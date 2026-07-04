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

import lazy { CameraSwitchButton } from '@ohos/common/src/main/ets/function/cameraswitcher/CameraSwitchButton';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { OhCombinedState, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { RecordingControlButton } from '@ohos/common/src/main/ets/function/recordcontrol/RecordingControlButton';
import lazy { ShutterButton } from '@ohos/common/src/main/ets/function/capture/ShutterButton';
import lazy { ThumbnailView } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailView';
import lazy { COMPONENT_WIDTH } from './LandscapeIndex';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { CircleImage } from '@ohos/common/src/main/ets/component/picker/CircleImage';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { ChangeState, execDispatch, reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { OutputSwitcherButton } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcherButton';
import lazy { RecordingCaptureButton } from '@ohos/common/src/main/ets/function/recordcontrol/RecordingCaptureButton';
import lazy { ImmersiveActionData } from '@ohos/common/src/main/ets/utils/types';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { camera } from '@kit.CameraKit';
import lazy { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import animator, { AnimatorOptions, AnimatorResult } from '@ohos.animator';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { display } from '@kit.ArkUI';
import lazy { PickerAction } from '@ohos/common/src/main/ets/service/picker/PickerAction';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { RecordActionType } from '@ohos/common/src/main/ets/redux/actions/RecordActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { FOOT_BAR_HEIGHT } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService';

/* instrument ignore file */
const TAG: string = 'LandscapeFootBar';

const TIP_DURING: number = 3000;

// 不支持前后置切换的模式
const MODE_FOR_BACK: ModeType[] = [
]

class RecordData {
  public startTimeSeconds: number = 0;
}

class StateStruct {
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public videoState: RecordingState = RecordingState.READY;
  public mode: ModeType = ModeType.NONE;
}

@Component
export struct LandscapeFootBar {
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @Prop isPicker: boolean = false;
  @Prop isShowSemiCollapsed: boolean = false;
  @State showCameraSwitcher: boolean = true;
  @State videoState: RecordingState = RecordingState.READY;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State mHideThumbnailAndSwitchButton: boolean = false;
  @State mCancelButtonHide: boolean = false;
  @State state: StateStruct = new StateStruct();
  @State touchEvent: TouchEvent | null = null;
  @State isInLrImmersive: boolean = false;
  @State @Watch('enterAndExitLrSwipeAnim') lrImmersiveTrigger: boolean | null = false;
  @State @Watch('enterAndExitLrSwipeAnim') isShutterButtonLongClick: boolean = false;
  private shutterButtonLongClickCache: boolean = false;
  @State isSwipeFootBarShown: boolean = false;
  @State immersiveOpacity: number = 1;
  @State immersiveScale: number = 1;
  @State sideImmersiveVisibility: Visibility = Visibility.Visible;
  @State isLrShutterShown: boolean = false;
  // 隔离条件
  @State separationForLRSwipeFootBar: boolean = true;
  private sideShrinkAnimator: AnimatorResult | null = null; // 缩小动效
  private sideExpandAnimator: AnimatorResult | null = null; // 放大动效
  @Prop footBarScale: number;
  @State @Watch('collapsStateUpdated') collapsState: display.FoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  private collapsStateCache: display.FoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  @State horizontalOffset: number = 0;
  @Prop isHdr: boolean = false;
  @State @Watch('swipeRecordBlockUiStatusChange') isRightSwipeBlockUi: boolean = false;
  private uiBlockResetTimeout: number = -1;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.separationForLRSwipeFootBar = false;
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.collapsState = state.get<display.FoldStatus>('collapsReducer', 'collapsStatus');
      changeState(this.state, {
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        mode: state.get<ModeType>('modeReducer', 'mode'),
        videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
      });
      this.isShutterButtonLongClick = state.get<boolean>('leftRightSwipeReducer', 'longClicked');
      this.isLrShutterShown = state.get<boolean>('leftRightSwipeReducer', 'lrShutterShown');
      this.isRightSwipeBlockUi = state.get<boolean>('leftRightSwipeReducer', 'blockUi');
    }, null);
    this.mEventBus.on(RecordActionType.START, this.onRecordStart.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_PICKER_REMAKE, this.onPickerRemake.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_NIGHT_CAPTURE_START, this.onNightCaptureStart.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_NIGHT_CAPTURE_END, this.onNightCaptureEnd.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LONG_EXPOSURE_SHUTTER,
      this.onLongExposureShutter.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LONG_EXPOSURE_SHUTTER_END,
      this.onLongExposureShutterEnd.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackGround.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, () => this.onCameraStarted(), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_IS_ENTER_IMMERSIVE, this.isEnterLrSwipeImmersive.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_HIDE_BUTTON,
      () => this.isHideThumbnailAndSwitchButton(true), this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_IS_START_PANORAMA],
      () => this.isHideThumbnailAndSwitchButton(true), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_IS_END_PANORAMA, () => this.isHideThumbnailAndSwitchButton(false),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_PHOTO_STOP_PANORAMA, () => this.isHideThumbnailAndSwitchButton(false),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_START_STITCHING_CAPTURE, () => this.doHideStitchingAnimate(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_END_STITCHING_CAPTURE, () => this.doShowStitchingAnimation(),
      this.mBase.hashCode());
  }

  private onBackGround(): void {
    this.isHideThumbnailAndSwitchButton(false);
  }

  private onLongExposureShutterEnd(): void {
    this.isHideThumbnailAndSwitchButton(false);
  }

  private onLongExposureShutter(): void {
    this.isHideThumbnailAndSwitchButton(true);
  }

  private onNightCaptureEnd(): void {
    this.isHideThumbnailAndSwitchButton(false);
  }

  private onNightCaptureStart(): void {
    this.isHideThumbnailAndSwitchButton(true);
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
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    clearTimeout(this.uiBlockResetTimeout);
  }

  private collapsStateUpdated(): void {
    if (this.collapsStateCache !== display.FoldStatus.FOLD_STATUS_UNKNOWN && this.collapsStateCache !== this.collapsState) {
      if (this.collapsStateCache === display.FoldStatus.FOLD_STATUS_FOLDED ||
        this.collapsState === display.FoldStatus.FOLD_STATUS_FOLDED) {
        this.immersiveOpacity = 1;
        this.immersiveScale = 1;
      }
    }
    this.collapsStateCache = this.collapsState;
  }

  private onCameraStarted(): void {
    this.showCameraSwitcher = FeatureManager.getInstance().getFunction(FunctionId.CAMERA_SWITCHER)?.isAvailable();
  }

  private onRecordStart(data: RecordData): void {
    HiLog.i(TAG, 'onRecordStart E.');
    this.mCancelButtonHide = true;
    HiLog.i(TAG, 'onRecordStart X.');
  }

  private onPickerRemake(): void {
    HiLog.i(TAG, 'onPickerRemake E.');
    this.mCancelButtonHide = false;
    HiLog.i(TAG, 'onPickerRemake X.');
  }

  private getIsShowRecordingControlButton(): boolean {
    return this.state.videoState !== RecordingState.READY && this.state.videoState !== RecordingState.STOPPING;
  }

  private getIsShowCameraSwitchButton(): boolean {
    if (this.isPicker && this.state.videoState !== RecordingState.READY) {
      return false;
    }
    if (this.showCameraSwitcher && !MODE_FOR_BACK.includes(this.state.mode)) {
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
    this.immersiveOpacity = 1;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_150,
      onFinish: () => {
        this.sideImmersiveVisibility = Visibility.Hidden;
      }
    }, () => {
      this.immersiveOpacity = 0;
    });
  }

  private doBrightAnimation(): void {
    this.immersiveOpacity = 0;
    this.sideImmersiveVisibility = Visibility.Visible;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_150,
      onFinish: () => {
        if (this.sideImmersiveVisibility === Visibility.Hidden) {
          this.sideImmersiveVisibility = Visibility.Visible;
        }
      }
    }, () => {
      this.immersiveOpacity = 1;
    });
  }

  private doShrinkAnimation(): void {
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
      this.sideShrinkAnimator = null;
    }
    this.sideShrinkAnimator.oncancel = () => {
      this.immersiveScale = 1;
      this.sideShrinkAnimator = null;
    }
    this.sideShrinkAnimator?.play();
  }

  private doExpandAnimation(): void {
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
      this.sideExpandAnimator = null;
    }
    this.sideExpandAnimator.oncancel = () => {
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
      Flex({
        direction: this.isShowSemiCollapsed ? FlexDirection.RowReverse : FlexDirection.Column,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.SpaceBetween
      }) {
        this.topSideIcon()
        ShutterButton({
          isPicker: this.isPicker,
          horizontallyArranged: false,
          touchEvent: this.touchEvent,
          isInLrImmersive: this.isInLrImmersive,
          innerHorizontalOffset: this.horizontalOffset,
        })
        this.bottomSideIcon()
      }.width(this.isShowSemiCollapsed ? FOOT_BAR_HEIGHT : COMPONENT_WIDTH)
      .height(this.isShowSemiCollapsed ? COMPONENT_WIDTH : FOOT_BAR_HEIGHT)
      .hitTestBehavior(HitTestMode.None)
    }
    .enabled(!this.isRightSwipeBlockUi)
  }

  @Builder
  bottomSideIcon() {
    Stack() {
      if (this.isPicker) {
        CircleImage({
          circleImageRes: $r('app.media.ic_camera_cancel'),
          onCircleImageClicked: () => {
            execDispatch(PickerAction.exitPickerWithoutResults());
          },
          isCancelViewVisibility: this.isCancelViewVisibility(),
          keyValue: ComponentIdKeys.THIRDPARTYCALL_BACK_1,
          abText: $r('sys.string.icon_cancel')
        });
        if (this.getIsShowRecordingControlButton()) {
          RecordingControlButton();
        }
      } else {
        ThumbnailView({
          isThumbnailViewVisibility: this.isThumbnailViewVisibility()
        });
      }
    }
    .visibility(this.isShowRecordingComp() ? Visibility.Visible : Visibility.Hidden)
    .shrinkAndDimInLRSwipe();
  }

  @Builder
  topSideIcon() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.getIsShowCameraSwitchButton()) {
        CameraSwitchButton({
          mHideThumbnailAndSwitchButton: this.isThumbnailViewVisibility(),
          isHdr: this.isHdr
        })
      } else {
        //闪拍，高像素，流光快门、全景模式，延时摄影录像中在展开态或者是半折态等情况时占位，不然布局会偏上
        Column()
          .width(44)
          .height(44)
      }
      RecordingCaptureButton({
        isPicker: this.isPicker,
        isHdr: this.isHdr
      });
    }
    .visibility(this.isShowRecordingComp() ? Visibility.Visible : Visibility.Hidden)
    .shrinkAndDimInLRSwipe();
  }

  @Styles
  shrinkAndDimInLRSwipe() {
    .scale({ x: this.immersiveScale, y: this.immersiveScale })
    .opacity(this.immersiveOpacity)
    .visibility(this.sideImmersiveVisibility);
  }

  private isCancelViewVisibility() {
    return this.videoState === RecordingState.READY && !this.mCancelButtonHide;
  }

  private isHideThumbnailAndSwitchButton(visible: boolean): void {
    HiLog.i(TAG, 'onHideThumbnailAndSwitchButton E.' + visible);
    this.mHideThumbnailAndSwitchButton = visible;
    HiLog.i(TAG, 'onHideThumbnailAndSwitchButton X.');
  }

  private isThumbnailViewVisibility() {
    return !this.mHideThumbnailAndSwitchButton;
  }

  private isShowRecordingComp(): boolean {
    return true;
  }
}