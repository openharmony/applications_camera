// @ts-nocheck
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

import dataStorage from '@ohos.data.storage';

const TAG: string = 'PreferencesService'

export enum PersistType {
  NEVER,
  FOREVER,
  FOR_AWHILE,
  TILL_EXIT
}

export class PreferencesService {
  private static modeStorage

  public static getInstance(): PreferencesService {
    if (!globalThis?.sInstancePreferencesService) {
      globalThis.sInstancePreferencesService = new PreferencesService()
      let filePath = globalThis.cameraAbilityContext.filesDir
      PreferencesService.modeStorage = dataStorage.getStorageSync(filePath + '/mode_persist_values')
    }
    return globalThis.sInstancePreferencesService
  }

  getModeValue(persistType: PersistType, defaultValue: any) {
    if (persistType === PersistType.FOR_AWHILE && this.isModeExpire()) {
      return defaultValue
    }
    return PreferencesService.modeStorage.getSync(this.getModePersistKey(persistType, 'BASE'), defaultValue)
  }

  putModeValue(persistType, value: any) {
    if (persistType === PersistType.FOR_AWHILE) {
      PreferencesService.modeStorage.putSync(this.getModePersistKey(persistType, 'Timestamp'), new Date().getTime())
    }
    PreferencesService.modeStorage.putSync(this.getModePersistKey(persistType, 'BASE'), value)
  }

  flush(): void {
    PreferencesService.modeStorage.putSync(this.getModePersistKey(PersistType.FOR_AWHILE, 'Timestamp'), new Date().getTime())
    this.flushMode()
  }

  flushMode(): void {
    PreferencesService.modeStorage.flushSync()
  }

  private getModeTimestamp(persistType: PersistType, defaultValue: any): any {
    return PreferencesService.modeStorage.getSync(this.getModePersistKey(persistType, 'Timestamp'), defaultValue)
  }

  private isModeExpire(): boolean {
    return (new Date().getTime() - this.getModeTimestamp(PersistType.FOR_AWHILE, 0)) > 15*60*1000
  }

  private getModePersistKey(persistType: PersistType, item: string): string {
    return 'mode_' + persistType + '_' + item
  }
}