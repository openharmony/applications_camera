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

import lazy { HiLog } from '../../../../utils/HiLog';
import camera from '@ohos.multimedia.camera';
import type PhotoOutputWrap from '../PhotoOutputWrap';
import type PreviewOutputWrap from '../PreviewOutputWrap';
import type MetadataOutputWrap from '../MetadataOutputWrap';
import type CameraInputWrap from '../CameraInputWrap';
import type CameraContext from '../CameraContext';
import lazy { App2CameraModeMessage, LightStatus, TagMessage } from '../../../DataType';
import lazy { ModeType } from '../../../../mode/ModeType';
import lazy { DeviceInfo } from '../../../../component/deviceinfo/DeviceInfo';
import colorSpaceManager from '@ohos.graphics.colorSpaceManager';
import lazy { BaseSession } from './BaseSession';
import lazy { OutputOperation } from '../../../../function/outputswitcher/OutputOperation';
import lazy { AsyncCallback, ErrorCallback } from '@ohos.base';
import lazy { ZoomPointInfo } from '../../../../function/zoombar/ZoomParam';
import lazy { workerCallback } from '../../WorkerCallback';
import lazy { simpleStringify } from '../../../../utils/SimpleStringify';
import lazy { TripodStatus } from '../../../../function/enumbase/TripodStatus';
import lazy { display, window } from '@kit.ArkUI';
import VideoModule from '../video/VideoModule';
import lazy { WorkerDataCache } from '../../WorkerDataCache';
import lazy { DisplayService } from '../../../../service/UIAdaptive/DisplayService';
import image from '@ohos.multimedia.image';
import lazy { LogStyleMode } from '../../../../function/enumbase/LogStyleMode';
import lazy { geoLocationManager } from '@kit.LocationKit';
import lazy { LOCATION_MESSAGE } from '../../CameraTaskHandler';
import lazy { OutputType } from '../../../../function/outputswitcher/OutputType';
import lazy { ExposureData } from '../../../../component/focusExposure/FocusExposureHelper';
import lazy { BusinessError } from '@kit.BasicServicesKit';
import lazy { audio } from '@kit.AudioKit';

/* instrument ignore file */
const TAG: string = 'SessionWrap';
const EXPOSURE_VALUE: number = 1000;
const TIME_LAPSE_MIN_INTERVAL: number = 500;
const SKIN_TONE_OFFSET: number = 5;
const TIME_OPEN = 200;

// Session包装类
export default class SessionWrap {
  // 全局变量
  private mCameraContext!: CameraContext;
  private mMode: ModeType = ModeType.NONE;
  // Session对象
  private mSession!: BaseSession;
  private timeLapseTimerId: number = Number.MIN_VALUE;
  // 输入输出
  private mMetadataOutput!: MetadataOutputWrap;
  private mPhotoOutput!: PhotoOutputWrap;
  private mCollaborateOutput?: PreviewOutputWrap;
  private mCollaborateControlOutput?: PreviewOutputWrap;
  private mPreviewOutput: PreviewOutputWrap;
  private mPreviewOutputForTimeLapse!: PreviewOutputWrap;
  private mPanoramaMaxPreviewOutput!: PreviewOutputWrap;
  private mPanoramaMinPreviewOutput!: PreviewOutputWrap;
  private mCameraInput: CameraInputWrap;

  private hasOtherOutput: boolean = false;
  // Session数据
  private mCanAddOutput: boolean = true;
  private mZoomRatioRange: number[] | undefined;
  private mHasFlash: boolean | undefined = true;
  private mIsMacroSupported: boolean = false;
  private mIsEffectSuggestionSupported: boolean = false;
  private mIsSceneFeatureSupported: boolean = false;
  private mZoomPointInfo: ZoomPointInfo | undefined;
  private mIsDeferPhoto: boolean = false;
  private mIsDeferVideo: boolean = false;
  private mIsCompositionSuggestionSupported: boolean = false;
  // 延时摄影状态
  private mTryAeInfo: camera.TryAEInfo | undefined;
  private mIsInTryAe: boolean = false;
  private mIsTimeLapseSpeedAuto: boolean = false;
  private mTimeLapseUserInterval: number = TIME_LAPSE_MIN_INTERVAL;
  private mTimeLapseHalInterval: number = TIME_LAPSE_MIN_INTERVAL;
  private mTimeLapseStopCapture: boolean = false;
  private prevLcdFlashStatus: boolean = false;
  private mIsColorStyleSupport: boolean = false;
  private isCollaborationPreviewOutputStop: boolean = false;
  private isoValue: number = 0;
  private proShutterEffectValue: number = 0;

  private mSmoothZoomInfoCallback: AsyncCallback<camera.SmoothZoomInfo> = (err, zoomInfo: camera.SmoothZoomInfo) => {
    if (err) {
      HiLog.e(TAG, `SmoothZoomInfo error: ${err?.code}.`);
      return;
    }
    HiLog.i(TAG, `smoothZoomInfoAvailable zoomInfo: ${zoomInfo.duration}.`);
  };
  private captureTimelapseFun: Function = () => {
    if (this.mPhotoOutput.isInCapture()) {
      HiLog.w(TAG, 'timeLapseVideo capture failed');
      return;
    }
    if (this.mTimeLapseStopCapture) {
      return;
    }
    HiLog.i(TAG, 'timeLapseCapture One');
    this.mPhotoOutput.capture({
      rotation: 0,
      quality: 1
    }, {
      downCapture: false,
      isBackCapture: this.mCameraContext.getCameraPosition() === camera.CameraPosition.CAMERA_POSITION_BACK,
    });
  };
  private mSceneFeatureCallBack: AsyncCallback<camera.TripodDetectionResult> =
    (err, detectionResult: camera.TripodDetectionResult) => {
      let result: camera.TripodDetectionResult = detectionResult;
      if (err) {
        HiLog.e(TAG, `SceneFeatureDetectionResult error: ${err?.code}.`);
        result = {
          featureType: -1,
          detected: false,
          tripodStatus: TripodStatus.INVALID
        };
      }
      HiLog.i(TAG,
        `mSceneFeatureCallBack detected: ${detectionResult.detected}, featureType:  ${detectionResult.featureType}, tripodStatus: ${detectionResult.tripodStatus}.`);
      workerCallback.onSceneFeatureDetectionResult(result);
    };
  private mIsoInfoCallback: AsyncCallback<camera.IsoInfo> = (err, IsoInfo: camera.IsoInfo) => {
    if (err) {
      HiLog.e(TAG, `IsoInfo error: ${err?.code}.`);
      return;
    }
    if (IsoInfo.iso !== this.isoValue) {
      this.isoValue = IsoInfo.iso;
      workerCallback.onUpdateIsoDuration(IsoInfo.iso);
    }
  };
  private mExposureInfoCallback: AsyncCallback<camera.ExposureInfo> = (err, exposureInfo: camera.ExposureInfo) => {
    if (err) {
      HiLog.e(TAG, `exposureInfo error: ${err?.code}.`);
      return;
    }
    // @ts-ignore
    if (exposureInfo.exposureTimeValue !== this.proShutterEffectValue) {
      // @ts-ignore
      this.proShutterEffectValue = exposureInfo.exposureTimeValue;
      // @ts-ignore
      workerCallback.onUpdateExposureDuration(exposureInfo.exposureTimeValue); // 实际上报exposureTimeValue,相机框架文档错误
    }
  };
  private mApertureInfoCallback: AsyncCallback<camera.ApertureInfo> = (err, apertureInfo: camera.ApertureInfo) => {
    if (err) {
      HiLog.e(TAG, `apertureInfo error: ${err?.code}.`);
      return;
    }
    HiLog.i(TAG, `apertureInfo success ApertureInfo: ${apertureInfo.aperture}.`);
    if (this.getSupportedPhysicalApertures().length !== 0) {
      workerCallback.onUpdatePhysicalApertureDuration(apertureInfo.aperture);
    }
  };
  private mLuminationCallback: AsyncCallback<camera.LuminationInfo> = (err, luminationInfo: camera.LuminationInfo) => {
    if (err) {
      HiLog.e(TAG, `luminationInfo error: ${err?.code}.`);
      return;
    }
    workerCallback.onUpdateExposureRecoveryFlag(luminationInfo.lumination);
  };
  private mTryAeCallback: AsyncCallback<camera.TryAEInfo> = (error, tryAeInfo: camera.TryAEInfo) => {
    if (error) {
      HiLog.e(TAG, `try ae callback error: ${error}.`);
      return;
    }
    if (!this.mIsInTryAe) {
      return;
    }

    this.mTryAeInfo = tryAeInfo;
    HiLog.i(TAG, `timeLapseVideo try ae done: ${this.mTryAeInfo.isTryAEDone}, needed: ${
    this.mTryAeInfo.isTryAEHintNeeded}, previewType: ${this.mTryAeInfo.previewType}, interval: ${
    this.mTryAeInfo.captureInterval}`);

    if (this.mTryAeInfo?.isTryAEHintNeeded) {
      // show hint
    }

    if (this.mTryAeInfo?.captureInterval) {
      HiLog.i(TAG,
        `timeLapseVideo interval by hal: ${this.mTryAeInfo?.captureInterval}, by user: ${this.mTimeLapseUserInterval}}`);
      this.mSession.setTimeLapseInterval(this.mTimeLapseUserInterval);
      if (this.mTryAeInfo?.captureInterval >= TIME_LAPSE_MIN_INTERVAL) {
        this.mTimeLapseHalInterval = this.mTryAeInfo?.captureInterval;
        HiLog.i(TAG, `update timeLapse HAL interval: ${this.mTimeLapseHalInterval}`);
      }
    }

    if (this.mTryAeInfo?.isTryAEDone) {
      HiLog.i(TAG, 'timeLapseVideo confirm try AE done');
      this.mIsInTryAe = false;
      this.mSession.stopTryAE();
      const finalInterval: number =
        this.mIsTimeLapseSpeedAuto ? this.mTimeLapseHalInterval : this.mTimeLapseUserInterval;
      HiLog.i(TAG, `timeLapseVideo final interval: ${finalInterval}, isSpeedAuto: ${this.mIsTimeLapseSpeedAuto}`);
      workerCallback.onTimeLapseTryAeDone(finalInterval);
      this.mSession?.setTimeLapseRecordState(camera.TimeLapseRecordState.RECORDING);
      this.startCaptureLoop(finalInterval);
    }
  };
  private mTimeLapseErrorCallback: ErrorCallback = (error) => {
    HiLog.e(TAG, `timeLapseVideo error: ${error.code}`);
  };
  private mAbilityChangeCallback: AsyncCallback<void> = (err) => {
    if (err) {
      HiLog.e(TAG, `abilityChange error: ${err?.code}.`);
      return;
    }
    HiLog.i(TAG, 'abilityChange success');
    if (this.getSupportedPhysicalApertures().length === 0) {
      workerCallback.onAbilityChange(this.mSession.getIsoRange(), []); // 自查无参数
    } else {
      workerCallback.onAbilityChange(this.mSession.getIsoRange(), this.mSession.getSupportedPhysicalApertures());
    }
  };
  private mSuperMacroIconVisibleCallback: AsyncCallback<boolean> = (err, isSuperMacroIconVisible: boolean) => {
    HiLog.i(TAG, `mSuperMacroIconVisibleCallback isSuperMacroIconVisible: ${isSuperMacroIconVisible}.`);
    if (err) {
      HiLog.e(TAG, `isSuperMacroIconVisible error: ${err?.code}.`);
    }
  };
  private watchSuperMotionStatusCallback: AsyncCallback<camera.SlowMotionStatus> = (err, status: number) => {
    if (err) {
      HiLog.e(TAG, `SlowMotionStatus error: ${err?.code}.`);
    }
    const resultMotionStatus: number = err ? 0 : status;
    HiLog.i(TAG, `watch super motion status:${resultMotionStatus}`);
    workerCallback.onSuperMotionStatus(resultMotionStatus);
  };
  // @ts-ignore
  private watchSlowZoomRangeCallback: AsyncCallback<camera.ZoomInfo> = (err, slowZoomRange: number[]) => {
    if (err) {
      HiLog.e(TAG, `SLOWMotionZoomRange error: ${err?.code}.`);
    }
    HiLog.i(TAG, `watch slow motion zoom range:${JSON.stringify(slowZoomRange)}`);
    workerCallback.onSlowMotionZoomRange(slowZoomRange);
  };

