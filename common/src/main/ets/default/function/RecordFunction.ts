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

import { Action, UiStateMode } from '../redux/actions/Action';
import { Log } from '../utils/Log';
import { CameraStatus } from '../utils/Constants';
import { BaseFunction } from './BaseFunction';
import type { VideoCallBack } from '../camera/CameraService';
import { GlobalContext } from '../utils/GlobalContext';

const TAG = '[RecordFunction]:';

export class RecordFunction extends BaseFunction {
  private functionBackImpl: VideoCallBack = {
    videoUri: (videoUri: any): void => {
      Log.info(`${TAG} functionBackImpl videoUri ${videoUri}`);
      this.mWorkerManager.postMessage(Action.updateVideoUri(videoUri));
    },
    onRecodeError:(data: any): void => {
      this.mWorkerManager.postMessage(Action.recordError());
      this.mWorkerManager.postMessage(Action.reStartPreview(1));
    }
  }

  private async startRecording() {
    Log.info(`${TAG} startRecording E`);
    GlobalContext.get().setObject('startRecordingFlag', true);
    GlobalContext.get().setObject('cameraStatus', CameraStatus.CAMERA_BEGIN_TAKE_VIDEO);
    this.disableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    await this.mCameraService.StartRecording(this.functionBackImpl);
    // TODO update video status in State by sending action
    // temp code
    this.mWorkerManager.postMessage(Action.updateRecordingPaused(false));
    this.enableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);

    GlobalContext.get().setObject('startRecordingFlag', false);
    Log.info(`${TAG} globalThis.stopRecording : ` + GlobalContext.get().getT<boolean>('stopRecordingFlag'));
    if (GlobalContext.get().getT<boolean>('stopRecordingFlag')) {
      this.stopRecording();
      GlobalContext.get().setObject('stopRecordingFlag', false);
    }
    Log.info(`${TAG} startRecording X`);
  }

  private async pauseRecording() {
    Log.info(`${TAG} pauseRecording E`);
    this.disableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    await this.mCameraService.pauseRecording();
    // TODO update video status in State by sending action
    // temp code
    this.mWorkerManager.postMessage(Action.updateRecordingPaused(true));
    this.enableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    Log.info(`${TAG} pauseRecording X`);
  }

  private async resumeRecording() {
    Log.info(`${TAG} resumeRecording E`);
    this.disableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    await this.mCameraService.resumeRecording();
    // TODO update video status in State by sending action
    // temp code
    this.mWorkerManager.postMessage(Action.updateRecordingPaused(false));
    this.enableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    Log.info(`${TAG} resumeRecording X`);
  }

  private async stopRecording() {
    Log.info(`${TAG} stopRecording E`);

    Log.info(`${TAG} globalThis.startRecording : ${JSON.stringify(GlobalContext.get().getT<boolean>('startRecordingFlag'))}`);
    if (GlobalContext.get().getT<boolean>('startRecordingFlag')) {
      return;
    }
    this.disableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    const thumbnailPixelMap = await this.mCameraService.stopRecording();
    // TODO update video status in State by sending action
    // temp code
    this.mWorkerManager.postMessage(Action.updateRecordingTime(0));
    this.mWorkerManager.postMessage(Action.updateRecordingTimeDisplay('00:00'));
    this.mWorkerManager.postMessage(Action.updateRecordingSpotVisible(false));
    this.mWorkerManager.postMessage(Action.updateRecordingPaused(false));
    this.mWorkerManager.postMessage(Action.updateThumbnail(thumbnailPixelMap, ''));
    GlobalContext.get().setObject('cameraStatus', CameraStatus.CAMERA_TAKE_VIDEO_FINISHED);
    this.mWorkerManager.postMessage(Action.updateCameraStatus());
    this.enableUiWithMode(UiStateMode.EXCLUDE_PREVIEW);
    Log.info(`${TAG} stopRecording X`);
  }

  load(): void{
    this.mEventBus.on(Action.ACTION_RECORD_START, this.startRecording.bind(this));
    this.mEventBus.on(Action.ACTION_RECORD_PAUSE, this.pauseRecording.bind(this));
    this.mEventBus.on(Action.ACTION_RECORD_RESUME, this.resumeRecording.bind(this));
    this.mEventBus.on(Action.ACTION_RECORD_STOP, this.stopRecording.bind(this));
  }

  unload(): void {
    this.mEventBus.off(Action.ACTION_RECORD_START, this.startRecording.bind(this));
    this.mEventBus.off(Action.ACTION_RECORD_PAUSE, this.pauseRecording.bind(this));
    this.mEventBus.off(Action.ACTION_RECORD_RESUME, this.resumeRecording.bind(this));
    this.mEventBus.off(Action.ACTION_RECORD_STOP, this.stopRecording.bind(this));
  }
}