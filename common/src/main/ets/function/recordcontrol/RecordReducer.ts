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
/* instrument ignore file */
import lazy { OhCombinedState } from '../../redux';
import type { ActionData } from '../../redux/actions/Action';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { execReduxReducer, initReduxStateMap } from '../../redux/ReducerUtil';
import lazy { RecordingState } from './RecordAction';

export type RecordState = {
  recordingState: RecordingState, // 录制状态：录制前、录制时、已暂停
  videoTimerState: boolean, // 录制计时框是否上树
  recordingTime: number, // 录制计时时间
  recordingTimeDisplay: string, // 录制计时显示
  startTimeSeconds: number, // 开始录像的时候记录的毫秒值
  uselessSeconds: number, // 继续和暂停之间没有录像的毫秒值总和
  videoErrorCode: number, //录制底层上报error code
  videoErrorMsg: string, // 录制底层上报error msg
  videoUri: string,
  isRecordTimeComponentLarge: boolean, // 录像计时组件是否处于大字体期间
  isSupportAutoFrameRate: boolean, // 是否支持动态帧率
  isKeepFlowingRecording: boolean, // 是否不断流录制中
};

const TAG: string = 'recordReducer';

const recordStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initRecordStateMap(): Map<string, object> {
  const initState: RecordState = {
    recordingState: RecordingState.READY, // 省略初始化和release阶段，后面有需要可以添加
    videoTimerState: false,
    recordingTime: 0,
    recordingTimeDisplay: '00:00',
    startTimeSeconds: -1,
    uselessSeconds: 0,
    videoErrorCode: -1,
    videoErrorMsg: '',
    videoUri: '',
    isRecordTimeComponentLarge: false,
    isSupportAutoFrameRate: false,
    isKeepFlowingRecording: false,
  };
  return initReduxStateMap(initState, recordStateMap);
}

const recordReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setRecordReducerMap(): void {
  recordReducerMap.set(RecordActionType.START, (action: ActionData) => {
    return {
      recordingState: RecordingState.STARTING,
      uselessSeconds: 0,
      startTimeSeconds: 0,
      videoTimerState: true
    };
  });

  recordReducerMap.set(RecordActionType.STARTED, (action: ActionData) => {
    return {
      recordingState: RecordingState.RECORDING
    };
  });

  recordReducerMap.set(RecordActionType.PAUSE, (action: ActionData) => {
    return {
      recordingState: RecordingState.PAUSING
    };
  });

  recordReducerMap.set(RecordActionType.PAUSED, (action: ActionData) => {
    return {
      recordingState: RecordingState.PAUSED
    };
  });

  recordReducerMap.set(RecordActionType.RESUME, (action: ActionData) => {
    return {
      recordingState: RecordingState.RESUMING
    };
  });

  recordReducerMap.set(RecordActionType.RESUMED, (action: ActionData) => {
    return {
      recordingState: RecordingState.RECORDING
    };
  });

  recordReducerMap.set(RecordActionType.STOP, (action: ActionData) => {
    return {
      recordingState: RecordingState.STOPPING,
      videoTimerState: false,
      isRecordTimeComponentLarge: false
    };
  });

  recordReducerMap.set(RecordActionType.STOPPED, (action: ActionData) => {
    return {
      recordingState: RecordingState.READY
    };
  });

  recordReducerMap.set(RecordActionType.ERROR, (action: ActionData) => {
    return {
      videoErrorCode: action.data.code,
      videoErrorMsg: action.data.msg,
      isRecordTimeComponentLarge: false
    };
  });

  recordReducerMap.set(ActionType.ACTION_RECORD_START_SECONDS, (action: ActionData) => {
    return {
      startTimeSeconds: action.data.startTimeSeconds
    };
  });

  recordReducerMap.set(ActionType.ACTION_RECORD_USELESS_SECONDS, (action: ActionData) => {
    return {
      uselessSeconds: action.data.uselessSeconds
    };
  });

  recordReducerMap.set(RecordActionType.VIDEO_ON_SAVE, (action: ActionData) => {
    return {
      videoUri: action.data.videoUri
    };
  });

  recordReducerMap.set(RecordActionType.UPDATE_RECORDING_TIMER_COMPONENT_LARGE_STATE, (action: ActionData) => {
    return {
      isRecordTimeComponentLarge: action.data.isRecordTimeComponentLarge
    };
  });

  recordReducerMap.set(RecordActionType.EMIT_VIDEO_AUTO_FRAME_RATE, (action: ActionData) => {
    return {
      isSupportAutoFrameRate: action.data.isSupportAutoFrameRate
    };
  });

  recordReducerMap.set(RecordActionType.RECORD_KEEP_FLOWING, (action: ActionData) => {
    return {
      isKeepFlowingRecording: action.data.isKeepFlowingRecording
    };
  });
}

export function recordReducer(state: OhCombinedState, action: ActionData): string[] {
  if (recordReducerMap.size <= 0) {
    setRecordReducerMap();
  }
  return execReduxReducer(state, action, recordReducer.name, recordReducerMap, initRecordStateMap);
}