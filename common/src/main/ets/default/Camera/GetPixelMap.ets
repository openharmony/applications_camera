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
export default class GetPixelMap {

  public async getThumbnailInfo(width: number, height: number, uri?: string): Promise<string> {
    console.log("getThumbnailInfoA start")
    let thumbnail
    let fileKeyObj = mediaLibrary.FileKey;
    let fetchOp: any
    const media = mediaLibrary.getMediaLibrary(globalThis.cameraAbilityContext);
    if (uri != undefined) {
      return uri
    }
    fetchOp = {
      selections: `${fileKeyObj.RELATIVE_PATH}=?`,
      selectionArgs: ["Pictures/Camera/"],
      order: fileKeyObj.DATE_ADDED,
    }

    console.log(`fetchOp ${JSON.stringify(fetchOp)}`);
    let fetchFileResult = await media.getFileAssets(fetchOp);
    let count = fetchFileResult.getCount()
    console.log(`getThumbnailInfo fetchFileResult.getCount: ${count}`)
    if (count == 0) {
      return ''
    }
    let lastFileAsset = await fetchFileResult.getLastObject()
    thumbnail = lastFileAsset.uri
    console.info(`getThumbnailInfo fileAsset.uri: ${thumbnail}`)
    return thumbnail;
  }
}
