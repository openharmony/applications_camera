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

import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { OhCombinedState, Unsubscribe, reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { PositionType } from '@ohos/common/src/main/ets/utils/types';

const TAG = 'AssistiveGridView';

/* instrument ignore file */
const ASSISTIVE_GRID_ROTTEN: number = 3;

@Component
export struct AssistiveGridView {
  private mGlobalAlpha: number = 0.5;
  private mLineWidth: number = 1;
  private mShadowColor: string = 'rgba(0,0,0,0.2)';
  private mShadowBlur: number = 1;
  private mShadowOffsetX: number = 0;
  private mShadowOffsetY: number = 0;
  private mStrokeStyle: string = '#FFFFFF';
  private scaleLen: number = 4;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private mSubscriber: Unsubscribe | null = null;
  @State isShowSemiCollapsed: boolean = false;
  @State isHalfCollapsLEM: boolean = false;
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
    }, null);
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  aboutToDisappear() {
    this.mSubscriber?.destroy();
  }

  drawRuler() {
    const curX = this.xComponentWidth / ASSISTIVE_GRID_ROTTEN;
    const curY = this.xComponentHeight / ASSISTIVE_GRID_ROTTEN;
    this.context.beginPath();
    this.context.globalAlpha = this.mGlobalAlpha;
    this.context.lineWidth = this.mLineWidth;
    this.context.strokeStyle = this.mStrokeStyle;
    this.context.shadowColor = this.mShadowColor;
    this.context.shadowBlur = this.mShadowBlur;
    this.context.shadowOffsetX = this.mShadowOffsetX;
    this.context.shadowOffsetY = this.mShadowOffsetY;
    for (let i = 1; i <= this.scaleLen; i++) {
      if (i <= this.scaleLen / 2) {
        this.context.moveTo(curX * i, 0);
        this.context.lineTo(curX * i, this.xComponentHeight);
      } else {
        let n = Math.floor(i / 2);
        this.context.moveTo(0, curY * n);
        this.context.lineTo(this.xComponentWidth * n, curY * n);
      }
    }
    this.context.closePath();
    this.context.stroke();
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .onReady((): void => {
          this.context.clearRect(0, 0, this.xComponentWidth, this.xComponentHeight);
          this.drawRuler();
        })
    }
    .width(this.xComponentWidth)
    .height(this.xComponentHeight)
  }
}