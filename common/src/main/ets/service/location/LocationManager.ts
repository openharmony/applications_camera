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
/* instrument ignore file */
import lazy { HiLog } from '../../utils/HiLog';
import lazy geolocation from '@ohos.geoLocationManager';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { LocationMessage, LocationType } from './LocationMessage';
import lazy { CameraProxy } from '../../camera/uithread/CameraProxy';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import lazy { PublicTag } from '../../service/preferences/PropTag';
import { execDispatch } from '../../redux/Store';

const TAG: string = 'LocationManager';

const LOCATION_INTERVAL: number = 30000;
const LOCATION_TRIGGER_DELAY: number = 600;
const LAST_LOCATION_TIME: number = 3600000; //lastLocation超过一个小时，则舍弃

const PRECISELY_CUR_REQUEST_INFO: geolocation.CurrentLocationRequest = {
  priority: 0x201,
  scenario: 0x301,
  maxAccuracy: 0,
  timeoutMs: 5000
};
const FAST_CUR_REQUEST_INFO: geolocation.CurrentLocationRequest = { priority: 0x203, scenario: 0x300, maxAccuracy: 0 };

export class LocationManager {
  private static sInstance: LocationManager;
  // 权限开关
  private systemEnabled: boolean = false;
  private locationSwitcher: boolean = false;

  private constructor() {
    try {
      HiLog.i(TAG, 'checkSystemEnabled begin.');
      this.setSystemEnable(geolocation.isLocationEnabled());
      HiLog.i(TAG, `checkSystemEnabled end, is enabled: ${this.systemEnabled}.`);
      geolocation.on('locationEnabledChange', (state: boolean) => {
        HiLog.i(TAG, `systemEnabledChange, system location enabled: ${state}.`);
        this.setSystemEnable(state);
      });
    } catch (err) {
      HiLog.e(TAG, `enableSystemLocation error code: ${err?.code}.`);
    }
  }

  public static getInstance(): LocationManager {
    if (!LocationManager.sInstance) {
      LocationManager.sInstance = new LocationManager();
    }
    return LocationManager.sInstance;
  }

  public setLocationSwitch(switcher: boolean): void {
    if (this.locationSwitcher === switcher) {
      return;
    }
    this.locationSwitcher = switcher;
    HiLog.i(TAG, `CAMERA_LOCATION SWITCHER button: ${switcher}.`);
    this.changeLocationGetter();
  }

  private setSystemEnable(enable: boolean): void {
    if (this.systemEnabled === enable) {
      return;
    }
    this.systemEnabled = enable;
    HiLog.i(TAG, `CAMERA_LOCATION SYSTEM_ENABLED: ${this.systemEnabled}.`);
    this.changeLocationGetter();
  }

  private changeLocationGetter(): void {
    if (EnableLocation.enable === this.locationSwitcher && this.systemEnabled) {
      HiLog.i(TAG, `changeLocationGetter return, enable is same to oldState, enable: ${EnableLocation.enable}.`);
      return;
    }
    EnableLocation.enable = this.locationSwitcher && this.systemEnabled;
    HiLog.i(TAG, `changeLocationGetter enable: ${EnableLocation.enable}.`);
    if (EnableLocation.enable) {
      EnableLocation.getInstance().begin();
    } else {
      EnableLocation.getInstance().end();
    }
  }

  public getLocationCache(): LocationMessage {
    HiLog.i(TAG, 'getLocationCache begin.');
    if (DeviceInfo.isPc()) {
      HiLog.i(TAG, 'getLocationCache NO_PERMISSION.');
      return { type: LocationType.NO_PERMISSION };
    }
    if (!this.systemEnabled) {
      HiLog.i(TAG, 'getLocationCache systemEnabled: false, return null.');
      return { type: LocationType.NO_PERMISSION };
    }
    const locationSwitcher = FeatureManager.getInstance().getFunction(FunctionId.SAVE_GEO_LOCATION)?.getValue();
    if (!locationSwitcher) {
      HiLog.i(TAG, 'getLocationCache geoLocation switch: false, return null.');
      return { type: LocationType.NO_PERMISSION };
    }
    const location = EnableLocation.getInstance().getLocationCache();
    const lastLocation = EnableLocation.getInstance().getLastLocationCache();
    if (location) {
      HiLog.i(TAG, 'getLocationCache CURRENT_LOCATION.');
      return { type: LocationType.CURRENT_LOCATION, location: location };
    }
    if (lastLocation) {
      HiLog.i(TAG, 'getLocationCache LAST_LOCATION.');
      return { type: LocationType.LAST_LOCATION, location: lastLocation };
    }
    HiLog.i(TAG, 'getLocationCache FAULTY.');
    return { type: LocationType.FAULTY };
  }
}

export class EnableLocation {
  private static sInstance: EnableLocation;
  private cameraProxy: CameraProxy = CameraProxy.getInstance();
  private locationTimer: number = Number.NaN;
  private lastTime: number = Number.NaN;
  // 当前状态
  public static enable: boolean = false;
  // 位置信息
  private location: geolocation.Location | undefined;
  private lastLocation: geolocation.Location | undefined;

