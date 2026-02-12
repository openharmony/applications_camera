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

import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { OhCombinedState, Unsubscribe, Dispatch, reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { Action, ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { FocusModeEffectMode } from '@ohos/common/src/main/ets/function/enumbase/FocusModeEffectMode';
import lazy { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { UserEventReport } from '@ohos/common/src/main/ets/statistics/UserEventReport';
import lazy { ChangeState, getStates } from '@ohos/common/src/main/ets/redux/Store';
import lazy { UiElement } from '@ohos/common/src/main/ets/function/core/UiElement';
import lazy { StandardSlider } from './StandardSlider';
import camera from '@ohos.multimedia.camera';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { FocusFunction } from './FocusFunction';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { getColorString } from '@ohos/common/src/main/ets/utils/ColorUtil';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import lazy { CollapsChangeService } from '@ohos/common/src/main/ets/service/collaps/CollapsChangeService';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { FocusExposureService } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureService';
import lazy { FocusExposureAction } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureAction';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';
import lazy { DirectionCorrectionService } from '@ohos/common/src/main/ets/service/direction/DirectionCorrectionService';
import lazy { HdrBrightnessUtil } from '@ohos/common/src/main/ets/utils/HdrBrightnessUtil';

/* instrument ignore file */
const TAG: string = 'FocusModeView';
const MF_ARRAY_LENGTH = 27;
const MAX_MF_VALUE = 1;
const MIN_MF_VALUE = 0;

class StateStruct {
  public isShowExtendBar: boolean = false;
  public xComponentWidth?: number = 0;
  public mode = ModeType.NONE;
}

class FocusModeStruct {
  public focusMode: camera.FocusMode = camera.FocusMode.FOCUS_MODE_AUTO;
  public focusPoint?: camera.Point = { x: 0, y: 0 };
  public focusValue: number = 0;
}

class PositionData {
  public x: number = 0;
  public y: number = 0;
}

class FocusModeDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeFunctionValue(id: FunctionId, value: FocusModeStruct): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public hideFocusModeView(iconId: number): void {
    this.mDispatch(Action.proSonChangeState(iconId));
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.PRO_BAR));
  }

  public proSonChangeView(iconId: number, ui: number): void {
    this.mDispatch(Action.proSonChangeView(iconId, ui));
  }

  public isProShowTreasureBox(): void {
    this.mDispatch(Action.isProShowTreasureBox());
  }

  public isProHideTreasureBox(): void {
    this.mDispatch(Action.isProHideTreasureBox());
  }

  public resetFocusState(): void {
    this.mDispatch(FocusExposureAction.hideFocus());
  }
}

