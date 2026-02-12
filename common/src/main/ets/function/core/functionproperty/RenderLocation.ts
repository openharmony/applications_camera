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

export enum RenderLocation {
  NONE = 0,
  TAB_BAR_RIGHT = 1,
  TAB_BAR_LEFT = 2,
  TAB_BAR_LIST = 3,
  SETTING_MENU_PHOTO = 4,
  SETTING_MENU_VIDEO = 5,
  SETTING_MENU_COMMON = 6,
  TREASURE_BOX = 7,
  PARAM_BAR_LEFT = 8,
  PARAM_BAR_RIGHT = 9,
  TAB_BAR_MIDDLE = 10,
  TAB_BAR_CUSTOM_FILTER_MENU = 11,
  CUSTOM_FILTER_CARD = 12,
  MERGER_CUSTOM_FILTER_CARD = 13
}

export const TabBarRenderLocations: RenderLocation[] = [
  RenderLocation.TAB_BAR_RIGHT,
  RenderLocation.TAB_BAR_LEFT,
  RenderLocation.TAB_BAR_LIST,
  RenderLocation.TAB_BAR_MIDDLE,
];