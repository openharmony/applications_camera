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
import lazy { OhCombinedState, Unsubscribe, Dispatch, reduxSubscribe, getStates } from '../../redux';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { RecordingState } from '../recordcontrol/RecordAction';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { OutputType } from './OutputType';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { VibratorService } from '../../component/vibration/VibratorService';
import lazy { BlurAnimateUtil } from '../../utils/BlurAnimateUtil';
import lazy { MULTIPLE_OUTPUTS_MODES, OutputSwitcher } from './OutputSwitcher';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import ResGetter from '../../utils/ResGetter';
import lazy { LongPressDialogView } from '../../component/customdialog/dialogComponent/LongPressDialogView';
import lazy { Action, ActionData } from '../../redux/actions/Action';
import lazy { AccessibilityUtils } from '../../utils/AccessibilityUtils';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { LogStyleMode } from '../../function/enumbase/LogStyleMode';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';

/* instrument ignore file */
const TAG = 'OutputSwitcherButton';
const ICON_OUTER_HEIGHT = 44;
const ICON_HEIGHT = 24;

class ButtonDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public proSonChangeState(iconId: number): void {
    this.mDispatch(Action.proSonChangeState(iconId));
  }
}

@Component
export struct OutputSwitcherButton {
  private subscriber: Unsubscribe = { destroy: () => {} };
  private base: BaseComponent = new BaseComponent();
  private eventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mAction: ButtonDispatcher = new ButtonDispatcher();

  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @State rotateAngle: number = 0;
  @State uiEnable: boolean = false;
  @State mode: ModeType = ModeType.NONE;
  @State outputType: OutputType = OutputType.PHOTO_OUTPUT;

