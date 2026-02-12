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

import lazy { TIP_COLOR } from '@ohos/common/src/main/ets/component/tip/Tip';
import lazy { APPEAR_ANIMATION_DURING } from '@ohos/common/src/main/ets/component/tip/TipService';
import lazy { Dispatch, OhCombinedState, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { FunctionFirstToast, PropTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { DirectionToAngleUtil } from '@ohos/common/src/main/ets/utils/DirectionToAngleUtil';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import I18n from '@ohos.i18n';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { CaptureActionType } from '@ohos/common/src/main/ets/redux/actions/CaptureActionType';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';

/* instrument ignore file */
const TAG: string = 'ExposureBarViewPopup';
const POPUP_HEIGHT: number = 48;
const ROTATE_ANGLE_90: number = 90;

class ExposureBarViewPopupDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }
}

@Component
export struct ExposureBarViewPopup {
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mSubscriber: Unsubscribe | null = null;
  private mAction: ExposureBarViewPopupDispatcher = new ExposureBarViewPopupDispatcher();
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State popupOpacity: number = 1;
  @State popupOnceVisible: boolean = false;
  @State windowWidth: number = 0;
  @State isHalfCollapsLEM: boolean = false;
  @State isShowDefault: boolean = true;
  @State isShowSemiCollapsed: boolean = false;
  @State isShowLandscape: boolean = false;
  @State isShowLowAngleShotView: boolean = false;
  @State rotateAngle: number = 0;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowDefault = state.get<boolean>('collapsReducer', 'isShowDefault');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isShowLowAngleShotView = state.get<boolean>('collapsReducer', 'isShowLowAngleShotView');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.popupOnceVisible = this.getMotionToastVisible();
    this.mEventBus.on([
      CaptureActionType.VOLUME_KEY_EVENT,
      ContextActionType.UPDATE_SAVE_POWER_MODE_STATE,
      ActionType.ACTION_HANDLE_ONCE_TOAST,
      WindowActionType.ON_LOCK_ROTATION_STATUS_CHANGE, WindowActionType.REFRESH_UX
    ],
      this.handlePopupOnceVis.bind(this),
      this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber?.destroy();
    HiLog.i(TAG, 'aboutToDisappear X.');
  }

