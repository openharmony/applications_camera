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
import lazy { vibrator } from '../../utils/LazyImportUtil';
import lazy { GlobalContext } from '../../utils/GlobalContext';

const TAG: string = 'VibratorService';
const MAX_CACHE_TIMES: number = 2;
const MAX_TIME_DELAY_TIMES: number = 3;

export type Usage = 'unknown' | 'alarm' | 'ring' | 'notification' | 'communication' |
'touch' | 'media' | 'physicalFeedback' | 'simulateReality';

export class VibratorService {
  public static readonly CAMERA_GEAR_SLIP_LIGHT_ID: string = 'haptic.camera.gear_slip_light';
  public static readonly CAMERA_GEAR_SLIP_HEAVY_ID: string = 'haptic.camera.gear_slip_heavy';
  public static readonly CAMERA_FOCUS_EFFECT_ID: string = 'haptic.camera.focus';
  public static readonly MODE_SWITCH_EFFECT_ID: string = 'haptic.camera.mode_switch';
  public static readonly CAMERA_GEAR_SLIP2_EFFECT_ID: string = 'haptic.camera.gear_slip2';
  public static readonly CAMERA_CLICK_EFFECT_ID: string = 'haptic.camera.click';
  public static readonly CAMERA_LONG_PRESS_ID: string = 'haptic.camera.long_press';
  public static readonly CAMERA_LONG_PRESS_LIGHT: string = 'haptic.long_press_light';
  public static readonly SHUTTER_CLICK_DOWN = 'haptic.camera.shutter.action_down';
  public static readonly SHUTTER_CLICK_UP = 'haptic.camera.shutter.action_up';
  public static readonly LONG_EXPOSURE_CAPTURE = 'haptic.camera.finish_capture';
  public static readonly BURST_CAPTURE_CONTINUOUS = 'haptic.camera.shutter.continuous';
  public static readonly MORE_MODE_DRAG: string = 'haptic.drag';
  public static readonly VIBRATOR_USAGE_UNKNOWN: Usage = 'unknown';
  public static readonly CAMERA_BURST_DOWN_OGG_TIME = 70; //一次连拍声音长度为70ms
  private static readonly DELAY_TIME: number = 40;
  private static sInstanceVibrator: VibratorService;
  private isSmallVibrator: boolean = false;
  private isLargeVibrator: boolean = false;
  private largeVibratorNumber: number = 0;
  private lastVibratorTime: number = 0;
  private isBlocked: boolean = false;
  private mTimerId: number = Number.MIN_VALUE;
  private lastBurstVibrateTime: number = Number.MIN_VALUE;
  private isVibrateBlocked: boolean = false;
  private static throttleTimeoutID: number | null = null;
  private static flag = false;

  constructor() {
    HiLog.i(TAG, 'constructor.');
  }

  public static getInstance(): VibratorService {
    if (!VibratorService.sInstanceVibrator) {
      VibratorService.sInstanceVibrator = new VibratorService();
    }
    return VibratorService.sInstanceVibrator;
  }

  /**
   节流：wait 时间内只执行一次
   */
  static throttle(func: () => void, wait: number = 700, immediate = true): void {
    if (immediate) {
      if (!this.flag) {
        this.flag = true;
        func();
        this.throttleTimeoutID = setTimeout(() => {
          this.flag = false;
          this.throttleTimeoutID = null;
        }, wait);
      }
    } else {
      if (!this.flag) {
        this.flag = true;
        this.throttleTimeoutID = setTimeout(() => {
          this.flag = false;
          func();
          this.throttleTimeoutID = null;
        }, wait);
      }
    }
  }

  /**
   * 触发振动（预置振动）
   *
   * @param effectId 预置振动效果id
   */
  async triggerVibrator(effectId: string, usage?: Usage): Promise<void> {
    VibratorService.throttle(() => {
      HiLog.d(TAG, 'triggerVibrator begin.');
      usage ? usage : (usage = VibratorService.VIBRATOR_USAGE_UNKNOWN);
      this.stopVibrator();
      try {
        vibrator.startVibration({
          type: 'time',
          duration: 10
          // type: 'preset',
          // effectId: effectId,
          // count: 1,
        }, {
          usage: usage
        }, (error) => {
          if (error) {
            HiLog.e(TAG, `error: ${JSON.stringify(error.message)}.`);

          } else {
            HiLog.d(TAG, `success: ${JSON.stringify(effectId)}.`);
          }
        });
      } catch (error) {
        this.stopVibrator();
        HiLog.e(TAG, `Exception in, error: ${error?.code}.`);
      }
      HiLog.i(TAG, `id: ${effectId}.`);
      HiLog.i(TAG, 'triggerVibrator end.');

    }, 700);
  }

  /* instrument ignore next */
  async stopVibrator(): Promise<void> {
    try {
      // 按照VIBRATOR_STOP_MODE_PRESET模式停止振动
      vibrator?.stopVibration(vibrator.VibratorStopMode.VIBRATOR_STOP_MODE_PRESET).then(() => {
        HiLog.d(TAG, 'stop vibration success.');
      }, (error) => {
        HiLog.e(TAG, `${error?.code}.`);
      });
    } catch (err) {
      HiLog.e(TAG, `${JSON.stringify(err)}.`);
    }
  }

