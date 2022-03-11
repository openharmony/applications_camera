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

import {FootBar} from './FootBar.ets'
import {Control} from './Control.ets'
import {PreviewArea} from './PreviewArea.ets'
import {TabBar} from './TabBar.ets'
import {ZoomView} from './ZoomView.ets';
import {BigVideoTimer} from './BigVideoTimer.ets'
import {SmallVideoTimer} from './SmallVideoTimer.ets'
import {ModeConfig} from '../common/ModeConfig.ets'
import {EventBus} from '../../../../../../../common/src/main/ets/default/Utils/EventBus.ets'
import {EventBusManager} from '../../../../../../../common/src/main/ets/default/Utils/EventBusManager.ets'
import router from '@system.router';

@Entry
@Component
struct Index {
  private modeConfig: ModeConfig = new ModeConfig()
  private currentMode: string
  @State tabItem: string[] = ['', 'flash', 'zoom', 'focus', 'setup']
  @State aspectRatio: number = 4 / 3
  @State previewImage: string = 'PHOTO'
  appEventBus: EventBus = EventBusManager.getMainInstance().getEventBus()
  @State state: any = {}
  @State deviceHeight: number = 0
  @State isBigVideoTimerVisible: boolean = false
  @State isSmallVideoTimerVisible: boolean = false
  @State surfaceId: number = 0
  @State cameraPosition: string = 'ORIGIN'
  @State isThirdPartyCall: boolean = false
  @State isResumeVideo: boolean = false
  @State iscContinueVideo: boolean = false
  @State isShowZoomText: boolean = false
  @State zoomValue: number = 1
  @State isPhotoZoomDetails: boolean = false
  @State zoomPercentage: number = 0
  @State isPinchGesture: boolean = false
  @State maxZoomRatio: number = 0
  @State minZoomRatio: number = 0
  @State pinchGestureTimer: number = 0
  @State onTouchDownTimer: number = 0
  @State XcomponentWidth: string = ''
  @State XcomponentHeight: string = ''
  @State action: string = ''
  @State isShowFlashBlack: boolean = false
  @State btnSwitch: boolean = false
  @State btnSwitchSec: boolean = false
  @State btnOpacity_first: number = 1
  @State btnOpacity_sec: number = 0
  @State xComponentChangeFlag: boolean = true
  @State curCameraPosition: string = 'BACK'
  @State curPreviewImage: string = 'PHOTO'
  @State cameraId: string = ''
  @State isStartVideo: boolean = false
  @State isSwitchBackground: boolean = false
  @State permissionFlag :boolean = globalThis.permissionFlag
  @State videoState: string = 'beforeTakeVideo'
  private aboutToAppear() {
    console.info('Camera index aboutToAppear')
    let permissionList:Array<string> = [
      "ohos.permission.MEDIA_LOCATION",
      "ohos.permission.READ_MEDIA",
      "ohos.permission.WRITE_MEDIA",
      "ohos.permission.CAMERA",
      "ohos.permission.MICROPHONE"
    ];
    if(!this.permissionFlag){
      globalThis.cameraAbilityContext.requestPermissionsFromUser(permissionList).then(function(data) {
        console.info('data permissions: ' + data.permissions)
        console.info('data result: ' + data.authResults)
        let sum = 0
        for (let i = 0; i < data.authResults.length; i++) {
          sum += data.authResults[i]
        }
        console.info('data sum: ' + sum)
        if(sum >= -1){
          globalThis.permissionFlag = true
        }else {
          globalThis.permissionFlag = false
        }
        console.info('request permissions result: ' + globalThis.permissionFlag )
      }, (err) => {
        console.error('Failed to start ability', err.code);
      });
    }


    if (globalThis.cameraFormParam !== undefined) {
      this.action = globalThis.cameraFormParam.action
      this.cameraPosition = 'ORIGIN'
      this.curCameraPosition = 'BACK'
      this.previewImage = globalThis.cameraFormParam.previewImage
      this.curPreviewImage = this.previewImage
      globalThis.cameraFormParam = undefined
    }

    console.info("indexLand router.getParams()= " + JSON.stringify(router.getParams()))
    if (router.getParams() != undefined) {
      this.cameraPosition = router.getParams().position
      this.previewImage = router.getParams().mode
    }

    this.appEventBus.on('tabItem', (tabItem: string[]) => {
      this.tabItem = tabItem
      console.info(`UI thread get the tabItem: ${this.tabItem}`)
    })
  }

