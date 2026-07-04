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
import type image from '@ohos.multimedia.image';
import lazy { DeviceInfo } from '../component/deviceinfo/DeviceInfo';
import lazy { HiLog } from './HiLog';
import camera from '@ohos.multimedia.camera';
import display from '@ohos.display';
import lazy { DisplayService } from '../service/UIAdaptive/DisplayService';
import lazy { effectKit } from './LazyImportUtil';
import lazy { FunctionId } from '../function/core/functionproperty/FunctionId';
import lazy { PickerUtils } from './PickerUtils';
import lazy { ModeType } from '../mode/ModeType';
import lazy { getStates } from '../redux';
import lazy { window } from '@kit.ArkUI';
import lazy { CameraAppCapability } from '../camera/CameraAppCapability';
import lazy { GlobalContext } from './GlobalContext';
import { ComponentSnapshotService } from '../service/componentSnapshot/ComponentSnapshotService';

const TAG: string = 'BlurAnimateUtil';

/* instrument ignore file */
export class BlurAnimateUtil {
  public static readonly IMG_ROTATE_ANGLE_0: number = 0;
  public static readonly IMG_ROTATE_ANGLE_90: number = 90;
  public static readonly IMG_ROTATE_ANGLE_180: number = 180;
  public static readonly IMG_ROTATE_ANGLE_270: number = 270;
  public static readonly IMG_FLIP_ANGLE_0: number = 0;
  public static readonly IMG_FLIP_ANGLE_180: number = 180;
  public static readonly IMG_FLIP_ANGLE_90: number = 90;
  public static readonly IMG_FLIP_ANGLE_270: number = 270;
  public static readonly IMG_FLIP_ANGLE_MINUS_90: number = -90;

  public static readonly SHOW_BLUR_DURATION: number = 200;
  public static readonly HIDE_BLUR_DURATION: number = 150;
  public static readonly HIDE_BLUR_DURATION_SHORT: number = 100;
  public static readonly HIDE_BLUR_DELAY_50: number = 50;
  public static readonly HIDE_BLUR_DELAY_200: number = 200;
  public static readonly CHANGE_PREVIEW_DURATION: number = 200;
  public static readonly ROTATION_DURATION: number = 200;
  public static readonly SWITCH_TIMEOUT: number = 300;
  public static readonly FLIP_DELAY: number = 50;
  public static readonly ROTATE_AXIS: number = 0.5;
  public static readonly IMG_SCALE: number = 0.75;

  public static readonly KIT_BLUR_RADIUS_48: number = 58;
  public static readonly KIT_BLUR_RADIUS_28: number = 28;

  public static isColdFrameStart: boolean = false;
  public static superMacroFlag: boolean = false;

  private static mScreenshotPixelMap: image.PixelMap;
  private static mCachedScreenshotPixelMap: image.PixelMap;
  private static mBlurPixelAngle: number = 0;
  private static validFrameFlag: boolean = true;
  private static waitForPositionFlag: boolean = false;
  private static isInSwitchCamera: boolean = false;
  private static isContinuousSwitch: boolean = false;
  private static hasShowBlurWhenExit: boolean = false;
  // record camera position when create snapshot from surface
  private static cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  private static functionNeedBlur: Set<FunctionId> = new Set([
    FunctionId.ASPECT_RATIO,
    FunctionId.VIDEO_RESOLUTION,
    FunctionId.FRAME_RATE]);
  private static needStitchingAnim: boolean = false;

