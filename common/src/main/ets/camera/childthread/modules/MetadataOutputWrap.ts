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

import lazy { HiLog } from '../../../utils/HiLog';
import CameraOutput from './CameraOutput';
import camera from '@ohos.multimedia.camera';
import type CameraContext from './CameraContext';
import type CameraDeviceManager from './CameraDeviceManager';
import lazy { ModeType } from '../../../mode/ModeType';
import lazy { OutputType } from '../../../function/outputswitcher/OutputType';
import lazy { OutputOperation } from '../../../function/outputswitcher/OutputOperation';
import lazy { workerCallback } from '../WorkerCallback';
import lazy { simpleStringify } from '../../../utils/SimpleStringify';
import lazy { FocusTrackingMetaInfo } from './video/MovieFileOutputCinemaWrap';

const UPDATE_PRECISION: number = 0.002;
const UPDATE_PRECISION_EYE: number = 0.0015;
const UPDATE_PRECISION_EYES_CHANGE: number = 0.04;
const THREE_DISAPPEAR_TIME: number = 3000;
const FRAME_STAB_TIME: number = 70;
const EYES_DISAPPEAR_MIN_NUM: number = 3;

/* instrument ignore file */
const TAG: string = 'MetadataOutputWrap';

// MetadataOutput包装类
export default class MetadataOutputWrap extends CameraOutput {
  private mMetadataOutput!: camera.MetadataOutput;
  private mCurrentMode: ModeType;
  private mIsPanVideoBackPosition: boolean;
  private mLastFaceMetadataArr: camera.Rect[] = [];
  // 显示期间永远保存上一帧上报data
  private mLastEyeMetadataArr: camera.Rect[] = [];
  private mFaceMetadataArr: camera.Rect[] = [];
  private mHumanFaceMetadataArr: camera.MetadataObject[] = [];
  private mFaceTimestamp: number = 0;
  private mEyeFocus: camera.Rect[] = [];
  private isOperationEmotion: boolean = false;
  private isSwingSubscribed: boolean = false;
  private disappearTimerId: number = Number.MIN_VALUE;
  // 除人像模式外其它模式3s消失规格定时器
  private isExecThreeSecondsDisappear: boolean = false;
  // 执行3s消失策略后不再绘制标志位

  private mLastTimestamp: number = 0;
  private frameStabTimerId: number = Number.MIN_VALUE;
  // 检测失败、暗光、降帧场景,应用稳帧策略定时器
  private eyesDisappearNum: number = 0;
  private mIsFrontPosition: boolean = false;
  private mIsVideoOutPut: boolean = false;
  private mCurrentZoomRatio: number = 1;
  private mIsSupportOnlyShowEye: boolean = false;
  private isCinemaEmpty: boolean = false;

  constructor(cameraDeviceManager: CameraDeviceManager, cameraContext: CameraContext) {
    super(cameraDeviceManager, cameraContext);
  }

  public init(cameraManager: camera.CameraManager, metadataObjectTypeArr: camera.MetadataObjectType[], mode:
    ModeType, outputType: OutputType, position: camera.CameraPosition, supportOnlyShowEye: boolean): Promise<void> {
    if (!cameraManager) {
      HiLog.e(TAG, 'createPhotoOutput cameraManager is null.');
      return;
    }
    let metadataObjectType: camera.MetadataObjectType[] = metadataObjectTypeArr;
    this.mMetadataOutput = cameraManager.createMetadataOutput(metadataObjectType);
    this.mCurrentMode = mode;
    this.metadataOutputOn();
    this.mIsPanVideoBackPosition =
      OutputOperation.isPanVideoOutput(mode, outputType) && position === camera.CameraPosition.CAMERA_POSITION_BACK;
    this.mIsFrontPosition = position === camera.CameraPosition.CAMERA_POSITION_FRONT;
    this.mIsVideoOutPut = OutputOperation.isPanVideoOutput(mode, outputType);
    this.mIsSupportOnlyShowEye = supportOnlyShowEye;
  }

  public async start(): Promise<void> {
    await this.mMetadataOutput.start();
  }

  public async stop(): Promise<void> {
    await this.mMetadataOutput.stop();
  }

