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
import wearService from '@hms.health.wearService';
import lazy { common } from '@kit.AbilityKit';

/* instrument ignore file */
const TAG = 'RemoteCaptureExtSvs';

export class RemoteCaptureExtensionService {
  private static instance: RemoteCaptureExtensionService;
  private deviceMgr: wearService.DeviceManager;
  private cameraManager: wearService.cameraService.CameraManager;
  private deviceFound: wearService.Device;
  public static getInstance(): RemoteCaptureExtensionService {
    if (!RemoteCaptureExtensionService.instance) {
      RemoteCaptureExtensionService.instance = new RemoteCaptureExtensionService();
      HiLog.i(TAG, 'get instance');
    }
    return RemoteCaptureExtensionService.instance;
  }

  public async init(conText: common.UIAbilityContext): Promise<void> {
    try {
      this.deviceMgr = wearService.getDeviceManager(conText);
      let filter: wearService.DeviceFilter = {
        deviceCategory: [1]
        // 过滤掉非watch设备
      };
      let devices = await this.deviceMgr.getBoundDevices(filter);
      HiLog.i(TAG, `devices length : ${devices?.length}`);
      for (let device of devices) {
        if (device?.category === wearService.DeviceCategory.WATCH) {
          this.deviceFound = device;
          this.cameraManager = this.deviceFound.getService<wearService.cameraService.CameraManager>(wearService.DeviceServiceType.CAMERA);
          HiLog.i(TAG, 'get cameraManager success');
          break;
        }
      }
    } catch (err) {
      HiLog.e(TAG, `Init remoteCapture catch err code: ${err?.code}`);
    }
  }

  public async verifyPermission(uuid: string): Promise<boolean> {
    try {
      if (uuid !== undefined) {
        let isGranted: boolean = await this.cameraManager.verifyPermission(uuid);
        HiLog.i(TAG, `uuid is granted or not: ${isGranted}`);
        return isGranted;
      } else {
        return false;
      }
    } catch (e) {
      HiLog.i(TAG, `VerifyPermission error : ${e.code} message :  ${e.message}`);
      return false;
    }
  }

  public async forbiddenCamera(): Promise<void> {
    try {
      await this.cameraManager.syncState(wearService.cameraService.CameraState.FORBIDDEN);
    } catch (err) {
      HiLog.e(TAG, `err code: ${err?.code}`);
      return;
    }
    HiLog.i(TAG, 'forbidden Camera done');
  }

}