  // 截图作预览模糊动效场景,对外封装模块方法
  public static generatePixelMapFromSurface(isBigToSmall?: boolean): null | image.PixelMap {
    let mode = getStates().get<ModeType>('modeReducer', 'mode');
    let position = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    try {
      if (!this.getValidFrameFlag()) {
        HiLog.w(TAG, `wait for first frame`);
        return null;
      }
      let snapPixelMap = ComponentSnapshotService.getInstance().generateSnapshotImg(mode);
      if (!snapPixelMap) {
        HiLog.e(TAG, 'ComponentSnapshotService generateSnapshotImg pixelMap is null.')
        return null;
      }
      BlurAnimateUtil.setBlurPixelMap(snapPixelMap);
      BlurAnimateUtil.setBlurPixelAngle(position, isBigToSmall);
      BlurAnimateUtil.setCameraPostion(position);
      if (DeviceInfo.isPc() || DeviceInfo.isTablet()) {
        BlurAnimateUtil.rotatePixelMap(snapPixelMap, position);
      }
      return snapPixelMap;
    } catch (e) {
      HiLog.e(TAG, 'generatePixelMapFromSurface err: ' + e.code)
      return null;
    }
  }

  // 方式2: 直接针对PixelMap执行旋转,如截图做缩略图等场景
  public static rotatePixelMap(pixelMap: image.PixelMap, cameraPosition: camera.CameraPosition): void {
    let rotateAngle: number = BlurAnimateUtil.getBlurPixelMapRotateAngle(cameraPosition);
    HiLog.i(TAG, 'rotatePixelMap rotateAngle:' + rotateAngle);
    if (rotateAngle === BlurAnimateUtil.IMG_ROTATE_ANGLE_0) {
      return;
    }
    pixelMap.rotateSync(rotateAngle);
  }

  // 获取PixelMap在当前形态下的需旋转角度,内部封装
  private static getBlurPixelMapRotateAngle(cameraPosition: camera.CameraPosition, isBigToSmall?: boolean): number {
    if (DeviceInfo.isTv()) {
      return BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
    }
    if (DeviceInfo.isPc()) { // harden和Hopper旋转模糊缩略图角度不同
      let angle = CameraAppCapability.getInstance().getPcCameraOrientation();
      return angle === BlurAnimateUtil.IMG_ROTATE_ANGLE_0 ? angle : BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
    }
    if (DeviceInfo.isTablet()) {
      if (PickerUtils.getIsTabletTopBottomSplitScreenFromReducer() ||
      PickerUtils.getIsTabletVerticalFullScreenFromReducer()) {
        return (getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
        camera.CameraPosition.CAMERA_POSITION_FRONT) ?
          BlurAnimateUtil.IMG_ROTATE_ANGLE_270 : BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
      }
      return BlurAnimateUtil.getTabletImgRotate(cameraPosition);
    }
    const dis: display.Display = DisplayService.getInstance().getDisplay();
    if (PickerUtils.getIsExpandedTopBottomSplitScreen()) {
      return DisplayService.getInstance().isOrientationVertical() ?
        BlurAnimateUtil.IMG_ROTATE_ANGLE_180 : BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
    }
    const isShowLandscape: boolean = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    const isShowTricollaps: boolean = getStates().get<boolean>('collapsReducer', 'isShowTricollaps');
    if ((getStates().get<window.WindowStatusType>('windowReducer', 'windowStatus') ===
    window.WindowStatusType.SPLIT_SCREEN ||
      isShowLandscape && !isShowTricollaps) ||
    PickerUtils.getIsPicker()) {
      return BlurAnimateUtil.getLandscapeRotation(dis, cameraPosition);
    } else {
      return BlurAnimateUtil.getScapeRotation(dis.orientation, cameraPosition, isBigToSmall);
    }
  }

  private static getScapeRotation(orientation: display.Orientation, cameraPosition: camera.CameraPosition,
    isBigToSmall?: boolean): number {
    HiLog.i(TAG, 'getScapeRotation orientation:' + orientation);
    let angle = DeviceInfo.isUis7885() ? BlurAnimateUtil.IMG_ROTATE_ANGLE_90 : BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
    switch (orientation) {
      case 0:
        return (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) ? angle :
          isBigToSmall ? BlurAnimateUtil.IMG_ROTATE_ANGLE_180 : angle;
      case 1:
        return (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) ?
          BlurAnimateUtil.IMG_ROTATE_ANGLE_180 : isBigToSmall ?
            BlurAnimateUtil.IMG_ROTATE_ANGLE_270 : BlurAnimateUtil.IMG_ROTATE_ANGLE_180;
      case 2:
        return (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) ?
          BlurAnimateUtil.IMG_ROTATE_ANGLE_90 : isBigToSmall ?
            BlurAnimateUtil.IMG_ROTATE_ANGLE_180 : BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
      case 3:
        return (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) ?
          BlurAnimateUtil.IMG_ROTATE_ANGLE_0 : isBigToSmall ?
            BlurAnimateUtil.IMG_ROTATE_ANGLE_270 : BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
      default:
        return (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) ?
          BlurAnimateUtil.IMG_ROTATE_ANGLE_270 : BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
    }
  }

