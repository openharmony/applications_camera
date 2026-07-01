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
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { audio } from '@kit.AudioKit';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';

/* instrument ignore file */
const TIP_DURING: number = 3000;

// 11 为音频框架新增source 类型，还未添加到sdk
const AUDIO_SOURCE = [
  audio.SourceType.SOURCE_TYPE_MIC,
  audio.SourceType.SOURCE_TYPE_VOICE_CALL,
  audio.SourceType.SOURCE_TYPE_VOICE_COMMUNICATION,
  audio.SourceType.SOURCE_TYPE_VOICE_MESSAGE,
  audio.SourceType.SOURCE_TYPE_CAMCORDER,
  audio.SourceType.SOURCE_TYPE_UNPROCESSED
];

const TAG = 'RecordController';

export enum RecordType {
  longClick = 'longClick',
  click = 'click'
}

export class RecordController {
  private static sInstance: RecordController;
  private recordType: RecordType = RecordType.click;

  private constructor() {
    const code = new BaseComponent().hashCode();
    EventBusManager.getInstance().getEventBus().on(RecordActionType.STOP, () => this.click(), code);
  }

  public static getInstance(): RecordController {
    if (!RecordController.sInstance) {
      RecordController.sInstance = new RecordController();
    }
    return RecordController.sInstance;
  }

  public longClick(): void {
    HiLog.i(TAG, 'RECORD_TRACK longClick change record type.');
    this.recordType = RecordType.longClick;
  }

  public getRecordType(): RecordType {
    return this.recordType;
  }

  public click(): void {
    HiLog.i(TAG, 'RECORD_TRACK  longClick change record type.');
    this.recordType = RecordType.click;
  }

  // 临时解决方案，拍照模式下，动态图片打开时，右滑录像
  private validateAudioAvailablePhoto(): boolean {
    let existExcludesScene: boolean = true;
    const audioManager = audio.getAudioManager();
    const captureInfo = audioManager.getStreamManager().getCurrentAudioCapturerInfoArraySync();
    const isAudioAvailable: boolean = captureInfo.every(item => {
      HiLog.i(TAG,
        `validateAudioAvailable capturerState: ${item.capturerState}, capturerState: ${item.capturerInfo.source},`);
      let isAvailable: boolean = true;
      if (item.capturerState === audio.AudioState.STATE_RUNNING && AUDIO_SOURCE.includes(item.capturerInfo.source)) {
        if (existExcludesScene && item.capturerInfo.source === audio.SourceType.SOURCE_TYPE_UNPROCESSED) {
          existExcludesScene = false;
        } else {
          isAvailable = false;
        }
      }
      return isAvailable;
    });
    HiLog.i(TAG, `validateAudioAvailable isAudioAvailable: ${isAudioAvailable}`);

    return isAudioAvailable;
  }

  public validateAudioAvailable(needExclude = false): boolean {
    return true;
  }

  public validateAudioAvailableWithOutPreRecord(needExclude = false): boolean {
    HiLog.i(TAG, `needExclude: ${needExclude}`);
    if (needExclude) {
      return this.validateAudioAvailablePhoto();
    }
    let source: audio.SourceType = audio.SourceType.SOURCE_TYPE_CAMCORDER;
    const captureInfo: audio.AudioCapturerInfo = {
      source,
      capturerFlags: 0
    };

    const streamManager = audio.getAudioManager().getStreamManager();
    // @ts-ignore
    const isRecordingAvailable: boolean = streamManager?.isRecordingAvailable?.(captureInfo);
    HiLog.i(TAG, `validateAudioAvailable isRecordingAvailable: ${isRecordingAvailable}, source: ${source}`);
    return isRecordingAvailable;
  }
}