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

import lazy { HiLog } from '../../../utils/HiLog';
import lazy { DeviceInfo } from '../../deviceinfo/DeviceInfo';
import lazy { WindowDirection } from '../../../utils/WindowDirection';
import lazy {
  DIALOG_DEFAULT_MARGIN,
  DIALOG_WIDTH_LANDSCAPE,
  DIALOG_WIDTH_TABLET,
  PhoneCustomDialogOperate
} from './PhoneCustomDialogOperate';
import lazy { OhCombinedState, Unsubscribe, reduxSubscribe } from '../../../redux';
import lazy { PickerUiService } from '../../../service/picker/PickerUiService';
import lazy { CameraErrorCode } from '../../../camera/childthread/modules/CameraInputWrap';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';

/* instrument ignore file */
const TAG: string = 'CameraErrorDialogView';

const DIALOG_WIDTH_SEMI_COLLAPSED: number = 400;
const CONFIRM_FONT_COLOR: string = '#5291FF';
const ALL_PADDING_HEIGHT: number = 44;
const MAX_DIALOG_TITLE_HEIGHT: number = 96;
const MAX_DIALOG_BUTTON_HEIGHT: number = 32;

export interface CameraErrorDialogViewParams {
  confirm: () => void;
  title: string | Resource;
  description?: string | Resource;
  confirmText: string | Resource;
}

export interface CameraErrorData {
  code: number;
  msg: string;
}

@CustomDialog
export struct CameraErrorDialogView {
  controller?: CustomDialogController;
  confirm: () => void = () => {
  };
  title: string | Resource = '';
  description?: string | Resource = '';
  confirmText: string | Resource = '';
  rotateAngle: number = 0;
  currentDirection: number = WindowDirection.TOP;
  isShowSemiCollapsed: boolean = false;
  private isVertical: boolean = this.currentDirection === WindowDirection.TOP ||
    this.currentDirection === WindowDirection.BOTTOM;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State isCancelButtonTouchDown: boolean = false;
  @State isConfirmButtonTouchDown: boolean = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @State textContentHeight: Length = 0;
  // 限制弹窗中列表的最大高度
  private textContentMaxHeight: Length = 0;
  @State isHighContrastText: boolean = false;
  @State isShowTricollaps: boolean = false;
  @State isShowLandscape: boolean = false;

  private StatusErrorViewClose(): void {
    HiLog.i(TAG, 'StatusErrorViewClose start.');
    this.controller?.close();
    HiLog.i(TAG, 'StatusErrorViewClose end.');
  }

