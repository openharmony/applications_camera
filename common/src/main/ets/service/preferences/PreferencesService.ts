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

import dataPreferences from '@ohos.data.preferences';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { PropTag, PublicTag } from './PropTag';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { ContextManager } from '../context/ContextManager';

const TAG = 'PreferencesService';

export enum PersistType {
  NEVER = 1,
  FOREVER = 2,
  FOR_AWHILE = 3,
  TILL_EXIT = 4
}

export const EXPIRE_MINUTE_TIME_15: number = 15;
export const FLUSH_TIMESTAMP: string = 'FLUSH_TIMESTAMP';
export const FLUSH_TIMESTAMP_AWHILE: string = 'FLUSH_TIMESTAMP_AWHILE';

const ONE_MINUTE_SECONDS: number = 60;
const ONE_SECOND_MILLISECONDS: number = 1000;

export class PreferencesService {
  public static readonly MULTI_PROCESS_CHANGE: string = 'multiProcessChange';
  private static functionPreferences: dataPreferences.Preferences;
  private static propPreferences: dataPreferences.Preferences;
  private static publicPreferences: dataPreferences.Preferences;
  private static capabilityPreferences: dataPreferences.Preferences;
  private static sInstancePreferencesService: PreferencesService;
  // 大图组件也会发送emitter消息, 这里EMITTER_ID要保证唯一
  public static readonly EMITTER_ID: number = 20241029;

  public static getInstance(): PreferencesService {
    if (!PreferencesService.sInstancePreferencesService) {
      try {
        PreferencesService.sInstancePreferencesService = new PreferencesService();
        PreferencesService.updatePreference();
      } catch (e) {
        HiLog.i(TAG, `getInstance error: ${JSON.stringify(e)}.`);
      }
    }
    return PreferencesService.sInstancePreferencesService;
  }

  getFunctionValue(persistType: PersistType, functionId: FunctionId, defaultValue: dataPreferences.ValueType):
    dataPreferences.ValueType {
    return PreferencesService.functionPreferences?.getSync(this.getFunctionPersistKey(persistType, 'ALL', 'ALL', functionId), defaultValue);
  }

  async putFunctionValue(persistType: PersistType, functionId: FunctionId, value: dataPreferences.ValueType | undefined): Promise<void> {
    HiLog.d(TAG, 'putFunctionValue X.');
    if (value === undefined) {
      HiLog.w(TAG, `The input value is undefined!`);
      return;
    }
    PreferencesService.functionPreferences.putSync(this.getFunctionPersistKey(persistType, 'ALL', 'ALL', functionId), value);
    await this.flushFunction();
    HiLog.d(TAG, 'putFunctionValue E.');
  }

  private getAvoidDefaultVal(propTag: PropTag): boolean {
    // const isCameraPosition = PropTag.CAMERA_POSITION === propTag; // 镜头信息超时，不拿默认值
    const isPcPersistMode = PropTag.MODE === propTag && DeviceInfo.isPc(); // pc无默认模式恢复
    const isWaterMark = PropTag.WATERMARK_VIEW === propTag;
    const isCustomFilterParamStatus = PropTag.WATERMARK_CUSTOM_FILTER_PARAM_STATUS === propTag;
    const isNeedAvoidDefaultVal = isPcPersistMode || isWaterMark || isCustomFilterParamStatus;
      // isCameraPosition ||
    return isNeedAvoidDefaultVal;
  }

  getPropValue(persistType: PersistType, propTag: PropTag,
    defaultValue: dataPreferences.ValueType): dataPreferences.ValueType {
    const isNeedAvoidDefaultVal = this.getAvoidDefaultVal(propTag);
    if (persistType === PersistType.FOR_AWHILE && this.isExpire(EXPIRE_MINUTE_TIME_15, FLUSH_TIMESTAMP) &&
      !isNeedAvoidDefaultVal) {
      if (propTag === PropTag.MODE) { // 15min 冷启相机恢复默认模式时需要持久化，热启warmStartWithModeAPos 会自动存下
        PreferencesService.propPreferences.putSync(this.getPropPersistKey(PersistType.FOR_AWHILE, 'ALL', 'ALL',
          propTag), defaultValue);
        HiLog.i(TAG, `15min to default mode, ${defaultValue}.`);
      }
      return defaultValue;
    }
    return PreferencesService.propPreferences?.getSync(this.getPropPersistKey(persistType, 'ALL', 'ALL', propTag),
      defaultValue);
  }

