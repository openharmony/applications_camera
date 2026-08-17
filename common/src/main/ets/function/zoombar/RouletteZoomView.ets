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

import lazy { ZoomNodeController } from './ZoomNodeController';
import curves from '@ohos.curves';
import animator, { AnimatorOptions, AnimatorResult } from '@ohos.animator';
import lazy { ZoomParam, ZoomPointInfo } from './ZoomParam';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { Dispatch, OhCombinedState, Unsubscribe, getStates, reduxSubscribe } from '../../redux';
import lazy { ActionData } from '../../redux/actions/Action';
import lazy { ZoomAction } from './ZoomAction';
import lazy { VibratorService } from '../../component/vibration/VibratorService';
import camera from '@ohos.multimedia.camera';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { RecordingState } from '../recordcontrol/RecordAction';
import lazy { CameraRunningState, CameraStartType, CameraStartTypeStruct } from '../../camera/uithread/CameraAction';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { CameraBasicService } from '../../camera/uithread/CameraBasicService';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { SavePowerModeActionData, XComponentSize } from '../../utils/types';
import lazy { ZoomInnerStatus, ZoomOuterStatus, ZoomStateType } from './ZoomStateType';
import lazy { ZoomOperation, ZoomScaleStruct } from './ZoomOperation';
import lazy { ChangeState } from '../../redux/Store';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { EntryExitAnimParam } from 'appnative/Index';
import lazy { PhotoFormatMode } from '../enumbase/PhotoFormatMode';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { OutputType } from '../outputswitcher/OutputType';
import lazy { CameraProxy } from '../../camera/uithread/CameraProxy';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { JSON } from '@kit.ArkTS';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { AdaptiveLayoutService, ZOOM_VIEW_HEIGHT } from '../../service/UIAdaptive/AdaptiveLayoutService';
import lazy {
  EnableData, RouletteZoomState, ZoomFuncValueStruct, ZoomViewDispatcher
} from './ZoomStruct';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { OutputSwitcher } from '../outputswitcher/OutputSwitcher';
import ResGetter from '../../utils/ResGetter';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import lazy { TipService } from '../../component/tip/TipService';
import lazy { AccessibilityUtils } from '../../utils/AccessibilityUtils';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { UIOperationType } from '../../component/uicomponent/UIOperationType';
import lazy { KeyCode } from '@ohos.multimodalInput.keyCode';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import lazy { PickerWindowType } from '../../component/picker/PickerWindowType';
import lazy { OutputOperation } from '../outputswitcher/OutputOperation';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { SelfieStickKey } from '../../service/selfieStick/SelfieStickService';
import lottie, { AnimationItem } from '@ohos/lottie';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';
import lazy { CaptureActionType } from '../../redux/actions/CaptureActionType';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { ZoomActionType } from '../../redux/actions/ZoomActionType';
import lazy { FunctionActionType } from '../../redux/actions/FunctionActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { WindowActionType } from '../../redux/actions/WindowActionType';
import lazy { CollaborateControlActionType } from '../../redux/actions/CollaborateControlActionType';
import lazy { window } from '@kit.ArkUI';
import lazy { SystemLanguageUtil } from '../../utils/SystemLanguageUtil';
import lazy { QUICK_ZOOM_MARGIN_BOTTOM_28 } from '../../service/UIAdaptive/AdaptiveLandscapeLayoutService';
import lazy { BlurAnimateUtil } from '../../utils/BlurAnimateUtil';
import lazy { ZOOM_STEP } from '../../service/collaborateControl/CollaborateControlAction'

/* instrument ignore file */
const VIBRATOR_USAGE_PHYSIC = 'physicalFeedback';
const WAIT_TIME: number = 400;

export const QUICK_ZOOM_ITEM_SIZE: number = 32;

export const QUICK_ZOOM_POSITION_Y: number = 4;

const EPSILON: number = 0.1;
const FOCAL_ZOOM_EPSILON: number = 0.01;
const POINT_ZOOM: number = 1.5;
const POINT_ZOOM_EQUIVALENT_FOCAL: number = 35;
const TAG: string = 'RouletteZoomView';
const QUICK_ZOOM_MARGIN_LR_LONG: number = 34;
const QUICK_ZOOM_MARGIN_LR_SHORT: number = 16;
const selfieStickLongPressCount: number = 30; // 长按自拍杆，一秒内焦距变化的次数
const selfieStickLongPressZoom: number = 1.018; // 长按自拍杆，焦距一次的变化率，与之前一致
const setOnceSelfieStickZoom: number = 0.1; // 短按自拍杆一次，焦距的变化率，与之前一致
const SET_SELFIE_STICK_ZOOM_NUM: number = 10;
const COLORFUL_ZOOM_RING_CANVAS_PATH: string = 'common/lottie/colorful_zoom_ring.json';
const COLORFUL_ZOOM_RING_ANIM_NAME: string = 'colorfulZoomRing';
const INDICATOR_HEIGHT: number = 32;
const DISTANCE_INDICATOR_FOOTBAR: number = 4;
const ZOOM_CUSTOM_FILTER_VERTICAL_OFFSET: number = -160;
const DRAW_HEIGHT_COEFFICIENT: number = 0.16;

class LockedData {
  public isLocked: boolean = false;
}

/*
 * 快捷变焦点、轮盘变焦方案; UI布局、动效操作类;
 * */
@Component
export struct RouletteZoomView {
  private mBase: BaseComponent = new BaseComponent();
  @State state: RouletteZoomState = new RouletteZoomState();
  private mAction: ZoomViewDispatcher = new ZoomViewDispatcher();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State @Watch('changeRotateAngle') rotateAngleWatch: number = 0;
  @State rotateAngle: number = 0;
  @State windowHeight: number = 0;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  // 变焦公共层变量
  @State curZoomValue: number = 1.0; // 当前变焦值
  @State isShowQuickZoom: boolean = true; // 是否显示快捷变焦点
  @State isShowRouletteZoom: boolean = false; // 是否显示轮盘变焦条
  @State isShowBigText: boolean = false; // 是否显示变焦大字体
  @State quickZoomValArr: number[] = []; // 快捷变焦点对应值列表,产品配置项
  @State @Watch('changeQuickZoomArr') quickZoomValArrLengthWatch: number = 0;
  @State quickZoomValArrLength: number = 0;
  @State isDepthFusionBarShow: boolean = false;
  @State isStitchingTypeBarShow: boolean = false;
  private isDepthFusionConflictLongPress: boolean = false;
  private oldQuickZoomArrLength: number = 0;
  @State opticalZoomValArr: number[] = []; // 轮盘变焦条光学变焦点对应值列表,产品配置项
  @State @Watch('watchZoomInnerStatus') mZoomInnerStatus: ZoomInnerStatus = ZoomInnerStatus.QUICK_STATIC; // 变焦内部状态
  private isExecAdsorptionType: number = 0; // 滑动变焦生命周期内,关键刻度吸附逃逸类型,1、2滑入滑出动效,5吸附暂态,0其它
  private mExecAdsorptionTimerId: number = Number.MAX_VALUE; // 关键刻度吸附停留计时器
  private mFrameAnimResultArr: AnimatorResult[] | null[] =
    [null, null, null, null, null, null, null, null, null, null, null, null, null]; // 变焦帧回调动效发生器
  // QuickZoom快捷变焦变量
  @State curValIndex: number = 0; // 快捷变焦点对应当前index
  private quickEquivalentFocalArr: number[] = []; // 快捷变焦点对应等效焦距
  @State mQuickOtherAlpha: number = 1; // 快捷变焦-其他透明度
  @State mQuickZoomBlur: number = 0; // 快捷变焦整体模糊
  @State mQuickZoomPositionY: number = 0; // 快捷变焦整体位移
  @State quickZoomScale: number = 1; // 快捷变焦-选中圆整体收缩比例
  @State quickZoomAlpha: number = 1; // 快捷变焦-选中圆透明度
  @State mQuickZoomOverColor: number = 0; // 快捷变焦整体叠加颜色
  @State superMacroEnable: boolean = false; // 超级微距特性是否使能状态
  // RouletteZoom轮盘变焦变量
  private curZoomAngle: number = 0; // 当前焦距对应角度
  private mNodeController: ZoomNodeController | undefined = undefined;
  private opticalZoomDotIndexArr: number[] = []; // 光学变焦点所在的index
  private opticalZoomDotAngleArr: number[] = []; // 光学变焦点所在的angle
  private smallScaleDotAngleArr: number[] = []; // 仅变焦精细小刻度点(非光学变焦点)所在的angle
  private lastGestureOffset: number = 0; // 滑动last位置记录
  private lastSlideTouchRadian: number = 0; // 滑动last触摸弧度记录
  private rouletteZoomTimerId: number = Number.MIN_VALUE; // 轮盘变焦定时器Id
  @State longCurveHaloMatteScale?: number = 1; // 光晕动效参数
  @State longCurveHaloOpacity?: number = 1;
  @State spherePosition?: number = 0; // 光球参数
  @State sphereScale?: number = 1;
  @State sphereColor?: number = 0;
  @State sphereHaloOpacity?: number = 1; // 光球光晕参数
  @State redLineAndTextOpacity?: number = 1; // 焦圈中心刻度参数
  @State scaleAllMatteScale?: number = 1; // 焦圈参数
  @State scaleAllOpacity?: number = 1;
  @State carmenLineMatteScale?: number = 1; // 卡门线参数
  @State carmenLineOpacity?: number = 1;
  private mStateChangeAnimator: AnimatorResult | null = null; // native变焦帧回调动效下发执行器
  private redLineTopY: number = 0; // 红线顶部positionY
  private redLineTopRadius: number = 0; // 红线顶部outer圆半径
  // 变焦大字体变量
  @State bigTextZoomValue: number = 1.0; // 变焦大字体变焦值
  private bigTextTimerId: number = Number.MIN_VALUE; // 变焦大字体定时器Id
  @State bigTextPositionY: number = 0; // 变焦大字体Y位置
  @State bigTextScale: number = 1; // 变焦大字体收缩比例
  @State bigTextOpacity: number = 1; // 变焦大字体透明度
  // 变焦多端适配方案
  @State zoomWidth: number = 0;
  private zoomHeight: number = 0;
  private drawHeight: number = 0;
  @State @Watch('onDirectionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State @Watch('updateDensity') density: number = 1 //DisplayService.getInstance().getDisplay().densityPixels;
  @State isShowSubScreenRadius: boolean = false;
  @State isHalfCollapsLEM: boolean = false;
  private isSecurityCameraLast = false;
  private quickZoomArray: number[] = [0.67, 0.8, 1];
  private zoomScaleStruct: ZoomScaleStruct = new ZoomScaleStruct();
  @State isShowSemiCollapsed: boolean = false;
  @State isShowLandscape: boolean = false;
  @State pickerWindowType: PickerWindowType = PickerWindowType.COLLAPSED_VERTICAL_FULL;
  @Prop landscapeZoomWidth: number = 0;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @StorageLink('isBackground') @Watch('stateChange') isBackground: boolean = false;
  @State isShowTricollaps: boolean = false;
  @State isVdeLandscape: boolean = false;
  private isSavePowerMode: boolean = false;
  private quickZoomTimerId: number = Number.MIN_VALUE;
  private selfieStickZoomTimerId: number = Number.MIN_VALUE;
  private setSelfieStickZoom: boolean = true;
  private isSelfieStickLongPress: boolean = false;
  private isSelfieStickShortPress: boolean = false;
  private selfieStickLongPressTimer: number = 0;
  private selfieStickShortPressTimer: number = 0;
  private setSelfieStickZoomTimerId: number = Number.MIN_VALUE;
  private isSetSelfieStickZoom: boolean = true;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false; // 浏览模式是否开启
  // AI 构图彩色圆环
  private antiAliasingSetting: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.antiAliasingSetting);
  private animationItem: AnimationItem | undefined = undefined;
  @StorageLink('isShowColorfulZoomRing') isShowColorfulZoomRing: boolean = false;
  private isNeedVibratorWhenShowColorfulZoomRing: boolean = false;
  @State colorfulZoomRingOpacity: number = 0;
  @Prop @Watch('changeZoomWithCustomImmersive') isCustomFilterImmersive: boolean;
  @Prop layoutService: AdaptiveLayoutService = AdaptiveLayoutService.getInstance();
  @Prop currentFootBarLocation: number = 0;
  @StorageLink('onCustomFilterTopLineChange') customFilterTopLineHeight: number = 0;
  @Prop zoomLocation: number = 0;
  @StorageLink('treasureBoxSelector') selector: FunctionId = FunctionId.NONE;
  private panGestureZoomVelocity: number = CameraAppCapability.getInstance().getPanGestureZoomVelocity() ?? 1;
  @Prop isHdr: boolean = false;
  @State zoomIsHide: boolean = false;
  @State zoomOpacity: number = 1;
  @State mQuickOffsetY: number = 0;
  private zoomPosAnimator: AnimatorResult | null = null;
  @State isShowColumnDivisionLayout: boolean = false;
  @State isShowCycleClickZoom: boolean = false; // 是否显示快捷变焦点上面的等效焦距
  private cycleZoomData: number[] = []; // 当前快捷变焦点的循环点切数组
  private cycleClickTimerId: number = Number.MIN_VALUE; // 等效焦距变焦大字体定时器Id
  @State isDuringCycleClick: boolean = false; // 是否在循环点切的过程中
  private zoomFunction = FeatureManager.getInstance().getFunction(FunctionId.ZOOM);
  private isSupportSelfieStick = true;

  private watchZoomInnerStatus(): void {
    HiLog.i(TAG, `watchZoomInnerStatus: ${this.mZoomInnerStatus}.`);
  }

  aboutToAppear() {
    HiLog.i(TAG, `aboutToAppear`);
    this.rotateAngle = getStates().get<number>('contextReducer', 'rotateAngle');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<RouletteZoomState>) => {
      changeState(this.state, {
        isShowDefault: state.get<boolean>('collapsReducer', 'isShowDefault'),
        isShowSemiCollapsed: state.get<boolean>('collapsReducer', 'isShowSemiCollapsed'),
        xComponentWidth: state.get<number>('previewReducer', 'xComponentWidth'),
        xComponentHeight: state.get<number>('previewReducer', 'xComponentHeight'),
        mode: state.get<ModeType>('modeReducer', 'mode'),
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        isShowPinch: state.get<boolean>('zoomReducer', 'isShowPinch'),
        isShowZoomView: state.get<boolean>('zoomReducer', 'isShowZoomView'),
        isShowZoomText: state.get<boolean>('zoomReducer', 'isShowZoomText'),
        minZoomRatio: state.get<number>('zoomReducer', 'minZoomRatio'),
        maxZoomRatio: state.get<number>('zoomReducer', 'maxZoomRatio'),
        zoomRatio: state.get<number>('zoomReducer', 'zoomRatio'),
        recordingState: state.get<RecordingState>('recordReducer', 'recordingState'),
        zoomState: state.get<string>('zoomReducer', 'zoomState'),
        isImmersive: state.get<boolean>('uiReducer', 'isImmersive'),
        uiEnable: state.get<boolean>('contextReducer', 'uiEnable'),
        cameraRunningState: state.get<CameraRunningState>('cameraReducer', 'cameraRunningState'),
        mainTrigCompo: state.get<UIOperationType>('uiReducer', 'mainTrigCompo'),
        isShowLowAngleShotView: state.get<boolean>('collapsReducer', 'isShowLowAngleShotView'),
        tabSelector: state.get<FunctionId>('tabBarReducer', 'tabBarSelector'),
      });
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.rotateAngleWatch = state.get<number>('contextReducer', 'rotateAngle');
      this.density = state.get<number>('collapsReducer', 'density');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.pickerWindowType = state.get<PickerWindowType>('windowReducer', 'pickerWindowType');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.mNodeController = new ZoomNodeController(this.zoomWidth, this.zoomHeight, this.drawHeight,
      (this.state.isShowDefault && DeviceInfo.isPhone()) ? 0 : 1);
    let redLineTopHeight = this.drawHeight;
    this.redLineTopY = 150 - redLineTopHeight;
    this.redLineTopRadius = (this.zoomWidth * this.zoomWidth / 4 +
      redLineTopHeight * redLineTopHeight) / (2 * redLineTopHeight);
    this.initZoomViewUIData(this.getDefaultZoomRatio());
    this.isShowQuickZoom = true;
    this.isShowRouletteZoom = false;
    this.quickZoomArray = CameraAppCapability.getInstance()
      .getQuickZoomArray(this.state.cameraPosition, this.state.mode, OutputSwitcher.getInstance().getOutput());
    if (this.state.zoomState !== ZoomStateType.QUICK_ZOOM) {
      this.mAction.changeZoomState(ZoomStateType.QUICK_ZOOM);
    }
    this.registerListening(); // 注册事件监听回调
    this.quickZoomValArrLength = this.getRoulette2QuickOrUpdateZoomArrayLength();
    this.quickZoomValArrLengthWatch = this.quickZoomValArrLength;
    this.roulette2QuickAnimOrUpdateZoomArrayExecAnim(false);
    if (this.state.cameraRunningState === CameraRunningState.STARTED) { // 规避组件加载晚于启流完成时间
      this.onCameraActionStarted({ type: CameraStartType.COLD_START });
    }
    this.onChangeXComponentSize({
      xComponentWidth: this.state.xComponentWidth,
      xComponentHeight: this.state.xComponentHeight
    });
    this.changeZoomWithCustomImmersive();
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  private onDirectionChange(): void {
    HiLog.i(TAG, `onDirectionChange mDirection: ${this.mDirection}`);
    this.mNodeController?.updateDirection(this.getZoomSelfDirectRotateAngle());
    return;
  }

  private changeQuickZoomArr(): void {
    let isZoomViewCreated: boolean = ZoomOperation.getInstance().isZoomViewCreated;
    HiLog.i(TAG, `isZoomViewCreated: ${isZoomViewCreated}`);
    HiLog.i(TAG, `quickLength: ${this.quickZoomValArrLength}, quickLengthWatch: ${this.quickZoomValArrLengthWatch}`);
    if (!isZoomViewCreated || this.quickZoomValArrLength === this.quickZoomValArrLengthWatch) {
      return;
    }
    animateToImmediately({
      duration: 300,
      curve: Curve.Friction,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
        HiLog.i(TAG, 'animation onFinish');
      }
    }, () => {
      this.quickZoomValArrLength = this.quickZoomValArrLengthWatch;
      if (CameraAppCapability.getInstance().getIsSupportedCycleClickZoom()) {
        this.doCycleClickZoomAnim(false);
        this.isDuringCycleClick = false;
      }
    })
  }

  /**
   * 初始化ZoomUI状态及data
   * */
  private initZoomViewUIData(mZoomRatio: number): void {
    HiLog.i(TAG,
      `initZoomViewUIData oldZoomValue: ${this.curZoomValue}, mZoomRatio: ${mZoomRatio}, quickZoomValArr: ${this.quickZoomValArr}.`);
    let mCurrentZoom: number = Number(mZoomRatio.toFixed(3));
    if ((this.quickZoomValArr && mCurrentZoom < this.quickZoomValArr[0]) ||
      (this.opticalZoomValArr && mCurrentZoom > this.opticalZoomValArr[this.opticalZoomValArr.length - 1])) {
      mCurrentZoom = this.getDefaultZoomRatio();
    }
    if (this.quickZoomValArr.length > 0 && mCurrentZoom < this.quickZoomValArr[0]) {
      mCurrentZoom = this.quickZoomValArr[0];
    }
    this.curZoomValue = mCurrentZoom;
    this.curValIndex = this.calZoomValIndex(this.curZoomValue);
    this.bigTextZoomValue = this.curZoomValue;
  }

  /**
   * 注册事件监听回调
   * */
  private registerListening(): void {
    // 响应变焦数据及UI状态重置操作
    this.mEventBus.on([ActionType.ACTION_PREVIEW_CLICKED, CaptureActionType.CAPTURE, RecordActionType.START,
      ActionType.ACTION_NIGHT_CAPTURE_START, ContextActionType.CHANGE_WINDOW_EVENT_TYPE],
      this.responsePreviewClick.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ZoomActionType.ACTION_CHANGE_ZOOM_RATIO,
      this.handleZoomRatioChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM,
      this.onSetFunctionConflict.bind(this), this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_IS_ENTER_IMMERSIVE, ActionType.ACTION_PHOTO_BROWSER_ON_BACK_PRESS],
      (data: ActionData) => this.initDepthFusionState(), this.mBase.hashCode());
    // 响应捏合变焦处理
    this.mEventBus.on(ZoomActionType.ACTION_SWITCH_ZOOM_RATIO, this.onSwitchZoomRatio.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, this.pinchUpdateZoomAndVibrator.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ZoomActionType.ACTION_UPDATE_SHOW_PINCH, this.pinchResetZoomAndBigText.bind(this),
      this.mBase.hashCode());

    // 设置焦距保持
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForegroundCallback.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([ContextActionType.ABILITY_ON_BACKGROUND, ContextActionType.SCREEN_LOCKED_STATE],
      this.onBackgroundCallback.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.SCREEN_LOCKED_STATE, this.cameraLocked.bind(this), this.mBase.hashCode());

