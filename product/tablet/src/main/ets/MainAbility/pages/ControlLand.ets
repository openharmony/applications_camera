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

import {ModeConfig} from '../common/ModeConfig.ets'
import getStore from '../store.ets'
import {changePreviewSize} from '../../../../../../../common/src/main/ets/default/redux/actions/ModeChange.ets'
import {CameraService} from '../../../../../../../common/src/main/ets/default/Camera/CameraService.ets';

let changeModeState = (state) => {
  return {
    number: state.ModeChangeReducer.number,
    res: state.ModeChangeReducer.res
  }
}

let changeModeDispatch = (dispatch) => {
  return {
    onclickPhoto: () => {
      console.info('onclickPhoto1')
      dispatch(changePreviewSize(154))
      console.info('onclickPhoto2')
    },
    onclickVideo: () => dispatch(changePreviewSize(0))
  }
}


@Component
export struct ControlLand {
  scroller: Scroller = new Scroller()
  private cameraService = CameraService.getInstance()
  @Link aspectRatio: number
  @Link previewImage: string
  private modeConfig: ModeConfig = new ModeConfig()
  @Link state: any
  private connect: any
  @State scrollValue: number = 0
  @State photoFontWeight: FontWeight = FontWeight.Bold
  @State videoFontWeight: FontWeight = FontWeight.Regular
  @State multiFontWeight: FontWeight = FontWeight.Regular
  @Link isThirdPartyCall: boolean
  @Link action: string
  @Link isSmallVideoTimerVisible: boolean
  @Link isBigVideoTimerVisible: boolean
  @Link cameraPosition: string
  @Link XcomponentWidth: string
  @Link XcomponentHeight: string
  @State opacityValue: number = 1
  @Link curPreviewImage: string
  @Link xComponentChangeFlag: boolean
  @State isScrollToMulti: boolean = false

  private aboutToAppear() {
    let startWant = globalThis.cameraAbilityWant
    console.info('Camera MainAbility onCreate uri: ' + startWant.uri)

    this.connect = getStore().connect(changeModeState, changeModeDispatch)(this.state)

    if (startWant.action === 'ohos.want.action.imageCapture') {
      console.info('wantConstant.ACTION_IMAGE_CAPTURE called')
      this.isThirdPartyCall = true
      this.previewImage = 'PHOTO'
    } else if (startWant.action === 'ohos.want.action.videoCapture') {
      console.info('wantConstant.ACTION_VIDEO_CAPTURE called')
      this.isThirdPartyCall = true
      this.previewImage = 'VIDEO'
    }
  }

