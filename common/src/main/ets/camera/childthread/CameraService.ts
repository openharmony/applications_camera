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

import lazy { audio, systemDateTime /*, TimelapseNative*/ } from '../../utils/LazyImportUtil';
import camera from '@ohos.multimedia.camera';
import CameraDeviceManager from './modules/CameraDeviceManager';
import CameraInputWrap from './modules/CameraInputWrap';
import PhotoOutputWrap from './modules/PhotoOutputWrap';
import PreviewOutputWrap from './modules/PreviewOutputWrap';
import MetadataOutputWrap from './modules/MetadataOutputWrap';
import SessionWrap from './modules/session/SessionWrap';
import CameraContext from './modules/CameraContext';
import lazy { HiLog } from '../../utils/HiLog';
import type {
  App2CameraModeMessage,
  CameraInputMessage,
  TimeLapseRecordOutputMessage,
  PreviewOutputMessage,
  PreviewRecordOutputMessage,
  TagMessage,
  VideoOutputMessage,
  SessionMessage,
  SessionInfo,
  CloseInfoToWork,
  TimeLapseRecordMessage
} from '../DataType';
import lazy { photoAccessHelper } from '@kit.MediaLibraryKit';
import type { PickerInfo, StartRecordResultType } from '../../utils/types';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import RecorderWrap from './modules/video/RecorderWrap';
import lazy { modulesManager } from '../../worker/WorkerModuleManager';
import lazy { OutputOperation } from '../../function/outputswitcher/OutputOperation';
import image from '@ohos.multimedia.image';
import lazy { BusinessError } from '@ohos.base';
import lazy { workerCallback } from './WorkerCallback';
import type { CaptureMessage } from '../../function/capture/CaptureMessage';
import lazy { simpleStringify } from '../../utils/SimpleStringify';
import lazy { TaskExecutor } from '../../utils/TaskExecutor';
import lazy { RecordingState } from '../../function/recordcontrol/RecordAction';
import VideoModule from './modules/video/VideoModule';
import lazy { WorkerDataCache } from './WorkerDataCache';
import lazy { JSON } from '@kit.ArkTS';
import lazy { ModeTransform } from '../../mode/ModeTransform';
import lazy { colorSpaceManager } from '@kit.ArkGraphics2D';
import lazy { media } from '@kit.MediaKit';
import lazy { geoLocationManager } from '@kit.LocationKit';
import lazy { ExposureData } from '../../component/focusExposure/FocusExposureHelper';
import lazy { HideBugUtil } from '../../utils/HideBugUtil';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { window } from '@kit.ArkUI';
import lazy { LocationMessage } from '../../service/location/LocationMessage';
import lazy { CollaborateControlService } from '../../service/collaborateControl/CollaborateControlService'
import { isSupportFlashMode } from '../../function/enumbase/FlashMode';

/* instrument ignore file */
const TAG: string = 'CameraService';
const CAMERASTAUS: number = 4;

// saveRestore时间、类型数据
const PERSISTENT_DEFAULT_TIME = 15;
const TRANSIENT_ACTIVE_TIME = 0;
const PERSISTENT_DEFAULT_PARAM = 1;
const TRANSIENT_ACTIVE_PARAM = 2;
const VIRTUAL_APERTURE_FIRST: number = 0.95;
const VIRTUAL_APERTURE_LAST: number = 16;
// UserEventReport的常量，import会导致Worker线程创建耗时恶化
const TIME_COST_MS_CAMERA_TIMEOUT = 5000;
// GRL M态width
const MIDDLE_WIDTH_GRL = 2048;
const TIME_LAPSE_DELAY_100 = 100;
const TIME_LAPSE_DELAY_200 = 200;
const TIME_LAPSE_DELAY_500 = 500;
const TIME_LAPSE_DELAY_1000 = 1000;

export enum VlogTool {
  VALUE_OFF,
  NEAR_FOCUS,
  PORTRAIT_FOCUS,
  PORTRAIT_BLUR,
  AI_COLOR
}

// camera模块对外呈现界面
export class CameraService {
  private mCameraManager: camera.CameraManager;
  private mCameraDeviceManager: CameraDeviceManager;
  private mCameraInput: CameraInputWrap;
  private mSession: SessionWrap;
  private mPreviewOutput!: PreviewOutputWrap;
  private mPrepareFile: photoAccessHelper.PhotoAsset;
  private mPrepareFileChange: photoAccessHelper.PhotoAsset;
  private mTimelapseFd: number;
  private mTimelapseFdChange: number;
  private mTimeLapseFrontLocationMessage: LocationMessage;
  private mTimelapseFrontReady: boolean;
  private mCollaboratePreviewOutput!: PreviewOutputWrap;
  private mCollaborateControlPreviewOutput!: PreviewOutputWrap;
  private mPanoramaMaxPreviewOutput!: PreviewOutputWrap;
  private mPanoramaMinPreviewOutput!: PreviewOutputWrap;
  private mPhotoOutput!: PhotoOutputWrap;
  private videoModule: VideoModule = VideoModule.getInstance();
  private mMetadataOutput!: MetadataOutputWrap;
  public mCameraContext: CameraContext;
  public currentMode: ModeType;
  private pickerInfo: PickerInfo;
  private isCommit: boolean = false;
  private isDepthFusionConfigured: boolean = false;
  private mTagMessage: TagMessage;
  private mPreviewOutputForTimeLapse: PreviewOutputWrap;
  private mLastPhotoTime: number = 0;
  private lastImgComponent: image.Component = null;
  private realWidth: number = 0;
  private realHeight: number = 0;
  private isTimeLapseFrontStarted: boolean = false;
  private isTimeLapseFrontStopping: boolean = false;
  private isTimeLapseFrontFirstFrame: boolean = false;
  private timeLapseFrontInterval: number = 500;
  private timeLapseFrontFrameCount: number = 0;
  private fdNeedRelease: number = -1;
  private photoBufferState: number = 0;
  private displayDirection: number = 0;
  private mSessionMessage: SessionMessage;
  // @ts-ignore
  private mNightSubMode: camera.NightSubModeType[] = [];
  private vlogIndex: number = -1;
  private closeCameraAfterCapture: boolean = false;

  public constructor() {
  }

  public exitWithoutReleaseCamera(): void {
    this.closeCameraAfterCapture = true;
  }


  public initCameraManager(context, pickerInfo?: PickerInfo): void {
    HiLog.i(TAG, 'initCamera getCameraManager begin.');
    this.pickerInfo = pickerInfo;
    HiLog.i(TAG, `pickerInfo: ${simpleStringify(pickerInfo)}`);
    this.getCameraManager(context);
    this.mCameraDeviceManager = CameraDeviceManager.getInstance();
    this.mCameraDeviceManager.initCameraList(this.mCameraManager);
    GlobalContext.get().setWorkerContext(context);
    HiLog.i(TAG, 'initCamera getCameraManager end.')
  }

  public setSessionMessage(sessionMsg: SessionMessage): void {
    this.mSessionMessage = sessionMsg;
  }

  public checkCameraMangerStatus(): boolean {
    return !!this.mCameraManager;
  }

  private getCameraManager(context): void {
    if (!!this.mCameraManager) {
      return;
    }
    try {
      this.mCameraManager = camera.getCameraManager(context);
      // 监听 camera_service 的异常状态
      this.mCameraManager.on('cameraStatus', (error, cameraInfo: camera.CameraStatusInfo) => {
        if (cameraInfo.camera.cameraId === this.mCameraContext?.getCamera().cameraId &&
          cameraInfo.status === camera.CameraStatus.CAMERA_STATUS_AVAILABLE &&
        this.mCameraInput?.getIsDuringCloseDelay()) {
          HiLog.w(TAG, 'close delay end camera input set to null');
          this.mCameraInput = null;
        }
        if (cameraInfo.status === CAMERASTAUS) {
          HiLog.w(TAG, 'cameraStatus error back');
          workerCallback.recoveryRestartApp();
        }
        workerCallback.onCameraStatus(cameraInfo.status);
      });
      this.mCameraManager.on('cameraMute', (error, callback: boolean) => {
        HiLog.i(TAG, 'cameraMute on');
        HiLog.i(TAG, 'cameraMute disabling');
        workerCallback.superPrivacyModeEnabled(callback);
      });
    } catch (error) {
      HiLog.e(TAG, `getCameraManager error: ${simpleStringify(error)}`);
    }
  }

  public initCameraList(): void {
    this.mCameraDeviceManager.initCameraList(this.mCameraManager);
  }

  public async createCameraInput(message: CameraInputMessage): Promise<void> {
    HiLog.i(TAG, 'createCameraInput begin.');
    this.currentMode = message.mode;
    const targetCamera: camera.CameraDevice = this.mCameraDeviceManager.getCameraWithMessage(message);
    this.mCameraInput = new CameraInputWrap();
    HiLog.i(TAG, `createCameraInput position: ${message.cameraPosition},Device:${simpleStringify(targetCamera)}.`);
    await this.mCameraInput.open(targetCamera, this.mCameraManager, this.pickerInfo);
    if (!this.mCameraContext) {
      this.mCameraContext = CameraContext.getInstance();
    }
    this.mCameraContext.setCamera(targetCamera);
    HiLog.i(TAG, 'createCameraInput end.');
  }

  public hasCameraInput(): boolean {
    return this.mCameraInput?.getInput() && this.mSession?.hasInput();
  }

