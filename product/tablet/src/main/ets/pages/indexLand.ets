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
} from '../../../../../../common/src/main/ets/default/featurecommon/playsound/playSound'
import { PreviewAreaLand } from './PreviewAreaLand'
import RdbStoreManager from '../../../../../../common/src/main/ets/default/setting/storage/RdbStoreManager'
import { TabBarLand
} from '../../../../../../common/src/main/ets/default/featurecommon/tabbar/TabBarLand'
import { ZoomViewLand
} from '../../../../../../common/src/main/ets/default/featurecommon/zoomview/ZoomViewLand'
import ComponentPosition from '../../../../../../common/src/main/ets/default/utils/ComponentPosition'
import { Constants } from '../../../../../../common/src/main/ets/default/utils/Constants';
import { SettingView } from './SettingView'
import { PreferencesService, PersistType
} from '../../../../../../common/src/main/ets/default/featurecommon/preferences/PreferencesService'
import ScreenLockManager from '../../../../../../common/src/main/ets/default/featurecommon/screenlock/ScreenLockManager'

var cameraWorker = CameraWorker.getInstance()
var mScreenLockManager = new ScreenLockManager()

let indexState = (state: OhCombinedState) => {
  return {
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
    cameraPosition: state.CameraReducer.cameraPosition,
    isShowPinch: state.ZoomReducer.isShowPinch,
    xComponentWidth: state.PreviewReducer.xComponentWidth,
    xComponentHeight: state.PreviewReducer.xComponentHeight,
    isShowPageView: state.SettingReducer.isShowSettingView,
    isInitiated: state.ModeReducer.isInitiated,
    initShowFlag: state.ContextReducer.initShowFlag
  }
}

let indexDispatcher = (dispatch) => {
  return {
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
    updateInitShowFlag: (initShowFlag: boolean) => {
      dispatch(Action.updateInitShowFlag(initShowFlag))
    }
  }
}

PersistentStorage.PersistProp("storageCameraId", "")

