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

import lazy { HiLog } from '../../utils/HiLog';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { ContextManager } from '../context/ContextManager';
// import wearService from '@hms.health.wearService';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { CaptureAction } from '../../function/capture/CaptureAction';
import lazy { getStates, OhCombinedState } from '../../redux';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { window } from '@kit.ArkUI';
import lazy { PersistType, PreferencesService } from '../preferences/PreferencesService';
import lazy { PublicTag } from '../preferences/PropTag';
/* instrument ignore file */
const TAG = 'RemoteCaptureService';

export enum RemoteAuthorizeState {
  ONCE,
  ALWAYS,
  REJECT,
  TIMEOUT
}

export class RemoteCaptureService {
  private mBase: BaseComponent = new BaseComponent();
  private static instance: RemoteCaptureService;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private context;
  // private deviceMgr: wearService.DeviceManager;
  // private cameraManager: wearService.cameraService.CameraManager;
  // private deviceFound: wearService.Device;
  private uuid = '';
  private udid: string = '';
  private deviceName = '';
  private isShowPermission: boolean = false;
  private preferencesService: PreferencesService = PreferencesService.getInstance();

  public static getInstance(): RemoteCaptureService {
    if (!RemoteCaptureService.instance) {
      RemoteCaptureService.instance = new RemoteCaptureService();
      HiLog.i(TAG, 'get instance');
    }
    return RemoteCaptureService.instance;
  }

  private constructor() {

  }

  public async init(isMainAbility: boolean): Promise<void> {
    if (isMainAbility) {
      this.context = ContextManager.getInstance().getAbilityContext();
    } else {
      this.context = ContextManager.getInstance().getServiceExtensionContext();
    }
    // try {
    //   this.deviceMgr = wearService.getDeviceManager(this.context);
    //   let filter: wearService.DeviceFilter = {
    //     deviceCategory: [1, 2]
    //     // 只需要 watch 或者 band 设备
    //   };
    //   let devices = await this.deviceMgr.getBoundDevices(filter);
    //   HiLog.i(TAG, `devices length : ${devices?.length}`);
    //   for (let device of devices) {
    //     HiLog.i(TAG, `device category : ${device.category} , device name : ${device.name},device connectionState : ${device?.connectionState}`);
    //     // if (device?.connectionState === wearService.ConnectionState.CONNECTED) {
    //     //   this.deviceFound = device;
    //     //   this.cameraManager = this.deviceFound.getService<wearService.cameraService.CameraManager>(wearService.DeviceServiceType.CAMERA);
    //     //   HiLog.i(TAG, `get deviceManager success, device name : ${device.name}.`);
    //     //   break;
    //     // }
    //   }
    // } catch (err) {
    //   HiLog.e(TAG, `Init remoteCapture catch err code: ${err?.code}`);
    // }
  }


  public async RemoteCaptureSubscribe(): Promise<void> {
    // try {
    //   HiLog.i(TAG, 'Remote capture subscribe begin');
    //   await this.cameraManager.subscribeCameraOperation((operationType: wearService.cameraService.OperationType) => {
    //     HiLog.i(TAG, `Remote Capture callback enter ${operationType}   --- ${this.isInterceptRemoteCapture()} `);
    //     if (operationType === wearService.cameraService.OperationType.TAKE_PHOTO && !this.isInterceptRemoteCapture()) {
    //       HiLog.i(TAG, 'Remote capture begin. ' + getStates().get<boolean>('contextReducer', 'isDuringSavePowerMode'));
    //       if (getStates().get<boolean>('contextReducer', 'isDuringSavePowerMode')) {
    //         StoreManager.getInstance().postMessage(CaptureAction.exitSavePowerModeEvent());
    //       }
    //       StoreManager.getInstance().postMessage(CaptureAction.isRemoteCaptureEvent());
    //       HiLog.i(TAG, 'Remote capture done');
    //     } else if (operationType === wearService.cameraService.OperationType.EXIT_CAMERA) {
    //       ContextManager.getInstance().getUiContext().terminateSelf().then(async () => {
    //         HiLog.i(TAG, 'terminateSelf success by Remote capture ');
    //       });
    //     }
    //   });
    //   HiLog.i(TAG, 'Subscribe success done');
    // } catch (err) {
    //   HiLog.e(TAG, `Subscribe catch err code: ${err?.code}`);
    // }
  }

  public async RemoteCaptureUnSubsrcibe(): Promise<void> {
    // await this.cameraManager.unsubscribeCameraOperation(() => {
    //   HiLog.i(TAG, 'unsubscribeRemoteCapture done');
    // });
  }

