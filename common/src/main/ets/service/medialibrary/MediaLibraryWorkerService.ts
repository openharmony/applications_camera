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

import photoAccessHelper from '@ohos.file.photoAccessHelper';
import lazy { image } from '@kit.ImageKit';
import lazy { HiLog } from '../../utils/HiLog';
import camera from '@ohos.multimedia.camera';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { CaptureFailedType } from '../../camera/DataType';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { modulesManager } from '../../worker/WorkerModuleManager';
import type { Fail, PickerInfo } from '../../utils/types';
import lazy { PickerFileWorkerService } from '../picker/PickerFileWorkerService';
import lazy { workerCallback } from '../../camera/childthread/WorkerCallback';
import CameraContext from '../../camera/childthread/modules/CameraContext';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { WorkerDataCache } from '../../camera/childthread/WorkerDataCache';
import lazy { simpleStringify } from '../../utils/SimpleStringify';
import lazy { getStates } from '../../redux';
import RecorderWrap from '../../camera/childthread/modules/video/RecorderWrap';
// import lazy { awareness } from '@kit.ServiceCollaborationKit';
import lazy { LocationMessage, LocationType } from '../location/LocationMessage';
import MediaLibraryOperation from './MediaLibraryOperation';
import { DateTimeUtil } from '../../utils/LazyImportUtil';
import {
  LeftRightSwipeWorkerCaptureService
} from '../../component/leftrightswipecontrol/LeftRightSwipeWorkerCaptureService';

const TAG: string = 'MediaLibraryWorkerService';
const WAIT_TIME = 100; // 100:Waiting duration

enum CaptureScene {
  QUICK_SAVING = 'QUICK_SAVING',
  QUICK_SAVED = 'QUICK_SAVED',
  REAL_WAIT = 'REAL_WAIT',
  REAL_SAVING = 'REAL_SAVING',
  REAL_SAVED = 'REAL_SAVED'
}

/* instrument ignore file */
export default class MediaLibraryWorkerService {
  private static sInstance: MediaLibraryWorkerService;
  // 流程控制
  private mQueuePhotoAsset: photoAccessHelper.PhotoAsset[] = new Array();
  private mCaptureScene: CaptureScene = CaptureScene.REAL_SAVED;
  // 数据缓存
  private mQueueBuffer: ArrayBuffer[] = new Array();
  // 媒体库接口
  private mPhotoAccessHelper: photoAccessHelper.PhotoAccessHelper;
  private isSupportLrSwipeNewCapture: boolean;
  private mRequestId: string = '';

  public static getInstance(): MediaLibraryWorkerService {
    if (!MediaLibraryWorkerService.sInstance) {
      HiLog.begin(TAG, 'FileServiceCreate');
      MediaLibraryWorkerService.sInstance = new MediaLibraryWorkerService();
      HiLog.end(TAG, 'FileServiceCreate');
    }
    return MediaLibraryWorkerService.sInstance;
  }

  private constructor() {
    HiLog.i(TAG, 'MediaLibraryWorkerService constructor.');
    this.mPhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(GlobalContext.get().getWorkerContext());
  }

  // 单段式高质量图落盘
  public async saveHighQualityImage(buffer: ArrayBuffer, isQuickThumbnail: boolean,
    mSavePhotoFormat: camera.CameraFormat): Promise<string> {
    HiLog.i(TAG,
      `SINGLE_STAGE saveHighQualityImage isQuickThumbnail: ${isQuickThumbnail}, captureScene: ${this.mCaptureScene}.`);
    if (!isQuickThumbnail || (mSavePhotoFormat === camera.CameraFormat.CAMERA_FORMAT_DNG)) {
      HiLog.i(TAG, 'SINGLE_STAGE saveHighQualityImage is not quickThumbnail.');
      const photoAsset: photoAccessHelper.PhotoAsset =
        await MediaLibraryOperation.createPhotoAsset(this.mPhotoAccessHelper,
          photoAccessHelper.PhotoType.IMAGE, mSavePhotoFormat);
      await this.savePhotoFile(photoAsset, buffer, mSavePhotoFormat);
      this.notifyNextCapture();
      return photoAsset.uri;
    }
    if (this.mQueuePhotoAsset.length === 0) {
      HiLog.i(TAG, 'SINGLE_STAGE saveHighQualityImage captureScene QUICK_SAVING, set REAL_WAIT.');
      this.mQueueBuffer.push(buffer);
      this.mCaptureScene = CaptureScene.REAL_WAIT;
      return '';
    }
    this.mCaptureScene = CaptureScene.REAL_SAVING;
    HiLog.i(TAG, 'SINGLE_STAGE saveHighQualityImage has quickThumbnail file, save image buffer.');
    let photoAsset: photoAccessHelper.PhotoAsset = this.mQueuePhotoAsset.shift();
    await this.savePhotoFile(photoAsset, buffer, mSavePhotoFormat);
    return photoAsset.uri;
  }

