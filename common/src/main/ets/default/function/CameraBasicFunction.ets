/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { Action } from '../redux/actions/Action'
import { CameraId } from '../setting/CameraId'
import { CameraPlatformCapability } from '../Camera/CameraPlatformCapability'
import { CLog } from '../Utils/CLog'
import { Function } from "./Function"
import { FunctionCallBack } from '../Camera/CameraService'

export class CameraBasicFunction extends Function {
  private TAG: string = '[CameraBasicFunction]:'

  private mCameraId: CameraId = CameraId.BACK
  private mSurfaceId: any = null
  private mCurrentMode: any = null

  private functionBackImpl: FunctionCallBack = {
    onCaptureSuccess: (thumbnail: any): void => {
      CLog.info(`${this.TAG} functionBackImpl onCaptureSuccess ${thumbnail}`)
      this.mWorkerManager.postMessage(Action.UpdateThumbnail(thumbnail))
    },
    onCaptureFailure: (): void => {
      CLog.info(`${this.TAG} functionBackImpl onCaptureFailure`)
      this.mWorkerManager.postMessage(Action.captureError())
    },
    onRecordSuccess: (thumbnail: any): void => {
      CLog.info(`${this.TAG} functionBackImpl onRecordSuccess ${thumbnail}`)
      this.mWorkerManager.postMessage(Action.RecordDone(thumbnail))
    },
    onRecordFailure: (): void => {
      CLog.info(`${this.TAG} functionBackImpl onRecordFailure`)
      this.mWorkerManager.postMessage(Action.RecordError())
    },
    thumbnail: (thumbnail: any): void => {
      CLog.info(`${this.TAG} functionBackImpl thumbnail ${thumbnail}`)
      this.mWorkerManager.postMessage(Action.UpdateThumbnail(thumbnail))
    }
  }

  private async initCamera(data) {
    CLog.info(`${this.TAG} initCamera ${JSON.stringify(data)}  E`)
    this.mCameraId = data.cameraId
    this.mCurrentMode = data.mode
    await this.mCameraService.initCamera()
    let PlatformCapability = new CameraPlatformCapability()
    await PlatformCapability.init()
    this.mWorkerManager.postMessage(Action.initCameraDone(PlatformCapability))
    this.mCameraService.getThumbnail(this.functionBackImpl)
    CLog.info(`${this.TAG} initCamera X`)
  }

  private async imageSize(data) {
    CLog.info(`${this.TAG} imageSize ${JSON.stringify(data)}  E`)
    this.mCameraService.mImageSize.imageWidth = data.imageSize.width
    this.mCameraService.mImageSize.imageHeight = data.imageSize.height
    CLog.info(`${this.TAG} imageSize X`)
  }

  private async videoSize(data) {
    CLog.info(`${this.TAG} videoSize ${JSON.stringify(data)}  E`)
    this.mCameraService.mVideoFrameSize.frameWidth = data.videoSize.width
    this.mCameraService.mVideoFrameSize.frameHeight = data.videoSize.height
    CLog.info(`${this.TAG} videoSize X`)
  }

  private async onSurfacePrepare(data) {
    CLog.info(`${this.TAG} onSurfacePrepare ${JSON.stringify(data)}  E`)
    this.mSurfaceId = data.surfaceId
    CLog.info(`${this.TAG} onSurfacePrepare X`)
  }

  private async startPreview() {
    CLog.info(`${this.TAG} startPreview E`)
    if (!this.mSurfaceId) {
      CLog.info(`${this.TAG} startPreview error mSurfaceId is null`)
      this.enableUi()
      return
    }
    await this.mCameraService.releaseCamera()
    await this.mCameraService.createCameraInput(this.mCameraId)
    await this.mCameraService.createPreviewOutput(this.mSurfaceId)
    if (await this.isVideoMode()) {
      await this.mCameraService.createVideoOutput(this.functionBackImpl)
    } else {
      await this.mCameraService.createPhotoOutput(this.functionBackImpl)
    }
    await this.mCameraService.createSession(this.mSurfaceId, await this.isVideoMode())
    await this.mCameraService.startPreview()
    this.enableUi()
    CLog.info(`${this.TAG} startPreview X`)
  }