  public async closeInput(isNeedDelayClose?: boolean): Promise<void> {
    if (!this.mCameraInput) {
      return;
    }
    HiLog.i(TAG, 'closeInput begin.' + JSON.stringify(this.mCameraContext.getCamera()));
    await this.mCameraInput.close(this.mCameraContext.getCamera(), false, isNeedDelayClose);
    // @ts-ignore
    if (!isNeedDelayClose || !this.mCameraContext.getCamera()?.isRetractable) {
      HiLog.i(TAG, 'cameraInput null.');
      this.mCameraInput = null;
      this.mCameraContext.closeCamera();
    }
    HiLog.i(TAG, 'closeInput end.');
  }

  public getCameraInput(): CameraInputWrap {
    return this.mCameraInput;
  }

  public getCameraInputType(): camera.CameraType {
    if (!this.mCameraContext || !this.mCameraContext.getCamera()) {
      HiLog.i(TAG, 'getCameraInputType default');
      return camera.CameraType.CAMERA_TYPE_DEFAULT;
    }
    return this.mCameraContext.getCamera().cameraType;
  }

  public getCameraInputEquivalentFocalLength(): number {
    if (!this.mCameraContext || !this.mCameraContext.getCamera()) {
      HiLog.i(TAG, 'getCameraInputType default');
      return -1;
    }
    // @ts-ignore
    return this.mCameraContext.getCamera()?.equivalentFocalLength[0];
  }

  public isCanReuseCameraInput(message: SessionMessage): boolean {
    HiLog.i(TAG, `isCanReuseCameraInput mCameraManager:${!this.mCameraManager},
      mCameraDeviceManager: ${!this.mCameraDeviceManager}, mCameraInput: ${!this.mCameraInput},
      mCameraContext: ${!this.mCameraContext}, getCamera: ${!this.mCameraContext?.getCamera()}`);
    if (!this.mCameraManager || !this.mCameraDeviceManager || !this.mCameraInput || !this.mCameraContext ||
      !this.mCameraContext?.getCamera()) {
      HiLog.i(TAG, 'isCanReuseCameraInput camera is null');
      return false;
    }
    if (!this.isCommit) {
      HiLog.i(TAG, 'isCanReuseCameraInput: false (no successful commit yet; e.g. after ACTION_INIT only)');
      return false;
    }
    if (this.mCameraInput?.getIsDuringCloseDelay()) {
      HiLog.i(TAG, 'isCanReuseCameraInput getIsDuringCloseDelay');
      return false;
    }
    if (this.closeCameraAfterCapture) {
      this.closeCameraAfterCapture = false;
      HiLog.i(TAG, 'isCanReuseCameraInput closeCameraAfterCapture');
      return false;
    }
    if (message.tagMessage?.isBackSelfie) {
      HiLog.i(TAG, 'isCanReuseCameraInput isBackSelfie or is panorama');
      return false;
    }
    const targetCamera: camera.CameraDevice | undefined =
      this.mCameraDeviceManager?.getCameraWithMessage(message.cameraInputMessage);
    const curDevice: camera.CameraDevice | undefined = this.mCameraContext?.getCamera();
    if (!targetCamera || !curDevice) {
      HiLog.i(TAG, 'isCanReuseCameraInput target or cur device missing');
      return false;
    }
    HiLog.i(TAG, 'targetCamera: ' + targetCamera.cameraId);
    HiLog.i(TAG, 'curCamera: ' + curDevice.cameraId);
    const reuse: boolean = targetCamera.cameraId === curDevice.cameraId;
    HiLog.i(TAG, `isCanReuseCameraInput RESULT: ${reuse}`);
    return reuse;
  }

  public async createPreviewOutput(previewMessage: PreviewOutputMessage): Promise<void> {
    HiLog.begin(TAG, 'createPreviewOutput');
    this.mPreviewOutput = new PreviewOutputWrap(this.mCameraDeviceManager, this.mCameraContext);
    if (previewMessage.previewSurfaceId) {
      this.mPreviewOutput.init(previewMessage.previewProfile, previewMessage.previewSurfaceId, this.mCameraManager);
    } else {
      this.mPreviewOutput.initDeferred(previewMessage.previewProfile, this.mCameraManager);
    }
    if (previewMessage.collaborateSurfaceId) { // 本是已开启镜像智拍状态,重启流直接带下,不再走动态配流
      this.createCollaboratePreviewOut({
        previewSurfaceId: previewMessage.collaborateSurfaceId,
        previewProfile: previewMessage.previewProfile
      });
    } else {
      this.mCollaboratePreviewOutput = null;
    }
    HiLog.end(TAG, 'createPreviewOutput');
  }

  private getCollaborateControlPreviewProfile(originProfile: camera.Profile, scenceMode: camera.SceneMode,
    device: camera.CameraDevice): camera.Profile {
    HiLog.i(TAG, `originProfile: ${JSON.stringify(originProfile)}`);
    // 手表请求的分辨率手机可能不支持，从支持的分辨率中选择一个合适的分辨率
    const aspect = this.mSessionMessage?.tagMessage.aspectRatio;
    let allProfiles = this.mCameraManager.getSupportedOutputCapability(device, scenceMode);
    const mode = this.mSessionMessage.tagMessage.mode;
    return CollaborateControlService.getSupportPreviewProfile(originProfile, allProfiles.previewProfiles, mode, aspect);
  }

  public async createCollaborateControlPreviewOut(previewMessage: PreviewOutputMessage): Promise<void> {
    HiLog.begin(TAG, 'createCollaborateControlPreviewOut');
    if (previewMessage.previewProfile) {
      let device = this.mCameraDeviceManager.getCameraWithMessage(this.mSessionMessage.cameraInputMessage);
      const cameraModeMessage: App2CameraModeMessage = {
        outputType: this.mSessionMessage.tagMessage.outputType,
        isSuperSlowMotion: false,
      };
      let sceneMode = ModeTransform.modeType2SceneMode(this.mSessionMessage.tagMessage.mode, cameraModeMessage);
      let profile = this.getCollaborateControlPreviewProfile(previewMessage.previewProfile, sceneMode, device);
      HiLog.i(TAG, `createCollaborateControlPreviewOut ${profile.size.height}`);
      this.mCollaborateControlPreviewOutput = new PreviewOutputWrap(this.mCameraDeviceManager, this.mCameraContext);
      if (previewMessage.previewSurfaceId) {
        this.mCollaborateControlPreviewOutput.init(profile, previewMessage.previewSurfaceId, this.mCameraManager);
      } else {
        this.mCollaborateControlPreviewOutput.initDeferred(profile, this.mCameraManager);
      }
    }
    HiLog.end(TAG, 'createCollaborateControlPreviewOut')
  }

  public async stopAndReleaseCollaborateControlPreviewOutput(): Promise<void> {
    if (!this.mCollaborateControlPreviewOutput) {
      return;
    }
    HiLog.i(TAG, 'stopAndReleaseCollaborateControlPreviewOutput begin.');
    await this.mCollaborateControlPreviewOutput.previewOutputStop();
    await this.mCollaborateControlPreviewOutput.release();
    this.mSession.clearCollaborateControlPreviewOutput();
    this.mCollaborateControlPreviewOutput = undefined;
    HiLog.i(TAG, 'stopAndReleaseCollaborateControlPreviewOutput end.');
  }

  public async stopPreviewOutput(): Promise<void> {
    if (!this.mPreviewOutput) {
      HiLog.i(TAG, 'stopPreviewOutput return.');
      return;
    }
    HiLog.i(TAG, 'stopPreviewOutput begin.');
    await this.mPreviewOutput.previewOutputStop();
    HiLog.i(TAG, 'stopPreviewOutput end.');
  }

  public async releasePreviewOutput(): Promise<void> {
    if (!this.mPreviewOutput) {
      HiLog.i(TAG, 'releasePreviewOutput return.');
      return;
    }
    HiLog.i(TAG, 'releasePreviewOutput begin.');
    await this.mPreviewOutput.release();
    this.mPreviewOutput = null;
    HiLog.i(TAG, 'releasePreviewOutput end.');
  }

  private async initFileForTimelapse(): Promise<void> {
    HiLog.begin(TAG, 'initFile');
    try {
      const mediaLibrary = await modulesManager.getMediaLibrary();
      this.mPrepareFile = await mediaLibrary.createVideoFile();
      if (!this.mPrepareFile) {
        HiLog.e(TAG, 'createVideoFile mediaLibrary createAsset error: photoAsset undefined.');
        return;
      }
      let mUri = this.mPrepareFile.uri;
      HiLog.w(TAG, `VideoOutput init videoFileUri: ${mUri}.`);
      this.mTimelapseFd = await this.mPrepareFile.open('rw');
      HiLog.w(TAG, `VideoOutput init fd: ${this.mTimelapseFd}, displayName: ${this.mPrepareFile.displayName}.`);
    } catch (err) {
      HiLog.e(TAG, `create VideoFd err: ${err}.`);
    } finally {
      HiLog.end(TAG, 'initFile');
    }
  }

  private async initFileForTimelapseChange(): Promise<void> {
    HiLog.begin(TAG, 'initFile');
    try {
      const mediaLibrary = await modulesManager.getMediaLibrary();
      this.mPrepareFileChange = await mediaLibrary.createVideoFile();
      if (!this.mPrepareFileChange) {
        HiLog.e(TAG, 'createVideoFile mediaLibrary createAsset error: photoAsset undefined.');
        return;
      }
      let mUri = this.mPrepareFileChange.uri;
      HiLog.w(TAG, `VideoOutput init videoFileUri: ${mUri}.`);
      this.mTimelapseFdChange = await this.mPrepareFileChange.open('rw');
      HiLog.w(TAG,
        `VideoOutput init fd: ${this.mTimelapseFdChange}, displayName: ${this.mPrepareFileChange.displayName}.`);
    } catch (err) {
      HiLog.e(TAG, `create VideoFd err: ${err?.code}.`);
    } finally {
      HiLog.end(TAG, 'initFile');
    }
  }

