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

import { Action }  from '@ohos/common/src/main/ets/default/redux/actions/Action'
import { EventBus }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus'
import { EventBusManager }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager'
import { getStore, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store'
import { Log } from '@ohos/common/src/main/ets/default/utils/Log'
import { SettingManager } from '@ohos/common/src/main/ets/default/setting/SettingManager'
import { TabletSettingItem } from '@ohos/common/src/main/ets/default/featurecommon/settingview/tablet/TabletSettingItem'
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
    showBlur:() => {
      dispatch(Action.uiState(false))
    },
    resetZoomRatio: () => {
      dispatch(Action.changeZoomRatio(1))
    },
  }
}

class StateStruct {
  isCloseFlag
  mode
  zoomRatio
  closeDialog: Function
  hideSettingView: Function
  changeXComponentSize: Function
  assistiveGridView: Function
  reStartPreview: Function
  showBlur: Function
  resetZoomRatio: Function
}

type LocalStyleType = {
  columns: number
  offset: number
  span: number
}

@Component
export struct SettingView {
  private TAG: string = '[SettingView]:'
  private settingManager = SettingManager.getInstance()
  private scroller: Scroller = new Scroller();
  @State checkNameList: Array<string> = ["4:3", "[16:9] 720p"]
  @State closeFlag: boolean = false
  @State tempGutter: number = 12; //列间距
  @State tempMargin: number = 12; //两侧间距
  @State settingsList: any[] = new SettingListModel().getSettingList()
  @State state: StateStruct = new StateStruct()
  @State localStyle: LocalStyleType = { "columns": 12, "offset": 2, "span": 8 }
  private WH_100_100: string = "100%";
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  aboutToAppear(): void{
    Log.info(`${this.TAG} aboutToAppear invoke E`)
    getStore().connect(localState, localDispatcher)(this.state)
    this.mEventBus.on("windowSize", this.windowSizeChange.bind(this))
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
    if (this.state.isCloseFlag){
      this.closeFlag = !this.closeFlag
    } else {
      this.state.hideSettingView()
    }
    return true;
  }

  private windowSizeChange(data) {
    this.localStyle =  (data.width >= px2vp(1280)) ? { "columns": 12, "offset": 2, "span": 8 } :
      { "columns": 8, "offset": 1, "span": 6 }
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
    Column() {
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
      .width(this.WH_100_100)
      .height(56)
      .margin({ left: 48 })

      Scroll(this.scroller) {
        Column() {
          GridContainer({ columns: this.localStyle.columns, gutter: this.tempGutter, margin: this.tempMargin }) {
            Row() {
              Column() {
                List() {
                  ForEach(this.settingsList, (item, index) => {
                    ListItem() {
                      TabletSettingItem({
                        settingsList: $settingsList,
                        closeFlag: $closeFlag,
                        item: item,
                        index: index
                      })
                    }
                  })
                }
              }.useSizeType({
                xs: { span: this.localStyle.span, offset: this.localStyle.offset },
                sm: { span: this.localStyle.span, offset: this.localStyle.offset },
                md: { span: this.localStyle.span, offset: this.localStyle.offset },
                lg: { span: this.localStyle.span, offset: this.localStyle.offset }
              })
            }
          }

          GridContainer({ columns: 12, gutter: this.tempGutter, margin: this.tempMargin }) {
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
              .useSizeType({
                xs: { span: 4, offset: 4 },
                sm: { span: 4, offset: 4 },
                md: { span: 4, offset: 4 },
                lg: { span: 4, offset: 4 }
              })
              .onClick(() => {
                this.state.showBlur()
                this.settingManager.restoreValues(this.state.mode)
                this.state.resetZoomRatio()
                this.state.hideSettingView()
              })
            }.margin({ top: $r("sys.float.ohos_id_text_paragraph_margin_l") , bottom: 70 })
          }
        }
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
    }
    .height(this.WH_100_100)
    .backgroundColor(Color.Black)
  }
}