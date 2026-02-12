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

import window from '@ohos.window';
import animator, { AnimatorOptions, AnimatorResult } from '@ohos.animator';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { Dispatch, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../redux';
import lazy { Action } from '../../redux/actions/Action';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { ChangeState } from '../../redux/Store';
import lazy { CameraBasicService } from '../../camera/uithread/CameraBasicService';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { DirectionCorrectionService } from '../../service/direction/DirectionCorrectionService';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { WindowService } from '../../service/window/WindowService';
import ResGetter from '../../utils/ResGetter';
import lazy { AccessibilityUtils } from '../../utils/AccessibilityUtils';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { CaptureAction } from '../../function/capture/CaptureAction';

/* instrument ignore file */
const TAG: string = 'NightTimeBigText';
const ONE_SECOND_MILLISECONDS: number = 1000;
const MODE_ROTATE_90: number = 90;
const TEXT_INFO_MARGIN_WIDTH: number = 80;

class StateStruct {
  public mode: ModeType = ModeType.NONE;
  public exposureTime: number = 0;
  public estimatedCaptureDuration: number = 0;
  public isShowNightBigText: boolean = false;
  public direction: number = 0;
  public rotateAngle: number = 0;
}

class PositionData {
  public x: number = 0;
  public y: number = 0;
}

class NightBigTextDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public updateShowNightBigTextFlag(flag: boolean): void {
    this.mDispatch(Action.updateShowNightBigTextFlag(flag));
  };
}

@Component
export struct NightTimeBigText {
  @State state: StateStruct = new StateStruct();
  @State bigTextOpacity: number = 0;
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State newHeight: number = 0;
  @State isShowSemiCollapsed: boolean = false;
  @State isShowLandscape: boolean = false;
  @State semiComponentWidth: number = 0;
  private mAction: NightBigTextDispatcher = new NightBigTextDispatcher();
  private mSubscriber: Unsubscribe | null = null;
  private bigTextAppearAnimator: AnimatorResult | null = null; // 显示动效
  private bigTextDisAppearAnimator: AnimatorResult | null = null; // 隐藏动效
  private mTimer: number = Number.MIN_VALUE;
  private exposureTime: number = 0;
  private currentLongExposureTime: number = 0;
  @State offsetValue: Position = { x: 0, y: 0 };
  private seconds: number = 0;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;

