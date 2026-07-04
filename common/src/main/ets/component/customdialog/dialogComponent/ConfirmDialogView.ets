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

import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { ContextActionType } from '../../../redux/actions/ContextActionType';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { DeviceInfo } from '../../deviceinfo/DeviceInfo';
import lazy { WindowDirection } from '../../../utils/WindowDirection';
import lazy {
  DIALOG_DEFAULT_MARGIN,
  DIALOG_WIDTH_LANDSCAPE,
  DIALOG_WIDTH_TABLET,
  DIALOG_WIDTH_VDE_SEMI_COLLAPSED
} from './PhoneCustomDialogOperate';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { OhCombinedState, Unsubscribe, reduxSubscribe } from '../../../redux';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { MeasureText } from '@kit.ArkUI';
import lazy { DirectionToAngleUtil } from '../../../utils/DirectionToAngleUtil';

/* instrument ignore file */
const TAG: string = 'ConfirmDialogView';
const DIALOG_WIDTH_SEMI_COLLAPSED: number = 400;
const CANCEL_CONFIRM_FONT_COLOR: string = '#5291FF';
const ALL_PADDING_HEIGHT: number = 44;
const MAX_DIALOG_TITLE_HEIGHT: number = 96;
const MAX_DIALOG_BUTTON_HEIGHT: number = 32;
const MAX_DIALOG_BUTTON_HEIGHT_BRANCHES: number = 56;
const DIALOG_OFFSET: number = -30;