  private mWatchLcdStatusCallback: AsyncCallback<camera.LcdFlashStatus> = (err, lcdStatus: camera.LcdFlashStatus) => {
    if (err) {
      HiLog.e(TAG, `lcdFlashStatus error: ${err?.code}.`);
    }
    if (this.prevLcdFlashStatus !== lcdStatus.isLcdFlashNeeded) {
      this.prevLcdFlashStatus = lcdStatus.isLcdFlashNeeded;
      try {
        this.mSession.enableLcdFlash(lcdStatus.isLcdFlashNeeded);
      } catch (err) {
        HiLog.e(TAG, `enableLcdFlash fail, ${simpleStringify(err)}`);
      }
      HiLog.limitLog(TAG,
        `lcdFlashStatus enable, lcdCompensation: ${lcdStatus.lcdCompensation},${lcdStatus.isLcdFlashNeeded}`,
        'workerLcdFlashStatus');
    }
    workerCallback.onLcdFlashCompensate(lcdStatus);
  };

  // @ts-ignore
  private mConstellationDraw: AsyncCallback<camera.ConstellationDrawing> = (err, info: camera.ConstellationDrawing) => {
    if (err) {
      HiLog.e(TAG, `constellationDrawing error: ${err?.code}.`);
      return;
    }
    if (!info || !info.starsInfo) {
      HiLog.w(TAG, `info is invaliad: ${info}.`);
      return;
    }
  };

  constructor(cameraManager: camera.CameraManager, mode: ModeType, cameraModeMessage: App2CameraModeMessage,
    cameraContext: CameraContext) {
    this.mMode = mode;
    this.mCameraContext = cameraContext;
    this.mSession = new BaseSession(cameraManager, mode, cameraModeMessage);
    this.mSession.on('smoothZoomInfoAvailable', this.mSmoothZoomInfoCallback);
  }

  public async commitSession(tagMessage: TagMessage, cameraPosition: camera.CameraPosition,
    isPicker = false): Promise<void> {
    await this.createSessionAndSessionWrap(tagMessage, cameraPosition);
    await VideoModule.getInstance().addMaintainDebugMetaData(); // 录像维测数据
    HiLog.begin(TAG, 'commitConfig');
    await this.mSession.commitConfig().catch(error => {
      HiLog.e(TAG, `session commitConfig error: ${simpleStringify(error)}.`);
    });
    HiLog.end(TAG, 'commitConfig');
    //TODO this.checkIsCustomFilterSupported();
    // if (tagMessage.isLogAssistanceOn) {
    //   this.mPreviewOutput?.enableLogAssistance(true);
    //   HiLog.i(TAG, `enbale LogAssistance done`);
    // }
    // if (!isPicker && this.mSession.isMacroSupported()) {
    //   this.enableMacro(false);
    // }
    // if (!isPicker) { // picker不支持离线拍照
    //   this.mPhotoOutput?.enableOffline();
    // }
    // if (DeviceInfo.isPc()) {
    //   HiLog.w(TAG, 'Device is PC return.');
    //   return;
    // }
    // this.mHasFlash = this.mSession.hasFlash();
    this.mZoomRatioRange = this.mSession.getZoomRatioRange();
    // this.mZoomPointInfo = this.mSession.getZoomPointInfo();
    // this.handleScenesFeatureOn(tagMessage.mode);
    // this.handleMacroAbilityOn(tagMessage.mode);
    // this.handleProfessionOn(tagMessage.mode);
    // this.handleTimeLapseModeSessionOn(tagMessage.mode);
    // this.handleStitchingModeSessionOn(tagMessage.mode);
    // this.handleCinemaSessionOn(tagMessage.mode);
    // this.handleLcdFlashStatusOn();
    // this.handleEffectSuggestionChangeOn(tagMessage.mode);
    // this.handleFocusStateChangeOn();
    // this.setSessionUsage(tagMessage); //大光圈拍照模式信息更改
    // this.handleLightStatusOn();
    // HiLog.e(TAG, `commitConfig hasFlash: ${this.mHasFlash}, getZoomRatioRange: ${this.mZoomRatioRange.toString()}.`);
  }

  private handlePreviewRotation(tagMessage: TagMessage): void {
    if (!tagMessage?.previewRotationInfo?.isNeedSetPreviewRotation) {
      HiLog.i(TAG, 'no need to set preview rotation.');
      return;
    }
    try {
      let previewRotation = this.mPreviewOutput.getPreviewRotation(tagMessage.previewRotationInfo.previewRotation);
      this.mPreviewOutput.setPreviewRotation(previewRotation, tagMessage.previewRotationInfo.isDisplayLocked);
    } catch (error) {
      HiLog.e(TAG, `handlePreviewRotation error: ${simpleStringify(error)}.`);
    }
  }

  private getCameraInput(tagMessage: TagMessage): camera.CameraInput {
    let cameraInput: camera.CameraInput = this.mCameraInput.getInput();
    try {
      cameraInput.usedAsPosition(tagMessage.usedAsPositionValue);
      HiLog.i(TAG, `usedAsposition:${tagMessage.usedAsPositionValue}`);
    } catch (error) {
      HiLog.e(TAG, `usedAsposition error: ${simpleStringify(error)}.`);
    }
    return cameraInput;
  }

