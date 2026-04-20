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

import image from '@ohos.multimedia.image';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import lazy { HiLog } from '../../../utils/HiLog';
import CameraOutput from './CameraOutput';
import camera from '@ohos.multimedia.camera';
import type CameraContext from './CameraContext';
import type CameraDeviceManager from './CameraDeviceManager';
import lazy { ModeType } from '../../../mode/ModeType';
import lazy { modulesManager } from '../../../worker/WorkerModuleManager';
import lazy { CaptureFailedType } from '../../DataType';
import lazy { OutputOperation } from '../../../function/outputswitcher/OutputOperation';
import lazy { OutputType } from '../../../function/outputswitcher/OutputType';
import lazy { DeviceInfo } from '../../../component/deviceinfo/DeviceInfo';
import lazy { simpleStringify } from '../../../utils/SimpleStringify';
import lazy { PickerSaveResolveType } from '../../../service/picker/PickerFileWorkerService';
import lazy { workerCallback } from '../WorkerCallback';
import lazy { CaptureMessage } from '../../../function/capture/CaptureMessage';
import lazy { LOCATION_MESSAGE } from '../CameraTaskHandler';
import type { PickerInfo } from '../../../utils/types';
import lazy { DisplayService } from '../../../service/UIAdaptive/DisplayService';
import lazy { BusinessError } from '@kit.BasicServicesKit';
import {
  LeftRightSwipeWorkerCaptureService
} from '../../../component/leftrightswipecontrol/LeftRightSwipeWorkerCaptureService';

/* instrument ignore file */
const TAG: string = 'PhotoOutputWrap';
const ANGLE_90: number = 90;
const ANGLE_270: number = 270;
const ROTATION_1: number = 1;
const ROTATION_3: number = 3;
const RELEASE_OFFLINE_PHOTO_OUTPUT_DELAY: number = 100;

// PhotoOutput包装类
export default class PhotoOutputWrap extends CameraOutput {
  private mPhotoOutput!: camera.PhotoOutput;
  private mPickerInfo: PickerInfo = {
    isPicker: false,
    uri: '',
    callingTokenID: -1,
    callerPid: -1
  };
  private photoProfile: camera.Profile;
  // 拍照流Profile,含直出Format
  private savePhotoFormat: camera.CameraFormat;
  // 用户选择落盘方式,以Format形式表示避免PhotoFormatMode泛滥
  private isProRawDelivery: boolean = false;
  // 专业拍照模式是否使能RAW主图
  private currentMode: ModeType;
  private curOutputType: OutputType;
  private isQuickThumbnail: boolean;
  private isDeferEnabled: boolean;
  private captureTag: string;
  private isSupportLrSwipeNewCapture: boolean;
  private isInBurstCapture: boolean;
  private mIsInCapture: boolean = false;
  private cameraManager: camera.CameraManager = null;
  private isBackCapture: boolean = false;
  private hasCaptureReady: boolean = false;
  private hasAvailablePhotoAsset: boolean = false;
  private hasCaptured: boolean = false;
  public mOfflinePhotoReceiveCallBack: Function = () => {
  };
  public mOfflinePhotoFinishCallBack: Function = () => {
  };
  private offlineSupport: boolean = false;
  // 是否支持离线拍照
  private mQuickThumbnailMap: Map<string, image.PixelMap>;
  private pcPickerPhotoMap: Map<string, image.PixelMap>;

  //pc不支持快速缩略图使用

  constructor(cameraDeviceManager: CameraDeviceManager, cameraContext: CameraContext) {
    super(cameraDeviceManager, cameraContext);
  }