  private constructor() {
  }

  public static getInstance(): EnableLocation {
    if (!EnableLocation.sInstance) {
      EnableLocation.sInstance = new EnableLocation();
    }
    return EnableLocation.sInstance;
  }

  public begin(): void {
    this.getLastLocation();
    this.triggerGetLocation();
    this.startTimer();
  }

  public end(): void {
    HiLog.i(TAG, 'stop timer.');
    this.postMessage(LocationType.NO_PERMISSION);
    if (!Number.isNaN(this.locationTimer)) {
      clearInterval(this.locationTimer);
      this.locationTimer = Number.NaN;
      HiLog.i(TAG, 'stop getCurrentLocation.');
    } else {
      HiLog.i(TAG, 'getLocation timer is already not running.');
    }
  }

  private getLastLocation(): void {
    if (!!this.location) {
      HiLog.i(TAG, 'getLastLocation return, location is ready.');
      return;
    }
    try {
      if (!(PreferencesService.getInstance().getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as
        boolean)) {
        HiLog.w(TAG, 'getLastLocation return, currently on the privacy intro page.');
        return;
      }
      HiLog.begin(TAG, 'getLastLocation');
      this.lastLocation = geolocation.getLastLocation();
      HiLog.end(TAG, 'getLastLocation');
      HiLog.i(TAG, `lastLocation timeStamp: ${this.lastLocation.timeStamp}. `);
      let lastLocationIntervalTime = Date.now() - this.lastLocation.timeStamp;
      if (lastLocationIntervalTime > LAST_LOCATION_TIME) {
        HiLog.i(TAG, 'more than an hour since last location acquisition.');
        this.lastLocation = undefined;
        return;
      }
      this.postMessage(LocationType.LAST_LOCATION);
    } catch (error) {
      HiLog.e(TAG, `getLastLocation error: code: ${error.code}, message: ${error.message}.`);
      this.postMessage(LocationType.FAULTY);
    }
  }

  public getLocationCache(): geolocation.Location | undefined {
    return this.location;
  }

  public getLastLocationCache(): geolocation.Location | undefined {
    return this.lastLocation;
  }

  private triggerGetLocation(): void {
    HiLog.i(TAG, 'triggerGetLocation begin.');
    const time = Date.now();
    if (!Number.isNaN(this.lastTime) && time - this.lastTime < LOCATION_INTERVAL) {
      HiLog.w(TAG, `time: ${time}, lastTime: ${this.lastTime}, location has already get in the last 30 seconds.`);
      return;
    }
    this.getCurrentLocation(true);
    this.getCurrentLocation(false);
    HiLog.i(TAG, 'triggerGetLocation end.');
  }

  private startTimer(): void {
    HiLog.i(TAG, 'CAMERA_LOCATION START_TIMER.');
    if (Number.isNaN(this.locationTimer)) {
      this.postMessage();
      this.locationTimer = setInterval(() => this.getCurrentLocation(false), LOCATION_INTERVAL);
      HiLog.i(TAG, 'start getCurrentLocation.');
    } else {
      HiLog.i(TAG, 'getLocation timer is already running.');
    }
  }

  private async getCurrentLocation(isFirstRequest: boolean): Promise<void> {
    this.lastTime = Date.now();
    HiLog.begin(TAG, 'getCurrentLocation');
    try {
      let request = isFirstRequest ? FAST_CUR_REQUEST_INFO : PRECISELY_CUR_REQUEST_INFO;
      this.location = await geolocation.getCurrentLocation(request);
      if (!isFirstRequest) {
        let currentDuration = Date.now() - this.lastTime;
        HiLog.i(TAG, `current Duration: ${currentDuration}`);
      } else {
      }
      this.postMessage(LocationType.CURRENT_LOCATION);
    } catch (err) {
      HiLog.e(TAG, `CAMERA_LOCATION get error code: ${err?.code}.`);
    }
    HiLog.end(TAG, 'getCurrentLocation');
    if (this.lastLocation || this.location) {
      return;
    }
    this.postMessage(LocationType.FAULTY);
  }

  private postMessage(type?: LocationType): void {
    if (type === LocationType.NO_PERMISSION) {
      this.cameraProxy.changeLocation({ type: LocationType.NO_PERMISSION });
      return;
    }
    if (!EnableLocation.enable) {
      HiLog.i(TAG, `postMessage return, enable: ${EnableLocation.enable}, type: ${type}.`);
      return;
    }
    if (type === LocationType.CURRENT_LOCATION || this.location) {
      this.cameraProxy.changeLocation({
        type: LocationType.CURRENT_LOCATION,
        location: this.location
      });
      return;
    }
    if (type === LocationType.LAST_LOCATION || this.lastLocation) {
      this.cameraProxy.changeLocation({
        type: LocationType.LAST_LOCATION,
        location: this.lastLocation
      });
      return;
    }
    this.cameraProxy.changeLocation({ type: LocationType.FAULTY });
  }
}