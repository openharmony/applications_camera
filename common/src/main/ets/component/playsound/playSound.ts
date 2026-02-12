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

import media from '@ohos.multimedia.media';
import audio from '@ohos.multimedia.audio';
import lazy { RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { Voice } from './Voice';
import type { EventBus } from '../../worker/eventbus/EventBus';
import type resourceManager from '@ohos.resourceManager';
import lazy { getStates, reduxSubscribe, Unsubscribe } from '../../redux';
import type { OhCombinedState } from '../../redux';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { FlashMode } from '../../function/enumbase/FlashMode';
import camera from '@ohos.multimedia.camera';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { OutputType } from '../../function/outputswitcher/OutputType';
import lazy { Callback, ErrorCallback } from '@ohos.base';
import lazy { LeftRightSwipeActionType } from '../../redux/actions/LeftRightSwipeActionType';
import lazy { ContextManager } from '../../service/context/ContextManager';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { OutputSwitcher } from '../../function/outputswitcher/OutputSwitcher';
import lazy { VibratorService } from '../vibration/VibratorService';
import lazy { AuxiliaryMode } from '../../function/enumbase/AuxiliaryMode';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { PickerShowMsg } from '../../service/picker/PickerUiService';
import lazy { CaptureActionType } from '../../redux/actions/CaptureActionType';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { ZoomActionType } from '../../redux/actions/ZoomActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { ActionData } from '../../redux/actions/Action';
import { CameraStartType, CameraStartTypeStruct } from '../../camera/uithread/CameraAction';

const TAG: string = 'PlaySound';
const LIGHT_PAINTING_DENSE_PLAY_BEGIN_TIME = 2;
const LIGHT_PAINTING_DENSE_PLAY_PER_SECOND = 3;
const ONE_SECOND = 1000;
const PRO_SHUTTER_THRESHOLD: number = 1000000;

export class PlaySound {
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private soundIdList = new Map<String, number>();
  // @ts-ignore
  private mSoundPool?: media.SoundPool;
  private readonly NUM_SOUND_STREAMS: number = 1;
  private mSoundPoolDescriptor: resourceManager.RawFileDescriptor = undefined;
  private mVideoState: RecordingState = RecordingState.READY;
  private lightPaintingFlashCountdown: number = 0;
  private lightPaintingFlashTimerDuration: number = 1000;
  private lightPaintingTimer: number = Number.MIN_VALUE;
  private audioRendererInfo = {
    usage: DeviceInfo.isPc() ? audio.StreamUsage.STREAM_USAGE_NOTIFICATION :
    audio.StreamUsage.STREAM_USAGE_ENFORCED_TONE,
    rendererFlags: 1
  };
  private mTimerId: number = Number.MIN_VALUE;
  private isBlocked: boolean = false;
  private readonly DELAY_TIME: number = 180;
  private static sInstancePlaySound: PlaySound;
  private prevPlayCaptureSoundTime: number = 0; // 记录上一次拍照的时间
  private readonly MAX_TIME_DELAY_TIMES: number = 3;
  private readonly BURST_LOOP_PLAY_PARAM: media.PlayParameters = {
    loop: -1,
    rate: audio.AudioRendererRate.RENDER_RATE_NORMAL,
    leftVolume: 1.0,
    rightVolume: 1.0,
    priority: 0,
  };
  private readonly PC_PLAY_PARAM: media.PlayParameters = {
    parallelPlayFlag: DeviceInfo.isPc() ? true : false,
  };
  private burstIntervalTimer: number = Number.MIN_VALUE;
  private isPanoramaStart: boolean = false;
  private mSubscriber: Unsubscribe | null = null;
  private audioVolumeManager: audio.AudioVolumeManager = undefined;
  private isStitchingCapture: boolean = false;
  private isLongExposure: boolean = false;
  private isPickerViewShow: boolean = false;
  private volumeSize: number = 1;
  private isCloseCamera: boolean = false;
  private audioVolumeGroupManager: audio.AudioVolumeGroupManager = undefined;
  private curRingerMode: audio.AudioRingMode = audio.AudioRingMode.RINGER_MODE_NORMAL;

  private constructor() {
    this.mSubscriber?.destroy();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mVideoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.lightPaintingFlashCountdown = state.get<number>('lightPaintingReducer', 'lightPaintingFlashCountdown');
      this.isLongExposure = state.get<boolean>('longExposureReducer', 'longExposureEnable');
    }, null);
    this.audioVolumeManager = audio.getAudioManager().getVolumeManager();
    if (DeviceInfo.isPc()) {
      this.registerAudioEvent();
      this.registerAudioVolumeGroup();
    }
  }

  public init(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.START, this.playRecordStart.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.initAudioVolumeGroupManager.bind(this), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.PAUSE, this.playRecordPause.bind(this), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.RESUME, this.playRecordPause.bind(this), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.STOP, this.playRecordStop.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CAPTURE_EFFECT, this.soundDelay.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_NORMAL_FRAME_SHUTTER, this.onFlashUnsteady.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.ACTION_PLAY_COUNT_DOWN_TIMER_EFFECT, this.playCountDownTimerEffect.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CONFIRM_CAPTURE_EFFECT, this.handlePlayCapture.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([ZoomActionType.ACTION_ZOOM_SLIDE_QUICK_ZOOM, ActionType.CHANGE_MODE_PLAY_SOUND],
      this.playZoomSlide.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.PHOTO_ON_SAVE, this.onPhotoThumbnailBack.bind(this), this.mBase.hashCode());
    this.mEventBus.on(LeftRightSwipeActionType.BURST_FIRST, this.playBurstCapture.bind(this), this.mBase.hashCode());
    this.mEventBus.on(LeftRightSwipeActionType.BURST_SOUND_END, this.playBurstCaptureEnd.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LIGHT_PAINTING_FLASH_TIMER_SHOW,
      (data) => this.playLightPaintingFlashTimer(data.isLightPaintingFlashTimerShow), this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.CONFIRM_CAPTURE, () => this.clearTimer(), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForgeGround.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_IS_START_PANORAMA, this.onStartPanorama.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_START_STITCHING_CAPTURE, this.onStartStitchingCapture.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_END_STITCHING_CAPTURE, this.onEndStitchingCapture.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_IS_END_PANORAMA, this.onEndPanorama.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_PHOTO_STOP_PANORAMA, this.onPanoramaPhotoStop.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_PICKER, this.handleShowPickerView.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.PREEMPTION_WITH_ERROR, this.getCameraIsCloseState.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.UPDATE_SAVE_POWER_MODE_STATE, this.exitPowerLodeSound.bind(this),
      this.mBase.hashCode());
    if (DeviceInfo.isTv()) {
      this.mEventBus.on(ActionType.ACTION_TV_COUNTDOWN, this.onTvCountdown.bind(this), this.mBase.hashCode());
    }
  }

  public static getInstance(): PlaySound {
    if (!PlaySound.sInstancePlaySound) {
      PlaySound.sInstancePlaySound = new PlaySound();
    }
    return PlaySound.sInstancePlaySound;
  }

  public onBackground(): void {
    this.unRegisterAudioEvent();
    this.unRegisterAudioVolumeGroup();
    if (this.lightPaintingTimer !== Number.MIN_VALUE) {
      clearInterval(this.lightPaintingTimer);
      this.lightPaintingTimer = Number.MIN_VALUE;
    }
    this.lightPaintingFlashCountdown = 0;
    this.lightPaintingFlashTimerDuration = 1000;
  }

  public onForgeGround(): void {
    this.registerAudioEvent();
    this.registerAudioVolumeGroup();
  }

  public createSoundPool(): void {
    HiLog.i(TAG, 'Begin createSoundPool');
    try {
      HiLog.begin(TAG, 'create Sound Pool');
      AppStorage.setOrCreate('isSoundPoolLoaded', true);
      // @ts-ignore
      media?.createSoundPool(this.NUM_SOUND_STREAMS, this.audioRendererInfo, (error, soundPool) => {
        if (error) {
          HiLog.e(TAG, `createSoundPool error: ${error.message}.`);
        } else {
          HiLog.i(TAG, 'createSoundPool Success.');
          this.mSoundPool = soundPool;
          this.setSourceInfo();
          this.setErrorCallback();
          this.loadAllSoundResource();
        }
      });
      HiLog.end(TAG, 'create Sound Pool');
    } catch (e) {
      HiLog.e(TAG, `createSoundPool error: ${e.message}.`);
    }
  }

  public releaseSoundPool(): void {
    HiLog.i(TAG, 'begin release SoundPool.');
    this.mEventBus.clear(this.mBase.hashCode());
    if (this.mSoundPool) {
      HiLog.begin(TAG, 'release Sound Pool');
      this.mSoundPool.release(() => {
        HiLog.i(TAG, 'soundPool released.');
        AppStorage.setOrCreate('isSoundPoolLoaded', false);
      });
      HiLog.end(TAG, 'release Sound Pool');
    }
    PlaySound.sInstancePlaySound = null;
    HiLog.i(TAG, 'end release SoundPool.');
  }

  public loadSound(): void {
    HiLog.i(TAG, `loadSound isSoundPoolLoaded: ${AppStorage.get('isSoundPoolLoaded')}`);
    if (!AppStorage.get('isSoundPoolLoaded') || !this.mSoundPool) {
      this.createSoundPool();
    } else if (this.soundIdList.size === 0) {
      this.loadAllSoundResource();
    }
    HiLog.begin(TAG, 'load sound pool');
    for (let uri of this.soundIdList.keys()) {
      this.loadSoundByUri(uri);
    }
    HiLog.end(TAG, 'load sound pool');
  }

  public unloadSound(): void {
    HiLog.begin(TAG, 'unload sound pool');
    for (let uri of this.soundIdList.keys()) {
      this.unloadSoundById(this.soundIdList.get(uri));
    }
    HiLog.end(TAG, 'unload sound pool');
  }

  private loadAllSoundResource(): void {
    this.loadSoundByUri(Voice.RECORD_START_URI);
    this.loadSoundByUri(Voice.RECORD_PAUSE_URI);
    this.loadSoundByUri(Voice.RECORD_STOP_URI);
    this.loadSoundByUri(Voice.CAPTURE_URI);
    this.loadSoundByUri(Voice.ZOOM_SLIDE_URI);
    this.loadSoundByUri(Voice.GEAR_SLIDE_URI);
    this.loadSoundByUri(Voice.CAMERA_COUNT_DOWN_URI);
    if (DeviceInfo.isTv()) {
      this.loadSoundByUri(Voice.CAMERA_COUNTDOWN_URI);
    }
  }

  private loadSoundByUri(uri): void {
    ContextManager.getInstance().getResourceManager().getRawFd(uri).then((value) => {
      this.mSoundPoolDescriptor = value;
      this.mSoundPool?.load(this.mSoundPoolDescriptor.fd, this.mSoundPoolDescriptor.offset,
        this.mSoundPoolDescriptor.length, (error, soundId) => {
          if (error) {
            HiLog.e(TAG, `load soundPool error: ${error.message}.`);
          } else {
            HiLog.d(TAG, `load soundPool Success, soundId is ${soundId}.`);
            this.soundIdList.set(uri, soundId);
          }
        });
    });
  }

  private unloadSoundById(soundId: number): void {
    this.mSoundPool?.unload(soundId, (error) => {
      if (error) {
        HiLog.e(TAG, `unload soundPool error: ${error.message}.`);
      } else {
        HiLog.d(TAG, `unload soundPool Success, soundId is ${soundId}.`);
      }
    });
  }

  /**
   * @param soundId 播放的音频id， 加载音频资源后返回
   * @param playParameters 播放参数
   * @param isForcedPlay 是否强制播放 true：强制播放 false：正常播放 目前强制播放只有无障碍播放倒计时音效场景
   * @returns
   */
  private async playSoundVideo(soundId, playParameters: media.PlayParameters = {},
    isForcedPlay: boolean = false): Promise<void> {
    if (FeatureManager.getInstance().getFunction(FunctionId.SOUND_MUTE).getValue() && !isForcedPlay) {
      HiLog.i(TAG, 'playSoundVideo sound mute.');
      return;
    }

    if (DeviceInfo.isTv()) {
      this.mSoundPool?.play(soundId, (error, streamId) => {
        if (error) {
          HiLog.e(TAG, `play soundPoolerror: ${error.message}.`);
        } else {
          HiLog.i(TAG, `play soundPool Success, streamId is ${streamId}.`);
        }
      });
      return;
    }

    // 2-the ring mode
    if ((this.curRingerMode !== audio.AudioRingMode.RINGER_MODE_NORMAL && !isForcedPlay) ||
      (DeviceInfo.isPc() && this.volumeSize === 0)) {
      HiLog.w(TAG, 'play return.');
      return;
    }
    // @ts-ignore
    this.mSoundPool?.play(soundId, playParameters, (error, streamId) => {
      if (error) {
        HiLog.e(TAG, `play soundPoolerror: ${error.message}.`);
      } else {
        HiLog.i(TAG, `play soundPool Success, streamId is ${streamId}.`);
      }
    });
  }

  private onStartPanorama(): void {
    this.isPanoramaStart = true;
    HiLog.i(TAG, 'panoramaStart invoke E.');
    this.playSoundVideo(this.soundIdList.get(Voice.RECORD_START_URI));
    HiLog.i(TAG, 'panoramaStart invoke X.');
  }

  private onStartStitchingCapture(): void {
    this.isStitchingCapture = true;
    this.playSoundVideo(this.soundIdList.get(Voice.RECORD_START_URI));
  }

  private onEndStitchingCapture(): void {
    if (!this.isStitchingCapture) {
      return;
    }
    this.isStitchingCapture = false;
    this.playSoundVideo(this.soundIdList.get(Voice.RECORD_STOP_URI));
  }

  private onEndPanorama(): void {
    if (!this.isPanoramaStart) {
      return;
    }
    this.isPanoramaStart = false;
    HiLog.i(TAG, 'panoramaStop invoke E.');
    this.playSoundVideo(this.soundIdList.get(Voice.RECORD_STOP_URI));
    HiLog.i(TAG, 'panoramaStop invoke X.');
  }

  public onPanoramaPhotoStop(): void {
    if (!this.isPanoramaStart) {
      return;
    }
    this.isPanoramaStart = false;
    HiLog.i(TAG, 'onPanoramaPhotoStop invoke E.');
    this.playSoundVideo(this.soundIdList.get(Voice.RECORD_STOP_URI));
    HiLog.i(TAG, 'onPanoramaPhotoStop invoke X.');
  }

  private playRecordStart(data: { isSoundEffect: boolean }): void {
    HiLog.i(TAG, `playRecordStart invoke, isSoundEffect: ${data.isSoundEffect}.`);
    if (!data.isSoundEffect) {
      return;
    }
    this.playSoundVideo(this.soundIdList.get(Voice.RECORD_START_URI));
    HiLog.i(TAG, 'playRecordStart end.');
  }

  private playRecordPause(data: Record<string, boolean>): void {
    HiLog.i(TAG, 'playRecordPause invoke E.');
    if (data?.isManualChanged) {
      this.playSoundVideo(this.soundIdList.get(Voice.RECORD_PAUSE_URI));
    }
    HiLog.i(TAG, 'playRecordPause invoke X.');
  }

  private playRecordStop(): void {
    HiLog.i(TAG, 'playRecordStop invoke E.');
    this.playSoundVideo(this.soundIdList.get(Voice.RECORD_STOP_URI));
    HiLog.i(TAG, 'playRecordStop invoke X.');
  }

  private playCapture(): void {
    HiLog.i(TAG, 'playCapture invoke E.');
    this.prevPlayCaptureSoundTime = Date.now();
    HiLog.i(TAG, 'getPlayTime: ' + this.prevPlayCaptureSoundTime);
    this.playSoundVideo(this.soundIdList.get(Voice.CAPTURE_URI), this.PC_PLAY_PARAM);
    HiLog.i(TAG, 'playCapture invoke X.');
  }

  /* instrument ignore next */
  private playBurstCapture(): void {
    HiLog.i(TAG, 'playBurstCapture invoke E.');
    this.burstIntervalTimer = setInterval(() => {
      VibratorService.getInstance().playBurstVibrate(VibratorService.BURST_CAPTURE_CONTINUOUS);
    }, VibratorService.CAMERA_BURST_DOWN_OGG_TIME);
    HiLog.i(TAG, 'playBurstCapture invoke X.');
  }

  /* instrument ignore next */
  private playBurstCaptureEnd(): void {
    HiLog.i(TAG, 'playBurstCapture End invoke E.');
    clearInterval(this.burstIntervalTimer);
    VibratorService.getInstance().playBurstVibrate(VibratorService.SHUTTER_CLICK_UP);
    HiLog.i(TAG, 'playBurstCapture End invoke X.');
  }

  private playZoomSlide(): void {
    HiLog.i(TAG, 'playZoomSlide invoke E.');
    if (this.mVideoState === RecordingState.READY || this.mVideoState === RecordingState.PAUSED) {
      this.playSoundVideo(this.soundIdList.get(Voice.ZOOM_SLIDE_URI));
    }
    HiLog.i(TAG, 'playZoomSlide invoke X.');
  }

  private playLightPaintingFlashTimer(isLightPaintingFlashTimerShow: boolean): void {
    if (!isLightPaintingFlashTimerShow || this.lightPaintingFlashCountdown <= 0) {
      if (this.lightPaintingTimer !== Number.MIN_VALUE) {
        clearInterval(this.lightPaintingTimer);
        this.lightPaintingTimer = Number.MIN_VALUE;
      }
      this.lightPaintingFlashCountdown = 0;
      this.lightPaintingFlashTimerDuration = 1000;
      return;
    }
    let curTimer = this.lightPaintingFlashCountdown;
    this.lightPaintingTimer = setInterval(async () => {
      curTimer--;
      if (curTimer <= LIGHT_PAINTING_DENSE_PLAY_BEGIN_TIME) {
        this.resetTimer();
        return;
      }
    }, this.lightPaintingFlashTimerDuration);
  }

  private resetTimer(): void {
    if (this.lightPaintingTimer === Number.MIN_VALUE) {
      return;
    }
    clearInterval(this.lightPaintingTimer);
    let curTimer = LIGHT_PAINTING_DENSE_PLAY_BEGIN_TIME * LIGHT_PAINTING_DENSE_PLAY_PER_SECOND;
    this.lightPaintingFlashTimerDuration = ONE_SECOND / LIGHT_PAINTING_DENSE_PLAY_PER_SECOND;
    this.lightPaintingTimer = setInterval(async () => {
      curTimer--;
      if (curTimer <= 0) {
        this.clearTimer();
        return;
      }
    }, this.lightPaintingFlashTimerDuration);
  }

  private clearTimer(): void {
    if (this.lightPaintingTimer !== Number.MIN_VALUE) {
      clearInterval(this.lightPaintingTimer);
      this.lightPaintingTimer = Number.MIN_VALUE;
    }
    this.lightPaintingFlashTimerDuration = ONE_SECOND;
  }

  private handlePlayCapture(): void {
    HiLog.begin(TAG, 'handlePlayCapture');
    const currMode = getStates().get<ModeType>('modeReducer', 'mode');
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
    if (GlobalContext.get().getIsPicker() && this.isPickerViewShow) {
      HiLog.i(TAG, 'currently on picker view page.');
      HiLog.end(TAG, 'handlePlayCapture');
      return;
    }
    if (currMode === ModeType.VIDEO && outputType === OutputType.VIDEO_OUTPUT) {
      HiLog.i(TAG, 'do not to playsound');
      HiLog.end(TAG, 'handlePlayCapture');
      return;
    }

    let nowTime: number = Date.now();

    // 兜底，预防isBlocked状态异常
    if (nowTime - this.prevPlayCaptureSoundTime > this.DELAY_TIME * this.MAX_TIME_DELAY_TIMES && this.isBlocked) {
      HiLog.i(TAG, 'handlePlayCapture isBlocked state abnormal');
      this.isBlocked = false;
      clearTimeout(this.mTimerId);
      this.playCapture();
      HiLog.end(TAG, 'handlePlayCapture');
      return;
    }

    const playInterval = nowTime - this.prevPlayCaptureSoundTime;
    if (playInterval > this.DELAY_TIME && !this.isBlocked) {
      this.playCapture();
      HiLog.end(TAG, 'handlePlayCapture');
      return;
    }

    if (!this.isBlocked) {
      this.isBlocked = true;
      HiLog.i(TAG, 'handlePlayCapture set delay play: ' + playInterval);
      this.mTimerId = setTimeout((): void => {
        if (this.isBlocked) {
          HiLog.i(TAG, 'handlePlayCapture start delay play ');
          this.playCapture();
        }
        this.isBlocked = false;
      }, this.DELAY_TIME - playInterval);
      return;
    }

    HiLog.i(TAG, 'handlePlayCapture give up a capture play');
    HiLog.end(TAG, 'handlePlayCapture');
  }

  async setSourceInfo(): Promise<void> {
    // @ts-ignore
    this.mSoundPool?.on('loadComplete', this.loadCompleteCallback().bind(this));
    // @ts-ignore
    this.mSoundPool?.on('playFinished', this.playFinishedCallback().bind(this));
  }

  private playFinishedCallback(): Callback<void> {
    return () => {
      HiLog.i(TAG, 'on play Finished.');
    };
  }

  private loadCompleteCallback(): Callback<number> {
    return (soundId) => {
      HiLog.d(TAG, `on load completed, soundId is : ${soundId}.`);
    };
  }

  private setErrorCallback(): void {
    // @ts-ignore
    this.mSoundPool?.on('error', this.soundPoolCallback().bind(this));
  }

  private soundPoolCallback(): ErrorCallback {
    return (error) => {
      HiLog.e(TAG, `error happened, error: ${error.message}.`);
    };
  }

  private soundDelay(): void {
    HiLog.i(TAG, 'flash on Status B.');
    const currMode = getStates().get<ModeType>('modeReducer', 'mode');
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
    const flashStatus: number = FeatureManager.getInstance().getFunction(FunctionId.FLASH).getValue();
    const position: camera.CameraPosition =
      getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    HiLog.i(TAG, `soundDelay isLongExposure:${this.isLongExposure}}`);
    this.handlePlayCapture();
  }

  private onFlashUnsteady(): void {
    HiLog.i(TAG, 'onFlashUnsteady B.');
    HiLog.i(TAG, `onFlashUnsteady isLongExposure:${this.isLongExposure}}`);
    const flashStatus: number = FeatureManager.getInstance().getFunction(FunctionId.FLASH).getValue();
    HiLog.i(TAG, `onFlashUnsteady, flashStatus: ${flashStatus}`);
    if (flashStatus === FlashMode.ON || (flashStatus === FlashMode.AUTO && !this.isLongExposure)) {
      this.handlePlayCapture();
    }
  }

  // 平板不走快速缩略图，监听真图
  private onPhotoThumbnailBack(): void {
    HiLog.i(TAG, 'onPhotoThumbnailBack B.');
  }

  /**
   * 注册系统音量监听
   */
  private registerAudioEvent(): void {
    HiLog.i(TAG, 'register audio event');
    try {
      this.audioVolumeManager.on('volumeChange', (event: audio.VolumeEvent): void => {
        HiLog.i(TAG, `system volume changed, volumeType: ${event.volumeType},
          volume: ${event.volume}, updateUI: ${event.updateUi}`);
        let isMute = AppStorage.get<boolean>('isMute');
        this.volumeSize = event.volume;
        if (event.volumeType === audio.AudioVolumeType.MEDIA && isMute) {
          // 图库大图组件，音量加键解除静音播放
          AppStorage.set<boolean>('isMute', false);
        }
        if (event.volumeType === audio.AudioVolumeType.MEDIA && event.volume === 0) {
          AppStorage.set<boolean>('isMute', true);
        }
      });
    } catch (err) {
      HiLog.e(TAG, ` register audio event error msg: ${err?.msg}, code: ${err?.code}`);
    }
  }

  /**
   * 解注册系统音量监听
   */
  private unRegisterAudioEvent(): void {
    HiLog.i(TAG, 'unRegister audio event');
    try {
      this.audioVolumeManager.off('volumeChange');
    } catch (err) {
      HiLog.e(TAG, `unRegister audio event error msg: ${err?.msg}, code: ${err?.code}`);
    }
  }

  private registerAudioVolumeGroup(): void {
    HiLog.i(TAG, 'register audio volume group');
    try {
      this.audioVolumeGroupManager.on('ringerModeChange', (ringerMode: audio.AudioRingMode) => {
        this.curRingerMode = ringerMode;
      });
    } catch (err) {
      HiLog.e(TAG, ` register audio volume group error msg: ${err?.msg}, code: ${err?.code}`);
    }
  }

  private unRegisterAudioVolumeGroup(): void {
    HiLog.i(TAG, 'unRegister audio volume group');
    try {
      this.audioVolumeGroupManager.off('ringerModeChange');
    } catch (err) {
      HiLog.e(TAG, `unRegister audio volume group error msg: ${err?.msg}, code: ${err?.code}`);
    }
  }

  private handleShowPickerView(data: PickerShowMsg): void {
    this.isPickerViewShow = data.showPicker;
    HiLog.i(TAG, `handleShowPickerView isPickerViewShow:${this.isPickerViewShow}`);
  }

  private getCameraIsCloseState(): void {
    this.isCloseCamera = true;
  }

  private exitPowerLodeSound(data: ActionData): void {
    if (this.isCloseCamera && !data['isDuringSavePowerMode']) {
      this.createSoundPool();
    }
  }

  private playCountDownTimerEffect(): void {
    HiLog.i(TAG, 'playCountDownTimerEffect invoke E.');
    this.playSoundVideo(this.soundIdList.get(Voice.CAMERA_COUNT_DOWN_URI), {}, true);
    HiLog.i(TAG, 'playCountDownTimerEffect invoke X.');
  }

  private onTvCountdown(): void {
    HiLog.i(TAG, 'onTvCountdown invoke E.');
    this.playSoundVideo(this.soundIdList.get(Voice.CAMERA_COUNTDOWN_URI));
    HiLog.i(TAG, 'onTvCountdown invoke X.');
  }

  private async initAudioVolumeGroupManager(data?: CameraStartTypeStruct): Promise<void> {
    if (data?.type === CameraStartType.COLD_START || data?.type === CameraStartType.WARM_START) {
      this.audioVolumeGroupManager = await this.audioVolumeManager.getVolumeGroupManager(audio.DEFAULT_VOLUME_GROUP_ID);
    }
  }
}