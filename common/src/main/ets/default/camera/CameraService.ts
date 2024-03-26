//@ts-nocheck
/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import camera from '@ohos.multimedia.camera';
import image from '@ohos.multimedia.image';
import media from '@ohos.multimedia.media';
import deviceInfo from '@ohos.deviceInfo';

import { CameraId } from '../setting/settingitem/CameraId';
import { Log } from '../utils/Log';
import ThumbnailGetter from './ThumbnailGetter';
import SaveCameraAsset from './SaveCameraAsset';
import { SettingManager } from '../setting/SettingManager';
import { CameraPlatformCapability } from './CameraPlatformCapability';
import ReportUtil from '../utils/ReportUtil';
import { GlobalContext } from '../utils/GlobalContext';

const TAG = '[CameraService]:';

const DEFAULT_VIDEO_FRAME_RATE = 30;
const FRONT_CAMERA_POSITION = 2;
const CAMERA_CONNECT_TYPE = 2;

export interface FunctionCallBack {
  onCapturePhotoOutput(): void

  onCaptureSuccess(thumbnail: any, resourceUri: any): void

  onCaptureFailure(): void

  onRecordSuccess(thumbnail: any): void

  onRecordFailure(): void

  thumbnail(thumbnail: any): void
}

export interface VideoCallBack {
  videoUri(videoUri: any): void

  onRecodeError(errorMsg: any): void
}

type Callback = (args?: any) => void

class CameraInformation {
  deviceName: string;
  cameraId: string;
}

export class CameraService {
  public mImageSize = {
    imageWidth: 1920,
    imageHeight: 1080
  }
  public mVideoFrameSize = {
    frameWidth: 1920,
    frameHeight: 1080
  }
  private mCameraId: string = CameraId.BACK;
  private mFileAssetId = 0;
  private mCameraManager!: camera.CameraManager;
  private mCameraIdMap: Map<string, string> = new Map();
  private mLocalCameraMap: Map<string, string> = new Map();
  private mCameraMap: Map<string, CameraInformation> = new Map();
  private curCameraName = '';
  private mCameraCount = 0;
  private mCameraInput!: camera.CameraInput;
  private mCaptureSession!: camera.CaptureSession;
  private mPreviewOutput!: camera.PreviewOutput;
  private mPhotoOutPut!: camera.PhotoOutput;
  private mImageReceiver!: image.ImageReceiver;
  private mVideoOutput!: camera.VideoOutput;
  private mAVRecorder!: media.AVRecorder;
  private mThumbnail!: image.PixelMap;
  private mIsStartRecording = false;
  private mSaveCameraAsset = new SaveCameraAsset();
  private mThumbnailGetter = new ThumbnailGetter();
  private camerasCache: any = null;
  private outputCapability: camera.CameraOutputCapability = null;
  private mVideoConfig: any = {
    audioSourceType: 1,
    videoSourceType: 1,
    profile: {
      audioBitrate: 48000,
      audioChannels: 2,
      audioCodec: 'audio/mp4a-latm',
      audioSampleRate: 48000,
      durationTime: 1000,
      fileFormat: 'mp4',
      videoBitrate: 5000000,
      videoCodec: 'video/avc',
      videoFrameWidth: 640,
      videoFrameHeight: 480,
      videoFrameRate: 30
    },
    url: 'file:///data/media/01.mp4',
    orientationHint: 0,
    maxSize: 100,
    maxDuration: 500,
    rotation: 0
  }
  private mCaptureSetting: any = {
    rotation: 0,
    quality: 1,
    mirror: false
  }

  private constructor() {
  }

  public static getInstance(): CameraService {
    if (!globalThis?.sInstanceCameraService) {
      globalThis.sInstanceCameraService = new CameraService();
    }
    return globalThis.sInstanceCameraService;
  }

