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

import lazy { ModeType } from '../../mode/ModeType';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { ActionData } from '../../redux/actions/Action';
import lazy { CollaborateControlActionType } from '../../redux/actions/CollaborateControlActionType';

const PREFIX: string = 'COLLABORATE_ACTION_';
export const CLICK_DELAY: number = 100;
export const ZOOM_STEP: number = 0.3;

export interface DialogParams {
  show?: boolean, // 展示弹窗
  isCustomStyle: boolean, // 是否自定义风格
  deviceName?: string
}

export type DialogResult = {
  isGranted: boolean,
  isOnce?: boolean
};

/**
 * 遥控拍照 action 定义类
 */
export class CollaborateControlAction {

  public static changeMode(mode: ModeType): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.CHANGE_MODE,
      data: { mode: mode }
    };
  }

  public static capture(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.CAPTURE,
      data: {}
    };
  }

  public static video(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.VIDEO,
      data: {}
    };
  }

  public static switchCamera(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.SWITCH_CAMERA,
      data: {}
    };
  }

  public static zoomIn(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.ZOOM_IN,
      data: {}
    };
  }

  public static zoomOut(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.ZOOM_OUT,
      data: {}
    };
  }

  public static resume(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.RESUME,
      data: {}
    };
  }

  public static startStream(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.START_STREAM,
      data: {}
    };
  }

  public static stopStream(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.STOP_STREAM,
      data: {}
    };
  }

  public static streamStarted(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.STREAM_STARTED,
      data: {}
    };
  }

  public static streamEnd(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.STREAM_END,
      data: {}
    };
  }

  public static streamError(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.STREAM_ERROR,
      data: {}
    };
  }

  public static closeDiag(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.CLOSE_DIAG,
      data: {}
    };
  }

  public static closeSavePowerMode(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.CLOSE_SAVE_POWER_MODE,
      data: {}
    };
  }

  public static sourceConnect(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.SOURCE_CONNECT,
      data: {}
    };
  }

  public static sourceDisconnect(): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.SOURCE_DISCONNECT,
      data: {}
    };
  }

  public static showCommonCaptureDialog(data: DialogParams): ActionData {
    return {
      isEvent: true,
      type: ActionType.ACTION_COMMON_CAPTURE_PERMISSION_DIALOG,
      data: { isCustomStyle: data.isCustomStyle, show: data.show, deviceName: data.deviceName }
    };
  }

  static photoBrowser(isShow: boolean): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.PHOTO_BROWSER,
      data: {isShow : isShow},
    };
  }

  public static focus(x: number, y: number): ActionData {
    return {
      isEvent: true,
      type: CollaborateControlActionType.FOCUS,
      data: { x: x, y: y }
    }
  }
}