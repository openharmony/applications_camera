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

import media from '@ohos.multimedia.media';
import lazy { fs } from '../../../../utils/LazyImportUtil';
import lazy { HiLog } from '../../../../utils/HiLog';
import type photoAccessHelper from '@ohos.file.photoAccessHelper';
import lazy { DeviceInfo } from '../../../../component/deviceinfo/DeviceInfo';
import lazy { modulesManager } from '../../../../worker/WorkerModuleManager';
import lazy { GlobalContext } from '../../../../utils/GlobalContext';
import lazy { simpleStringify } from '../../../../utils/SimpleStringify';
import lazy { image } from '@kit.ImageKit';
import lazy { workerCallback } from '../../WorkerCallback';
import lazy { LOCATION_MESSAGE } from '../../CameraTaskHandler';
import lazy { TagMessage, VideoOutputMessage } from '../../../DataType';
import CameraContext from '../CameraContext';
import type { PickerInfo } from '../../../../utils/types';
import lazy { WorkerDataCache } from '../../WorkerDataCache';
import lazy { camera } from '@kit.CameraKit';
import lazy { LocationType } from '../../../../service/location/LocationMessage';

/* instrument ignore file */
const TAG: string = 'RecorderWrap';

export interface ExtraData {
  isNeedSaveSuperSlow: boolean;
  isSlowMotion: boolean;
  validateThumbnail: boolean;
}

// Recorder包装类
export default class RecorderWrap {
  private static sInstance: RecorderWrap;
  private recorder!: media.AVRecorder;
  private fileManager!: VideoFileManager;
  private recorderState: media.AVRecorderState = 'idle';
  private surfaceId: string = '';
  private recorderProfile: media.AVRecorderProfile;
  private recorderAudioSourceType?: media.AudioSourceType;
  // 音频
  private initVideoOutputMessage: VideoOutputMessage = undefined;
  // 初始化对象的引用持有
  private initTagMessage: TagMessage = undefined;
  // 初始化对象的引用持有
  private isAddWatermark: boolean = undefined;
  private deferredVideoEnhanceFlag: string = '0';
  private isStopping: boolean = false;
  private isSoftwareVideoWaterMarkInSwipeRecording: boolean = false;
  private lastLocationType: LocationType = undefined;
  private isNeedRelease: boolean = false;

  private constructor() {
    this.fileManager = new VideoFileManager();
  }

  public static getInstance(): RecorderWrap {
    if (!RecorderWrap.sInstance) {
      RecorderWrap.sInstance = new RecorderWrap();
    }
    return RecorderWrap.sInstance;
  }

  // AVRecorder create: null -> idle
  public async create(): Promise<void> {
    HiLog.i(TAG, 'AVRecorder create.');
    if (!!this.recorder && this.recorder.state !== 'released' && this.recorder.state !== 'error') {
      HiLog.w(TAG, `AVRecorder has been initialized, state is ${this.recorder.state}.`);
      return;
    }
    HiLog.begin(TAG, 'AVRecorderCreate');
    try {
      this.recorder = await media.createAVRecorder();
      HiLog.i(TAG, 'createAVReorder on success.');
      //监听AVRecorder的error状态，当发生异常错误的时候主动停止录像
      this.recorder.on('error', async (error) => {
        if (this.recorderState !== 'idle' && this.recorderState !== 'prepared') {
          workerCallback.onRecordError(error.code, error.message);
        }
        this.release();
      });
      HiLog.i(TAG, 'createAVReorder on stateChange.');
      this.recorder.on('stateChange', (state: media.AVRecorderState, reason: media.StateChangeReason) => {
        HiLog.i(TAG, `RecorderState change to ${state}, reasion is ${reason}.`);
        if (state === 'paused' && this.recorderState !== state) {
          workerCallback.onRecordPaused();
        }
        this.recorderState = state;
      });
    } catch (e) {
      HiLog.e(TAG, `createAVRecorder or on listen error: ${e}.`);
    }
    HiLog.end(TAG, 'AVRecorderCreate');
    HiLog.i(TAG, `AVRecorder create done, state change to: ${this.recorder.state}.`);
  }

