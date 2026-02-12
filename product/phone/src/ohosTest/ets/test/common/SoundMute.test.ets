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
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { TestConstants } from '../../TestConstants';
import { TestUtils } from '../../utils/TestUtils';
import { CommonHandler } from '../../aw/CommonHandler';
import { SettingsPageHandler } from '../../aw/SettingsPageHandler';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'SoundMuteTest';

export default function soundMuteTest() {
  describe('SoundMuteTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'SoundMute test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(38);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'SoundMute test is finished.');
      });
    });

    /**
     * 拍照模式
     */
    it('SoundMute_Mode_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SoundMute_Mode_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'photo Mode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SoundMute_Mode_001.');
    });


    /**
     * 设置页 静音打开
     * 1.进入设置页
     * 2.上滑
     * 3.点击静音
     * 4.返回预览页
     */
    it('SoundMute_Open_001_001', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'SoundMute_Open_001_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await SettingsPageHandler.SettingViewOpen(driver).then(() => {
        HiLog.i(TAG, 'settingView enter');
      });
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SoundMute_Open_001_001');
    });

    it('SoundMute_Open_001_002', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'SoundMute_Open_001_002');
      HiLog.i(TAG, 'slide up');
      await TestUtils.slideUpHalfScreen(driver);
      await TestUtils.slideUpHalfScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SoundMute_Open_001_002');
    });

    it('SoundMute_Open_001_003', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'SoundMute_Open_001_003');
      HiLog.i(TAG, 'itemSoundMute clicked');
      let id = ComponentIdKeys.getInstance().getKey('SettingItemComponentTOGGLE', FunctionId.SOUND_MUTE);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await SettingsPageHandler.SettingViewClose(driver).then(() => {
        HiLog.i(TAG, 'settingView close, back to preview.');
      });
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SoundMute_Open_001_003');
    });

    it('SoundMute_Open_001_004', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'SoundMute_Open_001_004');
      HiLog.i(TAG, 'back preview');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'SoundMute_Open_001_004');
    });

    /**
     * 退出应用
     * 打开应用
     */
    it('SettingToggle_Start_001', Level.LEVEL0, async () => {
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'back to homepage.');
      });
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'ability is start.');
      });

      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    /**
     * 静音拍照
     */
    it('SettingToggle_TakePhoto', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingToggle_TakePhoto');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await CommonHandler.PhotoCommon(driver).then(() => {
        HiLog.i(TAG, 'photo captured successful.');
      });
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingToggle_TakePhoto');
    });

    /**
     * 静音录像 再切模式
     * 1.录像模式
     * 2.录像
     * 3.拍照模式
     */
    it('SoundMute_ModeChange_001_001', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'SoundMute_ModeChange_001_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'video Mode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      await CommonHandler.VideoCommon(driver).then(() => {
        HiLog.i(TAG, 'video recorded successful.');
      });
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SoundMute_ModeChange_001_001');
    });

    it('SoundMute_ModeChange_001_002', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'SoundMute_ModeChange_001_002');
      HiLog.i(TAG, 'photo Mode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SoundMute_ModeChange_001_002');
    });

    /**
     * 设置页 静音关闭
     * 1.进入设置页
     * 2.上滑
     * 3.点击静音
     * 4.返回预览页
     */
    it('SoundMute_Close_001_001', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'SoundMute_Close_001_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await SettingsPageHandler.SettingViewOpen(driver).then(() => {
        HiLog.i(TAG, 'settingView enter');
      });
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SoundMute_Close_001_001');
    });

    it('SoundMute_Close_001_002', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'SoundMute_Close_001_002');
      HiLog.i(TAG, 'slide up');
      await TestUtils.slideUpHalfScreen(driver);
      await TestUtils.slideUpHalfScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.getInstance().getKey('SettingItemComponentTOGGLE', FunctionId.SOUND_MUTE);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SoundMute_Close_001_002');
    });

    it('SoundMute_Close_001_003', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'SoundMute_Close_001_003');
      HiLog.i(TAG, 'itemSoundMute clicked');
      let id = ComponentIdKeys.getInstance().getKey('SettingItemComponentTOGGLE', FunctionId.SOUND_MUTE);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await SettingsPageHandler.SettingViewClose(driver).then(() => {
        HiLog.i(TAG, 'settingView close, back to preview.');
      });
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SoundMute_Close_001_003');
    });


    /*
     * SoundMute 恢复默认值
     */
    it('SoundMute_Restore', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'SoundMute_Restore');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await SettingsPageHandler.RestoreDefaultValue(driver).then(() => {
        HiLog.i(TAG, 'SoundMute test is restore default value.');
      });
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SoundMute_Restore');
    });
  });
}