    // 重置等效焦距
    this.mEventBus.on([ZoomActionType.ACTION_RESET_ZOOM_RATIO,
      ZoomActionType.ACTION_CHANGE_ZOOM_BY_FRAMERATE,
      ZoomActionType.ACTION_CHANGE_ZOOM_BY_VIDEORESOLUTION,
      CameraActionType.CHANGE_MODE,
      CameraActionType.CHANGE_OUTPUT_TYPE,
      CameraActionType.SWITCH_CAMERA,
      CameraActionType.SWITCH_CAMERA_CHANGE_MODE
    ], () => {
      this.quickZoomValArrLengthWatch = this.getRoulette2QuickOrUpdateZoomArrayLength()
    }, this.mBase.hashCode());
    this.mEventBus.on([ZoomActionType.ACTION_RESET_ZOOM_RATIO,
      CameraActionType.CHANGE_OUTPUT_TYPE,
      CameraActionType.SWITCH_CAMERA,
      CameraActionType.CHANGE_MODE,
      CameraActionType.SWITCH_CAMERA_CHANGE_MODE,
    ], this.updateCycleClickZoom.bind(this), this.mBase.hashCode());
    // 录像模式开关防抖时重置等效焦距
    this.mEventBus.on(CameraActionType.RESTART, () => {
      if (this.state.mode === ModeType.VIDEO) {
        this.quickZoomValArrLengthWatch = this.getRoulette2QuickOrUpdateZoomArrayLength()
      }
    }, this.mBase.hashCode())
    this.mEventBus.on(CameraActionType.CHANGE_MODE, this.changeQuickZoomArr.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.CHANGE_MODE, () => {
      this.isShowRouletteZoom = false;
      this.isShowBigText = false;
    }, this.mBase.hashCode());
    this.mEventBus.on([ZoomActionType.ACTION_RESET_ZOOM_RATIO, CameraActionType.CHANGE_MODE,
      CameraActionType.CHANGE_OUTPUT_TYPE,
      CameraActionType.SWITCH_CAMERA, CameraActionType.SWITCH_CAMERA_CHANGE_MODE],
      () => this.roulette2QuickAnimOrUpdateZoomArrayExecAnim(false), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.onCameraActionStarted.bind(this), this.mBase.hashCode());

    // 重置多端适配布局
    this.mEventBus.on(ActionType.ACTION_CHANGE_X_COMPONENT_SIZE,
      this.onChangeXComponentSize.bind(this), this.mBase.hashCode());

    // 自动广角逻辑处理
    this.mEventBus.on(ZoomActionType.ACTION_CHANGE_ZOOM_TO_WIDE_ANGLE, this.switchZoomToWideAngle.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ZoomActionType.ACTION_CHANGE_ZOOM_TO_DEFAULT, this.switchZoomToDefault.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.SELFIE_STICK_EVENT, this.selfieStickEvent.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.UPDATE_SAVE_POWER_MODE_STATE, (data: SavePowerModeActionData) =>
    this.updateSavePowerModeState(data), this.mBase.hashCode());

    // 遥控拍照变焦
    this.mEventBus.on(CollaborateControlActionType.ZOOM_IN, this.onCollaborateZoomIn.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.ZOOM_OUT, this.onCollaborateZoomOut.bind(this),
      this.mBase.hashCode());

    // AI 构图
    this.mEventBus.on(ZoomActionType.SHOW_COLORFUL_ZOOM_RING, this.handleShowColorfulBorder.bind(this),
      this.mBase.hashCode());

    // 智拍键滑动变焦
    this.mEventBus.on(ZoomActionType.ACTION_SMART_CONTROL_ZOOM_RATIO, this.onSmartControlZoomRatio.bind(this),
      this.mBase.hashCode());

