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
import lazy { UiElement } from '@ohos/common/src/main/ets/function/core/UiElement';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';

const TAG = 'SoundMuteFunction';

// 拍摄静音特性
export class SoundMuteFunction extends BaseFunction {
  public static soundMuteValue: boolean = false;
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.SETTING_MENU_COMMON];

  constructor() {
    super();
    let persistedVal = this.getPersistedValue();
    if (persistedVal !== undefined) {
      SoundMuteFunction.soundMuteValue = persistedVal as boolean;
    }
  }

  getFunctionId(): FunctionId {
    return FunctionId.SOUND_MUTE;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.TOGGLE_SETTING_ITEM;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getUiElements(renderLocation: RenderLocation): Map<string | number, UiElement> {
    let uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.sound_mute'))
      .setIcon($r('app.media.ic_camera_sound_mute'))
      .setDesc($r('app.string.menu_remark_mute_disable'))
      .setAccessibilityTitle($r('app.string.sound_mute')));
    return uiElements;
  }

  getDefaultValue(): boolean {
    return false;
  }

  setValue(value: boolean): void {
    HiLog.i(TAG, `setValue value: ${value}.`);
    SoundMuteFunction.soundMuteValue = value;
    this.persistValue(value);
  }

  getValue(): boolean {
    if (DeviceInfo.isTv() && GlobalContext.get().getIsPicker()) {
      return false;
    }
    if (this.getPersistedValue()) {
      HiLog.i(TAG, 'persistedValue is true.');
      return this.getPersistedValue() as boolean;
    }
    let oldSoundMuteValue: boolean = SoundMuteFunction.soundMuteValue;
    let conflicts = this.getRequiredConflicts();
    if (conflicts?.disabled) {
      oldSoundMuteValue = true;
    } else if (conflicts?.limitedValue?.getValues()?.indexOf(SoundMuteFunction.soundMuteValue.toString()) < 0) {
      oldSoundMuteValue = conflicts?.limitedValue?.getValues()[0] as unknown as boolean;
    }
    HiLog.d(TAG, `getValue returnValue: ${oldSoundMuteValue}, persisitVal: ${SoundMuteFunction.soundMuteValue}.`);
    return oldSoundMuteValue;
  }

  isAvailable(): boolean {
    return true;
  }
}