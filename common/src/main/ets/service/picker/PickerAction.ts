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
import lazy { CommonEventData } from '../../component/commonevent/CommonEventManager';
import type { ActionData } from '../../redux/actions/Action';
import lazy { PickerActionType } from '../../redux/actions/PickerActionType';
import lazy { image } from '@kit.ImageKit';

const PREFIX: string = 'PICKER_ACTION_';

export class PickerAction {

  public static exitPickerWithoutResults(): ActionData {
    return {
      isEvent: true,
      type: PickerActionType.EXIT_PICKER_WITHOUT_RESULTS,
      data: {}
    };
  }

  public static learnMoreSecurityCamera(): ActionData {
    return {
      isEvent: true,
      type: PickerActionType.LEARN_MORE_SECURITY_CAMERA,
      data: {}
    };
  }

  public static extensionPickerClose(data: CommonEventData): ActionData {
    return {
      isEvent: true,
      type: PickerActionType.EXTENSION_PICKER_CLOSE,
      data: { isPicker: data.isPicker, isClose: data.isClosePicker }
    };
  }

  public static showPickerView(): ActionData {
    return {
      isEvent: true,
      type: PickerActionType.SHOW_PICKER_VIEW,
      data: {}
    };
  }

  public static photoReceived(photo: image.PixelMap): ActionData {
    return {
      isEvent: true,
      type: PickerActionType.PHOTO_RECEIVED,
      data: { photo: photo }
    };
  }
}