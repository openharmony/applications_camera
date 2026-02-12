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
import lazy { UiStateMode } from '../actions/Action';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import type { ActionData } from '../actions/Action';
import lazy { ActionType } from '../actions/ActionType';
import lazy { UIOperationType } from '../../component/uicomponent/UIOperationType';
import lazy { OhCombinedState } from '../ReduxConfig';
import lazy { execReduxReducer, initReduxStateMap } from '../ReducerUtil';
import lazy { PhotoBrowserActionType } from '../actions/PhotoBrowserActionType';
import lazy { ContextActionType } from '../actions/ContextActionType';
import lazy { CameraActionType } from '../actions/CameraActionType';

export type ContextState = {
  uiEnable: boolean,
  uiStateMode: UiStateMode,
  excludeComponent: string,
  deviceHeight: number,
  footBarHeight: number,
  isThirdPartyCall: boolean,
  action: string,
  direction: number,
  instantDirection: WindowDirection,
  rotateAngle: number,
  settingAngle: number,
  isPickerBack: boolean,
  exposureTime: number,
  estimatedCaptureDuration: number,
  displayRotation: number,
  isScreenAlwaysOn: boolean,
  isDuringSavePowerMode: boolean,
  isLocked: boolean,
  isForeground: boolean,
  isIntro: boolean,
  isHighContrastText: boolean,
  isViewVisibility: boolean,
  motionDirection: number,
  lockRotation: number
};

const contextStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initContextStateMap(): Map<string, object> {
  const initState: ContextState = {
    uiEnable: true,
    uiStateMode: UiStateMode.NONE,
    deviceHeight: 0,
    footBarHeight: 0,
    isThirdPartyCall: false,
    action: '',
    direction: WindowDirection.TOP,
    instantDirection: WindowDirection.TOP,
    rotateAngle: 0,
    settingAngle: 0,
    isPickerBack: false,
    exposureTime: 0,
    estimatedCaptureDuration: 0,
    excludeComponent: UIOperationType.NULL,
    displayRotation: 0,
    isScreenAlwaysOn: false,
    isDuringSavePowerMode: false,
    isLocked: false,
    isForeground: false,
    isIntro: false,
    isHighContrastText: false,
    isViewVisibility: true,
    motionDirection: 0,
    lockRotation: 0
  };
  return initReduxStateMap(initState, contextStateMap);
}

const contextReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setContextReducerMap(): void {
  contextReducerMap.set(ActionType.ACTION_UI_STATE, (action: ActionData) => {
    return {
      uiEnable: action.data.enable,
      uiStateMode: action.data.uiStateMode,
      excludeComponent: action.data.excludeComponent
    };
  });
  contextReducerMap.set(ActionType.ACTION_THIRD_PARTY_CALL, (action: ActionData) => {
    return {
      isThirdPartyCall: action.data.isThirdPartyCall, action: action.data.action
    };
  });
  contextReducerMap.set(ActionType.ACTION_NIGHT_CAPTURE_START, (action: ActionData) => {
    return {
      exposureTime: action.data.exposureTime
    };
  });
  contextReducerMap.set(ActionType.ACTION_ESTIMATED_CAPTURE_DURATION, (action: ActionData) => {
    return {
      estimatedCaptureDuration: action.data.estimatedCaptureDuration
    };
  });
  contextReducerMap.set(ActionType.ACTION_RESET_EXPOSURE_TIME, (action: ActionData) => {
    return {
      exposureTime: action.data.exposureTime
    };
  });
  contextReducerMap.set(ActionType.ACTION_DIRECTION_CHANGE, (action: ActionData) => {
    return {
      direction: action.data.direction, rotateAngle: action.data.rotate, settingAngle: action.data.settingAngle
    };
  });
  contextReducerMap.set(ActionType.ACTION_INSTANT_DIRECTION_CHANGE, (action: ActionData) => {
    return {
      instantDirection: action.data.instantDirection
    };
  });
  contextReducerMap.set(CameraActionType.CHANGE_MODE, (action: ActionData) => {
    return {
      uiEnable: false, uiStateMode: action.data.uiStateMode
    };
  });
  contextReducerMap.set(CameraActionType.CHANGE_OUTPUT_TYPE, (action: ActionData) => {
    return {
      uiEnable: false, uiStateMode: action.data.uiStateMode
    };
  });
  contextReducerMap.set(ContextActionType.ABILITY_ON_FOREGROUND, (action: ActionData) => {
    return {
      isForeground: true, isViewVisibility: true
    };
  });
  contextReducerMap.set(ContextActionType.ABILITY_ON_BACKGROUND, (action: ActionData) => {
    return {
      isPickerBack: action.data.isPickerBack, isForeground: false
    };
  });
  contextReducerMap.set(ContextActionType.ABILITY_ON_INTRO, (action: ActionData) => {
    return {
      isIntro: action.data.isIntro
    };
  });
  contextReducerMap.set(ContextActionType.UPDATE_SCREEN_ON_STATE, (action: ActionData) => {
    return {
      isScreenAlwaysOn: action.data.isScreenOn
    };
  });
  contextReducerMap.set(ContextActionType.UPDATE_SAVE_POWER_MODE_STATE, (action: ActionData) => {
    return {
      isDuringSavePowerMode: action.data.isDuringSavePowerMode
    };
  });
  contextReducerMap.set(ContextActionType.SCREEN_LOCKED_STATE, (action: ActionData) => {
    return {
      isLocked: action.data.isLocked
    };
  });
  contextReducerMap.set(ContextActionType.HIGH_CONTRAST_TEXT_STATE, (action: ActionData) => {
    return {
      isHighContrastText: action.data.isHighContrastText
    };
  });
  contextReducerMap.set(PhotoBrowserActionType.SET_VIEW_VISIBILITY, (action: ActionData) => {
    return {
      isViewVisibility: action.data.isVisibility
    };
  });
  contextReducerMap.set(ActionType.ACTION_MOTION_DIRECTION_CHANGE, (action: ActionData) => {
    return {
      motionDirection: action.data.motionDirection
    };
  });
  contextReducerMap.set(ActionType.ACTION_LOCK_ROTATION_CHANGE, (action: ActionData) => {
    return {
      lockRotation: action.data.lockRotation
    };
  });
}

export function contextReducer(state: OhCombinedState, action: ActionData): string[] {
  if (contextReducerMap.size <= 0) {
    setContextReducerMap();
  }
  return execReduxReducer(state, action, contextReducer.name, contextReducerMap, initContextStateMap);
}