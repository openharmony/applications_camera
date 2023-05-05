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

import { AsyncManager } from '../worker/AsyncManager'
import type { Message } from '../worker/AsyncManager'
import { EventBusManager } from '../worker/eventbus/EventBusManager'
import { Log } from '../utils/Log'
import { createStore, combineReducers, applyMiddleware } from '../redux/core/ohredux/index'
import { logger } from './middlewares/logger'
import { reduxWorkerMiddle } from './middlewares/ReduxWorkerMiddle'
import CameraInitReducer from './reducers/CameraInitReducer'
import type { CameraInitState } from './reducers/CameraInitReducer'
import ContextReducer from './reducers/ContextReducer'
import type { ContextState } from './reducers/ContextReducer'
import CameraReducer from './reducers/CameraReducer'
import type { CameraState } from './reducers/CameraReducer'
import PreviewReducer from './reducers/PreviewReducer'
import type { PreviewState } from './reducers/PreviewReducer'
import CaptureReducer from './reducers/CaptureReducer'
import type { CaptureState } from './reducers/CaptureReducer'
import ModeChangeReducer from './reducers/ModeChangeReducer'
import type { ModeChangeState } from './reducers/ModeChangeReducer'
import ModeReducer from './reducers/ModeReducer'
import type { ModeState } from './reducers/ModeReducer'
import SettingReducer from './reducers/SettingReducer'
import type { SettingState } from './reducers/SettingReducer'
import RecordReducer from './reducers/RecordReducer'
import type { RecordState } from './reducers/RecordReducer'
import ZoomReducer from './reducers/ZoomReducer'
import type { ZoomState } from './reducers/ZoomReducer'
import type { ActionData } from './actions/Action'
import type { CombinedState, Dispatch, Unsubscribe } from './core/redux'
import type { MapDispatchProp, MapStateProp } from './core/ohredux/connect'

const TAG = '[store]:'
const STORE_KEY = 'CAMERA_REDUX_STORE'

export type OhCombinedState = CombinedState<{
  CameraInitReducer: CameraInitState;
  ContextReducer: ContextState;
  CameraReducer: CameraState;
  PreviewReducer: PreviewState;
  CaptureReducer: CaptureState;
  RecordReducer: RecordState;
  ModeChangeReducer: ModeChangeState;
  ModeReducer: ModeState
  SettingReducer: SettingState
  ZoomReducer: ZoomState
}>

export function getStore(): {
  getState: () => OhCombinedState,
  dispatch: Dispatch<ActionData>,
  subscribe: (listener: () => void) => Unsubscribe,
  connect: (mapStateProp: MapStateProp, mapDispatchProp: MapDispatchProp) => (target: any) => void
  } {
  Log.info(`${TAG} store init.`)
  if (!AppStorage.Has(STORE_KEY)) {
    const store = createStore(
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
        ZoomReducer,
      }),
      applyMiddleware(logger, reduxWorkerMiddle)
    )
    AppStorage.SetOrCreate(STORE_KEY, store)
    AsyncManager.getInstance().onMessage = (msg: Message) => {
      const action = {type: '', data: undefined, tag: 'FROM_WORKER'}
      Log.info(`${TAG} store dispatch msg: ${JSON.stringify(msg)}`)
      action.type = msg.type
      action.data = msg.data
      store.dispatch(action)
      EventBusManager.getInstance().getEventBus().emit(msg.type, [msg.data])
    }

  }
  return AppStorage.Get(STORE_KEY)
}