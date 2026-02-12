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

import camera from '@ohos.multimedia.camera';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { BusinessError } from '@kit.BasicServicesKit';
import lazy { GlobalContext } from '../../../utils/GlobalContext';
import lazy { workerCallback } from '../WorkerCallback';
import lazy { simpleStringify } from '../../../utils/SimpleStringify';
import CameraContext from './CameraContext';
import privacyManager from '@ohos.privacyManager';
import lazy { PickerInfo } from '../../../utils/types';

/* instrument ignore file */
const TAG: string = 'CameraInputWrap';

export enum CameraErrorCode {
  INVALID_ARGUMENT = 7400101,
  OPERATION_NOT_ALLOWED = 7400102,
  SESSION_NOT_CONFIG = 7400103,
  SESSION_NOT_RUNNING = 7400104,
  SESSION_CONFIG_LOCKED = 7400105,
  DEVICE_SETTING_LOCKED = 7400106,
  CONFLICT_CAMERA = 7400107,
  DEVICE_DISABLED = 7400108,
  DEVICE_PREEMPTED = 7400109,
  UNRESOLVED_CONFLICTS_WITH_CURRENT_CONFIGURATIONS = 7400110,
  SERVICE_FATAL_ERROR = 7400201,
  PC_NOT_FIND_CAMERA = 7400999, // temporary error code
  DEVICE_FREQUENTLY_SWITCHED = 7400111, // 频繁开关镜头
  CAMERA_LENS_RETRACTED = 7400112, // 恒星镜头异常收回
}

// 恒星镜头枚举 后续SDK更新后从接口中取
enum AuxiliaryType {
  CONTRACTLENS = 0
};

enum AuxiliaryStatus {
  LOCKED = 0,
  ON,
  OFF
};


const DELAYED_CLOSE_TIME: number = 30; // 伸缩镜头延时关闭cameraInput的时间,单位秒

async function asyncMethodWithRetry(method: () => Promise<void>, methodName: string = '', retry: number = 1,
  maxRetries: number = 8,
  delayMs: number = 100): Promise<void> {
  try {
    HiLog.i(TAG, `${methodName} try times: ${retry}.`);
    await method();
    HiLog.i(TAG, `${methodName} executed successfully.`);
  } catch (error) {
    HiLog.i(TAG, 'Method failed to execute.');
    if (maxRetries >= retry) {
      await new Promise(resolve => setTimeout(resolve, delayMs));
      HiLog.i(TAG, `sleep time ${delayMs}ms.`);
      await asyncMethodWithRetry(method, methodName, retry + 1, maxRetries, delayMs);
    } else {
      throw error;
    }
  }
}

// CameraInput包装类
export default class CameraInputWrap {
  private cameraInput: camera.CameraInput;
  private isCameraLensDirty: boolean = false;
  private static isCameraOccluded: boolean = false; // 维护一个局部状态，减少子线程和主线程之间的通讯。
  private isDuringCloseDelay: boolean = false;
  private pickerInfo: PickerInfo | null = null;
  private static startUsingPermissionCount : number = 0; // 用于记录使用权限的次数，确保stop和start次数配对

  constructor() {
  }

  public async open(device: camera.CameraDevice, cameraManager: camera.CameraManager,
    pickerInfo: PickerInfo): Promise<void> {
    HiLog.begin(TAG, 'openCamera');
    HiLog.d(TAG, `openCamera ${pickerInfo?.isPicker}`);
    this.pickerInfo = pickerInfo;
    if (this.pickerInfo?.isPicker) {
      this.startUsingPermission();
    }
    this.cameraInput = null;
    this.isDuringCloseDelay = false;
    try {
      await asyncMethodWithRetry(async () => {
        this.cameraInput = cameraManager.createCameraInput(device);
      }, 'createCameraInput');
    } catch (error) {
      HiLog.e(TAG, `asyncMethodWithRetry error: ${simpleStringify(error)}.`);
      GlobalContext.get().setObject('cameraOpenSuccess', false);
      workerCallback.openCameraFailed('createCameraInput failed');
      this.stopUsingPermission();
      return;
    }
    try {
      await asyncMethodWithRetry(async () => {
        HiLog.begin(TAG, 'cameraInput::open');
        await this.cameraInput.open();
        HiLog.end(TAG, 'cameraInput::open');
      }, 'cameraInput open');
    } catch (error) {
      HiLog.e(TAG, `asyncMethodWithRetry error: ${simpleStringify(error)}.`);
      GlobalContext.get().setObject('cameraOpenSuccess', false);
      workerCallback.openCameraFailed('openCamera failed');
      return;
    }
    GlobalContext.get().setObject('cameraOpenSuccess', true);
    this.cameraInputInit(device);
    HiLog.end(TAG, 'openCamera');
  }

