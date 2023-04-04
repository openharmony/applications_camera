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
import EventLog from '../../utils/EventLog'

let tabBarState = (state) => {
  return {
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall
  }
}

let tabBarDispatcher = (dispatch) => {
  return {
    showSettingView: () => {
      EventLog.write(EventLog.CLICK_SETTINGS)
      dispatch(Action.showSettingView(true))
    },
  }
}

class StateStruct {
  isThirdPartyCall
  showSettingView: Function
}

@Component
export struct TabBar {
  private TAG: string = '[TabBar]'
  @State state: StateStruct = new StateStruct()
  private onBackClicked:Function

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear invoke E`)
    getStore().connect(tabBarState, tabBarDispatcher)(this.state)
    Log.info(`${this.TAG} aboutToAppear invoke X`)
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Column() {
//        TabBarOther()
      }.width('40%').height('100%')
      Column() {
            if (this.state.isThirdPartyCall) {
              Row() {
                Image($r("app.media.ic_public_back")).width(24).height(24)
                  .onClick(() => {
                    this.state.showSettingView()
                    this.onBackClicked()
                  })
              }.width(48).height(48)
              .padding({left: 12})
              .margin({ bottom: 12 })
            }
      }.width('40%').height('100%')
      Column() {
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Image($r('app.media.setting')).width(24).height(24)
        }.width('100%').height('100%')
      }.width('20%').height('100%').onClick(() => {
        this.state.showSettingView()
      })
    }.width('100%').height('100%')
  }
}