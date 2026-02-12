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

// @ts-nocheck
import lazy { HiLog } from '../../../../utils/HiLog';
import camera from '@ohos.multimedia.camera';
import lazy { workerCallback } from '../../WorkerCallback';
import VideoOutputInterface from './VideoOutputInterface';
import type { TagMessage, VideoOutputMessage } from '../../../DataType';
import lazy { simpleStringify } from '../../../../utils/SimpleStringify';
import lazy { BusinessError } from '@kit.BasicServicesKit';
import lazy { LOCATION_MESSAGE } from '../../CameraTaskHandler';
import lazy { modulesManager } from '../../../../worker/WorkerModuleManager';
import media from '@ohos.multimedia.media';
import lazy { HideBugUtil } from '../../../../utils/HideBugUtil';
import lazy { photoAccessHelper } from '@kit.MediaLibraryKit';
import lazy { Fail } from '../../../../utils/types';
import lazy { GlobalContext } from '../../../../utils/GlobalContext';
import { WatermarkOperation } from '../../../../service/watermark/WatermarkOperation';

/* instrument ignore file */
const TAG: string = 'MovieFileOutputCinemaWrap';

const WATER_MARK_PATH_KEY: string = 'RESOURCE_DIRECTORY';
const WATER_MARK_DIRECTION: string = 'FILTER_WATER_DIRECTION';
const INPLACE_STICKER: string = 'InplaceSticker';


export enum FocusTrackingMode {
  AUTO = 0,
  LOCKED = 1
}

export interface FocusTrackingMetaInfo {
  trackingMode: FocusTrackingMode;
  trackingRegion: camera.Rect;
  trackingObjectId: number;
  detectedObjects: Array<camera.MetadataObject>;
}

export enum ApertureEffect {
  EFFECT_NORMAL = 0,
  EFFECT_LOWLIGHT = 1,
  EFFECT_MACRO = 2
}

// MovieFileOutput包装类
export default class MovieFileOutputCinemaWrap extends VideoOutputInterface {
  private movieFileOutput!: camera.MovieFileOutput;
  private isRecording: boolean = false;
  private isDeferEnabled: boolean = false;
  private videoCodec: media.CodecMimeType | undefined = undefined;
  private stopTime: number = 0;

