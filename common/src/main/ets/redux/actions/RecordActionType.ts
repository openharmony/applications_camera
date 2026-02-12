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

const PREFIX: string = 'RECORD_ACTION_';

export class RecordActionType {
  public static readonly INIT = PREFIX + 'INIT'; // 预留
  public static readonly INITIALIZED = PREFIX + 'INITIALIZED'; // 预留
  public static readonly START = PREFIX + 'START';
  public static readonly STARTED = PREFIX + 'STARTED';
  public static readonly PAUSE = PREFIX + 'PAUSE';
  public static readonly WILL_PAUSE = PREFIX + 'WILL_PAUSE';
  public static readonly PAUSED = PREFIX + 'PAUSED';
  public static readonly WILL_RESUME = PREFIX + 'WILL_RESUME';
  public static readonly RESUME = PREFIX + 'RESUME';
  public static readonly RESUMED = PREFIX + 'RESUMED';
  public static readonly STOP = PREFIX + 'STOP';
  public static readonly STOPPED = PREFIX + 'STOPPED';
  public static readonly RELEASE = PREFIX + 'RELEASE'; // 预留
  public static readonly RELEASED = PREFIX + 'RELEASED'; // 预留
  public static readonly ERROR = PREFIX + 'ERROR';
  public static readonly VIDEO_ON_SAVE = PREFIX + 'VIDEO_ON_SAVE';
  public static readonly RESET_PRE_RECORD_STATE = PREFIX + 'RESET_PRE_RECORD_STATE';
  public static readonly EMIT_VIDEO_AUTO_FRAME_RATE = PREFIX + 'EMIT_VIDEO_AUTO_FRAME_RATE';
  public static readonly RECORD_PAUSED = PREFIX + 'RECORD_PAUSED';
  public static readonly UPDATE_RECORDING_TIMER_COMPONENT_LARGE_STATE: string = 'UPDATE_RECORDING_TIMER_COMPONENT_LARGE_STATE';
  public static readonly SAVE_MOVIE_INFO_ASSET_DONE = PREFIX + 'SAVE_MOVIE_INFO_ASSET_DONE';
  public static readonly RECORD_KEEP_FLOWING = PREFIX + 'RECORD_KEEP_FLOWING';
  public static readonly VIDEO_FRAME_END = PREFIX + 'VIDEO_FRAME_END';

}