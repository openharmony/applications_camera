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
import lazy { UIExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';

/* instrument ignore file */
const TAG: string = 'RemoteCaptureDialogAbility';

/**
 * 手表访问相机弹窗
 */
export default class RemoteCaptureDialogAbility extends UIExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    HiLog.begin(TAG, 'onSessionCreate');
    if (!want) {
      HiLog.e(TAG, 'onSessionCreate want is empty');
      return;
    }
    let param: Record<string, Object | undefined | string> = {
      'session': session,
      'watchDeviceName': want.parameters?.watchDeviceName,
      'watchUuid': want.parameters?.watchUuid,
      'isSmartWatch': want.parameters?.isSmartWatch
    }
    try {
      let storage: LocalStorage = new LocalStorage(param);
      session.loadContent('pages/RemoteCaptureDialogIndex', storage);
      session.setWindowBackgroundColor('#00000000');
    } catch (e) {
      HiLog.e(TAG, `loadContent failed ${e}`);
    }
    HiLog.end(TAG, 'onSessionCreate');
  }
}