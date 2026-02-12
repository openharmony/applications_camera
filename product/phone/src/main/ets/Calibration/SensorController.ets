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

import sensor from '@ohos.sensor';
import lazy { Quaternion } from '@kit.ArkGraphics3D';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import StateStore from './StateStore';
import MathUtil from './MathUtil';
import lazy { DisplayScreen } from './DisplayScreen';
import lazy { display, window } from '@kit.ArkUI';
import MathConstant from './MathConstant';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import CameraStandUpController from './CameraStandupController';
import lazy { PairValue, TripleValue } from './CompassData';
import lazy { CollapsChangeService } from '@ohos/common/src/main/ets/service/collaps/CollapsChangeService';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';

const TAG = 'SensorController';

const SENSOR_REPORT_INTERVAL_1S = 1000000000;
// 传感器上报间隔150ms
const SENSOR_REPORT_INTERVAL_150MS = 150000000;
const SENSOR_REPORT_INTERVAL_20MS = 15000000;

const DATA_RECORD_LEN = 20;

export class SensorController {
  private static instance: SensorController;
  // 罗盘转动角度（顺时针）
  private mTargetAngleX = 0;
  private mLastTargetDirectionX = 0;
  private mArrayIndex = 0;
  // 性能优化-缓存上一次Y轴的平均值
  private lastAvgY: number = 0;
  // 性能优化-缓存上一次Z轴的平均值
  private lastAvgZ: number = 0;
  private mSensorOrientationYs: number[] | undefined;
  private mSensorOrientationZs: number[] | undefined;
  private sensorValuesAngelYs: number[] | undefined;
  private sensorValuesDegrees: number[] | undefined;
  private mAvgOrientations: TripleValue = [0, 0, 0];
  private r = new number[](9).fill(0);
  private i = new number[](9).fill(0);
  private nativeAccelerometerData: number[] = [0, 0, 0];
  private mOrientationsFloat: TripleValue = [0, 0, 0];
  private mCurrentMagnetic: number = 0;
  private mPosition = 0;
  // 性能优化-缓存上一次的气压值
  private lastPressure: number = 0;
  /**
   * [angleY,degree]
   */
  private mDirectionPair: PairValue = [0.0001, 0];
  // 性能优化-缓存上一次上报的精度值
  private lastAccuracy: number = sensor.SensorAccuracy.ACCURACY_LOW;
  private mLastAccX: number = 0;
  private mLastAccY: number = 0;
  private mLastAccZ: number = 0;
  private rawAngle: number = 0;
  private mDegree: number = 0;
  private mAccelerometers = [0, 0, 0];
  private mTargetDegreeY: number = 0;
  private isRotation: number = 0;
  private isOverTurn: boolean = false;
  // 性能优化-缓存上一次的方向数据
  private lastFixedOrientationData: number[] = [];
  private lastCameraLevelOrientations: number[] = [0, 0, 0];
  private lastOrientationsFloats: TripleValue = [0, 0, 0];
  private mReverseOrientations: TripleValue = [0, 0, 0];
  private mOrientations = [0, 0, 0];
  // 沿着X 轴旋转90度
  private xQuaternionRotate: Quaternion = {
    x: -0.7071068,
    y: 0.0,
    z: 0.0,
    w: 0.7071068
  };

  public static getInstance(): SensorController {
    if (!SensorController.instance) {
      SensorController.instance = new SensorController();
    }
    return SensorController.instance;
  }

  public registerSensor(): void {
    HiLog.i(TAG, `registerSensor this.lastAccuracy:${this.lastAccuracy}`);
    this.registerRotationVector();
    this.registerMagnetic();
    this.registerAccelerometer();
  }