  // AVRecorder getSurface: null/idle -> prepared
  public async getSurfaceSwiftly(message: VideoOutputMessage, tagMessage: TagMessage,
    pickerInfo?: PickerInfo): Promise<string> {
    HiLog.i(TAG, `getInputSurface begin, state: ${this.recorder?.state}. is addWaterMark :${message.isAddWaterMark}`);
    this.initVideoOutputMessage = message;
    this.initTagMessage = tagMessage;
    await this.prepareAccurately(message, pickerInfo);
    HiLog.i(TAG, `getInputSurface end, surface: ${this.surfaceId}, state change to: ${this.recorder.state}.`);
    return this.surfaceId;
  }

  private checkHDRAndRemedyMessage(videoMessage: VideoOutputMessage, tagMessage: TagMessage): void {
    if (!videoMessage?.videoProfile || !videoMessage?.config) {
      return;
    }
    if (tagMessage.isHdrVividFlag &&
      this.initVideoOutputMessage.videoProfile.format === camera.CameraFormat.CAMERA_FORMAT_YCRCB_P010 &&
      videoMessage.config.profile.videoCodec === media.CodecMimeType.VIDEO_HEVC &&
    videoMessage.config.profile.isHdr) {
      return; // 开启HDR vivid场景校验通过
    }
    if (!tagMessage.isHdrVividFlag &&
      this.initVideoOutputMessage.videoProfile.format !== camera.CameraFormat.CAMERA_FORMAT_YCRCB_P010 &&
      !videoMessage.config.profile.isHdr) {
      return; // 关闭HDR vivid场景校验通过
    }
    HiLog.i(TAG, `checkHDRAndRemedyMessage hdr: ${this.initVideoOutputMessage.videoProfile.format}.`);
    // 再次prepare时状态不一致,矫正与videoProfile.format保持一致,因为录像流可能已经创建过了
    if (this.initVideoOutputMessage.videoProfile.format === camera.CameraFormat.CAMERA_FORMAT_YCRCB_P010) {
      tagMessage.isHdrVividFlag = true;
      videoMessage.config.profile.videoCodec = media.CodecMimeType.VIDEO_HEVC;
      videoMessage.config.profile.isHdr = true;
    }
    if (this.initVideoOutputMessage.videoProfile.format !== camera.CameraFormat.CAMERA_FORMAT_YCRCB_P010) {
      tagMessage.isHdrVividFlag = false;
      videoMessage.config.profile.isHdr = false;
    }
    videoMessage.videoProfile = {
      format: this.initVideoOutputMessage.videoProfile.format,
      size: {
        'width': this.initVideoOutputMessage.videoProfile.size.width,
        'height': this.initVideoOutputMessage.videoProfile.size.height
      },
      frameRateRange: {
        min: this.initVideoOutputMessage.videoProfile.frameRateRange.min,
        max: this.initVideoOutputMessage.videoProfile.frameRateRange.max
      }
    };
    HiLog.i(TAG, `checkHDRAndRemedyMessage end videoMessage: ${JSON.stringify(videoMessage)}.`);
  }

