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

import { Action } from '../../redux/actions/Action'
import { Log } from '../../utils/Log'
import { EventBus } from '../../worker/eventbus/EventBus'
import { EventBusManager } from '../../worker/eventbus/EventBusManager'
import { getStore } from '../../redux/store'
import EventLog from '../../utils/EventLog'

let tabBarLandState = (state) => {
  return {
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall
  }
}

let tabBarLandDispatcher = (dispatch) => {
  return {
    showSettingView: () => {
      dispatch(Action.showSettingView(true))
    },
  }
}

class StateStruct {
  isThirdPartyCall
  showSettingView: Function
}

type ScreenSizeType = {
  width: number
  height: number
}

@Component
export struct TabBarLand {
  private TAG: string = '[TabBarLand]'
  @State state: StateStruct = new StateStruct()
  @State opacityTabBar: number = 0
  @State isShowTabBarOther: boolean= false
  @Link screenSize: ScreenSizeType
  private onBackClicked:Function
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear invoke E`)
    getStore().connect(tabBarLandState, tabBarLandDispatcher)(this.state)
    Log.info(`${this.TAG} aboutToAppear invoke X`)
  }

  build() {
    Flex({ direction: FlexDirection.ColumnReverse, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
    if (this.state.isThirdPartyCall) {
      Row() {
        Image($r("app.media.ic_public_back")).width(24).height(24)
          .onClick(() => {
            this.onBackClicked()
          })
      }.width(48).height(48)
      .padding({left: 12})
      .margin({ bottom: 12 })
    }

    Row()  {
      Image($r("app.media.setting")).width(24).height(24)
        .onClick(() => {
          EventLog.write(EventLog.CLICK_SETTINGS)
          this.state.showSettingView()
        })
    }.width(48).height(48)
    .padding({ left: 12 })
    .position(this.state.isThirdPartyCall ? {x:0,y:12} : {x:0,y: this.screenSize.height - 144})
      //        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      //          TabBarOther()
      //        }.width('100%').height('20%')
      //        .opacity(this.state.opacityValueForTabBar)
      //        .animation({
      //          duration: 2000,
      //          curve: Curve.Sharp,
      //          delay: 0,
      //          iterations: 1,
      //          playMode: PlayMode.Normal
      //        })
      //
      //        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      //          TabBarSame()
      //        }
      //        .position({ y: this.state.widthTabBar })
      //        .width('100%')
      //        .height('20%')
      //        .animation({
      //          duration: 2000,
      //          curve: Curve.Sharp,
      //          delay: 0,
      //          iterations: 1,
      //          playMode: PlayMode.Normal
      //        })
    }.width(48).height('100%')
  }
}