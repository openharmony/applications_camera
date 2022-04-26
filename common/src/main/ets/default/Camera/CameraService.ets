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

import camera from '@ohos.multimedia.camera'
import deviceManager from '@ohos.distributedHardware.deviceManager'
import image from '@ohos.multimedia.image'
import media from '@ohos.multimedia.media'

import { CameraId } from '../setting/CameraId'
import { CLog } from '../Utils/CLog'
import { Constants } from '../Utils/Constants'
import GetPixelMap from './GetPixelMap'
import SaveCameraAsset from './SaveCameraAsset'

export interface FunctionCallBack {
  onCaptureSuccess(thumbnail: any): void

  onCaptureFailure(): void

  onRecordSuccess(thumbnail: any): void

  onRecordFailure(): void

  thumbnail(thumbnail: any): void
}

export class CameraService {
  private TAG: string = '[CameraService]:'
  private static sInstance: CameraService = undefined
  private mCameraId: CameraId = CameraId.BACK
  private mSurfaceId = null
  public mCurrentMode = null
  private mIsSessionRelease: boolean = true
  private mFileAssetId: number
  private mCameraManager = null
  private mCameraIdMap = new Map()
  private mCameraCount = 0
  private mCameraInput = null
  private mCaptureSession = null
  private mPreviewOutput = null
  private mPhotoOutPut = null
  private mVideoOutput = null
  private mVideoRecorder = null
  private mThumbnail = null
  private mIsStartRecording = false
  private mVideoConfig: any = {
    audioSourceType: 1,
    videoSourceType: 1,
    profile: {
      audioBitrate: 48000,
      audioChannels: 2,
      audioCodec: 'audio/mp4v-es',
      audioSampleRate: 48000,
      durationTime: 1000,
      fileFormat: 'mp4',
      videoBitrate: 48000,
      videoCodec: 'video/mp4v-es',
      videoFrameWidth: 640,
      videoFrameHeight: 480,
      videoFrameRate: 30
    },
    url: 'file:///data/media/01.mp4',
    orientationHint: 0,
    location: { latitude: 30, longitude: 130 },
    maxSize: 100,
    maxDuration: 500
  }
  private mCaptureSetting: any = {
    rotation: 0,
    quality: 1,
    location: {
      latitude: 12.9698,
      longitude: 77.7500
    },
    mirror: false
  }
  public mImageSize = {
    imageWidth: 1920,
    imageHeight: 1080
  }
  public mVideoFrameSize = {
    frameWidth: 1920,
    frameHeight: 1080
  }
  public mCameraListInfo = null
  public mSaveCameraAsset = new SaveCameraAsset()
  public mPixelMap = new GetPixelMap()

  private constructor() {
  }

  public static getInstance(): CameraService {
    if (!CameraService.sInstance) {
      CameraService.sInstance = new CameraService()
    }
    return CameraService.sInstance;
  }

  public async initCamera() {
    CLog.info(`${this.TAG} initCamera invoke E.`)
    if (this.mCameraManager) {
      CLog.info(`${this.TAG} initCamera CameraManager already init.`)
      return
    }

    this.mCameraManager = await camera.getCameraManager(null)
    if (!this.mCameraManager) {
      CLog.error(`${this.TAG} initCamera getCameraManager failed.`)
      return
    }

    let cameras = await this.mCameraManager.getCameras()
    this.mCameraCount = cameras.length
    if (cameras) {
      CLog.info(`${this.TAG} getCameras success.`)
      for (let i = 0; i < cameras.length; i++) {
        CLog.info(`${this.TAG} --------------Camera Info-------------`)
        CLog.info(`${this.TAG} camera_id: ${cameras[i].cameraId}`)
        CLog.info(`${this.TAG} cameraPosition: ${cameras[i].cameraPosition}`)
        CLog.info(`${this.TAG} cameraType: ${cameras[i].cameraType}`)
        CLog.info(`${this.TAG} connectionType: ${cameras[i].cameraType}`)
      }
      // TODO 根据底层信息匹配cameraId 目前默认第0个是back， 第1个是front
      this.mCameraIdMap[CameraId.BACK] = cameras[0].cameraId
      if (cameras.length > 1) {
        this.mCameraIdMap[CameraId.FRONT] = cameras[1].cameraId
      } else {
        this.mCameraIdMap[CameraId.FRONT] = cameras[0].cameraId
      }
    }
    CLog.info(`${this.TAG} initCamera invoke X.`)
  }

