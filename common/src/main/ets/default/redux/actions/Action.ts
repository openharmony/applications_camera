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

import { CameraPlatformCapability } from '../../camera/CameraPlatformCapability'
import { CameraId } from '../../setting/settingitem/CameraId'
import { AnyAction } from '../../redux/core/redux'

interface Data {
 [prop: string]: any;
}

export interface ActionData extends AnyAction {
  data: Data
}

export class Action {
  public static readonly ACTION_INIT = 'ACTION_INIT'
  public static readonly ACTION_INIT_DONE = 'ACTION_INIT_DONE'
  public static readonly ACTION_SURFACE_ID_PREPARE = 'ACTION_SURFACE_ID_PREPARE'
  public static readonly ACTION_START_PREVIEW = 'ACTION_START_PREVIEW'
  public static readonly ACTION_SWITCH_CAMERA = 'ACTION_SWITCH_CAMERA'
  public static readonly ACTION_CHANGE_MODE = 'ACTION_CHANGE_MODE'
  public static readonly ACTION_SET_MODE = 'ACTION_SET_MODE'
  public static readonly ACTION_UPDATE_MODE = 'ACTION_UPDATE_MODE'
  public static readonly ACTION_CLOSE_CAMERA = 'ACTION_CLOSE_CAMERA'

  // Setting 相关
  public static readonly ACTION_CHANGE_IMAGE_SIZE = 'ACTION_CHANGE_IMAGE_SIZE'
  public static readonly ACTION_CHANGE_VIDEO_SIZE = 'ACTION_CHANGE_VIDEO_SIZE'
  public static readonly ACTION_CHANGE_ZOOM_RATIO = 'ACTION_CHANGE_ZOOM_RATIO'
  public static readonly ACTION_CHANGE_TIME_LAPSE = 'ACTION_CHANGE_TIME_LAPSE'
  public static readonly ACTION_ASSISTIVE_GRID_VIEW = 'ACTION_ASSISTIVE_GRID_VIEW'
  public static readonly ACTION_CLOSE_DIALOG = 'ACTION_CLOSE_DIALOG'

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

  public static readonly ACTION_DEVICE_ERROR = 'ACTION_DEVICE_ERROR'

  public static readonly ACTION_UI_STATE = 'ACTION_UI_STATE'

  /********** NEW UI REMAKE START **********/
  // Context
  public static readonly ACTION_INIT_FOOT_BAR_WIDTH = 'ACTION_INIT_FOOT_BAR_WIDTH'
  public static readonly ACTION_INIT_FOOT_BAR_HEIGHT = 'ACTION_INIT_FOOT_BAR_HEIGHT'
  public static readonly ACTION_SET_PERMISSION_FLAG = 'ACTION_SET_PERMISSION_FLAG'
  public static readonly ACTION_INIT_ACTION = 'ACTION_INIT_ACTION'
  public static readonly ACTION_KEEP_SCREEN_ON = 'ACTION_KEEP_SCREEN_ON'

  // Camera
  public static readonly ACTION_SET_CAMERA_POSITION = 'ACTION_SET_CAMERA_POSITION'
  public static readonly ACTION_UPDATE_CAMERA_POSITION = 'ACTION_UPDATE_CAMERA_POSITION'

  // Mode
  public static readonly ACTION_INIT_MODE = 'ACTION_INIT_MODE'
  public static readonly ACTION_ON_MODE_CHANGED = 'ACTION_ON_MODE_CHANGED'
  public static readonly ACTION_THIRD_PARTY_CALL =  'ACTION_THIRD_PARTY_CALL'

