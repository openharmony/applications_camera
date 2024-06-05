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

import { Action } from '@ohos/common/src/main/ets/default/redux/actions/Action';
import { EventBus } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus';
import { EventBusManager } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager';
import { Dispatch, getStore, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store';
import { Log } from '@ohos/common/src/main/ets/default/utils/Log';
import { GlobalContext } from '@ohos/common/src/main/ets/default/utils/GlobalContext';

class StateStruct {
  recordingTime: number = 0;
  recordingTimeDisplay: string = '';
  isRecordingPaused: boolean = false;
  isRecordingSpotVisible: boolean = true;
  isThirdPartyCall: boolean = false;
}

class SmallVideoTimerDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public updateSpotVisible(visible: boolean): void {
    this.mDispatch(Action.updateRecordingSpotVisible(visible));
  }

  public updateRecordingTime(recordingTime: number): void {
    this.mDispatch(Action.updateRecordingTime(recordingTime));
  }

  public updateRecordingTimeDisplay(timeDisplay: string): void {
    this.mDispatch(Action.updateRecordingTimeDisplay(timeDisplay));
  }

  public stopRecording(): void {
    this.mDispatch(Action.stopRecording())
    this.mDispatch(Action.updateVideoState('beforeTakeVideo'))
    this.mDispatch(Action.updateBigVideoTimerVisible(false))
    this.mDispatch(Action.updateSmallVideoTimerVisible(false))
    this.mDispatch(Action.updateScreenStatus(false))
  }
}

@Component
export struct SmallVideoTimer {
  private TAG: string = '[SmallVideoTimer]';
  private timer: number = 0;
  private timerTick: number = 0;
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State state: StateStruct = new StateStruct();
  private mAction: SmallVideoTimerDispatcher = new SmallVideoTimerDispatcher();

  private async onRecordPausedSmall() {
    Log.info(`${this.TAG} onRecordPaused timer id: ${this.timer} E`)
    clearInterval(this.timer)
    Log.info(`${this.TAG} onRecordPaused X`)
  }

  private async onRecordResumedSmall() {
    Log.info(`${this.TAG} onRecordResumed E`)
    this.setIntervalTimer()
    Log.info(`${this.TAG} onRecordResumed timer id: ${this.timer} X`)
  }

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        recordingTime: state.recordReducer.recordingTime,
        recordingTimeDisplay: state.recordReducer.recordingTimeDisplay,
        isRecordingPaused: state.recordReducer.isRecordingPaused,
        isRecordingSpotVisible: state.recordReducer.isRecordingSpotVisible,
        isThirdPartyCall: state.contextReducer.isThirdPartyCall,
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });

    this.setIntervalTimer()
    this.appEventBus.on(Action.ACTION_RECORD_PAUSE, () => this.onRecordPausedSmall())
    this.appEventBus.on(Action.ACTION_RECORD_RESUME, () => this.onRecordResumedSmall())
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_RECORD_PAUSE, () => this.onRecordPausedSmall())
    this.appEventBus.off(Action.ACTION_RECORD_RESUME, () => this.onRecordResumedSmall())
    clearInterval(this.timer)
    Log.info(`${this.TAG} aboutToDisappear X`)
  }

  private setIntervalTimer(): void {
    clearInterval(this.timer)
    this.timer = setInterval(() => {
      this.timerTick++
      if (this.timerTick % 2 === 0) {
        this.mAction.updateRecordingTime(this.state.recordingTime + 1)
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
        this.mAction.updateRecordingTimeDisplay(`${shownMin}:${shownSec}`)
      }
      this.mAction.updateSpotVisible(!this.state.isRecordingSpotVisible)
      if (this.state.isThirdPartyCall && GlobalContext.get().getCameraAbilityWant().parameters?.videoDuration) {
        try {
          let videoDuration: number = Number.parseInt(GlobalContext.get().getCameraAbilityWant().parameters?.videoDuration as string)
          Log.info(`${this.TAG} videoDuration is ${videoDuration}`);
          if (this.state.recordingTime >= videoDuration) {
            this.mAction.stopRecording();
          }
        } catch (error) {
          Log.info(`${this.TAG} picker videoDuration --> ${JSON.stringify(error)}}`)
        }
      }
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
        Text(`${this.state.recordingTimeDisplay.split(':')[0]}`)
          .margin({ left: 8 })
          .fontSize('28fp')
          .fontWeight(300)
          .fontColor('#FFFFFF')
      }.layoutWeight(1)

      Text(":").fontSize('28fp').fontWeight(300).fontColor('#FFFFFF')
      Text(`${this.state.recordingTimeDisplay.split(':')[1]}`)
        .fontSize('28fp')
        .fontWeight(300)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Start)
        .align(Alignment.Start)
        .layoutWeight(1)
    }.width('100%').height(48)
  }
}