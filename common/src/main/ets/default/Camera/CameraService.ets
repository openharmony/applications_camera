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
import media from '@ohos.multimedia.media'
import image from '@ohos.multimedia.image'
import SaveCameraAsset from './SaveCameraAsset'
import GetPixelMap from './GetPixelMap'
import deviceManager from '@ohos.distributedHardware.deviceManager'

export class CameraService {
  private TAG = '[camera]: '
  private curCameraName: string = '本地（后置）'
  public SaveCameraAsset = new SaveCameraAsset()
  public getPixelMap = new GetPixelMap()
  public previewOutput: any
  public cameraInfo: any = undefined
  public cameraInput: any
  public cameraManager: any = undefined
  public cameraId: any
  public photoOutPut: any
  public captureSession: any
  public videoOutput: any
  public videoRecorder: any
  public thumbnailCallBack: any
  public captureSuccessCallBack: any
  public previewId: any
  public curMode: any
  public photoResolution: any
  public videoResolution: any
  private isSessionRelease: boolean = true
  private fileAsset: any
  public cameraListInfo: any
  private previewSize = [
    { width: 2048, height: 1536 },
    { width: 720, height: 720 },
    { width: 1920, height: 1080 },
    { width: 1920, height: 1080 },
    { width: 1920, height: 1080 },
    { width: 1920, height: 1080 }
  ]
  private imageSize = [
    { width: 2048, height: 1536 },
    { width: 3120, height: 3120 },
    { width: 1920, height: 1080 }
  ]
  private videoFrameSize = [
    { width: 1280, height: 720 },
    { width: 1920, height: 1080 },
    { width: 3840, height: 2160 }
  ]
  private videoProfile = {
    audioBitrate: 48000,
    audioChannels: 2,
    audioCodec: 'audio/mp4a-latm',
    audioSampleRate: 48000,
    durationTime: 1000,
    fileFormat: 'mp4',
    videoBitrate: 48000,
    videoCodec: 'video/mp4v-es',
    videoFrameWidth: 640,
    videoFrameHeight: 480,
    videoFrameRate: 30
  }
  private videoConfig = {
    audioSourceType: 1,
    videoSourceType: 0,
    profile: this.videoProfile,
    url: '',
    orientationHint: 0,
    location: { latitude: 30, longitude: 130 },
    maxSize: 100,
    maxDuration: 500
  }

  public static getInstance(): CameraService {
    if (!AppStorage.Has('app_key_camera_service')) {
      AppStorage.SetOrCreate('app_key_camera_service', new CameraService())
      console.info('build new CameraService.')
    }
    return AppStorage.Get('app_key_camera_service');
  }

  public async initCamera(surfaceId, previewImage) {
    console.info(`${this.TAG} initCamera is called.`)
    this.previewId = surfaceId
    if (this.cameraManager == undefined) {
      this.cameraManager = await camera.getCameraManager(null)
      console.info(`${this.TAG} getCameraManager success.`)
    }
    if (this.cameraInfo == undefined) {
      this.cameraInfo = await this.cameraManager.getCameras()
      console.info(`${this.TAG} getCameras success.`)
      for (let i = 0; i < this.cameraInfo.length; i++) {
        console.info(`${this.TAG} --------------Camera Info-------------`)
        console.info(`${this.TAG} camera_id: ${this.cameraInfo[i].cameraId}`)
        console.info(`${this.TAG} cameraPosition: ${this.cameraInfo[i].cameraPosition}`)
        console.info(`${this.TAG} cameraType: ${this.cameraInfo[i].cameraType}`)
        console.info(`${this.TAG} connectionType: ${this.cameraInfo[i].connectionType}`)
      }
      this.cameraId = this.cameraInfo[0].cameraId
      await this.calcSupportedSizes()
    }
    await this.changeMode_(previewImage, this.previewId)
  }

  public async startPreview(surfaceId: any, mode) {
    this.previewId = surfaceId
    await this.changeMode_(mode, this.previewId)
  }

  public getPhotoUri() {
    console.info('getPhotoUri called')
    return this.SaveCameraAsset.getPhotoUri()
  }

