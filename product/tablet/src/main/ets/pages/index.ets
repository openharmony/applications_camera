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

import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { RecordMode } from '@ohos/common/src/main/ets/function/recordcontrol/RecordMode';
import { RecordAction, RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { Action, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import { BusinessError } from '@ohos.base';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { CameraProxy } from '@ohos/common/src/main/ets/camera/uithread/CameraProxy';
import { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import {
  ImmersiveActionData,
  SavePowerModeActionData,
  WindowEventData
} from '@ohos/common/src/main/ets/utils/types';
import { FunctionFirstToast, PropTag, PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy {
  RequestLocationDialog
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/RequestLocationDialog';
import { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import camera from '@ohos.multimedia.camera';
import { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import { CameraStartType, CameraStartTypeStruct } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import { ChangeState, getStates, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
// import { PafUiWidget } from '@ohos-paf/ui-widget-base';
import { SettingView } from './SettingView';
import { SettingViewData } from '@ohos/common/src/main/ets/function/setting/SettingFunction';
import { VolumeShutterService } from '@ohos/common/src/main/ets/service/volume/VolumeShutterService';
import { SelfieStickService } from '@ohos/common/src/main/ets/service/selfieStick/SelfieStickService';
import { window } from '@kit.ArkUI';
import { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import { CaptureAction } from '@ohos/common/src/main/ets/function/capture/CaptureAction';
import { ModeDetailView } from './ModeDetailView';
import { ThumbnailReminder } from './ThumbnailReminder';
import { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import { MoreModeConfig } from '@ohos/common/src/main/ets/mode/MoreModeConfig';
import { ModeListManager } from '@ohos/common/src/main/ets/mode/ModeListManager';
import screenLock from '@ohos.screenLock';
import { AppLockThumbnailReminder } from './AppLockThumbnailReminder';
import { reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import { ThumbnailActionType } from '@ohos/common/src/main/ets/redux/actions/ThumbnailActionType';
import { SettingViewActionType } from '@ohos/common/src/main/ets/redux/actions/SettingViewActionType';
import { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import { LeftRightSwipeActionType } from '@ohos/common/src/main/ets/redux/actions/LeftRightSwipeActionType';
import { RecordActionType } from '@ohos/common/src/main/ets/redux/actions/RecordActionType';
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import { MediaLibraryUiService } from '@ohos/common/src/main/ets/utils/LazyImportUtil';
import { LandscapeIndex } from '../../../../../phone/src/main/ets/pages/landscape/LandscapeIndex'
import { PreviewWrap } from '../../../../../phone/src/main/ets/pages/preview/PreviewWrap';
import { SettingsValueUtil } from '@ohos/common/src/main/ets/utils/SettingsValueUtil';

const TAG: string = 'Index';
const TEN: number = 10;
const DELAY_HIDDEN_TIME: number = 10000;

class StateStruct {
  public isShowPageView: boolean = false;
  public isShowtimeLapse: boolean = false;
  public isThirdPartyCall: boolean = false;
  public isOpenTreasureBox: boolean = false;
  public isShowDefault: boolean = true;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public photoBrowserStatus: Boolean = false;
  public thumbnailReminderShow: boolean = false;
  public isDuringSavePowerMode: boolean = false;
  public appLockReminderShow: boolean = false;
}

class IndexDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeTimeLapse(isShowtimeLapse: boolean, timeLapseInterrupt?: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse, timeLapseInterrupt));
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

  public enableUiWithMode(uiStateMode: UiStateMode, excludeComponent: string): void {
    this.mDispatch(Action.uiStateWithMode(true, uiStateMode, excludeComponent));
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.ZOOM_BAR));
  }

  public showThumbnailReminder(isShow: boolean): void {
    this.mDispatch(Action.showThumbnailReminder(isShow));
  }

  public onBackPress(): void {
    this.mDispatch(Action.onBackPress());
  }

  public updateModePosition(withAnimate: boolean = false): void {
    this.mDispatch(Action.updateModePosition(withAnimate));
  }

  public handleOnceToast(): void {
    this.mDispatch(Action.handleOnceToast());
  }

  public showAppLockReminder(isShow: boolean): void {
    this.mDispatch(Action.showAppLockReminder(isShow));
  }

  public endPanorama(): void {
    this.mDispatch(Action.onBackPressPanoramaStop());
  }
}

class EnterImmersiveData {
  public isImmersive?: boolean = false;
  public mainTrigCompo?: UIOperationType = UIOperationType.NULL;
}

class SwipeRecordLockData {
  public isLocked?: boolean = false;
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

  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @BuilderParam photoBrowserLoader: () => void = this.PhotoBrowserMapTemp;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State state: StateStruct = new StateStruct();
  private mAction: IndexDispatcher = new IndexDispatcher();
  private mGlobalContext: GlobalContext = GlobalContext.get();
  private moreModeConfig: MoreModeConfig = MoreModeConfig.getInstance();
  // 录像控制
  @State videoState: RecordingState = RecordingState.READY;
  // 百宝箱
  @StorageLink('treasureBoxSelector') treasureBoxSelector: FunctionId = FunctionId.NONE;
  // 大图组件
  @StorageLink('isShowPhotoBrowser') isShowPhotoBrowser: boolean = false;
  @State isStarted: boolean = false;
  @State isShowViewVisibility: boolean = true;
  // 夜景曝光控制
  @State isShowNightExposure: boolean = false;
  @StorageLink('isNightShutting') isNightShutting: boolean = false;
  // 沉浸式
  @State immersiveUIType: UIOperationType = UIOperationType.NULL;
  @State immersiveOpacity: number = 1;
  @State isShowMorePage: boolean = false;
  @State isEditMorePage: boolean = false;
  //预授权启动页是否显示过
  @StorageLink('isIntroLoaded') isIntroLoaded: boolean = false;
  //页面超时
  private mPageShowTimeout: number = 20;
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  //帧率控制
  frameRateSaving: boolean = false;
  INDEX_SEC: number = 2;
  FRAME_RATE_60FPS: number = 60;
  private volumeService: VolumeShutterService = VolumeShutterService.getInstance();
  private selfieStickService: SelfieStickService = SelfieStickService.getInstance();
  @State isShowLandscape: boolean = false;
  @State mode: ModeType = ModeType.NONE;
  @StorageLink('isGuidanceLoaded') @Watch('isIntroLoadedChange') isGuidanceLoaded: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  private isInImmersive: boolean | undefined = false;
  private isRequestLocation: boolean = false;
  private requestLocationDialogController: CustomDialogController | null = null;
  private mTimer: number = Number.MIN_VALUE;
  @StorageLink('showPhotoBrowserAction') @Watch('showPhotoBrowserOnChange') showPhotoBrowserAction: boolean = false;

  @Builder
  PageMap(navigationName: string) {
    if (navigationName === 'SettingView') {
      SettingView({ pageId: Date.now() });
    } else if (navigationName === 'ModeDetailView') {
      ModeDetailView();
    }
  }

  aboutToAppear(): void {
    HiLog.begin(TAG, 'aboutToAppear');
    // Paf UiWidget 初始化
    // PafUiWidget.init(GlobalContext.get().getWindowStage(), ContextManager.getInstance().getAbilityContext());
    this.setEventBusOn();

    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      changeState(this.state, {
        isShowPageView: state.get<boolean>('settingViewReducer', 'isShowSettingView'),
        isShowtimeLapse: state.get<boolean>('settingReducer', 'isShowtimeLapse'), // 是否显示定时拍照倒计时
        isThirdPartyCall: state.get<boolean>('contextReducer', 'isThirdPartyCall'),
        isOpenTreasureBox: state.get<boolean>('treasureBoxReducer', 'isOpen'),
        isShowDefault: state.get<boolean>('collapsReducer', 'isShowDefault'),
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        photoBrowserStatus: state.get<boolean>('thumbnailReducer', 'photoBrowserStatus'),
        thumbnailReminderShow: state.get<boolean>('securityCameraReducer', 'thumbnailReminderShow'),
        appLockReminderShow: state.get<boolean>('securityCameraReducer', 'appLockReminderShow'),
        isDuringSavePowerMode: state.get<boolean>('contextReducer', 'isDuringSavePowerMode'),
      });
      this.isShowViewVisibility = state.get<boolean>('contextReducer', 'isViewVisibility');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.isEditMorePage = state.get<boolean>('modeReducer', 'isEditMorePage');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });

    // this.checkPermissions(); // 首帧加载权限验证耗时，暂时关闭
    this.isIntroLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean;
    this.initializeGuidancePages();
    HiLog.end(TAG, 'aboutToAppear');
  }

  private setEventBusOn(): void {
    this.mEventBus.on(CameraActionType.STARTED, this.indexOnStarted.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_NIGHT_FRAME_SHUTTER, this.onNightFrameShutter.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_RESET_EXPOSURE_TIME, this.onResetExposureTime.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_CHANGE_TIME_LAPSE, ActionType.ACTION_IS_ENTER_IMMERSIVE],
      this.isEnterImmersive.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.PHOTOBROWSER_STATUS, this.onPhotoBrowserStatus.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.CHANGE_WINDOW_EVENT_TYPE, this.onWindowEventType.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(SettingViewActionType.ACTION_SHOW_SETTING_VIEW,
      this.onSettingViewShow.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_IS_ENTER_IMMERSIVE, this.lockScreenRotation.bind(this), this.mBase.hashCode());
    this.mEventBus.on(LeftRightSwipeActionType.RECORD_LOCK_STATUS_CHANGE, this.rotationUnLockedBySwipeRecord.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.UPDATE_SAVE_POWER_MODE_STATE, (data: SavePowerModeActionData) =>
    this.updateSavePowerModeState(data), this.mBase.hashCode());
    this.mEventBus.on([RecordActionType.START, ActionType.ACTION_CAPTURE_EFFECT],
      () => this.checkRequestLocationDialogClose(), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, () => this.onBackground(), this.mBase.hashCode());
  }

  aboutToDisappear(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  private onBackground(): void {
    this.stopCameraRecording();
    this.checkRequestLocationDialogClose();
  }

  private onNightFrameShutter(): void {
    this.updateShowNightExposure(true);
  }

  private onResetExposureTime(): void {
    this.updateShowNightExposure(false)
  }

  private updateSavePowerModeState(data: SavePowerModeActionData) {
    HiLog.i(TAG, `Save power mode state: ${data.isDuringSavePowerMode}`);
    if (data.isDuringSavePowerMode) {
      this.checkRequestLocationDialogClose();
    }
  }

  private isIntroLoadedChange(): void {
    HiLog.i(TAG, 'isGuidanceLoadedChange E.');
    let isLocked = screenLock.isLocked();
    if (!isLocked) {
      this.checkRequestLocationDialog();
      this.mTimer = setTimeout(() => {
        this.checkRequestLocationDialogClose();
        this.mTimer = Number.NaN;
      }, DELAY_HIDDEN_TIME);
    }
  }

  private checkRequestLocationDialog(): void {
    this.isIntroLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean;
    this.isRequestLocation = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_REQUEST_LOCATION_DIALOG_LOADED, false) as boolean;
    HiLog.i(TAG, 'checkRequestLocationDialog isRequestLocation: ' + this.isRequestLocation);
    HiLog.i(TAG, 'checkRequestLocationDialog isIntroLoaded: ' + this.isIntroLoaded);
    if (this.isIntroLoaded && !this.isRequestLocation && !AppStorage.get<boolean>('checkAccessTokenIsSuccess')) {
      let currentLocationSwitch: boolean =
        FeatureManager.getInstance().getFunction(FunctionId.SAVE_GEO_LOCATION)?.getValue() ?? false;
      if (currentLocationSwitch) {
        HiLog.i(TAG, 'current location switch is true, no need to show locationDiaLog');
        PreferencesService.getInstance()
          .putPublicValue(PersistType.FOREVER, PublicTag.IS_REQUEST_LOCATION_DIALOG_LOADED, true);
        return;
      }
      this.requestLocationDialogController = new CustomDialogController({
        builder: RequestLocationDialog(),
        autoCancel: false,
        alignment: DialogAlignment.Top,
        maskColor: Color.Transparent,
        customStyle: true,
        offset: { dx: 0, dy: 120 },
        isModal: false,
        onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
          HiLog.i(TAG, `onWillDismiss: ${dismissDialogAction?.reason}`);
          if (dismissDialogAction?.reason === DismissReason.PRESS_BACK) {
            this.checkRequestLocationDialogClose();
          }
        }
      });
      this.requestLocationDialogController?.open();
    }
  }

  private checkRequestLocationDialogClose(): void {
    if (this.isIntroLoaded && this.isGuidanceLoaded) {
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
    }
  }

  private showPhotoBrowserOnChange(): void {
    if (!this.showPhotoBrowserAction) {
      return;
    }
    HiLog.i(TAG, `show photo browser: ${this.showPhotoBrowserAction}.`);
    this.checkRequestLocationDialogClose();
  }

  onBackPress(): boolean {
    HiLog.i(TAG, 'onBackPress E.');
    this.mAction.onBackPress();
    if (this.state.isDuringSavePowerMode) {
      return true;
    }
    if (this.isEditMorePage || this.isShowMorePage) {
      HiLog.i(TAG, 'showMore.-' + this.isShowMorePage + ',isEditMorePage.-' + this.isEditMorePage);
      this.backPressOnShowMore();
      return true;
    }
    if (this.isShowPhotoBrowser) {
      HiLog.i(TAG, 'browserController onBackPress');
      this.mAction.photoBrowserOnBackPress();
      return true;
    }
    if (this.state.thumbnailReminderShow) {
      this.mAction.showThumbnailReminder(false);
      return true;
    }
    if (this.state.appLockReminderShow) {
      HiLog.i(TAG, 'appLockReminderShow.-' + this.state.appLockReminderShow);
      this.mAction.showAppLockReminder(false);
      return true;
    }
    if (this.state.isShowPageView) {
      this.mAction.changeFunctionValue(FunctionId.SETTING, false);
      return true;
    }
    if (this.state.isShowtimeLapse) {
      this.mAction.changeTimeLapse(false, true);
      return true;
    }
    if (this.state.isThirdPartyCall) {
      PickerUiService.getInstance().terminateSelfWithResult();
      return true;
    }
    if (this.videoState === RecordingState.RECORDING || this.videoState === RecordingState.PAUSED ||
      this.videoState === RecordingState.RESUMING) {
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
      return true;
    }
    if (this.isShowNightExposure) {
      this.mAction.confirmCapture();
      return true;
    }
    if (!this.isShowLandscape && this.treasureBoxSelector !== FunctionId.NONE) {
      this.mAction.changeTreasureBoxSelectorNone();
      return true;
    }
    if (!this.isShowLandscape && this.state.isOpenTreasureBox) {
      this.mAction.closeTreasureBox();
      return true;
    }
    HiLog.i(TAG, 'onBackPress X.');
    return false;
  }

  private backPressOnShowMore(): void {
    HiLog.i(TAG, 'backPressOnShowMore tablet.');
    if (!this.isEditMorePage) {
      this.moreModeConfig.entryAOutMorePage(false);
      this.mAction.updateModePosition(true);
    }
    this.moreModeConfig.editMorePage(false);
  }

  onPageShow(): void {
    HiLog.i(TAG, 'onPageShow.');
    setTimeout((): void => {
    }, this.mPageShowTimeout);
    this.volumeService.volumeKeySubscribe();
    this.selfieStickService.selfieStickSubscribe();
    this.mAction.updateModePosition();
    MediaLibraryUiService.getInstance().onPageChange(true);
  }

  onPageHide(): void {
    HiLog.i(TAG, 'onPageHide E.');
    this.moreModeConfig.entryAOutMorePage(false);
    this.moreModeConfig.editMorePage(false);
    MediaLibraryUiService.getInstance().onPageChange(false);
    HiLog.i(TAG, 'onPageHide X.');
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

  private async indexOnStarted(data: CameraStartTypeStruct): Promise<void> {
    HiLog.i(TAG, 'importBrowser E.');
    if (data.type !== CameraStartType.COLD_START) {
      return;
    }
    const photoBrowserTimer = setTimeout(async () => {
      let photoBrowserLoader = await import('./PhotoBrowser');
      this.photoBrowserLoader = photoBrowserLoader.PhotoBrowserLoader;
      this.isStarted = true;
      AppStorage.setOrCreate('canClickThumbnailView', true);
      clearTimeout(photoBrowserTimer);
    }, 300);
    HiLog.i(TAG, 'importBrowser X.');
  }

  private onSettingViewShow(data: SettingViewData): void {
    HiLog.i(TAG, 'onSettingViewShow E.');
    if (data && data.isShowSettingView) {
      this.pageInfos.pushPath({ name: 'SettingView' });
      WindowService.getInstance().setSpecificSystemNavigationEnabled(true, true, true);
      this.checkRequestLocationDialogClose();
    } else {
      this.pageInfos.pop();
      WindowService.getInstance().setSpecificSystemNavigationEnabled(true, true, false);
    }
    HiLog.i(TAG, 'onSettingViewShow X.');
  }

  private onPhotoBrowserStatus(): void {
    if (this.state.photoBrowserStatus) {
      this.volumeService.volumeKeyUnsubscribe();
      this.selfieStickService.selfieStickUnSubscribe();
    } else {
      this.volumeService.volumeKeySubscribe();
      this.selfieStickService.selfieStickSubscribe();
    }
  }

  private onWindowEventType(data: WindowEventData): void {
    if (data.windowStageEventType === window.WindowStageEventType.INACTIVE) {
      this.volumeService.volumeKeyUnsubscribe();
      this.selfieStickService.selfieStickUnSubscribe();
    } else if (data.windowStageEventType === window.WindowStageEventType.ACTIVE) {
      this.volumeService.volumeKeySubscribe();
      this.selfieStickService.selfieStickSubscribe();
    }
  }

  private handoverFrameRate(): void {
    HiLog.i(TAG, 'handoverFrameRate E.');
    const isPanVideoOutput: boolean = OutputOperation.isPanVideoOutput(this.mode);
    if (!isPanVideoOutput) {
      return;
    }
    AppStorage.setOrCreate('restoreFlag', true);
    let frameRate = CameraBasicService.getInstance().getVideoFrameRate();
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
    if (this.state.isShowDefault) {
      if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
        HiLog.i(TAG, '(this.state.isShowDefault.');
        if (frameRate === this.FRAME_RATE_60FPS && videoProfile.frameRateRange.max !== this.FRAME_RATE_60FPS) {
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
      if (this.immersiveUIType !== UIOperationType.LR_SWIPE) {
        this.immersiveOpacity = 1;
      }
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_150,
        curve: Curve.Sharp,
      }, () => {
        this.immersiveOpacity = 0;
      })
    } else {
      this.immersiveOpacity = 0;
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_150,
        curve: Curve.Sharp,
        onFinish: () => {
          this.immersiveUIType = mImmersiveUIType; // 保证退出沉浸式时self不受opacity影响
        }
      }, () => {
        this.immersiveOpacity = 1;
      })
    }
  }

  private initializeGuidancePages(): void {
    this.isGuidanceLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_GUIDANCE_LOADED, false) as boolean;
  }

  build() {
    Stack() {
      Navigation(this.pageInfos) {
        Stack({ alignContent: Alignment.Top }) {
          PreviewWrap();
          LandscapeIndex({
            immersiveUIType: this.immersiveUIType,
            immersiveOpacity: this.immersiveOpacity,
            isShowNightExposure: this.isShowNightExposure,
            isShowSettingView: this.state.isShowPageView,
          }).visibility(this.isShowViewVisibility ? Visibility.Visible : Visibility.Hidden)

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
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
      }
      .width('100%')
      .height('100%')
      .hideTitleBar(true)
      .navDestination(this.PageMap)
      .mode(NavigationMode.Stack)
      .backgroundColor(Color.Black)
      .onTouch(() => {
      })
      .customNavContentTransition((from: NavContentInfo, to: NavContentInfo, operation: NavigationOperation) => {
        return undefined;
      })
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
}