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

import {ThumbnailView
} from '../../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/thumbnail/ThumbnailView.ets'
import {ShutterButton
} from '../../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/shutterbutton/ShutterButton.ets'
import {CameraSwitchButton
} from '../../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/cameraswitcher/CameraSwitchButton.ets'
import {CameraService} from '../../../../../../../common/src/main/ets/default/Camera/CameraService.ets';

@Component
export struct FootBar {
  @Link previewImage: string
  @State thumbnail: Resource = $r("app.media.ic_camera_thumbnail_default_white")
  private cameraService = CameraService.getInstance()
  @State isVisible: boolean = true
  @Link surfaceId: number
  @Link isThirdPartyCall: boolean;
  @Link isBigVideoTimerVisible: boolean
  @Link isSmallVideoTimerVisible: boolean
  @Link isResumeVideo: boolean
  @Link iscContinueVideo: boolean
  @Link isShowFlashBlack: boolean
  @Link isStartVideo: boolean
  @Link cameraId: string
  @Link cameraPosition: string
  @Link btnSwitch: boolean
  @Link btnSwitchSec: boolean
  @Link btnOpacity_first: number
  @Link btnOpacity_sec: number
  @Link xComponentChangeFlag: boolean
  @Link isSwitchBackground: boolean
  @Link videoState: string

  private aboutToAppear() {
    console.info("FootBar aboutToAppear")
    if (this.cameraService.cameraInfo) {
      if (this.cameraService.cameraInfo.length > 1) {
        this.isVisible = true
      } else {
        this.isVisible = false
      }
    } else {
      this.isVisible = true
    }
  }

  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.Center
    }) {
      ThumbnailView()
      ShutterButton({
        previewImage: $previewImage,
        isThirdPartyCall: $isThirdPartyCall,
        isStartVideo: $isStartVideo,
        isBigVideoTimerVisible: $isBigVideoTimerVisible,
        isSmallVideoTimerVisible: $isSmallVideoTimerVisible,
        isResumeVideo: $isResumeVideo,
        iscContinueVideo: $iscContinueVideo,
        isShowFlashBlack: $isShowFlashBlack,
        xComponentChangeFlag: $xComponentChangeFlag,
        videoState: $videoState
      })
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
          isSwitchBackground: $isSwitchBackground
        })
      } else {
        Column() {
        }
        .width('40')
        .aspectRatio(1)
      }
    }
    .height(96)
    .opacity(100)
    .width('100%')
    .padding({ top: 10, bottom: 10 })
  }
}
