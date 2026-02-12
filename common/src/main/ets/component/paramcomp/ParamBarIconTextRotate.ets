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
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { ParamBarDispatcher } from './ParamBarDispatcher';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { Unsubscribe, OhCombinedState, Dispatch, reduxSubscribe } from '../../redux';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { LongPressDialogView } from '../../component/customdialog/dialogComponent/LongPressDialogView';
import lazy { CommonConstants } from '../../statistics/CommonConstants';

/* instrument ignore file */
const TAG: string = 'ParamBarIconTextRotate';

export const PARAM_ELEMENT_SIDE_LENGTH: number = 48;

const PARAM_BAR_HEIGHT: number = 80;
const PARAM_BAR_ICON_TEXT_OFFSET_Y: number = (PARAM_BAR_HEIGHT - PARAM_ELEMENT_SIDE_LENGTH) / 2;
const ICON_SIZE: number = 20;
const TEXT_SINGLE_LINE_HEIGHT: number = 13;
const SPACE_ICON_TEXT: number = 3;
const ICON_TEXT_TOTAL_HEIGHT: number = (ICON_SIZE + TEXT_SINGLE_LINE_HEIGHT + SPACE_ICON_TEXT);
const MARGIN_TOP_BOTTOM: number = (PARAM_ELEMENT_SIDE_LENGTH - ICON_TEXT_TOTAL_HEIGHT) / 2;
const ICON_OFFSET_Y: number = MARGIN_TOP_BOTTOM + ICON_SIZE - PARAM_ELEMENT_SIDE_LENGTH / 2;

@Component
export struct ParamBarIconTextRotate {
  private mBase: BaseComponent = new BaseComponent();
  private mAction: ParamBarDispatcher = new ParamBarDispatcher();
  @Prop defaultImgSrc: Resource | string = '';
  @Prop defaultTextSrc: Resource | string = '';
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @Prop propText: string | null = '';
  @State rotateAngle: number = 0;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mSubscriber: Unsubscribe | null = null;
  @State modeType: String = ModeType.NONE;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  private customDialogViewController?: CustomDialogController;
  @State isShowLowAngleShotView: boolean = false;
  @State isShowSemiCollapsed: boolean = false;
  @State isShowRingLightView: boolean = false;
  private isBeautyIcon: boolean = false;
  private static BEAUTY_PORTRAIT_TEXT_WIDTH: number = 70;
  private static TEXT_WIDTH: number = 58;

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.modeType = state.get<ModeType>('modeReducer', 'mode');
      this.isShowLowAngleShotView = state.get<boolean>('collapsReducer', 'isShowLowAngleShotView');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear() {
    this.mSubscriber?.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
  }

  @Builder
  private ImageContentBuilder() {
    Image(this.defaultImgSrc)
      .id('defaultImgSrc')
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        bottom: { anchor: '__container__', align: VerticalAlign.Center },
      })
      .width(20)
      .height(20)
      .offset({ y: ICON_OFFSET_Y })
      .objectFit(ImageFit.Contain)
      .aspectRatio(1)
      .borderRadius(10)
      .fillColor(Color.White)
      .draggable(false)
      .syncLoad(true)
  }

  build() {
    RelativeContainer() {
      this.ImageContentBuilder();

      Text(this.propText || this.defaultTextSrc)
        .id('defaultTextSrc')
        .alignRules({
          middle: { anchor: '__container__', align: HorizontalAlign.Center },
          top: { anchor: 'defaultImgSrc', align: VerticalAlign.Bottom },
        })
        .offset({
          y: ICON_OFFSET_Y + SPACE_ICON_TEXT
        })
        .width(this.isBeautyIcon ?
          ParamBarIconTextRotate.BEAUTY_PORTRAIT_TEXT_WIDTH : ParamBarIconTextRotate.TEXT_WIDTH)
        .height(TEXT_SINGLE_LINE_HEIGHT * 2)
        .fontSize('11vp')
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .align(Alignment.Top)
        .textShadow({
          radius: 3,
          color: '#33000000',
          offsetX: 0,
          offsetY: 0
        })
        .fontFeature('\"ss01\" on')
    }
    .width(PARAM_ELEMENT_SIDE_LENGTH)
    .height(PARAM_ELEMENT_SIDE_LENGTH)
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
    .longPressDialogStyle()
    .onTouch((event) => {
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.customDialogViewController?.close();
      }
    })
  }

  @Styles
  private longPressDialogStyle() {
    .gesture(
      LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
        .onAction((event) => {
          if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
            this.createLongPressDialog(this.defaultImgSrc, this.propText || this.defaultTextSrc);
            this.customDialogViewController?.open();
          }
        })
    )
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
        textRes: label,
        isOnlyShowText: isOnlyShowText
      }),
      maskColor: Color.Transparent,
      isModal: true,
      customStyle: true
    })
  }
}