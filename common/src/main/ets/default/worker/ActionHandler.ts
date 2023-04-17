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

import { Log } from '../utils/Log'
import { EventBus } from './eventbus/EventBus'
import { EventBusManager } from './eventbus/EventBusManager'

// todo 后续考虑EventBus可能出现的消息堵塞问题
export class ActionHandler {
  private TAG = '[ActionHandler]:'
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  // 在worker线程中通过EventBus发送action，相关后台能力需要注册对应的action.type
  public handleAction(action: any) {
    Log.info(`${this.TAG} handle action: ${JSON.stringify(action)}`)
    this.appEventBus.emit(action.type, [action.data])
  }
}