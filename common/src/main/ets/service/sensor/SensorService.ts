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
import lazy { sensor } from '../../utils/LazyImportUtil';
// @ts-ignore
import motion from '@ohos.motion';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import { BusinessError } from '@kit.BasicServicesKit';
import { WindowDirection } from '../../utils/WindowDirection';
import { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';

/* instrument ignore file */
export class GravityData {
  public x: number = 0;
  public y: number = 0;
  public z: number = 0;
}

export class GyroscopeData {
  public x: number = 0;
  public y: number = 0;
  public z: number = 0;
  public timestamp: number = 0;
}

export interface SensorCallback {
  onGravitySensor(data: GravityData): void
}

export interface SensorGyroscopeCallback {
  onGyroscopeSensor(data: GyroscopeData): void
}

export interface MotionRotateCallback {
  onMotionRotate(data: number): void
}

export interface MotionRollCallback {
  onMotionRoll(data: number): void
}

export interface SensorMagneticCallback {
  onMagneticSensor(data: sensor.MagneticFieldResponse): void
}

const TAG: string = 'SensorService';

/*
 * 传感器监听通用Service;
 * 支持外部多模块同时虚拟注册后触发回调
 * 目前已实现加速度传感器、重力传感器、陀螺仪、motion模块旋转及翻转、磁场传感器; 后续可按需添加实现
 */
export class SensorService {
  private static sInstance: SensorService;
  private static readonly GRAVITY_CYCLE: number = 20000000; // 时间间隔20ms
  private static readonly GYROSCOPE_CYCLE: number = 10000000; // 时间间隔10ms
  private static readonly MAGNETIC_CYCLE: number = 1000000000; // 时间间隔1s
  private isGravityAlreadyRegistered: boolean = false; // 加速度传感器、重力传感器
  private gravityCallbackMap: Map<string, SensorCallback> = new Map();
  private isGyroscopeAlreadyRegistered: boolean = false; // 陀螺仪传感器
  private gyroscopeCallbackMap: Map<string, SensorGyroscopeCallback> = new Map();
  private isMotionRotateRegistered: boolean = false; // Motion模块旋转
  private motionRotateCallbackMap: Map<string, MotionRotateCallback> = new Map();
  private isMotionRollRegistered: boolean = false; // Motion模块侧倾
  private motionRollCallbackMap: Map<string, MotionRollCallback> = new Map();
  private isMagneticRegistered: boolean = false; // 磁场传感器
  private magneticCallbackMap: Map<string, SensorMagneticCallback> = new Map();

  public static getInstance(): SensorService {
    if (!SensorService.sInstance) {
      SensorService.sInstance = new SensorService();
    }
    return SensorService.sInstance;
  }

  /**
   * 下述注册重力传感数据监听
   */
  public async registerGravityListener(callback: SensorCallback, hashCode: string): Promise<void> {
    HiLog.i(TAG, 'registerGravityListener E.');
    if (AppStorage.get('isBackground')) {
      HiLog.w(TAG, 'onGravityListener is isBackground and return.');
      return;
    }
    try {
      this.gravityCallbackMap.set(hashCode, callback);
      HiLog.i(TAG, `registerGravityListener callbackMap length: ${this.gravityCallbackMap.size}.`);
      this.onGravityListener();
    } catch (err) {
      HiLog.e(TAG, `registerGravityListener err: ${err?.code}.`);
      return;
    }
    HiLog.i(TAG, 'registerGravityListener X.');
  }

  private onGravityListener(): void {
    if (this.isGravityAlreadyRegistered) {
      HiLog.i(TAG, 'onGravityListener is registered and return.');
      return;
    }

    if (CameraAppCapability.getInstance().getIsOnlySupportAccelerometer()) {
      try {
        sensor.on(sensor.SensorId.ACCELEROMETER, this.gravityDataCallBack.bind(this), {
          interval: SensorService.GRAVITY_CYCLE
        });
        this.isGravityAlreadyRegistered = true;
        HiLog.i(TAG, 'sensor.SensorId.ACCELEROMETER registered.');
      } catch (err) {
        HiLog.e(TAG, `sensor.SensorId.ACCELEROMETER on err: ${err?.code}.`);
      }
    } else {
      try {
        sensor.on(sensor.SensorId.ACCELEROMETER, this.gravityDataCallBack.bind(this), {
          interval: SensorService.GRAVITY_CYCLE
        });
        this.isGravityAlreadyRegistered = true;
        HiLog.i(TAG, 'sensor.SensorId.GRAVITY registered.');
      } catch (err) {
        HiLog.e(TAG, `sensor.SensorId.GRAVITY on err: ${err?.code}.`);
      }
    }
  }

  private gravityDataCallBack(data: sensor.GravityResponse): void {
    this.gravityCallbackMap.forEach((callBackItem) => {
      callBackItem.onGravitySensor(data);
    });
    this.motionRotateCallbackMap.forEach((callBackItem) => {
      this.isMotionRotateRegistered = true;
      callBackItem.onMotionRotate(this.motionMappingDirection(AppStorage.Get('sensorAngle') as number));
    });
  }
  public sensorToViewRotation(sensorValue: number): number {
    // 归一化到 -180~180
    let normalized = (sensorValue % 360 + 360) % 360;
    // 可选：叠加偏移（比如初始旋转180°）
    normalized = (normalized + 180) % 360;
    return normalized - 180;
  }
// -90 0 90 180 270
  // 从motion旋转角度转换成应用内定义的四个方向
  private motionMappingDirection(data: number): number {
    data = this.sensorToViewRotation(data);
    if (data >= -135 && data < -45) {
      return DeviceInfo.isUis7885() ? WindowDirection.TOP : WindowDirection.LEFT;
    } else if (data >= -45 && data < 45) {
      return DeviceInfo.isUis7885() ? WindowDirection.RIGHT : WindowDirection.BOTTOM;
    } else if (data >= 45 && data < 135) {
      return DeviceInfo.isUis7885() ? WindowDirection.LEFT : WindowDirection.TOP;
    } else {
      return DeviceInfo.isUis7885() ? WindowDirection.BOTTOM : WindowDirection.RIGHT;
    }
  }
  public unRegisterGravityListener(hashCode: string): void {
    try {
      this.gravityCallbackMap.delete(hashCode);
      if (this.gravityCallbackMap.size === 0) {
        HiLog.i(TAG, 'unRegisterGravityListener call back size is 0.');
        this.pauseGravityListener();
      } else {
        HiLog.e(TAG, 'unRegisterGravityListener interrupted, callBackMap size: ' + this.gravityCallbackMap.size);
      }
      this.isGravityAlreadyRegistered = false;
    } catch (err) {
      HiLog.e(TAG, `unRegisterGravityListener errCode: ${err?.code}.`);
    }
  }

  private pauseGravityListener(): void {
    if (CameraAppCapability.getInstance().getIsOnlySupportAccelerometer()) {
      sensor.off(sensor.SensorId.ACCELEROMETER);
    } else {
      sensor.off(sensor.SensorId.ACCELEROMETER);
    }
    this.isGravityAlreadyRegistered = false;
    this.gravityCallbackMap.clear();
    HiLog.i(TAG, 'pauseGravityListener Sensor off done.');
  }

  /**
   * 下述注册陀螺仪传感数据监听
   */
  public registerGyroscopeListener(callback: SensorGyroscopeCallback, hashCode: string): Promise<void> {
    HiLog.i(TAG, 'registerGyroscopeListener E.');
    try {
      this.gyroscopeCallbackMap.set(hashCode, callback);
      this.onGyroscopeListener();
    } catch (err) {
      HiLog.e(TAG, `registerGyroscopeListener err: ${err?.code}.`);
      return;
    }
    HiLog.i(TAG, 'registerGyroscopeListener X.');
  }

  private onGyroscopeListener(): void {
    if (AppStorage.get('isBackground')) {
      HiLog.w(TAG, 'onGyroscopeListener is isBackground and return.');
      return;
    }
    if (this.isGyroscopeAlreadyRegistered) {
      HiLog.i(TAG, 'onGyroscopeListener is registered and return.');
      return;
    }
    try {
      sensor.on(sensor.SensorId.GYROSCOPE, (data: sensor.GyroscopeResponse) => {
        this.gyroscopeCallbackMap.forEach((callBackItem) => {
          callBackItem.onGyroscopeSensor(data);
        });
      }, {
        interval: SensorService.GYROSCOPE_CYCLE
      });
      this.isGyroscopeAlreadyRegistered = true;
    } catch (err) {
      HiLog.e(TAG, `sensor.SensorId.GYROSCOPE on err: ${err?.code}.`);
    }
  }

  public unRegisterGyroscopeListener(hashCode: string): void {
    try {
      this.gyroscopeCallbackMap.delete(hashCode);
      if (this.gyroscopeCallbackMap.size === 0) {
        sensor.off(sensor.SensorId.GYROSCOPE);
        this.isGyroscopeAlreadyRegistered = false;
        this.gyroscopeCallbackMap.clear();
      }
    } catch (err) {
      HiLog.e(TAG, `unRegisterGyroscopeListener errCode: ${err?.code}.`);
    }
  }

  /**
   * 下述注册Motion模块旋转事件数据监听
   */
  public async registerMotionRotateListener(callback: MotionRotateCallback, hashCode: string): Promise<void> {
    HiLog.i(TAG, 'registerMotionRotateListener E.');
    try {
      this.motionRotateCallbackMap.set(hashCode, callback);
      //TODO 没有这个 await this.onMotionRotateListener();
    } catch (err) {
      HiLog.e(TAG, `registerMotionRotateListener err: ${err?.code}.`);
    }
  }

  private async onMotionRotateListener(): Promise<void> {
    if (AppStorage.get('isBackground')) {
      HiLog.w(TAG, 'onMotionRotateListener is isBackground and return.');
      return;
    }
    if (this.isMotionRotateRegistered) {
      HiLog.i(TAG, 'onMotionRotateListener is registered and return.');
      return;
    }
    try {
      await motion.on(motion.MotionType.TYPE_ROTATE, this.motionDataCallback.bind(this));
      this.isMotionRotateRegistered = true;
    } catch (err) {
      this.isMotionRotateRegistered = false;
      HiLog.e(TAG, `motion.MotionType.TYPE_ROTATE on err: ${err?.code}.`);
      let error = err as BusinessError;
      console.error("Failed on and err code is " + error.code);
    }
  }

  //TODO 没有旋转事件的api ,这里需要把加速事件整改一下
  private motionDataCallback(data: motion.MotionResponse): void {
    this.motionRotateCallbackMap.forEach((callBackItem) => {
      callBackItem.onMotionRotate(data.motionValue);
    });
  }

  public async unRegisterMotionRotateListener(hashCode?: string): Promise<void> {
    HiLog.i(TAG, 'unRegisterMotionRotateListener.');
    if (!AppStorage.get<boolean>('isBackground') && AppStorage.get('isMainForeground')) {
      HiLog.w(TAG, 'unRegisterMotionRotateListener isBackground false return');
      this.isMotionRotateRegistered = false;
      return;
    }
    try {
      this.motionRotateCallbackMap.delete(hashCode);
      if (this.motionRotateCallbackMap.size === 0 || !hashCode) {
        HiLog.i(TAG, 'unRegisterMotionRotateListener call back size is 0.');
        await motion.off(motion.MotionType.TYPE_ROTATE);
        this.isMotionRotateRegistered = false;
        this.motionRotateCallbackMap.clear();
      }
    } catch (err) {
      this.isMotionRotateRegistered = false;
      HiLog.e(TAG, `unRegisterMotionRotateListener errCode: ${err?.code}.`);
    }
  }

  /**
   * 下述注册Motion模块翻转事件数据监听
   */
  public async registerMotionRollListener(callback: MotionRollCallback, hashCode: string): Promise<void> {
    HiLog.i(TAG, 'registerMotionRollListener E.');
    try {
      this.motionRollCallbackMap.set(hashCode, callback);
      await this.onMotionRollListener();
    } catch (err) {
      HiLog.e(TAG, `registerMotionRollListener err: ${err?.code}.`);
    }
  }

  private async onMotionRollListener(): Promise<void> {
    if (AppStorage.get('isBackground')) {
      HiLog.w(TAG, 'onMotionRollListener is isBackground and return.');
      return;
    }
    if (this.isMotionRollRegistered) {
      HiLog.i(TAG, 'onMotionRollListener is registered and return.');
      return;
    }
    try {
      await motion.on(motion.MotionType.TYPE_ROLL, this.motionRollDataCallback.bind(this));
      this.isMotionRollRegistered = true;
    } catch (err) {
      HiLog.e(TAG, `motion.MotionType.TYPE_ROLL on err: ${err?.code}.`);
    }
  }

  private motionRollDataCallback(data: motion.FlipResponse): void {
    this.motionRollCallbackMap.forEach((callBackItem) => {
      callBackItem.onMotionRoll(data.motionValue);
    });
  }

  public async unRegisterMotionRollListener(hashCode?: string): Promise<void> {
    HiLog.i(TAG, 'unRegisterMotionRollListener.');
    try {
      this.motionRollCallbackMap.delete(hashCode);
      if (this.motionRollCallbackMap.size === 0 || !hashCode) {
        HiLog.i(TAG, 'unRegisterMotionRollListener call back size is 0.');
        await motion.off(motion.MotionType.TYPE_ROLL);
        this.isMotionRollRegistered = false;
        this.motionRollCallbackMap.clear();
      }
    } catch (err) {
      HiLog.e(TAG, `unRegisterMotionRollListener errCode: ${err?.code}.`);
    }
  }

  /**
   * 下述注册磁力计精度数据监听
   */
  public registerMagneticListener(magneticCallback: SensorMagneticCallback, hashCode: string): void {
    HiLog.i(TAG, `registerMagneticListener E.`);
    try {
      this.magneticCallbackMap.set(hashCode, magneticCallback);
      this.onMagneticListener();
      sensor.on(sensor.SensorId.MAGNETIC_FIELD, (data: sensor.MagneticFieldResponse) => {
        HiLog.i(TAG, `data:${data}`);
        if (magneticCallback) {
          magneticCallback.onMagneticSensor(data);
        }
      }, {
        interval: SensorService.MAGNETIC_CYCLE
      });
    } catch (err) {
      HiLog.e(TAG, `sensor.SensorId.MAGNETIC_FIELD on err. ${err?.code}`);
    }
  }

  private onMagneticListener(): void {
    if (AppStorage.get('isBackground')) {
      HiLog.w(TAG, 'onMagneticListener is isBackground and return.');
      return;
    }
    if (this.isMagneticRegistered) {
      HiLog.i(TAG, 'onMagneticListener is registered and return.');
      return;
    }
    try {
      sensor.on(sensor.SensorId.MAGNETIC_FIELD, this.magneticDataCallback.bind(this), {
        interval: SensorService.MAGNETIC_CYCLE
      });
      this.isMagneticRegistered = true;
    } catch (err) {
      HiLog.e(TAG, `sensor.SensorId.MAGNETIC_FIELD on err. ${err?.code}`);
    }
  }

  private magneticDataCallback(data: sensor.MagneticFieldResponse): void {
    this.magneticCallbackMap.forEach((callBackItem) => {
      callBackItem.onMagneticSensor(data);
    });
  }

  public unRegisterMagneticListener(hashCode: string): void {
    try {
      this.magneticCallbackMap.delete(hashCode);
      if (this.magneticCallbackMap.size === 0) {
        HiLog.i(TAG, 'unRegisterMagneticListener call back size is 0.');
        sensor.off(sensor.SensorId.MAGNETIC_FIELD);
        this.isMagneticRegistered = false;
        this.magneticCallbackMap.clear();
      }
    } catch (err) {
      HiLog.e(TAG, `unRegisterMagneticListener errCode: ${err?.code}`);
    }
  }

}
