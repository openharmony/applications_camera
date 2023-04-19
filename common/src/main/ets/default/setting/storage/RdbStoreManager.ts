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

import dataRdb from '@ohos.data.rdb';

import { Log } from '../../utils/Log'
import SettingItemInfo from './SettingItemInfo'

const DB_NAME = 'Camera.db'
const DB_VERSION = 1
const TABLE_NAME = 'SETTING'
const CREATE_TABLE = 'CREATE TABLE IF NOT EXISTS SETTING ' +
'(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
'item_name TEXT, ' +
'item_value TEXT)'

/**
 * db manager
 */
export class RdbStoreManager {
  private TAG = '[RdbStoreManager]:'
  private mRdbStore

  private constructor() {
  }
  /**
   * db manager instance
   *
   * @return rdbStoreManager instance
   */
  public static getInstance() {
    if (globalThis.RdbStoreManagerInstance == null) {
      globalThis.RdbStoreManagerInstance = new RdbStoreManager();
    }
    return globalThis.RdbStoreManagerInstance;
  }

  public async initRdbConfig() {
    Log.info(this.TAG + 'initRdbConfig start');
    const promise = dataRdb.getRdbStore(globalThis.cameraAbilityContext,
      {
        name: DB_NAME
      }, DB_VERSION);
    promise.then(async (rdbStore) => {
      Log.info(this.TAG + 'initRdbConfig dataRdb.getRdbStore:' + rdbStore);
      this.mRdbStore = rdbStore;
      this.createTable();
    }).catch((error) => {
      Log.error('RdbStoreManager.initRdbConfig Failed to obtain the rdbStore. Cause: ' + error.message);
    });
    Log.info(this.TAG + 'initRdbConfig end');
  }

  private async createTable() {
    Log.info(this.TAG + 'create table start');
    Log.info(this.TAG + `RdbStoreConfig.CREATE_TABLE: ${CREATE_TABLE}`);
    await this.mRdbStore.executeSql(CREATE_TABLE, []);
    Log.info(this.TAG + 'create table end');
  }

  public async getSettingByItem(itemName: string) {
    Log.info(this.TAG + 'getSettingByItem start');
    const resultList: SettingItemInfo[] = [];
    if (this.ifStringIsNull(itemName)) {
      Log.warn(this.TAG + 'itemName is null');
      return resultList;
    }
    try {
      const predicates = new dataRdb.RdbPredicates(TABLE_NAME);
      predicates.equalTo('item_name', itemName);
      const resultSet = await this.mRdbStore.query(predicates, []);
      let isLast = resultSet.goToFirstRow();
      Log.info(this.TAG + `getSettingByItem before isLast: ${isLast}`);
      while (isLast) {
        const itemInfo: SettingItemInfo = new SettingItemInfo()
        itemInfo.itemName = resultSet.getString(resultSet.getColumnIndex('item_name'));
        itemInfo.itemValue = resultSet.getString(resultSet.getColumnIndex('item_value'));
        resultList.push(itemInfo);
        isLast = resultSet.goToNextRow();
        Log.info(this.TAG + `getSettingByItem while isLast: ${isLast}`);
      }
    } catch (e) {
      Log.error(this.TAG + 'getSettingByItem error:' + e);
    }
    return resultList;
  }

  public async updateValue(settingItemInfo: SettingItemInfo) {
    Log.info(this.TAG + 'updateValue start');
    let result = false;
    try {
      const predicates = new dataRdb.RdbPredicates(TABLE_NAME);
      predicates.equalTo('item_name', settingItemInfo.itemName);
      const updateBucket = {
        'item_value': settingItemInfo.itemValue,
      };
      Log.info(this.TAG + 'updateValue predicates: ' + JSON.stringify(predicates))
      Log.info(this.TAG + 'mRdbStore.update called.')
      let changeRows = await this.mRdbStore.update(updateBucket, predicates);
      Log.info(this.TAG + 'mRdbStore.update finished.')
      if (changeRows == 1) {
        Log.info(this.TAG + `updateValue updated ok: ${changeRows}`);
        result = true;
      } else {
        Log.info(this.TAG + `updateValue updated not effect: ${changeRows}`);
        const insertBucket = {
          'item_name': settingItemInfo.itemName,
          'item_value': settingItemInfo.itemValue,
        };
        changeRows = await this.mRdbStore.insert(TABLE_NAME, insertBucket);
        Log.info(this.TAG + `updateValue insert: ${changeRows}`);
        result = (changeRows != -1);
      }
    } catch (e) {
      Log.error(this.TAG + 'updateValue error:' + e);
    }
    return result;
  }

  private ifStringIsNull(str) {
    return (str == undefined || str == '' || str == null)
  }
}