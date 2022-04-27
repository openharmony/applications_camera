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

import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import getStore from '../../../../../../../../../common/src/main/ets/default/redux/store'

let localState = (state) => {
  return {
    zoomRatio: state.UiReducer.zoomRatio
  }
}

let localDispatcher = (dispatch) => {
  return {}
}

@Component
export struct ZoomText {
  private TAG: string = '[ZoomText]'
  private mConnect: any

  @Link state: any

  private aboutToAppear() {
    CLog.info(`${this.TAG} aboutToAppear E`)
    this.mConnect = getStore().connect(localState, localDispatcher)(this.state)
    CLog.info(`${this.TAG} aboutToAppear X`)
  }

  private aboutToDisappear(): void {
    CLog.info(`${this.TAG} aboutToDisappear E`)
    this.mConnect.destroy()
    CLog.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text(this.state.zoomRatio.toFixed(1))
        .fontSize(60)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Lighter)
        .textAlign(TextAlign.Center)
      Text('x')
        .fontSize(60)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Lighter)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
      .height('100%')
  }
}