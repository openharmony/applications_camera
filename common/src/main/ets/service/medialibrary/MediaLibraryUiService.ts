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

import lazy { HiLog } from '../../utils/HiLog';
import image from '@ohos.multimedia.image';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import MediaLibraryOperation from './MediaLibraryOperation';
import lazy { ContextManager } from '../context/ContextManager';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { ThumbnailInfo } from '../../component/thumbnail/ThumbnailInfo';
import lazy { camera } from '@kit.CameraKit';
import lazy { LocationManager } from '../../service/location/LocationManager';
import lazy { LocationMessage, LocationType } from '../../service/location/LocationMessage';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { getStates } from '../../redux';
import lazy { simpleStringify } from '../../utils/SimpleStringify';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { ThumbnailAction } from '../../component/thumbnail/ThumbnailAction';
import lazy { CameraProxy } from '../../camera/uithread/CameraProxy';
import lazy { ThumbnailService } from '../../component/thumbnail/ThumbnailService';
import fs from '@ohos.file.fs';
import lazy { fileIO } from '../../utils/LazyImportUtil';
import lazy { JSON } from '@kit.ArkTS';
import json from '@ohos.util.json';
import lazy { RecordController } from '../../function/recordcontrol/RecordController';
import { PhotoFormatMode } from '../../function/enumbase/PhotoFormatMode';
import { ModeType } from '../../mode/ModeType';

const TAG: string = 'MediaLibraryUiService';

export default class MediaLibraryUiService {
  private static sInstance: MediaLibraryUiService;
  private helper: photoAccessHelper.PhotoAccessHelper;
  private mRecentFileUri: string = '';
  private thumbnailInfoForColdStart: ThumbnailInfo = null;
  private thumbnailUsed: boolean = false;
  private isRegister: boolean = false;

  public static getInstance(): MediaLibraryUiService {
    if (!MediaLibraryUiService.sInstance) {
      MediaLibraryUiService.sInstance = new MediaLibraryUiService();
    }
    MediaLibraryUiService.sInstance.checkPhotoAccessHelper();
    return MediaLibraryUiService.sInstance;
  }

  public async getThumbnailInfo(uri?: string): Promise<ThumbnailInfo | undefined> {
    HiLog.begin(TAG, 'get last photoAsset.');
    const photoAsset: photoAccessHelper.PhotoAsset = await MediaLibraryOperation.getLastPhotoAsset(this.helper, {
      uri,
      fetchColumns: [photoAccessHelper.PhotoKeys.HEIGHT, photoAccessHelper.PhotoKeys.WIDTH,
        photoAccessHelper.PhotoKeys.ORIENTATION]
    });
    this.mRecentFileUri = photoAsset?.uri;
    HiLog.end(TAG, 'get last photoAsset.');
    if (!photoAsset) {
      HiLog.e(TAG, 'getThumbnailInfo photoAsset undefined.');
      return undefined;
    }
    let pixelMap: image.PixelMap | undefined = undefined;
    try {
      HiLog.begin(TAG, 'get ThumbnailInfo pixelMap');
      pixelMap = await photoAsset.getThumbnail({
        height: -1,
        width: -1
      });
      HiLog.end(TAG, 'get ThumbnailInfo pixelMap');
      if (!pixelMap) {
        HiLog.e(TAG, 'getThumbnail error, thumbnail: undefined.');
        return undefined;
      }
      HiLog.i(TAG, `get photoAsset thumbnail pixelMap, PixelBytesNumber: ${pixelMap.getPixelBytesNumber()}.`);
    } catch (e) {
      HiLog.e(TAG, `getThumbnail error: ${JSON.stringify(e)}.`);
      return undefined;
    }
    try {
      if (pixelMap !== undefined) {
        pixelMap.setMemoryNameSync(TAG);
      }
    } catch (e) {
      HiLog.e(TAG, `getThumbnailInfo setMemoryNameSync error: ${JSON.stringify(e)}.`);
    }

    const thumbnailInfo: ThumbnailInfo = {
      thumbnailPixelMap: pixelMap,
      mediaUri: this.mRecentFileUri
    };
    HiLog.iWithUri(TAG, `getThumbnailInfo finished, thumbnail uri: ${this.mRecentFileUri}, pixelMap: ${pixelMap}.`);
    return thumbnailInfo;
  }

  public async getThumbnailMediaUri(): Promise<string> {
    HiLog.i(TAG, 'getThumbnailMediaUri invoke.');
    const photoAsset: photoAccessHelper.PhotoAsset = await MediaLibraryOperation.getLastPhotoAsset(this.helper);
    this.mRecentFileUri = photoAsset?.uri;
    if (!photoAsset) {
      HiLog.e(TAG, 'getThumbnailMediaUri photoAsset undefined.');
      return undefined;
    }
    return photoAsset?.uri;
  }

