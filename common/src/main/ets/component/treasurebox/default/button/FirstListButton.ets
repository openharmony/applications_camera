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
import lazy { IconElement } from './icon/IconElement';
import lazy { FunctionAction } from '../../../../function/core/FunctionAction';
import lazy { execDispatch, OhCombinedState, reduxSubscribe, Unsubscribe, getStates } from '../../../../redux';
import lazy { EventBusManager } from '../../../../worker/eventbus/EventBusManager';
import type { FunctionValueType, ValueType } from '../../../../utils/types';
import lazy { EventBus } from '../../../../worker/eventbus/EventBus';
import lazy { BaseComponent } from '../../../../worker/BaseComponent';
import lazy { TreasureBoxAction } from '../../reduce/TreasureBoxAction';
import lazy { Action } from '../../../../redux/actions/Action';
import lazy { VideoResolutionFunction } from '../../../../function/videoresolution/VideoResolutionFunction';
import lazy { FrameRateFunction } from '../../../../function/framerate/FrameRateFunction';
import lazy { TREASURE_BOX_IMAGE_ELEMENT } from '../../common/DataType';
import lazy {
  TREASURE_BOX_ELEMENT_HEIGHT,
  TREASURE_BOX_ELEMENT_VDE_COLLAPS_HEIGHT,
  TREASURE_BOX_ELEMENT_VDE_COLLAPS_WIDTH,
  TREASURE_BOX_ELEMENT_HALF_COLLAPS_LENGTH,
  TREASURE_BOX_ELEMENT_WIDTH
} from '../../../../service/UIAdaptive/AdaptiveLayoutService';
import lazy { WindowDirection } from '../../../../utils/WindowDirection';
import lazy { AnimSpecifications } from '../../../../animation/AnimSpecifications';
import lazy { Want } from '@kit.AbilityKit';
import lazy { ContextManager } from '../../../../service/context/ContextManager';
import lazy { BlurAnimateUtil } from '../../../../utils/BlurAnimateUtil';
import ResGetter from '../../../../utils/ResGetter';
import lazy { CommonConstants } from '../../../../statistics/CommonConstants';
import lazy { StoreManager } from '../../../../worker/StoreManager';
import lazy { TabBarAction } from '../../../tabbar/TabBarAction';
import lazy { AccessibilityUtils } from '../../../../utils/AccessibilityUtils';
import lazy { ModeType } from '../../../../mode/ModeType';
import lazy { ActionType } from '../../../../redux/actions/ActionType';
import lazy { FunctionActionType } from '../../../../redux/actions/FunctionActionType';
import lazy { TreasureBoxActionType } from '../../../../redux/actions/TreasureBoxActionType';
import lazy { TabBarActionType } from '../../../../redux/actions/TabBarActionType';
import lazy { camera } from '@kit.CameraKit';
import lazy { SystemLanguageUtil } from '../../../../utils/SystemLanguageUtil';
import lazy { DirectionToAngleUtil } from '../../../../utils/DirectionToAngleUtil';

/* instrument ignore file */
const TAG: string = 'FirstListButton';
const VISION_BUNDLE_NAME: string = 'com.ohos.vassistant';
const VISION_ABILITY_NAME: string = 'VisionCameraAbility';
const LOTTIE_ANIM_DELAY = 500;
const RUSSIAN_TREASURE_WIDTH_OFFSET: number = 14;
const CHANGE_TYPE_TREASURE: number = 0;

const CHANGE_ELEMENT_BY_VALUE_FUNCTIONS: FunctionId[] = [
  FunctionId.VIDEO_RESOLUTION,
  FunctionId.FRAME_RATE,
  FunctionId.SOUND_RECORDING_EFFECT
];

