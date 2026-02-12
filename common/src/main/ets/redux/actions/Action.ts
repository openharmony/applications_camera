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

import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import type { ModeType } from '../../mode/ModeType';
import type { UIOperationType } from '../../component/uicomponent/UIOperationType';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { camera } from '@kit.CameraKit';
import lazy { OutputType } from '../../function/outputswitcher/OutputType';
import type { FlashMode } from '../../function/enumbase/FlashMode';
import type { RenderLocation } from '../../function/core/functionproperty/RenderLocation';
import lazy { getStates } from '../Store';
import lazy { ActionType } from '../actions/ActionType';

export const XCOMPONENTWIDTH_OFFSETS: number = 8;

export const XCOMPONENTHEIGHT_OFFSETS: number = 13.5;

export interface Data {
  [prop: string]: any;
}

export interface resolutionData {
  val: number
}

export enum UiStateMode {
  NONE, // 禁用全局组件，任何组件都不能点击
  EXCLUDE_PREVIEW, // 禁用全局组件，除了PreviewArea区域
  EXCLUDE_COMPONENT, // 禁用全局组件，除了某个组件
}

export interface ActionData {
  isEvent?: boolean;
  data: Data;
  type: string
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

export interface MorePageStatus {
  isShowMorePage: boolean,
}

export interface SmartControlSwitchStatus {
  isSmartControlLightTouchEnable: boolean,
  isSmartControlLongTouchEnable: boolean,
  isSmartControlSlideEnable: boolean,
  isSmartControlConfig: boolean
}

export class Action {
  public static photoBrowserOnBackPress(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_PHOTO_BROWSER_ON_BACK_PRESS,
      data: {}
    };
  }

  // Setting
  public static closeDialog(isCloseFlag: boolean): ActionData {
    return {
      type: ActionType.ACTION_CLOSE_DIALOG,
      data: { isCloseFlag: isCloseFlag }
    };
  }

