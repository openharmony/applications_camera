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

import router from '@system.router';
import display from '@ohos.display';
import deviceInfo from '@ohos.deviceInfo'
import { BigVideoTimer } from './BigVideoTimer'
import { Action, UiStateMode } from '@ohos/common/src/main/ets/default/redux/actions/Action'
import { AssistiveGridView } from '@ohos/common/src/main/ets/default/featurecommon/assistivegridview/AssistiveGridView'
import { BigText } from '@ohos/common/src/main/ets/default/featurecommon/bigtext/BigText'
import { CameraNeedStatus, CameraStatus } from '@ohos/common/src/main/ets/default/utils/Constants'
import { CameraId } from '@ohos/common/src/main/ets/default/setting/settingitem/CameraId'
import { EventBus } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus'
import { EventBusManager } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager'
import { OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store'
import { getStore } from '@ohos/common/src/main/ets/default/redux/store'
import { Log } from '@ohos/common/src/main/ets/default/utils/Log'
import { GeoLocation } from '@ohos/common/src/main/ets/default/featurecommon/geolocation/GeoLocation'
import { ScreenLockManager } from '@ohos/common/src/main/ets/default/featurecommon/screenlock/ScreenLockManager'
import { SettingManager } from '@ohos/common/src/main/ets/default/setting/SettingManager'
import { ShowFlashBlack } from '@ohos/common/src/main/ets/default/featurecommon/animate/ShowFlashBlack'
import { TimeLapseView } from '@ohos/common/src/main/ets/default/featurecommon/timelapseview/TimeLapseView'
import { ZoomText } from '@ohos/common/src/main/ets/default/featurecommon/zoomview/ZoomText'
import { SmallVideoTimer } from './SmallVideoTimer'
import promptAction from '@ohos.promptAction';
import wantConstant from '@ohos.ability.wantConstant';
import { GlobalContext } from '@ohos/common/src/main/ets/default/utils/GlobalContext';

class StateStruct {
  mode
  curMode
  isShowPreview
  surfaceId
  xComponentWidth
  xComponentHeight
  cameraPosition
  curCameraPosition
  minZoomRatio
  maxZoomRatio
  zoomRatio
  platformCapability
  videoState
  footBarHeight
  isShowZoomText
  showZoomLabelValue
  modeIndex
  isThirdPartyCall
  isShowBigText
  isShowtimeLapse
  isBigVideoTimerVisible
  isSmallVideoTimerVisible
  isAssGridViewShow
  isShowFlashBlack
  modeChangeDone
  isShowPageView
  showBlur
  isFaCall
  baseZoom
  initCamera: Function
  initZoomRatio: Function
  changeZoomRatio: Function
  updateZoomPercentage: Function
  prepareSurface: Function
  startPreview: Function
  switchCamera: Function
  updateCameraPosition: Function
  startVideoFlag: Function
  changeXComponentSize: Function
  updateShowPreviewFlag: Function
  updateIsShowZoomText: Function
  updateIsPhotoZoomDetails: Function
  updateBaseZoom: Function
  changeImageSize: Function
  changeVideoSize: Function
  close: Function
  stopRecording: Function
  changeTimeLapse: Function
  capture: Function
  startRecording: Function
  assistiveGridView: Function
  swipeChangeMode: Function
  thirdPartyCall: Function
  faCall: Function
  initMode: Function
  updateMode: Function
  changeToMode: Function
  updateModeIndex: Function
  updateShowZoomLabelValue: Function
  reloadThumbnail: Function
  updateShowPinch: Function
  swipeModeChangeDone: Function
  updateInitShowFlag: Function
  hideSettingView: Function
}

GlobalContext.get().setXComponentController(new XComponentController())

type ScreenSizeType = {
  width: number
  height: number
};

@Component
export struct PreviewAreaLand {
  private TAG: string = '[PreviewAreaLand]:';
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State state: StateStruct = new StateStruct();
  @State btnSwitch: boolean = false;
  @State btnSwitchSec: boolean = false;
  @State pinchGestureTimerId: number = 0;
  @State onTouchDownTimerId: number = 0;
  @State scaleX: number = 1;
  @State scaleXSec: number = 0.8;
  @State rotateAngle: number = 0;
  @State rotateAngleSec: number = 80;
  @State btnOpacityFirst: number = 1;
  @State btnOpacitySec: number = 0;
  @State switchBackgroundOpacity: number = 1;
  @State isSwitchBackground: boolean = false;
  @State pageType: string = '';
  @Link screenSize: ScreenSizeType;
  @State isShowBlurSize: ScreenSizeType = { width: 0, height: 0};
  private mConnect: any;
  private isShowPreview: boolean = false;
  private settingManager = SettingManager.getInstance();
  private pinchGestureTimer: number;
  private baseZoom: number;
  private modeArray: Array<string> = ['MULTI', 'PHOTO', 'VIDEO'];

  private async onCameraInit(data) {
    Log.info(`${this.TAG} EventBus onCameraInit isShowPreview = ${this.isShowPreview}
      platformCapability = ${this.state.platformCapability} E`);
    if (this.state.platformCapability) {
      this.settingManager.loadAllSetting().then(() => {
        this.settingManager.setCameraId(this.state.cameraPosition);

        let imageSize = this.settingManager.getImageSize();
        this.state.changeImageSize(imageSize);

        let videoSize = this.settingManager.getVideoSize();
        this.state.changeVideoSize(videoSize);

        let isAssGridViewShow = this.settingManager.getAssistiveGrid();
        this.state.assistiveGridView(isAssGridViewShow);

        GeoLocation.getInstance().on();

        this.resetScreenSize(this.screenSize);
        this.state.updateShowPreviewFlag(true);
      })
    }
    Log.info(`${this.TAG} onCameraInit isShowPreview = ${this.state.isShowPreview}  X`);
  }

  private async doCameraAction() {
    Log.info(`${this.TAG} doCameraAction E`);
    this.settingManager.setCameraId(this.state.cameraPosition);
    Log.info(`${this.TAG} curMode:${this.state.curMode} mode:${this.state.mode}`);
    if (this.state.curCameraPosition != this.state.cameraPosition) {
      this.state.switchCamera(this.state.cameraPosition, this.state.mode);
      this.state.updateCameraPosition(this.state.cameraPosition);
    } else if (this.state.curMode != this.state.mode) {
      this.state.changeToMode(this.state.mode);
      this.state.updateMode(this.state.mode);
    } else {
      if (GlobalContext.get().getT<boolean>('keepCameraZoomRatio') && GlobalContext.get().getT<boolean>('keepCameraZoomRatio')) {
        GlobalContext.get().setObject('keepCameraZoomRatio', false)
        Log.info(`${this.TAG} keep zoomRatio: ` + this.state.zoomRatio);
      } else {
        this.state.changeZoomRatio(1);
        Log.info(`${this.TAG} change zoomRatio: 1`);
      }
      this.state.startPreview(this.state.zoomRatio);
    }
    Log.info(`${this.TAG} doCameraAction X`);
    this.state.updateInitShowFlag(true);
  }

  private async onModeChanged(data) {
    Log.debug(`${this.TAG} onModeChanged E data.mode: ${data.mode}`);
    this.state.changeZoomRatio(1);
    this.state.updateShowPreviewFlag(true);
    Log.debug(`${this.TAG} onModeChanged X`);
  }

  private async onRecordError() {
    Log.info(`${this.TAG} onRecordError invoke E`);
    promptAction.showToast({
      message: "录像异常",
      duration: 2000,
    })
    if (this.state.videoState === 'startTakeVideo') {
      this.state.stopRecording();
    }
    this.state.close();
    Log.info(`${this.TAG} onRecordError invoke X`);
  }

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E ${JSON.stringify(router.getParams())}`);
    let routerParams = router.getParams();
    if (routerParams && routerParams.pageType) {
      this.pageType = routerParams.pageType.toString();
    }
    this.mConnect = getStore().connect((state: OhCombinedState) => {
      let isShowBlur = !state.ContextReducer.uiEnable && state.ContextReducer.uiStateMode == UiStateMode.NONE;
      return {
        mode: state.ModeReducer.mode,
        curMode: state.ModeReducer.curMode,
        isShowPreview: state.PreviewReducer.isShowPreview,
        surfaceId: state.PreviewReducer.surfaceId,
        xComponentWidth: state.PreviewReducer.xComponentWidth,
        xComponentHeight: state.PreviewReducer.xComponentHeight,
        cameraPosition: state.CameraReducer.cameraPosition,
        curCameraPosition: state.CameraReducer.curCameraPosition,
        minZoomRatio: state.ZoomReducer.minZoomRatio,
        maxZoomRatio: state.ZoomReducer.maxZoomRatio,
        zoomRatio: state.ZoomReducer.zoomRatio,
        platformCapability: state.CameraInitReducer.platformCapability,
        videoState: state.RecordReducer.videoState,
        footBarHeight: state.ContextReducer.footBarHeight,
        isShowZoomText: state.ZoomReducer.isShowZoomText,
        showZoomLabelValue: state.ZoomReducer.showZoomLabelValue,
        modeIndex: state.ModeReducer.modeIndex,
        isThirdPartyCall: state.ContextReducer.isThirdPartyCall,
        isShowBigText: state.ModeReducer.isShowBigText,
        isShowtimeLapse: state.SettingReducer.isShowtimeLapse,
        isBigVideoTimerVisible: state.RecordReducer.isBigVideoTimerVisible,
        isSmallVideoTimerVisible: state.RecordReducer.isSmallVideoTimerVisible,
        isAssGridViewShow: state.SettingReducer.isAssGridViewShow,
        isShowFlashBlack: state.PreviewReducer.isShowFlashBlack,
        modeChangeDone: state.ModeReducer.modeChangeDone,
        isShowPageView: state.SettingReducer.isShowSettingView,
        showBlur: isShowBlur,
        isFaCall: state.ContextReducer.isFaCall
      };
    }, (dispatch) => {
      return {
        initCamera: (cameraId: CameraId, mode: string): void => {
          dispatch(Action.initCamera(cameraId, mode));
        },
        initZoomRatio: (min: number, max: number): void => {
          dispatch(Action.initZoomRatio(min, max));
        },
        changeZoomRatio: (zoomRatio: number): void => {
          dispatch(Action.changeZoomRatio(zoomRatio));
        },
        updateZoomPercentage: (zoomPercentage: number): void => {
          dispatch(Action.updateZoomPercentage(zoomPercentage));
        },
        prepareSurface: (surfaceId: number): void => {
          dispatch(Action.prepareSurface(surfaceId));
        },
        startPreview: (zoomRatio: number): void => {
          dispatch(Action.startPreview(zoomRatio));
        },
        switchCamera: (cameraId: CameraId, mode: string): void => {
          dispatch(Action.switchCamera(cameraId, mode));
        },
        updateCameraPosition: (cameraPosition: string): void => {
          dispatch(Action.updateCameraPosition(cameraPosition));
        },
        startVideoFlag: (isStartVideo: boolean): void => {
          dispatch(Action.startVideoFlag(isStartVideo));
        },
        changeXComponentSize: (xComponentWidth: number, xComponentHeight: number): void => {
          dispatch(Action.changeXComponentSize(xComponentWidth, xComponentHeight));
        },
        updateShowPreviewFlag: (isShowPreview: boolean): void => {
          dispatch(Action.updateShowPreviewFlag(isShowPreview));
        },
        updateIsShowZoomText: (isShowZoomText: boolean): void => {
          dispatch(Action.updateShowZoomTextFlag(isShowZoomText));
        },
        updateIsPhotoZoomDetails: (isPhotoZoomDetails: boolean): void => {
          dispatch(Action.updatePhotoZoomDetailsFlag(isPhotoZoomDetails));
        },
        updateBaseZoom: (zoomRatio: number): void => {
          dispatch(Action.updateBaseZoom(zoomRatio));
        },
        changeImageSize: (imageSize): void => {
          dispatch(Action.changeImageSize(imageSize));
        },
        changeVideoSize: (videoSize): void => {
          dispatch(Action.changeVideoSize(videoSize));
        },
        close: (): void => {
          dispatch(Action.close());
        },
        stopRecording: (): void => {
          dispatch(Action.stopRecording());
          dispatch(Action.updateVideoState('beforeTakeVideo'));
          dispatch(Action.updateBigVideoTimerVisible(false));
          dispatch(Action.updateSmallVideoTimerVisible(false));
          dispatch(Action.updateScreenStatus(false));
        },
        changeTimeLapse: (isShowtimeLapse: boolean): void => {
          dispatch(Action.changeTimeLapse(isShowtimeLapse));
        },
        capture: (): void => {
          dispatch(Action.updateShowFlashBlackFlag(true));
          dispatch(Action.capture());
        },
        startRecording: (): void => {
          dispatch(Action.startRecording());
          dispatch(Action.updateVideoState('startTakeVideo'));
          dispatch(Action.updateBigVideoTimerVisible(true));
          dispatch(Action.updateScreenStatus(true));
        },
        assistiveGridView: (isViewShow: number): void => {
          dispatch(Action.assistiveGridView(isViewShow));
        },
        swipeChangeMode: (swipeModeIndex: number): void => {
          dispatch(Action.swipeChangeMode(swipeModeIndex));
        },
        thirdPartyCall: (isThirdPartyCall: boolean, action: string): void => {
          dispatch(Action.thirdPartyCall(isThirdPartyCall, action));
        },
        faCall: (isFaCall: boolean): void => {
          dispatch(Action.faCall(isFaCall));
        },
        initMode: (mode: string): void => {
          dispatch(Action.initMode(mode));
        },
        updateMode: (mode: string): void => {
          dispatch(Action.updateMode(mode));
        },
        changeToMode: (mode: string): void => {
          dispatch(Action.changeMode(mode));
        },
        updateModeIndex: (index: number): void => {
          dispatch(Action.updateModeIndex(index));
        },
        updateShowZoomLabelValue: (flag: boolean): void => {
          dispatch(Action.updateShowZoomLabelValue(flag));
        },
        reloadThumbnail: (): void => {
          dispatch(Action.reloadThumbnail());
        },
        updateShowPinch: (flag: boolean): void => {
          dispatch(Action.updateShowPinch(flag));
        },
        swipeModeChangeDone: (actionOff: boolean): void => {
          dispatch(Action.swipeModeChangeDone(actionOff));
        },
        updateInitShowFlag: (initShowFlag: boolean): void => {
          dispatch(Action.updateInitShowFlag(initShowFlag));
        },
        hideSettingView: (): void => {
          dispatch(Action.showSettingView(false));
        }
      };
    })(this.state);

    this.appEventBus.on(Action.ACTION_INIT_DONE, this.onCameraInit.bind(this));
    this.appEventBus.on(Action.ACTION_ON_MODE_CHANGED, this.onModeChanged.bind(this));
    this.appEventBus.on(Action.ACTION_KEEP_SCREEN_ON, this.onKeepScreen.bind(this));
    this.appEventBus.on("windowSize", this.windowSizeChange.bind(this));
    this.appEventBus.on(Action.ACTION_RECORD_ERROR, this.onRecordError.bind(this));
    this.appEventBus.on(ScreenLockManager.SCREEN_CHANGE_EVENT, this.onScreenChange.bind(this));
    this.appEventBus.on(Action.ACTION_UPDATE_CAMERA_STATUS, this.updateCameraStatus.bind(this));
    GlobalContext.get().setObject('updateCameraStatus', () => {
      Log.info(`${this.TAG} globalThis.updateCameraStatus called`);
      this.updateCameraStatus();
    });
    display.getDefaultDisplay().then((dis) => {
      this.isShowBlurSize = { width: px2vp(dis.width), height: px2vp(dis.height) };
    })
    this.calledByOther();
    this.state.initCamera(this.state.cameraPosition, this.state.mode);
    this.state.initZoomRatio(1, 6); //TODO 需要动态取得实际变焦能力范围
    Log.info(`${this.TAG} aboutToAppear X`);
    Log.start(Log.X_COMPONENT_LIFE);
  }

  private releaseCamera(): void {
    Log.info(`${this.TAG} globalThis.releaseCamera called`);
    GlobalContext.get().setObject('cameraNeedStatus', CameraNeedStatus.CAMERA_NO_NEED_TO_DO);
    if (this.state.videoState === 'startTakeVideo') {
      this.state.stopRecording();
    }
    this.state.close();
  }

  private async onForegroundInit() {
    Log.info(`${this.TAG} onForegroundInit E `);
    this.pageType = '';
    GlobalContext.get().setObject('cameraNeedStatus', CameraNeedStatus.CAMERA_NO_NEED_TO_DO);
    this.calledByOther();
    this.state.initCamera(this.state.cameraPosition, this.state.mode);
    await new Promise((resolve) => setTimeout(resolve, 40));
    this.doCameraAction();
    this.state.updateInitShowFlag(true);
    if (!this.state.isThirdPartyCall) {
      this.state.reloadThumbnail();
    }
    Log.info(`${this.TAG} onForegroundInit X`);
  }

  private calledByOther(): void {
    Log.info(`${this.TAG} calledByOther invoke E`);
    let from: string = "";
    let action: string = "";

    if (GlobalContext.get().getCameraAbilityWant()) {
      Log.info(`${this.TAG} cameraAbilityWant: ${JSON.stringify(GlobalContext.get().getCameraAbilityWant())}`);
      if (GlobalContext.get().getCameraAbilityWant()?.parameters?.from) {
        from = GlobalContext.get().getCameraAbilityWant().parameters.from as string;
      }
      if (GlobalContext.get().getCameraAbilityWant()?.action) {
        action = GlobalContext.get().getCameraAbilityWant().action;
      }
    } else {
      this.state.thirdPartyCall(false, "");
      return;
    }
    Log.info(`${this.TAG} from: ${from}  uri: ${action}`);

    if (from === "FA") {
      Log.info(`from === "FA"`);
      if (GlobalContext.get().getCameraAbilityWant()?.parameters?.action) {
        action = GlobalContext.get().getCameraAbilityWant().parameters.action as string;
      }
      this.state.faCall(true);
      this.state.thirdPartyCall(false, "");
      this.initStateMode(action);
    } else if (action != "") {
      this.state.faCall(false);
      this.state.thirdPartyCall(true, GlobalContext.get().getCameraAbilityWant().action);
      this.initStateMode(action);
    } else {
      this.state.faCall(false);
      this.state.thirdPartyCall(false, "");
    }
    Log.info(`${this.TAG} calledByOther invoke X: ${this.state.mode}`);
  }

  private initStateMode(action: string): void {
    switch (action) {
      case wantConstant.Action.ACTION_IMAGE_CAPTURE:
        this.state.initMode('PHOTO');
        this.state.updateModeIndex(1);
        break;
      case wantConstant.Action.ACTION_VIDEO_CAPTURE:
        this.state.initMode('VIDEO');
        this.state.updateModeIndex(2);
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
    if (this.canRelease() && GlobalContext.get().getT<string>('cameraNeedStatus') == CameraNeedStatus.CAMERA_NEED_RELEASE) {
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

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`);
    this.appEventBus.off(Action.ACTION_INIT_DONE, this.onCameraInit.bind(this));
    this.appEventBus.off(Action.ACTION_ON_MODE_CHANGED, this.onModeChanged.bind(this));
    this.appEventBus.off("windowSize", this.windowSizeChange.bind(this));
    this.appEventBus.off(Action.ACTION_UPDATE_CAMERA_STATUS, this.updateCameraStatus.bind(this));
    this.mConnect?.destroy();
    GeoLocation.getInstance().off();
    GlobalContext.get().setObject('cameraNeedStatus', CameraNeedStatus.CAMERA_NEED_RELEASE)
    this.updateCameraStatus();
    Log.info(`${this.TAG} aboutToDisappear X`);
  }

  onPageHide(): void {
    this.state.startVideoFlag(false);
    Log.info(`${this.TAG} onPageHide`);
  }

  private switchAnimationSec(): void {
    Log.info(`${this.TAG} switchAnimationSec called`);
    animateTo({ duration: 200,
      delay: 0,
      curve: Curve.Sharp,
    }, () => {
      this.btnOpacitySec = 1;
    })
    animateTo({
      duration: 350,
      curve: Curve.FastOutSlowIn,
      delay: 0,
    }, () => {
      Log.info(`${this.TAG} btnSwitchSec callback btnSwitchSec= ${this.btnSwitchSec}`);
      this.scaleXSec = 1;
    })
    animateTo({
      duration: 350,
      curve: 'cubic-bezier(0.21, 0.27, 0.20, 1.00)',
      delay: 0,
      onFinish: () => {
        Log.info(`${this.TAG} btnSwitchSec onFinish btnSwitchSec= ${this.btnSwitchSec}`);
        this.btnSwitchSec = false;
        this.btnOpacitySec = 0;
        this.scaleXSec = 0.8;
        this.rotateAngleSec = 80;
        this.switchBackgroundAnimation();
      }
    }, () => {
      Log.info(`${this.TAG} btnSwitchSec callback btnSwitchSec= ${this.btnSwitchSec}`);
      this.rotateAngleSec = 0;
      //      this.btnSwitchSec = true
    })
  }

  private switchBackgroundAnimation(): void {
    animateTo({ duration: 350,
      delay: 0,
      curve: Curve.Sharp,
      onFinish: () => {
        this.isSwitchBackground = false;
        this.switchBackgroundOpacity = 1;
      }
    }, () => {
      this.switchBackgroundOpacity = 0;
    })
  }

  private pinchGestureStart(event: GestureEvent): void {
    Log.info(`${this.TAG} pinchGestureStart invoke E`);
    if (this.state.mode != 'MULTI' && this.state.cameraPosition !== 'FRONT') {
      clearTimeout(this.pinchGestureTimer);
      this.state.updateIsShowZoomText(true);
      this.state.updateShowPinch(true);
      this.state.updateShowZoomLabelValue(false);
      this.baseZoom = this.state.zoomRatio;
    }
    if (this.state.mode !== "MULTI" && this.state.cameraPosition !== 'FRONT') {
      this.state.updateIsShowZoomText(true);
      this.state.updateShowPinch(true);
      this.state.updateIsPhotoZoomDetails(true);
      this.state.updateBaseZoom(this.state.zoomRatio);
      clearTimeout(this.pinchGestureTimerId);
      clearTimeout(this.onTouchDownTimerId);
    }
    Log.info(`${this.TAG} pinchGestureStart invoke X`);
  }

  private pinchGestureUpdate(event: GestureEvent): void {
    Log.info(`${this.TAG} pinchGestureUpdate invoke E`);
    if (this.state.mode != 'MULTI' && this.state.cameraPosition !== 'FRONT') {
      let zoomRatio = event.scale + this.baseZoom - 1;
      if (zoomRatio > 6) {
        zoomRatio = 6;
      }
      if (zoomRatio < 1) {
        zoomRatio = 1;
      }
      this.state.changeZoomRatio(zoomRatio);
    }
    Log.info(`${this.TAG} pinchGestureUpdate invoke X`);
  }

  private pinchGestureEnd(event: GestureEvent): void {
    Log.info(`${this.TAG} pinchGestureEnd invoke E`);
    this.state.updateShowZoomLabelValue(true);
    this.state.updateShowPinch(false);
    if (this.state.mode != 'MULTI' && this.state.cameraPosition !== 'FRONT') {
      this.pinchGestureTimer = setTimeout(() => {
        this.state.updateIsShowZoomText(false);
      }, 2000)
    }
    Log.info(`${this.TAG} pinchGestureEnd invoke X`);
  }

  private onPreviewClicked(): void {
    Log.info(`${this.TAG} onPreviewClicked isShowtimeLapse= ${this.state.isShowtimeLapse}, state.mode= ${this.state.mode}`);
    if (this.state.mode === 'PHOTO' && this.state.isShowtimeLapse) {
      this.state.changeTimeLapse(false);
      this.state.capture();
    } else if (this.state.mode === 'VIDEO' && this.state.isShowtimeLapse) {
      this.state.changeTimeLapse(false);
      this.state.startRecording();
    }
    Log.info(`${this.TAG} onPreviewClicked invoke X`);
  }

  private swipeChangeMode(swipe: number): void {
    Log.info(`${this.TAG} swipeChangeMode E`);
    if (!this.state.modeChangeDone && this.state.modeIndex + swipe >= 0 && this.state.modeIndex + swipe <= this.modeArray.length - 1 && !this.state.isShowtimeLapse) {
      this.state.swipeChangeMode(this.state.modeIndex + swipe);
      this.state.swipeModeChangeDone(true);
    }
    Log.info(`${this.TAG} swipeChangeMode X`);
  }

  private onKeepScreen(data): void {
    Log.info(`${this.TAG} onKeepScreen E`);
    if (data) {
      GlobalContext.get().getCameraWinClass().setKeepScreenOn(data.isKeepScreenOn).then((v) => {
        Log.info('Succeeded in setting the screen to be always on. Data: ' + JSON.stringify(v));
      }).catch((err) => {
        Log.error('Failed to set the screen to be always on. Cause: ' + JSON.stringify(err));
      });
    }
    Log.info(`${this.TAG} onKeepScreen X`);
  }

  private windowSizeChange(data): void {
    if (this.screenSize != data) {
      this.screenSize = data;
      this.resetScreenSize(data);
    }
  }

  private resetScreenSize(size: any): void {
    this.settingManager.setScreenHeight(size.height);
    this.settingManager.setScreenWidth(size.width);
    let xComponentSize = this.settingManager.getPreviewDisplaySize(this.state.mode);
    Log.info(this.TAG + " PreviewArea xComponentSize = " + JSON.stringify(xComponentSize));
    this.state.changeXComponentSize(xComponentSize.width, xComponentSize.height);
  }

  private async onScreenChange(isScreenOn) {
    Log.info(`${this.TAG} onScreenChanged E isScreenOn: ${isScreenOn}`);
    if (!isScreenOn) {
      GlobalContext.get().setObject('keepCameraZoomRatio', true);
      if (this.state.isShowPageView) {
        this.state.hideSettingView();
      }
    }
    Log.info(`${this.TAG} onScreenChanged X`);
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
              Log.info(`${this.TAG} XComponent_onLoad`);
              let surfaceId = GlobalContext.get().getXComponentController().getXComponentSurfaceId();
              this.state.prepareSurface(surfaceId);
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
            .opacity(this.switchBackgroundOpacity)
          }

          if (this.btnSwitch) {
            Image($r('app.media.whitePicture'))
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
              .syncLoad(false)
              .scale({ x: this.scaleX, y: 1.0 })
              .rotate({ x: 0, y: 10, z: 0, angle: this.rotateAngle })
                // .opacity(this.state.btnOpacity_first)
              .onComplete(() => { /* this.switchAnimation() */
              })
          }

          if (this.btnSwitchSec) {
            Image($r('app.media.whitePicture'))
              .width(this.state.xComponentWidth)
              .height(this.state.xComponentHeight)
              .syncLoad(false)
              .scale({ x: this.scaleX, y: 1.0 })
              .rotate({ x: 0, y: 10, z: 0, angle: this.rotateAngleSec })
                // .opacity(this.state.btnOpacity_sec)
              .onComplete(() => { /* this.switchAnimationSec() */
              })
          }

          if (this.state.isShowFlashBlack) {
            ShowFlashBlack();
          }

          if (this.state.isShowZoomText && deviceInfo.deviceType !== "default" && !this.state.isShowtimeLapse) {
            Stack({ alignContent: Alignment.Top }) {
              Column() {
                Column() {
                  ZoomText({ state: $state })
                }
                .width('100%')
                .height('100%')
              }
              .width('100%')
              .height('100%')
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .height('96%')
          }

          if (this.state.isAssGridViewShow === '1' && this.state.mode !== 'MORE') {
            AssistiveGridView();
          }

          if (this.state.isSmallVideoTimerVisible) {
            Column() {
              SmallVideoTimer();
            }
            .width('100%')
            .height('100%')
            .alignItems(HorizontalAlign.Start)
          }
          if (this.state.isBigVideoTimerVisible) {
            Column() {
              BigVideoTimer();
            }
            .width('100%')
            .height('100%')
            .alignItems(HorizontalAlign.Start)
          }
          if (this.state.isShowtimeLapse) {
            Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
              Column() {
                TimeLapseView();
              }.width('100%').height(150)
            }.width('100%').height('100%')
          }
          if (this.state.showBlur) {
            Column()
              .width(this.isShowBlurSize.width)
              .height(this.isShowBlurSize.height)
              .backgroundColor(Color.Black)
              .border({ width: { top: 0.5, bottom: 0.5 }, color: Color.Black })
          }

          Stack() {
            if (this.state.isShowBigText) {
              Stack({ alignContent: Alignment.BottomStart }) {
                Column() {
                  Column() {
                    BigText()
                  }
                  .width('100%')
                  .height('100%')
                }
                .width('100%')
                .height('96vp')
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .height('100%')
            }
          }
          .width(this.screenSize.width > this.screenSize.height ? this.screenSize.height : this.screenSize.width)
          .height(this.screenSize.height > (this.screenSize.width * 9 / 16) ? (this.screenSize.width * 9 / 16) :
          this.screenSize.height)
        }
        .width('100%')
        .height('100%')
      }
    }
    .width(this.state.xComponentWidth)
    .height(this.state.xComponentHeight)
    .margin({ top: 0 })
    .backgroundColor('#000')
    .gesture(
    GestureGroup(
    GestureMode.Exclusive,
    TapGesture({ fingers: 1, count: 1 })
      .onAction(this.onPreviewClicked.bind(this)),
    PinchGesture({ fingers: 2, distance: 1 })
      .onActionStart(this.pinchGestureStart.bind(this))
      .onActionUpdate(this.pinchGestureUpdate.bind(this))
      .onActionEnd(this.pinchGestureEnd.bind(this)),
    PanGesture({ fingers: 1, direction: PanDirection.Up, distance: 10 })
      .onActionEnd(() => {
        if (!this.state.isThirdPartyCall && !this.state.isFaCall) {
          this.swipeChangeMode(1);
        }
      }),
    PanGesture({ fingers: 1, direction: PanDirection.Down, distance: 10 })
      .onActionEnd(() => {
        if (!this.state.isThirdPartyCall && !this.state.isFaCall) {
          this.swipeChangeMode(-1);
        }
      })
    )
    )
  }
}