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

import type { ActionData } from '../../redux/actions/Action';
import type { PositionType } from '../../utils/types';
import display from '@ohos.display';
import lazy { execReduxReducer, initReduxStateMap } from '../../redux/ReducerUtil';
import lazy { OhCombinedState } from '../../redux';

export class CollapsActionType {
  public static readonly ACTION_INIT_COLLAPS_STATUS = 'ACTION_INIT_COLLAPS_STATUS';
  public static readonly ACTION_CHANGE_COLLAPS_STATUS = 'ACTION_CHANGE_COLLAPS_STATUS';
  public static readonly ACTION_CHANGE_VDE_COLLAPSED_STATUS = 'ACTION_CHANGE_VDE_COLLAPSED_STATUS';
  public static readonly ACTION_CHANGE_SHOW_LANDSCAPE = 'ACTION_CHANGE_SHOW_LANDSCAPE';
  public static readonly ACTION_CHANGE_SHOW_TRICOLLAPS = 'ACTION_CHANGE_SHOW_TRICOLLAPS';
  public static readonly ACTION_CHANGE_VDE_SHOW_TYPE = 'ACTION_CHANGE_VDE_SHOW_TYPE';
  public static readonly ACTION_CHANGE_COLLAPS_DISPLAY_MODE = 'ACTION_CHANGE_COLLAPS_DISPLAY_MODE';
  public static readonly ACTION_CHANGE_SHOW_HALF_COLLAPS_LEM = 'ACTION_CHANGE_SHOW_HALF_COLLAPS_LEM';
  public static readonly ACTION_LANDSCAPE_STATUS_CHANGE = 'ACTION_LANDSCAPE_STATUS_CHANGE';
  public static readonly ACTION_LANDSCAPE_SEMI_COLLAPSED_BLACK_AREA_CLICKED =
    'ACTION_LANDSCAPE_SEMI_COLLAPSED_BLACK_AREA_CLICKED';
  public static readonly ACTION_SMALL_COLLAPS_SCREEN_SEMI_COLLAPSED_BLACK_AREA_CLICKED =
    'ACTION_SMALL_COLLAPS_SCREEN_SEMI_COLLAPSED_BLACK_AREA_CLICKED';
  public static readonly ACTION_LOW_ANGLE_SHOT_VIEW = 'ACTION_LOW_ANGLE_SHOT_VIEW';
  public static readonly ACTION_SHOW_BLACK = 'ACTION_SHOW_BLACK';
  public static readonly ACTION_CHANGE_HORIZONTAL_LEVEL_SIZE = 'ACTION_CHANGE_HORIZONTAL_LEVEL_SIZE';
  public static readonly ACTION_NEED_RE_FOREGROUND = 'ACTION_NEED_RE_FOREGROUND';
  public static readonly ACTION_CHANGE_DENSITY = 'ACTION_CHANGE_DENSITY';
  public static readonly ACTION_CHANGE_VDE_INNER_MODE_BAR = 'ACTION_CHANGE_VDE_INNER_MODE_BAR';
  public static readonly ACTION_REFRESH_COLLAPSED_TREASURE_BOX = 'ACTION_REFRESH_COLLAPSED_TREASURE_BOX';
  public static readonly ACTION_CHANGE_VDE_COLLAPSED_ON_FOREGROUND = 'ACTION_CHANGE_VDE_COLLAPSED_ON_FOREGROUND';
  public static readonly ACTION_REFRESH_VDE_INNER_FUNCTIONS = 'ACTION_REFRESH_VDE_INNER_FUNCTIONS';
  public static readonly ACTION_ON_CHANGE_SHOW_LANDSCAPE_DONE = 'ACTION_ON_CHANGE_SHOW_LANDSCAPE_DONE';
}

export type CollapsState = {
  isShowLandscape: boolean,
  isShowTricollaps: boolean,
  isShowSemiCollapsed: boolean,
  isVdeLandscape: boolean,
  isVdeSemiCollapsed: boolean,
  isVdeCollapsed: boolean,
  isHalfCollapsLEM: boolean,
  isShowDefault: boolean,
  collapsStatus: display.FoldStatus,
  previewArea: PositionType,
  isShowFlipTipView: boolean,
  isShowLowAngleShotView: boolean,
  isShowBlack: boolean,
  needReForeground: boolean,
  density: number,
  isVdeCollapsedOnForeground: boolean
};

/* instrument ignore file */

const collapsStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initCollapsStateMap(): Map<string, object> {
  const initState: CollapsState = {
    isShowLandscape: false,
    isShowTricollaps: false,
    isShowSemiCollapsed: false,
    isVdeLandscape: false,
    isVdeSemiCollapsed: false,
    isVdeCollapsed: false,
    isHalfCollapsLEM: false,
    needReForeground: false,
    isShowDefault: true,
    collapsStatus: display.FoldStatus.FOLD_STATUS_FOLDED,
    previewArea: {
      x: 0,
      y: 0
    },
    isShowFlipTipView: false,
    isShowLowAngleShotView: false,
    isShowBlack: false,
    density: 3.125,
    isVdeCollapsedOnForeground: true
  };
  return initReduxStateMap(initState, collapsStateMap);
}

const collapsReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setCollapsReducerMap(): void {
  collapsReducerMap.set(CollapsActionType.ACTION_CHANGE_SHOW_LANDSCAPE, (action: ActionData) => {
    const isShowLandscape: boolean = action.data.isShowLandscape;
    const isShowTricollaps: boolean = action.data.isShowTricollaps;
    const isShowSemiCollapsed: boolean = action.data.isShowSemiCollapsed;
    return {
      isShowLandscape: isShowLandscape,
      isShowSemiCollapsed: isShowSemiCollapsed,
      isShowDefault: !isShowLandscape,
      isShowTricollaps: isShowTricollaps
    };
  });

  collapsReducerMap.set(CollapsActionType.ACTION_CHANGE_VDE_COLLAPSED_ON_FOREGROUND, (action: ActionData) => {
    const isVdeCollapsedOnForeground: boolean = action.data.isVdeCollapsedOnForeground;
    return {
      isVdeCollapsedOnForeground: isVdeCollapsedOnForeground
    };
  });

  collapsReducerMap.set(CollapsActionType.ACTION_CHANGE_VDE_SHOW_TYPE, (action: ActionData) => {
    const isVdeLandscape: boolean = action.data.isVdeLandscape;
    const isVdeSemiCollapsed: boolean = action.data.isVdeSemiCollapsed;
    const isVdeCollapsed: boolean = (isVdeLandscape || isVdeSemiCollapsed) ? false : true;
    return {
      isVdeLandscape: isVdeLandscape, isVdeSemiCollapsed: isVdeSemiCollapsed, isVdeCollapsed: isVdeCollapsed
    };
  });

  collapsReducerMap.set(CollapsActionType.ACTION_CHANGE_SHOW_HALF_COLLAPS_LEM, (action: ActionData) => {
    const isHalfCollapsLEM: boolean = action.data.isHalfCollapsLEM;
    return {
      isHalfCollapsLEM: isHalfCollapsLEM
    };
  });

  collapsReducerMap.set(CollapsActionType.ACTION_INIT_COLLAPS_STATUS, (action: ActionData) => {
    return {
      collapsStatus: action.data.collapsStatus
    };
  });

  collapsReducerMap.set(CollapsActionType.ACTION_CHANGE_COLLAPS_STATUS, (action: ActionData) => {
    return {
      collapsStatus: action.data.collapsStatus
    };
  });

  collapsReducerMap.set(CollapsActionType.ACTION_CHANGE_COLLAPS_DISPLAY_MODE, (action: ActionData) => {
    return {
      isShowLandscape: false,
      isShowTricollaps: false,
      isShowSemiCollapsed: false,
      isShowDefault: false,
      isShowFlipTipView: false
    };
  });

  collapsReducerMap.set(CollapsActionType.ACTION_LOW_ANGLE_SHOT_VIEW, (action: ActionData) => {
    return {
      isShowLowAngleShotView: action.data.isShowLowAngleShotView
    };
  });

  collapsReducerMap.set(CollapsActionType.ACTION_SHOW_BLACK, (action: ActionData) => {
    return {
      isShowBlack: action.data.isShowBlack
    };
  });

  collapsReducerMap.set(CollapsActionType.ACTION_NEED_RE_FOREGROUND, (action: ActionData) => {
    const needReForeground: boolean = action.data.needReForeground;
    return {
      needReForeground: needReForeground
    };
  });

  collapsReducerMap.set(CollapsActionType.ACTION_CHANGE_DENSITY, (action: ActionData) => {
    const density: number = action.data.density;
    return {
      density: density
    };
  });
}

export function collapsReducer(state: OhCombinedState, action: ActionData): string[] {
  if (collapsReducerMap.size <= 0) {
    setCollapsReducerMap();
  }
  return execReduxReducer(state, action, collapsReducer.name, collapsReducerMap, initCollapsStateMap);
}
