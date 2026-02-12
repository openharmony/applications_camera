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

/*
 * 拟用于沉浸式事件归一化,谨慎新增父子组件共存Type
 * */
export enum UIOperationType {
  NULL = 'NULL',
  TAB_BAR = 'TAB_BAR',
  PREVIEW = 'PREVIEW',
  EXTEND_BAR = 'EXTEND_BAR',
  REAL_TIMELAPSE_BAR = 'PRO_BAR',
  PARAM_BAR = 'PARAM_BAR',
  ZOOM_BAR = 'ZOOM_BAR',
  PINCH_ZOOM = 'PINCH_ZOOM',
  MODE_BAR = 'MODE_BAR',
  FOOT_BAR = 'FOOT_BAR',
  PRO_BAR = 'PRO_BAR',
  TIMELAPSE = 'TIMELAPSE',
  EXPOSURE = 'EXPOSURE',
  LR_SWIPE = 'LR_SWIPE',
  VLOG_BAR = 'VLOG_BAR',


  // 逃脱组件枚举
  NIGHT_SCENE_CAPTURE_BUTTON = 'NIGHT_SCENE_CAPTURE_BUTTON',
  CAPTURE_BUTTON = 'CAPTURE_BUTTON',
  RECORD_BUTTON = 'RECORD_BUTTON',
}