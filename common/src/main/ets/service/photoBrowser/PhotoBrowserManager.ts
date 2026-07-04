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
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { execDispatch } from '../../redux';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { PhotoBrowserAction } from './PhotoBrowserAction';

const TAG: string = 'PhotoBrowserManager';
const DELAY_HIDDEN_TIME: number = 500;

export class PhotoBrowserManager {
  private static sInstance: PhotoBrowserManager;
  private timer: number = Number.NaN;

  public static getInstance(): PhotoBrowserManager {
    if (!PhotoBrowserManager.sInstance) {
      PhotoBrowserManager.sInstance = new PhotoBrowserManager();
    }
    return PhotoBrowserManager.sInstance;
  }

  public setViewHidden(): void {
    HiLog.i(TAG, 'setViewHidden.');
    if(DeviceInfo.isPhone()){
      HiLog.begin(TAG, 'setViewVisibilityFalse');
      execDispatch(PhotoBrowserAction.setViewVisibility(false));
      HiLog.end(TAG, 'setViewVisibilityFalse');
      return;
    }
    if (!Number.isNaN(this.timer)) {
      clearTimeout(this.timer);
    }
    this.timer = setTimeout(() => {
      HiLog.i(TAG, 'setViewVisibility false.');
      HiLog.begin(TAG, 'setViewVisibilityFalse');
      execDispatch(PhotoBrowserAction.setViewVisibility(false));
      HiLog.end(TAG, 'setViewVisibilityFalse');
      this.timer = Number.NaN;
    }, DELAY_HIDDEN_TIME);
  }

  public setViewVisibility(): void {
    HiLog.i(TAG, 'setViewVisibility.');
    if(DeviceInfo.isPhone()){
      HiLog.begin(TAG, 'setViewVisibilityTrue');
      execDispatch(PhotoBrowserAction.setViewVisibility(true));
      HiLog.end(TAG, 'setViewVisibilityTrue');
      return;
    }
    if (!Number.isNaN(this.timer)) {
      clearTimeout(this.timer);
      this.timer = Number.NaN;
    }
    HiLog.i(TAG, 'setViewVisibility true.');
    HiLog.begin(TAG, 'setViewVisibilityTrue');
    execDispatch(PhotoBrowserAction.setViewVisibility(true));
    HiLog.end(TAG, 'setViewVisibilityTrue');
  }
}