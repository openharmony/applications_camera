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
import { EventBus } from '../../../../../../common/src/main/ets/default/Utils/EventBus'
import EventBusManager from '../../../../../../common/src/main/ets/default/Utils/EventBusManager'
import { ShutterButton
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/shutterbutton/ShutterButton'
import { ThumbnailView
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/thumbnail/ThumbnailView'
import getStore from '../../../../../../common/src/main/ets/default/redux/store'
import { Action } from '../../../../../../common/src/main/ets/default/redux/actions/Action'

let footBarState = (state) => {
  return {
    platformCapability: state.CameraInitReducer.platformCapability
  }
}

let footBarDispatcher = (dispatch) => {
  return {}
}

@Component
export struct FootBar {
  private TAG: string = '[FootBar]:'

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

  public aboutToAppear(): void {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(footBarState, footBarDispatcher)(this.state)
    this.state.isRecording = false
    this.appEventBus.on(Action.ACTION_RECORD_START, this.onRecordStart.bind(this))
    this.appEventBus.on(Action.ACTION_RECORD_STOP, this.onRecordStop.bind(this))
    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  public aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_RECORD_START, this.onRecordStart.bind(this))
    this.appEventBus.off(Action.ACTION_RECORD_STOP, this.onRecordStop.bind(this))
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.Center
    }) {
      if (!this.state.isRecording) {
        ThumbnailView()
      } else {
        Column() {
        }.width('44').aspectRatio(1)
      }
      ShutterButton()
      if (this.state.platformCapability?.mCameraCount > 1 && !this.state.isRecording) {
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
    .padding({ top: 10, bottom: 10})
  }
}
