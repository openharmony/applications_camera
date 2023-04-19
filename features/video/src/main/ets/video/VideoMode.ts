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

import { Log, FunctionId } from '@ohos/common'
import { VideoModeParam } from './VideoModeParam'

const TAG: string = '[VideoMode]:'

export class VideoMode {
  private videoModeParam: VideoModeParam = new VideoModeParam()

  public getTabBarParam(): string[] {
    return this.videoModeParam.tabBar
  }

  public getFunctions(): FunctionId[] {
    Log.info(`${TAG} function = ${this.videoModeParam.functions}`)
    return this.videoModeParam.functions
  }
}