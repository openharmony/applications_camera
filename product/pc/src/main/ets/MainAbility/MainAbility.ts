/*
 * Copyright (c) Huawei Device Co., Ltd. 2023-2025. All rights reserved.
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
import wantConstant from '@ohos.ability.wantConstant';
import window from '@ohos.window';
import camera from '@ohos.multimedia.camera';
import { Action, ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import { CameraProxy } from '@ohos/common/src/main/ets/camera/uithread/CameraProxy';
import { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { OhCombinedState, Dispatch, Unsubscribe, reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import {
  PersistType,
  PreferencesService
} from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import { ModeMap } from '../common/ModeMap';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { ModeListManager } from '@ohos/common/src/main/ets/mode/ModeListManager';
import { ModeConfig } from '../common/ModeConfig';
import { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import { ThumbnailAction } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailAction';
import { CameraAction, CameraRunningState } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import type { Size } from '@ohos/common/src/main/ets/utils/types';
import { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { WindowAction } from '@ohos/common/src/main/ets/service/window/WindowAction';
import { PropTag, PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import { PlaySound } from '@ohos/common/src/main/ets/component/playsound/playSound';
import { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import type { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import CommonEventManager, {
  CUSTOM_EVENTS
} from '@ohos/common/src/main/ets/component/commonevent/CommonEventManager';
import { Callback } from '@ohos.base';
import { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import config from '@ohos.accessibility.config';
import { BusinessError } from '@ohos.base';
import { Configuration } from '@kit.AbilityKit';
import { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import { AudioSessionService } from '@ohos/common/src/main/ets/service/audioSessionService/AudioSessionService';
import { MemoryService } from '@ohos/common/src/main/ets/service/Memory/MemoryService';
import { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import { screenLock } from '@kit.BasicServicesKit';

const TAG: string = 'MainAbility';
const DELAY_SLEEP_TO_AWAKE_TIME: number = 200;

class StateStruct {
  mode: ModeType;
  position: camera.CameraPosition;
  isColdStart: boolean;
  isImmersive: boolean;
}

class AbilityDispatcher {
  private mDispatch: Dispatch;

  public constructor(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public reloadThumbnail(): void {
    this.mDispatch(ThumbnailAction.refresh());
  }

  public onNewWant(): void {
    this.mDispatch(ContextAction.abilityOnNewWant());
  }

  public initCamera(position, mode): void {
    this.mDispatch(CameraAction.init(position, mode, false));
  }

  public warmStartup(): void {
    this.mDispatch(CameraAction.warmStart());
  }

  public newWantToChangeMode(mode: ModeType): void {
    this.mDispatch(CameraAction.changeMode(mode));
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

  public isEnterImmersive(isEnterImmersive: boolean): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.NULL));
  }

  public close(): void {
    this.mDispatch(CameraAction.release(true));
  }

  public changeWindowEventType(windowStageEventType: window.WindowStageEventType): void {
    this.mDispatch(ContextAction.changeWindowEventType(windowStageEventType));
  }

  public abilityActive(): void {
    this.mDispatch(ContextAction.abilityActive());
  }

  public updateHighContrastState(isHighContrast: boolean): void {
    this.mDispatch(ContextAction.updateHighContrastState(isHighContrast));
  }

  public changeIsLockedState(): void {
    this.mDispatch(ContextAction.screenLockedState(false));
  }
}

export default class MainAbility extends UIAbility {
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private preferencesService: PreferencesService = PreferencesService.getInstance();
  private mState: StateStruct = new StateStruct();
  protected mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mAction: AbilityDispatcher;
  private timerId: number = Number.MIN_VALUE;
  private isLocked: boolean = false;
  private mInitMsg: {
    position: camera.CameraPosition,
    mode: ModeType
  };

  onCreate(want, launchParam): void {
    HiLog.begin(TAG, 'onCreate');
    if (!want) {
      HiLog.e(TAG, 'onCreate want is empty');
      return;
    }
    let applicationContext = this.context.getApplicationContext();
    try {
      applicationContext.setSupportedProcessCache(true);
    } catch (error) {
      HiLog.e(TAG, 'abilityStage setSupportedProcessCache error.');
    }
    // UIAbility is creating, initialize resources for this UIAbility
    AppStorage.setOrCreate<boolean>('isBackground', false);
    AppStorage.setOrCreate<boolean>('isPreemption', false);
    ContextManager.getInstance().setAbilityContext(this.context);
    GlobalContext.get().setCameraAbilityWant(this.launchWant);
    if (!!want?.parameters?.callBundleName) {
      GlobalContext.get().setIsPicker(true);
      GlobalContext.get().setObject('pickerInfo', PickerUiService.getInstance().getPickerInfo(want));
      PickerUiService.getInstance().addPickerVisitLog();
      HiLog.d(TAG, 'picker want camera.');
    } else {
      GlobalContext.get().setIsPicker(false);
      GlobalContext.get().setObject('pickerInfo', null);
    }
    GlobalContext.get().setObject('permissionFlag', false);
    const featureManager: FeatureManager = FeatureManager.getInstance();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mState = {
        mode: state.get<ModeType>('modeReducer', 'mode'),
        position: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        isColdStart: state.get<boolean>('cameraReducer', 'isColdStart'),
        isImmersive: state.get<boolean>('uiReducer', 'isImmersive')
      };
    }, (dispatch: Dispatch): void => {
      this.mAction = new AbilityDispatcher(dispatch);
    });
    this.initCachePrefer();
    this.initModeListAndName(want);
    if (<boolean> this.preferencesService.getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false)) {
      this.mAction.initCamera(this.mInitMsg.position, this.mInitMsg.mode);
    }
    PlaySound.getInstance().init(); // 初始化音频池
    DisplayService.getInstance().init();
    AppStorage.setOrCreate('isOnHiddenCamera', false);
    CameraAppCapability.getInstance().queryCapability(this.mInitMsg.position, this.mInitMsg.mode);
    GlobalContext.get().setObject('isPcCamera', true);
    AppStorage.setOrCreate('startOrUserChangeToModeLast', [ModeType.NONE, this.mInitMsg.mode]);
    featureManager.init(this.mInitMsg.mode, new ModeMap());
    this.mEventBus.on(ContextActionType.SCREEN_LOCKED_STATE, this.sleepToAwakeWarmUp.bind(this), this.mBase.hashCode());
    HiLog.end(TAG, 'onCreate');
  }

  onDestroy(): void {
    HiLog.begin(TAG, 'onDestroy');
    // Ability is creating, release resources for this ability
    PlaySound.getInstance().releaseSoundPool(); // 释放音频池
    PreferencesService.getInstance().flush();
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    FeatureManager.getInstance().unLoadFunctions();
    this.mAction.abilityOnDestroy();
    HiLog.end(TAG, 'onDestroy');
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

  //解锁热起相机
  sleepToAwakeWarmUp(data: ActionData): void {
    HiLog.i(TAG, 'sleepToAwakeWarmUp begin');
    const isIntroLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean;
    if (!isIntroLoaded || AppStorage.get('isOnHiddenCamera')) {
      return;
    }
    if ('isLocked' in data) {
      this.isLocked = data?.isLocked as boolean;
    }
    if (this.timerId !== Number.MIN_VALUE) {
      clearTimeout(this.timerId);
    }
    if (!this.isLocked) {
      HiLog.i(TAG, 'warm startup invoke.');
      this.hotStartUp();
    }
    HiLog.i(TAG, 'sleepToAwakeWarmUp end.');
  }

  onWindowStageCreate(windowStage): void {
    HiLog.begin(TAG, 'onWindowStageCreate');
    windowStage.setDefaultDensityEnabled(true);
    GlobalContext.get().setWindowStage(windowStage);
    // Main window is created, set main page for this ability
    try {
      windowStage.on('windowStageEvent', this.windowStageEventCallback().bind(this));
    } catch (err) {
      HiLog.e(TAG, `onWindowStageEvent fail ${err?.code}`);
    }

    windowStage.getMainWindow().then((win: window.Window) => {
      HiLog.i(TAG, `windowStage.getMainWindow then win: ${win}.`);
      try {
        WindowService.getInstance().init(win);
        WindowService.getInstance().onWindowSizeChange();
        WindowService.getInstance()?.setWindowDecorVisiblePc(false);
      } catch (err) {
        HiLog.e(TAG, `Camera onWindowSizeChange err: ${err?.code}.`);
      }
    }).catch((err) => {
      HiLog.e(TAG, `Camera getMainWindow err: ${err?.code}.`);
    });
    windowStage.setUIContent(this.context, 'pages/indexLand', new LocalStorage());
    HiLog.end(TAG, 'onWindowStageCreate');
  }

  private windowStageEventCallback(): Callback<window.WindowStageEventType> {
    return (event) => {
      HiLog.i(TAG, `Camera MainAbility onWindowStageEvent: ${event}.`);
      switch (event) {
        case window.WindowStageEventType.ACTIVE:
          AppStorage.setOrCreate<boolean>('isPreemption', false);
          this.mAction.reloadThumbnail();
          this.mAction.changeWindowEventType(window.WindowStageEventType.ACTIVE);
          this.mAction.abilityActive();
          AppStorage.setOrCreate<boolean>('isBackground', false);
          AppStorage.setOrCreate<boolean>('pcPickerActive', false)
          break;
        case window.WindowStageEventType.INACTIVE:
          this.mAction.changeWindowEventType(window.WindowStageEventType.INACTIVE);
          break;
        case window.WindowStageEventType.HIDDEN:
          this.mAction.changeWindowEventType(window.WindowStageEventType.HIDDEN);
          if (screenLock.isLocked() && !AppStorage.get('isOnHiddenCamera')) {
            this.mAction.close();
            PlaySound.getInstance().unloadSound();
          }
          break;
        case window.WindowStageEventType.RESUMED:
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
    HiLog.begin(TAG, 'onWindowStageDestroy');
    ContextManager.getInstance().getSettingAbilityContext()?.terminateSelf((err) => {;
      HiLog.i(TAG, `settingAbility terminateSelf ${JSON.stringify(err)}.`);
    });
    HiLog.end(TAG, 'onWindowStageDestroy');
  }


  onForeground(): void {
    HiLog.begin(TAG, 'onForeground');
    CommonEventManager.getInstance().createSubscriber();
    PlaySound.getInstance().loadSound();
    AppStorage.setOrCreate<boolean>('isBackground', false);
    this.getHighContrastTextState();
    this.mAction.foreground();
    MemoryService.getInstance().updateApplicationStorageSpace();
    if (GlobalContext.get().getIsPicker()) {
      PickerUiService.getInstance().registerApplicationStateObserver();
    }
    HiLog.end(TAG, 'onForeground');
  }

  onBackground(): void {
    HiLog.begin(TAG, 'onBackground');
    AudioSessionService.deactivateAudioSession();
    CommonEventManager.getInstance().unsubscribe();
    this.mAction.background(false);
    PlaySound.getInstance().unloadSound();
    AppStorage.setOrCreate<boolean>('isBackground', true);
    PreferencesService.getInstance().flush();
    if (GlobalContext.get().getIsPicker()) {
      PickerUiService.getInstance().unRegisterApplicationStateObserver();
    }
    if (this.mState.isImmersive) {
      this.mAction.isEnterImmersive(false);
    }
    if (<boolean> this.preferencesService.getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false)) {
      this.mAction.close();
    }
    HiLog.end(TAG, 'onBackground');
  }

  onNewWant(want): void {
    HiLog.begin(TAG, 'onNewWant');
    GlobalContext.get().setCameraNewWant(want);
    GlobalContext.get().setCameraAbilityWant(want);
    this.initModeListAndName(want);
    this.mAction.onNewWant();
    HiLog.end(TAG, 'onNewWant');
  }

  private initCachePrefer(): void {
    HiLog.begin(TAG, 'initCachePrefer');
    const position: camera.CameraPosition = DeviceInfo.isPc() ?
    CameraAppCapability.getInstance().getPcSupportCameraPosition() :
      <camera.CameraPosition> PreferencesService.getInstance()
        .getPropValue(PersistType.FOR_AWHILE, PropTag.CAMERA_POSITION, camera.CameraPosition.CAMERA_POSITION_BACK);
    HiLog.i(TAG, `initCachePrefer curStorageCameraPosition is ${position}.`);

    let initMode: ModeType = <ModeType> PreferencesService.getInstance().getPropValue(PersistType.FOR_AWHILE, PropTag.MODE, ModeType.PHOTO);
    HiLog.i(TAG, `initCachePrefer mode: ${initMode}.`);
    this.mInitMsg = {
      position: position, mode: initMode
    };
    HiLog.end(TAG, 'initCachePrefer');
  }

  private initModeListAndName(want): void {
    HiLog.i(TAG, 'initModeListAndName');
    let mode: ModeType = ModeType.NONE;
    let modeList: ModeType[] = [];
    if (want?.action === wantConstant.Action.ACTION_IMAGE_CAPTURE) {
      mode = ModeType.PHOTO;
      modeList = [ModeType.PHOTO];
      if (want?.parameters?.supportMultiMode) {
        modeList = [ModeType.PHOTO, ModeType.VIDEO];
      }
    } else if (want?.action === wantConstant.Action.ACTION_VIDEO_CAPTURE) {
      mode = ModeType.VIDEO;
      modeList = [ModeType.VIDEO];
    } else {
      mode = <ModeType> PreferencesService.getInstance().getPropValue(PersistType.FOR_AWHILE, PropTag.MODE, ModeType.PHOTO);
      const modeConfig: ModeConfig = new ModeConfig();
      modeList = modeConfig.getModeList();
    }
    this.mInitMsg.mode = mode;
    ModeListManager.getInstance().init(modeList);
    HiLog.i(TAG, `initModeListAndName this.mState.mode:${this.mState.mode}, mode:${mode}.`);
  }

  public getHighContrastTextState(): void {
    config.highContrastText.get((err: BusinessError, data: boolean) => {
      if (err) {
        HiLog.e(TAG, `failed to get highContrastText, Code is ${err?.code}`);
        return;
      }
      this.mAction.updateHighContrastState(data);
    });
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    if (newConfig.language) {
      HiLog.i(TAG, `systemLanguage change to ${newConfig.language}`);
      AppStorage.setOrCreate('systemLanguage', newConfig.language);
    }
  }
}