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
import { AspectRatioFunction } from '@ohos/common/src/main/ets/function/aspectratio/AspectRatioFunction'
import { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import { UiElement } from '@ohos/common/src/main/ets/function/core/UiElement';

const TAG: string = TestConstants.TAG + '_' + 'AspectRatioFunctionTest';

export default function aspectRatioFunctionTest(){
  const driver: Driver = Driver.create();
  let aspectRatioFunction: AspectRatioFunction = new AspectRatioFunction()

  beforeAll(async () => {
    await CommonHandler.abilityStart(driver).then(() => {
      HiLog.i(TAG, 'AspectRatioFunction test is start.');
    })
  });

  afterAll(async () => {
    await CommonHandler.abilityEnd(driver).then(() => {
      HiLog.i(TAG, 'AspectRatioFunction test is finished.');
    });
  });

  describe('AspectRatioFunctionTest', () => {
    it('AspectRatioFunctionTest_010', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'AspectRatioFunctionTest_010');
      const result = aspectRatioFunction.getRenderType(RenderLocation.TAB_BAR_MIDDLE);
      expect(result).assertNull();
      HiLog.end(TAG, 'AspectRatioFunctionTest_010');
    });

    it('AspectRatioFunctionTest_011', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'AspectRatioFunctionTest_011');
      let TempMap: Map<String, UiElement> = new Map();
      expect(aspectRatioFunction.getUiElements(RenderLocation.TAB_BAR_MIDDLE)).assertDeepEquals(TempMap);
      HiLog.end(TAG, 'AspectRatioFunctionTest_011');
    });

  });
}