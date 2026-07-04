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
import camera from '@ohos.multimedia.camera';
import type { AsyncCallback, BusinessError, ErrorCallback } from '@ohos.base';
import colorSpaceManager from '@ohos.graphics.colorSpaceManager';
import lazy { ModeType } from '../../../../mode/ModeType';
import lazy { HiLog } from '../../../../utils/HiLog';
import lazy { ModeTransform } from '../../../../mode/ModeTransform';
import lazy { App2CameraModeMessage } from '../../../DataType';
import type { ZoomPointInfo } from '../../../../function/zoombar/ZoomParam';
import lazy { FlashMode } from '../../../../function/enumbase/FlashMode';
import lazy { audio } from '../../../../utils/LazyImportUtil';
import lazy { JSON } from '@kit.ArkTS';
import type { geoLocationManager } from '@kit.LocationKit';
import lazy { simpleStringify } from '../../../../utils/SimpleStringify';

/* instrument ignore file */
const TAG: string = 'BaseSession';

export class BaseSession {
  private mSession: camera.PhotoSession | camera.VideoSession
    //| camera.NightPhotoSession | camera.PortraitPhotoSession |
  //   camera.ProfessionalPhotoSession | camera.ProfessionalVideoSession | camera.QuickShotPhotoSession |
  // // @ts-ignore
  //   camera.LightPaintingPhotoSession | camera.TimeLapsePhotoSession | camera.PanoramaPhotoSession | camera.StitchingPhotoSession | camera.StagePhotoSession | camera.StageVideoSession;
  private mMode: ModeType;

  constructor(manager: camera.CameraManager, mode: ModeType, cameraModeMessage: App2CameraModeMessage) {
    try {
      this.mSession = manager.createSession(ModeTransform.modeType2SceneMode(mode, cameraModeMessage));
    } catch (err) {
      HiLog.e(TAG, `createSession mode: ${mode}, error: ${JSON.stringify(err)}!`);
    }
    this.mMode = mode;
    HiLog.i(TAG, `baseSession create successful, ModeType: ${mode}.`);
  }

  on(type: 'error', callback: ErrorCallback<BusinessError<void>>): void;

  on(type: 'featureDetection', callback: AsyncCallback<camera.SceneFeatureDetectionResult>, subType: camera.SceneFeatureType): void;

  // @ts-ignore
  on(type: 'focusStateChange', callback: AsyncCallback<camera.FocusState, void>): void;

  on(type: 'smoothZoomInfoAvailable', callback: AsyncCallback<camera.SmoothZoomInfo, void>): void;

  on(type: 'macroStatusChanged', callback: AsyncCallback<boolean, void>): void;

  on(type: 'featureDetectionStatus', callback: AsyncCallback<camera.SceneFeatureDetectionResult, void>,
    subType: camera.SceneFeatureType): void;

  on(type: 'isoInfoChange', callback: AsyncCallback<camera.IsoInfo, void>): void;

  on(type: 'exposureInfoChange', callback: AsyncCallback<camera.ExposureInfo, void>): void;

  on(type: 'apertureInfoChange', callback: AsyncCallback<camera.ApertureInfo, void>): void;

  on(type: 'luminationInfoChange', callback: AsyncCallback<camera.LuminationInfo, void>): void;

  on(type: 'abilityChange', callback: AsyncCallback<void, void>): void;

  on(type: 'slowMotionStatus', callback: AsyncCallback<number, void>): void;

  // @ts-ignore
  on(type: 'zoomInfoChange', callback: AsyncCallback<camera.ZoomInfo, void>): void;

  on(type: 'lcdFlashStatus', callback: AsyncCallback<camera.LcdFlashStatus, void>): void;

  // @ts-ignore
  on(type: 'imageStabilizationGuide', callback: AsyncCallback<camera.ImageStabilizationGuideInfo>): void;

  on(type: 'effectSuggestionChange', callback: AsyncCallback<number, void>): void;

  on(type: 'tryAEInfoChange', callback: AsyncCallback<camera.TryAEInfo>): void;

  // @ts-ignore
  on(type: 'targetChange', callback: AsyncCallback<camera.StitchingTargetInfo>): void;

  // @ts-ignore
  on(type: 'captureStateChange', callback: AsyncCallback<camera.StitchingCaptureState>): void;

  // @ts-ignore
  on(type: 'capture', callback: AsyncCallback<camera.StitchingCaptureInfo>): void;

  // @ts-ignore
  on(type: 'stitchingHint', callback: AsyncCallback<camera.StitchingHint>): void;

  on(type: 'compositionBegin', callback: AsyncCallback<void, void>): void;

  // @ts-ignore
  on(type: 'compositionCalibration', callback: AsyncCallback<camera.CompositionCalibrationInfo, void>);

  // @ts-ignore
  on(type: 'compositionConfig', callback: AsyncCallback<camera.CompositionConfigInfo, void>);

  // @ts-ignore
  on(type: 'compositionEnd', callback: AsyncCallback<camera.CompositionEndInfo, void>);

  // @ts-ignore
  on(type: 'lightStatusChange', callback: AsyncCallback<camera.LightStatus, void>);

  // @ts-ignore
  on(type: 'apertureEffectChange', callback: AsyncCallback<camera.ApertureEffect, void>);

  public on(type: unknown, callback: unknown, subType?: camera.SceneFeatureType): void {
    if (!this.mSession) {
      HiLog.e(TAG, 'session is undefined.');
      return;
    }
    try {
      switch (type) {
        case 'error':
          this.mSession.on('error', callback as ErrorCallback<BusinessError<void>>);
          break;
        case 'focusStateChange':
          this.mSession.on('focusStateChange', callback as AsyncCallback<camera.FocusState, void>);
          break;
        case 'smoothZoomInfoAvailable':
          this.mSession.on('smoothZoomInfoAvailable', callback as AsyncCallback<camera.SmoothZoomInfo, void>);
          break;
        case 'macroStatusChanged':
          this.mSession.on('macroStatusChanged', callback as AsyncCallback<boolean, void>);
          break;
       case 'featureDetectionStatus':
         if (subType === undefined) {
           HiLog.e(TAG, 'featureDetectionStatus, subType is required');
           break;
         }
       //TODO  this.mSession.on('featureDetectionStatus', subType, callback as AsyncCallback<camera.TripodDetectionResult>);
         break;
       case 'isoInfoChange':
         //TODO    this.mSession.on('isoInfoChange', callback as AsyncCallback<camera.IsoInfo, void>);
         break;
       case 'exposureInfoChange':
         //TODO    this.mSession.on('exposureInfoChange', callback as AsyncCallback<camera.ExposureInfo, void>);
         break;
       case 'apertureInfoChange':
         //TODO    this.mSession.on('apertureInfoChange', callback as AsyncCallback<camera.ApertureInfo, void>);
         break;
       case 'luminationInfoChange':
         //TODO     this.mSession.on('luminationInfoChange', callback as AsyncCallback<camera.LuminationInfo, void>);
         break;
       case 'abilityChange':
         //TODO      this.mSession.on('abilityChange', callback as AsyncCallback<void, void>);
         break;
       case 'slowMotionStatus':
         //TODO      this.mSession.on('slowMotionStatus', callback as AsyncCallback<boolean, void>);
         break;
        case 'zoomInfoChange':
          // @ts-ignore
          this.mSession.on('zoomInfoChange', callback as AsyncCallback<camera.ZoomInfo, void>);
          break;
        case 'lcdFlashStatus':
          this.mSession.on('lcdFlashStatus', callback as AsyncCallback<camera.LcdFlashStatus, void>);
          break;
        case 'imageStabilizationGuide':
          // @ts-ignore
          this.mSession.on('imageStabilizationGuide', callback as AsyncCallback<camera.ImageStabilizationGuideInfo, void>);
          break;
        case 'effectSuggestionChange':
          //TODO         this.mSession.on('effectSuggestionChange', callback as AsyncCallback<boolean, void>);
          break;
        case 'tryAEInfoChange':
          //TODO      this.mSession.on('tryAEInfoChange', callback as AsyncCallback<camera.TryAEInfo, void>);
          break;
        case 'targetChange':
          // @ts-ignore
          this.mSession.on('targetChange', callback as AsyncCallback<camera.StitchingTargetInfo, void>);
          break;
        case 'captureStateChange':
          // @ts-ignore
          this.mSession.on('captureStateChange', callback as AsyncCallback<camera.StitchingCaptureState, void>);
          break;
        case 'capture':
          //@ts-ignore
          this.mSession.on('capture', callback as AsyncCallback<camera.StitchingCaptureInfo, void>);
          break;
        case 'stitchingHint':
          //@ts-ignore
          this.mSession.on('stitchingHint', callback as AsyncCallback<camera.StitchingHint, void>);
          break;
      case 'compositionBegin':
        //TODO     this.mSession.on('compositionBegin', callback as AsyncCallback<void, void>);
        break;
      case 'compositionCalibration':
        //TODO    this.mSession.on('compositionCalibration',
          // @ts-ignore
        //TODO        callback as AsyncCallback<camera.CompositionCalibrationInfo, void>);
        break;
        case 'featureDetection':
          if (subType === undefined) {
            HiLog.e(TAG, 'featureDetection, subType is required');
            break;
          }
          // @ts-ignore
          this.mSession.on('featureDetection', subType, callback as AsyncCallback<camera.SceneFeatureDetectionResult>);
          break;
        case 'compositionConfig':
          // @ts-ignore
          this.mSession.on('compositionConfig', callback as AsyncCallback<camera.CompositionConfigInfo, void>);
          break;
        case 'compositionEnd':
          // @ts-ignore
          this.mSession.on('compositionEnd', callback as AsyncCallback<camera.CompositionEndInfo, void>);
          break;
 /*       case 'lightStatusChange':
          // @ts-ignore
          this.mSession.on('lightStatusChange', callback as AsyncCallback<camera.LightStatus, void>);
          break;*/
 /*       case 'apertureEffectChange':
          // @ts-ignore
          this.mSession.on('apertureEffectChange', callback as AsyncCallback<camera.ApertureEffect, void>);
          break;*/
        default:
          HiLog.e(TAG, `type is not identified, type: ${type}`);
      }
    } catch (e) {
      HiLog.e(TAG, `session on error: ${JSON.stringify(e)}.`);
    }
  }

