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
import lazy { HiLog } from '../../utils/HiLog';
import type { IModeMap } from '../../mode/IModeMap';
import lazy { FunctionId } from './functionproperty/FunctionId';
import lazy { ConflictManager } from './ConflictManager';
import type { BaseMode } from '../../mode/BaseMode';
import type { BaseFunction } from './BaseFunction';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { ModeTransform } from '../../mode/ModeTransform';
import lazy { FeatureManager } from './FeatureManager';
import lazy { RenderLocation } from './functionproperty/RenderLocation';
import lazy { OutputType } from '../outputswitcher/OutputType';
import lazy { OutputSwitcher } from '../outputswitcher/OutputSwitcher';

const TAG: string = 'ModeAssembler';

export class ModeAssembler {
  private mPreFuns: Map<FunctionId, RenderLocation[]> = new Map();
  private mMode: IModeMap;
  private mFunctionsMap: Map<FunctionId, BaseFunction>;
  private mCurrentMode: BaseMode;
  private mConflictManager: ConflictManager = ConflictManager.getInstance();
  public mModeFunctionsMap: Map<string, BaseMode> = new Map();
  private static sModeAssembler: ModeAssembler;

  public static getInstance(): ModeAssembler {
    if (!ModeAssembler.sModeAssembler) {
      ModeAssembler.sModeAssembler = new ModeAssembler();
    }
    return ModeAssembler.sModeAssembler;
  }

  initMode(functionsMap: Map<FunctionId, BaseFunction>, modeMap: IModeMap): ModeAssembler {
    HiLog.i(TAG, `Constructor functionsMap.size: ${JSON.stringify(functionsMap.size)}.`);
    this.mFunctionsMap = functionsMap;
    this.mConflictManager.setFunctionsMap(functionsMap);
    this.mMode = modeMap;
    return ModeAssembler.sModeAssembler;
  }

  public assembler(currentMode: ModeType, setModeFunctionIds: Function): void {
    HiLog.i(TAG, `assembler currentMode: ${currentMode} begin.`);
    this.initModeFunction(currentMode);
    let needAdd: Map<FunctionId, RenderLocation[]> = new Map();
    let needDelete: Map<FunctionId, RenderLocation[]> = new Map();
    let currentModeFun: Map<FunctionId, RenderLocation[]> = new Map();
    this.mCurrentMode.getFunctions().forEach((value: RenderLocation[], key: FunctionId) => {
      if (this.mFunctionsMap.get(key)?.isAvailable()) {
        currentModeFun.set(key, Array.from(value)); // 避免影响源数据,深拷贝
        needAdd.set(key, Array.from(value)); // 避免影响源数据,深拷贝
      }
    }); // 当前模式加载的Function
    setModeFunctionIds(Array.from(currentModeFun.keys())); // 下面attach的load操作时需读取ModeFunctionIds,提前返回FunctionIds
    HiLog.i(TAG, `assembler preFuns: ${Array.from(this.mPreFuns.keys())}, currentModeFun: ${Array.from(currentModeFun.keys())}.`);
    if (this.mPreFuns.size > 0) {
      this.mPreFuns.forEach((value: RenderLocation[], key: FunctionId) => {
        let curLocations = needAdd.get(key);
        if (curLocations && curLocations.length > 0) {
          for (let preFunLoc of value) {
            let index = curLocations.indexOf(preFunLoc);
            if (index === -1) {
              if (needDelete.get(key)) {
                needDelete.get(key).push(preFunLoc);
              } else {
                needDelete.set(key, [preFunLoc]);
              }
            } else {
              curLocations.splice(index, 1);
              if (curLocations.length === 0) {
                needAdd.delete(key); // 没有需要增加的location，则不需要重复装载特性
              }
            }
          }
        } else {
          needDelete.set(key, value);
        }
      });
    }
    HiLog.i(TAG, `assembler needAdd = ${Array.from(needAdd.keys())}, needDelete = ${Array.from(needDelete.keys())}.`);
    this.mPreFuns = currentModeFun;
    this.attachFunction(needAdd);
    this.detachFunction(needDelete);
    this.mConflictManager.resolveConflicts(this.mCurrentMode, Array.from(currentModeFun.keys()));
    HiLog.i(TAG, 'assembler end.');
  }

  private initModeFunction(currentMode: ModeType,): void {
    if (currentMode === null) {
      currentMode = ModeType.PHOTO;
    }
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput(currentMode);
    this.mCurrentMode = this.mModeFunctionsMap.get(currentMode + '_' + outputType);
    if (!this.mCurrentMode) {
      this.mCurrentMode = this.mMode.getMode(currentMode, outputType);
      this.mModeFunctionsMap.set(currentMode + '_' + outputType, this.mCurrentMode);
    }
    this.mCurrentMode.initModeFunction(); // 初始化模式特有Function
    this.mFunctionsMap = FeatureManager.getInstance().getFunctionsMap(); // 加载模式特有Function后全量Function对象
  }

  private attachFunction(item: Map<FunctionId, RenderLocation[]>): void {
    item.forEach((value: RenderLocation[], key: FunctionId) => {
      HiLog.d(TAG, `attachFunction id: ${key}.` + value.toString());
      let functionItem: BaseFunction = this.mFunctionsMap.get(key);
      if (!functionItem) {
        HiLog.e(TAG, `attachFunction can not get funcion id: ${key}.`);
      } else {
        functionItem.load(value);
        functionItem.isLoaded = true;
      }
    });
  }

  private detachFunction(item: Map<FunctionId, RenderLocation[]>): void {
    item.forEach((value: RenderLocation[], key: FunctionId) => {
      HiLog.d(TAG, `disattachFunction id: ${key}.`);
      let functionItem: BaseFunction = this.mFunctionsMap.get(key);
      if (!functionItem) {
        HiLog.e(TAG, `disattachFunction can not get funcion id: ${key}.`);
      } else {
        functionItem.unload(value);
        functionItem.isLoaded = false;
      }
    });
  }

  public getPreFuns(): FunctionId[] {
    if (!this.mPreFuns) {
      return [];
    }
    return Array.from(this.mPreFuns.keys());
  }

  public unloadFunctions(): void {
    HiLog.i(TAG, 'ModeAssembler unLoadFunctions.' + this.mPreFuns);
    this.detachFunction(this.mPreFuns);
    this.mPreFuns = new Map();
  }
}