  @State isShowIcon: boolean = false;
  @State icon: Resource | undefined = $r('app.media.ic_public_video');
  @State innerOpacity: number = 1;
  @State circleOpacity: number = 1;
  @State innerScale: number = AnimSpecifications.SCALE_ORIGINAL;
  @State circleScale: number = AnimSpecifications.SCALE_ORIGINAL;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @StorageLink('isOpenTouchGuide') isOpenTouchGuide: boolean = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  private customDialogViewController?: CustomDialogController;
  private isHideButtonAnim: boolean = false;
  @Prop isHdr: boolean = false;

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E');
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });

    this.eventBus.on(CameraActionType.STARTED, () => {
      HiLog.i(TAG, 'OutputSwitcherButton on camera started.');
      this.isShowIcon = MULTIPLE_OUTPUTS_MODES.includes(this.mode) && this.videoState === RecordingState.READY;
      if (!this.isShowIcon) {
        return;
      }
      HiLog.i(TAG, 'switch button is show.');
      this.updateIcon();
    }, this.base.hashCode());

    this.eventBus.on(ActionType.ACTION_CHANGE_TIME_LAPSE, (data: ActionData) => {
      HiLog.i(TAG, 'on ACTION_CHANGE_TIME_LAPSE');
      if (data['timeLapseInterrupt']) {
        this.isHideButtonAnim = false;
        return;
      }
      this.isHideButtonAnim = true;
    }, this.base.hashCode())

    this.updateIcon();
  }

  aboutToDisappear() {
    HiLog.i(TAG, 'aboutToDisappear E');
    this.subscriber.destroy();
    this.eventBus.clear(this.base.hashCode());
  }

  private updateIcon() {
    this.outputType = OutputSwitcher.getInstance().getOutput(this.mode);
    HiLog.i(TAG, `updateIcon, outputType: ${this.outputType}`);
    const icon = this.outputType === OutputType.VIDEO_OUTPUT ? $r('app.media.ic_public_photo') :
    $r('app.media.ic_public_video');
    this.icon = icon;
  }

  private videoStateOnChange(): void {
    HiLog.i(TAG, `videoStateOnChange videoState: ${this.videoState}.`);
    if (this.videoState === RecordingState.STARTING) {
      this.recordStartAnim();
    } else if (this.videoState === RecordingState.STOPPING) {
      this.recordEndAnim();
    }
    this.isShowIcon = MULTIPLE_OUTPUTS_MODES.includes(this.mode) && this.videoState === RecordingState.READY;
  }

  private recordStartAnim(): void {
    HiLog.i(TAG, 'recordStartAnim.');
    this.innerOpacity = 1;
    this.circleOpacity = 1;
    this.innerScale = 1;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_300,
      curve: Curve.Friction
    }, () => {
      this.innerScale = 0;
    });
    animateToImmediately({
      delay: AnimSpecifications.ANIM_DELAY_50,
      duration: AnimSpecifications.ANIM_DURATION_150,
      curve: Curve.Sharp
    }, () => {
      this.innerOpacity = 0;
      this.circleOpacity = 0;
    });
  }

  private recordEndAnim(): void {
    HiLog.i(TAG, 'recordEndAnim.');
    this.isHideButtonAnim = false;
    this.innerOpacity = 0;
    this.circleOpacity = 0;
    this.innerScale = 0;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_300,
      curve: Curve.Friction
    }, () => {
      this.innerScale = 1;
    });
    animateToImmediately({
      delay: AnimSpecifications.ANIM_DELAY_50,
      duration: AnimSpecifications.ANIM_DURATION_150,
      curve: Curve.Sharp,
    }, () => {
      this.innerOpacity = 1;
      this.circleOpacity = 1;
    });
  }

  private getButtonVisible(): boolean {
    return false;
  }


  @Builder
  SwitcherButtonBuilder() {
    Column()
      .id('Circle')
      .alignRules({
        center: { anchor: '__container__', align: VerticalAlign.Center },
        middle: { anchor: '__container__', align: HorizontalAlign.Center }
      })
      .width(44)
      .height(44)
      .border({
        width: 1.5,
        color: Color.White,
        radius: 22,
        style: BorderStyle.Solid
      })
      .backgroundColor('#334d4d4d')
      .scale({
        x: this.circleScale,
        y: this.circleScale
      })
      .opacity(1)
      .visibility(this.getButtonVisible() ? Visibility.Hidden : Visibility.Visible)

    Image(this.icon)
      .width(ICON_HEIGHT)
      .height(ICON_HEIGHT)
      .objectFit(ImageFit.Cover)
      .aspectRatio(1)
      .fillColor(Color.White)
      .rotate({ angle: this.rotateAngle })
      .animation({
        duration: AnimSpecifications.ANIM_DURATION_300,
        curve: Curve.Friction,
        iterations: 1,
        playMode: PlayMode.Normal,
        onFinish: () => {
          HiLog.i(TAG, 'onFinish');
        },
      })
      .draggable(false)
      .id('RotateImageView')
      .alignRules({
        center: { anchor: '__container__', align: VerticalAlign.Center },
        middle: { anchor: '__container__', align: HorizontalAlign.Center }
      })
      .opacity(this.innerOpacity)
      .scale({ x: this.innerScale, y: this.innerScale })
  }

  build() {
    RelativeContainer() {
      this.SwitcherButtonBuilder();
    }
    .key(this.getKey())
    .width('100%').height('100%')
    .enabled(this.uiEnable)
    .onTouch((event?: TouchEvent) => {
      this.onTouchButton(event);
    })
    .width(ICON_OUTER_HEIGHT)
    .accessibilityText(this.getABText(this.outputType))
    .accessibilityDescription(ResGetter.getStringSafe($r('app.string.accessibility_clickable')))
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
    .accessibilityGroup(true)
    .clickStyle()
    .aspectRatio(1)
    .gestureStyle()
  }

  @Styles
  private gestureStyle() {
    .gesture(
      LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
        .onAction((event) => {
          if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2) && this.icon) {
            this.createLongPressDialog(this.icon);
            this.customDialogViewController?.open();
          }
        })
    )
  }

  @Styles
  private clickStyle() {
    .onClick((event) => {
      // 仅在无障碍服务开启时生效
      if (event && this.enableScreenReader && this.isOpenTouchGuide && this.uiEnable) {
        if (this.videoState !== RecordingState.READY) {
          return;
        }
        const outputType = OutputSwitcher.getInstance().getOutput();
        const newOutputType =
          outputType === OutputType.PHOTO_OUTPUT ? OutputType.VIDEO_OUTPUT : OutputType.PHOTO_OUTPUT;
        HiLog.i(TAG, `switch change, outputType: ${outputType}, change to ${newOutputType} begin.`);
        OutputSwitcher.getInstance().setOutput(newOutputType);
        this.rotateCircle();
        VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
        HiLog.i(TAG, `switch change, outputType: ${outputType}, change to ${newOutputType} end.`);
      }
    })
  }

  private getABText(outputType: OutputType): string {
    HiLog.i(TAG, 'getABText outputType ' + outputType);
    return ResGetter.getStringSafe(this.isOpenTouchGuide ?
      (this.outputType === OutputType.VIDEO_OUTPUT ?
      $r('app.string.accessibility_switch_to_camera') : $r('app.string.accessibility_switch_to_video')) : '');
  }

  private onTouchButton(event?: TouchEvent): void {
    if (!this.uiEnable) {
      return;
    }

    if ((this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2) &&
      ((event?.type === TouchType.Up) || (event?.type === TouchType.Cancel))) {
      this.customDialogViewController?.close();
    }

    if (event?.type === TouchType.Down) {
      this.onTouchUpEvent();
    } else if (event?.type === TouchType.Up) {
      if (this.enableScreenReader) {
        AccessibilityUtils.sendAnnounceAccessibilityEvent(this.outputType === OutputType.VIDEO_OUTPUT ?
        ResGetter.getStringSafe($r('app.string.accessibility_switch_to_camera')) :
        ResGetter.getStringSafe($r('app.string.accessibility_switch_to_video')))
      }
      this.onTouchDownEvent();
    } else if (event?.type === TouchType.Cancel) {
      this.rotateCircle();
    }
  }

  private onTouchUpEvent(): void {
    this.circleScale = 1;
    animateToImmediately({
      curve: AnimSpecifications.ANIM_CAPTURE_CURVE
    }, () => {
      this.circleScale = AnimSpecifications.SCALE_0_9;
    });
    BlurAnimateUtil.generatePixelMapFromSurface();
  }

  private onTouchDownEvent(): void {
    if (this.videoState !== RecordingState.READY) {
      return;
    }
    const outputType = OutputSwitcher.getInstance().getOutput();
    const newOutputType = outputType === OutputType.PHOTO_OUTPUT ? OutputType.VIDEO_OUTPUT : OutputType.PHOTO_OUTPUT;
    HiLog.i(TAG, `switch change, outputType: ${outputType}, change to ${newOutputType} begin.`);
    OutputSwitcher.getInstance().setOutput(newOutputType);
    this.rotateCircle();
    VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
    HiLog.i(TAG, `switch change, outputType: ${outputType}, change to ${newOutputType} end.`);
  }

  private rotateCircle(): void {
    HiLog.i(TAG, 'switch change rotateCircle.');
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_150,
      curve: Curve.Sharp,
      delay: AnimSpecifications.ANIM_DELAY_100
    }, () => {
      this.circleScale = AnimSpecifications.SCALE_1_1;
    });

    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_150,
      curve: Curve.Sharp,
      delay: AnimSpecifications.ANIM_DELAY_250
    }, () => {
      this.circleScale = AnimSpecifications.SCALE_ORIGINAL;
    });
  }

  private getKey(): string {
    return ComponentIdKeys.MACRO_SWITCH_BUTTON;
  }

  private createLongPressDialog(iconRes: ResourceStr): void {
    this.customDialogViewController = new CustomDialogController({
      builder: LongPressDialogView({
        cancel: () => {
        },
        confirm: () => {
        },
        iconItem: {
          iconRes: iconRes,
          isEnabled: true
        }
      }),
      maskColor: Color.Transparent,
      isModal: true,
      customStyle: true
    });
  }
}