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

import AbilityStage from '@ohos.app.ability.AbilityStage';
import lazy { CameraProxy } from '@ohos/common/src/main/ets/camera/uithread/CameraProxy';
import lazy { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { Configuration } from '@ohos.app.ability.Configuration';
// import lazy { PafUiWidget } from '@ohos-paf/ui-widget-base';
import lazy { reduxInit } from '@ohos/common/src/main/ets/redux/Store';

const TAG: string = 'MyAbilityStage';

export default class MyAbilityStage extends AbilityStage {
  onCreate(): void {
    HiLog.begin(TAG, 'onCreate');
    this.suggestCache();
    ContextManager.getInstance().setAbilityStageContext(this.context);
    CameraProxy.getInstance().init();
    CameraAppCapability.getInstance();
    reduxInit();
    CameraBasicService.getInstance().init();
    HiLog.end(TAG, 'onCreate');
  }

  private suggestCache(): void {
    const applicationContext = this.context.getApplicationContext();
    try {
      applicationContext.setSupportedProcessCache(true);
    } catch (error) {
      HiLog.e(TAG, `setSupportedProcessCache fail, code: ${error?.code}`);
    }
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    // PafUiWidget.configurationUpdate(newConfig);
    AppStorage.setOrCreate('currentColorMode', newConfig.colorMode); // 为大图同步显示模式（深色、浅色）
  }
}