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
import type { ActionData } from '../actions/Action';
import lazy { ActionType } from '../actions/ActionType';
import lazy { execReduxReducer, initReduxStateMap } from '../ReducerUtil';
import lazy { OhCombinedState } from '../ReduxConfig';

export type SecurityCameraState = {
  isSecurityCamera: boolean,
  cameraShotKey: string,
  thumbnailReminderShow: boolean,
  appLockReminderShow: boolean
};

const securityCameraStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initSecurityCameraStateMap(): Map<string, object> {
  const initState: SecurityCameraState = {
    isSecurityCamera: false,
    cameraShotKey: '',
    thumbnailReminderShow: false,
    appLockReminderShow: false
  };
  return initReduxStateMap(initState, securityCameraStateMap);
}

const securityCameraReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setSecurityCameraReducerMap(): void {
  securityCameraReducerMap.set(ActionType.ACTION_IS_SECURITY_CAMERA, (action: ActionData) => {
    return {
      isSecurityCamera: action.data.isSecurityCamera
    };
  });

  securityCameraReducerMap.set(ActionType.ACTION_CAMERA_SHOT_KEY, (action: ActionData) => {
    return {
      cameraShotKey: action.data.cameraShotKey
    };
  });

  securityCameraReducerMap.set(ActionType.ACTION_THUMBNAIL_REMINDER_SHOW, (action: ActionData) => {
    return {
      thumbnailReminderShow: action.data.thumbnailReminderShow
    };
  });

  securityCameraReducerMap.set(ActionType.ACTION_APP_LOCK_REMINDER_SHOW, (action: ActionData) => {
    return {
      appLockReminderShow: action.data.appLockReminderShow
    };
  });
}

export function securityCameraReducer(state: OhCombinedState, action: ActionData): string[] {
  if (securityCameraReducerMap.size <= 0) {
    setSecurityCameraReducerMap();
  }
  return execReduxReducer(state, action, securityCameraReducer.name, securityCameraReducerMap,
    initSecurityCameraStateMap);
}