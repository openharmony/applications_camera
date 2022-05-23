/**
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

import AspectRatio from '../../../../../../../../../../common/src/main/ets/default/setting/AspectRatio'
import Resolution from '../../../../../../../../../../common/src/main/ets/default/setting/Resolution'
import Timer from '../../../../../../../../../../common/src/main/ets/default/setting/Timer'
import {CustomDialogView, CustomDialogDetails} from '../../customDialog/dialogComponent/CustomDialogView'
import {CLog} from '../../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import {SettingsUtil} from '../../../../../../../../../../common/src/main/ets/default/Utils/SettingsUtil'
import {BaseData}  from '../../../../../../../../../../common/src/main/ets/default/Utils/bean/BaseData'
import {SettingData}  from '../../../../../../../../../../common/src/main/ets/default/Utils/bean/SettingData'

@Component
export struct SetResolution {
  private TAG: string = '[SetResolution]:'
  @Link settingsList: any[]
  private itemValue: SettingData
  private getCheckValue: Promise<string>
  private WH_100_100: string = "100%";
  private settingsUtil = SettingsUtil.getInstance()
  private setAlias: string= undefined;

  @State curCheckName: Resource = $r("app.string.default_value")
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
    cancel: this.existView,
    customStyle: true
  })

  existView() {
    CLog.info(`${this.TAG} existView E`)
    this.curCheckName = this.settingsUtil.getSettingValue(this.itemValue.settingAlias)
    CLog.info(`${this.TAG} existView curCheckName: ${this.curCheckName} X`)
  }

  aboutToAppear() {
    CLog.info(`${this.TAG} aboutToAppear settingsList: ${JSON.stringify(this.settingsList)} E`)
    this.curCheckName = this.settingsUtil.getSettingValue(this.itemValue.settingAlias)
    CLog.info(`${this.TAG} aboutToAppear curCheckName: ${this.curCheckName} X`)
  }

  public formatCurCheckName(name) {
    if (JSON.stringify(name) === JSON.stringify(Timer.DEFAULT_VALUE)) {
      name = Timer.RESOURCE_OFF_ALREADY
    }
    return name
  }

  build() {
    Row() {
      Flex({
        direction: FlexDirection.Row,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.SpaceBetween
      }) {
        Row() {
          Image(this.itemValue.imagePath)
            .width(24)
            .height(24)
            .fillColor("#FFFFFF")
          Text(this.itemValue.settingName)
            .margin({ left: $r("sys.float.ohos_id_elements_margin_horizontal_l") })
            .fontColor("#FFFFFF")
            .fontSize($r("sys.float.ohos_id_text_size_sub_title2"))
            .fontWeight(FontWeight.Regular)
        }

        Row() {
          Text(this.formatCurCheckName(this.curCheckName))
            .fontColor($r('app.color.font_color_FFFFFF'))
            .fontSize($r("sys.float.ohos_id_text_size_body2"))
            .fontWeight(FontWeight.Regular)
            .opacity($r('app.float.opacity_6'))
          Image($r("app.media.ic_public_arrow_right"))
            .width(12)
            .height(24)
            .fillColor('#66FFFFFF')
            .opacity($r('app.float.opacity_4'))
            .margin({ left: 4 })
        }
      }
      .height(64)
      .padding({ left: 12, right: 12, top: 4, bottom: 4 })
    }
    .margin({
      top: $r("sys.float.ohos_id_text_paragraph_margin_xs"),
      bottom: $r("sys.float.ohos_id_text_paragraph_margin_xs")
    })
    .width(this.WH_100_100)
    .height(56)
    .onClick(() => {
      this.openDetailsDialog(this.itemValue)
    })
  }

  async openDetailsDialog(itemValue): Promise<void> {
    CLog.info(`${this.TAG} openDetailsDialog start`)
    CLog.info(`${this.TAG} openDetailsDialog dataInfo ${JSON.stringify(itemValue)}`)
    // 需要根据相机能力更新这个childrenList，目前是写死状态
    this.customDialogDetails.childrenList = itemValue.radio;
    this.customDialogDetails.settingTitle = itemValue.settingName;
    this.customDialogDetails.setAlias = itemValue.settingAlias;
    CLog.info(`${this.TAG} childrenList: ${JSON.stringify(itemValue.radio)}`)
    this.CustomDialogView.open()
    CLog.info(`${this.TAG} openDetailsDialog end`)
  }
}