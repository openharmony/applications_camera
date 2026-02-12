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
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FocusExposureAction } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureAction';
import lazy { FocusExposureActionType } from '@ohos/common/src/main/ets/redux/actions/FocusExposureActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { FunctionActionType } from '@ohos/common/src/main/ets/redux/actions/FunctionActionType';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { RenderType } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderType';
import lazy { UiElement } from '@ohos/common/src/main/ets/function/core/UiElement';
import lazy { getStates, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { FocusModeEffectMode } from '@ohos/common/src/main/ets/function/enumbase/FocusModeEffectMode';
import lazy { PersistType } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { CameraStartType } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy { StringUtil } from '@ohos/common/src/main/ets/utils/StringUtil';
import lazy { OutputSwitcher } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcher';
import lazy { FocusData, LockLevel } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper';
import lazy { FocusExposureService } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureService';

const TAG = 'FocusFunction';

const MIN_DISTANCE = 0.001;

interface FocusState { focusState: camera.FocusState };

export class FocusFunction extends BaseFunction {
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.NONE];
  private focusData: FocusData = this.getDefaultValue();
  private valueMap: Map<string, FocusData> = new Map();
  private isExistParamConflict: boolean = false;

  constructor() {
    super();
    let cacheModeStr: string = <string> this.mPreferencesService
      .getFunctionValue(PersistType.FOREVER, FunctionId.FOCUS, '');
    this.valueMap = StringUtil.string2Map(cacheModeStr) as Map<string, FocusData>;
    HiLog.d(TAG, `constructor valueMap size: ${this.valueMap.size}.`);
    this.mEventBus.on(CameraActionType.STARTED, this.onSessionCreated.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM,
      this.onConflictParamChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FocusExposureActionType.ACTION_UPDATE_FOCUS_STATE,
      this.handleFocusStateChange, this.mBase.hashCode());
  }

  getFunctionId(): FunctionId {
    return FunctionId.FOCUS;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.NONE;
  }

  getUiElements(renderLocation: RenderLocation): Map<unknown, UiElement> {
    return new Map();
  }

  load(renderLocations: RenderLocation[]): void {
    HiLog.i(TAG, 'load E.');
    this.mEventBus.on(ActionType.ACTION_LAPSE_AUTO, this.changeStateByGlobalAuto.bind(this),
      this.mBase.hashCode());
  }

  unload(renderLocations: RenderLocation[]): void {
    super.unload(renderLocations);
    this.mEventBus.clear(this.mBase.hashCode());
  }

  async setValue(value: FocusData): Promise<void> {
    HiLog.i(TAG, `setValue Focus value is ${JSON.stringify(value)}.`);
    let focusData: FocusData = {
      focusMode: value.focusMode,
      focusPoint: value.focusPoint,
      focusValue: value.focusValue
    };
    const focusMode: camera.FocusMode = focusData.focusMode;
    if (focusMode === camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO) {
      focusData = this.getDefaultValue();
    } else if (focusMode === camera.FocusMode.FOCUS_MODE_MANUAL) {
      focusData.focusPoint = undefined;

      let focusValue: number = focusData.focusValue ?? MIN_DISTANCE;

      if (focusValue === MIN_DISTANCE) {
        focusValue = await this.mCameraProxy.getFocusDistance() || MIN_DISTANCE;
      }
      focusData.focusValue = focusValue;
    }

    if (value.isParamSetting) {
      // 来自参数设置的数据 专业模式/超级微距模式/也是摄影模式
      this.mStoreManager.postMessage(FocusExposureAction.changeFocusData(focusData));
      this.persistValue(focusData);
    } else {
      this.focusData = focusData;
    }

    this.mCameraProxy.setFocus(focusData);
  }

  protected persistValue(value?: FocusData): void {
    this.valueMap.set(this.getCacheKey(), value);
    this.mPreferencesService.putFunctionValue(PersistType.FOREVER, this.getFunctionId(),
      StringUtil.map2String(this.valueMap));
  }

  getDefaultValue(): FocusData {
    return {
      focusMode: camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO
    };
  }

  getValue(): FocusData {
    const conflicts = this.getRequiredConflicts();
    let focusData: FocusData = this.focusData;
    if (conflicts?.disabled) {
      focusData = this.getDefaultValue();
    } else if (conflicts?.limitedValue?.getValues()?.length) {
      const modes: string[] = conflicts?.limitedValue?.getValues();
      focusData = { focusMode: Number(modes[0]) };
    }

    const value: FocusData = {
      focusMode: focusData.focusMode,
      focusPoint: focusData.focusPoint,
      focusValue: focusData.focusValue
    }

    HiLog.i(TAG,
      `Focus getValue focusMode: ${focusData.focusMode}, focusPoint: ${focusData.focusPoint}, focusValue: ${focusData.focusValue}`);
    return value;
  }

  getModeValue(): number {
    let conflicts = this.getRequiredConflicts();
    HiLog.i(TAG, `getModeValue conflicts : ${conflicts?.disabled}.`);
    if (conflicts?.disabled) {
      return FocusModeEffectMode.FOCUS_MODE_CONTINUOUS_AUTO;
    }
    return this.getPersistSetValue();
  }

  getPersistSetValue(): number {
    let value: number = this.valueMap.get(this.getCacheKey())?.focusMode;
    HiLog.i(TAG, ' getModeValue: ' + value);
    return <number> (value === undefined ? 1 : value);
  }

  private async onConflictParamChange(data: { id: number }): Promise<void> {
    const currentFunctionId = this.getFunctionId();
    HiLog.i(TAG,
      `onConflictParamChange X, functionId: ${data.id}, currentFunctionId：${currentFunctionId}`);
    if (currentFunctionId !== data.id) {
      return;
    }
    const value: FocusData = this.getValue();
    const isExistParamConflict: boolean = FocusExposureService.getInstance().isConflictDisabled(FunctionId.FOCUS);
    if (isExistParamConflict || this.isExistParamConflict) {
      this.mStoreManager.postMessage(FocusExposureAction.hideFocus());
      this.isExistParamConflict = isExistParamConflict;
      this.mStoreManager.postMessage(FocusExposureAction.changeFocusData(value));
    }
    this.mCameraProxy.setFocus(value); // 可简化
  }

  private handleFocusStateChange = async (data: FocusState): Promise<void> => {
    HiLog.i(TAG, `handleFocusStateChange focusState:${data.focusState}.`);
  }

  getModeMfValue(): number {
    const cacheKey = this.getCacheKey();
    let value: number = this.valueMap.get(cacheKey)?.focusValue;
    HiLog.i(TAG, ' getModeMfValue: ' + value);
    return value ?? 0.5;
  }

  getFocusValue(): number {
    const cacheKey = this.getCacheKey();
    const focusData: FocusData = this.valueMap.get(cacheKey);
    const distance: number = focusData?.focusValue ?? MIN_DISTANCE;
    HiLog.i(TAG, 'getFocusValue distance: ' + distance);
    return distance;
  }

  isAvailable(): boolean {
    return true;
  }

  private async checkFocusStateDetectSupported(): Promise<void> {
    const isSupportedFocusStateDetect: boolean =
      await this.mCameraProxy.isSupportedFocusStateDetect(camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO);
    HiLog.i(TAG, `checkFocusStateDetectSupported isSupportedFocusStateDetect: ${isSupportedFocusStateDetect}`);
    this.mStoreManager.postMessage(FocusExposureAction.updateFocusStateDetectSupported(isSupportedFocusStateDetect));
  }

  private async onSessionCreated(data: { type: CameraStartType }): Promise<void> {
    HiLog.i(TAG, 'onSessionCreated called!.');
    if (data.type === CameraStartType.RECORD) {
      HiLog.w(TAG, 'onSessionCreated return.');
      return;
    }
    this.checkFocusStateDetectSupported();
    let focusData: FocusData = this.getDefaultValue();
    this.setValue({ focusMode: focusData.focusMode, focusValue: focusData.focusValue, isParamSetting: false });
  }

  private changeStateByGlobalAuto(data: ActionData): void {
    const property: string = 'autoType';
    const newState: number = data[property];
    if (newState === 0) {
      this.setValue({
        focusMode: FocusModeEffectMode.FOCUS_MODE_CONTINUOUS_AUTO,
        focusPoint: { x: 0, y: 0 },
        focusValue: 0,
        isParamSetting: true
      });
      if (getStates().get<number>('focusExposureReducer', 'focusMode')) {
        this.mStoreManager.postMessage(FocusExposureAction.hideFocus());
      }
    }
  }

  public resetFocus(): void {
    this.mStoreManager.postMessage(FocusExposureAction.changeFocusData(this.getDefaultValue()));
    this.persistValue();
    this.valueMap = new Map();
  }

  protected getCacheKey(mode?: ModeType): string {
    const state: OhCombinedState = getStates();
    mode = mode ? mode : state.get<ModeType>('modeReducer', 'mode');
    let key: string = '';
    key = `${mode}_${OutputSwitcher.getInstance().getOutput(mode)}_${state.get<camera.CameraPosition>('cameraReducer',
      'cameraPosition')}`;
    HiLog.d(`Function: ${this.getFunctionId()}`, `getCacheKey: ${key}.`);
    return key;
  }
}