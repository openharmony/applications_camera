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

import { Action, ActionData, UiStateMode } from '../actions/Action'

export type ContextState = {
  uiEnable: boolean,
  uiStateMode: UiStateMode,
  deviceHeight: number,
  footBarWidth: number,
  footBarHeight: number,
  isThirdPartyCall: boolean,
  isFaCall: boolean,
  permissionFlag: boolean,
  action: string,
  isKeepScreenOn: boolean,
  initShowFlag: boolean
}

const initState: ContextState = {
  uiEnable: true,
  uiStateMode: UiStateMode.NONE,
  deviceHeight: 0,
  footBarWidth: 0,
  footBarHeight: 0,
  isThirdPartyCall: false,
  isFaCall: false,
  permissionFlag: false,
  action: '',
  isKeepScreenOn: false,
  initShowFlag: false
}

export default function ContextReducer(state = initState, action: ActionData): ContextState {
  switch (action.type) {
  case Action.ACTION_UI_STATE:
    return { ...state, uiEnable: action.data.enable, uiStateMode: action.data.uiStateMode }
  case Action.ACTION_INIT_FOOT_BAR_WIDTH:
    return { ...state, footBarWidth: action.data.footBarWidth }
  case Action.ACTION_INIT_FOOT_BAR_HEIGHT:
    return { ...state, footBarHeight: action.data.footBarHeight }
  case Action.ACTION_THIRD_PARTY_CALL:
    return { ...state, isThirdPartyCall: action.data.isThirdPartyCall, action: action.data.action }
  case Action.ACTION_FA_CALL:
    return {...state, isFaCall: action.data.isFaCall}
  case Action.ACTION_SET_PERMISSION_FLAG:
    return { ...state, permissionFlag: action.data.permissionFlag }
  case Action.ACTION_INIT_ACTION:
    return { ...state, action: action.data.action }
  case Action.ACTION_KEEP_SCREEN_ON:
    return { ...state, isKeepScreenOn: action.data.isKeepScreenOn }
  case Action.ACTION_UPDATE_INIT_SHOW_FLAG:
    return { ...state, initShowFlag: action.data.initShowFlag }
  default:
    return state;
  }
}