  private notifyNextCapture(): void {
    if (modulesManager.isShouldNotifyNextCapture) {
      workerCallback.nextCapture(false);
    }
  }

  public async saveThumbnail(pixel: image.PixelMap, savePhotoFormat: camera.CameraFormat): Promise<void> {
    HiLog.i(TAG, `SHOT2SEE SaveThumbnail invoke, captureScene: ${this.mCaptureScene}.`);
    this.mCaptureScene = CaptureScene.QUICK_SAVING;
    const imagePackerApi = image.createImagePacker();
    const buffer: ArrayBuffer = await imagePackerApi.packing(pixel, {
      format: 'image/jpeg', quality: 50
    });
    HiLog.i(TAG, 'SINGLE_STAGE SHOT2SEE saveThumbnail create file buffer.');
    const photoAsset: photoAccessHelper.PhotoAsset =
      await MediaLibraryOperation.createPhotoAsset(this.mPhotoAccessHelper,
        photoAccessHelper.PhotoType.IMAGE, savePhotoFormat);
    if (!photoAsset) {
      HiLog.e(TAG, 'SINGLE_STAGE SHOT2SEE saveThumbnail photoAsset is null.');
      return;
    }
    workerCallback.quickThumbnailPrepare(photoAsset.uri);
    HiLog.i(TAG, 'SINGLE_STAGE SHOT2SEE saveThumbnail photoAsset created.');
    await this.saveFileByBufferWithWatermark(photoAsset, buffer, savePhotoFormat);
    HiLog.i(TAG, 'SINGLE_STAGE SHOT2SEE saveThumbnail photoAsset write done.');
    setTimeout((): void => {
      this.notifyNextCapture();
    }, WAIT_TIME);
    if (this.mQueueBuffer.length === 0) {
      HiLog.i(TAG, 'SINGLE_STAGE SHOT2SEE saveThumbnail save finished.');
      this.mQueuePhotoAsset.push(photoAsset);
      this.mCaptureScene = CaptureScene.QUICK_SAVED;
      return;
    }
    HiLog.i(TAG, 'SINGLE_STAGE SHOT2SEE saveThumbnail saved, save image buffer.');
    await this.savePhotoFile(photoAsset, this.mQueueBuffer.shift(), savePhotoFormat);
    await imagePackerApi.release();
  }

  static clonePixelMap(pixelMap: image.PixelMap, desiredPixelFormat?: image.PixelMapFormat): image.PixelMap {
    const imageInfo = pixelMap.getImageInfoSync();
    const buffer = new ArrayBuffer(pixelMap.getPixelBytesNumber());
    pixelMap.readPixelsToBufferSync(buffer);
    const options: image.InitializationOptions = {
      editable: true,
      srcPixelFormat: imageInfo.pixelFormat,
      pixelFormat: desiredPixelFormat ?? imageInfo.pixelFormat,
      size: imageInfo.size
    };
    if (imageInfo.pixelFormat === image.PixelMapFormat.YCRCB_P010) {
      HiLog.i(TAG, 'pixelFormat is YCRCB_P010, return original pixel map.');
      return pixelMap;
    } else {
      const clonePixelMap = image.createPixelMapSync(buffer, options);
      clonePixelMap.setColorSpace(pixelMap.getColorSpace());
      if (clonePixelMap !== undefined) {
        try {
          clonePixelMap.setMemoryNameSync(TAG);
        } catch (e) {
          HiLog.e(TAG, 'clonePixelMap setMemoryNameSync error');
        }
      }
      return clonePixelMap;
    }
  }

  public async getQuickThumbnailWatermarkFilter(pixel: image.PixelMap,
    isInBurstCapture: boolean): Promise<image.PixelMap> {
    if (isInBurstCapture) {
      return pixel;
    }

    HiLog.i(TAG,
      `quickThumbnail pixelSize: ${pixel.getImageInfoSync().size.height}x${pixel.getImageInfoSync().size.width},
     ${pixel?.getPixelBytesNumber()}. is align? ${pixel?.isStrideAlignment}, iseditable? ${pixel?.isEditable}`);
    HiLog.i(TAG, `quickThumbnail addWatermarkFilter succeed, ${pixel.getColorSpace().getColorSpaceName()}.`);
    return pixel;
  }

