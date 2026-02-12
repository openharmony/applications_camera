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

import { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import { PreviewArea } from '../PreviewArea';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import {
  PositionType,
  proSonChangeNumberData,
  SavePowerModeActionData,
  Size,
  XComponentSize
} from '@ohos/common/src/main/ets/utils/types';
import { RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import { FootBar } from './FootBar';
import { FOOT_BAR_HEIGHT } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService'
import { MODE_BAR_HEIGHT } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService';
import { BigScreenModeBar } from '@ohos/common/src/main/ets/component/ModeBar/bigScreen/BigScreenModeBar';
import { VideoTimer } from '@ohos/common/src/main/ets/component/videoTimer/VideoTimer';
import { TREASURE_BOX_ELEMENT_INNER_WIDTH } from '@ohos/common/src/main/ets/component/treasurebox/common/DataType';
import { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import { PickerView } from './PickerView';
import camera from '@ohos.multimedia.camera';
import { ParamBar } from './ParamBar';
import { MIDDLE_COMPONENT_WIDTH } from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService';
import {
  CameraRunningState,
  CameraStartType,
  CameraStartTypeStruct
} from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import { ExtendBar } from './ExtendBar';
import { ConfirmDialogView } from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/ConfirmDialogView';
import {
  FloatingShutterButton
} from '@ohos/extend/src/main/ets/settingcommonfunc/floatingShutter/FloatingShutterButton';
import { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { FlashMode } from '@ohos/common/src/main/ets/function/enumbase/FlashMode';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import { BigText } from '@ohos/common/src/main/ets/component/bigtext/BigText';
import lazy { AlertDialogView } from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/AlertDialogView'
import { PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import { ChangeState, reduxSubscribe, Unsubscribe, getStates } from '@ohos/common/src/main/ets/redux/Store';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import { RouletteZoomView } from '@ohos/common/src/main/ets/function/zoombar/RouletteZoomView';
import {
  QUICK_ZOOM_MARGIN_BOTTOM_28
} from '@ohos/common/src/main/ets/service/UIAdaptive/AdaptiveLandscapeLayoutService';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { TipBox } from '@ohos/common/src/main/ets/component/tip/TipBox';
import { PhotoFormatMode } from '@ohos/common/src/main/ets/function/enumbase/PhotoFormatMode';
import { OutputSwitcher } from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcher';
import { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import {
  CameraErrorDialogView,
  CameraErrorDialogViewParams,
  CameraErrorData
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/CameraErrorDialogView'
import { DisplayCalculator } from '@ohos/common/src/main/ets/component/xcomponent/DisplayCalculator';
import { RestartService } from '@ohos/common/src/main/ets/service/restart/RestartService';
import power from '@ohos.power';
import screenLock from '@ohos.screenLock';
import { display } from '@kit.ArkUI';
import { ZoomOperation } from '@ohos/common/src/main/ets/function/zoombar/ZoomOperation';
import { AuxiliaryMode } from '@ohos/common/src/main/ets/function/enumbase/AuxiliaryMode';
import { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import { FocusExposureService } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureService';
import { FocusExposureAction } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureAction';
import lazy { PropTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import { LandscapeTreasureBox as TreasureBox } from '@ohos/common/src/main/ets/component/treasurebox/landscape/LandscapeTreasureBox'

const TAG: string = 'DefaultIndex';

export const COMPONENT_WIDTH: number = 88;

const NUM_16: number = 16;
const NUM_9: number = 9;
const NUM_4: number = 4;
const NUM_3: number = 3;
const NUM_1: number = 1;

export const FULL_LENGTH: string = '100%';

class TabPosition {
  public x: number = 0;
  public y: number = 0;
}

class LumationConfirmData {
  public info: number = 0;
}

const BIG_TEXT_TOP_MARGIN: number = 500;
const VIDEO_TIMER_TOP_MARGIN: number = 40;
const NUMBER_16_9: number = 0.5625;
const ICON_SIZE: number = 24;
const TABLET_MARGIN_TOP_VERTICAL: number = 264;
const TABLET_MARGIN_TOP_HORIZONTAL: number = 95;
const WINDOWS_SCREEN_800: number = 800;
const ZOOM_PORTRAIT_DIFF: number = 11;
const ZOOM_LANDSCAPE_DIFF: number = 27;
const ZOOM_TOP_DIFF: number = 80;
const ZOOM_VIEW_TOP_MARGIN_VERTICAL: number = 597;
const ZOOM_VIEW_TOP_MARGIN: number = 384;
const TREASURE_BOX_TOP_MARGIN_VERTICAL: number = 240;
const MODE_BAR_TOP_MARGIN: number = 18;
const TREASURE_BOX_HEIGHT_VERTICAL: number = 360;
const PROFESSION_BAR_WIDTH: number = 240;
const PROFESSION_BAR_BUTTON_WIDTH: number = 60;
const QUICK_ZOOM_VIEW_HEIGHT: number = 40;
const CAMERA_START_TYPE_UNDEFINED: number = -1;

class RestoreDialogConfirmData {
  public restoreConfirmFlag: boolean = false;
  public isRequestOnSetting: boolean = false;
}

class PreviewFrameStartData {
  public isPreviewFrameStart: boolean = false;
}

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
  public treasureBoxCollapsState: boolean = false;
}

class IndexDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public changeXComponentSize(size: Size): void {
    this.mDispatch(Action.changeXComponentSize(size.width, size.height));
  }

  public confirmLocationTOSettingPermission(isRequestOnSetting: boolean): void {
    this.mDispatch(Action.confirmLocationTOSettingPermission(isRequestOnSetting));
  }

  public openTreasureBox(): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(true));
  }

  public closeTreasureBox(): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(false));
  }

  public hideFocus(): void {
    this.mDispatch(FocusExposureAction.hideFocus());
  }
}

class DisplayRotationStruct {
  public displayRotation: number = 0;
}

const TAB_BAR_HEIGHT: number = 30;

class ShowParm {
  public showModeBar: boolean = false;
}

class ExposureModeStruct {
  public exposureMode: camera.ExposureMode = camera.ExposureMode.EXPOSURE_MODE_AUTO;
  public exposureValue: number = 0;
}

class FocusModeStruct {
  public focusMode: camera.FocusMode = camera.FocusMode.FOCUS_MODE_AUTO;
  public focusPoint: camera.Point = { x: 0, y: 0 };
}

@Component
export struct DefaultIndex {
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State state: StateStruct = new StateStruct();
  private mAction: IndexDispatcher = new IndexDispatcher();
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @State loadSurfaceDone: boolean = true;
  @State @Watch('onModeChange') mode: ModeType = ModeType.NONE;
  // ux位置适配
  @State isVertical: boolean = true;
  @State previewPosition: PositionType = { x: 0, y: 0 };
  @State bigTextPosition: number = 0;
  @State componentPosition: number = 0; //footBar modeBar位置
  @State zoomViewTopMargin: number = 0;
  @State zoomViewLeftMargin: number = 0;
  @State treasureBoxTopMargin: number = 0;
  // VideoTimer
  @State showTimer: boolean = false;
  @State isTimelapseFront: boolean = false;
  @State timerOpacity: number = 0;
  @State @Watch('timerStateOnChange') videoTimerState: boolean = false;
  @State videoTimerVisible: boolean = false;
  @State videoTimerPosition: number = VIDEO_TIMER_TOP_MARGIN;
  // 沉浸式
  @Prop immersiveUIType: UIOperationType = UIOperationType.NULL;
  @Prop immersiveOpacity: number = 1;
  @State modeBarOpacity: number = 1;
  @State footBarPosition: number = 0;
  // 获取屏幕大小
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State @Watch('onXComponentSizeChange') xComponentWidth: number = 0;
  // Picker
  @State isPicker: boolean = false;
  @State showPicker: boolean = false;
  // 相机异常弹窗
  private cameraErrorDialogController: CustomDialogController | null = null;
  private isShowCameraError: boolean = false;
  private appRecoveryTimer: number = Number.MIN_VALUE;
  // 地理位置弹窗
  private locationDialogController: CustomDialogController | null = null;
  private isToSettingPermission: boolean = false;
  @State isShowMorePage: boolean = false;
  @State isShowLandscape: boolean = false;
  @State isEditMorePage: boolean = false;
  @State development: boolean = true;
  @State footBarAnimatePosition: PositionType = { x: 0, y: 0 }; //缩略图,快门,前后置切换动画效果定位
  @State isShowTextInfo: boolean = false;
  @State introductoryText: Resource | string = this.getDefaultTextSrc();
  @State treasureBoxLeftMargin: number = 0;
  @State treasureBoxHeight: number = TREASURE_BOX_HEIGHT_VERTICAL;
  @State footBarRightMargin: number = 0;
  @State paramBarPositionX: number = 0;
  @State modeBarRightMargin: number = 0;
  @State lumationValue: number = 101;
  @State rotateAngle: number = 0;
  @State isSupportMeteringModeFunc: boolean = false;
  @State tabViewPosition: TabPosition = this.getTimeLapseTabPosition();
  @State zoomOpacity: number = 0;
  @State footOpacity: number = 0;
  @State modeOpacity: number = 0;
  @State paramOpacity: number = 0;
  @State extendOpacity: number = 0;
  private exposureConfirmDialogController: CustomDialogController | null = null;
  @StorageLink('showFilmingTime') showFilmingTime: boolean = false;
  @State showModeBar: boolean = true;
  @State prosonNumber: number = -1;
  @State @Watch('dialogShowChange') isDialogShow: boolean = false;
  @State professionBarPositionX: number = 0;
  @StorageLink('isModeIntroDialogLoaded') isModeIntroDialogLoaded: Map<ModeType, boolean> =
    new Map<ModeType, boolean>();
  private modeIntroDialogController: CustomDialogController | null = null;
  @State isShowModeIntroCardEntry: boolean = false;
  //温控弹窗
  private exitCameraDialogController: CustomDialogController | null = null;
  private session: UIExtensionContentSession | undefined = undefined;
  @State isShowLowBatteryExitFlash: boolean = false;
  @State showProfessionBar: boolean = true;
  @State @Watch('lowBatteryExitFlashDialogShow') isFlashEnable: boolean = true;
  private recoverFlash: boolean = false;
  @State isLowBatteryTipShowed: boolean = false;
  @State exitTimer: number = 5;
  @State newPreviewAnimatePostion: PositionType = { x: 0, y: 0 };
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @StorageLink('isNightShutting') isNightShutting: boolean = false;
  @State aspectRatioType: number = 1;
  @State pageWidth: number = 0;
  @State pageHeight: number = 0;
  // 慢动作相关
  @State isSuperSlowMotion: boolean = false;
  @StorageLink('slowRecordingCompVisible') slowRecordingCompVisible: boolean = true; // 超慢控制组件展示的动效变量
  @StorageLink('isDownSuperSlowBtnState') @Watch('superSlowRecordingAnim') isDownSuperSlowBtn: boolean = false;
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @State treasureBoxOpacity: number = 1;
  @State isPanoramaBarVisible: boolean = false;
  private panoramaTimer: number = Number.MIN_VALUE;
  @State isShowRingLightView: boolean = false;
  @State isShowWhiteBack: boolean = false;
  @StorageLink('isBackground') isBackground: boolean = false;
  private hidePreviewWhenBackground: boolean = CameraAppCapability.getInstance().needHidePreviewWhenBackground();
  @State isPreviewFrameStart: boolean = true;
  @State cameraStartType: CameraStartType = CAMERA_START_TYPE_UNDEFINED;
  private isDisAbleRealTimeLapsePro: boolean = CameraAppCapability.getInstance().getIsDisAbleRealTimeLapsePro();
  @LocalStorageLink('newPreviewAnimatePosition') newPreviewAnimatePosition: PositionType = { x: 0, y: 0 };

  aboutToAppear(): void {
    this.setEventBusOn();

    this.restoreModeIntroDialogValues();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.videoTimerState = state.get<boolean>('recordReducer', 'videoTimerState');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isFlashEnable = state.get<boolean>('uiReducer', 'isFlashEnable');
      this.isShowMorePage = state.get<boolean>('modeReducer', 'isShowMorePage');
      this.isEditMorePage = state.get<boolean>('modeReducer', 'isEditMorePage');
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
        treasureBoxCollapsState: state.get<boolean>('treasureBoxReducer', 'isOpen'),
      });
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.showPicker = state.get<boolean>('uiReducer', 'showPicker');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.pageHeight = state.get<number>('windowReducer', 'windowHeight');
      this.pageWidth = state.get<number>('windowReducer', 'windowWidth');
      this.isShowRingLightView = state.get<boolean>('ringLightReducer', 'isShowRingLightView');
      this.isShowWhiteBack = state.get<boolean>('ringLightReducer', 'isShowWhiteBack');
      this.aspectRatioType = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue() as number;
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.uxInit();
    this.getXComponentSize();
  }

  private onLocationPermissionToSetting(): void {
    this.locationDialogShow(true);
  }

  private onRestoreDialogConfirm(data: RestoreDialogConfirmData): void {
    this.locationDialogShow(false, data);
  }

  private isShowComponentDisplay(): void {
    this.showProfessionBar = true;
  }

  private setEventBusOn(): void {
    this.mEventBus.on(CameraActionType.ERROR, (data: CameraErrorData) => this.cameraErrorDialogShow(data.code),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHANGE_X_COMPONENT_SIZE,
      this.setPreviewPosition.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_RESTORE_DIALOG_CONFIRM,
      this.onRestoreDialogConfirm.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LOCATION_PERMISSION_TO_SETTING,
      this.onLocationPermissionToSetting.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), this.mBase.hashCode());
    this.mEventBus.on([WindowActionType.ON_SIZE_CHANGE, WindowActionType.REFRESH_UX], this.uxInit.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_PROSON_CHANGE_STATE,
      this.prosonChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_LUMINATION_STATUS_CHANGED,
      this.updateLumation.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.UPDATE_SAVE_POWER_MODE_STATE, (data: SavePowerModeActionData) =>
    this.updateSavePowerModeState(data), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_EXIT_FLASH_DIALOG, () => this.exitFlashDialogShow(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_EXIT_CAMERA_DIALOG, () => this.exitCameraDialogShow(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHANGE_X_COMPONENT_SIZE,
      () => this.getXComponentSize(), this.mBase.hashCode());
    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.SWITCH_CAMERA_CHANGE_MODE],
      () => this.isShowComponentDisplay(), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.onCreateSessionDone.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_MORE_PAGE, this.showMoreChanged.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ON_PREVIEW_FRAME_START, this.onPreviewFrameStart.bind(this),
      this.mBase.hashCode());
  }

  private videoStateOnChange(): void {
    HiLog.i(TAG, `videoStateOnChange videoState:${this.videoState}.`);
    if (this.videoState === RecordingState.STARTING) {
      if (this.state.treasureBoxCollapsState) {
        this.treasureBoxOpacity = 0;
        this.modeBarOpacity = 0;
      } else {
        this.treasureBoxOpacity = 0;
        this.modeBarOpacity = 1;
      }
      this.recordStartAnim();
    } else if (this.videoState === RecordingState.STOPPING) {
      this.recordEndAnim();
    }
  }

  private recordEndAnim(): void {
    this.treasureBoxOpacity = 0;
    this.modeBarOpacity = 0;
    this.showModeBar = true;
    animateToImmediately({
      duration: AnimSpecifications.ANIM_VIDEO_START_TRANSLATE_DURATION,
      delay: AnimSpecifications.ANIM_VIDEO_START_TRANSLATE_DURATION,
      curve: Curve.Sharp,
      onFinish: () => {
        this.showModeBar = true;
      }
    }, () => {
      this.treasureBoxOpacity = 1;
      this.modeBarOpacity = 1;
    });
  }

  private recordStartAnim(): void {
    animateToImmediately({
      duration: AnimSpecifications.ANIM_VIDEO_START_TRANSLATE_DURATION,
      delay: AnimSpecifications.ANIM_VIDEO_START_TRANSLATE_DURATION,
      curve: Curve.Sharp,
      onFinish: () => {
        this.showModeBar = false;
      }
    }, () => {
      this.treasureBoxOpacity = 0;
      this.modeBarOpacity = 0;
    });
  }

  private restoreModeIntroDialogValues(): void {
    HiLog.i(TAG, 'Restoring ModeIntroDialog Values Starts.');
    HiLog.i(TAG, 'Restoring ModeIntroDialog Values Ends.');
  }

  private showMoreChanged(): void {
    if (this.isShowMorePage) {
      this.isShowTextInfo = false;
    } else {
      this.isShowTextInfo = true;
    }
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
    this.locationDialogController?.close();
    this.isPanoramaBarVisible = false;
    this.cameraStartType = CAMERA_START_TYPE_UNDEFINED;
  }

  private onModeChange(): void {
    this.isShowModeIntroCardEntry = false;
    this.lowBatteryExitFlashDialogShow();
  }

  private isShowModeIntroCardEntryBuilder(): boolean {
    if (this.state.videoState !== RecordingState.READY) {
      return false;
    }
    return this.isShowModeIntroCardEntry && !this.isShowMorePage && !this.isPicker;
  }

  private superSlowRecordingAnim(): void { // 超慢动效不在录制过程中处理，按下按钮就开始，且动效和一般录像不同
    HiLog.i(TAG, `timerStateOnChange isDownSuperSlowBtn: ${this.isDownSuperSlowBtn}.`);
    this.timerOpacity = this.isDownSuperSlowBtn ? 0 : 1;
    this.showTimer = true; // 超慢按钮按下的状态模拟录像videoTimeState
    animateToImmediately({
      duration: AnimSpecifications.ANIM_VIDEO_START_DURATION,
      curve: Curve.Sharp,
      onFinish: () => {
        this.showTimer = this.isDownSuperSlowBtn;
      }
    }, () => {
      this.timerOpacity = this.isDownSuperSlowBtn ? 1 : 0;
      this.slowRecordingCompVisible = !this.isDownSuperSlowBtn;
    });
  }

  private updateSavePowerModeState(data: SavePowerModeActionData) {
    if (data.isDuringSavePowerMode) {
      this.exposureConfirmDialogController?.close();
      this.locationDialogController?.close();
      this.exitCameraDialogController?.close();
      this.isDialogShow = false;
    }
  }

  private isPreviewAreaMiddle(xComponentWidth: number): boolean {
    if (WindowService.getInstance().isVertical()) {
      return true;
    }
    return (this.windowWidth - xComponentWidth) / 2 >= COMPONENT_WIDTH ? true : false;
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      PreviewArea({
        bigTextPosition: this.bigTextPosition,
        isPicker: this.isPicker,
        loadSurfaceDone: $loadSurfaceDone,
        development: this.development,
        previewPosition: this.previewPosition,
        newPreviewAnimatePostion: this.newPreviewAnimatePosition
      })
        .zIndex(ZIndex.BOTTOM)
        .key(ComponentIdKeys.PREVIEW_WINDOW_1)
        .position(this.previewPosition)
        .visibility(this.isBackground && this.hidePreviewWhenBackground || this.showPicker ? Visibility.Hidden :
          Visibility.Visible)


      RouletteZoomView({
        zoomWidth: 344,
        zoomHeight: 150,
        drawHeight: 95
      })
        .position({ x: this.zoomViewLeftMargin, y: this.zoomViewTopMargin })
        .key(ComponentIdKeys.RING_ZOOM_BAR)
        .opacity(!this.isShowMorePage && this.immersiveUIType === UIOperationType.ZOOM_BAR ? 1 : this.immersiveOpacity)
        .hitTestBehavior(HitTestMode.Transparent)
        .visibility(this.getZoomVisible())
        .rotate({
          centerX: 0,
          centerY: 80,
          angle: 90
        })

      FootBar({
        isPicker: this.isPicker,
        footBarScale: 1
      })
        .opacity(!this.isShowMorePage && (this.immersiveUIType === UIOperationType.FOOT_BAR ||
          this.immersiveUIType === UIOperationType.LR_SWIPE) ? 1 : this.immersiveOpacity)
        .visibility(this.isFootBarVisible() ? Visibility.Visible : Visibility.Hidden)
        .position({
          x: (this.componentPosition - this.footBarRightMargin),
          y: (this.windowHeight - FOOT_BAR_HEIGHT) >> 1
        })

      BigScreenModeBar()
        .hitTestBehavior(HitTestMode.Default)
        .opacity(this.immersiveUIType === UIOperationType.MODE_BAR ? 1 : this.immersiveOpacity)
        .visibility(!this.isEditMorePage && (this.immersiveUIType === UIOperationType.MODE_BAR ||
          this.immersiveOpacity !== 0) && !this.showTimer && !this.isDownSuperSlowBtn && !this.showPicker ?
          Visibility.Visible : Visibility.Hidden)
        .position({
          x: (this.componentPosition - this.modeBarRightMargin),
          y: ((this.windowHeight - FOOT_BAR_HEIGHT) >> 1) + FOOT_BAR_HEIGHT + MODE_BAR_TOP_MARGIN
        })

      // 非以下场景显示tip：沉浸式下的变焦（录像模式除外）以及倒计时拍照
      if (!(this.immersiveOpacity == 0 &&
        ((this.immersiveUIType === UIOperationType.ZOOM_BAR ||
          this.immersiveUIType === UIOperationType.PINCH_ZOOM) && this.mode !== ModeType.VIDEO ||
          this.immersiveUIType === UIOperationType.TIMELAPSE))) {
        TipBox({
          isShowTextInfo: this.isShowTextInfo,
          landscapePreviewPosition: this.previewPosition,
        })
      }

      TreasureBox({ treasureBoxHeight : this.treasureBoxHeight})
        .position({ x: this.treasureBoxLeftMargin, y: this.treasureBoxTopMargin })
        .opacity(this.immersiveUIType === UIOperationType.ZOOM_BAR ? 1 : this.immersiveOpacity)
        .visibility(!this.isShowMorePage && (this.immersiveUIType === UIOperationType.MODE_BAR ||
          this.immersiveOpacity !== 0) && !this.showPicker ? Visibility.Visible : Visibility.Hidden)

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

      if (this.state.isShowExtendBar) {
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

      // tablet后续修改的时候注意videoTime的展示取决于直接监听tabBar的展开态和方向！！！！！
      // 原有点击控制的状态已删除！！！！！
      if (!this.isShowMorePage && this.showTimer && !this.isTimelapseFront && !this.isSuperSlowMotion) {
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
          previewPosition: this.previewPosition,
          buttonPosition: this.footBarAnimatePosition
        })
          .visibility(this.showPicker ? Visibility.Visible : Visibility.Hidden)
          .zIndex(ZIndex.TOP)
      }

      if (this.state.isFloatingShutterShow && !this.isShowMorePage) {
        FloatingShutterButton({ isPicker: this.isPicker })
          .zIndex(ZIndex.MIDDLE_TOP)
          .position({ x: 0, y: 0 })
          .visibility(this.immersiveUIType === UIOperationType.FOOT_BAR ||
            this.immersiveUIType === UIOperationType.LR_SWIPE ||
            this.immersiveOpacity !== 0 ? Visibility.Visible : Visibility.Hidden)
      }

      this.modeIntroCardEntryBuilder();
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

  @Builder
  modeIntroCardEntryBuilder() {
    if (this.isShowModeIntroCardEntryBuilder() && !this.isShowMorePage) {
    }
  }

  private isFootBarVisible(): boolean {
    if (this.isShowMorePage || this.showPicker) {
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
    if (this.isShowMorePage || this.showPicker) {
      return Visibility.Hidden;
    }
    // 前置
    if (this.state.cameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      return Visibility.Hidden;
    }

    // 长曝光状态进入沉浸式拍照
    if (this.isNightShutting) {
      return Visibility.Hidden;
    }

    if (this.isSuperSlowMotion && !this.slowRecordingCompVisible) { // 超慢zoom动效
      return Visibility.Hidden;
    }

    // ExtendBar展示
    if (this.state.isShowExtendBar) {
      return Visibility.Hidden;
    }

    if (!(this.prosonNumber === -1 || this.prosonNumber === 0)) {
      return Visibility.Hidden;
    }

    return Visibility.Visible;
  }

  private onCreateSessionDone(data: CameraStartTypeStruct): void {
    this.cameraStartType = data.type;
    HiLog.d(TAG, `start type: ${this.cameraStartType}`);
  }

  private setPreviewPosition(data: XComponentSize): void {
    HiLog.i(TAG, `setPreviewPosition E, data: ${JSON.stringify(data)}.`);
    this.getXComponentSize();
    this.newPreviewAnimatePostion = {
      x: this.getPreviewXPostion(data),
      y: (this.windowHeight - data.xComponentHeight) >> 1
    }
    if ((this.previewPosition.x !== this.newPreviewAnimatePostion.x ||
      this.previewPosition.y !== this.newPreviewAnimatePostion.y) &&
      this.cameraStartType !== CAMERA_START_TYPE_UNDEFINED) {
      return;
    }
    this.newPreviewAnimatePostion.x = px2vp((Math.floor(vp2px(this.newPreviewAnimatePostion.x)) >> 1) << 1);
    this.newPreviewAnimatePostion.y = px2vp((Math.floor(vp2px(this.newPreviewAnimatePostion.y)) >> 1) << 1);
    this.previewPosition = this.newPreviewAnimatePostion;
    this.bigTextPosition = BIG_TEXT_TOP_MARGIN - (this.previewPosition.y);
  }

  private onXComponentSizeChange(): void {
    HiLog.i(TAG,
      `xComponentSize change, xComponentWidth: ${this.xComponentWidth}.`);
    this.uxInit();
  }

  private getPreviewXPostion(data: XComponentSize): number {
    return this.isPreviewAreaMiddle(this.xComponentWidth) ? (this.windowWidth - data.xComponentWidth) >> 1 : 0;
  }

  private getXComponentSize(): void {
    let previewAspectRatio =
      this.aspectRatioType === 1 ? (NUM_4 / NUM_3) : (this.aspectRatioType === 2 ? (NUM_1 / NUM_1) : (NUM_16 / NUM_9));
    this.xComponentWidth = this.getXComponentSizeWidth(previewAspectRatio);
  }

  private getXComponentSizeWidth(aspectRatio?: number): number {
    return DisplayCalculator.calcSurfaceDisplaySize(aspectRatio, this.windowWidth, this.windowHeight).width;
  }

  private uxInit(): void {
    HiLog.i(TAG, `Window size width: ${this.windowWidth}, height: ${this.windowHeight}.`);
    this.mAction.changeXComponentSize(CameraBasicService.getInstance().getPreviewDisplaySize());
    if (this.windowWidth < this.windowHeight) {
      let xComponentWidth16to9: number = this.getXComponentSizeWidth(NUM_16 / NUM_9);
      let blackSideBlack16to9: number = (this.windowWidth - xComponentWidth16to9) / 2;
      this.componentPosition = this.windowWidth - COMPONENT_WIDTH;
      this.zoomViewTopMargin = this.getPortraitZoomDiffValue();
      this.zoomViewLeftMargin = blackSideBlack16to9 - QUICK_ZOOM_MARGIN_BOTTOM_28;
      this.treasureBoxTopMargin = TREASURE_BOX_TOP_MARGIN_VERTICAL;
      this.treasureBoxLeftMargin = blackSideBlack16to9;
      this.footBarRightMargin = blackSideBlack16to9;
      this.modeBarRightMargin = blackSideBlack16to9;
      this.paramBarPositionX = this.componentPosition - MIDDLE_COMPONENT_WIDTH - blackSideBlack16to9;
      this.professionBarPositionX = this.componentPosition - blackSideBlack16to9 - PROFESSION_BAR_WIDTH;
      this.footBarAnimatePosition = {
        x: (this.componentPosition - this.footBarRightMargin),
        y: (this.windowHeight - FOOT_BAR_HEIGHT) >> 1
      };
      return;
    }
    let xComponentWidth4to3: number = this.getXComponentSizeWidth(NUM_4 / NUM_3);
    let xComponentWidth1to1: number = this.getXComponentSizeWidth(NUM_1 / NUM_1);
    let isPreviewAreaMiddle4to3: boolean = this.isPreviewAreaMiddle(xComponentWidth4to3);
    let bothSideBlack4to3: number =
      isPreviewAreaMiddle4to3 ? (this.windowWidth - xComponentWidth4to3) / 2 : (this.windowWidth - xComponentWidth4to3);
    let sideMargin: number = (bothSideBlack4to3 - COMPONENT_WIDTH) / 2;
    this.componentPosition = this.windowWidth - COMPONENT_WIDTH;
    this.zoomViewTopMargin = this.getLandscapeDiffValue();
    this.zoomViewLeftMargin =
      isPreviewAreaMiddle4to3 ? (bothSideBlack4to3 - QUICK_ZOOM_VIEW_HEIGHT) / 2 - QUICK_ZOOM_MARGIN_BOTTOM_28 :
        sideMargin - QUICK_ZOOM_MARGIN_BOTTOM_28;
    this.treasureBoxTopMargin = (this.windowHeight - this.windowWidth * NUMBER_16_9) / 2 + 16;
    this.treasureBoxLeftMargin =
      isPreviewAreaMiddle4to3 ? (bothSideBlack4to3 - TREASURE_BOX_ELEMENT_INNER_WIDTH) / 2 : sideMargin;
    this.footBarRightMargin = sideMargin;
    this.paramBarPositionX = (this.windowWidth + xComponentWidth1to1) / 2;
    if (!isPreviewAreaMiddle4to3 && this.paramBarPositionX + MIDDLE_COMPONENT_WIDTH > xComponentWidth4to3) {
      this.paramBarPositionX -= MIDDLE_COMPONENT_WIDTH;
    }
    this.modeBarRightMargin = sideMargin;
    this.professionBarPositionX =
      (this.windowWidth + xComponentWidth1to1) / 2 - PROFESSION_BAR_WIDTH + PROFESSION_BAR_BUTTON_WIDTH;
    this.footBarAnimatePosition = {
      x: (this.componentPosition - this.footBarRightMargin),
      y: (this.windowHeight - FOOT_BAR_HEIGHT) >> 1
    };
  }

  private getPortraitZoomDiffValue(): number {
    // 相对模式条的位置
    if (this.windowWidth > WINDOWS_SCREEN_800) {
      return ((this.windowHeight - FOOT_BAR_HEIGHT) >> 1) + FOOT_BAR_HEIGHT / 2 - MODE_BAR_HEIGHT / 2 +
        MODE_BAR_TOP_MARGIN + ZOOM_PORTRAIT_DIFF;
    }
    return ZOOM_VIEW_TOP_MARGIN_VERTICAL - ZOOM_TOP_DIFF;
  }

  private getLandscapeDiffValue(): number {
    // 相对模式条的位置
    if (this.windowHeight > WINDOWS_SCREEN_800) {
      return ((this.windowHeight - FOOT_BAR_HEIGHT) >> 1) + FOOT_BAR_HEIGHT / 2 - MODE_BAR_HEIGHT / 2 +
        MODE_BAR_TOP_MARGIN + ZOOM_LANDSCAPE_DIFF;
    }
    return ZOOM_VIEW_TOP_MARGIN - ZOOM_TOP_DIFF;
  }

  private onBackground(): void {
    HiLog.i(TAG, 'onBackground.');
    RestartService.getInstance().cancelRestart();
    this.cameraErrorDialogController?.close();
    this.isShowCameraError = false;
    this.locationDialogController?.close();
  }

  private timerStateOnChange(): void {
    if (this.isSuperSlowMotion) { // 一般慢动作动效和录像一致
      return;
    }
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
    HiLog.i(TAG, `isFlashEnable: ${this.isFlashEnable}`);
    if (this.isFlashEnable) {
      if (this.recoverFlash) {
        const flashPersistValue =
          PreferencesService.getInstance().getPublicValue(PersistType.FOREVER, PublicTag.FLASH_STATE, FlashMode.OFF);
        if (flashPersistValue !== FlashMode.OFF) {
          this.mAction.changeFunctionValue(FunctionId.FLASH, flashPersistValue);
          PreferencesService.getInstance().putPublicValue(PersistType.FOREVER, PublicTag.FLASH_STATE, FlashMode.OFF);
        }
      }
      return;
    }
    this.recoverFlash = true;
    const flashValue = FeatureManager.getInstance().getFunction(FunctionId.FLASH).getValue() as number;
    PreferencesService.getInstance().putPublicValue(PersistType.FOREVER, PublicTag.FLASH_STATE, flashValue);
    if (flashValue !== FlashMode.OFF) {
      this.mAction.changeFunctionValue(FunctionId.FLASH, FlashMode.OFF);
    }
    this.isLowBatteryTipShowed = PreferencesService.getInstance().getPublicValue(PersistType.FOREVER,
      PublicTag.IS_LOW_BATTERY_TIP_OPENED, false) as boolean;
    HiLog.i(TAG, `isShowLowBatteryExitFlash: ${this.isLowBatteryTipShowed}`);
    if (this.isLowBatteryTipShowed) {
      return;
    }
    TipService.getInstance().showTip($r('app.string.dialog_FlashOff_BatteryLowTips'), 3000, true);
    this.isLowBatteryTipShowed = true;
    PreferencesService.getInstance().putPublicValue(PersistType.FOREVER, PublicTag.IS_LOW_BATTERY_TIP_OPENED, true);
  }

  private createCameraErrorDialog(errorCode: number): void {
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
    if (this.isPicker) {
      HiLog.i(TAG, 'Ignore the errorCode for picker.')
      return;
    }
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

  private locationDialogShow(isToSettingPermission: boolean, data?: RestoreDialogConfirmData): void {
    HiLog.i(TAG, 'locationDialogShow ==' + JSON.stringify(data));
    this.isToSettingPermission = isToSettingPermission;
    if ((data?.restoreConfirmFlag || isToSettingPermission) && !this.isPicker && !data?.isRequestOnSetting) {
      this.createLocationDialog();
      this.locationDialogController?.open();
    }
  }

  private onPreviewFrameStart(data: PreviewFrameStartData): void {
    this.isPreviewFrameStart = data.isPreviewFrameStart;
  }

  private createLocationDialog(): void {
    if (this.isToSettingPermission) {
      // 地理位置权限前往设置弹窗
      this.createLocationToSettingDialog();
    } else {
      // 地理位置权限二次确认弹窗
      this.createLocationConfirmDialog();
    }
  }

  private createLocationToSettingDialog(): void {
    this.locationDialogController = new CustomDialogController({
      builder: ConfirmDialogView({
        cancel: () => {
          HiLog.i(TAG, 'locationSettingDialog ConfirmDialogView cancel.');
          this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
          this.isDialogShow = false;
        },
        confirm: () => {
          //拉起设置
          this.mAction.confirmLocationTOSettingPermission(true);
          this.locationDialogController?.close();
          this.isDialogShow = false;
        },
        title: $r('app.string.camera_location_request_dialog_title'),
        description: $r('app.string.camera_location_request_dialog_content'),
        cancelText: $r('app.string.cancel'),
        confirmText: $r('app.string.permission_dialog_goto_setting_button'),
        rotateAngle: 0,
        currentDirection: this.mDirection,
      }),
      autoCancel: false,
      customStyle: true,
      maskColor: '#66000000',
      cancel: () => {
        this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
        this.isDialogShow = false;
      },
      alignment: DialogAlignment.Center,
    });
  }

  private createLocationConfirmDialog(): void {
    this.locationDialogController = new CustomDialogController({
      builder: ConfirmDialogView({
        cancel: () => {
          this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, false);
          HiLog.i(TAG, 'locationConfirmDialog ConfirmDialogView cancel');
        },
        confirm: () => {
          this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION, true);
        },
        title: $r('app.string.camera_location_request_dialog_title'),
        description: $r('app.string.gps_attention_dialog_need_summary'),
        cancelText: $r('app.string.gps_attention_dialog_need_disable'),
        confirmText: $r('app.string.gps_attention_dialog_need_enable'),
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

  private getDefaultTextSrc(): Resource | string {
    this.isShowTextInfo = false;
    return '';
  }

  private getTimeLapseTabPosition(): TabPosition {
    this.rotateAngle = 0;
    HiLog.i(TAG, 'isShowNightCaptureInfo 1111: ');
    return {
      y: TAB_BAR_HEIGHT + 17,
      x: -40
    }
  }

  private timeLapse(data: ShowParm): void {
    this.showModeBar = data.showModeBar;
  }

  private directionChange(): void {
    this.tabViewPosition = this.getTimeLapseTabPosition();
    if (this.mDirection === WindowDirection.LEFT) {
      this.rotateAngle = 270;
    } else if (this.mDirection === WindowDirection.RIGHT) {
      this.rotateAngle = 90;
    } else {
      this.rotateAngle = 0;
    }
  }

  private prosonChange(data: proSonChangeNumberData): void {
    this.prosonNumber = data.iconId;
  }

  private createExposureConfirmDialog(): void {
    this.exposureConfirmDialogController = new CustomDialogController({
      builder: ConfirmDialogView({
        cancel: () => {
          this.isDialogShow = false;
          HiLog.i(TAG, 'closeExposureDialogConfirm ConfirmDialogView cancel');
        },
        confirm: () => {
          this.professionSetDefaultValue();
          this.isDialogShow = false;
        },
        title: $r('app.string.recover_underexposure_dialog_need_title'),
        description: this.lumationValue < 0.098 ? $r('app.string.recover_underexposure_dialog_need_content') :
          $r('app.string.recover_overexposed_dialog_need_content'),
        cancelText: $r('app.string.m_CANCEL'),
        confirmText: $r('app.string.m_Confirm'),
        rotateAngle: 0,
        currentDirection: this.mDirection,
        isShowSemiCollapsed: false,
      }),
      autoCancel: false,
      customStyle: true,
      maskColor: '#66000000',
      cancel: () => {
        this.isDialogShow = false;
      },
      alignment: DialogAlignment.Center,
    });
  }

  private dialogShowChange(): void {
    GlobalContext.get().setObject('isDialogShow', this.isDialogShow);
  }

  private getExposurePosition(): PositionType {
    return {
      x: this.windowWidth < this.windowHeight ?
        this.paramBarPositionX + ICON_SIZE + 4 : this.paramBarPositionX + ICON_SIZE,
      y: this.windowWidth < this.windowHeight ? TABLET_MARGIN_TOP_VERTICAL + 40 : TABLET_MARGIN_TOP_HORIZONTAL + 40
    };
  }

  private updateLumation(data: LumationConfirmData): void {
    this.lumationValue = data.info;
  }

  private professionSetDefaultValue(): void {
    let isoParams: Map<string, number> = new Map();
    let apertureParams: Map<string, number> = new Map();
    apertureParams.set('pApValue', 0);
    let shutterParams: Map<string, number> = new Map();
    shutterParams.set('pshutterValue', 0);
    if (getStates().get<boolean>('focusExposureReducer', 'isShowFocus')) {
      this.mAction.hideFocus();
    }
    FocusExposureService.getInstance().setFocusValue({
      focusMode: camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO,
      isParamSetting: true
    });
    FocusExposureService.getInstance().setExposureValue({
      exposureMode: camera.ExposureMode.EXPOSURE_MODE_AUTO,
      isParamSetting: true
    });
  }

  private getProBarVisible(): Visibility {
    // 切模式或者切前后置相机启动未完成隐藏
    if (this.state.cameraRunningState !== CameraRunningState.STARTED && this.showProfessionBar) {
      return Visibility.Hidden;
    }

    // 切模式启流成功后更改Profession显示判断
    if (this.state.cameraRunningState === CameraRunningState.STARTED && this.showProfessionBar) {
      this.showProfessionBar = false;
    }

    // 显示大字体隐藏
    if (this.state.isShowBigText && this.videoState === RecordingState.READY) {
      return Visibility.Hidden;
    }

    // 进入沉浸式隐藏
    if (this.immersiveUIType !== UIOperationType.PRO_BAR && this.immersiveOpacity === 0) {
      return Visibility.Hidden;
    }

    // 进入更多页隐藏
    if (this.isShowMorePage) {
      return Visibility.Hidden;
    }

    return Visibility.Visible;
  }
}