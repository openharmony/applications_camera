/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import { Action } from '../actions/Action'

let initState = {
  useThumbnail: false,
  isResumeVideo: false,
  isContinueVideo: false,
  isStartVideo: false,
  isRecordingPaused: false,
  videoState: 'beforeTakeVideo',
  recordingTime: 0,
  recordingTimeDisplay: '00:00'
}

export default function RecordReducer(state = initState, action: {
  type: string,
  data: any
}) {
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
    default:
      return state;
  }
  return state;
}