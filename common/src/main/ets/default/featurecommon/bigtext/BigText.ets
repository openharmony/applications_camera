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
import { Action } from '../../redux/actions/Action';

class StateStruct {
  mode:string = '';
}

class BigTextDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public updateShowBigTextFlag(flag: boolean): void {
    this.mDispatch(Action.updateShowBigTextFlag(flag));
  }

  public updateUiState(state: boolean): void {
    this.mDispatch(Action.uiState(state));
  }
}

@Component
export struct BigText {
  private TAG: string = '[BigText]:'
  private modeResource: Record<string, Resource> = {
    'MULTI': $r('app.string.multi_mode'),
    'PHOTO': $r('app.string.photo_mode'),
    'VIDEO': $r('app.string.video_mode')
  }
  @State state: StateStruct = new StateStruct()
  @State bigTextOpacity: number = 0
  private mAction: BigTextDispatcher = new BigTextDispatcher();

  public aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        mode: state.modeReducer.mode
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  public aboutToDisappear(): void {
  }

  build() {
    Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Text(this.modeResource[this.state.mode])
        .fontSize(60)
        .fontColor(Color.White)
        .fontWeight(300)
        .textAlign(TextAlign.Center)
        .width('100%')
        .opacity(this.bigTextOpacity)
        .onAppear(() => {
          animateTo({ duration: 150,
            curve: Curve.Sharp,
            delay: 0,
            onFinish: () => {
              animateTo({ duration: 150,
                curve: Curve.Sharp,
                delay: 1000,
                onFinish: () => {
                  this.mAction.updateShowBigTextFlag(false)
                  this.mAction.updateUiState(true)
                }
              }, () => {
                this.bigTextOpacity = 0
              })
            }
          }, () => {
            this.bigTextOpacity = 1
          })
        })
    }
    .width('100%')
    .height('96vp')
  }
}