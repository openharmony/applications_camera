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
import lazy { ActionData } from './Action';
import lazy { PreviewActionType } from './PreviewActionType';

export class PreviewAction {

  public static loadSurfaceDone(): ActionData {
    return {
      isEvent: true,
      type: PreviewActionType.LOAD_SURFACE_DONE,
      data: {}
    };
  }

  public static changeXComponentAuto(width: number, height: number): ActionData {
    return {
      isEvent: true,
      type: PreviewActionType.CHANGE_X_COMPONENT_AUTO,
      data: { xComponentWidth: width, xComponentHeight: height }
    };
  }

  public static setLemModeIcon(dir: number): ActionData {
    return {
      isEvent: true,
      type: PreviewActionType.SET_LEM_MODE_ICON,
      data: { dir: dir }
    };
  }

  public static changePreviewSizeAnim(): ActionData {
    return {
      isEvent: true,
      type: PreviewActionType.CHANGE_PREVIEW_SIZE_ANIM,
      data: {}
    };
  }

  public static updatePreviewAreaAttrs(): ActionData {
    return {
      isEvent: true,
      type: PreviewActionType.UPDATE_PREVIEW_AREA_ATTRS,
      data: {}
    };
  }

  public static hideXComponent(): ActionData {
    return {
      isEvent: true,
      type: PreviewActionType.HIDE_X_COMPONENT,
      data: {}
    };
  }
}