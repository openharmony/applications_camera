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
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { HiLog } from '../../utils/HiLog';
import type camera from '@ohos.multimedia.camera';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { OutputType } from '../outputswitcher/OutputType';
import lazy { OutputSwitcher } from '../outputswitcher/OutputSwitcher';
import lazy { hasCameraProfiles } from '../../utils/FileReadUtil';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';
import lazy { UiElement } from '../core/UiElement';
import lazy { OutputOperation } from '../outputswitcher/OutputOperation';
import lazy { simpleStringify } from '../../utils/SimpleStringify';
import lazy { PcInfo } from '../../component/deviceinfo/PcInfo';
import lazy { getStates } from '../../redux';
import { PhotoFormatMode } from '../enumbase/PhotoFormatMode';

const TAG: string = 'AspectRatioOperation';
const EPSILON = 0.1;
const MAIN_CAMERA_INDEX: number = 0;
const WIDE_CAMERA_INDEX: number = 1;
const LONG_FOCUS_CAMERA_INDEX: number = 2;
const CAMERA_RATIO_ONE_INDEX: number = 3;
const CAMERA_RATIO_FULL_INDEX: number = 4;

export class AspectRatioOperation {
  public static readonly ASPECT_RATIO_4_3: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_FIR;
  public static readonly ASPECT_RATIO_1_1: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_SEC;
  public static readonly ASPECT_RATIO_full: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_THR;
  public static readonly ASPECT_RATIO_16_9_2160: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_FIR;
  public static readonly ASPECT_RATIO_16_9_1080: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_SEC;
  public static readonly ASPECT_RATIO_16_9_720: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_THR;
  public static readonly ASPECT_RATIO_4_3_960: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_FOUR;
  public static readonly ASPECT_RATIO_1_1_2368: SettingFuncDialogItemIndex = SettingFuncDialogItemIndex.INDEX_FIF;
  public static readonly ASPECT_RATIO_INDEX_2: number = 2;
  public static readonly RATIO_NUM_3: number = 3;
  public static readonly RATIO_NUM_4: number = 4;
  public static readonly RATIO_NUM_9: number = 9;
  public static readonly RATIO_NUM_16: number = 16;

  public static getPreviewProfile(aspectRatio: SettingFuncDialogItemIndex, position: camera.CameraPosition,
                                  mode: ModeType): camera.Profile {
    const index: number = AspectRatioOperation.getIndex(aspectRatio);
    HiLog.i(TAG, `getPreviewProfile index: ${index}, position: ${position}, aspectRatio: ${aspectRatio}`);
    /* instrument ignore if*/
    if (PcInfo.isRotatablePc()) {
      if (aspectRatio === SettingFuncDialogItemIndex.INDEX_FOUR) {
        return { size: { width: 3200, height: 2400 }, format: 1003 };
      } else if (aspectRatio === SettingFuncDialogItemIndex.INDEX_FIF) {
        return { size: { width: 2368, height: 2368 }, format: 1003 };
      }
    }
    let photoPreviewProfiles = CameraAppCapability.getInstance()?.getPhotoPreviewProfiles(position, mode);
    HiLog.d(TAG, `photoPreviewProfiles: ${JSON.stringify(photoPreviewProfiles)}`);
    if (!photoPreviewProfiles || index >= photoPreviewProfiles.length) {
      HiLog.w(TAG, 'getPreviewProfile platform undefined.');
      return undefined;
    }
    HiLog.i(TAG, `photoPreviewProfile: ${JSON.stringify(photoPreviewProfiles[index])}.`);
    return photoPreviewProfiles[index];
  }