  public async init(photoProfile: camera.Profile, cameraManager: camera.CameraManager,
    savePhotoFormat: camera.CameraFormat, isProRawDelivery: boolean, pickerInfo?: PickerInfo): Promise<void> {
    if (!cameraManager) {
      HiLog.e(TAG, 'createPhotoOutput cameraManager is null.');
      return;
    }
    this.cameraManager = cameraManager;
    this.mPickerInfo = pickerInfo || {
      isPicker: false,
      uri: '',
      callingTokenID: -1,
      callerPid: -1
    };

    if (this.mPickerInfo && this.mPickerInfo.isPicker && !DeviceInfo.isPc()) {
      this.photoProfile = {
        format: camera.CameraFormat.CAMERA_FORMAT_JPEG,
        size: photoProfile.size
      };
    } else {
      this.photoProfile = photoProfile;
    }

    HiLog.i(TAG, `createPhotoOutput initProfile: ${this.photoProfile.format}, isPicker: ${this.mPickerInfo.isPicker}.`);
    this.savePhotoFormat = savePhotoFormat;
    this.isProRawDelivery = isProRawDelivery;
    this.mPhotoOutput = cameraManager.createPhotoOutput(this.photoProfile); // 单分段式全量走新接口,不再传递surface
    this.mQuickThumbnailMap = new Map<string, image.PixelMap>();
    this.pcPickerPhotoMap = new Map<string, image.PixelMap>();
  }

  public async capture(setting: camera.PhotoCaptureSetting, message: CaptureMessage): Promise<void> {
    if (!this.mPhotoOutput) {
      HiLog.e(TAG, 'PhotoOutput undefined error.');
      return;
    }
    if (LOCATION_MESSAGE.location) {
      setting.location = LOCATION_MESSAGE.location;
    } else {
      setting.location = { latitude: 30.5225, longitude: 114.5092, altitude: 0 }
    }
    HiLog.i(TAG, `capture begin, setting: ${simpleStringify(setting)}, message: ${simpleStringify(message)}.`);
    const mediaLibrary = await modulesManager.getMediaLibrary();
    this.hasCaptured = true;
    this.isBackCapture = message.isBackCapture;
    let singleCaptureSuccess = true;
    if (this.mPickerInfo && this.mPickerInfo.isPicker) {
      const pickerWorkerService = await modulesManager.getPickerFileWorkerService();
      pickerWorkerService.resetPickerBuffer();
    }
    this.isInBurstCapture = false;
    try {
      HiLog.i(TAG, 'capture2FWK');
      this.mIsInCapture = true;
      await this.mPhotoOutput.capture(setting);
    } catch (error) {
      singleCaptureSuccess = false;
      HiLog.e(TAG, `PhotoOutput capture error: ${error.code}`);
      if (error.code !== camera.CameraErrorCode.OPERATION_NOT_ALLOWED) {
        workerCallback.onCaptureAborted();
      }
    }
    if (singleCaptureSuccess) {
      LeftRightSwipeWorkerCaptureService.getInstance().shutterCapture(message.downCapture);
    }
    HiLog.i(TAG, 'capture done.');
  }

  public async release(): Promise<void> {
    if (!this.mPhotoOutput) {
      HiLog.i(TAG, 'release mPhotoOutput is null');
      return;
    }
    this.releaseRelatedStatus();
    this.releasePhotoOutput();
  }

  private releaseRelatedStatus(): void {
    this.initPickerCloseRelatedStatus();
    try {
      LeftRightSwipeWorkerCaptureService.getInstance().modeSwitchRelease();
    } catch (e) {
      HiLog.i(TAG, `modeSwitchRelease error: ${JSON.stringify(e)}.`);
    }
  }

