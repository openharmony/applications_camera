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

import inputConsumer from '@ohos.multimodalInput.inputConsumer';
import lazy { KeyCode } from '@ohos.multimodalInput.keyCode';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { getStates, OhCombinedState } from '../../redux';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { CaptureAction } from '../../function/capture/CaptureAction';
import lazy { HiLog } from '../../utils/HiLog';
import window from '@ohos.window';
import lazy { ContextAction } from '../../redux/actions/ContextAction';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { PersistType, PreferencesService } from '../preferences/PreferencesService';
import lazy { PropTag } from '../preferences/PropTag';
import camera from '@ohos.multimedia.camera';
import lazy { Action } from '../../redux/actions/Action';
import power from '@ohos.power';
import display from '@ohos.display';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { DisplayService } from '../UIAdaptive/DisplayService';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { UIOperationType } from '../../component/uicomponent/UIOperationType';

const volumeUpKeyOptionsDown: inputConsumer.KeyOptions = {
  preKeys: [],
  finalKey: KeyCode.KEYCODE_VOLUME_UP,
  isFinalKeyDown: true,
  finalKeyDownDuration: 0
};

const volumeUpKeyOptionsUp: inputConsumer.KeyOptions = {
  preKeys: [],
  finalKey: KeyCode.KEYCODE_VOLUME_UP,
  isFinalKeyDown: false,
  finalKeyDownDuration: 0
};

const volumeDownKeyOptionsDown: inputConsumer.KeyOptions = {
  preKeys: [],
  finalKey: KeyCode.KEYCODE_VOLUME_DOWN,
  isFinalKeyDown: true,
  finalKeyDownDuration: 0
};

const volumeDownKeyOptionsUp: inputConsumer.KeyOptions = {
  preKeys: [],
  finalKey: KeyCode.KEYCODE_VOLUME_DOWN,
  isFinalKeyDown: false,
  finalKeyDownDuration: 0
};

const powerKeyOptions: inputConsumer.KeyOptions = {
  preKeys: [],
  finalKey: KeyCode.KEYCODE_POWER,
  isFinalKeyDown: false,
  finalKeyDownDuration: 0
};

const TAG: string = 'VolumeShutterService';

export class VolumeShutterService {
  private mStoreManager: StoreManager = StoreManager.getInstance();
  private volumeIsDown: boolean = false;
  private volumeKeySubscribeStatus: boolean = false;
  private static sInstanceVolumeShutterService: VolumeShutterService;

  public static getInstance(): VolumeShutterService {
    if (!VolumeShutterService.sInstanceVolumeShutterService) {
      VolumeShutterService.sInstanceVolumeShutterService = new VolumeShutterService();
    }
    return VolumeShutterService.sInstanceVolumeShutterService;
  }


  public volumeKeySubscribe(): void {
    if (this.volumeKeySubscribeStatus || !power.isActive() || DeviceInfo.isPc()) {
      HiLog.w(TAG, 'volumeKey have Subscribe');
      return;
    }
    if (AppStorage.get<boolean>('isBackground')) {
      HiLog.i(TAG, 'background is Unsubscribe');
      return;
    }
    this.volumeKeySubscribeStatus = true;
    inputConsumer.on('key', volumeUpKeyOptionsDown, (keyOptions: inputConsumer.KeyOptions) => this.volumeKeyEventListener(keyOptions));
    inputConsumer.on('key', volumeUpKeyOptionsUp, (keyOptions: inputConsumer.KeyOptions) => this.volumeKeyEventListener(keyOptions));
    inputConsumer.on('key', volumeDownKeyOptionsDown, (keyOptions: inputConsumer.KeyOptions) => this.volumeKeyEventListener(keyOptions));
    inputConsumer.on('key', volumeDownKeyOptionsUp, (keyOptions: inputConsumer.KeyOptions) => this.volumeKeyEventListener(keyOptions));
    HiLog.i(TAG, 'volumeKey: Subscribed');
  }

  public volumeKeyUnsubscribe(): void {
    if (DeviceInfo.isPc()) {
      return;
    }
    HiLog.i(TAG, 'volumeKey: Unsubscribed begin');
    if (this.volumeIsDown && AppStorage.get('windowStageEventType') === window.WindowStageEventType.INACTIVE) {
      this.mStoreManager.postMessage(CaptureAction.volumeKeyEvent(false));
      this.volumeIsDown = false;
    }
    if (DisplayService.getInstance().getCollapsDisplayMode() === display.FoldDisplayMode.FOLD_DISPLAY_MODE_COORDINATION) {
      HiLog.i(TAG, 'coordination do not exit');
      return;
    }
    this.volumeKeySubscribeStatus = false;
    inputConsumer.off('key', volumeUpKeyOptionsDown);
    inputConsumer.off('key', volumeUpKeyOptionsUp);
    inputConsumer.off('key', volumeDownKeyOptionsDown);
    inputConsumer.off('key', volumeDownKeyOptionsUp);
    HiLog.i(TAG, 'volumeKey: Unsubscribed');
  }

