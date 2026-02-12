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
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { GlobalContext } from '../../../utils/GlobalContext';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { workerCallback } from '../WorkerCallback';
import PhotoOutputWrap from './PhotoOutputWrap';

/* instrument ignore file */
const TAG: string = 'OfflinePhotoOutput';
const RELEASE_PHOTO_OUTPUT_DELAY: number = 100;


export default class OfflinePhotoOutput {
  private offlineStartTime: number; // 开始触发离线拍照时间点
  private timeOutTimerId: number = Number.MIN_VALUE; // 超时退出离线拍照定时器
  private mPhotoOutputWrap: PhotoOutputWrap; // 离线photoOutput
  private offlineCaptureArray: Set<number> = new Set(); // 待返回80分图 captureIds
  private burstOfflineCount: number = 0; // 连拍计数

  constructor(photoOutput: PhotoOutputWrap, captureIdList: number[], startTime: number, burstOfflineCount: number) {
    this.mPhotoOutputWrap = photoOutput;
    this.offlineStartTime = startTime;
    if (burstOfflineCount > 0) {
      this.burstOfflineCount = burstOfflineCount;
    } else {
      captureIdList.forEach((item) => {
        this.offlineCaptureArray.add(item);
      });
    }
    HiLog.i(TAG, `createOfflineOutput, burstOfflineCount: ${this.burstOfflineCount}, captureIds: ${captureIdList}`);
    this.timeOutTimerId = setTimeout(() => { // 离线拍照通路超时释放
      this.clearTimeOutTimerId();
      this.mPhotoOutputWrap.releasePhotoOutput();
      const duration: number = Date.now() - this.offlineStartTime;
      if (this.offlineCaptureArray.size > 0) {
        const loseCaptureIds: number[] = Array.from(this.offlineCaptureArray);
        HiLog.w(TAG, `offline timeout, captureIds: ${loseCaptureIds.toString()}`);
        workerCallback.updateOfflineCaptureArray(loseCaptureIds, false, 0);
      }
      const loseCount = this.burstOfflineCount > 0 ? this.burstOfflineCount : this.offlineCaptureArray.size;
      workerCallback.onOfflinePhotoFinish(false, loseCount, duration);
      GlobalContext.get().getCameraService().minusOffline(this.offlineStartTime);
    }, CommonConstants.OFFLINE_TIME_OUT_DELAY);
  }

  public offlinePhotoReceiveCallBack(captureId: number): void { // 离线拍照成功上来一张图
    if (captureId < 0) {
      HiLog.w(TAG, 'offlinePhotoReceive error');
      return;
    }
    if (this.burstOfflineCount > 0) {
      --this.burstOfflineCount;
    }
    HiLog.i(TAG, `offlinePhotoReceiveCallBack: ${captureId}, burstOfflineCount: ${this.burstOfflineCount}`);
    this.offlineCaptureArray.delete(captureId);
    const duration: number = Date.now() - this.offlineStartTime;
    const loseCount = this.burstOfflineCount > 0 ? this.burstOfflineCount : this.offlineCaptureArray.size;
    workerCallback.onOfflinePhotoReceive(duration, loseCount);
    if (this.offlineCaptureArray.size === 0 && this.burstOfflineCount === 0) {
      setTimeout(() => {
        this.mPhotoOutputWrap.releasePhotoOutput(); // 该条离线拍照流所有图片上报完成,释放拍照流
        this.clearTimeOutTimerId();
        workerCallback.onOfflinePhotoFinish(true, 0, duration);
        GlobalContext.get().getCameraService().minusOffline(this.offlineStartTime);
      }, RELEASE_PHOTO_OUTPUT_DELAY);
    }
  }

  public offlinePhotoFinishCallBack(): void { // 接收到offlineDeliveryFinished回调
    this.mPhotoOutputWrap.releasePhotoOutput(); // 释放拍照流
    this.clearTimeOutTimerId();
  }

  private clearTimeOutTimerId(): void {
    clearTimeout(this.timeOutTimerId);
    this.timeOutTimerId = Number.MIN_VALUE;
  }

}