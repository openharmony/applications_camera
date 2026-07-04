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

import type common from '@ohos.app.ability.common';
import type UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import type { resourceManager } from '@kit.LocalizationKit';
import lazy { HiLog } from '../../utils/HiLog';

const TAG: string = 'ContextManager';

export class ContextManager {
  private static sInstance: ContextManager;

  // AbilityStage Context
  // Ability和picker因分包原因会有两个，目前验证分包后同进程，但内存不共享。
  private abilityStageContext: common.AbilityStageContext;
  private resManager: resourceManager.ResourceManager;
  private filesDir: string;
  private moduleName: string;

  // Ability Context
  private abilityContext: common.UIAbilityContext;
  // PC子窗口 Setting设置页
  private settingAbilityContext: common.UIAbilityContext;

  // ServiceExtensionAbility Context
  private serviceContext: common.ServiceExtensionContext;

  // UIExtensionAbility Context
  // 安全相机和Picker都有可能会创建UIExtensionContext，但至少不会同时使用
  private uiExtensionContext: common.UIExtensionContext;
  private uiExtensionSession: UIExtensionContentSession;

  private constructor() {
  }

  public static getInstance(): ContextManager {
    if (!ContextManager.sInstance) {
      ContextManager.sInstance = new ContextManager();
    }
    return ContextManager.sInstance;
  }

  public setAbilityStageContext(context: common.AbilityStageContext): void {
    this.abilityStageContext = context;
    this.resManager = this.abilityStageContext.resourceManager;
    this.filesDir = this.abilityStageContext.filesDir;
    this.moduleName = this.abilityStageContext.currentHapModuleInfo.name;
    HiLog.i(TAG, `setAbilityStageContext, name: ${this.moduleName}, filesDir: ${this.filesDir}.`);
  }

  public getAbilityStageContext(): common.AbilityStageContext {
    return this.abilityStageContext;
  }

  public getResourceManager(): resourceManager.ResourceManager {
    return this.resManager;
  }

  public getFilesDir(): string {
    return this.filesDir;
  }

  public getModuleName(): string {
    return this.moduleName;
  }

  public getApplicationContext(): common.ApplicationContext {
    return this.abilityStageContext.getApplicationContext();
  }

  public getContextWithToken(): common.ExtensionContext | common.UIAbilityContext {
    return this.getUiContext() || this.getServiceExtensionContext();
  }

  public getUiContext(): common.UIExtensionContext | common.UIAbilityContext {
    return this.getAbilityContext() || this.getUiExtensionContext();
  }

  public setAbilityContext(context: common.UIAbilityContext): void {
    this.abilityContext = context;
  }

  public getAbilityContext(): common.UIAbilityContext {
    return this.abilityContext;
  }

  public setSettingAbilityContext(context: common.UIAbilityContext): void {
    this.settingAbilityContext = context;
  }

  public getSettingAbilityContext(): common.UIAbilityContext {
    return this.settingAbilityContext;
  }

  public setServiceExtensionContext(context: common.ServiceExtensionContext): void {
    this.serviceContext = context;
  }

  public getServiceExtensionContext(): common.ServiceExtensionContext {
    return this.serviceContext;
  }

  public setUiExtensionContext(context: common.UIExtensionContext): void {
    this.uiExtensionContext = context;
  }

  public getUiExtensionContext(): common.UIExtensionContext {
    return this.uiExtensionContext;
  }

  public setUiExtensionSession(session: UIExtensionContentSession): void {
    this.uiExtensionSession = session;
  }

  public getUiExtensionSession(): UIExtensionContentSession {
    return this.uiExtensionSession;
  }
}