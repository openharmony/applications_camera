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

import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import getStore from '../../../../../../../../../common/src/main/ets/default/redux/store'
import {Action} from '../../../../../../../../../common/src/main/ets/default/redux/actions/Action'
import {SettingsUtil} from '../../../../../../../../../common/src/main/ets/default/Utils/SettingsUtil'

let localState = (state) => {
  return {
    mode: state.ModeReducer.mode,
    timerLapse: 0
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
  private mConnect: any
  private timer: number = 0
  private settingsUtil = SettingsUtil.getInstance()

  @State state: any = {}

  public aboutToAppear() {
    CLog.debug(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    switch(JSON.stringify(this.settingsUtil.getTimeLapse())){
      case JSON.stringify($r('app.string.off')):
        this.state.timerLapse = -1
        break;
      case JSON.stringify($r('app.string.timer_2_seconds')):
        this.state.timerLapse = 2
        break;
      case JSON.stringify($r('app.string.timer_5_seconds')):
        this.state.timerLapse = 5
        break;
      case JSON.stringify($r('app.string.timer_10_seconds')):
        this.state.timerLapse = 10
        break;
      default:
        this.state.timerLapse = 10
        break;
    }
    CLog.info(`${this.TAG} calculate timerLapse= ${this.state.timerLapse}`)
    if (this.state.timerLapse > 0) {
      clearInterval(this.timer)
      this.timer = setInterval(() => {
        this.state.timerLapse --
        if(this.state.timerLapse < 1){
          clearInterval(this.timer)
          this.state.changeTimeLapse(false)
          CLog.info(`${this.TAG} calculate mode= ${this.state.mode}`)
          if (!this.state.mode || this.state.mode === 'PHOTO') {
            this.state.capture()
          } else if (this.state.mode === 'VIDEO') {
            this.state.startRecording()
          }
        }
      }, 1000)
    }
    CLog.debug(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    clearInterval(this.timer)
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Flex({direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End}){
      Text(this.state.timerLapse.toString())
        .fontSize(120)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Lighter)
        .textAlign(TextAlign.Center)
    }.width('100%').height('100%')
  }
}