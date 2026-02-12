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

import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { PositionType, SavePowerModeActionData, Size, XComponentSize } from '@ohos/common/src/main/ets/utils/types';
import lazy { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { PreviewArea } from '../../../../../../tablet/src/main/ets/pages/PreviewArea';
import lazy { ExtendBar } from '../../../../../../tablet/src/main/ets/pages/default/ExtendBar';
import lazy { PickerView } from '../../../../../../tablet/src/main/ets/pages/default/PickerView';
import lazy { FootBar } from '../../../../../../tablet/src/main/ets/pages/default/FootBar';
import lazy {
  FOOT_BAR_HEIGHT,
  MODE_BAR_HEIGHT,
  MIDDLE_COMPONENT_WIDTH
} from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService';
import lazy { BigScreenModeBar } from '@ohos/common/src/main/ets/component/ModeBar/bigScreen/BigScreenModeBar';
import lazy { ParamBar } from '../../../../../../tablet/src/main/ets/pages/default/ParamBar';
import lazy { VideoTimer } from '@ohos/common/src/main/ets/component/videoTimer/VideoTimer';
import lazy { TREASURE_BOX_ELEMENT_INNER_WIDTH } from '@ohos/common/src/main/ets/component/treasurebox/common/DataType';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import camera from '@ohos.multimedia.camera';
import lazy { CameraRunningState } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { FlashMode } from '@ohos/common/src/main/ets/function/enumbase/FlashMode';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { BigText } from '@ohos/common/src/main/ets/component/bigtext/BigText';
import lazy { AlertDialogView } from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/AlertDialogView';
import lazy { PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { ChangeState, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import lazy { RouletteZoomView } from '@ohos/common/src/main/ets/function/zoombar/RouletteZoomView';
import lazy { QUICK_ZOOM_MARGIN_BOTTOM_28 } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { TipBox } from '@ohos/common/src/main/ets/component/tip/TipBox';
import lazy { OutputSwitcher } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcher';
import lazy { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import lazy { AspectRatioFunction } from '@ohos/common/src/main/ets/function/aspectratio/AspectRatioFunction';
import lazy {
  CameraErrorData,
  CameraErrorDialogView,
  CameraErrorDialogViewParams
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/CameraErrorDialogView';
import lazy { DisplayCalculator } from '@ohos/common/src/main/ets/component/xcomponent/DisplayCalculator';
import lazy { RestartService } from '@ohos/common/src/main/ets/service/restart/RestartService';
import power from '@ohos.power';
import screenLock from '@ohos.screenLock';
import lazy { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import lazy { PickerWindowType } from '@ohos/common/src/main/ets/component/picker/PickerWindowType';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import lazy { PreviewGestureArea } from '../../../../../../phone/src/main/ets/pages/preview/PreviewGestureArea';
import lazy { PreviewActionType } from '@ohos/common/src/main/ets/redux/actions/PreviewActionType';
import { TreasureBox } from '@ohos/common/src/main/ets/component/treasurebox/default/TreasureBox';

const TAG: string = 'TabletSplitScreenIndex';

export const COMPONENT_WIDTH: number = 94;

const NUM_16: number = 16;
const NUM_9: number = 9;
const NUM_4: number = 4;
const NUM_3: number = 3;
const NUM_1: number = 1;

export const FULL_LENGTH: string = '100%';

const BIG_TEXT_TOP_MARGIN: number = 500;
const VIDEO_TIMER_TOP_MARGIN: number = 40;
const NUMBER_16_9: number = 0.5625;

const TREASURE_BOX_HEIGHT_VERTICAL: number = 296;
const TREASURE_BOX_HEIGHT_HORIZONTAL: number = 296;

class StateStruct {
  public isShowBigText: boolean = false;
  public isShowPageView: boolean = false;
  public isFloatingShutterShow: boolean = false;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_BACK;
  public isShowParamBar: boolean = false;
  public isShowExtendBar: boolean = false;
  public cameraRunningState: CameraRunningState = CameraRunningState.UNINITIALIZED;
  public videoState: RecordingState = RecordingState.READY;
  public uiEnable: boolean = false;
}

class IndexDispatcher {
  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public confirmLocationTOSettingPermission(isRequestOnSetting: boolean): void {
    this.mDispatch(Action.confirmLocationTOSettingPermission(isRequestOnSetting));
  }

  private mDispatch: Dispatch = (data) => data;
}

class ShowParm {
  public showModeBar: boolean = false;
}

@Component
export struct TabletSplitScreenIndex {
  @State state: StateStruct = new StateStruct();
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @State videoState: RecordingState = RecordingState.READY;
  @State loadSurfaceDone: boolean = true;
  @State mode: ModeType = ModeType.NONE;
  // ux位置适配
  @State bigTextPosition: number = 0;
  @State componentPosition: number = 0; //footBar modeBar位置
  @State rouletteZoomViewPositionX: number = 0;
  @State rouletteZoomViewPositionY: number = 0;
  @State treasureBoxTopMargin: number = 0;
  @State footBarPositionY: number = 0;
  @State modeBarPositionY: number = 0;
  // VideoTimer
  @State showTimer: boolean = false;
  @State timerOpacity: number = 0;
  @State @Watch('timerStateOnChange') videoTimerState: boolean = false;
  @State videoTimerVisible: boolean = false;
  @State videoTimerPosition: number = VIDEO_TIMER_TOP_MARGIN;
  // 沉浸式
  @Prop immersiveUIType: UIOperationType = UIOperationType.NULL;
  @Prop immersiveOpacity: number = 1;
  // 获取屏幕大小
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State xComponentWidth: number = 0;
  @State xComponentHeight: number = 0;
  // Picker
  @State isPicker: boolean = true;
  @State showPicker: boolean = false;
  @State isShowMorePage: boolean = false;
  @State isEditMorePage: boolean = false;
  @State development: boolean = true;
  @State footBarAnimatePosition: PositionType = { x: 0, y: 0 }; //缩略图,快门,前后置切换动画效果定位
  @State isShowTextInfo: boolean = false;
  @State treasureBoxLeftMargin: number = 0;
  @State treasureBoxHeight: number = TREASURE_BOX_HEIGHT_VERTICAL;
  @State paramBarPositionX: number = 0;
  @State modeBarRightMargin: number = 0;
  @State lumationValue: number = 101;
  @State rotateAngle: number = 0;
  @State zoomOpacity: number = 0;
  @State footOpacity: number = 0;
  @State modeOpacity: number = 0;
  @State paramOpacity: number = 0;
  @State extendOpacity: number = 0;
  @State showModeBar: boolean = true;
  @State isShowTreasureBox: boolean = true;
  @State isShowModeBar: boolean = true;
  @State isShowLowBatteryExitFlash: boolean = false;
  @State @Watch('lowBatteryExitFlashDialogShow') isFlashEnable: boolean = true;
  @State isLowBatteryTipShowed: boolean = false;
  @State exitTimer: number = 5;
  @State aspectRatioType: number = 1;
  // Picker状态
  @State pickerWindowType: PickerWindowType = PickerWindowType.TABLET_FULL_SCREEN;
  @LocalStorageLink('previewAnimatePosition') previewAnimatePosition: PositionType = { x: 0, y: 0 };
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mAction: IndexDispatcher = new IndexDispatcher();
  // 相机异常弹窗
  private cameraErrorDialogController: CustomDialogController | null = null;
  private isShowCameraError: boolean = false;
  //温控弹窗
  private exitCameraDialogController: CustomDialogController | null = null;
  private session: UIExtensionContentSession | undefined = undefined;

  aboutToAppear(): void {
    this.mEventBus.on(CameraActionType.ERROR, (data: CameraErrorData) => this.cameraErrorDialogShow(data.code),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.ON_SIZE_CHANGE, this.uxInit.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.UPDATE_SAVE_POWER_MODE_STATE, (data: SavePowerModeActionData) =>
    this.updateSavePowerModeState(data), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_EXIT_FLASH_DIALOG, () => this.exitFlashDialogShow(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_EXIT_CAMERA_DIALOG, () => this.exitCameraDialogShow(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LOW_BATTERY_SHOW_EXIT_FLASH_DIALOG,
      () => this.lowBatteryExitFlashDialogShow(), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHANGE_X_COMPONENT_SIZE,
      () => this.getXComponentSize(), this.mBase.hashCode());
    this.mEventBus.on(PreviewActionType.LOAD_SURFACE_DONE, () => this.checkXComponentLock(), this.mBase.hashCode());
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.videoTimerState = state.get<boolean>('recordReducer', 'videoTimerState');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.isEditMorePage = state.get<boolean>('modeReducer', 'isEditMorePage');
      this.isFlashEnable = state.get<boolean>('uiReducer', 'isFlashEnable');
      changeState(this.state, {
        isShowBigText: state.get<boolean>('modeReducer', 'isShowBigText'), // 是否显示大字体
        isShowPageView: state.get<boolean>('settingViewReducer', 'isShowSettingView'),
        isFloatingShutterShow: state.get<boolean>('settingReducer', 'isFloatingShutterShow'),
        isShowParamBar: state.get<boolean>('uiReducer', 'isShowParamBar'),
        isShowExtendBar: state.get<boolean>('uiReducer', 'isShowExtendBar'),
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        cameraRunningState: state.get<CameraRunningState>('cameraReducer', 'cameraRunningState'),
        videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
        uiEnable: state.get<boolean>('contextReducer', 'uiEnable'),
      });
      this.showPicker = state.get<boolean>('uiReducer', 'showPicker');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.pickerWindowType = state.get<PickerWindowType>('windowReducer', 'pickerWindowType');
      this.aspectRatioType = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue() as number;
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.uxInit();
    this.getXComponentSize();
  }

  private checkXComponentLock(): void {
    WindowService.getInstance().lockXComponentSurface();
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  @Builder
  PreviewGestureBuilder() {
    PreviewGestureArea({
      immersiveUIType: this.immersiveUIType
    })
      .width(this.xComponentWidth)
      .height(this.xComponentHeight)
      .position(this.previewAnimatePosition)
      .hitTestBehavior(HitTestMode.Transparent)
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {

      RouletteZoomView({
        zoomWidth: this.getRouletteZoomWidth(),
        zoomHeight: 150,
        drawHeight: 95
      })
        .position({
          x: this.rouletteZoomViewPositionX,
          y: this.rouletteZoomViewPositionY
        })
        .key(ComponentIdKeys.RING_ZOOM_BAR)
        .opacity(!this.isShowMorePage && this.immersiveUIType === UIOperationType.ZOOM_BAR ? 1 : this.immersiveOpacity)
        .hitTestBehavior(HitTestMode.Transparent)
        .visibility(this.getZoomVisible())
        .rotate({ angle: 90, centerX: 40 })

      FootBar({
        isPicker: this.isPicker,
        footBarScale: 1
      })
        .opacity(!this.isShowMorePage && (this.immersiveUIType === UIOperationType.FOOT_BAR ||
          this.immersiveUIType === UIOperationType.LR_SWIPE) ? 1 : this.immersiveOpacity)
        .visibility(this.isFootBarVisible() ? Visibility.Visible : Visibility.Hidden)
        .position({
          x: this.componentPosition,
          y: this.footBarPositionY
        })

      BigScreenModeBar()
        .hitTestBehavior(HitTestMode.Default)
        .opacity(this.immersiveUIType === UIOperationType.MODE_BAR ? 1 : this.immersiveOpacity)
        .visibility(!this.isEditMorePage && (this.immersiveUIType === UIOperationType.MODE_BAR ||
          this.immersiveOpacity !== 0) && !this.showTimer && this.isShowModeBar ? Visibility.Visible :
        Visibility.Hidden)
        .position({
          x: this.componentPosition - 5,
          y: this.modeBarPositionY
        })

      // 非以下场景显示tip：沉浸式下的变焦（录像模式除外）以及倒计时拍照
      if (!(this.immersiveOpacity == 0 &&
        ((this.immersiveUIType === UIOperationType.ZOOM_BAR ||
          this.immersiveUIType === UIOperationType.PINCH_ZOOM) && this.mode !== ModeType.VIDEO ||
          this.immersiveUIType === UIOperationType.TIMELAPSE))) {
        TipBox({
          isShowTextInfo: this.isShowTextInfo,
          landscapePreviewPosition: this.previewAnimatePosition,
        })
      }

      TreasureBox({  })
        .position({ x: this.treasureBoxLeftMargin, y: this.treasureBoxTopMargin })
        .opacity(this.immersiveUIType === UIOperationType.ZOOM_BAR ? 1 : this.immersiveOpacity)
        .visibility(!this.isShowMorePage && (this.immersiveUIType === UIOperationType.MODE_BAR ||
          this.immersiveOpacity !== 0) && this.isShowTreasureBox ? Visibility.Visible : Visibility.Hidden)

      if (!this.isShowMorePage && this.state.isShowParamBar &&
        this.state.cameraRunningState === CameraRunningState.STARTED) {
        ParamBar({ isPicker: this.isPicker })
          .opacity(!this.isShowMorePage && this.immersiveUIType === UIOperationType.PARAM_BAR ? 1 :
          this.immersiveOpacity)
          .hitTestBehavior(HitTestMode.Transparent)
          .visibility(!this.isShowMorePage && !this.state.isShowBigText && this.immersiveOpacity !== 0 &&
            this.state.cameraRunningState === CameraRunningState.STARTED ? Visibility.Visible : Visibility.Hidden)
          .position({ x: this.paramBarPositionX, y: 0 })
      }

      if (!this.isShowMorePage && this.state.isShowExtendBar &&
        this.state.cameraRunningState === CameraRunningState.STARTED) {
        ExtendBar()
          .height('100%')
          .opacity(!this.isShowMorePage && this.immersiveUIType === UIOperationType.EXTEND_BAR ? 1 :
          this.immersiveOpacity)
          .visibility(!this.isShowMorePage && (this.immersiveUIType === UIOperationType.EXTEND_BAR ||
            this.immersiveOpacity !== 0) &&
            !this.state.isShowBigText &&
            this.state.cameraRunningState === CameraRunningState.STARTED ? Visibility.Visible : Visibility.Hidden)
          .position({ x: this.paramBarPositionX, y: 0 })
          .zIndex(ZIndex.MIDDLE_TOP)
      }

      if (!this.isShowMorePage && this.showTimer) {
        VideoTimer({
          videoTimerPosition: this.videoTimerPosition
        })
          .width('100%')
          .height('100%')
          .opacity(this.timerOpacity)
          .hitTestBehavior(HitTestMode.None)
          .visibility(this.videoTimerState ? Visibility.Visible : Visibility.Hidden)
      }

      if (this.isPicker) {
        PickerView({
          previewPosition: this.previewAnimatePosition,
          buttonPosition: this.footBarAnimatePosition
        })
          .visibility(this.showPicker ? Visibility.Visible : Visibility.Hidden)
          .zIndex(ZIndex.TOP)
      }

      if (this.state.isShowBigText && !this.isShowMorePage) {
        Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
          BigText()
            .border({ color: Color.Transparent })
        }
        .width(this.windowWidth)
        .height(this.windowHeight)
        .touchable(false)
      }
    }
    .width(FULL_LENGTH)
    .height(FULL_LENGTH)
  }

  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };

  private updateSavePowerModeState(data: SavePowerModeActionData) {
    if (data.isDuringSavePowerMode) {
      this.exitCameraDialogController?.close();
    }
  }

  private isPreviewAreaMiddle(xComponentWidth: number): boolean {
    if (WindowService.getInstance().isVertical()) {
      return true;
    }
    return (this.windowWidth - xComponentWidth) / 2 > COMPONENT_WIDTH ? true : false;
  }

  private getRouletteZoomWidth(): number {
    if (this.pickerWindowType === PickerWindowType.TABLET_1_3_SPLIT_SCREEN) {
      return 0.75 * this.windowHeight;
    }
    if (this.pickerWindowType === PickerWindowType.TABLET_TOP_BOTTOM_HALF_SPLIT_SCREEN) {
      return 0.5 * this.windowHeight;
    }
    if (this.pickerWindowType === PickerWindowType.TABLET_FULL_SCREEN) {
      if (DisplayService.getInstance().isOrientationVertical()) {
        return 0.28 * this.windowHeight;
      } else {
        const blackSideBlack16to9TopBottom: number = (this.windowHeight - this.windowWidth * NUMBER_16_9) / 2;
        const remainingAreaHeight: number = this.windowHeight - blackSideBlack16to9TopBottom * 2 - 32;
        return remainingAreaHeight * 0.44;
      }
    }
    return 0.43 * this.windowHeight;
  }

  private getRouletteZoomViewPositionX(): number {
    if (this.pickerWindowType === PickerWindowType.TABLET_1_3_SPLIT_SCREEN) {
      return 0;
    }
    return this.treasureBoxLeftMargin - 24;
  }

  private getRouletteZoomViewPositionY(): number {
    if (this.pickerWindowType === PickerWindowType.TABLET_TOP_BOTTOM_HALF_SPLIT_SCREEN) {
      return 0.43 * this.windowHeight;
    }
    if (this.pickerWindowType === PickerWindowType.TABLET_LEFT_RIGHT_SPLIT_SCREEN) {
      return 0.5 * this.windowHeight;
    }
    if (this.pickerWindowType === PickerWindowType.TABLET_1_3_SPLIT_SCREEN) {
      return 0.125 * this.windowHeight;
    }
    if (this.pickerWindowType === PickerWindowType.TABLET_FULL_SCREEN) {
      if (DisplayService.getInstance().isOrientationVertical()) {
        return 0.525 * this.windowHeight;
      } else {
        const blackSideBlack16to9TopBottom: number = (this.windowHeight - this.windowWidth * NUMBER_16_9) / 2;
        return this.windowHeight - blackSideBlack16to9TopBottom - this.getRouletteZoomWidth() - 16;
      }
    }
    return 0.57 * this.windowHeight;
  }

  private getModeBarPositionY(): number {
    const spaceTopBottom: number = (this.windowHeight - this.getFootBarHeight()) / 2;
    if (spaceTopBottom >= MODE_BAR_HEIGHT) {
      if (this.pickerWindowType === PickerWindowType.TABLET_FULL_SCREEN &&
      DisplayService.getInstance().isOrientationVertical()) {
        return this.footBarPositionY + this.getFootBarHeight() + 6;
      }
      return this.footBarPositionY + this.getFootBarHeight() + (spaceTopBottom - MODE_BAR_HEIGHT) / 2;
    }
    return this.windowHeight - MODE_BAR_HEIGHT + 24;
  }

  private isFootBarVisible(): boolean {
    if (this.isShowMorePage) {
      return false;
    }
    return this.immersiveUIType === UIOperationType.FOOT_BAR ||
      this.immersiveUIType === UIOperationType.LR_SWIPE ||
      this.immersiveOpacity !== 0;
  }

  private getZoomVisible(): number {
    // 非变焦组件引起的沉浸式模式
    if (this.immersiveUIType !== UIOperationType.ZOOM_BAR && this.immersiveOpacity === 0) {
      return Visibility.Hidden;
    }
    // 更多模式
    if (this.isShowMorePage) {
      return Visibility.Hidden;
    }
    // 前置
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      return Visibility.Hidden;
    }
    return Visibility.Visible;
  }

  private getPreviewXPostion(data: XComponentSize): number {
    if (WindowService.getInstance().isVertical() && this.mode !== ModeType.VIDEO && OutputSwitcher.getInstance()
      .getOutput(this.mode) !== OutputType.VIDEO_OUTPUT && this.aspectRatioType !== AspectRatioFunction.RATIO_NUM_3) {
      return 0;
    } else {
      return this.isPreviewAreaMiddle(this.xComponentWidth) ? (this.windowWidth - data.xComponentWidth) >> 1 : 0;
    }
  }

  private getXComponentSize(): void {
    let previewAspectRatio =
      this.aspectRatioType === 1 ? (NUM_4 / NUM_3) : (this.aspectRatioType === 2 ? (NUM_1 / NUM_1) : (NUM_16 / NUM_9));
    const size: Size = this.getXComponentSizeWidth(previewAspectRatio);
    this.xComponentWidth = size.width;
    this.xComponentHeight = size.height;
  }

  private getXComponentSizeWidth(aspectRatio?: number): Size {
    return DisplayCalculator.calcSurfaceDisplaySize(aspectRatio, this.windowWidth, this.windowHeight);
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

  private getFootBarPositionY(): number {
    let position: number = (this.windowHeight - this.getFootBarHeight()) >> 1;
    if (this.windowHeight - this.getFootBarHeight() < MODE_BAR_HEIGHT) {
      position = (this.windowHeight - this.getFootBarHeight() - MODE_BAR_HEIGHT + 24) >> 1;
    }
    return position;
  }

  private updateFreeWindowUI(): void {
    HiLog.i(TAG, 'uxInit free window UI.');
    this.isShowModeBar = true;
    this.isShowTreasureBox = true;
    this.componentPosition = this.windowWidth - COMPONENT_WIDTH;
    this.treasureBoxHeight = TREASURE_BOX_HEIGHT_HORIZONTAL;
    this.treasureBoxTopMargin = 10;
    this.treasureBoxLeftMargin = 16;
    this.rouletteZoomViewPositionX = 20 - QUICK_ZOOM_MARGIN_BOTTOM_28;
    this.rouletteZoomViewPositionY = this.treasureBoxTopMargin + this.treasureBoxHeight;
    this.footBarPositionY = (this.windowHeight - this.getFootBarHeight() - 60) >> 1;
    this.paramBarPositionX = this.componentPosition - MIDDLE_COMPONENT_WIDTH;
    this.modeBarRightMargin = this.componentPosition;
    this.modeBarPositionY = this.footBarPositionY + this.getFootBarHeight() - 24;
    this.footBarAnimatePosition = {
      x: this.componentPosition,
      y: (this.windowHeight - this.getFootBarHeight()) >> 1
    };
  }

  private updateLeftRightSplitScreenUI(): void {
    HiLog.i(TAG, 'uxInit left right split screen UI.');
    this.isShowModeBar = true;
    this.isShowTreasureBox = true;
    let xComponentWidth16to9: number = this.getXComponentSizeWidth(NUM_16 / NUM_9).width;
    let blackSideBlack16to9: number = (this.windowWidth - xComponentWidth16to9) / 2;
    this.componentPosition = this.windowWidth - COMPONENT_WIDTH;
    this.treasureBoxTopMargin = 0.05 * this.windowHeight;
    this.treasureBoxLeftMargin = 16;
    this.treasureBoxHeight = 0.52 * this.windowHeight;
    this.rouletteZoomViewPositionX = this.getRouletteZoomViewPositionX();
    this.rouletteZoomViewPositionY = this.getRouletteZoomViewPositionY();
    this.modeBarRightMargin = blackSideBlack16to9;
    this.paramBarPositionX = this.componentPosition - MIDDLE_COMPONENT_WIDTH - blackSideBlack16to9;
    this.footBarPositionY = (this.windowHeight - this.getFootBarHeight()) >> 1;
    this.modeBarPositionY = this.getModeBarPositionY();
    this.footBarAnimatePosition = {
      x: this.componentPosition,
      y: (this.windowHeight - this.getFootBarHeight()) >> 1
    };
  }

  private updateHalfHeightSplitScreen(): void {
    HiLog.i(TAG, 'uxInit top bottom split screen UI.}');
    this.isShowModeBar = true;
    this.isShowTreasureBox = true;
    const spaceOfTwoSides: number = (this.windowWidth - this.windowHeight) / 2;
    let marginSides: number = 0;
    if (spaceOfTwoSides < COMPONENT_WIDTH) {
      marginSides = (this.windowWidth - this.windowHeight - COMPONENT_WIDTH) / 2;
    } else {
      marginSides = ((this.windowWidth - this.windowHeight) / 2 - COMPONENT_WIDTH) / 2;
    }
    this.componentPosition = this.windowWidth - COMPONENT_WIDTH - marginSides;
    if (this.componentPosition < this.xComponentWidth + this.previewAnimatePosition.x) {
      this.componentPosition = this.windowWidth - COMPONENT_WIDTH;
    }
    this.treasureBoxHeight = 0.5 * this.windowHeight;
    this.treasureBoxTopMargin = 0.01 * this.windowHeight;
    this.treasureBoxLeftMargin = marginSides + (COMPONENT_WIDTH - TREASURE_BOX_ELEMENT_INNER_WIDTH) / 2;
    this.rouletteZoomViewPositionX = this.getRouletteZoomViewPositionX();
    this.rouletteZoomViewPositionY = this.getRouletteZoomViewPositionY();
    this.paramBarPositionX = this.componentPosition - MIDDLE_COMPONENT_WIDTH;
    this.modeBarRightMargin = this.componentPosition + 10;
    this.footBarPositionY = this.getFootBarPositionY();
    this.modeBarPositionY = this.getModeBarPositionY();
    this.footBarAnimatePosition = {
      x: this.componentPosition,
      y: (this.windowHeight - this.getFootBarHeight()) >> 1
    };
  }

  private updateHorizontalFullScreenUI(): void {
    HiLog.i(TAG, 'uxInit horizontal full screen UI.');
    this.isShowModeBar = true;
    this.isShowTreasureBox = true;
    let xComponentWidth16to9: number = this.getXComponentSizeWidth(NUM_16 / NUM_9).width;
    let blackSideBlack16to9: number = (this.windowWidth - xComponentWidth16to9) / 2;
    const spaceOfTwoSides: number = (this.windowWidth - this.windowHeight * 4 / 3) / 2;
    let marginSides: number = 0;
    if (spaceOfTwoSides < COMPONENT_WIDTH) {
      marginSides = (this.windowWidth - this.windowHeight * 4 / 3 - COMPONENT_WIDTH) / 2;
    } else {
      marginSides = ((this.windowWidth - this.windowHeight * 4 / 3) / 2 - COMPONENT_WIDTH) / 2;
    }
    this.componentPosition = this.windowWidth - COMPONENT_WIDTH - marginSides;
    const blackSideBlack16to9TopBottom: number = (this.windowHeight - this.windowWidth * NUMBER_16_9) / 2;
    const remainingAreaHeight: number = this.windowHeight - blackSideBlack16to9TopBottom * 2 - 32;
    this.treasureBoxTopMargin = blackSideBlack16to9TopBottom + 16;
    this.treasureBoxHeight = 0.46 * remainingAreaHeight;
    this.treasureBoxLeftMargin = marginSides + (COMPONENT_WIDTH - TREASURE_BOX_ELEMENT_INNER_WIDTH) / 2;
    this.rouletteZoomViewPositionX = this.getRouletteZoomViewPositionX();
    this.rouletteZoomViewPositionY = this.getRouletteZoomViewPositionY();
    this.paramBarPositionX = this.componentPosition - MIDDLE_COMPONENT_WIDTH - blackSideBlack16to9;
    this.footBarPositionY = (this.windowHeight - this.getFootBarHeight()) >> 1;
    this.modeBarPositionY = this.getModeBarPositionY();
    this.footBarAnimatePosition = {
      x: this.componentPosition,
      y: (this.windowHeight - this.getFootBarHeight()) >> 1
    };
  }

  private updateVerticalFullScreenUI(): void {
    HiLog.i(TAG, 'uxInit vertical full screen UI.');
    this.isShowModeBar = true;
    this.isShowTreasureBox = true;
    let xComponentWidth16to9: number = this.getXComponentSizeWidth(NUM_16 / NUM_9).width;
    let blackSideBlack16to9: number = (this.windowWidth - xComponentWidth16to9) / 2;
    let marginSides: number = (this.windowWidth - this.windowHeight * NUMBER_16_9) / 2;
    this.componentPosition = this.windowWidth - COMPONENT_WIDTH - marginSides;
    this.treasureBoxTopMargin = 0.195 * this.windowHeight;
    this.treasureBoxHeight = 0.28 * this.windowHeight;
    this.treasureBoxLeftMargin = marginSides + (COMPONENT_WIDTH - TREASURE_BOX_ELEMENT_INNER_WIDTH) / 2;
    this.rouletteZoomViewPositionX = this.getRouletteZoomViewPositionX();
    this.rouletteZoomViewPositionY = this.getRouletteZoomViewPositionY();
    this.paramBarPositionX = this.componentPosition - MIDDLE_COMPONENT_WIDTH - blackSideBlack16to9;
    this.footBarPositionY = this.getFootBarPositionY();
    this.modeBarPositionY = this.getModeBarPositionY();
    this.footBarAnimatePosition = {
      x: this.componentPosition,
      y: (this.windowHeight - this.getFootBarHeight()) >> 1
    };
  }

  private updateTwoThirdsHeightSplitScreen(): void {
    HiLog.i(TAG, 'uxInit top bottom split screen UI.}');
    this.isShowModeBar = true;
    this.isShowTreasureBox = true;
    let marginSides: number = 24;
    this.componentPosition = this.windowWidth - COMPONENT_WIDTH - marginSides;
    if ((this.windowWidth - this.windowHeight * NUMBER_16_9) / 2 < this.windowWidth - this.componentPosition) {
      this.componentPosition = this.windowWidth - COMPONENT_WIDTH;
    }
    this.treasureBoxHeight = 0.52 * this.windowHeight;
    this.treasureBoxTopMargin = 0.05 * this.windowHeight;
    this.treasureBoxLeftMargin = marginSides;
    this.rouletteZoomViewPositionX = this.getRouletteZoomViewPositionX();
    this.rouletteZoomViewPositionY = this.getRouletteZoomViewPositionY();
    this.footBarPositionY = this.getFootBarPositionY();
    this.paramBarPositionX = this.componentPosition - MIDDLE_COMPONENT_WIDTH;
    this.modeBarRightMargin = this.componentPosition + 10;
    this.modeBarPositionY = this.getModeBarPositionY();
    this.footBarAnimatePosition = {
      x: this.componentPosition,
      y: (this.windowHeight - this.getFootBarHeight()) >> 1
    };
  }

  private updateOneThirdHeightSplitScreenUI(): void {
    HiLog.i(TAG, 'uxInit one-third split screen UI.');
    this.isShowModeBar = false;
    this.isShowTreasureBox = false;
    const marginSides: number = 24;
    this.componentPosition = this.windowWidth - COMPONENT_WIDTH - marginSides;
    if ((this.windowWidth - this.windowHeight * NUMBER_16_9) / 2 < this.windowWidth - this.componentPosition) {
      this.componentPosition = this.windowWidth - COMPONENT_WIDTH;
    }
    this.rouletteZoomViewPositionX = this.getRouletteZoomViewPositionX();
    this.rouletteZoomViewPositionY = this.getRouletteZoomViewPositionY();
    this.paramBarPositionX = this.windowWidth / 2 + this.windowHeight / 2 - MIDDLE_COMPONENT_WIDTH;
    this.footBarPositionY = (this.windowHeight - this.getFootBarHeight()) >> 1;
    this.footBarAnimatePosition = {
      x: this.componentPosition,
      y: (this.windowHeight - this.getFootBarHeight()) >> 1
    };
  }

  private uxInit(): void {
    HiLog.i(TAG, `Window size width: ${this.windowWidth}, height: ${this.windowHeight}.`);
    if (PickerUtils.getIsTabletInFreeWindow() || PickerUtils.getIsTableInFloating()) {
      this.updateFreeWindowUI();
      return;
    }
    if (PickerUtils.getIsTabletLeftRightSplitScreenFromReducer()) {
      this.updateLeftRightSplitScreenUI();
      return;
    }
    if (this.pickerWindowType === PickerWindowType.TABLET_1_3_SPLIT_SCREEN) {
      this.updateOneThirdHeightSplitScreenUI();
      return;
    }
    if (this.pickerWindowType === PickerWindowType.TABLET_2_3_SPLIT_SCREEN) {
      this.updateTwoThirdsHeightSplitScreen();
      return;
    }
    if (this.pickerWindowType === PickerWindowType.TABLET_FULL_SCREEN) {
      if (DisplayService.getInstance().isOrientationVertical()) {
        this.updateVerticalFullScreenUI();
      } else {
        this.updateHorizontalFullScreenUI();
      }
      return;
    }
    this.updateHalfHeightSplitScreen();
  }

  private onBackground(): void {
    HiLog.i(TAG, 'onBackground.');
    RestartService.getInstance().cancelRestart();
    this.cameraErrorDialogController?.close();
    this.isShowCameraError = false;
  }

  private timerStateOnChange(): void {
    HiLog.i(TAG, `timerStateOnChange videoTimerState: ${this.videoTimerState}.`);
    this.timerOpacity = this.videoTimerState ? 0 : 1;
    this.showTimer = true;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_VIDEO_START_DURATION,
      curve: Curve.Sharp,
      onFinish: () => {
        this.showTimer = this.videoTimerState;
      }
    }, () => {
      this.timerOpacity = this.videoTimerState ? 1 : 0;
    });
  }

  private terminateCamera(): void {
    HiLog.i(TAG, 'terminateCamera');
    if (this.session) {
      this.session?.sendData({ 'cameraDown': true });
    } else {
      ContextManager.getInstance().getUiContext().terminateSelf().then(() => {
        HiLog.i(TAG, 'terminateSelf success');
      });
    }
  }

  private exitFlashDialogShow(): void {
    TipService.getInstance().showTip($r('app.string.device_hot_flash_off_tips'), 3000, true);
    this.mAction.changeFunctionValue(FunctionId.FLASH, FlashMode.OFF);
  }

  private exitCameraDialogShow(): void {
    this.createExitCameraDialog();
    this.exitCameraDialogController?.open();
    setTimeout((): void => {
      this.terminateCamera();
    }, 5000);
  }

  private lowBatteryExitFlashDialogShow(): void {
    HiLog.i(TAG, 'isFlashEnable ==' + this.isFlashEnable);
    if (this.isFlashEnable) {
      this.mAction.changeFunctionValue(FunctionId.FLASH, PreferencesService.getInstance()
        .getPublicValue(PersistType.FOREVER, PublicTag.FLASH_STATE, FlashMode.OFF));
      return;
    }
    PreferencesService.getInstance().putPublicValue(PersistType.FOREVER, PublicTag.FLASH_STATE,
      FeatureManager.getInstance().getFunction(FunctionId.FLASH).getValue() as number);
    this.mAction.changeFunctionValue(FunctionId.FLASH, FlashMode.OFF);
    this.isLowBatteryTipShowed = PreferencesService.getInstance().getPublicValue(PersistType.FOREVER,
      PublicTag.IS_LOW_BATTERY_TIP_OPENED, false) as boolean;
    HiLog.i(TAG, 'this.isShowLowBatteryExitFlash ==' + this.isLowBatteryTipShowed);
    if (this.isLowBatteryTipShowed) {
      return;
    }
    TipService.getInstance().showTip($r('app.string.dialog_FlashOff_BatteryLowTips'), 3000, true);
    this.isLowBatteryTipShowed = true;
    PreferencesService.getInstance().putPublicValue(PersistType.FOREVER, PublicTag.IS_LOW_BATTERY_TIP_OPENED, true);
  }

  private createCameraErrorDialog(errorCode: number): void {
    if (this.isPicker) {
      HiLog.i(TAG, 'Ignore the errorCode for picker.')
      return;
    }
    HiLog.i(TAG, `pass errorCode: ${errorCode}`);
    let params: CameraErrorDialogViewParams = CameraErrorDialogView.getDefaultParams(errorCode);
    this.cameraErrorDialogController = new CustomDialogController({
      builder: CameraErrorDialogView({
        confirm: () => {
          params.confirm();
          this.isShowCameraError = false;
        },
        title: params.title,
        description: params.description,
        confirmText: params.confirmText,
        rotateAngle: 0,
        currentDirection: this.mDirection,
      }),
      autoCancel: false,
      customStyle: true,
      maskColor: '#66000000',
      cancel: () => {
      },
      alignment: DialogAlignment.Center,
    });
  }

  private cameraErrorDialogShow(errorCode: number): void {
    let isBackground: boolean | undefined = AppStorage.get<boolean>('isBackground');
    let isActive: boolean = power.isActive();
    let isLocked: boolean = screenLock.isLocked();
    HiLog.i(TAG, `isBackground: ${isBackground}, isActive: ${isActive}, isLocked: ${isLocked}`);
    if (isBackground || !isActive || isLocked) {
      HiLog.i(TAG, 'Ignore the errorCode.');
      return;
    }
    this.cameraErrorDialogController?.close();
    this.isShowCameraError = false;
    HiLog.i(TAG, `errorCode == ${errorCode}`);
    this.createCameraErrorDialog(errorCode);
    this.cameraErrorDialogController?.open();
    this.isShowCameraError = true;
  }

  private createExitCameraDialog(): void {
    HiLog.i(TAG, 'createExitLocationDialog');
    this.exitCameraDialogController = new CustomDialogController({
      builder: AlertDialogView({
        confirm: () => {
          this.exitCameraDialogController?.close();
          this.terminateCamera();
        },
        title: $r('app.string.device_hot_exit_tips', this.exitTimer),
        confirmText: $r('app.string.dialog_comform_exit_new'),
      }),
      autoCancel: false,
      customStyle: true,
      maskColor: '#66000000',
      cancel: () => {
      },
      alignment: DialogAlignment.Center,
    });
  }

  private timeLapse(data: ShowParm): void {
    this.showModeBar = data.showModeBar;
  }

  private directionChange(): void {
    if (this.mDirection === WindowDirection.LEFT) {
      this.rotateAngle = 270;
    } else if (this.mDirection === WindowDirection.RIGHT) {
      this.rotateAngle = 90;
    } else {
      this.rotateAngle = 0;
    }
  }
}