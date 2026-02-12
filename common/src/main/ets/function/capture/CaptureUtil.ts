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
import lazy { HiLog } from '../../utils/HiLog';
import lazy { image } from '@kit.ImageKit';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { display } from '@kit.ArkUI';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { camera } from '@kit.CameraKit';
import lazy { WindowService } from '../../service/window/WindowService';
import window from '@ohos.window';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { getStates } from '../../redux';

const TAG: string = 'CaptureUtil';
const PIXEL_MAP_ROTATE_0: number = 0;
const PIXEL_MAP_ROTATE_90: number = 90;
const PIXEL_MAP_ROTATE_180: number = 180;
const PIXEL_MAP_ROTATE_270: number = 270;

export class CaptureUtil {
  public static async execScreenshotThumbnail(): Promise<image.PixelMap> {
    HiLog.i(TAG, 'execScreenshotThumbnail E.');
    let pixelMap: image.PixelMap = null;
    try {
      if (!pixelMap) {
        HiLog.e(TAG, 'The generateSnapshotImg pixelMap is null.');
        return pixelMap;
      }
      HiLog.i(TAG, 'execScreenshotThumbnail pixelMap X.');
      let pixelMapRotate: number = this.getPixelMapRotate();
      let isMirror: boolean = FeatureManager.getInstance().getFunction(FunctionId.MIRROR)?.getValue();
      HiLog.i(TAG, `execScreenshotThumbnail pixelMapRotate: ${pixelMapRotate}, isMirror: ${isMirror}.`);
      if (!DeviceInfo.isPc()) {
        await pixelMap.rotate(pixelMapRotate);
      }
      if (isMirror) {
        await pixelMap.flip(true, false);
      }
    } catch (err) {
      HiLog.e(TAG, `execScreenshotThumbnail err: ${JSON.stringify(err)}.`);
    }
    return pixelMap;
  }

  private static getPixelMapRotate(): number {
    let pixelMapRotate: number;
    const currentDirection: WindowDirection = getStates().get<WindowDirection>('contextReducer', 'direction');
    const position = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    const isShowLandscape: boolean = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    const isShowSemiCollapsed: boolean = getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed');
    const dis: display.Display = DisplayService.getInstance().getDisplay();
    const windowStatus = WindowService.getInstance().getWindowStatus();
    const isLockOrientation = getStates().get<boolean>('windowReducer', 'isLockRotation');
    if (DeviceInfo.isTablet()) {
      const currentDirection: WindowDirection = getStates().get<WindowDirection>('contextReducer', 'direction');
      return isLockOrientation ? this.getNormalLockRotate(currentDirection, position) :
      this.getUnlockTabletRotateAngle(position, dis);
    }
    if ((isShowLandscape && !isShowSemiCollapsed) ||
      ((windowStatus === window.WindowStatusType.FLOATING || windowStatus === window.WindowStatusType.SPLIT_SCREEN) &&
        dis.rotation !== 0 && !isLockOrientation)) {
      pixelMapRotate = CaptureUtil.getFloatSplitRotate(dis, position);
    } else {
      pixelMapRotate = this.getNormalLockRotate(currentDirection, position);
    }
    HiLog.i(TAG, 'pixelMapRotate :' + pixelMapRotate);
    return pixelMapRotate;
  }

  private static getFloatSplitRotate(dis: display.Display, position: camera.CameraPosition): number {
    let pixelMapRotate = 0;
    switch (dis.orientation) {
      case 0:
        pixelMapRotate =
          position === camera.CameraPosition.CAMERA_POSITION_FRONT ? PIXEL_MAP_ROTATE_270 : PIXEL_MAP_ROTATE_90;
        break;
      case 1:
        pixelMapRotate = PIXEL_MAP_ROTATE_180;
        break;
      case 2:
        pixelMapRotate =
          position === camera.CameraPosition.CAMERA_POSITION_FRONT ? PIXEL_MAP_ROTATE_90 : PIXEL_MAP_ROTATE_270;
        break;
      case 3:
        pixelMapRotate = PIXEL_MAP_ROTATE_0;
        break;
      default:
        pixelMapRotate = PIXEL_MAP_ROTATE_90;
    }
    return pixelMapRotate;
  }

  private static getNormalLockRotate(currentDirection: WindowDirection, position: camera.CameraPosition): number {
    switch (currentDirection) { // 锁定状态组件截图旋转角度矫正
      case WindowDirection.TOP:
        return (position === camera.CameraPosition.CAMERA_POSITION_FRONT && !AppStorage.get('isLemCollaps')) ?
          PIXEL_MAP_ROTATE_270 : PIXEL_MAP_ROTATE_90;
      case WindowDirection.BOTTOM:
        return (position === camera.CameraPosition.CAMERA_POSITION_FRONT && !AppStorage.get('isLemCollaps')) ?
          PIXEL_MAP_ROTATE_90 : PIXEL_MAP_ROTATE_270;
      case WindowDirection.LEFT:
        return AppStorage.get('isLemCollaps') ? 0 : PIXEL_MAP_ROTATE_180;
      default:
        return AppStorage.get('isLemCollaps') ? PIXEL_MAP_ROTATE_180 : 0;
    }
  }

  private static getUnlockTabletRotateAngle(position: camera.CameraPosition, display: display.Display): number {
    switch (display.orientation) { // 非锁定状态平板组件截图旋转角度矫正
      case 0:
        return position === camera.CameraPosition.CAMERA_POSITION_FRONT ? PIXEL_MAP_ROTATE_270 : PIXEL_MAP_ROTATE_90;
      case 1:
        return PIXEL_MAP_ROTATE_0;
      case 2:
        return position === camera.CameraPosition.CAMERA_POSITION_FRONT ? PIXEL_MAP_ROTATE_90 : PIXEL_MAP_ROTATE_270;
      default:
        return PIXEL_MAP_ROTATE_180;
    }
  }
}