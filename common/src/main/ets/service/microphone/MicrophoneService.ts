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

import lazy { HiLog } from '../../utils/HiLog';

import audio from '@ohos.multimedia.audio';
import lazy { TipService } from '../../component/tip/TipService';
import lazy { RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { getStates } from '../../redux';

const TAG: string = 'MicrophoneService';

export class MicrophoneService {
  private routingManager: audio.AudioRoutingManager = audio.getAudioManager().getRoutingManager();
  private microphoneSubscribeStatus: boolean = false;
  private static sInstanceMicrophoneService: MicrophoneService;

  public static getInstance(): MicrophoneService {
    if (!MicrophoneService.sInstanceMicrophoneService) {
      HiLog.d(TAG, 'new MicrophoneService');
      MicrophoneService.sInstanceMicrophoneService = new MicrophoneService();
    }
    return MicrophoneService.sInstanceMicrophoneService;
  }

  public microphoneSubscribe(): void {
    if (this.microphoneSubscribeStatus) {
      HiLog.d(TAG, 'Already Subscribe');
      return;
    }
    this.microphoneSubscribeStatus = true;
    try {
      //@ts-ignore
      this.routingManager?.isMicBlockDetectionSupported().then((support: boolean) => {
        HiLog.d(TAG, 'support.' + support);
        if (support) {
          //@ts-ignore
          this.routingManager?.on('micBlockStatusChanged', this.microphoneEventListener.bind(this));
        } else {
          this.microphoneSubscribeStatus = false;
        }
      });
    } catch (error) {
      this.microphoneSubscribeStatus = false;
      HiLog.e(TAG, `Subscribe error: ${error.code}.`);
    }
  }

  public microphoneUnsubscribe(): void {
    this.microphoneSubscribeStatus = false;
    HiLog.d(TAG, 'Unsubscribe.');
    try {
      //@ts-ignore
      this.routingManager?.off('micBlockStatusChanged');
    } catch (error) {
      HiLog.e(TAG, `Unsubscribe error: ${error.code}.`);
    }
  }

  //@ts-ignore
  private microphoneEventListener(deviceBlockStatusInfo: audio.DeviceBlockStatusInfo): void {
    if (deviceBlockStatusInfo?.blockStatus === 1) {
      if (getStates().get<RecordingState>('recordReducer', 'recordingState') === RecordingState.RECORDING) {
        TipService.getInstance().showTip($r('app.string.toast_microphone_blocked'), 3000, true);
      } else {
        HiLog.d(TAG, 'not recording');
      }
    }
  }
}