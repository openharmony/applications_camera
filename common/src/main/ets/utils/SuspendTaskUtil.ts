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
      this.savePhotoTask = setTimeout(() => {
        HiLog.w(TAG, 'save photo timeout, close camera');
        SuspendTaskUtil.getInstance().resetCount();
        CameraProxy.getInstance().resetWorkerPhotoCount();
        this.mAction.close();
        this.stopDelayTask();
        this.setAlreadyCloseCamera(true);
      }, this.SUSPEND_TASK_DELAY);
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