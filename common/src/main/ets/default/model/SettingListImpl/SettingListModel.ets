/**
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

import BaseConfModel from '../../model/common/BaseConfModel.ets'
/**
 * @file app setting homepage service class
 */

const FILE_URI = '/data/accounts/account_0/applications/com.ohos.camera'
+ '/com.ohos.camera/assets/tablet/resources/rawfile/';

export class SettingListModel {
  constructor() {
  }

  setSettingDetialListener() {
    console.info('settings SettingListModel start');
    BaseConfModel.getJsonDataBase(FILE_URI.concat('settingdetaillist.json'), baseData => {
      console.info(`settings SettingListModel getAbilityInfoListener getJsonDataBase: ${JSON.stringify(baseData)}`)
      let settingsDetailList = this.setTitleDetailValue(baseData);
      AppStorage.SetOrCreate('settingsDetailList', settingsDetailList);
      console.info('settings SettingListModel end');
    });
  }

  async setSettingListener() {
    console.info('settings SettingListModel start');
    BaseConfModel.getJsonDataBase(FILE_URI.concat('settingdetaillist.json'), baseData => {
      console.info(`settings SettingListModel getAbilityInfoListener getJsonDataBase: ${JSON.stringify(baseData)}`)
      let settingsList = this.setTitleValue(baseData);
      AppStorage.SetOrCreate('settingsList', settingsList);
      console.info('settings SettingListModel end');
    });
  }

  setTitleDetailValue(settingsDetailList) {
    console.info("setTitleValue start")
    for (let key in settingsDetailList) {
      let settingAlias = settingsDetailList[key].settingAlias;
      console.info(`settingAlias ${settingAlias}`)
      console.info(`key = ${key}`)
      let value;

      if ('photoScale' === settingAlias || 'Aspect ratio' === settingAlias) {
        value = $r('app.string.aspect_ratio')

      } else if ('videoResolution' === settingAlias || 'Video resolution' === settingAlias) {
        value = $r('app.string.video_resolution');

      } else if ('dateAndTimeTab' === settingAlias) {

      } else {
        value = ""
      }
      settingsDetailList[key].settingTitle = value;
    }
    console.info(`settings setTitleValue end ==: ${JSON.stringify(settingsDetailList)}`);
    return settingsDetailList;
  }

  setTitleValue(settingsList) {
    for (let index = 0; index < settingsList.length; index++) {
      if (settingsList[index].subtitle === 'PHOTO') {
        settingsList[index].subtitle = $r('app.string.photo_mode')
      } else if (settingsList[index].subtitle === 'VIDEO') {
        settingsList[index].subtitle = $r('app.string.video_mode')
      }
      for (let pro = 0; pro < settingsList[index].length; pro++) {
        if (settingsList[index][pro].settingName === 'Aspect ratio') {
          settingsList[index][pro].settingName = $r('app.string.aspect_ratio')
        } else if (settingsList[index][pro].settingName === 'Video resolution') {
          settingsList[index][pro].settingName = $r('app.string.video_resolution')
        }
      }
    }
    console.info(`settings setTitleValue ==: ${JSON.stringify(settingsList)}`);
    return settingsList;
  }

}

let settingListModel = new SettingListModel();

export default settingListModel as SettingListModel;