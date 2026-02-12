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

import lazy { Action, ActionData, UiStateMode } from '../../redux/actions/Action';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { RecordAction, RecordingState } from '../recordcontrol/RecordAction';
import lazy { OhCombinedState, Unsubscribe, Dispatch, reduxSubscribe, getStates } from '../../redux';
import lazy { FunctionAction } from '../core/FunctionAction';
import lazy { RecordMode } from '../recordcontrol/RecordMode';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { CaptureAction } from './CaptureAction';
import lazy { ChangeState } from '../../redux/Store';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import CommonEventManager from '../../component/commonevent/CommonEventManager';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { CameraRunningState } from '../../camera/uithread/CameraAction';
import lazy { UIOperationType } from '../../component/uicomponent/UIOperationType';
import lazy { StoreManager } from '../../worker/StoreManager';
import ResGetter from '../../utils/ResGetter';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { FloatingShutterActionType } from '../../redux/actions/FloatingShutterActionType';
import lazy { CaptureActionType } from '../../redux/actions/CaptureActionType';
import lazy { SystemLanguageUtil } from '../../utils/SystemLanguageUtil';
import lazy { PowerKeyService } from '../../service/powerKey/PowerKeyService';
import { MemoryService } from '../../service/Memory/MemoryService';

/* instrument ignore file */
const TAG: string = 'ContinuumVideoButton';
const SHUTTER_OUT_SHADE_COLOR: string = '#334d4d4d';

class StateStruct {
  public uiEnable: boolean = false;
  public mode: ModeType = ModeType.NONE;
  public isShowtimeLapse: boolean = false;
  public isLocked: boolean = false;
}

class VideoErrorData {
  public code: number = 0;
  public msg: string = '';
}

class VolumeKeyPhotoData {
  public isDown: boolean = false;
}

class ShutterButtonDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public capture(): void {
    this.mDispatch(CaptureAction.capture());
  }

  public startRecording(): void {
    this.mDispatch(Action.uiStateWithMode(false, UiStateMode.EXCLUDE_PREVIEW));
    this.mDispatch(RecordAction.start());
  }

  public pauseRecording(): void {
    this.mDispatch(Action.uiStateWithMode(false, UiStateMode.EXCLUDE_PREVIEW));
    this.mDispatch(RecordAction.pause(true));
  }

  public resumeRecording(): void {
    this.mDispatch(Action.uiStateWithMode(false, UiStateMode.EXCLUDE_PREVIEW));
    this.mDispatch(RecordAction.resume(true));
  }

  public stopRecording(): void {
    this.mDispatch(Action.uiStateWithMode(false, UiStateMode.EXCLUDE_PREVIEW));
    this.mDispatch(RecordAction.stop());
  }

  public changeTimeLapse(isShowtimeLapse: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse));
  }

  public changeFunctionValue(id: FunctionId, value: RecordMode | boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public enableUiWithMode(uiStateMode: UiStateMode, excludeComponent: string): void {
    this.mDispatch(Action.uiStateWithMode(true, uiStateMode, excludeComponent));
  }

  public disableUiWithMode(uiStateMode: UiStateMode, excludeComponent: string): void {
    this.mDispatch(Action.uiStateWithMode(false, uiStateMode, excludeComponent));
  }

  public isShowExtendBarAndParamBar(): void {
    this.mDispatch(Action.updateIsShowParamBar(true));
    this.mDispatch(Action.updateIsShowExtendBar(false));
  }
}

