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
import CameraContext from '../CameraContext';
import lazy { workerCallback } from '../../WorkerCallback';
import type { PickerInfo } from '../../../../utils/types';
import VideoOutputInterface from './VideoOutputInterface';
import RecorderWrap from './RecorderWrap';
import type { TagMessage, VideoOutputMessage } from '../../../DataType';
import lazy { simpleStringify } from '../../../../utils/SimpleStringify';
import lazy { HideBugUtil } from '../../../../utils/HideBugUtil';

/* instrument ignore file */
const TAG: string = 'VideoOutputWrap';

//视频流使用的角度
const ANGLES_180 = 180;
const ANGLES_360 = 360;

// VideoOutput包装类
export default class VideoOutputWrap extends VideoOutputInterface {
  private videoOutput!: camera.VideoOutput;
  // 流程控制
  private mIsRecording: boolean = false;
  // 数据缓存
  private mSurface: string = '';
  private pickerInfo: PickerInfo = {
    isPicker: false,
    callingTokenID: -1,
    callerPid: -1
  };
  private isDeferEnabled: boolean = false;

  constructor() {
    super();
  }

  public async init(message: VideoOutputMessage, tagMessage: TagMessage, cameraManager: camera.CameraManager,
    pickerInfo: PickerInfo): Promise<void> {
    HiLog.i(TAG, 'init begin.');
    // getInputSurface
    const surfaceId: string = await RecorderWrap.getInstance().getSurfaceSwiftly(message, tagMessage, pickerInfo);
    if (!surfaceId) {
      HiLog.e(TAG, 'surface is null, return.');
      return;
    }
    // createVideoOutput
    HiLog.i(TAG, `videoProfile: ${simpleStringify(message.videoProfile)}, videoId: ${surfaceId}.`);
    this.videoOutput = cameraManager.createVideoOutput(message.videoProfile, surfaceId);
    HiLog.i(TAG, `videoOutput: ${this.videoOutput}.`);
    this.mSurface = surfaceId;
    this.pickerInfo = pickerInfo || { isPicker: false, callingTokenID: -1, callerPid: -1 };
    HiLog.i(TAG, 'init end.');

    this.videoOutput.on('frameEnd', (err) => {
      HiLog.i(TAG, 'videoOutput frameEnd!!!');
      workerCallback.onVideoFrameEnd();
    })
  }

  public getOutput(): camera.VideoOutput {
    return this.videoOutput;
  }

  public isAutoDeferredVideoEnhancementSupported(): boolean {
    try {
      const isDeferSupport: boolean = this.videoOutput.isAutoDeferredVideoEnhancementSupported();
      return isDeferSupport;
    } catch (err) {
      HiLog.e(TAG, `SEGMENT_VIDEO enableDeferredVideoEnhance error: ${err?.code}.`);
    }
    return false;
  }

  public enableDeferredVideoEnhance(): boolean {
    try {
      this.videoOutput.enableAutoDeferredVideoEnhancement(true);
      HiLog.i(TAG, 'SEGMENT_VIDEO to query isAutoDeferredVideo.');
      this.isDeferEnabled = this.videoOutput.isAutoDeferredVideoEnhancementEnabled();
      HiLog.i(TAG, `SEGMENT_VIDEO DeferVideo now isEnabled: ${this.isDeferEnabled}.`);
      if (this.isDeferEnabled) {
        this.videoOutput.on('deferredVideoEnhancementInfo', (err, info: camera.DeferredVideoEnhancementInfo) => {
          HiLog.i(TAG, 'SEGMENT_VIDEO on deferredVideoEnhancementInfo Callback.');
          this.deferredVideoEnhancementCallback(err, info);
        });
      }
    } catch (err) {
      HiLog.e(TAG, `SEGMENT_VIDEO enableDeferredVideoEnhance error: ${err?.code}.`);
    }
    return this.isDeferEnabled;
  }

  public async start(): Promise<boolean> {
    HiLog.i(TAG, 'videoOutput will start');
    try {
      this.mIsRecording = true;
      await this.videoOutput.start();
    } catch (e) {
      this.mIsRecording = false;
      HiLog.e(TAG, `videoOutput start error: ${JSON.stringify(e)}.`);
    }
    let isSuccess: boolean = this.mIsRecording;
    if (isSuccess) {
      isSuccess = await RecorderWrap.getInstance().start();
      if (!isSuccess) {
        try {
          await this.videoOutput.stop();
        } catch (err) {
          HiLog.e(TAG, `videoOutput stop error: ${err}.`);
        }
      }
    }

    return isSuccess;
  }

