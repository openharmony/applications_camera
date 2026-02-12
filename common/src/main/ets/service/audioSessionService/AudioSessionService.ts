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

import lazy { audio } from '@kit.AudioKit';
import lazy { BusinessError } from '@kit.BasicServicesKit';
import lazy { HiLog } from '../../utils/HiLog';

const AUDIO_STRATEGY: audio.AudioSessionStrategy = {
  concurrencyMode: audio.AudioConcurrencyMode.CONCURRENCY_PAUSE_OTHERS
};

const TAG = 'AudioSessionService';

/**
 * 用于触发音频焦点管理的服务类 在应用的生命周期foreground和background时调用
 */
export class AudioSessionService {
  /**
   * activateAudioSession 激活当前应用的音频会话
   * 在应用的生命周期foreground时主动调用
   */
  static activateAudioSession(): void {
    HiLog.i(TAG, 'activateAudioSession trigger');
    try {
      const audioSessionManager: audio.AudioSessionManager = audio.getAudioManager().getSessionManager();
      audioSessionManager.activateAudioSession(AUDIO_STRATEGY).then(() => {
        HiLog.i(TAG, 'activate audio session success');
      }).catch((err: BusinessError) => {
        HiLog.e(TAG, `error: ${err}`);
      });
    } catch (err) {
      HiLog.e(TAG, `getSessionManager error: ${err}`);
    }
  }

  /**
   * deactivateAudioSession 停用当前应用的音频会话
   * 在应用的生命周期background时主动调用
   */
  static deactivateAudioSession(): void {
    HiLog.i(TAG, 'deactivateAudioSession trigger');
    try {
      const audioSessionManager: audio.AudioSessionManager = audio.getAudioManager().getSessionManager();
      const isActivated = audioSessionManager.isAudioSessionActivated();
      if (isActivated) {
        audioSessionManager.deactivateAudioSession().then(() => {
          HiLog.i(TAG, 'deactivate audio session success');
        }).catch((err: BusinessError) => {
          HiLog.e(TAG, `error: ${err}`);
        });
      } else {
        HiLog.i(TAG, 'deactivateAudioSession failed because not activated');
      }
    } catch (err) {
      HiLog.e(TAG, `getSessionManager error: ${err}`);
    }
  }
}