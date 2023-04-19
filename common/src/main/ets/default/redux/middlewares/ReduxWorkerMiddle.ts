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

import { AsyncManager, Message } from '../../worker/AsyncManager'
import { Log } from '../../utils/Log'
import { AnyAction, Dispatch, Middleware, MiddlewareAPI, Store } from '../core/redux'

const TAG = '[reduxWorkerMiddle]:'

/**
 * Middleware to emit async operation like switching camera and so on.
 * 
 * @param store the created old store
 * @returns (next: Dispatch) => (action: AnyAction) => anyAction
 */
export const reduxWorkerMiddle: Middleware = (store: MiddlewareAPI) => (next: Dispatch) => (action: AnyAction) => {
  const asyncManager = AsyncManager.getInstance()
  const uiAction = { type: undefined, data: undefined }
  if (Object.keys(action).length == 2) {
    asyncManager.postMessage(action as Message)
  }
  uiAction.type = action.type
  uiAction.data = action.data
  //  EventBusManager.getInstance().getEventBus().emit(action.type, [action.data])
  const result = next(uiAction)
  Log.info(`${TAG} logger: new state ${JSON.stringify(store.getState())}`)
  return result
}