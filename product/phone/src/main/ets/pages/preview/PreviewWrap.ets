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
import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { PositionType } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import lazy { Dispatch, getStates, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { PreviewArea } from './PreviewArea';
import lazy {
  ExtendBarData,
  AdaptiveLayoutService,
  NUMBER_MIN
} from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLayoutService';
import lazy { curves, display, window } from '@kit.ArkUI';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import lazy { PreviewActionType } from '@ohos/common/src/main/ets/redux/actions/PreviewActionType';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { COMPONENT_WIDTH } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { PreviewBlurAnimationComponent } from './PreviewBlurAnimationComponent';
import lazy { PreviewAction } from '@ohos/common/src/main/ets/redux/actions/PreviewAction';
import { XComponentSize } from '@ohos/common/src/main/ets/utils/types';

const TAG: string = 'PreviewWrap';

const NUMBER_4_3: number = 0.75;
const FOOT_BAR_COL: number = 8;
const EPSILON = 0.1;
const MOVE_ANIMATION_CURVE: curves.ICurve = curves.interpolatingSpring(0, 1, 228, 30);
const PREVIEW_MARGIN_SIZE_56: number = 56;
const PREVIEW_MARGIN_SIZE_68: number = 68;

export const DISPLAY_SCREEN_SIZE_LEM: number = 226;

export const DISPLAY_SCREEN_SIZE_PSD: number = 202;

const ROUND_VIDEO_PREVIEW_SCALE: number = 1.3;

/* instrument ignore file */
class ShotComponentData {
  public oldMode: ModeType = ModeType.NONE;
  public newMode: ModeType = ModeType.NONE;
  public oldOutputType?: OutputType = OutputType.NONE;
  public newOutputType?: OutputType = OutputType.NONE;
  public isShowBigText: boolean = true;
}

class ModeSwitchAnimData {
  public oldWidth: number = 0;
  public newWidth: number = 0;
  public oldHeight: number = 0;
  public newHeight: number = 0;
}

class PreviewAreaDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeXComponentSize(xComponentWidth: number, xComponentHeight: number): void {
    this.mDispatch(Action.changeXComponentSize(xComponentWidth, xComponentHeight));
  }

  public updateShowBigTextFlag(isShowBigTxt: boolean): void {
    this.mDispatch(Action.updateShowBigTextFlag(isShowBigTxt));
  }

  public updateExtendBarPosition(): void {
    this.mDispatch(Action.updateExtendBarPosition());
  }

  public changePreviewSizeAnim(): void {
    this.mDispatch(PreviewAction.changePreviewSizeAnim());
  }

  public updatePreviewAreaAttrs(): void {
    this.mDispatch(PreviewAction.updatePreviewAreaAttrs());
  }
}

@Component
export struct PreviewWrap {
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mBase: BaseComponent = new BaseComponent();
  private mAction: PreviewAreaDispatcher = new PreviewAreaDispatcher();
  private mAdaptiveLayoutService: AdaptiveLayoutService = AdaptiveLayoutService.getInstance();
  private isNeedUpdateLayoutService: boolean = true;
  private lowAngleAnimate: boolean | undefined = undefined;
  // LEM
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @StorageLink('isPSDCollaps') isPSDCollapsed: boolean = false;
  private smallSubDisplayWidth: number = this.isPSDCollapsed ? DISPLAY_SCREEN_SIZE_PSD : DISPLAY_SCREEN_SIZE_LEM;
  @State isShowLemAnimate: boolean = false;
  @State isHalfCollapsLEM: boolean = false;
  // VDE
  @State isVdeCollapsed: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  // OTHERS
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @LocalStorageLink('previewAnimatePosition') previewAnimatePosition: PositionType = { x: 0, y: 0 };
  @LocalStorageLink('newPreviewAnimatePosition') newPreviewAnimatePosition: PositionType = { x: 0, y: 0 };
  @LocalStorageLink('extendBarPosition') extendBarPosition: number = 0;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  private xComponentWidth: number = 0; // 无需使用@State装饰器
  private xComponentHeight: number = 0; // 无需使用@State装饰器
  @State isShowDefault: boolean = false;
  @State isShowSemiCollapsed: boolean = false;
  @State isShowLandscape: boolean = false;
  @State isShowTricollaps: boolean = false;
  @State isShowLowAngleShotView: boolean = false;
  @State showPicker: boolean = false; // 是否展示Picker确认界面
  @State isShowMorePage: boolean = false;
  @State mode: ModeType = ModeType.NONE;
  @StorageLink('onCustomFilterCardActionMenuShow') isShowActionMenu: boolean = false;
  @StorageLink('isBackground') isBackground: boolean = false;
  @Prop isHdr: boolean = false;
  buildFromPicker: boolean = false;

