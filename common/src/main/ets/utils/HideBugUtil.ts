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

import hideBug from '@ohos.hidebug';
import lazy { TipService } from '../component/tip/TipService';
import lazy { HiLog } from './HiLog';

const TAG = 'HideBugUtil';
const DT_MEM_LIMIT = 1.5 * 1024 * 1024; //单位byte
const MEM_UNIT_1024 = 1024;

export class HideBugUtil {
  /**
   * 获取本应用堆内存的总大小。
   * @returns
   */
  public static getNativeHeapSize(): string {
    return hideBug.getNativeHeapSize().toString();
  }

  /**
   * 获取本应用堆内存的已分配内存大小。
   * @returns
   */
  public static getNativeHeapAllocatedSize(): string {
    return hideBug.getNativeHeapAllocatedSize().toString();
  }

  /**
   * 获取本应用堆内存的空闲内存大小。
   * @returns
   */
  public static getNativeHeapFreeSize(): string {
    return hideBug.getNativeHeapFreeSize().toString();
  }

  /**
   * 获取应用进程实际使用的物理内存大小。
   * @returns
   */
  public static getPss(): string {
    HiLog.begin(TAG, 'getPss');
    const mem = hideBug.getPss().toString();
    HiLog.end(TAG, 'getPss');
    return mem;
  }

  /**
   * 获取系统内存信息。
   * @returns
   */
  public static getSystemMemInfo(): hideBug.SystemMemInfo {
    return hideBug.getSystemMemInfo();
  }

  /**
   * DT用例场景下：获取应用进程实际使用的物理内存大小(单位KB)，超过DT_MEM_LIMIT弹出提示框。
   * @returns
   */
  public static checkDtPss(dtIndex: number): void {
    const mem = hideBug.getPss().toString();
    HiLog.i(TAG, `checkDtPss, dtIndex: ${dtIndex}, value: ${mem}`);
    if (parseInt(mem) > DT_MEM_LIMIT) {
      TipService.getInstance()
        .showTip('dtIndex：' + dtIndex + '，DT内存过高，超过：' + parseInt(mem) / MEM_UNIT_1024 + 'M', 10000, true);
    }
  }
}