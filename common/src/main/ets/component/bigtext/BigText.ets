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
import lazy { OhCombinedState, Unsubscribe, Dispatch } from '../../redux';
import lazy { Action } from '../../redux/actions/Action';
import lazy { RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { DirectionToAngleUtil } from '../../utils/DirectionToAngleUtil';
import lazy { ModeType } from '../../mode/ModeType';
import animator, { AnimatorOptions, AnimatorResult } from '@ohos.animator';
import lazy { ChangeState, getStates, reduxSubscribe } from '../../redux';
import lazy { PositionType } from '../../utils/types';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { ModeListManager } from '../../mode/ModeListManager';
import lazy { AccessibilityUtils } from '../../utils/AccessibilityUtils';
import ResGetter from '../../utils/ResGetter';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { DirectionCorrectionService } from '../../service/direction/DirectionCorrectionService';
import lazy { SystemLanguageUtil } from '../../utils/SystemLanguageUtil';
import lazy { WindowService } from '../../service/window/WindowService';
import window from '@ohos.window';

/* instrument ignore file */
const TAG: string = 'BigText';

class StateStruct {
  public mode: ModeType = ModeType.NONE;
  public isRecordingPaused: boolean = false;
  public videoState: RecordingState = RecordingState.READY;
  public direction: number = 0;
}

class BigTextDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public updateShowBigTextFlag(flag: boolean): void {
    this.mDispatch(Action.updateShowBigTextFlag(flag));
  };
}

const BIG_TEXT_POSITION_Y: number = 64;
const BIG_TEXT_POSITION_Y_TABLET: number = 268;
const BIG_TEXT_LINE_HEIGHT: string = '64vp';

export const BIG_TEXT_HEIGHT = 96;

@Component
export struct BigText {
  @State state: StateStruct = new StateStruct();
  @State bigTextOpacity: number = 0;
  @State isShowSemiCollapsed: boolean = false;
  @State isShowLandscape: boolean = false;
  private mAction: BigTextDispatcher = new BigTextDispatcher();
  private currentRotate: number = 0;
  private mSubscriber: Unsubscribe | null = null;
  private bigTextAppearAnimator: AnimatorResult | null = null; // 显示动效
  private bigTextDisAppearAnimator: AnimatorResult | null = null; // 隐藏动效
  @State semiComponentWidth: number = 0;
  @State semiComponentHeight: number = 0;
  @State isLockRotation: boolean = true;
  @State isShowTricollaps: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  @State isShowLowAngleShotView: boolean = false;
  @State isShowRingLightView: boolean = false;
  @Prop isHdr: boolean = false;

