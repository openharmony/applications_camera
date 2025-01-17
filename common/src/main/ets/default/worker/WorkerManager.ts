/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import { ActionHandler } from './ActionHandler';
import { Log } from '../utils/Log';
import type { EventBus } from './eventbus/EventBus';
import { EventBusManager } from './eventbus/EventBusManager';
import type { ActionData } from '../redux/actions/Action';
import { getStore } from '../redux/store';

const TAG = '[WorkerManager]:';

export class WorkerManager {
  static parentPort = worker.parentPort;
  private actionHandler: ActionHandler = new ActionHandler();
  private _appEventBus: EventBus = EventBusManager.getCameraInstance().getEventBus();

  public onMessage(action: ActionData): void {
    getStore().dispatch(action);
  }

  //todo 预留实现，待能力稳定后开放
  //  // worker线程中通过该方法向UI线程发送消息，消息中包含type和data
  //  public postMessage(msg: any): void {
  //    Log.info(`${TAG} postMessage: ${JSON.stringify(msg)}`)
  //    WorkerManager.parentPort.postMessage(msg)
  //  }

  // worker线程中通过该方法向UI线程发送消息，消息中包含type和data
  public postMessage(msg: ActionData): void {
    Log.info(`${TAG} postMessage: ${JSON.stringify(msg)}`);
    this.onMessage(msg);
  }
}