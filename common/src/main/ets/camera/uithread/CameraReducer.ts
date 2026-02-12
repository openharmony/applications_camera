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
import camera from '@ohos.multimedia.camera';
import lazy { ActionData } from '../../redux/actions/Action';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { execReduxReducer, initReduxStateMap } from '../../redux/ReducerUtil';
import lazy { OhCombinedState } from '../../redux/ReduxConfig';
import lazy { getStates } from '../../redux/Store';
import lazy { CameraRunningState } from './CameraAction';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';

const TAG = 'CameraReducer';

export type CameraState = {
  cameraRunningState: CameraRunningState,
  cameraPosition: camera.CameraPosition,
  isColdStart: boolean,
  cameraErrorCode: number, //相机框架底层上报error code
  cameraErrorMsg: string, // 相机框架底层上报error msg
  isCameraActive: boolean,
  isFrameStarted: boolean
};

const cameraStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initCameraStateMap(): Map<string, object> {
  const initState: CameraState = {
    cameraRunningState: CameraRunningState.UNINITIALIZED,
    cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK,
    isColdStart: true,
    cameraErrorCode: -1,
    cameraErrorMsg: '',
    isCameraActive: false,
    isFrameStarted: false
  };
  return initReduxStateMap(initState, cameraStateMap);
}

const cameraReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setReducerMapStartRunningState(): void {
  cameraReducerMap.set(CameraActionType.INIT, (action: ActionData) => {
    return {
      cameraRunningState: CameraRunningState.INITIALIZED,
      cameraPosition: action.data.cameraPosition,
      isColdStart: action.data.isDeferred ? true : getStates().get('cameraReducer', 'isColdStart')
    };
  });

  cameraReducerMap.set(CameraActionType.INITIALIZED, (action: ActionData) => {
    if (getStates().get('cameraReducer', 'cameraRunningState') === CameraRunningState.INITIALIZING) {
      return {
        cameraRunningState: CameraRunningState.INITIALIZED
      };
    }
    return undefined;
  });

  cameraReducerMap.set(CameraActionType.START, (action: ActionData) => {
    return {
      cameraRunningState: CameraRunningState.STARTING
    };
  });

  cameraReducerMap.set(CameraActionType.WARM_START, (action: ActionData) => {
    return {
      cameraRunningState: CameraRunningState.STARTING
    };
  });

  cameraReducerMap.set(CameraActionType.WARM_START_WITH_MODE_AND_POS, (action: ActionData) => {
    if (!!action.data.cameraPosition) {
      return {
        cameraRunningState: CameraRunningState.STARTING, cameraPosition: action.data.cameraPosition
      };
    } else {
      return {
        cameraRunningState: CameraRunningState.STARTING
      };
    }
  });

  cameraReducerMap.set(CameraActionType.CHANGE_MODE, (action: ActionData) => {
    let cameraRunningState = getStates().get('cameraReducer', 'cameraRunningState');
    if (cameraRunningState === CameraRunningState.STARTED ||
      cameraRunningState === CameraRunningState.UNINITIALIZED) {
      return {
        cameraRunningState: CameraRunningState.STARTING
      };
    }
    return undefined;
  });

  cameraReducerMap.set(CameraActionType.CHANGE_OUTPUT_TYPE, (action: ActionData) => {
    if (getStates().get('cameraReducer', 'cameraRunningState') === CameraRunningState.STARTED) {
      return {
        cameraRunningState: CameraRunningState.STARTING
      };
    }
    return undefined;
  });

  cameraReducerMap.set(CameraActionType.SWITCH_CAMERA, (action: ActionData) => {
    if (AppStorage.Get('restoreFlag')) {
      return {
        cameraPosition: action.data.cameraPosition
      };
    }
    return {
      cameraRunningState: CameraRunningState.STARTING, cameraPosition: action.data.cameraPosition
    };
  });

  cameraReducerMap.set(CameraActionType.SWITCH_CAMERA_CHANGE_MODE, (action: ActionData) => {
    return {
      cameraRunningState: CameraRunningState.STARTING, cameraPosition: action.data.cameraPosition
    };
  });

  cameraReducerMap.set(CameraActionType.RESTART, (action: ActionData) => {
    const tricollapsStatusChange: boolean = action.data.tricollapsStatusChange;
    if (tricollapsStatusChange && getStates().get('cameraReducer', 'cameraRunningState') === CameraRunningState.UNINITIALIZED) {
      return {
        cameraRunningState: CameraRunningState.STARTED
      };
    }
    if (getStates().get('cameraReducer', 'cameraRunningState') === CameraRunningState.STARTED && !AppStorage.get('restoreFlag')) {
      return {
        cameraRunningState: CameraRunningState.STARTING
      };
    }
    return undefined;
  });

  cameraReducerMap.set(CameraActionType.STARTED, (action: ActionData) => {
    if (getStates().get('cameraReducer', 'cameraRunningState') === CameraRunningState.STARTING) {
      return {
        cameraRunningState: CameraRunningState.STARTED, isColdStart: false,
        isCameraActive: true,
      };
    }
    return undefined;
  });
}

