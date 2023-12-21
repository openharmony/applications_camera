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

import type { ActionData } from '../actions/Action';
import type { Dispatch } from '../store';

export interface Middleware {
  (): (next: Dispatch) => (action: ActionData) => ActionData
}

export interface Enhancer {
  (dispatch: Dispatch): Dispatch
}

export function applyMiddleware(...middlewares: Middleware[]): Enhancer {
  return (dispatch: Dispatch) => {
    const chain: Function[] = middlewares.map(middleware => middleware());
    return compose(chain)(dispatch);
  };
}

function compose(functions: Function[]): Function {
  if (functions.length === 0) {
    return <T = {}>(arg: T): T => arg;
  }
  if (functions.length === 1) {
    return functions[0];
  }

  return functions.reduce(
    (a, b): Function => (...args): void => a(b(...args))
  );
}