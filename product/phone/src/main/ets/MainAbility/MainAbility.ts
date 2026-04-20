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
/* instrument ignore file */
import UIAbility from '@ohos.app.ability.UIAbility';
import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import type { Dispatch } from '@ohos/common/src/main/ets/redux';
import lazy { execDispatch, getDispatch, getStates, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy {
  EXPIRE_MINUTE_TIME_15,
  FLUSH_TIMESTAMP,
  PersistType,
  PreferencesService
} from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { ModeType, VdeCollapsedFilterModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { ModeListManager } from '@ohos/common/src/main/ets/mode/ModeListManager';
import lazy { CameraProxy } from '@ohos/common/src/main/ets/camera/uithread/CameraProxy';
import camera from '@ohos.multimedia.camera';
import lazy { CameraAction } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { PropTag, PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { PlaySound } from '@ohos/common/src/main/ets/component/playsound/playSound';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import type { SettingViewData } from '@ohos/common/src/main/ets/function/setting/SettingFunction';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { pxChange, WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import CommonEventManager, { CUSTOM_EVENTS } from '@ohos/common/src/main/ets/component/commonevent/CommonEventManager';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import type Want from '@ohos.app.ability.Want';
import lazy { ModeMap } from '../common/ModeMap';
import window from '@ohos.window';
import lazy { RecordAction, RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { WindowAction } from '@ohos/common/src/main/ets/service/window/WindowAction';
import lazy { MoreModeConfig } from '@ohos/common/src/main/ets/mode/MoreModeConfig';
import screenLock from '@ohos.screenLock';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { BusinessError, Callback } from '@ohos.base';
import lazy { display } from '@kit.ArkUI';
import lazy { DataUriType, SettingsDataShareUtils } from '@ohos/common/src/main/ets/utils/SettingsDataShareUtils';
import lazy { OverTimeFuncSv } from '@ohos/common/src/main/ets/service/overTimerDefaultFunc/OverTimeFuncSv';
import lazy {
  ShortCutMode,
  ShortCutVisitService
} from '@ohos/common/src/main/ets/service/shortcutvisit/ShortCutVisitService';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { AbilityConstant, ApplicationStateChangeCallback, common, Configuration } from '@kit.AbilityKit';
import lazy { ZoomOperation } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import lazy { OutputSwitcher } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcher';
import lazy { ModePosWarmStartUtil } from '@ohos/common/src/main/ets/mode/ModePosWarmStartUtil';
import lazy {
  SettingFuncDialogItemIndex
} from '@ohos/common/src/main/ets/component/settingview/SettingFuncDialogItemIndex';
import MediaLibraryUiService from '@ohos/common/src/main/ets/service/medialibrary/MediaLibraryUiService';
import lazy { ThumbnailInfo } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailInfo';
import lazy { BlurAnimateUtil } from '@ohos/common/src/main/ets/utils/BlurAnimateUtil';
import lazy { simpleStringify } from '@ohos/common/src/main/ets/utils/SimpleStringify';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import power from '@ohos.power';
import config from '@ohos.accessibility.config';
import lazy { RestoreManager } from '@ohos/common/src/main/ets/restore/RestoreManager';
import lazy { SuspendTaskUtil } from '@ohos/common/src/main/ets/utils/SuspendTaskUtil';
import lazy { JSON } from '@kit.ArkTS';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy {
  RemoteAuthorizeState,
  RemoteCaptureService
} from '@ohos/common/src/main/ets/service/RemoteCapture/RemoteCaptureService';
import lazy { accessibility } from '@kit.AccessibilityKit';
import lazy { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import lazy { AppLockUtil } from '@ohos/common/src/main/ets/utils/AppLockUtil';
import lazy { rpc } from '@ohos/common/src/main/ets/utils/LazyImportUtil';
// @ts-ignore
import abilityConnectionManager from '@ohos.distributedsched.abilityConnectionManager';
import lazy { AudioSessionService } from '@ohos/common/src/main/ets/service/audioSessionService/AudioSessionService';
import lazy { ThumbnailAction } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailAction';
import lazy { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import lazy { SensorService } from '@ohos/common/src/main/ets/service/sensor/SensorService';
import lazy { AVPlayerService } from '@ohos/common/src/main/ets/service/AVPlayerService/AVPlayerService';
import lazy { FrameLockScene } from '@ohos/common/src/main/ets/utils/FrameLockScene';
import lazy { PhotoBrowserManager } from '@ohos/common/src/main/ets/service/photoBrowser/PhotoBrowserManager';
// @ts-ignore
// import lazy { PafEngine, Region } from '@ohos-paf/ui-widget-base-v2';
import lazy { TabBarAction } from '@ohos/common/src/main/ets/component/tabbar/TabBarAction';
import lazy { dataShare } from '@kit.ArkData';
import lazy { DelayLoadService } from '@ohos/common/src/main/ets/service/delayLoad/delayLoadService';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import lazy {
  AUTH_STATE,
  CollaborateControlService,
  CONNECT_TYPE
} from '@ohos/common/src/main/ets/service/collaborateControl/CollaborateControlService'
import lazy {
  DialogParams,
  CollaborateControlAction
} from '@ohos/common/src/main/ets/service/collaborateControl/CollaborateControlAction'

const TAG: string = 'MainAbility';
const CAMERA_SHOT_KEY_SIZE = 13; // 针对拼接时间戳长度
const START_DELAY_WITH_PICKER = 300;
const START_DELAY_WINDOW_SETTING = 180;
const DELAY_UPDATE_TABBAR = 50;
const SCREEN_COLLAPSED: number = 0;
const SCREEN_EXPANDED: number = 1;
const SCREEN_UNDEFINED: number = -1;
const ULTRA_SNAP_SHOT_DELAY: number = 500;
const CAMERA_BUNDLE_NAME: string = 'com.ohos.camera';
const CAMERA_ABILITY_NAME: string = 'com.ohos.camera.MainAbility';
const DOUBLE_TAP_PACKAGE = 'com.ohos.quickaccessmenu';
const TELEPHOTO_PACKAGE = 'com.ohos.baseexperience';
const FRESH_OPEN_TOUCH_GUIDE_DELAY: number = 1000;

type StartMessage = {
  mode: ModeType;
  position: camera.CameraPosition
};

class AbilityDispatcher {
  private mDispatch: Dispatch;

  public setDispatch(dispatch: Dispatch): void {
    this.mDispatch = dispatch;
  }

  public createAndOpenCameraInput(position: camera.CameraPosition, mode: ModeType): void {
    this.mDispatch(CameraAction.createAndOpenCameraInput(position, mode))
  }

  public coldStartup(position, mode): void {
    this.mDispatch(CameraAction.init(position, mode, true));
  }

  public warmStartup(): void {
    this.mDispatch(CameraAction.warmStart());
  }

  public switchCamera(cameraPosition: camera.CameraPosition): void {
    this.mDispatch(CameraAction.switchCamera(cameraPosition));
  }

  public changeMode(mode: ModeType): void {
    this.mDispatch(CameraAction.changeMode(mode));
  }

  public freshUx(): void {
    this.mDispatch(WindowAction.refresh());
  }

  public photoBrowserOnBackPress(): void {
    this.mDispatch(Action.photoBrowserOnBackPress());
  }

  public stopPreview(): void {
    this.mDispatch(CameraAction.stopPreview());
  }

  public recoverCamera(position): void {
    this.mDispatch(CameraAction.recoverCamera(position));
  }

  public switchCameraChangeModeOnly(cameraPosition: camera.CameraPosition, mode: ModeType): void {
    this.mDispatch(Action.switchCameraChangeModeOnly(cameraPosition, mode));
  }

  public foreground(): void {
    this.mDispatch(ContextAction.abilityOnForeground());
  }

  public background(isPickerBack: boolean): void {
    this.mDispatch(ContextAction.abilityOnBackground(isPickerBack));
  }

  public abilityOnDestroy(): void {
    this.mDispatch(ContextAction.abilityOnDestroy());
  }

  public changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.NULL));
  }

  public isShowWatermarkPage(isShow: boolean): void {
    this.mDispatch(Action.isShowWatermarkPage(isShow));
  }

  public changeWindowEventType(windowStageEventType: window.WindowStageEventType): void {
    this.mDispatch(ContextAction.changeWindowEventType(windowStageEventType));
  }

  public stopRecording(): void {
    this.mDispatch(RecordAction.stop());
  }

  public close(): void {
    this.mDispatch(CameraAction.release(true));
  }

  public setCameraShotKey(cameraShotKey: string): void {
    if (getStates().get<string>('securityCameraReducer', 'cameraShotKey') === cameraShotKey) {
      // 两次cameraShotKey值相同，不重复发送消息
      return;
    }
    this.mDispatch(Action.setCameraShotKey(cameraShotKey));
  }

  public updateIsSecurityCamera(isSecurityCamera: boolean): void {
    this.mDispatch(Action.updateIsSecurityCamera(isSecurityCamera));
  }


  public showThumbnailReminder(isShow: boolean): void {
    this.mDispatch(Action.showThumbnailReminder(isShow));
  }

  public showAppLockReminder(isShow: boolean): void {
    this.mDispatch(Action.showAppLockReminder(isShow));
  }

  public updateModeBar(): void {
    this.mDispatch(Action.updateModeBar());
  }

  public updateHighContrastState(isHighContrast: boolean): void {
    this.mDispatch(ContextAction.updateHighContrastState(isHighContrast));
  }

  public refreshThumbnail(isRefreshDefaultThumbnail: boolean): void {
    this.mDispatch(ThumbnailAction.refresh(isRefreshDefaultThumbnail));
  }

  public clearPageOrDialog(): void {
    this.mDispatch(Action.clearPageOrDialog());
  }


  public changeFunctionStatus(id: FunctionId, value: boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public closeCustomFilterCard(): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(false));
    setTimeout((): void => {
      this.mDispatch(TabBarAction.updateTabBarArr());
    }, DELAY_UPDATE_TABBAR);
  }

  public quitCustomFilterCardAndTreasureBox(): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(false));
  }
}

export default class MainAbility extends UIAbility {
  private mAction: AbilityDispatcher = new AbilityDispatcher();
  private mGlobalContext: GlobalContext = GlobalContext.get();
  private isForeground: boolean = false;
  private preferencesService: PreferencesService = PreferencesService.getInstance();
  // 快捷列表访问
  private isVisitedByShortCut: boolean = false;
  private shortCutVisitMode: ModeType = ModeType.NONE;
  private shortCutVisitPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;
  // 熄屏快拍访问
  private isUltraSnapshotCapture: boolean = false;
  private isVisitedByUltraSnapshot: boolean = false;
  // 三方应用拉系统相机
  private isVisitedByApp: boolean = true;
  private appVisitMode: ModeType = ModeType.NONE;
  private appVisitPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;
  private lastVdeCollapsStatus = SCREEN_UNDEFINED;
  private remoteCapture: RemoteCaptureService = undefined;
  private isRemoteCapture: boolean = false;
  private moreModeConfig: MoreModeConfig = MoreModeConfig.getInstance();
  private modeListManger: ModeListManager = ModeListManager.getInstance();
  private launchParam: AbilityConstant.LaunchParam;
  private isOnCreateLoaded: boolean = false;
  private mMainWindow: window.Window = undefined;
  private isSelfieStick: boolean = false;
  private recordingState: RecordingState = RecordingState.READY;
  private AppLockCallback = (value: boolean): void => {
    HiLog.i(TAG, `AppLockCallback = ${value}`);
    this.setCameraShotKey(value);
    if (getStates().get<boolean>('securityCameraReducer', 'appLockReminderShow') && !value) {
      this.mAction.showAppLockReminder(false);
    }
  };
  private isIntentVisit: boolean = false;
  private intentMode: ModeType = ModeType.NONE;
  private intentPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    HiLog.begin(TAG, 'onCreate');
    DelayLoadService.getInstance().loadFromOnCreate();
    if (!want) {
      HiLog.e(TAG, 'onCreate want is empty');
      return;
    }
    this.mAction.setDispatch(getDispatch());
    this.onWantReceived(want);
    AppStorage.setOrCreate('Destroyed', false);
    ContextManager.getInstance().setAbilityContext(this.context);
    try {
      const cameraMananger = camera.getCameraManager(this.context)
      cameraMananger.getSupportedCameras();
    } catch (e) {
      HiLog.e(TAG, 'pre getSupportedCameras error')
    }
    this.preCreateCamera(launchParam);
    AppLockUtil.getInstance().registerAppLock(this.AppLockCallback);
    this.launchParam = launchParam;
    const fontSizeScale = this.context.config.fontSizeScale;
    if (fontSizeScale) {
      AppStorage.setOrCreate('fontSizeScale', fontSizeScale);
      HiLog.i(TAG, `onCreate fontSizeScale = ${fontSizeScale}`);
    }
    if (!!want?.parameters?.callBundleName && want?.parameters['ohos.aafwk.param.callerToken']) {
      PickerUiService.getInstance().addPickerVisitLog();
    }
    this.onConfigurationUpdate(this.context.config);
    this.mGlobalContext.setIsPicker(false);

    this.mGlobalContext.setObject('permissionFlag', false);
    const { mode, position }: StartMessage = this.getColdStartMessage();
    HiLog.i(TAG, `cold start mode: ${mode}, position: ${position}, isVisitedByShortCut: ${this.isVisitedByShortCut}.`);
    CameraAppCapability.getInstance().queryCapability(position, mode);
    FeatureManager.getInstance().init(mode, new ModeMap());
    this.doColdStartUp(position, mode, launchParam);
    this.setDefaultConfigValue();
    this.moreModeConfig.mixPersistAndDefaultModeList();
    const modeList = this.moreModeConfig.processGlobalModeListAndName(mode);
    this.modeListManger.init(modeList);
    PlaySound.getInstance().init(); // 初始化音频池
    DisplayService.getInstance().init();
    AppStorage.setOrCreate('settingAnimationDoing', false);
    AppStorage.setOrCreate('lastDirection', WindowDirection.TOP);
    AppStorage.setOrCreate('startOrUserChangeToModeLast', [ModeType.NONE, mode]);

    CommonEventManager.getInstance().publishCommonEventMg(CUSTOM_EVENTS.PREEMPTION, { isPicker: false, active: true });
    this.initRemoteCaptureSvs(want);
    this.subscribeStateChange();
    RestoreManager.getInstance().addProcessChangeListener();
    this.isOnCreateLoaded = true;
    const isUpdatedWaterMarkStatus =
      this.preferencesService.getPropValue(PersistType.FOREVER, PropTag.IS_UPDATED_WATERMARK_STATUS, false) as boolean
    if (!isUpdatedWaterMarkStatus) {
      this.preferencesService.putPropValue(PersistType.FOREVER, PropTag.IS_UPDATED_WATERMARK_STATUS, true);
    }
    TipService.getInstance(); // 触发TipService的监听
    HiLog.end(TAG, 'onCreate');
  }

  preCreateCamera(launchParam: AbilityConstant.LaunchParam) {
    if (launchParam && launchParam.launchReason === AbilityConstant.LaunchReason.CALL) {
      HiLog.i(TAG, 'preCreateCamera by call');
      return
    }
    // Worker init must not run here when intro is already done: doColdStartUp() dispatches
    // CameraAction.init (ACTION_INIT). createAndOpenCameraInput also posts ACTION_INIT and
    // caused queue ACTION_INIT,ACTION_INIT → 7400109 / black screen (see cold-start logs).
  }

  private registerDataShare(): void {
    let uri: string = SettingsDataShareUtils.getSettingsUri(DataUriType.SETTING_GLOBAL_URI,
      SettingsDataShareUtils.ENABLE_SCREEN_READER_KEY);
    if (!uri) {
      HiLog.e(TAG, 'createDataHelper screen read uri empty!');
      return;
    }
    this.queryEnableScreenReader();
    (SettingsDataShareUtils.createDataHelper(uri) as Promise<dataShare.DataShareHelper>).then((
      dataHelper?: dataShare.DataShareHelper | undefined) => {
      SettingsDataShareUtils.registerDataChange(dataHelper, uri, () => this.queryEnableScreenReader());
    });
  }

  private initRemoteCaptureSvs(want: Want): void {
    if (want.action === 'com.ohos.camera.intent.RemoteCall') {
      // 遥控拍照入口
      let uuid: string = want.parameters?.uuid.toString();
      let deviceName: string = want.parameters?.deviceName.toString();
      HiLog.i(TAG, `Enter RemoteCapture`);
      this.isRemoteCapture = true;
      AppStorage.setOrCreate('isRemoteCapture', this.isRemoteCapture);
      CollaborateControlService.getInstance().setRemoteConnectType(CONNECT_TYPE.SPORT_REMOTE)
      this.initRemoteCapture(uuid, deviceName);
    }
    if (want.action === 'RemoteCall') {
      // 新遥控拍照入口
      this.isRemoteCapture = true;
      AppStorage.setOrCreate('isRemoteCapture', this.isRemoteCapture);
      if (typeof want.parameters?.isNeedSetPermission !== 'boolean' || typeof want.parameters?.uuid !== 'string'
        && typeof want.parameters?.uuid !== 'number') {
        HiLog.w(TAG, 'parameters isNeedSetPermission or uuid Illegal return.');
        return;
      }
      let isNeedSetPermission: boolean = want.parameters?.isNeedSetPermission as boolean;
      let uuid: string = want.parameters?.uuid.toString();
      CollaborateControlService.getInstance().setRemoteConnectType(CONNECT_TYPE.SMART_REMOTE)
      this.initRemoteCaptureNew(isNeedSetPermission, uuid);
    }
  }

  private async initRemoteCaptureNew(isNeedSetPermission: boolean | undefined, uuid: string): Promise<void> {
    if (screenLock.isLocked()) {
      power.wakeup('');
    }
    this.remoteCapture = RemoteCaptureService.getInstance();
    await this.remoteCapture.init(true);
    await this.remoteCapture.RemoteCaptureSubscribe();
    if (isNeedSetPermission === true) {
      // 用户选择始终允许，需要向运动健康写入授权数据
      await this.remoteCapture.setPermissionUuid(uuid, true);
    }
    await this.remoteCapture.startCamera();
  }

  private async initRemoteCapture(uuid: string, deviceName: string): Promise<void> {
    if (screenLock.isLocked()) {
      power.wakeup('');
    }
    HiLog.begin(TAG, 'remoteCapture');
    this.remoteCapture = RemoteCaptureService.getInstance();
    await this.remoteCapture.init(true);
    this.remoteCapture.setDeviceName(deviceName);
    this.remoteCapture.setUuid(uuid);
    let isGranted: boolean = await this.remoteCapture.verifyPermission(uuid);
    HiLog.i(TAG, `remoteCapture isGranted: ${isGranted}`);
    await this.remoteCapture.RemoteCaptureSubscribe();
    if (!isGranted) {
      const dialogParams: DialogParams = {
        show: true,
        deviceName: deviceName,
        isCustomStyle: false
      };
      StoreManager.getInstance().postMessage(CollaborateControlAction.showCommonCaptureDialog(dialogParams));
      return;
    }
    await this.remoteCapture.startCamera();
    HiLog.end(TAG, 'remoteCapture');
  }

  private async quitRemoteCapture(): Promise<void> {
    HiLog.i(TAG, `Quit remoteCapture.`);
    await this.remoteCapture.quitCamera();
    await this.remoteCapture.RemoteCaptureUnSubsrcibe();
    this.isRemoteCapture = false;
    AppStorage.setOrCreate('isRemoteCapture', this.isRemoteCapture);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    HiLog.i(TAG, 'onConfigurationUpdate');
    const fontSizeScale = newConfig.fontSizeScale;
    if (fontSizeScale) {
      AppStorage.setOrCreate('fontSizeScale', fontSizeScale);
      HiLog.i(TAG, `onConfigurationUpdate fontSizeScale = ${fontSizeScale}`);
    }
    if (newConfig?.displayId) {
      AppStorage.setOrCreate('windowDisplayId', newConfig.displayId);
      const displayName: string = WindowService.getInstance().getWindowDisplayName();
      HiLog.i(TAG, `onConfigurationUpdate: dn is ${displayName}`);
      AppStorage.setOrCreate('windowDisplayName', displayName);
    }
    if (newConfig.language) {
      HiLog.i(TAG, `systemLanguage change to ${newConfig.language}`);
      AppStorage.setOrCreate('systemLanguage', newConfig.language);
    }
  }

  private async queryEnableScreenReader(): Promise<void> {
    HiLog.i(TAG, 'queryEnableScreenReader');
    let enableScreenReader: boolean = await SettingsDataShareUtils.getBoolValue(DataUriType.SETTING_GLOBAL_URI,
      SettingsDataShareUtils.ENABLE_SCREEN_READER_KEY, false);
    GlobalContext.get().setScreenReaderEnabled(enableScreenReader);
    AppStorage.setOrCreate('enableScreenReader', enableScreenReader);
    setTimeout(() => {
      const isOpenTouchGuide: boolean = accessibility.isOpenTouchGuideSync(); // 无障碍 浏览模式
      HiLog.i(TAG, `queryEnableScreenReader isOpenTouchGuide: ${isOpenTouchGuide}`);
      GlobalContext.get().setOpenTouchGuide(isOpenTouchGuide);
      AppStorage.setOrCreate('isOpenTouchGuide', isOpenTouchGuide);
    }, FRESH_OPEN_TOUCH_GUIDE_DELAY);
    HiLog.i(TAG, 'queryEnableScreenReader' + enableScreenReader);
  }

  private getColdStartMessage(): StartMessage {
    let coldPos: camera.CameraPosition = this.getColdPosition();
    let coldMode: ModeType = this.getColdMode(coldPos);
    HiLog.i(TAG, `getColdStartMessage mode: ${coldMode}, camera position: ${coldPos}`);
    return {
      position: coldPos, mode: coldMode
    };
  }

  private getColdPosition(): camera.CameraPosition {
    let position: camera.CameraPosition =
      <camera.CameraPosition> this.preferencesService.getPropValue(PersistType.FOR_AWHILE, PropTag.CAMERA_POSITION,
        camera.CameraPosition.CAMERA_POSITION_BACK);
    if (this.isVisitedByShortCut || this.isUltraSnapshotCapture) {
      position = this.shortCutVisitPosition;
    }
    if (AppStorage.get('isLemCollaps')) {
      position = camera.CameraPosition.CAMERA_POSITION_FRONT;
    }
    if (this.isVisitedByApp) {
      position = this.appVisitPosition;
    }
    if (this.isIntentVisit) {
      position = this.intentPosition;
    }
    return position;
  }

  private getColdMode(pos: camera.CameraPosition): ModeType {
    let mode: ModeType = this.getModeByPosition(pos, true);
    if (this.isVisitedByShortCut) {
      mode = this.shortCutVisitMode;
    }
    if (this.isVisitedByApp) {
      mode = this.appVisitMode;
    }
    if (this.isIntentVisit) {
      mode = this.intentMode;
    }
    return mode;
  }

  private doColdStartUp(position: camera.CameraPosition, mode: ModeType,
    launchParam: AbilityConstant.LaunchParam): void {
    let isIntroLoaded: boolean = <boolean> this.preferencesService.getPublicValue(PersistType.FOREVER,
      PublicTag.IS_INTRO_LOADED, false) && !AppStorage.get('isLemCollaps');
    let isLemCollapsGuideLoad: boolean = <boolean> this.preferencesService.getPropValue(PersistType.FOREVER,
      PropTag.IS_SEMI_COLLAPSED_GUIDE_LOAD, false) && AppStorage.get('isLemCollaps');
    let isVdeCollapsGuideLoad: boolean = <boolean> this.preferencesService.getPropValue(PersistType.FOREVER,
      PropTag.IS_SEMI_COLLAPSED_GUIDE_LOAD, false);
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CALL) {
      // 遥控拍照拉起方式,相机在后台,先不起流
      HiLog.i(TAG, 'doColdStartUp by call');
      return;
    }
    if (isIntroLoaded || isLemCollapsGuideLoad || isVdeCollapsGuideLoad) { // 前次拉起相机已同意权限,当前次拉起可直接走冷启动流程
      this.mAction.coldStartup(position, mode);
    }
  }

  private setDefaultConfigValue(): void {
  }

  private getModeByPosition(position: camera.CameraPosition, clodStart: boolean): ModeType {
    let mode: ModeType = ModeType.NONE;
    if (position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      const defaultValue: string = ModeType.PHOTO;
      mode = <ModeType> this.preferencesService.getPropValue(PersistType.FOR_AWHILE, PropTag.MODE, defaultValue);
      HiLog.i(TAG, `preference front mode:${mode}`);
    } else {
      mode = <ModeType> this.preferencesService.getPropValue(PersistType.FOR_AWHILE, PropTag.MODE, ModeType.PHOTO);
      HiLog.i(TAG, `preference back mode:${mode}`);
    }
    return mode;
  }

  onForeground(): void {
    HiLog.i(TAG, 'onForeground');
    AppStorage.setOrCreate('closeFromWindowPaused', false);
    DelayLoadService.getInstance().loadFromOnForeground();
    this.checkWindowSize();
    // 起流前设置窗口，并主动获取一次窗口状态，解决窗口状态回调滞后，获取CameraProfiles配置不正确问题
    // 问题场景：展开态悬浮窗&分屏，照片比例全屏，息屏亮屏后预览拉伸
    if (!this.isOnCreateLoaded) {
      const windowService: WindowService = WindowService.getInstance();
      windowService.reSetWin(this.mMainWindow);
    }
    this.foreGroundToWarmStart();

    PhotoBrowserManager.getInstance().setViewVisibility();
    GlobalContext.get().setIsPicker(false);
    this.powerOffTerminate();
    this.restoreSecuritySettings();

    GlobalContext.get().setObject('isPhotoOn', false);
    CommonEventManager.getInstance().createSubscriber();
    this.isForeground = true;
    HiLog.begin(TAG, 'onForeground');
    const isShowPrivacyPolicyView: boolean = AppStorage.get('isShowPrivacyPolicyView');
    WindowService.getInstance().setSpecificSystemNavigationEnabled(true, true, isShowPrivacyPolicyView ||
    getStates().get<boolean>('settingViewReducer', 'isShowSettingView'));
    AppStorage.setOrCreate<boolean>('isBackground', false);
    WindowService.getInstance().setWindowBackGround(false);
    AppStorage.setOrCreate('enterCameraTime', Date.now());
    this.securityHandler();
    if (!getStates().get<boolean>('cameraReducer', 'isColdStart')) {
      const modes = this.moreModeConfig.processGlobalModeListAndName(getStates().get<ModeType>('modeReducer', 'mode'));
      this.modeListManger.init(modes);
      this.mAction.updateModeBar();
    }
    AppStorage.setOrCreate<boolean>('isMainForeground', true);
    this.mAction.foreground();
    AppStorage.setOrCreate('settingAnimationDoing', false);
    if (getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed') || AppStorage.get('isPSDCollaps')) {
      WindowService.getInstance().setWinOrientation(window.Orientation.PORTRAIT);
    }
    this.resetRecordState();
    this.getHighContrastTextState();
    this.ultraSnapshotUnlock();
    WindowService.getInstance().setFullScreen();
    let isOpenTouchGuide: boolean = accessibility.isOpenTouchGuideSync(); // 无障碍 浏览模式
    GlobalContext.get().setOpenTouchGuide(isOpenTouchGuide);
    AppStorage.setOrCreate('isOpenTouchGuide', isOpenTouchGuide);
    HiLog.end(TAG, 'onForeground');
    FrameLockScene.getInstance().apsSetScene('PreviewArea', true); // 进入相机开始锁帧
  }

  private resetRecordState(): void {
    // 相机进入前台时, 如果上次录像依然处于stopping状态, 则state无法恢复，会导致本次启动无法录像
    this.recordingState = getStates().get<RecordingState>('recordReducer', 'recordingState');
    HiLog.i(TAG, 'Last AVRecorder recordingState ' + this.recordingState);
    if (this.recordingState === RecordingState.STOPPING) {
      StoreManager.getInstance().postMessage(RecordAction.stopped());
      HiLog.w(TAG, 'Last AVRecorder error no stopped, reset record-state to ready.');
    }
  }

  private async securityHandler(): Promise<void> {
    if (AppStorage.get('isLemCollaps')) {
      // LEM 外屏不走应用锁逻辑
      return;
    }
    HiLog.i(TAG, `securityHandler begin`);
    let isAppLock = await AppLockUtil.getInstance().isPhotoAppLocked();
    HiLog.i(TAG, `isAppLock is ${isAppLock}`);
    if (GlobalContext.get().getObject('isSecurityCamera') || this.isRemoteCapture || this.isSelfieStick) {
      return;
    }
    if (isAppLock) {
      this.setCameraShotKey(true);
    } else {
      this.setCameraShotKey(false);
    }
    HiLog.i(TAG, `securityHandler end`);
  }

  private async powerOffTerminate(): Promise<void> {
    // 息屏拉起自杀相机
    const isActive = await power.isActive();
    if (GlobalContext.get().getT('isSecurityCamera') && !isActive &&
      AppStorage.get('windowDisplayName') !== 'SuperLauncher') {
      ContextManager.getInstance().getUiContext().terminateSelf().then(() => {
        HiLog.i(TAG, 'terminateSelf success');
      });
      return;
    }
  }

  private ultraSnapshotUnlock(): void {
    setTimeout(() => {
      if (this.isVisitedByUltraSnapshot && screenLock.isLocked() && !GlobalContext.get().getT('isSecureMode')) {
        HiLog.i(TAG, 'unlock');
        screenLock.unlock(() => {
          HiLog.i(TAG, 'unlock end.');
        });
      }
    }, ULTRA_SNAP_SHOT_DELAY);
  }

  // 热启动的起流过程
  public foreGroundToWarmStart(): void {
    OverTimeFuncSv.resetFuncDefaultVal();
    const state = getStates();
    let isIntroLoad: boolean =
      <boolean> this.preferencesService.getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false);
    let isIntroLoadLem: boolean =
      <boolean> this.preferencesService.getPropValue(PersistType.FOREVER, PropTag.IS_SEMI_COLLAPSED_GUIDE_LOAD, false);
    if (CameraAppCapability.getInstance().getIsSupportedLowAngleShot()) {
    }
    let position = <camera.CameraPosition> this.preferencesService.getPropValue(PersistType.FOR_AWHILE,
      PropTag.CAMERA_POSITION, camera.CameraPosition.CAMERA_POSITION_BACK);
    let curMode: ModeType = this.getModeByPosition(position, false);
    if (AppStorage.get('isLemOut2in')) {
      this.prepareForLemOut2in();
    }
    if (!AppStorage.get('isLemCollaps') && (!isIntroLoad || state.get<boolean>('cameraReducer', 'isColdStart'))) {
      HiLog.w(TAG, `Interrupt Warm start, ${!isIntroLoad}, ${state.get<boolean>('cameraReducer', 'isColdStart')}`);
      return;
    }
    if (AppStorage.get('isLemCollaps') && (!isIntroLoadLem || AppStorage.get('isPermissionShow'))) {
      HiLog.w(TAG, `LemCollaps interrupt Warm start, ${!isIntroLoadLem}, ${AppStorage.get('isPermissionShow')}`);
      return;
    }
    if (AppStorage.get<boolean>('isShowPhotoBrowser')) {
      HiLog.w(TAG, `isShowPhotoBrowser = true`);
      return;
    }
    const isOverDefaultTime = this.preferencesService.isExpire(EXPIRE_MINUTE_TIME_15, FLUSH_TIMESTAMP);
    HiLog.i(TAG, `onForeground mode:${curMode}, state mode:${state.get<ModeType>('modeReducer',
      'mode')}, overTime:${isOverDefaultTime}`);
    // 热启动15min内外，镜头模式处理
    const isOpenCustomFilterCardByApp: boolean | undefined = AppStorage.get('isOpenCustomFilterCardByApp');
    HiLog.i(TAG, 'onForeground isOpenCustomFilterCardByApp: ' + isOpenCustomFilterCardByApp);
    if (isOverDefaultTime) { // 15分钟后不加载之前的焦距
      ZoomOperation.getInstance().setRemainZoomRatio(false);
    }
    if (this.isVisitedByShortCut) {
      HiLog.i(TAG, 'shortCut warmStart');
      AppStorage.setOrCreate('isVisitedByShortCut', true);
      ModePosWarmStartUtil
        .startWithParams(state.get<ModeType>('modeReducer', 'mode'), this.shortCutVisitMode,
          this.shortCutVisitPosition);
      /* instrument ignore  if*/
    } else if (this.isVisitedByApp) {
      HiLog.i(TAG, 'appVisit warmStart');
      ModePosWarmStartUtil
        .startWithParams(state.get<ModeType>('modeReducer', 'mode'), this.appVisitMode, this.appVisitPosition);
    } else if (isOverDefaultTime && state.get<ModeType>('modeReducer', 'mode') !== curMode) {
      HiLog.i(TAG, 'warmStartWithModeAPosEntry.');
      ModePosWarmStartUtil.startWithParams(state.get<ModeType>('modeReducer', 'mode'), curMode, position);
    } else if (AppStorage.get('isLemOut2in') || AppStorage.get('isLemCollaps')) {
      HiLog.i(TAG, 'lem warmStart.');
      ModePosWarmStartUtil.startWithParams(state.get<ModeType>('modeReducer', 'mode'), curMode,
        camera.CameraPosition.CAMERA_POSITION_FRONT);
      AppStorage.setOrCreate('isLemOut2in', false);
    } else if (this.isIntentVisit) {
      HiLog.i(TAG, 'intentVisit warmStart');
      ModePosWarmStartUtil.startWithParams(state.get<ModeType>('modeReducer', 'mode'), this.intentMode,
        this.intentPosition);
    } else if (curMode === state.get<ModeType>('modeReducer', 'mode')) {
      HiLog.i(TAG, 'normal warmStart.');
      this.normalWarmStart();
    } else if (curMode !== state.get<ModeType>('modeReducer', 'mode')) { // 兜底，缓存和redux状态不同，以Redux统一，避免cameraManger为空
      HiLog.i(TAG, `warmStartWithModeAPos special case:${state.get<ModeType>('modeReducer', 'mode')}`);
      this.mAction.updateModeBar();
      ModePosWarmStartUtil
        .startWithParams(state.get<ModeType>('modeReducer', 'mode'), state.get<ModeType>('modeReducer', 'mode'));
    } else { // cold start流程没走完，就秒退秒起
      HiLog.i(TAG, 'code start is not ended but new foreground triggered.');
    }
  }

  private warmStartByShortcut(state: OhCombinedState): void {
    HiLog.i(TAG, 'shortCut warmStart');
    AppStorage.setOrCreate('isVisitedByShortCut', true);
    ModePosWarmStartUtil
      .startWithParams(state.get<ModeType>('modeReducer', 'mode'), this.shortCutVisitMode, this.shortCutVisitPosition);
  }

  private processVdeWarmStart(isOverDefaultTime: boolean, state: OhCombinedState, curMode: ModeType): void {
    let preMode = state.get<ModeType>('modeReducer', 'mode');
    let prePosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    HiLog.i(TAG, `processWarmStart preMode: ${preMode}, prePosition: ${prePosition}, curMode: ${curMode}`);
    if (this.isVisitedByShortCut) {
      this.warmStartByShortcut(state);
    } else if (this.isUltraSnapshotCapture) {
      HiLog.i(TAG, 'ultra snapshot warmStart');
    } else if (this.isVisitedByApp) {
      HiLog.i(TAG, 'process appVisit warmStart');
      const modes = MoreModeConfig.getInstance().processGlobalModeListAndName(this.appVisitMode);
      HiLog.d(TAG, `process inner warm start, modes: ${modes}, open mode: ${preMode}`);
      ModeListManager.getInstance().init(modes);
      this.mAction.updateModeBar();
      ModePosWarmStartUtil
        .startWithParams(state.get<ModeType>('modeReducer', 'mode'), this.appVisitMode, this.appVisitPosition);
    }
  }

  private handleVdeInnerWarmStart(preMode: ModeType, curMode: ModeType, cameraPosition: camera.CameraPosition): void {
    if (this.lastVdeCollapsStatus === SCREEN_COLLAPSED) {
      const modes = this.moreModeConfig.processGlobalModeListAndName(getStates().get<ModeType>('modeReducer', 'mode'));
      HiLog.d(TAG, `process phone outer to inner, modes: ${modes}, open mode: ${preMode}`);
      this.modeListManger.init(modes);
      this.mAction.updateModeBar();
      this.mAction.switchCameraChangeModeOnly(camera.CameraPosition.CAMERA_POSITION_BACK, preMode);
      ModePosWarmStartUtil.startWithParams(preMode, preMode, camera.CameraPosition.CAMERA_POSITION_BACK);
    } else if (preMode === curMode) {
      const modes = this.moreModeConfig.processGlobalModeListAndName(getStates().get<ModeType>('modeReducer', 'mode'));
      HiLog.d(TAG, `process inner warm start, modes: ${modes}, open mode: ${preMode}`);
      this.modeListManger.init(modes);
      this.mAction.updateModeBar();
      HiLog.i(TAG, 'process expanded normal warmStart.');
      this.normalWarmStart();
    } else if (preMode !== curMode) { // 兜底，缓存和redux状态不同，以Redux统一，避免cameraManger为空
      const modes = this.moreModeConfig.processGlobalModeListAndName(getStates().get<ModeType>('modeReducer', 'mode'));
      HiLog.d(TAG, `process inner warm start, open mode: ${preMode}`);
      this.modeListManger.init(modes);
      HiLog.i(TAG, `process expanded warmStartWithModeAPos special case:${preMode}`);
      this.mAction.updateModeBar();
      ModePosWarmStartUtil.startWithParams(preMode, preMode, cameraPosition);
    }
  }

  private handleVdeOuterWarmStart(preMode: ModeType, curMode: ModeType): void {
    if (this.lastVdeCollapsStatus === SCREEN_COLLAPSED) {
      ZoomOperation.getInstance().setRemainZoomRatio(true);
      if (preMode === curMode) {
        HiLog.i(TAG, 'process collapsed normal warmStart.');
        this.modeListManger.init(VdeCollapsedFilterModeType);
        this.mAction.updateModeBar();
        this.normalWarmStart();
      } else if (preMode !== curMode) { // 兜底，缓存和redux状态不同，以Redux统一，避免cameraManger为空
        HiLog.i(TAG, `process warmStartWithModeAPos special case:${preMode}`);
        this.mAction.updateModeBar();
        ModePosWarmStartUtil.startWithParams(preMode, preMode);
      }
      let cameraPosition = camera.CameraPosition.CAMERA_POSITION_FRONT;
      this.mAction.switchCameraChangeModeOnly(cameraPosition, preMode);
    } else {
      this.modeListManger.init(VdeCollapsedFilterModeType);
      this.mAction.updateModeBar();
      HiLog.d(TAG, `process phone inner to outer, reset PORTRAIT mode`);
      let cameraPosition = camera.CameraPosition.CAMERA_POSITION_FRONT;
    }
  }

  private prepareForLemOut2in(): void {
    GlobalContext.get().setCameraShotKey('');
    this.mAction.setCameraShotKey('');
    AppStorage.setOrCreate('cameraShotKey', ''); // 外屏图库使用
  }

  private prepareForSmallSubScreen(): void {
    let timestamp: string = `${Date.now()}`;
    let cameraShotKey = `isSecurityCamera_${'0'.repeat(CAMERA_SHOT_KEY_SIZE - timestamp.length)}${timestamp}`;
    HiLog.i(TAG, `small collaps subDisplay cameraShotKey ${cameraShotKey}`);
    GlobalContext.get().setCameraShotKey(cameraShotKey);
    this.mAction.setCameraShotKey(cameraShotKey);
    AppStorage.setOrCreate('cameraShotKey', cameraShotKey); // 外屏图库使用
  }

  private normalWarmStart(): void {
    if (AppStorage.get('pickerActive')) {
      HiLog.i(TAG, 'delay startup.');
      setTimeout(() => {
        this.mAction.warmStartup();
      }, START_DELAY_WITH_PICKER);
    } else {
      HiLog.i(TAG, 'startup.');
      this.mAction.warmStartup();
    }
  }

  /**
   * 拉起MainAbility
   */
  private async startMainAbility(): Promise<void> {
    HiLog.i(TAG, 'startMainAbility.');
    const want: Want = {
      bundleName: CAMERA_BUNDLE_NAME,
      abilityName: CAMERA_ABILITY_NAME,
      parameters: {
        // 这里是已授权拉起，不需要再传授权状态
        isDialogCallCamera: true,
        isSecureMode: await screenLock.isSecureMode(),
        isFromScreenLock: screenLock.isLocked()
      }
    };
    try {
      await this.context?.startAbility(want);
    } catch (error) {
      HiLog.e(TAG, ` startMainAbility error: ${error?.code}.`);
    }
  }

  /**
   * 打开跨设备访问权限弹窗
   *
   * @returns
   */
  async openDialog(wantParam: Record<string, Object>): Promise<void> {
    // @ts-ignore
    const options = wantParam?.ConnectOption as abilityConnectionManager.ConnectOptions;
    const udid = options?.parameters?.udid;
    const deviceName = options?.parameters?.deviceName;
    this.remoteCapture = RemoteCaptureService.getInstance();
    await this.remoteCapture.init(true);
    this.remoteCapture.setUdid(udid);
    const isGranted: boolean = await this.remoteCapture.verifyPermission(udid);
    HiLog.i(TAG, `openDialog isGranted = ${isGranted}`);
    if (isGranted) {
      CollaborateControlService.getInstance().handleAuthState(AUTH_STATE.ACCEPT)
      this.startMainAbility();
      return;
    }

    const newWant: Want = {
      bundleName: 'com.ohos.sceneboard',
      abilityName: 'com.ohos.sceneboard.systemdialog'
    }
    let dataSequence: rpc.MessageSequence = rpc.MessageSequence.create();
    let replySequence: rpc.MessageSequence = rpc.MessageSequence.create();
    const connectOption: common.ConnectOptions = {
      onConnect(elementName, remote) {
        HiLog.i(TAG, 'openDialog onConnect');
        let option = new rpc.MessageOption();
        dataSequence.writeInt(3);
        dataSequence.writeString('bundleName');
        dataSequence.writeString('com.ohos.camera');
        dataSequence.writeString('abilityName');
        dataSequence.writeString('RemoteCaptureDialogAbility');
        dataSequence.writeString('parameters');
        // sysDialogZOrder 1 锁屏下 2 锁屏上,需要增加权限ohos.permission.CALLED_UIEXTENSION_ON_LOCK_SCREEN
        const zOrder = screenLock.isLocked() ? 2 : 1;
        const parameter: Record<string, Object> = {
          'ability.want.params.uiExtensionType': 'sysDialog/common',
          'sysDialogZOrder': zOrder,
          'isSmartWatch': true,
          'watchDeviceName': deviceName
        };
        dataSequence.writeString(JSON.stringify(parameter));

        remote.sendMessageRequest(1, dataSequence, replySequence, option).then((ret) => {
          let msg = replySequence.readInt();
          HiLog.i(TAG, `openDialog sendMessageRequest ret: ${ret?.errCode}, msg:${msg}.`);
        }).catch((error: BusinessError) => {
          HiLog.e(TAG, `openDialog sendMessageRequest failed, err = ${error?.code}.`);
        });
      },
      onDisconnect(elementName) {
        HiLog.i(TAG, `openDialog onDisconnect, elementName: ${elementName.bundleName}.`);
        dataSequence.reclaim();
        replySequence.reclaim();
      },
      onFailed(code) {
        HiLog.i(TAG, `openDialog onFailed,code: ${code}.`);
        dataSequence.reclaim();
        replySequence.reclaim();
      }
    }
    try {
      const connectionId = this.context?.connectServiceExtensionAbility(newWant, connectOption);
      HiLog.i(TAG, `openDialog connectServiceExtensionAbility connectionId: ${connectionId}.`);
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      HiLog.e(TAG, `openDialog connectServiceExtensionAbility Failed,code: ${err?.code}.`);
      dataSequence.reclaim();
      replySequence.reclaim();
    }
  }

  onBackground(): void {
    this.isForeground = false;
    this.isVisitedByApp = false;
    this.isVisitedByShortCut = false;
    this.isIntentVisit = false;
    DelayLoadService.getInstance().unInit();
    FrameLockScene.getInstance().backGroundClearScene(); // 退出相机必须强制解除锁帧
    HiLog.begin(TAG, 'onBackground');
    AppStorage.setOrCreate<boolean>('isBackground', true);
    SensorService.getInstance().unRegisterMotionRotateListener();
    WindowService.getInstance().setWindowBackGround(true);
    this.mAction.refreshThumbnail(true);
    CommonEventManager.getInstance().unsubscribe();
    AudioSessionService.deactivateAudioSession();
    AppStorage.setOrCreate('isOpenCustomFilterCardByApp', false);
    const state = getStates();
    HiLog.i(TAG, 'onBackground after deactivateAudio .');
    let isShowPrivacyPolicyView: boolean = GlobalContext.get().getObject('privacyPolicyViewShow') as boolean;
    const isShowWatermarkView: boolean = AppStorage.get('isShowWatermarkView');
    if (getStates().get<boolean>('settingViewReducer', 'isShowSettingView') && !isShowPrivacyPolicyView &&
      !isShowWatermarkView) {
      const settingData: SettingViewData = {
        isShowSettingView: false,
        isTriggeredByBack: true
      };
      this.mAction.changeFunctionValue(FunctionId.SETTING, settingData);
    }
    this.preferencesService.flush();
    PlaySound.getInstance().unloadSound();
    HiLog.i(TAG, 'onBackground after unloadSound .');
    AppStorage.setOrCreate<boolean>('isMainForeground', false);
    this.mAction.background(false);
    this.isUltraSnapshotCapture = false;
    if (state.get<boolean>('uiReducer', 'isImmersive')) {
      this.mAction.isEnterImmersive(false);
    }
    if (WindowService.getInstance().getWindowKeepScreenOn() && AppStorage.get('enableScreenReader')) {
      WindowService.getInstance().setWindowKeepScreenOn(false);
    }
    if (<boolean> this.preferencesService.getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) ||
      <boolean> this.preferencesService.getPropValue(PersistType.FOREVER, PropTag.IS_SEMI_COLLAPSED_GUIDE_LOAD, false)) {
      if (this.launchParam.launchReason === AbilityConstant.LaunchReason.CALL) {
        // byCall后台拉起方式进后台无需close
        return;
      }
      this.mAction.close();
    }
    if (state.get<boolean>('securityCameraReducer', 'thumbnailReminderShow')) {
      this.mAction.showThumbnailReminder(false);
    }
    if (state.get<boolean>('securityCameraReducer', 'appLockReminderShow')) {
      this.mAction.showAppLockReminder(false);
    }
    this.setShowOnLockScreen(false);
    if (this.isRemoteCapture) {
      this.quitRemoteCapture();
    }
    CollaborateControlService.getInstance().unSubscribeHolderState();
    this.isOnCreateLoaded = false;
    HiLog.end(TAG, 'onBackground');
  }

  // 遥控拍照生命周期回调，前台拉不起不走 onCreate/onNewWant 只会走这里
  // @ts-ignore
  onCollaborate(wantParam: Record<string, Object>): AbilityConstant.OnCollaborateResult {
    HiLog.i(TAG, `onCollaborate foreground ${this.isForeground}`);
    if (!wantParam[`ohos.extra.param.key.supportCollaborateIndex`]) {
      HiLog.e(TAG, 'onCollaborate param error')
      return 1;
    }
    if (!power.isActive()) {
      power.wakeup('camera wakeup');
      HiLog.i(TAG, 'power wakeup');
    }
    const param = wantParam[`ohos.extra.param.key.supportCollaborateIndex`] as Record<string, object>;
    if (!CollaborateControlService.getInstance().checkIntroLoaded() ||
      !CollaborateControlService.getInstance().checkGuidanceLoaded()) {
      // 未同意隐私协议和引导页面，走协同通道返回错误码
      HiLog.i(TAG, 'user not agree')
      return CollaborateControlService.getInstance().onCollaborate(param, this.context);
    }
    if (!this.isForeground) {
      // 冷启或后台拉起，切后置拍照模式，拉起主页面
      AppStorage.SetOrCreate('restoreFlag', true);
      const oldMode = getStates().get<ModeType>('modeReducer', 'mode');
      ModePosWarmStartUtil.startWithParams(oldMode, ModeType.PHOTO, camera.CameraPosition.CAMERA_POSITION_BACK);
      AppStorage.SetOrCreate('restoreFlag', false);
    }
    // 授权校验弹窗，如果要弹窗不要阻塞该生命周期
    CollaborateControlService.getInstance().resetAuthState();
    this.openDialog(param);
    // 遥控拍照正常流程
    CollaborateControlService.getInstance().setForegroundCall(this.isForeground);
    return CollaborateControlService.getInstance().onCollaborate(param, this.context);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    HiLog.begin(TAG, 'onNewWant');
    if (!want) {
      HiLog.e(TAG, 'onNewWant want is empty');
      return;
    }
    GlobalContext.get().setIsPicker(false);
    this.launchParam = launchParam;
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CALL) {
      // 遥控拍照后台拉起，相机在后台，先不走后面流程，后面授权通过会再次走onNewWant
      HiLog.i(TAG, 'onNewWant by call');
      return;
    }
    const remoteAuthorizeState = want.parameters?.remoteAuthorizeState as RemoteAuthorizeState;
    if (remoteAuthorizeState === RemoteAuthorizeState.ALWAYS) {
      try {
        this.remoteCapture.setPermissionUdid().then(() => {
          HiLog.i(TAG, 'onNewWant setPermission success');
        }).catch((err) => {
          HiLog.i(TAG, `onNewWant setPermission err = ${err}`);
        });
      } catch (err) {
        HiLog.i(TAG, `onNewWant setPermission err1 = ${err}`);
      }
    }
    const isDialogCallCamera = want.parameters?.isDialogCallCamera;
    if (isDialogCallCamera && this.isForeground) {
      // 遥控拍照授权弹窗拉起，并且已经在前台，不走后面的流程
      HiLog.i(TAG, 'onNewWant isDialogCallCamera when foreground');
      return;
    }
    this.onWantReceived(want);
    if (want.action === 'com.ohos.camera.intent.RemoteCall' && (typeof want.parameters?.uuid === 'string'
      || typeof want.parameters?.uuid === 'number')
      && typeof want.parameters?.deviceName === 'string') {
      // 遥控拍照入口
      let uuid: string = want.parameters?.uuid.toString();
      let deviceName: string = want.parameters?.deviceName.toString();
      HiLog.i(TAG, `Enter RemoteCapture`);
      this.isRemoteCapture = true;
      AppStorage.setOrCreate('isRemoteCapture', this.isRemoteCapture);
      this.setShowOnLockScreen(true);
      this.mAction.photoBrowserOnBackPress();
      CollaborateControlService.getInstance().setRemoteConnectType(CONNECT_TYPE.SPORT_REMOTE);
      this.initRemoteCapture(uuid, deviceName);
    }
    HiLog.end(TAG, 'onNewWant');
    if (getStates().get<boolean>('collapsReducer', 'needReForeground')) {
      this.onForeground();
    }
  }

  onDestroy(): void {
    HiLog.begin(TAG, 'onDestroy');
    AppLockUtil.getInstance().ForceUnregisterAppLock();
    if (getStates().get<boolean>('settingViewReducer', 'isShowSettingView')) {
      const settingData: SettingViewData = {
        isShowSettingView: false,
        isTriggeredByBack: true
      };
      this.mAction.changeFunctionValue(FunctionId.SETTING, settingData);
    }
    CommonEventManager.getInstance().publishCommonEventMg(CUSTOM_EVENTS.PREEMPTION, {
      isPicker: false, active: false
    });
    FeatureManager.getInstance().unLoadFunctions();
    this.mAction.abilityOnDestroy();
    BlurAnimateUtil.releasePixelMap();
    this.preferencesService.flush(false);
    PlaySound.getInstance().releaseSoundPool();
    this.unRegisterDataShare();
    WindowService.getInstance().unRegisterAccelerometer();
    this.unsubscribeStateChange();
    if (this.isRemoteCapture) {
      this.quitRemoteCapture();
    }
    SensorService.getInstance().unRegisterMotionRotateListener();
    WindowService.getInstance().unRegisterKeyObserverFloatingNavigation();
    AppStorage.setOrCreate('Destroyed', true);
    HiLog.end(TAG, 'onDestroy');
  }

  private unRegisterDataShare(): void {
    let uri: string = SettingsDataShareUtils.getSettingsUri(DataUriType.SETTING_GLOBAL_URI,
      SettingsDataShareUtils.ENABLE_SCREEN_READER_KEY);
    if (!uri) {
      HiLog.e(TAG, 'createDataHelper screen read uri empty!');
      return;
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    HiLog.begin(TAG, 'onWindowStageCreate');
    // PafEngine.init(windowStage, this.context, {
    //   config: {
    //     region: Region.CN
    //   },
    // })
    // want 参数处处理该值 0 为 默认显示屏
    HiLog.i(TAG, 'onWindowStageCreate windowDisplayId' + AppStorage.get('windowDisplayId'));
    this.mGlobalContext.setWindowStage(windowStage);
    if (!AppStorage.get('windowDisplayId')) {
      if(!DeviceInfo.isRk3568()){
        HiLog.i(TAG, 'onWindowStageCreate setDefaultDensityEnabled true E');
        windowStage.setDefaultDensityEnabled(true);
        AppStorage.setOrCreate('windowDisplayName', 'UNKNOWN');
        HiLog.i(TAG, 'onWindowStageCreate setDefaultDensityEnabled true X');
      }
    } else if (!AppStorage.get('isLemCollaps')) {
      const displayName: string = WindowService.getInstance().getWindowDisplayName();
      HiLog.i(TAG, `other device run windowDisplayName is ${displayName}`);
      AppStorage.setOrCreate('windowDisplayName', displayName);
      StoreManager.getInstance().postMessage(CameraAction.changeMode(getStates().get<ModeType>('modeReducer', 'mode')));
    }
    if (GlobalContext.get().getT('isSecurityCamera') || this.isVisitedByUltraSnapshot ||
    this.isRemoteCapture || this.isSelfieStick) {
      this.setShowOnLockScreen(true);
    }
    try {
      windowStage.on('windowStageEvent', this.windowStageEventCallback().bind(this));
    } catch (err) {
      HiLog.e(TAG, `windowStageOnWindowStageEvent fail ${err?.code}`);
    }
    HiLog.begin(TAG, 'setUIContent');
    // @ts-ignore
    windowStage.setUIContent(this.context, this.getUIContent(), new LocalStorage());
    HiLog.end(TAG, 'setUIContent');

    HiLog.begin(TAG, 'getMainWindowSync');
    try {
      this.mMainWindow = windowStage.getMainWindowSync();
    } catch (err) {
      HiLog.e(TAG, `getMainWindowSync fail ${err?.code}`);
    }
    HiLog.end(TAG, 'getMainWindowSync');

    HiLog.begin(TAG, 'windowServiceInit');
    const windowService: WindowService = WindowService.getInstance();
    windowService.init(this.mMainWindow);
    windowService.initAvoidArea();
    windowService.initFloatingService();
    windowService.onWindowSizeChange();
    windowService.setFullScreen();
    setTimeout(() => {
      HiLog.begin(TAG, 'DelayWindowSetting');
      try {
        windowService.registerAccelerometer();
      } catch (e) {
        HiLog.i(TAG, `register windowStageEvent error: ${JSON.stringify(e)}.`);
      }
      HiLog.end(TAG, 'DelayWindowSetting');
    }, START_DELAY_WINDOW_SETTING);
    HiLog.end(TAG, 'windowServiceInit');
    HiLog.end(TAG, 'onWindowStageCreate');
  }

  private windowStageEventCallback(): Callback<window.WindowStageEventType> {
    return (event) => {
      HiLog.i(TAG, `Camera BaseAbility onWindowStageEvent: ${JSON.stringify(event)}.`);
      AppStorage.setOrCreate('windowStageEventType', event);
      switch (event) {
        case window.WindowStageEventType.SHOWN:
          HiLog.i(TAG, 'window.WindowStageEventType.SHOWN.');
          break;
        case window.WindowStageEventType.ACTIVE:
          AppStorage.setOrCreate('cameraActive', true);
          this.mAction.changeWindowEventType(window.WindowStageEventType.ACTIVE);
          break;
        case window.WindowStageEventType.INACTIVE:
          AppStorage.setOrCreate('cameraActive', false);
          this.mAction.changeWindowEventType(window.WindowStageEventType.INACTIVE);
          break;
        case window.WindowStageEventType.HIDDEN:
          break;
        case window.WindowStageEventType.RESUMED:
          this.moreModeConfig.handleWindowResumedModeChoose();
          this.mAction.changeWindowEventType(window.WindowStageEventType.RESUMED);
          break;
        case window.WindowStageEventType.PAUSED: {
          this.mAction.changeWindowEventType(window.WindowStageEventType.PAUSED);
          break;
        }
      }
      AppStorage.setOrCreate('windowStageEventType', event);
    };
  }

  onWindowStageWillDestroy(windowStage: window.WindowStage): void {
    try {
      windowStage.off('windowStageEvent');
    } catch (error) {
      HiLog.e(TAG, `off windowStageEvent error: ${error?.code}.`);
    }
    HiLog.i(TAG, 'onWindowStageWillDestroy.');
  }

  onWindowStageDestroy(): void {
    HiLog.i(TAG, 'Camera BaseAbility onWindowStageDestroy.');
    AVPlayerService.getInstance().releaseAllAVPlayers();
  }

  getUIContent(): string {
    return 'pages/index';
  }

  onBackPressed(): boolean {
    HiLog.i(TAG, 'onBackPressed');
    return true;
  }

  private onWantReceived(want: Want): void {
    HiLog.i(TAG, 'onWantReceived begin');
    if (!want || !want.parameters) {
      HiLog.e(TAG, 'onWantReceived: want or parameters is undefined');
      return;
    }
    const parameters = want.parameters;
    HiLog.i(TAG, 'onWantReceived begin' + JSON.stringify(parameters['ohos.aafwk.param.displayId']));

    if (parameters['ohos.aafwk.param.displayId'] !== undefined) {
      AppStorage.setOrCreate('windowDisplayId', parameters['ohos.aafwk.param.displayId']);
    }
    let windowCallerName = parameters['ohos.aafwk.param.callerBundleName'];
    let SmartAnimationShow = parameters['SmartAnimationShow'];
    let smartAnimPlayFlag = false;
    AppStorage.setOrCreate('smartAnimRoundPlay', smartAnimPlayFlag);
    HiLog.i(TAG, `onWantReceived windowCallerName from ${windowCallerName} smartAnimPlayFlag ${smartAnimPlayFlag}`);

    if (want.parameters?.isRunningDT) {
      AppStorage.setOrCreate('isRunningDT', 1);
    }
    if (want.action === 'RemoteCall') {
      this.isRemoteCapture = true;
      AppStorage.setOrCreate('isRemoteCapture', this.isRemoteCapture);
      let isNeedSetPermission: boolean = want.parameters?.isNeedSetPermission as boolean;
      let uuid: string = want.parameters?.uuid.toString();
      this.setShowOnLockScreen(true);
      this.mAction.photoBrowserOnBackPress();
      CollaborateControlService.getInstance().setRemoteConnectType(CONNECT_TYPE.SMART_REMOTE);
      this.initRemoteCaptureNew(isNeedSetPermission, uuid);
    }
    if (want.parameters?.trigger_type === 'SelfieStick') {
      // 适配自拍杆拉起功能
      this.isSelfieStick = true;
      if (screenLock.isLocked()) {
        power.wakeup('');
      }
      this.setShowOnLockScreen(true);
    }
    this.ultraSnapshotHandle(want);
    this.shortCutHandle(want);
    this.securityCameraHandle(want);
    this.otherHandle(want);
    HiLog.i(TAG, 'onWantReceived end.');
  }


  private otherHandle(want: Want): void {
    HiLog.i(TAG, 'otherHandle begin');
    if (want.parameters?.startByOtherApp) {
      if (want.parameters?.mode &&
        (typeof want.parameters?.mode !== 'string' && typeof want.parameters?.mode !== 'number')) {
        HiLog.w(TAG, 'parameters mode Illegal return.');
        return;
      }
      this.isVisitedByApp = true;
      if (typeof want.parameters?.zoom === 'number' && Number(want.parameters?.zoom) > 0) {
        AppStorage.setOrCreate('wantZoomRatio', Number(want.parameters?.zoom));
      }
      HiLog.i(TAG, `appVisitMode: ${this.appVisitMode}, appVisitedPosition: ${this.appVisitPosition}`);
    } else {
      this.isVisitedByApp = false;
    }
    HiLog.i(TAG, 'otherHandle end');
  }

  private ultraSnapshotHandle(want: Want): void {
    const isForeground = getStates().get<boolean>('contextReducer', 'isForeground');
    HiLog.i(TAG, `ULTRA snapshot want Handle, isForeground: ${isForeground}.`);
    if (isForeground) {
      return;
    }
    if (want.parameters?.ultraSnapshot) {
      this.isVisitedByUltraSnapshot = true;
      this.setShowOnLockScreen(true);
      HiLog.i(TAG, 'ULTRA snapshot want Handle, wakeup start.');
      HiLog.begin(TAG, 'ULTRA wakeup');
      try {
        power.wakeup('romate_picker');
      } catch (e) {
        HiLog.e(TAG, `power wakeup error: ${simpleStringify(e)}.`);
      }
      HiLog.end(TAG, 'ULTRA wakeup');
    } else {
      this.isUltraSnapshotCapture = false;
      this.isVisitedByUltraSnapshot = false;
    }
  }

  private shortCutHandle(want: Want): void {
    if (!want.parameters?.startByShortCut || !want.parameters?.mode) {
      HiLog.i(TAG, 'is not shortCut visited return.');
      this.isVisitedByShortCut = false;
      return;
    }
    let persistPosition: camera.CameraPosition =
      <camera.CameraPosition> this.preferencesService.getPropValue(PersistType.FOR_AWHILE, PropTag.CAMERA_POSITION,
        camera.CameraPosition.CAMERA_POSITION_BACK);
    this.isVisitedByShortCut = true;
    if (typeof want.parameters?.mode !== 'string' && typeof want.parameters?.mode !== 'number') {
      HiLog.w(TAG, 'mode is not string or number return.');
      return;
    }
    const shortCutMode = want.parameters?.mode as ShortCutMode;
    this.shortCutVisitMode = ShortCutVisitService.getInstance().getShotCutVisitResult(shortCutMode).mode;
    this.shortCutVisitPosition = ShortCutVisitService.getInstance().getShotCutVisitResult(shortCutMode).cameraPosition;
    PreferencesService.getInstance()
      .putPropValue(PersistType.FOR_AWHILE, PropTag.CAMERA_POSITION, this.shortCutVisitPosition);
    PreferencesService.getInstance().putPropValue(PersistType.FOR_AWHILE, PropTag.MODE, this.shortCutVisitMode);
    HiLog.i(TAG, `shortCutVisited mode: ${this.shortCutVisitMode}, position: ${this.shortCutVisitPosition}.`);
    this.refreshCustomFilterCardStatus(persistPosition);
  }

  private refreshCustomFilterCardStatus(persistPosition: camera.CameraPosition) {
    if (this.shortCutVisitMode && this.shortCutVisitMode !== ModeType.NONE) {
      let customFilterIsOpen = getStates().get<number>('customFilterStyleReducer', 'customFilterEffectEnable');
      const styleIndex = getStates().get<number>('customFilterStyleReducer', 'styleIndex');
      if (this.shortCutVisitPosition === camera.CameraPosition.CAMERA_POSITION_FRONT && !customFilterIsOpen) {
        this.mAction.closeCustomFilterCard();
      } else {
        this.mAction.quitCustomFilterCardAndTreasureBox();
      }
      setTimeout((): void => {
      }, 200);
    }
  }

  private async restoreSecuritySettings(): Promise<void> {
    if (!screenLock.isLocked() && GlobalContext.get().getObject('isSecurityCamera')) {
      HiLog.i(TAG, 'restoreSecuritySettings E.');
      this.mAction.updateIsSecurityCamera(false);
      GlobalContext.get().setObject('isSecurityCamera', false);
      GlobalContext.get().setObject('isSecureMode', false);
      this.isVisitedByUltraSnapshot = false;
      this.setShowOnLockScreen(false);
      let isAppLock = await AppLockUtil.getInstance().isPhotoAppLocked();
      if (!isAppLock) {
        GlobalContext.get().setCameraShotKey('');
        this.mAction.setCameraShotKey('');
      }
      HiLog.i(TAG, 'restoreSecuritySettings X.');
    }
  }

  private async securityCameraHandle(want: Want): Promise<void> {
    let isSecureMode = want.parameters?.isSecureMode as boolean;
    const isFromScreenLock = want.parameters?.isFromScreenLock as boolean;
    let noParams = isSecureMode === undefined || isFromScreenLock === undefined;
    if (isSecureMode === undefined) {
      isSecureMode = await screenLock.isSecureMode();
    }
    HiLog.i(TAG, `securityCameraHandle isSecureMode: ${isSecureMode}, isFromScreenLock: ${isFromScreenLock}.`);
    GlobalContext.get().setObject('isSecureMode', isSecureMode);
    if (noParams) {
      // 未按约定传参场景,非锁屏相机场景拉起相机,也要做保护,设置了密码状态下不允许查看所有照片
      GlobalContext.get().setObject('isSecurityCamera', false);
      if (screenLock.isLocked()) {
        HiLog.i(TAG, 'securityCameraHandle is not lock Camera but screen isLocked.');
        const isSecurityCamera = isSecureMode !== undefined;
        GlobalContext.get().setObject('isSecurityCamera', isSecurityCamera);
        this.mAction.updateIsSecurityCamera(isSecurityCamera);
        if (isSecureMode) {
          this.setCameraShotKey(isSecureMode);
        } else {
          let isSecurity = await AppLockUtil.getInstance().isPhotoAppLocked();
          this.setCameraShotKey(isSecurity);
        }
      } else {
        this.setShowOnLockScreen(false);
      }
      return;
    }
    // 锁屏和主题右下角相机图标拉起锁屏相机
    HiLog.i(TAG, 'securityCameraHandle is lock Camera.');
    this.setShowOnLockScreen(true);
    GlobalContext.get().setObject('isSecurityCamera', true);
    this.mAction.updateIsSecurityCamera(true);
    if (isSecureMode) {
      this.setCameraShotKey(isSecureMode);
    } else {
      let isSecurity = await AppLockUtil.getInstance().isPhotoAppLocked();
      this.setCameraShotKey(isSecurity);
    }
    HiLog.i(TAG, 'securityCameraHandle X.');
  }

  private setCameraShotKey(isSecureMode: boolean): void {
    if (isSecureMode) {
      let timestamp: string = `${Date.now()}`;
      let cameraShotKey = `isSecurityCamera_${'0'.repeat(CAMERA_SHOT_KEY_SIZE - timestamp.length)}${timestamp}`;
      HiLog.i(TAG, `securityCameraHandle cameraShotKey ${cameraShotKey}`);
      GlobalContext.get().setCameraShotKey(cameraShotKey);
      this.mAction.setCameraShotKey(cameraShotKey);
    } else {
      GlobalContext.get().setCameraShotKey('');
      this.mAction.setCameraShotKey('');
    }
  }

  private setShowOnLockScreen(isOnScreen: boolean): void {
    try {
      let showOnScreen = isOnScreen && screenLock.isLocked();
      HiLog.i(TAG, `setShowOnLockScreen: ${isOnScreen}, showOnScreen: ${showOnScreen}`);
      GlobalContext.get().setObject('showOnScreen', showOnScreen);
      GlobalContext.get().getWindowStage()?.setShowOnLockScreen(showOnScreen);
    } catch (e) {
      HiLog.i(TAG, `setShowOnLockScreen error: ${JSON.stringify(e)}.`);
    }
  }

  private async updateThumbnail(): Promise<void> {
    MediaLibraryUiService.getInstance().getThumbnailInfo().then((thumbnailInfo: ThumbnailInfo | undefined) => {
      if (thumbnailInfo && !MediaLibraryUiService.getInstance().getIfThumbnailUsed()) {
        HiLog.i(TAG, 'Get thumbnail for cold start.');
        MediaLibraryUiService.getInstance().setThumbnailInfoForColdStart(thumbnailInfo);
      }
    }).catch((e) => {
      HiLog.e(TAG, `getThumbnail error: ${JSON.stringify(e)}.`);
    });
  }

  public getHighContrastTextState(): void {
    config.highContrastText.get((err: BusinessError, data: boolean) => {
      if (err) {
        HiLog.e(TAG, `failed to get highContrastText, Code is ${err?.code}`);
        return;
      }
      HiLog.i(TAG, `Succeeded in get highContrastText, data is ${data}`);
      this.mAction.updateHighContrastState(data);
    });
  }

  private subscribeStateChange(): void {
    HiLog.i(TAG, 'subscribe application state change');
    let applicationContext = ContextManager.getInstance().getApplicationContext();
    let action = this.mAction;
    let appStateChangeCallBack: ApplicationStateChangeCallback = {
      onApplicationForeground() {
        HiLog.i(TAG, 'onApplicationForeground');
        PhotoBrowserManager.getInstance().setViewVisibility();
        SuspendTaskUtil.getInstance().setIsInBackground(false);
        SuspendTaskUtil.getInstance().clearSavePhotoTask();
        SuspendTaskUtil.getInstance().stopDelayTask();
      },
      onApplicationBackground() {
        HiLog.i(TAG, `onApplicationBackground: ${SuspendTaskUtil.getInstance().getAlreadyCloseCamera()}`);
        PhotoBrowserManager.getInstance().setViewVisibility();
        SuspendTaskUtil.getInstance().setIsInBackground(true);
        if (SuspendTaskUtil.getInstance().isEnterOfflinePhoto()) { // 触发离线拍照的短时任务
          SuspendTaskUtil.getInstance().requestSuspendDelay(CommonConstants.SUSPEND_DELAY_OFFLINE_REASON);
          return;
        }
        if (SuspendTaskUtil.getInstance().getAlreadyCloseCamera()) {
          return;
        }
        if (SuspendTaskUtil.getInstance().getThumbnailCount() > 0) {
          SuspendTaskUtil.getInstance().requestSuspendDelay('Suspend task for saving 80 grade photo.');
        } else {
          HiLog.i(TAG, '80 grade photo saved before suspend delay task, close camera');
          action.close();
        }
      }
    }
    SuspendTaskUtil.getInstance().setIsInBackground(false);
    applicationContext.on('applicationStateChange', appStateChangeCallBack);
  }

  private unsubscribeStateChange(): void {
    HiLog.i(TAG, 'unsubscribe');
    try {
      let applicationContext = ContextManager.getInstance().getApplicationContext();
      applicationContext.off('applicationStateChange');
      SuspendTaskUtil.getInstance().clearSavePhotoTask();
    } catch (e) {
      HiLog.i(TAG, `applicationContext error: ${JSON.stringify(e)}.`);
    }
  }

  private checkWindowSize(): void {
    if (AppStorage.get('isLemCollaps') && !AppStorage.get('isPSDCollaps')) {
      return;
    }
    const windowRect = WindowService.getInstance().getWindowRect();
    if (windowRect?.width && windowRect?.height) {
      const size = pxChange(windowRect);
      if (size && (size.width !== getStates().get<number>('windowReducer', 'windowWidth') ||
        size.height !== getStates().get<number>('windowReducer', 'windowHeight'))) {
        execDispatch(WindowAction.onSizeChange(size));
      }
    }
  }
}