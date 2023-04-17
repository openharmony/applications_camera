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

import deviceInfo from '@ohos.deviceInfo';
import { Action }  from '@ohos/common/src/main/ets/default/redux/actions/Action'
import { EventBusManager }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager'
import { getStore, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store'
import { Log } from '@ohos/common/src/main/ets/default/utils/Log'
import { SettingManager } from '@ohos/common/src/main/ets/default/setting/SettingManager'
import { SettingItem } from '@ohos/common/src/main/ets/default/featurecommon/settingview/phone/SettingItem'
import { SettingListModel } from '@ohos/common/src/main/ets/default/featurecommon/settingview/model/SettingListModel'

let localState = (state: OhCombinedState) => {
  return {
    isCloseFlag: state.SettingReducer.isCloseFlag,
    mode: state.ModeReducer.mode,
    zoomRatio: state.ZoomReducer.zoomRatio,
  }
}

let localDispatcher = (dispatch) => {
  return {
    closeDialog: (isCloseFlag: boolean) => {
      dispatch(Action.closeDialog(isCloseFlag))
    },
    hideSettingView: () => {
      dispatch(Action.showSettingView(false))
    },
    changeXComponentSize: (xComponentWidth: number, xComponentHeight: number) => {
      dispatch(Action.changeXComponentSize(xComponentWidth, xComponentHeight))
    },
    assistiveGridView: (isViewShow) => {
      dispatch(Action.assistiveGridView(isViewShow))
    },
    reStartPreview: (zoomRatio?: number) => {
      dispatch(Action.reStartPreview(zoomRatio))
    },
  }
}

class StateStruct {
  isCloseFlag
  mode
  zoomRatio
  closeDialog : Function
  hideSettingView : Function
  changeXComponentSize : Function
  assistiveGridView : Function
  reStartPreview : Function
}

@Component
export struct SettingView {
  private TAG: string = '[SettingView]:'
  private settingManager = SettingManager.getInstance()
  @State checkNameList: Array<string> = ["4:3", "[16:9] 720p"]
  @State closeFlag: boolean = false
  @State tempGutter: number = 12; //列间距
  @State tempMargin: number = 12; //两侧间距
  @State settingsList: any[] = new SettingListModel().getSettingList()
  @State state: StateStruct = new StateStruct()
  private mEventBus = EventBusManager.getInstance().getEventBus()
  private WH_100_100: string = "100%";

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear invoke E`)
    getStore().connect(localState, localDispatcher)(this.state)
    this.mEventBus.on("AspectRatio", this.aspectRatioChange.bind(this))
    this.mEventBus.on("Resolution", this.resolutionChange.bind(this))
    this.mEventBus.on("AssistiveGrid", this.assistiveGridChange.bind(this))
    Log.info(`${this.TAG} aboutToAppear invoke X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    this.mEventBus.off("AspectRatio", this.aspectRatioChange.bind(this))
    this.mEventBus.off("Resolution", this.resolutionChange.bind(this))
    this.mEventBus.off("AssistiveGrid", this.assistiveGridChange.bind(this))
  }

  onBackPress(): boolean {
    Log.info(`${this.TAG} onBackPress invoke X`)
    if (this.state.isCloseFlag) {
      this.closeFlag = !this.closeFlag
    } else {
      this.state.hideSettingView()
    }
    return true;
  }

  private aspectRatioChange(xComponentSize) {
    if (this.state.mode != 'VIDEO') {
      this.state.changeXComponentSize(xComponentSize.width, xComponentSize.height)
      this.state.reStartPreview(this.state.zoomRatio)
    }
  }

  private resolutionChange(xComponentSize) {
    if (this.state.mode == 'VIDEO') {
      this.state.changeXComponentSize(xComponentSize.width, xComponentSize.height)
      this.state.reStartPreview(this.state.zoomRatio)
    }
  }

  private assistiveGridChange(mAssistiveGrid) {
    this.state.assistiveGridView(mAssistiveGrid)
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      Row() {
        Image($r("app.media.ic_public_back"))
          .width(24)
          .height(24)
          .fillColor($r('app.color.settings_ic_public_back_FFFFFF'))
          .onClick(() => {
            this.state.hideSettingView()
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

          Row() {
            Button({ type: ButtonType.Normal, stateEffect: true }) {
              Text($r('app.string.restore_defaults'))
                .fontSize($r('sys.float.ohos_id_text_size_button1'))
                .fontColor($r('app.color.font_color_FFFFFF'))
                .fontWeight(FontWeight.Regular)
                .textAlign(TextAlign.Center)
            }
            .borderRadius(30)
            .backgroundColor($r('app.color.background_color_333333'))
            .height(40)
            .width('52%')
            .onClick(() => {
              this.settingManager.restoreValues(this.state.mode)
              this.state.hideSettingView()
            })
          }
          .margin({ top: $r("sys.float.ohos_id_text_paragraph_margin_l") })
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