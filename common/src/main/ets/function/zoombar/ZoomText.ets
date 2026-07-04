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
import lazy { OhCombinedState } from '../../redux';
import lazy { DirectionToAngleUtil } from '../../utils/DirectionToAngleUtil';
import lazy { ChangeState, Unsubscribe } from '../../redux/Store';

/* instrument ignore file */
const TAG: string = 'ZoomText';

class StateStruct {
  public zoomRatio: number = 0;
  public minZoomRatio: number = 0;
  public isShowZoomText: boolean = false;
  public direction: number = 0;
}

@Component
export struct ZoomText {
  @State state: StateStruct = new StateStruct();
  private mSubscriber: Unsubscribe = { destroy: () => {} };

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        zoomRatio: state.get<number>('zoomReducer', 'zoomRatio'),
        minZoomRatio: state.get<number>('zoomReducer', 'minZoomRatio'),
        isShowZoomText: state.get<boolean>('zoomReducer', 'isShowZoomText'),
        direction: state.get<WindowDirection>('contextReducer', 'direction'),
      });
    }, null);
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mSubscriber.destroy();
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      if (this.state.isShowZoomText) {
        Text(this.state.zoomRatio < Math.min(Math.ceil(this.state.minZoomRatio * 10) / 10, 1) ?
        $r('app.string.wide_angle') : SystemLanguageUtil.isRTL() ? ('x' + this.state.zoomRatio.toFixed(1)) :
            (this.state.zoomRatio.toFixed(1) + 'x'))
          .fontSize($r('sys.float.Display_L'))
          .fontColor(Color.White)
          .fontWeight(300)
          .textShadow({ radius: 3, color: '#33000000', offsetX: 0, offsetY: 0 })
          .textAlign(TextAlign.Center)
          .touchable(false)
          .fontFeature('\"ss01\" on')
      }
    }
    .width(360)
    .height(96)
    .touchable(false)
    .rotate({
      angle: DirectionToAngleUtil.geViewRotate(this.state.direction),
    })
  }
}