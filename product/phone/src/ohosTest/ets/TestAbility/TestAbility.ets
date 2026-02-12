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
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { Hypium } from '@ohos/hypium';
import testsuite from '../test/List.test';
import window from '@ohos.window';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';

const TAG = 'TestAbility';

let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
let abilityDelegatorArguments = AbilityDelegatorRegistry.getArguments();

Hypium.hypiumTest(abilityDelegator, abilityDelegatorArguments, testsuite);

/**
 * Phone- TestAbility.
 */
export default class TestAbility extends Ability {
  onCreate(): void {
    HiLog.i(TAG, 'TestAbility onCreate');
  }

  onDestroy(): void {
    HiLog.i(TAG, 'TestAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    HiLog.i(TAG, 'TestAbility onWindowStageCreate');
    windowStage.loadContent('TestAbility/pages/index', (err, data) => {
    });
  }

  onWindowStageDestroy(): void {
    HiLog.i(TAG, 'TestAbility onWindowStageDestroy');
  }

  onForeground(): void {
    HiLog.i(TAG, 'TestAbility onForeground');
  }

  onBackground(): void {
    HiLog.i(TAG, 'TestAbility onBackground');
  }
};