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

import type { UiStateMode } from '../redux/actions/Action';
import { Action } from '../redux/actions/Action';
import { CameraService } from '../camera/CameraService';
import type { EventBus } from '../worker/eventbus/EventBus';
import { EventBusManager } from '../worker/eventbus/EventBusManager';
import { WorkerManager } from '../worker/WorkerManager';

export abstract class BaseFunction {
  protected mCameraService: CameraService = CameraService.getInstance();
  protected mWorkerManager: WorkerManager = new WorkerManager();
  protected mEventBus: EventBus = EventBusManager.getInstance().getEventBus();

  protected enableUi(): void {
    this.mWorkerManager.postMessage(Action.uiState(true));
  }

  protected disableUi(): void {
    this.mWorkerManager.postMessage(Action.uiState(false));
  }

  protected enableUiWithMode(uiStateMode: UiStateMode): void {
    this.mWorkerManager.postMessage(Action.uiStateWithMode(true, uiStateMode));
  }

  protected disableUiWithMode(uiStateMode: UiStateMode): void {
    this.mWorkerManager.postMessage(Action.uiStateWithMode(false, uiStateMode));
  }

  abstract load(): void

  abstract unload(): void
}