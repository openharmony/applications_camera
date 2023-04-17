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

import { Log } from '../../utils/Log'
import { getStore } from '../../redux/store'
import { Action } from '../../redux/actions/Action'

let localState = (state) => {
  return {
    mode: state.ModeReducer.mode,
  }
}

let localDispatcher = (dispatch) => {
  return {
    updateShowBigTextFlag: (flag: boolean) => {
      dispatch(Action.updateShowBigTextFlag(flag))
    },
    updateUiState: (state: boolean) => {
      dispatch(Action.uiState(state))
    }
//    updateBigTextOpacity: (opacity: number) => {
//      dispatch(Action.updateBigTextOpacity(opacity))
//    }
  }
}

class StateStruct {
  mode
  updateShowBigTextFlag : Function
  updateUiState : Function
}

@Component
export struct BigText {
  private TAG: string = '[BigText]:'
  private mConnect: any
  private modeResource = {
    'MULTI': $r('app.string.multi_mode'),
    'PHOTO': $r('app.string.photo_mode'),
    'VIDEO': $r('app.string.video_mode')
  }

  @State state: StateStruct = new StateStruct()
  @State bigTextOpacity: number = 0

  public aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  public aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    this.mConnect?.destroy()
    Log.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text(this.modeResource[this.state.mode])
        .fontSize(60)
        .fontColor(Color.White)
        .fontWeight(300)
        .textAlign(TextAlign.Center)
        .width('100%')
        .opacity(this.bigTextOpacity)
        .onAppear(() => {
          animateTo({ duration: 150,
            curve: Curve.Sharp,
            delay: 0,
            onFinish: () => {
              animateTo({ duration: 150,
                curve: Curve.Sharp,
                delay: 1000,
                onFinish: () => {
                  this.state.updateShowBigTextFlag(false)
                  this.state.updateUiState(true)
                }
              }, () => {
                this.bigTextOpacity = 0
              })
            }
          }, () => {
            this.bigTextOpacity = 1
          })
        })
    }
    .width('100%')
    .height('96vp')
  }
}
