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
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { HorizontalLevelOperation } from './HorizontalLevelOperation';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { OhCombinedState, Unsubscribe, reduxSubscribe, getStates } from '@ohos/common/src/main/ets/redux';
import lazy { ChangeState } from '@ohos/common/src/main/ets/redux/Store';
import display from '@ohos.display';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { PositionType } from '@ohos/common/src/main/ets/utils/types';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy {
  SettingFuncDialogItemIndex
} from '@ohos/common/src/main/ets/component/settingview/SettingFuncDialogItemIndex';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { window } from '@kit.ArkUI';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { DisplayCalculator } from '@ohos/common/src/main/ets/component/xcomponent/DisplayCalculator';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { ThumbnailActionType } from '@ohos/common/src/main/ets/redux/actions/ThumbnailActionType';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';

/* instrument ignore file */
const TAG: string = 'HorizontalLevelView';
const TABLET_WIDTH: number = 360;
const VIBRATOR_USAGE_PHYSIC = 'physicalFeedback';
const DURATION: number = 150;
const HORIZONTAL_LAST_TIME: number = 2000;


class StateStruct {
  public xComponentWidth: number = 0;
  public xComponentHeight: number = 0;
}

@Component
export struct HorizontalLevelView {
  private mBase: BaseComponent = new BaseComponent();
  @StorageLink('ShowFlashBlackOpacity') @Watch('spiritLevelAppearAnim') opacityValue: number = 0;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State radius: number = 22; //中间圆半径
  private LINE_WIDTH_DEFAULT: number = 1; //默认线条宽度
  private RADIUS_DEFAULT: number = 22; //默认中间圆半径
  private ANGLE_90 = 90;
  private ANGLE_2 = 2;
  private ANGLE_88 = 88;
  private NUMBER_DOUBLE: number = 2;
  private paddingLeft: number = 61;
  private dashDotNumber: number = 8; // 圆中间虚点的数量
  private dashDotWidth: number = 1; //虚点宽度
  private dashDotGap: number = (this.radius * this.NUMBER_DOUBLE - this.dashDotWidth * this.dashDotNumber) /
    (this.dashDotNumber + 1); //虚点之间的间隔宽度
  private animationTime = 400;
  private disappearingTime = 50;
  private mAspectRatio: SettingFuncDialogItemIndex = 0;
  private mVideoResolution: SettingFuncDialogItemIndex = 0;
  @State xComponentWidth: number = 0;
  @State centerPointX: number = 0;
  @StorageProp('sensorAngle') @Watch('senSorAngleChange') sensorAngle: number = 0;
  private opaque: number = 1;
  private semitransparent: number = 0.5;
  private transparent: number = 0;
  @State mStartAnimation: boolean = false;
  @State @Watch('resetComponentWidth') isShowSemiCollapsed: boolean = false;
  @State isHalfCollapsLEM: boolean = false;
  @State previewSizeLem: PositionType = { x: 0, y: 0 };
  @State mode: ModeType = ModeType.NONE;
  private mSubscriber: Unsubscribe | null = null;
  @State mDisplayRotation: number = 0;
  private timer: number = -1;
  @State horizontalOpacity: number = 0;
  @State isShowTricollaps: boolean = false;
  @StorageLink('showHorizontalLevelView') @Watch('onShowHorizontalLevelViewChange') showHorizontalLevelView: boolean =
    false;
  @StorageLink('showPhotoBrowserAction') @Watch('hiddenLevelView') showPhotoBrowserAction: boolean = false;
  @State isHdr: boolean = false;

