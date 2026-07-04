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
import lazy { UIOperationType } from '../../component/uicomponent/UIOperationType';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import type { ActionData } from '../actions/Action';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { execReduxReducer, initReduxStateMap } from '../ReducerUtil';
import lazy { OhCombinedState } from '../ReduxConfig';

export enum ExtendComponent {
  NONE = 0,
  EFFECT = 1,
  BEAUTY = 2,
  FILTER = 3,
  XMAGE = 4,
  SHUTTER = 5,
  APERTURE = 6,
  TIMELAPSE = 6,
}

enum TimeLapseMode {
  NONE = -1,
  AUTOMATIC = 8,
  METERING_MODE = 1, // 矩阵
  ISO = 2,
  APERTURE = 3,
  S = 4,
  EXPOSURE = 5,
  FOCUS = 6,
  WHITE_BELANCE = 7,
}

export enum SketchStatus {
  STOPPED = 0,
  STARTED = 1,
  STOPPING = 2,
  STARTING = 3
}

export type UIState = {
  isShowFootBar: boolean,
  isShowModeBar: boolean,
  isShowParamBar: boolean,
  isShowExtendBar: boolean,
  isExtendBarContinuation: boolean,
  extendBarEffectView: FunctionId,
  isImmersive: boolean,
  mainTrigCompo: UIOperationType,
  showPicker: boolean
  isShowWatermarkPage: boolean,
  sketchStatus: SketchStatus,
  timeLapseSlider: number;
  timeLapse: TimeLapseMode,
  checkedIcon: TimeLapseMode,
  iconId: number,
  isShowToolBar: boolean,
  isFlashEnable: boolean,
  isSmartControlLightTouchEnable: boolean,
  isSmartControlLongTouchEnable: boolean,
  isSmartControlSlideEnable: boolean,
  isSmartControlConfig: boolean
};

const uiStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initUiStateMap(): Map<string, object> {
  const initState: UIState = {
    isShowFootBar: true,
    isShowModeBar: true,
    isShowParamBar: true,
    isShowExtendBar: false,
    isExtendBarContinuation: false,
    extendBarEffectView: FunctionId.NONE,
    isImmersive: false,
    mainTrigCompo:UIOperationType.NULL,
    showPicker: false,
    isShowWatermarkPage: false,
    sketchStatus: SketchStatus.STOPPED,
    timeLapseSlider: 0,
    timeLapse: TimeLapseMode.NONE,
    checkedIcon: TimeLapseMode.NONE,
    iconId: -1,
    isShowToolBar: false,
    isFlashEnable: true,
    isSmartControlLightTouchEnable: false,
    isSmartControlLongTouchEnable: false,
    isSmartControlSlideEnable: false,
    isSmartControlConfig: false
  };
  return initReduxStateMap(initState, uiStateMap);
}

const uiReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setUiReducerMap(): void {

  uiReducerMap.set(ActionType.ACTION_IS_SHOW_FOOT_BAR, (action: ActionData) => {
    return {
      isShowFootBar: action.data.isShowFootBar
    };
  });

  uiReducerMap.set(ActionType.ACTION_IS_SHOW_MODE_BAR, (action: ActionData) => {
    return {
      isShowModeBar: action.data.isShowModeBar
    };
  });

  uiReducerMap.set(ActionType.ACTION_IS_SHOW_PARAM_BAR, (action: ActionData) => {
    return {
      isShowParamBar: action.data.isShowParamBar
    };
  });

  uiReducerMap.set(ActionType.ACTION_IS_SHOW_EXTEND_BAR, (action: ActionData) => {
    return {
      isShowExtendBar: action.data.isShowExtendBar
    };
  });

  uiReducerMap.set(ActionType.ACTION_IS_EXTEND_BAR_CONTINUATION, (action: ActionData) => {
    return {
      isExtendBarContinuation: action.data.isExtendBarContinuation
    };
  });

  uiReducerMap.set(ActionType.ACTION_UPDATE_PORTRAIT_SLIDER, (action: ActionData) => {
    return {
      portraitSlider: action.data.portraitSlider
    };
  });

  uiReducerMap.set(ActionType.ACTION_IS_ENTER_IMMERSIVE, (action: ActionData) => {
    return {
      isImmersive: action.data.isImmersive, mainTrigCompo: action.data.mainTrigCompo
    };
  });

  uiReducerMap.set(ActionType.ACTION_CHANGE_SHOW_EXTEND_COMPONENT, (action: ActionData) => {
    return {
      extendBarEffectView: action.data.extendBarEffectView
    };
  });

  uiReducerMap.set(ActionType.ACTION_SHOW_PICKER, (action: ActionData) => {
    return {
      showPicker: action.data.showPicker
    };
  });

  uiReducerMap.set(ActionType.ACTION_IS_SHOW_WATERMARK_PAGE, (action: ActionData) => {
    return {
      isShowWatermarkPage: action.data.isShowWatermarkPage
    };
  });

  uiReducerMap.set(ActionType.ACTION_ON_SKETCH_STATUS_CHANGED, (action: ActionData) => {
    return {
      sketchStatus: action.data.status
    };
  });

  uiReducerMap.set(ActionType.ACTION_PROSON_CHANGE_STATE, (action: ActionData) => {
    return {
      iconId: action.data.iconId,
    };
  });

  uiReducerMap.set(ActionType.ACTION_UPDATE_TIME_LAPSE_SLIDER, (action: ActionData) => {
    return {
      timeLapseSlider: action.data.timeLapseSlider
    };
  });

  uiReducerMap.set(ActionType.ACTION_LOW_BATTERY_SHOW_EXIT_FLASH_DIALOG, (action: ActionData) => {
    return {
      isFlashEnable: action.data.isFlashEnable
    };
  });

  uiReducerMap.set(ActionType.ACTION_UPDATE_SMART_CONTROL_SWITCH_STATE, (action: ActionData) => {
    return {
      isSmartControlLightTouchEnable: action.data.isSmartControlLightTouchEnable,
      isSmartControlLongTouchEnable: action.data.isSmartControlLongTouchEnable,
      isSmartControlSlideEnable: action.data.isSmartControlSlideEnable,
      isSmartControlConfig: action.data.isSmartControlConfig
    };
  });
}

export function uiReducer(state: OhCombinedState, action: ActionData): string[] {
  if (uiReducerMap.size <= 0) {
    setUiReducerMap();
  }
  return execReduxReducer(state, action, uiReducer.name, uiReducerMap, initUiStateMap);
}