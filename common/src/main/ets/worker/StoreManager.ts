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

import lazy { FREQUENT_HILOG_EVENT, HiLog } from '../utils/HiLog';
import type { ActionData } from '../redux/actions/Action';
import lazy { execDispatch } from '../redux';

const TAG: string = 'StoreManager';

export class StoreManager {
  private static sInstanceStoreManager: StoreManager;

  public static getInstance(): StoreManager {
    if (!StoreManager.sInstanceStoreManager) {
      StoreManager.sInstanceStoreManager = new StoreManager();
    }
    return StoreManager.sInstanceStoreManager;
  }

  public postMessage(msg: ActionData): void {
    if (!msg) {
      return;
    }
    HiLog.iFreq(TAG, `postMessage: ${JSON.stringify(msg)}.`, FREQUENT_HILOG_EVENT.includes(msg.type));
    execDispatch(msg);
  }
}