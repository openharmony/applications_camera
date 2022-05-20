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

let tabBarMState = (state) => {
  return {
    widthTabBar: state.PreviewReducer.widthTabBar
  }
}

let tabBarMDispatcher = (dispatch) => {
  return {
    updateShowTabBarWidth: (widthTabBar: String) => {
      dispatch(Action.UpdateShowTabBarWidth(widthTabBar))
    }
  }
}

@Component
export struct TabBarSame {
  private TAG: string = '[TabBarSame]:'
  @State state: any ={}
  private mConnect: any
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  private aboutToAppear() {
    CLog.info(`${this.TAG} aboutToAppear invoke E`)
    this.mConnect = getStore().connect(tabBarMState, tabBarMDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_ON_MODE_CHANGED,this.updateTabBarWidth.bind(this))
    CLog.info(`${this.TAG} aboutToAppear invoke X`)
  }

  private updateTabBarWidth(data) {
    CLog.info(`${this.TAG} updateTabBarWidth invoke E ${data.mode}`)
    switch (data.mode) {
      case CaptureMode.PHOTO:
        this.state.updateShowTabBarWidth('40%')
        break;
      case CaptureMode.VIDEO:
        this.state.updateShowTabBarWidth('10%')
        break;
      default:
        this.state.updateShowTabBarWidth('30%')
        break;
    }
    CLog.info(`${this.TAG} updateTabBarWidth invoke X`)
  }

  private aboutToDisappear() {
    CLog.info(`${this.TAG} aboutToDisappear invoke E`)
    this.appEventBus.off(Action.ACTION_ON_MODE_CHANGED,this.updateTabBarWidth.bind(this))
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear invoke X`)
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Column() {
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Image($r("app.media.delete"))
            .width(24)
            .height(24)
        }.width('100%').height('100%')
      }
    }
  }
}