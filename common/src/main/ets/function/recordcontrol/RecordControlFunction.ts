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
/* instrument ignore file */
import camera from '@ohos.multimedia.camera';
import lazy { systemDateTime } from '../../utils/LazyImportUtil';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { BaseFunction } from '../core/BaseFunction';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';
import lazy { RenderType } from '../core/functionproperty/RenderType';
import lazy { UiElement } from '../core/UiElement';
import lazy { Action, UiStateMode } from '../../redux/actions/Action';
import lazy { RecordMode } from './RecordMode';
import lazy { CameraBasicService } from '../../camera/uithread/CameraBasicService';
import type { PreviewRecordOutputMessage, TagMessage, VideoOutputMessage } from '../../camera/DataType';
import type { TimeLapseRecordOutputMessage } from '../../camera/DataType';
import lazy { RecordAction } from './RecordAction';
import lazy { CameraAction, CameraStartType } from '../../camera/uithread/CameraAction';
import type { StartRecordResultType } from '../../utils/types';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { BlurAnimateUtil } from '../../utils/BlurAnimateUtil';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { ThumbnailAction, ThumbnailUpdateScene } from '../../component/thumbnail/ThumbnailAction';
import image from '@ohos.multimedia.image';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { PickerUiService } from '../../service/picker/PickerUiService';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { WindowService } from '../../service/window/WindowService';
import window from '@ohos.window';
import display from '@ohos.display';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { MicrophoneService } from '../../service/microphone/MicrophoneService';
import lazy { RecordController, RecordType } from './RecordController';
import lazy { getStates } from '../../redux';
import lazy { SuspendTaskUtil } from '../../utils/SuspendTaskUtil';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { DirectionCorrectionService } from '../../service/direction/DirectionCorrectionService';
import lazy { PcInfo } from '../../component/deviceinfo/PcInfo';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { AudioSessionService } from '../../service/audioSessionService/AudioSessionService';
import lazy { AccessibilityUtils } from '../../utils/AccessibilityUtils';
import ResGetter from '../../utils/ResGetter';
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { ZoomActionType } from '../../redux/actions/ZoomActionType';
import lazy { FunctionAction } from '../core/FunctionAction';
import lazy { MemoryService } from '../../service/Memory/MemoryService';
import { ComponentSnapshotService } from '../../service/componentSnapshot/ComponentSnapshotService';

const TAG = 'RecordControlFunction';

const DELAY_500 = 500;
const RECORD_DELAY = 200;
// 录像开始时间偏移量，为了减小录像时间和真实时间误差，取刷新频率的一半，即100，取开始时间到录像命令下发时间间隔约10ms
const RECORD_START_TIME_OFFSET = 100;
const DELAY_UPDATE_THUMBNAIL = 300;
const INTERVAL_TIME = 2000;

