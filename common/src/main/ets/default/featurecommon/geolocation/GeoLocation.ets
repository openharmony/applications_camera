/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import geolocation from '@ohos.geolocation';
import { Log } from '../../utils/Log'
import { SettingManager } from '../../setting/SettingManager'

export class GeoLocation {
  private TAG: string = '[GeoLocation]:'
  private static instance: GeoLocation
  private mLocation = undefined
  private requestInfo = {'priority': 0x203, 'scenario': 0x300, 'timeInterval': 0, 'distanceInterval': 0, 'maxAccuracy': 0}
  private locationChange = (location) => {//删掉参数err及相关逻辑
//    Log.info(`[GeoLocation]: locationChange err: ${err}`)
//    if (!err) {
      Log.info(`[GeoLocation]: locationChange: ${location}`)
      SettingManager.getInstance().setCurGeoLocation(location)
//    }
  }

  private Constructor() {}

  public static getInstance() {
    if (!GeoLocation.instance) {
      GeoLocation.instance = new GeoLocation()
    }
    return GeoLocation.instance
  }

  public async on() {
    Log.info(`${this.TAG} on E`)
    if (!SettingManager.getInstance().getSaveGeoLocation()) {
      Log.info(`${this.TAG} on geo setting off, X`)
      return
    }
    geolocation.isLocationEnabled().then((result) => {
      Log.info(`${this.TAG} isLocationEnabled: ${result}`)
      if (result) {
        var curRequestInfo = {'priority': 0x203, 'scenario': 0x300, 'maxAccuracy': 1000}
        geolocation.getCurrentLocation(curRequestInfo).then((result) => {
          Log.info(`${this.TAG} on getCurrentLocation result: ${JSON.stringify(result)}`)
          SettingManager.getInstance().setCurGeoLocation(result)
        }).catch((err) => {
          Log.info(`${this.TAG} on getCurrentLocation err result: ${JSON.stringify(err)}`)
        })
        geolocation.on('locationChange', this.requestInfo, this.locationChange)
      }
    })
    Log.info(`${this.TAG} on X`)
  }

  public async off() {
    Log.info(`${this.TAG} off E`)
    if (!SettingManager.getInstance().getSaveGeoLocation()) {
      Log.info(`${this.TAG} off geo setting off X`)
      return
    }
    geolocation.off('locationChange', this.locationChange)
    Log.info(`${this.TAG} off X`)
  }
}