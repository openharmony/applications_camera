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

import deviceInfo from '@ohos.deviceInfo';
import { HiLog } from '../../utils/HiLog';

const TAG = 'DeviceInfo';

export class DeviceInfo {
  private static readonly DEVICE_TYPE: string = deviceInfo.deviceType;
  private static readonly PRODUCT_SERIES: string = deviceInfo.productSeries;
  private static readonly PRODUCT_MODEL: string = deviceInfo.productModel;
  private static readonly CHIP_TYPE: string = deviceInfo.chipType;

  constructor() {
  }

  /**
   * Querying the Device Type
   *
   * default：智能手机  RK设备
   * phone: 智能手机  非RK设备
   * tablet：平板
   * tv：智慧屏
   * wearable：智能穿戴
   * liteWearable：轻量级智能穿戴
   * smartVision：智慧视觉设备
   * 2in1：平板
   */
  static getDeviceType(): string {
    return <string> this.DEVICE_TYPE;
  }

  /**
   * Querying the productSeries
   *
   * HYM：PC设备
   */
  static getProductSeries(): string {
    return <string> this.PRODUCT_SERIES;
  }

  /**
   * Querying the productModel
   */
  static getProductModel(): string {
    return <string> this.PRODUCT_MODEL;
  }

  // wgr也走isTablet
  static isTablet(): boolean {
    let deviceType = DeviceInfo.getDeviceType();
    return deviceType === 'tablet';
  }

  // 当前代表PC，特指klv
  static is2in1(): boolean {
    let deviceType = DeviceInfo.getDeviceType();
    return deviceType === '2in1';
  }

  // RK
  static isDefault(): boolean {
    let deviceType = DeviceInfo.getDeviceType();
    return deviceType === 'default';
  }

  // TODO 开发板 default
  static isPhone(): boolean {
    let deviceType = DeviceInfo.getDeviceType();
    return deviceType === 'phone'|| deviceType === 'default';
  }

  // 应该有专属的pc判断
  static isPc(): boolean {
    return this.is2in1();
  }

  static isTv(): boolean {
    let deviceType = DeviceInfo.getDeviceType();
    return deviceType === 'tv';
  }

  // 项目中存在pc和平板共走的逻辑
  static isPcAndTablet(): boolean {
    return this.isPc() || this.isTablet();
  }

  static getChipType():string {
    return <string> this.CHIP_TYPE;
  }

  static isRk3568(): boolean {
    return DeviceInfo.getChipType() == 'rk3568';
  }

  static isUis7885() : boolean {
    return DeviceInfo.getChipType() == 'uis7885';
  }

  static isDayu300() : boolean {
    return DeviceInfo.getChipType() == 'dayu300';
  }
}