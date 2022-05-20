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

import {CameraSwitchController} from './CameraSwitchController'
//import {CameraService} from '../../../../../../../../../common/src/main/ets/default/Camera/CameraService'
import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import MultiCameraDialog from '../customDialog/MultiCameraDialog'
import getStore from '../../../../../../../../../common/src/main/ets/default/redux/store'
import {Action} from '../../../../../../../../../common/src/main/ets/default/redux/actions/Action'

let localState = (state) => {
  return {
    mode: state.ModeReducer.mode,
    uiEnable: state.UiReducer.uiEnable,
    cameraPosition: state.CameraReducer.cameraPosition,
    xComponentChangeFlag: state.PreviewReducer.xComponentChangeFlag,
    videoState: state.RecordReducer.videoState,
  }
}

let localDispatcher = (dispatch) => {
  return {
    changeCameraPosition: (cameraPosition: string) => {
      dispatch(Action.UiState(false))
      dispatch(Action.SetCameraPosition(cameraPosition))
    },
    updateXComponentChangeFlag: (xComponentChangeFlag: boolean) => {
      dispatch(Action.UpdateXComponentChangeFlag(xComponentChangeFlag))
    },
  }
}

@Component
export struct CameraSwitchButton {
  private TAG: string = '[CameraSwitchButton]:'
  private mConnect: any
  private multiDialogController: CustomDialogController

  icon: Resource = $r('app.media.small_switch_camera')
  width: number
  height: number
  margin: number
  type: ButtonType
  stateEffect: boolean
  cameraSwitchController = new CameraSwitchController()

  @State state: any = {}

  private aboutToAppear() {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    this.cameraSwitchController.getParam()
    this.icon = this.cameraSwitchController.icon
    this.width = this.cameraSwitchController.width
    this.height = this.cameraSwitchController.height
    this.margin = this.cameraSwitchController.margin
    this.type = this.cameraSwitchController.type
    this.stateEffect = this.cameraSwitchController.stateEffect
    this.multiDialogController = new CustomDialogController({
      builder: MultiCameraDialog(),
      autoCancel: true,
      alignment:DialogAlignment.Center,
      customStyle: true,
      cancel: this.existView
    })
    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  private aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  private openMultiDialog() {
    CLog.info(`${this.TAG} openMultiDialog E`)
    this.multiDialogController.open()
    CLog.info(`${this.TAG} openMultiDialog X`)
  }

  private existView() {}

  build() {
    Column() {
      Stack() {
        Image($r('app.media.small_switch_camera'))
          .width('67.5%').aspectRatio(1)
          .clip(new Circle({ width: '100%', height: '100%' }))
        Column() {}.width('100%').height('100%')
          .border({ width: 1, color: Color.White, radius: 20, style: BorderStyle.Solid })
      }
      .width('100%').height('100%').enabled(this.state.uiEnable)
      .onClick(() => {
        CLog.info(`${this.TAG} onClick invoke E`)
        CLog.info(`${this.TAG} this.state.videoState: ${this.state.videoState}, this.state.mode: ${this.state.mode}`)
        CLog.info(`${this.TAG} this.state.cameraPosition: ${this.state.cameraPosition}`)
        if (this.state.videoState === 'beforeTakeVideo') {
          if (this.state.mode === 'MULTI') {
            this.openMultiDialog()
          } else {
            this.state.updateXComponentChangeFlag(!this.state.xComponentChangeFlag)
            if (this.state.cameraPosition !== 'BACK') {
              if (this.state.cameraPosition === 'ORIGIN') {
                this.state.changeCameraPosition('FRONT')
              } else {
                this.state.changeCameraPosition('BACK')
              }
            } else {
              this.state.changeCameraPosition('FRONT')
            }
          }
        }
        CLog.info(`${this.TAG} onClick invoke X`)
      })
    }.width(44).aspectRatio(1)
  }
}