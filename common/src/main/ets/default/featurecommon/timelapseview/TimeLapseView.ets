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

import { BusinessError } from "@ohos.base";
import { Log } from '../../utils/Log';
import { Dispatch, OhCombinedState } from '../../redux/store';
import { getStore } from '../../redux/store';
import { Action } from '../../redux/actions/Action';
import { SettingManager } from '../../setting/SettingManager';
import Timer from '../../setting/settingitem/Timer';
import { EventBus } from '../../worker/eventbus/EventBus';
import { EventBusManager } from '../../worker/eventbus/EventBusManager';
import { GlobalContext } from '../../utils/GlobalContext';

class StateStruct {
  mode: string = '';
}

class TimeLapseViewDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeTimeLapse(isShowtimeLapse: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse));
  }

  public capture(): void {
    this.mDispatch(Action.updateShowFlashBlackFlag(true))
    this.mDispatch(Action.capture());
  }

  public startRecording(): void {
    this.mDispatch(Action.startRecording());
    this.mDispatch(Action.updateVideoState('startTakeVideo'));
    this.mDispatch(Action.updateBigVideoTimerVisible(true));
    this.mDispatch(Action.updateScreenStatus(true));
  }
}

class KeepScreenStruct {
  isKeepScreenOn: boolean = false;
}

@Component
export struct TimeLapseView {
  private TAG: string = '[TimeLapseView]:'
  private timer: number = 0
  private settingManager = SettingManager.getInstance()
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  @State state: StateStruct = new StateStruct()
  @State timerLapse: number = 0
  private mAction: TimeLapseViewDispatcher = new TimeLapseViewDispatcher();

  private onKeepScreen(data: KeepScreenStruct): void {
    Log.info(`${this.TAG} onKeepScreen E`)
    if (data) {
      GlobalContext.get()
        .getCameraWinClass()
        .setKeepScreenOn(data.isKeepScreenOn)
        .then(() => {
          Log.info('Succeeded in setting the screen to be always on');
        })
        .catch((err: BusinessError) => {
          Log.error('Failed to set the screen to be always on. Cause: ' + JSON.stringify(err));
        });
    }
    Log.info(`${this.TAG} onKeepScreen X`)
  }

  aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        mode: state.modeReducer.mode,
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.appEventBus.on(Action.ACTION_KEEP_SCREEN_ON, (data: KeepScreenStruct) => this.onKeepScreen(data))
    switch (JSON.stringify(this.settingManager.getTimeLapse())) {
      case JSON.stringify(Timer.RESOURCE_OFF):
        this.timerLapse = -1
        break;
      case JSON.stringify(Timer.RESOURCE_TWO_SECONDS):
        this.timerLapse = 2
        break;
      case JSON.stringify(Timer.RESOURCE_FIVE_SECONDS):
        this.timerLapse = 5
        break;
      case JSON.stringify(Timer.RESOURCE_TEN_SECONDS):
        this.timerLapse = 10
        break;
      default:
        this.timerLapse = 10
        break;
    }
    Log.info(`${this.TAG} calculate timerLapse= ${this.timerLapse}`)
    if (this.timerLapse > 0) {
      clearInterval(this.timer)
      this.timer = setInterval(() => {
        this.timerLapse--
        if (this.timerLapse < 1) {
          clearInterval(this.timer)
          this.mAction.changeTimeLapse(false)
          Log.info(`${this.TAG} calculate mode= ${this.state.mode}`)
          if (!this.state.mode || this.state.mode === 'PHOTO' || this.state.mode === 'MULTI') {
            this.mAction.capture()
          } else if (this.state.mode === 'VIDEO') {
            this.mAction.startRecording()
          }
        }
      }, 1000)
    }
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    clearInterval(this.timer)
    Log.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
      Text(this.timerLapse.toString())
        .fontSize(120)
        .fontColor(Color.White)
        .fontWeight(300)
        .textAlign(TextAlign.Center)
    }.width('100%').height('100%')
  }
}