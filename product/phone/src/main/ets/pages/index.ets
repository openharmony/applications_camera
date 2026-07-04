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
import lazy { DefaultIndex } from './default/DefaultIndex';
import lazy { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { RecordMode } from '@ohos/common/src/main/ets/function/recordcontrol/RecordMode';
import lazy { RecordAction, RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { Action, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { CameraProxy } from '@ohos/common/src/main/ets/camera/uithread/CameraProxy';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy {
  ImmersiveActionData,
  PositionType,
  SavePowerModeActionData,
  Size,
  WindowEventData
} from '@ohos/common/src/main/ets/utils/types';
import lazy { FunctionFirstToast, PropTag, PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { TabBarAction } from '@ohos/common/src/main/ets/component/tabbar/TabBarAction';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { AdaptiveLayoutService } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLayoutService';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy {
  RequestLocationDialog
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/RequestLocationDialog';
import lazy { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import camera from '@ohos.multimedia.camera';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy {
  CameraAction,
  CameraRunningState,
  CameraStartType,
  CameraStartTypeStruct
} from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy {
  ChangeState,
  execDispatch,
  getStates,
  reduxSubscribe,
  Unsubscribe
} from '@ohos/common/src/main/ets/redux/Store';
import lazy { CaptureAction } from '@ohos/common/src/main/ets/function/capture/CaptureAction';
import lazy { VolumeShutterService } from '@ohos/common/src/main/ets/service/volume/VolumeShutterService';
import lazy { SelfieStickService } from '@ohos/common/src/main/ets/service/selfieStick/SelfieStickService';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import window from '@ohos.window';
import lazy { MoreModeConfig } from '@ohos/common/src/main/ets/mode/MoreModeConfig';

import { NAVIGATION_BAR_HEIGHT,SettingView } from './SettingView';
import lazy { SettingViewData } from '@ohos/common/src/main/ets/function/setting/SettingFunction';
import lazy { CustomTransition, TitleAnimation } from '@ohos/common/src/main/ets/animation/CustomNavigationUtils';
// import lazy { PafUiWidget } from '@ohos-paf/ui-widget-base';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { ThumbnailReminder } from './ThumbnailReminder';
import lazy { curves, display } from '@kit.ArkUI';
import lazy { ModeListManager } from '@ohos/common/src/main/ets/mode/ModeListManager';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import lazy { simpleStringify } from '@ohos/common/src/main/ets/utils/SimpleStringify';
import lazy {
  RemoteCaptureDialog
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/RemoteCaptureDialog';
import lazy { power, screenLock } from '@kit.BasicServicesKit';
import lazy { AppLockThumbnailReminder } from './AppLockThumbnailReminder';
import lazy { RemoteCaptureService } from '@ohos/common/src/main/ets/service/RemoteCapture/RemoteCaptureService';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { ThumbnailActionType } from '@ohos/common/src/main/ets/redux/actions/ThumbnailActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { LeftRightSwipeActionType } from '@ohos/common/src/main/ets/redux/actions/LeftRightSwipeActionType';
import lazy { RecordActionType } from '@ohos/common/src/main/ets/redux/actions/RecordActionType';
import lazy {
  CollaborateControlActionType
} from '@ohos/common/src/main/ets/redux/actions/CollaborateControlActionType';
import lazy {
  CollaborateControlService,
} from '@ohos/common/src/main/ets/service/collaborateControl/CollaborateControlService'
import lazy { SettingViewActionType } from '@ohos/common/src/main/ets/redux/actions/SettingViewActionType';
import lazy { CaptureActionType } from '@ohos/common/src/main/ets/redux/actions/CaptureActionType';
import lazy { MediaLibraryUiService } from '@ohos/common/src/main/ets/utils/LazyImportUtil';
import lazy { PreviewWrap } from './preview/PreviewWrap';
import lazy { ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { BlurAnimateUtil } from '@ohos/common/src/main/ets/utils/BlurAnimateUtil';
import lazy { AspectRatioOperation } from '@ohos/common/src/main/ets/function/aspectratio/AspectRatioOperation';
import lazy {
  GeoLocationSetting
} from '@ohos/extend/src/main/ets/settingcommonfunc/savegeolocation/GeoLocationSetting';
import lazy { SettingsValueUtil } from '@ohos/common/src/main/ets/utils/SettingsValueUtil';
import { DatabaseUtils } from '@ohos/common/src/main/ets/utils/DatabaseUtils';
import lazy { TimedShotView } from '@ohos/extend/src/main/ets/settingcommonfunc/timedshot/TimedShotView';
import { CameraErrorCode } from '@ohos/common/src/main/ets/camera/childthread/modules/CameraInputWrap';
import { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import { DeviceInfo } from "@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo"
import { ConfigurationConstant } from '@kit.AbilityKit';
import bundleManager from '@ohos.bundle.bundleManager';
import lazy { intl } from '@kit.LocalizationKit';


/* instrument ignore file */
const TAG: string = 'Index';
const TEN: number = 10;
const OFFSET_LEFT_20: string = '-20%';
const OFFSET_RIGHT_20: string = '20%';
const OFFSET_LEFT_100: string = '-100%';
const OFFSET_RIGHT_100: string = '100%';

export const COMPONENT_WIDTH: number = 84;

const DELAY_HIDDEN_TIME: number = 10000;
const CONFIRM_PICTURE_TIMER: number = 700;
const NO_NEED_SHOW_TREASURE_BOX_TIP_TIMESTAMP: number = -1;
const DEFAULT_SHOW_TREASURE_BOX_TIP_TIMESTAMP: number = 0;
const SHOW_TREASURE_BOX_TIP_MAX_CNT: number = 3;
const ONE_DAY: number = 1000 * 60 * 60 * 24;
const FRONT_TIP_UNLOADED: number = 0;
const FRONT_TIP_APPEARING: number = 1;
const TIMEOUT_INIT_CAMERA: number = 200;

interface DialogParams {
  show?: boolean, // 展示弹窗
  isCustomStyle: boolean, // 是否自定义风格
  deviceName?: string
}

interface DialogResult {
  isGranted: boolean,
  isOnce?: boolean
};

class MirrorSelfieSettingStruct {
  public isShowMirrorSelfieSetting: boolean = false;
}

class PreviewFrameStartData {
  public isPreviewFrameStart: boolean = false;
}

class StateStruct {
  public isShowPageView: boolean = false;
  public isShowtimeLapse: boolean = false;
  public isThirdPartyCall: boolean = false;
  public isOpenTreasureBox: boolean = false;
  public isShowDefault: boolean = true;
  public isVdeCollapsedOnForeground: boolean = true;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public isShowWatermarkPage: boolean = false;
  public photoBrowserStatus: Boolean = false;
  public isDuringSavePowerMode: boolean = false;
  public thumbnailReminderShow: boolean = false;
  public appLockReminderShow: boolean = false;
  public isLockRotation: boolean = true;
  public isShowLowAngleShotView: boolean = false;
  public cameraRunningState: CameraRunningState = CameraRunningState.UNINITIALIZED;
  public isShowTimedShot: boolean = false;
  public isWatchMoon: boolean = false;
}

class IndexDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeTimeLapse(isShowtimeLapse: boolean, timeLapseInterrupt?: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse, timeLapseInterrupt));
  }

  public changeTimelapseVideoState(): void {
    this.mDispatch(Action.changeTimelapseVideoState());
  }

  public stopRecording(): void {
    this.mDispatch(RecordAction.stop());
  }

  public confirmCapture(): void {
    this.mDispatch(CaptureAction.confirmCapture());
  }

  public changeFunctionValue(id: FunctionId, value: number | string | boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public changeTreasureBoxSelectorNone(): void {
    this.mDispatch(TreasureBoxAction.changeTreasureBoxSelector(FunctionId.NONE));
  }

  public closeTreasureBox(): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(false));
  }

  public photoBrowserOnBackPress(): void {
    this.mDispatch(Action.photoBrowserOnBackPress());
  }

  public isShowWatermarkPage(isShow: boolean): void {
    this.mDispatch(Action.isShowWatermarkPage(isShow));
  }

  public updateModePosition(withAnimate: boolean = false): void {
    this.mDispatch(Action.updateModePosition(withAnimate));
  }

  public onBackPress(): void {
    this.mDispatch(Action.onBackPress());
  }

  public enableUiWithMode(uiStateMode: UiStateMode, excludeComponent: string): void {
    this.mDispatch(Action.uiStateWithMode(true, uiStateMode, excludeComponent));
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.ZOOM_BAR));
  }

  public handleOnceToast(): void {
    this.mDispatch(Action.handleOnceToast());
  }

  public handleEyeTipAnim(): void {
    this.mDispatch(Action.handleEyeTipAnim());
  }

  public showThumbnailReminder(isShow: boolean): void {
    this.mDispatch(Action.showThumbnailReminder(isShow));
  }

  public showAppLockReminder(isShow: boolean): void {
    this.mDispatch(Action.showAppLockReminder(isShow));
  }

  public endPanorama(): void {
    this.mDispatch(Action.onBackPressPanoramaStop());
  }

  public endStitching(): void {
    this.mDispatch(Action.onBackPressStitchingStop());
  }

  public uiEnabled(uiEnabled: boolean): void {
    this.mDispatch(Action.uiState(uiEnabled));
  }

  public handleMoreModeTabFlashChanged(isEmitFlashChanged: boolean) {
    this.mDispatch(Action.handleMoreModeTabFlashChanged(isEmitFlashChanged));
  }

  public closeCameraToRecent(): void {
    BlurAnimateUtil.generatePixelMapFromSurface();
    this.mDispatch(CameraAction.release(true));
  }

  public warmStartFromRecent(): void {
    this.mDispatch(CameraAction.warmStart());
  }

  public restart(): void {
    this.mDispatch(CameraAction.restart(getStates().get<number>('zoomReducer', 'zoomRatio')))
  }

  public changeTimedShot(isShowTimedShot: boolean, timedShotInterrupt?: boolean): void {
    this.mDispatch(Action.changeTimedShot(isShowTimedShot, !!timedShotInterrupt));
  }
}

class EnterImmersiveData {
  public isImmersive?: boolean = false;
  public mainTrigCompo?: UIOperationType = UIOperationType.NULL;
}

class SwipeRecordLockData {
  public isLocked?: boolean = false;
}

class CollapsStatusData {
  public collapsStatus: display.FoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
}

class VdeCollapsedData {
  public isVdeCollapsed: boolean = false;
}

@Entry(LocalStorage.getShared())
@Component
struct Index {
  @Builder
  PhotoBrowserMap() {
    this.photoBrowserLoader();
  }

  @Builder
  PhotoBrowserMapTemp() {
  }

  @BuilderParam photoBrowserLoader: () => void = this.PhotoBrowserMapTemp;
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State state: StateStruct = new StateStruct();
  private mAction: IndexDispatcher = new IndexDispatcher();
  private mGlobalContext: GlobalContext = GlobalContext.get();
  private mode: ModeType = ModeType.NONE;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  // 录像控制
  @State videoState: RecordingState = RecordingState.READY;
  // 百宝箱
  @StorageLink('treasureBoxSelector') treasureBoxSelector: FunctionId = FunctionId.NONE;
  @State isHalfCollapsLEM: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State isForeground: boolean = false;
  // 大图组件
  @StorageLink('isShowPhotoBrowser') isShowPhotoBrowser: boolean = false;
  @State @Watch('showViewVisibility') isShowViewVisibility: boolean = false;
  @State isStarted: boolean = false;
  // 夜景曝光控制
  @State isShowNightExposure: boolean = false;
  // 沉浸式
  @State immersiveUIType: UIOperationType = UIOperationType.NULL;
  @State immersiveOpacity: number = 1;
  @State isShowMorePage: boolean = false;
  @State isEditMorePage: boolean = false;
  //预授权启动页是否显示过
  // @StorageLink('isIntroLoaded') @Watch('')isIntroLoaded: boolean = false;
  @StorageLink('isRequestedPermission') isRequestedPermission: boolean = false;
  @Provide('pageInfos') @Watch('handlePageInfoStatus') pageInfos: NavPathStack = new NavPathStack();
  private volumeService: VolumeShutterService = VolumeShutterService.getInstance();
  private selfieStickService: SelfieStickService = SelfieStickService.getInstance();
  //页面超时
  private mPageShowTimeout: number = 100;
  //帧率控制
  frameRateSaving: boolean = false;
  INDEX_SEC: number = 2;
  FRAME_RATE_60FPS: number = 60;
  @State @Watch('statusChanged') isShowSemiCollapsed: boolean = false;
  @State @Watch('onLandscapeChanged') isShowLandscape: boolean = false;
  @State @Watch('statusChanged') isShowTricollaps: boolean = false;
  @State @Watch('isShowTBTip') isNeedShowTBTip: boolean = false;
  @StorageLink('isSemiCollapsedGuideLoad') isSemiCollapsedGuideLoad: boolean = false;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @StorageLink('isPSDCollaps') isPSDCollapsed: boolean = false;
  @StorageLink('isGuidanceLoaded') @Watch('isGuidanceLoadedChange') isGuidanceLoaded: boolean = false;
  // 慢动作相关
  @StorageLink('isDownSuperSlowBtnState') isDownSuperSlowBtn: boolean = false;
  @StorageLink('isProShutterCaptureState') isProShutterCapture: boolean = false;
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State translateContent: number | string = 0;
  @State translateBlackPage: number | string = OFFSET_RIGHT_100;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  // 全景相关
  @State isPanoramaStart: boolean = false;
  //百香果相关
  @State isStitchingStart: boolean = false;
  private isInImmersive: boolean | undefined = false;
  // 详情卡片按钮跳转
  @StorageLink('isDetailCardMoreButtonClicked') isDetailCardMoreButtonClicked: boolean = false;
  @StorageLink('isNightShutting') isNightShutting: boolean = false;
  // 显示熄屏快拍图片
  @State @Watch('autoCloseShowUltraSnapshot') showUltraSnapshot: boolean = false;
  @State showCustomFilterTaskPool: boolean = false;
  // 环形补光
  @State isShowRingLightView: boolean = false;
  // 长曝光
  @State isLongExposure: boolean = false;
  @State isShowSettingView: boolean = false;
  private requestLocationDialogController: CustomDialogController | null = null;
  private moreModeConfig: MoreModeConfig = MoreModeConfig.getInstance();
  private isRequestLocation: boolean = false;
  private checkTreasureBoxTipFunc: () => void = () => {
    this.checkTreasureBoxTip()
  };
  @State isShowFlipTipView: boolean = false;
  private mTimer: number = Number.MIN_VALUE;
  @StorageLink('showPhotoBrowserAction') @Watch('showPhotoBrowserOnChange') showPhotoBrowserAction: boolean = false;
  private confirmRemoteCaptureDialogController: CustomDialogController | null = null;
  @StorageLink('isRemoteCapture') isRemoteCapture: boolean = false;
  private isRemoteCaptureDialogOpened: boolean = false;
  private mShowTBTipCnt: number = -1;
  @StorageLink('isChangingModeOrSwitchingCamera') isChangingModeOrSwitchingCamera: boolean = false;
  @State isShowMirrorSelfieSetting: boolean = false;
  @State isVideoOutput: boolean = false;
  @State isApplyHdr: boolean = false;
  @State isHdr: boolean = false;
  @StorageLink('isOpenHdrBrightness') isOpenHdrBrightness: boolean = false;
  private isMultiTaskStopStream: boolean = CameraAppCapability.getInstance().getIsSupportStopStreamToMultiTask();
  private isPhotoBrowserInWindowStagePaused: boolean = false;
  @StorageLink('isAnyDialogOpening') @Watch('dialogStatusOnChange') isAnyDialogOpening: boolean = false;
  @State lastWindowStatus: window.WindowStageEventType | undefined = undefined;
  @StorageLink('onCustomFilterTopLineChange') customFilterTopLineHeight: number = 0;
  @Prop isCustomFilterImmersive: boolean = false;
  @State xComponentWidth: number = getStates().get<number>('previewReducer', 'xComponentWidth');
  @State xComponentHeight: number = getStates().get<number>('previewReducer', 'xComponentHeight');
  @LocalStorageLink('previewAnimatePosition') previewAnimatePosition: PositionType =
    { x: 0, y: 0 };

  @Builder
  PageMap(navigationName: string) {
    if (navigationName === 'SettingView') {
      SettingView({ pageId: Date.now() });
    }
  }

  aboutToAppear(): void {
    HiLog.begin(TAG, 'aboutToAppear');
    // PafUiWidget.init(GlobalContext.get().getWindowStage(), ContextManager.getInstance().getAbilityContext());
    this.registerEvent();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      changeState(this.state, {
        isShowPageView: state.get<boolean>('settingViewReducer', 'isShowSettingView'),
        isShowtimeLapse: state.get<boolean>('settingReducer', 'isShowtimeLapse'), // 是否显示定时拍照倒计时
        isThirdPartyCall: state.get<boolean>('contextReducer', 'isThirdPartyCall'),
        isOpenTreasureBox: state.get<boolean>('treasureBoxReducer', 'isOpen'),
        isShowDefault: state.get<boolean>('collapsReducer', 'isShowDefault'),
        isVdeCollapsedOnForeground: state.get<boolean>('collapsReducer', 'isVdeCollapsedOnForeground'),
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        isShowWatermarkPage: state.get<boolean>('uiReducer', 'isShowWatermarkPage'),
        photoBrowserStatus: state.get<boolean>('thumbnailReducer', 'photoBrowserStatus'),
        isDuringSavePowerMode: state.get<boolean>('contextReducer', 'isDuringSavePowerMode'),
        thumbnailReminderShow: state.get<boolean>('securityCameraReducer', 'thumbnailReminderShow'),
        appLockReminderShow: state.get<boolean>('securityCameraReducer', 'appLockReminderShow'),
        isLockRotation: state.get<boolean>('windowReducer', 'isLockRotation'),
        isShowLowAngleShotView: state.get<boolean>('collapsReducer', 'isShowLowAngleShotView'),
        cameraRunningState: state.get<CameraRunningState>('cameraReducer', 'cameraRunningState'),
        isShowTimedShot: state.get<boolean>('settingReducer', 'isShowTimedShot'),
        isWatchMoon: state.get<boolean>('watchMoonReducer', 'watchMoonEnable'),
      });
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isForeground = state.get<boolean>('contextReducer', 'isForeground');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.isEditMorePage = state.get<boolean>('modeReducer', 'isEditMorePage');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      this.mDirection = state.get<number>('contextReducer', 'direction');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isShowFlipTipView = state.get<boolean>('backSelfieReducer', 'isShowFlipTipView');
      this.isShowViewVisibility = state.get<boolean>('contextReducer', 'isViewVisibility');
      this.isCustomFilterImmersive = state.get<boolean>('customFilterStyleReducer', 'isCustomFilterImmersive');
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    // this.isIntroLoaded = PreferencesService.getInstance()
    //   .getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean;
    this.isRequestedPermission = PreferencesService.getInstance()
      .getPropValue(PersistType.FOREVER, PropTag.IS_REQUESTED_PERMISSION, false) as boolean;
    this.isSemiCollapsedGuideLoad = PreferencesService.getInstance()
      .getPropValue(PersistType.FOREVER, PropTag.IS_SEMI_COLLAPSED_GUIDE_LOAD, false) as boolean;
    this.initializeGuidancePages();
    this.initializeTBTipWithoutFirstEnter();
    this.skipIntro()
    this.skipGuidancePages()
    HiLog.end(TAG, 'aboutToAppear');
  }

  private registerEvent(): void {
    const code = this.mBase.hashCode();
    this.mEventBus.on(CameraActionType.STARTED, this.indexOnStarted.bind(this), code);
    this.mEventBus.on(CameraActionType.CHANGE_MODE, this.onChangeMode.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_NIGHT_FRAME_SHUTTER, this.onNightFrameShutter.bind(this), code);
    this.mEventBus.on([ActionType.ACTION_RESET_EXPOSURE_TIME, CameraActionType.STARTED],
      this.onResetExposureTime.bind(this),
      code);
    this.mEventBus.on([ActionType.ACTION_CHANGE_TIME_LAPSE, ActionType.ACTION_IS_ENTER_IMMERSIVE],
      this.isEnterImmersive.bind(this), code);
    this.mEventBus.on([ActionType.ACTION_CHANGE_TIMED_SHOT, ActionType.ACTION_IS_ENTER_IMMERSIVE],
      this.isEnterImmersive.bind(this), code);
    this.mEventBus.on(ThumbnailActionType.PHOTOBROWSER_STATUS, this.onPhotoBrowserStatus.bind(this), code);
    this.mEventBus.on(ContextActionType.CHANGE_WINDOW_EVENT_TYPE, this.onWindowEventType.bind(this), code);
    this.mEventBus.on(SettingViewActionType.ACTION_SHOW_SETTING_VIEW, this.onSettingViewShow.bind(this), code);
    this.mEventBus.on(CameraActionType.PREEMPTION_WITH_ERROR, this.stopCameraRecording.bind(this), code);
    this.mEventBus.on([ActionType.ACTION_IS_START_PANORAMA], () => this.isStartPanorama(true), code);
    this.mEventBus.on(ActionType.ACTION_CLEAR_PAGE_OR_DIALOG, this.popPage.bind(this), code);
    this.mEventBus.on(ActionType.ACTION_IS_END_PANORAMA, () => this.isStartPanorama(false), code);
    this.mEventBus.on(ActionType.ACTION_ON_PHOTO_STOP_PANORAMA, () => this.isStartPanorama(false), code);

    this.mEventBus.on(ActionType.ACTION_START_STITCHING_CAPTURE, () => this.isStartStitching(true), code);
    this.mEventBus.on(CaptureActionType.CONFIRM_CAPTURE, () => this.isStartStitching(false), code);
    this.mEventBus.on(ActionType.ACTION_END_STITCHING_CAPTURE, () => this.isStartStitching(false), code);
    this.mEventBus.on(ActionType.ACTION_FINISH_STITCHING_CAPTURE, () => this.isStartStitching(false), code);
    this.mEventBus.on(ActionType.ACTION_LOAD_PHOTO_BROWSER, this.loadPhotoBrowser.bind(this), code);

    this.mEventBus.on(ActionType.ACTION_IS_ENTER_IMMERSIVE, this.lockScreenRotation.bind(this), code);
    this.mEventBus.on(LeftRightSwipeActionType.RECORD_LOCK_STATUS_CHANGE, this.rotationUnLockedBySwipeRecord.bind(this),
      code);
    this.mEventBus.on(ActionType.ACTION_LONG_EXPOSURE_SHUTTER, this.longExposureStart.bind(this), code);
    this.mEventBus.on(ContextActionType.UPDATE_SAVE_POWER_MODE_STATE, (data: SavePowerModeActionData) =>
    this.updateSavePowerModeState(data), code);
    this.mEventBus.on([RecordActionType.START,
      ActionType.ACTION_CAPTURE_EFFECT], () => this.checkRequestLocationDialogClose(),
      code);
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, () => this.onBackground(), code);
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, () => this.onForeground(), code);
    this.mEventBus.on(ActionType.ACTION_COMMON_CAPTURE_PERMISSION_DIALOG, this.isShowCommonCaptureDialog.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.SOURCE_CONNECT, this.onCollaborateControlSourceConnect.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.SOURCE_DISCONNECT,
      this.onCollaborateControlSourceDisconnect.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.CHANGE_OUTPUT_TYPE,
      CameraActionType.SWITCH_CAMERA_CHANGE_MODE, CameraActionType.SWITCH_CAMERA],
      this.onChangeModeOrSwitchCamera.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SUPPORT_HDR_BRIGHTNESS,
      (data: ActionData) => this.updateHDRBrightnessSupport(data), this.mBase.hashCode());
  }

  private onForeground(): void {
    HiLog.i(TAG, 'onForeground');
    this.isPhotoBrowserInWindowStagePaused = false;
  }

  private onBackground(): void {
    this.stopCameraRecording();
    this.checkRequestLocationDialogClose();
  }

  private onChangeModeOrSwitchCamera(): void {
    this.isChangingModeOrSwitchingCamera = true;
  }

  private longExposureStart(data: boolean) {
    this.isLongExposure = data;
  }

  private autoCloseShowUltraSnapshot(): void {
    if (!this.showUltraSnapshot) {
      return;
    }
    this.confirmPicture();
  }

  private confirmPicture(): void {
    HiLog.i(TAG, 'confirm picture end.');
    setTimeout(() => {
    }, CONFIRM_PICTURE_TIMER);
  }

  private rotationUnLockedByCollapsChange(data: CollapsStatusData): void {
    this.wakUpScreen(data);
    if (display.FoldStatus.FOLD_STATUS_EXPANDED === data?.collapsStatus) {
      return;
    }
    HiLog.i(TAG, 'rotationUnLocked CollapsChange');
    // 仅触发于大屏进入沉浸式锁定后直接切换状态的情况，因此不需要锁定ui元素到窗口方向
    WindowService.getInstance().setForceUnlockWindowRotation(false);
  }

  private wakUpScreen(data: CollapsStatusData): void {
    // 锁屏相机未设置密码状态下，切换状态，使屏幕亮起
    if (GlobalContext.get().getObject('isSecurityCamera') &&
      display.FoldStatus.FOLD_STATUS_FOLDED === data?.collapsStatus) {
      try {
        setTimeout((): void => {
          power.wakeup('security_camera');
        }, TIMEOUT_INIT_CAMERA);
      } catch (e) {
        HiLog.e(TAG, `power wakeup error: ${simpleStringify(e)}.`);
      }
    }
  }

  private rotationUnLockedBySwipeRecord(data: SwipeRecordLockData): void {
    if (data?.isLocked) {
      HiLog.i(TAG, 'rotationUnLocked SwipeRecord');
      WindowService.getInstance().setForceUnlockWindowRotation(true);
    }
  }

  private lockScreenRotation(data: EnterImmersiveData): void {
    this.isInImmersive = data.isImmersive;
    HiLog.i(TAG, 'lockScreenRotation:' + this.isInImmersive);
    if (this.isInImmersive) {
      WindowService.getInstance().setLockWindowRotation(true);
    } else {
      WindowService.getInstance().setLockWindowRotation(false);
    }
  }

  private directionChange(): void {
    if (this.mDirection === WindowDirection.BOTTOM) {
      return;
    }
    if (this.translateContent === 0) {
      this.translateBlackPage = this.state.isLockRotation ? OFFSET_RIGHT_100 :
        this.mDirection === WindowDirection.LEFT ? OFFSET_LEFT_100 : OFFSET_RIGHT_100;
    } else {
      this.translateContent = this.mDirection === WindowDirection.LEFT ? OFFSET_RIGHT_20 : OFFSET_LEFT_20;
      this.translateBlackPage = this.state.isLockRotation ? OFFSET_RIGHT_20 :
        this.mDirection === WindowDirection.LEFT ? OFFSET_LEFT_20 : OFFSET_RIGHT_20;
    }
  }

  private isVertical(): boolean {
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  private onNightFrameShutter(): void {
    this.updateShowNightExposure(true);
  }

  private onResetExposureTime(): void {
    this.updateShowNightExposure(false)
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear clear');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  private isStartPanorama(isStart: boolean): void {
    this.isPanoramaStart = isStart;
  }

  private isStartStitching(isStart: boolean): void {
    this.isStitchingStart = isStart
  }

  onBackPress(): boolean {
    HiLog.i(TAG, 'onBackPress E.-' + this.state.isDuringSavePowerMode);
    this.mAction.onBackPress();
    if (this.state.cameraRunningState === CameraRunningState.STARTING) {
      // 起流过程中不允许back推后台，防止相机黑屏卡死
      HiLog.i(TAG, `cameraRunningState: ${this.state.cameraRunningState}.`);
      return true;
    }
    if (this.isProShutterCapture) {
      HiLog.i(TAG, 'isProShutterCapture.-' + this.isProShutterCapture);
      return true;
    }

    if (this.state.isDuringSavePowerMode) {
      HiLog.i(TAG, 'isDuringSavePowerMode.-' + this.state.isDuringSavePowerMode);
      return true;
    }
    if (this.isEditMorePage || this.isShowMorePage) {
      HiLog.i(TAG, 'showMore.-' + this.isShowMorePage + ',isEditMorePage.-' + this.isEditMorePage);
      this.backPressOnShowMore();
      return true;
    }
    if (this.isShowPhotoBrowser) {
      HiLog.i(TAG, 'isShowPhotoBrowser.-' + this.isShowPhotoBrowser);
      this.mAction.photoBrowserOnBackPress();
      return true;
    }
    if (this.state.isShowWatermarkPage) {
      HiLog.i(TAG, 'isShowWatermarkPage.-' + this.state.isShowWatermarkPage);
      this.mAction.isShowWatermarkPage(false);
      return true;
    }
    if (this.state.thumbnailReminderShow) {
      HiLog.i(TAG, 'thumbnailReminderShow.-' + this.state.thumbnailReminderShow);
      this.mAction.showThumbnailReminder(false);
      return true;
    }
    if (this.state.appLockReminderShow) {
      HiLog.i(TAG, 'appLockReminderShow.-' + this.state.appLockReminderShow);
      this.mAction.showAppLockReminder(false);
      return true;
    }
    if (this.state.isShowPageView) {
      HiLog.i(TAG, 'isShowPageView.-' + this.state.isShowPageView);
      this.mAction.changeFunctionValue(FunctionId.SETTING, false);
      return true;
    }
    if (this.state.isShowtimeLapse) {
      HiLog.i(TAG, 'isShowtimeLapse.-' + this.state.isShowtimeLapse);
      this.mAction.changeTimeLapse(false, true);
      return true;
    }
    if (this.state.isThirdPartyCall) {
      HiLog.i(TAG, 'isThirdPartyCall.-' + this.state.isThirdPartyCall);
      PickerUiService.getInstance().terminateSelfWithResult();
      return true;
    }
    if (this.videoState === RecordingState.STARTING) {
      HiLog.i(TAG, 'videoState: ' + this.videoState);
      return true;
    }
    if (this.videoState === RecordingState.RECORDING || this.videoState === RecordingState.PAUSED ||
      this.videoState === RecordingState.RESUMING) {
      HiLog.i(TAG, 'videoState.-' + this.videoState);
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
      return true;
    }
    if (this.isShowNightExposure) {
      HiLog.i(TAG, 'isShowNightExposure.-' + this.isShowNightExposure);
      this.mAction.confirmCapture();
      return true;
    }
    if (!this.isShowLandscape && this.treasureBoxSelector !== FunctionId.NONE) {
      HiLog.i(TAG, 'treasureBoxSelector.-' + this.treasureBoxSelector + 'isShowLandscape.-' + this.isShowLandscape);
      this.mAction.changeTreasureBoxSelectorNone();
      return true;
    }
    if (!this.isShowLandscape && this.state.isOpenTreasureBox && !this.isHalfCollapsLEM && !this.isVdeCollapsed) {
      HiLog.i(TAG, 'isOpenTreasureBox.-' + this.state.isOpenTreasureBox + 'isShowLandscape.-' + this.isShowLandscape);
      this.mAction.closeTreasureBox();
      return true;
    }
    if (this.isPanoramaStart) {
      HiLog.i(TAG, 'isPanoramaStart.-' + this.isPanoramaStart);
      this.mAction.endPanorama();
      return true;
    }

    if (this.isStitchingStart) {
      HiLog.i(TAG, 'isStitchingStart.-' + this.isStitchingStart);
      this.mAction.endStitching();
      return true
    }

    if (this.isShowFlipTipView) {
      return true;
    }

    if (this.state.isShowTimedShot) {
      this.mAction.changeTimedShot(false, true);
      return true;
    }

    HiLog.i(TAG, 'onBackPress X.');
    return false;
  }

  private backPressOnShowMore(): void {
    if (!this.isEditMorePage) {
      this.moreModeConfig.entryAOutMorePage(false);
      if (this.moreModeConfig.isSupportMorePage() && !ModeListManager.getInstance().includes(this.mode)) {
        this.moreModeConfig.modifyMoreModeListAndName(this.mode);
      }
      this.mAction.updateModePosition(true);
    }
    this.moreModeConfig.editMorePage(false);
  }

  onPageShow(): void {
    HiLog.i(TAG, 'onPageShow.');
    HiLog.d(TAG, `screen is locked: ${screenLock.isLocked()}`);
    setTimeout((): void => {
    }, this.mPageShowTimeout);
    this.selfieStickService.selfieStickSubscribe();
    this.mAction.updateModePosition();
    MediaLibraryUiService.getInstance().onPageChange(true);
  }

  onPageHide(): void {
    HiLog.i(TAG, 'onPageHide E.');
    HiLog.d(TAG, `screen is locked: ${screenLock.isLocked()}`);
    this.isProShutterCapture = false;
    if (!this.isDetailCardMoreButtonClicked) {
      this.moreModeConfig.entryAOutMorePage(false);
    }
    this.moreModeConfig.editMorePage(false);
    this.selfieStickService.selfieStickUnSubscribe();
    MediaLibraryUiService.getInstance().onPageChange(false);
    HiLog.i(TAG, 'onPageHide X.');
  }

  private showViewVisibility(): void {
    HiLog.i(TAG, 'isShowViewVisibility = ' + this.isShowViewVisibility);
  }

  private onLandscapeChanged(): void {
    this.statusChanged();
  }

  private statusChanged(): void {
    HiLog.i(TAG, `statusChanged isShowSemiCollapsed: ${this.isShowSemiCollapsed},immersiveUIType: ${this.immersiveUIType}.`);
    this.handoverFrameRate();
    if (this.immersiveUIType !== UIOperationType.NULL) {
      if (this.state.isShowtimeLapse && !this.isShowLandscape && !this.isShowSemiCollapsed) { //拍照倒计时而且非半折态
        HiLog.i(TAG, `statusChanged isShowtimeLapse`);
        return;
      }
      this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
    }
    if (!((this.isShowLandscape || this.isShowTricollaps) && !this.isShowSemiCollapsed)) { //非展开态
      WindowService.getInstance().unlockXComponentSurface();
    }
    if (!this.isShowLandscape || !this.isShowSemiCollapsed) { //展开态
      WindowService.getInstance().lockXComponentSurface();
    }
  }

  private showPhotoBrowserOnChange(): void {
    if (!this.showPhotoBrowserAction) {
      return;
    }
    HiLog.i(TAG, `show photo browser: ${this.showPhotoBrowserAction}.`);
    this.checkRequestLocationDialogClose();
  }

  private onSettingViewShow(data: SettingViewData): void {
    HiLog.i(TAG, 'onSettingViewShow E.');
    if (data && data.isShowSettingView) {
      HiLog.i(TAG, 'pageInfos change, push SettingView');
      this.isShowSettingView = true;
      this.pageInfos.pushPath({ name: 'SettingView' });
      this.mAction.uiEnabled(false);
      WindowService.getInstance().setSpecificSystemNavigationEnabled(true, true, true);
      this.checkRequestLocationDialogClose();
    } else {
      HiLog.i(TAG, 'pageInfos change, pop by onSettingViewShow');
      this.isShowSettingView = false;
      this.pageInfos.pop();
      this.mAction.uiEnabled(true);
      WindowService.getInstance().setSpecificSystemNavigationEnabled(true, true, false);
    }
    HiLog.i(TAG, 'onSettingViewShow X.');
  }

  // 模式详情页状态依赖自身上下树，在一些快速极限操作场景，无法第一时间变更闪光灯状态，这里直接根据NavPage所展示的页面来快速处理
  private handlePageInfoStatus(): void {
    let curNavPage: string = this.pageInfos.getAllPathName()[0] as string;
    let isModeDetailPage: boolean = curNavPage === 'ModeDetailView';
    HiLog.i(TAG, `handlePageInfoStatus 0000 ${curNavPage}`);
    AppStorage.setOrCreate<boolean>('isNeedCloseFlashByMDV', isModeDetailPage);
    if (!AppStorage.get<boolean>('isBackground')) { // 退后台不刷闪光灯装态（否则会连续变更两次）
      this.mAction.handleMoreModeTabFlashChanged(isModeDetailPage);
    }
  }

  private updateSavePowerModeState(data: SavePowerModeActionData) {
    HiLog.i(TAG, `Save power mode state: ${data.isDuringSavePowerMode}`);
    if (data.isDuringSavePowerMode) {
      this.checkRequestLocationDialogClose();
    }
  }

  private onWindowEventType(data: WindowEventData): void {
    if (data.windowStageEventType === window.WindowStageEventType.INACTIVE) {
      this.volumeService.volumeKeyUnsubscribe();
      this.selfieStickService.selfieStickUnSubscribe();
    } else if (data.windowStageEventType === window.WindowStageEventType.ACTIVE && !this.state.photoBrowserStatus) {
      this.volumeService.volumeKeySubscribe();
      this.selfieStickService.selfieStickSubscribe();
    } else if (data.windowStageEventType === window.WindowStageEventType.RESUMED) {
      if (this.isMultiTaskStopStream) {
        HiLog.i(TAG, 'isPhotoBrowserInWindowStagePaused: ' + this.isPhotoBrowserInWindowStagePaused +
          ', closeFromWindowPaused: ' + AppStorage.get('closeFromWindowPaused'));
        if (!this.isPhotoBrowserInWindowStagePaused && AppStorage.get('closeFromWindowPaused')) {
          HiLog.i(TAG, 'windowStage resumed, open camera');
          this.mAction.warmStartFromRecent();
        }
        this.isPhotoBrowserInWindowStagePaused = false;
      }
    } else if (data.windowStageEventType === window.WindowStageEventType.PAUSED) {
      if (this.isMultiTaskStopStream) {
        HiLog.i(TAG, 'windowStage paused, close camera');
        HiLog.i(TAG, 'window paused showPhotoBrowserAction: ' + AppStorage.get('showPhotoBrowserAction'));
        if (AppStorage.get('showPhotoBrowserAction')) {
          this.isPhotoBrowserInWindowStagePaused = true;
        } else {
          this.isPhotoBrowserInWindowStagePaused = false;
          AppStorage.setOrCreate('closeFromWindowPaused', true);
          this.mAction.closeCameraToRecent();
        }
      }
    } else if (data.windowStageEventType === window.WindowStageEventType.HIDDEN) {
      if (this.isMultiTaskStopStream) {
        HiLog.i(TAG, 'windowStage hidden, reset closeFromWindowPaused state');
        AppStorage.setOrCreate('closeFromWindowPaused', false);
        this.isPhotoBrowserInWindowStagePaused = false;
      }
    }
  }

  private onPhotoBrowserStatus(): void {
    if (this.state.photoBrowserStatus) {
      this.volumeService.volumeKeyUnsubscribe();
      this.selfieStickService.selfieStickUnSubscribe();
    } else {
      if (AppStorage.get<boolean>('isBackground')) {
        return;
      }
      this.volumeService.volumeKeySubscribe();
      this.selfieStickService.selfieStickSubscribe();
    }
  }

  public stopCameraRecording(): void {
    HiLog.i(TAG, 'stopCameraRecording E.');
    if (this.state.isShowtimeLapse) {
      this.mAction.changeTimeLapse(false);
    }
    if (this.videoState === RecordingState.RECORDING || this.videoState === RecordingState.PAUSED ||
      this.videoState === RecordingState.RESUMING || this.videoState === RecordingState.STARTING) {
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
    }
    HiLog.i(TAG, 'stopCameraRecording X.');
  }

  public updateShowNightExposure(showNightExposure: boolean): void {
    HiLog.i(TAG, 'updateShowNightExposure :' + showNightExposure);
    this.isShowNightExposure = showNightExposure;
    if (!this.isShowNightExposure) {
      this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
    }
  }

  private onChangeMode(): void {
    // 切换模式后订阅智感拍照
    CollaborateControlService.getInstance().subscribeIntelligentSensePhoto(getContext());
  }

  private async indexOnStarted(data: CameraStartTypeStruct): Promise<void> {
    this.isChangingModeOrSwitchingCamera = false;
    if (data.type !== CameraStartType.COLD_START || GlobalContext.get().getPhotoBrowserDisabled()) {
      let canClickThumbnail: boolean | undefined = AppStorage.get('canClickThumbnailView');
      HiLog.i(TAG, `indexOnStarted load,type:${data.type},isStarted:${this.isStarted},canclick:${canClickThumbnail}`);
      if (this.isStarted && canClickThumbnail !== undefined) { // 配流未加载so时，加载一次
        return;
      }
    }
    this.loadPhotoBrowser();
  }

  private loadPhotoBrowser(): void {
    if (this.isStarted || CameraAppCapability.getInstance().getIsSuspendPhotoBrowser()) {
      return;
    }
    HiLog.i(TAG, 'prepareImportBrowser');
    const photoBrowserTimer = setTimeout(async () => {
      if (this.isStarted) {
        return;
      }
      this.isStarted = true;
      HiLog.begin(TAG, 'delayImportBrowser');
      let photoBrowserLoader = await import('./PhotoBrowser');
      this.photoBrowserLoader = photoBrowserLoader.PhotoBrowserLoader;
      HiLog.end(TAG, 'delayImportBrowser');
      clearTimeout(photoBrowserTimer);
    }, 100);
  }

  private handoverFrameRate(): void {
    HiLog.i(TAG, 'handoverFrameRate E.');
    const isPanVideoOutput: boolean = OutputOperation.isPanVideoOutput(this.mode);
    if (!isPanVideoOutput) {
      return;
    }
    AppStorage.setOrCreate('restoreFlag', true);
    const functionImpl: BaseFunction = FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION);
    const frameRateSwitching: BaseFunction = FeatureManager.getInstance().getFunction(FunctionId.FRAME_RATE);
    let videoProfile: camera.VideoProfile = CameraAppCapability.getInstance()
      .getVideoProfiles(camera.CameraPosition.CAMERA_POSITION_FRONT, this.mode)[functionImpl.getValue() - 1];
    HiLog.i(TAG, `handoverFrameRate isShowLandscape=${JSON.stringify(this.isShowLandscape)},
      isShowDefault=${JSON.stringify(this.state.isShowDefault)}.`);
    if (this.isShowLandscape) {
      HiLog.i(TAG, '(this.isShowLandscape.');
      if (this.frameRateSaving) {
        this.frameRateSaving = false;
        this.mAction.changeFunctionValue(FunctionId.FRAME_RATE, this.INDEX_SEC);
      }
    }
    if (!(this.isShowLandscape && !this.isShowSemiCollapsed)) {
      if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
        HiLog.i(TAG, '(this.state.isShowDefault.');
        if (frameRateSwitching.getValue() === this.INDEX_SEC && videoProfile.frameRateRange.max !==
        this.FRAME_RATE_60FPS) {
          this.mAction.changeFunctionValue(FunctionId.FRAME_RATE, frameRateSwitching.getDefaultValue() as number);
          this.frameRateSaving = true;
        }
      }
    }
    AppStorage.setOrCreate('restoreFlag', false);
    HiLog.i(TAG, 'handoverFrameRate x.');
  }

  private isEnterImmersive(data: ImmersiveActionData): void {
    let mIsImmersive: boolean = false;
    let mImmersiveUIType: UIOperationType = data.mainTrigCompo ?? UIOperationType.NULL;
    let json: ImmersiveActionData = JSON.parse(JSON.stringify(data));
    HiLog.i(TAG, `isEnterImmersive json: ${JSON.stringify(data)}.`)
    if (json.isShowtimeLapse !== undefined) { // 定时拍摄需要状态变量渲染组件,就不再重复发Action了直接复用
      mIsImmersive = json.isShowtimeLapse;
      mImmersiveUIType = mIsImmersive ? UIOperationType.TIMELAPSE : UIOperationType.NULL;
    } else {
      if (json.isImmersive !== undefined) {
        mIsImmersive = json.isImmersive;
      }
      if (json.mainTrigCompo !== undefined && mIsImmersive) {
        mImmersiveUIType = json.mainTrigCompo;
      }
    }

    if (mIsImmersive) {
      this.immersiveUIType = mImmersiveUIType;
      // 是否可以移除判断
      if (this.immersiveUIType !== UIOperationType.LR_SWIPE && this.immersiveUIType !== UIOperationType.EXPOSURE) {
        this.immersiveOpacity = 1;
      }
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_150,
        curve: Curve.Sharp,
      }, () => {
        this.immersiveOpacity = 0;
      })
    } else {
      // 是否可以移除判断
      if (this.immersiveUIType !== UIOperationType.LR_SWIPE && this.immersiveUIType !== UIOperationType.EXPOSURE) {
        this.immersiveOpacity = 0;
      }
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_150,
        curve: Curve.Sharp,
        onFinish: () => {
          if (this.isSecondCaptureMode() && this.isNightShutting) {
            this.immersiveUIType = UIOperationType.FOOT_BAR; // 拍照倒计时流光快门拍照按钮消失，150ms duration导致沉浸式时序不对
            return; // 屏蔽掉footbar区域的沉浸式响应
          }
          this.immersiveUIType = mImmersiveUIType; // 保证退出沉浸式时self不受opacity影响
        }
      }, () => {
        this.immersiveOpacity = 1;
      })
    }
  }

  private isSecondCaptureMode(): boolean {
    let curMode = getStates().get<ModeType>('modeReducer', 'mode');
    if (this.isLongExposure) {
      return true;
    }
    return false;
  }

  private initializeGuidancePages(): void {
    this.isGuidanceLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_GUIDANCE_LOADED, false) as boolean;
  }

  private skipIntro(): void {
    HiLog.i(TAG, 'isIntroLoaded true');
    PreferencesService.getInstance().putPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, true);
    let dateFormat = new intl.DateTimeFormat('zh - Hans', { dateStyle: 'long', timeStyle: 'medium' });
    let formatTime = dateFormat.format(new Date())
    HiLog.i(TAG, 'confirm time :' + formatTime);
    PreferencesService.getInstance().putPropValue(PersistType.FOREVER, PropTag.INTRO_AGREE_TIME, formatTime);
    try {
      let bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      PreferencesService.getInstance()
        .putPropValue(PersistType.FOREVER, PropTag.APPLICATION_VERSION, bundleInfo?.versionName);
    } catch (err) {
      HiLog.e(TAG, `getBundleInfo fail. ${err?.code}`);
    }
    PreferencesService.getInstance()
      .putPropValue(PersistType.FOREVER, PropTag.PRIVACY_VERSION, "1.0.3");
    // AppStorage.setOrCreate('isIntroLoaded', true);
    // PC和LEM还未上引导页，需要在权限页确认触发位置弹窗
    if (!DeviceInfo.isTablet()) {
      execDispatch(Action.isRequestPermission(true));
    }
    //引导页是深色模式 paf会把整个应用设置为深色模式 点击确认之后重新设置 深浅色 避免影响其它控件
    if (!DeviceInfo.isPc()) {
      WindowService.getInstance().setFullScreen();
    }
    let applicationContext = ContextManager.getInstance().getApplicationContext();
    applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    if (DeviceInfo.isPc()) {
      const pcCamState = getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState');
      if (pcCamState === CameraRunningState.UNINITIALIZED) {
        execDispatch(CameraAction.init(camera.CameraPosition.CAMERA_POSITION_FRONT, ModeType.PHOTO, false));
      } else {
        HiLog.i(TAG, 'skipIntro: MainAbility already dispatched CameraAction.init, skip duplicate (PC).');
      }
      return;
    }
    let newMode = PreferencesService.getInstance()
      .getPropValue(PersistType.FOR_AWHILE, PropTag.MODE, ModeType.PHOTO) as ModeType;
    const cameraPos: camera.CameraPosition =
      PreferencesService.getInstance().getPropValue(PersistType.FOR_AWHILE, PropTag.CAMERA_POSITION,
        camera.CameraPosition.CAMERA_POSITION_BACK) as camera.CameraPosition;
    HiLog.i(TAG, `intro start camera. newMode: ${newMode}, cameraPos: ${cameraPos}`);
    const phoneCamState = getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState');
    if (phoneCamState === CameraRunningState.UNINITIALIZED) {
      execDispatch(CameraAction.init(cameraPos, newMode, true));
    } else {
      HiLog.i(TAG, 'skipIntro: MainAbility already dispatched CameraAction.init, skip duplicate (phone).');
    }
    execDispatch(Action.introConfirm());
    HiLog.i(TAG, 'intro confirm end');
  }

  private skipGuidancePages(): void {
    PreferencesService.getInstance().putPublicValue(PersistType.FOREVER, PublicTag.IS_GUIDANCE_LOADED, true);
    AppStorage.setOrCreate('isGuidanceLoaded', true);
    WindowService.getInstance().setSpecificSystemNavigationEnabled(true, false, false);
    const cameraErrorCode: CameraErrorCode = getStates().get<CameraErrorCode>('cameraReducer', 'cameraErrorCode');
    if (cameraErrorCode === CameraErrorCode.DEVICE_PREEMPTED) {
      StoreManager.getInstance().postMessage(CameraAction.warmStart());
    }
  }

  private initializeTBTipWithoutFirstEnter(): void {
    const lastShowTreasureBoxTime: number = PreferencesService.getInstance()
      .getPropValue(PersistType.FOREVER, PropTag.LAST_SHOW_TREASURE_BOX_TIP_TIMESTAMP,
        DEFAULT_SHOW_TREASURE_BOX_TIP_TIMESTAMP) as number;
    this.mShowTBTipCnt = PreferencesService.getInstance()
      .getPropValue(PersistType.FOREVER, PropTag.SHOW_TREASURE_BOX_TIP_COUNT, 0) as number;
    if (this.mShowTBTipCnt === SHOW_TREASURE_BOX_TIP_MAX_CNT) {
      HiLog.i(TAG, 'tip cnt 3, no show, E.');
      this.isNeedShowTBTip = false;
      return;
    }
    if (lastShowTreasureBoxTime === NO_NEED_SHOW_TREASURE_BOX_TIP_TIMESTAMP) {
      HiLog.i(TAG, 'already enter TB setting, X.');
      this.isNeedShowTBTip = false;
      return;
    }
    if (lastShowTreasureBoxTime === DEFAULT_SHOW_TREASURE_BOX_TIP_TIMESTAMP) {
      HiLog.i(TAG, 'SP no TB value, X.');
      this.isNeedShowTBTip = false;
      return;
    }

    // 3天 & 7天弹toast
    const timeGap: number = Date.now() - lastShowTreasureBoxTime;
    this.isNeedShowTBTip = this.mShowTBTipCnt === 1 ? timeGap >= ONE_DAY * 3 : timeGap >= ONE_DAY * 4;
  }

  private processVdeCollapsMode(vdeCollapsedData: VdeCollapsedData): void {
    HiLog.i(TAG, 'processVdeCollapsModeData E.' + vdeCollapsedData?.isVdeCollapsed);
    MoreModeConfig.getInstance().processVdeCollapsedModeData(vdeCollapsedData?.isVdeCollapsed);
    HiLog.i(TAG, 'processVdeCollapsModeData X.');
  }

  private popPage(): void {
    HiLog.i(TAG, 'popPage E.');
    this.pageInfos?.pop();
    HiLog.i(TAG, 'popPage X.');
  }

  private clearPage(): void {
    HiLog.i(TAG, 'clearPage begin.');
    const names = this.pageInfos?.getAllPathName();
    if (!this.pageInfos || !names || !names.length) {
      HiLog.i(TAG, 'clearPage end, pageInfos is empty.');
      return;
    }
    HiLog.i(TAG, `clearPages: ${simpleStringify(names)}.`);
    this.pageInfos.clear(false);
    this.translateContent = 0;
    HiLog.i(TAG, 'clearPage end.');
  }

  private isExistOnceToast(): boolean {
    const isExistProToast: boolean = false &&
      PreferencesService.getInstance().getPropValue(PersistType.FOREVER,
        PropTag.PRO_EXPOSURE_FIRST_TOAST, FunctionFirstToast.NONE_TOAST) as FunctionFirstToast !==
      FunctionFirstToast.HIDE_TOAST;
    return isExistProToast;
  }

  private checkRequestLocationDialogClose(): void {
    // if (this.isIntroLoaded && this.isGuidanceLoaded) {
    this.requestLocationDialogController?.close();
    PreferencesService.getInstance()
      .putPublicValue(PersistType.FOREVER, PublicTag.IS_REQUEST_LOCATION_DIALOG_LOADED, true);
    AppStorage.setOrCreate('isRequestLocationLoaded', true);
    // 开启相机在相机未弹出过位置卡片时初始化位置开关状态，供图库获取使用
    const settingSwitchValue = SettingsValueUtil.getValueSync('camera_location_switch', 'undefined');
    HiLog.i(TAG, 'settingSwitchValue is:' + settingSwitchValue);
    if (settingSwitchValue === 'undefined') {
      SettingsValueUtil.setValueSync('camera_location_switch', '0');
    }
    clearTimeout(this.mTimer);
    // }
  }

  private isGuidanceLoadedChange(): void {
    HiLog.i(TAG, 'isGuidanceLoadedChange E.');
    let isLocked = screenLock.isLocked();
    if (!this.isLemCollaps && !isLocked) {
      this.checkRequestLocationDialog();
      this.mTimer = setTimeout(() => {
        this.checkRequestLocationDialogClose();
        this.mTimer = Number.NaN;
      }, DELAY_HIDDEN_TIME);
    }
  }

  private isShowTBTip(): void {
    HiLog.i(TAG, 'isShowTBTip E.');
    // if (!this.isLemCollaps && this.isNeedShowTBTip && this.isIntroLoaded) {
    //   setTimeout(() => {
    //     this.checkTreasureBoxTip();
    //   }, 3000);
    // }
  }

  private checkTreasureBoxTip(): void {
    HiLog.i(TAG, 'checkTreasureBoxTip');
    if (getStates().get<boolean>('collapsReducer', 'isShowLandscape')) {
      HiLog.i(TAG, 'isShowLandscape is true');
      return;
    }
    let securityTipTextResource: ResourceStr = $r('app.string.set_entrance_tweak_box');
    TipService.getInstance().showTip(securityTipTextResource, 3000, true, null, undefined, true);
    PreferencesService.getInstance()
      .putPropValue(PersistType.FOREVER, PropTag.LAST_SHOW_TREASURE_BOX_TIP_TIMESTAMP, Date.now());
    PreferencesService.getInstance()
      .putPropValue(PersistType.FOREVER, PropTag.SHOW_TREASURE_BOX_TIP_COUNT, this.mShowTBTipCnt + 1);
  }

  private checkRequestLocationDialog(): void {
    // this.isIntroLoaded = PreferencesService.getInstance()
    //   .getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean;
    this.isRequestLocation = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_REQUEST_LOCATION_DIALOG_LOADED, false) as boolean;
    HiLog.i(TAG, 'checkRequestLocationDialog isRequestLocation: ' + this.isRequestLocation);
    // HiLog.i(TAG, 'checkRequestLocationDialog isIntroLoaded: ' + this.isIntroLoaded);
    if (!this.isRequestLocation && !AppStorage.get<boolean>('checkAccessTokenIsSuccess')) {
      let currentLocationSwitch: boolean =
        FeatureManager.getInstance().getFunction(FunctionId.SAVE_GEO_LOCATION)?.getValue() ?? false;
      if (currentLocationSwitch) {
        HiLog.i(TAG, 'current location switch is true, no need to show locationDiaLog');
        PreferencesService.getInstance()
          .putPublicValue(PersistType.FOREVER, PublicTag.IS_REQUEST_LOCATION_DIALOG_LOADED, true);
        return;
      }
      this.requestLocationDialogController = new CustomDialogController({
        builder: RequestLocationDialog({ checkTreasureBoxTip: this.checkTreasureBoxTipFunc }),
        autoCancel: false,
        alignment: DialogAlignment.Top,
        maskColor: Color.Transparent,
        customStyle: true,
        offset: { dx: 0, dy: 120 },
        isModal: false,
        onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
          HiLog.i(TAG, `onWillDismiss: ${JSON.stringify(dismissDialogAction)}`);
          if (dismissDialogAction.reason === DismissReason.PRESS_BACK) {
            this.checkRequestLocationDialogClose();
          }
        }
      });
      this.requestLocationDialogController?.open();
    }
  }

  private isShowCommonCaptureDialog(data: DialogParams): void {
    HiLog.i(TAG, `CommonCaptureDialog show: ${data.show}, isCustomStyle: ${data.isCustomStyle}`);
    if (!data.show || this.isRemoteCaptureDialogOpened) {
      if (!data.show && this.isRemoteCaptureDialogOpened) { // 关闭权限弹窗
        this.confirmRemoteCaptureDialogController?.close();
        HiLog.i(TAG, 'RemoteCaptureDialog close');
        this.isRemoteCaptureDialogOpened = false;
      }
      return;
    }
    this.createCommonCaptureDialog(data, async (result) => {
      if (result.isGranted) {
        if (!this.isRemoteCapture) {
          CollaborateControlService.getInstance().handlePermissionGrantResult(true, result.isOnce);
        } else {
          RemoteCaptureService.getInstance().startCamera();
          if (!result.isOnce) {
            RemoteCaptureService.getInstance().setPermission();
          }
        }
      } else {
        if (!this.isRemoteCapture) {
          CollaborateControlService.getInstance().handlePermissionGrantResult(false);
        } else {
          RemoteCaptureService.getInstance().forbiddenCamera();
          ContextManager.getInstance().getUiContext().terminateSelf().then(async () => {
            HiLog.i(TAG, 'terminateSelf success by Remote capture ');
          });
        }
      }
      this.isRemoteCaptureDialogOpened = false;
    });
    this.confirmRemoteCaptureDialogController?.open();
    this.isRemoteCaptureDialogOpened = true;
    HiLog.i(TAG, 'RemoteCaptureDialog open');
  }

  private createCommonCaptureDialog(data: DialogParams, dialogCallback: (result: DialogResult) => void): void {
    HiLog.i(TAG, 'createCommonCaptureDialog E.');
    this.confirmRemoteCaptureDialogController = new CustomDialogController({
      builder: RemoteCaptureDialog({
        confirm: async (isOnce: boolean) => {
          HiLog.i(TAG, `CustomDialogController confirm isOnce = ${isOnce}`);
          dialogCallback({ isGranted: true, isOnce: isOnce });
        },
        cancel: () => {
          HiLog.i(TAG, 'CustomDialogController cancel');
          dialogCallback({ isGranted: false });
        },
        deviceName: data?.deviceName
      }),
      autoCancel: false,
      customStyle: data?.isCustomStyle,
      maskColor: $r('sys.color.mask_fourth'),
      alignment: DialogAlignment.Center,
      onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
        if (dismissDialogAction.reason === DismissReason.PRESS_BACK) {
          HiLog.i(TAG, 'CustomDialogController Back Press');
        }
      }
    });
  }

  private onCollaborateControlSourceConnect(): void {
    const securityTipTextResource: ResourceStr = $r('app.string.watch_connect_tip');
    TipService.getInstance().showTip(securityTipTextResource, 3000);
  }

  private onCollaborateControlSourceDisconnect(): void {
    const securityTipTextResource: ResourceStr = $r('app.string.watch_disconnect_tip');
    TipService.getInstance().showTip(securityTipTextResource, 3000);
  }

  private showSnapshotTip(): void {
    const snapshotTipTextResource: ResourceStr = $r('app.string.toast_rapid_prompt_close');
    TipService.getInstance().showTip(snapshotTipTextResource, 3000, true);
  }

  private showMirrorSelfieSetting(data: MirrorSelfieSettingStruct): void {
    HiLog.i(TAG, `isShowMirrorSelfieSetting : ${data.isShowMirrorSelfieSetting}`);
    this.isShowMirrorSelfieSetting = data.isShowMirrorSelfieSetting;
    if (data && data.isShowMirrorSelfieSetting) {
      HiLog.i(TAG, 'pageInfos change, push MirrorSelfieSettingView');
      this.pageInfos.pushPath({ name: 'MirrorSelfieSettingView' }, true);
    }
  }

  private updateHDRBrightnessSupport(data: ActionData) {
    this.isApplyHdr = data['isOpen'] as boolean;
  }

  private isOpenHDRBright() {
    this.isVideoOutput = OutputOperation.isPanVideoOutput(this.mode);
    this.isHdr = false && this.isVideoOutput;
    if (!this.isVideoOutput) {
      this.isOpenHdrBrightness = this.isApplyHdr;
      return this.isApplyHdr;
    } else {
      this.isOpenHdrBrightness = this.isHdr;
      return this.isHdr;
    }
  }

  private getPictureInPictureFatherWidth(): number {
    if (this.isLemCollaps || this.isPSDCollapsed) {
      return this.windowWidth;
    }
    return this.xComponentWidth;
  }

  private getPictureInPictureFatherHeight(): number {
    if (this.isLemCollaps || this.isPSDCollapsed) {
      return this.windowHeight;
    }
    return this.xComponentHeight;
  }

  private getPictureInPictureFatherPosition(): PositionType {
    if (this.isLemCollaps || this.isPSDCollapsed) {
      return { x: 0, y: 0 };
    }
    return this.previewAnimatePosition;
  }

  build() {
    Stack() {
      Navigation(this.pageInfos) {
        Stack({ alignContent: Alignment.Top }) {
          PreviewWrap({
            isHdr: this.isOpenHDRBright()
          })

          if (this.state.isShowTimedShot) {
            TimedShotView()
          }

          if (this.state.isShowDefault) {
            DefaultIndex({
              immersiveUIType: this.immersiveUIType,
              immersiveOpacity: this.immersiveOpacity,
              isShowSettingView: this.isShowSettingView,
              isHdr: this.isOpenHDRBright()
            })
              .visibility(this.isShowViewVisibility && !this.state.isShowTimedShot ? Visibility.Visible :
                Visibility.Hidden)
          }

          if (this.state.isShowDefault && this.isVdeCollapsed && this.state.isVdeCollapsedOnForeground) {
          }

          if (this.isStarted) {
            this.PhotoBrowserMap();
          }

          if (this.state.thumbnailReminderShow) {
            ThumbnailReminder()
              .width('100%')
              .height('100%')
              .backgroundColor(Color.Black)
          }

          if (this.state.appLockReminderShow) {
            AppLockThumbnailReminder()
              .width('100%')
              .height('100%')
              .backgroundColor(Color.Black)
          }

          if (this.showUltraSnapshot) {
            Stack() {
            }
            .width('100%')
            .height('100%')
            .zIndex(ZIndex.SKETCH_INDEX)
          }
          GeoLocationSetting();
        }
        .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
        .key('Navigation_content_stack')
        .width('100%')
        .height('100%')
        .offset({
          x: this.isShowSemiCollapsed ? 0 : ((this.isVertical() || this.state.isLockRotation) ? this.translateContent : 0),
          y: this.isShowSemiCollapsed ? this.translateContent : ((this.isVertical() ||
          this.state.isLockRotation) ? 0 : this.translateContent)
        })
      }
      .width('100%')
      .height('100%')
      .hideTitleBar(true)
      .key(ComponentIdKeys.PAGE_ROOT_NAV)
      .navDestination(this.PageMap)
      .mode(NavigationMode.Stack)
      .backgroundColor(this.isShowRingLightView && this.isHalfCollapsLEM ? Color.White : Color.Black)
      .onTouch(() => {
        let isLoaded = PreferencesService.getInstance()
          .getPropValue(PersistType.FOREVER, PropTag.IS_FRONT_CAMERA_TIPS_LOADED, FRONT_TIP_UNLOADED) as number;
        if (this.isExistOnceToast()) {
          this.mAction.handleOnceToast(); // 各种首次提示弹窗触发关闭上层事件节点
        }
      })
      .customNavContentTransition((from: NavContentInfo, to: NavContentInfo, operation: NavigationOperation) => {
        if (from.mode === NavDestinationMode.DIALOG || to.mode === NavDestinationMode.DIALOG) {
          return undefined;
        }
        HiLog.i(TAG, `to info: ${JSON.stringify(to)}`);
        HiLog.i(TAG, `from info: ${JSON.stringify(from)}`);
        HiLog.i(TAG, `operation: ${operation}`);
        // 隐私页不能旋转，不做自定义动效
        if (to.name === 'PrivacyPolicyView' || from.name === 'PrivacyPolicyView' ||
          to.name === 'MirrorSelfieSettingView' || from.name === 'MirrorSelfieSettingView' ||
          to.name === 'SettingView' || from.name === 'SettingView' || to.name === 'ModeDetailView' ||
          from.name === 'ModeDetailView' || from.name === 'WatermarkSettingView' ||
          to.name === 'WatermarkSettingView') {
          return undefined;
        }
        let customAnimation: NavigationAnimatedTransition = {
          onTransitionEnd: (isSuccess: boolean) => {
            this.mAction.uiEnabled(true);
            HiLog.i(TAG, `current transition result is ${isSuccess}`);
          },
          // 转场开始时系统调用该方法，并传入转场上下文代理对象
          transition: (transitionProxy: NavigationTransitionProxy) => {
            HiLog.i(TAG, 'trigger transition callback');
            let fromAnimation: TitleAnimation | undefined = CustomTransition.getInstance().getAnimateParam(from.index);
            let toAnimation: TitleAnimation | undefined = CustomTransition.getInstance().getAnimateParam(to.index);
            let isPop: boolean = NavigationOperation.POP === operation;
            // title offset animation
            if (fromAnimation?.transitionAnimation?.start) {
              fromAnimation?.transitionAnimation?.start(isPop, true);
            }
            if (toAnimation?.transitionAnimation?.start) {
              toAnimation.transitionAnimation.start(isPop, false);
            }
            animateTo({
              duration: 450, curve: curves.interpolatingSpring(0.0, 1.0, 342.0, 37.0), onFinish: () => {
                if (fromAnimation?.transitionAnimation?.onFinish) {
                  fromAnimation.transitionAnimation.onFinish(isPop, true);
                }
                if (toAnimation?.transitionAnimation?.onFinish) {
                  toAnimation.transitionAnimation.onFinish(isPop, false);
                }
              }
            }, () => {
              if (from.index === -1) {
                this.translateContent = (this.state.isLockRotation || this.isVertical()) ? OFFSET_LEFT_20 :
                  this.mDirection === WindowDirection.LEFT ? OFFSET_RIGHT_20 : OFFSET_LEFT_20;
                this.translateBlackPage = (this.state.isLockRotation || this.isVertical()) ? OFFSET_RIGHT_20 :
                  this.mDirection === WindowDirection.LEFT ? OFFSET_LEFT_20 : OFFSET_RIGHT_20;
              }
              if (to.index === -1) {
                this.translateContent = 0;
                this.translateBlackPage = (this.state.isLockRotation || this.isVertical()) ? OFFSET_RIGHT_100 :
                  this.mDirection === WindowDirection.LEFT ? OFFSET_LEFT_100 : OFFSET_RIGHT_100;
              }
              if (fromAnimation?.transitionAnimation?.finish) {
                fromAnimation.transitionAnimation.finish(isPop, true);
              }
              if (toAnimation?.transitionAnimation?.finish) {
                toAnimation.transitionAnimation.finish(isPop, false);
              }
            })
            // title in animation
            if (toAnimation?.titleAnimation?.start) {
              toAnimation.titleAnimation.start(isPop, false);
            }
            animateTo({
              duration: 150,
              delay: 33,
              curve: Curve.Sharp,
              onFinish: () => {
                if (toAnimation?.titleAnimation?.onFinish) {
                  toAnimation.titleAnimation.onFinish(isPop, false);
                }
              }
            }, () => {
              if (toAnimation?.titleAnimation?.finish) {
                toAnimation.titleAnimation.finish(isPop, false);
              }
            })
            // title out animation
            animateTo({
              duration: 150,
              delay: 17,
              curve: Curve.Sharp,
              onFinish: () => {
                if (fromAnimation?.titleAnimation?.onFinish) {
                  fromAnimation.titleAnimation.onFinish(isPop, true);
                }
              }
            }, () => {
              if (fromAnimation?.titleAnimation?.finish) {
                fromAnimation.titleAnimation.finish(isPop, true);
              }
            })
            // back button in animation
            if (fromAnimation?.opacityAnimation.start) {
              fromAnimation.opacityAnimation.start(isPop, true);
            }
            if (toAnimation?.opacityAnimation.start) {
              toAnimation.opacityAnimation.start(isPop, false);
            }
            // back in animation
            animateTo({
              duration: 200,
              delay: 150,
              curve: Curve.Sharp,
              onFinish: () => {
                if (toAnimation?.opacityAnimation.onFinish) {
                  toAnimation?.opacityAnimation.onFinish(isPop, false);
                }
              }
            }, () => {
              if (toAnimation?.opacityAnimation.finish) {
                toAnimation?.opacityAnimation.finish(isPop, false);
              }
            })
            animateTo({
              duration: 67, curve: Curve.Sharp, onFinish: () => {
                if (fromAnimation?.opacityAnimation.onFinish) {
                  fromAnimation.opacityAnimation.onFinish(isPop, true);
                }
              }
            }, () => {
              if (fromAnimation?.opacityAnimation.finish) {
                fromAnimation.opacityAnimation.finish(isPop, true);
              }
            })
          }
        };
        return customAnimation;
      })
    }
  }

  @Builder
  blackPageBuilder(): void {
    Column() { // 黑色背景 防止设置页旋转的时候漏相机首页
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .offset({
      x: this.isShowSemiCollapsed ? 0 : ((this.isVertical() || this.state.isLockRotation) ? this.translateBlackPage : 0),
      y: this.isShowSemiCollapsed ? this.translateBlackPage : ((this.isVertical() ||
      this.state.isLockRotation) ? 0 : this.translateBlackPage)
    })
  }

  private dialogStatusOnChange(): void {
    CollaborateControlService.getInstance().updateDialogOpenStatus(this.isAnyDialogOpening);
  }

  private onPreviewFrameStart(data: PreviewFrameStartData): void {
    if (data.isPreviewFrameStart) {
      if (!this.showCustomFilterTaskPool && (DatabaseUtils.store === null || DatabaseUtils.store === undefined)) {
        this.showCustomFilterTaskPool = true;
      }
    }
  }
}