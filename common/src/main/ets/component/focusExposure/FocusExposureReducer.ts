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

import camera from '@ohos.multimedia.camera';
import lazy { OhCombinedState } from '../../redux';
import type { ActionData } from '../../redux/actions/Action';
import lazy { FocusExposureActionType } from '../../redux/actions/FocusExposureActionType';
import lazy { execReduxReducer, initReduxStateMap } from '../../redux/ReducerUtil';
import lazy { LockLevel } from './FocusExposureHelper';

export type FocusState = {
  focusMode: number,
  focusPoint: camera.Point,
  isShowExposureRing: boolean,
  isShowFocus: boolean,
  isShowExposure: boolean,
  lockLevel: LockLevel,
  isSupportedFocusStateDetect: boolean,
  exposureMode: camera.ExposureMode,
  exposurePoint: camera.Point,
  exposureValue: number,
  smartControlLocked: boolean,
};

const resetState: Pick<FocusState, 'isShowFocus' | 'isShowExposureRing' | 'isShowExposure' | 'lockLevel'> = {
  isShowFocus: false,
  isShowExposureRing: false,
  isShowExposure: false,
  lockLevel: LockLevel.UNLOCK,
};

const focusStateMap: Map<string, object> = new Map(); // 维护局部state

export function initFocusStateMap(): Map<string, object> {
  const initState: FocusState = {
    ...resetState,
    focusMode: camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO,
    focusPoint: null,
    isSupportedFocusStateDetect: false,
    exposureMode: camera.ExposureMode.EXPOSURE_MODE_CONTINUOUS_AUTO,
    exposurePoint: null,
    exposureValue: 0,
    smartControlLocked: false,
  };
  return initReduxStateMap(initState, focusStateMap);
};

const focusExposureReducerMap: Map<string, Function> = new Map();

function setFocusExposureReducerMap(): void {
  focusExposureReducerMap.set(FocusExposureActionType.ACTION_HIDE_FOCUS_BOX, (action: ActionData) => {
    return { ...resetState };
  });

  focusExposureReducerMap.set(FocusExposureActionType.ACTION_CHANGE_FOCUS_DATA, (action: ActionData) => {
    return { focusMode: action.data.focusMode, focusPoint: action.data.focusPoint };
  });

  focusExposureReducerMap.set(FocusExposureActionType.ACTION_UPDATE_SHOW_EXPOSURE_RING, (action: ActionData) => {
    return { isShowExposureRing: action.data.isShowExposureRing };
  });

  focusExposureReducerMap.set(FocusExposureActionType.ACTION_UPDATE_SHOW_FOCUS, (action: ActionData) => {
    return { isShowFocus: action.data.isShowFocus };
  });

  focusExposureReducerMap.set(FocusExposureActionType.ACTION_UPDATE_SHOW_EXPOSURE, (action: ActionData) => {
    return { isShowExposure: action.data.isShowExposure };
  });

  focusExposureReducerMap.set(FocusExposureActionType.ACTION_CHANGE_EXPOSURE_DATA, ( action: ActionData) => {
    return {
      exposureMode: action.data.exposureMode,
      exposurePoint: action.data.exposurePoint,
      exposureValue: action.data.exposureValue
    };
  });

  focusExposureReducerMap.set(FocusExposureActionType.ACTION_UPDATE_LOCK_LEVEL, ( action: ActionData) => {
    return { lockLevel: action.data.lockLevel };
  });

  focusExposureReducerMap.set(FocusExposureActionType.ACTION_UPDATE_FOCUS_STATE_DETECT_SUPPORTED, (action: ActionData) => {
    return { isSupportedFocusStateDetect: action.data.isSupportedFocusStateDetect };
  });

  focusExposureReducerMap.set(FocusExposureActionType.ACTION_SMART_CONTROL_LOCK, (action: ActionData) => {
    return { smartControlLocked: action.data.smartControlLocked };
  });

  focusExposureReducerMap.set(FocusExposureActionType.ACTION_UPDATE_FOCUS_LOCKED, (action: ActionData) => {
    return { isFocusLocked: action.data.isFocusLocked };
  });
}

export function focusExposureReducer(state: OhCombinedState, action: ActionData): string[] {
  if (focusExposureReducerMap.size <= 0) {
    setFocusExposureReducerMap();
  }
  return execReduxReducer(state, action, focusExposureReducer.name, focusExposureReducerMap, initFocusStateMap);
}