  // 生成edit data
  private generateEditData(burstKey: string): photoAccessHelper.MediaAssetEditData {
    const editData: photoAccessHelper.MediaAssetEditData = new photoAccessHelper.MediaAssetEditData('system', '1');
    return editData;
  }

  public async captureSavePhotoAsset(captureTag: string, deferPhotoAsset: photoAccessHelper.PhotoAsset, mode: ModeType,
    profileFormat: camera.CameraFormat, savePhotoFormat: camera.CameraFormat, pickerInfo: PickerInfo,
    isBackCapture: boolean): Promise<string> { // 带维测信息通路图片落盘
    HiLog.i(TAG, `${captureTag} captureSavePhotoAsset E.`);
    try {
      HiLog.i(TAG, `${captureTag} captureSavePhotoAsset: ${deferPhotoAsset.displayName}.`);
      if (!deferPhotoAsset) {
        return '';
      }
      await this.assetSaveCameraPhoto(captureTag, deferPhotoAsset, mode, profileFormat, savePhotoFormat, pickerInfo,
        isBackCapture);
      HiLog.i(TAG, `${captureTag} end.`);
      return deferPhotoAsset.uri;
    } catch (err) {
      const error: string = `captureSavePhotoAsset err: ${err}, ${err?.code}.`;
      workerCallback.onCaptureEnd();
      HiLog.e(TAG, error);
      return '';
    }
  }

  private getBurstKey(photoAsset: photoAccessHelper.PhotoAsset): string {
    let burstKey: string = '';
    let photoSubtype: number = -1;
    try {
      photoSubtype = photoAsset.get('subtype') as number;
      HiLog.i(TAG, 'subtype from mediaLib:' + photoSubtype);
      if (photoSubtype !== 4) {
        // photoAccessHelper.PhotoSubtype.BURST
        return '';
      }
      burstKey = photoAsset.get('burst_key') as string;
      HiLog.i(TAG, 'burst_key from mediaLib =' + burstKey);
    } catch (e) {
      HiLog.i(TAG, `asset getBurstKey with error:` + e.code);
    }
    return burstKey;
  }

  private async assetSaveCameraPhoto(captureTag: string, deferPhotoAsset: photoAccessHelper.PhotoAsset, mode: ModeType,
    profileFormat: camera.CameraFormat, savePhotoFormat: camera.CameraFormat, pickerInfo: PickerInfo,
    isBackCapture: boolean): Promise<void> {
    try {
      const mediaRequest: photoAccessHelper.MediaAssetChangeRequest =
        new photoAccessHelper.MediaAssetChangeRequest(deferPhotoAsset);
      HiLog.i(TAG, `${captureTag} new MediaAssetChangeRequest end.`);
      let cameraShotKey: string = getStates().get<string>('securityCameraReducer', 'cameraShotKey') ||
      GlobalContext.get().getCameraShotKey();
      if (cameraShotKey) {
        mediaRequest.setCameraShotKey(cameraShotKey);
        HiLog.i(TAG, `${captureTag} setCameraShotKey end.`);
      }
      mediaRequest.setLocation(114.5092, 30.5225)
      let burstKey = this.getBurstKey(deferPhotoAsset);
      // todo RPX 暂时屏蔽连拍水印滤镜，依赖媒体库需求SR20240604727711
      // @ts-ignore
      let saveCameraType: photoAccessHelper.ImageFileType | undefined = undefined;
      if (!pickerInfo || !pickerInfo.isPicker) {
        try {
          saveCameraType = (savePhotoFormat === 2003 && !RecorderWrap.getInstance().getIsRecording()) ?
            photoAccessHelper.ImageFileType.HEIF : photoAccessHelper.ImageFileType.JPEG;
        } catch (err) {
          HiLog.e(TAG, `${captureTag} YUV-HEIF-setJPEG getCameraType err: ${err?.code}.`);
        }
        // @ts-ignore
        let captureId: string = deferPhotoAsset.captureId;
        HiLog.i(TAG, `assetSaveCameraPhoto: ${captureId}`);
        await this.processRequest(captureTag, burstKey, mediaRequest, saveCameraType, Number(captureId));
      }
    } catch (err) {
      HiLog.i(TAG, `${captureTag} mediaRequest error: ${err}, ${err?.code}.`);
    }
    if (pickerInfo && pickerInfo.isPicker) {
      const pickerWorkerService = await modulesManager.getPickerFileWorkerService();
      if (profileFormat === camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP) {
        this.requestYuvPictureBuffer(captureTag, deferPhotoAsset, pickerWorkerService);
      } else {
        this.requestImageBuffer(captureTag, deferPhotoAsset, pickerWorkerService);
      }
    }
  }

