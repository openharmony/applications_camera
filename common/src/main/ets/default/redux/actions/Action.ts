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

import { CameraPlatformCapability } from '../../camera/CameraPlatformCapability'
import { CameraId } from '../../setting/settingitem/CameraId'
import { AnyAction } from '../../redux/core/redux'
import { Log } from '../../utils/Log'

interface Data {
 [prop: string]: any;
}

export enum UiStateMode {
  NONE,
  EXCLUDE_PREVIEW
}

export interface ActionData extends AnyAction {
  data: Data
}

export class Action {

  // Context
  public static readonly ACTION_INIT_FOOT_BAR_WIDTH = 'ACTION_INIT_FOOT_BAR_WIDTH'
  public static readonly ACTION_INIT_FOOT_BAR_HEIGHT = 'ACTION_INIT_FOOT_BAR_HEIGHT'
  public static readonly ACTION_SET_PERMISSION_FLAG = 'ACTION_SET_PERMISSION_FLAG'
  public static readonly ACTION_INIT_ACTION = 'ACTION_INIT_ACTION'
  public static readonly ACTION_KEEP_SCREEN_ON = 'ACTION_KEEP_SCREEN_ON'
  public static readonly ACTION_UPDATE_INIT_SHOW_FLAG = 'ACTION_UPDATE_INIT_SHOW_FLAG'

  // Camera
  public static readonly ACTION_INIT = 'ACTION_INIT'
  public static readonly ACTION_INIT_DONE = 'ACTION_INIT_DONE'
  public static readonly ACTION_SWITCH_CAMERA = 'ACTION_SWITCH_CAMERA'
  public static readonly ACTION_SET_CAMERA_POSITION = 'ACTION_SET_CAMERA_POSITION'
  public static readonly ACTION_UPDATE_CAMERA_POSITION = 'ACTION_UPDATE_CAMERA_POSITION'
  public static readonly ACTION_CLOSE_CAMERA = 'ACTION_CLOSE_CAMERA'
  public static readonly ACTION_UPDATE_CAMERA_STATUS = 'ACTION_UPDATE_CAMERA_STATUS'

  // Mode
  public static readonly ACTION_INIT_MODE = 'ACTION_INIT_MODE'
  public static readonly ACTION_CHANGE_MODE = 'ACTION_CHANGE_MODE'
  public static readonly ACTION_SET_MODE = 'ACTION_SET_MODE'
  public static readonly ACTION_UPDATE_MODE = 'ACTION_UPDATE_MODE'
  public static readonly ACTION_ON_MODE_CHANGED = 'ACTION_ON_MODE_CHANGED'
  public static readonly ACTION_THIRD_PARTY_CALL =  'ACTION_THIRD_PARTY_CALL'
  public static readonly ACTION_FA_CALL =  'ACTION_FA_CALL'
  public static readonly ACTION_SWIPE_MODE_DONE =  'ACTION_SWIPE_MODE_DONE'

  // Preview
  public static readonly ACTION_PREPARE_SURFACE = 'ACTION_PREPARE_SURFACE'
  public static readonly ACTION_START_PREVIEW = 'ACTION_START_PREVIEW'
  public static readonly ACTION_RESTART_PREVIEW = 'ACTION_RESTART_PREVIEW'
  public static readonly ACTION_UPDATE_SURFACE_ID = 'ACTION_UPDATE_SURFACE_ID'
  public static readonly ACTION_CHANGE_X_COMPONENT_SIZE = 'ACTION_CHANGE_X_COMPONENT_SIZE'
  public static readonly ACTION_UPDATE_SHOW_PREVIEW_FLAG = 'ACTION_UPDATE_SHOW_PREVIEW_FLAG'

