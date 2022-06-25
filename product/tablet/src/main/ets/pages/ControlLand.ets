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

import { Log } from '../../../../../../common/src/main/ets/default/utils/Log'
import getStore, { OhCombinedState } from '../../../../../../common/src/main/ets/default/redux/store'
import { Action } from '../../../../../../common/src/main/ets/default/redux/actions/Action'
import { SettingManager } from '../../../../../../common/src/main/ets/default/setting/SettingManager'
import wantConstant from '@ohos.ability.wantConstant';
import { EventBus } from '../../../../../../common/src/main/ets/default/worker/eventbus/EventBus'
import EventBusManager from '../../../../../../common/src/main/ets/default/worker/eventbus/EventBusManager'

let controlLandState = (state: OhCombinedState) => {
  return {
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall,
    action: state.ContextReducer.action,
    xComponentChangeFlag: state.PreviewReducer.xComponentChangeFlag,
    uiEnable: state.ContextReducer.uiEnable,
    modeIndex: state.ModeReducer.modeIndex,
    mode: state.ModeReducer.mode,
    isShowMoreList: state.ModeReducer.isShowMoreList
  }
}

let controlLandDispatcher = (dispatch) => {
  return {
    changeToMode: (mode: string) => {
      dispatch(Action.setMode(mode))
      dispatch(Action.UiState(false))
      dispatch(Action.UpdateShowBigTextFlag(true))
    },
    updateModeIndex: (index: number) => {
      dispatch(Action.UpdateModeIndex(index))
    },
    updateShowMoreList: (isShowMoreList) => {
      dispatch(Action.UpdateShowMoreList(isShowMoreList))
    },
    updateXComponentChangeFlag: (xComponentChangeFlag: boolean) => {
      dispatch(Action.UpdateXComponentChangeFlag(xComponentChangeFlag))
    },
    thirdPartyCall: (isThirdPartyCall: boolean, action: string) => {
      dispatch(Action.thirdPartyCall(isThirdPartyCall, action))
    },
    initAction: (action: string) => {
      dispatch(Action.InitAction(action))
    },
    initMode: (mode: string) => {
      dispatch(Action.initMode(mode))
    }
  }
}


@Component
export struct ControlLand {
  private TAG: string = '[ControlLand]:'
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  private scroller: Scroller = new Scroller()
  private settingManager = SettingManager.getInstance()
  private mConnect: any
  private modeArray: Array<string> = ['MULTI', 'PHOTO', 'VIDEO'] //, 'MORE'

