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

const TAG: string = 'FocusExposureActionType';

export class FocusExposureActionType {
  public static readonly ACTION_CHANGE_FOCUS_DATA = 'ACTION_CHANGE_FOCUS_DATA';
  public static readonly ACTION_HIDE_FOCUS_BOX = 'ACTION_HIDE_FOCUS_BOX';
  public static readonly SET_METERING_POINT = 'SET_METERING_POINT';
  public static readonly ACTION_UPDATE_SHOW_EXPOSURE_RING = 'ACTION_UPDATE_SHOW_EXPOSURE_RING';
  public static readonly ACTION_SET_FOCUS_MODE = 'ACTION_SET_FOCUS_MODE';
  public static readonly ACTION_LOCK_FOCUS_MODE = 'ACTION_LOCK_FOCUS_MODE';
  public static readonly ACTION_SMART_CONTROL_LOCK = 'ACTION_SMART_CONTROL_LOCK';
  public static readonly ACTION_RESET_SMART_CONTROL_LOCK = 'ACTION_RESET_SMART_CONTROL_LOCK';
  public static readonly ACTION_UPDATE_SHOW_EXPOSURE_AND_FOCUS_ICON = 'ACTION_UPDATE_SHOW_EXPOSURE_AND_FOCUS_ICON';
  public static readonly ACTION_UPDATE_SHOW_FOCUS: string = 'ACTION_UPDATE_SHOW_FOCUS';
  public static readonly ACTION_UPDATE_SHOW_EXPOSURE: string = 'ACTION_UPDATE_SHOW_EXPOSURE';
  public static readonly ACTION_UPDATE_LOCK_LEVEL: string = 'ACTION_UPDATE_LOCK_LEVEL';
  public static readonly ACTION_UPDATE_FOCUS_STATE: string = 'ACTION_UPDATE_FOCUS_STATE';
  public static readonly ACTION_CHANGE_EXPOSURE_DATA: string = 'ACTION_CHANGE_EXPOSURE_DATA';
  public static readonly ACTION_UPDATE_FOCUS_STATE_DETECT_SUPPORTED: string =
    'ACTION_UPDATE_FOCUS_STATE_DETECT_SUPPORTED';
  public static readonly ACTION_UPDATE_FOCUS_LOCKED: string = 'ACTION_UPDATE_FOCUS_LOCKED';
  public static readonly ACTION_RESET_FOCUS_EXPOSURE: string = 'ACTION_RESET_FOCUS_EXPOSURE';
}