  private async createSessionAndSessionWrap(tagMessage: TagMessage,
    cameraPosition: camera.CameraPosition): Promise<void> {
    const videoModule: VideoModule = VideoModule.getInstance();
  //TODO  this.setColorSpaceBeforeCommitConfig(tagMessage); // 下发P3广色域、HDR vivid色彩空间
    if (OutputOperation.isPanVideoOutput(tagMessage.mode, tagMessage.outputType) && !!videoModule.getOutput()) {
      await VideoModule.getInstance().setOutputSetting(); //设置MovieOutputSetting需要在setColorSpace之后执行
      HiLog.i(TAG, 'RECORD_TRACK createSession video addOutput.');
      this.sessionAddOutputWrap(videoModule.getOutput());
      // 仅能配流过程中使能,会导致底层重启流
      this.mIsDeferVideo = videoModule.enableDeferredVideoEnhance();
    }
    if ((this.mCameraContext.isSupportPhotoOutput())) {
      HiLog.i(TAG, 'createSession photo addOutput.');
      this.sessionAddOutputWrap(this.mPhotoOutput.getOutput());
      HiLog.i(TAG, 'createSession photo addOutput done.');
      // 仅能配流过程中使能,会导致底层重启流
      this.mIsDeferPhoto = this.mPhotoOutput.enable(this.mMode, tagMessage.outputType);
    }
    // PC暂未支持拍照新增接口
    if (this.mPhotoOutput) {
      try {
        await this.mPhotoOutput.addCaptureListener();
      } catch (e) {
        HiLog.end(TAG, `addCaptureListener err, ${e}`);
      }
    }
    this.addPreviewOutput();
    HiLog.i(TAG, 'before add dual output, mode: ' + tagMessage.mode);
    const targetCamera: camera.CameraDevice = this.mCameraContext.getCamera();
    const isFront: boolean = targetCamera.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT ||
      targetCamera.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FOLD_INNER;

    if (this.mMetadataOutput) {
      HiLog.i(TAG, 'createSession metadata addOutput.');
      this.mSession.addOutput(this.mMetadataOutput.getOutput());
    }
    this.featureEnable(tagMessage);
  }

  public beginConfig(): void {
    HiLog.i(TAG, 'SessionWrap beginConfig.');
    this.mSession.beginConfig();
    HiLog.i(TAG, 'SessionWrap beginConfig done.');
  }

  public addInput(tagMessage: TagMessage): void {
    HiLog.i(TAG, 'createSession addInput.');
    this.mSession.addInput(this.getCameraInput(tagMessage));
    HiLog.i(TAG, 'createSession addInput done.');
  }

  private addPreviewOutput(): void {
    HiLog.i(TAG, 'createSession preview addOutput.');
    if (!!this.mPreviewOutput) {
      this.sessionAddOutputWrap(this.mPreviewOutput.getOutput());
    }
    if (this.mCollaborateOutput) { // 添加同端双屏协同镜头
      HiLog.i(TAG, ' mSession.addOutput: mCollaborateOutput.');
      this.mSession.addOutput(this.mCollaborateOutput.getOutput());
      this.hasOtherOutput = true;
    }
    if (this.mCollaborateControlOutput) { // 添加遥控拍照手表流
      HiLog.i(TAG, ' mSession.addOutput: mCollaborateControlOutput ' + this.mCollaborateControlOutput.getOutput());
      this.mSession.addOutput(this.mCollaborateControlOutput.getOutput());
    }
  }

  public setCollaboratePreviewOutput(previewOutput: PreviewOutputWrap): void {
    if (!previewOutput) {
      return;
    }
    this.mCollaborateOutput = previewOutput;
  }

  public clearCollaboratePreviewOutput(): void {
    this.mCollaborateOutput = null;
  }

  public setCollaborateControlPreviewOutput(previewOutput: PreviewOutputWrap): void {
    if (!previewOutput) {
      return;
    }
    this.mCollaborateControlOutput = previewOutput;
  }

  public clearCollaborateControlPreviewOutput(): void {
    this.mCollaborateControlOutput = null;
  }


  private featureEnable(tagMessage: TagMessage): void {
    if (!tagMessage) {
      return;
    }

    if (tagMessage.isMirror !== undefined && this.mPhotoOutput) {
      this.mPhotoOutput.setMirror(tagMessage.isMirror);
    }
    this.emotionEnable(tagMessage);
    this.mPreviewOutput.enableBandwidthCompression();
    this.isSupportStage(tagMessage);
  }

  private emotionEnable(tagMessage: TagMessage): void {
    try {
      if (tagMessage.isOperationEmotion !== undefined) {
        this.mMetadataOutput.setOperationEmotion(tagMessage.isOperationEmotion);
      }
    } catch (e) {
      HiLog.i(TAG, `metadataOutput set motion error = ${e.code}`);
    }
  }


  private isSupportStage(tagMessage): void {
    if (tagMessage.isSupportAudioStage) {
      this.setEffectAudioStage(true);
    }
    if (!this.isStageBoostSupported()) {
      return;
    }
  }

  private setLogStyleColorSpaceBeforeCommitConfig(tagMassage: TagMessage): boolean {
    return false;
  }

  private setColorSpaceBeforeCommitConfig(tagMassage: TagMessage): void {
    let mColorSpace = colorSpaceManager.ColorSpace.DISPLAY_P3;
    let mHighColorSpace = colorSpaceManager.ColorSpace.BT2020_HLG;
    let traditionalColorSpace = colorSpaceManager.ColorSpace.SRGB;
    HiLog.i(TAG, `setColorSpaceBeforeCommitConfig ColorSpace: ${mColorSpace}, traditional: ${traditionalColorSpace}.`);
    if (tagMassage?.isP3Flag !== undefined) {
      traditionalColorSpace = colorSpaceManager.ColorSpace.SRGB;
      HiLog.i(TAG, `setColorSpaceBeforeCommitConfig isP3Flag: ${tagMassage?.isP3Flag}, mColorSpace: ${mColorSpace}.`);
    }
    if (this.setLogStyleColorSpaceBeforeCommitConfig(tagMassage)) {
      return;
    }
    try {
      let colorSpaceArr: colorSpaceManager.ColorSpace[] = this.getColorSpaceArr(tagMassage);
      colorSpaceArr.forEach((colorSpace) => {
        HiLog.i(TAG, `setColorSpace colorSpaceArr: ${colorSpace}.`);
      });
      const isSupportUseColorSpace = colorSpaceArr.indexOf(mColorSpace) >= 0;
      const isSupportHighColorSpace = colorSpaceArr.indexOf(mHighColorSpace) >= 0;
      HiLog.i(TAG,
        `setColorSpace isSupportUseColorSpace: ${isSupportUseColorSpace}, index: ${colorSpaceArr.indexOf(mColorSpace)}.`);
      HiLog.i(TAG,
        `setColorSpace isSupportHighColorSpace: ${isSupportHighColorSpace}, index: ${colorSpaceArr.indexOf(mHighColorSpace)}.`);
      if (isSupportUseColorSpace) {
        this.mSession.setColorSpace(mColorSpace);
      } else {
        this.mSession.setColorSpace(traditionalColorSpace);
      }
    } catch (err) {
      HiLog.e(TAG, `setColorSpace err: ${simpleStringify(err)}.`);
    }
  }

  private getColorSpaceArr(tagMassage: TagMessage) {
    let colorSpaceArr: colorSpaceManager.ColorSpace[] = [];
    colorSpaceArr = this.mSession.getSupportedColorSpaces();
    return colorSpaceArr;
  }

  public async swapVideoOutput(oldOutput: camera.CameraOutput, output: camera.CameraOutput,
    outputType: OutputType): Promise<void> {
    this.mSession.beginConfig();
    if (!!oldOutput && !!output) {
      try {
        this.mSession.removeOutput(oldOutput);
        HiLog.i(TAG, 'old videoOutput has been removed.');
      } catch (err) {
        HiLog.e(TAG, `remove video output fail, err: ${err}.`);
      }
      try {
        await oldOutput.release();
      } catch (err) {
        HiLog.e(TAG, `release old video output fail, err: ${err}.`);
      }
      try {
        this.mSession.addOutput(output);
      } catch (err) {
        HiLog.e(TAG, `addOutput video output fail, err: ${err}.`);
      }
    }
    this.mIsDeferPhoto = this.mPhotoOutput.enable(this.mMode, outputType);
    HiLog.i(TAG, 'startRecording addOutput finished.');
    HiLog.begin(TAG, 'commitConfig');
    await this.mSession.commitConfig();
    HiLog.end(TAG, 'commitConfig');
    this.mHasFlash = this.mSession.hasFlash();
    this.mZoomRatioRange = this.mSession.getZoomRatioRange();
    this.mZoomPointInfo = this.mSession.getZoomPointInfo();
  }

  public timeLapseTryAe(captureInterval: number, isSpeedAuto: boolean): void {
    HiLog.i(TAG, `timeLapseVideo start try ae, interval: ${captureInterval}`);
    this.mSession.setTimeLapseInterval(captureInterval);
    this.mTimeLapseUserInterval = captureInterval;
    this.mIsInTryAe = true;
    this.mIsTimeLapseSpeedAuto = isSpeedAuto;
    this.mSession.startTryAE();
  }

  public setVideoStabilization(videoStabilizationMode: camera.VideoStabilizationMode): void {
    try {
      HiLog.i(TAG, `RECORD_TRACK setVideoStabilization videoStabilizationMode: ${videoStabilizationMode} begin.`);
      let isSupported = this.mSession.isVideoStabilizationModeSupported(videoStabilizationMode);
      HiLog.i(TAG, `RECORD_TRACK setVideoStabilization isSupported: ${isSupported}.`);
      if (isSupported) {
        this.mSession.setVideoStabilizationMode(videoStabilizationMode);
        HiLog.i(TAG, `RECORD_TRACK setVideoStabilization videoStabilizationMode: ${isSupported} success.`);
      }
      const vsMode = this.mSession.getActiveVideoStabilizationMode();
      HiLog.i(TAG, `RECORD_TRACK get videoStabilizationMode: ${vsMode}.`);
    } catch (error) {
      HiLog.e(TAG, error.code);
    }
  }

