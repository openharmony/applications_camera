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
import lazy { AngleOrientation, SensorData } from './HorizontalLevelOperation';

const TAG: string = 'HorizontalLevelUtils';

const ONE_RADIAN = 57.29577957855; //180 / PI, 1弧度
const ANGLE_0: number = 0;
const ANGLE_90: number = 90;
const ANGLE_180: number = 180;
const ANGLE_270: number = 270;
const ANGLE_360: number = 360;
const MAX_QUEUE_LENGTH: number = 5;

export class HorizontalLevelUtils {

  public static vectorAngle(sensorData: SensorData): number {
    // 利用重力加速度在x,y,z轴上的分量计算手机偏转角度
    // 由于重力加速度传感器测得的值为重力加速度在x,y,z轴上分量的相反数
    // 所以在进行角度计算之前需要取相反数
    let rx = -sensorData.x;
    let ry = -sensorData.y;
    let rz = -sensorData.z;
    let angleZ = HorizontalLevelUtils.calcAngle(AngleOrientation.RZ, rx, ry, rz);
    return angleZ;
  }

  public static calcAngle(angleOrientation: AngleOrientation, rx: number, ry: number, rz: number): number {
    let relativeX = 0;
    let relativeY = 0;
    let relativeZ = 0;
    switch (angleOrientation) {
      case AngleOrientation.RX:
        relativeX = ry;
        relativeY = rz;
        relativeZ = rx;
        break;
      case AngleOrientation.RY:
        relativeX = rx;
        relativeY = rz;
        relativeZ = ry;
        break;
      case AngleOrientation.RZ:
        relativeX = rx;
        relativeY = ry;
        relativeZ = rz;
        break;
      default:
        break;
    }

    let angleZ = Math.atan2(-relativeY, relativeX) * ONE_RADIAN;
    // 当用户面朝屏幕手持手机逆时针旋转时,Math.atan2计算结果从90增大到180
    // 此时水平线应顺时针旋转angleZ - 90°, 后面有对angleZ取相反数的过程
    angleZ = ANGLE_90 - Math.round(angleZ);
    return angleZ;
  }

  //将角度存入数组中取平均值解决用户手轻微抖动引起角度变化从而造成预览界面水平线抖动问题
  public static addAngleToQueues(angleQueue: number[], angle: number): number {
    angleQueue.push(-angle);
    if (angleQueue.length > MAX_QUEUE_LENGTH) {
      angleQueue.shift();
    }
    //当面朝屏幕状态栏在上逆时针旋转手机360：
    //旋转角度为0° -> 90°时，-angle从0° -> 90°
    //旋转角度为90° -> 180°时，-angle从 -270° -> -180°
    //旋转角度为180° -> 270°时，-angle从 -180° -> -90°
    //旋转角度为270° -> 360°时，-angle从 -90° -> 0°
    //角度在手机从90°旋转到91°时会存在角度突变的情况
    //如果存在这种情况但是不做处理的话后面算角度平均值时会有问题
    //isAboveZero跟isBelowZero就是为了表示存在这种突变
    let isAboveZero = false;
    let isBelowZero = false;
    for (let value of angleQueue) {
      if ((value >= ANGLE_0) && (value <= ANGLE_90)) {
        isAboveZero = true;
      }
      if ((value >= -ANGLE_270) && (value <= -ANGLE_180)) {
        isBelowZero = true;
      }
    }
    let sum = 0;
    for (let value of angleQueue) {
      //当存在角度从0° -> 90° 突变成 -270° -> -180° ，需要将0° -> 90°的转成对应的负角才能进行求和运算
      if (isAboveZero && isBelowZero && (value >= ANGLE_0) &&
        (value <= ANGLE_90)) {
        sum += value - ANGLE_360;
      } else {
        sum += value;
      }
    }
    if (angleQueue.length <= 0) {
      return sum;
    }
    return Math.floor(sum / angleQueue.length);
  }
}