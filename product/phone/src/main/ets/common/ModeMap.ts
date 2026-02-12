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

import type { BaseMode } from '@ohos/common/src/main/ets/mode/BaseMode';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import type { IModeMap } from '@ohos/common/src/main/ets/mode/IModeMap';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import lazy { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { addState } from '@ohos/common/src/main/ets/redux';
import lazy { addReducer } from '@ohos/common/src/main/ets/redux/Store';
import lazy { addAction } from '@ohos/common/src/main/ets/redux/ActionRegistry';
import lazy { dynamicAddExtend } from '@ohos/extend/src/main/ets/DynamicAddExtend';

import lazy { PhotoMode } from '@ohos/photo/src/main/ets/photo/PhotoMode';
import lazy { VideoMode } from '@ohos/video/src/main/ets/video/VideoMode';

import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';


import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';

const TAG: string = '[Mode]:';

/**
 * 获取不同模式的功能类（phone）
 *
 * 1.getMode：根据mode，指定当前场景。
 * 2.getFunctions:根据当前模式获取支持的functionId数组；
 */
/* instrument ignore file */
export class ModeMap implements IModeMap {
  private mPhotoMode: PhotoMode = null;
  private mVideoMode: VideoMode = null;


  private getPhotoMode(): PhotoMode {
    if (this.mPhotoMode === null) {
      HiLog.begin(TAG, 'create PhotoMode.');
      this.mPhotoMode = new PhotoMode();
      HiLog.end(TAG, 'create PhotoMode.');
    }
    return this.mPhotoMode;
  }

  private getVideoMode(): VideoMode {
    if (this.mVideoMode === null) {
      HiLog.begin(TAG, 'create VideoMode.');
      this.mVideoMode = new VideoMode();
      HiLog.end(TAG, 'create VideoMode.');
    }
    return this.mVideoMode;
  }

  public getMode(mode: ModeType, outputType: OutputType): BaseMode {
    switch (mode) {
      case ModeType.PHOTO:
        return this.getPhotoMode();
      case ModeType.VIDEO:
        return this.getVideoMode();
      default:
        return this.getMoreMode(mode, outputType);
    }
  }

  private getMoreMode(mode: ModeType, outputType: OutputType): BaseMode {
    switch (mode) {
      default:
        return this.getPhotoMode();
    }
  }

  // 动态添加特性、state、reducer、Action
  public initExtendFeatures(): void {
    dynamicAddExtend();
  }

  public getFunctions(mode: ModeType): Map<FunctionId, RenderLocation[]> {
    switch (mode) {
      case ModeType.PHOTO:
        return this.getPhotoMode().getFunctions();
      case ModeType.VIDEO:
        return this.getVideoMode().getFunctions();
      default:
        return this.getModeFunctions(mode);
    }
  }

  private getModeFunctions(mode: ModeType): Map<FunctionId, RenderLocation[]> {
    switch (mode) {
      default:
        return new Map();
    }
  }
}