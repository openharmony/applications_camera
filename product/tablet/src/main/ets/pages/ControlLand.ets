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

////import ability_featureAbility from '@ohos.ability.featureAbility';
//import router from '@system.router';
//import wantConstant from '@ohos.ability.wantConstant';
//
//import { AsyncManager } from '../../../../../../common/src/main/ets/default/Utils/AsyncManager'
////import {CameraService} from '../../../../../../../common/src/main/ets/default/Camera/CameraService.ets';
//import { changePreviewSize } from '../../../../../../common/src/main/ets/default/redux/actions/ModeChange'
//import { CLog } from '../../../../../../common/src/main/ets/default/Utils/CLog'
//import getStore from '../../../../../../common/src/main/ets/default/redux/store'
//import { ModeConfig } from '../common/ModeConfig'
//import { SettingsUtil } from '../../../../../../common/src/main/ets/default/Utils/SettingsUtil'
//
//let changeModeState = (state) => {
//  return {
//    number: state.ModeChangeReducer.number,
//    res: state.ModeChangeReducer.res
//  }
//}
//
//let changeModeDispatch = (dispatch) => {
//  return {
//    onclickPhoto: () => {
//      CLog.info('[ControlLand]: zhaochong: onclickPhoto1')
//      dispatch(changePreviewSize(154))
//      CLog.info('[ControlLand]: zhaochong: onclickPhoto2')
//    },
//    onclickVideo: () => dispatch(changePreviewSize(0))
//  }
//}

import display from '@ohos.display'

import { CLog } from '../../../../../../common/src/main/ets/default/Utils/CLog'
import getStore from '../../../../../../common/src/main/ets/default/redux/store'
import { Action } from '../../../../../../common/src/main/ets/default/redux/actions/Action'
import { SettingsUtil } from '../../../../../../common/src/main/ets/default/Utils/SettingsUtil'
import wantConstant from '@ohos.ability.wantConstant';
import { EventBus } from '../../../../../../common/src/main/ets/default/Utils/EventBus'
import EventBusManager from '../../../../../../common/src/main/ets/default/Utils/EventBusManager'

let controlLandState = (state) => {
  return {
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall,
    action: state.ContextReducer.action,
    xComponentChangeFlag: state.PreviewReducer.xComponentChangeFlag,
    uiEnable: state.UiReducer.uiEnable,
    modeIndex: state.UiReducer.modeIndex,
    multiFontWeight: state.UiReducer.multiFontWeight,
    photoFontWeight: state.UiReducer.photoFontWeight,
    videoFontWeight: state.UiReducer.videoFontWeight,
    multiFontSize: state.UiReducer.multiFontSize,
    photoFontSize: state.UiReducer.photoFontSize,
    videoFontSize: state.UiReducer.videoFontSize,
    modeBarItemWidth: state.UiReducer.modeBarItemWidth,
    mode: state.ModeReducer.mode,
    isShowMoreList: state.UiReducer.isShowMoreList
  }
}

let controlLandDispatcher = (dispatch) => {
  return {
    changeToMode: (mode: string) => {
      dispatch(Action.UiState(false))
      dispatch(Action.ChangeMode(mode))
      dispatch(Action.UpdateShowBigTextFlag(true))
    },
    updateModeIndex: (index: number) => {
      dispatch(Action.UpdateModeIndex(index))
    },
    updateModeBarItemWidth: (width: number) => {
      dispatch(Action.UpdateModeBarItemWidth(width))
    },
    updateShowMoreList: (isShowMoreList) => {
      dispatch(Action.UpdateShowMoreList(isShowMoreList))
    },
    updateXComponentChangeFlag: (xComponentChangeFlag: boolean) => {
      dispatch(Action.UpdateXComponentChangeFlag(xComponentChangeFlag))
    },
    thirdPartyCall: (isThirdPartyCall: boolean) => {
      dispatch(Action.thirdPartyCall(isThirdPartyCall))
    },
    initAction: (action: string) => {
      dispatch(Action.InitAction(action))
    },
    InitMode: (mode: string) => {
      dispatch(Action.InitMode(mode))
    }
  }
}


@Component
export struct ControlLand {
  private TAG: string = '[ControlLand]:'
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  private scroller: Scroller = new Scroller()
  private settingsUtil = SettingsUtil.getInstance()
  private mConnect: any
  private modeArray: Array<string> = ['MULTI', 'PHOTO', 'VIDEO'] //, 'MORE'

