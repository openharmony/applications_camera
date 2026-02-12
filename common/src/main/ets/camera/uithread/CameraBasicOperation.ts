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
import camera from '@ohos.multimedia.camera';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { CameraAction } from './CameraAction';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';

const TAG: string = 'CameraBasicOperation';

export interface ReconfigurationFlowData {
  cameraPosition?: camera.CameraPosition,
  mode?: ModeType,
  isDeferred?: boolean,
  zoomRatio?: number,
  superMacroEnable?: boolean,
  watchMoonEnable?: boolean,
  physicalEnable?: boolean,
  isToDefaultWarmStart?: boolean,
  isPicker?: boolean,
  isNeedSaveRestore?: boolean
}

/* instrument ignore file */
export class CameraBasicOperation {
  /**
   * 用户连续重启流操作实现: 主要针对设置页涉及重启流按钮连续操作问题
   * 1.连续两次重启流操作,操作行为、数据缓存器;
   * 2.连续多次重启流操作,操作缓存队列按高优先级筛选器,提升性能;
   */
  private static mNextReconfigurationFlowAction: CameraAction | undefined = undefined;
  private static mNextReconfigurationFlowData: ReconfigurationFlowData | undefined = undefined;
  /**
   * 重启流场景防丢图机制: 主要针对用户拍照已见缩略图刷新但真图未上报/落盘完成场景
   * 操作行为Action、启流数据Data缓存
   */
  private static mNextReconfigFlowAction: CameraAction | undefined = undefined;
  private static mNextReconfigFlowData: ReconfigurationFlowData | undefined = undefined;

  // 连续重启流操作: 是否需要缓存Action、Data,并按需缓存
  public static getIsNeedStoreReconfigurationFlow(mCurrentFlowingActon: CameraAction, action: CameraAction,
    data: ReconfigurationFlowData): boolean {
    if (!mCurrentFlowingActon) {
      return false;
    }
    HiLog.i(TAG, `getIsNeedStoreReconfigurationFlow action: ${action}.`);
    if (CameraBasicOperation.getIsNeedReplaceFlowAction(action)) { // 是否需要替换重启流缓存队列数据
      CameraBasicOperation.mNextReconfigurationFlowAction = action;
      CameraBasicOperation.mNextReconfigurationFlowData = data;
    }
    return true;
  }

  // 连续重启流操作: 缓存队列按高优先级筛选器
  private static getIsNeedReplaceFlowAction(action: CameraAction): boolean {
    if (action === CameraActionType.CHANGE_MODE || action === CameraActionType.SWITCH_CAMERA ||
      action === CameraActionType.SWITCH_CAMERA_CHANGE_MODE || action === CameraActionType.INIT ||
      action === CameraActionType.WARM_START || action === CameraActionType.WARM_START_WITH_MODE_AND_POS) {
      return true;
    }
    if (CameraBasicOperation.mNextReconfigurationFlowAction === CameraActionType.CHANGE_MODE ||
      CameraBasicOperation.mNextReconfigurationFlowAction === CameraActionType.SWITCH_CAMERA ||
      CameraBasicOperation.mNextReconfigurationFlowAction === CameraActionType.SWITCH_CAMERA_CHANGE_MODE ||
      CameraBasicOperation.mNextReconfigurationFlowAction === CameraActionType.INIT ||
      CameraBasicOperation.mNextReconfigurationFlowAction === CameraActionType.WARM_START ||
      CameraBasicOperation.mNextReconfigurationFlowAction === CameraActionType.WARM_START_WITH_MODE_AND_POS) {
      return false; // 非低优先级启流,无需替换重启流行为
    }
    return true;
  }

  // 连续重启流操作: 获取是否存在下一次启流Action
  public static getNeedExecReconfigurationFlowAction(): CameraAction {
    return CameraBasicOperation.mNextReconfigurationFlowAction;
  }

  // 连续重启流操作: 获取并返回下一次启流Data、并清空缓存
  public static getExecReconfigurationFlowDataAndClearQueue(): ReconfigurationFlowData {
    let data = JSON.parse(JSON.stringify(CameraBasicOperation.mNextReconfigurationFlowData));
    CameraBasicOperation.mNextReconfigurationFlowAction = undefined;
    CameraBasicOperation.mNextReconfigurationFlowData = undefined;
    HiLog.i(TAG, `getExecReconfigurationFlowDataAndClearQueue data: ${data}.`);
    return data;
  }

  // 重启流场景防丢图机制: 缓存Action、Data
  public static saveReconfigFlowData(action: CameraAction, data: ReconfigurationFlowData): void {
    CameraBasicOperation.mNextReconfigFlowAction = action;
    CameraBasicOperation.mNextReconfigFlowData = data;
    HiLog.i(TAG, `saveReconfigFlowData mNextReconfigFlowAction: ${CameraBasicOperation.mNextReconfigFlowAction}.`);
  }

  public static clearReconfigFlowActionAndData(): void {
    if (!CameraBasicOperation.mNextReconfigFlowAction && !CameraBasicOperation.mNextReconfigFlowData) {
      return;
    }
    HiLog.i(TAG, 'clearReconfigFlowActionAndData X.');
    CameraBasicOperation.mNextReconfigFlowAction = undefined;
    CameraBasicOperation.mNextReconfigFlowData = undefined;
  }

  // 重启流场景防丢图机制: 获取是否存在下一次启流Action
  public static getNeedExecReconfigFlowAction(): CameraAction {
    return CameraBasicOperation.mNextReconfigFlowAction;
  }

  // 重启流场景防丢图机制: 获取并返回下一次启流Data、并清空缓存
  public static getExecReconfigFlowDataAndClearQueue(): ReconfigurationFlowData {
    let data = JSON.parse(JSON.stringify(CameraBasicOperation.mNextReconfigFlowData));
    CameraBasicOperation.mNextReconfigFlowAction = undefined;
    CameraBasicOperation.mNextReconfigFlowData = undefined;
    HiLog.i(TAG, `getExecReconfigFlowDataAndClearQueue data: ${data}.`);
    return data;
  }
}