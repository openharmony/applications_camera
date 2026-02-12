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
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { common } from '@kit.AbilityKit';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy {
  RemoteCaptureExtensionService
} from '@ohos/common/src/main/ets/service/RemoteCapture/RemoteCaptureExtensionService';
import lazy {
  RemoteCaptureDialog
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/RemoteCaptureDialog';
import lazy { RemoteAuthorizeState } from '@ohos/common/src/main/ets/service/RemoteCapture/RemoteCaptureService';
import lazy { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
import lazy { simpleStringify } from '@ohos/common/src/main/ets/utils/SimpleStringify';

/* instrument ignore file */
const storage = LocalStorage.getShared();
const TAG: string = 'RemoteCaptureDialogPage';
const CAMERA_BUNDLE_NAME: string = 'com.ohos.camera';
const CAMERA_ABILITY_NAME: string = 'com.ohos.camera.MainAbility';
const CAMERA_EXT_ABILITY_NAME: string = 'com.ohos.camera.SysDialogCallServiceExtAbility';
const CLOSE_DIALOG_TIME: number = 30 * 1000; // 8秒后自动关闭弹窗

@Entry(storage)
@Component
struct RemoteCaptureDialogIndex {
  context?: common.UIAbilityContext;
  timerId?: number;
  controller?: CustomDialogController;
  private isSmartWatch: boolean = storage.get<boolean>('isSmartWatch') ?? false;
  private uuid: string = storage.get<string>('watchUuid') ?? '';
  private isForeverGrant: boolean = false;
  private remoteCaptureExtSvs: RemoteCaptureExtensionService = RemoteCaptureExtensionService.getInstance();
  private started: boolean = false;
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;
  private isDialogShow: boolean = false;
  cancel: () => void = () => {
  };
  confirm: (isOnce: boolean) => void = () => {
  };
  normalConfirm = async (isOnce: boolean) => {
    HiLog.i(TAG, `CustomDialogController confirm isOnce = ${isOnce}`);
    if (!isOnce) {
      if (this.uuid !== undefined) {
        this.isForeverGrant = true;
      } else {
        HiLog.e(TAG, 'uuid is undefined');
      }
    }
    clearTimeout(this.timerId);
    await this.startMainAbility();
    this.context?.terminateSelf();
  }
  normalCancel = async () => {
    HiLog.i(TAG, 'CustomDialogController cancel');
    clearTimeout(this.timerId);
    await this.remoteCaptureExtSvs.init(this.context);
    await this.remoteCaptureExtSvs.forbiddenCamera();
    this.context?.terminateSelf();
    ContextManager.getInstance().getApplicationContext().killAllProcesses();
  }
  smartConfirm = async (isOnce: boolean) => {
    HiLog.i(TAG, `CustomDialogController confirm isOnce = ${isOnce}`);
    clearTimeout(this.timerId);
    this.startMainAbility(isOnce ? RemoteAuthorizeState.ONCE : RemoteAuthorizeState.ALWAYS);
    this.context?.terminateSelf();
  }
  smartCancel = () => {
    HiLog.i(TAG, 'CustomDialogController cancel');
    clearTimeout(this.timerId);
    this.startMainAbility(RemoteAuthorizeState.REJECT);
    this.context?.terminateSelf();
  }
  accessDialogController: CustomDialogController = new CustomDialogController({
    builder: RemoteCaptureDialog({
      confirm: this.isSmartWatch ? this.smartConfirm : this.normalConfirm,
      cancel: this.isSmartWatch ? this.smartCancel : this.normalCancel,
      deviceName: storage.get<string>('watchDeviceName'),
      isSmartWatch: this.isSmartWatch
    }),
    autoCancel: false,
    customStyle: false,
    maskColor: $r('sys.color.mask_fourth'),
    alignment: DialogAlignment.Center,
  });

  aboutToAppear(): void {
    this.isDialogShow = true;
    this.context = getContext() as common.UIAbilityContext;
    this.accessDialogController.open();
    this.subscribeCloseEvent();
  }

  onPageShow(): void {
    HiLog.d(TAG, 'onPageShow');
    this.timerId = setTimeout(async () => {
      HiLog.i(TAG, 'onPageShow auto close');
      this.handleTimeout();
      this.context?.terminateSelf();
    }, CLOSE_DIALOG_TIME);
  }

  aboutToDisappear(): void {
    HiLog.d(TAG, 'aboutToDisappear');
    this.isDialogShow = false;
    if (!this.started) {
      this.handleTimeout();
    }
    this.unsubscribeCloseEvent();
  }

  private handleTimeout(): void {
    clearTimeout(this.timerId);
    if (this.isSmartWatch) {
      this.startMainAbility(RemoteAuthorizeState.TIMEOUT);
    } else {
      this.remoteCaptureExtSvs.init(this.context);
      this.remoteCaptureExtSvs.forbiddenCamera();
    }
  }

  private getWant(remoteAuthorizeState?: RemoteAuthorizeState): Want {
    const want: Want = {
      bundleName: CAMERA_BUNDLE_NAME,
      abilityName: this.isSmartWatch ? CAMERA_EXT_ABILITY_NAME : CAMERA_ABILITY_NAME,
      parameters: this.isSmartWatch ? {
        'remoteAuthorizeState': remoteAuthorizeState ?? 0
      } : {
        'isNeedSetPermission': this.isForeverGrant,
        'uuid': this.uuid
      },
      action: this.isSmartWatch ? '' : 'RemoteCall'
    };
    return want;
  }

  private async startMainAbility(remoteAuthorizeState?: RemoteAuthorizeState): Promise<void> {
    HiLog.begin(TAG, 'startMainAbility by RemoteCapture');
    this.started = true;
    const want: Want = this.getWant(remoteAuthorizeState);
    try {
      await this.context?.startAbility(want);
    } catch (error) {
      HiLog.e(TAG, ` startMainAbility error: ${error?.code}.`);
    }
    HiLog.end(TAG, 'startMainAbility by RemoteCapture');
  }

  build() {
  }

  private async subscribeCloseEvent(): Promise<void> {
    try {
      this.subscriber = await commonEventManager.createSubscriber({ events: ['close_dialog'] });
      if (this.subscriber === null || this.subscriber === undefined) {
        return;
      }
      commonEventManager.subscribe(this.subscriber, (err: BusinessError, data: commonEventManager.CommonEventData) => {
        if (err) {
          HiLog.e(TAG, `subscribe err ${err?.code}`);
          return;
        }
        if (!this.isDialogShow) {
          return;
        }
        if (this.isSmartWatch) {
          this.smartCancel();
        } else {
          this.normalCancel();
        }
      });
    } catch (err) {
      HiLog.e(TAG, `subscribeCloseEvent err: ${simpleStringify(err)}`);
    }
  }

  private async unsubscribeCloseEvent(): Promise<void> {
    if (this.subscriber === null || this.subscriber === undefined) {
      return;
    }
    try {
      commonEventManager.unsubscribe(this.subscriber);
    } catch (err) {
      HiLog.e(TAG, `unsubscribeCloseEvent err: ${simpleStringify(err)}`);
    }
  }
}
