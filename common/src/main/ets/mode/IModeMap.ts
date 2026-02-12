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
import type { FunctionId } from '../function/core/functionproperty/FunctionId';
import type { BaseMode } from './BaseMode';
import type { ModeType } from './ModeType';
import lazy { RenderLocation } from '../function/core/functionproperty/RenderLocation';
import lazy { OutputType } from '../function/outputswitcher/OutputType';

export interface IModeMap {
  getFunctions: (mode: ModeType) => Map<FunctionId, RenderLocation[]>;
  initExtendFeatures: () => void;
  getMode: (mode: ModeType, outputType: OutputType) => BaseMode;
}