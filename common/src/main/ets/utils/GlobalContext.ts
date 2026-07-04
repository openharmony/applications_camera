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

import type Want from '@ohos.app.ability.Want';
import type window from '@ohos.window';
import type { Context } from '@ohos.abilityAccessCtrl';
import lazy { uiExtensionHost } from '@kit.ArkUI';
import lazy { HiLog } from './HiLog';
import lazy { CameraService } from '../camera/childthread/CameraService';
import lazy { CommonConstants } from '../statistics/CommonConstants';
import lazy { errorManager } from '@kit.AbilityKit';

const TAG: string = 'GlobalContext';

export class GlobalContext {
  private constructor() {
  }

  private static instance: GlobalContext;
  private _objects = new Map<string, Object>();
  private securityUIExtensionHostWindowProxy: uiExtensionHost.UIExtensionHostWindowProxy;
  private cameraAbilityWant: Want;
  private cameraNewWant: Want;
  private windowStage: window.WindowStage;
  // @ts-ignore
  private pipXComponentController: XComponentController;
  // @ts-ignore
  private panoramaXComponentController: XComponentController;
  private panoramaSurfaceQueue: string[] = [];
  private isPicker: boolean = false;
  private jumpToBrowser: boolean = false;
  private workerContext: Context = null;
  private cameraShotKey: string = '';
  private lastCameraShotKey: string = '';
  private filePath: string;
  private photoBrowserDisabled: boolean = false;
  private screenReaderEnabled: boolean = false;
  private mCameraService: CameraService;
  private ismOpenTouchGuide: boolean = false;
  private errorObserverId: number = CommonConstants.INVALID_ID;


  public static get(): GlobalContext {
    if (!Boolean(GlobalContext.instance).valueOf()) {
      GlobalContext.instance = new GlobalContext();
    }
    return GlobalContext.instance;
  }

  getObject(value: string): Object {
    return this._objects.get(value);
  }

  getT<T>(value: string): T {
    return this._objects.get(value) as T;
  }

  setObject(key: string, objectClass: Object): void {
    this._objects.set(key, objectClass);
  }

  apply(value: string): void {
    const func = this._objects.get(value);
    if (func) {
      (func as Function)();
    }
  }

  public getCameraAbilityWant(): Want {
    return this.cameraAbilityWant;
  }

  public setCameraAbilityWant(want: Want): void {
    this.cameraAbilityWant = want;
  }

  public getCameraNewWant(): Want {
    return this.cameraNewWant;
  }

  public setCameraNewWant(want: Want): void {
    this.cameraNewWant = want;
  }

  public getWindowStage(): window.WindowStage {
    return this.windowStage;
  }

  public setWindowStage(stage: window.WindowStage): void {
    this.windowStage = stage;
  }

  // @ts-ignore
  public getPipXComponentController(): XComponentController {
    return this.pipXComponentController;
  }

  public setPipXComponentController(controller): void {
    this.pipXComponentController = controller;
  }

  // @ts-ignore
  public getPanoramaXComponentController(): XComponentController {
    return this.panoramaXComponentController;
  }

  public setPanoramaXComponentController(controller): void {
    this.panoramaXComponentController = controller;
  }

  public createPanoramaSurface(): string {
    if (!this.panoramaXComponentController) {
      HiLog.e(TAG, 'createPanoramaSurface error, xComponentController is undefined.');
      return '';
    }
    const surface: string = this.panoramaXComponentController.getXComponentSurfaceId();
    if (!this.panoramaSurfaceQueue.includes(surface)) {
      HiLog.i(TAG, `createPanoramaSurface, surface: ${surface}.`);
      this.panoramaSurfaceQueue.push(surface);
    } else {
      HiLog.e(TAG, `createPanoramaSurface error, surface is created: ${surface}.`);
    }
    return surface;
  }

  public registerErrorManager(): void {
    try {
      HiLog.i(TAG, 'registerErrorManager');
      let errorObserver: errorManager.ErrorObserver = {
        onUnhandledException(errorMsg) {
          HiLog.e(TAG, `errorObserver onUnhandledException, errorMsg: ${errorMsg}`);
        },
        onException(errorObj) {
          HiLog.e(TAG, `errorObserver onException ${errorObj?.name} ${errorObj?.message}`)
          if (typeof (errorObj?.stack) === 'string') {
            HiLog.e(TAG, `onException, stack: ${errorObj.stack}`);
          }
        }
      };
      this.errorObserverId = errorManager.on('error', errorObserver);

      let unhandledRejectionObserver: errorManager.UnhandledRejectionObserver =
        (reason: Error, promise: Promise<void>) => {
          HiLog.e(TAG, `unhandledRejection ${reason?.name} ${reason?.message}`);
          if (reason?.stack) {
            HiLog.e(TAG, `unhandledRejection ${reason.stack}`);
          }
        };
      errorManager.on('unhandledRejection', unhandledRejectionObserver);
    } catch (err) {
      HiLog.e(TAG, `registerErrorManager error: ${err?.code}, ${err?.message}`);
    }
  }

