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

import fs, { Filter, ConflictFiles } from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import UserFileManager from '@ohos.filemanagement.userFileManager';
import dataSharePredicates from '@ohos.data.dataSharePredicates';

import { Log } from '../utils/Log';
import DateTimeUtil from '../utils/DateTimeUtil';
import { FunctionCallBack, VideoCallBack } from './CameraService';
import ThumbnailGetter from './ThumbnailGetter';
import ReportUtil from '../utils/ReportUtil';
import { GlobalContext } from '../utils/GlobalContext';
import buffer from '@ohos.buffer';

const TAG = '[SaveCameraAsset]:';

export type FetchOpType = {
  fetchColumns: Array<string>,
  predicates: dataSharePredicates.DataSharePredicates,
};

export default class SaveCameraAsset {
  private lastSaveTime = '';
  private saveIndex = 0;
  private mUserFileManager: UserFileManager.UserFileManager;
  public videoPrepareFile: UserFileManager.FileAsset;
  private mCameraAlbum: UserFileManager.Album;
  private photoUri: string = '';
  private videoUri: string = '';

  constructor() {
    this.mUserFileManager = UserFileManager.getUserFileMgr(GlobalContext.get().getCameraAbilityContext());
  }

  public getPhotoUri() {
    Log.log(`${TAG} getPhotoUri= ${this.photoUri}`);
    return this.photoUri;
  }

  private async createCameraAlbum(): Promise<void> {
    Log.log(`${TAG} createCameraAlbum E`);
    if (!this.mCameraAlbum) {
      let fetchResult = await this.mUserFileManager?.getAlbums(UserFileManager.AlbumType.SYSTEM, UserFileManager.AlbumSubType.CAMERA);
      this.mCameraAlbum = await fetchResult?.getFirstObject();
      Log.log(`${TAG} createCameraAlbum albumUri: ${JSON.stringify(this.mCameraAlbum.albumUri)}`);
    }
    Log.log(`${TAG} createCameraAlbum X`);
  }