@Component
export struct ContinuumVideoButton {
  private mBase: BaseComponent = new BaseComponent();
  type: ButtonType = ButtonType.Normal;
  stateEffect: boolean = false;
  @State state: StateStruct = new StateStruct();
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @State isShowCapture: boolean = false;
  @State captureBtnScale: number = 1;
  private mAction: ShutterButtonDispatcher = new ShutterButtonDispatcher();
  @State videoWidth: number = 64;
  @State videoHeight: number = 64;
  @State videoRadius: number = 32;
  @State videoColor: Color = AnimSpecifications.ANIM_VIDEO_BUTTON_COLOR_END;
  @State isShowPause: boolean = false;
  @State circleWidth: number = 48;
  @State circleRadius: number = 24;
  @State circleOpacity: number = 1;
  @State circleScale: ScaleOptions = { x: 1, y: 1 };
  @State videoBtnImg: Resource = $r('app.media.ic_video_pause');
  @State leftTrans: TranslateOptions = { x: 0 };
  @State rightTrans: TranslateOptions = { x: 0 };
  @State isFocusAcquisition: boolean = false;
  @State isShowRingLightView: boolean = false;
  @State @Watch('rotateAngleChanged') rotateAngleWatch: number = 0;
  @State rotateAngle: number = 0;
  @State uiEnable: boolean = false;
  @State excludeComponent: string = UIOperationType.NULL;
  private mSubscriber: Unsubscribe | null = null;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private isManualChanged: boolean = false;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false;

