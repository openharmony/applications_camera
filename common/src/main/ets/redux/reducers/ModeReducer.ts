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
import lazy { ActionType } from '../actions/ActionType';
import type { ActionData } from '../actions/Action';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { OhCombinedState } from '../ReduxConfig';
import lazy { execReduxReducer, initReduxStateMap } from '../ReducerUtil';
import lazy { CameraActionType } from '../actions/CameraActionType';

export type ModeState = {
  mode: ModeType,
  isShowBigText: boolean,
  isShowMorePage: boolean,
  isEditMorePage: boolean,
  isShowNightBigText: boolean,
  isShowBurstCaptureBigText: boolean,
  isNeedDisShowingMode: boolean
};

const modeStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initModeStateMap(): Map<string, object> {
  const initState: ModeState = {
    mode: ModeType.PHOTO,
    isShowBigText: false,
    isShowMorePage: false,
    isEditMorePage: false,
    isShowNightBigText: false,
    isShowBurstCaptureBigText: false,
    isNeedDisShowingMode: false,
  };
  return initReduxStateMap(initState, modeStateMap);
}

const modeReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setModeReducerMap(): void {
  modeReducerMap.set(CameraActionType.CHANGE_MODE, (action: ActionData) => {
    return { mode: action.data.mode };
  });

  modeReducerMap.set(ActionType.DISABLE_MODE_BAR_CHANGED, (action: ActionData) => {
    return { isNeedDisShowingMode: action.data.isNeedDisShowingMode };
  });

  modeReducerMap.set(ActionType.ACTION_UPDATE_SHOW_BIG_TEXT_FLAG, (action: ActionData) => {
    return {
      isShowBigText: action.data.isShowBigText
    };
  });

  modeReducerMap.set(ActionType.ACTION_SHOW_MORE_PAGE, (action: ActionData) => {
    return {
      isShowMorePage: action.data.isShowMorePage
    };
  });

  modeReducerMap.set(ActionType.ACTION_EDIT_MORE_PAGE, (action: ActionData) => {
    return {
      isEditMorePage: action.data.isEditMorePage
    };
  });

  modeReducerMap.set(ActionType.ACTION_UPDATE_SHOW_NIGHT_BIG_TEXT_FLAG, (action: ActionData) => {
    return {
      isShowNightBigText: action.data.isShowNightBigText
    };
  });

  modeReducerMap.set(ActionType.ACTION_UPDATE_SHOW_BURST_CAPTURE_BIG_TEXT_FLAG, (action: ActionData) => {
    return {
      isShowBurstCaptureBigText: action.data.isShowBurstCaptureBigText
    };
  });

  modeReducerMap.set(CameraActionType.INIT, (action: ActionData) => {
    return {
      mode: action.data.mode
    };
  });

  modeReducerMap.set(CameraActionType.SWITCH_CAMERA_CHANGE_MODE, (action: ActionData) => {
    return { mode: action.data.mode };
  });

  modeReducerMap.set(ActionType.ACTION_SWITCH_CAMERA_CHANGE_MODE_ONLY, (action: ActionData) => {
    return { mode: action.data.mode };
  });

  modeReducerMap.set(CameraActionType.WARM_START_WITH_MODE_AND_POS, (action: ActionData) => {
    return { mode: action.data.mode };
  });
}

export function modeReducer(state: OhCombinedState, action: ActionData): string[] {
  if (modeReducerMap.size <= 0) {
    setModeReducerMap();
  }
  return execReduxReducer(state, action, modeReducer.name, modeReducerMap, initModeStateMap);
}