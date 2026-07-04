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

import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { DeviceInfo } from '../deviceinfo/DeviceInfo';
import lazy { LongPressDialogView } from '../customdialog/dialogComponent/LongPressDialogView';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import ResGetter from '../../utils/ResGetter';
import lazy { SystemLanguageUtil } from '../../utils/SystemLanguageUtil';

/* instrument ignore file */
export const NAV_DESTINATION_TITLE_HEIGHT: number = 56;

const TEXT_COLOR: Resource = $r('sys.color.ohos_id_color_text_primary_dark');
const TEXT_SIZE: Resource = $r('sys.float.ohos_id_text_size_headline8');
const TEXT_WEIGHT: FontWeight = FontWeight.Bold;
const TEXT_MARGIN_LEFT: number = 8;
const TEXT_MARGIN_RIGHT_UG: number = 8;
const BACK_ARROW_SIZE: number = 24;
const BACK_ARROW_TOUCH_TARGET: number = 40;
const BACK_ARROW_COLOR: Resource = $r('sys.color.ohos_id_color_titlebar_icon_dark');
const LANDSCAPE_MARGIN: number = 24;
const HORIZONTAL_MARGIN: number = 24;
const DEFAULT_VERTICAL_MARGIN: number = 16;

@Component
export struct NavDestinationTitle {
  public titleText: ResourceStr = '';
  @Prop mDirection: WindowDirection = WindowDirection.TOP;
  @Prop isShowLandscape: boolean = false;
  @Prop isShowSemiCollapsed: boolean = false;
  @Prop isTablet: boolean = false;
  @Prop titleOpacity: number = 1;
  @Prop backButtonOpacity: number = 1;
  @Prop translateTitle: number | string = 0;
  clickFunction: () => void = () => {
  };
  private customDialogViewController?: CustomDialogController;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;

  aboutToAppear(): void {
  }

  private getPaddingLeftRight(): number {
    if (this.isShowLandscape && !this.isShowSemiCollapsed || this.isTablet) {
      return LANDSCAPE_MARGIN;
    } else if (this.isShowSemiCollapsed) {
      return HORIZONTAL_MARGIN;
    } else {
      return (this.mDirection === WindowDirection.LEFT || this.mDirection === WindowDirection.RIGHT) ?
        HORIZONTAL_MARGIN : DEFAULT_VERTICAL_MARGIN;
    }
  }

  @Builder
  BackButtonBuilder() {
    Button() {
      SymbolGlyph($r('sys.symbol.chevron_backward'))
        .renderingStrategy(SymbolRenderingStrategy.SINGLE)
        .fontColor([DeviceInfo.isPc() ? Color.Black : BACK_ARROW_COLOR])
        .draggable(false)
        .fontSize(BACK_ARROW_SIZE)
        .maxFontScale(1)
    }
    .width(BACK_ARROW_TOUCH_TARGET)
    .height(BACK_ARROW_TOUCH_TARGET)
    .backgroundColor('#26FFFFFF')
    .opacity(this.backButtonOpacity)
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
    .accessibilityText(ResGetter.getStringSafe($r('sys.string.icon_back')))
    .accessibilityDescription(ResGetter.getStringSafe($r('app.string.accessibility_clickable')))
    .onClick((): void => {
      this.clickFunction();
    })
    .gesture(
      LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
        .onAction((event) => {
          if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
            this.createLongPressDialog($r('sys.symbol.chevron_backward'), $r('sys.string.icon_back'));
            this.customDialogViewController?.open();
          }
        })
    )
    .onTouch((event) => {
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.customDialogViewController?.close();
      }
    })
    .key(ComponentIdKeys.NAV_DESTINATION_TITLE_BACK_1)
  }

  @Builder
  TitleViewBuilder() {
    Text(this.titleText)
      .margin({ left: TEXT_MARGIN_LEFT, right: SystemLanguageUtil.isRTL() ? TEXT_MARGIN_RIGHT_UG : 0 })
      .fontColor(TEXT_COLOR)
      .fontSize(TEXT_SIZE)
      .fontWeight(TEXT_WEIGHT)
      .key(ComponentIdKeys.NAV_DESTINATION_TITLE_TEXT_1)
      .fontFeature('\"ss01\" on')
      .opacity(this.titleOpacity)
      .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
      .accessibilityText(ResGetter.getStringSafe(this.titleText))
      .accessibilityDescription(' ')
      .gesture(
        LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
          .onAction((event) => {
            if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
              this.createLongPressDialog('', this.titleText, true);
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
    Row() {
      this.BackButtonBuilder();
      this.TitleViewBuilder();
    }
    .width('100%')
    .height(NAV_DESTINATION_TITLE_HEIGHT)
    .alignItems(VerticalAlign.Center)
    .padding({
      left: this.getPaddingLeftRight(),
      right: this.getPaddingLeftRight()
    })
    .translate({ x: this.translateTitle })
  }

  private createLongPressDialog(iconRes: ResourceStr, label: ResourceStr, isOnlyShowText: boolean = false): void {
    this.customDialogViewController = new CustomDialogController({
      builder: LongPressDialogView({
        cancel: () => {
        },
        confirm: () => {
        },
        iconItem: {
          iconRes: iconRes,
          isEnabled: true,
          label: label,
          isSymbolIcon: true
        },
        textRes: label,
        isOnlyShowText: isOnlyShowText,
        needFillColor: true
      }),
      maskColor: Color.Transparent,
      isModal: true,
      customStyle: true
    })
  }
}