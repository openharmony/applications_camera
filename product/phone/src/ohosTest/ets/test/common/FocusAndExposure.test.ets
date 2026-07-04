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
import { TestConstants } from '../../TestConstants';
import { TestUtils } from '../../utils/TestUtils';
import { CommonHandler } from '../../aw/CommonHandler';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'FocusAndExposureTest';

export default function focusAndExposureTest() {
  describe('FocusAndExposureTest', () => {
    const driver = Driver.create();
    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'FocusAndExposure test is start');
      });
    });
    afterAll(async () => {
      HideBugUtil.checkDtPss(39);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'FocusAndExposure test is finished.');
      });
    });
    /**
     * 基础拍照
     * 1.拍照模式
     * 2.点击预览界面
     * 3.修改EV值
     * 4.点击拍照
     */

    it('FocusAndExposure_TakePhoto', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'FocusAndExposure_TakePhoto');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'photoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click to PreviewArea');
      await driver.click(340, 512);
      HiLog.i(TAG, 'swipe change exposure value');
      await driver.swipe(541, 507, 541, 650, 800);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click to take photos');
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'FocusAndExposure_TakePhoto');
    });

    /**
     * 基础拍照(添加测光分离)
     * 1.拍照模式
     * 2.长按预览界面
     * 3.拖动测光圈
     * 4.拖动对焦框
     * 5.点击拍照
     */

    it('FocusAndExposure_TakePhoto_01', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'FocusAndExposure_TakePhoto_01');
      HiLog.i(TAG, 'photoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'longClick to PreviewArea');
      await driver.longClick(142, 587);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'swipe exposureRing');
      await driver.swipe(142, 587, 717, 596, 800);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'swipe focus');
      await driver.swipe(142, 587, 142, 931, 800);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click to take photos');
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'FocusAndExposure_TakePhoto_01');
    });


    /**
     * 基础录像
     * 1.点击录像模式
     * 2.点击预览界面
     * 3.修改EV值
     * 4.点击开始录像
     * 5.点击结束录像
     */
    it('FocusAndExposure_VideoRecord_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'FocusAndExposure_VideoRecord_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'videoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click to PreviewArea');
      await driver.click(340, 512);
      HiLog.i(TAG, 'swipe change exposure value');
      await driver.swipe(541, 507, 541, 750, 850);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'start recording');
      id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'end recording');
      id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      expect(id).not().assertNull();
      HiLog.end(TAG, 'FocusAndExposure_VideoRecord_001');
    });

    it('FocusAndExposure_reset', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'FocusAndExposure_reset');
      await CommonHandler.PhotoBack(driver);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'FocusAndExposure_reset');
    });
  })
}