  // Capture
  public static readonly ACTION_CAPTURE = 'ACTION_CAPTURE'
  public static readonly ACTION_CAPTURE_DONE = 'ACTION_CAPTURE_DONE'
  public static readonly ACTION_CAPTURE_ERROR = 'ACTION_CAPTURE_ERROR'
  public static readonly ACTION_THUMBNAIL = 'ACTION_THUMBNAIL'
  public static readonly ACTION_UPDATE_THUMBNAIL = 'ACTION_UPDATE_THUMBNAIL'
  public static readonly ACTION_LOAD_THUMBNAIL = 'ACTION_LOAD_THUMBNAIL'
  public static readonly ACTION_RELOAD_THUMBNAIL = 'ACTION_RELOAD_THUMBNAIL'

  // Record
  public static readonly ACTION_RECORD_START = 'ACTION_RECORD_START'
  public static readonly ACTION_RECORD_PAUSE = 'ACTION_RECORD_PAUSE'
  public static readonly ACTION_RECORD_RESUME = 'ACTION_RECORD_RESUME'
  public static readonly ACTION_RECORD_STOP = 'ACTION_RECORD_STOP'
  public static readonly ACTION_RECORD_DONE = 'ACTION_RECORD_DONE'
  public static readonly ACTION_RECORD_ERROR = 'ACTION_RECORD_ERROR'
  public static readonly ACTION_START_VIDEO_FLAG = 'ACTION_START_VIDEO_FLAG'
  public static readonly ACTION_UPDATE_RECORDING_TIME = 'ACTION_UPDATE_RECORDING_TIME'
  public static readonly ACTION_UPDATE_RECORDING_TIME_DISPLAY = 'ACTION_UPDATE_RECORDING_TIME_DISPLAY'
  public static readonly ACTION_UPDATE_VIDEO_STATE = 'ACTION_UPDATE_VIDEO_STATE'
  public static readonly ACTION_UPDATE_RECORDING_PAUSED = 'ACTION_UPDATE_RECORDING_PAUSED'
  public static readonly ACTION_UPDATE_VIDEO_URI = 'ACTION_UPDATE_VIDEO_URI'

  // Setting
  public static readonly ACTION_CHANGE_IMAGE_SIZE = 'ACTION_CHANGE_IMAGE_SIZE'
  public static readonly ACTION_CHANGE_VIDEO_SIZE = 'ACTION_CHANGE_VIDEO_SIZE'
  public static readonly ACTION_CHANGE_ZOOM_RATIO = 'ACTION_CHANGE_ZOOM_RATIO'
  public static readonly ACTION_CHANGE_TIME_LAPSE = 'ACTION_CHANGE_TIME_LAPSE'
  public static readonly ACTION_ASSISTIVE_GRID_VIEW = 'ACTION_ASSISTIVE_GRID_VIEW'

  // Device error
  public static readonly ACTION_DEVICE_ERROR = 'ACTION_DEVICE_ERROR'

