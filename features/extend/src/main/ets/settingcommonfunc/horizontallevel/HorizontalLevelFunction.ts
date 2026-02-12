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

import lazy { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { RenderType } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderType';
import lazy { UiElement } from '@ohos/common/src/main/ets/function/core/UiElement';
import lazy { HorizontalLevelOperation } from './HorizontalLevelOperation';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { ThumbnailActionType } from '@ohos/common/src/main/ets/redux/actions/ThumbnailActionType';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { window } from '@kit.ArkUI';
import lazy { getStates } from '@ohos/common/src/main/ets/redux';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';

const TAG = 'HorizontalLevelFunction';

interface PhotoBrowserStatus {
  photoBrowserStatus: boolean
};

export class HorizontalLevelFunction extends BaseFunction {
  private mHorizontalOperation: HorizontalLevelOperation = HorizontalLevelOperation.getInstance();
  private isShowHorizontalLevel: boolean = false;
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.SETTING_MENU_COMMON];

  constructor() {
    super();
    this.isShowHorizontalLevel = <boolean> this.getPersistedValue();
  }

  //应用进入前台是根据value值决定是否开启传感器
  onForeground(): void {
    //TODO 这里因为图标旋转的问题，需要依赖这个，所有这个界面需要开启
    // if (this.getValue()) {
      this.mHorizontalOperation.enableGListener();
    // }
  }

  onBackground(): void {
    // if (this.getValue()) {
    //TODO 这里因为图标旋转的问题，需要依赖这个，同理离开这个界面需要关闭
      this.mHorizontalOperation.disableGListener();
    // }
  }

  getFunctionId(): FunctionId {
    return FunctionId.HORIZONTAL_LEVEL;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.TOGGLE_SETTING_ITEM;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getUiElements(): Map<string | number, UiElement> {
    let uiElements: Map<string | number, UiElement> = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.horizontal_level'))
      .setIcon($r('app.media.ic_camera_setting_horizontal_level'))
      .setAccessibilityTitle($r('app.string.horizontal_level')));
    return uiElements;
  }

  getDefaultValue(): boolean {
    return false;
  }

  setValue(value: boolean): void {
    value ? this.mHorizontalOperation.enableGListener() : this.mHorizontalOperation.disableGListener();
    this.isShowHorizontalLevel = value;
    this.persistValue(value);
  }

  getValue(): boolean {
    // 直板机Picker分屏不支持水平仪
    const isInSplitScreen: boolean =
      WindowService.getInstance().getWindowStatus() === window.WindowStatusType.SPLIT_SCREEN;
    const isShowDefault: boolean = getStates().get<boolean>('collapsReducer', 'isShowDefault');
    const isPicker: boolean = GlobalContext.get().getIsPicker();
    if (isInSplitScreen && isShowDefault && isPicker && DeviceInfo.isPhone()) {
      return false;
    }
    let mode = getStates().get<ModeType>('modeReducer', 'mode');
    return this.isShowHorizontalLevel;
  }

  isAvailable(): boolean {
    return DeviceInfo.isPhone() || DeviceInfo.isTablet() ? true : false;
  }

  load(renderLocations: RenderLocation[]): void {
    super.load(renderLocations);
    this.getValue() ? this.mHorizontalOperation.enableGListener() : this.mHorizontalOperation.disableGListener();
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.PHOTOBROWSER_STATUS, (data: PhotoBrowserStatus) =>
    this.handlePhotoBrowser(data.photoBrowserStatus), this.mBase.hashCode());
  }

  unload(renderLocations: RenderLocation[]): void {
    super.unload(renderLocations);
    this.mEventBus.clear(this.mBase.hashCode());
    if (this.getValue()) {
      this.mHorizontalOperation.disableGListener();
    }
  }


  // 打开大图组件关闭重力传感器监听，返回相机重新打开
  private handlePhotoBrowser(photoBrowserStatus: boolean): void {
    if (photoBrowserStatus) {
      this.mHorizontalOperation.disableGListener();
    } else {
      if (this.getValue() && !AppStorage.get('isBackground')) {
        this.mHorizontalOperation.enableGListener();
      }
    }
  }
}