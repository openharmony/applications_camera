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

import Curves from '@ohos.curves';
import lazy { lottie, AnimationItem } from '../../utils/LazyImportUtil';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { OhCombinedState, Dispatch, Unsubscribe, getStates } from '../../redux';
import lazy { Action, ActionData, UiStateMode } from '../../redux/actions/Action';
import lazy { RecordAction } from '../recordcontrol/RecordAction';
import lazy { RecordingState } from '../recordcontrol/RecordAction';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { FunctionAction } from '../core/FunctionAction';
import lazy { RecordMode } from '../recordcontrol/RecordMode';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { CameraAction, CameraRunningState } from '../../camera/uithread/CameraAction';
import lazy { CaptureAction } from './CaptureAction';
import lazy { AudioControlShutterButton } from './AudioControlShutterButton';
import lazy { UIOperationType } from '../../component/uicomponent/UIOperationType';
import lazy { VideoTimer } from '../../component/videoTimer/VideoTimer';
import camera from '@ohos.multimedia.camera';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { PowerKeyService } from '../../service/powerKey/PowerKeyService';
import lazy { WindowEventData, WindowStatusChangeActionData } from '../../utils/types';
import window from '@ohos.window';
import lazy { CaptureService } from './CaptureService';
import lazy { FlashMode } from '../enumbase/FlashMode';
import lazy { TipService } from '../../component/tip/TipService';
import lazy { ShutterButtonType, ShutterController } from './ShutterController';
import lazy { VibratorService } from '../../component/vibration/VibratorService';
import lazy { CameraProxy } from '../../camera/uithread/CameraProxy';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { OutputType } from '../outputswitcher/OutputType';
import lazy { OutputSwitcher } from '../outputswitcher/OutputSwitcher';
import display from '@ohos.display';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { ContextManager } from '../../service/context/ContextManager';
import lazy { systemDateTime } from '../../utils/LazyImportUtil';
import ResGetter from '../../utils/ResGetter';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import lazy { ThumbnailService } from '../../component/thumbnail/ThumbnailService';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import lazy { PickerWindowType } from '../../component/picker/PickerWindowType';
import lazy { CaptureScene } from './CaptureFunction';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { ContinuumVideoButton } from './ContinuumVideoButton';
import lazy { AccessibilityUtils } from '../../utils/AccessibilityUtils';
import lazy { simpleStringify } from '../../utils/SimpleStringify';
import lazy { RecordController, RecordType } from '../recordcontrol/RecordController';
import lazy { MemoryService } from '../../service/Memory/MemoryService';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { PickerAction } from '../../service/picker/PickerAction';
import lazy { execAction } from '../../redux/ActionRegistry';
import lazy { BlurAnimateUtil } from '../../utils/BlurAnimateUtil';
import lazy { AuxiliaryMode } from '../enumbase/AuxiliaryMode';
import lazy { reduxSubscribe } from '../../redux/Store';
import lazy { TimeLapseActionType } from '../../redux/actions/TimeLapseActionType';
import lazy { FloatingShutterActionType } from '../../redux/actions/FloatingShutterActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { FunctionActionType } from '../../redux/actions/FunctionActionType';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { CollaborateControlActionType } from '../../redux/actions/CollaborateControlActionType';
import lazy { CaptureActionType } from '../../redux/actions/CaptureActionType';
import lazy { LeftRightSwipeActionType } from '../../redux/actions/LeftRightSwipeActionType';
import type { TimeLapseRecordMessage } from '../../camera/DataType';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { WindowActionType } from '../../redux/actions/WindowActionType';
import lazy { LocationMessage } from '../../service/location/LocationMessage';
import lazy { LocationManager } from '../../service/location/LocationManager';
import {
  LeftRightSwipeWorkerCaptureService
} from '../../component/leftrightswipecontrol/LeftRightSwipeWorkerCaptureService';

export const QUEUE_SIZE: number = 4;

export const MIN_LOADING_MODE_DURATION: number = 800;

const CAPTURE_DELAY: number = 10;
const RECORD_UP_DELAY: number = 10;
const IMMERSIVE_DELAY: number = 250;
const INVALID_CAPTURE_DURATION: number = 0;
const MAX_CLICK_MODE_DURATION: number = 350;
const MIN_COUNTER_DOWN_MODE_DURATION: number = 1500;
const PRO_SHUTTER_THRESHOLD: number = 1000000;
const SHUTTER_ANIMATE_DELAY: number = 100;
const CAN_AUDIO_SHUTTER_DELAY: number = 1000;
const TIP_DURING: number = 3000;
const STITCHING_STATUS_HIDE_DELAY = 1000;

/* instrument ignore file */
const TAG: string = 'ShutterButton';
const NIGHT_START_LOOP: string = 'nightStartLoop';
const NIGHT_STOP_LOOP: string = 'nightStopLoop';
const NIGHT_CAPTURE_FIRST_LOOP: string = 'nightCaptureFirstLoop';
const NIGHT_CAPTURE_SECOND_LOOP: string = 'nightCaptureSecondLoop';

const STITCHING_FIRST_LOOP: string = 'stitchingFirstLoop';
const STITCHING_SECOND_LOOP: string = 'stitchingSecondLoop';

const NIGHT_EXPOSURE_PATH: string = 'common/lottie/night_exposure.json';
const NIGHT_CAPTURE_FIRST_PATH: string = 'common/lottie/night_capture_first.json';
const NIGHT_CAPTURE_SECOND_PATH: string = 'common/lottie/night_capture_second.json';
const LIGHT_PAINTING_CAPTURE_FIRST_LOOP: string = 'lightPaintingCaptureFirstLoop';
const LIGHT_PAINTING_CAPTURE_PATH: string = 'common/lottie/light_painting_capture.json';
const SHUTTER_OUT_SHADE_COLOR: string = '#334d4d4d';
const REFRESH_MINIMUM_TIME: number = 50;
const SLEEP: Function = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));
const CLICK_DOWN_CAPTURE_SUPPORT_MODE: ModeType[] = [ModeType.PHOTO];

class FrameStartData {
  public isPreviewFrameStart: boolean = false;
}

class VideoErrorData {
  public code: number = 0;
  public msg: string = '';
}

class VolumeKeyPhotoData {
  public isDown: boolean = false;
}

class PickerData {
  public isPicker: boolean = false;
  public dbValue?: number = 0;
  public dbThreshold?: number = 0;
  public dbStateList?: number[];
}

interface ProShutterValue {
  functionId: FunctionId,
  value: number
}

interface FunctionConflictParamData {
  id: FunctionId,
  conflictParam: Object
}

class EnterImmersiveData {
  public isImmersive: boolean = false;
}

class ShutterButtonDispatcher {
  private mDispatch: Dispatch = (data) => data;
  private lastClickRefreshTime: number = 0;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  //TODO 到这里一切都是正常的
  public capture(): void {
    this.mDispatch(Action.updateIsShowParamBar(true));
    this.mDispatch(Action.updateIsShowExtendBar(false));
    this.mDispatch(Action.proSonChangeState(-1));
    this.mDispatch(Action.changeShowExtendComponent(FunctionId.NONE));
    this.mDispatch(CaptureAction.capture());
  }

  public startRecording(isSoundEffect: boolean = true): void {
    this.mDispatch(Action.proSonChangeState(-1));
    this.mDispatch(Action.uiStateWithMode(false, UiStateMode.EXCLUDE_PREVIEW));
    this.mDispatch(RecordAction.start(isSoundEffect));
  }

  public updateShowPickerView(showPicker: boolean): void {
    this.mDispatch(Action.updateShowPickerView(showPicker, true));
  }

  public stopRecording(): void {
    this.mDispatch(Action.uiStateWithMode(false, UiStateMode.EXCLUDE_PREVIEW));
    this.mDispatch(RecordAction.stop());
  }

  public changeTimeLapse(isShowtimeLapse: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse));
  }

  public changeTimedShot(isShowTimedShot: boolean): void {
    this.mDispatch(Action.changeTimedShot(isShowTimedShot));
  }

  public changeFunctionValue(id: FunctionId, value: number | string | boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    if (isEnterImmersive) {
      this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.FOOT_BAR));
    } else {
      this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.NULL));
    }
  }

  public confirmCapture(): void {
    this.mDispatch(CaptureAction.confirmCapture());
  }

  public confirmCaptureEffect(): void {
    this.mDispatch(Action.updateIsShowParamBar(true));
    this.mDispatch(Action.updateIsShowExtendBar(false));
    this.mDispatch(Action.proSonChangeState(-1));
    this.mDispatch(Action.changeShowExtendComponent(FunctionId.NONE));
    this.mDispatch(Action.confirmCaptureEffect());
  }

  public isClearExposureTime(): void {
    this.mDispatch(Action.isResetExposureTime());
  }

  public enableUiWithMode(uiStateMode: UiStateMode, excludeComponent: string): void {
    this.mDispatch(Action.uiStateWithMode(true, uiStateMode, excludeComponent));
  }

  public disableUiWithMode(uiStateMode: UiStateMode, excludeComponent: string): void {
    this.mDispatch(Action.uiStateWithMode(false, uiStateMode, excludeComponent));
  }

  public disAbleModeBarChanged(isNeedDisShowingMode: boolean): void {
    this.mDispatch(Action.disAbleModeBarChanged(isNeedDisShowingMode));
  }

  public hideThumbnailAndSwitchButton(): void {
    this.mDispatch(Action.hideThumbnailAndSwitchButton());
  }

  public longExposureShutter(): void {
    AppStorage.setOrCreate('longExposureShutter', true);
    this.mDispatch(Action.longExposureShutter());
  }

  public longExposureShutterEnd(): void {
    AppStorage.setOrCreate('longExposureShutter', false);
    this.mDispatch(Action.longExposureShutterEnd());
  }

  public countDownShutter(): void {
    this.mDispatch(Action.countDownShutter());
  }

  public countDownShutterEnd(): void {
    this.mDispatch(Action.countDownShutterEnd());
  }

  public captureEnd(): void {
    this.mDispatch(Action.captureEnd());
  }

  public proSonChangeState(iconId: number): void {
    this.mDispatch(Action.proSonChangeState(iconId));
  }

  public uiDisabled(): void {
    this.mDispatch(Action.uiState(false));
  }

  public uiEnabled(): void {
    this.mDispatch(Action.uiState(true));
  }

  public async longClickStatusChange(isLongClicked: boolean): Promise<void> {
    let currentTime: number = Date.now();
    let refreshInterval: number = (currentTime - this.lastClickRefreshTime) < 0
      ? currentTime : (currentTime - this.lastClickRefreshTime);
    HiLog.i(TAG, `clickStatus refreshInterval:${refreshInterval} for longclick ${isLongClicked}`);
    let pauseTime: number = 0;
    if (refreshInterval < REFRESH_MINIMUM_TIME) {
      pauseTime = REFRESH_MINIMUM_TIME - refreshInterval;
      await SLEEP(pauseTime);
      HiLog.i(TAG, `clickStatus pause finish for :${refreshInterval}`);
    }
    this.lastClickRefreshTime = currentTime + pauseTime;
    HiLog.i(TAG, `longClickChange ${isLongClicked}`);
  }

  public isShowExtendBarAndParamBar(): void {
    this.mDispatch(Action.updateIsShowParamBar(true));
    this.mDispatch(Action.updateIsShowExtendBar(false));
  }

  public async startLightPainting(): Promise<void> {
    const startTimeSeconds: number = await systemDateTime.getRealTime(false);
    this.mDispatch(execAction('LightPaintingAction', 'start'));
    this.mDispatch(execAction('LightPaintingAction', 'setStartSeconds', startTimeSeconds + CAPTURE_DELAY));
    this.mDispatch(execAction('LightPaintingAction', 'setLightPaintingTimerShow', true));
  }

  public showLightPaintingFlashTimer(): void {
    this.mDispatch(execAction('LightPaintingAction', 'setLightPaintingFlashTimerShow', true));
  }

  public stopLightPaintingFlashTimer(): void {
    this.mDispatch(execAction('LightPaintingAction', 'setLightPaintingFlashTimerShow', false));
  }

  public stopLightPaintingTimer(): void {
    this.mDispatch(execAction('LightPaintingAction', 'setLightPaintingTimerShow', false));
  }

  public startPanorama(): void {
    this.mDispatch(Action.startPanorama());
  }

  public stitchingCaptureStart(): void {
    this.mDispatch(Action.stitchingCaptureStart())
  }

  public stitchingCaptureEnd(): void {
    this.mDispatch(Action.stitchingCaptureEnd())
  }

  public hideStitchingStatusView(delayTime?: number): void {
    this.mDispatch(execAction('StitchingAction', 'hideStitchingStatus', delayTime ? delayTime : 0));
  }

  public endPanorama(): void {
    this.mDispatch(Action.endPanorama());
  }

  public nightCapture(): void {
    this.mDispatch(CaptureAction.nightCapture());
  }

  public hideExtendBar(): void {
    this.mDispatch(Action.updateIsShowParamBar(true));
    this.mDispatch(Action.updateIsShowExtendBar(false));
  }
}

