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

import lazy { HiLog } from '../utils/HiLog';
import lazy { ActionData } from './actions/Action';

const TAG = 'ActionRegistry';

export function addAction(name: string, action: Function): void { // 动态添加增量action类型
  ActionRegistry.getInstance().actionRegister(name, action);
}

export function execAction(actionName: string, funcName: string, ...arg): ActionData { // 执行Action并获取ActionData
  let action = ActionRegistry.getInstance().get(actionName);
  if (!action || !action[funcName]) {
    return undefined;
  }
  return action[funcName](...arg);
}

export class ActionRegistry {
  private static instance: ActionRegistry | undefined = undefined;
  private actionClassMap: Map<string, Function>;

  public static getInstance(): ActionRegistry {
    if (!ActionRegistry.instance) {
      ActionRegistry.instance = new ActionRegistry();
    }
    return ActionRegistry.instance;
  }

  private constructor() {
    this.actionClassMap = new Map();
  }

  public actionRegister(name: string, action: Function): void {
    if (!action) {
      HiLog.e(TAG, 'actionRegister action is null');
    }
    this.actionClassMap.set(name, action);
  };

  public get<T>(action: string): T {
    return this.actionClassMap.get(action) as T;
  }
}