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
import lazy { HiLog } from '../../utils/HiLog';
import lazy { BaseFunction } from '../core/BaseFunction';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';
import lazy { RenderType } from '../core/functionproperty/RenderType';
import lazy { UiElement } from '../core/UiElement';
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import camera from '@ohos.multimedia.camera';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { PropTag } from '../../service/preferences/PropTag';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { getStates } from '../../redux';

const TAG = 'CameraSwitcherFunction';

/**
 * 相机前后置摄像头切换/跨端拍照远端摄像头切换
 * */
export class CameraSwitcherFunction extends BaseFunction {
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.NONE];

  constructor() {
    super();
  }

  load(renderLocations: RenderLocation[]): void {
    super.load(renderLocations);
  }

  getFunctionId(): FunctionId {
    return FunctionId.CAMERA_SWITCHER;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.NONE;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getUiElements(): Map<string | number, UiElement> {
    let uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setIcon($r('app.media.small_switch_camera'))
      .setAccessibilityTitle($r('app.media.small_switch_camera')));
    return uiElements;
  }

  getDefaultValue(): camera.CameraPosition {
    if (DeviceInfo.isPc()) {
      const pcCameraPosition: camera.CameraPosition = CameraAppCapability.getInstance().getPcSupportCameraPosition();
      if (pcCameraPosition === camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED) {
        return camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
      }
      return camera.CameraPosition.CAMERA_POSITION_FRONT;
    }
    return camera.CameraPosition.CAMERA_POSITION_BACK;
  }

  setValue(value: camera.CameraPosition): void {
    HiLog.i(TAG, `setValue value: ${value}.`);
    PreferencesService.getInstance().putPropValue(PersistType.FOR_AWHILE, PropTag.CAMERA_POSITION, value);
  }

  getValue(): number {
    const pcCameraPosition: camera.CameraPosition = CameraAppCapability.getInstance().getPcSupportCameraPosition();
    return <number> PreferencesService.getInstance().getPropValue(PersistType.FOR_AWHILE, PropTag.CAMERA_POSITION,
      DeviceInfo.isPc() ? pcCameraPosition === camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED ?
      camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED : camera.CameraPosition.CAMERA_POSITION_FRONT :
      camera.CameraPosition.CAMERA_POSITION_BACK);
  }

  private onChangeCameraPosition(): void {

    let cameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    HiLog.begin(TAG, `onChangeCameraPosition cameraPosition:${cameraPosition}`);
    const isCustomStyleEnabled: boolean = PreferencesService.getInstance()
      .getPropValue(PersistType.FOREVER, PropTag.CUSTOM_COLOR_STYLE_ENABLED, false) as boolean ||
    getStates().get<boolean>('customFilterStyleReducer', 'customFilterEffectEnable');
    const curStyleIndex = getStates().get<number>('customFilterStyleReducer', 'styleIndex');
    if (curStyleIndex === 0 && !isCustomStyleEnabled &&
    getStates().get<boolean>('customFilterStyleReducer', 'isCustomFilterImmersive')) {
      return;
    }
    HiLog.end(TAG, `onChangeCameraPosition cameraPosition:${cameraPosition}`);
  }

  isAvailable(): boolean {
    return true;
  }
}