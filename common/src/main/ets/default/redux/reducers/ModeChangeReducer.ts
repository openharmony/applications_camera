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

import { ACTION_CHANGE_PREVIEW_SIZE, ACTION_CHANGE_SHUTTER_BUTTON } from '../actions/ModeChange'
import { UIDATA_TAB_ITEM } from '../actions/UiData'

let initState = {
  number: 154,
  res: "app.media.icon",
  tabItem: ['', 'flash', 'zoom', 'focus', 'setup']
}

export default function ModeChangeReducer(state = initState, action: {
  type: string,
  data: any
}) {
  switch (action.type) {
    case ACTION_CHANGE_PREVIEW_SIZE:
      return { ...state, number: action.data.size}
    case ACTION_CHANGE_SHUTTER_BUTTON:
      return { ...state, res: action.data.res}
    case UIDATA_TAB_ITEM:
      return { ...state, tabItem: action.data}
    default:
      return state;
  }
  return state;
}