  public metadataOutputOn(): void {
    this.mMetadataOutput.on('metadataObjectsAvailable',
      (err, metadataObject: camera.MetadataObject[]) => this.metadataObjCallback(err, metadataObject));
  }

  private focusTrackingMetaInfoAvailableCallback(err, info: FocusTrackingMetaInfo): void {
    if (err) {
      HiLog.e(TAG, `handleCinemaTracking focusTrackingInfoAvailable, err: ${err}.`);
      return;
    }
    const isEmpty = info.detectedObjects.length === 0 && (!info.trackingRegion?.width || !info.trackingRegion?.height);
    if (isEmpty && this.isCinemaEmpty) {
      HiLog.i(TAG, `MOVIE_TRACKING focusTrackingMetaInfoAvailable isEmpty, info: ${simpleStringify(info)}.`);
      return;
    }
    this.isCinemaEmpty = isEmpty;
    HiLog.i(TAG, `MOVIE_TRACKING focusTrackingMetaInfoAvailable FocusTrackingMetaInfo: ${simpleStringify(info)}.`);
    workerCallback.updateFocusTrackingInfo(info);
  }

  private metadataObjCallback(err, metadataObjectArr: camera.MetadataObject[]): void {
    if (err) {
      HiLog.e(TAG, `on metadataOutput err: ${err?.code}.`);
      return;
    }
    let scanCodeMetadataArr: camera.MetadataObject[] = [];
    this.mFaceMetadataArr = [];
    this.mHumanFaceMetadataArr = [];
    this.mFaceTimestamp = 0;
    this.mEyeFocus = [];
    metadataObjectArr.forEach((cameraMetadataObj: camera.MetadataObject, index) => {
      if (cameraMetadataObj.type === camera.MetadataObjectType.BAR_CODE_DETECTION) {
        scanCodeMetadataArr.push(cameraMetadataObj);
      } else if (cameraMetadataObj.type === camera.MetadataObjectType.FACE_DETECTION ||
        cameraMetadataObj.type === camera.MetadataObjectType.CAT_FACE ||
        cameraMetadataObj.type === camera.MetadataObjectType.DOG_FACE) {
        if (cameraMetadataObj.type === camera.MetadataObjectType.FACE_DETECTION) {
          this.mHumanFaceMetadataArr.push(cameraMetadataObj);
        }
        this.mFaceMetadataArr.push(cameraMetadataObj.boundingBox);
        this.mFaceTimestamp = cameraMetadataObj.timestamp;
        // @ts-ignore
        if (cameraMetadataObj.leftEyeBoundingBox && cameraMetadataObj.leftEyeBoundingBox.width > 0) {
          // @ts-ignore
          this.mEyeFocus.push(cameraMetadataObj.leftEyeBoundingBox);
        }
        this.metadataEmotionCallback(cameraMetadataObj);
      }
    });
    this.metadataUpdateTactics();
  }

  private metadataEmotionCallback(cameraMetadataObj: camera.MetadataObject): void {
    try {
      // @ts-ignore
      if (cameraMetadataObj.emotion === camera.Emotion.SMILE && this.isOperationEmotion) {
        workerCallback.faceMetadataSimle(true);
      }
    } catch (e) {
      HiLog.i(TAG, `metadataOutput face motion error = ${e.code}`);
    }
  }

