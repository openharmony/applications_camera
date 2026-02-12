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

const TAG: string = 'UuidUtil';

/**
 * @file:生成一个随机的ID
 */
export class UuidUtil {
  private static readonly HEXADECIMAL: number = 16;
  private static readonly SUB_LENGTH: number = 2;

  /**
   * uuid
   * @return {number} - uuid
   */
  static getUuid(): string {
    let uuid;
    uuid = Math.random().toString(this.HEXADECIMAL).substr(this.SUB_LENGTH);
    return uuid;
  }

  static async sleep(time: number): Promise<void> {
    await new Promise(resolve => setTimeout(resolve, time));
  }
}