  public getCameraManager() {
    return this.mCameraManager
  }

  public getCameraIdMap() {
    return this.mCameraIdMap
  }

  public getCameraCount() {
    return this.mCameraCount
  }

  public async createCameraInput(cameraId: CameraId) {
    CLog.info(`${this.TAG} createCameraInput invoke E.`)
    this.mCameraId = cameraId
    if (this.mCameraInput) {
      this.mCameraInput.release()
    }
    let id = this.mCameraIdMap[cameraId]
    CLog.info(`${this.TAG} createCameraInput id = ${id}`)
    this.mCameraInput = await this.mCameraManager.createCameraInput(id)
    CLog.info(`${this.TAG} createCameraInput invoke X.`)
  }

  public async releaseCameraInput() {
    CLog.info(`${this.TAG} releaseCameraInput invoke E.`)
    if (this.mCameraInput) {
      await this.mCameraInput.release()
      this.mCameraInput = null
    }
    CLog.info(`${this.TAG} releaseCameraInput invoke X.`)
  }

  public async createPreviewOutput(surfaceId: number) {
    CLog.info(`${this.TAG} createPreviewOutput invoke ${surfaceId} E. `)
    this.mSurfaceId = surfaceId
    this.mPreviewOutput = await camera.createPreviewOutput(surfaceId)
    CLog.info(`${this.TAG} createPreviewOutput invoke ${this.mPreviewOutput} X.`)
  }

  public async releasePreviewOutput() {
    CLog.info(`${this.TAG} releasePreviewOutput invoke E.`)
    if (this.mPreviewOutput) {
      await this.mPreviewOutput.release()
      this.mPreviewOutput = null
    }
    CLog.info(`${this.TAG} releasePreviewOutput invoke X.`)
  }

  public async createPhotoOutput(functionCallback: FunctionCallBack) {
    CLog.info(`${this.TAG} createPhotoOutput invoke ${this.mImageSize.imageWidth}x${this.mImageSize.imageHeight} E.`)
    let receiver = image.createImageReceiver(this.mImageSize.imageWidth, this.mImageSize.imageHeight, 4, 8)
    CLog.info(`${this.TAG} createPhotoOutput receiver: ${receiver}.`)
    let surfaceId = await receiver.getReceivingSurfaceId()
    CLog.info(`${this.TAG} createPhotoOutput surfaceId: ${surfaceId}.`)
    this.mPhotoOutPut = await camera.createPhotoOutput(surfaceId)
    CLog.info(`${this.TAG} createPhotoOutput mPhotoOutPut: ${this.mPhotoOutPut}.`)
    this.mSaveCameraAsset.saveImage(receiver, 40, 40, this.mPixelMap, functionCallback)
    CLog.info(`${this.TAG} createPhotoOutput invoke X.`)
  }

  public async releasePhotoOutput() {
    CLog.info(`${this.TAG} releasePhotoOutput invoke E.`)
    if (this.mPhotoOutPut) {
      await this.mPhotoOutPut.release()
      this.mPhotoOutPut = null
    }
    CLog.info(`${this.TAG} releasePhotoOutput invoke X.`)
  }

  public async createSession(surfaceId: number, isVideo: boolean) {
    CLog.info(`${this.TAG} createSession invoke E.`)
    this.mSurfaceId = surfaceId
    this.mCaptureSession = await camera.createCaptureSession(null)

    CLog.info(`${this.TAG} createSession captureSession: ${this.mCaptureSession}, cameraInput: ${this.mCameraInput}, videoOutPut: ${this.mVideoOutput}, photoOutPut: ${this.mPhotoOutPut},  mPreviewOutput: ${this.mPreviewOutput}`)
    CLog.info(`${this.TAG} createSession beginConfig.`)
    await this.mCaptureSession.beginConfig()
    CLog.info(`${this.TAG} createSession addInput.`)
    await this.mCaptureSession.addInput(this.mCameraInput)
    if (isVideo) {
      CLog.info(`${this.TAG} createSession video addOutput.`)
      await this.mCaptureSession.addOutput(this.mVideoOutput)
    } else {
      CLog.info(`${this.TAG} createSession photo addOutput.`)
      await this.mCaptureSession.addOutput(this.mPhotoOutPut)
    }
    CLog.info(`${this.TAG} createSession preview addOutput.`)
    await this.mCaptureSession.addOutput(this.mPreviewOutput)
    CLog.info(`${this.TAG} createSession commitConfig.`)
    await this.mCaptureSession.commitConfig()
    CLog.info(`${this.TAG} createSession invoke X.`)
  }

