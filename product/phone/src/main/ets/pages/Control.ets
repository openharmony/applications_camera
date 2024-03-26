/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import { Action } from '@ohos/common/src/main/ets/default/redux/actions/Action';
import { EventBus } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus';
import { EventBusManager } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager';
import { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store';
import { getStore } from '@ohos/common/src/main/ets/default/redux/store';
import { Log } from '@ohos/common/src/main/ets/default/utils/Log';
import {
  PersistType,
  PreferencesService
} from '@ohos/common/src/main/ets/default/featurecommon/preferences/PreferencesService';

class StateStruct {
  isThirdPartyCall: boolean = false;
  thirdCallAction: string = '';
  isFaCall: boolean = false;
  action: string = '';
  uiEnable: boolean = true;
  modeIndex: number = 0;
  mode: string = 'PHOTO';
  isShowMoreList: boolean = false;
}

class ControlDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeToMode(mode: string): void {
    this.mDispatch(Action.uiState(false));
    this.mDispatch(Action.changeMode(mode));
    this.mDispatch(Action.updateShowBigTextFlag(true));
  }

  public updateModeIndex(index: number): void {
    this.mDispatch(Action.updateModeIndex(index));
  }

  public updateShowMoreList(isShowMoreList: boolean): void {
    this.mDispatch(Action.updateShowMoreList(isShowMoreList));
  }

  public initAction(action: string): void {
    this.mDispatch(Action.initAction(action));
  }

  public initMode(mode: string): void {
    this.mDispatch(Action.initMode(mode));
  }

  public updateListStatus(enable: boolean): void {
    this.mDispatch(Action.uiState(enable));
  }
}

class SwipeModeIndexStruct {
  swipeModeIndex: number = 0;
}


@Component
export struct Control {
  private TAG: string = '[Control]';
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private scroller: Scroller = new Scroller();
  private modeArray: Array<string> = ['PHOTO', 'VIDEO'];
  private itemWidth: number = 56;
  protected mPreferencesService: PreferencesService = PreferencesService.getInstance();
  @State state: StateStruct = new StateStruct();
  private mAction: ControlDispatcher = new ControlDispatcher();
  @State startScroll: number = 0;
  @State endScroll: number = 0;
  @State index: number = 0;

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`);
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        isThirdPartyCall: state.contextReducer.isThirdPartyCall,
        thirdCallAction: state.contextReducer.thirdCallAction,
        isFaCall: state.contextReducer.isFaCall,
        action: state.contextReducer.action,
        uiEnable: state.contextReducer.uiEnable,
        modeIndex: state.modeReducer.modeIndex,
        mode: state.modeReducer.mode,
        isShowMoreList: state.modeReducer.isShowMoreList
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });

    this.appEventBus.on(Action.ACTION_SWIPE_MODE, (data: SwipeModeIndexStruct) => this.swipeChangeMode(data));
    Log.info(`${this.TAG} aboutToAppear X`);
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`);
    this.appEventBus.off(Action.ACTION_SWIPE_MODE, (data: SwipeModeIndexStruct) => this.swipeChangeMode(data));
    Log.info(`${this.TAG} aboutToDisappear X`);
  }

  private changeToMode(modeIndex: number): void {
    Log.info(`${this.TAG} changeToMode modeIndex: ${modeIndex} E`);
    this.scroller.scrollToIndex(modeIndex);
    if (this.modeArray[modeIndex] !== this.state.mode) {
      Log.info(`${this.TAG} this.state.changeToMode(${this.modeArray[modeIndex]})`);
      this.mAction.changeToMode(this.modeArray[modeIndex]);
      this.mPreferencesService.putModeValue(PersistType.FOR_AWHILE, modeIndex);
      this.mPreferencesService.flushMode();
    } else {
      this.mAction.updateListStatus(true);
    }
    Log.info(`${this.TAG} changeToMode X`);
  }

  private getModeFontWeight(modeIndex: number): FontWeight {
    if (this.state.mode === this.modeArray[modeIndex]) {
      return FontWeight.Bold;
    } else {
      return FontWeight.Regular;
    }
  }

  private swipeChangeMode(data: SwipeModeIndexStruct): void {
    this.changeToMode(data.swipeModeIndex);
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomStart }) {
        if ((this.state.isThirdPartyCall || this.state.isFaCall) && this.state.mode === 'PHOTO' && (this.state.thirdCallAction != 'ALL')) {
          Row() {
            Text($r('app.string.photo_mode'))
              .width('100%')
              .height('100%')
              .fontSize(14)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
          }.width('100%').height('100%').offset({ x: -156, y: 0 })
        } else if ((this.state.isThirdPartyCall || this.state.isFaCall) && this.state.mode === 'VIDEO' && (this.state.thirdCallAction != 'ALL')) {
          Row() {
            Text($r('app.string.video_mode'))
              .width('100%')
              .height('100%')
              .fontSize(14)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
          }.width('100%').height('100%').offset({ x: -156, y: 0 })
        } else {
          List({ initialIndex: this.state.modeIndex, scroller: this.scroller }) {
            ListItem() {
            }.width(56).height('100%')

            ListItem() {
              Text($r('app.string.photo_mode'))
                .width('100%')
                .height('100%')
                .fontColor('#fff')
                .fontSize($r("sys.float.ohos_id_text_size_sub_title3"))
                .fontWeight(this.getModeFontWeight(0))
                .textAlign(TextAlign.Center)
                .enabled(this.state.uiEnable)
                .onClick(() => {
                  this.changeToMode(0)
                })
            }.width(56).height('100%')

            ListItem() {
              Text($r('app.string.video_mode'))
                .width('100%')
                .height('100%')
                .fontColor('#fff')
                .fontSize($r("sys.float.ohos_id_text_size_sub_title3"))
                .fontWeight(this.getModeFontWeight(1))
                .textAlign(TextAlign.Center)
                .enabled(this.state.uiEnable)
                .onClick(() => {
                  this.changeToMode(1)
                })
            }.width(56).height('100%')

            ListItem() {
            }.width(56).height('100%')
          }
          .width(this.itemWidth * 3)
          .height('100%')
          .scrollBar(BarState.Off)
          .listDirection(Axis.Horizontal)
          .edgeEffect(EdgeEffect.None)
          .chainAnimation(false)
          .enabled(this.state.uiEnable)
          .onScrollIndex((firstIndex: number, lastIndex: number, centerIndex: number) => {
            Log.info(`${this.TAG} Control scroll index first: ${firstIndex}, centerIndex: ${centerIndex}, last: ${lastIndex}`)
            this.index = firstIndex;
            this.mAction.updateModeIndex(firstIndex);
            Log.info(`${this.TAG} onScrollIndex this.state.modeIndex: ${this.state.modeIndex}`)
          })
          .onScrollStop(() => {
            Log.info(`${this.TAG} onScrollStop`);
            this.changeToMode(this.index);
          })
        }
        Column() {
          Column() {
          }.width(6).height(6).borderRadius(3).backgroundColor('#007DFF')
        }.width('100%').height(18).offset({ x: -156, y: 0 })
      }.width('100%').height(58)
    }
  }
}