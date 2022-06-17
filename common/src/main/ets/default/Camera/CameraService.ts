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
import deviceInfo from '@ohos.deviceInfo'

import { CameraId } from '../setting/settingitem/CameraId'
import { Log } from '../utils/Log'
import ThumbnailGetter from './ThumbnailGetter'
import SaveCameraAsset from './SaveCameraAsset'
import { SettingManager } from '../setting/SettingManager'
import { CameraPlatformCapability } from './CameraPlatformCapability'

export interface FunctionCallBack {
  onCaptureSuccess(thumbnail: any, resourceUri: any): void

  onCaptureFailure(): void

  onRecordSuccess(thumbnail: any): void

  onRecordFailure(): void

  thumbnail(thumbnail: any): void
}

export interface VideoCallBack {
  videoUri(videoUri: any): void
}

export class CameraService {
  private TAG = '[CameraService]:'
  private mCameraId: CameraId = CameraId.BACK
  private mSurfaceId = ''
  private mIsSessionRelease = true
  private mFileAssetId = 0
  private mCameraManager!: camera.CameraManager
  private mCameraIdMap: Map<CameraId, string> = new Map()
  private mCameraMap = new Map()
  private curCameraName = ''
  private mCameraCount = 0
  private mCameraInput!: camera.CameraInput
  private mCaptureSession!: camera.CaptureSession
  private mPreviewOutput!: camera.PreviewOutput
  private mPhotoOutPut!: camera.PhotoOutput
  private mVideoOutput!: camera.VideoOutput
  private mVideoRecorder!: media.VideoRecorder
  private mThumbnail!: image.PixelMap
  private mIsStartRecording = false
  private mSaveCameraAsset = new SaveCameraAsset()
  private mThumbnailGetter = new ThumbnailGetter()

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


  private constructor() {
  }

  public static getInstance(): CameraService {
    if (!globalThis?.sInstanceCameraService) {
      globalThis.sInstanceCameraService = new CameraService()
    }
    return globalThis.sInstanceCameraService;
  }

  public async initCamera(): Promise<number> {
    Log.info(`${this.TAG} initCamera invoke E.`)
    if (this.mCameraManager) {
      Log.info(`${this.TAG} initCamera CameraManager already init.`)
      return this.mCameraCount
    }

    this.mCameraManager = await camera.getCameraManager(globalThis.cameraAbilityContext)
    if (!this.mCameraManager) {
      Log.error(`${this.TAG} initCamera getCameraManager failed.`)
      return this.mCameraCount
    }

    const cameras = await this.mCameraManager.getCameras()
    this.mCameraCount = cameras.length
    if (cameras) {
      Log.info(`${this.TAG} getCameras success.`)
      for (let i = 0; i < cameras.length; i++) {
        Log.info(`${this.TAG} --------------Camera Info-------------`)
        Log.info(`${this.TAG} camera_id: ${cameras[i].cameraId}`)
        Log.info(`${this.TAG} cameraPosition: ${cameras[i].cameraPosition}`)
        Log.info(`${this.TAG} cameraType: ${cameras[i].cameraType}`)
        Log.info(`${this.TAG} connectionType: ${cameras[i].cameraType}`)
      }
      // TODO 根据底层信息匹配cameraId 目前默认第0个是back， 第1个是front
      this.mCameraIdMap.set(CameraId.BACK, cameras[0].cameraId);
      if (cameras.length > 1) {
        this.mCameraIdMap.set(CameraId.FRONT, cameras[1].cameraId);
      } else {
        this.mCameraIdMap.set(CameraId.FRONT, cameras[0].cameraId);
      }
    }
    this.curCameraName = CameraId.BACK
    await this.createCameraInput(CameraId.BACK)

    Log.info(`${this.TAG} deviceType = ${deviceInfo.deviceType}`)
    if (deviceInfo.deviceType == 'PAD' || deviceInfo.deviceType == 'tablet') {
      this.mVideoConfig.videoSourceType = 0
      this.mVideoConfig.profile.videoCodec = 'video/avc'
    } else {
      this.mVideoConfig.videoSourceType = 1
      this.mVideoConfig.profile.videoCodec = 'video/mp4v-es'
    }
    return this.mCameraCount
    Log.info(`${this.TAG} initCamera invoke X.`)
  }

  public getCameraManager() {
    return this.mCameraManager
  }

  public getCameraIdMap() {
    return this.mCameraIdMap
  }

  public getCameraMap() {
    return this.mCameraMap
  }

  public getCameraCount() {
    return this.mCameraCount
  }

