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

import { AnyAction, Dispatch, Middleware, MiddlewareAPI } from '../core/redux'

/**
 * Middleware to log the behaviors of dispatch.
 * 
 * @param store the created old store
 * @returns (next: Dispatch) => (newDispatch: Dispatch), by input the old dispatch, new dispatch
 * can be obtained.
 */
export const logger: Middleware = (store: MiddlewareAPI) => (next: Dispatch<AnyAction>) => (action: AnyAction) => {
  console.info(`logger: dispatch ${JSON.stringify(action)}, store: ${JSON.stringify(store.getState())}`)
  const result = next(action)
  console.info(`logger: new state ${JSON.stringify(store.getState())}`)
  return result
}