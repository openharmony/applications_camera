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

import type camera from '@ohos.multimedia.camera';
import type CameraDeviceManager from './CameraDeviceManager';
import type CameraContext from './CameraContext';

/* instrument ignore file */
const TAG: string = 'CameraOutput';

// Output基类
export default abstract class CameraOutput {
  protected mCameraDeviceManager: CameraDeviceManager;
  protected mCameraContext: CameraContext;

  constructor(cameraDeviceManager: CameraDeviceManager, cameraContext: CameraContext) {
    this.mCameraDeviceManager = cameraDeviceManager;
    this.mCameraContext = cameraContext;
  }

  abstract getOutput(): camera.CameraOutput;

  abstract release(): void;
}