  public unregisterSensor(): void {
    HiLog.i(TAG, `unregisterSensor`);
    try {
      HiLog.i(TAG, 'unregister rotation vector');
      sensor.off(sensor.SensorId.ROTATION_VECTOR);
      HiLog.i(TAG, 'unregister rotation vector finish');
    } catch (e) {
      HiLog.e(TAG, 'unregister rotation vector error ' + JSON.stringify(e));
    }
    try {
      HiLog.i(TAG, 'unregister magnetic field');
      sensor.off(sensor.SensorId.MAGNETIC_FIELD);
      HiLog.i(TAG, 'unregister magnetic field finish');
    } catch (e) {
      HiLog.e(TAG, 'unregister magnetic field error ' + JSON.stringify(e));
    }
    try {
      HiLog.i(TAG, 'unregister Accelerometer field');
      sensor.off(sensor.SensorId.ACCELEROMETER);
      HiLog.i(TAG, 'unregister Accelerometer field finish');
    } catch (e) {
      HiLog.e(TAG, 'unregister Accelerometer field error ' + JSON.stringify(e));
    }
    this.clearCacheData();
  }

  public registerAccelerometer(): void {
    try {
      sensor.on(sensor.SensorId.ACCELEROMETER, (data: sensor.AccelerometerResponse) => {
        this.accelerometerDataBack(data);
      }, { interval: SENSOR_REPORT_INTERVAL_150MS });
    } catch (e) {
      HiLog.e(TAG, 'registerAccelerometer error:' + JSON.stringify(e));
    }
  }

  private accelerometerDataBack(data: sensor.AccelerometerResponse): void {
    if (DisplayScreen.getVerdeExternalScreen()) {
      data.y = -data.y;
    }
    if (MathUtil.equalFloat(this.mLastAccX, data.x, 0.05) && MathUtil.equalFloat(this.mLastAccY, data.y, 0.05) &&
    MathUtil.equalFloat(this.mLastAccZ, data.z, 0.05)) {
      return;
    }

    this.accelerometerDataToArr(data, this.nativeAccelerometerData);
    HiLog.d(TAG, 'accelerometerDataBack_changed', 'ACCELEROMETER:' + data.x + ',' + data.y + ',' + data.z);

    let accelerometersTmp = MathUtil.convertAccelerometer(data.x, data.y, data.z);
    if (MathUtil.equalFloat(this.mAccelerometers[0], accelerometersTmp[0], 0.05) &&
    MathUtil.equalFloat(this.mAccelerometers[1], accelerometersTmp[1], 0.85)) {
      HiLog.d(TAG, 'accelerometerDataBack_temp_equals', 'drop--- angle data');
      return;
    }
    this.mLastAccX = data.x;
    this.mLastAccY = data.y;
    this.mLastAccZ = data.z;

    this.mAccelerometers = accelerometersTmp;
    this.mTargetDegreeY = MathUtil.getLevelDegree(this.mAccelerometers[1]);
    this.updateOverTurn(this.mTargetDegreeY);
    StateStore.updateAccDegreePair([this.mAccelerometers[0], this.mTargetDegreeY])

    if (window.Orientation.AUTO_ROTATION) {
      window.getLastWindow(getContext(), (err, win) => {
        let rotation: number = DisplayService.getInstance().getDisplay().orientation // 获取当前屏幕的枚举值
        // 横屏显示内容 或 显示内容与竖屏模式方向相反。
        HiLog.d(TAG, 'getLastWindow_rotation', `getDisplay orientation ${rotation}`);
        StateStore.updateDeviceOrientation(rotation);
        if (rotation === display.Orientation.LANDSCAPE || rotation === display.Orientation.PORTRAIT_INVERTED ||
          rotation === display.Orientation.LANDSCAPE_INVERTED) {
          this.isRotation = rotation;
          HiLog.i(TAG, 'getLastWindow_rotation', 'getLastWindow_rotation: ' + rotation)
        } else {
          this.isRotation = 0;
        }
        StateStore.updateIsRotation(this.isRotation)
      })
    } else {
      this.isRotation = 0;
      StateStore.updateIsRotation(this.isRotation)
    }
  }

  public registerMagnetic(): void {
    try {
      sensor.on(sensor.SensorId.MAGNETIC_FIELD, (data: sensor.MagneticFieldResponse) => {
        this.magneticDataBack(data);
      }, { interval: SENSOR_REPORT_INTERVAL_1S });
    } catch (e) {
      HiLog.e(TAG, 'registerMagnetic error:' + JSON.stringify(e));
    }
  }

