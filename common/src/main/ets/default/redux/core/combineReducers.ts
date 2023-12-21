/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import { Log } from '../../utils/Log';
import type { ActionData } from '../actions/Action';
import type { OhCombinedState } from '../store';

export type Reducer = (
  state: OhCombinedState | undefined,
  action: ActionData) => OhCombinedState;

export function combineReducers(reducers: Array<Function>): Reducer {
  return function combination(
    state: OhCombinedState | undefined,
    action: ActionData
  ) {
    const nextState: unknown = {};
    const currentState = state || {};
    reducers.forEach((reducer: Function) => {
      const previousStateForKey = currentState[reducer.name];
      const nextStateForKey = reducer(previousStateForKey, action);
      if (!nextStateForKey) {
        Log.error('reducer error, result is undefined.');
      }
      nextState[reducer.name] = nextStateForKey;
    });
    return nextState as OhCombinedState;
  };
}
