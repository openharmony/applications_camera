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
import { Action } from '@ohos/common/src/main/ets/default/redux/actions/Action';
import { CameraWorker } from '@ohos/common/src/main/ets/default/worker/CameraWorker';
import { ComponentPosition } from '@ohos/common/src/main/ets/default/utils/ComponentPosition';
import { Constants } from '@ohos/common/src/main/ets/default/utils/Constants';
import { EventBus } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus';
import { EventBusManager } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager';
import { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store';
import { getStore } from '@ohos/common/src/main/ets/default/redux/store';
import { Log } from '@ohos/common/src/main/ets/default/utils/Log';
import { MoreList } from '@ohos/common/src/main/ets/default/featurecommon/moreList/moreList';
import {
  PersistType,
  PreferencesService
} from '@ohos/common/src/main/ets/default/featurecommon/preferences/PreferencesService';
import { RdbStoreManager } from '@ohos/common/src/main/ets/default/setting/storage/RdbStoreManager';
import { ScreenLockManager } from '@ohos/common/src/main/ets/default/featurecommon/screenlock/ScreenLockManager';
import { TabBarLand } from '@ohos/common/src/main/ets/default/featurecommon/tabbar/TabBarLand';
import { ZoomViewLand } from '@ohos/common/src/main/ets/default/featurecommon/zoomview/ZoomViewLand';
import { FootBarLand } from './FootBarLand';
import { PreviewAreaLand } from './PreviewAreaLand';
import { SettingView } from './SettingView';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { ModeMap } from '../common/ModeMap';
import { GlobalContext } from '@ohos/common/src/main/ets/default/utils/GlobalContext';
import { CameraId } from '@ohos/common/src/main/ets/default/setting/settingitem/CameraId';
import { BusinessError } from '@ohos.base';
import ability from '@ohos.ability.ability';

const DEFAULT_FUNCTION = () => {
}

CameraWorker.getInstance(new ModeMap());
let mScreenLockManager = new ScreenLockManager();

PersistentStorage.PersistProp("storageCameraId", "");

class StateStruct {
  permissionFlag: boolean = false;
  mode: string = '';
  curMode: string = '';
  isBigVideoTimerVisible: boolean = false;
  isSmallVideoTimerVisible: boolean = false;
  videoState: string = '';
  isShowtimeLapse: boolean = false;
  isShowMoreList: boolean = false;
  isThirdPartyCall: boolean = false;
  showZoomLabelValue: boolean = false;
  cameraPosition: CameraId = CameraId.FRONT;
  isShowPinch: boolean = false;
  xComponentWidth: number = 0;
  xComponentHeight: number = 0;
  isShowPageView: boolean = false;
  isInitiated: boolean = false;
  initShowFlag: boolean = false;
}

class IndexDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public setPermissionFlag(permissionFlag: boolean): void {
    Log.info(`CameraApp setPermissionFlag: ${permissionFlag}`);
    this.mDispatch(Action.setPermissionFlag(permissionFlag));
  }

  public initAction(action: string): void {
    this.mDispatch(Action.initAction(action));
  }

  public initCameraPosition(cameraPosition: string): void {
    this.mDispatch(Action.setCameraPosition(cameraPosition));
  }

  public initMode(mode: string): void {
    this.mDispatch(Action.initMode(mode));
  }

  public changeTimeLapse(isShowtimeLapse: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse));
  }

  public stopRecording(): void {
    this.mDispatch(Action.stopRecording());
    this.mDispatch(Action.updateVideoState('beforeTakeVideo'));
    this.mDispatch(Action.updateBigVideoTimerVisible(false));
    this.mDispatch(Action.updateSmallVideoTimerVisible(false));
  }

  public resetRecordingTime(): void {
    this.mDispatch(Action.updateRecordingTime(0));
    this.mDispatch(Action.updateRecordingTimeDisplay('00:00'));
  }

  public hideSettingView(): void {
    this.mDispatch(Action.showSettingView(false));
  }

  public updateModeIndex(index: number): void {
    this.mDispatch(Action.updateModeIndex(index));
  }

  public faCall(isFaCall: boolean): void {
    this.mDispatch(Action.faCall(isFaCall));
  }

  public updateInitShowFlag(initShowFlag: boolean): void {
    this.mDispatch(Action.updateInitShowFlag(initShowFlag))
  }

  public thirdPartyCall(isThirdPartyCall: boolean, action: string): void {
    this.mDispatch(Action.thirdPartyCall(isThirdPartyCall, action));
  }

  public resetZoomRatio(): void {
    this.mDispatch(Action.changeZoomRatio(1));
  }
}

