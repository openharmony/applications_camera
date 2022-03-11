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
export struct BigText {
  @Link previewImage: string
  @Link isShowBigText: boolean
  @State tempScale: number = 1
  @State opacityValue: number = 0;
  @State tempCurve: Curve = Curve.Sharp;

  build() {
    Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text(this.previewImage)
        .fontSize(40)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width('100%')
        .opacity(this.opacityValue)
        .onAppear(() => {
          animateTo({ duration: 150,
            curve: Curve.Sharp,
            delay: 0,
            onFinish: () => {
              animateTo({ duration: 150,
                curve: Curve.Sharp,
                delay: 100,
                onFinish: () => {
                  this.isShowBigText = false
                }
              }, () => {
                this.opacityValue = 0
              })
            }
          }, () => {
            this.opacityValue = 1
          })
        })
    }
    .width('100%')
      .height(96)
  }
}
