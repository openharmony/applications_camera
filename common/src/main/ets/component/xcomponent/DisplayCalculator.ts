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

import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import deviceInfoMessage from '@ohos.deviceInfo';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import display from '@ohos.display';
import lazy { WindowService } from '../../service/window/WindowService';
import window from '@ohos.window';
import lazy { getStates } from '../../redux';
import lazy { JSON } from '@kit.ArkTS';

/* instrument ignore next */
const TAG: string = 'DisplayCalculator';
const SCREEN_WIDTH: number = 16;
const SCREEN_WIDTH_0: number = 0;

export class DisplayCalculator {
  public static readonly windowWidthSpace: number = deviceInfoMessage.productSeries === 'NOH' ? SCREEN_WIDTH : SCREEN_WIDTH_0;

  public static calcSurfaceDisplaySize(ratio: number, windowWidth?: number, windowHeight?: number,
    orientationVertical?: boolean): {
    width: number,
    height: number
  } {
    const size = {
      width: 1920, height: 1080
    };
    HiLog.d(TAG, `calcSurfaceDisplaySize, ratio: ${ratio}.`);
    const isShowDefault: boolean = getStates().get<boolean>('collapsReducer', 'isShowDefault');
    windowWidth = windowWidth || getStates().get<number>('windowReducer', 'windowWidth');
    windowHeight = windowHeight || getStates().get<number>('windowReducer', 'windowHeight');
    /* instrument ignore if*/
    if (this.isHorizontalPreview(windowWidth, windowHeight, orientationVertical)) {
      if (windowWidth / windowHeight > ratio) {
        size.width = windowHeight * ratio;
        size.height = windowHeight;
      } else {
        size.width = windowWidth;
        size.height = windowWidth / ratio;
      }
    } else {
      /* instrument ignore if */
      if (windowWidth / windowHeight > 1 / ratio) {
        size.width = windowHeight / ratio;
        size.height = windowHeight;
      } else {
        size.width = windowWidth - DisplayCalculator.windowWidthSpace;
        size.height = (windowWidth - DisplayCalculator.windowWidthSpace) * ratio;
      }
    }
    return this.calcPreviewSize(size.width, size.height);
  }

  private static calcPreviewSize(wth: number, hgt: number): {
    width: number,
    height: number
  } {
    const previewSize = {
      width: px2vp((Math.floor(vp2px(wth)) >> 1) << 1),
      height: px2vp((Math.floor(vp2px(hgt)) >> 1) << 1),
    };
    return previewSize;
  }
  /* instrument ignore next */
  private static isHorizontalPreview(windowWidth: number, windowHeight: number,
    orientationVertical?: boolean): boolean {
    // 此处 return true，则预览框尺寸的宽度始终大于等于高度
    if (DeviceInfo.isTv()) {
      return !orientationVertical;
    }
    const isShowTricollaps: boolean = getStates().get<boolean>('collapsReducer', 'isShowTricollaps');
    if (isShowTricollaps) {
      return windowWidth > windowHeight ? false : true;
    }
    if (PickerUtils.getIsPicker()) {
      const isOrientationVertical: boolean =
        orientationVertical ?? DisplayService.getInstance().isOrientationVertical();
      if (PickerUtils.getIsExpandedTopBottomSplitScreenFromReducer()) {
        return isOrientationVertical;
      }
      return !isOrientationVertical;
    }
    const status: window.WindowStatusType = WindowService.getInstance().getWindowStatus();
    if (status === window.WindowStatusType.FLOATING && DisplayService.getInstance().isHorizontal()) {
      return true;
    }
    const isShowDefault: boolean = getStates().get<boolean>('collapsReducer', 'isShowDefault');
    return (DeviceInfo.isPc()) || (!DeviceInfo.isPc() && windowWidth > windowHeight ||
      (isShowDefault  && DisplayService.getInstance().isHorizontal()));
  }
}