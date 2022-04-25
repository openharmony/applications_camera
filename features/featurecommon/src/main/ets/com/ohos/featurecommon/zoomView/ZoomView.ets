/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import display from '@ohos.display';

import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import getStore from '../../../../../../../../../common/src/main/ets/default/redux/store'
import {Action} from '../../../../../../../../../common/src/main/ets/default/redux/actions/Action'

let localState = (state) => {
  return {
    photoZoomOpacity: state.UiReducer.photoZoomOpacity,
    mode: state.ModeReducer.mode,
    videoState: state.RecordReducer.videoState,
    cameraPosition: state.CameraReducer.cameraReducer,
    isShowPressScrollDetailPhotoButton: state.UiReducer.isShowPressScrollDetailPhotoButton,
    zoomRatio: state.UiReducer.zoomRatio,
    minZoomRatio: state.UiReducer.minZoomRatio,
    maxZoomRatio: state.UiReducer.maxZoomRatio,
    scrollDetailsBox: state.UiReducer.scrollDetailsBox,
    isPhotoZoomDetails: state.UiReducer.isPhotoZoomDetails,
    photoDetailsOffsetX: state.UiReducer.photoDetailsOffsetX,
    photoDetailsOffsetXInit: state.UiReducer.photoDetailsOffsetXInit,
  }
}

let localDispatcher = (dispatch) => {
  return {
    updateShowPressScrollDetailPhotoButton: (isShow: boolean) => {
      dispatch(Action.UpdateShowPressScrollDetailPhotoButton(isShow))
    },
    updateShowZoomText: (isShow: boolean) => {
      dispatch(Action.UpdateShowZoomTextFlag(isShow))
    },
    updatePhotoZoomDetailsFlag: (flag: boolean) => {
      dispatch(Action.UpdatePhotoZoomDetailsFlag(flag))
    },
    updateScrollDetailsBox: (value: number) => {
      dispatch(Action.UpdateScrollDetailsBox(value))
    },
    initPhotoDetailsOffsetX: (value: number) => {
      dispatch(Action.InitPhotoDetailsOffsetX(value))
    },
    updatePhotoDetailsOffsetX: (value: number) => {
      dispatch(Action.UpdatePhotoDetailsOffsetX(value))
    },
    updateZoomRatio: (zoomRatio: number) => {
      dispatch(Action.ChangeZoomRatio(zoomRatio))
    }
  }
}

@Component
export struct ZoomView {
  private TAG: string = '[ZoomView]:'

  @State state: any = {}

  build() {}
}