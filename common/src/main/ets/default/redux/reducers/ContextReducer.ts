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
  deviceHeight: 0,
  footBarWidth: 0,
  footBarHeight: 0,
  isThirdPartyCall: false,
  permissionFlag: false,
  action: ''
}

export default function ContextReducer(state = initState, action: {
  type: string,
  data: any
}) {
  switch (action.type) {
    case Action.ACTION_INIT_FOOT_BAR_WIDTH:
      return { ...state, footBarWidth: action.data.footBarWidth }
    case Action.ACTION_INIT_FOOT_BAR_HEIGHT:
      return { ...state, footBarHeight: action.data.footBarHeight }
    case Action.ACTION_THIRD_PARTY_CALL:
      return { ...state, isThirdPartyCall: action.data.isThirdPartyCall, action: action.data.action }
    case Action.ACTION_SET_PERMISSION_FLAG:
      return { ...state, permissionFlag: action.data.permissionFlag }
    case Action.ACTION_INIT_ACTION:
      return { ...state, action: action.data.action }
    default:
      return state;
  }
  return state;
}