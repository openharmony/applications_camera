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

import { Log } from '../../utils/Log'
import getStore from '../../redux/store'
import { Action } from '../../redux/actions/Action'
import { EventBus } from '../../worker/eventbus/EventBus'
import EventBusManager from '../../worker/eventbus/EventBusManager'

let localState = (state) => {
  return {
    mode: state.ModeReducer.mode,
    videoState: state.RecordReducer.videoState,
    cameraPosition: state.CameraReducer.cameraPosition,
    isShowPressScrollDetailPhotoButton: state.ZoomReducer.isShowPressScrollDetailPhotoButton,
    zoomRatio: state.ZoomReducer.zoomRatio,
    minZoomRatio: state.ZoomReducer.minZoomRatio,
    maxZoomRatio: state.ZoomReducer.maxZoomRatio,
    scrollDetailsBox: state.ZoomReducer.scrollDetailsBox,
    isPhotoZoomDetails: state.ZoomReducer.isPhotoZoomDetails,
    photoDetailsOffsetX: state.ZoomReducer.photoDetailsOffsetX,
    photoDetailsOffsetXInit: state.ZoomReducer.photoDetailsOffsetXInit,
    isShowZoomText: state.ZoomReducer.isShowZoomText,
    showZoomLabelValue: state.ZoomReducer.showZoomLabelValue,
  }
}

let localDispatcher = (dispatch) => {
  return {
    updateZoomRatio: (zoomRatio: number) => {
      dispatch(Action.ChangeZoomRatio(zoomRatio))
    },
    updateShowZoomFlag: (flag: boolean) => {
      dispatch(Action.UpdateShowZoomTextFlag(flag))
    },
    updateShowZoomLabelValue: (flag: boolean) => {
      dispatch(Action.UpdateShowZoomLabelValue(flag))
    }
  }
}

@Component
export struct ZoomViewLand {
  private TAG: string = '[ZoomViewLand]:'
  private mConnect: any
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  @State state: any = {}
  @State offsetY: number = 0
  @State triggerRebuildNum: number = 0

