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

import { Action } from '../../redux/actions/Action'
import { CameraSwitchController } from './CameraSwitchController'
import { getStore } from '../../redux/store'
import { Log } from '../../utils/Log'
import MultiCameraDialog from '../customdialog/MultiCameraDialog'
import deviceInfo from '@ohos.deviceInfo'

let localState = (state) => {
  return {
    mode: state.ModeReducer.mode,
    uiEnable: state.ContextReducer.uiEnable,
    cameraPosition: state.CameraReducer.cameraPosition,
    videoState: state.RecordReducer.videoState,
  }
}

let localDispatcher = (dispatch) => {
  return {
    changeCameraPosition: (cameraPosition: string) => {
      dispatch(Action.uiState(false))
      dispatch(Action.switchCamera(cameraPosition))
      dispatch(Action.resetZoomRatio(1))
    },
  }
}

let storageCameraId = AppStorage.Link('storageCameraId')

class StateStruct {
  mode
  uiEnable
  cameraPosition
  videoState
  changeCameraPosition : Function
}

@Component
export struct CameraSwitchButton {
  private TAG: string = '[CameraSwitchButton]:'
  @State state: StateStruct = new StateStruct()
  @State deviceType: string = deviceInfo.deviceType
  @StorageLink('storageCameraId') storageCameraId: string = ''

  icon: Resource = $r('app.media.small_switch_camera')
  mWidth: number
  mHeight: number
  mMargin: number
  type: ButtonType
  stateEffect: boolean
  cameraSwitchController: CameraSwitchController = new CameraSwitchController()
  multiDialogController: CustomDialogController = new CustomDialogController({
    builder: MultiCameraDialog({
      cancel: this.existView.bind(this),
      deviceType: $deviceType
    }),
    autoCancel: true,
    alignment:DialogAlignment.Center,
    customStyle: true,
    cancel: this.existView
  })

  aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().connect(localState, localDispatcher)(this.state)
    this.cameraSwitchController.getParam()
    this.icon = this.cameraSwitchController.icon
    this.mWidth = this.cameraSwitchController.width
    this.mHeight = this.cameraSwitchController.height
    this.mMargin = this.cameraSwitchController.margin
    this.type = this.cameraSwitchController.type
    this.stateEffect = this.cameraSwitchController.stateEffect
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  private openMultiDialog() {
    Log.info(`${this.TAG} openMultiDialog E`)
    this.multiDialogController.open()
    Log.info(`${this.TAG} openMultiDialog X`)
  }

  private existView() {}

  build() {
    Column() {
      Stack() {
        Image($r('app.media.small_switch_camera'))
          .width('67.5%').aspectRatio(1)
          .clip(new Circle({ width: '100%', height: '100%' }))
        Column() {}.width(44).height(44)
          .border({ width: 1, color: Color.White, radius: 22, style: BorderStyle.Solid })
      }
      .width('100%').height('100%').enabled(this.state.uiEnable)
      .onClick(() => {
        Log.info(`${this.TAG} onClick invoke E`)
        Log.info(`${this.TAG} this.state.videoState: ${this.state.videoState}, this.state.mode: ${this.state.mode}`)
        Log.info(`${this.TAG} this.state.cameraPosition: ${this.state.cameraPosition}`)
        if (this.state.videoState === 'beforeTakeVideo') {
          if (this.state.mode === 'MULTI') {
            this.openMultiDialog()
          } else {
            globalThis.switchCameraTime = new Date().getTime()
            if (this.state.cameraPosition !== 'BACK') {
              this.state.changeCameraPosition('BACK')
              this.storageCameraId = 'BACK'
            } else {
              this.state.changeCameraPosition('FRONT')
              this.storageCameraId = 'FRONT'
            }
          }
        }
        Log.info(`${this.TAG} onClick invoke X`)
      })
    }.width(44).aspectRatio(1)
  }
}