  aboutToAppear(): void {
    this.subscribeRedux();
    this.subscribeEventBus();
    this.uxInit();
  }

  aboutToDisappear(): void {
    this.mSubscriber?.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
  }

  private subscribeRedux(): void {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.showPicker = state.get<boolean>('uiReducer', 'showPicker');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.isShowDefault = state.get<boolean>('collapsReducer', 'isShowDefault');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isShowLowAngleShotView = state.get<boolean>('collapsReducer', 'isShowLowAngleShotView');
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
  }

  private subscribeEventBus(): void {
    const code: string = this.mBase.hashCode();
    this.mEventBus.on([WindowActionType.ON_SIZE_CHANGE, WindowActionType.REFRESH_UX], () => this.uxInit(), code);
    this.mEventBus.on(ActionType.ACTION_IS_SHOW_EXTEND_BAR, (data: ExtendBarData) => this.previewAvoidingMotion(data),
      code);
    this.mEventBus.on(ActionType.ACTION_PREVIEW_SHOT_COMPONENT,
      (data: ShotComponentData) => this.updateShotComponent(data), code);
    this.mEventBus.on(PreviewActionType.CHANGE_X_COMPONENT_AUTO,
      (data: XComponentSize) => this.changeXComponentSizeAuto(data), code);
  }

  /**
   * 桌面旋转，窗口大小发生变化，预览大小、位置更新的统一入口
   */
  private uxInit(): void {
    this.isNeedUpdateLayoutService = true;
    const size: Size = CameraBasicService.getInstance().getPreviewDisplaySize();
    const xComponentSize: XComponentSize = { xComponentWidth: size.width, xComponentHeight: size.height };
    // 先changeXComponent，确保下面计算中从reducer拿到的xComponentWidth和xComponentHeight是最新的
    this.changeXComponentSizeAuto(xComponentSize);
    try {
      if (display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_EXPANDED && !this.isShowDefault) {
        this.UpdatePreviewPositionForLandscape(xComponentSize.xComponentWidth, xComponentSize.xComponentHeight);
      }
    } catch (err) {
      HiLog.e(TAG, `getCollapsStatus fail. ${err?.code}`);
    }
    this.previewAnimatePosition = this.newPreviewAnimatePosition;
    this.mAction.updatePreviewAreaAttrs();
  }

  /**
   * 页面布局形态切换，XComponentSize改变的统一入口。
   * 页面布局形态切换 --> 预览大小变化 --> 更新 newPreviewAnimatePosition --> 发送ACTION_CHANGE_X_COMPONENT_SIZE事件 -->
   * PreviewArea中监听该事件的回调会在changePreviewSizeAnimWithoutBlur方法中统一执行预览缩放、位移动效
   */
  private onChangeShowLandscapeDone() {
    if (CameraAppCapability.getInstance().getIsSupportedLowAngleShot()) {
      this.lowAngleAnimate = false;
    }
    /**
     * isNeedPreviewResizeAnim 控制是否要执行预览缩放时的动效，因为动效变量涉及到 PreviewArea 中的 previewSize和xComponentWidth、
     * xComponentHeight（与reducer中的不同），所以预览缩放动效在 PreviewArea 的 ACTION_CHANGE_X_COMPONENT_SIZE 回调中执行
     */
    const size: Size = CameraBasicService.getInstance().getPreviewDisplaySize();
    const xComponentSize: XComponentSize = { xComponentWidth: size.width, xComponentHeight: size.height };
    // 此处统一发送CHANGE_X_COMPONENT_SIZE事件，触发onXComponentSizeChange方法并只更新 newPreviewAnimatePosition，即预览目标位置
    this.changeXComponentSizeAuto(xComponentSize);
  }

