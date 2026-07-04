/*
 * Copyright (c) Huawei Device Co., Ltd. 2023-2025. All rights reserved.
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

import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';

export class PhotoModeParam {
  public readonly phoneFunctions: Map<FunctionId, RenderLocation[]> = new Map([
    [FunctionId.CAPTURE, [RenderLocation.NONE]],
    [FunctionId.ZOOM, [RenderLocation.NONE]],
    [FunctionId.FLASH, [RenderLocation.TREASURE_BOX, RenderLocation.TAB_BAR_LEFT]],
    [FunctionId.FOCUS, [RenderLocation.NONE]],
    [FunctionId.EXPOSURE, [RenderLocation.NONE]],
    [FunctionId.ASSISTIVE_GRID, [RenderLocation.TREASURE_BOX, RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.HORIZONTAL_LEVEL, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.TIME_LAPSE, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.MIRROR, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.CAMERA_SWITCHER, [RenderLocation.NONE]],
    [FunctionId.SAVE_GEO_LOCATION, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.SOUND_MUTE, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.ASPECT_RATIO, [RenderLocation.TREASURE_BOX, RenderLocation.SETTING_MENU_PHOTO]],
    [FunctionId.VIDEO_RESOLUTION, [RenderLocation.SETTING_MENU_VIDEO]],
    [FunctionId.FRAME_RATE, [RenderLocation.SETTING_MENU_VIDEO]],
    [FunctionId.EFFICIENT_VIDEO, [RenderLocation.SETTING_MENU_VIDEO]],
    [FunctionId.SETTING, [RenderLocation.TREASURE_BOX]],
    [FunctionId.DIRECTION, [RenderLocation.NONE]],
    [FunctionId.FLOATING_SHUTTER, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.TIMED_SHOT, [RenderLocation.SETTING_MENU_COMMON]],
  ]);

  public readonly vdeCollapsedFunctions: Map<FunctionId, RenderLocation[]> = new Map([
    [FunctionId.ASPECT_RATIO, [RenderLocation.TREASURE_BOX]],
    [FunctionId.EFFICIENT_VIDEO, [RenderLocation.SETTING_MENU_VIDEO]],
    [FunctionId.TIME_LAPSE, [RenderLocation.TREASURE_BOX]],
    [FunctionId.DIRECTION, [RenderLocation.NONE]],
    [FunctionId.SAVE_GEO_LOCATION, [RenderLocation.SETTING_MENU_COMMON]],
  ]);

  public readonly tabletFunctions: Map<FunctionId, RenderLocation[]> = new Map([
    [FunctionId.CAPTURE, [RenderLocation.NONE]],
    [FunctionId.ZOOM, [RenderLocation.NONE]],
    [FunctionId.FLASH, [RenderLocation.TAB_BAR_RIGHT, RenderLocation.TREASURE_BOX]],
    [FunctionId.FOCUS, [RenderLocation.NONE]],
    [FunctionId.EXPOSURE, [RenderLocation.NONE]],
    [FunctionId.ASSISTIVE_GRID, [RenderLocation.SETTING_MENU_COMMON, RenderLocation.TREASURE_BOX]],
    [FunctionId.HORIZONTAL_LEVEL, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.TIME_LAPSE, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.MIRROR, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.CAMERA_SWITCHER, [RenderLocation.NONE]],
    [FunctionId.SAVE_GEO_LOCATION, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.SOUND_MUTE, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.ASPECT_RATIO, [RenderLocation.SETTING_MENU_PHOTO, RenderLocation.TREASURE_BOX]],
    [FunctionId.VIDEO_RESOLUTION, [RenderLocation.SETTING_MENU_VIDEO]],
    [FunctionId.FRAME_RATE, [RenderLocation.SETTING_MENU_VIDEO]],
    [FunctionId.EFFICIENT_VIDEO, [RenderLocation.SETTING_MENU_VIDEO]],
    [FunctionId.SETTING, [RenderLocation.TREASURE_BOX]],
    [FunctionId.FLOATING_SHUTTER, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.DIRECTION, [RenderLocation.NONE]],
    [FunctionId.TIMED_SHOT, [RenderLocation.SETTING_MENU_COMMON]],
  ]);

  public readonly pcFunctions: Map<FunctionId, RenderLocation[]> = new Map([
    [FunctionId.CAPTURE, [RenderLocation.NONE]],
    [FunctionId.ASSISTIVE_GRID, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.HORIZONTAL_LEVEL, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.TIME_LAPSE, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.MIRROR, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.SOUND_MUTE, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.ASPECT_RATIO, [RenderLocation.SETTING_MENU_PHOTO]],
    [FunctionId.SETTING, [RenderLocation.TREASURE_BOX]],
    [FunctionId.DIRECTION, [RenderLocation.NONE]],
    [FunctionId.TIMED_SHOT, [RenderLocation.SETTING_MENU_COMMON]],
  ]);

  public readonly tvFunctions: Map<FunctionId, RenderLocation[]> = new Map([
    [FunctionId.CAPTURE, [RenderLocation.NONE]],
    [FunctionId.ZOOM, [RenderLocation.NONE]],
    [FunctionId.FOCUS, [RenderLocation.NONE]],
    [FunctionId.MIRROR, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.SOUND_MUTE, [RenderLocation.SETTING_MENU_COMMON]],
    [FunctionId.ASPECT_RATIO, [RenderLocation.NONE]],
    [FunctionId.VIDEO_RESOLUTION, [RenderLocation.SETTING_MENU_VIDEO]],
    [FunctionId.SETTING, [RenderLocation.TREASURE_BOX]],
  ]);
}