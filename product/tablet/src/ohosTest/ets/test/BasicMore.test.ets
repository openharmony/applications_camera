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
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { CommonHandler } from '../aw/CommonHandler';
import { TestConstants } from '../TestConstants';
import { SettingsPageHandler } from '../aw/SettingsPageHandler';
import { TestUtils } from '../utils/TestUtils';

const TAG: string = 'BasicMoreTest';

class MoreModeType {
  public name?: Resource | string;
  public img?: Resource;
  public isDelete?: boolean;
  public isDrag?: boolean;
  public modeType?: ModeType;
}

export default function basicMoreTest() {
  describe('BasicMoreTest', () => {
    const driver = Driver.create();
    let projectModeData: Map<ModeType, MoreModeType>;

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(async () => {
        HiLog.i(TAG, 'MoreModeIndex test is start.');
      })
    });

    afterAll(async () => {
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'MoreModeIndex test is finished.');
      });
    });

    /*
     * BasicMore 恢复默认值
     */
    it('BasicMore_Restore', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'BasicMore_Restore');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await SettingsPageHandler.RestoreDefaultValue(driver).then(() => {
        HiLog.i(TAG, 'BasicMore test is restore default value.');
      });
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'BasicMore_Restore');
    });
  });

}