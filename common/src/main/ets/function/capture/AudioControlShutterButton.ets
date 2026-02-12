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

import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { OhCombinedState, Unsubscribe } from '../../redux';
import lazy { reduxSubscribe } from '../../redux/Store';
import lazy { getColorString } from '../../utils/ColorUtil';

/* instrument ignore file */
const TAG = 'AudioControlShutterButton';

@Component
export struct AudioControlShutterButton {
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe | null = null;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private audioControlType: Boolean = true;
  private heightList: number[] = [23, 21, 19, 17];
  private stateList: Boolean[] = [false, false, false, false];
  private animationInterval: number = 420 / 9;
  private minHeight = 23;
  private maxHeight = 14;
  @State audioOpacity: number = 1;
  @State audioScale: ScaleOptions = { x: 1, y: 1 };
  @State isShowRingLightView: boolean = false;
  private mIntervalID: number = Number.MIN_VALUE;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State isVdeCollapsed: boolean = false;

  aboutToAppear() {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
    }, null);
    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.CHANGE_OUTPUT_TYPE,
      CameraActionType.SWITCH_CAMERA_CHANGE_MODE, CameraActionType.SWITCH_CAMERA],
      this.onChangeModeState.bind(this), this.mBase.hashCode());
  }

  aboutToDisappear(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber?.destroy();
  }

  private onChangeModeState() {
    this.onForegroundCallback();
  }

  private onForegroundCallback(): void {
    this.audioControlType = true;
    this.heightList = this.isVdeCollapsed ? [25, 23, 21, 19] : [23, 21, 19, 17];
    this.stateList = [false, false, false, false];
  }

  drawRuler() {
    if (!this.audioControlType) {
      this.isVdeCollapsed ? this.context.clearRect(0, 0, 33, 33) : this.context.clearRect(0, 0, 48, 48);
      return;
    }
    let xPos = this.isVdeCollapsed ? 8 : 14;
    let yPos = this.isVdeCollapsed ? 24 : 33;
    let spacing = this.isVdeCollapsed ? 5.5 : 6.5;
    for (let i = 0; i < 4; i++) {
      this.isVdeCollapsed ? this.context.clearRect(0, 0, 33, 33) : this.context.clearRect(0, 0, 48, 48);
      if (this.heightList[i] >= this.minHeight) {
        this.stateList[i] = true;
      } else if (this.heightList[i] <= this.maxHeight) {
        this.stateList[i] = false;
      }
      if (this.stateList[i] === true) {
        this.heightList[i]--;
      } else {
        this.heightList[i]++;
      }
    }
    this.context.lineWidth = 2;
    this.context.beginPath();
    this.context.lineCap = 'round';
    this.context.strokeStyle = getColorString();
    this.context.moveTo(xPos, yPos); // 绘制动效所需四条线
    this.context.lineTo(xPos, this.heightList[0]);
    this.context.moveTo(xPos + spacing, yPos);
    this.context.lineTo(xPos + spacing, this.heightList[1]);
    this.context.moveTo(xPos + spacing * 2, yPos);
    this.context.lineTo(xPos + spacing * 2, this.heightList[2]);
    this.context.moveTo(xPos + spacing * 3, yPos);
    this.context.lineTo(xPos + spacing * 3, this.heightList[3]);
    this.context.stroke();
  };

  build() {
    Row() {
      Canvas(this.context)
        .backgroundColor(Color.White)
        .width(this.isVdeCollapsed ? 33 : 48)
        .height(this.isVdeCollapsed ? 33 : 48)
        .borderRadius(24)
        .opacity(this.audioOpacity)
        .scale(this.audioScale)
        .onReady((): void => {
          HiLog.i(TAG, 'Canvas onReady');
          this.onForegroundCallback();
          if (this.mIntervalID !== Number.MIN_VALUE) {
            clearInterval(this.mIntervalID);
          }
          this.mIntervalID = setInterval(() => {
            this.drawRuler();
          }, this.animationInterval);
        })
        .onDisAppear((): void => {
          HiLog.i(TAG, 'Canvas onDisAppear');
          this.audioControlType = false;
          clearInterval(this.mIntervalID);
        })
    }
    .alignItems(VerticalAlign.Bottom)
  }
}