  public async getLastFileUri(): Promise<string> {
    const photoAsset = await MediaLibraryOperation.getLastPhotoAsset(this.helper);
    this.mRecentFileUri = photoAsset?.uri ?? '';
    HiLog.iWithUri(TAG, `getLastFileUri: ${this.mRecentFileUri}.`);
    return this.mRecentFileUri;
  }

  public getRecentFileUri(): string {
    HiLog.i(TAG, 'getRecentFileUri.');
    return this.mRecentFileUri;
  }

  public setThumbnailInfoForColdStart(info: ThumbnailInfo): void {
    this.thumbnailInfoForColdStart = info;
  }

  public getThumbnailInfoForColdStart(): ThumbnailInfo {
    this.thumbnailUsed = true;
    return this.thumbnailInfoForColdStart;
  }

  public getIfThumbnailUsed(): boolean {
    return this.thumbnailUsed;
  }

  /**
   * 保存全景模式拍照照片
   * @param width
   * @param height
   * @param arrayBuffer
   */
  public async savePanoramaPhotoFile(width: number, height: number, arrayBuffer: ArrayBuffer): Promise<void> {
    HiLog.i(TAG, `savePanoramaPhotoFile width: ${width}, height: ${height}, arrayBuffer: ${arrayBuffer.byteLength}.`);
    const photoAsset: photoAccessHelper.PhotoAsset = await MediaLibraryOperation.createPhotoAsset(this.helper,
      photoAccessHelper.PhotoType.IMAGE,
      camera.CameraFormat.CAMERA_FORMAT_JPEG);
    let changeRequest: photoAccessHelper.MediaAssetChangeRequest =
      new photoAccessHelper.MediaAssetChangeRequest(photoAsset);

    let pixelMap: image.PixelMap = image.createPixelMapSync(arrayBuffer,
      {
        srcPixelFormat: image.PixelMapFormat.NV21,
        pixelFormat: image.PixelMapFormat.NV21,
        size: { width: width, height: height }
      });
    let packOpts: image.PackingOption = {
      format: 'image/jpeg', quality: 100
    };
    HiLog.i(TAG, 'savePanoramaPhotoFile X');
    let mTempDir = ContextManager.getInstance().getApplicationContext().tempDir;
    const filePath = `${mTempDir}/${photoAsset.displayName}`;
    let file: fs.File = undefined;
    try {
      file = await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      const imagePackerApi: image.ImagePacker = image.createImagePacker();
      await imagePackerApi.packToFile(pixelMap, file.fd, packOpts);
      const imageSourceApi: image.ImageSource = image.createImageSource(file.fd);
      await imageSourceApi.modifyImageProperty(image.PropertyKey.CAPTURE_MODE, '8');
      const featureManager: FeatureManager = FeatureManager.getInstance();
      if (featureManager.getFunction(FunctionId.SAVE_GEO_LOCATION).getValue()) {
        const message: LocationMessage = LocationManager.getInstance().getLocationCache();
        if (message.type === LocationType.CURRENT_LOCATION) {
          const geoLocation = message.location;
          await imageSourceApi.modifyImageProperty(image.PropertyKey.GPS_LATITUDE,
            Number(geoLocation.latitude).toString());
          await imageSourceApi.modifyImageProperty(image.PropertyKey.GPS_LONGITUDE,
            Number(geoLocation.longitude).toString());
        }
      }
      await imagePackerApi.release();
      await imageSourceApi.release();
    } catch (e) {
      HiLog.e(TAG, e);
    } finally {
      if (file !== undefined) {
        await fs.close(file);
      }
      pixelMap.release();
    }
    await changeRequest.addResource(photoAccessHelper.ResourceType.IMAGE_RESOURCE, filePath);
    const featureManager: FeatureManager = FeatureManager.getInstance();
    if (featureManager.getFunction(FunctionId.SAVE_GEO_LOCATION).getValue()) {
      const message: LocationMessage = LocationManager.getInstance().getLocationCache();
      if (message.type === LocationType.CURRENT_LOCATION) {
        const geoLocation = message.location;
        changeRequest.setLocation(geoLocation.longitude, geoLocation.latitude);
      }
    }
    await this.helper.applyChanges(changeRequest);
    await fs.unlinkSync(filePath);
    HiLog.i(TAG, 'savePanoramaPhotoFile E');
  }

  /**
   * onPageshow时注册媒体库监听,onPageHide解注册
   * @param isPageShow is onPageShow
   */
  public onPageChange(isPageShow: boolean): void {
    if (isPageShow && !this.isRegister) {
      HiLog.i(TAG, 'onPageChange true');
      this.helper?.registerChange(CommonConstants.FILE_PATH_PHOTO, true, this.handleMediaUriChange);
      this.isRegister = true;
    } else if (!isPageShow && this.isRegister) {
      HiLog.i(TAG, 'onPageChange false');
      this.helper?.unRegisterChange(CommonConstants.FILE_PATH_PHOTO, this.handleMediaUriChange);
      this.isRegister = false;
    }
  }