  private cameraInputInit(device: camera.CameraDevice): void {
    try {
      this.cameraInput.on('error', device, (error: BusinessError): void => {
        HiLog.i(TAG, `cameraInput error: ${simpleStringify(error)}.`);
        this.handleCameraInputError(error);
      });
    } catch (error) {
      HiLog.e(TAG, `cameraInput on error, error: ${simpleStringify(error)}.`);
    }
    try {
      HiLog.d(TAG, `cameraOcclusionDetect isCameraOccluded: ${CameraInputWrap.isCameraOccluded}`);
      if (CameraInputWrap.isCameraOccluded || device.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
        CameraInputWrap.isCameraOccluded = false;
        HiLog.d(TAG, `cameraOcclusionDetect state reset. ${device.cameraPosition}`);
        workerCallback.onLensBlocking(false);
      }
      this.isCameraLensDirty = false;
      // @ts-ignore
      this.cameraInput.on('cameraOcclusionDetect', (err: BusinessError, result: CameraOcclusionDetectResult) => {
        if (err) {
          HiLog.d(TAG, 'cameraOcclusionDetect err.');
        }
        if (!result) {
          HiLog.e(TAG, 'cameraOcclusionDetect: undefined');
          return;
        }
        if (CameraInputWrap.isCameraOccluded !== result.isCameraOccluded) {
          CameraInputWrap.isCameraOccluded = result.isCameraOccluded;
          HiLog.d(TAG, `cameraOcclusionDetect: ${result.isCameraOccluded}`);
          workerCallback.onLensBlocking(result.isCameraOccluded);
        }
        if (this.isCameraLensDirty !== result.isCameraLensDirty) {
          this.isCameraLensDirty = result.isCameraLensDirty;
          HiLog.d(TAG, `isCameraLensDirty: ${result.isCameraLensDirty}`);
          workerCallback.onLensDirty(result.isCameraLensDirty);
        }
      });
    } catch (error) {
      HiLog.e(TAG, `cameraInput on error: ${simpleStringify(error)}.`);
    }
  }

  private handleCameraInputError(error: BusinessError): void {
    if (error.code >= CameraErrorCode.INVALID_ARGUMENT && error.code <= CameraErrorCode.DEVICE_SETTING_LOCKED ||
      error.code === CameraErrorCode.UNRESOLVED_CONFLICTS_WITH_CURRENT_CONFIGURATIONS ||
      error.code === CameraErrorCode.CONFLICT_CAMERA || error.code === CameraErrorCode.DEVICE_DISABLED) {
      HiLog.i(TAG, `Ignore errorCode: ${error.code}`);
    } else if (error.code === CameraErrorCode.SERVICE_FATAL_ERROR) {
      // to restart app
      workerCallback.recoveryRestartApp();
      this.close(CameraContext.getInstance().getCamera(), true);
    } else {
      // specialized processing of DEVICE_PREEMPTED
      if (error.code === CameraErrorCode.DEVICE_PREEMPTED) {
        workerCallback.preemptWithError();
      }
      // pass exception messages
      workerCallback.onCameraError(error.code as CameraErrorCode, error.message);
    }
  }

