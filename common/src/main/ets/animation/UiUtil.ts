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

const TAG: string = 'UiUtil';

export class UiUtil {
  static resetGeometryTransitionParamsSize(): void {
    LocalStorage.getShared().setOrCreate<number>('geometryScale', 1);
    LocalStorage.getShared().setOrCreate<number>('geometryOffsetX', 0);
    LocalStorage.getShared().setOrCreate<number>('geometryOffsetY', 0);
  }

  static setGeometryTransitionParamsVisible(): void {
    LocalStorage.getShared().setOrCreate<number>('geometryOpacity', 1);
  }

  static setGeometryTransitionParamsInvisible(): void {
    LocalStorage.getShared().setOrCreate<number>('geometryOpacity', 0);
  }

  static setBorderVisible(): void {
    LocalStorage.getShared().setOrCreate<string>('browserBorderColor', '#ffffffff');
  }

  static setBorderInvisible(): void {
    LocalStorage.getShared().setOrCreate<string>('browserBorderColor', '#00ffffff');
  }
}