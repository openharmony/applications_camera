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

import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';

export const SETTING_MENU_PHOTO_ORDER = [
  FunctionId.ASPECT_RATIO,
];

export const SETTING_MENU_VIDEO_ORDER = [
  FunctionId.VIDEO_RESOLUTION,
  FunctionId.FRAME_RATE,
  FunctionId.EFFICIENT_VIDEO,
];

export const SETTING_MENU_COMMON_ORDER = [
  FunctionId.ASSISTIVE_GRID,
  FunctionId.HORIZONTAL_LEVEL,
  FunctionId.TIME_LAPSE,
  FunctionId.TIMED_SHOT,
  FunctionId.MIRROR,
  FunctionId.SAVE_GEO_LOCATION,
  FunctionId.SOUND_MUTE,
  FunctionId.FLOATING_SHUTTER
];