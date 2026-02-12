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

import lazy { OhCombinedState, Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { ViewRotateTranslate } from '@ohos/common/src/main/ets/utils/ViewRotateTranslate';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';

/* instrument ignore file */
const TAG: string = 'ThumbnailReminder';

const TOP_HOLE: number = 36;
const MARGIN_PADDING_24: number = 24;
const WH_100_100: string = '100%';

@Component
export struct ThumbnailReminder {
  private readonly ANIMATION_DURATION_420: number = 420;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @State rotateAngle: number = 0;
  @State displayWidth: number = 0;
  @State displayHeight: number = 0;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      if (WindowService.getInstance().isSubscriptionNeeded()) {
        this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
        this.rotateAngle = state.get<number>('contextReducer', 'settingAngle');
      }
      this.displayWidth = state.get<number>('windowReducer', 'windowWidth');
      this.displayHeight = state.get<number>('windowReducer', 'windowHeight');
    }, null);
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  aboutToDisappear(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  private isVertical(): boolean {
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  private getColumns(): number {
    return this.isVertical() ? 4 : 8;
  }

  private getImageSpan(): number {
    return this.isVertical() ? 4 : 8;
  }

  private getTipSpan(): number {
    return this.isVertical() ? 4 : 6;
  }

  private getOffset(): number {
    return this.isVertical() ? 0 : 1;
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
      alignItems: ItemAlign.Start,
      justifyContent: FlexAlign.Start
    }) {
      GridRow({
        columns: this.getColumns(),
        gutter: { x: 24, y: 0 },
        direction: GridRowDirection.Row
      }) {

        GridCol({
          span: {
            xs: this.getImageSpan(),
            sm: this.getImageSpan(),
            md: this.getImageSpan(),
            lg: this.getImageSpan()
          },
          offset: 0
        }) {
        }.height('20%')

        GridCol({
          span: {
            xs: this.getTipSpan(),
            sm: this.getTipSpan(),
            md: this.getTipSpan(),
            lg: this.getTipSpan()
          },
          offset: this.getOffset()
        }) {
          Tip()
        }.height(this.isVertical() ? '40%' : '60%')
        .rotate({
          angle: this.rotateAngle
        })
        .animation(
          {
            duration: this.ANIMATION_DURATION_420,
            curve: Curve.Sharp,
            iterations: 1,
            playMode: PlayMode.Normal,
            onFinish: () => {
              HiLog.i(TAG, 'animation onFinish');
            }
          })

        GridCol({
          span: {
            xs: this.getImageSpan(),
            sm: this.getImageSpan(),
            md: this.getImageSpan(),
            lg: this.getImageSpan()
          },
          offset: 0
        }) {
        }.height(this.isVertical() ? '40%' : '20%')
      }.width(WH_100_100).height(WH_100_100)
    }
    .width(this.isVertical() ? this.displayWidth : this.displayHeight)
    .height(this.isVertical() ? this.displayHeight : this.displayWidth)
    .padding({
      top: this.isVertical() ? TOP_HOLE : 0,
      left: this.mDirection === WindowDirection.RIGHT ? TOP_HOLE : MARGIN_PADDING_24,
      right: (this.mDirection === WindowDirection.RIGHT || this.isVertical()) ? MARGIN_PADDING_24 : TOP_HOLE
    })
    .translate({
      x: this.isVertical() ? 0 : ViewRotateTranslate.getTranslateSize(this.displayHeight, this.displayWidth).translateX,
      y: this.isVertical() ? 0 : ViewRotateTranslate.getTranslateSize(this.displayHeight,
        this.displayWidth).translateY,
    })
    .animation(
      {
        duration: this.ANIMATION_DURATION_420,
        curve: Curve.Sharp,
        iterations: 1,
        playMode: PlayMode.Normal,
        onFinish: () => {
          HiLog.i(TAG, 'animation onFinish');
        }
      })
    .backgroundColor('#000000')
  }
}

@Component
export struct Tip {
  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text($r('app.string.no_photos_and_videos'))
        .fontSize($r('sys.float.Body_L'))
        .fontWeight(FontWeight.Medium)
        .lineHeight(21)
        .textAlign(TextAlign.Center)
        .fontColor('#DBFFFFFF')
        .fontFeature('\"ss01\" on')
        .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
      Text($r('app.string.no_photos_and_videos_desc'))
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Regular)
        .lineHeight(19)
        .margin({ top: $r('sys.float.padding_level4') })
        .textAlign(TextAlign.Center)
        .fontColor('#99FFFFFF')
        .fontFeature('\"ss01\" on')
        .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
    }
    .width(WH_100_100)
    .height(WH_100_100)
  }
}