    this.mEventBus.on([ActionType.ACTION_NIGHT_CAPTURE_START, ActionType.ACTION_START_STITCHING_CAPTURE],
      this.captureStart.bind(this), this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_NIGHT_CAPTURE_END, ActionType.ACTION_END_STITCHING_CAPTURE],
      this.captureEnd.bind(this), this.mBase.hashCode());
  }

  aboutToDisappear() {
    HiLog.i(TAG, 'disappear');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  /**
   * AI 构图展示彩色边框
   * */
  private handleShowColorfulBorder(data: Record<'isShow', boolean>): void {
    if (data.isShow) {
      this.showColorfulZoomRing();
    } else {
      this.hideColorfulZoomRing();
    }
  }

  private showColorfulZoomRing(): void {
    this.isShowColorfulZoomRing = true;
    this.isNeedVibratorWhenShowColorfulZoomRing = true;
    animateToImmediately({ curve: Curve.Sharp }, () => {
      this.colorfulZoomRingOpacity = 1;
    });
  }

  private hideColorfulZoomRing(): void {
    this.isNeedVibratorWhenShowColorfulZoomRing = false;
    animateToImmediately({
      curve: Curve.Sharp, onFinish: () => {
        this.isShowColorfulZoomRing = false;
      }
    }, () => {
      this.colorfulZoomRingOpacity = 0;
    });
  }

  /**
   * 适配自拍杆调节焦距
   * */
  private captureStart(): void {
    this.isSupportSelfieStick = false;
  }

  private captureEnd(): void {
    this.isSupportSelfieStick = true;
  }

  private updateSavePowerModeState(data: SavePowerModeActionData): void {
    this.isSavePowerMode = data.isDuringSavePowerMode;
  }

  private selfieStickEvent(data: SelfieStickKey): void {
    let isShowtimeLapse = getStates().get<boolean>('settingReducer', 'isShowtimeLapse');
    let isImmersive = getStates().get<boolean>('uiReducer', 'isImmersive');
    if (this.isSavePowerMode || !this.isSupportSelfieStick || isImmersive || isShowtimeLapse) {
      return;
    }
    HiLog.i(TAG, `selfieStickEvent finalKey:  ${data['key'].keyValue}`);
    if (data['key'].keyValue !== KeyCode.KEYCODE_ZOOMIN && data['key'].keyValue !== KeyCode.KEYCODE_ZOOMOUT) {
      return;
    }
    if ((this.curZoomValue >= this.opticalZoomValArr[this.opticalZoomValArr.length - 1] &&
      data['key'].keyValue === KeyCode.KEYCODE_ZOOMIN) || (this.curZoomValue <= this.opticalZoomValArr[0] &&
      data['key'].keyValue === KeyCode.KEYCODE_ZOOMOUT)) {
      return;
    }
    let index: number = this.calZoomValIndex();
    if (data['key'].keyValue === KeyCode.KEYCODE_ZOOMIN) {
      if (this.isBlockGestureEvent() && index !== (this.opticalZoomValArr.length - 1)) {
        this.curZoomValue = this.opticalZoomValArr[index + 1];
      } else {
        this.setSelfieStickZoomUp(data);
      }
    } else if (data['key'].keyValue === KeyCode.KEYCODE_ZOOMOUT) {
      if ((this.isBlockGestureEvent() && index !== 0)) {
        this.curZoomValue = this.opticalZoomValArr[index - 1];
      } else {
        this.setSelfieStickZoomDown(data);
      }
    }
    this.curValIndex = this.calZoomValIndex();
    this.changeZoomFunctionValue({ zoomRatio: this.curZoomValue });
    if (data['key'].preKeys !== undefined) {
      this.isShowQuickZoom = false;
      this.isShowRouletteZoom = false;
      this.clearAndSetQuickZoom();
    }
    this.clearAndSetBigTextTimer();
    this.clearSelStickShortPress();
    this.isShowBigText = true;
  }

  private setSelfieStickZoomUp(data: SelfieStickKey): void {
    let zoomValue: string;
    if (data['key'].preKeys === undefined) { // 短按自拍杆
      if (this.curZoomValue >= this.quickZoomValArr[this.quickZoomValArrLength -1]) {
        if (this.isSetSelfieStickZoom) {
          this.isSetSelfieStickZoom = false;
          this.clearAndSelfieStickZoomTimerId();
          zoomValue = (this.curZoomValue * selfieStickLongPressZoom).toFixed(3);
          this.curZoomValue = parseFloat(zoomValue) > this.opticalZoomValArr[this.opticalZoomValArr.length - 1] ?
            this.opticalZoomValArr[this.opticalZoomValArr.length - 1] : parseFloat(zoomValue);
        }
      } else {
        zoomValue = (this.curZoomValue + setOnceSelfieStickZoom).toFixed(1);
        this.curZoomValue = parseFloat(zoomValue);
      }
      this.isSelfieStickShortPress = true;
    } else if (data['key'].preKeys !== undefined && this.setSelfieStickZoom) { // 长按自拍杆
      this.isSelfieStickLongPress = true;
      zoomValue = (this.curZoomValue * selfieStickLongPressZoom).toFixed(3);
      this.curZoomValue = parseFloat(zoomValue) > this.opticalZoomValArr[this.opticalZoomValArr.length - 1] ?
        this.opticalZoomValArr[this.opticalZoomValArr.length - 1] : parseFloat(zoomValue);
      this.setSelfieStickZoom = false;
      this.setSelfieLongPress();
      this.selfieStickLongPressTimer = Date.now();
    }
  }

  private setSelfieStickZoomDown(data: SelfieStickKey): void {
    let zoomValue: string;
    if (data['key'].preKeys === undefined) {
      if (this.curZoomValue >= this.quickZoomValArr[this.quickZoomValArrLength -1]) {
        if (this.isSetSelfieStickZoom) {
          this.isSetSelfieStickZoom = false;
          this.clearAndSelfieStickZoomTimerId();
          zoomValue = (this.curZoomValue / selfieStickLongPressZoom).toFixed(3);
          this.curZoomValue = parseFloat(zoomValue) < this.opticalZoomValArr[0] ?
            this.opticalZoomValArr[0] : parseFloat(zoomValue);
        }
      } else {
        zoomValue = (this.curZoomValue - setOnceSelfieStickZoom).toFixed(1);
        this.curZoomValue = parseFloat(zoomValue);
      }
      this.isSelfieStickShortPress = true;
    } else if (data['key'].preKeys !== undefined && this.setSelfieStickZoom) {
      this.isSelfieStickLongPress = true;
      zoomValue = (this.curZoomValue / selfieStickLongPressZoom).toFixed(3);
      this.curZoomValue = parseFloat(zoomValue) < this.opticalZoomValArr[0] ?
        this.opticalZoomValArr[0] : parseFloat(zoomValue);
      this.setSelfieStickZoom = false;
      this.setSelfieLongPress();
      this.selfieStickLongPressTimer = Date.now();
    }
  }

  private clearAndSelfieStickZoomTimerId(): void {
    if (this.setSelfieStickZoomTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.setSelfieStickZoomTimerId);
      this.setSelfieStickZoomTimerId = Number.MIN_VALUE;
    }
    this.setSelfieStickZoomTimerId = setTimeout((): void => {
      this.isSetSelfieStickZoom = true;
    }, SET_SELFIE_STICK_ZOOM_NUM);
  }

  private clearAndSetQuickZoom(): void {
    this.clearQuickZoomTimer();
    this.quickZoomTimerId = setTimeout((): void => {
      this.isShowQuickZoom = true;
      this.isSelfieStickLongPress = false;
    }, 1500);
  }

  private clearQuickZoomTimer(): void {
    if (this.quickZoomTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.quickZoomTimerId);
      this.quickZoomTimerId = Number.MIN_VALUE;
    }
  }

  private clearSelStickShortPress(): void {
    if (this.selfieStickShortPressTimer !== Number.MIN_VALUE) {
      clearTimeout(this.selfieStickShortPressTimer);
      this.selfieStickShortPressTimer = Number.MIN_VALUE;
    }
    this.selfieStickShortPressTimer = setTimeout((): void => {
      this.isSelfieStickShortPress = false;
    }, 1500);
  }

  private setSelfieLongPress(): void {
    if (this.selfieStickZoomTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.selfieStickZoomTimerId);
      this.selfieStickZoomTimerId = Number.MIN_VALUE;
    }
    this.selfieStickZoomTimerId = setTimeout((): void => {
      this.setSelfieStickZoom = true;
    }, 1000 / selfieStickLongPressCount);
  }

  private handleDepthFusionBarVisibility(data: ActionData): void {
    if (!this.isShowQuickZoom || this.isShowLandscape) {
      return;
    }
    const targetShowState: boolean = data['isShow'];
    if (this.isDepthFusionBarShow === targetShowState) {
      return;
    }
    this.isDepthFusionBarShow = targetShowState;

    HiLog.i(TAG, `is depthFusion bar show: ${this.isDepthFusionBarShow}`);
    this.updateQuickZoomValArr(
      this.isDepthFusionBarShow ? [this.quickZoomValArr[this.curValIndex]] : this.zoomScaleStruct.quickZoomValArr);
    this.changeQuickZoomViewOpacity();
  }

  private handleStitchingTypeBarVisibility(data: ActionData): void {
    const targetShowState: boolean = data['showStitchingBar'];
    this.isStitchingTypeBarShow = targetShowState;
    this.updateQuickZoomValArr(
      this.isStitchingTypeBarShow ? [this.quickZoomValArr[this.curValIndex]] : this.zoomScaleStruct.quickZoomValArr);

    this.changeQuickZoomViewOpacity();
  }

  private changeQuickZoomViewOpacity(): void {
    if (this.isDepthFusionBarShow || this.isStitchingTypeBarShow) {
      this.quickZoomValArrLengthWatch = 1;
      this.initZoomViewUIData(this.state.zoomRatio);
      animateTo({
        duration: 100,
        curve: Curve.Sharp,
        iterations: 1,
        playMode: PlayMode.Normal,
        delay: 150,
        onFinish: () => {
          HiLog.i(TAG, 'depthFusion hide quickZoom animation onFinish');
        },
      }, () => {
        this.mQuickOtherAlpha = 0;
      });
    } else {
      animateTo({
        duration: 100,
        curve: Curve.Sharp,
        iterations: 1,
        playMode: PlayMode.Normal,
        delay: 100,
        onFinish: () => {
          HiLog.i(TAG, 'depthFusion hide quickZoom animation onFinish');
        }
      }, () => {
        this.mQuickOtherAlpha = 1;
      });
      setTimeout(() => {
        this.initZoomViewUIData(this.state.zoomRatio)
      }, 50);
      setTimeout(() => {
        this.quickZoomValArrLengthWatch = this.quickZoomValArr.length;
      }, 150);
    }
  }

  /**
   *  切换至默认广角ZOOM_RATIO_WIDE
   */
  private switchZoomToWideAngle(data: ActionData): void {
    HiLog.i(TAG, `switchZoomToWideAngle ${data['zoomRatio']} - ${this.curZoomValue} - ${this.opticalZoomValArr[0]}`);
    if (data['zoomRatio'] && this.curZoomValue === this.opticalZoomValArr[0]) {
      HiLog.w(TAG, 'zoom value is w, can not change to 0.8x');
      return;
    }
    let zoomRatio: number = data['zoomRatio'] || this.opticalZoomValArr[0];
    if (this.opticalZoomValArr[0] <= zoomRatio && this.curZoomValue != zoomRatio) {
      HiLog.i(TAG, `switch zoom ratio to ${zoomRatio} x.`);
      this.curZoomValue = zoomRatio;
      this.bigTextZoomValue = zoomRatio;
      this.curValIndex = this.calZoomValIndex(zoomRatio);
      this.quickZoomArray = CameraAppCapability.getInstance()
        .getQuickZoomArray(this.state.cameraPosition, this.state.mode, OutputSwitcher.getInstance().getOutput());
      this.changeZoomFunctionValue({
        zoomRatio: this.curZoomValue,
        isPrepareZoom: true,
        isUnprepareZoom: true,
        unprepareDelay: ZoomParam.UNPREPARE_DELAY_TIME
      },
        zoomRatio === ZoomOperation.getDirectionChangeAutoWide(this.quickZoomArray));
    }
  }

  /**
   *  广角切换至默认焦距1
   */
  private switchZoomToDefault(): void {
    HiLog.i(TAG, 'switchZoomToDefault.');
    this.quickZoomArray = CameraAppCapability.getInstance()
      .getQuickZoomArray(this.state.cameraPosition, this.state.mode, OutputSwitcher.getInstance().getOutput());
    this.curZoomValue = 1;
    this.bigTextZoomValue = 1;
    this.curValIndex = this.calZoomValIndex(1);
    HiLog.i(TAG, 'switch zoom ratio to 1x.');
    this.changeZoomFunctionValue({
      zoomRatio: this.curZoomValue,
      isPrepareZoom: true,
      isUnprepareZoom: true,
      unprepareDelay: ZoomParam.UNPREPARE_DELAY_TIME
    }, true);
  }

  private changeRotateAngle(): void {
    if (this.rotateAngleWatch === this.rotateAngle) {
      return;
    }
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_300,
      curve: Curve.Friction,
    }, () => {
      this.rotateAngle = this.rotateAngleWatch;
    });
  }

  /**
   * 用于注册Preview区域点击事件类似行为监听的回调
   * */
  private responsePreviewClick(): void {
    if (this.state.isShowPinch) {
      return;
    }
    if (this.mZoomInnerStatus === ZoomInnerStatus.QUICK_STATIC ||
      this.mZoomInnerStatus === ZoomInnerStatus.ROULETTE_TO_QUICK) {
      return;
    }
    if (this.mZoomInnerStatus === ZoomInnerStatus.QUICK_CLICK) {
      this.clearAndSetBigTextTimer();
      this.isShowBigText = false;
      return;
    }
    if (this.mZoomInnerStatus === ZoomInnerStatus.QUICK_TO_ROULETTE ||
      this.mZoomInnerStatus === ZoomInnerStatus.ROULETTE_SLIDE ||
      this.mZoomInnerStatus === ZoomInnerStatus.ROULETTE_STATIC) {
      this.cancelNativeAndFrameAnimators();
      this.clearRouletteZoomTimer();
      this.execRouletteZoom2QuickZoomAnim();
      // 非zoomBar组件触发的沉浸式状态改变，则不响应
      if (this.state.isImmersive && this.state.mainTrigCompo === UIOperationType.ZOOM_BAR) {
        this.mAction.isEnterImmersive(false);
      }
      if (!this.state.uiEnable) {
        this.mAction.uiStateWithMode(true);
      }
      return;
    }
  }

  private getRoulette2QuickOrUpdateZoomArrayLength(isExec2QuickAnim = true): number {

    HiLog.i(TAG, 'getRoulette2QuickOrUpdateZoomArrayLength isExec2QuickAnim : ' + isExec2QuickAnim);
    if (isExec2QuickAnim) {
      this.responsePreviewClick();
    }

    // initZoomData与动效时序控制
    let mZoomScaleStruct = ZoomOperation.getRingZoomUIState(this.state.cameraPosition, this.state.mode);
    this.oldQuickZoomArrLength = this.quickZoomValArr.length;
    if (isExec2QuickAnim) {
      HiLog.i(TAG, 'quickZoomValArr bendin : ' + this.quickZoomValArr + ', initZoomViewUIData : ' +
      mZoomScaleStruct.quickZoomValArr);
    }
    this.updateQuickZoomValArr(mZoomScaleStruct.quickZoomValArr);
    if (isExec2QuickAnim) {
      HiLog.i(TAG, 'quickZoomValArr end : ' + this.quickZoomValArr);
    }
    this.opticalZoomValArr = mZoomScaleStruct.opticalZoomValArr;
    this.opticalZoomDotIndexArr = mZoomScaleStruct.opticalZoomDotIndex;
    this.zoomScaleStruct = mZoomScaleStruct;
    this.opticalZoomDotAngleArr = [];
    this.opticalZoomDotIndexArr.forEach((value: number) => {
      this.opticalZoomDotAngleArr.push(-ZoomParam.SCALE_GAP_ANGLE * value);
    });

    this.initZoomViewUIData(this.state.zoomRatio);
    this.mAction.initZoomRatio(this.opticalZoomValArr[0], this.opticalZoomValArr[this.opticalZoomValArr.length - 1]);

    this.smallScaleDotAngleArr = [];
    for (let i = 0; i < this.opticalZoomDotIndexArr.length - 1; i++) {
      for (let j = this.opticalZoomDotIndexArr[i] + 1; j < this.opticalZoomDotIndexArr[i + 1]; j++) {
        this.smallScaleDotAngleArr.push(-ZoomParam.SCALE_GAP_ANGLE * j);
      }
    }
    if (this.isNeedShowEquivalentFocalBigText() || CameraAppCapability.getInstance().getIsSupportedCycleClickZoom()) {
      this.updateEquivalentFocalArray(); // 模式切换时等效焦距需及时更新, 避免等效大字体显示上一个模式的焦距
    }
    return this.quickZoomValArr.length;
  }

  private roulette2QuickAnimOrUpdateZoomArrayExecAnim(isSuperMacroChange: boolean): void {
    HiLog.i(TAG, 'roulette2QuickAnimOrUpdateZoomArrayExecAnim.');
    if (!isSuperMacroChange) {
      // 微距小花图标更新同样触发此方法，避免切换关闭微距选项时影响正在显示edof参数栏的场景
      this.isDepthFusionBarShow = false;
      this.mQuickOtherAlpha = 1;
    }
    this.responsePreviewClick();

    // initZoomData与动效时序控制
    let mZoomScaleStruct = ZoomOperation.getRingZoomUIState(this.state.cameraPosition, this.state.mode);
    this.oldQuickZoomArrLength = this.quickZoomValArr.length;

    this.updateQuickZoomValArr(mZoomScaleStruct.quickZoomValArr);

    this.opticalZoomValArr = mZoomScaleStruct.opticalZoomValArr;
    this.opticalZoomDotIndexArr = mZoomScaleStruct.opticalZoomDotIndex;
    this.zoomScaleStruct = mZoomScaleStruct;
    this.opticalZoomDotAngleArr = [];
    this.opticalZoomDotIndexArr.forEach((value: number) => {
      this.opticalZoomDotAngleArr.push(-ZoomParam.SCALE_GAP_ANGLE * value);
    });

    this.initZoomViewUIData(this.state.zoomRatio);
    this.mAction.initZoomRatio(this.opticalZoomValArr[0], this.opticalZoomValArr[this.opticalZoomValArr.length - 1]);

    this.smallScaleDotAngleArr = [];
    for (let i = 0; i < this.opticalZoomDotIndexArr.length - 1; i++) {
      for (let j = this.opticalZoomDotIndexArr[i] + 1; j < this.opticalZoomDotIndexArr[i + 1]; j++) {
        this.smallScaleDotAngleArr.push(-ZoomParam.SCALE_GAP_ANGLE * j);
      }
    }
  }

  private changeZoomWithCustomImmersive(): void {
    if (GlobalContext.get().getIsPicker()) {
      return;
    }
    if (!this.isLandscapeIndex()) {
      this.changeZoomVisWithAnim();
    }
    this.changeZoomPosWithAnim();
  }

  private changeZoomPosWithAnim() {
    this.zoomPosAnimator?.pause();
    let options: AnimatorOptions = {
      duration: AnimSpecifications.ANIM_DURATION_300,
      easing: 'cubic-bezier(0.33, 0.0, 0.67, 1.0)',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: this.mQuickOffsetY,
      end: this.isCustomFilterImmersive ? ZOOM_CUSTOM_FILTER_VERTICAL_OFFSET : 0
    };
    if (this.zoomPosAnimator) {
      try {
        this.zoomPosAnimator.reset(options);
      } catch (error) {
        HiLog.i(TAG, `zoomPosAnimator error: ${JSON.stringify(error)}.`);
      }
    } else {
      this.zoomPosAnimator = animator.create(options);
    }
    this.zoomPosAnimator.onframe = (value) => {
      this.mQuickOffsetY = value;
    };
    this.zoomPosAnimator.onfinish = () => {
      this.zoomPosAnimator = null;
    }
    this.zoomPosAnimator.oncancel = () => {
      this.zoomPosAnimator = null;
    }
    this.zoomPosAnimator?.play();
  }

  private changeZoomVisWithAnim(): void {
    if (this.isCustomFilterImmersive) {
      animateToImmediately({
        duration: 150,
        curve: Curve.Sharp,
        onFinish: () => {
          this.zoomIsHide = true;
        }
      }, () => {
        this.mQuickOtherAlpha = 0;
      });
    } else {
      this.zoomIsHide = false;
      animateToImmediately({
        duration: 150,
        delay: 100,
        curve: Curve.Sharp
      }, () => {
        this.mQuickOtherAlpha = 1;
      });
    }
  }

  private updateQuickZoomValArr(targetArray: number[]): void {
    if (!targetArray) {
      return;
    }
    let countDiff = targetArray.length - this.quickZoomValArr.length;
    let minCount = Math.min(targetArray.length, this.quickZoomValArr.length);
    HiLog.i(TAG, 'countDiff ' + countDiff + ', minCount : ' + minCount);
    for (let i = 0; i < minCount; i++) {
      this.quickZoomValArr[i] = targetArray[i];
    }
    if (countDiff > 0) {
      for (let i = minCount; i < targetArray.length; i++) {
        this.quickZoomValArr.push(targetArray[i]);
      }
    } else if (countDiff < 0) {
      this.quickZoomValArr.splice(minCount, this.quickZoomValArr.length - minCount);
    }
    HiLog.i(TAG, 'updateQuickZoomValArr');
  }

  private updateSuperMacroZoomView(data: EnableData): void {
    if (this.superMacroEnable === data.superMacroEnable) {
      return;
    }
    this.superMacroEnable = data.superMacroEnable;
    let zoomRatio: number = 1;
    const remainZoomRatio: boolean = ZoomOperation.getInstance().getRemainZoomRatio();
    if (remainZoomRatio || this.state.mode === ModeType.PHOTO) {
      zoomRatio = this.state.zoomRatio;
    } else if (this.state.mode === ModeType.VIDEO) {
      zoomRatio = FeatureManager.getInstance().getFunction(FunctionId.ZOOM).getValue();
    }
    HiLog.i(TAG, `mZoomRatio: ${zoomRatio}, ${this.state.zoomRatio}, remainZoomRatio: ${remainZoomRatio}.`);

    this.quickZoomValArrLengthWatch = this.getRoulette2QuickOrUpdateZoomArrayLength(false);
    this.roulette2QuickAnimOrUpdateZoomArrayExecAnim(true);

    this.updateEquivalentFocalArray();
    this.initZoomViewUIData(zoomRatio);
    if (this.superMacroEnable && this.state.mode === ModeType.VIDEO &&
      zoomRatio > this.opticalZoomValArr[this.opticalZoomValArr.length - 1]) {
      this.changeZoomFunctionValue({ zoomRatio: this.curZoomValue });
    }
  }

  private handleZoomRatioChange(data: Required<ZoomFuncValueStruct>): void {
    if (this.state.isShowPinch) {
      return;
    }
    if (data.zoomRatio !== this.curZoomValue) {
      this.initZoomViewUIData(data.zoomRatio);
    }
  }

  private onSetFunctionConflict(data: Record<'id', number>): void {
    if (FunctionId.FRAME_RATE === data.id &&
    OutputOperation.isPanVideoOutput(getStates().get<ModeType>('modeReducer', 'mode'))) {
      this.quickZoomValArrLengthWatch = this.getRoulette2QuickOrUpdateZoomArrayLength();
      return;
    }
    if (FunctionId.ZOOM !== data.id) {
      return;
    }
    this.curZoomValue = Number((this.state.zoomRatio).toFixed(3));
    this.curValIndex = this.calZoomValIndex();
    this.initZoomViewUIData(this.curZoomValue);
  }

  /**
   * 前置捏合变焦场景
   */
  private onSwitchZoomRatio(data: Record<'toNext', boolean>): void {
    if (data.toNext && this.curValIndex < this.opticalZoomValArr.length - 1) {
      this.curZoomValue = this.opticalZoomValArr[this.curValIndex + 1];
      this.curValIndex++;
      this.bigTextZoomValue = this.curZoomValue;
      HiLog.d(TAG, `pinch to switch Zoom value : ${this.curZoomValue}.`);
      this.changeZoomFunctionValue({ zoomRatio: this.curZoomValue });
      return;
    }
    if (!data.toNext && this.curValIndex > 0) {
      this.curZoomValue = this.opticalZoomValArr[this.curValIndex - 1];
      this.curValIndex--;
      this.bigTextZoomValue = this.curZoomValue;
      HiLog.d(TAG, `pinch to switch Zoom value : ${this.curZoomValue}.`);
      this.changeZoomFunctionValue({ zoomRatio: this.curZoomValue });
      return;
    }
  }

  /**
   * 智拍键滑动变焦场景
   */
  private onSmartControlZoomRatio(data: Record<'toNext', boolean>): void {
    this.responsePreviewClick();
    if (data.toNext && this.curValIndex < this.quickZoomValArr.length - 1) {
      this.curZoomValue = this.quickZoomValArr[this.curValIndex + 1];
      this.curValIndex++;
      this.bigTextZoomValue = this.curZoomValue;
      HiLog.d(TAG, `pinch to switch Zoom value : ${this.curZoomValue}.`);
      this.changeZoomFunctionValue({
        zoomRatio: this.curZoomValue,
        isPrepareZoom: true,
        isUnprepareZoom: true,
        isSmoothZoom: true
      });
      if (CameraAppCapability.getInstance().getIsSupportedCycleClickZoom()) {
        this.showBigTextAndEquivZoomText();
      }
      if (this.isShowBigText) {
        this.clearAndSetBigTextTimer();
      } else {
        this.isShowBigText = true;
      }
      return;
    }
    if (!data.toNext && this.curValIndex > 0) {
      this.curZoomValue = this.quickZoomValArr[this.curValIndex - 1];
      this.curValIndex--;
      this.bigTextZoomValue = this.curZoomValue;
      HiLog.d(TAG, `pinch to switch Zoom value : ${this.curZoomValue}.`);
      this.changeZoomFunctionValue({
        zoomRatio: this.curZoomValue,
        isPrepareZoom: true,
        isUnprepareZoom: true,
        isSmoothZoom: true
      });
      if (CameraAppCapability.getInstance().getIsSupportedCycleClickZoom()) {
        this.showBigTextAndEquivZoomText();
      }
      if (this.isShowBigText) {
        this.clearAndSetBigTextTimer();
      } else {
        this.isShowBigText = true;
      }
      return;
    }
  }

  /**
   * 双指捏合过程中更新变焦状态,执行振动效果
   * */
  private pinchUpdateZoomAndVibrator(data: ActionData): void {
    if (CameraAppCapability.getInstance().getNotSupportedVideo60fpsWide() &&
      (getStates().get<ModeType>('modeReducer', 'mode') === ModeType.VIDEO) &&
      getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ==
      camera.CameraPosition.CAMERA_POSITION_BACK &&
      data['id'] === FunctionId.FRAME_RATE) {
      this.getRoulette2QuickOrUpdateZoomArrayLength();
    }
    if (this.isBlockGestureEvent() || (data['id'] !== FunctionId.ZOOM && data['id'] !== FunctionId.ASPECT_RATIO)) {
      return;
    }
    if (data['id'] === FunctionId.ASPECT_RATIO) {
      this.responsePreviewClick();
    }
    let nowZoomValue = this.state.zoomRatio;
    let prevZoomValue = this.curZoomValue;
    if (!this.state.isShowPinch || this.curZoomValue === this.state.zoomRatio) {
      return;
    }
    if (this.isAllowVibratorSound()) {
      this.opticalZoomValArr.forEach((value, index) => {
        // 捏合手势变焦至快捷变焦点执行振动音频
        let isQuickZoom = ((prevZoomValue > value && value >= nowZoomValue) ||
          (prevZoomValue < value && value <= nowZoomValue));
        if (isQuickZoom) {
          this.onPinchChangeZoomValueVibrate();
        }
      });
    }
    this.curZoomValue = this.state.zoomRatio;
    this.curValIndex = this.calZoomValIndex();
    this.bigTextZoomValue = this.curZoomValue;
  }

  private debounceTimer: number = -1; // 捏合震动节流使用

  private onPinchChangeZoomValueVibrate(): void {
    if (this.debounceTimer !== -1) {
      return;
    }
    this.debounceTimer = setTimeout((): void => {
      VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID, VIBRATOR_USAGE_PHYSIC);
      this.debounceTimer = -1;
    }, 50);
  }

  /**
   * 双指捏合起始时重置变焦态、清除动效定时器、重置大字体状态
   * */
  private pinchResetZoomAndBigText(): void {
    this.clearBigTextTimer();
    this.clearRouletteZoomTimer();
    if (this.state.isShowPinch) {
      this.mAction.changeZoomState(ZoomOuterStatus.PINCH_ZOOM);
      this.mZoomInnerStatus = ZoomInnerStatus.PINCH_ZOOM;
      this.bigTextZoomValue = this.state.zoomRatio; // 捏合变焦大字体显示之前先同步redux层数据
      this.isShowQuickZoom = false;
      this.isShowRouletteZoom = false;
      this.isShowBigText = true;
      this.isDuringCycleClick = false;
      this.doCycleClickZoomAnim(false)
    } else {
      if (!this.isStitchingTypeBarShow) {
        this.mQuickOtherAlpha = 1;
      }
      this.isShowQuickZoom = true;
      this.isShowRouletteZoom = false;
      this.isShowBigText = false;
      this.mZoomInnerStatus = ZoomInnerStatus.QUICK_STATIC;
      this.mAction.changeZoomState(ZoomOuterStatus.QUICK_ZOOM);
      if (!this.enableScreenReader) {
        return;
      }
      if (this.curValIndex === 0 && this.state.zoomRatio <= this.quickZoomArray[0] && this.state.zoomRatio < 1) {
        AccessibilityUtils.sendAnnounceAccessibilityEvent(ResGetter.getStringSafe($r('app.string.wide_angle')));
      } else {
        AccessibilityUtils.sendAnnounceAccessibilityEvent(
          getContext(this).resourceManager
            .getPluralStringValueSync($r('app.plural.accessibility_tips_zoom_scale_new').id,
              this.roundOrSplitZoomVal(this.bigTextZoomValue)));
      }
    }
  }

  private getDefaultZoomRatio(): number {
    let mode = getStates().get<ModeType>('modeReducer', 'mode');
    let cameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    return ZoomOperation.getDefaultZoomRatio(mode, cameraPosition);
  }

  private onForegroundCallback(): void {
    let zoomRatio: number = this.getDefaultZoomRatio();
    if (ZoomOperation.getInstance().getRemainZoomRatio()) {
      zoomRatio = this.state.zoomRatio;
    } else {
      this.doCycleClickZoomAnim(false);
      this.isDuringCycleClick = false;
    }
    // 更新变焦值,帧率互斥逻辑使用
    StoreManager.getInstance().postMessage(ZoomAction.updateStateZoomRatio(zoomRatio));
    this.initDepthFusionState();
    this.initZoomViewUIData(zoomRatio);
  }

  private stateChange(): void {
    if (!this.isBackground && GlobalContext.get().getT('isSecurityCamera') && !this.isSecurityCameraLast) {
      ZoomOperation.getInstance().setRemainZoomRatio(false);
    }
  }

  private cameraLocked(lockedData: LockedData): void {
    if (!GlobalContext.get().getT('isSecurityCamera') && !GlobalContext.get().getIsPicker() && lockedData?.isLocked) {
      // 桌面相机界面直接锁屏，亮屏相机焦距保持
      ZoomOperation.getInstance().setRemainZoomRatio(true);
    }
  }

  private initDepthFusionState(): void {
    HiLog.i(TAG, `init depth fusion zoom bar ${this.zoomScaleStruct.quickZoomValArr}`);
    if (this.isDepthFusionBarShow) {
      this.quickZoomValArrLengthWatch = this.getRoulette2QuickOrUpdateZoomArrayLength()
    }
    this.isDepthFusionBarShow = false;
    if (!this.isStitchingTypeBarShow) {
      this.mQuickOtherAlpha = 1;
    }
  }

  private onBackgroundCallback(data: ActionData): void {
    this.isSecurityCameraLast = GlobalContext.get().getT('isSecurityCamera');
    this.isShowRouletteZoom = false;
    if (this.mZoomInnerStatus !== ZoomInnerStatus.QUICK_STATIC) {
      this.responsePreviewClick();
    }
    if (ZoomOperation.getInstance().getRemainZoomRatio()) {
      return;
    }
    if (data['isScreenLockBack'] || data?.data?.isLocked) {
      // 锁屏相机不退出息屏亮屏之后，焦距保持
      ZoomOperation.getInstance().setRemainZoomRatio(true);
    } else {
      ZoomOperation.getInstance().setRemainZoomRatio(false);
    }
  }

  private onCameraActionStarted(data?: CameraStartTypeStruct): void {
    setTimeout(() => {
      if (!ZoomOperation.getInstance().isZoomViewCreated) {
        HiLog.i(TAG, `reset isZoomViewCreated true`);
        ZoomOperation.getInstance().isZoomViewCreated = true;
        this.changeQuickZoomArr();
      }
    }, 20);
    if (PickerUtils.getIsPicker() && !PickerUtils.getIsFullScreen()) {
      this.zoomWidth =
        DeviceInfo.isTablet() ? this.getTabletPickerWidth() : this.state.isShowDefault ? this.state.xComponentWidth :
          this.state.isShowSemiCollapsed ? 308 : this.landscapeZoomWidth;
    } else if (DeviceInfo.isPhone() && this.state.isShowDefault) {
      const size: Size = CameraBasicService.getInstance().getPreviewDisplaySize();
      this.zoomWidth = size.width;
      this.drawHeight = AdaptiveLayoutService.getInstance().preview4to3Height * 0.16;
    }
    this.mNodeController?.updateZoomLayout(this.zoomWidth, this.zoomHeight, this.drawHeight,
      this.getZoomSelfCollapsStatus(), this.getZoomSelfDirectRotateAngle());
    if (!(data && data.type === CameraStartType.RECORD)) {
      this.updateEquivalentFocalArray();
    }
  }

  private onChangeXComponentSize(data: XComponentSize): void {
    if (this.mZoomInnerStatus !== ZoomInnerStatus.QUICK_STATIC) {
      this.responsePreviewClick();
    }
    this.onChangeCollapsStatus(); // 横屏大图组件长按退出场景刷新UI
    return; // 悬浮窗变焦宽策略预留,根据UX检视执行
    this.zoomWidth = data.xComponentWidth;
    this.mNodeController?.updateZoomLayout(this.zoomWidth, this.zoomHeight, this.drawHeight,
      this.getZoomSelfCollapsStatus(), this.getZoomSelfDirectRotateAngle());

    let redLineTopHeight = this.drawHeight;
    this.redLineTopY = 150 - redLineTopHeight;
    this.redLineTopRadius = (this.zoomWidth * this.zoomWidth / 4 +
      redLineTopHeight * redLineTopHeight) / (2 * redLineTopHeight);
  }

  private getTabletPickerWidth(): number {
    HiLog.i(TAG, `getTabletPickerWidth pickerWindowType: ${this.pickerWindowType}`);
    if (this.pickerWindowType === PickerWindowType.TABLET_TOP_BOTTOM_HALF_SPLIT_SCREEN) {
      return 0.57 * this.windowHeight;
    }
    if (this.pickerWindowType === PickerWindowType.TABLET_LEFT_RIGHT_SPLIT_SCREEN) {
      return 0.5 * this.windowHeight;
    }
    if (this.pickerWindowType === PickerWindowType.TABLET_IN_FLOATING) {
      return 0.5 * this.windowHeight;
    }
    if (this.pickerWindowType === PickerWindowType.TABLET_1_3_SPLIT_SCREEN) {
      return 0.75 * this.windowHeight;
    }
    if (this.pickerWindowType === PickerWindowType.TABLET_FULL_SCREEN) {
      if (DisplayService.getInstance().isOrientationVertical()) {
        return 0.28 * this.windowHeight;
      } else {
        const blackSideBlack16to9TopBottom: number =
          (this.windowHeight - getStates().get<number>('windowReducer', 'windowWidth') * 9 / 16) / 2;
        const remainingAreaHeight: number = this.windowHeight - blackSideBlack16to9TopBottom * 2 - 32;
        return remainingAreaHeight * 0.44;
      }
    }
    return 0.43 * this.windowHeight;
  }

  private onChangeCollapsStatus(): void {
    if (!DeviceInfo.isPhone()) {
      return;
    }
    const size: Size = CameraBasicService.getInstance().getPreviewDisplaySize();
    if (PickerUtils.getIsPicker() && this.state.isShowDefault) {
      this.zoomWidth =
        DeviceInfo.isTablet() ? this.getTabletPickerWidth() : getStates().get<number>('windowReducer', 'windowWidth');
    } else {
      this.zoomWidth = this.state.isShowDefault ? size.width :
        this.state.isShowSemiCollapsed ? 308 : this.landscapeZoomWidth;
    }
  }

  private isAllowVibratorSound(): boolean {
    if (this.state.recordingState === RecordingState.READY || this.state.recordingState === RecordingState.PAUSED) {
      return true;
    }
    return false;
  }

  private getZoomSelfCollapsStatus(): number {
    return (this.state.isShowDefault && DeviceInfo.isPhone()) ? 0 : this.state.isShowSemiCollapsed ? 2 : 1;
  }

  private getZoomSelfDirectRotateAngle(): number {
    return this.rotateAngle - (this.state.isShowSemiCollapsed ? 180 :
      ((this.isShowLandscape || DeviceInfo.isTablet()) || this.isShowTricollaps) ? 90 : 0);
  }

  // 更新等效焦距范围
  private updateEquivalentFocalArray(): void {
    if (!this.quickZoomValArr?.length || !this.opticalZoomValArr?.length ||
      this.opticalZoomValArr.length !== this.opticalZoomDotIndexArr.length) {
      HiLog.w(TAG, 'updateEquivalentFocalArray: skip initNode, zoom arrays empty or length mismatch.');
      this.quickEquivalentFocalArr = [];
      return;
    }
    this.quickEquivalentFocalArr = [];
    let zoomPointInfo: ZoomPointInfo = CameraProxy.getInstance().getZoomPointInfo();
    this.quickZoomValArr.forEach((zoomVal: number) => {
      this.quickEquivalentFocalArr.push(Math.round(zoomVal * zoomPointInfo?.equivalentFocalLength / 1));
      // 临时规避框架bug Math.round(zoomVal * zoomPointInfo.equivalentFocalLength / zoomPointInfo.zoomRatio));
    });
    if (this.quickEquivalentFocalArr.length !== this.quickZoomValArr.length) {
      HiLog.w(TAG, 'updateEquivalentFocalArray: equivalent focal length mismatch, skip initNode.');
      return;
    }
    this.mNodeController?.initNode(this.quickZoomValArr, this.quickEquivalentFocalArr, this.opticalZoomValArr,
      this.opticalZoomDotIndexArr);
  }

  /**
   * 点切变焦按人因曲线下发,更新取景框内容动效
   * */
  private clickZoomDelivery(): void {
    this.changeZoomFunctionValue({
      zoomRatio: this.curZoomValue,
      isPrepareZoom: this.enableScreenReader,
      isUnprepareZoom: this.enableScreenReader,
      isSmoothZoom: !this.isBlockGestureEvent() && !this.isPrepareZoomWithMode(),
      unprepareDelay: this.enableScreenReader ? ZoomParam.UNPREPARE_DELAY_TIME : undefined
    });
  }

  private isPrepareZoomWithMode(): boolean {
    return false;
  }

  private clearAndSetRouletteZoomTimer(): void {
    this.clearRouletteZoomTimer();
    this.rouletteZoomTimerId = setTimeout((): void => {
      this.execRouletteZoom2QuickZoomAnim();
    }, this.mZoomInnerStatus !== ZoomInnerStatus.QUICK_TO_ROULETTE ? 1000 : 2000);
  }

  private execRouletteZoom2QuickZoomAnim(): void {
    this.mZoomInnerStatus = ZoomInnerStatus.ROULETTE_TO_QUICK;
    this.updateAnimInitParam(2);
    // 临时规避animateTo接口初始化后设置组件显示,动效参数不生效问题
    this.createPlayNativeAnimator(800, 2);
    this.rouletteDisappearExecSphereAnim();
    this.rouletteDisappearExecBigTextAnim();
    this.rouletteDisappearExecRedLineAndScaleAllAnim();
    this.rouletteDisappearExecCarmenLineAnim();
    this.rouletteDisappearExecQuickZoomOutsideAnim();
  }

  private clearRouletteZoomTimer(): void {
    if (this.rouletteZoomTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.rouletteZoomTimerId);
      this.rouletteZoomTimerId = Number.MIN_VALUE;
    }
  }

  private clearAndSetBigTextTimer(): void {
    this.clearBigTextTimer();
    this.bigTextTimerId = setTimeout((): void => {
      this.isShowBigText = false;
    }, 1500);
  }

  private clearBigTextTimer(): void {
    if (this.bigTextTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.bigTextTimerId);
      this.bigTextTimerId = Number.MIN_VALUE;
    }
  }

  private clearAndSetCycleClickTimer(): void {
    this.clearCycleClickTimer();
    this.cycleClickTimerId = setTimeout((): void => {
      this.doCycleClickZoomAnim(false);
    }, 1500);
  }

  private clearCycleClickTimer(): void {
    if (this.cycleClickTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.cycleClickTimerId);
      this.cycleClickTimerId = Number.MIN_VALUE;
    }
  }

  private getMarginBottom(): number {
    if (this.isVdeLandscape) {
      return 10;
    }
    if (PickerUtils.getIsPicker() && this.pickerWindowType !== PickerWindowType.COLLAPSED_VERTICAL_FULL &&
      this.pickerWindowType !== PickerWindowType.COLLAPSED_HORIZONTAL_FULL) {
      return 29;
    }
    return (this.isShowLandscape || DeviceInfo.isTablet()) ? QUICK_ZOOM_MARGIN_BOTTOM_28 : 20;
  }

  private playColorfulZoomRingLottieAnimation(): void {
    lottie.pause(COLORFUL_ZOOM_RING_ANIM_NAME);
    lottie.destroy(COLORFUL_ZOOM_RING_ANIM_NAME);
    this.animationItem = lottie.loadAnimation({
      container: this.canvasContext,
      renderer: 'canvas',
      loop: true,
      path: COLORFUL_ZOOM_RING_CANVAS_PATH,
      autoplay: true,
      name: COLORFUL_ZOOM_RING_ANIM_NAME
    });
    this.animationItem?.addEventListener('DOMLoaded', (): void => {
      HiLog.i(TAG, 'lottieCanvasBuilder loaded');
    });
    this.animationItem?.addEventListener('complete', (): void => {
      HiLog.i(TAG, 'lottieCanvasBuilder Canvas complete.');
    });
  }

  @Builder
  ColorfulZoomRing() {
    Canvas(this.canvasContext)
      .onReady(() => {
        this.playColorfulZoomRingLottieAnimation();
      })
      .onDisAppear((): void => {
        HiLog.i(TAG, 'lottieCanvasBuilder Canvas onDisAppear.');
        lottie.destroy(COLORFUL_ZOOM_RING_ANIM_NAME);
      })
      .width(QUICK_ZOOM_ITEM_SIZE + 8)
      .height(QUICK_ZOOM_ITEM_SIZE + 8)
      .borderRadius(QUICK_ZOOM_ITEM_SIZE / 2 + 4)
      .draggable(false)
      .opacity(this.colorfulZoomRingOpacity)
  }

  @Builder
  quickZoomViewCircle() {
    Stack() {
      if (this.isShowColorfulZoomRing) {
        this.ColorfulZoomRing();
      }

      Circle()
        .width(QUICK_ZOOM_ITEM_SIZE)
        .height(QUICK_ZOOM_ITEM_SIZE)
        .fill($r('sys.color.ohos_id_color_bottom_tab_icon_auxcolor01'))
    }
    .width(QUICK_ZOOM_ITEM_SIZE)
    .height(QUICK_ZOOM_ITEM_SIZE)
    .position({ x: 4 + this.curValIndex * (32 + 8), y: QUICK_ZOOM_POSITION_Y })
    .animation((this.mZoomInnerStatus !== ZoomInnerStatus.QUICK_CLICK &&
      this.mZoomInnerStatus !== ZoomInnerStatus.QUICK_STATIC &&
      this.mZoomInnerStatus !== ZoomInnerStatus.FRONT_QUICK_SLIDE) ?
      undefined :
      {
        duration: 500,
        curve: curves.springMotion(0.314, 0.95),
        iterations: 1,
        playMode: PlayMode.Normal,
        onFinish: () => {
          if (this.isNeedVibratorWhenShowColorfulZoomRing) {
            this.isNeedVibratorWhenShowColorfulZoomRing = false;
            VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_GEAR_SLIP_HEAVY_ID);
          }
          HiLog.i(TAG, 'animation onFinish');
        }
      })
    .visibility(this.quickZoomValArr.length > 0 ? Visibility.Visible : Visibility.Hidden)
    .scale({ x: this.quickZoomScale, y: this.quickZoomScale })
    .key(`${ComponentIdKeys.QUICK_ZOOM_INDEX}${this.curValIndex}-choose`)
  }

  @Builder
  quickZoomView(): void {
    Row() { // Row快捷变焦点的父组件
      this.quickZoomViewCircle();
      ForEach(this.quickZoomValArr, (item: number, index: number = 0) => {
        this.quickForEachItem(item, index);
      })
    }
    .width(this.quickZoomValArrLength * (32 + 8))
    .height(40)
    .borderRadius(this.isShowSubScreenRadius ? 0 : 21)
    .margin({ bottom: this.getMarginBottom() })
    .backgroundColor('#664d4d4d')
    .opacity(this.mQuickOtherAlpha)
    .justifyContent(FlexAlign.Center)
    .visibility(this.getQuickZoomVisibility())
    .onClick((): void => { // QuickZoom空消费触摸事件,两侧不阻塞兄弟节点点击对焦事件
    })
    .key(ComponentIdKeys.QUICK_ZOOM_BAR)
    .enabled(this.state.uiEnable)
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
  }

  private getQuickZoomVisibility(): Visibility {
    return this.isShowQuickZoom && (!this.zoomIsHide || GlobalContext.get().getIsPicker()) &&
      !AppStorage.get('isPSDCollaps') ? Visibility.Visible : Visibility.Hidden;
  }

  @Builder
  quickForEachItem(item: number, index: number): void {
    Column() {
      if (this.enableScreenReader) {
        Column() {
          this.quickZoomItem(item, index);
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width(40)
        .height(40)
        .position({ x: -4, y: -4 })
        .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
        .accessibilitySelected(index === this.curValIndex)
        .accessibilityGroup(true)
        .accessibilityText(this.getAccessibilityText(item, index))
        .accessibilityRole(AccessibilityRoleType.BUTTON)
        .onClick((): void => {
          this.onZoomItemClick(item, index);
        })
      } else {
        Column() {
          this.quickZoomItem(item, index);
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .onTouch((event) => {
          if (this.isDepthFusionBarShow || this.isStitchingTypeBarShow) {
            return;
          }
          if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            if (this.mZoomInnerStatus === ZoomInnerStatus.FRONT_QUICK_SLIDE) {
              this.mZoomInnerStatus = ZoomInnerStatus.QUICK_STATIC;
            } else {
              this.quickZoomClickRespond(index);
            }
            // 由于onTouch的时序问题，为保证点切变焦后必定有一次unprepare
            this.touchUnprepareZoom();
          }
        })
      }
    }
    .width(QUICK_ZOOM_ITEM_SIZE)
    .height(QUICK_ZOOM_ITEM_SIZE)
    .position({ x: 4 + index * (32 + 8), y: QUICK_ZOOM_POSITION_Y })
    .justifyContent(FlexAlign.Center)
    .transition(ZoomOperation.getInstance().isZoomViewCreated ?
      TransitionEffect.asymmetric(
        index >= this.oldQuickZoomArrLength ?
          TransitionEffect.OPACITY
            .animation({
              duration: 800,
              curve: Curve.Friction
            }) : TransitionEffect.IDENTITY,
        index >= this.quickZoomValArr.length ?
          TransitionEffect.opacity(0.8)
            .animation({
              duration: 300,
              curve: Curve.Friction
            }) : TransitionEffect.IDENTITY
      ) : TransitionEffect.IDENTITY)
  }

  private onZoomItemClick(item: number, index: number) {
    AccessibilityUtils.sendAnnounceAccessibilityEvent(
      ResGetter.getStringSafe(`${
      ResGetter.getStringSafe($r('app.string.accessibility_checked'))} ${
      this.getQuickZoomABText(this.curZoomValue, this.curValIndex, item, index)}`));
    this.quickZoomClickRespond(index);
  }

  private getAccessibilityText(item: number, index: number): string {
    HiLog.i(TAG, `getAccessibilityText item = ${item}, index = ${index}`);
    return ResGetter.getStringSafe(this.isOpenTouchGuide ?
      `${this.getQuickZoomABText(this.curZoomValue, this.curValIndex, item, index)}` : '');
  }

  private getQuickZoomABText(mCurZoomValue: number, mCurValIndex: number, opticalZoomVal: number,
    index?: number): string {
    let realVal = mCurValIndex === index ? mCurZoomValue : opticalZoomVal;
    let showVal = this.roundOrSplitZoomVal(realVal);
    let firstQuickIsOneDecimalPlace = this.quickZoomValArr[0] === Math.floor(this.quickZoomValArr[0] * 10) / 10;
    if (index === 0 && this.quickZoomValArr[0] <= this.getQuickMaxZoomVarW() && (firstQuickIsOneDecimalPlace ?
      showVal <= this.quickZoomValArr[0] :
      (realVal === this.quickZoomValArr[0] || realVal < Math.ceil(this.quickZoomValArr[0] * 10) / 10))) {
      //  return '广角，单指双击即可切换，双击按住即可上下拖动'
      return ResGetter.getStringSafe($r('app.string.wide_angle')); // 避免前置0.8焦段
    }
    return getContext(this)
      .resourceManager
      .getPluralStringValueSync($r('app.plural.accessibility_tips_zoom_scale_new').id, showVal);
  }

  @Builder
  equivZoomBuilder(item: number, index: number) {
    Column() {
      Text(this.getQuickZoomFontText(this.curZoomValue, this.curValIndex, item, index)) // 快捷变焦字符显示
        .height(14)
        .maxFontScale(CommonConstants.TEXT_SIZE_NORMAL)
        .fontSize('11vp')
        .fontWeight(FontWeight.Bolder)
        .textShadow({
          radius: 2,
          color: '#29000000',
          offsetX: 0,
          offsetY: 0
        })
        .fontColor('#000000')
        .opacity(index === this.curValIndex ? 0.6 : 1)
        .fontFeature('\"ss01\" on')
      Text('mm')
        .height(8)
        .lineHeight(5)
        .maxFontScale(CommonConstants.TEXT_SIZE_NORMAL)
        .fontSize('9vp')
        .fontWeight(FontWeight.Bolder)
        .textShadow({
          radius: 2,
          color: '#29000000',
          offsetX: 0,
          offsetY: 0
        })
        .fontColor(index === this.curValIndex ? '#000000' : '#ffffff')
        .opacity(index === this.curValIndex ? 0.6 : 0)
        .fontFeature('\"ss01\" on')
    }
    .onDisAppear(() => {
      HiLog.i(TAG, `cycleClickZoom disAppear`)
    })
    .rotate({
      angle: this.rotateAngle +
        (this.isShowSemiCollapsed ?
          -180 : (this.isShowLandscape || DeviceInfo.isTablet() || this.isShowTricollaps) ? -90 : 0)
    })
  }

  @Builder
  commonQuickZoom(item: number, index: number) {
    // 广角缩放
    Text(this.getQuickZoomFontText(this.curZoomValue, this.curValIndex, item, index)) // 快捷变焦字符显示
      .height(17)
      .maxFontScale(CommonConstants.TEXT_SIZE_NORMAL)
      .fontSize('11vp')
      .fontWeight(index === this.curValIndex ? FontWeight.Bolder : FontWeight.Bold)
      .textShadow({
        radius: 2,
        color: index === this.curValIndex ? '#29000000' : '#33000000',
        offsetX: 0,
        offsetY: 0
      })
      .fontColor(index === this.curValIndex ? '#000000' : '#ffffff')
      .opacity(index === this.curValIndex ? 0.6 : 1)
      .animation({
        duration: 100,
        curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1)
      })
      .rotate({
        angle: this.rotateAngle +
          (this.state.isShowSemiCollapsed ?
            -180 : (this.isShowLandscape || DeviceInfo.isTablet() || this.isShowTricollaps) ? -90 : 0)
      })
      .key(ComponentIdKeys.QUICK_ZOOM_INDEX + index)
      .fontFeature('\"ss01\" on')
  }

  @Builder
  mixEquivZoomAndCommonZoom(item: number, index: number): void {
    if (this.isShowCycleClickZoom && index === this.curValIndex) {
      Row() {
        this.equivZoomBuilder(item, index);
      }
      .transition(this.getCycleClickZoomAnim())
    } else {
      Row() {
        this.commonQuickZoom(item, index);
      }
      .transition(this.getCommonZoomAnim())
    }
  }

  @Builder
  quickZoomItem(item: number, index: number): void {
    if (CameraAppCapability.getInstance().getIsSupportedCycleClickZoom()) {
      this.mixEquivZoomAndCommonZoom(item, index);
    } else {
      this.commonQuickZoom(item, index);
    }
  }

  private getQuickZoomFontText(mCurZoomValue: number, mCurValIndex: number, opticalZoomVal: number,
    index?: number): string {
    let realVal = mCurValIndex === index ? mCurZoomValue : opticalZoomVal;
    let showVal = this.roundOrSplitZoomVal(realVal);
    let firstQuickIsOneDecimalPlace = this.quickZoomValArr[0] === Math.floor(this.quickZoomValArr[0] * 10) / 10;
    if (this.isShowCycleClickZoom && index === mCurValIndex) {
      let zoomPointInfo: ZoomPointInfo = CameraProxy.getInstance().getZoomPointInfo();
      let curZoomInfo = Math.round(this.curZoomValue * zoomPointInfo?.equivalentFocalLength / 1);
      HiLog.i(TAG, `quickZoomClickShowEquivZoom : ${curZoomInfo}.`);
      return `${curZoomInfo}`;
    }
    if (index === 0 && this.quickZoomValArr[0] < 1.0 && (firstQuickIsOneDecimalPlace ?
      showVal <= this.quickZoomValArr[0] :
      (realVal === this.quickZoomValArr[0] || realVal < Math.ceil(this.quickZoomValArr[0] * 10) / 10))) {
      return 'W'; // 避免前置第二个焦段
    }
    return SystemLanguageUtil.isRTL() ? 'x' + showVal : showVal + 'x';
  }

  private quickZoomClickRespond(index: number): void {
    HiLog.i(TAG, `quickZoomClickRespond, index: ${index}, curValIndex: ${this.curValIndex}, mZoomInnerStatus:
     ${this.mZoomInnerStatus}, quickZoomValArr length: ${this.quickZoomValArr.length}.`);
    if (this.state.tabSelector !== FunctionId.NONE) {
      this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
    }
    if (this.mZoomInnerStatus !== ZoomInnerStatus.QUICK_STATIC &&
      this.mZoomInnerStatus !== ZoomInnerStatus.QUICK_CLICK) {
      return;
    }
    if (index === 0 && this.quickZoomValArr.length === 1) {
      this.mAction.changeZoomState(ZoomOuterStatus.ROULETTE_ZOOM);
      this.clearBigTextTimer();
      this.clearRouletteZoomTimer();
      if (this.isShowQuickZoom && !this.isShowRouletteZoom) {
        HiLog.d(TAG, 'only one quickZoom ClickRespond E.');
        this.mZoomInnerStatus = ZoomInnerStatus.QUICK_TO_ROULETTE;
        // 更新所有状态-务必保持动效初始状态
        this.updateAnimInitParam(1); // 动效起始参数初始化,避免delay异常
        this.createPlayNativeAnimator(1500, 1); // 开始触发帧回调刷新UI
        this.rouletteAppearExecQuickSelectedAndOpacityAnim(); // 长按出轮盘变焦,执行快捷变焦选中圆和其他不透明度动效
        this.rouletteAppearExecLongCurveHaloAnim(); // 长按出轮盘变焦,执行光晕动效
        this.rouletteAppearExecSphereAnim(); // 长按出轮盘变焦,执行光球动效
        this.rouletteAppearExecBigTextAnim(); // 长按出轮盘变焦,执行大字体动效
        this.rouletteAppearExecRedLineAndScaleAllAnim(); // 长按出轮盘变焦,执行焦圈中心刻度、焦圈动效
        this.rouletteAppearExecCarmenLineAnim(); // 长按出轮盘变焦,执行卡门线动效
        this.rouletteAppearExecQuickZoomOutsideAnim(); // 长按出轮盘变焦,执行快捷变焦圆外层动效
      }
      this.clearAndSetRouletteZoomTimer(); // 定时器内包含大字体
      return;
    }
    if (this.curValIndex !== index) {
      if (CameraAppCapability.getInstance().getIsSupportedCycleClickZoom() && this.isShowCycleClickZoomAndEquivZoom()) {
        this.isDuringCycleClick = true;
        this.doCycleClickZoomAnim(true);
        this.clearAndSetCycleClickTimer();
      }
      if (this.isAllowVibratorSound()) {
        VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
      }
      this.curZoomValue = this.quickZoomValArr[index];
      this.curValIndex = index;
      this.mZoomInnerStatus = ZoomInnerStatus.QUICK_CLICK;
      this.clickZoomDelivery(); // 点切变焦执行下发
      this.mAction.changeOtherComponent();
    } else {
      this.doCycleClickZoom();
      return;
    }
    // if (index === 0) {
    //   this.mAction.updateShowExposureAndFocusMoveFlag(false);
    // }
    if (this.isShowBigText) {
      this.clearAndSetBigTextTimer();
    } else {
      this.isShowBigText = true;
    }
  }

  @Builder
  touchRespondSectorHotZone(): void {
    Row() {
      Circle()
        .fillOpacity(0)
        .borderRadius(this.redLineTopRadius * 2 + 20)
        .width(this.redLineTopRadius * 2 + 20)
        .height(this.redLineTopRadius * 2 + 20)
        .position({
          x: (this.zoomWidth / 2 - this.redLineTopRadius - 10),
          y: this.redLineTopY - 10
        })
        .onTouch((event?: TouchEvent) => {
          this.nodeContainerOnTouch(event);
        })
        .key(ComponentIdKeys.RING_ZOOM_BAR)
        .onClick((): void => {
        }) // 空消费触摸事件
    }
    .width(this.zoomWidth)
    .height(150)
    .clip(true)
    .gesture(
      PanGesture({ fingers: 1, distance: 1 })
        .onActionStart((event?: GestureEvent) => {
          this.panGestureStart(event);
        })
        .onActionUpdate((event?: GestureEvent) => {
          this.panGestureUpdate(event);
        })
        .onActionEnd((event?: GestureEvent) => {
          if (this.isDepthFusionConflictLongPress) {
            this.isDepthFusionConflictLongPress = false;
            return;
          }

          this.panGestureEnd(event);
        })
        .onActionCancel((event?: GestureEvent) => {
          if (this.isDepthFusionConflictLongPress) {
            this.isDepthFusionConflictLongPress = false;
            return;
          }
          this.panGestureEnd(event);
        })
    )
  }

  @Builder
  bigTextView(): void {
    Text(this.getBigText())
      .fontSize(vp2px(px2fp(24)))
      .fontWeight(FontWeight.Medium)
      .width(this.zoomWidth)
      .height(40)
      .textAlign(TextAlign.Center)
      .textShadow({
        radius: 2,
        color: '#33000000',
        offsetX: 0,
        offsetY: 0
      })
      .fontColor(Color.White)
      .rotate({
        centerX: '50%',
        centerY: '50%',
        angle: this.rotateAngle +
          (this.state.isShowSemiCollapsed ? -180 : (this.isShowLandscape || DeviceInfo.isTablet()) ? -90 : 0)
      })
      .position(this.getBigTextPosition())
      .transition(this.getBigTextAppearDisappearAnim())
      .onAppear((): void => {
        if (this.mZoomInnerStatus === ZoomInnerStatus.QUICK_STATIC ||
          this.mZoomInnerStatus === ZoomInnerStatus.QUICK_CLICK ||
          this.mZoomInnerStatus === ZoomInnerStatus.FRONT_QUICK_SLIDE) {
          this.clearAndSetBigTextTimer(); // 设置定时器
        }
      })
      .onDisAppear((): void => {
      })
      .hitTestBehavior(HitTestMode.Transparent)
      .key(ComponentIdKeys.ZOOM_BIG_TEXT)
  }

  @Builder
  equivalentFocalZoomBigTextView(): void {
    Text(this.getBigText())
      .fontSize(vp2px(px2fp(24)))
      .fontWeight(FontWeight.Medium)
      .width(this.zoomWidth)
      .height(40)
      .textAlign(TextAlign.Center)
      .textShadow({
        radius: 2,
        color: '#33000000',
        offsetX: 0,
        offsetY: 0
      })
      .fontColor(Color.White)
      .transition(this.getAppearDisappearAnim(true))
      .onAppear((): void => {
        if (this.mZoomInnerStatus === ZoomInnerStatus.QUICK_STATIC ||
          this.mZoomInnerStatus === ZoomInnerStatus.QUICK_CLICK ||
          this.mZoomInnerStatus === ZoomInnerStatus.FRONT_QUICK_SLIDE) {
          this.clearAndSetBigTextTimer(); // 设置定时器
        }
      })
      .onDisAppear((): void => {
      })
      .hitTestBehavior(HitTestMode.Transparent)
      .key(ComponentIdKeys.ZOOM_BIG_TEXT)
  }

  @Builder
  equivalentFocalBigTextView(): void {
    Text(this.getEquivalentFocalBigText())
      .fontSize(vp2px(px2fp(18)))
      .fontWeight(FontWeight.Medium)
      .width(this.zoomWidth)
      .height(this.isDuringCycleClick ? 30 : 40)
      .textAlign(TextAlign.Center)
      .translate({ x: 0, y: -10 })
      .opacity(0.8)
      .textShadow({
        radius: 2,
        color: '#33000000',
        offsetX: 0,
        offsetY: 0
      })
      .visibility(this.getEquivalentFocalBigTextVis())
      .fontColor(Color.White)
      .transition(this.getAppearDisappearAnim(false))
      .onAppear((): void => {
        if (this.mZoomInnerStatus === ZoomInnerStatus.QUICK_STATIC ||
          this.mZoomInnerStatus === ZoomInnerStatus.QUICK_CLICK ||
          this.mZoomInnerStatus === ZoomInnerStatus.FRONT_QUICK_SLIDE) {
          this.clearAndSetBigTextTimer(); // 设置定时器
        }
      })
      .onDisAppear((): void => {
      })
      .hitTestBehavior(HitTestMode.Transparent)
      .key(ComponentIdKeys.EQUIVALENT_FOCAL_BIG_TEXT)
  }

  private isSupportedEquivalentFocalBigText(): boolean {
    if (!CameraAppCapability.getInstance().getIsSupportedEquivalentFocalBigText()) {
      return false;
    }
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT ||
      OutputSwitcher.getInstance().getOutput() === OutputType.VIDEO_OUTPUT) {
      return false;
    }
    return true;
  }

  private getEquivalentFocalBigTextVis(): Visibility {
    if (CameraAppCapability.getInstance().getIsSupportedCycleClickZoom()) {
      return this.opticalZoomValArr.indexOf(this.curZoomValue) !== -1 ? Visibility.Visible : Visibility.Hidden;
    }
    return Visibility.Visible;
  }

  private isNeedShowEquivalentFocalBigText(): boolean {
    if (!this.isSupportedEquivalentFocalBigText()) {
      return false;
    }
    if (this.curZoomValue >= POINT_ZOOM && this.curZoomValue - POINT_ZOOM < FOCAL_ZOOM_EPSILON) {
      return true;
    }
    return this.quickZoomValArr.some(zoom => Math.abs(zoom - this.curZoomValue) < FOCAL_ZOOM_EPSILON);
  }

  private getEquivalentFocalBigText(): string | Resource {
    HiLog.i(TAG, `getEquivalentFocalBigText: ${JSON.stringify(this.quickEquivalentFocalArr)}, ${this.curValIndex}}`);
    let tempValue = this.quickEquivalentFocalArr[this.calZoomValIndex()];
    if (this.curZoomValue >= POINT_ZOOM && this.curZoomValue - POINT_ZOOM < FOCAL_ZOOM_EPSILON) {
      tempValue = POINT_ZOOM_EQUIVALENT_FOCAL;
    }
    if (this.isDuringCycleClick) {
      let zoomPointInfo: ZoomPointInfo = CameraProxy.getInstance().getZoomPointInfo();
      tempValue = Math.round(this.curZoomValue * zoomPointInfo?.equivalentFocalLength / 1);
    }
    return SystemLanguageUtil.isRTL() ? `mm${tempValue}` : `${tempValue}mm`;
  }

  private getBigText(): string | Resource {
    let firstQuickIsOneDecimalPlace = this.quickZoomValArr[0] === Math.floor(this.quickZoomValArr[0] * 10) / 10;
    let quickZoomVarW = this.getQuickMaxZoomVarW();
    if (this.quickZoomValArr[0] <= quickZoomVarW && (firstQuickIsOneDecimalPlace ?
      Math.floor(this.curZoomValue * 10) / 10 <= this.quickZoomValArr[0] :
      (this.curZoomValue === this.quickZoomValArr[0] ||
        this.curZoomValue < Math.ceil(this.quickZoomValArr[0] * 10) / 10))) { // 避免前置第二个焦段
      return $r('app.string.wide_angle');
    }
    let tempValue = this.roundOrSplitZoomVal(this.curZoomValue);
    if (Number.isInteger(tempValue)) {
      return SystemLanguageUtil.isRTL() ? `x${tempValue}.0` : `${tempValue}.0x`;
    }
    return SystemLanguageUtil.isRTL() ? `x${tempValue}` : `${tempValue}x`;
  }

  private getABText(): string {
    let firstQuickIsOneDecimalPlace = this.quickZoomValArr[0] === Math.floor(this.quickZoomValArr[0] * 10) / 10;
    if (this.quickZoomValArr[0] <= this.getQuickMaxZoomVarW() && (firstQuickIsOneDecimalPlace ?
      Math.floor(this.curZoomValue * 10) / 10 <= this.quickZoomValArr[0] :
      (this.curZoomValue === this.quickZoomValArr[0] ||
        this.curZoomValue < Math.ceil(this.quickZoomValArr[0] * 10) / 10))) { // 避免前置第二个焦段
      return ResGetter.getStringSafe($r('app.string.wide_angle'));
    }
    let tempValue = this.roundOrSplitZoomVal(this.curZoomValue);
    return getContext(this)
      .resourceManager
      .getPluralStringValueSync($r('app.plural.accessibility_tips_zoom_scale_new').id, tempValue);
  }

  private getBigTextPosition(): Position {
    if (!this.isLandscapeIndex() && getStates().get<boolean>('customFilterStyleReducer', 'customFilterCardOpened')) {
      let windowStatus = getStates().get<window.WindowStatusType>('windowReducer', 'windowStatus');
      if (windowStatus === window.WindowStatusType.FLOATING) {
        let indicatorLocationY = this.currentFootBarLocation - INDICATOR_HEIGHT - DISTANCE_INDICATOR_FOOTBAR +
        this.layoutService.previewPosition;
        return {
          x: 0,
          y: -this.zoomLocation + (indicatorLocationY - this.layoutService.previewPosition) / 2 +
          this.layoutService.previewPosition + this.customFilterTopLineHeight - ZOOM_VIEW_HEIGHT / 2
        }
      }
      let xComponentWidth = getStates().get<number>('previewReducer', 'xComponentWidth');
      return {
        x: 0,
        y: -this.layoutService.rouletteZoomPosition + this.layoutService.previewPosition1to1 +
          (xComponentWidth - ZOOM_VIEW_HEIGHT) / 2
      }
    }
    if (this.isLemCollaps) {
      return AppStorage.get('isPSDCollaps') ? { x: 0, y: -this.windowHeight } : { x: 0, y: -214 };
    }
    if (this.state.isShowLowAngleShotView && this.state.isShowSemiCollapsed) {
      const componentSize: Size = CameraBasicService.getInstance().getSemiDisplaySize(this.state.mode);
      if (componentSize.width === 0) {
        HiLog.e(TAG, 'componentSizeWidth error, value: 0.');
        return { x: 0, y: 0 };
      }
      if (Math.abs(componentSize.height / componentSize.width - 4 / 3) < EPSILON) {
        return {
          x: 0,
          y: -this.drawHeight + 80 - 40 - 33 - 14 - 34 // - 34 是为了调整数字位置，预览在悬浮态下屏不被截断
        };
      }
    }
    return {
      x: 0,
      y: -this.drawHeight + 80 - 40 - 33 - 14 // - 14 是为了调整数字位置，屏展开态，录像1080p时不被截断
    };
  }

  private getAppearDisappearAnim(isBigText: boolean): TransitionEffect {
    if (!CameraAppCapability.getInstance().getIsSupportedEquivalentFocalBigText() ||
      !CameraAppCapability.getInstance().getIsSupportedCycleClickZoom()) {
      return this.getBigTextAppearDisappearAnim();
    }
    if (this.mZoomInnerStatus === ZoomInnerStatus.QUICK_STATIC ||
      this.mZoomInnerStatus === ZoomInnerStatus.QUICK_CLICK) {
      // 点切视为一个整体由父组件设置动效
      return TransitionEffect.IDENTITY;
    }
    if (!isBigText && (this.mZoomInnerStatus === ZoomInnerStatus.ROULETTE_SLIDE ||
      this.mZoomInnerStatus === ZoomInnerStatus.PINCH_ZOOM)) {
      // 等效焦距划切进场动效取消移动, 只淡入
      return TransitionEffect.asymmetric(
        TransitionEffect.OPACITY
          .animation({
            duration: 100,
            curve: Curve.Friction
          }),
        TransitionEffect.OPACITY
          .animation({
            duration: 100,
            curve: Curve.Sharp
          })
      );
    }
    // 大字体划切动效
    return TransitionEffect.asymmetric(
      TransitionEffect // 大字体进场动效
        .translate({ x: 0, y: -2 })
        .animation({
          duration: 300,
          curve: Curve.Friction
        })
        .combine(TransitionEffect.OPACITY
          .animation({
            duration: 100,
            curve: Curve.Friction
          })),
      TransitionEffect.OPACITY // 大字体退场动效
        .animation({
          duration: 100,
          curve: Curve.Sharp
        })
    );
  }

  private getFatherBigTextAnim(): TransitionEffect {
    HiLog.i(TAG, `getFatherBigTextAnim: ${this.mZoomInnerStatus}.`);
    if (this.mZoomInnerStatus === ZoomInnerStatus.QUICK_STATIC ||
      this.mZoomInnerStatus === ZoomInnerStatus.QUICK_CLICK) {
      return TransitionEffect.asymmetric(
        TransitionEffect // 大字体进场动效
          .scale({ x: 0.9, y: 0.9 })
          .animation({
            duration: 500,
            curve: curves.cubicBezierCurve(0.2, 0, 0.2, 1)
          })
          .combine(TransitionEffect.OPACITY
            .animation({
              duration: 100,
              curve: Curve.Sharp
            })),
        TransitionEffect // 大字体退场动效
          .scale({ x: 0.9, y: 0.9 })
          .animation({
            duration: 250,
            curve: curves.cubicBezierCurve(0.2, 0, 0.2, 1)
          })
          .combine(TransitionEffect.OPACITY
            .animation({
              duration: 250,
              curve: curves.cubicBezierCurve(0, 0, 0, 1)
            }))
      );
    }

    return TransitionEffect.IDENTITY;
  }

  private getBigTextAppearDisappearAnim(): TransitionEffect {
    if (this.mZoomInnerStatus === ZoomInnerStatus.QUICK_STATIC ||
      this.mZoomInnerStatus === ZoomInnerStatus.QUICK_CLICK) {
      return TransitionEffect.asymmetric(
        TransitionEffect // 大字体进场动效
          .scale({ x: 0.9, y: 0.9 })
          .animation({
            duration: 500,
            curve: curves.cubicBezierCurve(0.2, 0, 0.2, 1)
          })
          .combine(TransitionEffect.OPACITY
            .animation({
              duration: 100,
              curve: Curve.Sharp
            })),
        TransitionEffect // 大字体退场动效
          .scale({ x: 0.9, y: 0.9 })
          .animation({
            duration: 250,
            curve: curves.cubicBezierCurve(0.2, 0, 0.2, 1)
          })
          .combine(TransitionEffect.OPACITY
            .animation({
              duration: 250,
              curve: curves.cubicBezierCurve(0, 0, 0, 1)
            }))
      );
    }
    return TransitionEffect.asymmetric(
      TransitionEffect // 大字体进场动效
        .translate({ x: 0, y: -2 })
        .animation({
          duration: 300,
          curve: Curve.Friction
        })
        .combine(TransitionEffect.OPACITY
          .animation({
            duration: 100,
            curve: Curve.Friction
          })),
      TransitionEffect.OPACITY // 大字体退场动效
        .animation({
          duration: 100,
          curve: Curve.Sharp
        })
    );
  }

  private updateAnimInitParam(animType: number): void {
    HiLog.i(TAG, `updateAnimInitParam animType: ${animType}.`);
    this.longCurveHaloMatteScale = animType === 1 ? 0 : 1;
    this.longCurveHaloOpacity = animType === 1 ? 0 : 1;
    this.spherePosition = animType === 1 ? 8 : 0; // 入场动效,向上归位; 退场动效,向下退出
    this.sphereScale = animType === 1 ? 0 : 1;
    this.sphereColor = animType === 1 ? 0 : 1;
    this.sphereHaloOpacity = animType === 1 ? 0 : 0.5; // 光球-光晕,0.5驻场及退场
    this.redLineAndTextOpacity = animType === 1 ? 0 : 1;
    this.scaleAllMatteScale = animType === 1 ? 0 : 1;
    this.scaleAllOpacity = animType === 1 ? 0 : 1;
    this.carmenLineMatteScale = animType === 1 ? 0 : 1;
    this.carmenLineOpacity = animType === 1 ? 0 : 1;
  }

  // 创建/重置并开启native动效执行器
  private createPlayNativeAnimator(mDuration: number, mAnimType: number): void {
    HiLog.d(TAG, 'createPlayNativeAnimator E.');
    if (mAnimType === 1 && !this.isShowBigText) {
      this.clearBigTextTimer();
      this.isShowBigText = true;
    }
    // 变焦环收起动效30fps绘帧，大帧数目减半，降低RS绘帧压力，降低预览卡顿概率
    const expectedFrameRate: ExpectedFrameRateRange = {
      min: 0,
      max: 120,
      expected: 30
    }
    let options: AnimatorOptions = {
      duration: mDuration,
      easing: 'friction',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: 0,
      end: 1
    };
    if (this.mStateChangeAnimator) {
      try {
        this.mStateChangeAnimator.reset(options);
      } catch (error) {
        HiLog.e(TAG, `createPlayNativeAnimator error: ${error?.code}.`);
      }
    } else {
      this.mStateChangeAnimator = animator.create(options);
    }
    this.mStateChangeAnimator.setExpectedFrameRateRange(expectedFrameRate);
    this.mStateChangeAnimator.onFinish = () => {
      if (!this.mNodeController?.getIsTextParallel2CarmenLine() && mAnimType === 1) {
        HiLog.i(TAG, `createPlayNativeAnimator getIsTextParallel2CarmenLine mAnimType: ${mAnimType}.`);
        this.mNodeController?.execLandscapeSlideExpandAnim(this.curZoomValue); // 横屏滑动关键刻度展开动效
      }
      this.nativeAnimatorOnFinish(mAnimType);
    };
    this.mStateChangeAnimator.onFrame = (value) => {
      this.nativeAnimatorOnFrame(mAnimType);
    };
    this.mStateChangeAnimator?.play();
  }

  private nativeAnimatorOnFinish(mAnimType: number): void {
    HiLog.i(TAG, `createPlayNativeAnimator finish AnimType: ${mAnimType}, InnerStatus: ${this.mZoomInnerStatus}.`);
    if (mAnimType === 1 && this.mZoomInnerStatus === ZoomInnerStatus.QUICK_TO_ROULETTE) {
      this.mZoomInnerStatus = ZoomInnerStatus.ROULETTE_STATIC;
    } else if (mAnimType === 2 && this.mZoomInnerStatus === ZoomInnerStatus.ROULETTE_TO_QUICK) {
      if (this.isShowBigText && !this.isSelfieStickLongPress && !this.isSelfieStickShortPress) {
        this.isShowBigText = false;
      }
      this.mZoomInnerStatus = ZoomInnerStatus.QUICK_STATIC;
    }
  }

  private nativeAnimatorOnFrame(mAnimType: number): void {
    HiLog.d(TAG, `createPlayNativeAnimator onframe AnimType: ${mAnimType}, InnerStatus: ${this.mZoomInnerStatus}.`);
    if (!this.isShowRouletteZoom || !this.curZoomValue ||
      (mAnimType === 1 && this.mZoomInnerStatus !== ZoomInnerStatus.QUICK_TO_ROULETTE) ||
      (mAnimType === 2 && this.mZoomInnerStatus !== ZoomInnerStatus.ROULETTE_TO_QUICK)) {
      return;
    }
    try {
      this.mNodeController?.invalidate(this.curZoomValue, 1000, this.getAnimParamData(mAnimType)); // 数据小容器传递
    } catch (err) {
      HiLog.e(TAG, `NodeController invalidate err: ${err}.`);
    }
  }

  private getAnimParamData(mAnimType: number): EntryExitAnimParam {
    return {
      longCurveHaloMatteScale: this.longCurveHaloMatteScale,
      longCurveHaloOpacity: this.longCurveHaloOpacity,
      spherePosition: this.spherePosition,
      sphereScale: this.sphereScale,
      sphereColor: this.sphereColor,
      sphereHaloOpacity: this.sphereHaloOpacity,
      redLineAndTextOpacity: this.redLineAndTextOpacity,
      scaleAllMatteScale: this.scaleAllMatteScale,
      scaleAllOpacity: this.scaleAllOpacity,
      carmenLineMatteScale: this.carmenLineMatteScale,
      carmenLineOpacity: this.carmenLineOpacity,
      animType: mAnimType,
    };
  }

  // 创建/重置并开启frame各动效执行器
  private createPlayFrameAnimators(index: number, mDelay: number, mEasing: string, mDuration: number, mBegin:
    number, mEnd: number, frameCallback: Function, finishCallback?: Function): void {
    let options: AnimatorOptions = {
      duration: mDuration,
      easing: mEasing,
      delay: mDelay,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: mBegin,
      end: mEnd
    };
    if (this.mFrameAnimResultArr[index]) {
      try {
        (this.mFrameAnimResultArr[index] as AnimatorResult).reset(options);
      } catch (error) {
        HiLog.i(TAG, `createPlayFrameAnimators error: ${error}.`);
      }
    } else {
      this.mFrameAnimResultArr[index] = animator.create(options);
    }
    (this.mFrameAnimResultArr[index] as AnimatorResult).onFinish = () => {
      HiLog.d(TAG, `createPlayFrameAnimators finish index: ${index}.`);
      if (finishCallback) {
        finishCallback();
      }
    };
    (this.mFrameAnimResultArr[index] as AnimatorResult).onFrame = (value: number) => {
      frameCallback(value);
    };
    (this.mFrameAnimResultArr[index] as AnimatorResult)?.play();
  }

  // 清除native、frame动效执行器
  private cancelNativeAndFrameAnimators(): void {
    HiLog.d(TAG, 'cancelNativeAndFrameAnimators E.');
    this.mStateChangeAnimator?.cancel();
    for (let i = 0; i < this.mFrameAnimResultArr.length; i++) {
      this.mFrameAnimResultArr[i]?.cancel();
    }
  }

  private getZoomViewWidth(): number {
    let curMode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
    let isOverlap: boolean = (curMode === ModeType.PHOTO || curMode === ModeType.VIDEO);
    if (this.quickZoomValArr.length === 5 && isOverlap) { // 快捷变焦点为5个的话，考虑到部分模式与左右响应区重叠，重新调整响应区大小
      return this.isShowRouletteZoom ? this.zoomWidth :
        this.quickZoomValArr.length * (32 + 8) + 2 * QUICK_ZOOM_MARGIN_LR_SHORT;
    } else {
      return this.isShowRouletteZoom ? this.zoomWidth :
        this.quickZoomValArr.length * (32 + 8) + 2 * QUICK_ZOOM_MARGIN_LR_LONG;
    }
  }

  @Builder
  equivalentZoomBigText() {
    Column() {
      this.equivalentFocalZoomBigTextView();
      if (this.isNeedShowEquivalentFocalBigText() || this.isDuringCycleClick) {
        this.equivalentFocalBigTextView();
      }
    }
    .width(this.zoomWidth)
    .height(80)
    .position(this.getBigTextPosition())
    .transition(this.getFatherBigTextAnim())
    .rotate({
      centerX: '50%',
      centerY: '50%',
      angle: this.rotateAngle +
        (this.isShowSemiCollapsed ? -180 :
          (this.isShowLandscape || DeviceInfo.isTablet()) ? -90 : 0)
    })
    .hitTestBehavior(HitTestMode.Transparent)
  }

  /**
   * 变焦组件渲染规则: 快捷变焦组件与轮盘变焦条组件, 实现按需加载、部分渲染降低负载, 提升UI渲染性能;
   */
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.isShowQuickZoom) {
        this.quickZoomView();
      }

      if (this.isShowRouletteZoom &&
        ((!this.isLandscapeIndex() ? !this.isCustomFilterImmersive : true) ||
        GlobalContext.get().getIsPicker())) {
        NodeContainer(this.mNodeController)
          .width(this.zoomWidth)
          .height(150)
        this.touchRespondSectorHotZone();
      }

      if (this.isShowBigText && !this.isDuringCycleClick) {
        if (!this.isSupportedEquivalentFocalBigText()) {
          this.bigTextView();
        } else {
          this.equivalentZoomBigText();
        }
      }
      if (this.isShowBigText && this.isDuringCycleClick) {
        this.equivalentZoomBigText();
      }

      Column()
        .width(this.getZoomViewWidth())
        .height(this.isVdeLandscape ? 60 : this.isShowRouletteZoom ? 80 : 78)
        .offset({ y: this.isShowRouletteZoom ? 0 : -4 })
        .hitTestBehavior(HitTestMode.Transparent)
        .enabled(this.state.uiEnable)
        .key(ComponentIdKeys.ROULETTE_ZOOM_VIEW_COLUMN)
        .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
        .visibility((this.zoomIsHide && !GlobalContext.get().getIsPicker()) ? Visibility.Hidden :
          Visibility.Visible)
        .opacity(this.zoomOpacity)
        .onTouch((event) => {
          if (event.type === TouchType.Move) {
            return;
          }
          if (event.type === TouchType.Down) {
            this.touchPrepareZoom();
            return;
          }
          if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.touchUnprepareZoom();
          }
        })
        .gesture(
          PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Horizontal })
            .onActionStart((event?: GestureEvent) => {
              this.isDuringCycleClick = false;
              this.doCycleClickZoomAnim(false);
              this.panGestureStart(event);
              if (this.state.tabSelector !== FunctionId.NONE) {
                this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
              }
            })
            .onActionUpdate((event?: GestureEvent) => {
              this.panGestureUpdate(event);
            })
            .onActionEnd((event?: GestureEvent) => {
              if (this.isDepthFusionConflictLongPress) {
                this.isDepthFusionConflictLongPress = false;
                return;
              }

              this.panGestureEnd(event);
              if (this.enableScreenReader) {
                // 滚动条自动播报
                AccessibilityUtils.sendAnnounceAccessibilityEvent(this.getABText())
              }
            })
            .onActionCancel((event?: GestureEvent) => {
              if (this.isDepthFusionConflictLongPress) {
                this.isDepthFusionConflictLongPress = false;
                return;
              }
              this.panGestureEnd(event);
            }))
        .parallelGesture(
          LongPressGesture({ repeat: false, duration: 300 })
            .onAction((event?: GestureEvent) => {
              this.longPressGestureAction(event);
              if (this.state.tabSelector !== FunctionId.NONE) {
                this.mAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE);
              }
            })
            .onActionEnd((event?: GestureEvent) => {
              this.longPressGestureActionEnd(event);
            })
            .onActionCancel((event?: GestureEvent) => {
              this.longPressGestureActionEnd(event);
            }))
    }
    .onTouch((event: TouchEvent) => { // 变焦组件不在预览区域时，慢动作全焦段扩展变焦模糊没有截图
      if (event.type !== TouchType.Down) {
        return;
      }
      BlurAnimateUtil.generatePixelMapFromSurface();
    })
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
    // 开启屏幕朗读并且非平板
    .key(ComponentIdKeys.ROULETTE_ZOOM_VIEW_STACK)
    .width(this.zoomWidth)
    .height(this.isVdeLandscape ? 60 : 80)
    .offset(this.isShowLandscape ? { x: this.mQuickOffsetY } : undefined)
  }

  private touchPrepareZoom(): void {
    this.changeZoomFunctionValue({ zoomRatio: undefined, isPrepareZoom: true });
  }

  private touchUnprepareZoom(): void {
    this.changeZoomFunctionValue({
      zoomRatio: undefined,
      isUnprepareZoom: true,
      unprepareDelay: ZoomParam.UNPREPARE_DELAY_TIME
    });
  }

  private nodeContainerOnTouch(event?: TouchEvent): void {
    if (!event || event.type === TouchType.Move) {
      return;
    }
    if (event.type === TouchType.Down && this.mZoomInnerStatus === ZoomInnerStatus.ROULETTE_STATIC) {
      this.touchPrepareZoom();
      if (this.isAllowVibratorSound()) {
        VibratorService.getInstance().triggerVibrator(VibratorService.MODE_SWITCH_EFFECT_ID);
      }
      this.clearBigTextTimer();
      this.clearRouletteZoomTimer();
      return;
    }
    if ((event.type === TouchType.Up || event.type === TouchType.Cancel)) {
      if (this.mZoomInnerStatus === ZoomInnerStatus.ROULETTE_STATIC) {
        let centreDiffTouchX = this.redLineTopRadius + 10 - event.touches[0].x;
        let x = Math.abs(centreDiffTouchX);
        let y = this.redLineTopRadius + 10 - event.touches[0].y;
        let clickDotRadialLen = Math.sqrt(x * x + y * y);
        let alpha = Math.asin(x / clickDotRadialLen) * (centreDiffTouchX > 0 ? -1 : 1);

        let curZoomAngle: number = this.calZoomAngle(this.curZoomValue);
        let nextZoomAngle = curZoomAngle - alpha * 180 / Math.PI;
        let nextZoomValue = this.calZoomValue(nextZoomAngle);
        let pickIndex = -1; // 光学变焦点附近吸附
        for (let i = 0; i < this.opticalZoomDotAngleArr.length; i++) {
          if (Math.abs(nextZoomAngle - this.opticalZoomDotAngleArr[i]) <= ZoomParam.SCALE_GAP_ANGLE * 3) {
            pickIndex = i;
            break;
          }
        }

        if ((nextZoomValue < this.opticalZoomValArr[0] ||
          nextZoomValue > this.opticalZoomValArr[this.opticalZoomValArr.length - 1]) && pickIndex !== -1) {
          this.clearAndSetRouletteZoomTimer(); // 定时器内包含大字体
          this.touchUnprepareZoom();
          return;
        }
        this.execRouletteClickRespondAnim(pickIndex, nextZoomValue);
        this.touchUnprepareZoom();
        this.mAction.changeOtherComponent();
      } else {
        this.touchUnprepareZoom();
      }
    }
  }

  private execRouletteClickRespondAnim(pickIndex: number, nextZoomValue: number): void {
    let oldZoomValue = this.curZoomValue;
    if (pickIndex !== -1) {
      this.curZoomValue = this.opticalZoomValArr[pickIndex];
    } else {
      this.curZoomValue = nextZoomValue;
    }
    this.curValIndex = this.calZoomValIndex(); // 当前变焦值在快捷变焦点列表的index下界
    this.clickZoomDelivery(); // 点切变焦平滑曲线下发
    let options: AnimatorOptions = {
      duration: 400,
      easing: 'friction',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: 0,
      end: 1
    };
    if (this.mStateChangeAnimator !== null) {
      try {
        this.mStateChangeAnimator.reset(options);
      } catch (error) {
        HiLog.e(TAG, `createPlayNativeAnimator error: ${error?.code}.`);
      }
    } else {
      this.mStateChangeAnimator = animator.create(options);
    }
    this.mStateChangeAnimator.onFinish = () => {
      this.clearAndSetRouletteZoomTimer(); // 定时器内包含大字体
      if (!this.mNodeController?.getIsTextParallel2CarmenLine()) {
        this.mNodeController?.execLandscapeSlideExpandAnim(this.curZoomValue); // 横屏滑动关键刻度展开动效
      }
    };
    this.mStateChangeAnimator.onFrame = (value) => {
      if (!this.isShowRouletteZoom || !this.curZoomValue) {
        return;
      }
      try {
        this.mNodeController?.invalidate((this.curZoomValue - oldZoomValue) * value + oldZoomValue, 1000); // 数据小容器传递
      } catch (err) {
        HiLog.e(TAG, `NodeController invalidate err: ${err}.`);
      }
    };
    this.mStateChangeAnimator?.play();
  }

  private longPressGestureAction(event?: GestureEvent): void {
    if (!event || this.isBlockGestureEvent()) {
      return;
    }
    if (this.isDepthFusionBarShow) {
      this.isDepthFusionConflictLongPress = true;
      HiLog.i(TAG, 'depthFusion conflict longPress');
      return;
    }
    this.mAction.uiStateWithMode(false);
    if (!this.state.isImmersive) {
      this.mAction.isEnterImmersive(true);
    }
    this.mAction.changeZoomState(ZoomOuterStatus.ROULETTE_ZOOM);
    this.clearBigTextTimer();
    this.clearRouletteZoomTimer();
    if (this.isShowQuickZoom && !this.isShowRouletteZoom) {
      HiLog.d(TAG, 'outer LongPressGesture onAction E.');
      this.mZoomInnerStatus = ZoomInnerStatus.QUICK_TO_ROULETTE;
      // 更新所有状态-务必保持动效初始状态
      this.updateAnimInitParam(1); // 动效起始参数初始化,避免delay异常
      this.createPlayNativeAnimator(1500, 1); // 开始触发帧回调刷新UI
      this.rouletteAppearExecQuickSelectedAndOpacityAnim(); // 长按出轮盘变焦,执行快捷变焦选中圆和其他不透明度动效
      this.rouletteAppearExecLongCurveHaloAnim(); // 长按出轮盘变焦,执行光晕动效
      this.rouletteAppearExecSphereAnim(); // 长按出轮盘变焦,执行光球动效
      this.rouletteAppearExecBigTextAnim(); // 长按出轮盘变焦,执行大字体动效
      this.rouletteAppearExecRedLineAndScaleAllAnim(); // 长按出轮盘变焦,执行焦圈中心刻度、焦圈动效
      this.rouletteAppearExecCarmenLineAnim(); // 长按出轮盘变焦,执行卡门线动效
      this.rouletteAppearExecQuickZoomOutsideAnim(); // 长按出轮盘变焦,执行快捷变焦圆外层动效
    }
  }

  private longPressGestureActionEnd(event?: GestureEvent): void {
    if (!event || this.isBlockGestureEvent() || this.isDepthFusionConflictLongPress) {
      this.isDepthFusionConflictLongPress = false;
      return;
    }
    this.mAction.isEnterImmersive(false);
    this.mAction.uiStateWithMode(true);
    this.mAction.changeOtherComponent();

    this.clearAndSetRouletteZoomTimer(); // 定时器内包含大字体
    this.curValIndex = this.calZoomValIndex(); // 当前变焦值在快捷变焦点列表的index下界
  }

  // 长按出轮盘变焦,执行快捷变焦选中圆和其他不透明度动效
  private rouletteAppearExecQuickSelectedAndOpacityAnim(): void {
    if (this.quickZoomScale === 0) {
      this.quickZoomScale = 1;
    }
    animateToImmediately({
      // 快捷变焦-选中圆: scale 1-0.9; 0-150ms
      curve: Curve.Friction,
      duration: 150,
      onFinish: () => {
        this.isShowRouletteZoom = true;
      }
    }, () => {
      this.quickZoomScale = 0.9;
    });

    animateToImmediately({
      // 快捷变焦-选中圆: scale 0.9-1; 150ms-300ms
      delay: 150,
      curve: Curve.Sharp,
      duration: 150
    }, () => {
      this.quickZoomScale = 1;
    });

    animateToImmediately({
      delay: 200,
      curve: Curve.Sharp,
      duration: 250,
      onFinish: () => {
        if (this.mZoomInnerStatus === ZoomInnerStatus.QUICK_TO_ROULETTE) {
          this.isShowQuickZoom = false;
        }
      }
    }, () => {
      this.quickZoomAlpha = 0; // 快捷变焦-选中圆: opacity 1-0; 200ms-450ms
      this.mQuickOtherAlpha = 0; // 快捷变焦-其他: opacity 1-0; 200ms-450ms
    });
  }

  // 长按出轮盘变焦,执行光晕动效
  private rouletteAppearExecLongCurveHaloAnim(): void {
    this.createPlayFrameAnimators(0, 250, 'friction', 1250, 0, 1, (frameValue: number) => {
      this.longCurveHaloMatteScale = frameValue; // 光晕: 遮罩scale 0-1; 250-1500ms
    });

    this.createPlayFrameAnimators(1, 250, 'sharp', 100, 0, 1,
      (frameValue: number) => {
        this.longCurveHaloOpacity = frameValue; // 光晕: opacity 0-1; 250-350ms
      },
      () => {
        this.mFrameAnimResultArr[1] = null;
        this.createPlayFrameAnimators(1, 650, 'sharp', 500, 1, 0, (frameValue: number) => { // 生命周期内禁止reset自身对象
          this.longCurveHaloOpacity = frameValue; // 光晕: opacity 1-0; 1000-1500ms
        });
      });
  }

  // 长按出轮盘变焦,执行光球动效
  private rouletteAppearExecSphereAnim(): void {
    this.createPlayFrameAnimators(2, 350, 'friction', 500, 8, 0, (frameValue: number) => {
      this.spherePosition = frameValue; // 光球: 位移 向上8vp归位; 350-850ms
    });

    this.createPlayFrameAnimators(3, 150, 'friction', 350, 0, 1, (frameValue: number) => {
      this.sphereScale = frameValue; // 光球: scale 0-1; 150-500ms
    });

    this.createPlayFrameAnimators(4, 150, 'friction', 200, 0, 1, (frameValue: number) => {
      this.sphereColor = frameValue; // 光球: color E4E3E2-FFFFFF; 150-350ms; 使用0-1映射
    });

    this.createPlayFrameAnimators(5, 150, 'friction', 200, 0, 1,
      (frameValue: number) => {
        this.sphereHaloOpacity = frameValue; // 光球-光晕: opacity 0-1; 150-350ms
      },
      () => {
        this.mFrameAnimResultArr[5] = null;
        this.createPlayFrameAnimators(5, 0, 'sharp', 350, 1, 0.5, (frameValue: number) => { // 生命周期内禁止reset自身对象
          this.sphereHaloOpacity = frameValue; // 光球-光晕: opacity 1-0.5; 350-700ms
        });
      });
  }

  // 长按出轮盘变焦,执行大字体动效
  private rouletteAppearExecBigTextAnim(): void {
    setTimeout((): void => { // 大字体: 位移 向下位移2vp归位 400-700ms、opacity 0-1; 400-500ms
      if (!this.isShowBigText) {
        this.clearBigTextTimer();
        this.isShowBigText = true;
      }
    }, 400);
  }

  // 长按出轮盘变焦,执行焦圈中心刻度、焦圈动效
  private rouletteAppearExecRedLineAndScaleAllAnim(): void {
    this.createPlayFrameAnimators(6, 400, 'friction', 100, 0, 1, (frameValue: number) => {
      this.redLineAndTextOpacity = frameValue; // 焦圈中心刻度: opacity 0-1; 400-500ms
    });

    this.createPlayFrameAnimators(7, 400, 'friction', 600, 0, 1, (frameValue: number) => {
      this.scaleAllMatteScale = frameValue; // 焦圈: 遮罩scale 0-1; 400-1000ms
    });

    this.createPlayFrameAnimators(8, 400, 'sharp', 100, 0, 1, (frameValue: number) => {
      this.scaleAllOpacity = frameValue; // 焦圈: opacity 0-1; 400-500ms
    });
  }

  // 长按出轮盘变焦,执行卡门线动效
  private rouletteAppearExecCarmenLineAnim(): void {
    this.createPlayFrameAnimators(10, 300, 'sharp', 100, 0, 1,
      (frameValue: number) => {
        this.carmenLineOpacity = frameValue; // 卡门线: opacity 0-1; 300-400ms
      },
      () => {
        this.createPlayFrameAnimators(9, 0, 'friction', 600, 0, 1, (frameValue: number) => {
          this.carmenLineMatteScale = frameValue; // 卡门线: 遮罩scale 0-1; 400-1000ms
        });
      });
  }

  // 长按出轮盘变焦,执行快捷变焦圆外层动效
  private rouletteAppearExecQuickZoomOutsideAnim(): void {
    if (this.mQuickZoomBlur === 1) {
      this.mQuickZoomBlur = 0;
    }
    if (this.mQuickZoomPositionY === 0) {
      this.mQuickZoomPositionY = -2;
    }
    animateToImmediately({
      delay: 200,
      curve: Curve.Friction,
      duration: 250
    }, () => {
      this.mQuickZoomBlur = 1; // 快捷变焦圆: 模糊 0-1; 200-450ms
      this.mQuickZoomPositionY = 0; // 快捷变焦圆: 位移 向上?2vp归位; 200-450ms
    });

    if (this.mQuickZoomOverColor === 1) {
      this.mQuickZoomOverColor = 0;
    }
    animateToImmediately({
      // 快捷变焦圆: 叠加颜色 0-1; 300-450ms
      delay: 300,
      curve: Curve.Friction,
      duration: 150
    }, () => {
      this.mQuickZoomOverColor = 1;
    });
  }

  private isBlockGestureEvent(): boolean {
    // if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT &&
    //   !CameraAppCapability.getInstance().getIsSupportedFrontZoomSlide()) {
    //   return true;
    // }
    return false;
  }

  /**
   * 轮盘变焦条滑动手势Start回调
   * */
  private panGestureStart(event?: GestureEvent): void {
    HiLog.d(TAG, 'PanGesture onActionStart.');
    if (!event || this.isSelfieStickLongPress) {
      return;
    }
    if (this.isDepthFusionBarShow) {
      this.isDepthFusionConflictLongPress = true;
      HiLog.i(TAG, 'depthFusion conflict pan');
      return;
    }
    this.onProHideTreasureBox(true);
    if (this.selector !== FunctionId.NONE) {
      HiLog.i(TAG, `close second Treasure selector: ${this.selector}`);
      this.mAction.closeSecondTreasure();
    }
    if (this.isBlockGestureEvent()) {
      if (event.offsetX > 0) {
        this.quickZoomClickRespond(this.curValIndex < this.quickZoomValArr.length - 1 ? this.curValIndex + 1 :
          this.quickZoomValArr.length - 1);
      }
      if (event.offsetX < 0) {
        this.quickZoomClickRespond(this.curValIndex > 0 ? this.curValIndex - 1 : 0);
      }
      this.mZoomInnerStatus = ZoomInnerStatus.FRONT_QUICK_SLIDE;
      return;
    }

    this.mAction.uiStateWithMode(false);
    if (!this.state.isImmersive) {
      this.mAction.isEnterImmersive(true);
    }
    this.cancelNativeAndFrameAnimators(); // 清除动效执行器
    this.mAction.changeZoomState(ZoomOuterStatus.ROULETTE_ZOOM);
    this.clearBigTextTimer();
    this.clearRouletteZoomTimer();
    this.mZoomInnerStatus = ZoomInnerStatus.ROULETTE_SLIDE;
    this.isShowQuickZoom = false;
    this.isShowRouletteZoom = true;
    this.isShowBigText = true;
    if (CameraAppCapability.getInstance().getIsSupportedCycleClickZoom() && this.isShowCycleClickZoomAndEquivZoom()) {
      this.doCycleClickZoomAnim(true);
      this.clearAndSetCycleClickTimer();
      this.isDuringCycleClick = true;
    }

    this.lastGestureOffset = event.offsetX; // 基于上一次回调的偏移量
    this.curZoomAngle = this.calZoomAngle(this.curZoomValue);

    let validFingerLocalX = event.fingerList[0]?.localX;
    let validFingerLocalY = event.fingerList[0]?.localY;
    if (validFingerLocalX === undefined || validFingerLocalY === undefined) {
      let index: number | undefined = this.getValidFingerLocalIndex(event);
      if (index === undefined) {
        return;
      }
      validFingerLocalX = event.fingerList[index]?.localX;
      validFingerLocalY = event.fingerList[index]?.localY;
    }

    let x = Math.abs(this.zoomWidth / 2 - validFingerLocalX);
    let y = this.redLineTopRadius + 10 - validFingerLocalY;
    let clickDotRadialLen = Math.sqrt(x * x + y * y);
    this.lastSlideTouchRadian = ((validFingerLocalX > this.zoomWidth / 2) ?
      Math.asin(x / clickDotRadialLen) : -Math.asin(x / clickDotRadialLen)) * this.panGestureZoomVelocity;
    HiLog.d(TAG, `panGestureStart lastOffset: ${this.lastGestureOffset}, lastRadian: ${this.lastSlideTouchRadian}.`);
  }

  /**
   * 轮盘变焦条滑动手势Update回调
   * */
  private panGestureUpdate(event?: GestureEvent): void {
    if (!event || this.isBlockGestureEvent() || this.isSelfieStickLongPress) {
      return;
    }
    if (!this.isSelfieStickLongPress && AppStorage.get('isSelfieLongPress') === true) {
      // 长按自拍杆过程中，滑动手势处理
      let timeNow = Date.now();
      if ((timeNow - this.selfieStickLongPressTimer) > 1500) {
        AppStorage.setOrCreate('isSelfieLongPress', false);
      }
      this.mAction.uiStateWithMode(false);
      if (!this.state.isImmersive) {
        this.mAction.isEnterImmersive(true);
      }
      this.cancelNativeAndFrameAnimators(); // 清除动效执行器
      this.mAction.changeZoomState(ZoomOuterStatus.ROULETTE_ZOOM);
      this.clearBigTextTimer();
      this.clearRouletteZoomTimer();
      this.mZoomInnerStatus = ZoomInnerStatus.ROULETTE_SLIDE;
      this.isShowQuickZoom = false;
      this.isShowRouletteZoom = true;
      this.isShowBigText = true;
    }
    if (Math.abs(event.offsetX - this.lastGestureOffset) < 0.001) {
      return; // 性能优化
    }
    if (this.isDepthFusionBarShow) {
      this.isDepthFusionConflictLongPress = true;
      HiLog.i(TAG, 'depthFusion conflict pan');
      return;
    }
    let validFingerLocalX = event.fingerList[0]?.localX;
    let validFingerLocalY = event.fingerList[0]?.localY;
    if (validFingerLocalX === undefined || validFingerLocalY === undefined) {
      let index: number | undefined = this.getValidFingerLocalIndex(event);
      if (index === undefined) {
        HiLog.i(TAG, 'panGestureUpdate index === undefined');
        return;
      }
      validFingerLocalX = event.fingerList[index]?.localX;
      validFingerLocalY = event.fingerList[index]?.localY;
    }
    let isFineGrainedControl = Math.abs(event.offsetX - this.lastGestureOffset) < 0.5; // 精细控制体验优化
    let x = Math.abs(this.zoomWidth / 2 - validFingerLocalX);
    let y = this.redLineTopRadius + 10 - validFingerLocalY;
    let clickDotRadialLen = Math.sqrt(x * x + y * y);
    let curSlideTouchRadian = ((validFingerLocalX > this.zoomWidth / 2) ?
      Math.asin(x / clickDotRadialLen) : -Math.asin(x / clickDotRadialLen)) * this.panGestureZoomVelocity;
    let curSlideAngle = (curSlideTouchRadian - this.lastSlideTouchRadian) * 180 / Math.PI;

    let isOpticalZoomIndex = this.opticalZoomDotAngleArr.findIndex((value: number) => {
      return Math.abs(this.curZoomAngle + curSlideAngle - value) <= ZoomParam.SCALE_GAP_ANGLE / 2;
    });
    let oldZoomValue = this.curZoomValue;
    let oldZoomAngle = this.curZoomAngle;
    if (this.isExecAdsorptionType === 1) { // 滑入吸附动效过程中
      HiLog.i(TAG, `isExecAdsorptionType: ${this.isExecAdsorptionType}.`);
      return;
    } else if (this.isExecAdsorptionType === 2) { // 滑出吸附动效过程中
      HiLog.i(TAG, `isExecAdsorptionType: ${this.isExecAdsorptionType}.`);
      return;
    } else if (this.isExecAdsorptionType === 5) { // 吸附中暂态,不响应
      HiLog.i(TAG, `isExecAdsorptionType: ${this.isExecAdsorptionType}.`);
      this.lastSlideTouchRadian = curSlideTouchRadian;
      this.lastGestureOffset = event.offsetX; // 基于上一次回调的偏移量
      return;
    }

    if (this.curZoomValue <= this.opticalZoomValArr[0] && event.offsetX >= 0) { // 左侧极限焦距继续滑动,通过Angle控制
      this.execRightSlideLimitZoomAnim(event, oldZoomAngle, curSlideAngle, curSlideTouchRadian);
    } else if (this.curZoomValue >= this.opticalZoomValArr[this.opticalZoomValArr.length - 1] && event.offsetX <= 0) {
      // 右侧极限焦距继续滑动,通过Angle控制
      this.execLeftSlideLimitZoomAnim(event, oldZoomAngle, curSlideAngle, curSlideTouchRadian);
    } else { // 正常滑动,通过zoom控制
      this.execNormalSlideCal(event, isFineGrainedControl, isOpticalZoomIndex, curSlideAngle, curSlideTouchRadian);
    }
    if (Math.abs(this.curZoomValue - oldZoomValue) <= 0.005 && Math.abs(this.curZoomAngle - oldZoomAngle) <= 0.005) {
      return;
    }

    if (this.curZoomValue !== oldZoomValue) {
      this.execOpticalZoomVibrator(oldZoomValue); // 执行关键刻度振动音效
      this.changeZoomFunctionValue({ zoomRatio: this.curZoomValue });
    }
    this.mNodeController?.invalidate(this.curZoomValue,
      Math.abs(this.curZoomAngle - oldZoomAngle) <= 0.001 ? 1000 : this.curZoomAngle);
  }

  private getValidFingerLocalIndex(event: GestureEvent): number | undefined {
    let validFingerLocalX: number | undefined = undefined;
    let validFingerLocalY: number | undefined = undefined;
    for (let i = 0; i < event.fingerList.length; i++) {
      validFingerLocalX = event.fingerList[i]?.localX;
      validFingerLocalY = event.fingerList[i]?.localY;
      HiLog.d(TAG, `getValidFinger localX: ${validFingerLocalX}, localY: ${validFingerLocalY}.`);
      if (validFingerLocalX === null || validFingerLocalX === undefined || validFingerLocalY === null ||
        validFingerLocalY === undefined) {
        continue;
      } else {
        return i;
      }
    }
    return undefined;
  }

  private execRightSlideLimitZoomAnim(event: GestureEvent, oldZoomAngle: number, curSlideAngle:
    number, curSlideTouchRadian: number): void {
    let nextZoomAngle = oldZoomAngle + curSlideAngle * ZoomParam.RING_LOW_DYNAMIC_FOLLOW_UP_RATE;
    let isInRightGap = this.curZoomAngle + nextZoomAngle > -ZoomParam.SCALE_GAP_ANGLE / 2; // 右间距内
    let isInLeftGap = this.curZoomAngle + nextZoomAngle < 0; // 左间距内
    if ((this.curZoomAngle === 0) && (isInLeftGap && isInRightGap)) {
      this.lastGestureOffset = event.offsetX;
      this.lastSlideTouchRadian = curSlideTouchRadian;
      return;
    }
    HiLog.d(TAG, `execRightSlideLimitZoomAnim curAg:${curSlideAngle}, nxtAg:${nextZoomAngle}, oldAg:${oldZoomAngle}.`);
    if (curSlideAngle < 0 && (nextZoomAngle <= ZoomParam.SCALE_GAP_ANGLE / 2)) {
      this.isExecAdsorptionType = 1;
      this.execSlideOuterLimitInAdsorptionAnim(0, 100);
      return;
    }
    if (this.curZoomAngle !== nextZoomAngle && nextZoomAngle <= ZoomParam.SCALE_GAP_ANGLE * 4) {
      this.curZoomAngle = nextZoomAngle;
    }
    if (nextZoomAngle >= ZoomParam.SCALE_GAP_ANGLE * 4) {
      this.curZoomAngle = ZoomParam.SCALE_GAP_ANGLE * 4;
    }
    this.lastGestureOffset = event.offsetX;
    this.lastSlideTouchRadian = curSlideTouchRadian;
  }

  private execLeftSlideLimitZoomAnim(event: GestureEvent, oldZoomAngle: number, curSlideAngle: number,
    curSlideTouchRadian: number): void {
    let nextZoomAngle = oldZoomAngle + curSlideAngle * ZoomParam.RING_LOW_DYNAMIC_FOLLOW_UP_RATE;
    let maxZoomAngle = this.opticalZoomDotAngleArr[this.opticalZoomDotAngleArr.length - 1];
    if (curSlideAngle > 0 && (nextZoomAngle >= (maxZoomAngle - ZoomParam.SCALE_GAP_ANGLE / 2))) {
      this.isExecAdsorptionType = 1;
      this.execSlideOuterLimitInAdsorptionAnim(maxZoomAngle, 100);
      return;
    }
    if (this.curZoomAngle !== nextZoomAngle && nextZoomAngle >=
      this.opticalZoomDotAngleArr[this.opticalZoomDotAngleArr.length - 1] - ZoomParam.SCALE_GAP_ANGLE * 4) {
      this.curZoomAngle = nextZoomAngle;
    }
    if (nextZoomAngle <=
      this.opticalZoomDotAngleArr[this.opticalZoomDotAngleArr.length - 1] - ZoomParam.SCALE_GAP_ANGLE * 4) {
      this.curZoomAngle =
        this.opticalZoomDotAngleArr[this.opticalZoomDotAngleArr.length - 1] - ZoomParam.SCALE_GAP_ANGLE * 4;
    }
    this.lastGestureOffset = event.offsetX;
    this.lastSlideTouchRadian = curSlideTouchRadian;
  }

  private execNormalSlideCal(event: GestureEvent, isFineGrainedControl: boolean, isOpticalZoomIndex: number,
    curSlideAngle: number, curSlideTouchRadian: number): void {
    let isInRightGap = this.curZoomAngle + curSlideAngle >
      this.opticalZoomDotAngleArr[isOpticalZoomIndex] - ZoomParam.SCALE_GAP_ANGLE / 2; // 右间距内
    let isInLeftGap = this.curZoomAngle + curSlideAngle <
      this.opticalZoomDotAngleArr[isOpticalZoomIndex] + ZoomParam.SCALE_GAP_ANGLE / 2; // 左间距内
    if ((this.curZoomValue === this.opticalZoomValArr[isOpticalZoomIndex]) && (isInRightGap || isInLeftGap)) {
      HiLog.d(TAG, `execNormalSlideCal isInRightGap: ${isInRightGap}, isInLeftGap: ${isInLeftGap}.`);
      return;
    }

    if (this.getIsExecInAdsorption(event, isOpticalZoomIndex, curSlideAngle)) {
      this.isExecAdsorptionType = 1;
      this.execSlideInAdsorptionAnim(this.opticalZoomValArr[isOpticalZoomIndex], 100);
      return;
    }
    if (isFineGrainedControl) {
      if (event.offsetX < this.lastGestureOffset) { // 左滑
        let nextZoomVal = Math.min(this.curZoomValue + 0.05, this.calZoomValue(this.curZoomAngle + curSlideAngle));
        this.curZoomValue = isOpticalZoomIndex === -1 ? nextZoomVal :
          Math.min(nextZoomVal, this.opticalZoomValArr[isOpticalZoomIndex]);
      } else if (event.offsetX > this.lastGestureOffset) { // 右滑
        let nextZoomVal = Math.max(this.curZoomValue - 0.05, this.calZoomValue(this.curZoomAngle + curSlideAngle));
        this.curZoomValue = isOpticalZoomIndex === -1 ? nextZoomVal :
          Math.max(nextZoomVal, this.opticalZoomValArr[isOpticalZoomIndex]);
      } // else已被拦截
      if (this.curZoomValue !== this.opticalZoomValArr[isOpticalZoomIndex]) {
        this.lastGestureOffset = event.offsetX; // 基于上一次回调的偏移量
        this.lastSlideTouchRadian = curSlideTouchRadian;
      }
    } else {
      if (Math.abs(this.curZoomAngle + curSlideAngle - this.opticalZoomDotAngleArr[isOpticalZoomIndex]) <=
        ZoomParam.SCALE_GAP_ANGLE / 2) {
        this.curZoomValue = this.opticalZoomValArr[isOpticalZoomIndex];
      } else {
        this.curZoomValue = this.calZoomValue(this.curZoomAngle + curSlideAngle);
        this.lastGestureOffset = event.offsetX; // 基于上一次回调的偏移量
        this.lastSlideTouchRadian = curSlideTouchRadian;
      }
    }
    let oldZoomAngle: number = this.curZoomAngle;
    this.curZoomAngle = this.calZoomAngle(this.curZoomValue);
    // 执行变焦精细小刻度振动
    this.execSlideLightVibrator(oldZoomAngle);
  }

  private async execSlideLightVibrator(oldZoomAngle: number): Promise<void> {
    if (Number((this.state.zoomRatio).toFixed(3)) === this.curZoomValue || !this.isAllowVibratorSound()) {
      return;
    }
    let startIndex = Math.floor(-oldZoomAngle / ZoomParam.SCALE_GAP_ANGLE) - 5;
    startIndex = Math.max(0, startIndex);
    for (let i = startIndex; i < startIndex + 10 && i < this.smallScaleDotAngleArr.length; i++) {
      let smallAngle: number = this.smallScaleDotAngleArr[i];
      let isWhiteLineZoom = (smallAngle > oldZoomAngle && smallAngle <= this.curZoomAngle) ||
        (smallAngle < oldZoomAngle && smallAngle >= this.curZoomAngle);
      if (isWhiteLineZoom) {
        this.mAction.handleZoomVibrator(VibratorService.CAMERA_GEAR_SLIP_LIGHT_ID);
        break;
      }
    }
  }

  private execOpticalZoomVibrator(oldZoomValue: number): void {
    for (let i = 0; i < this.opticalZoomValArr.length; i++) {
      let isOpticalZoom = (oldZoomValue < this.opticalZoomValArr[i] && this.curZoomValue > this.opticalZoomValArr[i]) ||
        (oldZoomValue > this.opticalZoomValArr[i] && this.curZoomValue < this.opticalZoomValArr[i]) ||
        (oldZoomValue !== this.opticalZoomValArr[i] && this.curZoomValue === this.opticalZoomValArr[i]);
      if (this.isAllowVibratorSound() && isOpticalZoom && this.curZoomAngle <= 0 &&
        this.curZoomAngle >= this.opticalZoomDotAngleArr[this.opticalZoomDotAngleArr.length - 1]) {
        this.mAction.zoomSlide2QuickZoom(this.curZoomValue);
        this.mAction.handleZoomVibrator(VibratorService.CAMERA_GEAR_SLIP_HEAVY_ID, VIBRATOR_USAGE_PHYSIC);
        break;
      }
    }
  }

  private getIsExecInAdsorption(event: GestureEvent, isOpticalZoomIndex: number, curSlideAngle: number): boolean {
    if (Math.abs(event.offsetX - this.lastGestureOffset) > 2) {
      return false;
    }
    let isLeftIn: boolean = curSlideAngle < 0 &&
      this.opticalZoomDotAngleArr[isOpticalZoomIndex] !== undefined &&
      this.curZoomAngle > this.opticalZoomDotAngleArr[isOpticalZoomIndex] &&
      this.curZoomAngle + curSlideAngle >
        this.opticalZoomDotAngleArr[isOpticalZoomIndex] - ZoomParam.SCALE_GAP_ANGLE / 2; // 左滑需吸附至关键刻度点
    let isRightIn: boolean = curSlideAngle > 0 &&
      this.opticalZoomDotAngleArr[isOpticalZoomIndex] !== undefined &&
      this.curZoomAngle < this.opticalZoomDotAngleArr[isOpticalZoomIndex] &&
      this.curZoomAngle + curSlideAngle <
        this.opticalZoomDotAngleArr[isOpticalZoomIndex] + ZoomParam.SCALE_GAP_ANGLE / 2; // 右滑需吸附至关键刻度点
    return isLeftIn || isRightIn;
  }

  private execSlideInAdsorptionAnim(nextZoomValue: number, duration: number): void {
    HiLog.i(TAG, `execSlideInAdsorptionAnim nextZoomValue: ${nextZoomValue}, duration: ${duration}.`);
    let oldAdsorptionType = this.isExecAdsorptionType;
    let startZoomVal = this.curZoomValue;
    let options: AnimatorOptions = {
      duration: duration,
      easing: 'friction',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: startZoomVal,
      end: nextZoomValue
    };
    if (this.mStateChangeAnimator !== null) {
      try {
        this.mStateChangeAnimator.reset(options);
      } catch (error) {
        HiLog.e(TAG, `createPlayNativeAnimator error: ${error?.code}.`);
      }
    } else {
      this.mStateChangeAnimator = animator.create(options);
    }
    this.mStateChangeAnimator.onFinish = () => {
      HiLog.i(TAG, `oldAdsorptionType: ${oldAdsorptionType}, isExecAdsorptionType: ${this.isExecAdsorptionType}.`);
      if (!this.mNodeController?.getIsTextParallel2CarmenLine()) {
        this.mNodeController?.execLandscapeSlideExpandAnim(nextZoomValue); // 横屏滑动关键刻度展开动效
      }
      if (oldAdsorptionType !== this.isExecAdsorptionType) {
        return;
      }
      this.isExecAdsorptionType = 5;
      this.mExecAdsorptionTimerId = setTimeout(() => {
        this.isExecAdsorptionType = 0;
        this.mExecAdsorptionTimerId = Number.MAX_VALUE;
      }, 250);
      this.curZoomValue = nextZoomValue;
      this.curValIndex = this.calZoomValIndex(); // 当前变焦值在快捷变焦点列表的index下界
      this.curZoomAngle = this.calZoomAngle(this.curZoomValue);
      if (this.isAllowVibratorSound()) {
        this.mAction.zoomSlide2QuickZoom(this.curZoomValue);
        if (this.state.recordingState !== RecordingState.RECORDING) {
          this.mAction.handleZoomVibrator(VibratorService.CAMERA_GEAR_SLIP_HEAVY_ID, VIBRATOR_USAGE_PHYSIC);
        }
      }
    };
    this.mStateChangeAnimator.onFrame = (value) => {
      if (!this.isShowRouletteZoom || !this.curZoomValue || oldAdsorptionType !== this.isExecAdsorptionType) {
        return;
      }
      this.curZoomValue = value;
      this.changeZoomFunctionValue({ zoomRatio: this.curZoomValue });
      this.mNodeController?.invalidate(value, 1000); // 数据小容器传递
    };
    this.mStateChangeAnimator?.play();
  }

  private execSlideOuterLimitInAdsorptionAnim(nextZoomAngle: number, duration: number): void {
    HiLog.i(TAG, `execSlideOuterLimitInAdsorptionAnim nextZoomAngle: ${nextZoomAngle}, duration: ${duration}.`);
    let oldAdsorptionType = this.isExecAdsorptionType;
    let startZoomAng = this.curZoomAngle;
    let options: AnimatorOptions = {
      duration: duration,
      easing: 'friction',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: startZoomAng,
      end: nextZoomAngle
    };
    if (this.mStateChangeAnimator !== null) {
      try {
        this.mStateChangeAnimator.reset(options);
      } catch (error) {
        HiLog.e(TAG, `createPlayNativeAnimator error: ${error?.code}.`);
      }
    } else {
      this.mStateChangeAnimator = animator.create(options);
    }
    this.mStateChangeAnimator.onFinish = () => {
      HiLog.i(TAG, `oldAdsorptionType: ${oldAdsorptionType}, isExecAdsorptionType: ${this.isExecAdsorptionType}.`);
      if (!this.mNodeController?.getIsTextParallel2CarmenLine()) {
        this.mNodeController?.execLandscapeSlideExpandAnim(this.curZoomValue); // 横屏滑动关键刻度展开动效
      }
      if (oldAdsorptionType !== this.isExecAdsorptionType) {
        return;
      }
      this.isExecAdsorptionType = 5;
      this.mExecAdsorptionTimerId = setTimeout(() => {
        this.isExecAdsorptionType = 0;
        this.mExecAdsorptionTimerId = Number.MAX_VALUE;
      }, 150);
    };
    this.mStateChangeAnimator.onFrame = (value) => {
      if (!this.isShowRouletteZoom || !this.curZoomValue || oldAdsorptionType !== this.isExecAdsorptionType) {
        return;
      }
      this.curZoomAngle = value;
      this.mNodeController?.invalidate(this.curZoomValue, value);
    };
    this.mStateChangeAnimator?.play();
  }

  /**
   * 轮盘变焦条滑动手势End回调
   * */
  private panGestureEnd(event?: GestureEvent): void {
    if (!event || this.isBlockGestureEvent() || this.isSelfieStickLongPress) {
      if (this.mZoomInnerStatus === ZoomInnerStatus.FRONT_QUICK_SLIDE) {
        this.mZoomInnerStatus = ZoomInnerStatus.QUICK_STATIC;
      }
      return;
    }
    HiLog.d(TAG, `PanGesture onActionEnd offset event: ${event.speed}.`);
    this.mAction.isEnterImmersive(false);
    this.mAction.uiStateWithMode(true);
    this.mAction.changeOtherComponent();
    if (this.isExecAdsorptionType !== 0) {
      this.isExecAdsorptionType = 0;
    }

    if (this.curZoomAngle > this.opticalZoomDotAngleArr[0] ||
      this.curZoomAngle < this.opticalZoomDotAngleArr[this.opticalZoomDotAngleArr.length - 1]) {
      this.execLimitZoomSlideRecovery();
      this.curValIndex = this.calZoomValIndex(); // 当前变焦值在快捷变焦点列表的index下界
      return;
    }

    let nextZoomValue: number = this.curZoomValue;
    if (event?.velocityX > ZoomParam.THROW_SLIDE_TRIGGER_VELOCITY) { // 执行抛滑策略
      nextZoomValue = this.opticalZoomValArr[0] + (event?.velocityX > ZoomParam.THROW_SLIDE_UPPER_VELOCITY ? 0 :
        ((ZoomParam.THROW_SLIDE_UPPER_VELOCITY - event?.velocityX) * this.panGestureZoomVelocity /
          (ZoomParam.THROW_SLIDE_UPPER_VELOCITY - ZoomParam.THROW_SLIDE_TRIGGER_VELOCITY) *
          (this.curZoomValue - this.opticalZoomValArr[0])));
    } else if (event?.velocityX < -ZoomParam.THROW_SLIDE_TRIGGER_VELOCITY) {
      nextZoomValue = this.opticalZoomValArr[this.opticalZoomValArr.length - 1] -
        (event?.velocityX < -ZoomParam.THROW_SLIDE_UPPER_VELOCITY ? 0 :
          ((ZoomParam.THROW_SLIDE_UPPER_VELOCITY + event?.velocityX) * this.panGestureZoomVelocity /
            (ZoomParam.THROW_SLIDE_UPPER_VELOCITY - ZoomParam.THROW_SLIDE_TRIGGER_VELOCITY) *
            (this.opticalZoomValArr[this.opticalZoomValArr.length - 1] - this.curZoomValue)));
    } else {
      this.clearAndSetRouletteZoomTimer();
      this.mZoomInnerStatus = ZoomInnerStatus.ROULETTE_STATIC;
      this.curValIndex = this.calZoomValIndex(); // 当前变焦值在快捷变焦点列表的index下界
      return;
    }

    let nextZoomAngle: number = this.calZoomAngle(nextZoomValue);
    let isOpticalZoomIndex = this.opticalZoomDotAngleArr.findIndex((value: number) => {
      return Math.abs(nextZoomAngle - value) <= ZoomParam.SCALE_GAP_ANGLE * 3;
    });
    if (isOpticalZoomIndex !== -1) {
      nextZoomValue = this.opticalZoomValArr[isOpticalZoomIndex];
    }
    this.execThrowSlideRespondAnim(nextZoomValue, event?.velocityX);
  }

  private execLimitZoomSlideRecovery(): void {
    let startZoomAngle = this.curZoomAngle;
    let endZoomAngle = this.curZoomAngle > this.opticalZoomDotAngleArr[0] ?
      this.opticalZoomDotAngleArr[0] : this.opticalZoomDotAngleArr[this.opticalZoomDotAngleArr.length - 1];

    let options: AnimatorOptions = {
      duration: Math.abs(startZoomAngle - endZoomAngle) / (ZoomParam.SCALE_GAP_ANGLE * 4) * 250,
      easing: 'friction',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: startZoomAngle,
      end: endZoomAngle
    };
    if (this.mStateChangeAnimator !== null) {
      try {
        this.mStateChangeAnimator.reset(options);
      } catch (error) {
        HiLog.e(TAG, `createPlayNativeAnimator error: ${error?.code}.`);
      }
    } else {
      this.mStateChangeAnimator = animator.create(options);
    }
    this.mStateChangeAnimator.onFinish = () => {
      this.clearAndSetRouletteZoomTimer(); // 定时器内包含大字体
      this.mZoomInnerStatus = ZoomInnerStatus.ROULETTE_STATIC;
      if (!this.mNodeController?.getIsTextParallel2CarmenLine()) {
        this.mNodeController?.execLandscapeSlideExpandAnim(this.curZoomValue); // 横屏滑动关键刻度展开动效
      }
    };
    this.mStateChangeAnimator.onFrame = (value) => {
      if (!this.isShowRouletteZoom || !this.curZoomValue) {
        return;
      }
      this.mNodeController?.invalidate(this.curZoomValue, value);
    };
    this.mStateChangeAnimator?.play();
  }

  private execThrowSlideRespondAnim(nextZoomValue: number, mVelocityX: number): void {
    let startZoomVal = this.curZoomValue;
    this.curZoomValue = nextZoomValue;
    this.curValIndex = this.calZoomValIndex(); // 当前变焦值在快捷变焦点列表的index下界
    this.clickZoomDelivery(); // 点切变焦平滑曲线下发
    this.touchUnprepareZoom();
    let options: AnimatorOptions = {
      duration: Math.abs(mVelocityX) > ZoomParam.THROW_SLIDE_UPPER_VELOCITY ? 132 : 264,
      easing: 'friction',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: startZoomVal,
      end: nextZoomValue
    };
    let oldDrawZoomVal: number = startZoomVal;
    if (this.mStateChangeAnimator !== null) {
      try {
        this.mStateChangeAnimator.reset(options);
      } catch (error) {
        HiLog.e(TAG, `createPlayNativeAnimator error: ${error?.code}.`);
      }
    } else {
      this.mStateChangeAnimator = animator.create(options);
    }
    this.mStateChangeAnimator.onFinish = () => {
      this.clearAndSetRouletteZoomTimer(); // 定时器内包含大字体
      this.mZoomInnerStatus = ZoomInnerStatus.ROULETTE_STATIC;
      if (!this.mNodeController?.getIsTextParallel2CarmenLine()) {
        this.mNodeController?.execLandscapeSlideExpandAnim(nextZoomValue); // 横屏滑动关键刻度展开动效
      }
    };
    this.mStateChangeAnimator.onFrame = (value) => {
      if (!this.isShowRouletteZoom || !this.curZoomValue) {
        return;
      }
      this.throwSlideRespondAnimOnFrame(oldDrawZoomVal, value);
      oldDrawZoomVal = value;
    };
    this.mStateChangeAnimator?.play();
  }

  private throwSlideRespondAnimOnFrame(oldDrawZoomVal: number, frameValue: number): void {
    for (let i = 0; i < this.opticalZoomValArr.length; i++) {
      let isOpticalZoom = (oldDrawZoomVal < this.opticalZoomValArr[i] && frameValue > this.opticalZoomValArr[i]) ||
        (oldDrawZoomVal > this.opticalZoomValArr[i] && frameValue < this.opticalZoomValArr[i]) ||
        (oldDrawZoomVal !== this.opticalZoomValArr[i] && frameValue === this.opticalZoomValArr[i]);
      if (this.isAllowVibratorSound() && isOpticalZoom) {
        this.mAction.zoomSlide2QuickZoom(this.curZoomValue);
        this.mAction.handleZoomVibrator(VibratorService.CAMERA_GEAR_SLIP_HEAVY_ID, VIBRATOR_USAGE_PHYSIC);
        break;
      }
    }
    try {
      this.mNodeController?.invalidate(frameValue, 1000); // 数据小容器传递
    } catch (err) {
      HiLog.e(TAG, `NodeController invalidate err: ${err}.`);
    }
  }

  // 收起轮盘变焦,执行光球动效
  private rouletteDisappearExecSphereAnim(): void {
    this.createPlayFrameAnimators(2, 150, 'friction', 500, 0, 8, (frameValue: number) => {
      this.spherePosition = frameValue; // 光球: 位移 向下8vp消失; 150-650ms
    });

    this.createPlayFrameAnimators(3, 350, 'friction', 400, 1, 0, (frameValue: number) => {
      this.sphereScale = frameValue; // 光球: scale 1-0; 350-750ms
    });

    this.createPlayFrameAnimators(5, 250, 'friction', 400, 0.5, 1,
      (frameValue: number) => {
        this.sphereHaloOpacity = frameValue; // 光球-光晕: opacity 0.5-1; 250-650ms
      },
      () => {
        this.mFrameAnimResultArr[5] = null;
        this.createPlayFrameAnimators(5, 0, 'sharp', 150, 1, 0,
          (frameValue: number) => { // 生命周期内禁止reset自身对象
            this.sphereHaloOpacity = frameValue; // 光球-光晕: opacity 1-0; 650-800ms
          }, () => {
            this.isShowRouletteZoom = false;
          });
      });

    setTimeout((): void => {
      if (this.mZoomInnerStatus !== ZoomInnerStatus.ROULETTE_TO_QUICK) {
        return;
      }
      this.mAction.changeZoomState(ZoomOuterStatus.QUICK_ZOOM); // 保障同步出现效果
    }, 300);
  }

  // 收起轮盘变焦,执行大字体动效
  private rouletteDisappearExecBigTextAnim(): void {
    setTimeout((): void => { // 大字体: opacity 1-0; 350-450ms
      if (this.isShowBigText && this.mZoomInnerStatus === ZoomInnerStatus.ROULETTE_TO_QUICK &&
        !this.isSelfieStickLongPress && !this.isSelfieStickShortPress) {
        this.isShowBigText = false;
      }
    }, 350);
  }

  // 收起轮盘变焦,执行焦圈中心刻度、焦圈动效
  private rouletteDisappearExecRedLineAndScaleAllAnim(): void {
    this.createPlayFrameAnimators(6, 250, 'sharp', 100, 1, 0, (frameValue: number) => {
      this.redLineAndTextOpacity = frameValue; // 焦圈中心刻度: opacity 1-0; 250-350ms
    });

    this.createPlayFrameAnimators(7, 0, 'friction', 450, 1, 0, (frameValue: number) => {
      this.scaleAllMatteScale = frameValue; // 焦圈: 遮罩scale 1-0; 0-450ms
    });

    this.createPlayFrameAnimators(8, 250, 'sharp', 100, 1, 0, (frameValue: number) => {
      this.scaleAllOpacity = frameValue; // 焦圈: opacity 1-0; 250-350ms
    });
  }

  // 收起轮盘变焦,执行卡门线动效
  private rouletteDisappearExecCarmenLineAnim(): void {
    this.createPlayFrameAnimators(9, 150, 'friction', 300, 1, 0,
      (frameValue: number) => {
        this.carmenLineMatteScale = frameValue; // 卡门线: 遮罩scale 1-0; 150-450ms
      },
      () => {
        this.createPlayFrameAnimators(10, 0, 'sharp', 100, 1, 0, (frameValue: number) => {
          this.carmenLineOpacity = frameValue; // 卡门线: opacity 1-0; 450-550ms
        });
      });
  }

  // 收起轮盘变焦,执行快捷变焦圆外层动效
  private rouletteDisappearExecQuickZoomOutsideAnim(): void {
    if (this.quickZoomAlpha === 1) {
      this.quickZoomAlpha = 0;
    }
    if (this.mQuickOtherAlpha === 1) {
      this.mQuickOtherAlpha = 0;
    }
    if (this.mQuickZoomOverColor === 0) {
      this.mQuickZoomOverColor = 1;
    }
    if (!this.isShowQuickZoom) {
      this.isShowQuickZoom = true;
    }
    animateToImmediately({
      delay: 250,
      curve: Curve.Sharp,
      duration: 500
    }, () => {
      this.quickZoomAlpha = 1; // 快捷变焦圆: opacity 0-1; 250-750ms
      this.mQuickOtherAlpha = 1;
      this.mQuickZoomOverColor = 0; // 快捷变焦圆: 叠加颜色 1-0; 250-750ms
    });

    if (this.mQuickZoomPositionY === 2) {
      this.mQuickZoomPositionY = 0;
    }
    animateToImmediately({
      // 快捷变焦圆: 位移 向下2vp退出; 250-750ms
      delay: 250,
      curve: Curve.Friction,
      duration: 500
    }, () => {
      this.mQuickZoomPositionY = 2;
    });

    if (this.mQuickZoomBlur === 0) {
      this.mQuickZoomBlur = 1;
    }
    animateToImmediately({
      // 快捷变焦圆: 模糊 1-0; 450-650ms
      delay: 450,
      curve: Curve.Friction,
      duration: 200
    }, () => {
      this.mQuickZoomBlur = 0;
      this.onProHideTreasureBox(false);
    });
  }

  private onProHideTreasureBox(isHide: boolean): void {
    return;
    if (isHide) {
      this.mAction.isProHideTreasureBox();
    } else {
      this.mAction.isProShowTreasureBox();
    }
  }

  private changeZoomFunctionValue(zoomData: ZoomFuncValueStruct, autoTriggered?: boolean): void {
    this.zoomFunction?.setValue(zoomData);
    this.mAction.changedZoomByGesture(FunctionId.ZOOM, zoomData, autoTriggered);
  }

  private changeZoomValue(zoomVal: number): void {
    if (zoomVal > getStates().get<number>('zoomReducer', 'maxZoomRatio')) {
      zoomVal = getStates().get<number>('zoomReducer', 'maxZoomRatio')
    }
    if (zoomVal < getStates().get<number>('zoomReducer', 'minZoomRatio')) {
      zoomVal = getStates().get<number>('zoomReducer', 'minZoomRatio');
    }
    this.curZoomValue = zoomVal;
    this.curValIndex = this.calZoomValIndex();
  }

  private onCollaborateZoomIn(): void {
    // 遥控拍照每次固定变焦,首次变焦前设置mIsPrepareZoom = true,变焦结束500ms后设置mIsPrepareZoom = false
    this.changeZoomValue(this.getCollaborateTargetZoomValue(true));
    this.changeZoomFunctionValue({ zoomRatio: this.curZoomValue }, true);
  }

  private onCollaborateZoomOut(): void {
    this.changeZoomValue(this.getCollaborateTargetZoomValue(false));
    this.changeZoomFunctionValue({ zoomRatio: this.curZoomValue }, true);
  }

  private getCollaborateTargetZoomValue(isZoomIn: boolean): number {
    let targetZoomValue = this.curZoomValue;
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT &&
      !CameraAppCapability.getInstance().getIsSupportedFrontZoomSlide()) {
      // 不支持滑动变焦时，按照快捷变焦范围步进
      let targetValIndex = isZoomIn ? this.curValIndex + 1 : this.curValIndex - 1;
      if (targetValIndex >= 0 && targetValIndex <= this.quickZoomValArr.length - 1) {
        targetZoomValue = this.quickZoomValArr[targetValIndex];
      } else {
        targetZoomValue = isZoomIn ? this.curZoomValue + ZOOM_STEP : this.curZoomValue - ZOOM_STEP;
      }
    }
    return targetZoomValue;
  }

  /**
   * 计算zoomValue变焦值居顶红刻度线重合时,需要旋转的角度;
   * @param zoomValue
   * @returns to rotate angle
   */
  private calZoomAngle(zoomValue: number): number {
    if (zoomValue <= this.opticalZoomValArr[0]) {
      return 0;
    } else if (zoomValue >= this.opticalZoomValArr[this.opticalZoomValArr.length - 1]) {
      return -ZoomParam.SCALE_GAP_ANGLE * this.opticalZoomDotIndexArr[this.opticalZoomDotIndexArr.length - 1];
    }
    let resultAngle = 0;
    let index = 0;
    while (index < this.opticalZoomValArr.length && this.opticalZoomValArr[index] <= zoomValue) {
      index++;
    }
    index--;
    resultAngle = -ZoomParam.SCALE_GAP_ANGLE * this.opticalZoomDotIndexArr[index]; // 前序大刻度角度
    let smallAngle = -ZoomParam.SCALE_GAP_ANGLE * (zoomValue - this.opticalZoomValArr[index]) /
      (this.opticalZoomValArr[index + 1] - this.opticalZoomValArr[index]) *
      (this.opticalZoomDotIndexArr[index + 1] - this.opticalZoomDotIndexArr[index]);
    resultAngle += smallAngle;
    return resultAngle;
  }

  /**
   * 逆向思维;以第0个快捷变焦刻度居顶为初始,旋转zoomAngle角度后居顶的变焦值;
   * @param zoomAngle
   * @returns will zoomValue
   */
  private calZoomValue(zoomAngle: number): number {
    if (zoomAngle >= 0) {
      return this.opticalZoomValArr[0];
    } else if (zoomAngle <=
      -ZoomParam.SCALE_GAP_ANGLE * this.opticalZoomDotIndexArr[this.opticalZoomDotIndexArr.length - 1]) {
      return this.opticalZoomValArr[this.opticalZoomValArr.length - 1];
    }
    let resultZoom = 0;
    let index = 0;
    while (index < this.opticalZoomDotIndexArr.length &&
      (-ZoomParam.SCALE_GAP_ANGLE * this.opticalZoomDotIndexArr[index]) >= zoomAngle) {
      index++;
    }
    index--;
    resultZoom = this.opticalZoomValArr[index];
    let smallZoom = (zoomAngle + ZoomParam.SCALE_GAP_ANGLE * this.opticalZoomDotIndexArr[index]) /
      (-ZoomParam.SCALE_GAP_ANGLE * this.opticalZoomDotIndexArr[index + 1] +
        ZoomParam.SCALE_GAP_ANGLE * this.opticalZoomDotIndexArr[index]) *
      (this.opticalZoomValArr[index + 1] - this.opticalZoomValArr[index]);
    resultZoom += smallZoom;
    return resultZoom;
  }

  /**
   * 计算当前变焦值对应快捷变焦点列表的index下界-快捷变焦圆显示的index
   * @return 变焦范围内index
   * */
  private calZoomValIndex(zoomValue?: number): number {
    let nowZoomValue: number;
    zoomValue ? (nowZoomValue = zoomValue) : (nowZoomValue = this.curZoomValue);
    let index = 0;
    while (index < this.quickZoomValArr.length && this.roundOrSplitZoomVal(this.quickZoomValArr[index]) <=
    Number(Math.floor(nowZoomValue * 10) / 10)) {
      index++;
    }
    index -= 1; // 当前变焦值在快捷变焦点列表的index下界
    HiLog.i(TAG, `calZoomValIndex nowZoomValue: ${nowZoomValue}, index: ${index} X.`);
    return index < 0 ? 0 : Math.min(index, this.quickZoomValArr.length - 1);
  }

  private updateDensity(): void {
    HiLog.i(TAG, `updateDensity density: ${this.density}`);
    return;
    const size: Size = CameraBasicService.getInstance().getPreviewDisplaySize();
    setTimeout((): void => {
      this.zoomWidth = size.width;
    }, WAIT_TIME);
  }

  private getQuickMaxZoomVarW(): number {
    // 大字体或者zoom快捷点显示W 的阈值,默认阈值0.79,有上报w的话，以上报的w为阈值
    return (this.quickZoomValArr.length > 0 && this.quickZoomValArr[0] > 0 && this.quickZoomValArr[0] < 1) ?
      this.quickZoomValArr[0] : 0.79;
  }

  private roundOrSplitZoomVal(zoomVal: number): number {
    // 截取至一位小数, 如果是.0则保留为整数
    const truncatedNum = Math.floor(zoomVal * 10) / 10;
    return truncatedNum === Math.floor(zoomVal) ? Math.floor(zoomVal) : truncatedNum;
  }

  private isLandscapeIndex(): boolean {
    return this.isShowLandscape || this.isShowTricollaps;
  }

  private doCycleClickZoomAnim(isShow: boolean): void {
    this.isShowCycleClickZoom = isShow;
  }

  private getCommonZoomAnim(): TransitionEffect {
    return TransitionEffect.asymmetric(
      TransitionEffect.OPACITY
        .animation({
          curve: Curve.Sharp,
          duration: 100,
        }),
      TransitionEffect.OPACITY
        .animation({
          curve: Curve.Sharp,
          duration: 100,
          delay: 100,
        })
    );
  }

  private getCycleClickZoomAnim(): TransitionEffect {
    return TransitionEffect.asymmetric(
      TransitionEffect.OPACITY
        .animation({
          curve: Curve.Sharp,
          duration: 100,
          delay: 100,
        }),
      TransitionEffect.OPACITY
        .animation({
          curve: Curve.Sharp,
          duration: 100,
        })
    );
  }

  // 更新循环点切的状态
  private updateCycleClickZoom(): void {
    if (ZoomOperation.getInstance().getRemainZoomRatio()) {
      return;
    }
    this.doCycleClickZoomAnim(false);
  }

  // 执行循环点切或者焦距复位
  private doCycleClickZoom(): void {
    if (!CameraAppCapability.getInstance().getIsSupportedCycleClickZoom()) {
      return;
    }
    if (!this.isShowCycleClickZoomAndEquivZoom()) {
      return;
    }
    this.cycleZoomData = CameraAppCapability.getInstance().getZoomCycleList(this.state.mode,
      this.quickZoomValArr[this.curValIndex]);
    HiLog.i(TAG, `get cycleZoomData: ${this.cycleZoomData}`)


    if (this.isBlockGestureEvent()) {
      this.showBigTextAndEquivZoomText();
      return;
    }
    // 焦距复位
    let index = this.opticalZoomValArr.indexOf(this.curZoomValue);
    if (!this.isShowCycleClickZoom && this.curZoomValue !== this.quickZoomValArr[this.curValIndex] &&
      (index === -1 || index === this.opticalZoomValArr.length - 1)) {
      this.curZoomValue = this.quickZoomValArr[this.curValIndex];
      this.showBigTextAndEquivZoomText();
      this.clickZoomDelivery(); // 点切变焦执行下发
      return;
    }

    // 循环变焦
    if (this.cycleZoomData.length === 0) { // 如果当前的循环点切数组为空的话，证明这个快捷变焦点不支持循环变焦，但是也要展示等效焦距
      this.showBigTextAndEquivZoomText();
      return;
    }
    // 当前模式的最大变焦值比循环点切焦距数组的最小值还小，直接返回
    if (this.opticalZoomValArr[this.opticalZoomValArr.length -1] < this.cycleZoomData[0]) {
      this.showBigTextAndEquivZoomText();
      return;
    }
    index = this.cycleZoomData.indexOf(this.curZoomValue);
    if (this.curValIndex < this.quickZoomValArr.length - 1 &&
      this.cycleZoomData[index + 1] >= this.quickZoomValArr[this.curValIndex + 1]) {
      return;
    }
    if (index !== -1) {
      // 当前的焦距值已经在循环点切焦距数组里面了，并且下一个循环的焦距值是合法的
      if (index + 1 < this.cycleZoomData.length &&
        this.opticalZoomValArr[this.opticalZoomValArr.length -1] >= this.cycleZoomData[index + 1]) {
        this.curZoomValue = this.cycleZoomData[index + 1];
      } else {
        this.curZoomValue = this.quickZoomValArr[this.curValIndex];
      }
    } else {
      // 当前的焦距值不在循环点切焦距数组里面，就从头开始循坏变焦
      this.curZoomValue = this.cycleZoomData[0];
    }
    this.showBigTextAndEquivZoomText();
    this.clickZoomDelivery(); // 点切变焦执行下发
  }

  private showBigTextAndEquivZoomText(): void {
    // 展示变焦大字体和等效焦距
    this.doCycleClickZoomAnim(true);
    this.clearAndSetCycleClickTimer();
    this.isDuringCycleClick = true;
    if (this.isShowBigText) {
      this.clearAndSetBigTextTimer();
    } else {
      this.isShowBigText = true;
    }
  }

  private isShowCycleClickZoomAndEquivZoom(): boolean {
    return true;
  }
}