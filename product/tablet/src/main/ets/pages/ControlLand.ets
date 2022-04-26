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

//import ability_featureAbility from '@ohos.ability.featureAbility';
import router from '@system.router';
import wantConstant from '@ohos.ability.wantConstant';

import { AsyncManager } from '../../../../../../common/src/main/ets/default/Utils/AsyncManager'
//import {CameraService} from '../../../../../../../common/src/main/ets/default/Camera/CameraService.ets';
import { changePreviewSize } from '../../../../../../common/src/main/ets/default/redux/actions/ModeChange'
import { CLog } from '../../../../../../common/src/main/ets/default/Utils/CLog'
import getStore from '../../../../../../common/src/main/ets/default/redux/store'
import { ModeConfig } from '../common/ModeConfig'
import { SettingsUtil } from '../../../../../../common/src/main/ets/default/Utils/SettingsUtil'

let changeModeState = (state) => {
  return {
    number: state.ModeChangeReducer.number,
    res: state.ModeChangeReducer.res
  }
}

let changeModeDispatch = (dispatch) => {
  return {
    onclickPhoto: () => {
      CLog.info('[ControlLand]: zhaochong: onclickPhoto1')
      dispatch(changePreviewSize(154))
      CLog.info('[ControlLand]: zhaochong: onclickPhoto2')
    },
    onclickVideo: () => dispatch(changePreviewSize(0))
  }
}


@Component
export struct ControlLand {
  private TAG: string = '[ControlLand]:'
  scroller: Scroller = new Scroller()
  //  private cameraService = CameraService.getInstance()
  @Link aspectRatio: number
  @Link previewImage: string
  private modeConfig: ModeConfig = new ModeConfig()
  private asyncManager: AsyncManager
  @Link state: any
  private connect: any
  @State scrollValue: number = 0
  @State photoFontWeight: FontWeight = FontWeight.Bold
  @State videoFontWeight: FontWeight = FontWeight.Regular
  @State multiFontWeight: FontWeight = FontWeight.Regular
  @State notCheckFontSize: Resource = $r("sys.float.ohos_id_text_size_body2") // 未选中
  @State checkFontSize: Resource = $r("sys.float.ohos_id_text_size_body1") // 选中
  @State photoFontSize: Resource = $r("sys.float.ohos_id_text_size_body1")
  @State videoFontSize: Resource = $r("sys.float.ohos_id_text_size_body2")
  @State multiFontSize: Resource = $r("sys.float.ohos_id_text_size_body2")
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
  @State initIndex: number = 1
  @State modeIndex: number = 0
  private settingsUtil = SettingsUtil.getInstance()

  private aboutToAppear() {
    let startWant = globalThis.cameraAbilityWant
    CLog.info(this.TAG + ' Camera MainAbility onCreate uri: ' + startWant.uri)

    // todo 架构重构的线索
    this.asyncManager = AsyncManager.getInstance()
    this.connect = getStore().connect(changeModeState, changeModeDispatch)(this.state)

    if (startWant.action === 'ohos.want.action.imageCapture') {
      CLog.info(this.TAG + ' wantConstant.ACTION_IMAGE_CAPTURE called')
      this.isThirdPartyCall = true
      this.previewImage = 'PHOTO'
    } else if (startWant.action === 'ohos.want.action.videoCapture') {
      CLog.info(this.TAG + ' wantConstant.ACTION_VIDEO_CAPTURE called')
      this.isThirdPartyCall = true
      this.previewImage = 'VIDEO'
    }

    switch (this.previewImage) {
      case 'MULTI':
        this.initIndex = 0
        this.photoFontWeight = FontWeight.Regular
        this.videoFontWeight = FontWeight.Regular
        this.multiFontWeight = FontWeight.Bold
        this.photoFontSize = this.notCheckFontSize
        this.videoFontSize = this.notCheckFontSize
        this.multiFontSize = this.checkFontSize
        break;
      case 'PHOTO':
        this.initIndex = 1
        this.photoFontWeight = FontWeight.Bold
        this.videoFontWeight = FontWeight.Regular
        this.multiFontWeight = FontWeight.Regular
        this.photoFontSize = this.checkFontSize
        this.videoFontSize = this.notCheckFontSize
        this.multiFontSize = this.notCheckFontSize
        break;
      case 'VIDEO':
        this.initIndex = 2
        this.photoFontWeight = FontWeight.Regular
        this.videoFontWeight = FontWeight.Bold
        this.multiFontWeight = FontWeight.Regular
        this.photoFontSize = this.notCheckFontSize
        this.videoFontSize = this.checkFontSize
        this.multiFontSize = this.notCheckFontSize
        break;
      default:
        break;
    }

    //    console.info("ControlLand router.getParams()= " + JSON.stringify(router.getParams()))
    //    if (router.getParams() != undefined) {
    //      console.info("ControlLand scrollTo called")
    //      if (this.previewImage == 'MULTI') {
    //        this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
    //      } else if (this.previewImage == 'PHOTO') {
    //        this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
    //      } else {
    //        this.scroller.scrollTo({ xOffset: 0, yOffset: 30 })
    //      }
    //    }
  }

