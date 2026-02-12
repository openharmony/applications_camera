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
/* instrument ignore file */
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { HiLog } from '../../utils/HiLog';
import type camera from '@ohos.multimedia.camera';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { hasCameraProfiles } from '../../utils/FileReadUtil';

const TAG: string = 'VideoResolutionOperation';

export class VideoResolutionOperation {
  public static readonly RESOLUTION_16_9_4k: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_FIR;
  public static readonly VIDEO_RESOLUTION_FULL: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_SEC;
  public static readonly RESOLUTION_16_9_1080P: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_THR;
  public static readonly RESOLUTION_16_9_720P: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_FOUR;
  public static readonly RESOLUTION_16_9_1080P_PC: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_SEC;
  public static readonly RESOLUTION_16_9_720P_PC: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_THR;
  public static readonly RESOLUTION_4_3_960P: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_FIF;
  public static readonly RESOLUTION_4_3_480P: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_SIX;
  public static readonly RESOLUTION_2_7_K: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_FIF;
  public static readonly RES_NUM_16: number = 16;
  public static readonly RES_NUM_9: number = 9;

  public static getPreviewProfile(resolution: SettingFuncDialogItemIndex, position: camera.CameraPosition,
    mode: ModeType, isHdrVivid?: boolean): camera.Profile {
    const index: number = VideoResolutionOperation.getIndex(resolution);
    const list: camera.Profile[] = CameraAppCapability.getInstance()?.getVideoPreviewProfiles(position, mode,
      isHdrVivid);
    HiLog.i(TAG, `getPreviewProfile index: ${index}, list.length: ${list?.length}.`);
    if (index < list?.length) {
      HiLog.i(TAG, `getPreviewProfile: ${JSON.stringify(list)},${index}.`);
      return list[index];
    }
    HiLog.w(TAG, 'getPreviewProfile: undefined.');
    return undefined;
  }

  public static getVideoProfile(resolution: SettingFuncDialogItemIndex, position: camera.CameraPosition, mode: ModeType,
    frameRate: number, isHdrVivid?: boolean): camera.VideoProfile {
    const index: number = VideoResolutionOperation.getIndex(resolution);
    const list: camera.VideoProfile[] = CameraAppCapability.getInstance().getVideoProfiles(position, mode,
      isHdrVivid);
    if (index < list?.length) {
      HiLog.i(TAG, `getVideoProfile(: ${JSON.stringify(list)},${index}.`);
      return {
        format: list[index].format,
        size: list[index].size,
        frameRateRange: { min: frameRate, max: frameRate }
      };
    }
    HiLog.w(TAG, 'getVideoProfile: undefined.');
    return undefined;
  }

  private static getIndex(resolution: SettingFuncDialogItemIndex): number {
    if (DeviceInfo.isPc()) {
      if (!hasCameraProfiles()) {
        return SettingFuncDialogItemIndex.INDEX_THR;
      }
      switch (resolution) {
        case VideoResolutionOperation.RESOLUTION_16_9_4k:
          return 0;
        case VideoResolutionOperation.RESOLUTION_16_9_1080P_PC:
          return 1;
        case VideoResolutionOperation.RESOLUTION_16_9_720P_PC:
          return SettingFuncDialogItemIndex.INDEX_SEC;
        case VideoResolutionOperation.RESOLUTION_4_3_960P:
          return SettingFuncDialogItemIndex.INDEX_FOUR;
        case VideoResolutionOperation.RESOLUTION_4_3_480P:
          return SettingFuncDialogItemIndex.INDEX_FIF;
        default:
          HiLog.w(TAG, 'match resolution id failed.');
          return 0;
      }
    }
    switch (resolution) {
      case VideoResolutionOperation.RESOLUTION_16_9_4k:
        return 0;
      case VideoResolutionOperation.VIDEO_RESOLUTION_FULL:
        return 1;
      case VideoResolutionOperation.RESOLUTION_16_9_1080P:
        return SettingFuncDialogItemIndex.INDEX_SEC;
      case VideoResolutionOperation.RESOLUTION_16_9_720P:
        return SettingFuncDialogItemIndex.INDEX_THR;
      case VideoResolutionOperation.RESOLUTION_2_7_K:
        return SettingFuncDialogItemIndex.INDEX_FOUR;
      default:
        HiLog.w(TAG, 'match resolution id failed.');
        return 0;
    }
  }
}