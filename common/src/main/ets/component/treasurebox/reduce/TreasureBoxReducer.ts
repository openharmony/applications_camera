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

import type { ActionData } from '../../../redux/actions/Action';
import lazy { OhCombinedState } from '../../../redux';
import lazy { execReduxReducer, initReduxStateMap } from '../../../redux/ReducerUtil';
import lazy { TreasureBoxActionType } from '../../../redux/actions/TreasureBoxActionType';

export type TreasureBoxState = {
  isOpen: boolean
};

const treasureBoxStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initTreasureBoxStateMap(): Map<string, object> {
  const initState: TreasureBoxState = {
    isOpen: false,
  };
  return initReduxStateMap(initState, treasureBoxStateMap);
}

const treasureBoxReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setTreasureBoxReducerMap(): void {
  treasureBoxReducerMap.set(TreasureBoxActionType.ACTION_SET_TREASURE_BOX_STATUS, (action: ActionData) => {
    return {
      isOpen: action.data.isOpen
    };
  });
}

export function treasureBoxReducer(state: OhCombinedState, action: ActionData): string[] {
  if (treasureBoxReducerMap.size <= 0) {
    setTreasureBoxReducerMap();
  }
  return execReduxReducer(state, action, treasureBoxReducer.name, treasureBoxReducerMap, initTreasureBoxStateMap);
}