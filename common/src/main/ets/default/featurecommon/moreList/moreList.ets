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
import deviceInfo from '@ohos.deviceInfo';
import { Action } from '../../redux/actions/Action';
import { Log } from '../../utils/Log';
import { Dispatch, OhCombinedState } from '../../redux/store';
import { getStore } from '../../redux/store';

class MoreListInfo {
  itemIcon: Resource = $r("app.media.photo");
  itemValue: string = 'photo';
}

class StateStruct {
  modeIndex: number = 0;
}

class MoreListDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public swipeChangeMode(swipeModeIndex: number): void {
    this.mDispatch(Action.swipeChangeMode(swipeModeIndex));
  }
}

@Component
export struct MoreList {
  private TAG: string = '[moreList]:';
  @State state: StateStruct = new StateStruct();
  private mAction: MoreListDispatcher = new MoreListDispatcher();
  private mDirection: PanDirection = PanDirection.Right;
  private moreList: MoreListInfo[] = [{
    itemIcon: $r("app.media.photo"),
    itemValue: 'photo'
  }, {
    itemIcon: $r("app.media.sd_card"),
    itemValue: 'sd_card'
  }, {
    itemIcon: $r("app.media.setting"),
    itemValue: 'setting'
  }, {
    itemIcon: $r("app.media.small_switch_camera"),
    itemValue: 'switch'
  }, {
    itemIcon: $r("app.media.sound_mute"),
    itemValue: 'sound_mute'
  }]

  aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear start`)
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        modeIndex: state.modeReducer.modeIndex,
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.setDirection()
    Log.info(`${this.TAG} aboutToAppear end`)
  }

  private setDirection(): void {
    switch (deviceInfo.deviceType) {
      case 'PAD':
        this.mDirection = PanDirection.Down
        break
      case 'tablet':
        this.mDirection = PanDirection.Down
        break
      default:
        this.mDirection = PanDirection.Right
        break
    }
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
      Grid() {
        ForEach(this.moreList, (item: MoreListInfo) => {
          GridItem() {
            Column() {
              Image(item.itemIcon)
                .width(40)
                .height(40)
                .objectFit(ImageFit.Contain)
              Text(item.itemValue)
                .width('50%')
                .height('50%')
                .fontSize(16)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
            }
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr')
      .columnsGap(1)
      .rowsGap(1)
      .backgroundColor("rgba(205,201,201,0.6)")
    }
    .width("100%")
    .height("70%")
    .gesture(
    PanGesture({ direction: this.mDirection })
      .onActionEnd(() => {
        this.mAction.swipeChangeMode(this.state.modeIndex - 1)
      })
    )
  }
}