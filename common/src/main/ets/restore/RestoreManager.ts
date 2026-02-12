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
import lazy { emitter } from '@kit.BasicServicesKit';
import lazy { ContextManager } from '../service/context/ContextManager';
import lazy { PersistType, PreferencesService } from '../service/preferences/PreferencesService';
import lazy { HiLog } from '../utils/HiLog';
import dataPreferences from '@ohos.data.preferences';
import lazy { PropTag, PublicTag } from '../service/preferences/PropTag';
import { FeatureManager } from '../function/core/FeatureManager';
import { FunctionId } from '../function/core/functionproperty/FunctionId';
import { BaseFunction } from '../function/core/BaseFunction';

const TAG: string = 'RestoreManager';

export class RestoreManager {
  private static sInstanceRestoreManger: RestoreManager;
  private static propPreferences: dataPreferences.Preferences;
  private static isListenerRegistered: boolean = false;
  public static getInstance(): RestoreManager {
    if (!RestoreManager.sInstanceRestoreManger) {
      RestoreManager.sInstanceRestoreManger = new RestoreManager();
      RestoreManager.propPreferences = PreferencesService.getInstance().getPropPreferences();
    }
    return RestoreManager.sInstanceRestoreManger;
  }

  /**
   * 移除多进程读写preference的事件监听
   */
  /* instrument ignore next */
  public removeProcessChangeListener(): void {
    RestoreManager.propPreferences.off('multiProcessChange');
  }

  /**
   * 添加多进程读写preference的事件监听
   */
  public addProcessChangeListener(): void {
    try {
      /* instrument ignore if*/
      if (RestoreManager.isListenerRegistered) {
        HiLog.i(TAG, `listener has been Registered`);
        return;
      }
      RestoreManager.propPreferences.on('multiProcessChange', (key: string) => {
        RestoreManager.onMultiProcessChange(key);
      });
      RestoreManager.isListenerRegistered = true;
      HiLog.i(TAG, `addProcessChangeListener success`);
    } catch (error) {
      HiLog.e(TAG, `addProcessChangeListener fail error: ${error}`);
    }
  }

  /**
   * preference中键值发生变化时的回调
   *
   * @param key 值发生变化的键
   */
  private static onMultiProcessChange(key: string): void {
    HiLog.i(TAG, `onMultiProcessChange key: ${key}`);
    let propTag: PropTag = PropTag.FIRST_FOREGROUND_AFTER_RESTORE;
    let persistKey: string =
      PreferencesService.getInstance().getPropPersistKey(PersistType.FOREVER, 'ALL', 'ALL', propTag);
    // 当变化的key为FIRST_FOREGROUND_AFTER_RESTORE时表示在进行克隆恢复, 此时需要清除一下preference缓存并恢复function的值
    let needRemovePreferenceCache: boolean = persistKey === key;
    /* instrument ignore if*/
    if (needRemovePreferenceCache) {
      HiLog.i(TAG, `begin restore: ${needRemovePreferenceCache}`);
      PreferencesService.updatePreference(needRemovePreferenceCache);
      RestoreManager.restoreValue();
    }
  }

  private static restoreValue(): void {
    try {
      RestoreManager.restoreFunction_persist_values();
      RestoreManager.restorePublic_persist_values();
      RestoreManager.restoreProp_persist_values();
    } catch (err) {
      HiLog.e(TAG, `restore error: ${err}`);
    }

  }

  private static restoreFunction_persist_values(): void {
    let mFeatureMgr: FeatureManager = FeatureManager.getInstance();
    let functionsMap = mFeatureMgr.getFunctionsMap();
    let restoreKeys: FunctionId[] = [
      FunctionId.ASSISTIVE_GRID, FunctionId.HORIZONTAL_LEVEL, FunctionId.SOUND_MUTE, FunctionId.SAVE_GEO_LOCATION
    ];
    restoreKeys.forEach((functionId: FunctionId) => {
      let functionValue: boolean =
        JSON.parse(PreferencesService.getInstance().getFunctionValue(PersistType.FOREVER, functionId, false) as string);
      let mFunction: BaseFunction | undefined = functionsMap.get(functionId);
      if (mFunction) {
        mFunction.setValue(functionValue);
        HiLog.i(TAG, `restore function: ${functionId} success, functionValue: ${functionValue}`);
      } else {
        HiLog.i(TAG, `restore function: ${functionId} fail, functionValue: ${functionValue}`);
      }
    })
  }

  private static restorePublic_persist_values(): void {
    const restoreKeys: PublicTag[] = [PublicTag.IS_INTRO_LOADED];
    restoreKeys.forEach((restoreKey: PublicTag) => {
      let value: boolean =
        JSON.parse(PreferencesService.getInstance().getPublicValue(PersistType.FOREVER, restoreKey, false) as string);
      PreferencesService.getInstance().putPublicValue(PersistType.FOREVER, restoreKey, value);
      HiLog.i(TAG, `restore public: ${restoreKey} success, value: ${value}`);
    })
  }

  private static restoreProp_persist_values(): void {
    const restoreKeys: PropTag[] = [PropTag.IS_REQUESTED_PERMISSION];
    restoreKeys.forEach((restoreKey: PropTag) => {
      let value: boolean =
        JSON.parse(PreferencesService.getInstance().getPropValue(PersistType.FOREVER, restoreKey, false) as string);
      PreferencesService.getInstance().putPropValue(PersistType.FOR_AWHILE, restoreKey, value);
      HiLog.i(TAG, `restore prop: ${restoreKey} success, value: ${value}`);
    })
  }
}