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

import lazy { OhCombinedState } from '../../redux';
import type { ActionData } from '../../redux/actions/Action';
import lazy { SettingViewActionType } from '../../redux/actions/SettingViewActionType';
import lazy { execReduxReducer, initReduxStateMap } from '../../redux/ReducerUtil';

export type SettingViewState = {
  isShowSettingView: boolean,
  isTriggeredByBack: boolean
};

const settingViewStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initSettingViewStateMap(): Map<string, object> {
  const initState: SettingViewState = {
    isShowSettingView: false,
    isTriggeredByBack: false,
  };
  return initReduxStateMap(initState, settingViewStateMap);
}

const settingViewReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setSettingViewReducerMap(): void {
  settingViewReducerMap.set(SettingViewActionType.ACTION_SHOW_SETTING_VIEW, (action: ActionData) => {
    return {
      isShowSettingView: action.data.isShowSettingView,
      isTriggeredByBack: action.data.isTriggeredByBack
    };
  });
}

export function settingViewReducer(state: OhCombinedState, action: ActionData): string[] {
  if (settingViewReducerMap.size <= 0) {
    setSettingViewReducerMap();
  }
  return execReduxReducer(state, action, settingViewReducer.name, settingViewReducerMap, initSettingViewStateMap);
}