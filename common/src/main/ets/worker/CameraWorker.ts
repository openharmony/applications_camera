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

import worker from '@ohos.worker';
import lazy { CameraTaskHandler } from '../camera/childthread/CameraTaskHandler';
import type { MessageInfo } from '../camera/uithread/CameraProxy';
import lazy { SYNC_TASK_TYPES } from '../camera/uithread/TaskManager';
import lazy { HiLog } from '../utils/HiLog';
//TODO  import SetQosNative from 'libSetQosNative.so';
import lazy { WorkerTask } from '../camera/WorkerTask';

/* instrument ignore file */
const TAG = 'CameraWorker';
const workerPort = worker.workerPort;
let mCameraTaskHandler: CameraTaskHandler = new CameraTaskHandler();
let isRealTimeQos: boolean = false;

workerPort.onmessage = async function (e): Promise<void> {
  let msg: MessageInfo = e.data;
  if (!msg.type) {
    HiLog.e(TAG, `onmessage msg.type undefined, msg: ${JSON.stringify(msg)}.`);
    return;
  }
  if (!isRealTimeQos) {
    HiLog.begin(TAG, 'setQosUserInteractive');
    //TODO  SetQosNative.setQosUserInteractive();
    HiLog.end(TAG, 'setQosUserInteractive');
    isRealTimeQos = true;
  }
  if (msg.type === WorkerTask.ACTION_CLOSE_CAMERA && isRealTimeQos) {
    HiLog.begin(TAG, 'resetQos');
    //TODO  SetQosNative.resetQos();
    HiLog.end(TAG, 'resetQos');
    isRealTimeQos = false;
  }
  HiLog.i(TAG, `UI to worker: msg.type = ${msg.type}.`);
  let taskResult: unknown;
  try {
    taskResult = await mCameraTaskHandler.solveTask(msg.type, msg.data);
  } catch (err) {
    if (SYNC_TASK_TYPES.includes(msg.type)) {
      HiLog.e(TAG, `worker solveTask error: ${err},type:${msg.type}`);
    }
  }
  HiLog.i(TAG, `Worker to UI: msg.type = ${msg.type}.`);
  if (msg.hasResolve) {
    workerPort.postMessage({ type: msg.type, data: taskResult, hasResolve: true });
  }
};

workerPort.onerror = function (e): void {
  HiLog.e(TAG, `worker onerror: ${e.message}.`);
};