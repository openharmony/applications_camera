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

import Ability from '@ohos.app.ability.UIAbility';
import AbilityDelegatorRegistry from '@ohos.application.abilityDelegatorRegistry';
import { Hypium } from '@ohos/hypium';
import testsuite from '../test/List.test';

let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
let abilityDelegatorArguments = AbilityDelegatorRegistry.getArguments();
Hypium.hypiumTest(abilityDelegator, abilityDelegatorArguments, testsuite);

/**
 * tablet--TestAbility
 */
export default class TestAbility extends Ability {
  onCreate(want, launchParam): void {
  }

  onDestroy(): void {
  }

  onWindowStageCreate(windowStage): void {
    windowStage.setUIContent(this.context, 'TestAbility/pages/index', null);
  }

  onWindowStageDestroy(): void {
  }

  onForeground(): void {
  }

  onBackground(): void {
  }
};
