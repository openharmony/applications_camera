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

import { Log } from '../../utils/Log'
import getStore from '../../redux/store'
import { Action } from '../../redux/actions/Action'
import { SettingManager } from '../../setting/SettingManager'
import Timer from '../../setting/settingitem/Timer'

let localState = (state) => {
  return {
    mode: state.ModeReducer.mode,
  }
}

let localDispatcher = (dispatch) => {
  return {
    changeTimeLapse: (isShowtimeLapse: boolean) => {
      dispatch(Action.changeTimeLapse(isShowtimeLapse))
    },
    capture: () => {
      dispatch(Action.UpdateShowFlashBlackFlag(true))
      dispatch(Action.capture())
    },
    startRecording: () => {
      dispatch(Action.startRecording())
      dispatch(Action.UpdateVideoState('startTakeVideo'))
      dispatch(Action.UpdateBigVideoTimerVisible(true))
    }
  }
}

@Component
export struct TimeLapseView {
  private TAG: string = '[TimeLapseView]:'
  private timer: number = 0
  private settingManager = SettingManager.getInstance()

  @State state: any = {}
  @State timerLapse: number = 0

  public aboutToAppear() {
    Log.debug(`${this.TAG} aboutToAppear E`)
    getStore().connect(localState, localDispatcher)(this.state)
    switch(JSON.stringify(this.settingManager.getTimeLapse())){
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
        this.timerLapse --
        if(this.timerLapse < 1){
          clearInterval(this.timer)
          this.state.changeTimeLapse(false)
          Log.info(`${this.TAG} calculate mode= ${this.state.mode}`)
          if (!this.state.mode || this.state.mode === 'PHOTO' || this.state.mode === 'MULTI') {
            this.state.capture()
          } else if (this.state.mode === 'VIDEO') {
            this.state.startRecording()
          }
        }
      }, 1000)
    }
    Log.debug(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    clearInterval(this.timer)
    Log.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Flex({direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End}){
      Text(this.timerLapse.toString())
        .fontSize(120)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Lighter)
        .textAlign(TextAlign.Center)
    }.width('100%').height('100%')
  }
}