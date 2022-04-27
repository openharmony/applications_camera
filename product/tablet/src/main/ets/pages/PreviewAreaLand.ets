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
import AspectRatio from '../../../../../../common/src/main/ets/default/setting/AspectRatio'
import { BigText
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/bigText/BigText'
import { BigVideoTimer } from './BigVideoTimer'
import { CameraId, getCameraId } from '../../../../../../common/src/main/ets/default/setting/CameraId'
import { CameraPlatformCapability
} from '../../../../../../common/src/main/ets/default/Camera/CameraPlatformCapability'
import { CLog } from '../../../../../../common/src/main/ets/default/Utils/CLog'
import DisplayUtil from '../../../../../../common/src/main/ets/default/Utils/DisplayUtil'
import getStore from '../../../../../../common/src/main/ets/default/redux/store'
import Resolution from '../../../../../../common/src/main/ets/default/setting/Resolution'
import { SettingsUtil } from '../../../../../../common/src/main/ets/default/Utils/SettingsUtil'
import { ShowFlashBlack
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/animate/ShowFlashBlack'
import { SmallVideoTimer } from './SmallVideoTimer'
import { ZoomText
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/zoomView/ZoomText'

let cameraState = (state) => {
  return {
    platformCapability: state.CameraInitReducer.platformCapability,
    thumbnail: state.CaptureReducer.thumbnail,
    uiEnable: state.UiReducer.uiEnable
  }
}

let cameraDispatch = (dispatch) => {
  return {
    initCamera: (cameraId, mode) => {
      dispatch(Action.initCamera(cameraId, mode))
    },
    surfacePrepare: (surfaceId) => {
      dispatch(Action.surfacePrepare(surfaceId))
    },
    startPreview: () => {
      dispatch(Action.StartPreview())
    },
    switchCamera: (cameraId) => {
      dispatch(Action.SwitchCamera(cameraId))
    },
    changeMode: (mode) => {
      dispatch(Action.ChangeMode(mode))
    },
    close: () => {
      dispatch(Action.close())
    },
    capture: () => {
      dispatch(Action.UiState(false))
      dispatch(Action.capture())
    },
    startRecording: () => {
      dispatch(Action.UiState(false))
      dispatch(Action.startRecording())
    },
    pauseRecording: () => {
      dispatch(Action.UiState(false))
      dispatch(Action.pauseRecording())
    },
    resumeRecording: () => {
      dispatch(Action.UiState(false))
      dispatch(Action.resumeRecording())
    },
    stopRecording: () => {
      dispatch(Action.UiState(false))
      dispatch(Action.stopRecording())
    },
    changeImageSize: (imageSize) => {
      dispatch(Action.changeImageSize(imageSize))
    },
    changeVideoSize: (videoSize) => {
      dispatch(Action.changeVideoSize(videoSize))
    },
    changeZoomRatio: (zoomRatio) => {
      dispatch(Action.ChangeZoomRatio(zoomRatio))
    },
    disableUi: () => {
      dispatch(Action.UiState(false))
    }
  }
}

@Component
export struct PreviewAreaLand {
  private TAG: string = '[PreviewAreaLand]:'
  mXComponentController: XComponentController = new XComponentController()
  @Link surfaceId: number
  //  private cameraService = CameraService.getInstance()
  private settingsUtil = SettingsUtil.getInstance()
  private getPhotoValue: Promise<string>
  private getVideoValue: Promise<string>
  @Link aspectRatio: number
  @Link @Watch("onpreviewImageUpdated") previewImage: string
  @Link @Watch("onCameraInit") state: any
  @State isShowBigText: boolean = false
  @Link isSmallVideoTimerVisible: boolean
  @Link isBigVideoTimerVisible: boolean
  @Link cameraPosition: string
  @Link XcomponentWidth: string
  @Link XcomponentHeight: string
  @Link isResumeVideo: boolean
  @Link iscContinueVideo: boolean
  @Link isShowZoomText: boolean
  @Link zoomValue: number
  @Link isPhotoZoomDetails: boolean
  @State baseZoom: number = 1
  @Link zoomPercentage: number
  @Link isPinchGesture: boolean
  @Link maxZoomRatio: number
  @Link minZoomRatio: number
  @Link pinchGestureTimer: number
  @Link onTouchDownTimer: number
  @Link isShowFlashBlack: boolean
  @Link btnSwitch: boolean
  @Link btnSwitchSec: boolean
  @Link btnOpacity_first: number
  @Link btnOpacity_sec: number
  @State scaleX: number = 1
  @State rotateAngle: number = 0
  @State scaleXSec: number = 0.8
  @State rotateAngleSec: number = 80
  @Link isSwitchBackground: boolean
  @State switchBackgroundOpacity: number = 1
  @Link curCameraPosition: string
  @Link curPreviewImage: string
  @Link xComponentChangeFlag: boolean
  @Link cameraId: string
  @Link isStartVideo: boolean
  @State isShowPreview: boolean = false
  @State bigTextPositionY: object = { y: '30vp' }
  private mConnect: any

  onpreviewImageUpdated(): void {
    this.settingsUtil.setMode(this.previewImage)
    this.isShowBigText = true
  }

  onCameraInit(): void {
    CLog.info(`${this.TAG} onCameraInit isShowPreview = ${this.isShowPreview} platformCapability = ${this.state.platformCapability} E`)
    if (this.state.platformCapability) {
      if (!this.isShowPreview) {
        this.settingsUtil.loadAllSetting().then(() => {
          let platformCapability: CameraPlatformCapability = this.state.platformCapability
          this.settingsUtil.setCameraPlatformCapability(platformCapability)
          this.settingsUtil.setCameraId(getCameraId(this.curCameraPosition))
          this.settingsUtil.setMode(this.curPreviewImage)

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
            CLog.info(this.TAG + " xComponentSize = " + JSON.stringify(xComponentSize))
            this.XcomponentWidth = xComponentSize.width.toString() + 'px'
            this.XcomponentHeight = xComponentSize.height.toString() + 'px'
            this.isShowPreview = true
          })
        })
      }
    }
    CLog.info(`${this.TAG} onCameraInit isShowPreview = ${this.isShowPreview}  X`)
  }

  public onScaleUpdate(scale) {
    CLog.info(`${this.TAG} onScaleUpdate called scale= ${scale}`)
    let tempZoom = 1.0;
    if (scale > 1) {
      tempZoom = this.baseZoom + scale - 1
    } else {
      tempZoom = this.baseZoom * scale
    }
    if (tempZoom - this.zoomValue >= 0.1 || tempZoom - this.zoomValue <= -0.1) {
      if (tempZoom >= this.minZoomRatio && tempZoom <= this.maxZoomRatio) { //TODO 需要动态取得实际变焦能力范围
        //        this.cameraService.setZoomRatio(tempZoom)
        this.state.changeZoomRatio(tempZoom)
        this.zoomValue = tempZoom
        CLog.info(`${this.TAG} this.zoomPercentage=== ${this.zoomPercentage}`)
        this.zoomPercentage = this.ratioToPercentage(this.zoomValue)
      }
    }
  }

  public ratioToPercentage(ratio) {
    return (Math.log2(ratio) - Math.log2(this.minZoomRatio)) / (Math.log2(this.maxZoomRatio) - Math.log2(this.minZoomRatio))
  }

  private async doCameraAction(surfaceId: number, previewImage: string, mXComponentController: XComponentController) {
    let size = this.settingsUtil.getPreviewSize()
    CLog.info(`${this.TAG} doCameraAction  size = ${JSON.stringify(size)}`)
    let control: any = this.mXComponentController
    control.setXComponentSurfaceSize({
      surfaceWidth: size.width,
      surfaceHeight: size.height
    })

    this.state.surfacePrepare(surfaceId)
    if (this.curCameraPosition != this.cameraPosition) {
      if (this.cameraPosition === 'ORIGIN') {
        //        await this.cameraService.initCamera(surfaceId, previewImage, mXComponentController)
        this.state.startPreview()
      } else {
        //        await this.cameraService.switchCamera(surfaceId, , mXComponentController)
        this.state.switchCamera(getCameraId(this.cameraPosition), surfaceId)
      }
    } else if (this.curPreviewImage != this.previewImage) {
      //      await this.cameraService.changeMode_(previewImage, surfaceId, mXComponentController)
      this.state.changeMode(previewImage)
    } else if (this.isStartVideo) {
      //      await this.cameraService.startVideo(surfaceId, mXComponentController)
      this.isStartVideo = false
    } else {
      //      await this.cameraService.initCamera(surfaceId, previewImage, mXComponentController)
      this.state.startPreview()
    }
    this.curPreviewImage = this.previewImage
    this.curCameraPosition = this.cameraPosition
  }

  async aboutToAppear() {
    CLog.info(`${this.TAG} aboutToAppear`)
    this.mConnect = getStore().connect(cameraState, cameraDispatch)(this.state)
    globalThis.releaseCamera = (() => {
      CLog.info(`${this.TAG} globalThis.releaseCamera called`)
      this.state.close()
      //      let cameraService = CameraService.getInstance()
      //      cameraService.releaseVideo()
      //      cameraService.releaseCamera()
    })

    // todo 后续编译问题解决后，优先用事件通知的方式切换XComponent
    //    this.appEventBus.on('changeXComponent', () => {
    //      this.xComponentChangeFlag = !this.xComponentChangeFlag
    //    })

    globalThis.onForegroundInit = (() => {
      CLog.info(`${this.TAG} globalThis.onForegroundInit called`)
      this.xComponentChangeFlag = !this.xComponentChangeFlag
    })
    this.state.initCamera(getCameraId(this.curCameraPosition), this.previewImage)
    this.minZoomRatio = 1
    this.maxZoomRatio = 6
    //    for (let i = 0; i < zoomRatioRange.length; i++) {
    //      if (this.maxZoomRatio < zoomRatioRange[i]) {
    //        this.maxZoomRatio = zoomRatioRange[i]
    //      }
    //      if (this.minZoomRatio > zoomRatioRange[i]) {
    //        this.minZoomRatio = zoomRatioRange[i]
    //      }
    //    }
    CLog.info(`${this.TAG} aboutToAppear end`)
  }

  private aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear called`)
    this.mConnect.destroy()
    globalThis.releaseCamera()
  }

  private onBackPress(): void {
    CLog.info(`${this.TAG} onBackPress called`)
  }

  private onPageHide() {
    this.isStartVideo = false
  }

  public switchAnimationSec() {
    CLog.info(`${this.TAG} switchAnimationSec called`)
    animateTo({ duration: 200,
      delay: 0,
      curve: Curve.Sharp,
    }, () => {
      this.btnOpacity_sec = 1
    })
    animateTo({
      duration: 350,
      curve: Curve.FastOutSlowIn,
      delay: 0,
    }, () => {
      CLog.info(`${this.TAG} btnSwitchSec callback btnSwitchSec= ${this.btnSwitchSec}`)
      this.scaleXSec = 1
    })
    animateTo({
      duration: 350,
      curve: 'cubic-bezier(0.21, 0.27, 0.20, 1.00)',
      delay: 0,
      onFinish: () => {
        CLog.info(`${this.TAG} btnSwitchSec onFinish btnSwitchSec= ${this.btnSwitchSec}`)
        this.btnSwitchSec = false
        this.btnOpacity_sec = 0
        this.scaleXSec = 0.8
        this.rotateAngleSec = 80
        this.switchBackgroundAnimation()
      }
    }, () => {
      CLog.info(`${this.TAG} btnSwitchSec callback btnSwitchSec= ${this.btnSwitchSec}`)
      this.rotateAngleSec = 0
      //      this.btnSwitchSec = true
    })
  }

  public switchAnimation() {
    CLog.info(`${this.TAG} switchAnimation called`)
    animateTo({ duration: 300,
      delay: 0,
      curve: Curve.Sharp,
    }, () => {
      this.btnOpacity_first = 0
    })
    animateTo({ duration: 350,
      delay: 0,
      curve: Curve.FastOutSlowIn,
      onFinish: () => {
        CLog.info(`${this.TAG} btnSwitch onFinish btnSwitch= ${this.btnSwitch}`)
        this.btnSwitch = false
        this.btnOpacity_first = 1
        this.scaleX = 1
        this.rotateAngle = 0
      }
    }, () => {
      CLog.info(`${this.TAG} btnSwitch callback btnSwitch= ${this.btnSwitch}`)
      this.scaleX = 0.8
      this.rotateAngle = 80
    })
  }

  public switchBackgroundAnimation() {
    animateTo({ duration: 350,
      delay: 0,
      curve: Curve.Sharp,
      onFinish: () => {
        this.isSwitchBackground = false
        this.switchBackgroundOpacity = 1
      }
    }, () => {
      this.switchBackgroundOpacity = 0
    })
  }

  build() {
    Column() {
      if (this.isShowPreview) {
        Stack() {
          if (this.xComponentChangeFlag) {
            XComponent({
              id: '',
              type: 'surface',
              libraryname: '',
              controller: this.mXComponentController
            })
              .onLoad(() => {
                //              this.mXComponentController.setXComponentSurfaceSize({surfaceWidth:this.XcomponentWidth,surfaceHeight:this.XcomponentHeight})
                CLog.info(`${this.TAG} XComponent onLoad cameraPosition: ${this.cameraPosition}`)
                CLog.info(`${this.TAG} XComponent onLoad previewImage: ${this.previewImage}`)
                this.surfaceId = this.mXComponentController.getXComponentSurfaceId()
                CLog.info(`${this.TAG} XComponent onLoad surfaceId: ${this.surfaceId}`)
                this.doCameraAction(this.surfaceId, this.previewImage, this.mXComponentController)
              })
              .width(this.XcomponentWidth)
              .height(this.XcomponentHeight)
          } else {
            XComponent({
              id: '',
              type: 'surface',
              libraryname: '',
              controller: this.mXComponentController
            })
              .onLoad(() => {
                //              this.mXComponentController.setXComponentSurfaceSize({surfaceWidth:this.XcomponentWidth,surfaceHeight:this.XcomponentHeight})
                CLog.info(`${this.TAG} XComponent onLoad cameraPosition: ${this.cameraPosition}`)
                CLog.info(`${this.TAG} XComponent onLoad previewImage: ${this.previewImage}`)
                this.surfaceId = this.mXComponentController.getXComponentSurfaceId()
                CLog.info(`${this.TAG} XComponent onLoad surfaceId: ${this.surfaceId}`)
                this.doCameraAction(this.surfaceId, this.previewImage, this.mXComponentController)
              })
              .width(this.XcomponentWidth)
              .height(this.XcomponentHeight)
          }

          if (this.isSwitchBackground) {
            Column() {
            }
            .width(this.XcomponentWidth)
            .height(this.XcomponentHeight)
            .backgroundColor("#000")
            .opacity(this.switchBackgroundOpacity)
          }
          if (this.btnSwitch) {
            Image($r('app.media.whitePicture'))
              .width(this.XcomponentWidth)
              .height(this.XcomponentHeight)
                //                .opacity(this.btnOpacity_first)
              .syncLoad(false)
              .scale({ x: this.scaleX, y: 1.0 })
              .rotate({ x: 0, y: 10, z: 0, angle: this.rotateAngle })
              .onComplete(() => {
                this.switchAnimation()
              })
          }
          if (this.btnSwitchSec) {
            Image($r('app.media.whitePicture'))
              .width(this.XcomponentWidth)
              .height(this.XcomponentHeight)
                //                .opacity(this.btnOpacity_sec)
              .syncLoad(false)
              .scale({ x: this.scaleXSec, y: 1.0 })
              .rotate({ x: 0, y: 10, z: 0, angle: this.rotateAngleSec })
              .onComplete(() => {
                this.switchAnimationSec()
              })
          }
          if (this.isShowFlashBlack) {
            ShowFlashBlack({
              XcomponentWidth: $XcomponentWidth,
              XcomponentHeight: $XcomponentHeight,
              isShowFlashBlack: $isShowFlashBlack
            })
          }

          if (this.isShowZoomText) {
            Stack({ alignContent: Alignment.Top }) {
              ZoomText({ zoomValue: $zoomValue })
            }.width('100%')
            .height('96')
          }

          if (this.isShowBigText) {
            Stack({ alignContent: Alignment.BottomStart }) {
              BigText({
                previewImage: $previewImage,
                isShowBigText: $isShowBigText,
                bigTextPositionY: $bigTextPositionY
              })
            }
            .width('100%')
            .height('100%')
            .padding({ bottom: '30vp' })
          }
          if (this.isSmallVideoTimerVisible) {
            Column() {
              SmallVideoTimer({
                isResumeVideo: $isResumeVideo,
                iscContinueVideo: $iscContinueVideo
              })
            }
            .width('100%')
            .height('100%')
            .margin({ top: 12 })
          }
          if (this.isBigVideoTimerVisible) {
            Column() {
              BigVideoTimer({
                isSmallVideoTimerVisible: $isSmallVideoTimerVisible,
                isBigVideoTimerVisible: $isBigVideoTimerVisible,
                isResumeVideo: $isResumeVideo,
                iscContinueVideo: $iscContinueVideo
              })
            }
            .width('100%')
            .height('100%')
          }
        }
        .width('100%')
        .height('100%')
        //      .margin({ top: '50vp' })
        //            Text(this.previewImage)
        //                .fontSize(40)
        //                .textAlign(TextAlign.Center)
        //                .width('100%')
        //                .aspectRatio(this.aspectRatio)
      }
    }
    .height('100%')
    .aspectRatio(this.aspectRatio)
    .margin({ top: 0 })
    .backgroundColor('#000')
    .gesture(
    PinchGesture({
      fingers: 2, // 触发捏合的最少手指数, 最小为2指，最大为5指
      distance: 1 // 最小识别距离，单位为vp
    })
      .onActionStart((event: GestureEvent) => {
        CLog.info(`${this.TAG} Pinch start`)
        if (this.previewImage !== "MULTI") {
          this.isShowZoomText = true
          this.isPhotoZoomDetails = true
          this.baseZoom = this.zoomValue
          clearTimeout(this.pinchGestureTimer)
          clearTimeout(this.onTouchDownTimer)
        }
      })
      .onActionUpdate((event: GestureEvent) => {
        CLog.info(`${this.TAG} event.scale= ${event.scale}`)
        if (this.previewImage !== "MULTI") {
          this.onScaleUpdate(event.scale)
          this.isPinchGesture = true
        }
        CLog.info(`${this.TAG} event.scale= ${Number(event.scale.toFixed(1))}`)
      })
      .onActionEnd((event: GestureEvent) => {
        CLog.info(`${this.TAG} PreviewAreaLand PinchGestureEvent onActionEnd called`)
        if (this.previewImage !== "MULTI") {
          this.isPinchGesture = false
          clearTimeout(this.pinchGestureTimer)
          clearTimeout(this.onTouchDownTimer)
          this.pinchGestureTimer = setTimeout(() => {
            this.isShowZoomText = false
            this.isPhotoZoomDetails = false
          }, 3000)
          CLog.info(`${this.TAG} Pinch end= ${Number(event.scale.toFixed(1))}`)
        }
      })
    )
  }
}