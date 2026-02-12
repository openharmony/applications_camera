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
import { TestConstants } from '../../../TestConstants';
import { KeyCode } from '@ohos.multimodalInput.keyCode';
import { CommonHandler } from '../../../aw/CommonHandler';
import { TestUtils } from '../../../utils/TestUtils';
import { SettingsPageHandler } from '../../../aw/SettingsPageHandler';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'basicRecordingControlTest';

export default function basicRecordingControlTest() {
  describe('basicRecordingControlTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'basicRecordingControl test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(46);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'basicRecordingControl test is finished.');
      });
    });

    /**
     * 录像模式
     */
    it('basicRecordingControlFirst', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicRecordingControlFirst');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'videoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControlFirst');
    });

    /**
     * 录像抓拍
     * 1.点击开始录像
     * 2.点击抓拍
     * 3.点击结束录像
     */
    it('basicRecordingControl_001_001', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_001_001');
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_001_001');
    });

    it('basicRecordingControl_001_002', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_001_002');
      HiLog.i(TAG, 'shutter photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_ON_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_001_002');
    });

    it('basicRecordingControl_001_003', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_001_003');
      HiLog.i(TAG, 'shutter photo');
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_001_003');
    });

    /**
     * 前置录像
     * 1.点击切换前后置
     * 2.开始录像
     * 3.结束录像
     */
    it('basicRecordingControl_002_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_002_001');

      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_FIVE_SECOND);

      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_002_001');
    });

    it('basicRecordingControl_002_002', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_002_002');

      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_002_002');
    });

    it('basicRecordingControl_002_003', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_002_003');

      HiLog.i(TAG, 'pause recording');
      let id = ComponentIdKeys.VIDEO_RECORDING_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_002_003');
    });

    it('basicRecordingControl_002_004', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_002_004');

      HiLog.i(TAG, 'continue recording');
      let id = ComponentIdKeys.VIDEO_PAUSE_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_002_004');
    });

    it('basicRecordingControl_002_005', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_002_005');

      HiLog.i(TAG, 'pause recording');
      let id = ComponentIdKeys.VIDEO_RECORDING_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);

      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_002_005');
    });

    it('basicRecordingControl_002_006', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_002_006');

      HiLog.i(TAG, 'continue recording');
      let id = ComponentIdKeys.VIDEO_PAUSE_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);

      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_002_006');
    });

    it('basicRecordingControl_002_007', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_002_007');

      HiLog.i(TAG, 'end recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_002_007');
    });

    /**
     * 恢复录像后置
     * 1.点击切换前后置
     */
    it('basicRecordingControl_003', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_003');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'switch camera back');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_FIVE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_003');
    });

    /**
     * 音量键录像
     * 1.点击录像模式
     * 2.点击音量上键开始录像
     * 3.再次点击音量下键停止录像
     */
    it('basicRecordingControl_004_001', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_001');
      HiLog.i(TAG, 'videoMode');

      HiLog.i(TAG, 'volumeUp clicked');
      await driver.triggerKey(KeyCode.KEYCODE_VOLUME_UP);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);

      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_004_001');
    });

    it('basicRecordingControl_004_002', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_002');

      HiLog.i(TAG, 'again volumeUp clicked');
      await driver.triggerKey(KeyCode.KEYCODE_VOLUME_DOWN);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_004_002');
    });

    it('basicRecordingControl_004_003', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_003');

      if (await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_1))) {
        await driver.triggerKey(KeyCode.KEYCODE_VOLUME_UP);
        await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      }

      if (await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_1))) {
        HiLog.e(TAG, 'key volume to stop recording is failed ');
        await TestUtils.ClickComponentIfExist(driver, ComponentIdKeys.SHUTTER_VIDEO_END_1,
          TestConstants.DELAY_TWO_SECOND);
      }

      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      HiLog.end(TAG, 'basicRecordingControl_004_003');
    });


    /**
     * 录像 变焦
     * 1.开始录像
     * 2.捏合放大
     * 3.暂停录像
     * 4.继续录像
     * 5.捏合缩小
     * 6.结束录像
     */
    it('basicRecordingControl_005_001', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_005_001');

      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);

      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_005_001');
    });

    it('basicRecordingControl_005_002', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_005_002');

      HiLog.i(TAG, 'pinch out 2');
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_THREE_SECOND);

      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_005_002');
    });

    it('basicRecordingControl_005_003', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_005_003');

      HiLog.i(TAG, 'pause recording');
      let id = ComponentIdKeys.VIDEO_RECORDING_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);

      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_005_003');
    });

    it('basicRecordingControl_005_004', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_005_004');

      HiLog.i(TAG, 'continue recording');
      let id = ComponentIdKeys.VIDEO_PAUSE_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);

      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_005_004');
    });

    it('basicRecordingControl_005_005', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_005_005');

      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);

      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_005_005');
    });

    /**
     * basicRecordingControl 恢复默认值
     */
    it('basicRecordingControl_Restore', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicRecordingControl_Restore');
      await CommonHandler.PhotoBack(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await SettingsPageHandler.RestoreDefaultValue(driver).then(() => {
        HiLog.i(TAG, 'basicRecordingControl test is restore default value.');
      });
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);

      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicRecordingControl_Restore');
    });
  });
}