  public async releaseSession() {
    CLog.info(`${this.TAG} releasePhotoSession invoke E.`)
    if (this.mCaptureSession) {
      await this.mCaptureSession.release()
      this.mCaptureSession = null
    }
    CLog.info(`${this.TAG} releasePhotoSession invoke X.`)
  }

  public async startPreview() {
    CLog.info(`${this.TAG} startPreview invoke E.`)
    if (!this.mCaptureSession) {
      return
    }
    await this.mCaptureSession.start()
    CLog.info(`${this.TAG} startPreview invoke X.`)
  }

  public async stopPreview() {
    CLog.info(`${this.TAG} stopPreview invoke E.`)
    if (!this.mCaptureSession) {
      return
    }
    await this.mCaptureSession.stop()
    CLog.info(`${this.TAG} stopPreview invoke X.`)
  }

  public async takePicture() {
    CLog.info(`${this.TAG} takePicture invoke E.`)
    if (!this.mCaptureSession) {
      CLog.info(`${this.TAG} takePicture session is release`)
      return
    }
    if (!this.mPhotoOutPut) {
      CLog.info(`${this.TAG} takePicture photoOutPut is release`)
      return
    }
    CLog.info(`${this.TAG} takePicture captureSetting ${JSON.stringify(this.mCaptureSetting)}`)
    await this.mPhotoOutPut.capture(this.mCaptureSetting)
    CLog.info(`${this.TAG} takePicture invoke X.`)
  }

  public async createVideoOutput(functionCallBack: FunctionCallBack) {
    CLog.info(`${this.TAG} createVideoOutput invoke E.`)
    CLog.info(`${this.TAG} createVideoOutput this.mSurfaceId：saveCameraAsset: ${this.mSaveCameraAsset}`)
    this.mFileAssetId = await this.mSaveCameraAsset.createVideoFd()
    this.mVideoConfig.url = `fd://${this.mFileAssetId.toString()}`
    await media.createVideoRecorder().then((recorder) => {
      CLog.info(`${this.TAG} createVideoOutput createVideoRecorder record: ${recorder}`)
      this.mVideoRecorder = recorder
    })
    if (this.mVideoRecorder != null) {
      CLog.info(`${this.TAG} createVideoOutput videoRecorder.prepare called.`)
      this.mVideoConfig.profile.videoFrameWidth = this.mVideoFrameSize.frameWidth
      this.mVideoConfig.profile.videoFrameHeight = this.mVideoFrameSize.frameHeight
      CLog.info(`${this.TAG} createVideoOutput mVideoConfig =  ${JSON.stringify(this.mVideoConfig)}.`)
      await this.mVideoRecorder.prepare(this.mVideoConfig)
      CLog.info(`${this.TAG} createVideoOutput videoRecorder.prepare succeed.`)
    } else {
      CLog.info(`${this.TAG} createVideoOutput createVideoRecorder failed.`)
      return
    }

    let videoId = await this.mVideoRecorder.getInputSurface()
    this.mVideoOutput = await camera.createVideoOutput(videoId)
    CLog.info(`${this.TAG} createVideoOutput invoke X.`)
  }

  public async releaseVideoOutput() {
    CLog.info(`${this.TAG} releaseVideoOutput invoke E.`)
    if (this.mVideoOutput) {
      CLog.info(`${this.TAG} releaseVideoOutput start`)
      await this.mVideoOutput.release()
      CLog.info(`${this.TAG} releaseVideoOutput end`)
      this.mVideoOutput = null
    }
    CLog.info(`${this.TAG} releaseVideoOutput invoke X.`)
  }

