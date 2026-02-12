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
import type { FunctionId } from './functionproperty/FunctionId';
import type { RenderLocation } from './functionproperty/RenderLocation';
import type { ConflictParam } from './ConflictParam';
import lazy { execReduxReducer, initReduxStateMap } from '../../redux/ReducerUtil';
import lazy { getStates } from '../../redux/Store';
import lazy { OhCombinedState } from '../../redux/ReduxConfig';
import lazy { FunctionActionType } from '../../redux/actions/FunctionActionType';

const TAG: string = 'FunctionReducer';

export type FunctionState = {
  // 此处functionValue为过程值,与function的Value并不完全等价,以对应function的getValue为准,注意区分.
  functionValueMap: Map<FunctionId, unknown>
  functionRenderMap: Map<RenderLocation, Set<FunctionId>>
  functionConflictParamMap: Map<FunctionId, ConflictParam>
};

const functionStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initFunctionStateMap(): Map<string, object> {
  const initState: FunctionState = {
    functionValueMap: new Map(),
    functionRenderMap: new Map(),
    functionConflictParamMap: new Map()
  };
  return initReduxStateMap(initState, functionStateMap);
}

const functionReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setFunctionReducerMap(): void {
  functionReducerMap.set(FunctionActionType.ACTION_INIT_FUNCTION_VAL, (action: ActionData) => {
    let funcValueMap = getStates().get<Map<FunctionId, unknown>>('functionReducer', 'functionValueMap');
    funcValueMap.set(action.data.id, action.data.value);
    return {
      functionValueMap: funcValueMap
    };
  });

  functionReducerMap.set(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, (action: ActionData) => {
    let funcValueMap = getStates().get<Map<FunctionId, unknown>>('functionReducer', 'functionValueMap');
    funcValueMap.set(action.data.id, action.data.value);
    return {
      functionValueMap: funcValueMap
    };
  });

  functionReducerMap.set(FunctionActionType.ACTION_ADD_FUNCTION, (action: ActionData) => {
    let funcRenderMap = getStates().get<Map<RenderLocation, Set<FunctionId>>>('functionReducer', 'functionRenderMap');
    let funcRenderSet = funcRenderMap.get(action.data.location);
    if (!funcRenderSet) {
      funcRenderSet = new Set();
    }
    funcRenderMap.set(action.data.location, new Set(funcRenderSet.add(action.data.id)));
    return {
      functionRenderMap: funcRenderMap
    };
  });

  functionReducerMap.set(FunctionActionType.ACTION_REMOVE_FUNCTION, (action: ActionData) => {
    let funcRenderMap = getStates().get<Map<RenderLocation, Set<FunctionId>>>('functionReducer', 'functionRenderMap');
    let funcRenderSet = funcRenderMap.get(action.data.location);
    if (!funcRenderSet) {
      funcRenderSet = new Set();
    }
    if (funcRenderSet.has(action.data.id)) {
      funcRenderSet.delete(action.data.id);
      funcRenderMap.set(action.data.location, new Set(funcRenderSet));
    }
    return {
      functionRenderMap: funcRenderMap
    };
  });

  functionReducerMap.set(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM, (action: ActionData) => {
    let funcConflictParamMap = getStates().get<Map<FunctionId, ConflictParam>>('functionReducer', 'functionConflictParamMap');
    funcConflictParamMap.set(action.data.id, action.data.conflictParam);
    return {
      functionConflictParamMap: funcConflictParamMap
    };
  });
}

export function functionReducer(state: OhCombinedState, action: ActionData): string[] {
  if (functionReducerMap.size <= 0) {
    setFunctionReducerMap();
  }
  return execReduxReducer(state, action, functionReducer.name, functionReducerMap, initFunctionStateMap);
}