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

import { afterAll, beforeAll, describe, expect, it, Level } from '@ohos/hypium';
import { Driver } from '@ohos.UiTest';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { TestConstants } from '../../TestConstants';
import { TestUtils } from '../../utils/TestUtils';
import { CommonHandler } from '../../aw/CommonHandler';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'SavePowerModeTest';

export default function savePowerModeTest() {
  describe('savePowerModeTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'SPM Ability test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(60);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'SPM Ability test is finished.');
      });
    });

    /**
     * 进入省电模式
     */
    it('Ability_Into_Save_Power_Mode', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Ability_Into_Save_Power_Mode');
      await driver.delayMs(TestConstants.DELAY_INTO_SAVE_POWER_MODE);
      let id = ComponentIdKeys.SAVE_POWER_MODE_VIEW;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Ability_Into_Save_Power_Mode');
    });

    /**
     * 退出省电省电模式
     */
    it('Ability_Exit_Save_Power_Mode', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Ability_Exit_Save_Power_Mode');
      let id = ComponentIdKeys.SAVE_POWER_MODE_VIEW;
      HiLog.i(TAG, 'click the screen.');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click the screen success.');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Ability_Exit_Save_Power_Mode');
    });
  })
}