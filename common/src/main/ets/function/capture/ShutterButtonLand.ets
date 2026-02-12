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
import lazy { OhCombinedState, Unsubscribe, Dispatch, reduxSubscribe } from '../../redux';
import lazy { FunctionAction } from '../core/FunctionAction';
import lazy { RecordMode } from '../recordcontrol/RecordMode';
import lazy { UiElement } from '../core/UiElement';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { CaptureAction } from './CaptureAction';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { ChangeState } from '../../redux/Store';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';
import lazy { TipService } from '../../component/tip/TipService';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { Configuration, window } from '@kit.ArkUI';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { camera } from '@kit.CameraKit';
import lazy { WindowEventData } from '../../utils/types';
import lazy { ContextManager } from '../../service/context/ContextManager';
import lazy { RecordController } from '../recordcontrol/RecordController';
import lazy { MemoryService } from '../../service/Memory/MemoryService';
import lazy { CameraProxy } from '../../camera/uithread/CameraProxy';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { SystemLanguageUtil } from '../../utils/SystemLanguageUtil';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { PickerAction } from '../../service/picker/PickerAction';
import lazy { CaptureService } from './CaptureService';

/* instrument ignore file */
const TAG: string = 'ShutterButtonLand';
const CAPTURE_DELAY: number = 10;
const TIP_DURING: number = 3000;

class StateStruct {
  public uiEnable: boolean = false;
  public mode: ModeType = ModeType.NONE;
  public isShowtimeLapse: boolean = false;
}

class VideoErrorData {
  public code: number = 0;
  public msg: string = '';
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
}

@Component
export struct ShutterButtonLand {
  private mBase: BaseComponent = new BaseComponent();
  type: ButtonType = ButtonType.Normal;
  stateEffect: boolean = false;
  @State state: StateStruct = new StateStruct();
  @State @Watch('modeOnChange') mode: ModeType = ModeType.NONE;
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @State isShowCapture: boolean = false;
  @State isShowVideo: boolean = false;
  @State captureBtnScale: number = 1;
  private captureElements: Map<string, UiElement> = FeatureManager.getInstance()
    .getFunction(FunctionId.CAPTURE)?.getUiElements(RenderLocation.NONE);
  private mAction: ShutterButtonDispatcher = new ShutterButtonDispatcher();
  private mCurMode: ModeType = ModeType.NONE;
  private mCaptureService: CaptureService = CaptureService.getInstance();
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
  private mSubscriber: Unsubscribe | null = null;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private cameraManager: camera.CameraManager | undefined;
  //picker
  private singleStagePhotoCaptured: boolean = false;
  @StorageLink('isRecordUnavailable') @Watch('batterySOCStopping') isRecordUnavailable: boolean = false;

  aboutToAppear(): void {
    HiLog.d(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      changeState(this.state, {
        uiEnable: state.get<boolean>('contextReducer', 'uiEnable'),
        mode: state.get<ModeType>('modeReducer', 'mode'),
        isShowtimeLapse: state.get<boolean>('settingReducer', 'isShowtimeLapse'),
      });
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });

