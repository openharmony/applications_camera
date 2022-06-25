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

import display from '@ohos.display';

import { Action } from '../../../../../../common/src/main/ets/default/redux/actions/Action'
import { CameraWorker } from '../../../../../../common/src/main/ets/default/worker/CameraWorker'
import { Log } from '../../../../../../common/src/main/ets/default/utils/Log'
import { EventBus } from '../../../../../../common/src/main/ets/default/worker/eventbus/EventBus'
import EventBusManager from '../../../../../../common/src/main/ets/default/worker/eventbus/EventBusManager'
import { FootBarLand } from './FootBarLand'
import getStore, { OhCombinedState } from '../../../../../../common/src/main/ets/default/redux/store'
import { ModeConfig } from '../common/ModeConfig'
import {MoreList
} from '../../../../../../common/src/main/ets/default/featurecommon/moreList/moreList'
import { PlaySound
} from '../../../../../../common/src/main/ets/default/featurecommon/playSound/playSound'
import { PreviewAreaLand } from './PreviewAreaLand'
import RdbStoreManager from '../../../../../../common/src/main/ets/default/setting/storage/RdbStoreManager'
import ScreenLockManager from '../../../../../../common/src/main/ets/default/featurecommon/screenlock/ScreenLockManager'
import { TabBarLand
} from '../../../../../../common/src/main/ets/default/featurecommon/tabBar/TabBarLand'
import { ZoomViewLand
} from '../../../../../../common/src/main/ets/default/featurecommon/zoomView/ZoomViewLand'

var mScreenLockManager = new ScreenLockManager()
var cameraWorker = CameraWorker.getInstance()

let indexState = (state: OhCombinedState) => {
  return {
    footBarWidth: state.ContextReducer.footBarWidth,
    permissionFlag: state.ContextReducer.permissionFlag,
    mode: state.ModeReducer.mode,
    curMode: state.ModeReducer.curMode,
    isBigVideoTimerVisible: state.RecordReducer.isBigVideoTimerVisible,
    isSmallVideoTimerVisible: state.RecordReducer.isSmallVideoTimerVisible,
    videoState: state.RecordReducer.videoState,
    isShowtimeLapse: state.SettingReducer.isShowtimeLapse,
    isShowMoreList: state.ModeReducer.isShowMoreList,
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall,
    showZoomLabelValue: state.ZoomReducer.showZoomLabelValue,
  }
}

let indexDispatcher = (dispatch) => {
  return {
    initFootBarWidth: (footBarWidth: number) => {
      dispatch(Action.InitFootBarWidth(footBarWidth))
    },
    setPermissionFlag: (permissionFlag: boolean) => {
      console.info(`CameraApp setPermissionFlag: ${permissionFlag}`)
      dispatch(Action.SetPermissionFlag(permissionFlag))
    },
    initAction: (action: string) => {
      dispatch(Action.InitAction(action))
    },
    initCameraPosition: (cameraPosition: string) => {
      dispatch(Action.SetCameraPosition(cameraPosition))
    },
    initMode: (mode: string) => {
      dispatch(Action.initMode(mode))
    },
    changeTimeLapse: (isShowtimeLapse: boolean) => {
      dispatch(Action.changeTimeLapse(isShowtimeLapse))
    },
    stopRecording: () => {
      dispatch(Action.stopRecording())
      dispatch(Action.UpdateVideoState('beforeTakeVideo'))
      dispatch(Action.UpdateBigVideoTimerVisible(false))
      dispatch(Action.UpdateSmallVideoTimerVisible(false))
    }
  }
}