  private async processRequest(captureTag: string, burstKey: string,
    mediaRequest: photoAccessHelper.MediaAssetChangeRequest,
    // @ts-ignore
    saveCameraType: photoAccessHelper.ImageFileType | undefined, captureId: number): Promise<void> {
    HiLog.begin(TAG, 'processRequest');
    if (burstKey !== '') {
      workerCallback.resetPhotoCount();
      HiLog.i(TAG, `${captureTag} burst capture process end.`);
    } else {
      if (this.isSupportLrSwipeNewCapture) {
        LeftRightSwipeWorkerCaptureService.getInstance()
          .setSingleCaptureRequestForDelete(mediaRequest, saveCameraType, captureId);
        HiLog.i(TAG, `${captureTag} request process end.`);
      } else {
        this.saveRequest(captureTag, mediaRequest, saveCameraType);
        // @ts-ignore
        // TODO PictureCameraDuration未定义，导致阻塞后续缩略图保存
        // PictureCameraDuration.getInstance().setSavePictureFailReason('MediaLib_ApplyChanges failed');
        await this.mPhotoAccessHelper.applyChanges(mediaRequest);
        HiLog.i(TAG, `${captureTag} applyChanges end.`);
      }
    }
    HiLog.end(TAG, 'processRequest');
  }

  private saveRequest(captureTag: string, mediaRequest: photoAccessHelper.MediaAssetChangeRequest,
    // @ts-ignore
    saveCameraType: photoAccessHelper.ImageFileType | undefined): void {
    try {
      HiLog.i(TAG, `${captureTag} request apply saveCameraPhoto: ${saveCameraType}.`);
      // @ts-ignore
      mediaRequest.saveCameraPhoto(saveCameraType);
    } catch (err) {
      HiLog.e(TAG, `${captureTag} YUV-HEIF-setJPEG saveCameraPhoto err: ${err?.code}.`);
      HiLog.i(TAG, `${captureTag} request apply saveCameraPhoto.`);
      mediaRequest.saveCameraPhoto();
    }
    HiLog.i(TAG, `${captureTag} saveCameraPhoto end.`);
  }

  public async requestHighQualityImage(captureTag: string, asset: photoAccessHelper.PhotoAsset): Promise<void> {
    HiLog.i(TAG, 'requestHighQualityImage E.');
    const dataHandler: photoAccessHelper.MediaAssetDataHandler<image.ImageSource> = {
      onDataPrepared(data: image.ImageSource): void {
        HiLog.i(TAG, `onDataPrepared.`);
        try {
          data?.getImageInfo().then((info): void => {
            workerCallback.onCaptureEnd();
            HiLog.i(TAG, `getImageInfo info?.size height: ${info?.size.height}, width: ${info?.size.width}.`);
          });
        } catch (error) {
          HiLog.e(TAG, 'getImageInfo error.');
        } finally {
          this.mRequestId = '';
        }
      }
    };
    const requestOp: photoAccessHelper.RequestOptions = {
      deliveryMode: photoAccessHelper.DeliveryMode.HIGH_QUALITY_MODE,
      sourceMode: photoAccessHelper.SourceMode.ORIGINAL_MODE
    };
    try {
      this.mRequestId =
        await photoAccessHelper.MediaAssetManager.requestImage(GlobalContext.get().getWorkerContext(), asset, requestOp,
          dataHandler);
    } catch (error) {
      HiLog.e(TAG, `photoAccessHelper requestImage error: ${error}, code: ${error?.code}.`);
    }
    HiLog.i(TAG, `${captureTag} requestHighQualityImage X.`);
  }

  public cancelRequestHighQualityImage(): void {
    if (this.mRequestId === '') {
      return;
    }
    try {
      photoAccessHelper.MediaAssetManager.cancelRequest(GlobalContext.get().getWorkerContext(), this.mRequestId);
    } catch (error) {
      HiLog.e(TAG, `photoAccessHelper cancelRequest error: ${error}, code: ${error?.code}.`);
    } finally {
      this.mRequestId = '';
    }
  }

