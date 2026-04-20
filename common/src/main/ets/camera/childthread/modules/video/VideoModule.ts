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

import lazy { HiLog } from '../../../../utils/HiLog';
import camera from '@ohos.multimedia.camera';
import type { PickerInfo } from '../../../../utils/types';
import lazy { VideoOutputWrap, MovieFileOutputWrap } from '../../../../utils/LazyImportUtil';
import lazy { TagMessage, VideoOutputMessage } from '../../../DataType';
import VideoOutputInterface from './VideoOutputInterface';
import CameraContext from '../CameraContext';
import lazy { ModeType } from '../../../../mode/ModeType';
import MovieFileOutputCinemaWrap from './MovieFileOutputCinemaWrap';

/* instrument ignore file */
const TAG: string = 'VideoModule';

// VideoOutput 和 MovieFileOutput包装类
export default class VideoModule {
  private static sInstance: VideoModule;
  private videoWrap: VideoOutputInterface;
  private pickerInfo: PickerInfo;

  private constructor() {
  }

  public static getInstance(): VideoModule {
    if (!VideoModule.sInstance) {
      VideoModule.sInstance = new VideoModule();
    }
    return VideoModule.sInstance;
  }

  public async createOutput(message: VideoOutputMessage, tagMessage: TagMessage, manager: camera.CameraManager,
    pickerInfo: PickerInfo): Promise<boolean> {
    HiLog.begin(TAG, 'createOutput');
    this.pickerInfo = pickerInfo;
    await this.release();
    if (message.isMovie) {
      HiLog.i(TAG, 'RECORD_TRACK isMovie, video create.');
      this.videoWrap = new MovieFileOutputWrap();
    } else {
      HiLog.i(TAG, 'isVideo, video create.');
      this.videoWrap = new VideoOutputWrap();
    }
    //TODO PC预览流定位到这里，因为这个任务的执行导致。怀疑是PC视频格式导致
    try {
      await this.videoWrap?.init(message, tagMessage, manager, pickerInfo);
    }catch ( error) {
      HiLog.e(TAG, `=====>>> video create error: ${error}`);
    }
    HiLog.end(TAG, 'createOutput');
    return true;
  }

  public getOutput(): camera.CameraOutput {
    if (this.videoWrap) {
      return this.videoWrap.getOutput();
    }
    HiLog.e(TAG, 'videoWrap is undefined.');
    return undefined;
  }

  public enableDeferredVideoEnhance(): boolean {
    if (!this.videoWrap) {
      HiLog.e(TAG, 'videoWrap is undefined.');
      return false;
    }
    HiLog.i(TAG, 'SEGMENT_VIDEO enableDeferredVideoEnhance begin');
    const isDeferSupport: boolean = this.videoWrap.isAutoDeferredVideoEnhancementSupported();
    HiLog.i(TAG, `RECORD_TRACK SEGMENT_VIDEO DeferVideo isSupport: ${isDeferSupport}.`);
    if (!isDeferSupport || (this.pickerInfo && this.pickerInfo.isPicker)) {
      return false;
    }
    return this.videoWrap.enableDeferredVideoEnhance();
  }

  public async start(): Promise<boolean> {
    if (!this.videoWrap) {
      HiLog.e(TAG, 'videoWrap is undefined.');
      return false;
    }
    const isSuccess = await this.videoWrap.start();
    return isSuccess;
  }

  public async startWithPreRecording(): Promise<boolean> {
    if (!this.videoWrap) {
      HiLog.e(TAG, 'videoWrap is undefined.');
      return false;
    }
    const isSuccess = await this.videoWrap.startWithPreRecording();
    return isSuccess;
  }

  public async stop(): Promise<void> {
    if (this.videoWrap) {
      await this.videoWrap.stop();
    }
  }

  public async pause(): Promise<void> {
    if (this.videoWrap) {
      await this.videoWrap.pause();
    }
  }

  public async resume(): Promise<void> {
    if (this.videoWrap) {
      await this.videoWrap.resume();
    }
  }

  public async release(): Promise<void> {
    if (this.videoWrap) {
      await this.videoWrap.release();
      this.videoWrap = undefined;
    }
  }

  public async setOutputSetting(rotation?: number): Promise<void> {
    if (this.videoWrap) {
      await this.videoWrap.setOutputSettings(rotation);
    }
  }

  //开启关闭录像镜像
  public enableMirror(isMirror: boolean): void {
    if (this.videoWrap) {
      this.videoWrap.enableMirror(isMirror);
    }
  }

