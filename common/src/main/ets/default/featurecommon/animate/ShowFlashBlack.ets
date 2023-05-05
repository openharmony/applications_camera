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
import type { OhCombinedState } from '../../redux/store'
import { getStore } from '../../redux/store'
import { Action } from '../../redux/actions/Action'

class StateStruct {
  xComponentWidth: number
  xComponentHeight: number
  updateShowFlashBlackFlag : Function
}

@Component
export struct ShowFlashBlack {
  private TAG: string = '[ShowFlashBlack]:'

  @State state: StateStruct = new StateStruct()
  @State opacityValue: number = 1

  aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().connect((state: OhCombinedState) => {
      return {
        xComponentWidth: state.PreviewReducer.xComponentWidth,
        xComponentHeight: state.PreviewReducer.xComponentHeight
      }
    }, (dispatch) => {
      return {
        updateShowFlashBlackFlag: (flag: boolean): void => {
          dispatch(Action.updateShowFlashBlackFlag(flag))
        }
      }
    })(this.state)
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