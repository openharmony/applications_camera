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

import image from '@ohos.multimedia.image';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import type { Unsubscribe } from '@ohos/common/src/main/ets/redux';
import { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import { PositionType, ThumbnailStruct } from '@ohos/common/src/main/ets/utils/types';
import { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import { Action, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { DirectionToAngleUtil } from '@ohos/common/src/main/ets/utils/DirectionToAngleUtil';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { CircleImage } from '@ohos/common/src/main/ets/component/picker/CircleImage';
import {
  FOOT_BAR_HEIGHT,
  MODE_BAR_HEIGHT
} from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService';
import { COMPONENT_WIDTH } from './DefaultIndex';
import { ZoomOperation } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import camera from '@ohos.multimedia.camera';
import display from '@ohos.display';
import { DirectionCorrectionService } from '@ohos/common/src/main/ets/service/direction/DirectionCorrectionService';
import { ConflictManager } from '@ohos/common/src/main/ets/function/core/ConflictManager';
import { PickerWindowType } from '@ohos/common/src/main/ets/component/picker/PickerWindowType';
import { VideoPlayer } from '@ohos/common/src/main/ets/component/pickerVideo/VideoPlayer';
import {
  VIDEO_CONTROLLER_COMPONENT_HEIGHT
} from '@ohos/common/src/main/ets/component/pickerVideo/PickerVideoController';
import { getStates, reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import { PickerActionType } from '@ohos/common/src/main/ets/redux/actions/PickerActionType';
import { ThumbnailActionType } from '@ohos/common/src/main/ets/redux/actions/ThumbnailActionType';
import { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';

const TAG: string = 'PickerView';
const BUTTON_MARGIN: number = 30;

class StateStruct {
  public isPhoto: boolean = true;
  public videoUri: string = '';
  public resourceUri: string = '';
  public xComponentWidth: number = 0;
  public xComponentHeight: number = 0;
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
export struct PickerView {
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mCallBundleName: string = '';
  private mAction: Dispatcher = new Dispatcher();
  @State state: StateStruct = new StateStruct();
  // ux位置
  @Link previewPosition: PositionType;
  // 录像组件
  @State videoControllerWidth: number = 0;
  @State videoControllerOffsetY: number = 0;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State pixelMap: image.PixelMap | undefined = undefined;
  @Prop buttonPosition: PositionType = { x: 0, y: 0 };
  @State uri: string = '';
  @State isShowPickerView: boolean = false;
  @State isLockRotation: boolean = true;
  @State @Watch('onDirectionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State videoButtonRotateAngle: number = 0;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  @State pickerWindowType: PickerWindowType = PickerWindowType.TABLET_FULL_SCREEN;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State contentRotateAngle: number = 0;
  @State componentSize: Size = { width: 0, height: 0 };
  @State isOrientationVerticalWhenCapture: boolean = false;
  @State directionWhenCapture: WindowDirection = WindowDirection.TOP;
  private static readonly ZOOM_RATIO_2: number = 2;
  private mConflictManager: ConflictManager = ConflictManager.getInstance();
  private isImageConfirmClicked: boolean = false; // 当前次拉起PickerView是否点击过确认回传按钮,防止用户多次点击
  @StorageLink('isPickerVideoReady') isPickerVideoReady: boolean = false;

  aboutToAppear() {
    this.isImageConfirmClicked = false;
    this.pixelMap = PickerUiService.getInstance().getThumbnail();
    this.uri = PickerUiService.getInstance().getUri();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.state = {
        isPhoto: OutputOperation.isPanPhotoOutput(state.get<ModeType>('modeReducer', 'mode'), OutputType.NONE),
        videoUri: state.get<string>('recordReducer', 'videoUri'),
        resourceUri: state.get<string>('captureReducer', 'resourceUri'),
        xComponentWidth: state.get<number>('previewReducer', 'xComponentWidth'),
        xComponentHeight: state.get<number>('previewReducer', 'xComponentHeight'),
      };
      this.isShowPickerView = state.get<boolean>('uiReducer', 'showPicker');
      // isLockRotation更新需要在directionCorrection之前
      this.isLockRotation = state.get<boolean>('windowReducer', 'isLockRotation');
      if (!this.isShowPickerView) {
        this.mDirection = DirectionCorrectionService.directionCorrection(state.get<WindowDirection>('contextReducer', 'direction'),
          state.get<boolean>('windowReducer', 'isLockRotation'));
      }
      this.videoButtonRotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.pickerWindowType = state.get<PickerWindowType>('windowReducer', 'pickerWindowType');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.mCallBundleName = GlobalContext.get().getCameraAbilityWant()?.parameters?.callBundleName as string;
    if (!this.mCallBundleName) {
      this.mCallBundleName = GlobalContext.get().getCameraNewWant()?.parameters?.callBundleName as string;
    }
    this.mEventBus.on([PickerActionType.SHOW_PICKER_VIEW, ThumbnailActionType.RECEIVED], this.showPickerView.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([WindowActionType.ON_SIZE_CHANGE, ActionType.ACTION_UPDATE_ASPECT_RATIO,
      CameraActionType.CHANGE_MODE], () => this.uxInit(), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_BACK_PRESS, () => this.onCancelClicked(), this.mBase.hashCode());
    this.uxInit();
  }

  aboutToDisappear() {
    HiLog.i(TAG, 'aboutToDisappear called!');
    this.mSubscriber.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
    this.isImageConfirmClicked = false;
  }

  private resetPixelMap(): void {
    HiLog.i(TAG, 'resetPixelMap E');
    if (this.pixelMap) {
      this.pixelMap?.release?.();
      HiLog.i(TAG, `resetPixelMap ${this.pixelMap}`);
    }
    HiLog.i(TAG, 'resetPixelMap X');
  }

  private onDirectionChange(): void {
    this.contentRotateAngle = DirectionToAngleUtil.geViewRotate(this.mDirection);
  }

  private showPickerView(data: ThumbnailStruct): void {
    PickerUiService.getInstance().saveUriAndThumbnail(data?.thumbnail);
    this.uri = PickerUiService.getInstance().getUri();
    this.getPixelMap();
    this.isOrientationVerticalWhenCapture = DisplayService.getInstance().isOrientationVertical();
    this.directionWhenCapture = this.mDirection;
    this.videoControllerOffsetY = this.getVideoControllerOffsetY();
    this.mAction.updateShowPickerView(true);
  }

  private getPixelMap(): void {
    this.pixelMap = PickerUiService.getInstance().getThumbnail();
    if (this.state.isPhoto) {
      return;
    }
    const orientation: display.Orientation = DisplayService.getInstance().getDisplay().orientation;
    const cameraPosition: camera.CameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    const isFrontCamera: boolean = cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT;
    const direction: WindowDirection = getStates().get<WindowDirection>('contextReducer', 'direction');
    HiLog.i(TAG, `isLockRotation:${this.isLockRotation},orientation:${orientation},direction:${direction}`);
    if (this.isLockRotation) {
      if (this.mDirection === WindowDirection.LEFT) {
        this.pixelMap.rotateSync(isFrontCamera ? -90 : 90);
      }
      if (this.mDirection === WindowDirection.RIGHT) {
        this.pixelMap.rotateSync(isFrontCamera ? 90 : -90);
      }
      if (this.mDirection === WindowDirection.BOTTOM) {
        this.pixelMap.rotateSync(180);
      }
      return;
    }
    if (!DisplayService.getInstance().isOrientationVertical()) {
      return;
    }
    if (!this.isLockRotation && orientation === display.Orientation.PORTRAIT_INVERTED) {
      this.pixelMap.rotateSync(180);
      return;
    }
    if (this.isLockRotation && orientation === display.Orientation.PORTRAIT_INVERTED) {
      this.pixelMap.rotateSync(isFrontCamera ? 90 : -90);
    }
  }

  private uxInit(): void {
    this.autoResizeContent();
    this.videoControllerWidth = this.getContentWidth();
    this.videoControllerOffsetY = this.getVideoControllerOffsetY();
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

  private isVertical(direction?: WindowDirection): boolean {
    const dir: WindowDirection = direction ?? this.mDirection;
    return dir === WindowDirection.TOP || dir === WindowDirection.BOTTOM;
  }

  private getContentWidth(): number {
    return this.isVertical() ? this.componentSize.width : this.componentSize.height;
  }

  private getContentHeight(): number {
    return this.isVertical() ? this.componentSize.height : this.componentSize.width;
  }

  private getContentPosition(): PositionType {
    let outputPos: PositionType = { x: this.previewPosition.x, y: this.previewPosition.y }
    if (this.isOrientationVerticalWhenCapture && !DisplayService.getInstance().isOrientationVertical()) {
      outputPos.x = (this.windowWidth - COMPONENT_WIDTH - this.getContentWidth()) / 2;
      outputPos.y = this.contentRotateAngle % 360 !== 0 ? (this.getContentWidth() - this.getContentHeight()) / 2 : 0;
    } else if (!this.isOrientationVerticalWhenCapture && DisplayService.getInstance().isOrientationVertical()) {
      outputPos.x = 0;
      outputPos.y = this.contentRotateAngle % 360 !== 0 ? (this.windowHeight - this.getContentWidth()) / 2 :
        (this.windowHeight - this.getContentHeight()) / 2;
    } else if (this.mDirection === WindowDirection.LEFT) {
      outputPos.y += (this.state.xComponentHeight - this.state.xComponentWidth);
    }
    return outputPos;
  }

  private getImageOffsetY(): number {
    if (this.mDirection === WindowDirection.LEFT) {
      const baseOffset: number = this.getContentWidth() - this.getContentHeight();
      return baseOffset;
    }
    return 0;
  }

  private getRotateCenterX(): number | undefined {
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
    if (!this.isOrientationVerticalWhenCapture) {
      return DisplayService.getInstance().isOrientationVertical() ? this.getContentWidth() / 2 : undefined;
    }
    return undefined;
  }

  private getVideoControllerOffsetY(): number {
    if (this.isOrientationVerticalWhenCapture && this.isVertical(this.directionWhenCapture) ||
      !this.isOrientationVerticalWhenCapture && !this.isVertical(this.directionWhenCapture)) {
      return this.getContentHeight() / 2 - 145 - VIDEO_CONTROLLER_COMPONENT_HEIGHT / 2;
    } else {
      return this.getContentHeight() / 2 - 60 - VIDEO_CONTROLLER_COMPONENT_HEIGHT / 2;
    }
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
    const showPickerUi = getStates().get<boolean>('uiReducer', 'showPicker');
    const hasCaptured = !!(this.state.resourceUri || this.state.videoUri ||
    PickerUiService.getInstance().getUri());
    if (!showPickerUi && !(GlobalContext.get().getIsPicker() && hasCaptured)) {
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
    StoreManager.getInstance().postMessage(Action.uiStateWithMode(true, UiStateMode.EXCLUDE_PREVIEW));
    PickerUiService.getInstance().resetURIContent();
    this.isPickerVideoReady = false;
    PickerUiService.getInstance().setVideoTimeBeforeCollapsing(0);
    this.uxInit();
    this.resetPixelMap();
  }

  @Builder
  ButtonComponent() {
    Flex({
      direction: FlexDirection.Column,
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
        .margin({ top: this.getMargin() })

      CircleImage({
        circleImageRes: $r('app.media.ic_camera_cancel'),
        onCircleImageClicked: async () => {
          this.onCancelClicked();
        },
        isCancelViewVisibility: true,
        keyValue: ComponentIdKeys.THIRDPARTYCALL_REMAKE_1,
        abText: $r('sys.string.icon_cancel')
      })
        .margin({ bottom: this.getMargin() })
    }
    .width(COMPONENT_WIDTH)
    .height(this.getFootBarHeight())
    .position(this.buttonPosition)
    .zIndex(ZIndex.TOP)
  }

  private getMargin(): number {
    const circleImageSize: number = 44;
    const shutterButtonSize: number = 64;
    let marginShutterButton: number = 0;
    if (this.pickerWindowType === PickerWindowType.TABLET_TOP_BOTTOM_HALF_SPLIT_SCREEN) {
      marginShutterButton = 0.05 * this.windowHeight;
    } else if (this.pickerWindowType === PickerWindowType.TABLET_FULL_SCREEN &&
    DisplayService.getInstance().isOrientationVertical()) {
      marginShutterButton = 74;
    } else {
      marginShutterButton =
        this.pickerWindowType === PickerWindowType.TABLET_1_3_SPLIT_SCREEN ? 32 : 0.1 * this.windowHeight;
    }
    return (this.getFootBarHeight() - circleImageSize * 2 - shutterButtonSize - marginShutterButton * 2) / 2;
  }

  private getFootBarHeight(): number {
    if (this.pickerWindowType === PickerWindowType.TABLET_1_3_SPLIT_SCREEN) {
      if (FOOT_BAR_HEIGHT > this.windowHeight) {
        return this.windowHeight;
      } else {
        return FOOT_BAR_HEIGHT;
      }
    }
    if (this.windowHeight - FOOT_BAR_HEIGHT > 0.1 * this.windowHeight) {
      return FOOT_BAR_HEIGHT;
    }
    return this.windowHeight - MODE_BAR_HEIGHT + 24;
  }
}