  public async startCamera(): Promise<void> {
    try {
      if (this.verifyPermission(this.uuid)) {
        // await this.cameraManager.syncState(wearService.cameraService.CameraState.STARTED);
      }
    } catch (err) {
      HiLog.e(TAG, `err code: ${err?.code}`);
      return;
    }
    HiLog.i(TAG, 'startCamera done');
  }

  public async quitCamera(): Promise<void> {
    try {
    // await this.cameraManager.syncState(wearService.cameraService.CameraState.STOPPED);
    } catch (err) {
      HiLog.e(TAG, `err code: ${err?.code}`);
      return;
    }
    HiLog.i(TAG, 'quitCamera done');
  }

  public async forbiddenCamera(): Promise<void> {
    try {
      // await this.cameraManager.syncState(wearService.cameraService.CameraState.FORBIDDEN);
    } catch (err) {
      HiLog.e(TAG, `err code: ${err?.code}`);
      return;
    }
    HiLog.i(TAG, 'forbidden Camera done');
  }

  public async setPermission(): Promise<void> {
    try {
      // await this.cameraManager.setPermission(this.uuid, true);
      AppStorage.setOrCreate('showRemoCapturePermission', true);
    } catch (err) {
      HiLog.e(TAG, `setPermission error : ${err?.code}`);
    }
    HiLog.i(TAG, 'setPermission done');
  }

  public async setPermissionUuid(uuid: string, bool: boolean): Promise<void> {
    try {
      // await this.cameraManager.setPermission(uuid, bool);
    } catch (err) {
      HiLog.e(TAG, `setPermission error : ${err?.code}`);
    }
    HiLog.i(TAG, 'setPermission done');
  }

  public async setPermissionUdid(): Promise<void> {
    try {
      // await this.cameraManager.setPermission(this.udid, true);
    } catch (err) {
      HiLog.e(TAG, `setPermissionUdid error : ${err?.code}`);
    }
    HiLog.i(TAG, 'setPermissionUdid done');
  }

  public async verifyPermission(uuid: string): Promise<boolean> {
    try {
      if (uuid) {
        // let isGranted: boolean = await this.cameraManager.verifyPermission(uuid);
        // HiLog.i(TAG, `uuid is granted or not: ${isGranted}`);
        return false//isGranted;
      } else {
        return false;
      }
    } catch (e) {
      HiLog.i(TAG, `VerifyPermission error : ${e.code} message :  ${e.message}`);
      return false;
    }
  }

  public setUuid(uuid: string): void {
    this.uuid = uuid;
  }

  public setUdid(udid: string): void {
    this.udid = udid;
  }

  public getUuid(): string {
    return this.uuid;
  }

  public setDeviceName(deviceName: string): void {
    this.deviceName = deviceName;
  }

  public getDeviceName(): string {
    return this.deviceName;
  }

  private isInterceptRemoteCapture(): boolean {
    let state: OhCombinedState = getStates();
    let isShowMorePage: boolean = state.get<boolean>('modeReducer', 'isShowMorePage');
    let isEditMorePage: boolean = state.get<boolean>('modeReducer', 'isEditMorePage');
    let isModeIntroDialogOpen: boolean = AppStorage.get('isModeIntroDialogOpen');
    let windowStageEventType = AppStorage.get('windowStageEventType');
    let isAnyDialogOpening: boolean = AppStorage.get('isAnyDialogOpening');
    let isIntroLoad: boolean =
      <boolean> this.preferencesService.getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false);
    let isGuideLoaded: boolean =
      <boolean> this.preferencesService.getPublicValue(PersistType.FOREVER, PublicTag.IS_GUIDANCE_LOADED, false);
    return state.get<ModeType>('modeReducer', 'mode') === ModeType.NONE ||
      isShowMorePage || isEditMorePage || isModeIntroDialogOpen || !isGuideLoaded ||
    state.get<boolean>('uiReducer', 'showPicker') || !isIntroLoad || isAnyDialogOpening ||
    state.get<boolean>('thumbnailReducer', 'photoBrowserStatus') ||
    state.get<boolean>('settingViewReducer', 'isShowSettingView') ||
    state.get<boolean>('settingReducer', 'isShowtimeLapse') ||
    state.get<boolean>('securityCameraReducer', 'thumbnailReminderShow') ||
    state.get<boolean>('securityCameraReducer', 'appLockReminderShow') ||
    state.get<boolean>('customFilterStyleReducer', 'isOpenPhotoPicker') ||
      windowStageEventType === window.WindowStageEventType.INACTIVE;
  }

}

