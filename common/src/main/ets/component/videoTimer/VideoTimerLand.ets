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

import systemDateTime from '@ohos.systemDateTime';
import lazy { RecordAction, RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { Action, UiStateMode } from '../../redux/actions/Action';
import lazy { OhCombinedState, Unsubscribe, Dispatch, reduxSubscribe } from '../../redux';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { RecordMode } from '../../function/recordcontrol/RecordMode';
import lazy { FunctionAction } from '../../function/core/FunctionAction';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { ActionType } from '../../redux/actions/ActionType';

const TAG: string = 'VideoTimerLand';
const TIME_SYSTEM: number = 60;
const INIT_VIDEO_TIMER_HEIGHT: number = 62;

class VideoTimerDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public updateRecordUselessTime(uselessSeconds: number): void {
    this.mDispatch(Action.updateRecordUselessTime(uselessSeconds));
  }

  public stopRecording(): void {
    this.mDispatch(Action.uiStateWithMode(false, UiStateMode.EXCLUDE_PREVIEW));
    this.mDispatch(RecordAction.stop());
  }

  public changeFunctionValue(id: FunctionId, value: number | string | boolean): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }
}

@Component
export struct VideoTimerLand {
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mGlobalContext: GlobalContext = GlobalContext.get();
  @State mFontSize: string = '48fp';
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @State mIsRecording: boolean = false;
  @State mIsPausing: boolean = false;
  @State mRecordScale: ScaleOptions = { x: 1, y: 1 };
  @State mPauseScale: ScaleOptions = { x: 0, y: 0 };
  @State mRecordOpacity: number = 1;
  @State mPauseOpacity: number = 0;
  @State recordingTime: number = 0;
  @State recordingTimeDisplay: string = '00:00';
  private isBigTimer: boolean = true;
  private mAction: VideoTimerDispatcher = new VideoTimerDispatcher();
  private mTimer: number = 0;
  private mFontScalingTimer: number = Number.MIN_VALUE; // 组件缩放计时器
  private subscriber: Unsubscribe | null = null;
  @State startTimeSeconds: number = 0;
  @State uselessSeconds: number = 0;
  @State startTime: number = 0;
  @State stopTime: number = 0;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.startTimeSeconds = state.get<number>('recordReducer', 'startTimeSeconds');
      this.uselessSeconds = state.get<number>('recordReducer', 'uselessSeconds');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.setIntervalTimer();
    this.mEventBus.on(RecordActionType.PAUSE, this.onPause.bind(this), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.RESUME, this.onResume.bind(this), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.STOP, this.onStop.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_RECORD_START_SECONDS, this.startToRecord.bind(this), this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.intervalClearing();
    this.fontScalingTimerClear();
    this.subscriber?.destroy();
    HiLog.i(TAG, `clearInterval timer id: ${this.mTimer}.`);
    clearInterval(this.mTimer);
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToDisappear X.');
  }

  private videoStateOnChange() {
    HiLog.d(TAG, `videoStateOnChange videoState:${this.videoState}.`);
    if (this.videoState === RecordingState.PAUSING) {
      this.recordToPauseAnim();
    } else if (this.videoState === RecordingState.RESUMING) {
      this.pauseToRecordAnim();
    }
  }

  private recordToPauseAnim() {
    this.mIsPausing = true;
    animateToImmediately({
      delay: 0,
      duration: 300,
      curve: Curve.Friction,
      onFinish: () => {
        this.mIsRecording = false;
      }
    }, () => {
      this.mRecordScale = { x: 0, y: 0 }
      this.mPauseScale = { x: 1, y: 1 }
    });

    animateToImmediately({
      delay: 50,
      duration: 150,
      curve: Curve.Sharp
    }, () => {
      this.mRecordOpacity = 0;
      this.mPauseOpacity = 1;
    });
  }

