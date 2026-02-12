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

import lazy { HiLog } from '../../utils/HiLog';
import lazy { BaseFunction } from '../core/BaseFunction';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { RenderType } from '../core/functionproperty/RenderType';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';
import lazy { UiElement } from '../core/UiElement';
import lazy { SettingViewAction } from '../../component/settingview/SettingViewAction';
import lazy { getStates } from '../../redux';
import { tag } from '@kit.ConnectivityKit';

const TAG = 'SettingFunction';

export type SettingViewData = {
  isShowSettingView: boolean,
  isTriggeredByBack: boolean
};

// 设置页操作入口
export class SettingFunction extends BaseFunction {
  private isShowSetting: boolean | string = false;
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.TREASURE_BOX];

  constructor() {
    super();
    this.isShowSetting = getStates().get<boolean>('settingViewReducer', 'isShowSettingView');
    HiLog.i(TAG, `当前按钮的getValue---thisisShowSetting1--${this.isShowSetting}`)
  }

  getFunctionId(): FunctionId {
    return FunctionId.SETTING;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.TOGGLE_TREASURE_BOX_ITEM;
  }

  getRenderLocations(): RenderLocation[] {
    HiLog.d(TAG, 'RenderLocation.TREASURE_BOX');
    return this.RENDER_LOCATIONS;
  }

  getDefaultValue(): boolean {
    return false;
  }

  setValue(value: SettingViewData | boolean): void {
    // setting在退后台时SettingViewData退后台的标志位，一般情情况boolean
    // 退后台特殊情况标志用于解决闪光灯事件监听的误触发操作
    /* instrument ignore else*/
    if (typeof value === 'boolean') {
      //zy-20251209-这里在设置返回的时候触发，如果把返回的false赋值，会导致下次点击后无法进入设置，先屏蔽
      // this.isShowSetting = value;
      this.mStoreManager.postMessage(SettingViewAction.showSettingView(value));
      HiLog.i(TAG, `SettingBooleanValue:${value}`);
    } else {
      // this.isShowSetting = value.isShowSettingView;
      this.mStoreManager.postMessage(SettingViewAction.showSettingView(value.isShowSettingView, !!value.isTriggeredByBack));
      HiLog.i(TAG, `SettingObjextVal${value.isShowSettingView}`);
    }
  }

  getValue(): boolean | string {
    return this.isShowSetting;
  }

  getUiElements(renderLocation: RenderLocation): Map<unknown, UiElement> {
    const uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement()
      .setTitle($r('app.string.settings'))
      .setIcon($r('app.media.treasure_box_setting'))
      .setAccessibilityTitle($r('app.string.settings')));
    uiElements.set(true, new UiElement()
      .setTitle($r('app.string.settings'))
      .setIcon($r('app.media.treasure_box_setting'))
      .setAccessibilityTitle($r('app.string.settings')));

    uiElements.set(false, new UiElement()
       .setTitle($r('app.string.settings'))
       .setIcon($r('app.media.treasure_box_setting'))
      .setAccessibilityTitle($r('app.string.settings'))
    );
    return uiElements;
  }

  isAvailable(): boolean {
    return true;
  }
}