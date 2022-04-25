/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import {CLog} from '../Utils/CLog'
import {Constants} from './Constants'
import {EventBus} from './EventBus'
import EventBusManager from './EventBusManager'

export class AsyncManager {
  private static TAG: string = '[AsyncManager]:'
  private workerName: string
  private workerUri: string
  protected mWorker: any
  private appEventBus: EventBus = EventBusManager.getWorkerInstance().getEventBus()
  private _appEventBus: EventBus = EventBusManager.getCameraInstance().getEventBus()

  constructor() {
    // todo 此处暂时只考虑了一个worker，后续改造支持多个worker创建
    this.workerName = "AsyncManager"
    this.workerUri = "workers/CameraWorker.js"
    this.initWorker()
  }

  public static getInstance(): AsyncManager {
    if (!AppStorage.Has(Constants.APP_KEY_ASYNC_MANAGER)) {
      AppStorage.SetOrCreate(Constants.APP_KEY_ASYNC_MANAGER, new AsyncManager())
      CLog.info(`${this.TAG} build new AsyncManager.`)
    }
    return AppStorage.Get(Constants.APP_KEY_ASYNC_MANAGER);
  }

  //todo 目前worker能力不足，暂时规避
//  private initWorker(): void {
//    this.mWorker = new worker.Worker(this.workerUri, {type: 'classic', name: this.workerName})
//    CLog.info(`${AsyncManager.TAG} build the worker.`)
//    this.mWorker.onmessage = (...args) => {
//      CLog.info(`${AsyncManager.TAG} mWorker.onmessage`)
//      this.onMessage(args[0].data)
//    }
//    this.mWorker.onmessageerror = this.onmessageerror.bind(this)
//    this.mWorker.onerror = this.onerror.bind(this)
//    this.mWorker.onexit = this.onexit.bind(this)
//  }

  private initWorker(): void {
    this._appEventBus.on('WORKER_TO_MAIN', (...args) => {
      CLog.info(`${AsyncManager.TAG} mWorker.onmessage`)
      this.onMessage(args[0])
    })
  }

  //todo 目前worker能力不足，暂时规避
//  // 向worker线程发送消息
//  public postMessage(msg: any): AsyncManager {
//    this.mWorker.postMessage(msg)
//    return this
//  }

  // 向worker线程发送消息
  public postMessage(msg: any): void {
    CLog.info(`${AsyncManager.TAG} postMessage`)
    this.appEventBus.emit('MAIN_TO_WORKER', [msg])
  }

  // 接收worker线程返回的UiData
  public onMessage(msg: any): void {
    CLog.info(`${AsyncManager.TAG} onMessage uidata: ${JSON.stringify(msg.data)}`)
  }

  public onmessageerror(msg: any): void {

  }

  public onerror(msg: any): void {

  }

  public onexit(msg: any): void {

  }

}