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
import {CameraService} from '../../../../../../../common/src/main/ets/default/Camera/CameraService.ets'

@Component
export struct ZoomView {
  private cameraService = CameraService.getInstance()
  @State offsetYVideo: number = 0
  @State offsetYVideoInit: number = 0
  @State offsetYPhoto: number = 0
  @State offsetYPhotoDetails: number = 0
  @State scrollPhotoBox: number = 32
  @State scrollVideoBox: number = 32
  @State scrollDetailsBox: number = 32
  @State isLongPress: boolean = false
  @State isPhotoLongPress: boolean = false
  @Link isPhotoZoomDetails: boolean
  @State arrayList: String[] = ['1', '2', '3', '4', '5', '6']
  @State isPhotoZoom: boolean = false
  @Link @Watch('previewMode') previewImage: string
  @Link cameraPosition: string
  @State isPressScrollDetailPhotoButton: boolean = false
  @State isPressScrollDetailVideoButton: boolean = false
  @State defaultPhotoList: Number[] = []
  @State detailPhotoList: Number[] = []
  @State detailVideoList: Number[] = []
  @Link isShowZoomText: boolean
  @Link zoomValue: number
  @State photoZoomDetailsTimer: number = 0
  @Link @Watch("zoomPercentageUpdate") zoomPercentage: number
  @State detailPhotoHeight: number = 0
  @State detailVideoHeight: number = 0
  @State photoScrollBox: boolean = true
  @Link @Watch("isPinchGestureUpdate") isPinchGesture: boolean
  @State photoZoomHeight: number = 180
  @Link maxZoomRatio: number
  @Link minZoomRatio: number
  @State offsetYPhotoDetailsInit: number = 0
  @Link onTouchDownTimer: number
  @Link pinchGestureTimer: number;
  @State opacityZoomPhoto: number = 1;
  @State previewImageAnimate: string = ''
  @Link videoState: string

  public aboutToAppear() {
    console.log("previewImage=11= C =" + this.previewImage)
    display.getDefaultDisplay().then((dis) => {
      console.info(`dis.height= ${dis.height}`)
      let detailPhotoSpot = Math.floor(286 / 5.5)
      let detailVideoSpot = Math.floor(284 / 5.5)
      let defaultPhotoSpot = Math.floor(138 / 5.5)
      console.info(`detailPhotoSpot= ${detailPhotoSpot}`)
      for (var i = 0; i < defaultPhotoSpot; i++) {
        this.defaultPhotoList.push(i)
      }
      for (var i = 0; i < detailPhotoSpot; i++) {
        this.detailPhotoList.push(i)
      }
      for (var j = 0; j < detailVideoSpot; j++) {
        this.detailVideoList.push(i)
      }
      this.detailPhotoHeight = detailPhotoSpot * 5.5 + 10 + 16 * 3
      console.info(`this.detailPhotoHeight= ${this.detailPhotoHeight}`)
      this.detailVideoHeight = detailVideoSpot * 5.5 + 16 * 3
      console.info(`this.detailVideoHeight= ${this.detailVideoHeight}`)
      this.offsetYPhotoDetails = this.detailPhotoHeight - 51
      this.offsetYVideo = this.detailVideoHeight - 51;
      this.previewImageAnimate = this.previewImage
    });
  }

  previewMode() {
    console.log(`previewImage=11= B = ${this.previewImage}`)
    console.log(`previewImageAnimate=11= B = ${this.previewImageAnimate}`)
    animateTo({ duration: 200,
      delay: 0,
      curve: Curve.Sharp,
      onFinish: () => {
        console.log(`previewImageAnimate=22= ${this.previewImageAnimate}`)
        this.previewImageAnimate = this.previewImage;
        animateTo({ duration: 200,
          delay: 0,
          curve: Curve.Sharp }, () => {
          this.opacityZoomPhoto = 1
          this.zoomValue = 1
          this.offsetYPhotoDetails = this.detailPhotoHeight - 51
          this.offsetYVideo = this.detailVideoHeight - 51
          this.zoomPercentage = 0
        })
      }
    }, () => {
      this.opacityZoomPhoto = 0
    })
  }

