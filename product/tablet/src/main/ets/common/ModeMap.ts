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
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import type { IModeMap } from '@ohos/common/src/main/ets/mode/IModeMap';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import { addState } from '@ohos/common/src/main/ets/redux';
import { addReducer } from '@ohos/common/src/main/ets/redux/Store';
import { addAction } from '@ohos/common/src/main/ets/redux/ActionRegistry';
import { dynamicAddExtend } from '@ohos/extend/src/main/ets/DynamicAddExtend';

// 导入Mode
import { PhotoMode } from '@ohos/photo/src/main/ets/photo/PhotoMode';
import { VideoMode } from '@ohos/video/src/main/ets/video/VideoMode';


const TAG: string = '[Mode]:';

/**
 * 获取不同模式的功能类（phone）
 *
 * 1.getMode：根据mode，指定当前场景。
 * 2.getFunctions:根据当前模式获取支持的functionId数组；
 */
export class ModeMap implements IModeMap {
  private mPhotoMode: PhotoMode = new PhotoMode();
  private mVideoMode: VideoMode = new VideoMode();

  public getMode(mode: ModeType, outputType: OutputType): BaseMode {
    switch (mode) {
      case ModeType.PHOTO:
        return this.mPhotoMode;
      case ModeType.VIDEO:
        return this.mVideoMode;
      default:
        return this.mPhotoMode;
    }
  }



  public initExtendFeatures(): void {
    dynamicAddExtend();

    let featureManager = FeatureManager.getInstance();
  }

  public getFunctions(mode: ModeType): Map<FunctionId, RenderLocation[]> {
    switch (mode) {
      case ModeType.PHOTO:
        return this.mPhotoMode.getFunctions();
      case ModeType.VIDEO:
        return this.mVideoMode.getFunctions();
      default:
        return new Map();
    }
  }
}