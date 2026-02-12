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

import lazy { FunctionId } from '../function/core/functionproperty/FunctionId';
import lazy { FlashMode } from '../function/enumbase/FlashMode';
import lazy { ModeType } from '../mode/ModeType';

/**
 * 自动化测试用例,开发动态to测试静态,控件key值映射表
 * 增、删、改控件时,时刻注意配置该映射表!!!!!
 * 映射表短期配置原则:
 *   1.增、删控件,与测试对齐控件唯一key值
 *   2.改控件,如ForEach类控件,历史功能控件与历史key值保持一一对应关系不变更
 * ComponentIdKeys常量: 对应独立控件,静态绑定
 * keysMap映射表: 对应ForEach等动态控件,动态绑定
 */
import lazy { HiLog } from './HiLog';
import lazy { camera } from '@kit.CameraKit';
import lazy { SettingFuncDialogItemIndex } from '../component/settingview/SettingFuncDialogItemIndex';

const TAG: string = 'ComponentIdKeys';

export class ComponentIdKeys {
  private code2TestKeysMap: Map<string, string>;
  private static sInstanceComponentIdKeys: ComponentIdKeys;

  private constructor() {
    this.code2TestKeysMap = new Map();
    this.createKeysMap();
  }

  public static getInstance(): ComponentIdKeys {
    if (!ComponentIdKeys.sInstanceComponentIdKeys) {
      ComponentIdKeys.sInstanceComponentIdKeys = new ComponentIdKeys();
    }
    return ComponentIdKeys.sInstanceComponentIdKeys;
  }

  getKey(...codeKey): string {
    let testKey = this.code2TestKeysMap.get(codeKey.join('_'));
    return testKey;
  }

  createKeysMap(): void {
    HiLog.i(TAG, 'createKeysMap.');
    this.setControlModeTextModeType();
    this.setTabBarPopupFunctionMode();
    this.setSettingItemFunction();
    this.setTreasureBox();
    this.setLandscapeTreasureBox();
    this.setProfessionFunctionItem();
    this.setModeDetailListItem();
    this.setVlogToolViewItem();
    this.setOutHomeItem();
  }

  private setControlModeTextModeType(): void {
    // Control区域模式列表,Control_Mode_Text_ModeType
    this.code2TestKeysMap.set('ControlModeText_' + ModeType.PHOTO, 'COMPONENT_ID_CONTROL_PHOTO_2'); // 模式区域-拍照
    this.code2TestKeysMap.set('ControlModeText_' + ModeType.VIDEO, 'COMPONENT_ID_CONTROL_VIDEO_2'); // 模式区域-录像
  }

  private setTabBarPopupFunctionMode(): void {
    // Popup状态类型列表,Location_RenderType_Function_FuncMode tab bar的二级key
    this.code2TestKeysMap.set('TAB_BAR_FLASH_' + FlashMode.AUTO, 'COMPONENT_ID_FLASH_AUTO');
    this.code2TestKeysMap.set('TAB_BAR_FLASH_' + FlashMode.ON, 'COMPONENT_ID_FLASH_ON');
    this.code2TestKeysMap.set('TAB_BAR_FLASH_' + FlashMode.OFF, 'COMPONENT_ID_FLASH_OFF');
    this.code2TestKeysMap.set('TAB_BAR_FLASH_' + FlashMode.ALWAYS_OPEN, 'COMPONENT_ID_FLASH_ALWAYS_OPEN');
    this.code2TestKeysMap.set('TAB_BAR_FLASH_' + FlashMode.TORCH, 'COMPONENT_ID_FLASH_ALWAYS_TORCH');
    this.code2TestKeysMap.set('TAB_BAR_STABILIZATION_RIGHT_TAB_BAR_' + camera.VideoStabilizationMode.OFF,
      'TAB_BAR_STABILIZATION_OFF');
    this.code2TestKeysMap.set('TAB_BAR_STABILIZATION_RIGHT_TAB_BAR_' + camera.VideoStabilizationMode.AUTO,
      'TAB_BAR_STABILIZATION_AUTO');
    this.code2TestKeysMap.set('TAB_BAR_STABILIZATION_RIGHT_TAB_BAR_' + camera.VideoStabilizationMode.HIGH,
      'TAB_BAR_STABILIZATION_HIGH');
    this.code2TestKeysMap.set('TAB_BAR_LIGHT_PAINTING_FLASH_' + FlashMode.OFF, 'COMPONENT_ID_LIGHT_PAINTING_FLASH_OFF');
    // TabBar视频分辨率和帧率切换按钮 tab bar的一级key
    this.code2TestKeysMap.set('TabBar_' + FunctionId.VIDEO_RESOLUTION, 'TAB_BAR_VIDEO_RESOLUTION_BUTTON');
    this.code2TestKeysMap.set('TabBar_' + FunctionId.FRAME_RATE, 'TAB_BAR_FRAME_RATE_BUTTON');
    this.code2TestKeysMap.set('TabBar_' + FunctionId.FLASH, 'TAB_BAR_FLASH');
    this.code2TestKeysMap.set('TAB_BAR_RING_LIGHT_0', 'TAB_BAR_RING_LIGHT_OFF');
    this.code2TestKeysMap.set('TAB_BAR_RING_LIGHT_1', 'TAB_BAR_RING_LIGHT_AUTO');
    this.code2TestKeysMap.set('TAB_BAR_RING_LIGHT_2', 'TAB_BAR_RING_LIGHT_ALWAYS_OPEN');
    this.code2TestKeysMap.set('TAB_BAR_RING_LIGHT_3', 'TAB_BAR_RING_LIGHT_TORCH');
  }