  public async initCamera(cameraId: string): Promise<number> {
    Log.start(`${TAG} initCamera`);
    if (!this.mCameraManager) {
      try {
        this.mCameraManager = camera.getCameraManager(GlobalContext.get().getCameraAbilityContext());
        const cameras = this.mCameraManager.getSupportedCameras();
        this.camerasCache = cameras;
        this.mCameraCount = cameras.length;
        if (cameras) {
          Log.info(`${TAG} getCameras success.`);
          for (let i = 0; i < cameras.length; i++) {
            Log.info(`${TAG} camera_id: ${cameras[i].cameraId}  cameraPosition: ${cameras[i].cameraPosition}
              cameraType: ${cameras[i].cameraType} connectionType: ${cameras[i].connectionType}`);
            if (cameras[i].cameraPosition === FRONT_CAMERA_POSITION && cameras[i].connectionType !== CAMERA_CONNECT_TYPE) {
              this.mLocalCameraMap.set('front', 'true');
            }
            if (cameras[i].cameraPosition !== FRONT_CAMERA_POSITION && cameras[i].connectionType !== CAMERA_CONNECT_TYPE) {
              this.mLocalCameraMap.set('back', 'true');
            }
          }
          // TODO 根据底层信息匹配cameraId 目前默认第0个是back， 第1个是front
          this.mCameraIdMap.set(CameraId.BACK, cameras[0].cameraId);
          if (cameras.length > 1 && cameras[1].connectionType !== 2) {
            this.mCameraIdMap.set(CameraId.FRONT, cameras[1].cameraId);
          } else {
            this.mCameraIdMap.set(CameraId.FRONT, cameras[0].cameraId);
          }
        }
      } catch (error) {
        Log.error(`${TAG} initCamera failed: ${JSON.stringify(error)}`);
        ReportUtil.writeFaultLog(error);
      }
    }
    this.curCameraName = cameraId;
    await this.createCameraInput(cameraId, 'init');

    Log.info(`${TAG} deviceType = ${deviceInfo.deviceType}`);
    if (deviceInfo.deviceType == 'default') {
      this.mVideoConfig.videoSourceType = 1;
    } else {
      this.mVideoConfig.videoSourceType = 0;
    }
    Log.end(`${TAG} initCamera`);
    return this.mCameraCount;
  }

  public getCameraManager(): camera.CameraManager {
    return this.mCameraManager;
  }

  public getCameraIdMap(): Map<string, string> {
    return this.mCameraIdMap;
  }

  public getLocalCameraMap(): Map<string, string> {
    return this.mLocalCameraMap;
  }

  public getCameraMap(): Map<string, CameraInformation> {
    return this.mCameraMap;
  }

  public getCameraCount(): number {
    return this.mCameraCount;
  }

  public async createCameraInput(cameraName: string, callType?: string) {
    Log.start(`${TAG} createCameraInput`);
    this.mCameraId = cameraName;
    this.curCameraName = cameraName;
    if (callType === 'modeChange' || callType === 'init') {
      let targetCamera = this.camerasCache.filter(item => item.connectionType !== 2);
      if (targetCamera && targetCamera.length <= 1 && cameraName === 'BACK') {
        this.curCameraName = 'FRONT';
        this.mCameraId = 'FRONT';
      }
    }
    if (this.mCameraInput) {
      await this.mCameraInput.release();
    }
    let id;
    if (cameraName == CameraId.FRONT || cameraName == CameraId.BACK) {
      id = this.mCameraIdMap.get(cameraName);
    } else {
      id = this.mCameraMap.get(cameraName).cameraId;
    }
    Log.info(`${TAG} createCameraInput id = ${id}`);
    try {
      let cameras = await this.getCameraLists();
      let targetCamera = cameras.find(item => item.cameraId === id);
      this.outputCapability = this.mCameraManager.getSupportedOutputCapability(targetCamera);
      this.mCameraInput = this.mCameraManager.createCameraInput(targetCamera);
      await this.mCameraInput.open();
      const platformCapability = CameraPlatformCapability.getInstance();
      await platformCapability.calcSupportedSizes(this.mCameraInput, this.outputCapability);
      SettingManager.getInstance().setCameraPlatformCapability(platformCapability);
    } catch (error) {
      Log.error(`${TAG} createCameraInput failed: ${JSON.stringify(error)}`);
      ReportUtil.writeFaultLog(error);
    }
    Log.end(`${TAG} createCameraInput`);
  }

