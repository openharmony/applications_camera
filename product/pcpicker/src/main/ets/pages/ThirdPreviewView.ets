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

import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import image from '@ohos.multimedia.image';
import lazy { Action, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { CircleImage } from '@ohos/common/src/main/ets/component/picker/CircleImage'
import { ChangeState, Dispatch, execDispatch } from '@ohos/common/src/main/ets/redux/Store';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import { PcInfo } from '@ohos/common/src/main/ets/component/deviceinfo/PcInfo';
import { reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import { window } from '@kit.ArkUI';
import { CameraAction } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';

const TAG: string = 'ThirdPreviewView';
const BUTTON_SIZE: number = 44;
const SHUTTER_BUTTON_WIDTH: number = 64;
const BUTTON_ROW_HEIGHT: number = 72;
const SPACE_BETWEEN_BUTTONS: number = 74;
const BUTTON_ROW_MARGIN_BOTTOM: number = 32;
const ANGLE_90: number = 90;
const ANGLE_180: number = 180;
const ANGLE_270: number = 270;
const ANGLE_0: number = 0;
const ROTATION_1: number = 1;
const ROTATION_3: number = 3;

class StateStruct {
  public photoWidth: number = 0;
  public photoHeight: number = 0;
  public mode: ModeType = ModeType.NONE;
  public photoUri: string = '';
  public videoUri: string = '';
}

class ThirdPreviewViewDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }
}

@Component
export struct ThirdPreviewView {
  @State controls: boolean = false;
  private mBase: BaseComponent = new BaseComponent();
  protected mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State isShowVideoButton: boolean = true;
  @State state: StateStruct = new StateStruct();
  @State windowHeight: number = 0;
  private myVideoController: VideoController = new VideoController();
  private mAction: ThirdPreviewViewDispatcher = new ThirdPreviewViewDispatcher();
  @State thumbnail: image.PixelMap | null = null;
  private callBundleName: string = '';
  @Consume('pageInfos') pageInfos: NavPathStack;
  @State mode: ModeType = ModeType.NONE;
  @State curWindowStatus: window.WindowStatusType = window.WindowStatusType.UNDEFINED;
  private rotation: number = DisplayService.getInstance().getDisplay().rotation;

