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
import type { ActionData } from '../../redux/actions/Action';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { RenderLocation } from '../../function/core/functionproperty/RenderLocation';
import lazy { TabBarActionType } from '../../redux/actions/TabBarActionType';

export class TabBarAction {

  public static changeTabBarSelector(functionId: FunctionId, renderLocation: RenderLocation): ActionData {
    return {
      type: TabBarActionType.ACTION_CHANGE_TAB_BAR_SELECTOR,
      data: { functionId: functionId, renderLocation: renderLocation }
    };
  }

  public static updateTabBarArr(): ActionData {
    return {
      isEvent: true,
      type: TabBarActionType.ACTION_UPDATE_TAB_BAR_ARR,
      data: {}
    };
  }

  public static updatePositionAndOpacity(isActivelyDoTransAnim: boolean = false): ActionData {
    return {
      isEvent: true,
      type: TabBarActionType.ACTION_UPDATE_TAB_BAR_POS_N_OPA,
      data: { isActivelyDoTransAnim: isActivelyDoTransAnim }
    };
  }

  public static playLottieAnimation(isClicked: boolean = false, functionId: FunctionId = FunctionId.NONE): ActionData {
    return {
      isEvent: true,
      type: TabBarActionType.ACTION_PLAY_LOTTIE_ANIMATION,
      data: { isClicked: isClicked, functionId: functionId }
    };
  }

  public static updateLinkageButton(): ActionData {
    return {
      isEvent: true,
      type: TabBarActionType.ACTION_UPDATE_LINKAGE_BUTTON,
      data: {}
    };
  }

  public static updatePopUpButton(): ActionData {
    return {
      isEvent: true,
      type: TabBarActionType.ACTION_UPDATE_POPUP_BUTTON,
      data: {}
    };
  }

  public static updateTextList(): ActionData {
    return {
      isEvent: true,
      type: TabBarActionType.ACTION_UPDATE_TEXT_LIST,
      data: {}
    };
  }
}