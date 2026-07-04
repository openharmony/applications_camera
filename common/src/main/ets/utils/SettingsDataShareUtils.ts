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
import lazy { dataShare, dataSharePredicates, DataShareResultSet, ValuesBucket } from '@kit.ArkData';
import lazy { HiLog } from './HiLog';
import lazy { ContextManager } from '../service/context/ContextManager';

const TAG = 'SettingsDataShareUtils';

export enum DataUriType {
  SETTING_GLOBAL_URI = 0,
  SETTING_SYSTEM_URI,
  SETTING_SECURE_URI,
  CUSTOM_COLOR_STYLES
}

export class SettingsDataShareUtils {
  private static SETTING_COLUMN_KEYWORD = 'KEYWORD';
  private static SETTING_COLUMN_VALUE = 'VALUE';
  private static dataUriMap: Map<DataUriType, string> = new Map<DataUriType, string>([
    [DataUriType.SETTING_GLOBAL_URI,
      'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true&key='],
    [DataUriType.SETTING_SYSTEM_URI,
      'datashare:///com.ohos.settingsdata/entry/settingsdata/USER_SETTINGSDATA_100?Proxy=true&key='],
    [DataUriType.SETTING_SECURE_URI,
      'datashare:///com.ohos.settingsdata/entry/settingsdata/USER_SETTINGSDATA_SECURE_100?Proxy=true&key='],
    [DataUriType.CUSTOM_COLOR_STYLES,
    'datashare:///com.ohos.camera/data?Proxy=true&key='],
  ]);
  public static ENABLE_SCREEN_READER_KEY = 'accessibility_screenreader_enabled';
  public static CUSTOM_COLOR_STYLES = `custom_color_styles`;

  public static getSettingsUri(dataUri: DataUriType, key: string, needKey: boolean = true): string {
    if (!key && needKey) {
      HiLog.e(TAG, 'getSettingsUri key empty!');
      return '';
    }
    if (!SettingsDataShareUtils.dataUriMap.has(dataUri)) {
      HiLog.e(TAG, 'getSettingsUri dataUri invalid!');
      return '';
    }
    return SettingsDataShareUtils.dataUriMap.get(dataUri) + key;
  }

// 测试在是否锁定情况下ui方向是否稳定，看屏幕朗读功能是否正常
  public static createDataHelper(uri: string): Promise<dataShare.DataShareHelper> | undefined {
    if (!uri) {
      HiLog.e(TAG, 'createDataHelper uri invalid');
      return undefined;
    }
    return dataShare.createDataShareHelper(ContextManager.getInstance().getContextWithToken(), uri);
  }

  private static async getStringValue(dataUri: DataUriType, key: string, defaultValue: string): Promise<string> {
    let resultValue: string = defaultValue;
    let queryColumns: string[] = [SettingsDataShareUtils.SETTING_COLUMN_VALUE];
    let uri: string = SettingsDataShareUtils.getSettingsUri(dataUri, key);
    if (!uri) {
      HiLog.e(TAG, 'getStringValue uri empty!');
      return resultValue;
    }
    let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(SettingsDataShareUtils.SETTING_COLUMN_KEYWORD, key);
    let dataHelper: dataShare.DataShareHelper =
      await (SettingsDataShareUtils.createDataHelper(uri) as Promise<dataShare.DataShareHelper>);

    let data: DataShareResultSet = await dataHelper.query(uri, predicates, queryColumns);
    if (data?.rowCount <= 0) {
      HiLog.e(TAG, 'dataHelper query result is empty!');
    } else {
      data?.goToFirstRow();
      resultValue = data?.getString(0);
    }
    data?.close();
    HiLog.i(TAG, 'dataHelper query result:' + resultValue);
    return resultValue;
  }

  // 提供直接获取settingsdata布尔类型数据
  public static async getBoolValue(dataUri: DataUriType, key: string, defaultValue: boolean): Promise<boolean> {
    let resultValue: boolean = defaultValue;
    let valueStr: string = await SettingsDataShareUtils.getStringValue(dataUri, key, '');
    if (valueStr !== '') {
      resultValue = (valueStr === '1' || valueStr === 'true');
    }
    return resultValue;
  }

// 提供settingsdata的数据变更监听回调
  public static registerDataChange(dataHelper: dataShare.DataShareHelper, uri: string, onDataChange: () => void): void {
    if (!dataHelper || !onDataChange) {
      HiLog.w(TAG, 'registerDataChange params invalid');
      return;
    }
    if (!uri) {
      HiLog.e(TAG, 'registerDataChange uri invalid');
      return;
    }
    dataHelper.on('dataChange', uri, onDataChange);
  }

  public static unRegisterDataChange(dataHelper: dataShare.DataShareHelper, uri: string): void {
    if (!dataHelper) {
      HiLog.w(TAG, 'unRegisterDataChange params invalid');
      return;
    }
    if (!uri) {
      HiLog.w(TAG, 'unRegisterDataChange uri invalid');
      return;
    }
    dataHelper.off('dataChange', uri);
  }
}