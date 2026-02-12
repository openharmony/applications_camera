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
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy {
  SettingFuncDialogItemIndex
} from '@ohos/common/src/main/ets/component/settingview/SettingFuncDialogItemIndex';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';

/* instrument ignore file */
const TAG: 'ParamBarService' = 'ParamBarService';

export type ExtraData = Record<string, string | number | boolean>;

export enum UPDATE_TYPE {
  ADD = 0,
  DELETE = 1,
  REPLACE = 2
}
;

interface FunctionVisibility {
  (functionId: FunctionId, extraData?: ExtraData): boolean;
}

export class ParamBarService {
  static instance: ParamBarService;

  // 记录显示的 functionId
  private functionVisibilityQueue: FunctionId[] = [];

  // 静态功能的显示计算
  private staticFunctionVisibilityMap: Map<FunctionId, FunctionVisibility> = new Map([
    [FunctionId.FOCUS, this.handleMacroFocusVisibility],
  ]);

  constructor() {
  }

  static getInstance(): ParamBarService {
    if (!ParamBarService.instance) {
      ParamBarService.instance = new ParamBarService();
    }

    return ParamBarService.instance;
  }

  public isStaticFunction(functionId: FunctionId): boolean {
    return this.staticFunctionVisibilityMap.has(functionId);
  }

  // 静态功能的展示与否
  public handleFunctionVisibility(functionId: FunctionId, extraData?: ExtraData): boolean {
    const getFunctionVisibility = this.staticFunctionVisibilityMap.get(functionId);
    HiLog.i(TAG,
      `handleFunctionVisibility functionId: ${functionId}, getFunctionVisibility: ${typeof getFunctionVisibility}`);
    let isVisibility: boolean = false;
    if (getFunctionVisibility) {
      isVisibility = getFunctionVisibility.call(this, functionId, extraData);
    }
    HiLog.i(TAG, `handleFunctionVisibility isVisibility: ${isVisibility}`);
    return isVisibility;
  }

  //=======================calc Visibility start=================================
  private validateFunctionSupported(functionId: FunctionId): boolean {
    const isSuppored: boolean = FeatureManager.getInstance().getModeFunctionIds().includes(functionId);
    return isSuppored;
  }

  // 美颜图标显示与否
  private handleBeautyVisibility(functionId: FunctionId,
    extraData: ExtraData = {}): boolean {
    const isSupported = this.validateFunctionSupported(functionId);
    let isVisibility: boolean = false;
    const mode: ModeType = extraData.mode as ModeType;
    const recordingState: boolean =
      extraData.recordingState === RecordingState.READY ||
        extraData.recordingState === RecordingState.STOPPING;
    if (isSupported) {
      isVisibility = false;
      if (mode === ModeType.VIDEO) {
        const stabilizationValue: boolean = true;
        const isSupport4k = FeatureManager.getInstance()?.getFunction(FunctionId
          .VIDEO_RESOLUTION)?.getValue() !== SettingFuncDialogItemIndex.INDEX_FIR;
        const isSupport60fps = FeatureManager.getInstance()?.getFunction(FunctionId
          .FRAME_RATE)?.getValue() !== SettingFuncDialogItemIndex.INDEX_SEC;

        isVisibility = stabilizationValue && recordingState &&
          !extraData.superMacroConflict && isSupport4k && isSupport60fps;
      }
    }
    HiLog.i(TAG,
      `handleBeautyShow isSupported: ${isSupported}, isVisibility: ${isVisibility}`);
    return isVisibility;
  }

  // 大光圈效果图标显示与否
  private handleApertureVisibility(functionId: FunctionId): boolean {
    const isVisibility = this.validateFunctionSupported(functionId);

    HiLog.i(TAG, `handleApertureVisibility isVisibility: ${isVisibility}`);

    return isVisibility;
  }

  // 快门图标显示与否
  private handleShutterVisibility(functionId: FunctionId, extraData: ExtraData = {}): boolean {
    const isSupported = this.validateFunctionSupported(functionId);
    const isVisibility = isSupported && extraData.cameraPosition !== camera.CameraPosition.CAMERA_POSITION_FRONT;

    HiLog.i(TAG, `handleShutterVisibility isVisibility: ${isVisibility}`);

    return isVisibility;
  }

  // 慢动作速率图标显示与否
  private handleMotionFrameRateVisibility(functionId: FunctionId, extraData: ExtraData = {}): boolean {
    const isSupported = this.validateFunctionSupported(functionId);
    const isVisibility = isSupported && extraData.slowRecordingCompVisible as boolean;
    HiLog.i(TAG, `handleMotionFrameRateVisibility isVisibility: ${isVisibility}`);
    return isVisibility;
  }

