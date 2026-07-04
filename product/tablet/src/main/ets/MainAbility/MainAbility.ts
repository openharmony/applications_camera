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

import { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import { Dispatch, execDispatch, getDispatch, getStates } from '@ohos/common/src/main/ets/redux';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import {
  EXPIRE_MINUTE_TIME_15,
  FLUSH_TIMESTAMP,
  PersistType,
  PreferencesService
} from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { CameraProxy } from '@ohos/common/src/main/ets/camera/uithread/CameraProxy';
import { Callback } from '@kit.BasicServicesKit';
import camera from '@ohos.multimedia.camera';
import { CameraAction } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { PropTag, PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import { PlaySound } from '@ohos/common/src/main/ets/component/playsound/playSound';
import { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import type { SettingViewData } from '@ohos/common/src/main/ets/function/setting/SettingFunction';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { window } from '@kit.ArkUI';
import { SettingsDataShareUtils, DataUriType } from '@ohos/common/src/main/ets/utils/SettingsDataShareUtils';
import { screenLock } from '@kit.BasicServicesKit';
import { ApplicationStateChangeCallback, Configuration, Want } from '@kit.AbilityKit';
import UIAbility from '@ohos.app.ability.UIAbility';
import { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import { WindowAction } from '@ohos/common/src/main/ets/service/window/WindowAction';
import { ModeListManager } from '@ohos/common/src/main/ets/mode/ModeListManager';
import { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import CommonEventManager from '@ohos/common/src/main/ets/component/commonevent/CommonEventManager';
import { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import { ModeMap } from '../common/ModeMap';
import { ShortCutMode,
  ShortCutVisitService } from '@ohos/common/src/main/ets/service/shortcutvisit/ShortCutVisitService';
import config from '@ohos.accessibility.config';
import { RestoreManager } from '@ohos/common/src/main/ets/restore/RestoreManager';
import { BusinessError } from '@ohos.base';
import power from '@ohos.power';
import { MoreModeConfig } from '@ohos/common/src/main/ets/mode/MoreModeConfig';
import { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import { AudioSessionService } from '@ohos/common/src/main/ets/service/audioSessionService/AudioSessionService';
import { ThumbnailAction } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailAction';
import { AppLockUtil } from '@ohos/common/src/main/ets/utils/AppLockUtil';
import { accessibility } from '@kit.AccessibilityKit';
import { SuspendTaskUtil } from '@ohos/common/src/main/ets/utils/SuspendTaskUtil';
import { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import { ZoomOperation } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import { MemoryService } from '@ohos/common/src/main/ets/service/Memory/MemoryService';
import { ModePosWarmStartUtil } from '@ohos/common/src/main/ets/mode/ModePosWarmStartUtil';
// @ts-ignore
import { dataShare } from '@kit.ArkData';

const TAG: string = 'MainAbility';
const LIFECYCLE_SLEEP_TIME: number = 100;
const CAMERA_SHOT_KEY_SIZE = 13; // 针对拼接时间戳长度

class AbilityDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch): void {
    this.mDispatch = dispatch;
  }

  public warmStartup(): void {
    this.mDispatch(CameraAction.warmStart());
  }

  public coldStartup(position, mode): void {
    this.mDispatch(CameraAction.init(position, mode, true));
  }

  public foreground(): void {
    PlaySound.getInstance().loadSound();
    this.mDispatch(ContextAction.abilityOnForeground());
  }

  public background(isPickerBack: boolean): void {
    PlaySound.getInstance().unloadSound();
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

  public switchCamera(cameraPosition: camera.CameraPosition): void {
    this.mDispatch(CameraAction.switchCamera(cameraPosition));
  }

  public changeMode(mode: ModeType): void {
    this.mDispatch(CameraAction.changeMode(mode));
  }

  public freshUx(): void {
    this.mDispatch(WindowAction.refresh());
  }

  public closeTreasureBox(): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(false));
  }

  public changeWindowEventType(windowStageEventType: window.WindowStageEventType): void {
    this.mDispatch(ContextAction.changeWindowEventType(windowStageEventType));
  }

  public updateModeBar(): void {
    this.mDispatch(Action.updateModeBar());
  }

  public refreshThumbnail(isRefreshDefaultThumbnail: boolean): void {
    this.mDispatch(ThumbnailAction.refresh(isRefreshDefaultThumbnail));
  }
}

export default class MainAbility extends UIAbility {
  // 快捷列表访问
  public isVisitedByShortCut: boolean = false;
  public shortCutVisitMode: ModeType = ModeType.NONE;
  public shortCutVisitCameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;
  private mAction: AbilityDispatcher = new AbilityDispatcher();
  private isForeground: boolean = false;
  private preferencesService: PreferencesService = PreferencesService.getInstance();
  private settingDataHelper: dataShare.DataShareHelper = undefined;
  private isOnCreateLoaded: boolean = false;
  private mMainWindow: window.Window = undefined;
  private moreModeConfig: MoreModeConfig = MoreModeConfig.getInstance();
  private isSelfieStick: boolean = false; // 自拍杆拉起相机
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

  onCreate(want, launchParam): void {
    HiLog.begin(TAG, 'onCreate');
    HiLog.i(TAG, 'BaseAbility onCreate.');
    if (!want) {
      HiLog.e(TAG, 'onCreate want is empty');
      return;
    }
    AppLockUtil.getInstance().registerAppLock(this.AppLockCallback);
    let fontSizeScale = this.context.config.fontSizeScale;

    if (fontSizeScale) {
      AppStorage.setOrCreate('fontSizeScale', fontSizeScale);
      HiLog.i(TAG, `onCreate fontSizeScale = ${fontSizeScale}`);
    }
    ContextManager.getInstance().setAbilityContext(this.context);
    GlobalContext.get().setObject('permissionFlag', false);
    this.mAction.setDispatch(getDispatch());
    let position: camera.CameraPosition = <camera.CameraPosition> this.preferencesService.getPropValue(
      PersistType.FOR_AWHILE, PropTag.CAMERA_POSITION, camera.CameraPosition.CAMERA_POSITION_BACK);
    let mode: ModeType = this.getModeByPosition(position); // 冷启动15min内外，镜头模式处理
    if (mode !== undefined && position !== undefined) {
    } else {
      HiLog.i(TAG, 'preCreateCamera invalid mode: ' + mode + ', position: ' + position)
    };
    if (!!want.parameters?.callBundleName && want.parameters['ohos.aafwk.param.callerToken']) {
      PickerUiService.getInstance().addPickerVisitLog();
    }
    this.onWantReceived(want, true);
    this.securityCameraHandle(want);
    if (this.isVisitedByShortCut) {
      position = this.shortCutVisitCameraPosition;
      mode = this.shortCutVisitMode;
    }
    if (this.isIntentVisit) {
      position = this.intentPosition;
      mode = this.intentMode;
    }
    if (mode !== ModeType.VIDEO) {
      CameraAppCapability.getInstance().queryCapability(position, ModeType.VIDEO);
    }
    CameraAppCapability.getInstance().queryCapability(position, mode);
    FeatureManager.getInstance().init(mode, new ModeMap());
    AppStorage.setOrCreate('startOrUserChangeToModeLast', [ModeType.NONE, mode]);
    if (<boolean> this.preferencesService.getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false)) {
      this.mAction.coldStartup(position, mode);
    }
    PlaySound.getInstance().init(); // 创建音频实例，创建音频池
    DisplayService.getInstance().init();

    this.moreModeConfig.mixPersistAndDefaultModeList();
    const modeList = this.moreModeConfig.processGlobalModeListAndName(mode);
    ModeListManager.getInstance().init(modeList);
    this.moreModeConfig.processBackAsFrontModeData(false, false);

    GlobalContext.get().setIsPicker(false);
    AppStorage.setOrCreate('settingAnimationDoing', false);
    AppStorage.setOrCreate('lastDirection', WindowDirection.TOP);
    this.registerDataShare();
    RestoreManager.getInstance().addProcessChangeListener();
    this.isOnCreateLoaded = true;
    this.subscribeStateChange();
    HiLog.end(TAG, 'onCreate');
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
      this.settingDataHelper = dataHelper;
      SettingsDataShareUtils.registerDataChange(dataHelper, uri, () => this.queryEnableScreenReader());
    });
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    let fontSizeScale = newConfig.fontSizeScale;
    if (fontSizeScale) {
      AppStorage.setOrCreate('fontSizeScale', fontSizeScale);
      HiLog.i(TAG, `onConfigurationUpdate fontSizeScale = ${fontSizeScale}`);
    }
    if (newConfig.language) {
      HiLog.i(TAG, `systemLanguage change to ${newConfig.language}`);
      AppStorage.setOrCreate('systemLanguage', newConfig.language);
    }
  }

  /**
   * 冷启动 或者 热启动会走该流程 快捷访问方式处理参数入口
   * @param want 参数载体
   * @param isColdStart 冷热启动标识
   */
  public onWantReceived(want: Want, isColdStart: boolean): void {
    HiLog.i(TAG, `onWantReceived isColdStart:${isColdStart}`);
    if (want.parameters?.trigger_type === 'SelfieStick') {
      // 适配自拍杆拉起功能
      this.isSelfieStick = true;
      if (screenLock.isLocked()) {
        power.wakeup('');
        this.setShowOnLockScreen(true);
      }
    }
    this.InsightintentsHandle(want);
    if (!want.parameters?.startByShortCut || !want.parameters?.mode) {
      HiLog.i(TAG, 'is not shortCut visited return.');
      this.isVisitedByShortCut = false;
      return;
    }
    this.isVisitedByShortCut = true;
    let shortCutMode = want.parameters.mode as ShortCutMode;
    this.shortCutVisitMode = ShortCutVisitService.getInstance().getShotCutVisitResult(shortCutMode).mode;
    this.shortCutVisitCameraPosition = ShortCutVisitService.getInstance()
      .getShotCutVisitResult(shortCutMode).cameraPosition;
    PreferencesService.getInstance()
      .putPropValue(PersistType.FOR_AWHILE, PropTag.CAMERA_POSITION, this.shortCutVisitCameraPosition);
    PreferencesService.getInstance().putPropValue(PersistType.FOR_AWHILE, PropTag.MODE, this.shortCutVisitMode);
    HiLog.i(TAG, `shortCutVisited. mode:${this.shortCutVisitMode} :position:${this.shortCutVisitCameraPosition}.`);
    HiLog.i(TAG, 'onWantReceived X.');
  }

  private InsightintentsHandle(want: Want): void {
    HiLog.i(TAG, 'InsightintentsHandle begin');
    const parameters = want?.parameters;
    if (parameters?.['ohos.insightIntent.executeParam.name']) {
      this.isIntentVisit = true;
      const intentName: string =parameters['ohos.insightIntent.executeParam.name'] as string;
      const param = parameters['ohos.insightIntent.executeParam.param'];
    } else {
      this.isIntentVisit = false;
    }
    HiLog.i(TAG, 'InsightintentsHandle end');
  }

  getModeByPosition(position: camera.CameraPosition): ModeType {
    let mode: ModeType = ModeType.NONE;
    if (position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      const defaultValue: string = ModeType.PHOTO;
      mode = <ModeType> this.preferencesService.getPropValue(PersistType.FOR_AWHILE, PropTag.MODE, defaultValue);
    } else {
      mode = <ModeType> this.preferencesService.getPropValue(PersistType.FOR_AWHILE, PropTag.MODE, ModeType.PHOTO);
    }
    return mode;
  }

  // 热启动的起流过程
  public foreGroundToWarmStart(): void {
    const state = getStates();
    let isIntroLoad: boolean =
      <boolean> this.preferencesService.getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false);
    if (!isIntroLoad || state.get<boolean>('cameraReducer', 'isColdStart')) {
      HiLog.w(TAG, `Interrupt Warm start,${!isIntroLoad},${state.get<boolean>('cameraReducer', 'isColdStart')}`);
      return;
    }
    const position = <camera.CameraPosition> this.preferencesService.getPropValue(PersistType.FOR_AWHILE,
      PropTag.CAMERA_POSITION, camera.CameraPosition.CAMERA_POSITION_BACK);
    let curMode: ModeType = this.getModeByPosition(position);
    const isOverDefaultTime = this.preferencesService.isExpire(EXPIRE_MINUTE_TIME_15, FLUSH_TIMESTAMP);
    HiLog.i(TAG, `onForeground mode:${curMode}, state mode:${state.get<ModeType>('modeReducer', 'mode')}, overTime:${isOverDefaultTime}`);
    if (this.isVisitedByShortCut) {
      HiLog.i(TAG, 'shortCut warmStart');
      AppStorage.setOrCreate('isVisitedByShortCut', true); // PreviewArea组件中同步XCOMPONENT的宽高
      ModePosWarmStartUtil
        .startWithParams(state.get<ModeType>('modeReducer', 'mode'), this.shortCutVisitMode,
          this.shortCutVisitCameraPosition);
    } else if (this.isIntentVisit) {
      HiLog.i(TAG, 'intentVisit warmStart');
      ModePosWarmStartUtil.startWithParams(state.get<ModeType>('modeReducer', 'mode'), this.intentMode,
        this.intentPosition);
    } else if (isOverDefaultTime && state.get<ModeType>('modeReducer', 'mode') !== curMode) {
      HiLog.i(TAG, 'warmStartWithModeAPos Entry.');
      ModePosWarmStartUtil.startWithParams(state.get<ModeType>('modeReducer', 'mode'), curMode, position);
    } else if (curMode !== state.get<ModeType>('modeReducer', 'mode') &&
    ModeListManager.getInstance().getModeList().includes(curMode)) {
      HiLog.i(TAG, 'warmStartWithModeAPos special case.');
      ModePosWarmStartUtil.startWithParams(state.get<ModeType>('modeReducer', 'mode'), curMode);
    } else if (curMode === state.get<ModeType>('modeReducer', 'mode')) {
      HiLog.i(TAG, 'normal warmStart');
      this.mAction.warmStartup();
    } else { // cold start流程没走完，就秒退秒起
      HiLog.i(TAG, 'code start is not ended but new foreground triggered.');
    }
  }

  onForeground(): void {
    this.powerOffTerminate();
    this.restoreSecuritySettings();
    GlobalContext.get().setObject('isPhotoOn', false);
    this.isForeground = true;
    HiLog.begin(TAG, 'onForeground');
    CommonEventManager.getInstance().createSubscriber();
    GlobalContext.get().setIsPicker(false);
    const isShowPrivacyPolicyView: boolean = AppStorage.get('isShowPrivacyPolicyView');
    WindowService.getInstance().setSpecificSystemNavigationEnabled(true, true, isShowPrivacyPolicyView ||
    getStates().get<boolean>('settingViewReducer', 'isShowSettingView'));
    AppStorage.setOrCreate<boolean>('isBackground', false);
    AppStorage.setOrCreate('enterCameraTime', Date.now());
    this.securityHandler();
    this.foreGroundToWarmStart();
    if (!getStates().get<boolean>('cameraReducer', 'isColdStart')) {
      const modes = this.moreModeConfig.processGlobalModeListAndName(getStates().get<ModeType>('modeReducer', 'mode'));
      ModeListManager.getInstance().init(modes);
      this.mAction.updateModeBar(); // 更多页退出、热启动，modeBar上的模式数据需要更新
    }
    this.moreModeConfig.processBackAsFrontModeData(false, false);
    AppStorage.setOrCreate<boolean>('isMainForeground', true);
    this.mAction.foreground();
    AppStorage.setOrCreate('settingAnimationDoing', false);
    this.getHighContrastTextState();

    let isOpenTouchGuide: boolean = accessibility.isOpenTouchGuideSync(); // 无障碍 浏览模式
    GlobalContext.get().setOpenTouchGuide(isOpenTouchGuide);
    AppStorage.setOrCreate('isOpenTouchGuide', isOpenTouchGuide);
    HiLog.i(TAG, `onForeground isOpenTouchGuide is ${isOpenTouchGuide}`);

    if (!this.isOnCreateLoaded) {
      const windowService: WindowService = WindowService.getInstance();
      windowService.reSetWin(this.mMainWindow);
    }
    MemoryService.getInstance().updateApplicationStorageSpace();
    HiLog.end(TAG, 'onForeground');
  }

  private async securityHandler(): Promise<void> {
    HiLog.i(TAG, `securityHandler begin`);
    let isAppLock = await AppLockUtil.getInstance().isPhotoAppLocked();
    HiLog.i(TAG, `isAppLock is ${isAppLock}`);
    if (GlobalContext.get().getObject('isSecurityCamera') || this.isSelfieStick) {
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
    if (GlobalContext.get().getT('isSecurityCamera') && !isActive) {
      ContextManager.getInstance().getUiContext().terminateSelf().then(() => {
        HiLog.i(TAG, 'terminateSelf success');
      });
      return;
    }
  }

  onBackground(): void {
    this.isForeground = false;
    this.isVisitedByShortCut = false;
    this.isIntentVisit = false;
    HiLog.begin(TAG, 'onBackground');
    AudioSessionService.deactivateAudioSession();
    this.mAction.refreshThumbnail(true);
    const state = getStates();
    CommonEventManager.getInstance().unsubscribe();
    AppStorage.setOrCreate<boolean>('isBackground', true);
    let isShowPrivacyPolicyView: boolean = GlobalContext.get().getObject('privacyPolicyViewShow') as boolean;
    if (getStates().get<boolean>('settingViewReducer', 'isShowSettingView') && !isShowPrivacyPolicyView) {
      const settingData: SettingViewData = {
        isShowSettingView: false,
        isTriggeredByBack: true
      };
      this.mAction.changeFunctionValue(FunctionId.SETTING, settingData);
    }
    this.preferencesService.flush();
    AppStorage.setOrCreate<boolean>('isMainForeground', false);
    this.mAction.background(false);
    if (state.get<boolean>('uiReducer', 'isImmersive')) {
      this.mAction.isEnterImmersive(false);
    }
    if (<boolean> this.preferencesService.getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false)) {
      this.mAction.close();
    }
    if (state.get<boolean>('securityCameraReducer', 'thumbnailReminderShow')) {
      this.mAction.showThumbnailReminder(false);
    }
    if (state.get<boolean>('securityCameraReducer', 'appLockReminderShow')) {
      this.mAction.showAppLockReminder(false);
    }
    if (!screenLock.isLocked()) {
      this.setShowOnLockScreen(false);
    }
    this.isOnCreateLoaded = false;
    HiLog.end(TAG, 'onBackground.');
  }

  onNewWant(want): void {
    HiLog.begin(TAG, 'onNewWant');
    this.securityCameraHandle(want);
    this.onWantReceived(want, false);
    //防止组件在反注册callback的时候受到此处更新ispicker的干扰
    setTimeout((): void => {
      GlobalContext.get().setIsPicker(false);
    }, LIFECYCLE_SLEEP_TIME);
    ContextManager.getInstance().setAbilityContext(this.context);
    HiLog.end(TAG, 'onNewWant');
  }

  onDestroy(): void {
    HiLog.begin(TAG, 'onDestroy.');
    AppLockUtil.getInstance().ForceUnregisterAppLock();
    this.preferencesService.flush(false);
    PlaySound.getInstance().releaseSoundPool();
    FeatureManager.getInstance().unLoadFunctions();
    this.mAction.abilityOnDestroy();
    WindowService.getInstance().unRegisterAccelerometer();
    this.unsubscribeStateChange();
    WindowService.getInstance().unRegisterKeyObserverFloatingNavigation();
    this.unRegisterDataShare();
    HiLog.end(TAG, 'onDestroy.');
  }

  private unRegisterDataShare(): void {
    if (!this.settingDataHelper) {
      HiLog.e(TAG, 'unRegisterAccelerometer screen read dataHelper is undefined');
      return;
    }
    let uri: string = SettingsDataShareUtils.getSettingsUri(DataUriType.SETTING_GLOBAL_URI,
      SettingsDataShareUtils.ENABLE_SCREEN_READER_KEY);
    if (!uri) {
      HiLog.e(TAG, 'createDataHelper screen read uri empty!');
      return;
    }
    SettingsDataShareUtils.unRegisterDataChange(this.settingDataHelper, uri);
  }

  async onWindowStageCreate(windowStage): Promise<void> {
    HiLog.begin(TAG, 'onWindowStageCreate.');
    try {
      windowStage.setDefaultDensityEnabled(true);
    } catch (e) {
      HiLog.e(TAG, `windowStage setDefaultDensityEnabled: ${e.code}`)
    }
    GlobalContext.get().setWindowStage(windowStage);
    if (GlobalContext.get().getT('isSecurityCamera') || this.isSelfieStick) {
      this.setShowOnLockScreen(true);
    }
    try {
      windowStage.on('windowStageEvent', this.windowStageEventCallback().bind(this));
    } catch (err) {
      HiLog.e(TAG, `windowStageOnWindowStageEvent fail ${err?.code}`);
    }
    windowStage.setUIContent(this.context, this.getUIContent(), new LocalStorage());
    try {
      this.mMainWindow = windowStage.getMainWindowSync();
      const windowService: WindowService = WindowService.getInstance();
      windowService.init(this.mMainWindow);
      windowService.setFullScreen();
      windowService.onWindowSizeChange();
      windowService.registerAccelerometer();
      this.mMainWindow.setWindowBackgroundColor('#000000');
    } catch (err) {
      HiLog.e(TAG, 'setWindowBackgroundColor err.');
    }
    HiLog.end(TAG, 'onWindowStageCreate.');
  }

  private windowStageEventCallback(): Callback<window.WindowStageEventType> {
    return (event) => {
      HiLog.i(TAG, `windowStageEvent, window WindowStageEventType: ${event}.`);
      AppStorage.setOrCreate('windowStageEventType', event);
      switch (event) {
        case window.WindowStageEventType.SHOWN:
          break;
        case window.WindowStageEventType.ACTIVE:
          this.mAction.changeWindowEventType(window.WindowStageEventType.ACTIVE);
          break;
        case window.WindowStageEventType.INACTIVE:
          this.mAction.changeWindowEventType(window.WindowStageEventType.INACTIVE);
          break;
        case window.WindowStageEventType.HIDDEN:
          break;
        case window.WindowStageEventType.RESUMED:
          this.moreModeConfig.handleWindowResumedModeChoose();
          this.mAction.closeTreasureBox();
          break;
        case window.WindowStageEventType.PAUSED:
          break;
        default:
          return;
      }
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

  getUIContent(): string {
    return 'pages/index'; //tablet后续支持注意入口页面，没用的删除！！！！如indexLand的一套东西！
  }

  private async queryEnableScreenReader(): Promise<void> {
    HiLog.i(TAG, 'queryEnableScreenReader');
    let enableScreenReader: boolean = await SettingsDataShareUtils.getBoolValue(DataUriType.SETTING_GLOBAL_URI,
      SettingsDataShareUtils.ENABLE_SCREEN_READER_KEY, false);
    GlobalContext.get().setScreenReaderEnabled(enableScreenReader);
    AppStorage.setOrCreate('enableScreenReader', enableScreenReader);
    HiLog.i(TAG, 'queryEnableScreenReader' + enableScreenReader);
  }

  private async restoreSecuritySettings(): Promise<void> {
    if (!screenLock.isLocked() && GlobalContext.get().getObject('isSecurityCamera')) {
      HiLog.i(TAG, 'restoreSecuritySettings E.');
      this.mAction.updateIsSecurityCamera(false);
      GlobalContext.get().setObject('isSecurityCamera', false);
      GlobalContext.get().setObject('isSecureMode', false);
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
      // 未按约定传参场景，非锁屏相机场景拉起相机,也要做保护，设置了密码状态下不允许查看所有照片
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

  public getHighContrastTextState(): void {
    config.highContrastText.get((err: BusinessError, data: boolean) => {
      if (err) {
        HiLog.e(TAG, `failed to get highContrastText, Code is ${err?.code}`);
        return;
      }
      HiLog.i(TAG, `Succeeded in get highContrastText, data is ${data}`);
      execDispatch(ContextAction.updateHighContrastState(data));
    });
  }


  private subscribeStateChange(): void {
    HiLog.i(TAG, 'subscribe application state change');
    let applicationContext = ContextManager.getInstance().getApplicationContext();
    let action = this.mAction;
    let appStateChangeCallBack: ApplicationStateChangeCallback = {
      onApplicationForeground() {
        HiLog.i(TAG, 'onApplicationForeground');
        SuspendTaskUtil.getInstance().setIsInBackground(false);
        SuspendTaskUtil.getInstance().clearSavePhotoTask();
        SuspendTaskUtil.getInstance().stopDelayTask();
      },
      onApplicationBackground() {
        HiLog.i(TAG, 'onApplicationBackground   ' + SuspendTaskUtil.getInstance().getAlreadyCloseCamera());
        SuspendTaskUtil.getInstance().setIsInBackground(true);
        if (SuspendTaskUtil.getInstance().getAlreadyCloseCamera()) {
          return;
        }
        const recordingState = getStates().get<RecordingState>('recordReducer', 'recordingState');
        HiLog.i(TAG, `onApplicationBackground ${recordingState}`);
        if (recordingState === RecordingState.STOPPING) {
          SuspendTaskUtil.getInstance().requestSuspendDelay('Suspend task for stop record and save video');
        } else {
          HiLog.i(TAG, 'video state is normal, no need to delay close');
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
    } catch (err) {
      HiLog.e(TAG, `applicationContext off applicationStateChange error: ${err?.code}.`);
    }
  }
}