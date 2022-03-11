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

@Component
export struct ZoomTextLand {
  @Link zoomValue: number

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text(this.zoomValue.toFixed(1))
        .fontSize('60fp')
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
      Text('X')
        .fontSize('60fp')
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .fontWeight(400)
    }
    .width('100%')
    .height('100%')
  }
}