  public static getPhotoProfile(aspectRatio: SettingFuncDialogItemIndex, position: camera.CameraPosition,
                                mode: ModeType, zoomRatio?: number, isPhysicalLens?: boolean): camera.Profile {
    let index: number = 0;
    /* instrument ignore if*/
    if (PcInfo.isRotatablePc()) {
      if (aspectRatio === SettingFuncDialogItemIndex.INDEX_FOUR) {
        return { size: { width: 3200, height: 2400 }, format: 2000 };
      } else if (aspectRatio === SettingFuncDialogItemIndex.INDEX_FIF) {
        return { size: { width: 2368, height: 2368 }, format: 2000 };
      }
    }
    if (isPhysicalLens === true) {
      const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
      let quickZoomArray: number[] = CameraAppCapability.getInstance().getQuickZoomArray(position, mode, outputType);
      index = this.getPhysicalLensIndex(zoomRatio, quickZoomArray); // MAIN、WIDE、TELEPHOTO
      if (aspectRatio === AspectRatioOperation.ASPECT_RATIO_1_1) {
        index = CAMERA_RATIO_ONE_INDEX; // 1：1
      } else if (aspectRatio === AspectRatioOperation.ASPECT_RATIO_full) {
        index = CAMERA_RATIO_FULL_INDEX; // full
      }
    } else {
      index = AspectRatioOperation.getIndex(aspectRatio);
    }
    HiLog.i(TAG, `getPhotoProfile index: ${index}, isPhysicalLens: ${isPhysicalLens}. aspectRatio : ${aspectRatio}`);
    let photoFormat = AspectRatioOperation.getSavePhotoFormat();
    let photoProfiles = CameraAppCapability.getInstance().getPhotoProfiles(position, mode, photoFormat, isPhysicalLens);
    if (!photoProfiles || index >= photoProfiles.length) {
      HiLog.w(TAG, 'mPhotoProfilesMap platform undefined.');
      return undefined;
    }
    HiLog.d(TAG, `getPhotoProfile: ${simpleStringify(photoProfiles[index])}.`);
    return photoProfiles[index];
  }

//TODO 这里FeatureManager.getInstance().getFunction(FunctionId.PHOTO_FORMAT).getValue(); 没取到值，强行赋值了
  public static getSavePhotoFormat(): PhotoFormatMode { // 用户选择的落盘方式
    let mode = getStates().get<ModeType>('modeReducer', 'mode');
    let outputType = OutputSwitcher.getInstance().getOutput();
    let savePhotoFormat;
    savePhotoFormat = OutputOperation.isPanVideoOutput(mode, outputType) ? PhotoFormatMode.JPG :PhotoFormatMode.JPG
    // FeatureManager.getInstance().getFunction(FunctionId.PHOTO_FORMAT).getValue();
    // 用户设置页选择图片落盘格式,原则上不可能走到RAW
    return savePhotoFormat;
  }

  /* instrument ignore next */
  private static getIndex(aspectRatio: SettingFuncDialogItemIndex): number {
    let index: number = AspectRatioOperation.ASPECT_RATIO_4_3;
    if (DeviceInfo.isPc()) {
      if (!hasCameraProfiles()) {
        return SettingFuncDialogItemIndex.INDEX_SEC;
      }
      switch (aspectRatio) {
        case AspectRatioOperation.ASPECT_RATIO_16_9_2160:
          return SettingFuncDialogItemIndex.INDEX_NONE;
        case AspectRatioOperation.ASPECT_RATIO_16_9_1080:
          return SettingFuncDialogItemIndex.INDEX_FIR;
        case AspectRatioOperation.ASPECT_RATIO_16_9_720:
          return SettingFuncDialogItemIndex.INDEX_SEC;
        case AspectRatioOperation.ASPECT_RATIO_4_3_960:
          return SettingFuncDialogItemIndex.INDEX_THR;
        case AspectRatioOperation.ASPECT_RATIO_1_1_2368:
          return SettingFuncDialogItemIndex.INDEX_FOUR;
        default:
          HiLog.w(TAG, 'match resolution id failed.');
          return SettingFuncDialogItemIndex.INDEX_THR;
      }
    }
    if (aspectRatio === AspectRatioOperation.ASPECT_RATIO_1_1) {
      index = AspectRatioOperation.ASPECT_RATIO_1_1;
    } else if (aspectRatio === AspectRatioOperation.ASPECT_RATIO_full) {
      index = AspectRatioOperation.ASPECT_RATIO_full;
    } else if (DeviceInfo.isTablet() && aspectRatio === SettingFuncDialogItemIndex.INDEX_FOUR) {
      index = SettingFuncDialogItemIndex.INDEX_FOUR;
    }
    return index - 1; // SettingFuncDialogItemIndex映射为数组索引下标对应要减一
  }

  private static getPhysicalLensIndex(zoomRatio: number, quickZoomArray: number[]): number {
    if (quickZoomArray.length === 1) {
      return MAIN_CAMERA_INDEX; // 默认物理镜头主摄
    }

    if (Math.abs(zoomRatio - quickZoomArray[0]) < EPSILON) {
      return WIDE_CAMERA_INDEX; //物理镜头--广角
    } else if (zoomRatio === 1) {
      return MAIN_CAMERA_INDEX; //物理镜头--主摄
    } else {
      return LONG_FOCUS_CAMERA_INDEX; //物理镜头--长焦
    }
  }
}