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
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { uiEffect } from '@kit.ArkGraphics2D';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import { VideoEffectsManager } from './VideoEffectsManager';

const TAG: string = 'VideoEffectsSlider';

const LONG_TOUCH_INTERVAL: number = 300;

const SLIDER_CHOSEN_BLENDER = uiEffect.createBrightnessBlender({
  cubicRate: 0,
  quadraticRate: 0,
  linearRate: 0.6,
  degree: 0.4125,
  saturation: 1.5,
  positiveCoefficient: [1.2, 1.8, 1],
  negativeCoefficient: [2, 2.2, 0.5],
  fraction: 0
});

@Component
export struct VideoEffectsSlider {
  private imageSrc: Resource | undefined = undefined;
  private textSrc: Resource | string = '';
  private onValueChange: Function = (value: number) => {
  };

  @State sliderValue: number = 0;
  @State sliderMin: number = 0;
  @State sliderMax: number = 10;
  @State bottomVisualEffect: uiEffect.VisualEffect = uiEffect.createEffect();
  @State upperVisualEffect: uiEffect.VisualEffect = uiEffect.createEffect();

  private touchStartTime: number = 0;
  private touchCurTime: number = 0;
  @State isLongTouch: boolean = false;
  private onLongTouch: Function = (isTouching: boolean) => {
  };

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear');
    HiLog.i(TAG, `slider value = ${this.sliderValue}`);
    let bottomBlender = uiEffect.createBrightnessBlender({
      cubicRate: 0,
      quadraticRate: 0,
      linearRate: 1,
      degree: -0.0784,
      saturation: 1.2,
      positiveCoefficient: [1.3, 0.5, 0.5],
      negativeCoefficient: [1, 1, 1],
      fraction: 0
    });
    this.bottomVisualEffect.backgroundColorBlender(bottomBlender);

    let upperBlender = uiEffect.createBrightnessBlender({
      cubicRate: 0,
      quadraticRate: 0,
      linearRate: 0.2632,
      degree: 0.7529,
      saturation: 2.3,
      positiveCoefficient: [0.8, 0.7, 1],
      negativeCoefficient: [1, 1.2, 1],
      fraction: 0
    });
    this.upperVisualEffect.backgroundColorBlender(upperBlender);
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear');
  }

  build() {
    Column() {
      Row() {
        Image(this.imageSrc)
          .width(24)
          .height(24)

        Text(this.textSrc)
          .fontSize(14)
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })
          .maxLines(1)
          .fontColor($r('app.color.text_color'))
          .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL2)
      }
      .width('100%')
      .opacity(this.isLongTouch ? 0 : 1)

      Stack() {
        Row()
          .width(`${getPercent(this.sliderValue, this.sliderMax)}`)
          .height('100%')
          .borderRadius(12)
          .visualEffect(this.bottomVisualEffect)

        Column()
          .backgroundColor('#FFFFFF')
          .width(`${getPercent(this.sliderValue, this.sliderMax)}`)
          .height('100%')
          .borderRadius(12)
          .visualEffect(this.upperVisualEffect)

        Slider({
          style: SliderStyle.NONE,
          value: this.sliderValue,
          min: this.sliderMin,
          max: this.sliderMax
        })
          .selectedBorderRadius(12)
          .backgroundColor(Color.Transparent)
          .trackColor(Color.Transparent)
          .selectedColor(Color.Transparent)
          .blockColor(Color.Transparent)
          .trackThickness(20)
          .height(20)
          .onChange((value: number, mode: SliderChangeMode) => {
            animateToImmediately({
              delay: 0,
              duration: 100,
              curve: Curve.Linear
            }, () => {
              this.sliderValue = value;
            })
            this.onValueChange(value);
          })
          .enabled(true)
          .onTouch((event) => {
            switch (event.type) {
              case TouchType.Down:
                this.touchStartTime = Date.now();
                break;
              case TouchType.Move:
                this.touchCurTime = Date.now();
                if (this.touchCurTime - this.touchStartTime > LONG_TOUCH_INTERVAL) {
                  animateTo({
                    delay: 0,
                    duration: 250,
                    curve: Curve.Friction
                  }, () => {
                    this.isLongTouch = true;
                    this.onLongTouch(true);
                    this.touchStartTime = this.touchCurTime;
                    HiLog.i(TAG, 'long touch start.');
                    VideoEffectsManager.getInstance().sendData({ 'method': 'isSliderChosen', 'param': true });
                  });
                }
                break;
              case TouchType.Up:
              case TouchType.Cancel:
                if (this.isLongTouch) {
                  HiLog.i(TAG, 'long touch end.');
                  VideoEffectsManager.getInstance().sendData({ 'method': 'isSliderChosen', 'param': false });
                  this.bottomVisualEffect.backgroundColorBlender(SLIDER_CHOSEN_BLENDER);
                }
                animateTo({
                  delay: 0,
                  duration: 250,
                  curve: Curve.Friction
                }, () => {
                  this.touchStartTime = 0;
                  this.touchCurTime = 0;
                  this.isLongTouch = false;
                  this.onLongTouch(false);
                });
                break;
              default:
                break;
            }
          })
          .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
          .accessibilityText(`${ResGetter.getStringSafe(this.textSrc)},${getPercent(this.sliderValue, this.sliderMax, 0)}`)
      }
      .clip(true)
      .alignContent(Alignment.Start)
      .width('100%')
      .height(20)
      .margin({ top: 18 })
      .borderRadius(12)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .backgroundEffect(this.isLongTouch ? {
        policy: 1,
        radius: 60,
        blurOptions: { grayscale: [38, 38] }
      } : undefined)
      .shadow(this.isLongTouch ? {
        radius: 40,
        color: '#26000000',
        offsetY: 0,
        offsetX: 0
      } : undefined)
    }
  }
}

function getPercent(a: number, b: number, decimalPlaces: number = 2): string | number {
  if (typeof a !== "number" || typeof b !== "number") {
    HiLog.e(TAG, 'input is not number.');
    return 0;
  }
  if (b === 0) {
    HiLog.e(TAG, 'divisor is not zero.');
    return 0;
  }
  const result = (a / b) * 100;
  return `${result.toFixed(decimalPlaces)}%`;
}