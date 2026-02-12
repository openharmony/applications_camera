/*
 * Copyright (c) Huawei Device Co., Ltd. 2024-2025. All rights reserved.
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

/* instrument ignore file */
@Entry
@Component
struct CameraWidgetCard {
  readonly ACTION_TYPE: string = 'router';
  readonly ABILITY_NAME: string = 'com.ohos.camera.MainAbility';
  readonly MESSAGE: string = 'camera card';
  readonly COLLAPS_DISPLAY_MODE_SUB: number = 5;
  @State imgPath: string = 'common/bal_card_common.png';

  private getRealValues(value: number): number {
    let realValue = px2vp(340) * value / 226;
    return realValue;
  }

  build() {
    FormLink({
      action: this.ACTION_TYPE,
      abilityName: this.ABILITY_NAME,
      params: {
        message: this.MESSAGE,
        displayId: this.COLLAPS_DISPLAY_MODE_SUB
      }
    }) {
      Row() {
        Column() {
          Image(this.imgPath)
            .width(this.getRealValues(76))
            .height(this.getRealValues(76))
            .align(Alignment.Center)
            .backgroundColor(Color.Black)
            .interpolation(ImageInterpolation.High)
            .autoResize(true)
            .offset({ y: this.getRealValues(1.33) })

          Text($r('app.string.app_name'))
            .fontSize(this.getRealValues(23))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor(Color.White)
            .margin({ top: this.getRealValues(9.33), left: this.getRealValues(1.33), right: this.getRealValues(1.33) })
            .offset({ y: this.getRealValues(6) })
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .align(Alignment.Center)
        .justifyContent(FlexAlign.Start)
      }
      .height('100%')
      .align(Alignment.Center)
      .backgroundColor(Color.Black)
    }
  }
}