  aboutToAppear() {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.previewSizeLem = state.get<PositionType>('collapsReducer', 'previewArea');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      this.isHdr = state.get<boolean>('settingReducer', 'isHdrOpen');
    }, null);
    this.xComponentWidth = (HorizontalLevelOperation.getInstance()
      .getViewWidth() + this.paddingLeft) / this.NUMBER_DOUBLE;
    this.centerPointX = this.xComponentWidth / this.NUMBER_DOUBLE;
    this.mEventBus.on(ThumbnailActionType.RECEIVED, this.startAnimation.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHANGE_X_COMPONENT_SIZE, this.resetComponentWidth.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([WindowActionType.ON_SIZE_CHANGE, WindowActionType.REFRESH_UX],
      this.resetDisplayRotation.bind(this),
      this.mBase.hashCode());
    HorizontalLevelOperation.getInstance().enableGListener(); // 开启注册 状态展开会在DirectionFunction中取消注册
    this.resetDisplayRotation();
    this.updateOpacity(false);
  }

  private hiddenLevelView(): void {
    // 进入大图后回来防止水平仪闪烁
    this.horizontalOpacity = 0;
    if (!this.showPhotoBrowserAction) {
      this.updateOpacity(false);
    }
  }

  aboutToDisappear() {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber?.destroy();
  }

  private onShowHorizontalLevelViewChange(): void {
    animateToImmediately({
      duration: DURATION,
      curve: Curve.Sharp
    }, () => {
      this.horizontalOpacity = this.showHorizontalLevelView ? this.opaque : 0;
    })
    if (this.horizontalOpacity === 1) {
      clearTimeout(this.timer);
      this.timer = setTimeout(() => {
        this.setHorizontalOpacity(this.transparent);
      }, HORIZONTAL_LAST_TIME);
    }
  }

  private onCollapsStatusChanged(): void {
    HorizontalLevelOperation.getInstance().enableGListener();
  }

  private getGRLCollapsedRotation(): void {
    switch (DisplayService.getInstance().getDisplay().orientation) {
      case 0: // 右
        this.mDisplayRotation = 90;
        break;
      case 1: // 下
        this.mDisplayRotation = 180;
        break;
      case 2: // 左
        this.mDisplayRotation = 270;
        break;
      case 3: // 上
        this.mDisplayRotation = 0;
        break;
      default:
        this.mDisplayRotation = 0;
        break;
    }
  }

  private resetDisplayRotation(): void {
    switch (DisplayService.getInstance().getDisplay().orientation) {
      case 0:
        // this.mDisplayRotation = 0;
        this.mDisplayRotation = 90;
        break;
      case 1:
        this.mDisplayRotation = 90;
        break;
      case 2:
        this.mDisplayRotation = 180;
        break;
      case 3:
        this.mDisplayRotation = 270;
        break;
      default:
        this.mDisplayRotation = 0;
    }
  }

  private resetComponentWidth(): void {
    const globalState = getStates();
    if (WindowService.getInstance().getWindowStatus() === window.WindowStatusType.SPLIT_SCREEN &&
      !globalState.get<boolean>('windowReducer', 'isLockRotation') &&
      !DisplayService.getInstance().isOrientationVertical()) {
      this.xComponentWidth =
        DisplayCalculator.calcSurfaceDisplaySize(16 / 9, globalState.get<number>('windowReducer', 'windowWidth'),
          globalState.get<number>('windowReducer', 'windowHeight')).width - this.paddingLeft * this.NUMBER_DOUBLE;
    } else {
      this.xComponentWidth = DeviceInfo.isTablet() ? TABLET_WIDTH :
        HorizontalLevelOperation.getInstance().getViewWidth() - this.paddingLeft * this.NUMBER_DOUBLE;
    }
  }

  private startAnimation(): void {
    this.mStartAnimation = true;
  }

  private spiritLevelAppearAnim() {
    clearTimeout(this.timer);
    this.timer = setTimeout(() => {
      this.setHorizontalOpacity(this.transparent);
    }, HORIZONTAL_LAST_TIME);
    let prevOpacity: number = this.horizontalOpacity;
    animateToImmediately({
      duration: this.disappearingTime,
      curve: Curve.Sharp,
      onFinish: () => {
        this.mStartAnimation = false;
      }
    }, () => {
      this.opaque = 0;
      this.semitransparent = 0;
      this.horizontalOpacity = 0;
    });

    animateToImmediately({
      duration: this.animationTime,
      tempo: 0.5,
      delay: this.disappearingTime,
      curve: Curve.Sharp
    }, () => {
      this.opaque = 1;
      this.semitransparent = 0.5;
      if (prevOpacity) {
        this.horizontalOpacity = prevOpacity === this.opaque ? this.opaque : this.semitransparent;
      }
    });
  }

  private senSorAngleChange(): void {
    this.updateOpacity();
  }

  private isHorizontal(): boolean {
    return (Math.abs(this.sensorAngle % this.ANGLE_90) <= this.ANGLE_2 ||
      Math.abs(this.sensorAngle % this.ANGLE_90) >= this.ANGLE_88);
  }

  private updateOpacity(needVibration: boolean = true): void {
    if (this.isHorizontal() && this.showHorizontalLevelView) {
      clearTimeout(this.timer);
      // 保持水平2秒后隐藏水平线
      this.timer = setTimeout(() => {
        this.setHorizontalOpacity(this.transparent);
      }, HORIZONTAL_LAST_TIME);
      this.setHorizontalOpacity(this.opaque);
      return;
    }
    if (this.showHorizontalLevelView) {
      clearTimeout(this.timer);
      this.setHorizontalOpacity(this.semitransparent);
    }
  }

  private setHorizontalOpacity(opacity: number): void {
    animateTo({
      duration: DURATION,
      curve: Curve.Sharp
    }, () => {
      this.horizontalOpacity = opacity;
    });
  }

  build() {
    Row({ space: 0 }) {
      //左侧直线
      Line()
        .width(this.xComponentWidth / this.NUMBER_DOUBLE - this.radius)
        .height(1)
        .startPoint([0, 0])
        .endPoint([this.xComponentWidth / this.NUMBER_DOUBLE - this.radius, 0])
        .stroke(Color.White)
        .strokeWidth(this.LINE_WIDTH_DEFAULT)
      //中间圆与直线
      Stack({ alignContent: Alignment.Start }) {
        Circle()
          .width(this.NUMBER_DOUBLE * this.radius)
          .height(this.NUMBER_DOUBLE * this.radius)
          .strokeWidth(this.LINE_WIDTH_DEFAULT)
          .stroke(Color.White)
          .fillOpacity(0)

        Line()
          .width(this.NUMBER_DOUBLE * this.radius - this.dashDotGap)
          .height(1)
          .startPoint([0, 0])
          .endPoint([this.NUMBER_DOUBLE * this.radius, 0])
          .stroke(Color.White)
          .strokeDashArray(
            (Math.abs(this.sensorAngle % this.ANGLE_90) <= this.ANGLE_2 ||
              Math.abs(this.sensorAngle % this.ANGLE_90) >= this.ANGLE_88) ? [0] :
              [this.dashDotWidth, this.dashDotGap]
          )
          .strokeDashOffset(-this.dashDotGap)
          .strokeWidth(this.LINE_WIDTH_DEFAULT)
      }

      // 右边直线
      Line()
        .width(this.xComponentWidth / this.NUMBER_DOUBLE - this.radius)
        .height(1)
        .startPoint([0, 0])
        .endPoint([this.xComponentWidth / this.NUMBER_DOUBLE - this.radius, 0])
        .stroke(Color.White)
        .strokeWidth(this.LINE_WIDTH_DEFAULT)
    }
    .opacity(this.horizontalOpacity)
    .rotate({ angle: -this.sensorAngle + this.mDisplayRotation })
    .key(ComponentIdKeys.HORIZONTAL_LEVEL_PREVIEW_VIEW)
    .width(this.xComponentWidth)
    .height(this.NUMBER_DOUBLE * this.radius + this.NUMBER_DOUBLE * this.LINE_WIDTH_DEFAULT)
  }
}