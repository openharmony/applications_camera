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

import lazy { HiLog } from '../../utils/HiLog'
import { photoAccessHelper } from "@kit.MediaLibraryKit";
import lazy { GlobalContext } from '../../utils/GlobalContext'
import { hilog } from "@kit.PerformanceAnalysisKit";
import { workerCallback } from '../../camera/childthread/WorkerCallback';
import { worker } from '@kit.ArkTS';

const TAG: string = "LRSwipeWorkerSvs"
const SHUTTER_DOWN: number = 0;
const SHUTTER_UP: number = 1;
const NEED_DELETE: number = -1;
const ANIM_DURATION_LR_LONG_CLICK: number = 600;
const SLEEP: Function = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms))
const WAIT_SVE_GRT_THUMB_TIME = 150;
const NORMAL_MIN_SHUTTER_DOWN_UP_INTERVAL: number = 40;

export class LeftRightSwipeWorkerCaptureService {
  private static sInstanceService: LeftRightSwipeWorkerCaptureService;
  private mPhotoAccessHelper: photoAccessHelper.PhotoAccessHelper;
  private shutterUpWaitTimeout: number = -1;
  private shutterUpLongClickWaiTimeout: number = -1;
  private captureQueue: Queue<number> = new Queue<number>();
  private backTrackSingleCaptureQueue: Queue<RequestFormatMapStruct> = new Queue<RequestFormatMapStruct>();
  private offlineCaptureArray: Set<number> = new Set();

  constructor() {
    this.mPhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(GlobalContext.get().getWorkerContext());
  }

  public static getInstance(): LeftRightSwipeWorkerCaptureService {
    if (!LeftRightSwipeWorkerCaptureService.sInstanceService) {
      LeftRightSwipeWorkerCaptureService.sInstanceService = new LeftRightSwipeWorkerCaptureService();
    }
    this.sInstanceService.checkPhotoAccessHelper();
    return LeftRightSwipeWorkerCaptureService.sInstanceService;
  }

  public checkPhotoAccessHelper(): void {
    HiLog.i(TAG, "checkPhotoAccessHelper", "photoAccessHelper undefined, retry.")
    if (!this.mPhotoAccessHelper) {
      this.mPhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(GlobalContext.get().getWorkerContext())
    }
  }

  public shutterButtonUp(shutterInterval: number): void {
    HiLog.i(TAG, "shutterButtonUp intv: " + shutterInterval)
    if (shutterInterval < NORMAL_MIN_SHUTTER_DOWN_UP_INTERVAL) {
      HiLog.i(TAG, "shutterButtonUp set timeout, intv: " + NORMAL_MIN_SHUTTER_DOWN_UP_INTERVAL)
      this.shutterUpWaitTimeout = setTimeout(() => {
        HiLog.i(TAG, "exe shutterButtonUpCheck shutterUp after intv")
        HiLog.i(TAG, "clearTimeout shutterUpLongClickWaiTimeout:after intv")
        clearTimeout(this.shutterUpLongClickWaiTimeout);
        this.doShutterButtonUpCheck();
      }, NORMAL_MIN_SHUTTER_DOWN_UP_INTERVAL - shutterInterval);
      return
    }
    HiLog.i(TAG, "exe shutterButtonUpCheck shutterUp normal")
    HiLog.i(TAG, "clearTimeout shutterUpLongClickWaiTimeout:shutterUp normal")
    HiLog.i(TAG, "clearTimeout shutterUpWaitTimeout:shutterUp normal")
    clearTimeout(this.shutterUpLongClickWaiTimeout);
    clearTimeout(this.shutterUpWaitTimeout);
    this.doShutterButtonUpCheck();
  }

  public setSingleCaptureRequestForDelete(request: photoAccessHelper.MediaChangeRequest,
    saveCameraType: photoAccessHelper.ImageFileType | undefined, captureId: number): void {
    let enqueueStruct = {
      fileType: saveCameraType,
      request: request,
    } as RequestFormatMapStruct;
    this.backTrackSingleCaptureQueue.enqueueAtBack(enqueueStruct);
    HiLog.i(TAG, `setSingleCaptureRequestForDelete captureQueue [${this.captureQueue.length()}]` +
      `backTrackSingleCaptureQueue:[${this.backTrackSingleCaptureQueue.length()}]`);
    this.checkDeletePhoto(captureId);
  }

  private doShutterButtonUpCheck(): void {
    this.shutterUpWaitTimeout = -1;
    this.shutterUpLongClickWaiTimeout - 1;
    this.previousShutterButtonCommandUp();
    HiLog.i(TAG, `shutterButtonUp captureQueue [${this.captureQueue.length()}]` +
      `backTrackSingleCaptureQueue:[${this.backTrackSingleCaptureQueue.length()}]`);
    this.checkDeletePhoto();
  }

