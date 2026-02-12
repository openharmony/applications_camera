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

import lazy { HiLog } from './HiLog';

const TAG: string = 'TaskExecutor';

/* instrument ignore file */
export class TaskExecutor {
  private mTasks: Promise<void>[] = new Array();

  public constructor() {
    HiLog.i(TAG, 'create new TaskExecutor.');
  }

  public addTask(promise: Promise<void>): void {
    this.mTasks.push(promise);
  }

  public addTaskFunction(func: () => Promise<void>): void {
    this.mTasks.push(new Promise<void>(async resolve => {
      await func();
      resolve();
    }));
  }

  public clearTask(): void {
    this.mTasks = new Array();
  }

  public async executeTasks(): Promise<void[]> {
    const results: void[] = await Promise.all(this.mTasks);
    return results;
  }
}