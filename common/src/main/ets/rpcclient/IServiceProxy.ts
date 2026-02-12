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

import rpc from '@ohos.rpc';
import lazy { HiLog } from '../utils/HiLog';
import IService, { ICallback } from './IService.ts';

/* instrument ignore file */
const TAG: string = 'IServiceProxy';

export default class IServiceProxy implements IService {
  public proxy: rpc.IRemoteObject | null = null;

  constructor(proxy: rpc.IRemoteObject) {
    this.proxy = proxy;
  }

  getICallback(requestCode: number, methodName: string, isEnable: boolean, callback: ICallback): void {
    let option = new rpc.MessageOption();
    let data = new rpc.MessageSequence();
    let reply = new rpc.MessageSequence();
    const trans = JSON.stringify({ method: methodName, extra: isEnable });
    data.writeString(trans);
    if (!this.proxy) {
      HiLog.e(TAG, `getICallback, proxy is null`);
      return;
    }
    this.proxy.sendMessageRequest(requestCode, data, reply, option).then(result => {
      HiLog.i(TAG, `sendMessageRequest ${result?.errCode}`);
      if (result?.errCode === 0) {
        let errCode = result.reply?.readInt();
        if (errCode !== 0) {
          callback(errCode, null);
          return;
        }
        let returnValue = result.reply?.readStringArray();
        callback(errCode, returnValue);
      } else {
        HiLog.e(TAG, `getICallback, failed errCode: ${result?.errCode}`);
      }
    }).finally(() => {
      data.reclaim();
      reply.reclaim();
    });
  }
}