  public async close(device: camera.CameraDevice, isOnError: boolean = false, isNeedDelayClose?: boolean): Promise<void> {
    HiLog.d(TAG, `cameraInput closed  ${this.pickerInfo?.isPicker}`);
    if (!this.cameraInput) {
      return;
    }
    try {
      if (!isOnError) { // 如果是onError回调里触发, 不能再调用off-error, 会导致相机框架死锁
        this.cameraInput.off('error', device);
      }
    } catch (error) {
      HiLog.e(TAG, `cameraInput off error, error: ${simpleStringify(error)}.`);
    }
    try {
      // @ts-ignore
      this.cameraInput.off('cameraOcclusionDetect');
    } catch (error) {
      HiLog.e(TAG, `cameraInput off cameraOcclusionDetect, error: ${simpleStringify(error)}.`);
    }
    try {
      HiLog.d(TAG, `isNeedDelayClose ${isNeedDelayClose}  isRetractable:${device?.isRetractable}`);
      if (isNeedDelayClose && device?.isRetractable) {
        HiLog.i(TAG, 'mCameraInput is delayed close');
        await this.cameraInput?.closeDelayed(DELAYED_CLOSE_TIME);
        this.isDuringCloseDelay = true;
      } else {
        HiLog.i(TAG, 'mCameraInput is closed');
        await this.cameraInput?.close();
        this.stopUsingPermission();
        this.isDuringCloseDelay = false;
        this.cameraInput = null;
      }
    } catch (error) {
      HiLog.e(TAG, `releaseCameraInput error: ${simpleStringify(error)}.`);
    }
    if (CameraInputWrap.isCameraOccluded) {
      CameraInputWrap.isCameraOccluded = true;
      HiLog.d(TAG, 'cameraOcclusionDetect off.');
      workerCallback.onLensBlocking(false);
    }
    if (this.isCameraLensDirty) {
      this.isCameraLensDirty = false;
      HiLog.d(TAG, 'cameraOcclusionDetect isCameraLensDirty off.');
      workerCallback.onLensDirty(false);
    }
    HiLog.i(TAG, 'cameraInput closed.');
  }

  public getInput(): camera.CameraInput {
    return this.cameraInput;
  }

  public keepUsingStellarLenses(): void {
    HiLog.i(TAG, 'keepUsingStellarLenses');
    if (this.cameraInput) {
      try {
        HiLog.i(TAG, 'controlAuxiliary begin');
        // @ts-ignore
        this.cameraInput.controlAuxiliary(AuxiliaryType.CONTRACTLENS, AuxiliaryStatus.ON);
        HiLog.i(TAG, 'controlAuxiliary end');
      } catch (err) {
        HiLog.e(TAG, `controlAuxiliary err.${err}`);
      }
    }
  }

  public getIsDuringCloseDelay(): boolean {
    return this.isDuringCloseDelay;
  }


  /**
   * 开始使用相机权限时，传入调用者信息 PermissionUsedType
   * NORMAL_TYPE  0  表示通过弹窗授权或设置授权的方式来使用敏感权限。
   * PICKER_TYPE  1  表示通过某个PICKER服务来使用敏感权限，此方式未授予权限。
   * SECURITY_COMPONENT_TYPE  2  表示通过安全控件授权的方式来使用敏感权限。
   * 待SDK更新到18后换成对应枚举
   */
  public startUsingPermission(): void {
    try {
      const callingTokenID: number = this.pickerInfo?.callingTokenID; // callingTokenID as number;
      const callerPid: number = this.pickerInfo?.callerPid;
      HiLog.i(TAG, `startUsingPermission: ${CameraInputWrap.startUsingPermissionCount}`);
      if (!callingTokenID) {
        return;
      }
      if (CameraInputWrap.startUsingPermissionCount > 0) {
        this.stopUsingPermission();
      }
      privacyManager.startUsingPermission(
        callingTokenID, 'ohos.permission.CAMERA', callerPid, 1)
        .then(() => {
          HiLog.i(TAG, 'startUsingPermission CAMERA success');
        }).catch((err) => {
        HiLog.e(TAG, `startUsingPermission CAMERA fail er1r: ${err?.code}`);
      });
      CameraInputWrap.startUsingPermissionCount += 1;
      HiLog.i(TAG, `startUsingPermissionCount add ${CameraInputWrap.startUsingPermissionCount}`);
    } catch (err) {
      HiLog.e(TAG, `startUsingPermission  CAMERA fail err: ${err?.code}`);
    }
  }

  /**
   * 结束使用相机权限时，传入调用者信息
   */
  public stopUsingPermission(): void {
    if (!this.pickerInfo?.isPicker) {
      return;
    }
    try {
      const callingTokenID: number = this.pickerInfo.callingTokenID; // callingTokenID as number;
      const callerPid: number = this.pickerInfo?.callerPid;
      if (!callingTokenID) {
        return;
      }
      privacyManager.stopUsingPermission(callingTokenID, 'ohos.permission.CAMERA', callerPid)
        .then(() => {
          HiLog.i(TAG, 'stopUsingPermission CAMERA success');
        });
      if (CameraInputWrap.startUsingPermissionCount > 0) {
        CameraInputWrap.startUsingPermissionCount -= 1;
        HiLog.i(TAG, `startUsingPermissionCount minus ${CameraInputWrap.startUsingPermissionCount}`);
      }
    } catch (err) {
      HiLog.e(TAG, `stopUsingPermission CAMERA fail err: ${err?.code}`);
    }
  }
}