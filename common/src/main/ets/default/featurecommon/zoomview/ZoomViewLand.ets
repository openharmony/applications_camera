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

import { Log } from '../../utils/Log'
import { getStore, OhCombinedState } from '../../redux/store'
import { Action } from '../../redux/actions/Action'
import { EventBus } from '../../worker/eventbus/EventBus'
import { EventBusManager } from '../../worker/eventbus/EventBusManager'

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
  isShowPressScrollDetailPhotoButton
  minZoomRatio
  maxZoomRatio
  scrollDetailsBox
  isPhotoZoomDetails
  photoDetailsOffsetX
  photoDetailsOffsetXInit
  updateZoomRatio: Function
  updateShowZoomFlag: Function
  updateShowZoomLabelValue: Function
}

@Component
export struct ZoomViewLand {
  private TAG: string = '[ZoomViewLand]:'
  private mConnect: any
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  @State state: StateStruct = new StateStruct()
  @State @Watch('onZoomRatioRefresh') zoomRatio: number = 0
  @State @Watch('onZoomRatioRefresh') showZoomLabelValue: boolean = true
  @State @Watch('onZoomRatioRefresh') isShowZoomText: boolean = false
  @State @Watch('onZoomRatioRefresh') curZoomRatio: number = 0
  @State offsetY: number = 0
  @State triggerRebuildNum: number = 0

  private canvasWidth: number = 82
  private notTakeVideoExtCanvasHeight: number = 360
  private takingVideoExtCanvasHeight: number = 196
  private foldCanvasHeight: number = 94

