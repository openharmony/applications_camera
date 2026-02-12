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

import lazy { EventBus } from './EventBus';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { GlobalContext } from '../../utils/GlobalContext';

const TAG: string = 'EventBusManager';

export class EventBusManager {
  // The global eventbus of the application process. Event registration and destruction should be paired
  private mAppEventBus: EventBus;
  private static sInstanceEventBus: EventBusManager;

  constructor() {
    this.mAppEventBus = new EventBus();
  }

  public static getInstance(): EventBusManager {
    if (!EventBusManager.sInstanceEventBus) {
      EventBusManager.sInstanceEventBus = new EventBusManager();
      HiLog.i(TAG, 'EventBusManager create a new EventBus.');
    }
    return EventBusManager.sInstanceEventBus;
  }

  public getEventBus(): EventBus {
    return this.mAppEventBus;
  }
}