  onImageArrival(receiver: image.ImageReceiver): void {
    receiver.on('imageArrival', () => {
      receiver.readNextImage((err: BusinessError, nextImage: image.Image) => {
        if (err || nextImage === undefined) {
          HiLog.d(TAG, 'read next image failed');
          return;
        }
        nextImage.getComponent(image.ComponentType.JPEG, (err: BusinessError, imgComponent: image.Component) => {
          this.onBufferReceived(err, imgComponent, nextImage);
        });
      });
    });
  }

  private onBufferReceived(err: BusinessError<void>, imgComponent: image.Component, nextImage: image.Image): void {
    if (err || imgComponent === undefined) {
      HiLog.w(TAG, 'Get component failed');
      return;
    }
    if (imgComponent && imgComponent.byteBuffer as ArrayBuffer) {
      let nowPhotoTime = systemDateTime.getTime(false);
      this.lastImgComponent = imgComponent;
      this.pushBufferToNative(nowPhotoTime, imgComponent);
    }
    nextImage.release();
  }

  private async pushBufferToNative(nowPhotoTime: number, imgComponent: image.Component): Promise<void> {
    if ((this.isTimeLapseFrontStarted && nowPhotoTime - this.mLastPhotoTime >= this.timeLapseFrontInterval) ||
    this.isTimeLapseFrontStopping || this.isTimeLapseFrontFirstFrame) {
      this.isTimeLapseFrontFirstFrame = false;
      this.mLastPhotoTime = nowPhotoTime;
      this.timeLapseFrontFrameCount++;
      if (this.timeLapseFrontFrameCount >= 1200) {
        this.timeLapseFrontFrameCount = 600;
        this.timeLapseFrontInterval *= 2;
      }
      HiLog.d(TAG, `pushBufferToNative: ${this.photoBufferState}, ${this.fdNeedRelease}`);
      if (this.photoBufferState === -1 && this.fdNeedRelease !== -1) {
        this.isTimeLapseFrontStopping = false;
        const mediaLibrary = await modulesManager.getMediaLibrary();
        if (this.fdNeedRelease === 0) {
          this.fdNeedRelease = -1;
          HiLog.i(TAG, `will close fd: ${this.mTimelapseFd}`);
          await this.mPrepareFileChange?.close(this.mTimelapseFdChange);
          workerCallback.videoUri(this.mPrepareFileChange?.uri);
          await mediaLibrary.saveTimeLapseFrontLocation(this.mPrepareFileChange, this.mTimeLapseFrontLocationMessage);
          this.mPrepareFileChange = undefined;
          this.deleteTimeLapseFrontVideoUri(this.mPrepareFile);
          this.mPrepareFile = undefined;
          HiLog.d(TAG, 'file fd closed');
        } else {
          this.fdNeedRelease = -1;
          HiLog.i(TAG, `will close fd: ${this.mTimelapseFdChange}`);
          await this.mPrepareFile?.close(this.mTimelapseFd);
          workerCallback.videoUri(this.mPrepareFile?.uri);
          await mediaLibrary.saveTimeLapseFrontLocation(this.mPrepareFile, this.mTimeLapseFrontLocationMessage);
          this.mPrepareFile = undefined;
          this.deleteTimeLapseFrontVideoUri(this.mPrepareFileChange);
          this.mPrepareFileChange = undefined;
          HiLog.d(TAG, 'file fd closed');
        }
        this.mTimelapseFrontReady = true;
        this.photoBufferState = 0;
        HiLog.d(TAG, 'fdNeedRelease: ' + this.fdNeedRelease);
      }
    }
  }

  private async deleteTimeLapseFrontVideoUri(asset: photoAccessHelper.PhotoAsset): Promise<void> {
    if (asset === undefined) {
      HiLog.e(TAG, 'asset is null, deleteTimeLapseFrontVideoUri error.');
      return;
    }
    HiLog.begin(TAG, 'deleteTimeLapseFrontVideoUri');
    const mediaLibrary = await modulesManager.getMediaLibrary();
    await mediaLibrary.deleteVideoAsset(asset.uri);
    HiLog.end(TAG, 'deleteTimeLapseFrontVideoUri');
  }

  private createCollaboratePreviewOut(previewMessage: PreviewOutputMessage): void {
    HiLog.i(TAG, `createCollaboratePreviewOut surfaceId: ${previewMessage.previewSurfaceId}.`);
    this.mCollaboratePreviewOutput = new PreviewOutputWrap(this.mCameraDeviceManager, this.mCameraContext);
    this.mCollaboratePreviewOutput.initCollaborate(previewMessage.previewProfile, previewMessage.previewSurfaceId,
      this.mCameraManager);
  }

  public getPhotoOutput(): PhotoOutputWrap {
    return this.mPhotoOutput;
  }

  public hasPreviewSurface(): boolean {
    return this.mPreviewOutput.hasSurface();
  }

  public addDeferredSurface(surfaceId: string): void {
    if (!this.mPreviewOutput) {
      return;
    }
    HiLog.i(TAG, 'addDeferredSurface');
    this.mPreviewOutput.addDeferredSurface(surfaceId);
  }

  public swapDeferredSurface(surfaceId: string): void {
    if (!this.mPreviewOutput) {
      return;
    }
    HiLog.i(TAG, 'swapDeferredSurface');
    this.mPreviewOutput.swapDeferredSurface(surfaceId);
  }

  public addMixDeferredSurface(mixSurfaceId: string): void {
    if (!this.mPanoramaMinPreviewOutput) {
      return;
    }
  }

  public hasSession(): boolean {
    return !!this.mSession;
  }

  public async createPhotoOutput(photoProfile: camera.Profile, savePhotoFormat: camera.CameraFormat,
    isProRawDelivery: boolean): Promise<void> {
    HiLog.begin(TAG, 'createPhotoOutput');
    this.mPhotoOutput = new PhotoOutputWrap(this.mCameraDeviceManager, this.mCameraContext);
    await this.mPhotoOutput.init(photoProfile, this.mCameraManager, savePhotoFormat, isProRawDelivery, this.pickerInfo);
    HiLog.end(TAG, 'createPhotoOutput');
  }

  public async releasePhotoOutput(): Promise<void> {
    if (!this.mPhotoOutput) {
      return;
    }
    HiLog.i(TAG, 'releasePhotoOutput begin.');
    await this.mPhotoOutput.release();
    this.mPhotoOutput = null;
    HiLog.i(TAG, 'releasePhotoOutput end.');
  }


  public async switchCollaborate(previewMessage: PreviewOutputMessage, tagMessage: TagMessage): Promise<void> {
    HiLog.i(TAG, `switchCollaborate previewMsg: ${previewMessage}, mCollaborate: ${this.mCollaboratePreviewOutput}.`);
    if (previewMessage) {
      this.createCollaboratePreviewOut(previewMessage);
      if (this.mSession) {
        await this.mSession.dynamicAddPreviewOutput(this.mCollaboratePreviewOutput, tagMessage);
        this.mSession.setCollaboratePreviewOutput(this.mCollaboratePreviewOutput);
      }
    } else {
      if (!this.mCollaboratePreviewOutput) {
        return;
      }
      if (this.mSession) {
        HiLog.i(TAG, 'switchCollaborate session is not null');
        await this.mSession.dynamicRemovePreviewOutput(this.mCollaboratePreviewOutput, tagMessage);
        this.mSession.clearCollaboratePreviewOutput();
      }
      this.mCollaboratePreviewOutput = null;
    }
  }

  public async switchWatchCollaborateControl(previewMessage: PreviewOutputMessage,
    tagMessage: TagMessage): Promise<void> {
    HiLog.i(TAG, `switchWatchCollaborateControl previewMessage: ${previewMessage}.`);
    if (previewMessage) {
      this.createCollaborateControlPreviewOut(previewMessage);
      await this.mSession.dynamicAddPreviewOutput(this.mCollaborateControlPreviewOutput, tagMessage);
      this.mSession.setCollaborateControlPreviewOutput(this.mCollaborateControlPreviewOutput);
    } else {
      if (!this.mCollaborateControlPreviewOutput) {
        return;
      }
      await this.mSession.dynamicRemovePreviewOutput(this.mCollaborateControlPreviewOutput, tagMessage);
      this.mSession.clearCollaborateControlPreviewOutput();
      this.mCollaborateControlPreviewOutput = null;
    }
  }

  public async createSession(hasPhotoProfile: boolean, tagMessage: TagMessage): Promise<SessionWrap> {
    workerCallback.onUpdateValidFrameFlag(false);
    HiLog.begin(TAG, 'createSession');
    this.isCommit = false;
    this.currentMode = tagMessage.mode;
    this.mTagMessage = tagMessage;
    this.mCameraContext.setIsSupportPhotoOutput(hasPhotoProfile);
    const cameraModeMessage: App2CameraModeMessage = {
      outputType: tagMessage.outputType,
    };
    this.mSession = new SessionWrap(this.mCameraManager, this.currentMode, cameraModeMessage, this.mCameraContext);
    this.mSession.setCameraInput(this.mCameraInput);
    HiLog.end(TAG, 'createSession');
    return this.mSession;
  }