  public closeVideoStabilization(): void {
    try {
      const isSupported = this.mSession.isVideoStabilizationModeSupported(camera.VideoStabilizationMode.OFF);
      HiLog.i(TAG, `closeVideoStabilization isSupported: ${isSupported}.`);
      if (isSupported) {
        this.mSession.setVideoStabilizationMode(camera.VideoStabilizationMode.OFF);
      }
      const vsMode = this.mSession.getActiveVideoStabilizationMode();
      HiLog.i(TAG, `VideoStabilization Mode : ${vsMode}.`);
    } catch (error) {
      HiLog.e(TAG, `RECORD_TRACK setVideoStabilization error: ${error?.code}.`);
    }
  }

  public async start(tagMessage: TagMessage): Promise<void> {
    this.handlePreviewRotation(tagMessage);
    HiLog.begin(TAG, 'start');
    await this.mSession.start().catch(error => {
      HiLog.e(TAG, `session start error: ${simpleStringify(error)}.`);
    });
    if (this.mMetadataOutput !== undefined) {
      await this.mMetadataOutput.start();
    }
  //TODO  this.checkIsCustomFilterSupported();
    HiLog.end(TAG, 'start');
  }

  public async stop(): Promise<void> {
    await this.mSession.stop().catch(error => {
      HiLog.e(TAG, `session stop error: ${simpleStringify(error)}.`);
    });
  }

  // @ts-ignore
  public getSupportedNightSubModeTypes(): camera.NightSubModeType[] {
    // @ts-ignore
    const modes: camera.NightSubMode[] = this.mSession.getSupportedNightSubModeTypes();
    HiLog.i(TAG, `getSupportedNightSubModeTypes: ${modes ? JSON.stringify(modes) : -1}`);
    return modes ? modes : [];
  }

  // @ts-ignore
  public setNightSubModeType(subMode: camera.NightSubModeType): void {
    this.mSession.setNightSubModeType(subMode);
  }

  public setLocation(location: geoLocationManager.Location): void {
    HiLog.i(TAG, `set night sub mode location: ${LOCATION_MESSAGE.type}`);
    this.mSession.setLocation(location);
  }

  public isNightSubModeHasFlash(flashMode: camera.FlashMode): boolean {
    const isHasFlash: boolean = this.mSession.isFlashModeSupported(flashMode);
    HiLog.i(TAG, 'isNightSubModeHasFlash: ' + isHasFlash);
    return isHasFlash;
  }

  public async offlineRemoveOutput(): Promise<void> {
    HiLog.begin(TAG, 'offlineRemoveOutput');
    try {
      this.mSession.beginConfig();
    } catch (e) {
      HiLog.i(TAG, `beginConfig, err: ${simpleStringify(e)}.`);
    }
    try {
      this.mSession.removeOutput(this.mPhotoOutput.getOutput());
    } catch (e) {
      HiLog.i(TAG, `offlineRemoveOutput, err: ${simpleStringify(e)}.`);
    }
    await this.mSession.commitConfig().catch(error => {
      HiLog.e(TAG, `session commitConfig error: ${simpleStringify(error)}.`);
    });
    HiLog.end(TAG, 'offlineRemoveOutput');
  }

  public async removeInput(): Promise<void> {
    HiLog.begin(TAG, 'removeInput');
    this.mSession.beginConfig();
    HiLog.i(TAG, 'remove input from session, and reuse it next.');
    try {
      this.mSession.removeInput(this.mCameraInput.getInput());
      this.mCameraInput = null;
    } catch (e) {
      HiLog.i(TAG, `remove input from session, err: ${simpleStringify(e)}.`);
    }
    HiLog.end(TAG, 'removeInput');
  }

  public async release(): Promise<void> {
    this.hasOtherOutput = false;

    this.handleMacroAbilityOff();
    this.handleSceneFeatureOff();
    this.handleProfessionOff();
    this.handleSlowMotionOff();
    this.handleLcdFlashStatusOff();
    this.handleTimeLapseModeSessionOff();
    this.handleNightSubModeOff();
    this.handleStitchingModeSessionOff();
    this.handleCinemaSessionOff();
    this.handleEffectSuggestionChangeOff();
    this.handleSmoothZoomInfoAvailableOff();
    this.handleCompositionSuggestionOff();
    this.handleLightStatusOff();

    this.mPreviewOutput = null;
    await this.mSession.release().catch(error => {
      HiLog.e(TAG, `session release error: ${simpleStringify(error)}.`);
    });
    this.mSession = null;
  }

  public hasInput(): boolean {
    return !!this.mCameraInput;
  }

  public setCameraInput(cameraInput: CameraInputWrap): void {
    if (!cameraInput) {
      HiLog.e(TAG, 'cameraInput is null.');
      return;
    }
    this.mCameraInput = cameraInput;
  }

  public setPreviewOutput(previewOutput: PreviewOutputWrap): void {
    if (!previewOutput) {
      HiLog.e(TAG, 'setPreviewOutput previewOutput is null.');
      return;
    }
    this.mPreviewOutput = previewOutput;
  }

  public setPreviewOutputForTimeLapse(previewOutput: PreviewOutputWrap): void {
    if (!previewOutput) {
      HiLog.e(TAG, 'setPreviewOutputForTimeLapse previewOutput is null.');
      return;
    }
    this.mPreviewOutputForTimeLapse = previewOutput;
  }

  public setPanoramaMaxPreviewOutput(previewOutput: PreviewOutputWrap): void {
    if (!previewOutput) {
      HiLog.e(TAG, 'panoramaMaxPreviewOutput is null.');
      return;
    }
    this.mPanoramaMaxPreviewOutput = previewOutput;
  }

  // 动态配流-海思是否使能HEBC均需支持动态配置不断流
  public async dynamicAddPreviewOutput(previewOutput: PreviewOutputWrap, tagMessage: TagMessage): Promise<void> {
    if (!previewOutput.getOutput()) {
      HiLog.e(TAG, 'dynamicAddPreviewOutput is null.');
      return;
    }
    try {
      HiLog.begin(TAG, 'dynamicAddPreviewOutput');
      this.mSession.beginConfig();
      this.mSession.addOutput(previewOutput.getOutput());
      await this.mSession.commitConfig().then(() => {
        HiLog.i(TAG, 'dynamicAddPreviewOutput session commit successfully');
      }).catch(error => {
        HiLog.e(TAG, `dynamicAddPreviewOutput session commitConfig error: ${simpleStringify(error)}.`);
      });
      await this.start(tagMessage);
      HiLog.end(TAG, 'dynamicAddPreviewOutput');
      this.hasOtherOutput = true;
    } catch (err) {
      HiLog.e(TAG, `dynamicAddPreviewOutput error: ${simpleStringify(err)}`);
    }
  }

  // 动态remove流
  public async dynamicRemovePreviewOutput(previewOutput: PreviewOutputWrap, tagMessage: TagMessage): Promise<void> {
    if (!previewOutput || !previewOutput.getOutput()) {
      HiLog.e(TAG, 'dynamicRemovePreviewOutput is null.');
      return;
    }
    HiLog.begin(TAG, 'dynamicRemovePreviewOutput');
    try {
      this.mSession.beginConfig();
      this.mSession.removeOutput(previewOutput.getOutput());
      await previewOutput.getOutput().release(); // HAL未真正实现释放,需上层主动release该条流
      await this.mSession.commitConfig().then(() => {
        HiLog.i(TAG, 'dynamicRemovePreviewOutput session commit successfully');
      }).catch(error => {
        HiLog.e(TAG, `dynamicRemovePreviewOutput session commitConfig error: ${simpleStringify(error)}.`);
      });
      await this.start(tagMessage);
      this.hasOtherOutput = false;
    } catch (error) {
      HiLog.e(TAG, `dynamicRemovePreviewOutput error: ${simpleStringify(error)}.`);
    }
    HiLog.end(TAG, 'dynamicRemovePreviewOutput');
  }

  public setPhotoOutput(photoOutput: PhotoOutputWrap): void {
    if (!photoOutput) {
      HiLog.w(TAG, 'photoOutput is null.');
      return;
    }
    this.mPhotoOutput = photoOutput;
  }

  public isHasOtherOutput(): boolean {
    return this.hasOtherOutput;
  }

  public setMetadataOutput(metadataOutput: MetadataOutputWrap): void {
    if (!metadataOutput) {
      HiLog.w(TAG, 'metadataOutput is null.');
      return;
    }
    this.mMetadataOutput = metadataOutput;
  }

  public hasFlash(): boolean {
    return this.mHasFlash;
  }

  public setFlashMode(flashMode: camera.FlashMode): void {
    HiLog.i(TAG, `setFlashMode: ${flashMode}.`);
    try {
      this.mSession.setFlashMode(flashMode);
    } catch (err) {
      HiLog.e(TAG, `setFlashMode err: ${simpleStringify(err)}`);
    }
  }

  //@ts-ignore
  public setStitchingType(stitchingType: camera.StitchingType): void {
    HiLog.i(TAG, `setStitchingType: ${stitchingType}.`);
    try {
      this.mSession.setStitchingType(stitchingType);
    } catch (err) {
      HiLog.e(TAG, `setStitchingType err: ${simpleStringify(err)}`);
    }
  }

  //@ts-ignore
  public setStitchingDirection(stitchingDirection: camera.StitchingDirection): void {
    HiLog.i(TAG, `setStitchingDirection: ${stitchingDirection}.`);
    try {
      this.mSession.setStitchingDirection(stitchingDirection);
    } catch (err) {
      HiLog.e(TAG, `setStitchingDirection err: ${simpleStringify(err)}`);
    }
  }

