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
import type { VibratorService } from '../component/vibration/VibratorService';
import type MediaLibraryWorkerService from '../service/medialibrary/MediaLibraryWorkerService';
import type { PickerFileWorkerService } from '../service/picker/PickerFileWorkerService';
import lazy { HiLog } from '../utils/HiLog';

const TAG: string = 'WorkerModulesManager';

class WorkerModulesManager {
  private mediaLibrary: MediaLibraryWorkerService;
  private pickerFileWorkerService: PickerFileWorkerService;
  private vibratorService: VibratorService;

  // 临时数据处理
  public isShouldNotifyNextCapture: boolean = true;

  public async getMediaLibrary(): Promise<MediaLibraryWorkerService> {
    if (!this.mediaLibrary) {
      HiLog.i(TAG, 'import mediaLibraryWorkerService begin');
      const mediaLibraryWorkerService = await import('../service/medialibrary/MediaLibraryWorkerService');
      HiLog.i(TAG, 'import mediaLibraryWorkerService end');
      this.mediaLibrary = mediaLibraryWorkerService.default.getInstance();
    }
    this.mediaLibrary.checkPhotoAccessHelper();
    return this.mediaLibrary;
  }

  public async getPickerFileWorkerService(): Promise<PickerFileWorkerService> {
    if (!this.pickerFileWorkerService) {
      const pickerWorkerFile = await import('../service/picker/PickerFileWorkerService');
      this.pickerFileWorkerService = pickerWorkerFile.PickerFileWorkerService.getInstance();
    }
    return this.pickerFileWorkerService;
  }

  public async getVibratorService(): Promise<VibratorService> {
    if (!this.vibratorService) {
      const vibrator = await import('../component/vibration/VibratorService');
      this.vibratorService = vibrator.VibratorService.getInstance();
    }
    return this.vibratorService;
  }
}

export const modulesManager: WorkerModulesManager = new WorkerModulesManager();
