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
import { TestConstants } from '../../../../../TestConstants';
import { CommonHandler } from '../../../../../aw/CommonHandler';
import { TestUtils } from '../../../../../utils/TestUtils';
import { SettingsPageHandler } from '../../../../../aw/SettingsPageHandler';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'TimeLapseViewTest';

export default function timeLapseViewTest() {
  describe('TimeLapseViewTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'TimeLapseView test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(29);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'TimeLapseView test is finished.');
      });
    });

    /*
     * 设置页 定时拍照
     * 1.拍照模式
     */
    it('TimeLapseView_Function_001_01', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_001_01');
      HiLog.begin(TAG, 'TimeLapseView_Function_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'photo Mode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TimeLapseView_Function_001_01');
    });

    /*
     * 设置页 定时拍照
     * 2.进入设置页
     */
    it('TimeLapseView_Function_001_02', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_001_02');
      await SettingsPageHandler.SettingViewOpen(driver).then(() => {
        HiLog.i(TAG, 'settingView enter');
      });
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TimeLapseView_Function_001_02');
    });

    /*
     * 设置页 定时拍照
     * 3.点击定时拍照 若当前页没有上滑
     */
    it('TimeLapseView_Function_001_03', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_001_03');
      HiLog.i(TAG, 'slide up');
      await TestUtils.slideUpHalfScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TimeLapseView_Function_001_03');
    });

    it('TimeLapseView_Function_001_04', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_001_04');
      HiLog.i(TAG, 'itemTimeLapse clicked');
      let idItem = ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', FunctionId.TIME_LAPSE);
      await TestUtils.ClickComponentIfExist(driver, idItem, TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TimeLapseView_Function_001_04');
    });

    it('TimeLapseView_Function_001_05', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_001_05');
      let idDialog = await driver.findComponent(ON.id('COMPONENT_ID_SETTING_DIALOG_ITEM_TIME_OFF'));
      let isSelected = await idDialog.isSelected();
      if (!isSelected) {
        HiLog.i(TAG, 'Timer off toggle click');
        await idDialog.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      }
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TimeLapseView_Function_001_05');
    });

    /*
     * 设置页 定时拍照
     * 5.第二次点击定时拍摄 2s  2
     */
    it('TimeLapseView_Function_001_06', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_001_06');
      let com = await driver.findComponent(ON.id(ComponentIdKeys.SETTING_DIALOG_ITEM_CANCEL_1));
      if (!com) {
        HiLog.i(TAG, 'itemTimeLapse clicked, second.');
        let idItem = ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', FunctionId.TIME_LAPSE);
        await TestUtils.ClickComponentIfExist(driver, idItem, TestConstants.DELAY_ONE_SECOND);
      }
      HiLog.i(TAG, 'itemTimeLapse 2s');
      let id = ComponentIdKeys.getInstance().getKey('SettingDialog', FunctionId.TIME_LAPSE, '2');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TimeLapseView_Function_001_06');
    });

    /*
     * 设置页 定时拍照
     * 6.第三次点击定时拍摄 5s  3
     */
    it('TimeLapseView_Function_001_07', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_001_07');
      HiLog.i(TAG, 'itemTimeLapse clicked, third.');
      let idItem = ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', FunctionId.TIME_LAPSE);
      await TestUtils.ClickComponentIfExist(driver, idItem, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemTimeLapse 5s');
      let id = ComponentIdKeys.getInstance().getKey('SettingDialog', FunctionId.TIME_LAPSE, '3');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TimeLapseView_Function_001_07');
    });

    /*
     * 设置页 定时拍照
     * 7.第四次点击定时拍摄 10s  4
     */
    it('TimeLapseView_Function_001_08', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_001_08');
      HiLog.i(TAG, 'itemTimeLapse clicked, fourth.');
      let idItem = ComponentIdKeys.getInstance().getKey('SettingItemPOPUP', FunctionId.TIME_LAPSE);
      await TestUtils.ClickComponentIfExist(driver, idItem, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemTimeLapse 10s');
      let id = ComponentIdKeys.getInstance().getKey('SettingDialog', FunctionId.TIME_LAPSE, '4');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TimeLapseView_Function_001_08');
    });

    /*
     * 设置页 定时拍照
     * 8.侧滑两次
     */
    it('TimeLapseView_Function_001_09', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_001_09');
      HiLog.i(TAG, 'slide left twice');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TimeLapseView_Function_001_09');
    });

    it('TimeLapseView_Function_001_10', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_001_10');
      HiLog.i(TAG, 'click to take a photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      let timelapseViewKey = 'TimerLapseView';
      const component = await driver.findComponent(ON.id(timelapseViewKey));
      if (component) {
        expect(component).not().assertNull();
      }
      HiLog.end(TAG, 'TimeLapseView_Function_001_10');
    });

    it('TimeLapseView_Function_001_11', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_001_11');
      HiLog.i(TAG, 'middle area clicked');
      await driver.click(650, 1050);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TimeLapseView_Function_001');
      HiLog.end(TAG, 'TimeLapseView_Function_001_11');
    });

    /**
     * 1.切换到录像模式
     */
    it('TimeLapseView_Function_003_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_003_01');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'videoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_FIVE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TimeLapseView_Function_003_01');
    });

    /**
     * 2.2S后开始录像
     */
    it('TimeLapseView_Function_003_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_003_02');
      HiLog.i(TAG, 'start recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      let timelapseViewKey = 'TimerLapseView';
      let component = await driver.findComponent(ON.id(timelapseViewKey));
      if (component) {
        expect(component).not().assertNull();
      }
      HiLog.i(TAG, 'middle area clicked');
      await driver.click(650, 1050);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.end(TAG, 'TimeLapseView_Function_003_02');
    });

    /**
     * 3.结束录像
     */
    it('TimeLapseView_Function_003_03', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_003_03');
      HiLog.i(TAG, 'end recording');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      let component = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      if (component) {
        expect(component).not().assertNull();
      }
      HiLog.end(TAG, 'TimeLapseView_Function_003_03');
    });

    /**
     * 4.切换拍照模式
     */
    it('TimeLapseView_Function_003_04', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Function_003_04');
      HiLog.i(TAG, 'photo Mode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      let component = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      if (component) {
        expect(component).not().assertNull();
      }
      HiLog.end(TAG, 'TimeLapseView_Function_003_04');
    });

    /*
     * TimeLapseView 恢复默认值
     */
    it('TimeLapseView_Restore', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'TimeLapseView_Restore');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await SettingsPageHandler.RestoreDefaultValue(driver).then(() => {
        HiLog.i(TAG, 'TimeLapseView test is restore default value.');
      });
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'TimeLapseView_Restore');
    });
  });
}