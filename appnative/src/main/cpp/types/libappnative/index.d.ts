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

import { DrawContext } from '@ohos.arkui.node';

export const initNode: (id: number, width: number, height: number, drawHeight: number,
  collapsStatus: number, directionAngle: number, densityPixels: number,
  quickZoomValArr: number[], quickEquivalentFocalArr: number[],
  opticalZoomValArr: number[], opticalZoomDotIndexArr: number[], cycleClickZoomArr: number[]) => void;

export const updateDirection: (direction: number) => void;

export const setCameraAppCapabilityParams: (isNovaProduct: boolean, isSupport: boolean,
  isSupportedCycleClickZoom: boolean) => void;

export const execLandscapeSlideAnim: (zoomIndex: number, displacementDistance: number, animType: number) => void;

export const onDraw: (id: number, context: DrawContext, curZoomVal: number, curZoomAngle: number,
  animParam?: EntryExitAnimParam) => void;

export interface EntryExitAnimParam {
  longCurveHaloMatteScale?: number; // 光晕动效参数
  longCurveHaloOpacity?: number;
  spherePosition?: number; // 光球参数
  sphereScale?: number;
  sphereColor?: number;
  sphereHaloOpacity?: number; // 光球光晕参数
  redLineAndTextOpacity?: number; // 焦圈中心刻度参数
  scaleAllMatteScale?: number; // 焦圈参数
  scaleAllOpacity?: number;
  carmenLineMatteScale?: number; // 卡门线参数
  carmenLineOpacity?: number;
  animType?: AnimType; // 动效类型
}

export enum AnimType {
  NONE_ANIM = 0,
  APPEAR_ANIM = 1,
  DISAPPEAR_ANIM = 2,
}

