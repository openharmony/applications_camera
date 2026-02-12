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

/* instrument ignore file */
const PREFIX: string = 'LEFT_RIGHT_SWIPE_ACTION_';

export class LeftRightSwipeActionType {
  public static readonly INIT = PREFIX + 'INIT'; // 预留
  public static readonly INITIALIZED = PREFIX + 'INITIALIZED'; // 预留
  public static readonly LONG_CLICK_STATUS_CHANGE = PREFIX + 'LONG_CLICK_STATUS_CHANGE';
  public static readonly BURST = PREFIX + 'BURST';
  public static readonly RECORD = PREFIX + 'RECORD';
  public static readonly LR_SHUTTER_SHOWN_STATUS_CHANGE = PREFIX + 'LR_SHUTTER_SHOWN_STATUS_CHANGE';
  public static readonly RECORD_LOCK_STATUS_CHANGE = PREFIX + 'RECORD_LOCK_STATUS_CHANGE';
  public static readonly RESET = PREFIX + 'RESET';
  public static readonly BURST_ONE = PREFIX + 'BURST_ONE';
  public static readonly BURST_FIRST = PREFIX + 'BURST_FIRST';
  public static readonly FORCE_EXIT_LR_BURST = PREFIX + 'FORCE_EXIT_LR_BURST';
  public static readonly FORCE_EXIT_LR_RECORD = PREFIX + 'FORCE_EXIT_LR_RECORD';
  public static readonly BURST_SOUND_END = PREFIX + 'BURST_END';
  public static readonly UPDATE_LR_SWIPE_HORIZON_ARRANGE = PREFIX + 'UPDATE_LR_SWIPE_HORIZON_ARRANGE';
  public static readonly MIRROR_UI_STATUS_CHANGE = PREFIX + 'MIRROR_UI_STATUS_CHANGE';
  public static readonly NEED_STOP_QUICK_THUMB = PREFIX + 'NEED_STOP_QUICK_THUMB';
  public static readonly NEED_STOP_FRAME_SHUTTER_END = PREFIX + 'NEED_STOP_FRAME_SHUTTER_END';
  public static readonly CANCEL_CLICK_DOWN_CAPTURE = PREFIX + 'CANCEL_CLICK_DOWN_CAPTURE';
  public static readonly RESET_LIVE_PHOTO_LOTTIE_BY_BURST_STOP = PREFIX + 'RESET_LIVE_PHOTO_LOTTIE_BY_BURST_STOP';
  public static readonly BLOCK_UI_WHEN_FAST_IN_OUT = PREFIX + 'BLOCK_UI_WHEN_FAST_IN_OUT';

}