  private metadataUpdateTactics(): void {
    let ret: number = 0;
    if (!this.mIsPanVideoBackPosition) { // 人像模式、后置泛录像模式持续更新显示
      // 左右眼数据均在leftEye中提供，无法判断左右眼切换情况，现只能通过眼框的位移情况判断是否切换
      let isEyeChanged: boolean = this.getIsEyeNeedUpdate(this.mEyeFocus, UPDATE_PRECISION_EYES_CHANGE);
      if (this.isExecThreeSecondsDisappear && this.mFaceMetadataArr.length === this.mLastFaceMetadataArr.length) {
        this.mLastFaceMetadataArr = this.mFaceMetadataArr;
        this.mLastTimestamp = this.mFaceTimestamp;
        ret++; // 3s消失策略已经生效后不再绘制检测框
      }
      if (this.isExecThreeSecondsDisappear && !isEyeChanged) {
        this.mLastTimestamp = this.mFaceTimestamp;
        this.mLastEyeMetadataArr = this.mEyeFocus;
        ret++;
      }
      if (this.mFaceMetadataArr.length !== this.mLastFaceMetadataArr.length || isEyeChanged) {
        this.clearAndSetDisappearTimeout();
      }
      if (ret === 2) { // 如果脸和眼均无需重新绘制则返回
        return;
      }
    }
    if (this.mLastFaceMetadataArr.length === this.mFaceMetadataArr.length) {
      let isNeedUpdate: boolean = this.getIsFaceNeedUpdate(this.mFaceMetadataArr);
      let isEyeNeedUpdate: boolean = this.getIsEyeNeedUpdate(this.mEyeFocus, UPDATE_PRECISION_EYE);
      if (!isNeedUpdate && !isEyeNeedUpdate) {
        this.mLastFaceMetadataArr = this.mFaceMetadataArr;
        this.mLastEyeMetadataArr = this.mEyeFocus;
        this.mLastTimestamp = this.mFaceTimestamp;
        if (this.eyesDisappearNum === 0) {
          return;
        }
      }
    } else {
      if (this.mFaceMetadataArr.length < 1 && this.mFaceTimestamp - this.mLastTimestamp > 200) {
        HiLog.i(TAG, `mFaceTimestamp - this.mLastTimestamp: ${this.mFaceTimestamp - this.mLastTimestamp}.`);
        this.clearAndSetFrameStabTimeout();
        this.mLastFaceMetadataArr = [];
        this.mLastEyeMetadataArr = [];
        this.mLastTimestamp = 0;
        return;
      }
    }
    this.workerCallbackFunc();
    this.mLastFaceMetadataArr = this.mFaceMetadataArr;
    this.mLastEyeMetadataArr = this.mEyeFocus;
  }

  private workerCallbackFunc(): void {
    if (this.isOnlyShowEye()) {
      this.showOrHideEye();
    } else {
      this.eyesDisappearNum = 0;
      if (this.mFaceMetadataArr.length === 1 && this.mEyeFocus.length === 1) {
        workerCallback.eyeMetadata(this.mEyeFocus);
        workerCallback.faceMetadataArr([]);
      } else {
        workerCallback.faceMetadataArr(this.mFaceMetadataArr);
        workerCallback.eyeMetadata([]);
      }
    }
    if (this.isSwingSubscribed) {
      workerCallback.smartBackSelfieFaceMetadataArr(this.mHumanFaceMetadataArr);
    }
  }

  private isOnlyShowEye(): boolean {
    // M,M+产品在拍照前置2.2x 和 录像2.4x以上一个人脸的情况下只显示人眼。
    return this.mIsFrontPosition && this.mIsSupportOnlyShowEye && this.mFaceMetadataArr.length === 1 &&
      ((this.mIsVideoOutPut && this.mCurrentZoomRatio > 2.4) || (!this.mIsVideoOutPut && this.mCurrentZoomRatio > 2.2));
  }

  private showOrHideEye(): void {
    if (this.mEyeFocus.length === 1) {
      this.eyesDisappearNum = 0;
      workerCallback.eyeMetadata(this.mEyeFocus);
      workerCallback.faceMetadataArr([]);
    } else if (this.mEyeFocus.length === 0 && this.eyesDisappearNum >= EYES_DISAPPEAR_MIN_NUM) {
      this.eyesDisappearNum = 0;
      workerCallback.eyeMetadata([]);
      workerCallback.faceMetadataArr([]);
    } else {
      this.eyesDisappearNum++;
    }
  }

