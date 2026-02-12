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

import lazy { PlaySound } from "../../component/playsound/playSound";
import lazy { CameraActionType } from "../../redux/actions/CameraActionType";
import lazy { HiLog } from "../../utils/HiLog";
import lazy { BaseComponent } from "../../worker/BaseComponent";
import lazy { EventBus } from "../../worker/eventbus/EventBus";
import lazy { EventBusManager } from "../../worker/eventbus/EventBusManager";
import lazy { AudioSessionService } from "../audioSessionService/AudioSessionService";
import lazy { ContextManager } from "../context/ContextManager";
import lazy { MemoryService } from "../Memory/MemoryService";

/* instrument ignore file */
const TAG: 'DelayLoadService' = 'DelayLoadService';

export class DelayLoadService {
  private static instance: DelayLoadService;
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private isOnCreateExecuted: boolean = false;
  private isOnForegroundExecuted: boolean = false;
  private onEventBus: boolean = false;

  public static getInstance(): DelayLoadService {
    if (!this.instance) {
      this.instance = new DelayLoadService();
    }
    return this.instance;
  }

  private constructor() {
    HiLog.i(TAG, 'DelayLoadService constructor');
    this.registerEventBus();
  }

  private registerEventBus() {
    if (!this.onEventBus) {
      this.mEventBus.on(CameraActionType.STARTED, this.onStarted.bind(this), this.mBase.hashCode());
      this.onEventBus = true;
    }
  }

  public unInit(): void {
    if (this.onEventBus) {
      this.mEventBus.clear(this.mBase.hashCode());
      this.onEventBus = false;
    }
  }

  public loadFromOnCreate(): void {
    HiLog.i(TAG, 'loadFromOnCreate');
    this.registerEventBus();
    this.isOnCreateExecuted = true;
  }

  public loadFromOnForeground(): void {
    HiLog.i(TAG, 'loadFromOnForeground');
    this.registerEventBus();
    this.isOnForegroundExecuted = true;
  }

  private onStarted(): void {
    HiLog.i(TAG, 'delayLoadOnStarted');
    // onCreate执行逻辑延后到started
    if (this.isOnCreateExecuted) {
      HiLog.begin(TAG, 'isOnCreateExecuted');
      HiLog.end(TAG, 'isOnCreateExecuted');
    }
    this.isOnCreateExecuted = false;

    // onForeground执行逻辑延后到started
    if (this.isOnForegroundExecuted) {
      HiLog.begin(TAG, 'isOnForegroundExecuted');
      PlaySound.getInstance().loadSound();
      MemoryService.getInstance().updateApplicationStorageSpace();
      HiLog.end(TAG, 'isOnForegroundExecuted');
    }
    this.isOnForegroundExecuted = false;

    this.unInit();
  }
}