  public async releaseCameraInput() {
    Log.start(`${TAG} releaseCameraInput`);
    if (this.mCameraInput) {
      try {
        await this.mCameraInput.release();
      } catch (error) {
        Log.error(`${TAG} releaseCameraInput failed: ${JSON.stringify(error)}`);
        ReportUtil.writeFaultLog(error);
      }
      this.mCameraInput = null;
    }
    Log.end(`${TAG} releaseCameraInput`);
  }

  public async createPreviewOutput(surfaceId: string, mode: string) {
    Log.start(`${TAG} createPreviewOutput`);
    const size = SettingManager.getInstance().getPreviewSize(mode);
    Log.info(`${TAG} createPreviewOutput size.width = ${size.width} size.height = ${size.height}`);
    GlobalContext.get().getXComponentController().setXComponentSurfaceSize({
      surfaceWidth: size.width,
      surfaceHeight: size.height
    });
    let previewProfiles = this.outputCapability.previewProfiles;
    let previewProfile;
    if (deviceInfo.deviceType == 'default') {
      previewProfile = previewProfiles[0];
    } else {
      Log.info(`${TAG} previewProfiles length.` + previewProfiles.length);
      previewProfile = previewProfiles.find(item => item.size.width === size.width &&
        item.size.height === size.height && item.format === 1003);
    }
    await this.releasePreviewOutput();
    try {
      this.mPreviewOutput = this.mCameraManager.createPreviewOutput(previewProfile, surfaceId);
    } catch (error) {
      Log.error(`${TAG} createPreviewOutput failed: ${JSON.stringify(error)}`);
      ReportUtil.writeFaultLog(error);
    }
    Log.end(`${TAG} createPreviewOutput`);
  }

  public async releasePreviewOutput() {
    Log.start(`${TAG} releasePreviewOutput`);
    if (this.mPreviewOutput) {
      try {
        await this.mPreviewOutput.release();
        this.mPreviewOutput = null;
      } catch (error) {
        Log.error(`${TAG} releasePreviewOutput failed: ${JSON.stringify(error)}`);
        ReportUtil.writeFaultLog(error);
      }
    }
    Log.end(`${TAG} releasePreviewOutput`);
  }

  public async createPhotoOutput(functionCallback: FunctionCallBack) {
    Log.start(`${TAG} createPhotoOutput`);
    const size = SettingManager.getInstance().getImageSize();
    Log.info(`${TAG} createPhotoOutput size.width = ${size.width} size.height = ${size.height}`);
    this.mImageReceiver = image.createImageReceiver(size.width, size.height, image.ImageFormat.JPEG, 8);
    const surfaceId = await this.mImageReceiver.getReceivingSurfaceId();
    Log.info(`${TAG} createPhotoOutput surfaceId: ${surfaceId}.`);
    let photoProfiles = this.outputCapability.photoProfiles;
    let photoProfile;
    if (deviceInfo.deviceType == 'default') {
      photoProfile = photoProfiles[0];
    } else {
      Log.info(`${TAG} videoProfiles length.` + photoProfiles.length);
      photoProfile = photoProfiles.find(item => item.size.width === size.width && item.size.height === size.height);
    }
    try {
      this.mPhotoOutPut = this.mCameraManager.createPhotoOutput(photoProfile, surfaceId);
    } catch (error) {
      Log.error(`${TAG} createPhotoOutput failed: ${JSON.stringify(error)}`);
      ReportUtil.writeFaultLog(error);
    }
    Log.info(`${TAG} createPhotoOutput mPhotoOutPut: ${this.mPhotoOutPut}.`);
    this.mSaveCameraAsset.saveImage(this.mImageReceiver, 40, 40, this.mThumbnailGetter, functionCallback);
    Log.end(`${TAG} createPhotoOutput`);
  }

  public async releasePhotoOutput() {
    Log.start(`${TAG} releasePhotoOutput`);
    if (this.mPhotoOutPut) {
      try {
        await this.mPhotoOutPut.release();
        this.mPhotoOutPut = null;
      } catch (error) {
        Log.error(`${TAG} releasePhotoOutput failed: ${JSON.stringify(error)}`);
        ReportUtil.writeFaultLog(error);
      }
    }
    if (this.mImageReceiver) {
      await this.mImageReceiver.release();
      this.mImageReceiver = null;
    }
    Log.end(`${TAG} releasePhotoOutput`);
  }

