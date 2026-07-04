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
import lazy { resourceManager } from '@kit.LocalizationKit';
import lazy { HiLog } from './HiLog';
import lazy { BusinessError } from '@kit.BasicServicesKit';
import lazy { ContextManager } from '../service/context/ContextManager';

const TAG = 'ResGetter';

export default class ResGetter {
  private static resManager: resourceManager.ResourceManager;
  private static sInstance: ResGetter;

  public static getInstance(): ResGetter {
    if (!ResGetter.sInstance) {
      ResGetter.sInstance = new ResGetter();
      ResGetter.resManager = ContextManager.getInstance().getUiContext().resourceManager;
    }
    return ResGetter.sInstance;
  }

  /* instrument ignore next */
  public static getResManager(): resourceManager.ResourceManager {
    if (this.resManager) {
      return this.resManager;
    }
    try {
      this.resManager = ContextManager.getInstance().getUiContext().resourceManager;
      HiLog.i(TAG, 'rsm get suc from ui context');
      return this.resManager;
    } catch (err) {
      HiLog.e(TAG, `get resManager fail ${err?.code}`);
    }
    if (ContextManager.getInstance().getResourceManager()) {
      this.resManager = ContextManager.getInstance().getResourceManager();
      HiLog.i(TAG, 'rsm get suc from ctx');
      return this.resManager;
    }
    HiLog.e(TAG, 'resManager maybe is null');
    return this.resManager;
  }

  private constructor() {
  }

  private static getString(resource: resourceManager.Resource): string {
    if (resource.params && resource.params.length) {
      try {
        return this.getResManager().getStringSync(resource.id, ...resource.params);
      } catch (error) {
        let code = (error as BusinessError).code;
        let message = (error as BusinessError).message;
        HiLog.e(TAG, `getString failed, error code: ${code}, message: ${message}`);
      }
    }
    try {
      return this.getResManager().getStringSync(resource.id);
    } catch (e) {
      HiLog.e(TAG, `getString failed, error2 code: ${e.code}, message: ${e.message}`);
    }
    HiLog.e(TAG, `getString failed, resource: ${JSON.stringify(resource)}`);
    return '';
  }

  public static getStringSafe(resource?: resourceManager.Resource | string): string {
    if (!resource) {
      return '';
    }
    if (typeof resource === 'string') {
      return resource;
    }
    if (resource?.id === -1) {
      return '';
    }
    return this.getString(resource);
  }

  /* instrument ignore next */
  public static getStringByName(resource: resourceManager.Resource): string {
    if (resource.params && resource.params.length) {
      try {
        let nameArray = resource.params[0].split('.');
        const name = nameArray[nameArray.length - 1];
        return this.getResManager().getStringByNameSync(name);
      } catch (error) {
        let code = (error as BusinessError).code;
        let message = (error as BusinessError).message;
        HiLog.e(TAG, `getStringByName failed, error code: ${code}, message: ${message}`);
      }
    }
    return this.getResManager().getStringSync(resource?.id);
  }
}