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

import display from '@ohos.display';
import { Action }  from '@ohos/common/src/main/ets/default/redux/actions/Action'
import { CameraWorker }  from '@ohos/common/src/main/ets/default/worker/CameraWorker'
import { ComponentPosition }  from '@ohos/common/src/main/ets/default/utils/ComponentPosition'
import { Constants }  from '@ohos/common/src/main/ets/default/utils/Constants'
import type { EventBus }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus'
import { EventBusManager }  from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager'
import { getStore, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store'
import { Log } from '@ohos/common/src/main/ets/default/utils/Log'
import { MoreList } from '@ohos/common/src/main/ets/default/featurecommon/moreList/moreList'
import { PersistType, PreferencesService } from '@ohos/common/src/main/ets/default/featurecommon/preferences/PreferencesService'
import { RdbStoreManager } from '@ohos/common/src/main/ets/default/setting/storage/RdbStoreManager'
import { PlaySound } from '@ohos/common/src/main/ets/default/featurecommon/playsound/playSound'
import { ScreenLockManager } from '@ohos/common/src/main/ets/default/featurecommon/screenlock/ScreenLockManager'
import { TabBarLand } from '@ohos/common/src/main/ets/default/featurecommon/tabbar/TabBarLand'
import { ZoomViewLand } from '@ohos/common/src/main/ets/default/featurecommon/zoomview/ZoomViewLand'
import { FootBarLand } from './FootBarLand'
import { ModeConfig } from '../common/ModeConfig'
import { PreviewAreaLand } from './PreviewAreaLand'
import { SettingView } from './SettingView'
import abilityAccessCtrl from '@ohos.abilityAccessCtrl'
import { ModeMap } from '../common/ModeMap';

var cameraWorker = CameraWorker.getInstance(new ModeMap())
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
    },
    thirdPartyCall: (isThirdPartyCall: boolean, action: string) => {
      dispatch(Action.thirdPartyCall(isThirdPartyCall, action))
    },
    resetZoomRatio: () => {
      dispatch(Action.changeZoomRatio(1))
    },
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
  initFootBarHeight: Function
  setPermissionFlag: Function
  initAction: Function
  initCameraPosition: Function
  initMode: Function
  changeTimeLapse: Function
  stopRecording: Function
  resetRecordingTime: Function
  resetZoomRatio
  hideSettingView: Function
  updateModeIndex: Function
  faCall: Function
  thirdPartyCall: Function
}

type ScreenSizeType = {
  width: number
  height: number
}

@Entry
@Component
struct Index {
  private TAG: string = '[IndexLand]:'
  private modeConfig: ModeConfig = new ModeConfig()
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  @State state: StateStruct = new StateStruct()
  @State screenSize: ScreenSizeType = { width: 0, height: 0 }
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
        });
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

    globalThis.resetZoomRatio = (() => {
      this.state.resetZoomRatio()
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
    if (cameraId) this.state.initCameraPosition(cameraId)
    Log.info(`${this.TAG} initCameraPosition ${cameraId}`)
    this.state.resetRecordingTime()
    Log.info(`${this.TAG} onPageShow X`)
  }

  private onBackClicked() {
    Log.info(`${this.TAG} onBackClicked E`)
    this.terminateSelfWithResult()
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
    };

    globalThis.cameraAbilityContext.terminateSelfWithResult(abilityResult, (error, data) => {
      if (error) {
        Log.error(`${this.TAG} Operation failed. Cause: ${error}`);
        return;
      }
      Log.info(`${this.TAG} Operation succeeded: ${data}`);
    });
  }

  private componentVisibility(condition: boolean): Visibility {
    return (!this.state.isShowtimeLapse && this.state.initShowFlag && condition) ? Visibility.Visible : Visibility.Hidden
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        PreviewAreaLand({ screenSize: $screenSize })
      }
      .position(this.state.isThirdPartyCall ? ComponentPosition.previewTabletPosition(this.screenSize.width, this.screenSize.height,
      this.state.xComponentWidth, this.state.xComponentHeight) : ComponentPosition.previewPosition(this.screenSize.width, this.screenSize.height,
      this.state.xComponentWidth, this.state.xComponentHeight))

      Column() {
        if ((this.state.mode === "PHOTO" || this.state.mode === "VIDEO") && this.state.cameraPosition !== 'FRONT') {
          ZoomViewLand()
        } else {
          Column() {
          }.width(82).margin({ right: '20vp' })
        }
      }.zIndex(2).height('100%')
      .position(this.state.isThirdPartyCall ? {
                                                x: 984,
                                                y: 0
                                              } : ComponentPosition.zoomViewPosition(this.screenSize.width, this.screenSize.height,
      this.state.xComponentWidth, this.state.xComponentHeight, this.state.videoState))
      .visibility(this.componentVisibility(!this.state.isShowPinch))

      Column() {
        FootBarLand({ screenSize: $screenSize })
      }.zIndex(2).height('100%')
      .position(this.state.isThirdPartyCall ? {
                                                x: 1124,
                                                y: 0
                                              } : ComponentPosition.footBarPosition(this.screenSize.width, this.screenSize.height,
      this.state.xComponentWidth, this.state.xComponentHeight))
      .visibility(this.componentVisibility(this.state.showZoomLabelValue))

      Column() {
        TabBarLand({ onBackClicked: () => this.onBackClicked(), screenSize: $screenSize })
      }.zIndex(3)
      .visibility(this.componentVisibility(this.state.videoState === "beforeTakeVideo" && this.state.showZoomLabelValue))
      .position(this.state.isThirdPartyCall ? {
                                                x: 0,
                                                y: 44
                                              } : ComponentPosition.tabBarPosition(this.screenSize.width, this.screenSize.height,
      this.state.xComponentWidth, this.state.xComponentHeight))
      .height(712)

      if (this.state.isShowMoreList) {
        Column() {
          MoreList()
        }.zIndex(1).height('100%').width('100%')
        .visibility(this.componentVisibility(this.state.showZoomLabelValue))
      }
      if (this.state.isShowPageView) {
        SettingView().width('100%').height('100%').zIndex(4)
      }
    }.width('100%').height('100%').backgroundColor('#000')
  }
}