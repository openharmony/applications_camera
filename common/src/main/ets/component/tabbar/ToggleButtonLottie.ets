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

import lazy { lottie, AnimationItem } from '../../utils/LazyImportUtil';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { RenderLocation } from '../../function/core/functionproperty/RenderLocation';
import lazy { ValueType } from '@kit.ArkData';
import lazy { BaseFunction } from '../../function/core/BaseFunction';
import ResGetter from '../../utils/ResGetter';
import lazy { LongPressDialogView } from '../customdialog/dialogComponent/LongPressDialogView';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import lazy { TabBarUtils } from './TabBarUtils';
import lazy { camera } from '@kit.CameraKit';

/* instrument ignore file */
const TAG: string = 'ToggleButtonLottie';
const TAB_BAR_LOTTIE_PATH: Map<string, string> = new Map([]);

const TAB_BAR_LOTTIE_IMG_PATH: Map<string, ResourceStr> = new Map([]);

const LOTTIE_DELAY = 3000;
const TIMER_DURATION = 700;

@Component
export struct ToggleButtonLottie {
  private antiAliasingSetting: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.antiAliasingSetting);
  private mFunctionId: FunctionId = FunctionId.NONE;
  @Link isToggleButtonTimerStarted: boolean;
  private isOpen: boolean | undefined = undefined;
  @State iconOpenState: boolean | undefined = undefined;
  private animationItem: AnimationItem | undefined = undefined;
  private timerId: number = Number.MIN_VALUE;
  @State abTitle: Resource | string | undefined = '';
  @State abDescription: Resource | string | undefined = '';
  private functionImpl: BaseFunction | undefined = undefined;
  private renderLocation: RenderLocation = RenderLocation.NONE;
  private mValue: ValueType = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  private customDialogViewController?: CustomDialogController;
  @State private canvasPath: string = '';
  private isPreviousOpen: boolean | undefined = undefined;
  @StorageLink('isTabBarLottiePlaying') isTabBarLottiePlaying: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @Link isShowLottieCanvas: Map<FunctionId, boolean>;
  @Link isShownByClick: Map<FunctionId, boolean>;
  @Link isShowLottieCanvasLeft: boolean;
  @State isShowIcon: boolean = true;
  private animationName: string = `toggleButtonLottie-${this.mFunctionId}`;

  aboutToAppear(): void {
    HiLog.i(TAG, `aboutToAppear functionId is ${this.mFunctionId}.`);
    this.functionImpl = FeatureManager.getInstance().getFunction(this.mFunctionId);
    this.isOpen = !!this.functionImpl.getValue();
    this.iconOpenState = this.isOpen;
    this.isPreviousOpen = this.isOpen;
  }

  private getAccessibilityText(): void {
    const value: ValueType = this.functionImpl?.getValue() as ValueType;
    if (value === this.mValue) {
      return;
    }

    this.mValue = value;
    this.abTitle = this.functionImpl?.getUiElements(this.renderLocation).get(this.mValue)?.accessibilityTitle;
    this.abDescription = this.functionImpl?.getUiElements(this.renderLocation)
      .get(this.mValue)?.accessibilityDescription;
  }

  private animationItemAddListeners(): void {
    this.animationItem?.addEventListener('DOMLoaded', (): void => {
      HiLog.i(TAG, 'lottieCanvasBuilder loaded');
      this.isShowIcon = false;
    });
    this.animationItem?.addEventListener('complete', (): void => {
      HiLog.i(TAG, 'lottieCanvasBuilder Canvas complete.');
      if (this.isOpen === this.getIsOpen()) {
        this.isShowLottieCanvas.set(this.mFunctionId, false);
      } else {
        HiLog.i(TAG, `complete updateToggleState`);
        this.updateToggleState();
      }
    });
    this.animationItem?.addEventListener('destroy', (): void => {
      HiLog.i(TAG, 'lottieCanvasBuilder Canvas destroy.');
      if (this.isShowLottieCanvas.get(this.mFunctionId)) {
        this.isShowLottieCanvas.set(this.mFunctionId, false);
      }
      this.isShowIcon = true;
      this.isTabBarLottiePlaying = false;
      this.iconOpenState = this.isOpen;
    });
  }

  private getIsOpen(): boolean {
    const value: ValueType = FeatureManager.getInstance().getFunction(this.mFunctionId).getValue();
    return value !== 0;
  }

  updateToggleState(): void {
    this.isOpen = this.getIsOpen();
    HiLog.i(TAG, `isOpen: ${this.isOpen} isPrevOpen ${this.isPreviousOpen}`);
    const isFirstShow: boolean = this.isShownByClick.get(this.mFunctionId) ?? false;

    if (this.isPreviousOpen === this.isOpen && !isFirstShow) {
      this.isPreviousOpen = this.isOpen;
      this.isShowIcon = true;
      {
        this.isShowLottieCanvas.set(this.mFunctionId, false);
      }
      this.isTabBarLottiePlaying = false;
      return;
    }
    this.isShownByClick.set(this.mFunctionId, false);
    this.isPreviousOpen = this.isOpen ?? false;
    this.getAccessibilityText();
    this.canvasPath = TAB_BAR_LOTTIE_PATH.get(this.mFunctionId + '' + this.isOpen) || '';
    HiLog.i(TAG, `canvasPath: ${this.canvasPath}.`);
    lottie.pause(this.animationName);
    lottie.destroy(this.animationName);
    this.animationItem = lottie.loadAnimation({
      container: this.canvasContext,
      renderer: 'canvas',
      loop: false,
      path: this.canvasPath,
      autoplay: true,
      name: this.animationName
    });
    clearTimeout(this.timerId);
    this.animationItemAddListeners();
    if (!this.isOpen) {
      this.timerId = setTimeout((): void => {
        lottie.destroy(this.animationName);
        this.isToggleButtonTimerStarted = false;
      }, LOTTIE_DELAY);
    }
  }

  private getOpenImageKey(): string {
    return `${ComponentIdKeys.getInstance().getKey('TabBar', this.mFunctionId)}_${'OPEN'}`;
  }

  private getClosedImageKey(): string {
    return `${ComponentIdKeys.getInstance().getKey('TabBar', this.mFunctionId)}_${'CLOSE'}`;
  }

  @Builder
  canvasBuilder() {
    Canvas(this.canvasContext)
      .width(TabBarUtils.getImageWidth(this.mFunctionId))
      .height(this.enableScreenReader ? 20 : '100%')
      .key(ComponentIdKeys.FOCUS_ASSIST_LAMP)
      .onReady((): void => {
        HiLog.i(TAG, 'lottieCanvasBuilder Canvas onReady.');
        this.updateToggleState();
      })
      .onDisAppear((): void => {
        HiLog.i(TAG, 'lottieCanvasBuilder Canvas onDisAppear.');
        lottie.destroy(this.animationName);
      })
  }

  @Builder
  openImage() {
    Image(TAB_BAR_LOTTIE_IMG_PATH.get(this.mFunctionId + '' + true))
      .width(TabBarUtils.getImageWidth(this.mFunctionId))
      .height(20)
      .fillColor(Color.White)
      .objectFit(ImageFit.Contain)
      .draggable(false)
      .visibility(this.iconOpenState && this.isShowIcon ? Visibility.Visible : Visibility.Hidden)
      .key(this.getOpenImageKey())
      .gesture(
        LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
          .onAction((event) => {
            if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
              // Dialog从显示Canvas改为显示Functions中的icon
              this.createLongPressDialog(
                TAB_BAR_LOTTIE_IMG_PATH.get(this.mFunctionId + '' + true) || '');
              this.customDialogViewController?.open();
            }
          })
      )
      .onTouch((event) => {
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.customDialogViewController?.close();
        }
      })
  }

  @Builder
  closedImage() {
    Image(TAB_BAR_LOTTIE_IMG_PATH.get(this.mFunctionId + '' + false))
      .width(TabBarUtils.getImageWidth(this.mFunctionId))
      .height(20)
      .fillColor(Color.White)
      .objectFit(ImageFit.Contain)
      .draggable(false)
      .visibility(!this.iconOpenState && this.isShowIcon ? Visibility.Visible : Visibility.Hidden)
      .key(this.getClosedImageKey())
      .gesture(
        LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
          .onAction((event) => {
            if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
              // Dialog从显示Canvas改为显示Functions中的icon
              this.createLongPressDialog(TAB_BAR_LOTTIE_IMG_PATH.get(this.mFunctionId + '' + false) || '');
              this.customDialogViewController?.open();
            }
          })
      )
      .onTouch((event) => {
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.customDialogViewController?.close();
        }
      })
  }

  build() {
    Stack() {
      if (this.isShowLottieCanvas.get(this.mFunctionId)) {
        this.canvasBuilder();
      }
      this.openImage();
      this.closedImage();
    }
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
        },

      }),
      maskColor: Color.Transparent,
      isModal: true,
      customStyle: true
    })
  }
}