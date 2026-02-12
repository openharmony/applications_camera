/*
 * Copyright (c) Huawei Device Co., Ltd. 2023-2025. All rights reserved.
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

import lazy { BaseMode } from '@ohos/common/src/main/ets/mode/BaseMode';
import lazy { ConflictParam } from '@ohos/common/src/main/ets/function/core/ConflictParam';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { PhotoModeParam } from './PhotoModeParam';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { getStates } from '@ohos/common/src/main/ets/redux';

const TAG: string = 'PhotoMode';

export class PhotoMode extends BaseMode {
  private mPhotoModeParam: PhotoModeParam = new PhotoModeParam();

  getConflicts(isFront: boolean): Map<FunctionId, ConflictParam> {
    let map = new Map();
    // 锁屏相机设置密码状态下地理位置开关禁用
    /* instrument ignore if*/
    if (getStates().get<boolean>('securityCameraReducer', 'isSecurityCamera')) {
      map.set(FunctionId.SAVE_GEO_LOCATION, new ConflictParam().disable());
    }
    return map;
  }

  public getFunctions(): Map<FunctionId, RenderLocation[]> {
    let result: Map<FunctionId, RenderLocation[]>;
    /* instrument ignore else*/
    if (DeviceInfo.isPhone()) {
      result = this.mPhotoModeParam.phoneFunctions;
    } else if (DeviceInfo.isPc()) {
      result = this.mPhotoModeParam.pcFunctions;
    } else if (DeviceInfo.isTv()) {
      result = this.mPhotoModeParam.tvFunctions;
    } else {
      result = this.mPhotoModeParam.tabletFunctions;
    }
    return result;
  }
}