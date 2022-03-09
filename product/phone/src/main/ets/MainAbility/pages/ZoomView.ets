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
  @State offsetXVideo: number = 0
  @State offsetXVideoInit: number = 0
  @State offsetXPhoto: number = 0
  @State offsetXPhotoDetails: number = 0
  @State scrollPhotoBox: number = 32
  @State scrollVideoBox: number = 32
  @State scrollDetailsBox: number = 32
  @State isLongPress: boolean = false
  @State isPhotoLongPress: boolean = false
  @Link isPhotoZoomDetails: boolean
  @State arrayList: String[] = ['1', '2', '3', '4', '5', '6']
  @State isPhotoZoom: boolean = false
  @Link @Watch('previewMode') previewImage: string
  @State isPressScrollDetailPhotoButton: boolean = false
  @State isPressScrollDetailVideoButton: boolean = false
  @State defaultPhotoList: Number[] = []
  @State detailPhotoList: Number[] = []
  @State detailVideoList: Number[] = []
  @Link isShowZoomText: boolean
  @Link zoomValue: number
  @State photoZoomDetailsTimer: number = 0
  @Link @Watch("zoomPercentageUpdate") zoomPercentage: number
  @State detailPhotoWidth: number = 0
  @State detailVideoWidth: number = 0
  @State photoScrollBox: boolean = true
  @Link @Watch("isPinchGestureUpdate") isPinchGesture: boolean
  @State photoZoomWidth: number = 180
  @Link maxZoomRatio: number
  @Link minZoomRatio: number
  @State offsetXPhotoDetailsInit: number = 0
  @Link onTouchDownTimer: number
  @Link pinchGestureTimer: number;
  @State opacityZoomPhoto: number = 1;
  @State previewImageAnimate: string = ''
  @Link videoState: string
  @Link cameraPosition: string

  public aboutToAppear() {
    console.log("previewImage=11= C =" + this.previewImage)
    display.getDefaultDisplay().then((dis) => {
      console.info(`dis.height= ${dis.height}`)
      let detailPhotoSpot = Math.floor(286 / 5.5)
      let detailVideoSpot = Math.floor(307 / 5.5)
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
      this.detailPhotoWidth = detailPhotoSpot * 5.5 + 10 + 16 * 3
      console.info(`this.detailPhotoWidth= ${this.detailPhotoWidth}`)
      this.detailVideoWidth = detailVideoSpot * 5.5 + 16 * 3
      console.info(`this.detailVideoWidth= ${this.detailVideoWidth}`)
      this.offsetXPhotoDetails = 0
      this.offsetXVideo = 0
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
        this.zoomValue = 1
        this.isPhotoZoomDetails = false
        this.offsetXVideo = 0
        this.offsetXPhotoDetails = 0
        this.zoomPercentage = 0
        animateTo({ duration: 200,
          delay: 0,
          curve: Curve.Sharp }, () => {
          this.opacityZoomPhoto = 1
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
        this.offsetXPhotoDetails = this.zoomPercentage * (this.detailPhotoWidth - 51)
        console.info(`this.offsetXPhotoDetails= ${this.offsetXPhotoDetails}`)
      } else if (this.previewImage === "VIDEO") {
        this.offsetXVideo = this.zoomPercentage * (this.detailVideoWidth - 51)
      }
    }
  }

  public scrollBoxPosition() {
    console.info("this.detailPhotoWidth11=" + this.detailPhotoWidth)
    console.info("this.photoZoomWidth11=" + this.photoZoomWidth)
    console.info("this.zoomPercentage11=" + this.zoomPercentage)
    let offsetXPhotoOutSide = (this.detailPhotoWidth / 2 - this.photoZoomWidth / 2 - 7) + this.zoomPercentage * (this.photoZoomWidth - 32)
    return offsetXPhotoOutSide
  }

  public isPinchGestureUpdate() {
    if (this.previewImage === "PHOTO") {
      this.isPressScrollDetailPhotoButton = this.isPinchGesture ? true : false
    } else if (this.previewImage === "VIDEO") {
      this.isPressScrollDetailVideoButton = this.isPinchGesture ? true : false
    }
  }

  public getZoomPhotoPosition() {
    this.offsetXPhoto = this.zoomPercentage * (this.photoZoomWidth - 32)
  }

  public ratioToPercentage(ratio) {
    return (Math.log2(ratio) - Math.log2(this.minZoomRatio)) / (Math.log2(this.maxZoomRatio) - Math.log2(this.minZoomRatio))
  }

  public onPercentageUpdate(percentage) {
    console.info(`onPercentageUpdate called percentage= ${percentage}`)
    let tempZoom = this.percentageToRatio(percentage)
    console.info(`onPercentageUpdate called tempZoom= ${tempZoom}`)
    if ((tempZoom - this.zoomValue >= 0.1) || (tempZoom - this.zoomValue <= -0.1)) {
      if (tempZoom >= this.minZoomRatio && tempZoom <= this.maxZoomRatio) {
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
        if ((this.previewImageAnimate === "PHOTO" || this.previewImageAnimate === "MULTI") || this.videoState === "beforeTakeVideo" && this.cameraPosition != "FRONT") {
          Stack() {
            Flex({
              direction: FlexDirection.Row,
              alignItems: ItemAlign.Center
            }) {
              Column() {
                Flex({
                  direction: FlexDirection.Row,
                  alignItems: ItemAlign.Center,
                  justifyContent: FlexAlign.Center
                }) {
                  if (this.isPressScrollDetailPhotoButton) {
                    Column() {
                    }.width(5).height(5).borderRadius(2.5).backgroundColor('#fff')
                  } else {
                    Text(`${Number(this.zoomValue.toFixed(1)) / 1}x`).fontColor('#fff').fontSize('10fp').fontWeight(700)
                  }
                }.width('100%').height('100%')
              }
              .width(this.scrollDetailsBox)
              .height(this.scrollDetailsBox)
              .backgroundColor('#000')
              .borderRadius(this.scrollDetailsBox / 2)
              .border({ width: 2, color: 0xffffff, style: BorderStyle.Solid })
              .translate({ x: this.isPhotoZoomDetails ? this.offsetXPhotoDetails : this.scrollBoxPosition() })
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
                direction: PanDirection.Horizontal
              })
                .onActionStart((event: PanGestureEvent) => {
                  console.info('pan start')
                  this.isShowZoomText = true
                  this.isPhotoZoomDetails = true
                  this.offsetXPhotoDetailsInit = this.offsetXPhotoDetails
                  clearTimeout(this.onTouchDownTimer)
                  clearTimeout(this.pinchGestureTimer)
                })
                .onActionUpdate((event: PanGestureEvent) => {
                  console.info('pan update')
                  this.scrollDetailsBox = 36
                  console.info("this.offsetXPhotoDetailsInit=" + this.offsetXPhotoDetailsInit + "event.offsetX=" + event.offsetX)
                  if ((this.offsetXPhotoDetailsInit + event.offsetX) < 0) {
                    this.offsetXPhotoDetails = 0
                    console.info("offsetXPhotoDetails start" + this.offsetXPhotoDetails)
                  } else if ((this.offsetXPhotoDetailsInit + event.offsetX) > (this.detailPhotoWidth - 51)) {
                    this.offsetXPhotoDetails = this.detailPhotoWidth - 51
                    console.info("offsetXPhotoDetails end" + this.offsetXPhotoDetails)
                  } else {
                    this.offsetXPhotoDetails = this.offsetXPhotoDetailsInit + event.offsetX
                    console.info("this.offsetXPhotoDetails scroll" + this.offsetXPhotoDetails)
                  }
                  this.zoomPercentage = this.offsetXPhotoDetails / (this.detailPhotoWidth - 51)
                  console.info("this.offsetXPhotoDetails2222=" + this.offsetXPhotoDetails + "this.detailPhotoWidth=" + this.detailPhotoWidth + "this.zoomPercentage=" + this.zoomPercentage)
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
            }
            .width(this.detailPhotoWidth)
            .height(50)
            .padding({ left: '10vp' })
            .margin({ top: '51vp' })
            .zIndex(2)

            if (this.isPhotoZoomDetails) {
              Column() {
                Flex({
                  direction: FlexDirection.Row,
                  alignItems: ItemAlign.Center,
                  justifyContent: FlexAlign.SpaceBetween
                }) {
                  Text('1x').fontSize('11fp').fontWeight(700).fontColor('#fff')
                    .rotate({
                      x: 0,
                      y: 0,
                      z: 90,
                      centerX: '50%',
                      centerY: '50%',
                      angle: 90
                    })
                  Text('6x').fontSize('11fp').fontWeight(700).fontColor('#fff')
                    .rotate({
                      x: 0,
                      y: 0,
                      z: 90,
                      centerX: '50%',
                      centerY: '50%',
                      angle: 90
                    })
                }.width('100%').height(32)
                .margin({ top: '10vp', bottom: '8vp' })
                .padding({ left: '29vp', right: '29vp' })

                Row() {
                  Column() {
                  }
                  .width(3)
                  .height(3)
                  .borderRadius(1.5)
                  .backgroundColor('#ffffff')
                  .margin({ right: '4vp' })

                  ForEach(this.detailPhotoList, item => {
                    Column() {
                    }
                    .width(1.5)
                    .height(1.5)
                    .borderRadius(0.75)
                    .backgroundColor('#fff')
                    .opacity(0.2)
                    .margin({ right: '4vp' })
                  })
                  Column() {
                  }.width(3).height(3).borderRadius(1.5).backgroundColor('#ffffff')
                }.width('100%').height(50).padding({ left: '32vp', right: '32vp' })
              }.width('100%').height('100%').zIndex(1)
            } else {
              Row() {
                Column() {

                }
                .width(3)
                .height(3)
                .borderRadius(1.5)
                .backgroundColor('#ffffff')
                .margin({ right: '4vp' })

                ForEach(this.defaultPhotoList, item => {
                  Column() {

                  }
                  .width(1.5)
                  .height(1.5)
                  .borderRadius(0.75)
                  .backgroundColor('#ffffff')
                  .opacity(0.2)
                  .margin({ right: '4vp' })
                })
                Column() {

                }.width(3).height(3).borderRadius(1.5).backgroundColor('#ffffff')
              }
              .width(this.photoZoomWidth)
              .height(50)
              .margin({ top: '51vp' })
              .zIndex(1)
              .padding({ left: '16vp' })
            }
          }.width(360).height('100%')
        } else if (this.previewImageAnimate === "VIDEO" && this.cameraPosition != "FRONT" && this.videoState !== "beforeTakeVideo") {
          Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
            Text('-')
              .fontSize('24fp')
              .fontColor('#fff')
              .height('100%')
              .textAlign(TextAlign.Center)
              .onClick(() => {
                if (Number(this.offsetXVideo.toFixed(1)) < (this.detailVideoWidth - 51)) {
                  this.offsetXVideo = this.offsetXVideo - (this.detailVideoWidth - 51) * 0.1
                  this.zoomPercentage = this.zoomPercentage - 0.1
                  this.onPercentageUpdate(this.zoomPercentage)
                }
              })
            Stack() {
              Row() {
                ForEach(this.detailVideoList, item => {
                  Column() {
                  }
                  .width(1.5)
                  .height(1.5)
                  .borderRadius(0.75)
                  .backgroundColor('#ffffff')
                  .opacity(0.2)
                  .margin({ right: '4vp' })
                })
              }.width('100%').padding({ left: 16, right: 12 })

              Flex({
                direction: FlexDirection.Row,
                alignItems: ItemAlign.Center
              }) {
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
                .translate({ x: this.offsetXVideo })
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
                  direction: PanDirection.Horizontal
                })
                  .onActionStart((event: PanGestureEvent) => {
                    console.info('pan start')
                    this.isShowZoomText = true
                    this.offsetXVideoInit = this.offsetXVideo
                  })
                  .onActionUpdate((event: PanGestureEvent) => {
                    console.info('pan update')
                    this.scrollDetailsBox = 36
                    if ((this.offsetXVideoInit + event.offsetX) < 0) {
                      this.offsetXVideo = 0
                    } else if ((this.offsetXVideoInit + event.offsetX) > (this.detailVideoWidth - 51)) {
                      this.offsetXVideo = this.detailVideoWidth - 51
                    } else {
                      this.offsetXVideo = this.offsetXVideoInit + event.offsetX
                    }
                    this.zoomPercentage = this.offsetXVideo / (this.detailVideoWidth - 51)
                    this.onPercentageUpdate(this.zoomPercentage)
                  })
                  .onActionEnd(() => {
                    this.scrollVideoBox = 32
                    this.isShowZoomText = false
                    console.info('Pan end')
                  })
                )
              }.width('100%').height('100%')
            }.width(this.detailVideoWidth).height('100%')

            Text('+')
              .fontSize('24fp')
              .fontColor('#fff')
              .height('100%')
              .textAlign(TextAlign.Center)
              .onClick(() => {
                if (Number(this.offsetXVideo.toFixed(1)) < (this.detailVideoWidth - 51)) {
                  this.offsetXVideo = this.offsetXVideo + (this.detailVideoWidth - 51) * 0.1
                  this.zoomPercentage = this.zoomPercentage + 0.1
                  this.onPercentageUpdate(this.zoomPercentage)
                }
              })
          }.width(360).height('100%')
        }
      }.width('100%').height('100%')
    }.width('100%')
    .height(100)
    .opacity(this.opacityZoomPhoto)
  }
}