  public async createSession(surfaceId: string, isVideo: boolean) {
    Log.start(`${TAG} createSession`);
    GlobalContext.get().setObject('isSessionCreating', true)
    this.mCaptureSession = this.mCameraManager.createCaptureSession();
    GlobalContext.get().setObject('isSessionCreating', false)
    Log.info(`${TAG} createSession captureSession: ${this.mCaptureSession}, cameraInput: ${this.mCameraInput},
    videoOutPut: ${this.mVideoOutput}, photoOutPut: ${this.mPhotoOutPut},  mPreviewOutput: ${this.mPreviewOutput}`);
    Log.info(`${TAG} createSession beginConfig.`);
    Log.start(Log.STREAM_DISTRIBUTION);
    try {
      this.mCaptureSession?.beginConfig();
      await new Promise((resolve) => setTimeout(resolve, 1));
      Log.info(`${TAG} createSession addInput.`);
      this.mCaptureSession?.addInput(this.mCameraInput);
      if (!isVideo) {
        Log.info(`${TAG} createSession photo addOutput.`);
        this.mCaptureSession?.addOutput(this.mPhotoOutPut);
      }
      Log.info(`${TAG} createSession preview addOutput.`);
      this.mCaptureSession?.addOutput(this.mPreviewOutput);
    } catch (error) {
      Log.error(`${TAG} createSession failed: ${JSON.stringify(error)}`);
      if (error) {
        ReportUtil.write(ReportUtil.CAMERA_ERROR);
      }
    }
    Log.info(`${TAG} createSession commitConfig.`);
    Log.start(Log.OPEN_CAMERA);
    try {
      await this.mCaptureSession?.commitConfig();
      Log.end(Log.OPEN_CAMERA);
      Log.end(Log.STREAM_DISTRIBUTION);
      await this.mCaptureSession?.start();
    } catch (err) {
      if (err) {
        ReportUtil.write(ReportUtil.OPEN_FAIL);
      }
    }
    if (GlobalContext.get().getT<boolean>('cameraStartFlag') && (new Date().getTime() - GlobalContext.get().getT<number>('cameraStartTime')) > 2000) {
      ReportUtil.write(ReportUtil.START_TIMEOUT);
    }
    GlobalContext.get().setObject('cameraStartFlag', false);
    Log.end(`${TAG} createSession`);
  }

  public async releaseSession() {
    Log.start(`${TAG} releaseSession`);
    if (this.mCaptureSession) {
      try {
        await this.mCaptureSession.stop();
        await this.mCaptureSession.release();
        this.mCaptureSession = null;
      } catch (error) {
        Log.error(`${TAG} releaseSession failed: ${JSON.stringify(error)}`);
        ReportUtil.writeFaultLog(error);
      }
    }
    Log.end(`${TAG} releaseSession`);
  }

  public async startPreview() {
    Log.start(`${TAG} startPreview`);
    if (!this.mCaptureSession) {
      return;
    }
    try {
      await this.mCaptureSession.start();
    } catch (error) {
      Log.error(`${TAG} startPreview failed: ${JSON.stringify(error)}`);
      ReportUtil.writeFaultLog(error);
    }
    Log.end(`${TAG} startPreview`);
  }

  public async stopPreview() {
    Log.start(`${TAG} stopPreview`);
    if (!this.mCaptureSession) {
      return;
    }
    try {
      await this.mCaptureSession.stop();
    } catch (error) {
      Log.error(`${TAG} stopPreview failed: ${JSON.stringify(error)}`);
      ReportUtil.writeFaultLog(error);
    }
    Log.end(`${TAG} stopPreview`);
  }