  public async requestYuvPictureBuffer(captureTag: string, asset: photoAccessHelper.PhotoAsset,
    pickerWorkerService: PickerFileWorkerService): Promise<void> {
    HiLog.i(TAG, `${captureTag} requestYuvPictureBuffer E.`);
    let requestOptions: photoAccessHelper.RequestOptions = {
      deliveryMode: photoAccessHelper.DeliveryMode.BALANCE_MODE,
      sourceMode: photoAccessHelper.SourceMode.ORIGINAL_MODE
    };
    // @ts-ignore
    const dataHandler: photoAccessHelper.QuickImageDataHandler<image.Picture> = {
      // @ts-ignore
      async onDataPrepared(yuvPicture: image.Picture, imageSource: image.ImageSource): void {
        HiLog.i(TAG, 'onDataPrepared callback E.');
        let buffer: ArrayBuffer;
        if (yuvPicture) {
          HiLog.i(TAG, 'onDataPrepared yuvPicture createImagePacker start.');
          const imagePacker = image.createImagePacker();
          HiLog.i(TAG, 'onDataPrepared imagePackerApi.packing start.');
          let packOpts: image.PackingOption = {
            format: pickerWorkerService.getYuvPicturePackerFormat(), quality: 100
          };
          buffer = await imagePacker.packing(yuvPicture, packOpts);
          HiLog.i(TAG, `onDataPrepared imagePackerApi.packing buffer.byteLength: ${buffer.byteLength}.`);
          imagePacker.release();
        } else {
          let storageDiskPixelMap = imageSource.createPixelMapSync();
          try {
            storageDiskPixelMap?.setMemoryNameSync(TAG);
          } catch (e) {
            HiLog.e(TAG, 'clonePixelMap setMemoryNameSync error');
          }
          HiLog.i(TAG, `onDataPrepared storageDiskPixelMap.createPixelMapSync: ${storageDiskPixelMap.isEditable}.`);
          buffer = new ArrayBuffer(storageDiskPixelMap.getPixelBytesNumber());
          HiLog.i(TAG, 'onDataPrepared getPixelBytesNumber.');
          storageDiskPixelMap.readPixelsToBuffer(buffer);
          HiLog.i(TAG, `onDataPrepared readPixelsToBufferSync: ${buffer.byteLength}.`);
        }
        pickerWorkerService.savePickerBuffer(buffer, asset.displayName);
        HiLog.i(TAG, `onDataPrepared savePickerBuffer: ${asset.displayName}.`);
      }
    };
    HiLog.i(TAG, `${captureTag} MediaAssetManager.quickRequestImage E.`);
    let requestId =
      // @ts-ignore
      await photoAccessHelper.MediaAssetManager.quickRequestImage(GlobalContext.get().getWorkerContext(), asset,
        requestOptions, dataHandler);
    HiLog.i(TAG, `${captureTag} requestYuvPictureBuffer requestId: ${requestId} X.`);
  }

  public async requestImageBuffer(captureTag: string, asset: photoAccessHelper.PhotoAsset,
    pickerWorkerService: PickerFileWorkerService): Promise<string> {
    HiLog.i(TAG, 'requestImageBuffer E.');
    const dataHandler: photoAccessHelper.MediaAssetDataHandler<ArrayBuffer> = {
      onDataPrepared(buffer: ArrayBuffer, map: Map<string, string>): void {
        pickerWorkerService.savePickerBuffer(buffer, asset.displayName);
        HiLog.i(TAG, `onDataPrepared buffer: ${buffer?.byteLength}, map: ${JSON.stringify(map)}`);
      }
    };
    const requestOp: photoAccessHelper.RequestOptions = {
      deliveryMode: photoAccessHelper.DeliveryMode.BALANCE_MODE,
      sourceMode: photoAccessHelper.SourceMode.ORIGINAL_MODE
    };
    let requestId: string = '';
    try {
      requestId = await photoAccessHelper.MediaAssetManager.requestImageData(
        GlobalContext.get().getWorkerContext(), asset, requestOp, dataHandler);
    } catch (error) {
      HiLog.e(TAG, `photoAccessHelper requestImageBuffer error: ${error}, code: ${error?.code}.`);
    }
    HiLog.i(TAG, `${captureTag} requestBalanceImageBuffer X.`);
    return requestId;
  }

  public async createPhotoFile(buffer: ArrayBuffer,
    savePhotoFormat: camera.CameraFormat): Promise<photoAccessHelper.PhotoAsset> {
    const photoAsset: photoAccessHelper.PhotoAsset =
      await MediaLibraryOperation.createPhotoAsset(this.mPhotoAccessHelper, photoAccessHelper.PhotoType.IMAGE,
        savePhotoFormat);
    await this.savePhotoFile(photoAsset, buffer, savePhotoFormat);
    return photoAsset;
  }

