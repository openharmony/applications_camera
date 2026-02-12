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
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { CaptureAction } from '../../function/capture/CaptureAction';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { FlashMode } from '../../function/enumbase/FlashMode';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { CaptureActionType } from '../../redux/actions/CaptureActionType';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { image } from '@kit.ImageKit';

/* instrument ignore file */
const TAG: string = 'ShowFlashBlack';
const DELAY_TIME: number = 180;
const MAX_TIME_DELAY_TIMES: number = 3;
const PRO_SHUTTER_THRESHOLD: number = 1000000;

@Component
export struct ShowFlashBlack {
  private mBase: BaseComponent = new BaseComponent();
  @StorageLink('ShowFlashBlackOpacity') @Watch('onChangeOpacity') opacityValue: number = 0;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @State blackVisibility: boolean = false;
  @Prop xComponentWidth: number = 0;
  @Prop xComponentHeight: number = 0;
  @Prop screenshotPixelMap?: image.PixelMap | null;
  @State blurNumber: number = AnimSpecifications.ANIM_MODE_SWITCH_BLUR;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mTimerId: number = Number.MIN_VALUE;
  private isBlocked: boolean = false;
  private prevAnimationTime: number = 0;
  private showBlackTimeoutId: number = Number.MIN_VALUE;

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mEventBus.on(ActionType.ACTION_CONFIRM_CAPTURE_EFFECT, this.handleFlashBlack.bind(this),
      this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisAppear E.');
    // 进程退出清理资源
    if (this.showBlackTimeoutId !== Number.MIN_VALUE) {
      clearTimeout(this.showBlackTimeoutId);
      this.showBlackTimeoutId = Number.MIN_VALUE;
    }
    this.opacityValue = 0;
    this.blackVisibility = false;
    this.screenshotPixelMap?.release();
    this.mEventBus.clear(this.mBase.hashCode());
  }

  private onChangeOpacity(): void {
    HiLog.i(TAG, `ShowFlashBlack opacity: ${this.opacityValue}.`);
    if (this.opacityValue === 0) {
      return;
    }
    this.showBlackTimeoutId = setTimeout((): void => {
      HiLog.i(TAG, 'flashBlackAnim start.');
      animateToImmediately({
        duration: 200,
        curve: Curve.Sharp,
        onFinish: () => {
          this.blackVisibility = false;
          this.screenshotPixelMap?.release();
          HiLog.i(TAG, 'flashBlackAnim onFinish.');
        }
      }, () => {
        this.opacityValue = AnimSpecifications.ANIM_CAPTURE_FLASH_BLACK_OPACITY_TO;
        if (DeviceInfo.isTv()) {
          this.blurNumber = AnimSpecifications.ANIM_CAPTURE_FLASH_BLACK_OPACITY_TO;
        }
      });
    }, AnimSpecifications.ANIM_CAPTURE_FLASH_BLACK_DELAY);
  }

  private getXComponentSideLength(length: number): number | string {
    if (DeviceInfo.isPc() && CameraAppCapability.getInstance().getPcCameraOrientation() === 0) {
      return '100%';
    }
    return length;
  }

  build() {
    Column() {
      if (DeviceInfo.isTv() && this.screenshotPixelMap) {
        Image(this.screenshotPixelMap)
          .width('100%')
          .height('100%')
          .blur(this.blurNumber)
      }
    }
    .width(this.isLemCollaps ? 226 : this.getXComponentSideLength(this.xComponentWidth))
    .height(this.isLemCollaps ? 226 : this.getXComponentSideLength(this.xComponentHeight))
    .backgroundColor(DeviceInfo.isTv() ? undefined : Color.Black)
    .opacity(this.opacityValue)
  }

  private handleFlashBlack(): void {
    HiLog.i(TAG, 'handleFlashBlack E');
    let nowTime: number = Date.now();
    // 兜底，预防isBlocked状态异常
    if (nowTime - this.prevAnimationTime > DELAY_TIME * MAX_TIME_DELAY_TIMES && this.isBlocked) {
      HiLog.i(TAG, 'handleFlashBlack isBlocked state abnormal');
      this.isBlocked = false;
      clearTimeout(this.mTimerId);
      this.playFlashBlackAnim();
      HiLog.i(TAG, 'handleFlashBlack X');
      return;
    }

    const playInterval = nowTime - this.prevAnimationTime;
    if (playInterval > DELAY_TIME && !this.isBlocked) {
      this.playFlashBlackAnim();
      HiLog.i(TAG, 'handleFlashBlack X');
      return;
    }

    if (!this.isBlocked) {
      this.isBlocked = true;
      HiLog.i(TAG, 'handleFlashBlack set delay play: ' + playInterval);
      this.mTimerId = setTimeout((): void => {
        if (this.isBlocked) {
          HiLog.i(TAG, 'handleFlashBlack start delay play ');
          this.playFlashBlackAnim();
        }
        this.isBlocked = false;
      }, DELAY_TIME - playInterval);
      HiLog.i(TAG, 'handleFlashBlack X');
      return;
    }
    HiLog.i(TAG, 'handleFlashBlack give up a play');
    HiLog.i(TAG, 'handleFlashBlack X');
  }

  private playFlashBlackAnim() {
    HiLog.begin(TAG, 'playFlashBlack');
    this.prevAnimationTime = Date.now();
    HiLog.i(TAG, 'getPlayTime: ' + this.prevAnimationTime);
    animateToImmediately({
      duration: 0,
      onFinish: () => {
        this.playFlashBlackAnimDone();
        HiLog.end(TAG, 'playFlashBlack');
      }
    }, () => {
      this.opacityValue = 0;
    })
    this.resetFlashBlackAnim();
  }

  private resetFlashBlackAnim() {
    HiLog.i(TAG, 'flashBlackAnim E');
    this.opacityValue = 1;
    if (DeviceInfo.isTv()) {
      this.blurNumber = AnimSpecifications.ANIM_MODE_SWITCH_BLUR;
    }
    this.blackVisibility = true;
    HiLog.i(TAG, 'flashBlackAnim X');
  }

  private playFlashBlackAnimDone(): void {
    HiLog.i(TAG, 'playFlashBlackAnimEnd B.');
    if (GlobalContext.get().getIsPicker()) {
      StoreManager.getInstance().postMessage(CaptureAction.isFlashBlackDone());
    }
  }
}