  public isMirrorSupported(): boolean {
    if (this.videoWrap) {
      return this.videoWrap.isMirrorSupported();
    }
    return false;
  }

  //开启关闭录像动态帧率
  public enableAutoVideoFrameRate(isEnable: boolean): void {
    if (this.videoWrap) {
      this.videoWrap.enableAutoVideoFrameRate(isEnable);
    }
  }

  //判断能否开启动态帧率: 1、只有支持动态帧率设置才能设置；2、根据底层支持情况禁用设置页动态帧率选项
  public isAutoVideoFrameRateSupported(): boolean {
    if (this.videoWrap) {
      return this.videoWrap.isAutoVideoFrameRateSupported();
    }
    HiLog.e(TAG, 'videoWrap is undefined.');
    return false;
  }

  public async addMaintainDebugMetaData(): Promise<void> {
    HiLog.i(TAG, 'addMaintainDebugMetaData begin.');
    if (!this.videoWrap) {
      HiLog.w(TAG, `addMaintainDebugMetaData videoWrap or avRecorder is not exit!`);
      return;
    }
    let videoMetaTypes: number[]
    try {
      videoMetaTypes = this.videoWrap.getSupportedVideoMetaTypes();
      HiLog.e(TAG, `getSupportedVideoMetaTypes: ${JSON.stringify(videoMetaTypes)}.`);
    } catch (error) {
      HiLog.e(TAG, `getSupportedVideoMetaTypes err: ${error}.`);
      return;
    }
    if (!videoMetaTypes || !videoMetaTypes.length) {
      HiLog.w(TAG, `RECORD_TRACK addMaintainDebugMetaData there is no metaType supporting.`);
      return;
    }
    HiLog.i(TAG, `addMaintainDebugMetaData videoMetaTypes: ${videoMetaTypes.toString()}`);
    await this.videoWrap.attachMetaSurface(videoMetaTypes[0]);
    HiLog.i(TAG, 'addMaintainDebugMetaData end.');
  }

  public async setRotation(angles: number, message: VideoOutputMessage): Promise<void> {
    if (this.videoWrap) {
      await this.videoWrap.setRotation(angles, message);
    }
  }

  public async checkStartRecordingState(message: VideoOutputMessage, cameraManager: camera.CameraManager,
    restart: (oldOutput: camera.CameraOutput, output: camera.CameraOutput) => Promise<void>): Promise<void> {
    HiLog.i(TAG, 'checkStartRecordingState.');
    if (!this.videoWrap) {
      HiLog.e(TAG, `checkStartRecordingState return, videoWrap is not exit!`);
      return;
    }
    this.videoWrap.setWatermark(message.isAddWaterMark, message.config.rotation,
      CameraContext.getInstance().getCameraPosition());
    const oldOutput: camera.VideoOutput = await this.videoWrap.checkSurfaceAndReconstruct(message, cameraManager);
    if (!oldOutput) {
      return;
    }
    await restart(oldOutput, this.videoWrap.getOutput());
  }

  public isPreRecordingSupported(): boolean {
    if (!this.videoWrap) {
      HiLog.e(TAG, 'isPreRecordingSupported error: videoWrap is undefined.');
      return false;
    }
    const isPreRecordingSupported: boolean = this.videoWrap.isPreRecordingSupported();
    HiLog.i(TAG, `isPreRecordingSupported: ${isPreRecordingSupported}.`);
    return isPreRecordingSupported;
  }

  public togglePreRecording(on: boolean): void {
    if (!this.videoWrap) {
      HiLog.e(TAG, 'togglePreRecording error: videoWrap is undefined.');
      return;
    }
    if (this.videoWrap.isPreRecordingSupported()) {
      this.videoWrap.togglePreRecording(on);
    } else {
      HiLog.i(TAG, 'togglePreRecording error: isPreRecordingSupported false.');
    }
  }

  public setFilter(filter: string): void {
    if (!this.videoWrap) {
      HiLog.e(TAG, 'setFilter error: videoWrap is undefined.');
      return;
    }
    HiLog.i(TAG, `setFilter begin, filter: ${filter}.`);
    this.videoWrap.setFilter(filter);
  }

  public setWatermark(hasWatermark: boolean, rotate: number): void {
    if (!this.videoWrap) {
      HiLog.e(TAG, 'setWatermark error: videoWrap is undefined.');
      return;
    }
    HiLog.i(TAG, `setWatermark begin, hasWatermark: ${hasWatermark}, rotate: ${rotate}.`);
    this.videoWrap.setWatermark(hasWatermark, rotate, CameraContext.getInstance().getCameraPosition());
  }
}