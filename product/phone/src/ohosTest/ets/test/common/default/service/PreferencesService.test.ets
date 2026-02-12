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

import { afterAll, ArgumentMatchers, beforeAll, describe, expect, it, MockKit, TestType, when } from '@ohos/hypium';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { TestConstants } from '../../../../TestConstants';
import camera from '@ohos.multimedia.camera';
import { CommonHandler } from '../../../../aw/CommonHandler';
import { Driver } from '@kit.TestKit';
import lazy { PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import dataPreferences from '@ohos.data.preferences';
import lazy { PropTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';

const TAG: string = TestConstants.TAG + '_' + 'PreferencesServiceTest';

export default function preferencesServiceTest(){
  const driver: Driver = Driver.create();
  let preferencesService: PreferencesService = PreferencesService.getInstance();

  beforeAll(async () => {
    await CommonHandler.abilityStart(driver).then(() => {
      HiLog.i(TAG, 'PreferencesService test is start.');
    })
  });

  afterAll(async () => {
    await CommonHandler.abilityEnd(driver).then(() => {
      HiLog.i(TAG, 'PreferencesService test is finished.');
    });
  });

  describe('PreferencesServiceTest', () => {

    it('PreferencesServiceTest_010', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'PreferencesServiceTest_010');
      let result = await preferencesService.putFunctionValue(1, 0, undefined);
      expect(result as undefined).assertUndefined();
      HiLog.end(TAG, 'PreferencesServiceTest_010');
    });

  });
}