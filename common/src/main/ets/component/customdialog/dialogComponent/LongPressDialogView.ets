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
import lazy { common } from '@kit.AbilityKit';
import lazy { window } from '@kit.ArkUI';
import lottie, { AnimationItem } from '@ohos/lottie';
import lazy { AnimSpecifications } from '../../../animation/AnimSpecifications';
import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { OhCombinedState, Unsubscribe, reduxSubscribe } from '../../../redux';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { HiLog } from '../../../../ets/utils/HiLog';

/* instrument ignore file */
const IMAGE_SIZE = '64vp';
const TEXT_EDITABLE_DIALOG = '18.3fp';
const TEXT_SIZE_GLOBAL_EXPOSURE = '8fp';
const MAX_DIALOG = '256vp';
const MIN_DIALOG = '216vp';
const ANGLE_90 = 90;

export declare interface IconItem {
  iconRes: ResourceStr;
  isEnabled: boolean;
  label?: ResourceStr;
  isCanvasIcon?: boolean;
  canvasPath?: string;
  action?: () => void;
  isSymbolIcon?: boolean;
}

/**
 * 适老化适配，1.75倍数字体下长按控件才会显示的dialog
 * */
@CustomDialog
export struct LongPressDialogView {
  controller?: CustomDialogController
  iconItem: IconItem = {
    iconRes: '',
    isEnabled: true,
    isCanvasIcon: false,
    isSymbolIcon: false
  }
  textRes?: ResourceStr = '';
  functionId?: FunctionId = FunctionId.NONE;
  isTreasureBox?: boolean = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @State windowWidth: number = 0;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State maxLines: number = 1;
  verticalScreenLines: number = 6;
  horizontalsScreenLines: number = 1;
  isOnlyShowText: boolean = false;
  @State rotateAngle: number = 0;
  @State isShowSemiCollapsed: boolean = false;
  @State globalExposureValue: number = 0;
  // 针对需要fill color的icon
  needFillColor: boolean = false;
  mainWindowStage: window.Window | undefined = undefined;
  cancel: () => void = () => {
  }
  confirm: () => void = () => {
  }
  private antiAliasingSetting: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.antiAliasingSetting);
  private animationItem: AnimationItem | undefined = undefined;

  @Builder
  SingleTextBuilder() {
    Column() {
      Text(this.textRes)
        .fontSize(TEXT_EDITABLE_DIALOG)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(2)
        .width('100%')
        .textAlign(TextAlign.Center)
        .fontColor($r('sys.color.ohos_id_color_text_primary_contrary'))
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private CanvasItemBuilder() {
    Canvas(this.canvasContext)
      .width(IMAGE_SIZE)
      .height(IMAGE_SIZE)
      .onReady((): void => {
        this.animationItem = lottie.loadAnimation({
          container: this.canvasContext,
          renderer: 'canvas',
          loop: false,
          autoplay: false,
          path: this.iconItem.canvasPath,
        });
      })
      .onDisAppear((): void => {
        this.animationItem?.destroy();
      })
      .margin({
        top: $r('sys.float.padding_level24'),
        bottom: $r('sys.float.padding_level8'),
      })
  }

  @Builder
  IconBuilder(needMargin: boolean) {
    if (this.iconItem.isSymbolIcon) {
      SymbolGlyph(this.iconItem.iconRes as Resource)
        .renderingStrategy(SymbolRenderingStrategy.SINGLE)
        .fontColor([Color.White])
        .draggable(false)
        .fontSize(IMAGE_SIZE)
        .maxFontScale(1)
    } else {
      if (this.needFillColor) {
        Image(this.iconItem.iconRes)
          .width(IMAGE_SIZE)
          .height(IMAGE_SIZE)
          .objectFit(ImageFit.Contain)
          .fillColor(Color.White)
          .margin({
            top: needMargin ? $r('sys.float.padding_level24') : undefined,
            bottom: needMargin ? $r('sys.float.padding_level8') : undefined,
          })
      } else {
        Image(this.iconItem.iconRes)
          .width(IMAGE_SIZE)
          .height(IMAGE_SIZE)
          .objectFit(ImageFit.Contain)
          .margin({
            top: needMargin ? $r('sys.float.padding_level24') : undefined,
            bottom: needMargin ? $r('sys.float.padding_level8') : undefined,
          })
      }
    }
  }

  @Builder
  globalExposureBuilder() {
    Column() {
      Stack() {
        Text((this.globalExposureValue > 0 ? '+' : '') + this.globalExposureValue?.toFixed(1))
          .fontSize(TEXT_SIZE_GLOBAL_EXPOSURE)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(this.maxLines)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 16 })
          .fontColor($r('sys.color.ohos_id_color_text_primary_contrary'))
          .visibility((this.globalExposureValue === 0 && this.isTreasureBox) ? Visibility.Hidden : Visibility.Visible);

        Image(this.iconItem.iconRes)
          .width(IMAGE_SIZE)
          .height(IMAGE_SIZE)
          .objectFit(ImageFit.Contain)
      }
      .width('100%')
      .height(IMAGE_SIZE)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ImageAndTextBuilder() {
    Column() {
      if (this.iconItem.isCanvasIcon) {
        this.CanvasItemBuilder();
      } else {
        this.IconBuilder(true);
      }

      Column() {
        Text(this.textRes)
          .fontSize(TEXT_EDITABLE_DIALOG)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(this.maxLines)
          .width('100%')
          .textAlign(TextAlign.Center)
          .fontColor($r('sys.color.ohos_id_color_text_primary_contrary'))
      }
      .width('100%')
      .padding({
        left: $r('sys.float.padding_level4'),
        right: $r('sys.float.padding_level4'),
        bottom: $r('sys.float.padding_level12'),
      })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  SingleImageBuilder() {
    Column() {
      if (this.iconItem.isCanvasIcon) {
        Canvas(this.canvasContext)
          .width(IMAGE_SIZE)
          .height(IMAGE_SIZE)
          .onReady((): void => {
            this.animationItem = lottie.loadAnimation({
              container: this.canvasContext,
              renderer: 'canvas',
              loop: false,
              autoplay: false,
              path: this.iconItem.canvasPath,
            });
          })
          .onDisAppear((): void => {
            this.animationItem?.destroy();
          })
      } else {
        this.IconBuilder(false);
      }
    }
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Stack() {
      Stack() {
        if (this.isOnlyShowText) {
          this.SingleTextBuilder();
        } else if (this.textRes) {
          this.ImageAndTextBuilder();
        } else {
          this.SingleImageBuilder();
        }
      }.rotate({
        angle: this.isShowSemiCollapsed ? ANGLE_90 : this.rotateAngle,
      })
      .animation({
        duration: AnimSpecifications.ANIM_DURATION_300,
        curve: Curve.Friction,
        iterations: 1,
        playMode: PlayMode.Normal,
      })
    }
    .backgroundColor($r('app.color.long_press_dialog_background_color'))
    .backgroundBlurStyle(BlurStyle.NONE)
    .shadow(ShadowStyle.OUTER_DEFAULT_LG)
    .borderRadius($r('sys.float.corner_radius_level10'))
    .width(this.fontSizeScale === CommonConstants.TEXT_SIZE_HUGE_LEVEL4 ? MAX_DIALOG : MIN_DIALOG)
    .constraintSize({
      minHeight: this.fontSizeScale === CommonConstants.TEXT_SIZE_HUGE_LEVEL4 ?
        MAX_DIALOG : MIN_DIALOG
    })
  }

  async aboutToAppear(): Promise<void> {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.globalExposureValue = state.get<number>('globalExposureReducer', 'globalExposureValue');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
    }, null);

    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    let height: number = 0;
    try {
      this.mainWindowStage = context.windowStage.getMainWindowSync();
      let properties: window.WindowProperties = this.mainWindowStage.getWindowProperties();
      height = properties.windowRect.height;
    } catch (err) {
      HiLog.e('LongPressDialogView', `getMainWindowSync fail. ${err?.code}`);
      height = 0;
    }
    if (px2vp(height) > this.windowWidth) {
      this.maxLines = this.verticalScreenLines;
    } else {
      this.maxLines = this.horizontalsScreenLines;
    }
  }

  aboutToDisappear(): void {
    this.mSubscriber.destroy();
  }
}