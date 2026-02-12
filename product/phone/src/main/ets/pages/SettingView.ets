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

import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { SettingMenuItem } from '@ohos/common/src/main/ets/component/settingview/phone/SettingMenuItem';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy {
  ConfirmDialogView
} from '@ohos/common/src/main/ets/component/customdialog/dialogComponent/ConfirmDialogView';
import lazy { Dispatch, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import lazy { GlobalContext } from '@ohos/common/src/main/ets/utils/GlobalContext';
import lazy { ViewRotateTranslate } from '@ohos/common/src/main/ets/utils/ViewRotateTranslate';
import lazy { PersistType, PreferencesService } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy { ZoomAction } from '@ohos/common/src/main/ets/function/zoombar/ZoomAction';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { CameraProxy } from '@ohos/common/src/main/ets/camera/uithread/CameraProxy';
import lazy { TreasureBoxAction } from '@ohos/common/src/main/ets/component/treasurebox/reduce/TreasureBoxAction';
import lazy { TabBarAction } from '@ohos/common/src/main/ets/component/tabbar/TabBarAction';
import camera from '@ohos.multimedia.camera';
import lazy { CameraAction } from '@ohos/common/src/main/ets/camera/uithread/CameraAction';
import lazy {
  ChangeState,
  execDispatch,
  getStates,
  reduxSubscribe,
  Unsubscribe
} from '@ohos/common/src/main/ets/redux/Store';
import lazy { PropTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { DeviceInfo } from '@ohos/common/src/main/ets/component/deviceinfo/DeviceInfo';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import lazy { ContextAction } from '@ohos/common/src/main/ets/redux/actions/ContextAction';
import lazy { AnimateCallback, CustomTransition } from '@ohos/common/src/main/ets/animation/CustomNavigationUtils';
import lazy { MoreModeConfig } from '@ohos/common/src/main/ets/mode/MoreModeConfig';
import lazy { apsSetScene } from '@ohos/common/src/main/ets/utils/FrameLockSceneUtil';
import lazy { FrameLockScene } from '@ohos/common/src/main/ets/utils/FrameLockScene';
import lazy { FrameRateFunction } from '@ohos/common/src/main/ets/function/framerate/FrameRateFunction';
import lazy { ModeListManager } from '@ohos/common/src/main/ets/mode/ModeListManager';
import lazy { WindowService } from '@ohos/common/src/main/ets/service/window/WindowService';
import lazy { batteryInfo, BusinessError, screenLock } from '@kit.BasicServicesKit';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { Configuration, MeasureText, window } from '@kit.ArkUI';
import lazy { ExposureData } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper';
import lazy { FocusFunction } from '@ohos/extend/src/main/ets/commonfunc/focus/FocusFunction';
import lazy { BlurAnimateUtil } from '@ohos/common/src/main/ets/utils/BlurAnimateUtil';
import lazy { PickerUtils } from '@ohos/common/src/main/ets/utils/PickerUtils';
import lazy { PickerWindowType } from '@ohos/common/src/main/ets/component/picker/PickerWindowType';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { ContextManager } from '@ohos/common/src/main/ets/service/context/ContextManager';
import lazy { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';
// TODO OpenHarmony编译报错，待后续相关kit支持放开
// import { HdsNavDestination, HdsNavDestinationAttribute } from '@kit.UIDesignKit';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';
import lazy { ConfigurationConstant } from '@kit.AbilityKit';
import lazy { displaySync } from '@kit.ArkGraphics2D';

/* instrument ignore file */
const TAG: string = 'SettingView';
const ROTATE_ANGLE_90: number = 90;
const PADDING_RIGHT_24: number = 24;
const LANDSCAPE_MARGIN: number = 24;
const HORIZONTAL_MARGIN: number = 24;
const DEFAULT_VERTICAL_MARGIN: number = 16;
const TOP_HOLE: number = 36;
const AI_BAR_HEIGHT: number = 6;

// fix: 修复设置页列表最后一栏被导航栏盖住点击不到
export const NAVIGATION_BAR_HEIGHT: number = 48;
const OFFSET_LEFT_20: string = '-20%';
const OFFSET_RIGHT_20: string = '20%';
const OFFSET_LEFT_100: string = '-100%';
const OFFSET_RIGHT_100: string = '100%';
const OFFSET_RIGHT_50: string = '50%';
const OFFSET_0: number = 0;
const OPACITY_SHOW: number = 1;
const OPACITY_HIDDEN: number = 0;
const GLOBAL_EXPOSURE_INVALID = -100;

class ZoomFuncValueStruct {
  public zoomRatio?: number = 1;
}

class StateStruct {
  public mode: ModeType = ModeType.NONE;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public cameraShotKey: string = '';
  public isSecurityCamera: boolean = false;
  public isShowSettingView: boolean = false;
}

class SettingViewDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public showBlur(): void {
    this.mDispatch(Action.uiState(false));
  }

  public changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public restoreDialogConfirm(restoreConfirmFlag: boolean): void {
    this.mDispatch(Action.restoreDialogConfirm(restoreConfirmFlag));
  }

  public resetZoomRatio(): void {
    this.mDispatch(ZoomAction.resetZoomRatio());
  }

  public changeToMode(oldMode: ModeType, newMode: ModeType): void {
    AppStorage.Delete('startOrUserChangeToModeLast');
    this.mDispatch(CameraAction.changeMode(newMode, false));
    this.mDispatch(Action.updateXComponentShot(oldMode, newMode, false));
  }

  public resetSaveModeTimer() {
    this.mDispatch(ContextAction.resetSaveModeTimer());
  };

  public checkCurrentDirection() {
    this.mDispatch(Action.checkCurrentDirection());
  }

  public stitchingRestore() {
    this.mDispatch(Action.onStitchingRestore());
  }
}

@Component
export struct SettingView {
  private pageId: number = 0;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mBase: BaseComponent = new BaseComponent();
  @State mGutter: number = 12; //列间距
  @State tempMargin: Resource = $r('sys.float.padding_level6'); //两侧间距
  @State renderLocationList: RenderLocation[] = [];
  @State isShowLandscape: boolean = false;
  @State @Watch('statusChange') isShowSemiCollapsed: boolean = false;
  private isFirstTime: boolean = true;
  private mAction: SettingViewDispatcher = new SettingViewDispatcher();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State @Watch('rotateChange') rotateAngle: number = 0;
  @State lastRotateAngle: number = 0;
  @State @Watch('dialogShowChange') isDialogShow: boolean = false;
  private confirmDialogController: CustomDialogController | null = null;
  private readonly ANIMATION_DURATION_420: number = 420;
  private readonly ANIMATION_DURATION_840: number = 840;
  private mTimerId: number = Number.MIN_VALUE;
  @State rotateAngleDuration: number = this.ANIMATION_DURATION_420;
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State state: StateStruct = new StateStruct();
  protected mPreferencesService: PreferencesService = PreferencesService.getInstance();
  private moreModeConfig: MoreModeConfig = MoreModeConfig.getInstance();
  @Consume('pageInfos') pageInfos: NavPathStack;
  private restoreDialogConfirmTimer: number | null = null;
  @State settingOffset: Position = { x: 0, y: 0 };
  @Provide isShowSavePowerModeView: boolean = false;
  @StorageLink('isSettingViewScrollStart') isSettingViewScrollStart: boolean = false;
  @State translateTitle: number | string = OFFSET_0;
  @State translateContent: number | string = OFFSET_0;
  @State titleOpacity: number = OPACITY_SHOW;
  @State backButtonOpacity: number = OPACITY_SHOW;
  @State animationIsExit: boolean = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @State isHighContrastText: boolean = false;
  @State pickerWindowType: PickerWindowType = PickerWindowType.COLLAPSED_VERTICAL_FULL;
  @State restoreDialogConfirmState: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  private isUIExtensionPicker: boolean = false;
  private displayRotation: number = 0;
  @State stages: number = 0; // 分帧加载
  private myDisplaySync: displaySync.DisplaySync | null = null;

  private initSettingList() {
    const isPicker: boolean = GlobalContext.get().getIsPicker();
    this.renderLocationList = [RenderLocation.SETTING_MENU_PHOTO, RenderLocation.SETTING_MENU_VIDEO,
      RenderLocation.SETTING_MENU_COMMON];
    const modeList = ModeListManager.getInstance().getModeList();
    if (isPicker) {
      let isPhotoSupported: boolean = modeList.includes(ModeType.PHOTO);
      let isVideoSupported: boolean = modeList.includes(ModeType.VIDEO);
      if (isPhotoSupported && !isVideoSupported) {
        this.renderLocationList = [RenderLocation.SETTING_MENU_PHOTO, RenderLocation.SETTING_MENU_COMMON];
      } else if (!isPhotoSupported && isVideoSupported) {
        this.renderLocationList = [RenderLocation.SETTING_MENU_VIDEO, RenderLocation.SETTING_MENU_COMMON];
      }
    }
  }

  aboutToAppear(): void {
    apsSetScene(TAG, true); // 进入页面开始锁帧
    FrameLockScene.getInstance().apsSetScene(TAG, true); // 进入页面解除锁帧
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.initSettingList();
    this.uxInit();
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.isShowLandscape = state.get<boolean>('collapsReducer', 'isShowLandscape');
      this.isShowSemiCollapsed = state.get<boolean>('collapsReducer', 'isShowSemiCollapsed');
      this.updateDirectionAndRotationAngle(
        state.get<number>('contextReducer', 'direction'),
        state.get<number>('contextReducer', 'settingAngle'),
        state.get<boolean>('windowReducer', 'isLockRotation'));
      changeState(this.state, {
        mode: state.get<ModeType>('modeReducer', 'mode'),
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        cameraShotKey: state.get<string>('securityCameraReducer', 'cameraShotKey'),
        isSecurityCamera: state.get<boolean>('securityCameraReducer', 'isSecurityCamera'),
        isShowSettingView: state.get<boolean>('settingViewReducer', 'isShowSettingView'),
      });
      this.windowWidth = state.get<number>('windowReducer', 'windowWidth');
      this.windowHeight = state.get<number>('windowReducer', 'windowHeight');
      this.isShowSavePowerModeView = state.get<boolean>('contextReducer', 'isDuringSavePowerMode');
      this.isHighContrastText = state.get<boolean>('contextReducer', 'isHighContrastText');
      this.pickerWindowType = state.get<PickerWindowType>('windowReducer', 'pickerWindowType');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });

    if (this.isShowLandscape) {
      this.mGutter = PADDING_RIGHT_24;
    }
    ContextManager.getInstance().getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    AppStorage.setOrCreate('settingAnimationDoing', false);
    this.customTransition(); // 自定义动效
    this.mEventBus.on(ActionType.ACTION_CLOSE_SETTING_DIALOG, this.confirmDialogClose.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.ON_SIZE_CHANGE, this.uxInit.bind(this), this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.REFRESH_UX, () => this.refreshRotation(), this.mBase.hashCode());
    this.isUIExtensionPicker = PickerUtils.getIsPicker() && !!ContextManager.getInstance().getUiExtensionContext();
    // this.displayRotation = DisplayService.getInstance().getDisplay().rotation || 1;
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  private uxInit(): void {
    HiLog.begin(TAG, 'createDisplaySync');
    this.myDisplaySync = displaySync.create();
    HiLog.end(TAG, 'createDisplaySync');
    this.updateStage();
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    if (pickerWindowType === PickerWindowType.COLLAPSED_HORIZONTAL_1_2_SPLIT_SCREEN ||
      pickerWindowType === PickerWindowType.COLLAPSED_1_3_SPLIT_SCREEN) {
      this.mAction.changeFunctionValue(FunctionId.SETTING, false);
      return;
    }
  }

  updateStage() {
    if (this.stages == 0) {
      this.myDisplaySync?.start();
      this.myDisplaySync?.on('frame', (frameInfo: displaySync.IntervalInfo) => {
        this.updateStage();
      });
    }
    this.stages += 1;
    if (this.stages >= 5) {
      this.myDisplaySync?.stop();
      this.myDisplaySync?.off('frame');
    }
  }

  private restoreDefaults(featureManager: FeatureManager): void {
    HiLog.begin(TAG, 'restoreDefaults.');
    this.mAction.changeFunctionValue(FunctionId.ZOOM, {
      zoomRatio: featureManager.getFunction(FunctionId.ZOOM)?.getDefaultValue() as number
    } as ZoomFuncValueStruct);
    this.mAction.changeFunctionValue(FunctionId.ASPECT_RATIO, featureManager.getFunction(FunctionId.ASPECT_RATIO)
    ?.getDefaultValue() as number);
    this.mAction.changeFunctionValue(FunctionId.VIDEO_RESOLUTION,
      featureManager.getFunction(FunctionId.VIDEO_RESOLUTION)?.getDefaultValue() as number);
    this.mAction.changeFunctionValue(FunctionId.FRAME_RATE, FrameRateFunction.RESTORE_VALUE);
    this.mAction.changeFunctionValue(FunctionId.MIRROR, featureManager.getFunction(FunctionId.MIRROR)
    ?.getDefaultValue() as boolean);
    this.mAction.changeFunctionValue(FunctionId.ASSISTIVE_GRID, featureManager.getFunction(FunctionId.ASSISTIVE_GRID)
    ?.getDefaultValue() as boolean);
    this.mAction.changeFunctionValue(FunctionId.HORIZONTAL_LEVEL, featureManager.getFunction(FunctionId.HORIZONTAL_LEVEL)
    ?.getDefaultValue() as boolean);
    this.mAction.changeFunctionValue(FunctionId.SOUND_MUTE, featureManager.getFunction(FunctionId.SOUND_MUTE)
    ?.getDefaultValue() as boolean);
    this.mAction.changeFunctionValue(FunctionId.FLOATING_SHUTTER,
      featureManager.getFunction(FunctionId.FLOATING_SHUTTER)?.getDefaultValue() as boolean);
    this.mAction.changeFunctionValue(FunctionId.TIME_LAPSE, featureManager.getFunction(FunctionId.TIME_LAPSE)
    ?.getDefaultValue() as number);
    if (!this.state.isSecurityCamera) {
      this.mAction.changeFunctionValue(FunctionId.SAVE_GEO_LOCATION,
        featureManager.getFunction(FunctionId.SAVE_GEO_LOCATION)?.getDefaultValue() as boolean);
    }
    this.mAction.changeFunctionValue(FunctionId.EFFICIENT_VIDEO, featureManager.getFunction(FunctionId.EFFICIENT_VIDEO)
    ?.getDefaultValue() as boolean);
    this.mAction.changeFunctionValue(FunctionId.FOCUS,
      featureManager.getFunction(FunctionId.FOCUS)?.getDefaultValue() as boolean);
    HiLog.end(TAG, 'restoreDefaults.');
  }

  private restoreValues(): void {
    HiLog.begin(TAG, 'restoreValues.');
    AppStorage.setOrCreate('restoreFlag', true);
    AppStorage.setOrCreate('refreshTreasureBoxTriggeredByRestore', true);
    AppStorage.setOrCreate('userChangeEfficientVideo', false);
    AppStorage.setOrCreate('userChangeHdrVivid', false);
    let featureManager = FeatureManager.getInstance();
    this.mAction.changeFunctionValue(FunctionId.FLASH, -1);
    this.mAction.resetZoomRatio();
    this.restoreDefaults(featureManager);
    (featureManager.getFunction(FunctionId.FOCUS) as FocusFunction).resetFocus();
    this.mAction.changeFunctionValue(FunctionId.SETTING, false);
    this.mPreferencesService.putPropValue(PersistType.FOREVER, PropTag.IS_CLOSE_PORTRAIT_BEAUTY, false);
    this.mPreferencesService.putPropValue(PersistType.FOREVER, PropTag.IS_LIGHT_PAINTING_DIALOG_LOADED, false);
    this.mPreferencesService.putPropValue(PersistType.FOREVER, PropTag.IS_RESTORE_DEFAULT_VALUE, true);
    this.mPreferencesService.putPropValue(PersistType.FOREVER, PropTag.IS_LOG_ASSISTANCE_OPEN, false);
    AppStorage.setOrCreate('restoreFlag', false);
    if (this.moreModeConfig.isSupportMorePage()) {
      this.moreModeConfig.modifyMoreModeListAndName(ModeType.MORE);
    }
    // 将所有Function默认值通过changeMode一次起流配置带下
    if (PickerUtils.getIsPicker()) {
      const want: Want = GlobalContext.get().getCameraAbilityWant();
      const numSupportedModes: number = want?.parameters?.supportMultiMode ? 2 : 1;
      HiLog.i(TAG, `camera picker supports ${numSupportedModes} types of modes.`);
      if (numSupportedModes === 1) {
        this.mAction.changeToMode(this.state.mode, this.state.mode);
        return;
      }
    }

    this.mAction.changeToMode(this.state.mode, ModeType.PHOTO);
    HiLog.end(TAG, 'restoreValues.')
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear E.');
    AppStorage.setOrCreate('settingAnimationDoing', false);
    this.confirmDialogClose();
    clearTimeout(this.mTimerId);
    this.restoreDialogConfirmState = false;
    this.mSubscriber.destroy();
    this.mEventBus.clear(this.mBase.hashCode());
    if (!this.state.isShowSettingView) {
      ContextManager.getInstance()
        .getApplicationContext()
        .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    }
    HiLog.i(TAG, 'aboutToDisappear X.');
    apsSetScene(TAG, false); // 退出页面结束锁帧
    FrameLockScene.getInstance().apsSetScene(TAG, false); // 退出页面开始锁帧
  }

  private broadcastTabBarEvents(): void {
    StoreManager.getInstance().postMessage(TabBarAction.updateTabBarArr());
    StoreManager.getInstance().postMessage(TabBarAction.updatePositionAndOpacity());
    StoreManager.getInstance().postMessage(TabBarAction.updateLinkageButton());
    StoreManager.getInstance().postMessage(TabBarAction.updatePopUpButton());
  }

  private dialogShowChange(): void {
    GlobalContext.get().setObject('isDialogShow', this.isDialogShow);
  }

  private customTransition(): void {
    this.pageId = this.pageInfos.getAllPathName().length - 1;
    HiLog.i(TAG, `pageId : ${this.pageId}`);
    CustomTransition.getInstance().registerNavParam(this.pageId, {
      transitionAnimation: this.transitionAnimation(),
      titleAnimation: this.titleAnimation(),
      opacityAnimation: this.opacityAnimation()
    });
  }

  private transitionAnimation(): AnimateCallback {
    return {
      finish: (isPop: boolean, isExit) => {
        HiLog.i(TAG, `transitionAnimation finish, isPop: ${isPop}, isExit: ${isExit}.`);
        if (isPop) {
          // pop animation
          if (isExit) {
            this.translateTitle = OFFSET_RIGHT_50;
            this.translateContent = this.mDirection === WindowDirection.LEFT ? OFFSET_LEFT_100 : OFFSET_RIGHT_100;
          } else {
            this.translateTitle = OFFSET_0;
            this.translateContent = OFFSET_0;
          }
        } else {
          if (isExit) {
            this.translateTitle = OFFSET_0;
            this.translateContent = this.mDirection === WindowDirection.LEFT ? OFFSET_RIGHT_20 : OFFSET_LEFT_20;
          } else {
            this.translateTitle = OFFSET_0;
            this.translateContent = OFFSET_0;
          }
        }
      },
      onFinish: (isPop: boolean, isExit: boolean) => {
        HiLog.i(TAG, `transitionAnimation onFinish, isPop: ${isPop}, isExit: ${isExit}.`);
      },
      start: (isPop: boolean, isExit: boolean) => {
        HiLog.i(TAG, `transitionAnimation start, isPop: ${isPop}, isExit: ${isExit}.`);
        this.animationIsExit = isPop && isExit;
        if (this.animationIsExit) {
          this.broadcastTabBarEvents();
        }
        if (isPop) {
          // pop animation
          if (isExit) {
            this.translateTitle = OFFSET_0;
            this.translateContent = OFFSET_0;
          } else {
            this.translateTitle = OFFSET_0;
            this.translateContent = this.mDirection === WindowDirection.LEFT ? OFFSET_RIGHT_20 : OFFSET_LEFT_20;
          }
        } else {
          // push animation
          if (isExit) {
            this.translateTitle = OFFSET_0;
            this.translateContent = OFFSET_0;
          } else {
            this.translateTitle = OFFSET_RIGHT_50;
            this.translateContent = this.mDirection === WindowDirection.LEFT ? OFFSET_LEFT_100 : OFFSET_RIGHT_100;
          }
        }
      }
    }
  }

  private titleAnimation(): AnimateCallback {
    return {
      finish: (isPop: boolean, isExit: boolean) => {
        HiLog.i(TAG, `titleAnimation finish, isPop: ${isPop}, isExit: ${isExit}.`);
        if (isPop) {
          if (isExit) {
            this.titleOpacity = OPACITY_HIDDEN;
          } else {
            this.titleOpacity = OPACITY_SHOW;
          }
        } else {
          if (isExit) {
            this.titleOpacity = OPACITY_SHOW;
          } else {
            this.titleOpacity = OPACITY_SHOW;
          }
        }
      },
      onFinish: () => {
      },
      start: (isPop: boolean, isExit: boolean) => {
        HiLog.i(TAG, `titleAnimation start, isPop: ${isPop}, isExit: ${isExit}.`);
        if (isPop) {
          if (isExit) {
            this.titleOpacity = OPACITY_SHOW;
          } else {
            this.titleOpacity = OPACITY_SHOW;
          }
        } else {
          if (isExit) {
            this.titleOpacity = OPACITY_SHOW;
          } else {
            this.titleOpacity = OPACITY_SHOW;
          }
        }
      }
    }
  }

  private opacityAnimation(): AnimateCallback {
    return {
      finish: (isPop: boolean, isExit: boolean) => {
        HiLog.i(TAG, `opacityAnimation finish, isPop: ${isPop}, isExit: ${isExit}.`);
        if (isPop) {
          if (isExit) {
            this.backButtonOpacity = OPACITY_HIDDEN;
          } else {
            this.backButtonOpacity = OPACITY_SHOW;
          }
        } else {
          if (isExit) {
            this.backButtonOpacity = OPACITY_SHOW;
          } else {
            this.backButtonOpacity = OPACITY_SHOW;
          }
        }
      },
      onFinish: () => {
      },
      start: (isPop: boolean, isExit: boolean) => {
        HiLog.i(TAG, `opacityAnimation start, isPop: ${isPop}, isExit: ${isExit}.`);
        if (isPop) {
          if (isExit) {
            this.backButtonOpacity = OPACITY_SHOW;
          } else {
            this.backButtonOpacity = OPACITY_SHOW;
          }
        } else {
          if (isExit) {
            this.backButtonOpacity = OPACITY_SHOW;
          } else {
            this.backButtonOpacity = OPACITY_HIDDEN;
          }
        }
      }
    }
  }

  private confirmDialogClose(): void {
    clearTimeout(this.mTimerId);
    this.confirmDialogController?.close();
    this.isDialogShow = false;
  }

  private statusChange(): void {
    if (this.isDialogShow && this.isFirstTime) {
      this.confirmDialogController?.close();
      this.isDialogShow = false;
      this.createDialog();
      this.isFirstTime = false;
      this.mTimerId = setTimeout((): void => {
        this.confirmDialogController?.open();
        this.isDialogShow = true;
        this.isFirstTime = true;
      }, 250)
    }
  }

  private refreshRotation(): void {
    this.displayRotation = DisplayService.getInstance().getDisplay().rotation;
  }

  private directionChange(): void {
    HiLog.i(TAG, 'directionChange E.');
    if (this.mDirection === WindowDirection.BOTTOM || AppStorage.get('settingAnimationDoing') ||
    this.isShowSemiCollapsed) {
      return;
    }
    AppStorage.setOrCreate('settingAnimationDoing', true);
    this.statusChange();
    HiLog.i(TAG, 'directionChange X.');
  }

  private rotateChange() {
    HiLog.i(TAG, 'rotateChange E.');
    if ((this.rotateAngle - this.lastRotateAngle) % AnimSpecifications.ANIM_ROTATE_180 === 0) {
      this.rotateAngleDuration = this.ANIMATION_DURATION_840;
    } else {
      this.rotateAngleDuration = this.ANIMATION_DURATION_420;
    }
    this.lastRotateAngle = this.rotateAngle;
    HiLog.i(TAG, 'rotateChange X.');
  }

  private createDialog(): void {
    HiLog.i(TAG, 'createDialog E.');
    this.confirmDialogController = new CustomDialogController({
      builder: ConfirmDialogView({
        cancel: () => {
          HiLog.i(TAG, 'ConfirmDialogView cancel');
          this.isDialogShow = false;
          this.mAction.resetSaveModeTimer();
        },
        confirm: () => {
          if (this.restoreDialogConfirmTimer || this.restoreDialogConfirmState) {
            return;
          }
          BlurAnimateUtil.generatePixelMapFromSurface();
          this.mAction.showBlur();
          this.isDialogShow = false;
          this.restoreDialogConfirmTimer = setTimeout((): void => {
            HiLog.i(TAG, 'ConfirmDialogView confirm');
            this.restoreDialogConfirmTimer = null;
            // 恢复默认值确认操作
            this.restoreValues();
            this.mAction.restoreDialogConfirm(!this.state.isSecurityCamera);
          }, 180);
          this.mAction.resetSaveModeTimer();
          this.mAction.stitchingRestore();
          this.restoreDialogConfirmState = true;
        },
        description: $r('app.string.confirm_restore_message'),
        cancelText: $r('app.string.cancel'),
        confirmText: $r('app.string.confirm'),
        rotateAngle: this.isShowSemiCollapsed ? ROTATE_ANGLE_90 : this.rotateAngle,
        currentDirection: this.mDirection,
        isShowLandscape: this.isShowLandscape,
        isShowSemiCollapsed: this.isShowSemiCollapsed
      }),
      autoCancel: false,
      customStyle: true,
      cancel: () => {
        this.isDialogShow = false;
      },
      maskColor: '#66000000',
      alignment: this.isShowSemiCollapsed ? DialogAlignment.CenterStart : DialogAlignment.Center,
      offset: { dx: 0, dy: this.isVdeSemiCollapsed ? 170 : 0 }
    });
    HiLog.i(TAG, 'createDialog X.');
  }

  private getCardColumns(): number {
    if (this.pickerWindowType === PickerWindowType.EXPANDED_TOP_BOTTOM_SPLIT_SCREEN) {
      return 8;
    }
    return this.isShowSemiCollapsed ? 8 : !this.isShowLandscape ? 4 : 8;
  }

  private getCardSpan(): number {
    if (this.pickerWindowType === PickerWindowType.EXPANDED_TOP_BOTTOM_SPLIT_SCREEN) {
      return 6;
    }
    return this.isShowSemiCollapsed ? 6 : !this.isShowLandscape ? 4 : 6;
  }

  private getCardOffset(): number {
    if (this.pickerWindowType === PickerWindowType.EXPANDED_TOP_BOTTOM_SPLIT_SCREEN) {
      return 1;
    }
    return this.isShowSemiCollapsed ? 1 : !this.isShowLandscape ? 0 : 1;
  }

  private getPageTop(): number {
    return this.isShowSemiCollapsed ? this.windowWidth / 2 + 12 : TOP_HOLE;
  }

  private getViewWidth(): number {
    if (this.pickerWindowType === PickerWindowType.EXPANDED_TOP_BOTTOM_SPLIT_SCREEN) {
      return Math.max(this.windowWidth, this.windowHeight);
    }
    if (this.pickerWindowType === PickerWindowType.EXPANDED_LEFT_RIGHT_SPLIT_SCREEN) {
      return Math.min(this.windowWidth, this.windowHeight);
    }
    return this.isShowSemiCollapsed ? this.windowHeight : this.windowWidth;
  }

  private getViewHeight(): number {
    if (this.pickerWindowType === PickerWindowType.EXPANDED_TOP_BOTTOM_SPLIT_SCREEN) {
      return Math.min(this.windowWidth, this.windowHeight);
    }
    if (this.pickerWindowType === PickerWindowType.EXPANDED_LEFT_RIGHT_SPLIT_SCREEN) {
      return Math.max(this.windowWidth, this.windowHeight);
    }
    return this.isShowSemiCollapsed ? this.windowWidth : this.windowHeight;
  }

  private getTranslateX(): number {
    if (this.isUIExtensionPicker && this.displayRotation !== 0) {
      return 0;
    }
    return this.isShowSemiCollapsed ?
      ViewRotateTranslate.getTranslateSize(this.windowHeight, this.windowWidth).translateX : 0;
  }

  private getTranslateY(): number {
    if (this.isUIExtensionPicker && this.displayRotation !== 0) {
      return 0;
    }
    return this.isShowSemiCollapsed ?
      ViewRotateTranslate.getTranslateSize(this.windowHeight, this.windowWidth).translateY : 0;
  }

  private getPaddingLeftRight(): number {
    if (this.isShowLandscape && !this.isShowSemiCollapsed) {
      return LANDSCAPE_MARGIN;
    } else if (this.isShowSemiCollapsed) {
      return HORIZONTAL_MARGIN;
    } else {
      return DEFAULT_VERTICAL_MARGIN;
    }
  }

  private getRotateAngle(): number {
    if (this.isUIExtensionPicker && this.displayRotation !== 0) {
      return 0;
    }
    return this.isShowSemiCollapsed ? ROTATE_ANGLE_90 : 0;
  }

  //zy-20251209-这里改变了返回的isSettingShow
  private settingViewOnBack(): void {
    this.animationIsExit = true;
    this.mAction.changeFunctionValue(FunctionId.SETTING, false);
    if (AppStorage.get('settingAnimationDoing')) {
      this.animationIsExit = false;
    }
  }

  @Builder
  listItem(item: RenderLocation) {
    ListItem() {
      GridRow({
        columns: this.getCardColumns(),
        direction: GridRowDirection.Row,
        gutter: this.mGutter,
      }) {
        GridCol({
          span: {
            xs: this.getCardSpan(),
            sm: this.getCardSpan(),
            md: this.getCardSpan(),
            lg: this.getCardSpan()
          },
          offset: {
            xs: this.getCardOffset(),
            sm: this.getCardOffset(),
            md: this.getCardOffset(),
            lg: this.getCardOffset()
          }
        }) {
          SettingMenuItem({
            menuLocation: item
          })
        }
      }
    }
  }

  @Builder
  restoreButton() {
    // 恢复默认值 按钮，适老化适配，根据系统字体大小，展现不同风格
    Button({
      stateEffect: true,
      type: (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2) ?
        ButtonType.Normal : ButtonType.Capsule
    }) {
      Text($r('app.string.restore_defaults'))
        .fontSize($r('app.float.font_16'))
        .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
        .fontColor($r('app.color.setting_page_text_color'))
        .fontWeight(FontWeight.Regular)
        .textAlign(TextAlign.Center)
        .lineHeight(17)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontFeature('\"ss01\" on')
    }
    .height(this.getRestoreButtonHeight())
    .backgroundColor($r('app.color.list_card_bg')) //ohos_id_corner_radius_button = 20vp
    .borderRadius($r('sys.float.ohos_id_corner_radius_button'))
    .hoverEffect(HoverEffect.None) // .height(40)
    .margin({ top: $r('sys.float.padding_level12'), bottom: $r('sys.float.padding_level12') })
    .padding({
      top: 12,
      bottom: 12,
      left: this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2 ?
        $r('app.float.button_padding_value_16') : $r('app.float.button_padding_value_32'),
      right: this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2 ?
        $r('app.float.button_padding_value_16') : $r('app.float.button_padding_value_32')
    })
    .onClick((): void => {
      this.createDialog();
      this.confirmDialogController?.open();
      this.isDialogShow = true;
    })
    .key(ComponentIdKeys.SETTING_DEFAULT_BUTTON_1)
  }

  @Builder
  privacyText() {
    Text($r('app.string.camera_privacy_with_cloud_photo'))
      .fontSize($r('sys.float.Body_S'))
      .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
      .fontColor(this.isHighContrastText ? Color.White : '#5291FF')
      .fontWeight(FontWeight.Regular)
      .visibility(Visibility.None)//TODO 隐私声明需厂商自行补齐，隐藏入口
      .margin({ bottom: $r('sys.float.padding_level12') })
      .onClick((): void => { //跳转隐私声明页面
        HiLog.i(TAG, 'pageInfos change, push PrivacyPolicyView');
        if (GlobalContext.get().getT('isSecureMode')) {
          screenLock.unlock().then((data: Boolean) => {
            HiLog.i(TAG, `Succeeded in unlocking the screen. result: ${data}`);
            if (data) {
              this.pageInfos.pushPath({ name: 'PrivacyPolicyView' });
              GlobalContext.get().setObject('privacyPolicyViewShow', true);
            }
          }).catch((err: BusinessError) => {
            HiLog.e(TAG, `Failed to unlock the screen, Code: ${err?.code}`);
          });
        } else {
          this.pageInfos.pushPath({ name: 'PrivacyPolicyView' });
          GlobalContext.get().setObject('privacyPolicyViewShow', true);
        }
      })
      .key(ComponentIdKeys.SETTING_PERMISSION_TEXT)
      .fontFeature('\"ss01\" on')
  }

  @Builder
  scroller() {
    Scroll() {
      Column() {
        if (this.stages >= 5) {
          // Blank().height(56);
          List() {
            ForEach(this.renderLocationList, (item: RenderLocation) => {
              this.listItem(item);
            })
          }.scrollBar(BarState.Off)

          this.restoreButton();
        }
        if (!GlobalContext.get().getIsPicker()) {
          this.privacyText();
        }
      }
    }
    .width('100%')
    .flexShrink(1)
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .padding({
      left: this.getPaddingLeftRight(),
      right: this.getPaddingLeftRight(),

      // fix: 修复设置页列表最后一栏被导航栏盖住点击不到
      bottom: NAVIGATION_BAR_HEIGHT
    })
    .onScrollStart((): void => {
      HiLog.i(TAG, 'List scroll starts.');
      this.isSettingViewScrollStart = true;
    })
    .onScrollStop((): void => {
      HiLog.i(TAG, 'List scroll ends.');
      this.isSettingViewScrollStart = false;
    })
  }

  build() {
    NavDestination() {
      if (this.stages >= 3) {
        this.scroller();
      }
      // .toolBar({
      //   content: {
      //     title: {
      //       mainTitle: $r('app.string.settings')
      //     },
      //     backIcon: {
      //       componentId: ComponentIdKeys.NAV_DESTINATION_TITLE_BACK_1,
      //       action: () => {
      //         this.settingViewOnBack();
      //       }
      //     }
      //   },
      //   style: {
      //     originalStyle: {
      //       backgroundStyle: {
      //         backgroundColor: Color.Black,
      //       },
      //       contentStyle: {
      //         titleStyle: {
      //           mainTitleColor: $r('sys.color.ohos_id_color_text_primary_dark')
      //         },
      //         backIconStyle: {
      //           iconColor: $r('sys.color.ohos_id_color_titlebar_icon_dark'),
      //           backgroundColor: '#26FFFFFF'
      //         }
      //       }
      //     },
      //     scrollEffectOpts: {
      //       enableScrollEffect: false
      //     }
      //   }
      // })
    }
    // NavDestination替换HdsNavDestination，有些属性暂不支持设置
    .title($r('app.string.settings'))
    .onBackPressed(() => {
      this.settingViewOnBack();
      return true;
    })
    .width(this.getViewWidth())
    .height(this.getViewHeight())
    .id('settingView')
    .backgroundColor(Color.Black)
    .padding({ top: this.getPageTop(), left: 0 })
    .rotate({ angle: this.getRotateAngle() })
    .animation(
      {
        duration: this.rotateAngleDuration,
        curve: Curve.Sharp,
        iterations: 1,
        playMode: PlayMode.Normal,
        onFinish: () => {
          HiLog.i(TAG, 'animation onFinish');
          AppStorage.setOrCreate('settingAnimationDoing', false);
          this.mAction.checkCurrentDirection();
        }
      })
    .translate({
      x: this.getTranslateX(),
      y: this.getTranslateY(),
    })
    .onBackPressed((): boolean => {
      this.settingViewOnBack();
      return true;
    })

    // .offset({
    //   x: this.isShowSemiCollapsed ? OFFSET_0 : this.translateContent,
    //   y: this.isShowSemiCollapsed ? this.translateContent : OFFSET_0
    // })
  }

  private getRestoreButtonHeight(): number {
    let maxOneLineLength: number = this.getViewWidth() - 2 * 4 - 32;
    let restoreTextLength: number = MeasureText.measureText({
      textContent: $r('app.string.restore_defaults'),
      fontSize: $r('sys.float.Body_L'),
      fontWeight: FontWeight.Regular
    });
    let sizeScale = this.fontSizeScale;
    if (this.fontSizeScale > CommonConstants.TEXT_SIZE_HUGE_LEVEL3) {
      sizeScale = CommonConstants.TEXT_SIZE_HUGE_LEVEL3
    }
    if ((px2vp(restoreTextLength) > maxOneLineLength)) {
      if (SystemLanguageUtil.isTibetan() && sizeScale === CommonConstants.TEXT_SIZE_HUGE_LEVEL4) {
        return 40 + 32 * sizeScale;
      }
      return 24 + 32 * sizeScale;
    } else {
      if (SystemLanguageUtil.isTibetan() && sizeScale === CommonConstants.TEXT_SIZE_HUGE_LEVEL4 ||
      SystemLanguageUtil.isSpanish()) {
        return 40 + 16 * sizeScale;
      }
      return 24 + 16 * sizeScale;
    }
  }

  private updateDirectionAndRotationAngle(direction: WindowDirection, rotateAngle: number,
    isLockRotation: boolean): void {
    if (PickerUtils.getIsExpandedTopBottomSplitScreenFromReducer()) {
      this.mDirection = WindowDirection.RIGHT;
      this.rotateAngle = 0;
      return;
    }
    if (PickerUtils.getIsExpandedLeftRightSplitScreenFromReducer()) {
      this.mDirection = WindowDirection.TOP;
      this.rotateAngle = 0;
      return;
    }
    if (isLockRotation) { // 不锁定旋转 恢复竖直状态
      this.mDirection = WindowDirection.TOP;
      this.rotateAngle = 0;
      return;
    }
    if (WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) { //进入悬浮窗，恢复竖直状态
      this.mDirection = WindowDirection.TOP;
      this.rotateAngle = 0;
      return;
    }
    if (WindowService.getInstance().isSubscriptionNeeded() && !this.animationIsExit) {
      this.mDirection = direction;
      this.rotateAngle = rotateAngle;
    }
  }
}