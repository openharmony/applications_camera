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
import MathConstant from './MathConstant';
import lazy { sensor } from '@kit.SensorServiceKit';
import lazy { display, window } from '@kit.ArkUI';
import StdLibUtil from './StdLibUtil';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { CollapsChangeService } from '@ohos/common/src/main/ets/service/collaps/CollapsChangeService';

const TAG = 'MathUtil';

enum DeviceType {
  PHONE = 'phone',
  TABLET = 'tablet'
}

export default class MathUtil {
  static normalizeDegree(degree: number): number {
    return (degree + 720) % 360;
  }

  static equalFloat(f1: number, f2: number, equalOffset: number): boolean {
    return Math.abs(f1 - f2) <= equalOffset;
  }

  static getInterpolatorValue(targetValue: number, baseValue: number, interpolateValue: number): number {
    return baseValue + ((targetValue - baseValue) * interpolateValue);
  }

  static getAverage(values: number[]): number {
    if (!values) {
      return 0;
    }
    let sum = 0;
    let length = values.length;
    if (length === 0) {
      return sum;
    }
    for (let index = 0; index < length; index++) {
      sum += values[index];
    }
    return sum / length;
  }

  static toFixedNumber(num: number, digits: number, base: number): number {
    const pow = Math.pow(base ?? 10, digits);
    return Math.round(num * pow) / pow;
  }

  static getRotationMatrix(r: number[], i: number[], gravity: number[], geomagnetic: number[]): boolean {
    let aX = gravity[0];
    let aY = gravity[1];
    let aZ = gravity[2];

    const normsqA = (aX * aX + aY * aY + aZ * aZ);
    const g = 9.81;
    const freeFallGravitySquared = 0.01 * g * g;
    if (normsqA < freeFallGravitySquared) {
      // gravity less than 10% of normal value
      return false;
    }

    const eX = geomagnetic[0];
    const eY = geomagnetic[1];
    const eZ = geomagnetic[2];
    let hX = eY * aZ - eZ * aY;
    let hY = eZ * aX - eX * aZ;
    let hZ = eX * aY - eY * aX;
    const normH = Math.sqrt(hX * hX + hY * hY + hZ * hZ);

    if (normH < 0.1) {
      // device is close to free fall (or in space?), or close to
      // magnetic north pole. Typical values are  > 100.
      return false;
    }
    const invH = 1.0 / normH;
    hX *= invH;
    hY *= invH;
    hZ *= invH;
    const invA = 1.0 / Math.sqrt(aX * aX + aY * aY + aZ * aZ);
    aX *= invA;
    aY *= invA;
    aZ *= invA;
    const mX = aY * hZ - aZ * hY;
    const mY = aZ * hX - aX * hZ;
    const mZ = aX * hY - aY * hX;
    if (r) {
      if (r.length === 9) {
        r[0] = hX;
        r[1] = hY;
        r[2] = hZ;
        r[3] = mX;
        r[4] = mY;
        r[5] = mZ;
        r[6] = aX;
        r[7] = aY;
        r[8] = aZ;
      } else if (r.length === 16) {
        r[0] = hX;
        r[1] = hY;
        r[2] = hZ;
        r[3] = 0;
        r[4] = mX;
        r[5] = mY;
        r[6] = mZ;
        r[7] = 0;
        r[8] = aX;
        r[9] = aY;
        r[10] = aZ;
        r[11] = 0;
        r[12] = 0;
        r[13] = 0;
        r[14] = 0;
        r[15] = 1;
      }
    }
    if (i) {
      // compute the inclination matrix by projecting the geomagnetic
      // vector onto the Z (gravity) and X (horizontal component
      // of geomagnetic vector) axes.
      const invE = 1.0 / Math.sqrt(eX * eX + eY * eY + eZ * eZ);
      const c = (eX * mX + eY * mY + eZ * mZ) * invE;
      const s = (eX * aX + eY * aY + eZ * aZ) * invE;
      if (i.length === 9) {
        i[0] = 1;
        i[1] = 0;
        i[2] = 0;
        i[3] = 0;
        i[4] = c;
        i[5] = s;
        i[6] = 0;
        i[7] = -s;
        i[8] = c;
      } else if (i.length === 16) {
        i[0] = 1;
        i[1] = 0;
        i[2] = 0;
        i[4] = 0;
        i[5] = c;
        i[6] = s;
        i[8] = 0;
        i[9] = -s;
        i[10] = c;
        i[3] = i[7] = i[11] = i[12] = i[13] = i[14] = 0;
        i[15] = 1;
      }
    }
    return true;
  }

  static convertAccelerometer(ax: number, ay: number, az: number): number[] {
    let g2 = Math.sqrt(az * az + ay * ay + ax * ax);

    let cos2 = az / g2;
    cos2 = Math.max(-1, cos2);
    cos2 = Math.min(1, cos2);

    let rad2 = Math.acos(cos2);

    let value0 = MathConstant.DEGREE_180 * Math.atan2(ax, ay) / Math.PI;
    let value1 = MathUtil.rad2Deg(rad2);

    if (value0 < 0) {
      value0 += MathConstant.DEGREE_360;
    }
    let value2 = MathConstant.DEGREE_180 * Math.asin(ax / g2) / Math.PI;
    let value3 = MathConstant.DEGREE_180 * Math.asin(ay / g2) / Math.PI;

    return [value0, value1, value2, value3];
  }

