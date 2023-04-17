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

import { Action } from '../../../redux/actions/Action'
import { Log } from '../../../utils/Log'
import { getStore } from '../../../redux/store'
import EntryComponent from './EntryComponent'

@Observed
export class CustomDialogDetails {
  confirmCallback: Function
  confirmItem: boolean
  height: number
  width: number
  setAlias: string
  childrenList: any[]
  settingTitle: string
}

let localState = (state) => {
  return {}
}

let localDispatcher = (dispatch) => {
  return {
    closeDialog: (isCloseFlag: boolean) => {
      dispatch(Action.closeDialog(isCloseFlag))
    }
  }
}

class StateStruct {
  closeDialog : Function
}

@CustomDialog
export struct CustomDialogView {
  private TAG: string = '[CustomDialogView]:'
  //  @StorageLink('settingsDetailList') settingsDetailList: any[]= [];
  localStyle = { "columns": 4, "offset": 0 }
  controller: CustomDialogController
  cancel: () => void
  confirm: () => void
  @Consume customDialogDetails: CustomDialogDetails
  @State settingAlias: string= ""
  @State getValue: string= ""
  @StorageLink('settingsList') settingsList: any[]= []
  @State childrenList: Array<any> = []

  @State state: StateStruct = new StateStruct()

  async aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear start`)
    this.childrenList = this.customDialogDetails.childrenList
    Log.info(`${this.TAG} childrenList ${JSON.stringify(this.childrenList)}`)
    getStore().connect(localState, localDispatcher)(this.state)
    this.settingAlias = this.customDialogDetails.setAlias
    Log.info(`${this.TAG} aboutToAppear end`)
  }

  public onChange(): void {
    Log.info(`${this.TAG} onChange start`)
    this.state.closeDialog(false)
    this.controller.close()
    this.cancel()
    Log.info(`${this.TAG} onChange end`)
  }

  build() {
    if (deviceInfo.deviceType == 'PAD' || deviceInfo.deviceType == 'tablet') {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        Column() {
          Row() {
            Text(this.customDialogDetails.settingTitle)
              .fontSize($r("sys.float.ohos_id_text_size_dialog_tittle"))
              .fontColor('#E6000000')
              .opacity(0.9)
              .fontWeight(FontWeight.Medium)
              .opacity($r("sys.float.ohos_id_alpha_content_primary"))
          }
          .width('100%')
          .height(56)

          List() {
            ForEach(this.customDialogDetails.childrenList, (item) => {
              ListItem() {
                EntryComponent({
                  itemValue: item.itemValue,
                  checkedValue: this.getValue,
                  settingAlias: this.settingAlias,
                  onChange: () => this.onChange()
                })
              }
              .height(48)
              .width('100%')
            })
          }
          .listDirection(Axis.Vertical)
          .divider({ strokeWidth: 0.5, color: '#33000000', startMargin: 0, endMargin: 12 }) // 每行之间的分界线
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
              this.state.closeDialog(false)
              this.controller.close()
            })
          }
          .height(56)
          .width('100%')
          .margin({ top: 8 }).padding({ bottom: '16vp' })
        }
        .width(394)
        .margin({ left: '12vp', right: '12vp', bottom: '16vp' })
        .backgroundColor(Color.White)
        .padding({ left: '24vp', right: '24vp' })
        .borderRadius($r("sys.float.ohos_id_corner_radius_default_xl"))
      }
    } else {
      Flex({ justifyContent: FlexAlign.Center }) {
        Column() {
          Row() {
            Text(this.customDialogDetails.settingTitle)
              .fontSize($r("sys.float.ohos_id_text_size_dialog_tittle"))
              .fontColor('#E6000000')
              .opacity(0.9)
              .fontWeight(FontWeight.Medium)
              .opacity($r("sys.float.ohos_id_alpha_content_primary"))
          }
          .width('100%')
          .height(56)

          GridContainer({ columns: this.localStyle.columns, gutter: 12, margin: 12 }) {

            List() {
              ForEach(this.customDialogDetails.childrenList, (item) => {
                ListItem() {
                  EntryComponent({
                    itemValue: item.itemValue,
                    checkedValue: this.getValue,
                    settingAlias: this.settingAlias,
                    onChange: () => this.onChange()
                  })
                }
                .height(48)
                .width('100%')
              })
            }
            .listDirection(Axis.Vertical)
            .divider({ strokeWidth: 0.5, color: '#33000000', startMargin: 0, endMargin: 12 }) // 每行之间的分界线
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
                this.state.closeDialog(false)
                this.controller.close()
              })
            }
            .height(56)
            .width('100%')
            .margin({ top: 8 }).padding({ bottom: '16vp' })
          }
          .width('96%')
        }
        .margin({ left: '12vp', right: '12vp', bottom: '16vp' })
        .backgroundColor(Color.White)
        .padding({ left: '24vp', right: '24vp' })
        .borderRadius($r("sys.float.ohos_id_corner_radius_default_xl"))
        .useSizeType({
          xs: { span: 4, offset: this.localStyle.offset },
          sm: { span: 4, offset: this.localStyle.offset },
          md: { span: 4, offset: this.localStyle.offset },
          lg: { span: 4, offset: this.localStyle.offset }
        })
      }
    }
  }
}