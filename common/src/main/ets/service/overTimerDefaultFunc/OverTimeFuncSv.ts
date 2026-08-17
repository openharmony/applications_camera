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
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { EXPIRE_MINUTE_TIME_15, FLUSH_TIMESTAMP, PreferencesService } from '../preferences/PreferencesService';

const TAG: string = 'OverTimeFuncSv';

export class OverTimeFuncSv {

  /**
   * 进入前台超时15min，部分特性恢复默认值
   */
  static  resetFuncDefaultVal(): void {
    const mFeatureManger: FeatureManager = FeatureManager.getInstance();
    const preferencesService: PreferencesService = PreferencesService.getInstance();
    const isOverDefaultTime = preferencesService.isExpire(EXPIRE_MINUTE_TIME_15, FLUSH_TIMESTAMP);
    if (isOverDefaultTime) {
      const exposureFunc = mFeatureManger.getFunction(FunctionId.EXPOSURE) as unknown as { resetValue?: () => void } | undefined;
      if (exposureFunc && typeof exposureFunc.resetValue === 'function') {
        exposureFunc.resetValue();
        HiLog.i(TAG, 'over 15 min into foreground, reset func default val.');
      } else {
        // Feature functions may not be ready before camera STARTED; avoid crash.
        HiLog.w(TAG, 'over 15 min but exposure function not ready, skip reset.');
      }
    }
  }
}

