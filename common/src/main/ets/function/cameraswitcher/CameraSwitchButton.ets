/*
 * Copyright (c) Huawei Device Co., Ltd. 2024-2025. All rights reserved.
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

import window from '@ohos.window';
import lazy { Action } from '../../redux/actions/Action';
import lazy { RecordAction, RecordingState } from '../recordcontrol/RecordAction';
import lazy { CameraSwitchController } from './CameraSwitchController';
import lazy { OhCombinedState, Unsubscribe, Dispatch, getStates } from '../../redux';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import deviceInfo from '@ohos.deviceInfo';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { FunctionAction } from '../core/FunctionAction';
import lazy { UiElement } from '../core/UiElement';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { FeatureManager } from '../core/FeatureManager';
import camera from '@ohos.multimedia.camera';
import lazy { VibratorService } from '../../component/vibration/VibratorService';
import lazy { CameraAction, CameraStartType, CameraStartTypeStruct } from '../../camera/uithread/CameraAction';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { BaseFunction } from '../core/BaseFunction';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { CameraBasicService } from '../../camera/uithread/CameraBasicService';
import lazy { ChangeState, reduxSubscribe } from '../../redux/Store';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { ModeListManager } from '../../mode/ModeListManager';
import lazy { BlurAnimateUtil } from '../../utils/BlurAnimateUtil';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { PickerUiService } from '../../service/picker/PickerUiService';
import ResGetter from '../../utils/ResGetter';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import lazy { LongPressDialogView } from '../../component/customdialog/dialogComponent/LongPressDialogView';
import lazy { KeyCode } from '@ohos.multimodalInput.keyCode';
import lazy { SavePowerModeActionData } from '../../utils/types';
import lazy { RecordMode } from '../recordcontrol/RecordMode';
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import lazy { AccessibilityUtils } from '../../utils/AccessibilityUtils';
import lazy { SelfieStickKey } from '../../service/selfieStick/SelfieStickService';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { CaptureService } from '../capture/CaptureService';
import lazy { execAction } from '../../redux/ActionRegistry';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { CaptureActionType } from '../../redux/actions/CaptureActionType';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { CollaborateControlActionType } from '../../redux/actions/CollaborateControlActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { CameraProxy } from '../../camera/uithread/CameraProxy';
import lazy { CLICK_DELAY } from '../../service/collaborateControl/CollaborateControlAction'
import { TipService } from '../../component/tip/TipService';

/* instrument ignore file */
const TAG: string = 'CameraSwitchButton';

class StateStruct {
  public mode: ModeType = ModeType.NONE;
  public videoState: RecordingState = RecordingState.READY;
  public isShowExtendBar: boolean = false;
}

class CameraSwitchDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeCameraPosition(position: camera.CameraPosition, keepVideoFlowing?: boolean,
    isVideoRotation?: boolean): void {
    this.mDispatch(CameraAction.switchCamera(position, keepVideoFlowing, isVideoRotation));
  }

  public uiDisabled(): void {
    this.mDispatch(Action.uiState(false));
  }

  public changeFunctionValue(id: FunctionId, value: number | string): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public switchCameraChangeMode(position: camera.CameraPosition, mode: ModeType): void {
    this.mDispatch(CameraAction.switchCameraChangeMode(position, mode));
  }

  public updateIsShowParamBar(isShow: boolean): void {
    this.mDispatch(Action.updateIsShowParamBar(isShow));
  }

  public updateIsShowExtendBar(isShow: boolean): void {
    this.mDispatch(Action.updateIsShowExtendBar(isShow));
  }

  public cameraSwitchOnChange(isChangeFront: boolean): void {
    this.mDispatch(execAction('MotionAction', 'handleSlowCameraSwitch', isChangeFront));
  }

  public changeRecordFunctionValue(): void {
    this.mDispatch(RecordAction.pause(false));
    this.mDispatch(FunctionAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.SWITCH_CAMERA_TO_PAUSE));
  }

  public resumeNovaVideo(): void {
    this.mDispatch(RecordAction.resume(false));
    this.mDispatch(FunctionAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.SWITCH_CAMERA_TO_RESUME));
    this.mDispatch(Action.uiState(true));
  }

  public updateNightSubModeExtendBar(isShow: boolean): void {
    this.mDispatch(execAction('NightSubModeAction', 'updateNightSubModeExtendBarShow', isShow));
  }
}


