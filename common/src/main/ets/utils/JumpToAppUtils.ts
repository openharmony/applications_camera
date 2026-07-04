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
import lazy { BusinessError } from '@ohos.base';
import lazy { HiLog } from './HiLog';
import common from '@ohos.app.ability.common';
import bundleManager from '@ohos.bundle.bundleManager';
import Want from '@ohos.app.ability.Want';

const TAG: string = 'JumpToAppUtils';
const CODE_BUNDLE_NAME_NOT_FOUND: number = 17700001;
const CODE_SUCCESS = 0;

type startAbleContext = common.UIAbilityContext | common.ServiceExtensionContext;
/* instrument ignore file */
export class JumpToAppUtils {
  public static jumpToApp(context: startAbleContext, want: Want): void {
    HiLog.i(TAG, 'Start to jump to the target app.');
    context.startAbility(want, (err: BusinessError) => {
      if (err?.code !== CODE_SUCCESS) {
        HiLog.w(TAG, 'Failed to jump to the target app. Error : %{private}s', JSON.stringify(err));
      } else {
        HiLog.i(TAG, 'Successfully jumped to the target app.');
      }
    });
  }

  public static isAppInstalled(appBundleName: string, appID: string): Promise<boolean> {
    return bundleManager.getBundleInfo(appBundleName, bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO)
      .then((bundleInfo) => {
        // 校验跳转目标应用包的正确性，防止跳转到伪造的同名包应用。
        if (bundleInfo.signatureInfo.appId === appID) {
          HiLog.i(TAG, 'The input app is installed.');
          return true;
        } else {
          HiLog.w(TAG, 'The input app is forged.');
          return false;
        }
      })
      .catch((err: BusinessError) => {
        if (err?.code === CODE_BUNDLE_NAME_NOT_FOUND) {
          HiLog.e(TAG, 'The input bundle name is not installed.');
        } else {
          HiLog.i(TAG, 'Failed to check if the input app is installed. Error: %{private}s', JSON.stringify(err));
        }
        return false;
      });
  }
}