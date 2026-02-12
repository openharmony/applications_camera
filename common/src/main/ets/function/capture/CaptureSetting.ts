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

import lazy { camera } from '@kit.CameraKit';
import lazy { display, window } from '@kit.ArkUI';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { LightPaintingType } from '../../utils/types';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { getStates } from '../../redux';

const TAG = 'CaptureSetting';

export function getCaptureSetting(position: camera.CameraPosition): camera.PhotoCaptureSetting {
  return {
    rotation: getJpegRotationCapture(position),
    quality: 1,
    mirror: getMirror()
  };
}

/* instrument ignore file */
function getMirror(): boolean {
  return FeatureManager.getInstance().getFunction(FunctionId.MIRROR).getValue();
}

export function getJpegRotationCapture(position: camera.CameraPosition): camera.ImageRotation {
  if (DeviceInfo.isTv()) {
    return <number> camera.ImageRotation.ROTATION_0;
  }
  const isLockOrientation = getStates().get<boolean>('windowReducer', 'isLockRotation'); // 锁定方向
  const orientation: display.Orientation = DisplayService.getInstance().getDisplay().orientation;
  HiLog.i(TAG, `display.orientation: ${orientation}.`);
  if ((getStates().get<boolean>('collapsReducer', 'isShowLandscape') && !getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed') &&
    WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FULL_SCREEN || DeviceInfo.isTablet()) &&
    !isLockOrientation) {
    return getFullScreenRotation(orientation, position);
  }
  return getJpegRotationCaptureWithDevice(position);
}

function getJpegRotationCaptureWithDevice(position: camera.CameraPosition): camera.ImageRotation {
  const isLockOrientation: boolean = getStates().get<boolean>('windowReducer', 'isLockRotation'); // 锁定方向
  const orientation: display.Orientation = DisplayService.getInstance().getDisplay().orientation;
  const windowStatus = WindowService.getInstance().getWindowStatus();

  if (!DeviceInfo.isPc() && !DeviceInfo.isTablet() &&
    (windowStatus === window.WindowStatusType.FLOATING || windowStatus === window.WindowStatusType.SPLIT_SCREEN ||
    PickerUtils.getIsPickerInSplitScreen()) && orientation !== display.Orientation.PORTRAIT && !isLockOrientation) {
    //展开态 悬浮窗分屏场景
    return getFloatOrSplitRotation(orientation, position);
  }

  if ((DeviceInfo.isTablet() && isLockOrientation) || DeviceInfo.isPhone()) {
    return getLockStatusRotation(position);
  }

  if (DeviceInfo.isPc()) {
    return getFullScreenRotation(orientation, position);
  }

  return checkPostionBack(position);
}

function getFullScreenRotation(orientation: display.Orientation, position: camera.CameraPosition): number {
  switch (orientation) {
    case display.Orientation.PORTRAIT:
      return camera.ImageRotation.ROTATION_0;
    case display.Orientation.LANDSCAPE:
      if (DeviceInfo.isTablet()) {
        return position === camera.CameraPosition.CAMERA_POSITION_FRONT ? camera.ImageRotation.ROTATION_270
          : camera.ImageRotation.ROTATION_90;
      }
      // pc设备根据底层上报镜头角度下发拍照角度
      return position === camera.CameraPosition.CAMERA_POSITION_FRONT ?
        (DeviceInfo.isPc() ? CameraAppCapability.getInstance().getPcCameraOrientation() :
        camera.ImageRotation.ROTATION_0) : camera.ImageRotation.ROTATION_90;
    case display.Orientation.PORTRAIT_INVERTED:
      return camera.ImageRotation.ROTATION_180;
    case display.Orientation.LANDSCAPE_INVERTED:
      if (DeviceInfo.isTablet()) {
        return position === camera.CameraPosition.CAMERA_POSITION_FRONT ? camera.ImageRotation.ROTATION_90
          : camera.ImageRotation.ROTATION_270;
      }
      return position === camera.CameraPosition.CAMERA_POSITION_FRONT ? camera.ImageRotation.ROTATION_90
        : camera.ImageRotation.ROTATION_270;
    default:
      return camera.ImageRotation.ROTATION_0;
  }
}

function getLockStatusRotation(position: camera.CameraPosition): camera.ImageRotation {
  const currentDirection: WindowDirection = getStates().get<WindowDirection>('contextReducer', 'direction');
  HiLog.i(TAG, `getPhoneRotation currentDirection: ${currentDirection}`);
  switch (currentDirection) {
    case WindowDirection.LEFT:
      return position === camera.CameraPosition.CAMERA_POSITION_FRONT ? camera.ImageRotation.ROTATION_270 :
        (camera.ImageRotation.ROTATION_270);
    case WindowDirection.RIGHT:
      return position === camera.CameraPosition.CAMERA_POSITION_FRONT ? camera.ImageRotation.ROTATION_90 :
        (camera.ImageRotation.ROTATION_90);
    case WindowDirection.BOTTOM:
      return camera.ImageRotation.ROTATION_180;
    default:
      return camera.ImageRotation.ROTATION_0;
  }
}

function getFloatOrSplitRotation(orientation: display.Orientation, position: camera.CameraPosition):
  camera.ImageRotation {
  switch (orientation) {
    case display.Orientation.PORTRAIT:
      return camera.ImageRotation.ROTATION_0;
    case display.Orientation.LANDSCAPE:
      return position === camera.CameraPosition.CAMERA_POSITION_FRONT ? camera.ImageRotation.ROTATION_270
        : camera.ImageRotation.ROTATION_90;
    case display.Orientation.PORTRAIT_INVERTED:
      return camera.ImageRotation.ROTATION_180;
    case display.Orientation.LANDSCAPE_INVERTED:
      return position === camera.CameraPosition.CAMERA_POSITION_FRONT ? camera.ImageRotation.ROTATION_90
        : camera.ImageRotation.ROTATION_270;
    default:
      return camera.ImageRotation.ROTATION_0;
  }
}


function getVdeCollapsedRotation(): camera.ImageRotation {
  const rotation: display.Orientation = DisplayService.getInstance().getDisplay().rotation;
  switch (rotation) {
    case 0: // 右
      return camera.ImageRotation.ROTATION_0;
    case 1: // 下
      return camera.ImageRotation.ROTATION_270;
    case 2: // 左
      return camera.ImageRotation.ROTATION_180;
    case 3: // 上
      return camera.ImageRotation.ROTATION_90;
    default:
      return camera.ImageRotation.ROTATION_90;
  }
}

function getGRLCollapsedRotation(orientation: display.Orientation, position: camera.CameraPosition): camera.ImageRotation {
  switch (orientation) {
    case 0: // 右
      return position === camera.CameraPosition.CAMERA_POSITION_FRONT ? camera.ImageRotation.ROTATION_270
        : camera.ImageRotation.ROTATION_90;
    case 1: // 下
      return camera.ImageRotation.ROTATION_180;
    case 2: // 左
      return position === camera.CameraPosition.CAMERA_POSITION_FRONT ? camera.ImageRotation.ROTATION_90
        : camera.ImageRotation.ROTATION_270;
    case 3: // 上
      return camera.ImageRotation.ROTATION_0;
    default:
      return camera.ImageRotation.ROTATION_0;
   }
}

function checkPostionBack(position: camera.CameraPosition): camera.ImageRotation {
  if (position === camera.CameraPosition.CAMERA_POSITION_BACK) {
    return camera.ImageRotation.ROTATION_270;
  } else {
    return camera.ImageRotation.ROTATION_0;
  }
}
