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

import lazy { HiLog } from '../../../utils/HiLog';
import type camera from '@ohos.multimedia.camera';

/* instrument ignore file */
const TAG: string = 'CameraContext';

// 负责管理当前相机应用状态的上下文,仅被camera模块使用,不对外呈现
export default class CameraContext {
  private static sInstance: CameraContext;
  private mCamera: camera.CameraDevice | undefined;
  private mIsSupportPhotoOutput: boolean;
  private mIsSupportVideoOutput: boolean;
  private mCameraPosition: camera.CameraPosition;
  private mVideoEnhancePhotoId: number;

  public static getInstance(): CameraContext {
    if (!CameraContext.sInstance) {
      CameraContext.sInstance = new CameraContext();
    }
    return CameraContext.sInstance;
  }

  public isSupportPhotoOutput(): boolean {
    return this.mIsSupportPhotoOutput;
  }

  public setIsSupportPhotoOutput(isSupportPhotoOutput: boolean): void {
    this.mIsSupportPhotoOutput = isSupportPhotoOutput;
  }

  public isSupportVideoOutput(): boolean {
    return this.mIsSupportVideoOutput;
  }

  public setIsSupportVideoOutput(mIsSupportVideoOutput: boolean): void {
    this.mIsSupportVideoOutput = mIsSupportVideoOutput;
  }

  public getCameraPosition(): camera.CameraPosition {
    return this.mCameraPosition;
  }

  public setCameraPosition(position: camera.CameraPosition): void {
    this.mCameraPosition = position;
  }

  public setCamera(camera: camera.CameraDevice): void {
    if (!camera) {
      HiLog.e(TAG, 'setCamera error: camera is null.');
      return;
    }
    this.mCamera = camera;
    this.mCameraPosition = camera.cameraPosition;
  }

  public closeCamera(): void {
    this.mCamera = undefined;
  }

  public getCamera(): camera.CameraDevice {
    return this.mCamera;
  }

  public productVideoEnhancePhotoId(photoId: number): void {
    this.mVideoEnhancePhotoId = photoId;
    HiLog.d(TAG, `SEGMENT_VIDEO productVideoEnhancePhotoId: ${this.mVideoEnhancePhotoId}.`);
  }

  public consumeVideoEnhancePhotoId(): number {
    let photoId = this.mVideoEnhancePhotoId;
    this.mVideoEnhancePhotoId = undefined;
    HiLog.d(TAG, `SEGMENT_VIDEO consumeVideoEnhancePhotoId: ${photoId}, result: ${this.mVideoEnhancePhotoId}.`);
    return photoId;
  }
}