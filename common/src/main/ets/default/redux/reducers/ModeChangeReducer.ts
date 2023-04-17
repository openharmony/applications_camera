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

import { ActionData } from '../actions/Action'
import { ACTION_CHANGE_PREVIEW_SIZE, ACTION_CHANGE_SHUTTER_BUTTON } from '../actions/ModeChange'
import { UIDATA_TAB_ITEM } from '../actions/UiData'

export type ModeChangeState = {
  number: number,
  res: Resource,
  tabItem: string[]
}

const initState: ModeChangeState = {
  number: 154,
  res: $r('app.media.icon'),
  tabItem: ['', 'flash', 'zoom', 'focus', 'setup']
}

export default function ModeChangeReducer(state = initState, action: ActionData): ModeChangeState {
  switch (action.type) {
  case ACTION_CHANGE_PREVIEW_SIZE:
    return { ...state, number: action.data.size}
  case ACTION_CHANGE_SHUTTER_BUTTON:
    return { ...state, res: action.data.res}
  case UIDATA_TAB_ITEM:
    return { ...state, tabItem: action.data.tabItem}
  default:
    return state;
  }
}