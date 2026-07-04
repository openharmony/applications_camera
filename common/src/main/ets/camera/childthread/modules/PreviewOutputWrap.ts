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
import CameraOutput from './CameraOutput';
import type camera from '@ohos.multimedia.camera';
import type CameraContext from './CameraContext';
import type CameraDeviceManager from './CameraDeviceManager';
import lazy { BusinessError } from '@ohos.base';
import lazy { workerCallback } from '../WorkerCallback';

/* instrument ignore file */
const TAG: string = 'PreviewOutputWrap';

// PreviewOut包装类
export default class PreviewOutputWrap extends CameraOutput {
  private mPreviewOutput!: camera.PreviewOutput;
  private mSurface: string = '';
  private mPreviewOutputImageReceiver!: camera.PreviewOutput;
  private mImageReceiverSurfaceId: string = '';
  private mIsCollaborateControl: boolean = false;

  constructor(cameraDeviceManager: CameraDeviceManager, cameraContext: CameraContext) {
    super(cameraDeviceManager, cameraContext);
  }

  public init(profile: camera.Profile, surfaceId: string, cameraManager: camera.CameraManager): void {
    HiLog.i(TAG, `createPreviewOutput previewProfile ${JSON.stringify(profile)}, surfaceId: ${surfaceId}.`);
    this.mPreviewOutput = cameraManager.createPreviewOutput(profile, surfaceId);
    HiLog.i(TAG, `createPreviewOutput previewProfile. ${JSON.stringify(this.mPreviewOutput)}`);
    this.mSurface = surfaceId;
    HiLog.i(TAG, `createPreviewOutput X surfaceId: ${surfaceId}.`);
    this.registerPreviewListener();
    // this.registerSlowMoZoomChangePreview();
  }

  public initCollaborate(profile: camera.Profile, surfaceId: string, cameraManager: camera.CameraManager): void {
    // lem 镜像智拍 外屏专用预览流
    HiLog.i(TAG, `initCollaborate previewProfile ${JSON.stringify(profile)}, surfaceId: ${surfaceId}.`);
    this.mPreviewOutput = cameraManager.createPreviewOutput(profile, surfaceId);
    this.mSurface = surfaceId;
    this.registerCollaboratePreviewListener();
  }

  public initTimeLapseFront(profile: camera.Profile, surfaceId: string, cameraManager: camera.CameraManager): void {
    this.mPreviewOutputImageReceiver = cameraManager.createPreviewOutput(profile, surfaceId);
    this.mImageReceiverSurfaceId = surfaceId;
    this.registerImageReceiverPreviewListener();
  }

  public setCollaborateControl(): void {
    this.mIsCollaborateControl = true;
  }

  public initDeferred(profile: camera.Profile, cameraManager: camera.CameraManager): void {
    // profile ={"format":1003,"size":{"width":720,"height":1080}}
    HiLog.i(TAG, `createDeferredPreviewOutput initDeferred previewProfile: ${JSON.stringify(profile)}.`);
    try {
      this.mPreviewOutput = cameraManager.createDeferredPreviewOutput(profile);
    } catch (e) {
      HiLog.e(TAG, `createDeferredPreviewOutput failed, mSurface: ${this.mSurface}.`);
      this.mPreviewOutput = cameraManager.createPreviewOutput(profile, this.mSurface);
    }
    this.registerPreviewListener();
    // this.registerSlowMoZoomChangePreview();
  }

  public addDeferredSurface(surfaceId: string): void {
    HiLog.i(TAG, `addDeferredSurfaceId: ${surfaceId}.`);
    try {
      HiLog.begin(TAG, 'addDeferredSurface');
      workerCallback.setAddsurfaceTime(Date.now());
      this.mPreviewOutput.addDeferredSurface(surfaceId);
      HiLog.end(TAG, 'addDeferredSurface');
      this.mSurface = surfaceId;
    } catch (e) {
      HiLog.e(TAG, 'addDeferredSurface failed.');
    }
  }

  public removeDeferredSurface(surfaceId: string): boolean {
    HiLog.i(TAG, `removeDeferredSurface: ${surfaceId}.`);
    let success: boolean = true;
    try {
      HiLog.begin(TAG, 'removeDeferredSurface');
      // @ts-ignore
      this.mPreviewOutput.removeDeferredSurface(surfaceId);
      HiLog.end(TAG, 'removeDeferredSurface');
    } catch (e) {
      HiLog.e(TAG, 'removeDeferredSurface failed.');
      success = false;
    }
    if (success) {
      HiLog.i(TAG, `removeDeferredSurface: ${surfaceId} success`);
      this.mSurface = '';
    }
    return success;
  }

