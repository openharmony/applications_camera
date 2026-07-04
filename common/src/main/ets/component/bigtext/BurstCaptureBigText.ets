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
import lazy { getStates, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../redux';
import lazy { DirectionToAngleUtil } from '../../utils/DirectionToAngleUtil';
import animator, { AnimatorOptions, AnimatorResult } from '@ohos.animator';
import lazy { ChangeState } from '../../redux/Store';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { window } from '@kit.ArkUI';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { DirectionCorrectionService } from '../../service/direction/DirectionCorrectionService';
import lazy { PickerUtils } from '../../utils/PickerUtils';

/* instrument ignore file */

const TAG: string = 'BurstCaptureBigText';

class StateStruct {
  public direction: number = 0;
}

const VERTICAL_OFFSET_TO_CENTER: Length | undefined = 152;
const VDE_VERTICAL_OFFSET_TO_CENTER: Length | undefined = 122;
const MIRROR_LANGUAGE_HORIZON_OFFSET_TO_CENTER: Length | undefined = -350;
const SEMI_COLLAPS_ANGLE: number = 90;
const SEMI_COLLAPS_WIDTH: number = 360;

@Component
export struct BurstCaptureBigText {
  @State @Watch('updateDirection') state: StateStruct = new StateStruct();
  @State bigTextOpacity: number = 0;
  @State isShowSemiCollapsed: boolean = false;
  @State isShowLandscape: boolean = false;
  @State currentRotate: number = 0;
  private mSubscriber: Unsubscribe | null = null;
  private bigTextAppearAnimator: AnimatorResult | null = null; // 显示动效
  private bigTextDisAppearAnimator: AnimatorResult | null = null; // 隐藏动效
  @State semiComponentWidth: number = 0;
  @State semiComponentHeight: number = 0;
  @State customText: string = '1';
  @State @Watch('updateBurstNum') burstNum: number = 0;
  @State @Watch('updateOpacity') isShowBurstCaptureBigTextCache: boolean = false;
  private lrSwipeMirrorUi: boolean = false;
  @State isLockRotation: boolean = true;
  @State isShowTricollaps: boolean = false;
  @State isVdeLandscape: boolean = false;
  @Prop isHdr: boolean = false;

  public aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        direction: state.get<WindowDirection>('contextReducer', 'direction'),
      });
      this.semiComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.semiComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
      this.isShowBurstCaptureBigTextCache = state.get<boolean>('modeReducer', 'isShowBurstCaptureBigText');
      this.burstNum = state.get<number>('leftRightSwipeReducer', 'burstCount');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.lrSwipeMirrorUi = state.get<boolean>('leftRightSwipeReducer', 'isUiMirror');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      this.currentRotate = state.get<number>('contextReducer', 'rotateAngle');
      this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
      this.isLockRotation = state.get<boolean>('windowReducer', 'isLockRotation');
    }, null);
    if (this.isSubscriptionNeeded() && !DeviceInfo.isPc()) {
      const direction: WindowDirection = DirectionCorrectionService.directionCorrection(this.state.direction,
        getStates().get<boolean>('windowReducer', 'isLockRotation'));
      this.currentRotate =
        DirectionToAngleUtil.geViewRotate(direction);
    }
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  public aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear invoke.');
    this.mSubscriber?.destroy();
  }

  public getText(): string {
    return this.customText;
  }

  private isSubscriptionNeeded(): boolean { // 锁定状态
    return !(((this.isShowLandscape && !this.isShowSemiCollapsed) || DeviceInfo.isTablet() || this.isShowTricollaps) &&
    this.isLockRotation);
  }

  private isWindowFloat(): boolean {
    const status: window.WindowStatusType = WindowService.getInstance().getWindowStatus();
    return status === window.WindowStatusType.FLOATING;
  }

  private updateDirection(): void {
    this.currentRotate = DirectionToAngleUtil.geViewRotate(this.state.direction);
  }

  private updateOpacity(): void {
    HiLog.i(TAG, 'burstcapture state update ' + this.isShowBurstCaptureBigTextCache);
    if (this.isShowBurstCaptureBigTextCache) {
      this.bigTextAppearAnim();
    } else {
      this.bigTextDisAppearAnim();
    }
  }

  private updateBurstNum(): void {
    HiLog.i(TAG, 'updateBurstNum');
    if (this.burstNum !== 0) {
      this.customText = this.burstNum.toString();
    }
  }

  private bigTextAppearAnim() {
    this.bigTextAppearAnimator?.pause();
    this.bigTextDisAppearAnimator?.pause();
    let options: AnimatorOptions = {
      duration: AnimSpecifications.ANIM_DURATION_100,
      easing: 'linear',
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
        HiLog.i(TAG, `bigTextAppearAnim error:` + error.code);
      }
    } else {
      this.bigTextAppearAnimator = animator.create(options);
    }
    this.bigTextAppearAnimator.onframe = (value) => {
      this.bigTextOpacity = value;
    };
    this.bigTextAppearAnimator.onfinish = () => {
      this.bigTextAppearAnimator = null;
    }
    this.bigTextAppearAnimator.oncancel = () => {
      this.bigTextOpacity = 0;
      this.bigTextAppearAnimator = null;
    }
    this.bigTextAppearAnimator?.play();
  }

  private bigTextDisAppearAnim() {
    let options: AnimatorOptions = {
      duration: AnimSpecifications.ANIM_DURATION_150,
      easing: 'linear',
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
        HiLog.i(TAG, `bigTextDisAppearAnimator error:` + error.code);
      }
    } else {
      this.bigTextDisAppearAnimator = animator.create(options);
    }
    this.bigTextDisAppearAnimator.onframe = (value) => {
      this.bigTextOpacity = value;
    };
    this.bigTextDisAppearAnimator.onfinish = () => {
      this.bigTextDisAppearAnimator = null;
    }
    this.bigTextDisAppearAnimator.oncancel = () => {
      this.bigTextOpacity = 1;
      this.bigTextDisAppearAnimator = null;
    }
    this.bigTextDisAppearAnimator?.play();
  }

  private getTextOffset(): Position {
    if ((this.isShowSemiCollapsed || DeviceInfo.isTablet())) {
      return { x: this.lrSwipeMirrorUi ? MIRROR_LANGUAGE_HORIZON_OFFSET_TO_CENTER : 0, y: 0 };
    }
    if (this.isVdeLandscape) {
      return { x: 0, y: this.isWindowFloat() ? 0 : VDE_VERTICAL_OFFSET_TO_CENTER };
    }
    return { x: 0, y: this.isWindowFloat() ? 0 : VERTICAL_OFFSET_TO_CENTER };
  }

  build() {
    if (0 !== this.bigTextOpacity) {
      if (this.isShowLandscape && !this.isShowSemiCollapsed) {
        Text(this.getText())
          .fontFamily('HarmonyHeiTi')
          .fontSize($r('sys.float.ohos_id_text_size_headline4'))
          .fontColor(Color.White)
          .fontWeight('medium')
          .textAlign(TextAlign.Center)
          .textCase(TextCase.UpperCase)
          .opacity(this.bigTextOpacity)
          .textShadow({
            radius: 3,
            color: '#33000000',
            offsetX: 0,
            offsetY: 0
          })
          .rotate({
            angle: this.isShowSemiCollapsed ? SEMI_COLLAPS_ANGLE : this.currentRotate,
          })
          .visibility(0 === this.bigTextOpacity ? Visibility.None : Visibility.Visible)
      } else {
        Flex() {
          Text(this.getText())
            .fontFamily('HarmonyHeiTi')
            .fontSize($r('sys.float.ohos_id_text_size_headline4'))
            .fontColor(Color.White)
            .fontWeight('medium')
            .textAlign(TextAlign.Center)
            .textCase(TextCase.UpperCase)
            .width('100%')
            .opacity(this.bigTextOpacity)
            .textShadow({
              radius: 3,
              color: '#33000000',
              offsetX: 0,
              offsetY: 0
            })
            .rotate({
              angle: this.isShowSemiCollapsed ? SEMI_COLLAPS_ANGLE : this.currentRotate,
            })
            .offset(this.getTextOffset())
        }
        .width(this.isShowSemiCollapsed ? SEMI_COLLAPS_WIDTH : '100%')
        .visibility(0 === this.bigTextOpacity ? Visibility.None : Visibility.Visible)
      }
    }
  }
}