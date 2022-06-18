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

import display from '@ohos.display'

import { Action } from '../../../../../../common/src/main/ets/default/redux/actions/Action'
import { CameraWorker } from '../../../../../../common/src/main/ets/default/worker/CameraWorker'
import { Log } from '../../../../../../common/src/main/ets/default/utils/Log'
import { Control } from './Control'
import { EventBus } from '../../../../../../common/src/main/ets/default/worker/eventbus/EventBus'
import EventBusManager from '../../../../../../common/src/main/ets/default/worker/eventbus/EventBusManager'
import { FootBar } from './FootBar'
import getStore, { OhCombinedState } from '../../../../../../common/src/main/ets/default/redux/store'
import { ModeConfig } from '../common/ModeConfig'
import { MoreList
} from '../../../../../../common/src/main/ets/default/featurecommon/moreList/moreList'
import { PlaySound
} from '../../../../../../common/src/main/ets/default/featurecommon/playSound/playSound'
import { PreviewArea } from './PreviewArea'
import RdbStoreManager from '../../../../../../common/src/main/ets/default/setting/storage/RdbStoreManager'
import ScreenLockManager from '../../../../../../common/src/main/ets/default/featurecommon/screenlock/ScreenLockManager'
import { TabBar
} from '../../../../../../common/src/main/ets/default/featurecommon/tabBar/TabBar'
import { ZoomView
} from '../../../../../../common/src/main/ets/default/featurecommon/zoomView/ZoomView'

var mScreenLockManager = new ScreenLockManager()
var cameraWorker = CameraWorker.getInstance()

let indexState = (state: OhCombinedState) => {
  return {
    footBarHeight: state.ContextReducer.footBarHeight,
    permissionFlag: state.ContextReducer.permissionFlag,
    mode: state.ModeReducer.mode,
    curMode: state.ModeReducer.curMode,
    isShowtimeLapse: state.SettingReducer.isShowtimeLapse,
    videoState: state.RecordReducer.videoState,
    isShowMoreList: state.ModeReducer.isShowMoreList,
    isThirdPartyCall: state.ContextReducer.isThirdPartyCall,
    showZoomLabelValue: state.ZoomReducer.showZoomLabelValue,
  }
}

let indexDispatcher = (dispatch) => {
  return {
    initFootBarHeight: (footBarHeight: number) => {
      dispatch(Action.InitFootBarHeight(footBarHeight))
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

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`)
    let dbStore = RdbStoreManager.getInstance()
    dbStore.initRdbConfig()
    mScreenLockManager.init()
    getStore().connect(indexState, indexDispatcher)(this.state)

    display.getDefaultDisplay().then((dis) => {
      Log.info(`${this.TAG} dis data = ${JSON.stringify(dis)}`)
      let footBarHeight = px2vp(dis.width) * (4 / 3) - 160
      this.state.initFootBarHeight(footBarHeight)
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
      })
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
    console.info("onPageShow this.permissionFlag= " + this.state.permissionFlag + '  globalThis.permissionFlag = ' + globalThis.permissionFlag)
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
      if(this.state.videoState === 'startTakeVideo'){
        this.state.stopRecording()
        return true
      }
      Log.info(`${this.TAG} onBackPress X`)
      return false
    }
  }

  onPageHide(): void {
    Log.info(`${this.TAG} onPageHide E`)
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
    }

    globalThis.cameraAbilityContext.terminateSelfWithResult(abilityResult, (error, data) => {
      if (error) {
        Log.error(`${this.TAG} Operation failed. Cause: ${error}`)
        return;
      }
      Log.info(`${this.TAG} Operation succeeded: ${data}`)
    })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      if (this.state.permissionFlag) {
        Stack() {
          PreviewArea()
        }.width('100%').position({ x: '0', y: '48' })
        Stack() {
          if (this.state.videoState === "beforeTakeVideo" && !this.state.isShowtimeLapse && this.state.showZoomLabelValue) {
//            TabBar()
          }
        }.width('100%').height(48).position({ x: '0', y: '0' })
        if(this.state.isShowMoreList){
          MoreList()
        }
        Stack({alignContent: Alignment.Bottom}) {
          Column() {
            if (this.state.mode === "PHOTO" || this.state.mode === "VIDEO") {
//              ZoomView()
            }
            if (this.state.videoState === "beforeTakeVideo" && this.state.showZoomLabelValue) {
              Control()
            }
            FootBar()
          }
        }.width('100%').height(302).position({ y: this.state.footBarHeight })
          .visibility(!this.state.isShowtimeLapse ? Visibility.Visible : Visibility.Hidden)
      }
    }.width('100%').height('100%').backgroundColor('#000')
  }
}