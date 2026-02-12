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
import lazy { HiLog } from '../../utils/HiLog';
import lazy { WindowService } from '../../service/window/WindowService';
import PickerVideoUtils from './PickerVideoUtils';
import lazy { PickerUiService } from '../../service/picker/PickerUiService';

const TAG: string = 'PickerVideoController';

export const VIDEO_CONTROLLER_COMPONENT_HEIGHT: number = 56;

const MAX_VIDEO_CONTROLLER_COMPONENT_WIDTH: number = 475;
const BUTTON_SIZE: number = 24;
const HOT_AREA_SIZE: number = 40;
const SPACE_BUTTON_SLIDER: number = 8;
const PADDING_LEFT: number = 16;
const PADDING_RIGHT: number = 24;
const SLIDER_UPDATE_STEP: number = 30;
const SPACE_SLIDER_TO_BORDER: number = 6;
const VIDEO_READY_OPACITY: number = 1;
const VIDEO_NOT_READY_OPACITY: number = 0.4;

@Component
export struct PickerVideoController {
  @Prop isVideoReady: boolean = false;
  @Prop @Watch('uxInit') componentWidth: number = 0;
  @State currentVideoTime: number = 0;
  @Link videoDuration: number;
  @Link isVideoPlaying: boolean;
  @Link isShowPreviewPixelMap: boolean;
  @Link isVideoFinished: boolean;
  @State videoSliderWidth: number = 0;
  @State timeDisplay: string = '00:00';
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  private timer: number = Number.MIN_VALUE;
  public videoController: VideoController | undefined = undefined;

  aboutToAppear(): void {
    this.uxInit();
  }

  aboutToDisappear(): void {
    if (this.isVideoReady) {
      PickerUiService.getInstance().setVideoTimeBeforeCollapsing(this.currentVideoTime);
    }
  }

  private uxInit(): void {
    this.componentWidth = this.getComponentWidth();
    this.videoSliderWidth = this.getVideoSliderWidth();
  }

  private getComponentWidth(): number {
    return Math.min(MAX_VIDEO_CONTROLLER_COMPONENT_WIDTH, this.componentWidth);
  }

  private getVideoSliderWidth(): number {
    return this.componentWidth - PADDING_LEFT - PADDING_RIGHT - SPACE_BUTTON_SLIDER - HOT_AREA_SIZE +
      SPACE_SLIDER_TO_BORDER * 2;
  }

  private sliderOnChange(value: number, sliderChangeMode: SliderChangeMode): void {
    if (!this.isVideoReady) {
      return;
    }
    this.dealSliderChangeMode(sliderChangeMode);
    this.isShowPreviewPixelMap = false;
    this.currentVideoTime = value;
    if (this.currentVideoTime !== this.videoDuration) {
      this.isVideoFinished = false;
    }
    this.videoController?.setCurrentTime(this.currentVideoTime / 1000, SeekMode.Accurate);
  }

  private dealSliderChangeMode(sliderChangeMode: SliderChangeMode): void {
    if (!this.isVideoPlaying) {
      return;
    }
    if (sliderChangeMode === SliderChangeMode.Moving) {
      this.videoController?.pause();
    }
    if (sliderChangeMode === SliderChangeMode.End) {
      this.videoController?.start();
    }
  }

  private videoButtonOnClick(): void {
    HiLog.i(TAG, `video button clicked. ${this.isVideoReady}`);
    if (!this.isVideoReady) {
      return;
    }
    HiLog.i(TAG, 'video button clicked.');
    if (this.isVideoPlaying) {
      this.videoController?.pause();
      this.isVideoPlaying = false;
      clearInterval(this.timer);
      WindowService.getInstance().setWindowKeepScreenOn(false);
    } else {
      this.videoController?.start();
      if (this.isVideoFinished) {
        this.currentVideoTime = 0;
        this.isVideoFinished = false;
      }
      this.updateVideoController();
      this.isVideoPlaying = true;
      WindowService.getInstance().setWindowKeepScreenOn(true);
    }
  }

  private updateVideoController(): void {
    // 时间纠正机制
    const startTime: number = Date.now();
    this.timer = setTimeout(() => {
      clearTimeout(this.timer);
      const endTime: number = Date.now();
      this.currentVideoTime += (endTime - startTime);
      if (this.currentVideoTime < this.videoDuration) {
        this.updateVideoController();
      } else {
        this.currentVideoTime = this.videoDuration;
      }
    }, SLIDER_UPDATE_STEP);
  }

  @Builder
  VideoControllerButton() {
    Stack() {
      Image(this.isVideoPlaying ? $r('sys.media.ohos_ic_public_pause') : $r('sys.media.ohos_ic_public_play'))
        .width(BUTTON_SIZE)
        .height(BUTTON_SIZE)
        .fillColor('rgba(255,255,255,0.9)')
        .opacity(this.isVideoReady ? VIDEO_READY_OPACITY : VIDEO_NOT_READY_OPACITY)
    }
    .width(HOT_AREA_SIZE)
    .height(HOT_AREA_SIZE)
    .enabled(this.isVideoReady)
    .onClick(() => {
      this.videoButtonOnClick();
    })
  }

  @Builder
  VideoSlider() {
    Slider({
      value: this.currentVideoTime,
      min: 0,
      max: this.videoDuration,
      style: SliderStyle.NONE
    })
      .width(this.videoSliderWidth)
      .trackThickness(SliderStyle.OutSet)
      .trackColor('rgba(255, 255, 255, 0.4)')
      .selectedColor(Color.White)
      .onChange((value: number, sliderChangeMode: SliderChangeMode) => {
        this.sliderOnChange(value, sliderChangeMode);
      })
      .onAppear(() => {
        if (this.isVideoReady) {
          this.sliderOnChange(PickerUiService.getInstance().getVideoTimeBeforeCollapsing(), SliderChangeMode.End);
        }
      })
  }

  @Builder
  VideoControllerPart() {
    Row() {
      this.VideoControllerButton();
      this.VideoSlider();
    }
    .width('100%')
    .height('100%')
    .padding({ left: PADDING_LEFT, right: PADDING_RIGHT - SPACE_SLIDER_TO_BORDER })
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  DurationTimeText() {
    Text(PickerVideoUtils.formatVideoTime(this.videoDuration))
      .fontSize($r('sys.float.Body_M'))
      .fontColor(Color.White)
      .lineHeight(20)
      .textAlign(TextAlign.Center)
      .fontFeature('\"ss01\" on')
  }

  @Builder
  CurrentTimeText() {
    Text(PickerVideoUtils.formatVideoTime(this.currentVideoTime, true))
      .fontSize($r('sys.float.Body_M'))
      .fontColor(Color.White)
      .lineHeight(20)
      .textAlign(TextAlign.Center)
      .fontFeature('\"ss01\" on')
  }

  @Builder
  VideoTimeTextPart() {
    Row() {
      this.CurrentTimeText();
      this.DurationTimeText();
    }
    .width(this.componentWidth)
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: PADDING_LEFT + HOT_AREA_SIZE + SPACE_BUTTON_SLIDER, right: 24 })
    .position({ x: 0, y: this.fontSizeScale > 2 ? -40 : -10 })
  }

  build() {
    Stack() {
      this.VideoTimeTextPart();
      this.VideoControllerPart();
    }
    .width(this.componentWidth)
    .height(VIDEO_CONTROLLER_COMPONENT_HEIGHT)
  }
}