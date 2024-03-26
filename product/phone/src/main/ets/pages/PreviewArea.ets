/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

import router from '@system.router';
import display from '@ohos.display';
import deviceInfo from '@ohos.deviceInfo';
import { Action, UiStateMode } from '@ohos/common/src/main/ets/default/redux/actions/Action';
import { AssistiveGridView } from '@ohos/common/src/main/ets/default/featurecommon/assistivegridview/AssistiveGridView';
import { BigText } from '@ohos/common/src/main/ets/default/featurecommon/bigtext/BigText';
import { CameraNeedStatus, CameraStatus } from '@ohos/common/src/main/ets/default/utils/Constants';
import { CameraId } from '@ohos/common/src/main/ets/default/setting/settingitem/CameraId';
import { EventBus } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus';
import { EventBusManager } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager';
import { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store';
import { getStore } from '@ohos/common/src/main/ets/default/redux/store';
import { Log } from '@ohos/common/src/main/ets/default/utils/Log';
import { GeoLocation } from '@ohos/common/src/main/ets/default/featurecommon/geolocation/GeoLocation';
import { SettingManager } from '@ohos/common/src/main/ets/default/setting/SettingManager';
import { ShowFlashBlack } from '@ohos/common/src/main/ets/default/featurecommon/animate/ShowFlashBlack';
import { TimeLapseView } from '@ohos/common/src/main/ets/default/featurecommon/timelapseview/TimeLapseView';
import { ZoomText } from '@ohos/common/src/main/ets/default/featurecommon/zoomview/ZoomText';
import { BigVideoTimer } from './BigVideoTimer';
import { SmallVideoTimer } from './SmallVideoTimer';
import promptAction from '@ohos.promptAction';
import wantConstant from '@ohos.ability.wantConstant';
import { CameraPlatformCapability } from '@ohos/common/src/main/ets/default/camera/CameraPlatformCapability';
import { BusinessError } from '@ohos.base';
import { GlobalContext } from '@ohos/common/src/main/ets/default/utils/GlobalContext';

GlobalContext.get().setXComponentController(new XComponentController())

class StateStruct {
  mode: string = 'PHOTO';
  curMode: string = 'PHOTO';
  isShowPreview: boolean = true;
  surfaceId: number = 0;
  xComponentWidth: number = 0;
  xComponentHeight: number = 0;
  cameraPosition: CameraId = CameraId.BACK;
  curCameraPosition: CameraId = CameraId.BACK;
  minZoomRatio: number = 1;
  maxZoomRatio: number = 6;
  zoomRatio: number = 0;
  platformCapability: CameraPlatformCapability | undefined = undefined;
  videoState: string = '';
  footBarHeight: number = 0;
  isShowZoomText: boolean = false;
  showZoomLabelValue: boolean = true;
  modeIndex: number = 0;
  isThirdPartyCall: boolean = false;
  isShowBigText: boolean = false;
  isShowtimeLapse: boolean = false;
  isBigVideoTimerVisible: boolean = false;
  isSmallVideoTimerVisible: boolean = false;
  isAssGridViewShow: string = '';
  isShowFlashBlack: boolean = false;
  modeChangeDone: boolean = false;
  isShowPageView: boolean = false;
  showBlur: boolean = false;
  isFaCall: boolean = false;
  rotateAngle: number = 0;
  rotateAngleSec: number = 0;
  switchBackgroundOpacity: number = 1;
}

class PreviewAreaDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public initCamera(cameraId: CameraId, mode: string): void {
    this.mDispatch(Action.initCamera(cameraId, mode));
  }

  public initZoomRatio(min: number, max: number): void {
    this.mDispatch(Action.initZoomRatio(min, max));
  }

  public resetZoomRatio(zoomRatio: number): void {
    this.mDispatch(Action.resetZoomRatio(zoomRatio));
  }

  public changeZoomRatio(zoomRatio: number): void {
    this.mDispatch(Action.changeZoomRatio(zoomRatio));
  }

  public updateZoomPercentage(zoomPercentage: number): void {
    this.mDispatch(Action.updateZoomPercentage(zoomPercentage));
  }

  public prepareSurface(surfaceId: number): void {
    this.mDispatch(Action.prepareSurface(surfaceId));
  }

  public updateSurfaceId(surfaceId: number): void {
    this.mDispatch(Action.updateSurfaceId(surfaceId));
  }

  public startPreview(): void {
    this.mDispatch(Action.startPreview());
  }

  public switchCamera(cameraId: string): void {
    this.mDispatch(Action.switchCamera(cameraId));
  }

  public startVideoFlag(isStartVideo: boolean): void {
    this.mDispatch(Action.startVideoFlag(isStartVideo));
  }

  public updateCameraPosition(cameraPosition: string): void {
    this.mDispatch(Action.updateCameraPosition(cameraPosition));
  }

  public changeXComponentSize(xComponentWidth: number, xComponentHeight: number): void {
    this.mDispatch(Action.changeXComponentSize(xComponentWidth, xComponentHeight));
  }

  public updateShowPreviewFlag(isShowPreview: boolean): void {
    this.mDispatch(Action.updateShowPreviewFlag(isShowPreview));
  }

  public updateIsShowZoomText(isShowZoomText: boolean): void {
    this.mDispatch(Action.updateShowZoomTextFlag(isShowZoomText));
  }

  public updateIsPhotoZoomDetails(isPhotoZoomDetails: boolean): void {
    this.mDispatch(Action.updatePhotoZoomDetailsFlag(isPhotoZoomDetails));
  }

  public updateBaseZoom(zoomRatio: number): void {
    this.mDispatch(Action.updateBaseZoom(zoomRatio));
  }

  public changeImageSize(imageSize: SizeStruct): void {
    this.mDispatch(Action.changeImageSize(imageSize));
  }

  public changeVideoSize(videoSize: SizeStruct): void {
    this.mDispatch(Action.changeVideoSize(videoSize));
  }

  public close(): void {
    this.mDispatch(Action.close());
  }

  public stopRecording(): void {
    this.mDispatch(Action.stopRecording());
    this.mDispatch(Action.updateVideoState('beforeTakeVideo'));
    this.mDispatch(Action.updateBigVideoTimerVisible(false));
    this.mDispatch(Action.updateSmallVideoTimerVisible(false));
    this.mDispatch(Action.updateScreenStatus(false));
  }

  public changeTimeLapse(isShowtimeLapse: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse));
  }

  public capture(): void {
    this.mDispatch(Action.updateShowFlashBlackFlag(true));
    this.mDispatch(Action.capture());
  }

  public startRecording(): void {
    this.mDispatch(Action.startRecording());
    this.mDispatch(Action.updateVideoState('startTakeVideo'));
    this.mDispatch(Action.updateBigVideoTimerVisible(true));
    this.mDispatch(Action.updateScreenStatus(true));
  }

  public assistiveGridView(isViewShow: number): void {
    this.mDispatch(Action.assistiveGridView(isViewShow));
  }

  public thirdPartyCall(isThirdPartyCall: boolean, thirdCallAction: string): void {
    this.mDispatch(Action.thirdPartyCall(isThirdPartyCall, thirdCallAction));
  }

  public faCall(isFaCall: boolean): void {
    this.mDispatch(Action.faCall(isFaCall));
  }

  public initMode(mode: string): void {
    this.mDispatch(Action.initMode(mode));
  }

  public updateModeIndex(index: number): void {
    this.mDispatch(Action.updateModeIndex(index));
  }

  public updateMode(mode: string): void {
    this.mDispatch(Action.updateMode(mode));
  }

  public changeToMode(mode: string): void {
    this.mDispatch(Action.changeMode(mode));
  }

  public swipeChangeMode(swipeModeIndex: number): void {
    this.mDispatch(Action.swipeChangeMode(swipeModeIndex));
  }

  public updateShowZoomLabelValue(flag: boolean): void {
    this.mDispatch(Action.updateShowZoomLabelValue(flag));
  }

  public reloadThumbnail(): void {
    this.mDispatch(Action.reloadThumbnail());
  }

  public changeCameraPosition(cameraPosition: string): void {
    this.mDispatch(Action.setCameraPosition(cameraPosition));
  }

  public updateShowPinch(flag: boolean): void {
    this.mDispatch(Action.updateShowPinch(flag));
  }

  public swipeModeChangeDone(actionOff: boolean): void {
    this.mDispatch(Action.swipeModeChangeDone(actionOff));
  }
}

