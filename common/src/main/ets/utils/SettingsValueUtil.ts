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

import lazy { HiLog } from '../utils/HiLog';
import lazy { ContextManager } from '../service/context/ContextManager';
import lazy { Context } from '@ohos.arkui.UIContext';
import settings from '@ohos.settings';

const TAG: string = 'SettingsValueUtil';

/*
 * 系统设置配置项/参数读取代理
 */
export class SettingsValueUtil {
  public static getValueSync(name: string, defValue: string, domainName?: string): string {
    try {
      const context = ContextManager.getInstance().getContextWithToken();
      let value = defValue;
      if (domainName) {
        value = settings.getValueSync(context, name, defValue, domainName);
      } else {
        value = settings.getValueSync(context, name, defValue);
      }
      HiLog.i(TAG, `getValueSync value: ${value}, name: ${name}, defValue: ${defValue}.`);
      return value;
    } catch (e) {
      HiLog.e(TAG, `getValueSync err: ${e?.message}`);
      return defValue;
    }
  }

  public static setValueSync(name: string, value: string, domainName?: string): void {
    try {
      HiLog.i(TAG, `setValueSync name: ${name}, value: ${value}.`);
      const context = ContextManager.getInstance().getContextWithToken();
      if (domainName) {
        settings.setValueSync(context, name, value, domainName);
      } else {
        settings.setValueSync(context, name, value);
      }
    } catch (e) {
      HiLog.e(TAG, `setValueSync err: ${e?.message}.`);
    }
  }
}