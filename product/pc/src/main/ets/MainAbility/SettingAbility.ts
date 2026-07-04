/*
 * Copyright (c) Huawei Device Co., Ltd. 2023-2025. All rights reserved.
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

import UIAbility from '@ohos.app.ability.UIAbility';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { ModeMap } from '../common/ModeMap';
import window from '@ohos.window';
import type { Size } from '@ohos/common/src/main/ets/utils/types';
import { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import { SettingViewAction } from '@ohos/common/src/main/ets/component/settingview/SettingViewAction';
import { PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import { Callback } from '@ohos.base';
import { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import config from '@ohos.accessibility.config';
import { BusinessError } from '@ohos.base';
import { display } from '@kit.ArkUI';
import { execDispatch } from '@ohos/common/src/main/ets/redux';
import { Configuration } from '@kit.AbilityKit';

const TAG: string = 'SettingAbility';

export default class SettingAbility extends UIAbility {
  private readonly windowBorderHeight: number = 43;
  private readonly windowBorderWidth: number = 8;
  private mWindow: window.Window;
  protected mStoreManager: StoreManager = StoreManager.getInstance();

  onCreate(want, launchParam): void {
    HiLog.i(TAG, 'SettingAbility onCreate.');
    ContextManager.getInstance().setSettingAbilityContext(this.context);
  }

  onDestroy(): void {
    PreferencesService.getInstance().flush();
    HiLog.i(TAG, 'SettingAbility onDestroy.');
    StoreManager.getInstance().postMessage(SettingViewAction.showSettingView(false, true));
  }

  onWindowStageCreate(windowStage): void {
    HiLog.i(TAG, 'SettingAbility onWindowStageCreate.');
    try {
      windowStage.setDefaultDensityEnabled(true);
    } catch (e) {
      HiLog.e(TAG, `windowStage setDefaultDensityEnabled: ${e.code}`)
    }
    windowStage.getMainWindow().then((win) => {
      try {
        HiLog.i(TAG, `windowStage.getMainWindow then win: ${win}.`);
        this.mWindow = win;
        const properties: window.WindowProperties = win.getWindowProperties();
        const fullWindowHeight: number = DisplayService.getInstance().getDisplay().height;
        const winSize: Size = this.windowSizeWithoutDecorate(properties.windowRect, fullWindowHeight);
        AppStorage.setOrCreate<Size>('PCPrivacyPolicyViewSize', winSize);
        this.registerWindowStatusChange(win);
      } catch (err) {
        HiLog.e(TAG, `Camera onWindowSizeChange err: ${err}.`);
      }
    }).catch((err) => {
      HiLog.e(TAG, `Failed to getMainWindow, Code: ${err?.code}`);
    });
    try {
      windowStage.on('windowStageEvent', this.windowStageEventCallback().bind(this));
    } catch (err) {
      HiLog.e(TAG, `windowStageOnWindowStageEvent fail ${err?.code}`);
    }
    windowStage?.setUIContent(this.context, 'pages/SettingView', null);
  }

  private windowStageEventCallback(): Callback<window.WindowStageEventType> {
    return (event) => {
      HiLog.i(TAG, `Camera SettingAbility onWindowStageEvent: ${JSON.stringify(event)}.`);
      switch (event) {
        case window.WindowStageEventType.ACTIVE:
          this.mStoreManager.postMessage(ContextAction.abilityActive());
          break;
      }
    };
  }

  private registerWindowStatusChange(win: window.Window): void {
    // 监听窗口事件
    win.on('windowStatusChange', this.windowStatusChangeCallback().bind(this));
  }

  private windowStatusChangeCallback(): Callback<window.WindowStatusType> {
    return (windowType) => {
      HiLog.d(TAG, 'Succeeded in enabling the listener for window status changes. Data: ' + windowType);
      if (windowType === window.WindowStatusType.MINIMIZE || windowType === window.WindowStatusType.FLOATING ||
        windowType === window.WindowStatusType.MAXIMIZE) {
        WindowService.getInstance().setWindowTouchable(true);
      } else {
        WindowService.getInstance().setWindowTouchable(false);
      }
    };
  }

  onWindowStageWillDestroy(windowStage: window.WindowStage): void {
    try {
      windowStage.off('windowStageEvent');
    } catch (error) {
      HiLog.e(TAG, `off windowStageEvent error: ${error?.code}.`);
    }
    HiLog.i(TAG, 'onWindowStageWillDestroy.');
  }

  onWindowStageDestroy(): void {
    HiLog.i(TAG, 'SettingAbility onWindowStageDestroy.');
    PreferencesService.getInstance().flush();
    WindowService.getInstance().setWindowTouchable(true);
  }

  onForeground(): void {
    HiLog.i(TAG, 'SettingAbility onForeground.');
    this.getHighContrastTextState();
  }

  onBackground(): void {
    PreferencesService.getInstance().flush();
    HiLog.i(TAG, 'SettingAbility onBackground.');
  }

  private windowSizeWithoutDecorate(data: Size, fullWindowHeight: number): Size {
    HiLog.d(TAG, 'SettingAbility windowSizeWithoutDecorate.');
    return data.height === fullWindowHeight ?
      {
        width: px2vp(data.width), height: px2vp(data.height)
      } :
      {
        width: px2vp(data.width) - this.windowBorderWidth, height: px2vp(data.height) - this.windowBorderHeight
      };
  }

  public getHighContrastTextState(): void {
    config.highContrastText.get((err: BusinessError, data: boolean) => {
      if (err) {
        HiLog.e(TAG, `failed to get highContrastText, Code is ${err?.code}`);
        return;
      }
      HiLog.i(TAG, `Succeeded in get highContrastText, data is ${data}`);
      execDispatch(ContextAction.updateHighContrastState(data));
    });
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    if (newConfig.language) {
      HiLog.i(TAG, `systemLanguage change to ${newConfig.language}`);
      AppStorage.setOrCreate('systemLanguage', newConfig.language);
    }
  }
}