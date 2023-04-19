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

import display from '@ohos.display'

import {Log} from '../../utils/Log'
import { getStore } from '../../redux/store'
import {Action} from '../../redux/actions/Action'
import { EventBus } from '../../worker/eventbus/EventBus'
import { EventBusManager } from '../../worker/eventbus/EventBusManager'


let localState = (state) => {
  return {
    mode: state.ModeReducer.mode,
    videoState: state.RecordReducer.videoState,
    cameraPosition: state.CameraReducer.cameraPosition,
    zoomRatio: state.ZoomReducer.zoomRatio,
    isShowZoomText: state.ZoomReducer.isShowZoomText,
    showZoomLabelValue: state.ZoomReducer.showZoomLabelValue,
    minZoomRatio: state.ZoomReducer.minZoomRatio,
    maxZoomRatio: state.ZoomReducer.maxZoomRatio,
  }
}

let localDispatcher = (dispatch) => {
  return {
    updateZoomRatio: (zoomRatio: number) => {
      dispatch(Action.changeZoomRatio(zoomRatio))
    },
    updateShowZoomFlag: (flag: boolean) => {
      dispatch(Action.updateShowZoomTextFlag(flag))
    },
    updateShowZoomLabelValue: (flag: boolean) => {
      dispatch(Action.updateShowZoomLabelValue(flag))
    }
  }
}

let SHOW_FOLD_CANVAS: number = 0
let SHOW_NOT_TAKE_VIDEO_CANVAS: number = 1
let SHOW_TAKING_VIDEO_CANVAS: number = 2

class StateStruct {
  mode
  videoState
  cameraPosition
  zoomRatio
  isShowZoomText
  showZoomLabelValue
  minZoomRatio
  maxZoomRatio
  updateZoomRatio : Function
  updateShowZoomFlag : Function
  updateShowZoomLabelValue : Function
}

@Component
export struct ZoomView {
  private TAG: string = '[ZoomView]:'
  private mConnect: any
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  @State state: StateStruct = new StateStruct()
  @State offsetX: number = 0
  @State triggerRebuildNum: number = 0

  private notTakeVideoExtCanvasWidth: number = 360
  private takingVideoExtCanvasWidth: number = 196
  private foldCanvasWidth: number = 94
  private canvasHeight: number = 82

