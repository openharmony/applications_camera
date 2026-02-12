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

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import lazy { Action, ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import camera from '@ohos.multimedia.camera';
import lazy { Dispatch, execDispatch, getStates, reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import type { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { PlaySound } from '@ohos/common/src/main/ets/component/playsound/playSound';
import CommonEventManager from '@ohos/common/src/main/ets/component/commonevent/CommonEventManager';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { ModeMap } from '../../../../../phone/src/main/ets/common/ModeMap';
import lazy { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import lazy { CameraAction, CameraRunningState } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import type Want from '@ohos.app.ability.Want';
import wantConstant from '@ohos.ability.wantConstant';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import type { OhCombinedState } from '@ohos/common/src/main/ets/redux';
import type { Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import type UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import lazy { display, Size, uiExtensionHost, window } from '@kit.ArkUI';
import lazy { pxChange, WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { ModeListManager } from '@ohos/common/src/main/ets/mode/ModeListManager';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { SettingsDataShareUtils, DataUriType } from '@ohos/common/src/main/ets/utils/SettingsDataShareUtils';
import lazy { WindowAction } from '@ohos/common/src/main/ets/service/window/WindowAction';
import lazy { Callback, power } from '@kit.BasicServicesKit';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import config from '@ohos.accessibility.config';
import lazy { BusinessError } from '@ohos.base';
import lazy { Configuration, ConfigurationConstant } from '@kit.AbilityKit';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import lazy { PickerWindowType } from '@ohos/common/src/main/ets/component/picker/PickerWindowType';
import lazy { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import lazy { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import lazy { AudioSessionService } from '@ohos/common/src/main/ets/service/audioSessionService/AudioSessionService';
import lazy { accessibility } from '@kit.AccessibilityKit';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { PickerInfo } from '@ohos/common/src/main/ets/utils/types';
import lazy { dataShare } from '@kit.ArkData';

const TAG: string = 'ExtensionPickerAbility';
const DELAY: number = 400;

class StateStruct {
  isColdStart: boolean = true;
  isImmersive: boolean;
  isDuringSavePowerMode: boolean;
}

export class WindowSizeStruct {
  public width: number = 0;
  public height: number = 0;
}

class PickerAbilityDispatcher {
  private mDispatch: Dispatch;

  public constructor(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public initCamera(position, mode): void {
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

  public warmStartup(): void {
    this.mDispatch(CameraAction.warmStart());
  }

  public changeFunctionValue(id: FunctionId, value: boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  updateCollaborationPhotoInfo(): void {
    this.mDispatch(Action.updateCollaborationPhotoInfo());
  }

  public close(): void {
    this.mDispatch(CameraAction.release(false));
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.NULL));
  }

  public thirdPartyCall(isThirdPartyCall: boolean, action: string): void {
    this.mDispatch(Action.thirdPartyCall(isThirdPartyCall, action));
  }

  public updateHighContrastState(isHighContrast: boolean): void {
    this.mDispatch(ContextAction.updateHighContrastState(isHighContrast));
  }

  public updatePickerWindowType(pickerWindowType: PickerWindowType): void {
    this.mDispatch(WindowAction.updatePickerWindowType(pickerWindowType));
  }

  public changeXComponentSize(size: WindowSizeStruct): void {
    this.mDispatch(Action.changeXComponentSize(size.width, size.height));
  }

  public openTreasureBox(): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(true));
  }

  public changeExtensionWindowEventType(windowEventType: window.WindowEventType): void {
    this.mDispatch(ContextAction.changeExtensionWindowEventType(windowEventType));
  }
}

export default class ExtensionPickerAbility extends UIExtensionAbility {
  private subWindow: window.Window = undefined;
  private extensionWindow: uiExtensionHost.UIExtensionHostWindowProxy = undefined;
  private mBase: BaseComponent = new BaseComponent();
  private mAction: PickerAbilityDispatcher = null;
  private mState: StateStruct = new StateStruct();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private settingDataHelper: dataShare.DataShareHelper = undefined;
  private mModeList: ModeType[] = [ModeType.PHOTO];
  private launchWant: Want = null;
  private mPosition: camera.CameraPosition;
  private mMode: ModeType;
  protected mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mGlobalContext: GlobalContext = GlobalContext.get();
  private loadIndex: string = 'pages/picker';
  private cameraStatus: number = -1;
  private isChecking: boolean = false;
  private isForeground: boolean = false;
  private mCurrentDpi: number;

  onCreate(): void {
    HiLog.begin(TAG, 'onCreate');
    this.mGlobalContext.setIsPicker(true);
    ContextManager.getInstance().setUiExtensionContext(this.context);
    this.onConfigurationUpdate(this.context.config);
    this.mEventBus.on(CameraActionType.ON_CAMERA_STATUS, this.onCameraStatus.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CommonEventManager.SCREEN_CHANGE_EVENT, this.onScreenStatusChange.bind(this),
      this.mBase.hashCode());
    AppStorage.setOrCreate('settingAnimationDoing', false);
    AppStorage.setOrCreate('lastDirection', WindowDirection.TOP);
    PlaySound.getInstance().init(); // 初始化音频池信息
    DisplayService.getInstance().init();
    DisplayService.getInstance();
    let applicationContext = ContextManager.getInstance().getApplicationContext();
    applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    HiLog.end(TAG, 'onCreate');
  }

  onForeground(): void {
    if (this.isForeground) {
      return;
    }
    if (this.extensionWindow !== undefined && this.subWindow !== undefined) {
      this.resizeWindowSize();
    }
    CommonEventManager.getInstance().createSubscriber();
    this.isForeground = true;
    HiLog.begin(TAG, 'onForeground');
    GlobalContext.get().setIsPicker(true);
    PlaySound.getInstance().loadSound();
    if (!this.mState.isColdStart && !this.mState.isDuringSavePowerMode &&
      !getStates().get<boolean>('uiReducer', 'showPicker')) {
      this.mAction.warmStartup();
    }
    if (!this.isChecking) {
      this.isChecking = true;
      this.checkCameraStatusAndRestart();
    }
    this.mAction.foreground();
    AppStorage.setOrCreate('pickerActive', true);
    WindowService.getInstance().setSpecificSystemNavigationEnabled(true, true, false);
    AppStorage.setOrCreate('settingAnimationDoing', false);
    this.getHighContrastTextState();
    this.registerDisplayChange();
    this.queryEnableScreenReader();
    HiLog.end(TAG, 'onForeground');
  }

  /**
   * 监听窗口DPI变化
   */
  private registerDisplayChange(): void {
    this.mCurrentDpi = DisplayService.getInstance().getDisplay().densityDPI;
    DisplayService.getInstance().registerChange(this.changeCallback.bind(this));
  }

  private changeCallback(): Callback<number> {
    return () => {
      const newDisplay: display.Display = DisplayService.getInstance().getDisplay();
      if (newDisplay === undefined || newDisplay.densityDPI === this.mCurrentDpi) {
        return;
      }
      HiLog.i(TAG, `displayChange new DPI: ${newDisplay.densityDPI}`);
      this.mCurrentDpi = newDisplay.densityDPI;
      StoreManager.getInstance().postMessage(Action.pickerDpiChange());
      setTimeout(() => {
        this.resizeWindowSize();
      }, 50);
    };
  }

  /**
   * 取消监听窗口DPI变化
   */
  private unregisterDisplayChange(): void {
    this.mCurrentDpi = DisplayService.getInstance().getDisplay().densityDPI;
    DisplayService.getInstance().registerChange(this.changeCallback.bind(this));
  }

  private async checkCameraStatusAndRestart(checkTimes: number = 3): Promise<void> {
    while (checkTimes > 0) {
      StoreManager.getInstance().postMessage(Action.uiState(false));
      await new Promise((resolve) => {
        setTimeout(resolve, DELAY);
      });
      checkTimes--;
      if (!this.isForeground || this.mState.isDuringSavePowerMode || GlobalContext.get().getIsPicker()) {
        HiLog.i(TAG, 'checkCameraStatus no need to warmStartup');
        StoreManager.getInstance().postMessage(Action.uiState(true));
        this.isChecking = false;
        return;
      }
    }
    if (this.cameraStatus === camera.CameraStatus.CAMERA_STATUS_AVAILABLE && this.isForeground &&
      !this.mState.isDuringSavePowerMode) {
      if (power.isActive()) {
        HiLog.i(TAG, 'checkCameraStatus need to warmStartup');
        this.mAction.warmStartup();
      }
    }
    StoreManager.getInstance().postMessage(Action.uiState(true));
    this.isChecking = false;
  }

  onBackground(): void {
    if (!this.isForeground) {
      return;
    }
    AudioSessionService.deactivateAudioSession();
    this.isForeground = false;
    HiLog.begin(TAG, 'onBackground');
    CommonEventManager.getInstance().unsubscribe();
    if (this.mState.isImmersive) {
      this.mAction.isEnterImmersive(false);
    }
    if (!AppStorage.get('securityCameraOn') as boolean) {
      PlaySound.getInstance().unloadSound();
    }
    if (!this.mGlobalContext.getJumpToBrowser()) {
      this.mAction.changeFunctionValue(FunctionId.SETTING, false);
    }
    PreferencesService.getInstance().flush();
    this.mAction.background(true);
    this.mAction.close();
    this.unregisterDisplayChange();
    HiLog.end(TAG, 'onBackground');
  }

  onDestroy(): void {
    HiLog.begin(TAG, 'onDestroy');
    try {
      PickerUiService.getInstance().stopUsingPermission(GlobalContext.get().getObject('pickerInfo') as PickerInfo);
    } catch (err) {
      HiLog.e(TAG, `stopUsingPermission fail ${err?.code}`);
    }
    PickerUiService.getInstance().resetURIContent();
    PreferencesService.getInstance().flush();
    if (!AppStorage.get('securityCameraOn') as boolean) {
      PlaySound.getInstance().releaseSoundPool(); // 释放音频池
    }
    GlobalContext.get().setIsPicker(false);
    WindowService.getInstance().unRegisterAccelerometer();
    this.mSubscriber.destroy();
    this.unRegisterDataShare();
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

  onSessionCreate(want: Want, session): void {
    HiLog.begin(TAG, 'onSessionCreate');
    if (!want) {
      HiLog.e(TAG, 'onSessionCreate want is empty');
      return;
    }
    PickerUiService.getInstance().dealPicker(want);
    this.launchWant = want;
    this.mGlobalContext.setCameraAbilityWant(want);
    this.connectStore();
    this.mAction.thirdPartyCall(true, want.action);
    GlobalContext.get().setIsPicker(true);
    GlobalContext.get().setObject('pickerInfo', PickerUiService.getInstance().getPickerInfo(want));
    PickerUiService.getInstance().addPickerVisitLog();
    this.mMode = this.getStartMode();
    if (want.parameters?.cameraPosition) {
      this.mPosition = want.parameters?.cameraPosition as camera.CameraPosition;
    } else {
      this.mPosition = camera.CameraPosition.CAMERA_POSITION_BACK;
    }
    if (this.mMode !== ModeType.VIDEO) {
      CameraAppCapability.getInstance().queryCapability(this.mPosition, ModeType.VIDEO);
    }
    ContextManager.getInstance().setUiExtensionSession(session);
    CameraAppCapability.getInstance().queryCapability(this.mPosition, this.mMode);
    FeatureManager.getInstance().init(this.mMode, new ModeMap());
    ModeListManager.getInstance().init(this.mModeList); // 初始化picker的模式序列
    this.startCamera(this.mPosition, this.mMode);

    let wantParam: { [key: string]: Object } = want.parameters as { [key: string]: Object };
    this.loadContent(session);
    try {
      session.setWindowPrivacyMode(true);
    } catch (e) {
      HiLog.e(TAG, 'Failed to set the window to privacy mode.');
    }
    this.registerDataShare();
    HiLog.end(TAG, 'onSessionCreate.');
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

  private async onCameraStatus(data: ActionData): Promise<void> {
    if ('cameraStatus' in data) {
      this.cameraStatus = data?.cameraStatus as number;
    }
    HiLog.i(TAG, `cameraStatus: ${this.cameraStatus}.`);
    if (!this.isChecking && !getStates().get<boolean>('uiReducer', 'showPicker')) {
      this.isChecking = true;
      this.checkCameraStatusAndRestart();
    }
  }

  public loadContent(session: UIExtensionContentSession): void {
    // extension无自身窗口,嵌入三方应用感知三方窗口
    this.extensionWindow = session.getUIExtensionHostWindowProxy();
    PickerUiService.getInstance().setPickerWindowProxy(this.extensionWindow);
    this.loadContentWithSubWindow(session);
  }

  private async loadContentWithSubWindow(session: UIExtensionContentSession): Promise<void> {
    HiLog.i(TAG, 'loadContentWithSubWindow E');
    const subWindowOpts: window.SubWindowOptions = {
      'title': 'camera picker',
      decorEnabled: true,
      isModal: true
    };
    try {
      this.subWindow = await this.extensionWindow.createSubWindowWithOptions('cameraPickerWindow', subWindowOpts);
      try {
        // @ts-ignore
        this.subWindow.setDefaultDensityEnabled(true);
      } catch (e) {
        HiLog.e(TAG, 'lock density failed');
      }
      const storage: LocalStorage = new LocalStorage({ 'session': session });
      this.resizeWindowSize();
      await this.subWindow.loadContent(this.loadIndex, storage);
      this.subWindow.setWindowBackgroundColor('#00000000');
      await this.subWindow.showWindow();
      const windowService: WindowService = WindowService.getInstance();
      windowService.init(this.subWindow);
      windowService.initAvoidArea();
      windowService.setFullScreen();
      windowService.initFloatingService();
      windowService.registerAccelerometer();
      this.subWindow.on('windowSizeChange', this.windowSizeChangeCallback().bind(this));
    } catch (err) {
      HiLog.i(TAG, 'loadContent err.');
    }
    HiLog.i(TAG, 'loadContentWithSubWindow X');
  }

  private async resizeWindowSize(): Promise<void> {
    const size: Size = pxChange(this.extensionWindow.properties.uiExtensionHostWindowProxyRect);
    HiLog.i(TAG, `loadContentWithSubWindow windowSizeChange, width: ${size.width}, height: ${size.height}.`);
    const displayInfo: display.Display = DisplayService.getInstance().getDisplay();
    if (DeviceInfo.isTablet() && PickerUtils.getIsTabletInFreeWindow(size.width, size.height)) {
      const width: number = 0.75 * displayInfo.width;
      const height: number = 0.75 * displayInfo.height;
      const maxWidth: number = 0.85 * displayInfo.width;
      const maxHeight: number = 0.85 * displayInfo.height;
      HiLog.i(TAG, `Tablet free window. Width: ${width} Height ${height}`);
      await this.subWindow.resize(width, height);
      this.onWindowSizeChange({
        width: width, height: height
      });
      await this.subWindow.moveWindowTo((displayInfo.width - width) >> 1,
        (displayInfo.height - px2vp(265) - height) >> 1);
      await this.subWindow.setWindowLimits({
        minWidth: width,
        minHeight: height,
        maxWidth: maxWidth,
        maxHeight: maxHeight
      });
      this.subWindow.on('windowEvent', this.windowEventCallback().bind(this));
    } else {
      await this.subWindow.resize(displayInfo.width, displayInfo.height);
      this.onWindowSizeChange(size);
      this.subWindow.on('windowEvent', this.windowEventCallback().bind(this));
    }
  }

  private windowEventCallback(): Callback<window.WindowEventType> {
    return (event) => {
      HiLog.i(TAG, `Camera ExtensionPickerAbility onWindowEvent: ${JSON.stringify(event)}.`);
      switch (event) {
        case window.WindowEventType.WINDOW_DESTROYED:
          PickerUiService.getInstance().back();
          break;
        case window.WindowEventType.WINDOW_INACTIVE:
          this.mAction.changeExtensionWindowEventType(window.WindowEventType.WINDOW_INACTIVE);
          break;
      }
    };
  }

  private onScreenStatusChange(isScreenOn: boolean): void {
    HiLog.i(TAG, `onScreenStatusChange, isScreenOn: ${isScreenOn}.`);
    if (isScreenOn) {
      const state = getStates();
      if (this.isForeground &&
        (state.get<CameraRunningState>('cameraReducer', 'cameraRunningState') === CameraRunningState.UNINITIALIZED ||
        AppStorage.get('cameraError'))) {
        this.mAction.warmStartup();
      }
    } else {
      this.mAction.close();
    }
  }

  onSessionDestroy(session): void {
    HiLog.i(TAG, 'onSessionDestroy begin.');
    PreferencesService.getInstance().flush();
    GlobalContext.get().setIsPicker(false);
    WindowService.getInstance().unRegisterAccelerometer();
    AppStorage.setOrCreate('pickerActive', false);
    StoreManager.getInstance().postMessage(Action.updateShowPickerView(false));
    session.terminateSelf((error) => {
      HiLog.e(TAG, `Operation terminateSelf : ${error?.code}.`);
    });
    HiLog.i(TAG, 'onSessionDestroy end.');
  }

  connectStore(): void {
    HiLog.i(TAG, 'ExtensionPickerAbility connectStore E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState): void => {
      this.mState = {
        isColdStart: state.get<boolean>('cameraReducer', 'isColdStart'),
        isImmersive: state.get<boolean>('uiReducer', 'isImmersive'),
        isDuringSavePowerMode: state.get<boolean>('contextReducer', 'isDuringSavePowerMode'),
      };
    }, (dispatch: Dispatch): void => {
      this.mAction = new PickerAbilityDispatcher(dispatch);
    });
    HiLog.i(TAG, 'ExtensionPickerAbility connectStore X.');
  }

  getStartMode(): ModeType {
    HiLog.i(TAG, 'ExtensionPickerAbility getStartMode.');
    const want: Want = this.launchWant;
    let mode: ModeType = ModeType.PHOTO;
    let modeList: ModeType[] = [ModeType.PHOTO];
    if (want?.action === wantConstant.Action.ACTION_IMAGE_CAPTURE) {
      let isPhotoPicker: boolean = false;
      HiLog.i(TAG, 'ExtensionPickerAbility isPhotoPicker');
      if (want?.parameters?.supportMultiMode) {
        isPhotoPicker = <boolean> want?.parameters?.supportMultiMode;
      }
      if (isPhotoPicker) {
        modeList = [ModeType.PHOTO, ModeType.VIDEO];
      }
      HiLog.i(TAG, 'ExtensionPickerAbility modeList modeName');
    } else if (want?.action === wantConstant.Action.ACTION_VIDEO_CAPTURE) {
      mode = ModeType.VIDEO;
      modeList = [ModeType.VIDEO];
    }
    const isPickerSupportedPortrait: boolean = CameraAppCapability.getInstance().getIsPickerSupportedPortrait();
    HiLog.i(TAG, `isPickerSupportedPortrait: ${isPickerSupportedPortrait}`);
    if (DeviceInfo.isTablet()) {
      modeList.shift();
    }
    HiLog.i(TAG, `initCachePrefer initModeListAndName: ${JSON.stringify(modeList)}.`);
    this.mModeList = modeList;
    HiLog.i(TAG, `ExtensionPickerAbility getStartMode mode is ${mode}`);
    return mode;
  }

  startCamera(position, mode): void {
    HiLog.i(TAG, `getStartMode mode is ${mode}`);
    this.mAction.initCamera(position, mode);
  }

  private async queryEnableScreenReader(): Promise<void> {
    HiLog.i(TAG, 'queryEnableScreenReader');
    let enableScreenReader: boolean = await SettingsDataShareUtils.getBoolValue(DataUriType.SETTING_GLOBAL_URI,
      SettingsDataShareUtils.ENABLE_SCREEN_READER_KEY, false);
    GlobalContext.get().setScreenReaderEnabled(enableScreenReader);
    AppStorage.setOrCreate('enableScreenReader', enableScreenReader);
    HiLog.i(TAG, 'queryEnableScreenReader' + enableScreenReader);
    let isOpenTouchGuide: boolean = accessibility.isOpenTouchGuideSync(); // 无障碍 浏览模式
    GlobalContext.get().setOpenTouchGuide(isOpenTouchGuide);
    AppStorage.setOrCreate('isOpenTouchGuide', isOpenTouchGuide);
  }

  private windowSizeChangeCallback(): Callback<window.Size> {
    HiLog.i(TAG, 'windowSizeChangeCallback registered');
    return async (size: Size) => {
      size = pxChange(size);
      HiLog.i(TAG, `windowSizeChange, width: ${size.width}, height: ${size.height}.`);
      this.onWindowSizeChange(size);
    };
  }

  private onWindowSizeChange(size: Size): void {
    if ((PickerUtils.getIsExpandedTopBottomSplitScreen(size.height, size.width)) && !DeviceInfo.isTablet()) {
      size = { width: size.height, height: size.width };
    }
    PickerUtils.updatePickerWindowType(size);
    execDispatch(WindowAction.onSizeChange(size));
    this.updateXComponentSize(size);
  }

  private updateXComponentSize(size: Size): void {
    if (getStates().get<boolean>('collapsReducer', 'isShowTricollaps')) {
      return;
    }
    const componentSize: Size =
      CameraBasicService.getInstance().getPreviewDisplaySize(undefined, size.width, size.height);
    this.mAction.changeXComponentSize(componentSize);

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
};