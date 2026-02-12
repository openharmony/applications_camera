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
import lazy { screenLock } from '@kit.BasicServicesKit';
import lazy { RemoteAuthorizeState } from '@ohos/common/src/main/ets/service/RemoteCapture/RemoteCaptureService';
import lazy {
  CollaborateControlService,
  AUTH_STATE
} from '@ohos/common/src/main/ets/service/collaborateControl/CollaborateControlService'

const TAG = 'SysDialogCallServiceExtAbility';
const CAMERA_BUNDLE_NAME: string = 'com.ohos.camera';
const CAMERA_ABILITY_NAME: string = 'com.ohos.camera.MainAbility';

/**
 * 智能表遥控拍照用户授权弹窗用户同意后,拉起的相机ServiceExtensionAbility
 */
export default class SysDialogCallServiceExtAbility extends ServiceExtensionAbility {
  onCreate(): void {
    HiLog.begin(TAG, 'onCreate');
    ContextManager.getInstance().setServiceExtensionContext(this.context);
    HiLog.end(TAG, 'onCreate');
  }

  async onRequest(want: Want): Promise<void> {
    HiLog.begin(TAG, 'onRequest');
    const remoteAuthorizeState: RemoteAuthorizeState = want.parameters?.remoteAuthorizeState as RemoteAuthorizeState;
    switch (remoteAuthorizeState) {
      case RemoteAuthorizeState.ALWAYS:
      case RemoteAuthorizeState.ONCE:
        CollaborateControlService.getInstance().handleAuthState(AUTH_STATE.ACCEPT);
        this.startMainAbility(remoteAuthorizeState);
        break;
      case RemoteAuthorizeState.REJECT:
        CollaborateControlService.getInstance().handleAuthState(AUTH_STATE.REJECT);
        break;
      case RemoteAuthorizeState.TIMEOUT:
        CollaborateControlService.getInstance().handleAuthState(AUTH_STATE.TIMEOUT);
        break;
      default:
        HiLog.i(TAG, `onRequest remoteAuthorizeState = ${remoteAuthorizeState}.`);
        break;
    }
    HiLog.end(TAG, 'onRequest');
  }

  private async startMainAbility(remoteAuthorizeState: RemoteAuthorizeState) {
    HiLog.i(TAG, 'startMainAbility');
    const want: Want = {
      bundleName: CAMERA_BUNDLE_NAME,
      abilityName: CAMERA_ABILITY_NAME,
      parameters: {
        remoteAuthorizeState: remoteAuthorizeState,
        isDialogCallCamera: true,
        isSecureMode: await screenLock.isSecureMode(),
        isFromScreenLock: screenLock.isLocked()
      }
    };
    try {
      await this.context.startAbility(want);
      await this.context.terminateSelf();
      HiLog.i(TAG, 'startMainAbility terminateSelf success.');
    } catch (error) {
      HiLog.e(TAG, ` startMainAbility error: ${error?.code}.`);
    }
  }

  onDestroy(): void {
    HiLog.i(TAG, 'ServiceExtAbility onDestroy.');
  }
}