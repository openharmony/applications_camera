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

import lazy { HiLog } from '../../../utils/HiLog';
import camera from '@ohos.multimedia.camera';
import type { CameraInputMessage } from '../../DataType';
import lazy { ModeType } from '../../../mode/ModeType';
import lazy { getStates } from '../../../redux';
import lazy { DeviceInfo } from '../../../component/deviceinfo/DeviceInfo';

/* instrument ignore file */
const TAG: string = 'CameraDeviceManager';
const physicalDeviceList: camera.CameraType[] = [camera.CameraType.CAMERA_TYPE_ULTRA_WIDE,
  camera.CameraType.CAMERA_TYPE_WIDE_ANGLE, camera.CameraType.CAMERA_TYPE_TELEPHOTO];
const EPSILON = 0.5;

// 负责相机设备以及静态能力管理
export default class CameraDeviceManager {
  private static sInstance: CameraDeviceManager;
  private mCameras: camera.CameraDevice[];
  private mPhysicalCameras: camera.CameraDevice[];
  private mainLensEquivalentFocalLength: number;

  private constructor() {
    HiLog.i(TAG, 'constructor.');
  }

  public static getInstance(): CameraDeviceManager {
    if (!CameraDeviceManager.sInstance) {
      CameraDeviceManager.sInstance = new CameraDeviceManager();
    }
    return CameraDeviceManager.sInstance;
  }

  public initCameraList(cameraManager: camera.CameraManager): void {
    if (!cameraManager) {
      HiLog.e(TAG, 'no cameraManager when init cameras');
      return;
    }
    HiLog.begin(TAG, 'getSupportedCameras');
    this.mCameras = cameraManager.getSupportedCameras();
    if (!this.mCameras) {
      HiLog.e(TAG, 'getSupportedCameras error, cameras is null.');
    } else {
      this.mCameras.forEach((device, index) => {
        HiLog.i(TAG, `forEach ${index}, id: ${device.cameraId}, cameraPosition: ${device.cameraPosition
          }, cameraType: ${device.cameraType}`);
        // @ts-ignore
        HiLog.i(TAG, `forEach lensEquivalentFocalLength: ${device?.lensEquivalentFocalLength}.`);
      });
      this.mCameras.forEach(item => {
        if (item.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK &&
          item.cameraType === camera.CameraType.CAMERA_TYPE_WIDE_ANGLE) {
          // @ts-ignore
          this.mainLensEquivalentFocalLength = item?.lensEquivalentFocalLength[0];
        }
      })
      this.mPhysicalCameras =
        this.mCameras.filter(item => item.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK &&
          // @ts-ignore
        physicalDeviceList.includes(item.cameraType) && item?.lensEquivalentFocalLength !== undefined &&
          // @ts-ignore
          item?.lensEquivalentFocalLength?.length > 0)
        // @ts-ignore
          .sort((a, b) => a?.lensEquivalentFocalLength[0] - b?.lensEquivalentFocalLength[0]);
      if (!this.mPhysicalCameras || this.mPhysicalCameras.length < 1) {
        this.mPhysicalCameras =
          this.mCameras.filter(item => item.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK &&
            item.cameraType !== camera.CameraType.CAMERA_TYPE_DEFAULT)
            .sort((a, b) => physicalDeviceList.indexOf(a.cameraType) - physicalDeviceList.indexOf(b.cameraType));
      }
    }
    HiLog.end(TAG, 'getSupportedCameras');
  }

  public getCameraDevices(): camera.CameraDevice[] {
    return this.mCameras;
  }

  public getCameraWithPosition(cameraPosition: camera.CameraPosition): camera.CameraDevice | undefined {
    if (!this.mCameras || cameraPosition === undefined) {
      HiLog.e(TAG, 'cameras or cameraPosition is null.');
      return undefined;
    }
    HiLog.i(TAG, `getCameraWithPosition, position: ${cameraPosition}.`);
    // cameradevice 需要同时匹配position和connectionType  因为底层在组网成功后也会把远端的摄像头上报并且无序
    // rk3568 设备只有前置摄像头
    const cameraDevice: camera.CameraDevice | undefined = this.mCameras
      .find(item => item.cameraPosition ===
        (DeviceInfo.getChipType() === 'rk3568' ? camera.CameraPosition.CAMERA_POSITION_FRONT : cameraPosition) &&
        item.connectionType !== camera.ConnectionType.CAMERA_CONNECTION_REMOTE);
    if (cameraDevice === undefined) {
      HiLog.e(TAG, `getCameraWithPosition no such cameraPosition: ${cameraPosition}.`);
      return undefined;
    }
    this.checkCamera(cameraDevice);
    HiLog.i(TAG, `getCameraWithPosition, connectionType: ${cameraDevice.connectionType}.`);
    return cameraDevice;
  }