  private onPageShow() {
    console.info("onPageShow11 this.permissionFlag= " + this.permissionFlag+'  globalThis.permissionFlag = '+globalThis.permissionFlag)
    this.permissionFlag = globalThis.permissionFlag
  }
  build() {
    Stack({ alignContent: Alignment.Top }) {
      PreviewArea({
        aspectRatio: $aspectRatio,
        previewImage: $previewImage,
        state: $state,
        isSmallVideoTimerVisible: $isSmallVideoTimerVisible,
        isBigVideoTimerVisible: $isBigVideoTimerVisible,
        surfaceId: $surfaceId,
        cameraPosition: $cameraPosition,
        isResumeVideo: $isResumeVideo,
        iscContinueVideo: $iscContinueVideo,
        isShowZoomText: $isShowZoomText,
        zoomValue: $zoomValue,
        isPhotoZoomDetails: $isPhotoZoomDetails,
        zoomPercentage: $zoomPercentage,
        isPinchGesture: $isPinchGesture,
        maxZoomRatio: $maxZoomRatio,
        minZoomRatio: $minZoomRatio,
        pinchGestureTimer: $pinchGestureTimer,
        onTouchDownTimer: $onTouchDownTimer,
        XcomponentWidth: $XcomponentWidth,
        XcomponentHeight: $XcomponentHeight,
        isShowFlashBlack: $isShowFlashBlack,
        btnSwitch: $btnSwitch,
        btnSwitchSec: $btnSwitchSec,
        btnOpacity_first: $btnOpacity_first,
        btnOpacity_sec: $btnOpacity_sec,
        xComponentChangeFlag: $xComponentChangeFlag,
        curCameraPosition: $curCameraPosition,
        curPreviewImage: $curPreviewImage,
        cameraId: $cameraId,
        isStartVideo: $isStartVideo,
        isSwitchBackground: $isSwitchBackground
      })
      if (this.isBigVideoTimerVisible) {
        BigVideoTimer({
          isSmallVideoTimerVisible: $isSmallVideoTimerVisible,
          isBigVideoTimerVisible: $isBigVideoTimerVisible,
          isResumeVideo: $isResumeVideo,
          iscContinueVideo: $iscContinueVideo
        })
      }
      Stack({ alignContent: Alignment.Bottom }) {
        Stack() {
          TabBar({
            previewImage: $previewImage,
            cameraPosition: $cameraPosition,
            tabItem: $tabItem
          })
          if(this.isSmallVideoTimerVisible) {
            SmallVideoTimer({
              isResumeVideo: $isResumeVideo,
              iscContinueVideo: $iscContinueVideo
            })
          }
        }
        .width('100%')
          .height(48)
          .position({ x: '0', y: '0' })
        Column() {
          ZoomView({
            previewImage: $previewImage,
            isShowZoomText: $isShowZoomText,
            zoomValue: $zoomValue,
            isPhotoZoomDetails: $isPhotoZoomDetails,
            zoomPercentage: $zoomPercentage,
            isPinchGesture: $isPinchGesture,
            maxZoomRatio: $maxZoomRatio,
            minZoomRatio: $minZoomRatio,
            pinchGestureTimer: $pinchGestureTimer,
            onTouchDownTimer: $onTouchDownTimer,
            videoState: $videoState,
            cameraPosition: $cameraPosition
          })
          Control({
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
          FootBar({
            previewImage: $previewImage,
            surfaceId: $surfaceId,
            cameraPosition: $cameraPosition,
            isThirdPartyCall: $isThirdPartyCall,
            isBigVideoTimerVisible: $isBigVideoTimerVisible,
            isSmallVideoTimerVisible: $isSmallVideoTimerVisible,
            isResumeVideo: $isResumeVideo,
            iscContinueVideo: $iscContinueVideo,
            isShowFlashBlack: $isShowFlashBlack,
            btnSwitch: $btnSwitch,
            btnSwitchSec: $btnSwitchSec,
            btnOpacity_first: $btnOpacity_first,
            btnOpacity_sec: $btnOpacity_sec,
            xComponentChangeFlag: $xComponentChangeFlag,
            cameraId: $cameraId,
            isStartVideo: $isStartVideo,
            isSwitchBackground: $isSwitchBackground,
            videoState: $videoState
          })
        }
      }
      .width('100%')
       .height('100%')
    }
    .width('100%')
      .height('100%')
      .backgroundColor('#000')
  }
}