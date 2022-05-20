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

import { CameraSwitchButton
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/cameraswitcher/CameraSwitchButton'
import { CLog } from '../../../../../../common/src/main/ets/default/Utils/CLog'
import { ControlLand } from './ControlLand'
import { EventBus } from '../../../../../../common/src/main/ets/default/Utils/EventBus'
import EventBusManager from '../../../../../../common/src/main/ets/default/Utils/EventBusManager'
import { ShutterButtonLand
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/shutterbutton/ShutterButtonLand'
import { ThumbnailView
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/thumbnail/ThumbnailView'
import getStore from '../../../../../../common/src/main/ets/default/redux/store'
import { Action } from '../../../../../../common/src/main/ets/default/redux/actions/Action'

let footBarLandState = (state) => {
  return {
    platformCapability: state.CameraInitReducer.platformCapability
  }
}

let footBarLandDispatcher = (dispatch) => {
  return {}
}

@Component
export struct FootBarLand {
  private TAG: string = '[FootBarLand]:'

  @State state: any = {}

  private mConnect: any
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  private async onRecordStart(data) {
    CLog.info(`${this.TAG} onRecordStart E`)
    this.state.isRecording = true
    CLog.info(`${this.TAG} onRecordStart X`)
  }

  private async onRecordStop(data) {
    CLog.info(`${this.TAG} onRecordStop E`)
    this.state.isRecording = false
    CLog.info(`${this.TAG} onRecordStop X`)
  }

  private aboutToAppear(): void {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(footBarLandState, footBarLandDispatcher)(this.state)
    this.state.isRecording = false
    this.appEventBus.on(Action.ACTION_RECORD_START, this.onRecordStart.bind(this))
    this.appEventBus.on(Action.ACTION_RECORD_STOP, this.onRecordStop.bind(this))
    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  private aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_RECORD_START, this.onRecordStart.bind(this))
    this.appEventBus.off(Action.ACTION_RECORD_STOP, this.onRecordStop.bind(this))
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.Center
    }) {
      Column() {}.width('100%').height(160)
      Flex({
        direction: FlexDirection.Column,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center
      }) {
        if (this.state.platformCapability?.mCameraCount > 1 && !this.state.isRecording) {
          CameraSwitchButton()
        } else {
          Column() {
          }.width('40').aspectRatio(1)
        }
        ShutterButtonLand()
        if (!this.state.isRecording) {
          ThumbnailView()
        }
      }.width('100%').height(260).margin({
        top: $r("sys.float.ohos_id_text_paragraph_margin_xl"),
        bottom: $r("sys.float.ohos_id_text_paragraph_margin_xl")
      })

      if (this.state.videoState === "beforeTakeVideo") {
        ControlLand()
      } else {
        Column() {
        }.width('100%').height(160)
      }
    }.width(128).height('100%')
  }
}
