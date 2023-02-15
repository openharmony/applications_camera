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

import { Action, UiStateMode } from '../redux/actions/Action'
import { Log } from '../utils/Log'
import { BaseFunction } from './BaseFunction'

export class CaptureFunction extends BaseFunction {
  private TAG = '[CaptureFunction]:'

  private async capture(): Promise<void> {
    Log.info(`${this.TAG} capture E`)
    globalThis.startCaptureTime = new Date().getTime()
    this.disableUiWithMode(UiStateMode.EXCLUDE_PREVIEW)
    await this.mCameraService.takePicture()
    Log.info(`${this.TAG} capture X`)
  }

  private onCapturePhotoOutput(){
    Log.info(`${this.TAG} onCapturePhotoOutput E`)
    this.enableUiWithMode(UiStateMode.EXCLUDE_PREVIEW)
    Log.info(`${this.TAG} onCapturePhotoOutput X`)
  }

  load(): void{
    Log.info(`${this.TAG} load E`)
    this.mEventBus.on(Action.ACTION_CAPTURE, this.capture.bind(this))
    this.mEventBus.on(Action.ACTION_CAPTURE_PHOTO_OUTPUT, this.onCapturePhotoOutput.bind(this))
    Log.info(`${this.TAG} load X`)
  }

  unload(): void {
    Log.info(`${this.TAG} unload E`)
    this.mEventBus.off(Action.ACTION_CAPTURE, this.capture.bind(this))
    this.mEventBus.off(Action.ACTION_CAPTURE_PHOTO_OUTPUT, this.onCapturePhotoOutput.bind(this))
    Log.info(`${this.TAG} unload X`)

  }
}