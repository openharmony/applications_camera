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

import type { FunctionId } from '../function/core/functionproperty/FunctionId';
import type { UIOperationType } from '../component/uicomponent/UIOperationType';
import type window from '@ohos.window';
import type { SessionInfo } from '../camera/DataType';
import type { camera } from '@kit.CameraKit';
import type { RenderLocation } from '../function/core/functionproperty/RenderLocation';
import type { image } from '@kit.ImageKit';
import type { ThumbnailUpdateScene } from '../component/thumbnail/ThumbnailAction';
import lazy { AuxiliaryMode } from '../function/enumbase/AuxiliaryMode';
import lazy { FlashMode } from '../function/enumbase/FlashMode';
import lazy { ModeType } from '../mode/ModeType';
import lazy { ExposureData, FocusData } from '../component/focusExposure/FocusExposureHelper';

export type Size = {
  width: number,
  height: number
};

export type PositionType = {
  x: number,
  y: number
};

export class DirectionType {
  public direction: number = 1;
}

export class Point {
  x: number;
  y: number;
}
;

export enum LightPaintingType {
  CAR = 0, // 车水马龙
  LIGHT = 3, //光绘涂鸦
  WATER = 2, // 丝绢流水
  STAR = 1, // 绚丽星轨
}

export enum LightPaintingCaptureState {
  READY = 0, // 拍摄前
  STARTING = 1, // 准备开始拍摄
  CAPTURING = 2, // 拍摄中
  STOPPING = 3, // 准备结束拍摄
}

export type XComponentSize = {
  xComponentWidth: number,
  xComponentHeight: number
};

export type FunctionValueType = {
  id: FunctionId;
  value: unknown | Record<string, unknown>;
  renderLocation?: RenderLocation;
};

export interface ThumbnailStruct {
  thumbnail: image.PixelMap | undefined,
  scene: ThumbnailUpdateScene;
}

export type PickerPhotoData = {
  photo: image.PixelMap | undefined
}

export type SwipeChangeNumberData = {
  swipe: number;
};

export type OnModeData = {
  isOn: boolean;
};

export type ImmersiveActionData = {
  isShowtimeLapse?: boolean,
  isImmersive?: boolean,
  mainTrigCompo?: UIOperationType,
  isShowTimedShot?: boolean,
};

export type WindowEventData = {
  windowStageEventType: window.WindowStageEventType;
};

export type WindowVisibilityData = {
  windowStageVisibilityType: boolean;
};

export type CollaborateControlModeType = {
  mode: ModeType;
};

export interface CollaborationFdData {
  sandboxFd: number;
  sandboxPath: string;
}

export interface PhotoInfoStruct {
  imageFd: number;
  errorCode: number;
}

export interface StartRecordResultType {
  sessionMessage: SessionInfo;
  isSuccess: boolean;
}

export type proSonChangeNumberData = {
  iconId: number;
};

export type ChangeNumberData = {
  duration: number;
};

export type AbilityChangeData = {
  isoRange: number[];
  ApertureRange: camera.PhysicalAperture[]
};

export type proSonChangeViewData = {
  iconId: number;
  ui: number;
};


export type SavePowerModeActionData = {
  isDuringSavePowerMode: boolean;
};

export type WindowStatusChangeActionData = {
  windowStatus: window.WindowStatusType,
  windowPreStatus: window.WindowStatusType
};

export type ValueType = number | string | boolean;

export type StringResourceType = (string | Resource)[];

export type WithAnimateType = {
  withAnimate: boolean
};

export interface PickerInfo {
  isPicker: boolean,
  uri?: string,
  callingTokenID: number,
  callerPid: number
}

export interface PreviewRotationInfo {
  isNeedSetPreviewRotation: boolean;
  previewRotation?: camera.ImageRotation;
  isDisplayLocked?: boolean
}

export interface PreviewFrameStartData {
  isPreviewFrameStart: boolean;
  isToGallery: boolean;
}

export class AbilityBackgroundData {
  public isPickerBack: boolean = false;
}

export type EnumType = AuxiliaryMode | FlashMode | FocusData | AuxiliaryMode | ExposureData | LightPaintingType |
camera.ColorEffectType |
// @ts-ignore
FunctionId | camera.NightSubModeType;

export enum PhotoBrowserFlowType { // 相机进大图场景流类型
  CLOSE = 0, // 进大图后close状态
  CAMERA_STEADY_FLOW = 1, // 正常流稳态
  BROWSER_NOT_FULL_TRANSIENT = 2, // 大图处于非全屏悬浮时启流暂态(仅用于暂态,回相机后重新标记为1)
}

export interface Fail {
  isFail: boolean;
  failReason?: string;
}