  off(type: 'error', callback?: ErrorCallback<BusinessError<void>>): void;

  off(type: 'focusStateChange', callback?: AsyncCallback<camera.FocusState, void>): void;

  off(type: 'smoothZoomInfoAvailable', callback?: AsyncCallback<camera.SmoothZoomInfo, void>): void;

  off(type: 'featureDetection', callback?: AsyncCallback<camera.SceneFeatureDetectionResult>): void;

  // @ts-ignore
  off(type: 'macroStatusChanged', callback?: AsyncCallback<boolean, void>): void;

  off(type: 'featureDetectionStatus', callback?: AsyncCallback<camera.SceneFeatureDetectionResult, void>): void;

  off(type: 'isoInfoChange', callback?: AsyncCallback<camera.IsoInfo, void>): void;

  off(type: 'exposureInfoChange', callback?: AsyncCallback<camera.ExposureInfo, void>): void;

  off(type: 'apertureInfoChange', callback?: AsyncCallback<camera.ApertureInfo, void>): void;

  off(type: 'luminationInfoChange', callback?: AsyncCallback<camera.LuminationInfo, void>): void;

  off(type: 'abilityChange', callback?: AsyncCallback<void, void>): void;

  off(type: 'slowMotionStatus', callback?: AsyncCallback<number, void>): void;

  // @ts-ignore
  off(type: 'zoomInfoChange', callback?: AsyncCallback<camera.ZoomInfo, void>): void;

  off(type: 'lcdFlashStatus', callback?: AsyncCallback<camera.LcdFlashStatus, void>): void;

  // @ts-ignore
  off(type: 'imageStabilizationGuide', callback?: AsyncCallback<camera.ImageStabilizationGuideInfo>): void;

  off(type: 'effectSuggestionChange', callback?: AsyncCallback<number, void>): void;

  off(type: 'tryAEInfoChange', callback?: AsyncCallback<camera.TryAEInfo>): void;

  // @ts-ignore
  off(type: 'targetChange', callback: AsyncCallback<camera.StitchingTargetInfo>): void;

  // @ts-ignore
  off(type: 'captureStateChange', callback: AsyncCallback<camera.StitchingCaptureState>): void;

  // @ts-ignore
  off(type: 'capture', callback: AsyncCallback<camera.StitchingCaptureInfo>): void;

  // @ts-ignore
  off(type: 'stitchingHint', callback: AsyncCallback<camera.StitchingHint>): void;

  off(type: 'compositionBegin', callback?: AsyncCallback<void, void>): void;

  // @ts-ignore
  off(type: 'compositionCalibration', callback?: AsyncCallback<void, void>);

  // @ts-ignore
  off(type: 'compositionConfig', callback?: AsyncCallback<void, void>);

  // @ts-ignore
  off(type: 'compositionEnd', callback?: AsyncCallback<void, void>);

  // @ts-ignore
  off(type: 'lightStatusChange', callback?: AsyncCallback<camera.LightStatus, void>);

  // @ts-ignore
  off(type: 'apertureEffectChange', callback?: AsyncCallback<camera.ApertureEffect, void>);

