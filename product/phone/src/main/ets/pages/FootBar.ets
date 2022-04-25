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

import {CameraSwitchButton
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/cameraswitcher/CameraSwitchButton'
//import {CameraService} from '../../../../../../../common/src/main/ets/default/Camera/CameraService';
import {CLog} from '../../../../../../common/src/main/ets/default/Utils/CLog'
import {ShutterButton
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/shutterbutton/ShutterButton'
import {ThumbnailView
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/thumbnail/ThumbnailView'
import getStore from '../../../../../../common/src/main/ets/default/redux/store'
import {Action} from '../../../../../../common/src/main/ets/default/redux/actions/Action'

let footBarState = (state) => {
  return {
    platformCapability: state.CameraInitReducer.platformCapability
  }
}

let footBarDispatcher = (dispatch) => {
  return {}
}

@Component
export struct FootBar {
  private TAG: string = '[FootBar]:'

  @State state: any = {}

  private mConnect: any

//  @Link previewImage: string
////  private cameraService = CameraService.getInstance()
//  @State isVisible: boolean = true
//  @Link surfaceId: number
//  @Link isThirdPartyCall: boolean;
//  @Link isBigVideoTimerVisible: boolean
//  @Link isSmallVideoTimerVisible: boolean
//  @Link isResumeVideo: boolean
//  @Link iscContinueVideo: boolean
//  @Link isShowFlashBlack: boolean
//  @Link isStartVideo: boolean
//  @Link cameraId: string
//
//
//  @Link cameraPosition: string
//  @Link btnSwitch: boolean
//  @Link btnSwitchSec: boolean
//  @Link btnOpacity_first: number
//  @Link btnOpacity_sec: number
//  @Link xComponentChangeFlag: boolean
//  @Link isSwitchBackground: boolean
//  @Link videoState: string
//  @Link XcomponentWidth: string
//  @Link XcomponentHeight: string
//  @State cameraDevice: string = 'phone'
//  @Link state: any

  public aboutToAppear(): void {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(footBarState, footBarDispatcher)(this.state)
    CLog.info(`${this.TAG} aboutToAppear X`)
//    if (this.camera`                                                          Service.cameraInfo) {
//      if (this.cameraService.cameraInfo.length > 1) {
//        this.isVisible = true
//      } else {
//        this.isVisible = false
//      }
//    } else {
//      this.isVisible = true
//    }
  }

  public aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.Center
    }) {
      ThumbnailView()
      ShutterButton()
      if (this.state.platformCapability?.mCameraCount > 1) {
        CameraSwitchButton()
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
    .padding({ top: 10, bottom: 10})
  }

//  build() {
//    Flex({
//      direction: FlexDirection.Row,
//      alignItems: ItemAlign.Center,
//      justifyContent: FlexAlign.Center
//    }) {
//      ThumbnailView({state: $state})
//      ShutterButton({
//        previewImage: $previewImage,
//        state: $state,
//        isThirdPartyCall: $isThirdPartyCall,
//        isStartVideo: $isStartVideo,
//        isBigVideoTimerVisible: $isBigVideoTimerVisible,
//        isSmallVideoTimerVisible: $isSmallVideoTimerVisible,
//        isResumeVideo: $isResumeVideo,
//        iscContinueVideo: $iscContinueVideo,
//        isShowFlashBlack: $isShowFlashBlack,
//        xComponentChangeFlag: $xComponentChangeFlag,
//        videoState: $videoState,
//        XcomponentWidth: $XcomponentWidth,
//        XcomponentHeight: $XcomponentHeight
//      })
//      if (this.isVisible) {
//        CameraSwitchButton({
//          surfaceId: $surfaceId,
//          cameraPosition: $cameraPosition,
//          btnSwitch: $btnSwitch,
//          btnSwitchSec: $btnSwitchSec,
//          btnOpacity_first: $btnOpacity_first,
//          btnOpacity_sec: $btnOpacity_sec,
//          xComponentChangeFlag: $xComponentChangeFlag,
//          previewImage: $previewImage,
//          cameraId: $cameraId,
//          isSwitchBackground: $isSwitchBackground,
//          videoState: $videoState,
//          cameraDevice: $cameraDevice,
//          state: $state
//        })
//      } else {
//        Column() {
//        }
//        .width('40')
//        .aspectRatio(1)
//      }
//    }
//    .height(96)
//    .opacity(100)
//    .width('100%')
//    .padding({ top: 10, bottom: 10 })
//  }
}
