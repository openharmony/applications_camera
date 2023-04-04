/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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
import deviceInfo from '@ohos.deviceInfo'
import { ModeMap } from '../common/ModeMap';
import { Action }  from '@ohos/common/src/main/ets/default/redux/actions/Action'
import { CameraWorker }  from '@ohos/common/src/main/ets/default/worker/CameraWorker'
import { EventBus }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus'
import { EventBusManager }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager'
import { getStore, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store'
import { Log } from '@ohos/common/src/main/ets/default/utils/Log'
import { MoreList } from '@ohos/common/src/main/ets/default/featurecommon/moreList/moreList'
import { PersistType, PreferencesService } from '@ohos/common/src/main/ets/default/featurecommon/preferences/PreferencesService'
import { PlaySound } from '@ohos/common/src/main/ets/default/featurecommon/playsound/playSound'
import { RdbStoreManager } from '@ohos/common/src/main/ets/default/setting/storage/RdbStoreManager'
import { TabBar } from '@ohos/common/src/main/ets/default/featurecommon/tabbar/TabBar'
import { ZoomView } from '@ohos/common/src/main/ets/default/featurecommon/zoomview/ZoomView'
import { Control } from './Control'
import { FootBar } from './FootBar'
import { ModeConfig } from '../common/ModeConfig'
import { PreviewArea } from './PreviewArea'
import { SettingView } from './SettingView'
import abilityAccessCtrl from '@ohos.abilityAccessCtrl'

var cameraWorker = CameraWorker.getInstance(new ModeMap())

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
    curCameraPosition: state.CameraReducer.curCameraPosition,
    isShowPinch: state.ZoomReducer.isShowPinch,
    isShowPageView: state.SettingReducer.isShowSettingView,
    isInitiated: state.ModeReducer.isInitiated
  }
}

let indexDispatcher = (dispatch) => {
  return {
    initFootBarHeight: (footBarHeight: number) => {
      dispatch(Action.initFootBarHeight(footBarHeight))
    },
    setPermissionFlag: (permissionFlag: boolean) => {
      console.info(`CameraApp setPermissionFlag: ${permissionFlag}`)
      dispatch(Action.setPermissionFlag(permissionFlag))
    },
    initAction: (action: string) => {
      dispatch(Action.initAction(action))
    },
    initCameraPosition: (cameraPosition: string) => {
      dispatch(Action.setCameraPosition(cameraPosition))
    },
    initMode: (mode: string) => {
      dispatch(Action.initMode(mode))
    },
    changeTimeLapse: (isShowtimeLapse: boolean) => {
      dispatch(Action.changeTimeLapse(isShowtimeLapse))
    },
    stopRecording: () => {
      dispatch(Action.stopRecording())
      dispatch(Action.updateVideoState('beforeTakeVideo'))
      dispatch(Action.updateBigVideoTimerVisible(false))
      dispatch(Action.updateSmallVideoTimerVisible(false))
    },
    resetRecordingTime: () => {
      dispatch(Action.updateRecordingTime(0))
      dispatch(Action.updateRecordingTimeDisplay('00:00'))
    },
    hideSettingView: () => {
      dispatch(Action.showSettingView(false))
    },
    updateModeIndex: (index: number) => {
      dispatch(Action.updateModeIndex(index))
    },
    faCall: (isFaCall: boolean) => {
      dispatch(Action.faCall(isFaCall))
    },
    thirdPartyCall: (isThirdPartyCall: boolean, action: string) => {
      dispatch(Action.thirdPartyCall(isThirdPartyCall, action))
    }
  }
}

PersistentStorage.PersistProp("storageCameraId", "")

class StateStruct {
  permissionFlag
  mode
  curMode
  isBigVideoTimerVisible
  isSmallVideoTimerVisible
  videoState
  isShowtimeLapse
  isShowMoreList
  isThirdPartyCall
  showZoomLabelValue
  cameraPosition
  isShowPinch
  xComponentWidth
  xComponentHeight
  isShowPageView
  isInitiated
  initShowFlag
  curCameraPosition
  footBarHeight
  initFootBarHeight: Function
  setPermissionFlag: Function
  initAction: Function
  initCameraPosition: Function
  initMode: Function
  changeTimeLapse: Function
  stopRecording: Function
  resetRecordingTime: Function
  hideSettingView: Function
  updateModeIndex: Function
  faCall: Function
  thirdPartyCall: Function
}