  private magneticDataBack(data: sensor.MagneticFieldResponse): void {
    HiLog.i(TAG, `data.accuracy:${data.accuracy}`);
    if (this.lastAccuracy !== data.accuracy) {
      StateStore.updateAccuracyData(data.accuracy);
      this.lastAccuracy = data.accuracy;
    }
    this.calculateMagneticStrength([data.x, data.y, data.z]);
  }

  private accelerometerDataToArr(accData: sensor.AccelerometerResponse, targetArr: number[]) {
    if (!targetArr) {
      targetArr = [0, 0, 0];
    }
    targetArr[0] = accData.x;
    targetArr[1] = accData.y;
    targetArr[2] = accData.z;
  }

  public registerRotationVector(): void {
    try {
      sensor.on(sensor.SensorId.ROTATION_VECTOR, (data: sensor.RotationVectorResponse) => {
        try {
          HiLog.i(TAG, 'registerRotationVector_rotation_vector',
            `rotation vector data: x:${data.x},y:${data.y},z:${data.z},w:${data.w}`)
          this.rotationVectorDataBack(data);
        } catch (e) {
          HiLog.e(TAG, 'rotationVectorDataBack error:' + JSON.stringify(e));
        }
      }, { interval: SENSOR_REPORT_INTERVAL_20MS });
    } catch (e) {
      HiLog.e(TAG, 'registerRotationVector error:' + JSON.stringify(e));
    }
  }

  private rotationVectorDataBack(rvData: sensor.RotationVectorResponse): void {
    // verde 的状态处理
    if (DeviceInfo.isVerde() &&
      CollapsChangeService.getInstance().getCurCollapsStatus() === display.CollapsStatus.COLLAPS_STATUS_COLLAPSED) {
      let rvQuaternion: Quaternion = {
        x: rvData.x,
        y: rvData.y,
        z: rvData.z,
        w: rvData.w
      };
      const newQuaternion =
        this.multiply(this.multiply(rvQuaternion, this.xQuaternionRotate), this.inverse(this.xQuaternionRotate))
      rvData.x = newQuaternion.x;
      rvData.y = newQuaternion.y;
      rvData.z = newQuaternion.z;
      rvData.w = newQuaternion.w;
    }

    this.fixedRotationVectorData(rvData, 10, 10);
    // 过滤重复数据避免功耗
    if (this.orientationDataNoChanged(rvData, this.lastFixedOrientationData, 0.001)) {
      // 数据不改变时也需要判断是否显示实景
      this.doCameraShow(this.lastCameraLevelOrientations);
      return;
    }

    this.cacheLastRVData(rvData, this.lastFixedOrientationData)
    MathUtil.rotationVectorConvertToOrientation(rvData, this.mOrientationsFloat);
    StateStore.updateOrientationVectorData(this.mOrientationsFloat);
    this.doOrientationCalc(this.mOrientationsFloat);
  }

  private cacheLastRVData(rvData: sensor.RotationVectorResponse, lastCacheArr: number[]) {
    if (!lastCacheArr) {
      lastCacheArr = [rvData.x, rvData.y, rvData.z, rvData.w];
    } else {
      lastCacheArr[0] = rvData.x;
      lastCacheArr[1] = rvData.y;
      lastCacheArr[2] = rvData.z;
      lastCacheArr[3] = rvData.w;
    }
  }

  private doCameraShow(orientationsFloats: number[]): void {
    let orientationY = orientationsFloats[1];
    let orientationZ = orientationsFloats[2];
    CameraStandUpController.updateCameraStandUpStatus(orientationY, orientationZ);
  }

  private doOrientationCalc(orientationsFloats: TripleValue): void {
    this.mTargetAngleX = MathUtil.normalizeDegree(orientationsFloats[0] * MathConstant.SWITCH_NEGATIVE_FLOAT);
    if (MathUtil.equalFloat(this.lastOrientationsFloats[0], orientationsFloats[0], 0.05) &&
    MathUtil.equalFloat(this.lastOrientationsFloats[1], orientationsFloats[1], 0.05) &&
    MathUtil.equalFloat(this.lastOrientationsFloats[2], orientationsFloats[2], 0.05)
    ) {
      HiLog.d(TAG, 'doOrientationCalc orientationsFloats no change')
      return
    }
    this.lastOrientationsFloats = [orientationsFloats[0], orientationsFloats[1], orientationsFloats[2]];
    this.mLastTargetDirectionX = this.mTargetAngleX;
    // 罗盘页数据计算
    this.rawAngle = shapeAngle(this.mLastTargetDirectionX, this.isOverTurn, this.isRotation);
    this.updateRawAngle();
    // 水平仪页数据计算
    MathUtil.convertToOrientationInt(orientationsFloats, this.mOrientations);
    MathUtil.shallowCopyNum(this.mReverseOrientations, orientationsFloats);
    this.refreshLevelDegree();
  }