  private async saveFileByBufferWithWatermark(photoAsset: photoAccessHelper.PhotoAsset, buffer: ArrayBuffer,
    mSavePhotoFormat: camera.CameraFormat): Promise<void> {
    HiLog.i(TAG, `saveFileByBufferWithWatermark E`);
    let changeRequest: photoAccessHelper.MediaAssetChangeRequest =
      new photoAccessHelper.MediaAssetChangeRequest(photoAsset);
    changeRequest.addResource(photoAccessHelper.ResourceType.IMAGE_RESOURCE, buffer);
    await this.mPhotoAccessHelper.applyChanges(changeRequest);
    HiLog.i(TAG, `saveFileByBufferWithWatermark X`);
  }

  private async savePhotoFile(photoAsset: photoAccessHelper.PhotoAsset, buffer: ArrayBuffer,
    mSavePhotoFormat: camera.CameraFormat): Promise<void> {
    await this.saveFileByBufferWithWatermark(photoAsset, buffer, mSavePhotoFormat);
    HiLog.i(TAG, `SHOT2SEE savePhotoFile image saved, photoUri: ${photoAsset.uri}`);
    workerCallback.photoSaved(photoAsset.uri);
    this.mCaptureScene = CaptureScene.REAL_SAVED;
  }

  public async createVideoFile(): Promise<photoAccessHelper.PhotoAsset> {
    HiLog.i(TAG, 'createVideoFd E.');
    const photoAsset: photoAccessHelper.PhotoAsset =
      await MediaLibraryOperation.createPhotoAsset(this.mPhotoAccessHelper, photoAccessHelper.PhotoType.VIDEO,
        camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP);
    HiLog.i(TAG, 'createVideoFd X.');
    return photoAsset;
  }

  public async deleteVideoAsset(uri: string): Promise<void> {
    HiLog.i(TAG, `deleteAsset uri: ${JSON.stringify(uri)}.`);
    try {
      await this.mPhotoAccessHelper.deleteAssets([uri]).catch((err) => {
        HiLog.e(TAG, `deleteAssets error: ${JSON.stringify(err)}.`);
      });
      HiLog.i(TAG, 'TYPE_TRASH Album deleteAssets.');

      const albumFetchResult: photoAccessHelper.FetchResult<photoAccessHelper.Album> =
        await this.mPhotoAccessHelper.getAlbums(photoAccessHelper.AlbumType.SYSTEM,
          photoAccessHelper.AlbumSubtype.TRASH);
      const trashAlbum: photoAccessHelper.Album = await albumFetchResult.getFirstObject();
      HiLog.i(TAG, 'deleteAssets get trashAlbum successfully.');

      const fetchOption: photoAccessHelper.FetchOptions = {
        fetchColumns: [],
        predicates: null
      };
      HiLog.i(TAG, `deleteAsset fetchOptions: ${JSON.stringify(fetchOption)}.`);
      const fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> =
        await trashAlbum.getAssets(fetchOption);
      const asset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject();
      HiLog.i(TAG, `deleteAsset asset: ${JSON.stringify(asset)}.`);
      await trashAlbum.deleteAssets([asset]);
      albumFetchResult.close();
      fetchResult.close();
      HiLog.i(TAG, 'album deleteAssets successfully.');
    } catch (err) {
      HiLog.e(TAG, `deleteAsset Err. ${JSON.stringify(err)}`);
    }
  }

  private makeVideoFileName(): string {
    let fileHeader: string = WorkerDataCache.getInstance().getSlowMotionStatus() ? 'SL_MO_VID' : 'VID';
    const dateTimeUtil: DateTimeUtil = new DateTimeUtil();
    const name =
      `${MediaLibraryOperation.checkName(`${fileHeader}_${dateTimeUtil.getDate()}_${dateTimeUtil.getTime()}`)}`;
    HiLog.i(TAG, `RECORD_TRACK make videoFile newName: ${name}.`);
    return name;
  }

