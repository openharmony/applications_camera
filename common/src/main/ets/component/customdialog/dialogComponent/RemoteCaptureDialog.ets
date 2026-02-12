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

import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { HiLog } from '../../../utils/HiLog';

/* instrument ignore file */
const dialogMargin: number = 16;
const buttonWidth: string = '87%';
const TAG: string = 'RemoteCaptureDialog';
const CLOSE_DIALOG_TIME: number = 8 * 1000; // 8秒后自动关闭弹窗

@CustomDialog
export struct RemoteCaptureDialog {
  timerId?: number;
  controller?: CustomDialogController;
  cancel: () => void = async () => {
    clearTimeout(this.timerId);
  };
  confirm: (isOnce: boolean) => void = () => {
    clearTimeout(this.timerId);
  };
  isSmartWatch: boolean = false;
  deviceName: string | undefined;
  build() {
    Column() {
      Image($r('app.media.ic_camera_remote_capture'))
        .height(32)
        .width(32)
        .margin({ top: 24 })

      Column() {
        Text($r('app.string.sports_health_title', this.deviceName))
          .fontSize(20)
          .maxFontScale(CommonConstants.TEXT_SIZE_NORMAL)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Bold)
          .fontFamily('HarmonyHeiTi')
          .lineHeight(23)
          .textAlign(TextAlign.Center)
          .height(77)
          .width('87%')
          .opacity(1)

        Text(!this.isSmartWatch ? $r('app.string.sports_health_contents_UnSmart') : $r('app.string.sports_health_contents'))
          .fontColor($r('sys.color.font_primary'))
          .maxFontScale(CommonConstants.TEXT_SIZE_NORMAL)
          .fontWeight(FontWeight.Regular)
          .fontFamily('HarmonyHeiTi')
          .textAlign(TextAlign.Start)
          .lineHeight(19)
          .width('87%')
          .opacity(1)
      }

      Column() {
        Button() {
          Text($r('app.string.sports_health_dialog_need_once'))
            .fontColor($r('sys.color.font_emphasize'))
            .fontSize($r('sys.float.Body_L'))
            .maxFontScale(CommonConstants.TEXT_SIZE_NORMAL)
            .lineHeight(19)
            .fontWeight(FontWeight.Medium)
            .height(21)
            .width(buttonWidth)
            .opacity(1)
            .textAlign(TextAlign.Center)
        }
        .width(296)
        .height(40)
        .opacity(1)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .onClick(async (): Promise<void> => {
          this.controller?.close();
          this.confirm(true);
        })

        Button() {
          Text($r('app.string.sports_health_dialog_need_enable'))
            .fontColor($r('sys.color.font_emphasize'))
            .fontSize($r('sys.float.Body_L'))
            .maxFontScale(CommonConstants.TEXT_SIZE_NORMAL)
            .lineHeight(19)
            .fontWeight(FontWeight.Medium)
            .height(21)
            .width(buttonWidth)
            .textAlign(TextAlign.Center)
        }
        .height(40)
        .width(296)
        .margin({ top: 4 })
        .opacity(1)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .onClick(async (): Promise<void> => {
          this.confirm(false);
          this.controller?.close();
        })

        Button() {
          Text($r('app.string.sports_health_dialog_deny'))
            .fontColor($r('sys.color.font_emphasize'))
            .fontSize($r('sys.float.Body_L'))
            .maxFontScale(CommonConstants.TEXT_SIZE_NORMAL)
            .lineHeight(19)
            .fontWeight(FontWeight.Medium)
            .height(21)
            .width(buttonWidth)
            .opacity(1)
            .textAlign(TextAlign.Center)
        }
        .height(40)
        .width(296)
        .margin({ top: 4 })
        .opacity(1)
        .buttonStyle(ButtonStyleMode.TEXTUAL)
        .onClick(async (): Promise<void> => {
          this.cancel();
          this.controller?.close();
        })
      }
      .height(136)
      .width(328)
      .margin({ top: 8 })
    }
    .width('100%')
    .borderRadius($r('sys.float.ohos_id_corner_radius_dialog'))
    .backgroundColor(Color.Transparent)
    .opacity(1)
    .margin({ left: dialogMargin, right: dialogMargin })
    .onAppear( () => {
      this.timerId = setTimeout(async () => {
        HiLog.i(TAG, 'onPageShow auto close at 8s');
        clearTimeout(this.timerId);
        this.cancel();
        this.controller?.close();
      }, CLOSE_DIALOG_TIME);
    })
    .onDisAppear(()=>{
      clearTimeout(this.timerId);
    })
  }
}