class SizeStruct {
  width: number = 0;
  height: number = 0;
}

class CameraInitStruct {
  platformCapability: CameraPlatformCapability | undefined = undefined;
}

class ModeStruct {
  mode: string = '';
}

class KeepScreenOnStruct {
  isKeepScreenOn: boolean = false;
}

@Component
export struct PreviewArea {
  private TAG: string = '[PreviewArea]:';
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State state: StateStruct = new StateStruct();
  @State mAspectRatio: number = 3 / 4;
  @State btnSwitch: boolean = false;
  @State btnSwitchSec: boolean = false;
  @State isSwitchBackground: boolean = false;
  @State pageType: string = '';
  private isShowPreview: boolean = false;
  private isForegroundInit: boolean = false;
  private settingManager = SettingManager.getInstance();
  private pinchGestureTimer: number = 0;
  private baseZoom: number = 0;
  private modeArray: Array<string> = ['PHOTO', 'VIDEO'];
  private mAction: PreviewAreaDispatcher = new PreviewAreaDispatcher();

  private async onCameraInit(data: CameraInitStruct): Promise<void> {
    Log.info(`${this.TAG} EventBus onCameraInit isShowPreview = ${this.isShowPreview} platformCapability = ${this.state.platformCapability} E`);
    if (this.isForegroundInit === true) {
      Log.info(`${this.TAG} EventBus onCameraInit foregroundInit`);
      this.doCameraAction();
      if (!this.state.isThirdPartyCall) {
        this.mAction.reloadThumbnail();
      }
      this.isForegroundInit = false;
    }
    if (this.state.platformCapability) {
      this.settingManager.loadAllSetting().then(() => {
        this.settingManager.setCameraId(this.state.cameraPosition);

        let imageSize = this.settingManager.getImageSize();
        this.mAction.changeImageSize(imageSize);

        let videoSize = this.settingManager.getVideoSize();
        this.mAction.changeVideoSize(videoSize);

        let isAssGridViewShow: number = Number(this.settingManager.getAssistiveGrid());
        this.mAction.assistiveGridView(isAssGridViewShow);
        display.getDefaultDisplay().then((dis) => {
          let screenHeight = px2vp(dis.height - 176);
          let screenWidth = px2vp(dis.width);

          this.settingManager.setScreenHeight(screenHeight);
          this.settingManager.setScreenWidth(screenWidth);

          let xComponentSize = this.settingManager.getPreviewDisplaySize(this.state.mode);
          Log.info(this.TAG + " PreviewArea xComponentSize = " + JSON.stringify(xComponentSize));
          this.mAction.changeXComponentSize(xComponentSize.width, xComponentSize.height);
          this.mAction.updateShowPreviewFlag(true);
        })
      })
    }
    Log.info(`${this.TAG} onCameraInit isShowPreview = ${this.state.isShowPreview}  X`);
  }