  playBurstVibrate(effectId: string): void {
    let currentTime: number = Date.now();
    let vibrateInterval: number = currentTime - this.lastBurstVibrateTime;
    if (vibrateInterval >= VibratorService.DELAY_TIME) {
      HiLog.i(TAG, 'play burst vibrate:' + effectId);
      this.triggerVibrator(effectId);
      this.lastBurstVibrateTime = currentTime;
      this.isVibrateBlocked = false;
      return;
    }

    if (this.isVibrateBlocked) {
      HiLog.w(TAG, 'isVibrateBlocked');
      return;
    }

    this.isVibrateBlocked = true;
    let waitTime: number = VibratorService.DELAY_TIME - vibrateInterval;
    HiLog.i(TAG, 'burst vibrate wait ' + waitTime + ' ms');
    setTimeout(() => {
      HiLog.i(TAG, 'play burst vibrate:' + effectId + ' after wait');
      this.triggerVibrator(effectId);
      this.lastBurstVibrateTime = Date.now();
      this.isVibrateBlocked = false;
    }, waitTime);
  }

  /* instrument ignore next */
  private clearVibrator(): void {
    this.largeVibratorNumber = 0;
    clearTimeout(this.mTimerId);
    this.isLargeVibrator = false;
    this.isSmallVibrator = false;
  }

  /* instrument ignore next */
  private triggerZoomVibrator(usage: Usage): void {
    HiLog.i(TAG, 'triggerZoomVibrator begin.');
    this.lastVibratorTime = Date.now();
    if (this.isSmallVibrator && this.isLargeVibrator) {
      this.triggerVibrator(VibratorService.CAMERA_GEAR_SLIP_HEAVY_ID, usage);
      this.largeVibratorNumber = this.largeVibratorNumber - 1;
      if (this.largeVibratorNumber === 0) {
        this.isLargeVibrator = false;
      }
      this.isSmallVibrator = false;
      return;
    }
    if (this.isLargeVibrator) {
      this.triggerVibrator(VibratorService.CAMERA_GEAR_SLIP_HEAVY_ID, usage);
      this.largeVibratorNumber = this.largeVibratorNumber - 1;
      if (this.largeVibratorNumber === 0) {
        this.isLargeVibrator = false;
      }
      return;
    }
    if (this.largeVibratorNumber > 0) {
      this.triggerVibrator(VibratorService.CAMERA_GEAR_SLIP_HEAVY_ID, usage);
      this.largeVibratorNumber = this.largeVibratorNumber - 1;
      this.isSmallVibrator = false;
      if (this.largeVibratorNumber === 0) {
        this.isLargeVibrator = false;
      }
      return;
    } else {
      this.triggerVibrator(VibratorService.CAMERA_GEAR_SLIP_LIGHT_ID, usage);
      this.isSmallVibrator = false;
    }
    HiLog.i(TAG, 'triggerZoomVibrator end.');
  }

  /* instrument ignore next */
  public handleZoomVibrator(effectId: string, usage?: string): void {
    HiLog.i(TAG, 'handleZoomVibrator begin.');
    HiLog.i(TAG, 'handleZoomVibrator  effectId ' + effectId + ' isSmallVibrator ' + this.isSmallVibrator +
      ' isLargeVibrator ' + this.isLargeVibrator + ' this.largeVibratorNumber ' + this.largeVibratorNumber);
    usage ? usage : (usage = VibratorService.VIBRATOR_USAGE_UNKNOWN);
    let usageValue = usage as Usage;
    const currentTime = Date.now();
    if (effectId === VibratorService.CAMERA_GEAR_SLIP_LIGHT_ID) {
      this.isSmallVibrator = true;
    }
    if (effectId === VibratorService.CAMERA_GEAR_SLIP_HEAVY_ID) {
      this.isLargeVibrator = true;
      if (this.largeVibratorNumber < MAX_CACHE_TIMES) {
        this.largeVibratorNumber = this.largeVibratorNumber + 1;
      }
    }

    if (currentTime - this.lastVibratorTime > VibratorService.DELAY_TIME * MAX_TIME_DELAY_TIMES && this.isBlocked) {

      this.isBlocked = false;
      clearTimeout(this.mTimerId);
      this.clearVibrator();
      this.triggerZoomVibrator(usageValue);
      return;
    }

    if (currentTime - this.lastVibratorTime > VibratorService.DELAY_TIME) {
      HiLog.i(TAG, 'handleZoomVibrator isBlocked state abnormal.');
      this.triggerZoomVibrator(usageValue);
      clearTimeout(this.mTimerId);
      this.clearVibrator();
      this.isBlocked = false;
      return;
    }

    if (!this.isBlocked) {
      this.isBlocked = true;
      const currentTime = Date.now();
      this.mTimerId = setTimeout((): void => {
        if (this.isBlocked) {
          HiLog.i(TAG, 'handleZoomVibrator triggerZoomVibrator delay play.');
          this.triggerZoomVibrator(usageValue);
        }
        this.isBlocked = false;
      }, VibratorService.DELAY_TIME - (currentTime - this.lastVibratorTime));
      return;
    }
    HiLog.i(TAG, 'handleZoomVibrator end.');
  }
}