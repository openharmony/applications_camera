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
import lazy { OutputSwitcher } from './OutputSwitcher';
import lazy { OutputType } from './OutputType';

const TAG: string = 'OutputOperation';

/**
 * 相机Output能力操作类、泛拍照/泛录像能力查询类
 * */
export class OutputOperation {
  static isPanPhotoOutput(mode: ModeType, output?: OutputType): boolean { // 专业模式、多机位模式、高像素模式需要搭配output判断
    switch (mode) {
      case ModeType.PHOTO:
      // case ModeType.APERTURE:
        return true;
      case ModeType.VIDEO:
        return false;
      default:
        if (!output) {
          output = OutputSwitcher.getInstance().getOutput(mode);
        }
        if (output === OutputType.PHOTO_OUTPUT) {
          return true;
        }
        return false;
    }
  }

  static isPanVideoOutput(mode: ModeType, output?: OutputType): boolean {
    switch (mode) {
      case ModeType.PHOTO:
      // case ModeType.APERTURE:
        return false;
      case ModeType.VIDEO:
        return true;
      default:
        if (!output) {
          output = OutputSwitcher.getInstance().getOutput(mode);
        }
        if (output === OutputType.VIDEO_OUTPUT) {
          return true;
        }
        return false;
    }
  }
}