@CustomDialog
export struct ConfirmDialogView {
  private mBase: BaseComponent = new BaseComponent();
  controller?: CustomDialogController;
  cancel: () => void = () => {
  };
  confirm: () => void = () => {
  };
  title: string | Resource = '';
  description?: string | Resource = '';
  cancelText: string | Resource = '';
  confirmText: string | Resource = '';
  @State rotateAngle: number = 0;
  fixedRotateAngle?: number = 0;
  currentDirection: number = WindowDirection.TOP;
  isShowLandscape: boolean = false;
  isShowSemiCollapsed: boolean = false;
  followSystemLocation: boolean = true;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private uiEnabled: boolean = true;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State isHighContrastText: boolean = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @State textContentHeight: Length = 0;
  // 限制弹窗中列表的最大高度
  private textContentMaxHeight: Length = 0;
  // 取消和确认按钮在同一行时, 按钮的长度
  private buttonWidth: number = 0;
  private maxButtonTextLength: number = 0;
  // 取消和确认按钮在同一行时，文字是否超长
  private isButtonTextLongMoreThanHalf: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @State @Watch('updateRotationStatus') mIsLockRotation: boolean = true;
  @Prop isHdr: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear start.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.isHighContrastText = state.get<boolean>('contextReducer', 'isHighContrastText');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.mIsLockRotation = state.get<boolean>('windowReducer', 'isLockRotation');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
    }, null);

    this.textContentMaxHeight = this.getMaxTextContentHeight();
    this.buttonWidth = ((this.isShowSemiCollapsed ? DIALOG_WIDTH_SEMI_COLLAPSED : this.getWidth()) - 48) / 2 - 32;

    this.isButtonTextLongMoreThanHalf = false;
    this.maxButtonTextLength = Math.max(
      MeasureText.measureText({
        textContent: this.cancelText,
        fontSize: (this.fontSizeScale < CommonConstants.TEXT_SIZE_HUGE_LEVEL4) ?
        $r('sys.float.Body_L') : $r('app.float.dialog_button_max_font_size'),
        fontWeight: FontWeight.Medium
      }),
      MeasureText.measureText({
        textContent: this.confirmText,
        fontSize: (this.fontSizeScale < CommonConstants.TEXT_SIZE_HUGE_LEVEL4) ?
        $r('sys.float.Body_L') : $r('app.float.dialog_button_max_font_size'),
        fontWeight: FontWeight.Medium
      })
    );

    if (px2vp(this.maxButtonTextLength) > this.buttonWidth) {
      this.isButtonTextLongMoreThanHalf = true;
      HiLog.i(TAG, `show two line button view`);
    }

    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.confirmDialogClose.bind(this),
      this.mBase.hashCode());
    HiLog.i(TAG, `aboutToAppear end, isVertical currentDirection: ${this.currentDirection}....${this.followSystemLocation}`);
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear start.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    HiLog.i(TAG, 'aboutToDisappear end.');
  }

  private confirmDialogClose(): void {
    HiLog.i(TAG, 'confirmDialogClose start.');
    this.controller?.close();
    HiLog.i(TAG, 'confirmDialogClose end.');
  }

  private getMaxTextContentHeight(): Length {
    if (this.isShowSemiCollapsed) {
      return this.windowWidth / 2 * CommonConstants.DIALOG_REDUCTION_RATIO - ALL_PADDING_HEIGHT -
        MAX_DIALOG_TITLE_HEIGHT - MAX_DIALOG_BUTTON_HEIGHT;
    } else if (this.isVertical()) {
      return this.isButtonTextLongMoreThanHalf ? this.windowHeight * CommonConstants.DIALOG_REDUCTION_RATIO -
        ALL_PADDING_HEIGHT - MAX_DIALOG_TITLE_HEIGHT - MAX_DIALOG_BUTTON_HEIGHT :
        this.windowHeight * CommonConstants.DIALOG_REDUCTION_RATIO - ALL_PADDING_HEIGHT -
        MAX_DIALOG_TITLE_HEIGHT - MAX_DIALOG_BUTTON_HEIGHT_BRANCHES;
    } else {
      return this.windowWidth * CommonConstants.DIALOG_REDUCTION_RATIO - ALL_PADDING_HEIGHT -
        MAX_DIALOG_TITLE_HEIGHT - MAX_DIALOG_BUTTON_HEIGHT;
    }
  }

  @Builder
  ScrollContentViewBuilder() {
    Scroll() {
      if (this.description) {
        this.DescriptionViewBuilder();
      }
    }
    .height((this.textContentHeight > this.textContentMaxHeight) ? this.textContentMaxHeight : '')
    .padding({ left: 24, right: 24 })
    .margin({ top: this.title ? ((this.fontSizeScale > CommonConstants.TEXT_SIZE_NORMAL) ? 8 : 0) : 24 })
    .width('100%')
  }

  @Builder
  DescriptionViewBuilder() {
    Row() {
      Text(this.description)
        .fontSize($r('sys.float.Body_L'))
        .fontWeight(FontWeight.Regular)
        .fontColor(DeviceInfo.isPc() ? $r('sys.color.font_secondary') : '#DBFFFFFF')
        .fontFeature('\"ss01\" on')
        .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL2)
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .onAreaChange((oldValue, newValue) => {
      if (this.textContentHeight != newValue.height) {
        this.textContentHeight = newValue.height;
      }
    })
  }

  @Builder
  TitleViewBuilder() {
    if (this.title && this.fontSizeScale === CommonConstants.TEXT_SIZE_NORMAL) {
      Text(this.title)
        .maxFontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontSize(16)
        .maxFontScale(CommonConstants.TEXT_SIZE_NORMAL)
        .fontWeight(FontWeight.Bold)
        .fontColor(DeviceInfo.isPc() ? $r('sys.color.font_primary') : '#DBFFFFFF')
        .fontFeature('\"ss01\" on')
        .maxLines(2)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        })
        .textAlign(TextAlign.Center)
        .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
        .size({ width: '100%', height: 56 })
        .align(Alignment.Center)
        .padding({
          left: $r('sys.float.padding_level12'),
          right: $r('sys.float.padding_level12')
        })
    } else {
      Text(this.title)
        .fontSize(20)
        .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
        .fontWeight(FontWeight.Bold)
        .fontColor(DeviceInfo.isPc() ? $r('sys.color.font_primary') : '#DBFFFFFF')
        .fontFeature('\"ss01\" on')
        .maxLines(2)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        })
        .textAlign(TextAlign.Center)
        .size({ width: '100%' })
        .align(Alignment.Center)
        .padding({
          left: $r('sys.float.padding_level12'),
          right: $r('sys.float.padding_level12')
        })
        .margin({ top: this.title ? 15 : 0 })
    }
  }

  @Builder
  CancelButtonBuilder() {
    Button({
      stateEffect: true,
      type: ButtonType.Normal
    }) {
      Text(this.cancelText)
        .fontColor(this.isHighContrastText ? Color.White : DeviceInfo.isPc() ? $r('sys.color.font_emphasize') :
          CANCEL_CONFIRM_FONT_COLOR)
        .fontSize($r('sys.float.Body_L'))
        .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .align(Alignment.Center)
        .maxLines(1)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        })
    }
    .size({ width: '100%', height: '100%' })
    .padding({
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8')
    })
    .buttonStyle(ButtonStyleMode.TEXTUAL)
    .backgroundColor(Color.Transparent)
    .stateStyles({
      pressed: {
        .backgroundColor(DeviceInfo.isPc() ? $r('sys.color.interactive_click') : '#26FFFFFF')
        .borderRadius(DeviceInfo.isPc() ? $r('sys.float.corner_radius_level4') :
        $r('sys.float.ohos_id_corner_radius_button'))
      }
    })
  }

  @Builder
  ConfirmButtonBuilder() {
    Button({
      stateEffect: true,
      type: ButtonType.Normal
    }) {
      Text(this.confirmText)
        .fontColor(this.isHighContrastText ? Color.White : DeviceInfo.isPc() ? $r('sys.color.font_emphasize') :
          CANCEL_CONFIRM_FONT_COLOR)
        .fontSize($r('sys.float.Body_L'))
        .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .align(Alignment.Center)
        .maxLines(1)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        })
    }
    .size({ width: '100%', height: '100%' })
    .padding({
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8')
    })
    .buttonStyle(ButtonStyleMode.TEXTUAL)
    .backgroundColor(Color.Transparent)
    .stateStyles({
      pressed: {
        .backgroundColor(DeviceInfo.isPc() ? $r('sys.color.interactive_click') : '#26FFFFFF')
        .borderRadius(DeviceInfo.isPc() ? $r('sys.float.corner_radius_level4') :
        $r('sys.float.ohos_id_corner_radius_button'))
      }
    })
  }

  @Builder
  OneLineButtonViewBuilder() {
    Row() {
      Column() {
        this.CancelButtonBuilder();
      }
      .layoutWeight(1)
      .padding({ right: $r('sys.float.padding_level4') })
      .enabled(this.uiEnabled)
      .height('100%')
      .accessibilityGroup(true)
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .onClick((): void => {
        this.uiEnabled = false;
        this.controller?.close();
        this.cancel();
      })
      .key(ComponentIdKeys.SETTING_RESTORE_DEFAULT_CANCEL)

      if (!DeviceInfo.isPc()) {
        Line()
          .width(0.5)
          .height(24)
          .backgroundColor('#0DFFFFFF')
      }

      Column() {
        this.ConfirmButtonBuilder();
      }
      .defaultFocus(true)
      .layoutWeight(1)
      .padding({ left: $r('sys.float.padding_level4') })
      .enabled(this.uiEnabled)
      .accessibilityGroup(true)
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .onClick((): void => {
        this.uiEnabled = false;
        this.controller?.close();
        this.confirm();
      })
      .key(ComponentIdKeys.SETTING_RESTORE_DEFAULT_CONFIRM)
    }
    .margin({
      top: $r('sys.float.padding_level4'),
      bottom: $r('sys.float.padding_level8')})
    .padding({
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8')
    })
    .key(ComponentIdKeys.SETTING_RESTORE_DEFAULT_OP_BUTTON)
    // 自适应按钮高度
    .height(24 + 16 * (Math.min(this.fontSizeScale, 2)))
  }

  @Builder
  TwoLineButtonViewBuilder() {
    Column() {
      Column() {
        this.CancelButtonBuilder();
      }
      .enabled(this.uiEnabled)
      .width('100%')
      .height(24 + 16 * (Math.min(this.fontSizeScale, 2)))
      .onClick((): void => {
        this.uiEnabled = false;
        this.controller?.close();
        this.cancel();
      })
      .key(ComponentIdKeys.SETTING_RESTORE_DEFAULT_CANCEL)

      Column() {
        this.ConfirmButtonBuilder();
      }
      .width('100%')
      .height(24 + 16 * (Math.min(this.fontSizeScale, 2)))
      .enabled(this.uiEnabled)
      .onClick((): void => {
        this.uiEnabled = false;
        this.controller?.close();
        this.confirm();
      })
      .margin({top: $r('sys.float.padding_level2')})
      .key(ComponentIdKeys.SETTING_RESTORE_DEFAULT_CONFIRM)
    }
    .key(ComponentIdKeys.SETTING_RESTORE_DEFAULT_OP_BUTTON)
    .margin({ top: $r('sys.float.padding_level4') })
    .padding({
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8'),
      bottom: $r('sys.float.padding_level4')
    })
  }

  @Builder
  ButtonViewBuilder() {
    if (this.isButtonTextLongMoreThanHalf) {
      this.TwoLineButtonViewBuilder();
    } else {
      this.OneLineButtonViewBuilder();
    }
  }

  private getStackRotateAngle(): number {
    if ((this.isShowLandscape || DeviceInfo.isTablet()) && !this.isShowSemiCollapsed && !this.mIsLockRotation) {
      return 0;
    }
    return this.rotateAngle;
  }

  private updateRotationStatus(): void {
    this.getStackRotateAngle();
  }

  build() {
    Flex({ justifyContent: FlexAlign.Center }) {
      Column() {
        this.TitleViewBuilder();
        this.ScrollContentViewBuilder();
        this.ButtonViewBuilder();
      }
      .width(this.isShowSemiCollapsed ? DIALOG_WIDTH_SEMI_COLLAPSED : '100%')
      .borderRadius(DeviceInfo.isPc() ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level16'))
      .backgroundColor(DeviceInfo.isPc() ? $r('sys.color.ohos_id_color_dialog_bg') : '#202224')
    }
    .rotate({
      angle: this.followSystemLocation ? this.getRotateAngle() : this.fixedRotateAngle,
    })
    .key(ComponentIdKeys.SETTING_RESTORE_DEFAULT_CONFIRM_DIALOG)
    .margin({
      left: $r('sys.float.ohos_id_dialog_margin_start'),
      right: $r('sys.float.ohos_id_dialog_margin_end'),
      bottom: this.isShowSemiCollapsed ? 0 :
        (this.isVertical() && !this.isShowLandscape ? $r('sys.float.ohos_id_dialog_margin_bottom') : 0)
    })
    .offset(this.isShowSemiCollapsed ? { x: DIALOG_OFFSET } : {})
    .width(this.getWidth())
  }

  private getWidth(): number {
    if (DeviceInfo.isPcAndTablet()) {
      return DIALOG_WIDTH_TABLET;
    }
    if (this.isVdeSemiCollapsed && !this.isVertical()) {
      return DIALOG_WIDTH_VDE_SEMI_COLLAPSED;
    }
    if (!this.isShowLandscape && this.isVertical()) {
      HiLog.i(TAG, `aawindowWidth: ${this.windowWidth}, width: ${this.windowWidth - DIALOG_DEFAULT_MARGIN}.`);
      return this.windowWidth - DIALOG_DEFAULT_MARGIN;
    }
    HiLog.i(TAG, `bbwindowWidth: ${this.windowWidth}, width: ${DIALOG_WIDTH_LANDSCAPE}.`);
    return DIALOG_WIDTH_LANDSCAPE;
  }

  private isVertical(): boolean {
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM &&
        (this.followSystemLocation || this.fixedRotateAngle === 0);
  }

  private getRotateAngle(): number {
    if (DeviceInfo.isTablet() && this.mIsLockRotation) {
      return DirectionToAngleUtil.getRotateAngleByWindowDirection(this.mDirection) - 90;
    } else {
      return this.getStackRotateAngle();
    }
  }
}