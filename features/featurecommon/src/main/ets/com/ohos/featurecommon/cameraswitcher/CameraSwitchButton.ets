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

import {CameraSwitchController} from './CameraSwitchController.ets'
import {CameraService} from '../../../../../../../../../common/src/main/ets/default/Camera/CameraService'
import MultiCameraDialog from '../customDialog/MultiCameraDialog.ets'

@Component
export struct CameraSwitchButton {
  @State icon: Resource = $r("app.media.small_switch_camera")
  width: number
  height: number
  margin: number
  type: ButtonType
  stateEffect: boolean
  cameraSwitchController = new CameraSwitchController()
  private cameraService = CameraService.getInstance()
  @Link surfaceId: number
  @Link cameraPosition: string
  @Link btnOpacity_first: number
  @Link btnOpacity_sec: number
  @Link btnSwitch: boolean
  @Link btnSwitchSec: boolean
  @Link xComponentChangeFlag: boolean
  @Link previewImage: string
  @Link cameraId: string
  @Link isSwitchBackground: boolean
  @State switchAnimationTimer: number = 0
  multiDialogController: CustomDialogController = new CustomDialogController({
    builder: MultiCameraDialog({
      action: this.onAccept,
      cameraId:$cameraId,
      cameraPosition:$cameraPosition,
      xComponentChangeFlag: $xComponentChangeFlag
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    cancel: this.existView
  })

  aboutToAppear() {
    this.cameraSwitchController.getParam()
    this.icon = this.cameraSwitchController.icon
    this.width = this.cameraSwitchController.width
    this.height = this.cameraSwitchController.height
    this.margin = this.cameraSwitchController.margin
    this.type = this.cameraSwitchController.type
    this.stateEffect = this.cameraSwitchController.stateEffect
  }

  private openMultiDialog() {
    console.info('CameraSwitchButton.openMultiDialog called')
    this.multiDialogController.open()
  }

  public existView() {

  }
  private onAccept() {

  }

  build() {
    Column() {
      Stack() {
        Image($r('app.media.small_switch_camera'))
          .width('67.5%')
          .aspectRatio(1)
          .clip(new Circle({ width: '100%', height: '100%' }))
        Column() {

        }
        .border({ width: 2, color: 0xffffff, radius: 20, style: BorderStyle.Solid })
          .width('100%')
          .height('100%')
      }
      .width('100%')
        .height('100%')
        .onClick(() => {
          if (this.previewImage == 'MULTI') {
            this.openMultiDialog()
          } else {
            this.xComponentChangeFlag = !this.xComponentChangeFlag
            if (this.cameraPosition !== 'BACK') {
              if (this.cameraPosition === 'ORIGIN') {
                this.cameraPosition = 'FRONT'
              } else {
                this.cameraPosition = 'BACK'
              }
            } else {
              this.cameraPosition = 'FRONT'
            }
          }
        })
    }
    .width(40)
      .aspectRatio(1)
  }
}