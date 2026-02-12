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
import type { ModeType } from '../../mode/ModeType';
import lazy { OutputType } from '../../function/outputswitcher/OutputType';
import lazy { CommonEventData } from '../../component/commonevent/CommonEventManager';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';

const PREFIX: string = 'CAMERA_ACTION_';

export enum CameraRunningState {
  UNINITIALIZED = 0,
  INITIALIZING = 1, // 该状态暂时弃用
  INITIALIZED = 2,
  STARTING = 3,
  STARTED = 4,
  RELEASING = 5, // 该状态暂时弃用
  BREAK = 6
}

export enum CameraStartType {
  COLD_START = 0,
  WARM_START = 1,
  RESTART = 2,
  SWITCH_CAMERA = 3,
  CHANGE_MODE = 4,
  RECORD = 5, // 录像会重启流，需要审视是否必要这个状态
  SWITCH_CAMERA_CHANGE_MODE = 6, // 切换前后置联动(人像-拍照)模式切换
  WARM_START_WITH_MODE_AND_POS = 7,
  CHANGE_OUTPUT_TYPE = 8, // 拍照/录像切换， 如微距模式
  COLLAPS_CHANGE = 9, // 6.0 火龙果F态体现上，M和半折态关闭，更新managerAssembler
}



export class CameraStartTypeStruct {
  type: CameraStartType = CameraStartType.COLD_START;
}

export interface closeInfo {
  isNeedSaveRestore?: boolean, // 是否需要下发saveRestore
  isEnterPhotoBrowser?: boolean, // 是否是进入大图触发的close相机
  isNeedDelayClose?: boolean,
  isPcEnterSleep?: boolean, //pc相机进入S4休眠close相机暂时规避
}

export class CameraAction {

  public static init(position: camera.CameraPosition, mode: ModeType, isDeferred: boolean): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.INIT,
      data: { cameraPosition: position, mode: mode, isDeferred: isDeferred, isColdStart: true }
    };
  }

  public static initCameraList(): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.INIT_CAMERA_LIST,
      data: {}
    };
  }

  public static initialized(): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.INITIALIZED,
      data: {}
    };
  }

  public static start(isDeferred: boolean): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.START,
      data: { isDeferred: isDeferred }
    };
  }

  public static createAndOpenCameraInput(position: camera.CameraPosition, mode: ModeType): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.CREATE_AND_OPEN_CAMERA_INPUT,
      data: { position: position, mode: mode }
    };
  }

  public static warmStart(): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.WARM_START,
      data: {}
    };
  }

  public static warmStartWithModeAPos(mode: ModeType, cameraPosition?: camera.CameraPosition): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.WARM_START_WITH_MODE_AND_POS,
      data: { mode: mode, cameraPosition: cameraPosition }
    };
  }

  public static restart(restartData: {
    zoomRatio: number,
    superMacroEnable?: boolean,
    watchMoonEnable?: boolean,
    collaborate?: boolean,
    tricollapsStatusChange?: boolean
  } | number): ActionData {
    let data: Object = restartData;
    if (typeof restartData !== 'object') {
      data = { zoomRatio: restartData };
    }
    return {
      isEvent: true,
      type: CameraActionType.RESTART,
      data
    };
  }

  public static switchCollaboration(collaborated: boolean): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.SWITCH_COLLABORATION,
      data: { collaborated: collaborated}
    };
  }

  public static break(): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.BREAK,
      data: {}
    };
  }

  public static reset(): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.RESET,
      data: {}
    };
  }

  public static switchCamera(position: camera.CameraPosition, keepVideoFlowing?: boolean,
    isVideoRotation?: boolean): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.SWITCH_CAMERA,
      data: { cameraPosition: position, keepVideoFlowing: keepVideoFlowing, isVideoRotation: isVideoRotation }
    };
  }

  public static recoverCamera(position: camera.CameraPosition): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.RECOVER_CAMERA,
      data: { cameraPosition: position }
    };
  }

  public static changeMode(mode: ModeType, isToDefaultWarmStart: boolean = false): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.CHANGE_MODE,
      data: { mode: mode, isToDefaultWarmStart: isToDefaultWarmStart }
    };
  }

  public static changeOutputType(outputType: OutputType): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.CHANGE_OUTPUT_TYPE,
      data: { outputType: outputType }
    };
  }

  public static switchCameraChangeMode(position: camera.CameraPosition, mode: ModeType): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.SWITCH_CAMERA_CHANGE_MODE,
      data: { cameraPosition: position, mode: mode }
    };
  }

  public static started(type: CameraStartType, zoomRatio?: number): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.STARTED,
      data: { type: type, zoomRatio: zoomRatio }
    };
  }

  public static release(isNeedSaveRestore: boolean = false): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.RELEASE,
      data: { isNeedSaveRestore: isNeedSaveRestore }
    };
  }

  public static stopPreview(): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.STOP_PREVIEW,
      data: {}
    };
  }

  public static close(data: closeInfo): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.CLOSE,
      data: {
        isNeedSaveRestore: !!data.isNeedSaveRestore,
        isNeedDelayClose: !!data.isNeedDelayClose,
        isEnterPhotoBrowser: !!data.isEnterPhotoBrowser,
        isPcEnterSleep: !!data.isPcEnterSleep
      }
    };
  }

  public static released(): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.RELEASED,
      data: {}
    };
  }

  public static recoveryRestartApp(): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.RECOVERY_RESTART_APP,
      data: {}
    };
  }

  public static superPrivacyModeEnabled(isEnable: boolean): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.SUPER_PRIVACY_MODE_ENABLED,
      data: { isEnable: isEnable }
    };
  }

  public static error(errorCode: number, errorMsg: string): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.ERROR,
      data: { code: errorCode, msg: errorMsg }
    };
  }

  public static onCameraStatus(cameraStatus: number): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.ON_CAMERA_STATUS,
      data: { cameraStatus: cameraStatus }
    };
  }

  public static preemption(data: CommonEventData): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.PREEMPTION,
      data: { isPicker: data.isPicker, active: data.active }
    };
  }

  public static preemptWithError(): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.PREEMPTION_WITH_ERROR,
      data: {}
    };
  }

  public static onLensBlocking(isCameraOccluded: boolean): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.ON_LENS_BLOCKING,
      data: { isCameraOccluded: isCameraOccluded }
    };
  }

  public static onLensDirty(isCameraLensDirty: boolean): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.ON_LENS_DIRTY,
      data: { isCameraLensDirty: isCameraLensDirty }
    };
  }

  // 拍照后立即重启流场景防丢图机制,图落盘后接续触发重启流操作Action
  public static releaseAndRestartAfterPhotoSaved(mFlowAction: CameraAction, mFlowData: unknown): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.RELEASE_RESTART_AFTER_PHOTO_SAVED,
      data: { flowAction: mFlowAction, flowData: mFlowData }
    };
  }

  // 手机跌落 镜头自动回收 用户选择继续使用恒星镜头
  public static keepUsingStellarLenses(): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.KEEP_USING_STELLAR_LENSES,
      data: {}
    };
  }

  public static setPreviewRotation(): ActionData {
    return {
      isEvent: true,
      type: CameraActionType.SET_PREVIEW_ROTATION,
      data: {}
    }
  }
}