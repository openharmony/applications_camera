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
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { display } from '@kit.ArkUI';
import lazy { DisplayService } from '../UIAdaptive/DisplayService';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import lazy { getStates } from '../../redux';
import window from '@ohos.window';

/* instrument ignore file */
const TAG: string = 'DirectionCorrectionService';

const directionArrTopBottomPortrait: WindowDirection[] =
  [WindowDirection.TOP, WindowDirection.BOTTOM, WindowDirection.RIGHT, WindowDirection.LEFT];
const directionArrTopBottomPortraitInverted: WindowDirection[] =
  [WindowDirection.BOTTOM, WindowDirection.TOP, WindowDirection.LEFT, WindowDirection.RIGHT];
const directionArrLeftRightLandscape: WindowDirection[] =
  [WindowDirection.TOP, WindowDirection.BOTTOM, WindowDirection.RIGHT, WindowDirection.LEFT];
const directionArrLeftRightLandscapeInverted: WindowDirection[] =
  [WindowDirection.BOTTOM, WindowDirection.TOP, WindowDirection.LEFT, WindowDirection.RIGHT];
const sameDirectionArr: WindowDirection[] =
  [WindowDirection.LEFT, WindowDirection.RIGHT, WindowDirection.TOP, WindowDirection.BOTTOM];
const invertedDirectionArr: WindowDirection[] =
  [WindowDirection.RIGHT, WindowDirection.LEFT, WindowDirection.BOTTOM, WindowDirection.TOP];

export const HORIZONTAL_PREVIEW_DIRECTION_CORRECTION_ARR: WindowDirection[][] =
  [directionArrTopBottomPortrait, directionArrLeftRightLandscape, directionArrTopBottomPortraitInverted,
    directionArrLeftRightLandscapeInverted];

export const VERTICAL_PREVIEW_DIRECTION_CORRECTION_ARR: WindowDirection[][] =
  [sameDirectionArr, invertedDirectionArr, invertedDirectionArr, sameDirectionArr];

export const LAND_HORIZONTAL_SPLIT_DIRECTION_CORRECTION_ARR: WindowDirection[][] =
  [sameDirectionArr, directionArrLeftRightLandscape, sameDirectionArr, directionArrTopBottomPortraitInverted];

export const LANDSCAPE_ORIENTATION_TO_DIRECTION: WindowDirection[] = [WindowDirection.TOP, WindowDirection.LEFT,
  WindowDirection.BOTTOM, WindowDirection.RIGHT];

export const GRL_FULL_DIRECTION_CORRECTION_ARR: WindowDirection[][] =
  [directionArrLeftRightLandscape, invertedDirectionArr, directionArrTopBottomPortraitInverted, sameDirectionArr];

export class DirectionCorrectionService {

  public static directionCorrection(inputDirection: WindowDirection, isLockRotation: boolean,
    orientation?: display.Orientation): WindowDirection {
    if (DeviceInfo.isPc()) {
      return inputDirection;
    }
    let windowStatus: window.WindowStatusType =
      getStates().get<window.WindowStatusType>('windowReducer', 'windowStatus');
    orientation = orientation ?? DisplayService.getInstance().getDisplay().orientation;
    if (DeviceInfo.isTablet()) {
      if (!isLockRotation) {
        return WindowDirection.TOP;
      }
      if (PickerUtils.getIsTabletTopBottomSplitScreenFromReducer() ||
      PickerUtils.getIsTabletVerticalFullScreenFromReducer()) {
        return VERTICAL_PREVIEW_DIRECTION_CORRECTION_ARR[orientation][inputDirection as number];
      } else if (PickerUtils.getIsTabletLeftRightSplitScreenFromReducer() ||
      PickerUtils.getIsTabletHorizontalFullScreenFromReducer() || PickerUtils.getIsTabletInFreeWindowFromReducer()) {
        return LAND_HORIZONTAL_SPLIT_DIRECTION_CORRECTION_ARR[orientation][inputDirection as number];
      }
      if (!DisplayService.getInstance().isOrientationVertical()) {
        return LAND_HORIZONTAL_SPLIT_DIRECTION_CORRECTION_ARR[orientation][inputDirection as number];
      }
    }
    return this.directionCorrectionForTriCollaps(false, inputDirection, isLockRotation, orientation);
  }

  private static directionCorrectionForTriCollaps(isShowTricollaps: boolean, inputDirection: WindowDirection,
    isLockRotation: boolean, orientation?: display.Orientation): WindowDirection{
    if (isShowTricollaps && isLockRotation) {
      return GRL_FULL_DIRECTION_CORRECTION_ARR[orientation][inputDirection as number];
    } else if (PickerUtils.getIsPicker() && isShowTricollaps && !isLockRotation) {
      return WindowDirection.TOP;
    } else {
      return this.getPickerOrDefaultDirection(inputDirection, orientation);
    }
  }

  public static getPickerOrDefaultDirection(
    inputDirection: WindowDirection, orientation?: display.Orientation): WindowDirection {
    if (PickerUtils.getIsCollapsedHorizontalFullScreenFromReducer()) {
      const orientation: display.Orientation = DisplayService.getInstance().getDisplay().orientation;
      return orientation === display.Orientation.LANDSCAPE ? WindowDirection.LEFT : WindowDirection.RIGHT;
    }
    if (PickerUtils.getIsExpandedHorizontalPreviewSize()) {
      return HORIZONTAL_PREVIEW_DIRECTION_CORRECTION_ARR[orientation][inputDirection as number];
    } else if (PickerUtils.getIsExpandedVerticalPreviewSize()) {
      return VERTICAL_PREVIEW_DIRECTION_CORRECTION_ARR[orientation][inputDirection as number];
    }
    return inputDirection;
  }
}