    this.mEventBus.on(RecordActionType.ERROR, this.onVideoError.bind(this), this.mBase.hashCode());
    this.mEventBus.on([ContextActionType.DEV_ON_SHUTDOWN, ContextActionType.ABILITY_ON_BACKGROUND],
      this.onDevShutDown.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.SUPER_PRIVACY_MODE_ENABLED,
      this.superPrivacyStopRecord.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHANGE_TIME_LAPSE, this.timeLapseEnd.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.CHANGE_WINDOW_EVENT_TYPE, this.onChangeWindowEventType.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_FRAME_SHUTTER_END, this.onFrameShutterEnd.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_PICKER,
      this.onPickerReCapture.bind(this), this.mBase.hashCode());
    HiLog.d(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear(): void {
    HiLog.d(TAG, 'aboutToDisappear E.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber?.destroy();
    HiLog.d(TAG, 'aboutToDisappear X.');
  }

  private onVideoError(data: VideoErrorData) {
    HiLog.i(TAG, `onVideoError  errorCode : ${data.code} errorMsg : ${data.msg}`);
    this.mAction.stopRecording();
    this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
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

  private onFrameShutterEnd() {
    HiLog.i(TAG, 'onFrameShutterEnd')
    CameraProxy.getInstance().attemptPlayThumbnailAnimation();
  }

  private onPickerReCapture(data: ActionData): void {
    // picker一次只允许拍一张
    if (!data['showPicker']) {
      this.singleStagePhotoCaptured = false;
    }
  }

  //超级隐私开启后无法录像
  private onChangeWindowEventType(data: WindowEventData): void {
    if (!this.cameraManager) {
      this.cameraManager = camera.getCameraManager(ContextManager.getInstance().getAbilityStageContext());
    }
    if (data.windowStageEventType === window.WindowStageEventType.INACTIVE &&
      this.cameraManager.isCameraMuted()) {
      if (this.videoState !== RecordingState.READY &&
        this.videoState !== RecordingState.STOPPING &&
        this.videoState !== RecordingState.ERROR) {
        this.mAction.stopRecording();
        this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
        this.endVideoAnim();
      }
    }
  }


  private superPrivacyStopRecord(data: ActionData): void {
    if (data['isEnable']) {
      HiLog.i(TAG, 'superPrivacyStopRecord is enter super privacy mode');
      this.superPrivacyStatusChange(data['isEnable']);
    }
  }

  private superPrivacyStatusChange(isEnable: boolean): void {
    if (this.videoState !== RecordingState.READY &&
      this.videoState !== RecordingState.STOPPING &&
      this.videoState !== RecordingState.ERROR && isEnable) {
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
      this.endVideoAnim();
    }
  }

  private modeOnChange() {
    HiLog.d(TAG, `modeOnChange preMode:${this.mCurMode} mode:${this.mode}`);
    switch (this.mode) {
      case ModeType.NONE:
        break;
      case ModeType.PHOTO:
        this.isShowCapture = true;
        this.isShowVideo = false;
        break;
      case ModeType.VIDEO:
        this.isShowVideo = true;
        this.isShowCapture = false;
        break;
      default:
        break;
    }
    this.mCurMode = this.mode;
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
      if (GlobalContext.get().getIsPicker()) {
        StoreManager.getInstance().postMessage(PickerAction.showPickerView());
      }
    }
  }

  private onPhotoShutterDown(): void {
    this.captureBtnScale = 1;
    animateToImmediately(
      {
        curve: AnimSpecifications.ANIM_CAPTURE_CURVE,
        onFinish: () => {
        }
      },
      () => {
        this.captureBtnScale = 0.9;
      })
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
        this.circleWidth = 16;
        this.circleRadius = 2;
        this.circleOpacity = 0;
        this.circleScale = { x: 0, y: 0 };
        this.isShowPause = true;
        this.leftTrans = { x: SystemLanguageUtil.isRTL() ? 32 : -32 };
        this.rightTrans = { x: SystemLanguageUtil.isRTL() ? -32 : 32 };
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

  private photoInnerBtnTouchUpCapture(): void {
    HiLog.i(TAG, 'button up capture.');
    if (MemoryService.getInstance().isFullStorage() || !this.mCaptureService.isEnableCapture()) {
      return;
    }
    let timerLapse: number = FeatureManager.getInstance().getFunction(FunctionId.TIME_LAPSE)?.getValue();
    HiLog.i(TAG, `ShutterButton capture getValue: ${JSON.stringify(timerLapse)}.`);
    HiLog.i(TAG, `StartRecording getValue: ${JSON.stringify(timerLapse)}.`);
    if (timerLapse && timerLapse > SettingFuncDialogItemIndex.INDEX_FIR) {
      HiLog.i(TAG, 'ShutterButton capture changeTimeLapse called.');
      this.mAction.changeTimeLapse(true);
    } else {
      HiLog.i(TAG, 'ShutterButton capture called.');
      this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
      this.mAction.capture();
      this.singleStagePhotoCaptured = PickerUtils.getIsPicker() ? true : this.singleStagePhotoCaptured;
      this.mAction.changeFunctionValue(FunctionId.CAPTURE, true);
    }
    HiLog.i(TAG, 'button up capture end.');
  }

  private videoInnerClickFn(): void {
    if (MemoryService.getInstance().isFullStorage(true)) {
      return;
    }
    if (AppStorage.get('isRecordUnavailable')) {
      if (AppStorage.get('isBatterySOCStopping')) {
        AppStorage.setOrCreate<boolean>('isBatterySOCStopping', false);
      } else {
        TipService.getInstance().showTip($r('app.string.battery_desc_unable'), TIP_DURING, true, null, undefined, true);
        HiLog.i(TAG, 'batterySOC is less than 2%');
        return;
      }
    }
    if (this.videoState !== RecordingState.READY) {
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
      return;
    }
    this.startVideoAnim();
    let timerLapse: number = FeatureManager.getInstance().getFunction(FunctionId.TIME_LAPSE)?.getValue();
    HiLog.i(TAG, `StartRecording getValue: ${JSON.stringify(timerLapse)}.`);
    if (timerLapse && timerLapse > SettingFuncDialogItemIndex.INDEX_FIR) {
      this.mAction.changeTimeLapse(true);
    } else {
      HiLog.i(TAG, 'ShutterButtonLand startRecording changeTimeLapse not called.');
      this.mAction.startRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_START);
    }
  }

  private batterySOCStopping(): void {
    HiLog.i(TAG, `isRecordUnavailable: ${this.isRecordUnavailable} this.videoState: ${this.videoState}  this.mCurMode ${this.mCurMode}`);
    if (this.isRecordUnavailable && this.videoState !== RecordingState.READY &&
      this.videoState !== RecordingState.STOPPING && this.mCurMode !== ModeType.PHOTO) {
      AppStorage.setOrCreate<boolean>('isBatterySOCStopping', true);
      TipService.getInstance().showTip($r('app.string.battery_desc_stop'), TIP_DURING, true, null, undefined, true);
      this.videoInnerClickFn();
    }
  }

  @Builder
  photoBtn() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(64)
        .aspectRatio(1)
        .border({ width: 1.5, color: Color.White, radius: 64 / 2, style: BorderStyle.Solid })
        .shadow({ radius: 1, color: Color.Black })


      Stack({ alignContent: Alignment.Center }) {
        Image(this.captureElements.get(UiElement.DEFAULT)?.icon)
          .width(48)
          .aspectRatio(1)
          .draggable(false)
          .fillColor(Color.White)
          .key(ComponentIdKeys.SHUTTER_PHOTO_1)
          .scale({ x: this.captureBtnScale, y: this.captureBtnScale, z: this.captureBtnScale })
          .enabled(this.state.uiEnable)
          .defaultFocus(true)
          .focusable(true)
          .onFocus(() => {
            this.isFocusAcquisition = true;
          })
          .onClick(() => {
            //pc使用键盘tab走焦后使用键盘拍照
            if (this.isFocusAcquisition) {
              if (MemoryService.getInstance().isFullStorage()) {
                return;
              }
              // 打断场景的恢复
              if (this.singleStagePhotoCaptured && PickerUtils.getIsPicker()) {
                return;
              }
              this.photoInnerBtnTouchUpCapture();
              setTimeout((): void => {
                this.onPhotoShutterUp();
              }, CAPTURE_DELAY)
            }
          })
          .onTouch((event?: TouchEvent) => {
            this.isFocusAcquisition = false;
            if (event === undefined) {
              return;
            }
            if (this.isFocusAcquisition) {
              return;
            }
            if (MemoryService.getInstance().isFullStorage()) {
              return;
            }
            // 打断场景的恢复
            if (this.singleStagePhotoCaptured && PickerUtils.getIsPicker()) {
              return;
            }
            if (event.type === TouchType.Down) {
              this.onPhotoShutterDown();
            } else if (event.type === TouchType.Up) {
              this.photoInnerBtnTouchUpCapture();
              setTimeout((): void => {
                this.onPhotoShutterUp();
              }, CAPTURE_DELAY)
            } else if (event.type === TouchType.Cancel) {
              this.onPhotoShutterUp();
            }
          })
      }
    }
  }

