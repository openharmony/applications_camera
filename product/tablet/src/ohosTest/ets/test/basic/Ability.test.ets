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
import { FlashMode } from '@ohos/common/src/main/ets/function/enumbase/FlashMode';
import { BusinessError } from '@ohos.base';
import { TestConstants } from '../../TestConstants';

const TAG: string = 'CameraAbilityTest';

export default function abilityTest() {
  describe('ActsAbilityTest', () => {
    /**
     * 打开应用
     */
    it('StartAbility_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'StartAbility_001');
      let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
      try {
        await abilityDelegator.startAbility({
          bundleName: 'com.ohos.camera',
          abilityName: 'com.ohos.camera.MainAbility'
        });
      } catch (error) {
        let exp = error as BusinessError;
        expect(0).assertEqual(error?.code);
        HiLog.i(TAG, `StartAbility err ${exp?.code}`);
      }
      HiLog.end(TAG, 'StartAbility_001');
    });

    /**
     * 隐私权限 同意
     */
    it('PermissionUsageFunction_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'PermissionUsageFunction_001');
      const driver = await Driver.create();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'agree.');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.INTRO_PERMISSION_AGREE));
      let permissionAgree = await driver.findComponent(ON.id(ComponentIdKeys.INTRO_PERMISSION_AGREE));
      await permissionAgree.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      // 成功返回相机页面
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.end(TAG, 'PermissionUsageFunction_001');
    });

    /**
     * 基础拍照
     * 1.拍照模式
     * 2.点击拍照
     * 3.查看缩略图
     * 4.滑动返回
     * 5.返回相机
     */
    it('TakePhotoFunction_001', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'TakePhotoFunction_001 begin');
      let driver = await Driver.create();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'photoMode');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.PHOTO)));
      let photoMode = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('ControlModeText', ModeType.PHOTO)));
      await photoMode.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click to take a photo');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      let shutterPhoto = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await shutterPhoto.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click on the thumbnail');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.THUMBNAIL_1));
      let thumbnail = await driver.findComponent(ON.id(ComponentIdKeys.THUMBNAIL_1));
      await thumbnail.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'slide back');
      let pointers01 = PointerMatrix.create(1, 3);
      pointers01.setPoint(0, 0, {
        x: 1250, y: 1355
      });
      pointers01.setPoint(0, 1, {
        x: 900, y: 1355
      });
      pointers01.setPoint(0, 2, {
        x: 700, y: 1355
      });
      await driver.injectMultiPointerAction(pointers01);
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'TakePhotoFunction_001 end');
    });

    /**
     * 闪光灯
     * 1.点击闪光灯设置 闪光灯-自动
     * 2.点击闪光灯设置 闪光灯-打开
     * 3.点击闪光灯设置 闪光灯-常亮
     * 4.点击闪光灯设置 闪光灯-关闭
     */
    it('ChangeFlashModeFunction_001', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'ChangeFlashModeFunction_001 begin');
      let driver = await Driver.create();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashSetting open');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.POPUPBUTTON_1));
      let flashSetting = await driver.findComponent(ON.id(ComponentIdKeys.POPUPBUTTON_1));
      await flashSetting.click();
      HiLog.i(TAG, 'flashAuto');
      let flashAuto = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TabBarFLASH', FlashMode.AUTO)));
      await flashAuto.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashSetting open');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.POPUPBUTTON_1));
      flashSetting = await driver.findComponent(ON.id(ComponentIdKeys.POPUPBUTTON_1));
      await flashSetting.click();
      HiLog.i(TAG, 'flashOn');
      let flashOn = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TabBarFLASH', FlashMode.ON)));
      await flashOn.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashSetting open');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.POPUPBUTTON_1));
      flashSetting = await driver.findComponent(ON.id(ComponentIdKeys.POPUPBUTTON_1));
      await flashSetting.click();
      HiLog.i(TAG, 'flashAlwaysOpen');
      let flashAlwaysOpen = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TabBarFLASH', FlashMode.ALWAYS_OPEN)));
      await flashAlwaysOpen.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'flashSetting open');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.POPUPBUTTON_1));
      flashSetting = await driver.findComponent(ON.id(ComponentIdKeys.POPUPBUTTON_1));
      await flashSetting.click();
      HiLog.i(TAG, 'flash off');
      let flashOff = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TabBarFLASH', FlashMode.OFF)));
      await flashOff.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'ChangeFlashModeFunction_001 end');
    });

    /**
     * 拍照前后置切换
     * 1.点击切换前后置
     * 2.点击拍照
     * 3.点击自拍镜像开
     * 4.点击自拍镜像确定
     * 5.点击拍照
     * 6.点击切换前后置
     */
    it('SwitchPhotoCameraFunction_001', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'SwitchPhotoCameraFunction_001 begin');
      let driver = await Driver.create();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'switch camera');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SWITCH_PROFESSION_1));
      let switchCamera = await driver.findComponent(ON.id(ComponentIdKeys.SWITCH_PROFESSION_1));
      await switchCamera.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click to take a photo');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      let shutterPhoto = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await shutterPhoto.click();
      await driver.delayMs(TestConstants.DELAY_FIVE_SECOND);
      HiLog.i(TAG, 'click to take a photo, second');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      shutterPhoto = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await shutterPhoto.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'switch camera back');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SWITCH_PROFESSION_1));
      switchCamera = await driver.findComponent(ON.id(ComponentIdKeys.SWITCH_PROFESSION_1));
      await switchCamera.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'SwitchPhotoCameraFunction_001 end');
    });

    /**
     * 基础录像
     * 1.点击录像模式
     * 2.点击开始录像
     * 3.点击暂停录像 点击继续录像
     * 4.点击暂停录像 点击继续录像
     * 5.点击结束录像
     */
    it('VideoRecordFunction_001', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'VideoRecordFunction_001 begin');
      let driver = await Driver.create();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'videoMode');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO)));
      let videoMode = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('ControlModeText', ModeType.VIDEO)));
      await videoMode.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'start recording');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      let shutterVideo = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      await shutterVideo.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'pause recording');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_RECORDING_1));
      let videoRecord = await driver.findComponent(ON.id(ComponentIdKeys.VIDEO_RECORDING_1));
      await videoRecord.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'continue recording');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_PAUSE_1));
      let videoPause = await driver.findComponent(ON.id(ComponentIdKeys.VIDEO_PAUSE_1));
      await videoPause.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'pause recording, second');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_RECORDING_1));
      videoRecord = await driver.findComponent(ON.id(ComponentIdKeys.VIDEO_RECORDING_1));
      await videoRecord.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'continue recording, second');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_PAUSE_1));
      videoPause = await driver.findComponent(ON.id(ComponentIdKeys.VIDEO_PAUSE_1));
      await videoPause.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'end recording');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_1));
      let shutterVideoEnd = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_1));
      await shutterVideoEnd.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'VideoRecordFunction_001 end');
    });

    /**
     * 录像前后置切换
     * 1.点击录像
     * 2.点击切换前后置
     * 3.点击 开始-暂停-继续-结束 录像
     * 4.点击切换前后置
     */
    it('SwitchVideoCameraFunction_001', Level.LEVEL0, async () => {
      HiLog.i(TAG, 'SwitchVideoCameraFunction_001 begin');
      let driver = await Driver.create();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'click recording');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance().getKey('ControlModeText', ModeType.VIDEO)));
      let videoMode = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('ControlModeText', ModeType.VIDEO)));
      await videoMode.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'switch camera');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SWITCH_PROFESSION_1));
      let switchCamera = await driver.findComponent(ON.id(ComponentIdKeys.SWITCH_PROFESSION_1));
      await switchCamera.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'start recording');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      let shutterVideo = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      await shutterVideo.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);
      HiLog.i(TAG, 'pause recording');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_RECORDING_1));
      let videoRecord = await driver.findComponent(ON.id(ComponentIdKeys.VIDEO_RECORDING_1));
      await videoRecord.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      // 点击继续录像
      HiLog.i(TAG, 'continue recording');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.VIDEO_PAUSE_1));
      let videoPause = await driver.findComponent(ON.id(ComponentIdKeys.VIDEO_PAUSE_1));
      await videoPause.click();
      await driver.delayMs(TestConstants.DELAY_TWO_SECOND);

      // 点击结束录像
      HiLog.i(TAG, 'end recording');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_1));
      let shutterVideoEnd = await driver.findComponent(ON.id(ComponentIdKeys.SHUTTER_VIDEO_END_1));
      await shutterVideoEnd.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      // 点击切换前后置
      HiLog.i(TAG, 'switch camera back');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SWITCH_PROFESSION_1));
      switchCamera = await driver.findComponent(ON.id(ComponentIdKeys.SWITCH_PROFESSION_1));
      await switchCamera.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_VIDEO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'SwitchVideoCameraFunction_001 end');
    });

    /**
     * 设置页 弹窗
     * 1.点击拍照模式
     * 2.打开百宝箱
     * 3.点击设置
     * 4.点击照片比例 1:1  2
     * 5.第二次点击照片比例 全屏  3
     * 6.第三次点击照片比例 4:3  1
     * 7.点击视频分辨率 [16:9]4k  1
     * 8.第二次点击视频分辨率 [全屏]1080p  2
     * 9.第三次点击视频分辨率 [16:9]720p  4
     * 10.第四次点击视频分辨率 [16:9]1080p  3
     * 11.点击视频帧率 60fps  2
     * 12.第二次点击视频帧率 30fps  1
     * 13.点击定时拍摄 2s  2
     * 14.第二次点击定时拍摄 5s  3
     * 15.第三次点击定时拍摄 10s  4
     * 16.第四次点击定时拍摄 关闭  1
     * 17.第四次点击定时拍摄 关闭  1
     * 18.设置页返回
     * 19.关闭百宝箱
     */
    it('SettingViewPopupFunction_001', Level.LEVEL0, async () => {
      HiLog.begin(TAG, 'SettingViewPopupFunction_001');
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
      HiLog.i(TAG, 'settingView open');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance().getKey('TreasureBox', FunctionId.SETTING)));
      let settingView = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('TreasureBox', FunctionId.SETTING)));
      await settingView.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemAspectRatio clicked');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.ASPECT_RATIO)));
      let itemAspectRatio = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.ASPECT_RATIO)));
      await itemAspectRatio.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemAspectRatio 1:1');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.ASPECT_RATIO, '2')));
      let itemAspectRatio1_1 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.ASPECT_RATIO, '2')));
      await itemAspectRatio1_1.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemAspectRatio clicked, second');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.ASPECT_RATIO)));
      itemAspectRatio = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.ASPECT_RATIO)));
      await itemAspectRatio.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemAspectRatio full');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.ASPECT_RATIO, '3')));
      let itemAspectRatioFull = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.ASPECT_RATIO, '3')));
      await itemAspectRatioFull.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemAspectRatio clicked, third');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.ASPECT_RATIO)));
      itemAspectRatio = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.ASPECT_RATIO)));
      await itemAspectRatio.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemAspectRatio 4:3');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.ASPECT_RATIO, '1')));
      let itemAspectRatio4_3 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.ASPECT_RATIO, '1')));
      await itemAspectRatio4_3.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution clicked');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.VIDEO_RESOLUTION)));
      let itemVideoResolution = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.VIDEO_RESOLUTION)));
      await itemVideoResolution.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution 4k');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.VIDEO_RESOLUTION, '1')));
      let itemVideoResolutionFull_4k = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.VIDEO_RESOLUTION, '1')));
      await itemVideoResolutionFull_4k.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution clicked, second');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.VIDEO_RESOLUTION)));
      itemVideoResolution = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.VIDEO_RESOLUTION)));
      await itemVideoResolution.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution full 1080p');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.VIDEO_RESOLUTION, '2')));
      let itemVideoResolutionFull_1080 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.VIDEO_RESOLUTION, '2')));
      await itemVideoResolutionFull_1080.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution clicked, third');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.VIDEO_RESOLUTION)));
      itemVideoResolution = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.VIDEO_RESOLUTION)));
      await itemVideoResolution.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution 720p');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.VIDEO_RESOLUTION, '4')));
      let itemVideoResolution720 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.VIDEO_RESOLUTION, '4')));
      await itemVideoResolution720.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution clicked, fourth');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.VIDEO_RESOLUTION)));
      itemVideoResolution = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.VIDEO_RESOLUTION)));
      await itemVideoResolution.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemVideoResolution 1080p');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.VIDEO_RESOLUTION, '3')));
      let itemVideoResolution1080 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.VIDEO_RESOLUTION, '3')));
      await itemVideoResolution1080.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemFrameRate clicked');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.FRAME_RATE)));
      let itemFrameRate = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.FRAME_RATE)));
      await itemFrameRate.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemFrameRate 60');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.FRAME_RATE, '2')));
      let itemFrameRate60 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.FRAME_RATE, '2')));
      await itemFrameRate60.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemFrameRate clicked, second');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.FRAME_RATE)));
      itemFrameRate = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.FRAME_RATE)));
      await itemFrameRate.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemFrameRate 30');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.FRAME_RATE, '1')));
      let itemFrameRate30 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.FRAME_RATE, '1')));
      await itemFrameRate30.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemTimeLapse clicked');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.TIME_LAPSE)));
      let itemTimeLapse = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.TIME_LAPSE)));
      await itemTimeLapse.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemTimeLapse 2s');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.TIME_LAPSE, '2')));
      let itemTimeLapse2 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.TIME_LAPSE, '2')));
      await itemTimeLapse2.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemTimeLapse clicked, second');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.TIME_LAPSE)));
      itemTimeLapse = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.TIME_LAPSE)));
      await itemTimeLapse.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemTimeLapse 5s');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.TIME_LAPSE, '3')));
      let itemTimeLapse5 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.TIME_LAPSE, '3')));
      await itemTimeLapse5.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemTimeLapse clicked, third');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.TIME_LAPSE)));
      itemTimeLapse = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.TIME_LAPSE)));
      await itemTimeLapse.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemTimeLapse 10s');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.TIME_LAPSE, '4')));
      let itemTimeLapse10 = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.TIME_LAPSE, '4')));
      await itemTimeLapse10.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemTimeLapse clicked, fourth');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.TIME_LAPSE)));
      itemTimeLapse = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingItemPOPUP', FunctionId.TIME_LAPSE)));
      await itemTimeLapse.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'itemTimeLapse off');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.TIME_LAPSE, '1')));
      let itemTimeLapseOff = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
        .getKey('SettingDialog', FunctionId.TIME_LAPSE, '1')));
      await itemTimeLapseOff.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'settingView back');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.NAV_DESTINATION_TITLE_BACK_1));
      let settingViewBack = await driver.findComponent(ON.id(ComponentIdKeys.NAV_DESTINATION_TITLE_BACK_1));
      await settingViewBack.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'treasureBox close.');
      await driver.assertComponentExist(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      let treasureBoxClose = await driver.findComponent(ON.id(ComponentIdKeys.TREASURE_BOX_ARROW));
      await treasureBoxClose.click();
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
      await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
      HiLog.i(TAG, 'SettingViewPopupFunction_001 end.');
    });
  })
}
