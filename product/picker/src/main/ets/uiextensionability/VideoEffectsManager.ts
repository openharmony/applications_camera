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
import lazy { simpleStringify } from '@ohos/common/src/main/ets/utils/SimpleStringify';
import lazy { Context, UIExtensionContentSession } from '@kit.AbilityKit';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';

const TAG: string = 'VideoEffectsManager';

export interface SupportedEffectTypes {
  supportedVirtualApertures: boolean,
  supportedBeautyRange: boolean
}

export class VideoEffectsManager {
  private static sInstance: VideoEffectsManager;
  // @ts-ignore
  private mSession: camera.ControlCenterSession;
  private mCameraManager: camera.CameraManager;
  private mSupportedVirtualApertures: number[] = [];
  private mBeautyVal: number = 0;
  private mApertureVal: number = 0;
  private mExtSession: UIExtensionContentSession;

  public static getInstance(): VideoEffectsManager {
    if (!VideoEffectsManager.sInstance) {
      VideoEffectsManager.sInstance = new VideoEffectsManager();
    }
    return VideoEffectsManager.sInstance;
  }

  public setCameraManager(cameraManager: camera.CameraManager): void {
    this.mCameraManager = cameraManager;
  }

  public init(context: Context, session: UIExtensionContentSession): void {
    HiLog.i(TAG, 'init');
    this.mCameraManager = camera.getCameraManager(context);
    this.mExtSession = session;
    try {
      // @ts-ignore
      this.mSession = this.mCameraManager.createControlCenterSession();
      this.initSupportedVirtualApertures();
    } catch (e) {
      HiLog.e(TAG, `init fail, error: ${simpleStringify(e)}`);
    }
  }

  public sendData(data: Record<string, Object>): void {
    this.mExtSession?.sendData(data);
  }

  public release(): void {
    HiLog.i(TAG, 'release');
    this.mCameraManager = null;
    this.mSession = null;
  }

  public getSupportedEffectTypes(): SupportedEffectTypes {
    HiLog.i(TAG, 'getSupportedEffectTypes');
    const supportedEffectTypes: SupportedEffectTypes = {
      supportedVirtualApertures: false,
      supportedBeautyRange: false
    };
    try {
      supportedEffectTypes.supportedVirtualApertures = this.mSession.getSupportedVirtualApertures()?.length > 0;
      supportedEffectTypes.supportedBeautyRange = this.mSession.getSupportedBeautyRange(0).length > 0;
      HiLog.d(TAG, `supportedEffectTypes: supportedVirtualApertures - ${supportedEffectTypes.supportedVirtualApertures},
       supportedBeautyRange - ${supportedEffectTypes.supportedBeautyRange}`);
    } catch (e) {
      HiLog.e(TAG, `getSupportedEffectTypes fail, err: ${simpleStringify(e)}`);
    }
    return supportedEffectTypes;
  }

  /**
   * 初始化虚拟光圈范围
   */
  public initSupportedVirtualApertures(): void {
    try {
      this.mSupportedVirtualApertures = this.mSession.getSupportedVirtualApertures();
      this.mSupportedVirtualApertures.reverse();
      HiLog.d(TAG, `supportedVirtualApertures = ${JSON.stringify(this.mSupportedVirtualApertures)}`);
    } catch (e) {
      HiLog.e(TAG, `initSupportedVirtualApertures fail, error: ${simpleStringify(e)}`);
    }
  }

  /**
   * 获取支持的光圈范围
   *
   * @returns
   */
  public getSupportedVirtualApertures(): number[] {
    return this.mSupportedVirtualApertures;
  }

  /**
   * 获取光圈的调节档位
   *
   * @returns
   */
  public getVirtualAperturesLevels(): number {
    const levels = VideoEffectsManager.getInstance().getSupportedVirtualApertures()?.length - 1;
    return levels > 0 ? levels : 10;
  }

  /**
   * 获取当前美颜值
   *
   * @returns
   */
  public getCurrentBeautyValue(): number {
    let beautyLevel: number = 0;
    try {
      beautyLevel = this.mSession.getBeauty(camera.BeautyType.AUTO);
      this.mBeautyVal = beautyLevel;
    } catch (err) {
      HiLog.e(TAG, `getCurrentBeautyValue fail, ${simpleStringify(err)}`);
    }
    HiLog.i(TAG, `getCurrentBeautyValue, value = ${beautyLevel}`);
    return beautyLevel;
  }

  /**
   * 设置当前美颜值
   *
   * @param value
   */
  public setCurrentBeautyValue(value: number): void {
    HiLog.i(TAG, `setCurrentBeautyValue = ${value}`);
    try {
      this.mSession.setBeauty(camera.BeautyType.AUTO, value);
      this.mBeautyVal = value;
    } catch (err) {
      HiLog.e(TAG, `setCurrentBeautyValue fail, err:${simpleStringify(err)}`);
    }
  }

  /**
   * 获取当前背景虚化值
   *
   * @returns
   */
  public getCurrentApertureValue(): number {
    let aperture: number = 0;
    let value: number = 0;
    try {
      aperture = this.mSession.getVirtualAperture();
      this.mApertureVal = aperture;
      HiLog.i(TAG, `getCurrentApertureValue, aperture = ${aperture}`);
    } catch (err) {
      HiLog.e(TAG, `getCurrentApertureValue fail, err: ${simpleStringify(err)}`);
    }
    for (let index = 0; index < this.mSupportedVirtualApertures.length; index++) {
      if (aperture === this.mSupportedVirtualApertures[index]) {
        value = index;
      }
    }
    HiLog.i(TAG, `getCurrentApertureValue, value = ${aperture}`);
    return value;
  }

  /**
   * 设置当前背景虚化值
   *
   * @param value
   */
  public setCurrentApertureValue(value: number): void {
    HiLog.i(TAG, `setCurrentApertureValue = ${value}`);
    const index = value;
    const aperture = this.mSupportedVirtualApertures[index];
    HiLog.i(TAG, `setCurrentAperture aperture = ${aperture}`);
    try {
      this.mSession?.setVirtualAperture(aperture);
      this.mApertureVal = aperture;
    } catch (error) {
      HiLog.e(TAG, `setVirtualAperture call failed. error code: ${simpleStringify(error)}`);
    }
  }
}