  public zoomPercentageUpdate() {
    console.info("zoomPercentageUpdate called")
    if (this.isPinchGesture) {
      console.info("zoomPercentageUpdate isPinchGesture")
      if (this.previewImage === "PHOTO") {
        console.info(`zoomPercentageUpdate mode=photo ${this.zoomPercentage}`)
        this.offsetYPhotoDetails = (1 - this.zoomPercentage) * (this.detailPhotoHeight - 51)
        console.info(`this.offsetYPhotoDetails= ${this.offsetYPhotoDetails}`)
      } else if (this.previewImage === "VIDEO") {
        this.offsetYVideo = (1 - this.zoomPercentage) * (this.detailVideoHeight - 51)
      }
    }
  }

  public scrollBoxPosition() {
    let offsetYPhotoOutSide = (this.detailPhotoHeight / 2 - this.photoZoomHeight / 2 - 7) + (1 - this.zoomPercentage) * (this.photoZoomHeight - 32)
    return offsetYPhotoOutSide
  }

  public isPinchGestureUpdate() {
    if (this.previewImage === "PHOTO") {
      this.isPressScrollDetailPhotoButton = this.isPinchGesture ? true : false
    } else if (this.previewImage === "VIDEO") {
      this.isPressScrollDetailVideoButton = this.isPinchGesture ? true : false
    }
  }

  public getZoomPhotoPosition() {
    this.offsetYPhoto = (1 - this.zoomPercentage) * (this.photoZoomHeight - 32)
  }

  public ratioToPercentage(ratio) {
    return (Math.log2(ratio) - Math.log2(this.minZoomRatio)) / (Math.log2(this.maxZoomRatio) - Math.log2(this.minZoomRatio))
  }

  public onPercentageUpdate(percentage) {
    console.info(`onPercentageUpdate called percentage= ${percentage}`)
    let tempZoom = this.percentageToRatio(percentage)

    if ((tempZoom - this.zoomValue >= 0.1) || (tempZoom - this.zoomValue <= -0.1)) {
      if (tempZoom >= this.minZoomRatio && tempZoom <= this.maxZoomRatio) {
        this.cameraService.setZoomRatio(tempZoom)
        this.zoomValue = tempZoom
      }
    }
  }

  public percentageToRatio(percentage) {
    return Math.pow(2, Math.log2(this.minZoomRatio) + percentage * (Math.log2(this.maxZoomRatio) - Math.log2(this.minZoomRatio)))
  }