  public unregisterErrorManager(): void {
    HiLog.i(TAG, 'unregisterErrorManager');
    try {
      if (this.errorObserverId !== CommonConstants.INVALID_ID) {
        errorManager.off('error', this.errorObserverId)
          .then((data) => {
            HiLog.i(TAG, 'unregisterErrorObserver success');
          })
          .catch((err) => {
            HiLog.e(TAG, `unregisterErrorObserver fail errMsg:${err?.message} errCode:${err?.code}`);
          });
        this.errorObserverId = CommonConstants.INVALID_ID;
      }
      errorManager.off('unhandledRejection');
    } catch (paramError) {
      HiLog.e(TAG, `unregisterErrorManager error: ${paramError?.code}, ${paramError?.message}`);
    }
  }

  public getPanoramaSurfaceQueue(): string[] {
    return this.panoramaSurfaceQueue;
  }

  public getPanoramaSurface(): string | undefined {
    if (this.panoramaSurfaceQueue.length === 0) {
      HiLog.e(TAG, 'getPanoramaSurface error, surface: undefined.');
      return undefined;
    }
    return this.panoramaSurfaceQueue[this.panoramaSurfaceQueue.length - 1];
  }

  public deletePanoramaSurface(): string {
    if (this.panoramaSurfaceQueue.length === 0) {
      HiLog.e(TAG, 'deletePanoramaSurface error, surfaceQueue length: 0.');
      return '';
    }
    const surface: string = this.panoramaSurfaceQueue.shift();
    HiLog.i(TAG, `deletePanoramaSurface, surface: ${surface}.`);
    return surface;
  }

  public setIsPicker(isPicker: boolean): void {
    this.isPicker = isPicker;
  }

  public getIsPicker(): boolean {
    return this.isPicker;
  }

  public setJumpToBrowser(jumpToBrowser: boolean): void {
    this.jumpToBrowser = jumpToBrowser;
  }

  public getJumpToBrowser(): boolean {
    return this.jumpToBrowser;
  }

  public setWorkerContext(context: Context): void {
    this.workerContext = context;
  }

  public getWorkerContext(): Context {
    return this.workerContext;
  }

  public setCameraShotKey(cameraShotKey: string): void {
    this.cameraShotKey = cameraShotKey;
  }

  public getCameraShotKey(): string {
    return this.cameraShotKey;
  }

  public setLastCameraShotKey(cameraShotKey: string): void {
    this.lastCameraShotKey = cameraShotKey;
  }

  public getLastCameraShotKey(): string {
    return this.lastCameraShotKey;
  }

  public setPhotoBrowserDisabled(disabled: boolean): void {
    this.photoBrowserDisabled = disabled;
  }

  public getPhotoBrowserDisabled(): boolean {
    return this.photoBrowserDisabled;
  }

  public getFilePath(): string {
    return this.filePath;
  }

  public setFilePath(filePath: string): void {
    this.filePath = filePath;
  }

  public getScreenReaderEnabled(): boolean {
    return this.screenReaderEnabled;
  }

  public setScreenReaderEnabled(screenReaderEnabled: boolean): void {
    this.screenReaderEnabled = screenReaderEnabled;
  }

  public getSecurityUIExtensionHostWindowProxy(): uiExtensionHost.UIExtensionHostWindowProxy {
    return this.securityUIExtensionHostWindowProxy;
  }

  public setSecurityUIExtensionHostWindowProxy(windowProxy: uiExtensionHost.UIExtensionHostWindowProxy): void {
    this.securityUIExtensionHostWindowProxy = windowProxy;
  }

  public setCameraService(mCameraService: CameraService): void {
    this.mCameraService = mCameraService;
  }

  public getCameraService(): CameraService {
    return this.mCameraService;
  }

  public setOpenTouchGuide(mOpenTouchGuide: boolean): void {
    this.ismOpenTouchGuide = mOpenTouchGuide;
  }

  public getOpenTouchGuide(): boolean {
    return this.ismOpenTouchGuide;
  }
}