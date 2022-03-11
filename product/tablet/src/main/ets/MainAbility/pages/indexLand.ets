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

import {TabBarLand} from './TabBarLand.ets'
import {FootBarLand} from './FootBarLand.ets'
import {PreviewAreaLand} from './PreviewAreaLand.ets'
import {ControlLand} from './ControlLand.ets'
import {ZoomView} from './ZoomView.ets';
import {ModeConfig} from '../common/ModeConfig.ets'
import {EventBus} from '../../../../../../../common/src/main/ets/default/Utils/EventBus.ets'
import {EventBusManager} from '../../../../../../../common/src/main/ets/default/Utils/EventBusManager.ets'
import router from '@system.router';
import RdbStoreManager from '../../../../../../../common/src/main/ets/default/Utils/RdbStoreManager.ets'
import bundle from '@ohos.bundle';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import display from '@ohos.display';

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
  @State permissionFlag: boolean = globalThis.permissionFlag
  @State videoState: string = 'beforeTakeVideo'
  @State footBarWidth: number = 0

  private aboutToAppear() {
    console.info('Camera indexLand aboutToAppear')
    display.getDefaultDisplay().then((dis) => {
      console.info("dis data=" + JSON.stringify(dis))
      this.footBarWidth = px2vp(dis.height - dis.height * 0.14) * (4 / 3) - 100
    })
    if (!this.permissionFlag) {
      let permissionList: Array<string> = [
        "ohos.permission.MEDIA_LOCATION",
        "ohos.permission.READ_MEDIA",
        "ohos.permission.WRITE_MEDIA",
        "ohos.permission.CAMERA",
        "ohos.permission.MICROPHONE"
      ];
      bundle.getApplicationInfo('com.ohos.camera', 0, 100).then((appInfo) => {
        console.info("appInfo bundle getApplicationInfo start")
        let tokenId = appInfo.accessTokenId
        console.info("appInfo bundle: " + tokenId)
        let statusPromise: Array<Promise<number>> = []
        let requestList: Array<string> = []
        let atManager = abilityAccessCtrl.createAtManager()
        console.info("appInfo atManager : " + JSON.stringify(atManager))
        for (let i = 0; i < permissionList.length; i++) {
          statusPromise.push(atManager.verifyAccessToken(tokenId, permissionList[i]))
        }
        console.info("appInfo statusPromise")
        Promise.all(statusPromise).then((status) => {
          console.info("appInfo Promise.all" + JSON.stringify(status))
          for (let i = 0; i < status.length; i++) {
            if (status[i] == -1) {
              requestList.push(permissionList[i])
            }
          }
          console.info("appInfo requestList: " + requestList.length)
          if (requestList.length != 0) {
            console.info("appInfo requestList: " + JSON.stringify(requestList))
            console.info("appInfo requestList.length: " + requestList.length)
            console.info('permissions need to require from user: ' + requestList)
            globalThis.cameraAbilityContext.requestPermissionsFromUser(requestList).then(function (data) {
              console.info("data data: " + JSON.stringify(data))
              console.info('data permissions: ' + data.permissions)
              console.info('data result: ' + data.authResults)
              let sum = 0
              for (let i = 0; i < data.authResults.length; i++) {
                sum += data.authResults[i]
              }
              console.info("sum data: " + JSON.stringify(sum))
              if (sum >= -1) {
                globalThis.permissionFlag = true
              } else {
                globalThis.permissionFlag = false
              }
              console.info('request permissions result: ' + globalThis.permissionFlag)
            }, (err) => {
              console.error('Failed to start ability', err.code);
            });
          } else {
            console.info('check all permissions are granted.')
            this.permissionFlag = true
            globalThis.permissionFlag = true
          }
        })
      })
    }

    let dbStore = RdbStoreManager.getInstance();
    dbStore.initRdbConfig();


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
    console.info("onPageShow this.permissionFlag= " + this.permissionFlag + '  globalThis.permissionFlag = ' + globalThis.permissionFlag)
    this.permissionFlag = globalThis.permissionFlag
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.permissionFlag) {
        PreviewAreaLand({
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
        Stack({ alignContent: Alignment.BottomEnd }) {
          FootBarLand({
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
          ZoomView({
            previewImage: $previewImage,
            cameraPosition: $cameraPosition,
            isShowZoomText: $isShowZoomText,
            zoomValue: $zoomValue,
            isPhotoZoomDetails: $isPhotoZoomDetails,
            zoomPercentage: $zoomPercentage,
            isPinchGesture: $isPinchGesture,
            maxZoomRatio: $maxZoomRatio,
            minZoomRatio: $minZoomRatio,
            pinchGestureTimer: $pinchGestureTimer,
            onTouchDownTimer: $onTouchDownTimer,
            videoState: $videoState
          })
        }
        .zIndex(1)
        .width(244)
        .position({x: this.footBarWidth, y: 0})
        .height('100%')

        Column() {
          TabBarLand({
            previewImage: $previewImage,
            cameraPosition: $cameraPosition,
            tabItem: $tabItem
          })
        }
        .zIndex(3)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000')
  }
}