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
import lazy { image } from '@kit.ImageKit';
import lazy { RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { getStates } from '../../redux';
import lazy { PickerUiService } from '../../service/picker/PickerUiService';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { PickerVideoController } from './PickerVideoController';
import PickerVideoUtils from './PickerVideoUtils';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { RecordController } from '../../function/recordcontrol/RecordController';

const TAG: string = 'VideoPlayer';

@Component
export struct VideoPlayer {
  @Prop uri: string = '';
  @Prop videoControllerOffsetFromCenter: Position = { x: 0, y: 0 };
  @Prop videoControllerWidth: number = 0;
  @State videoDuration: number = 0;
  @StorageLink('isPickerVideoReady') isPickerVideoReady: boolean = false;
  @State isVideoPlaying: boolean = false;
  @State isVideoFinished: boolean = false;
  @State isShowPreviewPixelMap: boolean = true;
  private base: BaseComponent = new BaseComponent();
  private eventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mVideoController = new VideoController();
  public previewPixelMap: image.PixelMap | undefined = undefined;

  aboutToAppear(): void {
    if (this.isPickerVideoReady) {
      this.queryVideoDuration();
    }
    if (getStates().get<RecordingState>('recordReducer', 'recordingState') === RecordingState.READY) {
      this.onVideoReady();
    }
    if (RecordController.getInstance().isMovieFile()) {
      this.eventBus.on(RecordActionType.SAVE_MOVIE_INFO_ASSET_DONE, () => this.onVideoReady(), this.base.hashCode());
    } else {
      this.eventBus.on(RecordActionType.STOPPED, () => this.onVideoReady(), this.base.hashCode());
    }
  }

  aboutToDisappear(): void {
    this.eventBus.clear(this.base.hashCode());
  }

  private onVideoReady(): void {
    this.uri = getStates().get<string>('recordReducer', 'videoUri');
    this.queryVideoDuration();
    this.isPickerVideoReady = true;
  }

  private async queryVideoDuration(): Promise<void> {
    this.videoDuration = await PickerVideoUtils.queryVideoDuration(this.uri);
    HiLog.d(TAG, `The video duration is ${this.videoDuration} ms.`);
  }

  @Builder
  VideoComponent() {
    Stack() {
      if (this.isPickerVideoReady) {
        Video({
          src: this.uri,
          previewUri: this.isShowPreviewPixelMap ? this.previewPixelMap : '',
          controller: this.mVideoController
        })
          .controls(false)
          .objectFit(ImageFit.Contain)
          .onPrepared(() => {
            this.mVideoController.setCurrentTime(PickerUiService.getInstance().getVideoTimeBeforeCollapsing() / 1000,
              SeekMode.Accurate);
          })
          .onStart(() => {
            this.isShowPreviewPixelMap = false;
            this.isVideoFinished = false;
          })
          .onFinish(() => {
            this.isVideoPlaying = false;
            this.isVideoFinished = true;
            WindowService.getInstance().setWindowKeepScreenOn(false);
          })
      }
      if (this.isShowPreviewPixelMap) {
        Image(this.previewPixelMap)
          .objectFit(ImageFit.Contain)
          .draggable(false)
          .syncLoad(true)
      }
    }
  }

  build() {
    Stack() {
      this.VideoComponent();
      PickerVideoController({
        videoDuration: this.videoDuration,
        isVideoReady: this.isPickerVideoReady,
        isVideoPlaying: this.isVideoPlaying,
        isVideoFinished: this.isVideoFinished,
        videoController: this.mVideoController,
        isShowPreviewPixelMap: this.isShowPreviewPixelMap,
        componentWidth: this.videoControllerWidth,
      })
        .offset(this.videoControllerOffsetFromCenter)
    }
    .width('100%')
    .height('100%')
  }
}