// 录像流程控制
export class RecordControlFunction extends BaseFunction {
  private mRecordState: RecordMode;
  private mIsBackGround: boolean;
  private mIsBufferReceivedTimelapse: boolean = false;
  private recordTimerId: number = Number.MIN_VALUE;
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.NONE];
  private thumbnail: image.PixelMap;
  private isRecordingSuccess: boolean;
  private isKeepFlowingRecording: boolean;
  private startRecordingResolution: number = SettingFuncDialogItemIndex.INDEX_NONE;
  private startRecordingFrameRate: number = SettingFuncDialogItemIndex.INDEX_NONE;
  private timeMemory: number = Number.MIN_VALUE;

  constructor() {
    super();
    this.mRecordState = RecordMode.TO_STOP;
  }

  getFunctionId(): FunctionId {
    return FunctionId.RECORD_CONTROL;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.NONE;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getUiElements(renderLocation: RenderLocation): Map<string | number, UiElement> {
    let uiElements = new Map();
    uiElements.set(RecordMode.TO_START, new UiElement()
      .setIcon($r('app.media.take_video_normal'))
      .setAccessibilityTitle($r('app.string.video_mode')));
    uiElements.set(RecordMode.TO_PAUSE, new UiElement()
      .setIcon($r('app.media.ic_video_pause'))
      .setAccessibilityTitle($r('app.string.video_mode')));
    uiElements.set(RecordMode.TO_RESUME, new UiElement()
      .setIcon($r('app.media.ic_video_continue'))
      .setAccessibilityTitle($r('app.string.video_mode')));
    uiElements.set(RecordMode.TO_STOP, new UiElement()
      .setIcon($r('app.media.ic_video_end'))
      .setAccessibilityTitle($r('app.string.video_mode')));
    return uiElements;
  }

  getDefaultValue(): number {
    return RecordMode.TO_STOP;
  }

  setValue(value: number): void {
    HiLog.i(TAG, `setValue value: ${value}.`);
    this.mRecordState = value;
    // startRecording and resumeRecording use timing control
    switch (this.mRecordState) {
      case RecordMode.TO_START:
        if (getStates().get<boolean>('modeReducer', 'isShowBigText')) {
          this.mStoreManager.postMessage(Action.updateShowBigTextFlag(false));
        }
        this.recordTimerId = setTimeout(() => {
          this.clearRecordTimer();
          this.startRecording();
        }, RECORD_DELAY);
        break;
      case RecordMode.TO_PAUSE:
        this.pauseRecording();
        break;
      case RecordMode.TO_RESUME:
        this.recordTimerId = setTimeout(() => {
          this.clearRecordTimer();
          this.resumeRecording();
        }, RECORD_DELAY);
        break;
      case RecordMode.TO_STOP:
        this.stopRecording();
        break;
      case RecordMode.SWITCH_CAMERA_TO_PAUSE:
        if (!this.isKeepFlowingRecording) {
          this.mStoreManager.postMessage(RecordAction.keepFlowingRecording(true));
          this.setKeepValue();
          this.isKeepFlowingRecording = true;
        }
        this.switchCameraPauseRecording();
        this.mRecordState = RecordMode.TO_PAUSE;
        break;
      case RecordMode.SWITCH_CAMERA_TO_RESUME:
        this.recordTimerId = setTimeout(() => {
          this.clearRecordTimer();
          this.switchCameraResumeRecording();
        }, RECORD_DELAY);
        this.mRecordState = RecordMode.TO_RESUME;
        break;
    }
  }

  private async updateStartTimeAfterTryAe(captureInterval: number): Promise<void> {
    const startTimeSeconds: number = await systemDateTime.getRealTime(false);
    HiLog.i(TAG, `updateStartTimeAfterTryAe, startTimeSeconds: ${startTimeSeconds}`);
    this.mStoreManager.postMessage(RecordAction.setStartSeconds(startTimeSeconds + RECORD_START_TIME_OFFSET));
  }

  private async bufferReceivedInTimeLapse(): Promise<void> {
    HiLog.i(TAG, 'bufferReceivedInTimeLapse');
    if (!this.mIsBufferReceivedTimelapse) {
      this.mIsBufferReceivedTimelapse = true;
      this.saveVideoThumbnail();
    }
  }

  private async startRecording(): Promise<void> {
    AudioSessionService.activateAudioSession();
    if (this.isInSwipeRecording()) {
      this.startRecordingPreview(this.isSupportRealTimeFilter());
    } else {
      this.startRecordingVideoOutput();
    }
    this.fullMemoryStop();
    MicrophoneService.getInstance().microphoneSubscribe();
  }

  private async startRecordingPreview(isSupportRealTimeFilter: boolean): Promise<void> {
    HiLog.i(TAG, 'startRecordingPreview E .');
    const previewRecordMessage: PreviewRecordOutputMessage = CameraBasicService.getInstance().getPreviewRecordMessage();
    if (AppStorage.get('enableScreenReader') || !WindowService.getInstance().getWindowKeepScreenOn()) {
      WindowService.getInstance().setWindowKeepScreenOn(true);
    }
    const startTimeSeconds: number = await systemDateTime.getRealTime(false);
    HiLog.i(TAG, `startRecordingPreview startTimeSeconds ${startTimeSeconds}`);
    this.mStoreManager.postMessage(RecordAction.setStartSeconds(startTimeSeconds + RECORD_START_TIME_OFFSET));
    HiLog.i(TAG, `this.mIsBackGround: ${this.mIsBackGround} `);
    if (this.mIsBackGround && AppStorage.get('isBackground')) {
      HiLog.w(TAG, `startRecordingPreview When in background, the video status needs to be reset to READY`);
      this.mIsBackGround = false;
      this.mStoreManager.postMessage(RecordAction.stopped());
      return;
    }
    await CameraBasicService.getInstance().swapDeferredSurface(true);
    this.mCameraProxy.startRecorderRecording(previewRecordMessage, isSupportRealTimeFilter)
      .then((data: StartRecordResultType) => {
        this.isRecordingSuccess = data.isSuccess;
        if (data && data.isSuccess) {
          this.mStoreManager.postMessage(CameraAction.started(CameraStartType.RECORD));
          this.mStoreManager.postMessage(RecordAction.started());
          this.saveVideoThumbnail();
        } else {
          this.mStoreManager.postMessage(RecordAction.stop());
          this.mStoreManager.postMessage(RecordAction.stopped());
          this.dealRecordErr();
        }
        this.enableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
      }).catch((err) => {
      HiLog.e(TAG, `startRecorderRecording ${err?.code}`);
    });
    HiLog.i(TAG, 'startRecordingPreview X.');
  }

  private async startRecordingTimelapse(isSupportRealTimeFilter: boolean): Promise<void> {
    HiLog.i(TAG, 'startRecordingTimelapse E .');
    const timelapseRecordMessage: TimeLapseRecordOutputMessage =
      CameraBasicService.getInstance().getTimelapseRecordMessage();
    if (AppStorage.get('enableScreenReader') || !WindowService.getInstance().getWindowKeepScreenOn()) {
      WindowService.getInstance().setWindowKeepScreenOn(true);
    }
    const startTimeSeconds: number = await systemDateTime.getRealTime(false);
    HiLog.i(TAG, `startRecordingTimelapse startTimeSeconds ${startTimeSeconds}`);
    this.mStoreManager.postMessage(RecordAction.setStartSeconds(startTimeSeconds + RECORD_START_TIME_OFFSET));
    HiLog.i(TAG, `this.mIsBackGround: ${this.mIsBackGround} `);
    if (this.mIsBackGround && AppStorage.get('isBackground')) {
      HiLog.w(TAG, `startRecordingTimelapse When in background, the video status needs to be reset to READY`);
      this.mIsBackGround = false;
      this.mStoreManager.postMessage(RecordAction.stopped());
      return;
    }
    HiLog.i(TAG, 'startRecordingTimelapse X.');
  }

  private async startRecordingVideoOutput(): Promise<void> {
    HiLog.i(TAG, 'StartRecording E .');
    if (AppStorage.get('enableScreenReader') || !WindowService.getInstance().getWindowKeepScreenOn()) {
      WindowService.getInstance().setWindowKeepScreenOn(true);
    }
    const message: VideoOutputMessage = CameraBasicService.getInstance().getVideoMessage();
    message.isPreRecord = RecordController.getInstance().getRecordType() === RecordType.longClick;
    const tagMessage: TagMessage = CameraBasicService.getInstance().getTagMessage();
    const startTimeSeconds: number = await systemDateTime.getRealTime(false);
    HiLog.i(TAG,
      `RECORD_TRACK StartRecording startTimeSeconds ${startTimeSeconds}, isPreRecord: ${message.isPreRecord}.`);
    this.mStoreManager.postMessage(RecordAction.setStartSeconds(startTimeSeconds + RECORD_START_TIME_OFFSET));
    HiLog.i(TAG, `this.mIsBackGround: ${this.mIsBackGround} `);
    // picker和系统相机同时存在时存在极端场景,picker切前台时,function未load,mIsBackGround状态仍为true
    if (this.mIsBackGround && AppStorage.get('isBackground')) {
      HiLog.w(TAG, `startRecordingVideoOutput When in background, the video status needs to be reset to READY`);
      this.mIsBackGround = false;
      this.mStoreManager.postMessage(RecordAction.stopped());
      return;
    }
    const data: StartRecordResultType = await this.mCameraProxy.startRecording(message, tagMessage);
    this.isRecordingSuccess = data.isSuccess;
    if (data && data.isSuccess) {
      const startTime: number = await systemDateTime.getRealTime(false);
      this.mStoreManager.postMessage(RecordAction.setStartSeconds(startTime));
      this.mStoreManager.postMessage(CameraAction.started(CameraStartType.RECORD));
      this.mStoreManager.postMessage(RecordAction.started());
      this.saveVideoThumbnail();
    } else {
      this.mStoreManager.postMessage(RecordAction.stop());
      this.mStoreManager.postMessage(RecordAction.stopped());
      this.dealRecordErr();
    }
    this.enableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    HiLog.i(TAG, 'startRecording X.');
  }

  private async generateThumbnail(): Promise<null | image.PixelMap> {
    const state = getStates();
    let pixelMap = null;
    try {
      pixelMap = ComponentSnapshotService.getInstance().generateSnapshotImg(state.get<ModeType>('modeReducer', 'mode'));
      if (pixelMap) {
        if (!DeviceInfo.isPc()) {
          BlurAnimateUtil.rotatePixelMap(pixelMap, state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'))
        }
      } else {
        HiLog.e(TAG, 'The generateSnapshotImg pixelMap is null.');
      }
    } catch (e) {
      HiLog.e(TAG, `execScreenshotThumbnail err: ${JSON.stringify(e)}.`);
    }

    return pixelMap;
  }

  private async saveVideoThumbnail(): Promise<void> {
    const isPicker = GlobalContext.get().getIsPicker();
    const pixelMap = await this.generateThumbnail();
    if (!AppStorage.get('isLemCollaps')) {
      await this.rotateImg(pixelMap);
    }
    if (isPicker) {
      PickerUiService.getInstance().setThumbnail(pixelMap);
      BlurAnimateUtil.setBlurPixelMap(pixelMap, true);
    } else {
      await this.thumbnail?.release();
      this.thumbnail = pixelMap;
    }
  }

  private lockVdeCollapsedRotateImg(currentDirection: WindowDirection): number {
    // vde屏幕开启旋转锁定走此逻辑
    const rotation = DisplayService.getInstance().getDisplay().rotation;
    switch (rotation) {
      case 0:
        if (currentDirection === WindowDirection.LEFT) {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
        } else if (currentDirection === WindowDirection.RIGHT) {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
        } else if (currentDirection === WindowDirection.BOTTOM) {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_180;
        } else {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
        }
      case 2:
        if (currentDirection === WindowDirection.LEFT) {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
        } else if (currentDirection === WindowDirection.RIGHT) {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
        } else if (currentDirection === WindowDirection.BOTTOM) {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
        } else {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
        }
      case 3:
        if (currentDirection === WindowDirection.LEFT) {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
        } else if (currentDirection === WindowDirection.RIGHT) {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_180;
        } else if (currentDirection === WindowDirection.BOTTOM) {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
        } else {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
        }
      default:
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
    }
  }

  private lockVdeShowBackAsFrontRotateImg(currentDirection: WindowDirection): number {
    if (currentDirection === WindowDirection.LEFT) {
      return BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
    } else if (currentDirection === WindowDirection.RIGHT) {
      return BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
    } else if (currentDirection === WindowDirection.BOTTOM) {
      return BlurAnimateUtil.IMG_ROTATE_ANGLE_180;
    } else {
      return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
    }
  }

  private unLockRotateImg(dis: display.Display, isFront: boolean): number {
    const windowStatus = WindowService.getInstance().getWindowStatus();
    const isFloatingOrSplit =
      (windowStatus === window.WindowStatusType.FLOATING || windowStatus === window.WindowStatusType.SPLIT_SCREEN)
    if (isFloatingOrSplit) {
      return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
    }
    switch (dis.orientation) {
      case 1:
        return isFront ? BlurAnimateUtil.IMG_ROTATE_ANGLE_270 : BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
      case 2:
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_180;
      case 3:
        return isFront ? BlurAnimateUtil.IMG_ROTATE_ANGLE_90 : BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
      default:
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
    }
  }

  private defRotateAngle(currentDirection: WindowDirection): number {
    const isFront = this.isFrontCamera();
    const isLemCollapsOrFrontCamera: boolean = AppStorage.get('isLemCollaps') || isFront;
    if (currentDirection === WindowDirection.LEFT) {
      return isLemCollapsOrFrontCamera ?
        BlurAnimateUtil.IMG_ROTATE_ANGLE_270 : BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
    } else if (currentDirection === WindowDirection.RIGHT) {
      return isLemCollapsOrFrontCamera ?
        BlurAnimateUtil.IMG_ROTATE_ANGLE_90 : BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
    } else if (currentDirection === WindowDirection.BOTTOM) {
      return BlurAnimateUtil.IMG_ROTATE_ANGLE_180;
    }
    return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
  }

  private async rotateImg(pixelMap: image.PixelMap | null): Promise<void> {
    const isFront = this.isFrontCamera();
    const currentDirection: WindowDirection =
      DirectionCorrectionService.directionCorrection(getStates().get<WindowDirection>('contextReducer', 'direction'),
        getStates().get<boolean>('windowReducer', 'isLockRotation'));
    HiLog.i(TAG, 'startRecording currentDirection: ' + currentDirection);
    let rotateAngle: number = BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
    rotateAngle = this.defRotateAngle(currentDirection);
    const windowStatus = WindowService.getInstance().getWindowStatus();
    const dis: display.Display = DisplayService.getInstance().getDisplay();
    const isLockRotation = getStates().get<boolean>('windowReducer', 'isLockRotation');
    const rotationStatus = getStates().get<string>('windowReducer', 'rotationStatus');
    HiLog.i(TAG,
      `startRecording windowStatus: ${windowStatus}, dis: ${dis.orientation}, rotationStatus: ${rotationStatus}`);
    if ((windowStatus === window.WindowStatusType.FLOATING || windowStatus === window.WindowStatusType.SPLIT_SCREEN) &&
      dis.orientation !== 0 && !isLockRotation) {
      rotateAngle = this.unLockRotateImg(dis, isFront);
    }
    let angle = CameraAppCapability.getInstance().getPcCameraOrientation();
    if (DeviceInfo.isPc()) {
      rotateAngle = !PcInfo.isRotatablePc() ? angle : this.getPcThumbnailRotation();
      await pixelMap.rotate(rotateAngle);
    } else if (rotateAngle) {
      await pixelMap.rotate(rotateAngle);
    }
    let isMirror: boolean = FeatureManager.getInstance().getFunction(FunctionId.MIRROR)?.getValue();
    // 后置自拍右滑录像不支持镜像
    if (isMirror) {
      await pixelMap?.flip(true, false);
    }
  }

  private getPcThumbnailRotation(): number {
    const rotation = DisplayService.getInstance().getDisplay().rotation;
    let xComponentRotate = 0;
    switch (rotation) {
      case 0:
        xComponentRotate = BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
        break;
      case 1:
        xComponentRotate = BlurAnimateUtil.IMG_ROTATE_ANGLE_180;
        break;
      case 2:
        xComponentRotate = BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
        break;
      case 3:
        xComponentRotate = BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
        break;
      default:
        xComponentRotate = BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
    }
    return xComponentRotate;
  }

  onBackGround(): void {
    HiLog.i(TAG, 'onBackGround');
    clearTimeout(this.recordTimerId);
    this.mIsBackGround = true;
    this.isKeepFlowingRecording = false;
  }

  onForeground(): void {
    HiLog.i(TAG, 'onForeground');
    this.mIsBackGround = false;
  }

  private dealRecordErr(): void {
    HiLog.i(TAG, 'dealRecordErr E.');
  }

  private async resumeRecording(): Promise<void> {
    if (this.isInSwipeRecording()) {
      this.resumeRecordingPreview(this.isSupportRealTimeFilter());
    } else {
      this.resumeRecordingVideoOutput();
    }
    this.fullMemoryStop();
  }

  private isSupportRealTimeFilter(): boolean {
    return false;
  }

  private async switchCameraResumeRecording(): Promise<void> {
    HiLog.i(TAG, 'switchCameraResumeRecording E.');
    await this.mCameraProxy.resumeRecording();
    this.mStoreManager.postMessage(RecordAction.resumed());
    this.enableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    HiLog.i(TAG, 'switchCameraResumeRecording X.');
  }

  private async resumeRecordingPreview(isSupportRealTimeFilter: boolean): Promise<void> {
    HiLog.i(TAG, 'resumeRecordingPreview E.');
    await this.mCameraProxy.resumeRecordingPreview(isSupportRealTimeFilter);
    this.mStoreManager.postMessage(Action.updateShowBigTextFlag(true));
    this.mStoreManager.postMessage(RecordAction.resumed());
    this.enableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    HiLog.i(TAG, 'resumeRecordingPreview X.');
  }

  private async resumeRecordingVideoOutput(): Promise<void> {
    HiLog.i(TAG, 'resumeRecording E.');
    await this.mCameraProxy.resumeRecording();
    this.mStoreManager.postMessage(Action.updateShowBigTextFlag(true));
    this.mStoreManager.postMessage(RecordAction.resumed());
    this.enableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    HiLog.i(TAG, 'resumeRecording X.');
  }

  getValue(): number {
    return this.mRecordState;
  }

  isAvailable(): boolean {
    return true;
  }

  load(renderLocations: RenderLocation[]): void {
    super.load(renderLocations);
    const code: string = this.mBase.hashCode();
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackGround.bind(this), code);
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), code);
    this.mEventBus.on(ActionType.ACTION_TIME_LAPSE_TRY_AE_DONE, this.updateStartTimeAfterTryAe.bind(this), code);
    this.mEventBus.on(ActionType.ACTION_BUFFER_RECEIVED_TIMELAPSE, this.bufferReceivedInTimeLapse.bind(this), code);
    this.mEventBus.on(RecordActionType.VIDEO_FRAME_END, this.handleVideoFrameEnd.bind(this), code);
  }

  unload(renderLocations: RenderLocation[]): void {
    super.unload(renderLocations);
    this.mEventBus.clear(this.mBase.hashCode());
    this.thumbnail?.release(() => {
      this.thumbnail = null;
    });
  }

  private async pauseRecording(): Promise<void> {
    if (this.isInSwipeRecording()) {
      this.pauseRecordingPreview(this.isSupportRealTimeFilter());
    } else {
      this.pauseRecordingVideoOutput();
    }
    clearInterval(this.timeMemory);
  }

  private async switchCameraPauseRecording(): Promise<void> {
    HiLog.i(TAG, 'switchCameraPauseRecording E.');
    await this.mCameraProxy.pauseRecording();
    this.mStoreManager.postMessage(RecordAction.paused());
    HiLog.i(TAG, 'switchCameraPauseRecording X.');
  }

  private async pauseRecordingPreview(isSupportRealTimeFilter: boolean): Promise<void> {
    HiLog.i(TAG, 'pauseRecordingPreview E.');
    await this.mCameraProxy.pauseRecorderRecording(isSupportRealTimeFilter);
    this.mStoreManager.postMessage(RecordAction.paused());
    this.mStoreManager.postMessage(Action.updateShowBigTextFlag(true));
    HiLog.i(TAG, 'pauseRecordingPreview X.');
  }

  private async pauseRecordingVideoOutput(): Promise<void> {
    HiLog.i(TAG, 'pauseRecording E.');
    this.disableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    await this.mCameraProxy.pauseRecording();
    this.mStoreManager.postMessage(RecordAction.paused());
    this.mStoreManager.postMessage(Action.updateShowBigTextFlag(true));
    HiLog.i(TAG, 'pauseRecording X.');
  }

  private async toUpdateThumbnail(isInSwipeRecording: boolean): Promise<void> {
    await new Promise((resolve: Function) => {
      if (isInSwipeRecording) {
        const timerId: number = setTimeout(() => {
          HiLog.i(TAG, `updateThumbnail timeout.`);
          clearTimeout(timerId);
          resolve();
        }, DELAY_UPDATE_THUMBNAIL);
      } else {
        HiLog.i(TAG, `updateThumbnail no timeout.`);
        resolve();
      }
    }).then(() => {
      const scene: ThumbnailUpdateScene = isInSwipeRecording ? ThumbnailUpdateScene.BURST : ThumbnailUpdateScene.RECORD;
      if (getStates().get<ModeType>('modeReducer', 'mode') === ModeType.PHOTO) { //TODO 这里更新屏蔽视频更新多次刷新
        this.mStoreManager.postMessage(ThumbnailAction.received(this.thumbnail, scene));
      }
    });
  }

  private async stopRecording(): Promise<void> {
    const cameraShotKey = GlobalContext.get().getCameraShotKey();
    HiLog.i(TAG, `stopRecording begin cameraShotKey ${cameraShotKey}.`);
    const recordTimerNULL = this.recordTimerId === Number.MIN_VALUE;
    if (!recordTimerNULL) {
      this.clearRecordTimer();
    }
    this.changeExposureValue();
    HiLog.i(TAG, 'stopRecording E.');
    const isNeedResetParams = this.isKeepFlowingRecording;
    if (this.isKeepFlowingRecording) {
      this.mStoreManager.postMessage(RecordAction.keepFlowingRecording(false));
      this.isKeepFlowingRecording = false;
    }
    const validateThumbnail: boolean = AppStorage.get('windowStageEventType') === window.WindowStageEventType.PAUSED ||
      AppStorage.get('windowStageEventType') === window.WindowStageEventType.INACTIVE;
    const isInSwipeRecording: boolean = this.isInSwipeRecording();
    if (isInSwipeRecording) {
      HiLog.i(TAG, 'swipe Record exit');
      await this.mCameraProxy.stopRecorderRecording(false, validateThumbnail);
      await CameraBasicService.getInstance().swapDeferredSurface(false);
    } else {
      await this.mCameraProxy.stopRecording(validateThumbnail);
    }
    this.mStoreManager.postMessage(RecordAction.stopped());
    if (isNeedResetParams) {
      this.resetParams();
    }
    SuspendTaskUtil.getInstance().onRecordStopped();

    if (this.isUpdateThumbnail(cameraShotKey, recordTimerNULL)) {
      if (AppStorage.get('isLemCollaps')) {
        await this.rotateImg(this.thumbnail);
      }
      await this.toUpdateThumbnail(isInSwipeRecording);
    }
    this.mIsBufferReceivedTimelapse = false;
    this.enableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    MicrophoneService.getInstance().microphoneUnsubscribe();
    if (AppStorage.get('enableScreenReader')) {
      WindowService.getInstance().setWindowKeepScreenOn(false);
    }
    if (GlobalContext.get().getIsPicker() && getStates().get<boolean>('uiReducer', 'showPicker')) {
      PickerUiService.isCameraActive = false;
    }
    AudioSessionService.deactivateAudioSession();
    clearInterval(this.timeMemory);
    HiLog.i(TAG, 'stopRecording X.');
  }

  private changeExposureValue(): void {
    if(getStates().get<ModeType>('modeReducer', 'mode') === ModeType.VIDEO) {
      const mExposureFunction = FeatureManager.getInstance().getFunction(FunctionId.EXPOSURE);
      mExposureFunction['changeExposureAuto']();
    }
  }

  //录制中内存不足停止录像
  private fullMemoryStop(): void {
    clearInterval(this.timeMemory);
    this.timeMemory = setInterval(() => {
      if (MemoryService.getInstance().isFullStorage()) {
        clearInterval(this.timeMemory);
        this.mStoreManager.postMessage(RecordAction.stop());
        this.mStoreManager.postMessage(RecordAction.stopped());
      }
    }, INTERVAL_TIME);
  }

  private isUpdateThumbnail(cameraShotKey: string, recordTimerNULL: boolean): boolean {
    HiLog.i(TAG, `stopRecording cameraShotKey ${GlobalContext.get().getCameraShotKey()}.`);
    if (DeviceInfo.isTv() || GlobalContext.get().getIsPicker()) {
      return false;
    }
    if (cameraShotKey !== GlobalContext.get().getCameraShotKey() || !recordTimerNULL || !this.isRecordingSuccess) {
      return false;
    }
    return true;
  }

  private isNeedUpdateThumbnailInTimelapse(): boolean {
    const isBack = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
    camera.CameraPosition.CAMERA_POSITION_BACK;
    return this.mIsBufferReceivedTimelapse || !isBack;
  }

  private isInSwipeRecording(): boolean {
    return getStates().get<ModeType>('modeReducer', 'mode') === ModeType.PHOTO;
  }

  private clearRecordTimer(): void {
    clearTimeout(this.recordTimerId);
    this.recordTimerId = Number.MIN_VALUE;
  }

  private setKeepValue(): void {
    this.startRecordingResolution = FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION)?.getValue();
    this.startRecordingFrameRate = FeatureManager.getInstance().getFunction(FunctionId.FRAME_RATE)?.getValue();
  }

  private resetParams(): void {
    if (this.startRecordingResolution !==
    FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION)?.getValue()
      || this.startRecordingFrameRate !==
      FeatureManager.getInstance().getFunction(FunctionId.FRAME_RATE).getValue()) {
      this.mStoreManager.postMessage(CameraAction.restart(getStates().get<number>('zoomReducer', 'zoomRatio')));
      BlurAnimateUtil.generatePixelMapFromSurface();
      this.mEventBus.emit(ZoomActionType.ACTION_CHANGE_ZOOM_BY_FRAMERATE, []);
      HiLog.i(TAG, 'updateNovaFrameRate');
    }
  }

  private handleVideoFrameEnd(): void {
    HiLog.i(TAG, `handleVideoFrameEnd E mRecordState: ${this.mRecordState}`);
    if (this.mRecordState === RecordMode.TO_PAUSE) {
      this.enableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    }
  }
}