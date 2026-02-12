/*
 * Copyright (c) Huawei Device Co., Ltd. 2023-2025. All rights reserved.
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

import { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import { OhCombinedState, reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { CameraSwitchButton } from '@ohos/common/src/main/ets/function/cameraswitcher/CameraSwitchButton';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { ThumbnailView } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailView';
import lazy { ShutterButtonLand } from '@ohos/common/src/main/ets/function/capture/ShutterButtonLand';
import { ChangeState, Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';

const TAG: string = 'FootBarLand';

class StateStruct {
  public videoState: RecordingState = RecordingState.READY;
  public isThirdPartyCall: boolean = false;
  public uiEnable: boolean = false;
}

@Component
export struct FootBarLand {
  @State state: StateStruct = new StateStruct();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State showCameraSwitcher: boolean = false;
  @StorageProp('cameraCount') mCameraCount: number = 2;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E.');
    const featureManager = FeatureManager.getInstance();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.showCameraSwitcher = featureManager.isAvailableFunction(FunctionId.CAMERA_SWITCHER);
      changeState(this.state, {
        videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
        isThirdPartyCall: state.get<boolean>('contextReducer', 'isThirdPartyCall'),
        uiEnable: state.get<boolean>('contextReducer', 'uiEnable'),
      });
    }, null);
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mSubscriber.destroy();
    HiLog.i(TAG, 'aboutToDisappear X.');
  }

  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.Center
    }) {
      ThumbnailView({
        isThumbnailViewVisibility: this.isThumbnailViewVisibility()
      })
        .enabled(this.state.uiEnable)
        .width(44).aspectRatio(1)

      ShutterButtonLand()
      Column() {
      }
      .width(44)
      .aspectRatio(1)
    }
  }

  private isThumbnailViewVisibility() {
    return this.state.videoState === RecordingState.READY && !this.state.isThirdPartyCall;
  }
}