  private static getTabletImgRotate(cameraPosition: camera.CameraPosition): number {
    const windowDirection: number = DisplayService.getInstance().getDisplay().orientation;
    switch (windowDirection) {
      case 0:
        return (cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) ? BlurAnimateUtil.IMG_ROTATE_ANGLE_90 :
          BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
      case 1:
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_180;
      case 2:
        return (cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) ? BlurAnimateUtil.IMG_ROTATE_ANGLE_270 :
          BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
      case 3:
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
      default:
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
    }
  }

  private static getLandscapeRotation(dis: display.Display, cameraPosition: camera.CameraPosition): number {
    switch (dis.orientation) {
      case 0:
        return (cameraPosition !== camera.CameraPosition.CAMERA_POSITION_FRONT ||
        getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed')) ?
          BlurAnimateUtil.IMG_ROTATE_ANGLE_90 : BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
      case 1:
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_180;
      case 2:
        return (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) ?
          BlurAnimateUtil.IMG_ROTATE_ANGLE_90 : BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
      case 3:
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
      default:
        return (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) ?
          BlurAnimateUtil.IMG_ROTATE_ANGLE_270 : BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
    }
  }

  private static getVdeCollapsScreenRotation(): number {
    const rotation: number = DisplayService.getInstance().getDisplay().rotation;
    switch (rotation) {
      case 0: // 右
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
      case 1: // 下
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_180;
      case 2: // 左
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
      case 3: // 上
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
      default:
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
    }
  }

  private static getTriCollapsScreenRotationForThumbnail(): number {
    const cameraPosition: camera.CameraPosition =
      getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    HiLog.d(TAG, `getTriCollapsScreenRotation cameraPosition: ${cameraPosition}.`);

    const rotation: number = DisplayService.getInstance().getDisplay().rotation;
    HiLog.d(TAG, `getTriCollapsScreenRotation rotation: ${rotation}.`);
    switch (rotation) {
      case 0: // 右
        if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
        }
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
      case 1: // 下
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_180;
      case 2: // 左
        if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) {
          return BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
        }
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
      case 3: // 上
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
      default:
        return BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
    }
  }

  public static setBlurPixelMap(pixelMap: image.PixelMap, noNeedToRelease?: boolean): void {
    HiLog.i(TAG, 'set blur pixelMap');
    if (BlurAnimateUtil.mScreenshotPixelMap !== undefined && !noNeedToRelease && !GlobalContext.get().getIsPicker()) {
      HiLog.i(TAG, 'release blur pixelMap');
      BlurAnimateUtil.mScreenshotPixelMap.release();
    }
    BlurAnimateUtil.mScreenshotPixelMap = pixelMap;
    BlurAnimateUtil.mBlurPixelAngle = 0;
  }

  public static setCachedBlurPixelMap(pixelMap: image.PixelMap): void {
    HiLog.i(TAG, 'set blur mCachedScreenshotPixelMap');
    BlurAnimateUtil.mCachedScreenshotPixelMap = pixelMap;
    BlurAnimateUtil.mBlurPixelAngle = 0;
  }

  public static getCachedBlurPixelMap(): image.PixelMap {
    HiLog.i(TAG, 'get blur pixelMap');
    return BlurAnimateUtil.mCachedScreenshotPixelMap;
  }

  public static getBlurPixelMap(): image.PixelMap {
    HiLog.i(TAG, 'get blur pixelMap');
    if (!BlurAnimateUtil.mScreenshotPixelMap) {
      HiLog.w(TAG, 'pixelMap is null');
    }
    return BlurAnimateUtil.mScreenshotPixelMap;
  }

  // 方式1: 记录PixelMap需旋转的角度,Image渲染时再设置属性值,如预览模糊动效等场景
  private static setBlurPixelAngle(cameraPosition: camera.CameraPosition, isBigToSmall?: boolean): void {
    BlurAnimateUtil.mBlurPixelAngle = BlurAnimateUtil.getBlurPixelMapRotateAngle(cameraPosition, isBigToSmall);
    HiLog.i(TAG, 'setBlurPixelAngle: ' + BlurAnimateUtil.mBlurPixelAngle);
  }

  public static getBlurPixelAngle(): number {
    return BlurAnimateUtil.mBlurPixelAngle;
  }

  public static async releasePixelMap(): Promise<void> {
    HiLog.i(TAG, 'release blur pixelMap');
    BlurAnimateUtil.isColdFrameStart = false;
    BlurAnimateUtil.mScreenshotPixelMap.release();
  }

  public static setValidFrameFlag(frameFlag: boolean): void {
    HiLog.i(TAG, 'setValidFrameFlag: ' + frameFlag);
    this.validFrameFlag = frameFlag;
  }

  public static getValidFrameFlag(): boolean {
    HiLog.i(TAG, 'getValidFrameFlag: ' + BlurAnimateUtil.validFrameFlag);
    return BlurAnimateUtil.validFrameFlag;
  }

  public static setWaitForPositionFlag(value: boolean): void {
    BlurAnimateUtil.waitForPositionFlag = value;
  }

  public static getWaitForPositionFlag(): boolean {
    return BlurAnimateUtil.waitForPositionFlag;
  }

  public static async generateBlurByEffectKit(pixelMap: image.PixelMap, isLowBlur: boolean): Promise<image.PixelMap> {
    HiLog.i(TAG, 'blur pixelmap by effectKit');
    if (pixelMap) {
      let blurRadius: number = isLowBlur ? BlurAnimateUtil.KIT_BLUR_RADIUS_28 : BlurAnimateUtil.KIT_BLUR_RADIUS_48;
      // @ts-ignore
      return await effectKit.createEffect(pixelMap)?.blur(blurRadius, 0)?.getEffectPixelMap(false);
    }
    return pixelMap;
  }

  public static checkIfNeedBlur(id: FunctionId): boolean {
    return this.functionNeedBlur.has(id);
  }

  public static setInSwitchCamera(flag: boolean): void {
    BlurAnimateUtil.isInSwitchCamera = flag;
  }

  public static getIsInSwitchCamera(): boolean {
    return BlurAnimateUtil.isInSwitchCamera;
  }

  public static setCameraPostion(cameraPosition: camera.CameraPosition): void {
    BlurAnimateUtil.cameraPosition = cameraPosition;
  }

  public static getCameraPosition(): camera.CameraPosition {
    return BlurAnimateUtil.cameraPosition;
  }

  public static setIsContinuousSwitch(state: boolean): void {
    BlurAnimateUtil.isContinuousSwitch = state;
  }

  public static getIsContinuousSwitch(): boolean {
    return BlurAnimateUtil.isContinuousSwitch;
  }

  public static setHasShowBlurWhenExit(state: boolean): void {
    BlurAnimateUtil.hasShowBlurWhenExit = state;
  }

  public static getHasShowBlurWhenExit(): boolean {
    return BlurAnimateUtil.hasShowBlurWhenExit;
  }

  public static setStitchingAnimate(needAnimate: boolean): void {
    BlurAnimateUtil.needStitchingAnim = needAnimate;
  }

  public static getStitchingAnimate(): boolean {
    return BlurAnimateUtil.needStitchingAnim;
  }
}