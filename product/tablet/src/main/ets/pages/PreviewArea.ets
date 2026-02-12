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
import {
  Action,
  UiStateMode,
  XCOMPONENTHEIGHT_OFFSETS,
  XCOMPONENTWIDTH_OFFSETS
} from '@ohos/common/src/main/ets/redux/actions/Action';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import { ShowFlashBlack } from '@ohos/common/src/main/ets/component/animate/ShowFlashBlack';
import { TimeLapseView } from '@ohos/extend/src/main/ets/settingcommonfunc/timelapse/TimeLapseView';
import { ZoomAction } from '@ohos/common/src/main/ets/function/zoombar/ZoomAction';
import { ZoomActionType } from '@ohos/common/src/main/ets/redux/actions/ZoomActionType';
import { ZoomOperation } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import { CameraProxy } from '@ohos/common/src/main/ets/camera/uithread/CameraProxy';
import { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import { RecordAction, RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import {
  CameraAction,
  CameraRunningState,
  CameraStartType,
  CameraStartTypeStruct
} from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import image from '@ohos.multimedia.image';
import { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { CaptureAction } from '@ohos/common/src/main/ets/function/capture/CaptureAction';
import { PositionType, XComponentSize } from '@ohos/common/src/main/ets/utils/types';
import { TimeLapseAction } from '@ohos/extend/src/main/ets/settingcommonfunc/timelapse/TimeLapseAction';
import { AdaptiveLayoutService } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLayoutService';
import { DisplayCalculator } from '@ohos/common/src/main/ets/component/xcomponent/DisplayCalculator';
import { ChangeState, getStates, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import { WorkerTask } from '@ohos/common/src/main/ets/camera/WorkerTask';
import lazy { NightTimeBigText } from '@ohos/common/src/main/ets/component/bigtext/NightTimeBigText';
import { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import { XComponentService } from '@ohos/common/src/main/ets/component/xcomponent/XComponentService';
import { BlurAnimateUtil } from '@ohos/common/src/main/ets/utils/BlurAnimateUtil';
import { PhotoFormatMode } from '@ohos/common/src/main/ets/function/enumbase/PhotoFormatMode';
import { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import display from '@ohos.display';
import curves from '@ohos.curves';
import { BurstCaptureBigText } from '@ohos/common/src/main/ets/component/bigtext/BurstCaptureBigText';
import { COMPONENT_WIDTH } from './default/DefaultIndex';
import { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import { ModeListManager } from '@ohos/common/src/main/ets/mode/ModeListManager';
import { MoreModeConfig } from '@ohos/common/src/main/ets/mode/MoreModeConfig';
import { reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import { ZoomParam } from '@ohos/common/src/main/ets/function/zoombar/ZoomParam';
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import { AssistiveGridView } from '@ohos/extend/src/main/ets/settingcommonfunc/assistivegrid/AssistiveGridView';
import { FocusExposureArea } from '@ohos/extend/src/main/ets/commonfunc/focus/FocusExposureArea';
import { HorizontalLevelView } from '@ohos/extend/src/main/ets/settingcommonfunc/horizontallevel/HorizontalLevelView';
import {
  HorizontalCrucifix,
  DURATION,
  MOVABLE_CRUCIFIX_COLOR,
  MOVABLE_CRUCIFIX_SHADOW_RADIUS
} from '@ohos/extend/src/main/ets/settingcommonfunc/horizontallevel/HorizontalCrucifix';
import { FocusExposureActionType } from '@ohos/common/src/main/ets/redux/actions/FocusExposureActionType';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';

const TAG: string = 'PreviewArea';

const NUM_16: number = 16;
const NUM_9: number = 9;
const NUM_4: number = 4;
const NUM_3: number = 3;
const NUM_1: number = 1;

const LAYOUT_NUM: number = 2;
const BIG_TEXT_MARGIN_TOP: number = 81;
const BIG_TEXT_MARGIN_TOP_VERTICAL: number = -132;
const FIRST_FRAME_TIMEOUT: number = 3000;
const BURST_BIG_TEXT_LINE_HEIGHT: number = 64;
const hebcXcId = 'HDC_PREVIEW';

class PreviewFrameStartData {
  public isPreviewFrameStart: boolean = false;
}

class ZoomFuncValueStruct {
  public zoomRatio?: number = 1;
  public isPrepareZoom?: boolean = false;
  public isUnprepareZoom?: boolean = false;
  public unprepareDelay?: number;
}

class DisplayRotationStruct {
  public displayRotation: number = 0;
}

class StateStruct {
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public minZoomRatio: number = 0;
  public maxZoomRatio: number = 0;
  public zoomRatio: number = 0;
  public isShowBigText: boolean = false;
  public isShowtimeLapse: boolean = false;
  public isAssGridViewShow: boolean = false;
  public uiEnable: boolean = false;
  public videoState: RecordingState = RecordingState.READY;
  public baseZoom: number = 0;
  public direction: number = 0;
  public cameraRunningState: CameraRunningState = CameraRunningState.UNINITIALIZED;
  public isShowNightBigText: boolean = false;
  public isForeground: boolean = false;
}

class ModeSwitchAnimData {
  public oldWidth: number = 0;
  public newWidth: number = 0;
  public oldHeight: number = 0;
  public newHeight: number = 0;
}

class PhotoInfoStruct {
  public imageFd: number = 0;
  public errorCode: number = 0;
}

class EnterImmersiveStruct {
  public isImmersive?: boolean = false;
  public mainTrigCompo?: UIOperationType = UIOperationType.NULL;
  public isShowtimeLapse?: boolean = false;
}

class AbilityBackgroundData {
  public isPickerBack: boolean = false;
}

class ShotComponentData {
  public oldMode: ModeType = ModeType.NONE;
  public newMode: ModeType = ModeType.NONE;
  public oldOutputType?: OutputType = OutputType.NONE;
  public newOutputType?: OutputType = OutputType.NONE;
  public isShowBigText: boolean = true;
}

class CollaborationFdData {
  public sandboxFd: number = 0;
  public sandboxPath: string = '';
}

class PreviewAreaDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public startupWithDeferredSurface(): void {
    this.mDispatch(CameraAction.start(true));
  }

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public restartPreview(zoomRatio?: number): void {
    this.mDispatch(CameraAction.restart(zoomRatio ? zoomRatio : 1));
  }

  public changeTimeLapse(isShowtimeLapse: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse));
  }

  public capture(): void {
    this.mDispatch(CaptureAction.capture());
  }

  public startRecording(): void {
    this.mDispatch(Action.uiStateWithMode(false, UiStateMode.EXCLUDE_PREVIEW));
    this.mDispatch(RecordAction.start());
  }

  public assistiveGridView(isViewShow: boolean): void {
    this.mDispatch(Action.assistiveGridView(isViewShow));
  }

  public thirdPartyCall(isThirdPartyCall: boolean, action: string): void {
    this.mDispatch(Action.thirdPartyCall(isThirdPartyCall, action));
  }

  public swipeChangeMode(swipe: number): void {
    this.mDispatch(Action.swipeChangeMode(swipe));
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

  public changeXComponentSize(xComponentWidth: number, xComponentHeight: number): void {
    this.mDispatch(Action.changeXComponentSize(xComponentWidth, xComponentHeight));
  }

  public updateShowBigTextFlag(isShowBigTxt: boolean): void {
    this.mDispatch(Action.updateShowBigTextFlag(isShowBigTxt));
  }

  public startVideoAnim(): void {
    this.mDispatch(TimeLapseAction.startVideoAnim());
  }

  public switchZoomRatio(toNext: boolean) {
    this.mDispatch(ZoomAction.switchZoomRatio(toNext));
  }

  public updateShowNightBigTextFlag(isShowNightBigText: boolean): void {
    this.mDispatch(Action.updateShowNightBigTextFlag(isShowNightBigText));
  }

  public startup(): void {
    this.mDispatch(CameraAction.warmStart());
  }

  public closeCamera(): void {
    this.mDispatch(CameraAction.close({ isNeedSaveRestore: true }));
  }

  public updateShowBurstCaptureBigTextFlag(isShowBurstCaptureBigText: boolean): void {
    this.mDispatch(Action.updateShowBurstCaptureBigTextFlag(isShowBurstCaptureBigText));
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
  private readonly bigTextHeight: number = 96;
  private readonly timeLapseBottom: number = 23;
  private readonly positionZero: number = 0;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State state: StateStruct = new StateStruct();
  @State mode: ModeType = ModeType.NONE;
  private mAction: PreviewAreaDispatcher = new PreviewAreaDispatcher();
  private baseZoom: number = 0;
  @Prop bigTextPosition: number = 0;
  @Link previewPosition: PositionType;
  @Link loadSurfaceDone: boolean;
  private isPicker: boolean = false;
  @State isHorizontalLevelShow: boolean = false;
  private previewPositionDefaultConst: number = AdaptiveLayoutService.getInstance().previewPositionDefaultConst;
  // mode switch and camera switch screeShot pixelMap
  @State mScreenshotPixelMap: image.PixelMap | null = null;
  @State mScreenshotPixelMapAngle: number = 0;
  // mode switch data
  @State mShowModeSwitchImg: boolean = false;
  @State mModeSwitchImgBlur: number = 0;
  @State immersiveOpacity: number = 1;
  @State exposureImmersiveVisible: number = 1; // 控制曝光组件沉浸式时的显影
  private immersiveUIType: UIOperationType = UIOperationType.NULL;
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @State rotateAngle: number = 0;
  @State isShowLandscape: boolean = false;
  @State isPreviewFrameStart: boolean = true;
  private isReportDrawnCompleted: boolean = false;
  @State isShowFocus: boolean = false;
  @State focusPosition: PositionType = { x: 0, y: 0 };
  @Prop development: boolean = false;
  // 显示更多功能
  @State isShowMorePage: boolean = false;
  // 前置捏合时是否支持切换变焦
  private frontPinchCanUpdate: boolean = false;
  private readonly pinchToNextZoomScale = 1.25;
  private readonly pinchToPrevZoomScale = 0.75;
  @State cameraSwitchRotation: RotateOptions = {
    y: BlurAnimateUtil.ROTATE_AXIS,
    angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180
  }
  private clearBlurTask: number = -1;
  @State isInBlurAnim: boolean = false;
  private hasShowBlurWhenExit: boolean = false;
  private changeSizeImmediately: boolean = false;
  @State needShowBlackBack: boolean = false;
  @State mModeSwitchImgOpacity: number = 1;
  @State isInModeSwitching: boolean = false;
  @State isCollapsStart: boolean = false;
  @State showAssistGrid: boolean = false;
  @State imgScale: ScaleOptions = { x: 1, y: 1 };
  @State isColdFrameStart: boolean = BlurAnimateUtil.isColdFrameStart;
  @State @Watch('savePowerModeStatusChanged') isDuringSavePowerMode: boolean = false;
  @StorageLink('savePowerModeNeedRestartPreview') savePowerModeNeedRestartPreview: boolean = false;
  private xComponentSizeForAnim: Size = { width: 0, height: 0 }
  @State isShowStageLightEffect: boolean = false;
  private newAnimData: ModeSwitchAnimData = {
    oldWidth: 0,
    oldHeight: 0,
    newWidth: 0,
    newHeight: 0
  };
  @State previewSize: PositionType = { x: 0, y: 0 };
  @Prop newPreviewAnimatePostion: PositionType = { x: 0, y: 0 };
  //对焦框旁边曝光值
  @State isShowBurstCaptureBigText: boolean = false;
  @State windowDirection: number = DisplayService.getInstance().getDisplay().orientation;
  private sourceMode: ModeType = ModeType.NONE;
  @State isShowMotionDetection: boolean = false;
  @StorageLink('isDownSuperSlowBtnState') isDownSuperSlowBtn: boolean = false;
  @StorageLink('showHorizontalLevelView') showHorizontalLevelView: boolean = false;
  @State exposurePosition: PositionType = { x: 0, y: 0 };
  @State exposurePositionX: number = 0;
  @State exposurePositionY: number = 0;
  @StorageLink('isPanGestureDoing') isPanGestureDoing: boolean = false;
  @State moveOffsetX: number = 0;
  @State moveOffsetY: number = 0;
  @State moveOffFocusSetX: number = 0;
  @State moveOffFocusSetY: number = 0;
  @State positionX: number = 0;
  @State positionY: number = 0;
  @State isShowFocusLock: boolean = false;
  @State isFocusLocked: boolean = false;
  @State focusLockImagePath: string = 'app.media.focus_unlock';
  @Prop previewAreaSize: PositionType;
  @StorageLink('isNightShutting') isNightShutting: boolean = false;
  @State isShowNightInfo: boolean = false;
  @State isProShuttering: boolean = false;

  private setEventBusOn(): void {
    this.mEventBus.on(ActionType.ACTION_PREVIEW_SHOT_COMPONENT, this.updateShotComponent.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_CHANGE_TIME_LAPSE, ActionType.ACTION_IS_ENTER_IMMERSIVE],
      this.isEnterImmersive.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_PREVIEW_FRAME_START,
      this.onPreviewFrameStart.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_NIGHT_FRAME_SHUTTER, this.onNightFrameShutter.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_RESET_EXPOSURE_TIME, this.onResetExposureTime.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onAbilityBackground.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND,
      this.onBackGround.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_NIGHT_FRAME_SHUTTER,
      this.onNightFrameShutter.bind(this), this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_CONFIRM_CAPTURE_EFFECT,
      ActionType.ACTION_RESET_EXPOSURE_TIME], this.onConfirmCaptureEffect.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.CLOSE, this.closeCallback.bind(this), this.mBase.hashCode());
    this.mEventBus.on([WindowActionType.ON_SIZE_CHANGE],
      (data: DisplayRotationStruct) => this.displayRotationChange(data), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHANGE_X_COMPONENT_SIZE,
      (data: XComponentSize) => this.onChangeXComponentSize(data), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.startedInitSlowBoxPos.bind(this), this.mBase.hashCode());
    this.dealPicker();
    this.xComponentSizeForAnim = { width: this.xComponentWidth, height: this.xComponentHeight };
    this.mEventBus.on([ActionType.ACTION_NIGHT_CAPTURE_END, CameraActionType.STARTED],
      this.onNightCaptureEnd.bind(this), this.mBase.hashCode());
  }

  aboutToAppear(): void {
    HiLog.i(TAG, 'PreviewArea aboutToAppear.');
    CameraProxy.getInstance().on(WorkerTask.ON_COLLABORATION_FD, (data: CollaborationFdData) => {
    });

    const featureManager: FeatureManager = FeatureManager.getInstance();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        minZoomRatio: state.get<number>('zoomReducer', 'minZoomRatio'),
        maxZoomRatio: state.get<number>('zoomReducer', 'maxZoomRatio'),
        zoomRatio: state.get<number>('zoomReducer', 'zoomRatio'),
        isShowBigText: state.get<boolean>('modeReducer', 'isShowBigText'),
        isShowtimeLapse: state.get<boolean>('settingReducer', 'isShowtimeLapse'),
        isAssGridViewShow: state.get<boolean>('settingReducer', 'isAssGridViewShow'),
        uiEnable: state.get<boolean>('contextReducer', 'uiEnable'),
        videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
        baseZoom: state.get<number>('zoomReducer', 'baseZoom'),
        direction: state.get<WindowDirection>('contextReducer', 'direction'),
        cameraRunningState: state.get<CameraRunningState>('cameraReducer', 'cameraRunningState'),
        isShowNightBigText: state.get<boolean>('modeReducer', 'isShowNightBigText'),
        isForeground: state.get<boolean>('contextReducer', 'isForeground'),
      });
      this.isShowBurstCaptureBigText = state.get<boolean>('modeReducer', 'isShowBurstCaptureBigText');
      this.isDuringSavePowerMode = state.get<boolean>('contextReducer', 'isDuringSavePowerMode');
      this.isHorizontalLevelShow = featureManager.getFunction(FunctionId.HORIZONTAL_LEVEL).getValue();
      if (this.xComponentWidth === 0 || this.xComponentHeight === 0) {
        // 规避previewArea在模糊中销毁重建场景
        this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
        this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
        featureManager.setIsInResolution(false);
        this.isInBlurAnim = false;
      } else if (AppStorage.has('isVisitedByShortCut')) {
        this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
        this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
        AppStorage.delete('isVisitedByShortCut');
      }
      if (featureManager.getIsInResolution()) {
        this.newAnimData = {
          oldWidth: this.xComponentWidth,
          oldHeight: this.xComponentHeight,
          newWidth: state.get<number>('previewReducer', 'xComponentWidth'),
          newHeight: state.get<number>('previewReducer', 'xComponentHeight')
        }
      }
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.isShowMotionDetection = state.get<boolean>('motionReducer', 'isShowMotionBox');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.isShowFocus = state.get<boolean>('focusExposureReducer', 'isShowFocus');
      this.isProShuttering = state.get<boolean>('proShutterReducer', 'isProShuttering');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.setEventBusOn();
    HiLog.i(TAG, 'aboutToAppear end.');
  }

  private onAbilityBackground(data: AbilityBackgroundData): void {
    this.releaseCamera(data);
    this.mAction.updateShowBigTextFlag(false);
  }

  private onResetExposureTime(): void {
    this.mAction.updateShowBigTextFlag(false);
  }

  private onNightFrameShutter(): void {
    this.mAction.updateShowNightBigTextFlag(true);
    this.isShowNightCaptureInfo(true);
  }

  private onBackGround(data: AbilityBackgroundData): void {
    this.mAction.updateShowNightBigTextFlag(false);
    this.mAction.updateShowBurstCaptureBigTextFlag(false);
  }

  private onConfirmCaptureEffect(): void {
    this.mAction.updateShowNightBigTextFlag(false);
  }

  private onNightCaptureEnd(): void {
    this.isShowNightCaptureInfo(false);
  }

  private isShowNightCaptureInfo(showNightInfo: boolean): void {
    HiLog.i(TAG, `isShowNightCaptureInfo : ${showNightInfo}`);
    this.isShowNightInfo = showNightInfo;
  }

  private async showBlurWhenExit(): Promise<void> {
    HiLog.i(TAG, 'showBlurWhenExit');
    this.mScreenshotPixelMap = await BlurAnimateUtil.generateBlurByEffectKit(BlurAnimateUtil.getBlurPixelMap(),
      this.isShowLandscape);
    this.mScreenshotPixelMapAngle = BlurAnimateUtil.getBlurPixelAngle();
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
    } else {
      this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
    }
    if (!this.state.isForeground) {
      this.mModeSwitchImgBlur = 0;
      this.mModeSwitchImgOpacity = 1;
      this.mShowModeSwitchImg = true;
      this.isInBlurAnim = true;
      this.hasShowBlurWhenExit = true;
      this.changeSizeImmediately = true;
    }
  }

  private generateBlurPixelMap(needShow: boolean): void {
    BlurAnimateUtil.generatePixelMapFromSurface();
    if (needShow) {
      this.showBlurWhenExit();
    }
  }

  private closeCallback(): void {
    HiLog.i(TAG, 'Generate pixelMap while closing camera');
    clearTimeout(this.clearBlurTask);
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'previewArea aboutToDisappear called.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  // 省电模式状态变化
  private savePowerModeStatusChanged(): void {
    if (this.isDuringSavePowerMode) {
      HiLog.begin(TAG, 'savePowerModeStatusChanged closeCamera.');
      const mode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
      this.mAction.closeCamera();
      HiLog.end(TAG, 'savePowerModeStatusChanged closeCamera.');
    } else {
      if (MoreModeConfig.getInstance().isSupportMorePage() && !ModeListManager.getInstance().includes(this.mode)) {
        MoreModeConfig.getInstance().modifyMoreModeListAndName(this.mode);
      }
      HiLog.i(TAG, `savePowerModeStatusChanged startPreview loadSurfaceDone: ${this.loadSurfaceDone}`);
      if (this.loadSurfaceDone && this.savePowerModeNeedRestartPreview) {
        HiLog.i(TAG, 'savePowerModeStatusChanged startPreview');
        ZoomOperation.getInstance().setRemainZoomRatio(true);
        this.mAction.startup();
        HiLog.i(TAG, `cameraRunningState: ${this.state.cameraRunningState}`)
      }
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      FocusExposureArea() {
        XComponent({
          id: hebcXcId, // Hardware Direct Connect Preview,禁止变更
          type: XComponentType.SURFACE,
          libraryname: '',
          controller: XComponentService.getInstance().getController()
        } as ESObject)
          .id(PreviewArea.xComponentId)
          .onLoad((): void => {
            HiLog.begin(TAG, 'XComponent_onLoad');
            const surface = XComponentService.getInstance().createSurface();
            HiLog.i(TAG, `load xComponent surface: ${surface}`);
            this.mAction.startupWithDeferredSurface();
            this.loadSurfaceDone = true;
            WindowService.getInstance().lockXComponentSurface();
            HiLog.end(TAG, 'XComponent_onLoad');
          })
          .onDestroy((): void => {
            const surface = XComponentService.getInstance().deleteSurface();
            HiLog.i(TAG, `XComponent_onDestroy, delete surface: ${surface}.`);
          })
          .width(this.xComponentWidth)
          .height(this.xComponentHeight)
          .border({ width: { top: 0.5, bottom: 0.5 }, color: Color.Black })
        // 水平仪
        if (this.isHorizontalLevelShow && (!this.state.isShowBigText ||
          this.state.videoState !== RecordingState.READY) && !this.state.isShowtimeLapse) {
          HorizontalLevelView()
            .opacity(this.immersiveOpacity)
            .transition(TransitionEffect.OPACITY.animation({ duration: DURATION, curve: Curve.Sharp }))
            .visibility(!this.isShowMorePage && this.immersiveOpacity !== 0 && this.showHorizontalLevelView ?
            Visibility.Visible : Visibility.Hidden)

          HorizontalCrucifix()
            .visibility(!this.isShowMorePage && this.immersiveOpacity !== 0 ? Visibility.Visible : Visibility.Hidden)

          HorizontalCrucifix({
            fillColor: MOVABLE_CRUCIFIX_COLOR, shadowRadius: MOVABLE_CRUCIFIX_SHADOW_RADIUS,
            isMovable: true
          })
            .visibility(!this.isShowMorePage && this.immersiveOpacity !== 0 ? Visibility.Visible : Visibility.Hidden)
        }

        if (this.state.isAssGridViewShow && (!this.state.isShowBigText ||
          this.state.videoState !== RecordingState.READY)) {
          AssistiveGridView()
            .hitTestBehavior(HitTestMode.Transparent)
            .position({ x: this.positionZero, y: this.positionZero })
            .visibility(!this.isShowMorePage && this.immersiveOpacity !== 0 || this.state.isShowtimeLapse ?
            Visibility.Visible : Visibility.Hidden)
            .key(ComponentIdKeys.ASSISTIVE_GRID_VIEW)
        }

        if (!this.isPreviewFrameStart) {
          Column()
            .width(this.xComponentWidth)
            .height(this.xComponentHeight)
            .backgroundColor(Color.Black)
            .border({ width: { top: 0.5, bottom: 0.5 }, color: Color.Black })
        }

        if (this.mShowModeSwitchImg && this.mScreenshotPixelMap) {
          Column() {
            Image(this.mScreenshotPixelMap)
              .width(this.xComponentWidth)
              .height(this.xComponentHeight)
              .blur(this.mModeSwitchImgBlur)
              .syncLoad(true)
          }
          .rotate(this.cameraSwitchRotation)
          .scale(this.imgScale)
          .opacity(this.mModeSwitchImgOpacity)
        }
      }

      ShowFlashBlack({ xComponentWidth: this.xComponentWidth, xComponentHeight: this.xComponentHeight })
        .hitTestBehavior(HitTestMode.Transparent)

      if (this.state.isShowNightBigText) {
        Stack({ alignContent: Alignment.Top }) {
          NightTimeBigText()
        }
        .width('100%')
        .height('100%')
        .position(this.getLayoutPosition())
        .touchable(false)
      }

      if (this.isShowBurstCaptureBigText) {
        BurstCaptureBigText()
          .width('100%')
          .height('100%')
          .position(this.getBurstLayoutPosition())
          .touchable(false)
      }

      if (this.state.isShowtimeLapse) {
        TimeLapseView()
          .position(this.isPicker ? undefined : {
            x: this.positionZero,
            y: this.getTimeLapseViewBottom()
          })
      }
    }
    .width(this.xComponentWidth)
    .height(this.xComponentHeight)
    .hitTestBehavior(HitTestMode.Transparent)
    .clip(true)
    .backgroundColor(Color.Black)
    .enabled(!this.isDownSuperSlowBtn)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Move) {
        return;
      }
      if (TouchType.Down === event.type) {
        this.generateBlurPixelMap(false);
        if (event.touches.length === 2) {
          this.touchPrepareZoom();
        }
        return;
      }
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        if (event.touches.length === 2) {
          this.touchUnprepareZoom();
        }
      }
    })
    .gesture(
      GestureGroup(
        GestureMode.Exclusive,
        TapGesture({ fingers: 1, count: 1 })
          .onAction(() => this.onPreviewClicked()),
        PinchGesture({ fingers: 2, distance: 1 })
          .onActionStart((event?: GestureEvent) => {
            if (!event || this.isNightShutting) {
              return;
            }
            return this.pinchGestureStart(event);
          })
          .onActionUpdate((event?: GestureEvent) => {
            if (!event || this.isNightShutting) {
              return;
            }
            return this.pinchGestureUpdate(event);
          })
          .onActionCancel(() => {
            HiLog.i(TAG, 'onActionCancel');
            this.pinchGestureEnd();
          })
          .onActionEnd((event?: GestureEvent) => {
            if (!event || this.isNightShutting) {
              return;
            }
            return this.pinchGestureEnd();
          }),
        PanGesture({
          fingers: 1,
          direction: PanDirection.Up,
          distance: 10
        })
          .onActionStart((): void => {
            if (this.state.uiEnable && !this.state.isShowtimeLapse && this.state.videoState === RecordingState.READY &&
              !this.state.isShowNightBigText && !this.isDownSuperSlowBtn && !this.isShowNightInfo &&
              !this.isProShuttering) {
              this.mAction.swipeChangeMode(1);
            }
          }),
        PanGesture({
          fingers: 1,
          direction: PanDirection.Down,
          distance: 10
        })
          .onActionStart((): void => {
            if (this.state.uiEnable && !this.state.isShowtimeLapse && this.state.videoState === RecordingState.READY &&
              !this.state.isShowNightBigText && !this.isDownSuperSlowBtn && !this.isShowNightInfo &&
              !this.isProShuttering) {
              this.mAction.swipeChangeMode(-1);
            }
          })
      )
    )
  }

  private touchPrepareZoom(): void {
    this.mAction.changeFunctionValue(FunctionId.ZOOM, {
      zoomRatio: undefined,
      isPrepareZoom: true
    } as ZoomFuncValueStruct);
  }

  private touchUnprepareZoom(): void {
    this.mAction.changeFunctionValue(FunctionId.ZOOM, {
      zoomRatio: undefined,
      isUnprepareZoom: true,
      unprepareDelay: ZoomParam.UNPREPARE_DELAY_TIME
    } as ZoomFuncValueStruct);
  }

  public onScaleUpdate(scale: number): void {
    HiLog.i(TAG, `onScaleUpdate called scale = ${scale}.`);
    let tempZoom = 1.0;
    if (scale > 1) {
      tempZoom = this.state.baseZoom + scale - 1;
    } else {
      tempZoom = this.state.baseZoom * scale;
    }
    if (Math.abs(tempZoom - this.state.zoomRatio) >= 0.1) {
      if (tempZoom >= this.state.minZoomRatio && tempZoom <= this.state.maxZoomRatio) {
        this.mAction.changeFunctionValue(FunctionId.ZOOM, {
          zoomRatio: tempZoom,
        } as ZoomFuncValueStruct);
      }
    }
  }

  private dealPicker(): boolean {
    if (!this.isPicker) {
      return false;
    }
    HiLog.i(TAG, 'dealPicker invoke E.');
    let action: string | undefined = '';
    let hasDealPicker: boolean = false;

    if (GlobalContext.get().getCameraAbilityWant() && GlobalContext.get()
      .getCameraAbilityWant()
      .action !== 'action.system.home') {
      action = GlobalContext.get().getCameraAbilityWant().action;
      hasDealPicker = true;
      this.mAction.thirdPartyCall(true, GlobalContext.get().getCameraAbilityWant().action as string);
    } else {
      HiLog.d(TAG, 'not picker.');
      this.mAction.thirdPartyCall(false, '');
      return hasDealPicker;
    }
    HiLog.i(TAG, `action: ${action}.`);
    HiLog.i(TAG, 'dealPicker invoke X.');
    return hasDealPicker;
  }

  private releaseCamera(data: AbilityBackgroundData): void {
    HiLog.i(TAG, 'releaseCamera called.');
    if ((data.isPickerBack && !this.isPicker) || (!data.isPickerBack && this.isPicker)) {
      HiLog.w(TAG, 'releaseCamera Repeated Conflicts');
      return;
    }
    this.generateBlurPixelMap(true);
  }

  private hideBlurAnim(): void {
    if (!BlurAnimateUtil.getValidFrameFlag()) {
      HiLog.w(TAG, 'wait for first frame');
      return;
    }
    if (BlurAnimateUtil.getIsContinuousSwitch()) {
      HiLog.w(TAG, 'Switch timeout.');
      setTimeout(() => {
        this.hideBlurAnim();
      }, BlurAnimateUtil.SWITCH_TIMEOUT);
      BlurAnimateUtil.setIsContinuousSwitch(false);
      return;
    }
    HiLog.begin(TAG, 'hideBlurAnim');
    this.needShowBlackBack = false;
    this.hasShowBlurWhenExit = false;
    BlurAnimateUtil.setHasShowBlurWhenExit(false);
    animateToImmediately({
      duration: BlurAnimateUtil.HIDE_BLUR_DURATION,
      curve: Curve.FastOutSlowIn,
      onFinish: () => {
        HiLog.end(TAG, 'hideBlurAnim');
        if (!BlurAnimateUtil.getValidFrameFlag()) {
          HiLog.i(TAG, 'wait for next start');
          this.mModeSwitchImgOpacity = 1;
        } else {
          HiLog.i(TAG, 'Hide blur img done.');
          this.mShowModeSwitchImg = false;
          this.isInBlurAnim = false;
          BlurAnimateUtil.setInSwitchCamera(false);
          this.isCollapsStart = true;
          this.showAssistGrid = false;
          this.mModeSwitchImgBlur = 0;
          this.changeSizeImmediately = false;
          clearTimeout(this.clearBlurTask);
        }
      }
    }, () => {
      this.mModeSwitchImgOpacity = 0;
    });
  }

  private displayRotationChange(data: DisplayRotationStruct): void {
    this.xComponentWidth = getStates().get<number>('previewReducer', 'xComponentWidth');
    this.xComponentHeight = getStates().get<number>('previewReducer', 'xComponentHeight');
    HiLog.i(TAG, `setPreviewPosition, data: ${WindowService.getInstance().isVertical()}.`);
    this.newPreviewAnimatePostion = {
      x: this.getPreviewXPostion(),
      y: (this.windowHeight - this.xComponentHeight) >> 1
    }
    this.newPreviewAnimatePostion.x = px2vp((Math.floor(vp2px(this.newPreviewAnimatePostion.x)) >> 1) << 1);
    this.newPreviewAnimatePostion.y = px2vp((Math.floor(vp2px(this.newPreviewAnimatePostion.y)) >> 1) << 1);
    this.previewPosition = this.newPreviewAnimatePostion;
    this.initSlowBoxPosition();
  }

  private isPreviewAreaMiddle(xComponentWidth: number): boolean {
    if (WindowService.getInstance().isVertical()) {
      return true;
    }
    return (this.windowWidth - xComponentWidth) / 2 > COMPONENT_WIDTH ? true : false;
  }

  private getPreviewXPostion(): number {
    let aspectRatio = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue() as number;
    let previewAspectRatio =
      aspectRatio === 1 ? (NUM_4 / NUM_3) : (aspectRatio === 2 ? (NUM_1 / NUM_1) : (NUM_16 / NUM_9));
    let xComponentWidthByDisplayCal: number =
      DisplayCalculator.calcSurfaceDisplaySize(previewAspectRatio, this.windowWidth, this.windowHeight).width;
    return this.isPreviewAreaMiddle(xComponentWidthByDisplayCal) ? (this.windowWidth - this.xComponentWidth) >> 1 : 0;
  }

  private onChangeXComponentSize(data: XComponentSize): void {
    HiLog.i(TAG, `onChangeXComponentSize E, data: ${JSON.stringify(data)}.`);
    this.xComponentSizeForAnim = { width: data.xComponentWidth, height: data.xComponentHeight };
    if (this.changeSizeImmediately) {
      this.changePreviewSizeAnim(this.xComponentSizeForAnim);
    }
  }

  private clearBlur(): void {
    HiLog.e(TAG, 'No first frame, clear blur');
    BlurAnimateUtil.setValidFrameFlag(true);
    this.hideBlurAnim();
  }

  private updateBlurTask(): void {
    clearTimeout(this.clearBlurTask);
    this.clearBlurTask = setTimeout(() => {
      this.clearBlur();
    }, FIRST_FRAME_TIMEOUT);
  }

  private showBlurAnim(animData?: ModeSwitchAnimData): void {
    if (BlurAnimateUtil.getHasShowBlurWhenExit()) {
      this.hasShowBlurWhenExit = true;
      this.changeSizeImmediately = true;
    }
    if (this.isInBlurAnim) {
      BlurAnimateUtil.setIsContinuousSwitch(true);
      BlurAnimateUtil.setValidFrameFlag(false);
      HiLog.w(TAG, 'Restart preview too quick, then intercept blur and size animation.');
      this.mModeSwitchImgBlur = AnimSpecifications.ANIM_MODE_SWITCH_BLUR;
      this.mModeSwitchImgOpacity = 1;
      this.changeSizeImmediately = true;
      this.changePreviewSizeAnim(this.xComponentSizeForAnim);
      FeatureManager.getInstance().setIsInResolution(false);
      return;
    }
    this.isInBlurAnim = true;
    this.mModeSwitchImgBlur = CameraAppCapability.getInstance().getIsNeedFixedBlurRadius() ? 80 : 0;
    this.mModeSwitchImgOpacity = 1;
    this.mShowModeSwitchImg = true;
    this.prepareBlurImage();
    animateToImmediately(
      {
        duration: BlurAnimateUtil.SHOW_BLUR_DURATION,
        curve: Curve.Friction,
        onFinish: async () => {
          this.isInModeSwitching = false;
          this.mScreenshotPixelMapAngle = BlurAnimateUtil.getBlurPixelAngle();
          const cameraPosition: camera.CameraPosition = BlurAnimateUtil.getCameraPosition();
          if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
            this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
          } else {
            this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
          }
          this.mModeSwitchImgBlur = 0;
          FeatureManager.getInstance().setIsInResolution(false);
          if (animData) {
            this.changePreviewSizeAnim(this.xComponentSizeForAnim);
          }
        }
      },
      () => {
        this.mModeSwitchImgBlur = AnimSpecifications.ANIM_MODE_SWITCH_BLUR; // 蒙层从清晰到模糊
      }
    );
  }

  private prepareBlurImage(): void {
    this.mScreenshotPixelMap = BlurAnimateUtil.getBlurPixelMap();
    this.mScreenshotPixelMapAngle = BlurAnimateUtil.getBlurPixelAngle();
    const cameraPosition: camera.CameraPosition = BlurAnimateUtil.getCameraPosition();
    if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
    } else {
      this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
    }
  }

  private changePreviewSizeAnim(newSize: Size) {
    animateToImmediately({
      duration: BlurAnimateUtil.CHANGE_PREVIEW_DURATION,
      curve: Curve.Friction,
      onFinish: () => {
      }
    }, () => {
      this.xComponentWidth = newSize.width;
      this.xComponentHeight = newSize.height;
      this.newPreviewAnimatePostion.x = px2vp((Math.floor(vp2px(this.newPreviewAnimatePostion.x)) >> 1) << 1);
      this.newPreviewAnimatePostion.y = px2vp((Math.floor(vp2px(this.newPreviewAnimatePostion.y)) >> 1) << 1);
      this.previewPosition = this.newPreviewAnimatePostion;
    });
  }

  private async updateShotComponent(data: ShotComponentData): Promise<void> {
    HiLog.begin(TAG, 'updateShotComponent.');
    HiLog.d(TAG, `old: ${data.oldMode} new: ${data.newMode}.`);
    this.sourceMode = data.oldMode;
    // 受组件截图时长影响，提前切换流操作,出预览流时间早，动效开始前黑屏
    // 获取新模式预览流宽高
    const xComponentSizeOld = CameraBasicService.getInstance().getPreviewDisplaySize(data.oldMode);
    const xComponentSizeNew = CameraBasicService.getInstance().getPreviewDisplaySize(data.newMode);
    let animData: ModeSwitchAnimData = {
      oldWidth: xComponentSizeOld.width,
      newWidth: xComponentSizeNew.width,
      oldHeight: xComponentSizeOld.height,
      newHeight: xComponentSizeNew.height,
    };
    this.mAction.changeXComponentSize(animData.newWidth, animData.newHeight);
    animData = {
      oldWidth: xComponentSizeOld.width + XCOMPONENTWIDTH_OFFSETS,
      newWidth: xComponentSizeNew.width + XCOMPONENTWIDTH_OFFSETS,
      oldHeight: xComponentSizeOld.height + XCOMPONENTHEIGHT_OFFSETS,
      newHeight: xComponentSizeNew.height + XCOMPONENTHEIGHT_OFFSETS,
    };
    HiLog.end(TAG, 'updateShotComponent.');
    const modeChangeAvoidShowBT: boolean = data.isShowBigText; // 默认热启动，设置页恢复默认值，不展示大字体
    if (modeChangeAvoidShowBT) {
      this.mAction.updateShowBigTextFlag(true); //模式切换的大字体展示在这
    }
  }

  private rotateScaleAnim(): void {
    animateToImmediately(
      {
        duration: BlurAnimateUtil.ROTATION_DURATION,
        curve: Curve.Sharp,
        onFinish: () => {
        }
      },
      () => {
        this.imgScale = { x: 1, y: 1 };
      }
    )
  }

  private async rotateFlipAnim(): Promise<void> {
    this.mScreenshotPixelMap = await BlurAnimateUtil.generateBlurByEffectKit(BlurAnimateUtil.getBlurPixelMap(),
      this.isShowLandscape);
    this.mScreenshotPixelMapAngle = BlurAnimateUtil.getBlurPixelAngle();
    this.mModeSwitchImgBlur = 0;
    const cameraPosition: camera.CameraPosition = BlurAnimateUtil.getCameraPosition();
    if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_ROTATE_ANGLE_90 };
    } else {
      this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_MINUS_90 };
    }

    animateToImmediately(
      {
        duration: BlurAnimateUtil.ROTATION_DURATION,
        curve: curves.cubicBezierCurve(0.17, 0.00, 0.20, 1.00),
        onFinish: () => {
        }
      },
      () => {
        if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
          this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
        } else {
          this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
        }
      }
    )
  }

  private rotatePreviewAnim(): void {
    this.mModeSwitchImgOpacity = 1;
    this.mShowModeSwitchImg = true;
    this.isInBlurAnim = true;
    const cameraPosition: camera.CameraPosition = BlurAnimateUtil.getCameraPosition();
    if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
    } else {
      this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
    }

    animateToImmediately(
      {
        duration: BlurAnimateUtil.ROTATION_DURATION,
        curve: Curve.Sharp,
        onFinish: () => {
          this.rotateScaleAnim();
        }
      },
      () => {
        this.mModeSwitchImgBlur = AnimSpecifications.ANIM_MODE_SWITCH_BLUR;
        this.imgScale = { x: BlurAnimateUtil.IMG_SCALE, y: BlurAnimateUtil.IMG_SCALE };
      }
    );

    animateToImmediately(
      {
        duration: BlurAnimateUtil.ROTATION_DURATION,
        delay: BlurAnimateUtil.FLIP_DELAY,
        curve: curves.cubicBezierCurve(0.20, 0.00, 0.83, 1.00),
        onFinish: () => {
          this.rotateFlipAnim();
        }
      },
      () => {
        if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
          this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_ROTATE_ANGLE_270 };
        } else {
          this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_ROTATE_ANGLE_90 };
        }
      }
    )
  }

  private async cameraSwitchAnim(): Promise<void> {
    if (this.isInBlurAnim) {
      FeatureManager.getInstance().setIsInResolution(false);
      this.updateBlurTask();
      this.changeSizeImmediately = true;
      this.mModeSwitchImgBlur = AnimSpecifications.ANIM_MODE_SWITCH_BLUR;
      this.mModeSwitchImgOpacity = 1;
      return;
    }
    this.mScreenshotPixelMap = BlurAnimateUtil.getBlurPixelMap();
    this.mScreenshotPixelMapAngle = BlurAnimateUtil.getBlurPixelAngle();
    this.rotatePreviewAnim();
  }

  private pinchGestureStart(event: GestureEvent): void {
    HiLog.i(TAG, 'pinchGestureStart E.');
    let photoFormat: PhotoFormatMode = FeatureManager.getInstance().getFunction(FunctionId.PHOTO_FORMAT).getValue();
    if (this.state.isShowBigText || this.state.isShowtimeLapse ||
      this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      return;
    }

    this.mAction.isEnterImmersive(true);
    this.mAction.updateShowPinch(true);
    this.baseZoom = this.state.zoomRatio;
    this.frontPinchCanUpdate = true;
    HiLog.i(TAG, 'pinchGestureStart X.');
  }

  private pinchGestureUpdate(event: GestureEvent): void {
    HiLog.i(TAG, 'pinchGestureUpdate invoke, setZoomRatio.');
    let photoFormat: PhotoFormatMode = FeatureManager.getInstance().getFunction(FunctionId.PHOTO_FORMAT).getValue();
    if (this.state.isShowBigText || this.state.isShowtimeLapse) {
      return;
    }
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      if (!this.frontPinchCanUpdate) {
        return;
      }
      if (event.scale >= this.pinchToNextZoomScale) {
        this.frontPinchCanUpdate = false;
        this.mAction.switchZoomRatio(true);
      }
      if (event.scale <= this.pinchToPrevZoomScale) {
        this.frontPinchCanUpdate = false;
        this.mAction.switchZoomRatio(false);
      }
      return;
    }

    let zoomRatio = event.scale * this.baseZoom;
    if (zoomRatio > this.state.maxZoomRatio) {
      zoomRatio = this.state.maxZoomRatio;
    }
    if (zoomRatio < this.state.minZoomRatio) {
      zoomRatio = this.state.minZoomRatio;
    }
    zoomRatio = Number.parseFloat(zoomRatio.toFixed(3));
    if (zoomRatio !== this.state.zoomRatio) {
      this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: zoomRatio } as ZoomFuncValueStruct);
    }
    let preZoomRatio = this.state.zoomRatio.toFixed(1);
    let curZoomRatio = zoomRatio.toFixed(1);
    if ((curZoomRatio !== preZoomRatio) && (this.state.videoState === RecordingState.READY)) {
      VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
    }
    HiLog.i(TAG, 'pinchGestureUpdate end.');
  }

  private pinchGestureEnd(): void {
    HiLog.i(TAG, 'pinchGestureEnd E.');
    let photoFormat: PhotoFormatMode = FeatureManager.getInstance().getFunction(FunctionId.PHOTO_FORMAT).getValue();
    if (this.state.isShowBigText || this.state.isShowtimeLapse ||
      this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      return;
    }
    this.mAction.isEnterImmersive(false);
    this.mAction.updateShowPinch(false);
    HiLog.i(TAG, 'pinchGestureEnd X.');
  }

  private onPreviewClicked(): void {
    HiLog.i(TAG, 'Click preview called.');
    HiLog.i(TAG, `Click preview isShowtimeLapse= ${this.state.isShowtimeLapse}.`);
    HiLog.i(TAG, `Click preview state.mode= ${this.mode}.`);
    if (OutputOperation.isPanPhotoOutput(this.mode) && this.state.isShowtimeLapse) {
      this.mAction.changeTimeLapse(false);
      this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
      this.mAction.capture();
      this.mAction.changeFunctionValue(FunctionId.CAPTURE, true);
    } else if (OutputOperation.isPanVideoOutput(this.mode) && this.state.isShowtimeLapse) {
      this.mAction.changeTimeLapse(false);
      this.mAction.startVideoAnim();
      this.mAction.startRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, 0);
    }
  }

  private isEnterImmersive(data: EnterImmersiveStruct): void {

    let json: EnterImmersiveStruct = JSON.parse(JSON.stringify(data));
    let mIsImmersive: boolean = json?.isShowtimeLapse ?? json?.isImmersive ?? false;
    HiLog.i(TAG, `isEnterImmersive json: ${JSON.stringify(data)}.`);

    if (mIsImmersive) {
      this.immersiveOpacity = 1;
    } else {
      this.immersiveOpacity = 0;
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_150,
        curve: Curve.Sharp,
      }, () => {
        this.immersiveOpacity = 1;
      });
    }
  }

  private onPreviewFrameStart(data: PreviewFrameStartData): void {
    HiLog.i(TAG, `onPreviewFrameStart ${JSON.stringify(data)}.` + this.isInBlurAnim + '-' + !this.isCollapsStart + '=' +
      !this.isColdFrameStart);
    this.isPreviewFrameStart = data.isPreviewFrameStart;
    if (data.isPreviewFrameStart) {
      HiLog.i(TAG,
        `onPreviewFrameStart --` + this.isInBlurAnim + '-' + !this.isCollapsStart + '=' + !this.isColdFrameStart);
      if (!this.isColdFrameStart) {
        this.isColdFrameStart = true;
        BlurAnimateUtil.isColdFrameStart = true;
        this.isCollapsStart = true;
        this.isInBlurAnim = false;
      } else {
        if (this.isInBlurAnim || !this.isCollapsStart) {
          this.hideBlurAnim();
        }
      }
    } else {
      HiLog.i(TAG, `onPreviewFrameStart ==` + BlurAnimateUtil.getIsInSwitchCamera() + '-' + !this.hasShowBlurWhenExit +
      this.isInBlurAnim);
      this.updateBlurTask();
      if (BlurAnimateUtil.getIsInSwitchCamera()) {
        this.needShowBlackBack = true;
        this.cameraSwitchAnim();
      } else if (!this.hasShowBlurWhenExit) {
        this.showBlurAnim(this.newAnimData);
      }
    }
  }

  public getLayoutPosition(): PositionType {
    const xComponentSize = DisplayCalculator.calcSurfaceDisplaySize(4 / 3);
    const width = (xComponentSize.height / LAYOUT_NUM - this.bigTextHeight / LAYOUT_NUM) +
    this.previewPositionDefaultConst;
    return { x: 0, y: width };
  }

  public getBurstLayoutPosition(): PositionType {
    const xComponentSize = DisplayCalculator.calcSurfaceDisplaySize(4 / 3);
    const width = (xComponentSize.height / LAYOUT_NUM - BURST_BIG_TEXT_LINE_HEIGHT / LAYOUT_NUM)
    return { x: 0, y: width };
  }

  private getTimeLapseViewBottom(): number {
    return this.timeLapseBottom;
  }

  private startedInitSlowBoxPos(data: CameraStartTypeStruct): void {
    if (data && data.type === CameraStartType.COLD_START) {
      this.initSlowBoxPosition();
    }
  }

  // 初始化侦测框位置的事件绑定在父组件上，先初始化好位置在渲染侦测框组件
  private initSlowBoxPosition(size?: Size): void {
  }
}