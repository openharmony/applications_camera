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
import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { CameraStartType } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { RenderType } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderType';
import lazy { UiElement } from '@ohos/common/src/main/ets/function/core/UiElement';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';

const TAG = 'AssistiveGridFunction';

// 参考线
export class AssistiveGridFunction extends BaseFunction {
  private static isShow: boolean;
  private readonly RENDER_LOCATIONS: RenderLocation[] = [
    RenderLocation.TREASURE_BOX, RenderLocation.SETTING_MENU_COMMON
  ];

  constructor() {
    super();
    AssistiveGridFunction.isShow = <boolean> this.getPersistedValue();
    this.mEventBus.on(CameraActionType.STARTED, this.setIsShow.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_DESTROY, this.abilityOnDestroy.bind(this), this.mBase.hashCode());
  }

  private setIsShow(data): void {
    if (data.type === CameraStartType.COLD_START || data.type === CameraStartType.WARM_START) {
      this.mStoreManager.postMessage(Action.assistiveGridView(AssistiveGridFunction.isShow));
    }
  }

  getFunctionId(): FunctionId {
    return FunctionId.ASSISTIVE_GRID;
  }

  getDefaultValue(): boolean {
    return false;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    switch (renderLocation) {
      case RenderLocation.TREASURE_BOX:
        return RenderType.TOGGLE_TREASURE_BOX_ITEM;
      case RenderLocation.SETTING_MENU_COMMON:
        return RenderType.TOGGLE_SETTING_ITEM;
      default:
        return null;
    }
  }

  getUiElements(renderLocation: RenderLocation): Map<unknown, UiElement> {
    switch (renderLocation) {
      case RenderLocation.TREASURE_BOX:
        return this.getBoxUiElements();
      case RenderLocation.SETTING_MENU_COMMON:
        return this.getSettingUiElements();
      default:
        return new Map();
    }
  }

  private getBoxUiElements(): Map<unknown, UiElement> {
    let uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement()
      .setTitle($r('app.string.assistive_grid'))
      .setAccessibilityTitle($r('app.string.assistive_grid')));

    uiElements.set(true, new UiElement().setTitle($r('app.string.assistive_grid'))
      .setIcon($r('app.media.treasure_box_assistive_grid_open'))
      .setAccessibilityTitle($r('app.string.assistive_grid'))
      .setAccessibilityDescription($r('app.string.already_on')));

    uiElements.set(false, new UiElement().setTitle($r('app.string.assistive_grid'))
      .setIcon($r('app.media.treasure_box_assistive_grid_close'))
      .setAccessibilityTitle($r('app.string.assistive_grid'))
      .setAccessibilityDescription($r('app.string.already_off')));
    return uiElements;
  }

  private getSettingUiElements(): Map<unknown, UiElement> {
    const uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.assistive_grid'))
      .setIcon($r('app.media.ic_camera_setting_assistive_grid'))
      .setAccessibilityTitle($r('app.string.assistive_grid')));
    return uiElements;
  }

  setValue(value: boolean): void {
    HiLog.i(TAG, `setValue value: ${value}.`);
    AssistiveGridFunction.isShow = value;
    this.mStoreManager.postMessage(Action.assistiveGridView(value));
    this.persistValue(value);
  }

  getValue(): boolean {
    return AssistiveGridFunction.isShow;
  }

  isAvailable(): boolean {
    return true;
  }

  private abilityOnDestroy(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'abilityOnDestroy');
  }
}