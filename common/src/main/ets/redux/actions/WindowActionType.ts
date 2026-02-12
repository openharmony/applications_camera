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

const PREFIX: string = 'WINDOW_ACTION_';

export class WindowActionType {
  public static readonly ON_CLASS_READY = PREFIX + 'ON_CLASS_READY';
  public static readonly ON_SIZE_CHANGE = PREFIX + 'ON_SIZE_CHANGE';
  public static readonly ON_LOCK_ROTATION_STATUS_CHANGE = PREFIX + 'ON_LOCK_ROTATION_STATUS_CHANGE';
  public static readonly WINDOW_LOCK_DIRECTION = PREFIX + 'WINDOW_LOCK_DIRECTION';
  public static readonly ON_ROTATION_LOCKED = PREFIX + 'ON_ROTATION_LOCKED';
  public static readonly REFRESH_UX = PREFIX + 'REFRESH_UX';
  public static readonly WINDOW_STATUS = PREFIX + 'WINDOW_STATUS';
  public static readonly WINDOW_VISIBILITY_STATUS = PREFIX + 'WINDOW_VISIBILITY_STATUS';
  public static readonly PICKER_WINDOW_TYPE = PREFIX + 'PICKER_WINDOW_TYPE';
  public static readonly CHANGE_TOP_AVOID_AREA = PREFIX + 'CHANGE_TOP_AVOID_AREA';

}