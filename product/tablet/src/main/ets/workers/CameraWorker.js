import worker from '@ohos.worker';
import {WorkerManager} from '../../../../../../common/src/main/ets/default/Utils/WorkerManager'
import {FeatureManager} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/featureservice/FeatureManager'

//var worker = requireNapi('worker')
const parentPort = worker.parentPort
var workerManager =new WorkerManager()
var featureManager = new FeatureManager('PHOTO')

parentPort.onerror = function (data) {
    console.info(`worker:: worker.js onerror ${data.lineno}, msg = ${data.message}, filename${data.filename}, colno = ${data.colno}`);
}

// 接收UI线程的消息，并继续发送
parentPort.onmessage = (msg) => {
    let action = msg.data
    console.info(`[CameraWorker]:  action from main thread: ${JSON.stringify(action)}`)
    workerManager.onMessage(action)
}