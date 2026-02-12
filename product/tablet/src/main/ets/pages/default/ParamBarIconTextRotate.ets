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

import { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import { Dispatch, OhCombinedState, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import camera from '@ohos.multimedia.camera';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import lazy {
  LongPressDialogView
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/LongPressDialogView';
import { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';

export const PARAM_ELEMENT_SIDE_LENGTH: number = 72;

const rotateTAG: string = 'ParamBarIconTextRotate';


class StateStruct {
  public xComponentWidth: number = 0;
  public position?: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
}

class ParamBarDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }
}

@Component
export struct ParamBarIconTextRotate {
  private defaultImgSrc: Resource | string = '';
  @State defaultTextSrc: Resource | string = '';
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @Prop propText: string | null = '';
  @State rotateAngle: number = 0;
  private mSubscriber: Unsubscribe | null = null;
  @State modeType: String = ModeType.NONE;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  private customDialogViewController?: CustomDialogController;
  @State abTextSrc: string = '';
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State isShowRingLightView: boolean = false;
  @Prop aperture: number | null = 0;
  private isBeautyIcon: boolean = false;
  private static BEAUTY_PORTRAIT_TEXT_WIDTH: number = 70;
  private static TEXT_WIDTH: number = 58;

  aboutToAppear() {
    HiLog.i(rotateTAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.modeType = state.get<ModeType>('modeReducer', 'mode');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
    }, null);
    HiLog.i(rotateTAG, 'aboutToAppear X.');
  }

  aboutToDisappear() {
    this.mSubscriber?.destroy();
  }

  @Builder
  ParamBarIconTextItem() {
    Column() {
      Flex({
        direction: FlexDirection.Column,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center
      }) {
        Column() {
          Image(this.defaultImgSrc)
            .id('defaultImgSrc')
            .width(20)
            .height(20)
            .objectFit(ImageFit.Cover)
            .aspectRatio(1)
            .borderRadius(10)
            .fillColor(Color.White)
            .margin({ top: $r('sys.float.padding_level1') })
            .draggable(false)
          Column() {
            Text(this.aperture ? `F${this.aperture}` : this.defaultTextSrc)
              .id('defaultTextSrc')
              .width('100%')
              .height('100%')
              // 平板美颜 字体适老化
              .fontSize(11)
              .maxFontScale(1)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .margin({ top: $r('sys.float.padding_level1') })
              .textShadow({
                radius: 3,
                color: '#33000000',
                offsetX: 0,
                offsetY: 0
              })
              .textCase(TextCase.UpperCase)
              .fontFeature('\"ss01\" on')
          }
          .width(this.isBeautyIcon ?
          ParamBarIconTextRotate.BEAUTY_PORTRAIT_TEXT_WIDTH : ParamBarIconTextRotate.TEXT_WIDTH)
          .height(13)
        }
        .rotate({ angle: this.rotateAngle })
        .animation({
          duration: AnimSpecifications.ANIM_DURATION_300,
          curve: Curve.Friction,
          iterations: 1,
          playMode: PlayMode.Normal,
          onFinish: () => {
            HiLog.i(rotateTAG, 'onFinish');
          },
        })
      }.width(PARAM_ELEMENT_SIDE_LENGTH).height(PARAM_ELEMENT_SIDE_LENGTH)
    }
    .accessibilityText(this.abTextSrc)
    .width(PARAM_ELEMENT_SIDE_LENGTH)
    .height(PARAM_ELEMENT_SIDE_LENGTH)
  }

  build() {
    Column() {
      this.ParamBarIconTextItem();
    }
    .id('Beauty')
    .width(PARAM_ELEMENT_SIDE_LENGTH)
    .height(PARAM_ELEMENT_SIDE_LENGTH)
    .gesture(
      LongPressGesture({ repeat: false, duration: CommonConstants.LONG_PRESS_TIME })
        .onAction((event) => {
          if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
            this.createLongPressDialog(this.defaultImgSrc, this.aperture ? `F${this.aperture}` : this.defaultTextSrc);
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