  public async takePicture() {
    Log.start(`${TAG} takePicture`);
    ReportUtil.write(ReportUtil.CAPTURE);
    if (!this.mCaptureSession) {
      Log.info(`${TAG} takePicture session is release`);
      return;
    }
    if (!this.mPhotoOutPut) {
      Log.info(`${TAG} takePicture photoOutPut is release`);
      return;
    }
    if (this.mCameraId === CameraId.FRONT) {
      this.mCaptureSetting.mirror = SettingManager.getInstance().getSelfMirror();
    }
    const locationData = SettingManager.getInstance().getCurGeoLocation();
    if (locationData) {
      this.mCaptureSetting.location = {
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        altitude: locationData.altitude
      }
    }
    Log.info(`${TAG} takePicture captureSetting ${JSON.stringify(this.mCaptureSetting)}`);
    // todo modify the location and mirror config
    try {
      this.mPhotoOutPut.capture(this.mCaptureSetting);
    } catch (err) {
      if (err) {
        ReportUtil.write(ReportUtil.CAPTURE_FAIL);
      }
    }
    Log.end(`${TAG} takePicture`);
    if ((new Date().getTime() - GlobalContext.get().getT<number>('startCaptureTime')) > 2000) {
      ReportUtil.write(ReportUtil.CAPTURE_TIMEOUT);
    }
  }

  public async createVideoOutput(functionCallBack: VideoCallBack) {
    Log.start(`${TAG} createVideoOutput`);
    this.mFileAssetId = await this.mSaveCameraAsset.createVideoFd(functionCallBack);
    if (this.mFileAssetId === undefined) {
      Log.error(`${TAG} createVideoOutput error: mFileAssetId undefined`);
      functionCallBack.onRecodeError('createVideoOutput error: mFileAssetId undefined');
    }
    this.mVideoConfig.url = `fd://${this.mFileAssetId.toString()}`;
    await media.createAVRecorder().then((recorder) => {
      Log.info(`${TAG} createVideoOutput createAVRecorder record: ${recorder}`);
      this.mAVRecorder = recorder;
    });
    const size = SettingManager.getInstance().getVideoSize();
    if (this.mAVRecorder != null) {
      this.mAVRecorder.on('error', (error) => {
        if (error) {
          Log.error(`${TAG} createVideoOutput error: ${JSON.stringify(error)}`);
          functionCallBack.onRecodeError(`createVideoOutput error: ${JSON.stringify(error)}`);
        }
      });
      Log.info(`${TAG} createVideoOutput size = ${JSON.stringify(size)}`);
      this.mVideoConfig.profile.videoFrameWidth = size.width;
      this.mVideoConfig.profile.videoFrameHeight = size.height;
      const locationData = SettingManager.getInstance().getCurGeoLocation();
      if (locationData) {
        this.mVideoConfig.location = {
          latitude: locationData.latitude,
          longitude: locationData.longitude
        };
      }

      if (deviceInfo.deviceType != 'tablet') {
        if (this.curCameraName === 'BACK') {
          this.mVideoConfig.rotation = 90;
        } else {
          this.mVideoConfig.rotation = 270;
        }
      }
      Log.info(`${TAG} createVideoOutput mVideoConfig =  ${JSON.stringify(this.mVideoConfig)}.`);
      await this.mAVRecorder.prepare(this.mVideoConfig);
      Log.info(`${TAG} createVideoOutput AVRecorder.prepare succeed.`);
    } else {
      Log.error(`${TAG} createVideoOutput createAVRecorder failed.`);
      return;
    }

    let profileVideo;
    if (deviceInfo.deviceType == 'default') {
      profileVideo = this.outputCapability.videoProfiles[0];
    } else {
      let videoProfiles = this.outputCapability.videoProfiles;
      Log.info(`${TAG} videoProfiles length.` + videoProfiles.length);
      profileVideo = videoProfiles.find(item =>
      item.size.width === size.width && item.size.height === size.height
        && item.frameRateRange.min === DEFAULT_VIDEO_FRAME_RATE && item.frameRateRange.max === DEFAULT_VIDEO_FRAME_RATE
      );
    }

    const videoId = await this.mAVRecorder.getInputSurface();
    Log.info(`${TAG} createVideoOutput profileVideo =  ${JSON.stringify(profileVideo)}.`);
    try {
      this.mVideoOutput = this.mCameraManager.createVideoOutput(profileVideo, videoId);
    } catch (error) {
      Log.error(`${TAG} createVideoOutput failed: ${JSON.stringify(error)}`);
      ReportUtil.writeFaultLog(error);
    }
    Log.end(`${TAG} createVideoOutput`);
  }

