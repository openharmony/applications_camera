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
import lazy { ValueSet } from './ValueSet';

const TAG: string = 'ConflictParam';

export class ConflictParam {
  // disabled
  disabled: boolean = false;
  limitedValue: ValueSet = null;

  constructor() {
  }

  static emptyParam(): ConflictParam {
    return new ConflictParam();
  }

  /**
   * Disable
   *
   * @return ConflictParam
   */
  disable(): ConflictParam {
    this.disabled = true;
    return this;
  }

  /**
   * Set limited value set
   *
   * @param limitedValueSet The limited value set.
   * @return ConflictParam
   */
  setLimitedValueSet(limitedValueSet: ValueSet): ConflictParam {
    if (!limitedValueSet) {
      this.limitedValue = null;
      return this;
    }
    // 深拷贝
    this.limitedValue = new ValueSet();
    this.limitedValue.setValues([...limitedValueSet.getValues()]);
    return this;
  }

  // 按优先级进行冲突的合并
  // todo:一套互斥的优先级处理机制需要根据互斥种类进行完善
  merge(obj: ConflictParam): ConflictParam {
    if (obj && this.equals(obj)) {
      return this;
    }
    if (obj.disabled || this.disabled) {
      this.disable();
    }
    return this;
  }

  equals(obj: ConflictParam): boolean {
    let flag = false;
    if (this === obj) {
      flag = true;
    }
    if (obj) {
      if (this.limitedValue || obj.limitedValue) {
        if (this.limitedValue && obj.limitedValue) {
          return this.limitedValue.getValues().toString() === obj.limitedValue.getValues().toString();
        } else {
          return false;
        }
      }
      if (this.disabled === obj.disabled) {
        flag = true;
      }
    }
    return flag;
  }
}