  /**
   * 旋转矢量传感器数据转化为方向
   * @param srcData
   * @returns
   */
  static rotationVectorConvertToOrientation(data: sensor.RotationVectorResponse, newData: number[]): number[] {
    if (!data) {
      return [0, 0, 0];
    }
    if (!newData) {
      newData = [0, 0, 0];
    }
    let aw = data.x;
    let ax = data.y;
    let ay = data.z;
    let az = data.w;
    let squareY = ay * ay;
    let radX = Math.atan2(2 * (aw * ax + az * ay), 1 - 2 * (ax * ax + squareY));
    let radY = Math.asin(2 * (aw * ay - az * ax));
    let radZ = Math.atan2(2 * (aw * az + ax * ay), 1 - 2 * (az * az + squareY));

    newData[0] = MathUtil.convert180To360Float(MathUtil.rad2Deg(radX));
    newData[1] = MathUtil.convert180To360Float(MathUtil.rad2Deg(radY));
    newData[2] = MathUtil.convert180To360Float(MathUtil.rad2Deg(radZ));
    return newData;
  }

  static convertToOrientationInt(values: number[], targetValues: number[]): number[] {
    if (!targetValues) {
      targetValues = [0, 0, 0];
    }
    if (values != null && values.length >= 3) {
      targetValues[0] = MathUtil.scaleFloatToInt(values[0]);
      targetValues[1] = MathUtil.scaleFloatToInt(values[1]);
      targetValues[2] = MathUtil.scaleFloatToInt(values[2]);
    }
    return targetValues;
  }

  static scaleFloatToInt(value: number): number {
    let result: number;
    let intCarry = 0.5;
    let floorValue = Math.floor(value);
    if (Math.abs(value - floorValue) < intCarry) {
      result = Math.floor(value);
    } else {
      if (value < 0) {
        result = floorValue - 1;
      } else {
        result = floorValue + 1;
      }
    }
    return result;
  }

  static convert180To360Float(value: number): number {
    let result: number;
    if (value <= MathConstant.DEGREE_ZERO) {
      result = -value;
    } else {
      result = MathConstant.DEGREE_360 - value;
    }
    return result;
  }

  static getRotationOffset(origin: number, windowOrientation: window.Orientation, deviceType: DeviceType | string,
    dataTag: string): number {
    const displayCollapsStatus = CollapsChangeService.getInstance().getCurCollapsStatus();
    if ((displayCollapsStatus === display.CollapsStatus.COLLAPS_STATUS_COLLAPSED_WITH_SECOND_EXPANDED &&
      DisplayService.getInstance().getCollapsDisplayMode() === display.CollapsDisplayMode.COLLAPS_DISPLAY_MODE_MAIN)) {
      return origin + MathConstant.DEGREE_180;
    }
    let target;
    if (displayCollapsStatus === display.CollapsStatus.COLLAPS_STATUS_EXPANDED_WITH_SECOND_EXPANDED) {
      switch (windowOrientation) {
        case window.Orientation.PORTRAIT:
          target = origin + MathConstant.DEGREE_90;
          break;
        case window.Orientation.LANDSCAPE:
          target = origin + MathConstant.DEGREE_180;
          break;
        case window.Orientation.PORTRAIT_INVERTED:
          target = origin;
          break;
        default:
          target = origin;
          break;
      }
      return target;
    }

    if (deviceType === DeviceType.PHONE) {
      switch (windowOrientation) {
        case window.Orientation.PORTRAIT:
          target = origin + MathConstant.DEGREE_90;
          break;
        case window.Orientation.LANDSCAPE:
          target = origin + MathConstant.DEGREE_180;
          break;
        case window.Orientation.PORTRAIT_INVERTED:
          target = origin - MathConstant.DEGREE_90;
          break;
        default:
          target = origin;
          break;
      }
    }
    if (deviceType === DeviceType.TABLET) {
      //TODO need to fix(当前平板分屏横屏切换后不触发回调，目前先每次读取屏幕方向配置)
      let tabletOrientation: window.Orientation = DisplayService.getInstance().getDisplay().orientation;
      switch (tabletOrientation) {
        case window.Orientation.PORTRAIT:
          target = origin - MathConstant.DEGREE_90;
          break;
        case window.Orientation.LANDSCAPE:
          target = origin + MathConstant.DEGREE_180;
          break;
        case window.Orientation.PORTRAIT_INVERTED:
          target = origin + MathConstant.DEGREE_90;
          break;
        default:
          target = origin;
          break;
      }
    }
    return target;
  }

  static getMedian(floatValues: number[]): number {
    if (!floatValues) {
      return 0;
    }
    let length = floatValues.length;
    let tmps = new number[](length);
    StdLibUtil.assign(tmps, floatValues);
    tmps.sort();
    let result = tmps[length / 2];
    if (result === undefined) {
      return 0;
    }
    return result;
  }

  /**
   * 弧度转角度
   * @param degree
   * @returns
   */
  static rad2Deg(degree: number): number {
    return degree * MathConstant.DEGREE_180 / Math.PI;
  }

  // 水平
  static getLevelDegree(degreeY: number): number {
    return degreeY < MathConstant.DEGREE_THREE ? MathConstant.DEGREE_ZERO : degreeY;
  }

  static formatNumber(value: number): string {
    return Number(value.toFixed(1)).toLocaleString();
  }

  static isLevelUpAngle(angle: number): boolean {
    return angle >= MathConstant.LEVEL_UP_ANGLE_START;
  }

  static shallowCopyNum(targetArr: number[], sourceArr: number[]): void {
    for (let index in sourceArr) {
      targetArr[index] = sourceArr[index];
    }
  }
}
