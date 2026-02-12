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
import { TAG } from '@ohos/hypium/src/main/Constant';
import lazy { HiLog } from '../utils/HiLog';
import lazy { ActionData } from './actions/Action';
import lazy { OhCombinedState } from './ReduxConfig';

/*
 * 初始化各StateMap状态通用方法
 */
export function initReduxStateMap(initState, contextStateMap): Map<string, object> {
  Object.keys(initState).forEach((stateName: string) => {
    contextStateMap.set(stateName, initState[stateName]);
  }); // 方案测试使用,实际直接set性能更优,但容易破坏封装性
  return contextStateMap;
}

/*
 * 执行各ReduxReducer触发状态刷新通用方法
 */
export function execReduxReducer(state: OhCombinedState, action: ActionData, reducerName: string,
  reducerMap: Map<string, Function>, initReduxStateFunc: Function): string[] {
  if (!reducerMap.has(action.type)) {
    return undefined;
  }
  let stateMap = state.getStateMap<Map<string, object>>(reducerName); // 获取stateMap引用
  if (!stateMap) {
    stateMap = initReduxStateFunc();
    state.setStateMap(reducerName, stateMap);
  }
  let dataObj = reducerMap.get(action.type)(action); // 获取需刷新的多个变量列表
  if (!dataObj) {
    return undefined;
  }
  let stateKeys: string[] = Object.keys(dataObj);
  stateKeys.forEach((stateKey: string) => {
    stateMap.set(stateKey, dataObj[stateKey]); // 执行刷新
  });
  return stateKeys; // 后续可进一步性能优化至按stateKey维度
}
