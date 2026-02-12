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

import fileIo from '@ohos.fileio';
import image from '@ohos.multimedia.image';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { Action, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { CircleImage } from '@ohos/common/src/main/ets/component/picker/CircleImage';
import lazy { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import type { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { Unsubscribe } from '@ohos/common/src/main/ets/redux';
import lazy {
  FOOT_BAR_HEIGHT,
  TAB_BAR_HEIGHT
} from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLayoutService';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import camera from '@ohos.multimedia.camera';
import lazy { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { ThumbnailStruct } from '@ohos/common/src/main/ets/utils/types';
import lazy { ZoomOperation } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy {
  PICKER_HORIZONTAL_LAYOUT,
  PICKER_VERTICAL_LAYOUT,
  PickerUtils
} from '@ohos/common/src/main/ets/utils/PickerUtils';
import display from '@ohos.display';
import lazy {
  DirectionCorrectionService,
  HORIZONTAL_PREVIEW_DIRECTION_CORRECTION_ARR
} from '@ohos/common/src/main/ets/service/direction/DirectionCorrectionService';
import lazy { PickerWindowType } from '@ohos/common/src/main/ets/component/picker/PickerWindowType';
import lazy { DisplayCalculator } from '@ohos/common/src/main/ets/component/xcomponent/DisplayCalculator';
import lazy { VideoPlayer } from '@ohos/common/src/main/ets/component/pickerVideo/VideoPlayer';
import lazy {
  VIDEO_CONTROLLER_COMPONENT_HEIGHT
} from '@ohos/common/src/main/ets/component/pickerVideo/PickerVideoController';
import lazy { getStates, reduxSubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { PickerActionType } from '@ohos/common/src/main/ets/redux/actions/PickerActionType';
import lazy { ThumbnailActionType } from '@ohos/common/src/main/ets/redux/actions/ThumbnailActionType';
import lazy { CaptureActionType } from '@ohos/common/src/main/ets/redux/actions/CaptureActionType';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import lazy { RecordActionType } from '@ohos/common/src/main/ets/redux/actions/RecordActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import window from '@ohos.window';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';

/* instrument ignore file */
const TAG: string = 'PickerView';
const DELAY: number = 200;
const BUTTON_VIEW_HEIGHT = 72;
const ROTATE_ANGLE_90: number = 90;
const ROTATE_ANGLE_NEG_90: number = -90;
const ROTATE_ANGLE_180: number = 180;
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
export struct PickerView {
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mCallBundleName: string = '';
  private mAction: Dispatcher = new Dispatcher();
  @State state: StateStruct = new StateStruct();
  // 录像组件
  @State showControlsBar: boolean = false;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  // 自拍镜像关闭的时候图片内容和拍照内容是镜像的  所以当用户点击关闭自拍镜像弹框按钮的时候 图片需要作镜像处理
  @State contentRotateAngle: number = 0;
  @State videoButtonRotateAngle: number = 0;
  @State pixelMap: image.PixelMap | undefined = undefined;
  @State videoControllerWidth: number = 0;
  @State videoControllerOffsetY: number = 0;
  @State contentPosition: number = 0;
  @State isLockRotation: boolean = true;
  @State @Watch('uxInit') mDirection: WindowDirection = WindowDirection.TOP;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  @State isPickerTopBottomSplitScreenVertical: boolean = false;
  @State isPickerLeftRightSplitScreenHorizontal: boolean = false;
  @State isPickerCollapsedHorizontalSplitScreen: boolean = false;
  @State contentSize: Size = { width: 0, height: 0 };
  @State pickerWindowType: PickerWindowType = PickerWindowType.COLLAPSED_VERTICAL_FULL;
  @State isVdeCollapsed: boolean = false;
  private isFlashBlackDone: boolean = false;
  private mTimer: number = Number.MIN_VALUE;
  private componentSize4To3: Size = { width: 0, height: 0 };
  @Prop @Watch('getViewCenterPosition') tabBarPosition: number = 0;
  @Prop @Watch('getViewCenterPosition') footBarPosition: number = 0;
  @Prop @Watch('getViewCenterPosition') previewPosition: number = 0;
  @Prop modeBarPosition: number = 0;
  @State uri: string = '';
  @State showPicker: boolean = false;
  @StorageLink('directionWhenCapture') directionWhenCapture: WindowDirection = WindowDirection.TOP;
  @StorageLink('correctedDirectionWhenCapture') correctedDirectionWhenCapture: WindowDirection = WindowDirection.TOP;
  @StorageLink('isOrientationVerticalWhenCapture') isOrientationVerticalWhenCapture: boolean = false;
  @StorageLink('pickerWindowTypeWhenCapture') pickerWindowTypeWhenCapture: PickerWindowType =
    PickerWindowType.COLLAPSED_VERTICAL_FULL;
  @StorageLink('isGeneratedContentHorizontal') isGeneratedContentHorizontal: boolean = false;
  @StorageLink('orientationWhenCapture') orientationWhenCapture: display.Orientation = display.Orientation.PORTRAIT;
  @StorageLink('isPickerVideoReady') isPickerVideoReady: boolean = false;
  private isImageConfirmClicked: boolean = false; // 当前次拉起PickerView是否点击过确认回传按钮,防止用户多次点击
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;

  aboutToAppear() {
    this.isImageConfirmClicked = false;
    PickerUiService.getInstance().setNoConfirm(true);
    this.pixelMap = PickerUiService.getInstance().getThumbnail();
    this.uri = PickerUiService.getInstance().getUri();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.state = {
        isPhoto: OutputOperation.isPanPhotoOutput(state.get<ModeType>('modeReducer', 'mode')),
        videoUri: state.get<string>('recordReducer', 'videoUri'),
        resourceUri: state.get<string>('captureReducer', 'resourceUri'),
      };
      this.showPicker = state.get<boolean>('uiReducer', 'showPicker');
      this.videoButtonRotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.isLockRotation = state.get<boolean>('windowReducer', 'isLockRotation');
      this.pickerWindowType = state.get<PickerWindowType>('windowReducer', 'pickerWindowType');
      if (!this.showPicker &&
        getStates().get<RecordingState>('recordReducer', 'recordingState') === RecordingState.READY) {
        this.mDirection =
          DirectionCorrectionService.directionCorrection(state.get<WindowDirection>('contextReducer', 'direction'),
            state.get<boolean>('windowReducer', 'isLockRotation'));
      }
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    if (this.showPicker) {
      this.mDirection = this.directionWhenCapture;
    }
    this.mCallBundleName = GlobalContext.get().getCameraAbilityWant()?.parameters?.callBundleName as string;
    if (!this.mCallBundleName) {
      this.mCallBundleName = GlobalContext.get().getCameraNewWant()?.parameters?.callBundleName as string;
    }
    HiLog.i(TAG, `aboutToAppear E pixelMap: ${this.pixelMap}`);
    this.mEventBus.on([PickerActionType.SHOW_PICKER_VIEW, ThumbnailActionType.RECEIVED], this.showPickerView.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.FLASH_BLACK_DONE,
      () => this.flashBlackDone(), this.mBase.hashCode());
    this.mEventBus.on([WindowActionType.ON_SIZE_CHANGE, ActionType.ACTION_CHANGE_X_COMPONENT_SIZE],
      () => this.uxInit(), this.mBase.hashCode());
    this.mEventBus.on([CaptureActionType.CAPTURE, RecordActionType.START, CameraActionType.CHANGE_MODE],
      () => this.uxInit(), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_BACK_PRESS, () => this.onCancelClicked(), this.mBase.hashCode());
    if (this.showPicker) {
      this.uxInit();
    }
  }

  aboutToDisappear() {
    HiLog.i(TAG, 'aboutToDisappear called!');
    this.mEventBus.clear(this.mBase.hashCode());
    clearInterval(this.mTimer);
    this.mSubscriber.destroy();
    this.isImageConfirmClicked = false;
  }

  private uxInit(): void {
    this.isPickerTopBottomSplitScreenVertical = PickerUtils.getIsExpandedTopBottomVertical();
    this.updateCommunicationData();
    this.autoResizeContent();
    this.getViewCenterPosition();
    this.updateDirection();
    this.updateContentRotateAngle();
    this.videoControllerWidth = this.getContentWidth();
    this.videoControllerOffsetY = this.getVideoControllerOffsetY();
  }

  private isNeedRotate(): boolean {
    return Math.ceil(this.getContentWidth4To3()) !== this.windowWidth &&
      Math.ceil(this.getContentHeight4To3()) !== this.windowHeight;
  }

  private updateDirection(): void {
    if (this.showPicker && !PickerUtils.getIsCollapsedHorizontalFullScreenFromReducer()) {
      let inputDirection: WindowDirection = this.directionWhenCapture;
      if (PickerUtils.getIsExpandedTopBottomSplitScreenFromReducer() &&
        this.pickerWindowTypeWhenCapture === PickerWindowType.EXPANDED_LEFT_RIGHT_SPLIT_SCREEN) {
        this.mDirection =
          HORIZONTAL_PREVIEW_DIRECTION_CORRECTION_ARR[this.orientationWhenCapture][this.directionWhenCapture];
        return;
      }
      this.mDirection = this.isPickerWindowTypeSame() ? this.correctedDirectionWhenCapture :
        DirectionCorrectionService.directionCorrection(inputDirection, this.isLockRotation);
    } else {
      this.mDirection =
        DirectionCorrectionService.directionCorrection(getStates().get<WindowDirection>('contextReducer', 'direction'),
          this.isLockRotation);
    }
  }

  private updateContentRotateAngle(): void {
    if (this.isOrientationVerticalWhenCapture && this.isGeneratedContentHorizontal &&
    PickerUtils.getIsCollapsedHorizontalFullScreenFromReducer() &&
      DisplayService.getInstance().getDisplay().orientation === display.Orientation.LANDSCAPE) {
      this.contentRotateAngle = ROTATE_ANGLE_180;
      HiLog.i(TAG, 'updateContentRotateAngle return 180');
      return;
    }
    if (this.isNeedRotate()) {
      this.contentRotateAngle = this.mDirection === WindowDirection.RIGHT ? ROTATE_ANGLE_90 : ROTATE_ANGLE_NEG_90;
    } else {
      this.contentRotateAngle = 0;
    }
    HiLog.i(TAG, `updateContentRotateAngle contentRotateAngle: ${this.contentRotateAngle}`);
  }

  private isPickerWindowTypeSame(): boolean {
    const isSameVertical: boolean = PICKER_VERTICAL_LAYOUT.includes(this.pickerWindowType) &&
    PICKER_VERTICAL_LAYOUT.includes(this.pickerWindowTypeWhenCapture);
    const isSameHorizontal: boolean = PICKER_HORIZONTAL_LAYOUT.includes(this.pickerWindowType) &&
    PICKER_HORIZONTAL_LAYOUT.includes(this.pickerWindowTypeWhenCapture);
    return isSameVertical || isSameHorizontal;
  }

  private getIsLayoutVertical(): boolean {
    return DisplayService.getInstance().isOrientationVertical() ||
    PickerUtils.getIsExpandedLeftRightSplitScreenFromReducer();
  }

  private getIsLayoutHorizontal(): boolean {
    return !DisplayService.getInstance().isOrientationVertical() ||
    PickerUtils.getIsExpandedTopBottomSplitScreenFromReducer();
  }

  private autoResizeContent(): void {
    let width: number = this.windowWidth;
    let height: number = this.windowHeight;
    if (this.showPicker) {
      this.componentSize4To3 =
        DisplayCalculator.calcSurfaceDisplaySize(4 / 3, width, height, this.isOrientationVerticalWhenCapture);
      this.contentSize =
        CameraBasicService.getInstance()
          .getPreviewDisplaySize(undefined, width, height, this.isOrientationVerticalWhenCapture);
    } else {
      this.componentSize4To3 =
        DisplayCalculator.calcSurfaceDisplaySize(4 / 3, width, height);
      this.contentSize =
        CameraBasicService.getInstance().getPreviewDisplaySize(undefined, width, height);
    }
  }

  private getViewCenterPosition(): void { // 横竖屏拍摄，照片位置计算
    let height: number = this.getContentHeight();
    if (this.getIsLayoutVertical()) {
      height =
        this.isOrientationVerticalWhenCapture ? Math.max(this.contentSize.width, this.contentSize.height) :
          Math.min(this.contentSize.width, this.contentSize.height);
    }
    if (this.getIsLayoutHorizontal()) {
      height =
        this.isOrientationVerticalWhenCapture ? Math.min(this.contentSize.width, this.contentSize.height) :
          Math.max(this.contentSize.width, this.contentSize.height);
    }
    this.contentPosition = Math.max(Math.round(this.footBarPosition / 2 + this.tabBarPosition / 2 +
      TAB_BAR_HEIGHT / 2 - height / 2), this.previewPosition);
    if (this.contentPosition + height > this.windowHeight) {
      this.contentPosition = (this.windowHeight - height) / 2;
    }
    HiLog.i(TAG, `getViewCenterPosition-${this.contentPosition}`);
  }

  private getContentWidth4To3(): number {
    return this.isGeneratedContentHorizontal ? Math.max(this.componentSize4To3.width, this.componentSize4To3.height) :
      Math.min(this.componentSize4To3.width, this.componentSize4To3.height);
  }

  private getContentHeight4To3(): number {
    return this.isGeneratedContentHorizontal ? Math.min(this.componentSize4To3.width, this.componentSize4To3.height) :
      Math.max(this.componentSize4To3.width, this.componentSize4To3.height);
  }

  private getContentWidth(): number {
    if (this.isVdeCollapsed) {
      return this.windowWidth;
    }
    return this.isGeneratedContentHorizontal ? Math.max(this.contentSize.width, this.contentSize.height) :
      Math.min(this.contentSize.width, this.contentSize.height);
  }

  private getContentHeight(): number {
    if (this.isVdeCollapsed) {
      return this.windowHeight;
    }
    return this.isGeneratedContentHorizontal ? Math.min(this.contentSize.width, this.contentSize.height) :
      Math.max(this.contentSize.width, this.contentSize.height);
  }

  private flashBlackDone(): void {
    this.isFlashBlackDone = true;
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
    HiLog.i(TAG, `showPickerView.`);
    PickerUiService.getInstance().saveUriAndThumbnail(data?.thumbnail);
    this.getPixelMap();
    this.uri = PickerUiService.getInstance().getUri();
    this.isFlashBlackDone = true;
    if (this.isFlashBlackDone || !this.state.isPhoto) {
      this.mAction.updateShowPickerView(true);
      this.isFlashBlackDone = false;
    } else {
      this.delayOpen();
    }
  }

  private updateCommunicationData(): void {
    // 开合体验，PickerView与LandscapePickerView之间通信数据
    this.orientationWhenCapture = DisplayService.getInstance().getDisplay().orientation;
    this.isOrientationVerticalWhenCapture = DisplayService.getInstance().isOrientationVertical();
    this.directionWhenCapture = getStates().get<WindowDirection>('contextReducer', 'direction');
    this.correctedDirectionWhenCapture = this.mDirection;
    this.pickerWindowTypeWhenCapture = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    this.isGeneratedContentHorizontal = PickerUtils.isGeneratedContentHorizontal(this.isOrientationVerticalWhenCapture,
      this.isVertical(this.directionWhenCapture));
    this.updateGeneratedContentHorizontal();
    HiLog.i(TAG, `updateCommunicationData directionWhenCapture ${this.directionWhenCapture},
      isGeneratedContentHorizontal ${this.isGeneratedContentHorizontal}`);
  }

  // 关闭旋转锁定，窗口direction始终为2， 需要依据屏幕的rotation判断isGeneratedContentHorizontal状态
  private updateGeneratedContentHorizontal(): void {
    if (this.isLockRotation) {
      return;
    }
    if (WindowService.getInstance().getWindowStatus() !== window.WindowStatusType.FLOATING) {
      return;
    }
    const rotation = DisplayService.getInstance().getDisplay().rotation;
    if (rotation === display.Orientation.PORTRAIT || rotation === display.Orientation.PORTRAIT_INVERTED) {
      this.isGeneratedContentHorizontal = false;
    } else {
      this.isGeneratedContentHorizontal = true;
    }
  }

  private getPixelMap(): void {
    this.pixelMap = PickerUiService.getInstance().getThumbnail();
    if (!this.state.isPhoto && PickerUtils.getIsExpandedTopBottomSplitScreen()) {
      if (DisplayService.getInstance().isOrientationVertical()) {
        this.pixelMap.rotateSync(this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK ?
          ROTATE_ANGLE_NEG_90 : ROTATE_ANGLE_90);
      } else {
        this.pixelMap.rotateSync(this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT ?
          ROTATE_ANGLE_180 : 0);
      }
      return;
    }
    if (!this.state.isPhoto && (PickerUtils.getIsExpandedLeftRightSplitScreen() &&
      !DisplayService.getInstance().isOrientationVertical())) {
      this.pixelMap.rotateSync(ROTATE_ANGLE_90);
      return;
    }
    const rotation: number = DisplayService.getInstance().getDisplay().rotation;
  }

  private isVertical(direction?: WindowDirection): boolean {
    const dir: WindowDirection = direction ?? this.mDirection;
    return dir === WindowDirection.TOP || dir === WindowDirection.BOTTOM;
  }

  private getContentOffsetY(): number {
    return this.isNeedRotate() ? (this.getContentWidth() - this.getContentHeight()) / 2 : 0;
  }

  private getImageOffset(): Position {
    if (this.isVdeCollapsed) {
      return { x: 0, y: 0 };
    }
    return { y: this.getContentOffsetY() + this.previewPosition };
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

  private getRotateCenterX(): number | undefined {
    if (this.isGeneratedContentHorizontal) {
      return undefined;
    }
    return Math.min(this.contentSize.width, this.contentSize.height) / 2;
  }

  private getVideoControllerOffsetY(): number {
    const originalPositionY: number = this.getContentHeight() / 2 - VIDEO_CONTROLLER_COMPONENT_HEIGHT / 2;
    let targetPositionY: number = 0;
    const direction = getStates().get<WindowDirection>('contextReducer', 'direction');
    if (this.isVertical(direction)) {
      targetPositionY = this.footBarPosition - this.contentPosition - 12 - VIDEO_CONTROLLER_COMPONENT_HEIGHT;
    } else {
      targetPositionY = this.getContentHeight() - 12 - VIDEO_CONTROLLER_COMPONENT_HEIGHT;
    }
    return targetPositionY - originalPositionY;
  }

  private isConfirmButtonEnabled(): boolean {
    return this.state.isPhoto || this.isPickerVideoReady;
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      if (this.state.isPhoto) {
        Image(this.pixelMap)
          .width(this.getContentWidth())
          .height(this.getContentHeight())
          .offset(this.getImageOffset())
          .draggable(false)
          .autoResize(false)
          .objectFit(ImageFit.Contain)
          .rotate({ angle: this.contentRotateAngle, centerX: this.getRotateCenterX() })
          .syncLoad(true)
      } else {
        if (this.showPicker) {
          this.VideoComponent();
        }
      }
      this.ButtonView();
    }
    .width(this.windowWidth)
    .height(this.windowHeight)
    .backgroundColor(Color.Black)
  }

  @Builder
  ButtonView() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
      CircleImage({
        circleImageRes: $r('app.media.ic_camera_cancel'),
        onCircleImageClicked: (): void => this.onCancelClicked(),
        isCancelViewVisibility: true,
        keyValue: ComponentIdKeys.THIRDPARTYCALL_REMAKE_1,
        abText: $r('sys.string.icon_cancel')
      })

      CircleImage({
        circleImageRes: $r('app.media.ic_camera_confirm'),
        onCircleImageClicked: async () => {
          this.onConfirmClicked();
        },
        isCancelViewVisibility: true,
        keyValue: ComponentIdKeys.THIRDPARTYCALL_CONFIRM_1,
        abText: $r('sys.string.icon_save')
      })
        .enabled(this.isConfirmButtonEnabled())
        .opacity(this.isConfirmButtonEnabled() ? CIRCLE_IMAGE_DEF_OPACITY : CIRCLE_IMAGE_OPACITY)
    }
    .width('100%')
    .height(BUTTON_VIEW_HEIGHT)
    .position({ y: this.footBarPosition })
    .padding({ left: 37, right: 37 })
    .hitTestBehavior(HitTestMode.Transparent)
    .onVisibleAreaChange([0, 1], (isVisible: boolean, currentRatio: number) => {
      // 无障碍专用
      if (this.enableScreenReader) {
        if (isVisible) {
          AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.THIRDPARTYCALL_CONFIRM_1);
        } else {
          AccessibilityUtils.sendFocusAccessibilityEvent(this.state.isPhoto ? 'nightShutterStatusShutter' :
            ComponentIdKeys.SHUTTER_VIDEO_1);
        }
      }
    })
  }

  private async onConfirmClicked(): Promise<void> {
    HiLog.i(TAG, 'Confirm button clicked.');
    if (!getStates().get<boolean>('uiReducer', 'showPicker')) {
      HiLog.i(TAG, 'hidden PickerView: showPicker false');
      return;
    }
    if (this.isImageConfirmClicked) {
      HiLog.i(TAG, 'isImageConfirmClicked true');
      return;
    }
    this.isImageConfirmClicked = true;
    const uri = this.state.isPhoto ? this.state.resourceUri : this.state.videoUri;
    HiLog.i(TAG, `this.state.isPhoto: ${this.state.isPhoto}`);
    await PickerUiService.getInstance().backAfterCapture(this.state.isPhoto, uri,
      this.mCallBundleName);
    StoreManager.getInstance().postMessage(Action.uiStateWithMode(true, UiStateMode.EXCLUDE_PREVIEW));
  }

  private onCancelClicked(): void {
    HiLog.i(TAG, 'Cancel button clicked.');
    StoreManager.getInstance().postMessage(Action.pickerRemake());
    StoreManager.getInstance().postMessage(Action.uiStateWithMode(true, UiStateMode.EXCLUDE_PREVIEW));
    this.showControlsBar = false;
    PickerUiService.getInstance().resetURIContent();
    ZoomOperation.getInstance().setRemainZoomRatio(true);
    StoreManager.getInstance().postMessage(Action.updateShowPickerView(false, true));
    this.resetPixelMap();
    this.updateContentRotateAngle();
    this.uxInit();
    this.isPickerVideoReady = false;
    PickerUiService.getInstance().setVideoTimeBeforeCollapsing(0);
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
      .offset(this.getImageOffset())
      .rotate({ angle: this.contentRotateAngle, centerX: this.getRotateCenterX() })
  }
}