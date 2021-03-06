/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

export class Voice {
  public static readonly ALIAS = 'CaptureMute'
  public static readonly DEFAULT_VALUE = '0'
  public static readonly SOUND = Voice.DEFAULT_VALUE
  public static readonly MUTE = '1'
  public static readonly RECORD_START_URI = 'file://system/etc/record_start.ogg'
  public static readonly RECORD_STOP_URI = 'file://system/etc/record_stop.ogg'
  public static readonly CAPTURE_URI = 'file://system/etc/capture.ogg'
}