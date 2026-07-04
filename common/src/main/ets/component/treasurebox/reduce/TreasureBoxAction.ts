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
import type { ActionData } from '../../../redux/actions/Action';
import type { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { TreasureBoxActionType } from '../../../redux/actions/TreasureBoxActionType';

export class TreasureBoxAction {

  // 关闭或打开百宝箱
  public static setTreasureBoxStatus(isOpen: boolean): ActionData {
    return {
      type: TreasureBoxActionType.ACTION_SET_TREASURE_BOX_STATUS,
      data: { isOpen: isOpen }
    };
  }

  // 打开百宝箱某个selector，或关闭百宝箱
  public static changeTreasureBoxSelector(functionId: FunctionId): ActionData {
    return {
      isEvent: true,
      type: TreasureBoxActionType.ACTION_CHANGE_TREASURE_BOX_SELECTOR,
      data: { functionId: functionId }
    };
  }

  public static updateByZoomChanged(): ActionData {
    return {
      isEvent: true,
      type: TreasureBoxActionType.ACTION_CHANGE_WITH_ZOOM,
      data: {}
    };
  }

  public static changeArrowUpDistance(): ActionData {
    return {
      isEvent: true,
      type: TreasureBoxActionType.ACTION_CHANGE_ARROW_UP_DISTANCE,
      data: {}
    };
  }

  public static refreshTreasureBoxView(): ActionData {
    return {
      isEvent: true,
      type: TreasureBoxActionType.ACTION_REFRESH_TREASURE_BOX_VIEW,
      data: {}
    };
  }

  public static proUpdateTreasureBox(): ActionData {
    return {
      isEvent: true,
      type: TreasureBoxActionType.ACTION_PRO_UPDATE_TREASURE_BOX,
      data: {}
    };
  }

  public static closeSecondTreasure(): ActionData {
    return {
      isEvent: true,
      type: TreasureBoxActionType.ACTION_CLOSE_SECOND_TREASURE,
      data: {}
    };
  }
}