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
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';

const TAG = 'TimedShotFunction';

// 定时拍摄特性
export class TimedShotFunction extends BaseFunction {
  public static readonly TIMED_SHOT_2: number = 2;
  public static readonly TIMED_SHOT_5: number = 5;
  public static readonly TIMED_SHOT_10: number = 10;
  public static readonly MAX_COUNT: number = 9;
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.SETTING_MENU_COMMON];
  private static mValueMap: Map<string, number> = new Map(); // 全量缓存数据
  private isConflicted: boolean = this.getRequiredConflicts()?.disabled;

  constructor() {
    super();
  }

  getFunctionId(): FunctionId {
    return FunctionId.TIMED_SHOT;
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
  public getUiElements(): Map<number | string, UiElement> {
    let uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.timer_burst_capture'))
      .setValue(this.getDefaultValue())
      .setIcon($r('app.media.ic_camera_setting_timed_shot'))
      .setDesc($r('app.string.timer_burst_capture_total_number', TimedShotFunction.MAX_COUNT))
      .setAccessibilityTitle($r('app.string.timer_burst_capture')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement()
      .setTitle($r('app.string.off'))
      .setAccessibilityDescription($r('app.string.off')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.already_off'))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIR)
      .setAccessibilityDescription($r('app.string.already_off')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle(this.getPluralValue(TimedShotFunction.TIMED_SHOT_2))
      .setValue(SettingFuncDialogItemIndex.INDEX_SEC)
      .setAccessibilityDescription(this.getPluralValue(TimedShotFunction.TIMED_SHOT_2)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle(this.getPluralValue(TimedShotFunction.TIMED_SHOT_5))
      .setValue(SettingFuncDialogItemIndex.INDEX_THR)
      .setAccessibilityDescription(this.getPluralValue(TimedShotFunction.TIMED_SHOT_5)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
      .setTitle(this.getPluralValue(TimedShotFunction.TIMED_SHOT_10))
      .setValue(SettingFuncDialogItemIndex.INDEX_FOUR)
      .setAccessibilityDescription(this.getPluralValue(TimedShotFunction.TIMED_SHOT_10)));
    return uiElements;
  }

  private getOutHomeUIElements(): Map<number | string, UiElement> {
    let uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.timer_burst_capture_number', 9))
      .setValue(this.getDefaultValue()));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement()
      .setTitle($r('app.string.off')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.off'))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIR));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle(this.getPluralValue(TimedShotFunction.TIMED_SHOT_2))
      .setValue(SettingFuncDialogItemIndex.INDEX_SEC));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle(this.getPluralValue(TimedShotFunction.TIMED_SHOT_5))
      .setValue(SettingFuncDialogItemIndex.INDEX_THR));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
      .setTitle(this.getPluralValue(TimedShotFunction.TIMED_SHOT_10))
      .setValue(SettingFuncDialogItemIndex.INDEX_FOUR));
    return uiElements;
  }

  public getDefaultValue(): number {
    return SettingFuncDialogItemIndex.INDEX_FIR; // off by default
  }

  public setValue(value: number): void {
    HiLog.i(TAG, `setValue value: ${value}.`);
    this.persistValue(value);
  }

  private getPluralValue(num: number): string {
    return getContext(this).resourceManager
      .getPluralStringValueSync($r('app.plural.timer_interval_seconds'), num);
  }

  protected persistValue(value: number): void {
    TimedShotFunction.mValueMap.set(this.getCacheKeyForTimedShot(), value);
    this.mPreferencesService.putFunctionValue(PersistType.FOREVER, this.getFunctionId(),
      StringUtil.map2String(TimedShotFunction.mValueMap));
  }

  public getValue(): number {
    let valueStr = this.getPersistedValue();
    let conflicts = this.getRequiredConflicts();
    this.isConflicted = conflicts?.disabled;
    if (this.isConflicted) {
      return SettingFuncDialogItemIndex.INDEX_FIR;
    }
    if (typeof valueStr === 'number') {
      TimedShotFunction.mValueMap.set(this.getCacheKeyForTimedShot(), valueStr as number);
      return valueStr as number;
    }
    TimedShotFunction.mValueMap = StringUtil.string2Map(valueStr as string) as Map<string, number>;
    if (!TimedShotFunction.mValueMap.has(this.getCacheKeyForTimedShot())) {
      TimedShotFunction.mValueMap.set(this.getCacheKeyForTimedShot(), this.getDefaultValue());
    }
    return TimedShotFunction.mValueMap.get(this.getCacheKeyForTimedShot());
  }

  private getCacheKeyForTimedShot(): string {
    return 'Others';
  }

  public isAvailable(): boolean {
    return true;
  }
}