  // 拍照流释放，其他资源释放不要写在此方法
  public async releasePhotoOutput(): Promise<void> {
    if (!this.mPhotoOutput) {
      HiLog.i(TAG, 'release photoOutput is null');
      return;
    }
    try {
      HiLog.begin(TAG, 'releasePhotoOutput');
      this.unregisterListeners('photoAssetAvailable');
      this.unregisterListeners('quickThumbnail');
      this.unregisterListeners('photoAvailable');
      this.unregisterListeners('offlineDeliveryFinished');
      this.unregisterListeners('frameShutterEnd');
      this.unregisterListeners('captureReady');
      this.unregisterListeners('estimatedCaptureDuration');
      this.unregisterListeners('captureStartWithInfo');
      this.unregisterListeners('captureEnd');
      this.unregisterListeners('frameShutter');
      this.unregisterListeners('constellationDrawingStateChange');
      this.unregisterListeners('error');
    } catch (e) {
      HiLog.i(TAG, `unregisterListeners error: ${JSON.stringify(e)}.`);
    }
    try {
      await this.mPhotoOutput.release();
      this.mPhotoOutput = null;
      HiLog.end(TAG, 'releasePhotoOutput');
    } catch (e) {
      HiLog.i(TAG, `releasePhotoOutput error: ${JSON.stringify(e)}.`);
    }
  }

  private unregisterListeners(type: string): void {
    try {
      // @ts-ignore
      this.mPhotoOutput.off(type);
    } catch (e) {
      HiLog.i(TAG, `unregisterListeners ${type} error: ${JSON.stringify(e)}.`);
    }
  }

  public getOutput(): camera.PhotoOutput {
    return this.mPhotoOutput;
  }

  public setOutput(photoOutput: camera.PhotoOutput): void {
    this.mPhotoOutput = photoOutput;
  }

  public confirmCapture(): void {
    HiLog.i(TAG, 'confirmCapture.');
    this.mPhotoOutput.confirmCapture();
  }

  public addConstellationCaptureListener(): void {
    // @ts-ignore
    this.mPhotoOutput.on('constellationDrawingStateChange', (err, state: ConstellationDrawingState) => {
      if (err) {
        HiLog.e(TAG, `constellationMatchingStateChange error: ${err?.code}.`);
        return;
      }
      workerCallback.onConstellationMatchingState(state);
      HiLog.i(TAG, `constellationMatchingStateChange to ${state}`);
    });
  }

  public releaseConstellationCaptureListener(): void {
    // @ts-ignore
    this.mPhotoOutput.off('constellationMatchingStateChange');
  }

  public async addCaptureListener(): Promise<void> {
    this.mPhotoOutput.on('frameShutter', (err, shutterInfo: camera.FrameShutterInfo) => {
      if (err) {
        HiLog.e(TAG, `frameShutter error: ${err?.code}.`);
        return;
      }
      HiLog.i(TAG, 'frameShutter success.');
      workerCallback.onNormalFrameShutter();
    });
    this.mPhotoOutput.on('frameShutterEnd', (err: BusinessError, frameShutterEndInfo: camera.FrameShutterEndInfo) => {
      if (err) {
        HiLog.e(TAG, `frameShutterEndInfo error: ${err?.code}.`);
        return;
      }
      HiLog.i(TAG, `frameShutterEnd success, captureId:${frameShutterEndInfo.captureId}`);
      workerCallback.onFrameShutterEnd();
    });
    this.mPhotoOutput.on('captureReady', (err) => {
      if (err) {
        HiLog.e(TAG, `captureReadyCallback error: ${err?.code}.`);
        return;
      }
      HiLog.i(TAG, 'captureReady success');
      if (this.mPickerInfo && this.mPickerInfo.isPicker) {
        this.hasCaptureReady = true;
        if (this.hasAvailablePhotoAsset && this.isDeferEnabled) {
          workerCallback.picker2ReleaseCameraFromMainThread();
          this.initPickerCloseRelatedStatus();
        }
      }
      this.mIsInCapture = false;
      workerCallback.nextCapture(this.isDeferEnabled);
    });
    this.mPhotoOutput.on('estimatedCaptureDuration', (err, duration: number): void => {
      if (err) {
        HiLog.e(TAG, `estimatedCaptureDuration error: ${err?.code}.`);
        return;
      }
      HiLog.limitLog(TAG, `get estimatedCaptureDuration: ${duration}`, 'workerEstimatedCaptureLogKey');
      workerCallback.estimatedCaptureDuration(duration);
    });

    if (DeviceInfo.isPhone()) {
      modulesManager.isShouldNotifyNextCapture = false;
    }
  }

