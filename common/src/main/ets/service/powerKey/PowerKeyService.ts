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

import inputConsumer from '@ohos.multimodalInput.inputConsumer';
import lazy { KeyCode } from '@ohos.multimodalInput.keyCode';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { Action } from '../../redux/actions/Action';

const powerKeyOptionsDurationOneSecond: inputConsumer.KeyOptions = {
  preKeys: [],
  finalKey: KeyCode.KEYCODE_POWER,
  isFinalKeyDown: true,
  finalKeyDownDuration: 1200
};

const TAG: string = 'PowerKeyService';

export class PowerKeyService {
  private mStoreManager: StoreManager = StoreManager.getInstance();
  private powerKeySubscribeStatus: boolean = false;
  private static sInstancePowerKeyService: PowerKeyService;

  public static getInstance(): PowerKeyService {
    if (!PowerKeyService.sInstancePowerKeyService) {
      PowerKeyService.sInstancePowerKeyService = new PowerKeyService();
    }
    return PowerKeyService.sInstancePowerKeyService;
  }

  public powerKeySubscribe(): void {
    if (this.powerKeySubscribeStatus) {
      HiLog.w(TAG, 'powerKey already Subscribed');
      return;
    }
    this.powerKeySubscribeStatus = true;
    inputConsumer.on('key', powerKeyOptionsDurationOneSecond, (() => this.powerKeyDownDurationOneSecond()));
    HiLog.i(TAG, 'powerKey Subscribe success.');
  }

  public powerKeyUnsubscribe(): void {
    if (this.powerKeySubscribeStatus) {
      this.powerKeySubscribeStatus = false;
      inputConsumer.off('key', powerKeyOptionsDurationOneSecond);
      HiLog.i(TAG, 'powerKey unSubscribe success.');
    }
    HiLog.i(TAG, 'powerKey already unSubscribed');
  }

  private powerKeyDownDurationOneSecond(): void {
    HiLog.i(TAG, 'powerKeyDownDurationOneSecond is triggered.');
    this.mStoreManager.postMessage(Action.powerKeyDownDurationOneSecond());
  }
}