  public async init(message: VideoOutputMessage, tagMessage: TagMessage,
    cameraManager: camera.CameraManager): Promise<void> {
    HiLog.i(TAG, `RECORD_TRACK init begin, profile: ${simpleStringify(message.videoProfile)}.`);
    this.movieFileOutput = cameraManager.createMovieFileOutput(message.videoProfile);
    try {
      // @ts-ignore
      const profile: camera.Profile = this.movieFileOutput.getActiveProfile();
      HiLog.i(TAG, `RECORD_TRACK createMovieFileOutput end, profile: ${simpleStringify(profile)}.`);
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK getActiveProfile error: ${simpleStringify(err)}.`);
    }
    this.videoCodec = message.config?.profile?.videoCodec;
    HiLog.i(TAG, `RECORD_TRACK init end, movieFileOutput: ${this.movieFileOutput}, videoCodec: ${this.videoCodec}.`);

    this.registerSaveFileListeners();
  }

  // 存图
  private registerSaveFileListeners(): void {
    try {
      // @ts-ignore
      this.movieFileOutput.on('photoAssetAvailable', async (err: BusinessError, asset: photoAccessHelper.PhotoAsset): Promise<void> => {
        if (err || !asset) {
          HiLog.e(TAG, `RECORD_TRACK photoAssetAvailable error: ${simpleStringify(err)}.`);
          return;
        }
        HiLog.i(TAG, `RECORD_TRACK photoAssetAvailable success, uri: ${asset.uri}`);
        const mediaLibrary = await modulesManager.getMediaLibrary();
        HiLog.begin(TAG, 'RECORD_TRACK saveMovieInfoAsset');
        const error: Fail = await mediaLibrary.saveMovieInfoAsset(asset);
        if (error.isFail) {
          workerCallback.onSaveVideoFail(error.failReason);
        }
        workerCallback.saveMovieInfoAssetDone(Date.now() - this.stopTime);
        HiLog.end(TAG, 'RECORD_TRACK saveMovieInfoAsset');
      });
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK movieFileOutput on photoAssetAvailable error: ${simpleStringify(err)}.`);
    }
  }

  /*
   * MovieFile需要设置，VideoOutput不需要，通过AVRecorder设置
   * setOutputSettings，HEVC支持HDR，AVC不支持HDR，默认使用HEVC
   */
  public async setOutputSettings(): Promise<void> {
    let types: camera.VideoCodecType[] = [];
    try {
      types = this.movieFileOutput.getSupportedVideoCodecTypes();
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK getSupportedVideoCodecTypes error: ${err}.`);
    }
    let type = camera.VideoCodecType.AVC;
    if (this.videoCodec === media.CodecMimeType.VIDEO_HEVC) {
      type = camera.VideoCodecType.HEVC;
    }
    HiLog.i(TAG, `RECORD_TRACK setOutputSettings videoCodecs: ${simpleStringify(types)}, videoCodec: ${this.videoCodec
    }, type: ${type}.`);
    try {
      await this.movieFileOutput.setOutputSettings({
        // @ts-ignore
        codecType: type,
        location: LOCATION_MESSAGE.location
      });
      HiLog.i(TAG, `RECORD_TRACK setOutputSettings end, videoCodec: ${type}.`);
      // @ts-ignore
      const setting : camera.MovieSettings = this.movieFileOutput.getOutputSettings();
      HiLog.i(TAG, `RECORD_TRACK getOutputSettings: ${simpleStringify(setting)}.`);
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK setOutputSettings error: ${err}.`);
    }
  }

  public getOutput(): camera.MovieFileOutput {
    return this.movieFileOutput;
  }

  public isAutoDeferredVideoEnhancementSupported(): boolean {
    try {
      // @ts-ignore
      const isDeferSupport: boolean = this.movieFileOutput.isAutoDeferredVideoEnhancementSupported();
      return isDeferSupport;
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK SEGMENT_VIDEO enableDeferredVideoEnhance error: ${err?.code}.`);
    }
    return false;
  }

  public enableDeferredVideoEnhance(): boolean {
    try {
      HiLog.i(TAG, 'SEGMENT_VIDEO enableAutoDeferredVideoEnhancement invoke.');
      // @ts-ignore
      this.movieFileOutput.enableAutoDeferredVideoEnhancement(true);
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK SEGMENT_VIDEO enableAutoDeferredVideoEnhancement error: ${err?.code}.`);
    }
    try {
      HiLog.i(TAG, 'SEGMENT_VIDEO isAutoDeferredVideoEnhancementEnabled invoke.');
      // @ts-ignore
      this.isDeferEnabled = this.movieFileOutput.isAutoDeferredVideoEnhancementEnabled();
      HiLog.i(TAG, `RECORD_TRACK SEGMENT_VIDEO DeferVideo now isEnabled: ${this.isDeferEnabled}.`);
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK SEGMENT_VIDEO enableDeferredVideoEnhance error: ${err?.code}.`);
    }
    return this.isDeferEnabled;
  }

  public async start(): Promise<boolean> {
    HiLog.i(TAG, 'RECORD_TRACK movieFileOutput will start');
    this.isRecording = true;
    GlobalContext.get().setLastCameraShotKey(GlobalContext.get().getCameraShotKey());
    try {
      await this.movieFileOutput.start();
      HiLog.i(TAG, 'RECORD_TRACK movieFileOutput start.');
    } catch (e) {
      this.isRecording = false;
      HiLog.e(TAG, `RECORD_TRACK movieFileOutput start error: ${simpleStringify(e)}.`);
    }
    return this.isRecording;
  }

  public async startWithPreRecording(): Promise<boolean> {
    HiLog.i(TAG, 'RECORD_TRACK movieFileOutput will startWithPreRecording');
    GlobalContext.get().setLastCameraShotKey(GlobalContext.get().getCameraShotKey());
    try {
      this.isRecording = true;
      // @ts-ignore
      const captureId = await this.movieFileOutput.startWithPreRecording();
      HiLog.i(TAG, `RECORD_TRACK movieFileOutput startWithPreRecording captureId: ${captureId}.`);
    } catch (e) {
      this.isRecording = false;
      HiLog.e(TAG, `RECORD_TRACK movieFileOutput startWithPreRecording error: ${simpleStringify(e)}.`);
    }
    return this.isRecording;
  }

  public async stop(): Promise<void> {
    this.isRecording = false;
    if (this.movieFileOutput) {
      try {
        HiLog.i(TAG, 'RECORD_TRACK movieFileOutput will stop.');
        await this.movieFileOutput.stop();
        this.stopTime = Date.now();
        const mem = HideBugUtil.getPss();
        workerCallback.onVideoRecordingStatus(mem);
        HiLog.i(TAG, 'movieFileOutput stop success.');
      } catch (e) {
        HiLog.e(TAG, `RECORD_TRACK stop video error: ${simpleStringify(e)}.`);
      }
    } else {
      HiLog.e(TAG, `RECORD_TRACK stopRecording error movieFileOutput: ${this.movieFileOutput}.`);
    }
    HiLog.i(TAG, 'stopRecording done.');
  }

  public async pause(): Promise<void> {
    this.isRecording = false;
    if (this.movieFileOutput) {
      try {
        HiLog.i(TAG, 'RECORD_TRACK movieFileOutput will pause.');
        // @ts-ignore
        await this.movieFileOutput.pause();
        HiLog.i(TAG, 'movieFileOutput pause success.');
      } catch (e) {
        HiLog.e(TAG, `RECORD_TRACK stop video error: ${simpleStringify(e)}.`);
      }
    } else {
      HiLog.e(TAG, `RECORD_TRACK stopRecording error movieFileOutput: ${this.movieFileOutput}.`);
    }
    HiLog.i(TAG, 'stopRecording done.');
  }

  public async resume(): Promise<void> {
    HiLog.i(TAG, 'RECORD_TRACK movieFileOutput will resume');
    try {
      this.isRecording = true;
      // @ts-ignore
      await this.movieFileOutput.resume();
    } catch (e) {
      this.isRecording = false;
      HiLog.e(TAG, `RECORD_TRACK movieFileOutput resume error: ${simpleStringify(e)}.`);
    }
  }

  public async setRotation(angles: number, message: VideoOutputMessage): Promise<void> {
    HiLog.i(TAG, `movieFileOutput setRotation: ${angles}, return null implementation.`);
  }

  public async release(): Promise<void> {
    // 在有画中画场景下的录像，如果已经开始录像，必须先stop再release
    if (this.isRecording) {
      await this.stop();
    }
    HiLog.i(TAG, 'RECORD_TRACK movieFileOutput will release');
    if (this.movieFileOutput) {
      this.clearListener();
      try {
        await this.movieFileOutput.release();
      } catch (err) {
        HiLog.e(TAG, `RECORD_TRACK movieFileOutput release err: ${err}.`);
      }
      this.movieFileOutput = null;
    }
  }

  //开启关闭录像镜像
  public enableMirror(isMirror: boolean): void {
    const isMirrorSupport = this.isMirrorSupported();
    HiLog.i(TAG, `RECORD_TRACK video Support: ${isMirrorSupport}, movieFileOutput enableMirror: ${isMirror}`);
    if (!isMirrorSupport) {
      return;
    }
    try {
      this.movieFileOutput.enableMirror(isMirror);
      HiLog.i(TAG, `RECORD_TRACK enableMirror: ${isMirror}`);
    } catch (e) {
      HiLog.e(TAG, `RECORD_TRACK movieFileOutput enableMirror error: ${simpleStringify(e)}.`);
    }
  }

  //判断能否开启镜像: 1、只有支持镜像设置才能设置；2、根据底层支持情况禁用设置页自拍镜像选项
  public isMirrorSupported(): boolean {
    try {
      const isSupportedMirror: boolean = this.movieFileOutput.isMirrorSupported();
      HiLog.i(TAG, `video isSupportedMirror: ${isSupportedMirror}`);
      return isSupportedMirror;
    } catch (e) {
      HiLog.e(TAG, `movieFileOutput isMirrorSupported error: ${simpleStringify(e)}.`);
      return false;
    }
  }

  //开启关闭录像动态帧率
  public enableAutoVideoFrameRate(isEnable: boolean): void {
    const isAutoVideoFrameRateSupport = this.isAutoVideoFrameRateSupported();
    HiLog.i(TAG, `RECORD_TRACK DynamicFrameRate video Support: ${isAutoVideoFrameRateSupport
    }, movieFileOutput enableAutoVideoFrameRate: ${isEnable}`);
    if (!isAutoVideoFrameRateSupport) {
      return;
    }
    try {
      // @ts-ignore
      this.movieFileOutput.enableAutoVideoFrameRate(isEnable);
    } catch (e) {
      HiLog.e(TAG, `RECORD_TRACK movieFileOutput enableAutoVideoFrameRate error.`);
    }
  }

  //判断能否开启动态帧率: 1、只有支持动态帧率设置才能设置；2、根据底层支持情况禁用设置页动态帧率选项
  public isAutoVideoFrameRateSupported(): boolean {
    try {
      // @ts-ignore
      const isAutoVideoFrameRateSupported: boolean = this.movieFileOutput.isAutoVideoFrameRateSupported();
      HiLog.i(TAG, `video isAutoVideoFrameRateSupported: ${isAutoVideoFrameRateSupported}`);
      return isAutoVideoFrameRateSupported;
    } catch (e) {
      HiLog.e(TAG, `movieFileOutput isAutoVideoFrameRateSupported error.`);
      return false;
    }
  }

  public isPreRecordingSupported(): boolean {
    try {
      // @ts-ignore
      const isPreRecordingSupported: boolean = this.movieFileOutput.isPreRecordingSupported();
      HiLog.i(TAG, `RECORD_TRACK isPreRecordingSupported: ${isPreRecordingSupported}.`);
      return isPreRecordingSupported;
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK PreRecord isPreRecordingSupported error: ${err}.`);
    }
    return false;
  }

  public async togglePreRecording(on: boolean): Promise<void> {
    try {
      HiLog.i(TAG, `RECORD_TRACK PreRecord enable: ${on}.`);
      // @ts-ignore
      await this.movieFileOutput.enablePreRecording(on);
      HiLog.i(TAG, 'RECORD_TRACK PreRecord enable finish.');
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK PreRecord enable error: ${err}.`);
    }
  }

  private clearListener(): void {
    try {
      // @ts-ignore
      this.movieFileOutput.off('photoAssetAvailable');
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK movieFileOutput off photoAssetAvailable error: ${err}.`);
    }
  }

  public setFilter(filter: string): void {
    HiLog.i(TAG, `RECORD_TRACK setFilter start, filter: ${filter}.`);
    try {
      // @ts-ignore
      this.movieFileOutput.setVideoFilter(filter);
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK setVideoFilter error: ${err}.`);
    }
  }

  public setWatermark(hasWatermark: boolean, rotate: number, position: camera.CameraPosition): void {
    HiLog.i(TAG, `RECORD_TRACK setWatermark start, hasWatermark: ${hasWatermark}.`);
    try {
      if (hasWatermark) {
        // @ts-ignore
        let path: string = WatermarkOperation.readWatermarkPath();
        this.movieFileOutput.setVideoFilter(INPLACE_STICKER, `{"${WATER_MARK_PATH_KEY}": "${path
        }", "${WATER_MARK_DIRECTION}": ${rotate}, "cameraPosition": ${position}}`);
      } else {
        // @ts-ignore
        this.movieFileOutput.setVideoFilter(INPLACE_STICKER, '');
      }
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK setWatermark error: ${err}.`);
    }
  }
}