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
import { SettingsPageHandler } from '../../aw/SettingsPageHandler';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'ZoomTest';

export default function zoomTest() {
  describe('ZoomTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'Zoom test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(4);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'Zoom test is finished.');
      });
    });

    /**
     * 后置拍照模式
     */
    it('Zoom_First', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Zoom_First');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await CommonHandler.PhotoBack(driver).then(() => {
        HiLog.i(TAG, 'position and mode is init.');
      });
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'Zoom_First');
    });
    it('Zoom_First_1', Level.LEVEL0, async () => {
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'Zoom_First');
    });

    /**
     * 点击聚焦拍照
     * 1.分别点击预览页的左上角、右下角、中间位置
     * 2.点击拍照
     */
    it('Zoom_ClickFocus', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'Zoom_ClickFocus');
      HiLog.i(TAG, 'middle area clicked');
      await driver.click(650, 1050);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    });
    it('Zoom_ClickFocus_1', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'click to take a photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Zoom_ClickFocus');
    });

    /**
     * 点击变焦拍照
     * 1.预览
     * 2.循环执行 点击四个快捷变焦圆 并逐个进行变焦后拍照
     */
    it('Zoom_ClickZoom_0', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_ClickZoom');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let key = `QUICK_ZOOM_INDEX_${0}`;
      let component = await driver.findComponent(ON.id(key));
      HiLog.i(TAG, `find the zoom ${key}.`);
      if (component) {
        HiLog.i(TAG, `click the zoom ${key}.`);
        await component.click();
        await driver.delayMs(TestConstants.DELAY_MIN_TIME);
        HiLog.i(TAG, 'click to take a photo');
        let id = ComponentIdKeys.SHUTTER_PHOTO_1;
        await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
        expect(id).not().assertNull();
      }
      HiLog.end(TAG, 'Zoom_ClickZoom');
    });
    it('Zoom_ClickZoom_1', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_ClickZoom');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let key = `QUICK_ZOOM_INDEX_${1}`;
      let component = await driver.findComponent(ON.id(key));
      HiLog.i(TAG, `find the zoom ${key}.`);
      if (component) {
        HiLog.i(TAG, `click the zoom ${key}.`);
        await component.click();
        await driver.delayMs(TestConstants.DELAY_MIN_TIME);
        HiLog.i(TAG, 'click to take a photo');
        let id = ComponentIdKeys.SHUTTER_PHOTO_1;
        await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
        expect(id).not().assertNull();
      }
      HiLog.end(TAG, 'Zoom_ClickZoom');
    });
    it('Zoom_ClickZoom_2', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_ClickZoom');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let key = `QUICK_ZOOM_INDEX_${2}`;
      let component = await driver.findComponent(ON.id(key));
      HiLog.i(TAG, `find the zoom ${key}.`);
      if (component) {
        HiLog.i(TAG, `click the zoom ${key}.`);
        await component.click();
        await driver.delayMs(TestConstants.DELAY_MIN_TIME);
        HiLog.i(TAG, 'click to take a photo');
        let id = ComponentIdKeys.SHUTTER_PHOTO_1;
        await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
        expect(id).not().assertNull();
      }
      HiLog.end(TAG, 'Zoom_ClickZoom');
    });
    it('Zoom_ClickZoom_3', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_ClickZoom');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let key = `QUICK_ZOOM_INDEX_${3}`;
      let component = await driver.findComponent(ON.id(key));
      HiLog.i(TAG, `find the zoom ${key}.`);
      if (component) {
        HiLog.i(TAG, `click the zoom ${key}.`);
        await component.click();
        await driver.delayMs(TestConstants.DELAY_MIN_TIME);
        HiLog.i(TAG, 'click to take a photo');
        let id = ComponentIdKeys.SHUTTER_PHOTO_1;
        await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
        expect(id).not().assertNull();
      }
      HiLog.end(TAG, 'Zoom_ClickZoom');
    });

    /**
     * 变焦画中画
     * 1.进入相机拍照模式
     * 2.双指滑动预览流，将焦距调至 15x 以上,显示画中画
     * 3.点击拍照
     * 4.点击画中画 x 按钮，缩小画中画
     * 5.在点击画中画缩小按钮，放大画中画
     * 6.点击1X 返回预览
     */
    it('Zoom_PipOperation_1', Level.LEVEL2, async () => {
      HiLog.begin(TAG, 'Zoom_PipOperation');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'photoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });
    it('Zoom_PipOperation_2', Level.LEVEL2, async () => {
      HiLog.i(TAG, 'PointerMatrix clicked');
      // 双指捏合放大
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });
    it('Zoom_PipOperation_3', Level.LEVEL2, async () => {
      HiLog.i(TAG, 'click to take a photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });
    it('Zoom_PipOperation_4', Level.LEVEL2, async () => {
      HiLog.i(TAG, 'pipClickClose clicked');
      let id = ComponentIdKeys.PIP_CLICK_CLOSE;
      if (await driver.findComponent(ON.id(id))) {
        await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
        expect(id).not().assertNull();
        HiLog.i(TAG, 'pipClickBig clicked');
      }
    });
    it('Zoom_PipOperation_5', Level.LEVEL2, async () => {
      let id = ComponentIdKeys.PIP_CLICK_BIG;
      if (await driver.findComponent(ON.id(id))) {
        await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
        expect(id).not().assertNull();
        HiLog.i(TAG, 'quickZoom clicked');
      }
    });
    it('Zoom_PipOperation_6', Level.LEVEL2, async () => {
      let key = 'QUICK_ZOOM_INDEX_1';
      let component = await driver.findComponent(ON.id(key));
      if (component) {
        HiLog.i(TAG, `click the zoom ${key}.`);
        await component.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      }
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Zoom_PipOperation');
    });

    /**
     * 变焦拍照 捏合放大
     * 1.双指捏合放大
     * 2.点击聚焦
     * 3.点击拍照
     */
    it('Zoom_001', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_001');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'pinch out 2');
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    })
    it('Zoom_002', Level.LEVEL1, async () => {
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      HiLog.i(TAG, 'middle area clicked');
      await driver.click(650, 1050);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    })

    it('Zoom_003', Level.LEVEL1, async () => {
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click to take a photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_MIN_TIME);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Zoom_003');
    })

    /**
     * 变焦拍照 捏合缩小
     * 1.双指捏合缩小至2x
     * 2.点击聚焦
     * 3.点击拍照
     */
    it('Zoom_004', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_004');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'pinch in 2x');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.PREVIEW_WINDOW_1));
    })
    it('Zoom_005', Level.LEVEL1, async () => {
      let quickZoom = await driver.findComponent(ON.id(ComponentIdKeys.PREVIEW_WINDOW_1));
      await quickZoom.pinchIn(1);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    })

    it('Zoom_006', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'middle area clicked');
      await driver.click(650, 1050);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    })

    it('Zoom_007', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to take a photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_MIN_TIME);
      expect(id).not().assertNull();
    })
    /**
     * 变焦拍照 10x
     * 1.点击10x
     * 2.点击拍照
     */
    it('Zoom_008', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_008');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'quickZoom clicked');
      let id = 'QUICK_ZOOM_INDEX_3';
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_MIN_TIME);
      expect(id).not().assertNull();
    })
    it('Zoom_009', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to take a photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_MIN_TIME);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Zoom_005');
    })

    /**
     * 快速滑动变焦
     * 1.长按 快速缩放索引
     * 2.左右滑动
     * 3.点击拍照
     */
    it('Zoom_010', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_010');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'swipe left or right');
      await driver.swipe(565, 1785, 700, 1785, 800);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    })
    it('Zoom_011', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_011');
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      await driver.swipe(825, 1785, 560, 1785, 800);
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
    })
    it('Zoom_012', Level.LEVEL1, async () => {
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      HiLog.i(TAG, 'click to take a photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Zoom_012');
    })
    it('Zoom_013', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_007');
      HiLog.i(TAG, 'videoMode');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_014', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_014');
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_015', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to start recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_016', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to stop recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_FIVE_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_017', Level.LEVEL1, async () => {
      //双指缩放
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_018', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to start recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_019', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to stop recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_FIVE_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_020', Level.LEVEL1, async () => {
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_021', Level.LEVEL1, async () => {
      await TestUtils.slideDownHalfScreenQuick(driver);
      HiLog.end(TAG, 'Zoom_021');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      expect(id).not().assertNull();
    });

    it('Zoom_022', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_022');
      HiLog.i(TAG, 'click to start recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_023', Level.LEVEL1, async () => {
      //双指缩放
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_024', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to stop recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_FIVE_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_025', Level.LEVEL1, async () => {
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'quickZoom clicked');
      let id = 'QUICK_ZOOM_INDEX_2';
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_MIN_TIME);
      expect(id).not().assertNull();
    });

    it('Zoom_026', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to start recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_027', Level.LEVEL1, async () => {
      //双指缩放
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_028', Level.LEVEL1, async () => {
      //双指缩放
      HiLog.i(TAG, 'click to stop recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_FIVE_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_029', Level.LEVEL1, async () => {
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_030', Level.LEVEL1, async () => {
      await TestUtils.slideDownHalfScreenQuick(driver);
      let id = ComponentIdKeys.THUMBNAIL_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Zoom_030');
    });

    it('Zoom_031', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_031');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'quickZoom clicked');
      let id = 'QUICK_ZOOM_INDEX_2';
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_MIN_TIME);
      expect(id).not().assertNull();
    });

    it('Zoom_032', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to start recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_033', Level.LEVEL1, async () => {
      //双指缩放
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_034', Level.LEVEL1, async () => {
      //双指缩放
      HiLog.i(TAG, 'click to stop recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_FIVE_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_035', Level.LEVEL1, async () => {
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    });

    it('Zoom_036', Level.LEVEL1, async () => {
      await TestUtils.slideDownHalfScreenQuick(driver);
      let id = ComponentIdKeys.THUMBNAIL_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Zoom_036');
    })

    it('Zoom_037', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_037');
      HiLog.i(TAG, 'switch camera.');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    })

    it('Zoom_038', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_038');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'quickZoom clicked');
      let id = 'QUICK_ZOOM_INDEX_2';
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_MIN_TIME);
      expect(id).not().assertNull();
    })

    it('Zoom_039', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_039');
      HiLog.i(TAG, 'click to start recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    })

    it('Zoom_040', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_040');
      //双指缩放
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_TWO_SECOND);
      await driver.delayMs(TestConstants.DELAY_THREE_SECOND);
      expect(id).not().assertNull();
    })

    it('Zoom_041', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'click to stop recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_FIVE_SECOND);
      expect(id).not().assertNull();
    })

    it('Zoom_042', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_042');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    })

    it('Zoom_043', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_043');
      await TestUtils.slideDownHalfScreenQuick(driver);
      let id = ComponentIdKeys.THUMBNAIL_1;
      expect(id).not().assertNull();
    })

    it('Zoom_044', Level.LEVEL1, async () => {
      HiLog.i(TAG, 'switch camera.');
      let id = ComponentIdKeys.SWITCH_CAMERA_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Zoom_044');
    })

    it('Zoom_045', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_045');
      HiLog.i(TAG, 'click to start recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    })

    it('Zoom_046', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_046');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'quickZoom clicked');
      let id = 'QUICK_ZOOM_INDEX_2';
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_MIN_TIME);
      expect(id).not().assertNull();
    })

    it('Zoom_047', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_047');
      HiLog.i(TAG, 'click to stop recording.');
      let id = ComponentIdKeys.SHUTTER_VIDEO_END_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_FIVE_SECOND);
      expect(id).not().assertNull();
    })

    it('Zoom_048', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_048');
      let id = ComponentIdKeys.THUMBNAIL_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    })

    it('Zoom_049', Level.LEVEL1, async () => {
      await TestUtils.slideDownHalfScreenQuick(driver);
      let id = ComponentIdKeys.THUMBNAIL_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Zoom_049');
    })

    it('Zoom_050', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'Zoom_Restore');
      let id = ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      expect(id).not().assertNull();
    })
    /*
     * Zoom 恢复默认值
     */
    it('Zoom_Restore', Level.LEVEL1, async () => {
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await SettingsPageHandler.RestoreDefaultValue(driver).then(() => {
        HiLog.i(TAG, 'Zoom test is restore default value.');
      });
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'Zoom_Restore');
    });

  });
}
