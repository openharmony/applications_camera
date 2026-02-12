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
 * 遥控拍照 action 定义类
 */
export class CollaborateControlActionType {
  public static readonly CHANGE_MODE = PREFIX + 'CHANGE_MODE';
  public static readonly CAPTURE = PREFIX + 'CAPTURE';
  public static readonly VIDEO = PREFIX + 'VIDEO';
  public static readonly SWITCH_CAMERA = PREFIX + 'SWITCH_CAMERA';
  public static readonly ZOOM_IN = PREFIX + 'ZOOM_IN';
  public static readonly ZOOM_OUT = PREFIX + 'ZOOM_OUT';
  public static readonly RESUME = PREFIX + 'RESUME';
  public static readonly START_STREAM = PREFIX + 'START_STREAM';
  public static readonly STOP_STREAM = PREFIX + 'STOP_STREAM';
  public static readonly STREAM_STARTED = PREFIX + 'STREAM_STARTED';
  public static readonly STREAM_END = PREFIX + 'STREAM_END';
  public static readonly STREAM_ERROR = PREFIX + 'STREAM_ERROR';
  public static readonly CLOSE_DIAG = PREFIX + 'CLOSE_DIAG';
  public static readonly CLOSE_SAVE_POWER_MODE = PREFIX + 'CLOSE_SAVE_POWER_MODE';
  public static readonly SOURCE_CONNECT = PREFIX + 'SOURCE_CONNECT';
  public static readonly SOURCE_DISCONNECT = PREFIX + 'SOURCE_DISCONNECT';
  public static readonly PHOTO_BROWSER = PREFIX + 'PHOTO_BROWSER';
  public static readonly FOCUS = PREFIX + 'FOCUS';
}