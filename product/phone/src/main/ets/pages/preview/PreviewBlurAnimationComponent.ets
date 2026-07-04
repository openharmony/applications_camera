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

import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { Dispatch, getStates, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { BlurAnimateUtil } from '@ohos/common/src/main/ets/utils/BlurAnimateUtil';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { image } from '@kit.ImageKit';
import lazy { PositionType } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy {
  AbilityBackgroundData,
  PreviewFrameStartData,
  SavePowerModeActionData
} from '@ohos/common/src/main/ets/utils/types';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { camera } from '@kit.CameraKit';
import lazy { curves } from '@kit.ArkUI';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { PreviewAction } from '@ohos/common/src/main/ets/redux/actions/PreviewAction';
import { ComponentSnapshotService } from '@ohos/common/src/main/ets/service/componentSnapshot/ComponentSnapshotService';

const TAG: string = 'PreviewBlurAnimationComponent';

const FIRST_FRAME_TIMEOUT: number = 3000;
const HIDE_X_COMPONENT_DELAY: number = 100;

class PreviewBlurAnimationDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changePreviewSizeAnim(): void {
    this.mDispatch(PreviewAction.changePreviewSizeAnim());
  }

  public hideXComponent(): void {
    this.mDispatch(PreviewAction.hideXComponent());
  }
}

@Component
export struct PreviewBlurAnimationComponent {
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mAction: PreviewBlurAnimationDispatcher = new PreviewBlurAnimationDispatcher();
  private hasShowBlurWhenExit: boolean = false;
  private clearBlurTask: number = -1;
  private isPicker: boolean = false;
  private alreadyDisappear: boolean = false;
  private blurredPixelMapWidth: number = 0;
  private blurredPixelMapHeight: number = 0;
  private isContinueChangeSlowZoom: boolean = false;
  private continueSlowZoomTimer: number = -1;
  private hideXComponentTimer: number = Number.MIN_VALUE;
  private isDeviceLowConfig : boolean = CameraAppCapability.getInstance().getIsDeviceLowConfig();
  @Prop previewAnimateWidth: number = 0;
  @Prop previewAnimateHeight: number = 0;
  @Link mScreenshotPixelMap: image.PixelMap | null;
  @Link blurredPixelMapPosition: PositionType;
  @Link xComponentWidth: number;
  @Link xComponentHeight: number;
  @State isColdFrameStart: boolean = BlurAnimateUtil.isColdFrameStart;
  @State isCollapsStart: boolean = false;
  @State isPhotoBrowserBack: boolean = false;
  @State isForeground: boolean = false;
  @State isInSwitchingCamera: boolean = false;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  @State isShowDefault: boolean = false;
  @State isShowSemiCollapsed: boolean = false;
  @State isShowLandscape: boolean = false;
  @State isShowTricollaps: boolean = false;
  @State isHalfCollapsLEM: boolean = false;
  @State mode: ModeType = ModeType.NONE;
  @State imgScale: ScaleOptions = { x: 1, y: 1 };
  @State staticBlur: image.PixelMap | null = null;
  @State isShowStaticBlur: boolean = false;
  @State isNeedFixBlur: boolean = false;
  @State hideBlurAnimDelay: number = 0;
  @State @Watch('pixelMapAngleChange') mScreenshotPixelMapAngle: number = 0;
  @State pixelMapHorizontal: boolean = true;
  @State cameraSwitchRotation: RotateOptions = {
    y: BlurAnimateUtil.ROTATE_AXIS,
    angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180
  }
  @State mModeSwitchImgBlur: number = 0;
  @State mModeSwitchImgOpacity: number = 1;
  @State visibleAreaWidth: number = 0;
  @State visibleAreaHeight: number = 0;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @StorageLink('isInBlurAnim') isInBlurAnim: boolean = false;
  @StorageLink('isShowPhotoBrowser') @Watch('changeImgBlurValue') isShowPhotoBrowser: boolean = false;
  @LocalStorageLink('previewAnimatePosition') previewAnimatePosition: PositionType = { x: 0, y: 0 };
  @LocalStorageLink('mShowModeSwitchImg') mShowModeSwitchImg: boolean = false;
  @LocalStorageLink('needShowBlackBack') needShowBlackBack: boolean = false;
  @LocalStorageLink('isNeedPreviewResizeAnim') isNeedPreviewResizeAnim: boolean = false;
  @LocalStorageLink('isBetweenBlurAnimDoneAndAnimEnd') isBetweenBlurAnimDoneAndAnimEnd: boolean = false;
  @LocalStorageLink('showAssistGrid') showAssistGrid: boolean = true;
  @LocalStorageLink('isLemModeSwitched') isLemModeSwitched: boolean = true;

