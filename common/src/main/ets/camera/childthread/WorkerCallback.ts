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

import type { camera } from '@kit.CameraKit';
import type { image } from '@kit.ImageKit';
import lazy { worker } from '@kit.ArkTS';
import lazy { WorkerTask } from '../WorkerTask';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { CameraErrorCode } from './modules/CameraInputWrap';
import lazy { photoAccessHelper } from '@kit.MediaLibraryKit';
import lazy { ModeType } from '../../mode/ModeType';

export interface WorkerCallback {
  photoSaved(uri: string): void

  bufferReceivedTimelapse(): void

  quickThumbnailPrepare(uri: string): void

  nextCapture(isDeferPhoto: boolean): void

  onCaptureAborted(): void

  onFrameShutterEnd(): void

  videoUri(uri: string): void

  collaborationFd(fd: number, path: string): void

  faceMetadataArr(boundingBoxArr: camera.Rect[]): void

  smartBackSelfieFaceMetadataArr(boundingBoxArr: camera.MetadataObject[]): void

  estimatedCaptureDuration(duration: number): void

  quickThumbnail(thumbnail: image.PixelMap, isDeferEnabled: boolean): void

  captureIdQuickThumbnail(captureId: string, thumbnail: image.PixelMap): void

  captureIdPhotoAsset(captureId: string, photoAsset: photoAccessHelper.PhotoAsset): void

  onRecordError(errorCode: number, errorMsg: string): void

  onCameraError(errorCode: CameraErrorCode, errorMsg: string): void

  onCameraStatus(cameraStatus: number): void

  onPreviewFrameStart(firstFrameTime: number): void

  onDepthFusionZoomThreshold(threshold: number[]): void

  onCollaboratePreviewFrameStart(): void

  onCollaborateControlPreviewFrameStart(): void

  onCollaborateControlPreviewFrameEnd(): void

  onCollaborateControlPreviewFrameError(): void

  onStartCameraDuration(): void

  onStartCameraPositionAndMode(cameraPosition: camera.CameraPosition, mode: ModeType): void

  onTimeLapseTryAeDone(captureInterval: number): void

  onCameraDestroySessionTimeout(duration: number): void

  pcPickerReceived(pcPickerPhotoMap: Map<string, image.PixelMap>): void

  onPickerPhotoReceived(photo: image.PixelMap): void

  onCloseCameraTimeout(duration: number): void

  onSavePictureFailed(pictureName: string, storagePath: string, pictureType: number, failReason: string): void

  onVideoRecordingStatus(mem: string): void

  onSaveVideoFail(failReason: string): void

 onSketchStatusChanged(status: number, sketchRatio: number, centerPointOffset?: camera.Point): void

  onNightCaptureStart(exposureTime: number): void

  onCaptureEnd(): void

  onNightFrameShutter(): void

  // @ts-ignore
  onNightSubModeTypes(mNightSubMode: camera.NightSubModeType[]): void

  // @ts-ignore
  onImageStabilizationGuide(imageStabilizationGuideInfo: camera.ImageStabilizationGuideInfo): void

  onConstellationMatchingState(state: number): void

  onNormalFrameShutter(): void

  onFirstBurstAvailable(thumbnail: image.PixelMap): void

  onPhotoProcessed(isPhotoSaved: boolean, thumbnailAnimAvailable: boolean): void

  onBurstPhotoTook(captureId: number): void

  onBurstFinishReset(): void

  onDeferPhotoReport(uri: string): void

  onDeferPhotoMediaUri(uri: string): void

  onUpdateValidFrameFlag(flag: boolean): void

  onSceneFeatureDetectionResult(detectionResult: camera.TripodDetectionResult): void

  onUpdateExposureRecoveryFlag(info: number): void

  onUpdateIsoDuration(duration: number): void

  onUpdatePhysicalApertureDuration(duration: number): void

  onUpdateExposureDuration(duration: number): void

  onAbilityChange(isoRange: number[], ApertureRange: camera.PhysicalAperture[]): void

  onSuperMotionStatus(motionState: number): void

  onSlowMotionZoomRange(slowZoomRange: number[]): void

  onSlowMotionPreviewChange(isPreviewStart: boolean): void

