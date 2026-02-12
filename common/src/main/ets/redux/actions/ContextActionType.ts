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

const PREFIX: string = 'CONTEXT_ACTION_';

export class ContextActionType {
  public static readonly ABILITY_ON_FOREGROUND = PREFIX + 'ABILITY_ON_FOREGROUND';
  public static readonly ABILITY_ACTIVE = PREFIX + 'ABILITY_ACTIVE';
  public static readonly ABILITY_ON_BACKGROUND = PREFIX + 'ABILITY_ON_BACKGROUND';
  public static readonly ABILITY_ON_INTRO = PREFIX + 'ABILITY_ON_INTRO';
  public static readonly ABILITY_ON_NEW_WANT = PREFIX + 'ABILITY_ON_NEW_WANT';
  public static readonly ABILITY_ON_CREATE = PREFIX + 'ABILITY_ON_CREATE';
  public static readonly ABILITY_ON_DESTROY = PREFIX + 'ABILITY_ON_DESTROY';
  public static readonly STAGE_ON_ACCEPT_WANT = PREFIX + 'STAGE_ON_ACCEPT_WANT';
  public static readonly STAGE_ON_CONF_UPDATE = PREFIX + 'STAGE_ON_CONF_UPDATE';
  public static readonly STAGE_ON_MEM_LEVEL = PREFIX + 'STAGE_ON_MEM_LEVEL';
  public static readonly CHANGE_WINDOW_EVENT_TYPE = PREFIX + 'CHANGE_WINDOW_EVENT_TYPE';
  public static readonly CHANGE_EXTENSION_WINDOW_EVENT_TYPE = PREFIX + 'CHANGE_EXTENSION_WINDOW_EVENT_TYPE';
  public static readonly DEV_ON_SHUTDOWN = PREFIX + 'DEV_ON_SHUTDOWN';
  public static readonly UPDATE_SCREEN_ON_STATE = PREFIX + 'CONTEXT_ACTION_UPDATE_SCREEN_ON_STATE';
  public static readonly UPDATE_SAVE_POWER_MODE_STATE = PREFIX + 'UPDATE_SAVE_POWER_MODE_STATE';
  public static readonly RESET_SAVE_MODE_TIMER = PREFIX + 'RESET_SAVE_MODE_TIMER';
  public static readonly VOLUME_KEY_UP = PREFIX + 'VOLUME_KEY_UP';
  public static readonly SCREEN_LOCKED_STATE = PREFIX + 'SCREEN_LOCKED_STATE';
  public static readonly HIGH_CONTRAST_TEXT_STATE = PREFIX + 'HIGH_CONTRAST_TEXT_STATE';

}