  public off(type: unknown, callback?: unknown): void {
    if (!this.mSession) {
      HiLog.e(TAG, 'session is undefined.');
      return;
    }
    try {
      switch (type) {
        case 'error':
          this.mSession.off('error', callback as ErrorCallback<BusinessError<void>>);
          break;
        case 'focusStateChange':
          this.mSession.off('focusStateChange', callback as AsyncCallback<camera.FocusState, void>);
          break;
        case 'smoothZoomInfoAvailable':
          this.mSession.off('smoothZoomInfoAvailable', callback as AsyncCallback<camera.SmoothZoomInfo, void>);
          break;
        case 'macroStatusChanged':
          this.mSession.off('macroStatusChanged', callback as AsyncCallback<boolean, void>);
          break;
        case 'featureDetectionStatus':
          if (this.isSceneFeatureSupported(camera.SceneFeatureType.MOON_CAPTURE_BOOST)) {
            //TODO       this.mSession.off('featureDetectionStatus', camera.SceneFeatureType.MOON_CAPTURE_BOOST, callback as AsyncCallback<camera.SceneFeatureDetectionResult>);
          }
          if (this.isSceneFeatureSupported(camera.SceneFeatureType.LOW_LIGHT_BOOST)) {
            //TODO         this.mSession.off('moonCaptureBoostStatus', camera.SceneFeatureType.LOW_LIGHT_BOOST, callback as AsyncCallback<camera.SceneFeatureDetectionResult>);
          }
          break;
 /*       case 'isoInfoChange':
           this.mSession.off('isoInfoChange', callback as AsyncCallback<camera.IsoInfo, void>);
          break;*/
    /*    case 'exposureInfoChange':
          this.mSession.off('exposureInfoChange', callback as AsyncCallback<camera.ExposureInfo, void>);
          break;*/
/*        case 'apertureInfoChange':
          this.mSession.off('apertureInfoChange', callback as AsyncCallback<camera.ApertureInfo, void>);
          break;*/
   /*     case 'luminationInfoChange':
           this.mSession.off('luminationInfoChange', callback as AsyncCallback<camera.LuminationInfo, void>);
          break;*/
        case 'abilityChange':
          //TODO       this.mSession.off('abilityChange', callback as AsyncCallback<void, void>);
          break;
      /*  case 'slowMotionStatus':
           this.mSession.off('slowMotionStatus', callback as AsyncCallback<boolean, void>);
          break;*/
     /*   case 'zoomInfoChange':
          // @ts-ignore
          this.mSession.off('zoomInfoChange', callback as AsyncCallback<camera.ZoomInfo, void>);
          break;*/
        case 'lcdFlashStatus':
          this.mSession.off('lcdFlashStatus', callback as AsyncCallback<camera.LcdFlashStatus, void>);
          break;
        case 'imageStabilizationGuide':
          // @ts-ignore
          this.mSession.off('imageStabilizationGuide', callback as AsyncCallback<camera.ImageStabilizationGuideInfo, void>);
          break;
        case 'effectSuggestionChange':
          //TODO       this.mSession.off('effectSuggestionChange', callback as AsyncCallback<boolean, void>);
          break;
        case 'featureDetection':
          // @ts-ignore
          this.mSession.off('featureDetection', camera.SceneFeatureType.CONSTELLATION_DRAWING);
          break;
    /*    case 'tryAEInfoChange':
           this.mSession.off('tryAEInfoChange', callback as AsyncCallback<camera.TryAEInfo, void>);
          break;*/
        case 'targetChange':
          // @ts-ignore
          this.mSession.off('targetChange', callback as AsyncCallback<camera.StitchingTargetInfo, void>);
          break;
        case 'captureStateChange':
          // @ts-ignore
          this.mSession.off('captureStateChange', callback as AsyncCallback<camera.StitchingTargetInfo, void>);
          break;
        case 'capture':
          // @ts-ignore
          this.mSession.off('capture', callback as AsyncCallback<camera.StitchingCaptureInfo, void>);
          break;
        case 'stitchingHint':
          // @ts-ignore
          this.mSession.off('stitchingHint', callback as AsyncCallback<camera.StitchingHint, void>);
          break;
   /*     case 'compositionBegin':
          this.mSession.off('compositionBegin', callback as AsyncCallback<void, void>);
          break;*/
/*        case 'compositionCalibration':
            this.mSession.off('compositionCalibration',
            // @ts-ignore
              callback as AsyncCallback<camera.CompositionCalibrationInfo, void>);
          break;*/
        case 'compositionConfig':
          //TODO     this.mSession.off('compositionConfig',
            // @ts-ignore
          //TODO      callback as AsyncCallback<camera.CompositionConfigInfo, void>);
          break;
        case 'compositionEnd':
          // @ts-ignore
          this.mSession.off('compositionEnd', callback as AsyncCallback<camera.CompositionEndInfo, void>);
          break;
        case 'lightStatusChange':
          //TODO           this.mSession.off('lightStatusChange', callback as AsyncCallback<camera.LightStatus, void>);
          break;
    /*    case 'apertureEffectChange':
          // @ts-ignore
          this.mSession.off('apertureEffectChange', callback as AsyncCallback<camera.ApertureEffect, void>);
          break;*/
   /*     case 'apertureEffectChange':
          // @ts-ignore
          this.mSession.off('apertureEffectChange', callback as AsyncCallback<camera.ApertureEffect, void>);
          break;*/
        default:
          HiLog.e(TAG, `type is not identified, type: ${type}`);
      }
    } catch (e) {
      HiLog.e(TAG, `session off error:${type}, ${JSON.stringify(e)}.`);
    }
  }

  // Session
  public beginConfig(): void {
    this.mSession?.beginConfig();
  }

  public async commitConfig(): Promise<void> {
    await this.mSession?.commitConfig();
  }

  public canAddInput(cameraInput: camera.CameraInput): boolean {
    return this.mSession?.canAddInput(cameraInput);
  }

  public addInput(cameraInput: camera.CameraInput): void {
    this.mSession?.addInput(cameraInput);
  }

  public removeInput(cameraInput: camera.CameraInput): void {
    this.mSession?.removeInput(cameraInput);
  }

  public canAddOutput(cameraOutput: camera.CameraOutput): boolean {
    return this.mSession?.canAddOutput(cameraOutput);
  }

  public addOutput(cameraOutput: camera.CameraOutput): void {
    this.mSession?.addOutput(cameraOutput);
  }

  public removeOutput(cameraOutput: camera.CameraOutput): void {
    this.mSession?.removeOutput(cameraOutput);
  }

  public async start(): Promise<void> {
    await this.mSession?.start();
  }

  public async stop(): Promise<void> {
    await this.mSession?.stop();
  }

  public async release(): Promise<void> {
    await this.mSession?.release();
  }

  // 录像防抖
  public isVideoStabilizationModeSupported(vsMode: camera.VideoStabilizationMode): boolean {
    if ('isVideoStabilizationModeSupported' in this.mSession) {
      try {
        return this.mSession.isVideoStabilizationModeSupported(vsMode);
      } catch (err) {
        HiLog.e(TAG, `isVideoStabilizationModeSupported err. ${err?.code}`);
        return false;
      }
    } else {
      HiLog.e(TAG, `Session has not isVideoStabilizationModeSupported, mode: ${this.mMode}.`);
    }
    return false;
  }

  public getActiveVideoStabilizationMode(): camera.VideoStabilizationMode {
    if ('getActiveVideoStabilizationMode' in this.mSession) {
        return this.mSession.getActiveVideoStabilizationMode();
    } else {
      HiLog.e(TAG, `Session has not getActiveVideoStabilizationMode, mode: ${this.mMode}.`);
    }
    return camera.VideoStabilizationMode.OFF;
  }

  public setVideoStabilizationMode(mode: camera.VideoStabilizationMode): void {
    if ('setVideoStabilizationMode' in this.mSession) {
          this.mSession.setVideoStabilizationMode(mode);
    } else {
      HiLog.e(TAG, `Session has not setVideoStabilizationMode, mode: ${this.mMode}.`);
    }
  }

  // 人像效果
  public getSupportedPortraitEffects(): camera.PortraitEffect[] {
    if ('getSupportedPortraitEffects' in this.mSession) {
      //TODO         return this.mSession.getSupportedPortraitEffects();
    } else {
      HiLog.e(TAG, `Session has not getSupportedPortraitEffects, mode: ${this.mMode}.`);
    }
    return [];
  }

  public getPortraitEffect(): camera.PortraitEffect {
    if ('getPortraitEffect' in this.mSession) {
      //TODO       return this.mSession.getPortraitEffect();
    } else {
      HiLog.e(TAG, `Session has not getPortraitEffect, mode: ${this.mMode}.`);
    }
    return camera.PortraitEffect.OFF;
  }

  public setPortraitEffect(effect: camera.PortraitEffect): void {
    if ('setPortraitEffect' in this.mSession) {
      //TODO       this.mSession.setPortraitEffect(effect);
    } else {
      HiLog.e(TAG, `Session has not setPortraitEffect, mode: ${this.mMode}.`);
    }
  }

  // Apertures
  public getSupportedVirtualApertures(): number[] {
    if ('getSupportedVirtualApertures' in this.mSession) {
      //TODO      return this.mSession.getSupportedVirtualApertures();
    } else {
      HiLog.e(TAG, `Session has not getSupportedVirtualApertures, mode: ${this.mMode}.`);
    }
    return [];
  }

  public getVirtualAperture(): number {
    if ('getVirtualAperture' in this.mSession) {
      //TODO      return this.mSession.getVirtualAperture();
    } else {
      HiLog.e(TAG, `Session has not getVirtualAperture, mode: ${this.mMode}.`);
    }
    return 0;
  }

  public setVirtualAperture(aperture: number): void {
    if ('setVirtualAperture' in this.mSession) {
      //TODO          this.mSession.setVirtualAperture(aperture);
    } else {
      HiLog.e(TAG, `Session has not setVirtualAperture, mode: ${this.mMode}.`);
    }
  }

  public getSupportedPhysicalApertures(): camera.PhysicalAperture[] {
    if ('getSupportedPhysicalApertures' in this.mSession) {
      //TODO       return this.mSession.getSupportedPhysicalApertures();
    } else {
      HiLog.e(TAG, `Session has not getSupportedPhysicalApertures, mode: ${this.mMode}.`);
    }
    return [];
  }

