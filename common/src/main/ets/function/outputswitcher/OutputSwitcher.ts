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
import lazy { OutputType } from './OutputType';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { CameraAction } from '../../camera/uithread/CameraAction';
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import lazy { Action } from '../../redux/actions/Action';
import lazy { PropTag } from '../../service/preferences/PropTag';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { FrameRateFunction } from '../framerate/FrameRateFunction';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { execDispatch, getStates } from '../../redux';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { ActionType } from '../../redux/actions/ActionType';

const TAG = 'OutputSwitcher';
export const MULTIPLE_OUTPUTS_MODES: ModeType[] = [
];

/**
 * 相机同一模式下PhotoOutput/VideoOutput能力切换
 * */
export class OutputSwitcher {
  private static sInstance: OutputSwitcher;
  private mBase: BaseComponent = new BaseComponent();
  private eventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private outputType: OutputType = OutputType.PHOTO_OUTPUT;

  public static getInstance(): OutputSwitcher {
    if (!OutputSwitcher.sInstance) {
      OutputSwitcher.sInstance = new OutputSwitcher();
    }
    return OutputSwitcher.sInstance;
  }

  constructor() {
    let catchValue = PreferencesService.getInstance().getPropValue(PersistType.FOREVER, PropTag.OUTPUT_SWITCHER,
      OutputType.PHOTO_OUTPUT) as OutputType;
    const mode = getStates().get<ModeType>('modeReducer', 'mode');
    HiLog.i(TAG, `syncCatchData outputType: ${this.outputType}, catchValue: ${catchValue}`);
    if (MULTIPLE_OUTPUTS_MODES.includes(mode) && !catchValue) {
      catchValue = OutputType.PHOTO_OUTPUT;
    }
    this.outputType = catchValue;
    this.eventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.SWITCH_CAMERA_CHANGE_MODE],
      this.handleModeChange.bind(this), TAG);
    this.eventBus.on(ActionType.MORE_MODE_SLIDER_DOUBLE_STREAM_MODE, () => this.sliderDoubleStreamFromMoreMode(),
      this.mBase.hashCode());
    this.eventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, () => this.handleBackground(), TAG);
  }

  public setOutput(type: OutputType): void {
    HiLog.i(TAG, `setValue old outputType: ${this.outputType}, new type: ${type}.`);
    if (this.outputType === type) {
      return;
    }
    this.outputType = type;
    execDispatch(CameraAction.changeOutputType(this.outputType));
    const mode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
    execDispatch(Action.updateXComponentShot(mode, mode, false, this.outputType, type));
  }

  public getOutput(mode?: ModeType): OutputType {
    mode = mode ? mode : getStates().get<ModeType>('modeReducer', 'mode');
    if (MULTIPLE_OUTPUTS_MODES.includes(mode)) {
      return this.outputType;
    }
    return OutputType.NONE;
  }

  public getDefaultOutput(mode?: ModeType): OutputType {
    mode = mode ? mode : getStates().get<ModeType>('modeReducer', 'mode');
    if (MULTIPLE_OUTPUTS_MODES.includes(mode)) {
      return OutputType.PHOTO_OUTPUT;
    }
    return OutputType.NONE;
  }

  private handleModeChange(): void {
    this.outputType = OutputType.PHOTO_OUTPUT;
    PreferencesService.getInstance().putPropValue(PersistType.FOREVER, PropTag.OUTPUT_SWITCHER, this.outputType);
  };

  private sliderDoubleStreamFromMoreMode(): void {
    this.setOutput(OutputType.PHOTO_OUTPUT); // 从更多页回来恢复默认拍照流
  }

  // 处于（微距）录像模式时，存储模式值，再次进入相机时，进入该模式
  private handleBackground(): void {
    HiLog.i(TAG, `handleBackground outputType: ${this.outputType}`);
    PreferencesService.getInstance().putPropValue(PersistType.FOREVER, PropTag.OUTPUT_SWITCHER, this.outputType);
  }
}