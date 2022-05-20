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

let controlState = (state) => {
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
  }
}

let controlDispatcher = (dispatch) => {
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
    updateXComponentChangeFlag: (xComponentChangeFlag: boolean) => {
      dispatch(Action.UpdateXComponentChangeFlag(xComponentChangeFlag))
    },
  }
}

@Component
export struct Control {
  private TAG: string = '[Control]'
  private scroller: Scroller = new Scroller()
  private settingsUtil = SettingsUtil.getInstance()
  private mConnect: any
  private modeArray: Array<string> = ['MULTI', 'PHOTO', 'VIDEO']

  @State state: any = {}

  public aboutToAppear(): void {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(controlState, controlDispatcher)(this.state)
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
    if (modeIndex !== this.state.modeIndex) {
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

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomStart }) {
        if (this.state.isThirdPartyCall || this.state.action === 'capture') {
          Row() {
            Text($r('app.string.photo_mode'))
              .width('100%').height('100%')
              .fontSize(14).fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
          }.width('100%').height('100%')
        } else if (this.state.action === 'video') {
          Row() {
            Text($r('app.string.video_mode'))
              .width('100%').height('100%')
              .fontSize(14).fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
          }.width('100%').height('100%')
        } else {
          List({ initialIndex: this.state.modeIndex, scroller: this.scroller }) {
            ListItem() {}.width(54).height('100%')
            ListItem() {}.width(54).height('100%')
            ListItem() {}.width(this.state.modeBarItemWidth).height('100%')
            ListItem() {
              Text($r('app.string.multi_mode'))
                .width('100%').height('100%')
//                .fontColor('#fff').fontSize(this.state.multiFontSize)
//                .fontWeight(this.state.multiFontWeight)
                .fontColor('#fff').fontSize(this.getModeFontSize(0))
                .fontWeight(this.getModeFontWeight(0))
                .textAlign(TextAlign.Center)
                .enabled(this.state.uiEnable)
                .onClick(() => { this.changeToMode(0) })
            }.width(54).height('100%')
            ListItem() {
              Text($r('app.string.photo_mode'))
                .width('100%').height('100%')
//                .fontColor('#fff').fontSize(this.state.photoFontSize)
//                .fontWeight(this.state.photoFontWeight)
                .fontColor('#fff').fontSize(this.getModeFontSize(1))
                .fontWeight(this.getModeFontWeight(1))
                .textAlign(TextAlign.Center)
                .enabled(this.state.uiEnable)
                .onClick(() => { this.changeToMode(1) })
            }.width(54).height('100%')
            ListItem() {
              Text($r('app.string.video_mode'))
                .width('100%').height('100%')
//                .fontColor('#fff').fontSize(this.state.videoFontSize)
//                .fontWeight(this.state.videoFontWeight)
                .fontColor('#fff').fontSize(this.getModeFontSize(2))
                .fontWeight(this.getModeFontWeight(2))
                .textAlign(TextAlign.Center)
                .enabled(this.state.uiEnable)
                .onClick(() => { this.changeToMode(2) })
            }.width(54).height('100%')
            ListItem() {}.width(this.state.modeBarItemWidth).height('100%')
            ListItem() {}.width(54).height('100%')
            ListItem() {}.width(54).height('100%')
          }
          .width('100%').height('100%')
          .listDirection(Axis.Horizontal)
          .edgeEffect(EdgeEffect.None)
          .chainAnimation(false)
          .enabled(this.state.uiEnable)
          .onScrollIndex((firstIndex: number, lastIndex: number) => {
            CLog.debug(`${this.TAG} Control scroll index first: ${firstIndex}, last: ${lastIndex}`)
            this.state.updateModeIndex(firstIndex)
            CLog.debug(`${this.TAG} onScrollIndex this.state.modeIndex: ${this.state.modeIndex}`)
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Up) {
              CLog.debug(`${this.TAG} modeIndex == ${this.state.modeIndex}`)
              this.changeToMode(this.state.modeIndex)
            }
          })
        }
        Column() {
          Column() {}.width(6).height(6).borderRadius(3).backgroundColor('#1095E8')
        }.width('100%').height(18)
      }.width('100%').height(58)
    }
  }
}