  public static restoreDialogConfirm(restoreConfirmFlag: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_RESTORE_DIALOG_CONFIRM,
      data: { restoreConfirmFlag: restoreConfirmFlag }
    };
  }

  public static confirmLocationTOSettingPermission(isRequestOnSetting: boolean, scene?: number,
    isPhotoRequest?: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_LOCATION_PERMISSION_TO_SETTING,
      data: { isRequestOnSetting: isRequestOnSetting, scene: scene, isPhotoRequest: isPhotoRequest }
    };
  }

  public static refreshLocationToggleItem(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_REFRESH_LOCATION_TOGGLE_ITEM,
      data: {}
    };
  }

  // Context
  public static directionChange(direction: number, rotate: number, settingAngle: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_DIRECTION_CHANGE,
      data: { direction: direction, rotate: rotate, settingAngle: settingAngle }
    };
  }

  public static motionDirectionChange(motionDirection: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_MOTION_DIRECTION_CHANGE,
      data: { motionDirection: motionDirection }
    };
  }

  public static lockRotationChange(lockRotation: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_LOCK_ROTATION_CHANGE,
      data: { lockRotation: lockRotation }
    };
  }

  public static instantDirectionChange(instantDirection: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_INSTANT_DIRECTION_CHANGE,
      data: { instantDirection: instantDirection }
    };
  }

  public static flashChanged(value: FlashMode, renderLocation?: RenderLocation): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_FLASH_CHANGED,
      data: { value: value, renderLocation: renderLocation }
    };
  }

  public static handleMoreModeTabFlashChanged(isEmitFlashChanged: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_MORE_MODE_TAB_EMIT_FLASH,
      data: { isEmitFlashChanged: isEmitFlashChanged }
    };
  }

  public static editMoreModePage(isEditMorePage: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_EDIT_MORE_PAGE,
      data: { isEditMorePage: isEditMorePage }
    };
  }


  public static showMoreModePage(isShowMorePage: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_SHOW_MORE_PAGE,
      data: { isShowMorePage: isShowMorePage }
    };
  }

  public static updateModeBar(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UPDATE_MODE_BAR,
      data: {}
    };
  }

  public static updateModePosition(withAnimate: boolean = false): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UPDATE_MODE_POS,
      data: { withAnimate: withAnimate }
    };
  }

  public static changeModePlaySound(): ActionData {
    return {
      isEvent: true,
      type: ActionType.CHANGE_MODE_PLAY_SOUND,
      data: {}
    };
  }

  public static slideDoubleStreamFromMore(): ActionData {
    return {
      isEvent: true,
      type: ActionType.MORE_MODE_SLIDER_DOUBLE_STREAM_MODE,
      data: {}
    };
  }

  public static disAbleModeBarChanged(isNeedDisShowingMode: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.DISABLE_MODE_BAR_CHANGED,
      data: { isNeedDisShowingMode: isNeedDisShowingMode }
    };
  }

  public static swipeChangeMode(swipe: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_SWIPE_CHANGE_MODE,
      data: { swipe: swipe }
    };
  }

  public static logModeChange(isOn: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_LOG_MODE_CHANGE,
      data: { isOn: isOn }
    };
  }

  public static thirdPartyCall(isThirdPartyCall: boolean, action?: string): ActionData {
    return {
      type: ActionType.ACTION_THIRD_PARTY_CALL,
      data: { isThirdPartyCall: isThirdPartyCall, action: action }
    };
  }

  // Preview
  public static onBackPress(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_BACK_PRESS,
      data: {}
    };
  }

  public static previewClicked(unLock?: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_PREVIEW_CLICKED,
      data: { unLock: unLock }
    };
  }

  public static changeXComponentSize(xComponentWidth: number, xComponentHeight: number): ActionData {
    let xComponentBias: number = 15;
    let xComponentWidthPX: number = Math.floor(vp2px(xComponentWidth));
    let xComponentHeightPX: number = Math.floor(vp2px(xComponentHeight));
    let windowWidthPX: number = 0;
    let windowHeightPX: number = 0;
    windowWidthPX = Math.ceil(vp2px(getStates().get<number>('windowReducer', 'windowWidth')));
    windowHeightPX = Math.ceil(vp2px(getStates().get<number>('windowReducer', 'windowHeight')));

    xComponentWidthPX =
      Math.abs(xComponentWidthPX - windowWidthPX) < xComponentBias ? windowWidthPX : xComponentWidthPX;
    xComponentHeightPX =
      Math.abs(xComponentHeightPX - windowHeightPX) < xComponentBias ? windowHeightPX : xComponentHeightPX;
    // 底层要求xComponent的px值是偶数
    xComponentWidth = px2vp(xComponentWidthPX % 2 === 0 ? xComponentWidthPX : xComponentWidthPX + 1);
    xComponentHeight = px2vp(xComponentHeightPX % 2 === 0 ? xComponentHeightPX : xComponentHeightPX + 1);
    return {
      isEvent: true,
      type: ActionType.ACTION_CHANGE_X_COMPONENT_SIZE,
      data: { xComponentWidth: xComponentWidth, xComponentHeight: xComponentHeight }
    };
  }

  public static pickerRemake(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_PICKER_REMAKE,
      data: {}
    };
  }

  public static updateShowPickerView(showPicker: boolean, needRestart?: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_SHOW_PICKER,
      data: { showPicker: showPicker, needRestart: needRestart }
    };
  }

  // Ui
  public static changeTimeLapse(isShowtimeLapse: boolean, timeLapseInterrupt?: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_CHANGE_TIME_LAPSE,
      data: { isShowtimeLapse: isShowtimeLapse, timeLapseInterrupt: timeLapseInterrupt }
    };
  }

  public static changeTimelapseVideoState(): ActionData {
    return {
      isEvent: true,
      type: ActionType.CHANGE_TIMELAPSE_VIDEO_STATE,
      data: {}
    };
  }

  public static updateShowBigTextFlag(isShowBigText: boolean): ActionData {
    return {
      type: ActionType.ACTION_UPDATE_SHOW_BIG_TEXT_FLAG,
      data: { isShowBigText: isShowBigText }
    };
  }

  public static updateShowNightBigTextFlag(isShowNightBigText: boolean): ActionData {
    return {
      type: ActionType.ACTION_UPDATE_SHOW_NIGHT_BIG_TEXT_FLAG,
      data: { isShowNightBigText: isShowNightBigText }
    };
  }

  public static updateShowBurstCaptureBigTextFlag(isShowBurstCaptureBigText: boolean): ActionData {
    return {
      type: ActionType.ACTION_UPDATE_SHOW_BURST_CAPTURE_BIG_TEXT_FLAG,
      data: { isShowBurstCaptureBigText: isShowBurstCaptureBigText }
    };
  }

  public static updateIsShowFootBar(isShowFootBar: boolean): ActionData {
    return {
      type: ActionType.ACTION_IS_SHOW_FOOT_BAR,
      data: { isShowFootBar: isShowFootBar }
    };
  }

  public static updateIsShowModeBar(isShowModeBar: boolean): ActionData {
    return {
      type: ActionType.ACTION_IS_SHOW_MODE_BAR,
      data: { isShowModeBar: isShowModeBar }
    };
  }

  public static updateIsShowParamBar(isShowParamBar: boolean): ActionData {
    return {
      type: ActionType.ACTION_IS_SHOW_PARAM_BAR,
      data: { isShowParamBar: isShowParamBar }
    };
  }

  public static updateIsShowExtendBar(isShowExtendBar: boolean, isBeautyTheme?: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_SHOW_EXTEND_BAR,
      data: { isShowExtendBar: isShowExtendBar, isBeautyTheme: isBeautyTheme }
    };
  }

  public static updateIsExtendBarContinuation(isExtendBarContinuation: boolean): ActionData {
    return {
      type: ActionType.ACTION_IS_EXTEND_BAR_CONTINUATION,
      data: { isExtendBarContinuation: isExtendBarContinuation }
    };
  }


  public static changeShowExtendComponent(functionId: FunctionId): ActionData {
    return {
      type: ActionType.ACTION_CHANGE_SHOW_EXTEND_COMPONENT,
      data: { extendBarEffectView: functionId }
    };
  }

  public static timeLapseSlider(rateSlider: Number, timeLapse: string): ActionData {
    return {
      isEvent: true,
      type: ActionType.TIME_LAPSE_ACTION_RATE_SLIDER,
      data: { timeLapseSlider: rateSlider, timeLapse: timeLapse }
    };
  }

  public static timeLapseCheckedIcon(checkedIcon: TimeLapseMode): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UI_CHECKED_ICON,
      data: { checkedIcon: checkedIcon }
    };
  }

  public static proBarRecoveryAuto(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_LUMATION_CHANGE_STATE,
      data: {}
    };
  }

  public static proSonChangeState(iconId: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_PROSON_CHANGE_STATE,
      data: { iconId: iconId }
    };
  }

  public static updateIsoRange(max: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UPDATE_ISO_RANGE,
      data: { max: max }
    };
  }

  public static updateSuperIsoValue(superIsoValue: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UPDATE_SUPER_ISO_VALUE,
      data: { superIsoValue: superIsoValue }
    };
  }

  public static updateIsoValue(isoValue: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UPDATE_ISO_VALUE,
      data: { isoValue: isoValue }
    };
  }

  public static updatePhotoFormat(photoFormat: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UPDATE_PHOTO_FORMAT,
      data: { photoFormat: photoFormat }
    };
  }

  public static proSonChangeView(iconId: number, ui: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_PROSON_CHANGE_VIEW,
      data: { iconId: iconId, ui: ui }
    };
  }

  public static isProShowTreasureBox(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_SHOW_TREASURE_BOX,
      data: {}
    };
  }

  public static isProHideTreasureBox(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_HIDE_TREASURE_BOX,
      data: {}
    };
  }

  public static timeLapseStart(exposureTime: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_TIME_LAPSE_CAPTURE_START,
      data: { exposureTime: exposureTime }
    };
  }

  public static timeLapseStop(exposureTime: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_TIME_LAPSE_CAPTURE_END,
      data: { exposureTime: exposureTime }
    };
  }


  public static timeLapseFrameShutter(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_TIME_LAPSE_FRAME_SHUTTER,
      data: {}
    };
  }

  public static isEnterImmersive(isImmersive: boolean, mainTrigCompo: UIOperationType): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_ENTER_IMMERSIVE,
      data: { isImmersive: isImmersive, mainTrigCompo: mainTrigCompo }
    };
  }

  public static handleZoomVibrator(effectId: string, usage: string): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_HANDLE_ZOOM_VIBRATOR,
      data: { effectId: effectId, usage: usage }
    };
  }

  public static stopZoomVibrator(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_STOP_ZOOM_VIBRATOR,
      data: {}
    };
  }

  public static isShowWatermarkPage(isShowWatermarkPage: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_SHOW_WATERMARK_PAGE,
      data: { isShowWatermarkPage: isShowWatermarkPage }
    };
  }

  public static isShowWatermarkParamsPage(isShow: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_SHOW_WATERMARK_PARAM_PAGE,
      data: { isShow: isShow }
    };
  }

  // Setting

  /********** NEW UI REMAKE END **********/
  public static updateIsShowShutterView(isShowShutterView: boolean): ActionData {
    return {
      type: ActionType.ACTION_IS_SHOW_SHUTTER_VIEW,
      data: { isShowShutterView: isShowShutterView }
    };
  }

  public static nightCaptureStart(exposureTime: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_NIGHT_CAPTURE_START,
      data: { exposureTime: exposureTime }
    };
  }

  public static estimatedCaptureDuration(estimatedCaptureDuration: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ESTIMATED_CAPTURE_DURATION,
      data: { estimatedCaptureDuration: estimatedCaptureDuration }
    };
  }

  public static isResetExposureTime(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_RESET_EXPOSURE_TIME,
      data: { exposureTime: 0 }
    };
  }

  public static confirmCaptureEffect(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_CONFIRM_CAPTURE_EFFECT,
      data: {}
    };
  }

  public static captureEnd(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_NIGHT_CAPTURE_END,
      data: {}
    };
  }

  public static delaySendCaptureEnd(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_DELAY_SEND_CAPTURE_END,
      data: {}
    };
  }

  public static nightFrameShutter(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_NIGHT_FRAME_SHUTTER,
      data: {}
    };
  }

  public static longExposureShutterEnd(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_LONG_EXPOSURE_SHUTTER_END,
      data: {}
    };
  }

  public static normalFrameShutter(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_NORMAL_FRAME_SHUTTER,
      data: {}
    };
  }

  public static longExposureShutter(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_LONG_EXPOSURE_SHUTTER,
      data: {}
    };
  }

  public static countDownShutter(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_COUNT_DOWN_SHUTTER,
      data: {}
    };
  }

  public static countDownShutterEnd(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_COUNT_DOWN_SHUTTER_END,
      data: {}
    };
  }

  public static countDownShutterAfterTimelapse(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_COUNT_DOWN_SHUTTER_AFTER_TIMELAPSE,
      data: {}
    };
  }

  public static savePickerFile(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_SAVE_PICKER_FILE,
      data: {}
    };
  }

  public static updateRecordUselessTime(uselessSeconds: number): ActionData {
    return {
      type: ActionType.ACTION_RECORD_USELESS_SECONDS,
      data: { uselessSeconds: uselessSeconds }
    };
  }

  public static uiState(enable: boolean): ActionData {
    return {
      type: ActionType.ACTION_UI_STATE,
      data: { enable: enable, uiStateMode: UiStateMode.NONE }
    };
  }

  public static uiStateWithMode(enable: boolean, uiStateMode: UiStateMode, excludeComponent?: string): ActionData {
    return {
      type: ActionType.ACTION_UI_STATE,
      data: { enable: enable, uiStateMode: uiStateMode, excludeComponent: excludeComponent }
    };
  }

  public static sendTimeLapseAuto(autoType: number): ActionData {
    return {
      type: ActionType.ACTION_LAPSE_AUTO,
      data: { autoType: autoType },
      isEvent: true
    };
  }

  public static sendTimeLapseOpen(isOpen: boolean): ActionData {
    return {
      type: ActionType.ACTION_TIME_LAPSE_OPEN,
      data: { isOpen: isOpen },
      isEvent: true
    };
  }

  public static sendKeepTime(keepTime: number): ActionData {
    return {
      type: ActionType.ACTION_LAPSE_KEEP_TIME,
      data: { keepTime: keepTime },
      isEvent: true
    };
  }

  public static sendInterval(interval: number): ActionData {
    return {
      type: ActionType.ACTION_LAPSE_INTERVAL,
      data: { interval: interval },
      isEvent: true
    };
  }

  public static sendIntervalType(intervalType: number): ActionData {
    return {
      type: ActionType.ACTION_LAPSE_INTERVAL_TYPE,
      data: { intervalType: intervalType },
      isEvent: true
    };
  }

  public static assistiveGridView(isAssGridViewShow: boolean): ActionData {
    return {
      type: ActionType.ACTION_ASSISTIVE_GRID_VIEW,
      data: { isAssGridViewShow: isAssGridViewShow }
    };
  }

  public static smartBackSelfie(isSmartBackSelfie: boolean): ActionData {
    return {
      type: ActionType.ACTION_SMART_BACK_SELFIE,
      data: { isSmartBackSelfie: isSmartBackSelfie }
    };
  }

  public static realTimeFilterIsOpen(isOpenFilter: boolean): ActionData {
    return {
      type: ActionType.ACTION_IS_OPEN_FILTER,
      data: { isOpenFilter: isOpenFilter }
    };
  }

  public static aigcEnhanceView(isAigcEnhance: boolean): ActionData {
    return {
      type: ActionType.ACTION_AIGC_ENHANCE,
      data: { isAigcEnhance: isAigcEnhance }
    };
  }

  public static lightPaintingFlashView(isLightPaintingFlashShow: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_LIGHT_PAINTING_FLASH,
      data: { isLightPaintingFlashShow: isLightPaintingFlashShow }
    };
  }

  public static nightRefreshTreasure(nightSubRefreshTreasure: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_NIGHT_SUB_REFRESH_TREASURE,
      data: { nightSubRefreshTreasure: nightSubRefreshTreasure }
    };
  }

  public static nightStarPortraitFlashView(isNightStarPortraitFlashShow: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_NIGHT_STAR_PORTRAIT_FLASH,
      data: { isNightStarPortraitFlashShow: isNightStarPortraitFlashShow }
    };
  }

  public static floatingShutterButton(isFloatingShutterShow: boolean): ActionData {
    return {
      type: ActionType.ACTION_FLOATING_SHUTTER_BUTTON,
      data: { isFloatingShutterShow: isFloatingShutterShow }
    };
  }

  public static updateCollaborationPhotoInfo(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UPDATE_COLLABORATION_PHOTO_INFO,
      data: {}
    };
  }

  public static updateXComponentShot(oldMode: ModeType, newMode: ModeType, isShowBigText: boolean = true,
    oldOutputType?: OutputType,
    newOutputType?: OutputType): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_PREVIEW_SHOT_COMPONENT,
      data: {
        oldMode,
        newMode,
        oldOutputType,
        newOutputType,
        isShowBigText
      }
    };
  }

  public static onPreviewFrameStart(isPreviewFrameStart: boolean, isToGallery?: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_PREVIEW_FRAME_START,
      data: { isPreviewFrameStart: isPreviewFrameStart, isToGallery: isToGallery }
    };
  }

  public static onCollaboratePreviewFrameStart(isPreviewFrameStart: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_COLLABORATE_PREVIEW_FRAME_START,
      data: { isPreviewFrameStart: isPreviewFrameStart }
    };
  }

  // 锁屏相机
  public static updateIsSecurityCamera(isSecurityCamera: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_SECURITY_CAMERA,
      data: { isSecurityCamera: isSecurityCamera }
    };
  }

  public static setCameraShotKey(cameraShotKey: string): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_CAMERA_SHOT_KEY,
      data: { cameraShotKey: cameraShotKey }
    };
  }

  public static closeSettingDialog(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_CLOSE_SETTING_DIALOG,
      data: {}
    };
  }

  public static showThumbnailReminder(thumbnailReminderShow: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_THUMBNAIL_REMINDER_SHOW,
      data: { thumbnailReminderShow: thumbnailReminderShow }
    };
  }

  public static showAppLockReminder(appLockReminderShow: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_APP_LOCK_REMINDER_SHOW,
      data: { appLockReminderShow: appLockReminderShow }
    };
  }

  public static onSketchStatusChanged(status: number, sketchRatio: number,
    centerPointOffset?: camera.Point): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_SKETCH_STATUS_CHANGED,
      data: { status: status, sketchRatio: sketchRatio, centerPointOffset: centerPointOffset }
    };
  }


  public static onIsoStatusChanged(duration: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_ISO_STATUS_CHANGED,
      data: { duration: duration }
    };
  }

  public static onApertureStatusChanged(duration: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_APETURE_STATUS_CHANGED,
      data: { duration: duration }
    };
  }

  // @ts-ignore
  public static onApertureEffectChange(effect: camera.ApertureEffect): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_APERTURE_EFFECT_CHANGE,
      data: { apertureEffect: effect }
    };
  }

  public static onLuminationStatusChanged(info: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_LUMINATION_STATUS_CHANGED,
      data: { info: info }
    };
  }

  public static onProfessionShutterStatusChanged(duration: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_PROFESSION_SHUTTER_STATUS_CHANGED,
      data: { duration: duration }
    };
  }

  public static onAbilityStatusChanged(isoRange: number[], ApertureRange: camera.PhysicalAperture[]): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_PROFESSION_ABILITY_STATUS_CHANGED,
      data: { isoRange: isoRange, ApertureRange: ApertureRange }
    };
  }

  public static addPipSurface(pipSurfaceId: string): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ADD_PIP_SURFACE_ID,
      data: { pipSurfaceId: pipSurfaceId }
    };
  }

  public static isRequestPermission(isRequestPermission: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_REQUEST_PERMISSION,
      data: { isRequestPermission: isRequestPermission }
    };
  }

  public static sendPermissionState(permissionState: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_SEND_PERMISSION_STATE,
      data: { permissionState: permissionState }
    };
  }

  public static powerKeyDownDurationOneSecond(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_POWER_KEY_DURATION_ONE_SECOND,
      data: {}
    };
  }

  public static audioControlShutterButton(data: {
    isPicker?: boolean, dbValue: number,
    dbThreshold?: number, dbStateList?: number[]
  }): ActionData {
    return {
      isEvent: true,
      type: ActionType.AUDIO_CONTROL_SHUTTER_BUTTON,
      data: {
        isPicker: data.isPicker || false,
        dbValue: data.dbValue,
        dbThreshold: data.dbThreshold,
        dbStateList: data.dbStateList
      }
    };
  }

  public static hideThumbnailAndSwitchButton(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_HIDE_BUTTON,
      data: {}
    };
  }

  public static changeResolution(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_CHANGE_RESOLUTION,
      data: {}
    };
  }

  public static updateAspectRatio(ratioVal: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UPDATE_ASPECT_RATIO,
      data: { val: ratioVal }
    };
  }

  public static isUpdateAspectRatio(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_UPDATE_ASPECT_RATIO,
      data: {}
    };
  }

  public static updateVideoResolution(resolutionVal: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UPDATE_VIDEO_RESOLUTION,
      data: { val: resolutionVal }
    };
  }

  public static showExitFlashDialog(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_SHOW_EXIT_FLASH_DIALOG,
      data: {}
    };
  }

  public static showExitCameraDialog(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_SHOW_EXIT_CAMERA_DIALOG,
      data: {}
    };
  }

  public static isPanoramaBtnStatus(isPanoramaBtnStatus: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_PANORAMA_BTN_STATUS,
      data: { isPanoramaBtnStatus: isPanoramaBtnStatus }
    };
  }

  public static startPanorama(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_START_PANORAMA,
      data: {}
    };
  }

  public static stitchingCaptureStart(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_START_STITCHING_CAPTURE,
      data: {}
    };
  }

  public static stitchingCaptureEnd(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_END_STITCHING_CAPTURE,
      data: {}
    };
  }

  public static stitchingCaptureFinish(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_FINISH_STITCHING_CAPTURE,
      data: {}
    };
  }

  public static startPanoramaShutterButton(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_START_PANORAMA_SHUTTER_BUTTON,
      data: {}
    };
  }

  public static startStitchingShutterButton(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_START_STITCHING_SHUTTER_BUTTON,
      data: {}
    };
  }

  public static endPanorama(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_END_PANORAMA,
      data: {}
    };
  }

  public static showLowBatteryExitFlashDialog(isFlashEnable: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_LOW_BATTERY_SHOW_EXIT_FLASH_DIALOG,
      data: { isFlashEnable: isFlashEnable }
    };
  }

  public static isPanoramaToast(isPanoramaToastInfo: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_IS_TOAST_PANORAMA,
      data: { isPanoramaToastInfo: isPanoramaToastInfo }
    };
  }

  public static panoramaToastTextInfo(toastTextInfo: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_TOAST_TEXT_INFO_PANORAMA,
      data: { textInfo: toastTextInfo }
    };
  }

  public static onPanoramaPhotoStop(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_PHOTO_STOP_PANORAMA,
      data: {}
    };
  }

  public static onBackPressPanoramaStop(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_BACK_PRESS_STOP_PANORAMA,
      data: {}
    };
  }

  public static onBackPressStitchingStop(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_BACK_PRESS_STOP_STITCHING,
      data: {}
    };
  }

  public static onStitchingRestore(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_ON_STITCHING_RESTORE,
      data: {}
    };
  }

  public static showLightPaintingDialog(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_SHOW_LIGHT_PAINTING_DIALOG,
      data: {}
    };
  }

  public static getTimeLapseIntervalRange(range: number[]): ActionData {
    return {
      type: ActionType.ACTION_GET_TIME_LAPSE_INTERVAL_RANGE,
      data: { intervalRange: range },
      isEvent: true
    };
  }

  public static panoramaProgressResult(width: number, height: number, x: number, y: number,): ActionData {
    return {
      isEvent: true,
      type: ActionType.PANORAMA_PROGRESS_RESULT,
      data: {
        width: width,
        height: height,
        x: x,
        y: y
      },
    };
  }

  public static panoramaResult(): ActionData {
    return {
      isEvent: true,
      type: ActionType.PANORAMA_RESULT,
      data: {},
    };
  }

  public static handleOnceToast(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_HANDLE_ONCE_TOAST,
      data: {},
    };
  }

  public static handleEyeTipAnim(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_EYE_TIP_ANIM,
      data: {},
    };
  }

  public static clearPageOrDialog(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_CLEAR_PAGE_OR_DIALOG,
      data: {}
    };
  }

  public static switchCameraChangeModeOnly(cameraPosition: camera.CameraPosition, mode: ModeType): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_SWITCH_CAMERA_CHANGE_MODE_ONLY,
      data: { cameraPosition: cameraPosition, mode: mode }
    };
  }

  public static updateGlobalExposure(value: number): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UPDATE_GLOBAL_EXPOSURE_VALUE,
      data: { globalExposureValue: value }
    };
  }

  public static checkCurrentDirection(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_CHECK_CURRENT_DIRECTION,
      data: {}
    };
  }

  public static loadPhotoBrowser(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_LOAD_PHOTO_BROWSER,
      data: {}
    };
  }

  public static pickerDpiChange(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_PICKER_DPI_CHANGE,
      data: {}
    };
  }

  public static lightStatueChange(lightStatus: camera.LightStatus): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_LIGHT_STATUS_CHANGE,
      data: { lightStatus: lightStatus }
    };
  }

  public static updateSmartControlSwitchState(smartControlSwitchStatus: SmartControlSwitchStatus): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UPDATE_SMART_CONTROL_SWITCH_STATE,
      data: { ...smartControlSwitchStatus }
    };
  }

  public static showPipSurfaceChange(isShow: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_SHOW_PIP_SURFACE_CHANGE,
      data: { isShow: isShow }
    };
  }

  public static updateHdrState(isHdrOpen: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UPDATE_HDR_STATE,
      data: { isHdrOpen: isHdrOpen }
    };
  }

  public static updateExtendBarPosition(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_UPDATE_EXTEND_BAR_POSITION,
      data: {}
    };
  }

  public static updateHDR(isOpen: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_SUPPORT_HDR_BRIGHTNESS,
      data: { isOpen: isOpen }
    };
  }

  public static introConfirm(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_INTRO_CONFIRM,
      data: {}
    };
  }

  /**
   * 间隔定时拍的change方法
   * @param isShowTimedShot
   * @param timedShotInterrupt
   * @returns ActionData
   * */
  public static changeTimedShot(isShowTimedShot: boolean, timedShotInterrupt?: boolean): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_CHANGE_TIMED_SHOT,
      data: { isShowTimedShot: isShowTimedShot, timedShotInterrupt: timedShotInterrupt }
    };
  }

  /**
   * 拍摄后的快门
   * @returns ActionData
   * */
  public static countDownShutterAfterTimedShot(): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_COUNT_DOWN_SHUTTER_AFTER_TIMED_SHOT,
      data: {}
    };
  }
}