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
import type { ActionData } from '../../redux/actions/Action';
import lazy { TipActionType } from '../../redux/actions/TipActionType';

export class TipAction {
  public static showTip(message: unknown, duration: number, isBlack: boolean, imgSrc?: unknown, isStitching?: boolean,
    isLongText: boolean = false, isPickerShield?: boolean): ActionData {
    return {
      type: TipActionType.ACTION_SHOW_TIP,
      data: {
        message,
        duration,
        isBlack,
        imgSrc,
        isStitching,
        isLongText,
        isPickerShield
      },
      isEvent: true
    };
  }

  public static hideTip(): ActionData {
    return {
      type: TipActionType.ACTION_HIDE_TIP,
      data: {},
      isEvent: true
    };
  }
}