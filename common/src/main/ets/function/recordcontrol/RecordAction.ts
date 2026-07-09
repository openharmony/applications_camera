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

import type { ActionData } from '../../redux/actions/Action';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';

const PREFIX: string = 'RECORD_ACTION_';

export enum RecordingState {
  READY = 0, // 录制前
  STARTING = 1, // 准备开始录制
  RECORDING = 2, // 录制中
  PAUSING = 3, // 准备暂停录制
  PAUSED = 4, // 已暂停
  RESUMING = 5, // 准备恢复录制
  STOPPING = 6, // 准备结束录制
  ERROR = 7, // 录制 error 底层上报erro
}

export class RecordAction {

  public static start(isSoundEffect: boolean = true): ActionData {
    return {
      isEvent: true,
      type: RecordActionType.START,
      data: { isSoundEffect: isSoundEffect }
    };
  }

  public static setStartSeconds(startTimeSeconds: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_RECORD_START_SECONDS,
      data: { startTimeSeconds: startTimeSeconds }
    };
  }

  public static started(): ActionData {
    return {
      isEvent: true,
      type: RecordActionType.STARTED,
      data: {}
    };
  }

  public static pause(isManualChanged?: boolean): ActionData {
    return {
      isEvent: true,
      type: RecordActionType.PAUSE,
      data: { isManualChanged: isManualChanged }
    };
  }

  public static paused(): ActionData {
    return {
      isEvent: true,
      type: RecordActionType.PAUSED,
      data: {}
    };
  }

  public static resume(isManualChanged?: boolean): ActionData {
    return {
      isEvent: true,
      type: RecordActionType.RESUME,
      data: { isManualChanged: isManualChanged }
    };
  }

  public static resumed(): ActionData {
    return {
      isEvent: true,
      type: RecordActionType.RESUMED,
      data: {}
    };
  }

  public static stop(): ActionData {
    return {
      isEvent: true,
      type: RecordActionType.STOP,
      data: {}
    };
  }

  public static stopped(): ActionData {
    return {
      isEvent: true,
      type: RecordActionType.STOPPED,
      data: {}
    };
  }

  public static error(errorCode: number, errorMsg: string): ActionData {
    return {
      isEvent: true,
      type: RecordActionType.ERROR,
      data: { code: errorCode, msg: errorMsg }
    };
  }

  public static updateRecordingTimerComponentLargeState(isLarge: boolean): ActionData {
    return {
      type: RecordActionType.UPDATE_RECORDING_TIMER_COMPONENT_LARGE_STATE,
      data: { isRecordTimeComponentLarge: isLarge }
    };
  }

  public static emitVideoAutoFrameRate(isSupportAutoFrameRate: boolean): ActionData {
    return {
      isEvent: true,
      type: RecordActionType.EMIT_VIDEO_AUTO_FRAME_RATE,
      data: { isSupportAutoFrameRate: isSupportAutoFrameRate }
    };
  }

  public static keepFlowingRecording(isKeepFlowingRecording: boolean): ActionData {
    return {
      isEvent: true,
      type: RecordActionType.RECORD_KEEP_FLOWING,
      data: { isKeepFlowingRecording: isKeepFlowingRecording }
    };
  }

  public static recordPaused(): ActionData {
    return {
      isEvent: true,
      type: RecordActionType.RECORD_PAUSED,
      data: {}
    };
  }
}