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

import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { UIExtensionContentSession } from '@kit.AbilityKit';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';

class PermissionState {
  public permissionState: boolean = false;
}

let storage = LocalStorage.getShared();
const TAG = 'PermissionExtension';

@Entry(storage)
@Component
struct PermissionExtension {
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  private session: UIExtensionContentSession | undefined = storage.get<UIExtensionContentSession>('session');

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E');
    this.mEventBus.on(ActionType.ACTION_SEND_PERMISSION_STATE,
      (permissionState: PermissionState) => this.permissionChange(permissionState),
      this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear X');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E');
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToDisappear X');
  }

  private permissionChange(permissionState: PermissionState): void {
    if (this.session != undefined) {
      HiLog.i(TAG, `send data to photo state: ${permissionState?.permissionState}`);
      this.session?.sendData({ 'cameraLocationPermission': permissionState?.permissionState });
    }
  }

  build() {
  }
}