  public async createCameraInput(cameraName: CameraId) {
    Log.info(`${this.TAG} createCameraInput invoke E.`)
    this.mCameraId = cameraName
    if (this.mCameraInput) {
      this.mCameraInput.release()
    }
    let id
    if (cameraName == CameraId.FRONT || cameraName == CameraId.BACK) {
      id = this.mCameraIdMap.get(cameraName)
    } else {
      id = this.mCameraMap.get(cameraName).cameraId
    }
    Log.info(`${this.TAG} createCameraInput id = ${id}`)
    this.mCameraInput = await this.mCameraManager.createCameraInput(id)
    const platformCapability = CameraPlatformCapability.getInstance()
    await platformCapability.calcSupportedSizes(this.mCameraInput)
    Log.info(`${this.TAG} createCameraInput invoke X.`)
  }

  public async releaseCameraInput() {
    Log.info(`${this.TAG} releaseCameraInput invoke E.`)
    if (this.mCameraInput) {
      await this.mCameraInput.release()
      this.mCameraInput = null
    }
    Log.info(`${this.TAG} releaseCameraInput invoke X.`)
  }

  public async createPreviewOutput(surfaceId: string) {
    Log.info(`${this.TAG} createPreviewOutput invoke ${surfaceId} E. `)
    this.mSurfaceId = surfaceId
    const size = SettingManager.getInstance().getPreviewSize()
    Log.info(`${this.TAG} createPreviewOutput size = ${JSON.stringify(size)}`)
    globalThis.mXComponentController.setXComponentSurfaceSize({ surfaceWidth: size.width, surfaceHeight: size.height })
    this.mPreviewOutput = await camera.createPreviewOutput(surfaceId)
    Log.info(`${this.TAG} createPreviewOutput invoke ${this.mPreviewOutput} X.`)
  }

  public async releasePreviewOutput() {
    Log.info(`${this.TAG} releasePreviewOutput invoke E.`)
    if (this.mPreviewOutput) {
      await this.mPreviewOutput.release()
      this.mPreviewOutput = null
    }
    Log.info(`${this.TAG} releasePreviewOutput invoke X.`)
  }

  public async createPhotoOutput(functionCallback: FunctionCallBack) {
    Log.info(`${this.TAG} createPhotoOutput invoke ${this.mImageSize.imageWidth}x${this.mImageSize.imageHeight} E.`)
    const receiver = image.createImageReceiver(this.mImageSize.imageWidth, this.mImageSize.imageHeight, 4, 8)
    Log.info(`${this.TAG} createPhotoOutput receiver: ${receiver}.`)
    const surfaceId = await receiver.getReceivingSurfaceId()
    Log.info(`${this.TAG} createPhotoOutput surfaceId: ${surfaceId}.`)
    this.mPhotoOutPut = await camera.createPhotoOutput(surfaceId)
    Log.info(`${this.TAG} createPhotoOutput mPhotoOutPut: ${this.mPhotoOutPut}.`)
    this.mSaveCameraAsset.saveImage(receiver, 40, 40, this.mThumbnailGetter, functionCallback)
    Log.info(`${this.TAG} createPhotoOutput invoke X.`)
  }

  public async releasePhotoOutput() {
    Log.info(`${this.TAG} releasePhotoOutput invoke E.`)
    if (this.mPhotoOutPut) {
      await this.mPhotoOutPut.release()
      this.mPhotoOutPut = null
    }
    Log.info(`${this.TAG} releasePhotoOutput invoke X.`)
  }

  public async createSession(surfaceId: string, isVideo: boolean) {
    Log.info(`${this.TAG} createSession invoke E.`)
    this.mSurfaceId = surfaceId
    this.mCaptureSession = await camera.createCaptureSession(globalThis.cameraAbilityContext)

    Log.info(`${this.TAG} createSession captureSession: ${this.mCaptureSession}, cameraInput: ${this.mCameraInput}, videoOutPut: ${this.mVideoOutput}, photoOutPut: ${this.mPhotoOutPut},  mPreviewOutput: ${this.mPreviewOutput}`)
    Log.info(`${this.TAG} createSession beginConfig.`)
    await this.mCaptureSession.beginConfig()
    Log.info(`${this.TAG} createSession addInput.`)
    await this.mCaptureSession.addInput(this.mCameraInput)
    if (!isVideo) {
      Log.info(`${this.TAG} createSession photo addOutput.`)
      await this.mCaptureSession.addOutput(this.mPhotoOutPut)
    }
    Log.info(`${this.TAG} createSession preview addOutput.`)
    await this.mCaptureSession.addOutput(this.mPreviewOutput)
    Log.info(`${this.TAG} createSession commitConfig.`)
    await this.mCaptureSession.commitConfig()
    Log.info(`${this.TAG} createSession invoke X.`)
  }

