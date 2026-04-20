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

import lazy { CameraService, VlogTool } from './CameraService';
import lazy { HiLog } from '../../utils/HiLog';
import camera from '@ohos.multimedia.camera';
import lazy {
  SessionMessage,
  CameraInputMessage,
  VideoOutputMessage,
  PreviewRecordOutputMessage,
  TimeLapseRecordOutputMessage,
  PreviewOutputMessage,
  SessionInfo,
  TagMessage,
  RestartPreviewType,
  CloseInfoToWork,
  TimeLapseRecordMessage
} from '../DataType';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { TaskExecutor } from '../../utils/TaskExecutor';
import type { PickerSaveResolveType } from '../../service/picker/PickerFileWorkerService';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { modulesManager } from '../../worker/WorkerModuleManager';
import lazy { WorkerTask } from '../WorkerTask';
import type { PickerInfo, StartRecordResultType } from '../../utils/types';
import lazy { OutputType } from '../../function/outputswitcher/OutputType';
import lazy { OutputOperation } from '../../function/outputswitcher/OutputOperation';
import lazy {
  LeftRightSwipeWorkerCaptureService
} from '../../component/leftrightswipecontrol/LeftRightSwipeWorkerCaptureService'
import type { CaptureMessage } from '../../function/capture/CaptureMessage';
import lazy { LocationType } from '../../service/location/LocationMessage';
import type { LocationMessage } from '../../service/location/LocationMessage';
import lazy { workerCallback } from './WorkerCallback';
import lazy { RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import VideoModule from './modules/video/VideoModule';
import lazy { colorSpaceManager } from '@kit.ArkGraphics2D';
import lazy { Context } from '@kit.AbilityKit';
import lazy { ExposureData, FocusData } from '../../component/focusExposure/FocusExposureHelper';
import lazy { simpleStringify } from '../../utils/SimpleStringify';
import lazy { window } from '@kit.ArkUI';

/* instrument ignore file */
const TAG: string = 'CameraTaskHandler';
const BEAUTY_ARRAY_INDEX_2: number = 2;
const ANGLE_360: number = 360;
const START_UP_INIT: number = 10;
const SKIN_TONE_OFFSET: number = 5;

type Callback = (args: unknown) => unknown;

export const LOCATION_MESSAGE: LocationMessage = {
  type: LocationType.NO_PERMISSION
};

export class CameraTaskHandler {
  private taskMap: Map<string, unknown> = new Map([
    [WorkerTask.ACTION_RECOVERY_WORKER_THREAD, this.recoveryWorkerThread.bind(this)],
    [WorkerTask.ACTION_INIT, this.initCamera.bind(this)],
    [WorkerTask.ACTION_INIT_CAMERA_LIST, this.initCameraList.bind(this)],
    [WorkerTask.ACTION_START_UP, this.startupCamera.bind(this)],
    [WorkerTask.ACTION_START_PREVIEW, this.startPreview.bind(this)],
    [WorkerTask.ACTION_ADD_DEFERRED_SURFACE, this.addDeferredSurface.bind(this)],
    [WorkerTask.ACTION_SWAP_DEFERRED_SURFACE, this.swapDeferredSurface.bind(this)],
    [WorkerTask.ACTION_COLLABORATE_CONTROL_PREVIEW_OUTPUT, this.switchWatchCollaborateControl.bind(this)],
    [WorkerTask.ACTION_RESTART_PREVIEW, this.restartPreview.bind(this)],
    [WorkerTask.ACTION_CHANGE_MODE, this.restartPreview.bind(this)],
    [WorkerTask.ACTION_SWITCH_CAMERA, this.restartPreview.bind(this)],
    [WorkerTask.ACTION_SWITCH_CAMERA_CHANGE_MODE, this.restartPreview.bind(this)],
    [WorkerTask.ACTION_SET_ZOOM_RATIO, this.setZoomRatio.bind(this)],
    [WorkerTask.ACTION_CLOSE_CAMERA, this.closeCamera.bind(this)],
    [WorkerTask.ACTION_STOP_PREVIEW_OUTPUT, this.stopPreviewOutput.bind(this)],
    [WorkerTask.ACTION_CAPTURE, this.capture.bind(this)],
    [WorkerTask.ACTION_ADD_PIP_SURFACE_ID, this.addPipSurface.bind(this)],
    [WorkerTask.ACTION_RECORD_START, this.startRecording.bind(this)],
    [WorkerTask.ACTION_RECORD_START_RECORDER, this.startRecorderRecording.bind(this)],
    [WorkerTask.ACTION_RECORD_PAUSE, this.pauseRecording.bind(this)],
    [WorkerTask.ACTION_RECORD_PAUSE_RECORDER, this.pauseRecorderRecording.bind(this)],
    [WorkerTask.ACTION_RECORD_RESUME, this.resumeRecording.bind(this)],
    [WorkerTask.ACTION_RECORD_RESUME_RECORDER, this.resumeRecorderRecording.bind(this)],
    [WorkerTask.ACTION_RECORD_STOP, this.stopRecording.bind(this)],
    [WorkerTask.ACTION_RECORD_STOP_RECORDER, this.stopRecorderRecording.bind(this)],
    [WorkerTask.ACTION_CHANGE_FLASH_MODE, this.setFlashMode.bind(this)],
    [WorkerTask.ACTION_CHANGE_STITCHING_TYPE, this.setStitchingMode.bind(this)],
    [WorkerTask.ACTION_CHANGE_STITCHING_DIRECTION, this.setStitchingDirection.bind(this)],
    [WorkerTask.ACTION_CHANGE_STITCHING_MOVE, this.setStitchingMove.bind(this)],
    [WorkerTask.ACTION_SET_FOCUS, this.setFocus.bind(this)],
    [WorkerTask.ACTION_IS_FOCUS_MODE_SUPPORTED, this.isFocusModeSupported.bind(this)],
    [WorkerTask.ACTION_SET_METERING_POINT, this.setMeteringPoint.bind(this)],
    [WorkerTask.ACTION_COLLABORATION_MODE, this.getCollaborationMode.bind(this)],
    [WorkerTask.ACTION_SET_XMAGE, this.setXmage.bind(this)],
    [WorkerTask.ACTION_SET_VIDEO_STABILIZATION, this.setVideoStabilization.bind(this)],
    [WorkerTask.ACTION_SET_PORTRAIT_EFFECT, this.setPortraitEffect.bind(this)],
    [WorkerTask.ACTION_TRIGGER_LIGHTING, this.triggerLighting.bind(this)],
    [WorkerTask.ACTION_START_FACE_METADATA, this.startFaceMetadata.bind(this)],
    [WorkerTask.ACTION_ENABLE_SUPER_MACRO, this.enableMacro.bind(this)],
    [WorkerTask.ACTION_START_SESSION, this.startSession.bind(this)],
    [WorkerTask.ACTION_STOP_SESSION, this.stopSession.bind(this)],
    [WorkerTask.ACTION_SET_EXPOSURE_VALUE, this.setExposureValue.bind(this)],
    [WorkerTask.ACTION_SET_EXPOSURE, this.setExposure.bind(this)],
    [WorkerTask.ACTION_CONFIRM_CAPTURE, this.confirmCapture.bind(this)],
    [WorkerTask.ACTION_HANDLE_ZOOM_VIBRATOR, this.handleZoomVibrator.bind(this)],
    [WorkerTask.ACTION_STOP_ZOOM_VIBRATOR, this.stopZoomVibrator.bind(this)],
    [WorkerTask.ACTION_SAVE_PICKER_FILE, this.savePickerFileInWorker.bind(this)],
    [WorkerTask.ACTION_PREPARE_OR_UNPREPARE_ZOOM, this.prepareOrUnprepareZoom.bind(this)],
    [WorkerTask.ACTION_SET_SMOOTH_ZOOM, this.setSmoothZoom.bind(this)],
    [WorkerTask.ACTION_ENABLE_SCENE_FEATURE, this.enableSceneFeature.bind(this)],
    [WorkerTask.ACTION_SET_VIRTUAL_APERTURE, this.setVirtualAperture.bind(this)],
    [WorkerTask.ACTION_SET_PHYSICAL_APERTURE, this.setPhysicalAperture.bind(this)],
    [WorkerTask.ACTION_SET_SUPER_MOTION_DETECTION, this.setSlowMotionDetectionArea.bind(this)],
    [WorkerTask.ACTION_GET_FOCUS_DISTANCE, this.getFocusDistance.bind(this)],
    [WorkerTask.ACTION_GET_ISO_RANGE, this.getIsoRange.bind(this)],
    [WorkerTask.ACTION_SET_METERING, this.setMeteringMode.bind(this)],
    [WorkerTask.ACTION_SET_ISO, this.setIsoValue.bind(this)],
    [WorkerTask.ACTION_SET_APERTURE, this.setApertureValue.bind(this)],
    [WorkerTask.ACTION_SET_AUXILIARY, this.setAuxiliary.bind(this)],
    [WorkerTask.ACTION_SET_LIVE_PHOTO, this.setLivePhoto.bind(this)],
    [WorkerTask.ACTION_CAMERA_SHOT_KEY, this.setCameraShotKey.bind(this)],
    [WorkerTask.ACTION_SEND_DIRECTION, this.setDirection.bind(this)],
    [WorkerTask.ACTION_REFRESH_PICKER_INFO, this.refreshPickerInfo.bind(this)],
    [WorkerTask.ACTION_IS_DEPTH_FUSION_CONFIGURED, this.isDepthFusionConfigured.bind(this)],
    [WorkerTask.ACTION_SET_TIME_LAPSE_INTERVAL, this.setTimeLapseInterval.bind(this)],
    [WorkerTask.ACTION_GET_TIME_LAPSE_INTERVAL, this.getTimeLapseInterval.bind(this)],
    [WorkerTask.ACTION_PANORAMA_MAX_START, this.panoramaMaxPreviewOutputStart.bind(this)],
    [WorkerTask.ACTION_PANORAMA_MIN_START, this.panoramaMinPreviewOutputStart.bind(this)],
    [WorkerTask.ACTION_PANORAMA_MAX_STOP, this.panoramaMaxPreviewOutputStop.bind(this)],
    [WorkerTask.ACTION_PANORAMA_MIN_STOP, this.panoramaMinPreviewOutputStop.bind(this)],
    [WorkerTask.ACTION_DELETE_PICKER_VIDEO_FILE, this.deletePickerVideoFile.bind(this)],
    [WorkerTask.RESET_VIDEO_FILE_MANAGER_URI, this.resetVideoFileManagerUri.bind(this)],
    [WorkerTask.SWITCH_COLLABORATION, this.switchCollaborate.bind(this)],
    [WorkerTask.CHANGE_LOCATION, this.changeLocation.bind(this)],
    [WorkerTask.SET_MIRROR, this.setMirror.bind(this)],
    [WorkerTask.AUTO_FRAME_RATE, this.setAutoFrameRate.bind(this)],
    [WorkerTask.ACTION_SET_CUSTOM_COLOR_STYLE_SETTING, this.setCustomColorStyleSetting.bind(this)],
    [WorkerTask.SET_OPERATION_EMOTION, this.setOperationEmotion.bind(this)],
    [WorkerTask.RESET_WORKER_PHOTO_COUNT, this.resetWorkerPhotoCount.bind(this)],
    [WorkerTask.SET_SWING_SUBSCRIBE_STATUS, this.setSwingSubscribeStatus.bind(this)],
    [WorkerTask.SET_AUDIO_EXTRA, this.setAudioZoomExtra.bind(this)],
    [WorkerTask.SET_SHORT_VIDEO_INDEX, this.setShortVideoIndex.bind(this)],
    [WorkerTask.SET_WIND_NOISE_SUPPRESSION, this.setWindNoiseSuppression.bind(this)],
    [WorkerTask.KEEP_USING_STELLAR_LENSES, this.onKeepUsingStellarLenses.bind(this)],
    [WorkerTask.SCAN_CODE_CLOSE, this.scanCodeClose.bind(this)],
    [WorkerTask.ENABLE_AI_COMPOSITION, this.enableAIComposition.bind(this)],
    [WorkerTask.ENABLE_LOG_ASSISTANCE, this.enableLogAssistance.bind(this)],
    [WorkerTask.CHANGE_COLLABORATION_PREVIEWOUTPUT, this.onChangeCollaborationPreviewOutput.bind(this)],
    [WorkerTask.ACTION_CHANGE_CONSTELLATION_STATUS, this.changeConstellationStatus.bind(this)],
    [WorkerTask.ACTION_SET_FOCUS_TRACKING_MODE, this.setFocusTrackingMode.bind(this)],
    [WorkerTask.SET_FILTER_TYPE, this.setFilterType.bind(this)],
    [WorkerTask.SET_ULTRA_PHOTO, this.setUltraPhoto.bind(this)],
    [WorkerTask.ACTION_SHUTTER_BUTTON_UP, this.shutterButtonUp.bind(this)],
    [WorkerTask.ACTION_NEED_DELETE_ONE_PIC, this.setNeedDeleteOnePhoto.bind(this)],
    // [WorkerTask.ACTION_SHUTTER_BUTTON_UP, this.setUltraPhoto.bind(this)]
  ]);
  private mCameraService: CameraService;

  public constructor() {
    this.mCameraService = new CameraService();
    GlobalContext.get().setCameraService(this.mCameraService);
  }

  public async solveTask(type: string, data: unknown): Promise<unknown> {
    const func: Callback = <Callback> this.taskMap.get(type);
    if (!func) {
      HiLog.e(TAG, 'CameraTaskHandler task type undefined error. ' + type);
      return undefined;
    }
    const result: unknown = await func.apply(this, data);
    return result;
  }

  public async getCollaborationMode(cm: string): Promise<void> {
    const pickerWorkerService = await modulesManager.getPickerFileWorkerService();
  }

  private async recoveryWorkerThread(): Promise<void> {
    HiLog.begin(TAG, 'recoveryWorkerThread');
    await this.mCameraService?.stopSession(); // 暂停session用于暂停流
    await this.mCameraService?.releasePreviewOutput(); // 释放各路输出流
    await this.mCameraService?.releasePhotoOutput();
    await this.mCameraService?.releaseVideoOutput();
    await this.mCameraService?.releaseMetadataOutput();
    await this.mCameraService?.closeInput(); // close输入流
    await this.mCameraService?.releaseSession(); // 释放session
    HiLog.end(TAG, 'recoveryWorkerThread');
  }

  private async initCamera(cameraInputMessage: CameraInputMessage, context, pickerInfo?: PickerInfo): Promise<void> {
    HiLog.begin(TAG, 'initCamera');
    this.mCameraService.initCameraManager(context, pickerInfo);
    await this.mCameraService.createCameraInput(cameraInputMessage);
    HiLog.end(TAG, 'initCamera');
  }

  private async initCameraList(): Promise<void> {
    HiLog.begin(TAG, 'initCameraList');
    this.mCameraService.initCameraList();
    HiLog.end(TAG, 'initCameraList');
  }

  private async startupCamera(message: SessionMessage): Promise<SessionInfo> {
    HiLog.begin(TAG, 'startupCamera');
    this.mCameraService.setSessionMessage(message);
    const mode: ModeType = message.tagMessage.mode;
    let photoProfile: camera.Profile = message.photoOutputMessage.photoProfile;

    let isCanReuseCameraInput: boolean = this.mCameraService.isCanReuseCameraInput(message);
    HiLog.i(TAG, 'startupCamera isCanReuseCameraInput: ' + isCanReuseCameraInput);
    await this.mCameraService.stopOutput();
    let executor: TaskExecutor = new TaskExecutor();
    if (!isCanReuseCameraInput) {
      HiLog.i(TAG, 'startupCamera closeInput.');
      await this.mCameraService.closeInput();
      this.mCameraService.initCameraManager(message.tagMessage.messageContext, message.tagMessage.pickerInfo);
      await this.mCameraService.createCameraInput(message.cameraInputMessage);
      if (!GlobalContext.get().getObject('cameraOpenSuccess')) {
        HiLog.e(TAG, 'cameraOpenFailed');
        return undefined;
      }
    } else {
      if (this.mCameraService.hasSession()) {
        this.mCameraService.removeInput();
      }
    }
    await this.mCameraService.stopSession();
    await this.mCameraService.releaseSession();
    executor.addTask(this.mCameraService.createPreviewOutput(message.previewOutputMessage));
    if (message.collaborateControlPreviewOutputMessage?.previewProfile) {
      this.addCollaborateControlPreviewOutput(executor, message); // 遥控场景按需新增创建远端预览流
    }
    if (message.metadataOutputMessage.metadataObjectTypeArr) {
      executor.addTask(this.mCameraService.createMetadataOutput(message));
    }
    HiLog.i(TAG,
      `mCameraService isPanVideoOutput:${OutputOperation.isPanVideoOutput(mode, message.tagMessage.outputType)}`);
    if (OutputOperation.isPanVideoOutput(mode, message.tagMessage.outputType)) {
      HiLog.i(TAG, 'mCameraService createVideoOutput');
      executor.addTask(this.mCameraService.createVideoOutput(message.videoOutputMessage, message.tagMessage));
    }
    if (!!photoProfile) {
      executor.addTaskFunction(async () => {
        await this.mCameraService.releasePhotoOutput();
        await this.mCameraService.createPhotoOutput(photoProfile, message.tagMessage.savePhotoFormat, false);
      })
    }
    await executor.executeTasks();
    HiLog.i(TAG, 'startupCamera cameraType:' + message.cameraInputMessage.cameraType);
    await this.changeFormat(!!photoProfile, message);
    const sessionInfo: SessionInfo = await this.mCameraService.commitSession(message.tagMessage,
      message?.videoOutputMessage);
    workerCallback.setCameraCloseFlag(false);
    HiLog.end(TAG, 'startupCamera');
    setTimeout(() => {
      this.mCameraService.afterStartupInit();
    }, START_UP_INIT);
    return sessionInfo;
  }

  private addCollaborateControlPreviewOutput(executor: TaskExecutor, message: SessionMessage): void {
    if (message.collaborateControlPreviewOutputMessage?.previewProfile) {
      executor.addTask(this.mCameraService.createCollaborateControlPreviewOut(message.collaborateControlPreviewOutputMessage));
    }
  }


  private async addDeferredSurface(surfaceId: string, minSurfaceId: string): Promise<boolean> {
    if (!this.mCameraService.hasSession()) {
      HiLog.w(TAG, 'addDeferredSurface interrupted:no session.');
      return false;
    }
    if (this.mCameraService.hasPreviewSurface()) {
      HiLog.w(TAG, 'addDeferredSurface interrupted:not latest surface.');
      try {
        await this.closeCamera();
      } catch (err) {
        HiLog.e(TAG, `addDefferedSurface err: ${err}.`);
      }
      return false;
    }
    this.mCameraService.addDeferredSurface(surfaceId);
    this.addMixDeferredSurface(minSurfaceId);
    await this.mCameraService.afterStartupInit();
    return true;
  }

  private async swapDeferredSurface(surfaceId: string): Promise<boolean> {
    if (!this.mCameraService.hasSession()) {
      HiLog.w(TAG, 'swapDeferredSurface interrupted:no session.');
      return false;
    }
    this.mCameraService.swapDeferredSurface(surfaceId);
    return true;
  }

  private async addMixDeferredSurface(mixSurfaceId: string): Promise<void> {
    if (mixSurfaceId === undefined) {
      return;
    }
    this.mCameraService.addMixDeferredSurface(mixSurfaceId);
    return;
  }

  private async startPreview(message: SessionMessage): Promise<SessionInfo> {
    HiLog.begin(TAG, 'startPreview');
    this.mCameraService.setSessionMessage(message);
    if (!this.mCameraService.checkCameraMangerStatus()) {
      HiLog.w(TAG, 'reset cameraManger');
      this.mCameraService.initCameraManager(message.tagMessage.messageContext, message.tagMessage.pickerInfo);
    }
    const mode: ModeType = message.tagMessage.mode;
    let photoProfile: camera.Profile = message.photoOutputMessage.photoProfile;
    await this.mCameraService.stopOutput();
    await this.mCameraService.releaseOutput();
    const executor: TaskExecutor = new TaskExecutor();
    if (!DeviceInfo.isPc()) { //切换场景已close故需创建,兼容(PC冷启动场景)不走延时配流走create故无需创建
      if (this.mCameraService.hasSession()) {
        this.mCameraService.removeInput();
      }
    }
    await this.mCameraService.stopSession();
    await this.mCameraService.releaseSession();
    executor.addTask(this.mCameraService.createPreviewOutput(message.previewOutputMessage));
    if (message.collaborateControlPreviewOutputMessage?.previewProfile) {
      this.addCollaborateControlPreviewOutput(executor, message); // 遥控场景按需新增创建远端预览流
    }
    HiLog.d(TAG, 'metadataObjectTypeArr.');
    if (message.metadataOutputMessage.metadataObjectTypeArr) {
      executor.addTask(this.mCameraService.createMetadataOutput(message));
    }
    if (OutputOperation.isPanVideoOutput(mode, message.tagMessage.outputType)) {
      executor.addTask(this.mCameraService.createVideoOutput(message.videoOutputMessage, message.tagMessage));
    }
    // 与 restartPreview 一致：releaseOutput 后必须重建 photoOutput，否则 commitSession 时 mPhotoOutput 为空
    // （跳过 INITIALIZED 态 CHANGE_MODE 时仅走本路径，此前依赖 restartPreview 隐式创建）
    this.createPhotoOutputWhenRestartPreview(executor, message, photoProfile);
    await executor.executeTasks();

    await this.changeFormat(!!photoProfile, message);
    const sessionMessage: SessionInfo = await this.mCameraService.commitSession(message.tagMessage,
      message?.videoOutputMessage);
    HiLog.end(TAG, 'startPreview');
    setTimeout(() => {
      this.mCameraService.afterStartupInit();
    }, START_UP_INIT);
    return sessionMessage;
  }

  private async restartPreview(
    message: SessionMessage, restartType: RestartPreviewType, tricollapsStatusChange?: boolean): Promise<SessionInfo> {
    this.mCameraService.setSessionMessage(message);
    if (message?.videoOutputMessage?.keepVideoFlowing) {
      return await this.restartContinuumPreview(message, restartType);
    }
    HiLog.begin(TAG, 'restartPreview');
    if (!this.mCameraService.checkCameraMangerStatus()) {
      HiLog.w(TAG, 'reset cameraManger');
      this.mCameraService.initCameraManager(message.tagMessage.messageContext, message.tagMessage.pickerInfo);
    }
    const mode: ModeType = message.tagMessage.mode;
    const outputType: OutputType | undefined = message.tagMessage.outputType;
    let photoProfile: camera.Profile = message.photoOutputMessage.photoProfile;
    const isPanVideoOutput = OutputOperation.isPanVideoOutput(mode, outputType);
    await this.mCameraService.enterOfflinePhoto(restartType?.toString());
    // 切换模式等流复用不关input，先remove之后add，切换镜头不复用输入流先close之后创建新输入流
    let canReUseInput = this.canReUseInput(restartType, message.cameraInputMessage.cameraType, false);
    HiLog.i(TAG, `release camera canReUseInput: ${canReUseInput}, restartType: ${restartType}`);
    if (!canReUseInput) {
      await this.mCameraService.preSwitchCamera(message.cameraInputMessage);
    }
    await this.mCameraService.stopOutput();
    const executor: TaskExecutor = new TaskExecutor();
    // 处理input
    executor.addTaskFunction(async () => {
      if (canReUseInput) {
        await this.mCameraService.removeInput();
      }
      HiLog.begin(TAG, 'releaseSession');
      await this.mCameraService.stopSession();
      await this.mCameraService.releaseSession(); // 释放session
      HiLog.end(TAG, 'releaseSession');
      if (!canReUseInput) {
        await this.mCameraService.createCameraInput(message.cameraInputMessage);
      }
    });
    executor.addTaskFunction(async () => {
      await this.mCameraService.releaseVideoOutput();
      if (isPanVideoOutput) {
        await this.mCameraService.createVideoOutput(message.videoOutputMessage, message.tagMessage);
      }
    });
    executor.addTaskFunction(async () => {
      await this.mCameraService.releaseMetadataOutput();
      if (message.metadataOutputMessage.metadataObjectTypeArr) {
        await this.mCameraService.createMetadataOutput(message);
      }
    });
    executor.addTask(this.mCameraService.createPreviewOutput(message.previewOutputMessage));
    if (message.collaborateControlPreviewOutputMessage?.previewProfile) {
      this.addCollaborateControlPreviewOutput(executor, message); // 遥控场景按需新增创建远端预览流
    }
    this.createPhotoOutputWhenRestartPreview(executor, message, photoProfile);
    await executor.executeTasks();
    if (!GlobalContext.get().getObject('cameraOpenSuccess')) {
      this.mCameraService.releaseOutput();
      HiLog.e(TAG, 'restart failed,camera open status error.');
      return undefined;
    }
    HiLog.i(TAG, 'restart executor task end,change format.');
    await this.changeFormat(!!photoProfile, message);
    const sessionMessage: SessionInfo = await this.mCameraService.commitSession(message.tagMessage,
      message?.videoOutputMessage);
    await this.mCameraService.resolveAVRecorder(isPanVideoOutput);
    HiLog.end(TAG, 'restartPreview');
    return sessionMessage;
  }

  private async restartContinuumPreview(message: SessionMessage,
    restartType: RestartPreviewType): Promise<SessionInfo> {
    HiLog.begin(TAG, 'restartContinuumPreview' + JSON.stringify(message));
    const canReUseInput = this.canReUseInput(restartType, message.cameraInputMessage.cameraType);
    const mode: ModeType = message.tagMessage.mode;
    const outputType: OutputType | undefined = message.tagMessage.outputType;
    let photoProfile: camera.Profile = message.photoOutputMessage.photoProfile;
    const isPanVideoOutput = OutputOperation.isPanVideoOutput(mode, outputType);
    await this.mCameraService.enterOfflinePhoto(restartType?.toString());
    HiLog.i(TAG, `release camera canReUseInput: ${canReUseInput}, restartType: ${restartType}`);

    const executor: TaskExecutor = new TaskExecutor();
    executor.addTaskFunction(async () => {
      if (canReUseInput) {
        await this.mCameraService.removeInput();
      }
      HiLog.begin(TAG, 'releaseSession');
      await this.mCameraService.stopSession();
      await this.mCameraService.releaseSession();
      HiLog.end(TAG, 'releaseSession');
      if (!canReUseInput) {
        await this.mCameraService.createCameraInput(message.cameraInputMessage);
      }
    });
    executor.addTaskFunction(async () => {
      await this.mCameraService.releaseMetadataOutput();
      if (message.metadataOutputMessage.metadataObjectTypeArr) {
        await this.mCameraService.createMetadataOutput(message);
      }
      await this.mCameraService.releaseVideoOutput();
      HiLog.d(TAG, 'restartContinuumPreview releaseVideoOutput');
      if (isPanVideoOutput) {
        await this.mCameraService.createVideoOutput(message.videoOutputMessage, message.tagMessage);
      }
    });
    executor.addTask(this.mCameraService.createPreviewOutput(message.previewOutputMessage));
    if (message.collaborateControlPreviewOutputMessage?.previewProfile) {
      this.addCollaborateControlPreviewOutput(executor, message); // 遥控场景按需新增创建远端预览流
    }
    HiLog.d(TAG, 'createPhotoOutputWhenRestartPreview');
    this.createPhotoOutputWhenRestartPreview(executor, message, photoProfile);

    await executor.executeTasks();
    HiLog.d(TAG, 'restartContinuumPreview executeTasks');

    await this.changeFormat(!!photoProfile, message);
    const sessionMessage: SessionInfo = await this.mCameraService.commitSession(message.tagMessage,
      message?.videoOutputMessage);
    HiLog.d(TAG, 'restartContinuumPreview preferencesMirror: ' + message.videoOutputMessage.preferencesMirror +
      ' videoOutputMessage.mirrorValue: ' + message.videoOutputMessage.mirrorValue);
    HiLog.end(TAG, 'restartContinuumPreview' + JSON.stringify(sessionMessage));
    return sessionMessage;
  }

  private async changeFormat(hasPhotoProfile: boolean, message: SessionMessage): Promise<void> {
    HiLog.begin(TAG, 'changeFormat');
    // 先创建会话和添加输入流，再查询色彩空间能力，根据色彩空间设置对应output format
    await this.mCameraService.createSession(hasPhotoProfile, message.tagMessage);

    await this.mCameraService.setAndAddSessionInput(message.tagMessage);
    let colorSpaceArr: colorSpaceManager.ColorSpace[] = [];
    colorSpaceArr = this.mCameraService.getSupportedColorSpaces();
    const isSupportHighColorSpace = colorSpaceArr.indexOf(colorSpaceManager.ColorSpace.BT2020_HLG) >= 0;
    HiLog.i(TAG, `isSupportHighColorSpace ${isSupportHighColorSpace}, colorSpaceArr ${colorSpaceArr.toString()}`);
    HiLog.i(TAG,
      `isPanVideoOutput ${OutputOperation.isPanVideoOutput(message.tagMessage.mode, message.tagMessage.outputType)},
     mode: ${message.tagMessage.mode}`);
    workerCallback.updateHdrSupport(false);
    HiLog.i(TAG, `format ${message.previewOutputMessage.previewProfile.format}`);
    HiLog.end(TAG, 'changeFormat');
  }

  private createPhotoOutputWhenRestartPreview(executor: TaskExecutor, message: SessionMessage,
    photoProfile: camera.Profile): void {
    executor.addTaskFunction(async () => {
      await this.mCameraService.releasePhotoOutput();
      if (!!photoProfile) {
        await this.mCameraService.createPhotoOutput(photoProfile, message.tagMessage.savePhotoFormat,
          message.tagMessage.isProRawDelivery);
      }
    });
  }

  private async switchCollaborate(previewMessage: PreviewOutputMessage, tagMessage: TagMessage): Promise<void> {
    await this.mCameraService.switchCollaborate(previewMessage, tagMessage);
  }

  private async switchWatchCollaborateControl(previewMessage: PreviewOutputMessage,
    tagMessage: TagMessage): Promise<void> {
    await this.mCameraService.switchWatchCollaborateControl(previewMessage, tagMessage);
  }

  private setZoomRatio(zoomRatio: number): void {
    this.mCameraService.setZoomRatio(zoomRatio);
  }


  private async closeCamera(closeInfo?: CloseInfoToWork): Promise<void> {
    let isNeedDelayClose: boolean = closeInfo && closeInfo.isNeedDelayClose; // 恒星&金牛
    let isNeedSaveRestore: boolean = closeInfo && closeInfo.isNeedSaveRestore; // saveRestore
    let isPcEnterSleep: boolean = closeInfo && closeInfo.isPcEnterSleep;
    HiLog.i(TAG, `worker do close with info:${JSON.stringify(closeInfo)}`);
    if (isNeedSaveRestore) {
      this.mCameraService.doPreLaunchOperation(closeInfo);
    }
    workerCallback.setCameraCloseFlag(true);
    await this.mCameraService.releaseCamera(isNeedDelayClose);
  }

  private async stopPreviewOutput(): Promise<void> {
    await this.mCameraService.stopPreviewOutput();
  }

  private addPipSurface(pipSurfaceId: string): void {
    this.mCameraService.addPipSurface(pipSurfaceId);
  }

  private capture(cameraSetting: camera.PhotoCaptureSetting, message: CaptureMessage): void {
    this.mCameraService.takePicture(cameraSetting, message);
  }

  private shutterButtonUp(shutterInterval: number): void {
    LeftRightSwipeWorkerCaptureService.getInstance().shutterButtonUp(shutterInterval)
  }

  private setNeedDeleteOnePhoto(thumbnailAnimAvailable: boolean): void {
    LeftRightSwipeWorkerCaptureService.getInstance().needDeleteOnePhoto(thumbnailAnimAvailable);
  }


  private async startRecording(message: VideoOutputMessage, tagMessage: TagMessage): Promise<StartRecordResultType> {
    const recordResult: StartRecordResultType = await this.mCameraService.startRecording(message, tagMessage);
    HiLog.i(TAG, `RECORD_TRACK startRecording end: ${simpleStringify(recordResult)}.`);
    return recordResult;
  }

  private async startRecorderRecording(message: PreviewRecordOutputMessage,
    isSupportRealTimeFilter: boolean): Promise<StartRecordResultType> {
    const recordResult: StartRecordResultType =
      await this.mCameraService.startRecorderRecording(message, isSupportRealTimeFilter);
    return recordResult;
  }

  private refreshPickerInfo(pickerInfo: PickerInfo): void {
    this.mCameraService.refreshPickerInfo(pickerInfo);
  }


  private isDepthFusionConfigured(isConfigured: boolean): void {
    this.mCameraService.getIsDepthFusionConfigured(isConfigured);
  }

  private async pauseRecording(): Promise<void> {
    await this.mCameraService.pauseRecording();
  }

  private async pauseRecorderRecording(isSupportRealTimeFilter: boolean): Promise<void> {
    await this.mCameraService.pauseRecorderRecording(isSupportRealTimeFilter);
  }

  private async resumeRecording(): Promise<void> {
    await this.mCameraService.resumeRecording();
  }

  private async resumeRecorderRecording(isSupportRealTimeFilter: boolean): Promise<void> {
    await this.mCameraService.resumeRecorderRecording(isSupportRealTimeFilter);
  }

  private async stopRecording(validateThumbnail: boolean): Promise<void> {
    await this.mCameraService.stopRecording(validateThumbnail);
  }

  private async deletePickerVideoFile(): Promise<void> {
    await this.mCameraService.deletePickerVideoFile();
  }

  private resetVideoFileManagerUri(): void {
    this.mCameraService.resetVideoFileManagerUri();
  }

  private async stopRecorderRecording(isSupportRealTimeFilter: boolean, validateThumbnail: boolean): Promise<void> {
    await this.mCameraService.stopRecorderRecording(isSupportRealTimeFilter, validateThumbnail);
  }

  private async startTimelapseRecording(message: TimeLapseRecordOutputMessage,
    isSupportRealTimeFilter: boolean): Promise<StartRecordResultType> {
    const recordResult: StartRecordResultType =
      await this.mCameraService.startTimelapseRecording(message, isSupportRealTimeFilter);
    return recordResult;
  }

  private async stopTimelapseRecording(isSupportRealTimeFilter: boolean, validateThumbnail: boolean): Promise<void> {
    await this.mCameraService.stopTimelapseRecording(isSupportRealTimeFilter, validateThumbnail);
  }

  private setFlashMode(flashMode): void {
    this.mCameraService.setFlashMode(flashMode);
  }

  // @ts-ignore
  private setStitchingMode(stitchingType: camera.StitchingType): void {
    this.mCameraService.setStitchingType(stitchingType);
  }

  // @ts-ignore
  private setStitchingDirection(stitchingDirection: camera.StitchingDirection): void {
    this.mCameraService.setStitchingDirection(stitchingDirection);
  }

  private setStitchingMove(stitchingMove: boolean): void {
    this.mCameraService.setStitchingMove(stitchingMove);
  }

  private isFocusModeSupported(focusMode: camera.FocusMode): boolean {
    return this.mCameraService.isFocusModeSupported(focusMode);
  }

  private setFocus(data: FocusData): void {
    this.mCameraService.setFocus(data.focusMode, data.focusPoint, data.focusValue === undefined ? 0 : data.focusValue);
  }

  private setExposure(data: ExposureData): void {
    this.mCameraService.setExposure(data);
  }

  private setMeteringPoint(data: camera.Point): void {
    this.mCameraService.setMeteringPoint(data);
  }

  private setXmage(value: number): void {
    this.mCameraService.setXmage(value);
  }

  public setVideoStabilization(value: camera.VideoStabilizationMode): void {
    this.mCameraService.setVideoStabilization(value);
  }

  private setExposureValue(value: number): void {
    this.mCameraService.setExposureValue(value);
  }

  public confirmCapture(): void {
    this.mCameraService.confirmCapture();
  }

  public async handleZoomVibrator(effectId: string, usage: string): Promise<void> {
    const vibratorService = await modulesManager.getVibratorService();
    vibratorService.handleZoomVibrator(effectId, usage);
  }

  public async stopZoomVibrator(): Promise<void> {
    const vibratorService = await modulesManager.getVibratorService();
    vibratorService.stopVibrator();
  }

  private setPortraitEffect(value: number): void {
    this.mCameraService.setPortraitEffect(value);
  }

  private setCameraShotKey(cameraShotKey: string, currentMode: ModeType, recordingState: RecordingState): void {
    GlobalContext.get().setCameraShotKey(cameraShotKey);
    this.mCameraService.setCameraShotKey(cameraShotKey, currentMode, recordingState);
  }


  private triggerLighting(): void {
    this.mCameraService.triggerLighting();
  }

  private startFaceMetadata(): void {
    this.mCameraService.startMetadataOutput();
  }

  private stopMetadataOutput(): void {
    this.mCameraService.stopMetadataOutput();
  }

  private enableMacro(enable: boolean): void {
    this.mCameraService.enableMacro(enable);
  }

  private async startSession(tagMessage: TagMessage): Promise<void> {
    await this.mCameraService.startSession(tagMessage);
  }

  private async stopSession(): Promise<void> {
    await this.mCameraService.stopSession();
  }

  private async savePickerFileInWorker(): Promise<PickerSaveResolveType> {
    HiLog.begin(TAG, 'savePickerFileInWorker');
    const pickerWorkerService = await modulesManager.getPickerFileWorkerService();
    const uriInfo: PickerSaveResolveType = await pickerWorkerService.savePickerFileInWorker();
    HiLog.end(TAG, 'savePickerFileInWorker');
    return uriInfo;
  }

  public setSmoothZoom(targetRatio: number): void {
    this.mCameraService.setSmoothZoom(targetRatio);
  }

  private prepareOrUnprepareZoom(isPrepare: boolean): void {
    this.mCameraService.prepareOrUnprepareZoom(isPrepare);
  }

  private enableSceneFeature(scene: camera.SceneFeatureType, enabled: boolean): void {
    this.mCameraService.enableSceneFeature(scene, enabled);
  }

  private setVirtualAperture(aperture: number): void {
    this.mCameraService.setVirtualAperture(aperture);
  }

  private setPhysicalAperture(aperture: number): void {
    return this.mCameraService.setPhysicalAperture(aperture);
  }

  private setMeteringMode(value: number): void {
    this.mCameraService.setMeteringValue(value);
  }

  private setIsoValue(value: number): void {
    this.mCameraService.setIsoValue(value);
  }

  private setApertureValue(value: number): void {
    this.mCameraService.setApertureValue(value);
  }

  private setAuxiliary(value: number): void {
    this.mCameraService.setAuxiliary(value);
  }

  public setSlowMotionDetectionArea(posData: camera.Rect): void {
    return this.mCameraService.setSlowMotionDetectionArea(posData);
  }

  private setLivePhoto(value: boolean): void {
    this.mCameraService.setLivePhoto(value);
  }

  private getFocusDistance(): number {
    return this.mCameraService.getFocusDistance();
  }

  public getIsoRange(): number[] {
    return this.mCameraService.getIsoRange();
  }


  private setDirection(data: {
    direction: number,
    rotate: number,
    settingAngle: number
  }): void {
    this.mCameraService.setDisplayRotate(data.rotate % ANGLE_360);
  }

  private setTimeLapseInterval(interval: number): void {
    HiLog.e(TAG, 'interval: ' + interval);
    this.mCameraService.setTimeLapseInterval(interval);
  }

  public getTimeLapseInterval(): number {
    return this.mCameraService.getTimeLapseInterval();
  }

  public async panoramaMaxPreviewOutputStart(): Promise<void> {
    await this.mCameraService.panoramaMaxPreviewOutputStart();
  }

  public async panoramaMinPreviewOutputStart(): Promise<void> {
    await this.mCameraService.panoramaMinPreviewOutputStart();
  }

  public async panoramaMaxPreviewOutputStop(): Promise<void> {
    await this.mCameraService.panoramaMaxPreviewOutputStop();
  }

  public async panoramaMinPreviewOutputStop(): Promise<void> {
    await this.mCameraService.panoramaMinPreviewOutputStop();
  }

  private canReUseInput(restartType: RestartPreviewType, cameraType: camera.CameraType,
    tricollapsStatusChange?: boolean): boolean {
    const restartReady = restartType === RestartPreviewType.CHANGE_MODE ||
      restartType === RestartPreviewType.CHANGE_ASPECT_RATIO;
    const cameraReady =
      this.mCameraService.getCameraInputType() === cameraType && cameraType === camera.CameraType.CAMERA_TYPE_DEFAULT;
    HiLog.i(TAG, `restartType: ${restartType}, ready: ${restartReady}, cameraType: ${cameraType}, ready: ${
    cameraReady}, getCameraInputType: ${this.mCameraService.getCameraInputType()}`);
    return restartReady && cameraReady && !tricollapsStatusChange;
  }

  private changeLocation(message: LocationMessage): void {
    if (!message) {
      return;
    }
    HiLog.i(TAG, `changeLocation message: ${message.type}.`);
    LOCATION_MESSAGE.type = message.type;
    LOCATION_MESSAGE.location = message.location;
  }

  private setMirror(value: boolean): void {
    this.mCameraService.setMirror(value);
  }

  private setAutoFrameRate(value: boolean): void {
    this.mCameraService.setAutoFrameRate(value);
  }

  // @ts-ignore
  public setCustomColorStyleSetting(setting: camera.ColorStyleSetting): void {
    return this.mCameraService.setColorStyleSetting(setting);
  }

  private setOperationEmotion(value: boolean): void {
    this.mCameraService.setOperationEmotion(value);
  }

  private setSwingSubscribeStatus(value: boolean): void {
    this.mCameraService.setSwingSubscribeStatus(value);
  }

  private resetWorkerPhotoCount(): void {
  }

  private setAudioZoomExtra(value: Record<string, string>): void {
    this.mCameraService.setAudioZoomExtra(value);
  }

  private async setShortVideoIndex(index: number): Promise<void> {
    HiLog.i(TAG, 'vlog index' + index);
    this.mCameraService.setShortVideoIndex(index);
    if (index === -1) {
      return;
    }
    switch (index) {
      case VlogTool.NEAR_FOCUS:
        this.startFaceMetadata();
        break;
      case VlogTool.PORTRAIT_FOCUS:
      case VlogTool.PORTRAIT_BLUR:
      case VlogTool.AI_COLOR:
        this.stopMetadataOutput();
        break;
      default:
        this.startFaceMetadata();
    }
  }

  private setWindNoiseSuppression(value: Record<string, string>): void {
    this.mCameraService.setWindNoiseSuppression(value);
  }

  private onKeepUsingStellarLenses(): void {
    HiLog.i(TAG, 'onKeepUsingStellarLenses');
    if (this.mCameraService) {
      HiLog.i(TAG, 'onKeepUsingStellarLenses keepUsingStellarLenses');
      this.mCameraService.keepUsingStellarLenses();
    }
  }

  private scanCodeClose(): void {
  }

  private enableAIComposition(enable: boolean): void {
    this.mCameraService.enableAIComposition(enable);
  }

  private enableLogAssistance(enable: boolean): void {
    this.mCameraService.enableLogAssistance(enable);
  }

  private onChangeCollaborationPreviewOutput(isMirrorSelfiePreviewItem: boolean): void {
    HiLog.i(TAG, 'onChangeCollaborationPreviewOutput');
    this.mCameraService.changeCollaborationPreviewOutput(isMirrorSelfiePreviewItem);
  }

  private changeConstellationStatus(isOpen: boolean): void {
    if (isOpen) {
      this.mCameraService.setLocation(LOCATION_MESSAGE.location);
    }
    this.mCameraService.changeConstellationStatus(isOpen);
  }

  private setFocusTrackingMode(mode: camera.FocusTrackingMode): void {
    this.mCameraService.setFocusTrackingMode(mode);
  }

  private setFilterType(filterTYpe: number): void {
    this.mCameraService.setFilterType(filterTYpe);
  }

  private setUltraPhoto(value: boolean): void {
    this.mCameraService.setUltraPhoto(value);
  }
}