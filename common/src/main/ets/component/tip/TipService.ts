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
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { TipAction } from './TipAction';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { camera } from '@kit.CameraKit';
import lazy { AccessibilityUtils } from '../../utils/AccessibilityUtils';
import ResGetter from '../../utils/ResGetter';
import lazy { LightStatus } from '../../camera/DataType';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { getStates } from '../../redux';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';

export const APPEAR_ANIMATION_DURING: number = 500;

const TAG = 'TipService';

export enum DurationType {
  Duration_Short = 1000,
  Duration_Normal = 3000,
  Duration_SLIGHT_LONG = 4000,
  Duration_LENS_DIRTY = 5000,
  Duration_ALWAYS = Number.MAX_VALUE,
}

export class TipService {
  private mStoreManager: StoreManager = StoreManager.getInstance();
  private mTipTimer: number = 0;
  private static sInstanceTipService: TipService;
  private hasAlwaysShowTip: boolean = false;
  public alwaysShowTipMessage: string | Resource = '';
  private alwaysShowTipIsBlack: boolean = false;
  private isPickerShield: boolean = false;
  private alwaysShowTipImgSrc: Resource;
  private alwaysShowTipInStitching: boolean = false;
  private showMessage: string | Resource = '';
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  private apertureEffectString: string[] = [
    ResGetter.getStringSafe($r('app.string.improved_light_for_better_blurring')),
    ResGetter.getStringSafe($r('app.string.quectel_point_for_better_blurring')),
  ];

  public static getInstance(): TipService {
    if (!TipService.sInstanceTipService) {
      TipService.sInstanceTipService = new TipService();
      TipService.sInstanceTipService.initEventBus();
    }
    return TipService.sInstanceTipService;
  }