  public saveImage(mReceiver, thumbWidth: number, thumbHeight: number, thumbnailGetter: ThumbnailGetter, captureCallBack: FunctionCallBack): void {
    Log.info(`${TAG} saveImage E mediaLibrary.getMediaLibrary media: ${this.mUserFileManager}`);
    mReceiver.on('imageArrival', async () => {
      Log.start(Log.UPDATE_PHOTO_THUMBNAIL);
      Log.log(`${TAG} saveImage ImageReceiver on called`);
      const buffer = await this.getBufferByReceiver(mReceiver);
      if (!buffer) {
        return;
      }
      captureCallBack.onCapturePhotoOutput();
      let pickerUri = GlobalContext.get().getPickerUri();
      Log.info('uri' + pickerUri)
      if (pickerUri === '' || pickerUri === undefined) {
        const fileAsset: UserFileManager.FileAsset = await this.createAsset(UserFileManager.FileType.IMAGE);
        if (!fileAsset) {
          Log.info(`${TAG} fileAsset is null`);
          return;
        }
        // @ts-ignore
        await fileAsset.setPending(true);
        this.photoUri = fileAsset.uri;
        Log.info(`${TAG} saveImage photoUri: ${this.photoUri}`);
        await this.fileAssetOperate(fileAsset, async (fd: number) => {
          Log.info(`${TAG} saveImage fileio write begin`);
          try {
            fs.writeSync(fd, buffer);
            fs.fsyncSync(fd);
          } catch (e) {
            Log.error(`${TAG} fileAssetOperate fileio writeSync ${JSON.stringify(e)}`);
          }
          Log.info(`${TAG} saveImage fileio write done`);
        }).catch(error => {
          Log.error(`${TAG} saveImage error: ${JSON.stringify(error)}`);
        });
        // @ts-ignore
        await fileAsset.setPending(false);
        thumbnailGetter.getThumbnailInfo(thumbWidth, thumbHeight, this.photoUri).then(thumbnail => {
          Log.info(`${TAG} saveImage thumbnailInfo: ${thumbnail}`);
          captureCallBack.onCaptureSuccess(thumbnail, this.photoUri);
          Log.end(Log.UPDATE_PHOTO_THUMBNAIL);
        })
      } else {
        try {
          Log.info(`${TAG} save Picker image`);
          const file: fs.File = await fs.open(pickerUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
          Log.info(`${TAG} open Picker image byteLength` + buffer.byteLength);
          await fs.write(file.fd, buffer);
          Log.info(`${TAG} write Picker image byteLength`);
          captureCallBack.onCaptureSuccess('thumbnail', pickerUri);
        } catch (e) {
          captureCallBack.onCaptureSuccess('thumbnail', '');
          Log.error(`${TAG} Picker fileio writeSync error ${JSON.stringify(e)}`);
        }
      }
    })
    Log.info(`${TAG} saveImage X`);
  }

  public async getThumbnailInfo(width: number, height: number): Promise<image.PixelMap | undefined> {
    Log.info(`${TAG} getThumbnailInfo E width: ${width}, height: ${height}`);
    Log.info(`${TAG} getThumbnailInfo E`);
    const fileAsset: UserFileManager.FileAsset = await this.getLastFileAsset();
    if (!fileAsset) {
      Log.info(`${TAG} getThumbnailInfo getLastFileAsset error: fileAsset undefined.`);
      return undefined;
    }
    let thumbnailSize: image.Size = {
      width: width, height: height
    };
    let thumbnailPixelMap: image.PixelMap = <image.PixelMap> await fileAsset.getThumbnail(thumbnailSize).catch(e => {
      Log.error(`${TAG} getThumbnail error: ${JSON.stringify(e)}`);
    });
    if (thumbnailPixelMap === undefined) {
      Log.info(`${TAG} getThumbnail fail`);
    } else {
      Log.info(`${TAG} getThumbnail successful ` + thumbnailPixelMap);
    }
    Log.info(`${TAG} getThumbnailInfo X`);
    return thumbnailPixelMap;
  }

  public async getLastFileAsset(): Promise<UserFileManager.FileAsset> {
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.orderByDesc('date_added').limit(1, 0);
    let fetchOptions: FetchOpType = {
      fetchColumns: ['date_added'],
      predicates: predicates,
    };
    Log.info(`${TAG} getLastFileAsset fetchOp: ${JSON.stringify(fetchOptions)}`);
    return this.getFileAssetByFetchOp(fetchOptions);
  }

  public async getFileAssetByFetchOp(fetchOp: FetchOpType): Promise<UserFileManager.FileAsset> {
    let fetchResult;
    let fileAsset;
    try {
      await this.createCameraAlbum();
      fetchResult = await this.mCameraAlbum?.getPhotoAssets(fetchOp);
      if (fetchResult !== undefined) {
        Log.info(`${TAG} getFileAssetByFetchOp fetchResult success`);
        fileAsset = await fetchResult.getLastObject();
        if (fileAsset !== undefined) {
          Log.info(`${TAG} getFileAssetByFetchOp fileAsset.displayName : ` + fileAsset.displayName);
        }
      }
    } catch (e) {
      Log.error(`${TAG} getFileAssetByFetchOp get fileAsset error: ${JSON.stringify(e)}`);
    } finally {
      fetchResult.close();
    }
    return fileAsset;
  }

  private async fileAssetOperate(fileAsset: UserFileManager.FileAsset, operate: (fd: number) => void): Promise<void> {
    const fd: number = <number> await fileAsset.open('Rw').catch(error => {
      Log.error(`${TAG} fileAsset open error: ${JSON.stringify(error)}`);
      return;
    });
    try {
      await operate.apply(this, [fd]);
    } catch (error) {
      Log.error(`${TAG} fileAsset operate error: ${JSON.stringify(error)}`);
    } finally {
      Log.info(`${TAG} fileAsset operate close`);
      await fileAsset.close(fd).catch(error => {
        ReportUtil.write(ReportUtil.SAVE_FAIL);
        Log.error(`${TAG} fileAsset open error: ${JSON.stringify(error)}`);
      });
    }
  }

  private async getBufferByReceiver(mReceiver: image.ImageReceiver): Promise<ArrayBuffer | undefined> {
    const imageInfo: image.Image = <image.Image> await mReceiver.readNextImage().catch(error => {
      Log.error(`${TAG} saveImage receiver read next image error: ${JSON.stringify(error)}`);
      return undefined;
    });
    try {
      const img: image.Component = await imageInfo.getComponent(image.ComponentType.JPEG);
      if (img && img.byteBuffer) {
        const buffer: ArrayBuffer = img.byteBuffer.slice(0, img.byteBuffer.byteLength);
        Log.info(`${TAG} saveImage getComponent img.byteBuffer.byteLength = ${buffer.byteLength}`);
        return buffer;
      } else {
        Log.error(`${TAG} saveImage getComponent img is undefined error`);
      }
    } catch (error) {
      Log.error(`${TAG} saveImage get buffer from receiver error: ${JSON.stringify(error)}`);
    } finally {
      if (imageInfo) {
        await imageInfo.release().catch(error => {
          Log.error(`${TAG} image info release error: ${JSON.stringify(error)}`);
        });
      }
    }
    return undefined;
  }

  public async createAsset(type: UserFileManager.FileType): Promise<UserFileManager.FileAsset> {
    const displayName = this.getDisplayName(type);
    Log.info(`${TAG} createAsset  displayName: ${displayName}`);
    let option: UserFileManager.PhotoCreateOptions = {
      subType: UserFileManager.PhotoSubType.CAMERA,
    };
    let fileAsset: UserFileManager.FileAsset;
    try {
      fileAsset = await this.mUserFileManager.createPhotoAsset(displayName, option);
      if (fileAsset !== undefined) {
        Log.info(`${TAG} createPhotoAsset successfully displayName` + fileAsset.displayName);
      } else {
        Log.error(`${TAG} createPhotoAsset failed, fileAsset is undefined `);
      }
    } catch (e) {
      Log.error(`${TAG} createPhotoAsset failed, error: ${JSON.stringify(e)}}`);
    }
    return fileAsset;
  }

  private getDisplayName(type: UserFileManager.FileType): string {
    const mDateTimeUtil: DateTimeUtil = new DateTimeUtil();
    const mData: string = mDateTimeUtil.getDate();
    const mTime: string = mDateTimeUtil.getTime();
    if (type === UserFileManager.FileType.IMAGE) {
      return `${this.checkName(`IMG_${mData}_${mTime}`)}.jpg`;
    } else {
      return `${this.checkName(`VID_${mData}_${mTime}`)}.mp4`;
    }
  }

  public async createVideoFd(captureCallBack: VideoCallBack): Promise<number | undefined> {
    Log.info(`${TAG} createVideoFd E`);
    const fileAsset: UserFileManager.FileAsset = await this.createAsset(UserFileManager.FileType.VIDEO);
    if (!fileAsset) {
      Log.error(`${TAG} createVideoFd mediaLibrary createAsset error: fileAsset undefined.`);
      return undefined;
    }
    let fdNumber: number = 0;
    try {
      this.videoPrepareFile = fileAsset;
      this.videoUri = fileAsset.uri;
      captureCallBack.videoUri(this.videoUri);
      Log.info(`${TAG} SaveCameraAsset getLastObject.uri: ${JSON.stringify(fileAsset.uri)}`);
      fdNumber = await fileAsset.open('Rw');
    } catch (err) {
      Log.error(`${TAG} createVideoFd err: ${err}`);
    }
    Log.info(`${TAG} createVideoFd X`);
    return fdNumber;
  }

  private checkName(name: string): string {
    if (this.lastSaveTime === name) {
      this.saveIndex++;
      return `${name}_${this.saveIndex}`;
    }
    this.lastSaveTime = name;
    this.saveIndex = 0;
    return name;
  }
}