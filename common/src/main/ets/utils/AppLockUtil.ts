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

import bundleManager from '@ohos.bundle.bundleManager';
import lazy { HiLog } from './HiLog';
// import appLock from '@hms.security.appLock';
import lazy { Callback, osAccount } from '@kit.BasicServicesKit';
import lazy { SystemParamService } from '../service/systemparameter/SystemParamService';

const TAG = 'ReadAPPLockStateUtil';
const ASSOCIATED_BUNDLE_NAME = 'com.ohos.photos';
const ASSOCIATED_APP_IDENTIFIER = '1207824849184017472';
const USER_ID = 100;

type CallbackInterface = (value: boolean) => void;

export class AppLockUtil {
  private static instance: AppLockUtil;
  private callbacks: Set<CallbackInterface> = new Set();
  private isPhotoLocked: boolean = false;
  private hasInitLockedState: boolean = false;

  private constructor() {
  }

  public static getInstance(): AppLockUtil {
    if (!AppLockUtil.instance) {
      AppLockUtil.instance = new AppLockUtil();
    }
    return AppLockUtil.instance;
  }

  /* instrument ignore next */
  // private appProtectedStateChangeCallback: Callback<appLock.AppProtectedState[]> =
  //   (appProtectedStates: appLock.AppProtectedState[]) => {
  //     let concernedArrays = appProtectedStates.filter((appProtectedState) => {
  //       return appProtectedState.appInfo.bundleName === ASSOCIATED_BUNDLE_NAME;
  //     });
  //     if (concernedArrays.length === 0) {
  //       return;
  //     }
  //     let isPhotoLockedInner: boolean = concernedArrays[0].isProtected;
  //     this.callbacks.forEach(callback => {
  //       HiLog.i(TAG, `isPhotoLocked: ${this.isPhotoLocked}, isPhotoLockedInner: ${isPhotoLockedInner}`);
  //       if (this.isPhotoLocked && isPhotoLockedInner === this.isPhotoLocked) {
  //         // 应用锁两次状态相同且为开启状态，不重复发回调
  //         return;
  //       }
  //       callback(isPhotoLockedInner);
  //     });
  //     this.isPhotoLocked = isPhotoLockedInner;
  //   };

  public async registerAppLock(callback: CallbackInterface): Promise<void> {
    this.isPhotoLocked = await this.isPhotoAppLocked();
    if (this.callbacks.size === 0) {
      // appLock.on('appProtectedStateChange', this.appProtectedStateChangeCallback);
    }
    this.callbacks.add(callback);
    HiLog.i(TAG, `register to read AppLock state successfully`);
  }

  /* instrument ignore next */
  public unregisterAppLock(callback: CallbackInterface): void {
    this.callbacks.delete(callback);
    HiLog.i(TAG, `unregister successfully`);
    if (this.callbacks.size === 0) {
      this.hasInitLockedState = false;
      // appLock.off('appProtectedStateChange', this.appProtectedStateChangeCallback);
      HiLog.i(TAG, `unregister to read AppLock state successfully`);
    }
  }

  public ForceUnregisterAppLock(): void {
    this.hasInitLockedState = false;
    this.callbacks.clear();
    // appLock.off('appProtectedStateChange', this.appProtectedStateChangeCallback);
    HiLog.i(TAG, `unregister all AppLock monitor successfully`);
  }

  public async isPhotoAppLocked(): Promise<boolean> {
    let appLockEnableTag = SystemParamService.getInstance().dynamicGet(true, 'security.app_lock_service.enabled', '0');
    let appLockEnable = appLockEnableTag === '1';
    HiLog.i(TAG, `appLockEnable: ${appLockEnable}, isPhotoAppLocked: ${this.isPhotoLocked}.`);
    if (!appLockEnable) {
      return false;
    }
    if (appLockEnable && !this.isPhotoLocked) {
      this.hasInitLockedState = false;
    }
    if (!this.hasInitLockedState) {
      this.isPhotoLocked = await this.isPhotoAppLockedInner();
      this.hasInitLockedState = true;
    }
    return this.isPhotoLocked;
  }

  /* instrument ignore next */
  private async isPhotoAppLockedInner(): Promise<boolean> {
    try {
      HiLog.begin(TAG,'isPhotoAppLockedInner getBundleInfo');
      let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfo(ASSOCIATED_BUNDLE_NAME,
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO
      );
      HiLog.end(TAG,'isPhotoAppLockedInner getBundleInfo');
      if (bundleInfo?.signatureInfo?.appIdentifier !== ASSOCIATED_APP_IDENTIFIER) {
        HiLog.i(TAG, 'invalid appIdentifier');
        return false;
      }
      // let option: appLock.Options = {
      //   userId: await this.getUserId()
      // };
      HiLog.begin(TAG,'isPhotoAppLockedInner isAppProtected');
      // let isProtected: boolean = await appLock.isAppProtected(ASSOCIATED_BUNDLE_NAME, option);
      HiLog.end(TAG,'isPhotoAppLockedInner isAppProtected');
      // HiLog.i(TAG, `${ASSOCIATED_BUNDLE_NAME} is protected: ${isProtected}`);
      return false//isProtected;
    } catch (error) {
      HiLog.e(TAG, `isAssociatedBundleBeingLocked failed: ${error?.code}`);
    }
    return false;
  }

  private async getUserId(): Promise<number> {
    const accountManager: osAccount.AccountManager = osAccount.getAccountManager();
    let userId: number = USER_ID;
    try {
      userId = await accountManager.getForegroundOsAccountLocalId();
    } catch (error) {
      HiLog.e(TAG, `get foreground os account local id failed: ${error?.code}`);
    }
    return userId;
  }
}