  public async releaseSession() {
    Log.info(`${this.TAG} releasePhotoSession invoke E.`)
    if (this.mCaptureSession) {
      await this.mCaptureSession.release()
      this.mCaptureSession = null
    }
    Log.info(`${this.TAG} releasePhotoSession invoke X.`)
  }

  public async startPreview() {
    Log.info(`${this.TAG} startPreview invoke E.`)
    if (!this.mCaptureSession) {
      return
    }
    await this.mCaptureSession.start()
    Log.info(`${this.TAG} startPreview invoke X.`)
  }

  public async stopPreview() {
    Log.info(`${this.TAG} stopPreview invoke E.`)
    if (!this.mCaptureSession) {
      return
    }
    await this.mCaptureSession.stop()
    Log.info(`${this.TAG} stopPreview invoke X.`)
  }

  public async takePicture() {
    Log.info(`${this.TAG} takePicture invoke E.`)
    if (!this.mCaptureSession) {
      Log.info(`${this.TAG} takePicture session is release`)
      return
    }
    if (!this.mPhotoOutPut) {
      Log.info(`${this.TAG} takePicture photoOutPut is release`)
      return
    }
    Log.info(`${this.TAG} takePicture SelfMirror setting: ${SettingManager.getInstance().getSelfMirror()}`)
    if (this.mCameraId === CameraId.FRONT) {
      this.mCaptureSetting.mirror = SettingManager.getInstance().getSelfMirror()
    }
    if (SettingManager.getInstance().getCurGeoLocation()) {
      this.mCaptureSetting.location.latitude = SettingManager.getInstance().getCurGeoLocation().latitude
      this.mCaptureSetting.location.longitude = SettingManager.getInstance().getCurGeoLocation().longitude
    }
    Log.info(`${this.TAG} takePicture captureSetting ${JSON.stringify(this.mCaptureSetting)}`)
    let tempCaptureSetting: any = {
      rotation: 0,
      quality: 1
    }
    // todo modify the location and mirror config
    await this.mPhotoOutPut.capture(tempCaptureSetting)
    Log.info(`${this.TAG} takePicture invoke X.`)
  }

  public async createVideoOutput(functionCallBack: VideoCallBack) {
    Log.info(`${this.TAG} createVideoOutput invoke E.`)
    Log.info(`${this.TAG} createVideoOutput this.mSurfaceId：saveCameraAsset: ${this.mSaveCameraAsset}`)
    this.mFileAssetId = await this.mSaveCameraAsset.createVideoFd(functionCallBack)
    this.mVideoConfig.url = `fd://${this.mFileAssetId.toString()}`
    await media.createVideoRecorder().then((recorder) => {
      Log.info(`${this.TAG} createVideoOutput createVideoRecorder record: ${recorder}`)
      this.mVideoRecorder = recorder
    })
    if (this.mVideoRecorder != null) {
      Log.info(`${this.TAG} createVideoOutput videoRecorder.prepare called.`)
      this.mVideoConfig.profile.videoFrameWidth = this.mVideoFrameSize.frameWidth
      this.mVideoConfig.profile.videoFrameHeight = this.mVideoFrameSize.frameHeight
      this.mVideoConfig.profile.videoCodec = SettingManager.getInstance().getVideoCodec()
      Log.info(`${this.TAG} createVideoOutput mVideoConfig =  ${JSON.stringify(this.mVideoConfig)}.`)
      await this.mVideoRecorder.prepare(this.mVideoConfig)
      Log.info(`${this.TAG} createVideoOutput videoRecorder.prepare succeed.`)
    } else {
      Log.error(`${this.TAG} createVideoOutput createVideoRecorder failed.`)
      return
    }

    const videoId = await this.mVideoRecorder.getInputSurface()
    this.mVideoOutput = await camera.createVideoOutput(videoId)
    Log.info(`${this.TAG} createVideoOutput invoke X.`)
  }

  public async releaseVideoOutput() {
    Log.info(`${this.TAG} releaseVideoOutput invoke E.`)
    if (this.mVideoOutput) {
      Log.info(`${this.TAG} releaseVideoOutput start`)
      await this.mVideoOutput.release()
      Log.info(`${this.TAG} releaseVideoOutput end`)
      this.mVideoOutput = null
    }
    Log.info(`${this.TAG} releaseVideoOutput invoke X.`)
  }