  public async stop(): Promise<void> {
    this.mIsRecording = false;
    if (this.videoOutput) {
      try {
        HiLog.i(TAG, 'videoOutput will stop.');
        await this.videoOutput.stop();
        const mem = HideBugUtil.getPss();
        workerCallback.onVideoRecordingStatus(mem);
        HiLog.i(TAG, 'videoOutput stop success.');
      } catch (e) {
        HiLog.e(TAG, `stop video error: ${JSON.stringify(e)}.`);
      }
    } else {
      HiLog.e(TAG, `stopRecording error videoOutput: ${this.videoOutput}.`);
    }
    HiLog.i(TAG, 'stopRecording done.');
    await RecorderWrap.getInstance().stop();
    if (this.pickerInfo?.isPicker) {
      workerCallback.picker2ReleaseCameraFromMainThread();
    }
  }

  public async pause(): Promise<void> {
    this.mIsRecording = false;
    if (this.videoOutput) {
      try {
        HiLog.i(TAG, 'videoOutput will stop.');
        await this.videoOutput.stop();
        HiLog.i(TAG, 'videoOutput stop success.');
      } catch (e) {
        HiLog.e(TAG, `stop video error: ${JSON.stringify(e)}.`);
      }
    } else {
      HiLog.e(TAG, `stopRecording error videoOutput: ${this.videoOutput}.`);
    }
    HiLog.i(TAG, 'stopRecording done.');
    await RecorderWrap.getInstance().pause();
  }

  public async resume(): Promise<void> {
    HiLog.i(TAG, 'videoOutput will resume');
    await RecorderWrap.getInstance().resume();
    try {
      this.mIsRecording = true;
      await this.videoOutput.start();
    } catch (e) {
      this.mIsRecording = false;
      HiLog.e(TAG, `videoOutput start error: ${JSON.stringify(e)}.`);
    }
  }

  public async setRotation(angles: number, message: VideoOutputMessage): Promise<void> {
    if (!this.videoOutput || !this.isRotationSupported()) {
      HiLog.e(TAG, 'videoOutput is undefined.');
      return;
    }
    try {
      if (angles >= 0) {
        await this.videoOutput.setRotation(angles);
        HiLog.i(TAG, `videoOutput setRotation value: ${JSON.stringify(angles)}.`);
      }
    } catch (e) {
      HiLog.e(TAG, `videoOutput videoRotation error: ${JSON.stringify(e)}.`);
    }
    if (angles >= 0 && message.mirrorValue) {
      message.config.rotation = (message.config.rotation + ANGLES_180) % ANGLES_360;
    }
    if (message === undefined || message === null) {
      return;
    }
    await RecorderWrap.getInstance().prepareAccurately(message, this.pickerInfo);
  }

  public async release(): Promise<void> {
    // 在有画中画场景下的录像，如果已经开始录像，必须先stop再release
    if (this.mIsRecording) {
      await this.stop();
    }
    if (this.videoOutput) {
      try {
        this.videoOutput.off('deferredVideoEnhancementInfo');
      } catch (err) {
        HiLog.e(TAG, `videoOutput off deferredVideoEnhancementInfo err: ${err}.`);
      }

      try {
        this.videoOutput.off('frameEnd');
      } catch (err) {
        HiLog.e(TAG, `videoOutput off frameEnd err: ${err}.`);
      }

      try {
        await this.videoOutput.release();
      } catch (err) {
        HiLog.e(TAG, `videoOutput release err: ${err}.`);
      }
      this.videoOutput = null;
    }
  }

  //开启关闭录像镜像
  public enableMirror(isMirror: boolean): void {
    const isMirrorSupport = this.isMirrorSupported();
    HiLog.i(TAG, `video Support: ${isMirrorSupport}, videoOutput enableMirror: ${isMirror}`);
    if (!isMirrorSupport) {
      return;
    }
    try {
      this.videoOutput.enableMirror(isMirror);
      HiLog.i(TAG, `enableMirror : ${isMirror}`);
    } catch (e) {
      HiLog.e(TAG, `videoOutput enableMirror error: ${JSON.stringify(e)}.`);
    }
  }

  //判断能否开启镜像: 1、只有支持镜像设置才能设置；2、根据底层支持情况禁用设置页自拍镜像选项
  public isMirrorSupported(): boolean {
    try {
      const isSupportedMirror: boolean = this.videoOutput.isMirrorSupported();
      HiLog.i(TAG, `video isSupportedMirror: ${isSupportedMirror}`);
      return isSupportedMirror;
    } catch (e) {
      HiLog.e(TAG, `videoOutput isMirrorSupported error: ${JSON.stringify(e)}.`);
      return false;
    }
  }

