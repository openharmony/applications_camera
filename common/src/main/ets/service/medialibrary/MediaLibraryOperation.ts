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
import lazy { HiLog } from '../../utils/HiLog';
import lazy { DateTimeUtil, dataSharePredicates } from '../../utils/LazyImportUtil';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { camera } from '@kit.CameraKit';
import lazy { getStates } from '../../redux';

const TAG: string = 'MediaLibraryOperation';

export interface FilterParameters {
  fetchColumns?: string[];
  uri?: string
}

// 媒体库单元操作，UI线程和worker线程均调用，但使用的helper非同一个。
export default class MediaLibraryOperation {
  private static lastSaveTime: string = '';
  private static saveIndex: number = 0;

  private static async getCameraAlbums(helper: photoAccessHelper.PhotoAccessHelper): Promise<photoAccessHelper.Album> {
    let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(photoAccessHelper.AlbumKeys.ALBUM_LPATH, '/DCIM/Camera');
    let fetchOptions: photoAccessHelper.FetchOptions = {
      fetchColumns: [],
      predicates: predicates
    };

    const fetchAlbumResult: photoAccessHelper.FetchResult<photoAccessHelper.Album> = await helper.getAlbums(
      photoAccessHelper.AlbumType.SOURCE, photoAccessHelper.AlbumSubtype.SOURCE_GENERIC, fetchOptions);

    if (fetchAlbumResult === undefined) {
      console.error('getAlbumsPromise fetchResult is undefined');
      return;
    }
    const album: photoAccessHelper.Album = await fetchAlbumResult.getFirstObject();
    fetchAlbumResult.close();

    return album;
  }

  public static async getLastPhotoAsset(helper: photoAccessHelper.PhotoAccessHelper,
    filterParameters: FilterParameters = {
    }, cameraShotKey?: string): Promise<photoAccessHelper.PhotoAsset> {
    HiLog.i(TAG, 'MediaLibraryOperation getLastPhotoAsset invoke. cameraShotKey:' + cameraShotKey);
    let fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset>;
    try {
      // getPredicates
      const predicates = new dataSharePredicates.DataSharePredicates();
      if (!cameraShotKey) {
        cameraShotKey = getStates().get<string>('securityCameraReducer', 'cameraShotKey') ||
          GlobalContext.get().getCameraShotKey();
        HiLog.i(TAG, `getLastPhotoAsset cameraShotKey: ${cameraShotKey}.`);
      }
      if (!!cameraShotKey) {
        predicates.equalTo(photoAccessHelper.PhotoKeys.CAMERA_SHOT_KEY.toString(), cameraShotKey);
        predicates.and();
      }
      predicates.notEqualTo('size', 0).and().isNotNull('size').and();
      if (filterParameters.uri) {
        predicates.equalTo('uri', filterParameters.uri);
      } else {
        predicates.orderByDesc('date_taken_ms').limit(1, 0);
      }

      // getPhotoAssetsByFetchOp
      const fetchOptions: photoAccessHelper.FetchOptions = {
        fetchColumns: filterParameters.fetchColumns || ['date_modified'],
        predicates
      };
      HiLog.i(TAG, `getLastPhotoAsset fetchOptions: ${JSON.stringify(fetchOptions)}, helper: ${JSON.stringify(helper)}.`);
      HiLog.begin(TAG, 'getCameraAlbums');
      const cameraAlbum: photoAccessHelper.Album = await this.getCameraAlbums(helper);
      HiLog.end(TAG, 'getCameraAlbums');
      fetchResult = await cameraAlbum.getAssets(fetchOptions);
      if (!fetchResult || fetchResult.getCount() === 0) {
        HiLog.i(TAG, 'getPhotoAssetsByFetchOp error: fetchResult undefined.');
        fetchResult?.close();
        return undefined;
      }
      HiLog.i(TAG, `getPhotoAssetsByFetchOp success: ${fetchResult.getCount()}.`);
      const photoAsset = await fetchResult.getFirstObject();
      fetchResult.close();
      HiLog.iWithUri(TAG, `getPhotoAssetsByFetchOp uri: ${photoAsset?.uri}.`);
      return photoAsset;
    } catch (e) {
      fetchResult?.close();
      HiLog.e(TAG, `getLastPhotoAsset error: ${JSON.stringify(e)}.`);
    }
    return undefined;
  }

