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
import { TestConstants } from '../../TestConstants';
import { TestUtils } from '../../utils/TestUtils';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { CommonHandler } from '../../aw/CommonHandler';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { SettingsPageHandler } from '../../aw/SettingsPageHandler';
import { KeyCode } from '@kit.InputKit';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'PickerTest';
const delegator: AbilityDelegatorRegistry.AbilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();

export default function PickerTest() {
  describe('PickerTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'OnCreate test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(64);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'OnCreate test is finished.');
      });
    });

    /**
     * 初始化工具包
     */
    it('PickerTest_init', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'PickerTest_init');
      await delegator.executeShellCommand(TestConstants.START_UP_PICKER_DEMO);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      if (await driver.findComponent(ON.id('extension_checked'))) {
        await TestUtils.ClickComponentIfExist(driver, 'extension_checked', TestConstants.DELAY_ONE_SECOND);
      }
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      if (await driver.findComponent(ON.id('video5_checked'))) {
        await TestUtils.ClickComponentIfExist(driver, 'video5_checked', TestConstants.DELAY_ONE_SECOND);
      }
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      if (await driver.findComponent(ON.id('multiMode_checked'))) {
        await TestUtils.ClickComponentIfExist(driver, 'multiMode_checked', TestConstants.DELAY_ONE_SECOND);
      }
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      if (await driver.findComponent(ON.id('switchToPC_checked'))) {
        await TestUtils.ClickComponentIfExist(driver, 'switchToPC_checked', TestConstants.DELAY_ONE_SECOND);
      }
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      if (await driver.findComponent(ON.id('switchToPC_checked'))) {
        await TestUtils.ClickComponentIfExist(driver, 'switchToPC_checked', TestConstants.DELAY_ONE_SECOND);
        expect('switchToPC_checked').not().assertNull();
      }

      HiLog.end(TAG, 'PickerTest_init');
    });

    /**
     * 拉起picker进行基础拍照
     */
    it('PickerTest_01', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'OnCreate_Start_001');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'click picker 前置拍照');
      // 如果uiextention选中 则取消选中
      if (await driver.findComponent(ON.id('extension_checked'))) {
        await TestUtils.ClickComponentIfExist(driver, 'extension_checked', TestConstants.DELAY_ONE_SECOND);
      }
      let frontPhotoComponent = await driver.findComponent(ON.id('foreCapture'));
      if (!frontPhotoComponent) {
        HiLog.i(TAG, 'click picker fail');
        return;
      }
      HiLog.i(TAG, 'click the frontPhotoComponent');
      await frontPhotoComponent.click();
      let count = 0;
      while (!await driver.findComponent(ON.id('PICKER_PRIVACY_DIALOG_BUTTON')) &&
        !await driver.findComponent(ON.id('COMPONENT_ID_SHUTTER_PHOTO_1')) && count < 10) {
        HiLog.i(TAG, 'try to await picker start');
        count += 3;
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      }
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await TestUtils.ClickComponentIfExist(driver, 'PICKER_PRIVACY_DIALOG_BUTTON', TestConstants.DELAY_ONE_SECOND);
      if (!AppStorage.get('onPreviewFrameStart')) {
        await driver.assertComponentExist(ON.id('onPreviewFrameStart'));
      }
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let shutterComponent = await driver.findComponent(ON.id('COMPONENT_ID_SHUTTER_PHOTO_1'));
      await driver.assertComponentExist(ON.id('COMPONENT_ID_SHUTTER_PHOTO_1'));
      if (!shutterComponent) {
        return;
      }
      HiLog.i(TAG, 'click the shutterButton');
      await shutterComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let confirmComponent = await driver.findComponent(ON.id('COMPONENT_ID_THIRDPARTYCALL_CONFIRM_1'));
      await driver.assertComponentExist(ON.id('COMPONENT_ID_THIRDPARTYCALL_CONFIRM_1'));
      if (!confirmComponent) {
        return;
      }
      HiLog.i(TAG, 'click the confirmComponent');
      await confirmComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.end(TAG, 'OnCreate_Start_001');
    });

    /**
     * 前置拍照
     * 1. 进设置
     * 2. 切照片比例1：1
     * 3. 返回拍照
     * 4. 确认返回
     */
    it('PickerTest_03', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'PickerTest_03');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click picker 前置拍照');
      let frontPhotoComponent = await driver.findComponent(ON.id('foreCapture'));
      if (!frontPhotoComponent) {
        return;
      }
      await frontPhotoComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);

      if (!AppStorage.get('onPreviewFrameStart')) {
        await driver.assertComponentExist(ON.id('onPreviewFrameStart'));
      }
      HiLog.i(TAG, 'open the setting page');
      await SettingsPageHandler.SettingViewOpen(driver);

      HiLog.i(TAG, 'click the aspect item');
      await TestUtils.ClickComponentIfExist(driver, 'COMPONENT_ID_SETTING_PHOTO_ITEM_0',
        TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click 4:3');
      await TestUtils.ClickComponentIfExist(driver, 'COMPONENT_ID_SETTING_DIALOG_ITEM_RADIO_0',
        TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'back from the setting page');

      let backToPhoto = await driver.findComponent(ON.id(ComponentIdKeys.NAV_DESTINATION_TITLE_BACK_1));
      await backToPhoto.click();
      HiLog.i(TAG, 'take photo');
      let shutterComponent = await driver.findComponent(ON.id('COMPONENT_ID_SHUTTER_PHOTO_1'));
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id('COMPONENT_ID_SHUTTER_PHOTO_1'));
      if (!shutterComponent) {
        return;
      }
      HiLog.i(TAG, 'click the shutterButton');
      await shutterComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let confirmComponent = await driver.findComponent(ON.id('COMPONENT_ID_THIRDPARTYCALL_CONFIRM_1'));
      await driver.assertComponentExist(ON.id('COMPONENT_ID_THIRDPARTYCALL_CONFIRM_1'));
      if (!confirmComponent) {
        return;
      }
      await confirmComponent.click();
      HiLog.end(TAG, 'PickerTest_03');
    });

    /**
     * 前置拍照
     * 1. 切后置
     * 2. 判断是否能起流
     * 3. 拍照，返回
     */
    it('PickerTest_04', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'PickerTest_04');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click picker 前置拍照');
      let frontPhotoComponent = await driver.findComponent(ON.id('foreCapture'));
      if (!frontPhotoComponent) {
        return;
      }
      await frontPhotoComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      if (!AppStorage.get('onPreviewFrameStart')) {
        await driver.assertComponentExist(ON.id('onPreviewFrameStart'));
      }

      HiLog.i(TAG, 'ready to switch camera to back ');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await TestUtils.ClickComponentIfExist(driver, 'COMPONENT_ID_SWITCH_CAMERA_1', TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id('cameraPosition:1'));
      if (!AppStorage.get('onPreviewFrameStart')) {
        await driver.assertComponentExist(ON.id('onPreviewFrameStart'));
      }

      HiLog.i(TAG, 'take photo');
      let shutterComponent = await driver.findComponent(ON.id('COMPONENT_ID_SHUTTER_PHOTO_1'));
      await driver.assertComponentExist(ON.id('COMPONENT_ID_SHUTTER_PHOTO_1'));
      if (!shutterComponent) {
        return;
      }
      HiLog.i(TAG, 'click the shutterButton');
      await shutterComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let confirmComponent = await driver.findComponent(ON.id('COMPONENT_ID_THIRDPARTYCALL_CONFIRM_1'));
      await driver.assertComponentExist(ON.id('COMPONENT_ID_THIRDPARTYCALL_CONFIRM_1'));
      if (!confirmComponent) {
        return;
      }
      await confirmComponent.click();
      HiLog.end(TAG, 'PickerTest_04');
    });

    /**
     * 1. 后置拍照
     * 2. 判断是否能起流
     * 3. 拍照，返回
     */
    it('PickerTest_05', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'PickerTest_05');
      HiLog.i(TAG, 'click picker 后置拍照');
      let frontPhotoComponent = await driver.findComponent(ON.id('backCapture'));
      if (!frontPhotoComponent) {
        return;
      }
      await frontPhotoComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      if (!AppStorage.get('onPreviewFrameStart')) {
        await driver.assertComponentExist(ON.id('onPreviewFrameStart'));
      }
      let shutterComponent = await driver.findComponent(ON.id('COMPONENT_ID_SHUTTER_PHOTO_1'));
      await driver.assertComponentExist(ON.id('COMPONENT_ID_SHUTTER_PHOTO_1'));
      if (!shutterComponent) {
        return;
      }
      HiLog.i(TAG, 'click the shutterButton');
      await shutterComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let confirmComponent = await driver.findComponent(ON.id('COMPONENT_ID_THIRDPARTYCALL_CONFIRM_1'));
      await driver.assertComponentExist(ON.id('COMPONENT_ID_THIRDPARTYCALL_CONFIRM_1'));
      if (!confirmComponent) {
        return;
      }
      await confirmComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.end(TAG, 'PickerTest_05');
    });

    /**
     * 1. 后置拍照
     * 2. 拍照
     * 3. 取消选中
     * 4. 进设置页 滑到最底部
     * 5. 找到隐私声明页点击
     * 6. 滑到隐私声明页底部 再返回返回
     * 4. 取消选中
     */
    it('PickerTest_06', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'PickerTest_06');
      HiLog.i(TAG, 'click picker 后置拍照');
      let frontPhotoComponent = await driver.findComponent(ON.id('backCapture'));
      if (!frontPhotoComponent) {
        return;
      }
      HiLog.i(TAG, 'click the backPhotoComponent');
      await frontPhotoComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      if (!AppStorage.get('onPreviewFrameStart')) {
        await driver.assertComponentExist(ON.id('onPreviewFrameStart'));
      }

      let shutterComponent = await driver.findComponent(ON.id('COMPONENT_ID_SHUTTER_PHOTO_1'));
      await driver.assertComponentExist(ON.id('COMPONENT_ID_SHUTTER_PHOTO_1'));
      if (!shutterComponent) {
        return;
      }
      HiLog.i(TAG, 'click the shutterButton');
      await shutterComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);

      HiLog.i(TAG, 'cancel confirm the photo');
      let cancelComponent = await driver.findComponent(ON.id('COMPONENT_ID_THIRDPARTYCALL_BACK_1'));
      await driver.assertComponentExist(ON.id('COMPONENT_ID_THIRDPARTYCALL_BACK_1'));
      if (!cancelComponent) {
        return;
      }
      HiLog.i(TAG, 'click the cancelComponent');
      await cancelComponent.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

      await SettingsPageHandler.SettingViewOpen(driver);
      await TestUtils.slideUpHalfScreen(driver);
      await TestUtils.slideUpHalfScreen(driver);
      await TestUtils.ClickComponentIfExist(driver, 'SETTING_PERMISSION_TEXT', TestConstants.DELAY_ONE_SECOND);
      await TestUtils.slideUpHalfScreen(driver);
      await TestUtils.slideUpHalfScreen(driver);
      await TestUtils.slideUpHalfScreen(driver);
      await TestUtils.slideUpHalfScreen(driver);
      await TestUtils.ClickComponentIfExist(driver, '__NavdestinationField__BackButton__Back__',
        TestConstants.DELAY_ONE_SECOND);
      await TestUtils.ClickComponentIfExist(driver, 'NAV_DESTINATION_TITLE_BACK_1', TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'cancel confirm the photo');
      cancelComponent = await driver.findComponent(ON.id('COMPONENT_ID_THIRDPARTYCALL_BACK_1'));
      await driver.assertComponentExist(ON.id('COMPONENT_ID_THIRDPARTYCALL_BACK_1'));
      if (!cancelComponent) {
        return;
      }
      HiLog.i(TAG, 'click the cancelComponent');
      await cancelComponent.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'PickerTest_06');
    });

    /**
     *  前置录像
     *  1. 开始录像
     *  2. 结束录像
     *  3. 确认返回
     */
    it('PickerTest_07', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'PickerTest_07');

      HiLog.i(TAG, 'click to close 录像5秒');
      if (await driver.findComponent(ON.id('video5_checked'))) {
        await TestUtils.ClickComponentIfExist(driver, 'video5_checked', TestConstants.DELAY_ONE_SECOND);
      }

      HiLog.i(TAG, 'click to close 录像5秒');
      let frontVideoComponent = await driver.findComponent(ON.id('backVideo'));
      if (!frontVideoComponent) {
        return;
      }
      HiLog.i(TAG, 'click the backPhotoComponent');
      await frontVideoComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      if (!AppStorage.get('onPreviewFrameStart')) {
        await driver.assertComponentExist(ON.id('onPreviewFrameStart'));
      }

      HiLog.i(TAG, 'start to record');
      await TestUtils.ClickComponentIfExist(driver, 'COMPONENT_ID_SHUTTER_VIDEO_1', TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id('COMPONENT_ID_SHUTTER_VIDEO_END_1'));
      HiLog.i(TAG, 'start to stop record');
      await TestUtils.ClickComponentIfExist(driver, 'COMPONENT_ID_SHUTTER_VIDEO_END_1',
        TestConstants.DELAY_THREE_SECOND);

      HiLog.i(TAG, 'confirm.');
      let confirmComponent = await driver.findComponent(ON.id('COMPONENT_ID_THIRDPARTYCALL_CONFIRM_1'));
      await driver.assertComponentExist(ON.id('COMPONENT_ID_THIRDPARTYCALL_CONFIRM_1'));
      if (!confirmComponent) {
        return;
      }
      await confirmComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.end(TAG, 'PickerTest_07');
    });

    /**
     * 后置录像 5 秒
     * 1. 打开录像5秒开关
     * 2. 后置录像
     * 3. 5s后 点击确认返回
     */
    it('PickerTest_08', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'PickerTest_08');

      HiLog.i(TAG, 'click to open 录像5秒');
      if (await driver.findComponent(ON.id('video5_noChecked'))) {
        await TestUtils.ClickComponentIfExist(driver, 'video5_noChecked', TestConstants.DELAY_ONE_SECOND);
      }

      HiLog.i(TAG, 'click to close 录像5秒');
      let frontVideoComponent = await driver.findComponent(ON.id('foreVideo'));
      if (!frontVideoComponent) {
        return;
      }
      HiLog.i(TAG, 'click the backPhotoComponent');
      await frontVideoComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      if (!AppStorage.get('onPreviewFrameStart')) {
        await driver.assertComponentExist(ON.id('onPreviewFrameStart'));
      }

      HiLog.i(TAG, 'start to record');
      await TestUtils.ClickComponentIfExist(driver, 'COMPONENT_ID_SHUTTER_VIDEO_1', TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id('COMPONENT_ID_SHUTTER_VIDEO_END_1'));
      await driver.delayMs(TestConstants.DELAY_FIVE_SECOND);
      HiLog.i(TAG, 'confirm.');
      let confirmComponent = await driver.findComponent(ON.id('COMPONENT_ID_THIRDPARTYCALL_CONFIRM_1'));
      await driver.assertComponentExist(ON.id('COMPONENT_ID_THIRDPARTYCALL_CONFIRM_1'));
      if (!confirmComponent) {
        return;
      }
      await confirmComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.end(TAG, 'PickerTest_08');
    });

    /**
     *  模式 切换
     * 1. 打开多模开关
     * 2. 切录像模式 判断起流是否成功
     */
    it('PickerTest_09', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'PickerTest_09');

      HiLog.i(TAG, 'click to open more mode');
      if (await driver.findComponent(ON.id('multiMode_noChecked'))) {
        await TestUtils.ClickComponentIfExist(driver, 'multiMode_noChecked', TestConstants.DELAY_ONE_SECOND);
      }

      HiLog.i(TAG, 'click to 打开 前置拍照');
      let frontPhotoComponent = await driver.findComponent(ON.id('foreCapture'));
      if (!frontPhotoComponent) {
        return;
      }
      HiLog.i(TAG, 'click the backPhotoComponent');
      await frontPhotoComponent.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      if (!AppStorage.get('onPreviewFrameStart')) {
        await driver.assertComponentExist(ON.id('onPreviewFrameStart'));
      }

      HiLog.i(TAG, 'start to change to video mode');
      await TestUtils.ClickComponentIfExist(driver, 'COMPONENT_ID_CONTROL_VIDEO_2', TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id('COMPONENT_ID_CONTROL_VIDEO_2'));
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      if (!AppStorage.get('onPreviewFrameStart')) {
        HiLog.i(TAG, 'change mode to video failed');
        await driver.assertComponentExist(ON.id('onPreviewFrameStart'));
      }
      HiLog.end(TAG, 'PickerTest_09');
    });

    /*
     * 恢复默认值
     */
    it('PickerTest_reset', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'PickerTest_reset');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await SettingsPageHandler.RestoreDefaultValue(driver).then(() => {
        HiLog.i(TAG, 'BasicSlowMo test is restore default value.');
      });
      await driver.triggerKey(KeyCode.KEYCODE_BACK);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'PickerTest_reset');
    });
  })
}