  private updateRawAngle() {
    // 指南针角度
    let rawAngleRotationFix =
      MathUtil.getRotationOffset(this.rawAngle, StateStore.getDeviceOrientation(), DeviceInfo.getDeviceType(), TAG);
    StateStore.updateRawAngle(rawAngleRotationFix);
    // 显示文字方向 角度
    let orientation = shapeOrientation(rawAngleRotationFix, this.isOverTurn);
    HiLog.d(TAG,
      `updateRawAngle ===doOrientationCalc  ${orientation} ==${this.rawAngle}==${rawAngleRotationFix}=${this.isOverTurn}`)
    StateStore.updateOrientation(orientation);
  }

  /**
   * 只计算小数点10位
   * @param data
   * @param digits
   * @param base
   */
  private fixedRotationVectorData(data: sensor.RotationVectorResponse, digits: number, base: number) {
    data.x = MathUtil.toFixedNumber(data.x, digits, base);
    data.y = MathUtil.toFixedNumber(data.y, digits, base);
    data.z = MathUtil.toFixedNumber(data.z, digits, base);
    data.w = MathUtil.toFixedNumber(data.w, digits, base);
  }

  private orientationDataNoChanged(newData: sensor.RotationVectorResponse, lastFixedOrientationData: number[],
    delta: number): boolean {
    return MathUtil.equalFloat(newData.x, lastFixedOrientationData[0], delta) &&
    MathUtil.equalFloat(newData.y, lastFixedOrientationData[1], delta) &&
    MathUtil.equalFloat(newData.z, lastFixedOrientationData[2], delta) &&
    MathUtil.equalFloat(newData.w, lastFixedOrientationData[3], delta)
  }

  /**
   * 水平仪页角度计算
   */
  private refreshLevelDegree(): void {
    this.adjustOrientation();
    HiLog.d(TAG, 'refreshValue', 'mDegree is:' + this.mDegree);
    if (this.mDegree < 100) {
      this.changeValue();
    } else {
      this.changeValuesAcc();
    }
    this.refreshAngleAndDegree();
  }

  adjustOrientation(): void {
    HiLog.d(TAG, 'adjustOrientation',
      `adjustOrientation x:${this.mOrientations[0]} y:${this.mOrientations[1]} z:${this.mOrientations[2]}`);
    this.mOrientations[2] = MathConstant.DEGREE_180 - this.mOrientations[2];
    if (this.mOrientations[1] > MathConstant.DEGREE_180) {
      this.mOrientations[1] = MathConstant.DEGREE_360 - this.mOrientations[1];
    } else {
      this.mOrientations[1] = -this.mOrientations[1];
    }
  }

  private updateOverTurn(degreeY: number) {
    HiLog.d(TAG, `updateOverTurn ==== ${degreeY}`)
    const isVerdeExternalScreen = DisplayScreen.getVerdeExternalScreen();
    let isOverTurn: boolean = false;
    if (isVerdeExternalScreen) {
      isOverTurn = degreeY < 60
    } else {
      isOverTurn = degreeY >= MathConstant.DEGREE_120;
    }
    this.isOverTurn = isOverTurn;
    StateStore.updateIsOverTurn(this.isOverTurn);
  }

