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

import lazy { HiLog } from '../../utils/HiLog';
import lazy { OhCombinedState, Dispatch, getStates } from '../../redux';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { RecordMode } from './RecordMode';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { FunctionAction } from '../core/FunctionAction';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { RecordAction, RecordingState } from './RecordAction';
import lazy { Action } from '../../redux/actions/Action';
import lazy { ChangeState, reduxSubscribe, Unsubscribe } from '../../redux/Store';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { window } from '@kit.ArkUI';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import ResGetter from '../../utils/ResGetter';
import lazy { AccessibilityUtils } from '../../utils/AccessibilityUtils';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { CollaborateControlActionType } from '../../redux/actions/CollaborateControlActionType';
/* instrument ignore file */

const TAG: string = 'RecordingControlButton';

class StateStruct {
  public videoState: RecordingState = RecordingState.READY;
  public rotateAngle: number = 0;
}

class RecordingControlDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public disAbleUi(): void {
    this.mDispatch(Action.uiState(false));
  }

  public pauseRecording(): void {
    this.mDispatch(RecordAction.pause(true));
    this.mDispatch(FunctionAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_PAUSE));
  }

  public resumeRecording(): void {
    this.mDispatch(RecordAction.resume(true));
    this.mDispatch(FunctionAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_RESUME));
  }
}

@Component
export struct RecordingControlButton { // use by phone FootBar
  @State state: StateStruct = new StateStruct();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State isShow: boolean = false;
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @State isRecording: boolean = true;
  @State isPausing: boolean = false;
  @State recordButtonScale: ScaleOptions = { x: 1, y: 1 };
  @State recordScale: ScaleOptions = { x: 1, y: 1 };
  @State pauseScale: ScaleOptions = { x: 0, y: 0 };
  @State recordButtonOpacity: number = 0;
  @State recordOpacity: number = 1;
  @State pauseOpacity: number = 0;
  @State rotateAngle: number = 0;
  @State isShowSubScreenRadius: boolean = false;
  @State @Watch('updateDensity') density: number = 1//DisplayService.getInstance().getDisplay().densityPixels;
  private isAnimating: boolean = false;
  private uiEnable: boolean = false;
  private isRecordStartAnimating: boolean = false;
  private mAction: RecordingControlDispatcher = new RecordingControlDispatcher();
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false;
  @State isShowRingLightView: boolean = false;
  @State isVdeCollapsed: boolean = false;
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();

