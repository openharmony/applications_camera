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

import lazy { ModeType } from './ModeType';
import lazy { EditedMoreModeData } from './MoreModeConfigData';

export class ModeListManager {
  private static sInstance: ModeListManager;
  private modeList: ModeType[] = [];

  private constructor() {
  }

  public static getInstance(): ModeListManager {
    if (!ModeListManager.sInstance) {
      ModeListManager.sInstance = new ModeListManager();
    }
    return ModeListManager.sInstance;
  }

  public init(list: ModeType[]): void {
    this.modeList = list;
  }

  public getModeList(): ModeType[] {
    return this.modeList;
  }

  public getModeNameList(): Resource[] {
    const names: Resource[] = [];
    this.modeList.forEach((mode: ModeType) => {
      names.push(this.getModeName(mode));
    });
    return names;
  }

  public getModeName(mode: ModeType): Resource {
    return EditedMoreModeData.get(mode)?.name;
  }

  public modifyModeList(mode: ModeType): void {
    this.modeList[this.modeList.length - 1] = mode;
  }

  public includes(mode: ModeType): boolean {
    return this.modeList.includes(mode);
  }
}