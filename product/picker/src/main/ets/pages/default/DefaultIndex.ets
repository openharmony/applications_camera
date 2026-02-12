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
import lazy { Action, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { PreviewGestureArea } from '../../../../../../phone/src/main/ets/pages/preview/PreviewGestureArea';
import lazy { TabBar } from '../../../../../../phone/src/main/ets/pages/default/TabBar';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { ParamBar } from '../../../../../../phone/src/main/ets/pages/default/ParamBar';
import lazy { ModeBar } from '@ohos/common/src/main/ets/component/ModeBar/default/ModeBar';
import lazy { FootBar } from '../../../../../../phone/src/main/ets/pages/default/FootBar';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy {
  TreasureBoxGestureGround
} from '@ohos/common/src/main/ets/component/treasurebox/default/TreasureBoxGestureGround';
import lazy { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { RecordAction, RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import lazy { VideoTimer } from '@ohos/common/src/main/ets/component/videoTimer/VideoTimer';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { CameraRunningState } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy {
  FunctionValueType,
  PositionType,
  SavePowerModeActionData,
  XComponentSize
} from '@ohos/common/src/main/ets/utils/types';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { ZoomStateType } from '@ohos/common/src/main/ets/function/zoombar/ZoomStateType';
import lazy { PickerView } from '../../../../../../phone/src/main/ets/pages/default/PickerView';
import lazy {
  AdaptiveLayoutService,
  FOOT_BAR_HEIGHT,
  MODE_BAR_HEIGHT,
  TAB_BAR_HEIGHT,
  ZOOM_VIEW_HEIGHT,
} from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLayoutService';
import lazy {
  FloatingShutterButton
} from '@ohos/extend/src/main/ets/settingcommonfunc/floatingShutter/FloatingShutterButton';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { ZoomAction } from '@ohos/common/src/main/ets/function/zoombar/ZoomAction';
import lazy { FlashMode } from '@ohos/common/src/main/ets/function/enumbase/FlashMode';
import lazy { AlertDialogView } from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/AlertDialogView'
import lazy { PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { getStates, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import appRecovery from '@ohos.app.ability.appRecovery';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { ZoomOperation } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import lazy { TreasureBox } from '@ohos/common/src/main/ets/component/treasurebox/default/TreasureBox';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { RouletteZoomView } from '@ohos/common/src/main/ets/function/zoombar/RouletteZoomView';
import lazy { BigText } from '@ohos/common/src/main/ets/component/bigtext/BigText';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { BlurAnimateUtil } from '@ohos/common/src/main/ets/utils/BlurAnimateUtil';
import lazy { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import lazy { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import lazy { CaptureAction } from '@ohos/common/src/main/ets/function/capture/CaptureAction';
import lazy { TimeLapseAction } from '@ohos/extend/src/main/ets/settingcommonfunc/timelapse/TimeLapseAction';
import display from '@ohos.display';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { TipBox } from '@ohos/common/src/main/ets/component/tip/TipBox';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import lazy { PickerWindowType } from '@ohos/common/src/main/ets/component/picker/PickerWindowType';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { FunctionActionType } from '@ohos/common/src/main/ets/redux/actions/FunctionActionType';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import lazy { PreviewActionType } from '@ohos/common/src/main/ets/redux/actions/PreviewActionType';

/* instrument ignore file */
const TAG: string = 'PickerDefaultIndex';
const SPLIT_SCREEN_ZOOM_HEIGHT: number = 64;
const CARD_VIEW_DEFAULT_SCALE: number = 0.7;
const EXTEND_BAR_HEIGHT: number = 380;

class ZoomFuncValueStruct {
  public zoomRatio?: number = 1;
  public isPrepareZoom?: boolean = false;
  public isUnprepareZoom?: boolean = false;
}

class PreviewFrameStartData {
  public isPreviewFrameStart: boolean = false;
}

class IndexDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeFunctionValue(id: FunctionId, value: number | string | boolean | Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public openTreasureBox(): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(true));
  }

  public closeTreasureBox(): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(false));
  }

  public resetSaveModeTimer() {
    this.mDispatch(ContextAction.resetSaveModeTimer());
  }

  public closeExtendBar() {
    this.mDispatch(Action.updateIsShowParamBar(true));
    this.mDispatch(Action.updateIsShowExtendBar(false));
  }

  public updateIsShowParamBar(showParamBar: boolean) {
    this.mDispatch(Action.updateIsShowParamBar(showParamBar));
  }

  public showExtendBar(extendBarEffectView: FunctionId): void {
    this.mDispatch(Action.changeShowExtendComponent(extendBarEffectView));
    this.mDispatch(Action.updateIsShowParamBar(false));
    this.mDispatch(Action.updateIsShowExtendBar(true));
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.ZOOM_BAR));
  }

  public updateShowPinch(flag: boolean): void {
    this.mDispatch(ZoomAction.updateShowPinch(flag));
  }

  public switchZoomRatio(toNext: boolean) {
    this.mDispatch(ZoomAction.switchZoomRatio(toNext));
  }

  public swipeChangeMode(swipe: number): void {
    this.mDispatch(Action.swipeChangeMode(swipe));
  }

  public changeTimeLapse(isShowtimeLapse: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse));
  }

  public capture(): void {
    this.mDispatch(CaptureAction.capture());
  }

  public startVideoAnim(): void {
    this.mDispatch(TimeLapseAction.startVideoAnim());
  }

  public startRecording(): void {
    this.mDispatch(Action.uiStateWithMode(false, UiStateMode.EXCLUDE_PREVIEW));
    this.mDispatch(RecordAction.start());
  }
}

class CameraErrorData {
  public code: number = 0;
  public msg: string = '';
}

class TabPosition {
  public x: number = 0;
  public y: number = 0;
}

class ShowParm {
  public showModeBar: boolean = false;
}

export class LumationConfirmData {
  public info: number = 0;
}

export class WindowSizeStruct {
  public width: number = 0;
  public height: number = 0;
}

export class RestoreDialogConfirmData {
  public restoreConfirmFlag: boolean = false;
}

