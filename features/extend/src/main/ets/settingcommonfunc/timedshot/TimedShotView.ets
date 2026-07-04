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

import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { OhCombinedState, Unsubscribe, Dispatch, getStates, reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { SettingFuncDialogItemIndex } from '@ohos/common/src/main/ets/component/settingview/SettingFuncDialogItemIndex';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { DirectionToAngleUtil } from '@ohos/common/src/main/ets/utils/DirectionToAngleUtil';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { CaptureAction } from '@ohos/common/src/main/ets/function/capture/CaptureAction';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { ChangeState } from '@ohos/common/src/main/ets/redux/Store';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { WindowEventData, PositionType } from '@ohos/common/src/main/ets/utils/types';
import window from '@ohos.window';
import lazy { camera } from '@kit.CameraKit';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import lazy {
  DirectionCorrectionService } from '@ohos/common/src/main/ets/service/direction/DirectionCorrectionService';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { MIN_LOADING_MODE_DURATION } from '@ohos/common/src/main/ets/function/capture/ShutterButton';
import lazy { execAction } from '@ohos/common/src/main/ets/redux/ActionRegistry';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { PcInfo } from '@ohos/common/src/main/ets/component/deviceinfo/PcInfo';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';
import lazy { AdaptiveLayoutService } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLayoutService';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { PickerWindowType } from '@ohos/common/src/main/ets/component/picker/PickerWindowType';
import lazy { ThumbnailService } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailService';

/* instrument ignore file */
const TAG: string = 'TimedShotView';

const MODE_ROTATE_90: number = 90;
const MODE_ROTATE_270: number = 270;
const MODE_ROTATE_450: number = 450;
const MODE_ROTATE_0: number = 0;
const MAX_PHONE_COUNT: number = 9;
const PSD_COUNT_FONT_SIZE: number = 16;
const COUNT_FONT_SIZE: number = 22;
const POSITION: number = 90;
const POSITION_Y_8: number = 8;
const INTERVAL_FONT_SIZE: number = 100;
const FONT_WEIGHT: number = 300;
const TEXT_SHADOW_RADIUS: number = 3;
const TEXT_SHADOW_COLOR: string = '#33000000';
const IMAGE_SIZE: number = 64;
const ROTATE_ANGLE: number = 180;
const HEIGHT_180: number = 180;
const POSITION_130: number = 130;
const LINE_HEIGHT_130: number = 130;
const FOOT_BAR_5: number = 5;
const INTERVAL_OFF: number = -1;
const INTERVAL_2: number = 2;
const INTERVAL_5: number = 5;
const INTERVAL_10: number = 10;
const INTERVAL_DEFAULT: number = 0;
const TIME_OUT_FALSE: number = 400;
const TIME_OUT_SHOW: number = 500;
const TIME_OUT_RESET: number = 200;
const TIME_OUT_ONE: number = 1000;
const Y_POSITION_FULL_FIR: number = 140;
const Y_POSITION_HALF_SEC: number = 66;
const Y_POSITION_FULL_SEC: number = 196;

class StateStruct {
  public mode: ModeType = ModeType.NONE;
}

class IntervalTimedShotDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeTimedShot(isShowTimedShot: boolean, timedShotInterrupt?: boolean): void {
    this.mDispatch(Action.changeTimedShot(isShowTimedShot, !!timedShotInterrupt));
  }

  public capture(): void {
    this.mDispatch(CaptureAction.capture());
  }

  public changeFunctionValue(id: number, value: number | boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public emitSuperMotionTimedShot(): void {
    this.mDispatch(execAction('MotionAction', 'emitSuperMotionTimedShot'));
  }

  public startPanoramaShutterButton(): void {
    this.mDispatch(Action.startPanoramaShutterButton());
  }

  public startStitchingShutterButton(): void {
    this.mDispatch(Action.startStitchingShutterButton());
  }

  public countDownShutterAfterTimedShot(): void {
    this.mDispatch(Action.countDownShutterAfterTimedShot());
  }
}

@Component
export struct TimedShotView {
  private mBase: BaseComponent = new BaseComponent();
  @State state: StateStruct = new StateStruct();
  @State timedShot: number = 1;
  @State timedShotShow: boolean = true;
  private timer: number = -1;
  private mFeatureManager: FeatureManager = FeatureManager.getInstance();
  private mAction: IntervalTimedShotDispatcher = new IntervalTimedShotDispatcher();
  private isPhone: boolean = DeviceInfo.isPhone();
  private mSubscriber: Unsubscribe | null = null;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State proShutterValue: number = 0;
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @State isVdeCollapsed: boolean = false;
  @State rotateAngle: number = 0;
  @StorageLink('isNightShutting') isNightShutting: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State successPhotoCount: number = 1;
  @State tabBarPosition: number = 0;
  @State footBarPosition: number = 0;
  private layoutService: AdaptiveLayoutService = AdaptiveLayoutService.getInstance();
  @State windowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  @StorageLink('isPSDCollaps') @Watch('clearCollapsCapture') isPSDCollapsed: boolean = false;
  @StorageLink('isProShutterCaptureState') @Watch('clearCapture') isProShutterCapture: boolean = false;
  @State windowHeight: number = 0;
  @State windowWidth: number = 0;
  @State isHalfCollapsLEM: boolean = false;
  @State halfCollapsHeight: number = 0;
  @State @Watch('clearCapture') isShowTimedShot: boolean = false;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @State mode: ModeType = ModeType.NONE;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  @State estimatedCaptureDuration: number = 0;
  @State pickerWindowType: PickerWindowType = PickerWindowType.COLLAPSED_VERTICAL_FULL;
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;
  @State isWindowRotationChange: boolean = false;
  @State mAspectRatio: SettingFuncDialogItemIndex = 0;
  @State footPositionY: number = 0;

  public aboutToAppear(): void {
    HiLog.d(TAG, 'aboutToAppear E.');
    this.uxInit();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.windowStatus = state.get<window.WindowStatusType>('windowReducer', 'windowStatus');
      this.isShowTimedShot = state.get<boolean>('settingReducer', 'isShowTimedShot');
      this.windowHeight = state.get<window.WindowStatusType>('windowReducer', 'windowHeight');
      this.windowWidth = state.get<window.WindowStatusType>('windowReducer', 'windowWidth');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.estimatedCaptureDuration = state.get<number>('contextReducer', 'estimatedCaptureDuration')
      this.pickerWindowType = state.get<PickerWindowType>('windowReducer', 'pickerWindowType');
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
      this.mDirection = DirectionCorrectionService.directionCorrection(state.get<WindowDirection>('contextReducer', 'direction'),
        state.get<boolean>('windowReducer', 'isLockRotation'));
      changeState(this.state, {
        mode: state.get<ModeType>('modeReducer', 'mode')
      });
      if ([-POSITION, MODE_ROTATE_270].includes(this.rotateAngle)) {
        const num: number = this.isHalfCollapsLEM ? POSITION : POSITION_130;
        const height: number = this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_SEC ? 20 : 0;
        this.halfCollapsHeight = (this.windowHeight - this.windowWidth) / 2 + num - height;
      } else {
        const height: number = this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_SEC ? this.tabBarPosition : 0;
        this.halfCollapsHeight = (this.windowHeight - this.windowWidth) / 2 - HEIGHT_180 + height;
      }
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.mEventBus.on(ContextActionType.CHANGE_WINDOW_EVENT_TYPE, this.onChangeWindowEvent.bind(this),
      this.mBase.hashCode());

    this.initTimedCapture();
    HiLog.d(TAG, 'aboutToAppear X.');
  }

  private uxInit(): void {
    const windowWidth = this.windowWidth;
    const windowHeight = this.windowHeight;
    this.mAspectRatio = this.mFeatureManager.getFunction(FunctionId.ASPECT_RATIO).getValue();
    this.footBarPosition = this.layoutService.footBarPosition + FOOT_BAR_5;
    this.halfCollapsHeight = (windowHeight - windowWidth) / 2 - HEIGHT_180;
    this.tabBarPosition = this.layoutService.tabBarPosition - POSITION_130;
    if (this.windowStatus === window.WindowStatusType.FLOATING &&
      windowHeight / windowWidth < AnimSpecifications.NEW_FLOAT_WINDOW_RATIO) {
      this.tabBarPosition = AnimSpecifications.NEW_FLOAT_WINDOW_TOP_OFFSET; // 悬浮态tabBar上边距
    }
  }

  private getTimedShotValue(): void {
    // start 延续之前的逻辑，定时拍摄开启优先取定时拍摄时间，关闭则取自己的设置时间
    const timedShot: number = this.mFeatureManager.getFunction(FunctionId.TIMED_SHOT).getValue() as number;
    const timeLapse: number = this.mFeatureManager.getFunction(FunctionId.TIME_LAPSE).getValue() as number;
    const num: number = timeLapse > SettingFuncDialogItemIndex.INDEX_FIR &&
      this.successPhotoCount === 1 ? timeLapse : timedShot;
    switch (num) {
      case SettingFuncDialogItemIndex.INDEX_NONE:
      case SettingFuncDialogItemIndex.INDEX_FIR:
        this.timedShot = INTERVAL_OFF;
        break;
      case SettingFuncDialogItemIndex.INDEX_SEC:
        this.timedShot = INTERVAL_2;
        break;
      case SettingFuncDialogItemIndex.INDEX_THR:
        this.timedShot = INTERVAL_5;
        break;
      case SettingFuncDialogItemIndex.INDEX_FOUR:
        this.timedShot = INTERVAL_10;
        break;
      default:
        this.timedShot = INTERVAL_DEFAULT;
        break;
    }
  }

  private onChangeWindowEvent(data: WindowEventData): void {
    if (data.windowStageEventType === window.WindowStageEventType.PAUSED ||
      data.windowStageEventType === window.WindowStageEventType.INACTIVE) {
      this.onStatePaused();
    }
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mSubscriber?.destroy();
    this.clearInterval();
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToDisappear X.');
  }

  private calculateTimedShot(): void {
    HiLog.i(TAG, `calculate timedShot: ${this.timedShot}.`);
    if (!this.isShowTimedShot) {
      return;
    }
    if (this.timedShot > 0) {
      this.clearInterval();
      this.timedShotShow = true;
      setTimeout((): void => {
        this.timedShotShow = false;
      }, TIME_OUT_FALSE);
      if (this.enableScreenReader && this.timedShot > 0) {
        AccessibilityUtils.sendAnnounceAccessibilityEvent(this.timedShot.toString());
      }
      this.timer = setInterval(async () => {
        this.timedShot--;
        this.timedShotShow = true;
        setTimeout((): void => {
          this.timedShotShow = false;
        }, TIME_OUT_SHOW);
        if (this.timedShot < 1) {
          this.clearInterval();
          this.timedShotShow = false;
          HiLog.i(TAG, `calculate mode: ${this.state.mode}.`);
          const estimateDuration: number = this.estimatedCaptureDuration;
          this.photoCapture();
          if (this.successPhotoCount < MAX_PHONE_COUNT) {
            this.successPhotoCount += 1;
            setTimeout(() => {
              this.initTimedCapture();
            }, TIME_OUT_RESET);
          } else {
            this.mAction.changeTimedShot(false);
          }
          return;
        }
        if (this.enableScreenReader && this.timedShot > 0) {
          AccessibilityUtils.sendAnnounceAccessibilityEvent(this.timedShot.toString());
        }
      }, TIME_OUT_ONE);
    }
  }

  private clearInterval(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  private clearCollapsCapture(): void {
    if (this.isProShutterCapture || this.isShowTimedShot) {
      this.clearInterval();
      this.mAction.changeTimedShot(false, true);
    }
  }

  private clearCapture(): void {
    if (this.isProShutterCapture) {
      this.clearInterval();
      this.mAction.changeTimedShot(false, true);
    }
  }

  private initTimedCapture(): void {
    this.getTimedShotValue();
    this.calculateTimedShot();
  }

  private photoCapture(): void {
    if (!this.state.mode || OutputOperation.isPanPhotoOutput(this.state.mode)) {
      this.mAction.capture();
      this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
      this.mAction.changeFunctionValue(FunctionId.CAPTURE, true);
      // 外屏间隔定时拍点击拍照打点
	  ThumbnailService.getInstance().thumbnailUpdate();
    }
  }

  private onStatePaused(type?: string): void {
    if (this.timer !== -1) {
      this.clearInterval();
      if (type !== 'TapGesture') {
        this.photoCapture();
      }
      this.mAction.changeTimedShot(false, true);
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Flex({
        direction: FlexDirection.Column,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center,
      }) {
        Text() {
          Span(this.successPhotoCount.toString())
          Span('/')
          Span(MAX_PHONE_COUNT.toString())
        }
        .width('100%')
        .textAlign(TextAlign.Center)
        .fontSize(this.isPSDCollapsed ? PSD_COUNT_FONT_SIZE : COUNT_FONT_SIZE)
        .fontColor(Color.White)
        .position(this.getFootPositionY())
        .zIndex(ZIndex.TOP)
        .fontWeight(FontWeight.Medium)
        .rotate(this.getTextAngle())

        if (this.timedShotShow) {
          Text(this.timedShot.toString())
            .fontSize((this.isPhone || DeviceInfo.isTablet()) ? INTERVAL_FONT_SIZE : $r('sys.float.Display_L'))
            .maxFontScale(CommonConstants.TEXT_SIZE_NORMAL)
            .fontColor(Color.White)
            .fontWeight(FONT_WEIGHT)
            .height(LINE_HEIGHT_130)
            .width(LINE_HEIGHT_130)
            .textAlign(TextAlign.Center)
            .lineHeight(LINE_HEIGHT_130)
            .position(this.getTextNumPosition())
            .textShadow({ radius: TEXT_SHADOW_RADIUS, color: TEXT_SHADOW_COLOR, offsetX: 0, offsetY: 0 })
            .fontFeature('\"ss01\" on')
            .key('TimedShotView')
            .scale({
              x: AppStorage.get('isPSDCollaps') ? 0.5 : 1,
              y: AppStorage.get('isPSDCollaps') ? 0.5 : 1
            })
            .rotate(this.getTextAngle())
        }
        if (!this.isPSDCollapsed) {
          Row() {
            Image($r('app.media.ic_camera_timed_shot_pause'))
              .width(IMAGE_SIZE)
              .height(IMAGE_SIZE)
              .onClick(()=>{
                this.onStatePaused();
              })
              .accessibilityText($r('app.string.video_pause'))
          }
          .width('100%')
          .height(IMAGE_SIZE)
          .justifyContent(FlexAlign.Center)
          .position(this.getButtonPosition())
          .zIndex(ZIndex.TOP)
        }
      }
      .width(this.getXComponentSize().x)
      .height(this.getXComponentSize().y)
      .gesture(
        GestureGroup(
          GestureMode.Exclusive,
          PanGesture(new PanGestureOptions({
            fingers: 1,
            direction: PanDirection.Horizontal,
            distance: 5
          })).onActionEnd(() => {
            this.onStatePaused('TapGesture');
          }),
          TapGesture({ fingers: 1, count: 1 })
            .onAction(() =>{
              this.onStatePaused();
            }),
        )
      )
      .rotate({ angle: this.getRotateAngle() })
      .padding({
        bottom: this.isHalfCollapsLEM ? this.windowHeight / 3 : 0
      })
    }
    .zIndex(1)
    .position(this.getBoxPosition())
    .width('100%')
  }

  private getTextAngle(): RotateOptions {
    if (this.isPSDCollapsed) {
      return [-POSITION, MODE_ROTATE_270].includes(this.rotateAngle) ?
        { angle: ROTATE_ANGLE } : { angle: 0 };
    } else {
      return [-POSITION, MODE_ROTATE_270, ROTATE_ANGLE].includes(this.rotateAngle) ?
        { angle: ROTATE_ANGLE } : { angle: 0 };
    }
  }

  private getBoxPosition(): PositionType {
    const obj: PositionType = {
      x: 0,
      y: 0
    }
    if (this.isPSDCollapsed) {
      return obj;
    }
    if (this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_FIR) {
      if (this.isHalfCollapsLEM) {
        obj.x = 0;
        obj.y = 0;
      } else {
        obj.x = 0;
        obj.y = Y_POSITION_FULL_FIR
      }
    } else if (this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_SEC) {
      if (this.isHalfCollapsLEM) {
        obj.x = 0;
        obj.y = Y_POSITION_HALF_SEC;
      } else {
        obj.x = 0;
        obj.y = Y_POSITION_FULL_SEC
      }
    } else if (this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_THR) {
      obj.x = 0;
      obj.y = 0;
    }
    return obj;
  }

  private getTextNumPosition(): PositionType | null {
    return this.isHalfCollapsLEM ? {
      x: this.getXComponentSize().x / 2 - IMAGE_SIZE,
      y: this.getXComponentSize().y / 2 - IMAGE_SIZE
    } : null;
  }
  private getFootPositionY(): PositionType {
    if (this.isPSDCollapsed) {
      return {x: 0, y: POSITION_Y_8};
    }
    if (this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_FIR) {
      if ([-POSITION, MODE_ROTATE_270].includes(this.rotateAngle)) {
        const y = this.getXComponentSize().x + 25;
        const x = 0;
        const FY_NUM = 340;
        return this.isHalfCollapsLEM ? {x, y: FY_NUM} : {x, y};
      } else if ([POSITION, MODE_ROTATE_450].includes(this.rotateAngle)) {
        const x = 0;
        const FY_NUM = 65;
        return {x, y: FY_NUM};
      } else {
        const x = 0;
        const FY_NUM = 35;
        const Y_NUM = -65
        return this.isHalfCollapsLEM ? {x, y: FY_NUM} : {x, y: Y_NUM};
      }
    } else if (this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_SEC) {
      if ([-POSITION, MODE_ROTATE_270].includes(this.rotateAngle)) {
        const y = this.getXComponentSize().x - 35;
        const x = 0;
        const FY_NUM = 325;
        return this.isHalfCollapsLEM ? {x, y: FY_NUM} : {x, y};
      } else if ([POSITION, MODE_ROTATE_450].includes(this.rotateAngle)) {
        const x = 0;
        const FY_NUM = 12;
        return {x, y: FY_NUM};
      } else {
        const x = 0;
        const FY_NUM = -35;
        const Y_NUM = -125
        return this.isHalfCollapsLEM ? {x, y: FY_NUM} : {x, y: Y_NUM};
      }
    } else if (this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_THR) {
      if ([-POSITION, MODE_ROTATE_270].includes(this.rotateAngle)) {
        const Y_NUM = 200;
        const y = this.getXComponentSize().x + Y_NUM;
        const x = 0;
        const FY_NUM = this.getXComponentSize().x * 2 - 25;
        return this.isHalfCollapsLEM ? {x, y: FY_NUM} : {x, y};
      } else if ([POSITION, MODE_ROTATE_450].includes(this.rotateAngle)) {
        const x = 0;
        const FY_NUM = 65;
        const Y_NUM = 275;
        return this.isHalfCollapsLEM ? {x, y: FY_NUM}: {x: 0, y: Y_NUM};
      } else {
        const x = 0;
        const FY_NUM = 35;
        const Y_NUM = 65
        return this.isHalfCollapsLEM ? {x, y: FY_NUM} : {x, y: Y_NUM};
      }
    } else {
      return {x: 0, y: 0}
    }
  }

  private getButtonPosition(): PositionType {
    if ([-POSITION, MODE_ROTATE_270, POSITION, MODE_ROTATE_450].includes(this.getRotateAngle())) {
      if (this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_FIR) {
        const FX_NUM = 13;
        const FY_NUM = 10;
        const Y_NUM = 3;
        const X_NUM = 22;
        const fx = this.windowHeight - this.getXComponentSize().y + (this.getXComponentSize().x / 2) -
          (IMAGE_SIZE / 2) + FX_NUM;
        const fy = (this.getXComponentSize().x + IMAGE_SIZE) / 2 - FY_NUM;
        const y = (this.getXComponentSize().x + IMAGE_SIZE) / 2 - Y_NUM;
        const x = this.windowHeight - this.getXComponentSize().y - X_NUM;
        return this.isHalfCollapsLEM ? { x: fx, y: fy } : { x, y };
      } else if (this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_SEC) {
        const FX_NUM = 175;
        const X_NUM = 9;
        const fx = this.getXComponentSize().x + FX_NUM;
        const y = (this.getXComponentSize().x - IMAGE_SIZE) / 2;
        const x = this.getXComponentSize().x-X_NUM;
        return this.isHalfCollapsLEM ? {x: fx, y} : {x, y};
      } else if (this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_THR) {
        const FX_NUM = 142;
        const X_NUM = 59;
        const fx = this.getXComponentSize().y + FX_NUM;
        const y = (this.getXComponentSize().y - IMAGE_SIZE) / 2;
        const x = this.getXComponentSize().x - X_NUM;
        return this.isHalfCollapsLEM ? {x: fx, y} : {x, y};
      } else {
        return {x: 0, y: 0}
      }
    } else {
      const FY_NUM = 325;
      const fy = this.getXComponentSize().y + FY_NUM;
      const ALL_NUM = this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_THR ? 50 : 0;
      const y = this.getXComponentSize().y +
        ((this.footBarPosition - this.getXComponentSize().y - IMAGE_SIZE) / 2) - ALL_NUM;
      return this.isHalfCollapsLEM ? {x: 0, y: fy} : {x: 0, y};
    }
  }

  private getXComponentSize(): PositionType {
    const previewSize: PositionType = { x: 0, y: 0 };
    if (this.isHalfCollapsLEM) {
      if (this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_FIR) {
        HiLog.i(TAG, `into set getXComponentSize 4:3`);
        previewSize.y = this.windowHeight / 2;
        previewSize.x = previewSize.y * 3 / 4;
      } else if (this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_SEC) {
        HiLog.i(TAG, `into set getXComponentSize 1:1`);
        if (this.isPSDCollapsed) {
          previewSize.y = this.windowHeight / 2;
          previewSize.x = previewSize.y;
        } else {
          previewSize.x = this.windowWidth;
          previewSize.y = previewSize.x;
        }
      } else if (this.mAspectRatio === SettingFuncDialogItemIndex.INDEX_THR) {
        HiLog.i(TAG, `into set getXComponentHeight full`);
        previewSize.y = (this.windowHeight / 2);
        previewSize.x = previewSize.y * this.windowWidth / this.windowHeight;
      }
    } else {
      previewSize.x = this.xComponentWidth;
      previewSize.y = this.xComponentHeight;
    }
    return previewSize;
  }

  private getRotateAngle(): number {
    const rotation = DisplayService.getInstance().getDisplay().rotation;
    const isRotatablePc: boolean = PcInfo.isRotatablePc();
    if (isRotatablePc) {
      return rotation === 1 ? MODE_ROTATE_270 : rotation === 3 ? MODE_ROTATE_90 : MODE_ROTATE_0;
    }
    if (this.isPSDCollapsed) {
      return this.rotateAngle === ROTATE_ANGLE ? 0 : ROTATE_ANGLE;
    }
    const rotate = DirectionToAngleUtil.geViewRotate(this.mDirection);
    return rotate % ROTATE_ANGLE;
  }
}