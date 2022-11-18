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
import Trace from '../utils/Trace'

export interface FunctionCallBack {
  onCaptureSuccess(thumbnail: any, resourceUri: any): void

  onCaptureFailure(): void

  onRecordSuccess(thumbnail: any): void

  onRecordFailure(): void

  thumbnail(thumbnail: any): void
}

export interface VideoCallBack {
  videoUri(videoUri: any): void
  onRecodeError(errorMsg: any): void
}

type Callback = (args?: any) => void

export class CameraService {
  private TAG = '[CameraService]:'
  private mCameraId: string = CameraId.BACK
  private mSurfaceId = ''
  private isVideo: boolean = false
  private mFileAssetId = 0
  private mCameraManager!: camera.CameraManager
  private mCameraIdMap: Map<string, string> = new Map()
  private mLocalCameraMap: Map<string, string> = new Map()
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
  private camerasCache: any = null
  private outputCapability: camera.CameraOutputCapability = null

  private mVideoConfig: any = {
    audioSourceType: 1,
    videoSourceType: 1,
    profile: {
      audioBitrate: 48000,
      audioChannels: 2,
      audioCodec: 'audio/mp4a-latm',
      audioSampleRate: 48000,
      durationTime: 1000,
      fileFormat: 'mp4',
      videoBitrate: 48000,
      videoCodec: 'video/avc',
      videoFrameWidth: 640,
      videoFrameHeight: 480,
      videoFrameRate: 30
    },
    url: 'file:///data/media/01.mp4',
    orientationHint: 0,
    maxSize: 100,
    maxDuration: 500,
    rotation: 0
  }
  private mCaptureSetting: any = {
    rotation: 0,
    quality: 1,
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

  public async initCamera(cameraId: string): Promise<number> {
    Log.info(`${this.TAG} initCamera invoke E.`)
    if (!this.mCameraManager) {
      this.mCameraManager = await camera.getCameraManager(globalThis.cameraAbilityContext)
      const cameras = await this.mCameraManager.getSupportedCameras()
      this.camerasCache = cameras
      this.mCameraCount = cameras.length
      if (cameras) {
        Log.info(`${this.TAG} getCameras success.`)
        for (let i = 0; i < cameras.length; i++) {
          Log.info(`${this.TAG} --------------Camera Info-------------`)
          Log.info(`${this.TAG} camera_id: ${cameras[i].cameraId}`)
          Log.info(`${this.TAG} cameraPosition: ${cameras[i].cameraPosition}`)
          Log.info(`${this.TAG} cameraType: ${cameras[i].cameraType}`)
          Log.info(`${this.TAG} connectionType: ${cameras[i].connectionType}`)
          if(cameras[i].cameraPosition === 2 && cameras[i].connectionType !== 2){
            this.mLocalCameraMap.set('front', 'true')
          }
          if(cameras[i].cameraPosition !== 2 && cameras[i].connectionType !== 2){
            this.mLocalCameraMap.set('back', 'true')
          }
        }
        // TODO 根据底层信息匹配cameraId 目前默认第0个是back， 第1个是front
        this.mCameraIdMap.set(CameraId.BACK, cameras[0].cameraId);
        if (cameras.length > 1 && cameras[1].connectionType !== 2) {
          this.mCameraIdMap.set(CameraId.FRONT, cameras[1].cameraId);
        } else {
          this.mCameraIdMap.set(CameraId.FRONT, cameras[0].cameraId);
        }
      }
    }
    this.curCameraName = cameraId
    await this.createCameraInput(cameraId, 'init')

    Log.info(`${this.TAG} deviceType = ${deviceInfo.deviceType}`)
    if (deviceInfo.deviceType == 'default') {
      this.mVideoConfig.videoSourceType = 1
    } else {
      this.mVideoConfig.videoSourceType = 0
    }
    Log.info(`${this.TAG} initCamera invoke X.`)
    return this.mCameraCount
  }

  public getCameraManager() {
    return this.mCameraManager
  }

  public getCameraIdMap() {
    return this.mCameraIdMap
  }

  public getLocalCameraMap() {
    return this.mLocalCameraMap
  }

  public getCameraMap() {
    return this.mCameraMap
  }

  public getCameraCount() {
    return this.mCameraCount
  }

  public async createCameraInput(cameraName: string, callType?: string) {
    Log.info(`${this.TAG} createCameraInput invoke E.`)
    this.mCameraId = cameraName
    this.curCameraName = cameraName
    if (callType === 'modeChange' || callType === 'init') {
      let targetCamera = this.camerasCache.filter(item=>item.connectionType !== 2)
      if (targetCamera && targetCamera.length <= 1 && cameraName === 'BACK') {
        this.curCameraName = 'FRONT'
        this.mCameraId = 'FRONT'
      }
    }
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
    let cameras = await this.getCameraLists()
    let targetCamera = cameras.find(item => item.cameraId === id)
    this.outputCapability = await this.mCameraManager.getSupportedOutputCapability(targetCamera)
    this.mCameraInput = await this.mCameraManager.createCameraInput(targetCamera)
    await this.mCameraInput.open()
    const platformCapability = CameraPlatformCapability.getInstance()
    await platformCapability.calcSupportedSizes(this.mCameraInput, this.outputCapability)
    SettingManager.getInstance().setCameraPlatformCapability(platformCapability)
    Log.info(`${this.TAG} createCameraInput invoke X.`)
  }

  public async releaseCameraInput() {
    Log.info(`${this.TAG} releaseCameraInput invoke E.`)
    if (this.mCameraInput) {
      try {
        await this.mCameraInput.release()
      } catch (err) {
        Log.error(`${this.TAG} releaseCameraInput ${err}`)
      }
      this.mCameraInput = null
    }
    Log.info(`${this.TAG} releaseCameraInput invoke X.`)
  }

  public async createPreviewOutput(surfaceId: string) {
    Log.info(`${this.TAG} createPreviewOutput invoke ${surfaceId} E. `)
    this.mSurfaceId = surfaceId
    const size = SettingManager.getInstance().getPreviewSize()
    Log.info(`${this.TAG} createPreviewOutput size = ${JSON.stringify(size)}`)
    globalThis.mXComponentController.setXComponentSurfaceSize({ surfaceWidth: size.width , surfaceHeight: size.height })
    let previewProfiles = this.outputCapability.previewProfiles
    let previewProfile;
    if (deviceInfo.deviceType == 'default') {
      previewProfile = previewProfiles[0]
    } else {
      Log.info(`${this.TAG} previewProfiles length.` + previewProfiles.length)
      previewProfile = previewProfiles.find(item => item.size.width === size.width
      && item.size.height === size.height && item.format === 1003)
    }
    this.mPreviewOutput = await this.mCameraManager.createPreviewOutput(previewProfile, surfaceId)
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
    Log.info(`${this.TAG} createPhotoOutput invoke E.`)
    const size = SettingManager.getInstance().getImageSize()
    Log.info(`${this.TAG} createPhotoOutput size = ${JSON.stringify(size)}`)
    const receiver = image.createImageReceiver(size.width, size.height, image.ImageFormat.JPEG, 8)
    Log.info(`${this.TAG} createPhotoOutput receiver: ${receiver}.`)
    const surfaceId = await receiver.getReceivingSurfaceId()
    Log.info(`${this.TAG} createPhotoOutput surfaceId: ${surfaceId}.`)
    let photoProfiles = this.outputCapability.photoProfiles
    let photoProfile;
    if (deviceInfo.deviceType == 'default') {
      photoProfile = photoProfiles[0]
    } else {
      Log.info(`${this.TAG} videoProfiles length.` + photoProfiles.length)
      photoProfile = photoProfiles.find(item => item.size.width === size.width && item.size.height === size.height)
    }
    this.mPhotoOutPut = await this.mCameraManager.createPhotoOutput(photoProfile, surfaceId)
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
    this.isVideo = isVideo
    globalThis.isSessionCreating = true
    this.mCaptureSession = await this.mCameraManager.createCaptureSession()
    globalThis.isSessionCreating = false
    Log.info(`${this.TAG} createSession captureSession: ${this.mCaptureSession}, cameraInput: ${this.mCameraInput}, videoOutPut: ${this.mVideoOutput}, photoOutPut: ${this.mPhotoOutPut},  mPreviewOutput: ${this.mPreviewOutput}`)
    Log.info(`${this.TAG} createSession beginConfig.`)
    Trace.start(Trace.STREAM_DISTRIBUTION)
    try {
      await this.mCaptureSession?.beginConfig()
      await new Promise((resolve) => setTimeout(resolve, 1));
      Log.info(`${this.TAG} createSession addInput.`)
      await this.mCaptureSession?.addInput(this.mCameraInput)
      if (!isVideo) {
        Log.info(`${this.TAG} createSession photo addOutput.`)
        await this.mCaptureSession?.addOutput(this.mPhotoOutPut)
      }
      Log.info(`${this.TAG} createSession preview addOutput.`)
      await this.mCaptureSession?.addOutput(this.mPreviewOutput)
    } catch(err) {
      if (err) {
        Trace.write(Trace.CAMERA_ERROR)
      }
    }
    Log.info(`${this.TAG} createSession commitConfig.`)
    Trace.start(Trace.OPEN_CAMERA)
    try {
      await this.mCaptureSession?.commitConfig()
    } catch(err) {
      if (err) {
        Trace.write(Trace.OPEN_FAIL)
      }
    }
    Trace.end(Trace.OPEN_CAMERA)
    Trace.end(Trace.STREAM_DISTRIBUTION)
    await this.mCaptureSession?.start()
    if(globalThis.cameraStartFlag && (new Date().getTime() - globalThis.cameraStartTime) > 2000){
      Trace.write(Trace.START_TIMEOUT)
    }
    globalThis.cameraStartFlag = false
    Log.info(`${this.TAG} createSession invoke X.`)
  }

  public async releaseSession() {
    Log.info(`${this.TAG} releasePhotoSession invoke E.`)
    if (this.mCaptureSession) {
      await this.mCaptureSession.stop()
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
    const locationData = SettingManager.getInstance().getCurGeoLocation()
    if (locationData) {
      this.mCaptureSetting.location = {
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        altitude: locationData.altitude
      }
    }
    Log.info(`${this.TAG} takePicture captureSetting ${JSON.stringify(this.mCaptureSetting)}`)
    // todo modify the location and mirror config
    try {
      await this.mPhotoOutPut.capture(this.mCaptureSetting)
    } catch(err) {
      if(err){
        Trace.write(Trace.CAPTURE_FAIL)
      }
    }
    Log.info(`${this.TAG} takePicture invoke X.`)
    Trace.end(Trace.TAKE_PICTURE)
    if((new Date().getTime() - globalThis.startCaptureTime) > 2000){
      Trace.write(Trace.CAPTURE_TIMEOUT)
    }
  }

  public async createVideoOutput(functionCallBack: VideoCallBack) {
    Log.info(`${this.TAG} createVideoOutput invoke E.`)
    Log.info(`${this.TAG} createVideoOutput this.mSurfaceId：saveCameraAsset: ${this.mSaveCameraAsset}`)
    this.mFileAssetId = await this.mSaveCameraAsset.createVideoFd(functionCallBack)
    if (this.mFileAssetId === undefined) {
      Log.error(`${this.TAG} createVideoOutput error: mFileAssetId undefined`)
      functionCallBack.onRecodeError(`createVideoOutput error: mFileAssetId undefined`)
    }
    this.mVideoConfig.url = `fd://${this.mFileAssetId.toString()}`
    await media.createVideoRecorder().then((recorder) => {
      Log.info(`${this.TAG} createVideoOutput createVideoRecorder record: ${recorder}`)
      this.mVideoRecorder = recorder
    })
    const size = SettingManager.getInstance().getVideoSize()
    if (this.mVideoRecorder != null) {
      this.mVideoRecorder.on('error', (error) => {
        if (error) {
          Log.error(`${this.TAG} createVideoOutput error: ${error}`)
          functionCallBack.onRecodeError(`createVideoOutput error: ${error}`)
        }
      })
      Log.info(`${this.TAG} createVideoOutput size = ${JSON.stringify(size)}`)
      this.mVideoConfig.profile.videoFrameWidth = size.width
      this.mVideoConfig.profile.videoFrameHeight = size.height
      const locationData = SettingManager.getInstance().getCurGeoLocation()
      if (locationData) {
        this.mVideoConfig.location = {
          latitude: locationData.latitude,
          longitude: locationData.longitude
        }
      }
      let settingManagerData = SettingManager.getInstance()
      if (settingManagerData.mScreenWidth < settingManagerData.mScreenHeight) {
        if (this.curCameraName === 'BACK') {
          this.mVideoConfig.rotation = 90
        } else {
          this.mVideoConfig.rotation = 270
        }
      }
      Log.info(`${this.TAG} createVideoOutput videoRecorder.prepare called.`)
      Log.info(`${this.TAG} createVideoOutput mVideoConfig =  ${JSON.stringify(this.mVideoConfig)}.`)
      await this.mVideoRecorder.prepare(this.mVideoConfig)
      Log.info(`${this.TAG} createVideoOutput videoRecorder.prepare succeed.`)
    } else {
      Log.error(`${this.TAG} createVideoOutput createVideoRecorder failed.`)
      return
    }

    let profileVideo;
    if (deviceInfo.deviceType == 'default') {
      profileVideo = this.outputCapability.videoProfiles[0]
    } else {
      let videoProfiles = this.outputCapability.videoProfiles
      Log.info(`${this.TAG} videoProfiles length.` + videoProfiles.length)
      profileVideo = videoProfiles.find(item =>
      item.size.width === size.width && item.size.height === size.height
      )
    }

    const videoId = await this.mVideoRecorder.getInputSurface()
    Log.info(`${this.TAG} createVideoOutput profileVideo =  ${JSON.stringify(profileVideo)}.`)
    this.mVideoOutput = await this.mCameraManager.createVideoOutput(profileVideo, videoId)
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
    let startRecordingTime = new Date().getTime()
    Log.info(`${this.TAG} StartRecording invoke E.`)
    Log.info(`${this.TAG} StartRecording codec ${this.mVideoConfig.profile.videoCodec}`)
    await this.mCaptureSession.stop()
    await this.mCaptureSession.beginConfig()
    if (this.mVideoOutput) {
      try {
        await this.mCaptureSession.removeOutput(this.mVideoOutput)
        Log.info(`${this.TAG} old videoOutput has been removed.`)
      } catch (err) {
        globalThis.startRecordingFlag = false
        Log.error(`${this.TAG} remove videoOutput ${err}`)
      }
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
    if(new Date().getTime() - startRecordingTime > 2000){
      Trace.write(Trace.START_RECORD_TIMEOUT)
    }
  }

  public async stopRecording() {
    Trace.start(Trace.STOP_RECORDING)
    let stopRecordingTime = new Date().getTime()
    Log.info(`${this.TAG} stopRecording invoke E.`)
    if (!this.mVideoOutput || !this.mVideoRecorder) {
      Log.error(`${this.TAG} stopRecording error videoOutPut: ${this.mVideoOutput},
              videoRecorder: ${this.mVideoRecorder} .`)
      return
    }
    this.mIsStartRecording = false
    try {
      await this.mVideoRecorder.stop()
      await this.mVideoRecorder.release()
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
    Trace.start(Trace.UPDATE_VIDEO_THUMBNAIL)
    const thumbnailPixelMap = await this.mThumbnailGetter.getThumbnailInfo(40, 40)
    Trace.end(Trace.UPDATE_VIDEO_THUMBNAIL)
    Log.info(`${this.TAG} stopRecording invoke X.`)
    if(new Date().getTime() - stopRecordingTime > 2000){
      Trace.write(Trace.FINISH_RECORD_TIMEOUT)
    }
    Trace.end(Trace.STOP_RECORDING)
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
    try {
      await this.releaseRecording()
    } catch(err) {
      Log.error(`${this.TAG} releaseRecording: ${err}`)
    }
    await this.releaseSession()
    Log.info(`${this.TAG} releaseCamera invoke X.`)
  }

  public async setZoomRatio(zoomRatio: number) {
    Log.info(`${this.TAG} setZoomRatio invoke E.`)
    if (!this.mCaptureSession) {
      Log.info(`${this.TAG} setZoomRatio mCaptureSession is release`)
      return
    }
    await this.mCaptureSession.setZoomRatio(zoomRatio)
    Log.debug(`${this.TAG} setZoomRatio invoke X.`)
  }

  public async getZoomRatio(): Promise<number> {
    Log.info(`${this.TAG} getZoomRatio invoke E.`)
    if (!this.mCaptureSession) {
      Log.info(`${this.TAG} getZoomRatio mCaptureSession is release`)
      return 1;
    }
    Log.debug(`${this.TAG} getZoomRatio invoke X.`)
    return await this.mCaptureSession.getZoomRatio()
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

  public async getMultiCameraInfo(callback: Callback) {
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
        callback()
      }
    })
  }

  private async getCameraLists() {
    const cameras = await this.mCameraManager.getSupportedCameras()
    this.camerasCache = cameras
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