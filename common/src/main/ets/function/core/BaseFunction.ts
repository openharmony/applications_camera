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

import camera from '@ohos.multimedia.camera';
import lazy { Action, UiStateMode } from '../../redux/actions/Action';
import lazy { CameraProxy } from '../../camera/uithread/CameraProxy';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { ConflictManager } from './ConflictManager';
import lazy { FunctionAction } from './FunctionAction';
import lazy { RenderType } from './functionproperty/RenderType';
import lazy { RenderLocation } from './functionproperty/RenderLocation';
import lazy { EXPIRE_MINUTE_TIME_15,
  FLUSH_TIMESTAMP,
  PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import type { EventBus } from '../../worker/eventbus/EventBus';
import type { UiElement } from './UiElement';
import type { IFunction } from './IFunction';
import type { FunctionId } from './functionproperty/FunctionId';
import type { ConflictParam } from './ConflictParam';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { HiLog } from '../../utils/HiLog';
import dataPreferences from '@ohos.data.preferences';
import lazy { OutputSwitcher } from '../outputswitcher/OutputSwitcher';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { OutputOperation } from '../outputswitcher/OutputOperation';
import lazy { getStates, OhCombinedState } from '../../redux';

const TAG = 'BaseFunction';

export abstract class BaseFunction implements IFunction {
  isLoaded: boolean = false;
  protected mBase: BaseComponent = new BaseComponent();
  protected mConflictManager: ConflictManager = ConflictManager.getInstance();
  protected mCameraProxy: CameraProxy = CameraProxy.getInstance();
  protected mStoreManager: StoreManager = StoreManager.getInstance();
  protected mPreferencesService: PreferencesService = PreferencesService.getInstance();
  protected mEventBus: EventBus = EventBusManager.getInstance().getEventBus();

  constructor() {
    if (this.getDefaultValue() !== -1) {
      this.mStoreManager.postMessage(FunctionAction.initFunctionValue(this.getFunctionId(), this.getDefaultValue()));
    }
  }

  getDefaultValue(): unknown {
    return -1;
  }

  /**
   * 指定特性在相机应用中被渲染的位置
   */
  abstract getRenderLocations(): RenderLocation[];

  /**
   * 指定特性的渲染方式，往往用于区分同一个位置不同类型的特性样式（表现形式或控制方式不同）
   */
  abstract getRenderType(renderLocation: RenderLocation): RenderType;

  /**
   * 指定支撑特性渲染的页面元素
   */
  abstract getUiElements(renderLocation: RenderLocation): Map<any, UiElement>;

  /**
   * 会在切模式或切前后置触发，用于改变其他冲突特性的值或UI状态（此function对其他function的互斥）
   */
  getConflicts(): Map<FunctionId, ConflictParam> {
    return null;
  }

  setValue(value: any, renderLocation?: RenderLocation): void {
  }

  getValue(): any {
    return -1;
  }

  /**
   * 默认功能：清除所有持久化值，清空Function临时缓存值，不下发
   */
  resetValue(): void {
  }

  /**
   * 用来控制该控件是否在对应模式可用，不可用则不显示，整个特性不加载
   */
  isAvailable(): boolean {
    return true;
  }

  /**
   * 用来控制该控件是否在对应模式可显示，无论是否显示，整个特性加载
   */
  isShow(): boolean {
    return true;
  }

  /**
   * 用来控制该控件是否在TabBar显示，无论是否显示，整个特性加载，默认采用当前Function自身的isShow()方法
   */
  isTabBarShow(): boolean {
    return this.isShow();
  }

  load(renderLocations: RenderLocation[]): void {
    HiLog.d(TAG, `load functionId: ${this.getFunctionId()} E.`);
    for (let location of renderLocations) { // 按location维度更新map里set元素
      if (location !== RenderLocation.NONE && this.getRenderLocations().includes(location)) {
        this.mStoreManager.postMessage(FunctionAction.addFunction(this.getFunctionId(), location));
      }
    }
    HiLog.d(TAG, `load functionId: ${this.getFunctionId()} X.`);
  }

  unload(renderLocations: RenderLocation[]): void {
    HiLog.d(TAG, `unload functionId: ${this.getFunctionId()} E.`);
    for (let location of renderLocations) {
      if (location !== RenderLocation.NONE && this.getRenderLocations().includes(location)) {
        this.mStoreManager.postMessage(FunctionAction.removeFunction(this.getFunctionId(), location));
      }
    }
    HiLog.d(TAG, `unload functionId: ${this.getFunctionId()} X.`);
  }

  abstract getFunctionId(): FunctionId;

  protected enableUi(): void {
    this.mStoreManager.postMessage(Action.uiState(true));
  }

  protected disableUi(): void {
    this.mStoreManager.postMessage(Action.uiState(false));
  }

  protected enableUiWithMode(uiStateMode: UiStateMode): void {
    this.mStoreManager.postMessage(Action.uiStateWithMode(true, uiStateMode));
  }

  protected disableUiWithMode(uiStateMode: UiStateMode): void {
    this.mStoreManager.postMessage(Action.uiStateWithMode(false, uiStateMode));
  }

  protected persistValue(value: unknown): void {
    this.mPreferencesService.putFunctionValue(PersistType.FOREVER, this.getFunctionId(), value as dataPreferences.ValueType);
  }

  protected getPersistedValue(): dataPreferences.ValueType {
    return this.mPreferencesService.getFunctionValue(PersistType.FOREVER, this.getFunctionId(), (this.getDefaultValue() as number | string | boolean));
  }

  /**
   * 获取所有对此Function的互斥
   */
  protected getRequiredConflicts(): ConflictParam {
    return this.mConflictManager.getFunctionConflicts(this.getFunctionId());
  }

  protected isFrontCamera(): boolean {
    return getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') === camera.CameraPosition.CAMERA_POSITION_FRONT;
  }

  protected getCacheKey(mode?: ModeType): string {
    const state: OhCombinedState = getStates();
    mode = mode ? mode : state.get<ModeType>('modeReducer', 'mode');
    let key : string = '';
    if (!OutputOperation.isPanPhotoOutput(getStates().get<ModeType>('modeReducer', 'mode'))) {
      key = `${mode}_false_${state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition')}`;
    } else if (!OutputOperation.isPanPhotoOutput(getStates().get<ModeType>('modeReducer', 'mode'))) {
      key = `${mode}_false_${state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition')}`;
    } else {
      key = `${mode}_${OutputSwitcher.getInstance().getOutput(mode)}_${state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition')}`;
    }
    HiLog.d(`Function: ${this.getFunctionId()}`, `getCacheKey: ${key}.`);
    return key;
  }
}