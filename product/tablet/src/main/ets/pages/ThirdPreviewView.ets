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
import fileshare from '@ohos.fileshare';
import wantConstant from '@ohos.ability.wantConstant';
import { Log } from '@ohos/common/src/main/ets/default/utils/Log';
import { GlobalContext } from '@ohos/common/src/main/ets/default/utils/GlobalContext';
import { BusinessError } from '@ohos.base';
import ability from '@ohos.ability.ability';

@Entry
@Component
struct ThirdPreviewView {
  private TAG: string = '[ThirdPreviewView]:';
  private photoWidth: string = '';
  private photoHeight: string = '';
  private photoUri: string = '';
  private videoUri: string = '';
  private mode: string = '';
  private callBundleName: string = '';
  @State controls: boolean = false;
  @State isShowVideoButton: boolean = true;
  myVideoController: VideoController = new VideoController();

  aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear E`);
    let routerParams = router.getParams();
    if (routerParams === undefined || routerParams === null) {
      return;
    }
    this.photoWidth = routerParams.width?.toString();
    this.photoHeight = routerParams.height?.toString();
    this.photoUri = routerParams.uri?.toString();
    this.mode = routerParams.mode?.toString();
    this.videoUri = routerParams.videoUri?.toString();
    this.callBundleName = routerParams.callBundleName?.toString();
    Log.info(`${this.TAG} aboutToAppear routerParams= ${JSON.stringify(routerParams)}`);
    Log.info(`${this.TAG} aboutToAppear X`);
  }

  backCalledApp(resourceUri: string): void {
    Log.info(`${this.TAG} backCalledApp E`);
    let that = this;
    fileshare.grantUriPermission(resourceUri, this.callBundleName, wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION)
      .then(() => {
        Log.info(`${this.TAG} grantUriPermission success`);
        that.terminateSelfWithResult(resourceUri);
      }).catch((error: BusinessError) => {
      Log.error(`${this.TAG} grantUriPermission error= ${error} `);
    });
    Log.info(`${this.TAG} backCalledApp X`);
  }

  terminateSelfWithResult(resourceUri: string): void {
    Log.info(`${this.TAG} terminateSelfWithResult start`);
    let abilityResult: ability.AbilityResult = {
      resultCode: 0,
      want: {
        parameters: {
          resourceUri: resourceUri,
        },
      }
    };

    GlobalContext.get().getCameraAbilityContext().terminateSelfWithResult(abilityResult, (error: BusinessError, data: Object) => {
      if (error) {
        Log.error(`${this.TAG} Operation failed. Cause: ${error}`);
        return;
      }
      Log.info(`${this.TAG} Operation succeeded: ${data}`);
    });
  }

  private getVideoPlayIcon() {
    if (vp2px(1) >= 1 && vp2px(1) < 2) {
      return $r('app.media.ic_video_play_btn_hdpi');
    } else if (vp2px(1) == 2) {
      return $r('app.media.ic_video_play_btn_xhdpi');
    } else if (vp2px(1) == 3) {
      return $r('app.media.ic_video_play_btn_xxhdpi');
    } else {
      return $r('app.media.ic_video_play_btn_xxxhdpi');
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
            previewUri: `${this.videoUri}/thumbnail/${this.photoWidth?.split("px")[0]}/${this.photoHeight?.split("px")[0]}`,
            controller: this.myVideoController
          })
            .controls(this.controls)
            .objectFit(ImageFit.Contain)
            .width(this.photoWidth)
            .height(this.photoHeight)
            .onClick(() => {
              this.controls = !this.controls;
            })
            .onFinish(() => {
              this.controls = true;
            })
            .zIndex(1)
          if (this.isShowVideoButton) {
            Column() {
              Flex({
                direction: FlexDirection.Column,
                alignItems: ItemAlign.Center,
                justifyContent: FlexAlign.Center
              }) {
                Image(this.getVideoPlayIcon()).objectFit(ImageFit.Contain).width(56).height(56)
                  .onClick(() => {
                    this.myVideoController.start();
                    this.isShowVideoButton = false;
                  })
              }
            }.zIndex(2)
          }
        }
      }
      .width(this.photoWidth)
      .height(this.photoHeight)

      Flex({
        direction: FlexDirection.Column,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.SpaceBetween
      }) {
        Image($r('app.media.ic_public_ok'))
          .width(24)
          .aspectRatio(1)
          .onClick(() => {
            this.backCalledApp(this.mode === "PHOTO" ? this.photoUri : this.videoUri);
          })
        Image($r('app.media.ic_public_cancel'))
          .width(24)
          .aspectRatio(1)
          .onClick(() => {
            router.back();
          })
      }
      .width(48)
      .height('100%')
      .margin({ left: 24 })
      .padding({ top: '64', bottom: '64' })
      .position({ y: 0 })
    }.width('100%').height('100%').backgroundColor('#000')
  }
}