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

import lazy { FeatureManager } from '../function/core/FeatureManager';
import lazy { FunctionId } from '../function/core/functionproperty/FunctionId';
import lazy { OutputOperation } from '../function/outputswitcher/OutputOperation';
import lazy { ZoomOperation } from '../function/zoombar/ZoomOperation';
import lazy { getStates } from '../redux';
import lazy { HiLog } from '../utils/HiLog';

import lazy { ModeType } from './ModeType';

const SUPER_ISO_VALUE: number = 12800;
const TAG: string = 'ModeControl';

export class ModeControl {
  private static sInstance: ModeControl;

  private constructor() {
  }

  public static getInstance(): ModeControl {
    if (!ModeControl.sInstance) {
      ModeControl.sInstance = new ModeControl();
    }
    return ModeControl.sInstance;
  }

  public setRemainZoomRatio(mode: ModeType, oldMode: ModeType): void {
    const isoValue: number = getStates().get<number>('isoReducer', 'isoValue');
    HiLog.i(TAG, 'isoValue:' + isoValue);
  }
}