  // @ts-ignore
  public getSupportedNightSubModeTypes(): camera.NightSubModeType[] {
    return this.mSession.getSupportedNightSubModeTypes();
  }

  // @ts-ignore
  public setNightSubModeType(subMode: camera.NightSubModeType): void {
    this.mSession.setNightSubModeType(subMode);
  }

  public setLocation(location: geoLocationManager.Location): void {
    this.mSession.setLocation(location);
  }

  // @ts-ignore
  public getSessionConflictFunctions(): camera.NightPhotoConflictFunctions[] {
    return this.mSession.getSessionConflictFunctions();
  }

  public async commitSession(tagMessage: TagMessage, videoMessage: VideoOutputMessage):
    Promise<SessionInfo> {
    HiLog.i(TAG, 'commitSession begin.');
    this.setSessionParam();
    try {
      await this.mSession.commitSession(tagMessage, this.mSessionMessage.cameraInputMessage.cameraPosition,
        this.pickerInfo?.isPicker);
    } catch (err) {
      HiLog.e(TAG, `DEBUGcommitSession err: ${err}.`);
      this.isCommit = false;
      return undefined;
    }
    const targetCamera: camera.CameraDevice = this.mCameraContext.getCamera();
    this.isCommit = true;
    this.afterSessionCommitConfig(tagMessage, videoMessage);
    try {
      await this.mSession.start(tagMessage);
    } catch (err) {
      HiLog.e(TAG, `start err: ${err}.`);
      return undefined;
    }
    workerCallback.onUpdateStartPreviewTime(Date.now());
    // workerCallback.onStartCameraDuration();
    workerCallback.onStartCameraPositionAndMode(targetCamera.cameraPosition, this.currentMode);
    this.afterSessionStart();
    /*    const isFront: boolean = targetCamera.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT ||
          targetCamera.cameraPosition === camera.CameraPosition.CAMERA_POSITION_COLLAPS_INNER;*/
    return this.getSessionMessage();
  }

  private initTimeLapseFrontStatus() {
    this.isTimeLapseFrontStarted = false;
    this.isTimeLapseFrontStopping = false;
    this.isTimeLapseFrontFirstFrame = false;
  }

  public async setAndAddSessionInput(tagMessage: TagMessage): Promise<void> {
    this.mSession.setCameraInput(this.mCameraInput);
    this.mSession.beginConfig();
    this.mSession.addInput(tagMessage);
  }

  public getSupportedColorSpaces(): colorSpaceManager.ColorSpace[] {
    return this.mSession.getSupportedColorSpaces();
  }

  private setSessionParam(): void {
    this.mSession.setPreviewOutput(this.mPreviewOutput);
    this.mSession.setPreviewOutputForTimeLapse(this.mPreviewOutputForTimeLapse);
    if (this.mCollaboratePreviewOutput && this.mCollaboratePreviewOutput.getOutput()) {
      HiLog.i(TAG, 'setSessionParam setCollaboratePreviewOutput');
      this.mSession.setCollaboratePreviewOutput(this.mCollaboratePreviewOutput);
    }
    if (this.mCollaborateControlPreviewOutput) {
      this.mSession.setCollaborateControlPreviewOutput(this.mCollaborateControlPreviewOutput);
    }
    this.mSession.setPhotoOutput(this.mPhotoOutput);
    this.mSession.setMetadataOutput(this.mMetadataOutput);
  }

  private afterSessionCommitConfig(tagMessage: TagMessage, videoMessage: VideoOutputMessage): void {
    if (!tagMessage) {
      return;
    }
    if (tagMessage.pipSurface) {
      HiLog.i(TAG, `pipSurface: ${tagMessage.pipSurface}.`);
      this.addPipSurface(tagMessage.pipSurface);
    }
    if (tagMessage.globalExposure) {
      this.mSession.setExposureBias(tagMessage.globalExposure);
    }
    if (tagMessage.mode === ModeType.VIDEO) {
      if (!!videoMessage.filter) {
        this.videoModule.setFilter(videoMessage.filter);
      }
      this.videoModule.setWatermark(videoMessage.isAddWaterMark, videoMessage.config.rotation);
    }
    if (videoMessage.mirrorValue !== undefined) {
      this.videoModule.enableMirror(videoMessage.mirrorValue);
    }
    if (videoMessage.isAutoFrameRate !== undefined) { //开关动态帧率
      this.videoModule.enableAutoVideoFrameRate(videoMessage.isAutoFrameRate);
    }
    this.checkRotateVideoOutput(videoMessage);
  }

  private async checkRotateVideoOutput(videoMessage: VideoOutputMessage): Promise<void> {
    if (!videoMessage?.keepVideoFlowing) {
      return;
    }
    if (videoMessage.preferencesMirror) {
      const isMirrorSupported = VideoModule.getInstance().isMirrorSupported();
      const shouldMirror =
        isMirrorSupported && videoMessage.mirrorValue !== undefined && videoMessage.mirrorValue;
      HiLog.d(TAG, shouldMirror ? 'restartContinuumPreview enable mirror' : 'disable mirror');
      this.mirrorVideoOutput(shouldMirror);
      await this.rotateVideoOutput(-1, videoMessage); //为了重新prepareAccurately，下发摄像头位置，不然水印有问题
    } else {
      this.mirrorVideoOutput(false);
      HiLog.d(TAG, 'restartContinuumPreview rotation value: ' + videoMessage?.config?.rotation);
      const rotation =
        videoMessage.isVideoRotation && (videoMessage?.config?.rotation === camera.ImageRotation.ROTATION_90 ||
          videoMessage?.config?.rotation === camera.ImageRotation.ROTATION_270) ? 180 : 0;
      await this.rotateVideoOutput(rotation, videoMessage);
    }
  }

  private afterSessionStart(): void {
    if (this.mSession.isImageStabilizationGuideSupported()) {
      HiLog.i(TAG, 'enable imageStabilizationGuide');
      this.mSession.enableImageStabilizationGuide(true);
    }
    this.doPreLaunchOperation({ mode: this.currentMode, isNeedSaveRestore: true, isLegalSaveRestore: true }, true);
  }

  private getSessionMessage(): SessionInfo {
    return {
      canAddOutput: this.mSession.getCanAddOutput(),
      hasFlash: this.mSession.hasFlash(),
      zoomRatioRange: this.mSession.getZoomRatioRange(),
      isDeferPhoto: this.mSession.getIsDeferPhoto(),
      zoomPointInfo: this.mSession.getZoomPointInfo(),
      virtualApertures: this.mSession.getSupportedVirtualApertures(),
      physicalApertures: this.mSession.getSupportedPhysicalApertures(),
      focusDistance: this.mSession.getFocusDistance(),
      defaultColorStyles: this.mSession.getDefaultColorStyleSettings(),
      timeLapseIntervalRange: this.mSession.getTimeLapseIntervalRange(),
      isVideoMirrorSupported: this.videoModule.isMirrorSupported(),
      isQuickThumbnailSupported: this.mPhotoOutput?.getIsQuickThumbnailSupported(),
      isAutoVideoFrameRateSupported: this.videoModule.isAutoVideoFrameRateSupported(),
      isPreRecordingSupported: this.videoModule.isPreRecordingSupported(),
      isCompositionSuggestionSupported: this.mSession.getIsCompositionSuggestionSupported(),
      isLogAssistanceSupported: this.mPreviewOutput?.isLogAssistanceSupported(),
    };
  }

  public async removeInput(): Promise<void> {
    if (!this.mSession) {
      return;
    }
    await this.mSession.removeInput();
  }

  public async preSwitchCamera(cameraMessage: CameraInputMessage): Promise<void> {
    HiLog.begin(TAG, 'preSwitchCamera');
    const targetCamera: camera.CameraDevice = this.mCameraContext.getCamera();
    HiLog.i(TAG, `getSessionMessage end, message: ${simpleStringify(cameraMessage)}.`);
    const preSwitchTargetCamera: camera.CameraDevice = this.mCameraDeviceManager.getCameraWithMessage(cameraMessage);
    HiLog.i(TAG, `preSwitchCamera  preSwitchTargetCamera: ${preSwitchTargetCamera}.`);
    if (preSwitchTargetCamera !== undefined) {
      HiLog.i(TAG,
        `preSwitchCamera,curCamera: ${targetCamera?.cameraId}, preSwitchTargetCamera: ${preSwitchTargetCamera.cameraId}.`);
      try {
        this.mCameraManager?.preSwitchCamera(preSwitchTargetCamera.cameraId);
      } catch (e) {
        HiLog.e(TAG,
          `preSwitchCamera, preSwitchCamera,curCamera: ${targetCamera?.cameraId}, preSwitchTargetCamera: ${preSwitchTargetCamera.cameraId} failed, err: ${JSON.stringify(e)}`)
      }
    } else {
      HiLog.d(TAG, 'preSwitchTargetCamera is null');
    }
    HiLog.end(TAG, 'preSwitchCamera');
  }

  public async releaseSession(): Promise<void> {
    if (!this.mSession) {
      HiLog.e(TAG, 'release session undefined.');
      return;
    }
    HiLog.i(TAG, 'releaseSession begin.');
    const beginTime: number = Date.now();
    await this.mSession.release();
    const duration: number = Date.now() - beginTime;
    HiLog.i(TAG, `cameraDestroySessionTimeout duration: ${duration}.`);
    workerCallback.onCameraDestroySessionTimeout(duration);
    this.mSession = null;
    if (this.mPreviewOutput.hasSurface()) {
      const mediaLibrary = await modulesManager.getMediaLibrary();
      mediaLibrary.clearQueueFileAsset();
    }
    HiLog.i(TAG, 'releaseSession end.');
  }