  onLcdFlashCompensate(lcdFlashStatus: camera.LcdFlashStatus): void

  preemptWithError(): void

  onLensBlocking(isCameraOccluded: boolean): void

  onLensDirty(isCameraLensDirty: boolean): void;

  onLosePhoto(count: number): void;

  enterOfflinePhoto(type: string, count: number): void;

  onOfflinePhotoReceive(duration: number, offlineCount: number): void;

  onOfflinePhotoFinish(isFinish: boolean, loseCount: number, duration: number): void;

  updateOfflineSupport(isSupport: boolean): void;

  openCameraFailed(failReason: string): void;

  burstStartFailed(): void;

  recoveryRestartApp(): void

  superPrivacyModeEnabled(isEnable: boolean): void

  eyeMetadata(boundingBoxArr: camera.Rect[]): void;

  faceMetadataSimle(isSmile: boolean): void;

  addPhotoCount(): void;

  minusPhotoCount(): void;

  resetPhotoCount(): void;

  updateOfflineCaptureArray(captureIdList: number[], isEnterOffline: boolean, burstOfflineCount: number): void;

  onDeferPhotoSaveEnd(captureId: number, isBurstCapture: boolean): void;

  resetBurstOfflineCount(): void;

  setCameraCloseFlag(flag: boolean): void;

  updateHdrSupport(isOpen: boolean): void;

  receivedPreRecordDurationTime(time: number): void;

  onUpdateStartPreviewTime(time: number): void;

  setAddsurfaceTime(time: number): void;

  picker2ReleaseCameraFromMainThread(): void;

  // @ts-ignore
  onUpdateStitchingTarget(targetInfo: camera.StitchingTargetInfo);

  // @ts-ignore
  onUpdateStitchingCaptureStatus(captureStatus: camera.StitchingCaptureState);

  onUpdatePreviewStitching(previewStitching: image.PixelMap);

  // @ts-ignore
  showStitchingHint(stitchingHint: camera.StitchingHint);

  onRecvAICompositionBeginNotice();

  // @ts-ignore
  onRecvAICompositionCalibrationData(calibrationData: camera.CompositionCalibrationInfo);

  // @ts-ignore
  onRecvAICompositionConfigData(configData: camera.CompositionConfigInfo);

  // @ts-ignore
  onRecvAICompositionEndData(endData: camera.CompositionEndInfo);

  onRecvLightStatusData(lightStatus: camera.LightStatus);

  onRecordPaused(): void;

  updateFocusState(state: camera.FocusState): void;

  // @ts-ignore
  updateFocusTrackingInfo(info: camera.FocusTrackingMetaInfo): void

  // @ts-ignore
  apertureEffectChange(effect: camera.ApertureEffect): void

  saveMovieInfoAssetDone(during: number): void;

  videoStateChange(type: string): void;

  onVideoFrameEnd(): void;
};

const TAG: string = 'WorkerCallback';
const workerPort = worker.workerPort;

