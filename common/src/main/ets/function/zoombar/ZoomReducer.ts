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
import lazy { ZoomStateType } from './ZoomStateType';
import lazy { OhCombinedState } from '../../redux';
import lazy { execReduxReducer, initReduxStateMap } from '../../redux/ReducerUtil';
import lazy { ZoomActionType } from '../../redux/actions/ZoomActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';

export type ZoomState = {
  zoomRatio: number,
  minZoomRatio: number,
  maxZoomRatio: number,
  isPhotoZoomDetails: boolean,
  isShowZoomView: boolean,
  isShowZoomText: boolean,
  isShowZoomBigText: boolean,
  isShowPinch: boolean,
  baseZoom: number,
  zoomState: string,
  isChangedZoomAfterChangeMode: boolean,
};

const zoomStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initZoomStateMap(): Map<string, object> {
  const initState: ZoomState = {
    zoomRatio: 1,
    minZoomRatio: 1,
    maxZoomRatio: 6,
    isPhotoZoomDetails: false,
    isShowZoomView: false,
    isShowZoomText: false,
    isShowPinch: false,
    isShowZoomBigText: false,
    baseZoom: 0,
    zoomState: ZoomStateType.QUICK_ZOOM,
    isChangedZoomAfterChangeMode: false,
  };
  return initReduxStateMap(initState, zoomStateMap);
}

const zoomReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setZoomReducerMap(): void {
  zoomReducerMap.set(ZoomActionType.ACTION_CHANGE_ZOOM_RATIO, (action: ActionData) => {
    return {
      zoomRatio: action.data.zoomRatio
    };
  });

  zoomReducerMap.set(ZoomActionType.ACTION_INIT_ZOOM_RATIO, (action: ActionData) => {
    return {
      minZoomRatio: action.data.minZoomRatio, maxZoomRatio: action.data.maxZoomRatio
    };
  });

  zoomReducerMap.set(ZoomActionType.ACTION_UPDATE_PHOTO_ZOOM_DETAILS_FLAG, (action: ActionData) => {
    return {
      isPhotoZoomDetails: action.data.isPhotoZoomDetails
    };
  });

  zoomReducerMap.set(ZoomActionType.ACTION_UPDATE_SHOW_ZOOM_VIEW_FLAG, (action: ActionData) => {
    return {
      isShowZoomView: action.data.isShowZoomView
    };
  });

  zoomReducerMap.set(ZoomActionType.ACTION_UPDATE_SHOW_ZOOM_TEXT_FLAG, (action: ActionData) => {
    return {
      isShowZoomText: action.data.isShowZoomText
    };
  });

  zoomReducerMap.set(CameraActionType.CHANGE_MODE, (action: ActionData) => {
    return {
      isShowZoomText: false, isShowZoomView: false, isChangedZoomAfterChangeMode: false,
    };
  });

  zoomReducerMap.set(CameraActionType.STARTED, (action: ActionData) => {
    return {
      isChangedZoomAfterChangeMode: false,
    };
  });

  zoomReducerMap.set(CameraActionType.RELEASE, (action: ActionData) => {
    return {
      isChangedZoomAfterChangeMode: false,
    };
  });

  zoomReducerMap.set(CameraActionType.CHANGE_OUTPUT_TYPE, (action: ActionData) => {
    return {
      isShowZoomText: false, isShowZoomView: false
    };
  });

  zoomReducerMap.set(ZoomActionType.ACTION_UPDATE_ZOOM_BIG_TEXT_VISIBLE, (action: ActionData) => {
    return {
      isShowZoomBigText: action.data.isShowZoomBigText
    };
  });

  zoomReducerMap.set(ZoomActionType.ACTION_UPDATE_SHOW_PINCH, (action: ActionData) => {
    return {
      isShowPinch: action.data.isShowPinch
    };
  });

  zoomReducerMap.set(ZoomActionType.ACTION_UPDATE_BASE_ZOOM, (action: ActionData) => {
    return {
      baseZoom: action.data.baseZoom
    };
  });

  zoomReducerMap.set(ZoomActionType.ACTION_CHANGE_ZOOM_STATE, (action: ActionData) => {
    return {
      zoomState: action.data.zoomState
    };
  });

  zoomReducerMap.set(ZoomActionType.ACTION_RESET_ZOOM_RATIO, (action: ActionData) => {
    return {
      zoomRatio: action.data.zoomRatio
    };
  });

  // 人像和拍照模式 是否手动变焦过 用于自动广角条件管控
  zoomReducerMap.set(ZoomActionType.ACTION_CHANGED_ZOOM_BY_GESTURE, (action: ActionData) => {
    return {
      isChangedZoomAfterChangeMode: true,
    };
  });
}

export function zoomReducer(state: OhCombinedState, action: ActionData): string[] {
  if (zoomReducerMap.size <= 0) {
    setZoomReducerMap();
  }
  return execReduxReducer(state, action, zoomReducer.name, zoomReducerMap, initZoomStateMap);
}