  private async changeMode(data) {
    CLog.info(`${this.TAG} changeMode ${JSON.stringify(data)} E`)
    this.mCurrentMode = data.mode
    CLog.info(`${this.TAG} this.mCurrentMode = ${this.mCurrentMode}`)
    await this.mCameraService.releaseCamera()
    await this.mCameraService.createCameraInput(this.mCameraId)
    await this.mCameraService.createPreviewOutput(this.mSurfaceId)
    if (await this.isVideoMode()) {
      await this.mCameraService.createVideoOutput(this.functionBackImpl)
    } else {
      await this.mCameraService.createPhotoOutput(this.functionBackImpl)
    }
    await this.mCameraService.createSession(this.mSurfaceId, await this.isVideoMode())
    await this.mCameraService.startPreview()
    this.mWorkerManager.postMessage(Action.OnModeChanged(this.mCurrentMode))
    this.enableUi()
    CLog.info(`${this.TAG} changeMode X`)
  }

  private async switchCamera(data) {
    CLog.info(`${this.TAG} switchCamera ${JSON.stringify(data)} E`)
    this.mCameraId = data.cameraId
    this.mCameraService.setCameraName(this.mCameraId)
    await this.mCameraService.releaseCamera()
    await this.mCameraService.createCameraInput(this.mCameraId)
    await this.mCameraService.createPreviewOutput(this.mSurfaceId)
    if (await this.isVideoMode()) {
      await this.mCameraService.createVideoOutput(this.functionBackImpl)
    } else {
      await this.mCameraService.createPhotoOutput(this.functionBackImpl)
    }
    await this.mCameraService.createSession(this.mSurfaceId, await this.isVideoMode())
    await this.mCameraService.startPreview()
    this.enableUi()
    CLog.info(`${this.TAG} switchCamera X`)
  }

  private async close(data) {
    CLog.info(`${this.TAG} close ${JSON.stringify(data)} E`)
    await this.mCameraService.releaseCamera()
    CLog.info(`${this.TAG} close X`)
  }

  private async isVideoMode(): Promise<boolean> {
    CLog.info(`${this.TAG} isVideoMode ${this.mCurrentMode} ${this.mCurrentMode === 'VIDEO'}`)
    return this.mCurrentMode === 'VIDEO'
  }

  load(): void {
    CLog.info(`${this.TAG} load E`)
    this.mEventBus.on(Action.ACTION_INIT, this.initCamera.bind(this))
    this.mEventBus.on(Action.ACTION_CHANGE_IMAGE_SIZE, this.imageSize.bind(this))
    this.mEventBus.on(Action.ACTION_CHANGE_VIDEO_SIZE, this.videoSize.bind(this))
//    this.mEventBus.on(Action.ACTION_SURFACE_ID_PREPARE, this.onSurfacePrepare.bind(this))
    this.mEventBus.on(Action.ACTION_PREPARE_SURFACE, this.onSurfacePrepare.bind(this))
    this.mEventBus.on(Action.ACTION_START_PREVIEW, this.startPreview.bind(this))
    this.mEventBus.on(Action.ACTION_CHANGE_MODE, this.changeMode.bind(this))
    this.mEventBus.on(Action.ACTION_SWITCH_CAMERA, this.switchCamera.bind(this))
    this.mEventBus.on(Action.ACTION_CLOSE_CAMERA, this.close.bind(this))
    CLog.info(`${this.TAG} load X`)
  }

  unload(): void {
    CLog.info(`${this.TAG} unload E`)
    this.mEventBus.off(Action.ACTION_INIT, this.initCamera.bind(this))
    this.mEventBus.off(Action.ACTION_CHANGE_IMAGE_SIZE, this.imageSize.bind(this))
    this.mEventBus.off(Action.ACTION_CHANGE_VIDEO_SIZE, this.videoSize.bind(this))
//    this.mEventBus.off(Action.ACTION_SURFACE_ID_PREPARE, this.onSurfacePrepare.bind(this))
    this.mEventBus.off(Action.ACTION_PREPARE_SURFACE, this.onSurfacePrepare.bind(this))
    this.mEventBus.off(Action.ACTION_START_PREVIEW, this.startPreview.bind(this))
    this.mEventBus.off(Action.ACTION_CHANGE_MODE, this.changeMode.bind(this))
    this.mEventBus.off(Action.ACTION_SWITCH_CAMERA, this.switchCamera.bind(this))
    this.mEventBus.off(Action.ACTION_CLOSE_CAMERA, this.close.bind(this))
    CLog.info(`${this.TAG} unload X`)
  }
}