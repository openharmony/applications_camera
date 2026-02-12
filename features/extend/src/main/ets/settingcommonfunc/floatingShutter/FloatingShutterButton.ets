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
import lazy { Dispatch, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { PropTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { AspectRatioOperation } from '@ohos/common/src/main/ets/function/aspectratio/AspectRatioOperation';
import lazy { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FloatingShutterAction } from './FloatingShutterAction';
import camera from '@ohos.multimedia.camera';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { DisplayCalculator } from '@ohos/common/src/main/ets/component/xcomponent/DisplayCalculator';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { AdaptiveLayoutService } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLayoutService';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { PositionType } from '@ohos/common/src/main/ets/utils/types';

const FLOATING_SHUTTER_LENGTH: number = 54;
const FLOATING_SHUTTER_MIDDLE: number = 2;
const FLOATING_SHUTTER_CREASE: number = 19;
const FLOATING_SHUTTER_HALF_COLLAPS_HEIGHT = 140;
const FLOATING_SHUTTER_VDE_HALF_COLLAPS_HEIGHT = 45;
const VDE_FLOATING_SHUTTER = 36;
const TOUCH_UP_DAILY: number = 50;
const FOOT_BAR_WIDTH: number = 40;
const FLOATING_SHUTTER_GRL_WIDTH: number = 400;

class LatestPositionInfo {
  public initX: number = 0;
  public initY: number = 0;
}

class FloatingShutterDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public clickFloatingShutterButton(isPicker: boolean): void {
    this.mDispatch(FloatingShutterAction.clickFloatingShutterButton(isPicker));
  }

  public disAbleModeBarChanged(isNeedDisShowingMode: boolean): void {
    this.mDispatch(Action.disAbleModeBarChanged(isNeedDisShowingMode));
  }
}

/* instrument ignore file */
const TAG = 'FloatingShutterButton';

@Component
export struct FloatingShutterButton {
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  // 移动的偏移量
  @State moveOffsetY: number = 0;
  @State moveOffsetX: number = 0;
  @State previewPositionDefault: number = AdaptiveLayoutService.getInstance().previewPosition4to3;
  @State previewPosition1to1: number = AdaptiveLayoutService.getInstance().previewPosition1to1;
  private latestPosition: LatestPositionInfo = { initX: 0, initY: 0 };
  private initX: number = 0;
  private initY: number = 0;
  // 按下时自身顶点xy轴位置
  private selfY: number = 0;
  private selfX: number = 0;
  // 按下时距屏幕的xy轴位置
  private screenY: number = 0;
  private screenX: number = 0;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  private isShowLandscape: boolean = false;
  @State @Watch('resetOffset') isShowSemiCollapsed: boolean = false;
  private adjustLandscapeX: number = 0;
  @State previewWidthDefault: number = 0;
  @State previewHeightDefault: number = 0;
  @State previewHeight1to1: number = 0;
  private mAction: FloatingShutterDispatcher = new FloatingShutterDispatcher();
  protected mPreferencesService: PreferencesService = PreferencesService.getInstance();
  private isPicker: boolean = false;
  @State @Watch('resetOffsetY') isHalfCollapsLEM: boolean = false;
  @State @Watch('updateDensity') density: number = 1//DisplayService.getInstance().getDisplay().densityPixels;
  @State isShowSubScreenRadius: boolean = false;
  @State isShowRingLightView: boolean = false;
  @State isVdeLandscape: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  private isClickFloatingShutterButton: boolean = false;
  @State isShowLowAngleShotView: boolean = false;
  @Prop footBarPosition: number = 0;
  @State mode: ModeType = ModeType.NONE;
  @Prop isHdr: boolean = false;
  @State isShowTricollaps: boolean = false;
  @Prop @Watch('initPosition') previewPosition: PositionType = { x: 0, y: 0 };
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;

  aboutToAppear() {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.screenWidth = state.get<number>('windowReducer', 'windowWidth');
      this.screenHeight = state.get<number>('windowReducer', 'windowHeight');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.density = state.get<number>('collapsReducer', 'density');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed')
      this.isShowLowAngleShotView = state.get<boolean>('collapsReducer', 'isShowLowAngleShotView');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.mEventBus.on(WindowActionType.ON_SIZE_CHANGE, this.initPosition.bind(this), this.mBase.hashCode());
    this.initPosition();
  }

  private resetOffsetY(): void {
    if (this.isVdeSemiCollapsed) {
      this.resetVdeSemiCollapsOffsetY();
      return;
    }
    if (DeviceInfo.isTablet()) {
      this.resetTabletOffsetY();
      return;
    }
    if (this.isHalfCollapsLEM) {
      let halfCollapsHeight: number = FLOATING_SHUTTER_HALF_COLLAPS_HEIGHT;
      if (this.moveOffsetY <= 0) {
        this.moveOffsetY = 0;
      } else if (this.moveOffsetY >= this.previewHeightDefault + halfCollapsHeight) {
        this.moveOffsetY = this.previewHeightDefault + halfCollapsHeight;
      }
      return;
    }
    let previewPosition: number = this.previewPositionDefault;
    let previewHeight: number = this.isVdeLandscape ? this.previewWidthDefault : this.previewHeightDefault;
    if (this.moveOffsetY <= previewPosition) {
      this.moveOffsetY = previewPosition;
    } else if (this.moveOffsetY >= previewPosition + previewHeight - FLOATING_SHUTTER_LENGTH) {
      this.moveOffsetY = previewPosition + previewHeight - FLOATING_SHUTTER_LENGTH;
    }
  }

  private resetOffset(): void {
    if (DeviceInfo.isTablet()) {
      this.resetTabletOffsetX();
      return;
    }
    if (this.isShowSemiCollapsed) {
      if (this.moveOffsetX <= (this.screenWidth - this.previewWidthDefault) /
        FLOATING_SHUTTER_MIDDLE - this.adjustLandscapeX) {
        this.moveOffsetX = (this.screenWidth - this.previewWidthDefault) /
          FLOATING_SHUTTER_MIDDLE - this.adjustLandscapeX;
      } else if (this.moveOffsetX >= this.screenWidth / 2 - FLOATING_SHUTTER_LENGTH - FLOATING_SHUTTER_CREASE) {
        this.moveOffsetX = this.screenWidth / 2 - FLOATING_SHUTTER_LENGTH - FLOATING_SHUTTER_CREASE;
      }
    } else if (this.isShowTricollaps) {
      if (this.moveOffsetX <= (this.screenWidth - this.previewWidthDefault) /
        FLOATING_SHUTTER_MIDDLE - this.adjustLandscapeX) {
        this.moveOffsetX = (this.screenWidth - this.previewWidthDefault) /
          FLOATING_SHUTTER_MIDDLE - this.adjustLandscapeX;
      } else if (this.moveOffsetX >= this.screenWidth - FLOATING_SHUTTER_LENGTH - (
        (this.screenWidth - this.previewWidthDefault) / FLOATING_SHUTTER_MIDDLE) - this.adjustLandscapeX +
        FLOATING_SHUTTER_GRL_WIDTH) {
        this.moveOffsetX = this.screenWidth - FLOATING_SHUTTER_LENGTH -
          ((this.screenWidth - this.previewWidthDefault) / FLOATING_SHUTTER_MIDDLE) - this.adjustLandscapeX +
          FLOATING_SHUTTER_GRL_WIDTH;
      }
    } else {
      if (this.moveOffsetX <= (this.screenWidth - this.previewWidthDefault) /
        FLOATING_SHUTTER_MIDDLE - this.adjustLandscapeX) {
        this.moveOffsetX = (this.screenWidth - this.previewWidthDefault) /
          FLOATING_SHUTTER_MIDDLE - this.adjustLandscapeX;
      } else if (this.moveOffsetX >= this.screenWidth - FLOATING_SHUTTER_LENGTH - (
        (this.screenWidth - this.previewWidthDefault) / FLOATING_SHUTTER_MIDDLE) - this.adjustLandscapeX) {
        this.moveOffsetX = this.screenWidth - FLOATING_SHUTTER_LENGTH -
          ((this.screenWidth - this.previewWidthDefault) / FLOATING_SHUTTER_MIDDLE) - this.adjustLandscapeX;
      }
    }
  }

  private resetTabletOffsetY(): void {
    let previewPosition: number = WindowService.getInstance().isVertical() ? this.previewPosition.y : 0;
    if (this.moveOffsetY <= previewPosition) {
      this.moveOffsetY = previewPosition;
    } else if (this.moveOffsetY >= previewPosition + this.xComponentHeight - FLOATING_SHUTTER_LENGTH) {
      this.moveOffsetY = previewPosition + this.xComponentHeight - FLOATING_SHUTTER_LENGTH;
    }
  }

  private resetTabletOffsetX(): void {
    let footBarWidth: number = WindowService.getInstance().isVertical() ? 130 : this.adjustLandscapeX;
    if (this.moveOffsetX <= 0) {
      this.moveOffsetX = 0;
    } else if (this.moveOffsetX >= this.screenWidth - FLOATING_SHUTTER_LENGTH - footBarWidth) {
      this.moveOffsetX = this.screenWidth - FLOATING_SHUTTER_LENGTH - footBarWidth;
    }
  }

  aboutToDisappear(): void {
    this.mSubscriber.destroy();
  }

  initDefaultPreviewSize(): void {
    const functionImpl: BaseFunction = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO);
    let previewSizeDefault = AspectRatioOperation.getPreviewProfile(functionImpl.getDefaultValue() as number,
      camera.CameraPosition.CAMERA_POSITION_BACK, ModeType.PHOTO).size;
    let previewRatioDefault = previewSizeDefault.width / previewSizeDefault.height;
    let xComponentSizeDefault = DisplayCalculator.calcSurfaceDisplaySize(previewRatioDefault, this.screenWidth,
      this.screenHeight);
    this.previewWidthDefault = xComponentSizeDefault.width;
    // this.previewHeightDefault = xComponentSizeDefault.height;
    this.previewHeightDefault = xComponentSizeDefault.width; // 1:1 防止拖动范围超过了界面下方的模式名
    if (this.isShowLandscape) {
      let isVertical = WindowService.getInstance().isVertical();
      HiLog.d(TAG, `isVertical: ${isVertical}, ${JSON.stringify(xComponentSizeDefault)}`);
      this.previewWidthDefault = DeviceInfo.isTablet() ? xComponentSizeDefault.width :
        isVertical ? xComponentSizeDefault.width : this.screenHeight - FOOT_BAR_WIDTH;
      this.previewHeightDefault = isVertical ? xComponentSizeDefault.height : this.screenHeight;
    }
    HiLog.i(TAG,
      `initDefaultPreviewSize done, previewWidthDefault: ${this.previewWidthDefault},
      this.previewHeightDefault:${this.previewHeightDefault}.`);
  }

  build() {
    Column()
      .width(FLOATING_SHUTTER_LENGTH)
      .height(FLOATING_SHUTTER_LENGTH)
      .borderRadius(this.isShowSubScreenRadius ? 0 : FLOATING_SHUTTER_LENGTH / FLOATING_SHUTTER_MIDDLE)
      .aspectRatio(1)
      .backgroundColor(Color.White)
      .opacity(0.9)
      .shadow({
        radius: 2,
        color: 'rgba(0, 0, 0, 0.2)',
        offsetX: 0,
        offsetY: 0
      })
      .key(ComponentIdKeys.FLOATING_SHUTTER_1)
      .position({
        x: this.moveOffsetX,
        y: this.moveOffsetY,
      })
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilityText($r('app.string.floating_shutter'))
      .onClick((): void => {
        HiLog.d(TAG, 'Click capture.');
        this.isClickFloatingShutterButton = true;
        this.mAction.clickFloatingShutterButton(this.isPicker);
      })
      .onTouch((event?: TouchEvent) => this.onTouchEvent(event))
  }

  private onTouchEvent(event?: TouchEvent | undefined): void {
    if (event === undefined) {
      return;
    }
    switch (event?.type) {
      case TouchType?.Down: {
        for (let i = 0, l = event.touches.length; i < l; i++) {
          if (this.isInRegion(event?.touches[i]?.x, event?.touches[i]?.y)) {
            this.selfY = event?.touches[i]?.y;
            this.selfX = event?.touches[i]?.x;
            break;
          }
        }
        this.mAction.disAbleModeBarChanged(true);
        HiLog.i(TAG, `TouchType?.Down :selfY: ${this.selfY}, selfX:${this.selfX}.`);
      }
        break;
      case TouchType?.Move: {
        this.screenY = event?.changedTouches[0]?.screenY;
        this.screenX = event?.changedTouches[0]?.screenX;
        this.moveOffsetY = this.screenY - this.selfY;
        this.moveOffsetX = this.screenX - this.selfX;
        this.resetOffsetY();
        this.resetOffset();
      }
        break;
      case TouchType?.Up: {
        // 延迟响应touch up事件，防止click事件后响应，点击拍照之后悬浮快拍组件跳变位置。
        let timer = setTimeout(() => {
          HiLog.i(TAG, `touch up isClickFloatingShutterButton: ${this.isClickFloatingShutterButton}.`);
          if (!this.isClickFloatingShutterButton) {
            this.moveOffsetX = this.screenX - this.selfX;
            this.moveOffsetY = this.screenY - this.selfY;
            this.resetOffsetY();
            this.resetOffset();
            this.latestPosition.initX = this.moveOffsetX;
            this.latestPosition.initY = this.moveOffsetY;
            HiLog.i(TAG, `moveOffsetY: ${this.moveOffsetY}, moveOffsetX:${this.moveOffsetX}.`);
            this.mPreferencesService.putPropValue(PersistType.FOREVER,
              PropTag.FLOATING_SHUTTER, JSON.stringify(this.latestPosition));
          }
          this.isClickFloatingShutterButton = false;
          this.mAction.disAbleModeBarChanged(false);
          clearTimeout(timer);
        }, TOUCH_UP_DAILY);
      }
      default:
        break;
    }
  }

  private isInRegion(touchX: number, touchY: number): boolean {
    return touchX > 0 && touchX < FLOATING_SHUTTER_LENGTH && touchY > 0 && touchY < FLOATING_SHUTTER_LENGTH;
  }

  private initPosition() {
    this.initDefaultPreviewSize();
    this.previewPositionDefault = this.setPreViewTopPosition();
    this.adjustLandscapeX = this.isShowLandscape ?
      (this.screenWidth - this.previewWidthDefault) / FLOATING_SHUTTER_MIDDLE : 0;
    const latestPositionStr: string = this.mPreferencesService.getPropValue(PersistType.FOREVER,
      PropTag.FLOATING_SHUTTER, JSON.stringify(this.latestPosition)) as string;
    this.latestPosition = JSON.parse(latestPositionStr);
    this.moveOffsetX = this.latestPosition.initX;
    this.initY = this.latestPosition.initY;
    this.moveOffsetY = this.initY ? this.initY : this.previewPositionDefault;
    this.resetOffsetY();
    this.resetOffset();
  }

  private setPreViewTopPosition(): number {
    let position: number = this.previewPositionDefault;
    if (this.isShowLandscape) {
      position = 0;
    }
    if (DeviceInfo.isTablet()) {
      if (WindowService.getInstance().isVertical()) {
        position = this.previewPosition.y;
      } else {
        position = 0;
      }
    }
    HiLog.i(TAG, `button on PreViewTopPosition: ${position}.`);
    return position;
  }

  private updateDensity() {
    HiLog.i(TAG, 'updateDensity density=' + this.density);
    this.initPosition();
  }

  private lowAngleChangeOffsetY(): void {
    if (!this.isVdeSemiCollapsed) {
      return;
    }
    animateToImmediately({
      curve: Curve.Sharp, duration: 300, delay: 0,
    }, () => {
      this.resetVdeSemiCollapsOffsetY();
    });
  }

  private resetVdeSemiCollapsOffsetY() {
    if (this.isShowLowAngleShotView) {
      if (this.moveOffsetY <= this.previewHeightDefault / 2 + FLOATING_SHUTTER_LENGTH) {
        this.moveOffsetY = this.previewHeightDefault / 2 + FLOATING_SHUTTER_LENGTH;
      } else if (this.moveOffsetY > this.footBarPosition - FLOATING_SHUTTER_LENGTH / 2) {
        this.moveOffsetY = this.footBarPosition - FLOATING_SHUTTER_LENGTH / 2;
      }
      return;
    }
    if (this.moveOffsetY <= 0) {
      this.moveOffsetY = 0;
    } else if (this.moveOffsetY >= this.previewHeightDefault / 2) {
      this.moveOffsetY = this.previewHeightDefault / 2;
    }
  }
}