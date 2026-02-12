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
import lazy { CaptureFunction } from '../capture/CaptureFunction';
import lazy { RecordControlFunction } from '../recordcontrol/RecordControlFunction';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { FunctionId } from './functionproperty/FunctionId';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { ModeAssembler } from './ModeAssembler';
import lazy { ZoomFunction } from '../zoombar/ZoomFunction';
import lazy { CameraSwitcherFunction } from '../cameraswitcher/CameraSwitcherFunction';
import lazy { AspectRatioFunction } from '../aspectratio/AspectRatioFunction';
import lazy { SettingFunction } from '../setting/SettingFunction';
import type { BaseFunction } from './BaseFunction';
import type { IModeMap } from '../../mode/IModeMap';
import type { EventBus } from '../../worker/eventbus/EventBus';
import type { ModeType } from '../../mode/ModeType';
import lazy { CameraStartType } from '../../camera/uithread/CameraAction';
import lazy { DirectionFunction } from '../direction/DirectionFunction';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import type image from '@ohos.multimedia.image';
import lazy { CameraBasicService } from '../../camera/uithread/CameraBasicService';
import lazy { FrameRateFunction } from '../framerate/FrameRateFunction';
import lazy { VideoResolutionFunction } from '../videoresolution/VideoResolutionFunction';
import type { RenderLocation } from './functionproperty/RenderLocation';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { getStates } from '../../redux';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { FunctionActionType } from '../../redux/actions/FunctionActionType';

const TAG: string = 'FeatureManager';

export class FeatureManager {
  private mBase: BaseComponent = new BaseComponent();
  mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mModeAssembler: ModeAssembler;
  private mFunctionsMap: Map<FunctionId, BaseFunction> = new Map(); // 全量Function对象
  private mModeFunctionIds: FunctionId[] = []; // 仅当前模式加载的Function
  private static sInstanceFeatureManager: FeatureManager;
  private isInResolutionChange: boolean = false;
  private surfaceSize: image.Size = { height: 0, width: 0 };

  public static getInstance(): FeatureManager {
    if (!FeatureManager.sInstanceFeatureManager) {
      FeatureManager.sInstanceFeatureManager = new FeatureManager();
    }
    return FeatureManager.sInstanceFeatureManager;
  }

  constructor() {
    this.initFunctionsMap();
    // 接收到modeChange的消息，调用changeMode做处理
    this.mEventBus.on(CameraActionType.STARTED, this.onCameraStarted.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.RECOVER_CAMERA, () => this.managerAssembler(), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, this.changeFunctionValue.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SWITCH_CAMERA_CHANGE_MODE_ONLY,
      this.onSwitchCameraAndChangeMode.bind(this), this.mBase.hashCode());
  }

  init(mode: ModeType, modeMap: IModeMap): void {
    if (!!this.mModeAssembler && this.mModeAssembler.getPreFuns().length !== 0 && !GlobalContext.get().getIsPicker()) {
      return;
    }
    HiLog.i(TAG, 'init.');
    modeMap.initExtendFeatures(); // 动态添加拓展特性分段初始化
    this.mModeAssembler = ModeAssembler.getInstance().initMode(this.mFunctionsMap, modeMap);
    this.managerAssembler();
  }

  getFunction(functionId: FunctionId): BaseFunction {
    return <BaseFunction> this.mFunctionsMap.get(functionId);
  }

  private onCameraStarted(data: { type: CameraStartType }): void {
    if (data.type === CameraStartType.CHANGE_MODE ||
      data.type === CameraStartType.CHANGE_OUTPUT_TYPE ||
      data.type === CameraStartType.SWITCH_CAMERA ||
      data.type === CameraStartType.SWITCH_CAMERA_CHANGE_MODE ||
      data.type === CameraStartType.WARM_START_WITH_MODE_AND_POS ||
      data.type === CameraStartType.COLD_START ||
      data.type === CameraStartType.COLLAPS_CHANGE
    ) { // 性能测试无明显影响;主干上暂以COLD_START去managerAssembler装载特性,可行性验证
      this.managerAssembler();
    }
  }

  private managerAssembler(mode?: ModeType): void {
    mode = mode || getStates().get<ModeType>('modeReducer', 'mode');
    this.mModeAssembler.assembler(mode, this.setModeFunctionIds.bind(this));
  }

  public unLoadFunctions(): void {
    HiLog.i(TAG, 'featureManager unLoadFunctions.');
    this.mModeAssembler.unloadFunctions();
  }

  private changeFunctionValue(data: {
    id: FunctionId,
    value: object,
    renderLocation: RenderLocation
  }): void {
    if (FunctionId.ASPECT_RATIO === data.id || FunctionId.VIDEO_RESOLUTION === data.id ||
      FunctionId.FRAME_RATE === data.id) {
      this.setIsInResolution(true);
      this.surfaceSize = CameraBasicService.getInstance().getSurfaceSize(getStates().get<ModeType>('modeReducer', 'mode'));
    }
    HiLog.i(TAG, `setValue----changeFunctionValue---${data.id}----${JSON.stringify(data.value)}-----${data.renderLocation}`)
    this.mFunctionsMap.get(data.id)?.setValue(data.value, data.renderLocation);
  }

  private onSwitchCameraAndChangeMode(): void {
    this.managerAssembler();
  }

  public setIsInResolution(value: boolean): void {
    this.isInResolutionChange = value;
  }

  public getIsInResolution(): boolean {
    return this.isInResolutionChange;
  }

  public getSurfaceSize(): image.Size {
    return this.surfaceSize;
  }

  private initFunctionsMap(): void {
    HiLog.i(TAG, 'initFunctionsMap invoke E.');
    this.mFunctionsMap.set(FunctionId.FRAME_RATE, new FrameRateFunction());
    this.mFunctionsMap.set(FunctionId.CAPTURE, new CaptureFunction());
    this.mFunctionsMap.set(FunctionId.RECORD_CONTROL, new RecordControlFunction());
    this.mFunctionsMap.set(FunctionId.ZOOM, new ZoomFunction());
    this.mFunctionsMap.set(FunctionId.CAMERA_SWITCHER, new CameraSwitcherFunction());
    this.mFunctionsMap.set(FunctionId.ASPECT_RATIO, new AspectRatioFunction());
    this.mFunctionsMap.set(FunctionId.VIDEO_RESOLUTION, new VideoResolutionFunction());
    this.mFunctionsMap.set(FunctionId.SETTING, new SettingFunction());
    this.mFunctionsMap.set(FunctionId.DIRECTION, new DirectionFunction());
    HiLog.i(TAG, `initFunctionsMap invoke X FunctionsMapSize: ${this.mFunctionsMap.size}.`);
  }

  public setExtendFunctionsMap(funcId: FunctionId, funcObj): void {
    this.mFunctionsMap.set(funcId, funcObj);
  }

  public setModeUniqueFunctionsMap(funcId: FunctionId, funcObj): void {
    this.mFunctionsMap.set(funcId, funcObj);
  }

  public getFunctionsMap(): Map<FunctionId, BaseFunction> {
    return this.mFunctionsMap;
  }

  public setModeFunctionIds(currentModeFun: FunctionId[]): void {
    this.mModeFunctionIds = currentModeFun;
  }

  public getModeFunctionIds(): FunctionId[] {
    return this.mModeFunctionIds;
  }

  public isAvailableFunction(functionId: FunctionId): boolean {
    return this.mModeAssembler.getPreFuns().includes(functionId);
  }
}