  changeValue(): void {
    if (!this.mSensorOrientationYs || !this.mSensorOrientationZs) {
      this.mSensorOrientationYs = new number[](DATA_RECORD_LEN).fill(-this.mOrientations[1]);
      this.mSensorOrientationZs = new number[](DATA_RECORD_LEN).fill(this.mOrientations[2]);
      HiLog.i(TAG, 'changeValue init arr');
    }
    this.mArrayIndex++;
    this.mArrayIndex %= DATA_RECORD_LEN;
    HiLog.d(TAG, 'changeValue', `orientationY:${this.mOrientations[1]} orientationZ:${this.mOrientations[2]}
       mArrayIndex:${this.mArrayIndex}`);
    this.mSensorOrientationYs[this.mArrayIndex] = -this.mOrientations[1];
    this.mSensorOrientationZs[this.mArrayIndex] = this.mOrientations[2];

    let avgY: number = MathUtil.getAverage(this.mSensorOrientationYs);
    let avgZ: number = MathUtil.getAverage(this.mSensorOrientationZs);
    avgY = -avgY;
    avgZ = -avgZ;
    if (avgY === this.lastAvgY && avgZ === this.lastAvgZ) {
      return;
    }
    this.lastAvgY = avgY;
    this.lastAvgZ = avgZ;
    HiLog.d(TAG, 'changeValue_avgY_avgZ', 'avgY ' + avgY + ' | avgZ ' + avgZ)
    if (avgY !== 0) {
      this.mAvgOrientations[1] = avgY;
    }
    if (avgZ !== 0) {
      this.mAvgOrientations[2] = avgZ;
    }
    this.mDegree = Math.max(Math.abs(this.mAvgOrientations[1]), Math.abs(this.mAvgOrientations[2]));
    if (this.mDegree < 3) {
      this.mDegree = Math.floor(this.mDegree);
    }
    this.updateLevelDegree(this.mAvgOrientations);
  }

  updateLevelDegree(orientations: TripleValue): void {
    HiLog.d(TAG, 'updateLevelDegree_enter',
      `updateLevelDegree--->orientations:[${orientations[0]},${orientations[1]},${orientations[2]}]`);
    let orientationY = orientations[1];
    let orientationZ = orientations[2];
    if (Number.isNaN(orientationY) || !orientationY) {
      HiLog.e(TAG, 'updateLevelDegree_invalidate_orientationY', 'orientation y is NaN');
      orientationY = 0;
    }
    if (Number.isNaN(orientationZ) || !orientationZ) {
      HiLog.e(TAG, 'updateLevelDegree_invalidate_orientationX', 'orientation z is NaN');
      orientationZ = 0;
    }
    let levelDegree = Math.round(Math.max(Math.abs(orientationY), Math.abs(orientationZ)));
    HiLog.d(TAG, 'updateLevelDegree_level_degree', 'zeroDegree:' + levelDegree);
    if (Number.isNaN(levelDegree)) {
      HiLog.e(TAG, 'updateLevelDegree_invalidate_level_degree', 'degree is NaN');
      levelDegree = 0;
    }
    let cOrientationY = Math.round(orientationY);
    let cOrientationZ = Math.round(orientationZ);
    this.lastCameraLevelOrientations[0] = orientations[0];
    this.lastCameraLevelOrientations[1] = cOrientationY;
    this.lastCameraLevelOrientations[2] = cOrientationZ;
    this.doCameraShow(this.lastCameraLevelOrientations);
    StateStore.updateOrientations({
      levelDegree: levelDegree,
      orientations: orientations
    });
  }

  refreshAngleAndDegree(): void {
    try {
      if (!this.sensorValuesAngelYs || !this.sensorValuesDegrees) {
        this.sensorValuesAngelYs = new number[](DATA_RECORD_LEN).fill(this.mAccelerometers[0]);
        this.sensorValuesDegrees = new number[](DATA_RECORD_LEN).fill(this.mAccelerometers[1]);
        HiLog.d(TAG, 'refreshAngleAndDegree init')
      }

      this.mPosition++;
      this.mPosition %= DATA_RECORD_LEN;
      this.sensorValuesAngelYs[this.mPosition] = this.mAccelerometers[0];
      this.sensorValuesDegrees[this.mPosition] = this.mAccelerometers[1];


      let valueRealY: number = MathUtil.getMedian(this.sensorValuesAngelYs);
      let valueRealDegree: number = MathUtil.getMedian(this.sensorValuesDegrees);

      if ((Math.round(this.mDirectionPair[0]) !== Math.round(valueRealY) ||
        Math.round(this.mDirectionPair[1]) !== Math.round(this.mAccelerometers[1]))) {
        this.mDirectionPair[0] = this.setAngelYanimation(valueRealY, this.mDirectionPair[0]);
        HiLog.d(TAG, 'refreshAngleAndDegreeAsync_mDirectAngelY', 'mDirectAngelY:' + this.mDirectionPair[0]);
        this.mDirectionPair[1] = this.setDegreeAnimation(valueRealDegree, this.mDirectionPair[1]);
        HiLog.d(TAG, 'refreshAngleAndDegreeAsync_mDirectDegree', 'mDirectDegree:' + this.mDirectionPair[1]);
        StateStore.updateDirections(this.mDirectionPair);
      }
    } catch (e) {
      HiLog.e(TAG, 'refreshAngleAndDegreeAsync_catch', 'changeValues error:' + JSON.stringify(e));
    }
  }

