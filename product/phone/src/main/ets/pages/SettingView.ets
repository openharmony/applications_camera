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
import deviceInfo from '@ohos.deviceInfo';
import { Action } from '../../../../../../common/src/main/ets/default/redux/actions/Action'
import { Log } from '../../../../../../common/src/main/ets/default/utils/Log'
import getStore, { OhCombinedState } from '../../../../../../common/src/main/ets/default/redux/store'
import ScreenLockManager from '../../../../../../common/src/main/ets/default/featurecommon/screenlock/ScreenLockManager'
import { SettingItem
} from '../../../../../../common/src/main/ets/default/featurecommon/settingview/phone/SettingItem'
import SettingListModel from '../../../../../../common/src/main/ets/default/featurecommon/settingview/model/SettingListModel'
import { SettingManager } from '../../../../../../common/src/main/ets/default/setting/SettingManager'

var mScreenLockManager = new ScreenLockManager()

let localState = (state: OhCombinedState) => {
  return {
    isCloseFlag: state.SettingReducer.isCloseFlag
  }
}

let localDispatcher = (dispatch) => {
  return {
    closeDialog: (isCloseFlag: boolean) => {
      dispatch(Action.closeDialog(isCloseFlag))
    }
  }
}

@Entry
@Component
struct SettingView {
  private TAG: string = '[SettingView]:'
  private cameraPosition: string
  private previewImage: string
  private settingManager = SettingManager.getInstance()
  @State checkNameList: Array<string> = ["4:3", "[16:9] 720p"]
  @State closeFlag: boolean = false
  @State tempGutter: number = 12; //列间距
  @State tempMargin: number = 12; //两侧间距
  @State settingsList: any[] = SettingListModel.getSettingList()
  @State state: any = {}
  private WH_100_100: string = "100%";

  aboutToAppear(): void{
    Log.info(`${this.TAG} aboutToAppear invoke E`)
    if (router.getParams() != undefined) {
      this.cameraPosition = router.getParams().position.toString()
      this.previewImage = router.getParams().mode.toString()
    }
    getStore().connect(localState, localDispatcher)(this.state)
    mScreenLockManager.init()
    Log.info(`${this.TAG} aboutToAppear invoke X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
  }

  onBackPress(): boolean {
    Log.info(`${this.TAG} onBackPress invoke X`)
    if (this.state.isCloseFlag){
      this.closeFlag = !this.closeFlag
    } else {
      router.replace({
        params: {
          position: this.cameraPosition,
          mode: this.previewImage,
          pageType: 'route'
        },
        uri: "pages/index"
      })
    }
    return true;
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Row() {
        Image($r("app.media.ic_public_back"))
          .width(24)
          .height(24)
          .fillColor($r('app.color.settings_ic_public_back_FFFFFF'))
          .onClick(() => {
            router.replace({
              params: {
                position: this.cameraPosition,
                mode: this.previewImage,
                pageType: 'route'
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
      .padding({ left: 24 })
      .width(this.WH_100_100)
      .height(56)
      .margin({ top: deviceInfo.deviceType !== 'default' ? 25 : 0 })

      Scroll() {
        Column() {
          GridContainer({ columns: 4, gutter: this.tempGutter, margin: this.tempMargin }) {
            List() {
              ForEach(this.settingsList, (item, index) => {
                ListItem() {
                  SettingItem({
                    settingsList: $settingsList,
                    closeFlag: $closeFlag,
                    item: item,
                    index: index
                  })
                }
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
                    xs: { span: 2, offset: 0 },
                    sm: { span: 2, offset: 0 },
                    md: { span: 2, offset: 0 },
                    lg: { span: 2, offset: 0 }
                  })
              }
              .borderRadius(30)
              .backgroundColor($r('app.color.background_color_333333'))
              .height(40)
              .onClick(() => {
                this.settingManager.restoreValues()
                router.replace({
                  params: {
                    position: this.cameraPosition,
                    mode: this.previewImage,
                    pageType: 'route'
                  },
                  uri: "pages/index"
                })
              })
            }
            .margin({ top: $r("sys.float.ohos_id_text_paragraph_margin_l") })
          }
        }
      }
      .width(this.WH_100_100)
      .flexShrink(1)
      .edgeEffect(EdgeEffect.Spring)
    }
    .height(this.WH_100_100)
    .backgroundColor(Color.Black)
  }
}