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

import camera from '@ohos.multimedia.camera';
import lazy { Action, resolutionData, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { NightTimeBigText } from '@ohos/common/src/main/ets/component/bigtext/NightTimeBigText';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { TimeLapseView } from '@ohos/extend/src/main/ets/settingcommonfunc/timelapse/TimeLapseView';
import lazy { ZoomAction } from '@ohos/common/src/main/ets/function/zoombar/ZoomAction';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { RecordAction, RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy {
  CameraAction,
  CameraRunningState,
  CameraStartType,
  CameraStartTypeStruct
} from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy {
  SettingFuncDialogItemIndex
} from '@ohos/common/src/main/ets/component/settingview/SettingFuncDialogItemIndex';
import image from '@ohos.multimedia.image';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { CaptureAction } from '@ohos/common/src/main/ets/function/capture/CaptureAction';
import lazy {
  AbilityBackgroundData,
  FunctionValueType,
  ImmersiveActionData,
  PositionType,
  PreviewFrameStartData,
  Size,
  XComponentSize,
} from '@ohos/common/src/main/ets/utils/types';
import lazy { ZoomOuterStatus } from '@ohos/common/src/main/ets/function/zoombar/ZoomStateType';
import lazy { TimeLapseAction } from '@ohos/extend/src/main/ets/settingcommonfunc/timelapse/TimeLapseAction';
import lazy { AdaptiveLayoutService } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLayoutService';
import lazy { ChangeState, getStates, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { DurationType, TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import curves from '@ohos.curves';
import lazy { BlurAnimateUtil } from '@ohos/common/src/main/ets/utils/BlurAnimateUtil';
import lazy { TipAction } from '@ohos/common/src/main/ets/component/tip/TipAction';
import lazy { ShowFlashBlack } from '@ohos/common/src/main/ets/component/animate/ShowFlashBlack';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { MoreModeConfig } from '@ohos/common/src/main/ets/mode/MoreModeConfig';
import lazy { ZoomOperation } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { POSITION_Y_VERTICAL_RECORDING } from '@ohos/common/src/main/ets/component/tip/Tip';
import lazy { RecordMode } from '@ohos/common/src/main/ets/function/recordcontrol/RecordMode';
import Animator, { AnimatorOptions, AnimatorResult } from '@ohos.animator';
import lazy { XComponentService } from '@ohos/common/src/main/ets/component/xcomponent/XComponentService';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { ModeListManager } from '@ohos/common/src/main/ets/mode/ModeListManager';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { PropTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import window from '@ohos.window';
import lazy { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import lazy { PickerWindowType } from '@ohos/common/src/main/ets/component/picker/PickerWindowType';
import lazy { CaptureService } from '@ohos/common/src/main/ets/function/capture/CaptureService';
import lazy { ThumbnailService } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailService';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { CaptureActionType } from '@ohos/common/src/main/ets/redux/actions/CaptureActionType';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import lazy { FunctionActionType } from '@ohos/common/src/main/ets/redux/actions/FunctionActionType';
import lazy { AssistiveGridView } from '@ohos/extend/src/main/ets/settingcommonfunc/assistivegrid/AssistiveGridView';
import lazy {
  HorizontalLevelView
} from '@ohos/extend/src/main/ets/settingcommonfunc/horizontallevel/HorizontalLevelView';
import lazy {
  HorizontalCrucifix,
  MOVABLE_CRUCIFIX_COLOR,
  MOVABLE_CRUCIFIX_SHADOW_RADIUS
} from '@ohos/extend/src/main/ets/settingcommonfunc/horizontallevel/HorizontalCrucifix';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { BigText } from '@ohos/common/src/main/ets/component/bigtext/BigText';
import lazy { DetectionView } from '../DetectionView';
import lazy { LightResult } from '@ohos/common/src/main/ets/camera/DataType';
import lazy { PreviewAction } from '@ohos/common/src/main/ets/redux/actions/PreviewAction';
import lazy { PreviewActionType } from '@ohos/common/src/main/ets/redux/actions/PreviewActionType';
import lazy { PreviewBlurAnimationComponent } from './PreviewBlurAnimationComponent';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { DISPLAY_SCREEN_SIZE_LEM, DISPLAY_SCREEN_SIZE_PSD } from './PreviewWrap';
import lazy {
  CollaborateControlService,
} from '@ohos/common/src/main/ets/service/collaborateControl/CollaborateControlService'


/* instrument ignore file */
const TAG: string = 'PreviewArea';


const CAPTURE_DELAY: number = 10;
const ROTATION_DELAY: number = 400;
const PIXELMAP_RELEASE_DELAY: number = 500; // 上滑到多任务后直接清除相机，模糊截图赋值在 disappear 后面，导致release失效

const X_COMPONENT_LOAD_TIMEOUT_DELAY: number = 600;
const SMILE_CAPTURE_TIMEOUT = 3000;
const SCALE_RATIO: number = 0.06;
const SECOND_LEVEL_LOAD_DELAY: number = 110;
const RECORD_FILTER_DELAY_TIME = 100;
const hebcXcId = 'HDC_PREVIEW';


class StateStruct {
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public minZoomRatio: number = 0;
  public maxZoomRatio: number = 0;
  public isShowBigText: boolean = false;
  public isShowNightBigText: boolean = false;
  public isShowtimeLapse: boolean = false;
  public isAssGridViewShow: boolean = false;
  public uiEnable: boolean = false;
  public videoState: RecordingState = RecordingState.READY;
  public direction: number = 0;
  public rotateAngle: number = 0;
  public isShowExtendBar: boolean = false;
  public cameraRunningState: CameraRunningState = CameraRunningState.UNINITIALIZED;
  public mode: ModeType = ModeType.NONE;
  public isShowLowAngleShotView: boolean = false;
  public isImageStabilizationGuideShow: boolean = false;
  public isForeground: boolean = false;
  public isImmersive: boolean = false;
  public exposureTime: number = 0;
  public isShowTimedShot: boolean = false;
}

class EnterImmersiveStruct {
  public isImmersive?: boolean = false;
  public mainTrigCompo?: UIOperationType = UIOperationType.NULL;
  public isShowtimeLapse?: boolean = false;
  public isShowTimedShot?: boolean = false;
}

class VolumeKeyPhotoData {
  public isDown: boolean = false;
}

export class ZoomFuncValueStruct {
  public zoomRatio?: number = 1;
  public isPrepareZoom?: boolean = false;
  public isUnprepareZoom?: boolean = false;
  public unprepareDelay?: number;
}

class DisplayRotationStruct {
  public displayRotation: number = 0;
}

class PreviewWrapDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public startup(): void {
    this.mDispatch(CameraAction.warmStart());
  }

  public closeCamera(): void {
    this.mDispatch(CameraAction.close({ isNeedSaveRestore: true }));
  }

  public startupWithDeferredSurface(isDeferSurface: boolean): void {
    this.mDispatch(CameraAction.start(isDeferSurface));
  }

  public loadPhotoBrowser(): void {
    this.mDispatch(Action.loadPhotoBrowser());
  }

  public switchCamera(position: camera.CameraPosition): void {
    this.mDispatch(CameraAction.switchCamera(position));
  }

  public changeTimeLapse(isShowtimeLapse: boolean, timeLapseInterrupt?: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse, timeLapseInterrupt));
  }

  public capture(): void {
    this.mDispatch(CaptureAction.capture());
  }

  public startRecording(): void {
    this.mDispatch(Action.uiStateWithMode(false, UiStateMode.EXCLUDE_PREVIEW));
    this.mDispatch(RecordAction.start());
  }

  public stopRecording(): void {
    this.mDispatch(RecordAction.stop());
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.ZOOM_BAR));
  }

  public updateShowPinch(flag: boolean): void {
    this.mDispatch(ZoomAction.updateShowPinch(flag));
  }

  public changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public previewClicked(unLock?: boolean): void {
    this.mDispatch(Action.previewClicked(unLock));
  }

  public updateShowBurstCaptureBigTextFlag(isShowBurstCaptureBigText: boolean): void {
    this.mDispatch(Action.updateShowBurstCaptureBigTextFlag(isShowBurstCaptureBigText));
  }

  public startVideoAnim(): void {
    this.mDispatch(TimeLapseAction.startVideoAnim());
  }

  public onLemDoubleClick(index: number): void {
    this.mDispatch(ZoomAction.onLemDoubleClick(index));
  }

  public updateIsShowParamBar(isShow: boolean): void {
    this.mDispatch(Action.updateIsShowParamBar(isShow));
  }

  public updateIsShowExtendBar(isShow: boolean): void {
    this.mDispatch(Action.updateIsShowExtendBar(isShow));
  }

  public hideTip(): void {
    this.mDispatch(TipAction.hideTip());
  }

  public uiDisabled(): void {
    this.mDispatch(Action.uiState(false));
  }

  public uiEnabled(): void {
    this.mDispatch(Action.uiState(true));
  }

  public loadSurfaceDone(): void {
    this.mDispatch(PreviewAction.loadSurfaceDone());
  }

  public setPreviewRotation(): void {
    this.mDispatch(CameraAction.setPreviewRotation());
  }

  public changeTimedShot(isShowTimedShot: boolean, timedShotInterrupt?: boolean): void {
    this.mDispatch(Action.changeTimedShot(isShowTimedShot, !!timedShotInterrupt));
  }
}

XComponentService.getInstance().init(new XComponentController());
GlobalContext.get().setPipXComponentController(new XComponentController());
GlobalContext.get().setPanoramaXComponentController(new XComponentController())

@Component
export struct PreviewArea {
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private static readonly xComponentId: string = 'xComponentId';
  private readonly positionZero: number = 0;
  @StorageLink('isPSDCollaps') isPSDCollapsed: boolean = false;
  @State displayWidth: number = 0;
  @State displayHeight: number = 0;
  @State @Watch('mUpdateMode') previewAnimateWidth: number = 0;
  @State @Watch('mUpdateMode') previewAnimateHeight: number = 0;
  @State xComponentWidth: number = getStates().get<number>('previewReducer', 'xComponentWidth');
  @State xComponentHeight: number = getStates().get<number>('previewReducer', 'xComponentHeight');
  @State focusBoxAlpha: number = 1.0;
  @State focusBoxScale: ScaleOptions = { x: 1.0, y: 1.0 };
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  protected mPreferencesService: PreferencesService = PreferencesService.getInstance();
  private moreModeConfig: MoreModeConfig = MoreModeConfig.getInstance();
  @State state: StateStruct = new StateStruct();
  @State @Watch('mUpdateMode') mode: ModeType = ModeType.NONE;
  private mAction: PreviewWrapDispatcher = new PreviewWrapDispatcher();
  @LocalStorageLink('previewAnimatePosition') previewAnimatePosition: PositionType = { x: 0, y: 0 };
  @State loadSurfaceDone: boolean = false;
  @LocalStorageLink('newPreviewAnimatePosition') newPreviewAnimatePosition: PositionType = { x: 0, y: 0 };
  @State isPicker: boolean = false;
  @State isHorizontalLevelShow: boolean = false;
  private mAspectRatio: SettingFuncDialogItemIndex = 0;
  private mVideoResolution: SettingFuncDialogItemIndex = 0;
  @State zoomPosition: number = AdaptiveLayoutService.getInstance().zoomPosition;
  @State tabBarPosition: number = AdaptiveLayoutService.getInstance().tabBarPosition;
  @State isShowSettingView: boolean = false;
  // mode switch and camera switch screeShot pixelMap
  @State mScreenshotPixelMap: image.PixelMap | null = null;
  @State blurredPixelMapPosition: PositionType = { x: 0, y: 0 };
  // mode switch data
  @LocalStorageLink('mShowModeSwitchImg') mShowModeSwitchImg: boolean = false;
  @State immersiveOpacity: number = 1;
  @State immersiveUIType: UIOperationType = UIOperationType.NULL;
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @State rotateAngle: number = 0;
  @State isShowLandscape: boolean = false;
  @State isShowTricollaps: boolean = false;
  @State isShowFocus: boolean = false;
  @State focusPosition: PositionType = { x: 0, y: 0 };
  @State previewSize: PositionType = { x: 0, y: 0 };
  // 慢动作相关
  @StorageLink('isDownSuperSlowBtnState') isDownSuperSlowBtn: boolean = false;
  // 显示更多功能
  @State isShowMorePage: boolean = false;
  @State lemModeIconScale: number = 1;
  @State lemModeIconTranslateY: number = 0;
  private xComponentSizeForAnim: Size = { width: 0, height: 0 }
  @StorageLink('isInBlurAnim') isInBlurAnim: boolean = false;
  @LocalStorageLink('needShowBlackBack') needShowBlackBack: boolean = false;
  @State isShowStageLightEffect: boolean = false;
  private lemCollapsZoomIndex: number = 1;
  @State indexFirCompHeight: number = 0;
  @State showGuideInfo: boolean = false;
  @StorageLink('showPhotoBrowserAction') showPhotoBrowserAction: boolean = false;
  @StorageLink('savePowerModeNeedRestartPreview') savePowerModeNeedRestartPreview: boolean = false;
  @StorageLink('isPanGestureDoing') isPanGestureDoing: boolean = false;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @LocalStorageLink('showAssistGrid') showAssistGrid: boolean = true;
  private progressSelfDecrAnimator: AnimatorResult | undefined = undefined;
  private total: number = 100;
  private low: number = 0;
  private progressDuration: number = 1000;
  private progressDelay: number = 0;
  @State @Watch('onProgressValueUpdate') progressValue: number = 0;
  @State roundModeIcon: Resource = $r(null);
  @State roundModeTextIcon: Resource = $r('app.string.portrait_mode');
  @LocalStorageLink('isLemModeSwitched') isLemModeSwitched: boolean = true;
  private subDisplayClickTimeout: number = Number.MIN_VALUE;
  private isWaitDoubleClick: boolean = false;
  @State isWindowRotationChange: boolean = false;
  private timerId: number = Number.MIN_VALUE;
  // 夜景拍照显示参考线、水平仪
  @StorageLink('isNightShutting') isNightShutting: boolean = false;
  @State isFocusLocked: boolean = false;
  @State focusLockImagePath: string = 'app.media.focus_unlock';
  private isLongExposure: boolean = false;
  @State xComponentRotate: number = 0;
  @State isDisplayRotationChange: boolean = false;
  private displayRotationTimerId: number = Number.MIN_VALUE;
  @State @Watch('refreshXComponentRotation') isVdeCollapsed: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State isVdeLandscape: boolean = false;
  @State windowStatusCurrent: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  @State isVdeSemiCollapsed: boolean = false;
  @State @Watch('refreshXComponentRotation') pickerWindowType: PickerWindowType = PickerWindowType.COLLAPSED_VERTICAL_FULL;
  private loadTimeoutTimer: number = Number.NaN; // 预览组件不走onload的兜底
  @State isHorizontalComponentVisible: boolean = false;
  @State customFilterCardOpened: boolean = false;
  @State isSkipPanGestureEnd: boolean = false;
  // 新夜景十字曝光
  @State isShowNightGuideView: boolean = false;
  @State isShowAICompositionBoxView: boolean = false;
  @State aiCompositionViewOpacity: number = 0;
  @StorageLink('onCustomFilterCardActionMenuShow') isShowActionMenu: boolean = false;
  @State smartControlLockState: boolean = false;
  @State smartControlLocked: boolean = false;
  private isSmileCaptured: boolean = false;
  private smileTimerId: number | null = null;
  @StorageLink('isChangingModeOrSwitchingCamera') isChangingModeOrSwitchingCamera: boolean = false;
  @State centerPoints: camera.Point[] = [{ x: 0, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 0 }, { x: 0, y: 0 }];
  // 水平仪是否可以显示标识
  @State canShowHorizontalComponentInNight: boolean = true;
  @State firstLevelLoaded: boolean = false;
  @Prop isHdr: boolean = false;
  @StorageLink('isCustomFilterCardTouched') isCustomFilterCardTouched: boolean = false;
  // 慢动作变焦动态扩展：切换变焦的模糊
  private mCacheVideoResolution: number = SettingFuncDialogItemIndex.INDEX_NONE;
  private mCacheFrameRate: number = 30;
  private mCacheCanAddFilter: boolean = true;
  @State isShowXComponent: boolean = true;
  @State isShowViewVisibility: boolean = false;
  buildFromPicker: boolean = false;

  private onAspectRatioChanged(data?: resolutionData): void {
    if (data) {
      this.mAspectRatio = data.val;
    }
  }

  private onVideoResolutionChanged(data?: resolutionData): void {
    if (data) {
      this.mVideoResolution = data.val;
    }
  }

  private computeCenterPoint(): void {
    this.centerPoints[0].x = this.previewAnimateWidth / 2;
    this.centerPoints[0].y = this.previewAnimateHeight / 2 - this.previewAnimateWidth * SCALE_RATIO / 2;
    this.centerPoints[1].x = this.previewAnimateWidth / 2 + this.previewAnimateWidth * SCALE_RATIO / 2;
    this.centerPoints[1].y = this.previewAnimateHeight / 2;
    this.centerPoints[2].x = this.previewAnimateWidth / 2;
    this.centerPoints[2].y = this.previewAnimateHeight / 2 + this.previewAnimateWidth * SCALE_RATIO / 2;
    this.centerPoints[3].x = this.previewAnimateWidth / 2 - this.previewAnimateWidth * SCALE_RATIO / 2;
    this.centerPoints[3].y = this.previewAnimateHeight / 2;
  }

  private mUpdateMode(): void {
    HiLog.i(TAG,
      `mUpdateMode: ${this.mode},${this.mVideoResolution},${this.mAspectRatio},${this.previewAnimateWidth},` +
        `${this.previewAnimateHeight}`);
    let isExtendBarContinuation = getStates().get<boolean>('uiReducer', 'isExtendBarContinuation');
    // 更新新夜景十字曝光中心位置
    this.computeCenterPoint();
    const isPanVideoOutput: boolean = OutputOperation.isPanVideoOutput(this.mode);
    isPanVideoOutput ? this.onVideoResolutionChanged() : this.onAspectRatioChanged();
  }

  public ratioToPercentage(ratio: number): number {
    return (Math.log2(ratio) - Math.log2(this.state.minZoomRatio)) /
      (Math.log2(this.state.maxZoomRatio) - Math.log2(this.state.minZoomRatio));
  }

  aboutToAppear(): void {
    HiLog.i(TAG, 'PreviewArea aboutToAppear.');
    this.isPicker = GlobalContext.get().getIsPicker();
    this.initPreviewAreaSubscriber();
    this.addEventBusListener();
    this.onForeground();
    this.displayWidth =
      getStates().get<number>('windowReducer', 'windowWidth') || DisplayService.getInstance().getDisplay().width;
    this.displayHeight =
      getStates().get<number>('windowReducer', 'windowHeight') || DisplayService.getInstance().getDisplay().height;
    this.xComponentWidth = getStates().get<number>('previewReducer', 'xComponentWidth');
    this.xComponentHeight = getStates().get<number>('previewReducer', 'xComponentHeight');
    let options: AnimatorOptions = {
      duration: this.progressDuration,
      easing: 'fast-out-linear-in',
      delay: this.progressDelay,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: this.total,
      end: this.low,
    };
    let theAnimator: AnimatorResult | null = Animator.create(options);
    theAnimator.onframe = (value) => {
      this.progressValue = value;
    }
    this.progressSelfDecrAnimator = theAnimator;
    this.canShowHorizontalComponentInNight = true;
    this.refreshXComponentRotation();
    this.setIntervalXComponentLoad();
    setTimeout(() => {
      HiLog.begin(TAG, 'LoadSecondLevel');
      this.firstLevelLoaded = true;
      HiLog.end(TAG, 'LoadSecondLevel');
    }, SECOND_LEVEL_LOAD_DELAY);
    HiLog.i(TAG, 'aboutToAppear end.');
  }

  private addEventBusListener() {
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_CHANGE_TIME_LAPSE, ActionType.ACTION_IS_ENTER_IMMERSIVE],
      this.isEnterImmersive.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_UPDATE_VIDEO_RESOLUTION,
      this.onVideoResolutionChanged.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_UPDATE_ASPECT_RATIO, this.onAspectRatioChanged.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.ON_SIZE_CHANGE,
      (data: DisplayRotationStruct) => this.displayRotationChange(data), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHANGE_X_COMPONENT_SIZE,
      (data: XComponentSize) => this.onChangeXComponentSize(data), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.ON_LENS_DIRTY, this.onLensDirty.bind(this), this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.ON_SIZE_CHANGE,
      () => this.spinUpdateStatus(), this.mBase.hashCode());
    this.mEventBus.on([WindowActionType.REFRESH_UX, WindowActionType.WINDOW_STATUS],
      this.onDisplayRotationChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.AUDIO_CONTROL_SHUTTER_BUTTON, this.audioControlCaptureEvent.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LONG_EXPOSURE_SHUTTER,
      () => this.changeLongExposure(true), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LONG_EXPOSURE_SHUTTER_END,
      () => this.changeLongExposure(false), this.mBase.hashCode());
    this.mEventBus.on(PreviewActionType.SET_LEM_MODE_ICON,
      (data: Record<string, number>) => this.setLemModeIcon(data.dir), this.mBase.hashCode());
    this.mEventBus.on(PreviewActionType.CHANGE_PREVIEW_SIZE_ANIM,
      () => this.changePreviewSizeAnim(this.xComponentSizeForAnim),
      this.mBase.hashCode());
    this.mEventBus.on(PreviewActionType.UPDATE_PREVIEW_AREA_ATTRS,
      () => this.updatePreviewAreaAttrs(this.xComponentSizeForAnim), this.mBase.hashCode());
    this.mEventBus.on(PreviewActionType.HIDE_X_COMPONENT, () => this.isShowXComponent = false, this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.setPreviewRotation.bind(this), this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_CHANGE_TIMED_SHOT, ActionType.ACTION_IS_ENTER_IMMERSIVE],
      this.isEnterImmersive.bind(this), this.mBase.hashCode());
  }

  private setPreviewRotation(): void {
    const windowStatus = WindowService.getInstance().getWindowStatus();
    if ((this.xComponentWidth !== this.xComponentSizeForAnim.width ||
      this.xComponentHeight !== this.xComponentSizeForAnim.height)) {
      this.showAssistGrid = false;
    }
    HiLog.i(TAG, `isNeed setPreviewRotation in floating, windowStatus: ${windowStatus}.`);
    if (DeviceInfo.isTablet() && !PickerUtils.getIsPicker() && !AppStorage.get('setXCRotation')) {
      if (windowStatus === window.WindowStatusType.FLOATING) {
        this.mAction.setPreviewRotation();
      } else {
        // 在全景多窗下（floating）冷启动，再热启桌面相机，不会走XC_Onload，需要主动调用lockSurface保证预览方向正确
        WindowService.getInstance().lockXComponentSurface();
      }
    }
  }

  private onForeground(): void {
    HiLog.i(TAG, 'show XComponent');
    this.isShowXComponent = true;
  }

  private onBackground(data: AbilityBackgroundData): void {
    this.mAction.updateShowBurstCaptureBigTextFlag(false);
    getStates().get<boolean>('zoomReducer', 'isShowPinch') && this.mAction.updateShowPinch(false);
  }

  private spinUpdateStatus(): void {
    this.mAction.uiEnabled();
  }

  private initPreviewAreaSubscriber(): void {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        minZoomRatio: state.get<number>('zoomReducer', 'minZoomRatio'),
        maxZoomRatio: state.get<number>('zoomReducer', 'maxZoomRatio'),
        isShowBigText: state.get<boolean>('modeReducer', 'isShowBigText'),
        isShowNightBigText: state.get<boolean>('modeReducer', 'isShowNightBigText'),
        isShowtimeLapse: state.get<boolean>('settingReducer', 'isShowtimeLapse'),
        isAssGridViewShow: state.get<boolean>('settingReducer', 'isAssGridViewShow'),
        uiEnable: state.get<boolean>('contextReducer', 'uiEnable'),
        videoState: state.get<number>('recordReducer', 'recordingState'),
        direction: state.get<number>('contextReducer', 'direction'),
        rotateAngle: state.get<number>('contextReducer', 'rotateAngle'),
        isShowExtendBar: state.get<boolean>('uiReducer', 'isShowExtendBar'),
        cameraRunningState: state.get<CameraRunningState>('cameraReducer', 'cameraRunningState'),
        mode: state.get<ModeType>('modeReducer', 'mode'),
        isShowLowAngleShotView: state.get<boolean>('collapsReducer', 'isShowLowAngleShotView'),
        isImageStabilizationGuideShow: state.get<boolean>('nightSubModeReducer', 'isImageStabilizationGuideShow'),
        isForeground: state.get<boolean>('contextReducer', 'isForeground'),
        isImmersive: state.get<boolean>('uiReducer', 'isImmersive'),
        exposureTime: state.get<number>('contextReducer', 'exposureTime'),
        isShowTimedShot: state.get<boolean>('settingReducer', 'isShowTimedShot'),
      });
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.isShowSettingView = state.get<boolean>('settingViewReducer', 'isShowSettingView');
      this.updateStateVariable(state);
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
      this.windowStatusCurrent = getStates().get<number>('windowReducer', 'windowStatus');
      this.pickerWindowType = state.get<PickerWindowType>('windowReducer', 'pickerWindowType');
      this.customFilterCardOpened = state.get<boolean>('customFilterStyleReducer', 'customFilterCardOpened');
      this.smartControlLocked = state.get<boolean>('focusExposureReducer', 'smartControlLocked');
      this.isShowFocus = state.get<boolean>('focusExposureReducer', 'isShowFocus');
      this.isShowViewVisibility = state.get<boolean>('contextReducer', 'isViewVisibility');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
  }

  private onChangeXComponentSize(data: XComponentSize): void {
    const isHorizontal: boolean = DisplayService.getInstance().isHorizontal();
    const windowHeight: number = getStates().get<number>('windowReducer', 'windowHeight');
    const minHeight: number = windowHeight * 0.7;
    if (isHorizontal && data.xComponentHeight < minHeight) {
      HiLog.w(TAG, `onChangeXComponentSize intercept wrong height: ${data.xComponentHeight}, force to ${windowHeight}`);
      data = { xComponentWidth: data.xComponentWidth, xComponentHeight: windowHeight };
    }
    HiLog.i(TAG, `onChangeXComponentSize E, data: ${JSON.stringify(data)}.`);
    this.zoomPosition = AdaptiveLayoutService.getInstance().zoomPosition;
    this.xComponentSizeForAnim = { width: data.xComponentWidth, height: data.xComponentHeight };
  }

  private onLensDirty(data: Record<string, boolean>): void {
    if (this.showPhotoBrowserAction) {
      if (TipService.getInstance().isAlwaysShowTip()) {
        TipService.getInstance().hideAlwaysShowTip($r('app.string.is_dirty_lens'));
      }
      return;
    }
    HiLog.i(TAG, `onLensDirty: ${data.isCameraLensDirty}`);
    if (data.isCameraLensDirty) {
      if (!TipService.getInstance().isAlwaysShowTip()) {
        TipService.getInstance().showTip($r('app.string.is_dirty_lens'), DurationType.Duration_LENS_DIRTY, true);
      }
    } else {
      if (TipService.getInstance().isAlwaysShowTip()) {
        TipService.getInstance().hideAlwaysShowTip($r('app.string.is_dirty_lens'));
      }
    }
  }

  private displayRotationChange(data: DisplayRotationStruct): void {
    if (Number.MIN_VALUE !== this.timerId) {
      clearTimeout(this.timerId);
    }
    this.isWindowRotationChange = true;
    this.previewAnimateWidth = getStates().get<number>('previewReducer', 'xComponentWidth');
    this.previewAnimateHeight = getStates().get<number>('previewReducer', 'xComponentHeight');
    this.timerId = setTimeout(() => {
      this.isWindowRotationChange = false;
    }, 150);
  }

  private updateStateVariable(state: OhCombinedState): void {
    const featureManager: FeatureManager = FeatureManager.getInstance();
    if (this.mode !== ModeType.NONE && this.mode !== state.get<ModeType>('modeReducer', 'mode') &&
      state.get<ModeType>('modeReducer', 'mode') === ModeType.VIDEO) {
    }
    this.mode = state.get<ModeType>('modeReducer', 'mode');
    this.isHorizontalLevelShow = featureManager.getFunction(FunctionId.HORIZONTAL_LEVEL).getValue();
    this.mAspectRatio = featureManager.getFunction(FunctionId.ASPECT_RATIO).getValue();
    if ((this.isWindowRotationChange) &&
      !BlurAnimateUtil.getWaitForPositionFlag()) {
      //专为防抖场景规避动效不一致问题。互斥回调触发的预览大小变化早于function改变回调触发的预览位置变化，这里控制两个动效统一触发
      if (BlurAnimateUtil.getWaitForPositionFlag() &&
        !this.isWindowRotationChange && this.previewAnimateWidth !== 0 && this.previewAnimateHeight !== 0) {
        if (this.previewAnimatePosition.y !== this.newPreviewAnimatePosition.y) {
          this.previewAnimateWidth = state.get<number>('previewReducer', 'xComponentWidth');
          this.previewAnimateHeight = state.get<number>('previewReducer', 'xComponentHeight');
          HiLog.i(TAG, `updateStateVariable, previewPosition: ${this.previewAnimatePosition.y}.`);
          this.previewAnimatePosition = this.newPreviewAnimatePosition;
          BlurAnimateUtil.setWaitForPositionFlag(false);
        }
      } else {
        this.previewAnimateWidth = state.get<number>('previewReducer', 'xComponentWidth');
        this.previewAnimateHeight = state.get<number>('previewReducer', 'xComponentHeight');
        if (this.xComponentSizeForAnim.width === 0) {
          this.xComponentSizeForAnim = {
            width: state.get<number>('previewReducer', 'xComponentWidth'),
            height: state.get<number>('previewReducer', 'xComponentHeight')
          }
        }
      }
    } else if (this.previewAnimateWidth === 0 || this.previewAnimateHeight === 0) {
      // 规避previewArea在模糊中销毁重建场景
      this.previewAnimateWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.previewAnimateHeight = state.get<number>('previewReducer', 'xComponentHeight');
      featureManager.setIsInResolution(false);
      this.isInBlurAnim = false;
    } else if (AppStorage.has('isVisitedByShortCut')) {
      this.previewAnimateWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.previewAnimateHeight = state.get<number>('previewReducer', 'xComponentHeight');
      AppStorage.delete('isVisitedByShortCut');
    }
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'previewArea aboutToDisappear called.');
    this.mAction.hideTip();
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    setTimeout(() => {
      HiLog.i(TAG, 'release pixelMap before disappear');
      this.mScreenshotPixelMap?.release();
    }, PIXELMAP_RELEASE_DELAY)
    this.clearXComponentLoadTimerId();
  }

  public onDisplayRotationChange(): void {
    HiLog.i(TAG, 'onDisplayRotationChange');
    this.refreshXComponentRotation();
    if (this.displayRotationTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.displayRotationTimerId);
    }
    this.isDisplayRotationChange = true;
    this.displayRotationTimerId = setTimeout(() => {
      this.isDisplayRotationChange = false;
    }, ROTATION_DELAY);
  }

  private refreshXComponentRotation(): void {
    if (DeviceInfo.isTablet() && PickerUtils.getIsPicker()) {
      this.xComponentRotate = 0;
      return;
    }
    const windowStatus = WindowService.getInstance().getWindowStatus();
    let offset: number = 0;
    if (PickerUtils.getIsExpandedTopBottomSplitScreenFromReducer()) {
      offset = 90;
    }
    HiLog.i(TAG, 'refreshXComponentRotation windowStatus:' + windowStatus);
    if (windowStatus === window.WindowStatusType.FLOATING || windowStatus === window.WindowStatusType.SPLIT_SCREEN ||
      PickerUtils.getIsPicker() && !PickerUtils.getIsFullScreenFromReducer() &&
        !this.isShowTricollaps) {
      const rotation = DisplayService.getInstance().getDisplay().rotation;
      HiLog.i(TAG, 'refreshXComponentRotation rotation:' + rotation);
      switch (rotation) {
        case 0:
          this.xComponentRotate = 0 + offset;
          break;
        case 1:
          this.xComponentRotate = 90 + offset;
          break;
        case 2:
          this.xComponentRotate = 180 + offset;
          break;
        case 3:
          this.xComponentRotate = 270 + offset;
          break;
        default:
          this.xComponentRotate = 0 + offset;
      }
    } else if (this.isVdeCollapsed) {
      const rotation = DisplayService.getInstance().getDisplay().rotation;
      HiLog.i(TAG, 'phone refreshXComponentRotation rotation:' + rotation);
      this.xComponentRotate = 270;
    } else {
      this.xComponentRotate = 0;
    }
    HiLog.i(TAG, 'refreshXComponentRotation xComponentRotate:' + this.xComponentRotate);
  }

  private changePreviewSizeAnim(newSize: Size) {
    if (newSize.width === 0 || newSize.height === 0) {
      HiLog.w(TAG, 'changePreviewSizeAnim newSize is invalid');
      return;
    }
    HiLog.begin(TAG, 'changePreviewSizeAnim');
    animateToImmediately({
      duration: BlurAnimateUtil.CHANGE_PREVIEW_DURATION,
      curve: AnimSpecifications.ANIM_PREVIEW_AREA_UP_OR_DOWN,
      onFinish: () => {
        this.blurredPixelMapPosition = this.previewAnimatePosition;
        this.showAssistGrid = true;
        HiLog.end(TAG, 'changePreviewSizeAnim');
      }
    }, () => {
      this.updatePreviewAreaAttrs(newSize);
    });
  }

  private updatePreviewAreaAttrs(newSize: Size): void {
    this.previewAnimateWidth = newSize.width;
    this.previewAnimateHeight = newSize.height;
    this.previewAnimatePosition = this.newPreviewAnimatePosition;
    this.xComponentWidth = newSize.width;
    this.xComponentHeight = newSize.height;
    this.showAssistGrid = true;
  }

  private isEnterImmersive(data: EnterImmersiveStruct): void {
    if (this.isVdeCollapsed) {
      return;
    }
    let mIsImmersive: boolean = false;
    let mImmersiveUIType: UIOperationType = UIOperationType.NULL;
    let json: EnterImmersiveStruct = JSON.parse(JSON.stringify(data));
    HiLog.i(TAG, `isEnterImmersive json: ${JSON.stringify(data)}.`)
    if (json.isShowtimeLapse !== undefined) { // 定时拍摄需要状态变量渲染组件,就不再重复发Action了直接复用
      mIsImmersive = json.isShowtimeLapse;
      mImmersiveUIType = mIsImmersive ? UIOperationType.TIMELAPSE : UIOperationType.NULL;
    } else {
      if (json.isImmersive !== undefined) {
        mIsImmersive = json.isImmersive;
      }
      if (json.mainTrigCompo !== undefined) {
        mImmersiveUIType = mIsImmersive !== undefined ? json.mainTrigCompo : UIOperationType.NULL;
      }
    }
    if (mIsImmersive &&
      (mImmersiveUIType === UIOperationType.ZOOM_BAR || mImmersiveUIType === UIOperationType.EXTEND_BAR ||
        mImmersiveUIType === UIOperationType.EXPOSURE || mImmersiveUIType === UIOperationType.PRO_BAR)) {
      this.showAssistGrid = false;
    } else {
      this.showAssistGrid = true;
    }
    if (mIsImmersive) {
      this.immersiveUIType = mImmersiveUIType;
      this.immersiveOpacity = 1;
    } else {
      this.immersiveOpacity = 0;
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_150,
        curve: Curve.Sharp,
        onFinish: () => {
          this.immersiveUIType = mImmersiveUIType; // 保证退出沉浸式时self不受opacity影响
        }
      }, () => {
        this.immersiveOpacity = 1;
      });
    }
  }

  private setAlignContent() {
    return Alignment.Center;
  }

  private getPreviewAnimateWidth(): number {
    if (PickerUtils.getIsPicker()) {
      if (PickerUtils.getIsFullScreen()) {
        return this.previewAnimateWidth;
      }
      if (this.pickerWindowType === PickerWindowType.EXPANDED_TOP_BOTTOM_SPLIT_SCREEN) {
        return DisplayService.getInstance().isOrientationVertical() ? this.previewAnimateHeight :
          this.previewAnimateWidth;
      }
      if (!DisplayService.getInstance().isOrientationVertical()) {
        return this.previewAnimateHeight;
      }
      return this.previewAnimateWidth;
    }
    return this.previewAnimateWidth;
  }

  private getPreviewAnimateHeight(): number {
    if (PickerUtils.getIsPicker()) {
      if (PickerUtils.getIsFullScreen()) {
        return this.previewAnimateHeight;
      }
      if (this.pickerWindowType === PickerWindowType.EXPANDED_TOP_BOTTOM_SPLIT_SCREEN) {
        return DisplayService.getInstance().isOrientationVertical() ? this.previewAnimateWidth :
          this.previewAnimateHeight;
      }
      if (!DisplayService.getInstance().isOrientationVertical()) {
        return this.previewAnimateWidth;
      }
      return this.previewAnimateHeight;
    }
    return this.previewAnimateHeight;
  }

  private setIntervalXComponentLoad(): void {
    if (!!this.loadSurfaceDone || !Number.isNaN(this.loadTimeoutTimer)) {
      return
    }
    HiLog.i(TAG, 'PREVIEW_LOAD_TIMEOUT setIntervalXComponentLoad.');
    this.loadTimeoutTimer = setTimeout(async () => {
      HiLog.i(TAG, 'PREVIEW_LOAD_TIMEOUT load surface time out.');
      await this.retryGetSurface();
      this.loadTimeoutTimer = Number.NaN;
    }, X_COMPONENT_LOAD_TIMEOUT_DELAY);
  }

  private async retryGetSurface(retry: number = 1, maxRetries: number = 9, delayMs: number = 300): Promise<void> {
    if (!!this.loadSurfaceDone || Number.isNaN(this.loadTimeoutTimer)) {
      return;
    }
    HiLog.i(TAG, `PREVIEW_LOAD_TIMEOUT createSurface try times: ${retry}.`);
    const surface = XComponentService.getInstance().createSurface();
    HiLog.i(TAG, `PREVIEW_LOAD_TIMEOUT createSurface: ${surface}.`);
    if (!surface) {
      HiLog.e(TAG, 'PREVIEW_LOAD_TIMEOUT createSurface failed.');
      if (maxRetries < retry) {
        return;
      }
      await new Promise<void>(resolve => setTimeout(resolve, delayMs));
      HiLog.i(TAG, `PREVIEW_LOAD_TIMEOUT sleep time ${delayMs}ms.`);
      await this.retryGetSurface(retry + 1, maxRetries, delayMs);
    } else {
      this.startPreview();
    }
  }

  private startPreview(): void {
    this.loadSurfaceDone = true;
    this.mAction.loadSurfaceDone();
    const oldSurface = XComponentService.getInstance().getSurface();
    const surface = XComponentService.getInstance().createSurface();
    let runningState = getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState');
    HiLog.i(TAG, `PREVIEW_LOAD_TIMEOUT load xComponent surface: ${surface}, runningState: ${runningState
    }, showPhotoBrowserAction: ${this.showPhotoBrowserAction}`);
    if (this.showPhotoBrowserAction && !AppStorage.get('isHidingPhotoBrowser')) {
      HiLog.i(TAG, 'showPhotoBrowserAction is true and not isHidingPhotoBrowser');
      return;
    }
    this.mAction.startupWithDeferredSurface(runningState === CameraRunningState.INITIALIZING ||
      (CollaborateControlService.getInstance().isInCollaborateState() && !oldSurface))
    this.mAction.loadPhotoBrowser();
  }

  private clearXComponentLoadTimerId(): void {
    if (!Number.isNaN(this.loadTimeoutTimer)) {
      HiLog.i(TAG, 'PREVIEW_LOAD_TIMEOUT clearXComponentLoadTimerId, loadTimeoutTimer');
      clearTimeout(this.loadTimeoutTimer);
      this.loadTimeoutTimer = Number.NaN;
    }
  }

  private getAndUpdateIsHorizontalComponentVisible(): boolean {
    this.isHorizontalComponentVisible =
      (!this.isShowMorePage && this.immersiveOpacity !== 0 || this.immersiveUIType === UIOperationType.LR_SWIPE) &&
        !this.isDisplayRotationChange && this.canShowHorizontalComponentInNight && !this.state.isImmersive;
    HiLog.i(TAG, `getAndUpdateIsHorizontalComponentVisible: ${this.isHorizontalComponentVisible}.`)
    return this.isHorizontalComponentVisible;
  }

  private getXComponentWidth(): number {
    const windowStatus = WindowService.getInstance().getWindowStatus();
    if (!PickerUtils.getIsUIExtensionPicker() &&
      (windowStatus === window.WindowStatusType.FLOATING || windowStatus === window.WindowStatusType.SPLIT_SCREEN)) {
      const rotation = DisplayService.getInstance().getDisplay().rotation;
      if (rotation === 3 || rotation === 1) { //悬浮窗 分屏横屏场景
        return this.xComponentHeight;
      }
    }
    if (this.isVdeCollapsed) {
      HiLog.i(TAG, `isVdeCollapsed getXComponentWidth = ${this.xComponentHeight}.`);
      return this.xComponentHeight;
    }
    return this.xComponentWidth;
  }

  private getXComponentHeight(): number {
    const windowStatus = WindowService.getInstance().getWindowStatus();
    if (!PickerUtils.getIsUIExtensionPicker() &&
      (windowStatus === window.WindowStatusType.FLOATING || windowStatus === window.WindowStatusType.SPLIT_SCREEN)) {
      const rotation = DisplayService.getInstance().getDisplay().rotation;
      if (rotation === 3 || rotation === 1) { //悬浮窗 分屏横屏场景
        return this.xComponentWidth;
      }
    }
    if (this.isVdeCollapsed) {
      return this.xComponentWidth;
    }
    return this.xComponentHeight;
  }

  build() {
    Stack() {
      Stack() {
        Stack({ alignContent: (this.isLemCollaps ? Alignment.Center : Alignment.Bottom) }) {
          XComponent({
            id: hebcXcId, // Hardware Direct Connect Preview,禁止变更
            type: XComponentType.SURFACE,
            controller: XComponentService.getInstance().getController()
          } as ESObject)
            .id(PreviewArea.xComponentId)
            .onLoad(() => {
              HiLog.begin(TAG, 'XComponent_onLoad');
              this.clearXComponentLoadTimerId();
              // 避免兜底函数走过起流后再二次起流
              if (!this.loadSurfaceDone) {
                HiLog.i(TAG, 'PREVIEW_LOAD_TIMEOUT x_component onload trigger.');
                this.startPreview();
              }
              HiLog.end(TAG, 'XComponent_onLoad');
            })
            .onDestroy(() => {
              HiLog.begin(TAG, 'XComponent_onDestroy');
              const surface = XComponentService.getInstance().deleteSurface();
              HiLog.i(TAG, `XComponent_onDestroy, delete surface: ${surface}.`);
              HiLog.end(TAG, 'XComponent_onDestroy');
            })
            .width(this.getXComponentWidth())
            .height(this.getXComponentHeight())
            .rotate({ angle: this.xComponentRotate })
            .hitTestBehavior(HitTestMode.Transparent)
            .visibility(this.isShowXComponent && this.isShowViewVisibility ? Visibility.Visible : Visibility.Hidden)

          if (this.isShowAICompositionBoxView && !this.isChangingModeOrSwitchingCamera && !this.isShowSettingView &&
            !this.isPicker) {
          }

          // 水平仪 显示状态下展开态窗口旋转时消失 旋转结束之后显示
          if (!this.isLemCollaps && !this.isVdeCollapsed && this.isHorizontalLevelShow &&
            (!this.state.isShowBigText || this.state.videoState !== RecordingState.READY) &&
            !this.state.isShowtimeLapse) {
            HorizontalLevelView()
              .visibility(this.getAndUpdateIsHorizontalComponentVisible() ? Visibility.Visible : Visibility.Hidden)
              .onAreaChange(() => {
              })
            HorizontalCrucifix({
              isHorizontalCrucifixVisible: this.isHorizontalComponentVisible,
              mode: this.mode,
            })
              .visibility(this.getAndUpdateIsHorizontalComponentVisible() ? Visibility.Visible : Visibility.Hidden);

            HorizontalCrucifix({
              fillColor: MOVABLE_CRUCIFIX_COLOR,
              shadowRadius: MOVABLE_CRUCIFIX_SHADOW_RADIUS,
              isMovable: true,
              isHorizontalCrucifixVisible: this.isHorizontalComponentVisible,
              mode: this.mode,
            })
              .visibility(this.getAndUpdateIsHorizontalComponentVisible() ? Visibility.Visible : Visibility.Hidden);
          }

          // 辅助线
          if (!this.isLemCollaps && !this.isVdeCollapsed && this.state.isAssGridViewShow &&
            (!this.state.isShowBigText || this.state.videoState !== RecordingState.READY) &&
          this.showAssistGrid && this.state.cameraRunningState === CameraRunningState.STARTED) {
            AssistiveGridView()
              .hitTestBehavior(HitTestMode.Transparent)
              .position({ x: this.positionZero, y: this.positionZero })
              .visibility(!this.isShowMorePage && this.immersiveOpacity !== 0 || this.state.isShowtimeLapse ||
                this.immersiveUIType === UIOperationType.LR_SWIPE ? Visibility.Visible : Visibility.Hidden)
              .zIndex(ZIndex.TOP)
              .key(ComponentIdKeys.ASSISTIVE_GRID_VIEW)
          }

          DetectionView({
            isShowStageLightEffect: this.isShowStageLightEffect,
            isDisplayRotationChange: this.isDisplayRotationChange,
            immersiveOpacity: this.immersiveOpacity,
            xComponentWidth: this.previewAnimateWidth,
            xComponentHeight: this.previewAnimateHeight,
            previewPosition: this.previewAnimatePosition.y,
            isHdr: this.isHdr,
          })
            .hitTestBehavior(HitTestMode.Transparent)

          ShowFlashBlack({
            xComponentWidth: this.previewAnimateWidth,
            xComponentHeight: this.previewAnimateHeight
          })
            .hitTestBehavior(HitTestMode.Transparent)

          if (this.state.isShowtimeLapse) {
            TimeLapseView()
          }

          if (this.state.isShowBigText && (this.isShowLandscape || this.isShowTricollaps) && !this.isShowMorePage) {
            BigText({ isHdr: this.isHdr })
              .zIndex(ZIndex.TOP)
          }

          //前后置切换时背景，否则会有停流前的残留
          if (this.needShowBlackBack && this.mShowModeSwitchImg && this.mScreenshotPixelMap) {
            Column()
              .key('test1')
              .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
              .width(this.previewAnimateWidth)
              .height(this.previewAnimateHeight)
              .backgroundColor(Color.Black)
          }

          if (this.isShowStageLightEffect && this.state.cameraRunningState === CameraRunningState.STARTED &&
            !this.isInBlurAnim && !this.isShowMorePage) {
          }

          PreviewBlurAnimationComponent({
            xComponentWidth: this.xComponentWidth,
            xComponentHeight: this.xComponentHeight,
            previewAnimateWidth: this.previewAnimateWidth,
            previewAnimateHeight: this.previewAnimateHeight,
            mScreenshotPixelMap: this.mScreenshotPixelMap,
            blurredPixelMapPosition: this.blurredPixelMapPosition
          });

          if (this.isPSDCollapsed) {
            RelativeContainer() {
              Text(this.roundModeTextIcon)
                .height(36)
                .fontColor(Color.White)
                .fontSize(20)
                .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL2)
                .fontWeight(FontWeight.Medium)
                .textAlign(TextAlign.Center)
                .draggable(false)
                .margin({
                  bottom: CommonConstants.VERTICAL_PADDING,
                  top: CommonConstants.VERTICAL_PADDING,
                  left: CommonConstants.VERTICAL_PADDING,
                  right: CommonConstants.VERTICAL_PADDING
                })
                .alignRules(this.getAlignRule())
                .rotate({ angle: this.rotateAngle })
                .animation({ duration: AnimSpecifications.ANIM_DURATION_300, curve: Curve.Ease })
                .translate({ y: this.lemModeIconTranslateY })
                .scale({ x: this.lemModeIconScale, y: this.lemModeIconScale })
            }
            .width(DISPLAY_SCREEN_SIZE_PSD)
            .height(DISPLAY_SCREEN_SIZE_PSD)
            .visibility(!this.state.isShowtimeLapse && this.state.videoState === RecordingState.READY ?
              Visibility.Visible : Visibility.Hidden)
            .visibility(!this.state.isShowtimeLapse && !this.state.isShowTimedShot &&
              this.state.videoState === RecordingState.READY ?
              Visibility.Visible : Visibility.Hidden)
            .enabled(false)
          } else if (this.isLemCollaps) { // LEM副屏模式图标
            RelativeContainer() {
              Image(this.roundModeIcon)
                .width(36)
                .height(36)
                .fillColor(Color.White)
                .draggable(false)
                .margin({ bottom: 20 })
                .alignRules({
                  middle: { anchor: '__container__', align: HorizontalAlign.Center },
                  bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
                })
                .rotate({ angle: this.rotateAngle })
                .animation({ duration: AnimSpecifications.ANIM_DURATION_300, curve: Curve.Ease })
                .translate({ y: this.lemModeIconTranslateY })
                .scale({ x: this.lemModeIconScale, y: this.lemModeIconScale })
            }
            .width(DISPLAY_SCREEN_SIZE_LEM)
            .height(DISPLAY_SCREEN_SIZE_LEM)
            .visibility(!this.state.isShowtimeLapse && !this.state.isShowTimedShot ? Visibility.Visible :
              Visibility.Hidden) // 外屏间隔定时拍和定时拍摄触发，隐藏设置人像等其他多余元素
            .enabled(false)
          }
        }
        .width((this.isLemCollaps || this.isVdeCollapsed || this.isPSDCollapsed) ? '100%' : this.previewAnimateWidth)
        .height((this.isLemCollaps || this.isVdeCollapsed || this.isPSDCollapsed) ? '100%' : this.previewAnimateHeight)
        .alignContent(this.setAlignContent())
        .hitTestBehavior(HitTestMode.Transparent)
        .clip(true)
        .enabled(!this.isDownSuperSlowBtn)
      }
    }
    .width(this.getPreviewAnimateWidth())
    .height(this.getPreviewAnimateHeight())
    .accessibilityGroup(true)
    .accessibilityLevel((this.isShowActionMenu && this.enableScreenReader) ?
      CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
      CommonConstants.ACCESSIBILITY_LEVEL_YES)
  }

  otherCapture(): boolean {
    const timeLapse: number = FeatureManager.getInstance().getFunction(FunctionId.TIME_LAPSE)?.getValue();
    const timeLapseType: boolean = !!timeLapse && timeLapse > SettingFuncDialogItemIndex.INDEX_FIR;
    if (timeLapseType) {
      this.mAction.changeTimeLapse(true);
      this.mAction.uiEnabled();
      return false;
    }
    return true;
  }

  onProgressValueUpdate() {
    HiLog.i(TAG, 'onProgressValueUpdate. this.progressValue = ' + this.progressValue);
    if (this.progressValue <= 0) {
      // 间隔拍摄功能方法
      const state = this.otherCapture();
      if (!state) {
        return;
      }

      HiLog.i(TAG, 'photoShutterUpCapture callback start.');
      this.mAction.changeTimeLapse(false);
      this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
      this.mAction.capture();
      this.mAction.changeFunctionValue(FunctionId.CAPTURE, true);
      this.mAction.uiEnabled();
      HiLog.i(TAG, 'photoShutterUpCapture callback end.');
    }
  }

  private startProgressCircle() {
    if (!this.state.uiEnable || !this.isLemCollaps) {
      return;
    }
    this.mAction.uiDisabled();
    HiLog.i(TAG, 'startProgressCircle start time = ' + Date.now());
    this.progressSelfDecrAnimator?.play();
    HiLog.i(TAG, 'startProgressCircle end time = ' + Date.now());
  }

  private processVideoMode(): void {
    HiLog.i(TAG, `this.state.videoState:` + this.state.videoState);
    if (this.state.videoState === RecordingState.RECORDING) {
      this.stopVideoMode();
      this.setLemModeIcon(0);
      this.isLemModeSwitched = true;
    } else if (this.state.videoState === RecordingState.READY) {
      this.isLemModeSwitched = false;
      this.hideLemModeIcon();
      this.startVideoMode();
    }
  }

  private startVideoMode() {
    this.mAction.changeTimeLapse(false);
    this.mAction.startVideoAnim();
    this.mAction.startRecording();
    this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, 0);
  }

  private stopVideoMode(): void {
    this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
    this.mAction.stopRecording();
  }

  private hideLemModeIcon(): void {
    this.roundModeIcon = $r(null);
    this.roundModeTextIcon = $r(null);
    this.lemModeIconTranslateY = 0;
    this.lemModeIconScale = 0.77;
    animateTo({ duration: 300 }, () => {
      this.lemModeIconTranslateY = 90;
    })
    animateTo({ duration: 250, delay: 300 }, () => {
      this.lemModeIconScale = 1;
    })
  }

  private setLemModeIcon(dir: number): void {
    HiLog.d(TAG, `setLemModeIcon current mode: ${this.mode} dir: ${dir}`);
    if (dir === 1) {
      this.roundModeIcon = $r(null);
      this.roundModeTextIcon = $r(null);
    } else if (dir === 0) {
      this.roundModeIcon = $r(null);
      this.roundModeTextIcon = $r(null);
    } else {
      this.roundModeIcon = $r(null);
      this.roundModeTextIcon = $r(null);
    }
    this.lemModeIconTranslateY = 30;
    this.lemModeIconScale = 1.2;
    VibratorService.getInstance().triggerVibrator(VibratorService.MODE_SWITCH_EFFECT_ID);
    animateTo({ duration: AnimSpecifications.ANIM_DURATION_300 }, () => {
      this.lemModeIconTranslateY = 0;
    })
    animateTo({ duration: AnimSpecifications.ANIM_DURATION_250, delay: 300 }, () => {
      this.lemModeIconScale = 1;
    })
  }

  private async changeLongExposure(isLongExposure: boolean) {
    this.isLongExposure = isLongExposure;
    HiLog.i(TAG, "isLongExposure:" + this.isLongExposure)
  }

  private audioControlCaptureEvent(): void {
    if (this.isLemCollaps && !AppStorage.get<boolean>('isBackground')) {
      HiLog.i(TAG, 'isSmallScreenCollapsed start audioControlCaptureEvent');
      const isStarted: boolean =
        getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') === CameraRunningState.STARTED;
      if (!isStarted) {
        HiLog.i(TAG, 'isSmallScreenCollapsed camera status is not started.');
        return;
      }
      if (!CaptureService.getInstance().isEnableCapture() ||
      ThumbnailService.getInstance().isPictureAcquireOrStoreTimeOut()) {
        HiLog.i(TAG, 'isSmallScreenCollapsed camera is not ready or wait save photo.');
        return;
      }
      this.startProgressCircle();
    }
  }

  private getAlignRule(): AlignRuleOption {
    HiLog.i(TAG, `getAlignRule mDirection: ${this.mDirection}`);
    if (this.mDirection === WindowDirection.LEFT) {
      return {
        left: { anchor: '__container__', align: HorizontalAlign.Center },
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
      }
    } else if (this.mDirection === WindowDirection.TOP) {
      return {
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
      }
    } else if (this.mDirection === WindowDirection.RIGHT) {
      return {
        top: { anchor: '__container__', align: VerticalAlign.Center },
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
      }
    } else if (this.mDirection === WindowDirection.BOTTOM) {
      return {
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        top: { anchor: '__container__', align: VerticalAlign.Top }
      }
    } else {
      return {
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
      }
    }
  }

  private isSupportContinuumVideo(): boolean {
    return CameraAppCapability.getInstance().getIsSupportRecordingFlowing() && (this.state.mode === ModeType.VIDEO) &&
      !GlobalContext.get().getIsPicker();
  }
}