  setAngelYanimation(angelY: number, directAngelY: number): number {
    let toAngelY = angelY;
    let mCurrentDirecangelY = 0;

    if (this.isBiggerFloat(toAngelY - directAngelY, MathConstant.DEGREE_180)) {
      toAngelY -= MathConstant.DEGREE_360;
    } else if (this.isSmallerFloat(toAngelY - directAngelY, -MathConstant.DEGREE_180)) {
      toAngelY += MathConstant.DEGREE_360;
    }
    let distance = toAngelY - directAngelY;
    let zeroPointTwo = 0.2;
    if (this.isBiggerFloat(Math.abs(distance), zeroPointTwo)) {
      distance = distance > 0 ? zeroPointTwo : (-1 * zeroPointTwo);
    }
    mCurrentDirecangelY = MathUtil.normalizeDegree(directAngelY + ((toAngelY - directAngelY) * 0.09));

    return mCurrentDirecangelY;
  }

  isBiggerFloat(f1: number, f2: number): boolean {
    return (f1 - f2) > 0.00001;
  }

  isSmallerFloat(f1: number, f2: number): boolean {
    return (f2 - f1) > 0.00001;
  }

  setDegreeAnimation(degree: number, directDegree: number): number {
    let toDegree = degree;
    let currentDirectDegree = 0;
    // limit the max speed to MAX_ROTATE_DEGREE
    let distance = toDegree - directDegree;

    if (this.isBiggerFloat(Math.abs(distance), 1)) {
      distance = distance > 0 ? 1 : -1;
    }

    currentDirectDegree = MathUtil.normalizeDegree(directDegree + ((toDegree - directDegree) * 0.09));

    return currentDirectDegree;
  }

  changeValuesAcc(): void {
    HiLog.d(TAG, 'changeValuesAcc_enter',
      `changeValueAcc-->[${this.mReverseOrientations[0]},${this.mReverseOrientations[1]},${this.mReverseOrientations[2]}]`);
    if (this.mReverseOrientations[1] > MathConstant.DEGREE_180) {
      this.mReverseOrientations[1] = this.mReverseOrientations[1] - MathConstant.DEGREE_360;
    }
    if (this.mReverseOrientations[2] > MathConstant.DEGREE_180) {
      this.mReverseOrientations[2] = this.mReverseOrientations[2] - MathConstant.DEGREE_360;
    }
    this.mReverseOrientations[1] = -this.mReverseOrientations[1];
    this.mReverseOrientations[2] = -this.mReverseOrientations[2];
    this.mDegree = Math.min(Math.abs(MathConstant.DEGREE_180 - Math.abs(this.mReverseOrientations[1])),
      Math.abs(MathConstant.DEGREE_180 - Math.abs(this.mReverseOrientations[2])));

    if (this.mDegree > 178) {
      this.mDegree = Math.ceil(this.mDegree);
    }
    this.updateLevelDegree(this.mReverseOrientations);
  }

  // 归一化
  normalise(q: Quaternion): Quaternion {
    let magnitude = Math.sqrt(q.w * q.w + q.x * q.x + q.y * q.y + q.z * q.z);
    return {
      w: q.w / magnitude,
      x: q.x / magnitude,
      y: q.y / magnitude,
      z: q.z / magnitude
    }
  }

