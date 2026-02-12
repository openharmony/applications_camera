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
import lazy { ValuesBucket, relationalStore } from '@kit.ArkData';
import lazy { HiLog } from './HiLog';
import lazy { ContextManager } from '../service/context/ContextManager';
import lazy { camera } from '@kit.CameraKit';
import lazy { CameraAppCapability } from '../camera/CameraAppCapability';

const TAG = 'CustomFilterDatabaseUtils';
const CUSTOM_TEMPLATE_DEFAULT_VALUE: number = -2;

export class DatabaseUtils {
  public static readonly TEMPLATE_MAX_NUMBER: number = 16;
  public static readonly TEMPLATE_MAX_NUMBER_CUSTOM_FILTER_TWO: number = 28;
  public static readonly CUSTOM_FILTER_TASK_POOL_TAG: string = 'CustomFilterTaskPool';
  public static readonly DB_NAME = 'OhosCamera.db';
  public static readonly TABLE_NAME = 'camera_custom_filter_style';
  public static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: this.DB_NAME,
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: false // 是否对数据库加密，false，不对数据库加密
  };
  public static store: relationalStore.RdbStore | undefined = undefined;
  private static sInstance: DatabaseUtils;
  private dataBaseAllItem: number = -1;

  private constructor() {
  }

  public static getInstance(): DatabaseUtils {
    if (!DatabaseUtils.sInstance) {
      DatabaseUtils.sInstance = new DatabaseUtils();
    }
    return DatabaseUtils.sInstance;
  }

  public async getDataBaseAllItem(): Promise<number> {
    HiLog.begin(TAG, 'getDataBaseAllItem');
    if (this.dataBaseAllItem === undefined) {
      this.dataBaseAllItem = await this.queryAllData();
    }
    HiLog.end(TAG, 'getDataBaseAllItem');
    return this.dataBaseAllItem;
  }


  public async createDataDB(): Promise<void> {
    try {
      DatabaseUtils.store =
        await relationalStore.getRdbStore(ContextManager.getInstance().getUiContext(), DatabaseUtils.STORE_CONFIG);
      HiLog.i(TAG, 'Create CustomFilter OhosCamera.db successfully!');
    } catch (err) {
      HiLog.e(TAG, `Create CustomFilter OhosCamera.db failed! err code:${err?.code}`);
    }
  }

  public async queryAllData(): Promise<number> {
    HiLog.begin(TAG, 'queryAllData');
    let resultSetAllCount: number;
    if (DatabaseUtils.store === null || DatabaseUtils.store === undefined) {
      HiLog.e(TAG, 'queryAllData OhosCamera.db failed! HomsCamera is null');
      this.createDataDB();
    }
    try {
      let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(DatabaseUtils.TABLE_NAME);
      let resultSet = await DatabaseUtils.store.query(predicates); // 查询所有数据
      resultSetAllCount = resultSet.rowCount;
      HiLog.i(TAG, `queryAllData table count:${resultSetAllCount}`);
      resultSet.close();
    } catch (err) {
      HiLog.e(TAG, `query data failed! err code:${err?.code}`);
    }
    HiLog.end(TAG, 'queryAllData');
    return resultSetAllCount;
  }


  //@ts-ignore
  public async deleteAllTableData(): Promise<void> {
    if (DatabaseUtils.store == null || DatabaseUtils.store === undefined) {
      HiLog.e(TAG, `insertTableData failed! HomsCamera is null`);
      return;
    }
    try {
      HiLog.begin(TAG, 'deleteAllTableData');
      let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(DatabaseUtils.TABLE_NAME);
      await DatabaseUtils.store.delete(predicates);
      HiLog.i(TAG, 'Delete all table data successfully!');
      HiLog.end(TAG, 'deleteAllTableData');
    } catch (err) {
      HiLog.e(TAG, `Delete data  failed! err code:${err.code}, err message:${err.message}`)
    }
  }

  //@ts-ignore
  public async deleteTableData(deleteStyleType: camera.ColorStyleType, deleteStyleIndex: number,
    curStyleTemplateLength: number): Promise<void> {
    HiLog.i(TAG, `deleteTableData deleteStyleType :${deleteStyleType},deleteStyleIndex :${deleteStyleIndex}
      ,curStyleTemplateLength :${curStyleTemplateLength}`);
    if (DatabaseUtils.store == null || DatabaseUtils.store === undefined) {
      HiLog.e(TAG, `insertTableData failed! HomsCamera is null`);
      return;
    }
    try {
      let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(DatabaseUtils.TABLE_NAME);
      const valueBucket: ValuesBucket = {
        'type': deleteStyleType,
        'styleIndex': deleteStyleIndex,
        'hue': CUSTOM_TEMPLATE_DEFAULT_VALUE,
        'saturation': CUSTOM_TEMPLATE_DEFAULT_VALUE,
        'tone': CUSTOM_TEMPLATE_DEFAULT_VALUE,
      };
      predicates.equalTo('type', deleteStyleType)
        .and()
        .equalTo('styleIndex', deleteStyleIndex);
      DatabaseUtils.store.update(valueBucket, predicates).then((count) => {
        HiLog.i(TAG, `delete update data successful count is:${count}`);
      });
    } catch (err) {
      HiLog.e(TAG, `delete data failed! err code:${err?.code}`);
    }
  }
}