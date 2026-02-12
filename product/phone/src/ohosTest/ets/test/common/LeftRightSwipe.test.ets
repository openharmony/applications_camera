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
import { Component, Driver, ON, Point } from '@ohos.UiTest';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { FlashMode } from '@ohos/common/src/main/ets/function/enumbase/FlashMode';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { TestConstants } from '../../TestConstants';
import { TestUtils } from '../../utils/TestUtils';
import { CommonHandler } from '../../aw/CommonHandler';
import { SettingsPageHandler } from '../../aw/SettingsPageHandler';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'LeftRightSwipeTest';

const DRAG_DISTANCE_RATIO: number = 1.1;
const DRAG_DISTANCE_RATIO_HALF: number = 0.5;
const SLOW_DRAG_SPEED: number = 200;
const FAST_DRAG_SPEED: number = 1000;
const FLASH_ID: string = ComponentIdKeys.getInstance().getKey('TabBar', FunctionId.FLASH);

export default function leftRightSwipeTest() {
  describe('LeftRightSwipeTest', () => {
    const driver = Driver.create();

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(() => {
        HiLog.i(TAG, 'LeftRightSwipeTest test is start.');
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(20);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'LeftRightSwipeTest test is finished.');
      });
    });

    /**
     * 进入拍照模式
     */
    it('LeftRightSwipeTest_First', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_First');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'enter photo mode');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO)));
      let photoMode = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('ControlModeText', ModeType.PHOTO)));
      await photoMode.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'LeftRightSwipeTest_First');
    });

    /**
     * 进入长按连拍后退出
     * 1.长按快门
     * 2.松手后查看缩略图， 前后置切换是否存在
     * 3.返回
     */
    it('LeftRightSwipeTest_LongPress_Release_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_Release');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'take one photo');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      let shutterButtonPoint: Point = await getComponentCenterPoint(id, driver);
      let shutterX: number = shutterButtonPoint.x;
      let shutterY: number = shutterButtonPoint.y;
      // 长按快门
      HiLog.i(TAG, 'longClick Shutter');
      await driver.longClick(shutterX, shutterY);
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      // 注意，无法在长按过程中检测component存在
      // 松手, 检测缩略图和前后置切换的出现
      HiLog.i(TAG, 'stop long click');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.THUMBNAIL_1));
      HiLog.i(TAG, 'assert thumbnail exist');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SWITCH_CAMERA_1));
      HiLog.i(TAG, 'assert switch camera exist');
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_Release');
    });

    it('LeftRightSwipeTest_LongPress_Release_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_Release');
      let id = ComponentIdKeys.THUMBNAIL_1;
      HiLog.i(TAG, 'click on the thumbnail');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'slide back');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_Release');
    });


    /**
     * 长按连拍
     * 1.长按快门
     * 2.进入连拍
     * 3.松手后查看缩略图
     * 4.返回
     */
    it('LeftRightSwipeTest_LongPress_Burst_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_Burst');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      let shutterButtonPoint: Point = await getComponentCenterPoint(id, driver);
      let shutterX: number = shutterButtonPoint.x;
      let shutterY: number = shutterButtonPoint.y;
      HiLog.i(TAG, 'find shutterButton coordinate');

      id = ComponentIdKeys.THUMBNAIL_1;
      let thumbnailPoint: Point = await getComponentCenterPoint(id, driver);
      let thumbX: number = thumbnailPoint.x;
      let thumbY: number = thumbnailPoint.y;

      let pointXOverThumb: number = Math.floor((thumbX - shutterX) * DRAG_DISTANCE_RATIO + shutterX);
      let pointYOverThumb: number = Math.floor((thumbY - shutterY) * DRAG_DISTANCE_RATIO + shutterY);

      // 长按快门并拖动
      await driver.drag(shutterX, shutterY, pointXOverThumb, pointYOverThumb, SLOW_DRAG_SPEED);
      expect(id).not().assertNull();
      HiLog.i(TAG, 'stop long click');
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_Burst');
    });

    it('LeftRightSwipeTest_LongPress_Burst_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_Burst');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.THUMBNAIL_1));
      HiLog.i(TAG, 'assert thumbnail exist');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SWITCH_CAMERA_1));
      HiLog.i(TAG, 'assert switch camera exist');
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_Burst');
    });

    /**
     * 长按连拍
     * 1.打开百宝箱
     * 2.长按快门
     * 3.进入连拍
     * 4.松手后查看缩略图
     * 5.返回
     */
    it('LeftRightSwipeTest_LongPress_Burst_Treasure_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_Burst_Treasure');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      HiLog.i(TAG, 'click on TreasureBoxPanel');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);

      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      let shutterButtonPoint: Point = await getComponentCenterPoint(id, driver);
      let shutterX: number = shutterButtonPoint.x;
      let shutterY: number = shutterButtonPoint.y;
      HiLog.i(TAG, 'find shutterButton coordinate');

      id = ComponentIdKeys.THUMBNAIL_1;
      let thumbnailPoint: Point = await getComponentCenterPoint(id, driver);
      let thumbX: number = thumbnailPoint.x;
      let thumbY: number = thumbnailPoint.y;

      let pointXOverThumb: number = Math.floor((thumbX - shutterX) * DRAG_DISTANCE_RATIO + shutterX);
      let pointYOverThumb: number = Math.floor((thumbY - shutterY) * DRAG_DISTANCE_RATIO + shutterY);

      // 长按快门并拖动
      await driver.drag(shutterX, shutterY, pointXOverThumb, pointYOverThumb, FAST_DRAG_SPEED);
      expect(id).not().assertNull();
      HiLog.i(TAG, 'stop long click');
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_Burst_Treasure');
    });

    it('LeftRightSwipeTest_LongPress_Burst_Treasure_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_Burst_Treasure');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.THUMBNAIL_1));
      HiLog.i(TAG, 'assert thumbnail exist');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SWITCH_CAMERA_1));
      HiLog.i(TAG, 'assert switch camera exist');

      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_Burst_Treasure');
    });

    /**
     * 长按录像
     * 1.长按快门
     * 2.进入录像
     * 3.按停止录像
     * 4.查看缩略图
     * 5.返回
     */
    it('LeftRightSwipeTest_LongPress_PressRecord_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      let shutterButtonPoint: Point = await getComponentCenterPoint(id, driver);
      let shutterX: number = shutterButtonPoint.x;
      let shutterY: number = shutterButtonPoint.y;
      HiLog.i(TAG, 'find shutterButton coordinate');

      id = ComponentIdKeys.SWITCH_CAMERA_1;
      let switchCamPoint: Point = await getComponentCenterPoint(id, driver);
      let thumbX: number = switchCamPoint.x;
      let thumbY: number = switchCamPoint.y;

      let pointXOverSwitchCam: number = Math.floor((thumbX - shutterX) * DRAG_DISTANCE_RATIO_HALF + shutterX);
      let pointYOverSwitchCam: number = Math.floor((thumbY - shutterY) * DRAG_DISTANCE_RATIO_HALF + shutterY);

      // 长按快门并拖动
      await driver.drag(shutterX, shutterY, pointXOverSwitchCam, pointYOverSwitchCam);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord');
    });

    it('LeftRightSwipeTest_LongPress_PressRecord_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord');
      HiLog.i(TAG, 'start video record');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_2));
      HiLog.i(TAG, 'assert stop video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_RECORDING_2));
      HiLog.i(TAG, 'assert pause video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.LEFT_RIGHT_SWIPE_RECORD_CAPTURE));
      HiLog.i(TAG, 'assert video capture button exist');


      await TestUtils.ClickComponentIfExist(driver, ComponentIdKeys.SHUTTER_VIDEO_END_2,
        TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord');
    });

    it('LeftRightSwipeTest_LongPress_PressRecord_03', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord');

      let id = ComponentIdKeys.THUMBNAIL_1;
      HiLog.i(TAG, 'click on the thumbnail');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'slide back');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord');
    });

    /**
     * 长按录像
     * 1.打开百宝箱
     * 2.长按快门
     * 3.进入录像
     * 4.按停止录像
     * 5.查看缩略图
     * 6.返回
     */
    it('LeftRightSwipeTest_LongPress_PressRecord_Treasure_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Treasure_01');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      HiLog.i(TAG, 'click on TreasureBoxPanel');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_500_MS);
      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      let shutterButtonPoint: Point = await getComponentCenterPoint(id, driver);
      let shutterX: number = shutterButtonPoint.x;
      let shutterY: number = shutterButtonPoint.y;
      HiLog.i(TAG, 'find shutterButton coordinate');

      id = ComponentIdKeys.SWITCH_CAMERA_1;
      let switchCamPoint: Point = await getComponentCenterPoint(id, driver);
      let thumbX: number = switchCamPoint.x;
      let thumbY: number = switchCamPoint.y;

      let pointXOverSwitchCam: number = Math.floor((thumbX - shutterX) * DRAG_DISTANCE_RATIO_HALF + shutterX);
      let pointYOverSwitchCam: number = Math.floor((thumbY - shutterY) * DRAG_DISTANCE_RATIO_HALF + shutterY);

      expect(id).not().assertNull();
      // 长按快门并拖动
      await driver.drag(shutterX, shutterY, pointXOverSwitchCam, pointYOverSwitchCam);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Treasure_01');
    });

    it('LeftRightSwipeTest_LongPress_PressRecord_Treasure_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Treasure_02');
      HiLog.i(TAG, 'start video record');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_2));
      HiLog.i(TAG, 'assert stop video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_RECORDING_2));
      HiLog.i(TAG, 'assert pause video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.LEFT_RIGHT_SWIPE_RECORD_CAPTURE));
      HiLog.i(TAG, 'assert video capture button exist');

      await TestUtils.ClickComponentIfExist(driver, ComponentIdKeys.SHUTTER_VIDEO_END_2,
        TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Treasure_02');
    });


    it('LeftRightSwipeTest_LongPress_PressRecord_Treasure_03', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Treasure_03');
      let id = ComponentIdKeys.THUMBNAIL_1;
      HiLog.i(TAG, 'click on the thumbnail');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'slide back');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Treasure_03');
    });

    /**
     * 长按录像
     * 1.长按快门
     * 2.进入录像
     * 3.暂停又继续录像
     * 4.停止录像
     * 5.查看缩略图
     * 6.返回
     */
    it('LeftRightSwipeTest_LongPress_PressRecord_PauseResume_Stop_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_PauseResume_Stop_01');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      let shutterButtonPoint: Point = await getComponentCenterPoint(id, driver);
      let shutterX: number = shutterButtonPoint.x;
      let shutterY: number = shutterButtonPoint.y;
      HiLog.i(TAG, 'find shutterButton coordinate');

      id = ComponentIdKeys.SWITCH_CAMERA_1;
      let switchCamPoint: Point = await getComponentCenterPoint(id, driver);
      let thumbX: number = switchCamPoint.x;
      let thumbY: number = switchCamPoint.y;

      let pointXOverSwitchCam: number = Math.floor((thumbX - shutterX) * DRAG_DISTANCE_RATIO_HALF + shutterX);
      let pointYOverSwitchCam: number = Math.floor((thumbY - shutterY) * DRAG_DISTANCE_RATIO_HALF + shutterY);

      expect(id).not().assertNull();
      // 长按快门并拖动
      await driver.drag(shutterX, shutterY, pointXOverSwitchCam, pointYOverSwitchCam);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_PauseResume_Stop_01');
    });

    it('LeftRightSwipeTest_LongPress_PressRecord_PauseResume_Stop_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_PauseResume_Stop_02');
      HiLog.i(TAG, 'start video record');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_2));
      HiLog.i(TAG, 'assert stop video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_RECORDING_2));
      HiLog.i(TAG, 'assert pause video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.LEFT_RIGHT_SWIPE_RECORD_CAPTURE));
      HiLog.i(TAG, 'assert video capture button exist');
      await driver.delayMs(TestConstants.DELAY_500_MS);

      await TestUtils.ClickComponentIfExist(driver, ComponentIdKeys.VIDEO_RECORDING_2, TestConstants.DELAY_500_MS);

      await TestUtils.ClickComponentIfExist(driver, ComponentIdKeys.VIDEO_PAUSE_2, TestConstants.DELAY_500_MS);

      await TestUtils.ClickComponentIfExist(driver, ComponentIdKeys.SHUTTER_VIDEO_END_2,
        TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_PauseResume_Stop_02');
    });

    /**
     * 长按录像
     * 1.长按快门
     * 2.进入录像
     * 3.暂停录像
     * 4.停止录像
     * 5.查看缩略图
     * 6.返回
     */
    it('LeftRightSwipeTest_LongPress_PressRecord_Pause_Stop_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Pause_Stop_01');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      let shutterButtonPoint: Point = await getComponentCenterPoint(id, driver);
      let shutterX: number = shutterButtonPoint.x;
      let shutterY: number = shutterButtonPoint.y;
      HiLog.i(TAG, 'find shutterButton coordinate');

      id = ComponentIdKeys.SWITCH_CAMERA_1;
      let switchCamPoint: Point = await getComponentCenterPoint(id, driver);
      let thumbX: number = switchCamPoint.x;
      let thumbY: number = switchCamPoint.y;

      let pointXOverSwitchCam: number = Math.floor((thumbX - shutterX) * DRAG_DISTANCE_RATIO_HALF + shutterX);
      let pointYOverSwitchCam: number = Math.floor((thumbY - shutterY) * DRAG_DISTANCE_RATIO_HALF + shutterY);

      expect(id).not().assertNull();
      // 长按快门并拖动
      await driver.drag(shutterX, shutterY, pointXOverSwitchCam, pointYOverSwitchCam);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Pause_Stop_01');
    });

    it('LeftRightSwipeTest_LongPress_PressRecord_Pause_Stop_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Pause_Stop_02');
      HiLog.i(TAG, 'start video record');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_2));
      HiLog.i(TAG, 'assert stop video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_RECORDING_2));
      HiLog.i(TAG, 'assert pause video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.LEFT_RIGHT_SWIPE_RECORD_CAPTURE));
      HiLog.i(TAG, 'assert video capture button exist');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);

      await TestUtils.ClickComponentIfExist(driver, ComponentIdKeys.VIDEO_RECORDING_2, TestConstants.DELAY_ONE_SECOND);

      await TestUtils.ClickComponentIfExist(driver, ComponentIdKeys.SHUTTER_VIDEO_END_2,
        TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Pause_Stop_02');
    });


    it('LeftRightSwipeTest_LongPress_PressRecord_Pause_Stop_03', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Pause_Stop_03');
      let id = ComponentIdKeys.THUMBNAIL_1;
      HiLog.i(TAG, 'click on the thumbnail');
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'slide back');
      await TestUtils.slideLeftFromScreen(driver);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Pause_Stop_03');
    });

    /**
     * 长按录像
     * 1.长按快门
     * 2.进入录像
     * 3.双指捏合zoomOut
     * 4.停止录像
     * 5.查看缩略图
     * 6.返回
     */
    it('LeftRightSwipeTest_LongPress_PressRecord_ZoomOut_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_ZoomOut_01');

      HiLog.i(TAG, 'quickZoom clicked');
      await TestUtils.ClickComponentIfExist(driver, 'QUICK_ZOOM_INDEX_3', TestConstants.DELAY_MIN_TIME);

      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      let shutterButtonPoint: Point = await getComponentCenterPoint(id, driver);
      let shutterX: number = shutterButtonPoint.x;
      let shutterY: number = shutterButtonPoint.y;
      HiLog.i(TAG, 'find shutterButton coordinate');

      id = ComponentIdKeys.SWITCH_CAMERA_1;
      let switchCamPoint: Point = await getComponentCenterPoint(id, driver);
      let thumbX: number = switchCamPoint.x;
      let thumbY: number = switchCamPoint.y;

      let pointXOverSwitchCam: number = Math.floor((thumbX - shutterX) * DRAG_DISTANCE_RATIO_HALF + shutterX);
      let pointYOverSwitchCam: number = Math.floor((thumbY - shutterY) * DRAG_DISTANCE_RATIO_HALF + shutterY);

      expect(id).not().assertNull();
      // 长按快门并拖动
      await driver.drag(shutterX, shutterY, pointXOverSwitchCam, pointYOverSwitchCam, FAST_DRAG_SPEED);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_ZoomOut_01');
    });

    it('LeftRightSwipeTest_LongPress_PressRecord_ZoomOut_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_ZoomOut_02');
      HiLog.i(TAG, 'start video record');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_2));
      HiLog.i(TAG, 'assert stop video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_RECORDING_2));
      HiLog.i(TAG, 'assert pause video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.LEFT_RIGHT_SWIPE_RECORD_CAPTURE));
      HiLog.i(TAG, 'assert video capture button exist');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_ZoomOut_02');
    });

    it('LeftRightSwipeTest_LongPress_PressRecord_ZoomOut_03', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_ZoomOut_03');
      // 双指捏合放大
      let id = ComponentIdKeys.PREVIEW_WINDOW_1;
      await TestUtils.testPinchOutById(driver, id, TestConstants.DELAY_ONE_SECOND);

      await TestUtils.ClickComponentIfExist(driver, ComponentIdKeys.SHUTTER_VIDEO_END_2,
        TestConstants.DELAY_ONE_SECOND);

      HiLog.i(TAG, 'quickZoom reset');
      await TestUtils.ClickComponentIfExist(driver, 'QUICK_ZOOM_INDEX_1', TestConstants.DELAY_MIN_TIME);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_ZoomOut_03');
    });

    /**
     * 长按录像
     * 1.长按快门
     * 2.进入录像
     * 3.录像中拍照
     * 4.停止录像
     * 5.查看缩略图
     * 6.返回
     */
    it('LeftRightSwipeTest_LongPress_PressRecord_Capture_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Capture');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      let shutterButtonPoint: Point = await getComponentCenterPoint(id, driver);
      let shutterX: number = shutterButtonPoint.x;
      let shutterY: number = shutterButtonPoint.y;
      HiLog.i(TAG, 'find shutterButton coordinate');

      id = ComponentIdKeys.SWITCH_CAMERA_1;
      let switchCamPoint: Point = await getComponentCenterPoint(id, driver);
      let thumbX: number = switchCamPoint.x;
      let thumbY: number = switchCamPoint.y;

      let pointXOverSwitchCam: number = Math.floor((thumbX - shutterX) * DRAG_DISTANCE_RATIO_HALF + shutterX);
      let pointYOverSwitchCam: number = Math.floor((thumbY - shutterY) * DRAG_DISTANCE_RATIO_HALF + shutterY);

      expect(id).not().assertNull();
      // 长按快门并拖动
      await driver.drag(shutterX, shutterY, pointXOverSwitchCam, pointYOverSwitchCam, FAST_DRAG_SPEED);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Capture');
    });

    it('LeftRightSwipeTest_LongPress_PressRecord_Capture_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Capture');
      HiLog.i(TAG, 'start video record');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_2));
      HiLog.i(TAG, 'assert stop video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_RECORDING_2));
      HiLog.i(TAG, 'assert pause video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.LEFT_RIGHT_SWIPE_RECORD_CAPTURE));
      HiLog.i(TAG, 'assert video capture button exist');
      await driver.delayMs(TestConstants.DELAY_500_MS);

      // 录像中拍照
      await TestUtils.ClickComponentIfExist(driver, ComponentIdKeys.LEFT_RIGHT_SWIPE_RECORD_CAPTURE,
        TestConstants.DELAY_ONE_SECOND);

      await TestUtils.ClickComponentIfExist(driver, ComponentIdKeys.SHUTTER_VIDEO_END_2, TestConstants.DELAY_500_MS);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Capture');
    });

    /**
     * 长按连拍
     * 1.打开LivePhoto
     * 2.长按快门
     * 3.进入连拍
     * 4.松手后查看缩略图
     * 5.返回
     */
    it('LeftRightSwipeTest_LongPress_Burst_LivePhoto_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_Burst_LivePhoto_01');
      HiLog.i(TAG, 'treasureBox open');
      let id = ComponentIdKeys.TREASURE_BOX_ARROW;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'treasureBox slide from left to right');
      await TestUtils.slideTreasureBox(driver);
      HiLog.i(TAG, 'LivePhoto click.');
      // id = ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.LIVE_PHOTO);
      // await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      let shutterButtonPoint: Point = await getComponentCenterPoint(id, driver);
      let shutterX: number = shutterButtonPoint.x;
      let shutterY: number = shutterButtonPoint.y;
      HiLog.i(TAG, 'find shutterButton coordinate');

      id = ComponentIdKeys.THUMBNAIL_1;
      let thumbnailPoint: Point = await getComponentCenterPoint(id, driver);
      let thumbX: number = thumbnailPoint.x;
      let thumbY: number = thumbnailPoint.y;

      let pointXOverThumb: number = Math.floor((thumbX - shutterX) * DRAG_DISTANCE_RATIO + shutterX);
      let pointYOverThumb: number = Math.floor((thumbY - shutterY) * DRAG_DISTANCE_RATIO + shutterY);

      expect(id).not().assertNull();
      // 长按快门并拖动
      await driver.drag(shutterX, shutterY, pointXOverThumb, pointYOverThumb, FAST_DRAG_SPEED);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_Burst_LivePhoto_01');
    });

    it('LeftRightSwipeTest_LongPress_Burst_LivePhoto_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_Burst_LivePhoto_02');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'stop long click');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.THUMBNAIL_1));
      HiLog.i(TAG, 'assert thumbnail exist');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SWITCH_CAMERA_1));
      HiLog.i(TAG, 'assert switch camera exist');
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_Burst_LivePhoto_02');
    });

    it('LeftRightSwipeTest_LongPress_PressRecord_LivePhoto_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_LivePhoto_02');

      HiLog.i(TAG, 'start video record');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_2));
      HiLog.i(TAG, 'assert stop video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_RECORDING_2));
      HiLog.i(TAG, 'assert pause video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.LEFT_RIGHT_SWIPE_RECORD_CAPTURE));
      HiLog.i(TAG, 'assert video capture button exist');

      await TestUtils.ClickComponentIfExist(driver, ComponentIdKeys.SHUTTER_VIDEO_END_2,
        TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_LivePhoto_02');
    });

    /**
     * 长按连拍
     * 1.打开打开闪光灯
     * 2.长按快门
     * 3.进入连拍
     * 4.松手后查看缩略图
     * 5.返回
     */
    it('LeftRightSwipeTest_LongPress_Burst_Flash_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_Burst_Flash_01');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashOn');
      id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.ON);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      id = ComponentIdKeys.SHUTTER_PHOTO_1;
      let shutterButtonPoint: Point = await getComponentCenterPoint(id, driver);
      let shutterX: number = shutterButtonPoint.x;
      let shutterY: number = shutterButtonPoint.y;
      HiLog.i(TAG, 'find shutterButton coordinate');

      id = ComponentIdKeys.THUMBNAIL_1;
      let thumbnailPoint: Point = await getComponentCenterPoint(id, driver);
      let thumbX: number = thumbnailPoint.x;
      let thumbY: number = thumbnailPoint.y;

      let pointXOverThumb: number = Math.floor((thumbX - shutterX) * DRAG_DISTANCE_RATIO + shutterX);
      let pointYOverThumb: number = Math.floor((thumbY - shutterY) * DRAG_DISTANCE_RATIO + shutterY);

      expect(id).not().assertNull();
      // 长按快门并拖动
      await driver.drag(shutterX, shutterY, pointXOverThumb, pointYOverThumb, FAST_DRAG_SPEED);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_Burst_Flash_01');
    });

    it('LeftRightSwipeTest_LongPress_Burst_Flash_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_Burst_Flash_02');
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'stop long click');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.THUMBNAIL_1));
      HiLog.i(TAG, 'assert thumbnail exist');
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SWITCH_CAMERA_1));
      HiLog.i(TAG, 'assert switch camera exist');

      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashOff');
      id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.OFF);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);

      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_Burst_Flash_02');
    });

    /**
     * 长按录像
     * 1.打开闪光灯
     * 2.长按快门
     * 3.进入录像
     * 4.按停止录像
     * 5.查看缩略图
     * 6.返回
     */
    it('LeftRightSwipeTest_LongPress_PressRecord_Flash_01', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Flash_01');
      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashOn');
      id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.ON);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      expect(id).not().assertNull();
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Flash_01');
    });

    it('LeftRightSwipeTest_LongPress_PressRecord_Flash_02', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Flash_02');
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      let shutterButtonPoint: Point = await getComponentCenterPoint(id, driver);
      let shutterX: number = shutterButtonPoint.x;
      let shutterY: number = shutterButtonPoint.y;
      HiLog.i(TAG, 'find shutterButton coordinate');

      id = ComponentIdKeys.SWITCH_CAMERA_1;
      let switchCamPoint: Point = await getComponentCenterPoint(id, driver);
      let thumbX: number = switchCamPoint.x;
      let thumbY: number = switchCamPoint.y;

      let pointXOverSwitchCam: number = Math.floor((thumbX - shutterX) * DRAG_DISTANCE_RATIO_HALF + shutterX);
      let pointYOverSwitchCam: number = Math.floor((thumbY - shutterY) * DRAG_DISTANCE_RATIO_HALF + shutterY);

      expect(id).not().assertNull();
      // 长按快门并拖动
      await driver.drag(shutterX, shutterY, pointXOverSwitchCam, pointYOverSwitchCam);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Flash_02');
    });


    it('LeftRightSwipeTest_LongPress_PressRecord_Flash_03', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Flash_03');
      HiLog.i(TAG, 'start video record');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_2));
      HiLog.i(TAG, 'assert stop video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_RECORDING_2));
      HiLog.i(TAG, 'assert pause video button exist');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.LEFT_RIGHT_SWIPE_RECORD_CAPTURE));
      HiLog.i(TAG, 'assert video capture button exist');

      await TestUtils.ClickComponentIfExist(driver, ComponentIdKeys.SHUTTER_VIDEO_END_2,
        TestConstants.DELAY_ONE_SECOND);

      let id = FLASH_ID;
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashOff');
      id = ComponentIdKeys.getInstance().getKey('TAB_BAR_FLASH', FlashMode.OFF);
      await TestUtils.ClickComponentIfExist(driver, id, TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'LeftRightSwipeTest_LongPress_PressRecord_Flash_03');
    });

    /**
     * LeftRightSwipeTest 恢复默认值
     * 悬浮快门键 关闭
     */
    it('LeftRightSwipeTest_Restore', Level.LEVEL1, async () => {
      HiLog.begin(TAG, 'LeftRightSwipeTest_Restore');
      await SettingsPageHandler.RestoreDefaultValue(driver).then(() => {
        HiLog.i(TAG, 'LeftRightSwipeTest test is restore default value.');
      });
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'LeftRightSwipeTest_Restore');
    });
  });
}

async function getComponentCenterPoint(id: string, driver: Driver): Promise<Point> {
  let component: Component = await driver.findComponent(ON.id(id));
  await driver.delayMs(TestConstants.DELAY_500_MS);
  let componentCenterPoint: Point = await component.getBoundsCenter();
  return componentCenterPoint;
}