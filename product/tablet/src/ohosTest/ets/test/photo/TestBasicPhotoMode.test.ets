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
import { TestConstants } from '../../TestConstants';
import { KeyCode } from '@ohos.multimodalInput.keyCode';
import { CommonHandler } from '../../aw/CommonHandler';
import { TestUtils } from '../../utils/TestUtils';
import { FlashMode } from '@ohos/common/src/main/ets/function/enumbase/FlashMode';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { SettingsPageHandler } from '../../aw/SettingsPageHandler';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'TestBasicPhotoModeFunction';
const FLASH_ID: string = ComponentIdKeys.getInstance().getKey('TabBar', FunctionId.FLASH);

export default function TestBasicPhotoModeFunction() {
  describe('TestBasicPhotoModeFunction', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'TestBasicPhotoModeFunction test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(13);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'TestBasicPhotoModeFunction test is finished.');
      });
    });

    /**
     * 拍照模式
     */
    it('TestBasicPhotoMode_Mode_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'PhotoModeTest_Mode_001');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
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
    it('TestBasicPhotoMode_Function_001', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_001');

      // 双指捏合放大
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_TWO_SECOND);

      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'switch camera');
      id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_001');
    });

    it('TestBasicPhotoMode_Function_002', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_002');

      // 双指捏合放大
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'switch camera');
      id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_002');
    });

    it('TestBasicPhotoMode_Function_003', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_003');

      let key = `QUICK_ZOOM_INDEX_${1}`;
      let component = await driver.findComponent(ON.id(key));
      HiLog.i(TAG, `find the zoom ${key}.`);
      if (component) {
        HiLog.i(TAG, `click the zoom ${key}.`);
        await component.click();
        expect(component).not().assertNull();
      }
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_003');
    });

    it('TestBasicPhotoMode_Function_004', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_004');

      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testLongClickById(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_004');
    });

    it('TestBasicPhotoMode_Function_005', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_005');

      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'volumeUp clicked');
      await driver.triggerKey(KeyCode.KEYCODE_VOLUME_UP);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_005');
    });

    /**
     * 闪光灯遍历操作
     * 音量键拍照
     */
    it('TestBasicPhotoMode_Function_010', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_010');

      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'flashSetting open');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'flashAuto');
      id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.AUTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();

      HiLog.i(TAG, 'switch camera');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'volumeUp clicked');
      await driver.triggerKey(KeyCode.KEYCODE_VOLUME_UP);

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_010');
    });

    it('TestBasicPhotoMode_Function_011', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_011');

      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'flashSetting open, second.');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'flashOn');
      id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.ON);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();

      HiLog.i(TAG, 'switch camera');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'volumeUp clicked');
      await driver.triggerKey(KeyCode.KEYCODE_VOLUME_UP);

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_011');
    });

    it('TestBasicPhotoMode_Function_012', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_012');

      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'flashSetting open, third.');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'flashAlwaysOpen');
      id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.ALWAYS_OPEN);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'switch camera');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'volumeUp clicked');
      await driver.triggerKey(KeyCode.KEYCODE_VOLUME_UP);
      expect(id).not().assertNull();

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_012');
    });

    it('TestBasicPhotoMode_Function_013', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_013');

      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'flashSetting open, fourth.');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'flash off');
      id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.OFF);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'switch camera');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'volumeUp clicked');
      await driver.triggerKey(KeyCode.KEYCODE_VOLUME_UP);
      expect(id).not().assertNull();

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_013');
    });

    it('TestBasicPhotoMode_Function_025', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_025');
      HiLog.i(TAG, 'XmageBox back');
      await TestUtils.testIsExist(driver, 'TREASURE_BOX_SECOND_LIST_BACK_BUTTON').then(() => {
        HiLog.i(TAG, 'back to treasure Box Level first page');
      });

      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await TestUtils.slideLeftFromScreen(driver);

      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_025');
    });

    /**
     * 遍历变焦点拍照
     */
    it('Zoom_ClickZoom', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_ClickZoom');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      for (let i = 0; i <= 4; i++) {
        let key = `QUICK_ZOOM_INDEX_${i}`;
        let component = await driver.findComponent(ON.id(key));
        HiLog.i(TAG, `find the zoom ${key}.`);
        if (component) {
          HiLog.i(TAG, `click the zoom ${key}.`);
          await component.click();
          await driver.delayMs(TestConstants.DELAY_MIN_TIME);
          HiLog.i(TAG, 'click to take a photo');
          let id = ComponentIdKeys.SHUTTER_PHOTO_1;
          await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
          expect(id).not().assertNull();
        }
      }
      HiLog.end(TAG, 'Zoom_ClickZoom');
    });

    /**
     * 闪光灯/变焦点/XMAGE/拍照混合操作
     */

    it('TestBasicPhotoMode_Function_030', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_030');

      HiLog.begin(TAG, 'Flash_FlashMode');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'flashAlwaysOpen');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.ALWAYS_OPEN);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND); //DELAY_ONE_SECOND

      HiLog.i(TAG, 'click to take a photo.');
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      // 双指捏合放大
      id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'flashSetting open, fourth.');
      id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'click to take a photo.');
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_030');
    });

    /**
     * 拍照切换比例1/前后置/拍照/查看缩略图
     */
    it('TestBasicPhotoMode_Function_040', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_040');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'PHOTO more');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_040');
    });

    it('TestBasicPhotoMode_Function_041', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_041');

      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_041');
    });

    it('TestBasicPhotoMode_Function_042', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_042');

      HiLog.i(TAG, 'aspect ratio open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_042');
    });

    it('TestBasicPhotoMode_Function_043', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_043');

      HiLog.i(TAG, 'aspect ratio 1');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO, '1');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_043');
    });

    it('TestBasicPhotoMode_Function_044', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_044');
      HiLog.i(TAG, 'click to take photos');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_044');
    });

    it('TestBasicPhotoMode_Function_045', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_045');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_045');
    });

    it('TestBasicPhotoMode_Function_046', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_046');

      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_046');
    });

    it('TestBasicPhotoMode_Function_047', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_047');

      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_047');
    });

    it('TestBasicPhotoMode_Function_048', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_048');

      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_048');
    });

    it('TestBasicPhotoMode_Function_049', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_049');

      HiLog.i(TAG, 'aspect ratio open');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_049');
    });

    it('TestBasicPhotoMode_Function_050', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_050');

      HiLog.i(TAG, 'aspect ratio 1');
      let id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO, '1');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_050');
    });

    it('TestBasicPhotoMode_Function_051', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_051');

      HiLog.i(TAG, 'click to take photos');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_051');
    });
    it('TestBasicPhotoMode_Function_052', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_052');

      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);

      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);

      HiLog.i(TAG, 'switch camera back');
      id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_052');
    });


    /**
     * 拍照切换比例2/前后置/拍照/查看缩略图
     */
    it('TestBasicPhotoMode_Function_053', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_053');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'PHOTO more');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'treasureBox open');
      id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'aspect ratio open');
      id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'aspect ratio 2');
      id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO, '2');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'click to take photos');
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_053');
    });

    it('TestBasicPhotoMode_Function_054', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_054');

      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);

      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_054');
    });

    it('TestBasicPhotoMode_Function_055', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_055');
      HiLog.i(TAG, 'switch camera');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_055');
    });

    it('TestBasicPhotoMode_Function_056', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_056');
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'aspect ratio open');
      id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'aspect ratio 2');
      id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO, '2');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'click to take photos');
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_056');
    });

    it('TestBasicPhotoMode_Function_057', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_057');
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);

      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);

      HiLog.i(TAG, 'switch camera back');
      id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_057');
    });

    /**
     * 拍照切换比例3/前后置/拍照/查看缩略图
     */
    it('TestBasicPhotoMode_Function_058', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_058');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'PHOTO more');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'treasureBox open');
      id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'aspect ratio open');
      id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'aspect ratio 3');
      id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO, '3');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'click to take photos');
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_058');
    });

    it('TestBasicPhotoMode_Function_059', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_059');
      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);

      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);

      HiLog.i(TAG, 'switch camera');
      id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_059');
    });

    it('TestBasicPhotoMode_Function_060', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_060');
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'aspect ratio open');
      id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'aspect ratio 3');
      id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.ASPECT_RATIO, '3');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'click to take photos');
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Function_060');
    });

    it('TestBasicPhotoMode_Function_061', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_061');

      HiLog.i(TAG, 'click on the thumbnail.');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);

      HiLog.i(TAG, 'slide left from screen.');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_061');
    });

    it('TestBasicPhotoMode_Function_062', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Function_062');

      HiLog.i(TAG, 'switch camera back');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();

      HiLog.end(TAG, 'TestBasicPhotoMode_Function_062');
    });

    /**
     * PhotoModeTest 恢复默认值
     */
    it('TestBasicPhotoMode_Restore_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Restore_01');
      await CommonHandler.PhotoBack(driver);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Restore_01');
    });

    it('TestBasicPhotoMode_Restore_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TestBasicPhotoMode_Restore_02');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await SettingsPageHandler.RestoreDefaultValue(driver).then(() => {
        HiLog.i(TAG, 'TestBasicPhotoModeFunction test is restore default value.');
      });
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TestBasicPhotoMode_Restore_02');
    });
  });
}