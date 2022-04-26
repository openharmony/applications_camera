/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import { AsyncManager } from '../../Utils/AsyncManager'
import { CLog } from '../../Utils/CLog'
import EventBusManager from '../../Utils/EventBusManager'

const TAG: string = '[ReduxWorkerMiddle]:'

export const ReduxWorkerMiddle = store => next => action => {
  let asyncManager = AsyncManager.getInstance()
  let uiAction = { type: undefined, data: undefined }
  if (Object.keys(action).length == 2) {
    asyncManager.postMessage(action)
  }
  uiAction.type = action.type
  uiAction.data = action.data
  //  EventBusManager.getInstance().getEventBus().emit(action.type, [action.data])
  let result = next(uiAction)
  CLog.info(`${TAG} logger: new state ${JSON.stringify(store.getState())}`)
  return result
}