  public getIsBurstCapture(): boolean {
    return this.isInBurstCapture; // 是否连拍
  }

  public addExposureListener(mode: ModeType): void {
    this.mPhotoOutput.on('captureStartWithInfo', (err, startInfo: camera.CaptureStartInfo) => {
      if (err) {
        HiLog.e(TAG, `captureStartWithInfo error: ${err?.code}.`);
        return;
      }
      HiLog.i(TAG, `captureStartWithInfo success exposureTime: ${startInfo.time}`);
      workerCallback.onNightCaptureStart(startInfo.time);
    });
  }

  public enable(mode: ModeType, outputType: OutputType): boolean {
    HiLog.i(TAG, 'photoOutput enable begin.');
    this.currentMode = mode;
    this.curOutputType = outputType;
    // this.enableCloudImageEnhance(); // 按能力使能云助端拍照

    this.isDeferEnabled = false;
    try {
      let mIsDeferSupport = this.mPhotoOutput.isDeferredImageDeliverySupported(camera.DeferredDeliveryImageType.PHOTO);
      HiLog.i(TAG, `isDeferredImageDeliverySupported-PHOTO isDeferSupport: ${mIsDeferSupport}.`);
      if (mIsDeferSupport) {
        this.mPhotoOutput.deferImageDelivery(camera.DeferredDeliveryImageType.PHOTO); // 使能分段式拍照
        this.isDeferEnabled = this.mPhotoOutput.isDeferredImageDeliveryEnabled(camera.DeferredDeliveryImageType.PHOTO);
        HiLog.i(TAG, `isDeferredImageDeliveryEnabled-PHOTO: ${this.isDeferEnabled}.`);
      } else {
        // 默认使能,需手动关闭分段式
        this.mPhotoOutput.deferImageDelivery(camera.DeferredDeliveryImageType.NONE);
      }
      // 快速缩略图
      this.isQuickThumbnail = this.queryAndEnableQuickThumbnail(mode, outputType);

      this.mPhotoOutput.on('photoAssetAvailable',
        (err, photoAsset: photoAccessHelper.PhotoAsset) => this.execAvailablePhotoAssetSave(err, photoAsset));

      this.mPhotoOutput.on('error', (err) => this.captureError(err));

      if (this.isProRawDelivery && this.photoProfile.format !== 5) {
        // DNG图处理
        this.mPhotoOutput.on('photoAvailable', (err, photo: camera.Photo) => this.photoAvailableSave(err, photo));
        this.enableProRawDelivery(); // 按条件使能专业RAW图
      }
      this.captureTag = this.isDeferEnabled ? 'SEGMENT_CAPTURE' : 'SINGLE_STAGE';
      return this.isDeferEnabled;
    } catch (err) {
      HiLog.e(TAG, `enable err: ${err.code}.`);
    }
    this.isDeferEnabled = false;
    this.captureTag = 'SINGLE_STAGE';
    return false;
  }

  private async captureError(err): Promise<void> {
    HiLog.i(TAG, 'captureError enter ' + err);
    if (err) {
      // 一次error对应HAL内部拍的一张照片。连拍可能会有很多次error
      HiLog.i(TAG, 'captureError');
      LeftRightSwipeWorkerCaptureService.getInstance().captureError();
    }
  }

  private enableProRawDelivery(): void {
    if (this.isProRawDelivery) {
      HiLog.i(TAG, 'enableRawDelivery true.');
      try {
        this.mPhotoOutput.enableRawDelivery(true);
      } catch (err) {
        HiLog.e(TAG, `enableRawDelivery err: ${err}.`);
      }
    }
  }