  private aboutToDisappear() {
    this.connect.destroy()
  }

  public switchToPhotoMode() {
    this.state.onclickPhoto()
    this.photoFontWeight = FontWeight.Bold
    this.videoFontWeight = FontWeight.Regular
    this.multiFontWeight = FontWeight.Regular
    this.photoFontSize = this.checkFontSize
    this.videoFontSize = this.notCheckFontSize
    this.multiFontSize = this.notCheckFontSize
    this.scroller.scrollToIndex(1)
    // 发送mode切换的消息
    this.asyncManager.postMessage({ type: 'modeChange', data: 'PHOTO' })
    this.aspectRatio = 4 / 3
    this.previewImage = 'PHOTO'
    this.isSmallVideoTimerVisible = false
    this.isBigVideoTimerVisible = false
    this.settingsUtil.setMode(this.previewImage)
    let xComponentSize = this.settingsUtil.getPreviewDisplaySize()
    CLog.info(this.TAG + " xComponentSize = " + JSON.stringify(xComponentSize))
    this.XcomponentWidth = xComponentSize.width.toString() + 'px'
    this.XcomponentHeight = xComponentSize.height.toString() + 'px'
    if (this.curPreviewImage != this.previewImage) {
      this.state.disableUi()
      this.xComponentChangeFlag = !this.xComponentChangeFlag
    }
    // if (this.cameraPosition !== this.previewImage) {
    //   this.cameraPosition = this.cameraPosition !== 'PHOTO' ? 'PHOTO' : 'VIDEO'
    // }
    // this.cameraService.changeMode(this.previewImage)
  }

  public switchToVideoMode() {
    this.state.onclickVideo()
    this.photoFontWeight = FontWeight.Regular
    this.videoFontWeight = FontWeight.Bold
    this.multiFontWeight = FontWeight.Regular
    this.photoFontSize = this.notCheckFontSize
    this.videoFontSize = this.checkFontSize
    this.multiFontSize = this.notCheckFontSize
    this.scroller.scrollToIndex(2)
    // 发送mode切换的消息
    this.asyncManager.postMessage({ type: 'modeChange', data: 'VIDEO' })
    this.aspectRatio = 4 / 3
    this.previewImage = 'VIDEO'
    this.isSmallVideoTimerVisible = false
    this.isBigVideoTimerVisible = false
    this.settingsUtil.setMode(this.previewImage)
    let xComponentSize = this.settingsUtil.getPreviewDisplaySize()
    CLog.info(this.TAG + " xComponentSize = " + JSON.stringify(xComponentSize))
    this.XcomponentWidth = xComponentSize.width.toString() + 'px'
    this.XcomponentHeight = xComponentSize.height.toString() + 'px'
    if (this.curPreviewImage !== this.previewImage) {
      this.state.disableUi()
      this.xComponentChangeFlag = !this.xComponentChangeFlag
    }
    // if (this.cameraPosition !== this.previewImage) {
    //   this.cameraPosition = this.cameraPosition !== 'VIDEO' ? 'VIDEO' : 'PHOTO'
    // }
    // this.cameraService.changeMode(this.previewImage)
  }