@Component
export struct DefaultIndex {
  // 消息事件
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mAction: IndexDispatcher = new IndexDispatcher();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  // 全局数据
  private mBase: BaseComponent = new BaseComponent();
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State rotateAngle: number = 0;
  @State @Watch('onModeChange') mode: ModeType = ModeType.NONE;
  private layoutService: AdaptiveLayoutService = AdaptiveLayoutService.getInstance();
  // UX位置
  private isNeedPlayZoomTransAnim: boolean = false;
  private isNeedPlayParamBarTransAnim: boolean = false;
  @LocalStorageLink('previewAnimatePosition') previewPosition: PositionType = { x: 0, y: 0 };
  @State zoomTranslate: number = 0;
  @State footBarPosition: number = 0;
  @State zoomPosition: number = 0; // 老变焦布局规则RingZoomPosition-Deprecated
  @State extendBarPosition: number = 0;
  @State rouletteZoomPosition: number = 0;
  @State modeBarPosition: number = 0;
  @State arrowPosition: number = 0;
  @State tabBarPosition: number = 0;
  @State compoMargin: number = 0;
  @State bigTextPosition: PositionType = { x: 0, y: 0 };
  // 显示与隐藏动效
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State @Watch('timerStateOnChange') videoTimerState: boolean = false;
  @State @Watch('setTreasureBoxUncollapsAnimation') isTreasureBoxOpen: boolean = false;
  @State orientation: display.Orientation = display.Orientation.PORTRAIT;
  @State tabViewPosition: TabPosition = this.getTimeLapseTabPosition();
  @State modeBarScale: number = 1;
  @State modeBarOpacity: number = 1;
  @State footBarTrans: number = 0;
  @State footBarScale: number = 1;
  @State showTimer: boolean = false;
  @State timerOpacity: number = 0;
  @Prop immersiveOpacity: number = 1;
  @Prop immersiveUIType: UIOperationType = UIOperationType.NULL;
  @State treasureBoxOpacity: number = 1;
  @State showModeBar: boolean = true;
  @State isShowTreasureBox: boolean = true;
  @State isShowZoomView: boolean = true;
  @State isShowTextInfo: boolean = false;
  @State isShowLongExposureInfo: boolean = false;
  @State showZoomView: boolean = false;
  @State showParamBar: boolean = false;
  @State @Watch('lowBatteryExitFlashDialogShow') isFlashEnable: boolean = true;
  // 启动相关
  //温控弹窗
  private exitCameraDialogController: CustomDialogController | null = null;
  private session: UIExtensionContentSession | undefined = undefined;
  @State isShowExitFlash: boolean = false;
  @State isShowExitCamera: boolean = false;
  @State isLowBatteryTipShowed: boolean = false;
  @State isShowExposure: boolean = false;
  private mTimerId: number = Number.MIN_VALUE;
  private appRecoveryTimer: number = Number.MIN_VALUE;
  private openBoxTimer: number = Number.MIN_VALUE;
  // Picker 状态
  @State pickerWindowType: PickerWindowType = PickerWindowType.COLLAPSED_VERTICAL_FULL;
  @State isExpandedTopBottomSplitScreen: boolean = false;
  @State isCollapsedSplitScreen: boolean = false;
  @State isFullScreen: boolean = false;
  // Picker
  @State isPicker: boolean = true;
  @State @Watch('changePickerView') isShowPickerView: boolean = false;
  @State isShowLandscape: boolean = false;
  @State @Watch('changeHalfCollapsLEM') isHalfCollapsLEM: boolean = false;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @State isEditMorePage: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State isHighStabilizationValue: boolean = false;
  @StorageLink('treasureBoxSelector') selector: FunctionId = FunctionId.NONE;
  @State isShowtimeLapse: boolean = false;
  @LocalStorageLink('previewAnimatePosition') previewAnimatePosition: PositionType = { x: 0, y: 0 };
  @State isShowLemAnimate: boolean = false;
  private pinchGestureTimer: number = 0;
  private baseZoom: number = 0;
  private recoverFlash: boolean = false;
  private frontPinchCanUpdate: boolean = false;
  private readonly pinchToNextZoomScale = 1.25;
  private readonly pinchToPrevZoomScale = 0.75;
  private isSizeChange: boolean = false;
  private exitTimer: number = 5;
  private displayInfo: display.Display = DisplayService.getInstance().getDisplay();
  private isPreviousOrientationVertical: boolean = DisplayService.getInstance().isOrientationVertical();
  @State isPreviewFrameStart: boolean = true;
  @State @Watch('updateBigTextPosition') isShowBigText: boolean = false;
  @State isFloatingShutterShow: boolean = false;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  @State xComponentWidth: number = getStates().get<number>('previewReducer', 'xComponentWidth');
  @State xComponentHeight: number = getStates().get<number>('previewReducer', 'xComponentHeight');
  @State @Watch('filterIsShowParamBar') isShowParamBar: boolean = false;
  @State isShowParamBarAfterFiltering: boolean = false;
  @State isShowExtendBar: boolean = false;
  @State zoomState: string = '';
  @State cameraRunningState: CameraRunningState = CameraRunningState.UNINITIALIZED;
  @State treasureBoxCollapsState: boolean = false;
  @State isShowBlack: boolean = false;
  @State excludeComponent: string = UIOperationType.NULL;
  @State uiEnable: boolean = false;
  @State zoomRatio: number = 0;
  @State minZoomRatio: number = 0;
  @State maxZoomRatio: number = 0;
  @State isShowPinch: boolean = false;
  @State rootContainerRotateAngle: RotateOptions = { angle: 0 };
  @State rootContainerWidth: number = 0;
  @State rootContainerHeight: number = 0;
  @State isVdeLandscape: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State thumbnailViewArea: Area = {
    width: '',
    height: '',
    position: {},
    globalPosition: {}
  };
  @State footBarCustomFilterScale: number = 1;
  @State footBarOffsetX: number = 0;
  @State footBarOffsetY: number = 0;
  @LocalStorageLink('isBetweenBlurAnimDoneAndAnimEnd') isBetweenBlurAnimDoneAndAnimEnd: boolean = false;
  // 环形补光
  @State isShowRingLightView: boolean = false;
  @State isShowWhiteBack: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear begin.');
    this.setMEventBusOn();
    this.chooseToShowExtendBar();
    this.initState();
    this.uxInit();
    this.onChangeXComponentSize({ xComponentWidth: this.xComponentWidth, xComponentHeight: this.xComponentHeight });
    HiLog.i(TAG, 'aboutToAppear end.');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    this.closeDialogConfirm();
  }

  private initState(): void {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      // 所属类型 - windowReducer
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.pickerWindowType = state.get<PickerWindowType>('windowReducer', 'pickerWindowType');
      // 所属类型 - previewReducer
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
      // 所属类型 - contextReducer
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      // 所属类型 - modeReducer
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isEditMorePage = state.get<boolean>('modeReducer', 'isEditMorePage');
      this.isShowBigText = state.get<boolean>('modeReducer', 'isShowBigText');
      // 所属类型 - collapsReducer
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowBlack = state.get<boolean>('collapsReducer', 'isShowBlack');
      // 所属类型 - zoomReducer
      this.zoomRatio = state.get<number>('zoomReducer', 'zoomRatio');
      this.minZoomRatio = state.get<number>('zoomReducer', 'minZoomRatio');
      this.maxZoomRatio = state.get<number>('zoomReducer', 'maxZoomRatio');
      this.isShowPinch = state.get<boolean>('zoomReducer', 'isShowPinch');
      this.zoomState = state.get<string>('zoomReducer', 'zoomState');
      // 所属类型 - recordReducer
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.videoTimerState = state.get<boolean>('recordReducer', 'videoTimerState');
      // 所属类型 - uiReducer
      this.isShowPickerView = state.get<boolean>('uiReducer', 'showPicker');
      this.isShowParamBar = state.get<boolean>('uiReducer', 'isShowParamBar');
      this.isShowExtendBar = state.get<boolean>('uiReducer', 'isShowExtendBar');
      this.isFlashEnable = state.get<boolean>('uiReducer', 'isFlashEnable');
      // 所属类型 - treasureBoxReducer
      this.isTreasureBoxOpen = state.get<boolean>('treasureBoxReducer', 'isOpen');
      this.treasureBoxCollapsState = state.get<boolean>('treasureBoxReducer', 'isOpen');
      // 所属类型 - settingViewReducer
      this.isShowtimeLapse = state.get<boolean>('settingReducer', 'isShowtimeLapse');
      this.isFloatingShutterShow = state.get<boolean>('settingReducer', 'isFloatingShutterShow');
      // 所属类型 - cameraReducer
      this.cameraRunningState = state.get<CameraRunningState>('cameraReducer', 'cameraRunningState');
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isShowWhiteBack = state.get<boolean>('ringLightReducer', 'isShowWhiteBack');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
  }

  private setMEventBusOn(): void {
    this.mEventBus.on(ActionType.ACTION_CHANGE_X_COMPONENT_SIZE,
      (data: XComponentSize) => this.onChangeXComponentSize(data), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, () => this.onBackground(), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.ERROR, (data: CameraErrorData) => this.onCameraError(data),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_EXIT_FLASH_DIALOG, () => this.exitFlashDialogShow(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_EXIT_CAMERA_DIALOG, () => this.exitCameraDialogShow(),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, () => this.onAbilityBackground(), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, () => this.onAbilityForeground(), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL,
      (data: FunctionValueType) => this.handleFunctionValueChange(data), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CLOSE_SETTING_DIALOG, () => this.closeDialogConfirm(), this.mBase.hashCode());
    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.SWITCH_CAMERA_CHANGE_MODE],
      () => this.isShowComponentDisplay(), this.mBase.hashCode());
    this.mEventBus.on([WindowActionType.ON_SIZE_CHANGE, WindowActionType.CHANGE_TOP_AVOID_AREA], () => this.uxInit(),
      this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.REFRESH_UX, () => this.onRefreshUX(), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.UPDATE_SAVE_POWER_MODE_STATE, (data: SavePowerModeActionData) =>
    this.updateSavePowerModeState(data), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LONG_EXPOSURE_SHUTTER,
      () => this.isShowLongExposureCaptureInfo(true), this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_LONG_EXPOSURE_SHUTTER_END, CameraActionType.STARTED],
      () => this.isShowLongExposureCaptureInfo(false), this.mBase.hashCode());
    this.mEventBus.on([PreviewActionType.LOAD_SURFACE_DONE],
      () => this.checkXComponentLock(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_PREVIEW_FRAME_START, this.onPreviewFrameStart.bind(this),
      this.mBase.hashCode());
  }

  private closeDialogConfirm(): void {
    this.exitCameraDialogController?.close();
    this.isShowExposure = false;
    this.isShowExitFlash = false;
    this.isShowExitCamera = false;
    this.isLowBatteryTipShowed = false;
  }

  private isShowComponentDisplay(): void {
    this.showZoomView = true;
    this.showParamBar = true;
  }

  private changePickerView(): void {
    if (this.isShowPickerView) {
      AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.THIRDPARTYCALL_REMAKE_1);
    } else {
      AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.PREVIEW_WINDOW_1);
    }
  }

  private changeHalfCollapsLEM(): void {
    this.isShowLemAnimate = true;
    setTimeout((): void => {
      this.isShowLemAnimate = false;
    }, 400)
    this.isSizeChange = false;
    this.mAction.closeTreasureBox();
    if (this.isHalfCollapsLEM) {
      this.modeBarOpacity = 1;
      this.modeBarScale = 1;
      // 展开treasureBox会走disappear, 概率导致closeTreasure不生效, 外屏展开场景做延迟处理
      if (AppStorage.get('isLemCollaps2HalfCollaps')) {
        this.initOpenBoxTimer();
      } else {
        this.mAction.openTreasureBox();
      }
      this.selector = FunctionId.NONE;
    }
  }

  private chooseToShowExtendBar(): void {
    let isExtendBarContinuation = getStates().get<boolean>('uiReducer', 'isExtendBarContinuation');
    let extendBarEffectView = getStates().get<FunctionId>('uiReducer', 'extendBarEffectView');
    if (isExtendBarContinuation) {
      this.mAction.showExtendBar(extendBarEffectView);
    }
  }

  private initOpenBoxTimer() {
    this.openBoxTimer = setTimeout((): void => {
      HiLog.i(TAG, 'openBoxTimer');
      if (AppStorage.get('isLemCollaps2Expand')) {
        HiLog.i(TAG, 'clearTimeout openBoxTimer');
        clearTimeout(this.openBoxTimer);
        return;
      }
      this.mAction.openTreasureBox();
    }, 300);
  }

  private onCameraError(data: CameraErrorData): void {
    if (!AppStorage.get<boolean>('isBackground')) {
      HiLog.i(TAG, `onCameraError errorCode : ${data.code} errorMsg : ${data.msg}`);
      this.appRecoveryTimer = setTimeout((): void => {
        HiLog.i(TAG, 'cameraError restartApp');
        appRecovery.restartApp();
        clearTimeout(this.appRecoveryTimer);
      }, 6000);
    }
  }

  private getRotate(): number {
    HiLog.i(TAG, `mDirection : ${this.mDirection} `);
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

  private terminateCamera(): void {
    HiLog.i(TAG, 'terminateCamera');
    if (this.session) {
      this.session?.sendData({ 'cameraDown': true });
    } else {
      ContextManager.getInstance().getUiContext().terminateSelf().then(() => {
        HiLog.i(TAG, 'terminateSelf success');
      });
    }
  }

  private createExitCameraDialog(): void {
    HiLog.i(TAG, 'createExitLocationDialog');
    this.exitCameraDialogController = new CustomDialogController({
      builder: AlertDialogView({
        confirm: () => {
          this.exitCameraDialogController?.close();
          this.isShowExitCamera = false;
          this.terminateCamera();
        },
        title: $r('app.string.device_hot_exit_tips', this.exitTimer),
        confirmText: $r('app.string.dialog_comform_exit_new'),
      }),
      autoCancel: false,
      customStyle: true,
      maskColor: $r('sys.color.mask_fourth'),
      alignment: DialogAlignment.Center,
    });
  }

  private isVertical(): boolean {
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  private exitFlashDialogShow(): void {
    TipService.getInstance().showTip($r('app.string.device_hot_flash_off_tips'), 3000, true);
    this.isShowExitFlash = true;
    this.mAction.changeFunctionValue(FunctionId.FLASH, FlashMode.OFF);
  }

  private exitCameraDialogShow(): void {
    if (this.isShowExitCamera) {
      return;
    }
    this.createExitCameraDialog();
    this.exitCameraDialogController?.open();
    this.isShowExitCamera = true;
    this.mTimerId = setTimeout((): void => {
      this.terminateCamera();
    }, 5000);
  }

  private lowBatteryExitFlashDialogShow(): void {
    HiLog.i(TAG, 'isFlashEnable ==' + this.isFlashEnable);
    if (!this.isFlashEnable) {
      PreferencesService.getInstance().putPublicValue(PersistType.FOREVER, PublicTag.FLASH_STATE,
        FeatureManager.getInstance().getFunction(FunctionId.FLASH).getValue() as number);
      this.recoverFlash = true;
    }
    if (this.isFlashEnable) {
      if (this.recoverFlash) {
        PreferencesService.getInstance().putPublicValue(PersistType.FOREVER, PublicTag.FLASH_STATE,
          FeatureManager.getInstance().getFunction(FunctionId.FLASH).getValue() as number);
      }
      return;
    }
    this.mAction.changeFunctionValue(FunctionId.FLASH, FlashMode.OFF);
    this.isLowBatteryTipShowed = PreferencesService.getInstance().getPublicValue(PersistType.FOREVER,
      PublicTag.IS_LOW_BATTERY_TIP_OPENED, false) as boolean;
    HiLog.i(TAG, 'this.isShowLowBatteryExitFlash ==' + this.isLowBatteryTipShowed);
    if (this.isLowBatteryTipShowed) {
      return;
    }
    TipService.getInstance().showTip('电量过低，无法使用闪光灯', 3000, true);
    this.isLowBatteryTipShowed = true;
    PreferencesService.getInstance().putPublicValue(PersistType.FOREVER, PublicTag.IS_LOW_BATTERY_TIP_OPENED, true);
  }

  private directionChange(): void {
    this.reOpenExitFlashDialog();
    this.tabViewPosition = this.getTimeLapseTabPosition();
  }

  private reOpenExitFlashDialog(): void {
    HiLog.i(TAG, 'reOpenExitFlashDialog' + this.mDirection + this.isShowExitFlash);
    if (this.mDirection === WindowDirection.BOTTOM || !this.isShowExitFlash) {
      return;
    }
    this.isShowExitFlash = false;
    TipService.getInstance().showTip($r('app.string.device_hot_flash_off_tips'), 3000, true);
  }

  private clearDialogTimerId(): void {
    if (this.mTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.mTimerId);
      this.mTimerId = Number.MIN_VALUE;
    }
  }

  private onBackground(): void {
    HiLog.i(TAG, 'onBackground.');
    this.exitCameraDialogController?.close();
    this.showTimer = false;
    this.isShowExitFlash = false;
    this.isShowExitCamera = false;
    this.isLowBatteryTipShowed = false;
    this.clearDialogTimerId();
    if (this.appRecoveryTimer !== Number.MIN_VALUE) {
      clearTimeout(this.appRecoveryTimer);
      this.appRecoveryTimer = Number.MIN_VALUE;
    }
  }

  private updateSavePowerModeState(data: SavePowerModeActionData) {
    HiLog.i(TAG, `Save power mode state: ${data.isDuringSavePowerMode}`);
    if (data.isDuringSavePowerMode) {
      this.exitCameraDialogController?.close();
      this.isShowExposure = false;
      this.isShowExitFlash = false;
      this.isShowExitCamera = false;
      this.isLowBatteryTipShowed = false;
    }
  }

  private updateFullScreenUI(): void {
    HiLog.i(TAG, `uxInit Full Screen`);
    this.previewPosition.y = this.layoutService.previewPosition;
    this.footBarPosition = this.layoutService.footBarPosition;
    this.rouletteZoomPosition = this.layoutService.rouletteZoomPosition;
    this.modeBarPosition = this.layoutService.modeBarPosition;
    this.arrowPosition = this.layoutService.arrowPosition;
    this.tabBarPosition = this.layoutService.tabBarPosition;
    this.compoMargin = this.layoutService.compoMargin;
    this.extendBarPosition = this.modeBarPosition - EXTEND_BAR_HEIGHT;
    HiLog.i(TAG, `full previewPosition ${this.previewPosition} tabbar ${this.tabBarPosition}`);
  }

  private updateFloatingWindowUI(): void {
    HiLog.i(TAG, `uxInit floating window`);
    this.previewPosition.y = this.layoutService.previewPosition;
    this.footBarPosition = this.layoutService.footBarPosition;
    this.rouletteZoomPosition = this.layoutService.rouletteZoomPosition;
    this.modeBarPosition = this.layoutService.modeBarPosition;
    this.arrowPosition = this.layoutService.arrowPosition;
    if (this.windowHeight / this.windowWidth < AnimSpecifications.NEW_FLOAT_WINDOW_RATIO) {
      this.tabBarPosition = AnimSpecifications.NEW_FLOAT_WINDOW_TOP_OFFSET; // 悬浮态tabBar上边距
    } else {
      this.tabBarPosition = this.layoutService.tabBarPosition;
    }
    this.compoMargin = this.layoutService.compoMargin;
    this.extendBarPosition = this.modeBarPosition - EXTEND_BAR_HEIGHT;
    HiLog.i(TAG, `floating previewPosition ${this.previewPosition} tabbar ${this.tabBarPosition}`);
  }

  private updateExpandedLRSplitScreenUI(): void {
    HiLog.i(TAG, `uxInit expanded left right split screen`);
    this.previewPosition.y = this.layoutService.previewPosition;
    this.footBarPosition = this.layoutService.footBarPosition;
    this.rouletteZoomPosition = this.layoutService.rouletteZoomPosition;
    this.zoomPosition = this.layoutService.zoomPosition;
    this.rouletteZoomPosition = (this.rouletteZoomPosition + 80 >= this.modeBarPosition) ? this.zoomPosition :
    this.rouletteZoomPosition;
    this.modeBarPosition = this.layoutService.modeBarPosition;
    this.arrowPosition = this.layoutService.arrowPosition;
    this.tabBarPosition = this.layoutService.tabBarPosition;
    this.compoMargin = this.layoutService.compoMargin;
    this.extendBarPosition = this.modeBarPosition - EXTEND_BAR_HEIGHT;
    HiLog.i(TAG,
      `expanded lr previewPosition ${this.previewPosition} roulettezoomposition ${this.rouletteZoomPosition}`)
  }

  private updateTwoThirdsHeightUI(): void {
    HiLog.i(TAG, `uxInit 2/3 screen`);
    const basePosition = Math.max((this.windowHeight - this.windowWidth * 4 / 3) >> 1, 0);
    this.previewPosition.y = (this.windowHeight - this.xComponentHeight) >> 1;
    this.tabBarPosition = basePosition + 26;
    this.arrowPosition = this.layoutService.arrowPosition;
    this.footBarPosition = this.arrowPosition - 12 - FOOT_BAR_HEIGHT;
    this.modeBarPosition = this.footBarPosition - 12 - MODE_BAR_HEIGHT;
    this.rouletteZoomPosition = this.modeBarPosition - SPLIT_SCREEN_ZOOM_HEIGHT;
    this.compoMargin = this.layoutService.compoMargin;
    this.extendBarPosition = this.modeBarPosition - EXTEND_BAR_HEIGHT;
  }

  private updateOneHalfHeightUI(): void {
    HiLog.i(TAG, `uxInit 1/2 screen`);
    this.previewPosition.y = Math.min(0, (this.windowHeight - this.xComponentHeight) >> 1);
    this.tabBarPosition = 44;
    this.arrowPosition = this.layoutService.arrowPosition;
    this.footBarPosition = this.arrowPosition - 12 - FOOT_BAR_HEIGHT;
    this.modeBarPosition = this.footBarPosition - 12 - MODE_BAR_HEIGHT;
    this.isShowZoomView = false;
    this.compoMargin = this.layoutService.compoMargin;
    this.mAction.updateIsShowParamBar(false);
  }

  private updateHorizontalOneHalfUI(): void {
    HiLog.i(TAG, `uxInit horizontal 1/2 screen`);
    this.previewPosition.y = Math.min(0, (this.windowHeight - this.xComponentHeight) >> 1);
    this.tabBarPosition = 32;
    this.isShowTreasureBox = false;
    this.footBarPosition = this.windowHeight - 18 - FOOT_BAR_HEIGHT;
    this.modeBarPosition = this.footBarPosition - MODE_BAR_HEIGHT;
    this.rouletteZoomPosition = this.modeBarPosition - SPLIT_SCREEN_ZOOM_HEIGHT;
    this.extendBarPosition = this.footBarPosition - EXTEND_BAR_HEIGHT;
  }

  private updateOneThirdHeightUI(): void {
    HiLog.i(TAG, `uxInit 1/3 screen`);
    this.previewPosition.y = 0;
    this.tabBarPosition = 44;
    this.footBarPosition = this.windowHeight - 18 - FOOT_BAR_HEIGHT;
    this.isShowTreasureBox = false;
    this.showModeBar = false;
    this.isShowZoomView = false;
    this.mAction.updateIsShowParamBar(false);
  }

  private updateExpandedTopBottomSplitScreenUI(): void {
    HiLog.i(TAG, `uxInit top bottom split screen`);
    this.previewPosition.y = this.layoutService.previewPosition;
    this.footBarPosition = this.layoutService.footBarPosition;
    this.updateRouletteZoomPosition();
    this.modeBarPosition = this.layoutService.modeBarPosition;
    this.arrowPosition = this.layoutService.arrowPosition;
    this.tabBarPosition = this.layoutService.tabBarPosition;
    this.compoMargin = this.layoutService.compoMargin;
    this.extendBarPosition = this.modeBarPosition - EXTEND_BAR_HEIGHT;
    HiLog.i(TAG, `zoom position is changed to ${this.rouletteZoomPosition}`);
  }

  private recoverAllUIComponents(): void {
    HiLog.i(TAG, 'Recover All UI Components.');
    if (this.videoState === RecordingState.READY || this.videoState === RecordingState.STOPPING) {
      this.isShowTreasureBox = true;
      this.showModeBar = true;
      this.mAction.closeExtendBar();
      this.modeBarScale = 1;
      if (!this.isHalfCollapsLEM) {
        this.mAction.closeTreasureBox();
      }
      this.modeBarOpacity = 1;
    }
    this.isShowZoomView = true;
    this.footBarTrans = 0;
    this.footBarScale = 1;
  }

  private updatePickerStates(): void {
    this.isExpandedTopBottomSplitScreen = PickerUtils.getIsExpandedTopBottomSplitScreen();
  }

  private onRefreshUX(): void {
    this.isPreviousOrientationVertical = DisplayService.getInstance().isOrientationVertical();
  }

  private uxInit(): void {
    this.orientation = this.displayInfo.orientation;
    HiLog.i(TAG, `uxInit begin, window size width: ${this.windowWidth}, height: ${this.windowHeight}.`);
    HiLog.i(TAG, `uxInit xComponentWidth ${this.xComponentWidth}, uxInit xComponentHeight ${this.xComponentHeight}`);
    this.updatePickerStates();
    this.recoverAllUIComponents();
    this.layoutService.calLayoutRuleParam(Math.min(this.windowWidth, this.windowHeight),
      Math.max(this.windowWidth, this.windowHeight));
    this.layoutService.changePreviewPosition(this.xComponentWidth, this.xComponentHeight);
    this.updatePickerUIByWindowType();
    this.updateRootContainerSize();
    this.updateRouletteZoomPosition();
    HiLog.i(TAG, `uxInit tabbarposition ${this.tabBarPosition}`);
  }

  private updatePickerUIByWindowType(): void {
    switch (this.pickerWindowType) {
      case PickerWindowType.COLLAPSED_VERTICAL_FULL:
      case PickerWindowType.COLLAPSED_HORIZONTAL_FULL:
        this.updateFullScreenUI();
        this.isFullScreen = true;
        break;
      case PickerWindowType.COLLAPSED_1_3_SPLIT_SCREEN:
        this.updateOneThirdHeightUI();
        this.isFullScreen = false;
        break;
      case PickerWindowType.COLLAPSED_VERTICAL_1_2_SPLIT_SCREEN:
        this.updateOneHalfHeightUI();
        this.isFullScreen = false;
        break;
      case PickerWindowType.COLLAPSED_HORIZONTAL_1_2_SPLIT_SCREEN:
        this.updateHorizontalOneHalfUI();
        this.isFullScreen = false;
        break;
      case PickerWindowType.COLLAPSED_2_3_SPLIT_SCREEN:
        this.updateTwoThirdsHeightUI();
        this.isFullScreen = false;
        break;
      case PickerWindowType.EXPANDED_LEFT_RIGHT_SPLIT_SCREEN:
        this.updateExpandedLRSplitScreenUI();
        this.isFullScreen = true;
        break;
      case PickerWindowType.EXPANDED_TOP_BOTTOM_SPLIT_SCREEN:
        this.updateExpandedTopBottomSplitScreenUI();
        this.isFullScreen = true;
        break;
      case PickerWindowType.PHONE_IN_FLOATING:
        this.updateFloatingWindowUI();
        this.isFullScreen = true;
        break;
      default:
        this.updateFullScreenUI();
        this.isFullScreen = true;
        break;
    }
    this.updateBigTextPosition();
    if (this.videoState !== RecordingState.READY && this.videoState !== RecordingState.STOPPING) {
      this.zoomTranslate = this.footBarPosition - this.getZoomViewHeight() - 12 - this.rouletteZoomPosition;
    }
    PickerUtils.currentTabBarPosition = this.tabBarPosition;
  }

  private updateRootContainerSize(): void {
    this.rootContainerWidth = this.windowWidth;
    this.rootContainerHeight = this.windowHeight;
    this.rootContainerRotateAngle = this.getRotateOptions();
  }

  private onChangeXComponentSize(data: XComponentSize): void {
    HiLog.i(TAG, `onChangeXComponentSize E, data: ${JSON.stringify(data)}.`);
    if (!this.isFullScreen) {
      return;
    }
    if (this.rouletteZoomPosition === 0) {
      this.isNeedPlayZoomTransAnim = false;
      this.isNeedPlayParamBarTransAnim = false;
    }
    this.updateRouletteZoomPosition();
    HiLog.i(TAG, `onChangeXComponentSize X, zoomPosition: ${this.rouletteZoomPosition}`);
  }

  private updateRouletteZoomPosition(): void {
    const roulettePos: number = this.layoutService.rouletteZoomPosition;
    this.zoomPosition = this.layoutService.zoomPosition;
    this.rouletteZoomPosition = (roulettePos + this.getZoomViewHeight() >= this.modeBarPosition) ?
      this.modeBarPosition - this.getZoomViewHeight() : roulettePos;
    const previewBottomLinePosition: number = this.previewAnimatePosition.y + this.xComponentHeight;
    const zoomBottomLinePosition: number = this.rouletteZoomPosition + this.getZoomViewHeight();
    if (this.rouletteZoomPosition < previewBottomLinePosition && previewBottomLinePosition < zoomBottomLinePosition) {
      this.rouletteZoomPosition = previewBottomLinePosition - this.getZoomViewHeight();
    }
  }

  private handleFunctionValueChange(data: FunctionValueType) {
    if (data.id === FunctionId.FRAME_RATE || data.id === FunctionId.VIDEO_RESOLUTION || data.id === FunctionId.FLASH) {
    }
  }

  private videoStateOnChange(): void {
    HiLog.i(TAG, `videoStateOnChange videoState:${this.videoState}.`);
    if (this.videoState === RecordingState.STARTING) {
      if (this.treasureBoxCollapsState) {
        this.modeBarOpacity = 0;
      } else {
        this.treasureBoxOpacity = 1;
        this.modeBarOpacity = 1;
      }
      this.recordStartAnim();
      if (!this.isHalfCollapsLEM) {
        this.mAction.closeTreasureBox();
      }
    } else if (this.videoState === RecordingState.STOPPING) {
      this.recordEndAnim();
      this.mAction.updateIsShowParamBar(true);
    }
  }

  private recordStartAnim(): void {
    this.zoomTranslate = 0;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_VIDEO_START_TRANSLATE_DURATION,
      delay: AnimSpecifications.ANIM_VIDEO_START_TRANSLATE_DURATION,
      curve: Curve.Sharp,
      onFinish: () => {
        this.showModeBar = false;
      }
    }, () => {
      this.treasureBoxOpacity = 0;
      this.modeBarOpacity = 0;
      this.zoomTranslate = this.footBarPosition - this.getZoomViewHeight() - 12 - this.rouletteZoomPosition;
    });
  }

  private recordEndAnim(): void {
    this.treasureBoxOpacity = 0;
    this.modeBarOpacity = 0;
    this.showModeBar = this.pickerWindowType === PickerWindowType.COLLAPSED_1_3_SPLIT_SCREEN ? false : true;
    this.zoomTranslate = this.footBarPosition - this.getZoomViewHeight() - 12 - this.rouletteZoomPosition;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_VIDEO_START_TRANSLATE_DURATION,
      delay: AnimSpecifications.ANIM_VIDEO_START_TRANSLATE_DURATION,
      curve: Curve.Sharp,
      onFinish: () => {
        this.showModeBar = this.pickerWindowType === PickerWindowType.COLLAPSED_1_3_SPLIT_SCREEN ? false : true;
      }
    }, () => {
      this.treasureBoxOpacity = 1;
      this.modeBarOpacity = 1;
      this.zoomTranslate = 0;
    });
  }

  private closeIntroductoryText(): void {
    this.isShowTextInfo = true;
    if (this.isHalfCollapsLEM) {
      setTimeout((): void => {
        this.mAction.openTreasureBox();
      }, 200);
    }
  }

  private isShowLongExposureCaptureInfo(showLongExposureInfo: boolean): void {
    HiLog.i(TAG, 'isShowLongExposureInfo: ' + showLongExposureInfo);
    this.isShowLongExposureInfo = showLongExposureInfo;
  }

  private onAbilityBackground(): void {
    HiLog.i(TAG, 'onAbilityBackground');
  }

  private onAbilityForeground(): void {
    HiLog.i(TAG, 'onAbilityForeground');
    if (this.isHalfCollapsLEM && !this.isTreasureBoxOpen) {
      this.mAction.openTreasureBox();
    }
  }

  private timeLapse(data: ShowParm): void {
    this.showModeBar = data.showModeBar;
  }

  private getTimeLapseTabPosition(): TabPosition {
    HiLog.i(TAG, `getTimeLapseTabPosition : ${this.isTreasureBoxOpen}.`);
    if (this.mDirection === WindowDirection.RIGHT) {
      return {
        y: this.isTreasureBoxOpen ? this.layoutService.footBarPosition - this.xComponentWidth - 20 :
          this.layoutService.footBarPosition - this.xComponentWidth + MODE_BAR_HEIGHT - 10,
        x: this.xComponentWidth / 2 - 30
      }

    } else if (this.mDirection === WindowDirection.LEFT) {
      return {
        y: this.isTreasureBoxOpen ? this.layoutService.footBarPosition - this.xComponentWidth - 20 :
          this.layoutService.footBarPosition - this.xComponentWidth + MODE_BAR_HEIGHT - 10,
        x: -this.xComponentWidth / 2 + 30
      }
    }
    return {
      y: TAB_BAR_HEIGHT + 17,
      x: 0
    }
  }

  private setTreasureBoxUncollapsAnimation() {
    this.tabViewPosition = this.getTimeLapseTabPosition();
  }

  private timerStateOnChange(): void {
    HiLog.i(TAG, `timerStateOnChange videoTimerState: ${this.videoTimerState}.`);
    this.timerOpacity = this.videoTimerState ? 0 : 1;
    this.showTimer = true;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_VIDEO_START_DURATION,
      curve: Curve.Sharp,
      onFinish: () => {
        this.showTimer = this.videoTimerState;
      }
    }, () => {
      this.timerOpacity = this.videoTimerState ? 1 : 0;
    });
  }

  private getZoomVisible(): number {
    if (this.isVdeCollapsed) {
      return Visibility.Hidden;
    }
    if (!this.isShowZoomView) {
      return Visibility.Hidden;
    }

    // 非变焦组件引起的沉浸式模式
    if (this.immersiveUIType !== UIOperationType.ZOOM_BAR && this.immersiveOpacity === 0) {
      return Visibility.Hidden;
    }

    // ExtendBar展示
    if (this.isShowExtendBar) {
      return Visibility.Hidden;
    }
    // 切模式启流成功后更改zoomView显示判断
    if (this.cameraRunningState === CameraRunningState.STARTED && this.showZoomView) {
      this.showZoomView = false;
    }

    // 非手机的前置
    if (this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT && !DeviceInfo.isPhone()) {
      return Visibility.Hidden;
    }
    // 只有一个变焦点
    if (ZoomOperation.getRingZoomUIState(this.cameraPosition, this.mode)?.opticalZoomValArr.length <= 1) {
      return Visibility.Hidden;
    }
    return Visibility.Visible;
  }

  private getParamVisible(): number {
    if (this.zoomState !== ZoomStateType.QUICK_ZOOM) {
      return Visibility.Hidden;
    }
    if (this.isLemCollaps) {
      return Visibility.Hidden;
    }
    if (this.immersiveOpacity === 0) {
      return Visibility.Hidden;
    }

    // 切模式或者切前后置相机启动未完成
    if (this.cameraRunningState !== CameraRunningState.STARTED && this.showParamBar) {
      return Visibility.Hidden;
    }

    // 切模式启流成功后更改ParamBar显示判断
    if (this.cameraRunningState === CameraRunningState.STARTED && this.showParamBar) {
      this.showParamBar = false;
    }

    return Visibility.Visible;
  }

  private getTabBarVisible(): Visibility {
    return this.immersiveOpacity !== 0 && !this.isLemCollaps && !this.isHalfCollapsLEM && !this.isVdeCollapsed ?
    Visibility.Visible : Visibility.Hidden;
  }

  private onPreviewFrameStart(data: PreviewFrameStartData): void {
    this.isPreviewFrameStart = data.isPreviewFrameStart;
  }

  private getPanoramaBarVisible(): boolean {
    // 切模式或者切前后置相机启动未完成
    if (this.cameraRunningState !== CameraRunningState.STARTED) {
      return false;
    }
    if (this.isShowBigText && this.videoState === RecordingState.READY) {
      return false;
    }
    if (!this.isPreviewFrameStart) {
      return false;
    }
    return true;
  }

  private isVerticalAndVideoRecording(): boolean {
    return this.mode === ModeType.VIDEO && this.isVertical() && this.videoState !== RecordingState.READY;
  }

  private getBigTextPosition(): PositionType {
    let bigTextLineHeight: number = 64;
    let marginBottom1to1PreviewArea: number = 80;
    let marginBottomHalfCollapsPreviewArea: number = 180;
    if (this.isVerticalAndVideoRecording() || PickerUtils.getIsExpandedHorizontalPreviewSize()) {
      let positionY: number = this.layoutService.previewPosition16to9 +
        this.layoutService.get16to9PreviewHeight(this.windowWidth, this.windowHeight) / 2 - bigTextLineHeight / 2;
      return { x: 0, y: positionY };
    }
    if (this.mDirection !== WindowDirection.RIGHT && this.mDirection !== WindowDirection.LEFT) {
      let positionY: number = this.layoutService.previewPosition1to1 + this.xComponentWidth -
        marginBottom1to1PreviewArea - bigTextLineHeight;
      if (this.isHalfCollapsLEM) {
        positionY = this.layoutService.previewPosition1to1 + this.xComponentWidth -
          marginBottomHalfCollapsPreviewArea - bigTextLineHeight;
      }
      return { x: 0, y: positionY };
    } else {
      let positionY: number = this.layoutService.previewPosition4to3 + this.layoutService.preview4to3Height / 2 -
        bigTextLineHeight / 2;
      if (this.isHalfCollapsLEM) {
        positionY = positionY - 40;
      }
      return { x: 0, y: positionY };
    }
  }

  private onModeChange(): void {
    this.lowBatteryExitFlashDialogShow();
  }

  private getStackOffsetX(): number {
    return 0;
  }

  build() {
    Stack({ alignContent: (this.isLemCollaps ? Alignment.Center : Alignment.Top) }) {
      this.PreviewGestureBuilder();
      this.bigTextBuilder();
      this.tabBarBuilder();
      this.videoTimerBuilder();
      this.paramBarBuilder();
      this.zoomBarBuilder();
      this.modeBarBuilder();
      this.footBarBuilder();
      this.treasureBoxBuilder();
      this.TipBoxBuilder();
      this.floatingShutterBuilder();
      this.pickerViewBuilder();
      this.captureShowBlackBuilder();
      this.zoomTextChangeBuilder();
    }
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .width(this.isLemCollaps ? 226 : '100%')
    .height(this.isLemCollaps ? 226 : '100%')
    .onClick((): void => {
      if (this.isHalfCollapsLEM) {
        if (this.selector !== FunctionId.NONE) {
          this.selector = FunctionId.NONE;
        }
        if (this.isShowExtendBar) {
          this.mAction.closeExtendBar();
        }
      }
    })
    .rotate(this.rootContainerRotateAngle)
    .offset({ x: this.getStackOffsetX() })
  }

  private isOrientationVertical(): boolean {
    return this.orientation === display.Orientation.PORTRAIT ||
      this.orientation === display.Orientation.PORTRAIT_INVERTED;
  }

  private getRotateOptions(): RotateOptions {
    const rotateZero: RotateOptions = { angle: 0 };
    if (this.isVdeCollapsed) {
      return rotateZero;
    }
    const baseRotateOptions: RotateOptions =
      {
        angle: -90,
        centerX: this.windowWidth / 2,
        centerY: this.windowWidth / 2
      };
    if (this.isExpandedTopBottomSplitScreen) {
      return baseRotateOptions;
    }
    return this.isOrientationVertical() || !this.isFullScreen || PickerUtils.getIsExpandedLeftRightSplitScreen() ?
      rotateZero : baseRotateOptions;
  }

  private getTabBarPosition(): Position {
    return { y: this.tabBarPosition };
  }

  private getModeBarPosition(): Position {
    if (this.isVdeCollapsed) {
      return { y: this.modeBarPosition + 12 };
    }
    return { y: this.isHalfCollapsLEM ? this.modeBarPosition + 52 : this.modeBarPosition };
  }

  private getFootBarPosition(): Position {
    if (this.isHalfCollapsLEM) {
      return { y: (this.footBarPosition + 45) };
    }
    if (this.isVdeLandscape) {
      return { y: (this.footBarPosition - 5) };
    }
    return { y: this.footBarPosition };
  }

  private getFootBarTrans(): TranslateOptions {
    return { y: this.footBarTrans };
  }

  private getTreasureBoxPosition(): Position {
    if (this.isHalfCollapsLEM) {
      return { y: this.windowHeight / 2 - 8 };
    }
    if (this.isVdeCollapsed) {
      return { y: 0 };
    }
    return { y: this.arrowPosition };
  }

  private getRouletteZoomViewWidth(): number {
    return this.windowWidth;
  }

  private getZoomViewHeight(): number {
    return this.isFullScreen ? ZOOM_VIEW_HEIGHT : 64;
  }

  private getZoomViewAnimation(): AnimateParam | undefined {
    if (!this.isFullScreen) {
      return undefined;
    }
    if (!this.isNeedPlayZoomTransAnim) {
      this.isNeedPlayZoomTransAnim = true;
      return undefined;
    }
    const delay: number = 200;
    return {
      duration: 200,
      delay: this.isBetweenBlurAnimDoneAndAnimEnd ? 0 : delay,
      curve: Curve.Friction,
      iterations: this.getZoomVisible() === Visibility.Hidden ? 0 : 1,
      playMode: PlayMode.Normal
    }
  }

  private getModeBarVisibility(): Visibility {
    if (this.isVdeCollapsed && !this.showModeBar) {
      return Visibility.Hidden;
    }
    return !this.isEditMorePage && (this.immersiveUIType === UIOperationType.MODE_BAR || this.immersiveOpacity !== 0) &&
    this.showModeBar && !this.isLemCollaps ? Visibility.Visible : Visibility.Hidden;
  }

  private filterIsShowParamBar(): void {
    if (this.pickerWindowType === PickerWindowType.COLLAPSED_VERTICAL_1_2_SPLIT_SCREEN ||
      this.pickerWindowType === PickerWindowType.COLLAPSED_1_3_SPLIT_SCREEN) {
      this.isShowParamBarAfterFiltering = false;
      this.mAction.updateIsShowParamBar(false);
    } else {
      this.isShowParamBarAfterFiltering = this.isShowParamBar;
    }
  }

  @Builder
  PreviewGestureBuilder() {
    PreviewGestureArea({
      immersiveUIType: this.immersiveUIType
    })
      .width(this.xComponentWidth)
      .height(this.xComponentHeight)
      .position(this.previewAnimatePosition)
      .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  bigTextBuilder(): void {
    if (this.isShowBigText) {
      Stack({ alignContent: Alignment.Top }) {
        BigText()
      }
      .width(this.windowWidth)
      .position(this.bigTextPosition)
      .zIndex(ZIndex.TOP)
      .accessibilityLevel(this.isShowPickerView ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
      CommonConstants.ACCESSIBILITY_LEVEL_AUTO)
    }
  }

  @Builder
  tabBarBuilder(): void {
    Column() {
      TabBar()
    }
    .width(this.windowWidth)
    .height(TAB_BAR_HEIGHT)
    .opacity(this.immersiveOpacity)
    .justifyContent(FlexAlign.Center)
    .position(this.getTabBarPosition())
    .zIndex(ZIndex.TOP)
    .visibility(this.getTabBarVisible())
    .accessibilityLevel(this.isShowPickerView ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
    CommonConstants.ACCESSIBILITY_LEVEL_AUTO)
  }

  @Builder
  videoTimerBuilder(): void {
    if (this.showTimer) { //超慢不展示录制时间
      VideoTimer({ pickerSplitScreenTabBarPosition: this.tabBarPosition })
        .position({ x: 0, y: 0 })
        .opacity(this.timerOpacity)
        .hitTestBehavior(HitTestMode.None)
        .accessibilityLevel(this.isShowPickerView ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
        CommonConstants.ACCESSIBILITY_LEVEL_AUTO)
    }
  }

  @Builder
  paramBarBuilder(): void {
    // 在开启屏幕朗读的时候 半折态 专业模式不需要此组件 此组件会遮挡专业模式下组件的聚焦
    if (this.isShowParamBarAfterFiltering && !(this.enableScreenReader && this.isHalfCollapsLEM)) {
      ParamBar({ isPicker: this.isPicker })
        .height(this.getZoomViewHeight())
        .offset({
          y: this.isHalfCollapsLEM ? this.zoomPosition + 58 : this.rouletteZoomPosition
        })
        .animation(this.getZoomViewAnimation())
        .opacity(this.immersiveUIType === UIOperationType.PARAM_BAR ? 1 : this.immersiveOpacity)
        .translate({ y: this.zoomTranslate })
        .hitTestBehavior(HitTestMode.Transparent)
        .visibility(this.getParamVisible())
        .zIndex(this.isHalfCollapsLEM ? 2 : 0)
        .width('100%')
        .accessibilityLevel(this.isShowPickerView ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
        CommonConstants.ACCESSIBILITY_LEVEL_AUTO)
    }
  }

  @Builder
  zoomBarBuilder(): void {
    RouletteZoomView({
      zoomWidth: this.getRouletteZoomViewWidth(),
      zoomHeight: 150,
      drawHeight: AdaptiveLayoutService.getInstance().preview4to3Height * 0.16
    })
      .height(this.getZoomViewHeight())
      .position(this.getZoomPosition())
      .animation(this.getZoomViewAnimation())
      .translate({ y: this.isLemCollaps ? 0 : this.zoomTranslate })
      .opacity(this.immersiveUIType === UIOperationType.ZOOM_BAR ? 1 : this.immersiveOpacity)
      .hitTestBehavior(HitTestMode.Transparent)
      .visibility(this.getZoomVisible())
      .zIndex(this.isHalfCollapsLEM ? 2 : 0)
      .accessibilityLevel(this.isShowPickerView ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
      CommonConstants.ACCESSIBILITY_LEVEL_AUTO)
  }

  @Builder
  modeBarBuilder(): void {
    ModeBar({ isPicker: this.isPicker })
      .width(this.windowWidth)
      .height(MODE_BAR_HEIGHT)
      .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
      .hitTestBehavior(this.isHalfCollapsLEM ? HitTestMode.Transparent : HitTestMode.Default)
      .scale({ x: this.modeBarScale, y: this.modeBarScale })
      .opacity(this.modeBarOpacity)
      .visibility(this.getModeBarVisibility())
      .position(this.getModeBarPosition())
      .animation(this.isShowLemAnimate ? this.getLemAnimateParam() : { delay: 50, duration: 350, iterations: 1 })
      .accessibilityLevel(this.isShowPickerView ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
      CommonConstants.ACCESSIBILITY_LEVEL_AUTO)
  }

  @Builder
  footBarBuilder(): void {
    Stack() {
      FootBar({
        isPicker: this.isPicker,
        footBarScale: this.footBarScale,
        thumbnailViewArea: this.thumbnailViewArea,
        offsetX: this.footBarOffsetX,
        offsetY: this.footBarOffsetY
      })
        .margin({ left: $r('sys.float.padding_level10'), right: $r('sys.float.padding_level10') })
        .zIndex(ZIndex.TOP)
        .hitTestBehavior(HitTestMode.None)

      if (!this.isHalfCollapsLEM && !this.isVdeCollapsed) {
        TreasureBoxGestureGround()
      }
    }
    .width(this.windowWidth)
    .height(FOOT_BAR_HEIGHT)
    .position(this.getFootBarPosition())
    .animation(this.isShowLemAnimate ? this.getLemAnimateParam() :
      {
        delay: 0,
        tempo: 0,
        duration: 0,
        iterations: 0
      })
    .translate(this.getFootBarTrans())
    .visibility(!this.isLemCollaps &&
      (this.immersiveUIType === UIOperationType.FOOT_BAR || this.immersiveUIType === UIOperationType.LR_SWIPE ||
        this.immersiveUIType === UIOperationType.NULL || this.immersiveOpacity !== 0) ?
    Visibility.Visible : Visibility.Hidden)
    .hitTestBehavior(this.isHalfCollapsLEM ? HitTestMode.Transparent : HitTestMode.None)
    .accessibilityLevel(this.isShowPickerView ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
    CommonConstants.ACCESSIBILITY_LEVEL_AUTO)
  }

  @Builder
  treasureBoxBuilder(): void {
    if ((this.isHalfCollapsLEM || this.isVdeCollapsed) && this.isShowTreasureBox) {
      Column() {
        TreasureBox({
          uncollaps: (data: boolean) => this.uncollapsTreasureBox(data)
        })
          .opacity(this.treasureBoxOpacity)
          .onAppear((): void => {
            if (this.isHalfCollapsLEM || this.isVdeCollapsed) {
              this.mAction.openTreasureBox();
            }
          })
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .position(this.getTreasureBoxPosition())
      .animation(this.isShowLemAnimate ? this.getLemAnimateParam() :
        {
          delay: 0,
          tempo: 0,
          duration: 0,
          iterations: 0
        })

      .visibility((this.immersiveOpacity !== 0) && this.isShowTreasureBox ? Visibility.Visible : Visibility.Hidden)
      .accessibilityLevel(this.isShowPickerView ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
      CommonConstants.ACCESSIBILITY_LEVEL_NO)
    } else if (this.isShowTreasureBox) {
      Column() {
        TreasureBox({
          uncollaps: (data: boolean) => this.uncollapsTreasureBox(data)
        })
          .opacity(this.treasureBoxOpacity)
      }
      .accessibilityLevel(this.isShowPickerView ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
      CommonConstants.ACCESSIBILITY_LEVEL_NO)
      .alignItems(HorizontalAlign.Center)
      .width(this.windowWidth)
      .position(this.getTreasureBoxPosition())
      .visibility(!this.isLemCollaps && this.immersiveOpacity !== 0 ? Visibility.Visible : Visibility.Hidden)
    }
  }

  @Builder
  TipBoxBuilder(): void {
    TipBox({
      isShowTextInfo: this.isShowTextInfo,
      isShowLongExposureInfo: this.isShowLongExposureInfo,
    })
      .hitTestBehavior(HitTestMode.Transparent)
      .position({ x: 0, y: 0 })
      .visibility(this.isFullScreen ? Visibility.Visible : Visibility.None)
      .accessibilityLevel(this.isShowPickerView ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
      CommonConstants.ACCESSIBILITY_LEVEL_AUTO)
  }

  @Builder
  floatingShutterBuilder(): void {
    if (this.isFloatingShutterShow && !this.isLemCollaps && !this.isShowPickerView) {
      FloatingShutterButton({ isPicker: this.isPicker })
        .zIndex(ZIndex.MIDDLE_TOP)
        .position({ x: 0, y: 0 })
        .visibility(this.immersiveUIType === UIOperationType.FOOT_BAR || this.immersiveOpacity !== 0 ?
        Visibility.Visible : Visibility.Hidden)
        .accessibilityLevel(this.isShowPickerView ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
        CommonConstants.ACCESSIBILITY_LEVEL_AUTO)
    }
  }

  @Builder
  pickerViewBuilder(): void {
    if (this.isPicker) {
      PickerView({
        tabBarPosition: this.tabBarPosition,
        previewPosition: this.previewAnimatePosition.y,
        footBarPosition: this.footBarPosition
      })
        .width(this.windowWidth)
        .height(this.windowHeight)
        .zIndex(ZIndex.TOP)
        .visibility(this.isShowPickerView ? Visibility.Visible : Visibility.Hidden)
        .position({ x: 0, y: 0 })
    }
  }

  @Builder
  captureShowBlackBuilder(): void {
    if (this.isShowBlack) {
      Column() {
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .zIndex(ZIndex.TOP)
      .accessibilityLevel(this.isShowPickerView ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
      CommonConstants.ACCESSIBILITY_LEVEL_AUTO)
    }
  }

  @Builder
  zoomTextChangeBuilder(): void {
    if (this.isHalfCollapsLEM) {
      Stack() {
      }
      .width(this.windowWidth)
      .height(this.windowHeight / 2)
      .hitTestBehavior(HitTestMode.Transparent)
      .position({ y: this.windowHeight / 2 })
      .zIndex(ZIndex.BOTTOM)
      .clip(true)
      .backgroundColor(Color.Black)
      .enabled(this.uiEnable)
      .accessibilityLevel(this.isShowPickerView ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
      CommonConstants.ACCESSIBILITY_LEVEL_AUTO)
      .onTouch((event: TouchEvent) => {
        this.onTouchZoomText(event);
      })
      .gesture(
        GestureGroup(
          GestureMode.Exclusive,
          PinchGesture({ fingers: 2, distance: 1 })
            .onActionStart((event?: GestureEvent) => {
              if (!event) {
                return;
              }
              return this.pinchGestureStart(event);
            })
            .onActionUpdate((event?: GestureEvent) => {
              if (!event) {
                return;
              }
              return this.pinchGestureUpdate(event);
            })
            .onActionEnd((event?: GestureEvent) => {
              if (!event) {
                return;
              }
              return this.pinchGestureEnd(event);
            }),
          PanGesture({
            fingers: 1,
            direction: this.isShowLandscape ? PanDirection.Up : PanDirection.Left,
            distance: 10
          })
            .onActionStart((): void => {
              if (!this.isShowtimeLapse && this.videoState === RecordingState.READY) {
                this.mAction.swipeChangeMode(1);
              }
            }),
          PanGesture({
            fingers: 1,
            direction: this.isShowLandscape ? PanDirection.Down : PanDirection.Right,
            distance: 10
          })
            .onActionStart((): void => {
              if (!this.isShowtimeLapse && this.videoState === RecordingState.READY) {
                this.mAction.swipeChangeMode(-1);
              }
            })
        )
      )
    }
  }

  // Builder组件按顺序创建结尾标识符

  private uncollapsTreasureBox(isOpen: boolean): void {
    if (isOpen && !(this.isHalfCollapsLEM || this.isVdeCollapsed)) {
      animateToImmediately({ duration: 150, curve: Curve.Sharp }, () => {
        this.modeBarOpacity = 0;
      });
      animateToImmediately({ duration: 500, curve: Curve.Friction }, () => {
        this.modeBarScale = 0.8;
        this.footBarTrans = -MODE_BAR_HEIGHT - this.compoMargin;
        this.footBarScale = 0.9;
      });
    } else {
      animateToImmediately({ duration: 100, curve: Curve.Sharp, delay: 50 }, () => {
        if (this.videoState !== RecordingState.RECORDING && this.videoState !== RecordingState.STARTING) {
          this.modeBarOpacity = 1;
        }
      });
      animateToImmediately({ duration: 500, curve: Curve.Friction, delay: 50 }, () => {
        this.modeBarScale = 1;
        this.footBarTrans = 0;
        this.footBarScale = 1;
      });
    }
  }

  private getZoomPosition(): Position {
    if (this.isCollapsedSplitScreen) {
      return { x: 0, y: this.rouletteZoomPosition };
    }
    if (this.isLemCollaps && !AppStorage.get('isBackground')) {
      return { x: (this.windowWidth - this.xComponentWidth) >> 1, y: 226 };
    }
    if (this.isVdeSemiCollapsed) {
      return { x: (this.windowWidth - this.xComponentWidth) >> 1, y: this.rouletteZoomPosition + 40 }
    }
    if (this.isHalfCollapsLEM) {
      return { x: (this.windowWidth - this.xComponentWidth) >> 1, y: this.zoomPosition + 58 };
    }
    return { x: (this.windowWidth - this.getRouletteZoomViewWidth()) >> 1, y: this.rouletteZoomPosition };
  }

  private getLemAnimateParam(): AnimateParam {
    return { delay: 50, duration: 300, iterations: 1 };
  }

  private checkXComponentLock(): void {
    HiLog.i(TAG, 'checkXComponentLock begin.');
    HiLog.i(TAG, 'checkXComponentLock end.');
  }

  private onTouchZoomText(event: TouchEvent): void {
    if (TouchType.Down === event.type) {
      BlurAnimateUtil.generatePixelMapFromSurface();
    }
  }

  private pinchGestureStart(event: GestureEvent): void {
    HiLog.i(TAG, 'pinchGestureStart E.');

    const isHideZoomView: boolean =
      ZoomOperation.getRingZoomUIState(this.cameraPosition, this.mode)?.quickZoomValArr.length <= 1;
    if (this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT && this.isShowLandscape) {
      return;
    }
    if (this.isShowBigText || this.isShowtimeLapse || isHideZoomView) {
      return;
    }
    this.mAction.changeFunctionValue(FunctionId.ZOOM,
      { zoomRatio: undefined, isPrepareZoom: true } as ZoomFuncValueStruct);
    clearTimeout(this.pinchGestureTimer);
    this.mAction.isEnterImmersive(true);
    this.mAction.updateShowPinch(true);
    this.baseZoom = this.zoomRatio;
    this.frontPinchCanUpdate = true;
    HiLog.i(TAG, 'pinchGestureStart X.');
  }

  private pinchGestureUpdate(event: GestureEvent): void {
    if (this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT && this.isShowLandscape) {
      return;
    }
    HiLog.i(TAG, 'pinchGestureUpdate invoke, setZoomRatio.');
    const isHideZoomView: boolean =
      ZoomOperation.getRingZoomUIState(this.cameraPosition, this.mode)?.quickZoomValArr.length <= 1;
    if (this.isShowBigText || this.isShowtimeLapse || isHideZoomView) {
      return;
    }
    if (this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      if (!this.frontPinchCanUpdate) {
        return;
      }
      if (event.scale >= this.pinchToNextZoomScale) {
        this.frontPinchCanUpdate = false;
        this.mAction.switchZoomRatio(true);
      }
      if (event.scale <= this.pinchToPrevZoomScale) {
        this.frontPinchCanUpdate = false;
        this.mAction.switchZoomRatio(false);
      }
      return;
    }

    let zoomRatio = event.scale * this.baseZoom;
    if (zoomRatio > this.maxZoomRatio) {
      zoomRatio = this.maxZoomRatio;
    }
    if (zoomRatio < this.minZoomRatio) {
      zoomRatio = this.minZoomRatio;
    }
    zoomRatio = Number.parseFloat(zoomRatio.toFixed(3));
    if (zoomRatio !== this.zoomRatio) {
      this.mAction.changeFunctionValue(FunctionId.ZOOM,
        { zoomRatio: zoomRatio } as ZoomFuncValueStruct);
    }
    let preZoomRatio = this.zoomRatio.toFixed(1);
    let curZoomRatio = zoomRatio.toFixed(1);
    if ((curZoomRatio !== preZoomRatio) &&
      (this.videoState === RecordingState.READY) && DeviceInfo.isPcAndTablet()) {
      VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_FOCUS_EFFECT_ID);
    }
    HiLog.i(TAG, 'pinchGestureUpdate end.');
  }

  private pinchGestureEnd(event: GestureEvent): void {
    HiLog.i(TAG, 'pinchGestureEnd E.');
    const isHideZoomView: boolean =
      ZoomOperation.getRingZoomUIState(this.cameraPosition, this.mode)?.quickZoomValArr.length <= 1;
    // 捏合过程中，触发倒计时拍照 倒计时过程中停止捏合 只需更新showpinch为false即可 不用退出沉浸式
    if (this.isShowPinch && this.isShowtimeLapse) {
      this.mAction.updateShowPinch(false);
      return;
    }
    if (this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT && this.isShowLandscape) {
      return;
    }
    if (this.isShowBigText || this.isShowtimeLapse || isHideZoomView) {
      return;
    }
    this.mAction.changeFunctionValue(FunctionId.ZOOM,
      { zoomRatio: undefined, isUnprepareZoom: true } as ZoomFuncValueStruct);
    this.mAction.isEnterImmersive(false);
    this.mAction.updateShowPinch(false);
    HiLog.i(TAG, 'pinchGestureEnd X.');
  }

  private updateBigTextPosition(): void {
    this.bigTextPosition = this.getBigTextPosition();
  }
}