  public async renameVideoFile(uri: string, cameraShotKey: string): Promise<string> {
    const name = this.makeVideoFileName();
    try {
      const photoAsset = await MediaLibraryOperation.getLastPhotoAsset(this.mPhotoAccessHelper, { uri },
        cameraShotKey);
      if (!photoAsset) {
        HiLog.e(TAG, `getLastPhotoAsset videoUri: ${uri} error, asset undefined.`);
        return uri;
      }
      HiLog.i(TAG, `renameFile photoAsset: ${JSON.stringify(photoAsset.displayName)}.`);
      const oldName: string = photoAsset.displayName;
      photoAsset.set(photoAccessHelper.PhotoKeys.TITLE.toString(), name);
      await photoAsset.commitModify();
      HiLog.i(TAG, `renameFile commitModify done, uri: ${photoAsset.uri}.`);
      const afterRenameUri: string = photoAsset.uri.replace(oldName, `${name}.mp4`);
      HiLog.i(TAG, `oldName: ${oldName}, afterRenameUri, uri: ${afterRenameUri}.`);

      try {
        let videoEnhancePhotoId = CameraContext.getInstance().consumeVideoEnhancePhotoId().toString();
        if (!videoEnhancePhotoId) {
          return afterRenameUri;
        }
        HiLog.i(TAG, 'SEGMENT_VIDEO new mediaRequest E.');
        const mediaRequest: photoAccessHelper.MediaAssetChangeRequest =
          new photoAccessHelper.MediaAssetChangeRequest(photoAsset);
        HiLog.d(TAG, `SEGMENT_VIDEO mediaRequest: ${mediaRequest}.`);
        // @ts-ignore
        mediaRequest.setVideoEnhancementAttr(photoAccessHelper.VideoEnhancementType.QUALITY_ENHANCEMENT_LOCAL,
          videoEnhancePhotoId);
        HiLog.d(TAG, 'SEGMENT_VIDEO setVideoEnhancementAttr: QUALITY_ENHANCEMENT_LOCAL end.');
        await this.mPhotoAccessHelper.applyChanges(mediaRequest);
        HiLog.i(TAG, 'SEGMENT_VIDEO applyChanges end.');
        return afterRenameUri;
      } catch (err) {
        HiLog.e(TAG, `setVideoEnhancementAttr error: ${err?.code}.`);
        return afterRenameUri;
      }
    } catch (err) {
      HiLog.e(TAG, `renameVideoFile commitModify err: ${JSON.stringify(err)}.`);
      return uri;
    }
  }

  public async setCameraShotKey(prepareFile: photoAccessHelper.PhotoAsset): Promise<void> {
    try {
      let cameraShotKey: string = getStates().get<string>('securityCameraReducer', 'cameraShotKey') ||
      GlobalContext.get().getCameraShotKey();
      if (cameraShotKey) {
        const mediaRequest: photoAccessHelper.MediaChangeRequest =
          new photoAccessHelper.MediaAssetChangeRequest(prepareFile);
        // @ts-ignore
        mediaRequest.setCameraShotKey(cameraShotKey);
        await this.mPhotoAccessHelper.applyChanges(mediaRequest);
      }
    } catch (err) {
      HiLog.e(TAG, `setCameraShotKey err: ${JSON.stringify(err)}.`);
    }
  }

  public async shouldSaveFile(uri: string, cameraShotKey: string): Promise<boolean> {
    HiLog.i(TAG, `shouldSaveFile uri: ${uri}`);
    let isSaveFile = false;
    if (!WorkerDataCache.getInstance().getMotionStateForRecord()) {
      return isSaveFile;
    }
    try {
      const photoAsset: photoAccessHelper.PhotoAsset =
        await MediaLibraryOperation.getLastPhotoAsset(this.mPhotoAccessHelper,
          {
            fetchColumns: [photoAccessHelper.PhotoKeys.DURATION, 'mime_type'], uri
          }, cameraShotKey);
      const duration: number = photoAsset.get(photoAccessHelper.PhotoKeys.DURATION) as number;
      const mimeType: string = photoAsset.get('mime_type') as string;

      const isValidateThumbnail: boolean = WorkerDataCache.getInstance().getValidateThumbnail();
      HiLog.i(TAG, `shouldSaveFile validateThumbnail: ${isValidateThumbnail}, duration: ${duration}, mime_type: ${
      mimeType}.`);
      isSaveFile = duration !== 0 && mimeType === 'video/mp4';
      if (isSaveFile && isValidateThumbnail) {
        const thumb = await photoAsset.getThumbnail();
        isSaveFile = !!thumb;
        HiLog.i(TAG, `shouldSaveFile isSaveFile: ${isSaveFile}.`);
      }
    } catch (err) {
      isSaveFile = false;
      HiLog.e(TAG, `shouldSaveFile failed. error: ${JSON.stringify(err)}`);
    }
    return isSaveFile;
  }


  public setSupportLrSwipeNewCapture(isSupportLrSwipeNewCapture: boolean): void {
    this.isSupportLrSwipeNewCapture = isSupportLrSwipeNewCapture;
  }

  public clearQueueFileAsset(): void {
    this.mQueuePhotoAsset = [];
  }

