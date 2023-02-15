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

import { PhotoMode } from '../photo/src/main/ets/photo/PhotoMode'
import { VideoMode } from '../video/src/main/ets/video/VideoMode'
import { MultiMode } from '../multi/src/main/ets/multi/MultiMode'

export class Mode {
  private TAG: string = '[Mode]:'
  private photoMode: PhotoMode = new PhotoMode()
  private videoMode: VideoMode = new VideoMode()
  private multiMode: MultiMode = new MultiMode()

  public getFunctions(mode: string): string[] {
    switch (mode) {
      case 'PHOTO':
        return this.photoMode.getFunctions()
        break;
      case 'VIDEO':
        return this.videoMode.getFunctions()
        break;
      case 'MULTI':
        return this.multiMode.getFunctions()
        break;
      default:
        return []
    }
  }
}