@Component
export struct ShutterButton {
  private isShutterButtonLongClick: boolean = false;
  @Link touchEvent: TouchEvent | null;
  private currentTouchEvent: TouchEvent | null = null;
  private timeoutID: number = 0;
  @State @Watch('changeOuterBackground') isLrShutterShown: boolean = false;
  @Link isInLrImmersive: boolean;
  private mBase: BaseComponent = new BaseComponent();
  private cameraManager: camera.CameraManager | undefined;
  type: ButtonType = ButtonType.Normal;
  stateEffect: boolean = false;
  @State uiEnable: boolean = false;
  @State excludeComponent: string = UIOperationType.NULL;
  @State mode: ModeType = ModeType.NONE;
  @State isShowtimeLapse: boolean = false;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  @State isLockRotation: boolean = true;
  private exposureTime: number = 0;
  @State estimatedCaptureDuration: number = 0;
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @State isShowCapture: boolean = false;
  @State isShowVideo: boolean = false;
  @State isShowNight: boolean = false;
  @State isShowLongExposure: boolean = false;
  @State isShowLoading: boolean = false;
  @State isShowCountDown: boolean = false;
  @State captureBtnScale: ScaleOptions = { x: 1, y: 1 };
  @State captureBtnOpacity: number = 1;
  @State captureBtn2Opacity: number = 1;
  @State videoBtn1Scale: ScaleOptions = { x: 1, y: 1 };
  @State videoBtn1Opacity: number = 1;
  @State videoBtn2Scale: ScaleOptions = { x: 0.5, y: 0.5 };
  @State videoBtn2Opacity: number = 0;
  @State videoWidth: number = AnimSpecifications.ANIM_VIDEO_BUTTON_WIDTH_END;
  @State videoRadius: number = AnimSpecifications.ANIM_VIDEO_BUTTON_RADIUS_END;
  @State videoColor: Color | string = AnimSpecifications.ANIM_VIDEO_BUTTON_COLOR_END;
  @State nightBtn1Scale: ScaleOptions = { x: 1, y: 1 };
  @State nightBtn1Opacity: number = 1;
  @State nightBtn2Scale: ScaleOptions = { x: 1, y: 1 };
  @State nightBtn2Opacity: number = 1;
  @State audioCaptureBtnScale: ScaleOptions = { x: 1, y: 1 };
  @State audioCaptureBtnVisibility: Visibility = Visibility.Visible;
  @State nightWidth: number = AnimSpecifications.ANIM_NIGHT_BUTTON_WIDTH_END;
  @State nightRadius: number = AnimSpecifications.ANIM_NIGHT_BUTTON_RADIUS_END;
  @State nightColor: Color = AnimSpecifications.ANIM_NIGHT_BUTTON_COLOR_END;
  @State confirmCaptureState: boolean = false;
  @State nightShutterStatus: boolean = false;
  @State audioControlShutterStatus: boolean = true;
  @State nightStartCaptureState: boolean = false;
  @State nightCaptureFirstFinish: boolean = false;
  @State loadingCaptureFirstFinish: boolean = false;
  @State shouldExitLongExposure: boolean = false;
  @State captureBtnWidth: number = AnimSpecifications.ANIM_NIGHT_BUTTON_WIDTH_END;
  @State captureBtnRadius: number = AnimSpecifications.ANIM_NIGHT_BUTTON_RADIUS_END;
  private mAction: ShutterButtonDispatcher = new ShutterButtonDispatcher();
  private mCaptureService: CaptureService = CaptureService.getInstance();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State audioControlType: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_NONE;
  @State rotateAngle: number = 0;
  @State @Watch('rotateAngleChanged') rotateAngleWatch: number = 0;
  @Prop innerHorizontalOffset: number = 0;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @StorageLink('nightCaptureStarted') nightCaptureStarted: boolean = false;
  @StorageLink('isOpenOrCloseTreasureBox') isOpenOrCloseTreasureBox: boolean = false; //百宝箱是否在做开关动效中
  // picker
  private singleStagePhotoCaptured: boolean = false;
  private isPicker: boolean = false;
  @State pickerWindowType: PickerWindowType = PickerWindowType.COLLAPSED_VERTICAL_FULL;
  // 夜景后置拍照按钮三种动画：小圆点消失、圆环动态更新、小圆点静止
  private antiAliasingSetting: RenderingContextSettings = new RenderingContextSettings(true);
  private mLoopStartController: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.antiAliasingSetting);
  private mLoopsStopController: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.antiAliasingSetting);
  private mLoopCaptureFirstController: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(this.antiAliasingSetting);
  private mLoopCaptureSecondController: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(this.antiAliasingSetting);
  private exposureStartAnimationItem: AnimationItem | undefined = undefined;
  private exposureStopAnimationItem: AnimationItem | undefined = undefined;
  private captureStartFirstAnimationItem: AnimationItem | undefined = undefined;
  private captureStartSecondAnimationItem: AnimationItem | undefined = undefined;
  private interval: number = 0;
  private timelapseDurationTimerId: number = Number.MIN_VALUE;
  private nightTimerId: number = Number.MIN_VALUE;
  private nightImmersiveTimerId: number = Number.MIN_VALUE;
  @State private isDuringSavePowerMode: boolean = false;
  @State currentButtonType: ShutterButtonType = ShutterButtonType.NULL;
  private mHasClickDownCapture: boolean = false;
  private mCountDownBtnDuration: number = 0;
  private mWaitingThumbnailAnimation: boolean = false;
  private mIsLongCaptureWaitingClickUp: boolean = false;
  private horizontallyArranged: boolean = true;
  @StorageLink('isTimeLapseVideoRecording') isTimeLapseVideoRecording: boolean = false;
  private isDelaySendCaptureEnd: boolean = false;
  private isFrameStarted: boolean = false;
  private isIgnoreTouch = false;
  @StorageLink('slowRecordingCompVisible') slowRecordingCompVisible: boolean = true;
  @State collapsStatus: display.FoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  @State @Watch('updateDensity') density: number = 1 //DisplayService.getInstance().getDisplay().densityPixels;
  @State isShowSubScreenRadius: boolean = false;
  @State isTakePhoto: boolean = false;
  @State proShutterValue: number = 0;
  @StorageLink('isProShutterCaptureState') isProShutterCapture: boolean = false;
  @State isHalfCollapsLEM: boolean = false;
  @State isVdeCollapsed: boolean = false;
  private outerLottiePath = NIGHT_EXPOSURE_PATH;
  private outerFirstLoopLottieName = NIGHT_CAPTURE_FIRST_LOOP;
  private isLottieLoop: boolean = false;
  private screenWidth: number = 0;
  private screenHeight: number = 0;
  private immersiveDelay = IMMERSIVE_DELAY;
  private shutterDownTime: number = -1;
  @State shutterOutsideBackground: ResourceColor = SHUTTER_OUT_SHADE_COLOR;
  @State shutterAllVisibility: Visibility = Visibility.Visible;
  private invisibleTimeout: number = Number.MIN_VALUE;
  private shouldApplyShade: boolean = false;
  // 多任务停流方案，快门状态需要重置
  private isMultiTaskStopStream: boolean = CameraAppCapability.getInstance().getIsSupportStopStreamToMultiTask();
  private isBackground: boolean = false;
  @StorageLink('onActionMenuShow') isShowActionMenu: boolean = false;

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.rotateAngle = getStates().get<number>('contextReducer', 'rotateAngle');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.rotateAngleWatch = state.get<number>('contextReducer', 'rotateAngle');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.density = state.get<number>('collapsReducer', 'density');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.screenWidth = state.get<number>('windowReducer', 'windowWidth');
      this.screenHeight = state.get<number>('windowReducer', 'windowHeight');
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isShowtimeLapse = state.get<boolean>('settingReducer', 'isShowtimeLapse');
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.isLockRotation = state.get<boolean>('windowReducer', 'isLockRotation');
      this.exposureTime = state.get<number>('contextReducer', 'exposureTime');
      this.estimatedCaptureDuration = state.get<number>('contextReducer', 'estimatedCaptureDuration');
      this.excludeComponent = state.get<string>('contextReducer', 'excludeComponent');
      this.isDuringSavePowerMode = state.get<boolean>('contextReducer', 'isDuringSavePowerMode');
      this.isShutterButtonLongClick = state.get<boolean>('leftRightSwipeReducer', 'longClicked');
      this.isLrShutterShown = state.get<boolean>('leftRightSwipeReducer', 'lrShutterShown');
      this.collapsStatus = state.get<display.FoldStatus>('collapsReducer', 'collapsStatus');
      this.pickerWindowType = state.get<PickerWindowType>('windowReducer', 'pickerWindowType');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.initMode();
    this.mEventBus.on(TimeLapseActionType.START_VIDEO_ANIM, this.startVideoAnim.bind(this), this.mBase.hashCode());
    this.mEventBus.on([CameraActionType.CHANGE_MODE,
      CameraActionType.CHANGE_OUTPUT_TYPE,
      CameraActionType.SWITCH_CAMERA_CHANGE_MODE,
      CameraActionType.SWITCH_CAMERA, CameraActionType.STARTED], () => this.modeOnChange(), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.ERROR, this.onVideoError.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.CHANGE_WINDOW_EVENT_TYPE, this.onChangeWindowEventType.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.CHANGE_EXTENSION_WINDOW_EVENT_TYPE,
      this.onChangeExtensionWindowEventType.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(FloatingShutterActionType.FLOATING_SHUTTER_BUTTON_CLICK,
      this.clickFloatingShutterButton.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.CAPTURE, this.onCollaborateControlCapture.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.VIDEO, this.onCollaborateControlVideo.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.AUDIO_CONTROL_SHUTTER_BUTTON, this.audioControlShutterButton.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.DEV_ON_SHUTDOWN, this.onDevShutdown.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_NIGHT_CAPTURE_END, this.captureEnd.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.PREEMPTION_WITH_ERROR, this.onBackground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_DELAY_SEND_CAPTURE_END, this.delaySendCaptureEnd.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHANGE_TIME_LAPSE, this.timeLapseEnd.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.VOLUME_KEY_EVENT, this.volumeKeyEventShutter.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_POWER_KEY_DURATION_ONE_SECOND, this.powerKeyDownDuration.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.RICH_CAPTURE_NEXT, this.onRichCaptureNext.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_FRAME_SHUTTER_END, this.onFrameShutterEnd.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_PICKER,
      this.onPickerReCapture.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(LeftRightSwipeActionType.FORCE_EXIT_LR_BURST, this.forceClickUp.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(LeftRightSwipeActionType.FORCE_EXIT_LR_RECORD,
      this.forceClickUpRecord.bind(this), this.mBase.hashCode());
    this.mEventBus.on(LeftRightSwipeActionType.RESET, this.doShutterExpandAnimation.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.IS_REMOTECAPTURE_EVENT, this.remoteCaptureEvent.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_COUNT_DOWN_SHUTTER_AFTER_TIMELAPSE,
      this.playLongExposureAfterTimeLapse.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_IS_ENTER_IMMERSIVE, this.isEnterImmersive.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM, this.onConflictParamChange.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, this.onFunctionChange.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHANGE_TIMED_SHOT, this.timeLapseEnd.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.IS_READY_FOR_NEXT_AUTO_CAPTURE, this.readyForNextAutoCapture.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_PREVIEW_FRAME_START, this.onFrameStartStatusChanged.bind(this),
      this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  onConflictParamChange(data: FunctionConflictParamData) {
  }

  private readyForNextAutoCapture(): void {
    this.photoProcess(false, false);
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    this.clearTimer();
    this.mAction.isClearExposureTime();
    this.lottieAnimationDestroy();
    HiLog.i(TAG, 'aboutToDisappear X.');
  }

  private rotateAngleChanged(): void {
    if (this.rotateAngle === this.rotateAngleWatch) {
      return;
    }
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_300,
      curve: Curve.Friction,
      iterations: 1,
      playMode: PlayMode.Normal,
    }, () => {
      this.rotateAngle = this.rotateAngleWatch
    });
  }

  private lottieAnimationDestroy(): void {
    // 只销毁当前组件内的lottie动画
    this.exposureStartAnimationItem?.destroy();
    this.exposureStopAnimationItem?.destroy();
    this.captureStartFirstAnimationItem?.destroy();
    this.captureStartSecondAnimationItem?.destroy();
  }

  private onFrameStartStatusChanged(data: FrameStartData) {
    this.isFrameStarted = data.isPreviewFrameStart;
  }

  private onRichCaptureNext(): void {
    this.photoProcess(false, true);
  }

  private clearTimelapseDurationTimer(): void {
    HiLog.i(TAG, 'clearTimelapseDurationTimer');
    if (Number.MIN_VALUE !== this.timelapseDurationTimerId) {
      clearTimeout(this.timelapseDurationTimerId);
    }
  }

  private onDevShutdown(): void {
    this.onStatePaused('devOnShutDown');
  }

  private onChangeWindowEventType(data: WindowEventData): void {
    if (data.windowStageEventType === window.WindowStageEventType.PAUSED) {
      this.onStatePaused('onStagePaused');
      this.forceClickUp();
      if (this.isMultiTaskStopStream) {
        HiLog.i(TAG, 'isMultiTaskStopStream, onBackground reset shutterButton status');
        this.onBackground();
      }
    } else if (data.windowStageEventType === window.WindowStageEventType.RESUMED) {
      if (this.isMultiTaskStopStream) {
        HiLog.i(TAG, 'isMultiTaskStopStream, onForeground reset shutterButton status');
        this.onForeground();
      }
    }
    if (!this.cameraManager) {
      this.cameraManager = camera.getCameraManager(ContextManager.getInstance().getAbilityStageContext());
    }
    if (data.windowStageEventType === window.WindowStageEventType.INACTIVE &&
      (this.cameraManager.isCameraMuted())) {
      if (this.videoState !== RecordingState.READY &&
        this.videoState !== RecordingState.STOPPING &&
        this.videoState !== RecordingState.ERROR) {
        this.mAction.stopRecording();
        this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
        this.endVideoAnim();
      }
      clearTimeout(this.nightImmersiveTimerId);
    }
  }

  private onChangeExtensionWindowEventType(data: Record<'windowEventType', window.WindowEventType>): void {
    if (data.windowEventType === window.WindowEventType.WINDOW_INACTIVE && this.videoState !== RecordingState.READY &&
      this.videoState !== RecordingState.STOPPING) {
      this.endVideoAnim();
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
    }
  }

  private powerKeyDownDuration() {
    if (this.videoState !== RecordingState.READY && this.videoState !== RecordingState.STOPPING &&
      this.videoState !== RecordingState.ERROR) {
      HiLog.i(TAG, 'power key duration one second triggered recording to stop.');
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
      this.endVideoAnim();
    }
  }

  /*
   * 相机适配非智能表遥控拍照
   */

  private remoteCaptureEvent(): void {
    if (this.isShowtimeLapse) {
      return;
    }
    if (MemoryService.getInstance().isFullStorage()) {
      return;
    }
    let isDown: boolean = false;
    if (AppStorage.get('isLemCollaps') ||
    this.isDuringSavePowerMode ||
    this.isProShutterCapture ||
      getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') !== CameraRunningState.STARTED ||
      (!this.uiEnable && isDown)) {
      return;
    }
    if (this.currentButtonType === ShutterButtonType.NORMAL_CAPTURE || this.isShowCapture) {
      this.mAction.disableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.CAPTURE_BUTTON);
      this.photoShutterDownAnimate();
      this.shutterDownTime = Date.now();
      this.photoShutterDownCapture();
      this.photoProcess(isDown, false);
      if (!isDown) {
        this.handleClickDownCaptureWhenUp();
      }
    }
  }

  private onFunctionChange(data: ActionData): void {
  }

  private volumeKeyEventShutter(data: VolumeKeyPhotoData) {
    if (MemoryService.getInstance().isFullStorage()) {
      return;
    }
    if (this.isPicker && AppStorage.get('inPrivacyLearnMore')) {
      return;
    }
    let isDown: boolean = data.isDown;
    if (AppStorage.get('isLemCollaps') ||
    this.isDuringSavePowerMode ||
    this.isProShutterCapture ||
      getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') !== CameraRunningState.STARTED ||
      (!this.uiEnable && isDown)) {
      return;
    }
    if (this.currentButtonType === ShutterButtonType.NORMAL_CAPTURE || this.isShowCapture) {
      this.photoProcess(isDown, false);
      if (!isDown) {
        this.handleClickDownCaptureWhenUp();
      }
    }
    if (this.isShowVideo) {
      this.videoProcess(isDown);
    }
  }

  private onPickerReCapture(data: ActionData): void {
    // picker一次只允许拍一张
    if (!data['showPicker']) {
      this.singleStagePhotoCaptured = false;
    }
  }

  private onStatePaused(event: string): void {
    HiLog.i(TAG, `${event} event triggered. Video state is ${this.videoState}`);
    if (this.videoState !== RecordingState.READY &&
      this.videoState !== RecordingState.STOPPING &&
      this.videoState !== RecordingState.ERROR) {
      HiLog.i(TAG, `${event} triggered video stopped. `);
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
      this.endVideoAnim();
      return;
    }
    if (this.isShowtimeLapse) {
      this.endVideoAnim();
    }
  }

  private onVideoError(data: VideoErrorData) {
    HiLog.i(TAG, `onVideoError  errorCode : ${data.code} errorMsg : ${data.msg}`);
    this.mAction.stopRecording();
    this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
  }

  private resetLongExposureState() {
    HiLog.i(TAG, 'resetLongExposureState');
    this.isShowLongExposure = false;
    this.isShowLoading = false;
    this.isShowCountDown = false;
    this.shouldExitLongExposure = false;
    this.loadingCaptureFirstFinish = false;
    this.mCountDownBtnDuration = 0;
    this.captureBtnWidth = AnimSpecifications.ANIM_NIGHT_BUTTON_WIDTH_END;
    this.captureBtnRadius = AnimSpecifications.ANIM_NIGHT_BUTTON_RADIUS_END;
    this.resetPhotoInnerBtn();
  }

  private initMode() {
    const buttonType: ShutterButtonType = this.getNewButtonType();
    HiLog.i(TAG, `buttonType: ${buttonType}.`);
    this.isFrameStarted = getStates().get<boolean>('cameraReducer', 'isFrameStarted');
    this.isTimeLapseVideoRecording = false;
    this.getAppearAnim(buttonType)(true);
    this.currentButtonType = buttonType;
  }

  private modeOnChange() {
    const buttonType: ShutterButtonType = this.getNewButtonType();
    HiLog.i(TAG, `new buttonType: ${buttonType},${this.currentButtonType}.`);
    if (this.currentButtonType === buttonType) { // started 起流结束在次刷新shutter样式，避免快切场景ui和模式不匹配
      return;
    }
    this.isFrameStarted = false;
    this.isTimeLapseVideoRecording = false;
    if (getStates().get<boolean>('uiReducer', 'isImmersive')) {
      this.mAction.isEnterImmersive(false);
    }
    this.changeAnim(this.currentButtonType, buttonType);
  }

  private changeAnim(currentButtonType: ShutterButtonType, buttonType: ShutterButtonType) {
    switch (currentButtonType) {
      case ShutterButtonType.NULL:
        this.getAppearAnim(buttonType)(true);
        this.currentButtonType = buttonType;
        break;
      case ShutterButtonType.NORMAL_CAPTURE:
        this.photoBtnDisAppearAnim(this.getAppearAnim(buttonType), buttonType);
        break;
      case ShutterButtonType.NORMAL_VIDEO:
        this.videoBtnDisAppearAnim(this.getAppearAnim(buttonType), buttonType);
        break;
    }
  }

  private videoStateOnChange() {
    HiLog.i(TAG, `videoStateOnChange videoState:${this.videoState}.`);
    if (this.videoState === RecordingState.STOPPING) {
      this.isTimeLapseVideoRecording = true;
      this.endVideoAnim();
      if (this.isPicker) {
        const windowState: window.WindowStageEventType =
          AppStorage.get('windowStageEventType') ?? window.WindowStageEventType.SHOWN;
        HiLog.i(TAG, `windowState is ${windowState}`);
        if (windowState === window.WindowStageEventType.HIDDEN) {
          return;
        }
        StoreManager.getInstance().postMessage(PickerAction.showPickerView());
      }
    } else {
      this.isTimeLapseVideoRecording = false;
    }
  }

  private getAppearAnim(buttonType: ShutterButtonType): Function {
    HiLog.i(TAG, `getAppearAnim mode: ${this.mode}, buttonType: ${buttonType}.`);
    if (buttonType === ShutterButtonType.NORMAL_VIDEO) {
      return (): void => this.videoBtnAppearAnim();
    }
    return (): void => this.photoBtnAppearAnim();
  }

  private photoBtnAppearAnim() {
    this.isShowCapture = true;
  }

  private photoBtnDisAppearAnim(appearAnim: Function, buttonType: ShutterButtonType) {
    this.currentButtonType = buttonType;
    setTimeout(() => {
      appearAnim();
      this.isShowCapture = false;
    }, SHUTTER_ANIMATE_DELAY);
  }

  private videoBtnAppearAnim(disableAnim?: boolean) {
    this.isShowVideo = true;
    if (disableAnim) {
      return;
    }
    this.videoBtn2Scale = { x: 0.5, y: 0.5 };
    this.videoBtn2Opacity = 0;
    animateToImmediately({
      duration: 100,
      curve: Curve.Sharp
    }, () => {
      this.videoBtn2Scale = { x: 1, y: 1 };
      this.videoBtn2Opacity = 1;
    });
  }

  private videoBtnDisAppearAnim(appearAnim: Function, buttonType: ShutterButtonType) {
    this.videoBtn2Scale = { x: 1, y: 1 };
    this.videoBtn2Opacity = 1;
    let prevButtonType = this.currentButtonType;
    this.currentButtonType = buttonType;
    animateToImmediately({
      duration: 100,
      curve: Curve.Sharp,
      onFinish: () => {
        this.isShowVideo = false;
        appearAnim();
      }
    }, () => {
      this.videoBtn2Scale = { x: 0.5, y: 0.5 };
      this.videoBtn2Opacity = 0;
    });
  }

  private timeLapseBtnAppearAnim(disableAnim?: boolean) {
    this.isShowVideo = true;
    this.isShowNight = true;
    if (disableAnim) {
      return;
    }
    this.videoBtn2Scale = { x: 0.5, y: 0.5 };
    this.videoBtn2Opacity = 0;
    animateToImmediately(
      {
        duration: 100,
        curve: Curve.Sharp
      },
      () => {
        this.videoBtn2Scale = { x: 1, y: 1 };
        this.videoBtn2Opacity = 1;
      });
  }

  private timeLapseBtnDisAppearAnim(appearAnim: Function, buttonType: ShutterButtonType) {
    this.videoBtn2Scale = { x: 1, y: 1 };
    this.videoBtn2Opacity = 1;
    this.currentButtonType = buttonType;
    animateToImmediately({
      duration: 100,
      curve: Curve.Sharp,
      onFinish: () => {
        this.isShowVideo = false;
        this.isShowNight = false;
        appearAnim();
      }
    }, () => {
      this.videoBtn2Scale = { x: 0.5, y: 0.5 };
      this.videoBtn2Opacity = 0;
    });
  }

  private confirmCapture() {
    let cancelConfirmCapture: boolean = this.confirmCaptureState || !this.nightStartCaptureState;
    HiLog.i(TAG, 'confirmCapture. cancelConfirmCapture:' + cancelConfirmCapture);
    if (cancelConfirmCapture) {
      return;
    }
    this.clearTimer();
    this.endNightSmallAnim();
    this.mAction.isClearExposureTime();
    this.confirmCaptureState = true;
    if (this.isDelaySendCaptureEnd) {
      this.mAction.captureEnd();
      this.isDelaySendCaptureEnd = false;
    }
  }

  private captureEnd() {
    HiLog.i(TAG, 'captureEnd E. ');
    if (!this.confirmCaptureState) {
      return;
    }
    this.isDelaySendCaptureEnd = false;
    this.nightCaptureFirstFinish = false;
    this.nightShutterStatus = false;
    this.nightStartCaptureState = false;
    this.confirmCaptureState = false;
    const timerLapse: number = FeatureManager.getInstance().getFunction(FunctionId.TIME_LAPSE)?.getValue() as number;
    this.mAction.isEnterImmersive(false);
    if (timerLapse && timerLapse === SettingFuncDialogItemIndex.INDEX_FIF && !this.isBackground) {
    }
    HiLog.i(TAG, 'captureEnd X. ');
  }

  private delaySendCaptureEnd() {
    HiLog.i(TAG, 'delaySendCaptureEnd. ');
    this.isDelaySendCaptureEnd = true;
  }

  private onBackground() {
    this.isBackground = true;
    this.audioControlShutterStatus = true;
    if (this.isShutterButtonLongClick) {
      this.forceClickUp();
    }
    if (this.isShowLongExposure) {
      this.exitLongExposure();
    }
    this.mHasClickDownCapture = false;
    this.mWaitingThumbnailAnimation = false;
    this.buttonStatusReset();
    this.isTakePhoto = false;
    this.isTimeLapseVideoRecording = false;
  }

  private onForeground() {
    if (getStates().get<boolean>('uiReducer', 'isImmersive')) {
      this.mAction.isEnterImmersive(false);
    }
  }

  private onVdeCollapsed(data: ActionData) {
    if (!data['isVdeCollapsed']) {
      return;
    }
    HiLog.i(TAG, 'is onCollapsStatusChanged E.');
    this.onBackground();
    HiLog.i(TAG, 'is onCollapsStatusChanged X.');
  }

  private buttonStatusReset(): void {
    this.captureBtnWidth = AnimSpecifications.ANIM_NIGHT_BUTTON_WIDTH_END;
    this.captureBtnRadius = AnimSpecifications.ANIM_NIGHT_BUTTON_RADIUS_END;
    this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
    this.videoWidth = this.isVdeCollapsed ? AnimSpecifications.VDE_ANIM_VIDEO_BUTTON_WIDTH_END :
      AnimSpecifications.ANIM_VIDEO_BUTTON_WIDTH_END;
    this.videoRadius = AnimSpecifications.ANIM_VIDEO_BUTTON_RADIUS_END;
    this.videoColor = AnimSpecifications.ANIM_VIDEO_BUTTON_COLOR_END;
    this.videoBtn2Scale = AnimSpecifications.ANIM_VIDEO_BUTTON_SCALE_UP;
    this.videoBtn1Scale = AnimSpecifications.ANIM_VIDEO_BUTTON_SCALE_UP;
    this.nightWidth = AnimSpecifications.ANIM_NIGHT_BUTTON_WIDTH_END;
    this.nightRadius = AnimSpecifications.ANIM_NIGHT_BUTTON_RADIUS_END;
  }

  private isSupportMultiCaptureEffect(captureDuration: number): boolean {
    HiLog.d(TAG, `support IsSupportedEffectWhenNotEnableCapture ${CameraAppCapability.getInstance()
      .getIsSupportedEffectWhenNotEnableCapture()}`);
    return captureDuration !== INVALID_CAPTURE_DURATION && ((this.mode === ModeType.PHOTO) &&
      this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) && this.isPicker === false;
  }

  private startLoadingBtnAnimation() {
    HiLog.i(TAG, 'startLoadingBtnAnimation');
    this.isShowLoading = true;
    this.loadingCaptureFirstFinish = false;
    this.startLoadingInnerBtnAnimation();
  }

  private stopLoadingBtnAnimation() {
    HiLog.i(TAG, 'stopLoadingBtnAnimation');
    if (this.mCountDownBtnDuration < MIN_COUNTER_DOWN_MODE_DURATION) {
      VibratorService.getInstance().triggerVibrator(VibratorService.LONG_EXPOSURE_CAPTURE);
      this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
    }

    this.exitLongExposure();
  }

  private exitLongExposure() {
    HiLog.i(TAG, 'stopLoadingBtnAnimation');
    this.resetLongExposureState();
    this.mAction.isEnterImmersive(false);
    this.mAction.longExposureShutterEnd();
  }

  private onFrameShutterEnd() {
    HiLog.i(TAG, `on Frame Shutter End.${this.mHasClickDownCapture}`);
    this.isTakePhoto = false;
    if (this.mHasClickDownCapture) {
      HiLog.i(TAG, 'button down Interrupt ThumbnailAnimation');
      this.mWaitingThumbnailAnimation = true;
    } else {
      CameraProxy.getInstance().attemptPlayThumbnailAnimation();
    }

    if (!this.isShowLongExposure) {
      return;
    }

    if (this.isShowCountDown) {
      HiLog.i(TAG, 'shouldExitLongExposure');
      this.shouldExitLongExposure = true;
      return;
    }

    if (this.isShowLoading) {
      this.stopLoadingBtnAnimation();
    }
  }

  private startCountDownInnerBtnAnimation() {
    HiLog.i(TAG, 'startCountDownInnerBtnAnimation');
    animateToImmediately(
      {
        duration: 175,
        curve: Curves.cubicBezierCurve(0.4, 0, 0.2, 1.0),
      },
      () => {
        this.captureBtnWidth = AnimSpecifications.ANIM_NIGHT_BUTTON_WIDTH_START;
        this.captureBtnRadius = AnimSpecifications.ANIM_NIGHT_BUTTON_RADIUS_START;
        this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
      })
  }

  private endCountDownInnerBtnAnimation() {
    HiLog.i(TAG, 'endCountDownInnerBtnAnimation');
    animateToImmediately(
      {
        duration: 150,
        curve: Curves.cubicBezierCurve(0.4, 0, 0.2, 1.0)
      },
      () => {
        this.captureBtnWidth = AnimSpecifications.ANIM_NIGHT_BUTTON_WIDTH_END;
        this.captureBtnRadius = AnimSpecifications.ANIM_NIGHT_BUTTON_RADIUS_END;
        this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
        this.audioCaptureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
      })
  }

  private resetPhotoInnerBtn() {
    this.captureBtnWidth = AnimSpecifications.ANIM_NIGHT_BUTTON_WIDTH_END;
    this.captureBtnRadius = AnimSpecifications.ANIM_NIGHT_BUTTON_RADIUS_END;
    this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
    this.audioCaptureBtnVisibility = Visibility.Visible;
  }

  private startLoadingInnerBtnAnimation() {
    HiLog.i(TAG, 'startLoadingInnerBtnAnimation');
    animateToImmediately(
      {
        duration: 175,
        curve: Curves.cubicBezierCurve(0.4, 0, 0.2, 1.0),
      },
      () => {
        this.captureBtnWidth = AnimSpecifications.ANIM_NIGHT_BUTTON_WIDTH_END;
        this.captureBtnRadius = AnimSpecifications.ANIM_NIGHT_BUTTON_RADIUS_END;
        this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
      })
  }

  private middleNightSmallAnim() {
    HiLog.i(TAG, 'play middleNightSmallAnim. ');
    this.nightWidth = AnimSpecifications.ANIM_NIGHT_BUTTON_WIDTH_END;
    this.nightBtn2Scale = AnimSpecifications.ANIM_NIGHT_BUTTON_SCALE_UP;
    this.audioCaptureBtnScale = AnimSpecifications.ANIM_NIGHT_BUTTON_SCALE_UP;
    animateToImmediately(
      {
        duration: 125,
        curve: Curves.cubicBezierCurve(0.4, 0, 0.2, 1.0),
      },
      () => {
        this.nightWidth = AnimSpecifications.ANIM_NIGHT_BUTTON_WIDTH_MIDDLE;
        this.nightBtn2Scale = AnimSpecifications.ANIM_NIGHT_BUTTON_SCALE_DOWN;
        this.audioCaptureBtnScale = AnimSpecifications.ANIM_AUDIO_CONTROL_CAPTURE_BUTTON_SCALE_DOWN;
      })
  }

  private endNightSmallAnim() {
    HiLog.i(TAG, 'play endNightAnim. ');
    this.nightWidth = AnimSpecifications.ANIM_NIGHT_BUTTON_WIDTH_START;
    this.nightRadius = AnimSpecifications.ANIM_NIGHT_BUTTON_RADIUS_START;
    this.nightBtn2Scale = AnimSpecifications.ANIM_NIGHT_BUTTON_TWO_SCALE_DOWN;
    this.nightColor = AnimSpecifications.ANIM_NIGHT_BUTTON_COLOR_END;
    animateToImmediately(
      {
        duration: 150,
        curve: Curves.cubicBezierCurve(0.4, 0, 0.2, 1.0)
      },
      () => {
        // shape C-B
        this.nightWidth = AnimSpecifications.ANIM_NIGHT_BUTTON_WIDTH_END;
        this.nightRadius = AnimSpecifications.ANIM_NIGHT_BUTTON_RADIUS_END;
        this.nightColor = AnimSpecifications.ANIM_NIGHT_BUTTON_COLOR_MIDDLE;
        // A scale 0-1
        this.nightBtn2Scale = AnimSpecifications.ANIM_NIGHT_BUTTON_SCALE_UP;
        this.audioCaptureBtnScale = AnimSpecifications.ANIM_NIGHT_BUTTON_SCALE_UP;
        // 流光快门/高像素/夜景模式快门动效结束之后，声控开启状态下将按钮重置为声控拍照样式
        if (!this.nightShutterStatus &&
          (this.audioControlType === SettingFuncDialogItemIndex.INDEX_SEC ||
            this.audioControlType === SettingFuncDialogItemIndex.INDEX_THR)) {
          this.audioControlShutterStatus = true;
        }
      })
  }

  private timeLapseEnd(data: ActionData) {
    HiLog.i(TAG, `timeLapseEnd mode:${this.mode}.`);
    // 录像模式
    if (this.mode === ModeType.VIDEO) {
      // 录像模式倒计时被打断按钮恢复
      this.resetVideoBtnScale(data);
    } else {
      CaptureService.getInstance().onCaptureReady();
    }
  }

  private resetVideoBtnScale(data: ActionData) {
    if (!this.isShowtimeLapse && data['timeLapseInterrupt']) {
      this.videoBtn1Scale = AnimSpecifications.ANIM_VIDEO_BUTTON_SCALE_UP;
    }
  }

  private photoAudioControlShutterDownAnimate(): void {
    this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
    this.audioCaptureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
    animateToImmediately({
      curve: Curve.Sharp,
      duration: 125,
      onFinish: () => {
        this.photoAudioControlShutterUpAnimate();
      }
    }, () => {
      this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_DOWN;
      this.audioCaptureBtnScale = AnimSpecifications.ANIM_AUDIO_CONTROL_CAPTURE_BUTTON_SCALE_DOWN;
    });
  }

  private photoAudioControlShutterUpAnimate(): void {
    this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_DOWN;
    this.audioCaptureBtnScale = AnimSpecifications.ANIM_AUDIO_CONTROL_CAPTURE_BUTTON_SCALE_DOWN;
    animateToImmediately({
      curve: Curve.Sharp,
      duration: 125,
      onFinish: () => {
        if (!this.isProShutterCapture) {
          this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
        }
      }
    }, () => {
      this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
      this.audioCaptureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
    });
  }

  private photoShutterDownAnimate(): void {
    HiLog.i(TAG, 'photoShutterDownAnimate animation begin');
    animateToImmediately({
      curve: AnimSpecifications.ANIM_CAPTURE_CURVE,
      onFinish: () => {
        HiLog.i(TAG, 'photoShutterDownAnimate animation Finish');
      }
    }, () => {
      this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_DOWN;
      this.audioCaptureBtnScale = AnimSpecifications.ANIM_AUDIO_CONTROL_CAPTURE_BUTTON_SCALE_DOWN;
    })
  }

  private photoShutterUpAnimate(): void {
    HiLog.i(TAG, 'photoShutterUpAnimate animation begin');
    animateToImmediately({
      curve: AnimSpecifications.ANIM_CAPTURE_CURVE,
      onFinish: () => {
        HiLog.i(TAG, 'photoShutterUpAnimate animation Finish');
      }
    }, () => {
      this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
      this.audioCaptureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
    })
  }

  private onVideoButtonDown(): void {
    HiLog.i(TAG, 'onVideoButtonDown animation begin');
    this.videoBtn1Scale = AnimSpecifications.ANIM_VIDEO_BUTTON_SCALE_UP;
    animateToImmediately({
      curve: AnimSpecifications.ANIM_VIDEO_CURVE
    }, () => {
      this.videoBtn1Scale = AnimSpecifications.ANIM_VIDEO_BUTTON_1_SCALE_DOWN;
    })
  }

  private onVideoButtonUpCancel(): void {
    HiLog.i(TAG, 'onVideoButtonUpCancel animation begin');
    this.videoBtn1Scale = AnimSpecifications.ANIM_VIDEO_BUTTON_1_SCALE_DOWN;
    animateToImmediately({
      curve: AnimSpecifications.ANIM_VIDEO_CURVE
    }, () => {
      this.videoBtn1Scale = AnimSpecifications.ANIM_VIDEO_BUTTON_SCALE_UP;
    })
  }

  private startVideoAnim() {
    HiLog.i(TAG, 'startVideoAnim');
    this.videoWidth = this.isVdeCollapsed ? AnimSpecifications.VDE_ANIM_VIDEO_BUTTON_WIDTH_END :
      AnimSpecifications.ANIM_VIDEO_BUTTON_WIDTH_END;
    this.videoRadius = AnimSpecifications.ANIM_VIDEO_BUTTON_RADIUS_END;
    this.videoColor = AnimSpecifications.ANIM_VIDEO_BUTTON_COLOR_END;
    this.videoBtn2Scale = AnimSpecifications.ANIM_VIDEO_BUTTON_SCALE_UP;
    this.videoBtn1Scale = AnimSpecifications.ANIM_VIDEO_BUTTON_1_SCALE_DOWN;
    animateToImmediately({
      curve: AnimSpecifications.ANIM_VIDEO_CURVE
    }, () => {
      // shape B-C
      this.videoWidth = this.isVdeCollapsed ? AnimSpecifications.VDE_ANIM_VIDEO_BUTTON_WIDTH_START :
        AnimSpecifications.ANIM_VIDEO_BUTTON_WIDTH_START;
      this.videoRadius = AnimSpecifications.ANIM_VIDEO_BUTTON_RADIUS_START;
      this.videoColor = AnimSpecifications.ANIM_VIDEO_BUTTON_COLOR_START;
      // A scale 1-0
      this.videoBtn2Scale = AnimSpecifications.ANIM_VIDEO_BUTTON_2_SCALE_DOWN;
      // total scale 0.9-1
      this.videoBtn1Scale = AnimSpecifications.ANIM_VIDEO_BUTTON_SCALE_UP;
    })
  }

  private endVideoAnim() {
    HiLog.i(TAG, 'endVideoAnim');
    this.videoWidth = this.isVdeCollapsed ? AnimSpecifications.VDE_ANIM_VIDEO_BUTTON_WIDTH_START :
      AnimSpecifications.ANIM_VIDEO_BUTTON_WIDTH_START;
    this.videoRadius = AnimSpecifications.ANIM_VIDEO_BUTTON_RADIUS_START;
    this.videoColor = AnimSpecifications.ANIM_VIDEO_BUTTON_COLOR_START;
    this.videoBtn2Scale = AnimSpecifications.ANIM_VIDEO_BUTTON_2_SCALE_DOWN;
    animateToImmediately({
      curve: AnimSpecifications.ANIM_VIDEO_CURVE
    }, () => {
      // shape C-B
      this.videoWidth = this.isVdeCollapsed ? AnimSpecifications.VDE_ANIM_VIDEO_BUTTON_WIDTH_END :
        AnimSpecifications.ANIM_VIDEO_BUTTON_WIDTH_END;
      this.videoRadius = AnimSpecifications.ANIM_VIDEO_BUTTON_RADIUS_END;
      this.videoColor = AnimSpecifications.ANIM_VIDEO_BUTTON_COLOR_END;
      // A scale 0-1
      this.videoBtn2Scale = AnimSpecifications.ANIM_VIDEO_BUTTON_SCALE_UP;
    })
  }

  private isEnterImmersive(data: EnterImmersiveData): void {
    HiLog.i(TAG, `isEnterImmersive isImmersive: ${data.isImmersive}.`);
    let timer: number = Number.NaN;
    if (!data.isImmersive) {
      timer = setTimeout(() => {
        HiLog.i(TAG, 'canAudioShutter is true');
      }, CAN_AUDIO_SHUTTER_DELAY);
    } else {
      clearTimeout(timer);
    }
  }

  private audioControlShutterButton(data: PickerData) {
    if (!this.uiEnable || data.isPicker !== this.isPicker || this.isProShutterCapture) {
      HiLog.i(TAG, 'audio Control Shutter return.');
      return;
    }
    if (!this.isCaptureEnabled()) {
      return;
    }
    if (MemoryService.getInstance().isFullStorage()) {
      return;
    }
    if ((this.isShowCapture ||
      this.currentButtonType === ShutterButtonType.NORMAL_CAPTURE)) {
      this.mAction.disableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
      this.photoAudioControlShutterDownAnimate();
      if (this.shouldPlayCaptureEffectWhenClick(this.estimatedCaptureDuration)) {
        HiLog.i(TAG, 'play capture effect when up');
        this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
      }
      this.photoShutterUpCapture();
      return;
    }
    if (this.currentButtonType === ShutterButtonType.SECOND_CAPTURE) {
      this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
      if (!this.nightShutterStatus && !this.confirmCaptureState) {
      } else if (this.nightShutterStatus && !this.confirmCaptureState) {
        this.clearTimer();
        HiLog.i(TAG, 'audioControlShutterButton confirmCapture');
        this.confirmCapture();
        this.mAction.confirmCapture();
      }
    }
  }

  private clickFloatingShutterButton(data: PickerData) {
    if ((!this.uiEnable && !this.nightShutterStatus) || data.isPicker !== this.isPicker) {
      HiLog.i(TAG, 'Floating Shutter return.');
      return;
    }
    HiLog.i(TAG, `onFloatingShutterButtonClick takeCapture isPicker: ${data.isPicker}.`);
    if (!this.isCaptureEnabled() &&
      !(this.nightShutterStatus && !this.confirmCaptureState)) {
      HiLog.i(TAG, `captureReadyis not end`);
      return;
    }
    if (MemoryService.getInstance().isFullStorage()) {
      return;
    }
    const isPlayDownAnimate = this.isShowCapture ||
      (this.currentButtonType === ShutterButtonType.NORMAL_CAPTURE && !this.isShowLongExposure);
    if (isPlayDownAnimate) {
      this.photoShutterDownAnimate();
      if (this.shouldPlayCaptureEffectWhenClick(this.estimatedCaptureDuration)) {
        HiLog.i(TAG, 'play capture effect when up');
        this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
      }
      if (this.mHasClickDownCapture) {
        this.mHasClickDownCapture = false;
      }
      this.photoShutterUpCapture();
      setTimeout((): void => {
        this.photoShutterUpAnimate();
      }, CAPTURE_DELAY * 5);
      return;
    }
    if (this.isShowVideo) {
      if (this.videoState === RecordingState.READY) {
        this.onVideoButtonDown();
      }
      this.videoInnerBtnTouchUp();
    }
    if (this.currentButtonType === ShutterButtonType.SECOND_CAPTURE) {
      this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
      if (!this.nightShutterStatus && !this.confirmCaptureState) {
      } else if (this.nightShutterStatus && !this.confirmCaptureState) {
        this.clearTimer();
        HiLog.i(TAG, 'clickFloatingShutterButton confirmCapture');
        this.confirmCapture();
        this.mAction.confirmCapture();
      }
    }
    HiLog.i(TAG, 'onFloatingShutterButtonClick end');
  }

  private onCollaborateControlCapture(): void {
    if (getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') !== CameraRunningState.STARTING ||
      !this.uiEnable) {
      return;
    }
    HiLog.begin(TAG, 'onCollaborateControlCapture')
    if (this.currentButtonType === ShutterButtonType.NORMAL_CAPTURE || this.isShowCapture) {
      // 遥控拍照,模拟触摸事件,按下50ms后抬起,仅普通拍照模式
      this.photoProcess(true, false);
      setTimeout((): void => {
        this.photoProcess(false, false);
        this.handleClickDownCaptureWhenUp();
      }, CAPTURE_DELAY * 5)
    }
    HiLog.end(TAG, 'onCollaborateControlCapture')
  }

  private onCollaborateControlVideo(): void {
    if (AppStorage.get('isLemCollaps') ||
    this.isDuringSavePowerMode ||
    this.isProShutterCapture ||
      getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') !== CameraRunningState.STARTED ||
      !this.uiEnable) {
      return;
    }
    HiLog.begin(TAG, 'onCollaborateControlVideo');
    // 遥控拍照,模拟触摸事件,按下50ms后抬起,仅普通录像模式
    if (this.isShowVideo) {
      // 遥控拍照,模拟触摸事件,按下50ms后抬起,仅普通录像模式
      if (this.currentButtonType === ShutterButtonType.NORMAL_VIDEO) {
        this.videoProcess(true);
        setTimeout((): void => {
          this.videoProcess(false);
        }, CAPTURE_DELAY * 5);
      }
    }
    HiLog.end(TAG, 'onCollaborateControlVideo');
  }

  private photoShutterUpCapture(): void {
    HiLog.i(TAG, 'up button capture.');
    if (!this.isFrameStarted) {
      return;
    }
    const currentCaptureDuration = this.estimatedCaptureDuration;
    const timeLapse: number = FeatureManager.getInstance().getFunction(FunctionId.TIME_LAPSE)?.getValue();
    const timedShot: number = FeatureManager.getInstance().getFunction(FunctionId.TIMED_SHOT)?.getValue();
    const timeLapseType: boolean = !timeLapse || timeLapse <= SettingFuncDialogItemIndex.INDEX_FIR;
    const timeShotType: boolean = !timedShot || timedShot <= SettingFuncDialogItemIndex.INDEX_FIR;
    HiLog.i(TAG,
      `timeLapse: ${timeLapse}, timedShot: ${timedShot}, timeLapseType: ${timeLapseType}, timeShotType: ${timeShotType}`);
    if ((timeLapseType && timeShotType) ||
      (timeLapse && this.videoState !== RecordingState.READY)) {
      HiLog.i(TAG, 'up capture called.');
      this.playCaptureEffectWhenCapture(currentCaptureDuration);
      this.mAction.capture();
      this.singleStagePhotoCaptured = this.isPicker ? true : this.singleStagePhotoCaptured;
      CaptureService.getInstance().clearRichCaptureNext();
      this.mAction.changeFunctionValue(FunctionId.CAPTURE, true);
    }

    const timerLapseType: boolean = !!timeLapse && timeLapse > SettingFuncDialogItemIndex.INDEX_FIR;
    if (timerLapseType) {
      HiLog.i(TAG, 'up capture changeTimeLapse called.');
      CaptureService.getInstance().clearRichCaptureNext();
      this.mAction.changeTimeLapse(true);
      return;
    }

    HiLog.i(TAG, 'up capture end.');
  }

  private shouldPlayCaptureEffectWhenClick(captureDuration: number) {
    const timerLapse: number = FeatureManager.getInstance().getFunction(FunctionId.TIME_LAPSE)?.getValue();
    const timedShot: number = FeatureManager.getInstance().getFunction(FunctionId.TIMED_SHOT)?.getValue();
    if (timerLapse && timerLapse > SettingFuncDialogItemIndex.INDEX_FIR) {
      return false;
    }

    const result: boolean =
      (this.isSupportMultiCaptureEffect(captureDuration)) &&
        captureDuration <= MAX_CLICK_MODE_DURATION;
    HiLog.i(TAG, `play capture effect without waiting: ${result}`);
    return result;
  }

  private playCaptureEffectWhenCapture(currentCaptureDuration: number) {
    if (this.isFlashOn()) {
      return;
    }

    if (this.videoState !== RecordingState.READY) {
      this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
      return;
    }

    if (!this.isSupportMultiCaptureEffect(currentCaptureDuration)) {
      HiLog.i(TAG, 'play capture effect when capture');
      this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
      return;
    }

    if (currentCaptureDuration > MAX_CLICK_MODE_DURATION && !this.mHasClickDownCapture) {
      HiLog.i(TAG, 'play capture effect when capture');
    }
  }

  private playLongExposureAfterTimeLapse() {
    HiLog.i(TAG, 'play long exposure after timeLapse');
    if (MemoryService.getInstance().isFullStorage()) {
      return;
    }
    const currentCaptureDuration = this.estimatedCaptureDuration;
    this.playCaptureEffectWhenCapture(currentCaptureDuration);
    this.mAction.capture();
    this.mAction.changeFunctionValue(FunctionId.CAPTURE, true);
  }

  private isFlashSteady(): boolean {
    const flashStatus: number = FeatureManager.getInstance().getFunction(FunctionId.FLASH).getValue();
    let isFlashSteady = !(flashStatus === FlashMode.ON || flashStatus === FlashMode.AUTO);
    HiLog.i(TAG, `isFlashSteady: ${isFlashSteady}.`);
    return isFlashSteady
  }

  private isFlashOn(): boolean {
    const flashStatus: number = FeatureManager.getInstance().getFunction(FunctionId.FLASH).getValue();
    HiLog.i(TAG, `isFlashOn flashStatus: ${flashStatus}.`);
    return flashStatus === FlashMode.ON;
  }

  private photoShutterDownCapture(): void {
    if (!this.isClickDownCaptureEnabled() && this.mode !== ModeType.VIDEO) {
      HiLog.w(TAG, `capture loop interrupt ${this.mode.toString()}E.`);
      return;
    }
    this.mHasClickDownCapture = true;
    const currentCaptureDuration = this.estimatedCaptureDuration;
    if (currentCaptureDuration >= MIN_LOADING_MODE_DURATION) {
      this.mIsLongCaptureWaitingClickUp = true;
    }
    HiLog.i(TAG, 'down button capture.' + this.estimatedCaptureDuration);
    CaptureService.getInstance().clearRichCaptureNext();
    this.mAction.changeFunctionValue(FunctionId.CAPTURE, CaptureScene.SHUTTER_DOWN_CAPTURE);
    this.mAction.capture();
  }

  private longClickUpdate(isDown: boolean): void {
    HiLog.i(TAG, `longClickUpdate ${isDown}`);
    if (isDown) {
      if (this.timeoutID) {
        clearTimeout(this.timeoutID);
      }
      this.timeoutID = setTimeout(() => {
        this.mAction.longClickStatusChange(true);
        this.doShutterLongClickShrinkAnimation();
        VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_LONG_PRESS_ID);
        this.touchEvent = this.currentTouchEvent;
        this.timeoutID = 0;
      }, AnimSpecifications.ANIM_DURATION_LR_LONG_CLICK);
    } else {
      this.touchEvent = null;
      if (this.timeoutID) {
        clearTimeout(this.timeoutID);
      }
      this.mAction.longClickStatusChange(false);
    }
  }

  private doShutterLongClickShrinkAnimation(): void {
    this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_LR_SWIPE;
    this.invisibleTimeout = setTimeout(() => {
      this.shutterAllVisibility = Visibility.None;
    }, AnimSpecifications.ANIM_DELAY_150);
  }

  private doShutterExpandAnimation(): void {
    clearTimeout(this.invisibleTimeout);
    this.shutterAllVisibility = Visibility.Visible;
    animateToImmediately({
      curve: AnimSpecifications.ANIM_FOLLOW_HAND_CIRCLE_SCALE_UP_CURVE
    }, () => {
      this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
    })
  }

  private forceClickUp(): void {
    HiLog.i(TAG, 'exit longClick by force');
    this.mAction.longClickStatusChange(false);
    this.handleClickDownCaptureWhenUp();
    // 上滑动效消失兜底方案
    this.captureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
    this.audioCaptureBtnScale = AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP;
  }

  private forceClickUpRecord(): void {
    HiLog.i(TAG, 'exit longClick by force');
    this.doShutterExpandAnimation();
    setTimeout(() => {
      this.handleClickDownCaptureWhenUp();
      this.mAction.longClickStatusChange(false);
    }, RECORD_UP_DELAY)
  }

  private isClickDownCaptureEnabled(): boolean {
    if (!CLICK_DOWN_CAPTURE_SUPPORT_MODE.includes(this.mode)) {
      return false;
    }

    if (this.isPicker) {
      return false;
    }

    if (!DeviceInfo.isPhone()) {
      return false;
    }

    if (!this.isCaptureEnabled()) {
      return false;
    }

    if (!this.isFlashSteady()) {
      return false;
    }

    if (this.estimatedCaptureDuration >= MIN_LOADING_MODE_DURATION) {
      return false;
    }

    const timerLapse: number = FeatureManager.getInstance().getFunction(FunctionId.TIME_LAPSE)?.getValue();

    const timedShot: number = FeatureManager.getInstance().getFunction(FunctionId.TIMED_SHOT)?.getValue();
    if (timerLapse && timerLapse > SettingFuncDialogItemIndex.INDEX_FIR) {
      return false;
    }

    // 时间间隔
    if (timedShot && timedShot > SettingFuncDialogItemIndex.INDEX_FIR) {
      return false;
    }
    return true;
  }

  private checkRecordingConditions(): boolean {
    if (AppStorage.get('isRecordUnavailable')) {
      if (AppStorage.get('isBatterySOCStopping')) {
        AppStorage.setOrCreate<boolean>('isBatterySOCStopping', false);
        return true;
      } else {
        TipService.getInstance().showTip($r('app.string.battery_desc_unable'), TIP_DURING, true, null, undefined, true);
        HiLog.i(TAG, 'batterySOC is less than 2%');
        this.onVideoButtonUpCancel(); // 快门抬起
        return false;
      }
    }
    if (this.videoState === RecordingState.READY && !RecordController.getInstance().validateAudioAvailable()) {
      TipService.getInstance().showTip($r('app.string.no_record_remind'), TIP_DURING, true, null, undefined, true);
      this.onVideoButtonUpCancel(); // 快门抬起
      return false;
    }
    return true;
  }

  private videoInnerBtnTouchUp(): void {
    if (!this.checkRecordingConditions()) {
      HiLog.i(TAG, `videoInnerBtnTouchUp checkRecordingConditions fail.`);
      return;
    }
    if (this.videoState === RecordingState.READY) {
      PowerKeyService.getInstance().powerKeySubscribe();
      let timerLapse: number = FeatureManager.getInstance().getFunction(FunctionId.TIME_LAPSE)?.getValue();
      HiLog.i(TAG, `ShutterButton startRecording getValue: ${JSON.stringify(timerLapse)}.`);
      if (timerLapse && timerLapse > SettingFuncDialogItemIndex.INDEX_FIR) {
        HiLog.i(TAG, 'ShutterButton startRecording changeTimeLapse called.');
        this.mAction.changeTimeLapse(true);
      } else {
        HiLog.i(TAG, 'ShutterButton startRecording changeTimeLapse not called.');
        this.startVideoAnim();
        this.mAction.startRecording();
        this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_START);
        this.mAction.isShowExtendBarAndParamBar();
      }
    } else {
      HiLog.i(TAG, 'startRecording not ready.');
      PowerKeyService.getInstance().powerKeyUnsubscribe();
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
      this.mAction.isShowExtendBarAndParamBar();
    }
  }

  private getAnimationDuration(): number {
    return AnimSpecifications.ANIM_DURATION_300;
  }

  private photoInnerBtnOnTouch(event: TouchEvent): void {
    this.currentTouchEvent = event;
    if (event.type === TouchType.Down) {
      this.mAction.isShowExtendBarAndParamBar();
      if (this.isFrameStarted) {
        this.longClickUpdate(true);
      }
      if (getStates().get<boolean>('leftRightSwipeReducer', 'isCancelClickDown')) {
      }
      VibratorService.getInstance().triggerVibrator(VibratorService.SHUTTER_CLICK_DOWN);
      this.photoProcess(true, false);
    }
    if (event.type === TouchType.Up) {
      let longClickStatusCache = this.isShutterButtonLongClick;
      if (!this.isShutterButtonLongClick) {
        // 进入沉浸式后，退出无闪黑等动效
        VibratorService.getInstance().triggerVibrator(VibratorService.SHUTTER_CLICK_UP);
        this.photoProcess(false, false);
      }
      this.handleClickDownCaptureWhenUp();
      this.longClickUpdate(false);
      if (longClickStatusCache) {
        this.photoShutterUpAnimate();
        this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
      }
    }
    if (this.isShutterButtonLongClick && event.type === TouchType.Move) {
      this.touchEvent = event;
    }
  }

  private handleClickDownCaptureWhenUp(): void {
    if (this.mHasClickDownCapture && this.mWaitingThumbnailAnimation) {
      CameraProxy.getInstance().attemptPlayThumbnailAnimation();
      this.mWaitingThumbnailAnimation = false;
    }
    this.mHasClickDownCapture = false;
  }

  private needPlayClickUpCaptureEffect(isCached: boolean): boolean {
    if (this.isFlashOn()) {
      return false;
    }

    const currentCaptureDuration = this.estimatedCaptureDuration;
    HiLog.i(TAG, 'CaptureDuration when play click up capture effect: ' + currentCaptureDuration);
    if (currentCaptureDuration >= MIN_LOADING_MODE_DURATION) {
      return false;
    }

    if (this.mHasClickDownCapture) {
      HiLog.i(TAG, 'hasClickDownCapture: ' + this.mHasClickDownCapture);
      return true;
    }

    return !isCached && this.shouldPlayCaptureEffectWhenClick(currentCaptureDuration);
  }

  private isCaptureEnabled(report: boolean = true): boolean {
    const isStarted: boolean =
      getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') === CameraRunningState.STARTED;
    if (!isStarted) {
      HiLog.i(TAG, 'camera status is not started.');
      return false;
    }

    if (!this.mCaptureService.isEnableCapture(report) || ThumbnailService.getInstance().isPictureAcquireOrStoreTimeOut()) {
      HiLog.i(TAG, 'camera is not ready or wait save photo.');
      return false;
    }

    if (this.isShowLoading || this.isShowCountDown) {
      HiLog.i(TAG, 'is BtnAnimation');
      return false;
    }
    return true;
  }

  private photoProcess(isDown: boolean, isCacheTriggered: boolean): void {
    this.isShowActionMenu = false;
    if (!this.isFrameStarted) {
      if (this.captureBtnScale !== AnimSpecifications.ANIM_CAPTURE_BUTTON_SCALE_UP) {
        this.doShutterExpandAnimation();
      }
      if (!this.uiEnable && this.excludeComponent === UIOperationType.CAPTURE_BUTTON) {
        this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
      }
      HiLog.e(TAG, 'photoProcess,frame not start');
      return;
    }
    HiLog.i(TAG, `isDown: ${isDown}, isCacheTriggered: ${isCacheTriggered}.`);
    if (MemoryService.getInstance().isFullStorage()) {
      return;
    }
    if (isDown) {
      this.mAction.disableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.CAPTURE_BUTTON);
      this.photoShutterDownAnimate();
      this.shutterDownTime = Date.now();
      this.photoShutterDownCapture();
    } else {
      CameraProxy.getInstance().sendShutterButtonUp(Date.now() - this.shutterDownTime);
      this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
      if (this.mIsLongCaptureWaitingClickUp) {
        HiLog.i(TAG, 'ignore click up because long exposure');
        this.mIsLongCaptureWaitingClickUp = false;
        return;
      }

      if (this.needPlayClickUpCaptureEffect(isCacheTriggered)) {
        HiLog.i(TAG, 'play capture effect when click');
        this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
      }

      if (!isCacheTriggered) {
        this.photoShutterUpAnimate();
      }

      if (this.mHasClickDownCapture || !this.isCaptureEnabled(false)) {
        HiLog.i(TAG, 'ignore photo shutter up capture.');
        this.cacheRichCapture();
        return;
      }

      if (this.mCaptureService.isEnableCapture() && !this.mHasClickDownCapture &&
        !ThumbnailService.getInstance().isPictureAcquireOrStoreTimeOut()) {
        this.photoShutterUpCapture();
      }
    }
  }

  private cacheRichCapture() {
    if (this.mHasClickDownCapture) {
      return;
    }

    if (!this.isFlashSteady()) {
      return;
    }

    CaptureService.getInstance().cacheRichCaptureNext();
  }

  private nightProcess(isDown: boolean): void {
    if (MemoryService.getInstance().isFullStorage()) {
      return;
    }
    const isEnable = this.mCaptureService.isEnableCapture();
    if (!this.nightShutterStatus && !this.confirmCaptureState && isDown && !this.nightStartCaptureState && isEnable) {
      this.mAction.disableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NIGHT_SCENE_CAPTURE_BUTTON);
      this.middleNightSmallAnim();
    } else if (!this.nightShutterStatus && !this.confirmCaptureState && !isDown && isEnable) {
      this.mAction.hideThumbnailAndSwitchButton();
      this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
    } else if (this.nightShutterStatus && !this.confirmCaptureState && !isDown) {
      this.clearTimer();
      this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
      HiLog.i(TAG, 'nightProcess confirmCapture');
      this.confirmCapture();
      this.mAction.confirmCapture();
    }
  }

  private videoProcess(isDown: boolean): void {
    if (!this.uiEnable && this.excludeComponent !== UIOperationType.RECORD_BUTTON) {
      return;
    }
    if (isDown) {
      this.mAction.disableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.RECORD_BUTTON);
      if (this.videoState === RecordingState.READY) {
        VibratorService.getInstance().triggerVibrator(VibratorService.SHUTTER_CLICK_DOWN);
        this.onVideoButtonDown();
      }
      return;
    }
    this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
    VibratorService.getInstance().triggerVibrator(VibratorService.SHUTTER_CLICK_UP);
    this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
    HiLog.i(TAG, `videoProcess videoInnerBtnTouchUp`)
    this.videoInnerBtnTouchUp();
  }

  private timeLapseVideoProcess(isDown: boolean): void {
    if (!this.uiEnable && this.excludeComponent !== UIOperationType.RECORD_BUTTON) {
      return;
    }
    if (isDown) {
      this.mAction.disableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.RECORD_BUTTON);
      if (this.videoState === RecordingState.READY) {
        VibratorService.getInstance().triggerVibrator(VibratorService.SHUTTER_CLICK_DOWN);
        this.onVideoButtonDown();
      }
      return;
    }
    this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
    VibratorService.getInstance().triggerVibrator(VibratorService.SHUTTER_CLICK_UP);
    this.videoInnerBtnTouchUp();
    let timerLapse: number = FeatureManager.getInstance().getFunction(FunctionId.TIME_LAPSE)?.getValue();
    let isNeedDelayChangeTimelapse = timerLapse && timerLapse > SettingFuncDialogItemIndex.INDEX_FIR &&
      this.videoState === RecordingState.READY;
  }

  private onSlowMoButtonChange(): void { // 慢动作：超慢&标慢切换帧率不需动效直接变更状态
    const buttonType: ShutterButtonType = this.getNewButtonType();
    HiLog.i(TAG, `currentButtonType: ${this.currentButtonType}, buttonType: ${buttonType}.`);
    this.currentButtonType = buttonType;
  }

  private getNewButtonType(): ShutterButtonType {
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
    return ShutterController.getInstance().getButtonType(this.mode, outputType, this.cameraPosition);
  }

  private isInTouchTarget(event?: TouchEvent): boolean {
    if (!event || !event.touches || !event.target || !event.target.area) {
      return false;
    }
    for (let touchObject of event.touches) {
      if (touchObject.x >= 0 && touchObject.x <= event.target.area.width &&
        touchObject.y >= 0 && touchObject.y <= event.target.area.height) {
        return true;
      } else {
        HiLog.i(TAG, `out touchx: ${touchObject.x}, touchy: ${touchObject.y}`)
      }
    }
    HiLog.i(TAG, `confirm out target width: ${event.target.area.width}， height: ${event.target.area.height}}`)
    return false;
  }

  private getButtonColor(): string | Color {
    return Color.White;
  }

  @Builder
  normalOuterBtn() {
    // photo & video use the same
    Column()
      .width(this.isVdeCollapsed ? 52 : 64)
      .aspectRatio(1)
      .border({
        width: 2,
        color: this.getButtonColor(),
        radius: this.isShowSubScreenRadius ? 0 : 32,
        style: BorderStyle.Solid
      })
      .backgroundColor(this.shutterOutsideBackground)
      .key(ComponentIdKeys.SHUTTER_BUTTON_NORMAL_OUT_BTN)
  }

  @Builder
  countDownBtnStart() {
    Canvas(this.mLoopStartController)
      .width(64)
      .height(64)
      .onReady((): void => {
        HiLog.i(TAG, 'countDownBtnStart onReady.');
        this.mLoopStartController.imageSmoothingEnabled = true;
        this.mLoopStartController.imageSmoothingQuality = 'medium';
        this.exposureStartAnimationItem?.destroy();
        this.exposureStartAnimationItem = lottie.loadAnimation({
          container: this.mLoopStartController,
          renderer: 'canvas',
          loop: false,
          autoplay: true,
          name: NIGHT_START_LOOP,
          path: NIGHT_EXPOSURE_PATH,
        })
        this.exposureStartAnimationItem.addEventListener('DOMLoaded', (args: Object): void => {
          HiLog.i(TAG, 'countDownBtnStart DownLoaded');
          let ssd: number | undefined = this.exposureStartAnimationItem?.getDuration();
          if (ssd === undefined) {
            return;
          }
          let speed: number = (1000 * ssd / this.mCountDownBtnDuration);
          this.exposureStartAnimationItem?.setSpeed(speed);
        })
      })
      .onDisAppear((): void => {
        // Canvas销毁时销毁lottie动画
        HiLog.i(TAG, 'countDownBtnStart onDisAppear.');
        if (this.exposureStartAnimationItem !== undefined) {
          lottie?.destroy(NIGHT_START_LOOP);
          this.exposureStartAnimationItem = undefined;
        }
      })
      .visibility(this.isShowCountDown ? Visibility.Visible : Visibility.Hidden)
  }

  @Builder
  loadingBtnFirst() {
    Canvas(this.mLoopCaptureFirstController)
      .width(64)
      .height(64)
      .onReady((): void => {
        HiLog.i(TAG, 'loadingBtnFirst onReady.');
        this.mLoopCaptureFirstController.imageSmoothingEnabled = true;
        this.mLoopCaptureFirstController.imageSmoothingQuality = 'medium';
        this.captureStartFirstAnimationItem?.destroy();
        this.captureStartFirstAnimationItem = lottie.loadAnimation({
          container: this.mLoopCaptureFirstController,
          renderer: 'canvas',
          loop: false,
          autoplay: true,
          name: NIGHT_CAPTURE_FIRST_LOOP,
          path: NIGHT_CAPTURE_FIRST_PATH,
        })
        this.captureStartFirstAnimationItem.addEventListener('complete', (args: Object): void => {
          if (!this.isShowLongExposure || !this.isShowLoading) {
            return;
          }
          HiLog.i(TAG, 'lottieLoadingFirst complete.');
          if (this.shouldExitLongExposure) {
            this.stopLoadingBtnAnimation();
          } else {
            this.loadingCaptureFirstFinish = true;
          }
        }); //动画播放结束且不再播放动画触发
      })
      .onDisAppear((): void => {
        HiLog.i(TAG, 'loadingBtnFirst disappear');
        if (this.captureStartFirstAnimationItem !== undefined) {
          HiLog.i(TAG, 'loadingBtnFirst onDisAppear.');
          lottie?.destroy(NIGHT_CAPTURE_FIRST_LOOP);
          this.captureStartFirstAnimationItem = undefined;
        }
      })
      .visibility((this.isShowLoading && !this.loadingCaptureFirstFinish) ? Visibility.Visible : Visibility.Hidden)
  }

  @Builder
  loadingBtnSecond() {
    Canvas(this.mLoopCaptureSecondController)
      .width(64)
      .height(64)
      .onReady((): void => {
        HiLog.i(TAG, 'loadingBtnSecond onReady.');
        this.mLoopCaptureSecondController.imageSmoothingEnabled = true;
        this.mLoopCaptureSecondController.imageSmoothingQuality = 'medium';
        this.captureStartSecondAnimationItem?.destroy();
        this.captureStartSecondAnimationItem = lottie.loadAnimation({
          container: this.mLoopCaptureSecondController,
          renderer: 'canvas',
          loop: true,
          autoplay: true,
          name: NIGHT_CAPTURE_SECOND_LOOP,
          path: NIGHT_CAPTURE_SECOND_PATH,
        })
      })
      .onDisAppear((): void => {
        if (this.captureStartSecondAnimationItem !== undefined) {
          HiLog.i(TAG, 'loadingBtnSecond onDisAppear.');
          lottie?.destroy(NIGHT_CAPTURE_SECOND_LOOP);
          this.captureStartSecondAnimationItem = undefined;
        }
      })
      .visibility(this.isLoadingBtnSecond() ? Visibility.Visible : Visibility.Hidden)
  }

  @Builder
  lottieCanvasLightPaintingStart() {
    Canvas(this.mLoopStartController)
      .width(64)
      .height(64)
      .onReady((): void => {
        HiLog.i(TAG, 'lottieCanvasLightPaintingStart onReady.');
        this.mLoopStartController.imageSmoothingEnabled = true;
        this.mLoopStartController.imageSmoothingQuality = 'medium';
        this.exposureStartAnimationItem?.destroy();
        this.exposureStartAnimationItem = lottie.loadAnimation({
          container: this.mLoopStartController,
          renderer: 'canvas',
          loop: false,
          autoplay: true,
          name: LIGHT_PAINTING_CAPTURE_FIRST_LOOP,
          path: LIGHT_PAINTING_CAPTURE_PATH,
        })
        this.exposureStartAnimationItem.addEventListener('DOMLoaded', (args: Object): void => {
          HiLog.i(TAG, 'lottieCanvasLightPaintingStart DownLoaded');
          let ssd: number | undefined = this.exposureStartAnimationItem?.getDuration();
          if (ssd === undefined) {
            return;
          }
          let speed: number = (1000 * ssd / this.mCountDownBtnDuration);
          this.exposureStartAnimationItem?.setSpeed(speed);
        })
      })
      .onDisAppear((): void => {
        // Canvas销毁时销毁lottie动画
        HiLog.i(TAG, 'lottieCanvasLightPaintingStart onDisAppear.');
        if (this.exposureStartAnimationItem !== undefined) {
          lottie?.destroy(LIGHT_PAINTING_CAPTURE_FIRST_LOOP);
          this.exposureStartAnimationItem = undefined;
        }
      })
      .visibility(Visibility.Visible)
  }

  @Builder
  lottieCanvasLightPaintingCaptureStartFirst() {
    Canvas(this.mLoopCaptureFirstController)
      .width(64)
      .height(64)
      .onReady(() => {
        HiLog.i(TAG, 'lottieCanvasLightPaintingCaptureStartFirst onReady.');
        this.mLoopCaptureFirstController.imageSmoothingEnabled = true;
        this.mLoopCaptureFirstController.imageSmoothingQuality = 'medium';
        this.captureStartFirstAnimationItem = lottie.loadAnimation({
          container: this.mLoopCaptureFirstController,
          renderer: 'canvas',
          loop: false,
          autoplay: true,
          name: LIGHT_PAINTING_CAPTURE_FIRST_LOOP,
          path: LIGHT_PAINTING_CAPTURE_PATH,
        })
        this.captureStartFirstAnimationItem.addEventListener('complete', (args: Object): void => {
          HiLog.i(TAG, 'lottieCanvasLightPaintingCaptureStartFirst complete.');
          this.nightCaptureFirstFinish = true;
        }); //动画播放结束且不再播放动画触发
      })
      .onDisAppear(() => {
        if (this.captureStartFirstAnimationItem !== undefined) {
          HiLog.i(TAG, 'lottieCanvasLightPaintingCaptureStartFirst onDisAppear.');
          lottie?.destroy(LIGHT_PAINTING_CAPTURE_FIRST_LOOP);
          this.captureStartFirstAnimationItem = undefined;
        }
      })
      .visibility(Visibility.Visible)
  }

  @Builder
  nightOuterBtn() {
    Row() {
      if (this.nightShutterStatus && !this.confirmCaptureState) {
      } else if (this.nightShutterStatus && this.confirmCaptureState && !this.nightCaptureFirstFinish) {
        this.lottieCanvasCaptureStartFirst();
      } else if (this.nightShutterStatus && this.confirmCaptureState && this.nightCaptureFirstFinish) {
        this.lottieCanvasCaptureStartSecond();
      }
    }
  }

  @Builder
  timeLapseOuterBtn() {
    Row() {
      if (this.videoState === RecordingState.RECORDING || this.videoState === RecordingState.STARTING) {
        this.lottieTimeLapseCanvasStart();
      } else if (this.videoState === RecordingState.STOPPING) {
        this.loadingBtnSecond();
      }
    }
  }

  @Builder
  longExposureOuterBtn() {
    Row() {
      if (this.isShowCountDown) {
        this.countDownBtnStart();
      } else {
        if (this.loadingCaptureFirstFinish) {
          this.loadingBtnSecond();
        } else {
          this.loadingBtnFirst();
        }
      }
    }
  }

  @Builder
  lottieTimeLapseCanvasStart() {
    Canvas(this.mLoopStartController)
      .width(64)
      .height(64)
      .onReady((): void => {
        HiLog.i(TAG, 'lottieTimeLapseCanvasStart onReady.');
        this.mLoopStartController.imageSmoothingEnabled = true;
        this.mLoopStartController.imageSmoothingQuality = 'medium';
        this.exposureStartAnimationItem?.destroy();
        this.exposureStartAnimationItem = lottie.loadAnimation({
          container: this.mLoopStartController,
          renderer: 'canvas',
          loop: true,
          autoplay: true,
          name: LIGHT_PAINTING_CAPTURE_FIRST_LOOP,
          path: LIGHT_PAINTING_CAPTURE_PATH,
        })
        this.exposureStartAnimationItem.addEventListener('DOMLoaded', (args: Object): void => {
          HiLog.i(TAG, 'lottieTimeLapseCanvasStart DownLoaded');
          let ssd: number | undefined = this.exposureStartAnimationItem?.getDuration();
          if (ssd === undefined) {
            return;
          }
          let speed: number = (ssd / 12);
          this.exposureStartAnimationItem?.setSpeed(speed);
        })
      })
      .onDisAppear((): void => {
        // Canvas销毁时销毁lottie动画
        HiLog.i(TAG, 'lottieTimeLapseCanvasStart onDisAppear.');
        if (this.exposureStartAnimationItem !== undefined) {
          lottie?.destroy(LIGHT_PAINTING_CAPTURE_FIRST_LOOP);
          this.exposureStartAnimationItem = undefined;
        }
      })
  }

  @Builder
  lottieCanvasCaptureStartFirst() {
    Canvas(this.mLoopCaptureFirstController)
      .width(64)
      .height(64)
      .onReady((): void => {
        HiLog.i(TAG, 'lottieCanvasCaptureStartFirst onReady.');
        this.mLoopCaptureFirstController.imageSmoothingEnabled = true;
        this.mLoopCaptureFirstController.imageSmoothingQuality = 'medium';
        this.captureStartFirstAnimationItem?.destroy();
        lottie.pause(NIGHT_CAPTURE_FIRST_LOOP);
        this.captureStartFirstAnimationItem = lottie.loadAnimation({
          container: this.mLoopCaptureFirstController,
          renderer: 'canvas',
          loop: false,
          autoplay: true,
          name: NIGHT_CAPTURE_FIRST_LOOP,
          path: NIGHT_CAPTURE_FIRST_PATH,
        })
        this.captureStartFirstAnimationItem.addEventListener('complete', (args: Object): void => {
          HiLog.i(TAG, 'lottieCanvasCaptureStart complete.');
          this.nightCaptureFirstFinish = true;
        }); //动画播放结束且不再播放动画触发
      })
      .onDisAppear((): void => {
        if (this.captureStartFirstAnimationItem !== undefined) {
          HiLog.i(TAG, 'lottieCanvasCaptureStart onDisAppear.');
          lottie?.destroy(NIGHT_CAPTURE_FIRST_LOOP);
          this.captureStartFirstAnimationItem = undefined;
        }
      })
      .visibility(this.nightShutterStatus && this.confirmCaptureState &&
        !this.nightCaptureFirstFinish ? Visibility.Visible : Visibility.Hidden)
  }

  @Builder
  stitchingLottieShootFirst() {
    Canvas(this.mLoopCaptureFirstController)
      .width(64)
      .height(64)
      .onReady((): void => {
        this.mLoopCaptureFirstController.imageSmoothingEnabled = true;
        this.mLoopCaptureFirstController.imageSmoothingQuality = 'medium';
        this.captureStartFirstAnimationItem?.destroy();
        this.captureStartFirstAnimationItem = lottie.loadAnimation({
          container: this.mLoopCaptureFirstController,
          renderer: 'canvas',
          loop: false,
          autoplay: true,
          name: STITCHING_FIRST_LOOP,
          path: NIGHT_CAPTURE_FIRST_PATH,
        })
        this.captureStartFirstAnimationItem.addEventListener('complete', (args: Object): void => {
        }); //动画播放结束且不再播放动画触发
      })
      .onDisAppear((): void => {
        if (this.captureStartFirstAnimationItem !== undefined) {
          HiLog.i(TAG, 'lottieCanvasCaptureStart onDisAppear.');
          lottie?.destroy(STITCHING_FIRST_LOOP);
          this.captureStartFirstAnimationItem = undefined;
        }
      })
  }

  private isLoadingBtnSecond(): boolean {
    return this.isShowLoading && this.loadingCaptureFirstFinish;
  }

  @Builder
  lottieCanvasCaptureStartSecond() {
    Canvas(this.mLoopCaptureSecondController)
      .width(64)
      .height(64)
      .onReady((): void => {
        HiLog.i(TAG, 'lottieCanvasCaptureStartSecond onReady.');
        this.mLoopCaptureSecondController.imageSmoothingEnabled = true;
        this.mLoopCaptureSecondController.imageSmoothingQuality = 'medium';
        this.captureStartSecondAnimationItem?.destroy();
        lottie.pause(NIGHT_CAPTURE_SECOND_LOOP);
        this.captureStartSecondAnimationItem = lottie.loadAnimation({
          container: this.mLoopCaptureSecondController,
          renderer: 'canvas',
          loop: true,
          autoplay: true,
          name: NIGHT_CAPTURE_SECOND_LOOP,
          path: NIGHT_CAPTURE_SECOND_PATH,
        })
      })
      .onDisAppear((): void => {
        if (this.captureStartSecondAnimationItem !== undefined) {
          HiLog.i(TAG, 'lottieCanvasCaptureStartSecond onDisAppear.');
          lottie?.destroy(NIGHT_CAPTURE_SECOND_LOOP);
          this.captureStartSecondAnimationItem = undefined;
        }
      })
      .visibility(this.nightShutterStatus && this.confirmCaptureState && this.nightCaptureFirstFinish
        ? Visibility.Visible : Visibility.Hidden)
  }

  @Builder
  stitchingLottieShootSecond() {
    Canvas(this.mLoopCaptureSecondController)
      .width(64)
      .height(64)
      .onReady((): void => {
        this.mLoopCaptureSecondController.imageSmoothingEnabled = true;
        this.mLoopCaptureSecondController.imageSmoothingQuality = 'medium';
        this.captureStartSecondAnimationItem?.destroy();
        this.captureStartSecondAnimationItem = lottie.loadAnimation({
          container: this.mLoopCaptureSecondController,
          renderer: 'canvas',
          loop: true,
          autoplay: true,
          name: STITCHING_SECOND_LOOP,
          path: NIGHT_CAPTURE_SECOND_PATH,
        })
      })
      .onDisAppear((): void => {
        if (this.captureStartSecondAnimationItem !== undefined) {
          lottie?.destroy(STITCHING_SECOND_LOOP);
          this.captureStartSecondAnimationItem = undefined;
        }
      })
  }

  /**
   * 及时清除定时器,避免timerId相对异步修改导致前一Id所属操作无法控制问题
   * */
  private clearTimer(): void {
    if (Number.MIN_VALUE !== this.nightTimerId) {
      clearTimeout(this.nightTimerId);
    }
  }

  private videoInnerTouchFn(event: TouchEvent): void {
    HiLog.i(TAG, 'videoInnerTouchFn videoState : ' + this.videoState);
    HiLog.i(TAG, 'videoInnerTouchFn event : ' + simpleStringify(event));
    if (this.videoState === RecordingState.STOPPING) {
      HiLog.e(TAG, 'videoInnerTouchFn videoState is stopping.');
      return;
    }
    if (MemoryService.getInstance().isFullStorage(true)) {
      if (event.type === TouchType.Down) {
        VibratorService.getInstance().triggerVibrator(VibratorService.SHUTTER_CLICK_DOWN);
      }
      if (event.type === TouchType.Up) {
        VibratorService.getInstance().triggerVibrator(VibratorService.SHUTTER_CLICK_UP);
      }
      HiLog.e(TAG, 'videoInnerTouchFn: The Storage is full and cannot record');
      return;
    }
    if (event.type === TouchType.Cancel) {
      HiLog.e(TAG, 'videoInnerTouchFn: The record cancel.');
      if (!this.uiEnable) {
        this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
      }
      this.onVideoButtonUpCancel();
    }
    if (event.type === TouchType.Down) {
      this.mAction.isShowExtendBarAndParamBar();
    }
    if (event.type === TouchType.Down) {
      RecordController.getInstance().click();
      HiLog.i(TAG, `TouchType.Down event: ${simpleStringify(event)}.`);
      this.videoProcess(true);
    }
    if (event.type === TouchType.Up) {
      HiLog.i(TAG, `TouchType.Up event: ${simpleStringify(event)}.`);
      if (RecordController.getInstance().getRecordType() !== RecordType.longClick) {
        this.videoProcess(false);
      }
    }
  }

  private getPhotoInnerBtnBgc(): string | Color {
    return this.isShowLongExposure ? Color.Gray : Color.White;
  }

  private getVideoInnerBtnBgc(): string | Color {
    return this.videoColor;
  }

  @Builder
  photoInnerBtn() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.isVdeCollapsed ? 40 : this.captureBtnWidth)
        .aspectRatio(1)
        .borderRadius(this.isShowSubScreenRadius ? 0 : this.captureBtnRadius)
        .backgroundColor(this.getPhotoInnerBtnBgc())

      if (this.audioControlType === SettingFuncDialogItemIndex.INDEX_SEC ||
        this.audioControlType === SettingFuncDialogItemIndex.INDEX_THR) {
        AudioControlShutterButton()
          .scale(this.audioCaptureBtnScale)
          .aspectRatio(1)
          .borderRadius(this.isShowSubScreenRadius ? 0 : 9)
          .visibility(this.audioCaptureBtnVisibility)
          .rotate({ angle: this.rotateAngle })
      }
    }
    .width(this.isVdeCollapsed ? '56vp' : $r('app.float.big_button_length'))
    .aspectRatio(1)
    .id(ComponentIdKeys.SHUTTER_PHOTO_1)
    .scale(this.captureBtnScale)
    .opacity(this.captureBtnOpacity)
    .enabled((!this.isDuringSavePowerMode ||
      this.excludeComponent === UIOperationType.CAPTURE_BUTTON) && !this.isOpenOrCloseTreasureBox)
    .onTouch(this.photoInnerTouchFn())
    .visibility(this.isLrShutterShown ? Visibility.None : Visibility.Visible)
    .accessibilityGroup(true)
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .accessibilityDescription(`${ResGetter.getStringSafe($r('app.string.accessibility_clickable'))} ${''}`)
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)

    // .onPhotoInnerBtnClick();//无障碍模式点击
  }

  @Styles
  private onPhotoInnerBtnClick() {
    .onClick((event) => {
    })
  }

  private photoInnerTouchFn(): (event: TouchEvent) => void {
    return (event: TouchEvent) => {
      HiLog.i(TAG, `photoInnerBtn onTouch: ${event?.type}.`);
      if (!event) {
        return;
      }
      // 打断场景的恢复
      if (event.type === TouchType.Cancel) {
        HiLog.i(TAG, `touch canceled ${this.uiEnable},${this.excludeComponent}`);
        this.longClickUpdate(false);
        if (!this.uiEnable && this.excludeComponent === UIOperationType.CAPTURE_BUTTON) {
          this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
        }
        this.resetPhotoInnerBtn();
        return;
      }
      if (this.singleStagePhotoCaptured && this.isPicker) {
        return;
      }
      if (this.isShowLongExposure) {
        if (event.type === TouchType.Up) {
          // 避免阻塞长曝光场景拇指图更新
          this.mHasClickDownCapture = false;
          this.mIsLongCaptureWaitingClickUp = false;
          this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
        }
        HiLog.i(TAG, 'long exposure shutter interrupt.');
        return;
      }

      if (!this.isSupportLrSwipe()) {
        this.photoInnerBtnOnTouch(event);
        HiLog.i(TAG, 'lr swipe shutter interrupt.');
        return;
      }

      if (event.type != TouchType.Down && event.type != TouchType.Cancel && this.isIgnoreTouch) {
        HiLog.i(TAG, 'event shutter interrupt.');
        return;
      }
      this.isIgnoreTouch = false;
      if (!this.isInTouchTarget(event) && !this.isShutterButtonLongClick) {
        // 按压后划出快门场景，特殊抬起状态
        HiLog.i(TAG, 'out PhotoInnerBtn');
        if (this.isFrameStarted) {
          this.photoShutterUpAnimate();
        }
        this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
        this.isIgnoreTouch = true;
        if (this.mHasClickDownCapture) {
          this.mWaitingThumbnailAnimation = false;
          ThumbnailService.getInstance().thumbnailUpdate(1);
          LeftRightSwipeWorkerCaptureService.getInstance().needDeleteOnePhoto(false);
        }
        this.longClickUpdate(false);
        return;
      }
      this.photoInnerBtnOnTouch(event);
    }
  }

  private isSupportLrSwipe(): boolean {
    return false;
  }

  @Builder
  videoInnerBtn() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.videoWidth)
        .aspectRatio(1)
        .borderRadius(this.isShowSubScreenRadius ? 0 : this.videoRadius)
        .backgroundColor(this.getVideoInnerBtnBgc())
        .opacity(1)

      Column()
        .width(this.isVdeCollapsed ? 20 : 24)
        .aspectRatio(1)
        .borderRadius(this.isShowSubScreenRadius ? 0 : 12)
        .scale(this.videoBtn2Scale)
        .opacity(this.videoBtn2Opacity)
        .backgroundColor(Color.Red)
    }
    .width(64)
    .aspectRatio(1)
    .scale(this.videoBtn1Scale)
    .opacity(1)
    .enabled((this.uiEnable || this.excludeComponent === UIOperationType.RECORD_BUTTON) &&
      !this.isOpenOrCloseTreasureBox)
    .key(this.videoState === RecordingState.READY
      ? ComponentIdKeys.SHUTTER_VIDEO_1
      : ComponentIdKeys.SHUTTER_VIDEO_END_1)
    .onTouch(async (event?: TouchEvent) => {
      HiLog.i(TAG, 'videoInnerBtn click.');
      if (event === undefined) {
        return;
      }
      this.videoInnerTouchFn(event);
    })
    .accessibilityGroup(true)
    .accessibilityText(this.getABText())
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
    .onVideoInnerBtnClick()
    .accessibilityDescription(`${ResGetter.getStringSafe($r('app.string.accessibility_button'))} ${
    ResGetter.getStringSafe($r('app.string.accessibility_clickable'))}`)
    .gesture(
      LongPressGesture({ repeat: false, duration: 500 })
        .onAction((event: GestureEvent | undefined) => {
          if (!event) {
            HiLog.e(TAG, 'LongPressGesture event undefined.');
          }
          if (!this.uiEnable && this.excludeComponent !== UIOperationType.RECORD_BUTTON) {
            HiLog.e(TAG, `return, uiEnable: ${this.uiEnable}, excludeComponent: ${this.excludeComponent}.`);
            return;
          }
          HiLog.i(TAG, `checkPreRecordConditions ok, recordState: ${this.videoState}.`);
          if (this.videoState !== RecordingState.READY) {
            return;
          }
          if (MemoryService.getInstance().isFullStorage(true)) {
            return;
          }
          HiLog.i(TAG, 'PRE_RECORD_TRACK preRecord is opened, trigger preRecord.');
          VibratorService.getInstance().triggerVibrator(VibratorService.SHUTTER_CLICK_DOWN);
          RecordController.getInstance().longClick();
          PowerKeyService.getInstance().powerKeySubscribe();
          HiLog.i(TAG, 'ShutterButton startRecording changeTimeLapse not called.');
          this.startVideoAnim();
          this.mAction.startRecording(false);
          this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_START);
          this.mAction.isShowExtendBarAndParamBar();
        })
        .onActionEnd(() => {
          HiLog.i(TAG, `PRE_RECORD_TRACK LongPressGesture onActionEnd`)
        })
    )
  }

  @Styles
  private onVideoInnerBtnClick() {
    .onClick((event) => {
    })
  }

  @Builder
  shutterOuterBtn() {
    if (this.currentButtonType === ShutterButtonType.SECOND_CAPTURE) {
      this.nightOuterBtn();
    } else {
      if (this.isShowLongExposure) {
        this.longExposureOuterBtn();
      } else {
        this.normalOuterBtn();
      }
    }
  }

  private isButtonTypeVideo(): boolean {
    return this.currentButtonType === ShutterButtonType.NORMAL_VIDEO;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      this.normalOuterBtn()
      if (this.currentButtonType === ShutterButtonType.NORMAL_CAPTURE) {
        this.photoInnerBtn();
      } else if (this.isButtonTypeVideo()) {
        this.videoInnerBtn();
      }
    }
    .onTouch((event) => {
      AppStorage.setOrCreate<boolean>('disShutterEmitTreasureOpen', true);
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) { // 双指拍摄&切模式同时操作，Ui错乱
        this.mAction.disAbleModeBarChanged(false);
      } else {
        this.mAction.disAbleModeBarChanged(true);
      }
    })
    .margin(this.getMargin())
    .id(ComponentIdKeys.SHUTTER_BUTTON_STACK)
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .height(this.isVdeCollapsed ? '56vp' : $r('app.float.big_button_length'))
    .width($r('app.float.big_button_length'))
    .onDisAppear(() => {
      AppStorage.setOrCreate<boolean>('disShutterEmitTreasureOpen', false);
      this.mAction.disAbleModeBarChanged(false);
    })
    .onAppear(() => {
      // 无障碍场景 key值归一 方便自动聚焦拍摄组件
      if (!this.isButtonTypeVideo()) {
        AccessibilityUtils.sendFocusAccessibilityEvent('nightShutterStatusShutter');
      }
      AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.SHUTTER_VIDEO_1);
    })
  }

  private getMargin(): Padding | undefined {
    if (this.isVdeCollapsed) {
      if (PickerUtils.getIsPicker()) {
        return { left: '29vp', right: '29vp' };
      }
      return { left: '21vp', right: '21vp' };
    }
    if (this.horizontallyArranged) {
      return { left: 74, right: 74 };
    }
    if (DeviceInfo.isTablet()) {
      if (PickerUtils.getIsPicker() && this.pickerWindowType === PickerWindowType.TABLET_TOP_BOTTOM_HALF_SPLIT_SCREEN) {
        return { top: 0.05 * this.screenHeight, bottom: 0.05 * this.screenHeight };
      }
      if (!PickerUtils.getIsPicker() || this.pickerWindowType === PickerWindowType.TABLET_FULL_SCREEN &&
      DisplayService.getInstance().isOrientationVertical()) {
        return { top: 74, bottom: 74 };
      }
      return {
        top: this.pickerWindowType === PickerWindowType.TABLET_1_3_SPLIT_SCREEN ? 32 : 0.1 * this.screenHeight,
        bottom: this.pickerWindowType === PickerWindowType.TABLET_1_3_SPLIT_SCREEN ? 32 : 0.1 * this.screenHeight
      };
    }
    return { top: 62, bottom: 62 };
  }

  private updateDensity() {
    HiLog.i(TAG, 'updateDensity density=' + this.density);
    this.isShowSubScreenRadius = this.density === 1.5;
  }

  private getABText(): string {
    HiLog.i(TAG, 'getABText videoState=' + this.videoState);
    return ResGetter.getStringSafe('');
  }

  private changeOuterBackground(): void {
    if (this.isLrShutterShown) {
      this.shutterOutsideBackground = Color.Transparent;
      this.shouldApplyShade = false;
    } else {
      this.shouldApplyShade = true;
      setTimeout(() => {
        if (this.shouldApplyShade) {
          this.shutterOutsideBackground = SHUTTER_OUT_SHADE_COLOR;
        }
        this.shouldApplyShade = false;
      }, AnimSpecifications.ANIM_DURATION_150)
    }
  }
}