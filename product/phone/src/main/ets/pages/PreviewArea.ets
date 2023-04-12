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

import router from '@system.router';
import display from '@ohos.display';
import wantConstant from '@ohos.ability.wantConstant'
import window from '@ohos.window';
import deviceInfo from '@ohos.deviceInfo'
import { Action, UiStateMode }  from '@ohos/common/src/main/ets/default/redux/actions/Action'
import { AssistiveGridView }  from '@ohos/common/src/main/ets/default/featurecommon/assistivegridview/AssistiveGridView'
import { BigText } from '@ohos/common/src/main/ets/default/featurecommon/bigtext/BigText'
import { CameraNeedStatus, CameraStatus } from '@ohos/common/src/main/ets/default/utils/Constants'
import { EventBus }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus'
import { EventBusManager }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager'
import { getStore, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store'
import { Log } from '@ohos/common/src/main/ets/default/utils/Log'
import { GeoLocation } from '@ohos/common/src/main/ets/default/featurecommon/geolocation/GeoLocation'
import { SettingManager } from '@ohos/common/src/main/ets/default/setting/SettingManager'
import { ShowFlashBlack } from '@ohos/common/src/main/ets/default/featurecommon/animate/ShowFlashBlack'
import { TimeLapseView } from '@ohos/common/src/main/ets/default/featurecommon/timelapseview/TimeLapseView'
import { ZoomText } from '@ohos/common/src/main/ets/default/featurecommon/zoomview/ZoomText'
import { BigVideoTimer } from './BigVideoTimer'
import { SmallVideoTimer } from './SmallVideoTimer'
import promptAction from '@ohos.promptAction';

let cameraState = (state: OhCombinedState) => {
  let isShowBlur = !state.ContextReducer.uiEnable && state.ContextReducer.uiStateMode == UiStateMode.NONE
  return {
    mode: state.ModeReducer.mode,
    curMode: state.ModeReducer.curMode,
    isShowPreview: state.PreviewReducer.isShowPreview,
    surfaceId: state.PreviewReducer.surfaceId,
    xComponentWidth: state.PreviewReducer.xComponentWidth,
    xComponentHeight: state.PreviewReducer.xComponentHeight,
    cameraPosition: state.CameraReducer.cameraPosition,
    curCameraPosition: state.CameraReducer.curCameraPosition,
    minZoomRatio: state.ZoomReducer.minZoomRatio,
    maxZoomRatio: state.ZoomReducer.maxZoomRatio,
    zoomRatio: state.ZoomReducer.zoomRatio,
    platformCapability: state.CameraInitReducer.platformCapability,
    videoState: state.RecordReducer.videoState,
    isShowZoomText: state.ZoomReducer.isShowZoomText,
    showZoomLabelValue: state.ZoomReducer.showZoomLabelValue,
    footBarHeight: state.ContextReducer.footBarHeight,
    isShowFlashBlack: state.PreviewReducer.isShowFlashBlack,
    isShowBigText: state.ModeReducer.isShowBigText,
    isShowtimeLapse: state.SettingReducer.isShowtimeLapse,
    isBigVideoTimerVisible: state.RecordReducer.isBigVideoTimerVisible,
    isSmallVideoTimerVisible: state.RecordReducer.isSmallVideoTimerVisible,
    isAssGridViewShow: state.SettingReducer.isAssGridViewShow,
    modeIndex: state.ModeReducer.modeIndex,
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall,
    modeChangeDone: state.ModeReducer.modeChangeDone,
    showBlur: isShowBlur
  }
}

let cameraDispatcher = (dispatch) => {
  return {
    initCamera: (cameraId, mode) => {
      dispatch(Action.initCamera(cameraId, mode))
    },
    initZoomRatio: (min: number, max: number) => {
      dispatch(Action.initZoomRatio(min, max))
    },
    resetZoomRatio: (zoomRatio: number) => {
      dispatch(Action.resetZoomRatio(zoomRatio))
    },
    changeZoomRatio: (zoomRatio: number) => {
      dispatch(Action.changeZoomRatio(zoomRatio))
    },
    updateZoomPercentage: (zoomPercentage: number) => {
      dispatch(Action.updateZoomPercentage(zoomPercentage))
    },
    prepareSurface: (surfaceId: number) => {
      dispatch(Action.prepareSurface(surfaceId))
    },
    updateSurfaceId: (surfaceId: number) => {
      dispatch(Action.updateSurfaceId(surfaceId))
    },
    startPreview: () => {
      dispatch(Action.startPreview())
    },
    switchCamera: (cameraId: string) => {
      dispatch(Action.switchCamera(cameraId))
    },
    startVideoFlag: (isStartVideo: boolean) => {
      dispatch(Action.startVideoFlag(isStartVideo))
    },
    updateCameraPosition: (cameraPosition: string) => {
      dispatch(Action.updateCameraPosition(cameraPosition))
    },
    changeXComponentSize: (xComponentWidth: number, xComponentHeight: number) => {
      dispatch(Action.changeXComponentSize(xComponentWidth, xComponentHeight))
    },
    updateShowPreviewFlag: (isShowPreview: boolean) => {
      dispatch(Action.updateShowPreviewFlag(isShowPreview))
    },
    updateIsShowZoomText: (isShowZoomText: boolean) => {
      dispatch(Action.updateShowZoomTextFlag(isShowZoomText))
    },
    updateIsPhotoZoomDetails: (isPhotoZoomDetails: boolean) => {
      dispatch(Action.updatePhotoZoomDetailsFlag(isPhotoZoomDetails))
    },
    updateBaseZoom: (zoomRatio: number) => {
      dispatch(Action.updateBaseZoom(zoomRatio))
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
      dispatch(Action.updateVideoState('beforeTakeVideo'))
      dispatch(Action.updateBigVideoTimerVisible(false))
      dispatch(Action.updateSmallVideoTimerVisible(false))
      dispatch(Action.updateScreenStatus(false))
    },
    changeTimeLapse: (isShowtimeLapse: boolean) => {
      dispatch(Action.changeTimeLapse(isShowtimeLapse))
    },
    capture: () => {
      dispatch(Action.updateShowFlashBlackFlag(true))
      dispatch(Action.capture())
    },
    startRecording: () => {
      dispatch(Action.startRecording())
      dispatch(Action.updateVideoState('startTakeVideo'))
      dispatch(Action.updateBigVideoTimerVisible(true))
      dispatch(Action.updateScreenStatus(true))
    },
    assistiveGridView: (isViewShow) => {
      dispatch(Action.assistiveGridView(isViewShow))
    },
    thirdPartyCall: (isThirdPartyCall: boolean, action: string) => {
      dispatch(Action.thirdPartyCall(isThirdPartyCall, action))
    },
    faCall: (isFaCall: boolean) => {
      dispatch(Action.faCall(isFaCall))
    },
    initMode: (mode: string) => {
      dispatch(Action.initMode(mode))
    },
    updateModeIndex: (index: number) => {
      dispatch(Action.updateModeIndex(index))
    },
    updateMode: (mode: string) => {
      dispatch(Action.updateMode(mode))
    },
    changeToMode: (mode: string) => {
      dispatch(Action.changeMode(mode))
    },
    swipeChangeMode: (swipeModeIndex) => {
      dispatch(Action.swipeChangeMode(swipeModeIndex))
    },
    updateShowZoomLabelValue: (flag: boolean) => {
      dispatch(Action.updateShowZoomLabelValue(flag))
    },
    reloadThumbnail: () => {
      dispatch(Action.reloadThumbnail())
    },
    changeCameraPosition: (cameraPosition: string) => {
      dispatch(Action.setCameraPosition(cameraPosition))
    },
    updateShowPinch: (flag: boolean) => {
      dispatch(Action.updateShowPinch(flag))
    },
    swipeModeChangeDone: (actionOff) => {
      dispatch(Action.swipeModeChangeDone(actionOff))
    },
  }
}

globalThis.mXComponentController = new XComponentController()

class StateStruct {
  mode
  baseZoom
  curMode
  isShowPreview
  surfaceId
  xComponentWidth
  xComponentHeight
  cameraPosition
  curCameraPosition
  minZoomRatio
  maxZoomRatio
  zoomRatio
  platformCapability
  videoState
  footBarHeight
  isShowZoomText
  showZoomLabelValue
  modeIndex
  isThirdPartyCall
  isShowBigText
  isShowtimeLapse
  isBigVideoTimerVisible
  isSmallVideoTimerVisible
  isAssGridViewShow
  isShowFlashBlack
  modeChangeDone
  isShowPageView
  showBlur
  isFaCall
  scaleX
  rotateAngle
  rotateAngleSec
  switchBackgroundOpacity
  initCamera: Function
  initZoomRatio: Function
  changeZoomRatio: Function
  updateZoomPercentage: Function
  prepareSurface: Function
  startPreview: Function
  switchCamera: Function
  updateCameraPosition: Function
  startVideoFlag: Function
  changeXComponentSize: Function
  updateShowPreviewFlag: Function
  updateIsShowZoomText: Function
  updateIsPhotoZoomDetails: Function
  updateBaseZoom: Function
  changeImageSize: Function
  changeVideoSize: Function
  close: Function
  stopRecording: Function
  changeTimeLapse: Function
  capture: Function
  startRecording: Function
  assistiveGridView: Function
  swipeChangeMode: Function
  thirdPartyCall: Function
  faCall: Function
  initMode: Function
  updateMode: Function
  changeToMode: Function
  updateModeIndex: Function
  updateShowZoomLabelValue: Function
  reloadThumbnail: Function
  updateShowPinch: Function
  swipeModeChangeDone: Function
}

@Component
export struct PreviewArea {
  private TAG: string = '[PreviewArea]:'
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  @State state: StateStruct = new StateStruct()
  @State mAspectRatio: number = 3 / 4
  @State btnSwitch: boolean = false
  @State btnSwitchSec: boolean = false
  @State isSwitchBackground: boolean = false
  @State pageType: string = ''
  private isShowPreview: boolean = false
  private isForegroundInit: boolean = false
  private settingManager = SettingManager.getInstance()
  private pinchGestureTimer: number
  private baseZoom: number
  private modeArray: Array<string> = ['MULTI', 'PHOTO', 'VIDEO']

  private async onCameraInit(data) {
    Log.info(`${this.TAG} EventBus onCameraInit isShowPreview = ${this.isShowPreview} platformCapability = ${this.state.platformCapability} E`)
    if (this.isForegroundInit === true) {
      Log.info(`${this.TAG} EventBus onCameraInit foregroundInit`)
      this.doCameraAction()
      if (!this.state.isThirdPartyCall) {
        this.state.reloadThumbnail()
      }
      this.isForegroundInit = false
    }
    if (this.state.platformCapability) {
      //      if (!this.state.isShowPreview) {
      this.settingManager.loadAllSetting().then(() => {
        this.settingManager.setCameraId(this.state.cameraPosition)

        let imageSize = this.settingManager.getImageSize()
        this.state.changeImageSize(imageSize)

        let videoSize = this.settingManager.getVideoSize()
        this.state.changeVideoSize(videoSize)

        let isAssGridViewShow = this.settingManager.getAssistiveGrid()
        this.state.assistiveGridView(isAssGridViewShow)

        //          GeoLocation.getInstance().on()

        display.getDefaultDisplay().then((dis) => {
          let screenHeight = px2vp(dis.height - 176)
          let screenWidth = px2vp(dis.width)

          this.settingManager.setScreenHeight(screenHeight)
          this.settingManager.setScreenWidth(screenWidth)

          let xComponentSize = this.settingManager.getPreviewDisplaySize(this.state.mode)
          Log.info(this.TAG + " PreviewArea xComponentSize = " + JSON.stringify(xComponentSize))
          this.state.changeXComponentSize(xComponentSize.width, xComponentSize.height)
          //            this.isShowPreview = true
          this.state.updateShowPreviewFlag(true)
        })
      })
      //      }
    }
    Log.info(`${this.TAG} onCameraInit isShowPreview = ${this.state.isShowPreview}  X`)
  }

  public onScaleUpdate(scale) {
    Log.info(`${this.TAG} onScaleUpdate called scale = ${scale}`)
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

  private async doCameraAction() {
    Log.debug(`${this.TAG} doCameraAction E`)
    this.settingManager.setCameraId(this.state.cameraPosition)
    if (this.state.curCameraPosition != this.state.cameraPosition) {
      this.state.switchCamera(this.state.cameraPosition)
    } else if (this.state.curMode != this.state.mode) {
      this.state.changeToMode(this.state.mode)
    } else {
      this.state.startPreview()
    }
    this.state.updateCameraPosition(this.state.cameraPosition)
    this.state.updateMode(this.state.mode)
    if (globalThis?.keepCameraZoomRatio && globalThis.keepCameraZoomRatio) {
      globalThis.keepCameraZoomRatio = false
    } else {
      this.state.changeZoomRatio(1)
    }
    Log.debug(`${this.TAG} doCameraAction X`)
  }

  private async onModeChanged(data) {
    Log.debug(`${this.TAG} onModeChanged E data.mode: ${data.mode}`)
    let xComponentSize = this.settingManager.getPreviewDisplaySize(data.mode)
    this.state.changeXComponentSize(xComponentSize.width, xComponentSize.height)
    this.state.updateShowPreviewFlag(true)
    Log.debug(`${this.TAG} onModeChanged X`)
  }

  private async onRecordError() {
    Log.info(`${this.TAG} onRecordError invoke E`)
    promptAction.showToast({
      message: "录像异常",
      duration: 2000,
    })
    if (this.state.videoState === 'startTakeVideo') {
      this.state.stopRecording()
    }
    this.state.close()
    Log.info(`${this.TAG} onRecordError invoke X`)
  }

  aboutToAppear(): void {
    Log.info(`${this.TAG} PreviewArea aboutToAppear ${JSON.stringify(router.getParams())}`)
    let routerParams = router.getParams()
    if (routerParams && routerParams.pageType) {
      this.pageType = routerParams.pageType.toString()
    }
    getStore().connect(cameraState, cameraDispatcher)(this.state)
    this.appEventBus.on(Action.ACTION_INIT_DONE, this.onCameraInit.bind(this))
    this.appEventBus.on(Action.ACTION_ON_MODE_CHANGED, this.onModeChanged.bind(this))
    this.appEventBus.on(Action.ACTION_KEEP_SCREEN_ON, this.onKeepScreen.bind(this))
    this.appEventBus.on(Action.ACTION_RECORD_ERROR, this.onRecordError.bind(this))
    this.appEventBus.on(Action.ACTION_UPDATE_CAMERA_STATUS, this.updateCameraStatus.bind(this))
    globalThis.updateCameraStatus = (() => {
      Log.info(`${this.TAG} globalThis.updateCameraStatus called`)
      this.updateCameraStatus()
    })
    this.calledByOther()
    this.state.initCamera(this.state.curCameraPosition, this.state.mode)
    this.state.initZoomRatio(1, 6) //TODO 需要动态取得实际变焦能力范围
    Log.info(`${this.TAG} aboutToAppear end`)
    Log.start(Log.X_COMPONENT_LIFE)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} previewAreaLand aboutToDisappear called`)
    this.appEventBus.off(Action.ACTION_INIT_DONE, this.onCameraInit.bind(this))
    this.appEventBus.off(Action.ACTION_ON_MODE_CHANGED, this.onModeChanged.bind(this))
    this.appEventBus.off(Action.ACTION_UPDATE_CAMERA_STATUS, this.updateCameraStatus.bind(this))
    GeoLocation.getInstance().off()
    globalThis.cameraNeedStatus = CameraNeedStatus.CAMERA_NEED_RELEASE
    this.updateCameraStatus()
  }

  private releaseCamera() {
    Log.info(`${this.TAG} globalThis.releaseCamera called`)
    globalThis.cameraNeedStatus = CameraNeedStatus.CAMERA_NO_NEED_TO_DO
    if (this.state.videoState === 'startTakeVideo') {
      this.state.stopRecording()
    }
    this.state.close()
  }

  private async onForegroundInit() {
    Log.info(`${this.TAG} onForegroundInit E `)
    this.pageType = ''
    globalThis.cameraNeedStatus = CameraNeedStatus.CAMERA_NO_NEED_TO_DO
    this.isForegroundInit = true
    this.calledByOther()
    this.state.initCamera(this.state.curCameraPosition, this.state.mode)
    Log.info(`${this.TAG} onForegroundInit X`)
  }

  private calledByOther(): void {
    Log.info(`${this.TAG} calledByOther invoke E`)
    let from: string = ""
    let uri: string = ""

    if (globalThis?.cameraAbilityWant) {
      Log.debug(`${this.TAG} cameraAbilityWant: ${JSON.stringify(globalThis.cameraAbilityWant)}`)
      if (globalThis.cameraAbilityWant?.parameters?.from) {
        from = globalThis.cameraAbilityWant.parameters.from
      }
      if (globalThis.cameraAbilityWant?.parameters?.uri) {
        uri = globalThis.cameraAbilityWant.parameters.uri
      }
    } else {
      this.state.thirdPartyCall(false, "")
      return
    }
    Log.info(`${this.TAG} from: ${from}  uri: ${uri}`)

    if (from === "FA") {
      Log.info(`from === "FA"`)
      this.state.faCall(true)
      this.state.thirdPartyCall(false, "")
      this.initStateMode(uri)
    } else if (uri != "") {
      this.state.faCall(false)
      this.state.thirdPartyCall(true, globalThis.cameraAbilityWant.action)
      this.initStateMode(uri)
    } else {
      this.state.faCall(false)
      this.state.thirdPartyCall(false, "")
    }
    Log.info(`${this.TAG} calledByOther invoke X: ${this.state.mode}`)
  }

  private initStateMode(uri: string) {
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

  private updateCameraStatus() {
    Log.info(`${this.TAG} updateCameraStatus  cameraStatus: ${globalThis.cameraStatus}`)
    Log.info(`${this.TAG} updateCameraStatus  cameraNeedStatus: ${globalThis.cameraNeedStatus}`)

    if (this.canInit() && globalThis.cameraNeedStatus == CameraNeedStatus.CAMERA_NEED_INIT) {
      this.onForegroundInit()
    }
    if (this.canRelease() && globalThis.cameraNeedStatus == CameraNeedStatus.CAMERA_NEED_RELEASE) {
      this.releaseCamera()
    }
    Log.info(`${this.TAG} updateCameraStatus X`)
  }

  private canInit(): boolean {
    //相机状态是首次加载或者session释放完成状态，才能进行初始化操作
    return globalThis.cameraStatus == CameraStatus.CAMERA_BEFORE_VALUE || globalThis.cameraStatus == CameraStatus.CAMERA_RELEASE_FINISHED
  }

  private canRelease(): boolean {
    //相机状态是预览完成状态或录像完成状态才能进行释放操作
    return globalThis.cameraStatus == CameraStatus.CAMERA_PREVIEW_FINISHED || globalThis.cameraStatus == CameraStatus.CAMERA_TAKE_VIDEO_FINISHED
  }

  onBackPress(): void {
    Log.info(`${this.TAG} previewAreaLand onBackPress called`)
  }

  onPageHide(): void {
    this.state.startVideoFlag(false)
  }

  private pinchGestureStart(event: GestureEvent) {
    Log.info(`${this.TAG} pinchGestureStart E`)
    if (this.state.mode != 'MULTI' && this.state.curCameraPosition !== 'FRONT') {
      clearTimeout(this.pinchGestureTimer)
      this.state.updateIsShowZoomText(true)
      this.state.updateShowPinch(true)
      this.state.updateShowZoomLabelValue(false)
      this.baseZoom = this.state.zoomRatio
    }
    Log.info(`${this.TAG} pinchGestureStart X`)
  }

  private pinchGestureUpdate(event: GestureEvent) {
    Log.info(`${this.TAG} pinchGestureUpdate E`)
    if (this.state.mode != 'MULTI' && this.state.curCameraPosition !== 'FRONT') {
      let zoomRatio = event.scale + this.baseZoom - 1
      if (zoomRatio > 6) {
        zoomRatio = 6
      }
      if (zoomRatio < 1) {
        zoomRatio = 1
      }
      this.state.changeZoomRatio(zoomRatio)
    }
    Log.info(`${this.TAG} pinchGestureUpdate X`)
  }

  private pinchGestureEnd(event: GestureEvent) {
    Log.info(`${this.TAG} pinchGestureEnd E`)
    if (this.state.mode != 'MULTI' && this.state.curCameraPosition !== 'FRONT') {
      this.state.updateShowZoomLabelValue(true)
      this.state.updateShowPinch(false)
      this.pinchGestureTimer = setTimeout(() => {
        this.state.updateIsShowZoomText(false)
      }, 2000)
    }
    Log.info(`${this.TAG} pinchGestureEnd X`)
  }

  private onPreviewClicked() {
    Log.info(`${this.TAG} click preview called`)
    Log.info(`${this.TAG} click preview isShowtimeLapse= ${this.state.isShowtimeLapse}`)
    Log.info(`${this.TAG} click preview state.mode= ${this.state.mode}`)
    if (this.state.mode === 'PHOTO' && this.state.isShowtimeLapse) {
      this.state.changeTimeLapse(false)
      this.state.capture()
    } else if (this.state.mode === 'VIDEO' && this.state.isShowtimeLapse) {
      this.state.changeTimeLapse(false)
      this.state.startRecording()
    }
  }

  private swipeChangeMode(swipe: number) {
    Log.info(`${this.TAG} swipeChangeMode E`)
    if (!this.state.modeChangeDone && this.state.modeIndex + swipe >= 0 && this.state.modeIndex + swipe <= this.modeArray.length - 1 && !this.state.isShowtimeLapse) {
      this.state.swipeChangeMode(this.state.modeIndex + swipe)
      this.state.swipeModeChangeDone(true)
    }
    Log.info(`${this.TAG} swipeChangeMode X`)
  }

  private onKeepScreen(data) {
    Log.info(`${this.TAG} onKeepScreen E`)
    if (data) {
      globalThis.cameraWinClass.setKeepScreenOn(data.isKeepScreenOn).then((v) => {
        Log.info('Succeeded in setting the screen to be always on. ' + JSON.stringify(v))
      }).catch((err) => {
        Log.error('Failed to set the screen to be always on. Cause: ' + JSON.stringify(err));
      });
    }
    Log.info(`${this.TAG} onKeepScreen X`)
  }

  build() {
    Column() {
      if (this.state.isShowPreview) {
        Stack() {
          XComponent({
            id: '',
            type: 'surface',
            libraryname: '',
            controller: globalThis.mXComponentController
          })
            .onLoad(() => {
              Log.end(Log.X_COMPONENT_LIFE)
              Log.info(`${this.TAG} XComponent_onLoad `)
              let surfaceId = globalThis.mXComponentController.getXComponentSurfaceId()
              this.state.prepareSurface(surfaceId)
              this.doCameraAction()
            })
            .width(this.state.xComponentWidth)
            .height(this.state.xComponentHeight)
            .animation({
              duration: 100,
              curve: Curve.Sharp,
              delay: 0,
              iterations: 1,
              playMode: PlayMode.Normal
            })

          if (this.isSwitchBackground) {
            Column() {
            }
            .width(this.state.xComponentWidth)
            .height(this.state.xComponentHeight)
            .backgroundColor('#000')
            .opacity(this.state.switchBackgroundOpacity)
          }

          if (this.state.showBlur) {
            Column()
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
              .backgroundColor(Color.Black)
              .border({ width: { top: 0.5, bottom: 0.5 }, color: Color.Black })
          }

          if (this.btnSwitch) {
            Image($r('app.media.whitePicture'))
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
              .syncLoad(false)
              .scale({ x: this.state.scaleX, y: 1.0 })
              .rotate({ x: 0, y: 10, z: 0, angle: this.state.rotateAngle })
                // .opacity(this.state.btnOpacity_first)
              .onComplete(() => { /* this.switchAnimation() */
              })
          }

          if (this.btnSwitchSec) {
            Image($r('app.media.whitePicture'))
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
              .syncLoad(false)
              .scale({ x: this.state.scaleX, y: 1.0 })
              .rotate({ x: 0, y: 10, z: 0, angle: this.state.rotateAngleSec })
                // .opacity(this.state.btnOpacity_sec)
              .onComplete(() => { /* this.switchAnimationSec() */
              })
          }

          if (this.state.isShowFlashBlack) {
            ShowFlashBlack()
          }

          if (this.state.isShowZoomText && deviceInfo.deviceType !== "default" && !this.state.isShowtimeLapse) {
            Stack({ alignContent: Alignment.Top }) {
              ZoomText({ state: $state })
            }
            .width('100%')
            .height('96%')
          }

          if (this.state.isShowBigText) {
            Stack({ alignContent: Alignment.BottomStart }) {
              BigText()
            }
            .width('100%')
            .height('100%')
            .padding({ bottom: '40vp' })
          }

          if (this.state.isAssGridViewShow === '1' && this.state.mode !== 'MORE') {
            AssistiveGridView()
          }

          if (this.state.isSmallVideoTimerVisible) {
            SmallVideoTimer()
          }

          if (this.state.isBigVideoTimerVisible) {
            BigVideoTimer()
          }

          if (this.state.isShowtimeLapse) {
            Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
              Column() {
                TimeLapseView()
              }.width('100%').height(150)
            }
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .height('100%')
    .width(this.state.xComponentWidth)
    .aspectRatio(this.mAspectRatio)
    .margin({ top: 0 })
    .backgroundColor('#000')
    .gesture(
    GestureGroup(
    GestureMode.Exclusive,
    TapGesture({ fingers: 1, count: 1 })
      .onAction(this.onPreviewClicked.bind(this)),
    PinchGesture({ fingers: 2, distance: 1 })
      .onActionStart(this.pinchGestureStart.bind(this))
      .onActionUpdate(this.pinchGestureUpdate.bind(this))
      .onActionEnd(this.pinchGestureEnd.bind(this)),
    PanGesture({ fingers: 1, direction: PanDirection.Left, distance: 10 })
      .onActionEnd(() => {
        if (!this.state.isThirdPartyCall && !globalThis.cameraAbilityWant?.parameters?.from) {
          this.swipeChangeMode(1)
        }
      }),
    PanGesture({ fingers: 1, direction: PanDirection.Right, distance: 10 })
      .onActionEnd(() => {
        if (!this.state.isThirdPartyCall && !globalThis.cameraAbilityWant?.parameters?.from) {
          this.swipeChangeMode(-1)
        }
      })
    )
    )
  }
}