class ResolutionStore {
  public isResolutionChange: boolean = false;
}

@Component
export struct CameraSwitchButton {
  private mBase: BaseComponent = new BaseComponent();
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @State isShow: boolean = true;
  @State isHighStabilization: number = 0;
  @State innerOpacity: number = 1;
  @State innerScale: ScaleOptions = { x: 1, y: 1 };
  @State deviceType: string = deviceInfo.deviceType;
  @State state: StateStruct = new StateStruct();
  @Prop mHideThumbnailAndSwitchButton: boolean = false;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  private imgFit: ImageFit = ImageFit.Cover;
  private defaultImgSrc: Resource | string | undefined = '';
  @State rotateAngle: number = 0;
  icon: Resource = $r('app.media.small_switch_camera');
  mWidth: number = 0;
  mHeight: number = 0;
  mMargin: number = 0;
  type: ButtonType = ButtonType.Capsule;
  INDEX_SEC = 2;
  INDEX_THR = 3;
  FRAME_RATE_60FPS: number = 60;
  stateEffect: boolean = false;
  frameRateSaving: boolean = false;
  cameraSwitchController: CameraSwitchController = new CameraSwitchController();
  private mAction: CameraSwitchDispatcher = new CameraSwitchDispatcher();
  private mSubscriber: Unsubscribe | null = null;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private uiEnable: boolean = false;
  @State circleScale: ScaleOptions = {
    x: AnimSpecifications.SCALE_ORIGINAL,
    y: AnimSpecifications.SCALE_ORIGINAL
  };
  @State circleRotation: RotateOptions = {
    y: AnimSpecifications.ROTATION_Y_HALF,
    angle: AnimSpecifications.ROTATION_POSITIVE_HORIZONTAL
  };
  @State circleOpacity: number = 1;
  private resolutionStore: ResolutionStore = new ResolutionStore();
  @State @Watch('updateDensity') density: number = 1 //DisplayService.getInstance().getDisplay().densityPixels;
  @State isShowSubScreenRadius: boolean = false;
  @StorageLink('slowRecordingCompVisible') slowRecordingCompVisible: boolean = true;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State isShowRingLightView: boolean = false;
  @State disEnableClickState: boolean = false;
  private customDialogViewController?: CustomDialogController;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  private isSavePowerMode: boolean = false;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false; // 浏览模式是否开启
  private isManualChanged: boolean = false;
  private isVideoRotation: boolean = false;
  @State isShowLandscape: boolean = false;
  @State isShowTricollaps: boolean = false;
  @State isShowtimeLapse: boolean = false
  @State isNightSubModeExtendBarShow: boolean = false;
  @StorageLink('onCustomFilterCardActionMenuShow') isShowActionMenu: boolean = false;
  @Prop isHdr: boolean = false;
  @State curStyleIndex: number = 0;
  @State isCustomFilterImmersive: boolean = false;

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.density = state.get<number>('collapsReducer', 'density');
      changeState(this.state, {
        mode: state.get<ModeType>('modeReducer', 'mode'),
        videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
        isShowExtendBar: state.get<boolean>('uiReducer', 'isShowExtendBar'),
      });
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      this.isNightSubModeExtendBarShow = state.get<boolean>('nightSubModeReducer', 'isNightSubModeExtendBarShow');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isShowtimeLapse = state.get<boolean>('settingReducer', 'isShowtimeLapse');
      this.curStyleIndex = state.get<number>('customFilterStyleReducer', 'styleIndex');
      this.isCustomFilterImmersive = state.get<boolean>('customFilterStyleReducer', 'customFilterCardOpened');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.mEventBus.on([ActionType.ACTION_CHANGE_RESOLUTION], this.onResolutionChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.CAPTURE, this.disEnableClick.bind(this), this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_FRAME_SHUTTER_END, ContextActionType.ABILITY_ON_BACKGROUND,
      CameraActionType.STARTED],
      this.enableClick.bind(this), this.mBase.hashCode());
    this.mEventBus.on([CameraActionType.STARTED], this.enableAndResumeNova.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.SELFIE_STICK_EVENT, this.selfieStickEvent.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.UPDATE_SAVE_POWER_MODE_STATE, (data: SavePowerModeActionData) =>
    this.updateSavePowerModeState(data), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.PAUSE, this.onRecordPause.bind(this), this.mBase.hashCode());
    this.mEventBus.on([RecordActionType.RESUME, RecordActionType.RELEASE], this.onRecordResume.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.SWITCH_CAMERA, this.onCollaborateSwitchCamera.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.RECORD_PAUSED, this.onRecordPaused.bind(this),
      this.mBase.hashCode());
    this.defaultImgSrc = FeatureManager.getInstance()
      .getFunction(FunctionId.CAMERA_SWITCHER)?.getUiElements(RenderLocation.NONE).get(UiElement.DEFAULT)?.icon;
    this.mEventBus.on(CameraActionType.CHANGE_MODE, () => this.enableClick(), this.mBase.hashCode());
    this.cameraSwitchController.getParam();
    this.icon = this.cameraSwitchController.icon;
    this.mWidth = this.cameraSwitchController.width;
    this.mHeight = this.cameraSwitchController.height;
    this.mMargin = this.cameraSwitchController.margin;
    this.type = this.cameraSwitchController.type;
    this.stateEffect = this.cameraSwitchController.stateEffect;
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mSubscriber?.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToDisappear X.');
  }

  /**
   *  适配自拍杆切换前后置摄像头
   */
  private updateSavePowerModeState(data: SavePowerModeActionData): void {
    this.isSavePowerMode = data.isDuringSavePowerMode;
  }

  private selfieStickEvent(data: SelfieStickKey): void {
    if (data['key'].keyValue !== KeyCode.KEYCODE_VIDEO_NEXT || this.isSavePowerMode ||
      (this.videoState !== RecordingState.READY)) {
      return;
    }
    if (!this.uiEnable || (GlobalContext.get().getIsPicker() && PickerUiService.getInstance().getCaptureState()) ||
      !CaptureService.getInstance().isEnableCapture()) {
      return;
    }
    if (data['key'].keyValue === KeyCode.KEYCODE_VIDEO_NEXT) {
      BlurAnimateUtil.generatePixelMapFromSurface();
      this.onSwitchCameraDown();
      BlurAnimateUtil.setInSwitchCamera(true);
      this.cameraSwitchOnChange();
    }
    if ((this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
      this.customDialogViewController?.close();
    }

  }

  private onRecordPause(data: Record<string, boolean>): void {
    HiLog.i(TAG, 'onRecordPause invoke E.' + data?.isManualChanged);
    this.isManualChanged = data?.isManualChanged;
    HiLog.i(TAG, 'onRecordPause invoke X.');
  }

  private onRecordResume(data: Record<string, boolean>): void {
    HiLog.i(TAG, 'onRecordResume invoke E.');
    this.isManualChanged = false;
    HiLog.i(TAG, 'onRecordResume invoke X.');
  }

  private disEnableClick(): void {
    this.disEnableClickState = true;
    HiLog.i(TAG, `disEnableClick disEnableClickState: ${this.disEnableClickState}`);
  }

  private enableClick(): void {
    this.disEnableClickState = false;
    HiLog.i(TAG, `enableClick disEnableClickState: ${this.disEnableClickState}`);
  }

  private enableAndResumeNova(data: CameraStartTypeStruct): void {
    if (data && data.type === CameraStartType.SWITCH_CAMERA && this.videoState !== RecordingState.READY &&
      !this.isManualChanged) {
      this.mAction.resumeNovaVideo()
      setTimeout(() => {
        this.disEnableClickState = false;
        HiLog.i(TAG, `enableAndResumeNova disEnableClickState: ${this.disEnableClickState}`);
      }, 200);
    }
  }

  private rotateCircle(): void {
    HiLog.i(TAG, 'rotateCircle.');
    this.circleScale = {
      x: AnimSpecifications.SCALE_ORIGINAL,
      y: AnimSpecifications.SCALE_ORIGINAL
    };
    this.circleRotation = {
      y: AnimSpecifications.ROTATION_Y_HALF,
      angle: AnimSpecifications.ROTATION_POSITIVE_HORIZONTAL
    };

    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_100,
      curve: Curve.Sharp
    }, () => {
      this.circleScale = {
        x: AnimSpecifications.CAMERA_FLIP_SCALE_90,
        y: AnimSpecifications.CAMERA_FLIP_SCALE_90
      };
    });

    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_150,
      curve: Curve.Sharp,
      delay: AnimSpecifications.ANIM_DELAY_100
    }, () => {
      this.circleScale = {
        x: AnimSpecifications.CAMERA_FLIP_SCALE_150,
        y: AnimSpecifications.CAMERA_FLIP_SCALE_150
      };
    });

    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_150,
      curve: Curve.Sharp,
      delay: AnimSpecifications.ANIM_DELAY_250
    }, () => {
      this.circleScale = {
        x: AnimSpecifications.SCALE_ORIGINAL,
        y: AnimSpecifications.SCALE_ORIGINAL
      };
    });

    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_300,
      curve: Curve.Sharp,
      delay: AnimSpecifications.ANIM_DELAY_100
    }, () => {
      this.circleRotation = {
        y: AnimSpecifications.ROTATION_Y_HALF,
        angle: AnimSpecifications.ROTATION_REVERSES_HORIZONTAL
      };
    });
  }

  private videoStateOnChange(): void {
    HiLog.d(TAG, `videoStateOnChange videoState: ${this.videoState}.`);
    if (this.videoState === RecordingState.READY) {
      this.isVideoRotation = false;
    }
    return;
    if (this.videoState === RecordingState.STARTING) {
      this.recordStartAnim();
    } else if (this.videoState === RecordingState.STOPPING) {
      this.recordEndAnim();
    }
  }

  private recordStartAnim(): void {
    HiLog.i(TAG, 'recordStartAnim.');
    this.innerOpacity = 1;
    this.innerScale = { x: 1, y: 1 };
    this.circleOpacity = 1;
    animateToImmediately(
      {
        duration: 300,
        curve: Curve.Friction,
        onFinish: () => {
          HiLog.i(TAG, 'recordStartAnim finish.');
          const windowStageEventType: window.WindowStageEventType | undefined = AppStorage.get('windowStageEventType');
          const isWindowInactive: boolean = windowStageEventType === window.WindowStageEventType.PAUSED ||
            windowStageEventType === window.WindowStageEventType.INACTIVE ||
            windowStageEventType === window.WindowStageEventType.HIDDEN;
          HiLog.i(TAG,
            `recordStartAnim finish isWindowActive: ${isWindowInactive}, windowStageEventType: ${windowStageEventType}`);
          this.isShow = isWindowInactive;

          if (isWindowInactive) {
            this.innerScale = { x: 1, y: 1 };
            this.circleOpacity = 1;
            this.innerOpacity = 1;
          }
        }
      },
      () => {
        this.innerScale = { x: 0, y: 0 };
        this.circleOpacity = 0;
      }
    );
    animateToImmediately(
      {
        delay: 50,
        duration: 150,
        curve: Curve.Sharp,
        onFinish: () => {
        }
      },
      () => {
        this.innerOpacity = 0;
      }
    );
  }

  private recordEndAnim(): void {
    HiLog.i(TAG, 'recordEndAnim.');
    this.innerOpacity = 0;
    this.innerScale = { x: 0, y: 0 };
    this.circleOpacity = 0;
    this.isShow = true;
    animateToImmediately(
      {
        duration: 300,
        curve: Curve.Friction,
        onFinish: () => {
          HiLog.i(TAG, 'recordEndAnim finish.');
          this.isShow = true;
        }
      },
      () => {
        this.innerScale = { x: 1, y: 1 };
        this.circleOpacity = 1;
      }
    );
    animateToImmediately(
      {
        delay: 50,
        duration: 150,
        curve: Curve.Sharp,
        onFinish: () => {
        }
      },
      () => {
        this.innerOpacity = 1;
      }
    );
  }

  private onSwitchCameraDown(): void {
    this.circleScale = { x: 1, y: 1 };
    animateToImmediately({
      curve: AnimSpecifications.ANIM_CAPTURE_CURVE,
      onFinish: () => {
      }
    }, () => {
      this.circleScale = { x: 0.9, y: 0.9 };
    });
  }

  private onSwitchCameraUp(): void {
    this.circleScale = { x: 0.9, y: 0.9 };
    animateToImmediately({
      curve: AnimSpecifications.ANIM_CAPTURE_CURVE,
      onFinish: () => {
      }
    }, () => {
      this.circleScale = { x: 1, y: 1 };
    });
  }

  private getAnimationDuration(): number {
    return AnimSpecifications.ANIM_DURATION_300;
  }

  private changeCameraPositionToBack(functionImpl: BaseFunction): void {
    AppStorage.setOrCreate('lastVideoResolutionValue', functionImpl?.getValue() as number);
    this.mAction.changeFunctionValue(FunctionId.CAMERA_SWITCHER, camera.CameraPosition.CAMERA_POSITION_BACK);
    if (DeviceInfo.isTablet() && this.resolutionStore.isResolutionChange) {
      this.changeResolution(1);
    }
    if (this.frameRateSaving) {
      this.changeFrameRate(this.INDEX_SEC, false);
    }

    if (this.videoState !== RecordingState.READY) {
      this.changeRecordFunctionValue();
      if (this.videoState === RecordingState.PAUSED) {
        this.mAction.changeCameraPosition(camera.CameraPosition.CAMERA_POSITION_BACK,
          true, this.isVideoRotation)
      }
    } else {
      this.mAction.changeCameraPosition(camera.CameraPosition.CAMERA_POSITION_BACK,
        this.videoState !== RecordingState.READY, this.isVideoRotation);
    }

    VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
    if (this.state.mode !== ModeType.VIDEO) {
      return;
    }
    let videoProfile: camera.VideoProfile = CameraAppCapability.getInstance()
      .getVideoProfiles(camera.CameraPosition.CAMERA_POSITION_BACK, this.state.mode)[functionImpl.getValue() - 1];
    if (videoProfile === undefined || videoProfile === null) { // 镜头切换时检测是否支持分辨率,否则需要切分辨率
      this.mAction.changeFunctionValue(FunctionId.VIDEO_RESOLUTION, functionImpl.getDefaultValue() as number);
    }
    return;
  }

  //录像中支持前后置切换
  private changeRecordFunctionValue(): void {
    if (this.videoState !== RecordingState.READY && this.videoState !== RecordingState.PAUSED) {
      this.mAction.changeRecordFunctionValue();
    }
  }

  private changeFrameRate(frameRate: number, isSaving: boolean): void {
    AppStorage.setOrCreate('restoreFlag', true);
    this.mAction.changeFunctionValue(FunctionId.FRAME_RATE, frameRate);
    this.frameRateSaving = isSaving;
    AppStorage.setOrCreate('restoreFlag', false);
  }

  private changeResolution(resolutionSetting: number): void {
    AppStorage.setOrCreate('restoreFlag', true);
    this.mAction.changeFunctionValue(FunctionId.VIDEO_RESOLUTION, resolutionSetting);
    AppStorage.setOrCreate('restoreFlag', false);
  }

  private changeCameraPositionToFront(frameRate: number, functionImpl: BaseFunction,
    frameRateSwitching: BaseFunction): void {
    this.mAction.changeFunctionValue(FunctionId.CAMERA_SWITCHER, camera.CameraPosition.CAMERA_POSITION_FRONT);
    if (DeviceInfo.isTablet()) {
      if (frameRate === this.FRAME_RATE_60FPS) {
        this.changeFrameRate(frameRateSwitching.getDefaultValue() as number, true);
      }
      let videoProfile: camera.VideoProfile = CameraAppCapability.getInstance()
        .getVideoProfiles(camera.CameraPosition.CAMERA_POSITION_FRONT, ModeType.VIDEO)[functionImpl.getValue() - 1];
      if (videoProfile === null || videoProfile === undefined || videoProfile?.size?.width === 0) {
        this.changeResolution(functionImpl.getDefaultValue() as number);
        this.resolutionStore.isResolutionChange = true;
      } else {
        this.resolutionStore.isResolutionChange = false;
      }
    }
    let videoProfile: camera.VideoProfile = CameraAppCapability.getInstance()
      .getVideoProfiles(camera.CameraPosition.CAMERA_POSITION_FRONT, ModeType.VIDEO)[functionImpl.getValue() - 1];
    if (frameRate === this.FRAME_RATE_60FPS && videoProfile?.frameRateRange.max !== this.FRAME_RATE_60FPS) {
      this.changeFrameRate(frameRateSwitching.getDefaultValue() as number, true);
    }
    if (!DeviceInfo.isTablet() && this.state.mode === ModeType.VIDEO) {
      let videoProfile: camera.VideoProfile = CameraAppCapability.getInstance()
        .getVideoProfiles(camera.CameraPosition.CAMERA_POSITION_FRONT, this.state.mode)[functionImpl.getValue() - 1];
      if (videoProfile === undefined || videoProfile === null) { // 镜头切换时检测是否支持分辨率,否则需要切分辨率
        this.changeResolution(functionImpl.getDefaultValue() as number);
      }
    }

    AppStorage.setOrCreate('startOrUserChangeToModeLast', this.state.mode);

    if (this.videoState !== RecordingState.READY) {
      this.changeRecordFunctionValue();
      if (this.videoState === RecordingState.PAUSED) {
        this.mAction.changeCameraPosition(camera.CameraPosition.CAMERA_POSITION_FRONT,
          true, this.isVideoRotation);
      }
    } else {
      this.mAction.changeCameraPosition(camera.CameraPosition.CAMERA_POSITION_FRONT,
        false, this.isVideoRotation);
    }

    VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
    return;
  }

  private onRecordPaused(): void {
    if (this.isManualChanged) {
      return;
    }
    if (this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      this.mAction.changeCameraPosition(camera.CameraPosition.CAMERA_POSITION_BACK,
        true, this.isVideoRotation)
    } else {
      this.mAction.changeCameraPosition(camera.CameraPosition.CAMERA_POSITION_FRONT,
        this.videoState !== RecordingState.READY, this.isVideoRotation);
    }
  }

  private cameraSwitchOnChange(): void {
    this.isShowActionMenu = false;
    if (this.state.videoState !== RecordingState.READY) {
      return;
    }
    PreferencesService.getInstance().getFunctionValue(PersistType.FOREVER, FunctionId.MIRROR, false);
    if (this.state.videoState !== RecordingState.READY) {
      this.isVideoRotation = !this.isVideoRotation;
      HiLog.d(TAG, 'this.isVideoRotation' + this.isVideoRotation);
    } else {
      HiLog.d(TAG, 'this.isVideoRotation' + this.isVideoRotation);
      this.isVideoRotation = false;
    }

    let frameRate: number = CameraBasicService.getInstance().getVideoFrameRate();
    this.onSwitchCameraUp();
    this.mAction.uiDisabled();
    const functionImpl: BaseFunction = FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION);
    const frameRateSwitching: BaseFunction = FeatureManager.getInstance().getFunction(FunctionId.FRAME_RATE);
    if (this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      this.mAction.cameraSwitchOnChange(false);
      this.changeCameraPositionToBack(functionImpl);
    } else {
      this.mAction.cameraSwitchOnChange(true);
      this.changeCameraPositionToFront(frameRate, functionImpl, frameRateSwitching);
    }
    this.rotateCircle();
    return;
  }

  private onCollaborateSwitchCamera(): void {
    BlurAnimateUtil.generatePixelMapFromSurface();
    this.onSwitchCameraDown();
    setTimeout((): void => {
      BlurAnimateUtil.setInSwitchCamera(true)
      this.cameraSwitchOnChange();
    }, CLICK_DELAY);
  }

  private onTouchButton(event?: TouchEvent): void {
    if (!this.uiEnable) {
      return;
    }
    if (GlobalContext.get().getIsPicker() && PickerUiService.getInstance().getCaptureState()) {
      return;
    }
    if (event?.type === TouchType.Down) {
      BlurAnimateUtil.generatePixelMapFromSurface();
      this.onSwitchCameraDown();
    } else if (event?.type === TouchType.Up) {
      BlurAnimateUtil.setInSwitchCamera(true);
      if (this.enableScreenReader) {
        AccessibilityUtils.sendAnnounceAccessibilityEvent(this.cameraPosition ===
        camera.CameraPosition.CAMERA_POSITION_FRONT ?
          ResGetter.getStringSafe($r('app.string.accessibility_camera_picker_front')) :
          ResGetter.getStringSafe($r('app.string.accessibility_camera_picker_back')))
      }
      this.cameraSwitchOnChange();
    } else if (event?.type === TouchType.Cancel) {
      this.onSwitchCameraUp();
    }

    if ((this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2) && ((event?.type === TouchType.Up) ||
      (event?.type === TouchType.Cancel))) {
      this.customDialogViewController?.close();
    }
    return;
  }

  private onResolutionChange(): void {
    this.resolutionStore.isResolutionChange = false;
    return;
  }

  private getCircleBackgroundColor(): ResourceColor {
    return this.videoState === RecordingState.READY ||
      this.videoState === RecordingState.STOPPING ? '#334d4d4d' : Color.Transparent;
  }

  private getCameraSwitchVis(): boolean {
    HiLog.i(TAG, `mHideThumbnailAndSwitchButton: ${this.mHideThumbnailAndSwitchButton}, mode: ${this.state.mode}`);
    return this.slowRecordingCompVisible && this.isShow &&
    this.mHideThumbnailAndSwitchButton;
  }

  private getLemAnimateParam(): AnimateParam | undefined {
    if (this.getCameraSwitchVis()) {
      return { curve: Curve.Sharp, duration: AnimSpecifications.ANIM_DURATION_150 }
    } else {
      return undefined;
    }
  }

  private getButtonColor(): string | Color {
    return Color.White;
  }

  build() {
    RelativeContainer() {
      Column()
        .id('Circle')
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .width(44)
        .height(44)
        .backgroundColor(this.getCircleBackgroundColor())
        .border({
          color: this.getButtonColor(),
          width: 1.5,
          radius: this.isShowSubScreenRadius ? 0 : 22
        })
        .scale(this.circleScale)
        .opacity(this.circleOpacity)
        .rotate(this.circleRotation)

      Image(this.defaultImgSrc)
        .width(24)
        .height(24)
        .objectFit(this.imgFit)
        .aspectRatio(1)
        .fillColor(this.getButtonColor())
        .rotate({ angle: this.rotateAngle })
        .animation({
          duration: this.getAnimationDuration(),
          curve: Curve.Friction,
          iterations: 1,
          playMode: PlayMode.Normal,
          onFinish: () => {
            HiLog.i(TAG, 'onFinish');
          },
        })
        .draggable(false)
        .id('RotateImageView')
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .key(ComponentIdKeys.SWITCH_CAMERA_1)
        .opacity(this.innerOpacity)
        .scale(this.innerScale)
    }
    // Distinguish the front and rear of the camera for auto Testing
    .key(`cameraPosition:${this.cameraPosition}`)
    .width('100%')
    .height('100%')
    .accessibilityNextFocusId('BackButton')
    .onTouch((event?: TouchEvent) => {
      // if (!event || !this.uiEnable || this.disEnableClickState) {
      // 暂时删除disEnableClickState的判断以免拍照过后无法使用前后置切换
      if (!event || !this.uiEnable) {
        HiLog.i(TAG, `switch disable status:${this.uiEnable},${this.disEnableClickState}.`);
        return;
      }
      this.onTouchButton(event);
    })
    .width(44)
    .aspectRatio(1)
    .visibility(this.getCameraSwitchVis() ? Visibility.Visible : Visibility.Hidden)
    .animation(this.getLemAnimateParam())
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
    .accessibilityGroup(true)
    .accessibilityText(this.getABText(this.cameraPosition))
    .accessibilityDescription(`${ResGetter.getStringSafe($r('app.string.accessibility_button'))} ${
    ResGetter.getStringSafe($r('app.string.accessibility_clickable'))}`)
    .clickStyle()
    .gesture(
      LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
        .onAction((event) => {
          if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2) && this.defaultImgSrc) {
            this.createLongPressDialog(this.defaultImgSrc, true);
            this.customDialogViewController?.open();
          }
        })
    )
  }

  @Styles
  private clickStyle() {
    .onClick((event) => {
      // 仅在无障碍服务开启时生效
      if (event && this.enableScreenReader && this.isOpenTouchGuide && this.uiEnable) {
        if (GlobalContext.get().getIsPicker() && PickerUiService.getInstance().getCaptureState()) {
          return;
        }
        BlurAnimateUtil.generatePixelMapFromSurface();
        this.onSwitchCameraDown();
        setTimeout((): void => {
          BlurAnimateUtil.setInSwitchCamera(true)
          this.cameraSwitchOnChange();
          AccessibilityUtils.sendAnnounceAccessibilityEvent(
            this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT ?
              ResGetter.getStringSafe($r('app.string.accessibility_camera_picker_back')) :
              ResGetter.getStringSafe($r('app.string.accessibility_camera_picker_front')));
        }, CLICK_DELAY);
      }
    })
  }

  private getABText(position: camera.CameraPosition): string {
    HiLog.i(TAG, 'getABText position ' + position);
    return ResGetter.getStringSafe(this.isOpenTouchGuide ?
      (position === camera.CameraPosition.CAMERA_POSITION_FRONT ?
        $r('app.string.accessibility_camera_picker_front') : $r('app.string.accessibility_camera_picker_back')) : '');
  }

  private updateDensity() {
    HiLog.i(TAG, 'updateDensity density=' + this.density);
    this.isShowSubScreenRadius = this.density === 1.5;
  }

  private createLongPressDialog(iconRes: ResourceStr, needFillColor: boolean): void {
    this.customDialogViewController = new CustomDialogController({
      builder: LongPressDialogView({
        cancel: () => {
        },
        confirm: () => {
        },
        iconItem: {
          iconRes: iconRes,
          isEnabled: true,
        },
        needFillColor: needFillColor
      }),
      maskColor: Color.Transparent,
      isModal: true,
      customStyle: true
    })
  }
}