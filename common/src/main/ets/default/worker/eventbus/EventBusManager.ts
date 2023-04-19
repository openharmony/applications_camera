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

import { EventBus } from './EventBus'

export class EventBusManager {
  // The global eventbus of the application process. Event registration and destruction should be paired
  private appEventBus: EventBus;

  constructor() {
    this.appEventBus = new EventBus();
  }

  public static getInstance(): EventBusManager {
    if (!globalThis?.sInstanceEventBus) {
      globalThis.sInstanceEventBus = new EventBusManager();
      console.info('EventBusManager create a new EventBus')
    }
    return globalThis.sInstanceEventBus;
  }

  public static getMainInstance(): EventBusManager {
    if (!globalThis?.mInstanceEventBus) {
      globalThis.mInstanceEventBus = new EventBusManager();
    }
    return globalThis.mInstanceEventBus;
  }

  public static getWorkerInstance(): EventBusManager {
    if (!globalThis?.wInstanceEventBus) {
      globalThis.wInstanceEventBus = new EventBusManager();
    }
    return globalThis.wInstanceEventBus;
  }

  public static getCameraInstance(): EventBusManager {
    if (!globalThis?.cInstanceEventBus) {
      globalThis.cInstanceEventBus = new EventBusManager();
    }
    return globalThis.cInstanceEventBus;
  }

  public getEventBus(): EventBus {
    return this.appEventBus;
  }
}