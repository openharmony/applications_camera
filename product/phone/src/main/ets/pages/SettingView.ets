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
import { Action } from '@ohos/common/src/main/ets/default/redux/actions/Action';
import { EventBusManager } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager';
import { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store';
import { getStore } from '@ohos/common/src/main/ets/default/redux/store';
import { Log } from '@ohos/common/src/main/ets/default/utils/Log';
import { SettingManager } from '@ohos/common/src/main/ets/default/setting/SettingManager';
import { SettingItem } from '@ohos/common/src/main/ets/default/featurecommon/settingview/phone/SettingItem';
import { SettingListModel } from '@ohos/common/src/main/ets/default/featurecommon/settingview/model/SettingListModel';
import { SettingGroupItem } from '@ohos/common/src/main/ets/default/featurecommon/settingview/model/SettingData';

class StateStruct {
  isCloseFlag: boolean = false;
  mode: string = '';
  zoomRatio: number = 1;
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
}

class SizeStruct {
  width: number = 0;
  height: number = 0;
}

@Component
export struct SettingView {
  private TAG: string = '[SettingView]:'
  private settingManager = SettingManager.getInstance()
  @State checkNameList: Array<string> = ["4:3", "[16:9] 720p"]
  @State closeFlag: boolean = false
  @State tempGutter: number = 12; //列间距
  @State tempMargin: number = 12; //两侧间距
  @State settingsList: SettingGroupItem[] = new SettingListModel().getSettingList()
  @State state: StateStruct = new StateStruct()
  private mEventBus = EventBusManager.getInstance().getEventBus()
  private WH_100_100: string = "100%";
  private mAction: SettingViewDispatcher = new SettingViewDispatcher();

  aboutToAppear(): void {
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
    this.mEventBus.on("AspectRatio", (data: SizeStruct) => this.aspectRatioChange(data));
    this.mEventBus.on("Resolution", (data: SizeStruct) => this.resolutionChange(data));
    this.mEventBus.on("AssistiveGrid", (data: number) => this.assistiveGridChange(data));
    Log.info(`${this.TAG} aboutToAppear invoke X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    this.mEventBus.off("AspectRatio", (data: SizeStruct) => this.aspectRatioChange(data));
    this.mEventBus.off("Resolution", (data: SizeStruct) => this.resolutionChange(data));
    this.mEventBus.off("AssistiveGrid", (data: number) => this.assistiveGridChange(data));
  }

  onBackPress(): boolean {
    Log.info(`${this.TAG} onBackPress invoke X`)
    if (this.state.isCloseFlag) {
      this.closeFlag = !this.closeFlag
    } else {
      this.mAction.hideSettingView()
    }
    return true;
  }

  private aspectRatioChange(xComponentSize: SizeStruct): void {
    if (this.state.mode != 'VIDEO') {
      this.mAction.changeXComponentSize(xComponentSize.width, xComponentSize.height)
      this.mAction.reStartPreview(this.state.zoomRatio)
    }
  }

  private resolutionChange(xComponentSize: SizeStruct): void {
    if (this.state.mode == 'VIDEO') {
      this.mAction.changeXComponentSize(xComponentSize.width, xComponentSize.height)
      this.mAction.reStartPreview(this.state.zoomRatio)
    }
  }

  private assistiveGridChange(mAssistiveGrid: number): void {
    this.mAction.assistiveGridView(mAssistiveGrid)
  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
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
      .padding({ left: 24 })
      .width(this.WH_100_100)
      .height(56)
      .margin({ top: deviceInfo.deviceType !== 'default' ? 25 : 0 })

      Scroll() {
        Column() {
          GridContainer({ columns: 4, gutter: this.tempGutter, margin: this.tempMargin }) {
            List() {
              ForEach(this.settingsList, (item: SettingGroupItem, index: number) => {
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
              this.mAction.hideSettingView()
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