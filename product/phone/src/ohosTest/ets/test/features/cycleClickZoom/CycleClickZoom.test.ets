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
import { TestConstants } from '../../../TestConstants';
import { CommonHandler } from '../../../aw/CommonHandler';

const TAG: string = TestConstants.TAG + '_' + 'CycleClickZoomTest';
const isSupportCycleClick: boolean = false;
export default function CycleClickZoomTest() {
  describe('CycleClickZoomTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'CycleClickZoom test is start.');
      })
    });

    afterAll(async () => {
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'CycleClickZoom test is finished.');
      });
    });

    /**
     * 后置拍照模式
     */
    it('CycleClickZoom_first', Level.LEVEL0, async () => {
      if (!isSupportCycleClick) {
        return;
      }
      HiLog.begin(TAG, 'CycleClickZoom_first');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await CommonHandler.PhotoBack(driver).then(() => {
        HiLog.i(TAG, 'position and mode is init.');
      });
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'CycleClickZoom_first');
    });

    /**
     * 1、遍历四个快捷变焦点
     * 2、循环点切第一个焦距
     * 3、循环点切第二个焦距
     * 3、循环点切最后一个焦距
     */
    it('CycleClickZoom_CycleClick', Level.LEVEL0, async () => {
      if (!isSupportCycleClick) {
        return;
      }
      HiLog.begin(TAG, 'CycleClickZoom_CycleClick');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      for (let i = 0; i <= 4; i++) {
        let key = `QUICK_ZOOM_INDEX_${i}`;
        let component = await driver.findComponent(ON.id(key));
        HiLog.i(TAG, `find the zoom ${key}.`);
        await component.click();
        HiLog.i(TAG, `click the zoom ${key}.`);
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      }

      let key = 'QUICK_ZOOM_INDEX_1';
      let component = await driver.findComponent(ON.id(key));
      if (component) {
        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      }
      key = 'QUICK_ZOOM_INDEX_1-choose';
      component = await driver.findComponent(ON.id(key));
      if (component) {
        // 对1x进行循环点切操作
        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      }

      key = 'QUICK_ZOOM_INDEX_3';
      component = await driver.findComponent(ON.id(key));
      if (component) {
        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      }
      key = 'QUICK_ZOOM_INDEX_3-choose';
      component = await driver.findComponent(ON.id(key));
      if (component) {
        // 对4x进行循环点切操作
        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      }

      key = 'QUICK_ZOOM_INDEX_4';
      component = await driver.findComponent(ON.id(key));
      if (component) {
        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      }
      key = 'QUICK_ZOOM_INDEX_4-choose';
      component = await driver.findComponent(ON.id(key));
      if (component) {
        // 对10x进行循环点切操作
        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      }
      key = 'QUICK_ZOOM_INDEX_1';
      component = await driver.findComponent(ON.id(key));
      await component.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      expect(key).not().assertNull();
      HiLog.end(TAG, 'CycleClickZoom_CycleClick');
    });

    /**
     * 焦距复位
     * 1、复位第三个焦距
     * 2、复位第四个焦距
     */
    it('CycleClickZoom_ZoomReset', Level.LEVEL1, async () => {
      if (!isSupportCycleClick) {
        return;
      }
      HiLog.begin(TAG, 'CycleClickZoom_ZoomReset');
      await driver.swipe(960, 1860, 800, 1860,1200);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let key = 'QUICK_ZOOM_INDEX_3-choose';
      let component = await driver.findComponent(ON.id(key));
      if (component) {
        // 对10x进行循环点切操作
        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      }
      await driver.swipe(960, 1860,360, 1860,1500);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      key = 'QUICK_ZOOM_INDEX_4-choose';
      component = await driver.findComponent(ON.id(key));
      if (component) {
        // 对10x进行循环点切操作
        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      }
      expect(key).not().assertNull();
    })

    /*
     * Zoom 恢复默认值
     */
    it('CycleClickZoom_Restore', Level.LEVEL1, async () => {
      if (!isSupportCycleClick) {
        return;
      }
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let key = 'QUICK_ZOOM_INDEX_1';
      let component = await driver.findComponent(ON.id(key));
      await component.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      expect(key).not().assertNull();
      HiLog.end(TAG, 'CycleClickZoom_Restore');
    });
  });
}