  build() {
    Column() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        if ((this.previewImageAnimate == "PHOTO" || this.previewImageAnimate == "MULTI" || this.videoState === "beforeTakeVideo") && this.cameraPosition != "FRONT") {
          Stack() {
            if (this.isPhotoZoomDetails) {
              Flex({
                direction: FlexDirection.Row,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
              }) {
                Flex({
                  direction: FlexDirection.Column,
                  alignItems: ItemAlign.Center,
                  justifyContent: FlexAlign.SpaceBetween
                }) {
                  Column() {
                    Text('6x').fontSize('11fp').fontWeight(700).fontColor('#fff')
                  }.width('100%')

                  Column() {
                    Text('1x').fontSize('11fp').fontWeight(700).fontColor('#fff')
                  }.width('100%')
                }.width(32).height('100%')
                .margin({ left: '10vp', right: '8vp' })
                .padding({ top: '29vp', bottom: '29vp' })

                Stack({ alignContent: Alignment.TopStart }) {
                  Column() {
                    Column() {
                    }
                    .width(3)
                    .height(3)
                    .borderRadius(1.5)
                    .backgroundColor('#ffffff')
                    .margin({ bottom: '4vp' })

                    ForEach(this.detailPhotoList, item => {
                      Column() {
                      }
                      .width(1.5)
                      .height(1.5)
                      .borderRadius(0.75)
                      .backgroundColor('#ffffff')
                      .opacity(0.2)
                      .margin({ bottom: '4vp' })
                    })
                    Column() {
                    }.width(3).height(3).borderRadius(1.5).backgroundColor('#ffffff')
                  }.width(50).height('100%')
                }.width('100%').height('100%').padding({ top: '32vp', bottom: '32vp' })
              }.width('100%').height('100%')
            } else {
              Stack({ alignContent: Alignment.TopStart }) {
                Column() {
                  Column() {

                  }
                  .width(3)
                  .height(3)
                  .borderRadius(1.5)
                  .backgroundColor('#ffffff')
                  .margin({ bottom: '4vp' })

                  ForEach(this.defaultPhotoList, item => {
                    Column() {

                    }
                    .width(1.5)
                    .height(1.5)
                    .borderRadius(0.75)
                    .backgroundColor('#ffffff')
                    .opacity(0.2)
                    .margin({ bottom: '4vp' })
                  })
                  Column() {

                  }.width(3).height(3).borderRadius(1.5).backgroundColor('#ffffff')
                }.width('100%').height('100%').padding({ top: '16vp' })
              }.width(50).height(this.photoZoomHeight).margin({ left: '51vp' })
            }
            Stack({ alignContent: Alignment.TopStart }) {
              Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Start
              }) {
                Column() {
                  Flex({
                    direction: FlexDirection.Column,
                    alignItems: ItemAlign.Center,
                    justifyContent: FlexAlign.Center
                  }) {
                    if (this.isPressScrollDetailPhotoButton) {
                      Column() {
                      }.width(5).height(5).borderRadius(2.5).backgroundColor('#fff')
                    } else {
                      Text(`${Number(this.zoomValue.toFixed(1)) / 1}x`)
                        .fontColor('#fff')
                        .fontSize('10fp')
                        .fontWeight(700)
                    }
                  }.width('100%').height('100%')
                }
                .width(this.scrollDetailsBox)
                .height(this.scrollDetailsBox)
                .backgroundColor('#000')
                .borderRadius(this.scrollDetailsBox / 2)
                .border({ width: 2, color: 0xffffff, style: BorderStyle.Solid })
                .translate({ y: this.isPhotoZoomDetails ? this.offsetYPhotoDetails : this.scrollBoxPosition() })
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.isPressScrollDetailPhotoButton = true
                    this.isShowZoomText = true
                  } else if (event.type === TouchType.Up) {
                    this.isPressScrollDetailPhotoButton = false
                    this.isShowZoomText = false
                    clearTimeout(this.onTouchDownTimer)
                    clearTimeout(this.pinchGestureTimer)
                    this.onTouchDownTimer = setTimeout(() => {
                      this.isPhotoZoomDetails = false
                      this.getZoomPhotoPosition()
                    }, 3000)
                  }
                })
                .gesture(
                GestureGroup(GestureMode.Parallel,
                LongPressGesture({ repeat: true })
                  .onAction((event: LongPressGestureEvent) => {
                    if (event.repeat) {
                      this.isPhotoZoomDetails = true
                      clearTimeout(this.onTouchDownTimer)
                      clearTimeout(this.pinchGestureTimer)
                    }
                    console.log('LongPress onAction')
                  })
                  .onActionEnd(() => {
                    console.log('LongPress end')
                  }),
                PanGesture({
                  fingers: 1,
                  distance: 1,
                  direction: PanDirection.Vertical
                })
                  .onActionStart((event: PanGestureEvent) => {
                    console.info('pan start')
                    this.isShowZoomText = true
                    this.isPhotoZoomDetails = true
                    this.offsetYPhotoDetailsInit = this.offsetYPhotoDetails
                    clearTimeout(this.onTouchDownTimer)
                    clearTimeout(this.pinchGestureTimer)
                  })
                  .onActionUpdate((event: PanGestureEvent) => {
                    console.info('pan update')
                    this.scrollDetailsBox = 36
                    if ((this.offsetYPhotoDetailsInit + event.offsetY) < 0) {
                      this.offsetYPhotoDetails = 0
                    } else if ((this.offsetYPhotoDetailsInit + event.offsetY) > (this.detailPhotoHeight - 51)) {
                      this.offsetYPhotoDetails = this.detailPhotoHeight - 51
                    } else {
                      this.offsetYPhotoDetails = this.offsetYPhotoDetailsInit + event.offsetY
                    }
                    this.zoomPercentage = 1 - (this.offsetYPhotoDetails / (this.detailPhotoHeight - 51))
                    this.onPercentageUpdate(this.zoomPercentage)
                  })
                  .onActionEnd(() => {
                    this.scrollDetailsBox = 32
                    this.isShowZoomText = false
                    console.info('Pan end')
                  })
                )
                  .onCancel(() => {
                    console.log('sequence gesture canceled')
                  })
                )
              }.width('100%').height('100%')
            }
            .width(50)
            .height('100%')
            .padding({ top: 16, bottom: 16 })
            .margin({ left: 51 })
          }.width('100%').height(360)
        } else if (this.previewImageAnimate == "VIDEO" && this.cameraPosition != "FRONT" && this.videoState !== "beforeTakeVideo") {
          Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
            Text('+')
              .fontSize('24fp')
              .fontColor('#fff')
              .width('100%')
              .textAlign(TextAlign.Center)
              .onClick(() => {
                if (Number(this.offsetYVideo.toFixed(1)) > 0) {
                  this.offsetYVideo = this.offsetYVideo - (this.detailVideoHeight - 51) * 0.1
                  this.zoomPercentage = this.zoomPercentage + 0.1
                  this.onPercentageUpdate(this.zoomPercentage)
                }
              })
            Stack({ alignContent: Alignment.TopStart }) {
              Column() {
                ForEach(this.detailVideoList, item => {
                  Column() {
                  }
                  .width(1.5)
                  .height(1.5)
                  .borderRadius(0.75)
                  .backgroundColor('#ffffff')
                  .opacity(0.2)
                  .margin({ bottom: '4vp' })
                })
              }.width('100%').padding({ top: '16vp', bottom: '12vp' })

              Column() {
                Column() {
                  Flex({
                    direction: FlexDirection.Column,
                    alignItems: ItemAlign.Center,
                    justifyContent: FlexAlign.Center
                  }) {
                    if (this.isPressScrollDetailVideoButton) {
                      Column() {
                      }.width(5).height(5).borderRadius(2.5).backgroundColor('#fff')
                    } else {
                      Text(`${Number(this.zoomValue.toFixed(1)) / 1}x`)
                        .fontColor('#fff')
                        .fontSize('10fp')
                        .fontWeight(700)
                    }
                  }.width('100%').height('100%')
                }
                .width(this.scrollVideoBox)
                .height(this.scrollVideoBox)
                .backgroundColor('#000')
                .borderRadius(this.scrollVideoBox / 2)
                .border({ width: 2, color: 0xffffff, style: BorderStyle.Solid })
                .translate({ y: this.offsetYVideo })
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.isPressScrollDetailVideoButton = true
                    this.isShowZoomText = true
                  } else if (event.type === TouchType.Up) {
                    this.isPressScrollDetailVideoButton = false
                    this.isShowZoomText = false
                  }
                })
                .gesture(
                PanGesture({
                  fingers: 1,
                  distance: 1,
                  direction: PanDirection.Vertical
                })
                  .onActionStart((event: PanGestureEvent) => {
                    console.info('pan start')
                    this.isShowZoomText = true
                    this.offsetYVideoInit = this.offsetYVideo
                  })
                  .onActionUpdate((event: PanGestureEvent) => {
                    console.info('pan update')
                    this.scrollDetailsBox = 36
                    if ((this.offsetYVideoInit + event.offsetY) < 0) {
                      this.offsetYVideo = 0
                    } else if ((this.offsetYVideoInit + event.offsetY) > (this.detailVideoHeight - 51)) {
                      this.offsetYVideo = this.detailVideoHeight - 51
                    } else {
                      this.offsetYVideo = this.offsetYVideoInit + event.offsetY
                    }
                    this.zoomPercentage = 1 - (this.offsetYVideo / (this.detailVideoHeight - 51))
                    this.onPercentageUpdate(this.zoomPercentage)
                  })
                  .onActionEnd(() => {
                    this.scrollVideoBox = 32
                    this.isShowZoomText = false
                    console.info('Pan end')
                  })
                )
              }.width('100%').height('100%')
            }.width('100%').height(this.detailVideoHeight)

            Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
              Text('-').fontSize('24fp').fontColor('#fff')
                .rotate({
                  x: 0,
                  y: 0,
                  z: 90,
                  centerX: '50%',
                  centerY: '50%',
                  angle: 90
                })
                .onClick(() => {
                  if (Number(this.offsetYVideo.toFixed(1)) < (this.detailVideoHeight - 51)) {
                    this.offsetYVideo = this.offsetYVideo + (this.detailVideoHeight - 51) * 0.1
                    this.zoomPercentage = this.zoomPercentage - 0.1
                    this.onPercentageUpdate(this.zoomPercentage)
                  }
                })
            }.width('100%')
          }.width('100%').height(360)
        }
      }.width('100%')
      .height('100%')
    }.width(100)
    .margin({ right: 144 })
    .opacity(this.opacityZoomPhoto)
  }
}