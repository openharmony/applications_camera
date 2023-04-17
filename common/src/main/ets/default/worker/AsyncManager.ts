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

import { Log } from '../utils/Log'
import { Constants } from '../utils/Constants'
import { EventBus } from './eventbus/EventBus'
import { EventBusManager } from './eventbus/EventBusManager'

export interface Message {
  type: string,
  data: any
}

export class AsyncManager {
  private static TAG = '[AsyncManager]:'
  private workerName: string
  private workerUri: string
  protected mWorker: any
  private appEventBus: EventBus = EventBusManager.getWorkerInstance().getEventBus()
  private _appEventBus: EventBus = EventBusManager.getCameraInstance().getEventBus()

  constructor() {
    // todo 此处暂时只考虑了一个worker，后续改造支持多个worker创建
    this.workerName = 'AsyncManager'
    this.workerUri = 'workers/CameraWorker.js'
    this.initWorker()
  }

  public static getInstance(): AsyncManager {
    if (!AppStorage.Has(Constants.APP_KEY_ASYNC_MANAGER)) {
      AppStorage.SetOrCreate(Constants.APP_KEY_ASYNC_MANAGER, new AsyncManager())
      Log.info(`${this.TAG} build new AsyncManager.`)
    }
    return AppStorage.Get(Constants.APP_KEY_ASYNC_MANAGER)
  }

  //todo 预留实现，待能力稳定后开放
  //  private initWorker(): void {
  //    this.mWorker = new worker.Worker(this.workerUri, {type: 'classic', name: this.workerName})
  //    Log.info(`${AsyncManager.TAG} build the worker.`)
  //    this.mWorker.onmessage = (...args) => {
  //      Log.info(`${AsyncManager.TAG} mWorker.onmessage`)
  //      this.onMessage(args[0].data)
  //    }
  //    this.mWorker.onmessageerror = this.onmessageerror.bind(this)
  //    this.mWorker.onerror = this.onerror.bind(this)
  //    this.mWorker.onexit = this.onexit.bind(this)
  //  }

  private initWorker(): void {
    this._appEventBus.on('WORKER_TO_MAIN', (...args) => {
      Log.info(`${AsyncManager.TAG} mWorker.onmessage`)
      this.onMessage(args[0])
    })
  }

  //todo 预留实现，待能力稳定后开放
  //  // 向worker线程发送消息
  //  public postMessage(msg: any): AsyncManager {
  //    this.mWorker.postMessage(msg)
  //    return this
  //  }

  // 向worker线程发送消息
  public postMessage(msg: Message): void {
    Log.info(`${AsyncManager.TAG} postMessage`)
    this.appEventBus.emit('MAIN_TO_WORKER', [msg])
  }

  // 接收worker线程返回的UiData
  public onMessage(msg: Message): void {
    Log.info(`${AsyncManager.TAG} onMessage uidata: ${JSON.stringify(msg.data)}`)
  }

  public onmessageerror(msg: Message): void {

  }

  public onerror(msg: Message): void {

  }

  public onexit(msg: Message): void {

  }
}