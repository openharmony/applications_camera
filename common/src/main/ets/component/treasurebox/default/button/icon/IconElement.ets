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

import lazy { UiElement } from '../../../../../function/core/UiElement';
import lazy { AnimSpecifications } from '../../../../../animation/AnimSpecifications';
import lazy {
  TREASURE_BOX_ELEMENT_HEIGHT,
  TREASURE_BOX_ELEMENT_WIDTH,
  TREASURE_BOX_ELEMENT_HALF_COLLAPS_LENGTH,
  TREASURE_BOX_ELEMENT_VDE_COLLAPS_WIDTH,
  TREASURE_BOX_ELEMENT_VDE_COLLAPS_HEIGHT
} from '../../../../../service/UIAdaptive/AdaptiveLayoutService';
import lazy { FunctionId } from '../../../../../function/core/functionproperty/FunctionId';
import lazy { TREASURE_BOX_ELEMENT_INNER_HEIGHT, TREASURE_BOX_ELEMENT_INNER_WIDTH,
  VDE_TREASURE_BOX_ELEMENT_INNER_HEIGHT,
  VDE_TREASURE_BOX_ELEMENT_INNER_WIDTH } from '../../../common/DataType';
import lazy { OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../../../redux';
import lazy { LongPressDialogView } from '../../../../customdialog/dialogComponent/LongPressDialogView';
import lazy { CommonConstants } from '../../../../../statistics/CommonConstants';
import ResGetter from '../../../../../utils/ResGetter';
import lazy { HiLog } from '../../../../../utils/HiLog';
import lazy { FeatureManager } from '../../../../../function/core/FeatureManager';
import lazy { getColorString } from '../../../../../utils/ColorUtil';
import lazy { SystemLanguageUtil } from '../../../../../utils/SystemLanguageUtil';

/* instrument ignore file */
const TAG: string = 'IconElement';

const JAPANESE_TREASURE_WIDTH_OFFSET: number = 4;

@Component
export struct IconElement {
  // icon显示内容与颜色
  @Prop uiElement: UiElement;
  @Prop isWhiteFont: boolean = false;
  @Prop fillColor: boolean = true;
  // 图标旋转相关。因为有和lottie图标切换的场景，角度变量由父组件传递。
  @Prop textAngleRotate: number = 0;
  @Prop @Watch('onRotateAngle') iconAngleRotate: number = 0;
  @State angleRotateShow: number = 0;
  // LEM
  @State isHalfCollapsLEM: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @StorageLink('treasureBoxSelector') selector: FunctionId = FunctionId.NONE;
  @State functionId: FunctionId = FunctionId.NONE;

  private customDialogViewController?: CustomDialogController;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  private isFirstListItem: boolean = true;
  @State private abilityText: string = '';
  private mSubscriber: Unsubscribe | null = null;
  private scroller: Scroller = new Scroller();
  // 环形补光
  @State isShowRingLightView: boolean = false;
  @State globalExposureValue: number = 0;
  @State isOpenFilter: boolean = false;

  aboutToAppear() {
    this.angleRotateShow = this.iconAngleRotate;
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
      this.isOpenFilter = state.get<boolean>('settingReducer', 'isOpenFilter');
    }, null);
    this.abilityText = this.isFirstListItem ? `${ResGetter.getStringSafe(this.uiElement?.accessibilityTitle)} ${
    ResGetter.getStringSafe(this.uiElement?.accessibilityDescription)}` :
      `${this.isWhiteFont ? '' :
      ResGetter.getStringSafe($r('app.string.accessibility_checked'))}
      ${ResGetter.getStringSafe(this.uiElement?.accessibilityDescription)}`
    HiLog.i(TAG, `ID = ${this.functionId}`)
  }

  aboutToDisappear(): void {
    this.mSubscriber?.destroy();
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
      .textShadow({ radius: 3, color: '#33000000', offsetX: 0, offsetY: 0 })
      .textAlign(TextAlign.Center)
      .touchable(false)
      .margin({ bottom: 6 })
      .fontFeature('\"ss01\" on')
      .visibility(this.globalExposureValue !== 0 ? Visibility.Visible : Visibility.Hidden);
  }

  @Builder
  globalExposureIconBuilder() {
    Stack() {
      this.globalExposureTextBuilder();
      Image(this.uiElement.icon)
        .width(28)
        .height(this.uiElement.height)
        .draggable(false)
        .objectFit(ImageFit.Contain)
    }
    .width(28)
    .height(this.uiElement.height)
    .rotate({ angle: this.angleRotateShow })
  }

  private isVdeHalfForFillColor(): boolean {
    return this.isVdeSemiCollapsed && !(this.isOpenFilter);
  }

  build() {
    Column() {
      Row() {
        if (this.uiElement.icon !== undefined) {
          if (!this.fillColor) {
            if (this.isVdeCollapsed) {
              Image(this.uiElement.icon)
                .width(this.uiElement.width)
                .height(this.uiElement.height)
                .draggable(false)
                .rotate({ angle: this.angleRotateShow })
                .objectFit(ImageFit.Contain)
                .fillColor(Color.White)
            } else if (this.isVdeHalfForFillColor()) {
              Image(this.uiElement.icon)
                .width(this.uiElement.width)
                .height(this.uiElement.height)
                .draggable(false)
                .rotate({ angle: this.angleRotateShow })
                .objectFit(ImageFit.Contain)
                .fillColor(this.isShowRingLightView ?
                  (getColorString()) : Color.White)
            } else {
              Image(this.uiElement.icon)
                .width(this.uiElement.width)
                .height(this.uiElement.height)
                .draggable(false)
                .rotate({ angle: this.angleRotateShow })
                .objectFit(ImageFit.Contain)
            }
          } else {
            if ((this.isHalfCollapsLEM || this.isVdeCollapsed) && (this.functionId === FunctionId.VIDEO_RESOLUTION ||
              this.functionId === FunctionId.FRAME_RATE)) {
              Column() {
                Text(this.uiElement.textIcon)
                  .fontColor(this.getFontColor())
                  .fontSize($r('app.float.first_level_list_element_text_size'))
                  .textAlign(TextAlign.Center)
                  .fontWeight(FontWeight.Medium)
                  .fontFamily($r('sys.string.ohos_id_text_font_family_medium'))
                  .height(16)
                  .fontFeature('\"ss01\" on')

                Text(this.uiElement.textItemSec)
                  .fontColor(this.getFontColor())
                  .fontSize($r('app.float.first_level_list_element_sec_text_size'))
                  .textAlign(TextAlign.Center)
                  .height(14)
                  .fontFeature('\"ss01\" on')
              }
              .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS)
              .id('Column')
              .alignRules({
                middle: { anchor: '__container__', align: HorizontalAlign.Center },
                center: { anchor: '__container__', align: VerticalAlign.Center },
              })
              .width(32)
              .height(32)
              .justifyContent(FlexAlign.Center)
              .rotate({ angle: this.angleRotateShow })
            } else {
              Image(this.uiElement.icon)
                .width(this.uiElement.width)
                .height(this.uiElement.height)
                .draggable(false)
                .fillColor(this.getFontColor())
                .rotate({ angle: this.angleRotateShow })
                .objectFit(ImageFit.Contain)
            }
          }
        } else {
          if (this.isHalfCollapsLEM || this.isVdeCollapsed) {
            Column() {
              Text(this.uiElement.textIcon)
                .fontColor(this.getFontColor())
                .fontSize(this.isVdeCollapsed ? '10vp' :
                  this.getIconLength(this.uiElement.textIcon) > 10 ? 7 :
                    this.getIconLength(this.uiElement.textIcon) > 8 ? 9 :
                    $r('app.float.first_level_list_element_text_size'))
                .textAlign(TextAlign.Center)
                .fontWeight(FontWeight.Medium)
                .fontFamily($r('sys.string.ohos_id_text_font_family_medium'))
                .height(this.isVdeCollapsed ? 11 : 16)
                .fontFeature('\"ss01\" on')

              if (this.showSecondLevelText()) {
                Text(this.getSecondLevelText())
                  .fontColor(this.getFontColor2())
                  .fontSize(this.isVdeCollapsed ? '7vp' : $r('app.float.first_level_list_element_sec_text_size'))
                  .textAlign(TextAlign.Center)
                  .height(this.isVdeCollapsed ? 9 : 14)
                  .fontFeature('\"ss01\" on')
              }
            }
            .id('Column')
            .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS)
            .alignRules({
              middle: { anchor: '__container__', align: HorizontalAlign.Center },
              center: { anchor: '__container__', align: VerticalAlign.Center },
            })
            .width(this.isVdeCollapsed ? 28 : 32)
            .height(this.isVdeCollapsed ? 28 : 32)
            .justifyContent(FlexAlign.Center)
            .rotate({ angle: this.angleRotateShow })
          } else {
            Text(this.uiElement.textIcon)
              .maxFontSize('15vp')
              .minFontSize('8vp')
              .width(32)
              .height(32)
              .textAlign(TextAlign.Center)
              .fontColor(this.isWhiteFont ? Color.White : getColorString())
              .fontWeight(FontWeight.Medium)
              .rotate({ angle: this.angleRotateShow })
              .fontFeature('\"ss01\" on')
              .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
              .textShadow({
                radius: 3,
                color: '#33000000',
                offsetX: 0,
                offsetY: 0
              })
          }
        }
      }
      .width(this.isVdeCollapsed ? VDE_TREASURE_BOX_ELEMENT_INNER_WIDTH : TREASURE_BOX_ELEMENT_INNER_WIDTH)
      .height(this.isVdeCollapsed ? VDE_TREASURE_BOX_ELEMENT_INNER_HEIGHT : TREASURE_BOX_ELEMENT_INNER_HEIGHT)
      .border({ radius: 24 })
      .backgroundColor(this.isWhiteFont ? $r('app.color.component_normal_dark') : (this.isVdeSemiCollapsed ? $r('app.color.component_normal_dark') : Color.White))
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)

      if (!this.isHalfCollapsLEM && !this.isVdeCollapsed) {
        if (this.isFirstListItem) {
          Text(this.uiElement.title)
            .fontSize($r('app.float.first_level_list_element_text_size'))
            .textAlign(TextAlign.Center)
            .fontColor(Color.White)
            .margin({ top: $r('app.float.margin_value_8') })
            .fontWeight(this.isWhiteFont ? FontWeight.Normal : FontWeight.Bold)
            .rotate({
              angle: this.textAngleRotate,
            })
            .textShadow({
              radius: 3,
              color: '#33000000',
              offsetX: 0,
              offsetY: 0
            })
            .fontFeature('\"ss01\" on')
            .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
        } else {
          Scroll(this.scroller) { //多语言字体超过截断设置为可滚动
            Text(this.uiElement.title)
              .fontSize($r('app.float.first_level_list_element_text_size'))
              .textAlign(TextAlign.Center)
              .fontColor(Color.White)
              .margin({ top: $r('app.float.margin_value_8') })
              .fontWeight(this.isWhiteFont ? FontWeight.Normal : FontWeight.Bold)
              .rotate({
                angle: this.textAngleRotate,
              })
              .textShadow({
                radius: 3,
                color: '#33000000',
                offsetX: 0,
                offsetY: 0
              })
              .fontFeature('\"ss01\" on')
              .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
          }
          .width('100%')
          .scrollBar(BarState.Off)
          .scrollable(ScrollDirection.Horizontal)
          .nestedScroll({
            scrollForward: NestedScrollMode.SELF_FIRST,
            scrollBackward: NestedScrollMode.SELF_FIRST
          })
        }
      }
    }
    .opacity(this.uiElement.disabled ? 0.5 : 1)
    .width(this.isVdeCollapsed ? TREASURE_BOX_ELEMENT_VDE_COLLAPS_WIDTH :
      this.isHalfCollapsLEM ? TREASURE_BOX_ELEMENT_HALF_COLLAPS_LENGTH : SystemLanguageUtil.isSpanish() ?
        TREASURE_BOX_ELEMENT_WIDTH + JAPANESE_TREASURE_WIDTH_OFFSET :
        TREASURE_BOX_ELEMENT_WIDTH)
    .justifyContent(FlexAlign.SpaceBetween)
    .height(this.isVdeCollapsed ? TREASURE_BOX_ELEMENT_VDE_COLLAPS_HEIGHT :
      this.isHalfCollapsLEM ? TREASURE_BOX_ELEMENT_HALF_COLLAPS_LENGTH : TREASURE_BOX_ELEMENT_HEIGHT)
    .padding(this.isVdeCollapsed ? 6 : 0)
    .accessibilityText(this.abilityText)
    .gesture(
      LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
        .onAction((event) => {
          if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
            if (this.uiElement.icon) {
              this.createLongPressDialog(this.uiElement.icon);
            } else {
              this.createLongPressDialog('', `${ResGetter.getStringSafe(this.uiElement.textIcon)} ${
              ResGetter.getStringSafe(this.uiElement.textItemSec)}`, true);
            }
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

  private getIconLength(val: Resource | string): number {
    return ResGetter.getStringSafe(val).length;
  }

  private showSecondLevelText(): boolean {
    if (!this.isVdeCollapsed) {
      return true;
    }
    if (this.selector === FunctionId.TIME_LAPSE || this.functionId === FunctionId.TIME_LAPSE) {
      return false;
    }
    return true;
  }

  private getSecondLevelText(): Resource | string {
    if (this.isVdeCollapsed && (this.functionId === FunctionId.FRAME_RATE || this.selector === FunctionId.FRAME_RATE)) {
      return this.uiElement.textItemSec;
    }
    return this.uiElement.title;
  }

  private onRotateAngle() {
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_300,
      curve: Curve.Friction,
      iterations: 1,
      playMode: PlayMode.Normal,
    }, () => {
      this.angleRotateShow = this.iconAngleRotate;
    });
  }

  private createLongPressDialog(iconRes: ResourceStr, label?: ResourceStr, isOnlyShowText: boolean = false): void {
    this.customDialogViewController = new CustomDialogController({
      builder: LongPressDialogView({
        cancel: () => {
        },
        confirm: () => {
        },
        iconItem: {
          iconRes: iconRes,
          isEnabled: true,
          label: label
        },
        functionId: this.functionId,
        isTreasureBox: true,
        textRes: label,
        isOnlyShowText: isOnlyShowText,
        needFillColor: true
      }),
      maskColor: Color.Transparent,
      isModal: true,
      customStyle: true
    })
  }

  private getFontColor(): ResourceColor {
    if (this.isWhiteFont && !this.isVdeSemiCollapsed) {
      return Color.White;
    }
    if (this.isWhiteFont && this.isVdeSemiCollapsed) {
      return Color.White;
    }
    return getColorString();
  }

  private getFontColor2(): ResourceColor {
    if (this.isWhiteFont && !this.isVdeSemiCollapsed) {
      return $r('sys.color.ohos_id_color_text_hint_contrary');
    }
    if (this.isWhiteFont && this.isVdeSemiCollapsed) {
      return $r('sys.color.ohos_id_color_text_hint_contrary');
    }
    return getColorString();
  }
}