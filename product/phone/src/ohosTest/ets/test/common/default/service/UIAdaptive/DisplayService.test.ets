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
import { TestConstants } from '../../../../../TestConstants';
import { CommonHandler } from '../../../../../aw/CommonHandler';
import { Driver } from '@kit.TestKit';
import { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';

const TAG: string = TestConstants.TAG + '_' + 'DisplayServiceTest';

export default function displayServiceTest(){
  const driver: Driver = Driver.create();
  let displayService: DisplayService = DisplayService.getInstance();

  beforeAll(async () => {
    await CommonHandler.abilityStart(driver).then(() => {
      HiLog.i(TAG, 'DisplayService test is start.');
    })
  });

  afterAll(async () => {
    await CommonHandler.abilityEnd(driver).then(() => {
      HiLog.i(TAG, 'DisplayService test is finished.');
    });
  });

  describe('DisplayServiceTest', () => {
    it('DisplayServiceTest_010', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'DisplayServiceTest_010');
      let rotationOrigin: number = Reflect.get(displayService, 'mRotation');
      Reflect.set(displayService, 'mRotation', 1);
      expect(displayService.isHorizontal()).assertEqual(true);
      Reflect.set(displayService, 'mRotation', rotationOrigin);
      HiLog.end(TAG, 'DisplayServiceTest_010');
    });

    it('DisplayServiceTest_011', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'DisplayServiceTest_011');
      expect(displayService.isHorizontal()).assertEqual(false);
      HiLog.end(TAG, 'DisplayServiceTest_011');
    });

  });
}