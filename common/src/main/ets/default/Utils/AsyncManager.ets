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

import {EventBus} from './EventBus.ets'
import {EventBusManager} from './EventBusManager.ets'
import {Constants} from './Constants.ets'

export class AsyncManager {

  appEventBus: EventBus = EventBusManager.getMainInstance().getEventBus()

  constructor() {

  }

  public static getInstance(): AsyncManager {
    if (!AppStorage.Has(Constants.APP_KEY_ASYNC_MANAGER)) {
      AppStorage.SetOrCreate(Constants.APP_KEY_ASYNC_MANAGER, new AsyncManager())
      console.info('build new AsyncManager.')
    }
    return AppStorage.Get(Constants.APP_KEY_ASYNC_MANAGER);
  }

  public postMessage(msg: any): AsyncManager {
    return this
  }

  public onMessage(msg: any): void {
    console.info(`AsyncManager  onMessage uidata: ${JSON.stringify(msg.data)}`)
  }

  public onmessageerror(msg: any): void {

  }

  public onerror(msg: any): void {

  }

  public onexit(msg: any): void {

  }
}