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

import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { HiLog } from '../../utils/HiLog';
import camera from '@ohos.multimedia.camera';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { hasCameraProfiles } from '../../utils/FileReadUtil';
import lazy { getStates } from '../../redux';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';

const TAG: string = 'FrameRateOperation';

export class FrameRateOperation {
  public static readonly FRAME_FPS_RATE_10: number = 10;
  public static FRAME_FPS_RATE_30: number = 30;
  public static FRAME_FPS_RATE_60: number = 60;

  private static readonly FRAME_RATE_30FPS: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_FIR;
  private static readonly FRAME_RATE_60FPS: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_SEC;

  public static getVideoFrameRate(frameRate: SettingFuncDialogItemIndex): number {
    const index = FrameRateOperation.getIndex(frameRate);
    if (DeviceInfo.isPc() && !hasCameraProfiles()) {
      if (CameraAppCapability.getInstance().getPcSupportCameraPosition() ===
      camera.CameraPosition.CAMERA_POSITION_FRONT) {
        return FrameRateOperation.FRAME_FPS_RATE_30;
      }
      return FrameRateOperation.FRAME_FPS_RATE_10;
    }
    const mPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    const mMode = getStates().get<ModeType>('modeReducer', 'mode');
    let videoFrameRate = CameraAppCapability.getInstance().getVideoFrameRateArray(mPosition, mMode);
    if (index >= videoFrameRate?.length) {
      HiLog.i(TAG,
        `getVideoFrameRate mode:${mMode},index: ${index}, mVideoFrameRate.length: ${videoFrameRate?.length}.`);
      return FrameRateOperation.FRAME_FPS_RATE_30;
    }
    HiLog.i(TAG, `getVideoFrameRate frameRate = ${JSON.stringify(videoFrameRate[index])}.`);
    return videoFrameRate[index];
  }

  private static getIndex(frameRate: SettingFuncDialogItemIndex): number {
    switch (frameRate) {
      case FrameRateOperation.FRAME_RATE_30FPS:
      case SettingFuncDialogItemIndex.INDEX_FIR:
        return 0;
      case FrameRateOperation.FRAME_RATE_60FPS:
      case SettingFuncDialogItemIndex.INDEX_SEC:
        return 1;
      case SettingFuncDialogItemIndex.INDEX_THR:
        return 2;
      default:
        HiLog.w(TAG, 'match frameRate id failed.');
        return 0;
    }
  }

  public static isBackVideoWideZoom60fps(zoomRatio: number, position: camera.CameraPosition): boolean {
    const frameRate: number = FeatureManager.getInstance().getFunction(FunctionId.FRAME_RATE)?.getValue() as number;
    return zoomRatio < 1 && frameRate === SettingFuncDialogItemIndex.INDEX_SEC &&
      position === camera.CameraPosition.CAMERA_POSITION_BACK;
  }
}