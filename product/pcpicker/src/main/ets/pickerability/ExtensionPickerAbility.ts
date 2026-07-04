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
import { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import camera from '@ohos.multimedia.camera';
import { Dispatch, execDispatch, reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import type { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { PlaySound } from '@ohos/common/src/main/ets/component/playsound/playSound';
import CommonEventManager, {
  CUSTOM_EVENTS
} from '@ohos/common/src/main/ets/component/commonevent/CommonEventManager';
import { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import { ModeMap } from '../../../../../phone/src/main/ets/common/ModeMap';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import { CameraAction } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import type Want from '@ohos.app.ability.Want';
import { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import wantConstant from '@ohos.ability.wantConstant';
import type { OhCombinedState } from '@ohos/common/src/main/ets/redux';
import type { Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import type UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import window from '@ohos.window';
import { WindowAction } from '@ohos/common/src/main/ets/service/window/WindowAction';
import type uiExtensionHost from '@ohos.uiExtensionHost';
import { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import { ModeListManager } from '@ohos/common/src/main/ets/mode/ModeListManager';
import { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import { display } from '@kit.ArkUI';
import { Callback, power } from '@kit.BasicServicesKit';
import config from '@ohos.accessibility.config';
import { BusinessError } from '@ohos.base';
import { Configuration, ConfigurationConstant } from '@kit.AbilityKit';
import { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import { AudioSessionService } from '@ohos/common/src/main/ets/service/audioSessionService/AudioSessionService';
import { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import { PickerInfo } from '@ohos/common/src/main/ets/utils/types';

const TAG: string = 'UIExtensionPickerAbility';

class StateStruct {
  isColdStart: boolean = true;
  isImmersive: boolean;
  isDuringSavePowerMode: boolean;
}

class PickerAbilityDispatcher {
  private mDispatch: Dispatch;

  public constructor(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public initCamera(position, mode): void {
    this.mDispatch(CameraAction.init(position, mode, false));
  }

  public background(isPickerBack: boolean): void {
    PlaySound.getInstance().unloadSound();
    this.mDispatch(ContextAction.abilityOnBackground(isPickerBack));
  }

  public foreground(): void {
    PlaySound.getInstance().loadSound();
    this.mDispatch(ContextAction.abilityOnForeground());
  }

  public changeFunctionValue(id: FunctionId, value: boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public warmStartup(): void {
    this.mDispatch(CameraAction.warmStart());
  }

  updateCollaborationPhotoInfo(): void {
    this.mDispatch(Action.updateCollaborationPhotoInfo());
  }

  public onClassReady(): void {
    this.mDispatch(WindowAction.onClassReady());
  }

  public close(): void {
    this.mDispatch(CameraAction.release(false));
  }

  public abilityActive(): void {
    this.mDispatch(ContextAction.abilityActive());
  }

  public changeIsLockedState(): void {
    this.mDispatch(ContextAction.screenLockedState(false));
  }
}

export default class ExtensionPickerAbility extends UIExtensionAbility {
  private readonly subWindowWidth: number = 1916;
  private readonly subWindowHeight: number = 1117;
  private mBase: BaseComponent = new BaseComponent();
  private mAction: PickerAbilityDispatcher = null;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mModeList: ModeType[] = [ModeType.PHOTO];
  private launchWant: Want = null;
  private mPosition: camera.CameraPosition;
  private mMode: ModeType;
  private mGlobalContext: GlobalContext = GlobalContext.get();
  protected mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private loadIndex: string = 'pages/pickerLand';
  private cameraInActive: boolean = false;
  private mState: StateStruct = new StateStruct();
  private displayInfo: display.Display = DisplayService.getInstance().getDisplay();

  onCreate(): void {
    HiLog.begin(TAG, 'onCreate');
    this.mGlobalContext.setIsPicker(true);
    ContextManager.getInstance().setUiExtensionContext(this.context);
    this.connectStore();
    AppStorage.setOrCreate('settingAnimationDoing', false);
    AppStorage.setOrCreate('lastDirection', WindowDirection.TOP);
    PlaySound.getInstance().init(); // 初始化音频池信息
    DisplayService.getInstance().init();
    let applicationContext = ContextManager.getInstance().getApplicationContext();
    applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    HiLog.end(TAG, 'onCreate');
  }

  onBackground(): void {
    HiLog.begin(TAG, 'onBackground');
    AudioSessionService.deactivateAudioSession();
    CommonEventManager.getInstance().unsubscribe();
    PlaySound.getInstance().unloadSound();
    this.mAction.changeFunctionValue(FunctionId.SETTING, false);
    PreferencesService.getInstance().flush();
    this.mAction.background(true);
    AppStorage.setOrCreate('pickerActive', false);
    HiLog.end(TAG, 'onBackground');
  }

  onForeground(): void {
    HiLog.begin(TAG, 'onForeground');
    CommonEventManager.getInstance().createSubscriber();
    CommonEventManager.getInstance().publishCommonEventMg(CUSTOM_EVENTS.PREEMPTION, {
      isPicker: true
    });
    AppStorage.setOrCreate('pickerActive', true);
    AppStorage.setOrCreate('settingAnimationDoing', false);
    this.getHighContrastTextState();
    this.hotStartUp();
    HiLog.end(TAG, 'onForeground');
  }

  onPreemption(data: { isPicker: boolean }): void {
    HiLog.i(TAG, 'onPreemption begin.');
    if (!data.isPicker) {
      // 非本应用发出的广播,说明被抢占
      this.context.terminateSelf().then(() => {
        HiLog.i(TAG, 'terminateSelf success');
      });
      HiLog.i(TAG, 'onPreemption terminateSelf.');
    }
    HiLog.i(TAG, 'onPreemption end.');
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
    PlaySound.getInstance().releaseSoundPool(); // 释放音频池
    this.mSubscriber.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
    this.mAction.close();
    ContextManager.getInstance().getSettingAbilityContext()?.terminateSelf((err) => {;
      HiLog.i(TAG, `settingAbility terminateSelf ${JSON.stringify(err)}.`);
    });
    HiLog.end(TAG, 'onDestroy');
  }

  onSessionCreate(want, session): void {
    HiLog.begin(TAG, 'onSessionCreate');
    if (!want) {
      HiLog.e(TAG, 'onSessionCreate want is empty');
      return;
    }
    this.launchWant = want;
    this.mGlobalContext.setCameraAbilityWant(want);
    GlobalContext.get().setObject('pickerInfo', PickerUiService.getInstance().getPickerInfo(want));
    this.mMode = this.getStartMode();
    this.mPosition = CameraAppCapability.getInstance().getPcSupportCameraPosition();
    if (this.mMode !== ModeType.VIDEO) {
      CameraAppCapability.getInstance().queryCapability(this.mPosition, ModeType.VIDEO);
    }
    ContextManager.getInstance().setUiExtensionSession(session);
    PickerUiService.getInstance().addPickerVisitLog();
    CameraAppCapability.getInstance().queryCapability(this.mPosition, this.mMode);
    FeatureManager.getInstance().init(this.mMode, new ModeMap());
    ModeListManager.getInstance().init(this.mModeList);
    let wantParam: { [key: string]: Object } = want.parameters as { [key: string]: Object };
    this.mEventBus.on(CameraActionType.PREEMPTION_WITH_ERROR, this.getCameraState.bind(this), this.mBase.hashCode());
    this.startCamera(this.mPosition, this.mMode);
    this.loadContentWithSubWindow(session);
    try {
      session.setWindowPrivacyMode(true);
    } catch (e) {
      HiLog.e(TAG, 'Failed to set the window to privacy mode.');
    }
    HiLog.end(TAG, 'onSessionCreate.');
  }

  public async loadContentWithSubWindow(session: UIExtensionContentSession): Promise<void> {
    const extensionWindow: uiExtensionHost.UIExtensionHostWindowProxy = session.getUIExtensionHostWindowProxy();
    PickerUiService.getInstance().setPickerWindowProxy(extensionWindow);
    HiLog.i(TAG, 'loadContentWithSubWindow E');
    const subWindowOpts: window.SubWindowOptions = {
      'title': ContextManager.getInstance().getResourceManager().getStringSync($r('app.string.app_name')),
      decorEnabled: true,
      isModal: true
    };
    try {
      const subWindow = await extensionWindow.createSubWindowWithOptions('cameraPickerWindow', subWindowOpts);
      subWindow.on('windowEvent', this.windowEventCallback().bind(this));
      const windowService: WindowService = WindowService.getInstance();
      await subWindow.setWindowLimits({
        maxWidth: this.displayInfo.width,
        maxHeight: this.displayInfo.height
      });
      await subWindow.resize(this.subWindowWidth, this.subWindowHeight);
      await subWindow.moveWindowTo((this.displayInfo.width - this.subWindowWidth) >> 1,
        (this.displayInfo.height - this.subWindowHeight) >> 1);
      windowService.init(subWindow);
      windowService.initAvoidArea();
      const storage: LocalStorage = new LocalStorage({
        'session': session
      });
      await subWindow.loadContent(this.loadIndex, storage);
      subWindow.setWindowBackgroundColor('#000000');
      windowService.onWindowSizeChange();
      await subWindow.showWindow();
    } catch (err) {
      HiLog.i(TAG, `loadContent err: ${err}.`);
    }
    HiLog.i(TAG, 'loadContentWithSubWindow X');

  }

  private getCameraState(): void {
    this.cameraInActive = true;
  }

  private windowEventCallback(): Callback<window.WindowEventType> {
    return (event) => {
      HiLog.i(TAG, `Camera ExtensionPickerAbility onWindowEvent: ${JSON.stringify(event)}.`);
      switch (event) {
        case window.WindowEventType.WINDOW_ACTIVE:
          if (this.cameraInActive) {
            this.cameraInActive = false;
            this.hotStartUp();
          }
          CommonEventManager.getInstance().publishCommonEventMg(CUSTOM_EVENTS.EXTENSION_PICKER_CLOSE, {
            isPicker: true,
            isClosePicker: false
          });
          break;
        case window.WindowEventType.WINDOW_INACTIVE:
          break;
        case window.WindowEventType.WINDOW_HIDDEN:
          break;
        case window.WindowEventType.WINDOW_DESTROYED:
          CommonEventManager.getInstance().publishCommonEventMg(CUSTOM_EVENTS.EXTENSION_PICKER_CLOSE, {
            isPicker: true,
            isClosePicker: true
          });
          PickerUiService.getInstance().back();
          break;
      }
    };
  }

  connectStore(): void {
    HiLog.i(TAG, 'connectStore E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState): void => {
      this.mState = {
        isColdStart: state.get<boolean>('cameraReducer', 'isColdStart'),
        isImmersive: state.get<boolean>('uiReducer', 'isImmersive'),
        isDuringSavePowerMode: state.get<boolean>('contextReducer', 'isDuringSavePowerMode'),
      };
    }, (dispatch: Dispatch): void => {
      this.mAction = new PickerAbilityDispatcher(dispatch);
    });
    HiLog.i(TAG, 'connectStore X.');
  }

  getStartMode(): ModeType {
    HiLog.i(TAG, 'getStartMode.');
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
    HiLog.i(TAG, `initCachePrefer initModeListAndName: ${JSON.stringify(modeList)}.`);
    this.mModeList = modeList;
    HiLog.i(TAG, `getStartMode mode is ${mode}`);
    return mode;
  }

  startCamera(position, mode): void {
    this.mAction.initCamera(position, mode);
  }

  sleepToAwakeWarmUp(): void {
    HiLog.i(TAG, 'sleepToAwakeWarmUp begin');
    PlaySound.getInstance().loadSound();
    AppStorage.setOrCreate<boolean>('isBackground', false);
    if (!this.mState.isColdStart) {
      HiLog.i(TAG, 'warm startup invoke.');
      this.mAction.warmStartup();
      this.mAction.changeIsLockedState();
    }
    this.mAction.foreground();
    HiLog.i(TAG, 'sleepToAwakeWarmUp end.');
  }

  private hotStartUp(): void {
    PlaySound.getInstance().loadSound();
    AppStorage.setOrCreate<boolean>('isBackground', false);
    if (!this.mState.isColdStart) {
      HiLog.i(TAG, 'warm startup invoke.');
      this.mAction.warmStartup();
    }
    this.mAction.foreground();
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

  onConfigurationUpdate(newConfig: Configuration): void {
    if (newConfig.language) {
      HiLog.i(TAG, `systemLanguage change to ${newConfig.language}`);
      AppStorage.setOrCreate('systemLanguage', newConfig.language);
    }
  }
};