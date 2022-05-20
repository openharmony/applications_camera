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

let localState = (state) => {
  return {
    mode: state.ModeReducer.mode,
    bigTextPositionY: state.UiReducer.bigTextPositionY,
    bigTextOpacity: state.UiReducer.bigTextOpacity,
  }
}

let localDispatcher = (dispatch) => {
  return {
    updateShowBigTextFlag: (flag: boolean) => {
      dispatch(Action.UpdateShowBigTextFlag(flag))
    },
    updateBigTextOpacity: (opacity: number) => {
      dispatch(Action.UpdateBigTextOpacity(opacity))
    }
  }
}

@Component
export struct BigText {
  private TAG: string = '[BigText]:'
  private mConnect: any

  @Link state: any

  public aboutToAppear() {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  public aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text(this.state.mode)
        .fontSize(40)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Lighter)
        .textAlign(TextAlign.Center)
        .width('100%')
        .opacity(this.state.bigTextOpacity)
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
                }
              }, () => {
                this.state.updateBigTextOpacity(0)
              })
            }
          }, () => {
            this.state.updateBigTextOpacity(1)
          })
        })
    }
    .width('100%')
    .height('96vp')
    //tablet 需要.position， phone不需要
    .position(this.state.bigTextPositionY)
  }
}
