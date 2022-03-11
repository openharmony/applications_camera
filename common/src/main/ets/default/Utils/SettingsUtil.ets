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

import RdbStoreManager from './RdbStoreManager.ets'
import SettingItemInfo from './SettingItemInfo.ets'

export class SettingsUtil {
  public photoValue: any = '4:3'
  public videoValue: any = '[16:9] 720p'
  private rdbStoreManager: RdbStoreManager = RdbStoreManager.getInstance()

  public static getInstance(): SettingsUtil {
    if (!AppStorage.Has('app_key_settings_util')) {
      AppStorage.SetOrCreate('app_key_settings_util', new SettingsUtil())
      console.info('build new SettingsUtil.')
    }
    return AppStorage.Get('app_key_settings_util');
  }

  public async setSettingValue(settingAlias, itemValue) {
    console.info('SettingsUtil.setSettingValue settingAlias: ' + settingAlias)
    console.info('SettingsUtil.setSettingValue itemValue: ' + itemValue)
    let settingItemInfo: SettingItemInfo = new SettingItemInfo();
    settingItemInfo.itemName = settingAlias;
    settingItemInfo.itemValue = itemValue;
    await this.rdbStoreManager.updateValue(settingItemInfo)
  }

  public async getSettingValue(settingAlias) {
    console.info('SettingsUtil.getSettingValue settingAlias: ' + settingAlias)
    let resultList: SettingItemInfo[] = await this.rdbStoreManager.getSettingByItem(settingAlias)
    console.info('SettingsUtil.getSettingValue resultList: ' + JSON.stringify(resultList))
    if (resultList.length == 0) {
      console.info('SettingsUtil.getSettingValue none.')
      return settingAlias == 'Aspect ratio' ? '4:3' : '[16:9] 720p'
    } else {
      for (let i = 0; i < resultList.length; i++) {
        console.info('SettingsUtil.getSettingValue' + i + ': ' + resultList[i].itemValue)
      }
    }
    return resultList[0].itemValue
  }
}