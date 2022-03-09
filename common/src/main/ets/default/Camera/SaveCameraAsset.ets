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
import fileio from '@ohos.fileio';
import DateTimeUtil from '../Utils/DateTimeUtil';
let photoUri;

export default class SaveCameraAsset {
  constructor() {

  }
  private TAG = 'image: '
  private lastSaveTime: string = ''
  private saveIndex : number = 0

  public getPhotoUri() {
    console.log(`getPhotoUri= ${photoUri}`)
    return photoUri
  }

  public saveImage(mReceiver, thumbWidth, thumbHeight, thumbCallback, getPixelMap, captureSuccessCallBack) {
    let mDateTimeUtil = new DateTimeUtil();
    let fileKeyObj = mediaLibrary.FileKey
    let mediaType = mediaLibrary.MediaType.IMAGE;
    let buffer = new ArrayBuffer(4096)
    const media = mediaLibrary.getMediaLibrary(globalThis.cameraAbilityContext);
    console.log("mediaLibrary.getMediaLibrary success")

    mReceiver.on('imageArrival', async () => {
      console.log("ImageReceiver on called")
      let displayName = this.checkName(`IMG_${mDateTimeUtil.getDate()}_${mDateTimeUtil.getTime()}`) + '.jpg'
      console.log(`saveImage displayName== ${displayName}`)
      mReceiver.readNextImage((err, image) => {
        if (image === undefined) {
          console.info(`${this.TAG} failed to get valid image`)
          return
        }
        image.getComponent(4, async (errMsg, img) => {
          if (img === undefined) {
            console.info(`${this.TAG} failed to get valid buffer`)
            return
          }
          if (img.byteBuffer) {
            buffer = img.byteBuffer
          } else {
            console.info(`${this.TAG} img.byteBuffer is undefined`)
          }
          await image.release()
        })
      })

      let publicPath: string = await media.getPublicDirectory(mediaLibrary.DirectoryType.DIR_IMAGE);
      publicPath = `${publicPath}Camera/`
      let dataUri = await media.createAsset(mediaType, displayName, publicPath)
      photoUri = dataUri.uri
      console.info(`${this.TAG} SaveCameraAsset photoUri: ${photoUri}`)

      if (dataUri !== undefined) {
        let args = dataUri.id.toString()
        let fetchOp = {
          selections: `${fileKeyObj.ID} = ? `,
          selectionArgs: [args],
        }

        console.log(`fetchOp${JSON.stringify(fetchOp)}`)
        let fetchFileResult = await media.getFileAssets(fetchOp);
        let fileAsset = await fetchFileResult.getAllObject();
        if (fileAsset != undefined) {
          console.info("fileAsset is not undefined")
          fileAsset.forEach((dataInfo) => {
            console.info("fileAsset.forEach called")
            dataInfo.open('Rw').then((fd) => {
              console.info("dataInfo.open called")
              fileio.write(fd, buffer).then(() => {
                console.info("fileio.write called")
                dataInfo.close(fd).then(() => {
                  console.info("ataInfo.close called")
                  captureSuccessCallBack()
                  getPixelMap.getThumbnailInfo(thumbWidth, thumbHeight, photoUri).then(thumbnail => {
                    console.info(`${this.TAG} getThumbnailInfo thumbnailInfo: ${thumbnail}`)
                    thumbCallback(thumbnail)
                  })
                  console.info("==========================fileAsset.close success=======================>");
                }).catch(error => {
                  console.info(`close is error ${JSON.stringify(error)}`)
                })
              })
            })
          });
        }
      }
    })
  }

  public async getVideoFd(): Promise<any> {

    let mDateTimeUtil = new DateTimeUtil();
    let displayName = this.checkName(`VID_${mDateTimeUtil.getDate()}_${mDateTimeUtil.getTime()}`) + '.mp4'
    const media = mediaLibrary.getMediaLibrary(globalThis.cameraAbilityContext);
    let fileKeyObj = mediaLibrary.FileKey;
    let mediaType = mediaLibrary.MediaType.VIDEO;
    let publicPath: string = await media.getPublicDirectory(mediaLibrary.DirectoryType.DIR_VIDEO);
    publicPath = `${publicPath}Camera/`
    let dataUri = await  media.createAsset(mediaType, displayName, publicPath)
    if (dataUri !== undefined) {
      let args = dataUri.id.toString()
      let fetchOp = {
        selections: `${fileKeyObj.ID} = ? `,
        selectionArgs: [args],
      }

      console.log(`fetchOp= ${JSON.stringify(fetchOp)}`)
      let fetchFileResult = await media.getFileAssets(fetchOp);
      let fileAssets = await fetchFileResult.getAllObject();
      return fileAssets;
    }
  }

  private checkName(name: string): string {
    if (this.lastSaveTime == name) {
      this.saveIndex++
      return `${name}_${this.saveIndex}`
    }
    this.lastSaveTime = name
    this.saveIndex = 0
    return name
  }
}