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

import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { ConflictManager } from '../core/ConflictManager';
import lazy { ConflictParam } from '../core/ConflictParam';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { ValueSet } from '../core/ValueSet';
import lazy { isHighStabilization } from '../operationbase/StabilizationManager';

const TAG: string = 'VideoResolutionConflictManager';

/**
 * 互斥处理类
 */
export class VideoResolutionConflictManager {
  private static conflictManager: VideoResolutionConflictManager;

  public static getInstance(): VideoResolutionConflictManager {
    if (!VideoResolutionConflictManager.conflictManager) {
      VideoResolutionConflictManager.conflictManager = new VideoResolutionConflictManager();
    }
    return VideoResolutionConflictManager.conflictManager;
  }

  public conflict(): void {
    let conflictParam: ConflictParam = ConflictParam.emptyParam();
    const featureManager: FeatureManager = FeatureManager.getInstance();
    const isHigh: boolean = isHighStabilization();
    const preRecord: boolean = featureManager.getFunction(FunctionId.PRE_RECORD)?.getValue();
    if (isHigh && preRecord) {
      conflictParam = conflictParam.setLimitedValueSet(new ValueSet().setValues([
        SettingFuncDialogItemIndex.INDEX_THR.toString()
      ]));
    } else if (isHigh) {
      conflictParam = conflictParam.setLimitedValueSet(new ValueSet().setValues([
        SettingFuncDialogItemIndex.INDEX_THR.toString(),
        SettingFuncDialogItemIndex.INDEX_FIF.toString()
      ]));
    } else if (preRecord) {
      conflictParam = conflictParam.setLimitedValueSet(new ValueSet().setValues([
        SettingFuncDialogItemIndex.INDEX_SEC.toString(),
        SettingFuncDialogItemIndex.INDEX_THR.toString(),
        SettingFuncDialogItemIndex.INDEX_FOUR.toString()
      ]));
    }
    ConflictManager.getInstance().setConflictParam(FunctionId.VIDEO_RESOLUTION, conflictParam);
  }
}
