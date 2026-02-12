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
import { ZoomOperation, ZoomScaleStruct } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import camera from '@ohos.multimedia.camera';

const TAG: string = TestConstants.TAG + '_' + 'ZoomOperationTest';

export default function zoomOperationTest(){
  const driver: Driver = Driver.create();

  beforeAll(async () => {
    await CommonHandler.abilityStart(driver).then(() => {
      HiLog.i(TAG, 'ZoomOperation test is start.');
    })
  });

  afterAll(async () => {
    await CommonHandler.abilityEnd(driver).then(() => {
      HiLog.i(TAG, 'ZoomOperation test is finished.');
    });
  });

  describe('ZoomOperationTest', () => {
    it('ZoomOperationTest_010', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'ZoomOperationTest_010');
      let zoomArray: number[] = [];
      expect(ZoomOperation.getDirectionChangeAutoWide(zoomArray)).assertEqual(1);
      HiLog.end(TAG, 'ZoomOperationTest_010');
    });

    it('ZoomOperationTest_011', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'ZoomOperationTest_011');
      expect(ZoomOperation.getDefaultZoomRatio(ModeType.PHOTO, camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED)).assertEqual(1);
      HiLog.end(TAG, 'ZoomOperationTest_011');
    });

  });
}