  public setMovingClockwise(stitchingMove: boolean): void {
    HiLog.i(TAG, `setMovingClockwise: ${stitchingMove}.`);
    try {
      this.mSession.setMovingClockwise(stitchingMove);
    } catch (err) {
      HiLog.e(TAG, `setMovingClockwise err: ${simpleStringify(err)}`);
    }
  }

  public setZoomRatio(zoomRatio: number): void {
    HiLog.d(TAG, `setZoomRatio: ${zoomRatio}.`);
    if (!!zoomRatio) {
      this.mSession.setZoomRatio(zoomRatio);
      this.mMetadataOutput?.setZoomRatio(zoomRatio);
    }
  }

  public getZoomRatio(): number {
    const zoomRatio: number = this.mSession.getZoomRatio();
    HiLog.i(TAG, `getZoomRatio: ${zoomRatio}.`);
    return zoomRatio;
  }

  public getZoomRatioRange(): number[] | undefined {
    HiLog.i(TAG, `getZoomRatioRange: ${JSON.stringify(this.mZoomRatioRange)}.`);
    return this.mZoomRatioRange;
  }

  public isFocusModeSupported(focusMode: number): boolean {
    const isSupported: boolean = this.mSession.isFocusModeSupported(focusMode);
    HiLog.i(TAG, `focusMode: ${focusMode} is isSupported: ${isSupported}.`);
    return isSupported;
  }

  public setFocusMode(focusMode: number, focusPoint: camera.Point, focusValue?: number): void {
    HiLog.i(TAG,
      `setFocusMode, focusMode: ${focusMode}, focusPoint: ${simpleStringify(focusPoint)},focusValue: ${focusValue}.`);
    if (focusMode !== undefined) {
      this.mSession.setFocusMode(focusMode);
    }
    if (focusPoint) {
      this.mSession.setFocusPoint(focusPoint);
    }
    if (focusMode === camera.FocusMode.FOCUS_MODE_MANUAL) {
      this.mSession.setFocusDistance(focusValue);
    }
  }

  public isExposureModeSupported(exposureMode: number): boolean {
    const isSupported: boolean = this.mSession.isExposureModeSupported(exposureMode);
    HiLog.i(TAG, `focusMode: ${exposureMode} is isSupported: ${isSupported}.`);
    return isSupported;
  }

  public setExposure(data: ExposureData): void {
    HiLog.i(TAG,
      `setExposure, exposureMode: ${data.exposureMode}, exposurePoint: ${data.exposurePoint},exposureValue: ${data.exposureValue}.`);
    if (data.exposureMode !== undefined && this.mSession.isExposureModeSupported(data.exposureMode)) {
      this.mSession.setExposureMode(data.exposureMode);
    }
    if (data.exposurePoint) {
      this.mSession.setMeteringPoint(data.exposurePoint);
    }
    if (data.exposureValue !== undefined) {
      this.mSession.setExposureBias(data.exposureValue);
    }
  }

  private handleFocusStateCallback = async (err: any, state: camera.FocusState): Promise<void> => {
    if (err) {
      HiLog.d(TAG, `handleFocusStateCallback focusStateChange, err: ${err}.`);
    } else {
      HiLog.limitLog(TAG, `handleFocusStateCallback focusStateChange, state: ${state}.`, 'workerFocusStateLogKey');
      workerCallback.updateFocusState(state);
    }
  }

  private handleFocusStateChangeOn(): void {
    HiLog.i(TAG, 'handleFocusStateChangeOn E.');
    this.mSession.on('focusStateChange', this.handleFocusStateCallback);
  }

  public setMeteringPoint(focusPoint: camera.Point): void {
    HiLog.i(TAG, `setMeteringPoint, focusPoint: ${JSON.stringify(focusPoint)}.`);
    this.mSession.setMeteringPoint(focusPoint);
  }

  public setXmage(value: number): void {
    HiLog.i(TAG, `setXmage value: ${value}`);
    this.mSession.setColorEffect(value === -1 ? 0 : value);
  }

  public getXmage(): number {
    return this.mSession.getColorEffect();
  }

  public getSupportedColorEffects(): camera.ColorEffectType[] {
    return this.mSession.getSupportedColorEffects();
  }

  public isNightSupportedColorEffects(): boolean {
    return this.mSession.getSupportedColorEffects()?.length > 1;
  }

  // @ts-ignore
  public getSessionFunctions(outputCapability: camera.CameraOutputCapability): camera.NightPhotoFunctions[] {
    return this.mSession.getSessionFunctions(outputCapability);
  }

  // @ts-ignore
  public getSessionConflictFunctions(): camera.NightPhotoConflictFunctions[] {
    return this.mSession.getSessionConflictFunctions();
  }

  public hasXmage(): boolean {
    return this.mSession.getSupportedColorEffects()?.length > 0;
  }

  public getSupportedPortraitEffects(): number[] {
    return this.mSession.getSupportedPortraitEffects();
  }

  public getPortraitEffect(): number {
    return this.mSession.getPortraitEffect();
  }

  public setPortraitEffect(value: number): void {
    HiLog.i(TAG, `setPortraitEffect value: ${value}.`);
    this.mSession.setPortraitEffect(value);
  }

  public getSupportedBeautyTypes(): camera.BeautyType[] {
    return this.mSession.getSupportedBeautyTypes();
  }

  public getSupportedBeautyRange(beautyType: camera.BeautyType): number[] {
    return this.mSession.getSupportedBeautyRange(beautyType);
  }

  public checkIsCustomFilterSupported(): boolean {
    this.mIsColorStyleSupport = this.mSession.isColorStyleSupported();
    return this.mIsColorStyleSupport;
  }

  // @ts-ignore
  public getDefaultColorStyleSettings(): camera.ColorStyleSetting[] {
    if (!this.mIsColorStyleSupport) {
      HiLog.w(TAG, `getDefaultColorStyleSettings in unsupport mode: ${this.mMode}`);
      return [];
    }

    // @ts-ignore
    const defaultSettings: camera.ColorStyleSetting[] = this.mSession.getDefaultColorStyleSettings();

    HiLog.i(TAG, `getDefaultColorStyleSettings: ${JSON.stringify(defaultSettings)}`)

    return defaultSettings ? defaultSettings : [];
  }

  // @ts-ignore
  public setColorStyleSetting(setting: camera.ColorStyleSetting): void {
    if (!this.mIsColorStyleSupport) {
      HiLog.w(TAG, `setColorStyleSetting in unsupport mode: ${this.mMode}`);
      return;
    }
    this.mSession.setColorStyleSetting(setting);
  }

  // @ts-ignore
  public getColorStyleSetting(): camera.ColorStyleSetting {
    if (!this.mIsColorStyleSupport) {
      HiLog.w(TAG, `setColorStyleSetting in unsupport mode: ${this.mMode}`);
      return null;
    }

    // @ts-ignore
    const currentSetting: camera.ColorStyleSetting = this.mSession.getColorStyleSetting();
    // todo colorStyle delete JSON.stringify
    HiLog.i(TAG, `getColorStyleSetting: ${JSON.stringify(currentSetting)}`);
    return currentSetting;
  }

  public getBeauty(beautyType: camera.BeautyType): number {
    return this.mSession.getBeauty(beautyType);
  }

  public setBeauty(beautyType: camera.BeautyType, beautyValue: number): void {
    HiLog.i(TAG, `setBeauty beautyType: ${beautyType}, beautyValue: ${beautyValue}.`);
    this.mSession.setBeauty(beautyType, beautyValue);
  }

  public setPortraitThemeType(ThemeType: number): void {
    HiLog.i(TAG, `setBeauty ThemeType: ${ThemeType}.`);
    this.mSession.setPortraitThemeType(ThemeType);
  }

  public getSupportedLightPaintings(): number[] {
    return this.mSession.getSupportedLightPaintings();
  }

  public getLightPainting(): number {
    return this.mSession.getLightPainting();
  }

  public setLightPainting(value: number): void {
    this.mSession.setLightPainting(value);
  }

  public triggerLighting(): void {
    this.mSession.triggerLighting();
  }

  public getExposureBiasRange(): number[] {
    let exposureBiasRange = this.mSession.getExposureBiasRange();
    return exposureBiasRange;
  }

  public getSupportedExposureRange(): number[] {
    const exposureRange: number[] = this.mSession.getSupportedExposureRange();
    HiLog.i(TAG, `getSupportedExposureRange: ${exposureRange ? JSON.stringify(exposureRange) : -1}`);
    return exposureRange ? exposureRange : [];
  }

  public getExposure(): number {
    return this.mSession.getExposure();
  }

  public getSupportedColorSpaces(): colorSpaceManager.ColorSpace[] {
    return this.mSession.getSupportedColorSpaces();
  }

  public setExposureValue(exposureValue: number): void {
    HiLog.i(TAG, `setExposureValue exposureValue: ${exposureValue}, mMode: ${this.mMode}.`);
    this.mSession.setExposureDuration(exposureValue);
  }

  public getExposureMode(): camera.ExposureMode {
    let curExposureMode = this.mSession.getExposureMode();
    return curExposureMode;
  }

