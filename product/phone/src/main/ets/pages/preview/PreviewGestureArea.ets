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

import lazy { Action, ActionData, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { UIOperationType } from "@ohos/common/src/main/ets/component/uicomponent/UIOperationType";
import lazy { RecordAction, RecordingState } from "@ohos/common/src/main/ets/function/recordcontrol/RecordAction";
import lazy { BlurAnimateUtil } from "@ohos/common/src/main/ets/utils/BlurAnimateUtil";
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { ZoomParam } from '@ohos/common/src/main/ets/function/zoombar/ZoomParam';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy {
  Dispatch,
  execDispatch,
  getStates,
  reduxSubscribe,
  Unsubscribe
} from '@ohos/common/src/main/ets/redux/Store';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { ZoomAction } from '@ohos/common/src/main/ets/function/zoombar/ZoomAction';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import lazy { TabBarAction } from '@ohos/common/src/main/ets/component/tabbar/TabBarAction';
import lazy { ThumbnailView } from '@ohos/common/src/main/ets/component/thumbnail/ThumbnailView';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';
import lazy { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import lazy { camera } from '@kit.CameraKit';
import lazy { ZoomOperation } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import lazy { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import lazy { OutputSwitcher } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcher';
import lazy { PhotoFormatMode } from '@ohos/common/src/main/ets/function/enumbase/PhotoFormatMode';
import lazy { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import lazy { ZoomFuncValueStruct } from './PreviewArea';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import lazy { MIN_LOADING_MODE_DURATION } from '@ohos/common/src/main/ets/function/capture/ShutterButton';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { proSonChangeNumberData } from '@ohos/common/src/main/ets/utils/types';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { CaptureAction } from '@ohos/common/src/main/ets/function/capture/CaptureAction';
import lazy { TimeLapseAction } from '@ohos/extend/src/main/ets/settingcommonfunc/timelapse/TimeLapseAction';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { CaptureActionType } from '@ohos/common/src/main/ets/redux/actions/CaptureActionType';
import lazy { FocusExposureArea } from '@ohos/extend/src/main/ets/commonfunc/focus/FocusExposureArea';
import lazy { PreviewAction } from '@ohos/common/src/main/ets/redux/actions/PreviewAction';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { PositionType } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper';
import lazy { DISPLAY_SCREEN_SIZE_PSD } from './PreviewWrap';
import { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import { CameraAction } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';

/* instrument ignore file */
const TAG: string = 'PreviewGestureArea';

const ISO_CUTOFF_VALUE_JPG: number = 12800;
const PRO_SHUTTER_THRESHOLD: number = 1000000;
const SMALL_SCREEN_THUMBNAIL_POSITION_X: number = 30;
const SMALL_SCREEN_THUMBNAIL_POSITION_Y: number = 131;
const TIME_OUT_NUM: number = 2000;

interface ProShutterValue {
  functionId: FunctionId,
  value: number
}

class PreviewGestureAreaDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public uiEnabled(): void {
    this.mDispatch(Action.uiState(true));
  }
}

@Component
export struct PreviewGestureArea {
  private base: BaseComponent = new BaseComponent();
  private subscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private eventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mAction: PreviewGestureAreaDispatcher = new PreviewGestureAreaDispatcher();
  private readonly pinchToNextZoomScale = 1.25;
  private readonly pinchToPrevZoomScale = 0.75;
  @LocalStorageLink('previewAnimatePosition') previewAnimatePosition: PositionType = { x: 0, y: 0 };
  // 前置捏合时是否支持切换变焦
  private frontPinchCanUpdate: boolean = false;
  @State mode: ModeType = ModeType.NONE;
  @State proShutterValue: number = 0;
  private proListExpansion: boolean = false
  private prosonNumber: number = -1;
  @StorageLink('isLemCollaps') isLemCollaps: boolean = false;
  @StorageLink('isPSDCollaps') isPSDCollapsed: boolean = false;
  @State isShowtimeLapse: boolean = false;
  @State cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  private baseZoom: number = 0;
  // 夜景拍照显示参考线、水平仪
  @StorageLink('isNightShutting') isNightShutting: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State isShowNightInfo: boolean = false;
  @StorageLink('isDownSuperSlowBtnState') isDownSuperSlowBtn: boolean = false;
  @State isPanoramaStart: boolean = false;
  @State isDepthFusionBarShow: boolean = false;
  @Prop immersiveUIType: UIOperationType = UIOperationType.NULL;
  @LocalStorageLink('isLemModeSwitched') isLemModeSwitched: boolean = true;
  @Prop isHdr: boolean = false;
  @State isShowMotionDetection: boolean = false; // 慢动作相关
  @State isShowMorePage: boolean = false; // 显示更多功能
  @State mDirection: WindowDirection = WindowDirection.TOP;
  private longClicked: boolean = false;
  @State @Watch('changeTimeShot') isShowTimedShot: boolean = false;
  @State timedShotThumbnail: boolean = true;

  aboutToAppear(): void {
    this.subscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isShowtimeLapse = state.get<boolean>('settingReducer', 'isShowtimeLapse');
      this.cameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isShowMotionDetection = state.get<boolean>('motionReducer', 'isShowMotionBox');
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.isShowTimedShot = state.get<boolean>('settingReducer', 'isShowTimedShot');
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.longClicked = state.get<boolean>('leftRightSwipeReducer', 'longClicked');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });

    const code: string = this.base.hashCode();
    this.eventBus.on(ActionType.ACTION_PROSON_CHANGE_STATE, (data: proSonChangeNumberData) => this.prosonChange(data),
      code);
    this.eventBus.on(ActionType.ACTION_IS_START_PANORAMA, this.onStartPanorama.bind(this), code);
    this.eventBus.on(ActionType.ACTION_IS_END_PANORAMA, this.onEndPanorama.bind(this), code);
    this.eventBus.on(ActionType.ACTION_ON_PHOTO_STOP_PANORAMA, this.onPanoramaPhotoStop.bind(this), code);
    this.eventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.CHANGE_OUTPUT_TYPE, CaptureActionType.CAPTURE,
      ActionType.ACTION_CHANGE_X_COMPONENT_SIZE, CameraActionType.RESTART, CameraActionType.SWITCH_CAMERA_CHANGE_MODE,
      CameraActionType.SWITCH_CAMERA, ActionType.ACTION_NIGHT_CAPTURE_START], this.resetPage.bind(this), code);
  }

  aboutToDisappear(): void {
    this.eventBus.clear(this.base.hashCode());
    this.subscriber.destroy();
  }

  private resetPage(): void {
    this.isDepthFusionBarShow = false;
  }

  private handleDepthFusionBarVisibility(data: ActionData): void {
    const targetShowState: boolean = data['isShow'];
    this.isDepthFusionBarShow = targetShowState;
    HiLog.i(TAG, `preview get depthFusion bar show state: ${this.isDepthFusionBarShow}`);
  }

  private onStartPanorama(): void {
    this.isPanoramaStart = true;
  }

  private onEndPanorama(): void {
    if (!this.isPanoramaStart) {
      return;
    }
    this.isPanoramaStart = false;
  }

  public onPanoramaPhotoStop(): void {
    if (!this.isPanoramaStart) {
      return;
    }
    this.isPanoramaStart = false;
  }

  private prosonChange(data: proSonChangeNumberData): void {
    this.prosonNumber = data.iconId;
  }

  private onPreviewClicked(): void {
    HiLog.i(TAG, `Click preview called. isShowtimeLapse: ${this.isShowtimeLapse}, state.mode: ${this.mode}.`);
    if (OutputOperation.isPanPhotoOutput(this.mode) && this.isShowtimeLapse) {
      execDispatch(Action.changeTimeLapse(false));
      const estimateDuration: number = getStates().get<number>('contextReducer', 'estimatedCaptureDuration');
      execDispatch(CaptureAction.capture());
      execDispatch(FunctionAction.changeFunctionValue(FunctionId.CAPTURE, true));
    } else if (OutputOperation.isPanVideoOutput(this.mode) && this.isShowtimeLapse) {
      execDispatch(Action.changeTimeLapse(false));
      execDispatch(TimeLapseAction.startVideoAnim());
      execDispatch((Action.uiStateWithMode(false, UiStateMode.EXCLUDE_PREVIEW)));
      execDispatch((RecordAction.start()));
      execDispatch(FunctionAction.changeFunctionValue(FunctionId.RECORD_CONTROL, 0));
      execDispatch(Action.changeTimelapseVideoState());
    }
  }

  private pinchGestureStart(event: GestureEvent): void {
    if (getStates().get<FunctionId>('tabBarReducer', 'tabBarSelector') !== FunctionId.NONE) {
      execDispatch(TabBarAction.changeTabBarSelector(FunctionId.NONE, RenderLocation.NONE));
    }
    if (this.prosonNumber !== -1) {
      execDispatch(Action.proSonChangeState(-1));
      this.proListExpansion = true;
      return;
    }
    HiLog.i(TAG, 'pinchGestureStart E.');
    if (!this.isSupportTwoFingerZoom()) {
      return;
    }
    if(!this.isSupportedZoomWhenOpenStabilization()) {
      return;
    }
    this.baseZoom = getStates().get<number>('zoomReducer', 'zoomRatio');
    this.frontPinchCanUpdate = true;
    HiLog.i(TAG, 'pinchGestureStart X.');
  }

  private pinchGestureUpdate(event: GestureEvent): void {
    const isFront: boolean = (this.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT &&
      !CameraAppCapability.getInstance().getIsSupportedFrontZoomSlide());
    if (this.proListExpansion) {
      HiLog.i(TAG, 'isNotVdeShowBackAsFront return.');
      return;
    }
    const isHideZoomView: boolean =
      ZoomOperation.getRingZoomUIState(this.cameraPosition, this.mode)?.opticalZoomValArr.length <= 1;
    if (this.noPinchGesture(isFront, isHideZoomView)) {
      HiLog.i(TAG, 'noPinchGesture return.');
      return;
    }
    HiLog.i(TAG, 'pinchGestureUpdate invoke, setZoomRatio.');
    if (!this.isSupportTwoFingerZoom()) {
      HiLog.i(TAG, 'isNotSupportTwoFingerZoom return.');
      return;
    }
    if (isFront) {
      if (!this.frontPinchCanUpdate) {
        HiLog.i(TAG, 'frontPinchCanUpdate return.');
        return;
      }
      if (event.scale >= this.pinchToNextZoomScale) {
        this.frontPinchCanUpdate = false;
        execDispatch(ZoomAction.switchZoomRatio(true));
      }
      if (event.scale <= this.pinchToPrevZoomScale) {
        this.frontPinchCanUpdate = false;
        execDispatch(ZoomAction.switchZoomRatio(false));
      }
      HiLog.i(TAG, 'isVdeShowBackAsFront return.');
      return;
    }

    let zoomRatio = event.scale * this.baseZoom;
    if (zoomRatio > getStates().get<number>('zoomReducer', 'maxZoomRatio')) {
      zoomRatio = getStates().get<number>('zoomReducer', 'maxZoomRatio');
    }
    if (zoomRatio < getStates().get<number>('zoomReducer', 'minZoomRatio')) {
      zoomRatio = getStates().get<number>('zoomReducer', 'minZoomRatio');
    }
    if (!zoomRatio) {
      HiLog.i(TAG, 'zoomRatio Unavailable return.');
      return;
    }
    zoomRatio = Number.parseFloat(zoomRatio.toFixed(3));
    if (zoomRatio !== getStates().get<number>('zoomReducer', 'zoomRatio')) {
      execDispatch(FunctionAction.changeFunctionValue(FunctionId.ZOOM,
        { zoomRatio: zoomRatio } as ZoomFuncValueStruct));
    }
    let preZoomRatio = getStates().get<number>('zoomReducer', 'zoomRatio').toFixed(1);
    let curZoomRatio = zoomRatio.toFixed(1);
    if ((curZoomRatio !== preZoomRatio) &&
      (getStates().get<number>('recordReducer', 'recordingState') === RecordingState.READY) &&
    DeviceInfo.isPcAndTablet()) {
      VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
    }
    HiLog.i(TAG, 'pinchGestureUpdate end.');
  }

  private noPinchGesture(isFront: boolean, isHideZoomView: boolean): boolean {
    HiLog.i(TAG, 'pinchGestureUpdate invoke, setZoomRatio.');
    if (getStates().get<boolean>('modeReducer', 'isShowBigText') || this.isShowtimeLapse ||
    getStates().get<boolean>('modeReducer', 'isShowMorePage')) {
      return true;
    }
    if (!this.isSupportedZoomWhenOpenStabilization()) {
      TipService.getInstance().showTip($r('app.string.Steadyshot_zoom_is_not_supported'), 3000, true);
      return true;
    }
    return false;
  }

  private isSupportedZoomWhenOpenStabilization(): boolean {
    return true;
  }

  private getPositivePanDirection(): PanDirection {
    const isShowSemiCollapsed: boolean = getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed');
    const isShowLandScape: boolean = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    if (this.isLemCollaps || (isShowLandScape && !isShowSemiCollapsed) || DeviceInfo.isTablet()) {
      return PanDirection.Up;
    } else if (isShowSemiCollapsed) {
      return SystemLanguageUtil.isRTL() ? PanDirection.Down : PanDirection.Up;
    } else {
      return SystemLanguageUtil.isRTL() ? PanDirection.Right : PanDirection.Left;
    }
  }

  private onPositivePreviewPanGesture(): void {
    if (getStates().get<boolean>('customFilterStyleReducer', 'isCustomFilterImmersive') && !PickerUtils.getIsPicker()) {
      return;
    }
    if (getStates().get<boolean>('proShutterReducer', 'isProShuttering')) {
      return;
    }
    let mode = getStates().get<ModeType>('modeReducer', 'mode');
    if (mode === ModeType.PHOTO) {
      StoreManager.getInstance().postMessage(CameraAction.changeMode(ModeType.VIDEO));
      VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
    }
    HiLog.i(TAG, 'PositivePreviewPanGesture');
  }

  private getNegativePanDirection(): PanDirection {
    const isShowSemiCollapsed: boolean = getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed');
    const isShowLandScape: boolean = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    if (this.isLemCollaps || (isShowLandScape && !isShowSemiCollapsed) || DeviceInfo.isTablet()) {
      return PanDirection.Down;
    } else if (isShowSemiCollapsed) {
      return SystemLanguageUtil.isRTL() ? PanDirection.Up : PanDirection.Down;
    } else {
      return SystemLanguageUtil.isRTL() ? PanDirection.Left : PanDirection.Right;
    }
  }

  private onNegativePreviewPanGesture(): void {
    if (getStates().get<boolean>('customFilterStyleReducer', 'isCustomFilterImmersive') && !PickerUtils.getIsPicker()) {
      return;
    }
    if (getStates().get<boolean>('proShutterReducer', 'isProShuttering')) {
      return;
    }
    let mode = getStates().get<ModeType>('modeReducer', 'mode');
    let videoState = getStates().get<RecordingState>('recordReducer', 'recordingState');
    if (mode === ModeType.VIDEO && videoState === RecordingState.READY) {
      StoreManager.getInstance().postMessage(CameraAction.changeMode(ModeType.PHOTO));
      VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
    }
    HiLog.i(TAG, 'NegativePreviewPanGesture');
  }

  private isSupportTwoFingerZoom(): boolean {
    if (getStates().get<boolean>('modeReducer', 'isShowBigText') || this.isShowtimeLapse ||
    getStates().get<boolean>('modeReducer', 'isShowMorePage')) {
      return false;
    }
    return true;
  }

  private pinchGestureEnd(): void {
    HiLog.i(TAG, 'pinchGestureEnd E.');
    // 捏合过程中，触发倒计时拍照 倒计时过程中停止捏合 只需更新showpinch为false即可 不用退出沉浸式
    if (getStates().get<boolean>('zoomReducer', 'isShowPinch') && this.isShowtimeLapse) {
      execDispatch(ZoomAction.updateShowPinch(false));
      return;
    }
    if (this.proListExpansion) {
      this.proListExpansion = false;
      return;
    }
    if (ZoomOperation.getRingZoomUIState(this.cameraPosition, this.mode)?.opticalZoomValArr.length <= 1) {
      return;
    }
    if (!this.isSupportTwoFingerZoom()) {
      return;
    }
    if (!this.isSupportedZoomWhenOpenStabilization()) {
      return;
    }
    if ((this.cameraPosition !== camera.CameraPosition.CAMERA_POSITION_FRONT ||
    CameraAppCapability.getInstance().getIsSupportedFrontZoomSlide())) {
      execDispatch(Action.isEnterImmersive(false, UIOperationType.ZOOM_BAR));
    }
    execDispatch(TreasureBoxAction.updateByZoomChanged());
    execDispatch(ZoomAction.updateShowPinch(false));
    HiLog.i(TAG, 'pinchGestureEnd X.');
  }

  // 超慢运动侦测框的拖动范围依赖预览区域的大小以及定位
  // 预览定位：直板机previewPosition，全局状态可得只有y方向，
  // 展开态和悬停态的预览定位只在LandScapeIndex传入且y方向错误只有x方向可用，这里手动处理
  private getSlowMoPreviewBoundary(): PositionType {
    if (getStates().get<boolean>('collapsReducer', 'isShowLandscape')) {
      return {
        x: this.previewAnimatePosition.x,
        y: (getStates().get<number>('windowReducer', 'windowHeight') -
        getStates().get<number>('previewReducer', 'xComponentHeight')) >> 1
      };
    } else {
      return this.previewAnimatePosition;
    }
  }

  private getSubThumbnailPosition(): Position {
    if (this.isPSDCollapsed) {
      if (this.mDirection === WindowDirection.BOTTOM) {
        return { x: SMALL_SCREEN_THUMBNAIL_POSITION_Y, y: SMALL_SCREEN_THUMBNAIL_POSITION_X };
      }
      return { x: SMALL_SCREEN_THUMBNAIL_POSITION_X, y: SMALL_SCREEN_THUMBNAIL_POSITION_Y };
    }
    return { x: SMALL_SCREEN_THUMBNAIL_POSITION_X, y: SMALL_SCREEN_THUMBNAIL_POSITION_Y };
  }

  // 间隔定时拍，拍完照再次拍照显示照片预览按钮或等待自动消失
  private timeOut: number = -1;

  private changeTimeShot(): void {
    if (this.isShowTimedShot) {
      this.timeOut = setTimeout(() => {
        this.timedShotThumbnail = false;
      }, TIME_OUT_NUM)
    } else {
      if (this.timeOut !== -1) {
        clearTimeout(this.timeOut);
        this.timeOut = -1;
      }
      this.timedShotThumbnail = true;
    }
  }

  build() {
    Column() {
      FocusExposureArea({
        isHdr: this.isHdr
      }) {
      }
    }
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .width('100%')
    .height('100%')
    .onTouchIntercept(() => {
      if (this.isShowtimeLapse) {
        return HitTestMode.Block;
      }
      return HitTestMode.Default;
    })
    .onTouch((event: TouchEvent) => {
      if (this.immersiveUIType === UIOperationType.EXPOSURE) {
        return;
      }
      switch (event.type) {
        case TouchType.Move:
          return;
        case TouchType.Down:
          if (getStates().get<number>('recordReducer', 'recordingState') !== RecordingState.RECORDING) {
            BlurAnimateUtil.generatePixelMapFromSurface();
          }
          if (event.touches.length === 2) {
            execDispatch(FunctionAction.changeFunctionValue(FunctionId.ZOOM, {
              zoomRatio: undefined,
              isPrepareZoom: true
            } as ZoomFuncValueStruct));
          }
          return;
        case TouchType.Up:
        case TouchType.Cancel:
          if (event.touches.length === 2) {
            execDispatch(FunctionAction.changeFunctionValue(FunctionId.ZOOM, {
              zoomRatio: undefined,
              isUnprepareZoom: true,
              unprepareDelay: ZoomParam.UNPREPARE_DELAY_TIME
            } as ZoomFuncValueStruct));
          }
      }
    })
    .gesture(
      GestureGroup(
        this.isVdeCollapsed ? GestureMode.Parallel : GestureMode.Exclusive,
        TapGesture({ fingers: 1, count: 1 })
          .onAction(() => this.onPreviewClicked()),
        PinchGesture({ fingers: 2, distance: 1 })
          .onActionStart((event?: GestureEvent) => {
            if (!event) {
              HiLog.i(TAG, 'no event received');
              return;
            }
            if (this.isNightShutting) {
              HiLog.i(TAG, 'no isNightShutting received');
              return;
            }
            if (this.longClicked) {
              return;
            }
            if (this.isLemCollaps) {
              return;
            }
            HiLog.i(TAG, 'PinchGesture onActionStart');
            return this.pinchGestureStart(event);
          })
          .onActionUpdate((event?: GestureEvent) => {
            if (!event || this.isLemCollaps || this.isNightShutting) {
              return;
            }
            if (this.longClicked) {
              return;
            }
            return this.pinchGestureUpdate(event);
          })
          .onActionCancel(() => {
            HiLog.i(TAG, 'onActionCancel');
            this.pinchGestureEnd();
          })
          .onActionEnd((event?: GestureEvent) => {
            if (!event || this.isLemCollaps || (this.isNightShutting)) {
              if (getStates().get<boolean>('zoomReducer', 'isShowPinch')) {
                execDispatch(ZoomAction.updateShowPinch(false));
              }
              return;
            }
            return this.pinchGestureEnd();
          }),
        PanGesture({
          fingers: 1,
          direction: this.getPositivePanDirection(),
          distance: 10
        })
          .onActionStart(() => this.onPositivePreviewPanGesture()),
        PanGesture({
          fingers: 1,
          direction: this.getNegativePanDirection(),
          distance: 10,
        })
          .onActionStart(() => this.onNegativePreviewPanGesture()),
        PanGesture({
          fingers: 1,
          direction: PanDirection.Left | PanDirection.Right,
          distance: 30
        })
          .onActionEnd(() => {
            HiLog.i(TAG, `PanDirection.Down onActionEnd this.isLemCollaps=${this.isLemCollaps}`);
            if (AppStorage.get('isPSDCollaps')) {
              if (getStates().get<number>('recordReducer', 'recordingState') === RecordingState.RECORDING) {
                execDispatch(CaptureAction.captureLemCollaps());
                return;
              } else if (this.isShowtimeLapse) {
                execDispatch(Action.changeTimeLapse(false));
                return;
              }
            }
          })
          .onActionCancel(() => {
            HiLog.i(TAG, `PanDirection.Down onActionCancel this.isLemCollaps=${this.isLemCollaps}`);
          })
      )
    )
  }
}