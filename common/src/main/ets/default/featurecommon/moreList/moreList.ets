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

import { Action } from '../../redux/actions/Action'
import { Log } from '../../utils/Log'
import { getStore } from '../../redux/store'

let localState = (state) => {
  return {
    modeIndex: state.ModeReducer.modeIndex
  }
}

let localDispatcher = (dispatch) => {
  return {
    swipeChangeMode: (swipeModeIndex) => {
      dispatch(Action.swipeChangeMode(swipeModeIndex))
    }
  }
}

class MoreListInfo {
  itemIcon: string | Resource = ''
  itemValue: number | string = ''
}

class StateStruct {
  modeIndex
  swipeChangeMode : Function
}

@Component
export struct MoreList {
  private TAG: string = '[moreList]:'
  @State state: StateStruct = new StateStruct()
  private mDirection: any
  private moreList: MoreListInfo[] = [{
                                        "itemIcon": $r("app.media.photo"),
                                        "itemValue": "photo"
                                      }, {
                                        "itemIcon": $r("app.media.sd_card"),
                                        "itemValue": "sd_card"
                                      }, {
                                        "itemIcon": $r("app.media.setting"),
                                        "itemValue": "setting"
                                      }, {
                                        "itemIcon": $r("app.media.small_switch_camera"),
                                        "itemValue": "switch"
                                      }, {
                                        "itemIcon": $r("app.media.sound_mute"),
                                        "itemValue": "sound_mute"
                                      }]

  aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear start`)
    getStore().connect(localState, localDispatcher)(this.state)
    this.setDirection()
    Log.info(`${this.TAG} aboutToAppear end`)
  }

  private setDirection() {
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
        ForEach(this.moreList, (item) => {
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
          this.state.swipeChangeMode(this.state.modeIndex - 1)
        })
    )
  }
}