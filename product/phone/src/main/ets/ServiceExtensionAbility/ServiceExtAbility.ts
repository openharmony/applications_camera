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
/* instrument ignore file */
import ServiceExtensionAbility from '@ohos.app.ability.ServiceExtensionAbility';
import Want from '@ohos.app.ability.Want';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { common } from '@kit.AbilityKit';
import lazy { rpc } from '@kit.IPCKit';
import lazy { BusinessError, power, screenLock } from '@kit.BasicServicesKit';
import lazy { RemoteCaptureService } from '@ohos/common/src/main/ets/service/RemoteCapture/RemoteCaptureService';
import lazy {
  CollaborateControlService,
  CONNECT_TYPE
} from '@ohos/common/src/main/ets/service/collaborateControl/CollaborateControlService'

const TAG = 'ServiceExtAbility';
const CAMERA_BUNDLE_NAME: string = 'com.ohos.camera';
const CAMERA_ABILITY_NAME: string = 'com.ohos.camera.MainAbility';

export default class ServiceExtAbility extends ServiceExtensionAbility {
  private remoteCaptureSvs: RemoteCaptureService = undefined;

  onCreate(): void {
    HiLog.begin(TAG, 'onCreate');
    ContextManager.getInstance().setServiceExtensionContext(this.context);
    HiLog.end(TAG, 'onCreate');
  }

  async onRequest(want: Want): Promise<void> {
    HiLog.begin(TAG, 'onRequest');
    if (want.action === 'com.ohos.camera.intent.RemoteCall') {
      // 运动健康拉起相机入口
      let uuid: string = want.parameters?.uuid.toString();
      let deviceName: string = want.parameters?.deviceName.toString();
      HiLog.i(TAG, `Enter RemoteCapture`);
      CollaborateControlService.getInstance().setRemoteConnectType(CONNECT_TYPE.SPORT_REMOTE);
      await this.initRemoteCapture(uuid, deviceName);
    }
    HiLog.end(TAG, 'onRequest');
  }

  private async initRemoteCapture(uuid: string, deviceName: string): Promise<void> {
    if (screenLock.isLocked()) {
      power.wakeup('');
    }
    HiLog.begin(TAG, 'remoteCapture in SvsExtAbility');
    this.remoteCaptureSvs = RemoteCaptureService.getInstance();
    await this.remoteCaptureSvs.init(false);
    let isGranted: boolean = await this.remoteCaptureSvs.verifyPermission(uuid);
    HiLog.i(TAG, `remoteCapture isGranted: ${isGranted}`);
    if (!isGranted) {
      await this.openDialog(deviceName, uuid);
      return;
    }
    await this.startMainAbility(uuid);
    HiLog.end(TAG, 'remoteCapture in SvsExtAbility');
  }

  /**
   * 打开跨设备访问权限弹窗
   *
   * @returns
   */
  async openDialog(deviceName: string, uuid: string): Promise<void> {
    HiLog.i(TAG, 'openDialog of RemoteCapture');
    const newWant: Want = {
      bundleName: 'com.ohos.sceneboard',
      abilityName: 'com.ohos.sceneboard.systemdialog',
    };
    let dataSequence: rpc.MessageSequence = rpc.MessageSequence.create();
    let replySequence: rpc.MessageSequence = rpc.MessageSequence.create();
    const connectOption: common.ConnectOptions = {
      onConnect(elementName, remote) {
        HiLog.i(TAG, 'openDialog onConnect');
        let option = new rpc.MessageOption();
        dataSequence.writeInt(3);
        dataSequence.writeString('bundleName');
        dataSequence.writeString('com.ohos.camera');
        dataSequence.writeString('abilityName');
        dataSequence.writeString('RemoteCaptureDialogAbility');
        dataSequence.writeString('parameters');
        // sysDialogZOrder 1 锁屏下 2 锁屏上
        const parameter: Record<string, Object> = {
          'ability.want.params.uiExtensionType': 'sysDialog/common',
          'sysDialogZOrder': screenLock.isLocked() ? 2 : 1,
          'watchDeviceName': deviceName,
          'watchUuid': uuid,
          'isSmartWatch': false
        };
        dataSequence.writeString(JSON.stringify(parameter));

        remote.sendMessageRequest(1, dataSequence, replySequence, option).then((ret) => {
          let msg = replySequence.readInt();
          HiLog.i(TAG, `openDialog sendMessageRequest ret:${ret}, msg:${msg}`);
        }).catch((error: BusinessError) => {
          HiLog.e(TAG, `openDialog sendMessageRequest failed, err = ${error?.code}`);
        });
      },
      onDisconnect(elementName) {
        HiLog.i(TAG, `openDialog onDisconnect, elementName: ${elementName.bundleName}`);
        dataSequence.reclaim();
        replySequence.reclaim();
      },
      onFailed(code) {
        HiLog.i(TAG, `openDialog onFailed,code: ${code}`);
        dataSequence.reclaim();
        replySequence.reclaim();
      }
    };
    try {
      const connectionId = this.context?.connectServiceExtensionAbility(newWant, connectOption);
      HiLog.i(TAG, `openDialog connectServiceExtensionAbility connectionId = ${connectionId}`);
    } catch (e) {
      let err: BusinessError = e as BusinessError;
      HiLog.e(TAG, `openDialog connectServiceExtensionAbility Failed,code: ${err?.code}`);
      dataSequence.reclaim();
      replySequence.reclaim();
    }
  }

  private async startMainAbility(uuid: string): Promise<void> {
    HiLog.begin(TAG, 'startMainAbility by RemoteCapture');
    const want: Want = {
      bundleName: CAMERA_BUNDLE_NAME,
      abilityName: CAMERA_ABILITY_NAME,
      parameters: {
        'isNeedSetPermission': false,
        'uuid': uuid,
      },
      action: 'RemoteCall'
    };
    try {
      await this.context?.startAbility(want);
    } catch (e) {
      HiLog.e(TAG, ` RemoteCapture StartMainAbility error: ${e.code} message :  ${e.message}.`);
    }
    HiLog.end(TAG, 'startMainAbility by RemoteCapture');
  }

  onDestroy(): void {
    HiLog.i(TAG, 'ServiceExtAbility onDestroy.');
  }
}