  /**
   * 模式切换、前后置切换等场景，更改预览大小的唯一入口
   * @param data 模式切换时的数据，包含新老预览大小、新老拍照流视频流状态
   */
  private async updateShotComponent(data: ShotComponentData): Promise<void> {
    HiLog.begin(TAG, 'updateShotComponent.');
    HiLog.d(TAG, `old: ${data.oldMode} new: ${data.newMode}.`);
    // 获取新模式预览流宽高
    let xComponentSizeOld: Size;
    let xComponentSizeNew: Size;
    if (this.isShowSemiCollapsed) {
      xComponentSizeOld = CameraBasicService.getInstance().getSemiDisplaySize(data.oldMode);
      xComponentSizeNew = CameraBasicService.getInstance().getSemiDisplaySize(data.newMode);
    } else {
      xComponentSizeOld = CameraBasicService.getInstance().getPreviewDisplaySize(data.oldMode);
      xComponentSizeNew = CameraBasicService.getInstance().getPreviewDisplaySize(data.newMode);
    }
    const animData: ModeSwitchAnimData = {
      oldWidth: xComponentSizeOld.width,
      newWidth: xComponentSizeNew.width,
      oldHeight: xComponentSizeOld.height,
      newHeight: xComponentSizeNew.height,
    };
    const modeChangeAvoidShowBT = data.isShowBigText; // 默认热启动，设置页恢复默认值，不展示大字体
    if (modeChangeAvoidShowBT) {
      this.mAction.updateShowBigTextFlag(true); //模式切换的大字体展示在这
    }
    const size: XComponentSize = { xComponentWidth: animData.newWidth, xComponentHeight: animData.newHeight };
    this.changeXComponentSizeAuto(size, data.newMode);
  }

  /**
   * 预览大小发生变化时，更新 newPreviewAnimatePosition，此处不负责动效
   * @param data 最新的预览大小
   */
  private onXComponentSizeChange(xComponentWidth: number, xComponentHeight: number): void {
    this.xComponentWidth = xComponentWidth;
    this.xComponentHeight = xComponentHeight;
    if (DeviceInfo.isTablet()) {
      this.newPreviewAnimatePosition = this.getTabletPreviewPosition();
      return;
    }

    if (this.isShowLandscape) {
      this.UpdatePreviewPositionForLandscape(xComponentWidth, xComponentHeight);
      return;
    }
    if (this.isShowDefault) {
      this.UpdatePreviewPositionForStraight(xComponentWidth, xComponentHeight);
      return;
    }
    if (this.isShowTricollaps) {
      this.UpdatePreviewPositionForTriCollaps(xComponentWidth, xComponentHeight);
      return;
    }
  }

  /**
   * 直板机预览位置计算逻辑
   * @param xComponentWidth 预览宽度
   * @param xComponentHeight 预览高度
   */
  private UpdatePreviewPositionForStraight(xComponentWidth: number, xComponentHeight: number): void {
    HiLog.i(TAG, `XComponentChangeForStraight E, data: ${xComponentWidth} ${xComponentHeight}.`);
    if (this.isNeedUpdateLayoutService) {
      this.mAdaptiveLayoutService.calLayoutRuleParam(this.windowWidth, this.windowHeight);
      this.isNeedUpdateLayoutService = false;
    }
    this.mAdaptiveLayoutService.changePreviewPosition(xComponentWidth, xComponentHeight);
    this.newPreviewAnimatePosition =
      { x: (this.windowWidth - this.xComponentWidth) / 2, y: this.mAdaptiveLayoutService.previewPosition };
    HiLog.i(TAG, `XComponentChangeForStraight X, previewPos: ${this.previewAnimatePosition.y}.` +
      ` newPos: ${this.newPreviewAnimatePosition.y}`);
  }

