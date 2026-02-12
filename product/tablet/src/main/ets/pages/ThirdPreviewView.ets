/*
 * Copyright (c) Huawei Device Co., Ltd. 2024-2025. All rights reserved.
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

import fileshare from '@ohos.fileshare';
import wantConstant from '@ohos.ability.wantConstant';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import { BusinessError } from '@ohos.base';
import { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';

const TAG: string = 'ThirdPreviewView';

class NavigationState {
  public width: number = 0;
  public height: number = 0;
  public mode: ModeType = ModeType.NONE;
  public uri: string = '';
  public videoUri: string = '';
  public callBundleName: string = '';
}

@Component
export struct ThirdPreviewView {
  @State controls: boolean = false;
  @State isShowVideoButton: boolean = true;
  private photoWidth: string = '';
  private photoHeight: string = '';
  private photoUri: string = '';
  private videoUri: string = '';
  private mode: ModeType = ModeType.NONE;
  private myVideoController: VideoController = new VideoController();
  private callBundleName: string = '';
  @Consume('pageInfos') pageInfos: NavPathStack;
  private navigationName: string = '';

  aboutToAppear() {
    HiLog.begin(TAG, 'aboutToAppear.');
    let routerParams: NavigationState[] = this.pageInfos.getParamByName('ThirdPreviewView') as NavigationState[];
    if (routerParams === undefined || routerParams === null) {
      return;
    }
    this.photoWidth = routerParams[0].width?.toString();
    this.photoHeight = routerParams[0].height?.toString();
    this.photoUri = routerParams[0].uri?.toString();
    this.mode = routerParams[0].mode?.toString() as ModeType;
    this.videoUri = routerParams[0].videoUri?.toString();
    this.callBundleName = routerParams[0].callBundleName?.toString();
    HiLog.i(TAG, `aboutToAppear callBundleName= ${JSON.stringify(routerParams)}.`);
    HiLog.end(TAG, 'aboutToAppear.');
  }

  backCalledApp(resourceUri: string) {
    HiLog.i(TAG, 'backCalledApp start.');
    HiLog.d(TAG, `backCalledApp resourceUri is ${resourceUri} callBundleName is ${this.callBundleName}.`);
    if (!resourceUri || !this.callBundleName) {
      HiLog.w(TAG, `resourceUri: ${resourceUri}, bundleName:${this.callBundleName}.`);
      return;
    }
    fileshare.grantUriPermission(resourceUri, this.callBundleName, wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION)
      .then(() => {
        HiLog.i(TAG, 'grantUriPermission success!.');
        PickerUiService.getInstance().terminateSelfWithResult(0, resourceUri);
      }).catch((error: BusinessError) => {
      HiLog.e(TAG, `grantUriPermission err: ${error}.`);
    })
  }

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        Stack() {
          if (OutputOperation.isPanPhotoOutput(this.mode, OutputType.NONE)) {
            Column() {
              Image(this.photoUri)
                .width('100%')
                .height('100%')
                .draggable(false)
            }
            .width(this.photoWidth)
            .height(this.photoHeight)
          } else {
            Video({
              src: this.videoUri,
              previewUri: `${this.videoUri}/thumbnail/${this.photoWidth?.split('px')[0]}/${
              this.photoHeight?.split('px')[0]}`,
              controller: this.myVideoController
            })
              .controls(this.controls)
              .objectFit(ImageFit.Contain)
              .width(this.photoWidth)
              .height(this.photoHeight)
              .onClick((): void => {
                this.controls = !this.controls;
              })
              .onFinish((): void => {
                this.controls = true;
              })
              .zIndex(ZIndex.MIDDLE_BOTTOM)
            if (this.isShowVideoButton) {
              Column() {
                Flex({
                  direction: FlexDirection.Column,
                  alignItems: ItemAlign.Center,
                  justifyContent: FlexAlign.Center
                }) {
                  Image(this.getVideoPlayIcon())
                    .objectFit(ImageFit.Contain)
                    .width(56)
                    .height(56)
                    .onClick((): void => {
                      this.myVideoController.start();
                      this.isShowVideoButton = false;
                    })
                    .draggable(false)
                }
              }.zIndex(ZIndex.MIDDLE_TOP)
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
            .draggable(false)
            .onClick((): void => {
              if (!this.isShowVideoButton) {
                this.isShowVideoButton = true;
              }
              this.pageInfos?.pop();
            })
          Image($r('app.media.ic_system_confirm'))
            .width(24)
            .aspectRatio(1)
            .draggable(false)
            .onClick((): void => {
              if (!this.photoUri && !this.videoUri) {
                HiLog.i(TAG, `Uri is NULL or UNDEFINED photoUri:${this.photoUri}, videoUri:${this.videoUri}`);
              }
              HiLog.i(TAG, 'photoUri and videoUri have valid type');
              this.backCalledApp(OutputOperation.isPanPhotoOutput(this.mode, OutputType.NONE) ?
              this.photoUri : this.videoUri);
            })
        }
        .width('100%')
        .height(48)
        .margin({ top: $r('sys.float.padding_level12') })
        .padding({
          top: $r('sys.float.padding_level6'),
          left: $r('sys.float.padding_level12'),
          right: $r('sys.float.padding_level12')
        })
        .position({ x: 0, y: 0 })
      }.width('100%').height('100%').backgroundColor(Color.Black)
    }
    .hideTitleBar(true)
  }

  private getVideoPlayIcon(): Resource {
    if (vp2px(1) >= 1 && vp2px(1) < 2) {
      return $r('app.media.ic_video_play_btn_hdpi');
    } else if (vp2px(1) === 2) {
      return $r('app.media.ic_video_play_btn_xhdpi');
    } else if (vp2px(1) === 3) {
      return $r('app.media.ic_video_play_btn_xxhdpi');
    } else {
      return $r('app.media.ic_video_play_btn_xxxhdpi');
    }
  }

  onPageShow(): void {
    HiLog.i(TAG, 'onPageShow.');
  }
}