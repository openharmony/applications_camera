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

import { Action } from '@ohos/common/src/main/ets/default/redux/actions/Action'
import { EventBus } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus'
import { EventBusManager } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager'
import { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store'
import { getStore } from '@ohos/common/src/main/ets/default/redux/store'
import { Log } from '@ohos/common/src/main/ets/default/utils/Log'
import { SettingManager } from '@ohos/common/src/main/ets/default/setting/SettingManager'
import { TabletSettingItem } from '@ohos/common/src/main/ets/default/featurecommon/settingview/tablet/TabletSettingItem'
import { SettingListModel } from '@ohos/common/src/main/ets/default/featurecommon/settingview/model/SettingListModel'
import { SettingGroupItem } from '@ohos/common/src/main/ets/default/featurecommon/settingview/model/SettingData'
import { BaseData } from '@ohos/common/src/main/ets/default/featurecommon/settingview/model/BaseData'

const DEFAULT_FUNCTION = () => {
}

class StateStruct {
  isCloseFlag: boolean = false;
  mode: string = '';
  zoomRatio: number = 0;
}

class SettingViewDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public closeDialog(isCloseFlag: boolean): void {
    this.mDispatch(Action.closeDialog(isCloseFlag));
  }

  public hideSettingView(): void {
    this.mDispatch(Action.showSettingView(false));
  }

  public changeXComponentSize(xComponentWidth: number, xComponentHeight: number): void {
    this.mDispatch(Action.changeXComponentSize(xComponentWidth, xComponentHeight));
  }

  public assistiveGridView(isViewShow: number): void {
    this.mDispatch(Action.assistiveGridView(isViewShow));
  }

  public reStartPreview(zoomRatio: number): void {
    this.mDispatch(Action.reStartPreview(zoomRatio));
  }

  public showBlur(): void {
    this.mDispatch(Action.uiState(false));
  }

  public resetZoomRatio(): void {
    this.mDispatch(Action.changeZoomRatio(1));
  }
}

interface LocalStyleType {
  columns: number
  offset: number
  span: number
}

interface PositionData {
  width: number;
  height: number;
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
  @State settingsList: SettingGroupItem[] = new SettingListModel().getSettingList();
  @State state: StateStruct = new StateStruct()
  @State localStyle: LocalStyleType = { columns: 12, offset: 2, span: 8 }
  private WH_100_100: string = "100%";
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  private mAction: SettingViewDispatcher = new SettingViewDispatcher();

  aboutToAppear(): void{
    Log.info(`${this.TAG} aboutToAppear invoke E`)
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        isCloseFlag: state.settingReducer.isCloseFlag,
        mode: state.modeReducer.mode,
        zoomRatio: state.zoomReducer.zoomRatio
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });

    this.mEventBus.on("windowSize", (data: PositionData) => this.windowSizeChange(data));
    this.mEventBus.on("AspectRatio", (data: PositionData) => this.aspectRatioChange(data));
    this.mEventBus.on("Resolution", (data: PositionData) => this.resolutionChange(data));
    this.mEventBus.on("AssistiveGrid", (data: number) => this.assistiveGridChange(data));
    Log.info(`${this.TAG} aboutToAppear invoke X`);
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`);
    this.mEventBus.off("AspectRatio", (data: PositionData) => this.aspectRatioChange(data));
    this.mEventBus.off("Resolution", (data: PositionData) => this.resolutionChange(data));
    this.mEventBus.off("AssistiveGrid", (data: number) => this.assistiveGridChange(data));
  }

  onBackPress(): boolean {
    Log.info(`${this.TAG} onBackPress invoke X`)
    if (this.state.isCloseFlag){
      this.closeFlag = !this.closeFlag
    } else {
      this.mAction.hideSettingView()
    }
    return true;
  }

  private windowSizeChange(data: PositionData): void {
    this.localStyle = (data.width >= px2vp(1280)) ? { columns: 12, offset: 2, span: 8 } :
      { columns: 8, offset: 1, span: 6 };
  }

  private aspectRatioChange(xComponentSize: PositionData): void {
    if (this.state.mode != 'VIDEO') {
      this.mAction.changeXComponentSize(xComponentSize.width, xComponentSize.height)
      this.mAction.reStartPreview(this.state.zoomRatio)
    }
  }

  private resolutionChange(xComponentSize: PositionData): void {
    if (this.state.mode == 'VIDEO') {
      this.mAction.changeXComponentSize(xComponentSize.width, xComponentSize.height)
      this.mAction.reStartPreview(this.state.zoomRatio)
    }
  }

  private assistiveGridChange(mAssistiveGrid: number): void {
    this.mAction.assistiveGridView(mAssistiveGrid)
  }

  build() {
    Column() {
      Row() {
        Image($r("app.media.ic_public_back"))
          .width(24)
          .height(24)
          .fillColor($r('app.color.settings_ic_public_back_FFFFFF'))
          .onClick(() => {
            this.mAction.hideSettingView()
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
                  ForEach(this.settingsList, (item: SettingGroupItem, index: number) => {
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
                this.mAction.showBlur()
                this.settingManager.restoreValues(this.state.mode)
                this.mAction.resetZoomRatio()
                this.mAction.hideSettingView()
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