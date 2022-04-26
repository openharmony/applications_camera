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

import { Action } from '../actions/Action.ets'

let initState = {
  surfaceId: 0,
  xComponentChangeFlag: true,
  xComponentWidth: '',
  xComponentHeight: '',
  isShowPreview: false
}

export default function PreviewReducer(state = initState, action: {
  type: string,
  data: any
}) {
  switch (action.type) {
    case Action.ACTION_UPDATE_SURFACE_ID:
      return { ...state, surfaceId: action.data.surfaceId }
    case Action.ACTION_PREPARE_SURFACE:
      return { ...state, surfaceId: action.data.surfaceId }
    case Action.ACTION_CHANGE_X_COMPONENT_SIZE:
      return { ...state, xComponentWidth: action.data.xComponentWidth, xComponentHeight: action.data.xComponentHeight}
    case Action.ACTION_UPDATE_X_COMPONENT_CHANGE_FLAG:
      return { ...state, xComponentChangeFlag: action.data.xComponentChangeFlag }
    case Action.ACTION_UPDATE_SHOW_PREVIEW_FLAG:
      return { ...state, isShowPreview: action.data.isShowPreview }
    default:
      return state;
  }
  return state;
}