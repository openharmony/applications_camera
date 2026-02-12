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
import lazy { App2CameraModeMessage } from '../camera/DataType';
import lazy { OutputOperation } from '../function/outputswitcher/OutputOperation';
import lazy { ModeType } from './ModeType';
// import lazy { retailAuth } from '@kit.AccountKit';
import lazy { HiLog } from '../utils/HiLog';

/* instrument ignore file */
const TAG: string = 'ModeTransform';

/**
 * 应用侧模式ModeType与框架侧模式CameraMode转换类
 * 说明: (用户)应用侧由PHOTO、VIDEO等一一对应模式 + PRO、Slow等合一/特殊模式构成; 框架侧模式化能力由单一输出类型模式集合而成;
 * */
export class ModeTransform {
  /*
   * 对外提供应用侧ModeType模式转换成框架侧SceneMode模式能力
   */
  static modeType2SceneMode(mode: ModeType, cameraModeMessage: App2CameraModeMessage): camera.SceneMode {
    // 常见一一对应模式
    switch (mode) {
      case ModeType.PHOTO:
        return camera.SceneMode.NORMAL_PHOTO;
      case ModeType.VIDEO:
        return camera.SceneMode.NORMAL_VIDEO;
      default :
        return this.modeType2SceneModeByOutput(mode, cameraModeMessage);
    }
  }

  private static modeType2SceneModeByOutput(mode: ModeType, cameraModeMessage: App2CameraModeMessage):
    camera.SceneMode {
    // 拍录合一 一对二模式
    switch (mode) {
      default:
        return this.modeType2SceneModeRest(mode, cameraModeMessage);
    }
  }

  private static modeType2SceneModeRest(mode: ModeType, cameraModeMessage: App2CameraModeMessage): camera.SceneMode {
    // 不常见模式、特殊转换模式
    switch (mode) {
      default:
        return null;
    }
  }

  /*
   * 对外提供框架侧SceneMode模式转换成应用侧ModeType模式能力
   */
  static sceneMode2ModeType(cameraMode: camera.SceneMode): ModeType {
    switch (cameraMode) {
      default:
        return null;
    }
  }

}