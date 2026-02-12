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

import type TestRunner from '@ohos.application.testRunner';
import AbilityDelegatorRegistry from '@ohos.application.abilityDelegatorRegistry';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';

const TAG: string = 'OpenHarmonyTestRunner';

let abilityDelegator = undefined;
let abilityDelegatorArguments = undefined;

function translateParamsToString(parameters): string {
  const keySet = new Set([
    '-s class', '-s notClass', '-s suite', '-s it',
    '-s level', '-s testType', '-s size', '-s timeout'
  ]);
  let targetParams = '';
  for (const key in parameters) {
    if (keySet.has(key)) {
      targetParams = `${targetParams} ${key} ${parameters[key]}`;
    }
  }
  return targetParams.trim();
}

async function onAbilityCreateCallback(): Promise<void> {
  HiLog.i(TAG, 'onAbilityCreateCallback.');
}

async function addAbilityMonitorCallback(err: string): Promise<void> {
  HiLog.i(TAG, `addAbilityMonitorCallback : ${JSON.stringify(err)}.`);
}

export default class OpenHarmonyTestRunner implements TestRunner {
  constructor() {
  }

  onPrepare(): void {
    HiLog.i(TAG, 'OpenHarmonyTestRunner OnPrepare .');
  }

  async onRun() {
    HiLog.i(TAG, 'OpenHarmonyTestRunner onRun run.');
    abilityDelegatorArguments = AbilityDelegatorRegistry.getArguments();
    abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
    let testAbilityName = abilityDelegatorArguments.bundleName + '.TestAbility';
    let lMonitor = {
      abilityName: testAbilityName,
      onAbilityCreate: onAbilityCreateCallback,
    };
    abilityDelegator.addAbilityMonitor(lMonitor, addAbilityMonitorCallback);
    let cmd = 'aa start -d 0 -a TestAbility' + ' -b ' + abilityDelegatorArguments.bundleName;
    cmd += ' ' + translateParamsToString(abilityDelegatorArguments.parameters);
    HiLog.i(TAG, 'cmd : ' + cmd);
    abilityDelegator.executeShellCommand(cmd,
      (err: any, d: any) => {
        HiLog.i(TAG, `executeShellCommand : err : ${JSON.stringify(err)}.`);
        HiLog.i(TAG, 'executeShellCommand : data : ' + d.stdResult);
        HiLog.i(TAG, 'executeShellCommand : data : ' + d.exitCode);
      });
    HiLog.i(TAG, 'OpenHarmonyTestRunner onRun end.');
  }
};
