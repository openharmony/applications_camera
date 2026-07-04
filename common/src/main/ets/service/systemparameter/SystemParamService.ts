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

import lazy { HiLog } from '../../utils/HiLog';
import lazy { systemParameter, systemParameterEnhance } from '@kit.BasicServicesKit';

const TAG: string = 'SystemParamService';

/*
 * 系统配置项/参数读取代理
 * 仅允许在此类中从@kit.BasicServicesKit底层导包systemParameter, systemParameterEnhance
 */
export class SystemParamService {
  private static sInstanceSystemParamService: SystemParamService;
  private mSystemParamMap: Map<string, string>;

  public static getInstance(): SystemParamService {
    if (!SystemParamService.sInstanceSystemParamService) {
      SystemParamService.sInstanceSystemParamService = new SystemParamService();
    }
    return SystemParamService.sInstanceSystemParamService;
  }

  constructor() {
    this.mSystemParamMap = new Map();
  }

  private getSystemParamSync(isNewApi: boolean, paramName: string, defaultValue?: string): string {
    let paramValue: string = undefined;
    try {
      HiLog.i(TAG, `getSystemParamSync isNewApi:${isNewApi}, paramName:${paramName}, defaultValue:${defaultValue}.`);
      if (isNewApi) {
        paramValue = systemParameterEnhance.getSync(paramName, defaultValue);
      } else {
        // 因新systemParameterEnhance接口未做好系统兜底,get不存在的系统配置会crash,还是需要走老systemParameter废弃接口
        paramValue = systemParameter.getSync(paramName, defaultValue);
      }
    } catch (err) {
      HiLog.e(TAG, `getSystemParamSync error: ${err}.`);
    }
    return paramValue;
  }

  // 静态系统配置项读取方法,减少io
  public get(isNewApi: boolean, paramName: string, defaultValue?: string): string {
    if (!this.mSystemParamMap.has(paramName)) {
      let paramValue = this.getSystemParamSync(isNewApi, paramName, defaultValue);
      HiLog.i(TAG, `getSystemParamSync paramValue: ${paramValue}.`);
      this.mSystemParamMap.set(paramName, paramValue);
    }
    return this.mSystemParamMap.get(paramName);
  }

  // 动态系统参数实时读取方法
  public dynamicGet(isNewApi: boolean, paramName: string, defaultValue?: string): string {
    let paramValue = this.getSystemParamSync(isNewApi, paramName, defaultValue);
    HiLog.i(TAG, `getSystemParamSync paramValue: ${paramValue}.`);
    return paramValue;
  }
}