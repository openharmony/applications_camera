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

const PREFIX: string = 'COLLABORATE_ACTION_';

/**
 * 双屏同显 action 定义类
 */
export class CollaborateActionType {
  public static readonly START = PREFIX + 'START';
  public static readonly STOP = PREFIX + 'STOP';
  public static readonly RESET = PREFIX + 'RESET';
  public static readonly SHOW_OR_HIDE_COLLABORATE_ICON = PREFIX + 'SHOW_OR_HIDE_COLLABORATE_ICON';
  public static readonly LOAD_EXTERNAL_SCREEN_BLUR = PREFIX + 'LOAD_EXTERNAL_SCREEN_BLUR';
  public static readonly UN_LOAD_COLLABORATE = PREFIX + 'UN_LOAD_COLLABORATE';
}