  // AVRecorder prepareAccurately: null/idle/prepared/stopped -> prepared
  public async prepareAccurately(message: VideoOutputMessage, pickerInfo?: PickerInfo): Promise<void> {
    this.checkHDRAndRemedyMessage(message, this.initTagMessage);
    HiLog.i(TAG, `prepareAccurately begin, state: ${this.recorder?.state}.`);
    await this.create();
    HiLog.i(TAG, `add video watermark ${message.isAddWaterMark} config rotation is:${message.config.rotation}`);
    // config不一致时或前后是否配置音频不同会先reset，重新prepare, 持录像中不断流的产品, 不能reset
    if (!(message.keepVideoFlowing && message.isFlowingVideo) && (!this.recorderProfile ||
      !this.isSameObject(message.config.profile, this.recorderProfile) ||
      message.config.location !== LOCATION_MESSAGE.location || this.lastLocationType !== LOCATION_MESSAGE.type ||
      (this.recorderAudioSourceType !== message.config.audioSourceType) ||
      this.isAddWatermark !== message.isAddWaterMark)) {
      HiLog.i(TAG, 'config different from last recorder config, reset recorder and prepare again.');
      message.config.location = LOCATION_MESSAGE.location;
      this.lastLocationType = LOCATION_MESSAGE.type;
      if (this.recorder.state !== 'idle' && this.recorder.state !== 'stopped') {
        await this.reset();
      }
      await this.prepare(message.config, message.isSupportVideoEdit, message.isAddFilter,
        message.isSupportVideoWatermark, message.isAddWaterMark, message.isFlowingVideo, message?.isInSwipeRecording,
        pickerInfo);
      HiLog.i(TAG, `prepareAccurately end, state: ${this.recorder.state}.`);
      return;
    }
    HiLog.i(TAG, 'Config same to last recorder config.');
    if (this.recorder.state === 'idle' || this.recorder.state === 'stopped') {
      // AVRecorder prepare。
      await this.prepare(message.config, message.isSupportVideoEdit, message.isAddFilter,
        message.isSupportVideoWatermark, message.isAddWaterMark, message.isFlowingVideo, message?.isInSwipeRecording,
        pickerInfo);
      return;
    }
    if (this.recorder.state === 'prepared') {
      // 已经prepare过，提供快速接口重置rotate参数。
      HiLog.i(TAG, 'AVRecorder prepared. Reset orientationHint.');
      try {
        HiLog.begin(TAG, 'SetOrientationHint');
        // @ts-ignore
        await this.recorder.SetOrientationHint(message.config);
        HiLog.end(TAG, 'SetOrientationHint');
      } catch (err) {
        HiLog.e(TAG, `SetOrientationHint config err. ${JSON.stringify(err)}`);
      }
    }
    HiLog.i(TAG, `prepareAccurately end, state: ${this.recorder.state}.`);
  }

  public async resetToUnprepared(): Promise<void> {
    HiLog.i(TAG, `resetToUnprepared begin, state: ${this.recorder?.state}.`);
    await this.create();
    if (this.recorder.state !== 'idle' && this.recorder.state !== 'stopped') {
      await this.reset();
    }
    await this.fileManager.deleteVideoFile(this.fileManager.getUri());
    HiLog.i(TAG, `resetToUnprepared end, state: ${this.recorder.state}.`);
  }

  private async prepare(config: media.AVRecorderConfig, isSupportVideoEdit: boolean,
    isAddFilter: boolean, isSupportVideoWatermark: boolean, isAddWaterMark: boolean, isFlowingVideo: boolean,
    isInSwipeRecording?: boolean, pickerInfo?: PickerInfo): Promise<void> {
    if (this.recorder.state !== 'idle' && this.recorder.state !== 'stopped') {
      HiLog.w(TAG, `AVRecorder has been prepared, state is ${this.recorder.state}.`);
      return;
    }
    this.isNeedRelease = false;
    HiLog.i(TAG, `prepare begin, config rotation: ${config.rotation}, profile: ${simpleStringify(config.profile)}.`);
    await this.fileManager.initFile(pickerInfo);
    const uri: string = this.fileManager.getUri();
    if (!uri) {
      HiLog.e(TAG, 'prepare error, surfaceId: undefined.');
      this.surfaceId = undefined;
      return;
    }
    workerCallback.videoUri(uri);
    config.url = `fd://${this.fileManager.getAssetId().toString()}`;
    //videoResolution:1代表选中4K，frameRate:60代表选中60fps，isDynamicFrameRate:2或3代表打开动态帧率
    if (this.initTagMessage && this.initTagMessage.videoResolution === 1 && this.initTagMessage.frameRate === 60
      && (this.initTagMessage.isDynamicFrameRate === 2 || this.initTagMessage.isDynamicFrameRate === 3)) {
      this.deferredVideoEnhanceFlag = '1';
    } else {
      this.deferredVideoEnhanceFlag = '0';
    }
    config.metadata = {
      ...config.metadata,
      customInfo: {
        'com.openharmony.isWaterMark': isAddWaterMark ? 'true' : 'false',
        'com.openharmony.deferredVideoEnhanceFlag': this.deferredVideoEnhanceFlag,
      }
    };
    try {
      HiLog.begin(TAG, 'prepare');
      await this.recorder.prepare(config);
      HiLog.end(TAG, 'prepare');
    } catch (err) {
      HiLog.e(TAG, `prepare err. ${err?.code}`);
    }
    this.recorderProfile = config.profile;
    this.isAddWatermark = isAddWaterMark;
    this.recorderAudioSourceType = config.audioSourceType;
    let surfaceIdOrigin: string = await this.recorder.getInputSurface();
    if (isAddFilter || isFlowingVideo ||
      await this.isAddSoftwareVideoWaterMark(isSupportVideoWatermark, isInSwipeRecording)) {
      this.isNeedRelease = true;
    } else {
      this.surfaceId = surfaceIdOrigin;
    }
    HiLog.i(TAG, `videoOutput: from ${surfaceIdOrigin}. get ${this.surfaceId}`);
  }

