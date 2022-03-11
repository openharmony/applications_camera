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

import {ShutterController} from './ShutterController.ets'
import {CameraService} from '../../../../../../../../../common/src/main/ets/default/Camera/CameraService'
import GetPixelMap from '../../../../../../../../../common/src/main/ets/default/Camera/GetPixelMap'
import router from "@system.router"

@Component
export struct ShutterButtonLand {
  @State icon: Resource = $r("app.media.ic_circled_filled")
  @Link @Watch("modeUpdate") previewImage: string
  width: number
  height: number
  type: ButtonType
  stateEffect: boolean
  shutterController = new ShutterController()
  private cameraService = CameraService.getInstance()
  getPixelMap = new GetPixelMap()
  @Link videoState: string
  @Link isThirdPartyCall: boolean
  @Link isStartVideo: boolean
  @Link isBigVideoTimerVisible: boolean
  @Link isSmallVideoTimerVisible: boolean
  @Link isResumeVideo: boolean
  @Link iscContinueVideo: boolean
  @Link isShowFlashBlack: boolean
  @State tempScale: number = 1
  @Link xComponentChangeFlag: boolean

  aboutToAppear() {
    this.shutterController.getParam()
    this.icon = this.shutterController.icon
    this.width = this.shutterController.width
    this.height = this.shutterController.height
    this.type = this.shutterController.type
    this.stateEffect = this.shutterController.stateEffect
  }

  modeUpdate() {
    if (this.previewImage === 'VIDEO') {
      this.icon = $r("app.media.take_video_normal")
    } else {
      this.icon = $r("app.media.ic_circled_filled")
    }
    this.videoState = 'beforeTakeVideo'
  }

  build() {
    if (this.videoState === 'beforeTakeVideo') {
      Stack({alignContent: Alignment.Center}) {
        if (this.previewImage === 'VIDEO'){
          Image(this.icon)
            .width(76)
            .aspectRatio(1)
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Up) {
                this.isBigVideoTimerVisible = true
                this.videoState = 'startTakeVideo'
                this.xComponentChangeFlag = !this.xComponentChangeFlag
                this.isStartVideo = true
              }
            })
        } else {
          Image($r("app.media.ic_circled")).fillColor(Color.White)
            .width(76)
            .aspectRatio(1)
          Image(this.icon)
            .width(54)
            .aspectRatio(1)
            .fillColor(Color.White)
            .scale({ x: this.tempScale, y: this.tempScale, z: this.tempScale })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                animateTo({
                  duration: 125,
                  curve: Curve.Sharp,
                  delay: 0
                }, () => {
                  this.tempScale = 0.85
                  console.info("Down Call Back")
                })
              } else if (event.type === TouchType.Up) {
                animateTo({
                  duration: 125,
                  curve: Curve.Sharp,
                  delay: 0,
                  onFinish: () => {
                    console.info(`this.onFinish= ${this.tempScale}`)
                    this.tempScale = 1
                    console.info("Up onFinish")
                  }
                }, () => {
                  this.tempScale = 1
                  console.info("Up Call Back")
                })
                this.isShowFlashBlack = true
                this.cameraService.takePicture(() => {
                  if (this.isThirdPartyCall) {
                    router.push({ uri: "pages/ThirdPreviewView" })
                  }
                })
              }
              console.info(`event.type=${event.type}`)
            })
        }
      }
      .width(76)
      .aspectRatio(1)
      .margin({ top: 48, bottom: 48 })
    } else {
      Column() {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          if (this.videoState === 'startTakeVideo') {
            Image($r('app.media.ic_video_recording'))
              .width(20)
              .aspectRatio(1)
              .fillColor(Color.White)
              .margin({ bottom: 16 })
              .onClick(() => {
                this.isResumeVideo = true
                this.iscContinueVideo = false
                this.cameraService.pauseVideo()
                this.videoState = 'pauseTakeVideo'
              })
          } else if (this.videoState === 'pauseTakeVideo') {
            Image($r('app.media.ic_video_pause'))
              .width(20)
              .aspectRatio(1)
              .fillColor('#ff0000')
              .margin({ bottom: 16 })
              .onClick(() => {
                this.isResumeVideo = false
                this.iscContinueVideo = true
                this.cameraService.resumeVideo()
                this.videoState = 'startTakeVideo'
              })
          }
          Image($r('app.media.ic_video_end'))
            .width(20)
            .aspectRatio(1)
            .fillColor(Color.White)
            .margin({ top: 16 })
            .onClick(() => {
              this.isResumeVideo = false
              this.iscContinueVideo = false
              this.isBigVideoTimerVisible = false
              this.isSmallVideoTimerVisible = false
              this.cameraService.stopVideo()
              this.cameraService.releaseVideo()
              this.videoState = 'beforeTakeVideo'
            })
        }
      }
      .width(56)
      .height(120)
      .borderRadius(28)
      .border({ width: 2, color: 0xffffff, style: BorderStyle.Solid })
      .margin({ top: 48, bottom: 48 })
    }
  }
}