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

import lazy { AnimSpecifications } from '../../../../../animation/AnimSpecifications';
import lazy { FunctionId } from '../../../../../function/core/functionproperty/FunctionId';
import lazy { UiElement } from '../../../../../function/core/UiElement';
import lazy { execDispatch, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../../../redux/index';
import lazy { WindowDirection } from '../../../../../utils/WindowDirection';
import lazy { ZIndex } from '../../../../../utils/ZIndex';
import lazy { ComponentIdKeys } from '../../../../../utils/ComponentIdKeys';
import lazy { ValueType } from '../../../../../utils/types';
import lazy { LongPressDialogView } from '../../../../customdialog/dialogComponent/LongPressDialogView';
import lazy { CommonConstants } from '../../../../../statistics/CommonConstants';
import ResGetter from '../../../../../utils/ResGetter';
import lazy { Action } from '../../../../../redux/actions/Action';
import lazy { HiLog } from '../../../../../utils/HiLog';
import lazy { SystemLanguageUtil } from '../../../../../utils/SystemLanguageUtil';
import lazy { DirectionToAngleUtil } from '../../../../../utils/DirectionToAngleUtil';

/* instrument ignore file */
export const XMAGE_BUTTON_WIDTH: number = 77;

export const IMAGE_BUTTON_SIDE_LENGTH: number = 58;

export const FILTER_IMAGE_SIDE_LENGTH: number = 116;

export const EFFECT_IMAGE_SIDE_LENGTH: number = 92;

export const XMAGE_IMAGE_SIDE_LENGTH: number = 88;

const TEXT_ELEMENT_HEIGHT: number = 78;

const ITEM_BUTTOM_HEIGHT: number = 98;

const RUSSIAN_PARAMETER_WIDTH_OFF: number = 12;

const TAG: string = 'ImageElement';

interface StateStruct {
  direction: number,
  rotate: number
}

interface ImageElementParameter {
  isSquare: boolean,
  buttonWidth: number,
  buttonHeight: number,
  imageWidth: number,
  imageHeight: number,
  imagePosition?: Position,
  imagePositionVertical?: Position,
  imagePositionHorizontal?: Position
}

const FILTER_ELEMENT_DATA: ImageElementParameter = {
  isSquare: true,
  buttonWidth: IMAGE_BUTTON_SIDE_LENGTH,
  buttonHeight: IMAGE_BUTTON_SIDE_LENGTH,
  imageWidth: FILTER_IMAGE_SIDE_LENGTH,
  imageHeight: FILTER_IMAGE_SIDE_LENGTH,
  imagePosition: {
    x: (IMAGE_BUTTON_SIDE_LENGTH - FILTER_IMAGE_SIDE_LENGTH) >> 1,
    y: (IMAGE_BUTTON_SIDE_LENGTH - FILTER_IMAGE_SIDE_LENGTH) >> 1
  }
}

const EFFECT_ELEMENT_DATA: ImageElementParameter = {
  isSquare: true,
  buttonWidth: IMAGE_BUTTON_SIDE_LENGTH,
  buttonHeight: IMAGE_BUTTON_SIDE_LENGTH,
  imageWidth: EFFECT_IMAGE_SIDE_LENGTH,
  imageHeight: EFFECT_IMAGE_SIDE_LENGTH,
  imagePosition: {
    x: (IMAGE_BUTTON_SIDE_LENGTH - EFFECT_IMAGE_SIDE_LENGTH) >> 1,
    y: (IMAGE_BUTTON_SIDE_LENGTH - EFFECT_IMAGE_SIDE_LENGTH) >> 1
  }
}

const MIRROR_SELFIE_ELEMENT_DATA: ImageElementParameter = {
  isSquare: true,
  buttonWidth: IMAGE_BUTTON_SIDE_LENGTH,
  buttonHeight: IMAGE_BUTTON_SIDE_LENGTH,
  imageWidth: EFFECT_IMAGE_SIDE_LENGTH,
  imageHeight: EFFECT_IMAGE_SIDE_LENGTH,
  imagePosition: {
    x: (IMAGE_BUTTON_SIDE_LENGTH - EFFECT_IMAGE_SIDE_LENGTH) >> 1,
    y: (IMAGE_BUTTON_SIDE_LENGTH - EFFECT_IMAGE_SIDE_LENGTH) >> 1
  }
}

const XMAGE_ELEMENT_DATA: ImageElementParameter = {
  isSquare: false,
  buttonWidth: XMAGE_BUTTON_WIDTH,
  buttonHeight: IMAGE_BUTTON_SIDE_LENGTH,
  imageWidth: XMAGE_IMAGE_SIDE_LENGTH,
  imageHeight: XMAGE_IMAGE_SIDE_LENGTH,
  imagePositionVertical: { x: -8, y: -15 },
  imagePositionHorizontal: { x: -5, y: -15 },
}

const TREASURE_BOX_IMAGE_ELEMENT: Map<FunctionId, ImageElementParameter> = new Map([
]);

@Component
export struct ImageElement {
  @Prop isSelected: boolean = false;
  private functionId: FunctionId = FunctionId.NONE;
  private mUiElement: UiElement = new UiElement();
  @State parameter: ImageElementParameter = FILTER_ELEMENT_DATA;
  @State state: StateStruct = { direction: 0, rotate: 0 };
  private subscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State isHalfCollapsLEM: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  @State isVdeLandscape: boolean = false;
  private curItemValue: ValueType = 0;
  private customDialogViewController?: CustomDialogController;
  private scroller: Scroller = new Scroller();
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @State isShowRingLightView: boolean = false;
  @State rotateAngle: number = 0;

  aboutToAppear() {
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.state.direction = state.get<WindowDirection>('contextReducer', 'direction');
      this.state.rotate = state.get<number>('contextReducer', 'rotateAngle');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
      this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
    }, null);

    const parameter = TREASURE_BOX_IMAGE_ELEMENT.get(this.functionId);
    if (!!parameter) {
      this.parameter = parameter;
    }
  }

  private isVertical(): boolean {
    return this.state.direction === WindowDirection.TOP || this.state.direction === WindowDirection.BOTTOM;
  }

  aboutToDisappear() {
    this.subscriber?.destroy();
  }

  build() {
    Stack() {
      Column() {
        Image(this.mUiElement.icon)
          .width(this.parameter.imageWidth)
          .height(this.parameter.imageHeight)
          .draggable(false)
          .fillColor(Color.White)
          .position(!!this.parameter.imagePosition ? this.parameter.imagePosition :
            this.isVertical() ? this.parameter.imagePositionVertical : this.parameter.imagePositionHorizontal)
          .rotate({ angle: this.isVdeSemiCollapsed ? 0 : this.state.rotate })
          .objectFit(ImageFit.Fill)
          .animation({
            duration: AnimSpecifications.ANIM_DURATION_300,
            curve: Curve.Friction,
            iterations: 1,
            playMode: PlayMode.Normal,
          })
      }
      .width(this.parameter.buttonWidth)
      .height(this.parameter.buttonHeight)
      .clip(new Rect({ width: this.parameter.buttonWidth, height: this.parameter.buttonHeight }))
      .zIndex(ZIndex.MIDDLE_TOP)

      if (this.isSelected) {
        if (this.isHalfCollapsLEM && this.isShowRingLightView) {
          Image(this.parameter.isSquare ? $r('app.media.selected_item_border_fill') :
          $r('app.media.selected_item_rect_border'))
            .width(this.parameter.isSquare ? this.parameter.buttonWidth + 8 : this.parameter.buttonWidth)
            .height(this.parameter.isSquare ? this.parameter.buttonHeight + 8 : this.parameter.buttonHeight)
            .position(this.parameter.isSquare ? { x: -4, y: -4 } : { x: 0, y: 0 })
            .zIndex(ZIndex.TOP)
            .objectFit(ImageFit.Fill)
            .draggable(false)
        } else {
          Image(this.parameter.isSquare ? $r('app.media.selected_item_border') :
          $r('app.media.selected_item_rect_border'))
            .width(this.parameter.isSquare ? this.parameter.buttonWidth + 2 : this.parameter.buttonWidth)
            .height(this.parameter.isSquare ? this.parameter.buttonHeight + 2 : this.parameter.buttonHeight)
            .position(this.parameter.isSquare ? { x: -1, y: -1 } : { x: 0, y: 0 })
            .zIndex(ZIndex.TOP)
            .objectFit(ImageFit.Fill)
            .draggable(false)
        }
      }

      Column() {
        Scroll(this.scroller) { //多语言字体超过截断设置为可滚动
          Text(this.mUiElement.title)// 适老化适配, 字体不随系统字体而放大
            .fontSize($r('app.float.second_level_list_element_text_size'))
            .textAlign(TextAlign.Center)
            .fontColor(Color.White)
            .fontWeight(!this.isSelected ? FontWeight.Normal : FontWeight.Bold)
            .lineHeight('20vp')
            .textShadow({
              radius: 3,
              color: '#33000000',
              offsetX: 0,
              offsetY: 0
            })
            .rotate({
              angle: DirectionToAngleUtil.getTwoDirectionTextRotate(this.state.direction),
            })
            .fontFeature('\"ss01\" on')
            .key(`${ComponentIdKeys.getInstance().getKey('TreasureBox',
              this.functionId, this.curItemValue)}_TEXT`)
        }
        .width(this.parameter.buttonWidth)
        .scrollBar(BarState.Off)
        .scrollable(ScrollDirection.Horizontal)
        .nestedScroll({
          scrollForward: NestedScrollMode.SELF_FIRST,
          scrollBackward: NestedScrollMode.SELF_FIRST
        })
      }
      .onAppear(() => {
        HiLog.i(TAG, `ImageElement title Appear: ${this.mUiElement.title}`);
      })
      .margin(this.getTextMargin())
      .height(this.isVdeSemiCollapsed ? this.parameter.buttonWidth : this.isVdeLandscape ? 20 : TEXT_ELEMENT_HEIGHT)
      .justifyContent(FlexAlign.Start)
      .zIndex(this.isVdeCollapsed ? ZIndex.TOP : (this.isHalfCollapsLEM ? ZIndex.MIDDLE_TOP : 0))
    }
    .alignContent(Alignment.TopStart)
    .width(this.parameter.buttonWidth)
    .height(this.isVdeSemiCollapsed ? this.parameter.buttonWidth : ITEM_BUTTOM_HEIGHT)
    .enabled(true)
    .rotate({ angle: this.isVdeSemiCollapsed ? this.rotateAngle : 0 })
    .animation(this.isVdeSemiCollapsed ? {
      duration: AnimSpecifications.ANIM_DURATION_300,
      curve: Curve.Friction,
      iterations: 1,
      playMode: PlayMode.Normal,
    } : undefined)
    .accessibilityText(`${this.isSelected ? ResGetter.getStringSafe($r('app.string.accessibility_checked')) : ''} ${
    ResGetter.getStringSafe(this.mUiElement.accessibilityDescription)}`)
    .gesture(
      LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
        .onAction((event) => {
          if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
            this.createLongPressDialog('', this.mUiElement.title, true);
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

  private getTextMargin(): Margin {
    if (this.isVdeLandscape) {
      return { top: 62 };
    }
    if (this.isHalfCollapsLEM) {
      return { left: -14, top: 53 };
    }
    return { top: 66 };
  }

  private getTextRotate(currentDirection: number): number {
    if (this.isVdeSemiCollapsed) {
      return 0;
    }
    if (currentDirection === WindowDirection.BOTTOM) {
      return AnimSpecifications.ANIM_ROTATE_180;
    }
    return 0;
  }

  private createLongPressDialog(iconRes: ResourceStr, label?: ResourceStr, isOnlyShowText: boolean = false): void {
    this.customDialogViewController = new CustomDialogController({
      builder: LongPressDialogView({
        cancel: () => {
        },
        confirm:() => {
        },
        iconItem: {
          iconRes: iconRes,
          isEnabled: true,
          label: label
        },
        textRes: label,
        isOnlyShowText: isOnlyShowText
      }),
      maskColor: Color.Transparent,
      isModal: true,
      customStyle: true
    })
  }
}