  public getIsPortraitThemeSupported(): boolean {
    if ('isPortraitThemeSupported' in this.mSession) {
      try {
        //TODO         return this.mSession.isPortraitThemeSupported();
      } catch (e) {
        HiLog.e(TAG, `isPortraitThemeSupported error`);
        return false;
      }
    } else {
      HiLog.e(TAG, `Session has not isPortraitThemeSupported, mode: ${this.mMode}.`);
    }
    return false;
  }

  public getPhysicalAperture(): number {
    if ('getPhysicalAperture' in this.mSession) {
      try {
        //TODO           return this.mSession.getPhysicalAperture();
      } catch (e) {
        HiLog.e(TAG, 'getPhysicalAperture error.');
        return 0;
      }
    } else {
      HiLog.e(TAG, `Session has not getPhysicalAperture, mode: ${this.mMode}.`);
    }
    return 0;
  }

  public setPhysicalAperture(aperture: number): void {
    if ('setPhysicalAperture' in this.mSession) {
      //TODO        this.mSession.setPhysicalAperture(aperture);
    } else {
      HiLog.e(TAG, `Session has not setPhysicalAperture, mode: ${this.mMode}.`);
    }
  }

  public getSupportedLightPaintings(): camera.LightPaintingType[] {
    if ('getSupportedLightPaintingTypes' in this.mSession) {
      //TODO          return this.mSession.getSupportedLightPaintingTypes();
    } else {
      HiLog.e(TAG, `Session has not getSupportedLightPaintingTypes, mode: ${this.mMode}.`);
    }
    return [];
  }

  public getLightPainting(): camera.LightPaintingType {
    if ('getLightPaintingType' in this.mSession) {
      //TODO       return this.mSession.getLightPaintingType();
    } else {
      HiLog.e(TAG, `Session has not getLightPaintingType, mode: ${this.mMode}.`);
    }
    return null;
  }

  public setLightPainting(type: camera.LightPaintingType): void {
    if ('setLightPaintingType' in this.mSession) {
      //TODO       this.mSession.setLightPaintingType(type);
    } else {
      HiLog.e(TAG, `Session has not setLightPaintingType, mode: ${this.mMode}.`);
    }
  }

  public triggerLighting(): void {
    if ('setFlashMode' in this.mSession) {
      //TODO   this.mSession.setFlashMode(FlashMode.ON);
    } else {
      HiLog.e(TAG, `Session has not setFlashMode, mode: ${this.mMode}.`);
    }
  }

  // 曝光
  public getSupportedExposureRange(): number[] {
    if ('getSupportedExposureRange' in this.mSession) {
      //TODO       return this.mSession.getSupportedExposureRange();
    } else {
      HiLog.e(TAG, `Session has not getSupportedExposureRange, mode: ${this.mMode}.`);
    }
    return [];
  }

  public getExposure(): number {
    if ('getExposure' in this.mSession) {
      //TODO       return this.mSession.getExposure();
    } else {
      HiLog.e(TAG, `Session has not getExposure, mode: ${this.mMode}.`);
    }
    return 0;
  }

  public setExposure(exposure: number): void {
    HiLog.i(TAG, `setExposure: ${exposure}.`);
    try {
      //TODO      this.mSession.setExposure(exposure);
    } catch (err) {
      HiLog.e(TAG, `setWhiteBalance catch err, mode: ${this.mMode}, err: ${err}.`);
    }
  }

  // 闪光灯
  public hasFlash(): boolean {
    if ('hasFlash' in this.mSession) {
      return this.mSession.hasFlash();
    } else {
      HiLog.e(TAG, `Session has not hasFlash, mode: ${this.mMode}.`);
    }
    return false;
  }

  public isFlashModeSupported(flashMode: camera.FlashMode): boolean {
    if ('isFlashModeSupported' in this.mSession) {
      return this.mSession.isFlashModeSupported(flashMode);
    } else {
      HiLog.e(TAG, `Session has not isFlashModeSupported, mode: ${this.mMode}.`);
    }
    return false;
  }

  // @ts-ignore
  public getSupportedNightSubModeTypes(): camera.NightSubModeType[] {
    if ('getSupportedNightSubModeTypes' in this.mSession) {
      //TODO     return this.mSession.getSupportedNightSubModeTypes();
    } else {
      HiLog.e(TAG, `Session has not get Supported Night SubModeTypes, mode: ${this.mMode}.`);
    }
    return [];
  }

  // @ts-ignore
  public setNightSubModeType(subMode: camera.NightSubModeType): void {
    HiLog.i(TAG, `Session setNightSubModeType: ${subMode}.`);
    if ('setNightSubModeType' in this.mSession) {
      //TODO     this.mSession.setNightSubModeType(subMode);
    } else {
      HiLog.e(TAG, `Session has not set Night SubModeType, mode: ${this.mMode}.`);
    }
  }

  public setLocation(location: geoLocationManager.Location): void {
    if (location && 'setLocation' in this.mSession) {
      HiLog.i(TAG, `Session setLocation`);
      //TODO     this.mSession.setLocation(location);
    } else {
      HiLog.e(TAG, `Session has not set Location, mode: ${this.mMode}`);
    }
  }

  public getFlashMode(): camera.FlashMode {
    if ('getFlashMode' in this.mSession) {
      return this.mSession.getFlashMode();
    } else {
      HiLog.e(TAG, `Session has not getFlashMode, mode: ${this.mMode}.`);
    }
    return camera.FlashMode.FLASH_MODE_CLOSE;
  }

  public setFlashMode(flashMode: camera.FlashMode): void {
    if ('setFlashMode' in this.mSession) {
      this.mSession.setFlashMode(flashMode);
    } else {
      HiLog.e(TAG, `Session has not setFlashMode, mode: ${this.mMode}.`);
    }
  }

  // @ts-ignore
  public setStitchingType(type: camera.StitchingType): void {
    // TODO 判断有效性
    // @ts-ignore
    this.mSession.setStitchingType(type);
  }

  // @ts-ignore
  public setStitchingDirection(direction: camera.Stitching): void {
    // TODO 判断有效性
    // @ts-ignore
    this.mSession.setStitchingDirection(direction);
  }

  public setMovingClockwise(move: boolean): void {
    //TODO    this.mSession.setMovingClockwise(move);
  }

  public isExposureModeSupported(aeMode: camera.ExposureMode): boolean {
    if ('isExposureModeSupported' in this.mSession) {
      return this.mSession.isExposureModeSupported(aeMode);
    } else {
      HiLog.e(TAG, `Session has not isExposureModeSupported, mode: ${this.mMode}.`);
    }
    return false;
  }

  public getExposureMode(): camera.ExposureMode {
    if ('getExposureMode' in this.mSession) {
      return this.mSession.getExposureMode();
    } else {
      HiLog.e(TAG, `Session has not getExposureMode, mode: ${this.mMode}.`);
    }
    return camera.ExposureMode.EXPOSURE_MODE_LOCKED;
  }

  public setSlowMotionDetectionArea(posData: camera.Rect): void {
    if ('setSlowMotionDetectionArea' in this.mSession) {
      //TODO      this.mSession.setSlowMotionDetectionArea(posData);
    } else {
      HiLog.e(TAG, `Session has not setSlowMotionDetectionArea, mode: ${this.mMode}.`);
    }
  }

  public isSlowMotionDetectionSupported(): boolean {
    if ('isSlowMotionDetectionSupported' in this.mSession) {
      //TODO       return this.mSession.isSlowMotionDetectionSupported();
    } else {
      HiLog.e(TAG, `Session has not isSlowMotionDetectionSupported, mode: ${this.mMode}.`);
    }
    return false;
  }

  public enableLcdFlash(enabled: boolean): void {
    if ('enableLcdFlash' in this.mSession) {
      this.mSession.enableLcdFlash(enabled);
    } else {
      HiLog.e(TAG, `Session has not enableLcdFlash, mode: ${this.mMode}.`);
    }
  }

  public isLcdFlashSupported(): boolean {
    if ('isLcdFlashSupported' in this.mSession) {
      return this.mSession.isLcdFlashSupported();
    } else {
      HiLog.e(TAG, `Session has not isLcdFlashSupported, mode: ${this.mMode}.`);
    }
    return false;
  }

