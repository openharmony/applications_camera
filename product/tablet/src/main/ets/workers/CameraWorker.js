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

import { CLog } from '../../../../../../common/src/main/ets/default/Utils/CLog'
import { WorkerManager } from '../../../../../../common/src/main/ets/default/Utils/WorkerManager'
import { FeatureManager
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/featureservice/FeatureManager'

const TAG = '[CameraWorker]:'
const parentPort = worker.parentPort
var workerManager = new WorkerManager()
var featureManager = new FeatureManager('PHOTO')


parentPort.onerror = function (data) {
    CLog.info(`${TAG} onerror ${data.lineno}, msg = ${data.message}, filename${data.filename}, colno = ${data.colno}`);
}

// 接收UI线程的消息，并继续发送
parentPort.onmessage = (msg) => {
    let action = msg.data
    CLog.info(`${TAG} action from main thread: ${JSON.stringify(action)}`)
    workerManager.onMessage(action)
}