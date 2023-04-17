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

import display from '@ohos.display'

import { Action }  from '@ohos/common/src/main/ets/default/redux/actions/Action'
import { EventBus }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus'
import { EventBusManager }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager'
import { Log } from '@ohos/common/src/main/ets/default/utils/Log'
import { getStore, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store'

let localState = (state: OhCombinedState) => {
  return {
    recordingTime: state.RecordReducer.recordingTime,
    recordingTimeDisplay: state.RecordReducer.recordingTimeDisplay,
    isRecordingPaused: state.RecordReducer.isRecordingPaused,
    isRecordingSpotVisible: state.RecordReducer.isRecordingSpotVisible,
  }
}

let localDispatcher = (dispatch) => {
  return {
    updateRecordingTime: (recordingTime: number) => {
      dispatch(Action.updateRecordingTime(recordingTime))
    },
    updateSmallVideoTimerVisible: (visible: boolean) => {
      dispatch(Action.updateSmallVideoTimerVisible(visible))
    },
    updateBigVideoTimerVisible: (visible: boolean) => {
      dispatch(Action.updateBigVideoTimerVisible(visible))
    },
    updateRecordingSpotVisible: (visible: boolean) => {
      dispatch(Action.updateRecordingSpotVisible(visible))
    },
    updateRecordingTimeDisplay: (timeDisplay: string) => {
      dispatch(Action.updateRecordingTimeDisplay(timeDisplay))
    }
  }
}

class StateStruct {
  recordingTime
  recordingTimeDisplay
  isRecordingPaused
  isRecordingSpotVisible
  updateRecordingTime: Function
  updateSmallVideoTimerVisible: Function
  updateBigVideoTimerVisible: Function
  updateRecordingSpotVisible: Function
  updateRecordingTimeDisplay: Function
}

@Component
export struct BigVideoTimer {
  private TAG: string = '[BigVideoTimer]'
  private timer: number = 0
  private timerTick: number = 0
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  @State state: StateStruct = new StateStruct()

  private async onRecordPausedBig(data) {
    Log.info(`${this.TAG} onRecordPaused timer id: ${this.timer} E`)
    clearInterval(this.timer)
    Log.info(`${this.TAG} onRecordPaused X`)
  }

  private async onRecordResumedBig(data) {
    Log.info(`${this.TAG} onRecordResumed E`)
    if (this.state.recordingTime <= 2) {
      this.setIntervalTimer()
    }
    Log.info(`${this.TAG} onRecordResumed X`)
  }

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().connect(localState, localDispatcher)(this.state)
    this.setIntervalTimer()
    this.appEventBus.on(Action.ACTION_RECORD_PAUSE, this.onRecordPausedBig.bind(this))
    this.appEventBus.on(Action.ACTION_RECORD_RESUME, this.onRecordResumedBig.bind(this))
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_RECORD_PAUSE, this.onRecordPausedBig.bind(this))
    this.appEventBus.off(Action.ACTION_RECORD_RESUME, this.onRecordResumedBig.bind(this))
    Log.info(`${this.TAG} clearInterval timer id: ${this.timer}`)
    clearInterval(this.timer)
    Log.info(`${this.TAG} aboutToDisappear X`)
  }

  private setIntervalTimer() {
    clearInterval(this.timer)
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
        if (this.state.recordingTime > 2) {
          clearInterval(this.timer)
          this.state.updateSmallVideoTimerVisible(true)
          this.state.updateBigVideoTimerVisible(false)
        }
      }
      this.state.updateRecordingSpotVisible(!this.state.isRecordingSpotVisible)
    }, 500)
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text('').layoutWeight(1)
      if (this.state.isRecordingPaused) {
        Image($r('app.media.ic_video_recording')).width(12).height(12).fillColor(Color.White)
      } else {
        if (this.state.isRecordingSpotVisible) {
          Column() {
          }
          .width(12)
          .height(12)
          .backgroundColor('#FF0000')
          .borderRadius(6)
          .visibility(Visibility.Visible)
        } else {
          Column() {
          }
          .width(12)
          .height(12)
          .backgroundColor('#FF0000')
          .borderRadius(6)
          .visibility(Visibility.Hidden)
        }
      }
      Text(`${this.state.recordingTimeDisplay}`)
        .margin({ left: 8, right: 8 })
        .fontSize('50fp')
        .fontWeight(300)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
      Text('').width(12).height(12)
      Text('').layoutWeight(1)
    }.width('100%').height(96)
  }
}