  private touchedOffsetX: number = this.takingVideoExtCanvasWidth / 2
  private startOffsetX: number = 0

  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private notTakeVideoExtCanvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private takingVideoExtCanvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private foldCanvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private notTakeVideoExtOffCanvasCtx: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.notTakeVideoExtCanvasWidth, this.canvasHeight, this.canvasSettings)
  private takingVideoExtOffCanvasCxt: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.takingVideoExtCanvasWidth, this.canvasHeight, this.canvasSettings)
  private foldOffCanvasCtx: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.foldCanvasWidth, this.canvasHeight, this.canvasSettings)

  private lpgTimer: number = 0
  private pgTimer: number = 0
  private lpgExp: boolean = false
  private pgExp: boolean = false
  private zoomTimer: number
  private baseZoomRatio: number = 1

  private mainDotRadius: number = 1.5
  private secDotRadius: number = 0.75
  private centerDotRadius: number = 2.5
  private dotSpacing: number = 4

  aboutToAppear(): void {
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_CHANGE_ZOOM_RATIO, this.updateZoomOffset.bind(this))
    this.appEventBus.on(Action.ACTION_UPDATE_VIDEO_STATE, this.updateZoomState.bind(this))
  }

  aboutToDisappear(): void {
    this.appEventBus.off(Action.ACTION_CHANGE_ZOOM_RATIO, this.updateZoomOffset.bind(this))
    this.appEventBus.off(Action.ACTION_UPDATE_VIDEO_STATE, this.updateZoomState.bind(this))
    this.mConnect?.destroy()
  }

  private getCurrentCanvasType(): number {
    if (this.state.isShowZoomText && (this.state.videoState === 'beforeTakeVideo'
      && (this.state.mode === 'PHOTO' || this.state.mode === 'VIDEO'))) {
      return SHOW_NOT_TAKE_VIDEO_CANVAS
    } else if (this.state.mode === 'VIDEO'
      && (this.state.isShowZoomText || this.state.videoState !== 'beforeTakeVideo')) {
      return SHOW_TAKING_VIDEO_CANVAS
    } else {
      return SHOW_FOLD_CANVAS
    }
  }

  private lpgOnAction(event: GestureEvent): void {
    this.clearTimer()
    this.state.updateShowZoomFlag(true)
    this.baseZoomRatio = this.state.zoomRatio
    this.offsetX = (this.state.zoomRatio - 1) * this.getZoomOffsetUnit()
    this.lpgExp = true
    this.pgExp = false
    this.triggerRebuildNum = this.triggerRebuildNum + 0.0001
  }

  private lpgOnActionEnd(): void {
    if (this.lpgTimer) {
      clearTimeout(this.lpgTimer)
    }
    this.lpgTimer = setTimeout(() => {
      if (this.lpgExp && !this.pgExp) {
        this.state.updateShowZoomFlag(false)
        this.triggerRebuildNum = this.triggerRebuildNum + 0.0001
      }
      this.lpgExp = false
    }, 3000)
  }

  private changeZoomRatioOnTakingVideoExt(): void {
    if (this.touchedOffsetX > this.takingVideoExtCanvasWidth / 2) {
      this.addZoomRatio()
    } else if (this.touchedOffsetX < this.takingVideoExtCanvasWidth / 2) {
      this.subtractZoomRatio()
    } else {
      this.triggerRebuildNum = this.triggerRebuildNum + 0.0001
      this.state.updateShowZoomFlag(false)
    }
  }

  private addZoomRatio(): void {
    let curZoomRatio = this.state.zoomRatio + 0.1
    if (curZoomRatio > this.state.maxZoomRatio) {
      curZoomRatio = this.state.maxZoomRatio
    }
    this.state.updateZoomRatio(curZoomRatio)
    this.state.updateShowZoomFlag(true)
    this.triggerRebuildNum = this.triggerRebuildNum + 0.0001
  }

  private subtractZoomRatio(): void {
    let curZoomRatio = this.state.zoomRatio - 0.1
    if (curZoomRatio < this.state.minZoomRatio) {
      curZoomRatio = this.state.minZoomRatio
    }
    this.state.updateZoomRatio(curZoomRatio)
    this.state.updateShowZoomFlag(true)
    this.triggerRebuildNum = this.triggerRebuildNum - 0.0001
  }

  private takingVideoExtTouched(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.touchedOffsetX = event.touches[0].x
      this.startOffsetX = event.touches[0].x
      this.changeZoomRatioOnTakingVideoExt()
    }
    if (event.type === TouchType.Up) {
      this.touchedOffsetX = this.takingVideoExtCanvasWidth / 2
      this.changeZoomRatioOnTakingVideoExt()
    }
  }

  private takingVideoExtLongPgAction(event: GestureEvent): void {
    this.touchedOffsetX = event.fingerList[0].localX
    this.changeZoomRatioOnTakingVideoExt()
  }

  private takingVideoExtLongPgActionEnd(): void {
    this.touchedOffsetX = this.takingVideoExtCanvasWidth / 2
    this.changeZoomRatioOnTakingVideoExt()
  }

  private takingVideoExtPgActionStart(event: GestureEvent): void {
    this.touchedOffsetX = this.startOffsetX + event.offsetX
    this.changeZoomRatioOnTakingVideoExt()
  }

  private takingVideoExtPgActionUpdate(event: GestureEvent): void {
    this.touchedOffsetX = this.startOffsetX + event.offsetX
    let takingVideoExtMaxOffsetX = this.takingVideoExtCanvasWidth - this.getZoomBtnRadius() - this.secDotRadius
    let takingVideoExtMinOffsetX = this.getZoomBtnRadius() + this.secDotRadius
    if (this.touchedOffsetX > takingVideoExtMaxOffsetX) {
      this.touchedOffsetX = takingVideoExtMaxOffsetX
    } else if (this.touchedOffsetX < takingVideoExtMinOffsetX) {
      this.touchedOffsetX = takingVideoExtMinOffsetX
    }
    this.changeZoomRatioOnTakingVideoExt()
  }

  private takingVideoExtPgActionEnd(event: GestureEvent): void {
    this.touchedOffsetX = this.takingVideoExtCanvasWidth / 2
    this.startOffsetX = 0
    this.changeZoomRatioOnTakingVideoExt()
  }

  private subtractTouched(event: TouchEvent) {
    if (event.type === TouchType.Down) {
      this.subtractZoomRatio()
    }
    if (event.type === TouchType.Up) {
      this.state.updateShowZoomFlag(false)
    }
  }

  private subtractLongOnAction(event: GestureEvent) {
    this.subtractZoomRatio()
  }

  private subtractLongOnActionEnd() {
    this.state.updateShowZoomFlag(false)
  }

  private addTouched(event: TouchEvent) {
    if (event.type === TouchType.Down) {
      this.addZoomRatio()
    }
    if (event.type === TouchType.Up) {
      this.state.updateShowZoomFlag(false)
    }
  }

  private addLongOnAction(event: GestureEvent) {
    this.addZoomRatio()
  }

  private addLongOnActionEnd() {
    this.state.updateShowZoomFlag(false)
  }

  private pgOnActionStart(event: GestureEvent): void {
    this.clearTimer()
    this.state.updateShowZoomFlag(true)
    this.state.updateShowZoomLabelValue(false)
    this.baseZoomRatio = this.state.zoomRatio
    this.pgExp = true
    this.lpgExp = false
  }

  private pgOnActionUpdate(event: GestureEvent): void {
    this.offsetX = (this.baseZoomRatio - this.state.minZoomRatio) * this.getZoomOffsetUnit() + event.offsetX
    this.updateZoomRatio()
  }

  private pgOnActionEnd(event: GestureEvent): void {
    this.state.updateShowZoomLabelValue(true)
    if (this.pgTimer) {
      clearTimeout(this.pgTimer)
    }
    this.pgTimer = setTimeout(() => {
      if (this.pgExp && !this.lpgExp) {
        this.state.updateShowZoomFlag(false)
      }
      this.pgExp = false
    }, 3000)
  }

  private mOnTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.clearTimer()
      this.state.updateShowZoomFlag(true)
      this.pgExp = true
      this.lpgExp = false

      let x = event.touches[0].x
      let zoomRatio = this.state.zoomRatio
      if (this.state.videoState === 'beforeTakeVideo' && this.getCurrentCanvasType() === SHOW_NOT_TAKE_VIDEO_CANVAS) {
        if (x < vp2px(36)) {
          zoomRatio = this.state.minZoomRatio
        }
        if (x > this.notTakeVideoExtCanvasWidth - vp2px(36)) {
          zoomRatio = this.state.maxZoomRatio
        }
        if (x > vp2px(36) && x < this.notTakeVideoExtCanvasWidth - vp2px(36)) {
          this.offsetX = x - this.getPadding()
          this.updateZoomRatio()
          return;
        }
      }
      this.offsetX = (zoomRatio - 1) * this.getZoomOffsetUnit()
      this.updateZoomRatio()
    } else if (event.type === TouchType.Up) {
      if (this.pgTimer) {
        clearTimeout(this.pgTimer)
      }
      this.pgTimer = setTimeout(() => {
        if (this.pgExp && !this.lpgExp) {
          this.state.updateShowZoomFlag(false)
        }
        this.pgExp = false
      }, 3000)
    }

  }

  private getZoomBtnCenterX(): number {
    if (this.getCurrentCanvasType() === SHOW_TAKING_VIDEO_CANVAS) {
      return this.touchedOffsetX
    }
    if (this.offsetX === 0 && this.state.zoomRatio !== 1) {
      this.offsetX = (this.state.zoomRatio - this.state.minZoomRatio) * this.getZoomOffsetUnit()
    }
    if (this.state.zoomRatio === 1 && this.offsetX !== 0) {
      this.offsetX = 0
    }
    let padding = this.getPadding()
    let result = this.offsetX + padding + this.mainDotRadius
    if (result > this.notTakeVideoExtCanvasWidth - padding - this.mainDotRadius) {
      result = this.notTakeVideoExtCanvasWidth - padding - this.mainDotRadius
    }
    if (result < padding + this.mainDotRadius) {
      result = padding + this.mainDotRadius
    }
    return result
  }

  private getZoomOffsetUnit(): number {
    let padding = this.getPadding()
    let fullWidth = this.notTakeVideoExtCanvasWidth - padding * 2 - this.mainDotRadius * 2
    return fullWidth / (this.state.maxZoomRatio - this.state.minZoomRatio)
  }

  private updateZoomOffset(data): void {
    let padding = this.getPadding()
    let offset = (data.zoomRatio - this.state.minZoomRatio) * this.getZoomOffsetUnit()
    this.offsetX = offset
  }

  private updateZoomState(data): void {
    if (data.videoState === 'beforeTakeVideo') {
      this.clearTimer()
      this.state.updateShowZoomFlag(false)
      this.pgExp = false
    }
  }

  private clearTimer(): void {
    if (this.pgTimer) {
      clearTimeout(this.pgTimer)
    }
    if (this.lpgTimer) {
      clearTimeout(this.lpgTimer)
    }
  }

  private updateZoomRatio(): void {
    let padding = this.getPadding()
    let fullWidth = this.notTakeVideoExtCanvasWidth - padding * 2 - this.mainDotRadius * 2
    let curZoomRatio = (this.offsetX / fullWidth) * (this.state.maxZoomRatio - this.state.minZoomRatio) + this.state.minZoomRatio
    if (curZoomRatio > this.state.maxZoomRatio) {
      curZoomRatio = this.state.maxZoomRatio
    }
    if (curZoomRatio < this.state.minZoomRatio) {
      curZoomRatio = this.state.minZoomRatio
    }
    this.state.updateZoomRatio(curZoomRatio)
  }

  private getPadding(): number {
    if (this.getCurrentCanvasType() === SHOW_NOT_TAKE_VIDEO_CANVAS) {
      return 32
    } else if (this.getCurrentCanvasType() === SHOW_TAKING_VIDEO_CANVAS) {
      return 15.5
    } else {
      return 32
    }
  }

  private getZoomText() {
    return `${Number(this.state.zoomRatio.toFixed(1))}x`
  }

  private getZoomBtnRadius(): number {
    if (!this.state.showZoomLabelValue) {
      return 17.25
    } else {
      return 15.25
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Stack({ alignContent: Alignment.Top }).width(this.offsetX + this.touchedOffsetX + this.state.zoomRatio).height(this.triggerRebuildNum).visibility(Visibility.None)
      if (this.getCurrentCanvasType() === SHOW_NOT_TAKE_VIDEO_CANVAS) {
        Canvas(this.notTakeVideoExtCanvasCtx)
          .width(this.notTakeVideoExtCanvasWidth)
          .height(this.canvasHeight)
          .onReady(() => {
            this.notTakeVideoExtCanvasCtx.clearRect(0, 0, this.notTakeVideoExtCanvasWidth, this.canvasHeight)
            this.notTakeVideoExtOffCanvasCtx.clearRect(0, 0, this.notTakeVideoExtCanvasWidth, this.canvasHeight)
            this.notTakeVideoExtOffCanvasCtx.strokeStyle = '#ffffff'
            this.notTakeVideoExtOffCanvasCtx.fillStyle = '#ffffff'
            this.notTakeVideoExtOffCanvasCtx.lineWidth = 1.5
            this.notTakeVideoExtOffCanvasCtx.beginPath()
            this.notTakeVideoExtOffCanvasCtx.arc(this.getZoomBtnCenterX(), this.canvasHeight / 2, this.getZoomBtnRadius(), 0, 6.28)
            this.notTakeVideoExtOffCanvasCtx.stroke()
            if (this.state.showZoomLabelValue) {
              this.notTakeVideoExtOffCanvasCtx.font = `bold ${vp2px(11)}px`
              this.notTakeVideoExtOffCanvasCtx.textAlign = 'center'
              this.notTakeVideoExtOffCanvasCtx.fillText(this.getZoomText(), this.getZoomBtnCenterX(), this.canvasHeight / 2 + 5)
            } else {
              this.notTakeVideoExtOffCanvasCtx.beginPath()
              this.notTakeVideoExtOffCanvasCtx.arc(this.getZoomBtnCenterX(), this.canvasHeight / 2, this.centerDotRadius, 0, 6.28)
              this.notTakeVideoExtOffCanvasCtx.fill()
            }

            let spotCount = (this.notTakeVideoExtCanvasWidth - this.getPadding() * 2 - this.mainDotRadius * 4 - this.dotSpacing) / (this.dotSpacing + this.secDotRadius * 2) + 2
            for (let i = 0; i < spotCount; i++) {
              let spotCenter = 0
              let spotRadius = 0
              if (i === 0) {
                spotRadius = this.mainDotRadius
                spotCenter = this.getPadding() + spotRadius
                this.notTakeVideoExtOffCanvasCtx.font = `bold ${vp2px(11)}px`
                this.notTakeVideoExtOffCanvasCtx.textAlign = 'center'
                this.notTakeVideoExtOffCanvasCtx.fillText(`${this.state.minZoomRatio}x`, spotCenter, this.canvasHeight / 2 - (!this.state.showZoomLabelValue ? 26: 24))
              } else if (i === spotCount - 1) {
                spotRadius = this.mainDotRadius
                spotCenter = this.notTakeVideoExtCanvasWidth - this.getPadding() - spotRadius
                this.notTakeVideoExtOffCanvasCtx.font = `bold ${vp2px(11)}px`
                this.notTakeVideoExtOffCanvasCtx.textAlign = 'center'
                this.notTakeVideoExtOffCanvasCtx.fillText(`${this.state.maxZoomRatio}x`, spotCenter, this.canvasHeight / 2 - (!this.state.showZoomLabelValue ? 26: 24))
              } else {
                spotRadius = this.secDotRadius
                spotCenter = this.getPadding() + this.mainDotRadius + (2 * i - 1) * this.secDotRadius + i * this.dotSpacing
                this.notTakeVideoExtOffCanvasCtx.globalAlpha = 0.2
              }
              if (spotCenter < this.getZoomBtnCenterX() - this.getZoomBtnRadius() || spotCenter > this.getZoomBtnCenterX() + this.getZoomBtnRadius()) {
                this.notTakeVideoExtOffCanvasCtx.beginPath()
                this.notTakeVideoExtOffCanvasCtx.arc(spotCenter, this.canvasHeight / 2, spotRadius, 0, 6.28)
                this.notTakeVideoExtOffCanvasCtx.fill()
              }
              this.notTakeVideoExtOffCanvasCtx.globalAlpha = 1
            }
            this.notTakeVideoExtCanvasCtx.transferFromImageBitmap(this.notTakeVideoExtOffCanvasCtx.transferToImageBitmap())
          })
          .gesture(
          GestureGroup(
            GestureMode.Parallel,
          PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Horizontal })
            .onActionStart(this.pgOnActionStart.bind(this))
            .onActionUpdate(this.pgOnActionUpdate.bind(this))
            .onActionEnd(this.pgOnActionEnd.bind(this))
          )
          )
          .onTouch(this.mOnTouch.bind(this))
      } else if (this.getCurrentCanvasType() === SHOW_TAKING_VIDEO_CANVAS) {
        Row() {
          Image($r('app.media.ic_camera_public_focus_ev_bright_subtract'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
            .onTouch(this.subtractTouched.bind(this))
            .gesture(
              GestureGroup(
                GestureMode.Parallel,
                LongPressGesture({ repeat: true })
                  .onAction(this.subtractLongOnAction.bind(this))
                  .onActionEnd(this.subtractLongOnActionEnd.bind(this)),
              )
            )
          Canvas(this.takingVideoExtCanvasCtx)
            .width(this.takingVideoExtCanvasWidth)
            .height(this.canvasHeight)
            .onReady(() => {
              this.takingVideoExtCanvasCtx.clearRect(0, 0, this.takingVideoExtCanvasWidth, this.canvasHeight)
              this.takingVideoExtOffCanvasCxt.clearRect(0, 0, this.takingVideoExtCanvasWidth, this.canvasHeight)
              this.takingVideoExtOffCanvasCxt.strokeStyle = '#ffffff'
              this.takingVideoExtOffCanvasCxt.fillStyle = '#ffffff'
              this.takingVideoExtOffCanvasCxt.lineWidth = 1.5
              this.takingVideoExtOffCanvasCxt.beginPath()
              this.takingVideoExtOffCanvasCxt.arc(this.getZoomBtnCenterX(), this.canvasHeight / 2, this.getZoomBtnRadius(), 0, 6.28)
              this.takingVideoExtOffCanvasCxt.stroke()
              if (this.state.isShowZoomText) {
                this.takingVideoExtOffCanvasCxt.beginPath()
                this.takingVideoExtOffCanvasCxt.arc(this.getZoomBtnCenterX(), this.canvasHeight / 2, this.centerDotRadius, 0, 6.28)
                this.takingVideoExtOffCanvasCxt.fill()
              } else {
                this.takingVideoExtOffCanvasCxt.font = `bold ${vp2px(11)}px`
                this.takingVideoExtOffCanvasCxt.textAlign = 'center'
                this.takingVideoExtOffCanvasCxt.fillText(this.getZoomText(), this.getZoomBtnCenterX(), this.canvasHeight / 2 + 5)
              }

              let spotCount = 30
              for (let i = 0; i < spotCount; i++) {
                let spotCenter = 0
                let spotRadius = 0
                spotRadius = this.secDotRadius
                spotCenter = this.getPadding() + (2 * i + 1) * this.secDotRadius + i * this.dotSpacing
                this.takingVideoExtOffCanvasCxt.globalAlpha = 0.2
                if (spotCenter < this.getZoomBtnCenterX() - this.getZoomBtnRadius() || spotCenter > this.getZoomBtnCenterX() + this.getZoomBtnRadius()) {
                  this.takingVideoExtOffCanvasCxt.beginPath()
                  this.takingVideoExtOffCanvasCxt.arc(spotCenter, this.canvasHeight / 2, spotRadius, 0, 6.28)
                  this.takingVideoExtOffCanvasCxt.fill()
                }
                this.takingVideoExtOffCanvasCxt.globalAlpha = 1
              }

              this.takingVideoExtCanvasCtx.transferFromImageBitmap(this.takingVideoExtOffCanvasCxt.transferToImageBitmap())
            })
            .gesture(
            GestureGroup(
              GestureMode.Parallel,
              LongPressGesture({ repeat: true })
                .onAction(this.takingVideoExtLongPgAction.bind(this))
                .onActionEnd(this.takingVideoExtLongPgActionEnd.bind(this)),
              PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Horizontal })
                .onActionStart(this.takingVideoExtPgActionStart.bind(this))
                .onActionUpdate(this.takingVideoExtPgActionUpdate.bind(this))
                .onActionEnd(this.takingVideoExtPgActionEnd.bind(this))
            ))
            .onTouch(this.takingVideoExtTouched.bind(this))
          Image($r('app.media.ic_camera_public_focus_ev_bright_add'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
            .onTouch(this.addTouched.bind(this))
            .gesture(
            GestureGroup(
              GestureMode.Parallel,
              LongPressGesture({ repeat: true })
                .onAction(this.addLongOnAction.bind(this))
                .onActionEnd(this.addLongOnActionEnd.bind(this)),
              )
            )
        }.width(this.notTakeVideoExtCanvasWidth).height('100%').padding({ left: 58, right: 58 })
      } else {
        Canvas(this.foldCanvasCtx)
          .width(this.foldCanvasWidth)
          .height(this.canvasHeight)
          .onReady(() => {
            this.foldCanvasCtx.clearRect(0, 0, this.foldCanvasWidth, this.canvasHeight)
            this.foldOffCanvasCtx.clearRect(0, 0, this.foldCanvasWidth, this.canvasHeight)
            this.foldOffCanvasCtx.strokeStyle = '#ffffff'
            this.foldOffCanvasCtx.fillStyle = '#ffffff'
            this.foldOffCanvasCtx.lineWidth = 1.5
            this.foldOffCanvasCtx.beginPath()
            this.foldOffCanvasCtx.arc(this.foldCanvasWidth / 2, this.canvasHeight / 2, this.getZoomBtnRadius(), 0, 6.28)
            this.foldOffCanvasCtx.stroke()
            this.foldOffCanvasCtx.font = `bold ${vp2px(10)}px`
            this.foldOffCanvasCtx.textAlign = 'center'
            this.foldOffCanvasCtx.fillText(this.getZoomText(), this.foldCanvasWidth / 2, this.canvasHeight / 2 + 3)

            let fullWidth = this.foldCanvasWidth / 2 - this.mainDotRadius
            let spotCount = (fullWidth - this.mainDotRadius * 2 - this.dotSpacing) / (this.dotSpacing + this.secDotRadius * 2) + 2
            let spotOffset = this.state.zoomRatio === this.state.maxZoomRatio ? this.foldCanvasWidth / 2 - fullWidth
                                                                                : this.foldCanvasWidth / 2
            for (let i = 0; i < spotCount; i++) {
              let spotCenter = 0
              let spotRadius = 0
              if (i === 0) {
                spotRadius = this.mainDotRadius
                spotCenter = spotOffset + spotRadius
              } else if (i === spotCount - 1) {
                spotRadius = this.mainDotRadius
                spotCenter = spotOffset + this.mainDotRadius * 2 + (i - 1) * this.dotSpacing + (2 * i - 1) * this.secDotRadius - this.secDotRadius + spotRadius
              } else {
                spotRadius = this.secDotRadius
                spotCenter = spotOffset + this.mainDotRadius * 2 + (i - 1) * this.dotSpacing + (2 * i - 1) * this.secDotRadius + spotRadius
                this.foldOffCanvasCtx.globalAlpha = 0.2
              }
              if (spotCenter < this.foldCanvasWidth / 2 - this.getZoomBtnRadius() || spotCenter > this.foldCanvasWidth / 2 + this.getZoomBtnRadius()) {
                this.foldOffCanvasCtx.beginPath()
                this.foldOffCanvasCtx.arc(spotCenter, this.canvasHeight / 2, spotRadius, 0, 6.28)
                this.foldOffCanvasCtx.fill()
              }
              this.foldOffCanvasCtx.globalAlpha = 1.0
            }

            this.foldCanvasCtx.transferFromImageBitmap(this.foldOffCanvasCtx.transferToImageBitmap())
          })
          .gesture(
          GestureGroup(
            GestureMode.Parallel,
          LongPressGesture({ repeat: true })
            .onAction(this.lpgOnAction.bind(this))
            .onActionEnd(this.lpgOnActionEnd.bind(this)),
          PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Horizontal })
            .onActionStart(this.pgOnActionStart.bind(this))
            .onActionUpdate(this.pgOnActionUpdate.bind(this))
            .onActionEnd(this.pgOnActionEnd.bind(this))
          )
          )
      }
    }.width('100%').height(this.canvasHeight).margin({ bottom: !this.state.showZoomLabelValue ? 58 : 0 })
  }
}