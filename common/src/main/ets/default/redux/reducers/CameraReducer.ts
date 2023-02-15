/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import { CameraId } from '../../setting/settingitem/CameraId'
import { Action, ActionData } from '../actions/Action'

export type CameraState = {
  cameraPosition: string,
  curCameraPosition: string,
  cameraId: string,
  curCameraName: string,
  cameraCount: number,
  shutterIcon: Resource
}

const initState: CameraState = {
  cameraPosition: 'BACK',
  curCameraPosition: 'BACK',
  cameraId: '',
  curCameraName: 'BACK',
  cameraCount: 0,
  shutterIcon: $r('app.media.ic_circled_filled')
}

export default function CameraReducer(state = initState, action: ActionData): CameraState {
  switch (action.type) {
  case Action.ACTION_SET_CAMERA_POSITION:
    return { ...state, cameraPosition: action.data.cameraPosition }
  case Action.ACTION_SWITCH_CAMERA:
    return { ...state, cameraPosition: action.data.cameraId }
  case Action.ACTION_UPDATE_CAMERA_POSITION:
    return { ...state, curCameraPosition: action.data.cameraPosition }
  case Action.ACTION_UPDATE_SHUTTER_ICON:
    return { ...state, shutterIcon: action.data.shutterIcon }
    case Action.ACTION_UPDATE_CAMERA_STATUS:
      return { ...state }
  default:
    return state;
  }
}