  public enableImageStabilizationGuide(enabled: boolean): void {
    if ('enableImageStabilizationGuide' in this.mSession) {
      //TODO      this.mSession.enableImageStabilizationGuide(enabled);
    } else {
      HiLog.e(TAG, `Session has not enableImageStabilizationGuide, mode: ${this.mMode}.`);
    }
  }

  public isImageStabilizationGuideSupported(): boolean {
    if ('isImageStabilizationGuideSupported' in this.mSession) {
      //TODO     HiLog.i(TAG, 'isImageStabilizationGuideSupported: ' + this.mSession.isImageStabilizationGuideSupported());
      //TODO   return this.mSession.isImageStabilizationGuideSupported();
    } else {
      HiLog.e(TAG, `Session has not isImageStabilizationGuideSupported, mode: ${this.mMode}.`);
    }
    return false;
  }

  public setExposureMode(aeMode: camera.ExposureMode): void {
    if ('setExposureMode' in this.mSession) {
      this.mSession.setExposureMode(aeMode);
    } else {
      HiLog.e(TAG, `Session has not setExposureMode, mode: ${this.mMode}.`);
    }
  }

  // 对焦
  public getMeteringPoint(): camera.Point {
    if ('getMeteringPoint' in this.mSession) {
      return this.mSession.getMeteringPoint();
    } else {
      HiLog.e(TAG, `Session has not getMeteringPoint, mode: ${this.mMode}.`);
    }
    return { x: 0, y: 0 };
  }

  public setMeteringPoint(point: camera.Point): void {
    if ('setMeteringPoint' in this.mSession) {
      this.mSession.setMeteringPoint(point);
    } else {
      HiLog.e(TAG, `Session has not setMeteringPoint, mode: ${this.mMode}.`);
    }
  }

  public getExposureBiasRange(): number[] {
    if ('getExposureBiasRange' in this.mSession) {
      return this.mSession.getExposureBiasRange();
    } else {
      HiLog.e(TAG, `Session has not getExposureBiasRange, mode: ${this.mMode}.`);
    }
    return [];
  }

  public setExposureBias(exposureBias: number): void {
    if ('setExposureBias' in this.mSession) {
      this.mSession.setExposureBias(exposureBias);
    } else {
      HiLog.e(TAG, `Session has not setExposureBias, mode: ${this.mMode}.`);
    }
  }

  public getExposureValue(): number {
    if ('getExposureValue' in this.mSession) {
      return this.mSession.getExposureValue();
    } else {
      HiLog.e(TAG, `Session has not getExposureValue, mode: ${this.mMode}.`);
    }
    return 0;
  }

  public isFocusModeSupported(afMode: camera.FocusMode): boolean {
    if ('isFocusModeSupported' in this.mSession) {
      return this.mSession.isFocusModeSupported(afMode);
    } else {
      HiLog.e(TAG, `Session has not isFocusModeSupported, mode: ${this.mMode}.`);
    }
    return false;
  }

  public getFocusMode(): camera.FocusMode {
    if ('getExposureValue' in this.mSession) {
      return this.mSession.getFocusMode();
    } else {
      HiLog.e(TAG, `Session has not getFocusMode, mode: ${this.mMode}.`);
    }
    return camera.FocusMode.FOCUS_MODE_MANUAL;
  }

  public setFocusMode(afMode: camera.FocusMode): void {
    if ('setFocusMode' in this.mSession) {
      this.mSession.setFocusMode(afMode);
    } else {
      HiLog.e(TAG, `Session has not setFocusMode, mode: ${this.mMode}.`);
    }
  }

  public setFocusPoint(point: camera.Point): void {
    if ('setFocusPoint' in this.mSession) {
      HiLog.i(TAG, `setFocusPoint: ${simpleStringify(point)}`);
      this.mSession.setFocusPoint(point);
    } else {
      HiLog.e(TAG, `Session has not setFocusPoint, mode: ${this.mMode}.`);
    }
  }

  public getFocusPoint(): camera.Point {
    if ('getFocusPoint' in this.mSession) {
      return this.mSession.getFocusPoint();
    } else {
      HiLog.e(TAG, `Session has not getFocusPoint, mode: ${this.mMode}.`);
    }
    return { x: 0, y: 0 };
  }

  public getFocalLength(): number {
    if ('getFocalLength' in this.mSession) {
      return this.mSession.getFocalLength();
    } else {
      HiLog.e(TAG, `Session has not getFocalLength, mode: ${this.mMode}.`);
    }
    return 0;
  }

  public getZoomRatioRange(): number[] {
    if ('getZoomRatioRange' in this.mSession) {
      return this.mSession.getZoomRatioRange();
    } else {
      HiLog.e(TAG, `Session has not getZoomRatioRange, mode: ${this.mMode}.`);
    }
    return [];
  }

  public getZoomRatio(): number {
    if ('getZoomRatio' in this.mSession) {
      return this.mSession.getZoomRatio();
    } else {
      HiLog.e(TAG, `Session has not getZoomRatio, mode: ${this.mMode}.`);
    }
    return 0;
  }

  public setZoomRatio(zoomRatio: number): void {
    if ('setZoomRatio' in this.mSession) {
      this.mSession.setZoomRatio(zoomRatio);
    } else {
      HiLog.e(TAG, `Session has not setZoomRatio, mode: ${this.mMode}.`);
    }
  }

  public setSmoothZoom(targetRatio: number, mode?: camera.SmoothZoomMode): void {
    if ('setSmoothZoom' in this.mSession) {
      this.mSession.setSmoothZoom(targetRatio, mode);
    } else {
      HiLog.e(TAG, `Session has not setSmoothZoom, mode: ${this.mMode}.`);
    }
  }

  public prepareZoom(): void {
    if ('prepareZoom' in this.mSession) {
      this.mSession.prepareZoom();
    } else {
      HiLog.e(TAG, `Session has not prepareZoom, mode: ${this.mMode}.`);
    }
  }

  public unprepareZoom(): void {
    if ('unprepareZoom' in this.mSession) {
      this.mSession.unprepareZoom();
    } else {
      HiLog.e(TAG, `Session has not unprepareZoom, mode: ${this.mMode}.`);
    }
  }

  public getSupportedBeautyTypes(): camera.BeautyType[] {
    if ('getSupportedBeautyTypes' in this.mSession) {
      //TODO return this.mSession.getSupportedBeautyTypes();
    } else {
      HiLog.e(TAG, `Session has not getSupportedBeautyTypes, mode: ${this.mMode}.`);
    }
    return [];
  }

  public getSupportedBeautyRange(type: camera.BeautyType): number[] {
    if ('getSupportedBeautyRange' in this.mSession) {
      //TODO return this.mSession.getSupportedBeautyRange(type);
    } else {
      HiLog.e(TAG, `Session has not getSupportedBeautyRange, mode: ${this.mMode}.`);
    }
    return [];
  }

  public getBeauty(type: camera.BeautyType): number {
    if ('getBeauty' in this.mSession) {
      //TODO  return this.mSession.getBeauty(type);
    } else {
      HiLog.e(TAG, `Session has not getBeauty, mode: ${this.mMode}.`);
    }
    return 0;
  }

  public setBeauty(type: camera.BeautyType, value: number): void {
    if ('setBeauty' in this.mSession) {
      //TODO    this.mSession.setBeauty(type, value);
    } else {
      HiLog.e(TAG, `Session has not setBeauty, mode: ${this.mMode}.`);
    }
  }

  public setPortraitThemeType(value: number): void {
    if ('setPortraitThemeType' in this.mSession) {
      //TODO     this.mSession.setPortraitThemeType(value);
    } else {
      HiLog.e(TAG, `Session has not setPortraitThemeType, mode: ${this.mMode}.`);
    }
  }