  /**
   * 检查媒体库接口是否ok,避免极限场景被管控初始化失败,导致后续操作异常
   */
  private checkPhotoAccessHelper(): void {
    if (!this.helper) {
      HiLog.i(TAG, 'photoAccessHelper undefined, retry.');
      this.helper = photoAccessHelper.getPhotoAccessHelper(ContextManager.getInstance().getContextWithToken());
    }
  }

  private handleMediaUriChange =
    async (data: photoAccessHelper.ChangeData): Promise<void> => { // 务必保证媒体库解注册对象唯一,禁止直接解注册
      const ignoreUriChange = this.validateUriChange(data);
      const nightCaptureStarted = AppStorage.get<boolean>('nightCaptureStarted');
      if (ignoreUriChange && !nightCaptureStarted) {
        HiLog.w(TAG, `handleMediaUriChange - ignoreUriChange: ${ignoreUriChange}, no update required!`);
        return;
      }
      AppStorage.setOrCreate('nightCaptureStarted', false);
      const type: photoAccessHelper.NotifyType = data.type;
      let thumbnailInfo: ThumbnailInfo | undefined;
      if (type === photoAccessHelper.NotifyType.NOTIFY_ADD ||
        DeviceInfo.isTablet() && type === photoAccessHelper.NotifyType.NOTIFY_UPDATE) {
        const uri = data.uris[0];
        thumbnailInfo = await MediaLibraryUiService.getInstance().getThumbnailInfo(uri);
        if (thumbnailInfo && !ThumbnailService.getInstance().isDeregisterUri(uri)) {
          ThumbnailService.getInstance().deregisterUri(uri);
        } else if (RecordController.getInstance().isMovieFile()) {
          HiLog.i(TAG, 'handleMediaUriChange during getPhotoAsset isDeregisterUri, ignoreUriChange!');
          return;
        }
      } else if (type === photoAccessHelper.NotifyType.NOTIFY_REMOVE) {
        thumbnailInfo = await MediaLibraryUiService.getInstance().getThumbnailInfo();
      }
      const recordingState: RecordingState = getStates().get<RecordingState>('recordReducer', 'recordingState');
      if (recordingState !== RecordingState.READY || thumbnailInfo === undefined &&
        type !== photoAccessHelper.NotifyType.NOTIFY_REMOVE) {
        return;
      }
      HiLog.i(TAG, `handleMediaUriChange file: ${simpleStringify(data)}.`);
      AppStorage.setOrCreate('thumbnailMediaUri', thumbnailInfo?.mediaUri);
      StoreManager.getInstance().postMessage(ThumbnailAction.changeThumbnail(thumbnailInfo?.thumbnailPixelMap,
        type !== photoAccessHelper.NotifyType.NOTIFY_REMOVE));
      HiLog.i(TAG, 'handleMediaUriChange end.');
    };

  private validateUriChange(data: photoAccessHelper.ChangeData): boolean {
    const type: photoAccessHelper.NotifyType = data.type;
    if (type === photoAccessHelper.NotifyType.NOTIFY_REMOVE) {
      // 除lem 场景，在大图界面删除图片，要更新缩略图
      return AppStorage.get<boolean>('isLemCollaps');
    }

    const uri: string = data.uris[0] ?? '';
    const isScreenshot = uri.includes('screenshot_'); // 截屏
    const isScreenRecord = uri.includes('SVID_'); // 录屏
    HiLog.i(TAG, `validateUriChange, isScreenshot: ${isScreenshot}, isScreenRecord: ${isScreenRecord}, type: ${type}.`);
    if (isScreenshot || isScreenRecord) {
      return type !== photoAccessHelper.NotifyType.NOTIFY_ADD || AppStorage.get<boolean>('showPhotoBrowserAction');
    }
    const isQuickThumbnailSupported: boolean = CameraProxy.getInstance().getIsQuickThumbnailSupported();
    if (isQuickThumbnailSupported) {
      HiLog.i(TAG, 'validateUriChange, isQuickThumbnailSupported: true, ignoreUriChange: true.');
      return true;
    }
    const isDng: boolean = uri.includes('dng');
    if (isDng) {
      HiLog.i(TAG, 'validateUriChange, isDNG: true, ignoreUriChange: true.');
      return true;
    }
    const isDeregisterUri: boolean = ThumbnailService.getInstance().isDeregisterUri(data.uris[0]);
    if (isDeregisterUri) {
      HiLog.i(TAG, 'validateUriChange, isDeregisterUri: true, ignoreUriChange: true.');
      if (getStates().get<ModeType>('modeReducer', 'mode') === ModeType.PHOTO) { //TODO 这里更新屏蔽视频更新多次刷新
        return true
      }
    }
    HiLog.i(TAG,
      'validateUriChange, ignoreUriChange: false, isQuickThumbnailSupported: false, isDng: false, isDeregisterUri: false.');
    return false;
  }
}