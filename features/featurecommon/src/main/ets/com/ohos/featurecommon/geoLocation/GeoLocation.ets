/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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
import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import {SettingsUtil} from '../../../../../../../../../common/src/main/ets/default/Utils/SettingsUtil'

export class GeoLocation {
  private TAG: string = '[GeoLocation]:'
  private static instance: GeoLocation
  private mLocation = undefined
  private requestInfo = {'priority': 0x203, 'scenario': 0x300, 'timeInterval': 0, 'distanceInterval': 0, 'maxAccuracy': 0}
  private locationChange = (err, location) => {
    CLog.info(`[GeoLocation]: locationChange err: ${err}`)
    if (!err) {
      CLog.info(`[GeoLocation]: locationChange: ${location}`)
      SettingsUtil.getInstance().setCurGeoLocation(location)
    }
  }

  private Constructor() {}

  public static getInstance() {
    if (!GeoLocation.instance) {
      GeoLocation.instance = new GeoLocation()
    }
    return GeoLocation.instance
  }

  public on() {
    CLog.info(`${this.TAG} on E`)
    if (!SettingsUtil.getInstance().getSaveGeoLocation()) {
      CLog.info(`${this.TAG} on geo setting off, X`)
      return
    }
    geolocation.isLocationEnabled().then((result) => {
      CLog.info(`${this.TAG} isLocationEnabled: ${result}`)
      if (result) {
        var curRequestInfo = {'priority': 0x203, 'scenario': 0x300,'maxAccuracy': 0}
        geolocation.getCurrentLocation(curRequestInfo).then((result) => {
          CLog.info(`${this.TAG} on getCurrentLocation result: ${JSON.stringify(result)}`)
          SettingsUtil.getInstance().setCurGeoLocation(result)
        })
        geolocation.on('locationChange', this.requestInfo, this.locationChange)
      }
    })
    CLog.info(`${this.TAG} on X`)
  }

  public off() {
    CLog.info(`${this.TAG} off E`)
    if (!SettingsUtil.getInstance().getSaveGeoLocation()) {
      CLog.info(`${this.TAG} off geo setting off X`)
      return
    }
    geolocation.off('locationChange', this.locationChange)
    CLog.info(`${this.TAG} off X`)
  }
}