  public async afterStartupInit(): Promise<void> {
    if (!this.mPreviewOutput.hasSurface()) {
      return;
    }
    await modulesManager.getMediaLibrary();
    await RecorderWrap.getInstance().create();
  }

  public async resolveAVRecorder(isPanVideoOutput: boolean): Promise<void> {
    if (!isPanVideoOutput) {
      await RecorderWrap.getInstance().resetToUnprepared();
    }
  }

  public async takePicture(cameraSetting: camera.PhotoCaptureSetting, captureMessage: CaptureMessage): Promise<void> {
    if (!this.mSession) {
      HiLog.w(TAG, 'takePicture session is release.');
      return;
    }
    if (!this.mPhotoOutput) {
      HiLog.w(TAG, 'takePicture photoOutput is release.');
      return;
    }
    HiLog.begin(TAG, 'takePicture');
    HiLog.i(TAG, 'SHOT2SEE takePicture invoke');
    await this.mPhotoOutput.capture(cameraSetting, captureMessage);
    HiLog.end(TAG, 'takePicture');
  }

  public setDisplayRotate(displayDirection: number): void {
    this.displayDirection = displayDirection;
  }

  public async startTimeLapse(recordMessage: TimeLapseRecordMessage): Promise<void> {
    const cameraPosition = this.mCameraContext.getCamera()?.cameraPosition;
    const isBack: boolean = cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK;
    HiLog.i(TAG, `timeLapseVideo start isBackCamera: ${isBack}`);
    if (isBack) {
      this.mSession.timeLapseTryAe(recordMessage.captureInterval, recordMessage.isSpeedAuto);
      return;
    } else {
      this.timeLapseFrontInterval = 500;
      this.timeLapseFrontFrameCount = 0;
      this.fdNeedRelease = -1;
      this.photoBufferState = 0;
      this.isTimeLapseFrontStarted = true;
      this.isTimeLapseFrontStopping = false;
      this.isTimeLapseFrontFirstFrame = true;
      this.mTimelapseFrontReady = false;
      await this.initFileForTimelapse();
      await this.initFileForTimelapseChange();
      if (recordMessage.locationMessage) {
        this.mTimeLapseFrontLocationMessage = recordMessage.locationMessage;
      } else {
        this.mTimeLapseFrontLocationMessage = undefined;
      }
      // front capture
      let rotate: number = this.getTimeLapseRotate(recordMessage);
      if (this.mTimelapseFd !== undefined && this.mPrepareFile !== undefined) {
        // TimelapseNative.imageReceiverInit(this.realWidth, this.realHeight, 1, this.mTimelapseFd,
        //   this.mPrepareFile.displayName.substring(0, this.mPrepareFile.displayName.length - 4), this.mTimelapseFdChange,
        //   this.mPrepareFileChange.displayName.substring(0, this.mPrepareFileChange.displayName.length - 4),
        //   recordMessage.isFrontMirror, rotate, recordMessage.isAddWaterMark);
        // HiLog.i(TAG, `imageReceiverInit rotate: ${rotate}`);
      }
    }
  }

  private getTimeLapseRotate(recordMessage: TimeLapseRecordMessage): number {
    let rotate: number = this.displayDirection;
    // 展开态关闭旋转锁定 特殊处理
    if (!recordMessage?.isLockRotation && recordMessage?.isLandScapeFront) {
      switch (recordMessage?.rotation) {
        case WindowDirection.RIGHT:
          rotate = camera.ImageRotation.ROTATION_270;
          break;
        case WindowDirection.TOP:
          rotate = camera.ImageRotation.ROTATION_180;
          break;
        case WindowDirection.BOTTOM:
          rotate = camera.ImageRotation.ROTATION_90;
          break;
        default:
          rotate = this.displayDirection;
      }
    }
    // 展开态开启旋转锁定
    if (recordMessage?.isLockRotation && recordMessage?.isLandScapeFront) {
      switch (recordMessage?.direction) {
        case WindowDirection.RIGHT:
          rotate = camera.ImageRotation.ROTATION_90;
          break;
        case WindowDirection.TOP:
          rotate = camera.ImageRotation.ROTATION_0;
          break;
        case WindowDirection.BOTTOM:
          rotate = camera.ImageRotation.ROTATION_180;
          break;
        case WindowDirection.LEFT:
          rotate = camera.ImageRotation.ROTATION_270;
          break;
        default:
          rotate = this.displayDirection;
      }
    }
    HiLog.i(TAG, `getTimeLapseRotate, orientation: ${recordMessage?.rotation}, direction: ${recordMessage?.direction},
     rotateAngle: ${rotate}.`);
    return rotate;
  }

  public stopTimeLapse(): void {
    return;
    let surfaceIdOrigin: string = RecorderWrap.getInstance().getSurfaceId();
    const cameraPosition = this.mCameraContext.getCamera()?.cameraPosition;
    const isBack: boolean = cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK;
    HiLog.i(TAG, `timeLapseVideo stop isBackCamera: ${isBack}`);
    if (isBack) {
      this.mSession.stopCaptureLoop();
      return;
    } else {
      HiLog.i(TAG, 'stopEncodingVideo begin');
      // front capture
      // this.fdNeedRelease = TimelapseNative.stopEncodingVideo();
      this.isTimeLapseFrontStopping = true;
      this.isTimeLapseFrontStarted = false;
      this.isTimeLapseFrontFirstFrame = false;
      HiLog.i(TAG, 'stopEncodingVideo end');
    }
  }

  /**
   * 前置延时摄影录像过程中手机，后续buffer无法送上来，需要手动pushBuffer结束录制
   */
  public collapsChangeFrontTimeLapseStop(): void {
    this.stopTimeLapse();
    let nowPhotoTime = systemDateTime.getTime(false);
    HiLog.i(TAG, 'collapsChangeFrontTimeLapseStop');
    this.pushBufferToNative(nowPhotoTime, this.lastImgComponent);
    this.frontTimeLapsePushBuffer(nowPhotoTime + TIME_LAPSE_DELAY_500, TIME_LAPSE_DELAY_100);
    this.frontTimeLapsePushBuffer(nowPhotoTime + TIME_LAPSE_DELAY_1000, TIME_LAPSE_DELAY_200);
  }

  private frontTimeLapsePushBuffer(nowPhotoTime: number, delayTime: number): void {
    setTimeout(() => {
      HiLog.d(TAG, 'frontTimeLapsePushBuffer');
      this.pushBufferToNative(nowPhotoTime, this.lastImgComponent);
    }, delayTime);
  }

  public async createVideoOutput(message: VideoOutputMessage, tagMessage: TagMessage): Promise<void> {
    await this.videoModule.createOutput(message, tagMessage, this.mCameraManager, this.pickerInfo);
  }

  public async rotateVideoOutput(angles: number, message: VideoOutputMessage): Promise<void> {
    HiLog.d(TAG, `rotateVideoOutput begin angles: ${angles}.`);
    await this.videoModule.setRotation(angles, message);
    HiLog.d(TAG, 'rotateVideoOutput end.');
  }

  public mirrorVideoOutput(mirrorValue: boolean): void {
    HiLog.d(TAG, `mirrorVideoOutput begin mirrorValue: ${mirrorValue}.`);
    this.videoModule.enableMirror(mirrorValue);
    HiLog.d(TAG, 'mirrorVideoOutput end.');
  }

  public async releaseVideoOutput(): Promise<void> {
    HiLog.begin(TAG, 'releaseVideoOutput');
    await this.videoModule.release();
    HiLog.end(TAG, 'releaseVideoOutput');
  }

  public async startRecording(message: VideoOutputMessage, tagMessage: TagMessage): Promise<StartRecordResultType> {
    if (!message) {
      HiLog.e(TAG, 'video message undefined.');
      return {
        sessionMessage: undefined,
        isSuccess: false
      };
    }
    HiLog.i(TAG, `RECORD_TRACK startRecording.`);
    await this.videoModule.checkStartRecordingState(message, this.mCameraManager,
      async (oldOutput: camera.CameraOutput, output: camera.CameraOutput) => {
        await this.mSession.stop();
        await this.mSession.swapVideoOutput(oldOutput, output, tagMessage.outputType);
        this.afterSessionCommitConfig(tagMessage, message);
        await this.mSession.start(tagMessage);
        this.afterSessionStart();
      });
    await this.videoModule.setOutputSetting(message.config?.rotation);
    if (message.mirrorValue !== undefined) { //开关前置录像镜像
      this.videoModule.enableMirror(message.mirrorValue);
    }
    if (message.isAutoFrameRate !== undefined) { //开关动态帧率
      this.videoModule.enableAutoVideoFrameRate(message.isAutoFrameRate);
    }
    let isSuccess: boolean = false;
    HiLog.begin(TAG, 'startRecording');
    HiLog.i(TAG, `RECORD_TRACK startRecording, isPreRecord: ${message.isPreRecord}.`);
    if (message.isPreRecord) {
      isSuccess = await this.videoModule.startWithPreRecording();
    } else {
      isSuccess = await this.videoModule.start();
    }
    const mem = HideBugUtil.getPss();
    workerCallback.onVideoRecordingStatus(mem);
    HiLog.end(TAG, 'startRecording');
    return {
      sessionMessage: this.getSessionMessage(),
      isSuccess: isSuccess
    };
  }

