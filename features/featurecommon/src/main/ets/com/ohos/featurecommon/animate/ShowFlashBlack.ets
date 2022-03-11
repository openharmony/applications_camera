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

import router from '@system.router'

@Component
export struct ShowFlashBlack {
  @State opacityValue: number = 1
  @Link XcomponentWidth: string;
  @Link XcomponentHeight: string;
  @Link isShowFlashBlack: boolean;

  build() {
    Flex({ direction: FlexDirection.Row }) {
      Row() {
        Shape() {
          Rect()
            .width(Number(this.XcomponentWidth.split('px')[0]))
            .height(Number(this.XcomponentHeight.split('px')[0]))
        }
        .fill(Color.Black)
        .opacity(this.opacityValue)
        .onAppear(() => {
          animateTo({
            duration: 50,
            delay: 0,
            onFinish: () => {
              console.info("isShowFlashBlack111=" + this.isShowFlashBlack)
              console.info("XcomponentWidth = " + Number(
                this.XcomponentWidth.split('px')[0]))
              console.info("XcomponentHeight = " + Number(
                this.XcomponentHeight.split('px')[0]))

            }
          }, () => {
            console.log("onAppear first")
          })
          animateTo({
            duration: 300,
            curve: Curve.Sharp,
            delay: 50,
            onFinish: () => {
              this.isShowFlashBlack = false;
              this.opacityValue = 1;
            }
          }, () => {
            this.opacityValue = 0;
          })
        })
      }
    }.height(Number(this.XcomponentHeight.split('px')[0]))
    .width(Number(this.XcomponentWidth.split('px')[0]))
  }
}