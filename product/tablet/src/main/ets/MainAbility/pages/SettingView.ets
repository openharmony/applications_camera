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

import SettingListModel from '../../../../../../../common/src/main/ets/default/model/SettingListImpl/SettingListModel.ets';
import {CustomDialogView, CustomDialogDetails} from './dialogComponent/CustomDialogView.ets'
import router from '@system.router';
import {SettingsUtil} from '../../../../../../../common/src/main/ets/default/Utils/SettingsUtil.ets'

@Entry
@Component
struct SettingView {
  @StorageLink('settingsDetailList') settingsDetailList: any[]= [];
  private cameraPosition: string
  private previewImage: string
  private settingsUtil = SettingsUtil.getInstance()
  private setAlias: string= undefined;
  private getPhotoValue: Promise<string>;
  private getVideoValue: Promise<string>;
  @State checkNameList: Array<string> = ["4:3", "[16:9] 720p"]
  @State actionValue: string = "";
  @State settingsListUpdated: boolean = false;
  @State tempGutter: number = 24;
  @State tempMargin: number = 24;
  @State sizeType: SizeType = SizeType.XS
  @Provide customDialogDetails: CustomDialogDetails = {
    confirmCallback: null,
    confirmItem: true,
    height: 256,
    width: 256,
    setAlias: this.setAlias,
    childrenList: [],
    settingTitle: ''
  }
  CustomDialogView: CustomDialogController = new CustomDialogController({
    builder: CustomDialogView({ cancel: this.existView.bind(this) }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    cancel: this.existView
  })
  @State settingsList: any[]= [
    {
      subtitle: $r('app.string.photo_mode'),
      details: [{
                  imagePath: $r("app.media.ic_camera_setting_resolution_photo"),
                  settingName: $r('app.string.aspect_ratio'),
                  CheckedName: "4:3",
                  settingAlias: "Aspect ratio",
                  radio: [{
                            "RadioName": "4:3",
                            "RadioDefault": true
                          }]
                }]
    }, {
      subtitle: $r('app.string.video_mode'),
      details: [{
                  imagePath: $r("app.media.ic_camera_setting_resolution_video"),
                  settingName: $r('app.string.video_resolution'),
                  settingAlias: "Video resolution",
                  CheckedName: "[16:9] 720p",
                  radio: [{
                            "RadioName": "[16:9] 720p",
                            "RadioDefault": true
                          }]
                }]
    }
  ]

  existView() {
    console.info('SettingView existView start')
    try {
      this.getPhotoValue = this.settingsUtil.getSettingValue('Aspect ratio')
      console.info(`SettingView values[0] = ${JSON.stringify(this.getPhotoValue)}`)
      this.getVideoValue = this.settingsUtil.getSettingValue('Video resolution')
      console.info(`SettingView values[0] = ${JSON.stringify(this.getVideoValue)}`)
      Promise.all([this.getPhotoValue, this.getVideoValue]).then(values => {
        this.checkNameList[0] = values[0];
        this.settingsList[0].details[0].CheckedName = values[0];
        console.info(`SettingView1 values[0] = ${JSON.stringify(values)}`)
        console.info(`SettingView2 values[0] = ${values[0]}`)
        console.info(`SettingView3 values[1] = ${values[1]}`)
        console.info(`SettingView4 PhotoScaleInfoStr = ${JSON.stringify(values)}`)
        this.checkNameList[1] = values[1]
        this.settingsList[1].details[0].CheckedName = values[1]
        console.info(`SettingView VideoScaleInfoStr = ${values[1]}`)
      })
    } catch {
      console.info(`settingsList = ${JSON.stringify(this.settingsList)}`)
    }
  }

  aboutToAppear() {
    console.info("SettingView aboutToAppear")
    console.info("SettingView router.getParams()= " + JSON.stringify(router.getParams()))
    if (router.getParams() != undefined) {
      this.cameraPosition = router.getParams().position
      this.previewImage = router.getParams().mode
      this.previewImage = 'PHOTO'
    }
    SettingListModel.setSettingDetialListener();

    try {
      this.getPhotoValue = this.settingsUtil.getSettingValue('Aspect ratio')
      this.getVideoValue = this.settingsUtil.getSettingValue('Video resolution')
      Promise.all([this.getPhotoValue, this.getVideoValue]).then(values => {
        this.checkNameList[0] = values[0]
        this.settingsList[0].details[0].CheckedName = values[0]
        console.info(`SettingView PhotoScaleInfoStr = ${values[0]}`)
        this.checkNameList[1] = values[1]
        this.settingsList[1].details[0].CheckedName = values[1]
        console.info(`SettingView VideoScaleInfoStr = ${values[1]}`)
      })
    } catch {
      console.info(`settingsList = ${JSON.stringify(this.settingsList)}`)
      console.info(`settingsList = ${JSON.stringify(this.settingsList[0].details[0].CheckedName)}`)
      console.info(`settingsList = ${JSON.stringify(this.settingsList[1].details[0].CheckedName)}`)

      this.settingsList[0].details[0].CheckedName = "4:3"
      this.settingsList[1].details[0].CheckedName = "[16:9] 720p"
    }
  }

  private onBackPress() {
    router.replace({
      params: {
        position: this.cameraPosition,
        mode: this.previewImage
      },
      uri: "pages/indexLand"
    })
    return true;
  }

  build() {
    Column() {
      GridContainer({ columns: 12, gutter: this.tempGutter }) {
        Row() {
          Image($r("app.media.ic_public_back"))
            .width(24)
            .height(24)
            .fillColor('#FFFFFF')
            .margin({ left: '12vp' })
            .onClick(() => {
              router.replace({
                params: {
                  position: this.cameraPosition,
                  mode: this.previewImage
                },
                uri: "pages/indexLand"
              })
            })
          Text($r('app.string.settings'))
            .margin({ left: '12vp' })
            .fontColor('#FFFFFF')
            .fontSize('20fp')
            .fontWeight(FontWeight.Medium)
            .height(48)
        }
        .useSizeType({
          xs: { span: 12, offset: 0 },
          sm: { span: 12, offset: 0 },
          md: { span: 12, offset: 0 },
          lg: { span: 12, offset: 0 }
        })
        .width('100%')
        .height(48)
      }.margin({ left: '12vp' })

      GridContainer({ columns: 12, gutter: this.tempGutter, margin: this.tempMargin }) {
        Row() {
          Column() {
            ForEach(this.settingsList, (item, index) => {
              Column() {
                Row() {
                  Text(item.subtitle)
                    .margin({ top: '20vp', left: '12vp', bottom: '8vp' })
                    .fontColor('#FFFFFF')
                    .opacity(0.6)
                    .fontSize('16fp')
                    .fontWeight(FontWeight.Medium)
                }.width('100%').height('100%')
              }.width('100%').height(48)

              Column() {
                ForEach(item.details, (pro) => {
                  Row() {
                    Flex({
                      direction: FlexDirection.Row,
                      alignItems: ItemAlign.Center,
                      justifyContent: FlexAlign.SpaceBetween
                    }) {
                      Row() {
                        Image(pro.imagePath)
                          .width(24)
                          .height(24)
                          .margin({ left: '12vp' })
                        Text(pro.settingName)
                          .margin({ left: '12vp' })
                          .fontColor('#99FFFFFF')
                          .fontSize('16fp')
                          .fontWeight(FontWeight.Regular)
                          .opacity(0.6)
                      }

                      Row() {
                        Text(this.checkNameList[index]).fontColor('#99FFFFFF').fontSize('14fp')
                          .fontWeight(FontWeight.Regular).opacity(0.6)
                        Text(">")
                          .margin({ left: '2vp' })
                          .fontColor('#99FFFFFF')
                          .fontSize('14fp')
                          .fontWeight(FontWeight.Regular)
                          .opacity(0.6)
                      }
                      .padding({ left: '12vp', right: '12vp' })
                    }
                    .height(56)
                    .borderRadius(16)
                    .backgroundColor('#333333')
                    .margin({ top: '4vp', bottom: '4vp' })
                  }
                  .width('100%')
                  .height(56)
                  .borderRadius(16)
                  .onClick(() => {
                    this.openDetailsDialog(pro.settingAlias)
                  })
                })
              }.width('100%')
              .borderRadius(36)
            })
          }
        }.alignItems(VerticalAlign.Center)
        .useSizeType({
          xs: { span: 8, offset: 2 },
          sm: { span: 8, offset: 2 },
          md: { span: 8, offset: 2 },
          lg: { span: 8, offset: 2 }
        })
      }

      GridContainer({ columns: 12, sizeType: SizeType.XS, gutter: this.tempGutter, margin: this.tempMargin }) {
        Row() {
          Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
            Button({ type: ButtonType.Normal, stateEffect: true }) {
              Text($r('app.string.restore_defaults'))
                .fontSize('16fp')
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Regular)
            }
            .borderRadius(20)
            .backgroundColor('#333333')
            .height(40)
            .width(this.tempGutter * 12)
            .onClick(() => {
              this.settingsUtil.setSettingValue('Aspect ratio', '4:3')
              this.settingsUtil.setSettingValue('Video resolution', '[16:9] 720p')
              router.replace({
                params: {
                  position: this.cameraPosition,
                  mode: this.previewImage
                },
                uri: "pages/indexLand"
              })
            })
          }.padding({ top: '14vp', bottom: '14vp' }).width('100%').margin({ top: '16vp' })
        }.useSizeType({
          xs: { span: 4, offset: 4 },
          sm: { span: 4, offset: 4 },
          md: { span: 4, offset: 4 },
          lg: { span: 4, offset: 4 }
        })
      }
    }
    .height('100%')
    .backgroundColor(Color.Black)
  }

  async openDetailsDialog(status): Promise<void> {
    console.log("status " + status)
    let name: string = ""
    if (status == 'Aspect ratio') {
      console.log("Aspect ratio1")
      name = "photoScale";
    } else {
      name = "videoResolution";
    }
    console.info(`tname = ${JSON.stringify(name)}`)
    console.info(`this.pthis.settingsList= ${JSON.stringify(this.settingsDetailList)}`)
    let dataInfo = await this.settingsDetailList.filter(v => {
      return v.settingAlias == name;
    })
    console.info(`this.photoItemValue dataInfo = ${JSON.stringify(dataInfo)}`)
    this.customDialogDetails.childrenList = dataInfo[0].settingChildren;
    this.customDialogDetails.settingTitle = dataInfo[0].settingTitle;
    console.info(`this.photoItemValue settingChildren = ${JSON.stringify(dataInfo[0].settingChildren)}`)
    this.customDialogDetails.setAlias = status;
    this.CustomDialogView.open()
  }
}