  /* instrument ignore next */
  public static async createPhotoAsset(helper: photoAccessHelper.PhotoAccessHelper, type: photoAccessHelper.PhotoType,
    savePhotoFormat: camera.CameraFormat): Promise<photoAccessHelper.PhotoAsset> {
    const displayName: string = this.createFileName(type, savePhotoFormat);
    HiLog.i(TAG, `createPhotoAsset displayName: ${displayName}.`);
    const option: photoAccessHelper.PhotoCreateOptions = {
      subtype: photoAccessHelper.PhotoSubtype.DEFAULT
    };
    let cameraShotKey: string = getStates().get<string>('securityCameraReducer', 'cameraShotKey') ||
    GlobalContext.get().getCameraShotKey();
    HiLog.i(TAG, `createPhotoAsset cameraShotKey: ${cameraShotKey}`);
    if (!!cameraShotKey) {
      option.cameraShotKey = cameraShotKey;
    }
    HiLog.i(TAG, `createPhotoAsset option: ${JSON.stringify(option)}`);
    try {
      HiLog.i(TAG, `createAsset, helper: ${JSON.stringify(helper)}.`);
      HiLog.begin(TAG, `createAsset-${displayName}`);
      let photoAsset: photoAccessHelper.PhotoAsset | null = null;
      // 调用NAPI接口,尽量使用链式调用的方式,只使用await的话,接口报错时,最外层的try-catch捕获不了异常
      await helper.createAsset(displayName, option).then((pa: photoAccessHelper.PhotoAsset) => {
        if (!pa) {
          HiLog.e(TAG, 'createAsset the back value is null');
          return;
        }
        photoAsset = pa;
      }).catch((err) => {
        HiLog.e(TAG, `createAsset err. errCode: ${err?.code}`);
      });
      HiLog.end(TAG, `createAsset-${displayName}`);
      if (!!photoAsset) {
        HiLog.i(TAG, `createPhotoAsset successfully displayName: ${JSON.stringify(photoAsset.displayName)}.`);
      } else {
        if (type === photoAccessHelper.PhotoType.IMAGE) {
        } else if (type === photoAccessHelper.PhotoType.VIDEO) {
        }
        HiLog.e(TAG, 'createPhotoAsset failed: undefined.');
      }
      return photoAsset;
    } catch (e) {
      HiLog.e(TAG, `createPhotoAsset error: ${JSON.stringify(e)}.`);
      return undefined;
    }
  }

  /* instrument ignore next */
  public static createFileName(type: photoAccessHelper.PhotoType, savePhotoFormat: camera.CameraFormat): string {
    const mDateTimeUtil: DateTimeUtil = new DateTimeUtil();
    const mData: string = mDateTimeUtil.getDate();
    const mTime: string = mDateTimeUtil.getTime();
    if (type === photoAccessHelper.PhotoType.IMAGE) {
      return savePhotoFormat === camera.CameraFormat.CAMERA_FORMAT_DNG ?
        `${this.checkName(`IMG_${mData}_${mTime}`)}.dng` :
        savePhotoFormat === 2003 ? `${this.checkName(`IMG_${mData}_${mTime}`)}.heic` :
          `${this.checkName(`IMG_${mData}_${mTime}`)}.jpg`;
    } else {
      return `${this.checkName(`VID_${mData}_${mTime}`)}.mp4`;
    }
  }

  /* instrument ignore next */
  public static checkName(name: string): string {
    if (this.lastSaveTime === name) {
      this.saveIndex++;
      return `${name}_${this.saveIndex}`;
    }
    this.lastSaveTime = name;
    this.saveIndex = 0;
    return name;
  }
}