  public async switchCamera(surfaceId, cameraPosition) {
    this.previewId = surfaceId
    console.info('switchCamera called')
    await this.captureSession.stop()
    console.info('switchCamera captureSession.stop')
    await this.cameraInput.release()
    await this.captureSession.release()
    this.isSessionRelease = true
    console.info('switchCamera captureSession.release')

    if (cameraPosition === 'FRONT') {
      this.cameraId = this.cameraInfo[1].cameraId
      this.previewSize = [
        { width: 2048, height: 1536 },
        { width: 720, height: 720 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 }
      ]
      this.imageSize = [
        { width: 2048, height: 1536 },
        { width: 2448, height: 2448 },
        { width: 1920, height: 1080 }
      ]
      this.videoFrameSize = [
        { width: 1280, height: 720 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 }
      ]
    } else if (cameraPosition === 'BACK') {
      this.cameraId = this.cameraInfo[0].cameraId
      this.previewSize = [
        { width: 2048, height: 1536 },
        { width: 720, height: 720 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 }
      ]
      this.imageSize = [
        { width: 2048, height: 1536 },
        { width: 3120, height: 3120 },
        { width: 1920, height: 1080 }
      ]
      this.videoFrameSize = [
        { width: 1280, height: 720 },
        { width: 1920, height: 1080 },
        { width: 3840, height: 2160 }
      ]
    } else if (cameraPosition === 'MatePad Pro（前置）') {
      this.cameraId = this.cameraInfo[6].cameraId
      this.previewSize = [
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 }
      ]
      this.imageSize = [
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 }
      ]
      this.videoFrameSize = [
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 }
      ]
    } else if (cameraPosition === 'MatePad Pro（后置）') {
      this.cameraId = this.cameraInfo[5].cameraId
      this.previewSize = [
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 }
      ]
      this.imageSize = [
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 }
      ]
      this.videoFrameSize = [
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 },
        { width: 1920, height: 1080 }
      ]
    }

    console.info(`get cameraId= ${this.cameraId}`)
    this.cameraInput = await this.cameraManager.createCameraInput(this.cameraId)
    await this.calcSupportedSizes()
    console.info('switchCamera cameraManager.createCameraInput')
    await this.changeMode_(this.curMode, this.previewId)
  }

  public getThumbnail(callback) {
    this.getPixelMap.getThumbnailInfo(40, 40).then((thumbnail) => {
      console.info('getPixelMap.getThumbnailInfo called')
      this.thumbnailCallBack = callback
      this.thumbnailCallBack(thumbnail)
    })
  }

  public changeMode(mode, id) {
    console.info(`${this.TAG} changeMode() called.`)
    this.changeMode_(mode, id)
  }

  public async changeMode_(mode, id) {
    console.info(`${this.TAG} changeMode_ called.`)
    this.curMode = mode
    this.previewId = id
    if (!this.isSessionRelease) {
      await this.captureSession.stop()
      if (this.cameraInput) {
        await this.cameraInput.release()
      }
      console.info(`${this.TAG} captureSession.release() called.`)
      await this.captureSession.release()
      console.info(`${this.TAG} captureSession.release() done.`)
      this.isSessionRelease = true
    }
    this.captureSession = await camera.createCaptureSession(null)
    if (this.captureSession) {
      console.info(`${this.TAG} createCaptureSession success.`)
      this.isSessionRelease = false
      console.info(`${this.TAG} this.previewId： ${this.previewId}`)
      this.previewOutput = await camera.createPreviewOutput(this.previewId)
      this.cameraInput = await this.cameraManager.createCameraInput(this.cameraId)
      console.info(`${this.TAG} beginConfig called.`)
      await this.captureSession.beginConfig()
      await this.captureSession.addInput(this.cameraInput)
      await this.captureSession.addOutput(this.previewOutput)
      switch (mode) {
        case 'PHOTO':
          console.info(`${this.TAG} now is PHOTO mode.`)
          console.info(`${this.TAG} start.`)
          let imageWidth = this.imageSize[this.photoResolution].width
          let imageHeight = this.imageSize[this.photoResolution].height
          let mReceiver = image.createImageReceiver(imageWidth, imageHeight, 4, 8)
          console.info(`${this.TAG} end.`)
          let mSurfaceId = await mReceiver.getReceivingSurfaceId()
          await camera.createPhotoOutput(mSurfaceId).then((res) => {
            console.info(`${this.TAG} createPhotoOutput called.`)
            this.photoOutPut = res
          })
          this.SaveCameraAsset.saveImage(mReceiver, 40, 40, this.thumbnailCallBack,
            this.getPixelMap,
            (() => {
              this.captureSuccessCallBack()
            }))
          await this.captureSession.addOutput(this.photoOutPut)
          break;
        case 'VIDEO':
          console.info(`${this.TAG} now is VIDEO mode.`)
          break;
        case 'MULTI':
          console.info(`${this.TAG} now is MULTI mode.`)
          let multiImageWidth = this.imageSize[this.photoResolution].width
          let multiImageHeight = this.imageSize[this.photoResolution].height
          let multiReceiver = image.createImageReceiver(multiImageWidth, multiImageHeight, 4, 8)
          let multiSurfaceId = await multiReceiver.getReceivingSurfaceId()
          await camera.createPhotoOutput(multiSurfaceId).then((res) => {
            console.info(`${this.TAG} createPhotoOutput called.`)
            this.photoOutPut = res
          })
          this.SaveCameraAsset.saveImage(multiReceiver, 40, 40, this.thumbnailCallBack,
            this.getPixelMap,
            (() => {
              this.captureSuccessCallBack()
            }))
          await this.captureSession.addOutput(this.photoOutPut)
          break;
        default:
          break;
      }
      await this.captureSession.commitConfig()
      await this.captureSession.start()
      console.info(`${this.TAG} changeMode_ finished.`)
    } else {
      console.info(`${this.TAG} createCaptureSession failed.`)
    }
  }

  public async takePicture(callback) {
    this.captureSuccessCallBack = callback
    let photoSettings = {
      rotation: 0,
      quality: 1,
      location: {
        latitude: 12.9698,
        longitude: 77.7500
      },
      mirror: false
    }
    console.info(`${this.TAG} takePicture photoSettings ${photoSettings}`)
    await this.photoOutPut.capture(photoSettings)
    console.info(`${this.TAG} capture done.`)
  }

  public async releaseCamera() {
    console.info(`${this.TAG} releaseCamera called.`)
    await this.captureSession.stop()
    console.info(`${this.TAG} cameraInput.release called.`)
    await this.cameraInput.release()
    console.info(`${this.TAG} captureSession.release called.`)
    await this.captureSession.release()
    this.isSessionRelease = true
    console.info(`${this.TAG} releaseCamera done.`)
  }

  public async releaseCameraInput() {
    await this.cameraInput.release()
    console.info(`${this.TAG} releaseCameraInput done.`)
  }

  public async releasePreviewOutput() {
    await this.previewOutput.release()
    console.info(`${this.TAG} releasePreviewOutput done.`)
  }

  public async releasePhotoOutPut() {
    await this.photoOutPut.release()
    console.info(`${this.TAG} releasePhotoOutPut done.`)
  }

  public async startVideo(id) {
    this.previewId = id
    let videoId
    if (!this.isSessionRelease) {
      await this.captureSession.stop()
      await this.cameraInput.release()
      console.info(`${this.TAG} captureSession.release() called.`)
      await this.captureSession.release().then(() => {
        this.SaveCameraAsset.getVideoFd().then(async (fileAssets) => {
          console.info(`getFileAssets fileAssets: ${fileAssets}`);
          this.fileAsset = fileAssets[0]
          let fdNumber = await this.fileAsset.open('Rw')
          this.videoConfig.url = `fd://${fdNumber.toString()}`
          console.info(`${this.TAG} videoRecorder.prepare videoConfig.url: ${this.videoConfig.url}`)
          this.captureSession = await camera.createCaptureSession(null)
          this.cameraInput = await this.cameraManager.createCameraInput(this.cameraId)
          if (this.captureSession != null) {
            console.info(`${this.TAG} createCaptureSession success.`)
            this.isSessionRelease = false
            console.info(`${this.TAG} this.previewId： ${this.previewId}`)
            this.previewOutput = await camera.createPreviewOutput(this.previewId)
            if (this.videoRecorder) {
              await this.videoRecorder.release()
            }
            await media.createVideoRecorder().then((recorder) => {
              console.info(`${this.TAG} createVideoRecorder called.`)
              this.videoRecorder = recorder
            })
            if (this.videoRecorder != null) {
              console.info(`${this.TAG} videoRecorder.prepare called.`)
              this.videoConfig.profile.videoFrameWidth = this.videoFrameSize[this.videoResolution].width
              this.videoConfig.profile.videoFrameHeight = this.videoFrameSize[this.videoResolution].height
              await this.videoRecorder.prepare(this.videoConfig)
              console.info(`${this.TAG} videoRecorder.prepare succeed.`)
            } else {
              console.info(`${this.TAG} createVideoRecorder failed.`)
            }
            await this.videoRecorder.getInputSurface().then((resultId) => {
              console.info(`${this.TAG} getInputSurface called`)
              videoId = resultId
              console.info(`${this.TAG} getInputSurface surfaceId: ${JSON.stringify(videoId)}`)
            })
            this.videoOutput = await camera.createVideoOutput(videoId)

            await this.captureSession.beginConfig()
            await this.captureSession.addInput(this.cameraInput)
            await this.captureSession.addOutput(this.previewOutput)
            await this.captureSession.addOutput(this.videoOutput)
            await this.captureSession.commitConfig()
            await this.captureSession.start().then(async () => {
              await this.videoOutput.start().then(() => {
                console.info(`${this.TAG} videoOutput.start()`)
              })
              await this.videoRecorder.start().then(() => {
                console.info(`${this.TAG} videoRecorder.start()`)
              })
            })
          } else {
            console.info(`${this.TAG} createCaptureSession failed.`)
          }
        })
      })
      this.isSessionRelease = true
    }
  }

  public async stopVideo() {
    console.info(`${this.TAG} stopVideo called.`)

    try {
      await this.videoRecorder.stop()
    } catch (err) {
      console.info(`${this.TAG} stop videoRecorder ${err}`)
    }

    try {
      await this.videoOutput.stop()
    } catch (err) {
      console.info(`${this.TAG} stop videoOutput ${err}`)
    }

    if (this.fileAsset != undefined) {
      this.fileAsset.close()
      this.fileAsset = undefined
      console.info(`${this.TAG} fileAsset.close().`)
    }
  }

  public async pauseVideo() {
    await this.videoOutput.stop()
    await this.videoRecorder.pause()
  }

  public async releaseVideo() {
    console.info(`${this.TAG} releaseVideo called.`)
    await this.stopVideo()
    await this.videoRecorder.release().then(() => {
      console.info(`${this.TAG} videoRecorder.release() success.`)
      this.videoRecorder = undefined
    })
    await this.videoOutput.release()
  }

  public async resumeVideo() {
    await this.videoOutput.start().then(() => {
      console.info(`${this.TAG} videoOutput.start()`)
    })
    await this.videoRecorder.resume()
  }

  public async setZoomRatio(zoomRatio) {
    console.info(`setZoomRatio called zoomRatio= ${zoomRatio}`)
    await this.cameraInput.setZoomRatio(zoomRatio)
  }

  public async getZoomRatio() {
    console.info('getZoomRatio called')
    let zoomRatioValue = await this.cameraInput.getZoomRatio()
    console.info(`ZoomRatio= ${zoomRatioValue}`)
    return zoomRatioValue
  }

  public async getZoomRatioRange() {
    console.info('getZoomRatioRange called')
    let zoomRatioRange = await this.cameraInput.getZoomRatioRange()
    console.info(`zoomRatioRange= ${zoomRatioRange}`)
    return zoomRatioRange
  }

  public async calcSupportedSizes() {
    return;
    let photoSize = await this.cameraInput.getSupportedSizes(2000)
    console.info("calcSupportedSizes photoSize" + JSON.stringify(photoSize))
    this.imageSize[0] = this.getMaxSize(photoSize, 4, 3)
    this.imageSize[1] = this.getMaxSize(photoSize, 1, 1)
    this.imageSize[2] = this.getMaxSize(photoSize, 16, 9)
    this.previewSize[0] = this.imageSize[0]
    this.previewSize[1] = this.imageSize[1]
    this.previewSize[2] = this.imageSize[2]

    let previewCurSize = await this.cameraInput.getSupportedSizes(1003)
    console.info("calcSupportedSizes previewCurSize" + JSON.stringify(previewCurSize))
    this.videoFrameSize[0] = this.getSpecifiedSize(previewCurSize, 1280, 720)
    this.videoFrameSize[1] = this.getSpecifiedSize(previewCurSize, 1920, 1080)
    this.videoFrameSize[2] = this.getSpecifiedSize(previewCurSize, 3840, 2160)
    this.previewSize[3] = this.videoFrameSize[0]
    this.previewSize[4] = this.videoFrameSize[1]
    this.previewSize[5] = this.videoFrameSize[2]
  }

  public getSpecifiedSize(sizeList, width, height) {
    let specifiedSize = { width: 0, height: 0 }
    for (let i = 0; i < sizeList.length; i++) {
      let widthError = sizeList[i].width - width
      let heightError = sizeList[i].height - height
      if (widthError <= 4 && widthError >= -4 && heightError <= 4 && heightError >= -4) {
        if (sizeList[i].width > specifiedSize.width) {
          specifiedSize = sizeList[i]
        }
      }
    }
    console.log("getSpecifiedSize specifiedSize = " + JSON.stringify(specifiedSize))
    return specifiedSize
  }

  public getMaxSize(sizeList, width, height) {
    let maxSize = { width: 0, height: 0 }
    for (let i = 0; i < sizeList.length; i++) {
      let errorValue = sizeList[i].width * height - sizeList[i].height * width
      if (errorValue <= 64 && errorValue >= -64) {
        if (sizeList[i].width > maxSize.width) {
          maxSize = sizeList[i]
        }
      }
    }
    return maxSize
  }

  public getPreviewSize(mode) {
    let previewSize
    switch (mode) {
      case 'PHOTO':
        previewSize = this.previewSize[this.photoResolution]
        break;
      case 'VIDEO':
        previewSize = this.previewSize[this.videoResolution + 3]
        break;
      default:
        break;
    }
    console.log("getPreviewSize" + JSON.stringify(previewSize));
    return previewSize;
  }

  public setAspectRatio(aspectRatio) {
    switch (aspectRatio) {
      case '4:3':
        this.photoResolution = 0
        break;
      case '1:1':
        this.photoResolution = 1
        break;
      case '16:9':
        this.photoResolution = 2
        break;
      default:
        this.photoResolution = 0
        break;
    }
  }

  public setVideoResolution(videoResolution) {
    switch (videoResolution) {
      case '[16:9] 720p':
        this.videoResolution = 0
        break;
      case '[16:9] 1080p':
        this.videoResolution = 1
        break;
      case '[16:9] 4k':
        this.videoResolution = 2
        break;
      default:
        this.videoResolution = 0
        break;
    }
  }

  getDeviceInfo() {
    console.info(`${this.TAG} getDeviceInfo called.`)
    return ['MatePad Pro（前置）', 'MatePad Pro（后置）']
    let deviceNames = []
    deviceManager.createDeviceManager('com.ohos.camera', (err, manager) => {
      if (err) {
        console.info(`${this.TAG} deviceManager.createDeviceManager failed.`)
        return
      }
      console.info(`${this.TAG} deviceManager.createDeviceManager success.`)
      let deviceInfoList = manager.getTrustedDeviceListSync()
      console.info(`${this.TAG} deviceManager.deviceInfoList: ${JSON.stringify(deviceInfoList)}`)
      if (typeof (deviceInfoList) != undefined && typeof (deviceInfoList.length) != undefined) {
        deviceInfoList.forEach(item => {
          deviceNames.push(item.deviceName)
        })
      }
    })
    return deviceNames
  }

  async getCameraLists() {
    console.info(`${this.TAG} getCameraLists called.`)
    let cameras = await this.cameraManager.getCameras()
    this.cameraListInfo = cameras
    if (cameras) {
      this.cameraInfo = cameras
      console.info(`${this.TAG} getCameraLists success.`)
      for (let i = 0; i < cameras.length; i++) {
        console.info(`${this.TAG} -----------------CameraInfo--------------`)
        console.info(`${this.TAG} camera_id: ${cameras[i].cameraId}`)
        console.info(`${this.TAG} cameraPosition: ${cameras[i].cameraPosition}`)
        console.info(`${this.TAG} cameraType: ${cameras[i].cameraType}`)
        console.info(`${this.TAG} connectionType: ${cameras[i].connectionType}`)
      }
    }
  }

  getCameraName() {
    return this.curCameraName
  }

  setCameraName(name: string) {
    console.info(this.TAG + 'setCameraName ' + name)
    this.curCameraName = name
  }
}