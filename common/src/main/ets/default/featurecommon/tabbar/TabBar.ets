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

import { Log } from '../../utils/Log'
import getStore from '../../redux/store'
import { Action } from '../../redux/actions/Action'

let tabBarState = (state) => {
  return {}
}

let tabBarDispatcher = (dispatch) => {
  return {
    showSettingView: () => {
      dispatch(Action.showSettingView(true))
    },
  }
}

@Component
export struct TabBar {
  private TAG: string = '[TabBar]'
  @State state: any = {}

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
//        TabBarSame()
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