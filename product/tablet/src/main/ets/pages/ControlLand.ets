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

import display from '@ohos.display'
import { CLog } from '../../../../../../common/src/main/ets/default/Utils/CLog'
import getStore from '../../../../../../common/src/main/ets/default/redux/store'
import { Action } from '../../../../../../common/src/main/ets/default/redux/actions/Action'
import { SettingsUtil } from '../../../../../../common/src/main/ets/default/Utils/SettingsUtil'

let controlLandState = (state) => {
  return {
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall,
    action: state.ContextReducer.action,
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
    }
  }
}


@Component
export struct ControlLand {
  private TAG: string = '[ControlLand]:'
  private scroller: Scroller = new Scroller()
  private settingsUtil = SettingsUtil.getInstance()
  private mConnect: any
  private modeArray: Array<string> = ['MULTI', 'PHOTO', 'VIDEO']

  @State state: any = {}

  public aboutToAppear(): void {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(controlLandState, controlLandDispatcher)(this.state)
    display.getDefaultDisplay().then((dis) => {
      let width = (px2vp(dis.width) - (54 * 5)) / 2
      this.state.updateModeBarItemWidth(width)
      CLog.info(`${this.TAG} width: ${width}, modeBarItemWidth: ${this.state.modeBarItemWidth}`)
    })
    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  public aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  private changeToMode(modeIndex: number) {
    CLog.debug(`${this.TAG} changeToMode modeIndex: ${modeIndex} E`)
    this.scroller.scrollToIndex(modeIndex)
    CLog.debug(`${this.TAG} this.state.changeToMode(${this.modeArray[modeIndex]})`)
    this.state.changeToMode(this.modeArray[modeIndex])
    this.state.updateControlFontStyle(this.modeArray[modeIndex])
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

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
        if (this.state.isThirdPartyCall || this.state.action === 'capture') {
          Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
            Text($r('app.string.photo_mode'))
//              .shadow({radius: 2, color: 'rgba(51, 0, 0, 0.2)', offsetX: 0, offsetY: 0})
              .fontSize(this.getModeFontSize(0))
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }.layoutWeight(1).height('100%')
        } else if (this.state.action === 'video') {
          Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
            Text($r('app.string.video_mode'))
//              .shadow({radius: 2, color: 'rgba(51, 0, 0, 0.2)', offsetX: 0, offsetY: 0})
              .fontSize(this.getModeFontSize(0))
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
                  .fontWeight(this.getModeFontWeight(1))
              }.width('100%').height('100%')
            }.width('100%').height(32)
            ListItem() {
              Flex({direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End}) {
                Text($r('app.string.photo_mode'))
//                  .shadow({radius: 2, color: 'rgba(51, 0, 0, 0.2)', offsetX: 0, offsetY: 0})
                  .fontSize(this.getModeFontSize(0))
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
                  .fontSize(this.getModeFontSize(0))
                  .fontColor(Color.White)
                  .enabled(this.state.uiEnable)
                  .onClick(async () => {this.changeToMode(2)})
                  .fontWeight(this.getModeFontWeight(1))
              }.width('100%').height('100%')
            }.width('100%').height(32)
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