  private async doCameraAction() {
    Log.info(`${this.TAG} doCameraAction E`);
    this.settingManager.setCameraId(this.state.cameraPosition);
    if (this.state.curCameraPosition != this.state.cameraPosition) {
      this.mAction.switchCamera(this.state.cameraPosition);
    } else if (this.state.curMode != this.state.mode) {
      this.mAction.changeToMode(this.state.mode);
    } else {
      this.mAction.startPreview();
    }
    this.mAction.updateCameraPosition(this.state.cameraPosition);
    this.mAction.updateMode(this.state.mode);
    if (GlobalContext.get().getT<boolean>('keepCameraZoomRatio') && GlobalContext.get()
      .getT<boolean>('keepCameraZoomRatio')) {
      GlobalContext.get().setObject('keepCameraZoomRatio', false)
    } else {
      this.mAction.changeZoomRatio(1);
    }
    Log.info(`${this.TAG} doCameraAction X`);
  }

  private async onModeChanged(data: ModeStruct): Promise<void> {
    Log.info(`${this.TAG} onModeChanged E data.mode: ${data.mode}`);
    let xComponentSize = this.settingManager.getPreviewDisplaySize(data.mode);
    this.mAction.changeXComponentSize(xComponentSize.width, xComponentSize.height);
    this.mAction.updateShowPreviewFlag(true);
    Log.info(`${this.TAG} onModeChanged X`);
  }

  private async onRecordError(): Promise<void> {
    Log.info(`${this.TAG} onRecordError invoke E`);
    promptAction.showToast({
      message: "录像异常",
      duration: 2000,
    });
    if (this.state.videoState === 'startTakeVideo') {
      this.mAction.stopRecording();
    }
    this.mAction.close();
    Log.info(`${this.TAG} onRecordError invoke X`);
  }

