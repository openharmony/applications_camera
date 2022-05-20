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
import { CameraWorker } from '../../../../../../common/src/main/ets/default/Utils/CameraWorker'
import { CLog } from '../../../../../../common/src/main/ets/default/Utils/CLog'
import { EventBus } from '../../../../../../common/src/main/ets/default/Utils/EventBus'
import EventBusManager from '../../../../../../common/src/main/ets/default/Utils/EventBusManager'
import { FootBarLand } from './FootBarLand'
import getStore from '../../../../../../common/src/main/ets/default/redux/store'
import { ModeConfig } from '../common/ModeConfig'
import {MoreList
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/moreList/moreList'
import { PlaySound
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/playSound/playSound'
import { PreviewAreaLand } from './PreviewAreaLand'
import RdbStoreManager from '../../../../../../common/src/main/ets/default/Utils/RdbStoreManager'
import ScreenLockManager from '../../../../../../common/src/main/ets/default/Utils/ScreenLockManager'
import { TabBarLand
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/tabBar/TabBarLand'
import { ZoomViewLand
} from '../../../../../../features/featurecommon/src/main/ets/com/ohos/featurecommon/zoomView/ZoomViewLand'

var mScreenLockManager = new ScreenLockManager()
var cameraWorker = CameraWorker.getInstance()

let indexState = (state) => {
  return {
    footBarWidth: state.ContextReducer.footBarWidth,
    permissionFlag: state.ContextReducer.permissionFlag,
    mode: state.ModeReducer.mode,
    curMode: state.ModeReducer.curMode,
    isBigVideoTimerVisible: state.UiReducer.isBigVideoTimerVisible,
    isSmallVideoTimerVisible: state.UiReducer.isSmallVideoTimerVisible,
    videoState: state.RecordReducer.videoState,
    isShowtimeLapse: state.UiReducer.isShowtimeLapse,
    isShowMoreList: state.UiReducer.isShowMoreList
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
      dispatch(Action.InitMode(mode))
    },
    changeTimeLapse: (isShowtimeLapse: boolean) => {
      dispatch(Action.changeTimeLapse(isShowtimeLapse))
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
  private mConnect: any

  private aboutToAppear(): void {
    CLog.info(`${this.TAG} aboutToAppear E`)
    let dbStore = RdbStoreManager.getInstance()
    dbStore.initRdbConfig()
    mScreenLockManager.init()
    this.mConnect = getStore().connect(indexState, indexDispatcher)(this.state)

    display.getDefaultDisplay().then((dis) => {
      CLog.info(`${this.TAG} dis data = ${JSON.stringify(dis)}`)
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
      CLog.info(`${this.TAG} permissions need to require from user: ${JSON.stringify(permissionList)}`)
      globalThis.cameraAbilityContext.requestPermissionsFromUser(permissionList).then((data) => {
        CLog.info(`${this.TAG} data permissions: ${JSON.stringify(data.permissions)}`)
        CLog.info(`${this.TAG} data authResult: ${JSON.stringify(data.authResults)}`)
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
        CLog.info(`${this.TAG} request permissions result: ${globalThis.permissionFlag}`)
      }, (err) => {
        CLog.error(`${this.TAG} Failed to start ability err code: ${err.code}`)
      });
    }

    if (globalThis.cameraFormParam != undefined) {
      this.state.initAction(globalThis.cameraFormParam.action)
      this.state.initMode(globalThis.cameraFormParam.mode)
      globalThis.cameraFormParam = undefined
    }

    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  private onPageShow(): void {
    console.info("onPageShow this.permissionFlag= " + this.state.permissionFlag + '  globalThis.permissionFlag = ' + globalThis.permissionFlag)
    this.state.setPermissionFlag(globalThis.permissionFlag)
  }

  private aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  private onBackPress() {
    CLog.info(`${this.TAG} onBackPress E isShowtimeLapse= ${this.state.isShowtimeLapse}`)
    if (this.state.isShowtimeLapse) {
      this.state.changeTimeLapse(false)
      return true
    }
    CLog.info(`${this.TAG} onBackPress X`)
    return false
  }

  private onPageHide(): void {
    CLog.info(`${this.TAG} onPageHide E isShowtimeLapse= ${this.state.isShowtimeLapse}`)
    this.state.changeTimeLapse(false)
    CLog.info(`${this.TAG} onPageHide X`)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.state.permissionFlag) {
        PreviewAreaLand()
        if (!this.state.isShowtimeLapse) {
          Column() {
            if (this.state.mode === "PHOTO" || this.state.mode === "VIDEO") {
              ZoomViewLand()
            } else {
              Column() {
              }.width(100).margin({ right: '20vp' })
            }
          }.zIndex(2).position({
            x: this.state.videoState === "beforeTakeVideo" ? (this.state.footBarWidth - 100) : (this.state.footBarWidth - 42),
            y: 0
          }).height('100%')
          Column(){
            FootBarLand()
          }.zIndex(2).position({ x: (this.state.footBarWidth + 32), y: 0 }).height('100%')
          Column() {
            if (this.state.videoState === "beforeTakeVideo" && !this.state.isShowtimeLapse) {
              TabBarLand()
            }
          }.zIndex(3)
          if(this.state.isShowMoreList){
            Column() {
              MoreList()
            }.zIndex(1).height('100%').width('100%')
          }
        }
      }
    }.width('100%').height('100%').backgroundColor('#000')
  }
}