  private canvasWidth: number = 82
  private extendCanvasHeight: number = 360
  private foldCanvasHeight: number = 105

  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private photoExtendCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private videoExtendCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private foldCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private photoExtendOffCanvasContext: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.canvasWidth, this.extendCanvasHeight, this.canvasSettings)
  private videoExtendOffCanvasContext: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.canvasWidth, this.extendCanvasHeight, this.canvasSettings)
  private foldOffCanvasContext: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.canvasWidth, this.foldCanvasHeight, this.canvasSettings)

  private lpgTimer: number = 0
  private pgTimer: number = 0
  private lpgExp: boolean = false
  private pgExp: boolean = false
  private zoomTimer: number = 0
  private baseZoomRatio: number = 1

  private mainDotRadius: number = 1.5
  private secDotRadius: number = 0.75
  private centerDotRadius: number = 1.5
  private dotSpacing: number = 4

  private aboutToAppear(): void {
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_CHANGE_ZOOM_RATIO, this.updateZoomOffset.bind(this))
    this.appEventBus.on(Action.ACTION_UPDATE_VIDEO_STATE, this.updateZoomState.bind(this))
  }

  private aboutToDisappear(): void {
    this.appEventBus.off(Action.ACTION_CHANGE_ZOOM_RATIO, this.updateZoomOffset.bind(this))
    this.appEventBus.off(Action.ACTION_UPDATE_VIDEO_STATE, this.updateZoomState.bind(this))
    this.mConnect.destroy()
  }

  private lpgOnAction(event: GestureEvent): void {
    this.clearTimer()
    this.state.updateShowZoomFlag(true)
    this.baseZoomRatio = this.state.zoomRatio
    this.lpgExp = true
    this.pgExp = false
    this.triggerRebuildNum = this.triggerRebuildNum + 0.0001
  }

  private lpgOnActionEnd(): void {
    this.lpgTimer = setTimeout(() => {
      if (this.lpgExp && !this.pgExp) {
        this.state.updateShowZoomFlag(false)
        this.triggerRebuildNum = this.triggerRebuildNum - 0.0001
      }
      this.lpgExp = false
    }, 3000)
  }

  private pgOnActionStart(event: GestureEvent): void {
    this.clearTimer()
    this.state.updateShowZoomFlag(true)
    this.baseZoomRatio = this.state.zoomRatio
    this.pgExp = true
    this.lpgExp = false
  }

  private pgOnActionUpdate(event: GestureEvent): void {
    this.offsetY = (this.baseZoomRatio - this.state.minZoomRatio) * this.getZoomOffsetUnit() - event.offsetY
    this.updateZoomRatio()
  }

  private pgOnActionEnd(event: GestureEvent): void {
    this.pgTimer = setTimeout(() => {
      if (this.pgExp && !this.lpgExp) {
        this.state.updateShowZoomFlag(false)
      }
      this.pgExp = false
    }, 3000)
  }

  private onTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.clearTimer()
      this.state.updateShowZoomFlag(true)
      this.pgExp = true
      this.lpgExp = false

      let y = event.touches[0].y
      let zoomRatio = this.state.zoomRatio
      if (this.state.videoState === 'beforeTakeVideo') {
        if (y < vp2px(24)) {
          zoomRatio = this.state.maxZoomRatio
        }
        if (y > this.extendCanvasHeight - vp2px(24)) {
          zoomRatio = this.state.minZoomRatio
        }
      } else {
        if (y < 24) {
          zoomRatio = zoomRatio + 0.1
        }
        if (y > 24 && y < vp2px(24) + 24) {
          zoomRatio = this.state.maxZoomRatio
        }
        if (y > this.extendCanvasHeight - 24) {
          zoomRatio = zoomRatio - 0.1
        }
        if (y > this.extendCanvasHeight - 24 - vp2px(24) && y < this.extendCanvasHeight - 24) {
          zoomRatio = this.state.minZoomRatio
        }
        if (zoomRatio < this.state.minZoomRatio) {
          zoomRatio = this.state.minZoomRatio
        }
        if (zoomRatio > this.state.maxZoomRatio) {
          zoomRatio = this.state.maxZoomRatio
        }
      }
      this.offsetY = (zoomRatio - 1) * this.getZoomOffsetUnit()
      this.updateZoomRatio()
    } else if (event.type === TouchType.Up) {
      this.pgTimer = setTimeout(() => {
        if (this.pgExp && !this.lpgExp) {
          this.state.updateShowZoomFlag(false)
        }
        this.pgExp = false
      }, 3000)
    }
  }

  private getZoomBtnCenterY(): number {
    let padding = this.getPadding()
    let result = this.extendCanvasHeight - padding - this.offsetY
    return result
  }

  private getZoomOffsetUnit(): number {
    let padding = this.getPadding()
    let fullHeight = this.extendCanvasHeight - padding * 2 - this.mainDotRadius * 2
    return fullHeight / (this.state.maxZoomRatio - this.state.minZoomRatio)
  }

  private updateZoomOffset(data): void {
    let padding = this.getPadding()
    let fullHeight = this.extendCanvasHeight - padding * 2 - this.mainDotRadius * 2
    let offset = (data.zoomRatio - this.state.minZoomRatio) * this.getZoomOffsetUnit()
    this.offsetY = offset
  }

  private updateZoomState(data): void {
    this.clearTimer()
    if (data.videoState === 'beforeTakeVideo') {
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
    let fullHeight = this.extendCanvasHeight - padding * 2 - this.mainDotRadius * 2
    let curZoomRatio = (this.offsetY / fullHeight) * (this.state.maxZoomRatio - this.state.minZoomRatio) + this.state.minZoomRatio
    if (curZoomRatio > this.state.maxZoomRatio) {
      curZoomRatio = this.state.maxZoomRatio
    }
    if (curZoomRatio < this.state.minZoomRatio) {
      curZoomRatio = this.state.minZoomRatio
    }
    this.state.updateZoomRatio(curZoomRatio)
  }

  private getPadding(): number {
    let padding = 32
    if (this.state.mode === 'PHOTO') {
      padding = 32
    }
    if (this.state.mode === 'VIDEO') {
      padding = 43
    }
    return padding
  }

  private getZoomText() {
    return `${Number(this.state.zoomRatio.toFixed(1))}x`
  }

  private getZoomBtnRadius(): number {
    if (this.state.isShowZoomText) {
      return 18
    } else {
      return 16
    }
  }

  build() {
    Stack({ alignContent: Alignment.Start}) {
      Stack({ alignContent: Alignment.Top }).width(this.triggerRebuildNum).height(this.offsetY + this.state.zoomRatio).visibility(Visibility.None)
      if (this.state.mode === 'PHOTO' && this.state.isShowZoomText) {
        Canvas(this.photoExtendCanvasContext)
          .width(this.canvasWidth)
          .height(this.extendCanvasHeight)
          .onReady(() => {
            this.photoExtendCanvasContext.clearRect(0, 0, this.canvasWidth, this.extendCanvasHeight)
            this.photoExtendOffCanvasContext.clearRect(0, 0, this.canvasWidth, this.extendCanvasHeight)
            this.photoExtendOffCanvasContext.strokeStyle = '#ffffff'
            this.photoExtendOffCanvasContext.fillStyle = '#ffffff'
            this.photoExtendOffCanvasContext.lineWidth = 2
            this.photoExtendOffCanvasContext.beginPath()
            this.photoExtendOffCanvasContext.arc(this.canvasWidth / 2, this.getZoomBtnCenterY(), this.getZoomBtnRadius(), 0, 6.28)
            this.photoExtendOffCanvasContext.stroke()
            this.photoExtendOffCanvasContext.beginPath()
            this.photoExtendOffCanvasContext.arc(this.canvasWidth / 2, this.getZoomBtnCenterY(), this.centerDotRadius, 0, 6.28)
            this.photoExtendOffCanvasContext.fill()

            let spotCount = (this.extendCanvasHeight - this.getPadding() * 2 - this.mainDotRadius * 4 - this.dotSpacing) / (this.dotSpacing + this.secDotRadius * 2) + 2
            for (let i = 0; i < spotCount; i++) {
              let spotCenter = 0
              let spotRadius = 0
              if (i === 0) {
                spotRadius = this.mainDotRadius
                spotCenter = this.extendCanvasHeight - this.getPadding() - spotRadius
                this.photoExtendOffCanvasContext.font = `bold ${vp2px(11)}px`
                this.photoExtendOffCanvasContext.textAlign = 'right'
                this.photoExtendOffCanvasContext.fillText(`${this.state.minZoomRatio}x`,this.canvasWidth / 2 - 24, spotCenter)
              } else if (i === spotCount - 1) {
                spotRadius = this.mainDotRadius
                spotCenter = this.getPadding() + spotRadius
                this.photoExtendOffCanvasContext.font = `bold ${vp2px(11)}px`
                this.photoExtendOffCanvasContext.textAlign = 'right'
                this.photoExtendOffCanvasContext.fillText(`${this.state.maxZoomRatio}x`,this.canvasWidth / 2 - 24, spotCenter)
              } else {
                spotRadius = this.secDotRadius
                spotCenter = this.extendCanvasHeight - this.getPadding() - this.mainDotRadius * 2 - (2 * i - 1) * this.secDotRadius - i * this.dotSpacing
              }
              if (spotCenter < this.getZoomBtnCenterY() - this.getZoomBtnRadius() || spotCenter > this.getZoomBtnCenterY() + this.getZoomBtnRadius()) {
                this.photoExtendOffCanvasContext.beginPath()
                this.photoExtendOffCanvasContext.arc(this.canvasWidth / 2, spotCenter, spotRadius, 0, 6.28)
                this.photoExtendOffCanvasContext.fill()
              }
            }
            this.photoExtendCanvasContext.transferFromImageBitmap(this.photoExtendOffCanvasContext.transferToImageBitmap())
          })
          .gesture(
            GestureGroup(
              GestureMode.Parallel,
              PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Vertical})
                .onActionStart(this.pgOnActionStart.bind(this))
                .onActionUpdate(this.pgOnActionUpdate.bind(this))
                .onActionEnd(this.pgOnActionEnd.bind(this))
            )
          )
          .onTouch(this.onTouch.bind(this))
      } else if (this.state.mode === 'VIDEO' && (this.state.isShowZoomText || this.state.videoState !== 'beforeTakeVideo')) {
        Canvas(this.videoExtendCanvasContext)
          .width(this.canvasWidth)
          .height(this.extendCanvasHeight)
          .onReady(() => {
            this.videoExtendCanvasContext.clearRect(0, 0, this.canvasWidth, this.extendCanvasHeight)
            this.videoExtendOffCanvasContext.clearRect(0, 0, this.canvasWidth, this.extendCanvasHeight)
            this.videoExtendOffCanvasContext.strokeStyle = '#ffffff'
            this.videoExtendOffCanvasContext.fillStyle = '#ffffff'
            this.videoExtendOffCanvasContext.lineWidth = 2
            this.videoExtendOffCanvasContext.beginPath()
            this.videoExtendOffCanvasContext.arc(this.canvasWidth / 2, this.getZoomBtnCenterY(), this.getZoomBtnRadius(), 0, 6.28)
            this.videoExtendOffCanvasContext.stroke()
            if (this.state.isShowZoomText) {
              this.videoExtendOffCanvasContext.beginPath()
              this.videoExtendOffCanvasContext.arc(this.canvasWidth / 2, this.getZoomBtnCenterY(), this.centerDotRadius, 0, 6.28)
              this.videoExtendOffCanvasContext.fill()
            } else {
              this.videoExtendOffCanvasContext.font = `bold ${vp2px(10)}px`
              this.videoExtendOffCanvasContext.textAlign = 'center'
              this.videoExtendOffCanvasContext.fillText(this.getZoomText(), this.canvasWidth / 2, this.getZoomBtnCenterY() + 5)
            }

            let spotCount = (this.extendCanvasHeight - this.getPadding() * 2 - this.mainDotRadius * 4 - this.dotSpacing) / (this.dotSpacing + this.secDotRadius * 2) + 2
            for (let i = 0; i < spotCount; i++) {
              let spotCenter = 0
              let spotRadius = 0
              if (i === 0) {
                spotRadius = this.mainDotRadius
                spotCenter = this.extendCanvasHeight - this.getPadding() - spotRadius
                this.videoExtendOffCanvasContext.font = `bold ${vp2px(11)}px`
                this.videoExtendOffCanvasContext.textAlign = 'right'
                this.videoExtendOffCanvasContext.fillText(`${this.state.minZoomRatio}x`,this.canvasWidth / 2 - 24, spotCenter)
              } else if (i === spotCount - 1) {
                spotRadius = this.mainDotRadius
                spotCenter = this.getPadding() + spotRadius
                this.videoExtendOffCanvasContext.font = `bold ${vp2px(11)}px`
                this.videoExtendOffCanvasContext.textAlign = 'right'
                this.videoExtendOffCanvasContext.fillText(`${this.state.maxZoomRatio}x`,this.canvasWidth / 2 - 24, spotCenter)
              } else {
                spotRadius = this.secDotRadius
                spotCenter = this.extendCanvasHeight - this.getPadding() - this.mainDotRadius * 2 - (2 * i - 1) * this.secDotRadius - i * this.dotSpacing
              }
              if (spotCenter < this.getZoomBtnCenterY() - this.getZoomBtnRadius() || spotCenter > this.getZoomBtnCenterY() + this.getZoomBtnRadius()) {
                this.videoExtendOffCanvasContext.beginPath()
                this.videoExtendOffCanvasContext.arc(this.canvasWidth / 2, spotCenter, spotRadius, 0, 6.28)
                this.videoExtendOffCanvasContext.fill()
              }
            }

            if (this.state.videoState !== 'beforeTakeVideo') {
              this.videoExtendOffCanvasContext.beginPath()
              this.videoExtendOffCanvasContext.rect(this.canvasWidth / 2 - 12, 10, 24, 4)
              this.videoExtendOffCanvasContext.fill()
              this.videoExtendOffCanvasContext.beginPath()
              this.videoExtendOffCanvasContext.rect(this.canvasWidth / 2 - 2, 0, 4, 24)
              this.videoExtendOffCanvasContext.fill()
              this.videoExtendOffCanvasContext.beginPath()
              this.videoExtendOffCanvasContext.rect(this.canvasWidth / 2 - 12, this.extendCanvasHeight - 14, 24, 4)
              this.videoExtendOffCanvasContext.fill()
            }

            this.videoExtendCanvasContext.transferFromImageBitmap(this.videoExtendOffCanvasContext.transferToImageBitmap())
          })
          .gesture(
            GestureGroup(
              GestureMode.Parallel,
              PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Vertical })
                .onActionStart(this.pgOnActionStart.bind(this))
                .onActionUpdate(this.pgOnActionUpdate.bind(this))
                .onActionEnd(this.pgOnActionEnd.bind(this))
            )
          )
          .onTouch(this.onTouch.bind(this))
      } else {
        Canvas(this.foldCanvasContext)
          .width(this.canvasWidth)
          .height(this.foldCanvasHeight)
          .onReady(() => {
            this.foldCanvasContext.clearRect(0, 0, this.canvasWidth, this.foldCanvasHeight)
            this.foldOffCanvasContext.clearRect(0, 0, this.canvasWidth, this.foldCanvasHeight)
            this.foldOffCanvasContext.strokeStyle = '#ffffff'
            this.foldOffCanvasContext.fillStyle = '#ffffff'
            this.foldOffCanvasContext.lineWidth = 2
            this.foldOffCanvasContext.beginPath()
            this.foldOffCanvasContext.arc(this.canvasWidth / 2, this.foldCanvasHeight / 2, this.getZoomBtnRadius(), 0, 6.28)
            this.foldOffCanvasContext.stroke()

            this.foldOffCanvasContext.font = `bold ${vp2px(10)}px`
            this.foldOffCanvasContext.textAlign = 'center'
            this.foldOffCanvasContext.fillText(this.getZoomText(), this.canvasWidth / 2, this.foldCanvasHeight / 2 + 3)

            let fullHeight = this.foldCanvasHeight / 2 - this.mainDotRadius
            let spotCount = (fullHeight - this.mainDotRadius * 2 - this.dotSpacing) / (this.dotSpacing + this.secDotRadius * 2) + 2
            let spotOffset = this.foldCanvasHeight / 2 + ((this.state.zoomRatio - this.state.minZoomRatio) / (this.state.maxZoomRatio - this.state.minZoomRatio) * fullHeight)
            for (let i = 0; i < spotCount; i++) {
              let spotCenter = 0
              let spotRadius = 0
              if (i === 0) {
                spotRadius = this.mainDotRadius
                spotCenter = spotOffset - spotRadius
              } else if (i === spotCount - 1) {
                spotRadius = this.mainDotRadius
                spotCenter = spotOffset - this.mainDotRadius * 2 - (i - 1) * this.dotSpacing - (2 * i - 1) * this.secDotRadius + this.secDotRadius - spotRadius
              } else {
                spotRadius = this.secDotRadius
                spotCenter = spotOffset - this.mainDotRadius * 2 - (i - 1) * this.dotSpacing - (2 * i - 1) * this.secDotRadius - spotRadius
              }
              if (spotCenter > this.foldCanvasHeight / 2 + this.getZoomBtnRadius() || spotCenter < this.foldCanvasHeight / 2 - this.getZoomBtnRadius()) {
                this.foldOffCanvasContext.beginPath()
                this.foldOffCanvasContext.arc(this.canvasWidth / 2, spotCenter, spotRadius, 0, 6.28)
                this.foldOffCanvasContext.fill()
              }
            }
            this.foldCanvasContext.transferFromImageBitmap(this.foldOffCanvasContext.transferToImageBitmap())
          })
          .gesture(
            GestureGroup(
              GestureMode.Parallel,
              LongPressGesture({ repeat: true })
                .onAction(this.lpgOnAction.bind(this))
                .onActionEnd(this.lpgOnActionEnd.bind(this)),
              PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Vertical })
                .onActionStart(this.pgOnActionStart.bind(this))
                .onActionUpdate(this.pgOnActionUpdate.bind(this))
                .onActionEnd(this.pgOnActionEnd.bind(this))
            )
          )
      }
    }.width(82).height('100%')
  }
}