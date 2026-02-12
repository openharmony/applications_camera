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

/* instrument ignore file */
const TAG: string = 'WorkerDataCache';

export class WorkerDataCache {
  private static instance: WorkerDataCache;
  // 录像文件设置
  private isNeedSaveSuperSlow: boolean = true;
  private isSlowMotion: boolean = false;
  private isValidateThumbnail: boolean = false;

  private constructor() {
  }

  public static getInstance(): WorkerDataCache {
    if (!WorkerDataCache.instance) {
      WorkerDataCache.instance = new WorkerDataCache();
    }
    return WorkerDataCache.instance;
  }

  public setSlowMotionStatus(isSlowMotion: boolean): void {
    this.isSlowMotion = isSlowMotion;
  }

  public getSlowMotionStatus(): boolean {
    return this.isSlowMotion;
  }

  public setMotionStateForRecord(isNeedSaveSuperSlow: boolean): void {
    this.isNeedSaveSuperSlow = isNeedSaveSuperSlow;
  }

  public getMotionStateForRecord(): boolean {
    return this.isNeedSaveSuperSlow;
  }

  public setValidateThumbnail(validateThumbnail: boolean): void {
    this.isValidateThumbnail = validateThumbnail;
  }

  public getValidateThumbnail(): boolean {
    return this.isValidateThumbnail;
  }
}