  aboutToAppear(): void {
    Log.info(`${this.TAG} PreviewArea aboutToAppear ${JSON.stringify(router.getParams())}`);
    let routerParams = router.getParams();
    if (routerParams && routerParams.pageType) {
      this.pageType = routerParams.pageType.toString();
    }

    getStore().subscribe((state: OhCombinedState) => {
      let isShowBlur: boolean = !state.contextReducer.uiEnable && state.contextReducer.uiStateMode == UiStateMode.NONE;
      this.state = {
        mode: state.modeReducer.mode,
        curMode: state.modeReducer.curMode,
        isShowPreview: state.previewReducer.isShowPreview,
        surfaceId: state.previewReducer.surfaceId,
        xComponentWidth: state.previewReducer.xComponentWidth,
        xComponentHeight: state.previewReducer.xComponentHeight,
        cameraPosition: state.cameraReducer.cameraPosition,
        curCameraPosition: state.cameraReducer.curCameraPosition,
        minZoomRatio: state.zoomReducer.minZoomRatio,
        maxZoomRatio: state.zoomReducer.maxZoomRatio,
        zoomRatio: state.zoomReducer.zoomRatio,
        platformCapability: state.cameraInitReducer.platformCapability,
        videoState: state.recordReducer.videoState,
        isShowZoomText: state.zoomReducer.isShowZoomText,
        showZoomLabelValue: state.zoomReducer.showZoomLabelValue,
        footBarHeight: state.contextReducer.footBarHeight,
        isShowFlashBlack: state.previewReducer.isShowFlashBlack,
        isShowBigText: state.modeReducer.isShowBigText,
        isShowtimeLapse: state.settingReducer.isShowtimeLapse,
        isBigVideoTimerVisible: state.recordReducer.isBigVideoTimerVisible,
        isSmallVideoTimerVisible: state.recordReducer.isSmallVideoTimerVisible,
        isAssGridViewShow: state.settingReducer.isAssGridViewShow,
        modeIndex: state.modeReducer.modeIndex,
        isThirdPartyCall: state.contextReducer.isThirdPartyCall,
        modeChangeDone: state.modeReducer.modeChangeDone,
        isShowPageView: state.settingReducer.isShowSettingView,
        showBlur: isShowBlur,
        isFaCall: state.contextReducer.isFaCall,
        rotateAngle: 0,
        rotateAngleSec: 0,
        switchBackgroundOpacity: 1,
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.state.platformCapability;
    this.appEventBus.on(Action.ACTION_INIT_DONE, (data: CameraInitStruct) => this.onCameraInit(data));
    this.appEventBus.on(Action.ACTION_ON_MODE_CHANGED, (data: ModeStruct) => this.onModeChanged(data));
    this.appEventBus.on(Action.ACTION_KEEP_SCREEN_ON, (data: KeepScreenOnStruct) => this.onKeepScreen(data));
    this.appEventBus.on(Action.ACTION_RECORD_ERROR, () => this.onRecordError());
    this.appEventBus.on(Action.ACTION_UPDATE_CAMERA_STATUS, () => this.updateCameraStatus());
    GlobalContext.get().setObject('updateCameraStatus', () => {
      Log.info(`${this.TAG} globalThis.updateCameraStatus called`);
      this.updateCameraStatus();
    });
    this.calledByOther();
    this.mAction.initCamera(this.state.curCameraPosition, this.state.mode);
    this.mAction.initZoomRatio(1, 6); //TODO 需要动态取得实际变焦能力范围
    Log.start(Log.X_COMPONENT_LIFE);
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} previewAreaLand aboutToDisappear called`);
    this.appEventBus.off(Action.ACTION_INIT_DONE, (data: CameraInitStruct) => this.onCameraInit(data));
    this.appEventBus.off(Action.ACTION_ON_MODE_CHANGED, (data: ModeStruct) => this.onModeChanged(data));
    this.appEventBus.off(Action.ACTION_UPDATE_CAMERA_STATUS, () => this.updateCameraStatus());
    GeoLocation.getInstance().off();
    GlobalContext.get().setObject('cameraNeedStatus', CameraNeedStatus.CAMERA_NEED_RELEASE);
    this.updateCameraStatus();
  }

  private releaseCamera(): void {
    Log.info(`${this.TAG} globalThis.releaseCamera called`);
    GlobalContext.get().setObject('cameraNeedStatus', CameraNeedStatus.CAMERA_NO_NEED_TO_DO);
    if (this.state.videoState === 'startTakeVideo') {
      this.mAction.stopRecording();
    }
    this.mAction.close();
  }

  private async onForegroundInit() {
    Log.info(`${this.TAG} onForegroundInit E `);
    this.pageType = '';
    GlobalContext.get().setObject('cameraNeedStatus', CameraNeedStatus.CAMERA_NO_NEED_TO_DO);
    this.isForegroundInit = true;
    this.calledByOther();
    this.mAction.initCamera(this.state.curCameraPosition, this.state.mode);
    Log.info(`${this.TAG} onForegroundInit X`);
  }

  private calledByOther(): void {
    Log.info(`${this.TAG} calledByOther invoke E`);
    let from: string = "";
    let action: string = "";

    if (GlobalContext.get().getCameraAbilityWant()) {
      Log.info(`${this.TAG} cameraAbilityWant: ${JSON.stringify(GlobalContext.get().getCameraAbilityWant())}`);
      if (GlobalContext.get().getCameraAbilityWant()?.parameters?.from) {
        from = GlobalContext.get().getCameraAbilityWant()?.parameters?.from as string;
      }
      const wantAction: string | undefined = GlobalContext.get().getCameraAbilityWant()?.action;
      if (wantAction) {
        action = wantAction;
      }
    } else {
      this.mAction.thirdPartyCall(false, "");
      return;
    }
    Log.info(`${this.TAG} from: ${from}  action: ${action}`);

    if (from === "FA") {
      Log.info(`from === "FA"`);
      if (GlobalContext.get().getCameraAbilityWant()?.parameters?.action) {
        action = GlobalContext.get().getCameraAbilityWant()?.parameters?.action as string;
      }
      this.mAction.faCall(true);
      this.mAction.thirdPartyCall(false, "");
      this.initStateMode(action);
    } else if (GlobalContext.get().getCameraAbilityWant()?.parameters?.supportMultiMode || action != "") {
      this.mAction.faCall(false);
      if (GlobalContext.get().getCameraAbilityWant()?.parameters?.supportMultiMode) {
        action = 'ALL';
        this.mAction.thirdPartyCall(true, action);
        this.initStateMode(action);
      } else {
        this.mAction.thirdPartyCall(true, action);
        this.initStateMode(action);
      }
    } else {
      this.mAction.faCall(false);
      this.mAction.thirdPartyCall(false, "");
    }
    Log.info(`${this.TAG} calledByOther invoke X: ${this.state.mode}`);
  }

  private initStateMode(action: string): void {
    switch (action) {
      case wantConstant.Action.ACTION_IMAGE_CAPTURE:
        this.mAction.initMode('PHOTO');
        this.mAction.updateModeIndex(0);
        break;
      case wantConstant.Action.ACTION_VIDEO_CAPTURE:
        this.mAction.initMode('VIDEO');
        this.mAction.updateModeIndex(1);
        break;
      case 'ALL':
        this.mAction.initMode(this.state.mode);
        this.mAction.updateModeIndex(this.state.modeIndex);
      // private modeArray: Array<string> = ['PHOTO', 'VIDEO']; //, 'MORE'this.modeArray[modeIndex]
        break;
      default:
        Log.info(`${this.TAG} FA default`);
        break;
    }
  }

  private updateCameraStatus(): void {
    Log.info(`${this.TAG} updateCameraStatus  cameraStatus: ${GlobalContext.get().getT<string>('cameraStatus')}
      cameraNeedStatus: ${GlobalContext.get().getT<string>('cameraNeedStatus')}`);

    if (this.canInit() && GlobalContext.get().getT<string>('cameraNeedStatus') == CameraNeedStatus.CAMERA_NEED_INIT) {
      this.onForegroundInit();
    }
    if (this.canRelease() && GlobalContext.get()
      .getT<string>('cameraNeedStatus') == CameraNeedStatus.CAMERA_NEED_RELEASE) {
      this.releaseCamera();
    }
    Log.info(`${this.TAG} updateCameraStatus X`);
  }

  private canInit(): boolean {
    //相机状态是首次加载或者session释放完成状态，才能进行初始化操作
    return GlobalContext.get().getT<string>('cameraStatus') == CameraStatus.CAMERA_BEFORE_VALUE ||
      GlobalContext.get().getT<string>('cameraStatus') == CameraStatus.CAMERA_RELEASE_FINISHED;
  }

  private canRelease(): boolean {
    //相机状态是预览完成状态或录像完成状态才能进行释放操作
    return GlobalContext.get().getT<string>('cameraStatus') == CameraStatus.CAMERA_PREVIEW_FINISHED ||
      GlobalContext.get().getT<string>('cameraStatus') == CameraStatus.CAMERA_TAKE_VIDEO_FINISHED;
  }

  onBackPress(): void {
    Log.info(`${this.TAG} previewAreaLand onBackPress called`);
  }

  onPageHide(): void {
    this.mAction.startVideoFlag(false);
  }

  private pinchGestureStart(event: GestureEvent): void {
    Log.info(`${this.TAG} pinchGestureStart E`);
    if (this.state.mode != 'MULTI' && this.state.curCameraPosition !== 'FRONT') {
      clearTimeout(this.pinchGestureTimer);
      this.mAction.updateIsShowZoomText(true);
      this.mAction.updateShowPinch(true);
      this.mAction.updateShowZoomLabelValue(false);
      this.baseZoom = this.state.zoomRatio;
    }
    Log.info(`${this.TAG} pinchGestureStart X`);
  }

  private pinchGestureUpdate(event: GestureEvent): void {
    Log.info(`${this.TAG} pinchGestureUpdate E`);
    if (this.state.mode != 'MULTI' && this.state.curCameraPosition !== 'FRONT') {
      let zoomRatio = event.scale + this.baseZoom - 1;
      if (zoomRatio > 6) {
        zoomRatio = 6;
      }
      if (zoomRatio < 1) {
        zoomRatio = 1;
      }
      this.mAction.changeZoomRatio(zoomRatio);
    }
    Log.info(`${this.TAG} pinchGestureUpdate X`);
  }

  private pinchGestureEnd(event: GestureEvent): void {
    Log.info(`${this.TAG} pinchGestureEnd E`);
    if (this.state.mode != 'MULTI' && this.state.curCameraPosition !== 'FRONT') {
      this.mAction.updateShowZoomLabelValue(true);
      this.mAction.updateShowPinch(false);
      this.pinchGestureTimer = setTimeout(() => {
        this.mAction.updateIsShowZoomText(false);
      }, 2000);
    }
    Log.info(`${this.TAG} pinchGestureEnd X`);
  }

  private onPreviewClicked(): void {
    Log.info(`${this.TAG} click preview isShowtimeLapse= ${this.state.isShowtimeLapse} state.mode= ${this.state.mode}`);
    if (this.state.mode === 'PHOTO' && this.state.isShowtimeLapse) {
      this.mAction.changeTimeLapse(false);
      this.mAction.capture();
    } else if (this.state.mode === 'VIDEO' && this.state.isShowtimeLapse) {
      this.mAction.changeTimeLapse(false);
      this.mAction.startRecording();
    }
  }

  private swipeChangeMode(swipe: number): void {
    Log.info(`${this.TAG} swipeChangeMode E`);
    if (!this.state.modeChangeDone && this.state.modeIndex + swipe >= 0 && this.state.modeIndex + swipe <= this.modeArray.length - 1 && !this.state.isShowtimeLapse) {
      this.mAction.swipeChangeMode(this.state.modeIndex + swipe);
      this.mAction.swipeModeChangeDone(true);
    }
    Log.info(`${this.TAG} swipeChangeMode X`);
  }

  private onKeepScreen(data: KeepScreenOnStruct): void {
    Log.info(`${this.TAG} onKeepScreen E`);
    if (data) {
      GlobalContext.get()
        .getCameraWinClass()
        .setKeepScreenOn(data.isKeepScreenOn)
        .then(() => {
          Log.info('Succeeded in setting the screen to be always on');
        })
        .catch((err: BusinessError) => {
          Log.error('Failed to set the screen to be always on. Cause: ' + JSON.stringify(err));
        });
    }
    Log.info(`${this.TAG} onKeepScreen X`);
  }

  build() {
    Column() {
      if (this.state.isShowPreview) {
        Stack() {
          XComponent({
            id: '',
            type: 'surface',
            libraryname: '',
            controller: GlobalContext.get().getXComponentController()
          })
            .onLoad(() => {
              Log.end(Log.X_COMPONENT_LIFE);
              Log.info(`${this.TAG} XComponent_onLoad `);
              let surfaceId: number = GlobalContext.get().getXComponentController().getXComponentSurfaceId();
              this.mAction.prepareSurface(surfaceId);
              this.doCameraAction();
            })
            .width(this.state.xComponentWidth)
            .height(this.state.xComponentHeight)
            .animation({
              duration: 100,
              curve: Curve.Sharp,
              delay: 0,
              iterations: 1,
              playMode: PlayMode.Normal
            })

          if (this.isSwitchBackground) {
            Column() {
            }
            .width(this.state.xComponentWidth)
            .height(this.state.xComponentHeight)
            .backgroundColor('#000')
            .opacity(this.state.switchBackgroundOpacity)
          }

          if (this.state.showBlur) {
            Column()
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
              .backgroundColor(Color.Black)
              .border({ width: { top: 0.5, bottom: 0.5 }, color: Color.Black })
          }

          if (this.btnSwitch) {
            Image($r('app.media.whitePicture'))
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
              .syncLoad(false)
              .scale({ y: 1.0 })
              .rotate({ x: 0, y: 10, z: 0, angle: this.state.rotateAngle })// .opacity(this.state.btnOpacity_first)
              .onComplete(() => {
              })
          }

          if (this.btnSwitchSec) {
            Image($r('app.media.whitePicture'))
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
              .syncLoad(false)
              .scale({ y: 1.0 })
              .rotate({ x: 0, y: 10, z: 0, angle: this.state.rotateAngleSec })// .opacity(this.state.btnOpacity_sec)
              .onComplete(() => {
              })
          }

          if (this.state.isShowFlashBlack) {
            ShowFlashBlack();
          }

          if (this.state.isShowZoomText && deviceInfo.deviceType !== "default" && !this.state.isShowtimeLapse) {
            Stack({ alignContent: Alignment.Top }) {
              ZoomText({ state: $state })
            }
            .width('100%')
            .height('96%')
          }

          if (this.state.isShowBigText) {
            Stack({ alignContent: Alignment.BottomStart }) {
              BigText()
            }
            .width('100%')
            .height('100%')
            .padding({ bottom: '40vp' })
          }

          if (this.state.isAssGridViewShow === '1' && this.state.mode !== 'MORE') {
            AssistiveGridView();
          }

          if (this.state.isSmallVideoTimerVisible) {
            SmallVideoTimer();
          }

          if (this.state.isBigVideoTimerVisible) {
            BigVideoTimer();
          }

          if (this.state.isShowtimeLapse) {
            Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
              Column() {
                TimeLapseView();
              }.width('100%').height(150)
            }
          }
        }
        .width('100%')
        .height('100%')
      }
    }
    .height('100%')
    .width(this.state.xComponentWidth)
    .aspectRatio(this.mAspectRatio)
    .margin({ top: 0 })
    .backgroundColor('#000')
    .gesture(
      GestureGroup(
        GestureMode.Exclusive,
        TapGesture({ fingers: 1, count: 1 })
          .onAction(() => this.onPreviewClicked()),
        PinchGesture({ fingers: 2, distance: 1 })
          .onActionStart((event) => {
            if (event === undefined) return;
            this.pinchGestureStart(event)
          })
          .onActionUpdate((event) => {
            if (event === undefined) return;
            this.pinchGestureUpdate(event)
          })
          .onActionEnd((event) => {
            if (event === undefined) return;
            this.pinchGestureEnd(event)
          }),
        PanGesture({ fingers: 1, direction: PanDirection.Left, distance: 10 })
          .onActionEnd(() => {
            if (!this.state.isThirdPartyCall && !GlobalContext.get().getCameraAbilityWant()?.parameters?.from) {
              this.swipeChangeMode(1);
            }
          }),
        PanGesture({ fingers: 1, direction: PanDirection.Right, distance: 10 })
          .onActionEnd(() => {
            if (!this.state.isThirdPartyCall && !GlobalContext.get().getCameraAbilityWant()?.parameters?.from) {
              this.swipeChangeMode(-1);
            }
          })
      )
    )
  }
}