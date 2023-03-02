//@ts-nocheck
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
import EventLog from '../utils/EventLog'

const DEFAULT_VIDEO_FRAME_RATE = 30

export interface FunctionCallBack {
  onCapturePhotoOutput(): void

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
  private mImageReceiver!: image.ImageReceiver
  private mVideoOutput!: camera.VideoOutput
  private mAVRecorder!: media.AVRecorder
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
      videoBitrate: 5000000,
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
    Log.start(`${this.TAG} initCamera`)
    if (!this.mCameraManager) {
      try {
        this.mCameraManager = camera.getCameraManager(globalThis.cameraAbilityContext)
        const cameras = this.mCameraManager.getSupportedCameras()
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
      } catch (error) {
        Log.error(`${this.TAG} initCamera failed: ${JSON.stringify(error)}`)
        EventLog.writeFaultLog(error)
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
    Log.end(`${this.TAG} initCamera`)
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
    Log.start(`${this.TAG} createCameraInput`)
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
    try {
      let cameras = await this.getCameraLists()
      let targetCamera = cameras.find(item => item.cameraId === id)
      this.outputCapability = this.mCameraManager.getSupportedOutputCapability(targetCamera)
      this.mCameraInput = this.mCameraManager.createCameraInput(targetCamera)
      await this.mCameraInput.open()
      const platformCapability = CameraPlatformCapability.getInstance()
      await platformCapability.calcSupportedSizes(this.mCameraInput, this.outputCapability)
      SettingManager.getInstance().setCameraPlatformCapability(platformCapability)
    } catch (error) {
      Log.error(`${this.TAG} createCameraInput failed: ${JSON.stringify(error)}`)
      EventLog.writeFaultLog(error)
    }
    Log.end(`${this.TAG} createCameraInput`)
  }

  public async releaseCameraInput() {
    Log.start(`${this.TAG} releaseCameraInput`)
    if (this.mCameraInput) {
      try {
        await this.mCameraInput.release()
      } catch (error) {
        Log.error(`${this.TAG} releaseCameraInput failed: ${JSON.stringify(error)}`)
        EventLog.writeFaultLog(error)
      }
      this.mCameraInput = null
    }
    Log.end(`${this.TAG} releaseCameraInput`)
  }

  public async createPreviewOutput(surfaceId: string, mode: string) {
    Log.start(`${this.TAG} createPreviewOutput`)
    const size = SettingManager.getInstance().getPreviewSize(mode)
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
    await this.releasePreviewOutput()
    try {
      this.mPreviewOutput = this.mCameraManager.createPreviewOutput(previewProfile, surfaceId)
    } catch (error) {
      Log.error(`${this.TAG} createPreviewOutput failed: ${JSON.stringify(error)}`)
      EventLog.writeFaultLog(error)
    }
    Log.end(`${this.TAG} createPreviewOutput`)
  }

  public async releasePreviewOutput() {
    Log.start(`${this.TAG} releasePreviewOutput`)
    if (this.mPreviewOutput) {
      try {
        await this.mPreviewOutput.release()
        this.mPreviewOutput = null
      } catch (error) {
        Log.error(`${this.TAG} releasePreviewOutput failed: ${JSON.stringify(error)}`)
        EventLog.writeFaultLog(error)
      }
    }
    Log.end(`${this.TAG} releasePreviewOutput`)
  }

  public async createPhotoOutput(functionCallback: FunctionCallBack) {
    Log.start(`${this.TAG} createPhotoOutput`)
    const size = SettingManager.getInstance().getImageSize()
    Log.info(`${this.TAG} createPhotoOutput size = ${JSON.stringify(size)}`)
    this.mImageReceiver = image.createImageReceiver(size.width, size.height, image.ImageFormat.JPEG, 8)
    Log.info(`${this.TAG} createPhotoOutput receiver: ${this.mImageReceiver}.`)
    const surfaceId = await this.mImageReceiver.getReceivingSurfaceId()
    Log.info(`${this.TAG} createPhotoOutput surfaceId: ${surfaceId}.`)
    let photoProfiles = this.outputCapability.photoProfiles
    let photoProfile;
    if (deviceInfo.deviceType == 'default') {
      photoProfile = photoProfiles[0]
    } else {
      Log.info(`${this.TAG} videoProfiles length.` + photoProfiles.length)
      photoProfile = photoProfiles.find(item => item.size.width === size.width && item.size.height === size.height)
    }
    try {
      this.mPhotoOutPut = this.mCameraManager.createPhotoOutput(photoProfile, surfaceId)
    } catch (error) {
      Log.error(`${this.TAG} createPhotoOutput failed: ${JSON.stringify(error)}`)
      EventLog.writeFaultLog(error)
    }
    Log.info(`${this.TAG} createPhotoOutput mPhotoOutPut: ${this.mPhotoOutPut}.`)
    this.mSaveCameraAsset.saveImage(this.mImageReceiver, 40, 40, this.mThumbnailGetter, functionCallback)
    Log.end(`${this.TAG} createPhotoOutput`)
  }

  public async releasePhotoOutput() {
    Log.start(`${this.TAG} releasePhotoOutput`)
    if (this.mPhotoOutPut) {
      try {
        await this.mPhotoOutPut.release()
        this.mPhotoOutPut = null
      } catch (error) {
        Log.error(`${this.TAG} releasePhotoOutput failed: ${JSON.stringify(error)}`)
        EventLog.writeFaultLog(error)
      }
    }
    if (this.mImageReceiver) {
      await this.mImageReceiver.release()
      this.mImageReceiver = null
    }
    Log.end(`${this.TAG} releasePhotoOutput`)
  }

  public async createSession(surfaceId: string, isVideo: boolean) {
    Log.start(`${this.TAG} createSession`)
    globalThis.isSessionCreating = true
    this.mCaptureSession = this.mCameraManager.createCaptureSession()
    globalThis.isSessionCreating = false
    Log.info(`${this.TAG} createSession captureSession: ${this.mCaptureSession}, cameraInput: ${this.mCameraInput},
    videoOutPut: ${this.mVideoOutput}, photoOutPut: ${this.mPhotoOutPut},  mPreviewOutput: ${this.mPreviewOutput}`)
    Log.info(`${this.TAG} createSession beginConfig.`)
    Log.start(Log.STREAM_DISTRIBUTION)
    try {
      this.mCaptureSession?.beginConfig()
      await new Promise((resolve) => setTimeout(resolve, 1));
      Log.info(`${this.TAG} createSession addInput.`)
      this.mCaptureSession?.addInput(this.mCameraInput)
      if (!isVideo) {
        Log.info(`${this.TAG} createSession photo addOutput.`)
        this.mCaptureSession?.addOutput(this.mPhotoOutPut)
      }
      Log.info(`${this.TAG} createSession preview addOutput.`)
      this.mCaptureSession?.addOutput(this.mPreviewOutput)
    } catch(error) {
      Log.error(`${this.TAG} createSession failed: ${JSON.stringify(error)}`)
      if (error) {
        EventLog.write(EventLog.CAMERA_ERROR)
      }
    }
    Log.info(`${this.TAG} createSession commitConfig.`)
    Log.start(Log.OPEN_CAMERA)
    try {
      await this.mCaptureSession?.commitConfig()
      Log.end(Log.OPEN_CAMERA)
      Log.end(Log.STREAM_DISTRIBUTION)
      await this.mCaptureSession?.start()
    } catch(err) {
      if (err) {
        EventLog.write(EventLog.OPEN_FAIL)
      }
    }
    if(globalThis.cameraStartFlag && (new Date().getTime() - globalThis.cameraStartTime) > 2000){
      EventLog.write(EventLog.START_TIMEOUT)
    }
    globalThis.cameraStartFlag = false
    Log.end(`${this.TAG} createSession`)
  }

  public async releaseSession() {
    Log.start(`${this.TAG} releaseSession`)
    if (this.mCaptureSession) {
      try {
        await this.mCaptureSession.stop()
        await this.mCaptureSession.release()
        this.mCaptureSession = null
      } catch (error) {
        Log.error(`${this.TAG} releaseSession failed: ${JSON.stringify(error)}`)
        EventLog.writeFaultLog(error)
      }
    }
    Log.end(`${this.TAG} releaseSession`)
  }

  public async startPreview() {
    Log.start(`${this.TAG} startPreview`)
    if (!this.mCaptureSession) {
      return
    }
    try {
      await this.mCaptureSession.start()
    } catch (error) {
      Log.error(`${this.TAG} startPreview failed: ${JSON.stringify(error)}`)
      EventLog.writeFaultLog(error)
    }
    Log.end(`${this.TAG} startPreview`)
  }

  public async stopPreview() {
    Log.start(`${this.TAG} stopPreview`)
    if (!this.mCaptureSession) {
      return
    }
    try {
      await this.mCaptureSession.stop()
    } catch (error) {
      Log.error(`${this.TAG} stopPreview failed: ${JSON.stringify(error)}`)
      EventLog.writeFaultLog(error)
    }
    Log.end(`${this.TAG} stopPreview`)
  }

  public async takePicture() {
    Log.start(`${this.TAG} takePicture`)
    EventLog.write(EventLog.CAPTURE)
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
      this.mPhotoOutPut.capture(this.mCaptureSetting)
    } catch(err) {
      if(err){
        EventLog.write(EventLog.CAPTURE_FAIL)
      }
    }
    Log.end(`${this.TAG} takePicture`)
//    Log.end(Log.TAKE_PICTURE)
    if((new Date().getTime() - globalThis.startCaptureTime) > 2000){
      EventLog.write(EventLog.CAPTURE_TIMEOUT)
    }
  }

