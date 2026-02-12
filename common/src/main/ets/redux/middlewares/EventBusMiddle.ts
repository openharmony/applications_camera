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

import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import type { ActionData } from '../actions/Action';
import type { Dispatch, Middleware } from '../Store';

const TAG: string = 'EventBusMiddle';
const ACTION_LENGTH: number = 2;

/**
 * Middleware to emit async operation like switching camera and so on.
 */
export const eventBusMiddle: Middleware = () => (next: Dispatch) => (action: ActionData) => {
  if (!action) {
    return undefined;
  }
  const result = next(action);
  if (Object.keys(action).length >= ACTION_LENGTH && action.isEvent) {
    EventBusManager.getInstance().getEventBus().emit(action.type, [action.data]);
  }
  return result;
};