  public async StartRecording() {
    CLog.info(`${this.TAG} StartRecording invoke E.`)
    await this.mVideoOutput.start().then(() => {
      CLog.info(`${this.TAG} videoOutput.start()`)
    })
    await this.mVideoRecorder.start().then(() => {
      CLog.info(`${this.TAG} videoRecorder.start()`)
    })
    this.mIsStartRecording = true
    CLog.info(`${this.TAG} StartRecording invoke X.`)
  }

  public async stopRecording() {
    CLog.info(`${this.TAG} stopRecording invoke E.`)
    if (!this.mVideoOutput || !this.mVideoRecorder) {
      CLog.info(`${this.TAG} stopRecording error videoOutPut: ${this.mVideoOutput},
              videoRecorder: ${this.mVideoRecorder} .`)
      return
    }
    this.mIsStartRecording = false
    try {
      await this.mVideoRecorder.stop()
    } catch (err) {
      CLog.info(`${this.TAG} stop videoRecorder ${err}`)
    }

    try {
      await this.mVideoOutput.stop()
    } catch (err) {
      CLog.info(`${this.TAG} stop videoOutput ${err}`)
    }

    if (this.mFileAssetId != undefined) {
      await this.mSaveCameraAsset.videoPrepareFile.close(this.mFileAssetId)
      this.mFileAssetId = undefined
      CLog.info(`${this.TAG} fileAsset.close().`)
    }

    let thumbnailPixelMap = await this.mPixelMap.getThumbnailInfo(40, 40)

    // 录像停止时需要重新创建mVideoOutput
    await this.mCaptureSession.stop()
    await this.mCaptureSession.beginConfig()
//    await this.mCaptureSession.removeOutput(this.mVideoOutput)

//    try {
//      await this.mVideoRecorder.release()
//      CLog.info(`${this.TAG} stopRecording videoRecorder.release() success.`)
//      this.mVideoRecorder = undefined
//    } catch (err) {
//      CLog.info(`${this.TAG} stopRecording  ${err}`)
//    }
//    await this.releaseVideoOutput()
//    await this.createVideoOutput(null)
//    await this.mCaptureSession.addOutput(this.mVideoOutput)
//    await this.mCaptureSession.commitConfig()
//    await this.mCaptureSession.start()

    await this.releaseVideoOutput()
    await this.releasePreviewOutput()
    await this.releaseCameraInput()
    await this.releaseSession()

    await this.createCameraInput(this.mCameraId)
    await this.createPreviewOutput(this.mSurfaceId)
    await this.createVideoOutput(null)
    await this.createSession(this.mSurfaceId, true)
    await this.startPreview()
    CLog.info(`${this.TAG} stopRecording invoke X.`)
    return thumbnailPixelMap
  }

  public async pauseRecording() {
    CLog.info(`${this.TAG} pauseRecording invoke E.`)
    if (!this.mVideoOutput || !this.mVideoRecorder) {
      CLog.info(`${this.TAG} pauseRecording error videoOutPut: ${this.mVideoOutput},
              videoRecorder: ${this.mVideoRecorder} .`)
      return
    }
    await this.mVideoRecorder.pause()
    await this.mVideoOutput.stop()
    CLog.info(`${this.TAG} pauseRecording invoke X.`)
  }

  public async resumeRecording() {
    CLog.info(`${this.TAG} resumeRecording invoke E.`)
    if (!this.mVideoOutput || !this.mVideoRecorder) {
      CLog.info(`${this.TAG} resumeRecording error videoOutPut: ${this.mVideoOutput},
              videoRecorder: ${this.mVideoRecorder} .`)
      return
    }
    await this.mVideoOutput.start().then(() => {
      CLog.info(`${this.TAG} videoOutput.start()`)
    })
    await this.mVideoRecorder.resume()
    CLog.info(`${this.TAG} resumeRecording invoke X.`)
  }

  public async releaseRecording() {
    CLog.info(`${this.TAG} releaseRecording invoke E.`)
    if (!this.mVideoRecorder) {
      CLog.info(`${this.TAG} releaseRecording error videoRecorder is null .`)
      return
    }
    if (this.mIsStartRecording) {
      await this.stopRecording()
    }
    await this.mVideoRecorder.release().then(() => {
      CLog.info(`${this.TAG} videoRecorder.release() success.`)
      this.mVideoRecorder = undefined
    })
    CLog.info(`${this.TAG} releaseRecording invoke X.`)
  }

