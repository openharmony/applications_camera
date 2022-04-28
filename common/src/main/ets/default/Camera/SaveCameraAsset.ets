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

import fileio from '@ohos.fileio'
import mediaLibrary from '@ohos.multimedia.mediaLibrary'

import { CLog } from '../Utils/CLog'
import DateTimeUtil from '../Utils/DateTimeUtil'

let photoUri;

export default class SaveCameraAsset {
  constructor() {

  }

  private TAG = '[SaveCameraAsset:] '
  private lastSaveTime: string = ''
  private saveIndex: number = 0
  public videoPrepareFile: any

  public getPhotoUri() {
    CLog.log(`${this.TAG} getPhotoUri= ${photoUri}`)
    return photoUri
  }

  public saveImage(mReceiver, thumbWidth, thumbHeight, thumbnailGetter, captureCallBack) {
    CLog.info(`${this.TAG} saveImage E`)
    let mDateTimeUtil = new DateTimeUtil();
    let fileKeyObj = mediaLibrary.FileKey
    let mediaType = mediaLibrary.MediaType.IMAGE;
    let buffer = new ArrayBuffer(4096)
    const media = mediaLibrary.getMediaLibrary(globalThis.cameraAbilityContext);
    CLog.info(`${this.TAG} saveImage mediaLibrary.getMediaLibrary media: ${media}`)

    mReceiver.on('imageArrival', async () => {
      CLog.log(`${this.TAG} saveImage ImageReceiver on called`)
      let displayName = this.checkName(`IMG_${mDateTimeUtil.getDate()}_${mDateTimeUtil.getTime()}`) + '.jpg'
      CLog.log(`${this.TAG} saveImage displayName== ${displayName}`)
      mReceiver.readNextImage((err, image) => {
        CLog.info(`${this.TAG} readNextImage image = ${image} error = ${err}`)
        if (image === undefined) {
          CLog.info(`${this.TAG} saveImage failed to get valid image`)
          return
        }
        image.getComponent(4, async (errMsg, img) => {
          CLog.info(`${this.TAG} getComponent img = ${img} errMsg = ${errMsg} E`)
          if (img === undefined) {
            CLog.info(`${this.TAG} getComponent failed to get valid buffer`)
            return
          }
          if (img.byteBuffer) {
            CLog.info(`${this.TAG} getComponent img.byteBuffer = ${img.byteBuffer}`)
            buffer = img.byteBuffer
          } else {
            CLog.info(`${this.TAG} getComponent img.byteBuffer is undefined`)
          }
          await image.release()
          CLog.info(`${this.TAG} getComponent  X`)
        })
      })

      CLog.info(`${this.TAG} saveImage getPublicDirectory `)
      let publicPath: string = await media.getPublicDirectory(mediaLibrary.DirectoryType.DIR_IMAGE);
      publicPath = `${publicPath}Camera/`
      CLog.info(`${this.TAG} saveImage publicPath = ${publicPath}`)
      let dataUri = await media.createAsset(mediaType, displayName, publicPath)
      photoUri = dataUri.uri
      CLog.info(`${this.TAG} saveImage photoUri: ${photoUri}`)

      if (dataUri !== undefined) {
        let args = dataUri.id.toString()
        let fetchOp = {
          selections: `${fileKeyObj.ID} = ? `,
          selectionArgs: [args],
        }
        // 通过id去查找
        CLog.log(`${this.TAG} saveImage fetchOp${JSON.stringify(fetchOp)}`)
        let fetchFileResult = await media.getFileAssets(fetchOp);
        let fileAsset = await fetchFileResult.getAllObject();
        if (fileAsset != undefined) {
          CLog.info(`${this.TAG} saveImage fileAsset is not undefined`)
          fileAsset.forEach((dataInfo) => {
            CLog.info(`${this.TAG} saveImage fileAsset.forEach called`)
            dataInfo.open('Rw').then((fd) => { // RW是读写方式打开文件 获取fd
              CLog.info(`${this.TAG} saveImage dataInfo.open called`)
              fileio.write(fd, buffer).then(() => {
                CLog.info(`${this.TAG} saveImage fileio.write called`)
                dataInfo.close(fd).then(() => {
                  CLog.info(`${this.TAG} saveImage ataInfo.close called`)
                  thumbnailGetter.getThumbnailInfo(thumbWidth, thumbHeight, photoUri).then(thumbnail => {
                    CLog.info(`${this.TAG} saveImage thumbnailInfo: ${thumbnail}`)
                    captureCallBack.onCaptureSuccess(thumbnail)
                  })
                  CLog.info(`${this.TAG} ==========================fileAsset.close success=======================>`);
                }).catch(error => {
                  CLog.error(`${this.TAG} saveImage close is error ${JSON.stringify(error)}`)
                })
              })
            })
          });
        }
      }
    })
    CLog.info(`${this.TAG} saveImage X`)
  }

  public async createVideoFd(): Promise<number> {
    CLog.info(`${this.TAG} getVideoFd E`)
    let mDateTimeUtil = new DateTimeUtil();
    let displayName = this.checkName(`VID_${mDateTimeUtil.getDate()}_${mDateTimeUtil.getTime()}`) + '.mp4'
    const media = mediaLibrary.getMediaLibrary(globalThis.cameraAbilityContext);
    CLog.info(`${this.TAG} getVideoFd publicPath: ${media}`)
    let fileKeyObj = mediaLibrary.FileKey;
    let mediaType = mediaLibrary.MediaType.VIDEO;
    let publicPath: string = await media.getPublicDirectory(mediaLibrary.DirectoryType.DIR_IMAGE);
    CLog.info(`${this.TAG} getVideoFd publicPath: ${JSON.stringify(publicPath)}`)
    publicPath = `${publicPath}Camera/`
    try {
      let dataUri = await  media.createAsset(mediaType, displayName, publicPath)
      if (dataUri !== undefined) {
        let args = dataUri.id.toString()
        let fetchOp = {
          selections: `${fileKeyObj.ID} = ? `,
          selectionArgs: [args],
        }
        // 通过id去查找
        CLog.log(`${this.TAG} fetchOp= ${JSON.stringify(fetchOp)}`)
        let fetchFileResult = await media.getFileAssets(fetchOp);
        CLog.info(`${this.TAG} SaveCameraAsset getFileAssets finished`)
        this.videoPrepareFile = await fetchFileResult.getFirstObject();
        CLog.info(`${this.TAG} SaveCameraAsset getFirstObject finished`)
        let fdNumber = await this.videoPrepareFile.open('Rw')
        return fdNumber;
      }
    } catch (err) {
      CLog.error(`${this.TAG} createVideoFd err: ` + err)
    }
    CLog.info(`${this.TAG} getVideoFd X`)
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