  // 微距对焦图标显示与否
  private handleMacroFocusVisibility(functionId: FunctionId, extraData: ExtraData): boolean {
    const isSupported = this.validateFunctionSupported(functionId);
    HiLog.i(TAG, `handleMotionFrameRateVisibility functionId: ${functionId}`);
    const isVisibility = isSupported && false;
    HiLog.i(TAG, `handleMotionFrameRateVisibility mode: ${extraData.mode}`);
    HiLog.i(TAG, `handleMotionFrameRateVisibility isVisibility: ${isVisibility}`);

    return isVisibility;
  }

  // 流光快门图标显示与否
  private handleLightPaintingVisibility(functionId: FunctionId): boolean {
    const isSupported = this.validateFunctionSupported(functionId);

    HiLog.i(TAG, `handleLightPaintingVisibility isVisibility: ${isSupported}`);

    return isSupported;
  }

  // 夜景图标显示与否
  private handleNightSubModeVisibility(functionId: FunctionId): boolean {
    const isSupported = this.validateFunctionSupported(functionId);
    HiLog.i(TAG, `handleNightSubModeVisibility isVisibility: ${isSupported}`);
    return isSupported;
  }


  // 百香果图标显示与否
  private handleStitchingVisibility(functionId: FunctionId, extraData: ExtraData = {}): boolean {
    const isSupported = this.validateFunctionSupported(functionId);
    const isVisibility = isSupported && extraData.cameraPosition !== camera.CameraPosition.CAMERA_POSITION_FRONT;

    HiLog.i(TAG, `handleShutterVisibility isVisibility: ${isVisibility}`);

    return isVisibility;
  }

  // 火龙果图标显示与否
  private handleCustomFilterVisibility(functionId: FunctionId, extraData: ExtraData = {}): boolean {
    const isSupported = this.validateFunctionSupported(functionId);
    const mode: ModeType = extraData.mode as ModeType;
    let isVisibility = false;
    isVisibility = isSupported;
    HiLog.i(TAG, `handleCustomFilterVisibility isVisibility: ${isVisibility}`);
    return isVisibility;
  }

  //=======================calc Visibility end=================================

  public getCurrentVisibilityFunctions(): FunctionId[] {
    HiLog.i(TAG, `getCurrentVisibilityFunctions: ${this.functionVisibilityQueue.toString()}`);
    return Array.from(this.functionVisibilityQueue);
  }

  // 删除、新增成功   已存在的不做任何处理
  /*
   * 动态图标互斥逻辑（例如超级微距和主体突出互斥）
   * 1. functionId 新加入的function，例如主体突出
   * 2. visibility 由于是新加入的，因此为true
   * 3. replacedFunctionId 需要被互斥的function，例如超级微距
   * */
  public updateVisibilityFunction(functionId: FunctionId, visibility: boolean,
    replacedFunctionId?: FunctionId): boolean {
    let type = visibility ? UPDATE_TYPE.ADD : UPDATE_TYPE.DELETE;
    const index = this.functionVisibilityQueue.indexOf(functionId);
    let replacedIndex = -1;
    if (replacedFunctionId) {
      replacedIndex = this.functionVisibilityQueue.indexOf(replacedFunctionId);
      if (type === UPDATE_TYPE.ADD && index === -1 && replacedIndex !== -1) {
        type = UPDATE_TYPE.REPLACE;
      }
    }
    HiLog.i(TAG, `updateVisibilityFunction: ${this.functionVisibilityQueue.toString()}， index: ${index}`);
    let isSuccess = true;
    if (type === UPDATE_TYPE.DELETE) {
      if (index === -1) {
        isSuccess = false;
      } else {
        this.functionVisibilityQueue.splice(index, 1);
      }
    } else if (type === UPDATE_TYPE.ADD) {
      if (index === -1) {
        this.functionVisibilityQueue.push(functionId);
      } else {
        isSuccess = false;
      }
    } else if (type === UPDATE_TYPE.REPLACE && replacedIndex !== -1) {
      this.functionVisibilityQueue[replacedIndex] = functionId;
      isSuccess = true;
    }

    return isSuccess;
  }

  public clearVisibilityFunctions(): void {
    HiLog.i(TAG, 'clearVisibilityFunctions E');
    this.functionVisibilityQueue = [];
  }
}