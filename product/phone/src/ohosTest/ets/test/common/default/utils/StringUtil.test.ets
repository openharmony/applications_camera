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
import { EnumType, ValueType } from '@ohos/common/src/main/ets/utils/types';
import { StringUtil } from '@ohos/common/src/main/ets/utils/StringUtil';

const TAG: string = TestConstants.TAG + '_' + 'StringUtilTest';

export default function stringUtilTest(){
  const driver: Driver = Driver.create();

  beforeAll(async () => {
    await CommonHandler.abilityStart(driver).then(() => {
      HiLog.i(TAG, 'StringUtil test is start.');
    })
  });

  afterAll(async () => {
    await CommonHandler.abilityEnd(driver).then(() => {
      HiLog.i(TAG, 'StringUtil test is finished.');
    });
  });

  describe('StringUtilTest', () => {

    it('StringUtilTest_010', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'StringUtilTest_010');
      let map: Map<EnumType | string, ValueType | EnumType> = new Map<EnumType | string, ValueType | EnumType>();
      expect(StringUtil.map2String(map)).assertEqual('');
      HiLog.end(TAG, 'StringUtilTest_010');
    });

    it('StringUtilTest_011', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'StringUtilTest_011');
      let map: Map<string, Map<string, number> | Map<EnumType, number>> = new Map<string, Map<string, number> | Map<EnumType, number>>();
      expect(StringUtil.mapMap2String(map)).assertEqual('');
      HiLog.end(TAG, 'StringUtilTest_011');
    });

  });
}