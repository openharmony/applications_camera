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

import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import wantConstant from '@ohos.ability.wantConstant';
import lazy { Action, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { CameraAction } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import lazy { reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { ModeListManager } from '@ohos/common/src/main/ets/mode/ModeListManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import type Want from '@ohos.app.ability.Want';
import type { OhCombinedState, Dispatch } from '@ohos/common/src/main/ets/redux';
import power from '@ohos.power';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { PlaySound } from '@ohos/common/src/main/ets/component/playsound/playSound';
import type { SettingViewData } from '@ohos/common/src/main/ets/function/setting/SettingFunction';
import CommonEventManager from '@ohos/common/src/main/ets/component/commonevent/CommonEventManager';
import camera from '@ohos.multimedia.camera';
import lazy {
  PersistType,
  PreferencesService
} from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { PropTag, PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { ModeMap } from '../../../../../phone/src/main/ets/common/ModeMap';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import lazy { Callback } from '@ohos.base';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { SettingsDataShareUtils, DataUriType } from '@ohos/common/src/main/ets/utils/SettingsDataShareUtils';
import lazy { Configuration, ConfigurationConstant } from '@kit.AbilityKit';
import config from '@ohos.accessibility.config';
import lazy { BusinessError } from '@ohos.base';
import lazy { AudioSessionService } from '@ohos/common/src/main/ets/service/audioSessionService/AudioSessionService';
import lazy { accessibility } from '@kit.AccessibilityKit';
import lazy { CameraProxy } from '@ohos/common/src/main/ets/camera/uithread/CameraProxy';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { PickerInfo } from '@ohos/common/src/main/ets/utils/types';
import screenLock from '@ohos.screenLock';
import lazy { osAccount } from '@kit.BasicServicesKit';
import lazy { dataShare } from '@kit.ArkData';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';

const TIMEOUT_INIT_CAMERA: number = 200;
const USER_ID: number = 100;
const TAG: string = 'PickerAbility';

class PickerAbilityDispatcher {
  private mDispatch: Dispatch = null;

  constructor(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  foreground(): void {
    this.mDispatch(ContextAction.abilityOnForeground());
  }

  initCamera(position, mode): void {
    this.mDispatch(CameraAction.init(position, mode, true));
  }

  background(isPickerBack: boolean): void {
    this.mDispatch(ContextAction.abilityOnBackground(isPickerBack));
  }

  public abilityOnDestroy(): void {
    this.mDispatch(ContextAction.abilityOnDestroy());
  }

  updateCollaborationPhotoInfo(): void {
    this.mDispatch(Action.updateCollaborationPhotoInfo());
  }

  changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public changeWindowEventType(windowStageEventType: window.WindowStageEventType): void {
    this.mDispatch(ContextAction.changeWindowEventType(windowStageEventType));
  }

  public updateShowPickerView(showPicker: boolean): void {
    this.mDispatch(Action.updateShowPickerView(showPicker));
  }

  public enableUi(): void {
    this.mDispatch(Action.uiStateWithMode(true, UiStateMode.EXCLUDE_PREVIEW));
  }

  public thirdPartyCall(isThirdPartyCall: boolean, action: string): void {
    this.mDispatch(Action.thirdPartyCall(isThirdPartyCall, action));
  }

  public close(): void {
    this.mDispatch(CameraAction.release(false));
  }

  public updateHighContrastState(isHighContrast: boolean): void {
    this.mDispatch(ContextAction.updateHighContrastState(isHighContrast));
  }
}

export default class PickerAbility extends UIAbility {
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mAction: PickerAbilityDispatcher = null;
  private isShowSettingView: boolean = false;
  private mModeList: ModeType[] = [ModeType.PHOTO];
  private mGlobalContext: GlobalContext = GlobalContext.get();
  private isForeground: boolean = false;
  private settingDataHelper: dataShare.DataShareHelper = undefined;

  onCreate(want: Want, launchParam): void {
    HiLog.begin(TAG, 'onCreateInfo');
    if (!want) {
      HiLog.e(TAG, 'onCreate want is empty');
      return;
    }
    this.mGlobalContext.setCameraAbilityWant(this.launchWant);
    this.onConfigurationUpdate(this.context.config);
    this.mGlobalContext.setIsPicker(true);
    AppStorage.setOrCreate<boolean>('isBackground', false);
    GlobalContext.get().setObject('pickerInfo', PickerUiService.getInstance().getPickerInfo(want));
    ContextManager.getInstance().setAbilityContext(this.context);
    GlobalContext.get().setObject('permissionFlag', false);
    this.connectStore();
    const position = this.getPosition(want);
    const mode: ModeType = this.getStartMode();
    CameraAppCapability.getInstance().queryCapability(position, mode);
    AppStorage.setOrCreate('startOrUserChangeToModeLast', [ModeType.NONE, mode]);
    FeatureManager.getInstance().init(mode, new ModeMap());
    this.startCamera(position, mode);
    PlaySound.getInstance().init(); // 创建音频实例
    PlaySound.getInstance().createSoundPool(); // 创建音频池
    DisplayService.getInstance().init();
    this.mGlobalContext.setCameraAbilityWant(this.launchWant);
    PickerUiService.getInstance().dealPicker(want);
    PickerUiService.getInstance().addPickerVisitLog();
    this.mAction.thirdPartyCall(true, want.action);
    ModeListManager.getInstance().init(this.mModeList); // 初始化picker的模式序列
    AppStorage.setOrCreate('settingAnimationDoing', false);
    AppStorage.setOrCreate('lastDirection', WindowDirection.TOP);
    DisplayService.getInstance().init();
    this.registerDataShare();
    let applicationContext = ContextManager.getInstance().getApplicationContext();
    applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    HiLog.end(TAG, 'onCreateInfo');
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
    const fontSizeScale = newConfig.fontSizeScale;
    if (fontSizeScale) {
      AppStorage.setOrCreate('fontSizeScale', fontSizeScale);
      HiLog.i(TAG, `onConfigurationUpdate fontSizeScale = ${fontSizeScale}`);
    }
    if (newConfig.language) {
      HiLog.i(TAG, `systemLanguage change to ${newConfig.language}`);
      AppStorage.setOrCreate('systemLanguage', newConfig.language);
    }
  }

  connectStore(): void {
    HiLog.i(TAG, 'connectStore E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState): void => {
      this.isShowSettingView = state.get<boolean>('settingViewReducer', 'isShowSettingView');
    }, (dispatch: Dispatch): void => {
      this.mAction = new PickerAbilityDispatcher(dispatch);
    });
    HiLog.i(TAG, 'connectStore X.');
  }

  getStartMode(): ModeType {
    HiLog.i(TAG, 'getStartMode X.');
    const want: Want = this.launchWant;
    let mode: ModeType = ModeType.PHOTO;
    let modeList: ModeType[] = [ModeType.PHOTO];
    if (want?.action === wantConstant.Action.ACTION_IMAGE_CAPTURE) {
      let isPhotoPicker: boolean = false;
      if (want?.parameters?.supportMultiMode) {
        isPhotoPicker = <boolean> want?.parameters?.supportMultiMode;
      }
      if (isPhotoPicker) {
        modeList = [ModeType.PHOTO, ModeType.VIDEO];
      }
    } else if (want?.action === wantConstant.Action.ACTION_VIDEO_CAPTURE) {
      mode = ModeType.VIDEO;
      modeList = [ModeType.VIDEO];
    }
    const isPickerSupportedPortrait: boolean = CameraAppCapability.getInstance().getIsPickerSupportedPortrait();
    HiLog.i(TAG, `isPickerSupportedPortrait: ${isPickerSupportedPortrait}`);
    if ((DeviceInfo.isTablet())) {
      modeList.shift();
    }
    HiLog.i(TAG, `initCachePrefer initModeListAndName: ${JSON.stringify(modeList)}.`);
    this.mModeList = modeList;
    HiLog.i(TAG, `getStartMode mode is ${mode}`);
    return mode;
  }

  private getPosition(want: Want): camera.CameraPosition {
    let position: camera.CameraPosition = <camera.CameraPosition> PreferencesService.getInstance()
      .getPropValue(PersistType.FOR_AWHILE, PropTag.CAMERA_POSITION, camera.CameraPosition.CAMERA_POSITION_BACK);
    const isPicker = GlobalContext.get().getIsPicker();
    if (isPicker) {
      if (want?.parameters?.cameraPosition) {
        position = want.parameters?.cameraPosition as camera.CameraPosition;
      } else {
        position = camera.CameraPosition.CAMERA_POSITION_BACK;
      }
    }
    return position;
  }

  startCamera(position, mode): void {
    HiLog.i(TAG, `getStartMode mode is ${mode}`);
    this.mAction.initCamera(position, mode);
  }

  onDestroy(): void {
    HiLog.begin(TAG, 'onDestroy');
    try {
      PickerUiService.getInstance().stopUsingPermission(GlobalContext.get().getObject('pickerInfo') as PickerInfo);
    } catch (err) {
      HiLog.e(TAG, `stopUsingPermission fail ${err?.code}`);
    }
    PickerUiService.getInstance().resetURIContent();
    CameraProxy.getInstance().resetVideoFileManagerUri();
    PreferencesService.getInstance().flush();
    if (!AppStorage.get('cameraActive')) {
      PlaySound.getInstance().releaseSoundPool();
    }
    WindowService.getInstance().unRegisterAccelerometer();
    WindowService.getInstance().unRegisterPcModeStatus();
    this.mAction.abilityOnDestroy();
    this.unRegisterDataShare();
    this.mSubscriber.destroy();
    HiLog.end(TAG, 'onDestroy');
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
    HiLog.begin(TAG, 'onWindowStageCreate');
    if(!DeviceInfo.isRk3568()){
      try {
        windowStage.setDefaultDensityEnabled(true);
      } catch (e) {
        HiLog.e(TAG, `windowStage setDefaultDensityEnabled: ${e.code}`)
      }
    }
    GlobalContext.get().setWindowStage(windowStage);
    this.windowStageCreate(windowStage);
    try {
      windowStage.on('windowStageEvent', this.windowStageEventCallback().bind(this));
    } catch (err) {
      HiLog.e(TAG, `windowStageOnWindowStageEvent fail ${err?.code}`);
    }
    windowStage.setUIContent(this.context, this.getUIContent(), null);
    try {
      const mainWindow = windowStage.getMainWindowSync();
      const windowService: WindowService = WindowService.getInstance();
      windowService.init(mainWindow);
      windowService.setFullScreen();
      windowService.initAvoidArea();
      windowService.onWindowSizeChange();
      windowService.initFloatingService();
      windowService.registerAccelerometer();
      mainWindow.setWindowBackgroundColor('#000000');
    } catch (err) {
      HiLog.e(TAG, `setWindowBackgroundColor or setFullScreen error: ${JSON.stringify(err)}.`);
    }
    HiLog.end(TAG, 'onWindowStageCreate');
  }

  private windowStageEventCallback(): Callback<window.WindowStageEventType> {
    return (event) => {
      HiLog.i(TAG, `Camera BaseAbility onWindowStageEvent: ${JSON.stringify(event)}.`);
      switch (event) {
        case window.WindowStageEventType.SHOWN:
          break;
        case window.WindowStageEventType.ACTIVE:
          this.mAction.changeWindowEventType(window.WindowStageEventType.ACTIVE);
          break;
        case window.WindowStageEventType.INACTIVE: //The window stage loses focus.
          this.mAction.changeWindowEventType(window.WindowStageEventType.INACTIVE);
          break;
        case window.WindowStageEventType.HIDDEN:
          break;
        case window.WindowStageEventType.RESUMED:
          this.mAction.changeWindowEventType(window.WindowStageEventType.RESUMED);
          break;
        case window.WindowStageEventType.PAUSED: {
          HiLog.i(TAG, 'window.WindowStageEventType.PAUSED.');
          this.mAction.changeWindowEventType(window.WindowStageEventType.PAUSED);
          break;
        }
      }
      AppStorage.setOrCreate('windowStageEventType', event);
    };
  }

  onWindowStageWillDestroy(windowStage: window.WindowStage): void {
    try {
      this.setShowOnLockScreen(windowStage, false);
      windowStage.off('windowStageEvent');
    } catch (error) {
      HiLog.e(TAG, `off windowStageEvent error: ${error?.code}.`);
    }
    HiLog.i(TAG, 'onWindowStageWillDestroy.');
  }

  onWindowStageDestroy(): void {
    HiLog.i(TAG, 'Camera BaseAbility onWindowStageDestroy.');
  }

  windowStageCreate(windowStage: window.WindowStage): void {
    this.setShowOnLockScreen(windowStage, true);
    this.mGlobalContext.apply('resetZoomRatio');
    if (this.mGlobalContext.getCameraAbilityWant()?.parameters?.callFlag !== 'remote') {
      return;
    }
    windowStage.setShowOnLockScreen(true);
    //息屏且锁屏的场景下，跨端拍照拉起需要直接唤醒屏幕，让用户看到预览画面
    if (power.isActive()) {
      return;
    }
    //延迟200ms是为了唤醒屏幕时候已经有预览画面了，此时200是经验值，和之前延迟预览的保持一致。
    setTimeout((): void => {
      power.wakeup('romate_picker');
    }, TIMEOUT_INIT_CAMERA);
  }

  onForeground(): void {
    HiLog.begin(TAG, 'onForeground');
    PickerUiService.getInstance().registerApplicationStateObserver();
    CommonEventManager.getInstance().createSubscriber();
    if (this.isForeground) {
      return;
    }
    this.isForeground = true;
    this.mGlobalContext.setIsPicker(true);
    AppStorage.setOrCreate<boolean>('isBackground', false);
    WindowService.getInstance().setWindowBackGround(false);
    PlaySound.getInstance().loadSound();
    this.mAction.foreground();
    AppStorage.setOrCreate('pickerActive', true);
    WindowService.getInstance().setSpecificSystemNavigationEnabled(true, true, false);
    AppStorage.setOrCreate('settingAnimationDoing', false);
    this.getHighContrastTextState();
    this.queryEnableScreenReader();
    HiLog.end(TAG, 'onForeground');
  }

  onBackground(): void {
    HiLog.begin(TAG, 'onBackground');
    PickerUiService.getInstance().unRegisterApplicationStateObserver();
    try {
      PickerUiService.getInstance().stopUsingPermission(GlobalContext.get().getObject('pickerInfo') as PickerInfo);
    } catch (err) {
      HiLog.e(TAG, `stopUsingPermission fail ${err?.code}`);
    }
    if (!this.isForeground) {
      return;
    }
    AudioSessionService.deactivateAudioSession();
    this.isForeground = false;
    this.mAction.close();
    AppStorage.setOrCreate('pickerActive', false);
    CommonEventManager.getInstance().unsubscribe();
    PlaySound.getInstance().unloadSound();
    if (this.isShowSettingView && !this.mGlobalContext.getJumpToBrowser()) {
      const settingData: SettingViewData = {
        isShowSettingView: false,
        isTriggeredByBack: true
      };
      this.mAction.changeFunctionValue(FunctionId.SETTING, settingData);
    }
    this.mAction.background(true);
    this.mAction.updateShowPickerView(false);
    this.mAction.enableUi();
    this.mGlobalContext.setIsPicker(false);
    HiLog.i(TAG, `isPicker:${this.mGlobalContext.getIsPicker()}`);
    if (this.mGlobalContext.getIsPicker()) {
      AppStorage.setOrCreate<boolean>('isBackground', true);
      WindowService.getInstance().setWindowBackGround(true);
    }
    const isIntroLoaded: boolean = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean;
    if (isIntroLoaded) {
      ContextManager.getInstance().getApplicationContext()
        .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    }
    HiLog.i(TAG, 'terminateSelf start.');
    ContextManager.getInstance().getUiContext().terminateSelf((error) => {
      HiLog.e(TAG, `Operation terminateSelf : ${error?.code}.`);
    });
    HiLog.end(TAG, 'onBackground');
  }

  onNewWant(want): void {
    HiLog.begin(TAG, 'onNewWant');
    this.mGlobalContext.setCameraNewWant(want);
    this.mGlobalContext.setIsPicker(true);
    AppStorage.setOrCreate<boolean>('isBackground', false);
    WindowService.getInstance().setWindowBackGround(false);
    this.mAction.updateCollaborationPhotoInfo();
    StoreManager.getInstance().postMessage(ContextAction.abilityOnNewWant());
    HiLog.end(TAG, 'onNewWant');
  }

  getUIContent(): string {
    return 'pages/picker';
  }

  private async queryEnableScreenReader(): Promise<void> {
    HiLog.i(TAG, 'queryEnableScreenReader');
    let enableScreenReader: boolean = await SettingsDataShareUtils.getBoolValue(DataUriType.SETTING_GLOBAL_URI,
      SettingsDataShareUtils.ENABLE_SCREEN_READER_KEY, false);
    GlobalContext.get().setScreenReaderEnabled(enableScreenReader);
    AppStorage.setOrCreate('enableScreenReader', enableScreenReader);
    let isOpenTouchGuide: boolean = accessibility.isOpenTouchGuideSync(); // 无障碍 浏览模式
    GlobalContext.get().setOpenTouchGuide(isOpenTouchGuide);
    AppStorage.setOrCreate('isOpenTouchGuide', isOpenTouchGuide);
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

  private async setShowOnLockScreen(windowStage: window.WindowStage, isShowScreenOn: boolean): Promise<void> {
    try {
      let userId = await this.getUserId();
      // @ts-ignore
      if (screenLock.isLocked() && !screenLock.isDeviceLocked(userId)) {
        HiLog.i(TAG,`setShowOnLockScreen isShowScreenOn:${isShowScreenOn}`)
        windowStage.setShowOnLockScreen(isShowScreenOn);
      }
    } catch (e) {
      HiLog.e(TAG, `setShowOnLockScreen err:${JSON.stringify(e)}`);
    }
  }

  private async getUserId(): Promise<number> {
    const accountManager: osAccount.AccountManager = osAccount.getAccountManager();
    let userId: number = USER_ID;
    try {
      userId = await accountManager.getForegroundOsAccountLocalId();
    } catch (error) {
      HiLog.e(TAG, `get foreground os account local id failed: ${error?.code}`);
    }
    return userId;
  }
}