  private previousShutterButtonCommandUp(): void {
    let lastCommand: number | undefined = this.captureQueue.peekLast();
    if (SHUTTER_DOWN === lastCommand) {
      this.captureQueue.dequeueAtBack();
      this.captureQueue.enqueueAtBack(SHUTTER_UP);
      workerCallback.onPhotoProcessed(true, true);
    }
  }

  public modeSwitchRelease(): void {
    // 模式切换时， 还没上报的照片会因为没有 output release 不再上报
    HiLog.i(TAG, `modeSwitchRelease captureQueue [${this.captureQueue.length()}]` +
      `backTrackSingleCaptureQueue:[${this.backTrackSingleCaptureQueue.length()}]`);
    this.previousShutterButtonCommandUp();
    this.checkDeletePhoto();
    this.captureQueue = new Queue<number>();
    HiLog.i(TAG, `modeSwitchRelease end captureQueue [${this.captureQueue.length()}]` +
      `backTrackSingleCaptureQueue:[${this.backTrackSingleCaptureQueue.length()}]`);
    if (!this.backTrackSingleCaptureQueue.isEmpty()) {
      let captureNum = this.backTrackSingleCaptureQueue.length();
      for (let i = 0; i < captureNum; i++) {
        this.captureQueue.enqueueAtBack(NEED_DELETE);
      }
      this.checkDeletePhoto()
    }
  }

  public captureError(): void {
    this.captureQueue.dequeueAtBack();
    HiLog.i(TAG, `captureError, captureQueue [${this.captureQueue.length()}]` +
      `backTrackSingleCaptureQueue:[${this.backTrackSingleCaptureQueue.length()}]`);
  }

  private checkDeletePhoto(captureId?: number): void {
    if (!this.isNeedSavePhoto(captureId)) {
      HiLog.i(TAG, `checkDeletePhoto captureQueue [${this.captureQueue.length()}]` +
        `backTrackSingleCaptureQueue:[${this.backTrackSingleCaptureQueue.length()}]`);
      return
    }
    while (this.isNeedSavePhoto(captureId)) {
      let firstCommand: number = this.captureQueue.peek();
      if (SHUTTER_DOWN === firstCommand) {
        break;
      } else {
        this.comsumeOnePhotoCheck(captureId);
      }
    }
  }

  public shutterCapture(isDownCapture: boolean): void {
    this.previousShutterButtonCommandUp();
    if (isDownCapture) {
      this.captureQueue.enqueueAtBack(SHUTTER_DOWN);
    } else {
      this.captureQueue.enqueueAtBack(SHUTTER_UP);
      // 抬手拍照场景
      workerCallback.onPhotoProcessed(true, true);
    }
    HiLog.i(TAG, `shutterCapture captureQueue [${this.captureQueue.length()}]` +
      `backTrackSingleCaptureQueue:[${this.backTrackSingleCaptureQueue.length()}]`);
    if (this.shutterUpWaitTimeout !== -1 || this.shutterUpLongClickWaiTimeout !== -1) {
      HiLog.i(TAG,
        `exe doShutterButtonUpCheck at capture, clearTimeouts ${this.shutterUpWaitTimeout} and ${this.shutterUpLongClickWaiTimeout}`)
      HiLog.i(TAG, "clearTimeout shutterUpLongClickWaiTimeout:at capture")
      HiLog.i(TAG, "clearTimeout shutterUpWaitTimeout:at capture")
      clearTimeout(this.shutterUpLongClickWaiTimeout);
      clearTimeout(this.shutterUpWaitTimeout);
      this.doShutterButtonUpCheck();
      return;
    }
    HiLog.i(TAG, "600ms later check")
    this.shutterUpLongClickWaiTimeout = setTimeout(() => {
      HiLog.i(TAG, "exe shutterButtonUpCheck 600ms after capture")
      HiLog.i(TAG, "clearTimeout shutterUpLongClickWaiTimeout:600ms after capture")
      clearTimeout(this.shutterUpWaitTimeout);
      this.doShutterButtonUpCheck()
    }, ANIM_DURATION_LR_LONG_CLICK)
  }

