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

import lazy { BaseFunction } from '../../../../function/core/BaseFunction';
import lazy { FeatureManager } from '../../../../function/core/FeatureManager';
import lazy { FunctionId } from '../../../../function/core/functionproperty/FunctionId';
import lazy { UiElement } from '../../../../function/core/UiElement';
import lazy { HiLog } from '../../../../utils/HiLog';
import lazy { RenderLocation } from '../../../../function/core/functionproperty/RenderLocation';
import lazy { RenderType } from '../../../../function/core/functionproperty/RenderType';
import lazy { FunctionAction } from '../../../../function/core/FunctionAction';
import lazy { execDispatch, getStates, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../../redux';
import lazy { EventBusManager } from '../../../../worker/eventbus/EventBusManager';
import lazy { FunctionValueType, ValueType } from '../../../../utils/types';
import lazy { EventBus } from '../../../../worker/eventbus/EventBus';
import lazy { BaseComponent } from '../../../../worker/BaseComponent';
import lazy { Action, ActionData } from '../../../../redux/actions/Action';
import lazy { TipService } from '../../../tip/TipService';
import lazy { TREASURE_BOX_IMAGE_ELEMENT } from '../../common/DataType';
import lazy { LandscapeIconElement } from './LandscapeIconElement';
import lazy { getTreasureBoxLottieFunctions, LottieAnimate } from '../../common/LottieAnimate';
import lazy { ContextManager } from '../../../../service/context/ContextManager';
import lazy { BlurAnimateUtil } from '../../../../utils/BlurAnimateUtil';
import ResGetter from '../../../../utils/ResGetter';
import lazy { CommonConstants } from '../../../../statistics/CommonConstants';
import lazy { ComponentIdKeys } from '../../../../utils/ComponentIdKeys';
import lazy { ActionType } from '../../../../redux/actions/ActionType';
import lazy { TreasureBoxActionType } from '../../../../redux/actions/TreasureBoxActionType';
import lazy { FunctionActionType } from '../../../../redux/actions/FunctionActionType';
import lazy { camera } from '@kit.CameraKit';
import lazy { LogStyleMode } from '../../../../function/enumbase/LogStyleMode';

/* instrument ignore file */
const TAG: string = 'LandscapeFirstListButton';
const VISION_BUNDLE_NAME: string = 'com.ohos.vassistant';
const VISION_ABILITY_NAME: string = 'VisionCameraAbility';

@Component
export struct LandscapeFirstListButton {
  // 业务数据
  private eventBus: EventBus | undefined;
  private mBase: BaseComponent | undefined;
  private functionImpl: BaseFunction | undefined;
  @State angleRotate: number = 0;
  // 接收父组件传递的id和信息；一二级切换事件触发
  private functionId: FunctionId = FunctionId.NONE;
  @Prop uiEnable: boolean = true;
  @Prop @Watch('changeElement') refresh: boolean;
  private changeSelector: (id: FunctionId) => void = () => {
  };
  private immutable: boolean = false;
  // 向icon层传递显示内容与颜色
  @State uiElement: UiElement | undefined = undefined;
  @State lottieOpenUiElement: UiElement | undefined = undefined;
  @State lottieClosedUiElement: UiElement | undefined = undefined;
  @State fillColor: boolean = true;
  @State isWhiteFont: boolean = true;
  // lottie动效相关
  @State showLightPaintingLottie: boolean = true;
  @State @Watch('onShowLightPaintingIconChange') showLightPaintingIcon: boolean = true;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State isShowRingLightView: boolean = false;
  @State specialCaseFill: boolean = false;
  @State isOpenState: Map<FunctionId, boolean> = new Map();
  private flashIssueButton: FunctionId[] = [FunctionId.ASSISTIVE_GRID];
  @StorageLink('isToVisionChangeAction') isToVisionChangeAction: boolean = false;
  @StorageLink('isShowStyleMenuChange') isShowStyleMenu: boolean = false;
  @State curStyleIndex: number = 0;
  @State isLogOpen: boolean = false;

  aboutToAppear() {
    this.changeElement();
    this.fillColor = !TREASURE_BOX_IMAGE_ELEMENT.has(this.functionId);
    if (this.immutable) {
      return;
    }
    this.eventBus = EventBusManager.getInstance().getEventBus();
    this.mBase = new BaseComponent();
    this.eventBus.on([FunctionActionType.ACTION_CHANGE_FUNCTION_VAL,
      FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM],
      (data: FunctionValueType) => {
        if (data.id === this.functionId) {
          this.changeElement();
        }
      }, this.mBase.hashCode())
    if (this.functionId === FunctionId.FLASH) {
      this.eventBus.on([
        TreasureBoxActionType.ACTION_CHANGE_WITH_ZOOM,
        ActionType.ACTION_FLASH_CHANGED
      ], () => this.changeElement(), this.mBase.hashCode());
    }
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.angleRotate = state.get<number>('contextReducer', 'rotateAngle');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
    }, null);
  }

  aboutToDisappear(): void {
    this.eventBus?.clear(this.mBase?.hashCode());
    this.mSubscriber?.destroy();
  }

  private onShowLightPaintingIconChange(): void {
    if (!this.showLightPaintingIcon || this.immutable) {
      return;
    }
    this.changeElement();
  }

  private changeElement(): void {
    if (this.functionId === FunctionId.NONE) {
      return;
    }
    HiLog.i(TAG, `changeElement invoke, funciton: ${this.functionId}.`);
    this.functionImpl = FeatureManager.getInstance().getFunction(this.functionId);
    if (!this.functionImpl) {
      return;
    }
    const uiElements: Map<Object, UiElement> = this.functionImpl.getUiElements(RenderLocation.TREASURE_BOX);
    const element: UiElement | undefined = uiElements.get(UiElement.DEFAULT);
    if (!element) {
      HiLog.e(TAG, `function: ${this.functionId}, default element is null.`);
      return;
    }
    if (!element.icon) {
      const valueElement = uiElements.get(this.functionImpl.getValue());
      if (!valueElement) {
        HiLog.e(TAG, `function: ${this.functionId}, value is not in uiElements.`);
        return;
      }
      if (!valueElement.icon) {
        element.setTextIcon(valueElement.textIcon);
        element.setTextItemSec(valueElement.textItemSec);
        element.setAccessibilityTitle(valueElement.accessibilityTitle);
        element.setAccessibilityDescription(valueElement.accessibilityDescription);
      } else if (this.flashIssueButton.includes(this.functionId)) {
        const iconOpen = uiElements.get(true)?.icon;
        const iconClosed = uiElements.get(false)?.icon;
        this.lottieOpenUiElement = element.setIcon(iconOpen)
          .setAccessibilityTitle(valueElement.accessibilityTitle)
          .setAccessibilityDescription(valueElement.accessibilityDescription);
        this.lottieClosedUiElement = this.functionImpl.getUiElements(RenderLocation.TREASURE_BOX)
          .get(UiElement.DEFAULT)?.setIcon(iconClosed)
          .setAccessibilityTitle(valueElement.accessibilityTitle)
          .setAccessibilityDescription(valueElement.accessibilityDescription);
        this.isOpenState.set(this.functionId, !this.functionImpl.getValue());
      } else {
        element.setWidth(valueElement.width);
        element.setIcon(valueElement.icon);
        element.setAccessibilityTitle(valueElement.accessibilityTitle);
        element.setAccessibilityDescription(valueElement.accessibilityDescription);
      }
    }
    this.uiElement = element;
  }

  private handleFillColor(): boolean {
    HiLog.i(TAG, `handleFillColor:${this.specialCaseFill}`);
    return this.specialCaseFill || this.fillColor;
  }

  @Builder
  LightPaintingFlashButton(): void {
    if (this.showLightPaintingLottie) {
      Column() {
      }
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilityGroup(true)
      .accessibilityText(ResGetter.getStringSafe(this.uiElement?.accessibilityTitle) +
      ResGetter.getStringSafe(this.uiElement?.accessibilityDescription))
    } else if (this.showLightPaintingIcon) {
      Column() {
        LandscapeIconElement({
          uiElement: this.uiElement,
          fillColor: this.fillColor,
          isWhiteFont: this.isWhiteFont
        })
      }
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilityGroup(true)
      .accessibilityText(ResGetter.getStringSafe(this.uiElement?.accessibilityTitle) +
      ResGetter.getStringSafe(this.uiElement?.accessibilityDescription))
      .onTouch((event) => {
        this.onTouchButton(event);
      })
      .onClick((): void => {
        this.onClickButton();
      })
    }
  }

  @Builder
  private IconElementBuilder(): void {
    if (this.uiElement) {
      Column() {
        LandscapeIconElement({
          functionId: this.functionId,
          uiElement: this.uiElement,
          fillColor: this.handleFillColor(),
          isWhiteFont: this.isWhiteFont
        })
      }
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilityGroup(true)
      .accessibilityText(this.getAccessibilityText(this.functionId))
      .onClick((): void => {
        HiLog.i(TAG, 'IconElementBuilder onClick');
        this.onClickButton();
      })
    }
  }

  private getAccessibilityText(functionId: FunctionId): string {
    return ResGetter.getStringSafe(this.uiElement?.accessibilityTitle) +
    ResGetter.getStringSafe(this.uiElement?.accessibilityDescription)
  }

  @Builder
  PopupButtonBuilder(): void {
    if (getTreasureBoxLottieFunctions().has(this.functionId)) {
      LottieAnimate({
        functionId: this.functionId,
        angleRotate: this.angleRotate
      })
        .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
        .accessibilityGroup(true)
        .accessibilityText(ResGetter.getStringSafe(this.uiElement?.accessibilityTitle) +
        ResGetter.getStringSafe(this.uiElement?.accessibilityDescription))
        .onClick(() => {
          this.onClickButton();
        })
        .onTouch((event) => {
          this.onTouchButton(event);
        })
        .key(`${ComponentIdKeys.getInstance().getKey('LandscapeTreasureBox',
          this.functionId)}_${FeatureManager.getInstance().getFunction(this.functionId)?.getValue() ?
          'OPEN' : 'CLOSE'}`)
    } else {
      this.IconElementBuilder();
    }
  }

  build() {
    Stack() {
      this.PopupButtonBuilder();
    }
  }

  private onClickButton(): void {
    if (!this.enableClick() || !this.functionImpl) {
      return;
    }
    const type: RenderType = this.functionImpl.getRenderType(RenderLocation.TREASURE_BOX);
    if (type === RenderType.POPUP_TREASURE_BOX_ITEM) {
      HiLog.i(TAG, `open TreasureBox Level-2 interface, functionId: ${this.functionId}.`);
      this.changeSelector(this.functionId);
    } else if (type === RenderType.TOGGLE_TREASURE_BOX_ITEM) {
      let value: ValueType = this.functionImpl.getValue();
      HiLog.i(TAG, `mainListBuilder onClick functionId is ${this.functionId}, change value to ${value}.`);
      value = !value
      if (getTreasureBoxLottieFunctions().has(this.functionId)) {
        execDispatch(FunctionAction.changeFunctionValue(this.functionId, value));
      } else {
        execDispatch(FunctionAction.changeFunctionValue(this.functionId, value));
        this.changeElement();
      }
    } else if (type === RenderType.POPUP_EXTEND_BAR) {
      const isShow = getStates().get<FunctionId>('uiReducer', 'extendBarEffectView') === this.functionId;
      this.hideExtendBar(isShow);
      execDispatch(Action.changeShowExtendComponent(isShow ? FunctionId.NONE : this.functionId));
    }
  }

  private hideExtendBar(isShow: boolean): void {
    execDispatch(Action.updateIsShowParamBar(isShow));
    execDispatch(Action.updateIsShowExtendBar(!isShow));
  }

  private onTouchButton(event: TouchEvent): void {
    if (event.type !== TouchType.Down) {
      return;
    }
  }

  private getVisionWant(): Want {
    return {
      bundleName: VISION_BUNDLE_NAME,
      abilityName: VISION_ABILITY_NAME
    }
  }

  private enableClick(): boolean {
    if (!this.uiEnable || this.immutable || !this.uiElement || this.uiElement.disabled) {
      return false;
    }
    HiLog.i(TAG, `firstList onClick main list button, functionId: ${this.functionId}.`);
    return true;
  }

  private tip(id: FunctionId, value: boolean): void {
  }
}