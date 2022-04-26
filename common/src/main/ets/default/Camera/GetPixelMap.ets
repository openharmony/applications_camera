/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import mediaLibrary from '@ohos.multimedia.mediaLibrary';

import { CLog } from '../Utils/CLog'

export default class GetPixelMap {
  private TAG = '[GetPixelMap]:'

  public async getThumbnailInfo(width: number, height: number, uri?: string): Promise<PixelMap> {
    CLog.log(`${this.TAG} getThumbnailInfo E`)
    CLog.log(`${this.TAG} getThumbnailInfo width: ${width}, height: ${height}, uri: ${JSON.stringify(uri)}`)
    let fileKeyObj = mediaLibrary.FileKey;
    let fetchOp: any
    const media = mediaLibrary.getMediaLibrary(globalThis.cameraAbilityContext);
    CLog.log(`${this.TAG} getThumbnailInfo media: ${media}`)
    fetchOp = {
      selections: `${fileKeyObj.RELATIVE_PATH}=?`,
      selectionArgs: ["Pictures/Camera/"],
      order: fileKeyObj.DATE_ADDED,
    }

    CLog.log(`${this.TAG} getThumbnailInfo fetchOp: ${JSON.stringify(fetchOp)}`)
    let fetchFileResult = await media.getFileAssets(fetchOp);
    let count = fetchFileResult.getCount()
    CLog.log(`${this.TAG} getThumbnailInfo fetchFileResult.getCount: ${count}`)
    if (count == 0) {
      return null
    }
    let lastFileAsset = await fetchFileResult.getLastObject()
    if (lastFileAsset == null) {
      return null
    }
    let thumbnailPixelMap = lastFileAsset.getThumbnail({size: {width: 40, height: 40}})
    CLog.info(`${this.TAG} getThumbnailInfo thumbnailPixelMap: ${JSON.stringify(thumbnailPixelMap)} X`)
    return thumbnailPixelMap
  }
}
