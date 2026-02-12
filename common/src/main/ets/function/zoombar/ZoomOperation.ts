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

import lazy { HiLog } from '../../utils/HiLog';
import camera from '@ohos.multimedia.camera';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { ZoomParam } from './ZoomParam';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { OutputType } from '../outputswitcher/OutputType';
import lazy { FrameRateOperation } from '../framerate/FrameRateOperation';
import lazy { CameraBasicService } from '../../camera/uithread/CameraBasicService';
import lazy { VideoResolutionOperation } from '../videoresolution/VideoResolutionOperation';
import lazy { OutputSwitcher } from '../outputswitcher/OutputSwitcher';
import lazy { OutputOperation } from '../outputswitcher/OutputOperation';
import lazy { getStates } from '../../redux';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { RecordingState } from '../recordcontrol/RecordAction';

export class ZoomScaleStruct {
  quickZoomValArr: number[] = [];
  opticalZoomValArr: number[] = [];
  opticalZoomMidDots: number[] = [];
  opticalZoomDotIndex: number[] = [];
}

const TAG: string = 'ZoomOperation';
const VDE_OUTER_ZOOM_MAX = 2;
const VDE_OUTER_ZOOM_MIN = 0.53;

export class ZoomOperation {
  private static sInstance: ZoomOperation;

  static readonly MAX_SCALE_THRESHOLD: number = 50;
  static readonly MAX_SCALE_DOTS: number = 66;
  static readonly MIN_DOT_INTERVAL: number = 5;
  private static readonly ZOOM_RATIO_DEFAULT: number = 1;
  private static readonly ZOOM_RATIO_3: number = 3;
  private static readonly ZOOM_RATIO_4: number = 4;
  private static readonly ZOOM_RATIO_TEN: number = 10;
  private static readonly reportReasonDirection = 'The direction is horizontal.';

  private remainZoomRatio: boolean = false;
  public isZoomViewCreated: boolean = false;

  private constructor() {
  }

  public static getInstance(): ZoomOperation {
    if (!ZoomOperation.sInstance) {
      HiLog.i(TAG, 'ZoomOperation init');
      ZoomOperation.sInstance = new ZoomOperation();
    }
    return ZoomOperation.sInstance;
  }

  public setRemainZoomRatio(remain: boolean): void {
    HiLog.i(TAG, `setRemainZoomRatio ${remain}`);
    this.remainZoomRatio = remain;
  }

  public getRemainZoomRatio(): boolean {
    HiLog.i(TAG, `getRemainZoomRatio ${this.remainZoomRatio}`);
    return this.remainZoomRatio;
  }

  public getStartupZoom(mode: ModeType, position: camera.CameraPosition): number {
    if (this.remainZoomRatio) {
      let zoomRatio = getStates().get<number>('zoomReducer', 'zoomRatio');
      HiLog.i(TAG, `getStartupZoom remainZoomRatio: ${this.remainZoomRatio}, zoomRatio: ${zoomRatio}`);
      return zoomRatio;
    }
    const specialZoomRatio = ZoomOperation.getDefaultZoomRatio(mode, position);
    HiLog.i(TAG, `getStartupZoom remainZoomRatio: ${this.remainZoomRatio}, specialZoomRatio: ${specialZoomRatio}`);
    return specialZoomRatio;
  }

  public static getQuickOpticalArr(cameraPosition: camera.CameraPosition, mode: ModeType): ZoomScaleStruct {
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
    const zoomScaleStruct = new ZoomScaleStruct();
    zoomScaleStruct.quickZoomValArr =
      CameraAppCapability.getInstance().getQuickZoomArray(cameraPosition, mode, outputType);
    zoomScaleStruct.opticalZoomValArr =
      CameraAppCapability.getInstance().getOpticalZoomArray(cameraPosition, mode, outputType);
    return zoomScaleStruct;
  }

