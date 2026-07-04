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
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import type uiExtension from '@ohos.arkui.uiExtension';
import type UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';

const TAG = 'SecureWindows';

export class SecureWindowsControl {
  private static mInstance: SecureWindowsControl;
  private extensionWindow: uiExtension.WindowProxy | undefined;

  constructor() {
  }

  public static getInstance(): SecureWindowsControl {
    if (!SecureWindowsControl.mInstance) {
      SecureWindowsControl.mInstance = new SecureWindowsControl();
    }
    return SecureWindowsControl.mInstance;
  }

  public async hideNonSecureWindows(hidden: boolean): Promise<void> {
    HiLog.i(TAG, 'hideNonSecureWindows E');
    if (!this.extensionWindow) {
      const session: UIExtensionContentSession = ContextManager.getInstance().getUiExtensionSession();
      HiLog.i(TAG, 'hideNonSecureWindows E11');
      if (!session) {
        HiLog.e(TAG, 'hideNonSecureWindows extensionWindow is not available');
        return;
      }
      this.extensionWindow = session.getUIExtensionHostWindowProxy();
    }
    HiLog.i(TAG, `hideNonSecureWindows E12 ${'hideNonSecureWindows' in this.extensionWindow}`);

    try {
      await this.extensionWindow?.hideNonSecureWindows(hidden);
      HiLog.i(TAG, `hideNonSecureWindows Succeeded in hiding (${hidden}) the non-secure windows`);
    } catch (err: unknown) {
      HiLog.e(TAG, `hideNonSecureWindows Failed to hide (${hidden}) the non-secure windows`);
    }
    HiLog.i(TAG, 'hideNonSecureWindows X');
  }
}