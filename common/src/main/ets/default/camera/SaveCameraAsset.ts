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

import fileio from '@ohos.fileio';
import mediaLibrary from '@ohos.multimedia.mediaLibrary';

import { Log } from '../utils/Log';
import DateTimeUtil from '../utils/DateTimeUtil';
import type { FunctionCallBack, VideoCallBack } from './CameraService';
import type ThumbnailGetter from './ThumbnailGetter';
import EventLog from '../utils/EventLog';

const TAG = '[SaveCameraAsset]:';
let photoUri: string;

export default class SaveCameraAsset {
  public videoPrepareFile: any;
  private lastSaveTime = '';
  private saveIndex = 0;

  constructor() {

  }

  public getPhotoUri() {
    Log.log(`${TAG} getPhotoUri= ${photoUri}`);
    return photoUri;
  }

  public saveImage(mReceiver, thumbWidth: number, thumbHeight: number, thumbnailGetter: ThumbnailGetter, captureCallBack: FunctionCallBack): void {
    Log.info(`${TAG} saveImage E`);
    const mDateTimeUtil = new DateTimeUtil();
    const fileKeyObj = mediaLibrary.FileKey;
    const mediaType = mediaLibrary.MediaType.IMAGE;
    let buffer = new ArrayBuffer(4096);
    const media = mediaLibrary.getMediaLibrary(globalThis.cameraAbilityContext);
    Log.info(`${TAG} saveImage mediaLibrary.getMediaLibrary media: ${media}`);

    mReceiver.on('imageArrival', async () => {
      Log.start(Log.UPDATE_PHOTO_THUMBNAIL);
      Log.log(`${TAG} saveImage ImageReceiver on called`);
      const displayName = this.checkName(`IMG_${mDateTimeUtil.getDate()}_${mDateTimeUtil.getTime()}`) + '.jpg';
      Log.log(`${TAG} saveImage displayName== ${displayName}`);
      mReceiver.readNextImage((err, image) => {
        Log.error(`${TAG} readNextImage image = ${image} error = ${err}`);
        if (image === undefined) {
          Log.info(`${TAG} saveImage failed to get valid image`);
          return;
        }
        image.getComponent(4, async (errMsg, img) => {
          Log.info(`${TAG} getComponent img = ${img} errMsg = ${errMsg} E`);
          if (img === undefined) {
            Log.error(`${TAG} getComponent failed to get valid buffer`);
            return;
          }
          if (img.byteBuffer) {
            Log.info(`${TAG} getComponent img.byteBuffer = ${img.byteBuffer}`);
            buffer = img.byteBuffer;
            captureCallBack.onCapturePhotoOutput();
          } else {
            Log.info(`${TAG} getComponent img.byteBuffer is undefined`);
          }
          await image.release();
          Log.info(`${TAG} getComponent  X`);
        })
      })

      Log.info(`${TAG} saveImage getPublicDirectory `);
      let publicPath: string = await media.getPublicDirectory(mediaLibrary.DirectoryType.DIR_CAMERA);
      //      publicPath = `${publicPath}Camera/`
      Log.info(`${TAG} saveImage publicPath = ${publicPath}`);
      const dataUri = await media.createAsset(mediaType, displayName, publicPath);
      photoUri = dataUri.uri;
      Log.info(`${TAG} saveImage photoUri: ${photoUri}`);

      if (dataUri !== undefined) {
        const args = dataUri.id.toString();
        const fetchOp = {
          selections: `${fileKeyObj.ID} = ? `,
          selectionArgs: [args],
        }
        // 通过id去查找
        Log.log(`${TAG} saveImage fetchOp${JSON.stringify(fetchOp)}`);
        const fetchFileResult = await media.getFileAssets(fetchOp);
        const fileAsset = await fetchFileResult.getAllObject();
        if (fileAsset != undefined) {
          Log.info(`${TAG} saveImage fileAsset is not undefined`);
          fileAsset.forEach((dataInfo) => {
            Log.info(`${TAG} saveImage fileAsset.forEach called`);
            dataInfo.open('Rw').then((fd) => { // RW是读写方式打开文件 获取fd
              Log.info(`${TAG} saveImage dataInfo.open called`);
              fileio.write(fd, buffer).then(() => {
                Log.info(`${TAG} saveImage fileio.write called`);
                dataInfo.close(fd).then(() => {
                  Log.info(`${TAG} saveImage ataInfo.close called`);
                  thumbnailGetter.getThumbnailInfo(thumbWidth, thumbHeight, photoUri).then(thumbnail => {
                    Log.info(`${TAG} saveImage thumbnailInfo: ${thumbnail}`);
                    captureCallBack.onCaptureSuccess(thumbnail, photoUri);
                    Log.end(Log.UPDATE_PHOTO_THUMBNAIL);
                  })
                  Log.info(`${TAG} ==========================fileAsset.close success=======================>`);
                }).catch(error => {
                  EventLog.write(EventLog.SAVE_FAIL);
                  Log.error(`${TAG} saveImage close is error `);
                })
              })
            })
          });
        }
      } else {
        Log.error(`${TAG} dataUri is null`);
      }
    })
    Log.info(`${TAG} saveImage X`);
  }

  public async createVideoFd(captureCallBack: VideoCallBack): Promise<number> {
    Log.info(`${TAG} getVideoFd E`);
    const mDateTimeUtil = new DateTimeUtil();
    const displayName = this.checkName(`VID_${mDateTimeUtil.getDate()}_${mDateTimeUtil.getTime()}`) + '.mp4';
    const media = mediaLibrary.getMediaLibrary(globalThis.cameraAbilityContext);
    Log.info(`${TAG} getVideoFd publicPath: ${media}`);
    const fileKeyObj = mediaLibrary.FileKey;
    const mediaType = mediaLibrary.MediaType.VIDEO;
    let publicPath: string = await media.getPublicDirectory(mediaLibrary.DirectoryType.DIR_CAMERA);
    Log.info(`${TAG} getVideoFd publicPath: ${JSON.stringify(publicPath)}`);
    //    publicPath = `${publicPath}Camera/`
    try {
      const dataUri = await media.createAsset(mediaType, displayName, publicPath);
      if (dataUri !== undefined) {
        const args = dataUri.id.toString();
        const fetchOp = {
          selections: `${fileKeyObj.ID} = ? `,
          selectionArgs: [args],
        };
        // 通过id去查找
        Log.log(`${TAG} fetchOp= ${JSON.stringify(fetchOp)}`);
        const fetchFileResult = await media.getFileAssets(fetchOp);
        Log.info(`${TAG} SaveCameraAsset getFileAssets finished`);
        this.videoPrepareFile = await fetchFileResult.getFirstObject();
        const getLastObject = await fetchFileResult.getLastObject();
        captureCallBack.videoUri(getLastObject.uri);
        Log.info(`${TAG} SaveCameraAsset getLastObject.uri: ${JSON.stringify(getLastObject.uri)}`);
        const fdNumber = await this.videoPrepareFile.open('Rw');
        return fdNumber;
      }
    } catch (err) {
      Log.error(`${TAG} createVideoFd err: ` + err);
    }
    Log.info(`${TAG} getVideoFd X`);
  }

  private checkName(name: string): string {
    if (this.lastSaveTime == name) {
      this.saveIndex++;
      return `${name}_${this.saveIndex}`;
    }
    this.lastSaveTime = name;
    this.saveIndex = 0;
    return name;
  }
}