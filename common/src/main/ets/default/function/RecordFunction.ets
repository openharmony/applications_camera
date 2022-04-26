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
import { CLog } from '../Utils/CLog'
import { Function } from "./Function"

export class RecordFunction extends Function {
  private TAG: string = '[RecordFunction]:'

  private async startRecording() {
    CLog.info(`${this.TAG} startRecording E`)
    await this.mCameraService.StartRecording()
    // TODO update video status in State by sending action
    // temp code
    this.mWorkerManager.postMessage(Action.UpdateRecordingPaused(false))
    this.enableUi()
    CLog.info(`${this.TAG} startRecording X`)
  }

  private async pauseRecording() {
    CLog.info(`${this.TAG} pauseRecording E`)
    await this.mCameraService.pauseRecording()
    // TODO update video status in State by sending action
    // temp code
    this.mWorkerManager.postMessage(Action.UpdateRecordingPaused(true))
    this.enableUi()
    CLog.info(`${this.TAG} pauseRecording X`)
  }

  private async resumeRecording() {
    CLog.info(`${this.TAG} resumeRecording E`)
    await this.mCameraService.resumeRecording()
    // TODO update video status in State by sending action
    // temp code
    this.mWorkerManager.postMessage(Action.UpdateRecordingPaused(false))
    this.enableUi()
    CLog.info(`${this.TAG} resumeRecording X`)
  }

  private async stopRecording() {
    CLog.info(`${this.TAG} stopRecording E`)
    let thumbnailPixelMap = await this.mCameraService.stopRecording()
    // TODO update video status in State by sending action
    // temp code
    this.mWorkerManager.postMessage(Action.UpdateRecordingTime(0))
    this.mWorkerManager.postMessage(Action.UpdateRecordingTimeDisplay('00:00'))
    this.mWorkerManager.postMessage(Action.UpdateRecordingSpotVisible(false))
    this.mWorkerManager.postMessage(Action.UpdateRecordingPaused(false))
    this.mWorkerManager.postMessage(Action.UpdateThumbnail(thumbnailPixelMap))
    this.enableUi()
    CLog.info(`${this.TAG} stopRecording X`)
  }

  load(): void{
    this.mEventBus.on(Action.ACTION_RECORD_START, this.startRecording.bind(this))
    this.mEventBus.on(Action.ACTION_RECORD_PAUSE, this.pauseRecording.bind(this))
    this.mEventBus.on(Action.ACTION_RECORD_RESUME, this.resumeRecording.bind(this))
    this.mEventBus.on(Action.ACTION_RECORD_STOP, this.stopRecording.bind(this))
  }

  unload(): void {
    this.mEventBus.off(Action.ACTION_RECORD_START, this.startRecording.bind(this))
    this.mEventBus.off(Action.ACTION_RECORD_PAUSE, this.pauseRecording.bind(this))
    this.mEventBus.off(Action.ACTION_RECORD_RESUME, this.resumeRecording.bind(this))
    this.mEventBus.off(Action.ACTION_RECORD_STOP, this.stopRecording.bind(this))
  }
}