  private aboutToDisappear() {
    this.connect().destroy()
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Row() {
        if (this.isThirdPartyCall || this.action === 'capture') {
          Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
            Text($r('app.string.photo_mode'))
              .width(64)
              .fontSize('14fp')
              .fontColor(Color.White)
              .textAlign(TextAlign.End)
              .fontWeight(FontWeight.Bold)
          }
          .width(64)
          .height('100%')
        } else if (this.action === 'video') {
          Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
            Text($r('app.string.video_mode'))
              .width(64)
              .fontSize('14fp')
              .fontColor(Color.White)
              .textAlign(TextAlign.End)
              .fontWeight(FontWeight.Bold)
          }
          .width(64)
          .height('100%')
        } else {
          Stack({ alignContent: Alignment.TopStart }) {
            Scroll(this.scroller) {
              List() {
                ListItem() {
                }
                .width('100%').height(28)

                if (this.isScrollToMulti) {
                  ListItem() {
                  }
                  .width('100%').height(30)
                }
                ListItem() {
                  Text($r('app.string.multi_mode'))
                    .width('100%')
                    .height('100%')
                    .fontSize('14fp')
                    .fontColor(Color.White)
                    .textAlign(TextAlign.End)
                    .onClick(async (event: ClickEvent) => {
                      this.photoFontWeight = FontWeight.Regular
                      this.videoFontWeight = FontWeight.Regular
                      this.multiFontWeight = FontWeight.Bold
                      this.isScrollToMulti = true
                      this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
                      this.aspectRatio = 4 / 3
                      this.previewImage = 'MULTI'
                      this.isSmallVideoTimerVisible = false
                      this.isBigVideoTimerVisible = false
                      this.XcomponentWidth = '1920px'
                      this.XcomponentHeight = '1080px'
                        if (this.curPreviewImage !== this.previewImage) {
                        this.xComponentChangeFlag = !this.xComponentChangeFlag
                      }
                    })
                    .fontWeight(this.multiFontWeight)
                }
                .width('100%').height(30)

                ListItem() {
                  Text($r('app.string.photo_mode'))
                    .width('100%')
                    .height('100%')
                    .fontSize('14fp')
                    .fontColor(Color.White)
                    .textAlign(TextAlign.End)
                    .onClick(async () => {
                      this.state.onclickPhoto()
                      this.photoFontWeight = FontWeight.Bold
                      this.videoFontWeight = FontWeight.Regular
                      this.multiFontWeight = FontWeight.Regular
                      this.isScrollToMulti = false
                      this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
                      this.aspectRatio = 4 / 3
                      this.previewImage = 'PHOTO'
                      this.isSmallVideoTimerVisible = false
                      this.isBigVideoTimerVisible = false
                      let getPreviewSize = await this.cameraService.getPreviewSize(this.previewImage)
                      console.info("getPreviewSize = " + JSON.stringify(getPreviewSize))
                      this.XcomponentWidth = getPreviewSize.width.toString() + 'px'
                      this.XcomponentHeight = getPreviewSize.height.toString() + 'px'
                      if (this.curPreviewImage != this.previewImage) {
                        this.xComponentChangeFlag = !this.xComponentChangeFlag
                      }
                    })
                    .fontWeight(this.photoFontWeight)
                }
                .width('100%').height(30)

                ListItem() {
                  Text($r('app.string.video_mode'))
                    .width('100%')
                    .height('100%')
                    .fontSize('14fp')
                    .fontColor(Color.White)
                    .textAlign(TextAlign.End)
                    .onClick(async (event: ClickEvent) => {
                      this.state.onclickVideo()
                      this.photoFontWeight = FontWeight.Regular
                      this.videoFontWeight = FontWeight.Bold
                      this.multiFontWeight = FontWeight.Regular
                      this.isScrollToMulti = false
                      this.scroller.scrollTo({ xOffset: 0, yOffset: 32 })
                      this.aspectRatio = 4 / 3
                      this.previewImage = 'VIDEO'
                      this.isSmallVideoTimerVisible = false
                      this.isBigVideoTimerVisible = false
                      let getPreviewSize = await this.cameraService.getPreviewSize(this.previewImage)
                      console.info("getPreviewSize = " + JSON.stringify(getPreviewSize))
                      this.XcomponentWidth = getPreviewSize.width.toString() + 'px'
                      this.XcomponentHeight = getPreviewSize.height.toString() + 'px'
                      if (this.curPreviewImage !== this.previewImage) {
                        this.xComponentChangeFlag = !this.xComponentChangeFlag
                      }
                    })
                    .fontWeight(this.videoFontWeight)
                }
                .width('100%').height(30)

                ListItem() {
                }
                .width('100%').height(32)

                ListItem() {
                }
                .width('100%').height(30)
              }.opacity(this.opacityValue)
            }
            .width(64)
            .height(150)
            .scrollable(ScrollDirection.Vertical)
            .scrollBarWidth(0)
            .onScroll((xOffset: number, yOffset: number) => {
              console.info('onScroll called')
            })
            .onScrollEdge(() => {
              console.info('To the edge')
            })
            .onScrollEnd(() => {
              console.info('Scroll Stop')
            })
          }
          .padding({ right: '16vp' })
          .width(64)
          .height('100%')
        }
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start, justifyContent: FlexAlign.Center }) {
          Column() {

          }
          .borderRadius('4vp')
          .width('8vp')
          .height('8vp')
          .backgroundColor('#1095E8')
        }
        .width(28)
        .height('100%')
        .margin({ left: 8 })
      }
      .padding({ right: '20vp' })
      .width('100%')
      .height('144vp')
      .margin({ bottom: '24vp' })
    }
    .width(100)
    .height(144)
    .margin({ bottom: 30})
    .zIndex(2)
  }
}