  private async isAddSoftwareVideoWaterMark(isSupportVideoWatermark: boolean,
    isInSwipeRecording?: boolean): Promise<boolean> {
    if (!await this.recorder.isWatermarkSupported() && isSupportVideoWatermark && !isInSwipeRecording) {
      this.isSoftwareVideoWaterMarkInSwipeRecording = isInSwipeRecording;
      return true; // 长按右滑录像时返回false
    }
    // add hardware watermark
    return false;
  }

  private async reset(): Promise<void> {
    HiLog.i(TAG, `AVRecorder state: ${this.recorder.state}, reset to idle.`);
    HiLog.begin(TAG, 'ResetRecorder');
    await this.recorder.reset();
    HiLog.end(TAG, 'ResetRecorder');
  }

  public async getInputMetaSurface(videoMetaType: number): Promise<string> {
    HiLog.i(TAG, 'getInputMetaSurface');
    let surface = '';
    try {
      surface = await this.recorder.getInputMetaSurface(videoMetaType);
    } catch (err) {
      HiLog.i(TAG, `getInputMetaSurface err: ${err?.code}`);
    }
    return surface;
  }

  public async start(): Promise<boolean> {
    HiLog.i(TAG, 'AVRecorder will start');
    this.isStopping = false;
    try {
      await this.recorder.start();
      HiLog.i(TAG, 'AVRecorder start success');
      return true;
    } catch (e) {
      HiLog.e(TAG, `AVRecorder start error: ${JSON.stringify(e)}.`);
      this.dealRecordError();
      return false;
    }
  }

  // AVRecorder pause
  public async pause(): Promise<void> {
    try {
      HiLog.i(TAG, 'AVRecorder will pause.');
      await this.recorder.pause();
      HiLog.i(TAG, 'AVRecorder pause success');
    } catch (e) {
      HiLog.e(TAG, `AVRecorder start error: ${JSON.stringify(e)}.`);
    }
  }

  // AVRecorder updateRotation
  public async updateRotation(rotation: number): Promise<void> {
    try {
      HiLog.i(TAG, 'AVRecorder will resume');
      await this.recorder.updateRotation(rotation);
      HiLog.i(TAG, 'AVRecorder resume success');
    } catch (e) {
      HiLog.e(TAG, `AVRecorder resume error: ${JSON.stringify(e)}.`);
      this.dealRecordError();
    }
  }

  // AVRecorder update
  public async resume(): Promise<void> {
    try {
      HiLog.i(TAG, 'AVRecorder will resume');
      await this.recorder.resume();
      HiLog.i(TAG, 'AVRecorder resume success');
    } catch (e) {
      HiLog.e(TAG, `AVRecorder resume error: ${JSON.stringify(e)}.`);
    }
  }

