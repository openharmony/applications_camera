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

import type { FunctionId } from './functionproperty/FunctionId';
import lazy { RenderLocation } from './functionproperty/RenderLocation';
import type { RenderType } from './functionproperty/RenderType';
import type { UiElement } from './UiElement';

export interface IFunction {

  /**
   * Get function id
   *
   * @return The unique id in {@link FeatureId} to indicate this function.
   */
  getFunctionId: () => FunctionId;
  getRenderLocations: () => RenderLocation[];
  getRenderType: (renderLocation: RenderLocation) => RenderType;
  getUiElements: (renderLocation: RenderLocation) => Map<number, UiElement>;
  isAvailable: () => boolean;
  getValue: () => any;
  setValue: (value: number, renderLocation?: RenderLocation) => void;
}