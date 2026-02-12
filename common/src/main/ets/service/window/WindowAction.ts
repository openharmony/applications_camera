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
import lazy { WindowDirection } from '../../utils/WindowDirection';
import window from '@ohos.window';
import lazy { PickerWindowType } from '../../component/picker/PickerWindowType';
import lazy { WindowActionType } from '../../redux/actions/WindowActionType';

const PREFIX: string = 'WINDOW_ACTION_';

export class WindowAction {

  public static onClassReady(): ActionData {
    return {
      isEvent: true,
      type: WindowActionType.ON_CLASS_READY,
      data: {}
    };
  }

  public static onSizeChange(windowSize: {
    width: number;
    height: number
  }): ActionData {
    return {
      isEvent: true,
      type: WindowActionType.ON_SIZE_CHANGE,
      data: { windowSize: windowSize }
    };
  }

  public static refresh(): ActionData {
    return {
      isEvent: true,
      type: WindowActionType.REFRESH_UX,
      data: {}
    };
  }

  public static onRotationStatusChange(isLockRotationStatus: boolean): ActionData {
    return {
      isEvent: true,
      type: WindowActionType.ON_LOCK_ROTATION_STATUS_CHANGE,
      data: { isLockRotation: isLockRotationStatus }
    };
  }

  public static onRotationLocked(lockRotation: boolean): ActionData {
    return {
      isEvent: true,
      type: WindowActionType.ON_ROTATION_LOCKED,
      data: { lockRotation: lockRotation }
    };
  }

  public static updateWindowLockDir(direction: WindowDirection): ActionData {
    return {
      isEvent: true,
      type: WindowActionType.WINDOW_LOCK_DIRECTION,
      data: { direction: direction }
    };
  }

  public static updateWindowStatus(windowStatus: window.WindowStatusType,
    windowPreStatus?: window.WindowStatusType): ActionData {
    return {
      isEvent: true,
      type: WindowActionType.WINDOW_STATUS,
      data: { windowStatus: windowStatus, windowPreStatus: windowPreStatus }
    };
  }

  public static updateWindowVisibilityStatus(windowVisibilityStatus: boolean): ActionData {
    return {
      isEvent: true,
      type: WindowActionType.WINDOW_VISIBILITY_STATUS,
      data: { windowVisibilityStatus: windowVisibilityStatus }
    };
  }

  public static updatePickerWindowType(pickerWindowType: PickerWindowType): ActionData {
    return {
      isEvent: true,
      type: WindowActionType.PICKER_WINDOW_TYPE,
      data: { pickerWindowType: pickerWindowType }
    };
  }

  public static changeTopAvoidArea(topAvoidArea: number): ActionData {
    return {
      isEvent: true,
      type: WindowActionType.CHANGE_TOP_AVOID_AREA,
      data: { topAvoidArea: topAvoidArea }
    };
  }
}