  public aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      // 模式不一致时，更新大字体内容
      if (this.state.mode != state.get<ModeType>('modeReducer', 'mode') && this.state.mode != ModeType.NONE) {
        this.bigTextAppearAnimator?.pause();
        this.bigTextDisAppearAnimator?.pause();
        this.bigTextAppearAnim();
      }
      changeState(this.state, {
        mode: state.get<ModeType>('modeReducer', 'mode'),
        isRecordingPaused: state.get<RecordingState>('recordReducer', 'recordingState') === RecordingState.PAUSED,
        videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
        direction: state.get<WindowDirection>('contextReducer', 'direction'),
      });
      this.semiComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.semiComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      this.isLockRotation = state.get<boolean>('windowReducer', 'isLockRotation');
      this.currentRotate = state.get<number>('contextReducer', 'rotateAngle');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isShowLowAngleShotView = state.get<boolean>('collapsReducer', 'isShowLowAngleShotView');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
    let windowStatus: window.WindowStatusType = WindowService.getInstance().getWindowStatus();
    if (this.isSubscriptionNeeded() && ! DeviceInfo.isPc() &&
      (windowStatus != window.WindowStatusType.FLOATING && windowStatus != window.WindowStatusType.SPLIT_SCREEN)) {
      const direction: WindowDirection = DirectionCorrectionService.directionCorrection(this.state.direction,
        getStates().get<boolean>('windowReducer', 'isLockRotation'));
      this.currentRotate = DirectionToAngleUtil.geViewRotate(direction);

    }
    HiLog.i(TAG, 'aboutToAppear X.');
    this.bigTextAppearAnim();
  }

  private isSubscriptionNeeded(): boolean { // 锁定状态
    return !(((this.isShowLandscape && !this.isShowSemiCollapsed) || DeviceInfo.isTablet() || this.isShowTricollaps) &&
      this.isLockRotation);
  }

  public aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear invoke.');
    this.mSubscriber?.destroy();
  }

  public getText(): Resource | string {
    if (this.state.videoState < RecordingState.RECORDING || this.state.videoState === RecordingState.STOPPING) {
      return ModeListManager.getInstance().getModeName(this.state.mode);
    } else {
      if (this.state.isRecordingPaused) {
        return $r('app.string.video_pause');
      } else {
        return $r('app.string.video_resume');
      }
    }
  }

  private bigTextAppearAnim() {
    this.bigTextAppearAnimator?.pause();
    this.bigTextDisAppearAnimator?.pause();
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
      this.bigTextAppearAnimator = null;
      this.bigTextDisAppearAnim();
    }
    this.bigTextAppearAnimator.oncancel = () => {
      this.bigTextOpacity = 0;
      this.bigTextAppearAnimator = null;
    }
    this.bigTextAppearAnimator?.play();
  }

  private bigTextDisAppearAnim() {
    let options: AnimatorOptions = {
      duration: 150,
      easing: 'cubic-bezier(0.33, 0.0, 0.67, 1.0)',
      delay: this.state.videoState === RecordingState.READY && DeviceInfo.isPc() ? 350 : 100,
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
        HiLog.e(TAG, `bigTextDisAppearAnimator reset error: ${error?.code}`);
      }
    } else {
      try {
        this.bigTextDisAppearAnimator = animator.create(options);
      } catch (err) {
        this.bigTextDisAppearAnimator = null;
        this.bigTextOpacity = 0;
        this.mAction.updateShowBigTextFlag(false);
        HiLog.e(TAG, `bigTextDisAppearAnimator create error: ${err?.code}`);
        return;
      }
    }
    this.bigTextDisAppearAnimator.onframe = (value) => {
      this.bigTextOpacity = value;
    };
    this.bigTextDisAppearAnimator.onfinish = () => {
      this.bigTextDisAppearAnimator = null;
      this.mAction.updateShowBigTextFlag(false);
    }
    this.bigTextDisAppearAnimator.oncancel = () => {
      this.bigTextOpacity = 1;
      this.bigTextDisAppearAnimator = null;
    }
    this.bigTextDisAppearAnimator?.play();
    // 仅在无障碍服务下生效
    if (this.isOpenTouchGuide) {
      this.handleSendAccessibilityText();
    } else if (this.enableScreenReader && !this.isOpenTouchGuide) {
      if (this.state.videoState !== RecordingState.READY && this.state.videoState !== RecordingState.STOPPING) {
        return;
      } else {
        this.handleSendAccessibilityText();
      }
    }
  }

  private handleSendAccessibilityText() {
    AccessibilityUtils.sendAnnounceAccessibilityEvent(ResGetter.getStringSafe(this.getText()));
  }

  private getTextPosition(): PositionType {
    if (DeviceInfo.isPc()) {
      return {
        x: this.isShowSemiCollapsed && !(this.state.direction === 1 || this.state.direction === 0) ?
          getStates().get<number>('windowReducer', 'windowWidth') / 2 - 180 : 0,
        y: getStates().get<number>('windowReducer', 'windowHeight') / 2 - BIG_TEXT_POSITION_Y
      };
    }
    if (this.isVdeSemiCollapsed) {
      return {
        x: 0,
        y: -100
      };
    }
    if (DeviceInfo.isTablet() || this.isShowTricollaps) {
      return {
        x: 0,
        y: 0
      };
    }
    return {
      x: 0,
      y: 0
    };
  }

  build() {
    if ((this.isShowLandscape && !this.isShowSemiCollapsed && !DeviceInfo.isPc()) || this.isShowTricollaps) {
      Text(this.getText())
        .fontSize($r('sys.float.ohos_id_text_size_headline4'))
        .lineHeight(BIG_TEXT_LINE_HEIGHT)
        .maxFontScale(1)
        .fontColor(Color.White)
        .fontWeight(300)
        .textAlign(TextAlign.Center)
        .opacity(this.bigTextOpacity)
        .textShadow({ radius: 3, color: '#33000000', offsetX: 0, offsetY: 0 })
        .rotate({
          angle: DeviceInfo.isPc() ? 0 :
            (this.isShowSemiCollapsed ? 90 : this.currentRotate)
        })
        .fontFeature('\"ss01\" on')
    } else {
      Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
        Text(this.getText())
          .fontSize((this.getIconLength(this.getText()) > 10) ?
          $r('sys.float.ohos_id_text_size_headline5')
            : $r('sys.float.ohos_id_text_size_headline4'))
          .lineHeight(BIG_TEXT_LINE_HEIGHT)
          .maxFontScale(1)
          .fontColor(Color.White)
          .fontWeight(300)
          .textAlign(TextAlign.Center)
          .width('100%')
          .opacity(this.bigTextOpacity)
          .textShadow({ radius: 3, color: '#33000000', offsetX: 0, offsetY: 0 })
          .rotate({
            angle: this.getTextRotate(),
          })
          .fontFeature('\"ss01\" on')
      }
      .width(this.isShowSemiCollapsed ? 360 : '100%')
      .position(this.getTextPosition())
    }
  }

  private getIconLength(val: Resource | string): number {
    return ResGetter.getStringSafe(val).length;
  }

  private getTextRotate(): number {
    if (DeviceInfo.isPc()) {
      return 0;
    } else if (this.isShowSemiCollapsed) {
      return 90;
    } else {
      return this.currentRotate;
    }
  }
}