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
import lazy { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { RenderType } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderType';
import lazy { UiElement } from '@ohos/common/src/main/ets/function/core/UiElement';
import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { PropTag, PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import abilityAccessCtrl, { PermissionRequestResult, Permissions } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { LocationManager } from '@ohos/common/src/main/ets/service/location/LocationManager';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { GeoPermissionScene } from '@ohos/common/src/main/ets/utils/GeoPermissionFrom';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { execDispatch } from '@ohos/common/src/main/ets/redux';
import lazy { SettingsValueUtil } from '@ohos/common/src/main/ets/utils/SettingsValueUtil';
import { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';

const TAG = 'SaveGeoLocationFunction';
const PERMISSION_LIST: Permissions[] = [
  'ohos.permission.APPROXIMATELY_LOCATION',
  'ohos.permission.LOCATION'
];
const bundleName: string = 'com.ohos.camera';

// 用户授权地理位置信息
export class SaveGeoLocationFunction extends BaseFunction {
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.SETTING_MENU_COMMON];
  private tokenID: number = 0;
  private locationSwitch: boolean | undefined = undefined;

  constructor() {
    super();
  }

  getFunctionId(): FunctionId {
    return FunctionId.SAVE_GEO_LOCATION;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.TOGGLE_SETTING_ITEM;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getUiElements(): Map<string, UiElement> {
    let desc: Resource = $r('app.string.location_permission_description_without_starry_sky');
    if (GlobalContext.get().getObject('isSecurityCamera')) {
      desc = $r('app.string.secure_camera_location_disabled_info');
    }

    let uiElements: Map<string, UiElement> = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement()
      .setTitle($r('app.string.setting_menu_location_title'))
      .setDesc(desc)
      .setIcon($r('app.media.ic_camera_setting_location'))
      .setAccessibilityTitle($r('app.string.setting_menu_location_title')));
    return uiElements;
  }

  getDefaultValue(): boolean {
    return false;
  }

  async setValue(value: boolean): Promise<void> {
    HiLog.i(TAG, `setValue value: ${value}.`);
    if (value === this.getValue()) {
      return;
    }
    if (value) {
      this.locationSwitch = value;
      await this.checkPermissionOrToSetting();

    } else {
      this.setLocationSwitch(false);
    }
  }

  private async checkPermissionOrToSetting(): Promise<void> {
    HiLog.i(TAG, 'checkPermissionOrToSetting begin.');
    let isSuccess: boolean = await this.checkAccessTokenSync();
    HiLog.i(TAG, 'checkPermissionOrToSetting:' + isSuccess);
    if (!isSuccess) {
      this.mStoreManager.postMessage(Action.confirmLocationTOSettingPermission(false));
      return;
    }
    this.setLocationSwitch(isSuccess);
    HiLog.i(TAG, 'checkPermissionOrToSetting end.');
  }

  public async checkAccessTokenSync(): Promise<boolean> {
    if (!this.tokenID) {
      this.tokenID = bundleManager.getApplicationInfoSync(bundleName,
        bundleManager.ApplicationFlag.GET_APPLICATION_INFO_DEFAULT).accessTokenId;
    }
    const grantStatus =
      await abilityAccessCtrl.createAtManager().checkAccessTokenSync(this.tokenID, PERMISSION_LIST[0]);
    let isSuccess: boolean = grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    return isSuccess;
  }

  // 查询相机地理位置信息权限
  private async enableWithPermission(): Promise<void> {
    HiLog.i(TAG, 'CAMERA_LOCATION PERMISSION for camera check begin.');
    // 双升单后第一次打开相机需要直接校验权限并根据持久化文件中对应项的值决定是否打开设置项地理位置开关
    let firstStartedAfterDoubleUpgradeToSingle: boolean =
      PreferencesService.getInstance().getPropValue(PersistType.FOREVER, PropTag.FIRST_START_AFTER_DOUBLE_TO_SINGLE_OTA,
        false) as boolean;
    const references: PreferencesService = PreferencesService.getInstance();
    if (!(references.getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean) &&
      !firstStartedAfterDoubleUpgradeToSingle) {
      HiLog.w(TAG, 'enableWithPermission Request location permission return, currently on the privacy intro page.');
      return;
    }
    if (!(references.getPublicValue(PersistType.FOREVER, PublicTag.IS_GUIDANCE_LOADED, false) as boolean) &&
      !firstStartedAfterDoubleUpgradeToSingle) {
      HiLog.w(TAG, 'enableWithPermission Request location permission return, currently on the guide page.');
      return;
    }
    if (!(references.getPublicValue(PersistType.FOREVER, PublicTag.IS_REQUEST_LOCATION_DIALOG_LOADED,
      false) as boolean) && !firstStartedAfterDoubleUpgradeToSingle) {
      HiLog.w(TAG, 'enableWithPermission Request location permission return, location dialog disagree.');
      return;
    }
    if (firstStartedAfterDoubleUpgradeToSingle) {
      PreferencesService.getInstance().putPropValue(PersistType.FOREVER, PropTag.FIRST_START_AFTER_DOUBLE_TO_SINGLE_OTA,
        false);
    }
    let isSuccess: boolean = await this.checkAccessTokenSync();
    HiLog.i(TAG, 'checkAccessTokenSync isSuccess:' + isSuccess);
    AppStorage.setOrCreate('checkAccessTokenIsSuccess', isSuccess);
    if (this.getValue()) {
      this.setLocationSwitch(isSuccess);
      StoreManager.getInstance().postMessage(FunctionAction.changeFunctionValue(this.getFunctionId(), isSuccess));
    }
  }

  /* instrument ignore next */
  private async requestPermissionsFromUser(fromModul?: number, isPhotoRequest?: boolean): Promise<void> {
    AppStorage.setOrCreate('isPermissionShow', true);
    const results: PermissionRequestResult = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(
      ContextManager.getInstance().getContextWithToken(), PERMISSION_LIST);
    let isSuccess: boolean = results.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    let isSuccessPrecisely: boolean = results.authResults[1] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    HiLog.i(TAG, `CAMERA_LOCATION PERMISSION for camera check end, isSuccess: ${isSuccess},
      isSuccessPrecisely: ${isSuccessPrecisely}, fromModul: ${fromModul}.`);
    StoreManager.getInstance().postMessage(Action.sendPermissionState(isSuccess));
    AppStorage.setOrCreate('isRequestedPermission', true);
    PreferencesService.getInstance().putPropValue(PersistType.FOREVER, PropTag.IS_REQUESTED_PERMISSION, true);
    this.setLocationSwitch(isSuccess, 0, isPhotoRequest);
    AppStorage.setOrCreate('isPermissionShow', false);
    this.updateGeoFunctionValue(isSuccess, fromModul);
  }

  private updateGeoFunctionValue(isSuccess: boolean, fromModul?: number): void {
    StoreManager.getInstance().postMessage(FunctionAction.changeFunctionValue(this.getFunctionId(), isSuccess));
  }

  // 弹出设置半模态权限弹窗
  /* instrument ignore next */
  private async requestPermissionOnSetting(data: { isRequestOnSetting: boolean, scene?: number, isPhotoRequest?: boolean }): Promise<void> {
    if (AppStorage.get('isLemCollaps')) {
      HiLog.w(TAG, 'requestPermissionOnSetting return, sub screen.');
      return;
    }
    HiLog.i(TAG, `requestPermissionOnSetting begin isRequestOnSetting:${data?.isRequestOnSetting}
      fromModul:${data?.scene}.`);
    if (data?.isRequestOnSetting) {
      try {
        let result: abilityAccessCtrl.GrantStatus[] =
          await abilityAccessCtrl.createAtManager()
            .requestPermissionOnSetting(ContextManager.getInstance().getContextWithToken(), PERMISSION_LIST);
        const isSuccess: boolean = result[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
        HiLog.i(TAG, `requestPermissionOnSetting isSuccess: ${isSuccess}`);
        StoreManager.getInstance().postMessage(Action.sendPermissionState(isSuccess));
        if (isSuccess) {
          this.setLocationSwitch(true, data?.scene, data?.isPhotoRequest);
        } else {
          StoreManager.getInstance().postMessage(FunctionAction.changeFunctionValue(this.getFunctionId(), false));
        }
      } catch (err) {
        HiLog.e(TAG, `requestPermissionOnSetting catch err code: ${err?.code}`);
        this.requestPermissionsFromUser(data?.scene, data?.isPhotoRequest);
      }
    }
    HiLog.i(TAG, `requestPermissionOnSetting end.}`);
  }

  // 设置地理位置开关
  private setLocationSwitch(value: boolean, fromModul?: number, isPhotoRequest?: boolean): void {
    HiLog.i(TAG, `set locaton switch value: ${value}, isPhotoRequest: ${isPhotoRequest}`);
    this.locationSwitch = value;
    this.persistValue(value);
    // 提供给图库应用调用相机位置授权卡片时使用，'0'代表未授权，'1'代表已授权
    let switchValue = value ? '1' : '0';
    SettingsValueUtil.setValueSync('camera_location_switch', switchValue);
    if (!isPhotoRequest) {
      LocationManager.getInstance().setLocationSwitch(value);
    }
  }

  getValue(): boolean {
    if (!this.locationSwitch) {
      this.locationSwitch = <boolean> this.getPersistedValue();
      HiLog.i(TAG, 'locationSwitch: ' + this.locationSwitch);
      let settingSwitchValue = SettingsValueUtil.getValueSync('camera_location_switch', 'undefined');
      HiLog.i(TAG, 'settingSwitchValue is:' + settingSwitchValue);
      if (settingSwitchValue === 'undefined') {
        // 升级克隆等场景，从没有settings值的版本升级到带settings版本，开关值使用Preferences处理，仅更新settings值，和Preferences保持一致
        SettingsValueUtil.setValueSync('camera_location_switch', this.locationSwitch ? '1' : '0');
      } else {
        let isOpen = settingSwitchValue === '1';
        if (this.locationSwitch !== isOpen) {
          // 桌面相机进程存在时，通过UIExtension改变Preferences开关值，桌面相机拿不到，得优先使用settings获取，并同步更新Preferences开关值
          this.persistValue(isOpen);
          this.locationSwitch = isOpen;
        }
      }
    }
    return this.locationSwitch;
  }

  isAvailable(): boolean {
    const isPicker: boolean = GlobalContext.get().getIsPicker();
    HiLog.i(TAG, `isAvailable isPicker ${isPicker}`);
    return !isPicker && !DeviceInfo.isPc();
  }

  load(renderLocations: RenderLocation[]): void {
    HiLog.i(TAG, 'load E.');
    super.load(renderLocations);

    this.mEventBus.on(ActionType.ACTION_IS_REQUEST_PERMISSION, this.requestLocationPermission.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LOCATION_PERMISSION_TO_SETTING, this.requestPermissionOnSetting.bind(this),
      this.mBase.hashCode());
    // 每次进前台、窗口获焦，都判断权限设置地理位置
    this.mEventBus.on([ContextActionType.ABILITY_ON_FOREGROUND, ContextActionType.ABILITY_ACTIVE], async () => {
      HiLog.i(TAG, 'onForeground check access token begin.');
      await this.enableWithPermission();
      HiLog.i(TAG, 'onForeground check access token end.');
    }, this.mBase.hashCode());
    // 退后台要关闭地理位置
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, () => {
      LocationManager.getInstance().setLocationSwitch(false);
    }, this.mBase.hashCode());
    HiLog.i(TAG, 'load x.');
  }

  unload(renderLocations: RenderLocation[]): void {
    HiLog.i(TAG, 'unload E.');
    super.unload(renderLocations);
    this.mEventBus.clear(this.mBase.hashCode());
    LocationManager.getInstance().setLocationSwitch(false);
    HiLog.i(TAG, 'unload X.');
  }

  // 每次硬启动会弹出地理位置弹窗
  private async requestLocationPermission(): Promise<void> {
    if (AppStorage.get('isLemCollaps')) {
      HiLog.w(TAG, 'requestLocationPermission return, sub screen.');
      return;
    }
    HiLog.i(TAG, 'requestLocationPermission begin.');
    const references: PreferencesService = PreferencesService.getInstance();
    if (references.getPropValue(PersistType.FOREVER, PropTag.IS_REQUESTED_PERMISSION, false) as boolean) {
      HiLog.w(TAG, 'Request location permission return, permission pop-up window has already popped up.');
      return;
    }
    if (!(references.getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean)) {
      HiLog.w(TAG, 'Request location permission return, currently on the privacy intro page.');
      return;
    }
    /* instrument ignore if */
    if (!DeviceInfo.isPc() &&
      !(references.getPublicValue(PersistType.FOREVER, PublicTag.IS_GUIDANCE_LOADED, false) as boolean)) {
      HiLog.w(TAG, 'Request location permission return, currently on the guide page.');
      return;
    }
    HiLog.i(TAG, 'requestLocationPermission from user start');
    let results: PermissionRequestResult = undefined;
    try {
      AppStorage.setOrCreate('isPermissionShow', true);
      results = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(
        ContextManager.getInstance().getContextWithToken(), PERMISSION_LIST);
    } catch (err) {
      HiLog.e(TAG, `requestLocationPermission catch err code: ${err?.code}`);
      this.setLocationSwitch(false);
      return;
    } finally {
      AppStorage.setOrCreate('isPermissionShow', false);
      references.putPropValue(PersistType.FOREVER, PropTag.IS_REQUESTED_PERMISSION, true);
      AppStorage.setOrCreate('isRequestedPermission', true);
      AppStorage.setOrCreate('isIntroLoaded', true);
    }
    /* instrument ignore if */
    if (results?.authResults.length >= 2) { //大约位置results.authResults[0], 精确位置results.authResults[1]
      HiLog.i(TAG,
        `requestLocationPermission approximatelyResult: ${results.authResults[0]}, Result: ${results.authResults[1]}`);
      this.setLocationSwitch(results.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
    }
    HiLog.i(TAG, 'requestLocationPermission end.');
  }
}