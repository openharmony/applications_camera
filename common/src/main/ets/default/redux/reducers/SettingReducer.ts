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

import type { ActionData } from '../actions/Action';
import { Action } from '../actions/Action';

export type SettingState = {
  isAssGridViewShow: string,
  isShowtimeLapse: boolean,
  isCloseFlag: boolean,
  isShowSettingView: boolean,
  opacityValueForTabBar: number
}

const initState = {
  isAssGridViewShow: '0',
  isShowtimeLapse: false,
  isCloseFlag: false,
  isShowSettingView: false,
  opacityValueForTabBar: 0
}

export function settingReducer(state = initState, action: ActionData): SettingState {
  switch (action.type) {
    case Action.ACTION_ASSISTIVE_GRID_VIEW:
      return {
        ...state, isAssGridViewShow: action.data.isAssGridViewShow
      };
    case Action.ACTION_CHANGE_TIME_LAPSE:
      return {
        ...state, isShowtimeLapse: action.data.isShowtimeLapse
      };
    case Action.ACTION_CLOSE_DIALOG:
      return {
        ...state, isCloseFlag: action.data.isCloseFlag
      };
    case Action.ACTION_SHOW_SETTING_VIEW:
      return {
        ...state, isShowSettingView: action.data.isShowSettingView
      };
    case Action.ACTION_UPDATE_OPACITY_TAB_BAR:
      return {
        ...state, opacityValueForTabBar: action.data.opacityValueForTabBar
      };
    default:
      return state;
  }
}