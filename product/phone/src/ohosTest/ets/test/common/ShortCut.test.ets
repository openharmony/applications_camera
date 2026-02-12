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
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'ShortCutTest';

export default function shortCutTest() {
  describe('shortCutTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'shortCutTest test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(65);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'shortCutTest test is finished.');
      });
    });

    /**
     * 拍照模式
     */
    it('shortCutTest_First', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'shortCutTest_First');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      const id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'backHomePage');
      await TestUtils.slideLeftFromScreen(driver);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'shortCutTest_First');
    });

    /**
     * 人像模式快捷启动
     */
    it('shortCutTest_portrait', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'shortCutTest_portrait');
      const modeArr: string[] = ['portrait', 'night', 'video', 'self_portrait'];
      await CommonHandler.abilityStartByShortCut(driver, 'portrait').then(async () => {
        HiLog.i(TAG, 'start by shortCut success mode is portrait');
      });
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

      // 判断模式选中是否正确
      let id = 'COMPONENT_ID_CONTROL_PORTRAIT_2-choose';
      expect(await driver.findComponent(ON.id(id))).not().assertNull();
      // 判断镜头是否正确
      id = 'cameraPosition:1';
      expect(await driver.findComponent(ON.id(id))).not().assertNull();
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await TestUtils.slideLeftFromScreen(driver);
      HiLog.end(TAG, 'shortCutTest_portrait');
    });

    /**
     * 录像模式快捷启动
     */
    it('shortCutTest_video', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'shortCutTest_video');
      await CommonHandler.abilityStartByShortCut(driver, 'video').then(async () => {
        HiLog.i(TAG, 'start by shortCut success mode is video');
      });
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

      // 判断模式选中是否正确
      let id = 'COMPONENT_ID_CONTROL_VIDEO_2-choose';
      expect(await driver.findComponent(ON.id(id))).not().assertNull();
      // 判断镜头是否正确
      id = 'cameraPosition:1';
      expect(await driver.findComponent(ON.id(id))).not().assertNull();
      id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      // 录像3秒钟
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      id = 'COMPONENT_ID_SHUTTER_VIDEO_END_1';
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      await TestUtils.slideLeftFromScreen(driver);
      HiLog.end(TAG, 'shortCutTest_video');
    });

    /**
     * 夜景模式快捷启动
     */
    it('shortCutTest_night', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'shortCutTest_night');
      await CommonHandler.abilityStartByShortCut(driver, 'night').then(async () => {
        HiLog.i(TAG, 'start by shortCut success mode is night');
      });
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

      // 判断模式选中是否正确
      let id = 'COMPONENT_ID_CONTROL_NIGHT_2-choose';
      expect(await driver.findComponent(ON.id(id))).not().assertNull();
      // 判断镜头是否正确
      id = 'cameraPosition:1';
      expect(await driver.findComponent(ON.id(id))).not().assertNull();
      id = ComponentIdKeys.SHUTTER_PHOTO_2;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      // 拍照3秒钟
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      await TestUtils.slideLeftFromScreen(driver);
      HiLog.end(TAG, 'shortCutTest_night');
    });

    /**
     * 人像模式快捷启动
     */
    it('shortCutTest_self_portrait', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'shortCutTest_self_portrait');
      const modeArr: string[] = ['portrait', 'night', 'video', 'self_portrait'];
      await CommonHandler.abilityStartByShortCut(driver, 'self_portrait').then(async () => {
        HiLog.i(TAG, 'start by shortCut success mode is self_portrait');
      });
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

      // 判断模式选中是否正确
      let id = 'COMPONENT_ID_CONTROL_PORTRAIT_2-choose';
      expect(await driver.findComponent(ON.id(id))).not().assertNull();
      // 判断镜头是否正确
      id = 'cameraPosition:2';
      expect(await driver.findComponent(ON.id(id))).not().assertNull();
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      await TestUtils.slideLeftFromScreen(driver);
      HiLog.end(TAG, 'shortCutTest_self_portrait');
    });
  });
}