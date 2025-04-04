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
import { Action } from '../../redux/actions/Action';

class StateStruct {
  isThirdPartyCall: boolean = false;
}

class TabBarDispatcher {
  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public showSettingView(isShowSettingView: boolean): void {
    this.mDispatch(Action.showSettingView(isShowSettingView));
  }

  private mDispatch: Dispatch = (data) => data;
}


@Component
export struct TabBar {
  @State state: StateStruct = new StateStruct();
  private TAG: string = '[TabBar]';
  private mAction: TabBarDispatcher = new TabBarDispatcher();

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear invoke E`)
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        isThirdPartyCall: state.contextReducer.isThirdPartyCall,
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    Log.info(`${this.TAG} aboutToAppear invoke X`)
  }

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Column() {
        //        TabBarOther()
      }.width('40%').height('100%')

      Column() {
        if (this.state.isThirdPartyCall) {
          Row() {
            Image($r('app.media.ic_public_back')).width(24).height(24)
              .onClick(() => {
                this.mAction.showSettingView(false)
                this.onBackClicked()
              })
          }.width(48).height(48)
          .padding({ left: 12 })
          .margin({ bottom: 12 })
        }
      }.width('40%').height('100%')

      Column() {
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          Image($r('app.media.setting')).width(24).height(24)
        }.width('100%').height('100%')
      }.width('20%').height('100%').onClick(() => {
        this.mAction.showSettingView(true)
      })
    }.width('100%').height('100%')
  }

  private onBackClicked: Function = () => {
  };
}