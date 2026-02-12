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

import lazy { OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../../redux/index';
import lazy { CommonConstants } from '../../../../statistics/CommonConstants';
import lazy { ComponentIdKeys } from '../../../../utils/ComponentIdKeys';
import lazy { HiLog } from '../../../../utils/HiLog';
import ResGetter from '../../../../utils/ResGetter';
import lazy { ZIndex } from '../../../../utils/ZIndex';
import lazy { BACK_BUTTON_LEFT_MARGIN, BACK_BUTTON_SIDE_LENGTH, TREASURE_BOX_TAG, } from '../TreasureBox';
import Configuration from '@system.configuration';
import lazy { AccessibilityUtils } from '../../../../utils/AccessibilityUtils';
import lazy { FunctionId } from '../../../../function/core/functionproperty/FunctionId';
import lazy { SystemLanguageUtil } from '../../../../utils/SystemLanguageUtil';
import lazy { FeatureManager } from '../../../../function/core/FeatureManager';
import lazy { BaseFunction } from '../../../../function/core/BaseFunction';
import lazy { RenderLocation } from '../../../../function/core/functionproperty/RenderLocation';
import lazy { UiElement } from '../../../../function/core/UiElement';

/* instrument ignore file */
const TAG: string = 'BackButton';

const backButtonReleaseAnimate = TransitionEffect.OPACITY.animation({ duration: 100, delay: 50 });
const backButtonEntryAnimate = TransitionEffect.OPACITY.animation({ duration: 200, delay: 100 });
const shadowEntryAnimate = TransitionEffect.OPACITY.animation({ duration: 200, delay: 200 });

const BACK_BUTTON_ICON_LENGTH: number = 14;
const BACK_BUTTON_IMAGE_LENGTH: number = 24;
const BACK_BUTTON_TOP_MARGIN = 8;
const HEIGHT_FULL = '100%';

@Component
export struct BackButton {
  private subscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State uiEnable: boolean = true;
  @State showShadow: boolean = true;
  @State topMargin: number = 0;
  private goBack: () => void = () => {
  };
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  functionId: FunctionId = FunctionId.NONE;
  @State isHideAnimation: boolean = false;
  @State private abilityTitle: Resource | string = '';

  aboutToAppear() {
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
    }, null);
  }

  aboutToDisappear() {
    this.subscriber.destroy();
  }

  build() {
    Stack() {
      Row() {
        this.BackButtonBuilder();
      }
      .zIndex(ZIndex.TOP)
      .key(ComponentIdKeys.TREASURE_BOX_SECOND_LIST_BACK_BUTTON)
      .width(BACK_BUTTON_SIDE_LENGTH)
      .height(BACK_BUTTON_SIDE_LENGTH)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .margin({
        left: SystemLanguageUtil.isRTL() ? 0 : BACK_BUTTON_LEFT_MARGIN,
        right: SystemLanguageUtil.isRTL() ? BACK_BUTTON_LEFT_MARGIN : 0,
        top: this.topMargin + BACK_BUTTON_TOP_MARGIN
      })
      .transition(this.isHideAnimation ? {} :
      TransitionEffect.asymmetric(backButtonEntryAnimate, TransitionEffect.IDENTITY))
      .onAppear((): void => {
        HiLog.i(TAG, 'show level-2 list.');
      })
      .onDisAppear((): void => {
        HiLog.i(TAG, 'change from level-2 list to main list.');
      })
    }
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .transition(this.isHideAnimation ? {} :
    TransitionEffect.asymmetric(TransitionEffect.IDENTITY, backButtonReleaseAnimate))
    .height(HEIGHT_FULL)
    .alignContent(Alignment.TopStart)
    .enabled(this.uiEnable)
    .onClick((): void => {
      if (!this.uiEnable) {
        return;
      }
      this.goBack();
    })
  }

  private getKey(functionId: FunctionId) {
    let keyNumber: number = 0;
    switch (functionId) {
      case FunctionId.ASPECT_RATIO:
      case FunctionId.VIDEO_RESOLUTION:
      case FunctionId.FRAME_RATE:
        keyNumber = 1;
        break;
      case FunctionId.FLASH:
        keyNumber = 2;
        break;
      default:
        break;
    }
    let key = ComponentIdKeys.getInstance().getKey(TREASURE_BOX_TAG, this.functionId, keyNumber);
    HiLog.i(TAG, 'getKey key = ' + key);
    return key;
  }

  @Builder
  private BackButtonBuilder() {
    Row() {
      Image($r('app.media.ic_public_back_black_white'))
        .width(BACK_BUTTON_ICON_LENGTH)
        .height(BACK_BUTTON_ICON_LENGTH)
        .draggable(false)
        .fillColor(Color.White)
    }
    .width(BACK_BUTTON_IMAGE_LENGTH)
    .height(BACK_BUTTON_IMAGE_LENGTH)
    .borderRadius(BACK_BUTTON_IMAGE_LENGTH >> 1)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.component_normal_dark'))
    .key(ComponentIdKeys.TREASURE_BOX_SECOND_LIST_BACK_BTN)
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
    .accessibilityText(ResGetter.getStringSafe($r('sys.string.icon_back')))
    .accessibilityDescription(ResGetter.getStringSafe($r('app.string.accessibility_clickable')))
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .accessibilityNextFocusId(this.getKey(this.functionId))
    .enabled(this.enableScreenReader)
    .rotate({ angle: SystemLanguageUtil.isRTL() ? 180 : 0 })
    .onClick((event): void => {
    // 仅在无障碍服务开启时生效
      if (event && this.enableScreenReader && this.uiEnable) {
        this.goBack();
        setTimeout(() => {
          AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.getInstance()
            .getKey(TREASURE_BOX_TAG, this.functionId));
          AccessibilityUtils.sendAnnounceAccessibilityEvent(this.getABText());
        }, 150)
      }
    })
  }

  private getABText(): string {
    HiLog.i(TAG, `getABText, functionId: ${this.functionId}`);
    const functionImpl: BaseFunction = FeatureManager.getInstance().getFunction(this.functionId);
    let uiElements: Map<Object, UiElement> = functionImpl.getUiElements(RenderLocation.TREASURE_BOX);
    const  defaultElement: UiElement  = uiElements.get(UiElement.DEFAULT) as UiElement;
    this.abilityTitle = defaultElement.accessibilityTitle || '';
    return `${ResGetter.getStringSafe(this.abilityTitle)} ${ResGetter.getStringSafe($r('app.string.accessibility_button'))}`;
  }
}