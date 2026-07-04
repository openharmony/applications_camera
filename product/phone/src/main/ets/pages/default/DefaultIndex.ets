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
import lazy { Action, ActionData, MorePageStatus, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { Dispatch, OhCombinedState, } from '@ohos/common/src/main/ets/redux';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { TabBar } from './TabBar';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy {
  PARAM_BAR_HEIGHT,
  PARAM_ELEMENT_SIDE_LENGTH,
  PARAM_ELEMENT_SIDE_LENGTH_RTL,
  PARAM_ICON_OFFSET,
  PARAM_ICON_OFFSET_RTL,
  ParamBar
} from './ParamBar';
import lazy { ModeBar } from '@ohos/common/src/main/ets/component/ModeBar/default/ModeBar';
import lazy { FootBar } from './FootBar';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import lazy {
  TreasureBoxGestureGround
} from '@ohos/common/src/main/ets/component/treasurebox/default/TreasureBoxGestureGround';
import lazy { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { RecordAction, RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy {
  ConfirmDialogView
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/ConfirmDialogView';
import lazy { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import lazy { VideoTimer } from '@ohos/common/src/main/ets/component/videoTimer/VideoTimer';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy {
  CameraAction,
  CameraRunningState,
  CameraStartType,
  CameraStartTypeStruct
} from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy {
  FunctionValueType,
  ImmersiveActionData,
  PositionType,
  proSonChangeNumberData,
  SavePowerModeActionData,
  XComponentSize
} from '@ohos/common/src/main/ets/utils/types';
import window from '@ohos.window';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { ZoomStateType } from '@ohos/common/src/main/ets/function/zoombar/ZoomStateType';
import lazy { PickerView } from './PickerView';
import lazy {
  AdaptiveLayoutService,
  ExtendBarData,
  FOOT_BAR_HEIGHT,
  MODE_BAR_HEIGHT,
  NUMBER_MIN,
  TAB_BAR_HEIGHT,
  VDE_ZOOM_VIEW_HEIGHT,
  ZOOM_VIEW_HEIGHT
} from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLayoutService';
import lazy {
  FloatingShutterButton
} from '@ohos/extend/src/main/ets/settingcommonfunc/floatingShutter/FloatingShutterButton';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { ZoomAction } from '@ohos/common/src/main/ets/function/zoombar/ZoomAction';
import lazy { FlashMode } from '@ohos/common/src/main/ets/function/enumbase/FlashMode';
import lazy { TabBarAction } from '@ohos/common/src/main/ets/component/tabbar/TabBarAction';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { AlertDialogView } from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/AlertDialogView';
import lazy { ChangeState, getStates, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import lazy { ZoomOperation } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import lazy { PhotoFormatMode } from '@ohos/common/src/main/ets/function/enumbase/PhotoFormatMode';
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
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { OutputSwitcher } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcher';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import lazy { AuxiliaryMode } from '@ohos/common/src/main/ets/function/enumbase/AuxiliaryMode';
import lazy { AnimationOptions } from '@ohos.arkui.drawableDescriptor';
import lazy {
  CameraErrorData,
  CameraErrorDialogView,
  CameraErrorDialogViewParams
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/CameraErrorDialogView';
import lazy { VolumeShutterService } from '@ohos/common/src/main/ets/service/volume/VolumeShutterService';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { RestartService } from '@ohos/common/src/main/ets/service/restart/RestartService';
import power from '@ohos.power';
import Curves from '@ohos.curves';
import screenLock from '@ohos.screenLock';
import lazy { CameraErrorCode } from '@ohos/common/src/main/ets/camera/childthread/modules/CameraInputWrap';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { GeoPermissionScene } from '@ohos/common/src/main/ets/utils/GeoPermissionFrom';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { FunctionActionType } from '@ohos/common/src/main/ets/redux/actions/FunctionActionType';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import lazy { LightResult, PipSurfaceData } from '@ohos/common/src/main/ets/camera/DataType';
import lazy { FocusExposureService } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureService';
import lazy { FocusExposureAction } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureAction';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';
import lazy { FunctionConflictParamData } from '@ohos/common/src/main/ets/component/treasurebox/common/DataType';
import lazy { PreviewActionType } from '@ohos/common/src/main/ets/redux/actions/PreviewActionType';
import lazy { PreviewGestureArea } from '../preview/PreviewGestureArea';
import I18n from '@ohos.i18n';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import { PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import { RecordActionType } from '@ohos/common/src/main/ets/redux/actions/RecordActionType';
import { TipBox } from '@ohos/common/src/main/ets/component/tip/TipBox';

/* instrument ignore file */
const TAG: string = 'DefaultIndex';
const FLOATING_BIG_TEXT_POSITION: number = 200;
const SPLIT_BIG_TEXT_POSITION: number = 230;
const MARGIN_I_EXPOSURE: number = 24;
const SECOND_LEVEL_LOAD_DELAY: number = 110;
const OVER_HOT_EXIT_CAMERA_DELAY: number = 5000;
const VDE_SEMI_COLLAPSED_ZOOM_TEXT_CHANGE: number = 38;
const CARD_VIEW_DEFAULT_OFFSET: number = 150;
const CARD_FLOAT_VIEW_DEFAULT_OFFSET: number = 217;
const CARD_VIEW_DEFAULT_SCALE: number = 0.7;
const FLOATING_MARGIN_I_EXPOSURE: number = 48;
const VDE_SEMI_ZOOM_OFFSET: number = 454;
const PRO_VDE_SEMI_ZOOM_OFFSET: number = 394;
const TRICOLLAPS_SPLIT_SCREEN_HORIZONTAL_ZOOM_POSITION: number = 390;
const SHOW_TIP_DELAY: number = 150;
const FLOATING_PARAM_BAR_SPACING_TRICOLLAPS: number = 4;
const FLOATING_ZOOM_BAR_SPACING_TRICOLLAPS: number = 4;
const FOOT_BAR_TRANSLATE: number = 4;
const DISPLAY_SCREEN_SIZE_LEM: number = 226;
const DISPLAY_SCREEN_SIZE_PSD: number = 202;
const COLLAPSED_SET_X: number = 10;
const COLLAPSED_SET_Y: number = 160;
const COLLAPSED_SET_SIZE: number = 30;
const COLLAPSED_ROTATE_180: number = 180;
const COLLAPSED_SE_DURATION: number = 300;
const IMAGE_SIZE_20: number = 20;
const VDE_HALF_COLLAPS_MODE_BAR_OFFSET: number = 28;
const LEM_HALF_COLLAPS_MODE_BAR_OFFSET: number = 52;
const LEM_HALF_COLLAPS_EXTEND_BAR_OFFSET: number = 45;
const FLOATING_FOOTBARTRANS_OFFSET: number = 17;
const OFFSET_Y_TRI_COLLAPSED: number = 12;
const CUSTOM_FILTER_CARD_DEFAULT_HEIGHT = 218;
const CUSTOM_FILTER_CARD_BOTTOM_MARGIN = 32;
const INDICATOR_OFFSET: number = 10;
const PREVIEW_MARGIN_SIZE_56: number = 56;
const PREVIEW_MARGIN_SIZE_68: number = 68;
const CUSTOM_CARD_POSITION_X: number = 16;
const CUSTOM_CARD_POSITION_X_VDE: number = 56;
const PARAM_BAR_CUSTOM_FILTER_OFFSET: number = 2.5;

class ZoomFuncValueStruct {
  public zoomRatio?: number = 1;
  public isPrepareZoom?: boolean = false;
  public isUnprepareZoom?: boolean = false;
}

class PreviewFrameStartData {
  public isPreviewFrameStart: boolean = false;
}

class StateStruct {
  public isShowPageView: boolean = false;
  public isShowBigText: boolean = false;
  public isShowtimeLapse: boolean = false;
  public isFloatingShutterShow: boolean = false;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public xComponentWidth: number = 0;
  public xComponentHeight: number = 0;
  public isShowFootBar: boolean = true;
  public isShowParamBar: boolean = false;
  public isShowExtendBar: boolean = false;
  public zoomState: string = '';
  public cameraRunningState: CameraRunningState = CameraRunningState.UNINITIALIZED;
  public treasureBoxCollapsState: boolean = false;
  public showPicker: boolean = false;
  public isShowBlack: boolean = false;
  public excludeComponent: string = UIOperationType.NULL;
  public uiEnable: boolean = false;
  public minZoomRatio: number = 0;
  public maxZoomRatio: number = 0;
  public videoState: RecordingState = RecordingState.READY;
  public isShowPinch: boolean = false;
  public isLightPaintingFlashTimerShow: boolean = false;
  public isLightPaintingFlashShow: boolean = false;
  public isShowToolBar: boolean = false;
  public isShowTimedShot: boolean = false;
}

class FocusModeStruct {
  public focusMode: camera.FocusMode = camera.FocusMode.FOCUS_MODE_AUTO;
  public focusPoint: camera.Point = { x: 0, y: 0 };
}

class ExposureModeStruct {
  public exposureMode: camera.ExposureMode = camera.ExposureMode.EXPOSURE_MODE_AUTO;
  public exposureValue: number = 0;
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

  public previewClicked(): void {
    this.mDispatch(Action.previewClicked());
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

  public proBarRecoveryAuto(): void {
    this.mDispatch(Action.proBarRecoveryAuto());
  }

  public confirmLocationTOSettingPermission(isRequestOnSetting: boolean, fromModul?: number): void {
    this.mDispatch(Action.confirmLocationTOSettingPermission(isRequestOnSetting, fromModul));
  }

  public showFootBar(): void {
    this.mDispatch(Action.updateIsShowFootBar(true));
  }

  public showModeBar(): void {
    this.mDispatch(Action.updateIsShowModeBar(true));
  }

  public updateZoomBuilderOffsetY(offsetY: number): void {
    this.mDispatch(ZoomAction.updateZoomBuilderOffsetY(offsetY));
  }

  public updateIsShowExtendBar(isShowExtendBar: boolean): void {
    this.mDispatch(Action.updateIsShowExtendBar(isShowExtendBar))
  }

  public updateIsShowParamBar(isShowParamBar: boolean): void {
    this.mDispatch(Action.updateIsShowParamBar(isShowParamBar))
  }

  public keepUsingStellarLenses(): void {
    this.mDispatch(CameraAction.keepUsingStellarLenses());
  }

  public setTimeLapseAuto(type: number): void {
    this.mDispatch(Action.sendTimeLapseAuto(type));
  }

  public hideFocus(): void {
    this.mDispatch(FocusExposureAction.hideFocus());
  }

  public updatePopUpButton(): void {
    this.mDispatch(TabBarAction.updatePopUpButton());
  }

  public changeTimedShot(isShowTimedShot: boolean): void {
    this.mDispatch(Action.changeTimedShot(isShowTimedShot));
  }

  public updateShowBigTextFlag(isShowBigText: boolean): void {
    this.mDispatch(Action.updateShowBigTextFlag(isShowBigText));
  }
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
  public isRequestOnSetting: boolean = false;
  public scene: number = 0;
}

interface ProIsoValue {
  functionId: FunctionId,
  value: number
}

@Component
export struct DefaultIndex {
  @State isCustomFilterStarted: boolean = false;
  // 消息事件
  private eventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mAction: IndexDispatcher = new IndexDispatcher();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  // 全局数据
  private mBase: BaseComponent = new BaseComponent();
  @State state: StateStruct = new StateStruct();
  @State @Watch('windowSizeChange') windowWidth: number = 0;
  @State @Watch('windowSizeChange') windowHeight: number = 0;
  @State mode: ModeType = ModeType.NONE;
  @State isShowFlipTipView: boolean = false;
  private layoutService: AdaptiveLayoutService = AdaptiveLayoutService.getInstance();
  // UX位置
  private isNeedPlayZoomTransAnim: boolean = false;
  private isNeedPlayParamBarTransAnim: boolean = false;
  @LocalStorageLink('previewAnimatePosition') @Watch('onFootBarPositionChange') previewAnimatePosition: PositionType =
    { x: 0, y: 0 };
  @State zoomTranslate: number = 0;
  @State footBarPosition: number = 0;
  @State zoomPosition: number = 0; // 老变焦布局规则RingZoomPosition-Deprecated
  @LocalStorageLink('extendBarPosition') extendBarPosition: number = 0;
  @State rouletteZoomPosition: number = 0;
  @State modeBarPosition: number = 0;
  @State arrowPosition: number = 0;
  @State tabBarPosition: number = 0;
  @State compoMargin: number = 0;
  // 显示与隐藏动效
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State videoTimerState: boolean = false;
  @State lightPaintingTimerState: boolean = false;
  @State @Watch('setTreasureBoxUncollapsAnimation') isOpen: boolean = false;
  @StorageLink('isInBlurAnim') isInBlurAnim: boolean = false;
  @State isModeBarWithoutAnimation: boolean = false;
  @State rotateAngle: number = 0;
  @State iconRotateAngle: number = 0;
  @State tabViewPosition: TabPosition = this.getTimeLapseTabPosition();
  @State prosonNumber: number = -1;
  @State lumationValue: number = 0.3;
  @State modeBarScale: number = 1;
  @State customFilterStackCardViewOpacity: number = 0;
  @State rouletteZoomViewScale: number = 1;
  @State customFilterStackCardVieWScaleX: number = CARD_VIEW_DEFAULT_SCALE;
  @State customFilterStackCardVieWScaleY: number = CARD_VIEW_DEFAULT_SCALE;
  @State customFilterStackCardVieWPositionY: number = CARD_VIEW_DEFAULT_OFFSET;
  @State modeBarOpacity: number = 1;
  @State tabBarOpacity: number = 1;
  @State @Watch('onFootBarPositionChange') footBarTrans: number = 0;
  @State footBarScale: number = 1;
  @State footBarCustomFilterScale: number = 1;
  @State showTimer: boolean = false;
  @State showLightPaintingTimer: boolean = false;
  @State timerOpacity: number = 0;
  @State lightPaintingTimerOpacity: number = 0;
  @Prop immersiveOpacity: number = 1;
  @Prop immersiveUIType: UIOperationType = UIOperationType.NULL;
  @State treasureBoxOpacity: number = 1;
  @State showModeBar: boolean = true;
  @State isShowTextInfo: boolean = false;
  @State isShowLongExposureInfo: boolean = false;
  @State showZoomView: boolean = false;
  @State showParamBar: boolean = false;
  @State showProfessionBar: boolean = true;
  @State isFlashEnable: boolean = true;
  // 启动相关
  @State firstLevelLoaded: boolean = false;
  // 音量键订阅
  private volumeService: VolumeShutterService = VolumeShutterService.getInstance();
  @StorageLink('isAnyDialogOpening') @Watch('volumeKeySubscribeOrNot') isAnyDialogOpening: boolean = false;
  // 相机异常弹窗
  private cameraErrorDialogController: CustomDialogController | null = null;
  @State @Watch('updateIsAnyDialogOpening') isShowCameraError: boolean = false;
  private errorCode: number = 0;
  // 地理位置弹窗
  private locationDialogController: CustomDialogController | null = null;
  //温控弹窗
  private exitCameraDialogController: CustomDialogController | null = null;
  private session: UIExtensionContentSession | undefined = undefined;
  private isToSettingPermission: boolean = false;
  private exposureConfirmDialogController: CustomDialogController | null = null;
  private lightPaintingDialogController: CustomDialogController | null = null;
  private portraitBeautyDialogController: CustomDialogController | null = null;
  private customFilterDialogController: CustomDialogController | null = null;
  @State @Watch('updateIsAnyDialogOpening') isShowExitFlash: boolean = false;
  @State @Watch('updateIsAnyDialogOpening') isShowExitCamera: boolean = false;
  @State isLowBatteryTipShowed: boolean = false;
  @State @Watch('updateIsAnyDialogOpening') isShowExposure: boolean = false;
  @State @Watch('dialogShowChange') @Watch('updateIsAnyDialogOpening') isDialogShow: boolean = false;
  private mTimerId: number = Number.MIN_VALUE;
  private exitCameraTimerId: number = Number.MIN_VALUE;
  private appRecoveryTimer: number = Number.MIN_VALUE;
  private openBoxTimer: number = Number.MIN_VALUE;
  private nightTimer: number = Number.MIN_VALUE;
  // Picker
  @State isPicker: boolean = false;
  @State showPicker: boolean = false;
  @State private isShowSemiCollapsed: boolean = false;
  @State private isShowLandscape: boolean = false;
  @State @Watch('changeHalfCollapsLEM') isHalfCollapsLEM: boolean = false;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @StorageLink('isPSDCollaps') isPSDCollapsed: boolean = false;
  @State isShowMorePage: boolean = false;
  @State isEditMorePage: boolean = false;
  @StorageLink('isShowModeDetailPage') isShowModeDetailPage: boolean = false;
  @State isHighStabilizationValue: boolean = false;
  @StorageLink('treasureBoxSelector') selector: FunctionId = FunctionId.NONE;
  @State isShowtimeLapse: boolean = false;
  @State isShowLemAnimate: boolean = false;
  @StorageLink('isBackground') isBackground: boolean = false;
  @State isImmersivePro: boolean = false;
  @State isImmersive: boolean = false;
  private pinchGestureTimer: number = 0;
  private baseZoom: number = 0;
  private recoverFlash: boolean = false;
  private frontPinchCanUpdate: boolean = false;
  private readonly pinchToNextZoomScale = 1.25;
  private readonly pinchToPrevZoomScale = 0.75;
  private isStart: boolean = false;
  private exitTimer: number = 5;
  @State isTimeLapseHideTimer: boolean = false;
  // 环形补光
  @State isShowRingLightView: boolean = false;
  @State isShowWhiteBack: boolean = false;
  @State @Watch('updateLayout') windowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  @State windowStateCache: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  // 慢动作相关
  @State isSuperSlowMotion: boolean = false;
  @State isTimelapseFront: boolean = false;
  @StorageLink('isDownSuperSlowBtnState') isDownSuperSlowBtn: boolean = false;
  @StorageLink('slowRecordingCompVisible') slowRecordingCompVisible: boolean = true; // 超慢控制组件展示的动效变量
  // 小i弹窗相关
  @StorageLink('isModeIntroDialogLoaded') isModeIntroDialogLoaded: Map<ModeType, boolean> =
    new Map<ModeType, boolean>();
  @State isShowModeIntroCardEntry: boolean = false;
  @State isLightPaintingDialogLoaded: boolean = false;
  @State @Watch('updateIsAnyDialogOpening') isLightPaintingDialogOpen: boolean = false;
  @State @Watch('updateIsAnyDialogOpening') isPortraitBeautyDialogOpen: boolean = false;
  @State @Watch('updateIsAnyDialogOpening') isCustomFilterDialogOpen: boolean = false;
  @State isPortraitBeautyDialogLoaded: boolean = false;
  @State isPreviewFrameStart: boolean = true;
  @State isPanoramaBarVisible: boolean = false;
  @State isPanoramaFootBarShow: boolean = false;
  private panoramaTimer: number = Number.MIN_VALUE;
  @State superIsoValue: number = 0;
  @StorageLink('isShowTimeLapseToolBar') isShowToolBar: boolean = false;
  @State specialModeZoomBarVisible: boolean = false;
  @State isShowBlackView: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @StorageLink('isNightShutting') isNightShutting: boolean = false;
  @State isShowLightPaintingTimer: boolean = false;
  @State isShowTreasureBox: boolean = false;
  @State @Watch('onVdeLandscapeChange') isVdeLandscape: boolean = false;
  @State @Watch('changeHalfCollapsVDE') isVdeSemiCollapsed: boolean = false;
  @Prop isShowSettingView: boolean = false;
  @State isShowLowAngleShotView: boolean = false;
  @State isShowLowAngleAnim: boolean = false;
  @State treasureBoxPositionY: number = this.getTreasureBoxPositionY();
  @State startVideoRecording: boolean = false;
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;
  @State treasureBoxGestureGroundHeight: number = 0;
  @State treasureBoxGestureGroundPosition: number = 0;
  @LocalStorageLink('changeCustomFilterImmersive')
  isCustomFilterImmersive: boolean = false;
  @StorageLink('isCustomFilterImmersiveMoving') isCustomFilterImmersiveMoving: boolean = false;
  @State isCustomFilterImmersiveImmediately: boolean = false;
  // CustomFilter
  @StorageLink('onCustomFilterTopLineChange') customFilterTopLineHeight: number = 0;
  @State customFilterCardPositionY: number = getStates().get<number>('windowReducer', 'windowHeight') - 109;
  @State customFilterCardScale: ScaleOptions = { x: CARD_VIEW_DEFAULT_SCALE, y: CARD_VIEW_DEFAULT_SCALE };
  @State customFilterCardOpacity: number = 0.0;
  private needOpen: boolean = false;
  private needDisappear: boolean = false;
  @State thumbnailViewArea: Area = {
    width: '',
    height: '',
    position: {},
    globalPosition: {}
  };
  @State footBarOffsetX: number = 0;
  @State @Watch('onFootBarPositionChange') footBarOffsetY: number = 0;
  // 镜头收回弹窗
  private cameraLensRetractedDialogController: CustomDialogController | null = null;
  private isChangeMode: boolean = false;
  private closingTimeoutIndex = -1;
  private preStatusIsFloatingOfZoomBar = false;
  private preStatusIsFloatingOfParamBar = false;
  private geoScene: number | undefined = undefined;
  @StorageLink('onCustomFilterCardActionMenuShow') isShowActionMenu: boolean = false;
  public skipOpenTreasureBox: boolean = false;
  // 奇异果-俯仰角引导动画
  @State isShowIntroLottie: boolean = false;
  @LocalStorageLink('isPitchAngleIntroLoaded') isPitchAngleIntroLoaded: boolean = false;
  @LocalStorageLink('isRotationSuggestionIntroLoaded') isRotationSuggestionIntroLoaded: boolean = false;
  @LocalStorageLink('isCustomStylesIntroLoaded') isCustomStylesIntroLoaded: boolean = false;
  @State introLottieOpacity: number = 0;
  @LocalStorageLink('footBarPositionChange') currentFootBarLocation: number = 0;
  // 夜景子模式画中画状态
  private isShowNightSubModePipSurface = false;
  @State isForeground: boolean = true;
  @Prop isHdr: boolean = false;
  @State private treasureBoxAnimationState: number = -1; // 0-消失过程 1-出现过程 -1 无动效
  @LocalStorageLink('isBetweenBlurAnimDoneAndAnimEnd') isBetweenBlurAnimDoneAndAnimEnd: boolean = false;
  @State isStitchingHorizontalFloating: boolean = false;
  @State isShowSetView: boolean = false;
  @State isShowCollapsSet: boolean = true;
  @State isProShuttering: boolean = false;
  @State zoomRatio: number = 0;
  @State isShowTimedShot: boolean = false;
  @State isFirstLauncher: boolean = true;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear begin.');
    this.isPicker = GlobalContext.get().getIsPicker();
    this.setEventBusOn();
    this.setSecondEventBusOn();
    this.chooseToShowExtendBar();
    this.initState();
    this.uxInit();
    this.initializeIsDialogLoaded();
    this.setTreasureBoxGestureGroundUX();
    if (!this.isPicker) {
      this.volumeService.volumeKeySubscribe();
    }
    setTimeout(() => {
      HiLog.begin(TAG, 'LoadSecondLevel');
      this.firstLevelLoaded = true;
      HiLog.end(TAG, 'LoadSecondLevel');
    }, SECOND_LEVEL_LOAD_DELAY);
    HiLog.i(TAG, 'aboutToAppear end.');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.eventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    this.closeDialogConfirm();
    this.isPanoramaBarVisible = false;
  }

  private initState(): void {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.isImmersive = state.get<boolean>('uiReducer', 'isImmersive');
      this.isShowtimeLapse = state.get<boolean>('settingReducer', 'isShowtimeLapse');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      // 延时摄影借用了video 的流所以加了判斷
      this.videoTimerState = state.get<boolean>('recordReducer', 'videoTimerState');
      this.lightPaintingTimerState = state.get<boolean>('lightPaintingReducer', 'lightPaintingTimerState');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.isEditMorePage = state.get<boolean>('modeReducer', 'isEditMorePage');
      this.isShowFlipTipView = state.get<boolean>('backSelfieReducer', 'isShowFlipTipView');
      this.onStateChanged(changeState, state);
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isShowWhiteBack = state.get<boolean>('ringLightReducer', 'isShowWhiteBack');
      this.windowStatus = state.get<window.WindowStatusType>('windowReducer', 'windowStatus');
      this.iconRotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.isShowLowAngleShotView = state.get<boolean>('collapsReducer', 'isShowLowAngleShotView');
      this.isProShuttering = state.get<boolean>('proShutterReducer', 'isProShuttering');
      this.zoomRatio = state.get<number>('zoomReducer', 'zoomRatio');
      this.isShowTimedShot = state.get<boolean>('settingReducer', 'isShowTimedShot');
      this.initState2(state);
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
  }

  private onStateChanged(changeState: ChangeState<StateStruct>, state: OhCombinedState) {
    changeState(this.state, {
      isShowPageView: state.get<boolean>('settingViewReducer', 'isShowSettingView'),
      isShowBigText: state.get<boolean>('modeReducer', 'isShowBigText'),
      isShowtimeLapse: state.get<boolean>('settingReducer', 'isShowtimeLapse'),
      isFloatingShutterShow: state.get<boolean>('settingReducer', 'isFloatingShutterShow'),
      cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
      xComponentWidth: state.get<number>('previewReducer', 'xComponentWidth'),
      xComponentHeight: state.get<number>('previewReducer', 'xComponentHeight'),
      isShowFootBar: state.get<boolean>('uiReducer', 'isShowFootBar'),
      isShowParamBar: state.get<boolean>('uiReducer', 'isShowParamBar'),
      isShowExtendBar: state.get<boolean>('uiReducer', 'isShowExtendBar'),
      zoomState: state.get<string>('zoomReducer', 'zoomState'),
      cameraRunningState: state.get<CameraRunningState>('cameraReducer', 'cameraRunningState'),
      treasureBoxCollapsState: state.get<boolean>('treasureBoxReducer', 'isOpen'),
      showPicker: state.get<boolean>('uiReducer', 'showPicker'),
      isShowBlack: state.get<boolean>('collapsReducer', 'isShowBlack'),
      excludeComponent: state.get<string>('contextReducer', 'excludeComponent'),
      uiEnable: state.get<boolean>('contextReducer', 'uiEnable'),
      minZoomRatio: state.get<number>('zoomReducer', 'minZoomRatio'),
      maxZoomRatio: state.get<number>('zoomReducer', 'maxZoomRatio'),
      videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
      isShowPinch: state.get<boolean>('zoomReducer', 'isShowPinch'),
      isLightPaintingFlashTimerShow: state.get<boolean>('lightPaintingReducer', 'isLightPaintingFlashTimerShow'),
      isLightPaintingFlashShow: state.get<boolean>('settingReducer', 'isLightPaintingFlashShow'),
      isShowToolBar: false,
      isShowTimedShot: state.get<boolean>('settingReducer', 'isShowTimedShot'),
    });
  }

  private initState2(state: OhCombinedState): void {
    this.showPicker = state.get<boolean>('uiReducer', 'showPicker');
    this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
    this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
    this.isOpen = state.get<boolean>('treasureBoxReducer', 'isOpen');
    this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
    this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
    this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
    this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
    this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
    this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
    this.isFlashEnable = state.get<boolean>('uiReducer', 'isFlashEnable');
    this.isShowLightPaintingTimer = state.get<boolean>('lightPaintingReducer', 'isLightPaintingTimerShow');
    this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
    this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
  }

  private setEventBusOn(): void {
    const code = this.mBase.hashCode();
    this.eventBus.on(CameraActionType.ERROR, (data: CameraErrorData) => this.cameraErrorDialogShow(data.code), code);
    this.eventBus.on(CameraActionType.STARTED, this.defaultIndexOnStarted.bind(this), code);
    this.eventBus.on(PreviewActionType.CHANGE_PREVIEW_SIZE_ANIM, () => this.updateZoomPosition(), code);
    this.eventBus.on(ActionType.ACTION_RESTORE_DIALOG_CONFIRM, (data: RestoreDialogConfirmData) =>
    this.locationDialogShow(false, data), code);
    this.eventBus.on(ActionType.ACTION_LOCATION_PERMISSION_TO_SETTING, (data: RestoreDialogConfirmData) =>
    this.locationDialogShow(true, data), code);
    this.eventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, () => this.onBackground(), code);
    this.eventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, () => this.onForeground(), code);
    this.eventBus.on(ActionType.ACTION_SHOW_EXIT_FLASH_DIALOG, () => this.exitFlashDialogShow(), code);
    this.eventBus.on(ActionType.ACTION_SHOW_EXIT_CAMERA_DIALOG, () => this.exitCameraDialogShow(), code);
    this.eventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, () => this.onAbilityBackground(), code);
    this.eventBus.on(ActionType.ACTION_CLOSE_SETTING_DIALOG, () => this.closeDialogConfirm(), code);
    this.eventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.SWITCH_CAMERA_CHANGE_MODE],
      () => this.isShowComponentDisplay(), code);
    this.eventBus.on([CameraActionType.SWITCH_CAMERA, CameraActionType.CHANGE_MODE, CameraActionType.CHANGE_OUTPUT_TYPE,
      CameraActionType.SWITCH_CAMERA_CHANGE_MODE], () => this.updateTimeLapseTimerState(true), code);
    this.eventBus.on([WindowActionType.ON_SIZE_CHANGE, WindowActionType.REFRESH_UX], () => this.uxInit(), code);
    this.eventBus.on(ActionType.ACTION_TIME_LAPSE_TRY_AE_DONE, () => this.updateTimeLapseTimerState(false), code);
    this.eventBus.on(ActionType.ACTION_TIME_LAPSE_RECORDING_STOP, () => this.updateTimeLapseTimerState(true), code);
    this.eventBus.on(ContextActionType.UPDATE_SAVE_POWER_MODE_STATE, (data: SavePowerModeActionData) =>
    this.updateSavePowerModeState(data), code);
    this.eventBus.on(ActionType.ACTION_CLEAR_PAGE_OR_DIALOG, this.clearDialog.bind(this), this.mBase.hashCode());
    this.eventBus.on(ActionType.ACTION_LONG_EXPOSURE_SHUTTER,
      () => this.isShowLongExposureCaptureInfo(true), code);
    this.eventBus.on([ActionType.ACTION_LONG_EXPOSURE_SHUTTER_END, CameraActionType.STARTED],
      () => this.isShowLongExposureCaptureInfo(false), code);
    this.eventBus.on(ActionType.ACTION_PROSON_CHANGE_STATE,
      (data: proSonChangeNumberData) => this.prosonChange(data), code);
    this.eventBus.on(ActionType.ACTION_ON_LUMINATION_STATUS_CHANGED,
      (data: LumationConfirmData) => this.updateLumation(data), code);
    this.eventBus.on(ActionType.ACTION_LIGHT_PAINTING_FLASH, () => this.initializeIsDialogLoaded(), code);
    this.eventBus.on(ActionType.ACTION_ON_PREVIEW_FRAME_START, this.onPreviewFrameStart.bind(this), code);
    this.eventBus.on([ActionType.ACTION_IS_START_PANORAMA], () => this.onIsPanoramaFootBar(true), code);
    this.eventBus.on(ActionType.ACTION_IS_END_PANORAMA, () => this.onIsPanoramaFootBar(false), code);

    this.eventBus.on(ActionType.ACTION_START_STITCHING_CAPTURE, () => this.onIsStitchingFootBar(true), code);
    this.eventBus.on(ActionType.ACTION_END_STITCHING_CAPTURE, () => this.onIsStitchingFootBar(false), code);

    this.eventBus.on(ActionType.ACTION_ON_PHOTO_STOP_PANORAMA, () => this.onIsPanoramaFootBar(false), code);
  }

  private setSecondEventBusOn(): void {
    const code = this.mBase.hashCode();
    this.eventBus.on(ActionType.ACTION_IS_ENTER_IMMERSIVE, this.isEnterLrSwipeImmersive.bind(this), code);
    this.eventBus.on(ActionType.ACTION_IS_SHOW_TREASURE_BOX, this.isProShowTreasureBox.bind(this), code);
    this.eventBus.on([CameraActionType.SWITCH_CAMERA, CameraActionType.CHANGE_MODE,
      CameraActionType.SWITCH_CAMERA_CHANGE_MODE], () => this.initializeIsDialogLoaded(), code);
    this.eventBus.on(ActionType.ACTION_IS_HIDE_TREASURE_BOX, this.isProHideTreasureBox.bind(this), code);
    this.eventBus.on(CameraActionType.START, this.startGetZoomBuilderOffsetY.bind(this), code);
    this.eventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, this.getZoomBuilderOffsetY.bind(this), code);
    this.eventBus.on(RecordActionType.STOP, this.onStop.bind(this), this.mBase.hashCode());
    this.eventBus.on(ActionType.ACTION_RECORD_START_SECONDS, this.startToRecord.bind(this), this.mBase.hashCode());
    this.eventBus.on(ActionType.ACTION_SHOW_MORE_PAGE, this.showMoreChanged.bind(this), this.mBase.hashCode());
    this.eventBus.on(PreviewActionType.LOAD_SURFACE_DONE, () => this.checkXComponentLock(), this.mBase.hashCode());
    this.eventBus.on(WindowActionType.WINDOW_STATUS, this.onWindowStatusChange.bind(this),
      this.mBase.hashCode());
  }

  private closeDialogConfirm(): void {
    this.cameraErrorDialogController?.close();
    this.locationDialogController?.close();
    this.exposureConfirmDialogController?.close();
    this.exitCameraDialogController?.close();
    this.lightPaintingDialogController?.close();
    this.portraitBeautyDialogController?.close();
    this.customFilterDialogController?.close();
    this.isShowExposure = false;
    this.isShowExitFlash = false;
    this.isShowExitCamera = false;
    this.isLowBatteryTipShowed = false;
    this.isLightPaintingDialogOpen = false;
    this.isPortraitBeautyDialogOpen = false;
    this.isCustomFilterDialogOpen = false;
    if (this.isDialogShow) {
      this.isDialogShow = false;
      this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
    }
  }

  private initializeIsDialogLoaded(): void {
    if (GlobalContext.get().getIsPicker()) {
      HiLog.i(TAG, 'picker is not need to show portrait beauty dialog.');
      return;
    }
  }

  private onFootBarPositionChange() {
    HiLog.i(TAG, `onFootBarPositionChange : ${JSON.stringify(this.footBarTrans)}.`);
    this.currentFootBarLocation =
      this.footBarTrans + this.getFootBarPositionY() + this.footBarOffsetY -
      this.previewAnimatePosition.y - INDICATOR_OFFSET;
  }

  private checkIsPortraitBeautyLoaded() {
    this.isPortraitBeautyDialogLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_PORTRAIT_BEAUTY_DIALOG_LOADED,
        false) as boolean;
    return this.isPortraitBeautyDialogLoaded;
  }

  private onLandscapeChanged(data: ActionData): void {
    HiLog.i(TAG, `onLandscapeChanged SemiCollapsed: ${this.isShowSemiCollapsed}, Landscape: ${this.isShowLandscape}.`);
    // 展开，关闭曝光恢复弹窗
    if (this.isShowSemiCollapsed && this.isShowLandscape && data['isShowLandscape'] && !data['isShowSemiCollapsed'] &&
    this.exposureConfirmDialogController) {
      this.exposureConfirmDialogController?.close();
      this.isDialogShow = false;
    }
    if (this.isShowSemiCollapsed || this.isShowLandscape) {
      this.lightPaintingDialogController?.close();
      this.isLightPaintingDialogOpen = false;
    }
    this.cameraErrorDialogController?.close();
    this.isShowCameraError = false;
  }

  private isShowComponentDisplay(): void {
    HiLog.i(TAG, 'isShowComponentDisplay.')
    this.showZoomView = true;
    this.showParamBar = true;
    this.showProfessionBar = true;
    if (this.isFirstLauncher) {
      this.isFirstLauncher = false;
    } else {
      this.mAction.updateShowBigTextFlag(true);
    }
  }

  private isProHideTreasureBox(): void {
    this.isShowTreasureBox = true;
  }

  private isProShowTreasureBox(): void {
    this.isShowTreasureBox = false;
  }

  private onStop(): void {
    this.startVideoRecording = false;
    this.showTimer = false;
    this.isTimeLapseHideTimer = true;
    this.timerOpacity = 0;
  }

  private startToRecord(): void {
    this.startVideoRecording = true;
    this.showTimer = true;
    this.isTimeLapseHideTimer = false;
    this.timerOpacity = 1;
  }

  //切换照片比例获取zoomBuilder的offsetY
  private getZoomBuilderOffsetY(data: ActionData): void {
    if (data['id'] === FunctionId.ASPECT_RATIO) {
      let zoomBuildOffsetY: number = this.getZoomOffset()?.y as number;
      this.mAction.updateZoomBuilderOffsetY(zoomBuildOffsetY)
    }
  }

  //Start时获取zoomBuilder的offsetY
  private startGetZoomBuilderOffsetY(): void {
    let zoomBuildOffsetY: number = this.getZoomOffset()?.y as number;
    this.mAction.updateZoomBuilderOffsetY(zoomBuildOffsetY)
  }

  private changeCustomFilterPreviewSize(data: ActionData): void {
    if (this.isPicker) {
      return;
    }
    if (data['isPreviewScaled']) {
      this.uncollapsCustomFilterStackCardView(true);
      this.mAction.updateIsShowExtendBar(false);
      if (this.isOpen) {
        this.needOpen = true;
      } else {
        //  箭头渐隐
        animateToImmediately({ duration: 100, curve: Curve.Sharp, delay: 0 }, () => { // 调色盘展开，快捷变焦缩放
          this.treasureBoxOpacity = 0;
        });
        this.needDisappear = true;
      }
      this.mAction.closeTreasureBox();
    } else {
      this.uncollapsCustomFilterStackCardView(false);
      this.mAction.updateIsShowParamBar(true);
      if (this.needOpen) {
        if ((this.mode === ModeType.PHOTO)) {
          this.modeBarOpacity = 0;
          this.mAction.openTreasureBox();
        } else {
          this.modeBarOpacity = 1;
          this.modeBarScale = 1;
          this.footBarTrans = 0;
          this.footBarScale = 1;
          this.footBarOffsetX = 0;
        }
      }
      this.needOpen = false;
      if (this.needDisappear) {
        //  箭头渐显
        animateToImmediately({ duration: 100, curve: Curve.Sharp, delay: 200 }, () => { // 调色盘展开，快捷变焦缩放
          this.treasureBoxOpacity = 1;
        });
        this.needDisappear = false;
      }
    }
  }

  private dialogShowChange(): void {
    GlobalContext.get().setObject('isDialogShow', this.isDialogShow);
  }

  private changeHalfCollapsLEM(): void {
    this.isShowLemAnimate = true;
    this.updateHalfCollapsedModeBarPosition();
    this.updateExtendBarPosition();
    setTimeout((): void => {
      this.isShowLemAnimate = false;
    }, 400);
    this.mAction.closeTreasureBox();
    if (this.isHalfCollapsLEM && !this.isShowMorePage) {
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

  private onVdeLandscapeChange(): void {
    if (this.isVdeLandscape) {
      this.uxInit();
    }
  }

  private changeHalfCollapsVDE(): void {
    // this.uxInit();
    this.updateHalfCollapsedModeBarPosition();
    this.updateExtendBarPosition();
    this.treasureBoxPositionY = this.getTreasureBoxPositionY();
    this.exposureConfirmDialogController?.close();
    this.exposureConfirmDialogController = null;
  }

  private changePreviewPositionAnim(): void {
    this.isShowLowAngleAnim = true;
    setTimeout((): void => {
      this.isShowLowAngleAnim = false;
    }, 400);
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
      if (this.isHalfCollapsLEM) {
        this.mAction.openTreasureBox();
      }
    }, 300);
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

  private createLocationDialog(fromModul?: number): void {
    if (this.isToSettingPermission) {
      // 地理位置权限前往设置弹窗
      this.createLocationToSettingDialog(fromModul);
    } else {
      // 地理位置权限二次确认弹窗
      this.createLocationConfirmDialog();
      // this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
      // this.mAction.resetSaveModeTimer();
      // HiLog.i(TAG, 'locationConfirmDialogController ConfirmDialogView cancel');
    }
  }

  private onIsPanoramaFootBar(visible: boolean) {
    HiLog.i(TAG, 'onIsPanoramaFootBar E.' + visible);
    this.isPanoramaFootBarShow = visible;
    if (visible && !this.isHalfCollapsLEM) {
      this.mAction.closeTreasureBox();
    }
    HiLog.i(TAG, 'onIsPanoramaFootBar X.');
  }

  private onIsStitchingFootBar(visible: boolean) {
    if (visible) {
      this.mAction.closeTreasureBox();
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

  private createCameraErrorDialog(errorCode: number): void {
    HiLog.i(TAG, `pass errorCode: ${errorCode}`);
    let params: CameraErrorDialogViewParams = CameraErrorDialogView.getDefaultParams(errorCode);
    this.errorCode = errorCode; // record for reOpenCameraErrorDialog function
    this.cameraErrorDialogController?.close();
    this.isShowCameraError = false;
    this.cameraErrorDialogController = new CustomDialogController({
      builder: CameraErrorDialogView({
        confirm: () => {
          this.mAction.resetSaveModeTimer();
          params.confirm();
          this.isShowCameraError = false;
          this.errorCode = 0;
        },
        title: params.title,
        description: params.description,
        confirmText: params.confirmText,
        rotateAngle: this.getRotate(),
        currentDirection: this.mDirection,
      }),
      autoCancel: false,
      customStyle: true,
      cancel: () => {
        this.isShowCameraError = false;
      },
      maskColor: '#66000000',
      alignment: DialogAlignment.Center,
    });
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

  private createLocationToSettingDialog(fromModul?: number): void {
    HiLog.i(TAG, `createLocationToSettingDialog fromModul: ${fromModul}`);
    this.locationDialogController = new CustomDialogController({
      builder: ConfirmDialogView({
        cancel: () => {
          HiLog.i(TAG, 'locationSettingDialogController ConfirmDialogView cancel.');
          this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
          if (fromModul === GeoPermissionScene.NIGHT) {
          }
          this.isDialogShow = false;
        },
        confirm: () => {
          //拉起设置
          this.mAction.confirmLocationTOSettingPermission(true, fromModul);
          this.isDialogShow = false;
        },
        title: $r('app.string.camera_location_request_dialog_title'),
        description:
        $r('app.string.location_permission_description_without_starry_sky'),
        cancelText: $r('app.string.cancel'),
        confirmText: $r('app.string.permission_dialog_goto_setting_button'),
        rotateAngle: this.getRotate(),
        currentDirection: this.mDirection,
        isHdr: this.isHdr
      }),
      autoCancel: false,
      customStyle: true,
      maskColor: '#66000000',
      cancel: () => {
        this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
        if (fromModul === GeoPermissionScene.NIGHT) {
        }
        this.isDialogShow = false;
      },
      alignment: DialogAlignment.Center,
    });
  }

  private createLocationConfirmDialog(): void {
    this.locationDialogController = new CustomDialogController({
      builder: ConfirmDialogView({
        cancel: () => {
          this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
          this.isDialogShow = false;
          this.mAction.resetSaveModeTimer();
          HiLog.i(TAG, 'locationConfirmDialogController ConfirmDialogView cancel');
        },
        confirm: () => {
          this.mAction.resetSaveModeTimer();
          this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, true);
          this.isDialogShow = false;
        },
        title: $r('app.string.camera_location_request_dialog_title'),
        description: $r('app.string.gps_attention_dialog_need_summary'),
        cancelText: $r('app.string.gps_attention_dialog_need_disable'),
        confirmText: $r('app.string.gps_attention_dialog_need_enable'),
        rotateAngle: this.getRotate(),
        currentDirection: this.mDirection,
        isHdr: this.isHdr
      }),
      // fix: 设置相机恢复默认设置后，位置弹框无法跳过
      autoCancel: true,
      customStyle: true,
      maskColor: '#66000000',
      cancel: () => {
        this.isDialogShow = false;
        this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
      },
      alignment: DialogAlignment.Center,
    });
  }

  private onWillDismissFunction(dismissContentCoverAction: DismissContentCoverAction): void {
    if (dismissContentCoverAction.reason === DismissReason.PRESS_BACK) {
      PreferencesService.getInstance()
        .putPublicValue(PersistType.FOREVER, PublicTag.IS_PORTRAIT_BEAUTY_DIALOG_LOADED, true);
      this.isPortraitBeautyDialogOpen = false;
      this.portraitBeautyDialogController?.close();
      this.locationDialogShow(false);
    }
  }

  private getOffset(): number {
    return -(getStates().get<number>('windowReducer', 'windowWidth') / 4);
  }

  private isVertical(): boolean {
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  private showLensRetractedDialog(): void {
    HiLog.e(TAG, `showLensRetractedDialog: ${this.cameraLensRetractedDialogController}`);
    if (this.cameraLensRetractedDialogController) {
      this.cameraLensRetractedDialogController?.close();
      this.cameraLensRetractedDialogController = null;
      this.showLensRetractedDialog();
      return;
    }
  }

  private cameraErrorDialogShow(errorCode: number): void {
    // 频繁切换镜头
    if (errorCode === CameraErrorCode.DEVICE_FREQUENTLY_SWITCHED) {
      TipService.getInstance().showTip($r('app.string.operate_frequently', 4), 3000, true);
      return;
    }
    if (this.isPicker) {
      HiLog.i(TAG, 'Ignore the errorCode for picker.')
      return;
    }
    // 恒星镜头异常收回 picker不弹窗
    if (errorCode === CameraErrorCode.CAMERA_LENS_RETRACTED) {
      this.showLensRetractedDialog();
      return;
    }
    let isBackground: boolean | undefined = AppStorage.get<boolean>('isBackground');
    let isActive: boolean = power.isActive();
    let isLocked: boolean = screenLock.isLocked();
    HiLog.i(TAG, `isBackground: ${isBackground}, isActive: ${isActive}, isLocked: ${isLocked}`);
    if (isBackground || !isActive || isLocked) {
      HiLog.i(TAG, 'Ignore the errorCode.');
      return;
    }
    this.cameraErrorDialogController?.close();
    this.isShowCameraError = false;
    HiLog.i(TAG, `errorCode == ${errorCode}`);
    this.createCameraErrorDialog(errorCode);
    this.cameraErrorDialogController?.open();
    this.isShowCameraError = true;
  }

  private locationDialogShow(isToSettingPermission: boolean, data?: RestoreDialogConfirmData): void {
    HiLog.i(TAG, `DialogShow: ${data}, SettingPermission: ${isToSettingPermission}，fromModul: ${data?.scene}}`);
    this.isToSettingPermission = isToSettingPermission;
    this.geoScene = data?.scene;
    if (((data?.restoreConfirmFlag || isToSettingPermission) && !this.isPicker && !data?.isRequestOnSetting &&
      !this.isPortraitBeautyDialogOpen)) {
      this.createLocationDialog(data?.scene);
      this.locationDialogController?.open();
      this.isDialogShow = true;
    }
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
    this.exitCameraTimerId = setTimeout((): void => {
      this.terminateCamera();
    }, OVER_HOT_EXIT_CAMERA_DELAY);
  }

  private hilogUxComponentStatus(): void {
    HiLog.i(TAG, `ux build status, ${this.firstLevelLoaded}.`);
    HiLog.i(TAG,
      `TabBar Show Status:${this.getTabBarVisible()},${Math.min(this.immersiveOpacity, this.tabBarOpacity)}`);
    HiLog.i(TAG, `ModeBar Show Status:${this.isModeBarVisible()}`);
    HiLog.i(TAG, `FootBar Show Status:${this.isFootBarVisible()}`);
    HiLog.i(TAG, `TreasureBox Show Status:${this.isDefaultTreasureVisible()},${this.treasureBoxOpacity}`);
  }

  private directionChange(): void {
    HiLog.i(TAG, 'directionChange.');
    this.hilogUxComponentStatus();
    this.reOpenLocationConfirmDialog();
    this.reOpenExposureConfirmDialog();
    this.reOpenExitFlashDialog();
    this.reOpenLightPaintingDialog();
    this.reOpenPortraitBeautyDialog();
    this.reOpenCameraErrorDialog();
    if (this.cameraLensRetractedDialogController) {
      this.showLensRetractedDialog();
    }
    this.tabViewPosition = this.getTimeLapseTabPosition();
    if (this.mDirection === WindowDirection.LEFT) {
      this.rotateAngle = 270;
    } else if (this.mDirection === WindowDirection.RIGHT) {
      this.rotateAngle = 90;
    } else {
      this.rotateAngle = 0;
    }
  }

  private reOpenExitFlashDialog(): void {
    if (this.mDirection === WindowDirection.BOTTOM || !this.isShowExitFlash) {
      return;
    }
    this.isShowExitFlash = false;
    TipService.getInstance().showTip($r('app.string.device_hot_flash_off_tips'), 3000, true);
  }

  private reOpenExposureConfirmDialog(): void {
    if (this.mDirection === WindowDirection.BOTTOM || !this.isShowExposure) {
      return;
    }
    this.clearDialogTimerId();
    this.exposureConfirmDialogController?.close();
    this.isShowExposure = false;
    this.createExposureConfirmDialog();
    this.mTimerId = setTimeout((): void => {
      this.exposureConfirmDialogController?.open();
      this.isShowExposure = true;
    }, 150);
  }

  private reOpenCameraErrorDialog(): void {
    if (this.mDirection === WindowDirection.BOTTOM || !this.isShowCameraError) {
      return;
    }
    this.clearDialogTimerId();
    this.cameraErrorDialogController?.close();
    this.isShowCameraError = false;
    this.createCameraErrorDialog(this.errorCode);
    this.mTimerId = setTimeout((): void => {
      this.cameraErrorDialogController?.open();
      this.isShowCameraError = true;
    }, 250);
  }

  private reOpenLocationConfirmDialog(): void {
    if (this.mDirection === WindowDirection.BOTTOM || !this.isDialogShow) {
      return;
    }
    this.clearDialogTimerId();
    this.locationDialogController?.close();
    this.isDialogShow = false;
    this.createLocationDialog(this.geoScene);
    this.mTimerId = setTimeout((): void => {
      this.locationDialogController?.open();
      this.isDialogShow = true;
    }, 150);
  }

  private reOpenLightPaintingDialog(): void {
    if (this.mDirection === WindowDirection.BOTTOM || !this.isLightPaintingDialogOpen ||
      !this.state.isLightPaintingFlashShow) {
      return;
    }
    this.clearDialogTimerId();
    this.mTimerId = setTimeout(() => {
      this.lightPaintingDialogController?.open();
      this.isLightPaintingDialogOpen = true;
    }, 150);
  }

  private reOpenPortraitBeautyDialog(): void {
    if (!this.isPortraitBeautyDialogOpen ||
    this.checkIsPortraitBeautyLoaded() || this.isShowSemiCollapsed) {
      return;
    }
    this.clearDialogTimerId();
    this.portraitBeautyDialogController?.close();
    this.isPortraitBeautyDialogOpen = false;
    this.mTimerId = setTimeout(() => {
      this.portraitBeautyDialogController?.open();
      this.isPortraitBeautyDialogOpen = true;
    }, 150);
  }

  private clearDialogTimerId(): void {
    if (this.mTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.mTimerId);
      this.mTimerId = Number.MIN_VALUE;
    }
    if (this.exitCameraTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.exitCameraTimerId);
      this.exitCameraTimerId = Number.MIN_VALUE;
    }
  }

  private onBackground(): void {
    HiLog.i(TAG, 'onBackground.');
    RestartService.getInstance().cancelRestart();
    this.locationDialogController?.close();
    this.exposureConfirmDialogController?.close();
    this.exitCameraDialogController?.close();
    this.lightPaintingDialogController?.close();
    this.portraitBeautyDialogController?.close();
    this.cameraErrorDialogController?.close();
    this.cameraLensRetractedDialogController?.close();
    this.cameraLensRetractedDialogController = null;
    this.isDialogShow = false;
    this.showTimer = false;
    this.showLightPaintingTimer = false;
    this.isShowExitFlash = false;
    this.isShowExitCamera = false;
    this.isLowBatteryTipShowed = false;
    this.isShowCameraError = false;
    this.errorCode = 0; //clear errorCode
    this.clearDialogTimerId();
    this.isShowBlackView = false;
    this.isForeground = false;
    this.isShowIntroLottie = false;
  }

  private onForeground(): void {
    if (!this.isOpen && this.modeBarOpacity === 0) {
      this.modeBarOpacity = 1;
    }
    this.initializeIsDialogLoaded();
    this.isShowBlackView = false;
    this.isForeground = true;
  }

  private updateSavePowerModeState(data: SavePowerModeActionData) {
    HiLog.i(TAG, `Save power mode state: ${data.isDuringSavePowerMode}`);
    if (data.isDuringSavePowerMode) {
      this.exposureConfirmDialogController?.close();
      this.cameraErrorDialogController?.close();
      this.locationDialogController?.close();
      this.exitCameraDialogController?.close();
      this.lightPaintingDialogController?.close();
      this.customFilterDialogController?.close();
      this.cameraLensRetractedDialogController?.close();
      this.cameraLensRetractedDialogController = null;
      this.isLightPaintingDialogOpen = false;
      this.isShowCameraError = false;
      this.isShowExposure = false;
      this.isShowExitFlash = false;
      this.isShowExitCamera = false;
      this.isLowBatteryTipShowed = false;
      this.isCustomFilterDialogOpen = false;
      if (this.isDialogShow) {
        this.isDialogShow = false;
        this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
      }
    }
  }

  private clearDialog() {
    this.exposureConfirmDialogController?.close();
    this.cameraErrorDialogController?.close();
    this.locationDialogController?.close();
    this.exitCameraDialogController?.close();
    this.lightPaintingDialogController?.close();
    this.cameraLensRetractedDialogController?.close();
    this.cameraLensRetractedDialogController = null;
    this.isLightPaintingDialogOpen = false;
    this.isShowCameraError = false;
    this.isDialogShow = false;
    this.isShowExposure = false;
    this.isShowExitFlash = false;
    this.isShowExitCamera = false;
    this.isLowBatteryTipShowed = false;
    this.isShowModeIntroCardEntry = false;
  }

  private updateTimeLapseTimerState(shouldHide: boolean) {
    this.isTimeLapseHideTimer = this.isTimelapseFront || shouldHide;
  }

  private uxInit(): void {
    this.isStart = true;
    HiLog.i(TAG, `uxInit begin, window size height: ${this.windowHeight}, width: ${this.windowWidth}.`);
    this.layoutService.calLayoutRuleParam(this.windowWidth, this.windowHeight);
    this.layoutService.changePreviewPosition(this.xComponentWidth, this.xComponentHeight);
    this.footBarPosition = this.layoutService.footBarPosition;
    this.zoomPosition = this.layoutService.zoomPosition;
    if (this.modeBarPosition !== this.layoutService.modeBarPosition) {
      if (!this.isOpen) {
        this.modeBarOpacity = 1;
      }
      this.modeBarPosition = this.layoutService.modeBarPosition
    }
    this.arrowPosition = this.layoutService.arrowPosition;
    this.tabBarPosition = this.layoutService.tabBarPosition;
    if (this.windowStatus === window.WindowStatusType.FLOATING &&
      this.windowHeight / this.windowWidth < AnimSpecifications.NEW_FLOAT_WINDOW_RATIO) {
      this.tabBarPosition = AnimSpecifications.NEW_FLOAT_WINDOW_TOP_OFFSET; // 悬浮态tabBar上边距
    }
    this.compoMargin = this.layoutService.compoMargin;
    if (!this.isShowLandscape && !this.isShowSemiCollapsed && !this.state.isShowPageView &&
      WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FULL_SCREEN &&
    AppStorage.get<boolean>('isShowPhotoBrowser')) { //直板机而且设置页没显示
      this.mTimerId = setTimeout(() => {
        this.isShowBlackView = DisplayService.getInstance().isHorizontal();
        HiLog.i(TAG, `uxInit black mask isShow:${this.isShowBlackView}`);
      }, 300);
    }
    this.updateZoomPosition();
  }

  private updateZoomPosition(): void {
    HiLog.i(TAG, 'on change preview size anim begin.');
    let roulette: number;
    this.zoomPosition = this.layoutService.zoomPosition;
    roulette = this.layoutService.rouletteZoomPosition;
    if (this.rouletteZoomPosition === 0) {
      this.isNeedPlayZoomTransAnim = false;
      this.isNeedPlayParamBarTransAnim = false;
    }
    this.rouletteZoomPosition = this.getZoomPosition(roulette);
    if (this.rouletteZoomPosition + this.zoomTranslate + ZOOM_VIEW_HEIGHT + 12 > this.footBarPosition) {
      this.zoomTranslate = this.footBarPosition - this.rouletteZoomPosition - ZOOM_VIEW_HEIGHT - 12;
    }
    HiLog.i(TAG, `on change preview size anim end. zoomPosition: ${this.zoomPosition}`);
  }

  private getZoomPosition(roulette: number): number {
    if (this.isVdeLandscape) {
      return (roulette + 80 >
        (this.modeBarPosition + 2)) ? this.zoomPosition :
        roulette;
    }
    return (roulette + 80 >=
      (false ? this.zoomPosition + 35 : this.modeBarPosition)) ? this.zoomPosition : roulette;
  }

  private volumeKeySubscribeOrNot(): void {
    HiLog.i(TAG, `isAnyDialogOpening: ${this.isAnyDialogOpening}`);
    if (this.isAnyDialogOpening) {
      HiLog.i(TAG, `volumeKeySubscribeOrNot: unsubscribe volumeKey`);
      this.volumeService.volumeKeyUnsubscribe();
    } else {
      HiLog.i(TAG, `volumeKeySubscribeOrNot: subscribe volumeKey`);
      this.volumeService.volumeKeySubscribe();
    }
  }

  private updateIsAnyDialogOpening(): void {
    this.isAnyDialogOpening =
      this.isDialogShow || this.isShowCameraError || this.isShowExitFlash || this.isShowExitCamera ||
      this.isShowExposure || this.isLightPaintingDialogOpen || this.isPortraitBeautyDialogOpen;
  }

  private videoStateOnChange(): void {
    HiLog.i(TAG, `videoStateOnChange videoState:${this.videoState}.`);
    if (this.videoState === RecordingState.STARTING) {
      if (this.state.treasureBoxCollapsState) {
        this.treasureBoxOpacity = 0;
        this.modeBarOpacity = 0;
      } else {
        this.treasureBoxOpacity = 0;
        this.modeBarOpacity = 1;
      }
      this.recordStartAnim(false);
      if (!this.isHalfCollapsLEM) {
        this.mAction.closeTreasureBox();
      }
    } else if (this.videoState === RecordingState.STOPPING) {
      this.recordEndAnim(false);
    }
  }

  private recordStartAnim(isPro: boolean): void {
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
      this.setZoomTranslate(isPro);
    });
  }

  private recordEndAnim(isPro: boolean): void {
    this.treasureBoxOpacity = 0;
    this.modeBarOpacity = 0;
    this.showModeBar = true;
    this.setZoomTranslate(false);
    animateToImmediately({
      duration: AnimSpecifications.ANIM_VIDEO_START_TRANSLATE_DURATION,
      delay: isPro ? 0 : AnimSpecifications.ANIM_VIDEO_START_TRANSLATE_DURATION,
      curve: Curve.Sharp,
      onFinish: () => {
        this.showModeBar = true;
      }
    }, () => {
      this.treasureBoxOpacity = 1;
      this.modeBarOpacity = 1;
      this.zoomTranslate = 0;
    });
  }

  private setZoomTranslate(isPro: boolean): void {
    if (!(this.isShowLowAngleShotView && this.isVdeSemiCollapsed)) {
      this.zoomTranslate = this.footBarPosition - ZOOM_VIEW_HEIGHT - 12 - this.zoomPosition;
    }
    if (this.mode === ModeType.PHOTO) {
      this.zoomTranslate = 0;
    }
    if (isPro) {
      if (!(this.isShowLowAngleShotView && this.isVdeSemiCollapsed)) {
        this.zoomTranslate = this.zoomTranslate - 60;
      }
    }
  }

  private showMoreChanged(data: MorePageStatus): void {
    if (data.isShowMorePage) {
      this.isShowTextInfo = false;
      if (this.isHalfCollapsLEM) {
        this.mAction.closeTreasureBox();
      }
      animateToImmediately({
        curve: Curve.Sharp,
        duration: 150
      }, () => {
        this.tabBarOpacity = 0;
      });
    } else {
      if (this.skipOpenTreasureBox) {
        this.skipOpenTreasureBox = false;
        return;
      }
      this.isShowTextInfo = true;
      if (this.isHalfCollapsLEM) {
        setTimeout((): void => {
          this.mAction.openTreasureBox();
        }, 200);
      }
      animateToImmediately({
        curve: Curve.Sharp,
        duration: 150,
        delay: 650
      }, () => {
        this.tabBarOpacity = 1;
      });
    }
  }

  private isShowLongExposureCaptureInfo(showLongExposureInfo: boolean): void {
    HiLog.i(TAG, 'isShowLongExposureInfo: ' + showLongExposureInfo);
    this.isShowLongExposureInfo = showLongExposureInfo;
  }

  private onAbilityBackground(): void {
    HiLog.i(TAG, 'onAbilityBackground');
    if (this.isShowFlipTipView) {
      DisplayService.getInstance().setCollapsStatusLocked(false);
    }
  }

  private timeLapse(data: ShowParm): void {
    this.showModeBar = data.showModeBar;
  }

  private prosonChange(data: proSonChangeNumberData): void {
    this.prosonNumber = data.iconId;
  }

  private getTimeLapseTabPosition(): TabPosition {
    HiLog.i(TAG, `getTimeLapseTabPosition : ${this.isOpen}.`);
    if (this.mDirection === WindowDirection.RIGHT) {
      return {
        y: this.isOpen ? this.layoutService.footBarPosition - this.state.xComponentWidth - 20 :
          this.layoutService.footBarPosition - this.state.xComponentWidth + MODE_BAR_HEIGHT - 10,
        x: this.state.xComponentWidth / 2 - 30
      }

    } else if (this.mDirection === WindowDirection.LEFT) {
      return {
        y: this.isOpen ? this.layoutService.footBarPosition - this.state.xComponentWidth - 20 :
          this.layoutService.footBarPosition - this.state.xComponentWidth + MODE_BAR_HEIGHT - 10,
        x: -this.state.xComponentWidth / 2 + 30
      }
    }
    return {
      y: TAB_BAR_HEIGHT + 17,
      x: 0
    }
  }

  private updateLumation(data: LumationConfirmData): void {
    this.lumationValue = data.info;
  }

  private setTreasureBoxUncollapsAnimation() {
    this.tabViewPosition = this.getTimeLapseTabPosition();
    HiLog.i(TAG, `setTreasureBoxUncollapsAnimation : ${JSON.stringify(this.tabViewPosition)}.`);
  }

  private createExposureConfirmDialog(): void {
    this.exposureConfirmDialogController = new CustomDialogController({
      builder: ConfirmDialogView({
        cancel: () => {
          this.isShowExposure = false;
          HiLog.i(TAG, 'closeExposureDialogConfirm ConfirmDialogView cancel');
        },
        confirm: () => {
          this.isShowExposure = false;
        },
        title: $r('app.string.recover_underexposure_dialog_need_title'),
        description: this.lumationValue < 0.098 ? $r('app.string.recover_underexposure_dialog_need_content') :
          $r('app.string.recover_overexposed_dialog_need_content'),
        cancelText: $r('app.string.m_CANCEL'),
        confirmText: $r('app.string.m_Confirm'),
        fixedRotateAngle: this.rotateAngle,
        currentDirection: this.mDirection,
        followSystemLocation: false,
        isHdr: this.isHdr
      }),
      autoCancel: false,
      customStyle: true,
      maskColor: '#66000000',
      cancel: () => {
        this.isDialogShow = false;
      },
      alignment: DialogAlignment.Center,
      offset: { dx: 0, dy: this.isVdeSemiCollapsed ? 170 : 0 },
      onWillDismiss: (dismissContentCoverAction: DismissContentCoverAction) => {
        this.onWillDismissExposureConfirmDialog(dismissContentCoverAction);
      }
    });
  }

  private onWillDismissExposureConfirmDialog(dismissContentCoverAction: DismissContentCoverAction): void {
    if (dismissContentCoverAction.reason === DismissReason.PRESS_BACK) {
      this.exposureConfirmDialogController?.close();
      this.isShowExposure = false;
    }
  }

  private getZoomVisible(): number {
    if (this.showPicker) {
      return Visibility.Hidden;
    }
    if (this.isCustomFilterImmersive) {
      return Visibility.Visible;
    }
    if (!(this.prosonNumber === -1 || this.prosonNumber === 0)) {
      return Visibility.Hidden;
    }

    // 非变焦组件引起的沉浸式模式
    if (this.immersiveUIType !== UIOperationType.ZOOM_BAR && this.immersiveOpacity === 0) {
      if (this.isCustomFilterImmersive) {
        return Visibility.Visible;
      }
      return Visibility.Hidden;
    }
    // 更多模式
    if (this.isShowMorePage) {
      return Visibility.Hidden;
    }
    // ExtendBar展示
    if (this.state.isShowExtendBar) {
      return Visibility.Hidden;
    }
    // 切模式启流成功后更改zoomView显示判断
    if (this.state.cameraRunningState === CameraRunningState.STARTED && this.showZoomView) {
      this.showZoomView = false;
    }
    // 非手机的前置
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT && !DeviceInfo.isPhone()) {
      return Visibility.Hidden;
    }
    // 长曝光状态进入沉浸式拍照
    if (this.isNightShutting) {
      return Visibility.Hidden;
    }

    this.specialModeZoomBarVisible = true;
    return Visibility.Visible;
  }

  private getParamVisible(): number {
    if (this.state.zoomState !== ZoomStateType.QUICK_ZOOM) {
      return Visibility.Hidden;
    }
    if (!(this.prosonNumber === -1 || this.prosonNumber === 0)) {
      return Visibility.Hidden;
    }
    if (this.isLemCollaps) {
      return Visibility.Hidden;
    }
    if (this.immersiveOpacity === 0) {
      if (this.isCustomFilterImmersive) {
        return Visibility.Visible;
      }
      return Visibility.Hidden;
    }
    // 更多模式
    if (this.isShowMorePage) {
      return Visibility.Hidden;
    }

    // 切模式或者切前后置相机启动未完成
    if (this.state.cameraRunningState !== CameraRunningState.STARTED && this.showParamBar && this.isChangeMode) {
      return Visibility.Hidden;
    }

    // 切模式启流成功后更改ParamBar显示判断
    if (this.state.cameraRunningState === CameraRunningState.STARTED && this.showParamBar) {
      this.showParamBar = false;
    }

    return Visibility.Visible;
  }

  private getTabBarVisible(): Visibility {
    return !this.isDownSuperSlowBtn && !this.isShowMorePage &&
      !this.isLemCollaps && !this.isHalfCollapsLEM && !this.showPicker ? Visibility.Visible : Visibility.Hidden;
  }

  private timeLapseToolBarVisible(): Visibility {
    return this.isShowToolBar &&
      (this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM) &&
      !this.isLemCollaps && !this.isHalfCollapsLEM ? Visibility.Visible : Visibility.Hidden;
  }

  private getTreasureBoxPositionY(): number {
    if (this.isShowLowAngleShotView && this.isVdeSemiCollapsed) {
      return 48;
    }
    return this.windowHeight / 2 - 8;
  }

  private onPreviewFrameStart(data: PreviewFrameStartData): void {
    this.isPreviewFrameStart = data.isPreviewFrameStart;
  }

  private getBigTextPosition(): PositionType {
    HiLog.i(TAG, 'getBigTextPosition 0.')
    let bigTextLineHeight: number = 64;
    let marginBottom1to1PreviewArea: number = 80;
    let marginBottomHalfCollapsPreviewArea: number = 180;
    if ((this.mode === ModeType.VIDEO) && this.isVertical()
      && this.videoState >= RecordingState.RECORDING) {
      HiLog.i(TAG, 'getBigTextPosition 1.')
      let positionY: number = this.layoutService.previewPosition16to9 +
        this.layoutService.get16to9PreviewHeight(this.windowWidth, this.windowHeight) / 2 - bigTextLineHeight / 2;
      return { x: 0, y: this.isShowLowAngleShotView && this.isVdeSemiCollapsed ? positionY + 30 : positionY };
    }
    const status: window.WindowStatusType = WindowService.getInstance().getWindowStatus();
    const isHorizontal: Boolean = DisplayService.getInstance().isHorizontal();
    if (status === window.WindowStatusType.FLOATING) {
      return { x: 0, y: FLOATING_BIG_TEXT_POSITION - 24 };
    }
    if (status === window.WindowStatusType.SPLIT_SCREEN && isHorizontal) {
      return { x: 0, y: SPLIT_BIG_TEXT_POSITION };
    }
    if (this.mDirection !== WindowDirection.RIGHT && this.mDirection !== WindowDirection.LEFT) {
      let positionY: number =
        this.layoutService.previewPosition1to1 + this.state.xComponentWidth / 2 - bigTextLineHeight / 2;
      if (this.isHalfCollapsLEM) {
        positionY = this.layoutService.previewPosition1to1 + this.state.xComponentWidth -
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

  private getWidthAndHeight(): number | string {
    if (this.isPSDCollapsed) {
      return DISPLAY_SCREEN_SIZE_PSD;
    } else if (this.isLemCollaps) {
      return DISPLAY_SCREEN_SIZE_LEM;
    } else {
      return '100%';
    }
  }

  private onClickCallback(): (() => void) | undefined {
    if (!this.enableScreenReader) {
      return undefined;
    }
    return () => {
      if (this.isShowActionMenu && this.enableScreenReader) {
        this.isShowActionMenu = false;
        AccessibilityUtils.sendFocusAccessibilityEvent('MoreButton')
      }
    }
  }

  private updateExtendBarPosition(): void {
    if (this.isVdeSemiCollapsed) {
      this.extendBarPosition -= 10;
      return;
    }
    if (this.isHalfCollapsLEM) {
      this.extendBarPosition += LEM_HALF_COLLAPS_EXTEND_BAR_OFFSET;
      return;
    } else {
      this.extendBarPosition -= LEM_HALF_COLLAPS_EXTEND_BAR_OFFSET;
      return;
    }
  }

  private getXComponentScale(): ScaleOptions {
    let scale: ScaleOptions = { x: 1, y: 1 };
    return scale;
  }

  private getPreviewGestureAreaWidth(): number {
    if (this.isLemCollaps || this.isPSDCollapsed) {
      return this.windowWidth;
    }
    return this.xComponentWidth;
  }

  private getPreviewGestureAreaHeight(): number {
    if (this.isLemCollaps || this.isPSDCollapsed) {
      return this.windowHeight;
    }
    return this.xComponentHeight;
  }

  private getPreviewGestureAreaPosition(): PositionType {
    if (this.isLemCollaps || this.isPSDCollapsed) {
      return { x: 0, y: 0 };
    }
    return this.previewAnimatePosition;
  }

  build() {
    Stack({ alignContent: (this.isLemCollaps || this.isPSDCollapsed ? Alignment.Center : Alignment.Top) }) {
      if (this.firstLevelLoaded) {
        this.PreviewGestureBuilder();
      }

      if (this.isPSDCollapsed && !this.isShowTimedShot && !this.isShowtimeLapse &&
        this.videoState === RecordingState.READY && this.isShowCollapsSet) {
        this.setViewBuilder();
      }

      this.tabBarBuilder();

      if (this.firstLevelLoaded) {
        this.bigTextBuilder();
      }

      this.zoomBarBuilder();

      if (this.firstLevelLoaded) {
        if (!this.isCustomFilterImmersive) {
          this.videoTimerBuilder();
        }
        this.paramBarBuilder();
      }

      this.modeBarBuilder(); // 模式切换
      this.footBarBuilder(); // 触发modeBar动效
      this.treasureBoxBuilder(); // 百宝箱

      if (this.firstLevelLoaded) {
        this.TreasureBoxGestureGroundBuilder();
        if (!this.isPicker) {
        }
        this.TipBoxBuilder();
        this.floatingShutterBuilder();
        this.pickerViewBuilder();
        this.captureShowBlackBuilder();
        this.zoomTextChangeBuilder();
      }
    }
    .width(this.getWidthAndHeight())
    .height(this.getWidthAndHeight())
    .key(ComponentIdKeys.PAGE_STACK_14)
    .rotate({ angle: this.isLemCollaps || this.isPSDCollapsed ? 180 : 0 })
    .accessibilityGroup((this.isShowActionMenu && this.enableScreenReader))
    .accessibilityText((this.isShowActionMenu && this.enableScreenReader) ? $r('sys.string.icon_back') : null)
    .accessibilityLevel((this.isShowActionMenu && this.enableScreenReader) ? CommonConstants.ACCESSIBILITY_LEVEL_YES :
      CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .onClick(this.onClickCallback())
  }

  @Builder
  PreviewGestureBuilder() {
    PreviewGestureArea({
      immersiveUIType: this.immersiveUIType,
      isHdr: this.isHdr
    })
      .width(this.getPreviewGestureAreaWidth())
      .height(this.getPreviewGestureAreaHeight())
      .position(this.getPreviewGestureAreaPosition())
      .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  blackViewBuilder(): void {
    Blank().width('100%').height('100%').backgroundColor(Color.Black).zIndex(ZIndex.TOP)
  }

  // Builder组件按顺序创建开始标识符
  @Builder
  tabBarBuilder(): void {
    Column() {
      TabBar(
        {
          isCustomFilterImmersiveImmediately: this.isCustomFilterImmersiveImmediately,
          isCustomFilterButtonShow: this.isCustomFilterImmersive,
          isPicker: this.isPicker,
          isHdr: this.isHdr
        },
      )
    }
    .width('100%')
    .opacity(Math.min(this.immersiveOpacity, this.tabBarOpacity))
    .height(TAB_BAR_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .position({ y: this.tabBarPosition })
    .zIndex(ZIndex.TOP)
    .visibility(this.getTabBarVisible())
  }

  @Builder
  bigTextBuilder(): void {
    if (this.state.isShowBigText && !this.isShowMorePage) {
      Stack({ alignContent: Alignment.Top }) {
        BigText({
          isHdr: this.isHdr
        })
      }
      .hitTestBehavior(HitTestMode.Transparent)
      .position(this.getBigTextPosition())
      .zIndex(ZIndex.TOP)
    }
  }

  @Builder
  videoTimerBuilder(): void {
    if (this.showTimer && !this.isSuperSlowMotion && !this.isTimelapseFront && !this.isTimeLapseHideTimer) {
      VideoTimer({
        startVideoRecording: this.startVideoRecording,
        isHdr: this.isHdr
      })
        .opacity(this.timerOpacity)
        .hitTestBehavior(HitTestMode.None)
    }
  }

  private getVlogViewVisible(): Visibility {
    // 进入沉浸式隐藏
    if (this.immersiveUIType !== UIOperationType.VLOG_BAR && this.immersiveOpacity === 0) {
      return Visibility.Hidden;
    }
    // 进入更多页隐藏
    if (this.isShowMorePage) {
      return Visibility.Hidden;
    }
    return Visibility.Visible;
  }

  private getParamBarOffsetY(): number {
    if (this.isVdeSemiCollapsed) {
      return this.isShowLowAngleShotView ? this.zoomPosition + 3 + 56 : this.zoomPosition + 3;
    } else if (this.isHalfCollapsLEM) {
      return this.zoomPosition + 58;
    }
    return this.rouletteZoomPosition;
  }

  @Builder
  paramBarBuilder(): void {
    // 在开启屏幕朗读的时候 半折态 专业模式不需要此组件 此组件会遮挡专业模式下组件的聚焦
    if (this.state.isShowParamBar && !(this.enableScreenReader && this.isHalfCollapsLEM) &&
      !this.isCustomFilterImmersiveMoving && this.getParamVisible() === Visibility.Visible) {
      ParamBar({
        isPicker: this.isPicker,
        isCustomFilterImmersive: this.isCustomFilterImmersive,
        isHdr: this.isHdr,
        isHorizontalFloatingWindow: this.isStitchingHorizontalFloating
      })
        .height(this.isVdeLandscape ? 60 : 80)
        .offset({
          y: this.getParamBarOffsetY()
        })
        .enabled(this.state.cameraRunningState === CameraRunningState.STARTED)
        .animation(this.getParamBarAnimation())
        .opacity(this.immersiveUIType === UIOperationType.PARAM_BAR ? 1 : this.immersiveOpacity)
        .translate(this.getTranslateY())
        .hitTestBehavior(HitTestMode.Transparent)
        .zIndex(this.isHalfCollapsLEM ? 2 : 0)
        .width(this.isVdeLandscape ? '95%' : '100%')
        .padding(this.getParamBarPadding())
        .transition(TransitionEffect.OPACITY.animation({ duration: 150, curve: Curve.Sharp }))
    }
  }

  private getParamBarPadding(): Padding {
    if (this.isCustomFilterImmersiveMoving) {
      return { left: 0, right: 0 };
    }
    if (this.isCustomFilterImmersive && this.thumbnailViewArea.globalPosition.x != undefined) {
      let CustomFilterImmersiveScale = 0.85
      let paramIconWidth =
        SystemLanguageUtil.isRTL() ? PARAM_ELEMENT_SIDE_LENGTH_RTL : PARAM_ELEMENT_SIDE_LENGTH
      let paramIconOffset = SystemLanguageUtil.isRTL() ? PARAM_ICON_OFFSET_RTL : PARAM_ICON_OFFSET
      const screenWidth = getStates().get<number>('windowReducer', 'windowWidth');
      let thumbnailViewCurrentPositionX = (Number(this.thumbnailViewArea.globalPosition.x) / screenWidth) *
        (screenWidth * CustomFilterImmersiveScale) + screenWidth * (1 - CustomFilterImmersiveScale) / 2;


      let padding = SystemLanguageUtil.isRTL() ?
        screenWidth - (thumbnailViewCurrentPositionX +
          (Number(this.thumbnailViewArea.width) / 2 * CustomFilterImmersiveScale) +
          paramIconOffset + screenWidth * (1 - 0.95) / 2 + paramIconWidth / 2) :
        thumbnailViewCurrentPositionX +
          (Number(this.thumbnailViewArea.width) / 2 * CustomFilterImmersiveScale) -
          paramIconOffset - screenWidth * (1 - 0.95) / 2 - paramIconWidth / 2 - PARAM_BAR_CUSTOM_FILTER_OFFSET;
      return { left: padding, right: padding };
    }
    return { left: 0, right: 0 };
  }

  private getTranslateY(): TranslateOptions {
    if (this.isCustomFilterImmersiveMoving) {
      return { y: this.zoomTranslate }
    }
    if (this.isCustomFilterImmersive) {
      return {
        y: this.getFootBarPositionY() + this.footBarTrans + this.footBarOffsetY + FOOT_BAR_HEIGHT * (1 -
          this.footBarCustomFilterScale * this.footBarScale) / 2 - this.footBarOffsetY * (1 - this.footBarScale) -
          PARAM_BAR_HEIGHT - this.getParamBarOffsetY() - INDICATOR_OFFSET
      }
    }
    return { y: this.zoomTranslate }
  }

  private getZoomBarAnimation(): AnimateParam | null {
    if (this.windowStatus === window.WindowStatusType.FLOATING) {
      this.preStatusIsFloatingOfZoomBar = true;
      return null;
    }
    // 冷启动相机初始化时不加次判断会导致变焦环从上到下位移，后续Zoom的动效需要使用animateToImmediately重写，而不是.animation。
    if (!this.isNeedPlayZoomTransAnim) {
      this.isNeedPlayZoomTransAnim = true;
      return null;
    }
    if (this.isShowLemAnimate) {
      return this.getLemAnimateParam();
    }
    if (this.isShowLowAngleAnim) {
      return { duration: 350, curve: Curves.interpolatingSpring(0, 1, 228, 30) };
    } else {
      let delay: number = 200;
      if (this.preStatusIsFloatingOfZoomBar) {
        this.preStatusIsFloatingOfZoomBar = false;
        delay = 50; // 和modeBar同步
      }
      return {
        duration: 200,
        delay: this.isBetweenBlurAnimDoneAndAnimEnd ? 0 : delay,
        curve: AnimSpecifications.ANIM_PREVIEW_AREA_UP_OR_DOWN,
        iterations: this.getZoomVisible() === Visibility.Hidden ? 0 : 1,
        playMode: PlayMode.Normal
      }
    }
  }

  private getParamBarAnimation(): AnimateParam | null {
    if (this.windowStatus === window.WindowStatusType.FLOATING) {
      this.preStatusIsFloatingOfParamBar = true;
      return null;
    }
    // 冷启动相机初始化时不加次判断会导致变焦环从上到下位移，后续Zoom的动效需要使用animateToImmediately重写，而不是.animation。
    if (!this.isNeedPlayParamBarTransAnim) {
      this.isNeedPlayParamBarTransAnim = true;
      return null;
    }
    if (this.isShowLemAnimate) {
      return this.getLemAnimateParam();
    }
    if (this.isShowLowAngleAnim) {
      return { duration: 350, curve: Curves.interpolatingSpring(0, 1, 228, 30) };
    } else {
      let delay: number = 200;
      if (this.preStatusIsFloatingOfParamBar) {
        this.preStatusIsFloatingOfParamBar = false;
        delay = 50; // 和modeBar同步
      }
      return {
        duration: 200,
        delay: this.isBetweenBlurAnimDoneAndAnimEnd ? 0 : delay,
        curve: AnimSpecifications.ANIM_PREVIEW_AREA_UP_OR_DOWN,
        iterations: this.getParamVisible() === Visibility.Hidden ? 0 : 1,
        playMode: PlayMode.Normal
      }
    }
  }

  @Builder
  zoomBarBuilder(): void {
    RouletteZoomView({
      zoomWidth: this.state.xComponentWidth,
      zoomHeight: 150,
      drawHeight: AdaptiveLayoutService.getInstance().preview4to3Height * 0.16,
      isHdr: this.isHdr,
      isCustomFilterImmersive: this.isCustomFilterImmersive,
      layoutService: this.layoutService,
      currentFootBarLocation: this.currentFootBarLocation,
      zoomLocation: Number(this.getZoomOffset().y) + this.zoomTranslate
    })
      .height(this.isVdeLandscape ? VDE_ZOOM_VIEW_HEIGHT : ZOOM_VIEW_HEIGHT)
      .offset(this.getZoomOffset())
      .animation(this.getZoomBarAnimation())
      .translate({ y: this.isLemCollaps ? 0 : this.zoomTranslate })
      .opacity(this.immersiveUIType === UIOperationType.ZOOM_BAR ? 1 : this.immersiveOpacity)
      .hitTestBehavior(HitTestMode.Transparent)
      .visibility(this.getZoomVisible())
      .scale({
        x: this.rouletteZoomViewScale,
        y: this.rouletteZoomViewScale,
        centerX: '50%',
        centerY: '50%',
      })
      .zIndex(this.isHalfCollapsLEM ? 2 : (ZIndex.TOP))
      .transition(TransitionEffect.OPACITY.animation({ duration: 150, curve: Curve.Sharp }))
  }

  private updateHalfCollapsedModeBarPosition(): void {
    this.layoutService.calLayoutRuleParam(this.windowWidth, this.windowHeight);
    const newPositionWhenShowLowAngle: number = this.windowHeight / 2 - MODE_BAR_HEIGHT - 22;
    const collapsStatus: display.FoldStatus = DisplayService.getInstance().getCollapsStatus();
    const isHalfCollapsed: boolean = collapsStatus === display.FoldStatus.FOLD_STATUS_HALF_FOLDED;
    let offset: number = this.isVdeSemiCollapsed ? VDE_HALF_COLLAPS_MODE_BAR_OFFSET : LEM_HALF_COLLAPS_MODE_BAR_OFFSET;
    const newPositionWhenOnlyHalfCollapsed: number = this.layoutService.modeBarPosition + offset;
    let newModeBarPosition: number = this.layoutService.modeBarPosition;
    if (isHalfCollapsed) {
      newModeBarPosition = this.isShowLowAngleShotView ? newPositionWhenShowLowAngle : newPositionWhenOnlyHalfCollapsed;
    }
    if (newModeBarPosition > this.windowHeight / 2 && this.layoutService.modeBarPosition > this.windowHeight / 2) {
      animateToImmediately({
        curve: Curve.Friction, duration: 300, delay: 50
      }, () => {
        this.modeBarPosition = newModeBarPosition;
      });
    } else {
      animateToImmediately({
        curve: Curve.Sharp, duration: 150, onFinish: () => {
          if (this.modeBarOpacity === 0) {
            this.modeBarPosition = newModeBarPosition;
            this.showModeBarAnim();
          }
        }
      }, () => {
        this.modeBarOpacity = 0;
      });
    }
  }

  private showModeBarAnim(): void {
    animateToImmediately({
      curve: Curve.Sharp, duration: 150, delay: 50,
    }, () => {
      this.modeBarOpacity = 1;
    });
  }

  private hideAndShowModeBarAnim(): void {
    if (!this.isVdeSemiCollapsed) {
      return;
    }
    this.changePreviewPositionAnim();
    this.modeBarOpacity = 1;
    this.treasureBoxOpacity = 1;
    this.updateHalfCollapsedModeBarPosition();
    animateToImmediately({
      curve: Curve.Sharp, duration: 150, onFinish: () => {
        this.treasureBoxPositionY = this.getTreasureBoxPositionY();
      }
    }, () => {
      this.treasureBoxOpacity = 0;
    });
    animateToImmediately({
      curve: Curve.Sharp, duration: 150, delay: 200,
    }, () => {
      this.treasureBoxOpacity = 1;
    });
  }

  private getModeBarPositionY(): number {
    if (this.isVdeSemiCollapsed && this.isShowLowAngleShotView) {
      return this.windowHeight / 2 - MODE_BAR_HEIGHT - 22;
    }
    return this.modeBarPosition;
  }

  private updateLayout(): void {
    if (this.windowStatus === window.WindowStatusType.FLOATING && this.windowStateCache ===
    window.WindowStatusType.FULL_SCREEN) {
      this.customFilterStackCardVieWPositionY = this.customFilterStackCardVieWPositionY -
        CARD_FLOAT_VIEW_DEFAULT_OFFSET;
    } else if (this.windowStatus === window.WindowStatusType.FULL_SCREEN && this.windowStateCache ===
    window.WindowStatusType.FLOATING) {
      this.customFilterStackCardVieWPositionY = this.customFilterStackCardVieWPositionY +
        CARD_FLOAT_VIEW_DEFAULT_OFFSET;
    }
    if (this.getIsSetImmersiveCollaps()) {
      AppStorage.setOrCreate('CustomFilterImmersiveCollaps', this.isCustomFilterImmersive);
    }
    this.onFootBarPositionChange();
    this.windowStateCache = this.windowStatus;
    HiLog.i(TAG, 'window State ' + this.windowStatus + ' as ' + this.customFilterStackCardVieWPositionY);
  }

  private getIsSetImmersiveCollaps() {
    return false;
    if (this.windowStatus === window.WindowStatusType.FLOATING ||
      this.windowStatus === window.WindowStatusType.SPLIT_SCREEN) {
      return true;
    }
    if (this.windowStatus === window.WindowStatusType.FULL_SCREEN && (this.windowStateCache ===
    window.WindowStatusType.FLOATING ||
      this.windowStateCache === window.WindowStatusType.SPLIT_SCREEN)) {
      return true;
    }
    return false;
  }

  private async defaultIndexOnStarted(data: CameraStartTypeStruct): Promise<void> {
    this.isShowNightSubModePipSurface = false;
    if (data.type !== CameraStartType.COLD_START) {
      HiLog.i(TAG,
        `defaultIndexOnStarted load so, type:${data.type}, isCustomFilterStarted:${this.isCustomFilterStarted}`);
      if (data.type === CameraStartType.WARM_START_WITH_MODE_AND_POS && this.isCustomFilterStarted) {
        HiLog.i(TAG, 'defaultIndexOnStarted openCustomFilterFromApp');
      }
      if (!((data.type === CameraStartType.WARM_START || data.type === CameraStartType.WARM_START_WITH_MODE_AND_POS) &&
        !this.isCustomFilterStarted)) { // 热启动且之前冷启动未加载so时，需加载so
        HiLog.i(TAG, 'defaultIndexOnStarted return');
        return;
      }
    }
  }

  @Builder
  modeBarBuilder(): void {
    ModeBar({ isPicker: this.isPicker })
      .width('100%')
      .height(MODE_BAR_HEIGHT)
      .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
      .hitTestBehavior(this.isHalfCollapsLEM ? HitTestMode.Transparent : HitTestMode.Default)
      .scale({ x: this.isShowMorePage ? 1 : this.modeBarScale, y: this.isShowMorePage ? 1 : this.modeBarScale })
      .opacity(this.isShowMorePage ? 1 : this.modeBarOpacity)
      .visibility(this.isModeBarVisible() ? Visibility.Visible : Visibility.Hidden)
      .enabled(this.isModeBarEnable())
      .position({ y: this.modeBarPosition })
      .animation(this.modeBarAnimation())
  }

  private isModeBarVisible(): boolean {
    if (this.isDownSuperSlowBtn || this.isEditMorePage || this.isLemCollaps || this.isImmersive || this.showPicker) {
      return false;
    }
    return (this.immersiveUIType === UIOperationType.MODE_BAR || this.immersiveOpacity !== 0) &&
    this.showModeBar &&
      (!this.isCustomFilterImmersive || this.isPicker);
  }

  private isModeBarEnable(): boolean {
    return (!this.isCustomFilterImmersive || this.isPicker) && (this.videoState === RecordingState.READY) &&
      !this.isImmersive && !this.isShowtimeLapse && !this.isProShuttering;
  }

  private getFootBarPositionY(): number {
    if (this.isVdeSemiCollapsed) {
      return this.footBarPosition + 30;
    }
    if (this.isHalfCollapsLEM) {
      return this.footBarPosition + 45;
    }
    if (this.isVdeLandscape) {
      return this.footBarPosition;
    }
    return this.footBarPosition;
  }

  @Builder
  footBarBuilder(): void {
    Stack() {
      FootBar({
        isPicker: this.isPicker,
        footBarScale: this.footBarScale,
        isCustomFilterImmersive: this.isCustomFilterImmersiveImmediately,
        footBarTrans: this.footBarTrans,
        staticFootBarTrans: -MODE_BAR_HEIGHT - this.compoMargin,
        thumbnailViewArea: this.thumbnailViewArea,
        offsetX: this.footBarOffsetX,
        offsetY: this.footBarOffsetY,
        isHdr: this.isHdr,
        previewAnimatePosition: this.previewAnimatePosition,
        previewHeight: this.xComponentHeight,
        previewWidth: this.xComponentWidth,
        lineHeight: this.customFilterTopLineHeight,
        footBarPosition: this.getFootBarPositionY(),
        customFilterStackCardVieWPositionY: this.customFilterStackCardVieWPositionY
      })
        .margin({ left: $r('sys.float.padding_level10'), right: $r('sys.float.padding_level10') })
        .zIndex(ZIndex.TOP)
        .hitTestBehavior(HitTestMode.None)
    }
    .width('100%')
    .height(FOOT_BAR_HEIGHT)
    .position({ y: this.getFootBarPositionY() })
    .animation(this.isShowLemAnimate ? this.getLemAnimateParam() :
      {
        delay: 0,
        tempo: 0,
        duration: 0,
        iterations: 0
      })
    .translate({ y: this.footBarTrans })
    .hitTestBehavior(this.isHalfCollapsLEM ? HitTestMode.Transparent : HitTestMode.None)
    .visibility(this.isFootBarVisible() ? Visibility.Visible : Visibility.Hidden)
  }

  @Builder
  TreasureBoxGestureGroundBuilder(): void {
    TreasureBoxGestureGround({
      isCustomFilterImmersive: this.isCustomFilterImmersive,
      isPicker: this.isPicker
    })
      .width('100%')
      .height(this.treasureBoxGestureGroundHeight)
      .position({ y: this.treasureBoxGestureGroundPosition })
      .visibility((!this.isDownSuperSlowBtn && !this.isLemCollaps &&
        ((!this.isShowMorePage && this.immersiveOpacity !== 0))) ?
        Visibility.Visible : Visibility.Hidden)
      .hitTestBehavior(HitTestMode.Transparent)
  }

  private setTreasureBoxGestureGroundUX(): void {
    this.treasureBoxGestureGroundHeight =
      FOOT_BAR_HEIGHT + (this.arrowPosition - this.getFootBarPositionY()) - this.footBarTrans;
    this.treasureBoxGestureGroundPosition =
      this.treasureBoxGestureGroundPosition = this.getFootBarPositionY() + this.footBarTrans;
  }

  private isFootBarVisible(): boolean {
    if (this.showPicker) {
      return false;
    }
    if (this.isShowMorePage || this.isLemCollaps) {
      return false;
    }
    if (this.isShowtimeLapse && this.immersiveOpacity === 0) {
      return false;
    }
    if (this.isShowTimedShot && this.immersiveOpacity === 0) {
      return false;
    }
    return this.immersiveUIType === UIOperationType.FOOT_BAR || this.immersiveUIType === UIOperationType.LR_SWIPE ||
      this.immersiveUIType === UIOperationType.NULL || this.immersiveOpacity !== 0 || this.isPanoramaFootBarShow;
  }

  private isDefaultTreasureVisible(): boolean {
    return (!this.showPicker && !this.isDownSuperSlowBtn && !this.isLemCollaps &&
      ((!this.isShowMorePage && this.immersiveOpacity !== 0)));
  }

  @Builder
  treasureBoxBuilder(): void {
    if (this.isHalfCollapsLEM) {
      Column() {
        TreasureBox({
          uncollaps: (data: boolean) => this.uncollapsTreasureBox(data),
          isHdr: this.isHdr,
          treasureBoxAnimationState: this.treasureBoxAnimationState
        })
          .opacity(this.treasureBoxOpacity)
          .onAppear((): void => {
            if ((this.isHalfCollapsLEM) && !this.isShowMorePage) {
              this.mAction.openTreasureBox();
            }
          })
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .position({ y: this.isShowLowAngleAnim ? this.treasureBoxPositionY : this.getTreasureBoxPositionY() })
      .animation(this.isShowLemAnimate ? this.getLemAnimateParam() :
        {
          delay: 0,
          tempo: 0,
          duration: 0,
          iterations: 0
        })
      .visibility(this.isTreasureBoxVisible())
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    } else {
      Column() {
        TreasureBox({
          uncollaps: (data: boolean) => this.uncollapsTreasureBox(data),
          isHdr: this.isHdr,
          treasureBoxAnimationState: this.treasureBoxAnimationState
        })
          .opacity(this.treasureBoxOpacity)
      }
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .position({ y: this.arrowPosition })
      .visibility(this.isDefaultTreasureVisible() ? Visibility.Visible : Visibility.Hidden)
    }
  }

  private isTreasureBoxVisible(): Visibility {
    if (this.isDownSuperSlowBtn || this.isShowMorePage || this.isShowTreasureBox || this.immersiveOpacity === 0 ||
    this.showPicker) {
      return Visibility.Hidden;
    }
    return Visibility.Visible;
  }

  @Builder
  TipBoxBuilder(): void {
    // 非以下场景显示tip：沉浸式下的变焦（录像模式除外）以及倒计时拍照
    if (!(this.immersiveOpacity == 0 &&
      ((this.immersiveUIType === UIOperationType.ZOOM_BAR ||
        this.immersiveUIType === UIOperationType.PINCH_ZOOM) && this.mode !== ModeType.VIDEO ||
        this.immersiveUIType === UIOperationType.TIMELAPSE)) || TipService.getInstance().isAlwaysShowTip()) {
      TipBox({
        isShowTextInfo: this.isShowTextInfo,
        isShowLongExposureInfo: this.isShowLongExposureInfo,
        isHdr: this.isHdr,
      })
    }
  }

  @Builder
  blackPageBuilder(): void {
    if (this.state.isShowPageView) {
      Column() { // 黑色背景 防止设置页旋转的时候漏相机首页
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .backgroundColor(Color.Black)
    }
  }

  @Builder
  floatingShutterBuilder(): void {
    if (this.state.isFloatingShutterShow && !this.isShowMorePage && !this.isLemCollaps && !this.showPicker) {
      FloatingShutterButton({
        isPicker: this.isPicker,
        footBarPosition: this.footBarPosition,
        isHdr: this.isHdr
      })
        .zIndex(ZIndex.SAVE_POWER_MODE)
        .position({ x: 0, y: 0 })
        .height(0)
        .visibility(this.immersiveUIType === UIOperationType.FOOT_BAR || this.immersiveOpacity !== 0 ?
          Visibility.Visible : Visibility.Hidden)
    }
  }

  @Builder
  pickerViewBuilder(): void {
    if (this.isPicker) {
      PickerView({
        previewPosition: this.previewAnimatePosition.y,
        footBarPosition: this.footBarPosition,
        tabBarPosition: this.tabBarPosition,
        modeBarPosition: this.modeBarPosition
      })
        .zIndex(ZIndex.TOP)
        .visibility(this.showPicker ? Visibility.Visible : Visibility.Hidden)
    }
  }

  @Builder
  captureShowBlackBuilder(): void {
    if (this.state.isShowBlack) {
      Column() {
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .zIndex(ZIndex.TOP)
    }
  }

  private zoomTextChangeBuilderHeight(): number {
    if (this.isVdeSemiCollapsed) {
      return (this.windowHeight / 2) - FOOT_BAR_HEIGHT - VDE_SEMI_COLLAPSED_ZOOM_TEXT_CHANGE;
    }
    return this.windowHeight / 2;
  }

  @Builder
  zoomTextChangeBuilder(): void {
    if (this.isHalfCollapsLEM && !(this.isVdeSemiCollapsed && this.isShowLowAngleShotView) && !this.isShowMorePage) {
      Stack() {
      }
      .width(this.windowWidth)
      .height(this.zoomTextChangeBuilderHeight())
      .hitTestBehavior(HitTestMode.Transparent)
      .position({ y: this.windowHeight / 2 })
      .zIndex(ZIndex.BOTTOM)
      .clip(true)
      .backgroundColor(this.zoomTextBackgroundColor())
      .enabled(this.state.uiEnable)
      .onTouch((event: TouchEvent) => {
        this.onTouchZoomText(event);
      })
      .onClick(() => {
        if (this.isHalfCollapsLEM && this.state.isShowExtendBar) {
          this.mAction.previewClicked();
        }
      })
      .gesture(
        GestureGroup(
          GestureMode.Exclusive,
          PinchGesture({ fingers: 2, distance: 1 })
            .onActionStart((event?: GestureEvent) => {
              if (!event || this.isShowMorePage) {
                return;
              }
              return this.pinchGestureStart(event);
            })
            .onActionUpdate((event?: GestureEvent) => {
              if (!event || this.isShowMorePage) {
                return;
              }
              return this.pinchGestureUpdate(event);
            })
            .onActionEnd((event?: GestureEvent) => {
              if (!event || this.isShowMorePage) {
                return;
              }
              return this.pinchGestureEnd(event);
            })
            .onActionCancel((event?: GestureEvent) => {
              if (!event || this.isShowMorePage) {
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
              if (!this.isShowtimeLapse && this.state.videoState === RecordingState.READY) {
                this.mAction.swipeChangeMode(1);
              }
            }),
          PanGesture({
            fingers: 1,
            direction: this.isShowLandscape ? PanDirection.Down : PanDirection.Right,
            distance: 10
          })
            .onActionStart((): void => {
              if (!this.isShowtimeLapse && this.state.videoState === RecordingState.READY) {
                this.mAction.swipeChangeMode(-1);
              }
            })
        )
      )
    }
  }

  private onFunctionalAreaClicked(): void {
    if (this.state.isShowExtendBar) {
      this.mAction.previewClicked();
    }
  }

  @Builder
  gestureBuilder() {
    if (this.isHalfCollapsLEM && !this.isShowLowAngleShotView) {
      Stack() {
      }
      .width(this.windowWidth)
      .height(this.windowHeight / 2)
      .position({ x: 0, y: this.windowHeight / 2 })
      .hitTestBehavior(HitTestMode.Transparent)
      .clip(true)
      .backgroundColor(Color.Transparent)
      .enabled(!this.isDownSuperSlowBtn)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
      .gesture(
        GestureGroup(
          GestureMode.Exclusive,
          TapGesture({ fingers: 1, count: 1 })
            .onAction(() => this.onFunctionalAreaClicked())
        )
      )
    }
  }

  private zoomTextBackgroundColor(): ResourceColor {
    if (this.isShowRingLightView && this.isVdeSemiCollapsed && this.isShowLowAngleShotView) {
      return Color.Transparent;
    }
    return this.isShowRingLightView ? Color.White : Color.Transparent;
  }

  private uncollapsTreasureBox(isOpen: boolean): void {
    if (this.needOpen) {
      return;
    }
    if (isOpen && !this.isHalfCollapsLEM) {
      this.treasureBoxAnimationState = 0;
      animateToImmediately({
        duration: 150, curve: Curve.Sharp, onFinish: () => {
          this.treasureBoxAnimationState = -1;
        },
      }, () => {
        this.modeBarOpacity = 0;
      });
      animateToImmediately({
        duration: 500, curve: Curve.Friction
      }, () => {
        this.modeBarScale = 0.8;
        this.setFootBarTrans();
        this.footBarScale = 0.9;
        this.footBarOffsetX = 10;
        this.setTreasureBoxGestureGroundUX();
      });
    } else {
      this.treasureBoxAnimationState = 1;
      animateToImmediately({
        duration: 100,
        curve: Curve.Sharp,
        onFinish: () => {
          this.treasureBoxAnimationState = -1;
        },
        delay: 50
      }, () => {
        if (this.videoState !== RecordingState.RECORDING && this.videoState !== RecordingState.STARTING) {
          this.modeBarOpacity = 1;
        }
      });
      animateToImmediately({
        duration: 500,
        curve: Curve.Friction,
        delay: 50
      }, () => {
        this.modeBarScale = 1;
        this.footBarTrans = 0;
        this.footBarScale = 1;
        this.footBarOffsetX = 0;
        this.setTreasureBoxGestureGroundUX();
      });
    }
  }

  private setFootBarTrans(): void {
    let previewPosition4to3Bottom = this.layoutService.previewPosition4to3 + (this.windowWidth * 4 / 3); //4:3预览区底部的定位
    let arrowButtonUpPosition = this.arrowPosition - this.layoutService.arrowUpDistance; // 百宝箱拉起之后顶部的定位
    let centerMargin =
      (arrowButtonUpPosition - previewPosition4to3Bottom - (FOOT_BAR_HEIGHT * 0.9)) / 2; //footBar居中后离预览区底部的间距
    this.footBarTrans = this.layoutService.modeBarPosition - this.footBarPosition; //footBar组件上方位置-modeBar组件上方位置

    // 解决悬浮窗比例1:1时，打开白宝箱后footbar与黑边发生重叠问题
    // 悬浮窗打开百宝箱后的footbar位置向上调整
    if (WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) {
      this.footBarTrans = -MODE_BAR_HEIGHT - this.compoMargin - FLOATING_FOOTBARTRANS_OFFSET;
    }
    // vde设备布局特殊，需隔离设置
    if (this.isVdeLandscape) {
      this.footBarTrans = -MODE_BAR_HEIGHT - this.compoMargin;
    }
    HiLog.i(TAG, `modeBarPosition : ${JSON.stringify(this.layoutService.modeBarPosition)}.`);
    HiLog.i(TAG, `footBarPosition : ${JSON.stringify(this.footBarPosition)}.`);
    HiLog.i(TAG, `setFootBarTrans : ${JSON.stringify(this.footBarTrans)}.`);
  }

  private uncollapsCustomFilterStackCardView(isOpen?: boolean): void {
    HiLog.i(TAG, 'uncollapsCustomFilterStackCardView this.isOpen： ' + this.isOpen + 'isopen' + isOpen);
    if (this.isOpen) {
      // 开百宝箱
      if (isOpen) {
        this.openCustomFilterStackCardAnim();
      } else {
        this.closeCustomFilterStackCardAnim();
      }
    } else {
      // 关百宝箱
      if (isOpen) {
        this.openCustomFilterStackCardAnim();
      } else {
        this.closeCustomFilterStackCardAnim();
      }
    }
  }

  private openCustomFilterStackCardAnim(): void {
    HiLog.i(TAG, 'openCustomFilterStackCardAnim');
    if (this.isVdeSemiCollapsed) {
      return;
    }
    if (this.isCustomFilterImmersiveMoving) {
      clearTimeout(this.closingTimeoutIndex);
    }
    this.isCustomFilterImmersive = true;
    this.isCustomFilterImmersiveImmediately = true;
    this.isCustomFilterImmersiveMoving = true;
    animateToImmediately({ duration: 150, curve: Curve.Sharp }, () => {
      this.modeBarOpacity = 0;
    });
    setTimeout(() => {
      this.isCustomFilterImmersiveMoving = false;
    }, 400);
    // 打开沉浸式
    animateToImmediately({ duration: 200, curve: Curve.Sharp, delay: 50 }, () => { // 透明度
      this.customFilterStackCardViewOpacity = 1;
    });
    animateToImmediately({ duration: 400, curve: Curve.Friction, delay: 0 }, () => { // 调色盘展开，快捷变焦缩放
      this.customFilterStackCardVieWScaleX = 1;
      this.customFilterStackCardVieWScaleY = 1;
      this.rouletteZoomViewScale = 0.9;
    });
  }

  private closeCustomFilterStackCardAnim(): void {
    HiLog.i(TAG, 'closeCustomFilterStackCardAnim this.isCustomFilterImmersive：' + this.isCustomFilterImmersive);
    if (!this.isCustomFilterImmersive) {
      return;
    }
    if (this.mode !== ModeType.PHOTO && OutputOperation.isPanPhotoOutput(this.mode)) {
      this.isCustomFilterImmersive = false;
      this.isCustomFilterImmersiveMoving = false;
      this.isCustomFilterImmersiveImmediately = false;
      this.closingTimeoutIndex = -1;
      this.customFilterStackCardViewOpacity = 0;
      this.customFilterStackCardVieWScaleX = CARD_VIEW_DEFAULT_SCALE;
      this.customFilterStackCardVieWScaleY = CARD_VIEW_DEFAULT_SCALE;
      this.rouletteZoomViewScale = 1;
      return;
    }
    this.isCustomFilterImmersiveMoving = true;
    clearTimeout(this.closingTimeoutIndex);
    let isCustomFilterImmersiveClosed = false;
    if (AppStorage.get('CustomFilterImmersiveCollaps')) {
      this.isCustomFilterImmersive = false;
      isCustomFilterImmersiveClosed = true;
      HiLog.i(TAG, 'isCustomFilterImmersiveClosed set true');
    }
    this.closingTimeoutIndex = setTimeout(() => {
      if (!isCustomFilterImmersiveClosed) {
        this.isCustomFilterImmersive = false;
      }
      this.isCustomFilterImmersiveMoving = false;
      this.closingTimeoutIndex = -1;
    }, 400);
    this.isCustomFilterImmersiveImmediately = false;
    if (!this.isOpen) {
      animateToImmediately({ duration: 150, curve: Curve.Sharp }, () => {
        this.modeBarOpacity = 1;
      });
    }
    animateToImmediately({ duration: 200, curve: Curve.Sharp, delay: 0 }, () => {
      this.customFilterStackCardViewOpacity = 0;
    });
    animateToImmediately({ duration: 400, curve: Curve.Friction, delay: 0 }, () => {
      this.customFilterStackCardVieWScaleX = CARD_VIEW_DEFAULT_SCALE;
      this.customFilterStackCardVieWScaleY = CARD_VIEW_DEFAULT_SCALE;
      this.customFilterStackCardVieWPositionY = CARD_VIEW_DEFAULT_OFFSET;
      this.rouletteZoomViewScale = 1;
    });
  }

  private getZoomOffset(): Position {
    if (this.isLemCollaps && !AppStorage.get('isBackground')) {
      return { y: 226 };
    }
    if (this.isVdeSemiCollapsed) {
      return { y: this.isShowLowAngleShotView ? VDE_SEMI_ZOOM_OFFSET + 3 + 56 : VDE_SEMI_ZOOM_OFFSET + 3 }
    }
    return { y: this.rouletteZoomPosition };
  }

  private getLemAnimateParam(): AnimateParam {
    return { delay: 50, duration: 300, iterations: 1 };
  }

  private checkXComponentLock(): void {
    HiLog.i(TAG, 'checkXComponentLock begin.');
    WindowService.getInstance().lockXComponentSurface();
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
      ZoomOperation.getRingZoomUIState(this.state.cameraPosition, this.mode)?.quickZoomValArr.length <= 1;
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT &&
      (this.isShowLandscape)) {
      return;
    }
    if (this.state.isShowBigText || this.isShowtimeLapse || isHideZoomView || this.isShowTimedShot) {
      return;
    }
    this.mAction.changeFunctionValue(FunctionId.ZOOM,
      { zoomRatio: undefined, isPrepareZoom: true } as ZoomFuncValueStruct);
    clearTimeout(this.pinchGestureTimer);
    this.baseZoom = this.zoomRatio;
    this.frontPinchCanUpdate = true;
    HiLog.i(TAG, 'pinchGestureStart X.');
  }

  private pinchGestureUpdate(event: GestureEvent): void {
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT &&
      (this.isShowLandscape)) {
      return;
    }
    HiLog.i(TAG, 'pinchGestureUpdate invoke, setZoomRatio.');
    const isHideZoomView: boolean =
      ZoomOperation.getRingZoomUIState(this.state.cameraPosition, this.mode)?.quickZoomValArr.length <= 1;
    if (this.state.isShowBigText || this.isShowtimeLapse || isHideZoomView || this.isShowTimedShot) {
      return;
    }
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
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
    if (zoomRatio > this.state.maxZoomRatio) {
      zoomRatio = this.state.maxZoomRatio;
    }
    if (zoomRatio < this.state.minZoomRatio) {
      zoomRatio = this.state.minZoomRatio;
    }
    zoomRatio = Number.parseFloat(zoomRatio.toFixed(3));
    if (zoomRatio !== this.zoomRatio) {
      this.mAction.changeFunctionValue(FunctionId.ZOOM,
        { zoomRatio: zoomRatio } as ZoomFuncValueStruct);
    }
    let preZoomRatio = this.zoomRatio.toFixed(1);
    let curZoomRatio = zoomRatio.toFixed(1);
    if ((curZoomRatio !== preZoomRatio) &&
      (this.state.videoState === RecordingState.READY) && DeviceInfo.isPcAndTablet()) {
      VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_FOCUS_EFFECT_ID);
    }
    HiLog.i(TAG, 'pinchGestureUpdate end.');
  }

  private pinchGestureEnd(event: GestureEvent): void {
    HiLog.i(TAG, 'pinchGestureEnd E.');
    const isHideZoomView: boolean =
      ZoomOperation.getRingZoomUIState(this.state.cameraPosition, this.mode)?.quickZoomValArr.length <= 1;
    // 捏合过程中，触发倒计时拍照 倒计时过程中停止捏合 只需更新showpinch为false即可 不用退出沉浸式
    if (this.state.isShowPinch && (this.isShowtimeLapse || this.isShowTimedShot)) {
      this.mAction.updateShowPinch(false);
      return;
    }
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT &&
      (this.isShowLandscape)) {
      return;
    }
    if (this.state.isShowBigText || this.isShowtimeLapse || isHideZoomView || this.isShowTimedShot) {
      return;
    }
    this.mAction.changeFunctionValue(FunctionId.ZOOM,
      { zoomRatio: undefined, isUnprepareZoom: true } as ZoomFuncValueStruct);
    this.mAction.isEnterImmersive(false);
    this.mAction.updateShowPinch(false);
    HiLog.i(TAG, 'pinchGestureEnd X.');
  }

  private isShowModeIntroCardEntryBuilder(): boolean {
    if (this.state.videoState !== RecordingState.READY && this.state.videoState !== RecordingState.STOPPING) {
      return false;
    }
    return this.isShowModeIntroCardEntry && !this.isShowMorePage && !this.isPicker;
  }

  //专业模式沉浸式
  private isEnterLrSwipeImmersive(data: ImmersiveActionData): void {
    let mImmersiveUIType: UIOperationType = data.mainTrigCompo ?? UIOperationType.NULL;
    let json: ImmersiveActionData = JSON.parse(JSON.stringify(data));
    if (json.isImmersive !== undefined && mImmersiveUIType === UIOperationType.PRO_BAR) {
      this.isImmersivePro = json.isImmersive;
    }
  }

  private modeBarAnimation(): AnimationOptions | undefined {
    if (this.isShowLowAngleAnim) {
      return undefined;
    }
    if (this.treasureBoxAnimationState >= 0) {
      return undefined;
    }
    return this.isShowLemAnimate ? this.getLemAnimateParam() :
      this.isImmersivePro ? { delay: 0, duration: 80, iterations: 1 } :
        { delay: 0, duration: 190, iterations: 1 };
  }

  private hideIntroLottie(): void {
  }

  private persistIntroLottieValues(): void {
  }

  // 外屏设置按钮和设置ux显示
  @Builder
  setViewBuilder(): void {
    if (!this.isShowSetView && this.isPSDCollapsed) {
      Flex({
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center,
      }) {
        Image($r('app.media.treasure_box_setting'))
          .width(IMAGE_SIZE_20)
      }
      .width(COLLAPSED_SET_SIZE)
      .height(COLLAPSED_SET_SIZE)
      .aspectRatio(1)
      .position(this.getPosition())
      .enabled(this.state.uiEnable)
      .onClick(() => {
        this.isShowSetView = true;
      })
    }
  }

  getPosition(): Position {
    const isRTL: boolean = I18n.isRTL(I18n.System.getSystemLocale());
    if (isRTL) {
      return this.iconRotateAngle == COLLAPSED_ROTATE_180 ?
        { x: COLLAPSED_SET_Y, y: COLLAPSED_SET_Y } : { x: COLLAPSED_SET_X, y: COLLAPSED_SET_X };
    }
    return this.iconRotateAngle == COLLAPSED_ROTATE_180 ?
      { x: COLLAPSED_SET_X, y: COLLAPSED_SET_Y } : { x: COLLAPSED_SET_Y, y: COLLAPSED_SET_X }
  }

  private onWindowStatusChange(): void {
    if (WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FULL_SCREEN && this.isOpen &&
      !this.isHalfCollapsLEM) {
      this.footBarTrans = -MODE_BAR_HEIGHT - FOOT_BAR_TRANSLATE;
    }
  }

  windowSizeChange(changedPropertyName: string) {
  }
}