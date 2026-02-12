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

const PREFIX: string = 'CAPTURE_ACTION_';

export class CaptureActionType {
  public static readonly CAPTURE = PREFIX + 'CAPTURE';
  public static readonly CAPTURE_LEM_COLLAPS = PREFIX + 'CAPTURE_LEM_COLLAPS';
  public static readonly PHOTO_ON_SAVE = PREFIX + 'PHOTO_ON_SAVE';
  public static readonly CONFIRM_CAPTURE = PREFIX + 'CONFIRM_CAPTURE';
  public static readonly CONFIRM_BURST_CAPTURE = PREFIX + 'CONFIRM_BURST_CAPTURE';
  public static readonly SYNC_PICKER_BUFFER = PREFIX + 'SYNC_PICKER_BUFFER';
  public static readonly VOLUME_KEY_EVENT = PREFIX + 'VOLUME_KEY_EVENT';
  public static readonly PICKER_VIEW_ROTATION = PREFIX + 'PICKER_VIEW_ROTATION';
  public static readonly RICH_CAPTURE_NEXT = PREFIX + 'RICH_CAPTURE_NEXT';
  public static readonly FLASH_BLACK_DONE = PREFIX + 'FLASH_BLACK_DONE';
  public static readonly IS_SMILE_EVENT = PREFIX + 'IS_SMILE_EVENT';
  public static readonly IS_REMOTECAPTURE_EVENT = PREFIX + 'IS_REMOTECAPTURE_EVENT';
  public static readonly SELFIE_STICK_EVENT = PREFIX + 'SELFIE_STICK_EVENT';
  public static readonly SAVE_POWER_MDE_EVENT = PREFIX + 'SAVE_POWER_MDE_EVENT';
  public static readonly NIGHT_CAPTURE = PREFIX + 'NIGHT_CAPTURE';
  // 倒计时音效
  public static readonly ACTION_PLAY_COUNT_DOWN_TIMER_EFFECT = 'ACTION_PLAY_COUNT_DOWN_TIMER_EFFECT';
  public static readonly IS_READY_FOR_NEXT_AUTO_CAPTURE = PREFIX + 'IS_READY_FOR_NEXT_AUTO_CAPTURE';

}