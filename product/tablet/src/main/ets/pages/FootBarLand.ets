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
import { ComponentPosition }  from '@ohos/common/src/main/ets/default/utils/ComponentPosition'
import { EventBus }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus'
import { EventBusManager }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager'
import { getStore, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store'
import { Log } from '@ohos/common/src/main/ets/default/utils/Log'
import { ShutterButtonLand } from '@ohos/common/src/main/ets/default/featurecommon/shutterbutton/ShutterButtonLand'
import { ThumbnailView } from '@ohos/common/src/main/ets/default/featurecommon/thumbnail/ThumbnailView'
import { ControlLand } from './ControlLand'


let footBarLandState = (state: OhCombinedState) => {
  return {
    platformCapability: state.CameraInitReducer.platformCapability,
    videoState: state.RecordReducer.videoState,
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall,
    showZoomLabelValue: state.ZoomReducer.showZoomLabelValue,
    xComponentHeight: state.PreviewReducer.xComponentHeight,
  }
}

let footBarLandDispatcher = (dispatch) => {
  return {}
}

class StateStruct {
  platformCapability
  videoState
  isThirdPartyCall
  showZoomLabelValue
  xComponentHeight
}

type ScreenSizeType = {
  width: number
  height: number
}

@Component
export struct FootBarLand {
  private TAG: string = '[FootBarLand]:'

  @State state: StateStruct = new StateStruct()
  @State isRecording: boolean = false
  @Link screenSize: ScreenSizeType

  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  private async onRecordStart(data) {
    Log.info(`${this.TAG} onRecordStart E`)
    this.isRecording = true
    Log.info(`${this.TAG} onRecordStart X`)
  }

  private async onRecordStop(data) {
    Log.info(`${this.TAG} onRecordStop E`)
    this.isRecording = false
    Log.info(`${this.TAG} onRecordStop X`)
  }

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().connect(footBarLandState, footBarLandDispatcher)(this.state)
    this.isRecording = false
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
    return!this.isRecording && !this.state.isThirdPartyCall &&
    this.state.videoState !== "startTakeVideo" && this.state.videoState !== "pauseTakeVideo"
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Column() {
      }.width('100%').height(ComponentPosition.getControlHeight(this.screenSize.width, this.screenSize.height))

      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        if (this.state.platformCapability?.mCameraCount > 1 && !this.isRecording && deviceInfo.deviceType !== "default") {
          CameraSwitchButton()
        } else {
          Column() {
          }.width('44').aspectRatio(1)
        }
        ShutterButtonLand({ screenSize: $screenSize })
        Column() {
          ThumbnailView()
        }.width(44).aspectRatio(1).visibility(this.isThumbnailViewVisibility() ? Visibility.Visible : Visibility.Hidden)
      }.width('100%')
      .height(ComponentPosition.getFootBarHeight(this.screenSize.width, this.screenSize.height, this.state.xComponentHeight))
      .margin({
        top: ComponentPosition.getFootBarMargin(this.screenSize.width, this.screenSize.height, this.state.xComponentHeight),
        bottom: ComponentPosition.getFootBarMargin(this.screenSize.width, this.screenSize.height, this.state.xComponentHeight)
      })
      .offset(ComponentPosition.getFootBarPosition(this.state.xComponentHeight))

      if (this.state.videoState === "beforeTakeVideo" && this.state.showZoomLabelValue) {
        ControlLand({ screenSize: $screenSize })
          .offset({ x: 0, y: 0 })
      } else {
        Column() {
        }.width('100%').height(ComponentPosition.getControlHeight(this.screenSize.width, this.screenSize.height))
      }
    }.width(98).height('100%')
  }
}