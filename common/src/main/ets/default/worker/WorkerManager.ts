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

import worker from '@ohos.worker'

import { ActionHandler } from './ActionHandler'
import { Log } from '../utils/Log'
import { EventBus } from './eventbus/EventBus'
import { EventBusManager } from './eventbus/EventBusManager'

export class WorkerManager {
  private TAG = '[WorkerManager]:'
  private actionHandler: ActionHandler = new ActionHandler()
  static parentPort = worker.parentPort
  private _appEventBus: EventBus = EventBusManager.getCameraInstance().getEventBus()

  public onMessage(action: any): void {
    Log.info(`${this.TAG} action from main thread: ${JSON.stringify(action)}`)
    this.actionHandler.handleAction(action)
  }

  //todo 预留实现，待能力稳定后开放
  //  // worker线程中通过该方法向UI线程发送消息，消息中包含type和data
  //  public postMessage(msg: any): void {
  //    Log.info(`${this.TAG} postMessage: ${JSON.stringify(msg)}`)
  //    WorkerManager.parentPort.postMessage(msg)
  //  }

  // worker线程中通过该方法向UI线程发送消息，消息中包含type和data
  public postMessage(msg: any): void {
    Log.info(`${this.TAG} postMessage: ${JSON.stringify(msg)}`)
    this._appEventBus.emit('WORKER_TO_MAIN', [msg])
  }
}