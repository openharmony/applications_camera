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
import { FrameRateFunction } from  '@ohos/common/src/main/ets/function/framerate/FrameRateFunction';
import { RenderLocation } from '@ohos/common/src/main/ets/function//core/functionproperty/RenderLocation';
import { RenderType } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderType';
import { UiElement } from '@ohos/common/src/main/ets/function/core/UiElement';
import { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';

const TAG: string = TestConstants.TAG + '_' + 'FrameRateFunctionTest';

export default function frameRateFunctionTest(){
  const driver: Driver = Driver.create();
  let frameRateFunction: FrameRateFunction = new FrameRateFunction();

  beforeAll(async () => {
    await CommonHandler.abilityStart(driver).then(() => {
      HiLog.i(TAG, 'FrameRateFunction test is start.');
    })
  });

  afterAll(async () => {
    await CommonHandler.abilityEnd(driver).then(() => {
      HiLog.i(TAG, 'FrameRateFunction test is finished.');
    });
  });

  describe('FrameRateFunctionTest', () => {

    it('FrameRateFunctionTest_010', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'FrameRateFunctionTest_010');
      const result = frameRateFunction.getRenderType(RenderLocation.TAB_BAR_LIST);
      expect(result).assertEqual(RenderType.NONE);
      HiLog.end(TAG, 'FrameRateFunctionTest_010');
    });

    it('FrameRateFunctionTest_011', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'FrameRateFunctionTest_011');
      const result = frameRateFunction.getRenderType(RenderLocation.TAB_BAR_MIDDLE);
      expect(result).assertNull();
      HiLog.end(TAG, 'FrameRateFunctionTest_011');
    });

    it('FrameRateFunctionTest_012', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'FrameRateFunctionTest_012');
      let TempMap: Map<String, UiElement> = new Map();
      expect(frameRateFunction.getUiElements(RenderLocation.TAB_BAR_MIDDLE)).assertDeepEquals(TempMap);
      HiLog.end(TAG, 'FrameRateFunctionTest_012');
    });

  });
}