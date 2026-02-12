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

import lazy { HiLog } from '../../utils/HiLog';

type Callback = (args: any, event?: string) => void;

const TAG: string = 'EventBus';

export enum EventPriority {
  HIGH_PRIORITY = -1,
  NORMAL = 0
}

export class EventBus {
  private mEvents: Map<string, Map<string, Set<Callback>>> = new Map();

  constructor() {
  }

  public on(event: string | string[], callback: Callback, code: string): void {
    if (Array.isArray(event)) {
      for (let i = 0, l = event.length; i < l; i++) {
        this.on(event[i], callback, code);
      }
      return;
    }
    if (!event) {
      return;
    }
    const map: Map<string, Set<Callback>> = this.mEvents.get(event) || new Map();
    const set: Set<Callback> = map.get(code) || new Set();
    // 同一个action，同一个类，只能注册一个唯一name的callback
    let needAdd = true;
    if (callback.name) {
      set.forEach(value => {
        if (value.name === callback.name) {
          HiLog.w(TAG, `duplicate on event: ${JSON.stringify(event)}, name: ${callback.name}.`);
          needAdd = false;
        }
      });
    }
    if (needAdd) {
      HiLog.d(TAG, `on event: ${JSON.stringify(event)}, name: ${callback.name}.`);
      set.add(callback);
      map.set(code, set);
      this.mEvents.set(event, map);
    }
  }

  public off(event: string | string[], callback: Callback | undefined, code: string): void {
    // Array cyclic emptying
    if (Array.isArray(event)) {
      for (let i = 0, l = event.length; i < l; i++) {
        this.off(event[i], callback, code);
      }
      return;
    }
    if (!event) {
      return;
    }
    const map: Map<string, Set<Callback>> = this.mEvents.get(event) || new Map();
    map.set(code, new Set());
    this.mEvents.set(event, map);
    HiLog.d(TAG, `off event: ${JSON.stringify(event)}, name: ${callback.name}.`);
  }

  public emit(event: string, argument: any): void {
    const map: Map<string, Set<Callback>> = this.mEvents.get(event);
    if (!map) {
      return;
    }
    HiLog.d(TAG, `emit event: ${event}, callbacks length: ${map.size}.`);
    const valuesIterator = map.values();
    for (const callbacks of valuesIterator) {
      callbacks?.forEach((callback: Callback) => {
        argument.push(event);
        try {
          callback.apply(this, argument);
        } catch (err) {
          HiLog.e(TAG, `emit error code: ${err?.code}, error msg: ${err}, callback: ${callback?.name}`);
        }
      });
    }
  }

  public clear(code: string): void {
    this.mEvents.forEach((innerMap, keyA) => {
      if (!innerMap.has(code)) {
        return;
      }
      innerMap.delete(code);
      if (innerMap.size === 0) {
        this.mEvents.delete(keyA);
      }
    });
  }
}