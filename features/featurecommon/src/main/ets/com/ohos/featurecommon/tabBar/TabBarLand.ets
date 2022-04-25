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

@Component
export struct TabBarLand {
  @Link previewImage: string
  @Link cameraPosition: string

  private aboutToAppear(): void {

  }

  private aboutToDisappear(): void {

  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
      Flex({ direction: FlexDirection.ColumnReverse, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Image($r("app.media.setting")).width(24).height(24)
            .onClick(() => {
              router.replace({
                params: {
                  position: this.cameraPosition,
                  mode: this.previewImage
                },
                uri: "pages/SettingView" })
            })
        }.width('100%').height('20%')
      }.width('100%').height(360)
      .margin({bottom: 44})
    }
    .width(48)
      .height('100%')
      .position({ x: 0, y: 0 })
  }
}