  public swapDeferredSurface(surfaceId: string): void {
    HiLog.i(TAG, `swapDeferredSurface: ${surfaceId}.`);
    if (this.removeDeferredSurface(this.mSurface)) {
      HiLog.i(TAG, `swapDeferredSurface remove success`);
      this.addDeferredSurface(surfaceId);
      HiLog.i(TAG, `swapDeferredSurface add finish`);
    } else {
      HiLog.i(TAG, `swapDeferredSurface remove failed`);
    }
  }

  public hasSurface(): boolean {
    return this.mSurface !== '';
  }

  public async release(): Promise<void> {
    if (this.mPreviewOutput) {
      this.mPreviewOutput.off('frameStart');
      this.mPreviewOutput.off('frameEnd');
      this.mPreviewOutput.off('sketchStatusChanged');
      // this.unRegisterSlowMoZoomChangePreview();
      await this.mPreviewOutput.release();
      this.mPreviewOutput = null;
    }
  }

  public getOutput(): camera.PreviewOutput {
    return this.mPreviewOutput;
  }

  public getImageReceiverOutput(): camera.PreviewOutput {
    return this.mPreviewOutputImageReceiver;
  }

  private registerPreviewListener(): void {
    if (this.mIsCollaborateControl) {
      this.registerCollaborateControlPreviewListener();
      return;
    }
    this.mPreviewOutput.on('frameStart', (err) => this.frameStartCallback(err));
    this.mPreviewOutput.on('frameEnd', (err) => this.frameEndCallback(err));
  }

  private registerCollaboratePreviewListener(): void {
    this.mPreviewOutput.on('frameStart', (err) => this.collaborateFrameStartCallback(err));
  }

  private registerCollaborateControlPreviewListener(): void {
    this.mPreviewOutput.on('frameStart', (err) => this.collaborateControlFrameStartCallback(err));
    this.mPreviewOutput.on('frameEnd', (err) => this.collaborateControlFrameEndCallback(err));
  }

  private registerImageReceiverPreviewListener(): void {
    this.mPreviewOutputImageReceiver.on('frameStart', (err) => this.frameStartCallback(err));
    this.mPreviewOutputImageReceiver.on('frameEnd', (err) => this.frameEndCallback(err));
  }

  // private registerSlowMoZoomChangePreview(): void { // 慢动作变焦预览流状态变化触发模糊
  //   try {
  //     // @ts-ignore
  //     this.mPreviewOutput.on('framePause', (err) => {
  //       this.slowMoZoomChangePreviewCallBack(err, false);
  //     });
  //     // @ts-ignore
  //     this.mPreviewOutput.on('frameResume', (err) => {
  //       this.slowMoZoomChangePreviewCallBack(err, true);
  //     });
  //   } catch (e) {
  //     HiLog.e(TAG, `registerSlowMoZoomChangePreview err:${JSON.stringify(e)}`);
  //   }
  // }

  // private unRegisterSlowMoZoomChangePreview(): void {
  //   try {
  //     // @ts-ignore
  //     this.mPreviewOutput.off('framePause');
  //     // @ts-ignore
  //     this.mPreviewOutput.off('frameResume');
  //   } catch (e) {
  //     HiLog.e(TAG, `unRegisterSlowMoZoomChangePreview err:${JSON.stringify(e)}`);
  //   }
  // }

  private slowMoZoomChangePreviewCallBack(err, isPreviewFrameStart): void {
    if (err) {
      HiLog.e(TAG, ` slowMo zoom change preview error: ${err?.code}.`);
      return;
    }
    workerCallback.onSlowMotionPreviewChange(isPreviewFrameStart);
  }

  public enableSketch(): void {
    try {
      if (!this.mPreviewOutput.isSketchSupported()) {
        HiLog.i(TAG, 'enableSketch previewOutput sketch is not supported.');
        return;
      }
      HiLog.i(TAG, 'previewOutput enableSketch invoke.');
      this.mPreviewOutput.enableSketch(true);
    } catch (e) {
      HiLog.i(TAG, `enableSketch error, ${e}`);
    }

    this.mPreviewOutput.on('sketchStatusChanged', (err, data: camera.SketchStatusData) => {
      if (err) {
        HiLog.i(TAG, `sketchStatusChangedCallback frame start error: ${err?.code}.`);
        return;
      }
      HiLog.i(TAG, `sketchStatusChanged: status = ${data.status}-----sketchRatio = ${data.sketchRatio} ----data = ${JSON.stringify(data)}}`);
      const status: number = data.status;
      const sketchRatio: number = data.sketchRatio;
      // @ts-ignore
      const centerPointOffset: camera.Point = data.centerPointOffset;
      workerCallback.onSketchStatusChanged(status, sketchRatio, centerPointOffset);
    });
  }