function setCameraReducerMap(): void {
  cameraReducerMap.set(CameraActionType.RELEASE, (action: ActionData) => {
    if (getStates().get('cameraReducer', 'cameraRunningState') === CameraRunningState.STARTED) {
      return {
        cameraRunningState: CameraRunningState.UNINITIALIZED,
        isCameraActive: false,
      };
    }
    return undefined;
  });

  cameraReducerMap.set(CameraActionType.RELEASED, (action: ActionData) => {
    if (getStates().get('cameraReducer', 'cameraRunningState') === CameraRunningState.RELEASING) {
      return {
        cameraRunningState: CameraRunningState.UNINITIALIZED
      };
    }
    return undefined;
  });

  cameraReducerMap.set(CameraActionType.BREAK, (action: ActionData) => {
    if (getStates().get('cameraReducer', 'cameraRunningState') === CameraRunningState.INITIALIZED) {
      return {
        cameraRunningState: CameraRunningState.UNINITIALIZED, isColdStart: false
      };
    }
    return undefined;
  });

  cameraReducerMap.set(CameraActionType.RESET, (action: ActionData) => {
    if (getStates().get('cameraReducer', 'cameraRunningState') === CameraRunningState.INITIALIZED) {
      return {
        cameraRunningState: CameraRunningState.UNINITIALIZED
      };
    }
    return undefined;
  });

  cameraReducerMap.set(CameraActionType.CLOSE, (action: ActionData) => {
    return {
      cameraRunningState: CameraRunningState.UNINITIALIZED,
      isCameraActive: false,
    };
  });

  cameraReducerMap.set(ContextActionType.ABILITY_ON_FOREGROUND, (action: ActionData) => {
    return {
      isColdStart: false
    };
  });

  cameraReducerMap.set(ContextActionType.ABILITY_ON_BACKGROUND, (action: ActionData) => {
    return {
      isColdStart: false
    };
  });

  cameraReducerMap.set(CameraActionType.RECOVER_CAMERA, (action: ActionData) => {
    return {
      cameraPosition: action.data.cameraPosition
    };
  });

  cameraReducerMap.set(CameraActionType.ERROR, (action: ActionData) => {
    return {
      cameraErrorCode: action.data.code,
      cameraErrorMsg: action.data.msg
    };
  });

  cameraReducerMap.set(CameraActionType.PREEMPTION_WITH_ERROR, (action: ActionData) => {
    return {
      isCameraActive: false
    };
  });

  cameraReducerMap.set(ActionType.ACTION_ON_PREVIEW_FRAME_START, (action: ActionData) => {
    return {
      isFrameStarted: action.data.isPreviewFrameStart
    };
  });

  cameraReducerMap.set(ActionType.ACTION_SWITCH_CAMERA_CHANGE_MODE_ONLY, (action: ActionData) => {
    return {
      cameraPosition: action.data.cameraPosition
    };
  });
}

export function cameraReducer(state: OhCombinedState, action: ActionData): string[] {
  if (cameraReducerMap.size <= 0) {
    setReducerMapStartRunningState();
    setCameraReducerMap();
  }
  return execReduxReducer(state, action, cameraReducer.name, cameraReducerMap, initCameraStateMap);
}