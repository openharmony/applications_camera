/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import { Action, ActionData } from '../actions/Action'

export type RecordState = {
  useThumbnail: boolean,
  isResumeVideo: boolean,
  isContinueVideo: boolean,
  isStartVideo: boolean,
  isRecordingPaused: boolean,
  videoState: string,
  isBigVideoTimerVisible: boolean,
  isSmallVideoTimerVisible: boolean,
  isRecordingSpotVisible: boolean,
  recordingTime: number,
  recordingTimeDisplay: string
}

const initState: RecordState = {
  useThumbnail: false,
  isResumeVideo: false,
  isContinueVideo: false,
  isStartVideo: false,
  isRecordingPaused: false,
  videoState: 'beforeTakeVideo',
  isBigVideoTimerVisible: false,
  isSmallVideoTimerVisible: false,
  isRecordingSpotVisible: true,
  recordingTime: 0,
  recordingTimeDisplay: '00:00'
}

export default function RecordReducer(state = initState, action: ActionData): RecordState {
  switch (action.type) {
  case Action.ACTION_START_VIDEO_FLAG:
    return { ...state, isStartVideo: action.data.isStartVideo }
  case Action.ACTION_UPDATE_RECORDING_TIME:
    return { ...state, recordingTime: action.data.recordingTime }
  case Action.ACTION_UPDATE_RECORDING_TIME_DISPLAY:
    return { ...state, recordingTimeDisplay: action.data.recordingTimeDisplay }
  case Action.ACTION_UPDATE_VIDEO_STATE:
    return { ...state, videoState: action.data.videoState }
  case Action.ACTION_UPDATE_RECORDING_PAUSED:
    return { ...state, isRecordingPaused: action.data.isRecordingPaused }
  case Action.ACTION_UPDATE_BIG_VIDEO_TIMER_VISIBLE:
    return { ...state, isBigVideoTimerVisible: action.data.isBigVideoTimerVisible }
  case Action.ACTION_UPDATE_SMALL_VIDEO_TIMER_VISIBLE:
    return { ...state, isSmallVideoTimerVisible: action.data.isSmallVideoTimerVisible }
  case Action.ACTION_UPDATE_RECORDING_SPOT_VISIBLE:
    return { ...state, isRecordingSpotVisible: action.data.isRecordingSpotVisible }
  default:
    return state;
  }
}