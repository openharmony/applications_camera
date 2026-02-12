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
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import lazy { MediaLibraryOperation, fs, fileIO, dataObserver, image } from '../../utils/LazyImportUtil';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { modulesManager } from '../../worker/WorkerModuleManager';
import lazy { workerCallback } from '../../camera/childthread/WorkerCallback';
import lazy { camera } from '@kit.CameraKit';
import type { PickerInfo } from '../../utils/types';
import { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';

/* instrument ignore file */
const TAG: string = 'PickerFileWorkerService';
const WRITE_READ = 0o2; // 0o2: The read and write function is enabled.
const OPEN_CREATE = 0o100; // 0o100: If the file does not exist, the file is created.
const FILE_PERMISSION = 0o660; // 0o660: The owner has the read and write permissions. All user groups have the read and write permissions.

export type PickerSaveResolveType = {
  uri: string,
  uriFromLocal: boolean,
  errorMessage?: string
};

export class PickerFileWorkerService {
  private static mInstance: PickerFileWorkerService;
  private mTempDir: string = '';
  private mPickerSaveResolve: PickerSaveResolveType;
  private mPickerBuffer: ArrayBuffer | null = null;
  private assetDisplayName: string;
  private isSingleStagePhoto: boolean = false;
  // 三方生态heif格式新规格:传uri则按后缀(heic编码、jpg编码),否则其它场景均默认jpg编码
  private mPhotoUriPackerFormat: string = 'image/jpeg';

  private constructor() {
    this.mTempDir = GlobalContext.get().getWorkerContext().tempDir;
    HiLog.i(TAG, `PickerFileWorkerService constructor, tempDir: ${this.mTempDir}.`);
  }

  public static getInstance(): PickerFileWorkerService {
    if (!PickerFileWorkerService.mInstance) {
      PickerFileWorkerService.mInstance = new PickerFileWorkerService();
    }
    return PickerFileWorkerService.mInstance;
  }

  // 用户点击确认时,按场景去执行返回
  public async savePickerFileInWorker(): Promise<PickerSaveResolveType> {
    HiLog.i(TAG, 'tryToSaveImageToUri');
    if (this.mPickerBuffer) {
      return this.saveImageToUri();
    }
    HiLog.i(TAG, 'tryToSaveImageToUri delay');
    return new Promise((resolve: (param: PickerSaveResolveType) => void): void => {
      dataObserver(this, 'mPickerBuffer', async (buffer: ArrayBuffer) => {
        if (buffer) {
          const uriInfo: PickerSaveResolveType = await this.saveImageToUri();
          resolve(uriInfo);
        } else {
          HiLog.i(TAG, 'listenBufferToSaveImage reset picker buffer.');
        }
      });
    });
  }

  // 在子线程中将buffer写入目标/创建uri,并返回uri
  private async saveImageToUri(): Promise<PickerSaveResolveType> {
    HiLog.i(TAG, `uri ${this.mPickerSaveResolve.uri}.`);
    try {
      if (!this.mPickerSaveResolve.uriFromLocal) { // 三方传递uri场景
        const file: fs.File = await fs.open(this.mPickerSaveResolve.uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        HiLog.i(TAG, `saveImage remote open file succeed fd: ${file.fd}, byteLength: ${this.mPickerBuffer?.byteLength}.`);
        if (!this.mPickerBuffer) {
          return this.mPickerSaveResolve;
        }
        await fs.write(file.fd, this.mPickerBuffer);
        HiLog.i(TAG, 'saveImage write called');
        workerCallback.photoSaved(this.mPickerSaveResolve.uri);
        this.resetPickerBuffer();
        await fs.close(file);
      } else { // 创建uri场景,默认jpg格式编码
        const mediaLibrary = await modulesManager.getMediaLibrary();
        const photoAsset =
          await mediaLibrary.createPhotoFile(this.mPickerBuffer, camera.CameraFormat.CAMERA_FORMAT_JPEG);
        this.mPickerSaveResolve.uri = photoAsset.uri;
        this.resetPickerBuffer();
      }
    } catch (err) {
      this.mPickerSaveResolve.errorMessage = err?.message;
      HiLog.i(TAG, `saveImageToUri err: ${JSON.stringify(err)}.`);
    }

    HiLog.i(TAG, 'saveImageToUri done.');
    return this.mPickerSaveResolve;
  }

  public resetPickerBuffer(): void {
    HiLog.i(TAG, 'resetPickerBuffer.');
    dataObserver(this, 'mPickerBuffer', () => {});
    this.mPickerBuffer = null;
  }

  // 记录picker需要编码的格式
  public setPhotoDecodeFormat(uri: string): void {
    if (!uri || uri === null) { // 三方不传递uri场景默认jpg编码
      this.mPhotoUriPackerFormat = 'image/jpeg';
      HiLog.i(TAG, `setPhotoDecodeFormat DefaultPackerFormat: ${this.mPhotoUriPackerFormat}.`);
      return;
    }
    let fileSuffix: string = this.extractUriSuffix(uri);
    switch (fileSuffix) {
      case 'jpg':
      case 'jpeg':
        this.mPhotoUriPackerFormat = 'image/jpeg';
        break;
      case 'heic':
      case 'heif':
        this.mPhotoUriPackerFormat = 'image/heif';
        break;
      case 'png':
        this.mPhotoUriPackerFormat = 'image/jpeg';
        // 当前Picture对象不支持png编码 this.mPhotoUriPackerFormat = 'image/png';
        break;
      case 'webp':
        this.mPhotoUriPackerFormat = 'image/jpeg';
        // 当前Picture对象不支持png编码 this.mPhotoUriPackerFormat = 'image/webp';
        break;
      default:
        this.mPhotoUriPackerFormat = 'image/jpeg';
        break;
    }
    HiLog.i(TAG, `setPhotoDecodeFormat mPhotoUriPackerFormat: ${this.mPhotoUriPackerFormat}.`);
  }

  public getYuvPicturePackerFormat(): string {
    return this.mPhotoUriPackerFormat;
  }

  private extractUriSuffix(uri: string): string | undefined {
    // 正则表达式匹配文件后缀名
    let regex = /\.([a-zA-Z0-9]+)$/;
    let match = uri.match(regex);
    if (match && match[1]) {
      return match[1];
    } else {
      return undefined;
    }
  }


  public photoArrival(buffer: ArrayBuffer, pickerInfo: PickerInfo, savePhotoFormat: camera.CameraFormat): boolean {
    HiLog.i(TAG, 'SINGLE_STAGE picker photoArrival begin.');
    if (pickerInfo.isPicker) {
      HiLog.i(TAG, 'SINGLE_STAGE photoArrival picker is true.');
      this.mPickerBuffer = buffer.slice(0);
      this.isSingleStagePhoto = true;
      this.mPickerSaveResolve = {
        uri: pickerInfo.uri,
        uriFromLocal: !pickerInfo.uri ? true : false
      };
      this.setPhotoDecodeFormat(pickerInfo.uri);
      return true;
    }
    HiLog.i(TAG, 'SINGLE_STAGE photo is not picker.');
    return false;
  }

  // 上报图buffer临时保存,80/100分两图可能会回调两次(与用户确认时机有关)
  public savePickerBuffer(buffer: ArrayBuffer, assetDisplayName: string): void {
    HiLog.i(TAG, `this.assetDisplayName: ${this.assetDisplayName}, assetDisplayName: ${assetDisplayName}`);
    try {
      if (this.assetDisplayName && this.assetDisplayName !== assetDisplayName) {
        const isSameDayNotLatest: boolean =
          (this.assetDisplayName.substring(4, 12) === assetDisplayName.substring(4, 12)) &&
            (this.assetDisplayName.substring(13, 19) > assetDisplayName.substring(13, 19));
        const isDiffDayNotLatest: boolean =
          (this.assetDisplayName.substring(4, 12) > assetDisplayName.substring(4, 12));
        if (isSameDayNotLatest || isDiffDayNotLatest) {
          HiLog.i(TAG, 'not the latest asset.');
          this.assetDisplayName = undefined;
          return;
        }
      }

      if (!this.mPickerBuffer && this.assetDisplayName === assetDisplayName) {
        HiLog.i(TAG, 'mPickerBuffer is null.');
        return;
      }

      this.assetDisplayName = assetDisplayName;
      this.mPickerBuffer = buffer?.slice(0);

      if (this.mPickerBuffer && DeviceInfo.isTv()) {
        try {
          HiLog.i(TAG, 'savePickerBuffer createPixelMap E');
          const imageSourceApi: image.ImageSource = image.createImageSource(this.mPickerBuffer);
          let photo:image.PixelMap = imageSourceApi.createPixelMapSync();
          workerCallback.onPickerPhotoReceived(photo);
          imageSourceApi.release(); //图片资源打开后释放
          HiLog.i(TAG, 'savePickerBuffer createPixelMap X');
        } catch (err) {
          HiLog.e(TAG, `savePickerBuffer createPixelMap fail ${err?.code} ${err?.message}`);
        }
      } else {
        try {
          HiLog.i(TAG, 'savePickerBuffer createPixelMap quickThumbnail for E');
          const imageSourceApi: image.ImageSource = image.createImageSource(this.mPickerBuffer);
          let photo:image.PixelMap = imageSourceApi.createPixelMapSync();
          GlobalContext.get().getCameraService().getPhotoOutput().quickThumbnail(null, photo);
          // workerCallback.onPickerPhotoReceived(photo);
          // imageSourceApi.release(); //图片资源打开后释放
          HiLog.i(TAG, 'savePickerBuffer createPixelMap quickThumbnail X');
        } catch (err) {
          HiLog.e(TAG, `savePickerBuffer createPixelMap quickThumbnail fail ${err?.code} ${err?.message}`);
        }
      }
    } catch (error) {
      HiLog.i(TAG, `savePickerBuffer fail ${error}`);
    }
  }

  public setPickerResolve(resolve: PickerSaveResolveType): void {
    this.mPickerSaveResolve = resolve;
    this.setPhotoDecodeFormat(resolve.uri);
  }
}