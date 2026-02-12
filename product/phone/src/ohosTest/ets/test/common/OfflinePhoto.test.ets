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
import { CommonHandler } from '../../aw/CommonHandler';
import { SettingsPageHandler } from '../../aw/SettingsPageHandler';
import { TestUtils } from '../../utils/TestUtils';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'OfflinePhotoTest';

export default function OfflinePhotoTest() {
  describe('OfflinePhotoTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'OfflinePhotoTest test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(21);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'OfflinePhotoTest test is finished.');
      });
    });

    /**
     * 拍照模式
     */
    it('OfflinePhotoTest_PhotoMode', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_PhotoMode');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await CommonHandler.PhotoBack(driver);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OfflinePhotoTest_PhotoMode');
    });

    /**
     * 1.连续拍4张
     */
    it('OfflinePhotoTest_Capture_Exit_001', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_Capture_Exit_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'take a photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_HUNDRED_MILLISECOND);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_HUNDRED_MILLISECOND);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_HUNDRED_MILLISECOND);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_HUNDRED_MILLISECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OfflinePhotoTest_Capture_Exit_001');
    });

    /**
     * 2.侧滑退出
     */
    it('OfflinePhotoTest_Capture_Exit_002', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_Capture_Exit_002');
      HiLog.i(TAG, 'slide left from screen');
      await TestUtils.slideLeftFromScreen(driver);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OfflinePhotoTest_Capture_Exit_002');
    });

    /**
     * 3.重新进相机
     */
    it('OfflinePhotoTest_Capture_Exit_003', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_Capture_Exit_003');
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'ability is start.');
      });
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OfflinePhotoTest_Capture_Exit_003');
    });

    /**
     * 4.预览界面-快门组件存在
     */
    it('OfflinePhotoTest_Capture_Exit_004', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_Capture_Exit_004');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'OfflinePhotoTest_Capture_Exit_004');
    });

    /**
     * 1.连续拍4张
     */
    it('OfflinePhotoTest_Capture_Thumbnail_001', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_Capture_Thumbnail_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'take a photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_HUNDRED_MILLISECOND);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_HUNDRED_MILLISECOND);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_HUNDRED_MILLISECOND);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_HUNDRED_MILLISECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OfflinePhotoTest_Capture_Thumbnail_001');
    });

    /**
     * 2.进缩略图
     */
    it('OfflinePhotoTest_Capture_Thumbnail_002', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_Capture_Thumbnail_002');
      HiLog.i(TAG, 'click on the thumbnail');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OfflinePhotoTest_Capture_Thumbnail_002');
    });

    /**
     * 3.从缩略图返回
     */
    it('OfflinePhotoTest_Capture_Thumbnail_003', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_Capture_Thumbnail_003');
      HiLog.i(TAG, 'slide back');
      await TestUtils.slideLeftFromScreen(driver);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OfflinePhotoTest_Capture_Thumbnail_003');
    });

    /**
     * 4.预览界面-快门组件存在
     */
    it('OfflinePhotoTest_Capture_Thumbnail_004', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_Capture_Thumbnail_004');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'OfflinePhotoTest_Capture_Thumbnail_004');
    });

    /**
     * 1.连续拍4张
     */
    it('OfflinePhotoTest_Capture_Switch_001', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_Capture_Switch_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'take five photos');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_HUNDRED_MILLISECOND);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_HUNDRED_MILLISECOND);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_HUNDRED_MILLISECOND);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_HUNDRED_MILLISECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OfflinePhotoTest_Capture_Switch_001');
    });

    /**
     * 2.切前置
     */
    it('OfflinePhotoTest_Capture_Switch_002', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_Capture_Switch_002');
      HiLog.i(TAG, 'switch camera.');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OfflinePhotoTest_Capture_Switch_002');
    });

    /**
     * 3.预览界面-快门
     */
    it('OfflinePhotoTest_Capture_Switch_003', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_Capture_Switch_003');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'OfflinePhotoTest_Capture_Switch_003');
    });

    /**
     * 4.切后置
     */
    it('OfflinePhotoTest_Capture_Switch_004', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_Capture_Switch_004');
      HiLog.i(TAG, 'switch camera.');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OfflinePhotoTest_Capture_Switch_004');
    });
    /**
     * 恢复默认值
     */
    it('OfflinePhotoTest_Restore', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'OfflinePhotoTest_Restore');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await SettingsPageHandler.RestoreDefaultValue(driver).then(() => {
        HiLog.i(TAG, 'OfflinePhoto test is restore default value.');
      });
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'OfflinePhotoTest_Restore');
    });

  });
}