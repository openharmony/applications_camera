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
import lazy { ModeType } from '../../mode/ModeType';
import camera from '@ohos.multimedia.camera';
import lazy { OutputType } from '../outputswitcher/OutputType';

const TAG: string = 'ShutterController';

export class ShutterController {
  icon: Resource;
  width: number;
  height: number;
  type: ButtonType;
  stateEffect: boolean;
  private static sInstanceShutterController: ShutterController;

  public static getInstance(): ShutterController {
    if (!ShutterController.sInstanceShutterController) {
      ShutterController.sInstanceShutterController = new ShutterController();
    }
    return ShutterController.sInstanceShutterController;
  }

  getParam(): void {
    this.icon = $r('app.media.ic_circled_filled');
    this.width = 76;
    this.height = 76;
    this.type = ButtonType.Circle;
    this.stateEffect = true;
  }

  getButtonType(mode: ModeType, outputType: OutputType, position?: camera.CameraPosition): ShutterButtonType {
    let shutterButtonType: ShutterButtonType = ShutterButtonType.NULL;
    switch (mode) {
      case ModeType.PHOTO:
        shutterButtonType = ShutterButtonType.NORMAL_CAPTURE;
        break;
      case ModeType.VIDEO:
        shutterButtonType = ShutterButtonType.NORMAL_VIDEO;
        break;
      default:
        shutterButtonType = this.getShutterButtonType(mode, outputType, position);
        break;

    }
    return shutterButtonType;
  }

  private getShutterButtonType(mode: ModeType, outputType: OutputType, position?: camera.CameraPosition): ShutterButtonType {
    let shutterButtonType: ShutterButtonType = ShutterButtonType.NULL;
    return shutterButtonType;
  }
}

export enum ShutterButtonType {
  NULL = -1,
  NORMAL_CAPTURE = 0,
  SECOND_CAPTURE = 1,
  NORMAL_VIDEO = 2,
}