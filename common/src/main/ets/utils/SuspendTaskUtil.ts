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

import lazy { backgroundTaskManager } from './LazyImportUtil';
import lazy { CameraProxy } from '../camera/uithread/CameraProxy';
import lazy { CameraAction } from '../camera/uithread/CameraAction';
import lazy { Dispatch, getDispatch } from '../redux';
import lazy { HiLog } from './HiLog';
import lazy { DeviceInfo } from '../component/deviceinfo/DeviceInfo';
import lazy { CommonConstants } from '../statistics/CommonConstants';

const TAG: string = 'SuspendTaskUtil';

class SuspendTaskDispatcher {
  private mDispatch: Dispatch;

  public setDispatch(dispatch: Dispatch): void {
    this.mDispatch = dispatch;
  }

  public close(): void {
    this.mDispatch(CameraAction.release(true));
  }
}

export class SuspendTaskUtil {

  private readonly SUSPEND_TASK_DELAY = 5000;
  private static mSuspendTaskInstance: SuspendTaskUtil;
  private thumbnailWithoutPhotoCount: number = 0;
  private requestId: number = -1;
  private alreadyCloseCamera: boolean = false;
  private mAction: SuspendTaskDispatcher = new SuspendTaskDispatcher();
  private isInBackground: boolean = false;
  private savePhotoTask: number = -1;
  private offlineCaptureArray: Set<number> = new Set(); // 待返回80分图 captureIds
  private burstOfflineCount: number = 0; // 连拍计数

  public static getInstance(): SuspendTaskUtil {
    if (!this.mSuspendTaskInstance) {
      this.mSuspendTaskInstance = new SuspendTaskUtil();
      this.mSuspendTaskInstance.mAction.setDispatch(getDispatch());
    }
    return this.mSuspendTaskInstance;
  }

  public requestSuspendDelay(reason: string): void {
    let delayTime: number;
    try {
      let delayInfo = backgroundTaskManager.requestSuspendDelay(reason, ()=> {
        HiLog.w(TAG, 'suspend delay task will timeout');
        this.stopDelayTask();
      });
      this.requestId = delayInfo.requestId;
      delayTime = delayInfo.actualDelayTime;
      HiLog.i(TAG, 'suspend delay task: ' + this.requestId + ' start, delay time: ' + delayTime);
      if (reason === CommonConstants.SUSPEND_DELAY_OFFLINE_REASON) {
        HiLog.i(TAG, 'suspend delay task offline');
        this.savePhotoTask = setTimeout(() => {
          HiLog.w(TAG, 'save photo timeout, release offlineOutput');
          this.resetOfflineCaptureArray();
          CameraProxy.getInstance().resetWorkerPhotoCount();
          this.stopDelayTask();
        }, CommonConstants.OFFLINE_TIME_OUT_DELAY);
      } else {
        this.savePhotoTask = setTimeout(() => {
          HiLog.w(TAG, 'save photo timeout, close camera');
          SuspendTaskUtil.getInstance().resetCount();
          CameraProxy.getInstance().resetWorkerPhotoCount();
          this.mAction.close();
          this.stopDelayTask();
          this.setAlreadyCloseCamera(true);
        }, this.SUSPEND_TASK_DELAY);
      }
    } catch (e) {
      HiLog.e(TAG, `suspend delay task err. ${JSON.stringify(e)}`);
    }
  }

  public stopDelayTask(): void {
    if (this.requestId > 0) {
      HiLog.i(TAG, 'suspend delay task stop: ' + this.requestId);
      try {
        backgroundTaskManager.cancelSuspendDelay(this.requestId);
        this.requestId = -1;
      } catch (e) {
        HiLog.e(TAG, `suspend delay task stop err. ${JSON.stringify(e)}`);
      }
    }
  }

  public addThumbnailCount(): void {
    ++this.thumbnailWithoutPhotoCount;
    HiLog.i(TAG, 'thumbnailWithoutPhotoCount++: ' + this.thumbnailWithoutPhotoCount);
  }

  public minusThumbnailCount(): void {
    --this.thumbnailWithoutPhotoCount;
    HiLog.i(TAG, 'thumbnailWithoutPhotoCount: ' + this.thumbnailWithoutPhotoCount);
    HiLog.i(TAG, 'isInBackground: ' + this.isInBackground + ' alreadyCloseCamera: ' + this.alreadyCloseCamera);
    if (this.isInBackground && !this.alreadyCloseCamera && this.thumbnailWithoutPhotoCount === 0) {
      HiLog.i(TAG, 'all photo received, close camera in suspend task');
      this.clearSavePhotoTask();
      this.mAction.close();
      this.stopDelayTask();
      this.setAlreadyCloseCamera(true);
    }
  }

