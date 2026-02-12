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

import power from '@ohos.power';
import screenLock from '@ohos.screenLock';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { ContextManager } from '../context/ContextManager';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import Want from '@ohos.app.ability.Want';

/* instrument ignore file */
const TAG = 'RestartService';

export class RestartService {
  public static readonly RESTART_DELAY: number = 12000;
  private static sInstanceCapability: RestartService;
  private appRecoveryTimer: number = Number.MIN_VALUE;

  public static getInstance(): RestartService {
    if (!RestartService.sInstanceCapability) {
      RestartService.sInstanceCapability = new RestartService();
    }
    return RestartService.sInstanceCapability;
  }

  public recoveryRestartApp(): void {
    if (!this.isEnableToRestart()) {
      HiLog.i(TAG, 'Ignore restartApp.');
      return;
    }
    this.appRecoveryTimer = setTimeout(
      (): void => {
        if (!this.isEnableToRestart()) {
          HiLog.i(TAG, 'Cancel restartApp.');
          this.cancelRestart();
          return;
        }
        HiLog.i(TAG, 'cameraError restartApp');
        let want: Want = {
          bundleName: 'com.ohos.camera',
          abilityName: 'com.ohos.camera.MainAbility'
        };
        try {
          ContextManager.getInstance().getApplicationContext().restartApp(want);
        } catch (error) {
          HiLog.e(TAG, `restartApp fail, error: ${error?.code}`);
        }
        this.cancelRestart();
      }
      , RestartService.RESTART_DELAY);
  }

  public cancelRestart(): void {
    if (this.appRecoveryTimer !== Number.MIN_VALUE) {
      clearTimeout(this.appRecoveryTimer);
      this.appRecoveryTimer = Number.MIN_VALUE;
    }
  }

  private isEnableToRestart(): boolean {
    let isPicker: boolean = GlobalContext.get().getIsPicker();
    let isBackground: boolean = AppStorage.get<boolean>('isBackground');
    try {
      let isActive: boolean = power.isActive();
      let isLocked: boolean = screenLock.isLocked();
      let isSecurityCamera: boolean = GlobalContext.get().getT<boolean>('isSecurityCamera');
      HiLog.i(TAG,
        `isPicker: ${isPicker}, isBackground ${isBackground}, isActive: ${isActive}, isLocked: ${isLocked},isSecurityCamera:${isSecurityCamera}`);
      return !isPicker && !isBackground && isActive && !isLocked && !isSecurityCamera;
    } catch (err) {
      HiLog.e(TAG, `screenLock error, code: ${err?.code}, message: ${err?.message}.`);
    }
  }
}
