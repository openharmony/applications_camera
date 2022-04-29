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

import { CameraService } from './CameraService'
import { CameraId } from '../setting/CameraId'
import { CLog } from '../Utils/CLog'

export class CameraPlatformCapability {
  private TAG: string = '[CameraPlatformCapability]:'
  public mZoomRatioRangeMap = new Map()
  public mPhotoPreviewSizeMap = new Map()
  public mVideoPreviewSizeMap = new Map()
  public mImageSizeMap = new Map()
  public mVideoFrameSizeMap = new Map()
  public mCameraCount = 0
  // TODO 需要针对不同设备固定不同的值
  private mPhotoPreviewSize = [
    { width: 640, height: 480 }, //Photo 4:3
    { width: 720, height: 720 }, //Photo 1:1
    { width: 1920, height: 1080 }, //Photo 16:9
  ]
  private mVideoPreviewSize = [
    { width: 1920, height: 1080 }, //Video 16:9 720p
    { width: 1920, height: 1080 }, //Video 16:9 1080p
    { width: 1920, height: 1080 } //Video 16:9 4k
  ]
  private mImageSize = [
    { width: 1280, height: 960 }, //4:3
    { width: 3120, height: 3120 }, //1:1
    { width: 1920, height: 1080 } //16:9
  ]
  private mVideoFrameSize = [
    { width: 1280, height: 960 }, //16:9 720p
    { width: 1920, height: 1080 }, //16:9 1080p
    { width: 3840, height: 2160 } //16:9 4k
  ]

  constructor() {
  }

  public async init() {
    CLog.info(`${this.TAG} init E.`)
    this.mCameraCount = CameraService.getInstance().getCameraCount()
    var cameraIds = [CameraId.BACK, CameraId.FRONT]
    for (let id of cameraIds) {

      // TODO 从底层获取支持的能力
      this.mZoomRatioRangeMap[id] = { min: 1, max: 6 }
      this.mPhotoPreviewSizeMap[id] = JSON.parse(JSON.stringify(this.mPhotoPreviewSize))
      this.mVideoPreviewSizeMap[id] = JSON.parse(JSON.stringify(this.mVideoPreviewSize))
      this.mImageSizeMap[id] = JSON.parse(JSON.stringify(this.mImageSize))
      this.mVideoFrameSizeMap[id] = JSON.parse(JSON.stringify(this.mVideoFrameSize))
    }

    CLog.info(`${this.TAG} init mZoomRatioRangeMap = ${JSON.stringify(this.mZoomRatioRangeMap)} `)
    CLog.info(`${this.TAG} init mPhotoPreviewSizeMap = ${JSON.stringify(this.mPhotoPreviewSizeMap)} `)
    CLog.info(`${this.TAG} init mVideoPreviewSizeMap = ${JSON.stringify(this.mVideoPreviewSizeMap)} `)
    CLog.info(`${this.TAG} init mImageSizeMap = ${JSON.stringify(this.mImageSizeMap)} `)
    CLog.info(`${this.TAG} init mVideoFrameSizeMap = ${JSON.stringify(this.mVideoFrameSizeMap)} `)
    CLog.info(`${this.TAG} init X.`)
  }

  private async calcSupportedSizes(cameraInput) {
    return; //TODO 待获取能力接口可用后，删除
    //TODO：目前认为，支持的photo size，preview size一定是支持的
    //TODO: 当取得相应的比例会或分辨率的size为(0, 0)时，说明不支持该size
    CLog.info(`${this.TAG} calcSupportedSizes called.`)
    let photoSize = await cameraInput.getSupportedSizes(2000) //CAMERA_FORMAT_JPEG
    CLog.info(`${this.TAG} calcSupportedSizes photoSize ${JSON.stringify(photoSize)}`)
    this.mImageSize[0] = this.getMaxSize(photoSize, 4, 3)
    this.mImageSize[1] = this.getMaxSize(photoSize, 1, 1)
    this.mImageSize[2] = this.getMaxSize(photoSize, 16, 9)
    this.mPhotoPreviewSize[0] = this.mImageSize[0]
    this.mPhotoPreviewSize[1] = this.mImageSize[1]
    this.mPhotoPreviewSize[2] = this.mImageSize[2]

    //TODO：目前认为，支持的preview size，videoRecorder一定是支持的
    let previewCurSize = await cameraInput.getSupportedSizes(1003) //CAMERA_FORMAT_YCRCb_420_SP
    CLog.info(`${this.TAG} calcSupportedSizes previewCurSize ${JSON.stringify(previewCurSize)}`)
    this.mVideoFrameSize[0] = this.getSpecifiedSize(previewCurSize, 1280, 720)
    this.mVideoFrameSize[1] = this.getSpecifiedSize(previewCurSize, 1920, 1080)
    this.mVideoFrameSize[2] = this.getSpecifiedSize(previewCurSize, 3840, 2160)
    this.mVideoPreviewSize[0] = this.mVideoFrameSize[0]
    this.mVideoPreviewSize[1] = this.mVideoFrameSize[1]
    this.mVideoPreviewSize[2] = this.mVideoFrameSize[2]
  }

  private getMaxSize(sizeList, width, height) {
    let maxSize = { width: 0, height: 0 }
    for (let i = 0; i < sizeList.length; i++) {
      let errorValue = sizeList[i].width * height - sizeList[i].height * width
      if (errorValue <= 64 && errorValue >= -64) { //TODO 误差范围要测算，目前考虑16:9的情况，有4个像素差
        if (sizeList[i].width > maxSize.width) {
          maxSize = sizeList[i]
        }
      }
    }
    return maxSize
  }

  private getSpecifiedSize(sizeList, width, height) {
    let specifiedSize = { width: 0, height: 0 }
    for (let i = 0; i < sizeList.length; i++) {
      let widthError = sizeList[i].width - width
      let heightError = sizeList[i].height - height
      //TODO 误差范围要测算，目前考虑有4个像素差
      if (widthError <= 4 && widthError >= -4 && heightError <= 4 && heightError >= -4) {
        if (sizeList[i].width > specifiedSize.width) {
          specifiedSize = sizeList[i]
        }
      }
    }
    CLog.log(`${this.TAG} getSpecifiedSize specifiedSize =  ${JSON.stringify(specifiedSize)}`)
    return specifiedSize
  }

  public async getZoomRatioRange(cameraInput) {
    CLog.info(`${this.TAG} getZoomRatioRange called`)
    let zoomRatioRange = await cameraInput.getZoomRatioRange()
    CLog.info(`${this.TAG} zoomRatioRange= ${zoomRatioRange}`)
    return zoomRatioRange
  }
}