@Entry
@Component
struct Index {
  private TAG: string = '[Index]:'
  private modeConfig: ModeConfig = new ModeConfig()
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  @State state: any = {}
  @State screenSize: any = { width: 0, height: 0 }
  private mPlaySound: PlaySound = PlaySound.getInstance()
  private modeArray: Array<string> = ['MULTI', 'PHOTO', 'VIDEO']
  protected mPreferencesService: PreferencesService = PreferencesService.getInstance()

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`)
    let dbStore = RdbStoreManager.getInstance()
    dbStore.initRdbConfig()
    getStore().connect(indexState, indexDispatcher)(this.state)
    mScreenLockManager.init()

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

    if (AppStorage.Has(Constants.APP_KEY_WINDOW_SIZE)) {
      this.screenSize = AppStorage.Get(Constants.APP_KEY_WINDOW_SIZE)
    } else {
      display.getDefaultDisplay().then((dis) => {
        this.screenSize.width = px2vp(dis.width)
        this.screenSize.height = px2vp(dis.height)
      })
    }

    if (!this.state.isInitiated) {
      let initIndex = this.mPreferencesService.getModeValue(PersistType.FOR_AWHILE, 1)
      Log.info(`${this.TAG} initModeIndex: ${initIndex}`)
      this.state.initMode(this.modeArray[initIndex])
      this.state.updateModeIndex(initIndex)
    }

    Log.info(`${this.TAG} aboutToAppear X`)
  }

  onPageShow(): void {
    Log.info(`${this.TAG} onPageShow E this.permissionFlag: ${this.state.permissionFlag} globalThis.permissionFlag: ${globalThis.permissionFlag}`)
    this.state.setPermissionFlag(globalThis.permissionFlag)
    let cameraId = AppStorage.Get<string>('storageCameraId')
    if(cameraId) this.state.initCameraPosition(cameraId)
    Log.info(`${this.TAG} initCameraPosition ${cameraId}`)
    this.state.resetRecordingTime()
    this.calledByFa()
    Log.info(`${this.TAG} onPageShow X`)
  }

  private calledByFa(): void {
    Log.info(`${this.TAG} calledByFa invoke E`)
    let from: string = ""
    let uri: string = ""

    if (globalThis?.cameraNewWant) {
      Log.debug((`${this.TAG} cameraNewWant: ${JSON.stringify(globalThis.cameraNewWant)}`))
      if (globalThis.cameraNewWant?.parameters?.from) {
        from = globalThis.cameraNewWant.parameters.from
      }
      if (globalThis.cameraNewWant?.parameters?.uri) {
        uri = globalThis.cameraNewWant.parameters.uri
      }
    } else if (globalThis?.cameraAbilityWant) {
      Log.debug(`${this.TAG} cameraAbilityWant: ${JSON.stringify(globalThis.cameraAbilityWant)}`)
      if (globalThis.cameraAbilityWant?.parameters?.from) {
        from = globalThis.cameraAbilityWant.parameters.from
      }
      if (globalThis.cameraAbilityWant?.parameters?.uri) {
        uri = globalThis.cameraAbilityWant.parameters.uri
      }
    } else {
      return
    }
    Log.info(`${this.TAG} from: ${from}  uri: ${uri}`)

    if (from === "FA") {
      Log.info(`from === "FA"`)
      this.state.faCall(true)
      switch (uri) {
        case "capture":
          this.state.initMode('PHOTO')
          this.state.updateModeIndex(1)
          break
        case "video":
          this.state.initMode('VIDEO')
          this.state.updateModeIndex(2)
          break
        default:
          Log.info(`${this.TAG} FA default`)
          break
      }
    } else {
      this.state.faCall(false)
    }
    Log.info(`${this.TAG} calledByFa invoke X: ${this.state.mode}`)
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
    this.stopCameraRecording()
    this.state.updateInitShowFlag(false)
    Log.info(`${this.TAG} onPageHide X`)
  }

  public stopCameraRecording() {
    Log.info(`${this.TAG} stopCameraRecording E`)
    if (this.state.isShowtimeLapse) {
      this.state.changeTimeLapse(false)
    }
    if(this.state.videoState === 'startTakeVideo' || this.state.videoState === 'pauseTakeVideo') {
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
      if (this.state.permissionFlag) {
        Column() {
          PreviewAreaLand({ screenSize: $screenSize })
        }.position(ComponentPosition.previewPosition(this.screenSize.width, this.screenSize.height,
          this.state.xComponentWidth, this.state.xComponentHeight))

        if (!this.state.isShowtimeLapse && this.state.initShowFlag) {
          Column() {
            if ((this.state.mode === "PHOTO" || this.state.mode === "VIDEO") && this.state.cameraPosition !== 'FRONT') {
              ZoomViewLand()
            } else {
              Column() {
              }.width(82).margin({ right: '20vp' })
            }
          }.zIndex(2).height('100%')
          .position(ComponentPosition.zoomViewPosition(this.screenSize.width, this.screenSize.height,
            this.state.xComponentWidth, this.state.xComponentHeight, this.state.videoState))
          .visibility(!this.state.isShowPinch ? Visibility.Visible : Visibility.Hidden)

          Column(){
            FootBarLand({ screenSize: $screenSize })
          }.zIndex(2).height('100%')
          .position(ComponentPosition.footBarPosition(this.screenSize.width, this.screenSize.height,
            this.state.xComponentWidth, this.state.xComponentHeight))
          .visibility(this.state.showZoomLabelValue ? Visibility.Visible : Visibility.Hidden)

          Column() {
            TabBarLand()
          }.zIndex(3)
          .visibility(this.state.videoState === "beforeTakeVideo" && this.state.showZoomLabelValue ? Visibility.Visible
                                                                                                   : Visibility.Hidden)
          .position(ComponentPosition.tabBarPosition(this.screenSize.width, this.screenSize.height,
            this.state.xComponentWidth, this.state.xComponentHeight))

          if (this.state.isShowMoreList) {
            Column() {
              MoreList()
            }.zIndex(1).height('100%').width('100%')
            .visibility(this.state.showZoomLabelValue ? Visibility.Visible : Visibility.Hidden)
          }
        }
      }
      if (this.state.isShowPageView) {
        SettingView().width('100%').height('100%').zIndex(4)
      }
    }.width('100%').height('100%').backgroundColor('#000')
  }
}