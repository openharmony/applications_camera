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
import lazy { getStates } from '../../redux';
import lazy { TAB_BAR_HEIGHT } from '../../service/UIAdaptive/AdaptiveLayoutService';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { PositionType } from '../../utils/types';
import lazy {
  TAB_BAR_ELEMENT_SIZE,
  TAB_BAR_MARGIN_LEFT_RIGHT,
  TAB_BAR_MARGIN_LEFT_RIGHT_CUSTOM_FILTER,
  TAB_BAR_MARGIN_VDE_LEFT_RIGHT,
  TAB_BAR_TOGGLE_ELEMENT_SIZE,
} from './TabBarConfig';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';

const TAG: string = 'TabBarUtils';

export const TAB_BAR_STABILIZATION_ELEMENT_LENGTH: number = 25;
const TAB_BAR_LOG_STYLE_ELEMENT_LENGTH: number = 28;

export class TabBarUtils {

  static calcElementPosition(functionId: FunctionId, allFunctionIds: FunctionId[], isPhotoOutputType: boolean):
    PositionType {
    let tabBarMargin: number = TAB_BAR_MARGIN_LEFT_RIGHT;
    let index: number = allFunctionIds.indexOf(functionId);
    if (index < 0) {
      return {x: 0, y: 0};
    }
    let numElements: number = allFunctionIds.length;
    const windowWidth: number = getStates().get<number>('windowReducer', 'windowWidth');
    if (numElements === 1) {
      return {
        x: windowWidth - tabBarMargin - TAB_BAR_ELEMENT_SIZE,
        y: (TAB_BAR_HEIGHT - TAB_BAR_ELEMENT_SIZE) / 2
      };
    }
    if (!isPhotoOutputType && allFunctionIds.length < 3) {
      numElements += 1;
      index += 1;
    }
    const videoModeExtraLeftSpace: number = isPhotoOutputType ? 0 : 94;
    // 可变宽度TabBar按钮处理
    let openVariableWidthElements: FunctionId[] = [];
    let variableWidthElementsTotalSize: number = 0;
    const totalSpace: number = windowWidth - videoModeExtraLeftSpace - tabBarMargin * 2 -
      (numElements - openVariableWidthElements.length) * TAB_BAR_ELEMENT_SIZE - variableWidthElementsTotalSize;
    const space: number = isPhotoOutputType ? totalSpace / (numElements - 1) : totalSpace / numElements;
    const basePositionX: number = index * (TAB_BAR_ELEMENT_SIZE + space) + tabBarMargin +
      videoModeExtraLeftSpace;
    return {
      x: isPhotoOutputType ? basePositionX : basePositionX + space,
      y: (TAB_BAR_HEIGHT - TAB_BAR_ELEMENT_SIZE) / 2,
    };
  }

  private static getOpenVariableWidthElements(setA: Set<FunctionId>, setB: Set<FunctionId>): FunctionId[] {
    return [...setA].filter(item => setB.has(item) && this.getIsVariableWidthElementOpen(item));
  }

  private static getIsVariableWidthElementOpen(functionId: FunctionId): boolean {
    return false;
  }

  public static getImageWidth(id: FunctionId): number {
    return TAB_BAR_TOGGLE_ELEMENT_SIZE;
  }
}