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

import { Log } from '../../utils/Log';
import type { ActionData } from '../actions/Action';
import { EventBusManager } from '../../worker/eventbus/EventBusManager';
import type { Middleware } from '../core';
import type { Dispatch } from '../store';

const TAG = '[reduxWorkerMiddle]:';
const ACTION_LENGTH: number = 2;

/**
 * Middleware to emit async operation like switching camera and so on.
 *
 * @param store the created old store
 * @returns (next: Dispatch) => (action: AnyAction) => anyAction
 */
export const eventBusMiddle: Middleware = () => (next: Dispatch) => (action: ActionData) => {
  const uiAction = { type: action.type,
    data: action.data };

  //  EventBusManager.getInstance().getEventBus().emit(action.type, [action.data])
  const result = next(uiAction);
  if (Object.keys(action).length >= ACTION_LENGTH && action.isEvent) {
    EventBusManager.getInstance().getEventBus().emit(action.type, [action.data]);
  }
  Log.info(`${TAG} logger: new state`);
  return result;
};