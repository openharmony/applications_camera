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

import {CameraService} from '../../../../../../../../../common/src/main/ets/default/Camera/CameraService'
import EntryComponentForMulti from './EntryComponentForMulti'

@CustomDialog
export default struct MultiCameraDialog {
  private cameraService = CameraService.getInstance()
  @Link cameraId: string
  @Link cameraPosition: string
  @Link xComponentChangeFlag: boolean
  controller: CustomDialogController
  cancel: () => void
  confirm: () => void
  private localList = ['本地（前置）', '本地（后置）']
  private moreList = []
  @State isShowMore: boolean = false

  async aboutToAppear() {
    console.info('MultiCameraDialog aboutToAppear.')
    this.moreList = this.cameraService.getDeviceInfo()
    this.cameraService.getCameraLists().then(() => {
      let cameraList = this.cameraService.cameraListInfo
      this.isShowMore = cameraList.length > 5 ? true : false
    })
  }

  private onChange(): void {
    this.controller.close()
    this.cancel()
  }

  build() {
    Column() {
      Row() {
        Text('选择摄像头')
          .fontSize('20fp')
          .fontColor('#E6000000')
          .fontWeight(FontWeight.Medium)
          .opacity(0.9)
          .padding({ left: 20 })
      }
      .width('100%')
      .height(40)

      Row() {
        Text('已连接设备').fontSize('12fp').fontColor(Color.Gray).padding({ left: 20 })
      }
      .width('100%')
      .height(20)

      List() {
        ForEach(this.localList, (item) => {
          ListItem() {
            EntryComponentForMulti({
              item: item,
              onChange: () => this.onChange(),
              cameraPosition: $cameraPosition,
              xComponentChangeFlag: $xComponentChangeFlag
            })
          }
          .margin({ left: '12vp', right: '12vp' })
          .width('100%')
          .height(48);
        })
      }
      .listDirection(Axis.Vertical)
      .divider({ strokeWidth: 0.5, color: '#33000000', startMargin: 0, endMargin: 12 })
      .margin({ left: '24vp', right: '24vp' })

      Row() {
        Text('更多设备')
          .fontSize('14fp')
          .fontColor('#99FFFFFF')
          .opacity(0.6)
          .fontWeight(FontWeight.Medium)
          .padding({ left: 20 })
      }
      .width('100%')
      .height(20)

      if (this.isShowMore) {
        List() {
          ForEach(this.moreList, (item) => {
            ListItem() {
              EntryComponentForMulti({
                item: item,
                onChange: () => this.onChange(),
                cameraPosition: $cameraPosition,
                xComponentChangeFlag: $xComponentChangeFlag
              });
            }
            .margin({ left: '12vp', right: '12vp' })
            .width('100%')
            .height(48);
          })
        }
        .listDirection(Axis.Vertical)
        .divider({ strokeWidth: 0.5, color: '#33000000', startMargin: 0, endMargin: 12 })
        .margin({ left: '24vp', right: '24vp' })
      }

      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Text($r('app.string.cancel'))
          .fontSize('16fp')
          .fontColor('#1095E8')
          .fontWeight(FontWeight.Medium)
          .height(40)
      }
      .margin({ top: '8vp', bottom: '16vp' })
      .height(56)
      .backgroundColor(0xffffff)
      .onClick(() => {
        this.controller.close()
      })
    }
  }
}