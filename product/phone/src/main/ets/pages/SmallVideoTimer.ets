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

import { CLog } from '../../../../../../common/src/main/ets/default/Utils/CLog'
import getStore from '../../../../../../common/src/main/ets/default/redux/store'
import { Action } from '../../../../../../common/src/main/ets/default/redux/actions/Action'
import { EventBus } from '../../../../../../common/src/main/ets/default/Utils/EventBus'
import EventBusManager from '../../../../../../common/src/main/ets/default/Utils/EventBusManager'

let localState = (state) => {
  return {
    recordingTime: state.RecordReducer.recordingTime,
    recordingTimeDisplay: state.RecordReducer.recordingTimeDisplay,
    isRecordingPaused: state.RecordReducer.isRecordingPaused,
    isRecordingSpotVisible: state.UiReducer.isRecordingSpotVisible,
  }
}

let localDispatcher = (dispatch) => {
  return {
    updateSpotVisible: (visible: boolean) => {
      dispatch(Action.UpdateRecordingSpotVisible(visible))
    },
    updateRecordingTime: (recordingTime: number) => {
      dispatch(Action.UpdateRecordingTime(recordingTime))
    },
    updateRecordingTimeDisplay: (timeDisplay: string) => {
      dispatch(Action.UpdateRecordingTimeDisplay(timeDisplay))
    }
  }
}

@Component
export struct SmallVideoTimer {
  private TAG: string = '[SmallVideoTimer]'
  private mConnect: any
  private timer: number = 0
  private timerTick: number = 0
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  @State state: any = {}

  private async onRecordPaused(data) {
    CLog.info(`${this.TAG} onRecordPaused timer id: ${this.timer} E`)
    clearInterval(this.timer)
    CLog.info(`${this.TAG} onRecordPaused X`)
  }

  private async onRecordResumed(data) {
    CLog.info(`${this.TAG} onRecordResumed E`)
    this.setIntervalTimer()
    CLog.info(`${this.TAG} onRecordResumed timer id: ${this.timer} X`)
  }

  aboutToAppear() {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    this.setIntervalTimer()
    this.appEventBus.on(Action.ACTION_RECORD_PAUSE, this.onRecordPaused.bind(this))
    this.appEventBus.on(Action.ACTION_RECORD_RESUME, this.onRecordResumed.bind(this))
    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_RECORD_PAUSE, this.onRecordPaused.bind(this))
    this.appEventBus.off(Action.ACTION_RECORD_RESUME, this.onRecordResumed.bind(this))
    clearInterval(this.timer)
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  private setIntervalTimer() {
    this.timer = setInterval(() => {
      this.timerTick++
      if (this.timerTick % 2 === 0) {
        this.state.updateRecordingTime(this.state.recordingTime + 1)
        let shownSec = '00'
        let shownMin = '00'
        let sec = this.state.recordingTime % 60
        if (sec < 10) {
          shownSec = `0${sec}`
        } else {
          shownSec = `${sec}`
        }
        let minute = Math.floor(this.state.recordingTime / 60)
        if (minute < 10) {
          shownMin = `0${minute}`
        } else {
          shownMin = `${minute}`
        }
        this.state.updateRecordingTimeDisplay(`${shownMin}:${shownSec}`)
      }
      this.state.updateSpotVisible(!this.state.isRecordingSpotVisible)
    }, 500)
  }

  build() {
    Column() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        Row() {
          Text('').layoutWeight(1)
          if (this.state.isRecordingPaused) {
            Image($r('app.media.ic_video_recording'))
              .width(12).height(12)
              .fillColor(Color.White)
          } else {
            if (this.state.isRecordingSpotVisible) {
              Column() {
              }.width(12).height(12).borderRadius(6)
              .backgroundColor(Color.Red).visibility(Visibility.Visible)
            } else {
              Column() {
              }.width(12).height(12).borderRadius(6)
              .backgroundColor(Color.Red).visibility(Visibility.Hidden)
            }
          }
          Text(`${this.state.recordingTimeDisplay}`)
            .margin({ left: 8, right: 8 })
            .textAlign(TextAlign.Center)
            .fontSize('28fp')
            .fontColor(Color.White)
            .fontWeight(300)
          Text('').width(12).height(12)
          Text('').layoutWeight(1)
        }
      }
    }.width('100%').height(48).position({ x: 0, y: -48 })
  }
}