  private setSettingItemFunction(): void {
    // 设置页选项,Setting_Item_RenderType_Function
    this.code2TestKeysMap.set('SettingItemPOPUP_' + FunctionId.ASPECT_RATIO, 'COMPONENT_ID_SETTING_PHOTO_ITEM_0'); // 设置页选项-照片比例
    this.code2TestKeysMap.set('SettingItemPOPUP_' + FunctionId.VIDEO_RESOLUTION, 'COMPONENT_ID_SETTING_VIDEO_ITEM_0'); // 设置页选项-视频分辨率
    this.code2TestKeysMap.set('SettingItemPOPUP_' + FunctionId.FRAME_RATE, 'COMPONENT_ID_SETTING_VIDEO_ITEM_1'); // 设置页选项-视频帧率
    this.code2TestKeysMap.set('SettingItemPOPUP_' + FunctionId.TIME_LAPSE, 'COMPONENT_ID_SETTING_TIME_LAPSE_ITEM_0'); // 设置页选项-定时拍摄
    this.code2TestKeysMap.set('SettingItemPOPUP_' + FunctionId.TIMED_SHOT, 'COMPONENT_ID_SETTING_TIMED_SHOT_ITEM_0'); // 设置页选项-间隔定时拍

    this.code2TestKeysMap.set('SettingItemTOGGLE_' + FunctionId.HORIZONTAL_LEVEL, 'COMPONENT_ID_SETTING_HORIZONTAL_LEVEL_ITEM_0'); // 设置页选项-水平仪
    this.code2TestKeysMap.set('SettingItemTOGGLE_' + FunctionId.MIRROR, 'COMPONENT_ID_SETTING_MIRROR_ITEM_0'); // 设置页选项-自拍镜像
    this.code2TestKeysMap.set('SettingItemTOGGLE_' + FunctionId.ASSISTIVE_GRID, 'COMPONENT_ID_SETTING_ASSISTIVE_GRID_ITEM_0'); // 设置页选项-参考线
    this.code2TestKeysMap.set('SettingItemTOGGLE_' + FunctionId.SAVE_GEO_LOCATION, 'COMPONENT_ID_SETTING_SAVE_GEO_LOCATION_ITEM_0'); // 设置页选项-地理位置
    this.code2TestKeysMap.set('SettingItemTOGGLE_' + FunctionId.SOUND_MUTE, 'COMPONENT_ID_SETTING_SOUND_MUTE_ITEM_0'); // 设置页选项-拍摄静音
    this.code2TestKeysMap.set('SettingItemTOGGLE_' + FunctionId.FLOATING_SHUTTER, 'COMPONENT_ID_FLOATING_SHUTTER_0'); // 设置页选项-悬浮快门键
    this.code2TestKeysMap.set('SettingItemTOGGLE_' + FunctionId.EFFICIENT_VIDEO, 'COMPONENT_ID_SETTING_EFFICIENT_VIDEO_ITEM_0'); // 设置页选项-高效视频格式

    // 设置页选项中子控件: ICON、TITLE、DESC、CONTENT、TOGGLE
    this.code2TestKeysMap.set('SettingItemComponentTOGGLE_' + FunctionId.HORIZONTAL_LEVEL, 'COMPONENT_ID_SETTING_COMMON_ITEM_TOGGLE_200'); // 水平仪开关控件
    this.code2TestKeysMap.set('SettingItemComponentTOGGLE_' + FunctionId.MIRROR, 'COMPONENT_ID_SETTING_COMMON_ITEM_TOGGLE_1'); // 自拍镜像开关控件
    this.code2TestKeysMap.set('SettingItemComponentTOGGLE_' + FunctionId.ASSISTIVE_GRID, 'COMPONENT_ID_SETTING_COMMON_ITEM_TOGGLE_ASSISTIVE_GRID'); // 参考线开关控件
    this.code2TestKeysMap.set('SettingItemComponentTOGGLE_' + FunctionId.SAVE_GEO_LOCATION, 'COMPONENT_ID_SETTING_COMMON_ITEM_TOGGLE_LOCATION'); // 地理位置开关控件
    this.code2TestKeysMap.set('SettingItemComponentTOGGLE_' + FunctionId.SOUND_MUTE, 'COMPONENT_ID_SETTING_COMMON_ITEM_TOGGLE_SOUND_MUTE'); // 静音拍摄开关控件
    this.code2TestKeysMap.set('SettingItemComponentTOGGLE_' + FunctionId.EFFICIENT_VIDEO, 'COMPONENT_ID_SETTING_COMMON_ITEM_TOGGLE_EFFICIENT_VIDEO'); // 高效视频格式开关控件
    this.code2TestKeysMap.set('SettingItemComponentTOGGLE_' + FunctionId.FLOATING_SHUTTER, 'COMPONENT_ID_SETTING_COMMON_ITEM_TOGGLE_FLOATING_SHUTTER'); // 悬浮快门键开关控件
    // 设置页弹窗页选项,Setting_Dialog_FunctionId_SettingFuncDialogItemIndex
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.ASPECT_RATIO + '_1', 'COMPONENT_ID_SETTING_DIALOG_ITEM_RADIO_0'); // 照片比例选择弹窗-选择4:3
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.ASPECT_RATIO + '_2', 'COMPONENT_ID_SETTING_DIALOG_ITEM_RADIO_1'); // 照片比例选择弹窗-选择1:1
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.ASPECT_RATIO + '_3', 'COMPONENT_ID_SETTING_DIALOG_ITEM_RADIO_2'); // 照片比例选择弹窗-选择全屏
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.VIDEO_RESOLUTION + '_1', 'COMPONENT_ID_SETTING_DIALOG_ITEM_RADIO_0'); // 视频分辨率选择弹窗-4K
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.VIDEO_RESOLUTION + '_2', 'COMPONENT_ID_SETTING_DIALOG_ITEM_RADIO_1'); // 视频分辨率选择弹窗-全屏1080p
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.VIDEO_RESOLUTION + '_3', 'COMPONENT_ID_SETTING_DIALOG_ITEM_RADIO_2'); // 视频分辨率选择弹窗-1080P
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.VIDEO_RESOLUTION + '_4', 'COMPONENT_ID_SETTING_DIALOG_ITEM_RADIO_3'); // 视频分辨率选择弹窗-720p
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.VIDEO_RESOLUTION + '_5', 'COMPONENT_ID_SETTING_DIALOG_ITEM_RADIO_4'); // 视频分辨率选择弹窗-2.7K
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.FRAME_RATE + '_1', 'COMPONENT_ID_SETTING_DIALOG_ITEM_RADIO_0'); // 视频帧率选择弹窗-30fps
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.FRAME_RATE + '_2', 'COMPONENT_ID_SETTING_DIALOG_ITEM_RADIO_1'); // 视频帧率选择弹窗-60fps
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.TIME_LAPSE + '_1', 'COMPONENT_ID_SETTING_DIALOG_ITEM_TIME_OFF'); // 延时拍摄关
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.TIME_LAPSE + '_2', 'COMPONENT_ID_SETTING_DIALOG_ITEM_TIME_2S'); // 延时拍摄2s
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.TIME_LAPSE + '_3', 'COMPONENT_ID_SETTING_DIALOG_ITEM_TIME_5S'); // 延时拍摄5s
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.TIME_LAPSE + '_4', 'COMPONENT_ID_SETTING_DIALOG_ITEM_TIME_10S'); // 延时拍摄10s
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.TIMED_SHOT + '_1', 'COMPONENT_ID_SETTING_DIALOG_ITEM_TIME_OFF'); // 间隔定时拍关
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.TIMED_SHOT + '_2', 'COMPONENT_ID_SETTING_DIALOG_ITEM_TIME_2S'); // 间隔定时拍2s
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.TIMED_SHOT + '_3', 'COMPONENT_ID_SETTING_DIALOG_ITEM_TIME_5S'); // 间隔定时拍5s
    this.code2TestKeysMap.set('SettingDialog_' + FunctionId.TIMED_SHOT + '_4', 'COMPONENT_ID_SETTING_DIALOG_ITEM_TIME_10S'); // 间隔定时拍10s
  }

  private setTreasureBox(): void {
    // 百宝箱一级界面按钮
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.ASPECT_RATIO, 'TREASURE_BOX_ASPECT_RATIO_BUTTON');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.VIDEO_RESOLUTION, 'TREASURE_BOX_VIDEO_RESOLUTION_BUTTON');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.FRAME_RATE, 'TREASURE_BOX_FRAME_RATE_BUTTON');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.FLASH, 'TREASURE_BOX_FLASH_BUTTON');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.ASSISTIVE_GRID, 'TREASURE_BOX_ASSISTIVE_GRID_BUTTON');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.SETTING, 'TREASURE_BOX_SETTING_BUTTON');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.TIME_LAPSE, 'TREASURE_BOX_TIME_LAPSE_BUTTON');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.TIMED_SHOT, 'TREASURE_BOX_TIMED_SHOT_BUTTON');

    // 百宝箱二级界面按钮
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.ASPECT_RATIO + '_1', 'TREASURE_BOX_ASPECT_RATIO_4_3');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.ASPECT_RATIO + '_2', 'TREASURE_BOX_ASPECT_RATIO_1_1');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.ASPECT_RATIO + '_3', 'TREASURE_BOX_ASPECT_RATIO_FULL');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.VIDEO_RESOLUTION + '_1', 'TREASURE_BOX_VIDEO_RESOLUTION_4K');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.VIDEO_RESOLUTION + '_2', 'TREASURE_BOX_VIDEO_RESOLUTION_1080_FULL');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.VIDEO_RESOLUTION + '_3', 'TREASURE_BOX_VIDEO_RESOLUTION_1080');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.VIDEO_RESOLUTION + '_4', 'TREASURE_BOX_VIDEO_RESOLUTION_720');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.VIDEO_RESOLUTION + '_5', 'TREASURE_BOX_VIDEO_RESOLUTION_2.7K');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.FRAME_RATE + '_1', 'TREASURE_BOX_FRAME_30');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.FRAME_RATE + '_2', 'TREASURE_BOX_FRAME_60');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.FLASH + '_0', 'TREASURE_BOX_FLASH_OFF');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.FLASH + '_1', 'TREASURE_BOX_FLASH_ON');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.FLASH + '_2', 'TREASURE_BOX_FLASH_AUTO');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.FLASH + '_3', 'TREASURE_BOX_FLASH_ALWAYS_OPEN');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.TIME_LAPSE + '_0', 'TREASURE_BOX_TIME_LAPSE_OFF');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.TIME_LAPSE + '_2', 'TREASURE_BOX_TIME_LAPSE_2_SECONDS');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.TIME_LAPSE + '_3', 'TREASURE_BOX_TIME_LAPSE_5_SECONDS');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.TIME_LAPSE + '_4', 'TREASURE_BOX_TIME_LAPSE_10_SECONDS');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.TIMED_SHOT + '_0', 'TREASURE_BOX_TIMED_SHOT_OFF');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.TIMED_SHOT + '_2', 'TREASURE_BOX_TIMED_SHOT_2_SECONDS');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.TIMED_SHOT + '_3', 'TREASURE_BOX_TIMED_SHOT_5_SECONDS');
    this.code2TestKeysMap.set('TreasureBox_' + FunctionId.TIMED_SHOT + '_4', 'TREASURE_BOX_TIMED_SHOT_10_SECONDS');
  }

  private setLandscapeTreasureBox(): void {
    // 百宝箱一级界面按钮
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.SETTING, 'LANDSCAPE_TREASURE_BOX_SETTING_BUTTON');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.ASSISTIVE_GRID, 'LANDSCAPE_TREASURE_BOX_ASSISTIVE_GRID_BUTTON');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.FLASH, 'LANDSCAPE_TREASURE_BOX_FLASH_BUTTON');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.ASPECT_RATIO, 'LANDSCAPE_TREASURE_BOX_ASPECT_RATIO_BUTTON');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.FRAME_RATE, 'LANDSCAPE_TREASURE_BOX_FRAME_RATE_BUTTON');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.VIDEO_RESOLUTION, 'LANDSCAPE_TREASURE_BOX_VIDEO_RESOLUTION_BUTTON');
    // 百宝箱二级界面按钮
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.ASPECT_RATIO, 'LANDSCAPE_BOX_ASPECT_RATIO');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.ASPECT_RATIO + '_1', 'LANDSCAPE_BOX_ASPECT_RATIO_4_3');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.ASPECT_RATIO + '_2', 'LANDSCAPE_BOX_ASPECT_RATIO_1_1');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.ASPECT_RATIO + '_3', 'LANDSCAPE_BOX_ASPECT_RATIO_FULL');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.VIDEO_RESOLUTION, 'LANDSCAPE_BOX_VIDEO_RESOLUTION');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.VIDEO_RESOLUTION + '_1', 'LANDSCAPE_BOX_VIDEO_RESOLUTION_4K_16_9');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.VIDEO_RESOLUTION + '_2', 'LANDSCAPE_BOX_VIDEO_RESOLUTION_1080_21_9');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.VIDEO_RESOLUTION + '_3', 'LANDSCAPE_BOX_VIDEO_RESOLUTION_1080_16_9');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.VIDEO_RESOLUTION + '_4', 'LANDSCAPE_BOX_VIDEO_RESOLUTION_720_16_9');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.VIDEO_RESOLUTION + '_5', 'LANDSCAPE_BOX_VIDEO_RESOLUTION_2.7K_16_9');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.FRAME_RATE, 'LANDSCAPE_BOX_FRAME_RATE');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.FRAME_RATE + '_1', 'LANDSCAPE_BOX_FRAME_30');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.FRAME_RATE + '_2', 'LANDSCAPE_BOX_FRAME_60');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.FLASH, 'LANDSCAPE_BOX_FLASH');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.FLASH + '_0', 'LANDSCAPE_BOX_FLASH_OFF');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.FLASH + '_1', 'LANDSCAPE_BOX_FLASH_ON');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.FLASH + '_2', 'LANDSCAPE_BOX_FLASH_AUTO');
    this.code2TestKeysMap.set('LandscapeTreasureBox_' + FunctionId.FLASH + '_3', 'LANDSCAPE_BOX_FLASH_ALWAYS_OPEN');
  }


  private setProfessionFunctionItem(): void {
    // focus展开key
    this.code2TestKeysMap.set('FocusModeView_' + FunctionId.FOCUS + '_slider', 'FOCUS_MODE_VIEW_MODE_SLIDER');
    this.code2TestKeysMap.set('FocusModeView_' + FunctionId.FOCUS + '_0', 'FOCUS_MODE_VIEW_MODE_MANUAL');
    this.code2TestKeysMap.set('FocusModeView_' + FunctionId.FOCUS + '_1', 'FOCUS_MODE_VIEW_MODE_CONTINUOUS_AUTO');
    this.code2TestKeysMap.set('FocusModeView_' + FunctionId.FOCUS + '_2', 'FOCUS_MODE_VIEW_MODE_AUTO');
    this.code2TestKeysMap.set('LandscapeFocusModeView_' + FunctionId.FOCUS + '_slider', 'FOCUS_MODE_VIEW_MODE_SLIDER');
    this.code2TestKeysMap.set('LandscapeFocusModeView_' + FunctionId.FOCUS + '_0', 'FOCUS_MODE_VIEW_MODE_MANUAL');
    this.code2TestKeysMap.set('LandscapeFocusModeView_' + FunctionId.FOCUS + '_1', 'FOCUS_MODE_VIEW_MODE_CONTINUOUS_AUTO');
    this.code2TestKeysMap.set('LandscapeFocusModeView_' + FunctionId.FOCUS + '_2', 'FOCUS_MODE_VIEW_MODE_AUTO');

    this.code2TestKeysMap.set('ExposureBarView_' + FunctionId.EXPOSURE, 'EXPOSURE_EFFECT_VIEW');
    this.code2TestKeysMap.set('LandscapeExposureBarView_' + FunctionId.EXPOSURE, 'EXPOSURE_EFFECT_VIEW');

    this.code2TestKeysMap.set('ProfessionBar_' + '1', 'PROFESSION_BAR_METERING_MODE');
    this.code2TestKeysMap.set('ProfessionBar_' + '2', 'PROFESSION_BAR_ISO');
    this.code2TestKeysMap.set('ProfessionBar_' + '3', 'PROFESSION_BAR_APERTURE');
    this.code2TestKeysMap.set('ProfessionBar_' + '4', 'PROFESSION_BAR_S');
    this.code2TestKeysMap.set('ProfessionBar_' + '5', 'PROFESSION_BAR_EXPOSURE');
    this.code2TestKeysMap.set('ProfessionBar_' + '6', 'PROFESSION_BAR_FOCUS');
    this.code2TestKeysMap.set('ProfessionBar_' + '7', 'PROFESSION_BAR_WHITE_BELANCE');
    this.code2TestKeysMap.set('LandProfessionBar_' + '1', 'PROFESSION_BAR_METERING_MODE');
    this.code2TestKeysMap.set('LandProfessionBar_' + '2', 'PROFESSION_BAR_ISO');
    this.code2TestKeysMap.set('LandProfessionBar_' + '3', 'PROFESSION_BAR_APERTURE');
    this.code2TestKeysMap.set('LandProfessionBar_' + '4', 'PROFESSION_BAR_S');
    this.code2TestKeysMap.set('LandProfessionBar_' + '5', 'PROFESSION_BAR_EXPOSURE');
    this.code2TestKeysMap.set('LandProfessionBar_' + '6', 'PROFESSION_BAR_FOCUS');
    this.code2TestKeysMap.set('LandProfessionBar_' + '7', 'PROFESSION_BAR_WHITE_BELANCE');
  }

  private setModeDetailListItem(): void {
    this.code2TestKeysMap.set('ModeDetailListItem_' + ModeType.PHOTO, 'ModeDetailListItem_' + ModeType.PHOTO);
    this.code2TestKeysMap.set('ModeDetailListItem_' + ModeType.VIDEO, 'ModeDetailListItem_' + ModeType.VIDEO);
  }

  private setVlogToolViewItem(): void {
    this.code2TestKeysMap.set('VlogModeView' + '_0', 'VLOG_TOOL_VALUE_OFF');
    this.code2TestKeysMap.set('VlogModeView' + '_1', 'VLOG_TOOL_NEAR_FOCUS');
    this.code2TestKeysMap.set('VlogModeView' + '_2', 'VLOG_TOOL_PORTRAIT_FOCUS');
    this.code2TestKeysMap.set('VlogModeView' + '_3', 'VLOG_TOOL_PORTRAIT_BLUR');
    this.code2TestKeysMap.set('VlogModeView' + '_4', 'VLOG_TOOL_AI_COLOR');
  }

  private setOutHomeItem(): void {
    // 外屏设置页选项,SettingOutHome_FunctionId_SettingFuncDialogItemIndex
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.ASPECT_RATIO + '_1', 'COMPONENT_ID_SETTING_OutHome_ITEM_RADIO_0'); // 照片比例选择-选择4:3
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.ASPECT_RATIO + '_2', 'COMPONENT_ID_SETTING_OutHome_ITEM_RADIO_1'); // 照片比例选择-选择1:1
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.VIDEO_RESOLUTION + '_1', 'COMPONENT_ID_SETTING_OutHome_ITEM_RADIO_0'); // 视频分辨率选择-4K
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.VIDEO_RESOLUTION + '_2', 'COMPONENT_ID_SETTING_OutHome_ITEM_RADIO_1'); // 视频分辨率选择-1080P
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.VIDEO_RESOLUTION + '_3', 'COMPONENT_ID_SETTING_OutHome_ITEM_RADIO_2'); // 视频分辨率选择-720p
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.FRAME_RATE + '_1', 'COMPONENT_ID_SETTING_OutHome_ITEM_RADIO_0'); // 视频帧率选择-30fps
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.FRAME_RATE + '_2', 'COMPONENT_ID_SETTING_OutHome_ITEM_RADIO_1'); // 视频帧率选择-60fps
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.TIME_LAPSE + '_1', 'COMPONENT_ID_SETTING_OutHome_ITEM_TIME_OFF'); // 延时拍摄关
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.TIME_LAPSE + '_2', 'COMPONENT_ID_SETTING_OutHome_ITEM_TIME_2S'); // 延时拍摄2s
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.TIME_LAPSE + '_3', 'COMPONENT_ID_SETTING_OutHome_ITEM_TIME_5S'); // 延时拍摄5s
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.TIME_LAPSE + '_4', 'COMPONENT_ID_SETTING_OutHome_ITEM_TIME_10S'); // 延时拍摄10s
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.TIMED_SHOT + '_1', 'COMPONENT_ID_SETTING_OutHome_ITEM_TIMESHOT_OFF'); // 间隔定时拍关
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.TIMED_SHOT + '_2', 'COMPONENT_ID_SETTING_OutHome_ITEM_TIMESHOT_2S'); // 间隔定时拍2s
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.TIMED_SHOT + '_3', 'COMPONENT_ID_SETTING_OutHome_ITEM_TIMESHOT_5S'); // 间隔定时拍5s
    this.code2TestKeysMap.set('SettingOutHome_' + FunctionId.TIMED_SHOT + '_4', 'COMPONENT_ID_SETTING_OutHome_ITEM_TIMESHOT_10S'); // 间隔定时拍10s
  }

  // Component ID
  static readonly SWITCH_CAMERA_1 = 'COMPONENT_ID_SWITCH_CAMERA_1'; // 预览界面-切换
  static readonly VIDEO_RECORDING_1 = 'COMPONENT_ID_VIDEO_RECORDING_1'; // 预览界面-录制中暂停
  static readonly VIDEO_PAUSE_1 = 'COMPONENT_ID_VIDEO_PAUSE_1'; // 预览界面-录制暂停后继续
  static readonly VIDEO_RECORDING_2 = 'COMPONENT_ID_VIDEO_RECORDING_2'; // 预览界面-长按录像中暂停
  static readonly VIDEO_PAUSE_2 = 'COMPONENT_ID_VIDEO_PAUSE_2'; // 预览界面-长按录像暂停后继续
  static readonly SHUTTER_PHOTO_1 = 'COMPONENT_ID_SHUTTER_PHOTO_1'; // 预览界面-快门
  static readonly SHUTTER_VIDEO_1 = 'COMPONENT_ID_SHUTTER_VIDEO_1'; // 预览界面-录制
  static readonly SHUTTER_VIDEO_END_1 = 'COMPONENT_ID_SHUTTER_VIDEO_END_1'; // 预览界面-完成录制
  static readonly SHUTTER_VIDEO_END_2 = 'COMPONENT_ID_SHUTTER_VIDEO_END_2'; // 预览界面-长按录像中完成录制
  static readonly SHUTTER_SUPER_SLOW_1 = 'COMPONENT_ID_SHUTTER_SUPER_SLOW_1'; // 预览界面-超级慢动作
  static readonly FLOATING_SHUTTER_1 = 'COMPONENT_ID_FLOATING_SHUTTER_1'; // 悬浮快门键
  static readonly SHUTTER_PHOTO_2 = 'COMPONENT_ID_SHUTTER_PHOTO_2'; // 预览界面-夜景快门
  static readonly SWITCH_PROFESSION_1 = 'COMPONENT_ID_PRO_PHOTO_OUTPUT_CAMERA_1'; // 专业录像-预览界面-切换
  static readonly SWITCH_PROFESSION_2 = 'COMPONENT_ID_PRO_VIDEO_OUTPUT_CAMERA_2'; // 专业录像-预览界面-切换
  static readonly SHUTTER_TIME_LAPSE = 'COMPONENT_ID_TIME_LAPS'; // 预览界面-延时摄影
  static readonly POPUPBUTTON_1 = 'COMPONENT_ID_POPUPBUTTON_1'; // 预览界面-闪光灯设置
  static readonly FOCUS_ASSIST_LAMP = 'COMPONENT_ID_FOCUS_ASSIST_LAMP'; // 预览界面-闪光灯设置
  static readonly THIRDPARTYCALL_BACK_1 = 'COMPONENT_ID_THIRDPARTYCALL_BACK_1';
  static readonly LEFT_RIGHT_SWIPE_VIDEO_SWIPE_SELECTABLE_ICON =
    'LEFT_RIGHT_SWIPE_VIDEO_SWIPE_SELECTABLE_ICON';// 长按录像待选按钮
  static readonly LEFT_RIGHT_SWIPE_VIDEO_ICON = 'LEFT_RIGHT_SWIPE_VIDEO_ICON';// 长按录像待选按钮图像
  static readonly LEFT_RIGHT_SWIPE_VIDEO_LOCK_ICON = 'LEFT_RIGHT_SWIPE_VIDEO_LOCK_ICON';// 长按录像锁定按钮图像
  static readonly LEFT_RIGHT_SWIPE_BURST_SWIPE_SELECTABLE_ICON =
    'LEFT_RIGHT_SWIPE_BURST_SWIPE_SELECTABLE_ICON';// 长按连拍待选按钮
  static readonly LEFT_RIGHT_SWIPE_BURST_ICON = 'LEFT_RIGHT_SWIPE_BURST_ICON';// 长按连拍待选按钮图像
  static readonly LEFT_RIGHT_SWIPE_RECORD_CAPTURE = 'LEFT_RIGHT_SWIPE_RECORD_CAPTURE';// 长按录像中拍照按钮
  static readonly CAMERA_SETTING_1 = 'COMPONENT_ID_CAMERA_SETTING_1'; // 预览界面-相机设置
  static readonly THUMBNAIL_1 = 'COMPONENT_ID_THUMBNAIL_1'; // 预览界面-缩略图
  static readonly THUMBNAIL_STACK = 'COMPONENT_ID_THUMBNAIL_STACK'; // 预览界面-缩略图
  static readonly THUMBNAIL_STACK_COLUMN = 'COMPONENT_ID_THUMBNAIL_STACK_COLUMN'; // 预览界面-缩略图
  static readonly THUMBNAIL_STACK_COLUMN_ANIMATE = 'COMPONENT_ID_THUMBNAIL_STACK_COLUMN_ANIMATE'; // 预览界面-缩略图
  static readonly PAGE_ROOT_NAV = 'PAGE_ROOT_NAV';
  static readonly PAGE_STACK_14 = 'PAGE_STACK_14';
  static readonly PREVIEW_FOCUSBOX_1 = 'COMPONENT_ID_PREVIEW_FOCUSBOX_1';
  static readonly PREVIEW_FOCUSLOCK_1 = 'COMPONENT_ID_PREVIEW_FOCUSLOCK_1';
  static readonly LONG_TOUCH_PREVIEW_EXPOSURE_1 = 'COMPONENT_ID_LONG_TOUCH_PREVIEW_EXPOSURE_1';
  static readonly THIRDPARTYCALL_REMAKE_1 = 'COMPONENT_ID_THIRDPARTYCALL_REMAKE_1';
  static readonly THIRDPARTYCALL_CONFIRM_1 = 'COMPONENT_ID_THIRDPARTYCALL_CONFIRM_1';
  static readonly PREVIEW_WINDOW_1 = 'COMPONENT_ID_PREVIEW_WINDOW_1';
  static readonly SHUTTER_PHOTO_ON_VIDEO_1 = 'COMPONENT_ID_SHUTTER_PHOTO_ON_VIDEO_1';
  static readonly TIP = 'TIP'; // 提示信息框
  //NavDestination Title Component Id
  static readonly NAV_DESTINATION_TITLE_BACK_1 = 'NAV_DESTINATION_TITLE_BACK_1';
  static readonly NAV_DESTINATION_TITLE_TEXT_1 = 'NAV_DESTINATION_TITLE_TEXT_1';
  // 慢动作相关
  static readonly PREVIEW_SLOW_MOTION_BOX_1 = 'PREVIEW_SLOW_MOTION_BOX_1'; //预览区域运动侦测框
  static readonly SUPPER_SLOW_TOP_TIP = 'SUPPER_SLOW_TOP_TIP';
  static readonly SUPPER_SLOW_BOTTOM_TIP = 'SUPPER_SLOW_BOTTOM_TIP';
  static readonly SUPPER_SLOW_ONCE_TOAST = 'SUPPER_SLOW_ONCE_TOAST';
  // Setting View Component Id
  static readonly SETTING_DEFAULT_BUTTON_TEXT = 'COMPONENT_ID_SETTING_DEFAULT_BUTTON_TEXT_';
  static readonly SETTING_DEFAULT_BUTTON_1 = 'COMPONENT_ID_SETTING_DEFAULT_BUTTON_1'; // 相机设置页-恢复默认设置
  static readonly SETTING_DIALOG_TITLE = 'COMPONENT_ID_SETTING_DIALOG_TITLE_';
  static readonly SETTING_DIALOG_ITEM = 'COMPONENT_ID_SETTING_DIALOG_ITEM_';
  static readonly SETTING_DIALOG_ITEM_DESC = 'COMPONENT_ID_SETTING_DIALOG_ITEM_DESC_';
  static readonly SETTING_DIALOG_ITEM_CANCEL_1 = 'COMPONENT_ID_SETTING_DIALOG_ITEM_CANCEL_1'; // xxx选择弹窗-取消
  static readonly SETTING_DIALOG_CANCEL_TEXT = 'COMPONENT_ID_SETTING_DIALOG_ITEM_CANCEL_TEXT_';
  static readonly SETTING_PERMISSION_TEXT = 'SETTING_PERMISSION_TEXT';
  //zoom view component id
  static readonly QUICK_ZOOM_INDEX = 'QUICK_ZOOM_INDEX_';
  static readonly DEPTH_FUSION_CHOICE_INDEX = 'DEPTH_FUSION_CHOICE_INDEX_';
  static readonly ZOOM_BIG_TEXT = 'ZOOM_BIG_TEXT';
  static readonly EQUIVALENT_FOCAL_BIG_TEXT = 'EQUIVALENT_FOCAL_BIG_TEXT';
  static readonly QUICK_ZOOM_BAR = 'QUICK_ZOOM_BAR';
  static readonly ROULETTE_ZOOM_VIEW_STACK = 'QUICK_ZOOM_BAR_STACK';
  static readonly ROULETTE_ZOOM_VIEW_COLUMN = 'QUICK_ZOOM_BAR_COLUMN';
  static readonly RING_ZOOM_BAR = 'RING_ZOOM_BAR';
  static readonly VIDEO_ZOOM_INCREASES_IMAGE = 'COMPONENT_ID_VIDEO_ZOOM_INCREASES_IMAGE_';
  static readonly VIDEO_ZOOM_SHRINKING_IMAGE = 'COMPONENT_ID_VIDEO_ZOOM_SHRINKING_IMAGE_';
  //Setting restore default
  static readonly SETTING_RESTORE_DEFAULT_CANCEL = 'SETTING_RESTORE_DEFAULT_CANCEL';
  static readonly SETTING_RESTORE_DEFAULT_CONFIRM = 'SETTING_RESTORE_DEFAULT_CONFIRM';
  static readonly SETTING_RESTORE_DEFAULT_CONFIRM_DIALOG = 'SETTING_RESTORE_DEFAULT_CONFIRM_DIALOG';
  static readonly SETTING_RESTORE_DEFAULT_OP_BUTTON = 'SETTING_RESTORE_DEFAULT_OP_BUTTON';
  //PrivacyPolicy view
  static readonly PRIVACY_POLICY_BACK = 'PRIVACY_POLICY_BACK';
  //Horizontal level view
  static readonly HORIZONTAL_LEVEL_PREVIEW_VIEW = 'HORIZONTAL_LEVEL_PREVIEW_VIEW';
  static readonly ASSISTIVE_GRID_VIEW = 'ASSISTIVE_GRID_VIEW';
  //Treasure box view
  static readonly TREASURE_BOX_SECOND_LIST_BACK_BUTTON = 'TREASURE_BOX_SECOND_LIST_BACK_BUTTON';
  static readonly TREASURE_BOX_SECOND_LIST_BACK_BTN = 'TREASURE_BOX_SECOND_LIST_BACK_BTN';
  static readonly TREASURE_BOX_FIRST_LIST = 'TREASURE_BOX_FIRST_LIST';
  static readonly TREASURE_BOX_SECOND_LIST = 'TREASURE_BOX_SECOND_LIST';
  static readonly TREASURE_BOX_ARROW = 'TREASURE_BOX_ARROW';
  //ParamBar
  static readonly PARAM_BAR_PORTRAIT_BEAUTY = 'PARAM_BAR_PORTRAIT_BEAUTY';
  static readonly PARAM_BAR_APERTURE = 'PARAM_BAR_APERTURE';
  static readonly PARAM_BAR_TIME_LAPSE = 'PARAM_BAR_TIME_LAPSE';
  static readonly PARAM_BAR_SLOW_MOTION = 'PARAM_BAR_SLOW_MOTION';
  static readonly PARAM_BAR_SUPER_MACRO = 'PARAM_BAR_SUPER_MACRO';
  static readonly PARAM_BAR_WATCH_MOON = 'PARAM_BAR_WATCH_MOON';
  static readonly PARAM_BAR_VIDEO_TIME_LAPSE = 'PARAM_BAR_VIDEO_TIME_LAPSE';
  static readonly PARAM_BAR_LIGHT_PAINTING = 'PARAM_BAR_LIGHT_PAINTING';
  static readonly PARAM_BAR_EFFECT_SUGGESTION = 'PARAM_BAR_EFFECT_SUGGESTION';
  static readonly PARAM_BAR_PANORAMA_BTN = 'PARAM_BAR_PANORAMA_BTN';
  static readonly PARAM_BAR_LONG_EXPOSURE = 'PARAM_BAR_LONG_EXPOSURE';
  static readonly PARAM_BAR_DEPTH_FUSION = 'PARAM_BAR_DEPTH_FUSION';
  static readonly PARAM_BAR_DEPTH_FUSION_POPUP = 'PARAM_BAR_DEPTH_FUSION_POPUP';
  static readonly PARAM_BAR_STITCHING_TYPE = 'PARAM_BAR_STITCHING_TYPE';
  static readonly PARAM_BAR_STITCHING_DIRECTION = 'PARAM_BAR_STITCHING_DIRECTION';
  static readonly PARAM_BAR_NIGHT_SUB_MODE = 'PARAM_BAR_NIGHT_SUB_MODE';
  static readonly PARAM_BAR_LOG_STYLE_ASSISTANCE_ON = 'PARAM_BAR_LOG_STYLE_ASSISTANCE_ON';
  static readonly PARAM_BAR_LOG_STYLE_ASSISTANCE_OFF = 'PARAM_BAR_LOG_STYLE_ASSISTANCE_OFF';
  // 火龙果popup
  static readonly PARAM_BAR_CUSTOM_FILTER_POPUP = 'PARAM_BAR_CUSTOM_FILTER_POPUP';

  //Intro
  static readonly INTRO_PERMISSION_CANCEL = 'INTRO_PERMISSION_CANCEL';
  static readonly INTRO_PERMISSION_AGREE = 'INTRO_PERMISSION_AGREE';
  static readonly PARAM_BAR_NIGHT_SHUTTER = 'PARAM_BAR_NIGHT_SHUTTER';
  static readonly PARAM_BAR_PANORAMA_ROTATION = 'PARAM_BAR_PANORAMA_ROTATION';
  //WatermarkView
  static readonly WATERMARK_VIEW_BACK = 'WATERMARK_VIEW_BACK';
  static readonly WATERMARK_VIEW_OPEN_TOGGLE = 'WATERMARK_VIEW_OPEN_TOGGLE';
  //pipStatus
  static readonly PIP_CLICK_CLOSE = 'PIP_CLICK_CLOSE';
  static readonly PIP_CLICK_BIG = 'PIP_CLICK_BIG';
  //moreModeIndex
  static readonly COMPONENT_ID_MOREMODE_CANCEL = 'COMPONENT_ID_MOREMODE_CANCEL'; // 更多页面取消按钮
  static readonly COMPONENT_ID_MOREMODE_EDIT = 'COMPONENT_ID_MOREMODE_EDIT'; // 更多页面编辑按钮
  static readonly COMPONENT_ID_MOREMODE_SUMBIT = 'COMPONENT_ID_MOREMODE_SUMBIT'; // 更多编辑页提交按钮
  static readonly COMPONENT_ID_MOREMODE_DEFAULT = 'COMPONENT_ID_MOREMODE_DEFAULT'; // 更多编辑页提交按钮
  static readonly COMPONENT_ID_MOREMODE_HIGH_RES = 'HIGH-RES'; // 更多编辑页提交按钮
  static readonly COMPONENT_ID_MOREMODE_SLOW_MO = 'SLOW-MO'; // 更多编辑页提交按钮
  static readonly COMPONENT_ID_MOREMODE_APERTURE = 'APERTURE'; // 更多编辑页提交按钮
  static readonly COMPONENT_ID_MOREMODE_TIMELAPSE = 'TIME-LAPSE'; // 更多编辑页提交按钮
  static readonly COMPONENT_ID_MOREMODE_LIGHT_PAINTING = 'LIGHT PAINTING'; // 更多编辑页提交按钮
  static readonly COMPONENT_ID_MOREMODE_SUPER_MACRO = 'SUPER MACRO'; // 更多编辑页提交按钮
  static readonly COMPONENT_ID_MOREMODE_PANORAMA = 'PANORAMA'; // 更多编辑页提交按钮
  // Aperture
  static readonly APERTURE_SLIDER_CANVAS = 'APERTURE_SLIDER_CANVAS'; // 大光圈刻度条
  // RealTimeLapse
  static readonly TIMELAPSE_INTERVAL_SLIDER_CANVAS = 'TIMELAPSE_INTERVAL_SLIDER_CANVAS'; // 延时摄影速率调节刻度条
  static readonly TIMELAPSE_DURATION_SLIDER_CANVAS = 'TIMELAPSE_DURATION_SLIDER_CANVAS'; // 延时摄影录制时长调节刻度条
  // 省电模式
  static readonly SAVE_POWER_MODE_VIEW = 'SAVE_POWER_MODE_VIEW'; // 省电模式组件
  // 超级微距模式对焦刻度条
  static readonly MACRO_SLIDER_CANVAS = 'MACRO_SLIDER_CANVAS';
  static readonly MACRO_SWITCH_BUTTON = 'MACRO_SWITCH_BUTTON'; // 超级微距模式 拍照/录像 切换按钮
  static readonly MACRO_FOCUS_BAR_AUTO = 'MACRO_FOCUS_BAR_AUTO';
  static readonly MACRO_SLIDER_RED_LINE = 'MACRO_SLIDER_RED_LINE';
  static readonly MACRO_SLIDER_FAR = 'MACRO_SLIDER_FAR';
  static readonly MACRO_SLIDER_NEAR = 'MACRO_SLIDER_NEAR';
  //引导页
  static readonly MODE_DETAIL_HORIZONTAL_CARD_TITLE = 'MODE_DETAIL_HORIZONTAL_CARD_TITLE';
  static readonly MODE_DETAIL_HORIZONTAL_CARD_CONTENT = 'MODE_DETAIL_HORIZONTAL_CARD_CONTENT';
  static readonly MODE_DETAIL_HORIZONTAL_CARD = 'MODE_DETAIL_HORIZONTAL_CARD';
  static readonly MODE_DETAIL_HORIZONTAL_CARD_CANCEL_BTN = 'MODE_DETAIL_HORIZONTAL_CARD_CANCEL_BTN';
  static readonly MODE_DETAIL_VERTICAL_CARD_TITLE = 'MODE_DETAIL_VERTICAL_CARD_TITLE';
  static readonly MODE_DETAIL_VERTICAL_CARD_CONTENT_1 = 'MODE_DETAIL_VERTICAL_CARD_CONTENT_1';
  static readonly MODE_DETAIL_VERTICAL_CARD_CONTENT_2 = 'MODE_DETAIL_VERTICAL_CARD_CONTENT_2';
  static readonly MODE_DETAIL_VERTICAL_CARD = 'MODE_DETAIL_VERTICAL_CARD';
  static readonly MODE_DETAIL_VERTICAL_CARD_MORE_BTN = 'MODE_DETAIL_VERTICAL_CARD_MORE_BTN';
  static readonly MODE_DETAIL_VERTICAL_CARD_CANCEL_BTN = 'MODE_DETAIL_VERTICAL_CARD_CANCEL_BTN';
  static readonly MODE_DESC_VERTICAL_CARD_TITLE = 'MODE_DESC_VERTICAL_CARD_TITLE';
  static readonly MODE_DESC_VERTICAL_CARD_CONTENT = 'MODE_DESC_VERTICAL_CARD_CONTENT';
  static readonly MODE_DESC_VERTICAL_CARD_IMG = 'MODE_DESC_VERTICAL_CARD_IMG';
  static readonly MODE_DESC_VERTICAL_CARD_MORE_BTN = 'MODE_DESC_VERTICAL_CARD_MORE_BTN';
  static readonly MODE_DESC_VERTICAL_CARD_CANCEL_BTN = 'MODE_DESC_VERTICAL_CARD_CANCEL_BTN';
  static readonly MODE_DETAIL_ENTRY = 'MODE_DETAIL_ENTRY';
  static readonly STARTUP_GUIDANCE_TITLE = 'STARTUP_GUIDANCE_TITLE';
  static readonly STARTUP_GUIDANCE_CONTENT = 'STARTUP_GUIDANCE_CONTENT';
  static readonly STARTUP_GUIDANCE_IMG = 'STARTUP_GUIDANCE_IMG';
  static readonly STARTUP_GUIDANCE_BTN = 'STARTUP_GUIDANCE_BTN';
  static readonly STARTUP_GUIDANCE_VIDEO = 'STARTUP_GUIDANCE_VIDEO';
  //picker隐私横幅
  static readonly PICKER_PRIVACY_BANNER = 'PICKER_PRIVACY_BANNER';
  static readonly PICKER_PRIVACY_BANNER_BUTTON = 'PICKER_PRIVACY_BANNER_BUTTON';
  // 流光快门闪光灯弹窗
  static readonly LIGHT_PAINTING_VERTICAL_DIALOG_BUTTON = 'LIGHT_PAINTING_VERTICAL_DIALOG_BUTTON';
  static readonly LIGHT_PAINTING_HORIZONTAL_DIALOG_BUTTON = 'LIGHT_PAINTING_HORIZONTAL_DIALOG_BUTTON';
  static readonly LIGHT_PAINTING_LANDSCAPE_DIALOG_BUTTON = 'LIGHT_PAINTING_LANDSCAPE_DIALOG_BUTTON';
  //TabBar
  static readonly TABBAR_VIEW = 'TABBAR_VIEW';
  // METERING
  static readonly METERING_MODE_VIEW = 'METERING_MODE_VIEW';
  // ISO
  static readonly ISO_EFFECT_VIEW = 'ISO_EFFECT_VIEW';
  // PHYSICAL_APERTURE_VIEW
  static readonly PHYSICAL_APERTURE_VIEW = 'PHYSICAL_APERTURE_VIEW';
  // s
  static readonly PROFESSION_SHUTTER_EFFECT_VIEW = 'PROFESSION_SHUTTER_EFFECT_VIEW';
  // ExposureBarView
  static readonly EXPOSURE_BAR_VIEW = 'EXPOSURE_BAR_VIEW';
  static readonly EXPOSURE_BAR_POPUP_VIEW = 'EXPOSURE_BAR_POPUP_VIEW';
  // FOCUS_MODE_VIEW
  static readonly FOCUS_MODE_VIEW = 'FOCUS_MODE_VIEW';
  // WHITE_BALANCE_VIEW
  static readonly WHITE_BALANCE_VIEW = 'WHITE_BALANCE_VIEW';
  // PROFESSION_BAR_VIEW
  static readonly PROFESSION_BAR_VIEW = 'PROFESSION_BAR_VIEW';
  // WhITE_BALANCE_EFFECT_VIEW
  static readonly WhITE_BALANCE_EFFECT_VIEW = 'WhITE_BALANCE_EFFECT_VIEW';
  // 前后置摄像头
  static readonly IS_FRONT_CAMERA = 'cameraPosition:2';
  static readonly IS_BACK_CAMERA = 'cameraPosition:1';
  // 美颜弹窗PortraitBeautyDialog
  static readonly SHOW_PORTRAIT_DIALOG = 'SHOW_PORTRAIT_DIALOG';
  static readonly RADIO_OPEN_PORTRAIT_BEAUTY = 'RADIO_OPEN_PORTRAIT_BEAUTY';
  static readonly RADIO_CLOSE_PORTRAIT_BEAUTY = 'RADIO_CLOSE_PORTRAIT_BEAUTY';
  static readonly BUTTON_CONFIRM_PORTRAIT_BEAUTY = 'BUTTON_CONFIRM_PORTRAIT_BEAUTY';
  //RequestLocationDialog
  static readonly LOCATION_DIALOG_ACCESS = 'LOCATION_DIALOG_ACCESS';
  static readonly LOCATION_DIALOG_CANCEL = 'LOCATION_DIALOG_CANCEL';
  // Stitching Mode
  static readonly STITCHING_BASE_CIRCLE_WHITE = 'STITCHING_BASE_CIRCLE_WHITE';
  static readonly STITCHING_BASE_CIRCLE_YELLOW = 'STITCHING_BASE_CIRCLE_YELLOW';
  static readonly STITCHING_BASE_VIEW = 'STITCHING_BASE_VIEW';
  static readonly STITCHING_PHOTO_BAR_LONG = 'STITCHING_PHOTO_BAR_LONG';
  static readonly STITCHING_PHOTO_BAR_PAINT = 'STITCHING_PHOTO_BAR_PAINT';
  static readonly STITCHING_PHOTO_BAR_NINE = 'STITCHING_PHOTO_BAR_NINE';
  static readonly STITCHING_TARGET_A_WHITE = 'STITCHING_TARGET_A_WHITE';
  static readonly STITCHING_TARGET_A_YELLOW = 'STITCHING_TARGET_A_YELLOW';
  static readonly STITCHING_TARGET_B_WHITE = 'STITCHING_TARGET_B_WHITE';
  static readonly STITCHING_ARROW_A_WHITE = 'STITCHING_ARROW_A_WHITE';
  static readonly STITCHING_ARROW_A_YELLOW = 'STITCHING_ARROW_A_YELLOW';
  static readonly STITCHING_ARROW_B_WHITE = 'STITCHING_ARROW_B_WHITE';
  static readonly STITCHING_ARROW_B_YELLOW = 'STITCHING_ARROW_B_YELLOW';
  static readonly STITCHING_TYPE_LONG = 'STITCHING_TYPE_LONG';
  static readonly STITCHING_TYPE_PAINT = 'STITCHING_TYPE_PAINT';
  static readonly STITCHING_TYPE_NINE = 'STITCHING_TYPE_NINE';

  static readonly GLOBAL_EXPOSURE_BAR_VIEW = 'GLOBAL_EXPOSURE_BAR_VIEW';
  static readonly PORTRAIT_BEAUTY_COMPARE_SWITCH = 'PORTRAIT_BEAUTY_COMPARE_SWITCH';

  // FootBar
  static readonly FOOT_BAR_STACK = 'FOOT_BAR_STACK';
  static readonly FOOT_BAR_COLUMN = 'FOOT_BAR_COLUMN';

  // ShutterButton
  static readonly SHUTTER_BUTTON_NORMAL_OUT_BTN = 'SHUTTER_BUTTON_NORMAL_OUT_BTN';
  static readonly SHUTTER_BUTTON_NIGHT_INNER_BTN = 'SHUTTER_BUTTON_NIGHT_INNER_BTN';
  static readonly SHUTTER_BUTTON_PANORAMA_INNER_BTN = 'SHUTTER_BUTTON_PANORAMA_INNER_BTN';
  static readonly SHUTTER_BUTTON_STITCHING_INNER_BTN = 'SHUTTER_BUTTON_STITCHING_INNER_BTN';
  static readonly SHUTTER_BUTTON_PHOTO_INNER_BTN = 'SHUTTER_BUTTON_PHOTO_INNER_BTN';
  static readonly SHUTTER_BUTTON_STACK = 'SHUTTER_BUTTON_STACK';
  // 魔镜设置页
  static readonly MIRROR_SELFIE_SETTING_VIEW = 'MIRROR_SELFIE_SETTING_VIEW';
  // paramBar夜景子模式popup
  static readonly NIGHT_SUBMODE_VIEW_POPUP = 'NIGHT_SUBMODE_VIEW_POPUP';
  //Vlog arrow button
  static readonly VLOG_ARROW_BUTTON = 'VLOG_ARROW_BUTTON';
}