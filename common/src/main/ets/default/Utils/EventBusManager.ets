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

import {EventBus} from "./EventBus"

export default class EventBusManager {
  // The global eventbus of the application process. Event registration and destruction should be paired
  private appEventBus: EventBus;
  static sInstance: EventBusManager = undefined;
  static mInstance: EventBusManager = undefined;
  static wInstance: EventBusManager = undefined;
  static cInstance: EventBusManager = undefined;

  private constructor() {
    this.appEventBus = new EventBus();
  }

  public static getInstance(): EventBusManager {
    if (EventBusManager.sInstance == null) {
      EventBusManager.sInstance = new EventBusManager();
    }
    return EventBusManager.sInstance;
  }

  public static getMainInstance(): EventBusManager {
    if (EventBusManager.mInstance == null) {
      EventBusManager.mInstance = new EventBusManager();
    }
    return EventBusManager.mInstance;
  }

  public static getWorkerInstance(): EventBusManager {
    if (EventBusManager.wInstance == null) {
      EventBusManager.wInstance = new EventBusManager();
    }
    return EventBusManager.wInstance;
  }

  public static getCameraInstance(): EventBusManager {
    if (EventBusManager.cInstance == null) {
      EventBusManager.cInstance = new EventBusManager();
    }
    return EventBusManager.cInstance;
  }

  public getEventBus(): EventBus {
    return this.appEventBus;
  }
}