  // Preview
  public static readonly ACTION_UPDATE_SURFACE_ID = 'ACTION_UPDATE_SURFACE_ID'
  public static readonly ACTION_CHANGE_X_COMPONENT_SIZE = 'ACTION_CHANGE_X_COMPONENT_SIZE'
  public static readonly ACTION_UPDATE_X_COMPONENT_CHANGE_FLAG = 'ACTION_UPDATE_X_COMPONENT_CHANGE_FLAG'
  public static readonly ACTION_UPDATE_SHOW_PREVIEW_FLAG = 'ACTION_UPDATE_SHOW_PREVIEW_FLAG'
  public static readonly ACTION_PREPARE_SURFACE = 'ACTION_PREPARE_SURFACE'
  // Capture
  // Record
  public static readonly ACTION_START_VIDEO_FLAG = 'ACTION_START_VIDEO_FLAG'
  public static readonly ACTION_UPDATE_RECORDING_TIME = 'ACTION_UPDATE_RECORDING_TIME'
  public static readonly ACTION_UPDATE_RECORDING_TIME_DISPLAY = 'ACTION_UPDATE_RECORDING_TIME_DISPLAY'
  public static readonly ACTION_UPDATE_VIDEO_STATE = 'ACTION_UPDATE_VIDEO_STATE'
  public static readonly ACTION_UPDATE_RECORDING_PAUSED = 'ACTION_UPDATE_RECORDING_PAUSED'
  public static readonly ACTION_UPDATE_VIDEO_URI = 'ACTION_UPDATE_VIDEO_URI'
  // Ui
  public static readonly ACTION_INIT_ZOOM_RATIO = 'ACTION_INIT_ZOOM_RATIO'
  public static readonly ACTION_RESET_ZOOM_RATIO = 'ACTION_RESET_ZOOM_RATIO'
  public static readonly ACTION_UPDATE_SHOW_BIG_TEXT_FLAG = 'ACTION_UPDATE_SHOW_BIG_TEXT_FLAG'
  public static readonly ACTION_UPDATE_ZOOM_PERCENTAGE = 'ACTION_UPDATE_ZOOM_PERCENTAGE'
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

  // Setting
  public static CloseDialog(isCloseFlag: boolean): ActionData {
    return {
      type: Action.ACTION_CLOSE_DIALOG,
      data: { isCloseFlag: isCloseFlag }
    }
  }

  // Context
  public static InitFootBarWidth(footBarWidth: number): ActionData {
    return {
      type: Action.ACTION_INIT_FOOT_BAR_WIDTH,
      data: { footBarWidth: footBarWidth }
    }
  }

  public static InitFootBarHeight(footBarHeight: number): ActionData {
    return {
      type: Action.ACTION_INIT_FOOT_BAR_HEIGHT,
      data: { footBarHeight: footBarHeight }
    }
  }

  public static SetPermissionFlag(permissionFlag: boolean): ActionData {
    return {
      type: Action.ACTION_SET_PERMISSION_FLAG,
      data: { permissionFlag: permissionFlag }
    }
  }

  public static UpdateScreenStatus(isKeepScreenOn: boolean): ActionData {
    return {
      type: Action.ACTION_KEEP_SCREEN_ON,
      data: { isKeepScreenOn: isKeepScreenOn }
    }
  }

  public static InitAction(action: string): ActionData {
    return {
      type: Action.ACTION_INIT_ACTION,
      data: { action: action }
    }
  }

  // Camera
  public static SetCameraPosition(cameraPosition: string): ActionData {
    return {
      type: Action.ACTION_SET_CAMERA_POSITION,
      data: { cameraPosition: cameraPosition }
    }
  }

  public static SwitchCamera(cameraId: CameraId): ActionData {
    return {
      type: Action.ACTION_SWITCH_CAMERA,
      data: { cameraId: cameraId }
    }
  }

  public static updateCameraPosition(cameraPosition: string): ActionData {
    return {
      type: Action.ACTION_UPDATE_CAMERA_POSITION,
      data: { cameraPosition: cameraPosition }
    }
  }

  // Mode
  public static initMode(mode: string): ActionData {
    return {
      type: Action.ACTION_INIT_MODE,
      data: { mode: mode }
    }
  }

  public static ChangeMode(mode: string): ActionData {
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

  public static OnModeChanged(mode: string): ActionData {
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

  // Preview
  public static StartPreview(): ActionData {
    return {
      type: Action.ACTION_START_PREVIEW,
      data: {}
    }
  }

  public static UpdateSurfaceId(surfaceId: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_SURFACE_ID,
      data: { surfaceId: surfaceId }
    }
  }

  public static PrepareSurface(surfaceId: number): ActionData {
    return {
      type: Action.ACTION_PREPARE_SURFACE,
      data: { surfaceId: surfaceId }
    }
  }

  public static ChangeXComponentSize(xComponentWidth: string, xComponentHeight: string): ActionData {
    return {
      type: Action.ACTION_CHANGE_X_COMPONENT_SIZE,
      data: { xComponentWidth: xComponentWidth, xComponentHeight: xComponentHeight }
    }
  }

  public static UpdateXComponentChangeFlag(flag: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_X_COMPONENT_CHANGE_FLAG,
      data: { xComponentChangeFlag: flag }
    }
  }

