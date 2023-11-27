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

import type { ActionData } from '../actions/Action';
import { Action } from '../actions/Action';

export type CaptureState = {
  captureBtnScale: number
};

const initState = {
  captureBtnScale: 0
};

export function captureReducer(state = initState, action: ActionData): CaptureState {
  switch (action.type) {
    case Action.ACTION_UPDATE_CAPTURE_BTN_SCALE:
      return {
        ...state, captureBtnScale: action.data.captureBtnScale
      };
    default:
      return state;
  }
  return state;
}
;