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

import router from "@system.router"

import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import getStore from '../../../../../../../../../common/src/main/ets/default/redux/store'

let tabBarLandState = (state) => {
  return {}
}

let tabBarLandDispatcher = (dispatcher) => {
  return {}
}

@Component
export struct TabBarLand {
  private TAG: string = '[TabBarLand]'
  //  @Link previewImage: string
  //  @Link cameraPosition: string
  @State state: any = {}
  private mConnect: any

  private aboutToAppear(): void {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(tabBarLandState, tabBarLandDispatcher)(this.state)
    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  private aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
      Flex({ direction: FlexDirection.ColumnReverse, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Image($r("app.media.setting")).width(24).height(24)
            .onClick(() => {
              router.replace({
//                params: {
//                  position: this.cameraPosition,
//                  mode: this.previewImage
//                },
                uri: "pages/SettingView" })
            })
        }.width('100%').height('20%')
      }.width('100%').height(360).margin({bottom: 44})
    }.width(48).height('100%').position({ x: 0, y: 0 })
  }
}