  private isVertical(): boolean {
    if (this.isShowLandscape && !this.isShowSemiCollapsed) {
      return (Math.abs(this.rotateAngle) / ROTATE_ANGLE_90) % 2 === 0;
    }
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  private handlePopupOnceVis(): void {
    if (this.popupOnceVisible) {
      this.popupOnceVisible = false;
      PreferencesService.getInstance()
        .putPropValue(PersistType.FOREVER, PropTag.PRO_EXPOSURE_FIRST_TOAST, FunctionFirstToast.HIDE_TOAST);
    }
  }

  private directionChange(): void {
    if (!this.isHalfCollapsLEM) {
      this.popupOpacity = 0;
      animateToImmediately({
        duration: APPEAR_ANIMATION_DURING,
        curve: Curve.Sharp,
      }, () => {
        this.popupOpacity = 1;
      });
    }
    return;
  }

  private getMotionToastVisible(): boolean {
    const exposureToastState = PreferencesService.getInstance().getPropValue(PersistType.FOREVER,
      PropTag.PRO_EXPOSURE_FIRST_TOAST, FunctionFirstToast.NONE_TOAST) as string;
    const motionToastVisible = exposureToastState === FunctionFirstToast.SHOW_TOAST;
    return motionToastVisible;
  }

  @Builder
  buildLandPopup() {
    Row() {
      Column() {
        Text($r('app.string.pro_popup_text_long_press'))
          .fontSize($r('sys.float.Body_S'))
          .maxFontScale(CommonConstants.TEXT_SIZE_LARGE)
          .fontColor(Color.White)
          .textAlign(TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(2)
          .borderRadius($r('sys.float.ohos_id_corner_radius_mark'))
          .padding({
            left: $r('sys.float.padding_level6'),
            right: $r('sys.float.padding_level6'),
            top: $r('sys.float.padding_level4'),
            bottom: $r('sys.float.padding_level4')
          })
          .shadow({
            radius: 2,
            color: '#99000000',
            offsetX: 0,
            offsetY: 0
          })
          .backgroundColor(TIP_COLOR)
          .translate(this.isVertical() ? { x: 0, y: 0 } : { x: 63, y: 40 })
          .rotate({ angle: this.rotateAngle })
          .fontFeature('\"ss01\" on')
      }

      Polygon({ width: 10, height: 16 })// 三角绘制
        .points([[0, 0], [0, 16], [10, 8]])
        .fill(TIP_COLOR)
    }
    .justifyContent(FlexAlign.End)
    .alignItems(VerticalAlign.Center)
    .opacity(this.popupOpacity)
    .height(POPUP_HEIGHT)
    .width(200)
    .key(ComponentIdKeys.EXPOSURE_BAR_POPUP_VIEW)
    .position({ x: -220, y: -10 })
    .visibility(this.popupOnceVisible ? Visibility.Visible : Visibility.None)
  }

  @Builder
  buildSemiPopup() {
    Column() {
      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
        Text($r('app.string.pro_popup_text_long_press'))
          .fontSize($r('sys.float.Body_S'))
          .maxFontScale(CommonConstants.TEXT_SIZE_LARGE)
          .fontColor(Color.White)
          .textAlign(TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(2)
          .borderRadius($r('sys.float.ohos_id_corner_radius_mark'))
          .padding({
            left: $r('sys.float.padding_level6'),
            right: $r('sys.float.padding_level6'),
            top: $r('sys.float.padding_level4'),
            bottom: $r('sys.float.padding_level4')
          })
          .shadow({
            radius: 2,
            color: '#99000000',
            offsetX: 0,
            offsetY: 0
          })
          .backgroundColor(this.isShowLowAngleShotView ? '#80000000' : '#34ffffff')
          .translate(!this.isVertical() ? { x: 0, y: 0 } : { x: 20, y: -46 }) // 数字均为ux设计
          .rotate({
            angle: (DirectionToAngleUtil.geViewRotate(this.mDirection) + 270) % 360
          })
          .fontFeature('\"ss01\" on')
      }

      Polygon({ width: 180, height: 10 })// 三角绘制
        .points([[50, 0], [66, 0], [58, 10]])
        .fill(this.isShowLowAngleShotView ? '#80000000' : '#34ffffff')
        .translate(!this.isVertical() ? { x: 0, y: 0 } : { x: 36, y: -16 })
    }
    .opacity(this.popupOpacity)
    .width(this.isVertical() ? 110 : 180)
    .key(ComponentIdKeys.EXPOSURE_BAR_POPUP_VIEW)
    .position(this.mDirection === WindowDirection.TOP ? {x: -50, y: -40 } : { x: -20, y: -50 })
    .visibility(this.popupOnceVisible ? Visibility.Visible : Visibility.None)
  }

  @Builder
  buildDefaultPopup() {
    Column() {
      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        Text($r('app.string.pro_popup_text_long_press'))
          .fontSize($r('sys.float.Body_S'))
          .maxFontScale(CommonConstants.TEXT_SIZE_LARGE)
          .fontColor(Color.White)
          .textAlign(TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(2)
          .borderRadius($r('sys.float.ohos_id_corner_radius_mark'))
          .padding({
            left: $r('sys.float.padding_level6'),
            right: $r('sys.float.padding_level6'),
            top: $r('sys.float.padding_level4'),
            bottom: $r('sys.float.padding_level4')
          })
          .shadow({
            radius: 2,
            color: '#99000000',
            offsetX: 0,
            offsetY: 0
          })
          .backgroundColor(TIP_COLOR)
          .rotate({ angle: DirectionToAngleUtil.geViewRotate(this.mDirection) })

          .translate(this.isVertical() ? { x: 0, y: 0 } :
            {
              x: 38, y: SystemLanguageUtil.isRTL() ? -48 :
              SystemLanguageUtil.isEnglish() ? -63 : SystemLanguageUtil.isTibetan() ? -65 : -62
            })
          .fontFeature('\"ss01\" on')
      }

      Polygon({ width: 180, height: 10 })// 三角绘制
        .points([[120, 0], [136, 0], [128, 10]])
        .fill(TIP_COLOR)
    }
    .opacity(this.popupOpacity)
    .width(180)
    .key(ComponentIdKeys.EXPOSURE_BAR_POPUP_VIEW)
    .position({ x: -90, y: -50 })
    .visibility(this.popupOnceVisible ? Visibility.Visible : Visibility.None)
  }

  // 整体位置position 相对要提示的icon调整-->三角位置固定-->文案旋转+平移使拼接三角
  // 直板、展开、位置、旋转策略均不同
  build() {
    if (this.isShowDefault) {
      this.buildDefaultPopup();
    } else {
      if (!this.isShowSemiCollapsed) {
        this.buildLandPopup();
      } else {
        this.buildSemiPopup();
      }
    }
  }
}