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

import fileio from '@ohos.fileio'
import mediaLibrary from '@ohos.multimedia.mediaLibrary'

import { Log } from '../utils/Log'
import DateTimeUtil from '../utils/DateTimeUtil'
import { FunctionCallBack, VideoCallBack } from './CameraService'
import ThumbnailGetter from './ThumbnailGetter'
import EventLog from '../utils/EventLog'

let photoUri: string;

export default class SaveCameraAsset {
  constructor() {

  }

  private TAG = '[SaveCameraAsset:] '
  private lastSaveTime = ''
  private saveIndex = 0
  public videoPrepareFile: any

  public getPhotoUri() {
    Log.log(`${this.TAG} getPhotoUri= ${photoUri}`)
    return photoUri
  }

  public saveImage(mReceiver, thumbWidth: number, thumbHeight: number, thumbnailGetter: ThumbnailGetter, captureCallBack: FunctionCallBack) {
    Log.info(`${this.TAG} saveImage E`)
    const mDateTimeUtil = new DateTimeUtil();
    const fileKeyObj = mediaLibrary.FileKey
    const mediaType = mediaLibrary.MediaType.IMAGE;
    let buffer = new ArrayBuffer(4096)
    const media = mediaLibrary.getMediaLibrary(globalThis.cameraAbilityContext);
    Log.info(`${this.TAG} saveImage mediaLibrary.getMediaLibrary media: ${media}`)

    mReceiver.on('imageArrival', async () => {
      Log.start(Log.UPDATE_PHOTO_THUMBNAIL)
      Log.log(`${this.TAG} saveImage ImageReceiver on called`)
      const displayName = this.checkName(`IMG_${mDateTimeUtil.getDate()}_${mDateTimeUtil.getTime()}`) + '.jpg'
      Log.log(`${this.TAG} saveImage displayName== ${displayName}`)
      mReceiver.readNextImage((err, image) => {
        Log.error(`${this.TAG} readNextImage image = ${image} error = ${err}`)
        if (image === undefined) {
          Log.info(`${this.TAG} saveImage failed to get valid image`)
          return
        }
        image.getComponent(4, async (errMsg, img) => {
          Log.info(`${this.TAG} getComponent img = ${img} errMsg = ${errMsg} E`)
          if (img === undefined) {
            Log.error(`${this.TAG} getComponent failed to get valid buffer`)
            return
          }
          if (img.byteBuffer) {
            Log.info(`${this.TAG} getComponent img.byteBuffer = ${img.byteBuffer}`)
            buffer = img.byteBuffer
            captureCallBack.onCapturePhotoOutput()
          } else {
            Log.info(`${this.TAG} getComponent img.byteBuffer is undefined`)
          }
          await image.release()
          Log.info(`${this.TAG} getComponent  X`)
        })
      })

      Log.info(`${this.TAG} saveImage getPublicDirectory `)
      let publicPath: string = await media.getPublicDirectory(mediaLibrary.DirectoryType.DIR_CAMERA)
//      publicPath = `${publicPath}Camera/`
      Log.info(`${this.TAG} saveImage publicPath = ${publicPath}`)
      const dataUri = await media.createAsset(mediaType, displayName, publicPath)
      photoUri = dataUri.uri
      Log.info(`${this.TAG} saveImage photoUri: ${photoUri}`)

      if (dataUri !== undefined) {
        const args = dataUri.id.toString()
        const fetchOp = {
          selections: `${fileKeyObj.ID} = ? `,
          selectionArgs: [args],
        }
        // 通过id去查找
        Log.log(`${this.TAG} saveImage fetchOp${JSON.stringify(fetchOp)}`)
        const fetchFileResult = await media.getFileAssets(fetchOp);
        const fileAsset = await fetchFileResult.getAllObject();
        if (fileAsset != undefined) {
          Log.info(`${this.TAG} saveImage fileAsset is not undefined`)
          fileAsset.forEach((dataInfo) => {
            Log.info(`${this.TAG} saveImage fileAsset.forEach called`)
            dataInfo.open('Rw').then((fd) => { // RW是读写方式打开文件 获取fd
              Log.info(`${this.TAG} saveImage dataInfo.open called`)
              fileio.write(fd, buffer).then(() => {
                Log.info(`${this.TAG} saveImage fileio.write called`)
                dataInfo.close(fd).then(() => {
                  Log.info(`${this.TAG} saveImage ataInfo.close called`)
                  thumbnailGetter.getThumbnailInfo(thumbWidth, thumbHeight, photoUri).then(thumbnail => {
                    Log.info(`${this.TAG} saveImage thumbnailInfo: ${thumbnail}`)
                    captureCallBack.onCaptureSuccess(thumbnail, photoUri)
                    Log.end(Log.UPDATE_PHOTO_THUMBNAIL)
                  })
                  Log.info(`${this.TAG} ==========================fileAsset.close success=======================>`);
                }).catch(error => {
                  EventLog.write(EventLog.SAVE_FAIL)
                  Log.error(`${this.TAG} saveImage close is error `)
                })
              })
            })
          });
        }
      } else {
        Log.error(`${this.TAG} dataUri is null`)
      }
    })
    Log.info(`${this.TAG} saveImage X`)
  }

  public async createVideoFd(captureCallBack: VideoCallBack): Promise<number> {
    Log.info(`${this.TAG} getVideoFd E`)
    const mDateTimeUtil = new DateTimeUtil();
    const displayName = this.checkName(`VID_${mDateTimeUtil.getDate()}_${mDateTimeUtil.getTime()}`) + '.mp4'
    const media = mediaLibrary.getMediaLibrary(globalThis.cameraAbilityContext);
    Log.info(`${this.TAG} getVideoFd publicPath: ${media}`)
    const fileKeyObj = mediaLibrary.FileKey;
    const mediaType = mediaLibrary.MediaType.VIDEO;
    let publicPath: string = await media.getPublicDirectory(mediaLibrary.DirectoryType.DIR_CAMERA)
    Log.info(`${this.TAG} getVideoFd publicPath: ${JSON.stringify(publicPath)}`)
//    publicPath = `${publicPath}Camera/`
    try {
      const dataUri = await media.createAsset(mediaType, displayName, publicPath)
      if (dataUri !== undefined) {
        const args = dataUri.id.toString()
        const fetchOp = {
          selections: `${fileKeyObj.ID} = ? `,
          selectionArgs: [args],
        }
        // 通过id去查找
        Log.log(`${this.TAG} fetchOp= ${JSON.stringify(fetchOp)}`)
        const fetchFileResult = await media.getFileAssets(fetchOp);
        Log.info(`${this.TAG} SaveCameraAsset getFileAssets finished`)
        this.videoPrepareFile = await fetchFileResult.getFirstObject();
        const getLastObject = await fetchFileResult.getLastObject()
        captureCallBack.videoUri(getLastObject.uri)
        Log.info(`${this.TAG} SaveCameraAsset getLastObject.uri: ${JSON.stringify(getLastObject.uri)}`)
        const fdNumber = await this.videoPrepareFile.open('Rw')
        return fdNumber;
      }
    } catch (err) {
      Log.error(`${this.TAG} createVideoFd err: ` + err)
    }
    Log.info(`${this.TAG} getVideoFd X`)
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