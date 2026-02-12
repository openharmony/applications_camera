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

// 因ArkTS struct不支持继承，基础方法包装成BaseComponent类型作为struct私有属性持有
export class BaseComponent {
  private static counter = 0;
  private id: string;

  public constructor() {
    this.id = this.generateUniqueId();
  }

  private generateUniqueId(): string {
    // 获取当前时间戳的字符串表示
    const timestamp = Date.now().toString();

    // 获取计数器的值，并递增
    const counterValue = BaseComponent.counter++;
    const counterString = counterValue.toString();

    // 组合时间戳和计数器，作为唯一标识符
    const uniqueId = timestamp + counterString;
    return uniqueId;
  }

  public hashCode(): string {
    return this.id;
  }
}