  public async releaseVideoOutput() {
    Log.start(`${TAG} releaseVideoOutput`);
    if (this.mVideoOutput) {
      Log.info(`${TAG} releaseVideoOutput start`);
      try {
        await this.mVideoOutput.release();
      } catch (error) {
        Log.error(`${TAG} releaseVideoOutput failed: ${JSON.stringify(error)}`);
        ReportUtil.writeFaultLog(error);
      }
      Log.info(`${TAG} releaseVideoOutput end`);
      this.mVideoOutput = null;
    }
    Log.end(`${TAG} releaseVideoOutput`);
  }

  public async StartRecording(functionCallBack: VideoCallBack) {
    let startRecordingTime = new Date().getTime();
    Log.start(`${TAG} StartRecording`);
    Log.info(`${TAG} StartRecording codec ${this.mVideoConfig.profile.videoCodec}`);
    ReportUtil.write(ReportUtil.VIDEO_RECORD);
    try {
      await this.mCaptureSession.stop();
      this.mCaptureSession.beginConfig();
      if (this.mVideoOutput) {
        await this.mCaptureSession.removeOutput(this.mVideoOutput);
        Log.info(`${TAG} old videoOutput has been removed.`);
      }
      await this.createVideoOutput(functionCallBack);
      this.mCaptureSession.addOutput(this.mVideoOutput);
      Log.info(`${TAG} StartRecording addOutput finished.`);
      await this.mCaptureSession.commitConfig();
      Log.info(`${TAG} StartRecording commitConfig finished.`);
      await this.mCaptureSession.start();
      Log.info(`${TAG} StartRecording Session.start finished.`);
    } catch (err) {
      GlobalContext.get().setObject('startRecordingFlag', false);
      ReportUtil.writeFaultLog(error);
      Log.error(`${TAG} remove videoOutput ${err}`);
    }
    await this.mVideoOutput.start().then(() => {
      Log.info(`${TAG} videoOutput.start()`);
    });
    await this.mAVRecorder.start().then(() => {
      Log.info(`${TAG} AVRecorder.start()`);
    });
    this.mIsStartRecording = true;
    if (new Date().getTime() - startRecordingTime > 2000) {
      ReportUtil.write(ReportUtil.START_RECORD_TIMEOUT);
    }
    Log.end(`${TAG} StartRecording`);
  }

  public async stopRecording(): Promise<PixelMap | undefined> {
    Log.start(Log.STOP_RECORDING);
    let stopRecordingTime = new Date().getTime();
    ReportUtil.write(ReportUtil.STOP_RECORD);
    if (!this.mVideoOutput || !this.mAVRecorder) {
      Log.error(`${TAG} stopRecording error videoOutPut: ${this.mVideoOutput},
              AVRecorder: ${this.mAVRecorder} .`);
      return undefined;
    }
    this.mIsStartRecording = false;
    try {
      await this.mAVRecorder.stop();
      await this.mAVRecorder.release();
    } catch (err) {
      Log.error(`${TAG} stop AVRecorder ${err}`);
    }

    try {
      await this.mVideoOutput.stop();
    } catch (err) {
      Log.error(`${TAG} stop videoOutput ${err}`);
    }

    if (this.mFileAssetId != undefined) {
      await this.mSaveCameraAsset.videoPrepareFile.close(this.mFileAssetId);
      this.mFileAssetId = undefined;
      Log.info(`${TAG} fileAsset.close().`);
    }
    Log.start(Log.UPDATE_VIDEO_THUMBNAIL);
    const thumbnailPixelMap: PixelMap | undefined = await this.mThumbnailGetter.getThumbnailInfo(40, 40);
    Log.end(Log.UPDATE_VIDEO_THUMBNAIL);
    if (new Date().getTime() - stopRecordingTime > 2000) {
      ReportUtil.write(ReportUtil.FINISH_RECORD_TIMEOUT);
    }
    Log.end(Log.STOP_RECORDING);
    return thumbnailPixelMap;
  }

  public async pauseRecording() {
    Log.start(`${TAG} pauseRecording`);
    if (!this.mVideoOutput || !this.mAVRecorder) {
      Log.error(`${TAG} pauseRecording error videoOutPut: ${this.mVideoOutput},
              AVRecorder: ${this.mAVRecorder} .`);
      return;
    }
    try {
      await this.mAVRecorder.pause();
      await this.mVideoOutput.stop();
    } catch (error) {
      Log.error(`${TAG} pauseRecording failed: ${JSON.stringify(error)}`);
    }
    Log.end(`${TAG} pauseRecording`);
  }