  public async startRecorderRecording(previewRecordMessage: PreviewRecordOutputMessage,
    isSupportRealTimeFilter: boolean): Promise<StartRecordResultType> {
    if (!previewRecordMessage) {
      HiLog.e(TAG, 'video message undefined.');
      return {
        sessionMessage: undefined,
        isSuccess: false
      };
    }
    HiLog.i(TAG, 'service startRecordingPreview begin.');
    let tempMessage: VideoOutputMessage = {
      videoProfile: undefined,
      config: previewRecordMessage.config,
      mirrorValue: false,
      isAddFilter: false,
      isSupportVideoEdit: previewRecordMessage.isAddWaterMark,
      isSupportVideoWatermark: true,
      isAddWaterMark: previewRecordMessage.isAddWaterMark,
      isAutoFrameRate: true,
      isFlowingVideo: false,
      isSupportFrontWaterMark: previewRecordMessage.isSupportFrontWaterMark,
      isInSwipeRecording: true
    };
    const isHdr = this.mSessionMessage?.previewOutputMessage?.previewProfile?.format ===
    camera.CameraFormat.CAMERA_FORMAT_YCBCR_P010
      || this.mSessionMessage?.previewOutputMessage?.previewProfile?.format ===
      camera.CameraFormat.CAMERA_FORMAT_YCRCB_P010;
    if (isHdr) {
      tempMessage.config.profile.videoCodec = media.CodecMimeType.VIDEO_HEVC;
      tempMessage.config.profile.isHdr = true;
    }
    await RecorderWrap.getInstance().prepareAccurately(tempMessage, this.pickerInfo);
    HiLog.i(TAG, `mAVRecorder.prepareAccurately end.`);
    const recorderSurface: string = RecorderWrap.getInstance().getSurfaceId();
    HiLog.i(TAG, `startRecordingPreview surface: ${recorderSurface}, realTimeFilterSup: ${isSupportRealTimeFilter}`);
    if (isSupportRealTimeFilter) {
      HiLog.i(TAG, 'RealTimeFilter setPreviewRecordSurface');
    } else {
      HiLog.i(TAG, 'RealTimeRecordFilter setPreviewRecordSurface');
    }
    HiLog.begin(TAG, 'startRecordingPreview startRecording');
    const recorderStartSuccess = await RecorderWrap.getInstance().start();
    HiLog.end(TAG, 'startRecordingPreview startRecording');

    return {
      sessionMessage: this.getSessionMessage(),
      isSuccess: recorderStartSuccess
    };
  }

  public async stopRecording(validateThumbnail: boolean): Promise<void> {
    HiLog.begin(TAG, 'stopRecording');
    HiLog.i(TAG, 'RECORD_TRACK stopRecording');
    WorkerDataCache.getInstance().setValidateThumbnail(validateThumbnail);
    await this.videoModule.stop();
    if (this.currentMode === ModeType.VIDEO && this.mSessionMessage.videoOutputMessage.isFlowingVideo) {
      this.rotateVideoOutput(0, undefined);
    }
    HiLog.end(TAG, 'stopRecording');
  }

  public async stopRecorderRecording(isSupportRealTimeFilter: boolean, validateThumbnail: boolean): Promise<void> {
    HiLog.begin(TAG, 'stopRecording');
    WorkerDataCache.getInstance().setValidateThumbnail(validateThumbnail);
    await RecorderWrap.getInstance().releaseSurfaceWhenStopRecorderRecording();
    await RecorderWrap.getInstance().stop();
    HiLog.end(TAG, 'stopRecording');
  }

  public async pauseRecorderRecording(isSupportRealTimeFilter: boolean): Promise<void> {
    HiLog.begin(TAG, 'pauseRecorderRecording');
    await RecorderWrap.getInstance().pause();
    HiLog.end(TAG, 'pauseRecorderRecording');
  }

  public async pauseRecording(): Promise<void> {
    HiLog.begin(TAG, 'pauseRecording');
    await this.videoModule.pause();
    HiLog.end(TAG, 'pauseRecording');
  }

  public async resumeRecorderRecording(isSupportRealTimeFilter: boolean): Promise<void> {
    HiLog.begin(TAG, 'resumeRecorderRecording');
    await RecorderWrap.getInstance().resume();
    HiLog.end(TAG, 'resumeRecorderRecording');
  }

  public async resumeRecording(): Promise<void> {
    HiLog.begin(TAG, 'resumeRecording');
    await this.videoModule.resume();
    HiLog.end(TAG, 'resumeRecording');
  }

  public async deletePickerVideoFile(): Promise<void> {
    await RecorderWrap.getInstance().deletePickerVideoFile();
  }

  public resetVideoFileManagerUri(): void {
    RecorderWrap.getInstance().resetVideoFileManagerUri();
  }

  public async stopTimelapseRecording(isSupportRealTimeFilter: boolean, validateThumbnail: boolean): Promise<void> {
    HiLog.begin(TAG, 'stopRecording');
    WorkerDataCache.getInstance().setValidateThumbnail(validateThumbnail);
    await RecorderWrap.getInstance().stop();
    // TimelapseNative.startPreviewRecord(false);
    // TimelapseNative.setPreviewRecordSurface('');
    HiLog.end(TAG, 'stopRecording');
  }

  public async startTimelapseRecording(timelapseRecordMessage: TimeLapseRecordOutputMessage,
    isSupportRealTimeFilter: boolean): Promise<StartRecordResultType> {
    HiLog.i(TAG, `service startRecordingTimelapse ${isSupportRealTimeFilter}`);
    if (!timelapseRecordMessage) {
      HiLog.e(TAG, 'video message undefined.');
      return {
        sessionMessage: undefined,
        isSuccess: false
      };
    }
    if (this.mCameraContext?.getCameraPosition() === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      HiLog.i(TAG, 'startTimelapseRecording, time lapse video front, need not use recorder');
      return {
        sessionMessage: this.getSessionMessage(),
        isSuccess: true
      };
    }
    HiLog.i(TAG, 'service startRecordingTimelapse begin.');
    await RecorderWrap.getInstance().release();
    let tempMessage: VideoOutputMessage = {
      videoProfile: undefined,
      config: timelapseRecordMessage.config,
      mirrorValue: false,
      isAddFilter: false,
      isSupportVideoEdit: timelapseRecordMessage.isAddWaterMark,
      isSupportVideoWatermark: true,
      isAddWaterMark: timelapseRecordMessage.isAddWaterMark,
      isAutoFrameRate: true,
      isFlowingVideo: false,
      isSupportFrontWaterMark: false,
    };
    await RecorderWrap.getInstance().prepareAccurately(tempMessage);
    // Surface校验，如果在之前有过AVRecorder error重启，需要更换surface和videoOutput。
    const recorderSurface: string = RecorderWrap.getInstance().getSurfaceId();
    HiLog.i(TAG,
      `startRecordingTimelapse recorder surface: ${recorderSurface}, realTimeFilterSupport: ${isSupportRealTimeFilter}`);
    // TimelapseNative.setPreviewRecordSurface(recorderSurface);
    // TimelapseNative.startPreviewRecord(true);
    HiLog.begin(TAG, 'startRecordingTimelapse startRecording');
    const recorderStartSuccess = await RecorderWrap.getInstance().start();
    HiLog.end(TAG, 'startRecordingTimelapse startRecording');

    return {
      sessionMessage: this.getSessionMessage(),
      isSuccess: recorderStartSuccess
    };
  }

  public async createMetadataOutput(message: SessionMessage): Promise<void> {
    HiLog.i(TAG, 'createMetadataOutput begin.');
    this.mMetadataOutput = new MetadataOutputWrap(this.mCameraDeviceManager, this.mCameraContext);
    await this.mMetadataOutput.init(this.mCameraManager, message.metadataOutputMessage.metadataObjectTypeArr,
      message.tagMessage.mode, message.tagMessage.outputType, message.cameraInputMessage.cameraPosition,
      message.tagMessage.supportOnlyShowEye);
    HiLog.i(TAG, 'createMetadataOutput end.');
  }

  public async startMetadataOutput(): Promise<void> {
    if (!this.mMetadataOutput) {
      return;
    }
    HiLog.begin(TAG, 'startMetadataOutput');
    await this.mMetadataOutput.start();
    HiLog.end(TAG, 'startMetadataOutput');
  }

  public async stopMetadataOutput(): Promise<void> {
    if (!this.mMetadataOutput) {
      return;
    }
    HiLog.i(TAG, 'stopMetadataOutput begin.');
    await this.mMetadataOutput.stop();
    HiLog.i(TAG, 'stopMetadataOutput end.');
  }

  public async releaseMetadataOutput(): Promise<void> {
    if (!this.mMetadataOutput) {
      return;
    }
    HiLog.i(TAG, 'releaseMetadataOutput begin.');
    await this.mMetadataOutput.release();
    this.mMetadataOutput = null;
    HiLog.i(TAG, 'releaseMetadataOutput end.');
  }

  public async releaseCollaborateOutput(): Promise<void> {
    if (!this.mCollaboratePreviewOutput) {
      return;
    }
    HiLog.i(TAG, 'releaseCollaborateOutput begin.');
    await this.mCollaboratePreviewOutput.release();
    this.mCollaboratePreviewOutput = null;
    this.mSession.clearCollaboratePreviewOutput();
    HiLog.i(TAG, 'releaseCollaborateOutput end.');
  }