  aboutToAppear(): void {
    HiLog.d(TAG, 'aboutToAppear E.');
    this.rotateAngle = getStates().get<number>('contextReducer', 'rotateAngle');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      changeState(this.state, {
        uiEnable: state.get<boolean>('contextReducer', 'uiEnable'),
        mode: state.get<ModeType>('modeReducer', 'mode'),
        isShowtimeLapse: state.get<boolean>('settingReducer', 'isShowtimeLapse'),
        isLocked: state.get<boolean>('contextReducer', 'isLocked'),
      });
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.excludeComponent = state.get<string>('contextReducer', 'excludeComponent');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.rotateAngleWatch = state.get<number>('contextReducer', 'rotateAngle');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });

    this.mEventBus.on(RecordActionType.ERROR, this.onVideoError.bind(this), this.mBase.hashCode());
    this.mEventBus.on([ContextActionType.DEV_ON_SHUTDOWN, ContextActionType.ABILITY_ON_BACKGROUND],
      this.onDevShutDown.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHANGE_TIME_LAPSE, this.timeLapseEnd.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CommonEventManager.SCREEN_CHANGE_EVENT, this.sleepToStopRecord.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.SCREEN_LOCKED_STATE, this.lockedStopRecord.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FloatingShutterActionType.FLOATING_SHUTTER_BUTTON_CLICK,
      this.clickFloatingShutterButton.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.VOLUME_KEY_EVENT, this.volumeKeyEventShutter.bind(this), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.PAUSE, this.onRecordPause.bind(this), this.mBase.hashCode());
    this.mEventBus.on([RecordActionType.RESUME, RecordActionType.RELEASE], this.onRecordResume.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), this.mBase.hashCode());
    HiLog.d(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear(): void {
    HiLog.d(TAG, 'aboutToDisappear E.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber?.destroy();
    HiLog.d(TAG, 'aboutToDisappear X.');
  }

  private onForeground() {
    if (getStates().get<RecordingState>('recordReducer', 'recordingState') !== RecordingState.READY) {
      StoreManager.getInstance().postMessage(RecordAction.stopped());
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

  private onVideoError(data: VideoErrorData) {
    HiLog.i(TAG, `onVideoError  errorCode : ${data.code} errorMsg : ${data.msg}`);
    this.mAction.stopRecording();
    this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
  }

  private lockedStopRecord(): void {
    HiLog.i(TAG, 'lockedStopRecord E');
    if (this.videoState === RecordingState.RECORDING && this.state.isLocked) {
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
    }
    HiLog.i(TAG, 'lockedStopRecord X');
  }

  private sleepToStopRecord(data: boolean): void {
    HiLog.i(TAG, 'sleepToStopRecord E');
    if (this.videoState === RecordingState.RECORDING && !data) {
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
    }
    HiLog.i(TAG, 'sleepToStopRecord X');
  }

  private onDevShutDown() {
    HiLog.i(TAG, `Shutdown event triggered. Video state is ${this.videoState}`);
    if (this.videoState === RecordingState.RECORDING || this.videoState === RecordingState.PAUSING ||
      this.videoState === RecordingState.PAUSED || this.videoState === RecordingState.RESUMING) {
      HiLog.i(TAG, 'Shutdown event triggered. Stop recording.');
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
    }
  }

  private videoStateOnChange() {
    HiLog.i(TAG, `videoStateOnChange videoState:${this.videoState}.`);
    if (this.videoState === RecordingState.STARTING) {
      WindowService.getInstance().setWindowKeepScreenOn(true);
      return;
    }
    if (this.videoState === RecordingState.STOPPING) {
      WindowService.getInstance().setWindowKeepScreenOn(false);
      this.endVideoAnim();
    }
  }

  private timeLapseEnd(data: ActionData) {
    HiLog.i(TAG, 'timeLapseEnd.');
    // 录像模式倒计时被打断按钮恢复
    if (this.state.mode === 'VIDEO' && !this.state.isShowtimeLapse && data['timeLapseInterrupt']) {
      this.endVideoAnim();
    }
  }

  private onPhotoShutterUp(): void {
    animateToImmediately(
      {
        curve: AnimSpecifications.ANIM_CAPTURE_CURVE,
        onFinish: () => {
        }
      },
      () => {
        this.captureBtnScale = 1;
      })
  }

  private startVideoAnim() {
    HiLog.i(TAG, 'startVideoAnim');
    this.videoColor = AnimSpecifications.ANIM_VIDEO_BUTTON_COLOR_END;
    animateToImmediately(
      {
        duration: 300,
        curve: Curve.Friction
      },
      () => {
        this.videoWidth = 120;
        this.videoHeight = 56;
        this.videoRadius = 26;
        this.circleWidth = 20;
        this.circleRadius = 4;
        this.circleOpacity = 0;
        this.circleScale = { x: 0, y: 0 };
        this.isShowPause = true;
        this.leftTrans = { x: SystemLanguageUtil.isRTL() ? 30 : -30 };
        this.rightTrans = { x: SystemLanguageUtil.isRTL() ? -30 : 30 };
        this.videoColor = AnimSpecifications.ANIM_VIDEO_BUTTON_COLOR_START;
      })
  }

  private endVideoAnim() {
    HiLog.i(TAG, 'endVideoAnim');
    this.isShowPause = false;
    this.videoColor = AnimSpecifications.ANIM_VIDEO_BUTTON_COLOR_START;
    animateToImmediately(
      {
        duration: 300,
        curve: Curve.Friction
      },
      () => {
        this.videoWidth = 64;
        this.videoHeight = 64;
        this.videoRadius = 32;
        this.circleWidth = 48;
        this.circleRadius = 24;
        this.circleOpacity = 1;
        this.circleScale = { x: 1, y: 1 };
        this.leftTrans = { x: 0 };
        this.rightTrans = { x: 0 };
        this.videoColor = AnimSpecifications.ANIM_VIDEO_BUTTON_COLOR_END;
      })
  }

  private videoInnerClickFn(): void {
    if (MemoryService.getInstance().isFullStorage(true)) {
      HiLog.e(TAG, 'videoInnerClickFn: The Storage is full and cannot record');
      return;
    }
    if (this.videoState !== RecordingState.READY) {
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
      return;
    }
    this.startVideoAnim();
    const timerLapse: number = FeatureManager.getInstance().getFunction(FunctionId.TIME_LAPSE)?.getValue();
    HiLog.i(TAG, `StartRecording getValue: ${JSON.stringify(timerLapse)}.`);
    if (timerLapse && timerLapse > SettingFuncDialogItemIndex.INDEX_FIR) {
      this.mAction.changeTimeLapse(true);
    } else {
      HiLog.i(TAG, 'ShutterButtonLand startRecording changeTimeLapse not called.');
      PowerKeyService.getInstance().powerKeySubscribe();
      this.mAction.startRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_START);
    }
  }

  private clickFloatingShutterButton() {
    if (!this.state.uiEnable) {
      HiLog.i(TAG, 'Floating Shutter return.');
      return;
    }
    this.videoInnerClickFn();
    HiLog.i(TAG, 'onFloatingShutterButtonClick end');
  }

  private volumeKeyEventShutter(data: VolumeKeyPhotoData) {
    let isDown: boolean = data.isDown;
    if (getStates().get<boolean>('contextReducer', 'isDuringSavePowerMode') ||
      getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') !== CameraRunningState.STARTED) {
      return;
    }
    if (!this.uiEnable && this.excludeComponent !== UIOperationType.RECORD_BUTTON) {
      return;
    }
    if (isDown) {
      return;
    }
    this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
    this.videoInnerClickFn();
  }

  private getVideoInnerBtnBgc(): string | Color {
    return this.videoColor;
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

  private getABText(): string {
    HiLog.i(TAG, 'getABText videoState=' + this.videoState);

    return ResGetter.getStringSafe(this.isOpenTouchGuide ?
      (this.videoState === RecordingState.READY || this.videoState === RecordingState.STOPPING ?
      ResGetter.getStringSafe($r('app.string.video_mode')) :
      ResGetter.getStringSafe($r('app.string.accessibility_stop_recording_video'))) : '');
  }

  private getRecordAbText(): string {
    HiLog.i(TAG, 'getRecordAbText.');
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

  @Builder
  videoBtn() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(this.videoWidth)
        .height(this.videoHeight)
        .border({
          width: 2,
          color:  Color.White,
          radius: this.videoRadius,
          style: BorderStyle.Solid
        })
        .backgroundColor(SHUTTER_OUT_SHADE_COLOR)

      Stack({ alignContent: Alignment.Center }) {
        //红色方形
        Column()
          .id('circle_A')
          .width(this.circleWidth)
          .aspectRatio(1)
          .borderRadius(this.circleRadius)
          .backgroundColor(this.getVideoInnerBtnBgc())

        //红色圆点
        Column()
          .id('circle_B')
          .width(24)
          .aspectRatio(1)
          .borderRadius(12)
          .backgroundColor(Color.Red)
          .opacity(this.circleOpacity)
          .scale(this.circleScale)
      }
      .width(this.videoHeight)
      .aspectRatio(1)
      .translate(this.leftTrans)
      .enabled(this.state.uiEnable)
      .key(this.videoState === RecordingState.READY
        ? ComponentIdKeys.SHUTTER_VIDEO_1
        : ComponentIdKeys.SHUTTER_VIDEO_END_1)
      .onClick(async () => {
        this.videoInnerClickFn();
      })
      .onTouch(async (event?: TouchEvent) => {
        if (event === undefined || !getStates().get<boolean>('uiReducer', 'isShowExtendBar')) {
          return;
        } else {
          this.mAction.isShowExtendBarAndParamBar();
        }
      })
      .accessibilityGroup(true)
      .accessibilityText(this.getABText())
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilityDescription(`${ResGetter.getStringSafe($r('app.string.accessibility_button'))} ${
      ResGetter.getStringSafe($r('app.string.accessibility_clickable'))}`)

      Column() {
        if (this.videoState === RecordingState.PAUSED && this.isManualChanged) {
          // 暂停
          Image($r('app.media.ic_video_continue'))
            .width(21)
            .aspectRatio(1)
            .fillColor(Color.Red)
            .draggable(false)
        } else {
          // 开始录制 & 恢复录制
          Image($r('app.media.ic_video_pause'))
            .width(30)
            .height(30)
            .fillColor(Color.White)
            .draggable(false)
        }
      }
      .rotate({ angle: this.rotateAngle })
      .justifyContent(FlexAlign.Center)
      .width(this.videoHeight)
      .aspectRatio(1)
      .translate(this.rightTrans)
      .visibility(this.isShowPause ? Visibility.Visible : Visibility.Hidden)
      .enabled(this.state.uiEnable)
      .key(this.videoState === RecordingState.PAUSED
        ? ComponentIdKeys.VIDEO_PAUSE_1
        : ComponentIdKeys.VIDEO_RECORDING_1)
      .onClick((): void => {
        HiLog.d(TAG, 'record control onClick');
        if (this.videoState === RecordingState.PAUSED) {
          // 继续录制
          this.mAction.resumeRecording();
          this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_RESUME);
        } else {
          // 暂停录制
          this.mAction.pauseRecording();
          this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_PAUSE);
        }
      })
      .accessibilityGroup(true)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilityText(this.getRecordAbText())
      .accessibilityDescription(`${ResGetter.getStringSafe($r('app.string.accessibility_button'))} ${
      ResGetter.getStringSafe($r('app.string.accessibility_clickable'))}`)
    } .direction(Direction.Auto)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      this.videoBtn();
    }
  }
}