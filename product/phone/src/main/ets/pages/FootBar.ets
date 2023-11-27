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
import { Action } from '@ohos/common/src/main/ets/default/redux/actions/Action';
import { CameraSwitchButton } from '@ohos/common/src/main/ets/default/featurecommon/cameraswitcher/CameraSwitchButton';
import { EventBus } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBus';
import { EventBusManager } from '@ohos/common/src/main/ets/default/worker/eventbus/EventBusManager';
import { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/default/redux/store';
import { getStore } from '@ohos/common/src/main/ets/default/redux/store';
import { Log } from '@ohos/common/src/main/ets/default/utils/Log';
import { ShutterButton } from '@ohos/common/src/main/ets/default/featurecommon/shutterbutton/ShutterButton';
import { ThumbnailView } from '@ohos/common/src/main/ets/default/featurecommon/thumbnail/ThumbnailView';
import { CameraPlatformCapability } from '@ohos/common/src/main/ets/default/camera/CameraPlatformCapability';

class StateStruct {
  platformCapability: CameraPlatformCapability | undefined = undefined;
  isThirdPartyCall: boolean = false;
  videoState: string = '';
  showZoomLabelValue: boolean = true;
  mode: string = '';
}

class FootBarDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }
}

@Component
export struct FootBar {
  private TAG: string = '[FootBar]:';
  @State state: StateStruct = new StateStruct();
  @State isRecording: boolean = false;
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mAction: FootBarDispatcher = new FootBarDispatcher();

  private async onRecordStart(): Promise<void> {
    this.isRecording = true
    Log.info(`${this.TAG} onRecordStart`)
  }

  private async onRecordStop(): Promise<void> {
    this.isRecording = false
    Log.info(`${this.TAG} onRecordStop`)
  }

  aboutToAppear(): void {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        platformCapability: state.cameraInitReducer.platformCapability,
        isThirdPartyCall: state.contextReducer.isThirdPartyCall,
        videoState: state.recordReducer.videoState,
        showZoomLabelValue: state.zoomReducer.showZoomLabelValue,
        mode: state.modeReducer.mode,
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.isRecording = false
    this.appEventBus.on(Action.ACTION_RECORD_START, () => this.onRecordStart())
    this.appEventBus.on(Action.ACTION_RECORD_STOP, () => this.onRecordStop())
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_RECORD_START, () => this.onRecordStart())
    this.appEventBus.off(Action.ACTION_RECORD_STOP, () => this.onRecordStop())
    Log.info(`${this.TAG} aboutToDisappear X`)
  }

  private isThumbnailViewVisibility(): boolean {
    return!this.isRecording && !this.state.isThirdPartyCall &&
    this.state.videoState !== "startTakeVideo" && this.state.videoState !== "pauseTakeVideo"
  }

  private isPhoneSwitchShow(): boolean {
    if (this.state.platformCapability) {
      return deviceInfo.deviceType !== 'default' && this.state.platformCapability?.mCameraCount > 1 &&
      !this.isRecording
    } else {
      return false;
    }
  }

  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.Center
    }) {
      Column() {
        ThumbnailView()
      }.width(44).aspectRatio(1).visibility(this.isThumbnailViewVisibility() ? Visibility.Visible : Visibility.Hidden)

      ShutterButton()
      if (this.isPhoneSwitchShow()) {
        CameraSwitchButton()
      } else {
        Column() {
        }
        .width('44')
        .aspectRatio(1)
      }
    }
    .height(96)
    .opacity(100)
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .visibility(this.state.showZoomLabelValue ? Visibility.Visible : Visibility.Hidden)
  }
}