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

import UserFileManager from '@ohos.filemanagement.userFileManager';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import image from '@ohos.multimedia.image';
import { Log } from '../utils/Log'
import { GlobalContext } from '../utils/GlobalContext';

const TAG = '[ThumbnailGetter]:';

export default class ThumbnailGetter {

  private mUserFileManager: UserFileManager.UserFileManager;
  private mCameraAlbum: UserFileManager.Album;
  private mRecentFileUri: string = '';

  public async getThumbnailInfo(width: number, height: number, uri?: string): Promise<PixelMap | undefined> {
    this.mUserFileManager = UserFileManager.getUserFileMgr(GlobalContext.get().getCameraAbilityContext());
    Log.info(`${TAG} getThumbnailInfo E width: ${width}, height: ${height}, uri: ${uri}`);
    Log.info(`${TAG} getThumbnailInfo E`);
    const fileAsset: UserFileManager.FileAsset = await this.getLastFileAsset();
    if (!fileAsset) {
      Log.info(`${TAG} getThumbnailInfo getLastFileAsset error: fileAsset undefined.`);
      return undefined;
    }
    let thumbnailPixelMap: image.PixelMap = <image.PixelMap> await fileAsset.getThumbnail({
      width: width, height: height
      // @ts-ignore
    }).catch(e => {
      Log.error(`${TAG} getThumbnail error: ${JSON.stringify(e)}`);
    });
    if (thumbnailPixelMap === undefined) {
      Log.info(`${TAG} getThumbnail successful ` + thumbnailPixelMap);
    } else {
      Log.info(`${TAG} getThumbnail fail`);
    }
    Log.info(`${TAG} getThumbnailInfo X`);
    return thumbnailPixelMap;
  }

  public async getLastFileAsset(): Promise<UserFileManager.FileAsset> {
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.orderByDesc('date_added').limit(1, 0);
    let fetchOptions = {
      fetchColumns: ['date_added'],
      predicates: predicates,
    };
    Log.info(`${TAG} getLastFileAsset fetchOp: ${JSON.stringify(fetchOptions)}`);
    return this.getFileAssetByFetchOp(fetchOptions);
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

  public getRecentFileUri(): string {
    return this.mRecentFileUri;
  }

  public async getFileAssetByFetchOp(fetchOp): Promise<UserFileManager.FileAsset> {
    let fetchResult;
    let fileAsset;
    try {
      await this.createCameraAlbum();
      fetchResult = await this.mCameraAlbum?.getPhotoAssets(fetchOp);
      if (fetchResult !== undefined) {
        Log.info(`${TAG} getFileAssetByFetchOp fetchResult success`);
        fileAsset = await fetchResult.getLastObject();
        if (fileAsset !== undefined) {
          Log.info(`${TAG} getFileAssetByFetchOp fileAsset.displayName : ${JSON.stringify(fileAsset.displayName)}`);
        }
      }
    } catch (e) {
      Log.error(`${TAG} getFileAssetByFetchOp get fileAsset error: ${JSON.stringify(e)}`);
    } finally {
      fetchResult.close();
    }
    this.mRecentFileUri = fileAsset?.uri;
    Log.info(`${TAG} mRecentFileUri : ${JSON.stringify(this.mRecentFileUri)}`);
    return fileAsset;
  }
}