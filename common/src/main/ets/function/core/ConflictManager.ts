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
import lazy { FunctionAction } from './FunctionAction';
import lazy { ConflictParam } from './ConflictParam';
import lazy { StoreManager } from '../../worker/StoreManager';
import camera from '@ohos.multimedia.camera';
import lazy { FunctionId } from './functionproperty/FunctionId';
import type { BaseMode } from '../../mode/BaseMode';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import lazy { PropTag } from '../../service/preferences/PropTag';
import lazy { BaseFunction } from './BaseFunction';
import lazy { ConflictParamFromFeature } from './ConflictParamFromFeature';
import lazy { getStates } from '../../redux';

const TAG: string = 'ConflictManager';

/**
 * 互斥处理类：
 * 互斥优先级：运行时互斥>function互斥=模式互斥
 * 对比之前没有优先级
 */
export class ConflictManager {
  private mPreConflicts: Map<FunctionId, ConflictParam> = new Map();
  private mRunTimeConflicts: Map<FunctionId, ConflictParam> = new Map();
  private mRunTimeConflictParamFromFeature: ConflictParamFromFeature = new ConflictParamFromFeature();
  private mFunctionsMap: Map<FunctionId, BaseFunction>;
  protected mStoreManager: StoreManager = StoreManager.getInstance();
  private static sInstanceConflictManager: ConflictManager;

  public static getInstance(): ConflictManager {
    if (!ConflictManager.sInstanceConflictManager) {
      ConflictManager.sInstanceConflictManager = new ConflictManager();
    }
    return ConflictManager.sInstanceConflictManager;
  }

  setFunctionsMap(functionsMap: Map<FunctionId, BaseFunction>): void {
    this.mFunctionsMap = functionsMap;
  }

  /**
   * 模式切换互斥处理流程：
   * 1. 不处理runtime互斥
   * 2. 合并function互斥：
   *    - 获得当期所有function互斥
   *    - 获取过程中合并
   * 3. 获取mode互斥
   * 4. 合并模式和function互斥
   * 5. 覆盖之前的互斥：
   *    - 现在有，之前也有，判断是否相同，相同不覆盖，不同合并后直接覆盖
   *    - 现在有，之前没有，直接添加
   *    - 现在没有，之前有，清理互斥
   * @param mode
   */
  resolveConflicts(mode: BaseMode, curModeFun: FunctionId[]): void {
    let curFunctionConflicts: Map<FunctionId, ConflictParam> = this.mergeFunctionConflicts(curModeFun);
    let curModeConflicts: Map<FunctionId, ConflictParam> = mode.getConflicts(this.isFrontCamera());
    let curConflicts = this.mergeModeAndFunctionConflicts(curModeConflicts, curFunctionConflicts);
    this.postConflictParam(curConflicts);
    this.mPreConflicts = curConflicts;
  }

  // 运行时触发互斥
  setConflictParam(functionId: FunctionId | FunctionId[], conflictParam: ConflictParam, needRecord: boolean = false,
    from: FunctionId = FunctionId.NONE): void {
    if (Array.isArray(functionId)) {
      functionId.forEach(id => this.setConflictParam(id, conflictParam, needRecord, from));
    } else {
      if (needRecord) {
        // 运行时多个特性对同一特性互斥，需要记录并对互斥参数与运算。非该场景needRecord勿设置true
        conflictParam = this.mRunTimeConflictParamFromFeature.setConflictParam(functionId, conflictParam, from);
      }
      if (this.mRunTimeConflicts.get(functionId) &&
      this.mRunTimeConflicts.get(functionId).equals(conflictParam)) {
        return;
      }
      if (this.mPreConflicts.get(functionId) && this.mPreConflicts.get(functionId).disabled) {
        return;
      }
      this.mRunTimeConflicts.set(functionId, conflictParam);
      this.mStoreManager.postMessage(FunctionAction.setFunctionConflictParam(functionId, conflictParam, true));
    }
  }

  getFunctionConflicts(functionId: FunctionId): ConflictParam {
    if (this.mRunTimeConflicts.get(functionId)) {
      return this.mRunTimeConflicts.get(functionId);
    }
    return this.mPreConflicts.get(functionId);
  }

