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

/* instrument ignore file */
import camera from '@ohos.multimedia.camera';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { RenderType } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderType';
import lazy { UiElement } from '@ohos/common/src/main/ets/function/core/UiElement';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { Action, ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { FunctionFirstToast, PropTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { StringUtil } from '@ohos/common/src/main/ets/utils/StringUtil';
import lazy { getStates } from '@ohos/common/src/main/ets/redux';
import lazy { ExposureData, LockLevel } from
  '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper';
import lazy { OutputSwitcher } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcher';
import lazy { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import lazy { FunctionActionType } from '@ohos/common/src/main/ets/redux/actions/FunctionActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { FocusExposureAction } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureAction';
import lazy { FocusExposureService } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureService';
import lazy { CameraStartType } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';

const TAG = 'ExposureFunction';
const EXPOSURE_MIN: number = -4;
const EXPOSURE_MAX: number = 4;

export class ExposureFunction extends BaseFunction {
  private exposureRange: number[] = undefined;
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.NONE];
  private valueMap: Map<string, ExposureData> = new Map();
  private savesPhotoValue: number = 0;
  private savesVideoValue: number = 0;
  private whetherToChange: boolean = true;
  private exposureData: ExposureData = this.getDefaultValue();
  private isExistParamConflict: boolean = false;

  constructor() {
    super();
    let cacheModeStr: string = <string> this.mPreferencesService
      .getFunctionValue(PersistType.FOREVER, FunctionId.EXPOSURE, '');
    this.valueMap = StringUtil.string2Map(cacheModeStr) as Map<string, ExposureData>;
    HiLog.d(TAG, `constructor valueMap size: ${this.valueMap.size}.`);
  }

  getFunctionId(): FunctionId {
    return FunctionId.EXPOSURE;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.NONE;
  }

  getRenderLocation(): RenderLocation {
    return RenderLocation.PARAM_BAR_RIGHT;
  }

  getUiElements(renderLocation: RenderLocation): Map<number, UiElement> {
    let uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setIcon($r('app.media.ic_camera_public_focus_ev_bright_normal')));
    return uiElements;
  }

  getDefaultValue(): ExposureData {
    return { exposureMode: camera.ExposureMode.EXPOSURE_MODE_AUTO, exposureValue: 0 };
  }

  setValue(value: ExposureData): void {
    HiLog.i(TAG, `setValue Exposure value: ${JSON.stringify(value)}.`);

    let exposureValue: number = value.exposureValue;
    if (value.isParamSetting) {
      this.persistValue(value);
      this.mStoreManager.postMessage(FocusExposureAction.changeExposureData(value));
      exposureValue += this.exposureData.exposureValue;
    } else {
      this.exposureData = {
        ...this.exposureData,
        ...value,
      };
    }
    HiLog.i(TAG, `setValue Exposure exposureValue: ${exposureValue}.`);
    if (exposureValue !== undefined) {
      exposureValue = this.getTotalExposureValue(exposureValue);
    }

    this.mCameraProxy.setExposure({
      ...value,
      exposureValue: exposureValue
    });
  }

  getTotalExposureValue(value: number): number {
    // 和全局曝光值相加
    const exposureValue: number = 0;
    if (exposureValue === 0) {
      return value;
    }
    let totalExposureValue: number = exposureValue + value;
    if (totalExposureValue >= EXPOSURE_MIN && totalExposureValue <= EXPOSURE_MAX) {
      return totalExposureValue;
    } else {
      return totalExposureValue < EXPOSURE_MIN ? EXPOSURE_MIN : EXPOSURE_MAX;
    }
  }

  getValue(): ExposureData {
    let value: ExposureData = this.exposureData;
    HiLog.i(TAG, `getValue Exposure exposureValue: ${value.exposureValue}`);
    const conflicts = this.getRequiredConflicts();
    if (conflicts?.disabled) {
      HiLog.i(TAG, `getValue Exposure disabled.`);
      value = this.getDefaultValue();
    }  else if (conflicts?.limitedValue?.getValues()?.length) {
      const modes: string[] =  conflicts?.limitedValue?.getValues();
      value = { exposureMode: Number(modes[0]), exposureValue: value.exposureValue };
    } else if (FocusExposureService.getInstance().isParamSetExposureSupported() &&
      !getStates().get<boolean>('focusExposureReducer', 'isShowFocus')) {
      value = this.getPersistSetValue();
    }
    return { ...value };
  }

  isAvailable(): boolean {
    const currMode = getStates().get<ModeType>('modeReducer', 'mode');
    return true;
  }

  load(renderLocations: RenderLocation[]): void {
    super.load(renderLocations);
    this.mEventBus.on(CameraActionType.STARTED, this.handleStartedExposureToast, this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LAPSE_AUTO, this.changeExposureToState.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM,
      this.onConflictParamChange.bind(this), this.mBase.hashCode());
  }

  private handleStartedExposureToast = (data: { type: CameraStartType }): void => {
    if (data.type === CameraStartType.RECORD) {
      HiLog.w(TAG, 'handleStartedExposureToast return.');
      return;
    }
    const exposureToastState = PreferencesService.getInstance().getPropValue(PersistType.FOREVER,
      PropTag.PRO_EXPOSURE_FIRST_TOAST, FunctionFirstToast.NONE_TOAST) as string; // 起流结束专业EV首次弹窗
    if (exposureToastState === FunctionFirstToast.NONE_TOAST) {
      PreferencesService.getInstance().putPropValue(PersistType.FOREVER,
        PropTag.PRO_EXPOSURE_FIRST_TOAST, FunctionFirstToast.SHOW_TOAST);
    }
    let value: ExposureData = this.getPersistSetValue();
    const isParamSetting: boolean = FocusExposureService.getInstance().isParamSetFocusSupported();
    if (FocusExposureService.getInstance().isParamSetExposureSupported()) {
      const conflicts = this.getRequiredConflicts();
      if (conflicts?.disabled) {
        HiLog.i(TAG, `getValue Exposure disabled.`);
        value = this.getDefaultValue();
      }
    }

    this.setValue({ ...value, isParamSetting });
  }

  protected persistValue(value?: ExposureData): void {
    this.valueMap.set(this.getCacheKey(), value);
    this.mPreferencesService.putFunctionValue(PersistType.FOREVER, this.getFunctionId(),
      StringUtil.map2String(this.valueMap));
  }

  // 仅用户获取到专业/延时摄影下 参数EV的值，将适配移除
  public getModeValue(): number {
    let conflicts = this.getRequiredConflicts();
    if (conflicts?.disabled) {
      return 0;
    }
    const exposureValue = getStates().get<number>('focusExposureReducer', 'exposureValue');
    return exposureValue;
  }

  // 将移除
  public changeExposureValue(result: boolean): void {
    HiLog.i(TAG, `changeExposureValue result: ${result}`);
    if (result === this.whetherToChange) {
      return;
    }
    this.whetherToChange = result;
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
    if (!result) {
      const value = this.getValue();
      if (outputType === OutputType.PHOTO_OUTPUT) {
        this.savesPhotoValue = value.exposureValue;
      } else {
        this.savesVideoValue = value.exposureValue;
      }
      this.setValue({
        exposureMode: camera.ExposureMode.EXPOSURE_MODE_AUTO,
        exposureValue: 0
      });
    } else {
      this.setValue({
        exposureMode: camera.ExposureMode.EXPOSURE_MODE_AUTO,
        exposureValue: outputType === OutputType.PHOTO_OUTPUT ? this.savesPhotoValue : this.savesVideoValue
      });
    }
  }

  public changeExposureAuto(): void {
    this.setValue({
      exposureMode: camera.ExposureMode.EXPOSURE_MODE_AUTO,
      exposureValue: 0
    });
  }

  private onConflictParamChange(data: { id: number }): void {
    const currentFunctionId = this.getFunctionId();
    HiLog.i(TAG,
      `onConflictParamChange X, functionId: ${JSON.stringify(data.id)}, currentFunctionId：${currentFunctionId}`);
    if (currentFunctionId !== data.id) {
      return;
    }
    const value: ExposureData = this.getValue();
    const exposureValue: number = this.getTotalExposureValue(value.exposureValue);
    this.mCameraProxy.setExposure({ ...value, exposureValue });
    const isExistParamConflict: boolean = FocusExposureService.getInstance().isConflictDisabled(FunctionId.EXPOSURE);
    if (isExistParamConflict || this.isExistParamConflict) {
      this.isExistParamConflict = isExistParamConflict;
      this.mStoreManager.postMessage(FocusExposureAction.changeExposureData(value));
    }
    this.handleExposureVisible();
  }

  public getExposureDisabled(): boolean {
    let disabled: boolean = false;
    return disabled;
  }

  private handleExposureVisible(): void {
    return;
    const disabled: boolean = this.getExposureDisabled();
    if (disabled) {
      const isShowExposure: boolean = getStates().get<boolean>('focusExposureReducer', 'isShowExposure');
      if (isShowExposure) {
        this.mStoreManager.postMessage(FocusExposureAction.updateShowExposure(false));
      }
    } else if (getStates().get<boolean>('focusExposureReducer', 'isShowFocus')) {
      const lockLevel: LockLevel = getStates().get<LockLevel>('focusExposureReducer', 'lockLevel');
      HiLog.i(TAG, `handleExposureVisible lockLevel: ${lockLevel}.`);
      if (lockLevel !== LockLevel.FOCUS_EXPOSURE_LOCK) {
        this.mStoreManager.postMessage(FocusExposureAction.updateShowExposure(true));
      }
    }
  }

  getPersistSetValue(): ExposureData | undefined {
    let value: ExposureData = this.valueMap.get(this.getCacheKey());
    HiLog.d(TAG, `Mode:${value?.exposureMode},Value:${value?.exposureValue}`);
    if (!value) {
      value = this.getDefaultValue();
    }
    return value;
  }

  unload(renderLocations: RenderLocation[]): void {
    super.unload(renderLocations);
    this.mEventBus.clear(this.mBase.hashCode());
  }

  private setExposureOnSessionDone(): void {
    HiLog.i(TAG, 'onSessionCreated called.');
    if (!this.isAvailable() || !this.isLoaded) {
      HiLog.w(TAG, 'onSessionCreated return.');
      return;
    }

    // 非专业模式下执行
    if (this.mCameraProxy.isExposureModeSupported(camera.ExposureMode.EXPOSURE_MODE_CONTINUOUS_AUTO)) {
      this.mCameraProxy.setExposure({
        exposureMode: camera.ExposureMode.EXPOSURE_MODE_CONTINUOUS_AUTO,
        exposureValue: 0.01
      });
      this.exposureRange = this.mCameraProxy.getExposureBiasRange();
      HiLog.i(TAG, `onSessionCreated ExposureBiasRange: ${JSON.stringify(this.exposureRange)}.`);
    }
  }

  private changeExposureToState(data: ActionData): void {
    const property: string = 'autoType';
    const newState: number = data[property];
    HiLog.i(TAG, `changeExposureToState value: ${newState}`);
    if (newState === 0) {
      this.setValue({
        exposureMode: camera.ExposureMode.EXPOSURE_MODE_AUTO,
        exposureValue: 0,
        isParamSetting: true
      });
    }
  }

  resetValue(): void {
    let value: ExposureData = this.getDefaultValue();
    this.persistValue(value);
    this.mStoreManager.postMessage(FocusExposureAction.changeExposureData(value));
    this.whetherToChange = false;
    this.savesPhotoValue = 0;
    this.savesVideoValue = 0;
    this.valueMap = new Map();
  }
}