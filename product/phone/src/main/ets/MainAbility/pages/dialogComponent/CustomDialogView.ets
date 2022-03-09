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

import EntryComponent from '../../../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/customDialog/entryComponent.ets'
import settings from '@ohos.settings';
import featureAbility from '@ohos.ability.featureAbility'

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

  public dialogList(name) {
    if (name === 'Aspect ratio') {
      this.dialogData = this.aspectRadioList
    } else {
      this.dialogData = this.videoResolutionList
    }
    return this.dialogData
  }

  async aboutToAppear() {
    this.childrenList = this.customDialogDetails.childrenList;
    console.info(`this.photoItemValue childrenList 1= ${JSON.stringify(this.childrenList)}`)
    this.settingAlias = this.customDialogDetails.setAlias;

    let settingCamera = `camera.settings.${this.settingAlias}`
    console.info("AppStorage.Has start ")
    let urivarCamera = settings.getUriSync(settingCamera);
    console.info(`urivarCamera = ${urivarCamera}`)
    let dataAbilityHelperCamera = featureAbility.acquireDataAbilityHelper(urivarCamera);
    console.info(`dataAbilityHelperCamera = ${dataAbilityHelperCamera}`)
    this.getValue = settings.getValueSync(dataAbilityHelperCamera, settingCamera, '');
    console.info(`PhotoScaleInfoStr = ${this.getValue}`)

  }

  public onChange(): void {
    this.controller.close()
    this.cancel()
  }

  build() {
    Column() {
      Row() {
        Text(this.customDialogDetails.settingTitle)
          .fontSize('20fp')
          .fontColor('#E6000000')
          .fontWeight(FontWeight.Medium)
          .opacity(0.9)
          .margin({ left: '24vp', right: '24vp' })
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
          .height(48);
        });
      }
      .listDirection(Axis.Vertical)
      .divider({ strokeWidth: 0.5, color: '#33000000', startMargin: 0, endMargin: 12 })
      .margin({ left: '24vp', right: '24vp' })

      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Row() {
          Text($r('app.string.cancel'))
            .fontSize('16fp')
            .fontColor('#0A59F7')
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(VerticalAlign.Center)
        .height(40)
        .margin({ top: "8vp" })
      }
      .margin({ bottom: '16vp' })
      .backgroundColor(0xffffff)
      .onClick(() => {
        this.controller.close()
      })
    }
    .margin({ left: '12vp', right: '12vp' })
    .width('100%')
  }
}