  private initEventBus(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.ON_LENS_BLOCKING, this.onLensBlocking, this.mBase.hashCode());
  }

  private onLensBlocking(data: Record<string, boolean>): void {
    HiLog.i(TAG, `onLensBlocking: ${data.isCameraOccluded}`);
    AppStorage.setOrCreate('isCameraOccluded', data.isCameraOccluded);
    /* instrument ignore if*/
    if (DeviceInfo.isTv()) {
      return;
    }
    if (getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') === camera.CameraPosition.CAMERA_POSITION_FRONT ||
    AppStorage.get('showPhotoBrowserAction')) {
      if (TipService.getInstance().isAlwaysShowTip()) {
        TipService.getInstance().hideAlwaysShowTip($r('app.string.camera_lans_blocking_tip'));
      }
      return;
    }
    HiLog.i(TAG, `onLensBlocking: ${data.isCameraOccluded}`);
    /* instrument ignore if*/
    if (data.isCameraOccluded) {
      if (!TipService.getInstance().isAlwaysShowTip()) {
        TipService.getInstance().showTip($r('app.string.camera_lans_blocking_tip'), DurationType.Duration_ALWAYS, true);
      }
    } else {
      if (TipService.getInstance().isAlwaysShowTip()) {
        TipService.getInstance().hideAlwaysShowTip($r('app.string.camera_lans_blocking_tip'));
      }
    }
  }

  /* instrument ignore next */
  public handleStitchingTip(showTip: boolean, hintMsg: Resource): void {
    if (showTip) {
      TipService.getInstance().showTip(hintMsg, DurationType.Duration_ALWAYS, true, null, true);
    } else {
      TipService.getInstance().hideAlwaysShowTip(hintMsg);
    }
  }

  // 原showTip参数太多，应拆成多个方法处理，待重构
  /* instrument ignore next */
  showAlwaysTip(message: Resource | string): void {
    HiLog.d(TAG, `showAlwaysTip message: ${message}.`);
    if (AppStorage.get('enableScreenReader')) {
      AccessibilityUtils.sendAnnounceAccessibilityEvent(ResGetter.getStringSafe(message));
    }
    if (this.showMessage !== '' && !this.apertureEffectString.includes(ResGetter.getStringSafe(this.showMessage))) {
      return
    }
    this.hasAlwaysShowTip = true;
    this.alwaysShowTipMessage = message;
    this.alwaysShowTipIsBlack = true;
    this.alwaysShowTipImgSrc = undefined;
    this.alwaysShowTipInStitching = false;
    this.TimerClear();
    this.mStoreManager.postMessage(TipAction.showTip(message, DurationType.Duration_ALWAYS, true, undefined, false, false));
    this.showMessage = message;
  }

  /**
   * Show tip on screen top
   * @param message Toast content
   * @param duration Toast duration
   */
  showTip(message: Resource | string, duration: number, isBlack: boolean = false, imgSrc?: Resource,
    isStitching?: boolean, isLongText: boolean = false, isPickerShield?: boolean): void {
    HiLog.d(TAG, `showTip message: ${message}, duration: ${duration}`);
    if (AppStorage.get('enableScreenReader')) {
      AccessibilityUtils.sendAnnounceAccessibilityEvent(ResGetter.getStringSafe(message));
    }
    if (duration === DurationType.Duration_ALWAYS) {
      this.hasAlwaysShowTip = true;
      this.alwaysShowTipMessage = message;
      this.alwaysShowTipIsBlack = isBlack;
      this.alwaysShowTipImgSrc = imgSrc;
      this.alwaysShowTipInStitching = isStitching;
      this.isPickerShield = isPickerShield;
      // 做短时提醒的避让，短提醒结束后会打开长提醒
      if (this.showMessage !== '') {
        return;
      }
    } else {
      // 长时提醒被短提醒打断
      /* instrument ignore if*/
      if (this.hasAlwaysShowTip && this.showMessage === this.alwaysShowTipMessage) {
        this.TimerClear();
        this.mStoreManager.postMessage(TipAction.hideTip());
        this.showMessage = '';
        this.mTipTimer = setTimeout((): void => {
          this.showTip(message, duration, isBlack, imgSrc);
        }, APPEAR_ANIMATION_DURING);
        return;
      }
    }
    this.TimerClear();
    this.mStoreManager.postMessage(TipAction.showTip(message, duration, isBlack, imgSrc, isStitching, isLongText,
      isPickerShield));
    this.showMessage = message;
    if (duration === DurationType.Duration_ALWAYS) {
      return;
    }
    this.mTipTimer = setTimeout((): void => {
      this.hideTip();
    }, duration - APPEAR_ANIMATION_DURING);
  }

  /**
   *  隐藏常亮类型的Tip
   */
  hideAlwaysShowTip(message: Resource | string): void {
    HiLog.d(TAG, `hideAlwaysShowTip: ${ResGetter.getStringSafe(message) ===
    ResGetter.getStringSafe(this.alwaysShowTipMessage)}`);
    if (this.hasAlwaysShowTip) {
      if (ResGetter.getStringSafe(message) === ResGetter.getStringSafe(this.alwaysShowTipMessage)) {
        this.hasAlwaysShowTip = false;
        this.mStoreManager.postMessage(TipAction.hideTip());
        this.showMessage = '';
      }
    }
  }

  public isAlwaysShowTip(): boolean {
    HiLog.d(TAG, `isAlwaysShowTip : ${this.hasAlwaysShowTip}`);
    return this.hasAlwaysShowTip;
  }

  hideTip(): void {
    HiLog.i(TAG, 'hide tip.');
    this.TimerClear();
    this.mStoreManager.postMessage(TipAction.hideTip());
    this.showMessage = '';
    /* instrument ignore if */
    if (this.hasAlwaysShowTip) {
      this.mTipTimer = setTimeout(() => {
        if (!this.hasAlwaysShowTip) {
          return;
        }
        this.mStoreManager.postMessage(TipAction.showTip(this.alwaysShowTipMessage, Number.MAX_VALUE,
          this.alwaysShowTipIsBlack, this.alwaysShowTipImgSrc, this.alwaysShowTipInStitching));
        this.showMessage = this.alwaysShowTipMessage;
      }, APPEAR_ANIMATION_DURING);
    }
  }

  private TimerClear(): void {
    if (this.mTipTimer) {
      clearTimeout(this.mTipTimer);
      this.mTipTimer = 0;
    }
  }
}