  // @ts-ignore
  public getSessionFunctions(outputCapability: camera.CameraOutputCapability): camera.NightPhotoFunctions[] {
    if (outputCapability && 'getSessionFunctions' in this.mSession) {
      //TODO    const sessionFunctions = this.mSession.getSessionFunctions();
      //TODO      HiLog.i(TAG, `getSessionFunctions, supportedFunctions: ${JSON.stringify(sessionFunctions)}.`);
      //TODO     return sessionFunctions;
    } else {
      HiLog.e(TAG, `Session has not getSessionFunctions, mode: ${this.mMode}.`);
    }
    return [];
  }

  // @ts-ignore
  public getSessionConflictFunctions(): camera.NightPhotoConflictFunctions[] {
    if ('getSessionConflictFunctions' in this.mSession) {
      const sessionConflictFunctions = this.mSession.getSessionConflictFunctions();
      HiLog.i(TAG, `getSessionConflictFunctions, ConflictFunctions: ${JSON.stringify(sessionConflictFunctions)}.`);
      return sessionConflictFunctions;
    } else {
      HiLog.e(TAG, `Session has not getSessionConflictFunctions, mode: ${this.mMode}.`);
    }
    return [];
  }

  public getSupportedColorEffects(): camera.ColorEffectType[] {
    if ('getSupportedColorEffects' in this.mSession) {
      //TODO    const supportedColorEffectType = this.mSession.getSupportedColorEffects();
      //TODO    HiLog.i(TAG, `getSupportedColorEffects, supportedColorEffectType: ${supportedColorEffectType.toString()}.`);
      //TODO     return supportedColorEffectType;
    } else {
      HiLog.e(TAG, `Session has not getSupportedColorEffects, mode: ${this.mMode}.`);
    }
    return [];
  }

  public getColorEffect(): camera.ColorEffectType {
    if ('getColorEffect' in this.mSession) {
      //TODO      return this.mSession.getColorEffect();
    } else {
      HiLog.e(TAG, `Session has not getColorEffect, mode: ${this.mMode}.`);
    }
    return camera.ColorEffectType.NORMAL;
  }

  public isColorStyleSupported(): boolean {
    if ('isColorStyleSupported' in this.mSession) {
      //TODO     return this.mSession.isColorStyleSupported();
    } else {
      HiLog.e(TAG, `Session has not isColorStyleSupported, mode: ${this.mMode}.`);
      return false;
    }
  }

  // @ts-ignore
  public getDefaultColorStyleSettings(): camera.ColorStyleSetting[] {
    if ('getDefaultColorStyleSettings' in this.mSession) {
      //TODO      return this.mSession.getDefaultColorStyleSettings();
    } else {
      HiLog.e(TAG, `Session has not getDefaultColorStyleSettings, mode: ${this.mMode}.`);
      return [];
    }
  }

  // @ts-ignore
  public setColorStyleSetting(setting: camera.ColorStyleSetting): void {
    if (!setting) {
      HiLog.w(TAG, `set color style setting is invalid: ${setting}`);
      return;
    }

    if ('setColorStyleSetting' in this.mSession) {
      HiLog.i(TAG, `set color style param: ${JSON.stringify(setting)}`);
      //TODO    this.mSession.setColorStyleSetting(setting);
    }
  }

  // @ts-ignore
  public getColorStyleSetting(): camera.ColorStyleSetting {
    if ('getColorStyleSetting' in this.mSession) {
      //TODO    return this.mSession.getColorStyleSetting();
    } else {
      HiLog.e(TAG, `Session has not getColorStyleSetting, mode: ${this.mMode}.`);
      return null;
    }
  }

  public setColorEffect(type: camera.ColorEffectType): void {
    if ('setColorEffect' in this.mSession) {
      //TODO     this.mSession.setColorEffect(type);
    } else {
      HiLog.e(TAG, `Session has not setColorEffect, mode: ${this.mMode}.`);
    }
  }

  public getActiveColorSpace(): colorSpaceManager.ColorSpace {
    if ('getActiveColorSpace' in this.mSession) {
      return this.mSession.getActiveColorSpace();
    } else {
      HiLog.e(TAG, `Session has not getActiveColorSpace, mode: ${this.mMode}.`);
    }
    return colorSpaceManager.ColorSpace.UNKNOWN;
  }

  public getSupportedColorSpaces(): colorSpaceManager.ColorSpace[] {
    if ('getSupportedColorSpaces' in this.mSession) {
      return this.mSession.getSupportedColorSpaces();
    } else {
      HiLog.e(TAG, `Session has not getSupportedColorSpaces, mode: ${this.mMode}.`);
    }
    return [];
  }

  public setColorSpace(colorSpace: colorSpaceManager.ColorSpace): void {
    if ('setColorSpace' in this.mSession) {
      this.mSession.setColorSpace(colorSpace);
    } else {
      HiLog.e(TAG, `Session has not setColorSpace, mode: ${this.mMode}.`);
    }
  }

  public isMacroSupported(): boolean {
    if ('isMacroSupported' in this.mSession) {
      return this.mSession.isMacroSupported();
    } else {
      HiLog.e(TAG, `Session has not isMacroSupported, mode: ${this.mMode}.`);
    }
    return false;
  }

  public enableMacro(enabled: boolean): void {
    if ('enableMacro' in this.mSession) {
      this.mSession.enableMacro(enabled);
    } else {
      HiLog.e(TAG, `Session has not enableMacro, mode: ${this.mMode}.`);
    }
  }

  public isStageBoostSupported(): boolean {
    if ('isStageBoostSupported' in this.mSession) {
      //TODO  return this.mSession.isStageBoostSupported();
    } else {
      HiLog.e(TAG, `Session has not isStageBoostSupported, mode: ${this.mMode}.`);
    }
    return false;
  }

  public enableStageBoost(enabled: boolean): void {
    if ('enableStageBoost' in this.mSession) {
      //TODO    this.mSession.enableStageBoost(enabled);
    } else {
      HiLog.e(TAG, `Session has not enableStageBoost, mode: ${this.mMode}.`);
    }
  }

  public isSceneFeatureSupported(scene: camera.SceneFeatureType): boolean {
    if ('isSceneFeatureSupported' in this.mSession) {
      //TODO    return this.mSession.isSceneFeatureSupported(scene);
    } else {
      HiLog.e(TAG, `Session has not isSceneFeatureSupported, mode: ${this.mMode}.`);
    }
    return false;
  }

  public enableSceneFeature(scene: camera.SceneFeatureType, enabled: boolean): void {
    if ('enableSceneFeature' in this.mSession) {
      //TODO     this.mSession.enableSceneFeature(scene, enabled);
    } else {
      HiLog.e(TAG, `Session has not enableSceneFeature, mode: ${this.mMode}.`);
    }
  }

  public setExposureDuration(exposure: number): void {
    if ('setExposureDuration' in this.mSession) {
      //TODO      this.mSession.setExposureDuration(exposure);
    } else {
      HiLog.e(TAG, `Session has not setExposureDuration, mode: ${this.mMode}.`);
    }
  }

  public getExposureDuration(): number {
    try {
      //TODO     return this.mSession?.getExposureDuration();
    } catch (e) {
      HiLog.e(TAG, 'getExposureDuration error.');
      return 0;
    }
  }

  public setFocusDistance(focusDistance: number): void {
    if ('setFocusDistance' in this.mSession) {
      //TODO     this.mSession.setFocusDistance(focusDistance);
    } else {
      HiLog.e(TAG, `Session has not setFocusDistance, mode: ${this.mMode}.`);
    }
  }

  public getFocusDistance(): number {
    try {
      //TODO    return this.mSession?.getFocusDistance();
    } catch (e) {
      HiLog.e(TAG, 'getFocusDistance error.');
      return 0;
    }
  }

  public setIso(isoValue: number): void {
    HiLog.i(TAG, `setIso: ${isoValue}.`);
    try {
      //TODO    this.mSession.setIso(isoValue);
    } catch (err) {
      HiLog.e(TAG, `setIso catch err, mode: ${this.mMode}, err: ${err}.`);
    }
  }

