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
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { TestConstants } from '../../../TestConstants';
import { CommonHandler } from '../../../aw/CommonHandler';
import { TestUtils } from '../../../utils/TestUtils';
import { SettingsPageHandler } from '../../../aw/SettingsPageHandler';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';
import { KeyCode } from '@ohos.multimodalInput.keyCode';

const TAG: string = TestConstants.TAG + '_' + 'VideoModeTestTest';

export default function VideoModeTest() {
  describe('VideoModeTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'VideoModeTest test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(16);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'VideoModeTest test is finished.');
      });
    });

    /**
     * 录像模式
     */
    it('VideoModeTestFirst', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'VideoModeTestFirst');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'videoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'VideoModeTestFirst');
    });

    /**
     * 录像中切换分辨率1/前后置/录像/查看录像
     */
    it('VideoModeTest_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'VideoModeTest_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'VIDEO more');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_002', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_003', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_004', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution 1');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '1');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_005', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_006', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_007', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_008', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_009', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_010', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_011', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_012', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution 1');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '1');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_013', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_014', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_015', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_016', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_017', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera back');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    /**
     * 录像中切换分辨率2/前后置/录像/查看录像
     */
    it('VideoModeTest_018', Level.LEVEL0, async () => {
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'VIDEO more');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_019', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_020', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_021', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution 2');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '2');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_022', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_023', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_024', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_025', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_026', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_027', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_028', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_029', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution 2');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '2');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_030', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_031', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_032', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_033', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_034', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera back');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND)
      expect(id).not().assertNull();
    });

    /**
     * 录像中切换分辨率3/前后置/录像/查看录像
     */
    it('VideoModeTest_035', Level.LEVEL0, async () => {
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'VIDEO more');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_036', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_037', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_038', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution 2');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '3');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_039', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_040', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_041', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_042', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_043', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_044', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_045', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_046', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution 2');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '3');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_047', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_048', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_049', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_050', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_051', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera back');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    /**
     * 录像中切换分辨率4/前后置/录像/查看录像
     */
    it('VideoModeTest_052', Level.LEVEL0, async () => {
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'VIDEO more');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_053', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_054', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_055', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution 2');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '4');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_056', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_057', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_058', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_059', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_060', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_061', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_062', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_063', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution 2');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '4');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_064', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_065', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_066', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_067', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_068', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera back');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    /**
     * 录像中切换帧率1/前后置/录像/查看录像
     */
    it('VideoModeTest_069', Level.LEVEL0, async () => {
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'VIDEO more');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_070', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_071', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.FRAME_RATE);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_072', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution 1');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.FRAME_RATE, '1');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_073', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_074', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_075', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_076', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_077', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_078', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_079', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.FRAME_RATE);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_080', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution 1');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.FRAME_RATE, '1');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_081', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_082', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_083', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_084', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_085', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera back');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    /**
     * 录像中切换帧率2/前后置/录像/查看录像
     */
    it('VideoModeTest_086', Level.LEVEL0, async () => {
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'VIDEO more');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_087', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_088', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.FRAME_RATE);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_089', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution 2');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.FRAME_RATE, '2');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_090', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_091', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_092', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_093', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_094', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_095', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_096', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.FRAME_RATE);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_097', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'resolution 2');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.FRAME_RATE, '2');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_098', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_099', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_100', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_101', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_102', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_103', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'BasicVideo_Stabilization_002');
      HiLog.i(TAG, 'treasureBox open.');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });
    it('VideoModeTest_104', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasure box slide from to right');
      await TestUtils.slideTreasureBox(driver);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_105', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'itemVideoResolution.');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });
    it('VideoModeTest_106', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'itemVideoResolution 720p.');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '4');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });
    it('VideoModeTest_107', Level.LEVEL0, async () => {
      await TestUtils.testIsExist(driver, 'TREASURE_BOX_SECOND_LIST_BACK_BUTTON').then(() => {
        HiLog.i(TAG, 'back to treasure Box Level first page');
      });
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });
    it('VideoModeTest_109', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox close');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });
    it('VideoModeTest_110', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });
    it('VideoModeTest_111', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera back');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });
    it('VideoModeTest_112', Level.LEVEL0, async () => {
      await driver.triggerKey(KeyCode.KEYCODE_VOLUME_UP);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('VideoModeTest_113', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'shutter photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_ON_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('VideoModeTest_115', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'again volumeUp clicked');
      await driver.triggerKey(KeyCode.KEYCODE_VOLUME_DOWN);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });
    it('VideoModeTest_116', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open.');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });
    it('VideoModeTest_118', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox close');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'BasicVideo_Stabilization_002');
    });
    /**
     * VideoModeTest 恢复默认值
     */
    it('VideoModeTest_Restore', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'VideoModeTest_Restore');
      await CommonHandler.PhotoBack(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'VideoModeTest_Restore');
    });
  });
}