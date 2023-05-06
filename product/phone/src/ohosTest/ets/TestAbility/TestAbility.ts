/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import Ability from '@ohos.application.Ability';
import type AbilityDelegator from '@ohos.application.AbilityDelegator';
import type AbilityDelegatorArgs from '@ohos.application.AbilityDelegatorArgs';
import AbilityDelegatorRegistry from '@ohos.application.abilityDelegatorRegistry';
import { Hypium } from 'hypium/index';
import testsuite from '../test/List.test';
import { Log } from '@ohos/common/src/main/ets/default/utils/Log';

export default class TestAbility extends Ability {
  onCreate(want, launchParam) {
    Log.log('TestAbility onCreate');
    let abilityDelegator: AbilityDelegator;
    abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
    let abilityDelegatorArguments: AbilityDelegatorArgs;
    abilityDelegatorArguments = AbilityDelegatorRegistry.getArguments();
    Log.info('start run testcase!!!');
    Hypium.hypiumTest(abilityDelegator, abilityDelegatorArguments, testsuite);
  }

  onDestroy() {
    Log.log('TestAbility onDestroy');
  }

  onWindowStageCreate(windowStage) {
    Log.log('TestAbility onWindowStageCreate');
    windowStage.setUIContent(this.context, 'TestAbility/pages/index', null);

    globalThis.abilityContext = this.context;
  }

  onWindowStageDestroy() {
    Log.log('TestAbility onWindowStageDestroy');
  }

  onForeground() {
    Log.log('TestAbility onForeground');
  }

  onBackground() {
    Log.log('TestAbility onBackground');
  }
};