  aboutToAppear() {
    HiLog.d(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      changeState(this.state, {
        videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
        rotateAngle: state.get<number>('contextReducer', 'rotateAngle')
      });
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.density = state.get<number>('collapsReducer', 'density');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.mEventBus.on(CollaborateControlActionType.RESUME, this.onCollaborateControlResume.bind(this),
      this.mBase.hashCode());
    HiLog.d(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear(): void {
    this.mSubscriber.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
  }

  private onCollaborateControlResume(): void {
    HiLog.i(TAG, 'onCollaborateControlResume.');
    this.recordDownAnim();
    setTimeout((): void => {
      this.recordUpAnim();
      if (!this.isAnimating) {
        this.recordUp();
      }
    });
  }

  private recordToPauseAnim(): void {
    this.isPausing = true;
    this.isAnimating = true;
    this.recordOpacity = 1;
    this.pauseOpacity = 0;
    this.recordScale = { x: 1, y: 1 };
    this.pauseScale = { x: 0, y: 0 };

    animateToImmediately(
      {
        duration: 100,
        curve: Curve.Sharp
      },
      () => {
        this.recordOpacity = 0;
        this.pauseOpacity = 1;
      })

    animateToImmediately(
      {
        curve: AnimSpecifications.ANIM_VIDEO_CURVE,
        onFinish: () => {
          this.isRecording = false;
          this.isAnimating = false;
        }
      },
      () => {
        this.recordScale = { x: 0, y: 0 };
        this.pauseScale = { x: 1, y: 1 };
      })
  }

  private pauseToRecordAnim(): void {
    this.isRecording = true;
    this.isAnimating = true;
    this.recordOpacity = 0;
    this.pauseOpacity = 1;
    this.recordScale = { x: 0, y: 0 };
    this.pauseScale = { x: 1, y: 1 };

    animateToImmediately(
      {
        duration: 100,
        curve: Curve.Sharp
      },
      () => {
        this.recordOpacity = 1;
        this.pauseOpacity = 0;
      })

    animateToImmediately(
      {
        curve: AnimSpecifications.ANIM_VIDEO_CURVE,
        onFinish: () => {
          this.isPausing = false;
          this.isAnimating = false;
        }
      },
      () => {
        this.recordScale = { x: 1, y: 1 };
        this.pauseScale = { x: 0, y: 0 };
      })
  }

  private recordDownAnim(): void {
    this.recordButtonScale = { x: 1, y: 1 }
    animateToImmediately(
      {
        curve: AnimSpecifications.ANIM_VIDEO_CURVE
      },
      () => {
        this.recordButtonScale = { x: 0.9, y: 0.9 }
      })
  }

  private getAnimationDuration(): number {
    return AnimSpecifications.ANIM_DURATION_300;
  }

  private recordUpAnim(): void {
    this.recordButtonScale = { x: 0.9, y: 0.9 }
    animateToImmediately(
      {
        curve: AnimSpecifications.ANIM_VIDEO_CURVE
      },
      () => {
        this.recordButtonScale = { x: 1, y: 1 }
      })
  }

  private recordUp() {
    HiLog.i(TAG, `recordUp videoState:${this.state.videoState}`)
    if (this.state.videoState === RecordingState.RECORDING) {
      // 无障碍 暂停
      if (this.enableScreenReader && !this.isOpenTouchGuide) {
        HiLog.i(TAG, 'recordUp sendAnnounceAccessibilityEvent video_pause');
        AccessibilityUtils.sendAnnounceAccessibilityEvent(ResGetter.getStringSafe($r('app.string.video_pause')));
      }
      this.mAction.pauseRecording();
      this.recordToPauseAnim();
    } else if (this.state.videoState === RecordingState.PAUSED) {
      // 无障碍 继续
      if (this.enableScreenReader && !this.isOpenTouchGuide) {
        HiLog.i(TAG, 'recordUp sendAnnounceAccessibilityEvent video_resume');
        AccessibilityUtils.sendAnnounceAccessibilityEvent(ResGetter.getStringSafe($r('app.string.video_resume')));
      }
      this.mAction.disAbleUi();
      this.mAction.resumeRecording();
      this.pauseToRecordAnim();
    }
  }

  private videoStateOnChange() {
    HiLog.d(TAG, `videoStateOnChange videoState:${this.videoState}.`);
    if (this.videoState === RecordingState.STARTING) {
      this.recordStartAnim();
    } else if (this.videoState === RecordingState.STOPPING) {
      this.recordEndAnim();
    }
  }

  private recordStartAnim() {
    HiLog.d(TAG, 'recordStartAnim');
    this.isRecordStartAnimating = true;
    this.recordOpacity = 0;
    this.recordScale = { x: 0, y: 0 };
    this.recordButtonOpacity = 0;
    this.recordButtonScale = { x: 0, y: 0 };
    this.isRecording = true;
    this.isShow = true;
    animateToImmediately(
      {
        duration: 300,
        curve: Curve.Friction,
        onFinish: () => {
          this.isRecordStartAnimating = false;
          HiLog.d(TAG, 'recordStartAnim onFinish');

          const windowStageEventType: window.WindowStageEventType | undefined = AppStorage.get('windowStageEventType');
          const isWindowInactive: boolean = windowStageEventType === window.WindowStageEventType.PAUSED ||
            windowStageEventType === window.WindowStageEventType.INACTIVE ||
            windowStageEventType === window.WindowStageEventType.HIDDEN;
          if (isWindowInactive) {
            this.recordOpacity = 0;
            this.pauseOpacity = 0;
            this.recordScale = { x: 0, y: 0 };
            this.pauseScale = { x: 0, y: 0 };

            this.isShow = false;
            this.isRecording = true;
            this.isPausing = false;
          }
        }
      },
      () => {
        this.recordScale = { x: 1, y: 1 };
        this.recordButtonScale = { x: 1, y: 1 };
      }
    )
    animateToImmediately(
      {
        delay: 50,
        duration: 150,
        curve: Curve.Sharp,
        onFinish: () => {
        }
      },
      () => {
        this.recordOpacity = 1;
        this.recordButtonOpacity = 1;
      }
    )
  }

  private recordEndAnim() {
    HiLog.d(TAG, 'recordEndAnim');
    this.recordOpacity = 1;
    this.pauseOpacity = 1;
    this.recordScale = { x: 1, y: 1 };
    this.pauseScale = { x: 1, y: 1 };
    this.recordButtonOpacity = 1;
    this.recordButtonScale = { x: 1, y: 1 };
    animateToImmediately(
      {
        duration: 300,
        curve: Curve.Friction,
        onFinish: () => {
          HiLog.d(TAG, 'recordEndAnim onFinish');
          if (this.isRecordStartAnimating) {
            return;
          }
          this.isShow = false;
          this.isRecording = true;
          this.isPausing = false;
        }
      },
      () => {
        this.recordScale = { x: 0, y: 0 };
        this.pauseScale = { x: 0, y: 0 };
        this.recordButtonOpacity = 0;
        this.recordButtonScale = { x: 0, y: 0 };
      }
    )
    animateToImmediately(
      {
        delay: 50,
        duration: 150,
        curve: Curve.Sharp,
        onFinish: () => {
        }
      },
      () => {
        this.recordOpacity = 0;
        this.pauseOpacity = 0;
      }
    )
  }

  private getRecordControlVis(): boolean {
    if (!this.isShow) {
      return false;
    }
    const mode = getStates().get<ModeType>('modeReducer', 'mode');
    return true;
  }

  private updateDensity() {
    HiLog.i(TAG, 'updateDensity density=' + this.density);
  }

  build() {
    if (this.getRecordControlVis()) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(this.isVdeCollapsed ? 28 : 44)
          .aspectRatio(1)
          .border({
            width: 1.5,
            color: Color.White,
            radius: $r('app.float.thumbnail_radius'),
            style: BorderStyle.Solid
          })
          .backgroundColor(this.isPausing && this.pauseOpacity ?
            (Color.White) : undefined)
        if (this.isRecording) {
          Image($r('app.media.ic_video_pause'))
            .width(this.isVdeCollapsed ? 20 : 24)
            .height(this.isVdeCollapsed ? 20 : 24)
            .objectFit(ImageFit.Cover)
            .aspectRatio(1)
            .fillColor(Color.White)
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
            .key(ComponentIdKeys.VIDEO_RECORDING_1)
            .opacity(this.recordOpacity)
            .scale(this.recordScale)
        }
        if (this.isPausing) {
          Image($r('app.media.ic_video_continue'))
            .width(12)
            .aspectRatio(1)
            .fillColor(Color.Red)
            .key(ComponentIdKeys.VIDEO_PAUSE_1)
            .opacity(this.pauseOpacity)
            .scale(this.pauseScale)
            .draggable(false)
        }
      }
      .width(this.isVdeCollapsed ? 28 : 44)
      .aspectRatio(1)
      .borderRadius($r('app.float.thumbnail_radius'))
      .backgroundColor('#334d4d4d')
      .animation({
        duration: AnimSpecifications.ANIM_DURATION_300,
        curve: Curve.Friction,
        iterations: 1,
        playMode: PlayMode.Normal,
      })
      .scale(this.recordButtonScale)
      .opacity(this.recordButtonOpacity)
      .visibility(this.getRecordControlVis() ? Visibility.Visible : Visibility.Hidden)
      .onTouch((event?: TouchEvent) => {
        if (!event || !this.uiEnable) {
          return;
        }
        if (event?.type === TouchType.Down) {
          this.recordDownAnim();
        } else if (event?.type === TouchType.Up) {
          this.recordUpAnim();
          if (!this.isAnimating) {
            this.recordUp();
          }
        } else if (event?.type === TouchType.Cancel) {
          this.recordUpAnim();
        }
      })
      .accessibilityGroup(true)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilityText(this.getAbText())
      .accessibilityDescription(ResGetter.getStringSafe($r('app.string.accessibility_clickable')))
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .onClickStyle();
    }
  }

  private getAbText(): string {
    HiLog.i(TAG, 'getAbText.');
    if (this.isOpenTouchGuide) {
      if (this.videoState === RecordingState.RECORDING || this.videoState === RecordingState.RESUMING) {
        return `${ResGetter.getStringSafe($r('app.string.video_pause')) +
        ResGetter.getStringSafe($r('app.string.video_mode'))}`;
      }
      if (this.videoState === RecordingState.PAUSED || this.videoState === RecordingState.PAUSING) {
        return `${ResGetter.getStringSafe($r('app.string.video_resume')) +
        ResGetter.getStringSafe($r('app.string.video_mode'))}`;
      }
    }
    return ' ';
  }

  @Styles
  private onClickStyle() {
    .onClick((event) => {
      // 仅在无障碍服务下生效
      if (event && this.enableScreenReader && this.isOpenTouchGuide && this.uiEnable) {
        if (!this.isAnimating) {
          this.recordUp();
        }
      }
    })
  }
}