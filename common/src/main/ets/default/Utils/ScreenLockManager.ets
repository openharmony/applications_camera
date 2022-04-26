/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import commonEvent from "@ohos.commonEvent";

import { CLog } from '../Utils/CLog'
import { CommonEventSubscriber } from "commonEvent/commonEventSubscriber";
import { debounce } from "./Decorators";
import { EventBus } from "./EventBus";
import EventBusManager from "./EventBusManager";

const SCREEN_COMMON_EVENT_INFO = {
  events: [commonEvent.Support.COMMON_EVENT_SCREEN_OFF, commonEvent.Support.COMMON_EVENT_SCREEN_ON],
};
const debounceTimeout = 500;

export class ScreenLockManager {
  private TAG: string = '[ScreenLockManager]:'
  public static readonly SCREEN_CHANGE_EVENT = 'SCREEN_CHANGE_EVENT'
  mSubscriber: CommonEventSubscriber | undefined;
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  async init() {
    CLog.log(`${this.TAG} init`)
    this.mSubscriber = await commonEvent.createSubscriber(SCREEN_COMMON_EVENT_INFO);
    commonEvent.subscribe(this.mSubscriber, (err, data) => {
      if (err.code != 0) {
        CLog.log(`${this.TAG} Can't handle screen change, err: ${JSON.stringify(err)}`);
        return;
      }
      CLog.log(`${this.TAG} screenChange, err: ${JSON.stringify(err)} data: ${JSON.stringify(data)}`);
      switch (data.event) {
        case commonEvent.Support.COMMON_EVENT_SCREEN_OFF:
          CLog.log(`${this.TAG} COMMON_EVENT_SCREEN_OFF`)
          this.notifyScreenEvent(false);
          break;
        case commonEvent.Support.COMMON_EVENT_SCREEN_ON:
          this.notifyScreenEvent(true);
          CLog.log(`${this.TAG} COMMON_EVENT_SCREEN_ON`)
          break;
        default:
          CLog.log(`${this.TAG} unknow event`);
      }
    });
  }

  @debounce(debounceTimeout)
  notifyScreenEvent(isScreenOn: boolean) {
    this.appEventBus.emit(ScreenLockManager.SCREEN_CHANGE_EVENT, [isScreenOn]);
    CLog.log(`${this.TAG} publish ${ScreenLockManager.SCREEN_CHANGE_EVENT} screenState: ${isScreenOn}`);
  }
}

export default ScreenLockManager;