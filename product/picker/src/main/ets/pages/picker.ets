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

import lazy { Action, UiStateMode } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import lazy { RecordMode } from '@ohos/common/src/main/ets/function/recordcontrol/RecordMode';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { RecordAction, RecordingState } from '@ohos/common/src/main/ets/function/recordcontrol/RecordAction';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { DefaultIndex } from '../../../../../phone/src/main/ets/pages/default/DefaultIndex';
import lazy { DefaultIndex as DefaultIndexPicker } from './default/DefaultIndex';
import lazy { DefaultIndex as TabletDefaultIndex } from '../../../../../tablet/src/main/ets/pages/default/DefaultIndex';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { ImmersiveActionData, WindowEventData } from '@ohos/common/src/main/ets/utils/types';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { ChangeState, getStates, reduxSubscribe, Unsubscribe } from '@ohos/common/src/main/ets/redux/Store';
import lazy { VolumeShutterService } from '@ohos/common/src/main/ets/service/volume/VolumeShutterService';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import window from '@ohos.window';
import lazy { CustomTransition, TitleAnimation } from '@ohos/common/src/main/ets/animation/CustomNavigationUtils';
import lazy { SettingViewData } from '@ohos/common/src/main/ets/function/setting/SettingFunction';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { FlashMode } from '@ohos/common/src/main/ets/function/enumbase/FlashMode';
import lazy { CameraBasicService } from '@ohos/common/src/main/ets/camera/uithread/CameraBasicService';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { PickerUiService } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { AlertDialogView } from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/AlertDialogView';
import lazy { SettingView } from '../../../../../phone/src/main/ets/pages/SettingView';
import lazy { SettingView as TabletSettingView } from '../../../../../tablet/src/main/ets/pages/SettingView';
import lazy { PropTag, PublicTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { TipService } from '@ohos/common/src/main/ets/component/tip/TipService';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { curves, display } from '@kit.ArkUI';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import treasureBoxConfig from '@ohos/common/src/main/ets/component/treasurebox/default/TreasureBoxConfig';
import lazy {
  CameraErrorData,
  CameraErrorDialogView,
  CameraErrorDialogViewParams
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/CameraErrorDialogView';
import lazy { DIALOG_OFFSET, PrivacyBanner } from '@ohos/common/src/main/ets/component/picker/PrivacyBanner';
import lazy { PICKER_ENTER_EXIT_ANIM_DURATION, PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import power from '@ohos.power';
import screenLock from '@ohos.screenLock';
import lazy { TabletSplitScreenIndex as TabletUIExtensionIndex } from './tablet/TabletSplitScreenIndex';
// import lazy { PickerSheet, PickerType } from '@ohos/pickersheet';
import lazy { CameraErrorCode } from '@ohos/common/src/main/ets/camera/childthread/modules/CameraInputWrap';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
import lazy { PickerActionType } from '@ohos/common/src/main/ets/redux/actions/PickerActionType';
import lazy { SettingViewActionType } from '@ohos/common/src/main/ets/redux/actions/SettingViewActionType';
import lazy { PreviewWrap } from '../../../../../phone/src/main/ets/pages/preview/PreviewWrap';
import lazy { ZIndex } from '@ohos/common/src/main/ets/utils/ZIndex';
import lazy { LandscapeIndex } from '../../../../../phone/src/main/ets/pages/landscape/LandscapeIndex'

let storage = LocalStorage.getShared();
const TAG: string = 'Picker';
const BLUR_RADIUS: number = 80;
const INVALID_BLUR_TIMEOUT_ID = -1;
const FRONT_TIP_UNLOADED: number = 0;
const FRONT_TIP_APPEARING: number = 1;
const PRIVACY_TIP_DELAY: number = 200;

class ZoomFuncValueStruct {
  public zoomRatio?: number = 1;
}

class StateStruct {
  public isShowPageView: boolean = false;
  public isShowtimeLapse: boolean = false;
  public isThirdPartyCall: boolean = false;
  public isOpenTreasureBox: boolean = false;
  public isShowLandscape: boolean = false;
  public isShowDefault: boolean = true;
  public mode: ModeType = ModeType.NONE;
}

class EnterImmersiveData {
  public isImmersive?: boolean = false;
  public mainTrigCompo?: UIOperationType = UIOperationType.NULL;
}

class CollapsStatusData {
  public collapsStatus: display.FoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
}

class PickerDispatcher {
  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeTimeLapse(isShowtimeLapse: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse));
  }

  public stopRecording(): void {
    this.mDispatch(RecordAction.stop());
  }

  public changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public changeTreasureBoxSelectorNone(): void {
    this.mDispatch(TreasureBoxAction.changeTreasureBoxSelector(FunctionId.NONE));
  }

  public closeTreasureBox(): void {
    this.mDispatch(TreasureBoxAction.setTreasureBoxStatus(false));
  }

  public updateShowPickerView(showPicker: boolean): void {
    this.mDispatch(Action.updateShowPickerView(showPicker, true));
  }

  public enableUi(): void {
    this.mDispatch(Action.uiStateWithMode(true, UiStateMode.EXCLUDE_PREVIEW));
  }

  public enableUiWithMode(uiStateMode: UiStateMode, excludeComponent: string): void {
    this.mDispatch(Action.uiStateWithMode(true, uiStateMode, excludeComponent));
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.ZOOM_BAR));
  }

  public changeXComponentSize(size: Size): void {
    this.mDispatch(Action.changeXComponentSize(size.width, size.height));
  }

  public uiEnabled(uiEnabled: boolean): void {
    this.mDispatch(Action.uiState(uiEnabled));
  }

  public onBackPress(): void {
    this.mDispatch(Action.onBackPress());
  }

  public handleEyeTipAnim(): void {
    this.mDispatch(Action.handleEyeTipAnim());
  }

  private mDispatch: Dispatch = (data) => data;
}