  /**
   * 检查媒体库接口是否ok,避免极限场景被管控初始化失败,导致后续操作异常
   */
  public checkPhotoAccessHelper(): void {
    if (!this.mPhotoAccessHelper) {
      HiLog.i(TAG, 'photoAccessHelper undefined, retry.');
      this.mPhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(GlobalContext.get().getWorkerContext());
    }
  }

  public async saveMovieInfoAsset(asset: photoAccessHelper.PhotoAsset): Promise<Fail> {
    if (!asset) {
      HiLog.e(TAG, 'RECORD_TRACK saveMovieInfoAsset return, photoAsset is undefined.');
      return { isFail: true, failReason: 'PhotoAsset is undefined.' };
    }
    const name = this.makeVideoFileName();
    try {
      asset.set(photoAccessHelper.PhotoKeys.TITLE.toString(), name);
      HiLog.begin(TAG, 'RECORD_TRACK commitModify');
      await asset.commitModify();
      HiLog.end(TAG, 'RECORD_TRACK commitModify');
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK asset commitModify error : ${simpleStringify(err)}.`);
    }
    let mediaRequest: photoAccessHelper.MediaAssetChangeRequest;
    try {
      mediaRequest = new photoAccessHelper.MediaAssetChangeRequest(asset);
    } catch (err) {
      HiLog.e(TAG, `RECORD_TRACK create MediaAssetChangeRequest error: ${simpleStringify(err)}.`);
    }
    if (!!mediaRequest) {
      HiLog.i(TAG, `RECORD_TRACK save applyChanges begin, mediaRequest: ${mediaRequest}.`);
      try {
        const cameraShotKey = GlobalContext.get().getLastCameraShotKey();
        HiLog.i(TAG, `RECORD_TRACK save cameraShotKey, setCameraShotKey: ${cameraShotKey}.`);
        if (cameraShotKey) {
          mediaRequest.setCameraShotKey(cameraShotKey);
          HiLog.i(TAG, `RECORD_TRACK setCameraShotKey end.`);
        }
      } catch (err) {
        HiLog.e(TAG, `RECORD_TRACK setCameraShotKey error : ${simpleStringify(err)}.`);
      }
      try {
        mediaRequest.saveCameraPhoto();
        await this.mPhotoAccessHelper.applyChanges(mediaRequest);
        HiLog.i(TAG, `RECORD_TRACK save applyChanges end.`);
      } catch (err) {
        HiLog.e(TAG, `RECORD_TRACK save applyChanges error : ${simpleStringify(err)}.`);
        return { isFail: true, failReason: 'MediaLib applyChanges failed.' };
      }
    } else {
      return { isFail: true, failReason: 'MediaLib createChangeRequest failed.' };
    }
    if (GlobalContext.get().getLastCameraShotKey() !== GlobalContext.get().getCameraShotKey()) {
      HiLog.i(TAG, `RECORD_TRACK cameraShotKey not same, cameraShotKey: ${GlobalContext.get().getCameraShotKey()}`);
      return { isFail: false };
    }
    const afterRenameUri: string = asset.uri.replace(asset.displayName, `${name}.mp4`);
    HiLog.i(TAG, `RECORD_TRACK afterRenameUri: ${afterRenameUri}`);
    workerCallback.videoUri(afterRenameUri);
    return { isFail: false };
  }

  public async saveTimeLapseFrontLocation(asset: photoAccessHelper.PhotoAsset,
    msg: LocationMessage | undefined): Promise<void> {
    HiLog.i(TAG, 'saveTimeLapseFrontLocation begin');
    if (asset === undefined) {
      HiLog.i(TAG, 'saveTimeLapseFrontLocation end, asset is undefined');
      return;
    }
    if (msg === undefined) {
      HiLog.i(TAG, 'saveTimeLapseFrontLocation end, no location message');
      return;
    }
    try {
      if (msg.type === LocationType.CURRENT_LOCATION) {
        HiLog.i(TAG, 'saveTimeLapseFrontLocation current location');
        let changeRequest: photoAccessHelper.MediaAssetChangeRequest =
          new photoAccessHelper.MediaAssetChangeRequest(asset);
        const geoLocation = msg.location;
        changeRequest.setLocation(geoLocation.longitude, geoLocation.latitude);
        await this.mPhotoAccessHelper.applyChanges(changeRequest);
      }
    } catch (err) {
      HiLog.e(TAG, `saveTimeLapseFrontLocation error : ${simpleStringify(err)}.`);
    }
    HiLog.i(TAG, 'saveTimeLapseFrontLocation end');
  }
}