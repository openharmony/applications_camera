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

export enum ZoomStateType {
  QUICK_ZOOM = 'QUICK_ZOOM',
  RING_ZOOM = 'RING_ZOOM',
  COEXISTENCE_ZOOM = 'COEXISTENCE_ZOOM',
}

// 变焦状态内部生命周期
export enum ZoomInnerStatus {
  NONE = 'NONE',
  QUICK_STATIC = 'QUICK_STATIC',
  QUICK_CLICK = 'QUICK_CLICK',
  FRONT_QUICK_SLIDE = 'FRONT_QUICK_SLIDE', // 前置摄像头时，滑动快捷变焦点时切换快捷变焦值
  QUICK_TO_ROULETTE = 'QUICK_TO_ROULETTE',
  ROULETTE_SLIDE = 'ROULETTE_SLIDE',
  ROULETTE_CLICK = 'ROULETTE_CLICK',
  ROULETTE_STATIC = 'ROULETTE_STATIC',
  ROULETTE_TO_QUICK = 'ROULETTE_TO_QUICK',
  PINCH_ZOOM = 'PINCH_ZOOM',
}

// 变焦外部生命周期
export enum ZoomOuterStatus {
  NONE = 'NONE',
  QUICK_ZOOM = 'QUICK_ZOOM',
  ROULETTE_ZOOM = 'ROULETTE_ZOOM',
  PINCH_ZOOM = 'PINCH_ZOOM',
}