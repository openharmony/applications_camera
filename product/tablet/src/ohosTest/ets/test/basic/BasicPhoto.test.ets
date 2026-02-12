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

import { describe, expect, it, Level } from '@ohos/hypium';
import { Driver, ON, PointerMatrix } from '@ohos.UiTest';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import AbilityDelegatorRegistry from '@ohos.application.abilityDelegatorRegistry';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { BusinessError } from '@ohos.base';
import { TestConstants } from '../../TestConstants';

const TAG: string = 'CameraBasicPhotoTest';

export default function basicPhotoTest() {
  describe('BasicPhotoTest', () => {
    /**
     * 打开应用
     */
    it('BasicPhotoOperationStart', TestConstants.TEST_LEVEL_ZERO, async () => {
      HiLog.i(TAG, 'BasicPhotoOperationStart begin.');
      let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
      try {
        await abilityDelegator.startAbility({
          bundleName: 'com.ohos.camera',
          abilityName: 'com.ohos.camera.MainAbility'
        });
      } catch (expection) {
        let exp = expection as BusinessError;
        expect(0).assertEqual(exp.code);
        HiLog.i(TAG, `StartAbility end ${JSON.stringify(exp)}`);
      }
      HiLog.i(TAG, 'BasicPhotoOperationStart end.');
    });

    /**
     * 点击聚焦
     * 1.分别点击预览页的左上角、右下角、中间位置
     * 2.点击拍照
     */
    it('BasicPhotoOperation_ClickFocus', TestConstants.TEST_LEVEL_ZERO, async () => {
      HiLog.begin(TAG, 'BasicPhotoOperation_ClickFocus');
      const driver = await Driver.create();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'middle area clicked.');
      await driver.click(650, 1050);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click to take a photo');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      let shutterPhoto = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await shutterPhoto.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'BasicPhotoOperation_ClickFocus');
    });

    /**
     * 点击变焦
     * 1.预览 点击焦距
     * 2.点击拍照
     */
    it('BasicPhotoOperation_ClickZoom', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'BasicPhotoOperation_ClickZoom');
      let driver = await Driver.create();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'quickZoom clicked.');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.QUICK_ZOOM_INDEX + 3));
      let quickZoom = await driver.findComponent(ON.id(ComponentIdKeys.QUICK_ZOOM_INDEX + 3));
      await quickZoom.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'click to take a photo.');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      let shutterPhoto = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await shutterPhoto.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'BasicPhotoOperation_ClickZoom');
    });


    /**
     * 使用参考线、水平仪拍照
     * 1.进入拍照模式
     * 2.打开百宝箱
     * 3.进入设置页
     * 4.打开参考线、水平仪
     * 5.设置页返回
     * 6.关闭百宝箱
     * 7.点击聚焦 拍照
     * 8.查看缩略图 滑动返回相机
     */
    it('BasicPhotoOperation_Reference', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'BasicPhotoOperation_Reference begin.');
      let driver = await Driver.create();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'enter photo mode');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO)));
      let photoMode = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('ControlModeText', ModeType.PHOTO)));
      await photoMode.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'treasureBox open');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      let treasureBox = await driver.findComponent(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      await treasureBox.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'enter settingView');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.SETTING)));
      let settingView = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.SETTING)));
      await settingView.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemAssistiveGrid clicked');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemComponentTOGGLE', FunctionId.ASSISTIVE_GRID)));
      let itemAssistiveGrid = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemComponentTOGGLE', FunctionId.ASSISTIVE_GRID)));
      await itemAssistiveGrid.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemHorizontalLevel clicked');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemComponentTOGGLE', FunctionId.HORIZONTAL_LEVEL)));
      let itemHorizontalLevel = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemComponentTOGGLE', FunctionId.HORIZONTAL_LEVEL)));
      await itemHorizontalLevel.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'settingView back');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.NAV_DESTINATION_TITLE_BACK_1));
      let settingViewBack = await driver.findComponent(ON.id(ComponentIdKeys.NAV_DESTINATION_TITLE_BACK_1));
      await settingViewBack.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'treasureBox off');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      let treasureBoxClose = await driver.findComponent(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      await treasureBoxClose.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'middle area clicked');
      await driver.click(650, 1050);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click to take a photo');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      let shutterPhoto = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await shutterPhoto.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'BasicPhotoOperation_Reference end');
    });

    /**
     * 静音拍照
     * 1.进入拍照模式
     * 2.打开百宝箱
     * 3.进入设置页
     * 4.打开拍照静音
     * 5.设置页返回
     * 6.关闭百宝箱
     * 7.点击拍照 查看缩略图 滑动返回相机
     */
    it('BasicPhotoOperation_SoundMute', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'BasicPhotoOperation_SoundMute begin');
      let driver = await Driver.create();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'enter photo mode');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO)));
      let photoMode = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('ControlModeText', ModeType.PHOTO)));
      await photoMode.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'treasureBox open');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      let treasureBox = await driver.findComponent(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      await treasureBox.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'enter settingView');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.SETTING)));
      let settingView = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.SETTING)));
      await settingView.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'soundMute open');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemComponentTOGGLE', FunctionId.SOUND_MUTE)));
      let itemSoundMute = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemComponentTOGGLE', FunctionId.SOUND_MUTE)));
      await itemSoundMute.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'settingView back');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.NAV_DESTINATION_TITLE_BACK_1));
      let settingViewBack = await driver.findComponent(ON.id(ComponentIdKeys.NAV_DESTINATION_TITLE_BACK_1));
      await settingViewBack.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'treasureBox off');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      let treasureBoxClose = await driver.findComponent(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      await treasureBoxClose.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click to take a photo');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      let shutterPhoto = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await shutterPhoto.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      // 相机页面
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'BasicPhotoOperation_SoundMute end');
    });

    /**
     * 恢复默认值
     * 1.点击拍照模式
     * 2.打开百宝箱 点击设置
     * 3.上滑
     * 4.点击记录地理位置信息、悬浮快门键
     * 5.点击恢复默认值 点击确定
     * 6.点击允许 获取信息
     * 7.关闭百宝箱
     */
    it('BasicPhotoOperation_Restore', TestConstants.TEST_LEVEL_ZERO, async () => {
      HiLog.i(TAG, 'BasicPhotoOperation_Restore begin');
      let driver = await Driver.create();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'photoMode');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO)));
      let photoMode = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('ControlModeText', ModeType.PHOTO)));
      await photoMode.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'treasureBox open');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      let treasureBox = await driver.findComponent(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      await treasureBox.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'settingView clicked');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.SETTING)));
      let settingView = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.SETTING)));
      await settingView.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'slide up');
      let pointers01 = PointerMatrix.create(1, 2);
      pointers01.setPoint(0, 0, {
        x: 650, y: TestConstants.DELAY_TWO_SECOND
      });
      pointers01.setPoint(0, 1, {
        x: 650, y: 1300
      });
      await driver.injectMultiPointerAction(pointers01);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemSaveGeoLocation clicked');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemComponentTOGGLE', FunctionId.SAVE_GEO_LOCATION)));
      let itemSaveGeoLocation = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemComponentTOGGLE', FunctionId.SAVE_GEO_LOCATION)));
      await itemSaveGeoLocation.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemFloatingShutter clicked');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemComponentTOGGLE', FunctionId.FLOATING_SHUTTER)));
      let itemFloatingShutter = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemComponentTOGGLE', FunctionId.FLOATING_SHUTTER)));
      await itemFloatingShutter.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'settingDefaultButton clicked');
      HiLog.i(TAG, ComponentIdKeys.SETTING_DEFAULT_BUTTON_1);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SETTING_DEFAULT_BUTTON_1));
      let settingDefault = await driver.findComponent(ON.id(ComponentIdKeys.SETTING_DEFAULT_BUTTON_1));
      await settingDefault.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'confirm');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SETTING_RESTORE_DEFAULT_CONFIRM));
      let settingDefaultConfirm = await driver.findComponent(ON.id(ComponentIdKeys.SETTING_RESTORE_DEFAULT_CONFIRM));
      await settingDefaultConfirm.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'settingDefaultConfirmGeo');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SETTING_RESTORE_DEFAULT_CONFIRM));
      let settingDefaultConfirmGeo = await driver.findComponent(ON.id(ComponentIdKeys.SETTING_RESTORE_DEFAULT_CONFIRM));
      await settingDefaultConfirmGeo.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'treasureBox close');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      let treasureBoxClose = await driver.findComponent(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      await treasureBoxClose.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'BasicPhotoOperation_Restore end');
    });
  });
}