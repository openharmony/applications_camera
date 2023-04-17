/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import { ZoomFunction } from '../../function/ZoomFunction'
import { Action, ActionData } from '../actions/Action'

export type ZoomState = {
  zoomRatio: number,
  minZoomRatio: number,
  maxZoomRatio: number,
  scrollDetailsBox: number,
  isPhotoZoomDetails: boolean,
  photoDetailsOffsetX: number,
  photoDetailsOffsetXInit: number,
  isShowZoomText: boolean,
  isShowPressScrollDetailPhotoButton: boolean,
  showZoomLabelValue: boolean,
  isShowPinch: boolean,
}

const initState: ZoomState = {
  zoomRatio: 1,
  minZoomRatio: 1,
  maxZoomRatio: 6,
  scrollDetailsBox: 32,
  isPhotoZoomDetails: false,
  photoDetailsOffsetX: 0,
  photoDetailsOffsetXInit: 0,
  isShowZoomText: false,
  isShowPinch: false,
  isShowPressScrollDetailPhotoButton: false,
  showZoomLabelValue: true,
}

export default function ZoomReducer(state = initState, action: ActionData): ZoomState {
  switch (action.type) {
  case Action.ACTION_CHANGE_ZOOM_RATIO:
    return { ...state, zoomRatio: action.data.zoomRatio }
  case Action.ACTION_RESET_ZOOM_RATIO:
    return { ...state, zoomRatio: action.data.zoomRatio }
  case Action.ACTION_INIT_ZOOM_RATIO:
    return { ...state, minZoomRatio: action.data.minZoomRatio, maxZoomRatio: action.data.maxZoomRatio }
  case Action.ACTION_UPDATE_SCROLL_DETAILS_BOX:
    return { ...state, scrollDetailsBox: action.data.scrollDetailsBox }
  case Action.ACTION_UPDATE_PHOTO_ZOOM_DETAILS_FLAG:
    return { ...state, isPhotoZoomDetails: action.data.isPhotoZoomDetails }
  case Action.ACTION_UPDATE_PHOTO_DETAILS_OFFSET_X:
    return { ...state, photoDetailsOffsetX: action.data.photoDetailsOffsetX }
  case Action.ACTION_INIT_PHOTO_DETAILS_OFFSET_X:
    return { ...state, photoDetailsOffsetXInit: action.data.photoDetailsOffsetXInit }
  case Action.ACTION_UPDATE_SHOW_ZOOM_TEXT_FLAG:
    return { ...state, isShowZoomText: action.data.isShowZoomText }
  case Action.ACTION_UPDATE_SHOW_PRESS_SCROLL_DETAIL_PHOTO_BUTTON:
    return { ...state, isShowPressScrollDetailPhotoButton: action.data.isShowPressScrollDetailPhotoButton }
  case Action.ACTION_SHOW_ZOOM_LABEL_VALUE:
    return { ...state, showZoomLabelValue: action.data.showZoomLabelValue }
  case Action.ACTION_UPDATE_SHOW_PINCH:
    return { ...state, isShowPinch: action.data.isShowPinch }
  default:
    return state;
  }
}