  public getCameraWithType(cameraType: camera.CameraType, zoomValue?: number): camera.CameraDevice | undefined {
    if (!this.mCameras || cameraType === undefined) {
      HiLog.e(TAG, 'cameras or cameraPosition is null.');
      return undefined;
    }
    let cameraPosition: number = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    HiLog.i(TAG,
      `getCameraWithType, cameraType: ${cameraType}. cameraPosition：${cameraPosition},zoomValue:${zoomValue}`);
    // cameradevice 需要同时匹配position和connectionType  因为底层在组网成功后也会把远端的摄像头上报并且无序
    let cameraDevice: camera.CameraDevice | undefined;
    if (this.mainLensEquivalentFocalLength !== undefined && zoomValue !== undefined) {
     cameraDevice = this.mPhysicalCameras.find(item =>
        item.cameraPosition === cameraPosition && cameraType === item.cameraType &&
          // @ts-ignore
          Math.abs(zoomValue - (item?.lensEquivalentFocalLength[0] / this.mainLensEquivalentFocalLength)) <= EPSILON
      )
    } else {
      cameraDevice = this.mPhysicalCameras.find(item =>
        item.cameraPosition === cameraPosition && cameraType === item.cameraType
      )
    }
    if (cameraDevice === undefined) {
      HiLog.e(TAG, `getCameraWithType no such cameraPosition: ${cameraType}.`);
      return null;
    }
    this.checkCamera(cameraDevice);
    HiLog.i(TAG, `getCameraWithType, id: ${cameraDevice.cameraId}.`);
    return cameraDevice;
  }

  public getCameraWithId(cameraId: string): camera.CameraDevice | undefined {
    if (!this.mCameras || cameraId === undefined) {
      HiLog.e(TAG, 'cameras or cameraId is null.');
      return null;
    }
    HiLog.i(TAG, `getCameraWithId, id: ${cameraId}.`);
    let camera: camera.CameraDevice | undefined = this.mCameras.find(item => item.cameraId === cameraId);
    if (camera === undefined) {
      HiLog.e(TAG, `getCameraWithId no such cameraId: ${cameraId}.`);
      return null;
    }
    this.checkCamera(camera);
    return camera;
  }

  public getCameraWithMessage(message: CameraInputMessage): camera.CameraDevice | undefined {
    if (!this.mCameras || message === undefined) {
      HiLog.e(TAG, 'cameras or message is null.');
      return undefined;
    }
    HiLog.i(TAG, `getCameraWithMessage: ${message.cameraPosition}, ${this.mCameras.length}.`);
    return this.getCameraWithPosition(message.cameraPosition);
  }

  public getSwitchCameraWithMessage(message: CameraInputMessage): camera.CameraDevice | undefined {
    if (message.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) {
      return this.getCameraWithPosition(camera.CameraPosition.CAMERA_POSITION_FRONT);
    }
    return this.getCameraWithPosition(camera.CameraPosition.CAMERA_POSITION_BACK);
  }

  private checkCamera(camera: camera.CameraDevice): void {
    if (camera) {
      HiLog.i(TAG, '--------------Camera Info-------------');
      HiLog.i(TAG, `camera_id: ${camera.cameraId}.`);
      HiLog.i(TAG, `cameraPosition: ${camera.cameraPosition}.`);
      HiLog.i(TAG, `cameraType: ${camera.cameraType}.`);
    } else {
      HiLog.e(TAG, 'getCamera failed, camera undefined.');
    }
  }

  private checkCameraList(cameraManager: camera.CameraManager): void {
    HiLog.i(TAG, `CameraDevices length: ${this.mCameras.length}`);
    this.mCameras.forEach((device: camera.CameraDevice) => {
      HiLog.i(TAG, '--------------Camera Info-------------');
      HiLog.i(TAG, `camera_id: ${device.cameraId}.`);
      HiLog.i(TAG, `cameraPosition: ${device.cameraPosition}.`);
    });
  }
}