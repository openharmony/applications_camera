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

import lazy { Action, ActionData, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { Dispatch, OhCombinedState, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType'
import lazy {
  FunctionValueType,
  PositionType,
  proSonChangeNumberData,
  Size,
  XComponentSize,
  SavePowerModeActionData
} from '@ohos/common/src/main/ets/utils/types';
import lazy { RecordAction, RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { LandscapeFootBar } from './LandscapeFootBar';
import lazy { FOOT_BAR_HEIGHT } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService';
import lazy { BigScreenModeBar } from '@ohos/common/src/main/ets/component/ModeBar/bigScreen/BigScreenModeBar';
import lazy {
  MODE_BAR_HEIGHT,
  LANDSCAPE_TRANSVERSE_HEIGHT_SEMI_COLLAPSED
} from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService';
import lazy { VideoTimer } from '@ohos/common/src/main/ets/component/videoTimer/VideoTimer';
import lazy {
  LandscapeTreasureBox
} from '@ohos/common/src/main/ets/component/treasurebox/landscape/LandscapeTreasureBox';
import lazy {
  LANDSCAPE_TRANSVERSE_HEIGHT
} from '@ohos/common/src/main/ets/component/treasurebox/landscape/LandscapeTreasureBoxConfig';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { CaptureAction } from '@ohos/common/src/main/ets/function/capture/CaptureAction';
import lazy { LandscapePickerView } from './LandscapePickerView';
import camera from '@ohos.multimedia.camera';
import lazy { GAP_WITH_MODE_BAR, LandscapeParamBar } from './LandscapeParamBar';
import lazy { CameraRunningState } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy { LumationConfirmData, RestoreDialogConfirmData } from '../default/DefaultIndex';
import lazy {
  ConfirmDialogView
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/ConfirmDialogView';
import lazy { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import lazy {
  FloatingShutterButton
} from '@ohos/extend/src/main/ets/settingcommonfunc/floatingShutter/FloatingShutterButton';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { ZoomAction } from '@ohos/common/src/main/ets/function/zoombar/ZoomAction';
import lazy { FlashMode } from '@ohos/common/src/main/ets/function/enumbase/FlashMode';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { CameraProxy } from '@ohos/common/src/main/ets/camera/uithread/CameraProxy';
import lazy { AlertDialogView } from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/AlertDialogView';
import lazy { PropTag, PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { ChangeState, getStates, reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import Curves from '@ohos.curves';
import lazy { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { TimeLapseAction } from '@ohos/extend/src/main/ets/settingcommonfunc/timelapse/TimeLapseAction';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import lazy { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import lazy { BlurAnimateUtil } from '@ohos/common/src/main/ets/utils/BlurAnimateUtil';
import lazy { ZoomOperation } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import lazy { PhotoFormatMode } from '@ohos/common/src/main/ets/function/enumbase/PhotoFormatMode';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { RouletteZoomView } from '@ohos/common/src/main/ets/function/zoombar/RouletteZoomView';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { TipBox } from '@ohos/common/src/main/ets/component/tip/TipBox';
import lazy { OutputSwitcher } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcher';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { display, window } from '@kit.ArkUI';
import lazy {
  CameraErrorData,
  CameraErrorDialogView,
  CameraErrorDialogViewParams
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/CameraErrorDialogView'
import lazy { VolumeShutterService } from '@ohos/common/src/main/ets/service/volume/VolumeShutterService';
import lazy { RestartService } from '@ohos/common/src/main/ets/service/restart/RestartService';
import power from '@ohos.power';
import screenLock from '@ohos.screenLock';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy {
  AdaptiveLandscapeLayoutService,
  MIDDLE_COMPONENT_WIDTH,
  MODE_BAR_INNER_WIDTH_SEMI
} from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService';
import lazy { DisplayCalculator } from '@ohos/common/src/main/ets/component/xcomponent/DisplayCalculator';
import lottie, { AnimationItem } from '@ohos/lottie';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import lazy { FocusExposureService } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureService';
import lazy { FocusExposureAction } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureAction';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';
import lazy { FunctionActionType } from '@ohos/common/src/main/ets/redux/actions/FunctionActionType';
import lazy { FunctionConflictParamData } from '@ohos/common/src/main/ets/component/treasurebox/common/DataType';
import treasureBoxConfig from '@ohos/common/src/main/ets/component/treasurebox/default/TreasureBoxConfig';
import lazy { LogStyleMode } from '@ohos/common/src/main/ets/function/enumbase/LogStyleMode';
import lazy { PreviewActionType } from '@ohos/common/src/main/ets/redux/actions/PreviewActionType';
import lazy { PreviewAction } from '@ohos/common/src/main/ets/redux/actions/PreviewAction';
import lazy { CameraStartType } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy { CameraStartTypeStruct } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy { PreviewCustomFilterMasking } from './PreviewCustomFilterMasking';
import lazy { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import lazy { PreviewGestureArea } from '../preview/PreviewGestureArea';
import { ComponentSnapshotService } from '@ohos/common/src/main/ets/service/componentSnapshot/ComponentSnapshotService';

/* instrument ignore file */
const TAG: string = 'LandscapeIndex';

export const COMPONENT_WIDTH: number = 84;

export const COMPONENT_WIDTH_TRICOLLAPS: number = 96;

export const FULL_LENGTH: string = '100%';

export const FOOTER_BAR_ROW: number = 40;

export const MENU_OFFSET_X: number = 10;

export const MENU_OFFSET_Y_M: number = 15;

export const MENU_OFFSET_Y_G: number = 30;

export const MENU_OFFSET_Y_G_FRONT: number = 95;

export const MENU_OFFSET_Y_MAX_BACK: number = 280;

export const MENU_OFFSET_Y_MAX_BACK_LAND: number = 225;

export const MENU_OFFSET_Y_MAX_BACK_G: number = 260;

export const MENU_OFFSET_Y_MAX_FRONT_G: number = 350;

const FRONT_TIP_UNLOADED: number = 0;
const FRONT_TIP_APPEARING: number = 1;
const FRONT_TIP_LOADED: number = 2;

const ISO_CUTOFF_VALUE_JPG: number = 12800;

class TabPosition {
  public x: number = 0;
  public y: number = 0;
}

class ExposureModeStruct {
  public exposureMode: camera.ExposureMode = camera.ExposureMode.EXPOSURE_MODE_AUTO;
  public exposureValue: number = 0;
}

interface ProIsoValue {
  functionId: FunctionId,
  value: number
}

const SECOND_LEVEL_LOAD_DELAY: number = 110;
const PARAM_BAR_ROW: number = 92;
const MODE_BAR_BOTTOM_MARGIN: number = 60;
const EXTEND_BAR_HEIGHT: number = 398;
const ROTATE_ANGLE_90: number = 90;
const ROTATE_ANGLE_180: number = 180;
const COMPONENT_WIDTH_CURR: number = 56;
const TREASURE_BOX_ELEMENT_HEIGHT: number = 48;
const MARGIN_I_EXPOSURE: number = 12;
const MARGIN_I_EXPOSURE_TRICOLLAPS_HORIZONTAL: number = 26;
const MARGIN_I_EXPOSURE_TRICOLLAPS_VERTICAL: number = 160;
const DIALOG_SCREEN_MARGIN = 188;
const LIGHT_PAINTING_DIALOG_WIDTH: number = 336;
const LIGHT_PAINTING_DIALOG_HEIGHT: number = 350;
const PORTRAIT_BEAUTY_DIALOG_OFFSET_X: number = -30;
const SELFIESTICK_POSITION: PositionType = { x: 505, y: 131 };
const EYE_TIP_ANIM: number = 3000;
const CARD_VIEW_DEFAULT_OFFSET: number = 150;
const CARD_VIEW_DEFAULT_SCALE: number = 0.7;
const ZOOM_AREA_WIDTH_DEFAULT: number = 220;
const FOOT_BAR_NON_DRAG_WIDTH: number = 126;
const CARD_VIEW_MASKING_WIDTH: number = 15;
const HORIZON_OFFSET: number = 12; // 用于UX上避免进入火龙果沉浸式导致的截断
const CUSTOM_FILTER_CARD_LANDSCAPE_DEFAULT_WIDTH: number = 328;
const CUSTOM_FILTER_CARD_LANDSCAPE_DEFAULT_HEIGHT: number = 226;
const CUSTOM_FILTER_CARD_LANDSCAPE_BOTTOM_MARGIN: number = 60;
const MODE_BAR_ALIGNMENT_FOOT_BAR_X: number = 12; // 用于modebar对齐footbar
const MODE_BAR_OFF_LOCK_ROTATION_Y: number = 30;
const HIDE_ZOOM_BAR_MODE_LIST: ModeType[] = [];

class ZoomFuncValueStruct {
  public zoomRatio?: number = 1;
  public isPrepareZoom?: boolean = false;
  public isUnprepareZoom?: boolean = false;
}

class FocusModeStruct {
  public focusMode: camera.FocusMode = camera.FocusMode.FOCUS_MODE_AUTO;
  public focusPoint: camera.Point = { x: 0, y: 0 };
}

class StateStruct {
  public isShowBigText: boolean = false;
  public isShowPageView: boolean = false;
  public isFloatingShutterShow: boolean = false;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;
  public isShowParamBar: boolean = false;
  public isShowExtendBar: boolean = false;
  public cameraRunningState: CameraRunningState = CameraRunningState.UNINITIALIZED;
  public uiEnable: boolean = false;
  public videoState: RecordingState = RecordingState.READY;
  public tabSelector: FunctionId = FunctionId.NONE;
  public isShowPinch: boolean = false;
  public zoomRatio: number = 0;
  public minZoomRatio: number = 0;
  public maxZoomRatio: number = 0;
  public isShowFlipTipView: boolean = false;
  public isShowBackSelfiePopupTip: boolean = false;
  public isShowLowAngleShotView: boolean = false;
  public isColdStart: boolean = false;
  public isLightPaintingFlashTimerShow: boolean = false;
  public isLightPaintingFlashShow: boolean = false;
}

const TAB_BAR_HEIGHT: number = 30;

class ShowParm {
  public showModeBar: boolean = false;
}

interface PositionInfo {
  top?: number,
  right?: number,
  bottom?: number,
  left?: number,
}

class IndexDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
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

  public swipeChangeMode(swipe: number): void {
    this.mDispatch(Action.swipeChangeMode(swipe));
  }

  public previewClicked(): void {
    this.mDispatch(Action.previewClicked());
  }

  public updateIsShowParamBar(isShow: boolean): void {
    this.mDispatch(Action.updateIsShowParamBar(isShow));
  }

  public updateIsShowExtendBar(isShow: boolean): void {
    this.mDispatch(Action.updateIsShowExtendBar(isShow));
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

  public resetSaveModeTimer() {
    this.mDispatch(ContextAction.resetSaveModeTimer());
  }

  public showExtendBar(extendBarEffectView: FunctionId): void {
    this.mDispatch(Action.changeShowExtendComponent(extendBarEffectView));
    this.mDispatch(Action.updateIsShowParamBar(false));
    this.mDispatch(Action.updateIsShowExtendBar(true));
  }

  public proBarRecoveryAuto(): void {
    this.mDispatch(Action.proBarRecoveryAuto());
  }

  public confirmLocationTOSettingPermission(isRequestOnSetting: boolean): void {
    this.mDispatch(Action.confirmLocationTOSettingPermission(isRequestOnSetting));
  }

  public hideFocus(): void {
    this.mDispatch(FocusExposureAction.hideFocus());
  }

  public changeXComponentAuto(width: number, height: number): void {
    this.mDispatch(PreviewAction.changeXComponentAuto(width, height));
  }

  public closeTreasureBox(): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(false));
  }

  public proSonChangeState(value: number): void {
    this.mDispatch(Action.proSonChangeState(value));
  }
}

@Component
export struct LandscapeIndex {
  @State isCustomFilterStarted: boolean = false;
  @StorageLink('changeCustomFilterImmersiveImmediately') isCustomFilterImmersiveImmediately: boolean = false;
  @LocalStorageLink('changeCustomFilterImmersive') @Watch('customFilterImmersiveChange') isCustomFilterImmersive: boolean =
    false;
  @StorageLink('isShowStyleMenuChange') @Watch('updateStyleMenuAvoidOpacity') isShowStyleMenu: boolean = false;
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State state: StateStruct = new StateStruct();
  private mAction: IndexDispatcher = new IndexDispatcher();
  // 启动相关
  @State firstLevelLoaded: boolean = false;
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State @Watch('instantDirectionChange') mInstantDirection: WindowDirection = WindowDirection.TOP;
  @State videoState: RecordingState = RecordingState.READY;
  @State @Watch('onModeChange') mode: ModeType = ModeType.NONE;
  @State tempPreviewPosition: number = 0;
  @State showComponent: FunctionId = FunctionId.NONE;
  // ux位置适配
  @State isShowFunctionModule: boolean = true; //功能模块是否可见
  @State isVertical: boolean = true;
  @State treasureBoxHeight: number = LANDSCAPE_TRANSVERSE_HEIGHT;
  @LocalStorageLink('previewAnimatePosition') @Watch('previewPositionChange') previewAnimatePosition: PositionType =
    { x: 0, y: 0 }; //预览框动画效果定位
  @State zoomBarAnimatePosition: PositionType = { x: 0, y: 0 }; //变焦条动画效果定位
  @State footBarAnimatePosition: PositionType = { x: 0, y: 0 }; //缩略图,快门,前后置切换动画效果定位
  @State modeBarAnimatePosition: PositionType = { x: 0, y: 0 }; //拍照模式动画效果定位
  @State tBoxBarAnimatePosition: PositionType = { x: 0, y: 0 }; //百宝箱模式动画效果定位
  @State paramAnimatePosition: PositionType = { x: 0, y: 0 }; //美颜效果动画效果定位
  @State proBarAnimatePosition: PositionType = { x: 0, y: 0 }; //专业模式动画效果定位
  @State modeIntroCardEntryPosition: PositionType = { x: 0, y: 0 };
  @State barOpacityAnimate: number = 1;
  @State componentPosition: number = 0; //footBar modeBar位置
  @State zoomViewTopMargin: number = 0;
  @State zoomViewLeftMargin: number = 0;
  @State treasureBoxTopMargin: number = 0;
  @State treasureBoxLeftMargin: number = 0;
  @State footBarRightMargin: number = 0;
  @State modeBarTopMargin: number = 0;
  @State modeBarRightMargin: number = 0;
  @State paramBarPositionX: number = 0;
  @State extendBarPositionX: number = 0;
  @State professionBarPositionX: number = 0;
  @State professionBarPositionY: number = 0;
  @State modeIntroCardPositionX: number = 0;
  @State modeIntroCardPositionY: number = 0;
  @State lumationValue: number = 0.3;
  // 变焦条与paramBar组件显示判断
  @State showZoomView: boolean = false;
  @State showParamBar: boolean = false;
  @State showProfessionBar: boolean = false;
  @State @Watch('setTreasureBoxUncollapsAnimation') isOpen: boolean = false;
  @State rotateAngle: number = 0;
  @State iconRotateAngle: number = 0;
  @State isSupportMeteringModeFunc: boolean = false;
  // VideoTimer
  @State showTimer: boolean = false;
  @State showLightPaintingTimer: boolean = false;
  @State timerOpacity: number = 0;
  @State lightPaintingTimerOpacity: number = 0;
  @State @Watch('timerStateOnChange') videoTimerState: boolean = false;
  @State @Watch('lightPaintingTimerStateOnChange') lightPaintingTimerState: boolean = false;
  @State videoTimerPosition: number = 0;
  // 沉浸式
  @Prop immersiveUIType: UIOperationType = UIOperationType.NULL;
  @Prop immersiveOpacity: number = 1;
  @State isImmersive: boolean = false;
  // 获取手机大小
  @State @Watch('limitDragOffsetToLegal') pageWidth: number = 0;
  @State @Watch('updateCustomFilterCardYPos') pageHeight: number = 0;
  // Picker
  @State isPicker: boolean = false;
  @State isPreviewRatioSymmetric: boolean = false; //1:1、全屏为true，4:3为false，用于控制提示语位置
  @State isShowTextInfo: boolean = false;
  @State isShowPanoramaInfo: boolean = false;
  @State introductoryText: Resource | string = this.getDefaultTextSrc();
  @State isShowLongExposureInfo: boolean = false;
  @State showPicker: boolean = false;
  // 音量键订阅
  private volumeService: VolumeShutterService = VolumeShutterService.getInstance();
  @StorageLink('isAnyDialogOpening') @Watch('volumeKeySubscribeOrNot') isAnyDialogOpening: boolean = false;
  // 相机异常弹窗
  private cameraErrorDialogController: CustomDialogController | null = null;
  @State @Watch('updateIsAnyDialogOpening') isShowCameraError: boolean = false;
  private errorCode: number = 0;
  // 地理位置弹窗
  private locationDialogController: CustomDialogController | null = null;
  private exitCameraDialogController: CustomDialogController | null = null;
  private lightPaintingDialogController: CustomDialogController | null = null;
  private portraitBeautyDialogController: CustomDialogController | null = null;
  private customFilterDialogController: CustomDialogController | null = null;
  private session: UIExtensionContentSession | undefined = undefined;
  private isToSettingPermission: boolean = false;
  @State isShowMorePage: boolean = false;
  private layoutService: AdaptiveLandscapeLayoutService = AdaptiveLandscapeLayoutService.getInstance();
  @State @Watch('setBarAnimate') isShowSemiCollapsed: boolean = false;
  @State @Watch('xComponentWidthChange') xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;
  @State isEditMorePage: boolean = false;
  @State animateOpacity: number = 0;
  @State tabViewPosition: TabPosition = this.getTimeLapseTabPosition();
  @State zoomOpacity: number = 0;
  @State footOpacity: number = 0;
  @State modeOpacity: number = 0;
  @State paramOpacity: number = 0;
  @State extendOpacity: number = 0;
  private exposureConfirmDialogController: CustomDialogController | null = null;
  @StorageLink('showFilmingTime') showFilmingTime: boolean = false;
  @State showModeBar: boolean = true;
  @State prosonNumber: number = -1;
  private pinchGestureTimer: number = 0;
  private baseZoom: number = 0;
  private frontPinchCanUpdate: boolean = false;
  private readonly pinchToNextZoomScale = 1.25;
  private readonly pinchToPrevZoomScale = 0.75;
  @State isShowtimeLapse: boolean = false;
  @State isTimeLapseBarOpen: boolean = false;
  @State @Watch('dialogShowChange') @Watch('updateIsAnyDialogOpening') isDialogShow: boolean = false;
  @State @Watch('updateIsAnyDialogOpening') isShowExposure: boolean = false;
  @State @Watch('updateIsAnyDialogOpening') isShowExitFlash: boolean = false;
  @State isShowExitCamera: boolean = false;
  private isFirstTime: boolean = true;
  private mTimerId: number = Number.MIN_VALUE;
  @Prop isShowNightExposure: boolean = false;
  @StorageLink('isBackground') isBackground: boolean = false;
  private exitTimer: number = 5;
  // 慢动作相关
  @StorageLink('isDownSuperSlowBtnState') @Watch('superSlowRecordingAnim') isDownSuperSlowBtn: boolean = false;
  @StorageLink('slowRecordingCompVisible') slowRecordingCompVisible: boolean = true; // 超慢控制组件展示的动效变量
  @State isSuperSlowMotion: boolean = false;
  @State isTimelapseFront: boolean = false;
  // 小i弹窗相关
  @StorageLink('isModeIntroDialogLoaded') isModeIntroDialogLoaded: Map<ModeType, boolean> =
    new Map<ModeType, boolean>();
  @State isShowModeIntroCardEntry: boolean = false;
  @State isLightPaintingDialogLoaded: boolean = false;
  @State @Watch('updateIsAnyDialogOpening') isLightPaintingDialogOpen: boolean = false;
  @State @Watch('updateIsAnyDialogOpening') isPortraitBeautyDialogOpen: boolean = false;
  @State @Watch('updateIsAnyDialogOpening') isCustomFilterDialogOpen: boolean = false;
  @State isPortraitBeautyDialogLoaded: boolean = false;
  private lightPaintingLandscapeDialogWidth = 0;
  private lightPaintingLandscapeDialogHeight = 0;
  private lightPaintingSemiCollapsedDialogWidth = 0;
  private lightPaintingSemiCollapsedDialogHeight = 0;
  private panoramaTimer: number = Number.MIN_VALUE;
  @State isPreviewFrameStart: boolean = true;
  @State isPanoramaBarVisible: boolean = false;
  @State isPanoramaFootBarShow: boolean = false;
  @State superIsoValue: number = 0;
  private proListExpansion: boolean = false;
  @State lightPaintingExtendBarVisible: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State @Watch('lowBatteryExitFlashDialogShow') isFlashEnable: boolean = true;
  @State isLowBatteryTipShowed: boolean = false;
  @StorageLink('isNightShutting') isNightShutting: boolean = false;
  @State isShowLightPaintingTimer: boolean = false;
  @State isShowRingLightView: boolean = false;
  @State isShowWhiteBack: boolean = false;
  @Prop isShowSettingView: boolean = false;
  @State isLongExposure: boolean = false;
  @State isDepthFusionBarShow: boolean = false;
  @State @Watch('tricollapsStatusChanged') isShowTricollaps: boolean = false;
  @State scanCodeCapsulePosition: PositionInfo = {};
  @State @Watch('rotationStatusChanged') isLockRotation: boolean = true;
  private scanCodeCapsuleVisible: boolean = false;
  @State tipsTextPosition: PositionType =
    { x: LandscapeIndex.defaultTipPosition.x, y: LandscapeIndex.defaultTipPosition.y + 30 };
  @State tipPosition: PositionType = LandscapeIndex.defaultTipPosition;
  @State tipTextAlignOption: AlignRuleOption =
    { 'left': { 'anchor': '__container__', 'align': HorizontalAlign.Start } };
  @State tipTextTopMargin: number = 0;
  @State tipTextLeftMargin: number = 0;
  @State tipTextRightMargin: number = 0;
  @State tipTextBottomMargin: number = 0;
  private frontTipAnimationItem: AnimationItem | undefined = undefined;
  private frontTipAnimationSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private frontTipAnimationContext: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(this.frontTipAnimationSettings);
  private static readonly defaultTipPosition: PositionType = { x: 163, y: 5 };
  // 0: 初始状态，未加载过， 1: 显示中， 2: 已加载过
  @State isLoaded: number = PreferencesService.getInstance()
    .getPropValue(PersistType.FOREVER, PropTag.IS_FRONT_CAMERA_TIPS_LOADED, 0) as number;
  @State tipTextRotateAngel: number = 0;
  @State tipTextRotateCenterX: string = '0%';
  @State tipTextRotateCenterY: string = '0%';
  @State tipTextOffsetX: number = 0;
  @State tipTextOffsetY: number = 0;
  @StorageLink('isModeIntroDialogOpen') isModeIntroDialogOpen: boolean = false;
  @State @Watch('updateLayout') windowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  @State windowStateCache: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  @StorageLink('customFilterCardDragOffsetX') @Watch('updateDragHorizontalOffset') customFilterCardDragOffsetX: number =
    0;
  @StorageLink('isCustomFilterCardDrag') @Watch('isDragStop') isCustomFilterCardDrag: boolean = false;
  @State dragHorizontalOffset: number = 0;
  @State dragHorizontalOffsetStore: number = 0;
  private defaultDragHorizontalOffset: number = -1;
  private horizontalDragRatio: number = 0.5;
  @StorageLink('customFilterCardWidth') @Watch('limitDragOffsetToLegal') customFilterCardWidth: number = 0;
  @StorageLink('showPhotoBrowserAction') showPhotoBrowserAction: boolean = false;
  @State customFilterStackCardVieWPositionY: number = this.getCustomFilterCardPosition() + CARD_VIEW_DEFAULT_OFFSET;
  @Prop isHdr: boolean = false;
  @StorageLink('isLogStyleAssistanceOpen') isLogStyleAssistanceOpen: boolean = PreferencesService.getInstance()
    .getPropValue(PersistType.FOREVER, PropTag.IS_LOG_ASSISTANCE_OPEN, false) as boolean;
  @State LogStyleText: string | Resource = '';
  @State LogStyleIcon: string | Resource = '';
  @State isShowLogStyleIcon: boolean = false;
  @State isVideoOutput: boolean = false;
  protected mStoreManager: StoreManager = StoreManager.getInstance();
  @State isCustomFilterImmersiveMoving: boolean = false;
  @State customFilterStackCardVieWScaleX: number = CARD_VIEW_DEFAULT_SCALE;
  @State customFilterStackCardVieWScaleY: number = CARD_VIEW_DEFAULT_SCALE;
  @State customFilterStackCardViewOpacity: number = 0;
  @State rouletteZoomViewScale: number = 1;
  private closingTimeoutIndex = -1;
  private openTimeoutIndex = -1;
  @Prop isCustomFilterButtonShow: boolean = false;
  @State isShowCustomFilterMenu: boolean = false;
  @State currentHue: number = 0;
  @State currentSaturation: number = 0;
  @State currentTone: number = 0;
  @State curStyleIndex: number = 0;
  @State @Watch('rotateAngleChanged') rotateAngleWatch: number = 0;
  @State isCustomFilterCloseLottieAnimDone: boolean = false;
  @State customFilterEffectEnable: boolean = false;
  @State curTemplateIndex: number = -1;
  private customCardAppeared: boolean = false;
  private backFromMoreDetail: boolean = false;
  @Prop indicatorLocationY: number;
  @State mModeBarOpacity: number = 1;
  @State mCustomFilterImmersOpacity: number = 1;
  @State mCustomFilterImmersVisibility: boolean = false;
  ;
  @State mModeBarImmersVisibility: boolean = true;
  @LocalStorageProp('xmagePositionLink') xmagePosition: Length | undefined = 0;
  @StorageLink('onCustomFilterTopLineChange') customFilterTopLineHeight: number = 0;
  @State isShowIntroLottie: boolean = false;
  @State introLottieOpacity: number = 0;
  @LocalStorageLink('isPitchAngleIntroLoaded') isPitchAngleIntroLoaded: boolean = false;
  @LocalStorageLink('isCustomStylesIntroLoaded') isCustomStylesIntroLoaded: boolean = false;
  @StorageLink('isDetailCardMoreButtonClicked')
  isDetailCardMoreButtonClicked: boolean = false;
  @State isProShuttering: boolean = false;
  @State displayInfo: display.Display = DisplayService.getInstance().getDisplay();
  @State styleMenuAvoidOpacity: number = 1;
  @State stitchingOpacity: number = 1;
  private stitchingTimeoutId: number = -1;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear begin.');
    this.isPicker = GlobalContext.get().getIsPicker();
    this.setMEventBusOn();
    this.setSecondMEventBusOn();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.isImmersive = state.get<boolean>('uiReducer', 'isImmersive');
      this.videoTimerState = state.get<boolean>('recordReducer', 'videoTimerState');
      this.lightPaintingTimerState = state.get<boolean>('lightPaintingReducer', 'lightPaintingTimerState');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.rotateAngleWatch = state.get<number>('contextReducer', 'rotateAngle');
      this.customFilterEffectEnable = state.get<boolean>('customFilterStyleReducer', 'customFilterEffectEnable');
      this.curStyleIndex = state.get<number>('customFilterStyleReducer', 'styleIndex');
      this.curTemplateIndex = state.get<number>('customFilterStyleReducer', 'templateIndex');
      changeState(this.state, {
        isShowBigText: state.get<boolean>('modeReducer', 'isShowBigText'), // 是否显示大字体
        isShowPageView: state.get<boolean>('settingViewReducer', 'isShowSettingView'),
        isFloatingShutterShow: state.get<boolean>('settingReducer', 'isFloatingShutterShow'),
        isShowParamBar: state.get<boolean>('uiReducer', 'isShowParamBar'),
        isShowExtendBar: state.get<boolean>('uiReducer', 'isShowExtendBar'),
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        cameraRunningState: state.get<CameraRunningState>('cameraReducer', 'cameraRunningState'),
        uiEnable: state.get<boolean>('contextReducer', 'uiEnable'),
        videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
        tabSelector: state.get<FunctionId>('tabBarReducer', 'tabBarSelector'),
        isShowPinch: state.get<boolean>('zoomReducer', 'isShowPinch'),
        zoomRatio: state.get<number>('zoomReducer', 'zoomRatio'),
        minZoomRatio: state.get<number>('zoomReducer', 'minZoomRatio'),
        maxZoomRatio: state.get<number>('zoomReducer', 'maxZoomRatio'),
        isShowFlipTipView: state.get<boolean>('backSelfieReducer', 'isShowFlipTipView'),
        isShowBackSelfiePopupTip: state.get<boolean>('collapsReducer', 'isShowBackSelfiePopupTip'),
        isShowLowAngleShotView: state.get<boolean>('collapsReducer', 'isShowLowAngleShotView'),
        isColdStart: state.get<boolean>('cameraReducer', 'isColdStart'),
        isLightPaintingFlashTimerShow: state.get<boolean>('lightPaintingReducer', 'isLightPaintingFlashTimerShow'),
        isLightPaintingFlashShow: state.get<boolean>('settingReducer', 'isLightPaintingFlashShow'),
      });
      this.isEditMorePage = state.get<boolean>('modeReducer', 'isEditMorePage');
      this.isFlashEnable = state.get<boolean>('uiReducer', 'isFlashEnable');
      this.showPicker = state.get<boolean>('uiReducer', 'showPicker');
      this.pageHeight = state.get<number>('windowReducer', 'windowHeight');
      this.pageWidth = state.get<number>('windowReducer', 'windowWidth');
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.mInstantDirection = state.get<WindowDirection>('contextReducer', 'instantDirection');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
      this.isShowtimeLapse = state.get<boolean>('settingReducer', 'isShowtimeLapse');
      this.showComponent = state.get<FunctionId>('uiReducer', 'extendBarEffectView');
      this.isTimelapseFront = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
      camera.CameraPosition.CAMERA_POSITION_FRONT
      this.isOpen = state.get<boolean>('treasureBoxReducer', 'isOpen');
      this.isSupportMeteringModeFunc = false;
      this.isShowLightPaintingTimer = state.get<boolean>('lightPaintingReducer', 'isLightPaintingTimerShow');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isShowWhiteBack = state.get<boolean>('ringLightReducer', 'isShowWhiteBack');
      this.iconRotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.isLockRotation = state.get<boolean>('windowReducer', 'isLockRotation');
      this.windowStatus = state.get<window.WindowStatusType>('windowReducer', 'windowStatus');
      this.isVideoOutput = OutputOperation.isPanVideoOutput(state.get<ModeType>('modeReducer', 'mode'));
      this.isProShuttering = state.get<boolean>('proShutterReducer', 'isProShuttering');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.chooseToShowExtendBar();
    this.uxInit();
    this.animateOpacity = 1;
    this.lightPaintingLandscapeDialogWidth =
      getStates().get<number>('windowReducer', 'windowWidth') - DIALOG_SCREEN_MARGIN * 2;
    this.lightPaintingLandscapeDialogHeight =
      LIGHT_PAINTING_DIALOG_HEIGHT / LIGHT_PAINTING_DIALOG_WIDTH * this.lightPaintingLandscapeDialogWidth;
    this.lightPaintingSemiCollapsedDialogWidth = 249;
    this.lightPaintingSemiCollapsedDialogHeight = 370;
    this.initializeIsDialogLoaded();
    if (!this.isPicker) {
      this.volumeService.volumeKeySubscribe();
    }
    this.updateLogStyleValue();
    this.isNeedToOpenCustomFilter();
    this.resetCustomFilterState();
    this.customCardAppeared = false;
    this.updateDragHorizontalPosDefault();
    setTimeout(() => {
      HiLog.begin(TAG, 'LoadSecondLevel');
      this.firstLevelLoaded = true;
      HiLog.end(TAG, 'LoadSecondLevel');
    }, SECOND_LEVEL_LOAD_DELAY);
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    clearTimeout(this.mTimerId);
    clearTimeout(this.closingTimeoutIndex);
    clearTimeout(this.openTimeoutIndex);
    clearTimeout(this.stitchingTimeoutId)
    this.onBackground();
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    if (this.isCustomFilterImmersive && !this.isPicker && this.windowStatus !== window.WindowStatusType.FLOATING
      && this.windowStatus !== window.WindowStatusType.SPLIT_SCREEN) {
      this.closeCustomFilterStackCardAnim();
    }
    this.isPanoramaBarVisible = false;
  }

  private getLimitedVal(currentVal: number): number {
    let minVal: number;
    let maxVal: number;
    let customFilterCardMaxDragOffsetX: number = this.pageWidth - this.customFilterCardWidth;
    minVal = this.previewAnimatePosition.x + this.xComponentWidth / 2 - this.customFilterCardWidth / 2;
    maxVal = customFilterCardMaxDragOffsetX - FOOT_BAR_NON_DRAG_WIDTH;
    return Math.max(minVal, Math.min(maxVal, currentVal));
  }

  private updateDragHorizontalOffset(): void {
    this.dragHorizontalOffset = this.getLimitedVal(this.customFilterCardDragOffsetX + this.dragHorizontalOffsetStore) -
    this.dragHorizontalOffsetStore;
  }

  private isDragStop(): void {
    if (!this.isCustomFilterCardDrag) {
      this.dragHorizontalOffsetStore += this.dragHorizontalOffset;
      this.dragHorizontalOffset = 0;
      this.limitDragOffsetToLegal(false);
    }
  }

  private limitDragOffsetToLegal(isLayoutRefresh: boolean = true): void {
    let customFilterCardMaxDragOffsetX: number = this.pageWidth - this.customFilterCardWidth;
    let oldHorizontalOffset: number;
    if (isLayoutRefresh) {
      oldHorizontalOffset = this.horizontalDragRatio * customFilterCardMaxDragOffsetX;
    } else {
      oldHorizontalOffset = this.dragHorizontalOffsetStore;
    }
    this.dragHorizontalOffsetStore = this.getLimitedVal(oldHorizontalOffset);
    this.horizontalDragRatio = this.dragHorizontalOffsetStore / customFilterCardMaxDragOffsetX;
    HiLog.i(TAG, `limitDragOffsetToLegal after for old ${oldHorizontalOffset} to val ` +
      `${this.dragHorizontalOffsetStore} with ratio ${this.horizontalDragRatio}`);
  }

  private updateCustomFilterCardYPos(): void {
    if (this.isCustomFilterImmersive) {
      this.customFilterStackCardVieWPositionY = this.getCustomFilterCardPosition();
    } else {
      this.customFilterStackCardVieWPositionY = this.getCustomFilterCardPosition() + CARD_VIEW_DEFAULT_OFFSET;
    }
  }

  private getCustomFilterCardPosition(): number {
    return this.pageHeight - CUSTOM_FILTER_CARD_LANDSCAPE_DEFAULT_HEIGHT - CUSTOM_FILTER_CARD_LANDSCAPE_BOTTOM_MARGIN;
  }

  private timeLapse(data: ShowParm): void {
    this.showModeBar = data.showModeBar;
  }

  private setMEventBusOn(): void {
    this.mEventBus.on(CameraActionType.ERROR, (data: CameraErrorData) => this.cameraErrorDialogShow(data.code),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHANGE_X_COMPONENT_SIZE, this.setPreviewPosition.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_RESTORE_DIALOG_CONFIRM, this.onRestoreDialogConfirm.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LOCATION_PERMISSION_TO_SETTING, this.onLocationPermissionToSetting.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_CLOSE_SETTING_DIALOG,
      ContextActionType.UPDATE_SAVE_POWER_MODE_STATE], this.onBackground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onAbilityBackground.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([WindowActionType.ON_SIZE_CHANGE, WindowActionType.REFRESH_UX],
      this.uxRefresh.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LONG_EXPOSURE_SHUTTER,
      this.onLongExposureShutter.bind(this), this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_LONG_EXPOSURE_SHUTTER_END, CameraActionType.STARTED],
      this.onLongExposureShutterEnd.bind(this), this.mBase.hashCode());
    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.SWITCH_CAMERA_CHANGE_MODE],
      this.onChangeMode.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_LUMINATION_STATUS_CHANGED,
      this.updateLumation.bind(this), this.mBase.hashCode());
    this.mEventBus.on([CameraActionType.SWITCH_CAMERA, CameraActionType.CHANGE_MODE,
      CameraActionType.SWITCH_CAMERA_CHANGE_MODE], () => this.initializeIsDialogLoaded(), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LIGHT_PAINTING_FLASH, () => this.initializeIsDialogLoaded(),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, () => this.onForeground(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_EXIT_FLASH_DIALOG, () => this.exitFlashDialogShow(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_EXIT_CAMERA_DIALOG, () => this.exitCameraDialogShow(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_TIME_LAPSE_OPEN, (data: ActionData) => this.isTimeLapseOpen(data['isOpen']),
      this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_IS_START_PANORAMA],
      () => this.onIsPanoramaFootBar(true), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_IS_END_PANORAMA, () => this.onIsPanoramaFootBar(false),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_PHOTO_STOP_PANORAMA, () => this.onIsPanoramaFootBar(false),
      this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_NIGHT_CAPTURE_START, ActionType.ACTION_LONG_EXPOSURE_SHUTTER],
      () => this.isEnterLongExposure(true), this.mBase.hashCode());
    this.mEventBus.on([ContextActionType.ABILITY_ON_BACKGROUND, ActionType.ACTION_NIGHT_CAPTURE_END,
      ActionType.ACTION_LONG_EXPOSURE_SHUTTER_END], () => this.isEnterLongExposure(false),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_EYE_TIP_ANIM, this.hideTipText.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_MORE_PAGE, this.closeIntroductoryText.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_UPDATE_PRO_PARAMETERS_VALUE, (data: ProIsoValue) =>
    this.updateSuperIsoValue(data), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.UPDATE_SAVE_POWER_MODE_STATE, (data: SavePowerModeActionData) =>
    this.updateSavePowerModeState(data), this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.REFRESH_UX, this.updateDisplayInfo.bind(this), this.mBase.hashCode());
  }

  private setSecondMEventBusOn(): void {
    this.mEventBus.on(ActionType.ACTION_PROSON_CHANGE_STATE, this.prosonChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(PreviewActionType.LOAD_SURFACE_DONE, () => this.checkXComponentLock(), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.updateLogStyleValue.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL,
      (data: FunctionValueType) => this.handleFunctionValueChange(data), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.defaultIndexOnStarted.bind(this), this.mBase.hashCode());
  }

  private updateDisplayInfo(): void {
    this.displayInfo = DisplayService.getInstance().getDisplay();
  }

  private updateStyleMenuAvoidOpacity(): void {
    if (this.isShowStyleMenu) {
      this.styleMenuAvoidOpacity = 1;
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_150,
        curve: Curve.Sharp,
      }, () => {
        this.styleMenuAvoidOpacity = 0;
      });
    } else {
      this.styleMenuAvoidOpacity = 0;
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_150,
        curve: Curve.Sharp,
      }, () => {
        this.styleMenuAvoidOpacity = 1;
      });
    }
  }

  private changeCustomFilterPreviewSize(data: ActionData): void {
    if (this.isPicker) {
      return;
    }
    if (data['isPreviewScaled']) {
      this.uncollapsCustomFilterStackCardView(true);
    } else {
      this.uncollapsCustomFilterStackCardView(false);
    }
  }

  private uncollapsCustomFilterStackCardView(isOpen?: boolean): void {
    if (isOpen) {
      this.openCustomFilterStackCardAnim();
    } else {
      this.closeCustomFilterStackCardAnim();
    }
  }

  private openCustomFilterStackCardAnim(): void {
    HiLog.i(TAG, 'openCustomFilterStackCardAnim this.isCustomFilterImmersive：' + this.isCustomFilterImmersive);
    if (this.isCustomFilterImmersiveMoving) {
      clearTimeout(this.closingTimeoutIndex);
    }
    this.isCustomFilterImmersive = true;
    this.isCustomFilterImmersiveImmediately = true;
    this.isCustomFilterImmersiveMoving = true;
    this.changeZoomVisWithAnim();
    this.openTimeoutIndex = setTimeout(() => {
      this.isCustomFilterImmersiveMoving = false;
    }, AnimSpecifications.ANIM_DELAY_400);
    // 打开沉浸式
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_200,
      curve: Curve.Sharp,
      delay: AnimSpecifications.ANIM_DELAY_50
    }, () => { // 透明度
      this.customFilterStackCardViewOpacity = 1;
    });
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_400,
      curve: Curve.Friction,
      delay: 0
    }, () => { // 调色盘展开，快捷变焦缩放
      this.customFilterStackCardVieWScaleX = 1;
      this.customFilterStackCardVieWScaleY = 1;
      this.customFilterStackCardVieWPositionY = this.getCustomFilterCardPosition();
      this.rouletteZoomViewScale = 0.9;
    });
  }

  private closeCustomFilterStackCardAnim(): void {
    HiLog.i(TAG, 'closeCustomFilterStackCardAnim this.isCustomFilterImmersive：' + this.isCustomFilterImmersive);
    if (!this.isCustomFilterImmersive) {
      this.isCustomFilterImmersiveImmediately = false;
      this.mModeBarImmersVisibility = true;
      this.mModeBarOpacity = 1;
      this.mCustomFilterImmersOpacity = 0;
    }
    if (this.mode !== ModeType.PHOTO) {
      this.isCustomFilterImmersive = false;
      this.isCustomFilterImmersiveMoving = false;
      this.isCustomFilterImmersiveImmediately = false;
      this.closingTimeoutIndex = -1;
      this.customFilterStackCardViewOpacity = 0;
      this.customFilterStackCardVieWScaleX = CARD_VIEW_DEFAULT_SCALE;
      this.customFilterStackCardVieWScaleY = CARD_VIEW_DEFAULT_SCALE;
      this.customFilterStackCardVieWPositionY = this.getCustomFilterCardPosition() + CARD_VIEW_DEFAULT_OFFSET;
      this.rouletteZoomViewScale = 1;
      return;
    }
    this.isCustomFilterImmersiveMoving = true;
    clearTimeout(this.closingTimeoutIndex);
    let isCustomFilterImmersiveClosed = false;
    if (AppStorage.get('CustomFilterImmersiveCollaps')) {
      isCustomFilterImmersiveClosed = true;
      HiLog.i(TAG, 'isCustomFilterImmersiveClosed set true');
    }
    this.closingTimeoutIndex = setTimeout(() => {
      if (!isCustomFilterImmersiveClosed) {
        this.isCustomFilterImmersive = false;
      }
      this.isCustomFilterImmersiveMoving = false;
      this.closingTimeoutIndex = -1;
    }, AnimSpecifications.ANIM_DELAY_400);
    this.isCustomFilterImmersiveImmediately = false;
    this.changeZoomVisWithAnim();
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_200,
      curve: Curve.Sharp,
      delay: 0
    }, () => {
      this.customFilterStackCardViewOpacity = 0;
    });
    animateToImmediately({ duration: AnimSpecifications.ANIM_DURATION_400, curve: Curve.Friction, delay: 0 }, () => {
      this.customFilterStackCardVieWScaleX = CARD_VIEW_DEFAULT_SCALE;
      this.customFilterStackCardVieWScaleY = CARD_VIEW_DEFAULT_SCALE;
      this.customFilterStackCardVieWPositionY = this.getCustomFilterCardPosition() + CARD_VIEW_DEFAULT_OFFSET;
      this.rouletteZoomViewScale = 1;
    });
  }

  private async defaultIndexOnStarted(data: CameraStartTypeStruct): Promise<void> {
    return;
    if (data.type !== CameraStartType.COLD_START) {
      HiLog.i(TAG,
        `defaultIndexOnStarted load so, type:${data.type}, isCustomFilterStarted:${this.isCustomFilterStarted}`);
      if (data.type === CameraStartType.WARM_START_WITH_MODE_AND_POS && this.isCustomFilterStarted) {
        HiLog.i(TAG, 'defaultIndexOnStarted openCustomFilterFromApp');
      }
      if (!((data.type === CameraStartType.WARM_START || data.type === CameraStartType.SWITCH_CAMERA) &&
        !this.isCustomFilterStarted)) { // 热启动且之前冷启动未加载so时，需加载so
        HiLog.i(TAG, `defaultIndexOnStarted return data.type: ${data.type}`);
        return;
      }
    }
    const nightSubmodeToastCount: number = PreferencesService.getInstance().getPropValue(PersistType.FOREVER,
      PropTag.NIGHT_SUBMODE_THREE_TOAST, 0) as number;

    const customFilterLoadTimer = setTimeout(async () => {
      HiLog.begin(TAG, 'delayImportCustomFilter');
      this.isCustomFilterStarted = true;
      HiLog.end(TAG, 'delayImportCustomFilter');
      clearTimeout(customFilterLoadTimer);
      if (this.isCustomFilterImmersive && this.customFilterStackCardViewOpacity === 0) {
        this.openCustomFilterStackCardAnim();
      }
    }, AnimSpecifications.ANIM_DELAY_100);
  }

  private isNeedToOpenCustomFilter(): void {
    if (this.isPicker) {
      return;
    }
    let isNeedOpenCustomFilter: boolean | undefined = AppStorage.get('CustomFilterImmersiveCollaps');
    HiLog.i(TAG, 'aboutToAppear isNeedOpenCustomFilter:' + isNeedOpenCustomFilter);
    if (isNeedOpenCustomFilter) {
      AppStorage.setOrCreate('CustomFilterImmersiveCollaps', undefined);
    }
  }

  private resetCustomFilterState(): void {
  }

  private updateSuperIsoValue(data: ProIsoValue): void {
  }

  private handleFunctionValueChange(data: FunctionValueType) {
  }

  private isSwipeRecord(): boolean {
    return false;
  }

  private onLongExposureShutterEnd(): void {
    this.isShowLongExposureCaptureInfo(false);
  }

  private onLongExposureShutter(): void {
    this.isShowLongExposureCaptureInfo(true);
  }

  private onChangeMode(): void {
    this.isShowComponentDisplay();
  }

  private isTimeLapseOpen(isOpen: boolean): void {
    this.isTimeLapseBarOpen = isOpen;
  }

  private onLocationPermissionToSetting(): void {
    this.locationDialogShow(true);
  }

  private onRestoreDialogConfirm(data: RestoreDialogConfirmData): void {
    this.locationDialogShow(false, data);
  }

  private dialogShowChange(): void {
    GlobalContext.get().setObject('isDialogShow', this.isDialogShow);
  }

  private onLandscapeChanged(data: ActionData): void {
    HiLog.i(TAG, `onLandscapeChanged   ${JSON.stringify(data)} -- ${this.isShowSemiCollapsed}`);
    // 1.展开态展开，关闭曝光恢复弹窗；2.展开切换，close弹窗后重新open
    if (!this.isShowSemiCollapsed && data['isShowLandscape'] && data['isShowSemiCollapsed'] &&
    this.exposureConfirmDialogController) {
      this.exposureConfirmDialogController?.close();
      this.isShowExposure = false;
    } else if (this.exposureConfirmDialogController && this.isShowExposure) {
      this.exposureConfirmDialogController?.close();
      this.isShowExposure = false;
      this.createExposureConfirmDialog();
      this.mTimerId = setTimeout((): void => {
        this.exposureConfirmDialogController?.open();
        this.isShowExposure = true;
      }, 250);
    }
    this.reOpenPortraitBeautyDialog();
    this.reOpenCameraErrorDialog();
  }

  private uxRefresh(): void {
    HiLog.i(TAG, 'uxfresh');
    this.uxInit();
    this.animateOpacity = 1;
  }

  private hilogUxComponentStatus(): void {
    HiLog.i(TAG, `LandModeBar Show Status:${this.isShowBigScreenModeBar()}`);
    HiLog.i(TAG, `LandFootBar Show Status:${this.isShowLandScapeFootBar()}`);
    HiLog.i(TAG, `LandTreasureBox Show Status:${this.isShowTreasureBoxVisible()}`);
  }

  private directionChange(): void {
    HiLog.i(TAG, 'directionChange.');
    this.hilogUxComponentStatus();
    this.tabViewPosition = this.getTimeLapseTabPosition();
    if (this.mDirection === WindowDirection.LEFT) {
      this.rotateAngle = 270;
    } else if (this.mDirection === WindowDirection.RIGHT) {
      this.rotateAngle = 90;
    } else if (this.mDirection === WindowDirection.BOTTOM) {
      this.rotateAngle = 180;
    } else {
      this.rotateAngle = 0;
    }
    HiLog.i(TAG, `directionChange rotateAngle: ${this.rotateAngle}`);
    this.rotateTipText();
    if (!this.isShowSemiCollapsed) {
      this.reOpenLightPaintingDialog();
      this.reOpenPortraitBeautyDialog();
    }
    if (!this.isShowCameraError) {
      this.reOpenCameraErrorDialog();
    }
  }

  private prosonChange(data: proSonChangeNumberData): void {
    this.prosonNumber = data.iconId;
  }

  private setTreasureBoxUncollapsAnimation() {
    this.tabViewPosition = this.getTimeLapseTabPosition();
  }

  private chooseToShowExtendBar(): void {
    let isExtendBarContinuation = getStates().get<boolean>('uiReducer', 'isExtendBarContinuation');
    let extendBarEffectView = getStates().get<FunctionId>('uiReducer', 'extendBarEffectView');
    if (isExtendBarContinuation) {
      this.mAction.showExtendBar(extendBarEffectView);
    }
  }

  private landScapeStatusChanged(): void {
    // 在后台切展开态的场景【展开态-后台-悬停态-展开态】
    if (this.isBackground && !this.isShowSemiCollapsed) {
      this.uxInit();
      this.animateOpacity = 1;
    }
  }

  private tricollapsStatusChanged(): void {
    // 在后台G态切M态的场景【G态-后台-M态-G态-打开相机】
    if (this.isBackground && !this.isShowSemiCollapsed) {
      this.uxInit();
      this.animateOpacity = 1;
    }
  }

  private handleDepthFusionBarVisibility(data: ActionData): void {
    const targetShowState: boolean = data['isShow'];
    this.isDepthFusionBarShow = targetShowState;

    HiLog.i(TAG, `landscapeIndex get depthFusion bar show state: ${this.isDepthFusionBarShow}`);
  }

  //监听悬停态和展开态切换
  private setBarAnimate(): void {
    HiLog.i(TAG, 'setBarAnimate E');
    this.treasureBoxHeight = this.isShowSemiCollapsed ?
      LANDSCAPE_TRANSVERSE_HEIGHT_SEMI_COLLAPSED : LANDSCAPE_TRANSVERSE_HEIGHT;
    HiLog.i(TAG, `isShowSemiCollapsed:${this.isShowSemiCollapsed}`);
    this.getComponentPosition();
    if (this.state.isColdStart) {
      if (this.isShowSemiCollapsed) {
        this.animateOpacity = 1;
      }
    } else if (this.isShowSemiCollapsed) {
      this.unToHasUOpacity();
      this.LToSShowSemiPosition();
    } else {
      this.unToHasUOpacity();
      this.SemiToLandShowLand();
    }
    if (this.locationDialogController && !this.isPicker && this.isDialogShow) {
      this.showDialog();
    }
    if (this.cameraErrorDialogController && this.isShowCameraError && !this.isPicker) {
      this.cameraErrorDialogShow(this.errorCode);
    }
    if (this.exitCameraDialogController && !this.isPicker) {
      this.exitCameraDialogShow();
    }
    this.tabViewPosition = this.getTimeLapseTabPosition();
    this.locationDialogController && this.locationDialogController?.close();
    let isExtendBarContinuation = getStates().get<boolean>('uiReducer', 'isExtendBarContinuation');
    if (this.state.isShowExtendBar && !isExtendBarContinuation) {
      this.mAction.updateIsShowParamBar(true);
      this.mAction.updateIsShowExtendBar(false);
    }
    if (this.immersiveUIType === UIOperationType.ZOOM_BAR) {
      this.mAction.updateShowPinch(false);
    }
    let extendBarEffectView = getStates().get<FunctionId>('uiReducer', 'extendBarEffectView');
    HiLog.i(TAG, 'setBarAnimate extendBarEffectView :' + extendBarEffectView);
    if (isExtendBarContinuation) {
      this.mAction.showExtendBar(extendBarEffectView);
    }
    HiLog.i(TAG, 'setBarAnimate x');
  }

  //展开态到悬停态的定位动画(显示悬停态的bar)
  private LToSShowSemiPosition(): void {
    HiLog.i(TAG, 'land to semi, component position animation');
    this.zoomBarAnimatePosition.y = this.layoutService.zoomBarPosition.y;
    this.footBarAnimatePosition.y = this.layoutService.footBarPosition.y;
    this.modeBarAnimatePosition.y = this.layoutService.modeBarPosition.y;
    this.tBoxBarAnimatePosition.y = this.layoutService.treasureBoxPosition.y;
    this.paramAnimatePosition.y = this.layoutService.paramBarPosition.y;
    this.proBarAnimatePosition.y = this.layoutService.proBarPosition.y;
    this.zoomBarAnimatePosition.x = this.layoutService.zoomBarPosition.x - (this.pageHeight * 0.15);
    this.footBarAnimatePosition.x = this.layoutService.footBarPosition.x - (this.pageHeight * 0.15);
    this.modeBarAnimatePosition.x = this.layoutService.modeBarPosition.x - (this.pageHeight * 0.15);
    this.tBoxBarAnimatePosition.x = this.layoutService.treasureBoxPosition.x - (this.pageHeight * 0.15);
    this.paramAnimatePosition.x = this.layoutService.paramBarPosition.x - (this.pageHeight * 0.15);
    this.proBarAnimatePosition.x = this.layoutService.proBarPosition.x - (this.pageHeight * 0.15);
    animateToImmediately({
      duration: 350,
      curve: Curves.cubicBezierCurve(0.18, 0.52, 0.47, 1.00),
      onFinish: () => {
        this.isShowFunctionModule = true;
      }
    },
      () => {
        this.getFinalStatus();
      })
  }

  //悬停态到展开态展开态再出现
  private SemiToLandShowLand(): void {
    HiLog.i(TAG, 'semi to land, component position animation');
    this.zoomBarAnimatePosition.y = this.layoutService.zoomBarPosition.y;
    this.footBarAnimatePosition.y = this.layoutService.footBarPosition.y;
    this.modeBarAnimatePosition.y = this.layoutService.modeBarPosition.y;
    this.tBoxBarAnimatePosition.y = this.layoutService.treasureBoxPosition.y;
    this.paramAnimatePosition.y = this.layoutService.paramBarPosition.y;
    this.proBarAnimatePosition.y = this.layoutService.proBarPosition.y;
    this.zoomBarAnimatePosition.x = this.layoutService.zoomBarPosition.x + (this.pageHeight * 0.15);
    this.footBarAnimatePosition.x = this.layoutService.footBarPosition.x + (this.pageHeight * 0.15);
    this.modeBarAnimatePosition.x = this.layoutService.modeBarPosition.x + (this.pageHeight * 0.15);
    this.tBoxBarAnimatePosition.x = this.layoutService.treasureBoxPosition.x + (this.pageHeight * 0.15);
    this.paramAnimatePosition.x = this.layoutService.paramBarPosition.x + (this.pageHeight * 0.15);
    this.proBarAnimatePosition.x = this.layoutService.proBarPosition.x + (this.pageHeight * 0.15);
    animateToImmediately({
      duration: 350,
      curve: Curves.cubicBezierCurve(0.18, 0.52, 0.47, 1.00),
      onFinish: () => {
        if (!this.isShowSemiCollapsed && !this.showPhotoBrowserAction) { //展开态
          WindowService.getInstance().lockXComponentSurface();
        }
      }
    },
      () => {
        this.getFinalStatus();
      })
  }

  //获得bar组件的定位
  private getFinalStatus(): void {
    HiLog.i(TAG, 'getFinalStatus');
    this.zoomBarAnimatePosition.x = this.layoutService.zoomBarPosition.x;
    this.footBarAnimatePosition.x = this.layoutService.footBarPosition.x;
    this.tBoxBarAnimatePosition.x = this.layoutService.treasureBoxPosition.x;
    this.modeBarAnimatePosition.x = this.layoutService.modeBarPosition.x;
    this.paramAnimatePosition.x = this.layoutService.paramBarPosition.x;
    this.proBarAnimatePosition.x = this.layoutService.proBarPosition.x;
  }

  private getComponentPosition(): void {
    this.layoutService.calLandscapeLayoutRuleParam(this.pageWidth, this.pageHeight, this.previewAnimatePosition,
      this.isShowTricollaps, this.isShowSemiCollapsed, this.state.isShowLowAngleShotView);
    this.zoomBarAnimatePosition = this.layoutService.zoomBarPosition;
    this.footBarAnimatePosition = this.layoutService.footBarPosition;
    this.tBoxBarAnimatePosition = this.layoutService.treasureBoxPosition;
    this.modeBarAnimatePosition = this.layoutService.modeBarPosition;
    this.paramAnimatePosition = this.layoutService.paramBarPosition;
    this.proBarAnimatePosition = this.layoutService.proBarPosition;
    this.modeIntroCardEntryPosition = this.layoutService.modeIntroCardEntryPosition;
  }

  //透明度从有到无
  private hasToUnOpacity(): void {
    this.animateOpacity = 1;
    animateToImmediately({
      duration: 150,
      curve: Curve.Linear,
    },
      () => {
        this.animateOpacity = 0;
      })
  }

  //透明度从无到有
  private unToHasUOpacity(): void {
    this.animateOpacity = 0;
    animateToImmediately({
      duration: 150,
      curve: Curve.Linear,
    },
      () => {
        this.animateOpacity = 1;
      })
  }

  // 横屏状态预览一直居中
  private setPreviewPosition(data: XComponentSize): void {
    HiLog.i(TAG, `setPreviewPosition E, data: ${JSON.stringify(data)}.`);
    this.reOpenLightPaintingDialog();
    const windowServiceInstance = WindowService.getInstance();
    if ((!this.isShowSemiCollapsed || this.isShowTricollaps) &&
      !this.showPhotoBrowserAction) { //展开态
      windowServiceInstance.lockXComponentSurface();
      HiLog.i(TAG, 'setPreviewPosition lock');
    }
    this.isPanoramaBarVisible = false;
  }

  private previewPositionChange(): void {
    HiLog.i(TAG, 'previewAnimatePosition changed.');
    this.getComponentPosition();
    this.updateDragHorizontalPosDefault();
  }

  private xComponentWidthChange(): void {
    this.updateDragHorizontalPosDefault();
    this.backFromMoreDetail = false;
  }

  private updateDragHorizontalPosDefault(): void {
    if (this.customCardAppeared) {
      return;
    }
    this.defaultDragHorizontalOffset =
      this.previewAnimatePosition.x + this.xComponentWidth / 2 - this.customFilterCardWidth / 2;
    this.dragHorizontalOffsetStore = this.defaultDragHorizontalOffset;
    let customFilterCardMaxDragOffsetX: number = this.pageWidth - this.customFilterCardWidth;
    this.horizontalDragRatio = this.dragHorizontalOffsetStore / customFilterCardMaxDragOffsetX;
    this.limitDragOffsetToLegal();
  }

  private uxInit(): void {
    HiLog.i(TAG,
      `Window size width: ${this.pageWidth}, height: ${this.pageHeight}, isShowTricollaps: ${this.isShowTricollaps}.`);
    this.treasureBoxHeight = this.isShowSemiCollapsed ?
      LANDSCAPE_TRANSVERSE_HEIGHT_SEMI_COLLAPSED : LANDSCAPE_TRANSVERSE_HEIGHT;
    this.getComponentPosition();
  }

  private onBackground(): void {
    RestartService.getInstance().cancelRestart();
    this.locationDialogController?.close();
    this.exposureConfirmDialogController?.close();
    this.exitCameraDialogController?.close();
    this.lightPaintingDialogController?.close();
    this.portraitBeautyDialogController?.close();
    this.lightPaintingDialogController = null;
    this.cameraErrorDialogController?.close();
    this.isShowExposure = false;
    this.isShowExitFlash = false;
    this.isShowExitCamera = false;
    this.showLightPaintingTimer = false;
    this.isLightPaintingDialogOpen = false;
    this.isPanoramaBarVisible = false;
    this.isShowCameraError = false;
    this.errorCode = 0; // Clear errorCode
    this.isShowStyleMenu = false;
    this.isShowIntroLottie = false;
    if (this.mTimerId >= 0) {
      clearTimeout(this.mTimerId);
    }
    if (this.isDialogShow) {
      this.isDialogShow = false;
      this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
    }
  }

  private onForeground(): void {
    HiLog.i(TAG, 'onForeground.' + this.isPanoramaBarVisible);
    this.initializeIsDialogLoaded();
    this.isDepthFusionBarShow = true;
  }

  private timerStateOnChange(): void {
    HiLog.i(TAG, `timerStateOnChange videoTimerState: ${this.videoTimerState}.`);
    // 延时摄影借用了video 的流所以加了判斷
    const isPanVideoOutput: boolean = OutputOperation.isPanVideoOutput(this.mode);
    if (!isPanVideoOutput) {
      return;
    }
    if (this.isSuperSlowMotion) { // 一般慢动作动效和录像一致
      return;
    }
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

  private lightPaintingTimerStateOnChange(): void {
    HiLog.i(TAG, `lightPaintingTimerStateOnChange lightPaintingTimerState: ${this.lightPaintingTimerState}.`);
    this.lightPaintingTimerOpacity = this.lightPaintingTimerState ? 0 : 1;
    this.showLightPaintingTimer = true;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_VIDEO_START_DURATION,
      curve: Curve.Sharp,
      onFinish: () => {
        this.showLightPaintingTimer = this.lightPaintingTimerState;
      }
    }, () => {
      this.lightPaintingTimerOpacity = this.lightPaintingTimerState ? 1 : 0;
    });
  }

  private superSlowRecordingAnim(): void { // 超慢动效不在录制过程中处理，按下按钮就开始，且动效和一般录像不同
    HiLog.i(TAG, `timerStateOnChange isDownSuperSlowBtn: ${this.isDownSuperSlowBtn}.`);
    this.timerOpacity = this.isDownSuperSlowBtn ? 0 : 1;
    this.showTimer = true; // 超慢按钮按下的状态模拟录像videoTimeState
    animateToImmediately({
      duration: AnimSpecifications.ANIM_VIDEO_START_DURATION,
      curve: Curve.Sharp,
      onFinish: () => {
        this.showTimer = this.isDownSuperSlowBtn;
      }
    }, () => {
      this.timerOpacity = this.isDownSuperSlowBtn ? 1 : 0;
      this.slowRecordingCompVisible = !this.isDownSuperSlowBtn;
    });
  }

  private getDefaultTextSrc(): Resource | string {
    this.isShowTextInfo = false;
    return '';
  }

  private onModeChange(): void {
  }

  private getTimeLapseTabPosition(): TabPosition {
    if (this.isShowSemiCollapsed) {
      this.rotateAngle = 90;
      HiLog.i(TAG, 'isShowNightCaptureInfo : ');
      return {
        x: this.pageWidth / 8,
        y: this.pageHeight / 2,
      }
    }
    this.rotateAngle = 0;
    HiLog.i(TAG, 'isShowNightCaptureInfo 1111: ');
    return {
      y: TAB_BAR_HEIGHT + 17,
      x: -40
    }
  }

  private closeIntroductoryText(): void {
    if (this.isShowMorePage) {
      this.isShowTextInfo = false;
    } else {
      this.isShowTextInfo = true;
    }
  }

  private isShowLongExposureCaptureInfo(showLongExposureInfo: boolean): void {
    HiLog.i(TAG, 'isShowLongExposureInfo: ' + showLongExposureInfo);
    this.isShowLongExposureInfo = showLongExposureInfo;
  }

  private onAbilityBackground(): void {
    HiLog.i(TAG, 'onAbilityBackground');
    this.onBackground();
  }

  private showDialog(): void {
    HiLog.i(TAG, `showDialog： ${this.isDialogShow}, ${this.isFirstTime}.`);
    if ((this.isDialogShow && this.isFirstTime) || this.mTimerId >= 0) {
      if (this.mTimerId >= 0) {
        clearTimeout(this.mTimerId);
      }
      this.locationDialogController?.close();
      this.isDialogShow = false;
      this.createLocationDialog();
      this.isFirstTime = false;
      this.mTimerId = setTimeout((): void => {
        this.locationDialogController?.open();
        this.isDialogShow = true;
        this.isFirstTime = true;
        this.mTimerId = -1;
      }, 250);
    }
  }

  private cameraErrorDialogShow(errorCode: number): void {
    if (this.isPicker) {
      HiLog.i(TAG, 'Ignore the errorCode for picker.')
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
    HiLog.i(TAG, `cameraErrorDialogShow`);
    this.createCameraErrorDialog(errorCode);
    this.cameraErrorDialogController?.open();
    this.isShowCameraError = true;
  }

  private exitFlashDialogShow(): void {
    TipService.getInstance().showTip($r('app.string.device_hot_flash_off_tips'), 3000, true);
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

  private lightPaintingDialogShow(): void {
    this.lightPaintingDialogController?.close();
    this.isLightPaintingDialogOpen = false;
    this.mTimerId = setTimeout(() => {
      this.lightPaintingDialogController?.open();
      this.isLightPaintingDialogOpen = true;
    }, 250);
  }

  private portraitBeautyDialogShow(): void {
    this.isPortraitBeautyDialogOpen = true;
    this.portraitBeautyDialogController?.open();
  }

  private customFilterDialogShow(data: ActionData): void {
    this.isCustomFilterDialogOpen = true;
    this.customFilterDialogController?.open();
  }

  private updateSavePowerModeState(data: SavePowerModeActionData) {
    HiLog.i(TAG, `Save power mode state: ${data.isDuringSavePowerMode}`);
    if (data.isDuringSavePowerMode) {
      this.isShowStyleMenu = false;
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

  private locationDialogShow(isToSettingPermission: boolean, data?: RestoreDialogConfirmData): void {
    HiLog.i(TAG, 'locationDialogShow ==' + JSON.stringify(data));
    this.isToSettingPermission = isToSettingPermission;
    const IS_RESTORE_DEFAULT_VALUE = PreferencesService.getInstance()
      .getPropValue(PersistType.FOREVER, PropTag.IS_RESTORE_DEFAULT_VALUE, false);
    if (((data?.restoreConfirmFlag || isToSettingPermission) && !this.isPicker && !data?.isRequestOnSetting &&
      !this.isPortraitBeautyDialogOpen)) {
      this.isDialogShow = true;
      this.createLocationDialog();
      this.locationDialogController?.open();
    }
  }

  private createLocationDialog(): void {
    if (this.isToSettingPermission) {
      // 地理位置权限前往设置弹窗
      this.createLocationToSettingDialog();
    } else {
      // 地理位置权限二次确认弹窗
      this.createLocationConfirmDialog();
    }
  }

  private createLocationToSettingDialog(): void {
    this.locationDialogController = new CustomDialogController({
      builder: ConfirmDialogView({
        cancel: () => {
          HiLog.i(TAG, 'locationSettingDialogController ConfirmDialogView cancel.');
          this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
          this.isDialogShow = false;
        },
        confirm: () => {
          //拉起设置
          this.mAction.confirmLocationTOSettingPermission(true);
          this.isDialogShow = false;
          this.locationDialogController?.close();
        },
        title: $r('app.string.camera_location_request_dialog_title'),
        description:
          $r('app.string.location_permission_description_without_starry_sky'),
        cancelText: $r('app.string.cancel'),
        confirmText: $r('app.string.permission_dialog_goto_setting_button'),
        rotateAngle: this.isShowSemiCollapsed ? ROTATE_ANGLE_90 : 0,
        fixedRotateAngle: this.isShowSemiCollapsed ? ROTATE_ANGLE_90 : 0,
        followSystemLocation: this.isShowSemiCollapsed ? false : true,
        currentDirection: this.mDirection,
        isShowSemiCollapsed: this.isShowSemiCollapsed,
      }),
      autoCancel: false,
      customStyle: true,
      maskColor: '#66000000',
      cancel: () => {
        this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
        this.isDialogShow = false;
      },
      alignment: this.isShowSemiCollapsed ? DialogAlignment.CenterStart : DialogAlignment.Center,
    });
  }

  private createLocationConfirmDialog(): void {
    this.locationDialogController = new CustomDialogController({
      builder: ConfirmDialogView({
        cancel: () => {
          this.mAction.resetSaveModeTimer();
          this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
          this.isDialogShow = false;
          clearTimeout(this.mTimerId);
          this.isDialogShow = false;
          HiLog.i(TAG, 'locationConfirmDialog ConfirmDialogView cancel');
        },
        confirm: () => {
          HiLog.i(TAG, 'locationConfirmDialogController ConfirmDialogView confirm');
          this.mAction.resetSaveModeTimer();
          this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, true);
          this.isDialogShow = false;
          clearTimeout(this.mTimerId);
          this.isDialogShow = false;
        },
        title: $r('app.string.camera_location_request_dialog_title'),
        description: $r('app.string.gps_attention_dialog_need_summary'),
        cancelText: $r('app.string.gps_attention_dialog_need_disable'),
        confirmText: $r('app.string.gps_attention_dialog_need_enable'),
        rotateAngle: this.isShowSemiCollapsed ? ROTATE_ANGLE_90 : 0,
        currentDirection: this.mDirection,
        isShowSemiCollapsed: this.isShowSemiCollapsed,
        fixedRotateAngle: this.isShowSemiCollapsed ? ROTATE_ANGLE_90 : 0,
        followSystemLocation: this.isShowSemiCollapsed ? false : true,
      }),
      autoCancel: false,
      customStyle: true,
      maskColor: '#66000000',
      cancel: () => {
        this.isDialogShow = false;
      },
      alignment: this.isShowSemiCollapsed ? DialogAlignment.CenterStart : DialogAlignment.Center,
    });
  }

  private lowBatteryExitFlashDialogShow(): void {
    HiLog.i(TAG, 'isFlashEnable ==' + this.isFlashEnable);
    if (this.isFlashEnable) {
      this.mAction.changeFunctionValue(FunctionId.FLASH, PreferencesService.getInstance()
        .getPublicValue(PersistType.FOREVER, PublicTag.FLASH_STATE, FlashMode.OFF));
      return;
    }
    PreferencesService.getInstance().putPublicValue(PersistType.FOREVER, PublicTag.FLASH_STATE,
      FeatureManager.getInstance().getFunction(FunctionId.FLASH).getValue() as number);
    this.mAction.changeFunctionValue(FunctionId.FLASH, FlashMode.OFF);
    this.isLowBatteryTipShowed = PreferencesService.getInstance().getPublicValue(PersistType.FOREVER,
      PublicTag.IS_LOW_BATTERY_TIP_OPENED, false) as boolean;
    HiLog.i(TAG, 'this.isShowLowBatteryExitFlash ==' + this.isLowBatteryTipShowed);
    if (this.isLowBatteryTipShowed) {
      return;
    }
    TipService.getInstance().showTip($r('app.string.dialog_FlashOff_BatteryLowTips'), 3000, true);
    this.isLowBatteryTipShowed = true;
    PreferencesService.getInstance().putPublicValue(PersistType.FOREVER, PublicTag.IS_LOW_BATTERY_TIP_OPENED, true);
  }

  private createCameraErrorDialog(errorCode: number): void {
    HiLog.i(TAG, `createCameraErrorDialog, pass errorCode: ${errorCode}`);
    let params: CameraErrorDialogViewParams =
      CameraErrorDialogView.getDefaultParams(errorCode); // record for reOpenCameraErrorDialog function
    this.errorCode = errorCode
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
        rotateAngle: this.isShowSemiCollapsed ? ROTATE_ANGLE_90 : 0,
        currentDirection: this.mDirection,
        isShowSemiCollapsed: this.isShowSemiCollapsed,
      }),
      autoCancel: false,
      customStyle: true,
      maskColor: '#66000000',
      cancel: () => {
        this.isShowCameraError = false;
      },
      alignment: this.isShowSemiCollapsed ? DialogAlignment.CenterStart : DialogAlignment.Center
    });
  }

  private createExitCameraDialog(): void {
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
      maskColor: '#66000000',
      alignment: this.isShowSemiCollapsed ? DialogAlignment.CenterStart : DialogAlignment.Center,
    });
  }

  private instantDirectionChange(): void {
  }

  private reOpenLightPaintingDialog(): void {
    if (!this.isLightPaintingDialogOpen || !this.state.isLightPaintingFlashShow || this.checkLightPaintingLoaded()) {
      return;
    }
    if (this.mTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.mTimerId);
      this.mTimerId = Number.MIN_VALUE;
    }
    this.mTimerId = setTimeout(() => {
      if (!this.isLightPaintingDialogOpen) {
        this.lightPaintingDialogController?.open();
        this.isLightPaintingDialogOpen = true;
      }
    }, 250);
  }

  private reOpenCameraErrorDialog(): void {
    HiLog.i(TAG, 'reOpenCameraErrorDialog.');
    if (!this.isShowCameraError) {
      return;
    }
    if (this.mTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.mTimerId);
      this.mTimerId = Number.MIN_VALUE;
    }
    this.createCameraErrorDialog(this.errorCode);
    this.mTimerId = setTimeout(() => {
      if (!this.isShowCameraError) {
        this.cameraErrorDialogController?.open();
        this.isShowCameraError = true;
      }
    }, 250);
  }

  private onWillDismissFunction(dismissContentCoverAction: DismissContentCoverAction): void {
    if (dismissContentCoverAction.reason === DismissReason.PRESS_BACK) {
      PreferencesService.getInstance()
        .putPublicValue(PersistType.FOREVER, PublicTag.IS_PORTRAIT_BEAUTY_DIALOG_LOADED, true);
      this.isPortraitBeautyDialogLoaded = true
      this.isPortraitBeautyDialogOpen = false;
      this.portraitBeautyDialogController?.close();
      this.locationDialogShow(false);
    }
  }

  private onWillDismissLightPaintingDialog(dismissContentCoverAction: DismissContentCoverAction): void {
    if (dismissContentCoverAction.reason === DismissReason.PRESS_BACK) {
      PreferencesService.getInstance()
        .putPropValue(PersistType.FOREVER, PropTag.IS_LIGHT_PAINTING_DIALOG_LOADED, true);
      this.lightPaintingDialogController?.close();
      this.isLightPaintingDialogOpen = false;
    }
  }

  private onWillDismissCustomFilterDialog(dismissContentCoverAction: DismissContentCoverAction): void {
    if (dismissContentCoverAction.reason === DismissReason.PRESS_BACK) {
      this.customFilterDialogController?.close();
      this.isCustomFilterDialogOpen = false;
    }
  }

  private reOpenPortraitBeautyDialog(): void {
    if (this.mDirection === WindowDirection.BOTTOM || !this.isPortraitBeautyDialogOpen ||
    this.checkIsPortraitBeautyLoaded()) {
      return;
    }
    if (this.mTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.mTimerId);
      this.mTimerId = Number.MIN_VALUE;
    }
  }

  private initializeIsDialogLoaded(): void {
    if (GlobalContext.get().getIsPicker()) {
      HiLog.i(TAG, 'picker is not need to show portrait beauty dialog.');
      return;
    }
    this.isDepthFusionBarShow = false;
  }

  private checkIsPortraitBeautyLoaded() {
    this.isPortraitBeautyDialogLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_PORTRAIT_BEAUTY_DIALOG_LOADED, false) as boolean;
    return this.isPortraitBeautyDialogLoaded;
  }

  private checkLightPaintingLoaded() {
    this.isLightPaintingDialogLoaded = PreferencesService.getInstance()
      .getPropValue(PersistType.FOREVER, PropTag.IS_LIGHT_PAINTING_DIALOG_LOADED, false) as boolean;
    return this.isLightPaintingDialogLoaded;
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
        rotateAngle: this.isShowSemiCollapsed ? ROTATE_ANGLE_90 : 0,
        currentDirection: this.mDirection,
        isShowSemiCollapsed: this.isShowSemiCollapsed,
        isHdr: this.isHdr,
        fixedRotateAngle: this.isShowSemiCollapsed ? ROTATE_ANGLE_90 : 0,
        followSystemLocation: this.isShowSemiCollapsed ? false : true,
      }),
      autoCancel: false,
      customStyle: true,
      maskColor: '#66000000',
      cancel: () => {
        this.isDialogShow = false;
        this.isShowExposure = false;
      },
      alignment: this.isShowSemiCollapsed ? DialogAlignment.CenterStart : DialogAlignment.Center,
    });
  }

  private getZoomWidth(): number {
    if (this.treasureBoxTopMargin + this.treasureBoxHeight - (this.pageHeight - 412) > TREASURE_BOX_ELEMENT_HEIGHT) {
      return this.pageHeight - (this.treasureBoxTopMargin + this.treasureBoxHeight);
    }
    return 336;
  }

  private getFlashPositionY(): number {
    if (this.isShowSemiCollapsed) {
      return 0;
    }
    return Math.floor(Math.abs(this.pageHeight - this.pageWidth) / 2);
  }

  private onFunctionalAreaClicked(): void {
    if (OutputOperation.isPanPhotoOutput(this.mode) && this.isShowtimeLapse) {
      this.mAction.changeTimeLapse(false);
      this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
      this.mAction.capture();
      this.mAction.changeFunctionValue(FunctionId.CAPTURE, true);
    } else if (OutputOperation.isPanVideoOutput(this.mode) && this.isShowtimeLapse) {
      if (this.isSuperSlowMotion) { // 超慢延时录像不走普通录像流程
        this.mAction.changeTimeLapse(false);
      } else {
        this.mAction.changeTimeLapse(false);
        this.mAction.startVideoAnim();
        this.mAction.startRecording();
        this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, 0);
      }
    }
  }

  private onIsPanoramaFootBar(visible: boolean) {
    HiLog.i(TAG, 'onIsPanoramaFootBar E.' + visible);
    this.isPanoramaFootBarShow = visible;
    HiLog.i(TAG, 'onIsPanoramaFootBar X.');
  }

  private pinchGestureStart(event: GestureEvent): void {
    HiLog.i(TAG, 'pinchGestureStart E.');
    if (this.prosonNumber !== -1 || this.superIsoValue >= ISO_CUTOFF_VALUE_JPG) {
      this.mAction.proSonChangeState(-1);
      this.proListExpansion = true;
      return;
    }
    const isHideZoomView: boolean = HIDE_ZOOM_BAR_MODE_LIST.includes(this.mode) &&
      ZoomOperation.getRingZoomUIState(this.state.cameraPosition, this.mode)?.quickZoomValArr.length <= 1;
    if (this.state.isShowBigText || this.isShowtimeLapse || isHideZoomView) {
      return;
    }
    if (!this.isSupportedZoomWhenOpenStabilization()) {
      return;
    }
    this.mAction.changeFunctionValue(FunctionId.ZOOM,
      { zoomRatio: undefined, isPrepareZoom: true } as ZoomFuncValueStruct);
    clearTimeout(this.pinchGestureTimer);
    if (!this.isSwipeRecord()) {
      this.mAction.isEnterImmersive(true);
      this.mAction.updateShowPinch(true);
    }
    this.baseZoom = this.state.zoomRatio;
    this.frontPinchCanUpdate = true;
    HiLog.i(TAG, 'pinchGestureStart X.');
  }

  private isSupportedZoomWhenOpenStabilization(): boolean {
    return false;
  }

  private pinchGestureUpdate(event: GestureEvent): void {
    if (this.noPinchGestureUpdate()) {
      return;
    }
    if (this.proListExpansion) {
      return;
    }
    HiLog.i(TAG, 'pinchGestureUpdate invoke, setZoomRatio.');
    const isHideZoomView: boolean = HIDE_ZOOM_BAR_MODE_LIST.includes(this.mode) &&
      ZoomOperation.getRingZoomUIState(this.state.cameraPosition, this.mode)?.quickZoomValArr.length <= 1;
    if (this.state.isShowBigText || this.isShowtimeLapse || isHideZoomView) {
      return;
    }
    if (!this.isSupportedZoomWhenOpenStabilization()) {
      TipService.getInstance().showTip($r('app.string.Steadyshot_zoom_is_not_supported'), 3000, true);
      return;
    }
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT || this.isPhysicalCameraDevice()) {
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
    if (zoomRatio !== this.state.zoomRatio) {
      this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: zoomRatio } as ZoomFuncValueStruct);
    }
    let preZoomRatio = this.state.zoomRatio.toFixed(1);
    let curZoomRatio = zoomRatio.toFixed(1);
    if ((curZoomRatio !== preZoomRatio) &&
      (this.state.videoState === RecordingState.READY) && DeviceInfo.isPcAndTablet()) {
      VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_FOCUS_EFFECT_ID);
    }
    HiLog.i(TAG, 'pinchGestureUpdate end.');
  }

  private noPinchGestureUpdate(): boolean {
    return false;
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

  private updateLumation(data: LumationConfirmData): void {
    HiLog.d(TAG, `updateLumation: ${data.info}.`)
    this.lumationValue = data.info;
  }

  private pinchGestureEnd(event: GestureEvent): void {
    HiLog.i(TAG, 'pinchGestureEnd E.');
    if (this.proListExpansion) {
      this.proListExpansion = false;
      return;
    }
    const isHideZoomView: boolean = HIDE_ZOOM_BAR_MODE_LIST.includes(this.mode) &&
      ZoomOperation.getRingZoomUIState(this.state.cameraPosition, this.mode)?.quickZoomValArr.length <= 1;
    // 捏合过程中，触发倒计时拍照 倒计时过程中停止捏合 只需更新showpinch为false即可 不用退出沉浸式
    if (this.state.isShowPinch && this.isShowtimeLapse) {
      this.mAction.updateShowPinch(false);
      return;
    }
    if (this.state.isShowBigText || this.isShowtimeLapse || isHideZoomView) {
      return;
    }
    if (!this.isSupportedZoomWhenOpenStabilization()) {
      return;
    }

    this.mAction.changeFunctionValue(FunctionId.ZOOM,
      { zoomRatio: undefined, isUnprepareZoom: true } as ZoomFuncValueStruct);
    this.mAction.isEnterImmersive(false);
    this.mAction.updateShowPinch(false);
    HiLog.i(TAG, 'pinchGestureEnd X.');
  }

  private isShowComponentDisplay(): void {
    this.showZoomView = true;
    this.showParamBar = true;
    this.showProfessionBar = true;
  }

  private isPhysicalCameraDevice(): boolean {
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
    const pictureType: PhotoFormatMode = FeatureManager.getInstance().getFunction(FunctionId.PHOTO_FORMAT).getValue();
    return FeatureManager.getInstance().getModeFunctionIds().indexOf(FunctionId.PHOTO_FORMAT) >= 0 &&
      outputType === OutputType.PHOTO_OUTPUT && false;
  }

  private getZoomViewVisible(): number {
    // 更多模式
    if (this.isShowMorePage || this.showPicker) {
      return Visibility.Hidden;
    }
    // 展开态前置模式
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      return Visibility.Hidden;
    }
    // 夜景曝光阶段
    if (this.isShowNightExposure) {
      return Visibility.Hidden;
    }
    // 倒计时
    if (this.isShowtimeLapse) {
      return Visibility.Hidden;
    }
    // 录像模式 且开了防抖
    if (!this.isSupportedZoomWhenOpenStabilization() && this.mode === ModeType.VIDEO) {
      return Visibility.Hidden;
    }
    // 非变焦组件引起的沉浸式模式
    if (this.immersiveUIType !== UIOperationType.ZOOM_BAR && this.immersiveOpacity === 0) {
      return Visibility.Hidden;
    }

    // 只有一个变焦点
    if (HIDE_ZOOM_BAR_MODE_LIST.includes(this.mode) &&
      ZoomOperation.getRingZoomUIState(this.state.cameraPosition, this.mode)?.quickZoomValArr.length <= 1) {
      return Visibility.Hidden;
    }
    if (this.isSuperSlowMotion && !this.slowRecordingCompVisible) { // 超慢zoom动效
      return Visibility.Hidden;
    }
    // 长曝光状态进入沉浸式拍照
    if (this.isNightShutting) {
      return Visibility.Hidden;
    }
    return Visibility.Visible;
  }

  private getParamVisible(): number {
    if (!this.state.isShowParamBar) {
      return Visibility.Hidden;
    }

    // 沉浸式不透明度
    if (this.immersiveOpacity === 0) {
      return Visibility.Hidden;
    }

    //显示夜间曝光
    if (this.isShowNightExposure) {
      return Visibility.Hidden;
    }

    //倒计时
    if (this.isShowtimeLapse) {
      return Visibility.Hidden;
    }

    // 更多模式
    if (this.isShowMorePage) {
      return Visibility.Hidden;
    }
    // 相机启动未完成
    if (this.state.cameraRunningState !== CameraRunningState.STARTED && this.showParamBar) {
      return Visibility.Hidden;
    }

    // 切模式启流成功后更改ParamBar显示判断
    if (this.state.cameraRunningState === CameraRunningState.STARTED && this.showParamBar) {
      this.showParamBar = false;
    }

    // 显示大字体 并且处于未录像状态
    if (this.state.isShowBigText && this.videoState === RecordingState.READY) {
      return Visibility.Hidden;
    }

    this.lightPaintingExtendBarVisible = true;
    return Visibility.Visible;
  }

  private getProBarVisible(): Visibility {

    // 切模式或者切前后置相机启动未完成隐藏
    if (this.state.cameraRunningState !== CameraRunningState.STARTED && this.showProfessionBar) {
      return Visibility.Hidden;
    }

    // 切模式启流成功后更改Profession显示判断
    if (this.state.cameraRunningState === CameraRunningState.STARTED && this.showProfessionBar) {
      this.showProfessionBar = false;
    }

    // 显示大字体隐藏
    if (this.state.isShowBigText && this.videoState === RecordingState.READY) {
      return Visibility.Hidden;
    }

    // 进入沉浸式隐藏
    if (this.immersiveUIType !== UIOperationType.PRO_BAR && this.immersiveOpacity === 0) {
      return Visibility.Hidden;
    }

    // 进入更多页隐藏
    if (this.isShowMorePage) {
      return Visibility.Hidden;
    }

    return Visibility.Visible;
  }

  private isShowTreasureBoxVisible(): Visibility {
    return !this.isShowMorePage &&
      (this.immersiveUIType === UIOperationType.ZOOM_BAR || this.immersiveOpacity !== 0) &&
      !this.state.isShowPinch && !this.isImmersive &&
      !this.isShowNightExposure && !this.isShowtimeLapse && !this.showPicker ? Visibility.Visible : Visibility.None
  }

  private checkXComponentLock(): void {
    HiLog.i(TAG, 'checkXComponentLock begin.');
    if (this.isShowSemiCollapsed || this.showPhotoBrowserAction) {
      return;
    }
    WindowService.getInstance().lockXComponentSurface();
    HiLog.i(TAG, 'checkXComponentLock end.');
  }

  private isShowModeBar(): boolean {
    return !this.isImmersive && !this.isDownSuperSlowBtn && !this.isEditMorePage &&
      (this.immersiveUIType === UIOperationType.MODE_BAR || this.immersiveOpacity !== 0) && !this.showTimer &&
      !this.isShowNightExposure && !this.isShowtimeLapse && !this.showPicker && !this.isTimeLapseBarOpen;
  }

  private isDisModeBar(): boolean {
    return !this.isProShuttering;
  }

  private rotationStatusChanged(): void {
  }

  private getPanoramaBarVisible(): boolean {
    if (this.isBackground) {
      return false;
    }
    if (this.isShowMorePage) {
      return false;
    }
    // 切模式或者切前后置相机启动未完成
    if (this.state.cameraRunningState !== CameraRunningState.STARTED) {
      return false;
    }
    if (this.state.isShowBigText && this.videoState === RecordingState.READY) {
      return false;
    }
    if (!this.isPreviewFrameStart) {
      return false;
    }
    this.panoramaTimer = setTimeout((): void => {
      this.isPanoramaBarVisible = true;
      clearTimeout(this.panoramaTimer);
    }, 800);
    return true;
  }

  private showExposureTip(): boolean {
    let isCurrentModeSupport: boolean = false;
    return (this.isPreviewFrameStart) && isCurrentModeSupport && (this.state.videoState === RecordingState.READY ||
      OutputSwitcher.getInstance().getOutput() === OutputType.PHOTO_OUTPUT) && (!this.isShowMorePage) &&
      (this.lumationValue < 0.098 || this.lumationValue > 0.392);
  }

  private isShowBigScreenModeBar(): boolean {
    return !this.isImmersive && !this.isDownSuperSlowBtn && this.mModeBarImmersVisibility &&
      !this.isEditMorePage && (this.immersiveUIType === UIOperationType.MODE_BAR || this.immersiveOpacity !== 0) &&
      !this.showTimer && !this.isShowNightExposure && !this.isShowtimeLapse && !this.showPicker
  }

  private isShowLandScapeFootBar(): boolean {
    return !this.isShowMorePage && (this.immersiveUIType === UIOperationType.FOOT_BAR || this.isPanoramaFootBarShow ||
      this.immersiveUIType === UIOperationType.LR_SWIPE || this.immersiveOpacity !== 0) && !this.isShowtimeLapse &&
      !this.showPicker;
  }

  // ==========扫码 start=========
  private rotationOpenPositionChangeAnim(rotation: number): void {
    HiLog.i(TAG, `calcScanCodeCapsulePosition rotation: ${rotation}`);
    let bottom: number = 60;
    if (rotation === 1 || rotation === 3) {
      bottom = 80;
    }

    if (this.scanCodeCapsulePosition.bottom === bottom) {
      HiLog.i(TAG, 'rotationOpenPositionChangeAnim bottom value is same as old value.');
      return;
    }

    animateTo({
      duration: 300,
      curve: Curve.Friction,
      onFinish: () => {
        HiLog.i(TAG, 'rotationOpenPositionChangeAnim onFinish');
      }
    }, () => {
      this.scanCodeCapsulePosition = { bottom };
    });
  }

  // ==========扫码 end=========

  private getXComponentScale(): ScaleOptions {
    let scale: ScaleOptions = { x: 1, y: 1 };
    return scale;
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      this.PreviewGestureBuilder();
      this.rouletteZoomViewBuilder();
      this.treasureBoxBuilder();
      if (!this.isPicker) {
        this.customFilterCardBuilder();
      }
      this.tipBoxBuilder();
      this.pickerViewBuilder();
      this.footBar();
      this.modeBarBuilder();
      this.paramBarBuilder();
      this.videoTimerBuilder();
      this.floatingShutterButtonBuilder();
      this.CustomFilterMasking();
      if (this.isShowSemiCollapsed) {
        this.selfieStickSwipeBuilder();
      }
      if (this.isShowTricollaps && this.windowStatus !== window.WindowStatusType.FLOATING &&
        this.windowStatus !== window.WindowStatusType.SPLIT_SCREEN) {
        this.frontCameraTipsBuilder();
      }
    }
    .width(FULL_LENGTH)
    .height(FULL_LENGTH)
    .alignContent(this.isShowSemiCollapsed ? Alignment.Start : Alignment.Center)
    .onTouch((): void => {
    })
  }

  @Builder
  selfieStickSwipeBuilder(): void {
    Column() {

    }
    .backgroundColor(Color.Black)
    .position(SELFIESTICK_POSITION)
    .width(10)
    .height(20)
    .draggable(false)
    .opacity(0)
    .gesture(
      PanGesture({
        fingers: 1,
        direction: PanDirection.Down,
        distance: 10
      })
        .onActionStart((): void => {
          if (!this.isShowtimeLapse && !this.isLongExposure && !this.isDownSuperSlowBtn &&
            !this.state.isShowLowAngleShotView && this.videoState === RecordingState.READY &&
            !this.isDepthFusionBarShow && !this.isProShuttering) {
            this.mAction.swipeChangeMode(-1);
          }
        })
    )
  }

  @Builder
  PreviewGestureBuilder() {
    PreviewGestureArea({
      immersiveUIType: this.immersiveUIType,
      isHdr: this.isHdr
    })
      .width(this.xComponentWidth)
      .height(this.xComponentHeight)
      .position(this.previewAnimatePosition)
      .hitTestBehavior(HitTestMode.Transparent)
  }

  @Builder
  rouletteZoomViewBuilder() {
    RouletteZoomView({
      zoomWidth: this.isShowSemiCollapsed ? 308 : this.getZoomWidth(),
      landscapeZoomWidth: this.isShowSemiCollapsed ? 308 : this.getZoomWidth(),
      zoomHeight: 150,
      drawHeight: 95,
      isCustomFilterImmersive: this.isCustomFilterImmersiveImmediately,
      isHdr: this.isHdr
    })
      .position(this.zoomBarAnimatePosition)
      .key(ComponentIdKeys.RING_ZOOM_BAR)
      .opacity(this.animateOpacity ?
        (!this.isShowMorePage && this.immersiveUIType === UIOperationType.ZOOM_BAR ? 1 : this.immersiveOpacity) : 0)
      .hitTestBehavior(HitTestMode.Transparent)
      .visibility(this.getZoomViewVisible())
      .rotate({
        centerX: this.isShowSemiCollapsed ? '50%' : 0,
        centerY: this.isShowSemiCollapsed ? '50%' : 80,
        angle: this.isShowSemiCollapsed ? ROTATE_ANGLE_180 : ROTATE_ANGLE_90
      })
      .zIndex((this.isShowSemiCollapsed || this.isCustomFilterImmersiveImmediately) ? ZIndex.MIDDLE_BOTTOM : 0)
  }

  @Builder
  customFilterCardBuilder(): void {
    Column() {
    }
    .opacity(this.customFilterStackCardViewOpacity * this.immersiveOpacity * this.styleMenuAvoidOpacity)
    .scale({
      x: this.customFilterStackCardVieWScaleX,
      y: this.customFilterStackCardVieWScaleY,
      z: 1,
      centerX: '50%',
      centerY: '50%',
    })
    .width(CUSTOM_FILTER_CARD_LANDSCAPE_DEFAULT_WIDTH)
    .height(CUSTOM_FILTER_CARD_LANDSCAPE_DEFAULT_HEIGHT)
    .zIndex(this.isCustomFilterImmersive ? ZIndex.TOP : ZIndex.BOTTOM)
    .enabled(this.isCustomFilterImmersive && !this.isImmersive && !this.isShowtimeLapse)
    .visibility(this.mode === ModeType.PHOTO ?
      Visibility.Visible : Visibility.Hidden)
    .position({
      x: this.dragHorizontalOffsetStore + this.dragHorizontalOffset,
      y: this.customFilterStackCardVieWPositionY
    });
  }

  @Builder
  CustomFilterMasking() {
    PreviewCustomFilterMasking({
      maskWidth: CARD_VIEW_MASKING_WIDTH,
      maskHeight: this.xComponentHeight,
      isLeft: true
    })
      .width(CARD_VIEW_MASKING_WIDTH)
      .visibility(this.getPreviewCustomMaskVisibility())
      .opacity(this.mCustomFilterImmersOpacity)
      .zIndex(ZIndex.TOP)
      .position({ x: this.previewAnimatePosition.x, y: this.previewAnimatePosition.y })
      .hitTestBehavior(HitTestMode.Transparent);

    PreviewCustomFilterMasking({
      maskWidth: CARD_VIEW_MASKING_WIDTH,
      maskHeight: this.xComponentHeight,
      isLeft: false
    })
      .width(CARD_VIEW_MASKING_WIDTH)
      .visibility(this.getPreviewCustomMaskVisibility())
      .opacity(this.mCustomFilterImmersOpacity)
      .zIndex(ZIndex.TOP)
      .position({ x: this.previewAnimatePosition.x + this.xComponentWidth, y: this.previewAnimatePosition.y })
      .hitTestBehavior(HitTestMode.Transparent)
  }

  private getPreviewCustomMaskVisibility(): Visibility {
    if (!this.mCustomFilterImmersVisibility) {
      return Visibility.Hidden;
    }
    const orientation: display.Orientation = DisplayService.getInstance().getDisplay().orientation;
    if (orientation === display.Orientation.PORTRAIT || orientation === display.Orientation.PORTRAIT_INVERTED) {
      return Visibility.Hidden;
    }
    return Visibility.Hidden;
  }

  @Builder
  treasureBoxBuilder() {
    if (this.isShowSemiCollapsed) {
      LandscapeTreasureBox({
        treasureBoxHeight: this.treasureBoxHeight,
        isHdr: this.isHdr
      })
        .position(this.tBoxBarAnimatePosition)
        .visibility(this.isShowTreasureBoxVisible())
        .opacity(this.animateOpacity ?
          (!this.isShowMorePage && this.immersiveUIType === UIOperationType.ZOOM_BAR ? 1 : this.immersiveOpacity) : 0)
        .zIndex(ZIndex.MIDDLE_BOTTOM)
    } else {
      LandscapeTreasureBox({
        treasureBoxHeight: this.treasureBoxHeight,
        isHdr: this.isHdr
      })
        .position(this.tBoxBarAnimatePosition)
        .visibility(this.isShowTreasureBoxVisible())
        .opacity(this.animateOpacity ?
          (!this.isShowMorePage && this.immersiveUIType === UIOperationType.ZOOM_BAR ? 1 : this.immersiveOpacity) : 0)
        .bindContextMenu(this.isShowStyleMenu,
          this.StyleListOutBuilder(), {
            placement: SystemLanguageUtil.isRTL() ? Placement.Left : Placement.Right,
            borderRadius: $r('sys.float.corner_radius_level10'),
            backgroundBlurStyle: BlurStyle.NONE,
            offset: {
              x: MENU_OFFSET_X, y: this.getMenuOffsetY()
            }
          })
    }
  }

  @Builder
  StyleListOutBuilder() {
  }

  private getMenuOffsetY(): number {
    let offsetYMax = MENU_OFFSET_Y_MAX_BACK;
    if (DisplayService.getInstance().getDisplay().orientation === display.Orientation.LANDSCAPE ||
      DisplayService.getInstance().getDisplay().orientation === display.Orientation.LANDSCAPE_INVERTED) {
      offsetYMax = MENU_OFFSET_Y_MAX_BACK_LAND;
    }
    if (Number(this.xmagePosition) > offsetYMax) {
      this.xmagePosition = offsetYMax;
    }
    return Number(this.xmagePosition) + MENU_OFFSET_Y_M;
  }

  @Builder
  tipBoxBuilder() {
    // 非以下场景显示tip：沉浸式下的变焦（录像模式除外）以及倒计时拍照
    if (!(this.immersiveOpacity == 0 &&
      ((this.immersiveUIType === UIOperationType.ZOOM_BAR ||
        this.immersiveUIType === UIOperationType.PINCH_ZOOM) && this.mode !== ModeType.VIDEO ||
        this.immersiveUIType === UIOperationType.TIMELAPSE)) || TipService.getInstance().isAlwaysShowTip()) {
      TipBox({
        isShowTextInfo: this.isShowTextInfo,
        isShowLongExposureInfo: this.isShowLongExposureInfo,
        landscapePreviewPosition: this.previewAnimatePosition,
        isHdr: this.isHdr
      })
    }
  }

  @Builder
  pickerViewBuilder() {
    if (this.isPicker) {
      LandscapePickerView({
        previewPosition: this.previewAnimatePosition,
        buttonPosition: this.footBarAnimatePosition
      })
        .visibility(this.showPicker ? Visibility.Visible : Visibility.Hidden)
        .zIndex(ZIndex.TOP)
    }
  }

  @Builder
  footBar() {
    LandscapeFootBar({
      isPicker: this.isPicker,
      isShowSemiCollapsed: this.isShowSemiCollapsed,
      footBarScale: 1,
      isHdr: this.isHdr
    })
      .opacity(this.animateOpacity ?
        (!this.isShowMorePage && (this.immersiveUIType === UIOperationType.FOOT_BAR ||
          this.immersiveUIType === UIOperationType.LR_SWIPE ||
        this.isPanoramaFootBarShow) ? 1 : this.immersiveOpacity) : 0)
      .visibility(this.isShowLandScapeFootBar() ? Visibility.Visible : Visibility.Hidden)
      .position(this.footBarAnimatePosition)
      .zIndex(this.isShowSemiCollapsed ? ZIndex.MIDDLE_BOTTOM : 0)
  }

  private changeZoomVisWithAnim(): void {
    if (this.isCustomFilterImmersiveImmediately) {
      this.mCustomFilterImmersVisibility = true;
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_300,
        curve: Curve.Sharp,
        onFinish: () => {
          this.mModeBarImmersVisibility = false;
        }
      }, () => {
        this.mModeBarOpacity = 0;
        this.mCustomFilterImmersOpacity = 1;
      });
    } else {
      this.mModeBarImmersVisibility = true;
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_300,
        curve: Curve.Sharp,
        onFinish: () => {
          this.mCustomFilterImmersVisibility = false;
        }
      }, () => {
        this.mModeBarOpacity = 1;
        this.mCustomFilterImmersOpacity = 0;
      });
    }
  }

  @Builder
  modeBarBuilder() {
    if (!this.isShowSemiCollapsed) {
      BigScreenModeBar({
        isPicker: this.isPicker
      })
        .hitTestBehavior(HitTestMode.Default)
        .opacity((this.mCustomFilterImmersVisibility && !this.isPicker) ? this.mModeBarOpacity : (this.animateOpacity ?
          (this.immersiveUIType === UIOperationType.MODE_BAR ? 1 : this.immersiveOpacity) : 0))
        .visibility(this.isShowBigScreenModeBar() ? Visibility.Visible : Visibility.Hidden)
        .enabled(this.isDisModeBar())
        .position({
          x: this.modeBarAnimatePosition.x - MODE_BAR_ALIGNMENT_FOOT_BAR_X,
          y: !this.isLockRotation && (this.displayInfo.rotation === 3 || this.displayInfo.rotation === 1) ?
            this.modeBarAnimatePosition.y + MODE_BAR_OFF_LOCK_ROTATION_Y : this.modeBarAnimatePosition.y
        })
        .zIndex(ZIndex.TOP)
    }
  }

  @Builder
  paramBarBuilder() {
    if (this.state.isShowParamBar) {
      // 开启屏幕朗读的时候限制宽度 防止遮挡其他组件的聚焦
      if (this.enableScreenReader) {
        LandscapeParamBar({
          isHdr: this.isHdr
        })
          .height(this.isShowSemiCollapsed ? EXTEND_BAR_HEIGHT : '100%')
          .width(MIDDLE_COMPONENT_WIDTH)
          .opacity(this.animateOpacity ?
            (!this.isShowMorePage && this.immersiveUIType === UIOperationType.PARAM_BAR ? 1 : this.immersiveOpacity) :
            0)
          .hitTestBehavior(HitTestMode.Transparent)
          // 专业模式下隐藏  避免遮挡LandProfessionBar的聚焦
          .visibility(this.getParamVisible())
          .position(this.paramAnimatePosition)
          .zIndex(0)
          .transition(treasureBoxConfig.getListReleaseAnimation())
      } else {
        LandscapeParamBar({
          isHdr: this.isHdr
        })
          .height(this.isShowSemiCollapsed ? EXTEND_BAR_HEIGHT : '100%')
          .width(MIDDLE_COMPONENT_WIDTH)
          .opacity(this.animateOpacity ?
            (!this.isShowMorePage && this.immersiveUIType === UIOperationType.PARAM_BAR ? 1 : this.immersiveOpacity) :
            0)
          .transition(treasureBoxConfig.getListReleaseAnimation())
          .hitTestBehavior(HitTestMode.Transparent)
          .visibility(this.getParamVisible())
          .position(this.paramAnimatePosition)
          .zIndex(ZIndex.MIDDLE_TOP)
      }
    }
  }

  @Builder
  videoTimerBuilder() {
    if (!this.isShowMorePage && (this.showTimer && !this.isSuperSlowMotion && !this.isTimelapseFront)) {
      VideoTimer({
        videoTimerPosition: Math.abs(this.pageHeight - this.pageWidth) >> 1,
        previewAnimatePosition: this.previewAnimatePosition,
        isHdr: this.isHdr
      })
        .position({ x: 0, y: 0 })
        .opacity(this.timerOpacity)
        .hitTestBehavior(HitTestMode.None)
        .visibility(this.videoTimerState ? Visibility.Visible : Visibility.Hidden)
    }
  }

  @Builder
  floatingShutterButtonBuilder() {
    if (this.state.isFloatingShutterShow && !this.state.isShowPageView && !this.showPicker && !this.isShowMorePage) {
      FloatingShutterButton({
        isPicker: this.isPicker,
        isHdr: this.isHdr,
        previewPosition: this.previewAnimatePosition
      })
        .zIndex(ZIndex.SKETCH_INDEX)
        .position({ x: 0, y: 0 })
        .visibility(this.immersiveUIType === UIOperationType.FOOT_BAR || this.immersiveOpacity !== 0 ?
          Visibility.Visible : Visibility.Hidden)
    }
  }

  @Builder
  gestureBuilder() {
    if (this.isShowSemiCollapsed && this.isShowFunctionModule && !this.state.isShowLowAngleShotView) {
      Stack() {
      }
      .width(this.pageWidth / 2)
      .height(this.pageHeight)
      .position({ left: 0 })
      .hitTestBehavior(HitTestMode.Transparent)
      .clip(true)
      .backgroundColor(Color.Transparent)
      .enabled(!this.isDownSuperSlowBtn)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
      .onTouch((event: TouchEvent) => {
        if (TouchType.Down === event.type) {
          ComponentSnapshotService.getInstance().setIsInSnapshot(true);
          BlurAnimateUtil.generatePixelMapFromSurface();
          ComponentSnapshotService.getInstance().setIsInSnapshot(false);
        }
      })
      .gesture(
        GestureGroup(
          GestureMode.Exclusive,
          TapGesture({ fingers: 1, count: 1 })
            .onAction(() => this.onFunctionalAreaClicked()),
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
              if (this.isSwipeRecord()) {
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
            direction: SystemLanguageUtil.isRTL() ? PanDirection.Down : PanDirection.Up,
            distance: 10
          })
            .onActionStart((): void => {
              if (!this.isShowtimeLapse && this.state.videoState === RecordingState.READY &&
                !this.isLongExposure && !this.isDownSuperSlowBtn && !this.isDepthFusionBarShow &&
                !this.isProShuttering) {
                this.mAction.swipeChangeMode(1);
              }
            }),
          PanGesture({
            fingers: 1,
            direction: SystemLanguageUtil.isRTL() ? PanDirection.Up : PanDirection.Down,
            distance: 10
          })
            .onActionStart((): void => {
              if (!this.isShowtimeLapse && this.state.videoState === RecordingState.READY &&
                !this.isLongExposure && !this.isDownSuperSlowBtn && !this.isDepthFusionBarShow &&
                !this.isProShuttering) {
                this.mAction.swipeChangeMode(-1);
              }
            })
        )
      )
    }
  }

  @Builder
  frontCameraTipsBuilder() {
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      RelativeContainer() {
        Canvas(this.frontTipAnimationContext)
          .width(28)
          .height(28)
          .position(this.tipPosition)
          .onReady(() => {
            HiLog.i(TAG, 'show frontCameraTip');
            this.frontTipAnimationContext.imageSmoothingEnabled = true;
            this.frontTipAnimationContext.imageSmoothingQuality = 'medium';
            this.frontTipAnimationItem?.destroy();
            this.frontTipAnimationItem = lottie.loadAnimation({
              container: this.frontTipAnimationContext,
              renderer: 'canvas',
              loop: false,
              autoplay: true,
              name: 'front_camera_ring',
              path: 'common/lottie/front_camera_ring.json',
            })
            this.frontTipAnimationItem.addEventListener('complete', (): void => {
              this.frontTipAnimationItem?.destroy();
            });
          })
          .onDisAppear(() => {
            this.frontTipAnimationItem?.destroy();
          })
          .zIndex(ZIndex.TOP)

        if (this.isLoaded === FRONT_TIP_UNLOADED || this.isLoaded === FRONT_TIP_APPEARING) {
          Text($r('app.string.front_camera_location_tip'))
            .alignRules(this.tipTextAlignOption)
            .margin({
              top: this.tipTextTopMargin,
              bottom: this.tipTextBottomMargin,
              right: this.tipTextRightMargin,
              left: this.tipTextLeftMargin
            })
            .fontColor('#FFFFFF')
            .fontSize(11)
            .backgroundColor('#80000000')
            .padding({
              right: 16,
              left: 16,
              top: 8,
              bottom: 8
            })
            .borderRadius(8)
            .onAppear(() => {
              if (this.isLoaded != FRONT_TIP_LOADED) {
                if (this.enableScreenReader) {
                  setTimeout(() => {
                    this.isLoaded = FRONT_TIP_LOADED;
                    PreferencesService.getInstance()
                      .putPropValue(PersistType.FOREVER, PropTag.IS_FRONT_CAMERA_TIPS_LOADED, FRONT_TIP_LOADED);
                  }, EYE_TIP_ANIM);
                } else {
                  this.isLoaded = FRONT_TIP_APPEARING;
                  PreferencesService.getInstance()
                    .putPropValue(PersistType.FOREVER, PropTag.IS_FRONT_CAMERA_TIPS_LOADED, FRONT_TIP_APPEARING);
                }
              }
            })
            .rotate({
              angle: this.tipTextRotateAngel,
              centerX: this.tipTextRotateCenterX, centerY: this.tipTextRotateCenterY
            })
            .offset({ x: this.tipTextOffsetX, y: this.tipTextOffsetY })
            .zIndex(ZIndex.TOP)
            .id('front_camera_tip')
        }
      }
      .width('100%')
      .height('100%')
      .zIndex(ZIndex.BOTTOM)
      .hitTestBehavior(HitTestMode.None)
    }
  }

  private locateTipPosition(direction: number) {
    const tipsLength = 28;
    let tipX = LandscapeIndex.defaultTipPosition.x;
    let tipY = LandscapeIndex.defaultTipPosition.y;
    switch (direction) {
      case WindowDirection.TOP:
        this.tipPosition = LandscapeIndex.defaultTipPosition;
        break;
      case WindowDirection.BOTTOM:
        tipX = this.pageWidth - LandscapeIndex.defaultTipPosition.x - tipsLength;
        tipY = this.pageHeight - LandscapeIndex.defaultTipPosition.y - tipsLength;
        this.tipPosition = { x: tipX, y: tipY }
        break;
      case WindowDirection.LEFT:
        tipX = this.pageWidth - LandscapeIndex.defaultTipPosition.y - tipsLength;
        tipY = LandscapeIndex.defaultTipPosition.x;
        this.tipPosition = { x: tipX, y: tipY }
        break;
      case WindowDirection.RIGHT:
        tipX = LandscapeIndex.defaultTipPosition.y;
        tipY = this.pageHeight - LandscapeIndex.defaultTipPosition.x - tipsLength;
        this.tipPosition = { x: tipX, y: tipY };
        break;
      default:
        HiLog.e(TAG, 'locateTipPosition get error direction');
    }
    HiLog.i(TAG, `locateTipPosition end, final position (${tipX}, ${tipY})`);
  }

  private resetTipTextAlignRules(direction: number) {
    if (SystemLanguageUtil.isRTL()) {
      if (direction === WindowDirection.TOP) {
        this.tipTextAlignOption = {
          'right': { 'anchor': '__container__', 'align': HorizontalAlign.End }
        };
      } else if (direction === WindowDirection.RIGHT) {
        this.tipTextAlignOption = {
          'right': { 'anchor': '__container__', 'align': HorizontalAlign.End }
        };
      } else if (direction === WindowDirection.BOTTOM) {
        this.tipTextAlignOption = {
          'left': { 'anchor': '__container__', 'align': HorizontalAlign.Start },
          'bottom': { 'anchor': '__container__', 'align': VerticalAlign.Bottom }
        };
      } else if (direction === WindowDirection.LEFT) {
        this.tipTextAlignOption = {
          'left': { 'anchor': '__container__', 'align': HorizontalAlign.Start }
        };
      } else {
        HiLog.e(TAG, 'getTipTextAlignRules wrong direction');
      }
      return;
    }
    if (direction === WindowDirection.TOP || direction === WindowDirection.RIGHT) {
      this.tipTextAlignOption = {
        'left': { 'anchor': '__container__', 'align': HorizontalAlign.Start }
      }
    } else if (direction === WindowDirection.BOTTOM) {
      this.tipTextAlignOption = {
        'right': { 'anchor': '__container__', 'align': HorizontalAlign.End },
        'bottom': { 'anchor': '__container__', 'align': VerticalAlign.Bottom }
      }
    } else if (direction === WindowDirection.LEFT) {
      this.tipTextAlignOption = {
        'right': { 'anchor': '__container__', 'align': HorizontalAlign.End }
      }
    } else {
      HiLog.e(TAG, 'getTipTextAlignRules wrong direction');
    }
  }

  private resetTipTextMargin(direction: number) {
    const tipsLength = 28;
    if (direction === WindowDirection.TOP) {
      this.tipTextTopMargin = tipsLength + this.tipPosition.y + 16;
      this.tipTextBottomMargin = 0;
      this.tipTextLeftMargin = this.tipPosition.x;
      this.tipTextRightMargin = 0;
    }

    if (direction === WindowDirection.BOTTOM) {
      this.tipTextTopMargin = 0;
      this.tipTextBottomMargin = tipsLength + 16;
      this.tipTextLeftMargin = 0;
      this.tipTextRightMargin = (this.pageWidth - this.tipPosition.x) - tipsLength;
    }

    if (direction === WindowDirection.LEFT) {
      this.tipTextTopMargin = this.tipPosition.y;
      this.tipTextBottomMargin = 0;
      this.tipTextLeftMargin = 0;
      this.tipTextRightMargin = tipsLength + 16;
    }

    if (direction === WindowDirection.RIGHT) {
      this.tipTextTopMargin = this.tipPosition.y;
      this.tipTextBottomMargin = 0;
      this.tipTextLeftMargin = tipsLength + 16;
      this.tipTextRightMargin = 0;
    }
  }

  private rotateTipText() {
    if (!this.isLockRotation) {
      HiLog.i(TAG, 'isLockRotation is 1, no need to rotate');
      return;
    }
    const orientation = DisplayService.getInstance().getDisplay().orientation;
    let tipTextItem = WindowService.getInstance().getUiContext()?.getComponentUtils()
      .getRectangleById('front_camera_tip');
    let tipTextWidth = px2vp(tipTextItem?.size.width);
    HiLog.d(TAG, `rotate tip text tipTextWidth ${px2vp(tipTextWidth)}, orientation ${orientation},` +
      `mDirection ${this.mDirection}`);
    if (tipTextWidth === 0) {
      tipTextWidth = 130;
    }

    switch (orientation) {
      case display.Orientation.PORTRAIT:
        if (this.mDirection === WindowDirection.TOP) {
          this.tipTextRotateAngel = 90;
          this.tipTextRotateCenterX = '0%';
          this.tipTextRotateCenterY = '0%';
          this.tipTextOffsetX = tipTextWidth;
          this.tipTextOffsetY = 0;
        }
        if (this.mDirection === WindowDirection.BOTTOM) {
          this.tipTextRotateAngel = -90;
          this.tipTextRotateCenterX = '100%';
          this.tipTextRotateCenterY = '100%';
          this.tipTextOffsetX = 0;
          this.tipTextOffsetY = -30;
        }
        if (this.mDirection === WindowDirection.LEFT) {
          this.tipTextRotateAngel = 0;
          this.tipTextOffsetX = 0;
          this.tipTextOffsetY = 0;
        }
        if (this.mDirection === WindowDirection.RIGHT) {
          this.tipTextRotateAngel = 180;
          this.tipTextRotateCenterX = '50%';
          this.tipTextRotateCenterY = '50%';
          this.tipTextOffsetX = 0;
          this.tipTextOffsetY = 0;
        }
        break;
      case display.Orientation.LANDSCAPE:
        if (this.mDirection === WindowDirection.TOP) {
          this.tipTextRotateAngel = 180;
          this.tipTextRotateCenterX = '50%';
          this.tipTextRotateCenterY = '50%';
          this.tipTextOffsetX = 0;
          this.tipTextOffsetY = 0;
        }
        if (this.mDirection === WindowDirection.BOTTOM) {
          this.tipTextRotateAngel = 0;
          this.tipTextOffsetX = 0;
          this.tipTextOffsetY = 0;
        }
        if (this.mDirection === WindowDirection.LEFT) {
          this.tipTextRotateAngel = 90;
          this.tipTextRotateCenterX = '100%';
          this.tipTextRotateCenterY = '100%';
          this.tipTextOffsetX = -30;
          this.tipTextOffsetY = 0;
        }
        if (this.mDirection === WindowDirection.RIGHT) {
          this.tipTextRotateAngel = -90;
          this.tipTextRotateCenterX = '0%';
          this.tipTextRotateCenterY = '100%';
          this.tipTextOffsetX = tipTextWidth;
          this.tipTextOffsetY = 0;
        }
        break;
      case display.Orientation.PORTRAIT_INVERTED:
        if (this.mDirection === WindowDirection.TOP) {
          this.tipTextRotateAngel = -90;
          this.tipTextRotateCenterX = '0%';
          this.tipTextRotateCenterY = '0%';
          this.tipTextOffsetX = 0;
          this.tipTextOffsetY = 30;
        }
        if (this.mDirection === WindowDirection.BOTTOM) {
          this.tipTextRotateAngel = 90;
          this.tipTextRotateCenterX = '100%';
          this.tipTextRotateCenterY = '100%';
          this.tipTextOffsetX = -tipTextWidth;
          this.tipTextOffsetY = 0;
        }
        if (this.mDirection === WindowDirection.LEFT) {
          this.tipTextRotateAngel = 180;
          this.tipTextRotateCenterX = '50%';
          this.tipTextRotateCenterY = '50%';
          this.tipTextOffsetX = 0;
          this.tipTextOffsetY = 0;
        }
        if (this.mDirection === WindowDirection.RIGHT) {
          this.tipTextRotateAngel = 0;
          this.tipTextOffsetX = 0;
          this.tipTextOffsetY = 0;
        }
        break
      case display.Orientation.LANDSCAPE_INVERTED:
        if (this.mDirection === WindowDirection.TOP) {
          this.tipTextRotateAngel = 0;
          this.tipTextOffsetX = 0;
          this.tipTextOffsetY = 0;
        }
        if (this.mDirection === WindowDirection.BOTTOM) {
          this.tipTextRotateAngel = 180;
          this.tipTextRotateCenterX = '50%';
          this.tipTextRotateCenterY = '50%';
          this.tipTextOffsetX = 0;
          this.tipTextOffsetY = 0;
        }
        if (this.mDirection === WindowDirection.LEFT) {
          this.tipTextRotateAngel = -90;
          this.tipTextRotateCenterX = '100%';
          this.tipTextRotateCenterY = '0%';
          this.tipTextOffsetX = -tipTextWidth;
          this.tipTextOffsetY = -10;
        }
        if (this.mDirection === WindowDirection.RIGHT) {
          this.tipTextRotateCenterX = '0%';
          this.tipTextRotateCenterY = '0%';
          this.tipTextRotateAngel = 90;
          this.tipTextOffsetX = 30;
          this.tipTextOffsetY = -10;
        }
        break;
      default:
        HiLog.e(TAG, `get wrong orientation ${orientation}`);
    }
  }

  private changeCameraFrontTip() {
    this.locateTipPosition(this.mInstantDirection);
    this.resetTipTextAlignRules(this.mInstantDirection);
    this.resetTipTextMargin(this.mInstantDirection);
  }

  private initCameraFrontTip() {
    const orientation = DisplayService.getInstance().getDisplay().orientation;
    HiLog.d(TAG, `start to initCameraFrontTip mInstantDirection: ${this.mInstantDirection},` +
      `orientation: ${orientation}, rotateStatus ${this.isLockRotation}, width ${this.pageWidth}, ` +
      `height ${this.pageHeight}`);
    if (this.isLockRotation) {
      const direction = this.convertOrient2Direct(orientation);
      this.locateTipPosition(direction);
      this.resetTipTextAlignRules(direction);
      this.resetTipTextMargin(direction);
      return;
    }
    this.changeCameraFrontTip();
  }

  private convertOrient2Direct(orientation: number): number {
    let direction: number = -1;
    switch (orientation) {
      case display.Orientation.PORTRAIT:
        direction = WindowDirection.LEFT;
        break
      case display.Orientation.LANDSCAPE:
        direction = WindowDirection.BOTTOM;
        break
      case display.Orientation.PORTRAIT_INVERTED:
        direction = WindowDirection.RIGHT;
        break
      case display.Orientation.LANDSCAPE_INVERTED:
        direction = WindowDirection.TOP;
        break
      default:
        HiLog.e(TAG, `get wrong orientation ${orientation}`);
    }
    return direction;
  }

  private hideTipText() {
    HiLog.i(TAG, 'start to hideTipText');
    if (this.isLoaded !== FRONT_TIP_APPEARING) {
      return;
    }
    this.isLoaded = FRONT_TIP_LOADED;
    PreferencesService.getInstance()
      .putPropValue(PersistType.FOREVER, PropTag.IS_FRONT_CAMERA_TIPS_LOADED, FRONT_TIP_LOADED);
  }

  private isShowModeIntroCardEntryBuilder(): boolean {
    if (this.state.videoState !== RecordingState.READY && this.state.videoState !== RecordingState.STOPPING) {
      return false;
    }
    return this.isShowModeIntroCardEntry && !this.isShowMorePage && !this.state.isShowBigText &&
      (this.backFromMoreDetail || this.state.cameraRunningState === CameraRunningState.STARTED) && !this.isPicker;
  }

  private isEnterLongExposure(isLongExposure: boolean): void {
    this.isLongExposure = isLongExposure;
  }

  private updateLogStyleValue(): void {
    this.isLogStyleAssistanceOpen = PreferencesService.getInstance()
      .getPropValue(PersistType.FOREVER, PropTag.IS_LOG_ASSISTANCE_OPEN, false) as boolean;
    this.LogStyleText = this.isLogStyleAssistanceOpen ? $r('app.string.log_assistance_on') :
      $r('app.string.log_assistance_off');
    return;
  }

  private getLogAssistancePosition(): PositionType {
    if (this.isShowSemiCollapsed) {
      return {
        x: this.paramAnimatePosition.x + MODE_BAR_BOTTOM_MARGIN,
        y: this.modeBarAnimatePosition.y + MODE_BAR_INNER_WIDTH_SEMI / 2 - 25
      };
    }
    return {
      x: this.paramAnimatePosition.x - MODE_BAR_BOTTOM_MARGIN,
      y: this.paramAnimatePosition.y + this.pageWidth / 2 + 10
    }
  }

  rotateAngleChanged(changedPropertyName: string) {
  }

  customFilterImmersiveChange(changedPropertyName: string) {
    HiLog.i(TAG, `customFilterImmersiveChange isCustomFilterImmersive: ${this.isCustomFilterImmersive}`);
    if (!this.customCardAppeared && this.isCustomFilterImmersive) {
      this.customCardAppeared = true;
    }
    AppStorage.setOrCreate('CustomFilterImmersive', this.isCustomFilterImmersive);
  }

  updateLayout() {
    HiLog.i(TAG,
      `updateLayout this.windowStatus: ${this.windowStatus} this.windowStateCache: ${this.windowStateCache}`);
    if (this.windowStatus === window.WindowStatusType.FULL_SCREEN && this.windowStateCache ===
    window.WindowStatusType.UNDEFINED) {
    }
    if (this.windowStatus === window.WindowStatusType.FLOATING && (this.windowStateCache ===
    window.WindowStatusType.UNDEFINED || this.windowStateCache === window.WindowStatusType.FULL_SCREEN)) {
      AppStorage.setOrCreate('CustomFilterImmersiveCollaps', this.isCustomFilterImmersive);
    }
    this.windowStateCache = this.windowStatus;
  }

  private isHorizontalAlign(): boolean {
    return DisplayService.getInstance().isHorizontal();
  }
}