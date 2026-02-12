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
import lazy { HiLog } from '../../utils/HiLog';
import lazy { BaseFunction } from '../core/BaseFunction';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';
import lazy { RenderType } from '../core/functionproperty/RenderType';
import lazy { UiElement } from '../core/UiElement';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { CaptureAction } from './CaptureAction';
import lazy { ThumbnailAction, ThumbnailUpdateScene } from '../../component/thumbnail/ThumbnailAction';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { CaptureUtil } from './CaptureUtil';
import lazy { image } from '@kit.ImageKit';
import lazy { BlurAnimateUtil } from '../../utils/BlurAnimateUtil';
import lazy { getCaptureSetting } from './CaptureSetting';
import lazy { simpleStringify } from '../../utils/SimpleStringify';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { CaptureMessage } from './CaptureMessage';
import lazy { execAction } from '../../redux/ActionRegistry';
import lazy { getStates } from '../../redux';
import ResGetter from '../../utils/ResGetter';
import lazy { SystemLanguageUtil } from '../../utils/SystemLanguageUtil';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { OutputOperation } from '../outputswitcher/OutputOperation';
import lazy { CameraBasicService } from '../../camera/uithread/CameraBasicService';
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { FrameRateOperation } from '../framerate/FrameRateOperation';

const TAG = 'CaptureFunction';
const SCREENSHOT_THUMBNAIL_TIMER: number = 400;

export class CaptureScene {
  public static ULTRA_SNAPSHOT: string = 'ULTRA_SNAPSHOT';
  public static SHUTTER_DOWN_CAPTURE: string = 'DOWN';
}

