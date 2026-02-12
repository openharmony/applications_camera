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

import lazy { ModeType } from '../../mode/ModeType';
import lazy { camera } from '@kit.CameraKit';

// 快捷列表枚举类型
export enum ShortCutMode {
  video = 'video',
  photo = 'photo',
};

// 快捷列表转换后的对象实体
export type ShortCutModeTransResult = {
  mode: ModeType,
  cameraPosition: camera.CameraPosition
};

export class ShortCutVisitService {
  private static instance: ShortCutVisitService | null = null;
  private modePositionMap: Map<ShortCutMode, ShortCutModeTransResult> = new Map();

  public static getInstance(): ShortCutVisitService {
    if (!ShortCutVisitService.instance) {
      ShortCutVisitService.instance = new ShortCutVisitService();
    }
    return ShortCutVisitService.instance;
  }

  /**
   *  获取快捷访问列表模式对应的摄像头位置
   * @param mode 模式
   * @returns 摄像头位置
   */
  public getShotCutVisitResult(mode: ShortCutMode): ShortCutModeTransResult {
    if (this.modePositionMap.size === 0) {
      this.initModePositionMap();
    }
    let shortCutResult = this.modePositionMap.get(mode);
    return shortCutResult;
  }

  /**
   * 配置快捷访问列表对应模式的摄像头位置， 若快捷访问列表调整，则该方法也需要做对应调整
   * 人像-> 后置人像
   * 自拍-> 前置人像
   * 夜景-> 后置夜景
   * 录像-> 后置录像
   */
  private initModePositionMap(): void {
    this.modePositionMap.set(ShortCutMode.video, {
      mode: ModeType.VIDEO,
      cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
    });
     this.modePositionMap.set(ShortCutMode.photo, {
      mode: ModeType.PHOTO,
      cameraPosition: camera.CameraPosition.CAMERA_POSITION_FRONT
    });
  }
}