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

import { Action } from '../../../../../../common/src/main/ets/default/redux/actions/Action'
import { BigText
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/bigText/BigText'
import { CameraId, getCameraId } from '../../../../../../common/src/main/ets/default/setting/CameraId'
import { CameraPlatformCapability
} from '../../../../../../common/src/main/ets/default/Camera/CameraPlatformCapability'
import { CLog } from '../../../../../../common/src/main/ets/default/Utils/CLog'
import getStore from '../../../../../../common/src/main/ets/default/redux/store'
import { ScreenLockManager } from '../../../../../../common/src/main/ets/default/Utils/ScreenLockManager'
import { SettingsUtil } from '../../../../../../common/src/main/ets/default/Utils/SettingsUtil'
import { ShowFlashBlack
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/animate/ShowFlashBlack'
import { ZoomText
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/zoomView/ZoomText'
import { EventBus } from '../../../../../../common/src/main/ets/default/Utils/EventBus'
import EventBusManager from '../../../../../../common/src/main/ets/default/Utils/EventBusManager'

let cameraState = (state) => {
  return {
    mode: state.ModeReducer.mode,
    curMode: state.ModeReducer.curMode,
    isShowPreview: state.PreviewReducer.isShowPreview,
    surfaceId: state.PreviewReducer.surfaceId,
    xComponentWidth: state.PreviewReducer.xComponentWidth,
    xComponentHeight: state.PreviewReducer.xComponentHeight,
    xComponentChangeFlag: state.PreviewReducer.xComponentChangeFlag,
    cameraPosition: state.CameraReducer.cameraPosition,
    curCameraPosition: state.CameraReducer.curCameraPosition,
    minZoomRatio: state.UiReducer.minZoomRatio,
    maxZoomRatio: state.UiReducer.maxZoomRatio,
    zoomRatio: state.UiReducer.zoomRatio,
    isSwitchBackground: state.UiReducer.isSwitchBackground,
    btnSwitch: state.UiReducer.btnSwitch,
    btnSwitchSec: state.UiReducer.btnSwitchSec,
    isShowFlashBlack: state.UiReducer.isShowFlashBlack,
    isShowBigText: state.UiReducer.isShowBigText,
    bigTextPositionY: state.UiReducer.bigTextPositionY,
    pinchGestureTimerId: state.UiReducer.pinchGestureTimerId,
    onTouchDownTimerId: state.UiReducer.onTouchDownTimerId,
    aspectRatio: state.UiReducer.aspectRatio,
    platformCapability: state.CameraInitReducer.platformCapability,
    videoState: state.RecordReducer.videoState,
  }
}

let cameraDispatcher = (dispatch) => {
  return {
    initCamera: (cameraId, mode) => {
      dispatch(Action.initCamera(cameraId, mode))
    },
    initZoomRatio: (min: number, max: number) => {
      dispatch(Action.InitZoomRatio(min, max))
    },
    changeZoomRatio: (zoomRatio: number) => {
      dispatch(Action.ChangeZoomRatio(zoomRatio))
    },
    updateZoomPercentage: (zoomPercentage: number) => {
      dispatch(Action.UpdateZoomPercentage(zoomPercentage))
    },
    changeMode: (mode: string) => {
      dispatch(Action.ChangeMode(mode))
      dispatch(Action.UpdateShowBigTextFlag(true))
    },
    prepareSurface: (surfaceId: number) => {
      dispatch(Action.PrepareSurface(surfaceId))
    },
    updateSurfaceId: (surfaceId: number) => {
      dispatch(Action.UpdateSurfaceId(surfaceId))
    },
    startPreview: () => {
      dispatch(Action.StartPreview())
    },
    switchCamera: (cameraId: CameraId) => {
      dispatch(Action.SwitchCamera(cameraId))
    },
    startVideoFlag: (isStartVideo: boolean) => {
      dispatch(Action.StartVideoFlag(isStartVideo))
    },
    cameraPositionChanged: (cameraPosition: string) => {
      dispatch(Action.CameraPositionChanged(cameraPosition))
    },
    changeXComponentSize: (xComponentWidth: string, xComponentHeight: string) => {
      dispatch(Action.ChangeXComponentSize(xComponentWidth, xComponentHeight))
    },
    updateXComponentChangeFlag: (xComponentChangeFlag: boolean) => {
      dispatch(Action.UpdateXComponentChangeFlag(xComponentChangeFlag))
    },
    updateShowPreviewFlag: (isShowPreview: boolean) => {
      dispatch(Action.UpdateShowPreviewFlag(isShowPreview))
    },
    updateIsShowZoomText: (isShowZoomText: boolean) => {
      dispatch(Action.UpdateShowZoomTextFlag(isShowZoomText))
    },
    updateIsPhotoZoomDetails: (isPhotoZoomDetails: boolean) => {
      dispatch(Action.UpdatePhotoZoomDetailsFlag(isPhotoZoomDetails))
    },
    updateBaseZoom: (zoomRatio: number) => {
      dispatch(Action.UpdateBaseZoom(zoomRatio))
    },
    updateIsPinchGesture: (isPinchGesture: boolean) => {
      dispatch(Action.UpdatePinchGestureFlag(isPinchGesture))
    },
    updatePinchGestureTimerId: (pinchGestureTimerId: number) => {
      dispatch(Action.UpdatePinchGestureTimerId(pinchGestureTimerId))
    },
    changeImageSize: (imageSize) => {
      dispatch(Action.changeImageSize(imageSize))
    },
    changeVideoSize: (videoSize) => {
      dispatch(Action.changeVideoSize(videoSize))
    },
    close: () => {
      dispatch(Action.close())
    },
    stopRecording: () => {
      dispatch(Action.stopRecording())
      dispatch(Action.UpdateVideoState('beforeTakeVideo'))
      dispatch(Action.UpdateBigVideoTimerVisible(false))
      dispatch(Action.UpdateSmallVideoTimerVisible(false))
    }
  }
}

@Component
export struct PreviewArea {
  @State state: any = {}
  private TAG: string = '[PreviewArea]:'
  private mConnect: any
  private isShowPreview: boolean = false
  private settingsUtil = SettingsUtil.getInstance()
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  mXComponentController: XComponentController = new XComponentController()

  private async onCameraInit(data) {
    CLog.info(`${this.TAG} EventBus onCameraInit isShowPreview = ${this.isShowPreview} platformCapability = ${this.state.platformCapability} E`)
    if (this.state.platformCapability) {
        this.settingsUtil.loadAllSetting().then(() => {
          this.settingsUtil.setCameraPlatformCapability(data.platformCapability)
          this.settingsUtil.setCameraId(getCameraId(this.state.curCameraPosition))
          this.settingsUtil.setMode(this.state.curMode)

          let imageSize = this.settingsUtil.getImageSize()
          this.state.changeImageSize(imageSize)

          let videoSize = this.settingsUtil.getVideoSize()
          this.state.changeVideoSize(videoSize)

          display.getDefaultDisplay().then((dis) => {
            let screenHeight = dis.height - 176
            let screenWidth = dis.width

            this.settingsUtil.setScreenHeight(screenHeight)
            this.settingsUtil.setScreenWidth(screenWidth)

            let xComponentSize = this.settingsUtil.getPreviewDisplaySize()
            CLog.info(this.TAG + " PreviewArea xComponentSize = " + JSON.stringify(xComponentSize))
            this.state.changeXComponentSize(xComponentSize.width.toString() + 'px', xComponentSize.height.toString() + 'px')
            this.state.updateShowPreviewFlag(true)
          })
        })
    }
    CLog.info(`${this.TAG} onCameraInit isShowPreview = ${this.state.isShowPreview}  X`)
  }

  public onScaleUpdate(scale) {
    CLog.info(`${this.TAG} onScaleUpdate called scale = ${scale}`)
    let tempZoom = 1.0
    if (scale > 1) {
      tempZoom = this.state.baseZoom + scale - 1
    } else {
      tempZoom = this.state.baseZoom * scale
    }
    if (Math.abs(tempZoom - this.state.zoomRatio) >= 0.1) {
      if (tempZoom >= this.state.minZoomRatio && tempZoom <= this.state.maxZoomRatio) {
        this.state.changeZoomRatio(tempZoom)
        this.state.updateZoomPercentage(this.ratioToPercentage(tempZoom))
      }
    }
  }

  public ratioToPercentage(ratio) {
    return (Math.log2(ratio) - Math.log2(this.state.minZoomRatio))
      / (Math.log2(this.state.maxZoomRatio) - Math.log2(this.state.minZoomRatio))
  }

  private async doCameraAction(surfaceId: number) {
    CLog.debug(`${this.TAG} doCameraAction E`)
    let size = SettingsUtil.getInstance().getPreviewSize()
    CLog.info(`${this.TAG} doCameraAction size = ${JSON.stringify(size)}`)
    let control: any = this.mXComponentController
    control.setXComponentSurfaceSize({ surfaceWidth: size.width, surfaceHeight: size.height })
    this.state.prepareSurface(surfaceId)
    if (this.state.curCameraPosition != this.state.cameraPosition) {
      if (this.state.cameraPosition === 'ORIGIN') {
        CLog.debug(`${this.TAG} doCameraAction call this.state.startPreview()`)
        this.state.startPreview()
      } else {
        this.state.switchCamera(getCameraId(this.state.cameraPosition), surfaceId)
      }
    } else if (this.state.curMode != this.state.mode) {
      this.state.changeMode(this.state.mode)
    } else if (this.state.isStartVideo) {
      this.state.startVideoFlag(false)
    } else {
      this.state.startPreview()
    }
    this.state.cameraPositionChanged(this.state.cameraPosition)
    CLog.debug(`${this.TAG} doCameraAction X`)
  }

  private async onModeChanged(data) {
    CLog.debug(`${this.TAG} onModeChanged E data.mode: ${data.mode}`)
    this.settingsUtil.setMode(data.mode)
    let xComponentSize = this.settingsUtil.getPreviewDisplaySize()
    this.state.changeXComponentSize(xComponentSize.width.toString() + 'px', xComponentSize.height.toString() + 'px')
    this.state.updateShowPreviewFlag(true)
    CLog.debug(`${this.TAG} onModeChanged X`)
  }

  private async onScreenChange(isScreenOn) {
    CLog.debug(`${this.TAG} onScreenChanged E isScreenOn: ${isScreenOn}`)
    if (isScreenOn) {
      this.state.updateXComponentChangeFlag(!this.state.xComponentChangeFlag)
      this.state.initCamera(getCameraId(this.state.curCameraPosition), this.state.mode)
      this.state.initZoomRatio(1, 6)
    } else {
      if (this.state.videoState === 'startTakeVideo') {
        this.state.stopRecording()
      }
      this.state.close()
    }
    CLog.debug(`${this.TAG} onScreenChanged X`)
  }

  private aboutToAppear(): void {
    CLog.info(`${this.TAG} PreviewArea aboutToAppear`)
    this.mConnect = getStore().connect(cameraState, cameraDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_INIT_DONE, this.onCameraInit.bind(this))
    this.appEventBus.on(Action.ACTION_ON_MODE_CHANGED, this.onModeChanged.bind(this))
    this.appEventBus.on(ScreenLockManager.SCREEN_CHANGE_EVENT, this.onScreenChange.bind(this))
    globalThis.releaseCamera = (() => {
      CLog.info(`${this.TAG} globalThis.releaseCamera called`)
      this.state.close()
    })

    globalThis.onForegroundInit = (() => {
      CLog.info(`${this.TAG} globalThis.onForegroundInit called`)
      this.state.updateXComponentChangeFlag(!this.state.xComponentChangeFlag)
    })
    this.state.initCamera(getCameraId(this.state.curCameraPosition), this.state.mode)
    this.state.initZoomRatio(1, 6) //TODO 需要动态取得实际变焦能力范围
    CLog.info(`${this.TAG} aboutToAppear end`)
  }

  private aboutToDisappear(): void {
    CLog.info(`${this.TAG} previewAreaLand aboutToDisappear called`)
    this.appEventBus.off(Action.ACTION_INIT_DONE, this.onCameraInit.bind(this))
    this.appEventBus.off(Action.ACTION_ON_MODE_CHANGED, this.onModeChanged.bind(this))
    this.appEventBus.off(ScreenLockManager.SCREEN_CHANGE_EVENT, this.onScreenChange.bind(this))
    this.mConnect.destroy()
    globalThis.releaseCamera()
  }

  private onBackPress(): void {
    CLog.info(`${this.TAG} previewAreaLand onBackPress called`)
  }

  private onPageHide() {
    this.state.startVideoFlag(false)
  }

  build() {
    Column() {
      if (this.state.isShowPreview) {
        Stack() {
          if (this.state.xComponentChangeFlag) {
            XComponent({
              id: '',
              type: 'surface',
              libraryname: '',
              controller: this.mXComponentController
            })
            .onLoad(() => {
              CLog.info(`${this.TAG} XComponent onLoad cameraPosition: `)
              let surfaceId = this.mXComponentController.getXComponentSurfaceId()
              this.state.updateSurfaceId(surfaceId)
              this.doCameraAction(surfaceId)
            })
            .width(this.state.xComponentWidth)
            .height(this.state.xComponentHeight)
          } else {
            XComponent({
              id: '',
              type: 'surface',
              libraryname: '',
              controller: this.mXComponentController
            })
              .onLoad(() => {
                CLog.info(`${this.TAG} XComponent onLoad cameraPosition: `)
                let surfaceId = this.mXComponentController.getXComponentSurfaceId()
                this.state.updateSurfaceId(surfaceId)
                this.doCameraAction(surfaceId)
              })
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
          }

          if (this.state.isSwitchBackground) {
            Column() {
            }
            .width(this.state.xComponentWidth)
            .height(this.state.xComponentHeight)
            .backgroundColor('#000')
            .opacity(this.state.switchBackgroundOpacity)
          }

          if (this.state.btnSwitch) {
            Image($r('app.media.whitePicture'))
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
              .syncLoad(false)
              .scale({ x: this.state.scaleX, y: 1.0})
              .rotate({ x: 0, y: 10, z: 0, angle: this.state.rotateAngle})
              // .opacity(this.state.btnOpacity_first)
              .onComplete(() => { /* this.switchAnimation() */ })
          }

          if (this.state.btnSwitchSec) {
            Image($r('app.media.whitePicture'))
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
              .syncLoad(false)
              .scale({ x: this.state.scaleX, y: 1.0})
              .rotate({ x: 0, y: 10, z: 0, angle: this.state.rotateAngleSec})
            // .opacity(this.state.btnOpacity_sec)
              .onComplete(() => { /* this.switchAnimationSec() */ })
          }

          if (this.state.isShowFlashBlack) {
            ShowFlashBlack({ state: $state })
          }

          if (this.state.isShowZoomText) {
            Stack({ alignContent: Alignment.Top }) {
              ZoomText({ state: $state })
            }
            .width('100%')
            .height('96%')
          }

          if (this.state.isShowBigText) {
            Stack({ alignContent: Alignment.BottomStart }) {
              BigText({ state: $state })
            }
            .width('100%')
            .height('100%')
            .padding({ bottom: '30vp' })
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .height('100%')
    .aspectRatio(this.state.aspectRatio)
    .margin({ top: 0 })
    .backgroundColor('#000')
    .gesture(
      PinchGesture({
        fingers: 2, // 触发捏合的最少手指数,最小为2,最大为5
        distance: 1 // 最小识别距离,单位vp
      })
      .onActionStart((event: GestureEvent) => {
        CLog.info(`${this.TAG} Pinch start`)
        if (this.state.mode !== "MULTI") {
          this.state.updateIsShowZoomText(true)
          this.state.updateIsPhotoZoomDetails(true)
          this.state.updateBaseZoom(this.state.zoomRatio)
          clearTimeout(this.state.pinchGestureTimerId)
          clearTimeout(this.state.onTouchDownTimerId)
        }
      })
      .onActionUpdate((event: GestureEvent) => {
        CLog.info(`${this.TAG} Pinch update E, event.scale = ${event.scale}`)
        if (this.state.mode !== "MULTI") {
          this.onScaleUpdate(event.scale)
          this.state.updateIsPinchGesture(true)
        }
        CLog.info(`${this.TAG} Pinch update X, fixed event.scale = ${Number(event.scale.toFixed(1))}`)
      })
      .onActionEnd((event: GestureEvent) => {
        CLog.info(`${this.TAG} Pinch end E`)
        if (this.state.mode !== "MULTI") {
          this.state.updateIsPinchGesture(false)
          clearTimeout(this.state.pinchGestureTimerId)
          clearTimeout(this.state.onTouchDownTimerId)
          let timerId = setTimeout(() => {
            this.state.updateIsShowZoomText(false)
            this.state.updateIsPhotoZoomDetails(false)
          }, 3000)
          this.state.updatePinchGestureTimerId(timerId)
        }
        CLog.info(`${this.TAG} Pinch end X, fixed event.scale = ${Number(event.scale.toFixed(1))}`)
      })
    )
  }
}