@Entry
@Component
struct Index {
  private TAG: string = '[Index]:'
  private modeConfig: ModeConfig = new ModeConfig()
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  @State state: StateStruct = new StateStruct()
  private mPlaySound: PlaySound = PlaySound.getInstance()
  private modeArray: Array<string> = ['MULTI', 'PHOTO', 'VIDEO']
  protected mPreferencesService: PreferencesService = PreferencesService.getInstance()

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`)
    let dbStore = RdbStoreManager.getInstance()
    dbStore.initRdbConfig()
    getStore().connect(indexState, indexDispatcher)(this.state)

    display.getDefaultDisplay().then((dis) => {
      Log.info(`${this.TAG} dis data = ${JSON.stringify(dis)}`)
      let footBarHeight
      if (deviceInfo.deviceType === "default") {
        footBarHeight = px2vp(dis.width) * (4 / 3) - 160
      } else {
        footBarHeight = px2vp(dis.width) * (4 / 3) - 82
      }
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
        "ohos.permission.LOCATION_IN_BACKGROUND",
        "ohos.permission.APPROXIMATELY_LOCATION"
      ]
      Log.info(`${this.TAG} permissions need to require from user: ${JSON.stringify(permissionList)}`)
      let atManager = abilityAccessCtrl.createAtManager()
      try {
        // @ts-ignore
        atManager.requestPermissionsFromUser(globalThis.cameraAbilityContext, permissionList).then((data) => {
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
      } catch (error) {
        Log.info(`${this.TAG} catch error: ${JSON.stringify(error)}`)
      }
    }

    if (globalThis.cameraFormParam != undefined) {
      this.state.initAction(globalThis.cameraFormParam.action)
      this.state.initMode(globalThis.cameraFormParam.mode)
      globalThis.cameraFormParam = undefined
    }

    globalThis.stopCameraRecording = (() => {
      this.stopCameraRecording()
    })

    if (!this.state.isInitiated) {
      let initIndex = this.mPreferencesService.getModeValue(PersistType.FOR_AWHILE, 1)
      Log.info(`${this.TAG} initModeIndex: ${initIndex}`)
      this.state.initMode(this.modeArray[initIndex])
      this.state.updateModeIndex(initIndex)
    }

    Log.info(`${this.TAG} aboutToAppear X`)
  }

  onPageShow(): void {
    Log.info(`${this.TAG} onPageShow this.permissionFlag: ${this.state.permissionFlag} globalThis.permissionFlag: ${globalThis.permissionFlag}`)
    this.state.setPermissionFlag(globalThis.permissionFlag)
    let curCameraId = AppStorage.Get<string>('storageCameraId')
    if (curCameraId) this.state.initCameraPosition(curCameraId)
    this.state.resetRecordingTime()
    Log.info(`${this.TAG} onPageShow X`)
  }

  private onBackClicked() {
    Log.info(`${this.TAG} onBackClicked E`)
    this.terminateSelfWithResult()
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
  }

  onBackPress(): boolean {
    Log.info(`${this.TAG} onBackPress E`)
    if (this.state.isShowPageView) {
      this.state.hideSettingView()
      return true
    } else if (this.state.isShowtimeLapse) {
      this.state.changeTimeLapse(false)
      return true
    } else if (this.state.isThirdPartyCall) {
      this.terminateSelfWithResult()
    } else {
      if (this.state.videoState === 'startTakeVideo' || this.state.videoState === 'pauseTakeVideo') {
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
    if (this.state.videoState === 'startTakeVideo' || this.state.videoState === 'pauseTakeVideo') {
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
          "resourceUri": "",
          "width": "",
          "height": ""
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
      Stack() {
        PreviewArea()
      }.width('100%').position({ y: 48 })

      Stack() {
        if (deviceInfo.deviceType !== "default" && this.state.videoState === "beforeTakeVideo" && !this.state.isShowtimeLapse && this.state.showZoomLabelValue) {
          TabBar({ onBackClicked: () => this.onBackClicked() })
        }
      }.width('100%').height(48).position({ x: '0', y: '0' })

      if (this.state.isShowMoreList && this.state.showZoomLabelValue) {
        MoreList()
      }
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          if (this.state.mode === "PHOTO" || this.state.mode === "VIDEO") {
            if (deviceInfo.deviceType !== "default" && this.state.curCameraPosition !== 'FRONT') {
              Column() {
                ZoomView()
              }
              .visibility(!this.state.isShowtimeLapse && !this.state.isShowPinch ? Visibility.Visible : Visibility.Hidden)
            }
          }
          if (this.state.videoState === "beforeTakeVideo" && this.state.showZoomLabelValue) {
            Column() {
              Control()
            }
            .visibility((!this.state.isShowtimeLapse && this.state.showZoomLabelValue) ? Visibility.Visible : Visibility.Hidden)
            .width('100%')
          }
          Column() {
            FootBar()
          }
          .visibility((!this.state.isShowtimeLapse && this.state.showZoomLabelValue) ? Visibility.Visible : Visibility.Hidden)
        }
      }.width('100%').height(302).position({ y: this.state.footBarHeight })
      .visibility(!this.state.isShowtimeLapse ? Visibility.Visible : Visibility.Hidden)

      if (this.state.isShowPageView) {
        SettingView().width('100%').height('100%')
      }
    }.width('100%').height('100%').backgroundColor('#000')
  }
}