  @Builder
  videoBtn() {

    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(this.videoWidth)
        .height(this.videoHeight)
        .border({ width: 1.5, color: Color.White, radius: this.videoRadius, style: BorderStyle.Solid })
        .shadow({ radius: 1, color: Color.Black })

      Stack({ alignContent: Alignment.Center }) {
        Column()
          .id('circle_A')
          .width(this.circleWidth)
          .aspectRatio(1)
          .borderRadius(this.circleRadius)
          .backgroundColor(this.videoColor)
          .shadow({ radius: 1, color: Color.Black })

        Column()
          .id('circle_B')
          .width(18)
          .aspectRatio(1)
          .borderRadius(9)
          .backgroundColor(Color.Red)
          .opacity(this.circleOpacity)
          .scale(this.circleScale)
      }
      .defaultFocus(true)
      .width(this.videoHeight)
      .aspectRatio(1)
      .translate(this.leftTrans)
      .enabled(this.state.uiEnable)
      .key(this.videoState === RecordingState.READY
        ? ComponentIdKeys.SHUTTER_VIDEO_1
        : ComponentIdKeys.SHUTTER_VIDEO_END_1)
      .onClick(async () => {
        if (MemoryService.getInstance().isFullStorage(true)) {
          return;
        }
        this.videoInnerClickFn();
      })

      Column() {
        if (this.videoState === RecordingState.PAUSED) {
          // 暂停
          Image($r('app.media.ic_video_continue'))
            .width(18)
            .aspectRatio(1)
            .fillColor(Color.Red)
            .draggable(false)
        } else {
          // 开始录制 & 恢复录制
          Image($r('app.media.ic_video_pause'))
            .width(20)
            .height(21)
            .fillColor(Color.White)
            .draggable(false)
        }
      }
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
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.isShowCapture) {
        this.photoBtn();
      }
      if (this.isShowVideo) {
        this.videoBtn();
      }
    }.width(76).aspectRatio(1).margin({ left: $r('sys.float.padding_level24'), right: $r('sys.float.padding_level24') })
  }
}