export const workerCallback: WorkerCallback = {
  photoSaved: (uri: string): void => {
    workerPort.postMessage({ type: WorkerTask.ON_PHOTO_SAVED, data: uri, hasResolve: false });
  },
  bufferReceivedTimelapse: (): void => {
    workerPort.postMessage({ type: WorkerTask.ON_BUFFER_RECEIVED_TIMELAPSE, hasResolve: false });
  },
  quickThumbnailPrepare: (uri: string): void => {
    workerPort.postMessage({ type: WorkerTask.ON_THUMBNAIL_FILE_CREATED, data: uri, hasResolve: false });
  },
  onCaptureAborted: (): void => {
    workerPort.postMessage({ type: WorkerTask.ON_CAPTURE_ABORTED, hasResolve: false });
  },
  onFrameShutterEnd: (): void => {
    workerPort.postMessage({ type: WorkerTask.ON_FRAME_SHUTTER_END, hasResolve: false });
  },
  nextCapture: (isDeferPhoto: boolean): void => {
    workerPort.postMessage({ type: WorkerTask.ON_NEXT_CAPTURE, data: isDeferPhoto, hasResolve: false });
  },
  videoUri: (uri: string): void => {
    workerPort.postMessage({ type: WorkerTask.ON_VIDEO_URI, data: uri, hasResolve: false });
  },
  collaborationFd: (fd: number, path: string): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_COLLABORATION_FD,
      data: { sandboxFd: fd, sandboxPath: path },
      hasResolve: false
    });
  },
  faceMetadataArr: (boundingBoxArr: camera.Rect[]): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_FACE_METADATA_OBJECT,
      data: { boundingBoxArr: boundingBoxArr },
      hasResolve: false
    });
  },
  smartBackSelfieFaceMetadataArr: (faceMetaData: camera.MetadataObject[]): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_SMART_BACKSELFIE_FACE_METADATA_OBJECT,
      data: { faceMetaData: faceMetaData },
      hasResolve: false
    });
  },
  faceMetadataSimle: (isSmile: boolean): void => {
    workerPort.postMessage({
      type: WorkerTask.SMILE_CAPTURE,
      data: { isSmile: isSmile },
      hasResolve: false
    });
  },
  eyeMetadata: (boundingBoxArr: camera.Rect[]): void => {
    workerPort.postMessage({
      type: WorkerTask.EYE_FOCUS,
      data: { boundingBoxArr: boundingBoxArr },
      hasResolve: false
    });
  },
  estimatedCaptureDuration: (duration: number): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_ESTIMATED_CAPTURE_DURATION,
      data: { duration: duration },
      hasResolve: false
    });
  },
  quickThumbnail: (thumbnail: image.PixelMap, isDeferEnabled: boolean): void => {
    HiLog.i(TAG, 'SHOT2SEE quickThumbnail worker to ui callback.');
    workerPort.postMessage({
      type: WorkerTask.ON_QUICK_THUMBNAIL,
      data: { thumbnail: thumbnail, isDeferEnabled: isDeferEnabled },
      hasResolve: false
    });
  },
  captureIdQuickThumbnail: (captureId: string, thumbnail: image.PixelMap): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_CAPTURE_ID_QUICK_THUMBNAIL,
      data: { captureId: captureId, thumbnail: thumbnail },
      hasResolve: false
    });
  },
  captureIdPhotoAsset: (captureId: string, photoAsset: photoAccessHelper.PhotoAsset): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_CAPTURE_ID_PHOTO_ASSET,
      data: { captureId: captureId, photoAsset: photoAsset },
      hasResolve: false
    });
  },
  onRecordError: (errorCode: number, errorMsg: string): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_RECORD_ERROR,
      data: { errorCode: errorCode, errorMsg: errorMsg },
      hasResolve: false
    });
  },
  onCameraError: (errorCode: CameraErrorCode, errorMsg: string): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_CAMERA_ERROR,
      data: { errorCode: errorCode as number, errorMsg: errorMsg },
      hasResolve: false
    });
  },
  onCameraStatus: (cameraStatus: number): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_CAMERA_STATUS,
      data: { cameraStatus: cameraStatus },
      hasResolve: false
    });
  },
  onPreviewFrameStart: (firstFrameTime: number): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_PREVIEW_FRAME_START,
      data: { firstFrameTime: firstFrameTime },
      hasResolve: false
    });
  },
  onDepthFusionZoomThreshold: (threshold: number[]): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_DEPTH_FUSION_ZOOM_THRESHOLD,
      data: { threshold: threshold },
      hasResolve: false
    });
  },
  onCollaboratePreviewFrameStart: (): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_COLLABORATE_PREVIEW_FRAME_START,
      data: {},
      hasResolve: false
    });
  },
  onCollaborateControlPreviewFrameStart: (): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_COLLABORATE_CONTROL_PREVIEW_FRAME_START,
      data: {},
      hasResolve: false
    });
  },
  onCollaborateControlPreviewFrameEnd: (): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_COLLABORATE_CONTROL_PREVIEW_FRAME_END,
      data: {},
      hasResolve: false
    });
  },
  onCollaborateControlPreviewFrameError: (): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_COLLABORATE_CONTROL_PREVIEW_FRAME_ERROR,
      data: {},
      hasResolve: false
    });
  },
  onStartCameraPositionAndMode: (cameraPosition: camera.CameraPosition, mode: ModeType): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_START_CAMERA_POSITION_AND_MODE,
      data: { cameraPositionOnStart: cameraPosition, cameraModeOnStart: mode },
      hasResolve: false
    });
  },
  onTimeLapseTryAeDone: (captureInterval: number): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_TIME_LAPSE_TRY_AE_DONE,
      data: { captureInterval },
      hasResolve: false
    });
  },
  onCameraDestroySessionTimeout: (duration: number): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_CAMERA_DESTROY_SESSION_TIMEOUT,
      data: {
        duration: duration,
      },
      hasResolve: false
    });
  },
  pcPickerReceived: (pcPickerPhotoMap: Map<string, image.PixelMap>): void => {
    workerPort.postMessage({
      type: WorkerTask.PC_PICKER_RECEIVED,
      data: {
        pcPickerPhotoMap: pcPickerPhotoMap
      },
      hasResolve: false
    });
  },
  onPickerPhotoReceived: (photo: image.PixelMap): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_PICKER_PHOTO_RECEIVED,
      data: {
        photo: photo
      },
      hasResolve: false
    });
  },
  onCloseCameraTimeout: (duration: number): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_CLOSE_CAMERA_TIMEOUT,
      data: {
        duration: duration,
      },
      hasResolve: false
    });
  },
  onSavePictureFailed: (pictureName: string, storagePath: string, pictureType: number, failReason: string): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_SAVE_PICTURE_FAILED,
      data: {
        pictureName: pictureName,
        storagePath: storagePath,
        pictureType: pictureType,
        failReason: failReason
      },
      hasResolve: false
    });
  },
  onVideoRecordingStatus: (mem: string): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_VIDEO_RECORDING_STATUS,
      data: { mem: mem },
      hasResolve: false
    });
  },
  onSaveVideoFail: (failReason: string): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_SAVE_VIDEO_FAIL,
      data: {
        failReason: failReason
      },
      hasResolve: false
    });
  },
  onNightCaptureStart: (exposureTime: number): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_NIGHT_CAPTURE_START,
      data: { exposureTime: exposureTime },
      hasResolve: false
    });
  },
  onCaptureEnd: (): void => {
    workerPort.postMessage({ type: WorkerTask.ON_NIGHT_CAPTURE_END, data: {}, hasResolve: false });
  },
  onNightFrameShutter: (): void => {
    workerPort.postMessage({ type: WorkerTask.ON_NIGHT_FRAME_SHUTTER, data: {}, hasResolve: false });
  },
  // @ts-ignore
  onNightSubModeTypes: (mNightSubMode: camera.NightSubModeType[]): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_SUPPORTED_NIGHT_SUB_MODE_TYPE,
      data: mNightSubMode,
      hasResolve: false
    });
  },
  // @ts-ignore
  onImageStabilizationGuide: (imageStabilizationGuideInfo: camera.ImageStabilizationGuideInfo): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_NIGHT_IMAGE_STABILIZATION_GUIDE,
      data: imageStabilizationGuideInfo,
      hasResolve: false
    });
  },
  onConstellationMatchingState: (state: number): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_CONSTELLATION_MATCHING_STATE,
      data: state,
      hasResolve: false
    });
  },
  onNormalFrameShutter: (): void => {
    workerPort.postMessage({ type: WorkerTask.ON_NORMAL_FRAME_SHUTTER, data: {}, hasResolve: false });
  },
  onFirstBurstAvailable: (thumbnail: image.PixelMap): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_FIRST_BURST_AVAILABLE, data: { thumbnail: thumbnail }, hasResolve: false
    });
  },
  onPhotoProcessed: (isPhotoSaved: boolean, thumbnailAnimAvailable: boolean): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_PHOTO_PROCESSED, data: {
        isPhotoSaved: isPhotoSaved,
        thumbnailAnimAvailable: thumbnailAnimAvailable
      }, hasResolve: false
    });
  },
  onBurstPhotoTook: (captureId: number): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_BURST_PHOTO_TOOK,
      data: captureId,
      hasResolve: false
    });
  },
  onBurstFinishReset: (): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_BURST_FINISH_RESET,
      data: {},
      hasResolve: false
    });
  },
  onSketchStatusChanged: (status: number, sketchRatio: number, centerPointOffset?: camera.Point): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_SKETCH_STATUS_CHANGED,
      data: { status: status, sketchRatio: sketchRatio, centerPointOffset: centerPointOffset },
      hasResolve: false
    });
  },
  onDeferPhotoReport: (uri: string): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_DEFER_PHOTO_REPORT,
      data: { assetUri: uri },
      hasResolve: false
    });
  },
  onDeferPhotoMediaUri: (uri: string): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_DEFER_PHOTO_MEDIA_URI,
      data: { assetUri: uri },
      hasResolve: false
    });
  },
  onUpdateValidFrameFlag: (flag: boolean): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_UPDATE_VALID_FRAME_FLAG,
      data: flag,
      hasResolve: false
    });
  },
  // @ts-ignore
  onSceneFeatureDetectionResult: (detectionResult: camera.TripodDetectionResult): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_SCENE_FEATURE_DETECTION_RESULT,
      data: { detectionResult },
      hasResolve: false
    });
  },
  onSuperMotionStatus: (motionState: number): void => {
    workerPort.postMessage({ type: WorkerTask.ON_SUPER_MOTION_STATUS, data: motionState, hasResolve: false });
  },
  onSlowMotionZoomRange: (slowZoomRange: number[]): void => {
    workerPort.postMessage({ type: WorkerTask.ON_SLOW_MOTION_ZOOM_RANGE, data: slowZoomRange, hasResolve: false });
  },
  onSlowMotionPreviewChange: (isPreviewStart: boolean): void => {
    workerPort.postMessage({ type: WorkerTask.ON_SLOW_MOTION_PREVIEW_CHANGE, data: isPreviewStart, hasResolve: false });
  },
  onLcdFlashCompensate: (lcdFlashStatus: camera.LcdFlashStatus): void => {
    workerPort.postMessage({ type: WorkerTask.ON_FLASH_STATUS, data: lcdFlashStatus, hasResolve: false });
  },
  onUpdateExposureRecoveryFlag: (info: number): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_UPDATE_EXPOSURE_RECOVERY_FLAG,
      data: { info: info },
      hasResolve: false
    });
  },
  onUpdateIsoDuration: (duration: number) => {
    workerPort.postMessage({
      type: WorkerTask.ON_UPDATE_ISO_DURATION,
      data: { duration: duration },
      hasResolve: false
    });
  },
  onUpdatePhysicalApertureDuration: (duration: number) => {
    workerPort.postMessage({
      type: WorkerTask.ON_UPDATE_PHYSICAL_APERTURE_DURATION,
      data: { duration: duration },
      hasResolve: false
    });
  },
  onUpdateExposureDuration: (duration: number) => {
    workerPort.postMessage({
      type: WorkerTask.ON_UPDATE_EXPOSURE_DURATION,
      data: { duration: duration },
      hasResolve: false
    });
  },
  onAbilityChange: (isoRange: number[], ApertureRange: camera.PhysicalAperture[]) => {
    workerPort.postMessage({
      type: WorkerTask.ON_PROFESSION_ABILITY_CHANGE,
      data: { isoRange: isoRange, ApertureRange: ApertureRange },
      hasResolve: false
    });
  },
  preemptWithError: (): void => {
    workerPort.postMessage({ type: WorkerTask.ON_PREEMPTION, data: {}, hasResolve: false });
  },
  onLensBlocking: (isCameraOccluded: boolean) => {
    workerPort.postMessage({
      type: WorkerTask.ACTION_ON_LENS_BLOCKING,
      data: { isCameraOccluded: isCameraOccluded },
      hasResolve: false
    });
  },
  onLensDirty: (isCameraLensDirty: boolean) => {
    workerPort.postMessage({
      type: WorkerTask.ACTION_ON_LENS_DIRTY,
      data: { isCameraLensDirty: isCameraLensDirty },
      hasResolve: false
    });
  },
  onLosePhoto: (count: number) => {
    workerPort.postMessage({
      type: WorkerTask.REPORT_LOSE_PHOTO,
      data: count,
      hasResolve: false
    });
  },
  enterOfflinePhoto: (type: string, count: number) => {
    workerPort.postMessage({
      type: WorkerTask.REPORT_ENTER_OFFLINE_PHOTO,
      data: { type: type, count: count },
      hasResolve: false
    });
  },
  onOfflinePhotoReceive: (duration: number, offlineCount: number) => {
    workerPort.postMessage({
      type: WorkerTask.REPORT_OFFLINE_PHOTO_RECEIVE,
      data: { duration: duration, offlineCount: offlineCount },
      hasResolve: false
    });
  },
  onOfflinePhotoFinish: (isFinish: boolean, loseCount: number, duration: number) => {
    workerPort.postMessage({
      type: WorkerTask.REPORT_OFFLINE_FINISH,
      data: { isFinish: isFinish, loseCount: loseCount, duration: duration },
      hasResolve: false
    });
  },
  updateOfflineSupport: (isSupport: boolean) => {
    workerPort.postMessage({
      type: WorkerTask.UPDATE_OFFLINE_SUPPORT,
      data: isSupport,
      hasResolve: false
    });
  },
  openCameraFailed: (failReason: string) => {
    workerPort.postMessage({
      type: WorkerTask.OPEN_FAILED,
      data: { failReason: failReason },
      hasResolve: false
    });
  },
  burstStartFailed: () => {
    workerPort.postMessage({
      type: WorkerTask.BURST_START_FAILED,
      data: {},
      hasResolve: false
    });
  },
  recoveryRestartApp: () => {
    workerPort.postMessage({
      type: WorkerTask.ACTION_RECOVERY_RESTART_APP,
      data: {},
      hasResolve: false
    });
  },
  superPrivacyModeEnabled: (isEnable: boolean) => {
    workerPort.postMessage({
      type: WorkerTask.ACTION_SUPER_PRIVACY_MODE_ENABLED,
      data: { isEnable: isEnable },
      hasResolve: false
    });
  },
  addPhotoCount: () => {
    workerPort.postMessage({
      type: WorkerTask.ADD_PHOTO_COUNT,
      data: {},
      hasResolve: false
    });
  },
  minusPhotoCount: () => {
    workerPort.postMessage({
      type: WorkerTask.MINUS_PHOTO_COUNT,
      data: {},
      hasResolve: false
    });
  },
  resetPhotoCount: () => {
    workerPort.postMessage({
      type: WorkerTask.RESET_PHOTO_COUNT,
      data: {},
      hasResolve: false
    });
  },
  updateOfflineCaptureArray: (captureIdList: number[], isEnterOffline: boolean, burstOfflineCount: number) => {
    workerPort.postMessage({
      type: WorkerTask.UPDATE_OFFLINE_CAPTURE_ARRAY,
      data: { captureIdList: captureIdList, isEnterOffline: isEnterOffline, burstOfflineCount: burstOfflineCount },
      hasResolve: false
    });
  },
  onDeferPhotoSaveEnd: (captureId: number, isBurstCapture: boolean) => {
    workerPort.postMessage({
      type: WorkerTask.ON_DEFER_PHOTO_SAVE_END,
      data: { captureId: captureId, isBurstCapture: isBurstCapture },
      hasResolve: false
    });
  },
  resetBurstOfflineCount: () => {
    workerPort.postMessage({
      type: WorkerTask.RESET_BURST_OFFLINE_COUNT,
      data: {},
      hasResolve: false,
    });
  },
  setCameraCloseFlag: (flag: boolean) => {
    workerPort.postMessage({
      type: WorkerTask.SET_CAMERA_CLOSE_FLAG,
      data: flag,
      hasResolve: false
    });
  },
  receivedPreRecordDurationTime: (time: number) => {
    workerPort.postMessage({
      type: WorkerTask.RECEIVED_PRE_RECORD_DURATION_TIME,
      data: time,
      hasResolve: false,
    });
  },
  onUpdateStartPreviewTime: (time: number) => {
    workerPort.postMessage({
      type: WorkerTask.ON_UPDATE_START_PREVIEW_TIME,
      data: time,
      hasResolve: false,
    });
  },
  setAddsurfaceTime: (time: number) => {
    workerPort.postMessage({
      type: WorkerTask.SET_ADDSURFACE_TIME,
      data: time,
      hasResolve: false,
    });
  },
  onRecordPaused: () => {
    workerPort.postMessage({
      type: WorkerTask.ON_RECORD_PAUSED,
      data: {},
      hasResolve: false,
    });
  },
  picker2ReleaseCameraFromMainThread: () => {
    workerPort.postMessage({
      type: WorkerTask.ON_PICKER_RELEASE_FROM_MAIN,
      data: {},
      hasResolve: false,
    });
  },
  //@ts-ignore
  onUpdateStitchingTarget: (targetInfo: camera.StitchingTargetInfo) => {
    workerPort.postMessage({
      type: WorkerTask.ON_STITCHING_TARGET_METADATA,
      data: targetInfo,
      hasResolve: false,
    });
  },

  // @ts-ignore
  onUpdateStitchingCaptureStatus: (captureStatus: camera.StitchingCaptureState) => {
    workerPort.postMessage({
      type: WorkerTask.ON_STITCHING_CAPTURE_STATUS,
      data: captureStatus,
      hasResolve: false,
    });
  },

  onUpdatePreviewStitching: (previewStitching: image.PixelMap) => {
    workerPort.postMessage({
      type: WorkerTask.ON_STITCHING_PREVIEW,
      data: previewStitching,
      hasResolve: false,
    });
  },

  // @ts-ignore
  showStitchingHint: (stitchingHint: camera.StitchingHint) => {
    workerPort.postMessage({
      type: WorkerTask.ON_STITCHING_HINT,
      data: stitchingHint,
      hasResolve: false,
    });
  },

  onRecvAICompositionBeginNotice: (): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_RECV_AI_COMPOSITION_BEGIN_NOTICE,
      data: {},
      hasResolve: false,
    });
  },
  // @ts-ignore
  onRecvAICompositionCalibrationData: (calibrationData: camera.CompositionCalibrationInfo): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_RECV_AI_COMPOSITION_CALIBRATION_DATA,
      data: calibrationData,
      hasResolve: false,
    });
  },
  // @ts-ignore
  onRecvAICompositionConfigData: (configData: camera.CompositionConfigInfo): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_RECV_AI_COMPOSITION_CONFIG_DATA,
      data: configData,
      hasResolve: false,
    });
  },

  // @ts-ignore
  updateFocusTrackingInfo: (info: camera.FocusTrackingMetaInfo): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_UPDATE_FOCUS_TRACKING_INFO,
      data: info,
      hasResolve: false,
    });
  },
  // @ts-ignore
  apertureEffectChange: (effect: camera.ApertureEffect): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_APERTURE_EFFECT_CHANGE,
      data: effect,
      hasResolve: false,
    });
  },
  // @ts-ignore
  onRecvAICompositionEndData: (endData: camera.CompositionEndInfo): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_RECV_AI_COMPOSITION_END_DATA,
      data: endData,
      hasResolve: false,
    });
  },
  // @ts-ignore
  onRecvLightStatusData: (lightStatus: camera.LightStatus): void => {
    workerPort.postMessage({
      type: WorkerTask.ON_LIGHT_STATUS_CHANGE,
      data: lightStatus,
      hasResolve: false
    });
  },

  updateFocusState: (state: camera.FocusState) => {
    workerPort.postMessage({
      type: WorkerTask.UPDATE_FOCUS_STATE,
      data: { focusState: state },
      hasResolve: false,
    });
  },

  updateHdrSupport: (isOpen: boolean) => {
    workerPort.postMessage({
      type: WorkerTask.UPDATE_HDR_SUPPORT,
      data: { isOpen: isOpen },
      hasResolve: false,
    });
  },

  saveMovieInfoAssetDone: (during: number) => {
    workerPort.postMessage({
      type: WorkerTask.SAVE_MOVIE_INFO_ASSET_DONE,
      data: { during: during },
      hasResolve: false,
    });
  },

  videoStateChange: (type: string) => {
    workerPort.postMessage({
      type: WorkerTask.VIDEO_STATE_CHANGE,
      data: type,
      hasResolve: false,
    });
  },

  onVideoFrameEnd: (): void => {
    workerPort.postMessage({ type: WorkerTask.ON_VIDEO_FRAME_END, data: {}, hasResolve: false });
  },
  onStartCameraDuration: function (): void {
    throw new Error('Function not implemented.');
  }
};