  async putPropValue(persistType: PersistType, propTag: PropTag, value: dataPreferences.ValueType,
    needFlush: boolean = true): Promise<void> {
    HiLog.d(TAG, 'putPropValue X.');
    PreferencesService.propPreferences.putSync(this.getPropPersistKey(persistType, 'ALL', 'ALL', propTag), value);
    if (needFlush) {
      await this.flushProp();
    }
    HiLog.d(TAG, 'putPropValue E.');
  }

  getPropValueAwhile(propTag: PropTag,
    defaultValue: dataPreferences.ValueType): dataPreferences.ValueType {
    const isNeedAvoidDefaultVal = this.getAvoidDefaultVal(propTag);
    if (this.isExpire(EXPIRE_MINUTE_TIME_15, FLUSH_TIMESTAMP_AWHILE) &&
      !isNeedAvoidDefaultVal) {
      return defaultValue;
    }
    return PreferencesService.propPreferences?.getSync(this.getPropPersistKey(PersistType.FOR_AWHILE, 'ALL', 'ALL', propTag),
      defaultValue);
  }

  async putPropValueAwhile(propTag: PropTag, value: dataPreferences.ValueType,
    needFlush: boolean = true, needUpdateTime: boolean = true): Promise<void> {
    HiLog.d(TAG, 'putPropValueAwhile X.');
    PreferencesService.propPreferences.putSync(this.getPropPersistKey(PersistType.FOR_AWHILE, 'ALL', 'ALL', propTag), value);
    if (needFlush) {
      await this.flushProp();
    }
    if (needUpdateTime) {
      await this.flushAwhile();
    }
    HiLog.d(TAG, 'putPropValueAwhile E.');
  }

  async flushAwhile(isNeedUpdateTimesTamp: boolean = true): Promise<void> {
    if (isNeedUpdateTimesTamp) {
      // 刷新时间标记，供下次15min判断使用
      PreferencesService.propPreferences.putSync(FLUSH_TIMESTAMP_AWHILE, new Date().getTime());
    }
  }

  getPublicValue(persistType: PersistType, publicTag: PublicTag, defaultValue: dataPreferences.ValueType):
    dataPreferences.ValueType {
    return PreferencesService.publicPreferences?.getSync(this.getPublicPersistKey(persistType, 'ALL', 'ALL', publicTag), defaultValue);
  }

  async putPublicValue(persistType: PersistType, publicTag: PublicTag, value: dataPreferences.ValueType): Promise<void> {
    HiLog.d(TAG, 'putPublicValue X.');
    PreferencesService.publicPreferences.putSync(this.getPublicPersistKey(persistType, 'ALL', 'ALL', publicTag), value);
    await this.flushPublic();
    HiLog.d(TAG, 'putPublicValue E.');
  }

  async reacquirePublicPreferencesSync(): Promise<void> {
    // 会优先从进程缓存取值，所以要清掉缓存重新从文件获取
    try {
      const optionsPublicPreferences: dataPreferences.Options = { 'name': 'public_persist_values' };
      const applicationContext = ContextManager.getInstance().getApplicationContext();
      dataPreferences.removePreferencesFromCacheSync(applicationContext, optionsPublicPreferences);
      PreferencesService.publicPreferences = dataPreferences.getPreferencesSync(applicationContext,
        optionsPublicPreferences);
    } catch (e) {
      HiLog.i(TAG, `reacquirePublicPreferencesSync error: ${JSON.stringify(e)}.`);
    }
  }

  async flush(isNeedUpdateTimesTamp: boolean = true): Promise<void> {
    if (isNeedUpdateTimesTamp) {
      // 相机退后台在去刷新时间标记，供下次15min判断使用
      PreferencesService.propPreferences.putSync(FLUSH_TIMESTAMP, Date.now());
    }
    await this.flushFunction();
    await this.flushProp();
    await this.flushPublic();
  }

  async flushFunction(): Promise<void> {
    await PreferencesService.functionPreferences.flush();
  }

  async flushProp(): Promise<void> {
    await PreferencesService.propPreferences.flush();
  }

  async flushPublic(): Promise<void> {
    await PreferencesService.publicPreferences.flush();
  }

  async flushCapability(): Promise<void> {
    await PreferencesService.capabilityPreferences.flush();
  }

  private getTimestamp(defaultValue: dataPreferences.ValueType, preferencesKey: string): dataPreferences.ValueType {
    if (preferencesKey === PropTag.AUDIO_ZOOM_TIMESTAMP || preferencesKey === PropTag.BUNDLE_STATS_TIMESTAMP) {
      return PreferencesService.propPreferences?.getSync(this.getPropPersistKey(PersistType.FOREVER, 'ALL', 'ALL',
        preferencesKey), defaultValue);
    } else {
      return PreferencesService.propPreferences?.getSync(preferencesKey, defaultValue);
    }
  }

