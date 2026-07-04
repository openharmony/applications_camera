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
import lazy { HiLog } from './HiLog';

interface DataObserver {
  (target: Object, property: string, callback: (val?: unknown, oldVal?: unknown) => void | Promise<void>): void
}


/**
 * 监听属性值改变，执行回调
 * 用于target中某个属性（property）的值，被重新设置时候，调用callback；
 * @param target 要监听属性所属的对象
 * @param property 要监听的值
 * @param callback 监听到属性被设置后的回调
 */
const dataObserver: DataObserver = (target: Object, property, callback) => {
  let value = target[property];
  Object.defineProperty(target, property, {
    configurable: true,
    enumerable: true,
    get: () => {
      return value;
    },
    set: (newValue) => {
      if (newValue === value) {
        return;
      }
      const oldValue = value;
      value = newValue;
      callback(value, oldValue);
    }
  });
};

export default dataObserver;