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
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { RenderType } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderType';
import lazy { UiElement } from '@ohos/common/src/main/ets/function/core/UiElement';
import lazy { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import lazy { CameraStartType } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';

const TAG = 'FloatingShutterFunction';

export class FloatingShutterFunction extends BaseFunction {
  private static isShow: boolean;
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.SETTING_MENU_COMMON];

  constructor() {
    super();
    FloatingShutterFunction.isShow = <boolean> this.getPersistedValue();
    this.mEventBus.on(CameraActionType.STARTED, this.setIsShow.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_DESTROY, this.abilityOnDestroy.bind(this), this.mBase.hashCode());
  }

  private setIsShow(data): void {
    // 冷启动或者热启动
    if (data.type === CameraStartType.COLD_START || data.type === CameraStartType.WARM_START) {
      this.mStoreManager.postMessage(Action.floatingShutterButton(FloatingShutterFunction.isShow));
    }
  }

  getFunctionId(): FunctionId {
    return FunctionId.FLOATING_SHUTTER;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.TOGGLE_SETTING_ITEM;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getUiElements(renderLocation: RenderLocation): Map<unknown, UiElement> {
    const uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.floating_shutter'))
      .setDesc($r('app.string.floating_shutter_description'))
      .setIcon($r('app.media.ic_camera_setting_floating_shutter'))
      .setAccessibilityTitle($r('app.string.floating_shutter')));
    return uiElements;
  }

  getDefaultValue(): boolean {
    return false;
  }

  setValue(value: boolean): void {
    HiLog.i(TAG, `setFloatingShutter value: ${value}.`);
    FloatingShutterFunction.isShow = value;
    this.mStoreManager.postMessage(Action.floatingShutterButton(value));
    this.persistValue(value);
  }

  getValue(): boolean {
    return FloatingShutterFunction.isShow;
  }

  isAvailable(): boolean {
    return true;
  }

  private abilityOnDestroy(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'abilityOnDestroy');
  }
}