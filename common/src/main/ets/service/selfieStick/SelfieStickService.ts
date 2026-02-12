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
import lazy { KeyCode } from '@kit.InputKit';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { getStates, OhCombinedState } from '../../redux';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { CaptureAction } from '../../function/capture/CaptureAction';
import lazy { HiLog } from '../../utils/HiLog';
import window from '@ohos.window';
import lazy { RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { CameraAction, CameraRunningState } from '../../camera/uithread/CameraAction';
import lazy { Action } from '../../redux/actions/Action';
import lazy { MoreModeConfig } from '../../mode/MoreModeConfig';
import { power } from '@kit.BasicServicesKit';

/* instrument ignore file */
/*
 * 自拍杆适配相机
 */
const VCR2OptionsUp: inputConsumer.KeyOptions = {
  preKeys: [],
  finalKey: KeyCode.KEYCODE_VCR2,
  isFinalKeyDown: true,
  finalKeyDownDuration: 0
};

const videoNextKeyOptionsUp: inputConsumer.KeyOptions = {
  preKeys: [],
  finalKey: KeyCode.KEYCODE_VIDEO_NEXT,
  isFinalKeyDown: true,
  finalKeyDownDuration: 0
};

const zoomInKeyOptionsUp: inputConsumer.KeyOptions = {
  preKeys: [],
  finalKey: KeyCode.KEYCODE_ZOOMIN,
  isFinalKeyDown: true,
  finalKeyDownDuration: 0,
};


const zoomOutKeyOptionsUp: inputConsumer.KeyOptions = {
  preKeys: [],
  finalKey: KeyCode.KEYCODE_ZOOMOUT,
  isFinalKeyDown: true,
  finalKeyDownDuration: 0
};

const zoomInKeyOptionsUpLongPress: inputConsumer.KeyOptions = {
  preKeys: [KeyCode.KEYCODE_DPAD_UP],
  finalKey: KeyCode.KEYCODE_ZOOMIN,
  isFinalKeyDown: true,
  finalKeyDownDuration: 0,
};

const zoomOutKeyOptionsUpLongPress: inputConsumer.KeyOptions = {
  preKeys: [KeyCode.KEYCODE_DPAD_DOWN],
  finalKey: KeyCode.KEYCODE_ZOOMOUT,
  isFinalKeyDown: true,
  finalKeyDownDuration: 0
};

export class SelfieStickKey {
  keyValue: number;
  preKeys: number | undefined;
}

const TAG: string = 'SelfieStickService';
export class SelfieStickService {
  private static sInstanceSelfieStickService: SelfieStickService;
  private mStoreManager: StoreManager = StoreManager.getInstance();
  private selfStickSubscribeStatus: boolean = false;
  public static getInstance(): SelfieStickService {
    if (!SelfieStickService.sInstanceSelfieStickService) {
      SelfieStickService.sInstanceSelfieStickService = new SelfieStickService();
    }
    return SelfieStickService.sInstanceSelfieStickService;
  }

  public selfieStickSubscribe(): void {
    if (this.selfStickSubscribeStatus) {
      HiLog.w(TAG, 'selfStick have Subscribed');
      return;
    }
    this.selfStickSubscribeStatus = true;
    inputConsumer.on('key', zoomInKeyOptionsUp, (keyOptions: inputConsumer.KeyOptions) => this.selfieStickEventListener(keyOptions));
    inputConsumer.on('key', zoomOutKeyOptionsUp, (keyOptions: inputConsumer.KeyOptions) => this.selfieStickEventListener(keyOptions));
    inputConsumer.on('key', zoomInKeyOptionsUpLongPress, (keyOptions: inputConsumer.KeyOptions) => this.selfieStickEventListener(keyOptions));
    inputConsumer.on('key', zoomOutKeyOptionsUpLongPress, (keyOptions: inputConsumer.KeyOptions) => this.selfieStickEventListener(keyOptions));
    inputConsumer.on('key', videoNextKeyOptionsUp, (keyOptions: inputConsumer.KeyOptions) => this.selfieStickEventListener(keyOptions));
    inputConsumer.on('key', VCR2OptionsUp, (keyOptions: inputConsumer.KeyOptions) => this.selfieStickEventListener(keyOptions));
    HiLog.i(TAG, 'selfStick Subscribe success');
  }

  private selfieStickEventListener(keyOptions: inputConsumer.KeyOptions): void {
    if (this.isIntercept(keyOptions?.finalKey)) {
      return;
    }
    HiLog.i(TAG, `selfieStickEventListener on, finalKey: ${keyOptions?.finalKey}, isFinalKeyDown: ${keyOptions?.isFinalKeyDown}.`);
    let key: SelfieStickKey = new SelfieStickKey();
    key.keyValue = keyOptions?.finalKey;
    key.preKeys = keyOptions?.preKeys[0];
    AppStorage.setOrCreate('isSelfieLongPress', key.preKeys !== undefined);
    this.selfieStickEventModeChange(key);
    this.mStoreManager.postMessage(CaptureAction.selfieStickEvent(key));
  }

  public selfieStickUnSubscribe(): void {
    this.selfStickSubscribeStatus = false;
    inputConsumer.off('key', zoomInKeyOptionsUp);
    inputConsumer.off('key', zoomOutKeyOptionsUp);
    inputConsumer.off('key', zoomInKeyOptionsUpLongPress);
    inputConsumer.off('key', zoomOutKeyOptionsUpLongPress);
    inputConsumer.off('key', videoNextKeyOptionsUp);
    inputConsumer.off('key', VCR2OptionsUp);
  }

  private isIntercept(finalKey: number): boolean {
    let state: OhCombinedState = getStates();
    let isShowMorePage: boolean = state.get<boolean>('modeReducer', 'isShowMorePage');
    let windowStageEventType = AppStorage.get('windowStageEventType');
    const isLongExposure = AppStorage.get<boolean>('longExposureShutter') ? AppStorage.get<boolean>('longExposureShutter') : false;
    HiLog.i(TAG, `isIntercept isLongExposure: ${isLongExposure}`)
    return state.get<ModeType>('modeReducer', 'mode') === ModeType.NONE ||
      isShowMorePage || isLongExposure ||
    state.get<boolean>('uiReducer', 'showPicker') ||
    state.get<boolean>('thumbnailReducer', 'photoBrowserStatus') ||
    state.get<boolean>('settingViewReducer', 'isShowSettingView') ||
    state.get<boolean>('settingReducer', 'isShowtimeLapse') ||
    state.get<boolean>('securityCameraReducer', 'thumbnailReminderShow') ||
    state.get<boolean>('securityCameraReducer', 'appLockReminderShow') ||
    state.get<boolean>('customFilterStyleReducer', 'isOpenPhotoPicker') ||
      windowStageEventType === window.WindowStageEventType.INACTIVE;
  }

  private selfieStickEventModeChange(data: SelfieStickKey): void {
    if (getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState')
      === CameraRunningState.UNINITIALIZED) {
      power.wakeup('');
      return;
    }
    if (!data || !data.keyValue) {
      return;
    }
    HiLog.i(TAG, `selfieStickEventModeChange:${data.keyValue}`);
    const isSavePowerMode: boolean = getStates().get<boolean>('contextReducer', 'isDuringSavePowerMode');
    const videoState: RecordingState = getStates().get<RecordingState>('recordReducer', 'recordingState');
    if (videoState !== RecordingState.READY || isSavePowerMode) {
      return;
    }
    let oldMode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
    let newMode: ModeType = ModeType.PHOTO;
    if (data.keyValue === KeyCode.KEYCODE_VCR2) {
      HiLog.i(TAG, `selfieStickEventModeChange:${MoreModeConfig.getInstance().getGridMode()}, ${oldMode}`);
      if (MoreModeConfig.getInstance().getGridMode().includes(oldMode)) {
        MoreModeConfig.getInstance().modifyMoreModeListAndName(ModeType.MORE);
      }
      if (oldMode !== ModeType.PHOTO) {
        newMode = ModeType.PHOTO;
      } else {
        newMode = ModeType.VIDEO;
      }
      StoreManager.getInstance().postMessage(CameraAction.changeMode(newMode));
      AppStorage.setOrCreate('startOrUserChangeToModeLast', newMode);
      StoreManager.getInstance().postMessage(Action.updateXComponentShot(oldMode, newMode));
    }
  }
}