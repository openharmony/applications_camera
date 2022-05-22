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

import router from '@system.router';

import { CLog } from '../../../../../../common/src/main/ets/default/Utils/CLog'
import ScreenLockManager from '../../../../../../common/src/main/ets/default/Utils/ScreenLockManager'
import { SettingItem
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/settingView/phone/SettingItem'
import SettingListModel from '../../../../../../common/src/main/ets/default/model/SettingListImpl/SettingListModel';
import { SettingsUtil } from '../../../../../../common/src/main/ets/default/Utils/SettingsUtil'

var mScreenLockManager = new ScreenLockManager()

@Entry
@Component
struct SettingView {
  private TAG: string = '[SettingView]:'
  private cameraPosition: string
  private previewImage: string
  private settingsUtil = SettingsUtil.getInstance()
  @State checkNameList: Array<string> = ["4:3", "[16:9] 720p"]
  @State tempGutter: number = 12; //列间距
  @State tempMargin: number = 12; //两侧间距
  @State settingsList: any[] = SettingListModel.getSettingList()
  private WH_100_100: string = "100%";

  private aboutToAppear(): void{
    CLog.info(`${this.TAG} aboutToAppear invoke E`)
    if (router.getParams() != undefined) {
      this.cameraPosition = router.getParams().position.toString()
      this.previewImage = router.getParams().mode.toString()
    }

    mScreenLockManager.init()
    CLog.info(`${this.TAG} aboutToAppear invoke X`)
  }

  private onBackPress() {
    router.replace({
      params: {
        position: this.cameraPosition,
        mode: this.previewImage
      },
      uri: "pages/index"
    })
    return true;
  }

  build() {
    Column() {
      GridContainer({ columns: 4, gutter: this.tempGutter }) {
        Row() {
          Image($r("app.media.ic_public_back"))
            .width(24)
            .height(24)
            .fillColor($r('app.color.settings_ic_public_back_FFFFFF'))
            .onClick(() => {
              router.replace({
                params: {
                  position: this.cameraPosition,
                  mode: this.previewImage
                },
                uri: "pages/index"
              })
            })
          Text($r('app.string.settings'))
            .margin({ left: $r("sys.float.ohos_id_elements_margin_horizontal_l") })
            .fontColor($r('app.color.settings_ic_public_back_FFFFFF'))
            .fontSize($r('sys.float.ohos_id_text_size_headline8'))
            .fontWeight(FontWeight.Medium)
        }
        .useSizeType({
          xs: { span: 12, offset: 0 },
          sm: { span: 12, offset: 0 },
          md: { span: 12, offset: 0 },
          lg: { span: 12, offset: 0 }
        })
        .width(this.WH_100_100)
        .height(56)
        .margin({ left: $r('sys.float.ohos_id_default_padding_start') })
      }

      GridContainer({ columns: 4, gutter: this.tempGutter, margin: this.tempMargin }) {
        Row() {
          Column() {
            List() {
              ForEach(this.settingsList, (item, index) => {
                ListItem() {
                  SettingItem({
                    settingsList: $settingsList,
                    item: item,
                    index: index
                  })
                }
              })
            }
          }.useSizeType({
            xs: { span: 4, offset: 0 },
            sm: { span: 4, offset: 0 },
            md: { span: 4, offset: 0 },
            lg: { span: 4, offset: 0 }
          })
        }
      }

      GridContainer({ columns: 4, gutter: this.tempGutter, margin: this.tempMargin }) {
        Row() {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text($r('app.string.restore_defaults'))
              .fontSize($r('sys.float.ohos_id_text_size_button1'))
              .fontColor($r('app.color.font_color_FFFFFF'))
              .fontWeight(FontWeight.Regular)
              .textAlign(TextAlign.Center)
              .useSizeType({
                xs: { span: 4, offset: 0 },
                sm: { span: 4, offset: 0 },
                md: { span: 4, offset: 0 },
                lg: { span: 4, offset: 0 }
              })
          }
          .borderRadius(30)
          .backgroundColor($r('app.color.background_color_333333'))
          .height(40)
          .onClick(() => {
            this.settingsUtil.restoreValues()
            router.replace({
              params: {
                position: this.cameraPosition,
                mode: this.previewImage
              },
              uri: "pages/index"
            })
          })
        }.margin({ top: $r("sys.float.ohos_id_text_paragraph_margin_l") })
      }
    }
    .height(this.WH_100_100)
    .backgroundColor(Color.Black)
  }
}