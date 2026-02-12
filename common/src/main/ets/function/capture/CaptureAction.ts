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
import type camera from '@ohos.multimedia.camera';
import lazy { SelfieStickKey } from '../../service/selfieStick/SelfieStickService';
import lazy { CaptureActionType } from '../../redux/actions/CaptureActionType';

const PREFIX: string = 'CAPTURE_ACTION_';

export class CaptureAction {

  public static capture(): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.CAPTURE,
      data: {}
    };
  }

  public static captureLemCollaps(): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.CAPTURE_LEM_COLLAPS,
      data: {}
    };
  }

  public static richCaptureNext(): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.RICH_CAPTURE_NEXT,
      data: {}
    };
  }

  public static confirmCapture(): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.CONFIRM_CAPTURE,
      data: {}
    };
  }

  public static confirmCaptureBurst(): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.CONFIRM_BURST_CAPTURE,
      data: {}
    };
  }

  public static photoOnSave(resourceUri: string): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.PHOTO_ON_SAVE,
      data: { resourceUri: resourceUri }
    };
  }

  public static pickerViewRotation(rotation: camera.ImageRotation): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.PICKER_VIEW_ROTATION,
      data: { rotation: rotation }
    };
  }

  public static volumeKeyEvent(isDown: boolean): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.VOLUME_KEY_EVENT,
      data: { isDown: isDown }
    };
  }

  public static isFlashBlackDone(): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.FLASH_BLACK_DONE,
      data: {}
    };
  }

  public static isSmileEvent(): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.IS_SMILE_EVENT,
      data: {}
    };
  }

  public static selfieStickEvent(key: SelfieStickKey): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.SELFIE_STICK_EVENT,
      data: { key: key }
    };
  }

  public static isRemoteCaptureEvent(): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.IS_REMOTECAPTURE_EVENT,
      data: {}
    };
  }

  public static exitSavePowerModeEvent(): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.SAVE_POWER_MDE_EVENT,
      data: {}
    };
  }

  public static nightCapture(): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.NIGHT_CAPTURE,
      data: {}
    };
  }

  public static playCountTimerEffect(): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.ACTION_PLAY_COUNT_DOWN_TIMER_EFFECT,
      data: {}
    };
  }

  public static isReadyForNextAutoCapture(): ActionData {
    return {
      isEvent: true,
      type: CaptureActionType.IS_READY_FOR_NEXT_AUTO_CAPTURE,
      data: {}
    };
  }
}