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
import lazy { abilityAccessCtrl, bundleManager, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';

/* instrument ignore file */
const TAG: 'GeoLocationService' = 'GeoLocationService';

const BUNDLE_NAME: string = 'com.ohos.camera';
const PERMISSION_LIST: Array<Permissions> = [
  'ohos.permission.APPROXIMATELY_LOCATION',
  'ohos.permission.LOCATION'
];

export class GeoLocationService {
  static instance: GeoLocationService;
  private appToken: number = 0;
  private permissionCallback: (isSuccess?: boolean) => void = (isSuccess) => {};

  constructor() {
  }

  static getInstance(): GeoLocationService {
    if (!this.instance) {
      this.instance = new GeoLocationService();
    }
    return this.instance;
  }

  // 校验地址位置权限
  public async checkLocationPermission(): Promise<boolean> {
    if (!this.appToken) {
      this.appToken = bundleManager.getApplicationInfoSync(BUNDLE_NAME,
        bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT).accessTokenId;
    }
    let grantStatus: abilityAccessCtrl.GrantStatus;
    try {
      grantStatus = await abilityAccessCtrl.createAtManager().checkAccessTokenSync(this.appToken, PERMISSION_LIST[0]);
    } catch (error) {
      HiLog.i(TAG, `checkLocationPermission message: ${error.message}`);
    }

    const isSuccess: boolean = grantStatus === abilityAccessCtrl?.GrantStatus?.PERMISSION_GRANTED;
    HiLog.i(TAG, `checkLocationPermission isSuccess: ${isSuccess}`);
    return isSuccess;
  }

  // 引导授权
  public async checkAndOpenGeoLocation(permissionCallback: (isSuccess?: boolean) => void): Promise<void> {
    const isSuccess: boolean = await this.checkLocationPermission();;
    HiLog.i(TAG, `checkAndOpenGeoLocation isSuccess: ${isSuccess}`);
    if (!isSuccess) {
      // 拉起引导授权框
      EventBusManager.getInstance().getEventBus().emit(ActionType.ACTION_LOCATION_GUIDED_AUTHORIZATION, []);
      this.permissionCallback = permissionCallback;
    } else {
      permissionCallback(true);
      this.permissionCallback = null;
    }
  }

  private async requestPermissionsFromUser(): Promise<boolean> {
    let result: PermissionRequestResult = {} as PermissionRequestResult;
    try {
      result = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(
        ContextManager.getInstance().getContextWithToken(), PERMISSION_LIST);
    } catch (error) {
      HiLog.i(TAG, `requestPermissionDialog message: ${error.message}`);
    }
    const isSuccess: boolean = result?.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    const isSuccessPrecisely: boolean = result?.authResults[1] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    HiLog.i(TAG, `requestPermissionsFromUser, isSuccess: ${isSuccess}, isSuccessPrecisely: ${isSuccessPrecisely}.`);

    return isSuccess;
}

  // 拉起授权模态框
  public async requestPermissionDialog(isRequest: boolean): Promise<void> {
    let isSuccess: boolean = false;
    if (isRequest) {
      let result: abilityAccessCtrl.GrantStatus[] = [];
      try {
        result = await abilityAccessCtrl.createAtManager().requestPermissionOnSetting(
          ContextManager.getInstance().getContextWithToken(), PERMISSION_LIST);
        isSuccess = result[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      } catch (error) {
        HiLog.i(TAG, `requestPermissionDialog message: ${error.message}`);
        isSuccess = await this.requestPermissionsFromUser();
      }

      HiLog.i(TAG, `requestPermissionDialog isSuccess: ${isSuccess}`);
    }
    this.permissionCallback(isSuccess);
    this.permissionCallback = null;
  }
}