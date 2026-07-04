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
import lazy { ModeType } from '../../mode/ModeType';
import camera from '@ohos.multimedia.camera';
import lazy { DurationType } from '../tip/TipService';

// value： 内容为[后置，前置] 或者 [**拍照， **录像]
export interface FocusConfig {
  isFocusExposureRingSupported: boolean[], // 是否支持对焦 + 测光分离  - 长按
  isFocusLockExposureSupported: boolean[], // 是否支持对焦锁定 + 测光可调  -  长按
  isOnlyFocusLockSupported: boolean[], // 是否仅支持对焦锁定  -  长按

  isOnlyFocusSupported: boolean[], // 是否仅支持对焦  - 短按
};

export const EXPOSURE_RING_LENGTH_20: number = 20;
export const FOCUS_EXPOSURE_GAP: number = 2;
export const SUPER_ISO_THRESHOLD_VALUE: number = 12800;
export const VLOG_FOCUS_DATA_LENGTH: number = 5;

export type PositionType = {
  x: number,
  y: number
};

export interface EventOffsetInfos {
  offsetX: number,
  offsetY: number,
};

interface FingerInfo {
  // displayX: number,
  // displayY: number,
  globalX?: number,
  globalY?: number,
  windowX?: number,
  windowY?: number,
}

interface ChangedTouches {
  // displayX: number,
  // displayY: number,
  globalX?: number,
  globalY?: number,
  windowX?: number,
  windowY?: number,
};

export interface Event {
  fingerList?: FingerInfo[],
  changedTouches?: ChangedTouches[],
  fromWatchTouch?: boolean;
}

export type RangeInfo = [number, number, number, number]; // [预览起点，预览终点，起点以下不可点击区域，终点内不可以点击区域]

export interface Ranges {
  x: RangeInfo,
  y: RangeInfo
}

export interface EventEffectiveInfo {
  isEffective: boolean;
  focusPosition: PositionType;
  exposurePosition: PositionType;
}

export type FocusData = {
  focusMode: number;
  focusPoint?: camera.Point;
  focusValue?: number;
  isParamSetting?: boolean; // 来自参数设置的数据 专业模式/超级微距模式/也是摄影模式
};

export type ExposureData = {
  exposureMode: camera.ExposureMode,
  exposurePoint?: camera.Point,
  exposureValue: number,
  isParamSetting?: boolean,
};

export enum LockLevel {
  UNLOCK = 0, // 解锁
  TEMPORARY_LOCK = 1, // 短暂锁定（3s）
  FOCUS_LOCK = 2, // （曝光和）对焦锁定 -- 录像的曝光和对焦锁定 以及 流光快门的对焦锁定
  FOCUS_EXPOSURE_LOCK = 3, // 测光分离场景
  LOCK_PAUSE = 4, // 锁定状态暂停， 如1+滑动小太阳；2+滑动小太阳；3+滑动测光；智拍键锁定 + 1/2/3
}

export interface TipInfo {
  tipText: Resource,
  tipDuring: DurationType,
}

// ============================常量/配置==========================
export const FOCUS_SIZE: number = 80;
export const CANVAS_WIDTH: number = 44;
export const CANVAS_HEIGHT: number = 120;
export const EXPOSURE_ICON_SIZE: number = 24;// 滑动图标size

export const ModeFocusConfig: Map<ModeType, FocusConfig> = new Map([
  [ModeType.PHOTO, {
    isFocusExposureRingSupported: [true, true],
    isOnlyFocusLockSupported: [false, false],
    isFocusLockExposureSupported: [false, false],
    isOnlyFocusSupported: [false, false]
  }],
  [ModeType.VIDEO, {
    isFocusExposureRingSupported: [false, false],
    isOnlyFocusLockSupported: [false, false],
    isFocusLockExposureSupported: [true, true],
    isOnlyFocusSupported: [false, false]
  }],
]);