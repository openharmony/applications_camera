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

import lazy { camera } from '@kit.CameraKit';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import image from '@ohos.multimedia.image';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import type { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import lazy { PositionType, ThumbnailStruct } from '@ohos/common/src/main/ets/utils/types';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { Action, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { CircleImage } from '@ohos/common/src/main/ets/component/picker/CircleImage';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { COMPONENT_WIDTH } from './LandscapeIndex';
import lazy { DirectionToAngleUtil } from '@ohos/common/src/main/ets/utils/DirectionToAngleUtil';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import lazy { ZoomOperation } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import lazy {
  DirectionCorrectionService,
  LANDSCAPE_ORIENTATION_TO_DIRECTION
} from '@ohos/common/src/main/ets/service/direction/DirectionCorrectionService';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { PickerWindowType } from '@ohos/common/src/main/ets/component/picker/PickerWindowType';
import lazy { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import display from '@ohos.display';
import lazy { VideoPlayer } from '@ohos/common/src/main/ets/component/pickerVideo/VideoPlayer';
import lazy {
  VIDEO_CONTROLLER_COMPONENT_HEIGHT
} from '@ohos/common/src/main/ets/component/pickerVideo/PickerVideoController';
import lazy { getStates, reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { PickerActionType } from '@ohos/common/src/main/ets/redux/actions/PickerActionType';
import lazy { CaptureActionType } from '@ohos/common/src/main/ets/redux/actions/CaptureActionType';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { ThumbnailActionType } from '@ohos/common/src/main/ets/redux/actions/ThumbnailActionType';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';

/* instrument ignore file */
const TAG: string = 'LandscapePickerView';
const FOOT_BAR_HEIGHT: number = 276;
const DELAY: number = 200;
const CIRCLE_IMAGE_DEF_OPACITY: number = 1.0;
const CIRCLE_IMAGE_OPACITY: number = 0.4;

class StateStruct {
  public isPhoto: boolean = true;
  public videoUri: string = '';
  public resourceUri: string = '';
}

class Dispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public updateShowPickerView(showPicker: boolean, needRestart?: boolean): void {
    this.mDispatch(Action.updateShowPickerView(showPicker, needRestart));
  }
}

@Component
export struct LandscapePickerView {
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mCallBundleName: string = '';
  private mAction: Dispatcher = new Dispatcher();
  @State state: StateStruct = new StateStruct();
  @State @Watch('uxInit') isShowSemiCollapsed: boolean = false;
  // ux位置
  @Link previewPosition: PositionType;
  @Prop buttonPosition: PositionType = { x: 0, y: 0 };
  // 录像组件
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State pixelMap: image.PixelMap | undefined = undefined;
  @State videoControllerWidth: number = 0;
  @State videoControllerOffsetY: number = 0;
  private isFlashBlackDone: boolean = false;
  private mTimer: number = Number.MIN_VALUE;
  @State videoButtonRotateAngle: number = 0;
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State uri: string = '';
  @State isShowPickerView: boolean = false;
  @State @Watch('onDirectionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State contentRotateAngle: number = 0;
  @State componentSize: Size = { width: 0, height: 0 };
  @State isLockRotation: boolean = true;
  @StorageLink('directionWhenCapture') directionWhenCapture: WindowDirection = WindowDirection.TOP;
  @StorageLink('correctedDirectionWhenCapture') correctedDirectionWhenCapture: WindowDirection = WindowDirection.TOP;
  @StorageLink('isOrientationVerticalWhenCapture') isOrientationVerticalWhenCapture: boolean = false;
  @StorageLink('pickerWindowTypeWhenCapture') pickerWindowTypeWhenCapture: PickerWindowType =
    PickerWindowType.COLLAPSED_VERTICAL_FULL;
  @StorageLink('isGeneratedContentHorizontal') isGeneratedContentHorizontal: boolean = false;
  @StorageLink('orientationWhenCapture') orientationWhenCapture: display.Orientation = display.Orientation.PORTRAIT;
  @State isShowTricollaps: boolean = false;
  private isImageConfirmClicked: boolean = false; // 当前次拉起PickerView是否点击过确认回传按钮,防止用户多次点击
  @StorageLink('isPickerVideoReady') isPickerVideoReady: boolean = false;

  aboutToAppear() {
    this.isImageConfirmClicked = false;
    PickerUiService.getInstance().setNoConfirm(true);
    this.pixelMap = PickerUiService.getInstance().getThumbnail();
    this.uri = PickerUiService.getInstance().getUri();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.videoButtonRotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.xComponentWidth = state.get<number>('previewReducer', 'xComponentWidth');
      this.xComponentHeight = state.get<number>('previewReducer', 'xComponentHeight');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      if (!this.isShowPickerView) {
        this.mDirection =
          DirectionCorrectionService.directionCorrection(state.get<WindowDirection>('contextReducer', 'direction'),
            state.get<boolean>('windowReducer', 'isLockRotation'));
      }
      this.state = {
        isPhoto: OutputOperation.isPanPhotoOutput(state.get<ModeType>('modeReducer', 'mode'), OutputType.NONE),
        videoUri: state.get<string>('recordReducer', 'videoUri'),
        resourceUri: state.get<string>('captureReducer', 'resourceUri')
      };
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowPickerView = state.get<boolean>('uiReducer', 'showPicker');
      this.isLockRotation = state.get<boolean>('windowReducer', 'isLockRotation');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    if (this.isShowPickerView) {
      if (this.isOrientationVerticalWhenCapture) {
        this.mDirection = this.pickerWindowTypeWhenCapture === PickerWindowType.EXPANDED_TOP_BOTTOM_SPLIT_SCREEN ?
          this.directionWhenCapture :
          this.correctedDirectionWhenCapture;
      } else {
        this.mDirection = WindowDirection.TOP;
      }
    }
    this.mCallBundleName = GlobalContext.get().getCameraAbilityWant()?.parameters?.callBundleName as string;
    if (!this.mCallBundleName) {
      this.mCallBundleName = GlobalContext.get().getCameraNewWant()?.parameters?.callBundleName as string;
    }
    this.mEventBus.on([PickerActionType.SHOW_PICKER_VIEW, ThumbnailActionType.RECEIVED], this.showPickerView.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.FLASH_BLACK_DONE, () => this.flashBlackDone(), this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.ON_SIZE_CHANGE, () => this.uxInit(), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.CHANGE_MODE, () => this.uxInit(), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_UPDATE_ASPECT_RATIO, () => this.uxInit(), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_BACK_PRESS, () => this.onCancelClicked(), this.mBase.hashCode());
    this.uxInit();
  }

  aboutToDisappear() {
    this.mEventBus.clear(this.mBase.hashCode());
    clearInterval(this.mTimer);
    this.mSubscriber.destroy();
    this.isImageConfirmClicked = false;
  }

  private isLandScapeAndInvert(): boolean {
    const rotation = DisplayService.getInstance().getDisplay().rotation;
    return false && rotation === display.Orientation.PORTRAIT_INVERTED &&
    this.isLockRotation;
  }

  private onDirectionChange(): void {
    if (this.isLandScapeAndInvert()) {
      this.contentRotateAngle = this.getLandInvertAngle();
    } else {
      this.contentRotateAngle = DirectionToAngleUtil.geViewRotate(this.mDirection);
    }
  }

  private getLandInvertAngle(): number {
    let angle = 0;
    switch (this.mDirection) {
      case WindowDirection.TOP:
        angle = camera.ImageRotation.ROTATION_180;
        break;
      case WindowDirection.BOTTOM:
        angle = camera.ImageRotation.ROTATION_0;
        break;
      case WindowDirection.RIGHT:
        angle = camera.ImageRotation.ROTATION_270;
        break;
      case WindowDirection.LEFT:
        angle = camera.ImageRotation.ROTATION_90;
        break;
      default:
        angle = camera.ImageRotation.ROTATION_0;
    }
    HiLog.d(TAG, `getLandInvertAngle:${angle}, direction: ${this.mDirection}`);
    return angle;
  }

  private uxInit(): void {
    this.autoResizeContent();
    this.videoControllerWidth = this.getContentWidth();
    this.videoControllerOffsetY = this.getVideoControllerOffsetY();
  }

  private isVertical(direction?: WindowDirection): boolean {
    const dir: WindowDirection = direction ?? this.mDirection;
    return dir === WindowDirection.TOP || dir === WindowDirection.BOTTOM;
  }

  private getContentWidth(): number {
    if (this.isShowSemiCollapsed) {
      return this.contentRotateAngle % 180 === 0 ? this.xComponentWidth : this.xComponentHeight;
    }
    return this.isVertical() ? this.componentSize.width : this.componentSize.height;
  }

  private getContentHeight(): number {
    if (this.isShowSemiCollapsed) {
      return this.contentRotateAngle % 180 === 0 ? this.xComponentHeight : this.xComponentWidth;
    }
    return this.isVertical() ? this.componentSize.height : this.componentSize.width;
  }

  private flashBlackDone(): void {
    this.isFlashBlackDone = true;
  }

  private autoResizeContent(): void {
    let width: number = this.windowWidth;
    let height: number = this.windowHeight;
    if (this.isShowPickerView) {
      this.componentSize =
        CameraBasicService.getInstance().getPreviewDisplaySize(undefined, width, height,
          this.isOrientationVerticalWhenCapture);
    } else {
      this.componentSize =
        CameraBasicService.getInstance().getPreviewDisplaySize(undefined, width, height);
    }
  }

  private resetPixelMap(): void {
    HiLog.i(TAG, 'resetPixelMap E');
    if (this.pixelMap) {
      this.pixelMap?.release?.();
      HiLog.i(TAG, `resetPixelMap ${this.pixelMap}`);
    }
    HiLog.i(TAG, 'resetPixelMap X');
  }

  private showPickerView(data: ThumbnailStruct): void {
    PickerUiService.getInstance().saveUriAndThumbnail(data?.thumbnail);
    this.uri = PickerUiService.getInstance().getUri();
    this.getPixelMap();
    this.updateCommunicationData();
    this.videoControllerWidth = this.getContentWidth();
    this.videoControllerOffsetY = this.getVideoControllerOffsetY();
    if (this.isFlashBlackDone || !this.state.isPhoto) {
      this.mAction.updateShowPickerView(true);
      this.isFlashBlackDone = false;
    } else {
      this.delayOpen();
    }
  }

  private getPixelMap(): void {
    this.pixelMap = PickerUiService.getInstance().getThumbnail();
  }

  private updateCommunicationData(): void {
    // 开合体验，PickerView与LandscapePickerView之间通信数据
    this.orientationWhenCapture = DisplayService.getInstance().getDisplay().orientation;
    this.isOrientationVerticalWhenCapture = DisplayService.getInstance().isOrientationVertical();
    if (this.isShowTricollaps) {
      this.isOrientationVerticalWhenCapture = !this.isOrientationVerticalWhenCapture;
    }
    if (this.isLockRotation) {
      this.directionWhenCapture = getStates().get<WindowDirection>('contextReducer', 'direction');
    } else {
      this.directionWhenCapture =
        LANDSCAPE_ORIENTATION_TO_DIRECTION[DisplayService.getInstance().getDisplay().orientation];
    }
    this.correctedDirectionWhenCapture = this.mDirection;
    this.pickerWindowTypeWhenCapture = PickerWindowType.EXPANDED_LEFT_RIGHT_SPLIT_SCREEN;
    this.isGeneratedContentHorizontal = PickerUtils.isGeneratedContentHorizontal(this.isOrientationVerticalWhenCapture,
      this.isVertical(this.directionWhenCapture));
  }

  private getContentPosition(): PositionType {
    if (this.isShowSemiCollapsed) {
      const width = getStates().get<number>('windowReducer', 'windowWidth');
      const height = getStates().get<number>('windowReducer', 'windowHeight');
      return {
        x: width / 2,
        y: (height - this.xComponentHeight) >> 1
      }
    }
    let outputPos: PositionType = { x: this.previewPosition.x, y: this.previewPosition.y }
    if (PickerUtils.getIsPicker() && this.isShowTricollaps) {
      outputPos.x = (WindowService.getInstance().getWindowAndXComDiffer(this.windowWidth, this.getContentWidth())) >> 1;
      outputPos.y =
        (WindowService.getInstance().getWindowAndXComDiffer(this.windowHeight, this.getContentHeight())) >> 1;
    } else {
      if (this.isOrientationVerticalWhenCapture && !DisplayService.getInstance().isOrientationVertical()) {
        outputPos.x = (this.windowWidth - COMPONENT_WIDTH - this.getContentWidth()) / 2;
        outputPos.y = this.contentRotateAngle % 360 !== 0 ? (this.getContentWidth() - this.getContentHeight()) / 2 : 0;
      } else if (!this.isOrientationVerticalWhenCapture && DisplayService.getInstance().isOrientationVertical()) {
        outputPos.x = 0;
        outputPos.y = this.contentRotateAngle % 360 !== 0 ? (this.windowHeight - this.getContentWidth()) / 2 :
          (this.windowHeight - this.getContentHeight()) / 2;
      } else if (this.isLandScapeAndInvert()) {
        if (this.mDirection === WindowDirection.RIGHT) {
          outputPos.y += (this.xComponentHeight - this.xComponentWidth);
        }
      } else if (this.mDirection === WindowDirection.LEFT) {
        outputPos.y += (this.xComponentHeight - this.xComponentWidth);
      }
    }
    return outputPos;
  }

  private getRotateCenterX(): number | undefined {
    if (this.isShowTricollaps) {
      return undefined;
    }
    if (this.isOrientationVerticalWhenCapture && !DisplayService.getInstance().isOrientationVertical() &&
      this.contentRotateAngle % 360 !== 0) {
      return this.getContentWidth() / 2;
    }
    if (!this.isOrientationVerticalWhenCapture) {
      return DisplayService.getInstance().isOrientationVertical() ? undefined :
        this.isVertical() ? undefined : this.getContentHeight() / 2;
    }
    return Math.min(this.getContentWidth(), this.getContentHeight()) / 2;
  }

  private getRotateCenterY(): number | undefined {
    if (this.isShowTricollaps) {
      return undefined;
    }
    if (!this.isOrientationVerticalWhenCapture) {
      return DisplayService.getInstance().isOrientationVertical() ? this.getContentWidth() / 2 : undefined;
    }
    return undefined;
  }

  private getVideoControllerOffsetY(): number {
    if (this.isShowSemiCollapsed) {
      return this.getContentHeight() / 2 - VIDEO_CONTROLLER_COMPONENT_HEIGHT / 2 + this.windowWidth / 2 - 90;
    }
    return this.getContentWidth() < this.getContentHeight() ?
      this.getContentHeight() / 2 - 60 - VIDEO_CONTROLLER_COMPONENT_HEIGHT / 2 :
      this.getContentHeight() / 2 - 12 - VIDEO_CONTROLLER_COMPONENT_HEIGHT / 2;
  }

  build() {
    Stack() {
      if (this.state.isPhoto) {
        Image(this.pixelMap)
          .width(this.getContentWidth())
          .height(this.getContentHeight())
          .rotate({
            angle: this.contentRotateAngle,
            centerX: this.getRotateCenterX(),
            centerY: this.getRotateCenterY()
          })
          .objectFit(ImageFit.Contain)
          .position(this.getContentPosition())
          .draggable(false)
          .syncLoad(true)
      } else {
        if (this.isShowPickerView) {
          this.VideoComponent();
        }
      }
      this.ButtonComponent();
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }

  @Builder
  VideoComponent() {
    VideoPlayer({
      uri: this.uri,
      previewPixelMap: this.pixelMap,
      videoControllerOffsetFromCenter: {
        y: this.videoControllerOffsetY
      },
      videoControllerWidth: this.videoControllerWidth,
    })
      .width(this.getContentWidth())
      .height(this.getContentHeight())
      .rotate({ angle: this.contentRotateAngle, centerX: this.getRotateCenterX(), centerY: this.getRotateCenterY() })
      .position(this.getContentPosition())
  }

  private async onConfirmClicked(): Promise<void> {
    HiLog.i(TAG, 'Confirm button clicked.');
    if (!getStates().get<boolean>('uiReducer', 'showPicker')) {
      HiLog.i(TAG, 'hidden PickerView: showPicker=false');
      return;
    }
    if (this.isImageConfirmClicked) {
      HiLog.i(TAG, 'isImageConfirmClicked=true');
      return;
    }
    this.isImageConfirmClicked = true;
    const uri = this.state.isPhoto ? this.state.resourceUri : this.state.videoUri;
    HiLog.i(TAG, `this.state.isPhoto: ${this.state.isPhoto}`);
    await PickerUiService.getInstance().backAfterCapture(this.state.isPhoto, uri,
      this.mCallBundleName);
  }

  private onCancelClicked(): void {
    HiLog.i(TAG, 'Cancel button clicked.');
    ZoomOperation.getInstance().setRemainZoomRatio(true);
    StoreManager.getInstance().postMessage(Action.updateShowPickerView(false, true));
    StoreManager.getInstance().postMessage(Action.pickerRemake());
    StoreManager.getInstance().postMessage(Action.uiStateWithMode(true, UiStateMode.EXCLUDE_PREVIEW));
    this.uxInit();
    PickerUiService.getInstance().resetURIContent();
    this.isPickerVideoReady = false;
    PickerUiService.getInstance().setVideoTimeBeforeCollapsing(0);
    this.resetPixelMap();
  }

  private isConfirmButtonEnabled(): boolean {
    return this.state.isPhoto || this.isPickerVideoReady;
  }

  @Builder
  ButtonComponent() {
    Flex({
      direction: this.isShowSemiCollapsed ? FlexDirection.RowReverse : FlexDirection.Column,
      alignItems: ItemAlign.Center,
      justifyContent: FlexAlign.SpaceBetween
    }) {
      CircleImage({
        circleImageRes: $r('app.media.ic_camera_confirm'),
        onCircleImageClicked: (): void => {
          this.onConfirmClicked();
        },
        isCancelViewVisibility: true,
        keyValue: ComponentIdKeys.THIRDPARTYCALL_CONFIRM_1,
        abText: $r('sys.string.icon_save')
      })
        .enabled(this.isConfirmButtonEnabled())
        .opacity(this.isConfirmButtonEnabled() ? CIRCLE_IMAGE_DEF_OPACITY : CIRCLE_IMAGE_OPACITY)
      CircleImage({
        circleImageRes: $r('app.media.ic_camera_cancel'),
        onCircleImageClicked: async () => {
          this.onCancelClicked();
        },
        isCancelViewVisibility: true,
        keyValue: ComponentIdKeys.THIRDPARTYCALL_REMAKE_1,
        abText: $r('sys.string.icon_cancel')
      })
    }
    .width(this.isShowSemiCollapsed ? FOOT_BAR_HEIGHT : COMPONENT_WIDTH)
    .height(this.isShowSemiCollapsed ? COMPONENT_WIDTH : FOOT_BAR_HEIGHT)
    .position(this.buttonPosition)
  }

  delayOpen(): void {
    this.mTimer = setInterval(() => {
      if (this.isFlashBlackDone || !this.state.isPhoto) {
        this.mAction.updateShowPickerView(true);
        this.isFlashBlackDone = false;
        clearInterval(this.mTimer);
      }
    }, DELAY);
  }
}