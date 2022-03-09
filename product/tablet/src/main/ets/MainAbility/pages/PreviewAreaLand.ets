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

import {BigTextLand} from './BigTextLand.ets'
import {ZoomTextLand} from './ZoomTextLand.ets'
import {BigVideoTimer} from './BigVideoTimer.ets'
import {SmallVideoTimer} from './SmallVideoTimer.ets'
import {ShowFlashBlack
} from '../../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/animate/ShowFlashBlack.ets'
import {CameraService} from '../../../../../../../common/src/main/ets/default/Camera/CameraService.ets'
import {SettingsUtil} from '../../../../../../../common/src/main/ets/default/Utils/SettingsUtil.ets'

globalThis.cameraStart = ((surfaceId, previewImage) => {
  let cameraService = CameraService.getInstance()
  cameraService.startPreview(surfaceId, previewImage)
})

@Component
export struct PreviewAreaLand {
  mXComponentController: XComponentController = new XComponentController()
  @Link surfaceId: number
  private cameraService = CameraService.getInstance()
  private settingsUtil = SettingsUtil.getInstance()
  private getPhotoValue: Promise<string>
  private getVideoValue: Promise<string>
  @Link aspectRatio: number
  @Link @Watch("onpreviewImageUpdated") previewImage: string
  @Link state: any
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

  onpreviewImageUpdated(): void {
    this.isShowBigText = true
  }

  public onScaleUpdate(scale) {
    console.info(`onScaleUpdate called scale= ${scale}`)
    let tempZoom = 1.0;
    if (scale > 1) {
      tempZoom = this.baseZoom + scale - 1
    } else {
      tempZoom = this.baseZoom * scale
    }
    if (tempZoom - this.zoomValue >= 0.1 || tempZoom - this.zoomValue <= -0.1) {
      if (tempZoom >= this.minZoomRatio && tempZoom <= this.maxZoomRatio) {
        this.cameraService.setZoomRatio(tempZoom)
        this.zoomValue = tempZoom
        console.info(`this.zoomPercentage=== ${this.zoomPercentage}`)
        this.zoomPercentage = this.ratioToPercentage(this.zoomValue)
      }
    }
  }

  public ratioToPercentage(ratio) {
    return (Math.log2(ratio) - Math.log2(this.minZoomRatio)) / (Math.log2(this.maxZoomRatio) - Math.log2(this.minZoomRatio))
  }

  private async doCameraAction(surfaceId: number, previewImage: string) {
    if (this.curCameraPosition != this.cameraPosition) {
      if (this.cameraPosition === 'ORIGIN') {
        await this.cameraService.initCamera(surfaceId, previewImage)
      } else {
        await this.cameraService.switchCamera(surfaceId, this.cameraPosition)
      }
    } else if (this.curPreviewImage != this.previewImage) {
      await this.cameraService.changeMode_(previewImage, surfaceId)
    } else if (this.isStartVideo) {
      await this.cameraService.startVideo(surfaceId)
      this.isStartVideo = false
    } else {
      await this.cameraService.initCamera(surfaceId, previewImage)
    }
    this.curPreviewImage = this.previewImage
    this.curCameraPosition = this.cameraPosition
  }

  async aboutToAppear() {
    globalThis.releaseCamera = (() => {
      console.info('globalThis.releaseCamera called')
      let cameraService = CameraService.getInstance()
      cameraService.releaseVideo()
      cameraService.releaseCamera()
    })

    globalThis.onForegroundInit = (() => {
      console.info('globalThis.onForegroundInit called')
      this.xComponentChangeFlag = !this.xComponentChangeFlag
    })

    this.getPhotoValue = this.settingsUtil.getSettingValue('Aspect ratio')
    this.getVideoValue = this.settingsUtil.getSettingValue('Video resolution')
    Promise.all([this.getPhotoValue, this.getVideoValue]).then(values => {
      console.info("PreviewAreaLand getSettingValues = " + JSON.stringify(values))
      this.cameraService.setAspectRatio(values[0])
      this.cameraService.setVideoResolution(values[1])
      let getPreviewSize = this.cameraService.getPreviewSize(this.previewImage)
      console.info("PreviewAreaLand getPreviewSize = " + JSON.stringify(getPreviewSize))
      this.XcomponentWidth = getPreviewSize.width.toString() + 'px'
      this.XcomponentHeight = getPreviewSize.height.toString() + 'px'
      this.isShowPreview = true
    })

    this.minZoomRatio = 1
    this.maxZoomRatio = 6
    console.info("aboutToAppear end")
  }

