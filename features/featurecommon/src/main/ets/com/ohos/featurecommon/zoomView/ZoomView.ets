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

import display from '@ohos.display';

import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import getStore from '../../../../../../../../../common/src/main/ets/default/redux/store'
import {Action} from '../../../../../../../../../common/src/main/ets/default/redux/actions/Action'

let localState = (state) => {
  return {
    mode: state.ModeReducer.mode,
    videoState: state.RecordReducer.videoState,
    cameraPosition: state.CameraReducer.cameraPosition,
    zoomRatio: state.UiReducer.zoomRatio,
    isShowZoomText: state.UiReducer.isShowZoomText,
  }
}

let localDispatcher = (dispatch) => {
  return {
    updateZoomRatio: (zoomRatio: number) => {
      dispatch(Action.ChangeZoomRatio(zoomRatio))
    },
    updateShowZoomFlag: (flag: boolean) => {
      dispatch(Action.UpdateShowZoomTextFlag(flag))
    }
  }
}

@Component
export struct ZoomView {
  private TAG: string = '[ZoomView]:'

  private mConnect: any
  @State state: any = {}

  private lpgTimer: number
  private pgTimer: number
  private zoomTimer: number

  private aboutToAppear(): void {
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    this.state.detailWidth = 51
    this.state.zoomWidth = 62
    this.state.zoomOpacity = 1
    this.state.isZoomDetails = true
    this.state.scrollDetailsBox = 32
    this.state.showZoomLabelValue = true
    this.state.zoomRatio = 1
    this.state.zoomPercentage = (this.state.zoomRatio - 1) / 5
    this.state.offsetX = 0
    this.state.zoomBtnRadius = 16
  }

  private aboutToDisappear(): void {
    this.mConnect.destroy()
  }

  private getDetailSpot() {
    let detailSpot = []
    let count = 0
    if (this.state.mode === 'PHOTO') {
      count = 52
    }
    if (this.state.mode === 'VIDEO') {
      count = 56
    }
    for (var i = 0; i < count; i++) {
      detailSpot.push(i)
    }
    return detailSpot
  }

  private getLinePadding() {
    if (this.state.mode === 'PHOTO') {
      return { left: 32, right: 32}
    } else {
      return {}
    }
  }

  private scrollBoxOffsetX() {
    return (this.state.detailWidth / 2 - this.state.zoomWidth - 7) + this.state.zoomPercentage * (this.state.zoomWidth - 32)
  }

  private zoomButtonOnTouch(event: TouchEvent) {
    CLog.info(`${this.TAG} onTouch`)
  }

  private lpgOnAction(event: GestureEvent) {
    clearTimeout(this.lpgTimer)
    clearTimeout(this.pgTimer)
    this.state.updateShowZoomFlag(true)
    this.state.zoomBtnRadius = 18
    CLog.info(`${this.TAG} lpg onAction: isZoomBarExtend: ${this.state.isShowZoomText}`)
  }

  private lpgOnActionEnd() {
    this.lpgTimer = setTimeout(() => {
      this.state.updateShowZoomFlag(false)
      this.state.zoomBtnRadius = 16
      CLog.info(`${this.TAG} lpg onActionEnd: isZoomBarExtend: ${this.state.isShowZoomText}`)
    }, 3000)
  }

  private pgOnActionStart(event: GestureEvent) {
    CLog.info(`${this.TAG} pg onActionStart: zoomValue: ${this.state.zoomRatio}`)
    clearTimeout(this.lpgTimer)
    clearTimeout(this.pgTimer)
    this.state.updateShowZoomFlag(true)
    this.state.showZoomLabelValue = false
    this.state.initOffsetX = this.getZoomButtonOffsetX()
    this.state.zoomBtnRadius = 18
    CLog.info(`${this.TAG} pg onActionStart: isZoomBarExtend: ${this.state.isShowZoomText}`)
    CLog.info(`${this.TAG} pg onActionStart: initOffsetX: ${this.state.initOffsetX}`)
  }

  private pgOnActionUpdate(event: GestureEvent) {
    clearTimeout(this.lpgTimer)
    CLog.info(`${this.TAG} pg onActionUpdate: initOffsetX: ${this.state.initOffsetX}`)
    let tempZoom = 5 * ((event.offsetX + this.state.initOffsetX + 148) / 296) + 1
    if (tempZoom < 1) {
      tempZoom = 1
    }
    if (tempZoom > 6) {
      tempZoom = 6
    }
    this.state.updateZoomRatio(tempZoom)
    CLog.info(`${this.TAG} pg onActionUpdate: zoomValue: ${this.state.zoomRatio}`)
  }

  private pgOnActionEnd() {
    CLog.info(`${this.TAG} pg onActionEnd`)
    this.state.showZoomLabelValue = true
    this.pgTimer = setTimeout(() => {
      this.state.updateShowZoomFlag(false)
      this.state.zoomBtnRadius = 16
      CLog.info(`${this.TAG} pg onActionEnd: isZoomBarExtend: ${this.state.isShowZoomText}`)
    }, 2000)
  }