  public getIso(): number {
    try {
      //TODO    return this.mSession?.getIso();
    } catch (e) {
      HiLog.e(TAG, 'getISO error.');
      return 0;
    }
  }

  public setApertureValue(Aperture: number): void {
    if ('setPhysicalAperture' in this.mSession) {
      //TODO        this.mSession.setPhysicalAperture(Aperture);
    } else {
      HiLog.e(TAG, `Session has not setPhysicalAperture, mode: ${this.mMode}.`);
    }
  }

  public setExposureMeteringMode(meteringMode: camera.ExposureMeteringMode): void {
    HiLog.i(TAG, `setExposureMeteringMode, mode: ${this.mMode}, meteringMode: ${meteringMode}.`);
    try {
      this.mSession.setExposureMeteringMode(meteringMode);
    } catch (err) {
      HiLog.e(TAG, `setExposureMeteringMode catch err, mode: ${this.mMode}, err: ${err}.`);
    }
  }

  public getExposureMeteringMode(): number {
    try {
      return this.mSession?.getExposureMeteringMode();
    } catch (e) {
      HiLog.e(TAG, 'getExposureMeteringMode error.');
      return 0;
    }
  }

  public setWhiteBalanceMode(whiteBalanceMode: number): void {
    if ('setWhiteBalanceMode' in this.mSession) {
      this.mSession.setWhiteBalanceMode(whiteBalanceMode);
    } else {
      HiLog.e(TAG, `Session has not setWhiteBalanceMode, mode: ${this.mMode}.`);
    }
  }

  public getWhiteBalanceMode(): number {
    try {
      return this.mSession?.getWhiteBalanceMode();
    } catch (e) {
      HiLog.e(TAG, 'getWhiteBalanceMode error.');
      return 0;
    }
  }

  public setWhiteBalance(whiteBalance: number): void {
    HiLog.i(TAG, `setWhiteBalance: ${whiteBalance}.`);
    try {
      this.mSession.setWhiteBalance(whiteBalance);
    } catch (err) {
      HiLog.e(TAG, `setWhiteBalance catch err, mode: ${this.mMode}, err: ${err}.`);
    }
  }

  public getWhiteBalanceRange(): number[] {
    if ('getWhiteBalanceRange' in this.mSession) {
      return this.mSession.getWhiteBalanceRange();
    } else {
      HiLog.e(TAG, `Session has not setWhiteBalance, mode: ${this.mMode}.`);
      return [];
    }
  }

  public getWhiteBalance(): number {
    try {
      return this.mSession?.getWhiteBalance();
    } catch (e) {
      HiLog.e(TAG, 'getWhiteBalance error.');
      return 0;
    }
  }

  public setFocusAssist(auxiliaryValue: number): void {
    if ('setFocusAssist' in this.mSession) {
      this.mSession.setFocusAssist(auxiliaryValue === 0 ? false : true);
    } else {
      HiLog.e(TAG, `Session has not setFocusAssist, mode: ${this.mMode}.`);
    }
  }

  public getFocusAssist(): boolean {
    try {
      return this.mSession?.getFocusAssist();
    } catch (e) {
      HiLog.e(TAG, 'getFocusAssist error.');
      return false;
    }
  }

  public getIsoRange(): number[] {
    try {
      //TODO return this.mSession?.getIsoRange();
    } catch (e) {
      HiLog.e(TAG, 'getISORange error.');
      return [];
    }
  }

  public getApertureRange(): number[] {
    try {
      //TODO     return this.mSession.getApertureRange();
    } catch (e) {
      HiLog.e(TAG, 'getApertureRange error.');
      return [];
    }
  }

  public getZoomPointInfo(): ZoomPointInfo {
    if ('getZoomPointInfos' in this.mSession) {
      let zoomPointInfo = this.mSession.getZoomPointInfos();
      return !zoomPointInfo || zoomPointInfo.length < 1 ? undefined : zoomPointInfo[0];
    } else {
      HiLog.e(TAG, `Session has not getZoomPointInfos, mode: ${this.mMode}.`);
      return undefined;
    }
  }

  public isEffectSuggestionSupported(): boolean {
    if ('isEffectSuggestionSupported' in this.mSession) {
      //TODO    const isEffectSuggestionSupported = this.mSession.isEffectSuggestionSupported();
      //TODO    return isEffectSuggestionSupported;
    } else {
      HiLog.e(TAG, `Session has not isEffectSuggestionSupported, mode: ${this.mMode}.`);
      return false;
    }
  }

  public enableEffectSuggestion(enabled: boolean): void {
    if ('enableEffectSuggestion' in this.mSession) {
      //TODO   this.mSession.enableEffectSuggestion(enabled);
    } else {
      HiLog.e(TAG, `Session has not enableEffectSuggestion, mode: ${this.mMode}.`);
    }
  }

  // 延时摄影速率调节范围
  public getTimeLapseIntervalRange(): number[] {
    if ('getTimeLapseIntervalRange' in this.mSession) {
      //TODO    return this.mSession.getSupportedTimeLapseIntervalRange();
    }
    HiLog.e(TAG, `Session has not getTimeLapseIntervalRange, mode: ${this.mMode}.`);
    return [];
  }

  public setTimeLapseRecordState(state: camera.TimeLapseRecordState): void {
    if ('setTimeLapseRecordState' in this.mSession) {
      //TODO    this.mSession.setTimeLapseRecordState(state);
    } else {
      HiLog.e(TAG, `Session has not setTimeLapseRecordState, mode: ${this.mMode}.`);
    }
  }

  public setTimeLapseInterval(interval: number): void {
    if ('setTimeLapseInterval' in this.mSession) {
      //TODO     this.mSession.setTimeLapseInterval(interval);
    } else {
      HiLog.e(TAG, `Session has not setTimeLapseInterval, mode: ${this.mMode}.`);
    }
  }

  public getTimeLapseInterval(): number {
    if ('getTimeLapseInterval' in this.mSession) {
      //TODO     return this.mSession.getTimeLapseInterval();
    }
    HiLog.e(TAG, `Session has not getTimeLapseInterval, mode: ${this.mMode}.`);
    return 0;
  }

  public startTryAE(): void {
    if ('startTryAE' in this.mSession) {
      //TODO    this.mSession.startTryAE();
    }
    HiLog.e(TAG, `Session has not startTryAE, mode: ${this.mMode}.`);
  }

  public stopTryAE(): void {
    if ('stopTryAE' in this.mSession) {
      //TODO    this.mSession.stopTryAE();
    }
    HiLog.e(TAG, `Session has not stopTryAE, mode: ${this.mMode}.`);
  }

  public setSessionUsage(usageType: number, enabled: boolean): void {
    if ('setUsage' in this.mSession) {
      try {
        this.mSession.setUsage(usageType, enabled);
      } catch (e) {
        HiLog.e(TAG, `setUsage catch err, ${e}`);
      }
    } else {
      HiLog.e(TAG, `setUsage has not setUsage, mode: ${this.mMode}.`);
    }
  }

  public isDepthFusionSupported(): boolean {
    if ('isDepthFusionSupported' in this.mSession) {
      //TODO     return this.mSession.isDepthFusionSupported();
    }
    HiLog.e(TAG, `Session dont support isDepthFusionSupported, mode: ${this.mMode}`);
    return false;
  }

  public getDepthFusionThreshold(): number[] {
    let threshold: number[];
    if ('getDepthFusionThreshold' in this.mSession) {
      //TODO     threshold = this.mSession.getDepthFusionThreshold();
    } else {
      HiLog.e(TAG, `Session has not getDepthFusionThreshold, mode: ${this.mMode}.`);
    }

    if (!threshold) {
      threshold = [];
    }
    return threshold;
  }

  public enableDepthFusion(enabled: boolean): void {
    if ('enableDepthFusion' in this.mSession) {
      //TODO    this.mSession.enableDepthFusion(enabled);
      return;
    }
    HiLog.e(TAG, `Session has not enableDepthFusion, mode: ${this.mMode}.`);
  }

