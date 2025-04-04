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
import { Dispatch, getStore, OhCombinedState } from '../../redux/store';

class StateStruct {
  zoomRatio: number = 1;
}

class ZoomTextDispatcher {
  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  private mDispatch: Dispatch = (data) => data;
}

@Component
export struct ZoomText {
  @Link state: StateStruct
  private TAG: string = '[ZoomText]'
  private mAction: ZoomTextDispatcher = new ZoomTextDispatcher();

  aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        zoomRatio: state.zoomReducer.zoomRatio,
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text(this.state.zoomRatio.toFixed(1))
        .fontSize(60)
        .fontColor(Color.White)
        .fontWeight(300)
        .textAlign(TextAlign.Center)
      Text('x')
        .fontSize(60)
        .fontColor(Color.White)
        .fontWeight(300)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}