  public async createVideoOutput(functionCallBack: VideoCallBack) {
    Log.start(`${this.TAG} createVideoOutput`)
    Log.info(`${this.TAG} createVideoOutput saveCameraAsset: ${this.mSaveCameraAsset}`)
    this.mFileAssetId = await this.mSaveCameraAsset.createVideoFd(functionCallBack)
    if (this.mFileAssetId === undefined) {
      Log.error(`${this.TAG} createVideoOutput error: mFileAssetId undefined`)
      functionCallBack.onRecodeError(`createVideoOutput error: mFileAssetId undefined`)
    }
    this.mVideoConfig.url = `fd://${this.mFileAssetId.toString()}`
    await media.createAVRecorder().then((recorder) => {
      Log.info(`${this.TAG} createVideoOutput createAVRecorder record: ${recorder}`)
      this.mAVRecorder = recorder
    })
    const size = SettingManager.getInstance().getVideoSize()
    if (this.mAVRecorder != null) {
      this.mAVRecorder.on('error', (error) => {
        if (error) {
          Log.error(`${this.TAG} createVideoOutput error: ${JSON.stringify(error)}`)
          functionCallBack.onRecodeError(`createVideoOutput error: ${JSON.stringify(error)}`)
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

      if (deviceInfo.deviceType != 'tablet') {
        if (this.curCameraName === 'BACK') {
          this.mVideoConfig.rotation = 90
        } else {
          this.mVideoConfig.rotation = 270
        }
      }
      Log.info(`${this.TAG} createVideoOutput AVRecorder.prepare called.`)
      Log.info(`${this.TAG} createVideoOutput mVideoConfig =  ${JSON.stringify(this.mVideoConfig)}.`)
      await this.mAVRecorder.prepare(this.mVideoConfig)
      Log.info(`${this.TAG} createVideoOutput AVRecorder.prepare succeed.`)
    } else {
      Log.error(`${this.TAG} createVideoOutput createAVRecorder failed.`)
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
      && item.frameRateRange.min === DEFAULT_VIDEO_FRAME_RATE && item.frameRateRange.max === DEFAULT_VIDEO_FRAME_RATE
      )
    }

    const videoId = await this.mAVRecorder.getInputSurface()
    Log.info(`${this.TAG} createVideoOutput profileVideo =  ${JSON.stringify(profileVideo)}.`)
    try {
      this.mVideoOutput = this.mCameraManager.createVideoOutput(profileVideo, videoId)
    } catch (error) {
      Log.error(`${this.TAG} createVideoOutput failed: ${JSON.stringify(error)}`)
      EventLog.writeFaultLog(error)
    }
    Log.end(`${this.TAG} createVideoOutput`)
  }

  public async releaseVideoOutput() {
    Log.start(`${this.TAG} releaseVideoOutput`)
    if (this.mVideoOutput) {
      Log.info(`${this.TAG} releaseVideoOutput start`)
      try {
        await this.mVideoOutput.release()
      } catch (error) {
        Log.error(`${this.TAG} releaseVideoOutput failed: ${JSON.stringify(error)}`)
        EventLog.writeFaultLog(error)
      }
      Log.info(`${this.TAG} releaseVideoOutput end`)
      this.mVideoOutput = null
    }
    Log.end(`${this.TAG} releaseVideoOutput`)
  }

  public async StartRecording(functionCallBack: VideoCallBack) {
    let startRecordingTime = new Date().getTime()
    Log.start(`${this.TAG} StartRecording`)
    Log.info(`${this.TAG} StartRecording codec ${this.mVideoConfig.profile.videoCodec}`)
    EventLog.write(EventLog.VIDEO_RECORD)
    try {
      await this.mCaptureSession.stop()
      this.mCaptureSession.beginConfig()
      if (this.mVideoOutput) {
          await this.mCaptureSession.removeOutput(this.mVideoOutput)
          Log.info(`${this.TAG} old videoOutput has been removed.`)
      }
      await this.createVideoOutput(functionCallBack)
      this.mCaptureSession.addOutput(this.mVideoOutput)
      Log.info(`${this.TAG} StartRecording addOutput finished.`)
      await this.mCaptureSession.commitConfig()
      Log.info(`${this.TAG} StartRecording commitConfig finished.`)
      await this.mCaptureSession.start()
      Log.info(`${this.TAG} StartRecording Session.start finished.`)
    } catch (err) {
      globalThis.startRecordingFlag = false
      EventLog.writeFaultLog(error)
      Log.error(`${this.TAG} remove videoOutput ${err}`)
    }
    await this.mVideoOutput.start().then(() => {
      Log.info(`${this.TAG} videoOutput.start()`)
    })
    await this.mAVRecorder.start().then(() => {
      Log.info(`${this.TAG} AVRecorder.start()`)
    })
    this.mIsStartRecording = true
    if(new Date().getTime() - startRecordingTime > 2000){
      EventLog.write(EventLog.START_RECORD_TIMEOUT)
    }
    Log.end(`${this.TAG} StartRecording`)
  }

  public async stopRecording() {
    Log.start(Log.STOP_RECORDING)
    let stopRecordingTime = new Date().getTime()
    Log.info(`${this.TAG} stopRecording invoke E.`)
    EventLog.write(EventLog.STOP_RECORD)
    if (!this.mVideoOutput || !this.mAVRecorder) {
      Log.error(`${this.TAG} stopRecording error videoOutPut: ${this.mVideoOutput},
              AVRecorder: ${this.mAVRecorder} .`)
      return
    }
    this.mIsStartRecording = false
    try {
      await this.mAVRecorder.stop()
      await this.mAVRecorder.release()
    } catch (err) {
      Log.error(`${this.TAG} stop AVRecorder ${err}`)
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
    Log.start(Log.UPDATE_VIDEO_THUMBNAIL)
    const thumbnailPixelMap = await this.mThumbnailGetter.getThumbnailInfo(40, 40)
    Log.end(Log.UPDATE_VIDEO_THUMBNAIL)
    Log.info(`${this.TAG} stopRecording invoke X.`)
    if(new Date().getTime() - stopRecordingTime > 2000){
      EventLog.write(EventLog.FINISH_RECORD_TIMEOUT)
    }
    Log.end(Log.STOP_RECORDING)
    return thumbnailPixelMap
  }

  public async pauseRecording() {
    Log.start(`${this.TAG} pauseRecording`)
    if (!this.mVideoOutput || !this.mAVRecorder) {
      Log.error(`${this.TAG} pauseRecording error videoOutPut: ${this.mVideoOutput},
              AVRecorder: ${this.mAVRecorder} .`)
      return
    }
    try {
      await this.mAVRecorder.pause()
      await this.mVideoOutput.stop()
    } catch (error) {
      Log.error(`${this.TAG} pauseRecording failed: ${JSON.stringify(error)}`)
    }
    Log.end(`${this.TAG} pauseRecording`)
  }

  public async resumeRecording() {
    Log.start(`${this.TAG} resumeRecording`)
    if (!this.mVideoOutput || !this.mAVRecorder) {
      Log.error(`${this.TAG} resumeRecording error videoOutPut: ${this.mVideoOutput},
              AVRecorder: ${this.mAVRecorder} .`)
      return
    }
    await this.mVideoOutput.start().then(() => {
      Log.info(`${this.TAG} videoOutput.start()`)
    }).catch((error) => {
      Log.error(`${this.TAG} resumeRecording mVideoOutput start failed: ${JSON.stringify(error)}`)
    })
    await this.mAVRecorder.resume()
    Log.end(`${this.TAG} resumeRecording`)
  }

  public async releaseRecording() {
    Log.start(`${this.TAG} releaseRecording`)
    if (!this.mAVRecorder) {
      Log.info(`${this.TAG} AVRecorder has not been created.`)
      return
    }
    if (this.mIsStartRecording) {
      await this.stopRecording()
    }
    await this.mAVRecorder.release().then(() => {
      Log.info(`${this.TAG} AVRecorder.release() success.`)
      this.mAVRecorder = undefined
    })
    Log.end(`${this.TAG} releaseRecording`)
  }

  public async releaseCamera() {
    Log.start(`${this.TAG} releaseCamera`)
    await this.releaseRecording()
    await this.releaseVideoOutput()
    await this.releasePhotoOutput()
    await this.releaseSession()
    Log.end(`${this.TAG} releaseCamera`)
  }

  public async setZoomRatio(zoomRatio: number) {
    Log.info(`${this.TAG} setZoomRatio invoke E ${zoomRatio}`)
    if (!this.mCaptureSession) {
      Log.info(`${this.TAG} setZoomRatio mCaptureSession is release`)
      return
    }
    try {
      this.mCaptureSession.setZoomRatio(zoomRatio)
    } catch (error) {
      Log.error(`${this.TAG} setZoomRatio failed: ${JSON.stringify(error)}`)
    }
    Log.info(`${this.TAG} setZoomRatio invoke X.`)
  }

  public async getZoomRatio(): Promise<number> {
    Log.info(`${this.TAG} getZoomRatio invoke E.`)
    if (!this.mCaptureSession) {
      Log.info(`${this.TAG} getZoomRatio mCaptureSession is release`)
      return 1;
    }
    Log.info(`${this.TAG} getZoomRatio invoke X.`)
    return this.mCaptureSession.getZoomRatio()
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
    Log.start(`${this.TAG} getThumbnail`)
    this.mThumbnailGetter.getThumbnailInfo(40, 40).then((thumbnail) => {
      Log.info(`${this.TAG} getThumbnail thumbnail: ${thumbnail}`)
      functionCallBack.thumbnail(thumbnail)
      Log.end(`${this.TAG} getThumbnail`)
    })
    Log.info(`${this.TAG} getThumbnail invoke X.`)
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
    const cameras = this.mCameraManager.getSupportedCameras()
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