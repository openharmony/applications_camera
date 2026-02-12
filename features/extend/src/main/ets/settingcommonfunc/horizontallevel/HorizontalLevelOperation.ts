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
import lazy { DisplayCalculator } from '@ohos/common/src/main/ets/component/xcomponent/DisplayCalculator';
import lazy { GravityData, SensorCallback, SensorService } from '@ohos/common/src/main/ets/service/sensor/SensorService';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { getStates } from '@ohos/common/src/main/ets/redux';
import lazy { HorizontalLevelUtils } from './HorizontalLevelUtils';
import { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';

/* instrument ignore file */
const TAG = 'HorizontalLevelOperation';
const WINDOW_OF: number = 2;

enum SurfaceDimensions {
  SIZE_16 = 16,
  SIZE_9 = 9,
}

export interface SensorData {
  x: number,
  y: number,
  z: number
}

export enum AngleOrientation {
  RX,
  RY,
  RZ,
}

export class HorizontalLevelOperation {
  private static mHorizontalManagerInstance: HorizontalLevelOperation = null;
  private angleQueue: number[] = [];
  private gAngle: number = DeviceInfo.isUis7885() ? 90 : 0; //上一次水平线旋转的角度
  private static readonly ANGLE_0: number = 0;
  private static readonly ANGLE_90: number = 90;
  private static readonly ANGLE_180: number = 180;
  private static readonly ANGLE_270: number = 270;
  private static readonly ANGLE_360: number = 360;
  private static readonly HORIZONTAL_ANGLE_OFFSET_2: number = 2; //当前角度与水平角度差2时将当前角度置为水平角度
  private static readonly MAX_GRAVITY_OF_Z_AXIS: number = 4.9; //屏幕与水平面夹角大于60°时, 显示垂直水平仪(G * cos60°)
  private static readonly ACCELEROMETER_CYCLE: number = 200000000; //时间间隔单位ns
  private static readonly  RATE_OF_Z_AXIS: number = DeviceInfo.isUis7885() ? 100000 : 1;
  private mBase: BaseComponent = new BaseComponent();
  private lastPrintLogTime: number = 0;

  private mCallback: SensorCallback = {
    onGravitySensor: (data: GravityData) => {
      this.onGSensor(data);
    }
  };

  constructor() {
    AppStorage.setOrCreate('sensorAngle', DeviceInfo.isUis7885() ? HorizontalLevelOperation.ANGLE_90 : HorizontalLevelOperation.ANGLE_0);
  }

  static getInstance(): HorizontalLevelOperation {
    if (HorizontalLevelOperation.mHorizontalManagerInstance) {
      return HorizontalLevelOperation.mHorizontalManagerInstance;
    }
    HorizontalLevelOperation.mHorizontalManagerInstance = new HorizontalLevelOperation();
    return HorizontalLevelOperation.mHorizontalManagerInstance;
  }

  //开启重力传感器
  enableGListener(): void {
    HiLog.i(TAG, 'Sensor GRAVITY on E.');
    try {
      SensorService.getInstance().registerGravityListener(this.mCallback, this.mBase.hashCode());
    } catch (err) {
      HiLog.e(TAG, `Sensor GRAVITY try catch err: ${err}.`);
    }
    HiLog.i(TAG, 'Sensor GRAVITY on X.');
  }

  disableGListener(): void {
    HiLog.i(TAG, 'off E.');
    try {
      SensorService.getInstance().unRegisterGravityListener(this.mBase.hashCode());
    } catch (err) {
      HiLog.e(TAG, `disable GRAVITY try catch err: ${err}.`);
    }
    HiLog.i(TAG, 'off X.');
  }

  onGSensor(sensorData: SensorData): void {
    AppStorage.setOrCreate('sensorData', sensorData);
    // 手机垂直于水平面时若绕y轴旋转30°就不显示水平仪
    if (Math.abs(sensorData.z * HorizontalLevelOperation.RATE_OF_Z_AXIS) > HorizontalLevelOperation.MAX_GRAVITY_OF_Z_AXIS) {
      AppStorage.setOrCreate('sensorAngle', this.gAngle); // 使用dispatch进行频繁消息下发会阻塞UI线程
      AppStorage.setOrCreate('showHorizontalLevelView', false);
      if (this.whetherPrintLog()) {
        HiLog.limitLog(TAG, `onGSensor rz: ${sensorData.z}, ${this.gAngle}`, 'UiGSensorRzLogKey', 3);
        this.lastPrintLogTime = Date.now();
      }
      return;
    }
    if (!AppStorage.get('showHorizontalLevelView')) {
      AppStorage.setOrCreate('showHorizontalLevelView', true);
    }
    let angleZ: number = HorizontalLevelUtils.vectorAngle(sensorData);
    if (this.whetherPrintLog()) {
      HiLog.i(TAG, `onGSensor vectorAngle angleZ: ${angleZ}`);
    }
    angleZ = HorizontalLevelUtils.addAngleToQueues(this.angleQueue, angleZ);
    if (this.whetherPrintLog()) {
      HiLog.i(TAG, `onGSensor addAngleToQueues angleZ: ${angleZ}`);
    }
    angleZ = this.nearHorizon(angleZ);
    if (this.whetherPrintLog()) {
      HiLog.limitLog(TAG, `onGSensor angleZ: ${angleZ}, gx: ${sensorData.x}, gy: ${sensorData.y}, gz: ${sensorData.z}`,
      'UiGSensorAngleZLogKey');
      this.lastPrintLogTime = Date.now();
    }
    if (this.gAngle === angleZ) {
      return;
    }
    this.gAngle = angleZ;
    AppStorage.setOrCreate('sensorAngle', angleZ); // 使用dispatch进行频繁消息下发会阻塞UI线程
    AppStorage.setOrCreate('showHorizontalLevelView', true);
  }

  // 水平仪接近水平时直接将角度置位最接近的水平角度
  // 实现水平吸附效果
  private nearHorizon(angle: number): number {
    let angleDivideNinety: number = Math.abs(angle % HorizontalLevelOperation.ANGLE_90);
    if (angleDivideNinety >=
      (HorizontalLevelOperation.ANGLE_90 - HorizontalLevelOperation.HORIZONTAL_ANGLE_OFFSET_2) ||
      angleDivideNinety <= HorizontalLevelOperation.HORIZONTAL_ANGLE_OFFSET_2) {
      // 手机逆时针旋转88°到92°之间时
      if ((angle >= (HorizontalLevelOperation.ANGLE_90 - HorizontalLevelOperation.HORIZONTAL_ANGLE_OFFSET_2) &&
        angle <= HorizontalLevelOperation.ANGLE_90) ||
        (angle >= -(HorizontalLevelOperation.ANGLE_270 + HorizontalLevelOperation.HORIZONTAL_ANGLE_OFFSET_2) &&
          angle <= -(HorizontalLevelOperation.ANGLE_270 - HorizontalLevelOperation.HORIZONTAL_ANGLE_OFFSET_2))) {
        return HorizontalLevelOperation.ANGLE_90;
      }
      // 手机逆时针旋转178°到182°之间时
      if ((angle >= -(HorizontalLevelOperation.ANGLE_180 + HorizontalLevelOperation.HORIZONTAL_ANGLE_OFFSET_2) &&
        angle <= -(HorizontalLevelOperation.ANGLE_180 - HorizontalLevelOperation.HORIZONTAL_ANGLE_OFFSET_2))) {
        return -HorizontalLevelOperation.ANGLE_180;
      }
      // 手机逆时针旋转268°到272°之间时
      if (angle >= -(HorizontalLevelOperation.ANGLE_90 + HorizontalLevelOperation.HORIZONTAL_ANGLE_OFFSET_2) &&
        angle <= -(HorizontalLevelOperation.ANGLE_90 - HorizontalLevelOperation.HORIZONTAL_ANGLE_OFFSET_2)) {
        return -HorizontalLevelOperation.ANGLE_90;
      }
      // 手机逆时针旋转358°到362°之间时
      if (angle >= -HorizontalLevelOperation.HORIZONTAL_ANGLE_OFFSET_2 &&
        angle <= HorizontalLevelOperation.HORIZONTAL_ANGLE_OFFSET_2) {
        return HorizontalLevelOperation.ANGLE_0;
      }
    }
    return angle;
  }

  public getViewWidth(): number {
    const state = getStates();
    const windowWidth = state.get<number>('windowReducer', 'windowWidth');
    const windowHeight = state.get<number>('windowReducer', 'windowHeight');
    const isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
    const viewSize = DisplayCalculator.calcSurfaceDisplaySize(SurfaceDimensions.SIZE_16 / SurfaceDimensions.SIZE_9,
      isShowSemiCollapsed ? windowWidth / WINDOW_OF : windowWidth, windowHeight);
    return Math.min(viewSize.width, viewSize.height);
  }

  private whetherPrintLog(): boolean {
    return Date.now() - this.lastPrintLogTime > 2 * 1000;
  }
}