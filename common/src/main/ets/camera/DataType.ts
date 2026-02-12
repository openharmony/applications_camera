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

import type camera from '@ohos.multimedia.camera';
import type { ModeType } from '../mode/ModeType';
import type media from '@ohos.multimedia.media';
import lazy { OutputType } from '../function/outputswitcher/OutputType';
import type { ZoomPointInfo } from '../function/zoombar/ZoomParam';
import lazy { FunctionId } from '../function/core/functionproperty/FunctionId';
import lazy { common } from '@kit.AbilityKit';
import lazy { LogStyleMode } from '../function/enumbase/LogStyleMode';
import lazy { LocationMessage } from '../service/location/LocationMessage';
import { PickerInfo, PreviewRotationInfo } from '../utils/types';

export type CameraInputMessage = {
  cameraPosition: camera.CameraPosition;
  mode: ModeType;
  cameraType?: camera.CameraType;
  zoomValue?: number;
};

export type PreviewOutputMessage = {
  previewSurfaceId: string;
  previewProfile: camera.Profile;
  collaborateSurfaceId?: string;
  xComponentSurfaceId?: string;
};


export type PhotoOutputMessage = {
  photoProfile: camera.Profile;
};

export type VideoOutputMessage = {
  videoProfile: camera.VideoProfile;
  isMovie?: boolean;
  config?: media.AVRecorderConfig;
  filter?: string;
  isPreRecord?: boolean;
  mirrorValue?: boolean;
  isSupportVideoEdit?: boolean;
  isSupportVideoWatermark?: boolean;
  isAddFilter?: boolean;
  isAddWaterMark?: boolean;
  isAutoFrameRate?: boolean;
  isFlowingVideo?: boolean;
  preferencesMirror?: boolean;
  keepVideoFlowing?: boolean;
  isVideoRotation?: boolean;
  isSupportFrontWaterMark?: boolean;
  isInSwipeRecording?: boolean;
};

export type PreviewRecordOutputMessage = {
  config: media.AVRecorderConfig;
  isAddWaterMark?: boolean;
  isSupportFrontWaterMark?: boolean;
};

export type TimeLapseRecordOutputMessage = {
  config: media.AVRecorderConfig;
  isAddWaterMark?: boolean;
};

export type TimeLapseRecordMessage = {
  captureInterval: number;
  isSpeedAuto: boolean;
  isFrontMirror: boolean;
  isAddWaterMark: boolean;
  isLandScapeFront: boolean;
  rotation: number;
  direction: number;
  isLockRotation: boolean;
  locationMessage?: LocationMessage
};

export type MetadataOutputMessage = {
  metadataObjectTypeArr: camera.MetadataObjectType[];
};


export type TagMessage = {
  mode?: ModeType;
  zoomRatio?: number;
  aspectRatio?: number;
  pipSurface?: string;
  realTimeLapseValue?: string;
  isP3Flag?: boolean;
  isDynamicFrameRate?: number;
  videoResolution?: number;
  frameRate?: number;
  outputType?: OutputType;
  isMirror?: boolean;
  savePhotoFormat?: camera.CameraFormat;
  isProRawDelivery?: boolean;
  isOperationEmotion?: boolean;
  isBackSelfie?: boolean;
  isUltraSnapshot?: boolean;
  pickerInfo?: PickerInfo;
  globalExposure?: number;
  isScanCodeAvailable?: boolean;
  supportOnlyShowEye?: boolean;
  nightSubModeType?: number;
  isOpenLogStyle?: LogStyleMode;
  vlogIndex?: number;
  isLogAssistanceOn?: boolean;
  isCloseBFrame?: boolean;
  previewRotationInfo?: PreviewRotationInfo;
  usedAsPositionValue?: camera.CameraPosition;
  messageContext?: common.ExtensionContext | common.UIAbilityContext; // context必现作为最后一项,序列化对象超长阻塞其它日志
  isHdrVividFlag?: boolean;
};

export type SessionMessage = {
  cameraInputMessage: CameraInputMessage;
  previewOutputMessage: PreviewOutputMessage;
  collaborateControlPreviewOutputMessage: PreviewOutputMessage;
  photoOutputMessage: PhotoOutputMessage;
  videoOutputMessage: VideoOutputMessage;
  timelapseOutputMessage: TimeLapseRecordOutputMessage;
  superMacroEnable?: boolean;
  metadataOutputMessage: MetadataOutputMessage;
  tagMessage: TagMessage; // tagMessage必现作为最后一项,序列化context对象超长阻塞其它日志
};

// appMode to cameraMode 时的补充信息
export type App2CameraModeMessage = {
  outputType?: OutputType;
  isSuperSlowMotion?: boolean;
};

export type CloseInfoToWork = {
  mode: ModeType;
  isNeedSaveRestore?: boolean;
  isLegalSaveRestore?: boolean;
  isNeedDelayClose?: boolean;
  isPcEnterSleep?: boolean;
};

export enum RestartPreviewType {
  CHANGE_MODE = 'CHANGE_MODE',
  CHANGE_OUTPUT_TYPE = 'CHANGE_OUTPUT_TYPE',
  SWITCH_CAMERA = 'SWITCH_CAMERA',
  CHANGE_MODE_AND_SWITCH_CAMERA = 'CHANGE_MODE_AND_SWITCH_CAMERA',
  CHANGE_ASPECT_RATIO = 'CHANGE_ASPECT_RATIO',
  CHANGE_PHYSICAL_CAMERA = 'CHANGE_PHYSICAL_CAMERA',
}

export enum CaptureFailedType {
  THUMBNAIL = 0,
  REAL_IMAGE = 1
}

export type TabBarAnimationType = {
  isActivelyDoTransAnim: boolean,
};

export type TabBarPlayLottieType = {
  isClicked: boolean,
  functionId: FunctionId,
};

export type SessionInfo = {
  canAddOutput: boolean,
  hasFlash: boolean;
  zoomRatioRange: number[];
  isDeferPhoto: boolean;
  zoomPointInfo: ZoomPointInfo;
  virtualApertures: number[];
  physicalApertures: camera.PhysicalAperture[];
  focusDistance: number;
  // @ts-ignore
  defaultColorStyles: camera.ColorStyleSetting[];
  timeLapseIntervalRange: number[];
  isVideoMirrorSupported: boolean;
  isQuickThumbnailSupported: boolean;
  isAutoVideoFrameRateSupported: boolean;
  isPreRecordingSupported: boolean;
  isCompositionSuggestionSupported: boolean;
  isLogAssistanceSupported?: boolean;
  enableLogAssistance?: boolean;
};

export type MotionData = {
  motionValue?: number,
};

export interface LightResult {
  lightStatus: number;
}

export enum LightStatus {
  DEFAULT = -1,
  NORMAL = 0, // 光线正常
  INSUFFICIENT = 1 // 光线不足
}

export class PhotoBrowserStatusData {
  public photoBrowserStatus: boolean = false;
  public isTriggeredByBack: boolean = false;
}

export type PipSurfaceData = {
  isShow: boolean;
};

export interface CustomFilterCardStateData {
  isPreviewScaled: boolean;
}

export interface AspectRatioData {
  val: number;
}