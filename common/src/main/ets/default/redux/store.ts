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

import { AsyncManager } from '../Utils/AsyncManager'
import EventBusManager from '../Utils/EventBusManager'
import { CLog } from '../Utils/CLog'
import { createStore, combineReducers, applyMiddleware } from '../Utils/ohredux/index'
import { logger } from './middlewares/logger'
import { ReduxWorkerMiddle } from './middlewares/ReduxWorkerMiddle'
import CameraInitReducer from './reducers/CameraInitReducer'
import ContextReducer from './reducers/ContextReducer'
import CameraReducer from './reducers/CameraReducer'
import PreviewReducer from './reducers/PreviewReducer'
import CaptureReducer from './reducers/CaptureReducer'
import ModeChangeReducer from './reducers/ModeChangeReducer'
import ModeReducer from './reducers/ModeReducer'
import SettingReducer from './reducers/SettingReducer'
import RecordReducer from './reducers/RecordReducer'
import UiReducer from './reducers/UiReducer'

const TAG: string = '[store]:'
const STORE_KEY = 'CAMERA_REDUX_STORE'

export default function getStore(): {
  getState: Function,
  dispatch: Function,
  subscribe: Function,
  connect: Function
} {
  CLog.info(`${TAG} store init.`)
  if (!AppStorage.Has(STORE_KEY)) {
    let store = createStore(
    combineReducers({
      CameraInitReducer,
      ContextReducer,
      CameraReducer,
      PreviewReducer,
      CaptureReducer,
      RecordReducer,
      ModeChangeReducer,
      ModeReducer,
      SettingReducer,
      UiReducer
    }),
    applyMiddleware(logger, ReduxWorkerMiddle)
    )
    AppStorage.SetOrCreate(STORE_KEY, store)
    AsyncManager.getInstance().onMessage = (msg) => {
      let action = {type: undefined, data: undefined, tag: 'FROM_WORKER'}
      CLog.info(`${TAG} store dispatch msg: ${JSON.stringify(msg)}`)
      action.type = msg.type
      action.data = msg.data
      store.dispatch(action)
      EventBusManager.getInstance().getEventBus().emit(msg.type, [msg.data])
    }

  }
  return AppStorage.Get(STORE_KEY)
}