  // 暂停所有输出流
  public async stopOutput(): Promise<void> {
    await this.stopPreviewOutput();
    await this.stopAndReleaseCollaborateControlPreviewOutput();
    await this.stopMetadataOutput();
  }

  // 释放所有输出流
  public async releaseOutput(): Promise<void> {
    await this.releaseVideoOutput();
    await this.releasePhotoOutput();
    await this.releaseMetadataOutput();
    await this.releaseCollaborateOutput();
  }



  public async releaseCamera(isNeedDelayClose?: boolean): Promise<void> {
    if (!this.mSession) {
      HiLog.i(TAG, 'no session return');
      await this.closeInput();
      return;
    }
    HiLog.begin(TAG, 'releaseCamera');
    this.vlogIndex = -1;
    const executor: TaskExecutor = new TaskExecutor();
    executor.addTaskFunction(async () => {
      await this.stopOutput();
      await this.stopSession();

      await this.releaseOutput();
      HiLog.i(TAG, `releaseSession isNeedDelayClose: ${!isNeedDelayClose},
     isRetractable: ${!this.mCameraContext.getCamera()?.isRetractable}`);
      await this.closeInput(isNeedDelayClose);
      if (isNeedDelayClose && this.mCameraContext.getCamera()?.isRetractable) {
        await this.mSession.removeInput();
        // 恒星，进大图延迟收回场景closeDelay，一段时间后框架关停输入流，此处从session移出输入流，避免释放session框架立即关停
      }
      await this.releaseSession();
    });
    const beginTime: number = Date.now();
    await executor.executeTasks();
    const duration: number = Date.now() - beginTime;
    if (duration >= TIME_COST_MS_CAMERA_TIMEOUT) {
      HiLog.i(TAG, `closeCameraTimeout duration: ${duration}`);
      workerCallback.onCloseCameraTimeout(duration);
    }
    if (!isNeedDelayClose || !this.mCameraContext.getCamera()?.isRetractable) {
      HiLog.i(TAG, 'cameraManager null.');
      this.mCameraManager?.off('cameraStatus');
      this.mCameraManager = null;
    }
    HiLog.end(TAG, 'releaseCamera');
    return;
  }

  public setZoomRatio(zoomRatio: number): void {
    HiLog.d(TAG, 'setZoomRatio: ' + zoomRatio);
    if (!this.mSession) {
      HiLog.w(TAG, 'setZoomRatio mSession is release.');
      return;
    }
    this.mSession.setZoomRatio(zoomRatio);
  }

  public addPipSurface(pipSurfaceId: string): void {
    HiLog.i(TAG, `pipSurfaceId: ${pipSurfaceId}.`);
    if (this.isCommit) {
      this.mPreviewOutput?.addPipSurface(pipSurfaceId);
    }
  }

  public getZoomRatio(): number {
    if (!this.mSession) {
      HiLog.i(TAG, 'getZoomRatio mSession is release.');
      return 1;
    }
    const zoomRatio: number = this.mSession.getZoomRatio();
    return zoomRatio;
  }

  public isFocusModeSupported(focusMode: camera.FocusMode): boolean {
    if (!this.mSession) {
      HiLog.i(TAG, 'isFocusModeSupported mSession is release.');
      return false;
    }
    const isFocusModeSupported: boolean = this.mSession.isFocusModeSupported(focusMode);
    return isFocusModeSupported;
  }

  public setFocus(focusMode: number, focusPoint: camera.Point, focusValue?: number): void {
    HiLog.i(TAG, 'setFocus begin.');
    if (!this.mSession || !this.mSession.isFocusModeSupported(focusMode)) {
      HiLog.e(TAG, 'this.mCaptureSession is null or FocusMode is not Supported.');
      return;
    }
    this.mSession.setFocusMode(focusMode, focusPoint, focusValue);
  }

  public setExposure(data: ExposureData): void {
    HiLog.i(TAG, 'setExposure begin.');
    if (!this.mSession) {
      HiLog.e(TAG, 'this.mCaptureSession is null or setExposure is not Supported.');
      return;
    }
    this.mSession.setExposure(data);
  }

  public setMeteringPoint(focusPoint: camera.Point): void {
    this.mSession.setMeteringPoint(focusPoint);
  }

  public setFlashMode(flashMode: camera.FlashMode): void {
    this.mSession.setFlashMode(flashMode);
  }

  // @ts-ignore
  public setStitchingType(stitchingType: camera.StitchingType): void {
    this.mSession.setStitchingType(stitchingType);
  }

  // @ts-ignore
  public setStitchingDirection(stitchingDirection: camera.StitchingDirection): void {
    this.mSession.setStitchingDirection(stitchingDirection);
  }

  public setStitchingMove(stitchingMove: boolean): void {
    this.mSession.setMovingClockwise(stitchingMove);
  }

  // 处理无需下发saveRestore场景，以及下发无需存储相机状态的saveRestore场景
  public interruptSaveRestore(saveRestoreData: CloseInfoToWork): boolean {
    const targetCamera: camera.CameraDevice = this.mCameraContext.getCamera();
    if ((this.pickerInfo && this.pickerInfo.isPicker)) { // picker会传入镜头且默认每次后置，和save可能冲突
      HiLog.i(TAG, 'picker saveRestore return.');
      return true;
    }
    if (!this.mCameraManager?.isPrelaunchSupported(targetCamera) || this.mCameraInput?.getIsDuringCloseDelay() ||
      !this.mSession) { // 延迟收回镜头期间不下发saveRestore
      HiLog.i(TAG, 'saveRestore to preLaunch return.');
      return true;
    }

    if (!saveRestoreData.isLegalSaveRestore || this.mSession.isHasOtherOutput()) { // 进大图、双屏同显，下发NoNeed
      try {
        HiLog.i(TAG, 'saveRestore not legal to NoNeed.');
        this.mCameraManager?.setPrelaunchConfig({
          cameraDevice: targetCamera,
          restoreParamType: camera.RestoreParamType.NO_NEED_RESTORE_PARAM,
        });
      } catch (e) {
        HiLog.e(TAG, `set prelaunch noNeed failed: ${e}.`);
      }
      return true;
    }
    return false;
  }

  // 下发持久化SaveRestore参数：后置拍照、前置人像时起流退后台，更新15min状态参数
  public saveRestoreWithPersistentParam(saveRestoreData: CloseInfoToWork): void {
    const targetCamera: camera.CameraDevice = this.mCameraContext.getCamera();
    const cameraPosition = targetCamera.cameraPosition;
    const mode: ModeType = saveRestoreData.mode;
    const isBackPhoto: boolean =
      mode === ModeType.PHOTO && cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK;
    const isDefault: boolean = isBackPhoto; // 前置人像&后置拍照场景Persistent参数
    if (!isDefault) {
      HiLog.i(TAG, 'start camera not default mode case.');
      return;
    }
    try {
      const supportedBeautyTypes = this.mSession.getSupportedBeautyTypes();
      const settingParamData = {
        skinSmoothLevel: supportedBeautyTypes.includes(camera.BeautyType.SKIN_SMOOTH) ? this.mSession.getBeauty(
          camera.BeautyType.SKIN_SMOOTH) : 0,
        faceSlender: supportedBeautyTypes.includes(camera.BeautyType.FACE_SLENDER) ? this.mSession.getBeauty(
          camera.BeautyType.FACE_SLENDER) : 0,
        skinTone: supportedBeautyTypes.includes(camera.BeautyType.SKIN_TONE) ? this.mSession.getBeauty(
          camera.BeautyType.SKIN_TONE) : 0,
      };
      HiLog.i(TAG, `saveRestoreWithPersistentParam to PreLaunch: ${JSON.stringify(settingParamData)}.`);
      this.mCameraManager?.setPrelaunchConfig({
        cameraDevice: targetCamera,
        restoreParamType: PERSISTENT_DEFAULT_PARAM,
        activeTime: PERSISTENT_DEFAULT_TIME,
        settingParam: settingParamData
      });
    } catch (e) {
      HiLog.e(TAG, `set prelaunch persistent failed: ${e}.`);
    }
  }

  // 下发临时SaveRestore参数：只有退后台场景下发，区别持久化只要起流起的时默认场景就更新15min状态参数
  public saveRestoreWithActiveParam(): void {
    HiLog.begin(TAG, 'setPreLaunchConfig');
    const targetCamera: camera.CameraDevice = this.mCameraContext.getCamera();
    try {
      const supportedBeautyTypes = this.mSession.getSupportedBeautyTypes();
      const settingParamData = {
        skinSmoothLevel: supportedBeautyTypes.includes(camera.BeautyType.SKIN_SMOOTH) ? this.mSession.getBeauty(
          camera.BeautyType.SKIN_SMOOTH) : 0,
        faceSlender: supportedBeautyTypes.includes(camera.BeautyType.FACE_SLENDER) ? this.mSession.getBeauty(
          camera.BeautyType.FACE_SLENDER) : 0,
        skinTone: supportedBeautyTypes.includes(camera.BeautyType.SKIN_TONE) ? this.mSession.getBeauty(
          camera.BeautyType.SKIN_TONE) : 0,
      };
      HiLog.i(TAG, `saveRestoreWithActiveParam to PreLaunch: ${JSON.stringify(settingParamData)}.`);
      this.mCameraManager?.setPrelaunchConfig({
        cameraDevice: targetCamera,
        restoreParamType: TRANSIENT_ACTIVE_PARAM,
        activeTime: TRANSIENT_ACTIVE_TIME,
        settingParam: settingParamData
      });
    } catch (e) {
      HiLog.e(TAG, `set prelaunch active failed: ${e}.`);
    }
    HiLog.end(TAG, 'setPreLaunchConfig');
  }

