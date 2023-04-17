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

import deviceInfo from '@ohos.deviceInfo'
import { Action }  from '@ohos/common/src/main/ets/default/redux/actions/Action'
import { CameraSwitchButton }  from '@ohos/common/src/main/ets/default/featurecommon/cameraswitcher/CameraSwitchButton'
import { EventBus }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus'
import { EventBusManager }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager'
import { getStore, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store'
import { Log } from '@ohos/common/src/main/ets/default/utils/Log'
import { ShutterButton } from '@ohos/common/src/main/ets/default/featurecommon/shutterbutton/ShutterButton'
import { ThumbnailView } from '@ohos/common/src/main/ets/default/featurecommon/thumbnail/ThumbnailView'

let footBarState = (state: OhCombinedState) => {
  return {
    platformCapability: state.CameraInitReducer.platformCapability,
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall,
    videoState: state.RecordReducer.videoState,
    showZoomLabelValue: state.ZoomReducer.showZoomLabelValue,
    mode: state.ModeReducer.mode
  }
}

let footBarDispatcher = (dispatch) => {
  return {}
}

class StateStruct {
  platformCapability
  isThirdPartyCall
  videoState
  showZoomLabelValue
  mode
  isRecording
}

@Component
export struct FootBar {
  private TAG: string = '[FootBar]:'

  @State state: StateStruct = new StateStruct()

  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  private async onRecordStart(data) {
    Log.info(`${this.TAG} onRecordStart E`)
    this.state.isRecording = true
    Log.info(`${this.TAG} onRecordStart X`)
  }

  private async onRecordStop(data) {
    Log.info(`${this.TAG} onRecordStop E`)
    this.state.isRecording = false
    Log.info(`${this.TAG} onRecordStop X`)
  }

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().connect(footBarState, footBarDispatcher)(this.state)
    this.state.isRecording = false
    this.appEventBus.on(Action.ACTION_RECORD_START, this.onRecordStart.bind(this))
    this.appEventBus.on(Action.ACTION_RECORD_STOP, this.onRecordStop.bind(this))
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_RECORD_START, this.onRecordStart.bind(this))
    this.appEventBus.off(Action.ACTION_RECORD_STOP, this.onRecordStop.bind(this))
    Log.info(`${this.TAG} aboutToDisappear X`)
  }

  private isThumbnailViewVisibility() {
    return!this.state.isRecording && !this.state.isThirdPartyCall &&
    this.state.videoState !== "startTakeVideo" && this.state.videoState !== "pauseTakeVideo"
  }

  private isPhoneSwitchShow(): boolean {
    return deviceInfo.deviceType !== 'default' && this.state.platformCapability?.mCameraCount > 1 &&
    !this.state.isRecording
  }

  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.Center
    }) {
      Column() {
        ThumbnailView()
      }.width(44).aspectRatio(1).visibility(this.isThumbnailViewVisibility() ? Visibility.Visible : Visibility.Hidden)

      ShutterButton()
      if (this.isPhoneSwitchShow()) {
        CameraSwitchButton()
      } else {
        Column() {
        }
        .width('44')
        .aspectRatio(1)
      }
    }
    .height(96)
    .opacity(100)
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .visibility(this.state.showZoomLabelValue ? Visibility.Visible : Visibility.Hidden)
  }
}
