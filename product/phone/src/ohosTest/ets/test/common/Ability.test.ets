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
import { TestConstants } from '../../TestConstants';
import { TestUtils } from '../../utils/TestUtils';
import { CommonHandler } from '../../aw/CommonHandler';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'AbilityTest';

export default function abilityTest() {
  describe('ActsAbilityTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'Ability test is start');
      });
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(3);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'Ability test is finished.');
      });
    });

    /**
     * 基础拍照
     * 1.拍照模式
     * 2.点击拍照
     * 3.查看缩略图
     * 4.滑动返回
     * 5.返回相机
     */
    it('Ability_TakePhoto', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Ability_TakePhoto');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'photoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'click to take photos');
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'click on the thumbnail');
      id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'slide left from screen');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Ability_TakePhoto');
    });

    /**
     * 拍照前后置切换
     * 1.点击切换前后置
     * 2.点击拍照
     * 3.点击切换前后置
     */
    it('Ability_SwitchPhoto_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Ability_SwitchPhoto_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'choose portrait dialog.');
      id = ComponentIdKeys.RADIO_OPEN_PORTRAIT_BEAUTY;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'conform dialog.');
      id = ComponentIdKeys.BUTTON_CONFIRM_PORTRAIT_BEAUTY;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'click to take a photo');
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'switch camera back');
      id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'Ability_SwitchPhoto_001');
    });

    /**
     * 基础录像
     * 1.点击录像模式
     * 2.点击开始录像
     * 3.点击暂停录像 点击继续录像
     * 4.点击暂停录像 点击继续录像
     * 5.点击结束录像
     */
    it('Ability_VideoRecord_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Ability_VideoRecord_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'videoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'start recording');
      id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'pause recording');
      id = ComponentIdKeys.VIDEO_RECORDING_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'continue recording');
      id = ComponentIdKeys.VIDEO_PAUSE_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'pause recording, second');
      id = ComponentIdKeys.VIDEO_RECORDING_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'continue recording, second');
      id = ComponentIdKeys.VIDEO_PAUSE_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'end recording');
      id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'Ability_VideoRecord_001');
    });

    /**
     * 录像前后置切换
     * 1.点击录像
     * 2.点击切换前后置
     * 3.点击 开始-暂停-继续-结束 录像
     * 4.点击切换前后置
     * 5.拍照模式
     */
    it('Ability_VideoRecord_002', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Ability_VideoRecord_002');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'videoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'switch camera');
      id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'start recording');
      id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'pause recording');
      id = ComponentIdKeys.VIDEO_RECORDING_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'continue recording');
      id = ComponentIdKeys.VIDEO_PAUSE_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'end recording');
      id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'switch camera back');
      id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'photoMode');
      id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'Ability_VideoRecord_002');
    });
  })
}
