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
import lazy { CameraAction } from '../camera/uithread/CameraAction';
import lazy { ZoomOperation } from '../function/zoombar/ZoomOperation';
import lazy { Dispatch, getStates } from '../redux';
import lazy { HiLog } from './HiLog';
import camera from '@ohos.multimedia.camera';
import lazy { ModeType, VdeCollapsedFilterModeType } from '../mode/ModeType';
import lazy { WindowAction } from '../service/window/WindowAction';
import lazy { PersistType, PreferencesService } from '../service/preferences/PreferencesService';
import lazy { PropTag } from '../service/preferences/PropTag';
import lazy { Action } from '../redux/actions/Action';
import lazy { MoreModeConfig } from '../mode/MoreModeConfig';
import lazy { ModePosWarmStartUtil } from '../mode/ModePosWarmStartUtil';

export enum CameraTask {
  OPEN = 'OPEN',
  CLOSE = 'CLOSE'
}

const TAG: string = 'TaskQueue';

export class TaskQueue {
  private mTaskList: CameraTask[] = [];
  private mIsDoing: boolean = false;
  private mDispatch: Dispatch = (data) => data;

  constructor() {
  }

  setDispatch(dispatch: Dispatch): void {
    this.mDispatch = dispatch;
  }

  public addTask(task: CameraTask): void {
    /* instrument ignore if */
    if (this.mTaskList.length === 0) {
      this.mTaskList.push(task);
    } else if (this.mTaskList[this.mTaskList.length - 1] !== task) {
      this.mTaskList.pop();
    }
    this.doTask();
  }

  public taskDone(): void {
    if (!this.mIsDoing) {
      return;
    }
    this.mIsDoing = false;
    this.doTask();
  }

  public doTask(): void {
    if (this.mIsDoing || this.mTaskList.length === 0) {
      return;
    }
    this.mIsDoing = true;
    const task = this.mTaskList.shift();
    if (task === CameraTask.OPEN) {
      HiLog.i(TAG, 'warmStart.');
      setTimeout((): void => {
        this.doWarmStart();
      }, 50);
    } else {
      this.mDispatch(CameraAction.close({
        isNeedSaveRestore: true,
        isNeedDelayClose: true,
        isEnterPhotoBrowser: true
      }));
      HiLog.i(TAG, 'close camera.');
      setTimeout((): void => {
        this.taskDone();
      }, 250);
    }
  }

  private doWarmStart(): void {
    ZoomOperation.getInstance().setRemainZoomRatio(true);
  }

  /* instrument ignore next */
  private updateVdeInnerFunctions(): void {
  }

  /* instrument ignore next */
  public warmStartVdeFromPhotoBrowser(): void {
    // 刷新底层CameraList及ModeBar
    this.mDispatch(CameraAction.initCameraList());
    MoreModeConfig.getInstance().processVdeCollapsedModeData(true);

    const preMode = getStates().get<ModeType>('modeReducer', 'mode');
    let newMode = preMode;
    let cameraPos = camera.CameraPosition.CAMERA_POSITION_FRONT;
    ModePosWarmStartUtil.startWithParams(preMode, newMode, cameraPos);
  }
}