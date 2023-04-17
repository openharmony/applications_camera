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

import { Log } from '../../utils/Log'

const TAG = '[Decorators]:'

export function debounce(timeout: number) {
    return function inner(target: any, propKey: string, descriptor: PropertyDescriptor) {
        let curFunc: number = 0;
        const original = descriptor.value;
        descriptor.value = function (...args: string[]) {
            Log.log(`${TAG} debounce invoke ${propKey} curFunc: ${curFunc}`);
            curFunc && clearTimeout(curFunc);
            curFunc = setTimeout(() => original.call(this, ...args), timeout);
        };
    };
}

export function throttle(waitTime: number) {
    return function inner(target: any, propKey: string, descriptor: PropertyDescriptor) {
        let lastTime: number = 0;
        const original = descriptor.value;
        descriptor.value = function (...args: string[]) {
            let curTime = Date.now();
            Log.log(`${TAG} throttle invoke ${propKey} timeInterval: ${curTime - lastTime}`);
            if (curTime - lastTime >= waitTime) {
                original.call(this, ...args);
                lastTime = curTime;
            }
        };
    };
}
