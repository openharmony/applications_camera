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

import deviceInfo from '@ohos.deviceInfo'

import { Log } from '../utils/Log'

export class CameraPlatformCapability {
  private TAG = '[CameraPlatformCapability]:'
  public mZoomRatioRangeMap = new Map()
  public mPhotoPreviewSizeMap = new Map()
  public mVideoPreviewSizeMap = new Map()
  public mImageSizeMap = new Map()
  public mVideoFrameSizeMap = new Map()
  public mCameraCount = 0
  // TODO 需要针对不同设备固定不同的值
  public mPhotoPreviewSize = [
    { width: 640, height: 480 }, //Photo 4:3
    { width: 720, height: 720 }, //Photo 1:1
    { width: 1920, height: 1080 }, //Photo 16:9
  ]
  public mVideoPreviewSize = [
    { width: 1280, height: 720 }, //Video 16:9 720p
    { width: 1920, height: 1080 }, //Video 16:9 1080p
    { width: 1920, height: 1080 } //Video 16:9 4k
  ]
  public mImageSize = [
    { width: 1280, height: 960 }, //4:3
    { width: 3120, height: 3120 }, //1:1
    { width: 1920, height: 1080 } //16:9
  ]
  public mVideoFrameSize = [
    { width: 1280, height: 720 }, //16:9 720p
    { width: 1920, height: 1080 }, //16:9 1080p
    { width: 3840, height: 2160 } //16:9 4k
  ]

  constructor() {
  }

  public static getInstance(): CameraPlatformCapability {
    if (!globalThis?.sInstanceCapability) {
      globalThis.sInstanceCapability = new CameraPlatformCapability()
    }
    return globalThis.sInstanceCapability;
  }

  public async init(cameraCount: number) {
    Log.info(`${this.TAG} init E.`)
    this.mCameraCount = cameraCount
    Log.info(`${this.TAG} init X.`)
  }

  public async calcSupportedSizes(cameraInput, outputCapability) {
    Log.info(`${this.TAG} calcSupportedSizes start.`)
    if (deviceInfo.deviceType == 'default') {
      return
    }
    const photoSize = outputCapability.photoProfiles //CAMERA_FORMAT_JPEG
    const previewCurSize = outputCapability.previewProfiles //CAMERA_FORMAT_YCRCb_420_SP

    this.mImageSize[0] = this.getMaxSize(photoSize, 4, 3)
    this.mImageSize[1] = this.getMaxSize(photoSize, 1, 1)
    this.mImageSize[2] = this.getMaxSize(photoSize, 16, 9)
    this.mPhotoPreviewSize[0] = this.getMaxSize(previewCurSize, 4, 3)
    this.mPhotoPreviewSize[1] = this.getMaxSize(previewCurSize, 1, 1)
    this.mPhotoPreviewSize[2] = this.getMaxSize(previewCurSize, 16, 9)

    this.mVideoFrameSize[0] = this.getSpecifiedSize(previewCurSize, 1280, 720)
    this.mVideoFrameSize[1] = this.getSpecifiedSize(previewCurSize, 1920, 1080)
    this.mVideoFrameSize[2] = this.getSpecifiedSize(previewCurSize, 3840, 2160)
    this.mVideoPreviewSize[0] = this.mVideoFrameSize[0]
    this.mVideoPreviewSize[1] = this.mVideoFrameSize[1]
    this.mVideoPreviewSize[2] = this.mVideoFrameSize[2]
    Log.info(`${this.TAG} calcSupportedSizes end.`)
  }

  private getMaxSize(sizeList, width: number, height: number) {
    const maxSize = { width: 0, height: 0 }
    const fitList = []
    for (let i = 0; i < sizeList.length; i++) {
      const errorValue = sizeList[i].size.width * height - sizeList[i].size.height * width
      if (errorValue <= 4 && errorValue >= -4) {
        fitList.push(sizeList[i])
      }
    }
    if (fitList.length == 0) {
      Log.error(`${this.TAG} calc failed based on the supportedSizesList, try default value.`)
      maxSize.width = 640
      maxSize.height = 480
      Log.info(`${this.TAG} -----------SupportedSizes List Start-----------`)
      for (let i = 0; i < sizeList.length; i++) {
        Log.info(`${this.TAG} supportedSize width: ${sizeList[i].size.width} height: ${sizeList[i].size.height}`)
      }
      Log.info(`${this.TAG} -----------SupportedSizes List End-----------`)
      return maxSize
    } else {
      const index = Math.floor(fitList.length / 2)
      maxSize.width = fitList[index].size.width
      maxSize.height = fitList[index].size.height
    }
    return maxSize
  }

  private getSpecifiedSize(sizeList, width: number, height: number) {
    const specifiedSize = { width: 0, height: 0 }
    for (let i = 0; i < sizeList.length; i++) {
      const widthError = sizeList[i].size.width - width
      const heightError = sizeList[i].size.height - height
      if (widthError <= 4 && widthError >= -4 && heightError <= 4 && heightError >= -4) {
        if (sizeList[i].size.width > specifiedSize.width) {
          specifiedSize.width = sizeList[i].size.width
          specifiedSize.height = sizeList[i].size.height
        }
      }
    }
    if (specifiedSize.width == 0) {
      Log.error(`${this.TAG} calc failed based on the supportedSizesList, try default value.`)
      specifiedSize.width = 1920
      specifiedSize.height = 1080
    }
    return specifiedSize
  }

  public async getZoomRatioRange(captureSession) {
    Log.info(`${this.TAG} getZoomRatioRange called`)
    const zoomRatioRange = await captureSession.getZoomRatioRange()
    Log.info(`${this.TAG} zoomRatioRange= ${zoomRatioRange}`)
    return zoomRatioRange
  }
}