  private gesturesOnCancel() {
    CLog.info(`${this.TAG} GestureGroup onCancel`)
  }

  private getZoomButtonOffsetX() {
    let offsetX = 59.2 * (this.state.zoomRatio - 1) - 148
    if (offsetX < -148) {
      offsetX = -148
    }
    if (offsetX > 148) {
      offsetX = 148
    }
    CLog.info(`${this.TAG} get offset x: ${offsetX}`)
    return offsetX
  }

  private zoomInBtnClick(event: ClickEvent) {
    CLog.info(`${this.TAG} track zoom ZoomIn click`)
    clearTimeout(this.zoomTimer)
    this.state.updateShowZoomFlag(true)
    this.state.updateZoomRatio(this.state.zoomRatio + 0.1)
    this.zoomTimer = setTimeout(() => {
      this.state.updateShowZoomFlag(false)
    }, 3000)
  }

  private zoomOutBtnClick(event: ClickEvent) {
    CLog.info(`${this.TAG} track zoom ZoomOut click`)
    clearTimeout(this.zoomTimer)
    this.state.updateShowZoomFlag(true)
    this.state.updateZoomRatio(this.state.zoomRatio - 0.1)
    this.zoomTimer = setTimeout(() => {
      this.state.updateShowZoomFlag(false)
    }, 3000)
  }

  build() {
    Stack({ alignContent: Alignment.Top}) {
      Stack({ alignContent: Alignment.Center }) {
        Stack({ alignContent: Alignment.Center }) {
          if (this.state.isShowZoomText && !this.state.showZoomLabelValue) {
            Stack() {}.width(5).height(5).borderRadius(2.5).backgroundColor('#ffffff')
          } else {
            Text(`${Number(this.state.zoomRatio.toFixed(1))}x`)
              .fontColor('#ffffff')
              .fontSize($r("sys.float.ohos_id_text_size_caption1"))
              .fontWeight(FontWeight.Bold)
          }
        }.width(this.state.zoomBtnRadius * 2).height(this.state.zoomBtnRadius * 2)
        .margin({ top: 4 })
        .borderRadius(this.state.zoomBtnRadius)
        .border({ width: 2, color: 0xffffff, style: BorderStyle.Solid })
      }.width(100).height(82).zIndex(2)
      .translate({ x: this.state.isShowZoomText ? this.getZoomButtonOffsetX() : 0 })
      .onTouch(this.zoomButtonOnTouch.bind(this))
      .gesture(
        GestureGroup(
          GestureMode.Parallel,
        LongPressGesture({ repeat: true})
          .onAction(this.lpgOnAction.bind(this))
          .onActionEnd(this.lpgOnActionEnd.bind(this)),
        PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Horizontal })
          .onActionStart(this.pgOnActionStart.bind(this))
          .onActionUpdate(this.pgOnActionUpdate.bind(this))
          .onActionEnd(this.pgOnActionEnd.bind(this))
        ).onCancel(this.gesturesOnCancel.bind(this))
      )

      if (this.state.isShowZoomText || this.state.mode === 'VIDEO') {
        Column() {
          Stack({ alignContent: Alignment.Bottom}) {
            if (this.state.mode === 'PHOTO') {
              Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
                Text('1x').fontSize(11).fontWeight(FontWeight.Bold).fontColor('#ffffff')
                  .width(20).height(11).textAlign(TextAlign.Center)
                Text('6x').fontSize(11).fontWeight(FontWeight.Bold).fontColor('#ffffff')
                  .width(20).height(11).textAlign(TextAlign.Center)
              }.width(316).height(11)
            }
          }.width(360).height(19).zIndex(1)

          Row() {
            if (this.state.mode === 'PHOTO') {
              Column() {}.width(3).height(3).borderRadius(1.5).margin({ right: 4 }).backgroundColor('#ffffff')
            } else {
              Text('-').width(24).height(24).margin({ right: 4 })
                .fontSize(24).fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Center).fontColor('#ffffff')
                .onTouch(this.zoomOutBtnClick.bind(this))
            }
            ForEach(this.getDetailSpot(), item => {
              Column() {
              }.width(1.5).height(1.5).borderRadius(0.75)
              .opacity(1).margin({ right: 4 }).backgroundColor('#ffffff')
            })
            if (this.state.mode === 'PHOTO') {
              Column() {}.width(3).height(3).borderRadius(1.5).backgroundColor('#ffffff')
            } else {
              Text('+').width(24).height(24)
                .fontSize(24).fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Center).fontColor('#ffffff')
                .onClick(this.zoomInBtnClick.bind(this))
            }
          }.width(360).height(32).zIndex(1).margin({ top: 8 })
          .padding(this.getLinePadding())
        }.width(360).height(82)
      }
    }.width('100%').height(82)
  }
}