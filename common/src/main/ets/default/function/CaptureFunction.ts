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

import { Action } from '../redux/actions/Action'
import { Log } from '../utils/Log'
import { Function } from './Function'

export class CaptureFunction extends Function {
  private TAG = '[CaptureFunction]:'

  private async capture(): Promise<void> {
    Log.info(`${this.TAG} capture E`)
    globalThis.startCaptureTime = new Date().getTime()
    this.disableUi()
    await this.mCameraService.takePicture()
    this.enableUi()
    Log.info(`${this.TAG} capture X`)
  }

  load(): void{
    Log.info(`${this.TAG} load E`)
    this.mEventBus.on(Action.ACTION_CAPTURE, this.capture.bind(this))
    Log.info(`${this.TAG} load X`)
  }

  unload(): void {
    Log.info(`${this.TAG} unload E`)
    this.mEventBus.off(Action.ACTION_CAPTURE, this.capture.bind(this))
    Log.info(`${this.TAG} unload X`)

  }
}