@Component
export struct FirstListButton {
  private eventBus: EventBus | undefined;
  private mBase: BaseComponent | undefined;
  private subscriber: Unsubscribe = { destroy: () => {} };
  @State textAngleRotate: number = 0;
  @State iconAngleRotate: number = 0;
  // 接收父组件传递的id和信息
  @Prop @Watch('changeElement') refresh: boolean;
  private immutable: boolean = false;
  private functionId: FunctionId = FunctionId.NONE;
  // 向icon层传递显示内容与颜色
  @State uiElement: UiElement = new UiElement();
  @State lottieOpenUiElement: UiElement | undefined = new UiElement();
  @State lottieClosedUiElement: UiElement | undefined = new UiElement();
  @State fillColor: boolean = true;
  @State isWhiteFont: boolean = true;
  // 一二级切换事件触发
  @Prop uiEnable: boolean = true;
  private changeSelector: (id: FunctionId) => void = () => {
  };
  // lottie动效相关
  @State isHalfCollapsLEM: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  @StorageLink('treasureBoxSelector') selector: FunctionId = FunctionId.NONE;
  @State showLightPaintingLottie: boolean = true;
  @State @Watch('onShowLightPaintingIconChange') showLightPaintingIcon: boolean = true;
  @State private abilityTitle: Resource | string = '';
  @State private abilityDescription: Resource | string = '';
  @StorageLink('isTabBarLottiePlaying') isTabBarLottiePlaying: boolean = false;
  @State isOpenState: Map<FunctionId, boolean> = new Map();
  private flashIssueButton: FunctionId[] = [FunctionId.ASSISTIVE_GRID];
  private openStatusButton: FunctionId[] = [FunctionId.ASSISTIVE_GRID];
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false;
  @StorageLink('isToVisionChangeAction') isToVisionChangeAction: boolean = false;
  @StorageLink('isOpenOrCloseTreasureBox') isOpenOrCloseTreasureBox: boolean = false; //百宝箱是否在做开关动效中
  private lottieAnimationPlaying: boolean = false;
  private setTimeout: Function = () => {};
  private mode: ModeType = ModeType.NONE;