  public static UpdateShowPreviewFlag(isShowPreview: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_PREVIEW_FLAG,
      data: { isShowPreview: isShowPreview }
    }
  }

  // Capture
  // Record
  public static StartVideoFlag(isStartVideoFlag: boolean): ActionData {
    return {
      type: Action.ACTION_START_VIDEO_FLAG,
      data: { isStartVideo: isStartVideoFlag }
    }
  }

  public static UpdateRecordingTime(recordingTime: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_RECORDING_TIME,
      data: { recordingTime: recordingTime }
    }
  }

  public static UpdateRecordingTimeDisplay(recordingTimeDisplay: string): ActionData {
    return {
      type: Action.ACTION_UPDATE_RECORDING_TIME_DISPLAY,
      data: { recordingTimeDisplay: recordingTimeDisplay }
    }
  }

  public static UpdateVideoState(videoState: string): ActionData {
    return {
      type: Action.ACTION_UPDATE_VIDEO_STATE,
      data: { videoState: videoState }
    }
  }

  public static UpdateRecordingPaused(isRecordingPaused: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_RECORDING_PAUSED,
      data: { isRecordingPaused: isRecordingPaused }
    }
  }

  public static UpdateVideoUri(videoUri: string): ActionData {
    return {
      type: Action.ACTION_UPDATE_VIDEO_URI,
      data: { videoUri: videoUri }
    }
  }

  // Ui
  public static InitZoomRatio(min: number, max: number): ActionData {
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

  public static ChangeZoomRatio(zoomRatio: number): ActionData {
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

  public static UpdateZoomPercentage(zoomPercentage: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_ZOOM_PERCENTAGE,
      data: { zoomPercentage: zoomPercentage }
    }
  }

  public static UpdateShowBigTextFlag(isShowBigText: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_BIG_TEXT_FLAG,
      data: { isShowBigText: isShowBigText }
    }
  }

  public static UpdateShowZoomTextFlag(isShowZoomText: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_ZOOM_TEXT_FLAG,
      data: { isShowZoomText: isShowZoomText }
    }
  }

  public static UpdateShowZoomLabelValue(flag: boolean): ActionData {
    return {
      type: Action.ACTION_SHOW_ZOOM_LABEL_VALUE,
      data: { showZoomLabelValue: flag }
    }
  }

  public static UpdatePhotoZoomDetailsFlag(isPhotoZoomDetails: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_PHOTO_ZOOM_DETAILS_FLAG,
      data: { isPhotoZoomDetails: isPhotoZoomDetails }
    }
  }

  public static UpdateBaseZoom(baseZoom: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_BASE_ZOOM,
      data: { baseZoom: baseZoom }
    }
  }

  public static UpdatePinchGestureFlag(isPinchGesture: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_PINCH_GESTURE_FLAG,
      data: { isPinchGesture: isPinchGesture }
    }
  }

  public static UpdatePinchGestureTimerId(pinchGestureTimerId: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_PINCH_GESTURE_TIMER_ID,
      data: { pinchGestureTimerId: pinchGestureTimerId }
    }
  }

  public static UpdateModeIndex(modeIndex: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_MODE_INDEX,
      data: { modeIndex: modeIndex }
    }
  }

  public static UpdateSmallVideoTimerVisible(visible: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SMALL_VIDEO_TIMER_VISIBLE,
      data: { isSmallVideoTimerVisible: visible }
    }
  }

  public static UpdateBigVideoTimerVisible(visible: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_BIG_VIDEO_TIMER_VISIBLE,
      data: { isBigVideoTimerVisible: visible }
    }
  }

  public static UpdateRecordingSpotVisible(visible: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_RECORDING_SPOT_VISIBLE,
      data: { isRecordingSpotVisible: visible }
    }
  }

  public static UpdateOpacityValue(opacityValue: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_OPACITY_VALUE,
      data: { opacityValue: opacityValue }
    }
  }

  public static UpdateShowPressScrollDetailPhotoButton(isShow: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_PRESS_SCROLL_DETAIL_PHOTO_BUTTON,
      data: { isShowPressScrollDetailPhotoButton: isShow }
    }
  }

  public static UpdateScrollDetailsBox(value: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_SCROLL_DETAILS_BOX,
      data: { scrollDetailsBox: value }
    }
  }

  public static InitPhotoDetailsOffsetX(offsetX: number): ActionData {
    return {
      type: Action.ACTION_INIT_PHOTO_DETAILS_OFFSET_X,
      data: { photoDetailsOffsetXInit: offsetX }
    }
  }

  public static UpdatePhotoDetailsOffsetX(offsetX: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_PHOTO_DETAILS_OFFSET_X,
      data: { photoDetailsOffsetX: offsetX }
    }
  }

  public static UpdateCaptureBtnScale(scale: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_CAPTURE_BTN_SCALE,
      data: { captureBtnScale: scale }
    }
  }

  public static UpdateShowFlashBlackFlag(flag: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_FLASH_BLACK_FLAG,
      data: { isShowFlashBlack: flag }
    }
  }

  public static UpdateShutterIcon(icon: Resource): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHUTTER_ICON,
      data: { shutterIcon: icon }
    }
  }

  public static UpdateBigTextOpacity(opacity: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_BIG_TEXT_OPACITY,
      data: { bigTextOpacity: opacity }
    }
  }

  public static UpdateModeBarItemWidth(width: number): ActionData {
    return {
      type: Action.ACTION_UPDATE_MODE_BAR_ITEM_WIDTH,
      data: { modeBarItemWidth: width }
    }
  }

  public static UpdateShowTabBarWidth(widthTabBar: string): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_TAB_BAR_WIDTH,
      data: { widthTabBar: widthTabBar }
    }
  }

  // Setting

  /********** NEW UI REMAKE END **********/

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

  //  public static surfacePrepare(surfaceId) {
  //    return {
  //      type: Action.ACTION_SURFACE_ID_PREPARE,
  //      data: { surfaceId: surfaceId}
  //    }
  //  }

  //  public static startPreview() {
  //    return {
  //      type: Action.ACTION_START_PREVIEW,
  //      data: {}
  //    }
  //  }

  //  public static switchCamera(cameraId) {
  //    return {
  //      type: Action.ACTION_SWITCH_CAMERA,
  //      data: { cameraId: cameraId }
  //    }
  //  }

  //  public static changeMode(mode) {
  //    return {
  //      type: Action.ACTION_CHANGE_MODE,
  //      data: { mode: mode }
  //    }
  //  }

  public static close(): ActionData {
    return {
      type: Action.ACTION_CLOSE_CAMERA,
      data: {}
    }
  }

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

  //  public static changeZoomRatio(zoomRatio) {
  //    return {
  //      type: Action.ACTION_CHANGE_ZOOM_RATIO,
  //      data: { zoomRatio: zoomRatio }
  //    }
  //  }

  public static capture(): ActionData {
    return {
      type: Action.ACTION_CAPTURE,
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

  public static UpdateThumbnail(thumbnailPixelMap, resourceUri): ActionData {
    return {
      type: Action.ACTION_UPDATE_THUMBNAIL,
      data: { thumbnail: thumbnailPixelMap, resourceUri: resourceUri }
    }
  }

  public static ReloadThumbnail(): ActionData {
    return {
      type: Action.ACTION_RELOAD_THUMBNAIL,
      data: {}
    }
  }

  public static LoadThumbnail(thumbnailPixelMap): ActionData {
    return {
      type: Action.ACTION_LOAD_THUMBNAIL,
      data: { thumbnail: thumbnailPixelMap }
    }
  }

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

  public static RecordDone(thumbnail): ActionData {
    return {
      type: Action.ACTION_RECORD_STOP,
      data: { thumbnail: thumbnail }
    }
  }

  public static RecordError(): ActionData {
    return {
      type: Action.ACTION_RECORD_DONE,
      data: {}
    }
  }

  public static DeviceError(info): ActionData {
    return {
      type: Action.ACTION_DEVICE_ERROR,
      data: { info: info }
    }
  }

  public static UiState(enable: boolean): ActionData {
    return {
      type: Action.ACTION_UI_STATE,
      data: { enable: enable }
    }
  }

  public static assistiveGridView(isAssGridViewShow: number): ActionData {
    return {
      type: Action.ACTION_ASSISTIVE_GRID_VIEW,
      data: { isAssGridViewShow: isAssGridViewShow }
    }
  }

  public static UpdateShowMoreList(isShowMoreList: boolean): ActionData {
    return {
      type: Action.ACTION_UPDATE_SHOW_MORE_LIST,
      data: { isShowMoreList: isShowMoreList }
    }
  }

  public static UpdateOpacityForTabBar(opacity: number): ActionData {
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
}