  @State state: any = {}

//  scroller: Scroller = new Scroller()
//  //  private cameraService = CameraService.getInstance()
//  @Link aspectRatio: number
//  @Link previewImage: string
//  private modeConfig: ModeConfig = new ModeConfig()
//  private asyncManager: AsyncManager
//  @Link state: any
//  private connect: any
//  @State scrollValue: number = 0
//  @State photoFontWeight: FontWeight = FontWeight.Bold
//  @State videoFontWeight: FontWeight = FontWeight.Regular
//  @State multiFontWeight: FontWeight = FontWeight.Regular
//  @State notCheckFontSize: Resource = $r("sys.float.ohos_id_text_size_body2") // 未选中
//  @State checkFontSize: Resource = $r("sys.float.ohos_id_text_size_body1") // 选中
//  @State photoFontSize: Resource = $r("sys.float.ohos_id_text_size_body1")
//  @State videoFontSize: Resource = $r("sys.float.ohos_id_text_size_body2")
//  @State multiFontSize: Resource = $r("sys.float.ohos_id_text_size_body2")
//  @Link isThirdPartyCall: boolean
//  @Link action: string
//  @Link isSmallVideoTimerVisible: boolean
//  @Link isBigVideoTimerVisible: boolean
//  @Link cameraPosition: string
//  @Link XcomponentWidth: string
//  @Link XcomponentHeight: string
//  @State opacityValue: number = 1
//  @Link curPreviewImage: string
//  @Link xComponentChangeFlag: boolean
//  @State initIndex: number = 1
//  @State modeIndex: number = 0
//  private settingsUtil = SettingsUtil.getInstance()


  public aboutToAppear(): void {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(controlLandState, controlLandDispatcher)(this.state)
    display.getDefaultDisplay().then((dis) => {
      let width = (px2vp(dis.width) - (54 * 5)) / 2
      this.state.updateModeBarItemWidth(width)
      CLog.info(`${this.TAG} width: ${width}, modeBarItemWidth: ${this.state.modeBarItemWidth}`)
      let startWant = globalThis.cameraAbilityWant
      CLog.info(`${this.TAG}  Camera MainAbility onCreate uri: ${startWant.uri}`)
      if (startWant.action === wantConstant.Action.ACTION_IMAGE_CAPTURE) {
        CLog.info(`${this.TAG} ACTION_IMAGE_CAPTURE called`)
        this.state.thirdPartyCall(true)
      } else if (startWant.action === wantConstant.Action.ACTION_VIDEO_CAPTURE) {
        CLog.info(`${this.TAG} ACTION_VIDEO_CAPTURE called`)
        this.state.thirdPartyCall(true)
      }
    })
    this.appEventBus.on(Action.ACTION_SWIPE_MODE, this.swipeChangeMode.bind(this))
    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  public aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_SWIPE_MODE, this.swipeChangeMode.bind(this))
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  private closeMoreListView() {
    if (this.state.isShowMoreList) {
      this.state.updateShowMoreList(false)
    }
  }
  
  private changeToMode(modeIndex: number) {
    CLog.debug(`${this.TAG} changeToMode modeIndex: ${modeIndex} E`)
    if (modeIndex !== this.state.modeIndex) {
//      if ( modeIndex !== 3 ) {
//        this.closeMoreListView()
//      } else {
//        this.state.updateShowMoreList(true)
//      }
      this.scroller.scrollToIndex(modeIndex)
      CLog.debug(`${this.TAG} this.state.changeToMode(${this.modeArray[modeIndex]})`)
      this.state.changeToMode(this.modeArray[modeIndex])
      this.state.updateXComponentChangeFlag(!this.state.xComponentChangeFlag)
      this.state.updateControlFontStyle(this.modeArray[modeIndex])
    }
    CLog.debug(`${this.TAG} changeToMode X`)
  }

  private getModeFontSize(modeIndex: number): Resource {
    if (this.state.mode === this.modeArray[modeIndex]) {
      return $r("sys.float.ohos_id_text_size_body1")
    } else {
      return $r("sys.float.ohos_id_text_size_body2")
    }
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

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
        if (this.state.isThirdPartyCall && this.state.action === 'capture') {
          Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
            Text($r('app.string.photo_mode'))
//              .shadow({radius: 2, color: 'rgba(51, 0, 0, 0.2)', offsetX: 0, offsetY: 0})
              .fontSize(this.getModeFontSize(1))
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }.layoutWeight(1).height('100%')
        } else if (this.state.isThirdPartyCall && this.state.action === 'video') {
          Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
            Text($r('app.string.video_mode'))
//              .shadow({radius: 2, color: 'rgba(51, 0, 0, 0.2)', offsetX: 0, offsetY: 0})
              .fontSize(this.getModeFontSize(2))
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
                  .fontSize(this.getModeFontSize(0))
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
                  .fontSize(this.getModeFontSize(1))
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
                  .fontSize(this.getModeFontSize(2))
                  .fontColor(Color.White)
                  .enabled(this.state.uiEnable)
                  .onClick(async () => {this.changeToMode(2)})
                  .fontWeight(this.getModeFontWeight(2))
              }.width('100%').height('100%')
            }.width('100%').height(32)
//	          ListItem() {
//              Flex({direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End}) {
//                Text($r('app.string.more_list'))
//                  .fontSize(this.getModeFontSize(3))
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
            CLog.debug(`${this.TAG} Control scroll index first: ${firstIndex}, last: ${lastIndex}`)
            this.state.updateModeIndex(firstIndex)
            CLog.debug(`${this.TAG} onScrollIndex this.state.modeIndex: ${this.state.modeIndex}`)
          })
          .enabled(this.state.uiEnable)
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Up) {
              CLog.debug(`${this.TAG} modeIndex == ${this.state.modeIndex}`)
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