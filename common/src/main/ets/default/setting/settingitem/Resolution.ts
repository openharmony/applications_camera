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

import { CameraPlatformCapability } from '../../camera/CameraPlatformCapability'
import { CameraId } from './CameraId'
import { Log } from '../../utils/Log'

export default class Resolution {
  private static TAG = '[Resolution]:'
  public static readonly ALIAS = 'VideoResolution'
  public static readonly RESOLUTION_16_9_720P = '[16:9] 720p'
  public static readonly RESOLUTION_16_9_1080P = '[16:9] 1080p'
  public static readonly DEFAULT_VALUE = $r('app.string.resolution_1280_720')
  public static readonly RESOURCE_16_9_720P = Resolution.DEFAULT_VALUE
  public static readonly RESOURCE_16_9_1080P = $r('app.string.resolution_1620_1080')

  private static getIndex(resolution: Resource): number {
    if (resolution.id === Resolution.RESOURCE_16_9_720P.id) {
      return 0
    } else if (resolution.id === Resolution.RESOURCE_16_9_1080P.id) {
      return 1
    }
    return 0
  }

  public static getVideoPreviewSize(platform: CameraPlatformCapability, cameraId: string, resolution: Resource) {
    const index = Resolution.getIndex(resolution)
    Log.info(`${this.TAG} getVideoPreviewSize size = ${JSON.stringify(platform.mVideoPreviewSize[index])}`)
    return platform.mVideoPreviewSize[index]
  }

  public static getVideoFrameSize(platform: CameraPlatformCapability, cameraId: string, resolution: Resource) {
    const index = Resolution.getIndex(resolution)
    Log.info(`${this.TAG} getVideoFrameSize size = ${JSON.stringify(platform.mVideoFrameSize[index])}`)
    return platform.mVideoFrameSize[index]
  }

  public static convertToResource(resolution: string): Resource {
    switch (resolution) {
    case Resolution.RESOLUTION_16_9_720P:
      return Resolution.RESOURCE_16_9_720P
    case Resolution.RESOLUTION_16_9_1080P:
      return Resolution.RESOURCE_16_9_1080P
    default:
      return Resolution.RESOURCE_16_9_720P
    }
  }

  public static convertToString(res: Resource): string {
    if (res.id === Resolution.RESOURCE_16_9_720P.id) {
      return Resolution.RESOLUTION_16_9_720P
    } else if(res.id === Resolution.RESOURCE_16_9_1080P.id) {
      return Resolution.RESOLUTION_16_9_1080P
    }
  }
}