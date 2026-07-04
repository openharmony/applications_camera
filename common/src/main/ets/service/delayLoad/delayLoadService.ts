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
import lazy { MemoryService } from "../Memory/MemoryService";

/* instrument ignore file */
const TAG: 'DelayLoadService' = 'DelayLoadService';

type StartedTask = {
  name: string;
  delayMs: number;
  task: () => void;
};

export class DelayLoadService {
  private static instance: DelayLoadService;
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private isOnCreateExecuted: boolean = false;
  private isOnForegroundExecuted: boolean = false;
  private onEventBus: boolean = false;
  private startedTasks: StartedTask[] = [];
  private onCreateTs: number = 0;
  private onForegroundTs: number = 0;

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
    this.startedTasks = [];
    this.onCreateTs = 0;
    this.onForegroundTs = 0;
  }

  public loadFromOnCreate(): void {
    HiLog.i(TAG, 'loadFromOnCreate');
    this.registerEventBus();
    this.isOnCreateExecuted = true;
    this.onCreateTs = Date.now();
  }

  public loadFromOnForeground(): void {
    HiLog.i(TAG, 'loadFromOnForeground');
    this.registerEventBus();
    this.isOnForegroundExecuted = true;
    this.onForegroundTs = Date.now();
  }

  /**
   * Post a task to run AFTER CameraActionType.STARTED.
   *
   * The goal is to reduce cold/warm start critical path latency:
   * keep onCreate/onForeground light, then defer non-critical work here.
   */
  public postAfterStarted(name: string, task: () => void, delayMs: number = 0): void {
    if (!name || typeof task !== 'function') {
      return;
    }
    this.startedTasks.push({ name, task, delayMs: Math.max(0, delayMs) });
  }

  private onStarted(): void {
    HiLog.i(TAG, 'delayLoadOnStarted');
    // onCreate执行逻辑延后到started
    if (this.isOnCreateExecuted) {
      HiLog.begin(TAG, 'isOnCreateExecuted');
      if (this.onCreateTs > 0) {
        HiLog.i(TAG, `startupLatency(from onCreate to STARTED)=${Date.now() - this.onCreateTs}ms`);
      }
      HiLog.end(TAG, 'isOnCreateExecuted');
    }
    this.isOnCreateExecuted = false;

    // onForeground执行逻辑延后到started
    if (this.isOnForegroundExecuted) {
      HiLog.begin(TAG, 'isOnForegroundExecuted');
      if (this.onForegroundTs > 0) {
        HiLog.i(TAG, `completeLatency(from onForeground to STARTED)=${Date.now() - this.onForegroundTs}ms`);
      }
      HiLog.end(TAG, 'isOnForegroundExecuted');
    }
    this.isOnForegroundExecuted = false;

    if (this.startedTasks.length > 0) {
      const tasks = this.startedTasks.slice();
      this.startedTasks = [];
      tasks.forEach((t: StartedTask) => {
        setTimeout(() => {
          HiLog.begin(TAG, `task:${t.name}`);
          try {
            t.task();
          } catch (e) {
            HiLog.e(TAG, `task:${t.name} failed: ${JSON.stringify(e)}`);
          }
          HiLog.end(TAG, `task:${t.name}`);
        }, t.delayMs);
      });
    }

    // Lightweight post-start defaults
    setTimeout(() => {
      MemoryService.getInstance().updateApplicationStorageSpace();
    }, 200);

    this.unInit();
  }
}