  aboutToAppear() {
    HiLog.begin(TAG, 'aboutToAppear.');
    reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        photoWidth: state.get<number>('previewReducer', 'xComponentWidth'),
        photoHeight: state.get<number>('previewReducer', 'xComponentHeight'),
        mode: state.get<ModeType>('modeReducer', 'mode'),
        videoUri: state.get<string>('recordReducer', 'videoUri'),
        photoUri: state.get<string>('captureReducer', 'resourceUri'),
      });
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.curWindowStatus = state.get<number>('windowReducer', 'windowStatus')
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.thumbnail = PickerUiService.getInstance().getThumbnail();
    this.callBundleName = GlobalContext.get()
      .getCameraAbilityWant()?.parameters?.callBundleName as string;
    HiLog.end(TAG, 'aboutToAppear.');
  }

  aboutToDisappear() {
    HiLog.i(TAG, 'aboutToDisappear.');
    this.mEventBus?.clear(this.mBase.hashCode());
  }

  async backCalledApp(isPhoto: boolean) {
    HiLog.i(TAG, 'backCalledApp start.');
    const uri = isPhoto ? this.state.photoUri : this.state.videoUri;
    HiLog.i(TAG, `isPhoto: ${isPhoto}`);
    await PickerUiService.getInstance().backAfterCapture(isPhoto, uri,
      this.callBundleName);
  }

  private getButtonRowWidth(): number {
    return 2 * (BUTTON_SIZE + SPACE_BETWEEN_BUTTONS) + SHUTTER_BUTTON_WIDTH;
  }

  private getButtonRowOffset(): Position {
    if (!PcInfo.isRotatablePc() && this.curWindowStatus === window.WindowStatusType.MAXIMIZE) {
      return { y: this.windowHeight / 2 - BUTTON_ROW_HEIGHT - BUTTON_ROW_MARGIN_BOTTOM };
    } else {
      return { y: this.windowHeight / 2 - BUTTON_ROW_HEIGHT / 2 - BUTTON_ROW_MARGIN_BOTTOM };
    }
  }

  private getXComponentSideLength(length: number): number | string {
    let isWindowStatusFloat: boolean = this.curWindowStatus === window.WindowStatusType.FLOATING;
    return PcInfo.isRotatablePc() || (!PcInfo.isRotatablePc() && !isWindowStatusFloat) ? length : '100%';
  }

  private isPortraitScreen(): boolean {
    const isRotatablePc: boolean = PcInfo.isRotatablePc();
    if (isRotatablePc && (this.rotation === ROTATION_1 || this.rotation === ROTATION_3)) {
      return false;
    }
    return true;
  }

  @Builder
  thumbnailBuilder() {
    Column() {
      Image(this.thumbnail)
        .width('100%')
        .height('100%')
        .draggable(false)
        .syncLoad(true)
        .objectFit(ImageFit.Fill)
    }
    .width(this.isPortraitScreen() ? this.getXComponentSideLength(this.state.photoWidth) :
    this.getXComponentSideLength(this.state.photoHeight))
    .height(this.isPortraitScreen() ? this.getXComponentSideLength(this.state.photoHeight) :
    this.getXComponentSideLength(this.state.photoWidth))
  }

  @Builder
  videoBuilder() {
    Video({
      src: this.state.videoUri,
      previewUri: this.thumbnail,
      controller: this.myVideoController
    })
      .controls(this.controls)
      .objectFit(ImageFit.Contain)
      .width(this.state.photoWidth)
      .height(this.state.photoHeight)
      .onClick((): void => {
        this.controls = !this.controls;
      })
      .onFinish((): void => {
        this.controls = true;
      })
      .zIndex(ZIndex.MIDDLE_BOTTOM)
  }

  @Builder
  videoButtonBuilder() {
    if (this.isShowVideoButton) {
      Column() {
        Flex({
          direction: FlexDirection.Column,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.Center
        }) {
          Image(this.getVideoPlayIcon())
            .objectFit(ImageFit.Contain)
            .width(56)
            .height(56)
            .onClick((): void => {
              this.myVideoController.start();
              this.isShowVideoButton = false;
            })
            .draggable(false)
        }
      }.zIndex(ZIndex.MIDDLE_TOP)
    }
  }

  @Builder
  buttonRow() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.SpaceBetween
    }) {
      CircleImage({
        circleImageRes: $r('app.media.ic_camera_cancel'),
        onCircleImageClicked: () => {
          if (!this.isShowVideoButton) {
            this.isShowVideoButton = true;
          }
          StoreManager.getInstance().postMessage(Action.uiStateWithMode(true, UiStateMode.EXCLUDE_PREVIEW));
          PickerUiService.getInstance().resetURIContent();
          StoreManager.getInstance().postMessage(Action.updateShowPickerView(false, true));
          this.resetPixelMap();
          this.pageInfos?.pop();
        },
        isCancelViewVisibility: true,
        keyValue: ComponentIdKeys.THIRDPARTYCALL_REMAKE_1
      });

      CircleImage({
        circleImageRes: $r('app.media.ic_camera_confirm'),
        onCircleImageClicked: () => {
          this.backCalledApp(OutputOperation.isPanPhotoOutput(this.state.mode, OutputType.NONE));
        },
        isCancelViewVisibility: true,
        keyValue: ComponentIdKeys.THIRDPARTYCALL_CONFIRM_1
      });
    }
    .width(this.getButtonRowWidth())
    .height(BUTTON_ROW_HEIGHT)
    .offset(this.getButtonRowOffset())
    .zIndex(ZIndex.TOP)
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Center }) {
        if (OutputOperation.isPanPhotoOutput(this.state.mode, OutputType.NONE)) {
          this.thumbnailBuilder();
        } else {
          this.videoBuilder();
          this.videoButtonBuilder();
        }
        this.buttonRow();
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
    .onBackPressed(() => {
      execDispatch(Action.updateShowPickerView(false, true));
      this.resetPixelMap();
      this.pageInfos?.pop();
      execDispatch(CameraAction.warmStart());
      return false;
    })
  }

  private getVideoPlayIcon(): Resource {
    if (vp2px(1) >= 1 && vp2px(1) < 2) {
      return $r('app.media.ic_video_play_btn_hdpi');
    } else if (vp2px(1) === 2) {
      return $r('app.media.ic_video_play_btn_xhdpi');
    } else if (vp2px(1) === 3) {
      return $r('app.media.ic_video_play_btn_xxhdpi');
    } else {
      return $r('app.media.ic_video_play_btn_xxxhdpi');
    }
  }

  private async resetPixelMap(): Promise<void> {
    HiLog.i(TAG, 'resetPixelMap E');
    if (this.thumbnail) {
      this.thumbnail?.release();
      HiLog.i(TAG, `resetPixelMap ${this.thumbnail}`);
    }
    HiLog.i(TAG, 'resetPixelMap X');
  }

  onPageShow(): void {
    HiLog.i(TAG, 'onPageShow.');
  }
}