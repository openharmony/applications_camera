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

import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { BaseFunction } from '../../function/core/BaseFunction';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { TabBarUtils } from './TabBarUtils';
import lazy { RenderLocation } from '../../function/core/functionproperty/RenderLocation';
import lazy { ValueType } from '../../utils/types';
import lazy { OhCombinedState, Unsubscribe } from '../../redux';
import lazy { lottie, AnimationItem } from '../../utils/LazyImportUtil';
import lazy { LongPressDialogView } from '../customdialog/dialogComponent/LongPressDialogView';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import ResGetter from '../../utils/ResGetter';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { reduxSubscribe } from '../../redux/Store';
import lazy { FunctionActionType } from '../../redux/actions/FunctionActionType';
import lazy { ActionData } from '../../redux/actions/Action';
import lazy { OutputOperation } from '../../function/outputswitcher/OutputOperation';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';

/* instrument ignore file */
const TAG: string = 'PopupButton';
const TYPE_CLASSIC = 4; // 经典
const TYPE_MODERN = 5; // 现代
const CLOSE: string = 'off';
const FILTER_ON: string = 'on';
const FILTER_OFF: string = 'off';
const FILTER_CLOSE: string = 'close';

@Component
export struct PopupButton {
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  @State popupIcon: Resource | undefined = undefined;
  @State abTitle: Resource | string | undefined = '';
  @State abDescription: Resource | string | undefined = '';
  @Prop isShowLandscape: boolean = false;
  @Prop @Watch('getPopupIcon') resetIcon: number = 0;
  @Prop keyName: string;
  @State videoState: RecordingState = RecordingState.READY;
  private mValue: ValueType = false;
  private mFunctionImpl: BaseFunction | undefined = undefined;
  private mFunctionId: FunctionId = FunctionId.NONE;
  private renderLocation: RenderLocation = RenderLocation.NONE;
  private onPopupButtonClicked: Function = () => {
  };
  private customDialogViewController?: CustomDialogController;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @State @Watch('onShowLottieChange') isShowLottie: boolean = true;
  @State isShowImage: boolean = true;
  @State flushLottie: boolean = true;
  @State isOpen: boolean = true;
  private antiAliasingSetting: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.antiAliasingSetting);
  private animationItem: AnimationItem | undefined = undefined;
  private lottiePath: string | undefined = undefined;
  private flashSwitch: string = '';
  private subscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private isSupportedCustomColorStyle: boolean = false;
  @Link functionOpacity: Map<FunctionId, number>;
  @State globalExposureValue: number = 0;
  @State @Watch('onCustomFilterChange') customFilterEffectEnable: boolean = false;
  @StorageLink('isGlobalExposureBarShow') isGlobalExposureBarShow: boolean = false;
  @State @Watch('onLogChange') isLogOpen: boolean = false;
  private isSupportedLogStyle: boolean = false;
  private mode: ModeType = ModeType.NONE;

  aboutToAppear() {
    HiLog.i(TAG, `aboutToAppear functionId is ${this.mFunctionId}.`);
    this.mFunctionImpl = FeatureManager.getInstance().getFunction(this.mFunctionId);
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.flashSwitch = state.get<string>('lightPaintingReducer', 'flashSwitch');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.globalExposureValue = state.get<number>('globalExposureReducer', 'globalExposureValue');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.customFilterEffectEnable = state.get<boolean>('customFilterStyleReducer', 'customFilterEffectEnable');
    }, null);
    this.getPopupIcon();
    this.popupIcon = this.mFunctionImpl?.getUiElements(this.renderLocation).get(this.mValue)?.icon;
    if (!this.popupIcon) {
      this.popupIcon = this.getOffIcon();
    }
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, this.isLogOn.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.CHANGE_MODE, this.changeMode.bind(this), this.mBase.hashCode());
  }

  aboutToDisappear(): void {
    this.subscriber.destroy();
  }

  private isLogOn(data: ActionData) {
  }

  private changeMode() {
  }

  private onLogChange() {
    const value: ValueType = this.mFunctionImpl?.getValue() as ValueType;
    this.isShowLottie = false;
    // 触发 xmage off -> value
    this.lottiePath = this.getLottiePath(CLOSE, value);
    this.mValue = value;
    this.isShowLottie = this.lottiePath ? true : false;
    this.isOpen = true;
    HiLog.i(TAG, `onLogChange this.isShowLottie: ${this.isShowLottie}`);
    if (!this.isShowLottie) {
      this.popupIcon = this.mFunctionImpl?.getUiElements(this.renderLocation).get(this.mValue)?.icon;
    }
  }

  private onShowLottieChange() {
    HiLog.i(TAG, `onShowLottieChange this.isShowLottie: ${this.isShowLottie}`);
  }

  private onCustomFilterChange(): void {
    if (!this.isSupportedCustomColorStyle) {
      return;
    }
    const value: ValueType = this.mFunctionImpl?.getValue() as ValueType;
    HiLog.i(TAG, `onCustomFilterChange customFilterEffectEnable: ${this.customFilterEffectEnable},` +
      ` id: ${this.mFunctionId}, value: ${value}, this.mValue: ${this.mValue}.`);
    this.isShowLottie = false;
    if (this.customFilterEffectEnable) {
      // 触发 xmage this.mValue -> off
      this.lottiePath = this.getLottiePath(this.mValue, CLOSE);
      this.isShowLottie = this.lottiePath ? true : false;
      this.isOpen = false;
      if (!this.isShowLottie) {
        this.popupIcon = this.getOffIcon();
      }
    } else {
      // 触发 xmage off -> value
      this.lottiePath = this.getLottiePath(CLOSE, value);
      this.mValue = value;
      this.isShowLottie = this.lottiePath ? true : false;
      this.isOpen = true;
      if (!this.isShowLottie) {
        this.popupIcon = this.mFunctionImpl?.getUiElements(this.renderLocation).get(this.mValue)?.icon;
      }
    }
  }

  private getPopupIcon() {
    const value: ValueType = this.mFunctionImpl?.getValue() as ValueType;
    HiLog.i(TAG,
      `getPopupIcon funcid: ${this.mFunctionId}, mode:${this.mode}}, value: ${value}, this.mValue: ${this.mValue}.`);
    if ((this.mValue === TYPE_CLASSIC || this.mValue === TYPE_MODERN || this.mValue === false) &&
      (value === TYPE_CLASSIC || value === TYPE_MODERN)) {
      if (this.mValue === false) {
        this.mValue = 0;
      }
      return;
    }
    if (value === this.mValue) {
      return;
    }
    this.isShowLottie = false;
    this.mValue = value;
    this.popupIcon = this.mFunctionImpl?.getUiElements(this.renderLocation).get(this.mValue)?.icon;
    this.abTitle = this.mFunctionImpl?.getUiElements(this.renderLocation).get(this.mValue)?.accessibilityTitle;
    this.abDescription = this.mFunctionImpl?.getUiElements(this.renderLocation)
      .get(this.mValue)?.accessibilityDescription;
  }

  updateLottieState(): void {
    this.animationItem?.destroy();
    this.animationItem = lottie.loadAnimation({
      container: this.canvasContext,
      renderer: 'canvas',
      loop: false,
      autoplay: true,
      path: this.lottiePath,
    });
    this.animationItem.addEventListener('DOMLoaded', (): void => {
      HiLog.i(TAG, `DOMLoaded this.isShowImage = false. this.isOpen=${this.isOpen}`);
      this.isShowImage = false;
      if (this.isOpen) {
        this.popupIcon = this.mFunctionImpl?.getUiElements(this.renderLocation).get(this.mValue)?.icon;
      } else {
        this.popupIcon = this.getOffIcon();
      }
    });
    this.animationItem.addEventListener('complete', (): void => {
      HiLog.i(TAG, `complete this.isShowImage = true.`);
      this.isShowImage = true;
      this.isShowLottie = false;
    });
  }

  @Builder
  globalExposureTextBuilder() {
    Text((this.globalExposureValue > 0 ? '+' : '') + this.globalExposureValue.toFixed(1))
      .fontSize($r('app.float.first_level_list_element_sec_text_size'))
      .maxFontScale(1)
      .fontWeight('bold')
      .fontColor(Color.White)
      .width(28)
      .lineHeight(10)
      .textShadow({
        radius: 3,
        color: '#33000000',
        offsetX: 0,
        offsetY: 0
      })
      .textAlign(TextAlign.Center)
      .touchable(false)
      .margin({ bottom: 6 })
      .fontFeature('\"ss01\" on')
  }

  @Builder
  globalExposurePopBuilder() {
    Stack() {
      this.globalExposureTextBuilder();
      Image(this.popupIcon)
        .width(28)
        .height(20)
        .objectFit(ImageFit.Contain)
        .draggable(false)
    }
    .visibility((this.globalExposureValue !== 0 || this.isGlobalExposureBarShow) ?
    Visibility.Visible : Visibility.Hidden)
    .width(28)
    .height(28)
  }

  @Builder
  XmagePopBuilder() {
    Stack() {
      if (this.isShowLottie) {
        this.CanvasBuilder()
      }
      Image(this.popupIcon)
        .width(20)
        .height(20)
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .visibility(this.isShowImage ? Visibility.Visible : Visibility.Hidden)
    }
    .width(28)
    .height(28)
  }

  @Builder
  CanvasBuilder() {
    Canvas(this.canvasContext)
      .width(20)
      .height(20)
      .onReady(() => {
        HiLog.i(TAG, 'lottieCanvasBuilder Canvas onReady.');
        this.updateLottieState();
      })
      .onDisAppear(() => {
        HiLog.i(TAG, 'lottieCanvasBuilder Canvas onDisAppear.');
        this.animationItem?.destroy();
      })
  }

  @Builder
  PopupButtonBuilder() {
    Image(this.popupIcon)
      .width(TabBarUtils.getImageWidth(this.mFunctionId))
      .height(20)
      .objectFit(ImageFit.Contain)
      .draggable(false)
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      if (this.flushLottie) { // Flush Lottie, Execute Lottie
        this.PopupButtonBuilder();
      } else {
        this.PopupButtonBuilder();
      }
    }
    .key(this.keyName)
    .width('100%')
    .height('100%')
    .accessibilityDescription(
      this.functionOpacity.get(this.mFunctionId) === AnimSpecifications.ALPHA_HALF ?
      ResGetter.getStringSafe($r('app.string.accessibility_not_clickable')) :
      ResGetter.getStringSafe($r('app.string.accessibility_clickable')))
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
    .accessibilityGroup(true)
    .accessibilityText(
      `${ResGetter.getStringSafe(this.abTitle)},${ResGetter.getStringSafe(this.abDescription)}`)
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .onClick((): void => {
      this.onPopupButtonClicked();
    })
    .gesture(
      LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
        .onAction((event) => {
          this.isLongPressDialogShow(event);
        })
    )
    .onTouch((event) => {
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.customDialogViewController?.close();
      }
    })
  }

  private createLongPressDialog(): void {
    if (this.popupIcon) {
      this.customDialogViewController = new CustomDialogController({
        builder: LongPressDialogView({
          cancel: () => {
          },
          confirm: () => {
          },
          functionId: this.mFunctionId,
          iconItem: {
            iconRes: this.popupIcon,
            isEnabled: true
          }
        }),
        maskColor: Color.Transparent,
        isModal: true,
        customStyle: true
      })
    }
  }

  private isLongPressDialogShow(event: GestureEvent): void {
    if (!event || (this.fontSizeScale < CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
      return;
    }
    if (this.videoState !== RecordingState.RECORDING) {
      this.createLongPressDialog();
      this.customDialogViewController?.open();
    }
  }

  private getOffIcon(): Resource | undefined {
    return undefined;
  }

  private getLottiePath(from: ValueType, to: ValueType): string | undefined {
    return undefined;
  }
}