  private aboutToDisappear(): void {
    console.info("previewAreaLand aboutToDisappear called")
    globalThis.releaseCamera()
  }

  private onBackPress(): void {
    console.info("previewAreaLand onBackPress called")
  }

  private onPageHide() {
    this.isStartVideo = false
  }

  public switchAnimationSec() {
    console.info("switchAnimationSec called")
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
      console.info(`btnSwitchSec callback btnSwitchSec= ${this.btnSwitchSec}`)
      this.scaleXSec = 1
    })
    animateTo({
      duration: 350,
      curve: 'cubic-bezier(0.21, 0.27, 0.20, 1.00)',
      delay: 0,
      onFinish: () => {
        console.info(`btnSwitchSec onFinish btnSwitchSec= ${this.btnSwitchSec}`)
        this.btnSwitchSec = false
        this.btnOpacity_sec = 0
        this.scaleXSec = 0.8
        this.rotateAngleSec = 80
        this.switchBackgroundAnimation()
      }
    }, () => {
      console.info(`btnSwitchSec callback btnSwitchSec= ${this.btnSwitchSec}`)
      this.rotateAngleSec = 0
    })
  }

  public switchAnimation() {
    console.info("switchAnimation called")
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
        console.info(`btnSwitch onFinish btnSwitch= ${this.btnSwitch}`)
        this.btnSwitch = false
        this.btnOpacity_first = 1
        this.scaleX = 1
        this.rotateAngle = 0
      }
    }, () => {
      console.info(`btnSwitch callback btnSwitch= ${this.btnSwitch}`)
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
                console.info(`XComponent onLoad cameraPosition: ${this.cameraPosition}`)
                console.info(`XComponent onLoad previewImage: ${this.previewImage}`)
                this.surfaceId = this.mXComponentController.getXComponentSurfaceId()
                console.info(`XComponent onLoad surfaceId: ${this.surfaceId}`)
                this.doCameraAction(this.surfaceId, this.previewImage)
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
                console.info(`XComponent onLoad cameraPosition: ${this.cameraPosition}`)
                console.info(`XComponent onLoad previewImage: ${this.previewImage}`)
                this.surfaceId = this.mXComponentController.getXComponentSurfaceId()
                console.info(`XComponent onLoad surfaceId: ${this.surfaceId}`)
                this.doCameraAction(this.surfaceId, this.previewImage)
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

          if (this.isShowFlashBlack) {
            ShowFlashBlack({
              XcomponentWidth: $XcomponentWidth,
              XcomponentHeight: $XcomponentHeight,
              isShowFlashBlack: $isShowFlashBlack
            })
          }

          if (this.isShowZoomText) {
            Stack({ alignContent: Alignment.Top }) {
              ZoomTextLand({ zoomValue: $zoomValue })
            }.width('100%')
            .height('96')
          }

          if (this.isShowBigText) {
            Stack({ alignContent: Alignment.BottomStart }) {
              BigTextLand({
                previewImage: $previewImage,
                isShowBigText: $isShowBigText
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
      }
    }
    .height('100%')
    .aspectRatio(this.aspectRatio)
    .margin({ top: 0 })
    .backgroundColor('#000')
    .gesture(
    PinchGesture({
      fingers: 2,
      distance: 0.5
    })
      .onActionStart((event: PinchGestureEvent) => {
        console.info('Pinch start')
        this.isShowZoomText = true
        this.isPhotoZoomDetails = true
        this.baseZoom = this.zoomValue
        clearTimeout(this.pinchGestureTimer)
        clearTimeout(this.onTouchDownTimer)
      })
      .onActionUpdate((event: PinchGestureEvent) => {
        console.info(`event.scale= ${event.scale}`)
        this.onScaleUpdate(event.scale)
        this.isPinchGesture = true
        console.info(`event.scale= ${Number(event.scale.toFixed(1))}`)
      })
      .onActionEnd((event: PinchGestureEvent) => {
        this.isPinchGesture = false
        clearTimeout(this.pinchGestureTimer)
        clearTimeout(this.onTouchDownTimer)
        this.pinchGestureTimer = setTimeout(() => {
          this.isShowZoomText = false
          this.isPhotoZoomDetails = false
        }, 3000)
        console.info(`Pinch end= ${Number(event.scale.toFixed(1))}`)
      })
    )
  }
}