  /**
   * 圆形外屏设备状态预览位置计算逻辑
   */
  private updateNewPreviewAnimatePositionForExtCircleScreenCollapsed(xComponentWidth: number,
    xComponentHeight: number): void {
    this.smallSubDisplayWidth = this.isPSDCollapsed ? DISPLAY_SCREEN_SIZE_PSD : DISPLAY_SCREEN_SIZE_LEM;
    this.newPreviewAnimatePosition = {
      x: (this.smallSubDisplayWidth - xComponentWidth) >> 1,
      y: (xComponentHeight - this.smallSubDisplayWidth) >> 1
    };
  }

  /**
   * 展开态预览计算逻辑
   * @param xComponentWidth 预览宽度
   * @param xComponentHeight 预览高度
   */
  private UpdatePreviewPositionForLandscape(xComponentWidth: number, xComponentHeight: number): void {
    HiLog.i(TAG, `XComponentChangeForLandscape E, data: ${xComponentWidth} ${xComponentHeight}.`);
    const windowServiceInstance = WindowService.getInstance();
    if (windowServiceInstance.isVertical()) {
      if (Math.abs(xComponentWidth / xComponentHeight - NUMBER_4_3) < NUMBER_MIN) {
        this.newPreviewAnimatePosition = { x: 0, y: 0 };
      } else {
        this.newPreviewAnimatePosition = {
          x: (windowServiceInstance.getWindowAndXComDiffer(this.windowWidth, xComponentWidth)) >> 1,
          y: (windowServiceInstance.getWindowAndXComDiffer(this.windowHeight, xComponentHeight)) >> 1
        };
      }
    } else {
      this.newPreviewAnimatePosition = {
        x: (windowServiceInstance.getWindowAndXComDiffer(this.windowWidth, xComponentWidth)) >> 1,
        y: (windowServiceInstance.getWindowAndXComDiffer(this.windowHeight, xComponentHeight)) >> 1
      };
    }
  }

  /**
   * 展开态预览计算逻辑，始终居中
   * @param xComponentWidth 预览宽度
   * @param xComponentHeight 预览高度
   */
  private UpdatePreviewPositionForTriCollaps(xComponentWidth: number, xComponentHeight: number): void {
    HiLog.i(TAG, `XComponentChangeForTriCollaps E, data: ${xComponentWidth} ${xComponentHeight}.`);
    const windowServiceInstance = WindowService.getInstance();
    this.newPreviewAnimatePosition = {
      x: (windowServiceInstance.getWindowAndXComDiffer(this.windowWidth, xComponentWidth)) >> 1,
      y: (windowServiceInstance.getWindowAndXComDiffer(this.windowHeight, xComponentHeight)) >> 1
    };
  }

  /**
   * 预览轻微上移动效，防止截断，触发场景：人像模式1：1，打开extend bar
   * @param data extend bar相关数据
   */
  private previewAvoidingMotion(data: ExtendBarData): void {
    if (!this.isShowDefault) {
      return;
    }
    HiLog.i(TAG, 'previewAvoidingMotion E.');
    this.mAction.updateExtendBarPosition();
    if (
      !this.mAdaptiveLayoutService.isEqual(this.xComponentWidth, this.xComponentHeight) || this.isHalfCollapsLEM) {
      return;
    }
    if (WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) {
      return;
    }
    this.mAdaptiveLayoutService.previewAvoidingMotion(this.xComponentHeight, data);
    if (Math.abs(this.newPreviewAnimatePosition.y - this.mAdaptiveLayoutService.previewPosition) > 1e-5) {
      HiLog.begin(TAG, 'previewAvoidingMotionAnimate');
      animateToImmediately({
        curve: AnimSpecifications.ANIM_PREVIEW_AREA_UP_OR_DOWN,
        duration: 500,
        onFinish: () => {
          HiLog.end(TAG, 'previewAvoidingMotionAnimate');
        }
      }, () => {
        this.previewAnimatePosition.y = this.mAdaptiveLayoutService.previewPosition;
      });
      this.newPreviewAnimatePosition = this.previewAnimatePosition;
    }
    HiLog.i(TAG, `previewAvoidingMotion end, previewPos: ${this.previewAnimatePosition}.`);
  }

