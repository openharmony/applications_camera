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

import display from '@ohos.display';
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
  isFaCall: boolean = false;
  action: string = '';
  uiEnable: boolean = true;
  modeIndex: number = 1;
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

  public thirdPartyCall(isThirdPartyCall: boolean, action: string): void {
    this.mDispatch(Action.thirdPartyCall(isThirdPartyCall, action));
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
  private TAG: string = '[Control]'
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  private scroller: Scroller = new Scroller()
  private modeArray: Array<string> = ['MULTI', 'PHOTO', 'VIDEO']
  private isScroll: boolean = false
  private scrollDistance: number = 0
  protected mPreferencesService: PreferencesService = PreferencesService.getInstance()
  @State state: StateStruct = new StateStruct()
  private mAction: ControlDispatcher = new ControlDispatcher();
  @State modeBarItemLeftWidth: number = 225
  @State modeBarItemRightWidth: number = 225
  @State startScroll: number = 0
  @State endScroll: number = 0
  @State index: number = 0

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        isThirdPartyCall: state.contextReducer.isThirdPartyCall,
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

    display.getDefaultDisplay().then((dis) => {
      this.modeBarItemLeftWidth = px2vp(dis.width) / 2 - 156
      this.modeBarItemRightWidth = px2vp(dis.width) / 2 - 148
    })
    this.appEventBus.on(Action.ACTION_SWIPE_MODE, (data: SwipeModeIndexStruct) => this.swipeChangeMode(data));
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_SWIPE_MODE, (data: SwipeModeIndexStruct) => this.swipeChangeMode(data))
    Log.info(`${this.TAG} aboutToDisappear X`)
  }

  private changeToMode(modeIndex: number): void {
    Log.debug(`${this.TAG} changeToMode modeIndex: ${modeIndex} E`)
    this.scroller.scrollToIndex(modeIndex)
    if (this.modeArray[modeIndex] !== this.state.mode) {
      Log.debug(`${this.TAG} this.state.changeToMode(${this.modeArray[modeIndex]})`)
      this.mAction.changeToMode(this.modeArray[modeIndex])
      this.mPreferencesService.putModeValue(PersistType.FOR_AWHILE, modeIndex)
      this.mPreferencesService.flushMode()
    } else {
      this.mAction.updateListStatus(true)
    }
    Log.debug(`${this.TAG} changeToMode X`)
  }

  private getModeFontWeight(modeIndex: number): FontWeight {
    if (this.state.mode === this.modeArray[modeIndex]) {
      return FontWeight.Bold
    } else {
      return FontWeight.Regular
    }
  }

  private swipeChangeMode(data: SwipeModeIndexStruct): void {
    this.changeToMode(data.swipeModeIndex)
  }

  private scrollSwitchMode(): void {
    if (this.index == 1 && Math.abs(this.scrollDistance) <= px2vp(28)) {
      this.changeToMode(1)
    }
    if (this.index == 1 && (this.scrollDistance) > px2vp(28)) {
      this.changeToMode(2)
    }
    if (this.index == 1 && (this.scrollDistance) < px2vp(-28)) {
      this.changeToMode(0)
    }
    if (this.index == 0 && (this.scrollDistance < px2vp(36))) {
      this.changeToMode(0)
    }
    if (this.index == 0 && this.scrollDistance <= px2vp(92) && this.scrollDistance >= px2vp(36)) {
      this.changeToMode(1)
    }
    if (this.index == 0 && this.scrollDistance > px2vp(92)) {
      this.changeToMode(2)
    }
    if (this.index == 2 && (this.scrollDistance > px2vp(-28))) {
      this.changeToMode(2)
    }
    if (this.index == 2 && this.scrollDistance <= px2vp(-28) && this.scrollDistance >= px2vp(-92)) {
      this.changeToMode(1)
    }
    if (this.index == 2 && this.scrollDistance < px2vp(-92)) {
      this.changeToMode(0)
    }
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomStart }) {
        if ((this.state.isThirdPartyCall || this.state.isFaCall) && this.state.mode === 'PHOTO') {
          Row() {
            Text($r('app.string.photo_mode'))
              .width('100%')
              .height('100%')
              .fontSize(14)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
          }.width('100%').height('100%')
        } else if ((this.state.isThirdPartyCall || this.state.isFaCall) && this.state.mode === 'VIDEO') {
          Row() {
            Text($r('app.string.video_mode'))
              .width('100%')
              .height('100%')
              .fontSize(14)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
          }.width('100%').height('100%')
        } else {
          List({ initialIndex: this.state.modeIndex, scroller: this.scroller }) {
            ListItem() {
            }.width(64).height('100%')

            ListItem() {
            }.width(56).height('100%')

            ListItem() {
            }.width(this.modeBarItemLeftWidth).height('100%')

            ListItem() {
              Text($r('app.string.multi_mode'))
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
            }.width(72).height('100%')

            ListItem() {
              Text($r('app.string.photo_mode'))
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
              Text($r('app.string.video_mode'))
                .width('100%')
                .height('100%')
                .fontColor('#fff')
                .fontSize($r("sys.float.ohos_id_text_size_sub_title3"))
                .fontWeight(this.getModeFontWeight(2))
                .textAlign(TextAlign.Center)
                .enabled(this.state.uiEnable)
                .onClick(() => {
                  this.changeToMode(2)
                })
            }.width(56).height('100%')

            ListItem() {
            }.width(this.modeBarItemRightWidth).height('100%')

            ListItem() {
            }.width(64).height('100%')

            ListItem() {
            }.width(56).height('100%')
          }
          .width('100%')
          .height('100%')
          .listDirection(Axis.Horizontal)
          .edgeEffect(EdgeEffect.None)
          .chainAnimation(false)
          .enabled(this.state.uiEnable)
          .onScrollIndex((firstIndex: number, lastIndex: number) => {
            Log.debug(`${this.TAG} Control scroll index first: ${firstIndex}, last: ${lastIndex}`)
            this.mAction.updateModeIndex(firstIndex)
            Log.debug(`${this.TAG} onScrollIndex this.state.modeIndex: ${this.state.modeIndex}`)
          })
          .onScrollStop(() => {
            Log.info(`${this.TAG} onScrollStop`)
            this.scrollSwitchMode()
          })
          .onScroll((scrollOffset: number, scrollState: ScrollState) => {
            if (scrollState === ScrollState.Fling) {
              this.scrollDistance += px2vp(scrollOffset)
              if (!this.isScroll) {
                this.isScroll = true
                this.mAction.updateListStatus(false)
              }
            }
          })
          .onTouch((event?: TouchEvent) => {
            if (!event) {
              return;
            }
            if (event.type === TouchType.Down) {
              this.scrollDistance = 0
              this.index = this.modeArray.indexOf(this.state.mode)
              this.startScroll = event.touches[0].screenX
            }
            if (event.type === TouchType.Up) {
              this.endScroll = event.touches[0].screenX
              this.scrollDistance = px2vp(this.startScroll - this.endScroll)
              this.isScroll = false
            }
          })
        }
        Column() {
          Column() {
          }.width(6).height(6).borderRadius(3).backgroundColor('#007DFF')
        }.width('100%').height(18)
      }.width('100%').height(58)
    }
  }
}