  public addPipSurface(pipSurfaceId: string): void {
    try {
      if (!this.mPreviewOutput.isSketchSupported()) {
        HiLog.i(TAG, 'enableSketch previewOutput sketch is not supported.');
        return;
      }
      HiLog.i(TAG, `previewOutput addPipSurface invoke, surface:${pipSurfaceId}.`);

      this.mPreviewOutput.attachSketchSurface(pipSurfaceId);
    } catch (e) {
      HiLog.i(TAG, 'attachSketchSurface fail.');
    }
  }

  // -------- 下述注册相机框架监听回调方法 --------

  private frameStartCallback(err): void {
    if (err) {
      HiLog.e(TAG, `frameStartCallback frame start error: ${err?.code}.`);
      return;
    }
    HiLog.begin(TAG, 'previewOutput frame start!');
    workerCallback.onPreviewFrameStart(Date.now());
    HiLog.end(TAG, 'previewOutput frame start!');
  }

  private collaborateFrameStartCallback(err): void {
    if (err) {
      HiLog.e(TAG, `collaborateFrameStartCallback frame start error: ${err?.code}.`);
      return;
    }
    HiLog.i(TAG, 'collaborate previewOutput frame start!');
    workerCallback.onCollaboratePreviewFrameStart();
  }

  private collaborateControlFrameStartCallback(err): void {
    if (err) {
      // 通知手表起流失败
      HiLog.e(TAG, `collaborateFrameStartCallback frame start error: ${err?.code}.`);
      workerCallback.onCollaborateControlPreviewFrameError();
      return;
    }
    HiLog.i(TAG, 'collaborate previewOutput frame start!');
    workerCallback.onCollaborateControlPreviewFrameStart();
  }

  private collaborateControlFrameEndCallback(err): void {
    if (err) {
      // 通知手表起流失败
      HiLog.e(TAG, `collaborateFrameStartCallback frame end error: ${err?.code}.`);
      workerCallback.onCollaborateControlPreviewFrameError();
      return;
    }
    HiLog.i(TAG, 'collaborate previewOutput frame end!');
    workerCallback.onCollaborateControlPreviewFrameEnd();
  }

  private frameEndCallback(err): void {
    if (err) {
      HiLog.e(TAG, `frameEndCallback frame start error: ${err?.code}.`);
      return;
    }
    HiLog.i(TAG, 'previewOutput frame end!');
  }

  public async previewOutputStop(): Promise<void> {
    try {
       await this.mPreviewOutput.stop();
    } catch (error) {
      let err = error as BusinessError;
      HiLog.i(TAG, 'Failed to beginConfig. errorCode = ' + err?.code);
    }
  }

  public async previewOutputStart(): Promise<void> {
    try {
      await this.mPreviewOutput.start();
    } catch (error) {
      let err = error as BusinessError;
      HiLog.i(TAG, 'Failed to beginConfig. errorCode = ' + err?.code);
    }
  }

  public getPreviewRotation(imageRotation: number): camera.ImageRotation {
    return this.mPreviewOutput.getPreviewRotation(imageRotation);
  }

  public setPreviewRotation(previewRotation: number, isDisplayLocked: boolean): void {
    this.mPreviewOutput.setPreviewRotation(previewRotation, isDisplayLocked);
  }

  public isLogAssistanceSupported(): boolean {
    HiLog.i(TAG, 'LogStyle check isLogAssistanceSupported');
    let isLogAssistanceSupported: boolean = false;
    try {
      // @ts-ignore
      isLogAssistanceSupported = this.mPreviewOutput.isLogAssistanceSupported();
      return isLogAssistanceSupported;
    } catch (e) {
      HiLog.i(TAG, `LogStyle check isLogAssistanceSupported failed: ${e}`);
    }
    return false;
  }

  public enableLogAssistance(enable: boolean): void {
    HiLog.i(TAG, 'LogStyle enableLogAssistance = ' + enable);
    try {
      // @ts-ignore
      this.mPreviewOutput.enableLogAssistance(enable);
    } catch (e) {
      HiLog.i(TAG, `LogStyle enableLogAssistance failed: ${e}`);
    }
  }

  // 使能预览hebc格式
  public enableBandwidthCompression(): void {
    try {
      // @ts-ignore
      let isSupported = this.mPreviewOutput.isBandwidthCompressionSupported();
      HiLog.i(TAG, `isBandwidthCompressionSupported: ${isSupported}.`);
      if (!isSupported) {
        return;
      }
      HiLog.i(TAG, 'enableBandwidthCompression: true.');
      // @ts-ignore
      this.mPreviewOutput.enableBandwidthCompression(isSupported);
    } catch (e) {
      HiLog.i(TAG, `enableBandwidthCompression failed: ${e}.`);
    }
  }
}