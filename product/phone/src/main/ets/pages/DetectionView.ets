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

import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import type { PositionType } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper';
import lazy { CameraRunningState } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import { camera } from '@kit.CameraKit';

/* instrument ignore file */
const TAG: string = 'DetectionView';

@Component
export struct DetectionView {
  private subscriber: Unsubscribe = { destroy: () => {} };
  @Prop isShowStageLightEffect: boolean = false;
  @Prop isDisplayRotationChange: boolean = false;
  @Prop immersiveOpacity: number = 1;
  @Prop xComponentWidth: number = 1;
  @Prop xComponentHeight: number = 1;
  @Prop previewPosition: number = 0;

  @State mode: ModeType = ModeType.PHOTO;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  @State isShowFocus: boolean = false;
  @State smartControlLocked: boolean = false;
  @State isShowMorePage: boolean = false;
  @State cameraRunningState: CameraRunningState = CameraRunningState.UNINITIALIZED;
  @State videoState: RecordingState = RecordingState.READY;
  @State isHalfCollapsLEM: boolean = false;
  @State previewSize: PositionType = { x: 0, y: 0 };
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @Prop isHdr: boolean = false;

  @StorageLink('isNightShutting') isNightShutting: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear');
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.smartControlLocked = state.get<boolean>('focusExposureReducer', 'smartControlLocked');
      this.isShowFocus = state.get<boolean>('focusExposureReducer', 'isShowFocus');
      this.cameraRunningState = state.get<CameraRunningState>('cameraReducer', 'cameraRunningState');
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.previewSize = state.get<PositionType>('collapsReducer', 'previewArea');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    });
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear');
    this.subscriber.destroy();
  }

  build() {
    if (this.isShowDetectionView()) {
      Stack() {
      }
      .width(this.isHalfCollapsLEM ? this.previewSize.x : this.xComponentWidth)
      .height(this.isHalfCollapsLEM ? this.previewSize.y : this.xComponentHeight)
      .position({ x: 0, y: 0 })
      .visibility(this.immersiveOpacity !== 0 ? Visibility.Visible : Visibility.Hidden)
    }
  }

  private isShowDetectionView(): boolean {
    if (this.isShowMorePage || this.isShowStageLightEffect || this.smartControlLocked) {
      return false;
    }
    if (this.videoState !== RecordingState.READY && this.videoState !== RecordingState.STOPPING) {
      return false;
    }
    if (this.isLemCollaps || this.isShowFocus) {
      return false;
    }
    return true;
  }
}