  // Ui
  public static readonly ACTION_UI_STATE = 'ACTION_UI_STATE'
  public static readonly ACTION_INIT_ZOOM_RATIO = 'ACTION_INIT_ZOOM_RATIO'
  public static readonly ACTION_RESET_ZOOM_RATIO = 'ACTION_RESET_ZOOM_RATIO'
  public static readonly ACTION_UPDATE_ZOOM_PERCENTAGE = 'ACTION_UPDATE_ZOOM_PERCENTAGE'
  public static readonly ACTION_UPDATE_SHOW_BIG_TEXT_FLAG = 'ACTION_UPDATE_SHOW_BIG_TEXT_FLAG'
  public static readonly ACTION_UPDATE_SHOW_ZOOM_TEXT_FLAG = 'ACTION_UPDATE_SHOW_ZOOM_TEXT_FLAG'
  public static readonly ACTION_UPDATE_PHOTO_ZOOM_DETAILS_FLAG = 'ACTION_UPDATE_PHOTO_ZOOM_DETAILS_FLAG'
  public static readonly ACTION_UPDATE_BASE_ZOOM = 'ACTION_UPDATE_BASE_ZOOM'
  public static readonly ACTION_UPDATE_PINCH_GESTURE_FLAG = 'ACTION_UPDATE_PINCH_GESTURE_FLAG'
  public static readonly ACTION_UPDATE_PINCH_GESTURE_TIMER_ID = 'ACTION_UPDATE_PINCH_GESTURE_TIMER_ID'
  public static readonly ACTION_UPDATE_MODE_INDEX = 'ACTION_UPDATE_MODE_INDEX'
  public static readonly ACTION_UPDATE_SMALL_VIDEO_TIMER_VISIBLE = 'ACTION_UPDATE_SMALL_VIDEO_TIMER_VISIBLE'
  public static readonly ACTION_UPDATE_BIG_VIDEO_TIMER_VISIBLE = 'ACTION_UPDATE_BIG_VIDEO_TIMER_VISIBLE'
  public static readonly ACTION_UPDATE_RECORDING_SPOT_VISIBLE = 'ACTION_UPDATE_RECORDING_SPOT_VISIBLE'
  public static readonly ACTION_UPDATE_OPACITY_VALUE = 'ACTION_UPDATE_OPACITY_VALUE'
  public static readonly ACTION_UPDATE_SHOW_PRESS_SCROLL_DETAIL_PHOTO_BUTTON = 'ACTION_UPDATE_SHOW_PRESS_SCROLL_DETAIL_PHOTO_BUTTON'
  public static readonly ACTION_UPDATE_SCROLL_DETAILS_BOX = 'ACTION_UPDATE_SCROLL_DETAILS_BOX'
  public static readonly ACTION_INIT_PHOTO_DETAILS_OFFSET_X = 'ACTION_INIT_PHOTO_DETAILS_OFFSET_X'
  public static readonly ACTION_UPDATE_PHOTO_DETAILS_OFFSET_X = 'ACTION_UPDATE_PHOTO_DETAILS_OFFSET_X'
  public static readonly ACTION_UPDATE_CAPTURE_BTN_SCALE = 'ACTION_UPDATE_CAPTURE_BTN_SCALE'
  public static readonly ACTION_UPDATE_SHOW_FLASH_BLACK_FLAG = 'ACTION_UPDATE_SHOW_FLASH_BLACK_FLAG'
  public static readonly ACTION_UPDATE_SHUTTER_ICON = 'ACTION_UPDATE_SHUTTER_ICON'
  public static readonly ACTION_UPDATE_BIG_TEXT_OPACITY = 'ACTION_UPDATE_BIG_TEXT_OPACITY'
  public static readonly ACTION_UPDATE_MODE_BAR_ITEM_WIDTH = 'ACTION_UPDATE_MODE_BAR_ITEM_WIDTH'
  public static readonly ACTION_UPDATE_SHOW_TAB_BAR_WIDTH = 'ACTION_UPDATE_SHOW_TAB_BAR_WIDTH'
  public static readonly ACTION_UPDATE_SHOW_MORE_LIST = 'ACTION_UPDATE_SHOW_MORE_LIST'
  public static readonly ACTION_UPDATE_OPACITY_TAB_BAR = 'ACTION_UPDATE_OPACITY_TAB_BAR'
  public static readonly ACTION_SWIPE_MODE = 'ACTION_SWIPE_MODE'
  public static readonly ACTION_SHOW_ZOOM_LABEL_VALUE = 'ACTION_SHOW_ZOOM_LABEL_VALUE'
  public static readonly ACTION_UPDATE_SHOW_PINCH = 'ACTION_UPDATE_SHOW_PINCH'
  public static readonly ACTION_CLOSE_DIALOG = 'ACTION_CLOSE_DIALOG'
  public static readonly ACTION_SHOW_SETTING_VIEW = 'ACTION_SHOW_SETTING_VIEW'
  public static readonly ACTION_CAPTURE_PHOTO_OUTPUT = 'ACTION_CAPTURE_PHOTO_OUTPUT'


  /** CONTEXT METHODS LIST **/

  public static initFootBarWidth(footBarWidth: number): ActionData {
    return {
      type: Action.ACTION_INIT_FOOT_BAR_WIDTH,
      data: { footBarWidth: footBarWidth }
    }
  }