  public static getDefaultParams(errorCode: number): CameraErrorDialogViewParams {
    let title: string | Resource = '';
    let description: string | Resource = '';
    let confirmText: string | Resource = '';
    let subConfirm: () => void = () => {
    };

    HiLog.i(TAG, `pass errorCode: ${errorCode}`);
    if (errorCode === CameraErrorCode.CONFLICT_CAMERA || errorCode === CameraErrorCode.DEVICE_DISABLED) { // 相机被停用
      title = $r('app.string.title_disabled');
      description = $r('app.string.content_disabled');
      confirmText = $r('app.string.dialog_ok_security');
    } else if (errorCode === CameraErrorCode.DEVICE_PREEMPTED) { // 相机被占用
      title = $r('app.string.title_occupied');
      description = $r('app.string.content_occupied');
      confirmText = $r('app.string.dialog_ok_security');
    } else if (errorCode === CameraErrorCode.PC_NOT_FIND_CAMERA) { // PC未检测到相机
      title = $r('app.string.title_not_detected');
      description = $r('app.string.content_not_detected');
      confirmText = $r('app.string.dialog_ok_security');
    } else { // 其他打开相机报错
      if (errorCode === 0) {
        description = '错误码未初始化！'
      } else {
        description = $r('app.string.content_unable_connect');
        confirmText = $r('app.string.option_exit_camera');
        subConfirm = () => {
          PickerUiService.getInstance().terminateSelfWithResult();
        };
      }
    }
    return {
      title: title,
      description: description,
      confirmText: confirmText,
      confirm: subConfirm
    };

  }

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.isHighContrastText = state.get<boolean>('contextReducer', 'isHighContrastText');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
    }, null);

    this.textContentMaxHeight = this.getMaxTextContentHeight();
    this.isVertical = this.currentDirection === WindowDirection.TOP || this.currentDirection === WindowDirection.BOTTOM;
    HiLog.i(TAG, `isVertical currentDirection: ${this.currentDirection}.`);

  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear start.');
    this.mSubscriber.destroy();
    HiLog.i(TAG, 'aboutToDisappear end.');
  }

  @Builder
  TitleViewBuilder() {
    if (this.title && this.fontSizeScale === CommonConstants.TEXT_SIZE_NORMAL) {
      Text(this.title)
        .maxFontSize($r('sys.float.ohos_id_text_size_headline8'))
        .minFontSize(16)
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
          left: $r('sys.float.padding_level12'), right: $r('sys.float.padding_level12')
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
          left: $r('sys.float.padding_level12'), right: $r('sys.float.padding_level12')
        })
        .margin({ top: this.title ? 15 : 0 })
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
        .fontSize($r('sys.float.ohos_id_text_size_body1'))
        .fontWeight(FontWeight.Medium)
        .fontColor(DeviceInfo.isPc() ? $r('sys.color.font_secondary') : '#DBFFFFFF')
        .fontFeature('\"ss01\" on')
        .textAlign(TextAlign.Start)
    }.width('100%').justifyContent(FlexAlign.Center).onAreaChange((oldValue, newValue) => {
      if (this.textContentHeight != newValue.height) {
        this.textContentHeight = newValue.height;
      }
    })
  }

  @Builder
  ButtonViewBuilder() {
    Row() {
      Column() {
        Button({
          stateEffect: true,
          type: ButtonType.Normal
        }) {
          Text(this.confirmText)
            .fontColor(this.isHighContrastText ? Color.White : CONFIRM_FONT_COLOR)
            .fontSize((this.fontSizeScale < CommonConstants.TEXT_SIZE_HUGE_LEVEL4) ? $r('sys.float.Body_L') :
            $r('app.float.dialog_button_max_font_size'))
            .fontWeight(FontWeight.Medium)
            .size({ width: '100%', height: '100%' })
            .textAlign(TextAlign.Center)
            .align(Alignment.Center)
        }
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .borderRadius(DeviceInfo.isPc() ? $r('sys.float.corner_radius_level4') :
        $r('sys.float.ohos_id_corner_radius_button'))
        .backgroundColor(this.isConfirmButtonTouchDown ? '#26ffffff' : Color.Transparent)
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Down) {
            this.isConfirmButtonTouchDown = true;
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.isConfirmButtonTouchDown = false;
          }
        })
      }.layoutWeight(1).onClick((): void => {
        this.controller?.close();
        this.confirm();
      })
    }.margin({ top: $r('sys.float.padding_level4') }).padding({
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8'),
      bottom: $r('sys.float.padding_level8')
    }).height(56)
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
    }.rotate({
      angle: this.rotateAngle,
    }).margin({
      left: $r('sys.float.ohos_id_dialog_margin_start'),
      right: $r('sys.float.ohos_id_dialog_margin_end'),
      bottom: this.isShowSemiCollapsed ? 0 :
        (this.isVertical && !this.isShowLandscape ? $r('sys.float.ohos_id_dialog_margin_bottom') : 0)
    }).width(this.getWidth())
  }

  private getWidth(): Length {
    if (DeviceInfo.isPcAndTablet()) {
      return DIALOG_WIDTH_TABLET;
    }
    if (this.isShowTricollaps && this.isVertical) {
      return DIALOG_WIDTH_LANDSCAPE;
    }
    if (!this.isShowLandscape && this.isVertical) {
      HiLog.i(TAG, `windowWidth: ${this.windowWidth}, width: ${this.windowWidth - DIALOG_DEFAULT_MARGIN}.`);
      return this.windowWidth - DIALOG_DEFAULT_MARGIN;
    }
    HiLog.i(TAG, `windowWidth: ${this.windowWidth}, width: ${DIALOG_WIDTH_LANDSCAPE}.`);
    return DIALOG_WIDTH_LANDSCAPE;
  }

  private getMaxTextContentHeight(): Length {
    if (this.isShowSemiCollapsed) {
      return this.windowWidth / 2 * CommonConstants.DIALOG_REDUCTION_RATIO - ALL_PADDING_HEIGHT -
        MAX_DIALOG_TITLE_HEIGHT - MAX_DIALOG_BUTTON_HEIGHT;
    } else if (this.isVertical) {
      return this.windowHeight * CommonConstants.DIALOG_REDUCTION_RATIO - ALL_PADDING_HEIGHT - MAX_DIALOG_TITLE_HEIGHT -
        MAX_DIALOG_BUTTON_HEIGHT;
    } else {
      return this.windowWidth * CommonConstants.DIALOG_REDUCTION_RATIO - ALL_PADDING_HEIGHT - MAX_DIALOG_TITLE_HEIGHT -
        MAX_DIALOG_BUTTON_HEIGHT;
    }
  }
}

