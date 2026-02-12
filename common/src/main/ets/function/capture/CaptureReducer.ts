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
import camera from '@ohos.multimedia.camera';
import lazy { OhCombinedState } from '../../redux';
import lazy { execReduxReducer, initReduxStateMap } from '../../redux/ReducerUtil';
import lazy { CaptureActionType } from '../../redux/actions/CaptureActionType';

export type CaptureState = {
  resourceUri: string;
  captureBufferQueueUseCount: number;
  rotation: camera.ImageRotation;
};

const captureStateMap: Map<string, object> = new Map(); // 维护局部state变量

export function initCaptureStateMap(): Map<string, object> {
  const initState = {
    resourceUri: '',
    captureBufferQueueUseCount: 0,
    rotation: camera.ImageRotation.ROTATION_0
  };
  return initReduxStateMap(initState, captureStateMap);
}

const captureReducerMap: Map<string, Function> = new Map(); // 注册action更新state

function setCaptureReducerMap(): void {
  captureReducerMap.set(CaptureActionType.PHOTO_ON_SAVE, (action: ActionData) => {
    return {
      resourceUri: action.data.resourceUri
    };
  });

  captureReducerMap.set(CaptureActionType.PICKER_VIEW_ROTATION, (action: ActionData) => {
    return {
      rotation: action.data.rotation
    };
  });
}

export function captureReducer(state: OhCombinedState, action: ActionData): string[] {
  if (captureReducerMap.size <= 0) {
    setCaptureReducerMap();
  }
  return execReduxReducer(state, action, captureReducer.name, captureReducerMap, initCaptureStateMap);
}