  public isExpire(time: number, preferencesKey: string): boolean {
    return (Date.now() - <number> this.getTimestamp(Date.now(), preferencesKey)) >
      time * ONE_MINUTE_SECONDS * ONE_SECOND_MILLISECONDS;
  }

  public getFunctionPersistKey(persistType: PersistType, mode: string, position: string, tag: FunctionId): string {
    return 'function_' + persistType + '_' + mode + '_' + position + '_' + tag;
  }

  public getPropPersistKey(persistType: PersistType, mode: string, position: string, tag: PropTag): string {
    return 'prop_' + persistType + '_' + mode + '_' + position + '_' + tag;
  }

  public getPublicPersistKey(persistType: PersistType, mode: string, position: string, tag: PublicTag): string {
    return 'public_' + persistType + '_' + mode + '_' + position + '_' + tag;
  }

  private getCapabilityPersistKey(persistType: PersistType, mode: string, position: string, capKey: string): string {
    return 'capability_' + persistType + '_' + mode + '_' + position + '_' + capKey;
  }

  public getPropPreferences(): dataPreferences.Preferences {
    return PreferencesService.propPreferences;
  }

  /**
   * 更新preference对象, 并由参数决定更新preference对象是否需要清除缓存
   *
   * @param needRemoveCache 是否需要更新缓存
   */
  public static updatePreference(needRemoveCache: boolean = false): void {
    try {
    const optionsFunctionPreferences: dataPreferences.Options = { 'name': 'function_persist_values' };
    const optionsPropPreferences: dataPreferences.Options = { 'name': 'prop_persist_values' };
    const optionsPublicPreferences: dataPreferences.Options = { 'name': 'public_persist_values' };
    const optionsCapabilityPreferences: dataPreferences.Options = { 'name': 'capability_persist_values' };
    const abilityStageContext = ContextManager.getInstance().getAbilityStageContext();
    const applicationContext = abilityStageContext.getApplicationContext();
    if (needRemoveCache) {
      //清空缓存
      dataPreferences.removePreferencesFromCacheSync(abilityStageContext, optionsFunctionPreferences);
      dataPreferences.removePreferencesFromCacheSync(abilityStageContext, optionsPropPreferences);
      dataPreferences.removePreferencesFromCacheSync(abilityStageContext, optionsPublicPreferences);
      dataPreferences.removePreferencesFromCacheSync(abilityStageContext, optionsCapabilityPreferences);
    }
      PreferencesService.functionPreferences = dataPreferences.getPreferencesSync(abilityStageContext,
        optionsFunctionPreferences);
      PreferencesService.propPreferences = dataPreferences.getPreferencesSync(abilityStageContext,
        optionsPropPreferences);
      PreferencesService.publicPreferences = dataPreferences.getPreferencesSync(applicationContext,
        optionsPublicPreferences);
      PreferencesService.capabilityPreferences = dataPreferences.getPreferencesSync(applicationContext,
        optionsCapabilityPreferences);
    } catch (e) {
      HiLog.i(TAG, `updatePreference error: ${JSON.stringify(e)}.`);
    }
  }

  /**
   * 从propPreferences持久化文件中移除键值对
   *
   * @param key 将被移除项的键
   */
  public removeKey(key: string): void {
    PreferencesService.propPreferences.deleteSync(key);
    PreferencesService.propPreferences.flush();
  }

  public deletePublicPersistKey(persistType: PersistType, publicTag: PublicTag): void {
    PreferencesService.publicPreferences.deleteSync(this.getPublicPersistKey(persistType, 'ALL', 'ALL', publicTag));
  }

  public deleteFunctionPersistKey(persistType: PersistType, functionId: FunctionId): void {
    PreferencesService.functionPreferences.
      deleteSync(this.getFunctionPersistKey(persistType, 'ALL', 'ALL', functionId));
  }

  public deletePropPersistKey(persistType: PersistType, propTag: PropTag): void {
    PreferencesService.publicPreferences.deleteSync(this.getPropPersistKey(persistType, 'ALL', 'ALL', propTag));
  }

  public getCapabilityValue(persistType: PersistType, capKey: string, defaultValue: dataPreferences.ValueType):
    dataPreferences.ValueType {
    return PreferencesService.capabilityPreferences.getSync(this.getCapabilityPersistKey(persistType, 'ALL', 'ALL',
      capKey), defaultValue);
  }

  public async putCapabilityValue(persistType: PersistType, capKey: string,
    value: dataPreferences.ValueType): Promise<void> {
    PreferencesService.capabilityPreferences.putSync(this.getCapabilityPersistKey(persistType, 'ALL', 'ALL', capKey),
      value);
    await this.flushCapability();
  }
}