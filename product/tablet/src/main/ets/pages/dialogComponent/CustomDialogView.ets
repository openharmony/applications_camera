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

import {CLog} from '../../../../../../../common/src/main/ets/default/Utils/CLog'
import EntryComponent from '../../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/customDialog/dialogComponent/EntryComponent'

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

@CustomDialog
export struct CustomDialogView {
  private TAG: string = '[CustomDialogView]:'
  @StorageLink('settingsDetailList') settingsDetailList: any[]= [];
  controller: CustomDialogController
  cancel: () => void
  confirm: () => void
  @Consume customDialogDetails: CustomDialogDetails;
  @State settingAlias: string= "";
  @State getValue: string= "";
  @StorageLink('settingsList') settingsList: any[]= [];
  @State childrenList: Array<any> = [];
  @State dialogData: Array<any> = [];
  @State aspectRadioList: Array<any> = [{
                                          "itemValue": "4:3"
                                        },
                                        {
                                          "itemValue": "1:1"
                                        },
                                        {
                                          "itemValue": "16:9"
                                        }];
  @State videoResolutionList: Array<any> = [{
                                              "itemValue": "[16:9] 4k"
                                            },
                                            {
                                              "itemValue": "[16:9] 1080p"
                                            },
                                            {
                                              "itemValue": "[16:9] 720p"
                                            }]

  async aboutToAppear() {
    CLog.info(`${this.TAG} aboutToAppear start`)
    this.childrenList = this.customDialogDetails.childrenList;
    CLog.info(`${this.TAG} childrenList ${JSON.stringify(this.childrenList)}`)
    this.settingAlias = this.customDialogDetails.setAlias;
    CLog.info(`${this.TAG} aboutToAppear end`)
  }
  
  private dialogList(name) {
    if (name === 'AspectRatio') {
      this.dialogData = this.aspectRadioList
    } else {
      this.dialogData = this.videoResolutionList
    }
    return this.dialogData
  }

  public onChange(): void {
    CLog.info(`${this.TAG} onChange start`)
    this.controller.close()
    this.cancel()
    CLog.info(`${this.TAG} onChange end`)
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      GridContainer({ columns: 12, gutter: 12, margin: 24 }) {
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
            ForEach(this.dialogList(this.customDialogDetails.setAlias), (item) => {
              ListItem() {
                EntryComponent({
                  itemValue: item.itemValue,
                  checkedValue: this.getValue,
                  settingAlias: this.settingAlias,
                  onChange: () => this.onChange()
                });
              }
              .width('100%')
                .height(48)
            });
          }
          .listDirection(Axis.Vertical)
          .divider({ strokeWidth: 0.5, color: '#33000000', startMargin: 0, endMargin: 12 }) // 每行之间的分界线
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
            .margin({top: 8}).padding({ bottom: '16vp' })
        }
        .width('100%')
          .backgroundColor(Color.White)
          .padding({ left: '24vp', right: '24vp' })
          .borderRadius($r("sys.float.ohos_id_corner_radius_default_xl"))
          .useSizeType({
            xs: { span: 4, offset: 4 },
            sm: { span: 4, offset: 4 },
            md: { span: 4, offset: 4 },
            lg: { span: 4, offset: 4 }
          })
      }.width('100%')
    }
  }
}