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
import lazy {
  SettingFuncDialogItemIndex
} from '@ohos/common/src/main/ets/component/settingview/SettingFuncDialogItemIndex';
import lazy { PersistType } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { StringUtil } from '@ohos/common/src/main/ets/utils/StringUtil';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';

const TAG = 'TimeLapseFunction';

// 定时拍摄特性
export class TimeLapseFunction extends BaseFunction {
  public static readonly TIME_LAPSE_2: number = 2;
  public static readonly TIME_LAPSE_5: number = 5;
  public static readonly TIME_LAPSE_10: number = 10;
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.SETTING_MENU_COMMON];
  private static mValueMap: Map<string, number> = new Map(); // 全量缓存数据

  constructor() {
    super();
  }

  getFunctionId(): FunctionId {
    return FunctionId.TIME_LAPSE;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.POPUP_SETTING_ITEM;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  /**
   * 照片比例展示数据组装函数
   *
   * uiElements.set(UiElement.DEFAULT...对应设置一级页面的item数据
   *  setValue(SettingFuncDialogItemIndex.INDEX_FIR)用于标识dialog二级弹窗页面的推荐值Index
   * uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE对应设置中dialog二级弹窗的(推荐)显示
   * uiElements.set(SettingFuncDialogItemIndex.xxx...对应设置中dialog二级弹窗的item数据
   */
  getUiElements(): Map<number | string, UiElement> {
    let uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.timer'))
      .setValue(this.getDefaultValue())
      .setIcon($r('app.media.ic_camera_setting_timer'))
      .setAccessibilityTitle($r('app.string.timer')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement()
      .setTitle($r('app.string.off'))
      .setAccessibilityDescription($r('app.string.off')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.already_off'))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIR)
      .setAccessibilityDescription($r('app.string.already_off')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle($r('app.string.timer_2_seconds', TimeLapseFunction.TIME_LAPSE_2))
      .setValue(SettingFuncDialogItemIndex.INDEX_SEC)
      .setAccessibilityDescription($r('app.string.timer_2_seconds', TimeLapseFunction.TIME_LAPSE_2)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle($r('app.string.timer_5_seconds', TimeLapseFunction.TIME_LAPSE_5))
      .setValue(SettingFuncDialogItemIndex.INDEX_THR)
      .setAccessibilityDescription($r('app.string.timer_5_seconds', TimeLapseFunction.TIME_LAPSE_5)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
      .setTitle($r('app.string.timer_10_seconds', TimeLapseFunction.TIME_LAPSE_10))
      .setValue(SettingFuncDialogItemIndex.INDEX_FOUR)
      .setAccessibilityDescription($r('app.string.timer_10_seconds', TimeLapseFunction.TIME_LAPSE_10)));
    if (!GlobalContext.get().getIsPicker() && CameraAppCapability.getInstance().getIsSupportedIntervalPhotoCapture()) {
      uiElements.set(SettingFuncDialogItemIndex.INDEX_FIF, new UiElement()
        .setTitle('间隔1.5秒循环拍摄')
        .setValue(SettingFuncDialogItemIndex.INDEX_FIF)
        .setAccessibilityDescription('间隔1.5秒循环拍摄'));
    }
    return uiElements;
  }

  private getVdeUIElements(): Map<number | string, UiElement> {
    let uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.timer'))
      .setValue(this.getDefaultValue())
      .setIcon($r('app.media.ic_camera_setting_timer'))
      .setAccessibilityTitle($r('app.string.timer')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement()
      .setTitle($r('app.string.off'))
      .setIcon($r('app.media.ic_camera_timer_off'))
      .setAccessibilityDescription($r('app.string.off')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle($r('app.string.timer_2_seconds', TimeLapseFunction.TIME_LAPSE_2))
      .setIcon($r('app.media.ic_camera_timer_2s'))
      .setValue(SettingFuncDialogItemIndex.INDEX_SEC)
      .setAccessibilityDescription($r('app.string.timer_2_seconds', TimeLapseFunction.TIME_LAPSE_2)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle($r('app.string.timer_5_seconds', TimeLapseFunction.TIME_LAPSE_5))
      .setIcon($r('app.media.ic_camera_timer_5s'))
      .setValue(SettingFuncDialogItemIndex.INDEX_THR)
      .setAccessibilityDescription($r('app.string.timer_5_seconds', TimeLapseFunction.TIME_LAPSE_5)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
      .setTitle($r('app.string.timer_10_seconds', TimeLapseFunction.TIME_LAPSE_10))
      .setIcon($r('app.media.ic_camera_timer_10s'))
      .setValue(SettingFuncDialogItemIndex.INDEX_FOUR)
      .setAccessibilityDescription($r('app.string.timer_10_seconds', TimeLapseFunction.TIME_LAPSE_10)));
    if (!GlobalContext.get().getIsPicker() && CameraAppCapability.getInstance().getIsSupportedIntervalPhotoCapture()) {
      uiElements.set(SettingFuncDialogItemIndex.INDEX_FIF, new UiElement()
        .setTitle('间隔1.5秒循环拍摄')
        .setValue(SettingFuncDialogItemIndex.INDEX_FIF)
        .setAccessibilityDescription('间隔1.5秒循环拍摄'));
    }
    return uiElements;
  }

  getPluralValue(num: number): string {
    return getContext(this).resourceManager.getPluralStringValueSync($r('app.plural.timer_sub_seconds').id, num);
  }

  /* instrument ignore next */
  private getOutHomeUiElements(): Map<number | string, UiElement> {
    let uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.timer'))
      .setValue(this.getDefaultValue())
      .setIcon($r('app.media.ic_camera_setting_timer'))
      .setAccessibilityTitle($r('app.string.timer')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement()
      .setTitle($r('app.string.off'))
      .setIcon($r('app.media.ic_camera_timer_off'))
      .setAccessibilityDescription($r('app.string.off')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.off'))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIR)
      .setIcon($r('app.media.ic_camera_timer_off'))
      .setAccessibilityDescription($r('app.string.off')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle(this.getPluralValue(TimeLapseFunction.TIME_LAPSE_2))
      .setIcon($r('app.media.ic_camera_timer_2s'))
      .setValue(SettingFuncDialogItemIndex.INDEX_SEC)
      .setAccessibilityDescription(this.getPluralValue(TimeLapseFunction.TIME_LAPSE_2)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle(this.getPluralValue(TimeLapseFunction.TIME_LAPSE_5))
      .setIcon($r('app.media.ic_camera_timer_5s'))
      .setValue(SettingFuncDialogItemIndex.INDEX_THR)
      .setAccessibilityDescription(this.getPluralValue(TimeLapseFunction.TIME_LAPSE_5)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
      .setTitle(this.getPluralValue(TimeLapseFunction.TIME_LAPSE_10))
      .setIcon($r('app.media.ic_camera_timer_10s'))
      .setValue(SettingFuncDialogItemIndex.INDEX_FOUR)
      .setAccessibilityDescription(this.getPluralValue(TimeLapseFunction.TIME_LAPSE_10)));
    return uiElements;
  }

  getDefaultValue(): number {
    return SettingFuncDialogItemIndex.INDEX_FIR; // off by default
  }

  setValue(value: number): void {
    HiLog.i(TAG, `setValue value: ${value}.`);
    if (AppStorage.get('restoreLittleExternalScreen')) {
      TimeLapseFunction.mValueMap.set('VerdeCollaps', this.getDefaultValue());
    }
    this.persistValue(value);
  }

  protected persistValue(value: number): void {
    TimeLapseFunction.mValueMap.set(this.getCacheKeyForTimeLapse(), value);
    this.mPreferencesService.putFunctionValue(PersistType.FOREVER, this.getFunctionId(),
      StringUtil.map2String(TimeLapseFunction.mValueMap));
  }

  // getValue
  getValue(): number {
    let valueStr = this.getPersistedValue();
    if (typeof valueStr === 'number') {
      TimeLapseFunction.mValueMap.set(this.getCacheKeyForTimeLapse(), valueStr as number);
      return valueStr as number;
    }
    TimeLapseFunction.mValueMap = StringUtil.string2Map(valueStr as string) as Map<string, number>;
    if (!TimeLapseFunction.mValueMap.has(this.getCacheKeyForTimeLapse())) {
      TimeLapseFunction.mValueMap.set(this.getCacheKeyForTimeLapse(), this.getDefaultValue());
    }
    return TimeLapseFunction.mValueMap.get(this.getCacheKeyForTimeLapse());
  }

  private getCacheKeyForTimeLapse(): string {
    return 'Others';
  }

  isAvailable(): boolean {
    return true;
  }
}