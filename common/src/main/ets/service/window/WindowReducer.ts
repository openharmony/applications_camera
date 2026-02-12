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
import type { ActionData } from '../../redux/actions/Action';
import lazy { WindowActionType } from '../../redux/actions/WindowActionType';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import window from '@ohos.window';
import lazy { PickerWindowType } from '../../component/picker/PickerWindowType';
import lazy { OhCombinedState } from '../../redux';
import lazy { execReduxReducer, initReduxStateMap } from '../../redux/ReducerUtil';

export type WindowState = {
  windowWidth: number,
  windowHeight: number,
  isLockRotation: boolean, // 是否锁定旋转(true:窗口方向不跟随sensor):用户选中锁定(控制中心) 或 应用内主动锁定(如半折态、直板态下锁定)
  windowDirection: WindowDirection, // 用于大屏进入沉浸式时锁定旋转计算组件方向的基础窗口方向
  windowStatus: window.WindowStatusType, // 窗口状态：悬浮窗、分屏、全屏等
  pickerWindowType: PickerWindowType,
};

const windowStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initWindowStateMap(): Map<string, object> {
  const initState: WindowState = {
    windowWidth: 0,
    windowHeight: 0,
    isLockRotation: true,
    windowDirection: WindowDirection.TOP,
    windowStatus: window.WindowStatusType.FULL_SCREEN,
    pickerWindowType: PickerWindowType.COLLAPSED_VERTICAL_FULL,
  };
  return initReduxStateMap(initState, windowStateMap);
}

const windowReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setWindowReducerMap(): void {
  windowReducerMap.set(WindowActionType.ON_SIZE_CHANGE, (action: ActionData) => {
    return {
      windowWidth: action.data.windowSize.width, windowHeight: action.data.windowSize.height
    };
  });

  windowReducerMap.set(WindowActionType.ON_LOCK_ROTATION_STATUS_CHANGE, (action: ActionData) => {
    return {
      isLockRotation: action.data.isLockRotation
    };
  });

  windowReducerMap.set(WindowActionType.WINDOW_LOCK_DIRECTION, (action: ActionData) => {
    return {
      windowDirection: action.data.direction
    };
  });

  windowReducerMap.set(WindowActionType.WINDOW_STATUS, (action: ActionData) => {
    return {
      windowStatus: action.data.windowStatus
    };
  });

  windowReducerMap.set(WindowActionType.PICKER_WINDOW_TYPE, (action: ActionData) => {
    return {
      pickerWindowType: action.data.pickerWindowType
    };
  });
}

export function windowReducer(state: OhCombinedState, action: ActionData): string[] {
  if (windowReducerMap.size <= 0) {
    setWindowReducerMap();
  }
  return execReduxReducer(state, action, windowReducer.name, windowReducerMap, initWindowStateMap);
}