  private getIsFaceNeedUpdate(mFaceMetadataArr: camera.Rect[]): boolean {
    let isNeedUpdate: boolean = false;
    for (let i = 0; i < mFaceMetadataArr.length; i++) {
      let isTopLeftXChange =
        Math.abs(mFaceMetadataArr[i].topLeftX - this.mLastFaceMetadataArr[i].topLeftX) >= UPDATE_PRECISION;
      let isTopLeftYChange =
        Math.abs(mFaceMetadataArr[i].topLeftY - this.mLastFaceMetadataArr[i].topLeftY) >= UPDATE_PRECISION;
      let isWidthChange = Math.abs(mFaceMetadataArr[i].width - this.mLastFaceMetadataArr[i].width) >= UPDATE_PRECISION;
      let isHeightChange =
        Math.abs(mFaceMetadataArr[i].height - this.mLastFaceMetadataArr[i].height) >= UPDATE_PRECISION;
      if (isTopLeftXChange || isTopLeftYChange || isWidthChange || isHeightChange) {
        isNeedUpdate = true;
        break;
      }
    }
    return isNeedUpdate;
  }

  private getIsEyeNeedUpdate(mEyeMetadataArr: camera.Rect[], updatePrecision: number): boolean {
    if (this.mLastEyeMetadataArr.length !== this.mEyeFocus.length) {
      return true;
    }
    let isNeedUpdate: boolean = false;
    for (let i = 0; i < mEyeMetadataArr.length; i++) {
      let isTopLeftXChange =
        Math.abs(mEyeMetadataArr[i].topLeftX - this.mLastEyeMetadataArr[i].topLeftX) >= updatePrecision;
      let isTopLeftYChange =
        Math.abs(mEyeMetadataArr[i].topLeftY - this.mLastEyeMetadataArr[i].topLeftY) >= updatePrecision;
      let isWidthChange = Math.abs(mEyeMetadataArr[i].width - this.mLastEyeMetadataArr[i].width) >= updatePrecision;
      let isHeightChange =
        Math.abs(mEyeMetadataArr[i].height - this.mLastEyeMetadataArr[i].height) >= updatePrecision;
      if (isTopLeftXChange || isTopLeftYChange || isWidthChange || isHeightChange) {
        isNeedUpdate = true;
        break;
      }
    }
    return isNeedUpdate;
  }

  public async release(): Promise<void> {
    try {
      if (this.mMetadataOutput) {
        this.mMetadataOutput.off('metadataObjectsAvailable');
        await this.mMetadataOutput.release();
        this.mMetadataOutput = null;
      }
    } catch (e) {
      HiLog.i(TAG, `MetadataOutput release error: ${JSON.stringify(e)}.`);
    }
  }

  public getOutput(): camera.MetadataOutput {
    return this.mMetadataOutput;
  }

  public setOutput(photoOutput: camera.MetadataOutput): void {
    this.mMetadataOutput = photoOutput;
  }

  private clearAndSetDisappearTimeout(): void {
    this.isExecThreeSecondsDisappear = false;
    if (this.disappearTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.disappearTimerId);
      this.disappearTimerId = Number.MIN_VALUE;
    }
    this.disappearTimerId = setTimeout((): void => {
      HiLog.i(TAG, `exec isExecThreeSecondsDisappear: ${this.isExecThreeSecondsDisappear} -> true, data: [].`);
      workerCallback.faceMetadataArr([]);
      workerCallback.eyeMetadata([]);
      this.isExecThreeSecondsDisappear = true;
    }, THREE_DISAPPEAR_TIME);
  }

  private clearAndSetFrameStabTimeout(): void {
    if (this.frameStabTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.frameStabTimerId);
      this.frameStabTimerId = Number.MIN_VALUE;
    }
    this.frameStabTimerId = setTimeout((): void => {
      if (this.mLastFaceMetadataArr.length < 1 || this.mLastEyeMetadataArr.length === 1) {
        workerCallback.faceMetadataArr([]);
      }
      if (this.mLastFaceMetadataArr.length >= 2 || this.mLastEyeMetadataArr.length > 1) {
        workerCallback.eyeMetadata([]);
      }
    }, FRAME_STAB_TIME);
  }

  public setOperationEmotion(isEmotion: boolean): void {
    this.isOperationEmotion = isEmotion;
  }

  public setSwingSubscribeStatus(isSubscribe: boolean): void {
    this.isSwingSubscribed = isSubscribe;
  }

  public setZoomRatio(zoomRatio: number): void {
    this.mCurrentZoomRatio = zoomRatio;
  }
}