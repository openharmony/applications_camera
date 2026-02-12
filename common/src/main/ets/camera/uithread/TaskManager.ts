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

import lazy { HiLog } from '../../utils/HiLog';
import type { MessageInfo, Callback } from './CameraProxy';
import type worker from '@ohos.worker';
import lazy { WorkerTask } from '../WorkerTask';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { RestartService } from '../../service/restart/RestartService';
import lazy { RecordController } from '../../function/recordcontrol/RecordController';
import { simpleStringify } from '../../utils/SimpleStringify';

/* instrument ignore file */

type ResolveType<T = void> = (value: T | PromiseLike<T>) => void;

const TAG: string = 'WorkerTaskManager';
const MAXIMUM_TIME: number = 1000 * 60 * 5;
const TASK_DURATION = 6000;

// 需要按照顺序依次执行的任务名单
export const SYNC_TASK_TYPES: string[] = [
  WorkerTask.ACTION_RECORD_STOP,
  WorkerTask.ACTION_RECORD_STOP_RECORDER,
  WorkerTask.ACTION_CLOSE_CAMERA,
  WorkerTask.ACTION_RECOVERY_WORKER_THREAD,
  WorkerTask.ACTION_INIT,
  WorkerTask.ACTION_START_PREVIEW,
  WorkerTask.ACTION_START_UP,
  WorkerTask.ACTION_RESTART_PREVIEW,
  WorkerTask.ACTION_CHANGE_MODE,
  WorkerTask.ACTION_RECORD_START,
  WorkerTask.ACTION_RECORD_START_RECORDER,
  WorkerTask.ACTION_SWITCH_CAMERA_CHANGE_MODE,
  WorkerTask.ACTION_SWITCH_CAMERA,
  WorkerTask.ACTION_SWAP_DEFERRED_SURFACE,
  WorkerTask.ACTION_ADD_DEFERRED_SURFACE,
  WorkerTask.SWITCH_COLLABORATION,
  WorkerTask.ACTION_COLLABORATE_CONTROL_PREVIEW_OUTPUT
];

const INITIATE_ACTION: string[] = [
  WorkerTask.ACTION_INIT,
  WorkerTask.ACTION_START_UP,
];

export class WorkerTaskManager {
  private worker: worker.ThreadWorker;
  public taskQueue: { type: string, resolve: unknown, callback?: unknown }[] = [];
  public syncQueue: {
    task: MessageInfo,
    resolve: unknown,
    time: number,
    callback?: unknown
  }[] = [];
  private isError: boolean = false;
  private taskTimer: number | null = null;

  constructor(worker: worker.ThreadWorker) {
    this.worker = worker;
  }

  // 执行后需要返回结果的子线程任务
  public postMessage<T>(task: MessageInfo, resolve: ResolveType<T>, callback?: unknown): void {
    HiLog.i(TAG, `postMessage: task type = ${task.type}.`);
    HiLog.i(TAG, `postMessage: data = ${simpleStringify(task.data)}`);
    this.worker.postMessage(task);
    this.taskQueue.push({ type: task.type, resolve: resolve, callback: callback });
    HiLog.i(TAG, `postMessage: tasks length = ${this.taskQueue.length}, taskQueue = ${this.taskQueue.map(t => t.type)
      .join(', ')}`);
  }

  // 需要按照下发顺序执行的子线程任务
  public postMessageWithSync<T>(task: MessageInfo, resolve: ResolveType<T>, callback?: unknown): void {
    HiLog.i(TAG, `postMessageWithSync: task type = ${task.type}.`);
    HiLog.i(TAG, `postMessageWithSync: data = ${simpleStringify(task.data)}`);
    this.closeActionResolute(task.type);
    if (this.isError && DeviceInfo.isPhone()) {
      if (INITIATE_ACTION.includes(task.type)) {
        this.isError = false;
      }
    }
    const currentTime = Date.now();
    if (DeviceInfo.isPhone() && this.syncQueue.length > 0 && currentTime - this.syncQueue[0].time > MAXIMUM_TIME) {
      HiLog.i(TAG, 'SyncTask execution times out and the ability restarts..');
      RestartService.getInstance().recoveryRestartApp();
    }
    this.syncQueue.push({ task: task, resolve: resolve, time: 0, callback: callback });
    if (this.syncQueue.length === 1) {
      HiLog.i(TAG, `postMessage: syncTask type = ${task.type}.`);
      HiLog.i(TAG, `postMessage: data = ${simpleStringify(task.data)}`);
      this.worker.postMessage(task);
      this.syncQueue[0].time = currentTime;
      this.taskDuration();
    }
    const tasks: string = this.syncQueue.map(t => t.task.type).join(', ');
    HiLog.i(TAG, `postMessage: syncTasks length = ${this.syncQueue.length}, queue = ${tasks}. task = ${JSON.stringify(task)}. `);
  }

