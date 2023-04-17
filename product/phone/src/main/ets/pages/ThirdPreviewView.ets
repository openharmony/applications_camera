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

import router from '@system.router'
import fileshare from '@ohos.fileshare'
import wantConstant from '@ohos.ability.wantConstant'

import { Log } from '@ohos/common/src/main/ets/default/utils/Log'

@Entry
@Component
struct ThirdPreviewView {
  private TAG: string = '[ThirdPreviewView]:'
  private photoWidth: string
  private photoHeight: string
  private photoUri: string
  private videoUri: string
  private mode: string
  private callBundleName: string
  @State controls: boolean = false
  @State isShowVideoButton: boolean = true
  myVideoController: VideoController = new VideoController()

  aboutToAppear() {
    let routerParams = router.getParams()
    this.photoWidth = routerParams.width.toString()
    Log.info(`${this.TAG} aboutToAppear photoWidth= ${this.photoWidth} E`)
    this.photoHeight = routerParams.height.toString()
    Log.info(`${this.TAG} aboutToAppear photoHeight= ${this.photoHeight} E`)
    this.photoUri = routerParams.uri.toString()
    Log.info(`${this.TAG} aboutToAppear photoUri= ${this.photoUri} E`)
    this.mode = routerParams.mode.toString()
    Log.info(`${this.TAG} aboutToAppear mode= ${this.mode} E`)
    this.videoUri = routerParams.videoUri.toString()
    Log.info(`${this.TAG} aboutToAppear videoUri= ${this.videoUri} E`)
    this.callBundleName = routerParams.callBundleName.toString()
    Log.info(`${this.TAG} aboutToAppear callBundleName= ${this.callBundleName} E`)
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  backCalledApp(resourceUri) {
    Log.info(`${this.TAG} backCalledApp E`)
    let that = this
    fileshare.grantUriPermission(resourceUri, this.callBundleName, wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION)
      .then(() => {
        Log.info(`${this.TAG} grantUriPermission success`)
        that.terminateSelfWithResult(resourceUri)
      }).catch(function (error) {
      Log.error(`${this.TAG} grantUriPermission error= ${error} `)
    })
    Log.info(`${this.TAG} backCalledApp X`)
  }

  terminateSelfWithResult(resourceUri) {
    Log.info(`${this.TAG} terminateSelfWithResult start`)
    let abilityResult = {
      "resultCode": 200,
      "want": {
        "parameters": {
          "resourceUri": resourceUri,
          "width": this.photoWidth,
          "height": this.photoHeight
        },
        "bundleName": "com.ohos.camera",
        "abilityName": "com.ohos.camera.MainAbility"
      }
    };

    globalThis.cameraAbilityContext.terminateSelfWithResult(abilityResult, (error, data) => {
      if (error) {
        Log.error(`${this.TAG} Operation failed. Cause: ${error}`);
        return;
      }
      Log.info(`${this.TAG} Operation succeeded: ${data}`);
    });
  }

  private getVideoPlayIcon() {
    if (vp2px(1) >= 1 && vp2px(1) < 2) {
      return $r('app.media.ic_video_play_btn_hdpi')
    } else if (vp2px(1) == 2) {
      return $r('app.media.ic_video_play_btn_xhdpi')
    } else if (vp2px(1) == 3) {
      return $r('app.media.ic_video_play_btn_xxhdpi')
    } else {
      return $r('app.media.ic_video_play_btn_xxxhdpi')
    }
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Stack() {
        if (this.mode === "PHOTO") {
          Column() {
            Image(this.photoUri)
              .width('100%')
              .height('100%')
          }
          .width(this.photoWidth)
          .height(this.photoHeight)
        } else {
          Video({
            src: this.videoUri,
            previewUri: `${this.videoUri}/thumbnail/${this.photoWidth.split("px")[0]}/${this.photoHeight.split("px")[0]}`,
            controller: this.myVideoController
          })
            .controls(this.controls)
            .objectFit(ImageFit.Contain)
            .width(this.photoWidth)
            .height(this.photoHeight)
            .onClick(() => {
              this.controls = !this.controls
            })
            .onFinish(() => {
              this.controls = true;
            })
            .zIndex(1)
          if(this.isShowVideoButton) {
            Column() {
              Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
                Image(this.getVideoPlayIcon()).objectFit(ImageFit.Contain).width(56).height(56)
                  .onClick(() => {
                    this.myVideoController.start()
                    this.isShowVideoButton = false
                  })
              }
            }.zIndex(2)
          }
        }
      }
      .width(this.photoWidth)
      .height(this.photoHeight)
      Flex({
        direction: FlexDirection.Row,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.SpaceBetween
      }) {
        Image($r('app.media.ic_system_cancel'))
          .width(24)
          .aspectRatio(1)
          .onClick(() => {
            router.back()
          })
        Image($r('app.media.ic_system_confirm'))
          .width(24)
          .aspectRatio(1)
          .onClick(() => {
            this.backCalledApp(this.mode === "PHOTO" ? this.photoUri : this.videoUri)
          })
      }.width('100%').height(48).margin({ top: '24vp' })
      .padding({ top: '12vp', left: '24vp', right: '24vp' })
      .position({x:0, y:0})
    }.width('100%').height('100%').backgroundColor('#000')
  }
}