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

import lazy { ActionType } from '../actions/ActionType';
import type { ActionData } from '../actions/Action';
import lazy { OhCombinedState } from '../ReduxConfig';
import lazy { execReduxReducer, initReduxStateMap } from '../ReducerUtil';

export type PreviewState = {
  xComponentWidth: number,
  xComponentHeight: number
};

const previewStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initPreviewStateMap(): Map<string, object> {
  const initState: PreviewState = {
    xComponentWidth: 0,
    xComponentHeight: 0
  };
  return initReduxStateMap(initState, previewStateMap);
}

const previewReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setPreviewReducerMap(): void {
  previewReducerMap.set(ActionType.ACTION_CHANGE_X_COMPONENT_SIZE, (action: ActionData) => {
    return {
      xComponentWidth: action.data.xComponentWidth, xComponentHeight: action.data.xComponentHeight
    };
  });
}

export function previewReducer(state: OhCombinedState, action: ActionData): string[] {
  if (previewReducerMap.size <= 0) {
    setPreviewReducerMap();
  }
  return execReduxReducer(state, action, previewReducer.name, previewReducerMap, initPreviewStateMap);
}