@Component
export struct FocusModeView {
  private setTimeoutForLapse: Function = () => {};
  private clearTimeoutForLapse: Function = () => {};
  @State state: StateStruct = new StateStruct();
  private mAction: FocusModeDispatcher = new FocusModeDispatcher();
  private timerId: number = Number.MIN_VALUE;
  @State focusModeFunValue: number = 0;
  @Prop immersiveOpacity: number = 1;
  @Prop isHideProfessionBar: boolean = false;
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @State rotateAngle: number = 0;
  private focusModeModeTimerId: number = Number.MIN_VALUE;
  private mFocusModeFunction: FocusFunction =
    FeatureManager.getInstance().getFunction(FunctionId.FOCUS) as FocusFunction;
  private initModeValue: number = this.mFocusModeFunction?.getModeValue();
  @State isSliding: boolean = false; // 用于滑动过程中,临时变量
  @State focusModeTextOpacity: number = 0;
  @State isCanvasClicked: boolean = false; // 用于滑动过程中,临时变量
  @State @Watch('onSliderValue') sliderValue: number = this.mFocusModeFunction?.getModeValue(); // 用于显示值
  private mSubscriber: Unsubscribe | null = null;
  @State check: number = 1;
  @State showFocusMode: number = FeatureManager.getInstance().getFunction(FunctionId.FOCUS)?.getValue().focusMode;
  @State isFocusModeAutoState: boolean = true;
  @State proSonUiElement: UiElement[] = this.getProSonUIData(this.getAFUiElementsArray());
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State isHalfCollapsLEM: boolean = false;
  @State focusOpacity: number = 0;
  @State isVdeSemiCollapsed: boolean = false;
  @Prop isHdr: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, `aboutToAppear invoke E. sliderValue: ${this.sliderValue}`);
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        isShowExtendBar: state.get<boolean>('uiReducer', 'isShowExtendBar'),
        xComponentWidth: state.get<number>('previewReducer', 'xComponentWidth'),
        mode: state.get<ModeType>('modeReducer', 'mode'),
      });
      this.mDirection =
        DirectionCorrectionService.directionCorrection(state.get<WindowDirection>('contextReducer', 'direction'),
          state.get<boolean>('windowReducer', 'isLockRotation'));
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.focusModeFunValue = FeatureManager.getInstance().getFunction(FunctionId.FOCUS).getValue();
    this.setTimeout();
    this.setTimeoutForLapse();
    this.isFocusModeAutoState = (this.initModeValue === FocusModeEffectMode.FOCUS_MODE_AUTO);
    const focusMode: camera.FocusMode = getStates().get<camera.FocusMode>('focusExposureReducer', 'focusMode');
    this.sliderValue = focusMode === camera.FocusMode.FOCUS_MODE_LOCKED ?
      camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO : focusMode;
    this.mEventBus.on(ActionType.ACTION_LAPSE_AUTO, (data: ActionData) => this.changeFocusToState(data['autoType']),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LUMATION_CHANGE_STATE, () => this.refreshingBar(),
      this.mBase.hashCode());
    this.onSliderValue();
    HiLog.i(TAG, `aboutToAppear invoke X. sliderValue: ${this.sliderValue}`);
  }

  aboutToDisappear() {
    HiLog.i(TAG, 'aboutToDisappear invoke E.');
    this.mAction.isProShowTreasureBox();
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber?.destroy();
    this.clearFocusModeTimeout();
  }

  private refreshingBar(): void {
    this.sliderValue = FocusModeEffectMode.FOCUS_MODE_CONTINUOUS_AUTO;
    this.showFocusMode = FocusModeEffectMode.FOCUS_MODE_CONTINUOUS_AUTO;
    this.proSonUiElement = this.getProSonUIData(this.getAFUiElementsArray());
  }

  private clearFocusModeTimeout(): void {
    HiLog.i(TAG, 'clearFocusModeTimeout & timeLapse.');
    if (Number.MIN_VALUE !== this.focusModeModeTimerId) {
      clearTimeout(this.focusModeModeTimerId);
    }
    this.clearTimeoutForLapse();
    this.clearTimer();
  }

  private setFocusModeTimeout(): void {
    this.clearFocusModeTimeout();
    this.focusModeModeTimerId = setTimeout((): void => {
    }, 5000);
    this.setTimeout();
    this.setTimeoutForLapse();
  }

  private clearTimer(): void {
    if (Number.MIN_VALUE !== this.timerId) {
      clearTimeout(this.timerId);
    }
  }

  private setTimeout(): void {
    this.clearTimer();
    this.timerId = setTimeout((): void => {
      this.mAction.hideFocusModeView(-1);
    }, this.enableScreenReader ? 3 * 5000 : 5000); // 开启屏幕朗读延长3倍时间自动关闭
  }

  private timeoutForSlider(): void {
    this.setTimeoutForLapse();
    this.setTimeout();
  }

  private clearTimerForSlider(): void {
    this.clearTimeoutForLapse();
    this.clearTimer();
  }

  private onSliderValue(): void {
    if (!CollapsChangeService.getInstance().isSmallIntSquareExtSemiCollapsed()) {
      return
    }
    if (this.isVdeSemiCollapsed && this.sliderValue === FocusModeEffectMode.FOCUS_MODE_MANUAL) {
      this.mAction.isProHideTreasureBox();
    } else {
      this.mAction.isProShowTreasureBox();
    }
  }

  private getProSonUIData(ui: UiElement[]): UiElement[] {
    return ui.map(item => {
      HiLog.i(TAG, `getProSonUIData sliderValue: ${this.sliderValue}, functionValue: ${item.functionValue}.`);
      if (item.functionValue === Number(this.sliderValue)) {
        item.setChecked(true);
        this.check = item.functionValue;
      }
      return item
    });
  }

  private getAFUiElementsArray(): UiElement[] {
    let uiElements: Map<FocusModeEffectMode, UiElement> = new Map();
    uiElements.set(FocusModeEffectMode.FOCUS_MODE_AUTO, new UiElement().setValue(FocusModeEffectMode.FOCUS_MODE_AUTO)
      .setTextIcon('AF-S').setAccessibilityDescription($r('app.string.accessibility_focus_mode_af_s')));
    uiElements.set(FocusModeEffectMode.FOCUS_MODE_CONTINUOUS_AUTO, new UiElement().setValue(FocusModeEffectMode
      .FOCUS_MODE_CONTINUOUS_AUTO).setTextIcon('AF-C').setAccessibilityDescription($r('app.string.accessibility_focus_mode_af_c')));
    uiElements.set(FocusModeEffectMode.FOCUS_MODE_MANUAL, new UiElement().setValue(FocusModeEffectMode
      .FOCUS_MODE_MANUAL).setTextIcon('MF').setAccessibilityDescription($r('app.string.accessibility_focus_mode_manual')));
    HiLog.i(TAG, `getAFUiElementsArray uiElements --- ${uiElements.size}`);
    return Array.from(uiElements.values());
  }

  private changeFocusFunctionValue(focusMode: number, focusValue?: number): void {
    HiLog.i(TAG, `changeFocusFunctionValue focusMode ---${focusMode} focusValue --- ${focusValue}`);
    this.clearFocusModeTimeout();
    this.mAction.resetFocusState();
    FocusExposureService.getInstance().setFocusValue({ focusMode, focusValue, isParamSetting: true });
    this.sliderValue = focusMode;
    UserEventReport.getInstance().setFunctionValueReport(FunctionId.FOCUS, RenderLocation.NONE,
      this.sliderValue.toString(), 1);
    this.mAction.proSonChangeView(5, this.check);
    this.setFocusModeTimeout();
    StoreManager.getInstance().postMessage(FocusExposureAction.smartControlLock(false));
  }

  private getProSonUISpace(index: Number, length: Number) {
    let result = index === length ? 0 : MF_ARRAY_LENGTH;
    return result;
  }

  @Builder
  afSonUI() {
    Column() {
      Row() {
        if (this.sliderValue === FocusModeEffectMode.FOCUS_MODE_MANUAL) {
          StandardSlider({
            initValue: this.mFocusModeFunction.getFocusValue() * MF_ARRAY_LENGTH,
            segCount: 1,
            gapNumInEachSeg: 26,
            sliderCanvasWidth: 338,
            bothSidesPadding: 20,
            changeFunctionValue: (mode: number, value: number) => {
              VibratorService.getInstance().triggerVibrator(value === MIN_MF_VALUE || value === MAX_MF_VALUE ?
              VibratorService.CAMERA_GEAR_SLIP_HEAVY_ID : VibratorService.CAMERA_GEAR_SLIP_LIGHT_ID);
              this.changeFocusFunctionValue(mode, value)
            },
            timeLapse: FocusModeEffectMode.FOCUS_MODE_MANUAL,
            valueRange: ['1', ' 2', ' 3', ' 4', ' 5', '6 ', '7 ', '8 ', '9 ', ' 10', ' 11', ' 12', ' 13', ' 14', ' 15',
              '16 ', '17 ', '18 ', '19 ', ' 20', ' 21', '22 ', '23 ', '24 ', ' 25', '26 ', '27'],
            setTimeout: () => this.timeoutForSlider(),
            clearTimeout: () => this.clearTimerForSlider(),
            isHdr: this.isHdr
          })
            .width(324)
            .height(80)
        }
      }
      .visibility(this.sliderValue === FocusModeEffectMode.FOCUS_MODE_MANUAL ? Visibility.Visible : Visibility.Hidden)
      .justifyContent(FlexAlign.Center)
    }
    .height(this.isHalfCollapsLEM ? 54 : 60)
    .width(324)
    .justifyContent(FlexAlign.End)
    .offset(this.state.mode === ModeType.TIME_LAPSE ?
      { y: CollapsChangeService.getInstance().isSmallIntSquareExtSemiCollapsed() ? -0 : -10 } : {})
  }

  build() {
    Column() {
      this.afSonUI();
      Row() {
        ForEach(this.proSonUiElement, (item: UiElement, index?: number) => {
          if (item.textIcon) {
            Column() {
              Text(item.textIcon)
                // 专业AF 适老化字体
                .fontSize('14vp')
                .height(24)
                .textAlign(TextAlign.Center)
                .rotate({ angle: this.rotateAngle })
                .animation({
                  duration: 300,
                  curve: Curve.Friction,
                })
                .fontColor(item.functionValue === this.sliderValue ? getColorString() : '#fff')
                .fontWeight(item.functionValue === this.sliderValue ? 'bold' : 'Regular')
                .textShadow({
                  radius: 3, color: item.functionValue === this.sliderValue ? '#00000000' : '#33000000',
                  offsetX: 0, offsetY: 0
                })
                .fontFeature('\"ss01\" on')
            }
            .foregroundFilter(HdrBrightnessUtil.getHdrFilter(this.isHdr))
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({
              right: SystemLanguageUtil.isRTL() ? 0 :
              this.getProSonUISpace(index, this.proSonUiElement.length - 1),
              left: SystemLanguageUtil.isRTL() ?
              this.getProSonUISpace(index, this.proSonUiElement.length - 1) : 0
            })
            .width(48)
            .height(48)
            .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
            .accessibilityText(`${this.sliderValue === item.functionValue ?
            ResGetter.getStringSafe($r('app.string.accessibility_checked')) : ''}
            ${ResGetter.getStringSafe(item.accessibilityDescription)}`)
            .onClick((): void => {
              this.changeFocusFunctionValue(item.functionValue);
              VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
              this.showFocusMode = item.functionValue;
              item.setChecked(true);
              if (this.enableScreenReader) {
                AccessibilityUtils.sendAnnounceAccessibilityEvent(`${this.sliderValue === item.functionValue ?
                ResGetter.getStringSafe($r('app.string.accessibility_checked')) : ''}
            ${ResGetter.getStringSafe(item.accessibilityDescription)}`);
              }
              // 更新父组件
            })
            .key(ComponentIdKeys.getInstance().getKey(TAG, FunctionId.FOCUS, item.functionValue))
          }
        })
      }
      .offset({x: 0, y: CollapsChangeService.getInstance().isSmallIntSquareExtSemiCollapsed() ? 0 : -1})
      .opacity(this.isHideProfessionBar ? 0 : this.immersiveOpacity)
      .justifyContent(FlexAlign.Center)
      .height(60)
    }
    .width('100%')
    .height(120)
    .justifyContent(FlexAlign.End)
    .key(ComponentIdKeys.FOCUS_MODE_VIEW)
    .opacity(this.focusOpacity)
    .onAppear(() => {
      this.focusOpacity = 0;
      animateToImmediately({
        delay: 100,
        duration: 200,
        curve: Curve.Sharp
      }, () => {
        this.focusOpacity = 1;
      });
    })
    .onDisAppear(() => {
      this.focusOpacity = 1;
      animateToImmediately({
        delay: 0,
        duration: 200,
        curve: Curve.Sharp
      }, () => {
        this.focusOpacity = 0;
      });
    })
  }

  private changeFocusToState(newState: number): void {
    if (newState === 0) {
      this.sliderValue = FocusModeEffectMode.FOCUS_MODE_CONTINUOUS_AUTO;
      this.showFocusMode = FocusModeEffectMode.FOCUS_MODE_CONTINUOUS_AUTO;
    }
    this.setFocusModeTimeout();
  }
}