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
import lazy { TipService } from '../../component/tip/TipService';
import lazy { PersistType, PreferencesService } from '../preferences/PreferencesService';
import lazy { PropTag } from '../preferences/PropTag';
import lazy { storageStatistics } from '@kit.CoreFileKit';

const TAG = 'MemoryService';
const BYTE_UNIT_CARRY = 1024;
const MIN_FREE_SPACE = 500;
const THREE_DISAPPEAR_TIME: number = 3000;
const FIVE_DISAPPEAR_TIME: number = 5000;
const EXPIRE_HOURS_TIME_24: number = 24 * 60;
const INSUFFICIENT_MEMORY_THRESHOLD = 10 * 1024;

/**
 * MemoryService
 *
 * @since 2025-02-09
 */
export class MemoryService {
  private static sInstance: MemoryService;
  private hasObtained: boolean = false;
  private mIsFullStorage: boolean = false;
  private taskTimer: number = Number.MIN_VALUE;

  public static getInstance(): MemoryService {
    if (!MemoryService.sInstance) {
      HiLog.d(TAG, 'new instance');
      MemoryService.sInstance = new MemoryService();
    }
    return MemoryService.sInstance;
  }

  isFullStorage(isVideo: boolean = false): boolean {
    if (this.hasObtained) {
      if (this.mIsFullStorage) {
        this.handleFullStorage();
      }
      return this.mIsFullStorage;
    }

    try {
      // 获取可用空间
      this.checkStorageStatus(isVideo);
      return this.mIsFullStorage;
    } catch (error) {
      this.handleError(error);
      return false;
    }
  }

  updateStorageStatus(freeSpace: number, isVideo: boolean): void {
    this.hasObtained = true;
    if (Number.MIN_VALUE !== this.taskTimer) {
      clearTimeout(this.taskTimer);
    }
    this.taskTimer = setTimeout(() => {
      this.hasObtained = false;
    }, THREE_DISAPPEAR_TIME);

    if(freeSpace < INSUFFICIENT_MEMORY_THRESHOLD) {
      // 内存已小于 10GB
      this.mIsFullStorage = freeSpace < MIN_FREE_SPACE;
      /* instrument ignore if */
      if (this.mIsFullStorage) {
        this.handleFullStorage();
      } else if (!isVideo) {
        TipService.getInstance().showTip($r('app.string.device_storage_space'), FIVE_DISAPPEAR_TIME, true);
      }
    }
  }

  checkStorageStatus(isVideo: boolean = false): void {
    try {
      // 获取可用空间
      let freeSpace = storageStatistics.getFreeSizeSync() / BYTE_UNIT_CARRY / BYTE_UNIT_CARRY;
      this.updateStorageStatus(freeSpace, isVideo);
      HiLog.i(TAG, `Free space: ${freeSpace}, mIsFullStorage: ${this.mIsFullStorage}`);
    } catch (error) {
      throw error;
    }
  }

  private handleError(error: Error): void {
    const faultReason = `getFreeSize failed because: ${error.message}`;
    HiLog.e(TAG, faultReason);
    this.hasObtained = false;
    this.mIsFullStorage = false;
  }

  private handleFullStorage(): void {
    HiLog.w(TAG, 'handleFullStorage');
    TipService.getInstance().showTip($r('app.string.internal_storage_full'), THREE_DISAPPEAR_TIME, true);
  }

  updateApplicationStorageSpace(): void {
    HiLog.i(TAG, 'updateApplicationStorageSpace');
    let preferencesService: PreferencesService = PreferencesService.getInstance();
    if (preferencesService.isExpire(EXPIRE_HOURS_TIME_24, PropTag.BUNDLE_STATS_TIMESTAMP) ||
      preferencesService.getPropValue(PersistType.FOREVER, PropTag.BUNDLE_STATS_TIMESTAMP, 0) === 0) {
      HiLog.i(TAG, 'applicationStorageSpaceReport');
    }
  }
}