  private enableCloudImageEnhance(): void {
    try { // 云助端拍照
      const isAutoCloudImageEnhanceSupported = this.mPhotoOutput.isAutoCloudImageEnhancementSupported();
      HiLog.i(TAG, `enableAutoCloudImageEnhancement:${isAutoCloudImageEnhanceSupported}.`);
      if (isAutoCloudImageEnhanceSupported) {
        this.mPhotoOutput.enableAutoCloudImageEnhancement(true);
        HiLog.i(TAG, 'enableAutoCloudImageEnhancement successful.');
      }
    } catch (err) {
      HiLog.e(TAG, `enableAutoCloudImageEnhancement fail:${err}.`);
    }
  }

  public enableOffline(): void {
    try { // commitConfig之后使能离线拍照
      this.offlineSupport = this.mPhotoOutput.isOfflineSupported();
      if (!this.isDeferEnabled) {
        HiLog.i(TAG, 'SINGLE_STAGE does not support offline');
        this.offlineSupport = false;
      }
      workerCallback.updateOfflineSupport(this.offlineSupport);
      HiLog.i(TAG, `isOfflineSupported:${this.offlineSupport}.`);
      if (this.offlineSupport) {
        this.mPhotoOutput.enableOffline();
        this.mPhotoOutput.on('offlineDeliveryFinished', () => this.offlineDeliveryFinished());
        HiLog.i(TAG, 'enableOffline successful.');
      }
    } catch (err) {
      HiLog.e(TAG, `enableOffline fail:${err}.`);
    }
  }

  private async offlineDeliveryFinished(): Promise<void> {
    // 处理完离线拍照的数据回调，释放离线photoOutput，需要使用setTimeOut异步，否则会死锁
    HiLog.i(TAG, 'offlineDeliveryFinished');
    setTimeout(() => {
      this.mOfflinePhotoFinishCallBack();
    }, RELEASE_OFFLINE_PHOTO_OUTPUT_DELAY);
  }

  private queryAndEnableQuickThumbnail(mode: ModeType, outputType: OutputType): boolean {
    HiLog.i(TAG,
      `queryAndEnableQuickThumbnail isQuickThumbnailSupported ${this.mPhotoOutput.isQuickThumbnailSupported()}`);
    const isQuickThumbnail = this.mPhotoOutput.isQuickThumbnailSupported() &&
      !OutputOperation.isPanVideoOutput(mode, outputType);
    if (!isQuickThumbnail) {
      return false;
    }
    HiLog.i(TAG, 'isQuickThumbnailSupported true.');
    this.mPhotoOutput.enableQuickThumbnail(true);
    this.mPhotoOutput.on('quickThumbnail', (err, pixel: image.PixelMap) => this.quickThumbnail(err, pixel));
    return true;
  }

  public isAutoHighQualityPhotosSupported(): boolean {
    let isAutoHighQualityPhotosSupported: boolean = false;
    try {
      isAutoHighQualityPhotosSupported = this.mPhotoOutput.isAutoHighQualityPhotoSupported();
    } catch (e) {
      HiLog.e(TAG, 'check highQualityPhotoEnable fail.');
    }
    HiLog.i(TAG, `isAutoHighQualityPhotosSupported:${isAutoHighQualityPhotosSupported}.`);
    return isAutoHighQualityPhotosSupported;
  }

  public enableAutoHighQualityPhotos(enabled: boolean): void {
    HiLog.i(TAG, `enableAutoHighQualityPhotos enabled: ${enabled}.`);
    const isAutoHighQualityPhotosSupported = this.isAutoHighQualityPhotosSupported();
    if (!isAutoHighQualityPhotosSupported) {
      return;
    }
    try {
      this.mPhotoOutput.enableAutoHighQualityPhoto(enabled);
    } catch (e) {
      HiLog.e(TAG, 'enableAutoHighQualityPhotos fail.');
    }
  }

  public setMirror(value: boolean): void {
    //自拍镜像不支持
    // if (DeviceInfo.isRk3568() || DeviceInfo.isUis7885()) {
    //   value = false;
    // }
    // HiLog.i(TAG, `setMirror value: ${value}.`);
    // try {
    //   this.mPhotoOutput.enableMirror(value);
    // } catch (err) {
    //   HiLog.e(TAG, `setMirror errcode: ${err?.code}, err: ${JSON.stringify(err)}.`);
    // }
  }

