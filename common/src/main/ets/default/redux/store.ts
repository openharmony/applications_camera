import { Message } from '../worker/AsyncManager';
import { AsyncManager } from '../worker/AsyncManager';
import { EventBusManager } from '../worker/eventbus/EventBusManager';
import { Log } from '../utils/Log';
import { applyMiddleware, combineReducers, createStore } from '../redux/core/ohredux/index';
import { logger } from './middlewares/logger';
import { reduxWorkerMiddle } from './middlewares/ReduxWorkerMiddle';
import type { CameraInitState } from './reducers/CameraInitReducer';
import CameraInitReducer from './reducers/CameraInitReducer';
import type { ContextState } from './reducers/ContextReducer';
import ContextReducer from './reducers/ContextReducer';
import type { CameraState } from './reducers/CameraReducer';
import CameraReducer from './reducers/CameraReducer';
import type { PreviewState } from './reducers/PreviewReducer';
import PreviewReducer from './reducers/PreviewReducer';
import type { CaptureState } from './reducers/CaptureReducer';
import CaptureReducer from './reducers/CaptureReducer';
import type { ModeChangeState } from './reducers/ModeChangeReducer';
import ModeChangeReducer from './reducers/ModeChangeReducer';
import type { ModeState } from './reducers/ModeReducer';
import ModeReducer from './reducers/ModeReducer';
import type { SettingState } from './reducers/SettingReducer';
import SettingReducer from './reducers/SettingReducer';
import type { RecordState } from './reducers/RecordReducer';
import RecordReducer from './reducers/RecordReducer';
import type { ZoomState } from './reducers/ZoomReducer';
import ZoomReducer from './reducers/ZoomReducer';
import type { ActionData } from './actions/Action';
import type { CombinedState, Dispatch, Unsubscribe } from './core/redux';
import type { MapDispatchProp, MapStateProp } from './core/ohredux/connect';

const TAG = '[store]:';
const STORE_KEY = 'CAMERA_REDUX_STORE';

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

export interface Unsubscribe {
  destroy(): void
}

export type StoreStruct = {
  getState: () => OhCombinedState,
  dispatch: Dispatch<ActionData>,
  subscribe: (mapToProps: MapStateProp | null, mapToDispatch: MapDispatchProp | null) => Unsubscribe | null,
  connect: (mapStateProp: MapStateProp, mapDispatchProp: MapDispatchProp) => (target: any) => void
};

export function getStore(): StoreStruct {
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
      const action = { type: '', data: undefined, tag: 'FROM_WORKER' }
      Log.info(`${TAG} store dispatch msg: ${JSON.stringify(msg)}`)
      action.type = msg.type
      action.data = msg.data
      store.dispatch(action)
      EventBusManager.getInstance().getEventBus().emit(msg.type, [msg.data])
    }

  }
  return AppStorage.Get(STORE_KEY);
}