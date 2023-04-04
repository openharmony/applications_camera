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

import { CameraService } from '../../camera/CameraService'
import { CameraId } from '../../setting/settingitem/CameraId'
import { Log } from '../../utils/Log'
import EntryComponentForMulti from './EntryComponentForMulti'
import { getStore } from '../../redux/store'
import { Action } from '../../redux/actions/Action'

let localState = (state) => {
  return {}
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
  changeCameraPosition : Function
}

@CustomDialog
export default struct MultiCameraDialog {
  private TAG: string = '[MultiCameraDialog]:'
  private cameraService = CameraService.getInstance()
  controller: CustomDialogController
  cancel: () => void
  confirm: () => void
  private localList: string[] = [
    CameraId.FRONT,
    CameraId.BACK
  ]
  @State private moreList: string[] = []
  private multiCameraMap = new Map()
  @State state: StateStruct = new StateStruct()
  @State isShowMore: boolean = false
  @State gridColumns: number = 12
  @State useSizeTypeOffset: number = 4
  @Link deviceType: string
  @StorageLink('storageCameraId') storageCameraId: string = ''

  aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear.`)
    getStore().connect(localState, localDispatcher)(this.state)
    this.cameraService.getMultiCameraInfo(() => {
      let cameraMap = new Map(this.cameraService.getCameraMap())
      let keys = cameraMap.keys()
      this.moreList = [...keys]
      Log.info(`${this.TAG} cameraMap length: ${this.moreList.length}`)
      if (this.moreList.length !== 0) {
        this.multiCameraMap = cameraMap
        this.isShowMore = true
        Log.info(`${this.TAG} getMultiCameraInfo finished.`)
      } else {
        this.isShowMore = false
        Log.info(`${this.TAG} getMultiCameraInfo null.`)
      }
    })
    let localCameraInfo = this.cameraService.getLocalCameraMap()
    if (!localCameraInfo.get('front')) {
      this.localList.shift()
    } else if (!localCameraInfo.get('back')) {
      this.localList.pop()
    }
    if (this.deviceType === 'phone' || this .deviceType === 'default') {
      this.gridColumns = 4
      this.useSizeTypeOffset = 0
    } else {
      this.gridColumns = 12
      this.useSizeTypeOffset = 4
    }
  }

  private onChange(item): void {
    Log.info(`${this.TAG} MultiCameraPosition ${JSON.stringify(item)}`)
    if (item.includes('BACK')) {
      this.storageCameraId = 'BACK'
    } else if(item.includes('FRONT')) {
      this.storageCameraId = 'FRONT'
    }
    this.state.changeCameraPosition(item)
    this.cancel()
    this.controller.close()
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
            Text($r('app.string.local_device'))
              .fontSize($r("sys.float.ohos_id_text_size_body2"))
              .fontColor("#99182431")
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .height('48vp')
          .padding({top: 20, bottom: 8})

          List() {
            ForEach(this.localList, (item) => {
              ListItem() {
                EntryComponentForMulti({
                  item: item,
                  localList: this.localList.toString(),
                  onChange: (data) => this.onChange(data)
                })
              }
              .width('100%')
              .height(48)
            })
          }
          .listDirection(Axis.Vertical)
          .divider({ strokeWidth: '1vp', color: "#33182431", startMargin: 0, endMargin: 12})

          Row() {
            Text($r('app.string.more_devices'))
              .fontSize($r("sys.float.ohos_id_text_size_body2"))
              .fontColor("#99182431")
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .height('48vp')
          .padding({top: 20, bottom: 8})

          if (this.isShowMore) {
            List() {
              ForEach(this.moreList, (item) => {
                ListItem() {
                  EntryComponentForMulti({
                    item: item,
                    localList: this.localList.toString(),
                    onChange: (data) => this.onChange(data)
                  })
                }
                .width('100%')
                .height(48)
              })
            }
            .listDirection(Axis.Vertical)
            .divider({ strokeWidth: 0.5, color: '#33000000', startMargin: 0, endMargin: 12 })
          }

          Column() {
            Button({ type: ButtonType.Capsule, stateEffect: true }) {
              Text($r('app.string.cancel'))
                .fontSize($r("sys.float.ohos_id_text_size_sub_title2"))
                .fontColor('#1095E8')
                .fontWeight(FontWeight.Medium)
                .height('100%')
                .height('100%')
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#00ffffff')
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