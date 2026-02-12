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

export enum ZIndex {
  SAVE_POWER_MODE = 7, // 其他组件不可比这个更高 如需增加 请保持该组件最高
  SKETCH_INDEX = 6,
  FOCUS_INDEX = 5,
  TOP = 4,
  MIDDLE_TOP = 3,
  MIDDLE_BOTTOM = 2,
  BOTTOM = -1
}