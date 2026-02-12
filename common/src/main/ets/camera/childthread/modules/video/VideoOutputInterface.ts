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
import lazy { HiLog } from '../../../../utils/HiLog';
import type { PickerInfo } from '../../../../utils/types';
import type { TagMessage, VideoOutputMessage } from '../../../DataType';

/* instrument ignore file */
const TAG: string = 'VideoOutputInterface';

// Output基类
export default abstract class VideoOutputInterface {

  public abstract init(message: VideoOutputMessage, tagMessage: TagMessage, cameraManager: camera.CameraManager,
    pickerInfo: PickerInfo): Promise<void>;

  public abstract getOutput(): camera.CameraOutput;

  public abstract isAutoDeferredVideoEnhancementSupported(): boolean;

  public abstract enableDeferredVideoEnhance(): boolean;

  public abstract start(): Promise<boolean>;

  public abstract stop(): Promise<void>;

  public abstract pause(): Promise<void>;

  public abstract resume(): Promise<void>;

  public abstract release(): Promise<void>;

  public abstract setRotation(angles: number, message: VideoOutputMessage): Promise<void>;

  public abstract isMirrorSupported(): boolean;

  public abstract enableMirror(isMirror: boolean): void;

  public abstract isAutoVideoFrameRateSupported(): boolean;

  public abstract enableAutoVideoFrameRate(isEnable: boolean): void;

  public isPreRecordingSupported(): boolean {
    return false;
  }

  public async setOutputSettings(rotation?: number): Promise<void> {
    HiLog.i(TAG, 'setOutputSettings is null implementation.');
    return;
  }

  public togglePreRecording(on: boolean): Promise<void> {
    return;
  }

  public getSupportedVideoMetaTypes(): number[] {
    HiLog.i(TAG, 'getSupportedVideoMetaTypes is null implementation.');
    return [];
  }

  public attachMetaSurface(videoMetaType: number): Promise<void> {
    HiLog.i(TAG, `attachMetaSurface is null implementation, metaType: ${videoMetaType}.`);
    return;
  }

  public checkSurfaceAndReconstruct(message: VideoOutputMessage, cameraManager: camera.CameraManager):
    Promise<camera.VideoOutput> {
    return undefined;
  }

  public async startWithPreRecording(): Promise<boolean> {
    HiLog.e(TAG, 'startWithPreRecording is null implementation, invoke start.');
    const isSuccess = await this.start();
    return isSuccess;
  }

  public setFilter(filter: string): void {
    HiLog.e(TAG, `setFilter is null implementation, filter: ${filter}.`);
  }

  public setWatermark(hasWatermark: boolean, rotate: number, position: camera.CameraPosition): void {
    HiLog.i(TAG, `setWatermark is null implementation, hasWatermark: ${hasWatermark}, rotate: ${rotate
      }, position: ${position}.`);
  }
}