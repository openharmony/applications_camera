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

import common from '@ohos.app.ability.common';
import rpc from '@ohos.rpc';
import Want from '@ohos.app.ability.Want';
import bundleManager from '@ohos.bundle.bundleManager';
import IServiceProxy from './IServiceProxy';
import lazy { ConnectCapabilityManager } from './ConnectCapabilityManager';
import lazy { Context } from '@kit.AbilityKit';
import lazy { HiLog } from '../utils/HiLog';

/* instrument ignore file */
const TAG: string = 'RemoteService';

export class RemoteService {
  private remoteObj?: rpc.IRemoteObject;
  private proxy?: IServiceProxy;
  private connectionCode?: number;
  private context?: common.UIAbilityContext;

  public constructor(context: Context) {
    this.context = context as common.UIAbilityContext;
  }

  public async getProxy(want: Want): Promise<IServiceProxy> {
    return new Promise<IServiceProxy>((resolve, reject) => {
      if (!this.context) {
        HiLog.e(TAG, `getProxyInner, context is empty`);
        let error: Record<string, string | number> = {
          'message': 'context is empty'
        };
        return reject(error);
      }
      try {
        this.connectionCode = this.context?.connectServiceExtensionAbility(want, {
          onConnect: (elementName: bundleManager.ElementName, remote: rpc.IRemoteObject): void => {
            HiLog.i(TAG, `getProxy, onConnect connectionCode: ${this.connectionCode}`);
            this.remoteObj = remote;
            this.proxy = new IServiceProxy(remote);
            ConnectCapabilityManager.isConnected = true;
            resolve(this.proxy);
          },
          onDisconnect: (elementName: bundleManager.ElementName): void => {
            HiLog.i(TAG, `getProxy, onDisconnect connectionCode:${this.connectionCode}`);
            ConnectCapabilityManager.isConnected = false;
            this.clean();
          },
          onFailed: (code: number): void => {
            HiLog.e(TAG, `getProxy, onFailed ${code}`);
            this.clean();
            let error: Record<string, string | number> = {
              'code': code,
              'message': 'getProxy failed'
            };
            reject(error);
          }
        });
      } catch (err) {
        reject(err);
        HiLog.e(TAG, `connectCallerRpc catch exception, ${err?.code}`);
      }
    });
  }

  private clean(): void {
    this.remoteObj = undefined;
    this.proxy = undefined;
  }

  public disConnect(): void {
    if (!this.context) {
      HiLog.e(TAG, `disConnect, context is empty`);
      return;
    }
    try {
      this.context.disconnectServiceExtensionAbility(this.connectionCode as number);
      ConnectCapabilityManager.isConnected = false;
    } catch (err) {
      HiLog.e(TAG, `disconnectThemeService failed: ${err?.code}`);
    }
  }
}