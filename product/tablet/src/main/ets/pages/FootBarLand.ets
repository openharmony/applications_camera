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

//import {CameraService} from '../../../../../../../common/src/main/ets/default/Camera/CameraService.ets';
import {CameraSwitchButton
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/cameraswitcher/CameraSwitchButton'
import {ControlLand} from './ControlLand'
import {ShutterButtonLand
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/shutterbutton/ShutterButtonLand'
import {ThumbnailView
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/thumbnail/ThumbnailView'

@Component
export struct FootBarLand {
  @Link previewImage: string
//  private cameraService = CameraService.getInstance()
  @State isVisible: boolean = true
  @Link surfaceId: number
  @Link cameraPosition: string
  @Link isThirdPartyCall: boolean
  @Link isBigVideoTimerVisible: boolean
  @Link isSmallVideoTimerVisible: boolean
  @Link isResumeVideo: boolean
  @Link iscContinueVideo: boolean
  @Link isShowFlashBlack: boolean
  @Link btnSwitch: boolean
  @Link btnSwitchSec: boolean
  @Link btnOpacity_first: number
  @Link btnOpacity_sec: number
  @Link xComponentChangeFlag: boolean
  @Link cameraId: string
  @Link isStartVideo: boolean
  @Link isSwitchBackground: boolean
  @Link videoState: string
  @Link XcomponentWidth: string
  @Link XcomponentHeight: string
  @Link aspectRatio: number
  @Link state: any
  @Link action: string
  @Link curPreviewImage: string
  @State cameraDevice: string = 'tablet'

  private aboutToAppear() {
    // todo 这里获取cameraInfo的时机有问题
//    if (this.cameraService.cameraInfo) {
//      if (this.cameraService.cameraInfo.length > 1) {
//        this.isVisible = true
//      } else {
//        this.isVisible = false
//      }
//    } else {
      this.isVisible = true
//    }
  }

  build() {
    Flex({
    direction: FlexDirection.Column,
    alignItems: ItemAlign.Center,
    justifyContent: FlexAlign.Center
    }) {
      Column(){

      }.width('100%').height(160)
      Flex({
        direction: FlexDirection.Column,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center
      }) {
        if (this.isVisible) {
          CameraSwitchButton({
            surfaceId: $surfaceId,
            cameraPosition: $cameraPosition,
            btnSwitch: $btnSwitch,
            btnSwitchSec: $btnSwitchSec,
            btnOpacity_first: $btnOpacity_first,
            btnOpacity_sec: $btnOpacity_sec,
            xComponentChangeFlag: $xComponentChangeFlag,
            previewImage: $previewImage,
            cameraId: $cameraId,
            isSwitchBackground: $isSwitchBackground,
            videoState: $videoState,
            cameraDevice: $cameraDevice,
	    state: $state
          })
        } else {
          Column() {
          }
          .width('40')
          .aspectRatio(1)
        }

      ShutterButtonLand({
        previewImage: $previewImage,
	state: $state,
        isThirdPartyCall: $isThirdPartyCall,
        isStartVideo: $isStartVideo,
        isBigVideoTimerVisible: $isBigVideoTimerVisible,
        isSmallVideoTimerVisible: $isSmallVideoTimerVisible,
        isResumeVideo: $isResumeVideo,
        iscContinueVideo: $iscContinueVideo,
        isShowFlashBlack: $isShowFlashBlack,
        xComponentChangeFlag: $xComponentChangeFlag,
        videoState: $videoState,
        XcomponentWidth: $XcomponentWidth,
        XcomponentHeight: $XcomponentHeight
      })

        ThumbnailView({state: $state})
      }
      .width('100%')
        .height(260)
        .margin({top: $r("sys.float.ohos_id_text_paragraph_margin_xl"), bottom: $r("sys.float.ohos_id_text_paragraph_margin_xl")})
      if (this.videoState === "beforeTakeVideo") {
        ControlLand({
          aspectRatio: $aspectRatio,
          previewImage: $previewImage,
          state: $state,
          isSmallVideoTimerVisible: $isSmallVideoTimerVisible,
          isBigVideoTimerVisible: $isBigVideoTimerVisible,
          isThirdPartyCall: $isThirdPartyCall,
          cameraPosition: $cameraPosition,
          XcomponentWidth: $XcomponentWidth,
          XcomponentHeight: $XcomponentHeight,
          action: $action,
          xComponentChangeFlag: $xComponentChangeFlag,
          curPreviewImage: $curPreviewImage
        })
      } else {
        Column(){

        }.width('100%').height(160)
      }
    }
    .width(128)
    .height('100%')
    .zIndex(1)
  }
}