  public setLivePhoto(value: boolean): void {
    HiLog.i(TAG, `setLivePhoto value: ${value}.`);
    if (!this.mPhotoOutput.isMovingPhotoSupported()) {
      return;
    }
    if (!value) {
      this.mPhotoOutput.enableMovingPhoto(false);
      return;
    }
    try {
      let videoCodecArr: camera.VideoCodecType[] = this.mPhotoOutput.getSupportedMovingPhotoVideoCodecTypes();
      let needCodecType = this.savePhotoFormat === 2003 ?
        camera.VideoCodecType.HEVC : camera.VideoCodecType.AVC;
      HiLog.i(TAG, `setLivePhoto format-needCodecType: ${this.savePhotoFormat}-${needCodecType}.`);
      HiLog.i(TAG, `setLivePhoto videoCodecArray: ${videoCodecArr.toString()}.`);
      let resultCodecType = camera.VideoCodecType.AVC;
      for (let i = 0; i < videoCodecArr.length; i++) {
        if (videoCodecArr[i] === needCodecType) {
          resultCodecType = videoCodecArr[i];
          break;
        } else if (videoCodecArr[i] === camera.VideoCodecType.AVC) {
          resultCodecType = videoCodecArr[i];
        }
      }
      HiLog.i(TAG, `setLivePhoto setMovingPhotoVideoCodec: ${resultCodecType}.`);
      this.mPhotoOutput.setMovingPhotoVideoCodecType(resultCodecType);
    } catch (err) {
      HiLog.e(TAG, `setLivePhoto queryAndSetVideoCodec err: ${err?.code}.`);
    }
    this.mPhotoOutput.enableMovingPhoto(true);
  }

  public refreshPickerInfo(pickerInfo: PickerInfo): void {
    this.mPickerInfo = pickerInfo;
  }

  public getIsQuickThumbnailSupported(): boolean {
    return this.isQuickThumbnail;
  }

  public getIsOfflineSupport(): boolean {
    return this.offlineSupport;
  }

  // -------- 下述注册相机框架监听回调方法 -------- //

  /*
   * 带维测信息的图片上报通路;(不再用于区分单分段式,分段式80分图、单段式真图均走改通路上报)
   */
  private async execAvailablePhotoAssetSave(err, deferPhotoAsset: photoAccessHelper.PhotoAsset): Promise<void> {
    HiLog.i(TAG, `${this.captureTag} SHOT2SEE deferredPhotoProxyAvailable success. ${deferPhotoAsset.displayName}`);
    HiLog.i(TAG, 'shot2see endTime');
    if (!!err) {
      const error = `Camera_photoAssetAvailable failed: ${err?.code}}`;
      HiLog.e(TAG, error);
      this.mOfflinePhotoReceiveCallBack(-1);
      return;
    }
    // @ts-ignore
    let captureId: string = deferPhotoAsset.captureId;
    if (captureId && captureId !== '' && this.mQuickThumbnailMap.get(captureId)) {
      HiLog.i(TAG, `${this.captureTag} SHOT2SEE execAvailablePhotoAssetSave captureId: ${captureId}.`);
      workerCallback.captureIdPhotoAsset(captureId, deferPhotoAsset);
      this.mQuickThumbnailMap.delete(captureId);
    }

    this.mOfflinePhotoReceiveCallBack(captureId);
    if (!this.mPickerInfo.isPicker) {
      workerCallback.minusPhotoCount();
    }
    if (!this.isSupportLrSwipeNewCapture) {
      workerCallback.onDeferPhotoReport(deferPhotoAsset.uri); // 机型不支持左滑右滑场景
    }
    const mediaLibrary = await modulesManager.getMediaLibrary();
    let assetUri = await mediaLibrary.captureSavePhotoAsset(this.captureTag, deferPhotoAsset, this.currentMode,
      this.photoProfile.format, this.savePhotoFormat, this.mPickerInfo, this.isBackCapture);
    await this.processPickerPhoto(deferPhotoAsset);
    if (!this.isSupportLrSwipeNewCapture) {
      workerCallback.onDeferPhotoMediaUri(assetUri); // 机型不支持左滑右滑场景
    }
  }

