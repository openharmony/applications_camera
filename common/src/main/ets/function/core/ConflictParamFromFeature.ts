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

import lazy { FunctionId } from './functionproperty/FunctionId';
import lazy { ConflictParam } from './ConflictParam';
import lazy { HiLog } from '../../utils/HiLog';

const TAG: string = 'ConflictParamFromFeature';

export class ConflictParamFromFeature {
  /**
   * 结构：
   * {
   *   FunctionId: {
   *     FunctionId: ConflictParam
   *   }
   * }
   */
  private map: Map<FunctionId, Map<FunctionId, ConflictParam>> = new Map();

  constructor() {
  }

  setConflictParam(functionId: FunctionId, conflictParam: ConflictParam, from: FunctionId): ConflictParam {
    let fromFun2ConflictParam: Map<FunctionId, ConflictParam> = this.map.get(functionId);
    if (!fromFun2ConflictParam) {
      HiLog.i(TAG, `${functionId} first set conflict`);
      fromFun2ConflictParam = new Map<FunctionId, ConflictParam>();
    }

    // 设置策略为：1. key为from的冲突参数首次存储，并且传入参数不为空，设置到map中；
    //           2. key为from的冲突参数非首次存储，更新map中的值
    let savedConflictParam: ConflictParam = fromFun2ConflictParam.get(from);
    savedConflictParam = (conflictParam ?? savedConflictParam) ?? undefined;
    if (savedConflictParam) {
      fromFun2ConflictParam.set(from, savedConflictParam);
    }
    this.map.set(functionId, fromFun2ConflictParam);

    if (fromFun2ConflictParam.size <= 0) {
      HiLog.w(TAG, `setConflictParam ${from} to ${functionId} is null, return`);
      return null;
    }

    let resultConflictParam: ConflictParam = null;
    fromFun2ConflictParam.forEach((v, k) => {
      if (!resultConflictParam) {
        resultConflictParam = new ConflictParam().setLimitedValueSet(v.limitedValue);
        if (v.disabled) {
          resultConflictParam.disable();
        }
        return;
      }

      if (v.disabled) {
        resultConflictParam.disable();
      }

      if (v.limitedValue && resultConflictParam.limitedValue) {
        resultConflictParam.limitedValue.merge(v.limitedValue);
        return;
      }
      if (!resultConflictParam.limitedValue) {
        resultConflictParam.limitedValue = v.limitedValue;
      }
    });
    return resultConflictParam;
  }
}