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

import lazy { BaseFunction } from '../../../function/core/BaseFunction';
import lazy { FeatureManager } from '../../../function/core/FeatureManager';
import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { UiElement } from '../../../function/core/UiElement';

/* instrument ignore file */
const TAG: string = 'TreasureBoxCommonFunction';
const ANIMATION_EACH_DELAY = 50;
const NORMAL_SCALE_DURATION = 300;
const NORMAL_OPACITY_DURATION = 50;
const NORMAL_DELAY = 100;
const ICON_SHOW_TIME: number = 670;
const ICON_SHOW_INDEX: number = 4;

export function isFirstModeUsing(selector: FunctionId): boolean {
  const functionImpl: BaseFunction = FeatureManager.getInstance().getFunction(selector);
  if (!functionImpl) {
    return false;
  }
  const mainList = Array.from<Object[]>(functionImpl.getUiElements(RenderLocation.TREASURE_BOX))
    .filter(value => value[0] != UiElement.DEFAULT);
  if (!mainList || !mainList[0]) {
    return false;
  }
  return mainList[0][0] === functionImpl.getValue();
}

export interface ScaleOpacityAnimateData {
  scaleDuration: number,
  opacityDuration: number,
  normalDelay?: number,
  index?: number,
  eachDelay?: number
}

const TREASURE_BOX_ELEMENT_COMMON_WIDTH: number = 24;
const TREASURE_BOX_ELEMENT_LOG_STYLE_WIDTH: number = 30;
export const TREASURE_BOX_ELEMENT_STABILIZATION_WIDTH: number = 30;

export function getElementWidth(id: FunctionId): number {
  return TREASURE_BOX_ELEMENT_COMMON_WIDTH;
}