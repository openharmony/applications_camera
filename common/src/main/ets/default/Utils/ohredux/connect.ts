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

function merge(obj, props) {
  const keysProp = Object.keys(props)
  console.info(`mapProps: ${JSON.stringify(keysProp)}`)
  for (let i = 0; i < keysProp.length; i++) {
    obj[keysProp[i]] = props[keysProp[i]]
  }
}

function connect(store, mapToProps, mapToDispatch) {
  return (obj) => {
    console.info(JSON.stringify(store.getState()))
    merge(obj, mapToProps(store.getState()))
    merge(obj, mapToDispatch(store.dispatch))
    let unsubscribe = store.subscribe(() => merge(obj, mapToProps(store.getState())))
    return {
      destroy() {
        unsubscribe()
      }
    }
  }
}

export { connect }