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

import commonEvent from "@ohos.commonEvent"

import { Log } from '../../utils/Log'
import { EventBus } from '../../worker/eventbus/EventBus'
import { EventBusManager } from '../../worker/eventbus/EventBusManager'

const SCREEN_COMMON_EVENT_INFO = {
    events: [commonEvent.Support.COMMON_EVENT_SCREEN_OFF],
};


export class ScreenLockManager {
    private TAG: string = '[ScreenLockManager]:'
    public static readonly SCREEN_CHANGE_EVENT = 'SCREEN_CHANGE_EVENT'
    mSubscriber: any;
    appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

    async init() {
        Log.log(`${this.TAG} init`)
        this.mSubscriber = await commonEvent.createSubscriber(SCREEN_COMMON_EVENT_INFO);
        commonEvent.subscribe(this.mSubscriber, (err, data) => {
            if (err.code != 0) {
                Log.error(`${this.TAG} Can't handle screen change, err: ${JSON.stringify(err)}`);
                return;
            }
            Log.info(`${this.TAG} screenChange, err: ${JSON.stringify(err)} data: ${JSON.stringify(data)}`);
            switch (data.event) {
                case commonEvent.Support.COMMON_EVENT_SCREEN_OFF:
                    Log.log(`${this.TAG} COMMON_EVENT_SCREEN_OFF`)
                    this.notifyScreenEvent(false);
                    break;
                default:
                    Log.log(`${this.TAG} unknow event`);
            }
        });
    }

    close() {
        commonEvent.unsubscribe(this.mSubscriber)
    }

    notifyScreenEvent(isScreenOn: boolean) {
        this.appEventBus.emit(ScreenLockManager.SCREEN_CHANGE_EVENT, [isScreenOn]);
        Log.log(`${this.TAG} publish ${ScreenLockManager.SCREEN_CHANGE_EVENT} screenState: ${isScreenOn}`);
    }
}

export default ScreenLockManager;