  public async StartRecording(functionCallBack: VideoCallBack) {
    Log.info(`${this.TAG} StartRecording invoke E.`)
    Log.info(`${this.TAG} StartRecording codec ${this.mVideoConfig.profile.videoCodec}`)
    await this.mCaptureSession.stop()
    await this.mCaptureSession.beginConfig()
    if (this.mVideoOutput) {
      await this.mCaptureSession.removeOutput(this.mVideoOutput)
      Log.info(`${this.TAG} old videoOutput has been removed.`)
    }
    await this.createVideoOutput(functionCallBack)
    await this.mCaptureSession.addOutput(this.mVideoOutput)
    Log.info(`${this.TAG} StartRecording addOutput finished.`)
    await this.mCaptureSession.commitConfig()
    Log.info(`${this.TAG} StartRecording commitConfig finished.`)
    await this.mCaptureSession.start()
    Log.info(`${this.TAG} StartRecording Session.start finished.`)
    await this.mVideoOutput.start().then(() => {
      Log.info(`${this.TAG} videoOutput.start()`)
    })
    await this.mVideoRecorder.start().then(() => {
      Log.info(`${this.TAG} videoRecorder.start()`)
    })
    this.mIsStartRecording = true
    Log.info(`${this.TAG} StartRecording invoke X.`)
  }

  public async stopRecording() {
    Log.info(`${this.TAG} stopRecording invoke E.`)
    if (!this.mVideoOutput || !this.mVideoRecorder) {
      Log.error(`${this.TAG} stopRecording error videoOutPut: ${this.mVideoOutput},
              videoRecorder: ${this.mVideoRecorder} .`)
      return
    }
    this.mIsStartRecording = false
    try {
      await this.mVideoRecorder.stop()
    } catch (err) {
      Log.error(`${this.TAG} stop videoRecorder ${err}`)
    }

    try {
      await this.mVideoOutput.stop()
    } catch (err) {
      Log.error(`${this.TAG} stop videoOutput ${err}`)
    }

    if (this.mFileAssetId != undefined) {
      await this.mSaveCameraAsset.videoPrepareFile.close(this.mFileAssetId)
      this.mFileAssetId = undefined
      Log.info(`${this.TAG} fileAsset.close().`)
    }

    const thumbnailPixelMap = await this.mThumbnailGetter.getThumbnailInfo(40, 40)
    Log.info(`${this.TAG} stopRecording invoke X.`)
    return thumbnailPixelMap
  }

  public async pauseRecording() {
    Log.info(`${this.TAG} pauseRecording invoke E.`)
    if (!this.mVideoOutput || !this.mVideoRecorder) {
      Log.error(`${this.TAG} pauseRecording error videoOutPut: ${this.mVideoOutput},
              videoRecorder: ${this.mVideoRecorder} .`)
      return
    }
    await this.mVideoRecorder.pause()
    await this.mVideoOutput.stop()
    Log.info(`${this.TAG} pauseRecording invoke X.`)
  }

  public async resumeRecording() {
    Log.info(`${this.TAG} resumeRecording invoke E.`)
    if (!this.mVideoOutput || !this.mVideoRecorder) {
      Log.error(`${this.TAG} resumeRecording error videoOutPut: ${this.mVideoOutput},
              videoRecorder: ${this.mVideoRecorder} .`)
      return
    }
    await this.mVideoOutput.start().then(() => {
      Log.info(`${this.TAG} videoOutput.start()`)
    })
    await this.mVideoRecorder.resume()
    Log.debug(`${this.TAG} resumeRecording invoke X.`)
  }

  public async releaseRecording() {
    Log.info(`${this.TAG} releaseRecording invoke E.`)
    if (!this.mVideoRecorder) {
      Log.info(`${this.TAG} video recorder has not been created.`)
      return
    }
    if (this.mIsStartRecording) {
      await this.stopRecording()
    }
    await this.mVideoRecorder.release().then(() => {
      Log.info(`${this.TAG} videoRecorder.release() success.`)
      this.mVideoRecorder = undefined
    })
    Log.debug(`${this.TAG} releaseRecording invoke X.`)
  }

  public async releaseCamera() {
    Log.info(`${this.TAG} releaseCamera invoke E.`)
    await this.stopPreview()
    await this.releaseRecording()
    await this.releaseCameraInput()
    await this.releasePreviewOutput()
    await this.releasePhotoOutput()
    await this.releaseVideoOutput()
    await this.releaseSession()
    Log.info(`${this.TAG} releaseCamera invoke X.`)
  }

