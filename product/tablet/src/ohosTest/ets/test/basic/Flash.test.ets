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
import { TestConstants } from '../../TestConstants';
import { TestUtils } from '../../utils/TestUtils';
import { CommonHandler } from '../../aw/CommonHandler';
import { FlashMode } from '@ohos/common/src/main/ets/function/enumbase/FlashMode';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';

const TAG: string = TestConstants.TAG + '_' + 'FlashTest';
const FLASH_ID: string = ComponentIdKeys.getInstance().getKey('TabBar', FunctionId.FLASH);

export default function flashTest() {

  describe('FlashTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'Flash test is start.');
      })
    });

    afterAll(async () => {
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'Flash test is finished.');
      });
    });

    /**
     * 初始化
     */
    it('Flash_Init', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Flash_Init');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await CommonHandler.PhotoBack(driver).then(() => {
        HiLog.i(TAG, 'position and mode is init.');
      });
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      const component = await driver.findComponent(ON.id(FLASH_ID));
      expect(component).not().assertNull();
      HiLog.end(TAG, 'Flash_Init');
    });

    /**
     * 顶部闪光灯 遍历子图标
     * 1.点击闪光灯设置 闪光灯-自动
     * 2.点击闪光灯设置 闪光灯-打开
     * 3.点击闪光灯设置 闪光灯-常亮
     * 4.点击闪光灯设置 闪光灯-关闭
     */
    it('Flash_FlashMode_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Flash_FlashMode_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashSetting open');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_FlashMode_001');
    });

    it('Flash_FlashMode_002', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Flash_FlashMode_002');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashAuto');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.AUTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_FlashMode_002');
    });

    it('Flash_FlashMode_003', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Flash_FlashMode_003');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashSetting open, second.');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_FlashMode_003');
    });

    it('Flash_FlashMode_004', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Flash_FlashMode_004');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashOn');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.ON);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_FlashMode_004');
    });

    it('Flash_FlashMode_005', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Flash_FlashMode_005');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashSetting open, third.');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_FlashMode_005');
    });

    it('Flash_FlashMode_006', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Flash_FlashMode_006');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashAlwaysOpen');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.ALWAYS_OPEN);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_FlashMode_006');
    });

    it('Flash_FlashMode_007', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Flash_FlashMode_007');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashSetting open, fourth.');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_FlashMode_007');
    });

    it('Flash_FlashMode_008', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Flash_FlashMode_008');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flash off');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.OFF);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      const component = await driver.findComponent(ON.id(FLASH_ID));
      expect(component).not().assertNull();
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_FlashMode_008');
    });

    /**
     * 顶部闪光灯 闪光灯开启拍照
     * 1.点击顶部 Flash 图标
     * 2.点击闪光灯-打开
     * 3.点击聚焦
     * 4.点击拍照
     */
    it('Flash_Function_001_001', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Flash_Function_001_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'FlashBox open');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_Function_001_001');
    });

    it('Flash_Function_001_002', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Flash_Function_001_002');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashOn');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.ON);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_Function_001_002');
    });

    it('Flash_Function_001_003', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Flash_Function_001_003');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'middle area clicked');
      await driver.click(650, 1050);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_Function_001_003');
    });

    it('Flash_Function_001_004', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Flash_Function_001_004');
      HiLog.i(TAG, 'click to take photos');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      const component = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      expect(component).not().assertNull();
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_Function_001_004');
    });

    /**
     * 顶部闪光灯 切模式保存
     * 1.点击顶部 Flash 图标
     * 2.点击闪光灯-常亮
     * 3.切换录像模式
     * 4.切换拍照模式
     * 5.点击拍照
     */
    it('Flash_Function_002_001', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Flash_Function_002_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'FlashBox open');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_Function_002_001');
    });

    it('Flash_Function_002_002', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Flash_Function_002_002');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashAlwaysOpen');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.ALWAYS_OPEN);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_Function_002_002');
    });

    it('Flash_Function_002_003', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Flash_Function_002_003');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'videoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_Function_002_003');
    });

    it('Flash_Function_002_004', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Flash_Function_002_004');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'photoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_Function_002_004');
    });

    it('Flash_Function_002_005', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Flash_Function_002_005');
      HiLog.i(TAG, 'click to take photos');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      const component = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      expect(component).not().assertNull();
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_Function_002_005');
    });

    /**
     * 顶部闪光灯 退出进入
     * 1.点击顶部 Flash 图标
     * 2.点击闪光灯-自动
     * 3.滑动退出
     * 4.进入应用
     * 5.点击拍照
     */
    it('Flash_Function_003_001', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Flash_Function_003_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'FlashBox open');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_Function_003_001');
    });

    it('Flash_Function_003_002', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Flash_Function_003_002');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flash Auto');
      let id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.AUTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_Function_003_002');
    });

    it('Flash_Function_003_003', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Flash_Function_003_003');
      HiLog.i(TAG, 'slide left from screen');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'ability is start.');
      });
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_Function_003_003');
    });

    it('Flash_Function_003_004', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Flash_Function_003_004');
      HiLog.i(TAG, 'click to take photos');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      const component = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      expect(component).not().assertNull();
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Flash_Function_003_004');
    });

  })
}