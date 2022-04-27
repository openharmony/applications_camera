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
    xComponentWidth: state.PreviewReducer.xComponentWidth,
    xComponentHeight: state.PreviewReducer.xComponentHeight,
    opacityValue: state.UiReducer.opacityValue
  }
}

let localDispatcher = (dispatch) => {
  return {
    updateOpacityValue: (opacityValue) => {
      dispatch(Action.UpdateOpacityValue(opacityValue))
    },
    updateShowFlashBlackFlag: (flag: boolean) => {
      dispatch(Action.UpdateShowFlashBlackFlag(flag))
    }
  }
}

@Component
export struct ShowFlashBlack {
  private TAG: string = '[ShowFlashBlack]:'
  private mConnect: any

  @Link state: any

  private aboutToAppear() {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  private aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Flex({ direction: FlexDirection.Row }) {
      Row() {
        Shape() {
          Rect()
            .width(Number(this.state.xComponentWidth.split('px')[0]))
            .height(Number(this.state.xComponentHeight.split('px')[0]))
        }
        .fill(Color.Black)
        .opacity(this.state.opacityValue)
        .onAppear(() => {
          animateTo({
            duration: 50,
            delay: 0,
            onFinish: () => {}
          }, () => {})
          animateTo({
            duration: 300,
            curve: Curve.Sharp,
            delay: 50,
            onFinish: () => {
              this.state.updateShowFlashBlackFlag(false)
              this.state.updateOpacityValue(1)
            }
          }, () => {
            this.state.updateOpacityValue(0)
          })
        })
      }
    }
    .width(Number(this.state.xComponentWidth.split('px')[0]))
    .height(Number(this.state.xComponentHeight.split('px')[0]))
  }
}