  public async resumeRecording() {
    Log.start(`${TAG} resumeRecording`);
    if (!this.mVideoOutput || !this.mAVRecorder) {
      Log.error(`${TAG} resumeRecording error videoOutPut: ${this.mVideoOutput},
              AVRecorder: ${this.mAVRecorder} .`);
      return;
    }
    await this.mVideoOutput.start().then(() => {
      Log.info(`${TAG} videoOutput.start()`);
    }).catch((error) => {
      Log.error(`${TAG} resumeRecording mVideoOutput start failed: ${JSON.stringify(error)}`);
    });
    await this.mAVRecorder.resume();
    Log.end(`${TAG} resumeRecording`);
  }

  public async releaseRecording() {
    Log.start(`${TAG} releaseRecording`);
    if (!this.mAVRecorder) {
      Log.info(`${TAG} AVRecorder has not been created.`);
      return;
    }
    if (this.mIsStartRecording) {
      await this.stopRecording();
    }
    await this.mAVRecorder.release().then(() => {
      Log.info(`${TAG} AVRecorder.release() success.`);
      this.mAVRecorder = undefined;
    });
    Log.end(`${TAG} releaseRecording`);
  }

  public async releaseCamera() {
    Log.start(`${TAG} releaseCamera`);
    await this.releaseRecording();
    await this.releaseVideoOutput();
    await this.releasePhotoOutput();
    await this.releaseSession();
    Log.end(`${TAG} releaseCamera`);
  }

  public async setZoomRatio(zoomRatio: number) {
    Log.info(`${TAG} setZoomRatio invoke E ${zoomRatio}`);
    if (!this.mCaptureSession) {
      Log.info(`${TAG} setZoomRatio mCaptureSession is release`);
      return;
    }
    try {
      this.mCaptureSession.setZoomRatio(zoomRatio);
    } catch (error) {
      Log.error(`${TAG} setZoomRatio failed: ${JSON.stringify(error)}`);
    }
    Log.info(`${TAG} setZoomRatio invoke X.`);
  }

  public async getZoomRatio(): Promise<number> {
    Log.info(`${TAG} getZoomRatio invoke E.`);
    if (!this.mCaptureSession) {
      Log.info(`${TAG} getZoomRatio mCaptureSession is release`);
      return 1;
    }
    Log.info(`${TAG} getZoomRatio invoke X.`);
    return this.mCaptureSession.getZoomRatio();
  }

  public async setVideoConfig(videoConfig: any) {
    Log.info(`${TAG} setVideoConfig invoke E.`);
    if (videoConfig) {
      this.mVideoConfig = videoConfig;
    } else {
      Log.info(`${TAG} setVideoConfig videoConfig is null.`);
    }
    Log.info(`${TAG} setVideoConfig invoke X.`);
  }

  public async setCaptureSetting(captureSetting: any) {
    Log.info(`${TAG} setCaptureSetting invoke E.`);
    if (captureSetting) {
      this.mCaptureSetting = captureSetting;
    } else {
      Log.info(`${TAG} setCaptureSetting captureSetting is null.`);
    }
    Log.info(`${TAG} setCaptureSetting invoke X.`);
  }

  public getThumbnail(functionCallBack: FunctionCallBack): image.PixelMap {
    Log.start(`${TAG} getThumbnail`);
    this.mThumbnailGetter.getThumbnailInfo(40, 40).then((thumbnail) => {
      functionCallBack.thumbnail(thumbnail);
      Log.end(`${TAG} getThumbnail`);
    });
    return this.mThumbnail;
  }

  public getCameraName(): string {
    return this.curCameraName;
  }

  public setCameraId(name: string): void {
    this.curCameraName = name;
  }

  public getPhotoUri() {
    return this.mSaveCameraAsset.getPhotoUri();
  }

  public getRecentFileUri(): string {
    return this.mThumbnailGetter.getRecentFileUri();
  }

  private async getCameraLists() {
    const cameras = this.mCameraManager.getSupportedCameras();
    this.camerasCache = cameras;
    return cameras;
  }
}