  private pauseToRecordAnim() {
    this.mIsRecording = true;
    animateToImmediately({
      delay: 0,
      duration: 300,
      curve: Curve.Friction,
      onFinish: () => {
        this.mIsPausing = false;
      }
    }, () => {
      this.mPauseScale = { x: 0, y: 0 }
      this.mRecordScale = { x: 1, y: 1 }
    });

    animateToImmediately({
      delay: 50,
      duration: 150,
      curve: Curve.Sharp
    }, () => {
      this.mPauseOpacity = 0;
      this.mRecordOpacity = 1;
    });
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Row() {
        Text('').layoutWeight(1)
        Stack({ alignContent: Alignment.Center }) {
          if (this.mIsRecording) {
            Image($r('app.media.ic_video_continue'))
              .width(12)
              .height(12)
              .fillColor(Color.Red)
              .scale(this.mRecordScale)
              .opacity(this.mRecordOpacity)
              .draggable(false)
          }
          if (this.mIsPausing) {
            Image($r('app.media.ic_video_pause'))
              .width(14)
              .height(14)
              .fillColor(Color.White)
              .scale(this.mPauseScale)
              .opacity(this.mPauseOpacity)
              .draggable(false)
          }
        }
        .width(12)
        .height(12)

        Text(`${this.recordingTimeDisplay}`)
          .margin({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
          .textAlign(TextAlign.Center)
          .fontSize(this.mFontSize)
          .fontColor(Color.White)
          .fontWeight(300)
          .textShadow({ radius: 3, color: '#33000000', offsetX: 0, offsetY: 0 })
          .fontFeature('\"ss01\" on')
        Text('').width(12).height(12)
        Text('').layoutWeight(1)
      }
    }
    .width('100%')
    .height(80)
    .hitTestBehavior(HitTestMode.None)
    .offset({ x: 0, y: 4 })
  }

  private bigToSmallAnim() {
    animateToImmediately({
      duration: 300,
      curve: Curve.Friction
    }, () => {
      this.mFontSize = '28fp';
    });
  }

  private async onTimerResumed() {
    HiLog.i(TAG, 'onTimerResumed E.');
    this.mAction.updateRecordUselessTime(this.uselessSeconds + (this.startTime + 200 - this.stopTime));

    this.recordingTime = await this.getCurRecordingTime();
    this.setIntervalTimer();
    HiLog.i(TAG, 'onTimerResumed X.');
  }

  private setIntervalTimer() {
    HiLog.i(TAG, 'setIntervalTimer.');
    this.intervalClearing();
    this.mTimer = setInterval(async () => {
      if (this.videoState === RecordingState.RECORDING) {
        this.recordingTime = await this.getCurRecordingTime();
        let currentTime = `${this.formatMin()}:${this.formatSec()}`;
        if (this.recordingTime >= TIME_SYSTEM * TIME_SYSTEM) {
          currentTime = this.formatHour() + ':' + currentTime;
        }
        if (this.recordingTimeDisplay === currentTime) {
          return;
        }
        this.recordingTimeDisplay = currentTime;
        if (this.mGlobalContext.getIsPicker() && this.mGlobalContext.getCameraAbilityWant().parameters?.videoDuration) {
          try {
            let videoDuration: number = Number.parseInt(this.mGlobalContext.getCameraAbilityWant()
              .parameters?.videoDuration as string)
            HiLog.i(TAG, `videoDuration is ${videoDuration}`);
            if (this.recordingTime >= videoDuration) {
              this.mAction.stopRecording();
              this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
            }
          } catch (error) {
            HiLog.e(TAG, `picker videoDuration --> ${error?.code}}`);
          }
        }

      }
    }, 50);
  }

  private async getCurRecordingTime(): Promise<number> {
    const curTime: number = await systemDateTime.getRealTime(false);
    let recordingTime: number = curTime - this.startTimeSeconds - this.uselessSeconds;
    HiLog.d(TAG, `getCurRecordingTime curTime is ${curTime}, startTimeSeconds is ${this.startTimeSeconds
      }, uselessSeconds is ${this.uselessSeconds}, recordingTime is ${recordingTime}.`);
    recordingTime = Math.floor(recordingTime / 1000);
    HiLog.d(TAG, `getCurRecordingTime recordingTime/1000 is ${recordingTime}.`);
    return recordingTime > 0 ? recordingTime : 0;
  }

  private formatSec(): string {
    let shownSec = '00';
    let sec = this.recordingTime % TIME_SYSTEM;
    if (sec < 10) {
      shownSec = `0${sec}`;
    } else {
      shownSec = `${sec}`;
    }
    return shownSec;
  }

  private formatMin(): string {
    let shownMin = '00';
    let minute = Math.floor(this.recordingTime % (TIME_SYSTEM * TIME_SYSTEM) / TIME_SYSTEM);
    if (minute < 10) {
      shownMin = `0${minute}`;
    } else {
      shownMin = `${minute}`;
    }
    return shownMin;
  }

  private formatHour(): string {
    let shownHour = '00';
    let minute = Math.floor(this.recordingTime / (TIME_SYSTEM * TIME_SYSTEM));
    if (minute < 10) {
      shownHour = `0${minute}`;
    } else {
      shownHour = `${minute}`;
    }
    return shownHour;
  }

  private intervalClearing(): void {
    if (this.mTimer !== Number.MIN_VALUE) {
      clearInterval(this.mTimer);
      this.mTimer = Number.MIN_VALUE;
    }
  }

  private fontScalingTimerClear(): void {
    if (this.mFontScalingTimer != Number.MIN_VALUE) {
      clearTimeout(this.mFontScalingTimer);
      this.mFontScalingTimer = Number.MIN_VALUE;
    }
  }

  private async calcTime(type: number) {
    HiLog.i(TAG, `calcTime type: ${type}.`);
    const currentTime: number = await systemDateTime.getRealTime(false);
    if (type === 2) {
      this.stopTime = currentTime;
      this.intervalClearing();
    } else if (type === 5) {
      this.startTime = currentTime;
      this.onTimerResumed();
    }
  }

  private onPause(): void {
    this.calcTime(2);
  }

  private onResume(): void {
    this.calcTime(5);
  }

  private onStop(): void {
    this.calcTime(0);
  }

  private startToRecord(): void {
    const startToRecordTimer = setTimeout((): void => {
      this.mIsRecording = true;
      HiLog.e(TAG, 'startToRecord: start recording now');
      clearTimeout(startToRecordTimer);
    }, 100);

    this.fontScalingTimerClear();
    this.mFontScalingTimer = setTimeout((): void => {
      this.isBigTimer = false;
      this.bigToSmallAnim();
      this.fontScalingTimerClear();
    }, 3000);
  }
}