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

import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { RenderType } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderType';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { UiElement } from '@ohos/common/src/main/ets/function/core/UiElement';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { CameraAction } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import lazy { OutputSwitcher } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcher';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { PersistType } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { PropTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy {
  SettingFuncDialogItemIndex
} from '@ohos/common/src/main/ets/component/settingview/SettingFuncDialogItemIndex';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { getStates } from '@ohos/common/src/main/ets/redux';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';

const TAG = 'EfficientVideoFunction';
const VIDEO_ENCODING: number = 0.35;

export class EfficientVideoFunction extends BaseFunction {
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.SETTING_MENU_VIDEO];

  constructor() {
    super();
  }

  getFunctionId(): FunctionId {
    return FunctionId.EFFICIENT_VIDEO;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.TOGGLE_SETTING_ITEM;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getUiElements(): Map<string, UiElement> {
    let uiElements: Map<string, UiElement> = new Map();
    let videoEncoding: string = SystemLanguageUtil.NumberFormat(VIDEO_ENCODING, 'percent');
    uiElements.set(UiElement.DEFAULT, new UiElement()
      .setTitle($r('app.string.efficient_video_encoding_format'))
      .setDesc($r('app.string.efficient_video_encoding_format_description', videoEncoding))
      .setIcon($r('app.media.ic_camera_setting_efficient_video_format'))
      .setAccessibilityTitle($r('app.string.efficient_video_encoding_format')));
    return uiElements;
  }

  getDefaultValue(): boolean {
    return (DeviceInfo.isPc()) ? false : true;
  }

  setValue(value: boolean): void {
    HiLog.i(TAG, `setValue value: ${value}.`);
    if (this.getPersistedValue() === value) {
      return;
    }
    this.persistValue(value);
    if (!value) {
      let hdrVividValue = false;
      this.mPreferencesService.putPropValue(PersistType.FOREVER, PropTag.LAST_HDR_VIVID, hdrVividValue);
      AppStorage.setOrCreate('restoreFlag', true);
      AppStorage.setOrCreate('restoreFlag', false);
    }
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
    if (OutputOperation.isPanPhotoOutput(getStates().get<ModeType>('modeReducer', 'mode'), outputType)) {
      return;
    }
    this.mStoreManager.postMessage(CameraAction.restart(getStates().get<number>('zoomReducer', 'zoomRatio')));
  }

  getValue(): boolean {
    if (CameraAppCapability.getInstance().getIs60fpsDefaultCloseEfficientVideo()) {
      let frameRate: number = FeatureManager.getInstance().getFunction(FunctionId.FRAME_RATE)?.getValue();
      let hdrVivid: boolean = false;
      if (!AppStorage.get(`userChangeEfficientVideo`) && frameRate === SettingFuncDialogItemIndex.INDEX_SEC && (
        !CameraAppCapability.getInstance().getIs60fpsSupportHdrVivid() && !hdrVivid)) {
        return false;
      }
    }
    return (DeviceInfo.isPc() ||
    CameraAppCapability.getInstance().getIsNotSupportedEfficientVideoFunction()) ? false :
      <boolean> this.getPersistedValue();
  }

  isAvailable(): boolean {
    let isEfficientVideoFunctionAvailable = (DeviceInfo.isPc() ||
    CameraAppCapability.getInstance().getIsNotSupportedEfficientVideoFunction()) ? false : true
    HiLog.i(TAG, `isAvailable: ${isEfficientVideoFunctionAvailable}.`)
    return isEfficientVideoFunctionAvailable;
  }
}