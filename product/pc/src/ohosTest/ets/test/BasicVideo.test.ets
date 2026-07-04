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
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog'
import AbilityDelegatorRegistry from '@ohos.application.abilityDelegatorRegistry';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { BusinessError } from '@ohos.base';
import { TestConstants } from './TestConstants';

const TAG: string = 'CameraBasicVideoTest';

export default function basicVideoTest() {
  describe('BasicVideoTest', () => {
    /**
     * 打开应用
     */
    it('BasicVideoOperationStart', TestConstants.TEST_LEVEL_ZERO, async () => {
      HiLog.begin(TAG, 'BasicVideoOperationStart');
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
      HiLog.end(TAG, 'BasicVideoOperationStart');
    });

    /**
     * 点击百宝箱
     * 1.点击录像模式
     * 2.打开百宝箱
     * 3.点击分辨率 720p 4k [full]1080p 1080p
     * 4.返回百宝箱一级页
     * 5.点击帧率 60 30
     * 6.返回百宝箱一级页面
     * 7.关闭百宝箱
     */
    it('BasicVideoOperation_TreasureBoxFunction', TestConstants.TEST_LEVEL_ZERO, async () => {
      HiLog.begin(TAG, 'BasicVideoOperation_TreasureBoxFunction');
      let driver = await Driver.create();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'videoMode');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO)));
      let videoMode = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('ControlModeText', ModeType.VIDEO)));
      await videoMode.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'treasureBox open');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      let treasureBox = await driver.findComponent(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      await treasureBox.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION)));
      let itemVideoResolution = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION)));
      await itemVideoResolution.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution 720p');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '4')));
      let itemVideoResolution720 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '4')));
      await itemVideoResolution720.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution 4k');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '1')));
      let itemVideoResolution4k = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '1')));
      await itemVideoResolution4k.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution 1080 full');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '2')));
      let itemVideoResolution1080_Full = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '2')));
      await itemVideoResolution1080_Full.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution 1080p');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '3')));
      let itemVideoResolution1080 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.VIDEO_RESOLUTION, '3')));
      await itemVideoResolution1080.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'treasureBox back');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.TREASURE_BOX_SECOND_LIST_BACK_BUTTON));
      let treasureBoxBack = await driver.findComponent(ON.id(ComponentIdKeys.TREASURE_BOX_SECOND_LIST_BACK_BUTTON));
      await treasureBoxBack.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemFrameRate clicked');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.FRAME_RATE)));
      let itemFrameRate = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.FRAME_RATE)));
      await itemFrameRate.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemFrameRate 60');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.FRAME_RATE, '2')));
      let itemFrameRate60 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.FRAME_RATE, '2')));
      await itemFrameRate60.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemFrameRate 30');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.FRAME_RATE, '1')));
      let itemFrameRate30 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.FRAME_RATE, '1')));
      await itemFrameRate30.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'treasureBox back, second.');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.TREASURE_BOX_SECOND_LIST_BACK_BUTTON));
      treasureBoxBack = await driver.findComponent(ON.id(ComponentIdKeys.TREASURE_BOX_SECOND_LIST_BACK_BUTTON));
      await treasureBoxBack.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'treasureBox close');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      let treasureBoxClose = await driver.findComponent(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      await treasureBoxClose.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'BasicVideoOperation_TreasureBoxFunction');
    })

  });
}