  aboutToAppear(): void {
    this.isForeground = true;
    this.isPicker = GlobalContext.get().getIsPicker();
    this.registerEventBus();
    this.subscribeRedux();
    this.initBlurAnimParams();
  }

  aboutToDisappear(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    this.alreadyDisappear = true;
  }

  private registerEventBus(): void {
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_PREVIEW_FRAME_START,
      (data: PreviewFrameStartData) => this.onPreviewFrameStart(data), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.UPDATE_SAVE_POWER_MODE_STATE, (data: SavePowerModeActionData) =>
    this.updateSavePowerModeState(data), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.CLOSE, this.closeCallback.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.WARM_START_WITH_MODE_AND_POS, this.warmStartWithModeAPos.bind(this),
      this.mBase.hashCode());
  }

  private subscribeRedux(): void {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.isShowDefault = state.get<boolean>('collapsReducer', 'isShowDefault');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
  }

  private initBlurAnimParams(): void {
    this.blurredPixelMapWidth = this.previewAnimateWidth;
    this.blurredPixelMapHeight = this.previewAnimateHeight;
    this.blurredPixelMapPosition.x = this.previewAnimatePosition.x;
    this.blurredPixelMapPosition.y = this.previewAnimatePosition.y;
    this.hideBlurAnimDelay = 0;
  }

  private prepareForHideBlurAnim(): void {
    if (!this.isShowSemiCollapsed && this.isShowLandscape) {
      this.prepareForLandscapeHideBlurAnim();
      return;
    }
    this.prepareForDefaultHideBlurAnim();
  }

  private isNonScaledFov(width: number, height: number): boolean {
    const ratio: number = width / height;
    const tolerance: number = 0.02;
    const isRatio4to3: boolean = Math.abs(ratio - 0.75) < tolerance || Math.abs(ratio - 4 / 3) < tolerance;
    const isRatio16to9: boolean = Math.abs(ratio - 9 / 16) < tolerance;
    const isRatio1to1: boolean = Math.abs(ratio - 1) < tolerance;
    if (this.isShowSemiCollapsed) {
      // 悬停态只有16:9的预览进行了放大
      return !isRatio16to9;
    }
    if (this.isShowLandscape || this.isShowTricollaps) {
      // 展开态只有4:3预览未进行裁剪放大
      return isRatio4to3;
    }
    // 或直板机4:3预览、1:1预览均未进行裁剪放大
    return isRatio4to3 || isRatio1to1;
  }

  private prepareForDefaultHideBlurAnim(): void {
    const xComponentWidthFromReducer: number = getStates().get<number>('previewReducer', 'xComponentWidth');
    const xComponentHeightFromReducer: number = getStates().get<number>('previewReducer', 'xComponentHeight');
    const isCurrentNonScaledFov: boolean = this.isNonScaledFov(this.previewAnimateWidth, this.previewAnimateHeight);
    const isTargetNonScaledFov: boolean = this.isNonScaledFov(xComponentWidthFromReducer, xComponentHeightFromReducer);
    let scale: number = 1;
    if (xComponentWidthFromReducer !== this.previewAnimateWidth &&
      xComponentHeightFromReducer !== this.previewAnimateHeight) {
      this.hideBlurAnimDelay = BlurAnimateUtil.HIDE_BLUR_DELAY_200;
      this.isNeedFixBlur = false;
    } else if (xComponentHeightFromReducer < this.previewAnimateHeight) {
      // 直板态预览宽度撑满，所以变化前后Fov为发生变化时，无需做缩小动效
      const isNeedIgnoreScaleDownAnim: boolean = isCurrentNonScaledFov && isTargetNonScaledFov;
      this.hideBlurAnimDelay =
        isNeedIgnoreScaleDownAnim ? BlurAnimateUtil.HIDE_BLUR_DELAY_200 : BlurAnimateUtil.HIDE_BLUR_DELAY_50;
      this.isNeedFixBlur = true;
      if (!isNeedIgnoreScaleDownAnim) {
        scale = this.previewAnimateHeight / xComponentHeightFromReducer;
      }
    } else if (xComponentWidthFromReducer < this.previewAnimateWidth) {
      this.hideBlurAnimDelay = BlurAnimateUtil.HIDE_BLUR_DELAY_200;
      this.isNeedFixBlur = true;
      this.xComponentWidth = xComponentWidthFromReducer;
      this.xComponentHeight = xComponentHeightFromReducer;
    } else {
      this.hideBlurAnimDelay = 0;
      this.isNeedFixBlur = false;
    }
    this.xComponentWidth = scale * xComponentWidthFromReducer;
    this.xComponentHeight = scale * xComponentHeightFromReducer;
  }

  private prepareForLandscapeHideBlurAnim(): void {
    const xComponentWidthFromReducer: number = getStates().get<number>('previewReducer', 'xComponentWidth');
    const xComponentHeightFromReducer: number = getStates().get<number>('previewReducer', 'xComponentHeight');
    if (xComponentWidthFromReducer !== this.previewAnimateWidth &&
      xComponentHeightFromReducer !== this.previewAnimateHeight) {
      this.hideBlurAnimDelay = BlurAnimateUtil.HIDE_BLUR_DELAY_200;
      this.isNeedFixBlur = false;
    } else if (xComponentWidthFromReducer < this.previewAnimateWidth ||
      xComponentHeightFromReducer < this.previewAnimateHeight) {
      this.hideBlurAnimDelay = BlurAnimateUtil.HIDE_BLUR_DELAY_200;
      this.isNeedFixBlur = true;
      this.xComponentWidth = xComponentWidthFromReducer;
      this.xComponentHeight = xComponentHeightFromReducer;
    } else {
      this.hideBlurAnimDelay = 0;
      this.isNeedFixBlur = false;
      this.xComponentWidth = xComponentWidthFromReducer;
      this.xComponentHeight = xComponentHeightFromReducer;
    }
  }

  private onPreviewFrameStart(data: PreviewFrameStartData): void {
    HiLog.i(TAG, `onPreviewFrameStart ${data.isPreviewFrameStart}.`);
    AppStorage.setOrCreate('onPreviewFrameStart', data.isPreviewFrameStart);
    if (data.isPreviewFrameStart) {
      if (!this.isColdFrameStart) {
        this.isColdFrameStart = true;
        BlurAnimateUtil.isColdFrameStart = true;
        this.isCollapsStart = true;
        this.isInBlurAnim = false;
      }
      this.hideBlurAnim();
    } else {
      this.initBlurAnimParams();
      this.updateBlurTask();
      if (BlurAnimateUtil.getIsInSwitchCamera()) {
        this.needShowBlackBack = true;
        this.cameraSwitch();
      } else if (!this.hasShowBlurWhenExit) {
        this.showBlurAnim(data.isToGallery);
      } else if (this.hasShowBlurWhenExit) {
        if (CameraAppCapability.getInstance().getIsDeviceLowConfig()) {
          return;
        }
        this.blurAnimate(true);
      }
    }
  }

  private onForeground(): void {
    this.isForeground = true;
    clearTimeout(this.hideXComponentTimer);
  }

  private onBackground(data: AbilityBackgroundData): void {
    this.isForeground = false;
    this.releaseCamera(data);
  }

  private clearBlur(): void {
    HiLog.e(TAG, 'No first frame, clear blur');
    BlurAnimateUtil.setValidFrameFlag(true);
    this.hideBlurAnim();
  }

  private updateBlurTask() {
    clearTimeout(this.clearBlurTask);
    this.clearBlurTask = setTimeout(() => {
      this.clearBlur();
    }, FIRST_FRAME_TIMEOUT);
  }

  private closeCallback(): void {
    HiLog.i(TAG, 'Generate pixelMap while goto gallery');
    clearTimeout(this.clearBlurTask);
  }

  private async releaseCamera(data: AbilityBackgroundData): Promise<void> {
    HiLog.i(TAG, 'releaseCamera called.');
    if ((data.isPickerBack && !this.isPicker) || (!data.isPickerBack && this.isPicker)) {
      HiLog.w(TAG, 'releaseCamera Repeated Conflicts');
      return;
    }
    this.generateBlurPixelMap(true);
  }

  private updateSavePowerModeState(data: SavePowerModeActionData): void {
    if (data.isDuringSavePowerMode) {
      this.generateBlurPixelMap(true);
    }
  }

  private isNeedRotate(cameraPosition: camera.CameraPosition): boolean {
    return cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT
  }

  private pixelMapAngleChange(): void {
    this.pixelMapHorizontal = this.mScreenshotPixelMapAngle === 0 || this.mScreenshotPixelMapAngle === 180;
    HiLog.d(TAG, `pixelMapHorizontal: ${this.pixelMapHorizontal}`);
  }

  private async prepareBlurImage(): Promise<void> {
    HiLog.begin(TAG, 'prepareBlurImage');
    if (this.isDeviceLowConfig) {
      HiLog.begin(TAG, 'generateBlurByEffectKit');
      this.mScreenshotPixelMap = await BlurAnimateUtil.generateBlurByEffectKit(BlurAnimateUtil.getBlurPixelMap(),
        this.isShowLandscape);
      HiLog.end(TAG, 'generateBlurByEffectKit');
    } else {
      this.mScreenshotPixelMap = BlurAnimateUtil.getBlurPixelMap();
    }
    this.prepareBlurAngleAndRotation();
    HiLog.end(TAG, 'prepareBlurImage');
  }

  private prepareBlurAngleAndRotation() {
    HiLog.begin(TAG, 'prepareBlurAngleAndRotation');
    this.mScreenshotPixelMapAngle = BlurAnimateUtil.getBlurPixelAngle();
    const cameraPosition: camera.CameraPosition = BlurAnimateUtil.getCameraPosition();
    if (this.isShowSemiCollapsed) {
      if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
        this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
      } else {
        this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
      }
    } else {
      if (this.isNeedRotate(cameraPosition)) {
        this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
      } else {
        this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
      }
    }
    HiLog.end(TAG, 'prepareBlurAngleAndRotation');
  }

  private warmStartWithModeAPos(): void {
    this.isNeedPreviewResizeAnim = true;
  }

  private changeImgBlurValue(): void {
    if (!this.isShowPhotoBrowser) {
      this.mModeSwitchImgBlur = AnimSpecifications.ANIM_MODE_SWITCH_BLUR;
      this.isPhotoBrowserBack = true;
    }
  }

  private generateBlurPixelMap(needShowBlur: boolean): void {
    BlurAnimateUtil.generatePixelMapFromSurface();
    if (needShowBlur) {
      this.showBlurWhenExit(false);
    }
  }

  private showBlurAnim(isToGallery?: boolean): void {
    if (BlurAnimateUtil.getHasShowBlurWhenExit()) {
      this.isNeedPreviewResizeAnim = true;
      this.hasShowBlurWhenExit = true;
    }
    if (this.isInBlurAnim) {
      BlurAnimateUtil.setIsContinuousSwitch(true)
      BlurAnimateUtil.setValidFrameFlag(false);
      HiLog.w(TAG, 'Restart preview too quick, then intercept blur and size animation.')
      this.mModeSwitchImgBlur = AnimSpecifications.ANIM_MODE_SWITCH_BLUR;
      this.mModeSwitchImgOpacity = 1;
      FeatureManager.getInstance().setIsInResolution(false);
      return;
    }
    HiLog.begin(TAG, 'showBlurAnim');
    this.showLowDeviceBlurBackground();
    if (isToGallery) {
      this.opacityAnimate();
    } else {
      this.blurAnimate(false);
    }
  }

  private showLowDeviceBlurBackground(): void {
    if (this.isDeviceLowConfig) {
      HiLog.begin(TAG, 'showLowDeviceBlurBackground');
      this.mShowModeSwitchImg = true;
      this.prepareBlurAngleAndRotation();
      HiLog.end(TAG, 'showLowDeviceBlurBackground');
    }
  }

  private async blurAnimate(isFromStart: boolean): Promise<void> {
    this.isShowStaticBlur = false;
    this.isInBlurAnim = true;
    this.mShowModeSwitchImg = true;
    let mModeSwitchImgBlur: number = isFromStart && !this.isDeviceLowConfig ?
      AnimSpecifications.ANIM_MODE_SWITCH_BLUR : 0;
    if (CameraAppCapability.getInstance().getIsNeedFixedBlurRadius() || this.isPhotoBrowserBack) {
      mModeSwitchImgBlur = AnimSpecifications.ANIM_MODE_SWITCH_BLUR;
      this.isPhotoBrowserBack = false;
    }
    this.mModeSwitchImgBlur = mModeSwitchImgBlur;
    HiLog.i(TAG, 'blurAnimate is low config device:' + this.isDeviceLowConfig);
    this.prepareBlurImage();
    if (this.isDeviceLowConfig) {
      if (isFromStart) {
        this.mModeSwitchImgOpacity = 1;
      } else {
        if (this.mModeSwitchImgOpacity === 0) {
          this.mModeSwitchImgOpacity = 0.3;
        }
      }
    } else {
      this.mModeSwitchImgOpacity = 1;
    }
    animateToImmediately(
      {
        duration: BlurAnimateUtil.SHOW_BLUR_DURATION,
        curve: Curve.Linear,
        onFinish: async () => {
          HiLog.end(TAG, 'showBlurAnim');
          this.isBetweenBlurAnimDoneAndAnimEnd = true;
          FeatureManager.getInstance().setIsInResolution(false);
          if (!this.isDeviceLowConfig) {
            this.staticBlur = ComponentSnapshotService.getInstance().getInSnapshotByComponentId('test3')
            this.isShowStaticBlur = true;
          }
          this.mScreenshotPixelMapAngle = BlurAnimateUtil.getBlurPixelAngle();
          const cameraPosition: camera.CameraPosition = BlurAnimateUtil.getCameraPosition();
          if (this.isShowSemiCollapsed) {
            if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
              this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
            } else {
              this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
            }
          } else {
            if (this.isNeedRotate(cameraPosition)) {
              this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
            } else {
              this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
            }
          }
          this.mModeSwitchImgBlur = 0;
          this.prepareForHideBlurAnim();
          if (this.hideBlurAnimDelay === BlurAnimateUtil.HIDE_BLUR_DELAY_200) {
            this.mAction.changePreviewSizeAnim();
          }
        }
      },
      () => {
        if (this.isDeviceLowConfig) {
          if (!isFromStart) {
            this.mModeSwitchImgOpacity = 1;
          }
        } else if (this.mModeSwitchImgBlur !== AnimSpecifications.ANIM_MODE_SWITCH_BLUR) {
          this.mModeSwitchImgBlur = AnimSpecifications.ANIM_MODE_SWITCH_BLUR;
        }
      }
    );
  }

  private async showBlurWhenExit(isCollaps: boolean): Promise<void> {
    HiLog.i(TAG, 'showBlurWhenExit');
    if (this.isDeviceLowConfig) {
      this.mScreenshotPixelMap = await BlurAnimateUtil.generateBlurByEffectKit(BlurAnimateUtil.getBlurPixelMap(),
        this.isShowLandscape);
      this.mModeSwitchImgBlur = 0;
    } else {
      this.mScreenshotPixelMap = BlurAnimateUtil.getBlurPixelMap();
      this.mModeSwitchImgBlur = AnimSpecifications.ANIM_MODE_SWITCH_BLUR;
    }
    this.mScreenshotPixelMapAngle = BlurAnimateUtil.getBlurPixelAngle();
    if (this.isNeedRotate(this.cameraPosition)) {
      this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
    } else {
      this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
    }
    HiLog.i(TAG, 'Foreground state: ' + this.isForeground + ' Collaps state: ' + isCollaps);
    if (!this.isForeground || isCollaps) {
      this.mModeSwitchImgOpacity = 1;
      this.mShowModeSwitchImg = true;
      this.isInBlurAnim = true;
      this.isNeedPreviewResizeAnim = true;
      this.hasShowBlurWhenExit = true;
      this.hideXComponentTimer = setTimeout(()=>{
        this.mAction.hideXComponent();
      }, HIDE_X_COMPONENT_DELAY);
    }
    if (this.alreadyDisappear) {
      HiLog.i(TAG, 'release pixelMap after disappear')
      this.mScreenshotPixelMap?.release();
      this.staticBlur?.release();
    }
  }

  private hideBlurAnim(): void {
    if (!BlurAnimateUtil.getValidFrameFlag()) {
      HiLog.w(TAG, 'wait for first frame');
      return;
    }
    if (BlurAnimateUtil.getIsContinuousSwitch()) {
      HiLog.w(TAG, 'Switch timeout.');
      setTimeout(() => {
        this.hideBlurAnim();
      }, BlurAnimateUtil.SWITCH_TIMEOUT);
      BlurAnimateUtil.setIsContinuousSwitch(false);
      return;
    }
    if (this.hideBlurAnimDelay !== BlurAnimateUtil.HIDE_BLUR_DELAY_200) {
      this.mAction.changePreviewSizeAnim();
    }
    this.needShowBlackBack = false;
    this.hasShowBlurWhenExit = false;
    BlurAnimateUtil.setHasShowBlurWhenExit(false);
    animateToImmediately({
      duration: BlurAnimateUtil.HIDE_BLUR_DURATION,
      curve: Curve.Linear,
      delay: this.hideBlurAnimDelay === BlurAnimateUtil.HIDE_BLUR_DELAY_200 ? 0 : this.hideBlurAnimDelay,
      onFinish: () => {
        if (!BlurAnimateUtil.getValidFrameFlag()) {
          HiLog.i(TAG, 'wait for next start');
          this.mModeSwitchImgOpacity = 1;
        } else {
          HiLog.i(TAG, 'Hide blur img done.');
          this.mShowModeSwitchImg = false;
          this.isShowStaticBlur = false;
          this.isInBlurAnim = false;
          this.isBetweenBlurAnimDoneAndAnimEnd = false;
          this.isInSwitchingCamera = false;
          this.isCollapsStart = true;
          BlurAnimateUtil.setWaitForPositionFlag(false);
          BlurAnimateUtil.setInSwitchCamera(false);
          this.isNeedPreviewResizeAnim = false;
          clearTimeout(this.clearBlurTask);
          this.mModeSwitchImgBlur = 0;
        }
        this.isLemModeSwitched = true;
        this.mScreenshotPixelMap?.release();
        this.staticBlur?.release();
      }
    }, () => {
      this.mModeSwitchImgOpacity = 0;
    });
  }

  private async opacityAnimate(): Promise<void> {
    this.isInBlurAnim = true;
    this.mModeSwitchImgBlur = 0;
    this.mModeSwitchImgOpacity = 0.3;
    this.mShowModeSwitchImg = true;
    this.mScreenshotPixelMap = await BlurAnimateUtil.generateBlurByEffectKit(BlurAnimateUtil.getBlurPixelMap(),
      this.isShowLandscape);
    this.mScreenshotPixelMapAngle = BlurAnimateUtil.getBlurPixelAngle();
    const cameraPosition: camera.CameraPosition = BlurAnimateUtil.getCameraPosition();
    if (this.isShowSemiCollapsed) {
      if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
        this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
      } else {
        this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
      }
    } else {
      if (this.isNeedRotate(cameraPosition)) {
        this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
      } else {
        this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
      }
    }
    animateToImmediately({
      duration: BlurAnimateUtil.SHOW_BLUR_DURATION,
      curve: Curve.Friction,
      onFinish: () => {
        HiLog.end(TAG, 'showBlurAnim');
        FeatureManager.getInstance().setIsInResolution(false);
        this.mAction.changePreviewSizeAnim();
      }
    }, () => {
      this.mModeSwitchImgOpacity = 1;
    });
  }

  private rotateScaleAnim(): void {
    animateToImmediately(
      {
        duration: BlurAnimateUtil.ROTATION_DURATION,
        curve: Curve.Sharp,
        onFinish: () => {
        }
      },
      () => {
        this.imgScale = { x: 1, y: 1 };
      }
    )
  }

  private doAnimateOfBlur(): void {
    HiLog.begin(TAG, 'showBlurWhenSwitchCamera');
    animateToImmediately(
      {
        duration: BlurAnimateUtil.ROTATION_DURATION,
        curve: Curve.Sharp,
        onFinish: () => {
          HiLog.end(TAG, 'showBlurWhenSwitchCamera');
          this.rotateScaleAnim();
          this.mAction.changePreviewSizeAnim();
        }
      },
      () => {
        this.mModeSwitchImgBlur = AnimSpecifications.ANIM_MODE_SWITCH_BLUR;
        this.imgScale = { x: BlurAnimateUtil.IMG_SCALE, y: BlurAnimateUtil.IMG_SCALE };
      }
    );
  }

  private rotatePreviewAnim(): void {
    this.mModeSwitchImgOpacity = 1;
    this.mShowModeSwitchImg = true;
    this.isInBlurAnim = true;
    const cameraPosition: camera.CameraPosition = BlurAnimateUtil.getCameraPosition();
    if (this.isShowSemiCollapsed) {
      if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
        this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
      } else {
        this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
      }
    } else {
      if (this.isNeedRotate(cameraPosition)) {
        this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
      } else {
        this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
      }
    }
    this.doAnimateOfBlur();
    this.doAnimateOfFlip(cameraPosition);
  }

  private async cameraSwitch(): Promise<void> {
    if (this.isInBlurAnim) {
      FeatureManager.getInstance().setIsInResolution(false);
      this.updateBlurTask();
      this.isNeedPreviewResizeAnim = true;
      this.mModeSwitchImgBlur = AnimSpecifications.ANIM_MODE_SWITCH_BLUR;
      this.mModeSwitchImgOpacity = 1;
      this.mAction.changePreviewSizeAnim();
      return;
    }
    this.mScreenshotPixelMap = BlurAnimateUtil.getBlurPixelMap();
    this.mScreenshotPixelMapAngle = BlurAnimateUtil.getBlurPixelAngle();
    this.rotatePreviewAnim();
  }

  private doAnimateOfFlip(cameraPosition: camera.CameraPosition): void {
    HiLog.begin(TAG, 'cameraFlipAnim');
    animateToImmediately(
      {
        duration: BlurAnimateUtil.ROTATION_DURATION,
        delay: BlurAnimateUtil.FLIP_DELAY,
        curve: curves.cubicBezierCurve(0.20, 0.00, 0.83, 1.00),
        onFinish: () => {
          this.rotateFlipAnim();
          HiLog.end(TAG, 'cameraFlipAnim');
        }
      },
      () => {
        if (this.isShowSemiCollapsed) {
          if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
            this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_ROTATE_ANGLE_270 };
          } else {
            this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_ROTATE_ANGLE_90 };
          }
        } else {
          if (this.isNeedRotate(cameraPosition)) {
            this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_ROTATE_ANGLE_270 };
          } else {
            this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_ROTATE_ANGLE_90 };
          }
        }
      }
    );
  }

  private async rotateFlipAnim(): Promise<void> {
    this.mScreenshotPixelMap = await BlurAnimateUtil.generateBlurByEffectKit(BlurAnimateUtil.getBlurPixelMap(),
      this.isShowLandscape);
    this.mScreenshotPixelMapAngle = BlurAnimateUtil.getBlurPixelAngle();
    this.mModeSwitchImgBlur = 0;
    const cameraPosition: camera.CameraPosition = BlurAnimateUtil.getCameraPosition();
    if (this.isShowSemiCollapsed) {
      if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
        this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_ROTATE_ANGLE_90 };
      } else {
        this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_MINUS_90 };
      }
    } else {
      if (this.isNeedRotate(cameraPosition)) {
        this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_ROTATE_ANGLE_90 };
      } else {
        this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_MINUS_90 };
      }
    }
    animateToImmediately(
      {
        duration: BlurAnimateUtil.ROTATION_DURATION,
        curve: curves.cubicBezierCurve(0.17, 0.00, 0.20, 1.00),
        onFinish: () => {
          HiLog.end(TAG, 'cameraFlipAnim');
        }
      },
      () => {
        if (this.isShowSemiCollapsed) {
          if (cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
            this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
          } else {
            this.cameraSwitchRotation = { x: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
          }
        } else {
          if (this.isNeedRotate(cameraPosition)) {
            this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_180 };
          } else {
            this.cameraSwitchRotation = { y: BlurAnimateUtil.ROTATE_AXIS, angle: BlurAnimateUtil.IMG_FLIP_ANGLE_0 };
          }
        }
      }
    );
  }

  private getImgWidth(): number {
    return this.isNeedFixBlur ? this.blurredPixelMapWidth : this.previewAnimateWidth;
  }

  private getImgHeight(): number {
    return this.isNeedFixBlur ? this.blurredPixelMapHeight : this.previewAnimateHeight;
  }

  private getXComponentScale(): ScaleOptions {
    let scale: ScaleOptions = { x: 1, y: 1 };
    return scale;
  }

  @Builder
  BlurredPixelMapBuilder(): void {
    Stack() {
      if (this.isShowStaticBlur) {
        Image(this.staticBlur)
          .width(this.getImgWidth())
          .height(this.getImgHeight())
          .syncLoad(true)
          .draggable(false)
      } else {
        Image(this.mScreenshotPixelMap)
          .width(this.pixelMapHorizontal ? this.getImgWidth() : this.getImgHeight())
          .height(this.pixelMapHorizontal ? this.getImgHeight() : this.getImgWidth())
          .rotate({
            angle: this.mScreenshotPixelMapAngle
          })
          .blur(this.mModeSwitchImgBlur)
          .syncLoad(true)
          .draggable(false)
          .autoResize(true)
      }
    }
    .key('test3')
    .width(this.getImgWidth())
    .height(this.getImgHeight())
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .rotate(this.cameraSwitchRotation)
    .scale(this.isLemCollaps ? this.getXComponentScale() : this.imgScale)
    .opacity(this.mModeSwitchImgOpacity)
    .position(this.isNeedFixBlur ? {
      x: this.blurredPixelMapPosition.x - this.previewAnimatePosition.x,
      y: this.blurredPixelMapPosition.y - this.previewAnimatePosition.y
    } : { x: 0, y: 0 })
  }

  build() {
    if (this.mShowModeSwitchImg && this.mScreenshotPixelMap) {
      this.BlurredPixelMapBuilder();
    }
  }
}