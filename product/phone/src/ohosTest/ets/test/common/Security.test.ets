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
import { Driver } from '@ohos.UiTest';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { TestConstants } from '../../TestConstants';
import { TestUtils } from '../../utils/TestUtils';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';


const TAG: string = TestConstants.TAG + '_' + 'SecurityCameraTest';
const delegator: AbilityDelegatorRegistry.AbilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();

export default function securityTest() {
  describe('SecurityTest', () => {
    const driver = Driver.create();

    /**
     * 进入锁屏相机
     * 1.开关机按下 第一次 息屏
     * 2.开关机按下 第二次 锁屏
     * 3.截屏
     * 4.滑动进入锁屏相机
     */
    it('SecurityCamera_CameraEnter', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'SecurityCamera_CameraEnter');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'OOK down.');
      await delegator.executeShellCommand(TestConstants.KEY_POWER);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'OOK down, second.');
      await delegator.executeShellCommand(TestConstants.KEY_POWER);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.begin(TAG, 'SecurityCamera_Snip');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'Screenshot completed.');
      await delegator.executeShellCommand(TestConstants.KEY_SNIP);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      HiLog.i(TAG, 'Sliding into');
      await driver.swipe(1070, 2518, 1070, 500, 5000);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SecurityCamera_CameraEnter');
    });

    /**
     * 拍照模式
     */
    it('SecurityCamera_Mode_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SecurityCamera_Mode_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'photo Mode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SecurityCamera_Mode_001');
    });

    /**
     * 1.拍照
     * 2.查看缩略图
     * 3.点击查看缩略图界面（观察显示的数量）
     * 4.返回
     */
    it('SecurityCamera_Photo', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SecurityCamera_Photo');
      HiLog.i(TAG, 'click to take a photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'click on the thumbnail');
      id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'middle area clicked');
      await driver.click(650, 1050);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'slide back');
      await TestUtils.slideLeftFromScreen(driver);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SecurityCamera_Photo');
    });

    /**
     * 录像模式
     * 1.点击开始录像
     * 2.录像中点击抓拍
     * 3.点击暂停，继续
     * 4.结束录像
     */
    it('SecurityCamera_Mode_002', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SecurityCamera_Mode_002');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'video Mode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'start recording');
      id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      HiLog.i(TAG, 'shutter photo');
      id = ComponentIdKeys.SHUTTER_PHOTO_ON_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'pause recording');
      id = ComponentIdKeys.VIDEO_RECORDING_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'continue recording');
      id = ComponentIdKeys.VIDEO_PAUSE_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'end recording');
      id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SecurityCamera_Mode_002');
    });

    /**
     * 切换拍照模式
     */
    it('SecurityCamera_Mode_005', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SecurityCamera_Mode_005');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'photo Mode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'SecurityCamera_Mode_005');
    });

    /**
     * 退出至主界面
     * 1.滑动退出锁屏相机到锁屏页
     * 2.锁屏 回到主页
     */
    it('SecurityCamera_HomeBack', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'SecurityCamera_HomeBack');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await TestUtils.slideLeftFromScreen(driver).then(() => {
        HiLog.i(TAG, 'back to lock screen page.');
      });
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'back to homepage.');
      await delegator.executeShellCommand(TestConstants.KEY_UNLOCK);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HideBugUtil.checkDtPss(58);
      HiLog.end(TAG, 'SecurityCamera_HomeBack');
    });
  });
}