  private volumeKeyEventListener(keyOptions: inputConsumer.KeyOptions): void {
    HiLog.i(TAG, `volumeKeyEventListener on, finalKey: ${keyOptions?.finalKey}, isFinalKeyDown: ${keyOptions?.isFinalKeyDown}.`);
    const isDown: boolean = keyOptions?.isFinalKeyDown;
    if (isDown === undefined) {
      HiLog.i(TAG, 'volumeKeyEventListener isDown undefined.');
      return;
    }
    if ((this.volumeIsDown && isDown) || this.isIntercept()) {
      HiLog.i(TAG, 'volumeKeyEventListener isDown true, isIntercept:' + this.isIntercept());
      return;
    }
    this.volumeIsDown = isDown;
    if (!isDown && getStates().get<boolean>('contextReducer', 'isDuringSavePowerMode')) {
      // 仅用于省电模式下退出省电模式
      this.mStoreManager.postMessage(ContextAction.volumeKeyUp());
      return;
    }
    // 音量键按下快门需响应动效
    this.mStoreManager.postMessage(CaptureAction.volumeKeyEvent(isDown));
  }

  private isImmersiveIntercept(): boolean {
    let mainTrigCompo: UIOperationType = getStates().get<UIOperationType>('uiReducer', 'mainTrigCompo');
    return mainTrigCompo === UIOperationType.ZOOM_BAR || mainTrigCompo === UIOperationType.EXTEND_BAR ||
      mainTrigCompo === UIOperationType.PRO_BAR;
  }

  private isIntercept(): boolean {
    let state: OhCombinedState = getStates();
    let mode: ModeType = state.get<ModeType>('modeReducer', 'mode');
    let isShowMorePage: boolean = state.get<boolean>('modeReducer', 'isShowMorePage');
    let showPicker: boolean = state.get<boolean>('uiReducer', 'showPicker');
    let photoBrowserStatus: boolean = state.get<boolean>('thumbnailReducer', 'photoBrowserStatus');
    let photoBrowserTouchStatus: boolean = state.get<boolean>('thumbnailReducer', 'photoBrowserTouchStatus');
    let isShowSettingView: boolean = state.get<boolean>('settingViewReducer', 'isShowSettingView');
    let isShowtimeLapse: boolean = state.get<boolean>('settingReducer', 'isShowtimeLapse');
    let windowStageEventType = AppStorage.get('windowStageEventType');
    let thumbnailReminderShow: boolean = state.get<boolean>('securityCameraReducer', 'thumbnailReminderShow');
    let appLockReminderShow: boolean = state.get<boolean>('securityCameraReducer', 'appLockReminderShow');
    let isOpenPhotoPicker: boolean = state.get<boolean>('customFilterStyleReducer', 'isOpenPhotoPicker');
    let isImmersive: boolean = state.get<boolean>('uiReducer', 'isImmersive');

    let isIntercept = mode === ModeType.NONE || isShowMorePage || showPicker || photoBrowserStatus ||
      isShowSettingView || isShowtimeLapse || thumbnailReminderShow || appLockReminderShow || isOpenPhotoPicker ||
      windowStageEventType === window.WindowStageEventType.PAUSED || (isImmersive && this.isImmersiveIntercept()) ||
      (windowStageEventType === window.WindowStageEventType.INACTIVE);
    HiLog.i(TAG,
      `isIntercept mode ` + mode + ', showPicker ' + showPicker + ', photoBrowserStatus ' +
        photoBrowserStatus + ', isShowSettingView ' + isShowSettingView + ', isShowtimeLapse ' +
        isShowtimeLapse + ', thumbnailReminderShow ' + thumbnailReminderShow + ', appLockReminderShow ' +
        appLockReminderShow + ', windowStageEventType ' + windowStageEventType + ', photoBrowserTouchStatus ' +
        photoBrowserTouchStatus);
    isIntercept ||=  photoBrowserTouchStatus;
    HiLog.i(TAG, `isIntercept: ${isIntercept}`);
    return isIntercept;
  }
}