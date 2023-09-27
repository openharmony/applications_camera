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

import { Log } from '../../../utils/Log';
import type { Unsubscribe } from '../../store';
import type { Action, Dispatch, ExtendState } from '../redux';
import type { Store } from '../redux/index';

const TAG: string = 'Subscribe';

export interface MapStateProp {
  (state: unknown): void;
}

export interface MapDispatchProp {
  (dispatch: unknown): void;
}

export function subscribe<S, A extends Action, StateExt, Ext>(store: Store<ExtendState<S, StateExt>, A, StateExt, Ext> & Ext,
                                                              mapToProps: MapStateProp | null, mapToDispatch: MapDispatchProp | null): Unsubscribe | null {
  Log.info(`${TAG} getStore subscribe invoke.`);
  if (mapToDispatch) {
    mapToDispatch(store.dispatch);
  }
  if (mapToProps) {
    mapToProps(store.getState());
    const unsubscribe: () => void = store.subscribe(() => mapToProps(store.getState()));
    return {
      destroy(): void {
        unsubscribe();
      }
    };
  }
  return null;
}