/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import { CameraId } from '../setting/settingitem/CameraId'
import { CameraPlatformCapability } from '../camera/CameraPlatformCapability'
import { Log } from '../utils/Log'
import { CameraStatus } from '../utils/Constants'
import { BaseFunction } from './BaseFunction'
import { FunctionCallBack } from '../camera/CameraService'
import EventLog from '../utils/EventLog'

export class CameraBasicFunction extends BaseFunction {
  private TAG = '[CameraBasicFunction]:'

  private mCameraId: string = CameraId.BACK
  private mSurfaceId = ''
  private mCurrentMode = ''
  private mSessionList = []
  private isSessionReleasing: boolean = false
  private initDataCache: any = null
  public startIdentification: boolean = false

  private functionBackImpl: FunctionCallBack = {
    onCapturePhotoOutput: (): void => {
      Log.info(`${this.TAG} functionBackImpl onCapturePhotoOutput`)
      this.mWorkerManager.postMessage(Action.capturePhotoOutput())
    },
    onCaptureSuccess: (thumbnail: any, resourceUri: any): void => {
      Log.info(`${this.TAG} functionBackImpl onCaptureSuccess ${thumbnail}`)
      this.mWorkerManager.postMessage(Action.updateThumbnail(thumbnail, resourceUri))
    },
    onCaptureFailure: (): void => {
      Log.info(`${this.TAG} functionBackImpl onCaptureFailure`)
      this.mWorkerManager.postMessage(Action.captureError())
    },
    onRecordSuccess: (thumbnail: any): void => {
      Log.info(`${this.TAG} functionBackImpl onRecordSuccess ${thumbnail}`)
      this.mWorkerManager.postMessage(Action.recordDone(thumbnail))
    },
    onRecordFailure: (): void => {
      Log.info(`${this.TAG} functionBackImpl onRecordFailure`)
      this.mWorkerManager.postMessage(Action.recordError())
    },
    thumbnail: (thumbnail: any): void => {
      Log.info(`${this.TAG} functionBackImpl thumbnail ${thumbnail}`)
      this.mWorkerManager.postMessage(Action.loadThumbnail(thumbnail))
    }
  }

  public async initCamera(data, callType?: string) {
    globalThis.cameraStatus = CameraStatus.CAMERA_BEGIN_INIT
    if (this.startIdentification) return;
    if (callType) this.startIdentification = true
    Log.start(`${this.TAG} initCamera`)
    this.mSessionList.push('CREATE')
    let curStorageCameraId = AppStorage.Get<string>('storageCameraId')
    if (curStorageCameraId) {
      data.cameraId = curStorageCameraId
    }
    Log.info(`${this.TAG} initData:${JSON.stringify(data)} `)
    this.initDataCache = data
    if (globalThis.isSessionCreating || this.isSessionReleasing) {
      Log.info(`${this.TAG} initCamera isSessionCreating or isSessionReleasing return`)
      return
    }
    this.mCameraId = data.cameraId
    this.mCurrentMode = data.mode
    let mCameraCount = await this.mCameraService.initCamera(this.mCameraId)
    const platformCapability = CameraPlatformCapability.getInstance()
    await platformCapability.init(mCameraCount)
    this.mWorkerManager.postMessage(Action.initCameraDone(platformCapability))
    this.mCameraService.getThumbnail(this.functionBackImpl)
    globalThis.cameraStatus = CameraStatus.CAMERA_INIT_FINISHED
    this.mWorkerManager.postMessage(Action.updateCameraStatus())
    Log.end(`${this.TAG} initCamera`)
  }

  private async imageSize(data) {
    Log.info(`${this.TAG} imageSize ${JSON.stringify(data)}  E`)
    this.mCameraService.mImageSize.imageWidth = data.imageSize.width
    this.mCameraService.mImageSize.imageHeight = data.imageSize.height
    Log.info(`${this.TAG} imageSize X`)
  }

  private async videoSize(data) {
    Log.info(`${this.TAG} videoSize ${JSON.stringify(data)}  E`)
    this.mCameraService.mVideoFrameSize.frameWidth = data.videoSize.width
    this.mCameraService.mVideoFrameSize.frameHeight = data.videoSize.height
    Log.info(`${this.TAG} videoSize X`)
  }

  private async onSurfacePrepare(data) {
    Log.info(`${this.TAG} onSurfacePrepare ${JSON.stringify(data)}  E`)
    this.mSurfaceId = data.surfaceId
    Log.info(`${this.TAG} onSurfacePrepare X`)
  }