  private async comsumeOnePhotoCheck(captureId?: number) {
    let firstCommand: number = this.captureQueue.dequeueAtFront();
    const isOfflineSavePhoto: boolean = captureId && this.offlineCaptureArray.has(captureId);
    if (isOfflineSavePhoto) {
      HiLog.i(TAG, `comsumeOnePhotoCheck offlineSavePhoto, captureId:${captureId}}`)
      this.offlineCaptureArray.delete(captureId)
    }
    let dataStruct: RequestFormatMapStruct = this.backTrackSingleCaptureQueue.dequeueAtFront();
    let request: photoAccessHelper.MediaAssetChangeRequest = dataStruct.request;
    let saveCameraType: photoAccessHelper.ImageFileType | undefined = dataStruct.fileType;
    HiLog.i(TAG, `comsumeOnePhotoCheck:${request?.getAsset().uri}`);
    try {
      let logMsg: string;
      if (NEED_DELETE === firstCommand && !isOfflineSavePhoto) {
        HiLog.i(TAG, `comsumeOnePhotoCheck discardCameraPhoto 1.1:${request?.getAsset().uri}`);
        logMsg = `comsumeOnePhotoCheck discard:${request?.getAsset().uri}`;
        let discardRequest: photoAccessHelper.MediaAssetChangeRequest =
          new photoAccessHelper.MediaAssetChangeRequest(request.getAsset());
        request = discardRequest;
        request.discardCameraPhoto();
      } else {
        HiLog.i(TAG, `comsumeOnePhotoCheck normal save:${request?.getAsset().uri}`);
        logMsg = `comsumeOnePhotoCheck save :${request?.getAsset().uri}`;
        this.saveRequest(request, saveCameraType);
      }
      workerCallback.onDeferPhotoReport(request.getAsset().uri);
      HiLog.begin(TAG, logMsg);
      await this.mPhotoAccessHelper.applyChanges(request)
      HiLog.end(TAG, logMsg);
      if (captureId) {
        workerCallback.onDeferPhotoSaveEnd(captureId, false); // 80分图保存完成
      }
      workerCallback.onDeferPhotoMediaUri(request.getAsset().uri) // 单拍场景
    } catch (err) {
      HiLog.e(TAG, `comsumeOnePhotoCheck error: ${err}, ${err?.code}}`)
      workerCallback.onDeferPhotoMediaUri(undefined);
    }
    HiLog.i(TAG, `after comsumeOnePhotoCheck captureQueue [${this.captureQueue.length()}]` +
      `backTrackSingleCaptureQueue:[${this.backTrackSingleCaptureQueue.length()}]`);
  }

  private saveRequest(mediaRequest: photoAccessHelper.MediaAssetChangeRequest,
    saveCameraType: photoAccessHelper.ImageFileType | undefined): void {
    try {
      HiLog.i(TAG, `request apply saveCameraPhoto with type: ${saveCameraType}.`)
      mediaRequest.saveCameraPhoto(saveCameraType);
    } catch (err) {
      HiLog.e(TAG, `SEGMENT_CAPTURE YUV-HEIF-setJPEG saveCameraPhoto err: ${err?.code}.`)
      mediaRequest.saveCameraPhoto();
    }
    HiLog.i(TAG, `SEGMENT_CAPTURE saveCameraPhoto end.`)
  }

  public needDeleteOnePhoto(thumbnailAnimAvailable: boolean) {
    HiLog.i(TAG, `clearTimeout shutterUpLongClickWaiTimeout:needDeleteOnePhoto`)
    clearTimeout(this.shutterUpLongClickWaiTimeout);
    this.shutterUpLongClickWaiTimeout = -1;
    let lastCommand: number | undefined = this.captureQueue.peekLast();
    if (SHUTTER_DOWN === lastCommand) {
      this.captureQueue.dequeueAtBack();
      this.captureQueue.enqueueAtBack(NEED_DELETE);
      // 删图场景，可能因为thumbnailAnimAvailable而更新缩略图
      workerCallback.onPhotoProcessed(false, thumbnailAnimAvailable)
    }
    HiLog.i(TAG, `needDeleteOnePhoto captureQueue [${this.captureQueue.length()}]` +
      `backTrackSingleCaptureQueue:[${this.backTrackSingleCaptureQueue.length()}]`);
    this.checkDeletePhoto();
  }

  private isNeedSavePhoto(captureId?: number): boolean {
    if (captureId && this.offlineCaptureArray.has(captureId)) {
      return true;
    }
    return this.captureQueue.length() != 0 && this.backTrackSingleCaptureQueue.length() != 0;
  }
}


class RequestFormatMapStruct {
  public fileType: photoAccessHelper.ImageFileType | undefined = undefined;
  public request: photoAccessHelper.MediaAssetChangeRequest = undefined;
}

class Queue<T> {
  private elements: T[] = [];

  public enqueueAtBack(item: T): void {
    this.elements.push(item);
  }

  public enqueueAtFront(item: T): void {
    this.elements.unshift(item);
  }

  public dequeueAtFront(): T | undefined {
    return this.elements.shift();
  }

  public dequeueAtBack(): T | undefined {
    return this.elements.pop();
  }

  public peek(): T | undefined {
    return this.elements[0];
  }

  public peekLast(): T | undefined {
    return this.elements[this.elements.length - 1];
  }

  public length(): number {
    return this.elements.length;
  }

  public isEmpty(): boolean {
    return this.elements.length === 0;
  }
}