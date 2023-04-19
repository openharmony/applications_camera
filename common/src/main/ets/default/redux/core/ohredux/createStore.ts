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

import {
  Store,
  createStore,
  ExtendState,
  PreloadedState,
  StoreEnhancer,
  Reducer,
  Action
} from '../redux/index'
import { connect } from './connect'

export default function _createStore<S,
A extends Action,
Ext = {},
StateExt = never>(
    reducer: Reducer<S, A>,
    enhancer?: StoreEnhancer<Ext, StateExt>
): Store<ExtendState<S, StateExt>, A, StateExt, Ext> & Ext

export default function _createStore<S,
A extends Action,
Ext = {},
StateExt = never>(
    reducer: Reducer<S, A>,
    preloadedState?: PreloadedState<S>,
    enhancer?: StoreEnhancer<Ext, StateExt>
): Store<ExtendState<S, StateExt>, A, StateExt, Ext> & Ext

export default function _createStore<S,
A extends Action,
Ext = {},
StateExt = never>(
  reducer: Reducer<S, A>,
  preloadedState?: PreloadedState<S>,
  enhancer?: StoreEnhancer<Ext, StateExt>
): Store<ExtendState<S, StateExt>, A, StateExt, Ext> & Ext {
  const store = createStore(reducer, preloadedState, enhancer)

  function _connect(mapToProps, mapToDispatch) {
    return connect(store, mapToProps, mapToDispatch)
  }

  return {
    ...store,
    connect: _connect
  }
}