  private async startPreview(data?) {
    Log.start(`${this.TAG} startPreview`)
    globalThis.cameraStatus = CameraStatus.CAMERA_BEGIN_PREVIEW
    if (!this.mSurfaceId) {
      Log.info(`${this.TAG} startPreview error mSurfaceId is null`)
      this.enableUi()
      return
    }
    await this.mCameraService.createPreviewOutput(this.mSurfaceId, this.mCurrentMode)
    if (await this.isVideoMode()) {
      //      await this.mCameraService.createVideoOutput(this.functionBackImpl)
    } else {
      await this.mCameraService.createPhotoOutput(this.functionBackImpl)
    }
    this.disableUi()
    await this.mCameraService.createSession(this.mSurfaceId, await this.isVideoMode())
    if ([...this.mSessionList].pop() === 'RELEASE') {
      await this.close()
    }
    if (data && data?.zoomRatio && data.zoomRatio !== 1) {
      await this.mCameraService.setZoomRatio(data.zoomRatio)
    }
    this.mSessionList = []
    this.enableUi()
    globalThis.cameraStatus = CameraStatus.CAMERA_PREVIEW_FINISHED
    this.mWorkerManager.postMessage(Action.updateCameraStatus())
    Log.end(`${this.TAG} startPreview`)
  }

  private async reStartPreview(data) {
    Log.start(`${this.TAG} reStartPreview`)
    if (!this.mSurfaceId) {
      Log.info(`${this.TAG} reStartPreview error mSurfaceId is null`)
      this.enableUi()
      return
    }
    this.mCameraService.setCameraId(this.mCameraId)
    globalThis.cameraStatus = CameraStatus.CAMERA_RELEASING
    await this.mCameraService.releaseCamera()
    globalThis.cameraStatus = CameraStatus.CAMERA_RELEASE_FINISHED
    globalThis.cameraStatus = CameraStatus.CAMERA_BEGIN_PREVIEW
    await this.mCameraService.createCameraInput(this.mCameraId)
    await this.mCameraService.createPreviewOutput(this.mSurfaceId, this.mCurrentMode)
    if (await this.isVideoMode()) {
      //      await this.mCameraService.createVideoOutput(this.functionBackImpl)
    } else {
      await this.mCameraService.createPhotoOutput(this.functionBackImpl)
    }
    this.disableUi()
    await this.mCameraService.createSession(this.mSurfaceId, await this.isVideoMode())
    if ([...this.mSessionList].pop() === 'RELEASE') {
      await this.close()
    }
    if (data && data?.zoomRatio && data.zoomRatio !== 1) {
      await this.mCameraService.setZoomRatio(data.zoomRatio)
    }
    this.mSessionList = []
    this.enableUi()
    globalThis.cameraStatus = CameraStatus.CAMERA_PREVIEW_FINISHED
    this.mWorkerManager.postMessage(Action.updateCameraStatus())
    Log.end(`${this.TAG} reStartPreview`)
  }

  private async changeMode(data) {
    Log.start(`${this.TAG} changeMode`)
    EventLog.write(EventLog.SWITCH_MODE)
    this.mCurrentMode = data.mode
    this.mCameraId = this.mCameraId.split('_').pop()
    Log.info(`${this.TAG} this.mCurrentMode = ${this.mCurrentMode}`)
    await this.mCameraService.releaseCamera()
    await this.mCameraService.createCameraInput(this.mCameraId, 'modeChange')
    await this.mCameraService.createPreviewOutput(this.mSurfaceId, this.mCurrentMode)
    if (await this.isVideoMode()) {
      //      await this.mCameraService.createVideoOutput(this.functionBackImpl)
    } else {
      await this.mCameraService.createPhotoOutput(this.functionBackImpl)
    }
    this.disableUi()
    await this.mCameraService.createSession(this.mSurfaceId, await this.isVideoMode())
    this.mWorkerManager.postMessage(Action.onModeChanged(this.mCurrentMode))
    this.mWorkerManager.postMessage(Action.swipeModeChangeDone(false))
    globalThis.cameraStatus = CameraStatus.CAMERA_PREVIEW_FINISHED
    this.mWorkerManager.postMessage(Action.updateCameraStatus())
    this.enableUi()
    Log.end(`${this.TAG} changeMode`)
  }

  private async switchCamera(data) {
    Log.start(`${this.TAG} switchCamera`)
    EventLog.write(EventLog.SWITCH_CAMERA)
    this.mCameraId = data.cameraId
    this.mCameraService.setCameraId(this.mCameraId)
    await this.mCameraService.releaseCamera()
    await this.mCameraService.createCameraInput(this.mCameraId)
    if (data?.curMode && data.curMode !== undefined && data.curMode !== this.mCurrentMode){
      this.mCurrentMode = data.curMode
    }
    await this.mCameraService.createPreviewOutput(this.mSurfaceId, this.mCurrentMode)
    if (await this.isVideoMode()) {
      //      await this.mCameraService.createVideoOutput(this.functionBackImpl)
    } else {
      await this.mCameraService.createPhotoOutput(this.functionBackImpl)
    }
    this.disableUi()
    await this.mCameraService.createSession(this.mSurfaceId, await this.isVideoMode())
    globalThis.cameraStatus = CameraStatus.CAMERA_PREVIEW_FINISHED
    this.mWorkerManager.postMessage(Action.updateCameraStatus())
    if (new Date().getTime() - globalThis.switchCameraTime > 2000) {
      EventLog.write(EventLog.SWITCH_TIMEOUT)
    }
    this.enableUi()
    Log.end(`${this.TAG} switchCamera`)
  }

