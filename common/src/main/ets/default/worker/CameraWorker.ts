

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

import { Log } from '../utils/Log'
import { Constants } from '../utils/Constants'
import { EventBus } from './eventbus/EventBus'
import { EventBusManager } from './eventbus/EventBusManager'
import { WorkerManager } from './WorkerManager'
import { IModeMap } from '../featureservice/IModeMap';
export class CameraWorker {
  private static TAG = '[CameraWorker]:'
  private appEventBus: EventBus = EventBusManager.getWorkerInstance().getEventBus()
  private workerManager: WorkerManager

  constructor(modeMap: IModeMap) {
    this.workerManager = new WorkerManager()
    // 接收UI线程的消息，并继续发送
    this.appEventBus.on('MAIN_TO_WORKER', (msg) => {
      console.info(`[CameraWorker]:  action from main thread: ${JSON.stringify(msg)}`)
      this.workerManager.onMessage(msg)
    })
  }

  public static getInstance(modeMap: IModeMap): CameraWorker {
    if (!AppStorage.Has(Constants.APP_KEY_CAMERA_WORKER)) {
      AppStorage.SetOrCreate(Constants.APP_KEY_CAMERA_WORKER, new CameraWorker(modeMap))
      Log.info(`${this.TAG} build new CameraWorker.`)
    }
    return AppStorage.Get(Constants.APP_KEY_CAMERA_WORKER);
  }
}