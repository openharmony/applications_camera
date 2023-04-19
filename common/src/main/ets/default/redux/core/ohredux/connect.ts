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

import { Dispatch, Unsubscribe } from '../redux'

export interface MapStateProp<State = any> {
  (state: State): any;
}

export interface MapDispatchProp {
  (dispatch: Dispatch): any;
}

function merge(obj: any, props: any) {
  const keysProp = Object.keys(props)
  console.info(`mapProps: ${JSON.stringify(keysProp)}`)
  for (let i = 0; i < keysProp.length; i++) {
    obj[keysProp[i]] = props[keysProp[i]]
  }
}

// The above merge function with no return should be replaced with this merge, so the state in the
// arkUI pages marked by @State has explicit type, which has great advantages in coding and debugging.
function merge1<T, U>(obj: T, props: U): T & U {
  for (const key in props) {
    (obj as any)[key] = props[key];
  }
  return obj as T & U;
}

export function connect(store, mapToProps: MapStateProp, mapToDispatch: MapDispatchProp): (state: any) => void {
  return (obj) => {
    console.info(JSON.stringify(store.getState()))
    merge(obj, mapToProps(store.getState()))
    merge(obj, mapToDispatch(store.dispatch))
    store.subscribe(() => merge(obj, mapToProps(store.getState())))
  }
}