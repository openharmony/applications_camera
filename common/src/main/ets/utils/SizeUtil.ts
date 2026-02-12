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
import display from '@ohos.display';
import lazy { HiLog } from './HiLog';
import lazy { DisplayService } from '../service/UIAdaptive/DisplayService';
import lazy { getStates } from '../redux';

/* instrument ignore file */

const TAG = 'SizeUtil';

/**
 * 大小/尺寸计算工具类
 *
 */
export class SizeUtil {
  public static readonly RATIO_TOLERANCE: number = 0.015;
  public static readonly RATIO_4TO3: number = 4 / 3;
  public static readonly RATIO_1TO1: number = 1;
  public static readonly RATIO_16To9: number = 16 / 9;

  public static is4To3Size(width: number, height: number): boolean {
    if (width < 0 || height < 0) {
      return false;
    }
    if (height > width) {
      return Math.abs((height / width) - this.RATIO_4TO3) <= this.RATIO_TOLERANCE;
    }
    return Math.abs((width / height) - this.RATIO_4TO3) <= this.RATIO_TOLERANCE;
  }

  public static is1To1Size(width: number, height: number): boolean {
    if (width < 0 || height < 0) {
      return false;
    }
    if (height > width) {
      return Math.abs((height / width) - this.RATIO_1TO1) <= this.RATIO_TOLERANCE;
    }
    return Math.abs((width / height) - this.RATIO_1TO1) <= this.RATIO_TOLERANCE;
  }

  public static is16To9Size(width: number, height: number): boolean {
    if (width < 0 || height < 0) {
      return false;
    }
    if (height > width) {
      return Math.abs((height / width) - this.RATIO_16To9) <= this.RATIO_TOLERANCE;
    }
    return Math.abs((width / height) - this.RATIO_16To9) <= this.RATIO_TOLERANCE;
  }

  public static isFullScreenSize(width: number, height: number): boolean {
    if (width < 0 || height < 0) {
      return false;
    }
    if (height > width) {
      return Math.abs((height / width) - this.getFullScreenRadio()) <= this.RATIO_TOLERANCE;
    }
    return Math.abs((width / height) - this.getFullScreenRadio()) <= this.RATIO_TOLERANCE;
  }

  public static getSizeRatio(width: number, height: number): number {
    if (width < 0 || height < 0) {
      return 0;
    }
    if (height > width) {
      return height / width;
    }
    return width / height;
  }

  private static getFullScreenRadio(): number {
    const width = getStates().get<number>('windowReducer', 'windowWidth');
    const height = getStates().get<number>('windowReducer', 'windowHeight');
    HiLog.i(TAG, `getFullScreenRadio width: ${width}, height: ${height}`);
    if (width > height) {
      return width / height;
    }
    return height / width;
  }
}