  // AVRecorder stop
  public async stop(): Promise<void> {
    if (!this.recorder ||
      (this.recorder.state !== 'started' && this.recorder.state !== 'paused' && this.recorder.state !== 'error') ||
    this.isStopping) {
      HiLog.w(TAG, `stop return, recorderState: ${this.recorder?.state}.`);
      return;
    }
    HiLog.i(TAG, `AVRecorder state: ${this.recorder.state}, will stop.`);
    let cameraShotKey: string = GlobalContext.get().getCameraShotKey();
    this.isStopping = true;
    try {
      await this.recorder.stop();
      HiLog.i(TAG, 'AVRecorder stop success.');
    } catch (err) {
      HiLog.e(TAG, `AVRecorder stop err:${err}`);
    }
    await this.fileManager.closeFile(cameraShotKey);
    this.isStopping = false;
    HiLog.i(TAG, `stop AVRecorder done. AVRecorder state: ${this.recorder.state}.`);
  }

  // AVRecorder release
  public async release(getModeIsSupportedRealTimeFilterFunction?: boolean): Promise<void> {
    if (!this.recorder || this.recorder.state === 'released') {
      HiLog.w(TAG, 'AVRecorder has been released.');
      return;
    }
    HiLog.begin(TAG, 'AVRecorderRelease');
    // 删除prepare创建，但未使用的录像文件
    if (this.recorder.state === 'prepared') {
      HiLog.i(TAG, 'deleteVideoAsset videoOutput file.');
      this.fileManager.deleteVideoFile(this.fileManager.getUri());
      this.fileManager.closePrepareFile();
    }
    WorkerDataCache.getInstance().setValidateThumbnail(true);
    await this.stop();
    // AVRecorder release
    HiLog.i(TAG, 'release releaseSurface');
    if (this.surfaceId !== undefined && this.surfaceId !== null &&
      (getModeIsSupportedRealTimeFilterFunction || this.isNeedRelease)) {
      HiLog.i(TAG, 'release releaseSurface');
    }
    await this.recorder.release();
    HiLog.i(TAG, `release AVRecorder done. AVRecorder state: ${this.recorder.state}.`);
    this.recorder.off('stateChange');
    this.recorder.off('error');
    this.surfaceId = '';
    HiLog.end(TAG, 'AVRecorderRelease');
  }

  private async dealRecordError(): Promise<void> {
    HiLog.i(TAG, 'dealRecordError invoke.');
    if (DeviceInfo.isPc()) {
      return;
    }
    this.fileManager.deleteVideoFile(this.fileManager.getUri());
  }

  public getSurfaceId(): string {
    HiLog.i(TAG, `getSurface: ${this.surfaceId}.`);
    return this.surfaceId;
  }

  public async releaseSurfaceWhenStopRecorderRecording(): Promise<void> {
    HiLog.i(TAG, `releaseSwipeSurface ${this.surfaceId}, ${this.isSoftwareVideoWaterMarkInSwipeRecording}`);
    if (!this.isSoftwareVideoWaterMarkInSwipeRecording) {
      return; // 不支持硬编的产品连拍录像结束时, 需要释放surface, 否则不需要
    }
  }

  private isSameObject(lastObj: Object, targetObj: Object): boolean {
    for (const key of Object.keys(targetObj)) {
      const lastValue = lastObj[key];
      const targetValue = targetObj[key];
      if (lastObj[key] !== targetObj[key]) {
        HiLog.i(TAG, `isSameObject different key: ${key}, lastValue: ${lastValue}, targetValue: ${targetValue}.`);
        return false;
      }
    }
    HiLog.i(TAG, 'isSameObject: ture.');
    return true;
  }

  public async changeFileShotKey(): Promise<void> {
    HiLog.i(TAG, 'changeFileShotKey invoke.');
    this.fileManager.changeFileShotKey();
  }

  public async deletePickerVideoFile(): Promise<void> {
    this.fileManager.deletePickerVideoFile();
  }

  public resetVideoFileManagerUri(): void {
    this.fileManager.resetUri();
  }

  public getIsRecording(): boolean {
    return this.recorderState === 'started' || this.recorderState === 'paused';
  }
}

