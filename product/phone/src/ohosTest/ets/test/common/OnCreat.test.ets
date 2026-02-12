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
import { TestConstants } from '../../TestConstants';
import { TestUtils } from '../../utils/TestUtils';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { CommonHandler } from '../../aw/CommonHandler';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'OnCreateTest';
const delegator: AbilityDelegatorRegistry.AbilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();

export default function onCreateTest() {
  describe('OnCreateTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'OnCreate test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(2);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'OnCreate test is finished.');
      });
    });

    /**
     * 侧滑退出
     * 进入相机
     */
    it('OnCreate_Start_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'OnCreate_Start_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'slide left from screen');
      await TestUtils.slideLeftFromScreen(driver);
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'ability is start.');
      });
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OnCreate_Start_001');
    });

    /**
     * 上滑退出
     * 进入相机
     */
    it('OnCreate_Start_002', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'OnCreate_Start_002');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'slide up from screen');
      await TestUtils.slideUpFromBottom(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'ability is start.');
      });
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OnCreate_Start_002');
    });

    /**
     * 息亮屏进入相机
     * 1.息屏
     * 2.亮屏
     * 3.解锁屏幕
     * 4.进入相机
     */
    it('OnCreate_Lock_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'OnCreate_Lock_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'OOK down.');
      await delegator.executeShellCommand(TestConstants.KEY_POWER);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'OOK down, second.');
      await delegator.executeShellCommand(TestConstants.KEY_POWER);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'unlock, back to homepage.');
      await delegator.executeShellCommand(TestConstants.KEY_UNLOCK);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'ability is start.');
      });
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OnCreate_Lock_001');
    });
  })
}