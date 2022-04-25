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
import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import EntryComponentForMulti from './EntryComponentForMulti'

@CustomDialog
export default struct MultiCameraDialog {
  private TAG: string = '[MultiCameraDialog]:'
//  private cameraService = CameraService.getInstance()
  @Link cameraId: string
  @Link cameraPosition: string
  @Link xComponentChangeFlag: boolean
  @Link cameraDevice: string
  @Link action:Function
  controller: CustomDialogController
  cancel: () => void
  confirm: () => void
  private localList = ['本地（前置）', '本地（后置）']
  private moreList = []
  @State isShowMore: boolean = false
  @State gridColumns: number = 12
  @State useSizeTypeOffset: number = 4

  aboutToAppear() {
    CLog.info(this.TAG + ' aboutToAppear.')
    if (this.cameraDevice === 'phone') {
      this.gridColumns = 4
      this.useSizeTypeOffset = 0
    } else if(this.cameraDevice === 'tablet') {
      this.gridColumns = 12
      this.useSizeTypeOffset = 4
    }
//    this.moreList = this.cameraService.getDeviceInfo()
//    this.cameraService.getDeviceInfo().then((list) => {
//      for (let i=0; i<list.length; i++) {
//        console.info('MultiCameraDialog getDeviceInfo: ' + i + ' ' + list[i])
//      }
//    this.moreList = list
//    })
//    this.cameraService.getCameraLists().then(() => {
//      let cameraList = this.cameraService.cameraListInfo
//      this.isShowMore = cameraList.length > 5 ? true : false
//    })
  }

  private onChange(): void {
    this.controller.close()
    this.cancel()
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      GridContainer({ columns: this.gridColumns, gutter: 12, margin: 12 }) {
        Column() {
          Row() {
            Text($r('app.string.select_camera'))
              .fontSize($r("sys.float.ohos_id_text_size_dialog_tittle"))
              .fontColor('#E6000000')
              .opacity(0.9)
              .fontWeight(FontWeight.Medium)
              .opacity($r("sys.float.ohos_id_alpha_content_primary"))
          }
          .width('100%')
          .height('56vp')

          Row() {
            Text($r('app.string.connected_device'))
              .fontSize($r("sys.float.ohos_id_text_size_body2"))
              .fontColor('#99000000')
              .fontWeight(FontWeight.Medium)
              .opacity(0.6)
          }
          .width('100%')
          .height('48vp')

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
              .width('100%')
              .height(48);
            })
          }
          .listDirection(Axis.Vertical)
          .divider({ strokeWidth: 1, color: '#33000000', startMargin: 0, endMargin: 12 }) // 每行之间的分界线

          Row() {
            Text($r('app.string.more_devices'))
              .fontSize($r("sys.float.ohos_id_text_size_body2"))
              .fontColor('#99000000') //99FFFFFF 无法看清
              .fontWeight(FontWeight.Regular)
              .opacity(0.6)
          }
          .width('100%')
          .height('48vp')

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
                .width('100%')
                .height(48);
              })
            }
            .listDirection(Axis.Vertical)
            .divider({ strokeWidth: 0.5, color: '#33000000', startMargin: 0, endMargin: 12 }) // 每行之间的分界线
          }

          Column() {
            Button({ type: ButtonType.Normal, stateEffect: true }) {
              Text($r('app.string.cancel'))
                .fontSize($r("sys.float.ohos_id_text_size_sub_title2"))
                .fontColor('#1095E8')
                .fontWeight(FontWeight.Medium)
                .height('100%')
                .height('100%')
            }
            .width('100%')
            .height('100%')
            .backgroundColor(0xffffff)
            .onClick(() => {
              this.controller.close()
            })
          }
          .height(56)
          .width('100%')
          .margin({ top: 8 }).padding({ bottom: 16 })
        }
        .width('100%')
          .backgroundColor(Color.White)
          .padding({ left: 24, right: 24 })
          .borderRadius($r("sys.float.ohos_id_corner_radius_default_xl"))
          .useSizeType({
            xs: { span: 4, offset: this.useSizeTypeOffset },
            sm: { span: 4, offset: this.useSizeTypeOffset },
            md: { span: 4, offset: this.useSizeTypeOffset },
            lg: { span: 4, offset: this.useSizeTypeOffset }
          })
      }.width('100%')
    }
  }
}