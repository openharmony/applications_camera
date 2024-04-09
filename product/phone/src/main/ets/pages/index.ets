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
import deviceInfo from '@ohos.deviceInfo';
import { ModeMap } from '../common/ModeMap';
import { Action } from '@ohos/common/src/main/ets/default/redux/actions/Action';
import { CameraWorker } from '@ohos/common/src/main/ets/default/worker/CameraWorker';
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
import { TabBar } from '@ohos/common/src/main/ets/default/featurecommon/tabbar/TabBar';
import { ZoomView } from '@ohos/common/src/main/ets/default/featurecommon/zoomview/ZoomView';
import { Control } from './Control';
import { FootBar } from './FootBar';
import { PreviewArea } from './PreviewArea';
import { SettingView } from './SettingView';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { CameraId } from '@ohos/common/src/main/ets/default/setting/settingitem/CameraId';
import { BusinessError } from '@ohos.base';
import ability from '@ohos.ability.ability';
import { GlobalContext } from '@ohos/common/src/main/ets/default/utils/GlobalContext';

CameraWorker.getInstance(new ModeMap());

PersistentStorage.PersistProp("storageCameraId", "");

class StateStruct {
  footBarHeight: number = 0;
  permissionFlag: boolean = false;
  mode: string = '';
  curMode: string = '';
  isShowtimeLapse: boolean = false;
  videoState: string = '';
  isShowMoreList: boolean = false;
  isThirdPartyCall: boolean = false;
  showZoomLabelValue: boolean = true;
  isShowPinch: boolean = false;
  isShowPageView: boolean = false;
  isInitiated: boolean = false;
  curCameraPosition: CameraId = CameraId.BACK
}

class IndexDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public initFootBarHeight(footBarHeight: number): void {
    this.mDispatch(Action.initFootBarHeight(footBarHeight));
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
}

const ZOOM_HEIGHT = 140;