  // 相乘
  multiply(q1: Quaternion, q2: Quaternion): Quaternion {
    const newW = q2.w * q1.w - q2.x * q1.x - q2.y * q1.y - q2.z * q1.z;
    const newX = q2.w * q1.x + q2.x * q1.w + q2.y * q1.z - q2.z * q1.y;
    const newY = q2.w * q1.y - q2.x * q1.z + q2.y * q1.w + q2.z * q1.x;
    const newZ = q2.w * q1.z + q2.x * q1.y - q2.y * q1.x + q2.z * q1.w;
    return {
      w: newW,
      x: newX,
      y: newY,
      z: newZ
    }
  }

  inverse(ret: Quaternion): Quaternion {
    ret.x *= -1;
    ret.y *= -1;
    ret.z *= -1;
    return ret;
  }

  /**
   * 磁场计算
   * @param geomagnetic
   */
  private calculateMagneticStrength(geomagnetic: number[]): void {
    if (!this.nativeAccelerometerData) {
      HiLog.i(TAG, `nativeAccelerometerData is false`);
      return;
    }
    let isNormalValue = MathUtil.getRotationMatrix(this.r, this.i, this.nativeAccelerometerData, geomagnetic);
    if (!isNormalValue) {
      HiLog.i(TAG, `isNormalValue is false`);
      return;
    }
    let newMagnetic = (this.i[3] * this.r[0] + this.i[4] * this.r[3] + this.i[5] * this.r[6]) * geomagnetic[0] +
      (this.i[3] * this.r[1] + this.i[4] * this.r[4] + this.i[5] * this.r[7]) * geomagnetic[1] +
      (this.i[3] * this.r[2] + this.i[4] * this.r[5] + this.i[5] * this.r[8]) * geomagnetic[2];
    HiLog.d(TAG, 'newMagnetic:' + newMagnetic);
    if (Math.abs(this.mCurrentMagnetic - newMagnetic) < 0.5) {
      HiLog.i(TAG, `this.mCurrentMagnetic - newMagnetic < 0.5, is return`);
      return;
    }
    HiLog.d(TAG, `calculateMagneticStrength geomagnetic:[${geomagnetic[0]},${geomagnetic[1]},${geomagnetic[2]}]`);
    this.mCurrentMagnetic = newMagnetic;
    StateStore.updateMagnetic(MathUtil.formatNumber(this.mCurrentMagnetic));
  }

  private clearCacheData() {
    this.sensorValuesAngelYs = undefined;
    this.sensorValuesDegrees = undefined;
    this.mSensorOrientationYs = undefined;
    this.mSensorOrientationZs = undefined;
    this.mOrientations = [0, 0, 0];
    this.mAccelerometers = [0, 0, 0];
    this.mAvgOrientations = [0, 0, 0];
    this.i = new number[](9).fill(0);
    this.r = new number[](9).fill(0);
    this.lastFixedOrientationData = [0, 0, 0];
    this.nativeAccelerometerData = [0, 0, 0];
    this.mDegree = 0;
    this.mArrayIndex = 0;
    this.mPosition = 0;
    this.lastAccuracy = sensor.SensorAccuracy.ACCURACY_LOW;
    this.lastPressure = 0;
    this.isOverTurn = false;
  }
}

/**
 * 调整罗盘转动方向角度
 * @param angle
 * @param isOverTurn 手机是否翻转（屏幕朝下）
 * @returns
 */
function shapeAngle(angle: number, isOverTurn: boolean, isRotation: number): number {
  let tmpAngle = Math.round(angle);
  if (isOverTurn) {
    tmpAngle = MathConstant.DEGREE_540 - tmpAngle;
  }
  if (isRotation !== 0 && tmpAngle <= 360 && tmpAngle >= 180) {
    tmpAngle = tmpAngle - 360;
  }
  return tmpAngle;
}

/**
 * 方向数值文字
 * @param angle
 * @returns
 */
function shapeOrientation(angle: number, isOverTurn: boolean): number {
  let orientation: number;
  orientation = Math.round(Math.abs(MathConstant.DEGREE_360 - angle) % MathConstant.DEGREE_360);
  if (isOverTurn) {
    orientation = Math.round(Math.abs(angle) % MathConstant.DEGREE_360);
  }
  if (orientation === MathConstant.DEGREE_360) {
    orientation = MathConstant.DEGREE_ZERO;
  }
  return orientation;
}