  public switchToMultiMode() {
    this.photoFontWeight = FontWeight.Regular
    this.videoFontWeight = FontWeight.Regular
    this.multiFontWeight = FontWeight.Bold
    this.photoFontSize = this.notCheckFontSize
    this.videoFontSize = this.notCheckFontSize
    this.multiFontSize = this.checkFontSize
    this.scroller.scrollToIndex(0)
    // 发送mode切换的消息
    // this.asyncManager.postMessage({ type: 'modeChange', data: 'VIDEO' })
    this.aspectRatio = 4 / 3
    this.previewImage = 'MULTI'
    this.isSmallVideoTimerVisible = false
    this.isBigVideoTimerVisible = false
    // todo 多机位分辨率暂时仅考虑1920*1080
    // this.XcomponentWidth = '1920px'
    // this.XcomponentHeight = '1080px'
    this.settingsUtil.setMode(this.previewImage)
    let xComponentSize = this.settingsUtil.getPreviewDisplaySize()
    CLog.info(this.TAG + " xComponentSize = " + JSON.stringify(xComponentSize))
    this.XcomponentWidth = xComponentSize.width.toString() + 'px'
    this.XcomponentHeight = xComponentSize.height.toString() + 'px'
    if (this.curPreviewImage !== this.previewImage) {
      this.state.disableUi()
      this.xComponentChangeFlag = !this.xComponentChangeFlag
    }
    // if (this.cameraPosition !== this.previewImage) {
    //   this.cameraPosition = this.cameraPosition !== 'VIDEO' ? 'VIDEO' : 'PHOTO'
    // }
    // this.cameraService.changeMode(this.previewImage)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
        if (this.isThirdPartyCall || this.action === 'capture') {
          Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
            Text($r('app.string.photo_mode'))
              .width(64)
              .fontSize(14)
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
              .fontSize(14)
              .fontColor(Color.White)
              .textAlign(TextAlign.End)
              .fontWeight(FontWeight.Bold)
          }
          .width(64)
          .height('100%')
        } else {
          List({ initialIndex: this.initIndex, scroller: this.scroller }) {
            ListItem() {
            }
            .width('100%').height(32)

            ListItem() {
            }
            .width('100%').height(32)

            ListItem() {
              Text($r('app.string.multi_mode'))
                .width('100%')
                .height('100%')
                .fontSize(this.multiFontSize)
                .fontColor(Color.White)
                .textAlign(TextAlign.End)
                .enabled(this.state.uiEnable)
                .onClick(async (event: ClickEvent) => {
                  this.switchToMultiMode()
                })
                .fontWeight(this.multiFontWeight)
            }
            .width('100%').height(32)

            ListItem() {
              Text($r('app.string.photo_mode'))
                .width('100%')
                .height('100%')
                .fontSize(this.photoFontSize)
                .fontColor(Color.White)
                .textAlign(TextAlign.End)
                .enabled(this.state.uiEnable)
                .onClick(async () => {
                  this.switchToPhotoMode()
                })
                .fontWeight(this.photoFontWeight)
            }
            .width('100%').height(32)

            ListItem() {
              Text($r('app.string.video_mode'))
                .width('100%')
                .height('100%')
                .fontSize(this.videoFontSize)
                .fontColor(Color.White)
                .textAlign(TextAlign.End)
                .enabled(this.state.uiEnable)
                .onClick(async (event: ClickEvent) => {
                  this.switchToVideoMode()
                })
                .fontWeight(this.videoFontWeight)
            }
            .width('100%').height(32)

            ListItem() {
            }
            .width('100%').height(32)

            ListItem() {
            }
            .width('100%').height(32)
          }
          .opacity(this.opacityValue)
          .layoutWeight(1)
          .height(160)
          .edgeEffect(EdgeEffect.None)
          .chainAnimation(false)
          .onScrollIndex((firstIndex: number, lastIndex: number) => {
            CLog.info(`${this.TAG} first= ${firstIndex}`)
            CLog.info(`${this.TAG} last= ${lastIndex}`)
            this.modeIndex = firstIndex
          })
          .enabled(this.state.uiEnable)
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Up) {
              CLog.log(`${this.TAG} modeIndex= ${this.modeIndex}`)
              this.scroller.scrollToIndex(this.modeIndex)
              if (this.modeIndex === 0) {
                this.switchToMultiMode()
              } else if (this.modeIndex === 1) {
                this.switchToPhotoMode()
              } else if (this.modeIndex === 2) {
                this.switchToVideoMode()
              }
            }
          })
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
        .height(160)
        .margin({ left: 8 })
      }
      .width('100%')
      .height('100%')
    }
    .width(128)
    .height(160)
    .zIndex(2)
  }
}