  /**
   * 修改窗口大小业务逻辑统一入口
   * @param xComponentSize 预览目标大小
   * @param mode 指定模式，可选，若不传入则从Reducer中取值
   */
  private changeXComponentSizeAuto(xComponentSize: XComponentSize, mode?: ModeType): void {
    HiLog.i(TAG,
      `changeXComponentSizeAuto E, data: ${xComponentSize.xComponentWidth} ${xComponentSize.xComponentHeight}.`);
    mode = mode ?? getStates().get<ModeType>('modeReducer', 'mode');
    const collapsStatus: display.FoldStatus = DisplayService.getInstance().getCollapsStatus();
    const isUIExtensionPicker: boolean =
      GlobalContext.get().getIsPicker() && !!ContextManager.getInstance().getUiExtensionContext();
    this.onXComponentSizeChange(xComponentSize.xComponentWidth, xComponentSize.xComponentHeight);
    this.mAction.changeXComponentSize(xComponentSize.xComponentWidth, xComponentSize.xComponentHeight);
  }

  /**
   * 计算低角度拍摄时的预览大小
   */
  private changeLowAngleXComponentSize(): void {
    const isPanVideoOutput = OutputOperation.isPanVideoOutput(this.mode);
    const semiWidth = this.windowWidth / 2;
    const semiHeight = semiWidth * (this.xComponentHeight / this.xComponentWidth);
    let newSemiHeight = semiHeight;
    let newSemiWidth = semiWidth;
    if (isPanVideoOutput && this.isShowLowAngleShotView &&
      Math.abs(semiWidth / semiHeight - 9 / 16) < EPSILON) {
      let scaleLength = (COMPONENT_WIDTH + FOOT_BAR_COL) - (this.windowHeight - semiHeight) / 2;
      newSemiHeight = (semiHeight - scaleLength * 2);
      newSemiWidth = semiWidth * (newSemiHeight / semiHeight);
    }
    this.onXComponentSizeChange(newSemiWidth, newSemiHeight);
    this.mAction.changeXComponentSize(newSemiWidth, newSemiHeight);
    this.mAction.changePreviewSizeAnim();
  }

  private getTabletPreviewPosition(): PositionType {
    let isPreviewAreaMiddle: boolean = false;
    if (WindowService.getInstance().isVertical() || (this.windowWidth - this.xComponentWidth) / 2 >= COMPONENT_WIDTH) {
      isPreviewAreaMiddle = true;
    }
    HiLog.i(TAG, `tablet previewArea isMiddle: ${isPreviewAreaMiddle}.`);
    const windowServiceInstance: WindowService = WindowService.getInstance();
    return {
      x: isPreviewAreaMiddle ?
        (windowServiceInstance.getWindowAndXComDiffer(this.windowWidth, this.xComponentWidth)) >> 1 : 0,
      y: (windowServiceInstance.getWindowAndXComDiffer(this.windowHeight, this.xComponentHeight)) >> 1,
    };
  }

  build() {
    PreviewArea({
      isHdr: this.isHdr,
      buildFromPicker: this.buildFromPicker
    })
      // .backgroundColor(Color.White)
      .key(ComponentIdKeys.PREVIEW_WINDOW_1)
      .id(ComponentIdKeys.PREVIEW_WINDOW_1)
      .position(this.previewAnimatePosition)
      .align(Alignment.Center)
      .visibility(this.showPicker ? Visibility.Hidden : Visibility.Visible)
      .accessibilityLevel(this.isShowMorePage ? CommonConstants.ACCESSIBILITY_LEVEL_NO_HIDE_DESCENDANTS :
      CommonConstants.ACCESSIBILITY_LEVEL_AUTO)
      .hitTestBehavior(HitTestMode.Transparent)
      .rotate({ angle: this.isLemCollaps || this.isPSDCollapsed ? 180 : 0 })
  }
}