  aboutToAppear() {
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.textAngleRotate =
        DirectionToAngleUtil.getTwoDirectionTextRotate(state.get<WindowDirection>('contextReducer', 'direction'));
      this.iconAngleRotate = state.get<number>('contextReducer', 'rotateAngle');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
    });
    this.changeElement();
    this.fillColor = !TREASURE_BOX_IMAGE_ELEMENT.has(this.functionId);
    TREASURE_BOX_IMAGE_ELEMENT.forEach((item) => {
    })
    if (this.immutable) {
      return;
    }
    this.eventBus = EventBusManager.getInstance().getEventBus();
    this.mBase = new BaseComponent();
    this.eventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, (data: FunctionValueType) => {
      if (data.id === this.functionId ||
        (data.id === FunctionId.PHOTO_FORMAT && this.functionId === FunctionId.ASPECT_RATIO)
      ) {
        this.changeElement();
      }
    }, this.mBase.hashCode());
    if (this.functionId === FunctionId.FLASH) {
      this.eventBus.on([
        TreasureBoxActionType.ACTION_CHANGE_WITH_ZOOM,
        ActionType.ACTION_FLASH_CHANGED
      ], () => this.changeElement(), this.mBase.hashCode());
    }
    if (this.functionId === FunctionId.FRAME_RATE && this.isVdeSemiCollapsed) {
      this.eventBus.on(TabBarActionType.ACTION_UPDATE_TEXT_LIST, () => this.changeElement(),
        this.mBase.hashCode());
    }
  }

  aboutToDisappear(): void {
    this.subscriber.destroy();
    this.eventBus?.clear(this.mBase?.hashCode());
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
    const functionImpl: BaseFunction = FeatureManager.getInstance().getFunction(this.functionId);
    let uiElements: Map<Object, UiElement> = functionImpl.getUiElements(RenderLocation.TREASURE_BOX);
    HiLog.i(TAG,`当前按钮的所有图标-----${uiElements.size}-------${functionImpl.constructor.name}`)
    if (this.isHalfCollapsLEM || this.isVdeCollapsed) {
      if (this.functionId === FunctionId.VIDEO_RESOLUTION) {
        if (functionImpl instanceof VideoResolutionFunction) {
          uiElements = functionImpl.getUiElementsLandscape();
        }
      } else if (this.functionId === FunctionId.FRAME_RATE) {
        if (functionImpl instanceof FrameRateFunction) {
          uiElements = functionImpl.getUiElementsLandscape();
        }
      }
    }
    let defaultElement: UiElement | undefined = new UiElement();
    if (defaultElement === undefined) {
      return;
    }
    const element = uiElements.get(functionImpl.getValue());
    const icon: Resource = defaultElement.icon || element?.icon;
    this.abilityTitle = defaultElement.accessibilityTitle || element?.accessibilityTitle || '';
    this.abilityDescription = defaultElement.accessibilityDescription || element?.accessibilityDescription || '';
    if (this.needChangeElementByValue(functionImpl)) {
      this.uiElement = element ||
      defaultElement.setAccessibilityTitle(this.abilityTitle).setAccessibilityDescription(this.abilityDescription);
    } else {
      this.uiElement = defaultElement.setIcon(icon).setAccessibilityTitle(this.abilityTitle)
        .setAccessibilityDescription(this.abilityDescription).setWidth(element?.width).setTextIcon(element?.textIcon);
      HiLog.i(TAG,`当前按钮的图标2-----${functionImpl.constructor.name}----${this.uiElement.title}-----${this.uiElement.icon}----${element!.textIcon}----${JSON.stringify(functionImpl.getValue())}`)
      if (this.flashIssueButton.includes(this.functionId)) {
        this.lottieOpenUiElement = defaultElement.setIcon(uiElements.get(true)?.icon).setAccessibilityTitle(this.abilityTitle)
          .setAccessibilityDescription(this.abilityDescription);
        this.lottieClosedUiElement = functionImpl.getUiElements(RenderLocation.TREASURE_BOX)
          .get(UiElement.DEFAULT)?.setIcon(uiElements.get(false)?.icon).setAccessibilityTitle(this.abilityTitle)
          .setAccessibilityDescription(this.abilityDescription);
        this.isOpenState.set(this.functionId, !functionImpl.getValue());
      }
    }

    // 解决参考线图标状态不刷新问题
    if (element) {
      this.uiElement = element
    }

  }

  private needChangeElementByValue(functionImpl: BaseFunction): boolean {
    if (!this.isHalfCollapsLEM && !this.isVdeCollapsed) {
      return false;
    }
    if (CHANGE_ELEMENT_BY_VALUE_FUNCTIONS.includes(this.functionId)) {
      return true;
    }
    return this.isVdeCollapsed && this.functionId === FunctionId.TIME_LAPSE && functionImpl.getValue() !== 0;
  }
  private getText(str: ResourceStr): string {
    if (!str) {
      return '';
    }
    if (typeof(str) !== 'string') {
      return SystemLanguageUtil.isEnglish() ? getContext(this).resourceManager.getStringSync(str) + ' ' :
      getContext(this).resourceManager.getStringSync(str);
    }
    return str.replace(/\s*/g, '')
  }

  @Builder
  LightPaintingFlashButton(): void {
    if (this.showLightPaintingLottie) {
      Column() {
        if (!this.isHalfCollapsLEM && !this.isVdeCollapsed) {
          Text(this.uiElement.title)
            .fontSize($r('sys.float.Body_S'))
            .textAlign(TextAlign.Center)
            .fontColor(Color.White)
            .margin({ top: $r('app.float.margin_value_8') })
            .fontWeight(FontWeight.Normal)
            .rotate({
              angle: this.textAngleRotate
            })
        }
      }
      .width(TREASURE_BOX_ELEMENT_WIDTH)
      .justifyContent(FlexAlign.SpaceBetween)
      .height(TREASURE_BOX_ELEMENT_HEIGHT)
    } else if (this.showLightPaintingIcon) {
      IconElement({
        uiElement: this.uiElement,
        fillColor: this.fillColor,
        isWhiteFont: this.isWhiteFont,
        functionId: this.functionId,
        iconAngleRotate: this.iconAngleRotate,
        textAngleRotate: this.textAngleRotate,
        isFirstListItem: true
      })
        .onClick((event) => {
          this.onClickButton();
        })
    }
  }

  build() {
    Stack() {
          this.IconElementBuilder();
    }
  }

  @Builder
  private IconElementBuilder() {
    Column() {
      IconElement({
        uiElement: this.uiElement,
        fillColor: this.fillColor,
        isWhiteFont: this.isWhiteFont,
        functionId: this.functionId,
        iconAngleRotate: this.iconAngleRotate,
        textAngleRotate: this.textAngleRotate,
        isFirstListItem: true
      })
    }
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .accessibilityGroup(true)
    .accessibilityText(`${ResGetter.getStringSafe(this.abilityTitle)}`)
    .accessibilityText(this.getABText())
    .onTouch((event) => {
      if (event.type === TouchType.Down) {
        this.onTouchButton();
      }
    })
    .onClick((event) => {
      this.onClickButton();
    })
  }

  private geTextRotate(currentDirection: number): number {
    if (currentDirection === WindowDirection.BOTTOM) {
      return AnimSpecifications.ANIM_ROTATE_180;
    }
    return 0;
  }

  private onClickButton(): void {
    HiLog.i(TAG, `onClickButton, functionId: ${this.functionId}, uiEnable: ${this.uiEnable}, immutable: ${
      this.immutable}, uiDisable: ${this.uiElement.disabled}, isTabBarLottiePlaying: ${this.isTabBarLottiePlaying}.`);
    if (!this.uiEnable || this.immutable || this.uiElement.disabled) {
      HiLog.i(TAG, 'first list button clicked but ineffective.');
      return;
    }
    if (this.isOpenOrCloseTreasureBox) {
      HiLog.i(TAG, 'first list button clicked but ineffective, isOpenOrCloseTreasureBox');
      return;
    }
    if (this.isTabBarLottiePlaying && !this.isVdeCollapsed) {
      HiLog.i(TAG, `first list button clicked but ineffective, isTabBarLottiePlaying: ${this.isTabBarLottiePlaying}`);
      return;
    }
    if (this.enableScreenReader) {
      HiLog.i(TAG, 'enableScreenReader abilityTitle' + this.abilityTitle);
      if (this.functionId !== FunctionId.ASSISTIVE_GRID) {
        AccessibilityUtils.sendAnnounceAccessibilityEvent(`${ResGetter.getStringSafe(this.abilityTitle)}`);
      }
    }
    HiLog.i(TAG, `first list button clicked , functionId: ${this.functionId}, selector: ${this.selector}`);

    const functionImpl: BaseFunction = FeatureManager.getInstance().getFunction(this.functionId);
    if (!functionImpl) {
      HiLog.i(TAG, 'functionImpl is null');
      return;
    }
    if (functionImpl.getRenderType(RenderLocation.TREASURE_BOX) === RenderType.TOGGLE_TREASURE_BOX_ITEM) {
      let value: ValueType = functionImpl.getValue();
      // 参考线、设置：百宝箱内 getValue 与点击意图不一致需取反；用 FunctionId 判断，避免 Picker 混淆后 constructor.name 失效
      if (this.functionId === FunctionId.ASSISTIVE_GRID || this.functionId === FunctionId.SETTING) {
        value = !(value as boolean);
      }
      HiLog.i(TAG, `mainListBuilder onClick functionId is ${this.functionId}, change value to ${value}.`);
      if (this.enableScreenReader && this.isOpenTouchGuide && this.functionId === FunctionId.ASSISTIVE_GRID) {
        HiLog.i(TAG, `enableScreenReader onClick FunctionId.ASSISTIVE_GRID, change value to ${value}.`);
        AccessibilityUtils.sendAnnounceAccessibilityEvent(`${ResGetter.getStringSafe(this.abilityTitle)} ${
          ResGetter.getStringSafe(value ? $r('app.string.already_on') : $r('app.string.already_off'))}`);
      }
      execDispatch(FunctionAction.changeFunctionValue(this.functionId, value));
    } else {
      HiLog.i(TAG, `mainListBuilder onClick functionId is---111 ${this.functionId}. functionImp is ${functionImpl.constructor.name}`);

      this.changeToVision();
    }
    StoreManager.getInstance().postMessage(TabBarAction.updateTabBarArr());
    StoreManager.getInstance().postMessage(TabBarAction.updatePositionAndOpacity(true));
  }

  private changeToVision(): void {
    HiLog.i(TAG, `open TreasureBox Level-2 interface, functionId: ${this.functionId}.`);
    // 跳转小艺视觉
    this.changeSelector(this.functionId);
  }

  private onTouchButton(): void {
    HiLog.i(TAG,
      `first list button is touched , functionId: ${this.functionId}, selector: ${this.selector}`);
  }

  private getVisionWant(): Want {
    return {
      bundleName: VISION_BUNDLE_NAME,
      abilityName: VISION_ABILITY_NAME
    }
  }

  private getABText(): string {
    HiLog.i(TAG, `getABText abilityTitle, functionId: ${this.functionId}, this.abilityTitle: ${this.abilityTitle},
     this.abilityDescription: ${this.abilityDescription}`);
    return ResGetter.getStringSafe(this.isOpenTouchGuide ?
      (`${ResGetter.getStringSafe(this.abilityTitle)} ${this.openStatusButton.includes(this.functionId) ?
      ResGetter.getStringSafe(this.abilityDescription) : ''}`) : '');
  }
}