  private isFrontCamera(): boolean {
    let cameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    if (GlobalContext.get().getT<boolean>('isSecurityCamera')) {
      // 锁屏相机由于init在onForeground周期，此时还无法根据state获取到前后置摄像头，采用持久化方式获取,解决自拍镜像开关不同步问题
      cameraPosition = <camera.CameraPosition> PreferencesService.getInstance()
        .getPropValue(PersistType.FOR_AWHILE, PropTag.CAMERA_POSITION, camera.CameraPosition.CAMERA_POSITION_BACK);
    }
    if (GlobalContext.get().getT<boolean>('isPcCamera')) {
      cameraPosition = <camera.CameraPosition> PreferencesService.getInstance()
        .getPropValue(PersistType.FOR_AWHILE, PropTag.CAMERA_POSITION, camera.CameraPosition.CAMERA_POSITION_FRONT);
    }
    HiLog.i(TAG, `isFrontCamera = ${cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT}.`);
    return cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT;
  }

  /**
   * 获取当前模式所有function冲突
   * 获取过程中按优先级合并
   *
   * @param curModeFun
   */
  private mergeFunctionConflicts(curModeFun: FunctionId[]): Map<FunctionId, ConflictParam> {
    let curFunctionConflicts: Map<FunctionId, ConflictParam> = new Map();
    let curFunctionConflictsKeys: Set<FunctionId> = new Set();
    curModeFun.map((id: FunctionId, index) => {
      let functionItem = this.mFunctionsMap.get(id);
      if (!functionItem) {
        HiLog.e(TAG, `mergeFunctionConflicts can not get funcion id: ${id}.`);
      } else {
        let funConflicts: Map<FunctionId, ConflictParam> = functionItem.getConflicts();
        if (funConflicts && funConflicts.size > 0) {
          funConflicts.forEach((conflictParam, functionId) => {
            if (curFunctionConflictsKeys.has(functionId)) {
              curFunctionConflicts.set(functionId, conflictParam.merge(curFunctionConflicts.get(functionId)));
            } else {
              curFunctionConflicts.set(functionId, conflictParam);
            }
            curFunctionConflictsKeys.add(functionId);
          });
        }
      }
    });
    return curFunctionConflicts;
  }

  private mergeModeAndFunctionConflicts(modeConflicts: Map<FunctionId, ConflictParam>,
                                        funConflicts: Map<FunctionId, ConflictParam>): Map<FunctionId, ConflictParam> {
    let curConflicts: Map<FunctionId, ConflictParam> = new Map();
    modeConflicts.forEach((modeConflictParam, modeFunctionId) => {
      curConflicts.set(modeFunctionId, modeConflictParam);
      funConflicts.forEach((funConflictParam, funFunctionId) => {
        if (modeFunctionId === funFunctionId) {
          curConflicts.set(funFunctionId, modeConflictParam.merge(funConflictParam));
        } else {
          curConflicts.set(funFunctionId, funConflictParam);
        }
      });
    });
    return curConflicts;
  }

  // 判断之前模式是否已经有对同一个function的相同冲突。如果有对同一个function的互斥，首先是否相同，如果相同，则不需要额外渲染，不同就需要重新渲染。
  // 由于找到了对同一个function的互斥，不管是否相同，都不需要再额外清空UX的互斥了。
  private postConflictParam(curConflicts: Map<FunctionId, ConflictParam>): void {
    let preConflictKeys = new Set(this.mPreConflicts.keys());
    curConflicts.forEach((conflictParam, functionId) => {
      let needAdd = true;
      this.mPreConflicts.forEach((preConflictParam, preFunctionId) => {
        if (functionId === preFunctionId) {
          preConflictKeys.delete(functionId);
          if (conflictParam.equals(preConflictParam)) {
            needAdd = false;
          }
        }
      });
      if (needAdd) {
        HiLog.i(TAG, 'Add current conflict: ' + functionId);
        this.mStoreManager.postMessage(FunctionAction.setFunctionConflictParam(functionId, conflictParam));
      }
    });

    preConflictKeys.forEach((key) => {
      HiLog.i(TAG, `Remove preConflict: ${key}.`);
      this.mStoreManager.postMessage(FunctionAction.setFunctionConflictParam(key, ConflictParam.emptyParam()));
    });
  }
}