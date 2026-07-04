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
import lazy { Context, Want } from '@kit.AbilityKit';
import lazy { HiLog } from '../utils/HiLog';
import lazy { REQUEST_CODE } from './IService.ts';
import IServiceProxy from './IServiceProxy';
import lazy { RemoteService } from './RemoteService';

/* instrument ignore file */
const TAG: string = 'ConnectCapabilityManager: ';

export class ConnectCapabilityManager {
  public static serviceInstance: RemoteService;
  public static isConnected: boolean = false;

  static async setConnectionCapability(context: Context, isEnable: boolean): Promise<void> {
    const want: Want = {
      bundleName: 'com.ohos.sceneboard',
      abilityName: 'SinglePocketProviderService'
    };
    ConnectCapabilityManager.serviceInstance = new RemoteService(context);
    try {
      ConnectCapabilityManager.serviceInstance.getProxy(want).then((proxy: IServiceProxy) => {
        proxy.getICallback(REQUEST_CODE, 'appSwitchContinuation', isEnable, () => {});
      }).catch((e: Error) => {
        HiLog.e(TAG, `request err: ${e?.message}`);
        ConnectCapabilityManager.serviceInstance.disConnect();
      });
    } catch (e) {
      HiLog.e(TAG, `request fail: ${e?.message}`);
    }
  }

  static disConnectService(): void {
    if (ConnectCapabilityManager.serviceInstance) {
      HiLog.i(TAG, `disConnectService`);
      ConnectCapabilityManager.serviceInstance.disConnect();
    }
  }
}