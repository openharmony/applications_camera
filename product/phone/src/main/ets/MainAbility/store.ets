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

import {AsyncManager} from '../../../../../../common/src/main/ets/default/Utils/AsyncManager.ets'

const STORE_KEY = 'CAMERA_REDUX_STORE'

export default function getStore(): {
  getState: Function,
  dispatch: Function,
  subscribe: Function,
  connect: Function
} {
  console.info(' store init.')
  if (!AppStorage.Has(STORE_KEY)) {
    AsyncManager.getInstance().onMessage = (msg) => {
      console.info(`store dispatch msg: ${JSON.stringify(msg)}`)
      let uiData = msg[0].data
      console.info(`store dispatch uidata: ${JSON.stringify(uiData)}`)
    }

  }
  return AppStorage.Get(STORE_KEY)
}