@Entry
@Component
struct Index {
  private TAG: string = '[Index]:'
  private modeConfig: ModeConfig = new ModeConfig()
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  @State state: any = {}
  private mPlaySound: PlaySound = PlaySound.getInstance()
  @State isPageShown: boolean = false

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`)
    let dbStore = RdbStoreManager.getInstance()
    dbStore.initRdbConfig()
    mScreenLockManager.init()
    getStore().connect(indexState, indexDispatcher)(this.state)

    display.getDefaultDisplay().then((dis) => {
      Log.info(`${this.TAG} dis data = ${JSON.stringify(dis)}`)
      //      this.footBarWidth = px2vp(dis.height - 176) * (4 / 3) - 100
      //      globalThis.footBarWidth = px2vp(dis.width) - 270
//      let footBarWidth = px2vp(dis.width) - 270
      let footBarWidth = px2vp(dis.height) * (4 / 3)
      this.state.initFootBarWidth(footBarWidth)
    })

    if (!this.state.permissionFlag) {
      let permissionList: Array<string> = [
        "ohos.permission.MEDIA_LOCATION",
        "ohos.permission.READ_MEDIA",
        "ohos.permission.WRITE_MEDIA",
        "ohos.permission.CAMERA",
        "ohos.permission.MICROPHONE",
        "ohos.permission.DISTRIBUTED_DATASYNC",
        "ohos.permission.LOCATION",
        "ohos.permission.LOCATION_IN_BACKGROUND"
      ]
      Log.info(`${this.TAG} permissions need to require from user: ${JSON.stringify(permissionList)}`)
      globalThis.cameraAbilityContext.requestPermissionsFromUser(permissionList).then((data) => {
        Log.info(`${this.TAG} data permissions: ${JSON.stringify(data.permissions)}`)
        Log.info(`${this.TAG} data authResult: ${JSON.stringify(data.authResults)}`)
        let sum = 0
        for (let i = 0; i < data.authResults.length; i++) {
          sum += data.authResults[i]
        }
        if (sum >= 0) {
          globalThis.permissionFlag = true
          this.state.setPermissionFlag(true)
        } else {
          globalThis.permissionFlag = false
          this.state.setPermissionFlag(false)
        }
        Log.info(`${this.TAG} request permissions result: ${globalThis.permissionFlag}`)
      }, (err) => {
        Log.error(`${this.TAG} Failed to start ability err code: ${err.code}`)
      });
    }

    if (globalThis.cameraFormParam != undefined) {
      this.state.initAction(globalThis.cameraFormParam.action)
      this.state.initMode(globalThis.cameraFormParam.mode)
      globalThis.cameraFormParam = undefined
    }

    globalThis.stopCameraRecording = (() => {
      this.stopCameraRecording()
    })

    Log.info(`${this.TAG} aboutToAppear X`)
  }

  onPageShow(): void {
    Log.info(`${this.TAG} onPageShow this.permissionFlag: ${this.state.permissionFlag} globalThis.permissionFlag: ${globalThis.permissionFlag}`)
    this.isPageShown = true
    this.state.setPermissionFlag(globalThis.permissionFlag)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
  }

  onBackPress(): boolean {
    Log.info(`${this.TAG} onBackPress E`)
    if (this.state.isShowtimeLapse) {
      this.state.changeTimeLapse(false)
      return true
    } else if (this.state.isThirdPartyCall) {
      this.terminateSelfWithResult()
    } else {
      if(this.state.videoState === 'startTakeVideo' || this.state.videoState === 'pauseTakeVideo'){
        this.state.stopRecording()
        return true
      }
      Log.info(`${this.TAG} onBackPress X`)
      return false
    }
  }

  onPageHide(): void {
    Log.info(`${this.TAG} onPageHide E`)
    this.isPageShown = false
    this.stopCameraRecording()
    Log.info(`${this.TAG} onPageHide X`)
  }

  public stopCameraRecording() {
    Log.info(`${this.TAG} stopCameraRecording E`)
    if (this.state.isShowtimeLapse) {
      this.state.changeTimeLapse(false)
    }
    if (this.state.videoState === "startTakeVideo") {
      this.state.stopRecording()
    }
    Log.info(`${this.TAG} stopCameraRecording X`)
  }

  terminateSelfWithResult() {
    Log.info(`${this.TAG} terminateSelfWithResult start`)
    let abilityResult = {
      "resultCode": 200,
      "want": {
        "parameters": {
          "imagePath": ""
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

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.state.permissionFlag && this.isPageShown) {
        PreviewAreaLand()
        Column() {
          if (this.state.mode === "PHOTO" || this.state.mode === "VIDEO") {
            ZoomViewLand()
          } else {
            Column() {
            }.width(82).margin({ right: '20vp' })
          }
        }.zIndex(2).position({
          x: this.state.videoState === "beforeTakeVideo" ? (this.state.footBarWidth - 82) : (this.state.footBarWidth - 42),
          y: 0
        }).height('100%').visibility(!this.state.isShowtimeLapse ? Visibility.Visible : Visibility.Hidden)
        Column(){
          FootBarLand()
        }.zIndex(2).position({ x: (this.state.footBarWidth + 32), y: 0 }).height('100%')
          .visibility((!this.state.isShowtimeLapse && this.state.showZoomLabelValue) ? Visibility.Visible : Visibility.Hidden)
        Column() {
          if (this.state.videoState === "beforeTakeVideo" && !this.state.isShowtimeLapse && this.state.showZoomLabelValue) {
            TabBarLand()
          }
        }.zIndex(3).visibility(!this.state.isShowtimeLapse ? Visibility.Visible : Visibility.Hidden)
        if(this.state.isShowMoreList){
          Column() {
            MoreList()
          }.zIndex(1).height('100%').width('100%').visibility(!this.state.isShowtimeLapse ? Visibility.Visible : Visibility.Hidden)
        }
      }
    }.width('100%').height('100%').backgroundColor('#000')
  }
}