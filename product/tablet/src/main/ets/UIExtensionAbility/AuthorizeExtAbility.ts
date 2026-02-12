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

import { UIExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { Dispatch, getDispatch } from '@ohos/common/src/main/ets/redux';
import { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { ModeMap } from '../common/ModeMap';
import { Action } from '@ohos/common/src/main/ets/redux/actions/Action';

const TAG: string = 'AuthorizeExtAbility';
class AbilityDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public confirmLocationTOSettingPermission(): void {
    this.mDispatch(Action.confirmLocationTOSettingPermission(true, 0, true));
  }
}

export default class AuthorizeExtAbility extends UIExtensionAbility {
  private mAction: AbilityDispatcher = new AbilityDispatcher();
  onCreate() {
    HiLog.begin(TAG, 'AuthorizeExtAbility onCreate.');
    ContextManager.getInstance().setUiExtensionContext(this.context);
    FeatureManager.getInstance().init(ModeType.PHOTO, new ModeMap());
    this.mAction.setDispatch(getDispatch());
    // 调用前往设置申请权限
    this.mAction.confirmLocationTOSettingPermission();
    HiLog.end(TAG, 'AuthorizeExtAbility onCreate.');
  }

  onForeground() {
    HiLog.i(TAG, 'AuthorizeExtAbility onForeground');
  }

  onBackground() {
    HiLog.i(TAG, 'AuthorizeExtAbility onBackground');
  }

  onDestroy() {
    HiLog.i(TAG, 'AuthorizeExtAbility onDestroy');
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    HiLog.begin(TAG, 'AuthorizeExtAbility onSessionCreate.');
    if (!want) {
      HiLog.e(TAG, 'onSessionCreate want is empty');
      return;
    }
    const  param: Record<string, UIExtensionContentSession> = {
      'session': session
    };
    const storage: LocalStorage = new LocalStorage(param);
    session.loadContent('pages/PermissionExtension', storage);
    HiLog.end(TAG, 'AuthorizeExtAbility onSessionCreate.');
  }

  onSessionDestroy(session: UIExtensionContentSession) {
    HiLog.i(TAG, 'AuthorizeExtAbility onSessionDestroy');
  }
}