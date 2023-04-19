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

import { Action } from '../../../redux/actions/Action'
import { CaptureMode } from '../../../setting/settingitem/CaptureMode'
import { Log } from '../../../utils/Log'
import { EventBus } from '../../../worker/eventbus/EventBus'
import { EventBusManager } from '../../../worker/eventbus/EventBusManager'
import { getStore } from '../../../redux/store'

let tabBarLandState = (state) => {
  return {
    opacityValueForTabBar: state.SettingReducer.opacityValueForTabBar
  }
}

let tabBarLandDispatcher = (dispatch) => {
  return {
    updateOpacityForTabBar: (opacityValue) => {
      dispatch(Action.updateOpacityForTabBar(opacityValue))
    }
  }
}

class StateStruct {
  opacityValueForTabBar
  updateOpacityForTabBar: Function
}

@Component
export struct TabBarOther {
  private TAG: string = '[TabBarOther]:'
  @State state: StateStruct = new StateStruct()
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  private aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear invoke E`)
    getStore().connect(tabBarLandState, tabBarLandDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_ON_MODE_CHANGED, this.updateOpacityTabBar.bind(this))
    Log.info(`${this.TAG} aboutToAppear invoke X`)
  }

  private aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear invoke E`)
    this.appEventBus.off(Action.ACTION_ON_MODE_CHANGED, this.updateOpacityTabBar.bind(this))
    Log.info(`${this.TAG} aboutToDisappear invoke X`)
  }

  private updateOpacityTabBar(data) {
    Log.info(`${this.TAG} updateOpacityTabBar invoke E`)
    if (data.mode === CaptureMode.VIDEO) {
      this.state.updateOpacityForTabBar(1)
    } else {
      this.state.updateOpacityForTabBar(0)
    }
    Log.info(`${this.TAG} updateOpacityTabBar invoke X`)
  }

  build() {
      Column() {
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Image($r("app.media.sd_card")).width(24).height(24)
        }
      }
  }
}