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

import { beforeAll, describe, expect, it, TestType } from '@ohos/hypium';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { TestConstants } from '../../../../TestConstants';
import { DirectionToAngleUtil } from '@ohos/common/src/main/ets/utils/DirectionToAngleUtil';
import { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import { CommonHandler } from '../../../../aw/CommonHandler';
import { Driver } from '@kit.TestKit';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'DirectionToAngleUtilTest';

export default function directionToAngleUtilTest() {
  describe('DirectionToAngleUtilTest', () => {
    const driver = Driver.create();
    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'DirectionToAngleUtil test is start');
      });
    });

    it('DirectionToAngleUtilTest_01', TestType.FUNCTION, async () => {
      const result = DirectionToAngleUtil.geViewRotate(WindowDirection.BOTTOM, true);
      expect(result).assertEqual(0);
    });

    it('DirectionToAngleUtilTest_02', TestType.FUNCTION, async () => {
      const result = DirectionToAngleUtil.geViewRotate(WindowDirection.BOTTOM);
      expect(result).assertEqual(180);
    });

    it('DirectionToAngleUtilTest_03', TestType.FUNCTION, async () => {
      const result = DirectionToAngleUtil.geViewRotate(WindowDirection.RIGHT);
      expect(result).assertEqual(90);
    });

    it('DirectionToAngleUtilTest_04', TestType.FUNCTION, async () => {
      const result = DirectionToAngleUtil.geViewRotate(WindowDirection.LEFT);
      expect(result).assertEqual(270);
    });

    it('DirectionToAngleUtilTest_05', TestType.FUNCTION, async () => {
      HideBugUtil.checkDtPss(55);
      const result = DirectionToAngleUtil.geViewRotate(30);
      expect(result).assertEqual(0);
    });

    it('DirectionToAngleUtilTest_06', TestType.FUNCTION, async () => {
      const result = DirectionToAngleUtil.getRotateAngleByWindowDirection(WindowDirection.TOP);
      expect(result).assertEqual(0);
    });

    it('DirectionToAngleUtilTest_07', TestType.FUNCTION, async () => {
      const result = DirectionToAngleUtil.getRotateAngleByWindowDirection(WindowDirection.BOTTOM);
      expect(result).assertEqual(180);
    });

    it('DirectionToAngleUtilTest_08', TestType.FUNCTION, async () => {
      const result = DirectionToAngleUtil.getRotateAngleByWindowDirection(WindowDirection.RIGHT);
      expect(result).assertEqual(90);
    });

    it('DirectionToAngleUtilTest_09', TestType.FUNCTION, async () => {
      const result = DirectionToAngleUtil.getRotateAngleByWindowDirection(WindowDirection.LEFT);
      expect(result).assertEqual(-90);
    });

    it('DirectionToAngleUtilTest_10', TestType.FUNCTION, async () => {
      const result = DirectionToAngleUtil.getRotateAngleByWindowDirection(30);
      expect(result).assertEqual(0);

    });
  })
}