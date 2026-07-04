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

import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { UiElement } from '../../../function/core/UiElement';
import type { CameraStartType } from '../../../camera/uithread/CameraAction';
import type { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { ValueType } from '../../../utils/types';

/* instrument ignore next */
class TransAnimationDataStruct {
  startUi?: UiElement = new UiElement();
  startId?: FunctionId = FunctionId.NONE;
  endUi?: UiElement = new UiElement();
  endId?: FunctionId = FunctionId.NONE;
  startLeftMargin: number = 0;
  endLeftMargin: number = 0;
}

/* instrument ignore next */
export class TransAnimationData {
  startUiElement?: UiElement;
  startFunctionId?: FunctionId;
  endUiElement?: UiElement;
  endFunctionId?: FunctionId;
  startLeftMargin: number;
  endLeftMargin: number;

  constructor(data: TransAnimationDataStruct) {
    this.startUiElement = data.startUi;
    this.startFunctionId = data.startId;
    this.endUiElement = data.endUi;
    this.endFunctionId = data.endId;
    this.startLeftMargin = data.startLeftMargin;
    this.endLeftMargin = data.endLeftMargin;
  }
}

export interface IsOpenStruct {
  isOpen: boolean;
}

export interface CameraStartTypeData {
  type: CameraStartType;
}

export interface SelectorData {
  functionId: FunctionId;
  renderLocation: RenderLocation;
}

export const TREASURE_BOX_IMAGE_ELEMENT: Set<FunctionId> = new Set([
]);

export const TREASURE_BOX_ELEMENT_INNER_WIDTH = 48;

export const TREASURE_BOX_ELEMENT_INNER_HEIGHT = 48;

export const VDE_TREASURE_BOX_ELEMENT_INNER_WIDTH = 28;

export const VDE_TREASURE_BOX_ELEMENT_INNER_HEIGHT = 28;

export const SLEEP_TIME: number = 10;

export interface FunctionType {
  uiElement: UiElement;
  value: ValueType;
  id?: FunctionId;
}

export interface FunctionConflictParamData {
  id: FunctionId,
  conflictParam: Object
}