  private handleTimeLapseModeSessionOff(): void {
    this.mTryAeInfo = undefined;
    this.mIsInTryAe = false;
    try {
      this.mSession?.off('isoInfoChange', this.mIsoInfoCallback);
      this.mSession?.off('exposureInfoChange', this.mExposureInfoCallback);
      this.mSession?.off('luminationInfoChange', this.mLuminationCallback);
      this.mSession?.off('error', this.mTimeLapseErrorCallback);
      this.mSession?.off('tryAEInfoChange', this.mTryAeCallback);
      this.mSession?.off('abilityChange', this.mAbilityChangeCallback);
      HiLog.d(TAG, 'handleTimeLapseModeSessionOff');
    } catch (e) {
      HiLog.e(TAG, `handleTimeLapseModeSessionOff err:${e}`);
    }
  }

  private handleStitchingModeSessionOff(): void {
    try {
      HiLog.i(TAG, `stitching session off`);
    } catch (e) {
      HiLog.e(TAG, `handlePassionModeSessionOff err:${e}`);
    }
  }

  private handleTimeLapseModeSessionOn(mode: ModeType): void {
    this.mIsInTryAe = false;
    this.mTryAeInfo = undefined;
    const targetCamera: camera.CameraDevice = this.mCameraContext.getCamera();
    const cameraPosition = targetCamera.cameraPosition;
    const isBack: boolean = cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK;
    HiLog.i(TAG, `timeLapseVideo regester callback mode: ${mode}, isBakcCamera: ${isBack}`);

    try {
      this.mSession?.on('isoInfoChange', this.mIsoInfoCallback);
      this.mSession?.on('exposureInfoChange', this.mExposureInfoCallback);
      this.mSession?.on('luminationInfoChange', this.mLuminationCallback);
      this.mSession?.on('error', this.mTimeLapseErrorCallback);
      this.mSession?.on('tryAEInfoChange', this.mTryAeCallback);
      this.mSession?.on('abilityChange', this.mAbilityChangeCallback);
    } catch (error) {
      HiLog.e(TAG, `timeLapseVideo register callback error: ${error.code}`);
    }
  }

  private handleNightSubModeOff() {
    if (this.getSupportedNightSubModeTypes().length > 0) {
      this.handleImageStabilizationGuideOff();
      this.handleConstellationDrawingOff();
    }
    try {
      this.mSession?.off('abilityChange', this.mAbilityChangeCallback);
    } catch (error) {
      HiLog.e(TAG, `NightSubMode register callback error: ${error.code}`);
    }
  }

  private handleStitchingModeSessionOn(mode: ModeType): void {
    try {
      HiLog.i(TAG, `stitching session on`);
    } catch (error) {
      HiLog.e(TAG, `stitching register callback error: ${error.code}`);
    }
  }

  private handleCinemaSessionOn(mode: ModeType): void {
    if (this.mCameraContext.getCameraPosition() !== camera.CameraPosition.CAMERA_POSITION_BACK) {
      return;
    }
    try {
      // @ts-ignore
      this.mSession?.on('apertureEffectChange', (error: BusinessError<void>, effect: camera.ApertureEffect) => {
        HiLog.i(TAG, `cinema apertureEffectChange: ${effect}.`);
        workerCallback.apertureEffectChange(effect);
      });
      HiLog.i(TAG, 'cinema session on');
    } catch (error) {
      HiLog.e(TAG, `cinema register callback error: ${error.code}`);
    }
  }

  private handleCinemaSessionOff(): void {
    try {
      this.mSession?.off('apertureEffectChange');
    } catch (error) {
      HiLog.e(TAG, `cinema apertureEffectChange callback error: ${error.code}`);
    }
  }

  private startCaptureLoop(captureInterval: number): void {
    this.mTimeLapseStopCapture = false;
    this.captureTimelapseFun();
    this.timeLapseTimerId = setInterval(this.captureTimelapseFun, Math.max(captureInterval, TIME_LAPSE_MIN_INTERVAL));
  }

  public stopCaptureLoop(): void {
    this.mTimeLapseStopCapture = true;
    this.clearTimeLapseInterval();
    this.timeLapseTimerId = Number.MIN_VALUE;
    this.mSession?.setTimeLapseRecordState(camera.TimeLapseRecordState.IDLE);
    HiLog.w(TAG, 'stopCaptureLoop E.');
  }

  private clearTimeLapseInterval(): void {
    if (Number.MIN_VALUE !== this.timeLapseTimerId) {
      clearInterval(this.timeLapseTimerId);
    }
  }

  private handleProfessionOn(mode: ModeType): void {
    this.mSession?.on('isoInfoChange', this.mIsoInfoCallback);
    this.mSession?.on('exposureInfoChange', this.mExposureInfoCallback);
    this.mSession?.on('apertureInfoChange', this.mApertureInfoCallback);
    this.mSession?.on('luminationInfoChange', this.mLuminationCallback);
    this.mSession?.on('abilityChange', this.mAbilityChangeCallback);
  }

  private handleProfessionOff(): void {
    try {
      this.mSession?.off('isoInfoChange', this.mIsoInfoCallback);
      this.mSession?.off('exposureInfoChange', this.mExposureInfoCallback);
      this.mSession?.off('apertureInfoChange', this.mApertureInfoCallback);
      this.mSession?.off('luminationInfoChange', this.mLuminationCallback);
      this.mSession?.off('abilityChange', this.mAbilityChangeCallback);
      HiLog.d(TAG, 'handleProfessionOff');
    } catch (e) {
      HiLog.e(TAG, `handleProfessionOff err:${e}`);
    }
  }

  public getExposureValue(): number {
    let curExposureValue = this.mSession.getExposureValue();
    return curExposureValue;
  }

  public setExposureMode(exposureMode: camera.ExposureMode): void {
    HiLog.i(TAG, `setExposureMode exposureMode: ${exposureMode}.`);
    this.mSession.setExposureMode(exposureMode);
  }

  public setExposureBias(value: number): void {
    HiLog.i(TAG, `setExposureBias value: ${value}.`);
    this.mSession.setExposureBias(value);
  }

  public enableMacro(enable: boolean): void {
    HiLog.i(TAG, `enableMacro [SuperMacro] enable: ${enable}.`);
    try {
      this.mSession.enableMacro(enable);
    } catch (err) {
      HiLog.e(TAG, `enableMacro [SuperMacro] set fail...， ${simpleStringify(err)}`);
    }
  }

  public isStageBoostSupported(): boolean {
    let isStageSupported = this.mSession.isStageBoostSupported();
    return isStageSupported;
  }

  public enableStageBoost(enable: boolean): void {
    HiLog.i(TAG, `enableStageBoost [Stage] enable: ${enable}.`);
    try {
      this.mSession.enableStageBoost(enable);
    } catch (err) {
      HiLog.e(TAG, `enableStageBoost [Stage] set fail...， ${simpleStringify(err)}`);
    }
  }

  private handleMacroAbilityOn(mode: ModeType): void {
    if (mode !== ModeType.PHOTO && mode !== ModeType.VIDEO) {
      return;
    }
    this.mIsMacroSupported = this.mSession.isMacroSupported();
    HiLog.i(TAG, `handleMacroAbilityOn  [SuperMacro] mIsMacroSupported: ${this.mIsMacroSupported}`);
    this.mSession.on('macroStatusChanged', this.mSuperMacroIconVisibleCallback);
  }

  private handleMacroAbilityOff(): void {
    try {
      this.mSession.off('macroStatusChanged', this.mSuperMacroIconVisibleCallback);
      HiLog.d(TAG, 'handleMacroAbilityOff');
    } catch (e) {
      HiLog.e(TAG, `handleMacroAbilityOff err:${e}`);
    }
  }

  public prepareZoom(): void {
    this.mSession.prepareZoom();
  }

  public unPrepareZoom(): void {
    this.mSession.unprepareZoom();
  }

  public setSmoothZoom(targetRatio: number): void {
    HiLog.i(TAG, `setSmoothZoom: ${targetRatio}`);
    if (!!targetRatio) {
      this.mSession.setSmoothZoom(targetRatio, 0);
      this.mMetadataOutput?.setZoomRatio(targetRatio);
    }
  }

  public getIsDeferPhoto(): boolean {
    return this.mIsDeferPhoto;
  }

  public getIsDeferVideo(): boolean {
    return this.mIsDeferVideo;
  }

  public isSceneFeatureSupported(scene: camera.SceneFeatureType): boolean {
    const result: boolean = this.mSession.isSceneFeatureSupported(scene);
    HiLog.i(TAG, `get sceneFeature: ${scene}, result: ${result}`);
    return result;
  }

  public async enableSceneFeature(scene: camera.SceneFeatureType, enabled: boolean): Promise<void> {
    HiLog.i(TAG, `enableSceneFeature enable: ${enabled}.`);
    try {
      this.mSession.enableSceneFeature(scene, enabled);
    } catch (err) {
      HiLog.e(TAG, 'enableSceneFeature set fail...');
    }
  }

  private handleSceneFeatureOn(type: camera.SceneFeatureType): void {
    const isSupported: boolean = this.mSession.isSceneFeatureSupported(type);
    if (isSupported) {
      this.mSession.on('featureDetectionStatus', this.mSceneFeatureCallBack, type);
    }
    HiLog.i(TAG, `handleSceneFeatureOn type: ${type}, isSupported: ${isSupported}.`);
    this.mIsSceneFeatureSupported = this.mIsSceneFeatureSupported || isSupported;
    HiLog.i(TAG, `handleSceneFeatureOn mIsSceneFeatureSupported: ${this.mIsSceneFeatureSupported}.`);
  }