  public async releaseCamera() {
    CLog.info(`${this.TAG} releaseCamera invoke E.`)
    await this.stopPreview()
    await this.releaseRecording()
    await this.releaseCameraInput()
    await this.releasePreviewOutput()
    await this.releasePhotoOutput()
    await this.releaseVideoOutput()
    await this.releaseSession()
    CLog.info(`${this.TAG} releaseCamera invoke X.`)
  }

  public async setZoomRatio(zoomRatio) {
    CLog.info(`${this.TAG} setZoomRatio invoke E.`)
    if (!this.mCameraInput) {
      CLog.info(`${this.TAG} setZoomRatio camerainput is release`)
      return
    }
    await this.mCameraInput.setZoomRatio(zoomRatio)
    CLog.info(`${this.TAG} setZoomRatio invoke X.`)
  }

  public async getZoomRatio() {
    CLog.info(`${this.TAG} getZoomRatio invoke E.`)
    if (!this.mCameraInput) {
      CLog.info(`${this.TAG} getZoomRatio camerainput is release`)
      return
    }
    CLog.info(`${this.TAG} getZoomRatio invoke X.`)
    return await this.mCameraInput.getZoomRatio()
  }

  public async setVideoConfig(videoConfig: any) {
    CLog.info(`${this.TAG} setVideoConfig invoke E.`)
    if (videoConfig) {
      this.mVideoConfig = videoConfig
    } else {
      CLog.info(`${this.TAG} setVideoConfig videoConfig is null.`)
    }
    CLog.info(`${this.TAG} setVideoConfig invoke X.`)
  }

  public async setCaptureSetting(captureSetting: any) {
    CLog.info(`${this.TAG} setCaptureSetting invoke E.`)
    if (captureSetting) {
      this.mCaptureSetting = captureSetting
    } else {
      CLog.info(`${this.TAG} setCaptureSetting captureSetting is null.`)
    }
    CLog.info(`${this.TAG} setCaptureSetting invoke X.`)
  }

  public getThumbnail(functionCallBack: FunctionCallBack) {
    CLog.info(`${this.TAG} getThumbnail invoke E.`)
    this.mPixelMap.getThumbnailInfo(40, 40).then((thumbnail) => {
      if (thumbnail != null) {
        CLog.info(`${this.TAG} getThumbnail thumbnail: ${thumbnail}`)
        functionCallBack.thumbnail(thumbnail)
      }
    })
    CLog.info(`${this.TAG} getThumbnail invoke X.`)
    return this.mThumbnail
  }

  async getDeviceInfo() {
    CLog.info(`${this.TAG} getDeviceInfo called.`)
    return ['MatePad Pro（前置）', 'MatePad Pro（后置）']
    let deviceNames = []
    deviceManager.createDeviceManager('com.ohos.camera', (err, manager) => {
      if (err) {
        CLog.info(`${this.TAG} deviceManager.createDeviceManager failed.`)
        return
      }
      CLog.info(`${this.TAG} deviceManager.createDeviceManager success.`)
      let deviceInfoList = manager.getTrustedDeviceListSync()
      CLog.info(`${this.TAG} deviceManager.deviceInfoList: ${JSON.stringify(deviceInfoList)}`)
      if (typeof (deviceInfoList) != undefined && typeof (deviceInfoList.length) != undefined) {
        CLog.info(`${this.TAG} deviceManager.deviceInfoList[0]: ${JSON.stringify(deviceInfoList[0])}`)
        deviceInfoList.forEach(item => {
          if (item.deviceName.length > 15) {
            if (item.deviceType == 0x0C) {
              item.deviceName = 'PC-' + item.deviceName.slice(8, 12)
            } else if (item.deviceType == 0x0E) {
              item.deviceName = 'Phone-' + item.deviceName.slice(8, 12)
            } else if (item.deviceType == 0x11) {
              item.deviceName = 'Pad-' + item.deviceName.slice(8, 12)
            } else {
              item.deviceName = 'Unknown-' + item.deviceName.slice(8, 12)
            }
          }
          deviceNames.push(item.deviceName)
        })
      }
    })
    return deviceNames
  }

  public getPhotoUri() {
    CLog.info(`${this.TAG} getPhotoUri called`)
    return this.mSaveCameraAsset.getPhotoUri()
  }
}