  // picker场景特殊流程; 获取pixelMap、传递三方uri、closeCamera
  private async processPickerPhoto(deferPhotoAsset: photoAccessHelper.PhotoAsset): Promise<void> {
    if (this.mPickerInfo && this.mPickerInfo.isPicker) {
      if (!this.isQuickThumbnail && DeviceInfo.isPc()) {
        await this.getPcPickerPixelMap(deferPhotoAsset);
        workerCallback.pcPickerReceived(this.pcPickerPhotoMap);
      }
      const pickerWorkerService = await modulesManager.getPickerFileWorkerService();
      const pickerResolve: PickerSaveResolveType = {
        uri: this.mPickerInfo?.uri,
        uriFromLocal: !this.mPickerInfo.uri ? true : false
      };
      pickerWorkerService.setPickerResolve(pickerResolve);
      this.hasAvailablePhotoAsset = true;
      if (this.hasCaptureReady) {
        workerCallback.picker2ReleaseCameraFromMainThread();
        this.initPickerCloseRelatedStatus();
      }
    }
  }

  private initPickerCloseRelatedStatus(): void { // picker 拍照进到pickerView界面，captureReady和80分后回的触发关闭相机
    if (this.mPickerInfo.isPicker) {
      this.hasCaptureReady = false;
      this.hasAvailablePhotoAsset = false;
    }
  }

  public async quickThumbnail(err, pixel: image.PixelMap): Promise<void> {
    HiLog.i(TAG, `SHOT2SEE quickThumbnail success.
     Pixel info height: ${pixel.getImageInfoSync().size.height}, width: ${pixel.getImageInfoSync().size.width}`);
    if (err) {
      const error = `Camera_quickThumbnail Error: ${err?.code}}`;
      HiLog.e(TAG, error);
      return;
    }
    let mediaLibraryService = await modulesManager.getMediaLibrary();
    let resPixelMap: image.PixelMap =
      await mediaLibraryService.getQuickThumbnailWatermarkFilter(pixel, this.isInBurstCapture);
    if (this.mQuickThumbnailMap === undefined || this.mQuickThumbnailMap === null) {
      this.mQuickThumbnailMap = new Map<string, image.PixelMap>();
    }
    // @ts-ignore
    let captureId: string = pixel.captureId;
    if ((captureId && captureId !== '')) {
      HiLog.i(TAG, `quickThumbnail captureId: ${captureId}, ${this.mQuickThumbnailMap.get(captureId)}.`);
      workerCallback.captureIdQuickThumbnail(captureId, resPixelMap);
      this.mQuickThumbnailMap.set(captureId, resPixelMap);
    }

    try {
      workerCallback.quickThumbnail(resPixelMap, this.isDeferEnabled);
      if (this.mPickerInfo.isPicker) {
        // const pickerWorkerService = await modulesManager.getPickerFileWorkerService();
        // pickerWorkerService.resetPickerBuffer();
        return;
      }
      if (!this.isDeferEnabled) {
        const mediaLibrary = await modulesManager.getMediaLibrary();
        await mediaLibrary.saveThumbnail(pixel, this.savePhotoFormat)
      }
    } catch (e) {
      const error = `onQuickThumbnail save error: ${JSON.stringify(e)}.`;
      HiLog.e(TAG, error);
    } finally {
      pixel?.release();
      resPixelMap?.release();
    }
  }

