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
/* instrument ignore file */
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import type { ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import { OhCombinedState } from '@ohos/common/src/main/ets/redux/ReduxConfig';
import { execReduxReducer, initReduxStateMap } from '@ohos/common/src/main/ets/redux/ReducerUtil';
import { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';

export type TestState = {
  testVal: number,
  testStr: string
};

const testStateMap: Map<string, object> = new Map();

export function initTestStateMap(): Map<string, object> {
  const initState: TestState = {
    testVal: 0,
    testStr: 'test'
  };
  return initReduxStateMap(initState, testStateMap);
}

const testReducerMap: Map<string, Function> = new Map();

function setTestReducerMap(): void {
  testReducerMap.set(CameraActionType.CHANGE_MODE, (action: ActionData) => {
    return { testVal: 1 };
  });

  testReducerMap.set(ActionType.ACTION_SHOW_PICKER, (action: ActionData) => {
    return { testStr: 'tst' };
  });
}

export function testReducer(state: OhCombinedState, action: ActionData): string[] {
  if (testReducerMap.size <= 0) {
    setTestReducerMap();
  }
  return execReduxReducer(state, action, testReducer.name, testReducerMap, initTestStateMap);
}