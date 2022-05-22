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

import { CameraPlatformCapability } from '../Camera/CameraPlatformCapability'
import { CameraId } from './CameraId'
import { CLog } from '../Utils/CLog'

export default class AspectRatio {
  private static TAG: string = '[AspectRatio]:'
  public static readonly ALIAS = 'AspectRatio'
  public static readonly ASPECT_RATIO_4_3 = '4:3'
  public static readonly ASPECT_RATIO_1_1 = '1:1'
  public static readonly ASPECT_RATIO_16_9 = '16:9'
  public static readonly DEFAULT_VALUE = $r('app.string.photo_ratio_4_3')
  public static readonly RESOURCE_RATIO_4_3 = AspectRatio.DEFAULT_VALUE
  public static readonly RESOURCE_RATIO_1_1 = $r('app.string.photo_ratio_1_1')
  public static readonly RESOURCE_RATIO_16_9 = $r('app.string.photo_ratio_16_9')

  private static getIndex(aspectRatio: string): number {
    if (aspectRatio === AspectRatio.ASPECT_RATIO_4_3) {
      return 0
    } else if (aspectRatio === AspectRatio.ASPECT_RATIO_1_1) {
      return 1
    } else if (aspectRatio === AspectRatio.ASPECT_RATIO_16_9) {
      return 2
    }
    return 0
  }

  public static getPhotoPreviewSize(platform: CameraPlatformCapability, cameraId: CameraId, aspectRatio: string) {
    let index = AspectRatio.getIndex(aspectRatio)
    CLog.info(`${this.TAG} getPhotoPreviewSize size = ${JSON.stringify(platform.mPhotoPreviewSize[index])}`)
    return platform.mPhotoPreviewSize[index]
  }

  public static getImageSize(platform: CameraPlatformCapability, cameraId: CameraId, aspectRatio: string) {
    let index = AspectRatio.getIndex(aspectRatio)
    CLog.info(`${this.TAG} getImageSize size = ${JSON.stringify(platform.mImageSize[index])}`)
    return platform.mImageSize[index]
  }

  public static convertToResource(aspectRatio: string): Resource {
    switch (aspectRatio) {
      case AspectRatio.ASPECT_RATIO_4_3:
        return AspectRatio.RESOURCE_RATIO_4_3
      case AspectRatio.ASPECT_RATIO_1_1:
        return AspectRatio.RESOURCE_RATIO_1_1
      case AspectRatio.ASPECT_RATIO_16_9:
        return AspectRatio.RESOURCE_RATIO_16_9
      default:
        return AspectRatio.DEFAULT_VALUE
    }
  }

  public static convertToString(res: Resource): String {
    if (JSON.stringify(res) === JSON.stringify(AspectRatio.RESOURCE_RATIO_4_3)) {
      return AspectRatio.ASPECT_RATIO_4_3
    } else if (JSON.stringify(res) == JSON.stringify(AspectRatio.RESOURCE_RATIO_1_1)) {
      return AspectRatio.ASPECT_RATIO_1_1
    } else if (JSON.stringify(res) == JSON.stringify(AspectRatio.RESOURCE_RATIO_16_9)) {
      return AspectRatio.ASPECT_RATIO_16_9
    }
  }
}