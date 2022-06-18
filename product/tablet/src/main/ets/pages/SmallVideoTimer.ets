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

import display from '@ohos.display';

import { Log } from '../../../../../../common/src/main/ets/default/utils/Log'
import getStore, { OhCombinedState } from '../../../../../../common/src/main/ets/default/redux/store'
import { Action } from '../../../../../../common/src/main/ets/default/redux/actions/Action'
import { EventBus } from '../../../../../../common/src/main/ets/default/worker/eventbus/EventBus'
import EventBusManager from '../../../../../../common/src/main/ets/default/worker/eventbus/EventBusManager'

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
  private timer: number = 0
  private timerTick: number = 0
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  @State state: any = {}

  @State timerPosition: number= 0

  private async onRecordPaused(data) {
    Log.info(`${this.TAG} onRecordPaused timer id: ${this.timer} E`)
    clearInterval(this.timer)
    Log.info(`${this.TAG} onRecordPaused X`)
  }

  private async onRecordResumed(data) {
    Log.info(`${this.TAG} onRecordResumed E`)
    this.setIntervalTimer()
    Log.info(`${this.TAG} onRecordResumed timer id: ${this.timer} X`)
  }

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().connect(localState, localDispatcher)(this.state)
    this.setIntervalTimer()
    display.getDefaultDisplay().then((dis) => {
      this.timerPosition = px2vp(dis.height) * (4 / 3)
    })
    this.appEventBus.on(Action.ACTION_RECORD_PAUSE, this.onRecordPaused.bind(this))
    this.appEventBus.on(Action.ACTION_RECORD_RESUME, this.onRecordResumed.bind(this))
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_RECORD_PAUSE, this.onRecordPaused.bind(this))
    this.appEventBus.off(Action.ACTION_RECORD_RESUME, this.onRecordResumed.bind(this))
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
      }
      this.state.updateSpotVisible(!this.state.isRecordingSpotVisible)
    }, 500)
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
        if (this.state.isRecordingPaused) {
          Image($r('app.media.ic_video_recording')).width(12).height(12).fillColor(Color.White)
        } else {
          if (this.state.isRecordingSpotVisible) {
            Column() {
            }.width(12).height(12).backgroundColor('#FF0000').borderRadius(6).visibility(Visibility.Visible)
          } else {
            Column() {
            }.width(12).height(12).backgroundColor('#FF0000').borderRadius(6).visibility(Visibility.Hidden)
          }
        }
        Text(`${this.state.recordingTimeDisplay.split(':')[0]}`).margin({ left: 8 }).fontSize('28fp').fontWeight(300).fontColor('#FFFFFF')
        //TODO 需要确认UX样式
//        Text(this.showMinute).margin({ left: 8 }).fontSize('28fp').fontWeight(300).fontColor('#FFFFFF')
      }.layoutWeight(1)
      Text(":").fontSize('28fp').fontWeight(300).fontColor('#FFFFFF')
      Text(`${this.state.recordingTimeDisplay.split(':')[1]}`).fontSize('28fp').fontWeight(300).fontColor('#FFFFFF').textAlign(TextAlign.Start).layoutWeight(1)
//      Text(this.showSecond).fontSize('28fp').fontWeight(300).fontColor('#FFFFFF').textAlign(TextAlign.Start).layoutWeight(1)
    }.width(this.timerPosition == 0 ? '100%' : this.timerPosition).height(48)
  }
}