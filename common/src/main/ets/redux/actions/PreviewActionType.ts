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

const TAG: string = 'PreviewAction';

export class PreviewActionType {
  public static readonly LOAD_SURFACE_DONE = TAG + '_' + 'LOAD_SURFACE_DONE';
  public static readonly CHANGE_X_COMPONENT_AUTO = TAG + '_' + 'CHANGE_X_COMPONENT_AUTO';
  public static readonly SET_LEM_MODE_ICON = TAG + '_' + 'SET_LEM_MODE_ICON';
  public static readonly CHANGE_PREVIEW_SIZE_ANIM = TAG + '_' + 'CHANGE_PREVIEW_SIZE_ANIM';
  public static readonly UPDATE_PREVIEW_AREA_ATTRS = TAG + '_' + 'UPDATE_PREVIEW_AREA_ATTRS';
  public static readonly HIDE_X_COMPONENT = TAG + '_' + 'HIDE_X_COMPONENT';
}