@Entry(storage)
@Component
struct MyPicker {
  @State state: StateStruct = new StateStruct();
  private mAction: PickerDispatcher = new PickerDispatcher();
  private isNotifiedPageAppear: boolean = false;
  // 音量键订阅
  private volumeService: VolumeShutterService = VolumeShutterService.getInstance();
  @StorageLink('isAnyDialogOpening') @Watch('volumeKeySubscribeOrNot') isAnyDialogOpening: boolean = false;
  @State @Watch('updateIsAnyDialogOpening') isShowCameraError: boolean = false;
  // 录像控制
  @State videoState: RecordingState = RecordingState.READY;
  // 百宝箱
  @StorageLink('treasureBoxSelector') treasureBoxSelector: FunctionId = FunctionId.NONE;
  // 沉浸式
  @State immersiveUIType: UIOperationType = UIOperationType.NULL;
  @State immersiveOpacity: number = 1;
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  //预授权启动页是否显示
  @StorageLink('isIntroLoaded') @Watch('onIsIntroLoadedChange') isIntroLoaded: boolean = false;
  //Picker首次点开弹窗
  @State isDialogLoaded: boolean = false;
  @State @Watch('statusChanged') isShowSemiCollapsed: boolean = false;
  @State @Watch('statusChanged') isShowLandscape: boolean = false;
  @State @Watch('onIsDialogOpenChange') @Watch('updateIsAnyDialogOpening') isBannerOpen: boolean = false;
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State translateContent: number | string = 0;
  @State translateBlackPage: number | string = '100%';
  @State @Watch('lowBatteryExitFlashDialogShow') isFlashEnable: boolean = true;
  @State @Watch('updateIsAnyDialogOpening') isShowExitFlash: boolean = false;
  @State @Watch('updateIsAnyDialogOpening') isShowExitCamera: boolean = false;
  @State isLowBatteryTipShowed: boolean = false;
  @State isShowLowBatteryExitFlash: boolean = false;
  @State isBannerVisible: boolean = true;
  @State @Watch('onLearnMoreChange') isLearnMore: boolean = false;
  dialogController: CustomDialogController = new CustomDialogController({
    builder: PrivacyBanner({
      isBannerLoaded: this.isDialogLoaded, isBannerOpen: this.isBannerOpen,
      isBannerVisible: this.isBannerVisible
    }),
    autoCancel: false,
    alignment: DialogAlignment.Top,
    maskColor: Color.Transparent,
    customStyle: true,
    offset: { dx: 0, dy: DIALOG_OFFSET },
    isModal: false,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      this.onWillDismissFunction(dismissDialogAction);
    }
  })
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @StorageLink(`isTipComponentReady`) @Watch('isTipComponentReadyChange') isTipComponentReady: boolean = false;
  @State isPickerInSplitScreen: boolean = PickerUtils.getIsPickerInSplitScreen();
  @State isShowPickerBuilder: boolean = false;
  @State @Watch('onIsShowPickerViewChange') isShowPickerView: boolean = false;
  @State isFirstTimeOpenPicker: boolean = true;
  @State isShowIndex: boolean = true;
  @State @Watch('statusChanged') isShowTricollaps: boolean = false;
  @State isHalfCollapsLEM: boolean = false;
  @State isVdeCollapsed: boolean = false;
  @State dpiChanged: boolean = false;
  @StorageLink('isChangingModeOrSwitchingCamera') isChangingModeOrSwitchingCamera: boolean = false;
  @StorageLink('isPickerVideoReady') isPickerVideoReady: boolean = false;
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  // 相机异常弹窗
  private cameraErrorDialogController: CustomDialogController | null = null;
  private errorCode: number = 0;
  private isIntroPageNeeded: boolean = false;
  private exitCameraDialogController: CustomDialogController | null = null;
  private exitTimer: number = 5;
  private mTimerId: number = Number.MIN_VALUE;
  private pickerBannerTimer: number = Number.MIN_VALUE;
  private session: UIExtensionContentSession | undefined = undefined;
  private isInImmersive: boolean | undefined = false;
  private blurTimeoutId: number = INVALID_BLUR_TIMEOUT_ID;
  private isFirstTip: boolean = true;
  @State windowStageEventType: window.WindowStageEventType = window.WindowStageEventType.ACTIVE;

  @Builder
  PageMap(navigationName: string) {
    if (navigationName === 'PrivacyPolicyView') {
    } else if (navigationName === 'SettingView') {
      if (DeviceInfo.isTablet()) {
        TabletSettingView({ pageId: Date.now() });
      } else {
        SettingView({ pageId: Date.now() });
      }
    }
  }

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.mDirection = state.get<WindowDirection>('contextReducer', 'direction');
      this.isFlashEnable = state.get<boolean>('uiReducer', 'isFlashEnable');
      this.isShowPickerView = state.get<boolean>('uiReducer', 'showPicker');
      this.isShowTricollaps = state.get<boolean>('collapsReducer', 'isShowTricollaps');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      changeState(this.state, {
        isShowPageView: state.get<boolean>('settingViewReducer', 'isShowSettingView'),
        isShowtimeLapse: state.get<boolean>('settingReducer', 'isShowtimeLapse'), // 是否显示定时拍照倒计时
        isThirdPartyCall: state.get<boolean>('contextReducer', 'isThirdPartyCall'),
        isOpenTreasureBox: state.get<boolean>('treasureBoxReducer', 'isOpen'),
        isShowLandscape: state.get<boolean>('collapsReducer', 'isShowLandscape'),
        isShowDefault: state.get<boolean>('collapsReducer', 'isShowDefault'),
        mode: state.get<ModeType>('modeReducer', 'mode'),
      });
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    PickerUiService.getInstance().setVideoTimeBeforeCollapsing(0);
    this.isPickerVideoReady = false;
    this.volumeService.volumeKeySubscribe();
    this.mEventBus.on(CameraActionType.STARTED, this.indexOnStarted.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.ERROR, (data: CameraErrorData) => this.cameraErrorDialogShow(data.code),
      this.mBase.hashCode());
    GlobalContext.get().setObject('resetZoomRatio', () => {
      this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: 1 } as ZoomFuncValueStruct);
    });
    this.mEventBus.on([ActionType.ACTION_CHANGE_TIME_LAPSE, ActionType.ACTION_IS_ENTER_IMMERSIVE],
      this.isEnterImmersive.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.CHANGE_WINDOW_EVENT_TYPE, this.onWindowEventType.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_EXIT_FLASH_DIALOG, () => this.exitFlashDialogShow(),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LOW_BATTERY_SHOW_EXIT_FLASH_DIALOG,
      () => this.lowBatteryExitFlashDialogShow(), this.mBase.hashCode());
    this.mEventBus.on(SettingViewActionType.ACTION_SHOW_SETTING_VIEW,
      this.onSettingViewShow.bind(this), this.mBase.hashCode());
    this.initializeIsDialogLoaded();
    if ((this.isShowLandscape && !this.isShowSemiCollapsed) || DeviceInfo.isTablet()) { //展开态
      WindowService.getInstance().setWinOrientation(window.Orientation.FOLLOW_DESKTOP);
    } else {
      WindowService.getInstance().setWinOrientation(window.Orientation.PORTRAIT);
    }
    this.mEventBus.on(ActionType.ACTION_IS_ENTER_IMMERSIVE, this.lockScreenRotation.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.resetState.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.ON_SIZE_CHANGE, this.onSizeChanged.bind(this), this.mBase.hashCode());
    this.mEventBus.on(PickerActionType.EXIT_PICKER_WITHOUT_RESULTS, this.exitPicker.bind(this), this.mBase.hashCode());
    this.mEventBus.on(PickerActionType.LEARN_MORE_SECURITY_CAMERA,
      this.learnMoreSecurityCamera.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_PICKER_DPI_CHANGE, this.onPickerDpiChanged.bind(this), this.mBase.hashCode());
    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.CHANGE_OUTPUT_TYPE,
      CameraActionType.SWITCH_CAMERA_CHANGE_MODE, CameraActionType.SWITCH_CAMERA],
      this.onChangeModeOrSwitchCamera.bind(this), this.mBase.hashCode());
  }

  onPageShow(): void {
    HiLog.i(TAG, 'onPageShow E.');
    if (this.isIntroPageNeeded) {
      this.isIntroLoaded = PreferencesService.getInstance()
        .getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean;
    }
    // 规避picker cppcrash
    AppStorage.setOrCreate('animationAble', true);
    HiLog.i(TAG, 'onPageShow X.');
  }

  onPageHide(): void {
    HiLog.i(TAG, 'onPageHide E.');
    this.stopCameraRecording();
    HiLog.i(TAG, 'onPageHide X.');
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  onBackPress(): boolean {
    HiLog.i(TAG, 'onBackPress E.');
    if (this.videoState === RecordingState.STARTING) {
      HiLog.i(TAG, 'videoState: ' + this.videoState);
      return true;
    }
    if (this.state.isThirdPartyCall) {
      if (this.isShowPickerView) {
        this.mAction.onBackPress();
        return true;
      }
    }
    if (this.state.isShowPageView) {
      this.mAction.changeFunctionValue(FunctionId.SETTING, false);
      return true;
    }
    if (this.state.isShowtimeLapse) {
      this.mAction.changeTimeLapse(false);
      return true;
    }
    if (this.videoState === RecordingState.RECORDING || this.videoState === RecordingState.PAUSED) {
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
      return true;
    }
    if (this.treasureBoxSelector !== FunctionId.NONE) {
      this.mAction.changeTreasureBoxSelectorNone();
      return true;
    }
    if (this.state.isOpenTreasureBox && !this.isHalfCollapsLEM) {
      this.mAction.closeTreasureBox();
      return true;
    }
    this.exitPicker();
    HiLog.i(TAG, 'onBackPress X.');
    return true;
  }

  public stopCameraRecording() {
    HiLog.i(TAG, 'stopCameraRecording E.');
    if (this.state.isShowtimeLapse) {
      this.mAction.changeTimeLapse(false);
    }
    if (this.videoState === RecordingState.RECORDING || this.videoState === RecordingState.PAUSED) {
      this.mAction.stopRecording();
      this.mAction.changeFunctionValue(FunctionId.RECORD_CONTROL, RecordMode.TO_STOP);
    }
    HiLog.i(TAG, 'stopCameraRecording X.');
  }

  @Builder
  PickerUIBuilder() {
    Navigation(this.pageInfos) {
      Stack({ alignContent: Alignment.Top }) {
        if (this.state.isShowLandscape || this.isShowTricollaps) {
          PreviewWrap();
          LandscapeIndex({
            isPicker: true,
            immersiveUIType: this.immersiveUIType,
            immersiveOpacity: this.immersiveOpacity
          })
            .hitTestBehavior(HitTestMode.Transparent)
        }
        if (this.state.isShowDefault && !DeviceInfo.isTablet()) {
          PreviewWrap();
          if (ContextManager.getInstance().getUiExtensionContext() && !this.isVdeCollapsed) {
            DefaultIndexPicker({
              isPicker: true,
              immersiveUIType: this.immersiveUIType,
              immersiveOpacity: this.immersiveOpacity
            })
              .visibility(this.isShowIndex ? Visibility.Visible : Visibility.Hidden)
              .animation({ iterations: 0 })
              .hitTestBehavior(HitTestMode.Transparent)
          } else {
            DefaultIndex({
              isPicker: true,
              immersiveUIType: this.immersiveUIType,
              immersiveOpacity: this.immersiveOpacity
            })
              .hitTestBehavior(HitTestMode.Transparent)
          }
        } else if (this.state.isShowDefault && DeviceInfo.isTablet()) {
          PreviewWrap({
            buildFromPicker: true
          });
          if (ContextManager.getInstance().getUiExtensionContext()) {
            TabletUIExtensionIndex({
              isPicker: true,
              immersiveUIType: this.immersiveUIType,
              immersiveOpacity: this.immersiveOpacity
            });
          } else {
            LandscapeIndex({
              isPicker: true,
              immersiveUIType: this.immersiveUIType,
              immersiveOpacity: this.immersiveOpacity
            })
              .hitTestBehavior(HitTestMode.Transparent)
          }
        }

        if (this.isLearnMore) {
          // PickerSheet({
          //   appIcon: $r('app.media.icon'),
          //   curPickerKey: PickerType.CAMERA_PICKER,
          //   onClose: () => {
          //     this.isLearnMore = false;
          //   },
          //   windowProxy: PickerUiService.getInstance().getPickerWindowProxy()
          // })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
      .offset({ x: this.isVertical() ? this.translateContent : 0, y: this.isVertical() ? 0 : this.translateContent })
    }
    .width('100%')
    .height('100%')
    .hideTitleBar(true)
    .navDestination(this.PageMap)
    .mode(NavigationMode.Stack)
    .backgroundColor(Color.Black)
    .blur(this.dpiChanged ? BLUR_RADIUS : 0)
    .onTouch(() => {
      let isLoaded = PreferencesService.getInstance()
        .getPropValue(PersistType.FOREVER, PropTag.IS_FRONT_CAMERA_TIPS_LOADED, FRONT_TIP_UNLOADED) as number;
    })
    .customNavContentTransition((from: NavContentInfo, to: NavContentInfo, operation: NavigationOperation) => {
      if (from.mode === NavDestinationMode.DIALOG || to.mode === NavDestinationMode.DIALOG) {
        return undefined;
      }
      if (DeviceInfo.isTablet()) {
        return undefined;
      }
      HiLog.i(TAG, `to info: ${JSON.stringify(to)}`);
      HiLog.i(TAG, `from info: ${JSON.stringify(from)}`);
      HiLog.i(TAG, `operation: ${operation}`);
      // 暂时只设置页做自定义动效
      if (!((to.name === 'SettingView' && from.index === -1) || (from.name === 'SettingView' && to.index === -1))) {
        return undefined;
      }
      let customAnimation: NavigationAnimatedTransition = {
        onTransitionEnd: (isSuccess: boolean) => {
          this.mAction.uiEnabled(true);
          HiLog.i(TAG, `current transition result is ${isSuccess}`);
        },
        // 转场开始时系统调用该方法，并传入转场上下文代理对象
        transition: (transitionProxy: NavigationTransitionProxy) => {
          HiLog.i(TAG, 'trigger transition callback');
          let fromAnimation: TitleAnimation | undefined = CustomTransition.getInstance().getAnimateParam(from.index);
          let toAnimation: TitleAnimation | undefined = CustomTransition.getInstance().getAnimateParam(to.index);
          let isPop: boolean = NavigationOperation.POP === operation;
          // title offset animation
          if (fromAnimation?.transitionAnimation?.start) {
            fromAnimation?.transitionAnimation?.start(isPop, true);
          }
          if (toAnimation?.transitionAnimation?.start) {
            toAnimation.transitionAnimation.start(isPop, false);
          }
          animateTo({
            duration: 450, curve: curves.interpolatingSpring(0.0, 1.0, 342.0, 37.0), onFinish: () => {
              if (fromAnimation?.transitionAnimation?.onFinish) {
                fromAnimation.transitionAnimation.onFinish(isPop, true);
              }
              if (toAnimation?.transitionAnimation?.onFinish) {
                toAnimation.transitionAnimation.onFinish(isPop, false);
              }
            }
          }, () => {
            if (from.index === -1) {
              this.translateContent = this.mDirection === WindowDirection.LEFT ? '20%' : '-20%';
              this.translateBlackPage = this.mDirection === WindowDirection.LEFT ? '-20%' : '20%';
            }
            if (to.index === -1) {
              this.translateContent = 0;
              this.translateBlackPage = this.mDirection === WindowDirection.LEFT ? '-100%' : '100%';
            }
            if (fromAnimation?.transitionAnimation?.finish) {
              fromAnimation.transitionAnimation.finish(isPop, true);
            }
            if (toAnimation?.transitionAnimation?.finish) {
              toAnimation.transitionAnimation.finish(isPop, false);
            }
          })
          // title in animation
          if (toAnimation?.titleAnimation?.start) {
            toAnimation.titleAnimation.start(isPop, false);
          }
          animateTo({
            duration: 150,
            delay: 33,
            curve: Curve.Sharp,
            onFinish: () => {
              if (toAnimation?.titleAnimation?.onFinish) {
                toAnimation.titleAnimation.onFinish(isPop, false);
              }
            }
          }, () => {
            if (toAnimation?.titleAnimation?.finish) {
              toAnimation.titleAnimation.finish(isPop, false);
            }
          })
          // title out animation
          animateTo({
            duration: 150,
            delay: 17,
            curve: Curve.Sharp,
            onFinish: () => {
              if (fromAnimation?.titleAnimation?.onFinish) {
                fromAnimation.titleAnimation.onFinish(isPop, true);
              }
            }
          }, () => {
            if (fromAnimation?.titleAnimation?.finish) {
              fromAnimation.titleAnimation.finish(isPop, true);
            }
          })
          // back button in animation
          if (fromAnimation?.opacityAnimation.start) {
            fromAnimation.opacityAnimation.start(isPop, true);
          }
          if (toAnimation?.opacityAnimation.start) {
            toAnimation.opacityAnimation.start(isPop, false);
          }
          // back in animation
          animateTo({
            duration: 200,
            delay: 150,
            curve: Curve.Sharp,
            onFinish: () => {
              if (toAnimation?.opacityAnimation.onFinish) {
                toAnimation?.opacityAnimation.onFinish(isPop, false);
              }
            }
          }, () => {
            if (toAnimation?.opacityAnimation.finish) {
              toAnimation?.opacityAnimation.finish(isPop, false);
            }
          })
          animateTo({
            duration: 67, curve: Curve.Sharp, onFinish: () => {
              if (fromAnimation?.opacityAnimation.onFinish) {
                fromAnimation.opacityAnimation.onFinish(isPop, true);
              }
            }
          }, () => {
            if (fromAnimation?.opacityAnimation.finish) {
              fromAnimation.opacityAnimation.finish(isPop, true);
            }
          })
        }
      };
      return customAnimation;
    })
  }

  build() {
    if (ContextManager.getInstance().getUiExtensionContext()) {
      Column()
        .width('100%')
        .height('100%')
        .onSizeChange(() => {
          this.isShowPickerBuilder = true;
        })
        .blur(this.dpiChanged ? BLUR_RADIUS : 0)
        .bindContentCover(this.isShowPickerBuilder, this.PickerUIBuilder(), {
          modalTransition: ModalTransition.DEFAULT,
          backgroundColor: Color.Transparent,
          onWillDisappear: () => {
            this.contentCoverOnWillDisappearFunc();
          },
          onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
            if (dismissDialogAction.reason === DismissReason.PRESS_BACK) {
              this.onBackPress();
            }
          },
          onAppear: () => {
            this.notifyPageAppear();
          }
        })
    } else {
      this.PickerUIBuilder();
    }
  }

  @Builder
  blackPageBuilder(): void {
    Column() { // 黑色背景 防止设置页旋转的时候漏相机首页
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .offset({ x: this.isVertical() ? this.translateBlackPage : 0, y: this.isVertical() ? 0 : this.translateBlackPage })
  }

  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };

  private onPickerDpiChanged(): void {
    this.dpiChanged = true;
    if (this.blurTimeoutId !== INVALID_BLUR_TIMEOUT_ID) {
      clearTimeout(this.blurTimeoutId);
    }
    this.blurTimeoutId = setTimeout(() => {
      this.dpiChanged = false;
      this.blurTimeoutId = INVALID_BLUR_TIMEOUT_ID;
    }, 600);
  }

  private onSizeChanged(): void {
    this.isFirstTimeOpenPicker = false;
    this.isPickerInSplitScreen = PickerUtils.getIsPickerInSplitScreen();
  }

  private notifyPageAppear(): void {
    if (!this.isNotifiedPageAppear) {
      try {
        ContextManager.getInstance().getUiExtensionSession().sendData({ code: 1 });
      } catch (error) {
        HiLog.e(TAG, `BusinessError: ` + error);
      }
      this.isNotifiedPageAppear = true;
    }
  }

  private onChangeModeOrSwitchCamera(): void {
    this.isChangingModeOrSwitchingCamera = true;
  }

  private indexOnStarted(): void {
    this.isChangingModeOrSwitchingCamera = false;
  }

  private isTipComponentReadyChange(): void {
    // 在aboutToAppear中会调用initializeIsDialogLoaded(), 但是若此时Tip组件还未创建成功则不会展示提示信息
    // 当Tip组件创建成功时再次调用initializeIsDialogLoaded(), 触发提示信息展示
    HiLog.i(TAG, `TipComponentReady: ${this.isTipComponentReady}`);
    if (this.isFirstTip) {
      this.initializeIsDialogLoaded();
    }
  }

  private onIsShowPickerViewChange(): void {
    // 规避picker拍照后从多任务切到相机时订阅音量键导致再次拉起picker时无法订阅音量键
    if (this.windowStageEventType === window.WindowStageEventType.INACTIVE) {
      return;
    }
    if (this.isShowPickerView) {
      this.volumeService.volumeKeyUnsubscribe();
    } else {
      this.volumeService.volumeKeySubscribe();
    }
  }

  private rotationUnLockedByCollapsChange(data: CollapsStatusData): void {
    if (display.FoldStatus.FOLD_STATUS_EXPANDED === data?.collapsStatus) {
      return;
    }
    HiLog.i(TAG, 'rotationUnLocked CollapsChange');
    // 仅触发于大屏进入沉浸式锁定后直接切换状态的情况，因此不需要锁定ui元素到窗口方向
    WindowService.getInstance().setForceUnlockWindowRotation(false);
  }

  private lockScreenRotation(data: EnterImmersiveData): void {
    this.isInImmersive = data.isImmersive;
    HiLog.i(TAG, 'lockScreenRotation:' + this.isInImmersive);
    if (this.isInImmersive) {
      WindowService.getInstance().setLockWindowRotation(true);
    } else {
      WindowService.getInstance().setLockWindowRotation(false);
    }
  }

  private volumeKeySubscribeOrNot(): void {
    HiLog.i(TAG, `isAnyDialogOpening: ${this.isAnyDialogOpening}`);
    if (this.isAnyDialogOpening) {
      HiLog.i(TAG, `volumeKeySubscribeOrNot: unsubscribe volumeKey`);
      this.volumeService.volumeKeyUnsubscribe();
    } else {
      HiLog.i(TAG, `volumeKeySubscribeOrNot: subscribe volumeKey`);
      this.volumeService.volumeKeySubscribe();
    }
  }

  private updateIsAnyDialogOpening(): void {
    this.isAnyDialogOpening = this.isShowCameraError || this.isShowExitFlash || this.isShowExitCamera;
  }

  private updateLandScapeSize() {
    let size: Size = CameraBasicService.getInstance().getPreviewDisplaySize();
    if (getStates().get<boolean>('collapsReducer', 'isShowTricollaps')) {
      return;
    }
    if (getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed')) {
      const displayWidth = getStates().get<number>('windowReducer', 'windowWidth');
      const semiWidth = displayWidth / 2;
      const semiHeight = semiWidth * (size.height / size.width);
      this.mAction.changeXComponentSize({ width: semiWidth, height: semiHeight });
    } else {
      this.mAction.changeXComponentSize(size);
    }
  }

  private statusChanged(): void {
    HiLog.i(TAG, `statusChanged isShowSemiCollapsed: ${this.isShowSemiCollapsed},immersiveUIType: ${this.immersiveUIType}.`);
    if (this.immersiveUIType !== UIOperationType.NULL) {
      if (this.state.isShowtimeLapse) {
        return;
      }
      this.mAction.enableUiWithMode(UiStateMode.EXCLUDE_COMPONENT, UIOperationType.NULL);
      this.mAction.isEnterImmersive(false);
    }
    if (!((this.isShowLandscape || this.isShowTricollaps || DeviceInfo.isTablet()) && !this.isShowSemiCollapsed)) { //非展开态
      WindowService.getInstance().unlockXComponentSurface();
    }
  }

  private resetState(): void {
    // 同进程picker退出状态需复位
    if (this.state.isOpenTreasureBox) {
      this.mAction.closeTreasureBox();
      treasureBoxConfig.setIsOpening(false);
    }
    this.isFirstTimeOpenPicker = true;
  }

  private directionChange(): void {
    if (this.mDirection === WindowDirection.BOTTOM) {
      return;
    }
    if (this.translateContent === 0) {
      this.translateBlackPage = this.mDirection === WindowDirection.LEFT ? '-100%' : '100%';
    } else {
      this.translateContent = this.mDirection === WindowDirection.LEFT ? '20%' : '-20%';
      this.translateBlackPage = this.mDirection === WindowDirection.LEFT ? '-20%' : '20%';
    }
    this.reOpenCameraErrorDialog();
    this.reOpenExitFlashDialog();
  }

  private isVertical(): boolean {
    return this.mDirection === WindowDirection.TOP || this.mDirection === WindowDirection.BOTTOM;
  }

  private onSettingViewShow(data: SettingViewData): void {
    HiLog.i(TAG, 'onSettingViewShow E.');
    if (data && data.isShowSettingView) {
      this.isBannerVisible = false;
      this.pageInfos.pushPath({ name: 'SettingView' });
      this.mAction.uiEnabled(false);
      WindowService.getInstance().setSpecificSystemNavigationEnabled(true, true, true);
    } else {
      this.pageInfos.pop();
      this.mAction.uiEnabled(true);
      WindowService.getInstance().setSpecificSystemNavigationEnabled(true, true, false);
      this.isBannerVisible = true;
    }
    HiLog.i(TAG, 'onSettingViewShow X.');
  }

  private onWindowEventType(data: WindowEventData): void {
    if (data.windowStageEventType === window.WindowStageEventType.INACTIVE) {
      this.windowStageEventType = window.WindowStageEventType.INACTIVE;
      this.volumeService.volumeKeyUnsubscribe();
    } else if (data.windowStageEventType === window.WindowStageEventType.ACTIVE) {
      this.windowStageEventType = window.WindowStageEventType.ACTIVE;
      this.volumeService.volumeKeySubscribe();
    }
  }

  private isEnterImmersive(data: ImmersiveActionData): void {
    let mIsImmersive: boolean = false;
    let mImmersiveUIType: UIOperationType = UIOperationType.NULL;
    let json: ImmersiveActionData = JSON.parse(JSON.stringify(data));
    HiLog.i(TAG, `isEnterImmersive json: ${JSON.stringify(data)}.`)
    if (json.isShowtimeLapse !== undefined) { // 定时拍摄需要状态变量渲染组件,就不再重复发Action了直接复用
      mIsImmersive = json.isShowtimeLapse;
      mImmersiveUIType = mIsImmersive ? UIOperationType.TIMELAPSE : UIOperationType.NULL;
    } else {
      if (json.isImmersive !== undefined) {
        mIsImmersive = json.isImmersive;
      }
      if (json.mainTrigCompo !== undefined && mIsImmersive) {
        mImmersiveUIType = json.mainTrigCompo;
      }
    }

    if (mIsImmersive) {
      this.immersiveUIType = mImmersiveUIType;
      this.immersiveOpacity = 1;
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_150,
        curve: Curve.Sharp,
      }, () => {
        this.immersiveOpacity = 0;
      })
    } else {
      this.immersiveOpacity = 0;
      animateToImmediately({
        duration: AnimSpecifications.ANIM_DURATION_150,
        curve: Curve.Sharp,
        onFinish: () => {
          this.immersiveUIType = mImmersiveUIType; // 保证退出沉浸式时self不受opacity影响
        }
      }, () => {
        this.immersiveOpacity = 1;
      })
    }
  }

  private isShowDialog(): boolean {
    if (this.isVdeCollapsed) {
      return false;
    }
    if (this.isIntroPageNeeded) {
      return this.isIntroLoaded && !this.isDialogLoaded;
    } else {
      return !this.isDialogLoaded && !this.isBannerOpen;
    }
  }

  private initializeIsDialogLoaded(): void {
    this.isDialogLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.PICKER_IS_BANNER_LOADED, false) as boolean;
    HiLog.i(TAG, `isDialogLoaded was initialized as: ${this.isDialogLoaded}`);
    if (this.isShowDialog()) {
      this.isFirstTip = false;
      if (this.pickerBannerTimer !== Number.MIN_VALUE) {
        clearTimeout(this.pickerBannerTimer);
        this.pickerBannerTimer = Number.MIN_VALUE;
      }
      if (ContextManager.getInstance().getUiExtensionContext()) {
        // picker banner需要设置300ms延时出现，否则会被盖在PickerUIBuilder下面
        this.pickerBannerTimer = setTimeout(() => {
          // this.dialogController.open();隐藏banner
          this.isBannerOpen = true;
        }, PICKER_ENTER_EXIT_ANIM_DURATION);
      } else {
        // this.dialogController.open();隐藏banner
        this.isBannerOpen = true;
      }
    }
    if (this.isDialogLoaded && this.isTipComponentReady || this.isVdeCollapsed) {
      this.showPrivacyTip();
      this.isFirstTip = false;
    }
  }

  private showPrivacyTip(): void {
    // 延时200ms再弹“安全访问”，避免picker内层Tip还未上树
    setTimeout(() => {
      TipService.getInstance().showTip('', 3500, false, undefined, false, false, true);
    }, PRIVACY_TIP_DELAY);
  }

  private onIsIntroLoadedChange(): void {
    if (this.isShowDialog()) {
      // this.dialogController.open();隐藏banner
      this.isBannerOpen = true;
    }
  }

  private onIsDialogOpenChange(): void {
    HiLog.i(TAG, `isDialogOpen was changed to: ${this.isBannerOpen}.`);
    if (this.isBannerOpen) {
      this.volumeService.volumeKeyUnsubscribe();
      HiLog.i(TAG, 'onIsDialogOpenChange unsubscribes volumeKey.');
    } else {
      HiLog.i(TAG, 'onIsDialogOpenChange subscribes volumeKey.');
      this.volumeService.volumeKeySubscribe();
    }
  }

  private onWillDismissFunction(dismissDialogAction: DismissDialogAction) {
    let isPrivacyPolicyViewShown: boolean | undefined = AppStorage.get('isPrivacyPolicyViewShown');
    HiLog.i(TAG, `reason=${dismissDialogAction.reason}, ${isPrivacyPolicyViewShown}`);
    if (dismissDialogAction.reason === DismissReason.PRESS_BACK && isPrivacyPolicyViewShown) {
      this.pageInfos.pop();
      return;
    }
    if (dismissDialogAction.reason === DismissReason.PRESS_BACK && this.state.isShowPageView &&
      !isPrivacyPolicyViewShown) {
      this.mAction.changeFunctionValue(FunctionId.SETTING, false);
    } else if (dismissDialogAction.reason === DismissReason.PRESS_BACK && !isPrivacyPolicyViewShown) {
      this.onBackPress();
    } else {
      dismissDialogAction.dismiss();
    }
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

  private createCameraErrorDialog(errorCode: number): void {
    if (errorCode === CameraErrorCode.DEVICE_FREQUENTLY_SWITCHED ||
      errorCode === CameraErrorCode.CAMERA_LENS_RETRACTED) {
      return;
    }
    HiLog.i(TAG, `pass errorCode: ${errorCode}`);
    let params: CameraErrorDialogViewParams =
      CameraErrorDialogView.getDefaultParams(errorCode); // record for reOpenCameraErrorDialog function
    this.errorCode = errorCode
    this.cameraErrorDialogController = new CustomDialogController({
      builder: CameraErrorDialogView({
        confirm: () => {
          this.cameraErrorDialogController?.close();
          this.isShowCameraError = false;
          params.confirm();
        },
        title: params.title,
        description: params.description,
        confirmText: params.confirmText,
        rotateAngle: this.getRotate(),
        currentDirection: this.mDirection,
      }),
      autoCancel: false,
      maskColor: '#66000000',
      alignment: DialogAlignment.Center,
      customStyle: true
    });
  }

  private createExitCameraDialog(): void {
    HiLog.i(TAG, 'createExitLocationDialog');
    this.exitCameraDialogController = new CustomDialogController({
      builder: AlertDialogView({
        confirm: () => {
          this.exitCameraDialogController?.close();
          this.isShowExitCamera = false;
          this.terminateCamera();
        },
        title: $r('app.string.device_hot_exit_tips', this.exitTimer),
        confirmText: $r('app.string.dialog_comform_exit_new'),
      }),
      autoCancel: false,
      customStyle: true,
      maskColor: $r('sys.color.mask_fourth'),
      alignment: DialogAlignment.Center,
    });
  }

  private cameraErrorDialogShow(errorCode: number): void {
    HiLog.i(TAG, `errorCode == ${errorCode}`);
    let isBackground: boolean | undefined = AppStorage.get<boolean>('isBackground');
    let isActive: boolean = power.isActive();
    let isLocked: boolean = screenLock.isLocked();
    HiLog.i(TAG, `isBackground: ${isBackground}, isActive: ${isActive}, isLocked: ${isLocked}`);
    if (isBackground || !isActive || isLocked || errorCode === CameraErrorCode.DEVICE_FREQUENTLY_SWITCHED ||
      errorCode === CameraErrorCode.CAMERA_LENS_RETRACTED) {
      HiLog.i(TAG, 'Ignore the errorCode.');
      return;
    }
    this.cameraErrorDialogController?.close();
    this.isShowCameraError = false;
    this.createCameraErrorDialog(errorCode);
    this.cameraErrorDialogController?.open();
    this.isShowCameraError = true;
  }

  private exitFlashDialogShow(): void {
    this.isShowExitFlash = true;
    TipService.getInstance().showTip($r('app.string.device_hot_flash_off_tips'), 3000, true);
    this.mAction.changeFunctionValue(FunctionId.FLASH, FlashMode.OFF);
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

  private reOpenCameraErrorDialog(): void {
    if (this.mDirection === WindowDirection.BOTTOM || !this.isShowCameraError) {
      return;
    }
    HiLog.i(TAG, 'reOpenExitFlashDialog' + this.isShowCameraError);
    if (this.mTimerId !== Number.MIN_VALUE) {
      clearTimeout(this.mTimerId);
      this.mTimerId = Number.MIN_VALUE;
    }

    this.cameraErrorDialogController?.close();
    this.isShowCameraError = false;
    this.createCameraErrorDialog(this.errorCode);
    this.mTimerId = setTimeout((): void => {
      this.cameraErrorDialogController?.open();
      this.isShowCameraError = true;
    }, 150);
  }

  private reOpenExitFlashDialog(): void {
    if (this.mDirection === WindowDirection.BOTTOM || !this.isShowExitFlash) {
      return;
    }
    this.isShowExitFlash = false;
  }

  private getRotate(): number {
    if (DeviceInfo.isTablet()) {
      return 0;
    }
    HiLog.i(TAG, `mDirection : ${this.mDirection} `);
    switch (this.mDirection) {
      case WindowDirection.TOP:
        return 0;
      case WindowDirection.BOTTOM:
        return 0;
      case WindowDirection.RIGHT:
        return AnimSpecifications.ANIM_ROTATE_90;
      case WindowDirection.LEFT:
        return AnimSpecifications.ANIM_ROTATE_270;
      default:
        return 0;
    }
  }

  private exitPicker(): void {
    if (ContextManager.getInstance().getUiExtensionContext()) {
      if (this.isBannerOpen) {
        this.dialogController.close();
        setTimeout(() => {
          this.isShowPickerBuilder = false;
        }, PICKER_ENTER_EXIT_ANIM_DURATION);
      } else {
        this.isShowPickerBuilder = false;
      }
    } else {
      PickerUiService.getInstance().back();
    }
  }

  private learnMoreSecurityCamera(): void {
    this.isLearnMore = true;
  }

  private contentCoverOnWillDisappearFunc(): void {
    HiLog.begin(TAG, `contentCoverOnWillDisappearFunc`);
    setTimeout(() => {
      PickerUiService.getInstance().back();
    }, PICKER_ENTER_EXIT_ANIM_DURATION);
  }

  private onLearnMoreChange(changedPropertyName: string): void {
    AppStorage.setOrCreate('inPrivacyLearnMore', this.isLearnMore);
  }
}
