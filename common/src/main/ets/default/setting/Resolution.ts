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

export default class Resolution {
  private static TAG: string = '[Resolution]:'
  public static readonly ALIAS = 'VideoResolution'
  public static readonly RESOLUTION_16_9_720P = '[16:9] 720p'
  public static readonly RESOLUTION_16_9_1080P = '[16:9] 1080p'
  public static readonly RESOLUTION_16_9_4K = '[16:9] 4k'
  public static readonly DEFAULT_VALUE = Resolution.RESOLUTION_16_9_720P

  private static getIndex(resolution: string): number {
    if (resolution === Resolution.RESOLUTION_16_9_720P) {
      return 0
    } else if (resolution === Resolution.RESOLUTION_16_9_1080P) {
      return 1
    } else if (resolution === Resolution.RESOLUTION_16_9_4K) {
      return 2
    }
    return 0
  }

  public static getVideoPreviewSize(platform: CameraPlatformCapability, cameraId: CameraId, resolution: string) {
    let index = Resolution.getIndex(resolution)
    CLog.info(`${this.TAG} getVideoPreviewSize size = ${JSON.stringify(platform.mVideoPreviewSize[index])}`)
    return platform.mVideoPreviewSize[index]
  }

  public static getVideoFrameSize(platform: CameraPlatformCapability, cameraId: CameraId, resolution: string) {
    let index = Resolution.getIndex(resolution)
    CLog.info(`${this.TAG} getVideoFrameSize size = ${JSON.stringify(platform.mVideoFrameSize[index])}`)
    return platform.mVideoFrameSize[index]
  }
}