  /**
   * 进入离线拍照或者超时释放拍照流时 更新captureIdList;连拍场景更新burstOfflineCount
   *
   * @param captureIdList captureIdList
   * @param isEnterOffline isEnterOffline
   * @param burstOfflineCount burstOfflineCount
   */
  public updateOfflineCaptureArray(captureIdList: number[], isEnterOffline: boolean, burstOfflineCount: number): void {
    this.burstOfflineCount = burstOfflineCount;
    if (captureIdList?.length <= 0) {
      HiLog.w(TAG, `updateOfflineCaptureArray captureIdList empty`);
      return;
    }
    if (isEnterOffline) {
      captureIdList.forEach((item) => {
        this.offlineCaptureArray.add(item);
      });
    } else {
      captureIdList.forEach((item) => {
        this.offlineCaptureArray.delete(item);
      });
    }
    HiLog.i(TAG,
      `updateOfflineCaptureArray: ${this.offlineCaptureArray.size}, ${isEnterOffline}, ${burstOfflineCount}`);
  }

  /**
   * 80分图保存结束
   *
   * @param captureId captureId
   * @param isBurstCapture isBurstCapture
   */
  public onDeferSavePhotoEnd(captureId: number, isBurstCapture: boolean): void {
    this.offlineCaptureArray.delete(captureId);
    if (this.burstOfflineCount > 0) {
      --this.burstOfflineCount;
    }
    if (isBurstCapture) {
      this.burstOfflineCount = 0;
    }
    HiLog.i(TAG,
      `onDeferSavePhotoEnd,captureId: ${captureId}, isInBackground: ${this.isInBackground}, ${this.offlineCaptureArray.size}, ${this.burstOfflineCount}`);
    // 80分图全部保存完成，结束短时任务
    if (this.isInBackground && this.offlineCaptureArray.size === 0 && this.burstOfflineCount === 0) {
      HiLog.i(TAG, 'all photo received and saved, stop suspend task');
      this.clearSavePhotoTask();
      this.stopDelayTask();
    }
  }

  public resetBurstOfflineCount(): void {
    this.burstOfflineCount = 0;
  }

  // 是否在离线拍照流程
  public isEnterOfflinePhoto(): boolean {
    HiLog.i(TAG, `isEnterOfflinePhoto:${this.offlineCaptureArray.size}, ${this.burstOfflineCount}`);
    return this.offlineCaptureArray.size > 0 || this.burstOfflineCount > 0;
  }

  public onRecordStopped(): void {
    HiLog.i(TAG, `onRecordStopped isbg: ${this.isInBackground} alreadyCloseCamera: ${this.alreadyCloseCamera}`);
    if (this.isInBackground && !this.alreadyCloseCamera && DeviceInfo.isTablet()) {
      HiLog.i(TAG, 'record state is stopped, close camera in suspend task');
      this.clearSavePhotoTask();
      this.mAction.close();
      this.stopDelayTask();
      this.setAlreadyCloseCamera(true);
    }
  }

  public getThumbnailCount(): number {
    return this.thumbnailWithoutPhotoCount;
  }

  public resetOfflineCaptureArray(): void {
    HiLog.i(TAG, 'reset offlineCaptureArray');
    this.offlineCaptureArray.clear();
    this.burstOfflineCount = 0;
  }

  public resetCount(): void {
    HiLog.i(TAG, 'reset thumbnailWithoutPhotoCount');
    this.thumbnailWithoutPhotoCount = 0;
  }

  public setAlreadyCloseCamera(hasCloseFlag: boolean): void {
    HiLog.i(TAG, 'setAlreadyCloseCamera: ' + hasCloseFlag);
    this.alreadyCloseCamera = hasCloseFlag;
  }

  public getAlreadyCloseCamera(): boolean {
    return this.alreadyCloseCamera;
  }

  public setIsInBackground(state: boolean): void {
    HiLog.i(TAG, 'setIsInBackground: ' + state);
    this.isInBackground = state;
  }

  public getIsInBackground(): boolean {
    return this.isInBackground;
  }

  public clearSavePhotoTask(): void {
    clearTimeout(this.savePhotoTask);
    HiLog.i(TAG, 'clearTimeout: ' + this.savePhotoTask);
  }

}