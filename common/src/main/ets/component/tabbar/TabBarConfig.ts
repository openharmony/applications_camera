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
import { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { OutputType } from '../../function/outputswitcher/OutputType';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { getStates } from '../../redux';

export const TAB_BAR_ELEMENT_SIZE: number = 30;

export const TAB_BAR_TOGGLE_ELEMENT_SIZE: number = 20;

export const TAB_BAR_MARGIN_LEFT_RIGHT: number = 26;

export const TAB_BAR_MARGIN_LEFT_RIGHT_CUSTOM_FILTER: number = 21;

export const TAB_BAR_MARGIN_VDE_LEFT_RIGHT: number = 28;

export const CUSTOM_FILTER_TABBAR_WIDTH: number = 20;

const CUSTOM_FILTER_TABBAR_EXPAND_WIDTH: number = 66;

export const CUSTOM_FILTER_TABBAR_MARGIN_RIGHT: number = 26;

const POPUP_BUTTONS: FunctionId[] = [FunctionId.FLASH];

export function getPopupButtons(): FunctionId[] {
  return POPUP_BUTTONS;
}

export const TabBarConfig: Map<string, FunctionId[]> = new Map<string, FunctionId[]>([
  [ModeType.PHOTO, [FunctionId.FLASH]],
  [ModeType.VIDEO, [FunctionId.FLASH]],
]);

// 组件树顺序受此影响，关乎屏幕朗读顺序
export const TAB_BAR_ELEMENTS: FunctionId[] =
  [FunctionId.FLASH, FunctionId.PHOTO_FORMAT];