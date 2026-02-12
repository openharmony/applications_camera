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
import camera from '@ohos.multimedia.camera';
import { CommonHandler } from '../../../../../aw/CommonHandler';
import { Driver } from '@kit.TestKit';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { getPhotoFormat, getPreviewAndVideoFormat } from '@ohos/common/src/main/ets/utils/jsonparseutil/ProfileStructure';
import { PhotoFormatMode } from '@ohos/common/src/main/ets/function/enumbase/PhotoFormatMode';

const TAG: string = TestConstants.TAG + '_' + 'ProfileStructureTest';

export default function profileStructureTest(){
  const driver: Driver = Driver.create();

  beforeAll(async () => {
    await CommonHandler.abilityStart(driver).then(() => {
      HiLog.i(TAG, 'ProfileStructure test is start.');
    })
  });

  afterAll(async () => {
    await CommonHandler.abilityEnd(driver).then(() => {
      HiLog.i(TAG, 'ProfileStructure test is finished.');
    });
  });

  describe('ProfileStructureTest', () => {
    it('ProfileStructureTest_010', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'ProfileStructureTest_010');
      let formatArr: string[] = ['HEIC'];
      HiLog.end(TAG, 'ProfileStructureTest_010');
    });

    it('ProfileStructureTest_011', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'ProfileStructureTest_011');
      let formatArr: string[] = ['XDRAW'];
      HiLog.end(TAG, 'ProfileStructureTest_011');
    });

    it('ProfileStructureTest_012', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'ProfileStructureTest_012');
      let formatArr: string[] = ['YUV_420_SP'];
      expect(getPreviewAndVideoFormat(formatArr, true)).assertEqual(camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP);
      HiLog.end(TAG, 'ProfileStructureTest_012');
    });

  });
}