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
/* instrument ignore file */
export class CommonConstants {
  public static readonly BUNDLE_NAME = 'com.ohos.camera';
  /**
   * 系统字体大小分级
   */
  public static readonly TEXT_SIZE_SMALL: number = 0.85;
  public static readonly TEXT_SIZE_NORMAL: number = 1;
  public static readonly TEXT_SIZE_LARGE: number = 1.15;
  public static readonly TEXT_SIZE_EXTRA_LARGE: number = 1.3;
  public static readonly TEXT_SIZE_HUGE: number = 1.45;
  public static readonly TEXT_SIZE_HUGE_LEVEL2: number = 1.75;
  public static readonly TEXT_SIZE_HUGE_LEVEL3: number = 2;
  public static readonly TEXT_SIZE_HUGE_LEVEL4: number = 3.2;

  // 适老化规范 列表padding值
  public static readonly VERTICAL_PADDING: number = 16;
  public static readonly VERTICAL_PADDING_IN_TEXT_SIZE_HUGE_LEVEL3: number = 20;
  public static readonly VERTICAL_PADDING_IN_TEXT_SIZE_HUGE_LEVEL4: number = 24;

  public static readonly HEIGHT_AI_BAR: number = 28;
  public static readonly DEFAULT_VERTICAL_SIGNAL_BAR: number = 36;
  public static readonly SIGNAL_BAR_AND_AI_BAR_HEIGHT = 64;
  public static readonly DIALOG_REDUCTION_RATIO: number = 0.9;

  public static readonly LONG_PRESS_TIME = 500;

  //无障碍重要性接口参数
  public static readonly ACCESSIBILITY_LEVEL_NO = 'no';
  public static readonly ACCESSIBILITY_LEVEL_YES = 'yes';
  public static readonly ACCESSIBILITY_LEVEL_AUTO = 'auto';
  public static readonly ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS = 'no-hide-descendants';
  public static readonly FILE_PATH_PHOTO = 'file://media/Photo';
  public static readonly FILE_PATH_AUDIO = 'file://media/Audio';

  public static readonly TYPE_DEFAULT = 0;
  public static readonly TYPE_REALTIMEFILTER = 1;
  public static readonly TYPE_LRSWIPE_PHOTO = 2;
  public static readonly TYPE_LRSWIPE_OTHER = 3;

  public static readonly EXPOSURE_ICON_SIZE: number = 20;
  public static readonly NUMBER_TWO: number = 2;
  public static readonly EXPOSURE_POSITION_Y_1: number = 135;
  public static readonly EXPOSURE_POSITION_Y_2: number = 16;
  public static readonly EXPOSURE_POSITION_Y_3: number = 60;
  public static readonly EXPOSURE_POSITION_Y_4: number = 104;
  public static readonly EXPOSURE_POSITION_Y_5: number = 112; // VDE、LEM、PSD 悬停态下恢复曝光按钮在Y方向上的位置
  public static readonly EXPOSURE_POSITION_Y_6: number = 10; // 修正VDE 展开态下恢复曝光按钮在Y方向上的位置
  public static readonly WINDOW_WIDTH: number = 344;
  public static readonly EXPOSURE_POSITION_X_1: number = 45;
  public static readonly EXPOSURE_POSITION_X_2: number = 26;
  public static readonly EXPOSURE_POSITION_X_3: number = 59;
  public static readonly EXPOSURE_POSITION_X_4: number = 41;
  public static readonly EXPOSURE_POSITION_X_5: number = 24;
  public static readonly EXPOSURE_POSITION_X_6: number = 34;
  public static readonly EXPOSURE_POSITION_X_7: number = 374;
  public static readonly EXPOSURE_POSITION_X_8: number = 45; // 修正LEM、PSD 悬停态下恢复曝光按钮在X方向上的位置
  public static readonly EXPOSURE_POSITION_X_9: number = 126; // 修正LEM、PSD 悬停态下恢复曝光按钮在X方向上的位置

  public static readonly INVALID_ID: number = -1;

  /**
   * 根据字体倍数获取对应padding数据
   */
  public static getListItemVerticalPadding(fontSizeScale: number): number {
    switch (fontSizeScale) {
      case CommonConstants.TEXT_SIZE_HUGE_LEVEL4:
        return CommonConstants.VERTICAL_PADDING_IN_TEXT_SIZE_HUGE_LEVEL4;
      case CommonConstants.TEXT_SIZE_HUGE_LEVEL3:
        return CommonConstants.VERTICAL_PADDING_IN_TEXT_SIZE_HUGE_LEVEL3;
      default:
        return CommonConstants.VERTICAL_PADDING;
    }
  }
}