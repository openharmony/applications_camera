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
import lazy { OhCombinedState } from '../ReduxConfig';
import lazy { execReduxReducer, initReduxStateMap } from '../ReducerUtil';

export type SettingState = {
  isAssGridViewShow: boolean,
  isFloatingShutterShow: boolean,
  isShowtimeLapse: boolean,
  isCloseFlag: boolean,
  restoreConfirmFlag: boolean,
  isLightPaintingFlashShow: boolean,
  nightSubRefreshTreasure: number,
  isNightStarPortraitFlashShow: boolean,
  isSmartBackSelfie: boolean,
  isAigcEnhanceOpened: boolean,
  isOpenFilter: boolean,
  isHdrOpen: boolean,
  isShowTimedShot: boolean,
};

const settingStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initSettingStateMap(): Map<string, object> {
  const initState = {
    isAssGridViewShow: false,
    isFloatingShutterShow: false,
    isShowtimeLapse: false,
    isCloseFlag: false,
    restoreConfirmFlag: false,
    isLightPaintingFlashShow: false,
    nightSubRefreshTreasure: 0,
    isNightStarPortraitFlashShow: false,
    isSmartBackSelfie: false,
    isAigcEnhanceOpened: false,
    isOpenFilter: false,
    isHdrOpen: false,
    isShowTimedShot: false,
  };
  return initReduxStateMap(initState, settingStateMap);
}

const settingReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setSettingReducerMap(): void {
  settingReducerMap.set(ActionType.ACTION_ASSISTIVE_GRID_VIEW, (action: ActionData) => {
    return {
      isAssGridViewShow: action.data.isAssGridViewShow
    };
  });

  settingReducerMap.set(ActionType.ACTION_SMART_BACK_SELFIE, (action: ActionData) => {
    return {
      isSmartBackSelfie: action.data.isSmartBackSelfie
    };
  });

  settingReducerMap.set(ActionType.ACTION_IS_OPEN_FILTER, (action: ActionData) => {
    return {
      isOpenFilter: action.data.isOpenFilter
    };
  });

  settingReducerMap.set(ActionType.ACTION_AIGC_ENHANCE, (action: ActionData) => {
    return {
      isAigcEnhanceOpened: action.data.isAigcEnhanceOpened
    };
  });
  settingReducerMap.set(ActionType.ACTION_NIGHT_SUB_REFRESH_TREASURE, (action: ActionData) => {
    return {
      nightSubRefreshTreasure: action.data.nightSubRefreshTreasure
    };
  });

  settingReducerMap.set(ActionType.ACTION_NIGHT_STAR_PORTRAIT_FLASH, (action: ActionData) => {
    return {
      isNightStarPortraitFlashShow: action.data.isNightStarPortraitFlashShow
    };
  });

  settingReducerMap.set(ActionType.ACTION_LIGHT_PAINTING_FLASH, (action: ActionData) => {
    return {
      isLightPaintingFlashShow: action.data.isLightPaintingFlashShow
    };
  });

  settingReducerMap.set(ActionType.ACTION_FLOATING_SHUTTER_BUTTON, (action: ActionData) => {
    return {
      isFloatingShutterShow: action.data.isFloatingShutterShow
    };
  });

  settingReducerMap.set(ActionType.ACTION_CHANGE_TIME_LAPSE, (action: ActionData) => {
    return {
      isShowtimeLapse: action.data.isShowtimeLapse
    };
  });

  settingReducerMap.set(ActionType.ACTION_CLOSE_DIALOG, (action: ActionData) => {
    return {
      isCloseFlag: action.data.isCloseFlag
    };
  });

  settingReducerMap.set(ActionType.ACTION_RESTORE_DIALOG_CONFIRM, (action: ActionData) => {
    return {
      restoreConfirmFlag: action.data.restoreConfirmFlag
    };
  });

  settingReducerMap.set(ActionType.ACTION_UPDATE_HDR_STATE, (action: ActionData) => {
    return {
      isHdrOpen: action.data.isHdrOpen
    };
  });

  settingReducerMap.set(ActionType.ACTION_CHANGE_TIMED_SHOT, (action: ActionData) => {
    return {
      isShowTimedShot: action.data.isShowTimedShot
    };
  });
}

export function settingReducer(state: OhCombinedState, action: ActionData): string[] {
  if (settingReducerMap.size <= 0) {
    setSettingReducerMap();
  }
  return execReduxReducer(state, action, settingReducer.name, settingReducerMap, initSettingStateMap);
}