  private touchedOffsetY: number = this.takingVideoExtCanvasHeight / 2
  private startOffsetY: number = 0

  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private notTakeVideoExtCanvasCxt: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private takingVideoExtCanvasCxt: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private foldCanvasCxt: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private notTakeVideoExtOffCanvasCxt: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.canvasWidth, this.notTakeVideoExtCanvasHeight, this.canvasSettings)
  private takingVideoExtOffCanvasCxt: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.canvasWidth, this.notTakeVideoExtCanvasHeight, this.canvasSettings)
  private foldOffCanvasCxt: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.canvasWidth, this.foldCanvasHeight, this.canvasSettings)

  private lpgTimer: number = 0
  private pgTimer: number = 0
  private lpgExp: boolean = false
  private pgExp: boolean = false
  private zoomTimer: number = 0
  private baseZoomRatio: number = 1

  private mainDotRadius: number = 1.5
  private secDotRadius: number = 0.75
  private centerDotRadius: number = 2.5
  private dotSpacing: number = 4
  private refreshSwitchCanvas: number = -1

  aboutToAppear(): void {
    this.mConnect = getStore().connect((state: OhCombinedState) => {
      this.zoomRatio = state.ZoomReducer.zoomRatio
      this.showZoomLabelValue = state.ZoomReducer.showZoomLabelValue
      this.isShowZoomText = state.ZoomReducer.isShowZoomText
      return {
        mode: state.ModeReducer.mode,
        videoState: state.RecordReducer.videoState,
        cameraPosition: state.CameraReducer.cameraPosition,
        isShowPressScrollDetailPhotoButton: state.ZoomReducer.isShowPressScrollDetailPhotoButton,
        minZoomRatio: state.ZoomReducer.minZoomRatio,
        maxZoomRatio: state.ZoomReducer.maxZoomRatio,
        scrollDetailsBox: state.ZoomReducer.scrollDetailsBox,
        isPhotoZoomDetails: state.ZoomReducer.isPhotoZoomDetails,
        photoDetailsOffsetX: state.ZoomReducer.photoDetailsOffsetX,
        photoDetailsOffsetXInit: state.ZoomReducer.photoDetailsOffsetXInit,
      }
    }, localDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_CHANGE_ZOOM_RATIO, this.updateZoomOffset.bind(this))
    this.appEventBus.on(Action.ACTION_UPDATE_VIDEO_STATE, this.updateZoomState.bind(this))
  }

  aboutToDisappear(): void {
    this.appEventBus.off(Action.ACTION_CHANGE_ZOOM_RATIO, this.updateZoomOffset.bind(this))
    this.appEventBus.off(Action.ACTION_UPDATE_VIDEO_STATE, this.updateZoomState.bind(this))
    this.mConnect?.destroy()
  }

  private getCurrentCanvasType(): number {
    if (this.isShowZoomText && (this.state.videoState === 'beforeTakeVideo'
      && (this.state.mode === 'PHOTO' || this.state.mode === 'VIDEO'))) {
      return SHOW_NOT_TAKE_VIDEO_CANVAS
    } else if (this.state.mode === 'VIDEO'
      && (this.isShowZoomText || this.state.videoState !== 'beforeTakeVideo')) {
      return SHOW_TAKING_VIDEO_CANVAS
    } else {
      return SHOW_FOLD_CANVAS
    }
  }

  private changeZoomRatioOnTakingVideoExt(): void {
    if (this.touchedOffsetY < this.takingVideoExtCanvasHeight / 2) {
      this.addZoomRatio()
    } else if (this.touchedOffsetY > this.takingVideoExtCanvasHeight / 2) {
      this.subtractZoomRatio()
    } else {
      this.triggerRebuildNum = this.triggerRebuildNum + 0.0001
      this.state.updateShowZoomFlag(false)
    }
  }

  private addZoomRatio(): void {
    this.curZoomRatio = this.zoomRatio + 0.1
    if (this.curZoomRatio > this.state.maxZoomRatio) {
      this.curZoomRatio = this.state.maxZoomRatio
    }
    this.state.updateZoomRatio(this.curZoomRatio)
    this.state.updateShowZoomFlag(true)
    this.triggerRebuildNum = this.triggerRebuildNum + 0.0001
  }

  private subtractZoomRatio(): void {
    this.curZoomRatio = this.zoomRatio - 0.1
    if (this.curZoomRatio < this.state.minZoomRatio) {
      this.curZoomRatio = this.state.minZoomRatio
    }
    this.state.updateZoomRatio(this.curZoomRatio)
    this.state.updateShowZoomFlag(true)
    this.triggerRebuildNum = this.triggerRebuildNum - 0.0001
  }

  private takingVideoExtTouched(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.touchedOffsetY = event.touches[0].y
      this.startOffsetY = event.touches[0].y
      this.changeZoomRatioOnTakingVideoExt()
    }
    if (event.type === TouchType.Up) {
      this.touchedOffsetY = this.takingVideoExtCanvasHeight / 2
      this.changeZoomRatioOnTakingVideoExt()
    }
  }

  private takingVideoExtLongPgAction(event: GestureEvent): void {
    this.touchedOffsetY = event.fingerList[0].localY
    this.changeZoomRatioOnTakingVideoExt()
  }

  private takingVideoExtLongPgActionEnd(): void {
    this.touchedOffsetY = this.takingVideoExtCanvasHeight / 2
    this.changeZoomRatioOnTakingVideoExt()
  }

  private takingVideoExtPgActionStart(event: GestureEvent): void {
    this.touchedOffsetY = this.startOffsetY + event.offsetY
    this.changeZoomRatioOnTakingVideoExt()
  }

  private takingVideoExtPgActionUpdate(event: GestureEvent): void {
    this.touchedOffsetY = this.startOffsetY + event.offsetY
    let takingVideoExtMaxOffsetY = this.takingVideoExtCanvasHeight - this.getZoomBtnRadius() - this.secDotRadius
    let takingVideoExtMinOffsetY = this.getZoomBtnRadius() + this.secDotRadius
    if (this.touchedOffsetY > takingVideoExtMaxOffsetY) {
      this.touchedOffsetY = takingVideoExtMaxOffsetY
    } else if (this.touchedOffsetY < takingVideoExtMinOffsetY) {
      this.touchedOffsetY = takingVideoExtMinOffsetY
    }
    this.changeZoomRatioOnTakingVideoExt()
  }

  private takingVideoExtPgActionEnd(event: GestureEvent): void {
    this.touchedOffsetY = this.takingVideoExtCanvasHeight / 2
    this.startOffsetY = 0
    this.changeZoomRatioOnTakingVideoExt()
  }

  private subtractTouched(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.subtractZoomRatio()
    }
    if (event.type === TouchType.Up) {
      this.state.updateShowZoomFlag(false)
    }
  }

  private subtractLongOnAction(event: GestureEvent): void {
    this.subtractZoomRatio()
  }

  private subtractLongOnActionEnd(): void {
    this.state.updateShowZoomFlag(false)
  }

  private addTouched(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.addZoomRatio()
    }
    if (event.type === TouchType.Up) {
      this.state.updateShowZoomFlag(false)
    }
  }

  private addLongOnAction(event: GestureEvent): void {
    this.addZoomRatio()
  }

  private addLongOnActionEnd(): void {
    this.state.updateShowZoomFlag(false)
  }

  private lpgOnAction(event: GestureEvent): void {
    this.clearTimer()
    this.state.updateShowZoomFlag(true)
    this.baseZoomRatio = this.zoomRatio
    this.offsetY = (this.zoomRatio - 1) * this.getZoomOffsetUnit()
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
        this.triggerRebuildNum = this.triggerRebuildNum - 0.0001
      }
      this.lpgExp = false
    }, 3000)
  }

  private pgOnActionStart(event: GestureEvent): void {
    this.clearTimer()
    this.state.updateShowZoomFlag(true)
    this.state.updateShowZoomLabelValue(false)
    this.baseZoomRatio = this.zoomRatio
    this.pgExp = true
    this.lpgExp = false
  }

  private pgOnActionUpdate(event: GestureEvent): void {
    this.offsetY = (this.baseZoomRatio - this.state.minZoomRatio) * this.getZoomOffsetUnit() - event.offsetY
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

      let y = event.touches[0].y
      let zoomRatio = this.zoomRatio
      if (this.state.videoState === 'beforeTakeVideo' && this.getCurrentCanvasType() === SHOW_NOT_TAKE_VIDEO_CANVAS) {
        if (y < vp2px(36)) {
          zoomRatio = this.state.maxZoomRatio
        }
        if (y > this.notTakeVideoExtCanvasHeight - vp2px(36)) {
          zoomRatio = this.state.minZoomRatio
        }
        if (y > vp2px(36) && y < this.notTakeVideoExtCanvasHeight - vp2px(36)) {
          this.offsetY = this.notTakeVideoExtCanvasHeight - y - this.getPadding()
          this.updateZoomRatio()
          return;
        }
      }
      this.offsetY = (zoomRatio - 1) * this.getZoomOffsetUnit()
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

  private getZoomBtnCenterY(): number {
    if (this.getCurrentCanvasType() === SHOW_TAKING_VIDEO_CANVAS) {
      return this.touchedOffsetY
    }
    if (this.offsetY === 0 && this.zoomRatio !== 1) {
      this.offsetY = (this.zoomRatio - this.state.minZoomRatio) * this.getZoomOffsetUnit()
    }
    if (this.zoomRatio === 1 && this.offsetY !== 0) {
      this.offsetY = 0
    }
    let padding = this.getPadding()
    let result = this.notTakeVideoExtCanvasHeight - padding - this.offsetY
    return result
  }

  private getZoomOffsetUnit(): number {
    let padding = this.getPadding()
    let fullHeight = this.notTakeVideoExtCanvasHeight - padding * 2 - this.mainDotRadius * 2
    return fullHeight / (this.state.maxZoomRatio - this.state.minZoomRatio)
  }

  private updateZoomOffset(data): void {
    let padding = this.getPadding()
    let offset = (data.zoomRatio - this.state.minZoomRatio) * this.getZoomOffsetUnit()
    this.offsetY = offset
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
    let fullHeight = this.notTakeVideoExtCanvasHeight - padding * 2 - this.mainDotRadius * 2
    this.curZoomRatio = (this.offsetY / fullHeight) * (this.state.maxZoomRatio - this.state.minZoomRatio) + this.state.minZoomRatio
    if (this.curZoomRatio > this.state.maxZoomRatio) {
      this.curZoomRatio = this.state.maxZoomRatio
    }
    if (this.curZoomRatio < this.state.minZoomRatio) {
      this.curZoomRatio = this.state.minZoomRatio
    }
    this.state.updateZoomRatio(this.curZoomRatio)
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
    return `${Number(this.zoomRatio.toFixed(1))}x`
  }

  private getZoomBtnRadius(): number {
    if (!this.showZoomLabelValue) {
      return 17.25
    } else {
      return 15.25
    }
  }

  private onZoomRatioRefresh() {
    if (this.getCurrentCanvasType() === this.refreshSwitchCanvas) {
      this.refreshCanvas(this.refreshSwitchCanvas)
    }
  }

  private canvasInit(mType: number) {
    this.refreshSwitchCanvas = mType
    this.refreshCanvas(mType)
  }

  private refreshCanvas(mType: number) {
    switch (mType) {
      case SHOW_NOT_TAKE_VIDEO_CANVAS:
        this.notTakeVideoCanvas();
        break;
      case SHOW_TAKING_VIDEO_CANVAS:
        this.takingVideoCanvas();
        break;
      default:
        this.foldCanvas()
    }
  }

  private notTakeVideoCanvas() {
    this.notTakeVideoExtCanvasCxt.clearRect(0, 0, this.canvasWidth, this.notTakeVideoExtCanvasHeight)
    this.notTakeVideoExtOffCanvasCxt.clearRect(0, 0, this.canvasWidth, this.notTakeVideoExtCanvasHeight)
    this.notTakeVideoExtOffCanvasCxt.strokeStyle = '#ffffff'
    this.notTakeVideoExtOffCanvasCxt.fillStyle = '#ffffff'
    this.notTakeVideoExtOffCanvasCxt.lineWidth = 1.5
    this.notTakeVideoExtOffCanvasCxt.beginPath()
    this.notTakeVideoExtOffCanvasCxt.arc(this.canvasWidth / 2, this.getZoomBtnCenterY(), this.getZoomBtnRadius(), 0, 6.28)
    this.notTakeVideoExtOffCanvasCxt.stroke()
    if (this.showZoomLabelValue) {
      this.notTakeVideoExtOffCanvasCxt.font = `bold ${vp2px(11)}px`
      this.notTakeVideoExtOffCanvasCxt.textAlign = 'center'
      this.notTakeVideoExtOffCanvasCxt.fillText(this.getZoomText(), this.canvasWidth / 2, this.getZoomBtnCenterY() + 5)
    } else {
      this.notTakeVideoExtOffCanvasCxt.beginPath()
      this.notTakeVideoExtOffCanvasCxt.arc(this.canvasWidth / 2, this.getZoomBtnCenterY(), this.centerDotRadius, 0, 6.28)
      this.notTakeVideoExtOffCanvasCxt.fill()
    }

    let spotCount = (this.notTakeVideoExtCanvasHeight - this.getPadding() * 2 - this.mainDotRadius * 4 - this.dotSpacing) / (this.dotSpacing + this.secDotRadius * 2) + 2
    for (let i = 0; i < spotCount; i++) {
      let spotCenter = 0
      let spotRadius = 0
      if (i === 0) {
        spotRadius = this.mainDotRadius
        spotCenter = this.notTakeVideoExtCanvasHeight - this.getPadding() - spotRadius
        this.notTakeVideoExtOffCanvasCxt.font = `bold ${vp2px(11)}px`
        this.notTakeVideoExtOffCanvasCxt.textAlign = 'right'
        this.notTakeVideoExtOffCanvasCxt.fillText(`${this.state.minZoomRatio}x`,this.canvasWidth / 2 - (!this.showZoomLabelValue ? 26: 24), spotCenter)
      } else if (i === spotCount - 1) {
        spotRadius = this.mainDotRadius
        spotCenter = this.getPadding() + spotRadius
        this.notTakeVideoExtOffCanvasCxt.font = `bold ${vp2px(11)}px`
        this.notTakeVideoExtOffCanvasCxt.textAlign = 'right'
        this.notTakeVideoExtOffCanvasCxt.fillText(`${this.state.maxZoomRatio}x`,this.canvasWidth / 2 - (!this.showZoomLabelValue ? 26: 24), spotCenter)
      } else {
        spotRadius = this.secDotRadius
        spotCenter = this.notTakeVideoExtCanvasHeight - this.getPadding() - this.mainDotRadius * 2 - (2 * i - 1) * this.secDotRadius - i * this.dotSpacing
        this.notTakeVideoExtOffCanvasCxt.globalAlpha = 0.2
      }
      if (spotCenter < this.getZoomBtnCenterY() - this.getZoomBtnRadius() || spotCenter > this.getZoomBtnCenterY() + this.getZoomBtnRadius()) {
        this.notTakeVideoExtOffCanvasCxt.beginPath()
        this.notTakeVideoExtOffCanvasCxt.arc(this.canvasWidth / 2, spotCenter, spotRadius, 0, 6.28)
        this.notTakeVideoExtOffCanvasCxt.fill()
      }
      this.notTakeVideoExtOffCanvasCxt.globalAlpha = 1
    }
    this.notTakeVideoExtCanvasCxt.transferFromImageBitmap(this.notTakeVideoExtOffCanvasCxt.transferToImageBitmap())
  }

  private takingVideoCanvas() {
    this.takingVideoExtCanvasCxt.clearRect(0, 0, this.canvasWidth, this.takingVideoExtCanvasHeight)
    this.takingVideoExtOffCanvasCxt.clearRect(0, 0, this.canvasWidth, this.takingVideoExtCanvasHeight)
    this.takingVideoExtOffCanvasCxt.strokeStyle = '#ffffff'
    this.takingVideoExtOffCanvasCxt.fillStyle = '#ffffff'
    this.takingVideoExtOffCanvasCxt.lineWidth = 1.5
    this.takingVideoExtOffCanvasCxt.beginPath()
    this.takingVideoExtOffCanvasCxt.arc(this.canvasWidth / 2, this.getZoomBtnCenterY(), this.getZoomBtnRadius(), 0, 6.28)
    this.takingVideoExtOffCanvasCxt.stroke()
    if (this.isShowZoomText) {
      this.takingVideoExtOffCanvasCxt.beginPath()
      this.takingVideoExtOffCanvasCxt.arc(this.canvasWidth / 2, this.getZoomBtnCenterY(), this.centerDotRadius, 0, 6.28)
      this.takingVideoExtOffCanvasCxt.fill()
    } else {
      this.takingVideoExtOffCanvasCxt.font = `bold ${vp2px(11)}px`
      this.takingVideoExtOffCanvasCxt.textAlign = 'center'
      this.takingVideoExtOffCanvasCxt.fillText(this.getZoomText(), this.canvasWidth / 2, this.getZoomBtnCenterY() + 5)
    }

    let spotCount = 30
    for (let i = 0; i < spotCount; i++) {
      let spotCenter = 0
      let spotRadius = 0
      spotRadius = this.secDotRadius
      spotCenter = this.getPadding() + (2 * i + 1) * this.secDotRadius + i * this.dotSpacing
      this.takingVideoExtOffCanvasCxt.globalAlpha = 0.2
      if (spotCenter < this.getZoomBtnCenterY() - this.getZoomBtnRadius() || spotCenter > this.getZoomBtnCenterY() + this.getZoomBtnRadius()) {
        this.takingVideoExtOffCanvasCxt.beginPath()
        this.takingVideoExtOffCanvasCxt.arc(this.canvasWidth / 2, spotCenter, spotRadius, 0, 6.28)
        this.takingVideoExtOffCanvasCxt.fill()
      }
      this.takingVideoExtOffCanvasCxt.globalAlpha = 1
    }

    this.takingVideoExtCanvasCxt.transferFromImageBitmap(this.takingVideoExtOffCanvasCxt.transferToImageBitmap())
  }

  private foldCanvas() {
    this.foldCanvasCxt.clearRect(0, 0, this.canvasWidth, this.foldCanvasHeight)
    this.foldOffCanvasCxt.clearRect(0, 0, this.canvasWidth, this.foldCanvasHeight)
    this.foldOffCanvasCxt.strokeStyle = '#ffffff'
    this.foldOffCanvasCxt.fillStyle = '#ffffff'
    this.foldOffCanvasCxt.lineWidth = 1.5
    this.foldOffCanvasCxt.beginPath()
    this.foldOffCanvasCxt.arc(this.canvasWidth / 2, this.foldCanvasHeight / 2, this.getZoomBtnRadius(), 0, 6.28)
    this.foldOffCanvasCxt.stroke()

    this.foldOffCanvasCxt.font = `bold ${vp2px(10)}px`
    this.foldOffCanvasCxt.textAlign = 'center'
    this.foldOffCanvasCxt.fillText(this.getZoomText(), this.canvasWidth / 2, this.foldCanvasHeight / 2 + 3)

    let fullHeight = this.foldCanvasHeight / 2 - this.mainDotRadius
    let spotCount = (fullHeight - this.mainDotRadius * 2 - this.dotSpacing) / (this.dotSpacing + this.secDotRadius * 2) + 2
    let spotOffset = (this.zoomRatio === this.state.maxZoomRatio) ? this.foldCanvasHeight / 2 + fullHeight
                                                                  : this.foldCanvasHeight / 2
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
        this.foldOffCanvasCxt.globalAlpha = 0.2
      }
      if (spotCenter > this.foldCanvasHeight / 2 + this.getZoomBtnRadius() || spotCenter < this.foldCanvasHeight / 2 - this.getZoomBtnRadius()) {
        this.foldOffCanvasCxt.beginPath()
        this.foldOffCanvasCxt.arc(this.canvasWidth / 2, spotCenter, spotRadius, 0, 6.28)
        this.foldOffCanvasCxt.fill()
      }
      this.foldOffCanvasCxt.globalAlpha = 1
    }
    this.foldCanvasCxt.transferFromImageBitmap(this.foldOffCanvasCxt.transferToImageBitmap())
  }

  build() {
    Stack({ alignContent: Alignment.Start}) {
      Stack({ alignContent: Alignment.Top }).width(this.triggerRebuildNum).height(this.offsetY + this.touchedOffsetY + this.zoomRatio).visibility(Visibility.None)
      if (this.getCurrentCanvasType() === SHOW_NOT_TAKE_VIDEO_CANVAS) {
        Canvas(this.notTakeVideoExtCanvasCxt)
          .width(this.canvasWidth)
          .height(this.notTakeVideoExtCanvasHeight)
          .onReady(() => this.canvasInit(SHOW_NOT_TAKE_VIDEO_CANVAS))
          .gesture(
            GestureGroup(
              GestureMode.Parallel,
              PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Vertical})
                .onActionStart(this.pgOnActionStart.bind(this))
                .onActionUpdate(this.pgOnActionUpdate.bind(this))
                .onActionEnd(this.pgOnActionEnd.bind(this))
            )
          )
          .onTouch(this.mOnTouch.bind(this))
      } else if (this.getCurrentCanvasType() === SHOW_TAKING_VIDEO_CANVAS) {
        Column() {
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
                  .onActionEnd(this.addLongOnActionEnd.bind(this))
              )
            )
          Canvas(this.takingVideoExtCanvasCxt)
            .width(this.canvasWidth)
            .height(this.takingVideoExtCanvasHeight)
            .onReady(() => this.canvasInit(SHOW_TAKING_VIDEO_CANVAS))
            .gesture(
            GestureGroup(
              GestureMode.Parallel,
              LongPressGesture({ repeat: true })
                .onAction(this.takingVideoExtLongPgAction.bind(this))
                .onActionEnd(this.takingVideoExtLongPgActionEnd.bind(this)),
              PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Vertical })
                .onActionStart(this.takingVideoExtPgActionStart.bind(this))
                .onActionUpdate(this.takingVideoExtPgActionUpdate.bind(this))
                .onActionEnd(this.takingVideoExtPgActionEnd.bind(this))
              )
            )
            .onTouch(this.takingVideoExtTouched.bind(this))
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
                  .onActionEnd(this.subtractLongOnActionEnd.bind(this))
              )
            )
        }.width('100%').height(this.notTakeVideoExtCanvasHeight).padding({ top: 58, bottom: 58 })
      } else {
        Canvas(this.foldCanvasCxt)
          .width(this.canvasWidth)
          .height(this.foldCanvasHeight)
          .onReady(() => this.canvasInit(SHOW_FOLD_CANVAS))
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