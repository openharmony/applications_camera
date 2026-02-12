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
import lazy { HiLog } from './HiLog';
import lazy { EnumType, ValueType } from './types';


const TAG: string = 'StringUtil';

export class StringUtil {
  /**
   * Map类型转为string类型
   */
  public static map2String(valueMap: Map<EnumType | string, ValueType | EnumType>): string {
    if (!valueMap || valueMap.size <= 0) {
      return '';
    }
    let resultString = JSON.stringify([...valueMap]);
    return resultString;
  }

  /**
   * string类型转为Map类型
   */
  public static string2Map(str: string): Map<string, number> | Map<string, EnumType> {
    let resultMap = new Map();
    if (!str || str === '' || str.length <= 0) {
      return resultMap;
    }
    try {
      let jsonString = JSON.parse(str);
      HiLog.d(TAG, `string2Map ${jsonString}.`);
      if (jsonString) {
        for (let [key, value] of jsonString) {
          resultMap.set(key, value);
        }
      }
    } catch (error) {
      HiLog.e(TAG, `string2Map ${error?.code}.`);
    }
    return resultMap;
  }

  /**
   * MapMap类型转为string类型
   */
  public static mapMap2String(valueMap: Map<string, Map<string, number> | Map<EnumType, number>>): string {
    if (!valueMap || valueMap.size <= 0) {
      return '';
    }
    let mapStringArray = new Map<string, string>();
    valueMap.forEach((value, key, map) => {
      mapStringArray.set(key, JSON.stringify([...value]));
    });
    let resultString = JSON.stringify([...mapStringArray]);
    return resultString;
  }

  /**
   * string类型转为MapMap类型
   */
  public static string2MapMap(str: string): Map<string, Map<string, number>> | Map<string, Map<EnumType, number>> {
    let resultMap = new Map();
    if (!str || str === '' || str.length <= 0) {
      return resultMap;
    }
    let jsonString = JSON.parse(str);
    for (let [key, value] of jsonString) {
      let childStr = JSON.parse(value);
      HiLog.d(TAG, `childStr:${childStr}--typeof:${typeof childStr}.`);
      if (typeof childStr === 'number' || typeof childStr === 'string') {
        return new Map();
      }
      let childMap = new Map();
      for (let [k, v] of childStr) {
        childMap.set(k, v);
      }
      resultMap.set(key, childMap);
    }
    return resultMap;
  }
}