  //判断是否支持setRotation
  public isRotationSupported(): boolean {
    try {
      const isSupportedRotation: boolean = this.videoOutput.isRotationSupported();
      HiLog.i(TAG, `video isSupportedRotation: ${isSupportedRotation}`);
      return isSupportedRotation;
    } catch (e) {
      HiLog.e(TAG, `videoOutput isRotationSupported error: ${JSON.stringify(e)}.`);
      return false;
    }
  }

  //开启关闭录像动态帧率
  public enableAutoVideoFrameRate(isEnable: boolean): void {
    const isAutoVideoFrameRateSupport = this.isAutoVideoFrameRateSupported();
    HiLog.i(TAG, `DynamicFrameRate: video Support: ${isAutoVideoFrameRateSupport}, videoOutput enableAutoVideoFrameRate: ${isEnable}`);
    if (!isAutoVideoFrameRateSupport) {
      return;
    }
    try {
      this.videoOutput?.enableAutoVideoFrameRate(isEnable);
    } catch (e) {
      HiLog.e(TAG, `videoOutput enableAutoVideoFrameRate error.`);
    }
  }

  //判断能否开启动态帧率: 1、只有支持动态帧率设置才能设置；2、根据底层支持情况禁用设置页动态帧率选项
  public isAutoVideoFrameRateSupported(): boolean {
    try {
      const isAutoVideoFrameRateSupported: boolean = this.videoOutput?.isAutoVideoFrameRateSupported();
      HiLog.i(TAG, `video isAutoVideoFrameRateSupported: ${isAutoVideoFrameRateSupported}`);
      return isAutoVideoFrameRateSupported;
    } catch (e) {
      HiLog.e(TAG, `videoOutput isAutoVideoFrameRateSupported error.`);
      return false;
    }
  }

  public getSupportedVideoMetaTypes(): number[] {
    HiLog.i(TAG, 'getSupportedVideoMetaTypes E');
    const videoMetaTypes: number[] = this.videoOutput.getSupportedVideoMetaTypes();
    // const videoMetaTypes = [0];
    HiLog.i(TAG, `getSupportedVideoMetaTypes videoMetaTypes: ${videoMetaTypes.toString()}`);
    return videoMetaTypes;
  }

  public async attachMetaSurface(videoMetaType: number): Promise<void> {
    try {
      const surface: string = await RecorderWrap.getInstance().getInputMetaSurface(videoMetaType);
      HiLog.i(TAG, `addMaintainDebugMetaData surface ${surface}`);
      if (surface) {
        this.videoOutput.attachMetaSurface(surface, videoMetaType);
      } else {
        HiLog.e(TAG, 'attachMetaSurface no surface');
      }
    } catch (err) {
      HiLog.i(TAG, `addMaintainDebugMetaData err: ${err?.code}`);
    }
  }

  public async checkSurfaceAndReconstruct(message: VideoOutputMessage, cameraManager: camera.CameraManager):
    Promise<camera.VideoOutput> {

    await RecorderWrap.getInstance().prepareAccurately(message, this.pickerInfo);
    // Surface校验，如果在之前有过路过一次像或者AVRecorder error重启，需要更换surface和videoOutput。
    const recorderSurface: string = RecorderWrap.getInstance().getSurfaceId();
    HiLog.i(TAG, `videoOutput surface: ${this.mSurface}, recorder surface: ${recorderSurface}.`);
    if (this.mSurface === recorderSurface) {
      return undefined;
    }
    const oldOutput = this.videoOutput;

    // createVideoOutput
    HiLog.i(TAG, `Reconstruct begin, profile: ${simpleStringify(message.videoProfile)}, suface: ${recorderSurface}.`);
    this.videoOutput = cameraManager.createVideoOutput(message.videoProfile, recorderSurface);
    HiLog.i(TAG, `videoOutput: ${this.videoOutput}.`);
    // 重新监听
    this.videoOutput.on('frameEnd', (err) => {
      HiLog.i(TAG, 'videoOutput frameEnd!!!');
      workerCallback.onVideoFrameEnd();
    })
    this.mSurface = recorderSurface;
    HiLog.i(TAG, 'Reconstruct end.');
    return oldOutput;
  }

  // -------- 下述注册相机框架监听回调方法 -------- //

  private deferredVideoEnhancementCallback(err, info): void {
    if (err) {
      HiLog.e(TAG, `deferredVideoEnhancementCallback error: ${err?.code}.`);
      return;
    }
    HiLog.i(TAG, `SEGMENT_VIDEO onCallback Info: ${info?.isDeferredVideoEnhancementAvailable}, ${info?.videoId}.`);
    if (!info?.isDeferredVideoEnhancementAvailable) {
      return;
    }
    CameraContext.getInstance().productVideoEnhancePhotoId(info.videoId);
  }
}