  @State state: any = {}

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(controlLandState, controlLandDispatcher)(this.state)
    let startWantAction = globalThis.cameraAbilityWant.action
    Log.info(`${this.TAG}  Camera MainAbility lanuchWant action: ${startWantAction}`)
    if (!globalThis?.cameraNewWant && startWantAction) {
      Log.info(`${this.TAG} thirdParty called`)
      this.state.thirdPartyCall(true, startWantAction)
      switch (startWantAction) {
        case wantConstant.Action.ACTION_IMAGE_CAPTURE:
          this.state.initMode('PHOTO')
          this.state.updateModeIndex(1)
          break
        case wantConstant.Action.ACTION_VIDEO_CAPTURE:
          this.state.initMode('VIDEO')
          this.state.updateModeIndex(2)
          break
        default:
          break
      }
    }
    this.appEventBus.on(Action.ACTION_SWIPE_MODE, this.swipeChangeMode.bind(this))
    this.calledByFa()
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_SWIPE_MODE, this.swipeChangeMode.bind(this))
    this.mConnect.destroy()
    Log.info(`${this.TAG} aboutToDisappear X`)
  }

  private closeMoreListView() {
    if (this.state.isShowMoreList) {
      this.state.updateShowMoreList(false)
    }
  }
  
  private changeToMode(modeIndex: number) {
    Log.debug(`${this.TAG} changeToMode modeIndex: ${modeIndex} E`)
    if (this.modeArray[modeIndex] !== this.state.mode) {
//      if ( modeIndex !== 3 ) {
//        this.closeMoreListView()
//      } else {
//        this.state.updateShowMoreList(true)
//      }
      this.scroller.scrollToIndex(modeIndex)
      Log.debug(`${this.TAG} this.state.changeToMode(${this.modeArray[modeIndex]})`)
      this.state.changeToMode(this.modeArray[modeIndex])
      this.state.updateXComponentChangeFlag(!this.state.xComponentChangeFlag)
      this.state.updateControlFontStyle(this.modeArray[modeIndex])
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

  private calledByFa(): void {
    Log.info(`${this.TAG} calledByFa invoke E`)
    let action: string = ""
    let uri: string = ""

    if (globalThis?.cameraNewWant) {
      Log.debug((`${this.TAG} cameraNewWant: ${JSON.stringify(globalThis.cameraNewWant)}`))
      if (globalThis.cameraNewWant?.parameters?.from) {
        action = globalThis.cameraNewWant.parameters.from
      }
      if (globalThis.cameraNewWant?.parameters?.uri) {
        uri = globalThis.cameraNewWant.parameters.uri
      }
    } else if (globalThis?.cameraAbilityWant) {
      Log.debug(`${this.TAG} cameraAbilityWant: ${JSON.stringify(globalThis.cameraAbilityWant)}`)
      if (globalThis.cameraAbilityWant?.parameters?.from) {
        action = globalThis.cameraAbilityWant.parameters.from
      }
      if (globalThis.cameraAbilityWant?.parameters?.uri) {
        uri = globalThis.cameraAbilityWant.parameters.uri
      }
    } else {
      return
    }
    Log.info(`${this.TAG} action: ${action}  uri: ${uri}`)

    if (action === "FA") {
      switch (uri) {
        case "capture":
          this.state.initMode('PHOTO')
          this.state.updateModeIndex(1)
          break
        case "video":
          this.state.initMode('VIDEO')
          this.state.updateModeIndex(2)
          break
        default:
          Log.info(`${this.TAG} FA default`)
          break
      }
    }
    Log.info(`${this.TAG} calledByFa invoke X`)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
        if (this.state.isThirdPartyCall && this.state.action === wantConstant.Action.ACTION_IMAGE_CAPTURE) {
          Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
            Text($r('app.string.photo_mode'))
//              .shadow({radius: 2, color: 'rgba(51, 0, 0, 0.2)', offsetX: 0, offsetY: 0})
              .fontSize($r("sys.float.ohos_id_text_size_body1"))
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }.layoutWeight(1).height('100%')
        } else if (this.state.isThirdPartyCall && this.state.action === wantConstant.Action.ACTION_VIDEO_CAPTURE) {
          Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
            Text($r('app.string.video_mode'))
//              .shadow({radius: 2, color: 'rgba(51, 0, 0, 0.2)', offsetX: 0, offsetY: 0})
              .fontSize($r("sys.float.ohos_id_text_size_body1"))
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }.layoutWeight(1).height('100%')
        } else {
          List({ initialIndex: this.state.modeIndex, scroller: this.scroller }) {
            ListItem() {}.width('100%').height(32)
            ListItem() {}.width('100%').height(32)
            ListItem() {
              Flex({direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End}) {
                Text($r('app.string.multi_mode'))
                  .fontSize($r("sys.float.ohos_id_text_size_body1"))
                  .fontColor(Color.White)
//                  .shadow({radius: 2, color: 'rgba(51, 0, 0, 0.2)', offsetX: 0, offsetY: 0})
                  .enabled(this.state.uiEnable)
                  .onClick(async () => {this.changeToMode(0)})
                  .fontWeight(this.getModeFontWeight(0))
              }.width('100%').height('100%')
            }.width('100%').height(32)
            ListItem() {
              Flex({direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End}) {
                Text($r('app.string.photo_mode'))
//                  .shadow({radius: 2, color: 'rgba(51, 0, 0, 0.2)', offsetX: 0, offsetY: 0})
                  .fontSize($r("sys.float.ohos_id_text_size_body1"))
                  .fontColor(Color.White)
                  .enabled(this.state.uiEnable)
                  .onClick(async () => {this.changeToMode(1)})
                  .fontWeight(this.getModeFontWeight(1))
              }.width('100%').height('100%')
            }.width('100%').height(32)
            ListItem() {
              Flex({direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End}) {
                Text($r('app.string.video_mode'))
//                  .shadow({radius: 2, color: 'rgba(51, 0, 0, 0.2)', offsetX: 0, offsetY: 0})
                  .fontSize($r("sys.float.ohos_id_text_size_body1"))
                  .fontColor(Color.White)
                  .enabled(this.state.uiEnable)
                  .onClick(async () => {this.changeToMode(2)})
                  .fontWeight(this.getModeFontWeight(2))
              }.width('100%').height('100%')
            }.width('100%').height(32)
//	          ListItem() {
//              Flex({direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End}) {
//                Text($r('app.string.more_list'))
//                  .fontSize($r("sys.float.ohos_id_text_size_body1"))
//                  .fontWeight(this.getModeFontWeight(3))
//                  .fontColor(Color.White)
//                  .enabled(this.state.uiEnable)
//                  .onClick(async () => {this.changeToMode(3)})
//                  .fontWeight(this.getModeFontWeight(3))
//              }.width('100%').height('100%')
//            }.width('100%').height(32)
            ListItem() {}.width('100%').height(32)
            ListItem() {}.width('100%').height(32)
          }
          .layoutWeight(1)
          .height(160)
          .edgeEffect(EdgeEffect.None)
          .chainAnimation(false)
          .onScrollIndex((firstIndex: number, lastIndex: number) => {
            Log.debug(`${this.TAG} Control scroll index first: ${firstIndex}, last: ${lastIndex}`)
            this.state.updateModeIndex(firstIndex)
            Log.debug(`${this.TAG} onScrollIndex this.state.modeIndex: ${this.state.modeIndex}`)
          })
          .enabled(this.state.uiEnable)
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Up) {
              Log.debug(`${this.TAG} modeIndex == ${this.state.modeIndex}`)
              this.changeToMode(this.state.modeIndex)
            }
          })
        }
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start, justifyContent: FlexAlign.Center }) {
          Column() {}.borderRadius(3).width(6).height(6).backgroundColor('#1095E8')
//            .shadow({radius: 5, color: 'argb(#7F000000)', offsetX: 0, offsetY: 0})
        }.width(26).height(160).margin({ left: 8 })
      }.width('100%').height('100%')
    }.width(128).height(160).zIndex(2)
  }
}