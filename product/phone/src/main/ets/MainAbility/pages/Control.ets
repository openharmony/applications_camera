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
import {changePreviewSize, changeTabItem
} from '../../../../../../../common/src/main/ets/default/redux/actions/ModeChange.ets'
import featureAbility from '@ohos.ability.featureAbility';
import router from '@system.router';
import {CameraService} from '../../../../../../../common/src/main/ets/default/Camera/CameraService.ets';
import wantConstant from '@ohos.ability.wantConstant';

let changeModeState = (state) => {
  return {
    number: state.ModeChangeReducer.number,
    res: state.ModeChangeReducer.res
  }
}

let changeModeDispatch = (dispatch) => {
  return {
    onclickPhoto: () => {
      dispatch(changePreviewSize(154))
      dispatch(changeTabItem('PHOTO'))
    },
    onclickVideo: () => {
      dispatch(changePreviewSize(0))
      dispatch(changeTabItem('VIDEO'))
    }
  }
}


@Component
export struct Control {
  scroller: Scroller = new Scroller()
  @Link aspectRatio: number
  @Link previewImage: string
  private modeConfig: ModeConfig = new ModeConfig()
  @Link state: any
  private connect: any
  private scrollValue: number = 0
  @State photoFontWeight: number = 700
  @State videoFontWeight: number = 400
  @State multiFontWeight: number = 400
  @Link isThirdPartyCall: boolean
  @Link action: string
  private cameraService = CameraService.getInstance()
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
    this.connect = getStore().connect(changeModeState, changeModeDispatch)(this.state)
    featureAbility.getWant().then((want) => {
      console.log(`aboutToAppear success ${JSON.stringify(want.parameters)}`)
      if (want.action === wantConstant.ACTION_IMAGE_CAPTURE) {
        this.isThirdPartyCall = true
        this.previewImage = 'PHOTO'
      } else if (want.action === wantConstant.ACTION_VIDEO_CAPTURE) {
        this.isThirdPartyCall = true
        this.previewImage = 'VIDEO'
      }
    }).catch((error) => {
      console.log(`aboutToAppear fail' ${error}`)
    });
    if (router.getParams() !== null) {
      console.log(`router.getParams()= ${JSON.stringify(router.getParams())}`)
      this.action = router.getParams().actionType
      this.previewImage = this.action === 'capture' ? 'PHOTO' : 'VIDEO'
    }
  }

  private aboutToDisappear() {
    this.connect().destory()
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomStart }) {
        if (this.isThirdPartyCall || this.action === 'capture') {
          Row() {
            Text($r('app.string.photo_mode'))
              .width('100%')
              .height('100%')
              .fontSize('14fp')
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .fontWeight(700)
          }
          .width('100%')
          .height('100%')
        } else if (this.action === 'video') {
          Row() {
            Text($r('app.string.video_mode'))
              .width('100%')
              .height('100%')
              .fontSize('14fp')
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .fontWeight(700)
          }
          .width('100%')
          .height('100%')
        } else {
          Stack() {
            Scroll(this.scroller) {
              Row() {
                Row() {
                  Text('')
                    .fontColor('#fff')
                    .fontSize('14fp')
                    .layoutWeight(1)
                    .height('100%')
                    .textAlign(TextAlign.Center)
                  if (this.isScrollToMulti) {
                    Text('')
                      .fontColor('#fff')
                      .fontSize('14fp')
                      .width(108)
                      .height('100%')
                      .textAlign(TextAlign.Center)
                  }
                  Text($r('app.string.multi_mode'))
                    .fontColor('#fff')
                    .fontSize('14fp')
                    .width(54)
                    .height('100%')
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      this.photoFontWeight = 400
                      this.videoFontWeight = 400
                      this.multiFontWeight = 700
                      this.isScrollToMulti = true
                      this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
                      this.aspectRatio = 3 / 4
                      this.previewImage = 'MULTI'
                    })
                    .fontWeight(this.multiFontWeight)
                  Text($r('app.string.photo_mode'))
                    .fontColor('#fff')
                    .fontSize('14fp')
                    .width(54)
                    .height('100%')
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      this.state.onclickPhoto()
                      this.photoFontWeight = 700
                      this.videoFontWeight = 400
                      this.multiFontWeight = 400
                      this.isScrollToMulti = false
                      this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
                      this.aspectRatio = 3 / 4
                      this.previewImage = 'PHOTO'
                    })
                    .fontWeight(this.photoFontWeight)
                  Text($r('app.string.video_mode'))
                    .fontColor('#fff')
                    .fontSize('14fp')
                    .width(54)
                    .height('100%')
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      this.state.onclickVideo()
                      this.photoFontWeight = 400
                      this.videoFontWeight = 700
                      this.multiFontWeight = 400
                      this.isScrollToMulti = false
                      this.scroller.scrollTo({ xOffset: '20%', yOffset: 0 })
                      this.aspectRatio = 3 / 4
                      this.previewImage = 'VIDEO'
                    })
                    .fontWeight(this.videoFontWeight)
                  Text('')
                    .fontColor('#fff')
                    .fontSize('14fp')
                    .layoutWeight(1)
                    .height('100%')
                    .textAlign(TextAlign.Center)
                }
                .width('100%')
                .height('100%')

                Row() {
                  Text('')
                    .fontColor('#fff')
                    .fontSize('14fp')
                    .width(54)
                    .height('100%')
                    .textAlign(TextAlign.Center)
                }
                .height('100%')
              }
              .height('100%')
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBarWidth(0)
            .onScroll((xOffset: number, yOffset: number) => {

            })
            .onScrollEdge(() => {
              console.info('To the edge')
            })
            .onScrollEnd(() => {
              console.info('Scroll Stop')
            })
          }
          .width('100%')
          .height('100%')
        }
        Column() {
          Column() {

          }
          .borderRadius(3)
          .width(6)
          .height(6)
          .backgroundColor('#1095E8')
        }
        .width('100%')
        .height(18)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height(58)
  }
}