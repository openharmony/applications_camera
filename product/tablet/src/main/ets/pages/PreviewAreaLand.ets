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
import wantConstant from '@ohos.ability.wantConstant'
import window from '@ohos.window';

import { Action } from '../../../../../../common/src/main/ets/default/redux/actions/Action'
import AspectRatio from '../../../../../../common/src/main/ets/default/setting/AspectRatio'
import { AssistiveGridView
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/assistiveGridView/AssistiveGridView'
import { BigText
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/bigText/BigText'
import { BigVideoTimer } from './BigVideoTimer'
import { CameraId, getCameraId } from '../../../../../../common/src/main/ets/default/setting/CameraId'
import { CameraPlatformCapability
} from '../../../../../../common/src/main/ets/default/Camera/CameraPlatformCapability'
import { CLog } from '../../../../../../common/src/main/ets/default/Utils/CLog'
import DisplayUtil from '../../../../../../common/src/main/ets/default/Utils/DisplayUtil'
import getStore from '../../../../../../common/src/main/ets/default/redux/store'
import { ScreenLockManager } from '../../../../../../common/src/main/ets/default/Utils/ScreenLockManager'
import Resolution from '../../../../../../common/src/main/ets/default/setting/Resolution'
import { SettingsUtil } from '../../../../../../common/src/main/ets/default/Utils/SettingsUtil'
import { ShowFlashBlack
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/animate/ShowFlashBlack'
import { SmallVideoTimer } from './SmallVideoTimer'
import { ZoomText
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/zoomView/ZoomText'
import { TimeLapseView } from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/timeLapseView/TimeLapseView'
import { EventBus } from '../../../../../../common/src/main/ets/default/Utils/EventBus'
import EventBusManager from '../../../../../../common/src/main/ets/default/Utils/EventBusManager'
import { GeoLocation } from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/geolocation/GeoLocation'


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
    btnOpacityFirst: state.UiReducer.btnOpacityFirst,
    btnOpacitySec: state.UiReducer.btnOpacitySec,
    scaleX: state.UiReducer.scaleX,
    scaleXSec: state.UiReducer.scaleXSec,
    rotateAngle: state.UiReducer.rotateAngle,
    rotateAngleSec: state.UiReducer.rotateAngleSec,
    switchBackgroundOpacity: state.UiReducer.switchBackgroundOpacity,
    isShowtimeLapse: state.UiReducer.isShowtimeLapse,
    isBigVideoTimerVisible: state.UiReducer.isBigVideoTimerVisible,
    isSmallVideoTimerVisible: state.UiReducer.isSmallVideoTimerVisible,
    footBarHeight: state.ContextReducer.footBarHeight,
    isAssGridViewShow: state.UiReducer.isAssGridViewShow,
    modeIndex: state.UiReducer.modeIndex,
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall
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
    updateCameraPosition: (cameraPosition: string) => {
      dispatch(Action.updateCameraPosition(cameraPosition))
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
    },
    changeTimeLapse: (isShowtimeLapse: boolean) => {
      dispatch(Action.changeTimeLapse(isShowtimeLapse))
    },
    capture: () => {
      dispatch(Action.UpdateShowFlashBlackFlag(true))
      dispatch(Action.capture())
    },
    startRecording: () => {
      dispatch(Action.startRecording())
      dispatch(Action.UpdateVideoState('startTakeVideo'))
      dispatch(Action.UpdateBigVideoTimerVisible(true))
    },
    assistiveGridView: (isViewShow) => {
      dispatch(Action.assistiveGridView(isViewShow))
    },
    swipeChangeMode: (swipeModeIndex) => {
      dispatch(Action.swipeChangeMode(swipeModeIndex))
    },
    thirdPartyCall: (isThirdPartyCall: boolean, action: string) => {
      dispatch(Action.thirdPartyCall(isThirdPartyCall, action))
    },
    initMode: (mode: string) => {
      dispatch(Action.initMode(mode))
    },
    updateModeIndex: (index: number) => {
      dispatch(Action.UpdateModeIndex(index))
    },
    updateMode: (mode: string) => {
      dispatch(Action.updateMode(mode))
    },
    changeToMode: (mode: string) => {
      dispatch(Action.ChangeMode(mode))
    }
  }
}

globalThis.mXComponentController = new XComponentController()

@Component
export struct PreviewAreaLand {
  private TAG: string = '[PreviewAreaLand]:'
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()

  @State state: any = {}

  private mConnect: any
  private isShowPreview: boolean = false
  private settingsUtil = SettingsUtil.getInstance()
  private pinchGestureTimer: number
  private baseZoom: number
  private modeArray: Array<string> = ['MULTI', 'PHOTO', 'VIDEO']

  private async onCameraInit(data) {
    CLog.info(`${this.TAG} EventBus onCameraInit isShowPreview = ${this.isShowPreview} platformCapability = ${this.state.platformCapability} E`)
    if (this.state.platformCapability) {
//      if (!this.state.isShowPreview) {
      this.settingsUtil.loadAllSetting().then(() => {
        this.settingsUtil.setCameraPlatformCapability(data.platformCapability)
        this.settingsUtil.setCameraId(getCameraId(this.state.cameraPosition))
        this.settingsUtil.setMode(this.state.mode)

        let imageSize = this.settingsUtil.getImageSize()
        this.state.changeImageSize(imageSize)

        let videoSize = this.settingsUtil.getVideoSize()
        this.state.changeVideoSize(videoSize)

        let isAssGridViewShow = this.settingsUtil.getAssistiveGrid()
        this.state.assistiveGridView(isAssGridViewShow)

        GeoLocation.getInstance().on()

        display.getDefaultDisplay().then((dis) => {
          let screenHeight = dis.height - 176
          let screenWidth = dis.width

          this.settingsUtil.setScreenHeight(screenHeight)
          this.settingsUtil.setScreenWidth(screenWidth)

          let xComponentSize = this.settingsUtil.getPreviewDisplaySize()
          CLog.info(this.TAG + " PreviewArea xComponentSize = " + JSON.stringify(xComponentSize))
          this.state.changeXComponentSize(xComponentSize.width.toString() + 'px', xComponentSize.height.toString() + 'px')
//          this.isShowPreview = true
          this.state.updateShowPreviewFlag(true)
        })
      })
//            }
    }
    CLog.info(`${this.TAG} onCameraInit isShowPreview = ${this.state.isShowPreview}  X`)
  }

  private onScaleUpdate(scale) {
    CLog.info(`${this.TAG} onScaleUpdate called scale = ${scale}`)
    let tempZoom = 1.0
    if (scale > 1) {
      tempZoom = this.state.baseZoom + scale - 1
    } else {
      tempZoom = this.state.baseZoom * scale
    }
    if (Math.abs(tempZoom - this.state.zoomRatio) >= 0.1) {
      if (tempZoom >= this.state.minZoomRatio && tempZoom <= this.state.maxZoomRatio) { //TODO 需要动态取得实际变焦能力范围
//        this.cameraService.setZoomRatio(tempZoom)
        this.state.changeZoomRatio(tempZoom)
        this.state.updateZoomPercentage(this.ratioToPercentage(tempZoom))
      }
    }
  }

  private ratioToPercentage(ratio) {
    return (Math.log2(ratio) - Math.log2(this.state.minZoomRatio))
    / (Math.log2(this.state.maxZoomRatio) - Math.log2(this.state.minZoomRatio))
  }

  private async doCameraAction(surfaceId: number) {
    CLog.debug(`${this.TAG} doCameraAction E`)
    this.settingsUtil.setCameraId(getCameraId(this.state.cameraPosition))
    this.settingsUtil.setMode(this.state.mode)
    this.state.prepareSurface(surfaceId)
    if (this.state.curCameraPosition != this.state.cameraPosition) {
      if (this.state.cameraPosition === 'ORIGIN') {
        CLog.debug(`${this.TAG} doCameraAction call this.state.startPreview()`)
        this.state.startPreview()
      } else {
        this.state.switchCamera(getCameraId(this.state.cameraPosition), surfaceId)
      }
    } else if (this.state.curMode != this.state.mode) {
      this.state.changeToMode(this.state.mode)
    } else {
      this.state.startPreview()
    }
    this.state.updateCameraPosition(this.state.cameraPosition)
    this.state.updateMode(this.state.mode)
    CLog.debug(`${this.TAG} doCameraAction X`)
  }

  private async onModeChanged(data) {
    CLog.debug(`${this.TAG} onModeChanged E data.mode: ${data.mode}`)
    let xComponentSize = this.settingsUtil.getPreviewDisplaySize()
    this.state.changeXComponentSize(xComponentSize.width.toString() + 'px', xComponentSize.height.toString() + 'px')
    this.state.updateShowPreviewFlag(true)
    CLog.debug(`${this.TAG} onModeChanged X`)
  }

  private async onScreenChange(isScreenOn) {
    CLog.debug(`${this.TAG} onScreenChanged E isScreenOn: ${isScreenOn}`)
    // the build() can only be called when window is foreground
    if (isScreenOn && globalThis.cameraWindowStageEvent == window.WindowStageEventType.FOREGROUND) {
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
    CLog.info(`${this.TAG} aboutToAppear E`)
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
      let newWantAction = globalThis?.cameraNewWant && globalThis.cameraNewWant.action
      if (newWantAction) {
        this.state.thirdPartyCall(true, newWantAction)
        switch (newWantAction) {
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
      } else {
        this.state.thirdPartyCall(false, newWantAction)
      }
    })
    this.state.initCamera(getCameraId(this.state.curCameraPosition), this.state.mode)
    this.state.initZoomRatio(1, 6) //TODO 需要动态取得实际变焦能力范围
    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  private aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_INIT_DONE, this.onCameraInit.bind(this))
    this.appEventBus.off(Action.ACTION_ON_MODE_CHANGED, this.onModeChanged.bind(this))
    this.appEventBus.off(ScreenLockManager.SCREEN_CHANGE_EVENT, this.onScreenChange.bind(this))
    this.mConnect.destroy()
    GeoLocation.getInstance().off()
    globalThis.releaseCamera()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  private onPageHide(): void {
    CLog.info(`${this.TAG} onPageHide E`)
    this.state.startVideoFlag(false)
    CLog.info(`${this.TAG} onPageHide X`)
  }

  private switchAnimationSec() {
    CLog.info(`${this.TAG} switchAnimationSec called`)
    animateTo({ duration: 200,
      delay: 0,
      curve: Curve.Sharp,
    }, () => {
      this.state.btnOpacitySec = 1
    })
    animateTo({
      duration: 350,
      curve: Curve.FastOutSlowIn,
      delay: 0,
    }, () => {
      CLog.info(`${this.TAG} btnSwitchSec callback btnSwitchSec= ${this.state.btnSwitchSec}`)
      this.state.scaleXSec = 1
    })
    animateTo({
      duration: 350,
      curve: 'cubic-bezier(0.21, 0.27, 0.20, 1.00)',
      delay: 0,
      onFinish: () => {
        CLog.info(`${this.TAG} btnSwitchSec onFinish btnSwitchSec= ${this.state.btnSwitchSec}`)
        this.state.btnSwitchSec = false
        this.state.btnOpacitySec = 0
        this.state.scaleXSec = 0.8
        this.state.rotateAngleSec = 80
        this.switchBackgroundAnimation()
      }
    }, () => {
      CLog.info(`${this.TAG} btnSwitchSec callback btnSwitchSec= ${this.state.btnSwitchSec}`)
      this.state.rotateAngleSec = 0
//      this.btnSwitchSec = true
    })
  }

  private switchAnimation() {
    CLog.info(`${this.TAG} switchAnimation called`)
    animateTo({ duration: 300,
      delay: 0,
      curve: Curve.Sharp,
    }, () => {
      this.state.btnOpacityFirst = 0
    })
    animateTo({ duration: 350,
      delay: 0,
      curve: Curve.FastOutSlowIn,
      onFinish: () => {
        CLog.info(`${this.TAG} btnSwitch onFinish btnSwitch= ${this.state.btnSwitch}`)
        this.state.btnSwitch = false
        this.state.btnOpacityFirst = 1
        this.state.scaleX = 1
        this.state.rotateAngle = 0
      }
    }, () => {
      CLog.info(`${this.TAG} btnSwitch callback btnSwitch= ${this.state.btnSwitch}`)
      this.state.scaleX = 0.8
      this.state.rotateAngle = 80
    })
  }

  private switchBackgroundAnimation() {
    animateTo({ duration: 350,
      delay: 0,
      curve: Curve.Sharp,
      onFinish: () => {
        this.state.isSwitchBackground = false
        this.state.switchBackgroundOpacity = 1
      }
    }, () => {
      this.state.switchBackgroundOpacity = 0
    })
  }

  private pinchGestureStart(event: GestureEvent) {
    CLog.info(`${this.TAG} pinchGestureStart invoke E`)
    if (this.state.mode != 'MULTI') {
      clearTimeout(this.pinchGestureTimer)
      this.state.updateIsShowZoomText(true)
      this.baseZoom = this.state.zoomRatio
    }
    CLog.info(`${this.TAG} track debug pinchGestureStart invoke X`)
    if (this.state.mode !== "MULTI") {
      this.state.updateIsShowZoomText(true)
      this.state.updateIsPhotoZoomDetails(true)
      this.state.updateBaseZoom(this.state.zoomRatio)
      clearTimeout(this.state.pinchGestureTimerId)
      clearTimeout(this.state.onTouchDownTimerId)
    }


  }

  private pinchGestureUpdate(event: GestureEvent) {
    CLog.info(`${this.TAG} pinchGestureUpdate invoke E`)
    if (this.state.mode != 'MULTI') {
      let zoomRatio = event.scale + this.baseZoom - 1
      if (zoomRatio > 6) {
        zoomRatio = 6
      }
      if (zoomRatio < 1) {
        zoomRatio = 1
      }
      this.state.changeZoomRatio(zoomRatio)
    }
    CLog.info(`${this.TAG} pinchGestureUpdate invoke X`)
  }

  private pinchGestureEnd(event: GestureEvent) {
    CLog.info(`${this.TAG} pinchGestureEnd invoke E`)
    if (this.state.mode != 'MULTI') {
      this.pinchGestureTimer = setTimeout(() => {
        this.state.updateIsShowZoomText(false)
      }, 3000)
    }
    CLog.info(`${this.TAG} pinchGestureEnd invoke X`)
  }

  private onPreviewClicked() {
    CLog.info(`${this.TAG} onPreviewClicked invoke E`)
    CLog.info(`${this.TAG} isShowtimeLapse= ${this.state.isShowtimeLapse}, state.mode= ${this.state.mode}`)
    if (this.state.mode === 'PHOTO' && this.state.isShowtimeLapse) {
      this.state.changeTimeLapse(false)
      this.state.capture()
    } else if (this.state.mode === 'VIDEO' && this.state.isShowtimeLapse) {
      this.state.changeTimeLapse(false)
      this.state.startRecording()
    }
    CLog.info(`${this.TAG} onPreviewClicked invoke X`)
  }

  private swipeChangeMode(swipe: number) {
    CLog.info(`${this.TAG} swipeChangeMode E`)
    if (this.state.modeIndex + swipe >= 0 && this.state.modeIndex + swipe <= this.modeArray.length - 1) {
      this.state.swipeChangeMode(this.state.modeIndex + swipe)
    }
    CLog.info(`${this.TAG} swipeChangeMode X`)
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
              controller: globalThis.mXComponentController
            })
              .onLoad(() => {
                CLog.info(`${this.TAG} XComponent onLoad cameraPosition: `)
                let surfaceId = globalThis.mXComponentController.getXComponentSurfaceId()
                this.state.updateSurfaceId(surfaceId)
                this.doCameraAction(surfaceId)
              })
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
              .animation({
                duration: 1000,
                curve: Curve.Sharp,
                delay: 10,
                iterations: 1,
                playMode: PlayMode.Normal
              })
          } else {
            XComponent({
              id: '',
              type: 'surface',
              libraryname: '',
              controller: globalThis.mXComponentController
            })
              .onLoad(() => {
                CLog.info(`${this.TAG} XComponent onLoad cameraPosition: `)
                let surfaceId = globalThis.mXComponentController.getXComponentSurfaceId()
                this.state.updateSurfaceId(surfaceId)
                this.doCameraAction(surfaceId)
              })
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
              .animation({
                duration: 1000,
                curve: Curve.Sharp,
                delay: 10,
                iterations: 1,
                playMode: PlayMode.Normal
              })
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
              .scale({ x: this.state.scaleX, y: 1.0 })
              .rotate({ x: 0, y: 10, z: 0, angle: this.state.rotateAngle })
                // .opacity(this.state.btnOpacity_first)
              .onComplete(() => { /* this.switchAnimation() */ })
          }

          if (this.state.btnSwitchSec) {
            Image($r('app.media.whitePicture'))
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
              .syncLoad(false)
              .scale({ x: this.state.scaleX, y: 1.0 })
              .rotate({ x: 0, y: 10, z: 0, angle: this.state.rotateAngleSec })
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

          if (this.state.xComponentChangeFlag ) {
            if(this.state.isAssGridViewShow === '1' && this.state.mode !=='MORE')
            {
              AssistiveGridView()
            }
          } else {
            if(this.state.isAssGridViewShow === '1' && this.state.mode !=='MORE')
            {
              AssistiveGridView()
            }
          }

          if (this.state.isSmallVideoTimerVisible) {
            Column() {
              SmallVideoTimer()
            }
            .width('100%')
            .height('100%')
            .padding({ top: 64 })
          }
          if (this.state.isBigVideoTimerVisible) {
            Column() {
              BigVideoTimer()
            }
            .width('100%')
            .height('100%')
            .padding({ top: 40 })
          }
          if (this.state.isShowtimeLapse) {
            Column() {
              TimeLapseView()
            }.width('100%').height(150).position({x: 0, y: 200})
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
      GestureGroup(
        GestureMode.Exclusive,
        TapGesture({ fingers: 1, count: 1 })
          .onAction(this.onPreviewClicked.bind(this)),
        PinchGesture({ fingers: 2, distance: 1})
          .onActionStart(this.pinchGestureStart.bind(this))
          .onActionUpdate(this.pinchGestureUpdate.bind(this))
          .onActionEnd(this.pinchGestureEnd.bind(this)),
        PanGesture({ fingers: 1, direction: PanDirection.Up, distance: 10 })
          .onActionEnd(() => {
            if (!this.state.isThirdPartyCall) {
              this.swipeChangeMode(1)
            }
          }),
        PanGesture({ fingers: 1, direction: PanDirection.Down, distance: 10 })
          .onActionEnd(() => {
            if (!this.state.isThirdPartyCall) {
              this.swipeChangeMode(-1)
            }
          })
      )
    )
  }
}