// 拍照按钮
export class CaptureFunction extends BaseFunction {
  private mShutterDown: boolean;
  private isFirstCapture: boolean = false;
  private cameraForeGroundTime: number = 0;
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.NONE];

  constructor() {
    super();
    this.mShutterDown = false;
  }

  getFunctionId(): FunctionId {
    return FunctionId.CAPTURE;
  }

  /* instrument ignore next */
  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.NONE;
  }

  /* instrument ignore next */
  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  /* instrument ignore next */
  getUiElements(): Map<string | number, UiElement> {
    let uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setIcon($r('app.media.ic_circled_filled')));
    return uiElements;
  }

  getDefaultValue(): boolean {
    return false;
  }

  setValue(value: boolean | string): void {
    HiLog.i(TAG, `setValue value: ${value}.`);
    this.mShutterDown = true;
    this.capture(getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition'), value);
    this.mShutterDown = false;
  }

  getValue(): boolean {
    return this.mShutterDown; // getValues
  }

  isAvailable(): boolean {
    return true;
  }

  load(renderLocations: RenderLocation[]): void {
    HiLog.i(TAG, 'load E.');
    super.load(renderLocations);
    // 每次进前台、窗口获焦，记录时间用于打点
    this.mEventBus.on([ContextActionType.ABILITY_ON_FOREGROUND], async () => {
      this.isFirstCapture = true;
      this.cameraForeGroundTime = Date.now();
    }, this.mBase.hashCode());
    HiLog.i(TAG, 'load x.');
  }

  unload(renderLocations: RenderLocation[]): void {
    HiLog.i(TAG, 'unload E.');
    super.unload(renderLocations);
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'unload X.');
  }

  private capture(position: camera.CameraPosition, value: boolean | string): void {
    HiLog.i(TAG, 'capture begin.');
    if (this.isFirstCapture) {
      // 记录相机拉起到前台-触发第一次拍照间隔打点
      this.isFirstCapture = false;
      let firstCaptureInterval = Date.now() - this.cameraForeGroundTime;
      HiLog.i(TAG, `first capture interval: ${firstCaptureInterval}`);
    }
    const isNeedShowRingBackFlash: boolean = getStates().get<boolean>('ringLightReducer', 'isShowPhotoFlash');
    if (isNeedShowRingBackFlash) {
      this.mStoreManager.postMessage(execAction('RingLightAction', 'emitBackGroundWhite', true));
    }

    const setting: camera.PhotoCaptureSetting = getCaptureSetting(position);
    HiLog.i(TAG, `captureSetting rotatio: ${setting.rotation}, quality: 1, mirror: ${setting.mirror}.`);
    this.mStoreManager.postMessage(CaptureAction.pickerViewRotation(setting.rotation));

    const captureMessage: CaptureMessage = this.getCaptureMessage(value);
    HiLog.i(TAG, `captureMessage: ${simpleStringify(captureMessage)}.`);

    this.mCameraProxy.capture(setting, captureMessage);
    /* instrument ignore if*/
    if (GlobalContext.get().getIsPicker()) {
      BlurAnimateUtil.generatePixelMapFromSurface();
    }
    HiLog.i(TAG, 'capture end.');
  }

  private getCaptureMessage(value: boolean | string): CaptureMessage {
    const isString = typeof value === 'string';
    const mode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
    let isBackCapture: boolean = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
    camera.CameraPosition.CAMERA_POSITION_BACK;
    const mCustomFilterMessage = this.prepareCustomFilterMessage(isBackCapture, mode);
    /* instrument ignore if*/
    if (isString && value === CaptureScene.ULTRA_SNAPSHOT) {
      HiLog.i(TAG, 'shutter capture ultraSnapshot');
      return {
        downCapture: true,
        isBackCapture: isBackCapture,
      };
    }
    let convertMode: ModeType = mode;
    if (OutputOperation.isPanVideoOutput(mode)) {
      convertMode = ModeType.PHOTO;
    }
    const downCapture: boolean = isString && value === CaptureScene.SHUTTER_DOWN_CAPTURE;
    HiLog.i(TAG, `shutter down capture: ${downCapture}`);
    return {
      downCapture,
      isBackCapture,
    };
  }

  private prepareCustomFilterMessage(isBackCapture: boolean, mode: ModeType) {
    const styleIndex = getStates().get<number>('customFilterStyleReducer', 'styleIndex');
    const templateIndex = getStates().get<number>('customFilterStyleReducer', 'templateIndex');
    const currentHue = getStates().get<number>('customFilterStyleReducer', 'currentHue');
    const currentSaturation = getStates().get<number>('customFilterStyleReducer', 'currentSaturation');
    const currentTone = getStates().get<number>('customFilterStyleReducer', 'currentTone');
    const customFilterCardOpened = getStates().get<boolean>('customFilterStyleReducer', 'customFilterCardOpened');
    let customFilterEffectEnable = getStates().get<boolean>('customFilterStyleReducer', 'customFilterEffectEnable');
    const customFilterCardOpenedWhenExit =
      getStates().get<boolean>('customFilterStyleReducer', 'customFilterCardOpenedWhenExit');
    const isOpenPhotoPicker = getStates().get<boolean>('customFilterStyleReducer', 'isOpenPhotoPicker');
    let useIndex = styleIndex;
    useIndex = useIndex < 0 ? 0 : useIndex;
    let colorValue = '';
    let templateName = '';
    const mCustomFilterMessage = {
      templateIndex: templateIndex,
      templateName: customFilterEffectEnable ? templateName : '',
      customFilterCardOpened: customFilterCardOpened,
      customFilterEffectEnable: customFilterEffectEnable,
      customFilterCardOpenedWhenExit: customFilterCardOpenedWhenExit,
      isOpenPhotoPicker: isOpenPhotoPicker,
      colorValue: colorValue,
    };
    return mCustomFilterMessage;
  }

  /* instrument ignore next */
  private async execScreenshotThumbnail(): Promise<void> {
    HiLog.i(TAG, 'execScreenshotThumbnail E.');
    const pixelMap: image.PixelMap = await CaptureUtil.execScreenshotThumbnail();
    this.mStoreManager.postMessage(ThumbnailAction.received(pixelMap, ThumbnailUpdateScene.CAPTURE));
  }
}