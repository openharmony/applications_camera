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

import lazy { UIExtensionContentSession } from '@kit.AbilityKit';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy {
  SupportedEffectTypes, VideoEffectsManager } from '../uiextensionability/VideoEffectsManager';
import lazy { VideoEffectsSlider } from '../uiextensionability/VideoEffectsSlider';
import { curves } from '@kit.ArkUI';

const TAG: string = 'VideoEffectsPage';
const PADDING_EDGE: number = 24;

enum LONG_TOUCH_COMPONENT {
  BEAUTY,
  APERTURE,
  NONE
}

@Entry()
@Component
struct VideoEffects {
  @State message: string = `UIExtension provider`;
  localStorage: LocalStorage | undefined = this.getUIContext().getSharedLocalStorage();
  private session: UIExtensionContentSession | undefined = this.localStorage?.get<UIExtensionContentSession>('session');
  private supportedEffectTypes: SupportedEffectTypes = VideoEffectsManager.getInstance().getSupportedEffectTypes();

  @State longTouchComponent: LONG_TOUCH_COMPONENT = LONG_TOUCH_COMPONENT.NONE;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear');
  }

  onPageShow() {
    HiLog.i(TAG, 'show');
  }

  build() {
    Column() {
      Flex({direction: FlexDirection.Column, justifyContent: FlexAlign.Center}) {
        // 美颜滑动条
        if (this.supportedEffectTypes.supportedBeautyRange) {
          VideoEffectsSlider({
            imageSrc: $r('app.media.beauty'),
            textSrc: $r('app.string.portrait_beauty'),
            sliderMax: 10,
            sliderValue: VideoEffectsManager.getInstance().getCurrentBeautyValue(),
            onValueChange: (value: number) => VideoEffectsManager.getInstance().setCurrentBeautyValue(value),
            onLongTouch: (isTouching: boolean) => this.setLongTouchComponent(isTouching ? LONG_TOUCH_COMPONENT.BEAUTY :
              LONG_TOUCH_COMPONENT.NONE)
          })
            .opacity(this.longTouchComponent === LONG_TOUCH_COMPONENT.APERTURE ? 0 : 1)
        }

        // 背景虚化滑动条
        if (this.supportedEffectTypes.supportedVirtualApertures) {
          VideoEffectsSlider({
            imageSrc: $r('app.media.virtual_background'),
            textSrc: $r('app.string.blurred_background'),
            sliderMax: VideoEffectsManager.getInstance().getVirtualAperturesLevels(),
            sliderValue: VideoEffectsManager.getInstance().getCurrentApertureValue(),
            onValueChange: (value: number) => VideoEffectsManager.getInstance().setCurrentApertureValue(value),
            onLongTouch: (isTouching: boolean) => this.setLongTouchComponent(isTouching ?
              LONG_TOUCH_COMPONENT.APERTURE :
              LONG_TOUCH_COMPONENT.NONE)
          })
            .margin({ top: 26 })
            .opacity(this.longTouchComponent === LONG_TOUCH_COMPONENT.BEAUTY ? 0 : 1)
          }
      }
    }
    .height('100%')
    .width('100%')
    .padding({
      left: PADDING_EDGE,
      right: PADDING_EDGE,
      top: PADDING_EDGE,
      bottom: PADDING_EDGE
    })
    .transition(TransitionEffect.OPACITY.animation({
      duration: 150,
      curve: curves.interpolatingSpring(0, 1, 228, 22)
    }))
  }

  /**
   * 设置当前长按的组件
   *
   * @param component
   */
  private setLongTouchComponent(component: LONG_TOUCH_COMPONENT): void {
    this.longTouchComponent = component;
  }
}
