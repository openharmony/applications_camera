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

import camera from '@ohos.multimedia.camera';
import window from '@ohos.window';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { reduxSubscribe, OhCombinedState, Dispatch, getStates } from '@ohos/common/src/main/ets/redux';
import lazy { Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { PositionType } from '@ohos/common/src/main/ets/utils/types';
import lazy {
  FocusExposureAreaDispatcher
} from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureAreaDispatcher';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { FocusExposureActionType } from '@ohos/common/src/main/ets/redux/actions/FocusExposureActionType';
import lazy { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import lazy { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import lazy { FocusArea } from './FocusArea';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { FocusExposureService } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureService';
import lazy {
  EventEffectiveInfo,
  LockLevel,
  FocusData,
  ExposureData,
  TipInfo
} from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper';
import lazy { FocusLock } from '@ohos/common/src/main/ets/component/focusExposure/FocusLock';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { RecordActionType } from '@ohos/common/src/main/ets/redux/actions/RecordActionType';
import lazy { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { ThumbnailActionType } from '@ohos/common/src/main/ets/redux/actions/ThumbnailActionType';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import dataObserver from '@ohos/common/src/main/ets/utils/dataObserver';
import lazy { WindowEventData } from '@ohos/common/src/main/ets/utils/types';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import lazy { Event } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper';
import lazy {
  CollaborateControlActionType
} from '@ohos/common/src/main/ets/redux/actions/CollaborateControlActionType';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { simpleStringify } from '@ohos/common/src/main/ets/utils/SimpleStringify';
import lazy {
  SettingFuncDialogItemIndex
} from '@ohos/common/src/main/ets/component/settingview/SettingFuncDialogItemIndex';
import { ExposureArea } from '../../commonfunc/exposure/ExposureArea';
import lazy { ExposureFunction } from '../../commonfunc/exposure/ExposureFunction';

const TAG: 'FocusExposureArea' = 'FocusExposureArea';

class EnterImmersiveStruct {
  public isImmersive?: boolean = false;
  public mainTrigCompo?: UIOperationType = UIOperationType.NULL;
  public isShowtimeLapse?: boolean = false;
  public isShowTimedShot?: boolean = false;
}

interface PhotoBrowserStatus {
  photoBrowserStatus: boolean
};

interface FocusState { focusState: camera.FocusState };

const EXPOSE_FOCUS_DURING: number = 3000;

interface CollaborateCoord {
  x: number;
  y: number;
}

@Component
export struct FocusExposureArea {
  @Builder
  childBuilder() {
  }

  // 使用父组件@Builder装饰的方法初始化子组件@BuilderParam
  @BuilderParam childBuilderParam: () => void = this.childBuilder;
  @LocalStorageLink('previewAnimatePosition') previewAnimatePosition: PositionType = { x: 0, y: 0 };
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;
  @State mode: ModeType = ModeType.NONE;
  @State exposurePosition: PositionType = { x: 0, y: 0 };
  @State focusOpacity: number = 1;
  @State exposureOpacity: number = 1;
  @State focusPosition: PositionType = { x: 0, y: 0 };
  @State @Watch('resetFocusState') isShowSemiCollapsed: boolean = false;
  @State isShowExposureRing: boolean = false;
  @State @Watch('handleFocusVisibility') isShowFocus: boolean = false;
  @State isShowExposure: boolean = false;
  @State focusLockPosition: PositionType = { x: 0, y: 0 };
  @State panGestureAction: TouchType = TouchType.Up;
  @State panGestureEventOffset: number = 0;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  @State @Watch('resetFocusState') isHalfCollapsLEM: boolean = false;
  @State @Watch('handleLockLevelChange') lockLevel: LockLevel = LockLevel.UNLOCK;
  @State isSupportedFocusStateDetect: boolean = false;
  @State touchPreviewAgain: string = '';
  @State @Watch('resetFocusExposure') superMacroEnable: boolean = false;
  @State @Watch('handleMorePageShow') isShowMorePage: boolean = false;
  @State @Watch('resetFocusExposure') windowStatus: window.WindowStatusType = window.WindowStatusType.FULL_SCREEN;
  @State uiEnable: boolean = true;
  @State @Watch('handleZoomChange') zoomRatio: number = 1;
  @State @Watch('changeExposureViewPosition') rotateAngle: number = 0;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @Prop isHdr: boolean = false
  @StorageLink('isCustomFilterCardTouched') isCustomFilterCardTouched: boolean = false;
  private cinemaFocusTimer: number = Number.NaN;
  @LocalStorageLink('cinemaTracking') cinemaTracking: boolean = false;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mAction: FocusExposureAreaDispatcher = new FocusExposureAreaDispatcher();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  private focusProgressTimerId: number = Number.MIN_VALUE;
  private mFocusExposureService: FocusExposureService = FocusExposureService.getInstance();
  private tabSelector: FunctionId = FunctionId.NONE;
  private isVdeCollapsed: boolean = false;
  private focusMode: camera.FocusMode = camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO;
  @State private isEditMorePage: boolean = false;
  private iconId: number = -1;
  private longPressTip: Resource = $r('app.string.exposure_focus_locked');
  private isShowExtendBar: boolean = false;
  private isImmersive: boolean = false;
  private mainTrigCompo: UIOperationType = UIOperationType.NULL;
  private isShowtimeLapse: boolean = false;
  private lockLevelBeforePan: LockLevel = LockLevel.UNLOCK;
  private progressOpacity: number = 1;
  private exposureMode: camera.ExposureMode = camera.ExposureMode.EXPOSURE_MODE_AUTO;
  private recordState: RecordingState = RecordingState.READY;
  private isShowTimedShot: boolean = false;

  aboutToAppear(): void {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.cameraPosition = state.get<number>('cameraReducer', 'cameraPosition');
      this.tabSelector = state.get<FunctionId>('tabBarReducer', 'tabBarSelector');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isSupportedFocusStateDetect = state.get<boolean>('focusExposureReducer', 'isSupportedFocusStateDetect');
      this.focusMode = state.get<camera.FocusMode>('focusExposureReducer', 'focusMode');
      this.isShowExposure = state.get<boolean>('focusExposureReducer', 'isShowExposure');
      this.isShowExposureRing = state.get<boolean>('focusExposureReducer', 'isShowExposureRing');
      this.isShowExtendBar = state.get<boolean>('uiReducer', 'isShowExtendBar');
      this.isShowFocus = state.get<boolean>('focusExposureReducer', 'isShowFocus');
      this.lockLevel = state.get<LockLevel>('focusExposureReducer', 'lockLevel');
      this.iconId = state.get<number>('uiReducer', 'iconId');
      this.superMacroEnable = state.get<boolean>('superMacroReducer', 'superMacroEnable');
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.isEditMorePage = state.get<boolean>('modeReducer', 'isEditMorePage');
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.zoomRatio = state.get<number>('zoomReducer', 'zoomRatio');
      this.isImmersive = state.get<boolean>('uiReducer', 'isImmersive');
      this.mainTrigCompo = state.get<UIOperationType>('uiReducer', 'mainTrigCompo');
      this.isShowtimeLapse = state.get<boolean>('settingReducer', 'isShowtimeLapse');
      this.exposureMode = state.get<camera.ExposureMode>('focusExposureReducer', 'exposureMode');
      this.recordState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.windowStatus = state.get<number>('windowReducer', 'windowStatus');
      this.isShowTimedShot = state.get<boolean>('settingReducer', 'isShowTimedShot');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });

    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.CHANGE_OUTPUT_TYPE,
      CameraActionType.RESTART, CameraActionType.SWITCH_CAMERA_CHANGE_MODE, CameraActionType.SWITCH_CAMERA,
      ContextActionType.UPDATE_SAVE_POWER_MODE_STATE, ContextActionType.ABILITY_ON_BACKGROUND],
      this.resetFocusState.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.PHOTOBROWSER_STATUS, this.handlePhotoBrowserOpen.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([RecordActionType.STOPPED, FocusExposureActionType.ACTION_RESET_FOCUS_EXPOSURE,
      WindowActionType.REFRESH_UX, ActionType.ACTION_SHOW_PICKER],
      this.resetFocusExposure.bind(this), this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_CHANGE_TIME_LAPSE, ActionType.ACTION_IS_ENTER_IMMERSIVE],
      this.handleEnterImmersiveForFocus.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FocusExposureActionType.ACTION_UPDATE_FOCUS_STATE,
      this.handleFocusStateChange, this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.CHANGE_WINDOW_EVENT_TYPE, this.onChangeWindowEvent.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.FOCUS, this.collaborateFocusExposure.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_CHANGE_TIMED_SHOT, ActionType.ACTION_IS_ENTER_IMMERSIVE],
      this.handleEnterImmersiveForFocus.bind(this), this.mBase.hashCode());
    dataObserver(this, 'mainTrigCompo', this.handleMainTrigCompoChange);
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'previewArea aboutToDisappear called.');
    this.mAction.hideTip();
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    this.resetFocusState();
  }

  private resetFocusState(data?: Record<string, object>): void {
    HiLog.i(TAG, `resetFocusState E ${JSON.stringify(data)}`);
    this.clearFocusProgressTimer();
    if (this.isShowFocus) {
      this.mAction.hideFocus();
    }
  }

  private resetFocusMode(): void {
    HiLog.i(TAG, 'resetFocusMode E');
    let focusMode: camera.FocusMode = camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO;
    this.mFocusExposureService.setFocusValue({ focusMode: focusMode, isParamSetting: false });
  }

  private resetFocusExposureMode(): void {
    HiLog.i(TAG, 'resetFocusExposureMode E');
    if (!this.isShowFocus) {
      return;
    }
    this.resetFocusMode();
    this.mFocusExposureService.setExposureValue({
      exposureMode: camera.ExposureMode.EXPOSURE_MODE_AUTO,
      exposureValue: 0
    });
  }

  private resetFocusExposure(): void {
    HiLog.i(TAG, 'resetFocusExposure E');
    if (this.panGestureAction !== TouchType.Up) {
      this.panGestureAction = TouchType.Up;
    }
    this.mAction.uiEnabled();
    this.resetFocusExposureMode();
    this.resetFocusState();
  }

  private handlePhotoBrowserOpen(data: PhotoBrowserStatus): void {
    HiLog.i(TAG, 'handlePhotoBrowserOpen E.');
    if (!data.photoBrowserStatus) {
      return;
    }
    this.resetFocusState();
  }

  private resetSmartControlLocked(): void {
    if (getStates().get<LockLevel>('focusExposureReducer', 'smartControlLocked')) {
      this.mAction.resetSmartControlLocked();
    }
  }

  private onChangeWindowEvent(data: WindowEventData) {
    HiLog.i(TAG, `onChangeWindowEvent windowStageEventType: ${data.windowStageEventType}.`);
    if ((data.windowStageEventType === window.WindowStageEventType.PAUSED ||
      data.windowStageEventType === window.WindowStageEventType.INACTIVE) && this.panGestureAction !== TouchType.Up) {
      this.panGestureAction = TouchType.Up;
      this.mAction.uiEnabled();
      let lockLevel: LockLevel = LockLevel.FOCUS_LOCK;
      if (this.lockLevelBeforePan !== LockLevel.FOCUS_LOCK) {
        lockLevel = LockLevel.TEMPORARY_LOCK;
      }
      this.mAction.updateLockLevel(lockLevel);
    }
  }

  private handleZoomChange(): void {
    if (!this.isShowFocus) {
      return;
    }
    HiLog.i(TAG, 'handleZoomChange E.');
    this.resetFocusExposure();
  }

  // 处理小太阳EV滑动手势
  private handlePanGestureAction = (action: TouchType) => (event: GestureEvent) => {
    if (AppStorage.get<boolean>('isNightShutting')) {
      HiLog.i(TAG, `The image is being saved.`);
      return;
    }
    if (this.isLemCollaps || this.isVdeCollapsed || !this.isShowExposure ||
      this.panGestureAction === TouchType.Up && action === TouchType.Move) {
      return;
    }
    HiLog.i(TAG, `handlePanGestureAction action: ${action}, rotateAngle: ${this.rotateAngle}.`);
    if (action === TouchType.Down) {
      this.mAction.uiDisabled();
      this.resetSmartControlLocked();
      HiLog.i(TAG, `handlePanGestureAction lockLevel: ${this.lockLevel}.`);
      this.lockLevelBeforePan = this.lockLevel;
      this.mAction.updateLockLevel(LockLevel.LOCK_PAUSE);
    } else if (action === TouchType.Up) {
      this.mAction.uiEnabled();
      let lockLevel: LockLevel = LockLevel.FOCUS_LOCK;
      if (this.lockLevelBeforePan !== LockLevel.FOCUS_LOCK) {
        lockLevel = LockLevel.TEMPORARY_LOCK;
      }
      this.mAction.updateLockLevel(lockLevel);
    }
    this.panGestureAction = action;
    this.panGestureEventOffset = this.mFocusExposureService.getExposureOffset(this.rotateAngle, event);
  };

  /**
   * 遥控拍照场景对焦
   */
  private collaborateFocusExposure(data: CollaborateCoord): void {
    const direction = getStates().get<WindowDirection>('contextReducer', 'direction');
    HiLog.d(TAG,
      `data:${JSON.stringify(data)},preview:${JSON.stringify(this.previewAnimatePosition)}, xW:${this.xComponentWidth}, xH:${this.xComponentHeight},d:${direction}`);
    let gx: number = 0;
    let gy: number = 0;
    switch (direction) {
      case WindowDirection.LEFT:
        gx = data.y;
        gy = 1 - data.x;
        break;
      case WindowDirection.RIGHT:
        gx = 1 - data.y;
        gy = data.x;
        break;
      case WindowDirection.TOP:
        gx = data.x;
        gy = data.y;
        break;
      case WindowDirection.BOTTOM:
        gx = 1 - data.y;
        gy = 1 - data.x;
        break;
    }
    const event: Event = {
      fingerList: [{
        globalX: this.xComponentWidth * gx,
        globalY: this.previewAnimatePosition.y + this.xComponentHeight * gy
      }],
      fromWatchTouch: true
    };
    HiLog.d(TAG, `event: ${JSON.stringify(event)}`)
    this.handleFocusExposure(event as GestureEvent);
  }

  // 处理touch - 短按/长按 数据下发
  private handleFocusExposure(event: GestureEvent, isLongPress: boolean = false): boolean {
    const eventInfo: EventEffectiveInfo = this.mFocusExposureService.getEventEffectiveInfo(event,
      this.previewAnimatePosition, isLongPress);
    if (!eventInfo.isEffective) {
      HiLog.i(TAG, 'longPressShowExposureAndFocus, out of ranges');
      return false;
    }
    this.handleShow(eventInfo, isLongPress);
    return this.handleSetFocusPoint(isLongPress);
  }

  // AF/AE 显示控制
  private handleShow(eventInfo: EventEffectiveInfo, isLongPress: boolean): void {
    this.focusPosition = eventInfo.focusPosition;
    this.exposurePosition = eventInfo.exposurePosition;
    this.resetSmartControlLocked();
    HiLog.i(TAG, `handleFocusExposureShow isLongPress: ${isLongPress}, isShowFocus: ${this.isShowFocus}.`);
    let lockLevel: LockLevel = LockLevel.TEMPORARY_LOCK;
    let isShowExposureRing: boolean = false;
    let isShowExposure: boolean = false;
    if (isLongPress) {
      const isSupportFocusLockExposure: boolean = this.mFocusExposureService.isSupportFocusLockExposure();
      const isSupportFocusExposureRing: boolean = this.mFocusExposureService.isSupportFocusExposureRing();
      const isSupportOnlyFocus: boolean = this.mFocusExposureService.isSupportOnlyFocusLock();
      if (isSupportFocusLockExposure) {
        isShowExposure =
          !(FeatureManager.getInstance().getFunction(FunctionId.EXPOSURE) as ExposureFunction).getExposureDisabled();
        lockLevel = LockLevel.FOCUS_LOCK;
      } else if (isSupportFocusExposureRing) {
        isShowExposureRing = true;
        lockLevel = LockLevel.FOCUS_EXPOSURE_LOCK;
      } else if (isSupportOnlyFocus) {
        lockLevel = LockLevel.FOCUS_LOCK;
      }
    } else if (!this.mFocusExposureService.isOnlyFocusSupported()) {
      isShowExposure =
        !(FeatureManager.getInstance().getFunction(FunctionId.EXPOSURE) as ExposureFunction).getExposureDisabled();
    }

    if (this.isShowExposureRing !== isShowExposureRing) {
      this.mAction.updateShowExposureRing(isShowExposureRing);
    }
    if (this.isShowExposure !== isShowExposure) {
      this.mAction.updateShowExposure(isShowExposure);
    }

    if (this.lockLevel === lockLevel) {
      this.handleFocusProgress();
    } else {
      this.mAction.updateLockLevel(lockLevel);
    }

    // 对焦框显示
    if (this.isShowFocus) {
      this.handleFocusShow();
      this.touchPreviewAgain = Date.now().toString(36);
    } else {
      this.mAction.updateShowFocus(true);
    }
    HiLog.i(TAG, `setFocusValue focusPosition: ${simpleStringify(this.focusPosition)}`);
  }

  private handleSetFocusPoint(isLongPress: boolean, eventInfo?: EventEffectiveInfo): boolean {
    const focusPosition = eventInfo?.focusPosition ?? this.focusPosition;
    const exposurePosition = eventInfo?.exposurePosition ?? this.exposurePosition;
    this.mFocusExposureService.setFocusValue({
      focusMode: camera.FocusMode.FOCUS_MODE_AUTO,
      focusPoint: focusPosition
    });

    if (this.isShowExposure || this.isShowExposureRing) {
      let exposureMode: camera.ExposureMode = camera.ExposureMode.EXPOSURE_MODE_AUTO;
      HiLog.i(TAG, `handleFocusExposure exposureMode: ${this.exposureMode}`);
      if ((isLongPress || this.exposureMode === camera.ExposureMode.EXPOSURE_MODE_LOCKED) && this.isShowExposure) {
        exposureMode = camera.ExposureMode.EXPOSURE_MODE_LOCKED;
      }
      this.mFocusExposureService.setExposureValue({
        exposureMode: exposureMode,
        exposurePoint: focusPosition
      }, true);
    }
    return true;
  }

  // 点击屏幕
  private tapGesturePreview = (event: GestureEvent): void => {
    HiLog.i(TAG, 'tapGesturePreview E.');
    const isShowExtendBar: boolean = this.isShowExtendBar;
    this.mAction.previewClicked();
    if (this.isVdeCollapsed ||
    this.isShowtimeLapse || this.isShowTimedShot ||
      this.isImmersive && this.mainTrigCompo !== UIOperationType.LR_SWIPE || isShowExtendBar) {
      return;
    }
    const timedShot: number = FeatureManager.getInstance().getFunction(FunctionId.TIMED_SHOT)?.getValue();
    const timeLapse: number = FeatureManager.getInstance().getFunction(FunctionId.TIME_LAPSE)?.getValue();
    const timeLapseType: boolean = !timeLapse || timeLapse <= SettingFuncDialogItemIndex.INDEX_FIR;
    const timeShotType: boolean = !timedShot || timedShot <= SettingFuncDialogItemIndex.INDEX_FIR;
    if (this.isLemCollaps && timeShotType && (timeLapseType || this.recordState === RecordingState.RECORDING)) {
      // 考虑移除
      this.mAction.captureLemCollaps();
      return;
    }

    // 定时拍摄
    if (this.isLemCollaps && timeLapse && timeLapse > SettingFuncDialogItemIndex.INDEX_FIR && timeShotType) {
      this.mAction.changeTimeLapse(true);
    }


    if (this.tabSelector !== FunctionId.NONE) {
      this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
      return;
    }


    this.handleFocusExposure(event);
  }
  // 长按
  private longPressShowExposureAndFocus = (event: GestureEvent): void => {
    HiLog.i(TAG, 'LongPressGesture onAction.');
    const isShowExtendBar: boolean = this.isShowExtendBar;
    this.mAction.previewClicked(true);
    const isSupportLongPress: boolean = this.mFocusExposureService.isSupportLongPress();
    if (this.isLemCollaps || !isSupportLongPress || this.isShowExposureRing || this.isVdeCollapsed || this.isShowtimeLapse ||
      this.isImmersive && this.mainTrigCompo !== UIOperationType.LR_SWIPE || isShowExtendBar) {
      HiLog.i(TAG, `LongPressGesture isShowExposureRing: ${this.isShowExposureRing}`);
      return;
    }

    if (this.tabSelector !== FunctionId.NONE) {
      this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
      return;
    }

    const isEffect: boolean = this.handleFocusExposure(event, true);
    if (!isEffect) {
      return;
    }

    VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_LONG_PRESS_ID);
    if (TipService.getInstance().isAlwaysShowTip()) {
      TipService.getInstance().hideAlwaysShowTip(TipService.getInstance().alwaysShowTipMessage);
    }
    const tipInfo: TipInfo = this.mFocusExposureService.getLongPressTip();
    this.longPressTip = tipInfo.tipText;

    TipService.getInstance().showTip(this.longPressTip, tipInfo.tipDuring, true);
    HiLog.i(TAG, 'LongPressGesture end');
  }

  // 更新曝光图标位置 （包括 手机旋转）
  private changeExposureViewPosition(): void {
    if (!this.isShowExposure) {
      return;
    }
    this.exposurePosition = this.mFocusExposureService.getExposurePosition(this.focusPosition);
  }

  // 处理锁定状态
  private handleLockLevelChange(): void {
    HiLog.i(TAG, `handleLockLevelChange lockLevel:${this.lockLevel}.`);
    if (this.lockLevel === LockLevel.LOCK_PAUSE) {
      this.clearFocusProgressTimer();
      this.focusOpacity = 1;
      this.exposureOpacity = 1;
      // 是否从 continue auto 变为auto
      const focusData: FocusData = FeatureManager.getInstance().getFunction(FunctionId.FOCUS).getValue();
      if (this.isShowExposure && focusData.focusMode !== camera.FocusMode.FOCUS_MODE_AUTO) { // 使用 lock 解决
        this.mFocusExposureService.setFocusValue({
          focusMode: camera.FocusMode.FOCUS_MODE_AUTO,
          focusPoint: this.focusPosition
        });
      }
    } else if (this.lockLevel !== LockLevel.UNLOCK) {
      this.handleFocusProgress();
    }

    if (this.lockLevel === LockLevel.UNLOCK || this.lockLevel === LockLevel.TEMPORARY_LOCK) {
      TipService.getInstance().hideAlwaysShowTip(this.longPressTip);
    }
  }

  // 监听 AF 状态上报
  private handleFocusStateChange = (data: FocusState): void => {
    HiLog.i(TAG,
      `handleFocusStateChange lockLevel:${this.lockLevel}, isShowFocus:${this.isShowFocus}, focusState:${data.focusState}.`);
    if (data.focusState === camera.FocusState.FOCUS_STATE_SCAN && this.isShowFocus &&
      this.lockLevel === LockLevel.UNLOCK) {
      this.mFocusExposureService.setExposureValue({
        exposureMode: camera.ExposureMode.EXPOSURE_MODE_AUTO,
        exposureValue: 0
      });
      this.resetFocusState();
    }
  }

  build() {
    Stack() {
      this.childBuilderParam()
      FocusArea({
        focusPosition: this.focusPosition,
        previewAnimatePosition: this.previewAnimatePosition,
        touchPreviewAgain: this.touchPreviewAgain,
        isHdr: this.isHdr
      })
        .zIndex(ZIndex.FOCUS_INDEX)
        .position(this.focusPosition)
        .opacity(this.focusOpacity)
        .visibility(AppStorage.get('isPSDCollaps') ? Visibility.None : Visibility.Visible)

      ExposureArea({
        focusPosition: this.exposurePosition,
        previewAnimatePosition: this.previewAnimatePosition,
        exposurePosition: this.exposurePosition,
        panGestureAction: this.panGestureAction,
        panGestureEventOffset: this.panGestureEventOffset,
        touchPreviewAgain: this.touchPreviewAgain,
        isHdr: this.isHdr
      })
        .zIndex(ZIndex.FOCUS_INDEX)
        .position(this.exposurePosition)
        .opacity(this.exposureOpacity)
        .visibility(Visibility.Visible)

      FocusLock({
        focusPosition: this.focusPosition,
        touchPreviewAgain: this.touchPreviewAgain,
        isHdr: this.isHdr
      })
        .zIndex(ZIndex.FOCUS_INDEX)
        .position(this.focusLockPosition)
        .opacity(this.focusOpacity)
    }
    .width('100%')
    .height('100%')
    .key('focusExposureArea')
    .enabled(this.uiEnable)
    .hitTestBehavior(HitTestMode.Transparent)
    .accessibilityLevel(this.isShowMorePage && this.isEditMorePage ?
      CommonConstants.ACCESSIBILITY_LEVEL_NO : CommonConstants.ACCESSIBILITY_LEVEL_YES)
    .accessibilityText(this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT ?
      ResGetter.getStringSafe($r('app.string.accessibility_front_preview')) :
      ResGetter.getStringSafe($r('app.string.accessibility_back_preview')))
    .onTouch(() => {
      // 无障碍场景 PreviewGestureArea无法聚焦，但是需要播报对应的引导提示语
    })
    .gesture(GestureGroup(GestureMode.Exclusive,
      LongPressGesture({
        repeat: false,
        duration: 500,
        isFingerCountLimited: true
      })
        .onAction(this.longPressShowExposureAndFocus),
      PanGesture({
        fingers: 1,
        direction: this.rotateAngle % 180 === 0 ? PanDirection.Vertical : PanDirection.Horizontal,
        distance: this.isShowExposure ? 1 : Number.MAX_VALUE,
        isFingerCountLimited: true
      })
        .onActionStart(this.handlePanGestureAction(TouchType.Down))
        .onActionUpdate(this.handlePanGestureAction(TouchType.Move))
        .onActionEnd(this.handlePanGestureAction(TouchType.Up)),
      TapGesture({
        fingers: 1,
        distanceThreshold: 5,
        isFingerCountLimited: true
      })
        .onAction(this.tapGesturePreview)
    ))
    .onGestureJudgeBegin((gestureInfo: GestureInfo, event: BaseGestureEvent) => {
      if (this.isCustomFilterCardTouched) {
        return GestureJudgeResult.REJECT
      }
      return GestureJudgeResult.CONTINUE;
    })
  }

  // ================== 动效 start ==================
  private clearFocusProgressTimer = (): void => {
    if (Number.MIN_VALUE === this.focusProgressTimerId) {
      return;
    }
    HiLog.i(TAG, `clearFocusTimer focusProgressTimerId: ${this.focusProgressTimerId}.`);
    clearTimeout(this.focusProgressTimerId);
    this.focusProgressTimerId = Number.MIN_VALUE;
  }

  private isFocusDelayDisappear(): boolean {
    let isDelay: boolean = false;
    if (this.lockLevel === LockLevel.TEMPORARY_LOCK) {
      if (this.isSupportedFocusStateDetect) {
        isDelay = this.focusMode === camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO;
      }
    } else {
      isDelay = true;
    }
    HiLog.i(TAG, `isFocusDelayDisappear isDelay: ${isDelay}`);
    return isDelay;
  }

  private handleFocusProgressFinish(isDelay: boolean): void {
    HiLog.i(TAG, `handleFocusProgress onFinish, recordState: ${this.recordState}, lockLevel: ${this.lockLevel}.`);
    const exposureData: ExposureData = FeatureManager.getInstance().getFunction(FunctionId.EXPOSURE).getValue();
    if (this.lockLevel === LockLevel.TEMPORARY_LOCK &&
      (this.recordState === RecordingState.READY || exposureData.exposureValue === 0)) {
      this.mAction.updateLockLevel(LockLevel.UNLOCK);
      if (isDelay) {
        this.resetFocusMode();
      } else {
        this.resetFocusExposure();
      }
    }
  }

  // 对焦变成半透明 存留/消失
  private handleFocusProgress = (): void => {
    HiLog.i(TAG, 'handleFocusProgress E.');
    this.clearFocusProgressTimer();
    this.focusProgressTimerId = setTimeout(() => {
      this.clearFocusProgressTimer();
      const isDelay: boolean = this.isFocusDelayDisappear();
      const opacity: number = isDelay ? 0.5 : 0;
      HiLog.i(TAG,
        `handleFocusProgress opacity: ${opacity}, lockLevel: ${this.lockLevel}, isImmersive: ${this.isImmersive}`);
      animateToImmediately({
        duration: 200,
        curve: Curve.Sharp,
        onFinish: () => {
          this.handleFocusProgressFinish(isDelay);
        }
      }, () => {
        if (this.isImmersive && this.mainTrigCompo !== UIOperationType.LR_SWIPE || this.isShowMorePage ||
        this.isShowtimeLapse || this.isShowTimedShot) {
          this.progressOpacity = opacity;
        } else {
          this.focusOpacity = opacity;
          this.exposureOpacity = opacity;
        }
      });

    }, EXPOSE_FOCUS_DURING);
  }
  private handleFocusHidden = (): void => {
    HiLog.i(TAG, 'handleFocusHidden E.');
    animateToImmediately({
      duration: 200,
      curve: Curve.Sharp,
      onFinish: () => {
        HiLog.i(TAG, 'handleFocusHidden onFinish.');
      }
    }, () => {
      this.focusOpacity = 0;
      this.exposureOpacity = 0;
    });
  }
  private handleFocusShow = (): void => {
    HiLog.i(TAG, 'handleFocusShow start.');
    this.focusOpacity = 0;
    this.exposureOpacity = 0;
    animateToImmediately({
      duration: 200,
      curve: Curve.Sharp,
      onFinish: () => {
        HiLog.i(TAG, 'handleFocusVisibility onFinish');
      }
    }, () => {
      this.focusOpacity = 1;
      this.exposureOpacity = 1;
    });
    HiLog.i(TAG, 'handleFocusVisibility end.');
  }

  // 对焦显示
  private handleFocusVisibility(): void {
    HiLog.i(TAG, `handleFocusVisibility isShowFocus: ${this.isShowFocus}.`);
    if (this.isShowFocus) {
      this.handleFocusShow();
    } else {
      this.handleFocusHidden();
    }
  }

  // 暂时隐藏或从暂时隐藏出来
  private handleTempHideShow(isHide: boolean, mainTrigCompo?: UIOperationType): void {
    if (isHide) {
      this.progressOpacity = this.focusOpacity;
    }
    const targetOpacity = isHide ? 0 : this.progressOpacity;
    HiLog.i(TAG, `handleEnterImmersiveForFocus, start ${targetOpacity}`);
    animateToImmediately({
      duration: 150,
      curve: Curve.Sharp,
      onFinish: () => {
        HiLog.i(TAG, 'handleEnterImmersiveForFocus, onFinish');
      }
    }, () => {
      this.focusOpacity = targetOpacity;
      if (mainTrigCompo !== UIOperationType.EXPOSURE) {
        this.exposureOpacity = targetOpacity;
      }
    });
  }

  // 处理进/出更多页
  private handleMorePageShow(): void {
    if (!this.isShowFocus) {
      return;
    }
    this.handleTempHideShow(this.isShowMorePage);
  }

  // 右滑录像中，滑动调曝光沉浸式结束
  private handleMainTrigCompoChange = (type: UIOperationType, oldType: UIOperationType): void => {
    HiLog.i(TAG, `handleMainTrigCompoChange type: ${type}，oldType: ${oldType}`);
    if (type === UIOperationType.LR_SWIPE && oldType === UIOperationType.EXPOSURE) {
      this.progressOpacity = 1;
      this.handleTempHideShow(false, type);
    }
  };

  // 沉浸式显隐动效
  private handleEnterImmersiveForFocus(data: EnterImmersiveStruct): void {
    if (!this.isShowFocus || data.mainTrigCompo === UIOperationType.LR_SWIPE) {
      return;
    }
    const isEnterImmersive = !!(data.isImmersive || data.isShowtimeLapse || data.isShowTimedShot);
    HiLog.i(TAG, `handleEnterImmersive data: ${JSON.stringify(data)}`);
    this.handleTempHideShow(isEnterImmersive, data.mainTrigCompo);
  }
}