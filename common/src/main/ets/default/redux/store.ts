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

import { Log } from '../utils/Log';
import { loggerMiddle } from './middlewares/loggerMiddle';
import type { CameraInitState } from './reducers/CameraInitReducer';
import { cameraInitReducer } from './reducers/CameraInitReducer';
import type { ContextState } from './reducers/ContextReducer';
import { contextReducer } from './reducers/ContextReducer';
import type { CameraState } from './reducers/CameraReducer';
import { cameraReducer } from './reducers/CameraReducer';
import type { PreviewState } from './reducers/PreviewReducer';
import { previewReducer } from './reducers/PreviewReducer';
import type { CaptureState } from './reducers/CaptureReducer';
import { captureReducer } from './reducers/CaptureReducer';
import type { ModeChangeState } from './reducers/ModeChangeReducer';
import { modeChangeReducer } from './reducers/ModeChangeReducer';
import type { ModeState } from './reducers/ModeReducer';
import { modeReducer } from './reducers/ModeReducer';
import type { SettingState } from './reducers/SettingReducer';
import { settingReducer } from './reducers/SettingReducer';
import type { RecordState } from './reducers/RecordReducer';
import { recordReducer } from './reducers/RecordReducer';
import type { ZoomState } from './reducers/ZoomReducer';
import { zoomReducer } from './reducers/ZoomReducer';
import type { ActionData } from './actions/Action';
import { applyMiddleware } from './core';
import type { Enhancer, Reducer } from './core';
import { eventBusMiddle } from './middlewares/EventBusMiddle';
import { combineReducers } from './core';

const TAG = '[store]:';
const INIT_TAG = 'StoreInit';

export type OhCombinedState = {
  cameraInitReducer: CameraInitState;
  contextReducer: ContextState;
  cameraReducer: CameraState;
  previewReducer: PreviewState;
  captureReducer: CaptureState;
  recordReducer: RecordState;
  modeChangeReducer: ModeChangeState;
  modeReducer: ModeState
  settingReducer: SettingState
  zoomReducer: ZoomState
};

function getReducers(): Reducer {
  return combineReducers([
    cameraInitReducer,
    contextReducer,
    cameraReducer,
    previewReducer,
    captureReducer,
    recordReducer,
    modeChangeReducer,
    modeReducer,
    settingReducer,
    zoomReducer,
  ]);
}

export interface Unsubscribe {
  destroy(): void
}

export interface Dispatch<A = ActionData> {
  <T extends A>(action: T): T;
}

function getEnhancer(): Enhancer {
  return applyMiddleware(loggerMiddle, eventBusMiddle);
}

export function getStore(): Store {
  Log.info('getStore');
  return Store.getInstance();
}

export class Store {
  private currentReducer: Reducer;
  private currentState = undefined;
  private currentListeners: (() => void)[] | null = [];
  private nextListeners = this.currentListeners;
  private isDispatching = false;
  private static mInstance: Store | undefined = undefined;

  public static hasStore(): boolean {
    return Store.mInstance !== undefined;
  }

  public static getInstance(): Store {
    if (!Store.mInstance) {
      Store.mInstance = new Store(getReducers(), getEnhancer());
    }
    return Store.mInstance;
  }

  public static createStore(reducer: Reducer, enhancer: Enhancer): Store {
    Store.mInstance = new Store(reducer, enhancer);
    return Store.mInstance;
  }

  private constructor(reducer: Reducer, enhancer: Enhancer) {
    this.currentReducer = reducer;
    this.dispatch({ type: INIT_TAG, data: null });
    this.dispatch = enhancer(this.dispatch.bind(this));
  }

  public getState(): OhCombinedState {
    if (this.isDispatching) {
      Log.error('isDispatching get error');
      return null;
    }
    return this.currentState;
  }

  public dispatch(action: ActionData): ActionData {
    if (this.isDispatching) {
      Log.error('isDispatching get error');
      return null;
    }
    try {
      this.isDispatching = true;
      this.currentState = this.currentReducer(this.currentState, action);
    } finally {
      this.isDispatching = false;
    }
    this.currentListeners = this.nextListeners;
    const listeners = this.nextListeners;
    for (let i = 0; i < listeners.length; i++) {
      const listener = listeners[i];
      listener();
    }
    return action;
  }

  public subscribe(mapToProps: MapStateProp | null, mapToDispatch: MapDispatchProp | null): Unsubscribe {
    Log.info(`${TAG} getStore subscribe invoke.`);
    if (mapToDispatch) {
      mapToDispatch(this.dispatch as Dispatch);
    }
    let unsubscribe: () => void = () => {};
    if (mapToProps) {
      mapToProps(this.currentState);
      unsubscribe = this.stateSubscribe(() => mapToProps(this.currentState));
      return {
        destroy(): void {
          unsubscribe();
        }
      };
    }
    return null;
  }

  private stateSubscribe(listener: () => void): () => void {
    if (typeof listener !== 'function') {
      Log.error('listener is not function');
      return () => {};
    }
    if (this.isDispatching) {
      Log.error('isDispatching stateSubscribe error');
      return () => {};
    }
    let isSubScribed = true;

    this.ensureCanMutateNextListeners();
    this.nextListeners.push(listener);
    return (): void => {
      if (!isSubScribed) {
        return;
      }
      this.currentListeners = null;
      if (this.isDispatching) {
        Log.error('isDispatching unstateSubscribe error');
        return;
      }
      isSubScribed = false;
      this.ensureCanMutateNextListeners();
      const index = this.nextListeners.indexOf(listener);
      this.nextListeners.slice(index, 1);
      this.currentListeners = null;
    };
  }

  private ensureCanMutateNextListeners(): void {
    if (this.nextListeners === this.currentListeners) {
      this.nextListeners = this.currentListeners.slice();
    }
  }
}

interface MapStateProp {
  (state: OhCombinedState): void;
}

interface MapDispatchProp {
  (dispatch: Dispatch): void;
}