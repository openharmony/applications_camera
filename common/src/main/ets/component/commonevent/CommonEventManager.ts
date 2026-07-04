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

import lazy { Action } from '../../redux/actions/Action';
import Base from '@ohos.base';
import CommonEventMg from '@ohos.commonEventManager';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { Dispatch, execDispatch, getStates, reduxSubscribe } from '../../redux';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { debounce } from './Decorators';
import type { EventBus } from '../../worker/eventbus/EventBus';
import lazy { ContextAction } from '../../redux/actions/ContextAction';
import lazy { CameraAction, CameraRunningState } from '../../camera/uithread/CameraAction';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '../../function/core/FunctionAction';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { ContextManager } from '../../service/context/ContextManager';
import lazy { RecordAction, RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { RecordMode } from '../../function/recordcontrol/RecordMode';
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import lazy { PublicTag } from '../../service/preferences/PropTag';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import screenLock from '@ohos.screenLock';
import lazy { ThumbnailAction } from '../thumbnail/ThumbnailAction';
import lazy { PickerAction } from '../../service/picker/PickerAction';
import lazy { VolumeShutterService } from '../../service/volume/VolumeShutterService';
import lazy { AppLockUtil } from '../../utils/AppLockUtil';
import lazy { WindowService } from '../../service/window/WindowService';
import window from '@ohos.window';

const TAG: string = 'CommonEventManager';

const DELAY_TIME: number = 200;

export enum CUSTOM_EVENTS {
  PREEMPTION = 'preemption',
  CHANGE_FUNCTION_VAL = 'CHANGE_FUNCTION_VAL',
  EXTENSION_PICKER_CLOSE = 'EXTENSION_PICKER_CLOSE'
}

export class CommonEventData {
  isPicker?: boolean;
  functionId?: FunctionId;
  functionValue?: unknown;
  active?: boolean;
  isClosePicker?: boolean;
}

/* instrument ignore file */
const COMMON_EVENT_INFO = {
  events: [CommonEventMg.Support.COMMON_EVENT_SCREEN_OFF, CommonEventMg.Support.COMMON_EVENT_SCREEN_ON,
    CommonEventMg.Support.COMMON_EVENT_LOCALE_CHANGED, CommonEventMg.Support.COMMON_EVENT_SHUTDOWN,
    CommonEventMg.Support.COMMON_EVENT_SCREEN_LOCKED, CommonEventMg.Support.COMMON_EVENT_SCREEN_UNLOCKED,
    CUSTOM_EVENTS.PREEMPTION, CUSTOM_EVENTS.CHANGE_FUNCTION_VAL, CUSTOM_EVENTS.EXTENSION_PICKER_CLOSE]
};
const DEBOUNCE_TIMEOUT = 50;

class CommonManagerDispatcher {
  private mDispatch: Dispatch;

  public constructor(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  notifyDevShutDown(): void {
    this.mDispatch(ContextAction.devOnShutDown());
  }

  notifyScreenLockState(isLock: boolean): void {
    this.mDispatch(ContextAction.screenLockedState(isLock));
  }

  notifyCameraPreemption(data: CommonEventData): void {
    this.mDispatch(CameraAction.preemption(data));
  }

  notifyExtensionPickerClose(data: CommonEventData): void {
    this.mDispatch(PickerAction.extensionPickerClose(data));
  }

  changeFunctionValue(id: FunctionId, value: unknown): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  };

  public setCameraShotKey(cameraShotKey: string): void {
    if (getStates().get<string>('securityCameraReducer', 'cameraShotKey') === cameraShotKey) {
      // 两次cameraShotKey值相同，不重复发送消息
      return;
    }
    this.mDispatch(Action.setCameraShotKey(cameraShotKey));
  };

  public updateIsSecurityCamera(isSecurityCamera: boolean): void {
    this.mDispatch(Action.updateIsSecurityCamera(isSecurityCamera));
  }

  public foreground(): void {
    this.mDispatch(CameraAction.warmStart());
    this.mDispatch(ContextAction.abilityOnForeground());
  }

  public background(): void {
    this.mDispatch(CameraAction.close({ isNeedSaveRestore: true }));
    this.mDispatch(ContextAction.abilityOnBackground(false, true));
  }

  public stopRecording(): void {
    this.mDispatch(RecordAction.stop());
  }

  public refreshThumbnail(): void {
    this.mDispatch(ThumbnailAction.refresh());
  }
}

export class CommonEventManager {
  public static readonly SCREEN_CHANGE_EVENT = 'SCREEN_CHANGE_EVENT';
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mAction: CommonManagerDispatcher;
  private static sInstanceCommonManager: CommonEventManager;
  private subscriber: CommonEventMg.CommonEventSubscriber; //用于保存创建成功的订阅者对象，后续使用其完成订阅及退订的动作

  public static getInstance(): CommonEventManager {
    if (!CommonEventManager.sInstanceCommonManager) {
      CommonEventManager.sInstanceCommonManager = new CommonEventManager();
    }
    return CommonEventManager.sInstanceCommonManager;
  }

  private constructor() {
    reduxSubscribe(null, (dispatch: Dispatch) => {
      this.mAction = new CommonManagerDispatcher(dispatch);
    });
  }

  //订阅公共事件回调
  private subscribeCB(err: Base.BusinessError, data: CommonEventMg.CommonEventData): void {
    if (err) {
      HiLog.e(TAG, `subscribeCB err, code is ${err?.code}`);
    } else {
      HiLog.i(TAG, `subscribeCB data: ${JSON.stringify(data)}.`);
      switch (data.event) {
        case CommonEventMg.Support.COMMON_EVENT_SCREEN_OFF:
          this.doCameraScreenOff();
          break;
        case CommonEventMg.Support.COMMON_EVENT_SCREEN_ON:
          this.doCameraScreenOn();
          break;
        case CommonEventMg.Support.COMMON_EVENT_LOCALE_CHANGED:
          break;
        case CommonEventMg.Support.COMMON_EVENT_SHUTDOWN:
          this.mAction.notifyDevShutDown();
          break;
        case CommonEventMg.Support.COMMON_EVENT_SCREEN_LOCKED:
          this.mAction.notifyScreenLockState(true);
          break;
        case CommonEventMg.Support.COMMON_EVENT_SCREEN_UNLOCKED:
          this.mAction.notifyScreenLockState(false);
          this.doCameraScreenUnLock();
          break;
        case CUSTOM_EVENTS.PREEMPTION:
          this.mAction.notifyCameraPreemption(data.parameters);
          break;
        case CUSTOM_EVENTS.CHANGE_FUNCTION_VAL:
          this.changeFunctionValue(data.parameters);
          break;
          case CUSTOM_EVENTS.EXTENSION_PICKER_CLOSE:
            this.mAction.notifyExtensionPickerClose(data.parameters);
            break;
        default:
          HiLog.i(TAG, 'unKnow event.');
      }
    }
  }

  //创建订阅者回调
  private createCB(err: Base.BusinessError, commonEventSubscriber: CommonEventMg.CommonEventSubscriber): void {
    if (!err) {
      HiLog.i(TAG, 'createSubscriber.');
      this.subscriber = commonEventSubscriber;
      //订阅公共事件
      try {
        CommonEventMg.subscribe(this.subscriber, this.subscribeCB.bind(this));
      } catch (err) {
        HiLog.e(TAG, `createCB err, code is ${err?.code}.`);
      }
    } else {
      HiLog.e(TAG, `createCB failed, code is ${err?.code}.`);
    }
  }

  // 取消订阅公共事件回调
  private unsubscribeCB(err: Base.BusinessError): void {
    if (err) {
      HiLog.e(TAG, `unsubscribe failed, code is ${err?.code}`);
    } else {
      HiLog.i(TAG, 'unsubscribe');
    }
  }

  public createSubscriber(): void {
    //创建订阅者
    try {
      CommonEventMg.createSubscriber(COMMON_EVENT_INFO, this.createCB.bind(this));
    } catch (err) {
      HiLog.e(TAG, `createSubscriber failed, code is ${err?.code}.`);
    }
  }

  public unsubscribe(): void {
    //取消订阅者
    setTimeout(() => {
      try {
        CommonEventMg.unsubscribe(this.subscriber, this.unsubscribeCB.bind(this));
      } catch (err) {
        HiLog.e(TAG, `createSubscriber failed, code is ${err?.code}.`);
      }
    }, DELAY_TIME);
  }

  @debounce(DEBOUNCE_TIMEOUT)
  notifyScreenEvent(isScreenOn: boolean): void {
    this.mEventBus.emit(CommonEventManager.SCREEN_CHANGE_EVENT, [isScreenOn]);
    HiLog.i(TAG, `Publish ${CommonEventManager.SCREEN_CHANGE_EVENT} screenState: ${isScreenOn}.`);
  }

  private changeFunctionValue(data: CommonEventData): void {
    if (data.isPicker && data.functionId && GlobalContext.get().getIsPicker()) {
      this.mAction.changeFunctionValue(data.functionId, data.functionValue);
    }
  }

  public publishCommonEventMg(event: string, data: CommonEventData): void {

    let options = {
      code: 1,
      data: '',
      parameters: data
    };

    // 发布公共事件
    try {
      CommonEventMg.publish(event, options, (err) => {
        if (err) {
          HiLog.e(TAG, `[CommonEvent]: ${event}, publish fail.`);
        } else {
          HiLog.i(TAG, `[CommonEvent]: ${event}, publish success.`);
        }
      });
    } catch (err) {
      HiLog.e(TAG, `publishCommonEventMg failed, code is ${err?.code}.`);
    }
  }

  private doCameraScreenOn(): void {
    //相机已后台||进程保活，相机已收到onDestroy，但是还能接受公共事件。导致时序混乱，销毁拦截
    if (AppStorage.get<boolean>('Destroyed') || AppStorage.get<boolean>('isBackground')) {
      HiLog.i(TAG, 'ability is destroyed or isBackground.');
      return;
    }
    this.notifyScreenEvent(true);
    VolumeShutterService.getInstance().volumeKeySubscribe();
    // 锁屏相机|通话中场景场景
    let isIntroLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean;
    if (isIntroLoaded &&
      getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') === CameraRunningState.UNINITIALIZED &&
      !getStates().get<boolean>('contextReducer', 'isDuringSavePowerMode') && !DeviceInfo.isPc()) {
      this.mAction.foreground();
    }
  }


  private async doCameraScreenOff(): Promise<void> {
    AppStorage.setOrCreate('isOpenCustomFilterCardByApp', false);
    this.notifyScreenEvent(false);
    VolumeShutterService.getInstance().volumeKeyUnsubscribe();
    WindowService.getInstance().setWinOrientation(window.Orientation.FOLLOW_DESKTOP);
    // 锁屏相机|通话中场景
    let isSecureMode = await screenLock.isSecureMode();
    HiLog.i(TAG, 'isSecureMode:' + isSecureMode);
    if (getStates().get<string>('securityCameraReducer', 'cameraShotKey') ||
      (GlobalContext.get().getObject('isSecurityCamera') && isSecureMode)) {
      ContextManager.getInstance().getUiContext().terminateSelf().then(() => {
        HiLog.i(TAG, 'terminateSelf success');
      });
      return;
    } else {
      if (GlobalContext.get().getT('showOnScreen') && !GlobalContext.get().getObject('isSecurityCamera')) {
        this.setNotShowLockScreen();
      }
    }
    const isShowPhotoBrowser: boolean = AppStorage.get<boolean>('isShowPhotoBrowser');
    if (GlobalContext.get().getObject('isSecurityCamera') && isShowPhotoBrowser) {
      ContextManager.getInstance().getUiContext().terminateSelf();
    }
    let isIntroLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean;
    if (isIntroLoaded && (getStates().get<boolean>('cameraReducer', 'isCameraActive') ||
      getStates().get<boolean>('contextReducer', 'isDuringSavePowerMode') || isShowPhotoBrowser)) {
      this.mAction.background();
    }
    // 录像中息屏，停止录像
    if (this.cameraRecordState()) {
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
    }
  }

  private cameraRecordState(): boolean {
    let recordState = getStates().get<RecordingState>('recordReducer', 'recordingState');
    if (recordState === RecordingState.RECORDING || recordState === RecordingState.PAUSING ||
      recordState === RecordingState.PAUSED || recordState === RecordingState.RESUMING) {
      return true;
    }
    return false;
  }

  private async doCameraScreenUnLock(): Promise<void> {
    if (AppStorage.get('Destroyed')) { //进程保活，相机已收到onDestroy，但是还能接受公共事件。导致时序混乱，销毁拦截
      HiLog.i(TAG,'ability is destroyed');
      return;
    }
    // 锁屏相机界面不退出解锁
    if (GlobalContext.get().getT('isSecurityCamera')) {
      this.mAction.updateIsSecurityCamera(false);
      GlobalContext.get().setObject('isSecurityCamera', false);
      GlobalContext.get().setObject('isSecureMode', false);
      this.setNotShowLockScreen();
      let isAppLock = await AppLockUtil.getInstance().isPhotoAppLocked();
      if (!isAppLock) {
        GlobalContext.get().setCameraShotKey('');
        this.mAction.setCameraShotKey('');
      }
      this.mAction.refreshThumbnail();
    }
  }

  private setNotShowLockScreen(): void {
    try {
      HiLog.i(TAG, 'setShowOnLockScreen false.');
      GlobalContext.get().getWindowStage()?.setShowOnLockScreen(false);
    } catch (e) {
      HiLog.i(TAG, `setShowOnLockScreen error: ${JSON.stringify(e)}.`);
    }
  }
}

export default CommonEventManager;