  public isDepthFusionEnabled(): boolean {
    if ('isDepthFusionEnabled' in this.mSession) {
      //TODO     return this.mSession.isDepthFusionEnabled();
    }
    HiLog.e(TAG, `Session has not isDepthFusionEnabled, mode: ${this.mMode}.`);
    return false;
  }

  public setAudioZoomExtra(value: Record<string, string>): void {
    HiLog.d(TAG, 'audioManager setExtraParameters ' + JSON.stringify(value));
    audio.getAudioManager()?.setExtraParameters('audio_effect', value).then(() => {
      HiLog.d(TAG, 'audioManager setExtraParameters success');
    }).catch(error => {
      HiLog.e(TAG, `audioManager setExtraParameters error: ${(error)}.`);
    });
  }

  /**********************近物对焦 start ******************/
  public isFocusRangeTypeSupported(type: camera.FocusRangeType): boolean {
    try {
      if ('isFocusRangeTypeSupported' in this.mSession) {
        HiLog.i(TAG, 'isFocusRangeTypeSupported' + this.mSession.isFocusRangeTypeSupported(type));
        return this.mSession.isFocusRangeTypeSupported(type);
      }
    } catch (e) {
      HiLog.e(TAG, `isFocusRangeTypeSupported catch err, ${e}`);
    }
    HiLog.e(TAG, `Session has not isFocusRangeTypeSupported, mode: ${this.mMode}.`);
    return false;
  }

  public getFocusRange(): camera.FocusRangeType {
    try {
      if ('getFocusRange' in this.mSession) {
        return this.mSession.getFocusRange();
      }
      HiLog.e(TAG, `Session has not getFocusRange, mode: ${this.mMode}.`);
    } catch (e) {
      HiLog.e(TAG, `getFocusRange catch err, ${e}`);
    }
    return camera.FocusRangeType.AUTO;
  }

  public setFocusRange(type: camera.FocusRangeType): void {
    this.isFocusRangeTypeSupported(type);
    try {
      if ('setFocusRange' in this.mSession) {
        HiLog.i(TAG, 'setFocusRange' + type);
        this.mSession.setFocusRange(type);
      }
    } catch (e) {
      HiLog.e(TAG, `setFocusRange catch err, ${e}`);
    }
    HiLog.e(TAG, `Session has not isDepthFusionEnabled, mode: ${this.mMode}.`);
  }

  /**********************近物对焦 end ******************/

  /**********************人像追焦 start ******************/
  public isFocusDrivenTypeSupported(type: camera.FocusDrivenType): boolean {

    try {
      if ('isFocusDrivenTypeSupported' in this.mSession) {
        HiLog.i(TAG, 'isFocusDrivenTypeSupported' + this.mSession.isFocusDrivenTypeSupported(type));
        return this.mSession.isFocusDrivenTypeSupported(type);
      }
    } catch (e) {
      HiLog.e(TAG, `isFocusDrivenTypeSupported catch err, ${e}`);
    }
    HiLog.e(TAG, `Session has not isFocusDrivenTypeSupported, mode: ${this.mMode}.`);
    return false;
  }

  public getFocusDriven(): camera.FocusDrivenType {
    try {
      if ('getFocusDriven' in this.mSession) {
        HiLog.i(TAG, 'getFocusDriven' + this.mSession.getFocusDriven());
        return this.mSession.getFocusDriven();
      }
    } catch (e) {
      HiLog.e(TAG, `getFocusDriven catch err, ${e}`);
    }
    return camera.FocusDrivenType.AUTO;
  }

  public setFocusDriven(type: camera.FocusDrivenType): void {
    try {
      this.isFocusDrivenTypeSupported(type);
      if ('setFocusDriven' in this.mSession) {
        HiLog.i(TAG, 'setFocusDriven' + type);
        this.mSession.setFocusDriven(type);
      }
    } catch (e) {
      HiLog.e(TAG, `setFocusDriven catch err, ${e}`);
    }
  }

  public setFocusTrackingMode(mode: camera.FocusTrackingMode): void {
    try {
      if ('setFocusTrackingMode' in this.mSession) {
        HiLog.i(TAG, `setFocusTrackingMode: ${mode}.`);
        //TODO     this.mSession.setFocusTrackingMode(mode);
      } else {
        HiLog.e(TAG, `setFocusTrackingMode: ${mode}, not in session.`);
      }
    } catch (e) {
      HiLog.e(TAG, `setFocusTrackingMode catch err, ${e}`);
    }
  }

  /**********************人像追焦 end ******************/

  /**********************人像留色 start ******************/
  public getSupportedColorReservationTypes(type: camera.ColorReservationType): camera.ColorReservationType[] {
    try {
      if ('getSupportedColorReservationTypes' in this.mSession) {
        //TODO     HiLog.i(TAG, 'getSupportedColorReservationTypes' + this.mSession.getSupportedColorReservationTypes(type));
        //TODO    return this.mSession.getSupportedColorReservationTypes(type);
      }
    } catch (e) {
      HiLog.e(TAG, `getSupportedColorReservationTypes catch err, ${e}`);
    }
    return [];
  }

  public getColorReservation(): camera.ColorReservationType {
    try {
      if ('getColorReservation' in this.mSession) {
        //TODO      HiLog.i(TAG, 'getColorReservation' + this.mSession.getColorReservation());
        //TODO      return this.mSession.getColorReservation();
      }
    } catch (e) {
      HiLog.e(TAG, `getColorReservation catch err, ${e}`);
    }
    return camera.ColorReservationType.NONE;
  }

  public setColorReservation(type: camera.ColorReservationType): void {
    try {
      this.getSupportedColorReservationTypes(type);
      if ('setColorReservation' in this.mSession) {
        HiLog.i(TAG, 'setColorReservation' + type);
        //TODO      this.mSession.setColorReservation(type);
      }
    } catch (e) {
      HiLog.e(TAG, `setColorReservation catch err, ${e}`);
    }
  }

  /**********************人像留色 end ******************/

  public setWindNoiseSuppression(value: Record<string, string>): void {
    audio.getAudioManager()?.setExtraParameters('audio_effect', value).then(() => {
      HiLog.d(TAG, 'audioManager setExtraParameters success');
    }).catch(error => {
      HiLog.e(TAG, `wind noise suppression audioManager setExtraParameters error: ${(error)}.`);
    });
  }

  public getIsCompositionSuggestionSupported(): boolean {
    if ('isCompositionSuggestionSupported' in this.mSession) {
      try {
        //TODO    HiLog.i(TAG, `Session has isCompositionSuggestionSupported, value: ${this.mSession.isCompositionSuggestionSupported()}`);
        //TODO    return this.mSession.isCompositionSuggestionSupported();
      } catch (e) {
        HiLog.e(TAG, `getIsCompositionSuggestionSupported error`);
        return false;
      }
    } else {
      HiLog.e(TAG, `Session has no getIsCompositionSuggestionSupported function, mode: ${this.mMode}.`);
    }
    return false;
  }

  public enableCompositionSuggestion(enable: boolean): void {
    if ('enableCompositionSuggestion' in this.mSession) {
      try {
        HiLog.i(TAG, `enableCompositionSuggestion, value ${enable}`);
        //TODO      this.mSession.enableCompositionSuggestion(enable);
      } catch (e) {
        HiLog.e(TAG, 'enableCompositionSuggestion error');
        return;
      }
    } else {
      HiLog.e(TAG, `Session has no enableCompositionSuggestion function, mode: ${this.mMode}.`);
    }
  }


  public setFilterType(filterType: number): void {
    if ('setFilter' in this.mSession) {
      //TODO    this.mSession.setFilter(filterType);
    } else {
      HiLog.e(TAG, `Session has not setFilter, mode: ${this.mMode}.`);
    }
  }

  public setAudioEffectStage(isSupportAudioStage: boolean): void {
    if (isSupportAudioStage) {
      audio.getAudioManager()?.setExtraParameters('audio_effect', { 'music_stage': 'on' });
    } else {
      audio.getAudioManager()?.setExtraParameters('audio_effect', { 'music_stage': 'off' });
    }
  }
}