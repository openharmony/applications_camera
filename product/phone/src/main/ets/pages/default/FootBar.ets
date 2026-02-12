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

import lazy { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { CameraSwitchButton } from '@ohos/common/src/main/ets/function/cameraswitcher/CameraSwitchButton';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { RecordingControlButton } from '@ohos/common/src/main/ets/function/recordcontrol/RecordingControlButton';
import lazy { ShutterButton } from '@ohos/common/src/main/ets/function/capture/ShutterButton';
import lazy { ThumbnailView } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailView';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy {
  ChangeState,
  execDispatch,
  getStates,
  reduxSubscribe,
  Unsubscribe
} from '@ohos/common/src/main/ets/redux/Store';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { FunctionValueType, ImmersiveActionData, XComponentSize } from '@ohos/common/src/main/ets/utils/types';
import animator, { AnimatorOptions, AnimatorResult } from '@ohos.animator';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { CircleImage } from '@ohos/common/src/main/ets/component/picker/CircleImage';
import lazy { ZoomViewVde } from '@ohos/common/src/main/ets/function/zoombar/ZoomViewVde';
import lazy { OutputSwitcherButton } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcherButton';
import lazy { RecordingCaptureButton } from '@ohos/common/src/main/ets/function/recordcontrol/RecordingCaptureButton';
import lazy { camera } from '@kit.CameraKit';
import lazy { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { Configuration, display, window } from '@kit.ArkUI';
import lazy { PickerAction } from '@ohos/common/src/main/ets/service/picker/PickerAction';
import lazy { SizeUtil } from '@ohos/common/src/main/ets/utils/SizeUtil';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { RecordActionType } from '@ohos/common/src/main/ets/redux/actions/RecordActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { FunctionActionType } from '@ohos/common/src/main/ets/redux/actions/FunctionActionType';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';
import lazy { PositionType } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';

/* instrument ignore file */
const TAG: string = 'FootBar';
const TIP_DURING: number = 3000;
const ICON_OUTER_HEIGHT = 44;
const CUSTOM_FILTER_OFFESET_X: number = 17;
const CUSTOM_FILTER_FOOTER_SCALE_ONE: number = 0.85;
const CUSTOM_FILTER_FOOTER_SCALE_TWO: number = 0.9;
const CUSTOM_FILTER_OFFESET_X_NORMAL: number = 10;
const FOOT_BAR_OFFSET_Y: number = 16;
const FILMING_CREW_TOP: number = 8;
const CARD_NORMAL_HEIGHT = 218;
const FOOT_BAR_HEIGHT: number = 72;
const BOTTOM_HEIGHT: number = 32;
const CUSTOM_FILTER_OFFESET_Y: number = -142;

export const CUSTOM_FILTER_DURATION: number = AnimSpecifications.ANIM_DURATION_400;

class StateStruct {
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public videoState: RecordingState = RecordingState.READY;
  public mode: ModeType = ModeType.NONE;
  public collapsStatus: display.FoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  public isVdeCollapsed: boolean = false;
  public isShowtimeLapse: boolean = false;
}

class RecordData {
  public startTimeSeconds: number = 0;
}

@Component
export struct FootBar {
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @Prop isPicker: boolean = false;
  @State state: StateStruct = new StateStruct();
  @StorageProp('cameraCount') mCameraCount: number = 2;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State mCancelButtonHide: boolean = false;
  @State @Watch('onThumbnailAndSwitchButtonChanged') mHideThumbnailAndSwitchButton: boolean = false;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @State isHalfCollapsLEM: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State isInLrImmersive: boolean = false;
  @State @Watch('enterAndExitLrSwipeAnim') lrImmersiveTrigger: boolean | null = null;
  @State @Watch('enterAndExitLrSwipeAnim') isShutterButtonLongClick: boolean = false;
  @State currentMode: ModeType = ModeType.NONE;
  private shutterButtonLongClickCache: boolean = false;
  @State isSwipeFootBarShown: boolean = false;
  @State touchEvent: TouchEvent | null = null;
  @State horizontalOffset: number = 0;
  @State @Watch('onImmersiveOpacityChanged') immersiveOpacity: number = 1;
  @State immersiveScale: number = 1;
  @State sideImmersiveVisibility: Visibility = Visibility.Visible;
  @State isLrShutterShown: boolean = false;
  // 隔离条件
  @State separationForLRSwipeFootBar: boolean = true;
  private sideShrinkAnimator: AnimatorResult | null = null; // 缩小动效
  private sideExpandAnimator: AnimatorResult | null = null; // 放大动效
  @Link footBarScale: number;
  @Prop @Watch('customFilterImmersiveChange') footBarTrans: number;
  @State isShowBackAsFront: boolean = false;
  @Prop @Watch('customFilterImmersiveChange') isCustomFilterImmersive: boolean = false;
  @State marginToShutterButton: Padding | undefined = undefined;
  @Link thumbnailViewArea: Area;
  @Link offsetX: number; // footbar的相机与缩略图偏移
  @Link offsetY: number;
  @State footBarCustomFilterOffsetY: number = 0;
  private windowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @Prop isHdr: boolean = false;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State isVdeLandscape: boolean = false;
  @Prop previewAnimatePosition: PositionType;
  @Prop previewHeight: number;
  @Prop previewWidth: number;
  @Prop @Watch('customFilterImmersiveChange') lineHeight: number;
  @Prop @Watch('customFilterImmersiveChange') footBarPosition: number;
  @Prop customFilterStackCardVieWPositionY: number;
  @State floatingFootBarOffset: number = 0;
  private curFootBarHeight: number = 0;
  private newFootBarHeight: number = 0;
  @Prop @Watch('customFilterImmersiveChange') staticFootBarTrans: number;
  @State @Watch('swipeRecordBlockUiStatusChange') isRightSwipeBlockUi: boolean = false;
  private uiBlockResetTimeout: number = -1;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        mode: state.get<ModeType>('modeReducer', 'mode'),
        videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
        collapsStatus: state.get<display.FoldStatus>('collapsReducer', 'collapsStatus'),
        isVdeCollapsed: state.get<boolean>('collapsReducer', 'isVdeCollapsed'),
        isShowtimeLapse: state.get<boolean>('settingReducer', 'isShowtimeLapse'),
      });
      this.currentMode = state.get<ModeType>('modeReducer', 'mode');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isShutterButtonLongClick = state.get<boolean>('leftRightSwipeReducer', 'longClicked');
      this.isLrShutterShown = state.get<boolean>('leftRightSwipeReducer', 'lrShutterShown');
      this.windowStatus = state.get<window.WindowStatusType>('windowReducer', 'windowStatus');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
      this.isRightSwipeBlockUi = state.get<boolean>('leftRightSwipeReducer', 'blockUi');
    }, null);
    this.mEventBus.on(RecordActionType.START, (data: RecordData) => this.onRecordStart(data), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_PICKER_REMAKE, () => this.onPickerRemake(), this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_NIGHT_CAPTURE_START, ActionType.ACTION_HIDE_BUTTON],
      () => this.isHideThumbnailAndSwitchButton(true), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_NIGHT_CAPTURE_END, () => this.isHideThumbnailAndSwitchButton(false),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LONG_EXPOSURE_SHUTTER,
      () => this.isHideThumbnailAndSwitchButton(true), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LONG_EXPOSURE_SHUTTER_END,
      () => this.isHideThumbnailAndSwitchButton(false), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, () => this.resetButton(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_IS_ENTER_IMMERSIVE, this.isEnterLrSwipeImmersive.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_IS_START_PANORAMA],
      () => this.isHideThumbnailAndSwitchButton(true), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_IS_END_PANORAMA, () => this.isHideThumbnailAndSwitchButton(false),
      this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_ON_PHOTO_STOP_PANORAMA], () => this.isHideThumbnailAndSwitchButton(false),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_START_STITCHING_CAPTURE, () => this.doHideStitchingAnimate(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_END_STITCHING_CAPTURE, () => this.doShowStitchingAnimation(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHANGE_TIME_LAPSE, this.timeLapseEnd.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL,
      (data: FunctionValueType) => this.changeFunctionValue(data),
      this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  private doHideStitchingAnimate(): void {
    this.immersiveOpacity = 1;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_150,
      onFinish: () => {
        this.mHideThumbnailAndSwitchButton = true;
      }
    }, () => {
      this.immersiveOpacity = 0;
    });
  }

  private doShowStitchingAnimation(): void {
    this.immersiveOpacity = 0;
    this.mHideThumbnailAndSwitchButton = false;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_150
    }, () => {
      this.immersiveOpacity = 1;
    });
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    clearTimeout(this.uiBlockResetTimeout);
    HiLog.i(TAG, 'aboutToDisappear X.');
  }

  private async onRecordStart(data: RecordData) {
    HiLog.i(TAG, 'onRecordStart E.');
    this.mCancelButtonHide = true;
    HiLog.i(TAG, 'onRecordStart X.');
  }

  private async onPickerRemake() {
    HiLog.i(TAG, 'onPickerRemake E.');
    this.mCancelButtonHide = false;
    HiLog.i(TAG, 'onPickerRemake X.');
  }

  private getIsShowRecordingControlButton(): boolean {
    return this.isPicker && this.state.videoState !== RecordingState.READY &&
      this.state.videoState !== RecordingState.STOPPING;
  }

  private getIsShowCameraSwitchButton(): boolean {
    HiLog.i(TAG, `mode: ${this.state.mode}, videoState:${this.state.videoState}`);
    if (this.isPicker && this.state.videoState !== RecordingState.READY) {
      return false;
    }
    if (this.isShowBackAsFront) {
      return false;
    }
    if (this.mCameraCount > 1) {
      return true;
    }
    return false;
  }

  private isEnterLrSwipeImmersive(data: ImmersiveActionData): void {
    let mIsImmersive: boolean = false;
    let mImmersiveUIType: UIOperationType = data.mainTrigCompo ?? UIOperationType.NULL;
    let json: ImmersiveActionData = JSON.parse(JSON.stringify(data));
    HiLog.i(TAG, `isEnterImmersive from action.`)
    if (json.isShowtimeLapse !== undefined) {
      mIsImmersive = json.isShowtimeLapse;
      mImmersiveUIType = mIsImmersive ? UIOperationType.TIMELAPSE : UIOperationType.NULL;
    } else {
      if (json.isImmersive !== undefined) {
        mIsImmersive = json.isImmersive;
      }
      if (json.mainTrigCompo !== undefined && mIsImmersive) {
        mImmersiveUIType = json.mainTrigCompo;
      }
    }
    if (mImmersiveUIType === UIOperationType.LR_SWIPE) {
      this.isInLrImmersive = mIsImmersive;
      this.lrImmersiveTrigger = this.isInLrImmersive;
    }
  }

  private onImmersiveOpacityChanged(): void {
    HiLog.i(TAG, 'onImmersiveOpacityChanged:' + this.immersiveOpacity);
  }

  private onThumbnailAndSwitchButtonChanged(): void {
    HiLog.i(TAG, 'onThumbnailAndSwitchButtonChanged:' + this.mHideThumbnailAndSwitchButton);
  }

  private enterAndExitLrSwipeAnim(): void {
    if (!this.separationForLRSwipeFootBar) {
      return;
    }
    if (this.lrImmersiveTrigger === null) {
      return;
    }
    HiLog.i(TAG, 'enterAndExitLrSwipeAnim longClick:' + this.isShutterButtonLongClick +
      ' immersiveScale:' + this.immersiveScale + ' longClickCache:' + this.shutterButtonLongClickCache);
    if (this.isShutterButtonLongClick !== this.shutterButtonLongClickCache) {
      HiLog.i(TAG, 'update longClickCache');
      // 进入沉浸式不能用沉浸式触发，用长按触发
      this.shutterButtonLongClickCache = this.isShutterButtonLongClick;
      if (this.isShutterButtonLongClick) {
        HiLog.i(TAG, 'enterLrImmersive');
        TipService.getInstance().showTip($r('app.string.left_right_swipe_toast'), TIP_DURING);
        if (this.enableScreenReader) {
          AccessibilityUtils.sendAnnounceAccessibilityEvent(`${ResGetter
            .getStringSafe($r('app.string.left_right_swipe_toast'))} ${ResGetter
            .getStringSafe($r('app.string.accessbility_camera_swipe_tip'))}`);
        }
        this.doDimAnimation();
        this.doShrinkAnimation();
      }
    } else {
      // 退出沉浸式由沉浸式触发
      if (!this.isShutterButtonLongClick) {
        HiLog.i(TAG, 'exitLrImmersive');
        this.doBrightAnimation();
        this.doExpandAnimation();
        this.lrImmersiveTrigger = null;
      }
    }
  }

  private doDimAnimation(): void {
    HiLog.i(TAG, 'doDimAnimation');
    this.immersiveOpacity = 1;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_150,
      onFinish: () => {
        this.sideImmersiveVisibility = Visibility.Hidden;
        HiLog.i(TAG, 'doDimAnimation end');
      }
    }, () => {
      this.immersiveOpacity = 0;
    });
  }

  private doBrightAnimation(): void {
    HiLog.i(TAG, 'doBrightAnimation');
    this.immersiveOpacity = 0;
    this.sideImmersiveVisibility = Visibility.Visible;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_150,
      onFinish: () => {
        if (this.immersiveOpacity !== 1) {
          this.immersiveOpacity = 1;
        }
        if (this.sideImmersiveVisibility === Visibility.Hidden) {
          this.sideImmersiveVisibility = Visibility.Visible;
        }
        HiLog.i(TAG, 'doBrightAnimation end');
      }
    }, () => {
      this.immersiveOpacity = 1;
    });
  }

  private doShrinkAnimation(): void {
    HiLog.i(TAG, 'doShrinkAnimation begin');
    this.sideShrinkAnimator?.cancel();
    this.sideExpandAnimator?.cancel();
    let options: AnimatorOptions = {
      duration: AnimSpecifications.ANIM_DURATION_400,
      easing: 'friction',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: 1,
      end: 0
    };
    if (this.sideShrinkAnimator) {
      try {
        this.sideShrinkAnimator.reset(options);
      } catch (error) {
        HiLog.i(TAG, `sideShrinkAnimator error:` + error.code);
      }
    } else {
      this.sideShrinkAnimator = animator.create(options);
    }
    this.sideShrinkAnimator.onframe = (value) => {
      this.immersiveScale = value;
    };
    this.sideShrinkAnimator.onfinish = () => {
      HiLog.i(TAG, 'doShrinkAnimation end');
      this.sideShrinkAnimator = null;
    }
    this.sideShrinkAnimator.oncancel = () => {
      HiLog.i(TAG, 'doShrinkAnimation oncancel');
      this.immersiveScale = 1;
      this.sideShrinkAnimator = null;
    }
    this.sideShrinkAnimator?.play();
  }

  private doExpandAnimation(): void {
    HiLog.i(TAG, 'doExpandAnimation begin');
    this.sideShrinkAnimator?.cancel();
    this.sideExpandAnimator?.cancel();
    let options: AnimatorOptions = {
      duration: AnimSpecifications.ANIM_DURATION_400,
      easing: 'friction',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: 0,
      end: 1
    };
    if (this.sideExpandAnimator) {
      try {
        this.sideExpandAnimator.reset(options);
      } catch (error) {
        HiLog.i(TAG, `sideExpandAnimator error:` + error.code);
      }
    } else {
      this.sideExpandAnimator = animator.create(options);
    }
    this.sideExpandAnimator.onframe = (value) => {
      this.immersiveScale = value;
    };
    this.sideExpandAnimator.onfinish = () => {
      HiLog.i(TAG, `doExpandAnimation end ${this.immersiveScale}`);
      if (this.immersiveScale !== 1) {
        this.immersiveScale = 1;
      }
      this.sideExpandAnimator = null;
    }
    this.sideExpandAnimator.oncancel = () => {
      HiLog.i(TAG, 'doExpandAnimation oncancel');
      this.immersiveScale = 0;
      this.sideExpandAnimator = null;
    }
    this.sideExpandAnimator?.play();
  }

  private swipeRecordBlockUiStatusChange(): void {
    HiLog.i(TAG, `isRightSwipeBlockUi ${this.isRightSwipeBlockUi}`);
    if (this.isRightSwipeBlockUi) {
      clearTimeout(this.uiBlockResetTimeout);
      this.uiBlockResetTimeout = setTimeout(() => {
        HiLog.w(TAG, `overTime isRightSwipeBlockUi reset from ${this.isRightSwipeBlockUi} `);
        this.isRightSwipeBlockUi = false;
      }, AnimSpecifications.ANIM_DELAY_1000);
    } else {
      this.isRightSwipeBlockUi = false;
      clearTimeout(this.uiBlockResetTimeout);
    }
  }

  build() {
    Stack() {
      Row() {
        this.leftSideIcon()
        ShutterButton({
          isPicker: this.isPicker,
          horizontallyArranged: true,
          touchEvent: this.touchEvent,
          isInLrImmersive: this.isInLrImmersive,
          innerHorizontalOffset: this.horizontalOffset
        })
          .scale({ x: this.footBarScale, y: this.footBarScale })
          .offset({ x: 0, y: this.offsetY })
        this.rightSideIcon()
      }
      .width('100%')
      .height('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .hitTestBehavior(HitTestMode.None)
      .zIndex(ZIndex.TOP)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)

      if (this.separationForLRSwipeFootBar && (this.isInLrImmersive || this.isLrShutterShown)) {
      }
    }
    .enabled(!this.isRightSwipeBlockUi)
    .margin({})
    .height(this.isVdeCollapsed ? '56vp' : 72)
    .width('100%')
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
  }

  @Builder
  rightSideIcon() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.state.isVdeCollapsed) {
        ZoomViewVde({ isHdr: this.isHdr });
      } else if (this.getIsShowCameraSwitchButton()) {
        CameraSwitchButton({
          mHideThumbnailAndSwitchButton: !this.mHideThumbnailAndSwitchButton,
          isHdr: this.isHdr
        })
      } else {
        //闪拍，高像素，流光快门、全景模式，延时摄影录像中等情况时占位，不然布局会偏右
        Column()
          .width(ICON_OUTER_HEIGHT)
          .height(ICON_OUTER_HEIGHT)
      }
      RecordingCaptureButton({
        isPicker: this.isPicker,
        isHdr: this.isHdr
      });
    }
    .scale({ x: this.footBarScale, y: this.footBarScale })
    .shrinkAndDimInLRSwipe()
    .offset({ x: SystemLanguageUtil.isRTL() ? this.offsetX : -this.offsetX, y: this.offsetY })
  }

  @Builder
  leftSideIcon() {
    Stack() {
      // picker取消按钮
      CircleImage({
        circleImageRes: $r('app.media.ic_camera_cancel'),
        onCircleImageClicked: () => {
          execDispatch(PickerAction.exitPickerWithoutResults());
        },
        isCancelViewVisibility: this.isCancelViewVisibility(),
        keyValue: ComponentIdKeys.THIRDPARTYCALL_BACK_1,
        abText: $r('sys.string.icon_cancel')
      })
      if (!this.isLemCollaps && !this.isPicker) {
        ThumbnailView({
          isThumbnailViewVisibility: this.isThumbnailViewVisibility()
        }).onAreaChange((oldValue, newValue) => {
          this.thumbnailViewArea = newValue
        });
      }
      if (this.getIsShowRecordingControlButton()) { // 录像控制按钮
        RecordingControlButton();
      }
    }
    .shrinkAndDimInLRSwipe()
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .offset({ x: SystemLanguageUtil.isRTL() ? -this.offsetX : this.offsetX, y: this.offsetY })
  }

  @Styles
  shrinkAndDimInLRSwipe() {
    .margin(this.state.isVdeCollapsed ? $r('sys.float.padding_level6') : 0)
    .scale({ x: this.immersiveScale, y: this.immersiveScale })
    .opacity(this.immersiveOpacity)
    .animation(undefined)
    .visibility(this.sideImmersiveVisibility)
  }

  private changeFunctionValue(data: FunctionValueType): void {
  }

  private async isHideThumbnailAndSwitchButton(visible: boolean) {
    HiLog.i(TAG, 'onHideThumbnailAndSwitchButton E.' + visible);
    this.mHideThumbnailAndSwitchButton = visible;
    HiLog.i(TAG, 'onHideThumbnailAndSwitchButton X.');
  }

  private isThumbnailViewVisibility() {
    return !this.mHideThumbnailAndSwitchButton;
  }

  private resetButton() {
    HiLog.i(TAG, 'resetButton E.');
    this.isHideThumbnailAndSwitchButton(false);
    this.immersiveOpacity = 1;
    this.sideImmersiveVisibility = Visibility.Visible;
    this.immersiveScale = 1;
    HiLog.i(TAG, 'resetButton X.');
  }

  private timeLapseEnd(data: ActionData) {
    HiLog.i(TAG, 'timeLapseEnd.');
  }

  private isCancelViewVisibility() {
    return this.state.videoState === RecordingState.READY && this.isPicker && !this.mCancelButtonHide;
  }

  private customFilterImmersiveOnChange() {
    if (this.isPicker) {
      return;
    }
    this.customFilterImmersiveChange();
  }

  private customFilterImmersiveChange() {
    if (this.isCustomFilterImmersive) {
      HiLog.i(TAG, `footBarTrans=${this.footBarTrans}`);
      // this.footBarTrans为0是点右上角展开，不为0是百宝箱展开
      // 为0是需要加一部分偏移量，不为0不用加
      animateToImmediately({ duration: CUSTOM_FILTER_DURATION, curve: Curve.Friction, delay: 0 }, () => {
        this.offsetX = CUSTOM_FILTER_OFFESET_X;
        this.offsetY = this.getOffsetY();
        this.footBarScale = this.footBarTrans ? CUSTOM_FILTER_FOOTER_SCALE_ONE : CUSTOM_FILTER_FOOTER_SCALE_TWO;
      });
    } else {
      let duration: number =
        CUSTOM_FILTER_DURATION;
      animateToImmediately({ duration: duration, curve: Curve.Friction, delay: 0 }, () => {
        this.offsetX = this.footBarTrans ? CUSTOM_FILTER_OFFESET_X_NORMAL : 0;
        this.offsetY = 0;
        this.footBarScale = this.footBarTrans ? CUSTOM_FILTER_FOOTER_SCALE_TWO : 1;
      });
    }
  }

  private getOffsetY(): number {
    if (this.isVdeLandscape || this.windowStatus === window.WindowStatusType.FLOATING) {
      this.curFootBarHeight = this.windowHeight - this.footBarPosition - this.footBarTrans;
      this.newFootBarHeight = CARD_NORMAL_HEIGHT + BOTTOM_HEIGHT + FOOT_BAR_OFFSET_Y + FOOT_BAR_HEIGHT;
    } else if (SizeUtil.is4To3Size(this.previewWidth, this.previewHeight) ||
    SizeUtil.is1To1Size(this.previewWidth, this.previewHeight)) {
      this.curFootBarHeight = this.windowHeight - this.footBarPosition - this.footBarTrans;
      this.newFootBarHeight = this.windowHeight - (this.previewAnimatePosition.y +
      this.previewHeight - this.lineHeight) + FOOT_BAR_OFFSET_Y + FOOT_BAR_HEIGHT;
      const middleHeight: number = this.windowHeight - (this.previewAnimatePosition.y +
      this.previewHeight - this.lineHeight) - CARD_NORMAL_HEIGHT - BOTTOM_HEIGHT;
      if (middleHeight > FOOT_BAR_HEIGHT) { // 预览和色盘间距大于footBar高度，footBar居中放置
        this.newFootBarHeight = CARD_NORMAL_HEIGHT + BOTTOM_HEIGHT +
          (middleHeight - FOOT_BAR_HEIGHT) / 2 + FOOT_BAR_HEIGHT;
      }
    } else {
      this.curFootBarHeight = this.windowHeight - this.footBarPosition - this.footBarTrans;
      this.newFootBarHeight = CARD_NORMAL_HEIGHT + BOTTOM_HEIGHT + FOOT_BAR_OFFSET_Y + FOOT_BAR_HEIGHT;
    }
    HiLog.i(TAG, `newFootBarHeight: ${this.newFootBarHeight}, curFootBarHeight: ${this.curFootBarHeight}`);
    return -(this.newFootBarHeight - this.curFootBarHeight);
  }
}