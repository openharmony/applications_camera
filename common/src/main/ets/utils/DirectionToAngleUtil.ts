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
import lazy { WindowDirection } from './WindowDirection';
import lazy { HiLog } from './HiLog';
import lazy { getStates } from '../redux';
import lazy window from '@ohos.window';
import lazy { DisplayService } from '../service/UIAdaptive/DisplayService';
import lazy { WindowService } from '../service/window/WindowService';

const TAG: string = 'DirectionToAngleUtil';

/* instrument ignore file */
/**
 * @file: 根据方向获得旋转角度工具
 */
export class DirectionToAngleUtil {
  private static readonly ROTATE_ANGLE_0: number = 0;
  private static readonly ROTATE_ANGLE_90: number = 90;
  private static readonly ROTATE_ANGLE_180: number = 180;
  private static readonly ROTATE_ANGLE_270: number = 270;
  private static readonly ROTATE_ANGLE_NEG_90: number = -90;

  /**
   * 根据当前屏幕方向获取view旋转角度
   *
   */
  static geViewRotate(currentDirection: WindowDirection, isSettingView: boolean = false): number {
    if (AppStorage.get('windowDisplayName') === 'SuperLauncher') {
      return 0;
    }
    let orientation = 0;
    switch (currentDirection) {
      case WindowDirection.TOP:
        orientation = 0;
        break;
      case WindowDirection.BOTTOM:
        orientation = isSettingView ? 0 : DirectionToAngleUtil.ROTATE_ANGLE_180;
        break;
      case WindowDirection.RIGHT:
        orientation = DirectionToAngleUtil.ROTATE_ANGLE_90;
        break;
      case WindowDirection.LEFT:
        orientation = DirectionToAngleUtil.ROTATE_ANGLE_270;
        break;
      default:
        orientation = 0;
    }
    return orientation;
  }

  private static getVdeViewRotate(currentDirection: WindowDirection): number {
    HiLog.i(TAG, `currentDirection: ${currentDirection}`);
    switch (currentDirection) {
      case WindowDirection.TOP:
        return DirectionToAngleUtil.ROTATE_ANGLE_270;
      case WindowDirection.BOTTOM:
        return DirectionToAngleUtil.ROTATE_ANGLE_90;
      case WindowDirection.RIGHT:
        return DirectionToAngleUtil.ROTATE_ANGLE_180;
      case WindowDirection.LEFT:
        return DirectionToAngleUtil.ROTATE_ANGLE_0;
      default:
        return 0;
    }
  }

  public static getRotateAngleByWindowDirection(direction: WindowDirection): number {
    switch (direction) {
      case WindowDirection.TOP:
        return DirectionToAngleUtil.ROTATE_ANGLE_0;
      case WindowDirection.BOTTOM:
        return DirectionToAngleUtil.ROTATE_ANGLE_180;
      case WindowDirection.RIGHT:
        return DirectionToAngleUtil.ROTATE_ANGLE_90;
      case WindowDirection.LEFT:
        return DirectionToAngleUtil.ROTATE_ANGLE_NEG_90;
      default:
        return 0;
    }
  }

  public static getTwoDirectionTextRotate(direction: WindowDirection): number {//只有上下两种方向显示的text控件的角度计算适配
    let isLockRotation = getStates().get<boolean>('windowReducer', 'isLockRotation');
    let windowStatus: window.WindowStatusType = WindowService.getInstance().getWindowStatus();
    if (isLockRotation &&
      (windowStatus === window.WindowStatusType.FLOATING || windowStatus === window.WindowStatusType.SPLIT_SCREEN)) {
      const disRotation = DisplayService.getInstance().getDisplay().rotation
      switch (disRotation) {
        case 0:
          return direction === WindowDirection.BOTTOM ? DirectionToAngleUtil.ROTATE_ANGLE_180 : 0;
        case 1:
          return direction === WindowDirection.RIGHT ? DirectionToAngleUtil.ROTATE_ANGLE_180 : 0;
        case 2:
          return direction === WindowDirection.TOP ? DirectionToAngleUtil.ROTATE_ANGLE_180 : 0;
        case 3:
          return direction === WindowDirection.LEFT ? DirectionToAngleUtil.ROTATE_ANGLE_180 : 0;
        default:
          return direction === WindowDirection.BOTTOM ? DirectionToAngleUtil.ROTATE_ANGLE_180 : 0;
      }
    }
    return direction === WindowDirection.BOTTOM ? DirectionToAngleUtil.ROTATE_ANGLE_180 : 0;
  }
}
