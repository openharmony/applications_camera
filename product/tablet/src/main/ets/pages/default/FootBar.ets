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

import { CameraSwitchButton } from '@ohos/common/src/main/ets/function/cameraswitcher/CameraSwitchButton';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { OhCombinedState, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { ShutterButton } from '@ohos/common/src/main/ets/function/capture/ShutterButton';
import { ThumbnailView } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailView';
import { COMPONENT_WIDTH } from './DefaultIndex';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { CircleImage } from '@ohos/common/src/main/ets/component/picker/CircleImage';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import { ChangeState, execDispatch } from '@ohos/common/src/main/ets/redux/Store';
import { OutputSwitcherButton } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcherButton';
import { RecordingCaptureButton } from '@ohos/common/src/main/ets/function/recordcontrol/RecordingCaptureButton';
import { ImmersiveActionData } from '@ohos/common/src/main/ets/utils/types';
import { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import { camera } from '@kit.CameraKit';
import { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import animator, { AnimatorOptions, AnimatorResult } from '@ohos.animator';
import { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import { PickerAction } from '@ohos/common/src/main/ets/service/picker/PickerAction';
import { MODE_BAR_HEIGHT } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService';
import { PickerWindowType } from '@ohos/common/src/main/ets/component/picker/PickerWindowType';
import { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import { reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import { FOOT_BAR_HEIGHT } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService';

const TAG: string = 'FootBar';

const TIP_DURING: number = 3000;

class StateStruct {
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public mode: ModeType = ModeType.NONE;
  public isShowtimeLapse: boolean = false;
}

@Component
export struct FootBar {
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @Prop isPicker: boolean = false;
  @State windowHeight: number = 0;
  @State pickerWindowType: PickerWindowType = PickerWindowType.TABLET_FULL_SCREEN;
  @State videoState: RecordingState = RecordingState.READY;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State mHideThumbnailAndSwitchButton: boolean = false;
  private mBase: BaseComponent = new BaseComponent();
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
  @State horizontalOffset: number = 0;
  @State @Watch('swipeRecordBlockUiStatusChange') isRightSwipeBlockUi: boolean = false;
  private uiBlockResetTimeout: number = -1;

  private setEventBusOn(): void {
    this.mEventBus.on([ActionType.ACTION_NIGHT_CAPTURE_START, ActionType.ACTION_HIDE_BUTTON],
      () => this.isHideThumbnailAndSwitchButton(true),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_NIGHT_CAPTURE_END, () => this.isHideThumbnailAndSwitchButton(false),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LONG_EXPOSURE_SHUTTER,
      () => this.isHideThumbnailAndSwitchButton(true), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LONG_EXPOSURE_SHUTTER_END,
      () => this.isHideThumbnailAndSwitchButton(false), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, () => this.isHideThumbnailAndSwitchButton(false),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_IS_ENTER_IMMERSIVE, this.isEnterLrSwipeImmersive.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHANGE_TIME_LAPSE, this.timeLapseEnd.bind(this), this.mBase.hashCode());
    this.mEventBus.on([ActionType.ACTION_IS_START_PANORAMA],
      () => this.isHideThumbnailAndSwitchButton(true), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_IS_END_PANORAMA, () => this.isHideThumbnailAndSwitchButton(false),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_PHOTO_STOP_PANORAMA, () => this.isHideThumbnailAndSwitchButton(false),
      this.mBase.hashCode());
  }

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E.');
    const featureManager = FeatureManager.getInstance();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.pickerWindowType = state.get<PickerWindowType>('windowReducer', 'pickerWindowType');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      changeState(this.state, {
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        mode: state.get<ModeType>('modeReducer', 'mode'),
        isShowtimeLapse: state.get<boolean>('settingReducer', 'isShowtimeLapse')
      });
      this.isShutterButtonLongClick = state.get<boolean>('leftRightSwipeReducer', 'longClicked');
      this.isLrShutterShown = state.get<boolean>('leftRightSwipeReducer', 'lrShutterShown');
      this.isRightSwipeBlockUi = state.get<boolean>('leftRightSwipeReducer', 'blockUi');
    }, null);
    this.setEventBusOn();
  }

  aboutToDisappear(): void {
    this.mSubscriber.destroy();
    clearTimeout(this.uiBlockResetTimeout);
  }

  private timeLapseEnd(data: ActionData) {
    HiLog.i(TAG, 'timeLapseEnd.');
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
      duration: AnimSpecifications.ANIM_DURATION_150
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

  private getFootBarHeight(): number {
    if (this.pickerWindowType === PickerWindowType.TABLET_1_3_SPLIT_SCREEN) {
      if (FOOT_BAR_HEIGHT > this.windowHeight) {
        return this.windowHeight;
      } else {
        return FOOT_BAR_HEIGHT;
      }
    }
    if (this.windowHeight - FOOT_BAR_HEIGHT > 0.1 * this.windowHeight || !PickerUtils.getIsPicker()) {
      return FOOT_BAR_HEIGHT;
    }
    return this.windowHeight - MODE_BAR_HEIGHT + 24;
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
      Column() {
        this.topSideIcon()
        ShutterButton({
          isPicker: this.isPicker,
          horizontallyArranged: false,
          touchEvent: this.touchEvent,
          isInLrImmersive: this.isInLrImmersive,
        })
        this.bottomSideIcon()
      }
      .width(COMPONENT_WIDTH)
      .height(this.getFootBarHeight())
      .key(ComponentIdKeys.FOOT_BAR_COLUMN)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .hitTestBehavior(HitTestMode.None)

      if (this.separationForLRSwipeFootBar && (this.isInLrImmersive || this.isLrShutterShown)) {
      }
    }
    .key(ComponentIdKeys.FOOT_BAR_STACK)
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
          isCancelViewVisibility: this.videoState === RecordingState.READY,
          keyValue: ComponentIdKeys.THIRDPARTYCALL_BACK_1,
          abText: $r('sys.string.icon_cancel')
        });
      } else {
        ThumbnailView({
          isThumbnailViewVisibility: this.isThumbnailViewVisibility()
        })
          .width($r('app.float.margin_value_44'))
          .aspectRatio(1);
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
          mHideThumbnailAndSwitchButton: this.isThumbnailViewVisibility()
        })
      } else {
        //闪拍，高像素，流光快门、全景模式，延时摄影录像中在展开态或者是半折态等情况时占位，不然布局会偏上
        Column()
          .width(44)
          .height(44)
      }
      RecordingCaptureButton({ isPicker: this.isPicker });
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

  private getIsShowCameraSwitchButton(): boolean {
    if (this.isPicker && this.videoState !== RecordingState.READY) {
      return false;
    }
    return false;
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