  private handleScenesFeatureOn(mode: ModeType): void {
    if (mode !== ModeType.PHOTO) {
      return;
    }
    this.handleSceneFeatureOn(camera.SceneFeatureType.MOON_CAPTURE_BOOST);
    this.handleSceneFeatureOn(camera.SceneFeatureType.TRIPOD_DETECTION);
    this.handleSceneFeatureOn(camera.SceneFeatureType.LOW_LIGHT_BOOST);
  };

  private handleSceneFeatureOff(): void {
    try {
      this.mSession?.off('featureDetectionStatus', this.mSceneFeatureCallBack);
      HiLog.d(TAG, 'handleSceneFeatureOff');
    } catch (e) {
      HiLog.e(TAG, `handleSlowMotionOff err:${e}`);
    }
  }

  public getSupportedVirtualApertures(): number[] {
    HiLog.i(TAG, 'getSupportedVirtualApertures E');
    let supportedVirtualApertures = this.mSession.getSupportedVirtualApertures();
    HiLog.i(TAG, `getSupportedVirtualApertures X`);
    return supportedVirtualApertures;
  }

  public getVirtualAperture(): number {
    let virtualAperture = this.mSession.getVirtualAperture();
    return virtualAperture;
  }

  public setVirtualAperture(value: number): void {
    HiLog.i(TAG, 'setVirtualAperture: ' + value);
    this.mSession.setVirtualAperture(value);
  }

  public getSupportedPhysicalApertures(): camera.PhysicalAperture[] {
    HiLog.i(TAG, 'getSupportedPhysicalApertures E');
    try {
      let supportedPhysicalApertures = this.mSession.getSupportedPhysicalApertures();
      HiLog.i(TAG, `getSupportedPhysicalApertures `);
      return supportedPhysicalApertures;
    } catch (err) {
      HiLog.e(TAG, 'getSupportedPhysicalApertures' + simpleStringify(err));
      return [];
    }
  }

  public getIsPortraitThemeSupported(): boolean {
    let isPortraitThemeSupported = this.mSession.getIsPortraitThemeSupported();
    return isPortraitThemeSupported;
  }

  public getPhysicalAperture(): number {
    let physicalAperture = this.mSession.getPhysicalAperture();
    return physicalAperture;
  }

  public setPhysicalAperture(value: number): void {
    HiLog.i(TAG, 'setPhysicalAperture: ' + value);
    this.mSession.setPhysicalAperture(value);
  }

  public getExposureMeteringMode(): number {
    let exposureMeteringMode = this.mSession.getExposureMeteringMode();
    return exposureMeteringMode;
  }

  public setExposureMeteringMode(meteringValue: number): void {
    HiLog.i(TAG, 'setExposureMeteringMode meteringValue: ' + meteringValue);
    this.mSession.setExposureMeteringMode(this.number2MeteringMode(meteringValue));
  }

  private number2MeteringMode(meteringValue: number): camera.ExposureMeteringMode {
    let mode: camera.ExposureMeteringMode;
    switch (meteringValue) {
      case 0:
        mode = camera.ExposureMeteringMode.MATRIX;
        break;
      case 1:
        mode = camera.ExposureMeteringMode.CENTER;
        break;
      case 2:
        mode = camera.ExposureMeteringMode.SPOT;
        break;
      default:
        mode = camera.ExposureMeteringMode.MATRIX;
    }
    return mode;
  }

  public setApertureValue(Aperture: number): void {
    HiLog.i(TAG, `setAperatureValue Aperature: ${Aperture}.`);
    this.mSession.setApertureValue(Aperture);
  }

  public getAuxiliary(): boolean {
    let auxiliary = this.mSession.getFocusAssist();
    return auxiliary;
  }

  public setAuxiliary(auxiliaryValue: number): void {
    HiLog.i(TAG, `setAuxiliary auxiliaryValue: ${auxiliaryValue} .`);
    this.mSession.setFocusAssist(auxiliaryValue);
  }

  public setExposureDuration(exposureValue: number): void {
    HiLog.i(TAG, `setExposureDuration exposureValue: ${exposureValue}.`);
    this.mSession.setExposureDuration(exposureValue);
  }

  public getExposureDuration(): camera.ExposureMode {
    let curExposureMode = this.mSession.getExposureDuration();
    return curExposureMode;
  }

  public getIsoValue(): number {
    let curIso = this.mSession.getIso();
    return curIso;
  }

  public setIsoValue(isoValue: number): void {
    HiLog.i(TAG, `setIsoValue isoValue: ${isoValue}.`);
    this.mSession.setIso(isoValue);
  }

  public getWhiteBalanceMode(): number {
    let whiteBalanceMode = this.mSession.getWhiteBalanceMode();
    return whiteBalanceMode;
  }

  public getWhiteBalance(): number {
    let curIso = this.mSession.getWhiteBalance();
    return curIso;
  }

  public setWhiteBalance(whiteBalanceValue: number): void {
    HiLog.i(TAG, `setWhitebalance whitebalanceValue: ${whiteBalanceValue} .`);
    this.mSession.setWhiteBalance(whiteBalanceValue);
  }

  public setSlowMotionDetectionArea(posData: camera.Rect): void {
    if (this.mSession.isSlowMotionDetectionSupported()) {
      HiLog.i(TAG, `set superSlowMotion detection box position data:${JSON.stringify(posData)}`);
      this.mSession.setSlowMotionDetectionArea(posData);
    }
  }

  private handleSlowZoomChangeOn(): void {
    try {
      this.mSession.on('zoomInfoChange', this.watchSlowZoomRangeCallback);
    } catch (e) {
      HiLog.e(TAG, `handleSlowMotionOn zoomInfoChange:${JSON.stringify(e)}`);
    }
  }

  private async handleSlowMotionOn(mode: ModeType, isSuperSlowMotion: boolean): Promise<void> {
    WorkerDataCache.getInstance().setMotionStateForRecord(true);
    this.handleSlowZoomChangeOn();
    if (isSuperSlowMotion) { // 针对超慢录制状态的监听
      const superDetectionPos: camera.Rect = {
        // 下发关闭运动侦测命令使能超慢
        topLeftX: -1.0,
        topLeftY: -1.0,
        width: -1.0,
        height: -1.0,
      };
      this.setSlowMotionDetectionArea(superDetectionPos);
      if (this.mSession.isSlowMotionDetectionSupported()) {
        this.mSession.on('slowMotionStatus', this.watchSuperMotionStatusCallback);
      }
    }
  }

  private handleSlowMotionOff(): void {
    try {
      this.mSession.off('slowMotionStatus');
      this.mSession.off('zoomInfoChange');
      HiLog.d(TAG, 'handleSlowMotionOff');
    } catch (e) {
      HiLog.e(TAG, `handleSlowMotionOff err:${e}`);
    }
  }

  public handleConstellationDrawingOn(): void {
    try {
      // @ts-ignore
      this.mSession.on('featureDetection', this.mConstellationDraw, camera.SceneFeatureType.CONSTELLATION_DRAWING);
      HiLog.i(TAG, 'on ConstellationDrawing');
    } catch (e) {
      HiLog.e(TAG, `on ConstellationDrawing err:${e}`);
    }
  }

  public handleConstellationDrawingOff(): void {
    // @ts-ignore
    if (this.mSession.isSceneFeatureSupported(camera.SceneFeatureType.CONSTELLATION_DRAWING)) {
      try {
        this.mSession.off('featureDetection', this.mConstellationDraw);
        HiLog.i(TAG, 'off ConstellationDrawing');
      } catch (e) {
        HiLog.e(TAG, `off ConstellationDrawing err:${e}`);
      }
    }
  }

  private handleLcdFlashStatusOn(): void { // 环形补光
    if (this.mSession.isLcdFlashSupported()) {
      this.mSession.on('lcdFlashStatus', this.mWatchLcdStatusCallback);
    }
  }

  private handleLcdFlashStatusOff(): void {
    try {
      this.mSession.off('lcdFlashStatus', this.mWatchLcdStatusCallback);
      HiLog.d(TAG, 'handleLcdFlashStatusOff');
    } catch (e) {
      HiLog.e(TAG, `handleLcdFlashStatusOff err:${e}`);
    }
  }

  private handleImageStabilizationGuideOn(): void { // 新夜景十字校准
    if (this.mSession.isImageStabilizationGuideSupported()) {
      try {
      } catch (e) {
        HiLog.e(TAG, `on imageStabilizationGuide err:${e}`);
      }
    }
  }

  private handleImageStabilizationGuideOff(): void {
    if (this.mSession.isImageStabilizationGuideSupported()) {
      try {
        HiLog.d(TAG, 'handleImageStabilizationGuideOff');
      } catch (e) {
        HiLog.e(TAG, `handleImageStabilizationGuideOff err:${e}`);
      }
    }
  }

  public isImageStabilizationGuideSupported(): boolean {
    let isSupported: boolean = this.mSession.isImageStabilizationGuideSupported();
    HiLog.i(TAG, `isImageStabilizationGuideSupported: ${isSupported}`);
    return isSupported;
  }

  public enableImageStabilizationGuide(enabled: boolean): void {
    HiLog.i(TAG, `enableImageStabilizationGuide: ${enabled}`);
    this.mSession.enableImageStabilizationGuide(enabled);
  }

