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
export class ZoomParam {
  // 无含义数字常量
  public static readonly TWO: number = 2;
  public static readonly THREE: number = 3;
  public static readonly FOUR: number = 4;
  public static readonly SIX: number = 6;
  public static readonly NINE: number = 9;
  public static readonly TEN: number = 10;
  public static readonly FOURTEEN: number = 14;
  public static readonly TWENTY_FIVE: number = 25;
  public static readonly ONE_HUNDRED: number = 100;
  public static readonly ONE_HUNDRED_AND_TEN: number = 110;
  public static readonly ONE_HUNDRED_AND_EIGHTY: number = 180;
  public static readonly THREE_HUNDRED_AND_SIXTY: number = 360;

  // 扇形变焦常量
  public static readonly LANDSCAPE_ZOOM_WIDTH: number = 412;
  public static readonly SEMI_COLLAPS_ZOOM_WIDTH: number = 308;
  public static readonly SCALE_GAP_ANGLE = 1.6;
  public static readonly RING_LOW_DYNAMIC_FOLLOW_UP_RATE: number = 0.1576; // 极限焦距场景动态跟手率e^(-1.848)
  public static readonly THROW_SLIDE_TRIGGER_VELOCITY: number = 200; // 触发抛滑阈值
  public static readonly THROW_SLIDE_UPPER_VELOCITY: number = 1500; // 直接触发抛滑上限

  // 变焦值
  public static readonly QUICK_ZOOM_0_49: number = 0.49;
  public static readonly QUICK_ZOOM_0_67: number = 0.67;
  public static readonly QUICK_ZOOM_0_8: number = 0.8;
  public static readonly QUICK_ZOOM_1: number = 1;
  public static readonly QUICK_ZOOM_2: number = 2;
  public static readonly QUICK_ZOOM_3: number = 3;
  public static readonly QUICK_ZOOM_3_5: number = 3.5;
  public static readonly QUICK_ZOOM_10: number = 10;
  public static readonly QUICK_ZOOM_5: number = 5;
  public static readonly QUICK_ZOOM_4: number = 4;
  public static readonly QUICK_ZOOM_5_5: number = 5.5;
  public static readonly QUICK_ZOOM_6: number = 6;
  public static readonly QUICK_ZOOM_100: number = 100;
  public static readonly QUICK_ZOOM_50: number = 50;
  public static readonly QUICK_ZOOM_20: number = 20;
  public static readonly QUICK_ZOOM_30: number = 30;
  public static readonly QUICK_ZOOM_15: number = 15;
  public static readonly QUICK_ZOOM_9: number = 9;
  public static readonly QUICK_ZOOM_14: number = 14;
  public static readonly QUICK_ZOOM_25: number = 25;
  public static readonly QUICK_ZOOM_35: number = 35;

  // 动效时长常量
  public static readonly DURATION_100: number = 100;
  public static readonly DURATION_150: number = 150;
  public static readonly DURATION_200: number = 200;
  public static readonly DURATION_250: number = 250;
  public static readonly DURATION_300: number = 300;
  public static readonly DURATION_350: number = 350;
  public static readonly DURATION_450: number = 450;
  public static readonly DURATION_500: number = 500;
  public static readonly DURATION_750: number = 750;
  public static readonly DURATION_1500: number = 1500;
  public static readonly DURATION_2000: number = 2000;

  // 若可能短时间内同时下发prepareZoom和unprepareZoom时，需在unprepareZoom处添加延时
  public static readonly UNPREPARE_DELAY_TIME: number = 100;
}

export interface ZoomPointInfo {
  readonly zoomRatio: number;
  readonly equivalentFocalLength: number;
}
