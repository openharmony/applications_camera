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

import lazy { HiLog } from '../utils/HiLog';
import lazy { loggerMiddle } from './middlewares/LoggerMiddle';
import lazy { eventBusMiddle } from './middlewares/EventBusMiddle';
import lazy { OhCombinedReducer } from './ReduxConfig';
import type { ActionData } from './actions/Action';
import lazy { OhCombinedState } from './ReduxConfig';

const TAG = 'Store';
const INIT_TAG: string = 'StoreInit';

export interface Unsubscribe {
  destroy(): void
}

export interface Dispatch<A = ActionData> {
  <T extends A>(action: T): T
}

export function reduxInit(): void { // 初始化Store单例对象: State、Reducer唯一实例
  Store.getInstance();
}

export function reduxSubscribe(mapToProps: MapToProps,
  mapToDispatch?: ((dispatch: Dispatch) => void) | null): Unsubscribe { // 执行页面关键变量的注册、dispatch注册
  return Store.getInstance().subscribe(mapToProps, mapToDispatch);
}

export function getStates(): OhCombinedState { // 从Store获取全量State
  return Store.getInstance().getState();
}

export function addState(reducerName: string, stateMap: Map<string, object>): void { // 动态添加增量state
  Store.getInstance().getState().setStateMap(reducerName, stateMap);
}

export function getDispatch(): Dispatch { // 从Store获取Dispatch
  return Store.getInstance().dispatch as Dispatch;
}

export function execDispatch(actionObj: ActionData): void { // 调用执行dispatch
  Store.getInstance().dispatch(actionObj);
}

export function addReducer(reducer: Function): void { // 动态添加增量reducer
  Store.getInstance().getReducer().addReducer(reducer);
}

export interface Middleware {
  (): (next: Dispatch) => (action: ActionData) => ActionData
}

export type ChangeState<T = unknown> = (state: T, data: T) => void;

type MapToProps = ((state: OhCombinedState) => void) | ((state: OhCombinedState, func: ChangeState) => void) | null;

export class Store {
  private static instance: Store | undefined = undefined;

  private isDispatching = false;
  private currentFullState: OhCombinedState = new OhCombinedState(); // 在Store中维护State唯一一份实例引用
  private mFullReducers: OhCombinedReducer = new OhCombinedReducer(); // 在Store中维护Reducer唯一一份实例引用
  private listeners: ((curUpdateReducer: string[]) => void)[] | null = []; // 页面注册的update操作
  public dispatch: Function = (action: ActionData): ActionData => {
    if (!action) {
      HiLog.e(TAG, 'dispatch action is null.');
      return undefined;
    }
    if (this.isDispatching) {
      HiLog.d(TAG, 'isDispatching dispatch, error.');
    }
    let curUpdateVariable: string[];
    try {
      this.isDispatching = true;
      curUpdateVariable = this.execCurrentReducer(action); // dispatch操作中去更新全量state
    } finally {
      this.isDispatching = false;
    }
    if (!curUpdateVariable || curUpdateVariable.length <= 0) {
      HiLog.d(TAG, 'dispatch curUpdateVariable is null.');
      return undefined;
    }
    // 执行页面中回调，更新页面内状态变量
    for (let i = 0; i < this.listeners.length; i++) {
      const listener = this.listeners[i];
      listener(curUpdateVariable); // dispatch操作中去update页面注册的state
    }
    return action;
  };

  public static getInstance(): Store {
    if (!Store.instance) {
      Store.instance = new Store();
      if (!Store.instance.currentFullState) {
        Store.instance.currentFullState = new OhCombinedState();
      }
    }
    return Store.instance;
  }

  // 初始化reducer、state，执行INIT_TAG任务给currentState赋值，创建中间件，增强dispatch。
  private constructor() {
    this.dispatch({ type: INIT_TAG, data: null });
    const enhancer = this.applyMiddleware(loggerMiddle, eventBusMiddle);
    this.dispatch = enhancer(this.dispatch.bind(this));
  }

  // 操作function：dispatch操作中一环去更新State
  private execCurrentReducer(action: ActionData): string[] {
    const curUpdateVariable: string[] = [];
    this.mFullReducers.getReducers().forEach((reducer: Function) => {
      let curReducerResult: string[] = reducer(this.currentFullState, action);
      if (!curReducerResult || curReducerResult.length <= 0) {
        return;
      }
      curReducerResult.forEach((reducerUpdate) => {
        curUpdateVariable.push(reducerUpdate);
      });
    });
    return curUpdateVariable;
  };

  public getState(): OhCombinedState {
    return this.currentFullState;
  };

  public getReducer(): OhCombinedReducer {
    return this.mFullReducers;
  };

  public subscribe(mapToProps: MapToProps, mapToDispatch?: ((dispatch: Dispatch) => void) | null): Unsubscribe {
    if (mapToDispatch) {
      mapToDispatch(this.dispatch as Dispatch);
    }
    let unsubscribe: () => void = () => {
    };
    if (mapToProps) {
      const initKeys: Set<string> = this.execListenerGetKeys(mapToProps);

      let listener = this.listenerMiddle(mapToProps, initKeys);
      this.listeners.push(listener);

      unsubscribe = (): void => {
        const index = this.listeners.indexOf(listener);
        this.listeners.splice(index, 1);
      };
    }
    return {
      destroy(): void {
        unsubscribe();
      }
    };
  }

  private execListenerGetKeys(mapToProps: MapToProps): Set<string> {
    const initKeys: Set<string> = new Set(); // 流程结构待优化
    const get = <T>(reducerName: string, stateKey: string): T => {
      initKeys.add(stateKey); // 按变量维度
      return this.currentFullState.get(reducerName, stateKey);
    };
    const state = {
      ...(this.currentFullState as OhCombinedState),
      get: get
    };
    mapToProps(state as OhCombinedState, this.replaceStateDifferent); // 执行页面StateStruct初始化

    return initKeys;
  }

  private listenerMiddle(mapToProps: MapToProps, initKeys: Set<string>): (curUpdateReducer: string[]) => void {
    const listener = (curUpdateReducer: string[]): void => { // 流程需抽象成中间件
      let isIntersection = false;
      for (let i = 0; i < curUpdateReducer.length; i++) {
        if (initKeys.has(curUpdateReducer[i])) {
          isIntersection = true;
          break;
        }
      }
      if (!isIntersection) {
        return;
      }
      mapToProps(this.currentFullState, this.replaceStateDifferent);
    };
    return listener;
  }

  private applyMiddleware(...middlewares: Middleware[]): (dispatch: Dispatch) => Dispatch {

    function compose(functions: Function[]): Function {
      if (functions.length === 0) {
        return <T = {}>(arg: T): T => arg;
      }
      if (functions.length === 1) {
        return functions[0];
      }
      return functions.reduce((a, b): Function => (...args): void => a(b(...args)));
    }

    return (dispatch: Dispatch) => {
      return compose(middlewares.map(middleware => middleware()))(dispatch);
    };
  }

  private replaceStateDifferent<T = unknown>(stateStruct: T, data: T): void {
    for (const prop in (stateStruct as unknown as object)) {
      if (stateStruct[prop] !== data[prop]) {
        stateStruct[prop] = data[prop];
      }
    }
  }
}