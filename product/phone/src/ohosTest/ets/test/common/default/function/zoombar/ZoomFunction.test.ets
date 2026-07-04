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
import { ZoomFunction } from '@ohos/common/src/main/ets/function/zoombar/ZoomFunction';
import { ZoomActionType } from '@ohos/common/src/main/ets/redux/actions/ZoomActionType';

const TAG: string = TestConstants.TAG + '_' + 'ZoomFunctionTest';

export default function zoomFunctionTest(){
  const driver: Driver = Driver.create();

  beforeAll(async () => {
    await CommonHandler.abilityStart(driver).then(() => {
      HiLog.i(TAG, 'ZoomFunction test is start.');
    })
  });

  afterAll(async () => {
    await CommonHandler.abilityEnd(driver).then(() => {
      HiLog.i(TAG, 'ZoomFunction test is finished.');
    });
  });

  describe('ZoomFunctionTest', () => {
    it('ZoomFunction_010', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'ZoomFunction_010');
      let zoomFunction: ZoomFunction = new ZoomFunction();
      expect(zoomFunction.setValue({zoomRatio: undefined, isPrepareZoom: undefined, isUnprepareZoom: undefined}) as undefined).assertUndefined();
      HiLog.end(TAG, 'ZoomFunction_010');
    });

  });

}