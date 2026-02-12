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
import { Driver, ON } from '@ohos.UiTest';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import AbilityDelegatorRegistry from '@ohos.application.abilityDelegatorRegistry';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { BusinessError } from '@ohos.base';
import { TestConstants } from '../../TestConstants';
import { TestUtils } from '../../utils/TestUtils';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';
import { CommonHandler } from '../../aw/CommonHandler';

const TAG: string = TestConstants.TAG + '_' + 'InitTest';

export default function initTest() {

  describe('InitTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'CustomFilterCard test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(1);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'CustomFilterCard test is finished.');
      });
    });
    /**
     * 打开应用
     */
    it('Init_Start', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Init_Start');
      let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
      try {
        await abilityDelegator.startAbility({
          bundleName: 'com.ohos.camera',
          abilityName: 'com.ohos.camera.MainAbility'
        });
      } catch (expection) {
        let exp = expection as BusinessError;
        expect(0).assertEqual(exp.code);
        HiLog.i(TAG, `Failed to startAbility, ${JSON.stringify(exp)}`);
      }
      HiLog.end(TAG, 'Init_Start');
    });

    /**
     * 权限
     * 隐私权限  同意
     * 引导页 跳过
     * 位置信息 允许
     */
    it('Init_Permission_1', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Init_Permission');
      let id = 'Paf.Permission.button_confirm';
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Init_Permission');
    });

    it('Init_Permission_2', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Skip_Permission');
      let id = ComponentIdKeys.STARTUP_GUIDANCE_BTN;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Skip_Permission');
    });

    it('Init_Permission_3', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Open Location Dialog');
      let id = ComponentIdKeys.LOCATION_DIALOG_ACCESS;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Open Location Dialog');
    });

    it('Init_Permission_4', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Confirm Location Dialog');
      let id = 'permission_dialog_vertical_button_1';
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Init_Permission');
    });

  })
}