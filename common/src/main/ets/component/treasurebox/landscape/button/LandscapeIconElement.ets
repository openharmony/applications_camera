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

import lazy { UiElement } from '../../../../function/core/UiElement';
import lazy { OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../../redux/index';
import lazy { AnimSpecifications } from '../../../../animation/AnimSpecifications';
import lazy { TREASURE_BOX_ELEMENT_INNER_HEIGHT, TREASURE_BOX_ELEMENT_INNER_WIDTH } from '../../common/DataType';
import lazy { CommonConstants } from '../../../../statistics/CommonConstants';
import lazy { LongPressDialogView } from '../../../customdialog/dialogComponent/LongPressDialogView';
import ResGetter from '../../../../utils/ResGetter';
import lazy { HiLog } from '../../../../utils/HiLog';
import lazy { FunctionId } from '../../../../function/core/functionproperty/FunctionId';
import lazy { DeviceInfo } from '../../../../component/deviceinfo/DeviceInfo';
import lazy { BaseFunction } from '../../../../function/core/BaseFunction';
import lazy { FeatureManager } from '../../../../function/core/FeatureManager';
import lazy { RenderLocation } from '../../../../function/core/functionproperty/RenderLocation';

/* instrument ignore file */
const TAG: string = 'LandscapeIconElement';

@Component
export struct LandscapeIconElement {
  // icon显示内容与颜色
  @Prop uiElement: UiElement = new UiElement();
  @Prop fillColor: boolean = true;
  @Prop isWhiteFont: boolean = false;
  // 图标旋转相关
  private subscriber: Unsubscribe | null = null;
  @State isShowSemiCollapsed: boolean = false;
  @State @Watch('onRotateAngle') rotateAngle: number = 0;
  @State angleRotateObj: RotateOptions = { angle: 0 };
  private customDialogViewController?: CustomDialogController;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State @Watch('updateExposureIcon') isShowLowAngleShotView: boolean = false;
  @State isShowRingLightView: boolean = false;
  private functionId: FunctionId = FunctionId.NONE;
  @State globalExposureValue: number = 0;

  aboutToAppear() {
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowLowAngleShotView = state.get<boolean>('collapsReducer', 'isShowLowAngleShotView');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.globalExposureValue = state.get<number>('globalExposureReducer', 'globalExposureValue');
    }, null);
    this.angleRotateObj = { angle: this.rotateAngle };
  }

  aboutToDisappear() {
    this.subscriber?.destroy();
  }

  // 低角度状态变化时，重新获取全局曝光图标
  private updateExposureIcon(): void {
    if (!this.isShowSemiCollapsed) {
      return;
    }
    const functionImpl: BaseFunction = FeatureManager.getInstance().getFunction(this.functionId);
    if (!functionImpl) {
      return;
    }
    const exposureElement = functionImpl.getUiElements(RenderLocation.TREASURE_BOX)?.get(functionImpl.getValue());
    if (exposureElement) {
      HiLog.d(TAG, 'updateExposureIcon');
      this.uiElement = exposureElement;
    }
  }

  private isShowRingLightColor(): boolean {
    return this.isShowRingLightView && !(this.isShowLowAngleShotView && this.isShowSemiCollapsed);
  }

  private getRotateAngle(): RotateOptions {
    if (this.isShowSemiCollapsed) {
      return this.angleRotateObj;
    }
    return { angle: 0 };
  }

  private onRotateAngle() {
    animateToImmediately({
      duration: AnimSpecifications.ANIM_DURATION_300,
      curve: Curve.Friction,
      iterations: 1,
      playMode: PlayMode.Normal,
    }, () => {
      this.angleRotateObj = { angle: this.rotateAngle };
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
  globalExposureIconBuilder() {
    Stack() {
      this.globalExposureTextBuilder();
      Image(this.uiElement.icon)
        .id('FillColor')
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center },
          center: { anchor: '__container__', align: VerticalAlign.Center },
        })
        .width(28)
        .height(this.uiElement.height)
        .draggable(false)
        .objectFit(ImageFit.Contain)
    }
    .alignRules({
      middle: { anchor: '__container__', align: HorizontalAlign.Center },
      center: { anchor: '__container__', align: VerticalAlign.Center },
    })
    .width(28)
    .height(this.uiElement.height)
  }

  build() {
    if (!!this.uiElement) {
      RelativeContainer() {
        if (!!this.uiElement.icon) {
          if (!this.fillColor) { // 非Normal滤镜
            Image(this.uiElement.icon)
              .id('FillColor')
              .alignRules({
                middle: { anchor: '__container__', align: HorizontalAlign.Center },
                center: { anchor: '__container__', align: VerticalAlign.Center },
              })
              .width(this.uiElement.width)
              .height(this.uiElement.height)
              .draggable(false)
              .objectFit(ImageFit.Contain)
          } else {
            Image(this.uiElement.icon)
              .id('FillColor')
              .alignRules({
                middle: { anchor: '__container__', align: HorizontalAlign.Center },
                center: { anchor: '__container__', align: VerticalAlign.Center },
              })
              .width(this.uiElement.width)
              .height(this.uiElement.height)
              .draggable(false)
              .fillColor(this.isWhiteFont ? (Color.White) :
                (DeviceInfo.isTablet() ? $r('sys.color.icon_emphasize') : Color.Red))
              .objectFit(ImageFit.Contain)
          }
        } else {
          Column() {
            Text(this.uiElement.textIcon)
              .fontColor(this.isWhiteFont ? (Color.White) :
                (DeviceInfo.isTablet() ? $r('sys.color.icon_emphasize') : Color.Red))// 平板 分辨率 帧数 适老化字体大小不变
              .fontSize($r('sys.float.Body_S'))
              .maxFontScale(1)
              .textAlign(TextAlign.Center)
              .fontWeight(FontWeight.Medium)
              .fontFamily($r('sys.string.ohos_id_text_font_family_medium'))
              .height(16)
            Text(this.uiElement.textItemSec)
              .fontColor(this.isWhiteFont ? (
                'rgba(255,255,255,0.6)') : (DeviceInfo.isTablet() ? $r('sys.color.icon_emphasize') : Color.Red))
              .fontSize($r('sys.float.Caption_M'))
              .maxFontScale(1)
              .textAlign(TextAlign.Center)
              .height(14)
          }
          .id('Column')
          .alignRules({
            middle: { anchor: '__container__', align: HorizontalAlign.Center },
            center: { anchor: '__container__', align: VerticalAlign.Center },
          })
          .width(32)
          .height(32)
          .justifyContent(FlexAlign.Center)
        }
      }
      .border(!this.isWhiteFont && this.isShowRingLightColor() ?
        { color: $r('app.color.component_normal_dark'), width: 2 } : { width: 0 })
      .borderRadius(24)
      .backgroundColor(this.isWhiteFont ? $r('app.color.component_normal_dark') : Color.White)
      .opacity(this.uiElement.disabled ? 0.5 : 1)
      .width(TREASURE_BOX_ELEMENT_INNER_WIDTH)
      .height(TREASURE_BOX_ELEMENT_INNER_HEIGHT)
      .rotate(this.angleRotateObj)
      .accessibilityGroup(true)
      .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
      .gesture(
        LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
          .onAction((event) => {
            if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
              if (!!this.uiElement.icon) {
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
  }

  private createLongPressDialog(iconRes: ResourceStr, label?: ResourceStr, isOnlyShowText: boolean = false): void {
    if (this.uiElement) {
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
          isOnlyShowText: isOnlyShowText
        }),
        maskColor: Color.Transparent,
        isModal: true,
        customStyle: true
      })
    }
  }
}