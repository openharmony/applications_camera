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

const PREFIX: string = 'CAMERA_ACTION_';

export class CameraActionType {
  public static readonly INIT = PREFIX + 'INIT';
  public static readonly INIT_CAMERA_LIST = PREFIX + 'INIT_CAMERA_LIST';
  public static readonly INITIALIZED = PREFIX + 'INITIALIZED';
  public static readonly START = PREFIX + 'START';
  public static readonly WARM_START = PREFIX + 'WARM_START';
  public static readonly CREATE_AND_OPEN_CAMERA_INPUT = PREFIX + 'CREATE_AND_OPEN_CAMERA_INPUT';
  public static readonly WARM_START_WITH_MODE_AND_POS = PREFIX + 'WARM_START_WITH_MODE_AND_POS';
  public static readonly RESTART = PREFIX + 'RESTART';
  public static readonly RECOVERY_RESTART_APP = PREFIX + 'RECOVERY_RESTART_APP';
  public static readonly SWITCH_CAMERA = PREFIX + 'SWITCH_CAMERA';
  public static readonly RECOVER_CAMERA = PREFIX + 'RECOVER_CAMERA';
  public static readonly CHANGE_MODE = PREFIX + 'CHANGE_MODE';
  public static readonly CHANGE_OUTPUT_TYPE = PREFIX + 'CHANGE_OUTPUT_TYPE';
  public static readonly SWITCH_CAMERA_CHANGE_MODE = PREFIX + 'SWITCH_CAMERA_CHANGE_MODE';
  public static readonly STARTED = PREFIX + 'STARTED';
  public static readonly RELEASE = PREFIX + 'RELEASE';
  public static readonly CLOSE = PREFIX + 'CLOSE';
  public static readonly STOP_PREVIEW = PREFIX + 'STOP_PREVIEW';
  public static readonly RELEASED = PREFIX + 'RELEASED';
  public static readonly BREAK = PREFIX + 'BREAK';
  public static readonly RESET = PREFIX + 'RESET';
  public static readonly ERROR = PREFIX + 'ERROR';
  public static readonly ON_CAMERA_STATUS = PREFIX + 'ON_CAMERA_STATUS';
  public static readonly PREEMPTION = PREFIX + 'PREEMPTION';
  public static readonly PREEMPTION_WITH_ERROR = PREFIX + 'PREEMPTION_WITH_ERROR';
  public static readonly ON_LENS_BLOCKING = PREFIX + 'ON_LENS_BLOCKING';
  public static readonly ON_LENS_DIRTY = PREFIX + 'ON_LENS_DIRTY';
  public static readonly SWITCH_COLLABORATION = PREFIX + 'SWITCH_COLLABORATION';
  public static readonly SUPER_PRIVACY_MODE_ENABLED = PREFIX + 'SUPER_PRIVACY_MODE_ENABLED';
  public static readonly RELEASE_RESTART_AFTER_PHOTO_SAVED = PREFIX + 'RELEASE_RESTART_AFTER_PHOTO_SAVED';
  // 手机跌落 镜头自动回收 用户选择继续使用恒星镜头
  public static readonly KEEP_USING_STELLAR_LENSES = PREFIX + 'KEEP_USING_STELLAR_LENSES';
  // 悬浮窗和分屏下锁预览接口不生效，需要适配预览方向
  public static readonly SET_PREVIEW_ROTATION = PREFIX + 'SET_PREVIEW_ROTATION';
}