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

/* instrument ignore file */
import lazy { StoreManager } from '../worker/StoreManager';
import type { ActionData } from '../redux/actions/Action';

export enum TriggerType {
  TRIGGER_TYPE_1 = 1,
  TRIGGER_TYPE_2 = 2,
  TRIGGER_TYPE_3 = 3,
}

const TRIGGER_TYPE_1: TriggerType.TRIGGER_TYPE_1 = 1;
const TRIGGER_TYPE_2: TriggerType.TRIGGER_TYPE_2 = 2;
const TRIGGER_TYPE_3: TriggerType.TRIGGER_TYPE_3 = 3;
const STORE_MANAGER_THROTTLE: number = 20;

type CBParam = ActionData | Record<string, unknown> | number | boolean;

export interface ThrottleCB<T, R> {
  (...rest: Array<T>): R
}

interface Throttle<T> {
  (T, during: number, triggerType: TriggerType): T
}

/*
    cb: 需要节流处理的函数
    during: 节流的时间段
    triggerType: cb 的触发时机，1: cb调用后马上触发，2: 最后一次函数调用during之后触发，即退出节流时触发；3: 1和2 时候都触发
 */
export const throttle: Throttle<ThrottleCB<CBParam, void>> = function (cb, during, triggerType) {
  let timer = Number.MIN_VALUE;

  return function (...rest) {
    if (timer === Number.MIN_VALUE) {
      if (triggerType === TRIGGER_TYPE_1 || triggerType === TRIGGER_TYPE_3) {
        cb(...rest);
      }
    } else {
      clearTimeout(timer);
      timer = Number.MIN_VALUE;
    }

    timer = setTimeout((): void => {
      if (triggerType === TRIGGER_TYPE_2 || triggerType === TRIGGER_TYPE_3) {
        cb(...rest);
      }
      clearTimeout(timer);
      timer = Number.MIN_VALUE;
    }, during);
  };
};

function eventBusPostMessage(action: ActionData): void {
  StoreManager.getInstance().postMessage(action);
}

export const postStoreManagerThrottle = throttle(eventBusPostMessage, STORE_MANAGER_THROTTLE, TRIGGER_TYPE_1);