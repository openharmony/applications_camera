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
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { getStates } from '@ohos/common/src/main/ets/redux';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';

const TAG = 'MirrorFunction';

export class MirrorFunction extends BaseFunction {
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.SETTING_MENU_COMMON];
  isMirror: boolean;

  constructor() {
    super();
    this.init();
  }

  protected init(): void {
    this.mEventBus.on(CameraActionType.STARTED, this.onSessionCreated.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_DESTROY, this.abilityOnDestroy.bind(this), this.mBase.hashCode());
  }

  getFunctionId(): FunctionId {
    return FunctionId.MIRROR;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.TOGGLE_SETTING_ITEM;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getUiElements(): Map<string | number, UiElement> {
    let uiElements = new Map();
    const isDisableFrontVideoMirror = CameraAppCapability.getInstance().getIsDisableFrontVideoMirror();
    if (DeviceInfo.isPc() || DeviceInfo.isPhone() || isDisableFrontVideoMirror) { // 当前设备禁用前置录像镜像，仅支持自拍镜像
      uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.self_mirror'))
        .setIcon($r('app.media.ic_camera_mirrow_reflection'))
        .setDesc($r('app.string.self_mirror_desp_photo'))
        .setAccessibilityTitle($r('app.string.self_mirror')));
    } else {
      uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.self_mirror'))
        .setIcon($r('app.media.ic_camera_mirrow_reflection'))
        .setDesc($r('app.string.self_mirror_desp'))
        .setAccessibilityTitle($r('app.string.self_mirror')));
    }
    return uiElements;
  }

  getDefaultValue(): boolean {
    if (DeviceInfo.isTv() && GlobalContext.get().getIsPicker()) {
      return false;
    }
    return true;
  }

  setValue(value: boolean): void {
    this.persistValue(value);
    this.mCameraProxy.setMirror(value);
  }

  getValue(): boolean { // 控制开关选择值
    const isSupported = getStates().get<boolean>('cameraReducer', 'isCameraActive') ?
      this.mCameraProxy.getIsVideoMirrorSupported() : true;
    if (DeviceInfo.isTv()) {
      if (GlobalContext.get().getIsPicker()) {
        return false;
      }
      return <boolean> this.getPersistedValue();
    }
    let isSupportRecordingFlowing = CameraAppCapability.getInstance().getIsSupportRecordingFlowing() &&
      (getStates().get<ModeType>('modeReducer', 'mode') === ModeType.VIDEO) &&
      getStates().get<RecordingState>('recordReducer', 'recordingState') !== RecordingState.READY &&
      !GlobalContext.get().getIsPicker();
    // 录像镜像、慢动作镜像
    if (isSupported || isSupportRecordingFlowing) { // nova 不断流镜像处理
      return <boolean> this.getPersistedValue();
    }
    if (OutputOperation.isPanPhotoOutput(getStates().get<ModeType>('modeReducer', 'mode'))) { // 泛拍照流镜像
      return <boolean> this.getPersistedValue();
    }
    return false;
  }

  isAvailable(): boolean {
    return true;
  }

  private onSessionCreated(): void { // 起流结束就确定该设备机型是否支持录像镜像供ui层面使用
    if (this.isFrontCamera()) {
      const isMirror = this.mCameraProxy.getIsVideoMirrorSupported();
      HiLog.i(TAG, `onSessionCreated isMirrorSupported:${isMirror}`);
      AppStorage.setOrCreate<boolean>('isMirrorSupported', isMirror);
    } else {
      AppStorage.setOrCreate<boolean>('isMirrorSupported', false);
    }
  }

  private abilityOnDestroy(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'abilityOnDestroy');
  }
}