  public closeActionResolute(type: string): void {
    if (type !== WorkerTask.ACTION_CLOSE_CAMERA) {
      return;
    }
    HiLog.i(TAG, `postMessage: syncTask CLOSE_CAMERA, clear queue.`);
    if (this.syncQueue.length <= 1) {
      return;
    }
    if (!RecordController.getInstance().isMovieFile()) {
      this.syncQueue = [this.syncQueue[0]];
      return
    }
    let stopRecordIndex = 0;
    for (let i = 1; i < this.syncQueue.length; i++) {
      if (this.syncQueue[i].task.type === WorkerTask.ACTION_RECORD_STOP) {
        stopRecordIndex = i;
        break;
      }
    }
    this.syncQueue = stopRecordIndex === 0 ? [this.syncQueue[0]] : [this.syncQueue[0], this.syncQueue[stopRecordIndex]];
  }

  public onMessage(result: MessageInfo): void {
    HiLog.i(TAG, `onMessage: ${result.type}, data: ${result.data}.`);
    if (SYNC_TASK_TYPES.includes(result.type)) {
      this.solveSyncTaskResult(result);
    } else {
      this.solveAsyncTaskResult(result);
    }
  }

  private solveSyncTaskResult(result: MessageInfo): void {
    if (this.syncQueue.length === 0) {
      HiLog.e(TAG, 'onMessage, syncQueue length still zero.');
      return;
    }
    if (this.syncQueue[0].task.type !== result.type) {
      HiLog.e(TAG, `onMessage syncTasks error. resultType: ${result.type}, firstType: ${this.syncQueue[0].task.type}.`);
    } else {
      const element = this.syncQueue.shift();
      const duration: number = Date.now() - element.time;
      HiLog.i(TAG, `onMessage syncTask type: ${result.type}, worker duration time: ${duration}.`);
      this.applyResolveAndCallback(<Callback> element.resolve, <Callback> element.callback, result.data);
      HiLog.i(TAG, 'applyResolveAndCallback done');
    }
    // 查询并继续执行下个任务
    if (this.syncQueue.length > 0) {
      const task = this.syncQueue[0].task;
      HiLog.i(TAG, `postMessage: syncTask type = ${task.type}.`);
      this.worker.postMessage({ hasResolve: true, type: task.type, data: task.data });
      this.syncQueue[0].time = Date.now();
      this.taskDuration();
    }
  }

  private solveAsyncTaskResult(result: MessageInfo): void {
    // 使用从子线程返回的结果执行主线程回调
    if (this.taskQueue.length === 0) {
      HiLog.e(TAG, 'onMessage, taskQueue length still zero.');
      return;
    }
    HiLog.i(TAG, `onMessage result type: ${result.type}, taskQueue: ${this.taskQueue.map(t => t.type).join(', ')}, .`);
    const index = this.taskQueue.findIndex(item => item.type === result.type);
    if (index === -1) {
      HiLog.e(TAG, `onMessage taskQueue error, result type: ${result.type}, findIndex: -1.`);
      return;
    }
    const element = this.taskQueue[index];
    this.taskQueue.splice(index, 1);
    HiLog.i(TAG, `onMessage: taskQueue splice end, now length = ${this.taskQueue.length}.`);
    this.applyResolveAndCallback(<Callback> element.resolve, <Callback> element.callback, result.data);
  }

  private applyResolveAndCallback(resolveCallback: Callback, callback: Callback, data: unknown): void {
    if (callback) {
      callback.apply(this, [data]);
    }
    if (resolveCallback) {
      resolveCallback.apply(this, [data]);
    }
    HiLog.i(TAG, 'onMessage: apply resolve and callback done.');
  }

  public excludes(...taskType: string[]): boolean {
    const tasks: string[] = this.taskQueue.map(t => t.type);
    const syncTasks: string[] = this.syncQueue.map(t => t.task.type);
    for (let i = 0; i < taskType.length; i++) {
      if (syncTasks.includes(taskType[i]) || tasks.includes(taskType[i])) {
        return false;
      }
    }
    return true;
  }

  private taskExecutionTimedOut(): boolean {
    const curTime: number = Date.now();
    const element = this.syncQueue[0];
    if (curTime > element.time + MAXIMUM_TIME) {
      HiLog.e(TAG, `SyncTask error! task: ${element.task.type}, execution duration time: ${curTime - element.time}.`);
      return true;
    }
    return false;
  }

  public cameraError(): void {
    this.isError = true;
  }

  private taskDuration(): void {
    if (this.taskTimer) {
      clearTimeout(this.taskTimer);
    }
    this.taskTimer = setTimeout(() => {
      const time = Date.now();
      if (this.syncQueue.length > 0 && time - this.syncQueue[0].time > 5500) {
      }
    }, TASK_DURATION);
  }

  public checkSyncTaskIsTimeout(): boolean {
    const currentTime = Date.now();
    if (DeviceInfo.isPhone() && this.syncQueue.length > 0 && currentTime - this.syncQueue[0].time > 5000) {
      HiLog.e(TAG, 'checkSyncTask confirm timeout 5000ms.');
      this.syncQueue = [];
      return true;
    }
    return false;
  }
}