  public static initFootBarHeight(footBarHeight: number): ActionData {
    return {
      type: Action.ACTION_INIT_FOOT_BAR_HEIGHT,
      data: { footBarHeight: footBarHeight }
    }
  }

  public static setPermissionFlag(permissionFlag: boolean): ActionData {
    return {
      type: Action.ACTION_SET_PERMISSION_FLAG,
      data: { permissionFlag: permissionFlag }
    }
  }

  public static initAction(action: string): ActionData {
    return {
      type: Action.ACTION_INIT_ACTION,
      data: { action: action }
    }
  }

  public static updateScreenStatus(isKeepScreenOn: boolean): ActionData {
    return {
      type: Action.ACTION_KEEP_SCREEN_ON,
      data: { isKeepScreenOn: isKeepScreenOn }
    }
  }

  public static updateInitShowFlag(initShowFlag: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_INIT_SHOW_FLAG,
      data: { initShowFlag: initShowFlag }
    }
  }


  /** CAMERA METHODS LIST **/

  public static initCamera(cameraId: CameraId, mode: string): ActionData {
    return {
      type: Action.ACTION_INIT,
      data: { cameraId: cameraId, mode: mode }
    }
  }

  public static initCameraDone(platformCapability: CameraPlatformCapability): ActionData {
    return {
      type: Action.ACTION_INIT_DONE,
      data: { platformCapability: platformCapability }
    }
  }

  public static switchCamera(cameraId: string, curMode?: string): ActionData {
    return {
      type: Action.ACTION_SWITCH_CAMERA,
      data: { cameraId: cameraId, curMode: curMode }
    }
  }

  public static setCameraPosition(cameraPosition: string): ActionData {
    return {
      type: Action.ACTION_SET_CAMERA_POSITION,
      data: { cameraPosition: cameraPosition }
    }
  }

  public static updateCameraPosition(cameraPosition: string): ActionData {
    return {
      type: Action.ACTION_UPDATE_CAMERA_POSITION,
      data: { cameraPosition: cameraPosition }
    }
  }

  public static updateCameraStatus(): ActionData {
    return {
      type: Action.ACTION_UPDATE_CAMERA_STATUS,
      data: {}
    }
  }

  public static close(): ActionData {
    return {
      type: Action.ACTION_CLOSE_CAMERA,
      data: {}
    }
  }


  /** MODE METHODS LIST**/

  public static initMode(mode: string): ActionData {
    return {
      type: Action.ACTION_INIT_MODE,
      data: { mode: mode }
    }
  }

  public static changeMode(mode: string): ActionData {
    return {
      type: Action.ACTION_CHANGE_MODE,
      data: { mode: mode }
    }
  }

  public static setMode(mode: string): ActionData {
    return {
      type: Action.ACTION_SET_MODE,
      data: { mode: mode }
    }
  }

  public static updateMode(mode: string): ActionData {
    return {
      type: Action.ACTION_UPDATE_MODE,
      data: { mode: mode }
    }
  }

  public static onModeChanged(mode: string): ActionData {
    return {
      type: Action.ACTION_ON_MODE_CHANGED,
      data: { mode: mode }
    }
  }

  public static thirdPartyCall(isThirdPartyCall: boolean, action: string): ActionData {
    return {
      type: Action.ACTION_THIRD_PARTY_CALL,
      data: { isThirdPartyCall: isThirdPartyCall, action: action }
    }
  }

  public static faCall(isFaCall: boolean): ActionData {
    return {
      type: Action.ACTION_FA_CALL,
      data: { isFaCall: isFaCall}
    }
  }


  /** PREVIEW METHODS LIST **/

  public static prepareSurface(surfaceId: number): ActionData {
    return {
      type: Action.ACTION_PREPARE_SURFACE,
      data: { surfaceId: surfaceId }
    }
  }

  public static startPreview(zoomRatio?: number): ActionData {
    return {
      type: Action.ACTION_START_PREVIEW,
      data: { zoomRatio: zoomRatio }
    }
  }

  public static reStartPreview(zoomRatio?: number): ActionData {
    return {
      type: Action.ACTION_RESTART_PREVIEW,
      data: { zoomRatio: zoomRatio }
    }
  }

  public static updateSurfaceId(surfaceId: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_SURFACE_ID,
      data: { surfaceId: surfaceId }
    }
  }

  public static changeXComponentSize(xComponentWidth: number, xComponentHeight: number): ActionData {
    return {
      type: Action.ACTION_CHANGE_X_COMPONENT_SIZE,
      data: { xComponentWidth: xComponentWidth, xComponentHeight: xComponentHeight }
    }
  }

  public static updateShowPreviewFlag(isShowPreview: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_PREVIEW_FLAG,
      data: { isShowPreview: isShowPreview }
    }
  }


  /** CAPTURE METHODS LIST **/

  public static capture(): ActionData {
    return {
      type: Action.ACTION_CAPTURE,
      data: {}
    }
  }

  public static capturePhotoOutput(): ActionData {
    return {
      isEvent: true,
      type: Action.ACTION_CAPTURE_PHOTO_OUTPUT,
      data: {}
    }
  }

  public static captureDone(thumbnail): ActionData {
    return {
      type: Action.ACTION_THUMBNAIL,
      data: { thumbnail: thumbnail }
    }
  }

  public static captureError(): ActionData {
    return {
      type: Action.ACTION_CAPTURE_ERROR,
      data: {}
    }
  }

  public static thumbnail(thumbnailUri): ActionData {
    return {
      type: Action.ACTION_THUMBNAIL,
      data: { thumbnail: thumbnailUri }
    }
  }

  public static updateThumbnail(thumbnailPixelMap, resourceUri): ActionData {
    return {
      type: Action.ACTION_UPDATE_THUMBNAIL,
      data: { thumbnail: thumbnailPixelMap, resourceUri: resourceUri }
    }
  }

  public static loadThumbnail(thumbnailPixelMap): ActionData {
    return {
      type: Action.ACTION_LOAD_THUMBNAIL,
      data: { thumbnail: thumbnailPixelMap }
    }
  }

  public static reloadThumbnail(): ActionData {
    return {
      type: Action.ACTION_RELOAD_THUMBNAIL,
      data: {}
    }
  }


  /** RECORD METHODS LIST **/

  public static startRecording(): ActionData {
    return {
      type: Action.ACTION_RECORD_START,
      data: {}
    }
  }

  public static pauseRecording(): ActionData {
    return {
      type: Action.ACTION_RECORD_PAUSE,
      data: {}
    }
  }

  public static resumeRecording(): ActionData {
    return {
      type: Action.ACTION_RECORD_RESUME,
      data: {}
    }
  }

  public static stopRecording(): ActionData {
    return {
      type: Action.ACTION_RECORD_STOP,
      data: {}
    }
  }

  public static recordDone(thumbnail): ActionData {
    return {
      type: Action.ACTION_RECORD_STOP,
      data: { thumbnail: thumbnail }
    }
  }

  public static recordError(): ActionData {
    return {
      type: Action.ACTION_RECORD_ERROR,
      data: {}
    }
  }

  public static startVideoFlag(isStartVideoFlag: boolean): ActionData {
    return {
      type: Action.ACTION_START_VIDEO_FLAG,
      data: { isStartVideo: isStartVideoFlag }
    }
  }

  public static updateRecordingTime(recordingTime: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_RECORDING_TIME,
      data: { recordingTime: recordingTime }
    }
  }

  public static updateRecordingTimeDisplay(recordingTimeDisplay: string): ActionData {
    return {
      type: Action.ACTION_UPDATE_RECORDING_TIME_DISPLAY,
      data: { recordingTimeDisplay: recordingTimeDisplay }
    }
  }

  public static updateVideoState(videoState: string): ActionData {
    return {
      type: Action.ACTION_UPDATE_VIDEO_STATE,
      data: { videoState: videoState }
    }
  }

  public static updateRecordingPaused(isRecordingPaused: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_RECORDING_PAUSED,
      data: { isRecordingPaused: isRecordingPaused }
    }
  }

  public static updateVideoUri(videoUri: string): ActionData {
    return {
      type: Action.ACTION_UPDATE_VIDEO_URI,
      data: { videoUri: videoUri }
    }
  }


  /** SETTING METHODS LIST **/

  public static changeImageSize(imageSize): ActionData {
    return {
      type: Action.ACTION_CHANGE_IMAGE_SIZE,
      data: { imageSize: imageSize }
    }
  }

  public static changeVideoSize(videoSize): ActionData {
    return {
      type: Action.ACTION_CHANGE_VIDEO_SIZE,
      data: { videoSize: videoSize }
    }
  }

  public static changeZoomRatio(zoomRatio: number): ActionData {
    return {
      type: Action.ACTION_CHANGE_ZOOM_RATIO,
      data: { zoomRatio: zoomRatio }
    }
  }

  public static changeTimeLapse(isShowtimeLapse: boolean): ActionData {
    return {
      type: Action.ACTION_CHANGE_TIME_LAPSE,
      data: { isShowtimeLapse: isShowtimeLapse}
    }
  }

  public static swipeModeChangeDone(modeChangeDone: boolean): ActionData {
    return {
      type: Action.ACTION_SWIPE_MODE_DONE,
      data: { modeChangeDone: modeChangeDone}
    }
  }

  public static assistiveGridView(isAssGridViewShow: number): ActionData {
    return {
      type: Action.ACTION_ASSISTIVE_GRID_VIEW,
      data: { isAssGridViewShow: isAssGridViewShow }
    }
  }


  /** DEVICE ERROR METHODS LIST **/

  public static deviceError(info): ActionData {
    return {
      type: Action.ACTION_DEVICE_ERROR,
      data: { info: info }
    }
  }


  /** UI METHODS LIST **/

  public static uiState(enable: boolean): ActionData {
    return {
      type: Action.ACTION_UI_STATE,
      data: { enable: enable, uiStateMode: UiStateMode.NONE }
    }
  }

  public static uiStateWithMode(enable: boolean, uiStateMode: UiStateMode): ActionData {
    return {
      type: Action.ACTION_UI_STATE,
      data: { enable: enable, uiStateMode: uiStateMode }
    }
  }

  public static initZoomRatio(min: number, max: number): ActionData {
    return {
      type: Action.ACTION_INIT_ZOOM_RATIO,
      data: { minZoomRatio: min, maxZoomRatio: max }
    }
  }

  public static resetZoomRatio(zoomRatio: number): ActionData {
    return {
      type: Action.ACTION_RESET_ZOOM_RATIO,
      data: { zoomRatio: zoomRatio }
    }
  }

  public static updateZoomPercentage(zoomPercentage: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_ZOOM_PERCENTAGE,
      data: { zoomPercentage: zoomPercentage }
    }
  }

  public static updateShowBigTextFlag(isShowBigText: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_BIG_TEXT_FLAG,
      data: { isShowBigText: isShowBigText }
    }
  }

  public static updateShowZoomTextFlag(isShowZoomText: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_ZOOM_TEXT_FLAG,
      data: { isShowZoomText: isShowZoomText }
    }
  }

  public static updatePhotoZoomDetailsFlag(isPhotoZoomDetails: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_PHOTO_ZOOM_DETAILS_FLAG,
      data: { isPhotoZoomDetails: isPhotoZoomDetails }
    }
  }

  public static updateBaseZoom(baseZoom: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_BASE_ZOOM,
      data: { baseZoom: baseZoom }
    }
  }

  public static updatePinchGestureFlag(isPinchGesture: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_PINCH_GESTURE_FLAG,
      data: { isPinchGesture: isPinchGesture }
    }
  }

  public static updatePinchGestureTimerId(pinchGestureTimerId: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_PINCH_GESTURE_TIMER_ID,
      data: { pinchGestureTimerId: pinchGestureTimerId }
    }
  }

  public static updateModeIndex(modeIndex: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_MODE_INDEX,
      data: { modeIndex: modeIndex }
    }
  }

  public static updateSmallVideoTimerVisible(visible: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SMALL_VIDEO_TIMER_VISIBLE,
      data: { isSmallVideoTimerVisible: visible }
    }
  }

  public static updateBigVideoTimerVisible(visible: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_BIG_VIDEO_TIMER_VISIBLE,
      data: { isBigVideoTimerVisible: visible }
    }
  }

  public static updateRecordingSpotVisible(visible: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_RECORDING_SPOT_VISIBLE,
      data: { isRecordingSpotVisible: visible }
    }
  }

  public static updateOpacityValue(opacityValue: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_OPACITY_VALUE,
      data: { opacityValue: opacityValue }
    }
  }

  public static updateShowPressScrollDetailPhotoButton(isShow: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_PRESS_SCROLL_DETAIL_PHOTO_BUTTON,
      data: { isShowPressScrollDetailPhotoButton: isShow }
    }
  }

  public static updateScrollDetailsBox(value: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_SCROLL_DETAILS_BOX,
      data: { scrollDetailsBox: value }
    }
  }

  public static initPhotoDetailsOffsetX(offsetX: number): ActionData {
    return {
      type: Action.ACTION_INIT_PHOTO_DETAILS_OFFSET_X,
      data: { photoDetailsOffsetXInit: offsetX }
    }
  }

  public static updatePhotoDetailsOffsetX(offsetX: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_PHOTO_DETAILS_OFFSET_X,
      data: { photoDetailsOffsetX: offsetX }
    }
  }

  public static updateCaptureBtnScale(scale: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_CAPTURE_BTN_SCALE,
      data: { captureBtnScale: scale }
    }
  }

  public static updateShowFlashBlackFlag(flag: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_FLASH_BLACK_FLAG,
      data: { isShowFlashBlack: flag }
    }
  }

  public static updateShutterIcon(icon: Resource): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHUTTER_ICON,
      data: { shutterIcon: icon }
    }
  }

  public static updateBigTextOpacity(opacity: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_BIG_TEXT_OPACITY,
      data: { bigTextOpacity: opacity }
    }
  }

  public static updateModeBarItemWidth(width: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_MODE_BAR_ITEM_WIDTH,
      data: { modeBarItemWidth: width }
    }
  }

  public static updateShowTabBarWidth(widthTabBar: string): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_TAB_BAR_WIDTH,
      data: { widthTabBar: widthTabBar }
    }
  }

  public static updateShowMoreList(isShowMoreList: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_MORE_LIST,
      data: { isShowMoreList: isShowMoreList }
    }
  }

  public static updateOpacityForTabBar(opacity: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_OPACITY_TAB_BAR,
      data: { opacityValueForTabBar: opacity }
    }
  }

  public static swipeChangeMode(swipeModeIndex: number): ActionData {
    return {
      type: Action.ACTION_SWIPE_MODE,
      data: { swipeModeIndex: swipeModeIndex }
    }
  }

  public static updateShowZoomLabelValue(flag: boolean): ActionData {
    return {
      type: Action.ACTION_SHOW_ZOOM_LABEL_VALUE,
      data: { showZoomLabelValue: flag }
    }
  }

  public static updateShowPinch(isShowPinch: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_PINCH,
      data: { isShowPinch: isShowPinch }
    }
  }

  public static closeDialog(isCloseFlag: boolean): ActionData {
    return {
      type: Action.ACTION_CLOSE_DIALOG,
      data: { isCloseFlag: isCloseFlag }
    }
  }

  public static showSettingView(isShowSettingView: boolean): ActionData {
    return {
      type: Action.ACTION_SHOW_SETTING_VIEW,
      data: { isShowSettingView: isShowSettingView }
    }
  }
}
