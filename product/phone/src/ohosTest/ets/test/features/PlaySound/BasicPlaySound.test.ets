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

const TAG: string = TestConstants.TAG + '_' + 'basicPlaySoundTest';

export default function basicPlaySoundTest() {
  describe('basicPlaySoundTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'basicPlaySound test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(47);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'basicPlaySound test is finished.');
      });
    });

    /**
     * 拍照
     */
    it('basicPlaySoundTest_1', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_1');

      HiLog.i(TAG, 'photoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'middle area clicked');
      await driver.click(650, 1050);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

      await CommonHandler.PhotoCommon(driver).then(() => {
        HiLog.i(TAG, 'photo captured successful.');
      });
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      HiLog.end(TAG, 'basicPlaySoundTest_1');
    });

    /**
     * 连拍
     */
    it('basicPlaySoundTest_2', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_2');

      HiLog.i(TAG, 'photoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'middle area clicked');
      await driver.click(650, 1050);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'long press to burst shot');
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.testLongClickById(driver, id, 0);
      await TestUtils.slideForBurst(driver);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicPlaySoundTest_2');
    });

    /**
     * 录像模式
     */
    it('basicPlaySoundTest_3', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_3');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'videoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicPlaySoundTest_3');
    });

    /**
     * 录像抓拍
     * 1.点击开始录像
     * 2.点击抓拍
     * 3.点击结束录像
     */
    it('basicPlaySoundTest_4_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_4_01');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicPlaySoundTest_4_01');
    });

    it('basicPlaySoundTest_4_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_4_02');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'shutter photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_ON_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicPlaySoundTest_4_02');
    });

    it('basicPlaySoundTest_4_03', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_4_03');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicPlaySoundTest_4_03');
    });

    /**
     * 前置录像
     */
    it('basicPlaySoundTest_5_01', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_5_01');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_FIVE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicPlaySoundTest_5_01');
    });

    it('basicPlaySoundTest_5_02', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_5_02');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicPlaySoundTest_5_02');
    });

    it('basicPlaySoundTest_5_03', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_5_03');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'pause recording');
      let id = ComponentIdKeys.VIDEO_RECORDING_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicPlaySoundTest_5_03');
    });

    it('basicPlaySoundTest_5_04', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_5_04');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'continue recording');
      let id = ComponentIdKeys.VIDEO_PAUSE_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicPlaySoundTest_5_04');
    });

    it('basicPlaySoundTest_5_05', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_5_05');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'end recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicPlaySoundTest_5_05');
    });

    /**
     * 恢复录像后置
     */
    it('basicPlaySoundTest_6', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_6');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'switch camera back');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_FIVE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicPlaySoundTest_6');
    });

    /**
     * 音量键录像
     */
    it('basicPlaySoundTest_7_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_7_01');
      HiLog.i(TAG, 'videoMode');

      HiLog.i(TAG, 'volumeUp clicked');
      await driver.triggerKey(KeyCode.KEYCODE_VOLUME_UP);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      expect(id).not().assertNull();

      HiLog.end(TAG, 'basicPlaySoundTest_7_01');
    });

    it('basicPlaySoundTest_7_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_7_02');

      HiLog.i(TAG, 'again volumeUp clicked');
      await driver.triggerKey(KeyCode.KEYCODE_VOLUME_DOWN);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicPlaySoundTest_7_02');
    });

    it('basicPlaySoundTest_7_03', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicPlaySoundTest_7_03');

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
      HiLog.end(TAG, 'basicPlaySoundTest_7_03');
    });

    /**
     * basicPlaySound 恢复默认值
     */
    it('basicPlaySound_Restore', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'basicPlaySound_Restore');
      await CommonHandler.PhotoBack(driver);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await SettingsPageHandler.RestoreDefaultValue(driver).then(() => {
        HiLog.i(TAG, 'basicPlaySound test is restore default value.');
      });
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'basicPlaySound_Restore');
    });
  });
}