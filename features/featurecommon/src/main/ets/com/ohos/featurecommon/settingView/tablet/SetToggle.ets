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

import AssistiveGrid from '../../../../../../../../../../common/src/main/ets/default/setting/AssistiveGrid'
import {CLog} from '../../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import {SettingsUtil} from '../../../../../../../../../../common/src/main/ets/default/Utils/SettingsUtil'
import {SettingData}  from '../../../../../../../../../../common/src/main/ets/default/Utils/bean/SettingData'

@Component
export struct SetToggle {
  private TAG: string = '[SetToggle]:'
  @Link settingsList: any[]
  @State isOn: boolean = false;
  private itemValue: SettingData
  private getAssistiveGridStatus: Promise<string>
  private WH_100_100: string = "100%";
  private settingsUtil = SettingsUtil.getInstance()
  @State generalStatusValue: boolean = false

  aboutToAppear() {
    CLog.info(`${this.TAG} aboutToAppear start`)
    try {
      this.getAssistiveGridStatus = this.settingsUtil.getSettingValue(this.itemValue.settingAlias)
      this.getAssistiveGridStatus.then((vData) => {
        CLog.info(`${this.TAG} aboutToAppear start ${JSON.stringify(vData)}`)
        if (Number(vData) == 1) {
          this.generalStatusValue = true
        } else {
          this.generalStatusValue = false
        }
      })
    } catch {
      CLog.info(`${this.TAG} aboutToAppear settingsList ${JSON.stringify(this.settingsList)}`)
      this.generalStatusValue = false
    }
    CLog.info(`${this.TAG} aboutToAppear end`)
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
          Toggle({ type: ToggleType.Switch, isOn: this.generalStatusValue })
            .width(50)
            .height(40)
            .onChange((isOn: boolean) => {
              this.isOn = new Boolean(isOn).valueOf();
              let setToggle = 0;
              if (this.isOn) {
                setToggle = 1
              } else {
                setToggle = 0
              }
              this.settingsUtil.setSettingValue(this.itemValue.settingAlias, setToggle)
            })
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
  }
}