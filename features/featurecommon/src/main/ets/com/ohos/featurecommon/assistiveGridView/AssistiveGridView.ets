/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import { Action } from '../../../../../../../../../common/src/main/ets/default/redux/actions/Action'
import { CLog } from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import { SettingsUtil } from '../../../../../../../../../common/src/main/ets/default/Utils/SettingsUtil'
import getStore from '../../../../../../../../../common/src/main/ets/default/redux/store'

let localState = (state) => {
  return {
    mode: state.ModeReducer.mode
  }
}

let localDispatcher = (dispatch) => {
  return {}
}

@Component
export struct AssistiveGridView {
  private TAG: string = '[AssistiveGridView]:'
  private curX: number = 0
  private curY: number = 0
  private mGlobalAlpha: number = 0.5
  private mLineWidth: number = 0
  private mShadowBlur: number = 5
  private mShadowColor: string = 'argb(#7F000000)'
  private mShadowOffsetX: number = 0
  private mShadowOffsetY: number = 0
  private mStrokeStyle: string = '#FFFFFF'

  private scaleLen: number = 4
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private settingsUtil = SettingsUtil.getInstance()
  private xCWidth: number = 0
  private xCHeight: number = 0
  @State state: any = {}
  private mConnect: any

  private aboutToAppear(): void {
    CLog.info(`${this.TAG} aboutToAppear invoke E`)
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    let xComponentAssSize = this.settingsUtil.getPreviewDisplaySizeForAss(this.state.mode)
    this.xCWidth = xComponentAssSize.width
    this.xCHeight = xComponentAssSize.height
    this.curX = this.xCWidth / 3
    this.curY = this.xCHeight / 3

    let vp2pxValue = Math.round(vp2px(0.5))
    if (vp2pxValue < 1) {
      this.mLineWidth = 1
    } else {
      this.mLineWidth = vp2pxValue
    }
    CLog.info(`${this.TAG} aboutToAppear vp2pxValue X ${vp2pxValue}`)
    CLog.info(`${this.TAG} aboutToAppear invoke X ${this.mLineWidth}`)
  }

  private aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear invoke E`)
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear invoke X`)
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.context.clearRect(0, 0, this.xCWidth, this.xCHeight);
          this.drawRuler()
        })
    }
    .width(this.xCWidth)
    .height(this.xCHeight)
  }

  drawRuler() {
    this.context.beginPath();
    this.context.globalAlpha = this.mGlobalAlpha
    this.context.lineWidth = this.mLineWidth
    this.context.strokeStyle = this.mStrokeStyle
    this.context.shadowColor = this.mShadowColor
    this.context.shadowOffsetX = this.mShadowOffsetX
    this.context.shadowOffsetY = this.mShadowOffsetY
    for (let i = 1; i <= this.scaleLen; i++) {
      if (i <= this.scaleLen / 2) {
        this.context.moveTo(this.curX * i, 0)
        this.context.lineTo(this.curX * i, this.xCHeight)
      } else {
        let n = Math.floor(i / 2)
        this.context.moveTo(0, this.curY * n)
        this.context.lineTo(this.xCWidth * n, this.curY * n)
      }
    }
    this.context.closePath()
    this.context.stroke()
  }
}