  public async getPcPickerPixelMap(deferPhotoAsset?: photoAccessHelper.PhotoAsset): Promise<void> {
    if (!deferPhotoAsset) {
      return undefined;
    }
    // 横屏相机or竖屏相机横屏状态两张图片传入主线程，在主线程判断使用
    const size: image.Size = this.photoProfile.size;
    if (this.pcPickerPhotoMap === undefined || this.pcPickerPhotoMap === null) {
      this.pcPickerPhotoMap = new Map<string, image.PixelMap>();
    }
    this.pcPickerPhotoMap.set('landscape', await deferPhotoAsset.getThumbnail(size));
    this.pcPickerPhotoMap.set('portrait', await deferPhotoAsset.getThumbnail({
      height: size.width,
      width: size.height
    }));
  }

  /*
   * 不带维测信息的图片上报通路;当前仅延时摄影、专业DNG图上报
   */
  private async photoAvailableSave(err, photoMessage: camera.Photo): Promise<void> {
    if (err) {
      const error = `Camera_PhotoAvailable Error: ${err?.code}}`;
      HiLog.e(TAG, error);
      return;
    }
    HiLog.i(TAG, `${this.captureTag} enableSingleStagePhoto begin.`);
    let imageInfo: image.Image;
    let img: image.Component;
    try {
      imageInfo = photoMessage.main;
      img = await imageInfo.getComponent(image.ComponentType.JPEG)
      HiLog.i(TAG, `${this.captureTag} getComponent success.`);
      if (!img || !img.byteBuffer) {
        HiLog.e(TAG, 'saveImage getComponent img is undefined error.');
        return;
      }
      await this.saveHighQualityWhenPhotoAvailable(img,
        this.isProRawDelivery ? camera.CameraFormat.CAMERA_FORMAT_DNG : this.savePhotoFormat);
    } catch (error) {
      const err: string = `SHOT2SEE enableSingleStagePhoto error: ${error?.code}.`;
      HiLog.e(TAG, err);
    } finally {
      await imageInfo?.release();
      // @ts-ignore
      await photoMessage?.rawImage?.release();
      await photoMessage.release();
      HiLog.i(TAG, `${this.captureTag} enableSingleStagePhoto end.`);
    }
  }

  private async saveHighQualityWhenPhotoAvailable(img: image.Component, mSavePhotoFormat: camera.CameraFormat):
    Promise<void> {
    const buffer = img.byteBuffer;
    const pickerWorkerService = await modulesManager.getPickerFileWorkerService();
    const isPicker = pickerWorkerService.photoArrival(buffer, this.mPickerInfo, mSavePhotoFormat);
    if (!isPicker) {
      const mediaLibrary = await modulesManager.getMediaLibrary();
      let HighQualityUri =
        await mediaLibrary.saveHighQualityImage(buffer, this.isQuickThumbnail, mSavePhotoFormat);
    }
  }

  public isInCapture(): boolean {
    return this.mIsInCapture;
  }

  public setUltraPhoto(value: boolean): void {
    HiLog.i(TAG, `setUltraPhoto value: ${value}.`);
    try {
      // @ts-ignore
      const isAutoMotionBoostDeliverySupported = this.mPhotoOutput.isAutoMotionBoostDeliverySupported();
      if (isAutoMotionBoostDeliverySupported) {
        // @ts-ignore
        this.mPhotoOutput.enableAutoMotionBoostDelivery(value);
        HiLog.i(TAG, 'setUltraPhoto enableAutoMotionBoostDelivery');
      }
    } catch (e) {
      HiLog.e(TAG, 'enableAutoMotionBoostDelivery fail.');
    }
    try {
      // @ts-ignore
      const isAutoBokehDataDeliverySupported = this.mPhotoOutput.isAutoBokehDataDeliverySupported();
      if (isAutoBokehDataDeliverySupported) {
        // @ts-ignore
        this.mPhotoOutput.enableAutoBokehDataDelivery(value);
        HiLog.i(TAG, 'setUltraPhoto enableAutoBokehDataDelivery');
      }
    } catch (e) {
      HiLog.e(TAG, 'enableAutoBokehDataDelivery fail.');
    }
  }
}