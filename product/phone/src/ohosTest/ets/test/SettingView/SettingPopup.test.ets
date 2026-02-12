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
import { TestConstants } from '../../TestConstants';
import { TestUtils } from '../../utils/TestUtils';
import { CommonHandler } from '../../aw/CommonHandler';
import { SettingsPageHandler } from '../../aw/SettingsPageHandler';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'SettingPopupTest';

export default function settingPopupTest() {
  describe('SettingPopupTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'SettingPopup test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(27);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'SettingPopup test is finished.');
      });
    });

    /**
     * 1.拍照模式
     */
    it('SettingPopup_Function_001_01', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_001_01.');
      HiLog.i(TAG, 'photo Mode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_001_01.');
    });

    /**
     * 2.进入设置页
     */
    it('SettingPopup_Function_001_02', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_001_02.');
      await SettingsPageHandler.SettingViewOpen(driver).then(() => {
        HiLog.i(TAG, 'settingView enter');
      });
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.SETTING);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_001_02.');
    });

    /**
     * 3.点击照片比例 1:1  2
     */
    it('SettingPopup_Function_001_03', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_001_03.');
      HiLog.i(TAG, 'itemAspectRatio clicked');
      let idItem = ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, idItem, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemAspectRatio 1:1');
      let id = ComponentIdKeys.getInstance().getKey('SettingDialog', FunctionId.ASPECT_RATIO, '2');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_001_03.');
    });

    /**
     * 4.第二次点击照片比例 全屏  3
     */
    it('SettingPopup_Function_001_04', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_001_04.');
      HiLog.i(TAG, 'itemAspectRatio clicked, second');
      let idItem = ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, idItem, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemAspectRatio full');
      let id = ComponentIdKeys.getInstance().getKey('SettingDialog', FunctionId.ASPECT_RATIO, '3');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_001_04.');
    });

    /**
     * 5.第三次点击照片比例 4:3  1
     */
    it('SettingPopup_Function_001_05', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_001_05.');
      HiLog.i(TAG, 'itemAspectRatio clicked, third');
      let idItem = ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, idItem, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemAspectRatio 4:3');
      let id = ComponentIdKeys.getInstance().getKey('SettingDialog', FunctionId.ASPECT_RATIO, '1');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_001_05.');
    });

    /**
     * 6.侧滑两次
     */
    it('SettingPopup_Function_001_06', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_001_06.');
      HiLog.i(TAG, 'slide left twice');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_001_06.');
    });

    /**
     * 7.退出设置页 收起百宝箱
     */
    it('SettingPopup_Function_001_07', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_001_07.');
      const component = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      expect(component).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_001_07.');
    });

    /**
     * 设置页 视屏分辨率
     * 1.拍照模式
     */
    it('SettingPopup_Function_002_01', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_002_01.');
      HiLog.i(TAG, 'photo Mode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_002_01.');
    });

    /**
     * 设置页 视屏分辨率
     * 2.进入设置页
     */
    it('SettingPopup_Function_002_02', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_002_02.');
      await SettingsPageHandler.SettingViewOpen(driver).then(() => {
        HiLog.i(TAG, 'settingView enter');
      });
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_002_02.');
    });

    /**
     * 设置页 视屏分辨率
     * 3.点击视频分辨率 [16:9]4k  1
     */
    it('SettingPopup_Function_002_03', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_002_03.');
      HiLog.i(TAG, 'itemVideoResolution clicked');
      let idItem = ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', FunctionId.VIDEO_RESOLUTION);
      await TestUtils.ClickComponentIfExist(driver, idItem, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution 4k');
      let id = ComponentIdKeys.getInstance().getKey('SettingDialog', FunctionId.VIDEO_RESOLUTION, '1');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_002_03.');
    });

    /**
     * 设置页 视屏分辨率
     * 4.第二次点击视频分辨率 [全屏]1080p  2
     */
    it('SettingPopup_Function_002_04', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_002_04.');
      HiLog.i(TAG, 'itemVideoResolution clicked, second');
      let idItem = ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', FunctionId.VIDEO_RESOLUTION);
      await TestUtils.ClickComponentIfExist(driver, idItem, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution full 1080p');
      let id = ComponentIdKeys.getInstance().getKey('SettingDialog', FunctionId.VIDEO_RESOLUTION, '2');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_002_04.');
    });

    /**
     * 设置页 视屏分辨率
     * 5.第三次点击视频分辨率 [16:9]720p  4
     */
    it('SettingPopup_Function_002_05', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_002_05.');
      HiLog.i(TAG, 'itemVideoResolution clicked, third');
      let idItem = ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', FunctionId.VIDEO_RESOLUTION);
      await TestUtils.ClickComponentIfExist(driver, idItem, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution 720p');
      let id = ComponentIdKeys.getInstance().getKey('SettingDialog', FunctionId.VIDEO_RESOLUTION, '4');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_002_05.');
    });

    /**
     * 设置页 视屏分辨率
     * 6.第四次点击视频分辨率 [16:9]1080p  3
     */
    it('SettingPopup_Function_002_06', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_002_06.');
      HiLog.i(TAG, 'itemVideoResolution clicked, fourth');
      let idItem = ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', FunctionId.VIDEO_RESOLUTION);
      await TestUtils.ClickComponentIfExist(driver, idItem, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution 1080p');
      let id = ComponentIdKeys.getInstance().getKey('SettingDialog', FunctionId.VIDEO_RESOLUTION, '3');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_002_06.');
    });

    /**
     * 设置页 视屏分辨率
     * 7.侧滑两次
     */
    it('SettingPopup_Function_002_07', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_002_07.');
      HiLog.i(TAG, 'slide left twice');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_002_07.');
    });

    /**
     * 设置页 视屏分辨率
     * 8.退出设置页 收起百宝箱
     */
    it('SettingPopup_Function_002_08', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_002_08.');
      const component = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      expect(component).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_002_08.');
    });

    /**
     * 设置页 视屏帧率
     * 1.拍照模式
     */
    it('SettingPopup_Function_003_01', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_003_01.');
      HiLog.i(TAG, 'photo Mode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_003_01.');
    });

    /**
     * 设置页 视屏帧率
     * 2.进入设置页
     */
    it('SettingPopup_Function_003_02', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_003_02.');
      await SettingsPageHandler.SettingViewOpen(driver).then(() => {
        HiLog.i(TAG, 'settingView enter');
      });
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.SETTING);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_003_02.');
    });

    /**
     * 设置页 视屏帧率
     * 3.点击视频帧率 60fps  2
     */
    it('SettingPopup_Function_003_03', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_003_03.');
      HiLog.i(TAG, 'itemFrameRate clicked');
      let idItem = ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', FunctionId.FRAME_RATE);
      await TestUtils.ClickComponentIfExist(driver, idItem, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemFrameRate 60');
      let id = ComponentIdKeys.getInstance().getKey('SettingDialog', FunctionId.FRAME_RATE, '2');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_003_03.');
    });

    /**
     * 设置页 视屏帧率
     * 4.第二次点击视频帧率 30fps
     */
    it('SettingPopup_Function_003_04', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_003_04.');
      HiLog.i(TAG, 'itemFrameRate clicked, second');
      let idItem = ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', FunctionId.FRAME_RATE);
      await TestUtils.ClickComponentIfExist(driver, idItem, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemFrameRate 30');
      let id = ComponentIdKeys.getInstance().getKey('SettingDialog', FunctionId.FRAME_RATE, '1');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_003_04.');
    });

    /**
     * 设置页 视屏帧率
     * 5.侧滑两次
     */
    it('SettingPopup_Function_003_05', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_003_05.');
      HiLog.i(TAG, 'slide left twice');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_003_05.');
    });

    /**
     * 设置页 视屏帧率
     * 6.退出设置页 收起百宝箱
     */
    it('SettingPopup_Function_003_06', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingPopup_Function_003_06.');
      const component = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      expect(component).not().assertNull();
      HiLog.end(TAG, 'SettingPopup_Function_003_06.');
    });
  });
}