class VideoFileManager {
  // 录像文件：文件与AVRecorder绑定，由AVRecorder缓存，媒体库服务和VideoOutput不缓存录像文件信息
  private mAssetId: number = 0;
  private mPrepareFile: photoAccessHelper.PhotoAsset;
  private mPreparePickerFile: fs.File;
  private mUri: string = '';
  // 流程控制
  private mInitialized: boolean = false;
  private pickerInfo?: PickerInfo;
  private cameraShotKey: string = '';

  public constructor() {
  }

  public async initFile(pickerInfo?: PickerInfo): Promise<void> {
    this.pickerInfo = pickerInfo;
    if (this.mInitialized && this.mUri !== '') {
      HiLog.w(TAG, 'initFile, video file is initialized.');
      return;
    }
    this.mInitialized = true;
    HiLog.begin(TAG, 'initFile');
    try {
      if (pickerInfo?.uri) {
        this.mUri = pickerInfo?.uri;
        this.mPreparePickerFile = await fs.open(pickerInfo?.uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        this.mAssetId = this.mPreparePickerFile.fd;
      } else {
        const mediaLibrary = await modulesManager.getMediaLibrary();
        this.cameraShotKey = GlobalContext.get().getCameraShotKey();
        this.mPrepareFile = await mediaLibrary.createVideoFile();
        if (!this.mPrepareFile) {
          HiLog.e(TAG, 'createVideoFile mediaLibrary createAsset error: photoAsset undefined.');
          return;
        }
        if (this.cameraShotKey !== GlobalContext.get().getCameraShotKey()) {
          // 兜底，创建文件的过程中cameraShotKey更新，则在文件创建完成之后将新的cameraShotKey更新到文件中
          HiLog.i(TAG, `changeCameraShotKey old: ${this.cameraShotKey}.`);
          this.cameraShotKey = GlobalContext.get().getCameraShotKey();
          HiLog.i(TAG, `changeCameraShotKey new: ${this.cameraShotKey}.`);
          this.changeFileShotKey();
        }
        this.mUri = this.mPrepareFile.uri;
        this.mAssetId = await this.mPrepareFile.open('rw');
      }
      HiLog.i(TAG, `VideoOutput init videoFileUri: ${this.mUri}.`);
    } catch (err) {
      HiLog.e(TAG, `create VideoFd err: ${JSON.stringify(err)}.`);
    } finally {
      HiLog.end(TAG, 'initFile');
    }
  }

  public async changeFileShotKey(): Promise<void> {
    try {
      if (this.mPrepareFile) {
        HiLog.i(TAG, `changeFileShotKey mPrepareFile: ${this.mPrepareFile.uri},
        cameraShotKey: ${GlobalContext.get().getCameraShotKey()}.`);
        const mediaLibrary = await modulesManager.getMediaLibrary();
        await mediaLibrary.setCameraShotKey(this.mPrepareFile);
        HiLog.i(TAG, 'changeFileShotKey commitModify done.');
      } else {
        // 文件未创建|文件还在创建中，此时cameraShotKey更新
        HiLog.i(TAG, 'file is not created.');
      }
    } catch (err) {
      HiLog.e(TAG, `changeFileShotKey err: ${JSON.stringify(err)}.`);
    }
  }

  public async closeFile(cameraShotKey: string): Promise<void> {
    if (!this.mAssetId) {
      HiLog.e(TAG, 'AssetId is undefined, close file error.');
      return;
    }
    this.mInitialized = false;
    HiLog.begin(TAG, 'closeFile');
    try {
      if (this.pickerInfo?.uri) {
        fs.close(this.mPreparePickerFile);
        HiLog.i(TAG, 'picker close done.');
        return;
      } else {
        await this.mPrepareFile.close(this.mAssetId);
        HiLog.i(TAG, 'close done.');
      }
      const mediaLibrary = await modulesManager.getMediaLibrary();
      HiLog.i(TAG, 'closeFile videoFile get mediaLibrary end');
      const isSaveFile: boolean = await mediaLibrary.shouldSaveFile(this.mPrepareFile.uri, cameraShotKey);
      HiLog.i(TAG, `closeFile videoFile isSaveFile: ${isSaveFile}.`);
      if (!isSaveFile) {
        await mediaLibrary.deleteVideoAsset(this.mUri);
        HiLog.i(TAG, 'closeFile videoFile should not be saved.');
        return;
      }

      // 重命名最后生成的视频文件
      HiLog.i(TAG, 'closeFile videoFile rename begin.');
      const uri: string = await mediaLibrary.renameVideoFile(this.mUri, cameraShotKey);
      HiLog.i(TAG, `closeFile video rename uri: ${uri}.`);
      workerCallback.videoUri(uri); // rename video之后触发全局state更新，保证其他场景使用数据正确
    } catch (error) {
      HiLog.e(TAG, `closeFile fail error: ${error?.code}.`);
    } finally {
      HiLog.end(TAG, 'closeFile');
      this.clear(this.mUri);
    }
  }

  public async closePrepareFile(): Promise<void> {
    if (!this.mAssetId || !this.mPrepareFile) {
      HiLog.e(TAG, 'AssetId or PrepareFile is undefined, close file error.');
      return;
    }
    HiLog.begin(TAG, 'closePrepareFile');
    try {
      await this.mPrepareFile.close(this.mAssetId);
      HiLog.i(TAG, 'close done.');
    } catch (error) {
      HiLog.e(TAG, `closePrepareFile fail error: ${error?.code}.`);
    }
    HiLog.end(TAG, 'closePrepareFile');
  }

  public async deletePickerVideoFile(): Promise<void> {
    HiLog.begin(TAG, `delete picker video file`);
    HiLog.i(TAG, `pickerInfo Uri: ${this.pickerInfo?.uri} mUri: ${this.mUri}`);
    if (this.pickerInfo.uri) {
      try {
        const file = await fs.open(this.pickerInfo.uri, fs.OpenMode.READ_WRITE);
        await fs.write(file.fd, '');
        await fs.close(file);
        HiLog.i(TAG, 'clear file by pickerInfo.uri done');
      } catch (err) {
        HiLog.e(TAG, `clear file by pickerInfo.uri error: ${err?.code}.`);
      }
    } else {
      await this.deleteVideoFile(this.mUri);
      HiLog.i(TAG, 'delete file by mUri done');
    }
    HiLog.end(TAG, `delete picker video file`);
  }

  public async deleteVideoFile(deleteUri: string): Promise<void> {
    this.mInitialized = false;
    if (deleteUri === '') {
      HiLog.e(TAG, 'deleteUri is null, deleteVideoFile error.');
      return;
    }
    HiLog.begin(TAG, 'deleteVideoAsset');
    const mediaLibrary = await modulesManager.getMediaLibrary();
    await mediaLibrary.deleteVideoAsset(deleteUri);
    this.clear(deleteUri);
    HiLog.end(TAG, 'deleteVideoAsset');
  }

  private clear(deleteUri: string): void {
    HiLog.i(TAG, 'clear video file.');
    if (deleteUri !== this.mUri) {
      HiLog.w(TAG, 'delete uri is not equals muri, do not clear');
      return;
    }
    if (!this.pickerInfo?.isPicker) {
      this.mUri = '';
    }
    this.mAssetId = 0;
    this.mPrepareFile = undefined;
    this.mPreparePickerFile = undefined;
  }

  public getUri(): string {
    if (this.mUri === '') {
      HiLog.e(TAG, 'getUri error, uri is not assigned a value.');
    } else {
      HiLog.i(TAG, `uri: ${this.mUri}.`);
    }
    return this.mUri;
  }

  public getAssetId(): number {
    if (this.mAssetId === 0) {
      HiLog.e(TAG, 'getAssetId error, AssetId is not assigned a value.');
    } else {
      HiLog.i(TAG, `AssetId: ${this.mAssetId}.`);
    }
    return this.mAssetId;
  }

  public resetUri(): void {
    this.mUri = '';
  }
}