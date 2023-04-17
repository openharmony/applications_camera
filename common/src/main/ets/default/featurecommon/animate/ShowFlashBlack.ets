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
    xComponentWidth: state.PreviewReducer.xComponentWidth,
    xComponentHeight: state.PreviewReducer.xComponentHeight,
  }
}

let localDispatcher = (dispatch) => {
  return {
//    updateOpacityValue: (opacityValue) => {
//      dispatch(Action.updateOpacityValue(opacityValue))
//    },
    updateShowFlashBlackFlag: (flag: boolean) => {
      dispatch(Action.updateShowFlashBlackFlag(flag))
    }
  }
}

class StateStruct {
  xComponentWidth
  xComponentHeight
  updateShowFlashBlackFlag : Function
}

@Component
export struct ShowFlashBlack {
  private TAG: string = '[ShowFlashBlack]:'

  @State state: StateStruct = new StateStruct()
  @State opacityValue: number = 1

  aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().connect(localState, localDispatcher)(this.state)
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  build() {
    Flex({ direction: FlexDirection.Row }) {
      Row() {
        Shape() {
          Rect()
            .width(this.state.xComponentWidth)
            .height(this.state.xComponentHeight)
        }
        .fill(Color.Black)
        .opacity(this.opacityValue)
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
              this.opacityValue = 1
            }
          }, () => {
            this.opacityValue = 0
          })
        })
      }
    }
    .width(this.state.xComponentWidth)
    .height(this.state.xComponentHeight)
  }
}