@Entry
@Component
struct Index {
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State state: StateStruct = new StateStruct();
  protected mPreferencesService: PreferencesService = PreferencesService.getInstance();
  private TAG: string = '[Index]:';
  private modeArray: Array<string> = ['PHOTO', 'VIDEO'];
  private mAction: IndexDispatcher = new IndexDispatcher();

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`);
    let dbStore: RdbStoreManager = RdbStoreManager.getInstance();
    dbStore.initRdbConfig();
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        footBarHeight: state.contextReducer.footBarHeight,
        permissionFlag: state.contextReducer.permissionFlag,
        mode: state.modeReducer.mode,
        curMode: state.modeReducer.curMode,
        isShowtimeLapse: state.settingReducer.isShowtimeLapse,
        videoState: state.recordReducer.videoState,
        isShowMoreList: state.modeReducer.isShowMoreList,
        isThirdPartyCall: state.contextReducer.isThirdPartyCall,
        showZoomLabelValue: state.zoomReducer.showZoomLabelValue,
        isShowPinch: state.zoomReducer.isShowPinch,
        isShowPageView: state.settingReducer.isShowSettingView,
        isInitiated: state.modeReducer.isInitiated,
        curCameraPosition: state.cameraReducer.curCameraPosition,
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    })
    display.getDefaultDisplay().then((dis) => {
      Log.info(`${this.TAG} dis data = ${JSON.stringify(dis)}`);
      let footBarHeight: number = 0;
      if (deviceInfo.deviceType === "default") {
        footBarHeight = px2vp(dis.width) * (4 / 3) - 160;
      } else {
        footBarHeight = px2vp(dis.width) * (4 / 3) - 82;
      }
      this.mAction.initFootBarHeight(footBarHeight);
    })

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
        atManager.requestPermissionsFromUser(GlobalContext.get().getCameraAbilityContext(), permissionList).then((data) => {
          Log.info(`${this.TAG} data permissions: ${JSON.stringify(data.permissions)}`);
          Log.info(`${this.TAG} data authResult: ${JSON.stringify(data.authResults)}`);
          let sum = 0
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
        })
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

    if (!this.state.isInitiated) {
      let initIndex: number = this.mPreferencesService.getModeValue(PersistType.FOR_AWHILE, 0);
      Log.info(`${this.TAG} initModeIndex: ${initIndex}`);
      this.mAction.initMode(this.modeArray[initIndex]);
      this.mAction.updateModeIndex(initIndex);
    }

    Log.info(`${this.TAG} aboutToAppear X`);
  }

  onPageShow(): void {
    Log.info(`${this.TAG} onPageShow this.permissionFlag: ${this.state.permissionFlag} permissionFlag: ${GlobalContext.get().getT<boolean>('permissionFlag')}`);
    this.mAction.setPermissionFlag(GlobalContext.get().getT<boolean>('permissionFlag'));
    let curCameraId = AppStorage.Get<string>('storageCameraId');
    if (curCameraId) this.mAction.initCameraPosition(curCameraId);
    this.mAction.resetRecordingTime();
    Log.info(`${this.TAG} onPageShow X`);
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`);
  }

  onBackPress(): boolean {
    Log.info(`${this.TAG} onBackPress E`);
    if (this.state.isShowPageView) {
      this.mAction.hideSettingView();
      return true;
    } else if (this.state.isShowtimeLapse) {
      this.mAction.changeTimeLapse(false);
      return true
    } else if (this.state.isThirdPartyCall) {
      let that = this;
      that.terminateSelfWithResult();
    } else {
      if (this.state.videoState === 'startTakeVideo' || this.state.videoState === 'pauseTakeVideo') {
        this.mAction.stopRecording();
        return true;
      }
      Log.info(`${this.TAG} onBackPress X`);
      return false;
    }
    return false;
  }

  onPageHide(): void {
    Log.info(`${this.TAG} onPageHide E`);
    this.stopCameraRecording();
    Log.info(`${this.TAG} onPageHide X`);
  }

  public stopCameraRecording() {
    Log.info(`${this.TAG} stopCameraRecording E`);
    if (this.state.isShowtimeLapse) {
      this.mAction.changeTimeLapse(false);
    }
    if (this.state.videoState === 'startTakeVideo' || this.state.videoState === 'pauseTakeVideo') {
      this.mAction.stopRecording();
    }
    Log.info(`${this.TAG} stopCameraRecording X`);
  }

  terminateSelfWithResult() {
    Log.info(`${this.TAG} terminateSelfWithResult start`);
    let abilityResult: ability.AbilityResult = {
      resultCode: -1,
      want: {
        parameters: {
          resourceUri: '',
          mode: this.state.mode
        }
      }
    };
    Log.info(`${this.TAG} terminateSelfWithResult start1`);
    if (GlobalContext.get().getSession()) {
      Log.info(`${this.TAG} terminateSelfWithResult start2`);
      GlobalContext.get().getSession().terminateSelfWithResult(abilityResult, (error: BusinessError) => {
        if (error) {
          Log.error(`${this.TAG} Operation failed. Cause: ${error?.code}`);
          return;
        }
        Log.info(`${this.TAG} Operation succeeded`);
      });
    } else {
      GlobalContext.get().getCameraAbilityContext().terminateSelfWithResult(abilityResult, (error: BusinessError) => {
        if (error) {
          Log.error(`${this.TAG} Operation failed. Cause: ${error}`);
          return;
        }
        Log.info(`${this.TAG} Operation succeeded`);
      });
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Stack() {
        PreviewArea()
      }.width('100%').position({ y: 48 })

      Stack() {
        if (deviceInfo.deviceType !== "default" && this.state.videoState === "beforeTakeVideo" && !this.state.isShowtimeLapse && this.state.showZoomLabelValue) {
          TabBar({ onBackClicked: () => this.onBackClicked() });
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
            .offset({
              x: 156, y: 0
            })
          }
          Column() {
            FootBar()
          }
          .visibility((!this.state.isShowtimeLapse && this.state.showZoomLabelValue) ? Visibility.Visible : Visibility.Hidden)
        }
      }.width('100%').height(302 - ZOOM_HEIGHT).position({ y: this.state.footBarHeight + ZOOM_HEIGHT })
      .visibility(!this.state.isShowtimeLapse ? Visibility.Visible : Visibility.Hidden)

      if (this.state.isShowPageView) {
        SettingView().width('100%').height('100%')
      }
    }.width('100%').height('100%').backgroundColor('#000')
  }

  private onBackClicked(): void {
    Log.info(`${this.TAG} onBackClicked E`);
    let that = this;
    that.terminateSelfWithResult();
  }
}