  public async setZoomRatio(zoomRatio: number) {
    Log.info(`${this.TAG} setZoomRatio invoke E.`)
    if (!this.mCameraInput) {
      Log.info(`${this.TAG} setZoomRatio camerainput is release`)
      return
    }
    await this.mCameraInput.setZoomRatio(zoomRatio)
    Log.debug(`${this.TAG} setZoomRatio invoke X.`)
  }

  public async getZoomRatio(): Promise<number> {
    Log.info(`${this.TAG} getZoomRatio invoke E.`)
    if (!this.mCameraInput) {
      Log.info(`${this.TAG} getZoomRatio camerainput is release`)
      return 1;
    }
    Log.debug(`${this.TAG} getZoomRatio invoke X.`)
    return await this.mCameraInput.getZoomRatio()
  }

  public async setVideoConfig(videoConfig: any) {
    Log.info(`${this.TAG} setVideoConfig invoke E.`)
    if (videoConfig) {
      this.mVideoConfig = videoConfig
    } else {
      Log.info(`${this.TAG} setVideoConfig videoConfig is null.`)
    }
    Log.info(`${this.TAG} setVideoConfig invoke X.`)
  }

  public async setCaptureSetting(captureSetting: any) {
    Log.info(`${this.TAG} setCaptureSetting invoke E.`)
    if (captureSetting) {
      this.mCaptureSetting = captureSetting
    } else {
      Log.info(`${this.TAG} setCaptureSetting captureSetting is null.`)
    }
    Log.debug(`${this.TAG} setCaptureSetting invoke X.`)
  }

  public getThumbnail(functionCallBack: FunctionCallBack) {
    Log.info(`${this.TAG} getThumbnail invoke E.`)
    this.mThumbnailGetter.getThumbnailInfo(40, 40).then((thumbnail) => {
      Log.info(`${this.TAG} getThumbnail thumbnail: ${thumbnail}`)
      functionCallBack.thumbnail(thumbnail)
    })
    Log.debug(`${this.TAG} getThumbnail invoke X.`)
    return this.mThumbnail
  }

  public async getMultiCameraInfo() {
    Log.info(`${this.TAG} getMultiCameraInfo called.`)
    //    return ['MatePad Pro（前置）', 'MatePad Pro（后置）']
    const deviceNames = []
    const deviceIds = []
    const cameraMap = new Map()
    const cameras = await this.getCameraLists()
    deviceManager.createDeviceManager('com.ohos.camera', (err, manager) => {
      if (err) {
        Log.info(`${this.TAG} deviceManager.createDeviceManager failed.`)
      }
      Log.info(`${this.TAG} deviceManager.createDeviceManager success.`)
      const deviceInfoList = manager.getTrustedDeviceListSync()
      Log.info(`${this.TAG} deviceManager.deviceInfoList: ${JSON.stringify(deviceInfoList)}`)
      if (typeof (deviceInfoList) != undefined && typeof (deviceInfoList.length) != undefined) {
        deviceInfoList.forEach(item => {
          deviceNames.push(item.deviceName)
          deviceIds.push(item.deviceId)
          let hasFront = false
          let hasBack = false
          let cameraName
          for (let i = 0; i < cameras.length; i++) {
            if (cameras[i].connectionType == 2) {
              if (cameras[i].cameraId.split('_')[0] == item.deviceId) {
                if (cameras[i].cameraPosition == 2 && !hasFront) {
                  cameraName = item.deviceId + '_FRONT'
                  cameraMap.set(cameraName, {deviceName: item.deviceName, cameraId: cameras[i].cameraId})
                  Log.info(`${this.TAG} deviceManager add cameraName: ${cameraName}`)
                  hasFront = true
                } else if (cameras[i].cameraPosition == 1 && !hasBack) {
                  cameraName = item.deviceId + '_BACK'
                  cameraMap.set(cameraName, {deviceName: item.deviceName, cameraId: cameras[i].cameraId})
                  Log.info(`${this.TAG} deviceManager add cameraName: ${cameraName}`)
                  hasBack = true
                }
                if (hasFront && hasBack) {
                  break
                }
              }
            }
          }
        })
        this.mCameraMap = new Map(cameraMap)
      }
    })
  }

  private async getCameraLists() {
    const cameras = await this.mCameraManager.getCameras()
    return cameras
  }

  public getCameraName(): string {
    return this.curCameraName
  }

  public setCameraId(name: string) {
    this.curCameraName = name
  }

  public getPhotoUri() {
    return this.mSaveCameraAsset.getPhotoUri()
  }
}