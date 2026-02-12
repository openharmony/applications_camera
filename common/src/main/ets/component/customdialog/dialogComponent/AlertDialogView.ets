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
import lazy { DIALOG_DEFAULT_MARGIN, DIALOG_WIDTH_LANDSCAPE, DIALOG_WIDTH_TABLET } from './PhoneCustomDialogOperate';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../redux';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { AnimSpecifications } from '../../../animation/AnimSpecifications';

/* instrument ignore file */
const TAG: string = 'AlertDialogView';
const DIALOG_WIDTH_SEMI_COLLAPSED: number = 400;
const ONE_SECOND_MILLISECONDS: number = 1000;
const EXIT_CAMERA_DURATION: number = 5000;

@CustomDialog
export struct AlertDialogView {
  private mBase: BaseComponent = new BaseComponent();
  controller?: CustomDialogController;
  cancel: () => void = () => {
  };
  confirm: () => void = () => {
  };
  title: string | Resource = '';
  description?: string | Resource = '';
  confirmText: string | Resource = '';
  @State isShowLandscape: boolean = false;
  @State isShowSemiCollapsed: boolean = false;
  @State mDirection: WindowDirection = WindowDirection.TOP;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private uiEnabled: boolean = true;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State windowWidth: number = 0;
  @State isHighContrastText: boolean = false;
  @State isButtonTouchDown: boolean = false;
  private dialogCountDown: number = 0;
  @State exitCameraCountDown: number = 5;
  private mTimer: number = Number.MIN_VALUE;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear start.');
    this.dialogCountDown = EXIT_CAMERA_DURATION + Date.now();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.isHighContrastText = state.get<boolean>('contextReducer', 'isHighContrastText');
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
    }, null);
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.alertDialogClose.bind(this), this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear end');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear start.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    clearTimeout(this.mTimer);
    HiLog.i(TAG, 'aboutToDisappear end.');
  }

  private alertDialogClose(): void {
    HiLog.i(TAG, 'confirmDialogClose start.');
    this.controller?.close();
    HiLog.i(TAG, 'confirmDialogClose end.');
  }

  private setIntervalTimer() {
    HiLog.i(TAG, 'setIntervalTimer.');
    clearTimeout(this.mTimer);
    this.mTimer = setInterval(() => {
      this.updateText();
    }, 100);
  }

  private isVertical(): boolean {
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  private getRotate(): number {
    HiLog.i(TAG, `mDirection: ${this.mDirection}`);
    if (DeviceInfo.isTablet()) {
      return 0;
    }
    if (this.isShowLandscape) {
      return this.isShowSemiCollapsed ? AnimSpecifications.ANIM_ROTATE_90 : 0;
    }
    switch (this.mDirection) {
      case WindowDirection.TOP:
        return 0;
      case WindowDirection.BOTTOM:
        return 0;
      case WindowDirection.RIGHT:
        return AnimSpecifications.ANIM_ROTATE_90;
      case WindowDirection.LEFT:
        return AnimSpecifications.ANIM_ROTATE_270;
      default:
        return 0;
    }
  }

  private updateText(): void {
    const counterTime: number = this.dialogCountDown - Date.now();
    this.exitCameraCountDown = Math.ceil((counterTime < 0 ? 0 : counterTime) / ONE_SECOND_MILLISECONDS);
  }

  build() {
    Flex({ justifyContent: FlexAlign.Center }) {
      Column() {
        Row() {
          Text($r('app.string.device_hot_exit_tips', this.exitCameraCountDown))
            .fontSize($r('sys.float.Subtitle_M'))
            .fontColor(DeviceInfo.isPc() ? $r('sys.color.font_primary') : '#DBFFFFFF')
            .onAppear((): void => {
              this.setIntervalTimer();
            })
        }
        .width('100%')
        .padding({
          left: $r('sys.float.padding_level4'),
          right: $r('sys.float.padding_level4'),
          bottom: $r('sys.float.padding_level4')
        })
        .justifyContent(this.description ? FlexAlign.Start : FlexAlign.Center)

        Row() {
          Flex({
            direction: FlexDirection.Column,
            justifyContent: FlexAlign.Center,
            alignItems: ItemAlign.Center
          }) {
            Button() {
              Text(this.confirmText)
                .fontColor(this.isHighContrastText ? Color.White : $r('sys.color.brand_font_contrary'))
                .fontSize($r('sys.float.Body_L'))
                .textCase(TextCase.UpperCase)
                .fontWeight(FontWeight.Medium)
                .fontSize((this.fontSizeScale <= CommonConstants.TEXT_SIZE_HUGE_LEVEL2) ? 16 : '32vp')
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .height('100%')
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .backgroundColor(this.isButtonTouchDown ? '#26ffffff' : Color.Transparent)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.isButtonTouchDown = true;
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.isButtonTouchDown = false;
              }
            })
          }
          .layoutWeight(1)
          .height(40)
          .padding({ right: $r('sys.float.padding_level2') })
          .enabled(this.uiEnabled)
          .onClick((): void => {
            this.uiEnabled = false;
            this.controller?.close();
            this.confirm();
          })
          .key(ComponentIdKeys.SETTING_RESTORE_DEFAULT_CANCEL)

        }
        .height(40)
      }
      .width(this.isShowSemiCollapsed ? DIALOG_WIDTH_SEMI_COLLAPSED : '100%')
      .borderRadius($r('sys.float.ohos_id_corner_radius_dialog'))
      .padding({
        left: $r('sys.float.padding_level8'),
        right: $r('sys.float.padding_level8'),
        top: $r('sys.float.padding_level12'),
        bottom: $r('sys.float.padding_level8')
      })
      .backgroundColor(DeviceInfo.isPc() ? $r('sys.color.ohos_id_color_dialog_bg') : '#202224')
    }
    .rotate({
      angle: this.getRotate(),
    })
    .margin({
      left: $r('sys.float.ohos_id_dialog_margin_start'),
      right: $r('sys.float.ohos_id_dialog_margin_end'),
      bottom: this.isShowSemiCollapsed ? 0 :
        (this.isVertical() && !this.isShowLandscape ? $r('sys.float.ohos_id_dialog_margin_bottom') : 0)
    })
    .width(this.getWidth())
  }

  private getWidth(): Length {
    if (DeviceInfo.isPcAndTablet()) {
      return DIALOG_WIDTH_TABLET;
    }
    if (!this.isShowLandscape && this.isVertical()) {
      HiLog.i(TAG, `windowWidth: ${this.windowWidth}, width: ${this.windowWidth - DIALOG_DEFAULT_MARGIN}.`);
      return this.windowWidth - DIALOG_DEFAULT_MARGIN;
    }
    HiLog.i(TAG, `windowWidth: ${this.windowWidth}, width: ${DIALOG_WIDTH_LANDSCAPE}.`);
    return DIALOG_WIDTH_LANDSCAPE;
  }
}