interface ScreenSizeType {
  width: number
  height: number
}

@Entry
@Component
struct Index {
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State state: StateStruct = new StateStruct();
  @State screenSize: ScreenSizeType = { width: 0, height: 0 };
  protected mPreferencesService: PreferencesService = PreferencesService.getInstance();
  private TAG: string = '[IndexLand]:';
  private modeArray: Array<string> = ['PHOTO', 'VIDEO'];
  private mAction: IndexDispatcher = new IndexDispatcher();

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`);
    let dbStore = RdbStoreManager.getInstance();
    dbStore.initRdbConfig();
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        permissionFlag: state.contextReducer.permissionFlag,
        mode: state.modeReducer.mode,
        curMode: state.modeReducer.curMode,
        isBigVideoTimerVisible: state.recordReducer.isBigVideoTimerVisible,
        isSmallVideoTimerVisible: state.recordReducer.isSmallVideoTimerVisible,
        videoState: state.recordReducer.videoState,
        isShowtimeLapse: state.settingReducer.isShowtimeLapse,
        isShowMoreList: state.modeReducer.isShowMoreList,
        isThirdPartyCall: state.contextReducer.isThirdPartyCall,
        showZoomLabelValue: state.zoomReducer.showZoomLabelValue,
        cameraPosition: state.cameraReducer.cameraPosition,
        isShowPinch: state.zoomReducer.isShowPinch,
        xComponentWidth: state.previewReducer.xComponentWidth,
        xComponentHeight: state.previewReducer.xComponentHeight,
        isShowPageView: state.settingReducer.isShowSettingView,
        isInitiated: state.modeReducer.isInitiated,
        initShowFlag: state.contextReducer.initShowFlag
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    })

    mScreenLockManager.init();

    if (!this.state.permissionFlag) {
      let permissionList: Array<Permissions> = [
        "ohos.permission.MEDIA_LOCATION",
        "ohos.permission.READ_IMAGEVIDEO",
        "ohos.permission.WRITE_IMAGEVIDEO",
        "ohos.permission.CAMERA",
        "ohos.permission.MICROPHONE",
        "ohos.permission.DISTRIBUTED_DATASYNC",
        "ohos.permission.LOCATION",
        "ohos.permission.LOCATION_IN_BACKGROUND",
        "ohos.permission.APPROXIMATELY_LOCATION"
      ];
      Log.info(`${this.TAG} permissions need to require from user: ${JSON.stringify(permissionList)}`);
      let atManager = abilityAccessCtrl.createAtManager();
      try {
        atManager.requestPermissionsFromUser(GlobalContext.get().getCameraAbilityContext(), permissionList)
          .then((data) => {
            Log.info(`${this.TAG} data permissions: ${JSON.stringify(data.permissions)}`);
            Log.info(`${this.TAG} data authResult: ${JSON.stringify(data.authResults)}`);
            let sum = 0;
            for (let i = 0; i < data.authResults.length; i++) {
              sum += data.authResults[i];
            }
            if (sum >= 0) {
              GlobalContext.get().setObject('permissionFlag', true);
              this.mAction.setPermissionFlag(true);
            } else {
              GlobalContext.get().setObject('permissionFlag', false);
              this.mAction.setPermissionFlag(false);
            }
            Log.info(`${this.TAG} request permissions result: ${GlobalContext.get().getT<boolean>('permissionFlag')}`);
          }, (err: BusinessError) => {
            Log.error(`${this.TAG} Failed to start ability err code: ${err.code}`);
          });
      } catch (error) {
        Log.info(`${this.TAG} catch error: ${JSON.stringify(error)}`);
      }
    }

    if (GlobalContext.get().getCameraFormParam() != undefined) {
      this.mAction.initAction(GlobalContext.get().getCameraFormParam().action);
      this.mAction.initMode(GlobalContext.get().getCameraFormParam().mode);
      GlobalContext.get().setCameraFormParam(undefined);
    }

    GlobalContext.get().setObject('stopCameraRecording', () => {
      this.stopCameraRecording();
    })

    GlobalContext.get().setObject('resetZoomRatio', () => {
      this.mAction.resetZoomRatio();
    })

    if (AppStorage.Has(Constants.APP_KEY_WINDOW_SIZE)) {
      const screenSizeData: ScreenSizeType | undefined = AppStorage.Get(Constants.APP_KEY_WINDOW_SIZE);
      if (screenSizeData) {
        this.screenSize = screenSizeData;
      }
    } else {
      display.getDefaultDisplay().then((dis) => {
        this.screenSize.width = px2vp(dis.width);
        this.screenSize.height = px2vp(dis.height);
      })
    }

    if (!this.state.isInitiated) {
      let initIndex = this.mPreferencesService.getModeValue(PersistType.FOR_AWHILE, 1);
      Log.info(`${this.TAG} initModeIndex: ${initIndex}`);
      this.mAction.initMode(this.modeArray[initIndex]);
      this.mAction.updateModeIndex(initIndex);
    }

    Log.info(`${this.TAG} aboutToAppear X`);
  }

  onPageShow(): void {
    Log.info(`${this.TAG} onPageShow E this.permissionFlag: ${this.state.permissionFlag}
    globalThis.permissionFlag: ${GlobalContext.get().getT<boolean>('permissionFlag')}`);
    this.mAction.setPermissionFlag(GlobalContext.get().getT<boolean>('permissionFlag'));
    let cameraId = AppStorage.Get<string>('storageCameraId');
    if (cameraId) this.mAction.initCameraPosition(cameraId);
    Log.info(`${this.TAG} initCameraPosition ${cameraId}`);
    this.mAction.resetRecordingTime();
    Log.info(`${this.TAG} onPageShow X`);
  }

  onBackPress(): boolean {
    Log.info(`${this.TAG} onBackPress E`);
    if (this.state.isShowPageView) {
      this.mAction.hideSettingView();
      return true;
    } else if (this.state.isShowtimeLapse) {
      this.mAction.changeTimeLapse(false);
      return true;
    } else if (this.state.isThirdPartyCall) {
      this.terminateSelfWithResult();
      return true;
    } else {
      if (this.state.videoState === 'startTakeVideo' || this.state.videoState === 'pauseTakeVideo') {
        this.mAction.stopRecording();
        return true;
      }
      Log.info(`${this.TAG} onBackPress X`);
      return false;
    }
  }

  onPageHide(): void {
    Log.info(`${this.TAG} onPageHide E`);
    this.stopCameraRecording();
    Log.info(`${this.TAG} onPageHide X`);
  }

  public stopCameraRecording(): void {
    Log.info(`${this.TAG} stopCameraRecording E`);
    if (this.state.isShowtimeLapse) {
      this.mAction.changeTimeLapse(false);
    }
    if (this.state.videoState === 'startTakeVideo' || this.state.videoState === 'pauseTakeVideo') {
      this.mAction.stopRecording();
    }
    Log.info(`${this.TAG} stopCameraRecording X`);
  }

  terminateSelfWithResult(): void {
    Log.info(`${this.TAG} terminateSelfWithResult start`);
    let abilityResult: ability.AbilityResult = {
      resultCode: 200,
      want: {
        parameters: {
          resourceUri: "",
          width: "",
          height: ""
        },
        bundleName: "com.ohos.camera",
        abilityName: "com.ohos.camera.MainAbility"
      }
    };

    GlobalContext.get().getCameraAbilityContext().terminateSelfWithResult(abilityResult, (error: BusinessError, data: Object) => {
      if (error) {
        Log.error(`${this.TAG} Operation failed. Cause: ${error}`);
        return;
      }
      Log.info(`${this.TAG} Operation succeeded: ${data}`);
    });
  }

  private onBackClicked(): void {
    Log.info(`${this.TAG} onBackClicked E`);
    this.terminateSelfWithResult();
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