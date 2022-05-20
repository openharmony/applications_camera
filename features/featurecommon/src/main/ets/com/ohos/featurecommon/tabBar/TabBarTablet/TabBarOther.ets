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

import { Action } from '../../../../../../../../../../common/src/main/ets/default/redux/actions/Action'
import { CaptureMode } from '../../../../../../../../../../common/src/main/ets/default/setting/CaptureMode'
import { CLog } from '../../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import { EventBus } from '../../../../../../../../../../common/src/main/ets/default/Utils/EventBus'
import EventBusManager from '../../../../../../../../../../common/src/main/ets/default/Utils/EventBusManager'
import getStore from '../../../../../../../../../../common/src/main/ets/default/redux/store'

let tabBarLandState = (state) => {
  return {
    opacityValueForTabBar: state.SettingReducer.opacityValueForTabBar
  }
}

let tabBarLandDispatcher = (dispatch) => {
  return {
    updateOpacityForTabBar: (opacityValue) => {
      dispatch(Action.UpdateOpacityForTabBar(opacityValue))
    }
  }
}

@Component
export struct TabBarOther {
  private TAG: string = '[TabBarOther]:'
  @State state: any ={}
  private mConnect: any
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  private aboutToAppear(): void {
    CLog.info(`${this.TAG} aboutToAppear invoke E`)
    this.mConnect = getStore().connect(tabBarLandState, tabBarLandDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_ON_MODE_CHANGED, this.updateOpacityTabBar.bind(this))
    CLog.info(`${this.TAG} aboutToAppear invoke X`)
  }

  private aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear invoke E`)
    this.appEventBus.off(Action.ACTION_ON_MODE_CHANGED, this.updateOpacityTabBar.bind(this))
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear invoke X`)
  }

  private updateOpacityTabBar(data) {
    CLog.info(`${this.TAG} updateOpacityTabBar invoke E`)
    if (data.mode === CaptureMode.VIDEO) {
      this.state.updateOpacityForTabBar(1)
    } else {
      this.state.updateOpacityForTabBar(0)
    }
    CLog.info(`${this.TAG} updateOpacityTabBar invoke X`)
  }

  build() {
      Column() {
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Image($r("app.media.sd_card")).width(24).height(24)
        }
      }
  }
}