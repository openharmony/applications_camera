/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import {Action} from '../actions/Action'

let initState = {
  uiEnable: true,
  tabItem: ['', 'flash', 'zoom', 'focus', 'setup'],
  aspectRatio: 3/4,
  isBigVideoTimerVisible: false,
  isSmallVideoTimerVisible: false,
  isRecordingSpotVisible: true,
  zoomRatio: 1,
  zoomPercentage: 0,
  maxZoomRatio: 1,
  minZoomRatio: 1,
  isShowZoomText: false,
  isPhotoZoomDetails: false,
  isPinchGesture: false,
  pinchGestureTimerId: 0,
  onTouchDownTimerId: 0,
  isShowFlashBlack: false,
  btnSwitch: false,
  btnSwitchSec: false,
  btnOpacityFirst: 1,
  btnOpacitySec: 0,
  isSwitchBackground: false,
  isShowBigText: false,
  baseZoom: 1,
  scaleX: 1,
  scaleXSec: 0.8,
  rotateAngle: 0,
  rotateAngleSec: 80,
  switchBackgroundOpacity: 1,
  bigTextPositionY: {},
  modeIndex: 1,
  opacityValue: 1,
  multiFontWeight: FontWeight.Regular,
  photoFontWeight: FontWeight.Bold,
  videoFontWeight: FontWeight.Regular,
  multiFontSize: $r("sys.float.ohos_id_text_size_body2"),
  photoFontSize: $r("sys.float.ohos_id_text_size_body1"),
  videoFontSize: $r("sys.float.ohos_id_text_size_body2"),
  isShowPressScrollDetailPhotoButton: false,
  scrollDetailsBox: 32,
  photoDetailsOffsetX: 0,
  photoDetailsOffsetXInit: 0,
  captureBtnScale: 1,
  thumbnailBorder: { width: 1, color: 0xffffff, style: BorderStyle.Solid },
  thumbnailScale: 1,
  thumbnailOpacity: 1,
  bigTextOpacity: 0,
  modeBarItemWidth: 225,
  shutterIcon: $r("app.media.ic_circled_filled")
}

export default function UiReducer(state = initState, action: {
  type: string,
  data: any
}) {
  switch (action.type) {
    case Action.ACTION_UI_STATE:
      return { ...state, uiEnable: action.data.enable}
    case Action.ACTION_INIT_ZOOM_RATIO:
      return { ...state, minZoomRatio: action.data.minZoomRatio, maxZoomRatio: action.data.maxZoomRatio }
    case Action.ACTION_CHANGE_ZOOM_RATIO:
      return { ...state, zoomRatio: action.data.zoomRatio }
    case Action.ACTION_UPDATE_SHOW_BIG_TEXT_FLAG:
      return { ...state, isShowBigText: action.data.isShowBigText }
    case Action.ACTION_UPDATE_ZOOM_PERCENTAGE:
      return { ...state, zoomPercentage: action.data.zoomPercentage }
    case Action.ACTION_UPDATE_SHOW_ZOOM_TEXT_FLAG:
      return { ...state, isShowZoomText: action.data.isShowZoomText }
    case Action.ACTION_UPDATE_PHOTO_ZOOM_DETAILS_FLAG:
      return { ...state, isPhotoZoomDetails: action.data.isPhotoZoomDetails }
    case Action.ACTION_UPDATE_BASE_ZOOM:
      return { ...state, baseZoom: action.data.baseZoom }
    case Action.ACTION_UPDATE_PINCH_GESTURE_FLAG:
      return { ...state, isPinchGesture: action.data.isPinchGesture }
    case Action.ACTION_UPDATE_PINCH_GESTURE_TIMER_ID:
      return { ...state, pinchGestureTimerId: action.data.pinchGestureTimerId }
    case Action.ACTION_UPDATE_SMALL_VIDEO_TIMER_VISIBLE:
      return { ...state, isSmallVideoTimerVisible: action.data.isSmallVideoTimerVisible }
    case Action.ACTION_UPDATE_BIG_VIDEO_TIMER_VISIBLE:
      return { ...state, isBigVideoTimerVisible: action.data.isBigVideoTimerVisible }
    case Action.ACTION_UPDATE_RECORDING_SPOT_VISIBLE:
      return { ...state, isRecordingSpotVisible: action.data.isRecordingSpotVisible }
    case Action.ACTION_UPDATE_OPACITY_VALUE:
      return { ...state, opacityValue: action.data.opacityValue }
    case Action.ACTION_UPDATE_SHOW_PRESS_SCROLL_DETAIL_PHOTO_BUTTON:
      return { ...state, isShowPressScrollDetailPhotoButton: action.data.isShowPressScrollDetailPhotoButton }
    case Action.ACTION_UPDATE_SCROLL_DETAILS_BOX:
      return { ...state, scrollDetailsBox: action.data.scrollDetailsBox }
    case Action.ACTION_INIT_PHOTO_DETAILS_OFFSET_X:
      return { ...state, photoDetailsOffsetXInit: action.data.photoDetailsOffsetXInit }
    case Action.ACTION_UPDATE_PHOTO_DETAILS_OFFSET_X:
      return { ...state, photoDetailsOffsetX: action.data.photoDetailsOffsetX }
    case Action.ACTION_UPDATE_CAPTURE_BTN_SCALE:
      return { ...state, captureBtnScale: action.data.captureBtnScale }
    case Action.ACTION_UPDATE_SHOW_FLASH_BLACK_FLAG:
      return { ...state, isShowFlashBlack: action.data.isShowFlashBlack }
    case Action.ACTION_UPDATE_SHUTTER_ICON:
      return { ...state, shutterIcon: action.data.shutterIcon }
    case Action.ACTION_UPDATE_BIG_TEXT_OPACITY:
      return { ...state, bigTextOpacity: action.data.bigTextOpacity }
    case Action.ACTION_UPDATE_MODE_BAR_ITEM_WIDTH:
      return { ...state, modeBarItemWidth: action.data.modeBarItemWidth }
    case Action.ACTION_UPDATE_MODE_INDEX:
      return { ...state, modeIndex: action.data.modeIndex }
    default:
      return state;
  }
  return state;
}