  public aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        mode: state.get<ModeType>('modeReducer', 'mode'),
        exposureTime: state.get<number>('contextReducer', 'exposureTime') + Date.now(),
        estimatedCaptureDuration: state.get<number>('contextReducer', 'estimatedCaptureDuration') + Date.now(),
        isShowNightBigText: state.get<boolean>('modeReducer', 'isShowNightBigText'),
        direction: state.get<WindowDirection>('contextReducer', 'direction'),
        rotateAngle: state.get<number>('contextReducer', 'rotateAngle'),
      });
      this.mDirection = DirectionCorrectionService.directionCorrection(state.get<WindowDirection>('contextReducer', 'direction'),
        state.get<boolean>('windowReducer', 'isLockRotation'));
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.semiComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      if (this.windowWidth !== state.get<number>('windowReducer', 'windowWidth')) {
        this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
        this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      }
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    this.exposureTime = this.state.exposureTime;
    this.currentLongExposureTime = this.state.estimatedCaptureDuration;
    let xComponentSizeNew = CameraBasicService.getInstance().getPreviewDisplaySize();
    this.newHeight = xComponentSizeNew.height;
    if (this.enableScreenReader) {
      const counterTime = this.getTargetTime() - Date.now();
      this.seconds = parseFloat((counterTime / ONE_SECOND_MILLISECONDS).toFixed(1));
      AccessibilityUtils.sendAnnounceAccessibilityEvent(this.getAccessString(this.seconds));
      AccessibilityUtils.sendFocusAccessibilityEvent('nightShutterStatusShutter'); // 曝光沉浸式，主动聚焦结束拍摄按钮
    }
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  public aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear invoke.');
    clearTimeout(this.mTimer);
    this.mSubscriber?.destroy();
  }

  private getAccessString(seconds: number): string {
    return `${ResGetter.getStringSafe($r('app.string.global_exposure'))}${ResGetter
      .getStringSafe($r('app.string.timer_10_seconds', seconds))},
      ${ResGetter.getStringSafe($r('app.string.night_submode_capture_desc'))}`;
  }

  private getTargetTime(): number {
    return this.currentLongExposureTime;
  }

  private showExposureTime(): number {
    return this.getTargetTime() - Date.now();
  }

  private getOffsetValue(): Position {
    return { x: 0, y: 0 };
  }

  public getText(): string | Resource {
    const counterTime = this.getTargetTime() - Date.now();
    const seconds = (((counterTime < 0 ? 0 : counterTime) / ONE_SECOND_MILLISECONDS).toFixed(1).toString());
    if (this.enableScreenReader) {
      this.seconds = parseFloat(seconds);
    }
    return $r('app.string.big_text_s', seconds);
  }

  private nightBigTextAppearAnim() {
    this.bigTextAppearAnimator?.cancel();
    this.bigTextDisAppearAnimator?.cancel();
    let options: AnimatorOptions = {
      duration: 150,
      easing: 'cubic-bezier(0.33, 0.0, 0.67, 1.0)',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: 0,
      end: 1
    };
    if (this.bigTextAppearAnimator) {
      try {
        this.bigTextAppearAnimator.reset(options);
      } catch (error) {
        HiLog.e(TAG, `bigTextAppearAnim error: ${error?.code}.`);
      }
    } else {
      this.bigTextAppearAnimator = animator.create(options);
    }
    this.bigTextAppearAnimator.onframe = (value) => {
      this.bigTextOpacity = value;
    };
    this.bigTextAppearAnimator.onfinish = () => {
      setTimeout((): void => {
        if (this.state.isShowNightBigText) {
          this.bigTextDisAppearAnim();
        }
      }, this.showExposureTime());
    }
    this.bigTextAppearAnimator?.play();
  }

  private bigTextDisAppearAnim() {
    let options: AnimatorOptions = {
      duration: 150,
      easing: 'cubic-bezier(0.33, 0.0, 0.67, 1.0)',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: 1,
      end: 0
    };
    if (this.bigTextDisAppearAnimator) {
      try {
        this.bigTextDisAppearAnimator.reset(options);
      } catch (error) {
        HiLog.e(TAG, `bigTextDisAppearAnimator error: ${error?.code}.`);
      }
    } else {
      this.bigTextDisAppearAnimator = animator.create(options);
    }
    this.bigTextDisAppearAnimator.onframe = (value) => {
      this.bigTextOpacity = value;
    };
    this.bigTextDisAppearAnimator.onfinish = () => {
      this.mAction.updateShowNightBigTextFlag(false);
    }
    this.bigTextDisAppearAnimator?.play();
  }

  private nightBigTextNightAppearAnim() {
    this.bigTextOpacity = 0.8;
    animateToImmediately(
      {
        duration: 10,
        curve: Curve.Sharp,
        onFinish: () => {
        }
      },
      () => {
        this.bigTextOpacity = 1;
      })
  }

  private directionChange(): void {
    HiLog.i(TAG, 'directionChange.');
  }

  private setIntervalTimer() {
    HiLog.i(TAG, 'setIntervalTimer.');
    clearTimeout(this.mTimer);
    if (this.enableScreenReader) {
      StoreManager.getInstance()?.postMessage(CaptureAction.playCountTimerEffect());
    }
    this.mTimer = setInterval(() => {
      this.nightBigTextNightAppearAnim();
      if (this.enableScreenReader && Number.isInteger(this.seconds)) {
        StoreManager.getInstance()?.postMessage(CaptureAction.playCountTimerEffect());
      }
    }, 100);
  }

  private getTextPosition(textPos: PositionData): PositionData {
    switch (this.mDirection) {
      case WindowDirection.TOP || WindowDirection.BOTTOM:
        break;
      case WindowDirection.LEFT:
        textPos.x = -8;
        textPos.y = 0;
        break;
      case WindowDirection.RIGHT:
        textPos.y = 0;
        textPos.x = 8;
        break;
      default:
        break;
    }
    return textPos;
  }
  private getItemAlign(): ItemAlign {
    if (WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) {
      if (this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM) {
        return ItemAlign.Center;
      }
      return ItemAlign.Start;
    }
    return ItemAlign.Center;
  }

  private getTextAlign(): TextAlign {
    if (WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) {
      if (this.mDirection === WindowDirection.RIGHT) {
        return TextAlign.End;
      }
      if (this.mDirection === WindowDirection.LEFT) {
        return TextAlign.Start;
      }
      return TextAlign.Center
    }
    return TextAlign.Center;
  }
  build() {
    Flex({ alignItems: this.getItemAlign(), justifyContent: FlexAlign.Center }) {
      Text(this.getText())
        .fontSize($r('sys.float.Display_M'))
        .fontColor(Color.White)
        .fontWeight(300)
        .maxFontScale(1)
        .textAlign(this.getTextAlign())
        .opacity(this.bigTextOpacity)
        .textShadow({ radius: 3, color: '#33000000', offsetX: 0, offsetY: 0 })
        .textCase(TextCase.Normal)
        .onAppear((): void => {
          this.setIntervalTimer();
          this.nightBigTextAppearAnim();
        })
        .fontFeature('\"ss01\" on')
    }
    .rotate({
      angle: this.isShowSemiCollapsed ? MODE_ROTATE_90 : this.state.rotateAngle
    })
    .key("nightTimeBigText")
    .width('100%')
    .height(DeviceInfo.isTablet() ? 96 : 80)
    .offset(this.getOffsetValue())
  }
}