  public doPreLaunchOperation(saveRestoreData: CloseInfoToWork, isDefaultModeCase: boolean = false): void {
    const isInterruptCase: boolean = this.interruptSaveRestore(saveRestoreData);
    if (isInterruptCase) {
      HiLog.i(TAG, 'interrupt saveRestore to PreLaunch.');
      return;
    }
    this.saveRestoreWithPersistentParam(saveRestoreData);
    if (!isDefaultModeCase) {
      this.saveRestoreWithActiveParam();
    }
  }

  public setXmage(value: number): void {
    this.mSession?.setXmage(value);
  }

  public setVideoStabilization(value?: number): void {
    this.mSession.setVideoStabilization(value);
  }

  public setPortraitEffect(value: number): void {
    this.mSession.setPortraitEffect(value);
  }

  public setCameraShotKey(cameraShotKey: string, currentMode: ModeType, recordingState: RecordingState): void {
    HiLog.e(TAG, `setCameraShotKey recordingState: ${recordingState}.`);
    GlobalContext.get().setCameraShotKey(cameraShotKey);
    if (currentMode === ModeType.VIDEO && recordingState === RecordingState.READY) {
      RecorderWrap.getInstance().changeFileShotKey();
    }
  }

  public getSupportedLightPaintings(): number[] {
    return this.mSession.getSupportedLightPaintings();
  }

  public getLightPainting(): number {
    return this.mSession.getLightPainting();
  }

  public setLightPainting(value: number): void {
    this.mSession.setLightPainting(value);
  }

  public togglePreRecording(open: boolean): void {
    HiLog.i(TAG, `==> togglePreRecording: ${open}.`);
    this.videoModule.togglePreRecording(open);
  }

  public triggerLighting(): void {
    this.mSession.triggerLighting();
  }

  public setExposureValue(exposureValue: number): void {
    this.mSession.setExposureValue(exposureValue);
  }

  public confirmCapture(): void {
    this.mPhotoOutput.confirmCapture();
  }

  public setPortraitThemeType(themeType: number): void {
    this.mSession.setPortraitThemeType(themeType);
  }

  public setExposureMode(exposureMode: camera.ExposureMode): void {
    this.mSession.setExposureMode(exposureMode);
  }

  public setExposureBias(value: number): void {
    this.mSession.setExposureBias(value);
  }

  public enableMacro(enable: boolean): void {
    this.mSession?.enableMacro(enable);
  }

  public async startSession(tagMessage: TagMessage): Promise<void> {
    await this.mSession?.start(tagMessage);
  }

  public async stopSession(): Promise<void> {
    if (!this.mSession) {
      HiLog.e(TAG, 'stop session undefined.');
      return;
    }
    HiLog.e(TAG, 'stop session successful.');
    await this.mSession?.stop();
  }

  public setSmoothZoom(targetRatio: number): void {
    this.mSession.setSmoothZoom(targetRatio);
  }

  public prepareOrUnprepareZoom(isPrepare: boolean): void {
    if (isPrepare) {
      this.mSession.prepareZoom();
    } else {
      this.mSession.unPrepareZoom();
    }
  }

  public setVirtualAperture(aperture: number): void {
    this.mSession?.setVirtualAperture(aperture);
  }

  public setPhysicalAperture(aperture: number): void {
    return this.mSession?.setPhysicalAperture(aperture);
  }

  public enableSceneFeature(scene: camera.SceneFeatureType, enabled: boolean): void {
    this.mSession?.enableSceneFeature(scene, enabled);
  }

  public setAuxiliary(Value: number): void {
    this.mSession.setAuxiliary(Value);
  }

  public setIsoValue(isoValue: number): void {
    this.mSession.setIsoValue(isoValue);
  }

  public setApertureValue(isoValue: number): void {
    this.mSession.setApertureValue(isoValue);
  }

  public setMeteringValue(meteringValue: number): void {
    this.mSession.setExposureMeteringMode(meteringValue);
  }

  public setSlowMotionDetectionArea(posData: camera.Rect): void {
    return this.mSession?.setSlowMotionDetectionArea(posData);
  }

  public setLivePhoto(value: boolean): void {
    this.mPhotoOutput.setLivePhoto(value);
  }

  public getFocusDistance(): number {
    return this.mSession?.getFocusDistance();
  }

  public getIsoRange(): number[] {
    return this.mSession?.getIsoRange()
  }

  public refreshPickerInfo(pickerInfo: PickerInfo): void {
    this.pickerInfo = pickerInfo;
    this.mPhotoOutput.refreshPickerInfo(pickerInfo);
  }

  public setTimeLapseInterval(interval: number): void {
    this.mSession.setTimeLapseInterval(interval);
  }

  public getIsDepthFusionConfigured(isConfigured: boolean): void {
    HiLog.i(TAG, `isDepthFusionConfigured: ${isConfigured}}, mode: ${this.currentMode}`);
    this.isDepthFusionConfigured = isConfigured;

  }

  public getTimeLapseInterval(): number {
    return this.mSession.getTimeLapseInterval();
  }

  public setTimeLapseRecordState(state: camera.TimeLapseRecordState): void {
    this.mSession.setTimeLapseRecordState(state);
  }

  // @ts-ignore
  public setColorStyleSetting(setting: camera.ColorStyleSetting): void {
    this.mSession.setColorStyleSetting(setting);
  }

  public async panoramaMaxPreviewOutputStart(): Promise<void> {
    await this.mPanoramaMaxPreviewOutput.previewOutputStart();
  }

  public async panoramaMinPreviewOutputStart(): Promise<void> {
    await this.mPanoramaMinPreviewOutput.previewOutputStart();
  }

  public async panoramaMaxPreviewOutputStop(): Promise<void> {
    await this.mPanoramaMaxPreviewOutput.previewOutputStop();
  }

  public async panoramaMinPreviewOutputStop(): Promise<void> {
    await this.mPanoramaMinPreviewOutput.previewOutputStop();
  }

  public setMirror(value: boolean): void {
    if (this.mPhotoOutput) {
      this.mPhotoOutput.setMirror(value);
    }
    this.videoModule.enableMirror(value);
  }

  public setAutoFrameRate(value: boolean): void {
    this.videoModule.enableAutoVideoFrameRate(value);
  }

  public setOperationEmotion(value: boolean): void {
    this.mMetadataOutput.setOperationEmotion(value);
  }

  public setSwingSubscribeStatus(value: boolean): void {
    this.mMetadataOutput.setSwingSubscribeStatus(value);
  }

  public setAudioZoomExtra(value: Record<string, string>): void {
    this.mSession?.setAudioZoomExtra(value);
  }

  public setShortVideoIndex(index: number): void {
    this.mSession?.setShortVideoIndex(index);
  }

  /**********************************************近物对焦 **/
  public getFocusRange(): camera.FocusRangeType {
    return this.mSession.getFocusRange();
  }

  public setFocusRange(value: camera.FocusRangeType): void {
    this.mSession?.setFocusRange(value);
  }

  /**********************************************人像追焦 **/
  public getFocusDriven(): camera.FocusDrivenType {
    return this.mSession.getFocusDriven();
  }

  public setFocusDriven(value: camera.FocusDrivenType): void {
    this.mSession?.setFocusDriven(value);
  }

  /**********************************************人像留色 **/
  public getColorReservation(): camera.ColorReservationType {
    return this.mSession.getColorReservation();
  }

  public setColorReservation(value: camera.ColorReservationType): void {
    this.mSession?.setColorReservation(value);
  }

  public setWindNoiseSuppression(value: Record<string, string>): void {
    this.mSession.setWindNoiseSuppression(value);
  }

  public keepUsingStellarLenses(): void {
    if (this.mCameraInput) {
      this.mCameraInput.keepUsingStellarLenses();
    }
  }

  public enableAIComposition(enable: boolean): void {
    this.mSession?.enableCompositionSuggestion(enable);
  }

  public enableLogAssistance(enable: boolean): void {
    this.mPreviewOutput?.enableLogAssistance(enable);
  }


  public async changeCollaborationPreviewOutput(isMirrorSelfiePreviewItem: boolean): Promise<void> {
    if (this.mCollaboratePreviewOutput) {
      HiLog.i(TAG, `changeCollaborationPreviewOutput begin, value: ${isMirrorSelfiePreviewItem}`);
      if (isMirrorSelfiePreviewItem) {
        this.mCollaboratePreviewOutput.previewOutputStart();
      } else {
        this.mCollaboratePreviewOutput.previewOutputStop();
      }
      HiLog.i(TAG, 'changeCollaborationPreviewOutput end');
    }
  }

  public changeConstellationStatus(isOpen: boolean): void {
    if (isOpen) {
      this.mSession?.handleConstellationDrawingOn();
      this.mPhotoOutput?.addConstellationCaptureListener();
    } else {
      this.mSession?.handleConstellationDrawingOff();
      this.mPhotoOutput?.releaseConstellationCaptureListener();
    }
  }

  public setFocusTrackingMode(mode: camera.FocusTrackingMode): void {
    this.mSession?.setFocusTrackingMode(mode);
  }

  public setFilterType(filterType: number): void {
    this.mSession?.setFilterType(filterType);
  }

  public setUltraPhoto(value: boolean): void {
    this.mPhotoOutput.setUltraPhoto(value);
  }
}