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

import worker from '@ohos.worker';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { FREQUENT_HILOG_EVENT, HiLog } from '../../utils/HiLog';
import camera from '@ohos.multimedia.camera';
import type {
  SessionMessage,
  CameraInputMessage,
  TimeLapseRecordOutputMessage,
  RestartPreviewType,
  VideoOutputMessage,
  PreviewRecordOutputMessage,
  PreviewOutputMessage,
  SessionInfo,
  TagMessage,
  CloseInfoToWork,
  TimeLapseRecordMessage
} from '../DataType';
import lazy { ThumbnailAction, ThumbnailUpdateScene } from '../../component/thumbnail/ThumbnailAction';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { Action } from '../../redux/actions/Action';
import lazy { RecordAction, RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { CameraAction, CameraRunningState } from './CameraAction';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import type { EventBus } from '../../worker/eventbus/EventBus';
import type image from '@ohos.multimedia.image';
import lazy { ThumbnailService } from '../../component/thumbnail/ThumbnailService';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { CaptureAction } from '../../function/capture/CaptureAction';
import lazy { ZoomAction } from '../../function/zoombar/ZoomAction';
import lazy { BlurAnimateUtil } from '../../utils/BlurAnimateUtil';
import lazy { CaptureService } from '../../function/capture/CaptureService';
import lazy { SYNC_TASK_TYPES, WorkerTaskManager } from './TaskManager';
import lazy { WorkerTask } from '../WorkerTask';
import lazy { ZoomPointInfo } from '../../function/zoombar/ZoomParam';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { ContextManager } from '../../service/context/ContextManager';
import lazy { simpleStringify } from '../../utils/SimpleStringify';
import lazy { Context } from '@kit.AbilityKit';
import lazy { PickerUiService } from '../../service/picker/PickerUiService';
import type { CaptureMessage } from '../../function/capture/CaptureMessage';
import type { LocationMessage } from '../../service/location/LocationMessage';
import lazy { SuspendTaskUtil } from '../../utils/SuspendTaskUtil';
import lazy { RestartService } from '../../service/restart/RestartService';
import lazy { OutputSwitcher } from '../../function/outputswitcher/OutputSwitcher';
import lazy { JSON } from '@kit.ArkTS';
import lazy {
  PersistType, PreferencesService
} from '../../service/preferences/PreferencesService';
import lazy { PropTag } from '../../service/preferences/PropTag';
import lazy { photoAccessHelper } from '@kit.MediaLibraryKit';
import lazy { getStates } from '../../redux';
import lazy { execAction } from '../../redux/ActionRegistry';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { DatabaseUtils } from '../../utils/DatabaseUtils';
import lazy { FocusExposureActionType } from '../../redux/actions/FocusExposureActionType';
import lazy { ExposureData, FocusData } from '../../component/focusExposure/FocusExposureHelper';
import lazy { CameraAppCapability } from '../CameraAppCapability';
import lazy { window } from '@kit.ArkUI';
import lazy { PickerAction } from '../../service/picker/PickerAction';
import lazy { systemDateTime } from '@kit.BasicServicesKit';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { OutputOperation } from '../../function/outputswitcher/OutputOperation';
import lazy { CollaborateControlAction } from '../../service/collaborateControl/CollaborateControlAction'
import lazy { CollaborateControlService } from '../../service/collaborateControl/CollaborateControlService'

export type Callback = (args: unknown) => void;

export type MessageInfo = {
  hasResolve?: boolean;
  type: string;
  data: unknown;
};

export interface PickerInfo {
  isPicker: boolean,
  uri?: string,
  callingTokenID: number,
  callerPid: number
}

export interface StartRecordResultType {
  sessionMessage: SessionInfo;
  isSuccess: boolean;
}


const TAG: string = 'CameraProxy';

let mWorker: worker.ThreadWorker = undefined;
let taskManager: WorkerTaskManager = undefined;

const FRAME_INTERVAL: number = 50;
const onMessageMap: Map<string, unknown> = new Map();
const ARRAY_LENGTHS: number = 6;
const DEFAULT_RATIO_RANGE: number[] = [1, ARRAY_LENGTHS];
const TEMPLATE_MAX_NUMBER: number = 16;
const FOCUS_MODE_CACHE_TTL_MS: number = 1500;
const HEAVY_LOG_TASK_TYPES: Set<string> = new Set([
  WorkerTask.ACTION_START_UP,
  WorkerTask.ACTION_INIT
]);

export class CameraProxy {
  public static readonly EXPOSURE_BIAS_RANGE_4: number = 4;
  public static readonly EXPOSURE_BIAS_RANGE_NEGATIVE_4: number = -4;
  private mHasFlash: boolean = true;
  private mZoomRatioRange: number[];
  private static sInstanceCameraProxy: CameraProxy;
  private mIsDeferPhoto: boolean = false;
  private isReportDrawnCompleted: boolean = false;
  private mZoomPointInfo: ZoomPointInfo;
  private virtualApertures: number[];
  private physicalApertures: camera.PhysicalAperture[];
  private supportedColorEffects: camera.ColorEffectType[];
  private timeLapseIntervalRange: number[];
  private isVideoMirrorSupported: boolean;
  private isQuickThumbnailSupported: boolean;
  private isAutoVideoFrameRateSupported: boolean;
  private isCompositionSuggestionSupported: boolean = false;
  private mIsLogAssistanceSupported: boolean = false;
  private isCustomFilterUpgrade: boolean = false;
  private focusModeSupportedInFlight: Map<number, Promise<boolean>> = new Map();
  private focusModeSupportedCache: Map<number, { value: boolean, time: number }> = new Map();

  public static getInstance(): CameraProxy {
    if (!CameraProxy.sInstanceCameraProxy) {
      CameraProxy.sInstanceCameraProxy = new CameraProxy();
      HiLog.i(TAG, 'build new WorkerTask.');
    }
    return CameraProxy.sInstanceCameraProxy;
  }

  private constructor() {
    let entry: string = 'phone';
    /* instrument ignore if*/
    /* instrument ignore else*/
    if (DeviceInfo.isPc() && GlobalContext.get().getIsPicker()) {
      entry = 'pcpicker';
    } else if (DeviceInfo.isPc()) {
      entry = 'pc';
    } else if (GlobalContext.get().getIsPicker()) {
      entry = 'picker';
    } else if (DeviceInfo.isTablet()) {
      entry = 'tablet';
    }
    mWorker = new worker.ThreadWorker('../../worker/CameraWorker.ts');
    taskManager = new WorkerTaskManager(mWorker);
    HiLog.i(TAG, `constructor, build new worker in: ${entry}.`);
    if (!mWorker) {
      HiLog.e(TAG, 'failed to create a CameraProxy, worker undefined.');
    }
  }

  public init(): void {
    HiLog.i(TAG, 'init WorkerTask.');
    this.initOnMessage();
    this.initRegisterListener();
  }

  private initOnMessage(): void {
    mWorker.onmessage = function (e): void {
      const result: MessageInfo = e.data;
      if (!result || !result.type) {
        return;
      }
      HiLog.beginTraceFreq(TAG, `onmsg:${result.type}`, FREQUENT_HILOG_EVENT.includes(result.type));
      if (!result.hasResolve) {
        const onMessage: Callback = <Callback> onMessageMap.get(result.type);
        if (onMessage) {
          // 子线程往主线程发送消息过于频繁，改成debug级别，避免冲掉关键日志
          HiLog.d(TAG, `onmsg: onWorker message type = ${result.type}, data = ${simpleStringify(result.data)}.`)
          onMessage.apply(this, [result.data]);
        }
      } else {
        taskManager.onMessage(result);
      }
      HiLog.endTraceFreq(TAG, `onmsg:${result.type}`, FREQUENT_HILOG_EVENT.includes(result.type));
    };
  }

  private initRegisterListener(): void {
    const storeManager: StoreManager = StoreManager.getInstance();
    const eventBus: EventBus = EventBusManager.getInstance().getEventBus();
    const thumbnailService: ThumbnailService = ThumbnailService.getInstance();
    this.on(WorkerTask.ON_QUICK_THUMBNAIL, async (data: { // 快速缩略图上报时机
      thumbnail: image.PixelMap,
      isDeferEnabled: boolean
    }) => {
      if (getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') !== CameraRunningState.STARTED) {
        return;
      }
      CollaborateControlService.getInstance().sendImage(data.thumbnail); // 遥控拍照发送缩略图
      if (!CaptureService.getInstance().isCancelClickDownCapture()) {
        HiLog.i(TAG,
          'SHOT2SEE onQuickThumbnail in main thread invoke, get quick thumbnail begin.' + data.isDeferEnabled);
        storeManager.postMessage(ThumbnailAction.received(data.thumbnail, ThumbnailUpdateScene.CAPTURE));
        AppStorage.setOrCreate('thumbnailPixelMap', data.thumbnail);
      }
    });
    this.on(WorkerTask.ON_CAPTURE_ID_QUICK_THUMBNAIL, async (data: { // captureId及匹配的快速缩略图
      captureId: string, thumbnail: image.PixelMap
    }) => {
      HiLog.i(TAG, 'WorkerTask.ON_CAPTURE_ID_QUICK_THUMBNAIL.');
      if (getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') !== CameraRunningState.STARTED) {
        return;
      }
      if (!CaptureService.getInstance().isCancelClickDownCapture()) {
        HiLog.i(TAG, 'postMessage browserAddThumbnail.');
        storeManager.postMessage(ThumbnailAction.browserAddThumbnail(data.captureId, data.thumbnail));
      }
      if (CameraAppCapability.getInstance().getIsSuspendPhotoBrowser()) { // 配置不使用大图组件hsp
        data.thumbnail?.release();
        return;
      }
    });
    this.on(WorkerTask.ON_CAPTURE_ID_PHOTO_ASSET, async (data: { // captureId及匹配的80分图Asset
      captureId: string, photoAsset: photoAccessHelper.PhotoAsset
    }) => {
      HiLog.i(TAG, 'WorkerTask.ON_CAPTURE_ID_PHOTO_ASSET postMessage browserUpdateThumbnailAsset.');
      storeManager.postMessage(ThumbnailAction.browserUpdateThumbnailAsset(data.captureId, data.photoAsset));
    });
    this.on(WorkerTask.ON_DEPTH_FUSION_ZOOM_THRESHOLD, (data: {
      threshold: number[]
    }) => {
      storeManager.postMessage(execAction('DepthFusionAction', 'onDepthFusionZoomThreshold', data.threshold));
    });
    this.on(WorkerTask.ON_THUMBNAIL_FILE_CREATED, (uri: string) => {
      thumbnailService.deregisterUri(uri);
    });
    this.on(WorkerTask.ON_NEXT_CAPTURE, (isDeferPhoto: boolean) => { // captureReady上报时机
      CaptureService.getInstance().onCaptureReady();
      if (CaptureService.getInstance().queryIsEnableRichCaptureNext() &&
        !thumbnailService.isPictureAcquireOrStoreTimeOut(false)) {
        storeManager.postMessage(CaptureAction.richCaptureNext());
      } else {
        CaptureService.getInstance().clearRichCaptureNext();
      }
      const mode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
      if (isDeferPhoto) {
        thumbnailService.pictureSaved();
      }
    });
    this.on(WorkerTask.ON_PHOTO_SAVED, (uri: string) => {
      HiLog.i(TAG, `SHOT2SEE onPhoto picture is saved, photoUri: ${uri}.`);
      CaptureService.getInstance().photoSaved(uri);
    });
    this.on(WorkerTask.ON_FACE_METADATA_OBJECT, (data: { boundingBoxArr: camera.Rect[] }) => {
      if (data && data.boundingBoxArr) {
        eventBus.emit(ActionType.ACTION_UPDATE_FACE_DETECTION_VIEW, [data.boundingBoxArr]);
      }
    });
    this.on(WorkerTask.ON_SMART_BACKSELFIE_FACE_METADATA_OBJECT, (data: { faceMetaData: camera.MetadataObject[] }) => {
      if (data && data.faceMetaData) {
        eventBus.emit(ActionType.ACTION_UPDATE_SMART_BACK_SELFIE_FACE_DATA, [data.faceMetaData]);
      }
    });
    this.on(WorkerTask.EYE_FOCUS, (data: { boundingBoxArr: camera.Rect[] }) => {
      if (data && data.boundingBoxArr) {
        eventBus.emit(ActionType.ACTION_UPDATE_EYE_FOCUS_VIEW, [data.boundingBoxArr]);
      }
    });
    this.on(WorkerTask.SMILE_CAPTURE, (data: { isSmile: camera.MetadataObject[] }) => {
      if (data && data.isSmile) {
        eventBus.emit(ActionType.ACTION_UPDATE_FACE_SMILE_DETECTION, [data.isSmile]);
      }
    });
    this.on(WorkerTask.UPDATE_HDR_SUPPORT, (data: { isOpen: boolean }) => {
      storeManager.postMessage(Action.updateHDR(data.isOpen));
    });
    this.on(WorkerTask.ON_ESTIMATED_CAPTURE_DURATION, (data: { duration: number }) => {
      storeManager.postMessage(Action.estimatedCaptureDuration(data.duration));
      HiLog.d(TAG, 'store update estimated capture duration: ' + data.duration);
    });
    this.on(WorkerTask.ON_VIDEO_URI, (uri: string) => {
      if (thumbnailService.isDeregisterUri(uri)) {
        HiLog.i(TAG, `CameraProxy on videoUri: ${uri}, isDeregisterUri: true.`);
        return;
      }
      HiLog.i(TAG, `CameraProxy on videoUri: ${uri}.`);
      thumbnailService.deregisterUri(uri);
    });
    this.on(WorkerTask.ON_RECORD_ERROR, (data) => {
      storeManager.postMessage(RecordAction.error(data.errorCode, data.errorMsg));
    });
    this.on(WorkerTask.ON_CAMERA_ERROR, (data) => {
      storeManager.postMessage(CameraAction.error(data.errorCode, data.errorMsg));
    });
    this.on(WorkerTask.ON_CAMERA_STATUS, (data) => {
      storeManager.postMessage(CameraAction.onCameraStatus(data.cameraStatus));
    });
    this.on(WorkerTask.ON_NIGHT_CAPTURE_START, (data) => {
      const position: camera.CameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      const mode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
      storeManager.postMessage(Action.nightCaptureStart(data.exposureTime));
    });
    this.on(WorkerTask.ON_NIGHT_CAPTURE_END, () => {
      const position: camera.CameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      const mode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
      if (getStates().get<number>('contextReducer', 'exposureTime') !== 0) {
        storeManager.postMessage(Action.delaySendCaptureEnd());
      } else {
        storeManager.postMessage(Action.captureEnd());
      }
    });
    this.on(WorkerTask.ON_NIGHT_FRAME_SHUTTER, () => {
      const position: camera.CameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      const mode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
      storeManager.postMessage(Action.nightFrameShutter());
    });

    /* instrument ignore next */
    this.on(WorkerTask.ON_BURST_DATA_REPORT, (data: {
      burstAvaInterval: number[],
    }) => {
      HiLog.i(TAG, 'burstDataReport');
    });
    this.on(WorkerTask.ON_BURST_FINISH_RESET, () => {
      HiLog.i(TAG, 'burstParamReset');
    });

    this.on(WorkerTask.ON_PREVIEW_FRAME_START, (data: { firstFrameTime: number }) => {
      HiLog.begin(TAG, 'reportOnFirstFrame');
      BlurAnimateUtil.setValidFrameFlag(true);
      storeManager.postMessage(Action.onPreviewFrameStart(true));
      const position: camera.CameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      const mode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
      HiLog.end(TAG, 'reportOnFirstFrame');
      if (this.isReportDrawnCompleted || GlobalContext.get().getT<boolean>('isSecurityCamera')) {
        return;
      }
      setTimeout(() => {
        HiLog.begin(TAG, 'reportDrawnCompleted');
        ContextManager.getInstance().getUiContext().reportDrawnCompleted(() => {
          HiLog.end(TAG, 'reportDrawnCompleted');
        });
        this.isReportDrawnCompleted = true;
      }, FRAME_INTERVAL);
    });
    this.on(WorkerTask.ON_COLLABORATE_PREVIEW_FRAME_START, () => {
      HiLog.i(TAG, 'on collaborate preview frame start');
      storeManager.postMessage(Action.onCollaboratePreviewFrameStart(true));
    });
    this.on(WorkerTask.ON_COLLABORATE_CONTROL_PREVIEW_FRAME_START, () => {
      HiLog.i(TAG, 'on collaborate control preview frame start');
      storeManager.postMessage(CollaborateControlAction.streamStarted());
    })
    this.on(WorkerTask.ON_COLLABORATE_CONTROL_PREVIEW_FRAME_END, () => {
      HiLog.i(TAG, 'on collaborate control preview frame end');
      storeManager.postMessage(CollaborateControlAction.streamEnd());
    })
    this.on(WorkerTask.ON_COLLABORATE_CONTROL_PREVIEW_FRAME_ERROR, () => {
      HiLog.i(TAG, 'on collaborate control preview frame error');
      storeManager.postMessage(CollaborateControlAction.streamError());
    })
    this.on(WorkerTask.ON_START_CAMERA_DURATION, (data: {
      fullOpenCameraEndTime: number,
      fullStartStreamBeginTime: number,
      preStartStreamBeginTime: number,
      openCameraEndTime: number,
      appPreOpenEndTime: number,
      openCameraBeginTime: number
      configSessionEndTime: number,
      configSessionBeginTime: number,
      sessionStartBeginTime: number,
      sessionStartEndTime: number,
      preStartStreamEndTime: number
    }) => {
    });
    this.on(WorkerTask.ON_CAMERA_PROCESS_DURATION, (data: {
      isStagedCapture: boolean,
      quickThumbBeginTime: number,
      realPictureBeginTime: number,
      realPictureEndTime: number,
      quickThumbEndTime: number,
      savePictureBeginTime: number,
      savePictureEndTime: number,
      pictureId: string,
      captureReadyTime: number,
      shot2ShotDuration: number,
      frameShutterEndTime: number,
      frameShutterEndDuration: number,
      captureDelivery2SegmentDuration: number,
      captureDelivery2SavePhotoDuration: number,
      captureDelivery2EnableThumbnailClickDuration: number,
    }) => {
    });
    this.on(WorkerTask.ON_START_CAMERA_POSITION_AND_MODE, (data: {
      cameraPositionOnStart: camera.CameraPosition,
      cameraModeOnStart: ModeType
    }) => {
    });
    this.on(WorkerTask.ON_USER_BEHAVIOR_PHOTO_INTERVAL, (data: {
      captureIntervalCurrentTime: number,
      isCaptureSuccess: boolean,
      failReason: string
    }) => {
    });
    this.on(WorkerTask.ON_CAMERA_DESTROY_SESSION_TIMEOUT, (data: {
      duration: number
    }) => {
    });
    this.on(WorkerTask.PC_PICKER_RECEIVED, (data: {
      pcPickerPhotoMap: Map<string, image.PixelMap>
    }) => {
      storeManager.postMessage(ThumbnailAction.pcPickerReceived(data.pcPickerPhotoMap));
    });
    this.on(WorkerTask.ON_PICKER_PHOTO_RECEIVED, (data: {
      photo: image.PixelMap
    }) => {
      storeManager.postMessage(PickerAction.photoReceived(data.photo));
    });
    this.on(WorkerTask.ON_TIME_LAPSE_TRY_AE_DONE, (data: { captureInterval: number }) => {
      eventBus.emit(ActionType.ACTION_TIME_LAPSE_TRY_AE_DONE, [data.captureInterval]);
    });
    this.on(WorkerTask.ON_BUFFER_RECEIVED_TIMELAPSE, () => {
      eventBus.emit(ActionType.ACTION_BUFFER_RECEIVED_TIMELAPSE, []);
    });
    this.on(WorkerTask.ON_CLOSE_CAMERA_TIMEOUT, (data: {
      duration: number
    }) => {
    });
    this.on(WorkerTask.ON_SAVE_PICTURE_FAILED, (data: {
      pictureName: string,
      storagePath: string,
      pictureType: number,
      failReason: string
    }) => {
    });
    this.on(WorkerTask.ON_VIDEO_RECORDING_STATUS, (data: { mem: string }) => {
      HiLog.i(TAG, 'video recording delay');
    });
    this.on(WorkerTask.ON_SAVE_VIDEO_FAIL, (data: {
      failReason: string
    }) => {
    });
    this.on(WorkerTask.ON_SKETCH_STATUS_CHANGED,
      async (data: { status: number, sketchRatio: number, centerPointOffset?: camera.Point }) => {
        const ratio = data.sketchRatio;
        const status = data.status;
        const centerPointOffset = data.centerPointOffset
        storeManager.postMessage(Action.onSketchStatusChanged(status, ratio, centerPointOffset));
      });
    this.on(WorkerTask.ON_DEFER_PHOTO_REPORT, (data: { assetUri: string }) => {
      // 80分图上报时机
    });
    this.on(WorkerTask.ON_DEFER_PHOTO_MEDIA_URI, (data: { assetUri: string }) => {
      // 80分图落盘结束时机
      if (data.assetUri) {
        if (thumbnailService.isWaitingLastCaptureMediaUri()) {
          thumbnailService.setLastCaptureMediaUri(data.assetUri);
        } else {
          thumbnailService.clearLastCaptureMediaUri();
        }
        AppStorage.setOrCreate('thumbnailMediaUri', data.assetUri); // 分段式传递uri
      }
      if (!this.mIsDeferPhoto || !this.isQuickThumbnailSupported) { // 单段式 或者 不支持快速缩略图的分段式
        thumbnailService.thumbnailUpdate(1);
      }
      const videoRecorderStatus: RecordingState = getStates().get<RecordingState>('recordReducer', 'recordingState');
      const isShowWhiteBack: boolean = getStates().get<boolean>('ringLightReducer', 'isShowWhiteBack');
      const isRecording: boolean =
        videoRecorderStatus !== RecordingState.READY && videoRecorderStatus !== RecordingState.ERROR;
      if (isShowWhiteBack && (isRecording || GlobalContext.get().getIsPicker())) {
        // 录像抓拍\Picker环形打闪没有缩略图变更，去掉打闪的时机在80分回图
        storeManager.postMessage(execAction('RingLightAction', 'emitBackGroundWhite', false));
      }
      if (GlobalContext.get().getIsPicker() && getStates().get<boolean>('uiReducer', 'showPicker')) {
        PickerUiService.isCameraActive = false;
        PickerUiService.getInstance().handleCameraCloseOrOpen();
      }
      thumbnailService.pictureSaved();
    });
    this.on(WorkerTask.ON_UPDATE_VALID_FRAME_FLAG, (flag: boolean) => {
      BlurAnimateUtil.setValidFrameFlag(flag);
    });
    this.on(WorkerTask.ON_SCENE_FEATURE_DETECTION_RESULT,
      (data: { detectionResult: camera.TripodDetectionResult }) => {
        const detectionResult = data.detectionResult;
        HiLog.i(TAG,
          `on detected: ${detectionResult.detected}, featureType:  ${detectionResult.featureType}, tripodStatus: ${detectionResult.tripodStatus}.`);
        if (detectionResult.featureType === camera.SceneFeatureType.MOON_CAPTURE_BOOST) {
          storeManager.postMessage(execAction('WatchMoonAction', 'onWatchMoonIconVisible', detectionResult.detected));
        }
        if (detectionResult.featureType === camera.SceneFeatureType.TRIPOD_DETECTION) {
          storeManager.postMessage(execAction('TripodAction', 'updateTripodStatus', detectionResult.tripodStatus));
        }
        if (detectionResult.featureType === camera.SceneFeatureType.LOW_LIGHT_BOOST) {
          storeManager.postMessage(execAction('LongExposureAction', 'onSceneFeatureChange', detectionResult.detected));
        }
      });
    this.on(WorkerTask.ON_CAPTURE_ABORTED, () => {
      CaptureService.getInstance().onCaptureAborted();
      thumbnailService.onCaptureAbort();
      CollaborateControlService.getInstance().onCaptureAborted(); // 遥控拍照，拍照发送失败，给手表发消息
    });
    this.on(WorkerTask.ON_NORMAL_FRAME_SHUTTER, () => {
      const position: camera.CameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      const mode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
      storeManager.postMessage(Action.normalFrameShutter());
    });
    this.on(WorkerTask.ON_FRAME_SHUTTER_END, () => {
      if (getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') !== CameraRunningState.STARTED) {
        return;
      }
      eventBus.emit(ActionType.ACTION_FRAME_SHUTTER_END, []);
    });
    this.on(WorkerTask.ON_UPDATE_ISO_DURATION, (data => {
      storeManager.postMessage(Action.onIsoStatusChanged(data.duration));
    }));
    // @ts-ignore
    this.on(WorkerTask.ON_UPDATE_FOCUS_TRACKING_INFO, (info: camera.FocusTrackingMetaInfo) => {
      if (!info) {
        return;
      }
      eventBus.emit(ActionType.ACTION_UPDATE_FOCUS_TRACKING_INFO, [info]);
    });
    this.on(WorkerTask.ON_UPDATE_PHYSICAL_APERTURE_DURATION, (data => {
      storeManager.postMessage(Action.onApertureStatusChanged(data.duration));
    }));
    // @ts-ignore
    this.on(WorkerTask.ON_APERTURE_EFFECT_CHANGE, (effect: camera.ApertureEffect) => {
      storeManager.postMessage(Action.onApertureEffectChange(effect));
    });
    this.on(WorkerTask.ON_UPDATE_EXPOSURE_RECOVERY_FLAG, (data => {
      storeManager.postMessage(Action.onLuminationStatusChanged(data.info));
    }));
    this.on(WorkerTask.ON_UPDATE_EXPOSURE_DURATION, (data => {
      storeManager.postMessage(Action.onProfessionShutterStatusChanged(data.duration));
    }));
    this.on(WorkerTask.ON_PROFESSION_ABILITY_CHANGE, (data => {
      storeManager.postMessage(Action.onAbilityStatusChanged(data.isoRange, data.ApertureRange));
    }));
    this.on(WorkerTask.ON_SUPER_MOTION_STATUS, (data: number) => {
      storeManager.postMessage(execAction('MotionAction', 'postSuperMotionState', data));
    });
    this.on(WorkerTask.ON_SLOW_MOTION_ZOOM_RANGE, (data: number[]) => {
      storeManager.postMessage(execAction('MotionAction', 'postSlowMotionZoomRange', data));
    });
    this.on(WorkerTask.ON_FLASH_STATUS, (data: camera.LcdFlashStatus) => {
      storeManager.postMessage(execAction('RingLightAction', 'emitRingPhotoFlash', data.lcdCompensation));
      storeManager.postMessage(execAction('RingLightAction', 'switchRingAlwaysOnUx', data.isLcdFlashNeeded));
    });
    // @ts-ignore
    this.on(WorkerTask.ON_SUPPORTED_NIGHT_SUB_MODE_TYPE, (data: camera.NightSubModeType[]) => {
      HiLog.i(TAG, `ON_SUPPORTED_NIGHT_SUB_MODE_TYPE: ${JSON.stringify(data)}`);
      storeManager.postMessage(execAction('NightSubModeAction', 'updateNightSubModeTypes', data));
    });
    // @ts-ignore
    this.on(WorkerTask.ON_NIGHT_IMAGE_STABILIZATION_GUIDE, (data: camera.ImageStabilizationGuideInfo) => {
      storeManager.postMessage(execAction('NightSubModeAction', 'updateImageStabilizationGuideInfo', data.lineSegments,
        true));
    });
    this.on(WorkerTask.ON_PREEMPTION, () => {
      HiLog.i(TAG, 'on preemption camera error.');
      storeManager.postMessage(CameraAction.preemptWithError());
    });
    this.on(WorkerTask.ACTION_ON_LENS_BLOCKING, (data: { isCameraOccluded: boolean }) => {
      storeManager.postMessage(CameraAction.onLensBlocking(data.isCameraOccluded));
    });
    this.on(WorkerTask.ACTION_ON_LENS_DIRTY, (data: { isCameraLensDirty: boolean }) => {
      storeManager.postMessage(CameraAction.onLensDirty(data.isCameraLensDirty));
    });

    this.on(WorkerTask.OPEN_FAILED, (data: { failReason: string }) => {
      HiLog.e(TAG, 'camera Error, OPEN_FAILED onMessage.');
      AppStorage.setOrCreate('cameraError', true);
      taskManager.cameraError();
    });
    this.on(WorkerTask.BURST_START_FAILED, () => {
      HiLog.e(TAG, 'camera Error, BURST_START_FAILED onMessage.');
    });
    this.on(WorkerTask.ACTION_RECOVERY_RESTART_APP, () => {
      HiLog.e(TAG, 'camera Error, ACTION_RECOVERY_RESTART_APP onMessage.');
      RestartService.getInstance().recoveryRestartApp();
    });
    this.on(WorkerTask.ACTION_SUPER_PRIVACY_MODE_ENABLED, (data: { isEnable: boolean }) => {
      storeManager.postMessage(CameraAction.superPrivacyModeEnabled(data.isEnable));
    });
    this.on(WorkerTask.RECEIVED_PRE_RECORD_DURATION_TIME, (time: number) => {
      HiLog.i(TAG, `PRE_RECORD_TRACK Received PreRecord duration time: ${time}.`);
    });
    this.on(WorkerTask.ADD_PHOTO_COUNT, () => {
      SuspendTaskUtil.getInstance().addThumbnailCount();
    });
    this.on(WorkerTask.MINUS_PHOTO_COUNT, () => {
      SuspendTaskUtil.getInstance().minusThumbnailCount();
    });
    this.on(WorkerTask.RESET_PHOTO_COUNT, () => {
      SuspendTaskUtil.getInstance().resetCount();
    });

    this.on(WorkerTask.SET_CAMERA_CLOSE_FLAG, (flag: boolean) => {
      SuspendTaskUtil.getInstance().setAlreadyCloseCamera(flag);
    });
    this.on(WorkerTask.VIDEO_STATE_CHANGE, (type: string) => {
      eventBus.emit(WorkerTask.VIDEO_STATE_CHANGE, [type]);
    });
    this.on(WorkerTask.ON_PICKER_RELEASE_FROM_MAIN, () => {
      if (getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState') !== CameraRunningState.STARTED ||
        !getStates().get<boolean>('uiReducer', 'showPicker')) {
        HiLog.d(TAG, 'ON_PICKER_RELEASE_FROM_MAIN to closeCamera blocked.');
        return;
      }
      HiLog.d(TAG, 'ON_PICKER_RELEASE_FROM_MAIN to closeCamera');
      this.closeCamera(); // picker80分图上报后close为生成100分图,从UI线程开始下发,避免picker快速退出后再立即重进时时序混乱
    });
    // @ts-ignore
    this.on(WorkerTask.ON_STITCHING_TARGET_METADATA, (targetInfo: camera.StitchingTargetInfo) => {
      if (targetInfo && targetInfo.position) {
        HiLog.d(TAG, `stitching target position: ${JSON.stringify(targetInfo)}.`);
        eventBus.emit(ActionType.ACTION_UPDATE_TARGET_POSITION, [targetInfo.position]);
        eventBus.emit(ActionType.ACTION_UPDATE_BASE_ANGLE, [targetInfo.angle]);
      }
    });
    // @ts-ignore
    this.on(WorkerTask.ON_STITCHING_CAPTURE_STATUS, (captureStatus: camera.StitchingCaptureState) => {
      let isBackground: boolean | undefined = AppStorage.get<boolean>('isBackground');
      if (captureStatus && !isBackground) {
        storeManager.postMessage(execAction('StitchingAction', 'updateCaptureStatus', captureStatus));
      }
    });

    this.on(WorkerTask.ON_STITCHING_PREVIEW, (pixelMap: image.PixelMap) => {
      eventBus.emit(ActionType.ACTION_UPDATE_STITCHING_PREVIEW, [pixelMap]);
    });

    // @ts-ignore
    this.on(WorkerTask.ON_STITCHING_HINT, (stitchingHint: camera.StitchingHint) => {
      HiLog.i(TAG, `stitching hint: ${JSON.stringify(stitchingHint)}.`);
      eventBus.emit(ActionType.ACTION_SHOW_STITCHING_HINT, [stitchingHint]);
    });
    this.on(WorkerTask.ON_RECV_AI_COMPOSITION_BEGIN_NOTICE,
      () => {
        storeManager.postMessage(execAction('AICompositionAction', 'recvAICompositionBeginNotice'));
      });

    this.on(WorkerTask.ON_RECV_AI_COMPOSITION_CALIBRATION_DATA,
      // @ts-ignore
      (calibrationData: camera.CompositionCalibrationInfo) => {
        if (calibrationData) {
          storeManager.postMessage(execAction('AICompositionAction', 'recvAICompositionCalibrationData',
            calibrationData));
        }
      });

    this.on(WorkerTask.ON_RECV_AI_COMPOSITION_CONFIG_DATA,
      // @ts-ignore
      (configData: camera.CompositionConfigInfo) => {
        if (configData) {
          storeManager.postMessage(execAction('AICompositionAction', 'recvAICompositionConfigData', configData));
        }
      });

    this.on(WorkerTask.ON_RECV_AI_COMPOSITION_END_DATA,
      // @ts-ignore
      (endData: camera.CompositionEndInfo) => {
        storeManager.postMessage(execAction('AICompositionAction', 'recvAICompositionEndData', endData));
      });

    this.on(WorkerTask.ON_LIGHT_STATUS_CHANGE,
      // @ts-ignore
      (lightStatus: camera.LightStatus) => {
        storeManager.postMessage(Action.lightStatueChange(lightStatus));
      });

    this.on(WorkerTask.ON_RECORD_PAUSED, () => {
      storeManager.postMessage(RecordAction.recordPaused());
    });

    this.on(WorkerTask.UPDATE_FOCUS_STATE, (data: { focusState: camera.FoldStatus }) => {
      eventBus.emit(FocusExposureActionType.ACTION_UPDATE_FOCUS_STATE, [data]);
    });

    this.on(WorkerTask.SAVE_MOVIE_INFO_ASSET_DONE, (data: { during: number }) => {
      eventBus.emit(RecordActionType.SAVE_MOVIE_INFO_ASSET_DONE, []);
      if (GlobalContext.get().getIsPicker() && getStates().get<boolean>('uiReducer', 'showPicker')) {
        HiLog.i(TAG, `SAVE_MOVIE_INFO_ASSET_DONE closeCamera`);
        this.closeCamera();
      }
    });

    this.on(WorkerTask.ON_VIDEO_FRAME_END, () => {
      eventBus.emit(RecordActionType.VIDEO_FRAME_END, []);
    });
  }

  private postMessageForPromise<T>(type: string, data: unknown, callback?: unknown): Promise<T> {
    HiLog.i(TAG, `postMessage: type = ${type}`);
    HiLog.i(TAG, `postMessage: data = ${this.getDataSummary(type, data)}, is sync.`);
    return new Promise<T>(function (resolve) {
      if (SYNC_TASK_TYPES.includes(type)) {
        taskManager.postMessageWithSync<T>({ hasResolve: true, type: type, data: data }, resolve, callback);
      } else {
        taskManager.postMessage<T>({ hasResolve: true, type: type, data: data }, resolve, callback);
      }
    });
  }

  private postMessage(type: string, data: unknown): void {
    HiLog.i(TAG, `postMessage: type = ${type}`);
    HiLog.i(TAG, `postMessage: data = ${simpleStringify(data)}, isAcync = false.`);
    mWorker.postMessage({ hasResolve: false, type: type, data: data });
  }

  public on(type: string, callback: unknown): void {
    onMessageMap.set(type, callback);
  }

  public destroy(): void {
    mWorker.terminate();
  }

  public readyToStartup(): boolean {
    return taskManager.excludes(WorkerTask.ACTION_CLOSE_CAMERA, WorkerTask.ACTION_ADD_DEFERRED_SURFACE,
      WorkerTask.ACTION_START_UP, WorkerTask.ACTION_START_PREVIEW);
  }

  public setCollaborationMode(collaborationMode: string): void {
    return this.postMessage(WorkerTask.ACTION_COLLABORATION_MODE, [collaborationMode]);
  }

  public checkThreadSyncTaskAndRecovery(): Promise<void> {
    if (taskManager.checkSyncTaskIsTimeout()) {
      return this.postMessageForPromise<void>(WorkerTask.ACTION_RECOVERY_WORKER_THREAD, []);
    }
    return new Promise<void>(() => {
    });
  }

  public initCamera(cameraInputMessage: CameraInputMessage, context,
    pickerInfo?: PickerInfo): Promise<void> {
    return this.postMessageForPromise<void>(WorkerTask.ACTION_INIT, [cameraInputMessage, context, pickerInfo]);
  }

  public initCameraList(): Promise<void> {
    return this.postMessageForPromise<void>(WorkerTask.ACTION_INIT_CAMERA_LIST, []);
  }

  public startupCamera(message: SessionMessage): Promise<SessionInfo> {
    return this.postMessageForPromise<SessionInfo>(WorkerTask.ACTION_START_UP, [message],
      this.onCreateSession.bind(this));
  }

  public startPreview(message: SessionMessage): Promise<SessionInfo> {
    return this.postMessageForPromise<SessionInfo>(WorkerTask.ACTION_START_PREVIEW, [message],
      this.onCreateSession.bind(this));
  }

  public addDeferredSurface(surfaceId: string, mixSurfaceId: string): Promise<boolean> {
    return this.postMessageForPromise<boolean>(WorkerTask.ACTION_ADD_DEFERRED_SURFACE, [surfaceId, mixSurfaceId]);
  }

  public swapDeferredSurface(surfaceId: string): Promise<boolean> {
    let messageReturn: Promise<boolean> = Promise.resolve(false);
    try {
      messageReturn = this.postMessageForPromise<boolean>(WorkerTask.ACTION_SWAP_DEFERRED_SURFACE, [surfaceId]);
    } catch (e) {
      HiLog.w(TAG, 'swapDeferredSurface failed');
    }
    return messageReturn;
  }

  public restartPreview(message: SessionMessage,
    restartPreviewType: RestartPreviewType, tricollapsStatusChange?: boolean): Promise<SessionInfo> {
    return this.postMessageForPromise<SessionInfo>(WorkerTask.ACTION_RESTART_PREVIEW,
      [message, restartPreviewType, tricollapsStatusChange], this.onCreateSession.bind(this));
  }

  public changeMode(message: SessionMessage, restartPreviewType: RestartPreviewType): Promise<SessionInfo> {
    return this.postMessageForPromise<SessionInfo>(WorkerTask.ACTION_CHANGE_MODE, [message, restartPreviewType],
      this.onCreateSession.bind(this));
  }

  public switchCamera(message: SessionMessage, restartPreviewType: RestartPreviewType): Promise<SessionInfo> {
    return this.postMessageForPromise<SessionInfo>(WorkerTask.ACTION_SWITCH_CAMERA, [message, restartPreviewType],
      this.onCreateSession.bind(this));
  }

  public changeModeAndSwitchCamera(message: SessionMessage,
    restartPreviewType: RestartPreviewType): Promise<SessionInfo> {
    return this.postMessageForPromise<SessionInfo>(WorkerTask.ACTION_SWITCH_CAMERA_CHANGE_MODE,
      [message, restartPreviewType], this.onCreateSession.bind(this));
  }

  public setZoomRatio(zoomRatio: number): void {
    this.postMessage(WorkerTask.ACTION_SET_ZOOM_RATIO, [zoomRatio]);
  }

  public addPipSurface(pipSurfaceId: string): void {
    this.postMessage(WorkerTask.ACTION_ADD_PIP_SURFACE_ID, [pipSurfaceId]);
  }

  public closeCamera(closeInfoToWork?: CloseInfoToWork): Promise<void> {
    const closedCallback = (): void => {
    }
    return this.postMessageForPromise<void>(WorkerTask.ACTION_CLOSE_CAMERA, [closeInfoToWork],
      closedCallback);
  }

  public stopPreviewOutPut(): Promise<void> {
    return this.postMessageForPromise<void>(WorkerTask.ACTION_STOP_PREVIEW_OUTPUT, undefined);
  }

  public capture(cameraSetting: camera.PhotoCaptureSetting, captureMessage: CaptureMessage): void {
    return this.postMessage(WorkerTask.ACTION_CAPTURE, [cameraSetting, captureMessage]);
  }

  public startRecording(message: VideoOutputMessage, tagMessage: TagMessage): Promise<StartRecordResultType> {
    return this.postMessageForPromise<StartRecordResultType>(WorkerTask.ACTION_RECORD_START, [message, tagMessage],
      this.onStartRecord.bind(this));
  }

  /* instrument ignore next */
  public startRecorderRecording(previewRecordMessage: PreviewRecordOutputMessage,
    isSupportRealTimeFilter: boolean): Promise<StartRecordResultType> {
    return this.postMessageForPromise<StartRecordResultType>(WorkerTask.ACTION_RECORD_START_RECORDER,
      [previewRecordMessage, isSupportRealTimeFilter], this.onStartRecord.bind(this));
  }

  public pauseRecording(): Promise<void> {
    EventBusManager.getInstance().getEventBus().emit(RecordActionType.WILL_PAUSE, []);
    return this.postMessageForPromise<void>(WorkerTask.ACTION_RECORD_PAUSE, []);
  }

  /* instrument ignore next */
  public pauseRecorderRecording(isSupportRealTimeFilter: boolean): Promise<void> {
    return this.postMessageForPromise<void>(WorkerTask.ACTION_RECORD_PAUSE_RECORDER, [isSupportRealTimeFilter]);
  }

  public resumeRecording(): Promise<void> {
    EventBusManager.getInstance().getEventBus().emit(RecordActionType.WILL_RESUME, []);
    return this.postMessageForPromise<void>(WorkerTask.ACTION_RECORD_RESUME, []);
  }

  /* instrument ignore next */
  public resumeRecordingPreview(isSupportRealTimeFilter: boolean): Promise<void> {
    return this.postMessageForPromise<void>(WorkerTask.ACTION_RECORD_RESUME_RECORDER, [isSupportRealTimeFilter]);
  }

  public stopRecording(validateThumbnail: boolean): Promise<void> {
    return this.postMessageForPromise<void>(WorkerTask.ACTION_RECORD_STOP, [validateThumbnail], () => {
      AppStorage.setOrCreate('thumbnailMediaUri', getStates().get<string>('recordReducer', 'videoUri'));
    });
  }

  public deletePickerVideoFile(): Promise<void> {
    return this.postMessageForPromise<void>(WorkerTask.ACTION_DELETE_PICKER_VIDEO_FILE, []);
  }

  public resetVideoFileManagerUri(): void {
    return this.postMessage(WorkerTask.RESET_VIDEO_FILE_MANAGER_URI, []);
  }

  public stopRecorderRecording(isSupportRealTimeFilter: boolean, validateThumbnail: boolean): Promise<void> {
    return this.postMessageForPromise<void>(WorkerTask.ACTION_RECORD_STOP_RECORDER,
      [isSupportRealTimeFilter, validateThumbnail], () => {
        AppStorage.setOrCreate('thumbnailMediaUri', getStates().get<string>('recordReducer', 'videoUri'));
      });
  }

  public setFlashMode(flashMode): void {
    return this.postMessage(WorkerTask.ACTION_CHANGE_FLASH_MODE, [flashMode]);
  }

  public setStitchingMove(stitchingMove: boolean): void {
    return this.postMessage(WorkerTask.ACTION_CHANGE_STITCHING_MOVE, [stitchingMove]);
  }

  public isSupportedFocusStateDetect(focusMode: camera.FocusMode): Promise<boolean> {
    const key = Number(focusMode);
    const cache = this.focusModeSupportedCache.get(key);
    if (cache && Date.now() - cache.time < FOCUS_MODE_CACHE_TTL_MS) {
      HiLog.d(TAG, `isSupportedFocusStateDetect: hit short cache, focusMode=${key}.`);
      return Promise.resolve(cache.value);
    }
    if (this.focusModeSupportedInFlight.has(key)) {
      return this.focusModeSupportedInFlight.get(key);
    }
    const inFlight = this.postMessageForPromise<boolean>(WorkerTask.ACTION_IS_FOCUS_MODE_SUPPORTED, [focusMode]);
    this.focusModeSupportedInFlight.set(key, inFlight);
    inFlight.then((supported) => {
      this.focusModeSupportedCache.set(key, { value: supported, time: Date.now() });
    });
    inFlight.finally(() => {
      this.focusModeSupportedInFlight.delete(key);
    });
    return inFlight;
  }

  public setFocus(focusData: FocusData): void {
    return this.postMessage(WorkerTask.ACTION_SET_FOCUS, [focusData]);
  }

  private getDataSummary(type: string, data: unknown): string {
    if (HEAVY_LOG_TASK_TYPES.has(type)) {
      const payloadLength = Array.isArray(data) ? data.length : 0;
      return `taskSummary={type:${type},dataType:${typeof data},payloadLength:${payloadLength}}`;
    }
    return simpleStringify(data);
  }

  /* instrument ignore next */
  public sendShutterButtonUp(shutterInterval: number): void {
    return this.postMessage(WorkerTask.ACTION_SHUTTER_BUTTON_UP, [shutterInterval]);
  }

  /* instrument ignore next */
  public sendNeedDeleteOnePhoto(thumbnailAnimAvailable: boolean): void {
    return this.postMessage(WorkerTask.ACTION_NEED_DELETE_ONE_PIC, [thumbnailAnimAvailable]);
  }

  /* instrument ignore next */
  public startBurst(startBurstTime: number): void {
    return this.postMessage(WorkerTask.ACTION_START_BURST, [startBurstTime]);
  }

  /* instrument ignore next */
  public stopBurst(): void {
    return this.postMessage(WorkerTask.ACTION_STOP_BURST, []);
  }

  /* instrument ignore next */
  public uiBurstOne(captureId: number): void {
    return this.postMessage(WorkerTask.ACTION_UI_BURST_ONE, [captureId]);
  }

  public hasFlash(): boolean {
    return this.mHasFlash;
  }

  public getZoomRatioRange(): number[] {
    return this.mZoomRatioRange;
  }

  /* instrument ignore next */
  public setIsShowLandscape(isShowLandscape: boolean): void {
    return this.postMessage(WorkerTask.ACTION_SET_IS_SHOW_LANDSCAPE, [isShowLandscape]);
  }

  public setIsConnectReaderAndSend(connected: boolean, canSendMessage, context: Context): void {
    return this.postMessage(WorkerTask.ACTION_CONNECT_RENDER_AND_SEND, [connected, canSendMessage, context]);
  }

  public setDirection(data: { direction: number, rotate: number, settingAngle: number }): void {
    return this.postMessage(WorkerTask.ACTION_SEND_DIRECTION, [data]);
  }

  private async onCreateSession(data: unknown): Promise<void> {
    const message: SessionInfo = <SessionInfo> data;
    if (message) {
      if (message.canAddOutput === false) {
        CameraAppCapability.getInstance().paramAbnormal2MatchCapability();
      }
      this.mHasFlash = message.hasFlash ?? this.mHasFlash;
      this.mZoomRatioRange = DEFAULT_RATIO_RANGE;
      this.mIsDeferPhoto = message.isDeferPhoto;
      this.mZoomPointInfo = message.zoomPointInfo;
      this.virtualApertures = message.virtualApertures;
      this.physicalApertures = message.physicalApertures;
      this.timeLapseIntervalRange = message.timeLapseIntervalRange;
      this.isVideoMirrorSupported = message.isVideoMirrorSupported;
      this.isQuickThumbnailSupported = message.isQuickThumbnailSupported;
      this.isAutoVideoFrameRateSupported = message.isAutoVideoFrameRateSupported;
      this.isCompositionSuggestionSupported = message.isCompositionSuggestionSupported;
      this.mIsLogAssistanceSupported = message.isLogAssistanceSupported;
    }
  }

  private onStartRecord(data: unknown): void {
    const result: StartRecordResultType = <StartRecordResultType> data;
    if (!result) {
      HiLog.e(TAG, 'onStartRecord err. data is undefined');
      return;
    }
    if (DeviceInfo.isTv()) {
      try {
        const startTimeSeconds: number = systemDateTime.getUptime(systemDateTime.TimeType.STARTUP);
        HiLog.i(TAG, `onStartRecord startTimeSeconds ${startTimeSeconds}`);
        StoreManager.getInstance().postMessage(RecordAction.setStartSeconds(startTimeSeconds));
      } catch (err) {
        HiLog.i(TAG, `onStartRecord startTimeSeconds error: ${err?.code} ${err?.message}`);
      }
    }
    this.onCreateSession(result.sessionMessage);
  }

  public async getFocusDistance(): Promise<number> {
    return await this.postMessageForPromise<number>(WorkerTask.ACTION_GET_FOCUS_DISTANCE, []);
  }

  public async getIsoRange(): Promise<number[]> {
    return await this.postMessageForPromise<number[]>(WorkerTask.ACTION_GET_ISO_RANGE, [])
  }

  public setVideoStabilization(value: camera.VideoStabilizationMode): void {
    return this.postMessage(WorkerTask.ACTION_SET_VIDEO_STABILIZATION, [value]);
  }

  public setPortraitEffect(value: number): void {
    return this.postMessage(WorkerTask.ACTION_SET_PORTRAIT_EFFECT, [value]);
  }

  public setPortraitThemeType(value: number): void {
    return this.postMessage(WorkerTask.ACTION_SET_PORTRAIT_BEAUTY_THEME, [value]);
  }

  public async getLightPainting(): Promise<number> {
    return await this.postMessageForPromise<number>(WorkerTask.ACTION_GET_LIGHT_PAINTING, []);
  }

  public setLightPainting(type: number): void {
    return this.postMessage(WorkerTask.ACTION_SET_LIGHT_PAINTING, [type]);
  }

  public setAigcEnhance(isEnable: boolean): void {
    return this.postMessage(WorkerTask.ACTION_SET_AIGC_ENHANCE, [isEnable]);
  }

  // @ts-ignore
  public setNightSubMode(subMode: camera.NightSubModeType): void {
    return this.postMessage(WorkerTask.ACTION_SET_NIGHT_SUB_MODE, [subMode]);
  }

  public triggerLighting(): void {
    return this.postMessage(WorkerTask.ACTION_TRIGGER_LIGHTING, []);
  }

  public confirmCapture(): void {
    return this.postMessage(WorkerTask.ACTION_CONFIRM_CAPTURE, []);
  }

  public handleZoomVibrator(effectId: string, usage: string): void {
    return this.postMessage(WorkerTask.ACTION_HANDLE_ZOOM_VIBRATOR, [effectId, usage]);
  }

  public stopZoomVibrator(): void {
    return this.postMessage(WorkerTask.ACTION_STOP_ZOOM_VIBRATOR, []);
  }

  public setCameraShotKey(cameraShotKey: string, currentMode: ModeType, recordingState: RecordingState): void {
    return this.postMessage(WorkerTask.ACTION_CAMERA_SHOT_KEY, [cameraShotKey, currentMode, recordingState]);
  }

  public getExposureBiasRange(): number[] {
    return [CameraProxy.EXPOSURE_BIAS_RANGE_NEGATIVE_4, CameraProxy.EXPOSURE_BIAS_RANGE_4];
  }

  public isExposureModeSupported(exposureMode: camera.ExposureMode): boolean {
    return true;
  }

  public getExposureModeAndValue(): {
    exposureMode: camera.ExposureMode,
    exposureValue: number
  } {
    return { exposureMode: 0, exposureValue: 0 };
  }

  public setExposureValue(value: number): void {
    return this.postMessage(WorkerTask.ACTION_SET_EXPOSURE_VALUE, [value]);
  }

  public setMeteringPoint(point: camera.Point): void {
    return this.postMessage(WorkerTask.ACTION_SET_METERING_POINT, [point]);
  }

  public setExposure(value: ExposureData): void {
    return this.postMessage(WorkerTask.ACTION_SET_EXPOSURE, [value]);
  }

  public startFaceMetadata(): void {
    return this.postMessage(WorkerTask.ACTION_START_FACE_METADATA, []);
  }

  public startSession(message: TagMessage): void {
    return this.postMessage(WorkerTask.ACTION_START_SESSION, [message]);
  }

  public stopSession(): void {
    return this.postMessage(WorkerTask.ACTION_STOP_SESSION, []);
  }

  public enableMacro(enable: boolean): void {
    this.postMessage(WorkerTask.ACTION_ENABLE_SUPER_MACRO, [enable]);
  }

  public attemptPlayThumbnailAnimation(): void {
    const isQuickThumbnailSupported: boolean = CameraProxy.getInstance().getIsQuickThumbnailSupported();
    if (!isQuickThumbnailSupported) {
      return;
    }
    StoreManager.getInstance().postMessage(ThumbnailAction.animation()); // 分段式触发拇指图更新动效
    ThumbnailService.getInstance().thumbnailUpdate(1); // 分段式并且支持快速缩略图
  }

  public async savePickerFile(): Promise<{
    uri: string,
    uriFromLocal: boolean,
    errorMessage: string
  }> {
    const uriInfo: {
      uri: string,
      uriFromLocal: boolean,
      errorMessage: string
    } = await this.postMessageForPromise(WorkerTask.ACTION_SAVE_PICKER_FILE, []);
    return uriInfo;
  }

  public setSmoothZoom(targetRatio: number): void {
    return this.postMessage(WorkerTask.ACTION_SET_SMOOTH_ZOOM, [targetRatio]);
  }

  public prepareOrUnPrepareZoom(isPrepare: boolean): void {
    return this.postMessage(WorkerTask.ACTION_PREPARE_OR_UNPREPARE_ZOOM, [isPrepare]);
  }

  public getIsVideoMirrorSupported(): boolean {
    return this.isVideoMirrorSupported;
  }

  public getIsAutoVideoFrameRateSupported(): boolean {
    return this.isAutoVideoFrameRateSupported;
  }

  public getIsDeferPhoto(): boolean {
    return this.mIsDeferPhoto;
  }

  public getIsQuickThumbnailSupported(): boolean {
    return this.isQuickThumbnailSupported;
  }

  public async enableSceneFeature(scene: camera.SceneFeatureType, enabled: boolean): Promise<void> {
    await this.postMessageForPromise<number[]>(WorkerTask.ACTION_ENABLE_SCENE_FEATURE, [scene, enabled]);
  }

  public getSupportedVirtualAperturesResult(): number[] {
    return this.virtualApertures;
  }

  public setVirtualAperture(aperture: number): void {
    this.postMessage(WorkerTask.ACTION_SET_VIRTUAL_APERTURE, [aperture]);
  }

  public getSupportedPhysicalAperturesResult(): camera.PhysicalAperture[] {
    return this.physicalApertures;
  }

  public setPhysicalAperture(aperture): void {
    this.postMessage(WorkerTask.ACTION_SET_PHYSICAL_APERTURE, [aperture]);
  }

  public setApertureValue(value: number): void {
    return this.postMessage(WorkerTask.ACTION_SET_APERTURE, [value]);
  }

  public setIsoValue(value: number): void {
    return this.postMessage(WorkerTask.ACTION_SET_ISO, [value]);
  }

  public setMeteringModeValue(value: number): void {
    return this.postMessage(WorkerTask.ACTION_SET_METERING, [value]);
  }

  public setAuxiliary(value: number): void {
    return this.postMessage(WorkerTask.ACTION_SET_AUXILIARY, [value]);
  }

  public setSlowMotionDetectionArea(posData: camera.Rect): void {
    this.postMessage(WorkerTask.ACTION_SET_SUPER_MOTION_DETECTION, [posData]);
  }

  public setLivePhoto(value: boolean): void {
    return this.postMessage(WorkerTask.ACTION_SET_LIVE_PHOTO, [value]);
  }

  public getZoomPointInfo(): ZoomPointInfo {
    return this.mZoomPointInfo;
  }

  /* instrument ignore next */
  public refreshPickerInfo(pickerInfo: PickerInfo): void {
    this.postMessage(WorkerTask.ACTION_REFRESH_PICKER_INFO, [pickerInfo]);
  }

  public enableDepthFusion(enable: boolean): void {
    this.postMessage(WorkerTask.ACTION_ENABLE_DEPTH_FUSION, [enable]);
  }

  public isDepthFusionConfigured(isConfigured: boolean): void {
    this.postMessage(WorkerTask.ACTION_IS_DEPTH_FUSION_CONFIGURED, [isConfigured]);
  }

  public setTimeLapseInterval(interval: number): void {
    this.postMessage(WorkerTask.ACTION_SET_TIME_LAPSE_INTERVAL, [interval]);
  }

  public async getTimeLapseInterval(): Promise<number> {
    const timeLapseInterval: number =
      await this.postMessageForPromise<number>(WorkerTask.ACTION_GET_TIME_LAPSE_INTERVAL, []);
    return timeLapseInterval;
  }

  public getTimeLapseIntervalRange(): number[] {
    return this.timeLapseIntervalRange;
  }

  public async switchCollaborate(message: PreviewOutputMessage, tagMessage: TagMessage): Promise<void> {
    return await this.postMessageForPromise(WorkerTask.SWITCH_COLLABORATION, [message, tagMessage]);
  }

  public async collaborateControlPreviewOutput(message: PreviewOutputMessage, tagMessage: TagMessage): Promise<void> {
    return await this.postMessageForPromise(WorkerTask.ACTION_COLLABORATE_CONTROL_PREVIEW_OUTPUT,
      [message, tagMessage]);
  }

  public async panoramaMaxPreviewOutputStart(): Promise<boolean> {
    return await this.postMessageForPromise<boolean>(WorkerTask.ACTION_PANORAMA_MAX_START, []);
  }

  public async panoramaMinPreviewOutputStart(): Promise<boolean> {
    return await this.postMessageForPromise<boolean>(WorkerTask.ACTION_PANORAMA_MIN_START, []);
  }

  public async panoramaMaxPreviewOutputStop(): Promise<boolean> {
    return await this.postMessageForPromise<boolean>(WorkerTask.ACTION_PANORAMA_MAX_STOP, []);
  }

  public async panoramaMinPreviewOutputStop(): Promise<boolean> {
    return await this.postMessageForPromise<boolean>(WorkerTask.ACTION_PANORAMA_MIN_STOP, []);
  }

  public changeLocation(message: LocationMessage): void {
    this.postMessage(WorkerTask.CHANGE_LOCATION, [message]);
  }

  public setMirror(value: boolean): void {
    this.postMessage(WorkerTask.SET_MIRROR, [value]);
  }

  public setAutoFrameRate(value: boolean): void {
    this.postMessage(WorkerTask.AUTO_FRAME_RATE, [value]);
  }

  public setOperationEmotion(value: boolean): void {
    this.postMessage(WorkerTask.SET_OPERATION_EMOTION, [value]);
  }

  public setWindNoiseSuppression(value: Record<string, string>): void {
    this.postMessage(WorkerTask.SET_WIND_NOISE_SUPPRESSION, [value]);
  }

  public setSwingSubscribeStatus(value: boolean): void {
    this.postMessage(WorkerTask.SET_SWING_SUBSCRIBE_STATUS, [value]);
  }

  public resetWorkerPhotoCount(): void {
    this.postMessage(WorkerTask.RESET_WORKER_PHOTO_COUNT, []);
  }

  public showSnapshotEnd(message: TagMessage): void {
    this.postMessage(WorkerTask.SHOW_SNAPSHOT_END, [message]);
  }

  public setAudioZoomExtra(value: Record<string, string>): void {
    this.postMessage(WorkerTask.SET_AUDIO_EXTRA, [value]);
  }

  public togglePreRecording(open: boolean): void {
    this.postMessage(WorkerTask.OPEN_PRE_RECORD, [open]);
  }

  public setVideoFilter(filter: string): void {
    this.postMessage(WorkerTask.SET_VIDEO_FILTER, [filter]);
  }

  public setShortVideoModeIndex(value: number): void {
    this.postMessage(WorkerTask.SET_SHORT_VIDEO_INDEX, [value]);
  }

  public keepUsingStellarLenses(): void {
    this.postMessage(WorkerTask.KEEP_USING_STELLAR_LENSES, []);
  }

  public ScanCodeClose(): void {
    this.postMessage(WorkerTask.SCAN_CODE_CLOSE, []);
  }

  public getIsCompositionSuggestionSupported(): boolean {
    return this.isCompositionSuggestionSupported;
  }

  public enableAIComposition(enable: boolean): void {
    this.postMessage(WorkerTask.ENABLE_AI_COMPOSITION, [enable]);
  }

  public isLogAssistanceSupported(): boolean {
    return this.mIsLogAssistanceSupported;
  }

  public isEnableLogAssistance(enable: boolean): void {
    this.postMessage(WorkerTask.ENABLE_LOG_ASSISTANCE, [enable]);
  }

  public changeConstellationStatus(isOpen: boolean): void {
    this.postMessage(WorkerTask.ACTION_CHANGE_CONSTELLATION_STATUS, [isOpen]);
  }

  public setFocusTrackingMode(mode: camera.FocusTrackingMode): void {
    HiLog.i(TAG, `setFocusTrackingMode ui postMessage: ${mode}.`)
    this.postMessage(WorkerTask.ACTION_SET_FOCUS_TRACKING_MODE, [mode]);
  }

  public setFilterType(value: number): void {
    this.postMessage(WorkerTask.SET_FILTER_TYPE, [value]);
  }

  public setUltraPhoto(value: boolean): void {
    this.postMessage(WorkerTask.SET_ULTRA_PHOTO, [value]);
  }
}