  public getZoomPointInfo(): ZoomPointInfo {
    return this.mZoomPointInfo;
  }

  public getFocusDistance(): number {
    let focusDistance = this.mSession.getFocusDistance();
    HiLog.i(TAG, `getFocusDistance focusDistance: ${focusDistance}`);
    return focusDistance;
  }

  public getIsoRange(): number[] {
    return this.mSession.getIsoRange();
  }


  private handleEffectSuggestionChangeOn(mode: ModeType): void {
    if (mode !== ModeType.PHOTO && mode !== ModeType.VIDEO) {
      return;
    }
    this.mIsEffectSuggestionSupported = this.mSession.isEffectSuggestionSupported();
    HiLog.i(TAG, `handleEffectSuggestionChangeOn isEffectSuggestionSupported: ${this.mIsEffectSuggestionSupported}.`);
    if (this.mIsEffectSuggestionSupported) {
      this.mSession.enableEffectSuggestion(true);
    }
  };

  private handleEffectSuggestionChangeOff(): void {
    try {
      HiLog.d(TAG, 'handleEffectSuggestionChangeOff');
    } catch (e) {
      HiLog.e(TAG, `handleEffectSuggestionChangeOff err:${e}`);
    }
  }

  public setTimeLapseInterval(interval: number): void {
    this.mSession.setTimeLapseInterval(interval);
  }

  public getTimeLapseInterval(): number {
    return this.mSession.getTimeLapseInterval();
  }

  public getTimeLapseIntervalRange(): number[] {
    return this.mSession.getTimeLapseIntervalRange();
  }

  public setTimeLapseRecordState(state: camera.TimeLapseRecordState): void {
    this.mSession.setTimeLapseRecordState(state);
  }

  private handleSmoothZoomInfoAvailableOff(): void {
    try {
      this.mSession?.off('smoothZoomInfoAvailable', this.mSmoothZoomInfoCallback);
      HiLog.d(TAG, 'handleSmoothZoomInfoAvailableOff');
    } catch (e) {
      HiLog.e(TAG, `handleSmoothZoomInfoAvailableOff err:${e}`);
    }
  }

  private setSessionUsage(tagMessage): void {
  }

  public setAudioZoomExtra(value: Record<string, string>): void {
    this.mSession?.setAudioZoomExtra(value);
    HiLog.i(TAG, 'SessionWrap setUsage AudioZoom.');
  }

  public setShortVideoIndex(index: number): void {
    HiLog.i(TAG, 'setShortVideoIndex' + index);
  }

  /**********************************************近物对焦 start***********************************************/

  public getFocusRange(): camera.FocusRangeType {
    return this.mSession.getFocusRange();
  }

  public setFocusRange(type: camera.FocusRangeType): void {
    this.mSession.setFocusRange(type);
    HiLog.i(TAG, 'SessionWrap setUsage AudioZoom.');
  }

  /**********************************************近物对焦 end***********************************************/

  /**********************************************人像追焦 start***********************************************/
  public getFocusDriven(): camera.FocusDrivenType {
    return this.mSession.getFocusDriven();
  }

  public setFocusDriven(type: camera.FocusDrivenType): void {
    this.mSession.setFocusDriven(type);
    HiLog.i(TAG, 'SessionWrap setFocusDriven.');
  }

  public setFocusTrackingMode(mode: camera.FocusTrackingMode): void {
    this.mSession.setFocusTrackingMode(mode);
    HiLog.i(TAG, 'SessionWrap setFocusTrackingMode.');
  }

  /**********************************************人像追焦 end***********************************************/
  /**********************************************人像留色 start***********************************************/

  public getColorReservation(): camera.ColorReservationType {
    return this.mSession.getColorReservation();
  }

  public setColorReservation(type: camera.ColorReservationType): void {
    this.mSession.setColorReservation(type);
    HiLog.i(TAG, 'SessionWrap setColorReservation.');
  }

  /**********************************************人像留色 end***********************************************/

  public setWindNoiseSuppression(value: Record<string, string>): void {
    this.mSession.setWindNoiseSuppression(value);
    HiLog.i(TAG, 'SessionWrap setUsage WindNoiseSuppression.');
  }

  public getIsCompositionSuggestionSupported(): boolean {
    let isCompositionSuggestionSupported = this.mSession.getIsCompositionSuggestionSupported();
    return isCompositionSuggestionSupported;
  }

  private handleCompositionBeginNotice: AsyncCallback<void> =
    (err) => {
      HiLog.i(TAG, `onRecvAICompositionBeginNotice`);
      workerCallback.onRecvAICompositionBeginNotice();
    };

  // @ts-ignore
  private handleCompositionCalibrationData: AsyncCallback<camera.CompositionCalibrationInfo> =
    // @ts-ignore
    (err, data: camera.CompositionCalibrationInfo) => {
      workerCallback.onRecvAICompositionCalibrationData(data);
    };

  // @ts-ignore
  private handleCompositionConfig: AsyncCallback<camera.CompositionConfigInfo> =
    // @ts-ignore
    (err, data: camera.CompositionConfigInfo) => {
      workerCallback.onRecvAICompositionConfigData(data);
    };

  // @ts-ignore
  private handleCompositionEnd: AsyncCallback<camera.CompositionEndInfo> = (err, data: camera.CompositionEndInfo) => {
    workerCallback.onRecvAICompositionEndData(data);
  };

  public enableCompositionSuggestion(enable: boolean): void {
    this.mIsCompositionSuggestionSupported = this.mSession.getIsCompositionSuggestionSupported();
    HiLog.i(TAG, `enableCompositionSuggestion mIsCompositionSuggestionSupported: ` +
      `${this.mIsCompositionSuggestionSupported}, enable: ${enable}`);
    if (!this.mIsCompositionSuggestionSupported) {
      return;
    }
    if (enable) {
      this.mSession.enableCompositionSuggestion(true);
      this.handleCompositionSuggestionOn();
    } else {
      this.handleCompositionSuggestionOff();
      this.mSession.enableCompositionSuggestion(false);
    }
  }

  private handleCompositionSuggestionOn(): void {
    try {
      this.mSession?.on('compositionBegin', this.handleCompositionBeginNotice);
      this.mSession?.on('compositionCalibration', this.handleCompositionCalibrationData);
      this.mSession?.on('compositionConfig', this.handleCompositionConfig);
      this.mSession?.on('compositionEnd', this.handleCompositionEnd);
      HiLog.d(TAG, 'handleCompositionSuggestionOn success.');
    } catch (e) {
      HiLog.e(TAG, `handleCompositionSuggestionOn err:${e}`);
    }
  }

  private handleCompositionSuggestionOff(): void {
    try {
      this.mSession?.off('compositionBegin');
      this.mSession?.off('compositionCalibration');
      this.mSession?.off('compositionConfig');
      this.mSession?.off('compositionEnd');
      HiLog.d(TAG, 'handleCompositionSuggestionOff success.');
    } catch (e) {
      HiLog.e(TAG, `handleCompositionSuggestionOff err:${e}`);
    }
  }

  public handleLightStatusOn(): void {
    HiLog.i(TAG, 'handleLightStatusOn');
    try {
      this.mSession?.on('lightStatusChange', this.handleLightStatusCallback);
    } catch (e) {
      HiLog.e(TAG, `handleLightStatusOn err:${e}`);
    }
  }

  public handleLightStatusOff(): void {
    HiLog.i(TAG, 'handleLightStatusOff');
    try {
      this.mSession?.off('lightStatusChange');
      // @ts-ignore
      workerCallback.onRecvLightStatusData(LightStatus.DEFAULT);
    } catch (e) {
      HiLog.e(TAG, `handleLightStatusOff err:${e}`);
    }
  }

  private handleLightStatusCallback: AsyncCallback<camera.LightStatus> =
    (err, data: camera.LightStatus) => {
      if (err) {
        HiLog.e(TAG, `handleLightStatusOff err: ${simpleStringify(err)}}`);
        return;
      }
      HiLog.i(TAG, `lightStatusCallback: ${data}`);
      workerCallback.onRecvLightStatusData(data);
    };

  private sessionAddOutputWrap(output): void {
    let canAddOutput = this.mSession.canAddOutput(output); // 针对相机主流的拍照流、录像流、预览流执行校验
    HiLog.i(TAG, `sessionAddOutputWrap canAddOutput: ${canAddOutput}`);
    if (canAddOutput) {
      this.mSession.addOutput(output);
    } else {
      this.mCanAddOutput = false; // 辅/小流暂不触发底层能力融合
      HiLog.e(TAG, `sessionAddOutputWrap failed!`);
    }
  }

  public getCanAddOutput(): boolean { // 获取该次启流动作主要输出流是否参数校验成功,否则需底层能力融合
    if (!this.mCanAddOutput) {
      this.mCanAddOutput = true;
      return false;
    }
    return this.mCanAddOutput;
  }

  public setFilterType(filterType: number): void {
    HiLog.i(TAG, `setFilterType: ${filterType}`);
    this.mSession.setFilterType(filterType);
  }

  public setEffectAudioStage(isSupportAudioStage: boolean): void {
    if (isSupportAudioStage) {
      this.mSession?.setAudioEffectStage(true);
      HiLog.i(TAG, 'setAudioEffectStage: True');
    } else {
      this.mSession?.setAudioEffectStage(false);
      HiLog.i(TAG, 'setAudioEffectStage: False');
    }
  }
}