  private async close() {
    Log.start(`${this.TAG} close`)
    this.mSessionList.push('RELEASE')
    if (globalThis.isSessionCreating || this.isSessionReleasing) {
      Log.info(`${this.TAG} isSessionCreating or isSessionReleasing return`)
      return
    }
    this.isSessionReleasing = true
    await this.mCameraService.releaseCamera()
    globalThis.cameraStatus = CameraStatus.CAMERA_RELEASE_FINISHED
    this.mWorkerManager.postMessage(Action.updateCameraStatus())
    this.startIdentification = false
    this.isSessionReleasing = false
    if ([...this.mSessionList].pop() === 'CREATE') {
      await this.initCamera(this.initDataCache)
      globalThis.cameraStatus = CameraStatus.CAMERA_INIT_FINISHED
      this.mWorkerManager.postMessage(Action.updateCameraStatus())
    }
    this.mSessionList = []
    Log.end(`${this.TAG} close`)
  }

  private async isVideoMode(): Promise<boolean> {
    Log.info(`${this.TAG} isVideoMode ${this.mCurrentMode} ${this.mCurrentMode === 'VIDEO'}`)
    return this.mCurrentMode === 'VIDEO'
  }

  private async reloadThumbnail(data) {
    Log.info(`${this.TAG} loadThumbnail E`)
    this.mCameraService.getThumbnail(this.functionBackImpl)
    Log.info(`${this.TAG} loadThumbnail X`)
  }

  static getInstance() {
    if (!globalThis?.cameraBasicMethod) {
      globalThis.cameraBasicMethod = new CameraBasicFunction()
    }
    return globalThis.cameraBasicMethod
  }

  load(): void {
    Log.info(`${this.TAG} load E`)
    this.mEventBus.on(Action.ACTION_INIT, this.initCamera.bind(this))
    this.mEventBus.on(Action.ACTION_CHANGE_IMAGE_SIZE, this.imageSize.bind(this))
    this.mEventBus.on(Action.ACTION_CHANGE_VIDEO_SIZE, this.videoSize.bind(this))
    this.mEventBus.on(Action.ACTION_PREPARE_SURFACE, this.onSurfacePrepare.bind(this))
    this.mEventBus.on(Action.ACTION_START_PREVIEW, this.startPreview.bind(this))
    this.mEventBus.on(Action.ACTION_RESTART_PREVIEW, this.reStartPreview.bind(this))
    this.mEventBus.on(Action.ACTION_CHANGE_MODE, this.changeMode.bind(this))
    this.mEventBus.on(Action.ACTION_SWITCH_CAMERA, this.switchCamera.bind(this))
    this.mEventBus.on(Action.ACTION_CLOSE_CAMERA, this.close.bind(this))
    this.mEventBus.on(Action.ACTION_RELOAD_THUMBNAIL, this.reloadThumbnail.bind(this))
    Log.info(`${this.TAG} load X`)
  }

  unload(): void {
    Log.info(`${this.TAG} unload E`)
    this.mEventBus.off(Action.ACTION_INIT, this.initCamera.bind(this))
    this.mEventBus.off(Action.ACTION_CHANGE_IMAGE_SIZE, this.imageSize.bind(this))
    this.mEventBus.off(Action.ACTION_CHANGE_VIDEO_SIZE, this.videoSize.bind(this))
    this.mEventBus.off(Action.ACTION_PREPARE_SURFACE, this.onSurfacePrepare.bind(this))
    this.mEventBus.off(Action.ACTION_START_PREVIEW, this.startPreview.bind(this))
    this.mEventBus.off(Action.ACTION_RESTART_PREVIEW, this.reStartPreview.bind(this))
    this.mEventBus.off(Action.ACTION_CHANGE_MODE, this.changeMode.bind(this))
    this.mEventBus.off(Action.ACTION_SWITCH_CAMERA, this.switchCamera.bind(this))
    this.mEventBus.off(Action.ACTION_CLOSE_CAMERA, this.close.bind(this))
    this.mEventBus.off(Action.ACTION_RELOAD_THUMBNAIL, this.reloadThumbnail.bind(this))
    Log.info(`${this.TAG} unload X`)
  }
}