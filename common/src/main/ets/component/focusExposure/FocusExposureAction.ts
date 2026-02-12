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

import type { ActionData } from '../../redux/actions/Action';
import type { PositionType } from '../../utils/types';
import lazy { FocusData, ExposureData, LockLevel } from './FocusExposureHelper';
import lazy { FocusExposureActionType } from '../../redux/actions/FocusExposureActionType';

const TAG: string = 'FocusExposureAction';

export class PreviewAreaPosition {
  x;
  y;
  width;
  height;
}

export class FocusExposureAction {
  public static readonly FOCUS_POSITION_40: number = 40;
  public static readonly FOCUS_POSITION_80: number = 80;

  public static changeFocusData(focusValue: FocusData): ActionData {
    return {
      isEvent: true,
      type: FocusExposureActionType.ACTION_CHANGE_FOCUS_DATA,
      data: { focusMode: focusValue.focusMode, focusPoint: focusValue.focusPoint, focusValue: focusValue.focusValue }
    };
  }

  public static smartControlLock(smartControlLocked: boolean): ActionData {
    return {
      isEvent: true,
      type: FocusExposureActionType.ACTION_SMART_CONTROL_LOCK,
      data: { smartControlLocked: smartControlLocked }
    };
  }

  public static resetSmartControlLocked(): ActionData {
    return {
      isEvent: true,
      type: FocusExposureActionType.ACTION_RESET_SMART_CONTROL_LOCK,
      data: {}
    };
  }

  public static hideFocus(): ActionData {
    return {
      isEvent: true,
      type: FocusExposureActionType.ACTION_HIDE_FOCUS_BOX,
      data: {}
    };
  }

  public static setMeteringPoint(exposurePoint: PositionType): ActionData {
    return {
      isEvent: true,
      type: FocusExposureActionType.SET_METERING_POINT,
      data: { exposurePoint: exposurePoint }
    };
  }

  public static updateShowExposureRing(isShowExposureRing: boolean): ActionData {
    return {
      isEvent: true,
      type: FocusExposureActionType.ACTION_UPDATE_SHOW_EXPOSURE_RING,
      data: { isShowExposureRing: isShowExposureRing }
    };
  }

  public static setFocusMode(focusValue: FocusData): ActionData {
    return {
      isEvent: true,
      type: FocusExposureActionType.ACTION_SET_FOCUS_MODE,
      data: { focusMode: focusValue.focusMode, focusPoint: focusValue.focusPoint, focusValue: focusValue.focusValue }
    };
  }

  public static updateShowFocus(isShowFocus: boolean): ActionData {
    return {
      type: FocusExposureActionType.ACTION_UPDATE_SHOW_FOCUS,
      data: { isShowFocus: isShowFocus },
      isEvent: true,
    };
  }

  public static changeExposureData(exposureData: ExposureData): ActionData {
    return {
      isEvent: true,
      type: FocusExposureActionType.ACTION_CHANGE_EXPOSURE_DATA,
      data: { ...exposureData }
    };
  }

  public static updateShowExposure(isShowExposure: boolean): ActionData {
    return {
      type: FocusExposureActionType.ACTION_UPDATE_SHOW_EXPOSURE,
      data: { isShowExposure: isShowExposure }
    };
  }

  public static updateLockLevel(lockLevel: LockLevel): ActionData {
    return {
      type: FocusExposureActionType.ACTION_UPDATE_LOCK_LEVEL,
      data: { lockLevel: lockLevel }
    };
  }

  public static updateFocusStateDetectSupported(isSupportedFocusStateDetect: boolean): ActionData {
    return {
      type: FocusExposureActionType.ACTION_UPDATE_FOCUS_STATE_DETECT_SUPPORTED,
      data: { isSupportedFocusStateDetect: isSupportedFocusStateDetect }
    };
  }

  public static resetFocusExposure(): ActionData {
    return {
      type: FocusExposureActionType.ACTION_RESET_FOCUS_EXPOSURE,
      data: {},
      isEvent: true
    };
  }
}