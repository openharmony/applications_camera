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
import { TestConstants } from '../../../TestConstants';
import { KeyCode } from '@ohos.multimodalInput.keyCode';
import { CommonHandler } from '../../../aw/CommonHandler';
import { TestUtils } from '../../../utils/TestUtils';
import { FlashMode } from '@ohos/common/src/main/ets/function/enumbase/FlashMode';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { SettingsPageHandler } from '../../../aw/SettingsPageHandler';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'PhotoModeTest';
const FLASH_ID: string = ComponentIdKeys.getInstance().getKey('TabBar', FunctionId.FLASH);

export default function PhotoModeTest() {
  describe('PhotoModeTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'PhotoModeTest test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(12);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'PhotoModeTest test is finished.');
      });
    });

    /**
     * 拍照模式
     */
    it('PhotoModeTest_Mode_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'PhotoModeTest_Mode_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await CommonHandler.PhotoBack(driver);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'PhotoModeTest_Mode_001');
    });

    /**
     * 双指捏合操作
     * 切换前后置操作
     * 恢复zoom
     * 拍照
     */
    it('PhotoModeTest_Function_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'PhotoModeTest_Function_01');
      // 双指捏合放大
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_02', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'PhotoModeTest_Function_02');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_03', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_04', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'PhotoModeTest_Function_04');
      // 双指捏合放大
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_05', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_06', Level.LEVEL1, async () => {
      let key = `QUICK_ZOOM_INDEX_${1}`;
      let component = await driver.findComponent(ON.id(key));
      HiLog.i(TAG, `find the zoom ${key}.`);
      if (component) {
        HiLog.i(TAG, `click the zoom ${key}.`);
        await component.click();
      }
      expect(key).not().assertNull();
    });

    it('PhotoModeTest_Function_07', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'PhotoModeTest_Function_07');
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testLongClickById(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_08', Level.LEVEL1, async () => {
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'volumeUp clicked');
      await driver.triggerKey(KeyCode.KEYCODE_VOLUME_UP);

      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'PhotoModeTest_Function_08');
    });

    /**
     * 闪光灯遍历操作
     * 音量键拍照
     */
    it('PhotoModeTest_Function_09', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'PhotoModeTest_Function_09');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashSetting open');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_10', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'flashAuto');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.AUTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_11', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'flashSetting open, second.');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_12', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'flashOn');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.ON);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_13', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'flashSetting open, third.');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_14', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'flashAlwaysOpen');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.ALWAYS_OPEN);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_15', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'flashSetting open, fourth.');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_16', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'flash off');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.OFF);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_17', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'switch camera');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'volumeUp clicked');
      await driver.triggerKey(KeyCode.KEYCODE_VOLUME_UP);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_20', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to take a photo.');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    /**
     * 遍历变焦点拍照
     */
    it('Zoom_ClickZoom_1', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_ClickZoom');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let key = `QUICK_ZOOM_INDEX_${0}`;
      let component = await driver.findComponent(ON.id(key));
      HiLog.i(TAG, `find the zoom ${key}.`);
      if (component) {
        HiLog.i(TAG, `click the zoom ${key}.`);
        await component.click();
        await driver.delayMs(TestConstants.DELAY_MIN_TIME);
        HiLog.i(TAG, 'click to take a photo');
        let id = ComponentIdKeys.SHUTTER_PHOTO_1;
        await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
        expect(id).not().assertNull();
      }
    });

    it('Zoom_ClickZoom_2', Level.LEVEL1, async () => {
      let key = `QUICK_ZOOM_INDEX_${1}`;
      let component = await driver.findComponent(ON.id(key));
      HiLog.i(TAG, `find the zoom ${key}.`);
      if (component) {
        HiLog.i(TAG, `click the zoom ${key}.`);
        await component.click();
        await driver.delayMs(TestConstants.DELAY_MIN_TIME);
        HiLog.i(TAG, 'click to take a photo');
        let id = ComponentIdKeys.SHUTTER_PHOTO_1;
        await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
        expect(id).not().assertNull();
      }
    });

    it('Zoom_ClickZoom_3', Level.LEVEL1, async () => {
      let key = `QUICK_ZOOM_INDEX_${2}`;
      let component = await driver.findComponent(ON.id(key));
      HiLog.i(TAG, `find the zoom ${key}.`);
      if (component) {
        HiLog.i(TAG, `click the zoom ${key}.`);
        await component.click();
        await driver.delayMs(TestConstants.DELAY_MIN_TIME);
        HiLog.i(TAG, 'click to take a photo');
        let id = ComponentIdKeys.SHUTTER_PHOTO_1;
        await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
        expect(id).not().assertNull();
      }
    });

    it('Zoom_ClickZoom_4', Level.LEVEL1, async () => {
      let key = `QUICK_ZOOM_INDEX_${3}`;
      let component = await driver.findComponent(ON.id(key));
      HiLog.i(TAG, `find the zoom ${key}.`);
      if (component) {
        HiLog.i(TAG, `click the zoom ${key}.`);
        await component.click();
        await driver.delayMs(TestConstants.DELAY_MIN_TIME);
        HiLog.i(TAG, 'click to take a photo');
        let id = ComponentIdKeys.SHUTTER_PHOTO_1;
        await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
        expect(id).not().assertNull();
      }
    });

    it('Zoom_ClickZoom_5', Level.LEVEL1, async () => {
      let key = `QUICK_ZOOM_INDEX_${4}`;
      let component = await driver.findComponent(ON.id(key));
      HiLog.i(TAG, `find the zoom ${key}.`);
      if (component) {
        HiLog.i(TAG, `click the zoom ${key}.`);
        await component.click();
        await driver.delayMs(TestConstants.DELAY_MIN_TIME);
        HiLog.i(TAG, 'click to take a photo');
        let id = ComponentIdKeys.SHUTTER_PHOTO_1;
        await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
        expect(id).not().assertNull();
      }
    });

    /**
     * 闪光灯/变焦点/拍照混合操作
     */
    it('PhotoModeTest_Function_29', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'PhotoModeTest_Function_29');
      HiLog.begin(TAG, 'Flash_FlashMode');
      await driver.delayMs(TestConstants.DELAY_500_MS);

      HiLog.i(TAG, 'flashAlwaysOpen');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.ALWAYS_OPEN);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_30', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to take a photo.');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_31', Level.LEVEL1, async () => {
      // 双指捏合放大
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_32', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'flashSetting open, fourth.');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_35', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to take a photo.');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_36', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'flash off');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.OFF);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_37', Level.LEVEL1, async () => {
      let key = `QUICK_ZOOM_INDEX_1`;
      let component = await driver.findComponent(ON.id(key));
      HiLog.i(TAG, `find the zoom ${key}.`);
      if (component) {
        HiLog.i(TAG, `click the zoom ${key}.`);
        await component.click();
        expect(key).not().assertNull();
      }
    });

    it('PhotoModeTest_Function_38', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to take a photo.');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    /**
     * 拍照切换比例1/前后置/拍照/查看缩略图
     */
    it('PhotoModeTest_Function_39', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'PhotoModeTest_Function_06');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'PHOTO more');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_40', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_41', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to take photos');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      await driver.delayMs(TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_42', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_43', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_44', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_45', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_46', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'aspect ratio open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_47', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'aspect ratio 1');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO, '1');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_48', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to take photos');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      await driver.delayMs(TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_49', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_50', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_51', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera back');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    /**
     * 拍照切换比例2/前后置/拍照/查看缩略图
     */
    it('PhotoModeTest_Function_52', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'PhotoModeTest_Function_07');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'PHOTO more');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_53', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_54', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'aspect ratio open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_55', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'aspect ratio 2');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO, '2');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_56', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click to take photos');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      await driver.delayMs(TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_57', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_58', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_59', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_601', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_61', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'aspect ratio open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_62', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'aspect ratio 2');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO, '2');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_63', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click to take photos');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      await driver.delayMs(TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_64', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_65', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_66', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera back');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    /**
     * 拍照切换比例3/前后置/拍照/查看缩略图
     */
    it('PhotoModeTest_Function_67', Level.LEVEL0, async () => {
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'PHOTO more');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_68', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_69', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'aspect ratio open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_70', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'aspect ratio 3');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO, '3');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_71', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click to take photos');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      await driver.delayMs(TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_72', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_73', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_74', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_75', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_76', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'aspect ratio open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_77', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'aspect ratio 3');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO, '3');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_78', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click to take photos');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      await driver.delayMs(TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_79', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_80', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });

    it('PhotoModeTest_Function_81', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'switch camera back');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    /**
     * PhotoModeTest 恢复默认值
     */
    it('PhotoModeTest_Restore', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'PhotoModeTest_Restore');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await SettingsPageHandler.RestoreDefaultValue(driver).then(() => {
        HiLog.i(TAG, 'PhotoModeTest test is restore default value.');
      });
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'PhotoModeTest_Restore');
    });
  });
}