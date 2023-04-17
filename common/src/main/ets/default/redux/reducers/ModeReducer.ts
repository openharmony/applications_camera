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

export type ModeState = {
  isInitiated: boolean,
  mode: string,
  curMode: string,
  isShowBigText: boolean,
  modeIndex: number,
  swipeModeIndex: number,
  isShowMoreList: boolean,
  modeChangeDone: boolean,
}

const initState: ModeState = {
  isInitiated: false,
  mode: 'PHOTO',
  curMode: 'PHOTO',
  isShowBigText: false,
  modeIndex: 1,
  swipeModeIndex: 1,
  isShowMoreList: false,
  modeChangeDone: false,
}

export default function ModeReducer(state = initState, action: ActionData): ModeState {
  switch (action.type) {
  case Action.ACTION_SWIPE_MODE_DONE:
    return { ...state, modeChangeDone: action.data.modeChangeDone }
  case Action.ACTION_INIT_MODE:
    return { ...state, mode: action.data.mode, isInitiated: true }
  case Action.ACTION_CHANGE_MODE:
    return { ...state, mode: action.data.mode }
  case Action.ACTION_SET_MODE:
    return { ...state, mode: action.data.mode }
  case Action.ACTION_UPDATE_MODE:
    return { ...state, curMode: action.data.mode }
  case Action.ACTION_UPDATE_MODE_INDEX:
    return { ...state, modeIndex: action.data.modeIndex }
  case Action.ACTION_SWIPE_MODE:
    return {...state, swipeModeIndex: action.data.swipeModeIndex}
  case Action.ACTION_UPDATE_SHOW_BIG_TEXT_FLAG:
    return { ...state, isShowBigText: action.data.isShowBigText }
  case Action.ACTION_UPDATE_SHOW_MORE_LIST:
    return {...state, isShowMoreList: action.data.isShowMoreList}
  default:
    return state;
  }
}