  public static getRingZoomUIState(cameraPosition: camera.CameraPosition, mode: ModeType): ZoomScaleStruct {
    let result: ZoomScaleStruct = this.getQuickOpticalArr(cameraPosition, mode);
    if (result.quickZoomValArr && result.opticalZoomValArr) {
      /* instrument ignore if */
      if (DeviceInfo.isTablet() && result.quickZoomValArr.length > 1 &&
        result.quickZoomValArr[0] < this.ZOOM_RATIO_DEFAULT) {
        let frameRate: number = CameraBasicService.getInstance().getVideoFrameRate();
        let videoResolution: number = FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION).getValue();
        if (mode === ModeType.VIDEO && (frameRate === FrameRateOperation.FRAME_FPS_RATE_60 ||
          videoResolution === VideoResolutionOperation.RESOLUTION_16_9_4k)) {
          result.quickZoomValArr.shift();
          result.opticalZoomValArr.shift();
        }
      }
      ZoomOperation.ProcessVideo60fps(mode, result);
      ZoomOperation.ProcessNotSupportedVideo60fpsWide(mode, result);
      ZoomOperation.calZoomScaleByExponential(result);
      return result;
    }

    ZoomOperation.getZoomArrFailed2ReadConfig(cameraPosition, result);
    return result;
  }

  private static ProcessVideo60fps(mode: ModeType, result: ZoomScaleStruct): void {
    if (CameraAppCapability.getInstance().getIsNotSupportedWideZoom60fpsVideoBack() && ModeType.VIDEO &&
      CameraBasicService.getInstance().getVideoFrameRate() === FrameRateOperation.FRAME_FPS_RATE_60) {
      if (result.quickZoomValArr.length > 1 && result.quickZoomValArr[0] < this.ZOOM_RATIO_DEFAULT &&
        getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
        camera.CameraPosition.CAMERA_POSITION_BACK) {
        result.quickZoomValArr.shift();
        result.opticalZoomValArr.shift();
      }
      if (result.quickZoomValArr.length > 0 && result.quickZoomValArr[0] < this.ZOOM_RATIO_DEFAULT &&
        getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
        camera.CameraPosition.CAMERA_POSITION_FRONT) {
        result.quickZoomValArr = result.quickZoomValArr.filter((quickZoom) => quickZoom <= this.ZOOM_RATIO_DEFAULT)
        result.opticalZoomValArr =
          result.opticalZoomValArr.filter((opticalZoom) => opticalZoom <= this.ZOOM_RATIO_DEFAULT)
      }
      if (CameraAppCapability.getInstance().getIsChange3To4Zoom60fpsVideoBack() && mode === ModeType.VIDEO &&
        result.quickZoomValArr.length > 0 &&
        CameraBasicService.getInstance().getVideoFrameRate() === FrameRateOperation.FRAME_FPS_RATE_60 &&
        getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
        camera.CameraPosition.CAMERA_POSITION_BACK) {
        result.quickZoomValArr =
          result.quickZoomValArr.map((quickZoom) => quickZoom === this.ZOOM_RATIO_3 ? this.ZOOM_RATIO_4 : quickZoom)
        result.opticalZoomValArr =
          result.opticalZoomValArr.map((opticalZoom) => opticalZoom === this.ZOOM_RATIO_3 ? this.ZOOM_RATIO_4 :
            opticalZoom)
      }
    }
  }

  private static ProcessNotSupportedVideo60fpsWide(mode: ModeType, result: ZoomScaleStruct): void {
    let frameRate: number = CameraBasicService.getInstance().getVideoFrameRate();
    const recordingState = getStates().get<RecordingState>('recordReducer', 'recordingState');
    /* instrument ignore if */
    if (CameraAppCapability.getInstance().getNotSupportedVideo60fpsWide() &&
      (mode === ModeType.VIDEO) &&
      frameRate === FrameRateOperation.FRAME_FPS_RATE_60 &&
      getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
      camera.CameraPosition.CAMERA_POSITION_BACK) {
      if (result.quickZoomValArr.length > 1 && result.quickZoomValArr[0] < this.ZOOM_RATIO_DEFAULT) {
        result.quickZoomValArr.shift();
        result.opticalZoomValArr.shift();
      }
    }
  }

  /* instrument ignore next */
  private static getZoomArrFailed2ReadConfig(cameraPosition: camera.CameraPosition, result: ZoomScaleStruct): void {
    if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      result.quickZoomValArr = [ZoomParam.QUICK_ZOOM_0_67, ZoomParam.QUICK_ZOOM_0_8, ZoomParam.QUICK_ZOOM_1];
      result.opticalZoomValArr = [ZoomParam.QUICK_ZOOM_0_67, ZoomParam.QUICK_ZOOM_0_8, ZoomParam.QUICK_ZOOM_1];
    } else {
      result.quickZoomValArr = [ZoomParam.QUICK_ZOOM_1, ZoomParam.QUICK_ZOOM_3, ZoomParam.QUICK_ZOOM_6];
      result.opticalZoomValArr = [ZoomParam.QUICK_ZOOM_1, ZoomParam.QUICK_ZOOM_3, ZoomParam.QUICK_ZOOM_6];
    }
    ZoomOperation.calZoomScaleByExponential(result);
  }

  public static calZoomScaleByExponential(result: ZoomScaleStruct): void {
    let mathLogMin = Math.log2(result.opticalZoomValArr[0]);
    let mathLogMax = Math.log2(result.opticalZoomValArr[result.opticalZoomValArr.length - 1]);
    let realDotsCount = 0;
    if (result.opticalZoomValArr[result.opticalZoomValArr.length - 1] >= ZoomOperation.MAX_SCALE_THRESHOLD) {
      realDotsCount = ZoomOperation.MAX_SCALE_DOTS;
    } else {
      let mathLogMaxScale = Math.log2(ZoomOperation.MAX_SCALE_THRESHOLD);
      realDotsCount =
        Math.round((mathLogMax - mathLogMin) / (mathLogMaxScale - mathLogMin) * ZoomOperation.MAX_SCALE_DOTS);
    }
    result.opticalZoomValArr.forEach((opticalZoomVal: number, index: number) => {
      if (index > 0) {
        let mathLogZoom = Math.log2(opticalZoomVal);
        result.opticalZoomDotIndex[index] =
          Math.round((mathLogZoom - mathLogMin) / (mathLogMax - mathLogMin) * realDotsCount);
        // zoom 展开状态，每个大点间隔至少5个,防止焦距重合
        if (opticalZoomVal <= this.ZOOM_RATIO_TEN &&
          result.opticalZoomDotIndex[index] - result.opticalZoomDotIndex[index - 1] < this.MIN_DOT_INTERVAL) {
          result.opticalZoomDotIndex[index] = result.opticalZoomDotIndex[index - 1] + this.MIN_DOT_INTERVAL;
          HiLog.d(TAG, `ZoomDot index: ${index} and ${index - 1}, interval less than 5, set value 5`);
        }
        result.opticalZoomMidDots[index - 1] =
          result.opticalZoomDotIndex[index] - result.opticalZoomDotIndex[index - 1];
      } else {
        result.opticalZoomDotIndex[index] = 0;
      }
    });
    HiLog.d(TAG, `DotIndex: ${result.opticalZoomDotIndex.join(',')}, MidDots: ${result.opticalZoomMidDots.join(',')}`);
  }

  /**
   * 获取特殊场景默认焦距 起流的时候会调用
   */
  /* instrument ignore next */
  public static getDefaultZoomRatio(mode: ModeType, cameraPosition: camera.CameraPosition): number {
    if (!mode || !cameraPosition) {
      return ZoomOperation.ZOOM_RATIO_DEFAULT;
    }
    HiLog.i(TAG, `get night submode moon: ${getStates().get<number>('nightSubModeReducer', 'nightSubMode')}`);
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
    const quickZoomValArr = CameraAppCapability.getInstance().getQuickZoomArray(cameraPosition, mode, outputType);
    if (quickZoomValArr?.[0] <= AppStorage.get('wantZoomRatio') &&
      AppStorage.get('wantZoomRatio') <= quickZoomValArr?.[quickZoomValArr.length - 1]) {
      return AppStorage.get('wantZoomRatio');
    }
    if (mode === ModeType.VIDEO && cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      if (quickZoomValArr?.[1]) {
        return quickZoomValArr[1];
      }
    }
    return ZoomOperation.ZOOM_RATIO_DEFAULT;
  }

  /**
   * 获取横屏时自动广角的焦距
   */
  public static getDirectionChangeAutoWide(quickZoomArray: number[]): number {
    if (quickZoomArray?.[1] && quickZoomArray[1] < this.ZOOM_RATIO_DEFAULT) {
      HiLog.i(TAG, `getDirectionChangeAutoWide: ${quickZoomArray[1]}`);
      return quickZoomArray[1];
    }
    if (quickZoomArray?.[0]) {
      HiLog.i(TAG, `getDirectionChangeAutoWide: ${quickZoomArray[0]}`);
      return quickZoomArray[0];
    }
    return ZoomOperation.ZOOM_RATIO_DEFAULT;
  }
}