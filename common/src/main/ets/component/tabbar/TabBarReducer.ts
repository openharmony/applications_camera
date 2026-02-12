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
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { RenderLocation } from '../../function/core/functionproperty/RenderLocation';
import lazy { OhCombinedState } from '../../redux';
import lazy { execReduxReducer, initReduxStateMap } from '../../redux/ReducerUtil';
import lazy { TabBarActionType } from '../../redux/actions/TabBarActionType';

export type TabBarState = {
  tabBarSelector: FunctionId,
  tabBarSelectorLocation: RenderLocation
};

const tabBarStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initTabBarStateMap(): Map<string, object> {
  const initState: TabBarState = {
    tabBarSelector: FunctionId.NONE,
    tabBarSelectorLocation: RenderLocation.NONE
  };
  return initReduxStateMap(initState, tabBarStateMap);
}

const tabBarReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setTabBarReducerMap(): void {
  tabBarReducerMap.set(TabBarActionType.ACTION_CHANGE_TAB_BAR_SELECTOR, (action: ActionData) => {
    return {
      tabBarSelector: action.data.functionId, tabBarSelectorLocation: action.data.renderLocation
    };
  });
}

export function tabBarReducer(state: OhCombinedState, action: ActionData): string[] {
  if (tabBarReducerMap.size <= 0) {
    setTabBarReducerMap();
  }
  return execReduxReducer(state, action, tabBarReducer.name, tabBarReducerMap, initTabBarStateMap);
}