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

import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { RecordAction, RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { OhCombinedState, Unsubscribe, Dispatch, getStates, reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { Action, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { SettingFuncDialogItemIndex } from '@ohos/common/src/main/ets/component/settingview/SettingFuncDialogItemIndex';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { DirectionToAngleUtil } from '@ohos/common/src/main/ets/utils/DirectionToAngleUtil';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { CaptureAction } from '@ohos/common/src/main/ets/function/capture/CaptureAction';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { RecordMode } from '@ohos/common/src/main/ets/function/recordcontrol/RecordMode';
import lazy { TimeLapseAction } from './TimeLapseAction';
import lazy { ChangeState } from '@ohos/common/src/main/ets/redux/Store';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { WindowEventData } from '@ohos/common/src/main/ets/utils/types';
import window from '@ohos.window';
import lazy { camera } from '@kit.CameraKit';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import lazy {
  DirectionCorrectionService } from '@ohos/common/src/main/ets/service/direction/DirectionCorrectionService';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { MIN_LOADING_MODE_DURATION } from '@ohos/common/src/main/ets/function/capture/ShutterButton';
import lazy { AuxiliaryMode } from '@ohos/common/src/main/ets/function/enumbase/AuxiliaryMode';
import lazy { execAction } from '@ohos/common/src/main/ets/redux/ActionRegistry';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { PcInfo } from '@ohos/common/src/main/ets/component/deviceinfo/PcInfo';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';

/* instrument ignore file */
const TAG: string = 'TimeLapseView';

export const TIME_LAPSE_LENGTH: number = 133;

const TIME_LAPSE_LENGTH_TABLET: number = 70;
const MODE_ROTATE_90: number = 90;
const MODE_ROTATE_270: number = 270;
const MODE_ROTATE_0: number = 0;
const PRO_SHUTTER_THRESHOLD: number = 1000000;

class StateStruct {
  public mode: ModeType = ModeType.NONE;
  public isShowSemiCollapsed: boolean = false;
}


class TimeLapseDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
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

  public changeFunctionValue(id: number, value: number | boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public changeTimelapseVideoState(): void {
    this.mDispatch(Action.changeTimelapseVideoState());
  }

  public startVideoAnim(): void {
    this.mDispatch(TimeLapseAction.startVideoAnim());
  }

  public emitSuperMotionTimeLapse(): void {
    this.mDispatch(execAction('MotionAction', 'emitSuperMotionTimeLapse'));
  }

  public startPanoramaShutterButton(): void {
    this.mDispatch(Action.startPanoramaShutterButton());
  }

  public startStitchingShutterButton(): void {
    this.mDispatch(Action.startStitchingShutterButton());
  }

  public countDownShutterAfterTimelapse(): void {
    this.mDispatch(Action.countDownShutterAfterTimelapse());
  }

  public readyForNextAutoCapture(): void {
    this.mDispatch(CaptureAction.isReadyForNextAutoCapture());
  }
}

@Component
export struct TimeLapseView {
  private mBase: BaseComponent = new BaseComponent();
  @State state: StateStruct = new StateStruct();
  @State timerLapse: number = 0;
  @State timerLapseShow: boolean = false;
  private timer: number = 0;
  private mFeatureManager: FeatureManager = FeatureManager.getInstance();
  private mAction: TimeLapseDispatcher = new TimeLapseDispatcher();
  private isPhone: boolean = DeviceInfo.isPhone();
  private timeLapseValue: number = SettingFuncDialogItemIndex.INDEX_NONE;
  @State mSideLength: number = this.isPhone ? TIME_LAPSE_LENGTH : TIME_LAPSE_LENGTH_TABLET;
  private mSubscriber: Unsubscribe | null = null;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State proShutterValue: number = 0;
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @State isVdeCollapsed: boolean = false;
  @State rotateAngle: number = 0;
  @StorageLink('isNightShutting') isNightShutting: boolean = false;
  @State videoState: RecordingState = RecordingState.READY;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;

  public aboutToAppear() {
    HiLog.d(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.mDirection = DirectionCorrectionService.directionCorrection(state.get<WindowDirection>('contextReducer', 'direction'),
        state.get<boolean>('windowReducer', 'isLockRotation'));
      changeState(this.state, {
        mode: state.get<ModeType>('modeReducer', 'mode'),
        isShowSemiCollapsed: state.get<boolean>('collapsReducer', 'isShowSemiCollapsed')
      });
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.mEventBus.on(ContextActionType.CHANGE_WINDOW_EVENT_TYPE, this.onChangeWindowEvent.bind(this),
      this.mBase.hashCode());
    this.timeLapseValue = this.mFeatureManager.getFunction(FunctionId.TIME_LAPSE).getValue() as number;
    switch (this.timeLapseValue) {
      case SettingFuncDialogItemIndex.INDEX_NONE:
      case SettingFuncDialogItemIndex.INDEX_FIR:
        this.timerLapse = -1;
        break;
      case SettingFuncDialogItemIndex.INDEX_SEC:
        this.timerLapse = 2;
        break;
      case SettingFuncDialogItemIndex.INDEX_THR:
        this.timerLapse = 5;
        break;
      case SettingFuncDialogItemIndex.INDEX_FOUR:
        this.timerLapse = 10;
        break;
      case SettingFuncDialogItemIndex.INDEX_FIF:
        this.timerLapse = 1.5;
        break;
      default:
        this.timerLapse = 0;
        break;
    }

    this.calculateTimerLapse();
    HiLog.d(TAG, 'aboutToAppear X.');
  }

  private onChangeWindowEvent(data: WindowEventData): void {
    if (data.windowStageEventType === window.WindowStageEventType.PAUSED ||
      data.windowStageEventType === window.WindowStageEventType.INACTIVE) {
      this.onStatePaused();
    }
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mSubscriber?.destroy();
    this.clearInterval();
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToDisappear X.');
  }


  private calculateTimerLapse(): void {
    HiLog.i(TAG, `calculate timerLapse: ${this.timerLapse}.`);
    if (this.timerLapse > 0) {
      this.clearInterval();
      this.timerLapseShow = true;
      if (this.timeLapseValue !== SettingFuncDialogItemIndex.INDEX_FIF) {
        setTimeout((): void => {
          this.timerLapseShow = false;
        }, 400);
      }
      if (this.enableScreenReader && this.timerLapse > 0) {
        AccessibilityUtils.sendAnnounceAccessibilityEvent(this.timerLapse.toString());
      }
      this.timer = setInterval(async () => {
        if (this.timeLapseValue === SettingFuncDialogItemIndex.INDEX_FIF) {
          this.timerLapse -= 0.1;
        } else {
          this.timerLapse--;
        }
        this.timerLapseShow = true;
        if (this.timeLapseValue !== SettingFuncDialogItemIndex.INDEX_FIF) {
          setTimeout((): void => {
            this.timerLapseShow = false;
          }, 400);
        }
        if (this.timerLapse <= 0) {
          this.clearInterval();
          this.timerLapseShow = false;
          HiLog.i(TAG, `calculate mode: ${this.state.mode}.`);
          if (!this.state.mode || OutputOperation.isPanPhotoOutput(this.state.mode)) {
            if (!this.isProShutterCapture()) {
              this.mEventBus.emit(ActionType.ACTION_CAPTURE_EFFECT, []);
            }
            this.mAction.capture();
            this.mAction.changeFunctionValue(FunctionId.CAPTURE, true);
          } else if (OutputOperation.isPanVideoOutput(this.state.mode)) {
            this.mAction.startVideoAnim();
            this.mAction.startRecording();
            this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, 0);
            this.mAction.changeTimelapseVideoState();
          }
          this.mAction.changeTimeLapse(false);
          return;
        }
        if (this.enableScreenReader && this.timerLapse > 0) {
          AccessibilityUtils.sendAnnounceAccessibilityEvent(this.timerLapse.toString());
        }
      }, this.timeLapseValue === SettingFuncDialogItemIndex.INDEX_FIF ? 100 : 1000);
    }
  }

  private clearInterval(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  private onStatePaused(): void {
    if (this.timerLapse >= 1) {
      this.clearInterval();
      this.mAction.changeTimeLapse(false, true);
      if (this.videoState === RecordingState.RECORDING || this.videoState === RecordingState.PAUSING ||
        this.videoState === RecordingState.PAUSED || this.videoState === RecordingState.RESUMING) {
        this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
      }
    }
  }

  private isProShutterCapture(): boolean {
    if (this.proShutterValue > PRO_SHUTTER_THRESHOLD) {
      return true;
    }
    return false;
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
      alignItems: ItemAlign.Center,
      justifyContent: this.state.isShowSemiCollapsed ? FlexAlign.Center : FlexAlign.Center
    }) {
      if (this.timerLapseShow) {
        Text(this.timeLapseValue === SettingFuncDialogItemIndex.INDEX_FIF ? this.timerLapse.toFixed(1) :
        this.timerLapse.toString())
          .fontSize((this.isPhone || DeviceInfo.isTablet()) ? 100 : $r('sys.float.Display_L'))
          .maxFontScale(CommonConstants.TEXT_SIZE_NORMAL)
          .fontColor(Color.White)
          .fontWeight(300)
          .textAlign(TextAlign.Center)
          .lineHeight(this.mSideLength)
          .textShadow({ radius: 3, color: '#33000000', offsetX: 0, offsetY: 0 })
          .rotate({ angle: this.getRotateAngle() })
          .scale({
            x: AppStorage.get('isPSDCollaps') ? 0.5 : 1,
            y: AppStorage.get('isPSDCollaps') ? 0.5 : 1
          })
          .fontFeature('\"ss01\" on')
          .key('TimerLapseView')
      }
    }.width('100%').height('100%')
  }

  private getRotateAngle(): number {
    const rotation = DisplayService.getInstance().getDisplay().rotation;
    const isRotatablePc: boolean = PcInfo.isRotatablePc();
    //TODO hopper的Picker与系统相机角度相差270度，后续重构旋转修改
    if (isRotatablePc) {
      return rotation === 1 ? MODE_ROTATE_270 : rotation === 3 ? MODE_ROTATE_90 : MODE_ROTATE_0
    }
    if (this.isVdeCollapsed) {
      return this.rotateAngle;
    }
    return this.state.isShowSemiCollapsed ?
      (DeviceInfo.isPc() ? 0 : MODE_ROTATE_90) : DirectionToAngleUtil.geViewRotate(this.mDirection);
  }
}