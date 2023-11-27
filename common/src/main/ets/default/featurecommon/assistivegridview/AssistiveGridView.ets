/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import { Log } from '../../utils/Log';
import { Dispatch, OhCombinedState } from '../../redux/store';
import { getStore } from '../../redux/store';

class StateStruct {
  xComponentWidth: number = 0;
  xComponentHeight: number = 0;
}

class AssistiveGridViewDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }
}

@Component
export struct AssistiveGridView {
  private TAG: string = '[AssistiveGridView]:';
  private mGlobalAlpha: number = 0.5;
  private mLineWidth: number = 0.5;
  private mShadowColor: string = 'argb(#7F000000)';
  private mShadowOffsetX: number = 0;
  private mShadowOffsetY: number = 0;
  private mStrokeStyle: string = '#FFFFFF';
  private scaleLen: number = 4;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private mAction: AssistiveGridViewDispatcher = new AssistiveGridViewDispatcher();
  @State state: StateStruct = new StateStruct();

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear invoke E`);
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        xComponentWidth: state.previewReducer.xComponentWidth,
        xComponentHeight: state.previewReducer.xComponentHeight
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    Log.info(`${this.TAG} aboutToAppear invoke X`)
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.context.clearRect(0, 0, this.state.xComponentWidth, this.state.xComponentHeight)
          this.drawRuler()
        })
    }
    .width(this.state.xComponentWidth)
    .height(this.state.xComponentHeight)
  }

  drawRuler(): void {
    let xCWidth = this.state.xComponentWidth
    let xCHeight = this.state.xComponentHeight
    let curX = xCWidth / 3
    let curY = xCHeight / 3
    this.context.beginPath()
    this.context.globalAlpha = this.mGlobalAlpha
    this.context.lineWidth = this.mLineWidth
    this.context.strokeStyle = this.mStrokeStyle
    this.context.shadowColor = this.mShadowColor
    this.context.shadowOffsetX = this.mShadowOffsetX
    this.context.shadowOffsetY = this.mShadowOffsetY
    for (let i = 1; i <= this.scaleLen; i++) {
      if (i <= this.scaleLen / 2) {
        this.context.moveTo(curX * i, 0)
        this.context.lineTo(curX * i, xCHeight)
      } else {
        let n = Math.floor(i / 2)
        this.context.moveTo(0, curY * n)
        this.context.lineTo(xCWidth * n, curY * n)
      }
    }
    this.context.closePath()
    this.context.stroke()
  }
}