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
import { ComponentPosition }  from '@ohos/common/src/main/ets/default/utils/ComponentPosition'
import { EventBus }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus'
import { EventBusManager }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager'
import { getStore, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store'
import { Log } from '@ohos/common/src/main/ets/default/utils/Log'
import { PersistType, PreferencesService } from '@ohos/common/src/main/ets/default/featurecommon/preferences/PreferencesService'
import { SettingManager } from '@ohos/common/src/main/ets/default/setting/SettingManager'

let controlLandState = (state: OhCombinedState) => {
  return {
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall,
    isFaCall: state.ContextReducer.isFaCall,
    action: state.ContextReducer.action,
    uiEnable: state.ContextReducer.uiEnable,
    modeIndex: state.ModeReducer.modeIndex,
    mode: state.ModeReducer.mode,
    isShowMoreList: state.ModeReducer.isShowMoreList,
  }
}

let controlLandDispatcher = (dispatch) => {
  return {
    changeToMode: (mode: string) => {
      dispatch(Action.uiState(false))
      dispatch(Action.updateMode(mode))
      dispatch(Action.changeMode(mode))
      dispatch(Action.updateShowBigTextFlag(true))
    },
    updateModeIndex: (index: number) => {
      dispatch(Action.updateModeIndex(index))
    },
    updateShowMoreList: (isShowMoreList) => {
      dispatch(Action.updateShowMoreList(isShowMoreList))
    },
    thirdPartyCall: (isThirdPartyCall: boolean, action: string) => {
      dispatch(Action.thirdPartyCall(isThirdPartyCall, action))
    },
    initAction: (action: string) => {
      dispatch(Action.initAction(action))
    },
    initMode: (mode: string) => {
      dispatch(Action.initMode(mode))
    },
    changeXComponentSize: (xComponentWidth: number, xComponentHeight: number) => {
      dispatch(Action.changeXComponentSize(xComponentWidth, xComponentHeight))
    },
  }
}

class StateStruct {
  isThirdPartyCall
  isFaCall
  action
  uiEnable
  modeIndex
  mode
  isShowMoreList
  changeToMode: Function
  updateModeIndex: Function
  updateShowMoreList: Function
  thirdPartyCall: Function
  initAction: Function
  initMode: Function
  changeXComponentSize: Function

}

type ScreenSizeType = {
  width: number
  height: number
}

@Component
export struct ControlLand {
  private TAG: string = '[ControlLand]:'
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  private scroller: Scroller = new Scroller()
  private settingManager = SettingManager.getInstance()
  private mConnect: any
  private modeArray: Array<string> = ['MULTI', 'PHOTO', 'VIDEO'] //, 'MORE'
  private touchOff: boolean = true
  private scrollDistance: number = 0
  protected mPreferencesService: PreferencesService = PreferencesService.getInstance()

  @State state: StateStruct = new StateStruct()
  @State startScroll: number = 0
  @State endScroll: number = 0
  @State index: number = 0
  @Link screenSize: ScreenSizeType

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(controlLandState, controlLandDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_SWIPE_MODE, this.swipeChangeMode.bind(this))
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_SWIPE_MODE, this.swipeChangeMode.bind(this))
    this.mConnect?.destroy()
    Log.info(`${this.TAG} aboutToDisappear X`)
  }

  private closeMoreListView() {
    if (this.state.isShowMoreList) {
      this.state.updateShowMoreList(false)
    }
  }

  private changeToMode(modeIndex: number, callType?: string) {
    Log.debug(`${this.TAG} changeToMode modeIndex: ${modeIndex} E`)
    this.scroller.scrollToIndex(modeIndex)
    if (callType === 'begin') return;
    if (this.modeArray[modeIndex] !== this.state.mode) {
      Log.debug(`${this.TAG} this.state.changeToMode(${this.modeArray[modeIndex]})`)
      this.state.changeToMode(this.modeArray[modeIndex])
      let xComponentSize = this.settingManager.getPreviewDisplaySize(this.state.mode)
      this.state.changeXComponentSize(xComponentSize.width, xComponentSize.height)
      this.mPreferencesService.putModeValue(PersistType.FOR_AWHILE, modeIndex)
      this.mPreferencesService.flushMode()
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

  private swipeChangeMode(data) {
    this.changeToMode(data.swipeModeIndex)
  }

  private scrollSwitchMode(callType: string) {
    if (this.index == 1 && Math.abs(this.scrollDistance) <= px2vp(20)) {
      this.changeToMode(1, callType)
    }
    if (this.index == 1 && (this.scrollDistance) > px2vp(20)) {
      this.changeToMode(0, callType)
    }
    if (this.index == 1 && (this.scrollDistance) < px2vp(-20)) {
      this.changeToMode(2, callType)
    }
    if (this.index == 0 && (this.scrollDistance > px2vp(-25))) {
      this.changeToMode(0, callType)
    }
    if (this.index == 0 && this.scrollDistance >= px2vp(-50) && this.scrollDistance <= px2vp(-25)) {
      this.changeToMode(1, callType)
    }
    if (this.index == 0 && this.scrollDistance < px2vp(-50)) {
      this.changeToMode(2, callType)
    }
    if (this.index == 2 && (this.scrollDistance < px2vp(25))) {
      this.changeToMode(2, callType)
    }
    if (this.index == 2 && this.scrollDistance >= px2vp(25) && this.scrollDistance <= px2vp(50)) {
      this.changeToMode(1, callType)
    }
    if (this.index == 2 && this.scrollDistance > px2vp(50)) {
      this.changeToMode(0, callType)
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
        if ((this.state.isThirdPartyCall || this.state.isFaCall) && this.state.mode === 'PHOTO') {
          Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
            Text($r('app.string.photo_mode'))
              .fontSize($r("sys.float.ohos_id_text_size_body1"))
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }.layoutWeight(1).height('100%')
        } else if ((this.state.isThirdPartyCall || this.state.isFaCall) && this.state.mode === 'VIDEO') {
          Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
            Text($r('app.string.video_mode'))
              .fontSize($r("sys.float.ohos_id_text_size_body1"))
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }.layoutWeight(1).height('100%')
        } else {
          List({ initialIndex: this.state.modeIndex, scroller: this.scroller }) {
            if (ComponentPosition.isUnfoldControl(this.screenSize.width, this.screenSize.height)) {
              ListItem() {
              }.width('100%').height(32)
            }
            ListItem() {
            }.width('100%').height(32)

            ListItem() {
              Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
                Text($r('app.string.multi_mode'))
                  .fontSize($r("sys.float.ohos_id_text_size_body1"))
                  .fontColor(Color.White)
                  .enabled(this.state.uiEnable)
                  .onClick(async () => {
                    this.changeToMode(0)
                  })
                  .fontWeight(this.getModeFontWeight(0))
              }.width('100%').height('100%')
            }.width('100%').height(32)

            ListItem() {
              Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
                Text($r('app.string.photo_mode'))
                  .fontSize($r("sys.float.ohos_id_text_size_body1"))
                  .fontColor(Color.White)
                  .enabled(this.state.uiEnable)
                  .onClick(async () => {
                    this.changeToMode(1)
                  })
                  .fontWeight(this.getModeFontWeight(1))
              }.width('100%').height('100%')
            }.width('100%').height(32)

            ListItem() {
              Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
                Text($r('app.string.video_mode'))
                  .fontSize($r("sys.float.ohos_id_text_size_body1"))
                  .fontColor(Color.White)
                  .enabled(this.state.uiEnable)
                  .onClick(async () => {
                    this.changeToMode(2)
                  })
                  .fontWeight(this.getModeFontWeight(2))
              }.width('100%').height('100%')
            }.width('100%').height(32)

            ListItem() {
            }.width('100%').height(32)

            ListItem() {
            }.width('100%').height(32)
          }
          .layoutWeight(1)
          .height('100%')
          .edgeEffect(EdgeEffect.None)
          .chainAnimation(false)
          .onScrollIndex((firstIndex: number, lastIndex: number) => {
            Log.debug(`${this.TAG} Control scroll index first: ${firstIndex}, last: ${lastIndex}`)
            this.state.updateModeIndex(firstIndex)
            Log.debug(`${this.TAG} onScrollIndex this.state.modeIndex: ${this.state.modeIndex}`)
          })
          // @ts-ignore
          .onScrollBegin(() => {
            if (!this.touchOff) this.scrollSwitchMode('begin')
          })
          .enabled(this.state.uiEnable)
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.touchOff = true
              this.index = this.modeArray.indexOf(this.state.mode)
              this.startScroll = event.touches[0].screenY
            }
            if (event.type === TouchType.Up) {
              this.endScroll = event.touches[0].screenY
              this.scrollDistance = px2vp(this.endScroll - this.startScroll)
              this.touchOff = false
              this.scrollSwitchMode('touch')
            }
          })
        }
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start, justifyContent: FlexAlign.Center }) {
          Column() {
          }.borderRadius(3).width(6).height(6).backgroundColor('#007DFF')
          //            .shadow({radius: 5, color: 'argb(#7F000000)', offsetX: 0, offsetY: 0})
        }.width(18).height('100%').margin({ left: 8 })
      }.width('100%').height('100%')
    }.width(98).height(ComponentPosition.getControlHeight(this.screenSize.width, this.screenSize.height)).zIndex(2)
  }
}