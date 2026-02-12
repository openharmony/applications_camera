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
import window from '@ohos.window';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { GlobalContext } from '../../utils/GlobalContext';

/* instrument ignore file */
const TAG: string = 'XComponentService';

export class XComponentService {
  private static instance: XComponentService;

  private xComponentController: XComponentController;
  private collaborateXComponentController: XComponentController;
  private surfaceQueue: string[] = [];
  private collaborateSurfaceId: string = '';

  public static getInstance(): XComponentService {
    if (!XComponentService.instance) {
      XComponentService.instance = new XComponentService();
    }
    return XComponentService.instance;
  }

  private constructor() {
  }

  public init(controller: XComponentController): void {
    this.xComponentController = controller;
  }

  public initCollaborate(controller: XComponentController): void {
    this.collaborateXComponentController = controller;
  }

  public getController(): XComponentController {
    return this.xComponentController;
  }

  public getCollaborateController(): XComponentController {
    return this.collaborateXComponentController;
  }

  public createSurface(): string {
    if (!this.xComponentController) {
      HiLog.e(TAG, 'createSurface error, xComponentController is undefined.');
      return '';
    }
    const surface: string = this.xComponentController.getXComponentSurfaceId();
    if (!this.surfaceQueue.includes(surface)) {
      HiLog.i(TAG, `createSurface, surface: ${surface}.`);
      this.surfaceQueue.push(surface);
    } else {
      HiLog.e(TAG, `createSurface error, surface is created: ${surface}.`);
    }
    return surface;
  }

  /**
   * 创建协同屏 surfaceID
   *
   * @returns string，协同屏surfaceID
   */
  public createCollaborateSurface(): string {
    if (!this.xComponentController) {
      HiLog.e(TAG, 'createCollaborateSurface error, xComponentController is undefined.');
      return '';
    }
    const surface: string = this.collaborateXComponentController.getXComponentSurfaceId();
    this.collaborateSurfaceId = surface;
    return surface;
  }

  public getCollaborateSurface(): string {
    return this.collaborateSurfaceId;
  }

  public deleteCollaborateSurface(): void {
    this.collaborateSurfaceId = '';
  }

  public getSurfaceQueue(): string[] {
    return this.surfaceQueue;
  }

  public getSurface(): string | undefined {
    if (this.surfaceQueue.length === 0) {
      HiLog.e(TAG, 'getSurface error, surface: undefined.');
      return undefined;
    }
    return this.surfaceQueue[this.surfaceQueue.length - 1];
  }

  public deleteSurface(): string {
    if (this.surfaceQueue.length === 0) {
      HiLog.e(TAG, 'deleteSurface error, surfaceQueue length: 0.');
      return '';
    }
    const surface: string = this.surfaceQueue.shift();
    HiLog.i(TAG, `deleteSurface, surface: ${surface}.`);
    return surface;
  }

  public lockCollaborateSurface(isLock: boolean): void {
    if (!this.collaborateXComponentController) {
      HiLog.e(TAG, 'lockCollaborateSurface error, collaborateXComponentController is undefined.');
      return;
    }
    this.collaborateXComponentController.setXComponentSurfaceRotation({ lock: isLock });
    HiLog.i(TAG, `lockCollaborateSurface, isLock: ${isLock}.`);
  }

  public lockSurface(isLock: boolean): void {
    if (!this.xComponentController) {
      HiLog.e(TAG, 'lockSurface error, xComponentController is undefined.');
      return;
    }
    const windowStatus = WindowService.getInstance().getWindowStatus();
    if ((windowStatus === window.WindowStatusType.FLOATING &&
      !(DeviceInfo.isTablet() && GlobalContext.get().getIsPicker())) ||
      windowStatus === window.WindowStatusType.SPLIT_SCREEN || PickerUtils.getIsExpandedSplitScreen()) { //悬浮窗和分屏场景不支持锁定预览接口
      HiLog.e(TAG, 'lockSurface error, windowStatus is full_screen.');
      this.xComponentController.setXComponentSurfaceRotation({ lock: false });
      AppStorage.setOrCreate('setXCRotation', false);
      return;
    }
    this.xComponentController.setXComponentSurfaceRotation({ lock: isLock });
    AppStorage.setOrCreate('setXCRotation', true);
    HiLog.i(TAG, `lockSurface, isLock: ${isLock}.`);
  }
}

/*
 * ts文件无法使用ets头文件，复制d.ts文件使用
 */
declare class XComponentController {
  getXComponentSurfaceId(): string;

  getXComponentContext(): Object;

  setXComponentSurfaceSize(value: {
    surfaceWidth: number;
    surfaceHeight: number;
  }): void;

  setXComponentSurfaceRect(rect: SurfaceRect): void;

  getXComponentSurfaceRect(): SurfaceRect;

  setXComponentSurfaceRotation(rotationOptions: SurfaceRotationOptions): void;

  getXComponentSurfaceRotation(): Required<SurfaceRotationOptions>;

  onSurfaceCreated(surfaceId: string): void;

  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void;

  onSurfaceDestroyed(surfaceId: string): void;

  startImageAnalyzer(config: ImageAnalyzerConfig): Promise<void>;

  stopImageAnalyzer(): void;
}

interface SurfaceRect {
  offsetX?: number;
  offsetY?: number;
  surfaceWidth: number;
  surfaceHeight: number;
}

interface SurfaceRotationOptions {
  lock?: boolean;
}

interface ImageAnalyzerConfig {
  types: number[];
}
