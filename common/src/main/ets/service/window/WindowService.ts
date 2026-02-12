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
/* instrument ignore file */
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { WindowAction } from './WindowAction';
import type BusinessError from '@ohos.base';
import window from '@ohos.window';
import type { UIContext } from '@ohos.arkui.UIContext';
import lazy { ContextAction } from '../../redux/actions/ContextAction';
import type { Size } from '../../utils/types';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { XComponentService } from '../../component/xcomponent/XComponentService';
import lazy { AdaptiveLayoutService } from '../UIAdaptive/AdaptiveLayoutService';
import settings from '@ohos.settings';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { PersistType, PreferencesService } from '../preferences/PreferencesService';
import lazy { PublicTag } from '../preferences/PropTag';
import lazy { ContextManager } from '../context/ContextManager';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import dataShare from '@ohos.data.dataShare';
import lazy { DisplayService } from '../UIAdaptive/DisplayService';
import lazy { common, ConfigurationConstant } from '@kit.AbilityKit';
import lazy { display } from '@kit.ArkUI';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import lazy { simpleStringify } from '../../utils/SimpleStringify';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { execDispatch, getStates } from '../../redux';
import lazy { camera } from '@kit.CameraKit';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { isLogStyleSupport } from '../../function/enumbase/LogStyleMode';
import lazy { PhotoBrowserStatusData } from '../../camera/DataType';
import lazy { ThumbnailActionType } from '../../redux/actions/ThumbnailActionType';
import lazy { DataUriType, SettingsDataShareUtils } from '../../utils/SettingsDataShareUtils';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { AspectRatioOperation } from '../../function/aspectratio/AspectRatioOperation';
import lazy { CameraAction } from '../../camera/uithread/CameraAction';
import lazy { OutputSwitcher } from '../../function/outputswitcher/OutputSwitcher';
import lazy { OutputType } from '../../function/outputswitcher/OutputType';
import lazy { SettingsValueUtil } from '../../utils/SettingsValueUtil';


const STATUS_BAR_COLOR: string = '#00000000';
const STATUS_BAR_CONTENT_COLOR: string = '#FFFFFFFF';

// fix: 相机导航栏按钮和背景色一样导致区分不出来
const NAVIGATION_BAR_COLOR: string = '#00000000';
const NAVIGATION_BAR_CONTENT_COLOR: string = '#FFFFFFFF';
const TAG: string = 'WindowService';
const AI_BAR_DISPLAY_DELAY: number = 2000;
const FOUR_DIRECTION: number = 4;

export const DIFFER_TOLERANCE = 4; // 窗口宽高和xComponent宽高存在误差（环形补光背景无法完全被xComp遮挡）
const WAIT_TIME: number = 100;
const PC_DIFFER_TOLERANCE = 10; // 窗口宽高和xComponent宽高存在误差（PC会有黑边产生）
const RATIO_ACCURACY: number = 2;
const WIN_DECOR_HEIGHT: number = 70;
const PCPICKER_WAIT_TIME = 500;
const WINDOW_PCMODE_SWITCH_STATUS: string = 'window_pcmode_switch_status';

/*
 导航栏类型枚举 0-三键  1-AI bar
 */
export enum NavigationStyle {
  THREE_KEY = '0',
  AI_BAR = '1',
}

/**
 *  state true-显示 false-隐藏
 *  animation： true 是否需要动画 false 不需要动画
 *  keepConstantDisplay: true 常显 false 不常显
 */
class AIBarStyle {
  public state: boolean;
  public animation: boolean;
  public keepConstantDisplay: boolean;
}

export const pxChange: (size: Size) => Size = (size: Size) => {
  return { width: Math.floor(px2vp(size.width)), height: Math.floor(px2vp(size.height)) };
};

export class WindowService {
  private mBase: BaseComponent = new BaseComponent();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();

  private static sInstanceWindowService: WindowService;
  private mWindow: window.Window;
  private rect: window.Rect;
  private initializedFloating: boolean = false;
  private cutoutAvoidArea: window.AvoidArea;
  // 窗口状态
  private isLocked: boolean = false;
  private windowStatus: window.WindowStatusType | undefined = undefined;
  private windowVisibilityStatus: boolean = false;
  //锁定旋转状态
  private accelerometerStatus: string = '0';
  private timerId: number = Number.MIN_VALUE;
  //锁定旋转状态
  private settingDataHelper: dataShare.DataShareHelper = undefined;
  //开合防抖
  private collapsTimer: number = Number.NaN;
  private oldRatio: number = 0;
  private isWindowRotationChangeLocked: boolean = false;
  private isSetWaterMarkFlag: boolean = false;
  //pcPicker拖动窗口防抖
  private dragTimer: number = -1;
  private navigationStyle: NavigationStyle = this.initNavigationStyle();
  private aiBarStyle: AIBarStyle = new AIBarStyle(); // 存储AIBar设置的样式开关，当样式发生变化时，需复用
  public static windowMap: Map<number, boolean> = new Map();

  public static getInstance(): WindowService {
    if (!WindowService.sInstanceWindowService) {
      WindowService.sInstanceWindowService = new WindowService();
    }
    return WindowService.sInstanceWindowService;
  }

  private constructor() {
    this.mEventBus.on(CameraActionType.STARTED, () => this.setWaterMarkFlag(), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, () => this.onBackground(), this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.PHOTOBROWSER_STATUS,
      (data: PhotoBrowserStatusData) => this.onPhotoBrowserStatusChange(data), this.mBase.hashCode());
  }

  public init(win): void {
    HiLog.i(TAG, 'init WindowService.');
    this.mWindow = win;
    execDispatch(WindowAction.onClassReady());
    this.setWaterMarkFlag();
    try {
      if (DeviceInfo.isPc() || DeviceInfo.isTablet()) {
        this.windowStatus = this.mWindow.getWindowStatus();
        execDispatch(WindowAction.updateWindowStatus(this.windowStatus));
      }
      // 错误码 801，设备不支持
      this.mWindow.on('windowStatusChange', (status: window.WindowStatusType) => {
        HiLog.i(TAG, `windowStatusChange, status: ${status}.`);
        if (status === window.WindowStatusType.MINIMIZE) {
          return;
        }
        let windowPreStatus: window.WindowStatusType = this.windowStatus;
        this.windowStatus = status;
        execDispatch(WindowAction.updateWindowStatus(this.windowStatus, windowPreStatus));
      });

      this.mWindow.on('windowVisibilityChange', (status: boolean) => {
        HiLog.i(TAG, `windowVisibilityChange, status: ${status}.`);
        this.windowVisibilityStatus = status;
        execDispatch(WindowAction.updateWindowVisibilityStatus(this.windowVisibilityStatus));
      });
      this.mWindow.on('windowEvent', (event: window.WindowEventType) => {
        AppStorage.setOrCreate('WindowEventType', event);
      });
      this.navigationStyle = this.initNavigationStyle();
      HiLog.d(TAG, 'registerKeyObserver floatingNavigation E');
      settings.registerKeyObserver(ContextManager.getInstance().getAbilityContext(), 'floatingNavigation',
        settings.domainName.USER_PROPERTY, () => {
          this.dealWithNavigationStyleChange();
        });
      HiLog.d(TAG, 'registerKeyObserver floatingNavigation X');
      if (DeviceInfo.isTablet() && GlobalContext.get().getIsPicker()) {
        this.registerPcModeStatus();
        this.updateSupportedWindowModes(PickerUtils.getIsInPcMode());
      }
    } catch (error) {
      HiLog.i(TAG, `windowStatusChange on error: ${error}.`);
    }
  }

  public setWindowBackGround(isBackGround: boolean): void {
    try {
      const win: number = this.mWindow.getWindowProperties().id;
      HiLog.i(TAG, `setWindowBackGround: ${win}, ${isBackGround}`);
      WindowService.windowMap.set(win, isBackGround);
    } catch (err) {
      HiLog.e(TAG, `setWindowBackGround fail. ${err?.code}`);
    }
  }

  // 全屏&悬浮窗之间互切操作
  private isFloatingSwitch(curStatus: window.WindowStatusType, lastStatus: window.WindowStatusType): boolean {
    if (curStatus === window.WindowStatusType.FLOATING && lastStatus === window.WindowStatusType.FULL_SCREEN ||
      curStatus === window.WindowStatusType.FULL_SCREEN && lastStatus === window.WindowStatusType.FLOATING) {
      return true;
    }
    return false;
  }

  // 全屏&分屏之间互切操作
  private isSplitSwitch(curStatus: window.WindowStatusType, lastStatus: window.WindowStatusType): boolean {
    if (curStatus === window.WindowStatusType.SPLIT_SCREEN && lastStatus === window.WindowStatusType.FULL_SCREEN ||
      curStatus === window.WindowStatusType.FULL_SCREEN && lastStatus === window.WindowStatusType.SPLIT_SCREEN) {
      return true;
    }
    return false;
  }

  public getMainWindow(): window.Window {
    return this.mWindow;
  }

  private registerPcModeStatus(): void {
    HiLog.d(TAG, 'registerPcModeStatus');
    try {
      settings.registerKeyObserver(ContextManager.getInstance().getAbilityContext(), WINDOW_PCMODE_SWITCH_STATUS,
        settings.domainName.USER_PROPERTY, () => {
          settings.getValue(ContextManager.getInstance().getAbilityContext(), WINDOW_PCMODE_SWITCH_STATUS,
            settings.domainName.USER_PROPERTY).then((data) => {
            HiLog.d(TAG, `registerPcModeStatus settings value changed: ${JSON.stringify(data)}`);
            this.updateSupportedWindowModes(data === 'true');
          });
        });
    } catch (err) {
      HiLog.e(TAG, `registerPcModeStatus err. ${err?.code}`);
    }
  }

  private updateSupportedWindowModes(isInPcMode: boolean): void {
    HiLog.d(TAG, `updateSupportedWindowModes,isInPcMode: ${isInPcMode}`);
    try {
      let windowStage: window.WindowStage = GlobalContext.get().getWindowStage();
      if (isInPcMode) { // pc模式
        windowStage.setSupportedWindowModes([0]); // 全屏
      } else {
        windowStage.setSupportedWindowModes([0, 1]); // 全屏 + 悬浮窗
      }
    } catch (err) {
      HiLog.e(TAG, `updateSupportedWindowModes err. ${err?.code}`);
    }
  }

  public unRegisterPcModeStatus(): void {
    HiLog.d(TAG, 'unRegisterPcModeStatus');
    try {
      settings.unregisterKeyObserver(ContextManager.getInstance().getAbilityContext(), WINDOW_PCMODE_SWITCH_STATUS,
        settings.domainName.USER_PROPERTY);
    } catch (err) {
      HiLog.e(TAG, `unRegisterPcModeStatus err. ${err?.code}`);
    }
  }

  unRegisterKeyObserverFloatingNavigation(): void {
    HiLog.d(TAG, 'unRegisterKeyObserverFloatingNavigation');
    try {
      settings.unregisterKeyObserver(ContextManager.getInstance().getAbilityContext(), 'floatingNavigation',
        settings.domainName.USER_PROPERTY);
    } catch (err) {
      HiLog.e(TAG, `unRegisterKeyObserverFloatingNavigation err. ${err?.code}`);
    }
  }

  public reSetWin(win): void {
    HiLog.i(TAG, 'reSetWind .');
    this.mWindow = win;
    try {
      this.windowStatus = 1//this.mWindow.getWindowStatus();
    }catch (err) {
      HiLog.e(TAG, `reSetWin err. ${err?.code}`);
    }
  }

  private onBackground(): void {
    this.isSetWaterMarkFlag = false;
    this.windowStatus = window.WindowStatusType.FULL_SCREEN;
    execDispatch(WindowAction.updateWindowStatus(this.windowStatus));
  }

  private isWindowFullScreen(): boolean {
    let windowStatus: window.WindowStatusType = this.getWindowStatus();
    return windowStatus === window.WindowStatusType.FULL_SCREEN || windowStatus === window.WindowStatusType.MINIMIZE;
  }

  private isFullScreenExpandMode(): boolean {
    let isWindowFull = this.isWindowFullScreen();
    return isWindowFull;
  }

  public setLockWindowRotation(value: boolean): void {
    HiLog.i(TAG, 'setLockWindowRotation:' + value);
    if (!this.isFullScreenExpandMode() && !DeviceInfo.isTablet()) {
      HiLog.i(TAG, 'not lockScreenRot for neither TAH nor tablet');
      return;
    }
    let systemWindowLockSetting: string = this.getSettingsValueAccRotationStatus();
    if ('0' === systemWindowLockSetting) {
      HiLog.i(TAG, 'not lockScreenRot for already sysLocked');
      return;
    }
    if (value) {
      this.lockWindowRotation();
    }
    this.isWindowRotationChangeLocked = value;
    if (!value) {
      this.unlockWindowRotation();
    }
  }

  public getWindowDisplayName(): string {
    try {
      HiLog.d(TAG, `getWindowDisplayName displayId:${AppStorage.get('windowDisplayId')}`);
      return display.getDisplayByIdSync(AppStorage.get('windowDisplayId')).name;
    } catch (err) {
      HiLog.e(TAG, `getWindowDisplayName err. ${err}`);
      return 'UNKNOWN';
    }
  }

  public setForceUnlockWindowRotation(isLockUiToWindow: boolean): void {
    HiLog.i(TAG, 'setUnlockWindowRotation:');
    let systemWindowLockSetting: string = this.getSettingsValueAccRotationStatus();
    if ('0' === systemWindowLockSetting) {
      HiLog.i(TAG, 'not unlockScreenRot for already sysLocked');
      return;
    }
    if (this.isWindowRotationChangeLocked) {
      this.isWindowRotationChangeLocked = false;
      this.unlockWindowRotation(isLockUiToWindow);
    }
  }

  private unlockWindowRotation(isLockUiToWindow: boolean = true): void {
    HiLog.i(TAG, 'unlockWindowRotation');
    let orientation = window.Orientation.FOLLOW_DESKTOP;
    this.setWinOrientation(orientation);
    if (!DeviceInfo.isTablet() && isLockUiToWindow) {
      execDispatch(WindowAction.onRotationLocked(false));
    }
  }

  private lockWindowRotation(): void {
    let disRotation: number = DisplayService.getInstance().getDisplay().rotation;
    let orientation: window.Orientation = window.Orientation.FOLLOW_DESKTOP;
    HiLog.i(TAG, 'lock window rotation:' + disRotation);
    switch (disRotation) {
      case 0:
        orientation = window.Orientation.PORTRAIT;
        break;
      case 1:
        orientation = window.Orientation.LANDSCAPE_INVERTED;
        break;
      case 2:
        orientation = window.Orientation.PORTRAIT_INVERTED;
        break;
      case 3:
        orientation = window.Orientation.LANDSCAPE;
        break;
      default:
        break;
    }
    this.setWinOrientation(orientation);
    if (window.Orientation.FOLLOW_DESKTOP !== orientation && !DeviceInfo.isTablet()) {
      execDispatch(WindowAction.onRotationLocked(true));
    }
  }

  public getSettingsValueAccRotationStatus(): string {
    return SettingsValueUtil.getValueSync(settings.general.ACCELEROMETER_ROTATION_STATUS, '0');
  }

  public registerAccelerometer(): void {
    this.accelerometerStatus = this.getSettingsValueAccRotationStatus();
    execDispatch(WindowAction.onRotationStatusChange(this.accelerometerStatus === '0'));

    SettingsDataShareUtils.createDataHelper(SettingsDataShareUtils.getSettingsUri(DataUriType.SETTING_GLOBAL_URI,
      settings.general.ACCELEROMETER_ROTATION_STATUS, true))?.then((dataHelper: dataShare.DataShareHelper) => {
      this.settingDataHelper = dataHelper;
      if (!this.settingDataHelper) {
        HiLog.e(TAG, 'createDataHelper is undefined');
        return;
      }
      SettingsDataShareUtils.registerDataChange(this.settingDataHelper,
        SettingsDataShareUtils.getSettingsUri(DataUriType.SETTING_GLOBAL_URI,
          settings.general.ACCELEROMETER_ROTATION_STATUS, true), () => {
          let currentAccStatus = this.getSettingsValueAccRotationStatus();
          if (this.accelerometerStatus === currentAccStatus) {
            return;
          }
          this.accelerometerStatus = currentAccStatus;
          execDispatch(WindowAction.onRotationStatusChange(this.accelerometerStatus === '0'));
          HiLog.i(TAG, `ACCELEROMETER_ROTATION_STATUS : ${this.accelerometerStatus}.`);
        });
    });
  }

  public unRegisterAccelerometer(): void {
    if (!this.settingDataHelper) {
      HiLog.e(TAG, 'unRegisterAccelerometer DataHelper is undefined');
      return;
    }
    SettingsDataShareUtils.unRegisterDataChange(this.settingDataHelper,
      SettingsDataShareUtils.getSettingsUri(DataUriType.SETTING_GLOBAL_URI,
        settings.general.ACCELEROMETER_ROTATION_STATUS, true));
  }

  public getUiContext(): UIContext | undefined {
    try {
      return this.mWindow?.getUIContext();
    } catch (err) {
      HiLog.e(TAG, `Window getUiContext err: ${err}.`);
    }
  }

  public setAspectRatio(ratio: number): void {
    try {
      this.mWindow?.setAspectRatio(ratio);
    } catch (err) {
      HiLog.e(TAG, `Window setAspectRatio err: ${err}.`);
    }
  }

  //extensionAbility使用
  private resizePcPickerWindow(ratio: number): void {
    if (this.dragTimer !== -1) {
      clearTimeout(this.dragTimer);
    }
    this.dragTimer = setTimeout(() => {
      let tempProperties = this.mWindow?.getWindowProperties();
      let tempWinTitleHeight = this.mWindow?.getWindowDecorHeight();
      this.mWindow?.resize((tempProperties?.windowRect?.height - tempWinTitleHeight * 2) * ratio,
        tempProperties?.windowRect?.height);
    }, PCPICKER_WAIT_TIME);
  }

  public onWindowSizeChange(): void {
    if (!this.mWindow) {
      HiLog.e(TAG, 'window undefined, onWindowSizeChange error.');
      return;
    }
    try {
      this.mWindow.getUIContext().runScopedTask(() => {
        const originalSize = this.mWindow.getWindowProperties().windowRect;
        const callback = this.createWindowSizeCallback();
        let size = callback(originalSize);
        HiLog.i(TAG, `onWindowSizeChange windowRect: ${simpleStringify(this.mWindow.getWindowProperties().windowRect)
        }, size: ${simpleStringify(size)}.`);
        execDispatch(WindowAction.onSizeChange(size));
        this.mWindow.on('windowSizeChange', this.windowSizeChangeCallback(callback).bind(this));
      });
    } catch (err) {
      HiLog.e(TAG, `getUIContext err: ${err}.`);
    }
  }

  private createWindowSizeCallback(): (size: Size) => Size {
    return (size: Size): Size => {
      let newSize: Size = size;

      if (DeviceInfo.isPc()) {
        const rect = this.mWindow.getWindowProperties().drawableRect;
        newSize = {
          width: size.width - rect.left,
          height: size.height - rect.top,
        };
        HiLog.i(TAG, `window size: ${simpleStringify(size)}, px drawableRect: ${simpleStringify(rect)}, new size: ${
        simpleStringify(newSize)}.`);
      }

      return pxChange(newSize);
    };
  }

  public refreshWindowSize(densityPixels: number): void {
    if (!this.mWindow) {
      return;
    }
    try {
      const size = {
        width: this.mWindow?.getWindowProperties()?.windowRect.width / densityPixels,
        height: this.mWindow?.getWindowProperties()?.windowRect.height / densityPixels
      };
      execDispatch(WindowAction.onSizeChange(size));
    } catch (err) {
      HiLog.e(TAG, `refreshWindowSize err. ${err}`);
    }
  }

  private windowSizeChangeCallback(callback: (size: window.Size) => window.Size): BusinessError.Callback<window.Size> {
    return async (size: Size) => {
      size = callback(size);
      HiLog.i(TAG, `windowSizeChange, width: ${size.width}, height: ${size.height}.`);
      if (!AppStorage.get('isLemCollaps') || AppStorage.get('isPSDCollaps')) {
        execDispatch(WindowAction.onSizeChange(size));
      }
      if (PickerUtils.getIsPicker()) {
        PickerUtils.updatePickerWindowType(size);
      }
      if (!this.initializedFloating) {
        return;
      }
      const isShowDefault = getStates().get<boolean>('collapsReducer', 'isShowDefault');
      const isShowLandscape = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
      const isShowSettingView = getStates().get<boolean>('settingViewReducer', 'isShowSettingView');

      if (isShowDefault || isShowLandscape || isShowSettingView) {
        return;
      }
      if (!Number.isNaN(this.collapsTimer)) {
        clearTimeout(this.collapsTimer);
      }
      this.collapsTimer = setTimeout(() => {
        HiLog.i(TAG, 'changeShowLandscape to open.');
        this.collapsTimer = Number.NaN;
      }, WAIT_TIME);
    };
  }

  public setWindowKeepScreenOn(isKeepScreenOn: boolean): void {
    HiLog.i(TAG, `setting the screen to be always on. Data: ${isKeepScreenOn}.`);
    this.mWindow?.setWindowKeepScreenOn(isKeepScreenOn).then((v) => {
      HiLog.i(TAG, `Succeeded in setting the screen to be always on. Data: ${JSON.stringify(v)}.`);
      StoreManager.getInstance().postMessage(ContextAction.updateScreenOnState(isKeepScreenOn));
    }).catch((err: BusinessError.BusinessError) => {
      HiLog.e(TAG, `Failed to set the screen to be always on. Cause: ${JSON.stringify(err)}.`);
    });
  }

  public getWindowKeepScreenOn(): boolean {
    try {
      return this.mWindow?.getWindowProperties().isKeepScreenOn;
    } catch (err) {
      HiLog.e(TAG, `getWindowProperties fail. ${err}`);
      return false;
    }
  }

  public async setFullScreen(): Promise<void> {
    if (!this.mWindow) {
      HiLog.e(TAG, 'window undefined, setFullScreen error.');
      return;
    }
    try {
      if (PickerUtils.getIsInPcMode()) {
        await this.mWindow.maximize(window.MaximizePresentation.ENTER_IMMERSIVE);
        this.mWindow.setWindowTitleButtonVisible(false, false, true);
        HiLog.e(TAG, `IsInPcMode. true`);
      } else {
        await this.mWindow.setWindowLayoutFullScreen(true);
        HiLog.e(TAG, `IsInPcMode. false`);
      }
      HiLog.i(TAG, 'Camera setFullScreen finished.');
      const preferences = PreferencesService.getInstance();
      // if (!<boolean> preferences.getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false)) {
      //   HiLog.e(TAG, 'intro not loaded return');
      //   return;
      // }
      this.mWindow?.setSpecificSystemBarEnabled('status', false, false).then(() => {
        HiLog.e(TAG, 'setSpecificSystemBarEnabled status false');
      }).catch((err) => {
        HiLog.e(TAG, `setSpecificSystemBarEnabled status err. ${err?.code}`);
      });
      this.mWindow?.setSpecificSystemBarEnabled('navigation', true, false).then(() => {
        HiLog.e(TAG, 'setSpecificSystemBarEnabled navigation false');
      }).catch((err) => {
        HiLog.e(TAG, `setSpecificSystemBarEnabled status err. ${err?.code}`);
      });
      HiLog.i(TAG, 'Camera setSystemBarEnable finished.');
      await this.mWindow.setWindowSystemBarProperties({
        statusBarColor: STATUS_BAR_COLOR,
        statusBarContentColor: STATUS_BAR_CONTENT_COLOR,
        // fix: 相机导航栏按钮和背景色一样导致区分不出来
        navigationBarColor:NAVIGATION_BAR_COLOR,
        navigationBarContentColor: NAVIGATION_BAR_CONTENT_COLOR
      });
      HiLog.i(TAG, 'Camera setSystemBarProperties.');
    } catch (err) {
      HiLog.i(TAG, 'Camera setFullScreen err: ' + err);
    }
  }

  public getWindowRect(): window.Rect {
    if (this.rect) {
      return this.rect;
    } else {
      try {
        return this.mWindow?.getWindowProperties()?.windowRect;
      } catch (err) {
        HiLog.e(TAG, 'getWindowRect err: ' + err);
      }
    }
  }

  public setWindowRect(rect: window.Rect): void {
    this.rect = rect;
  }

  public setWinOrientation(orientation: window.Orientation): void {
    if (this.isWindowRotationChangeLocked) {
      HiLog.i(TAG, 'rot locked in immersive');
      return;
    }
    const isShowPhotoBrowser: boolean | undefined = AppStorage.get('showPhotoBrowserAction');
    if (isShowPhotoBrowser) {
      HiLog.w(TAG, 'setPreferredOrientation return PhotoBrowser isShow');
      return;
    }
    HiLog.i(TAG, `setPreferredOrientation: ${orientation}`);
    this.clearTimer();
    this.timerId = setTimeout((): void => {
      this.timerId = Number.MIN_VALUE;
      let setSuccess = true;
      try {
        this.mWindow?.setPreferredOrientation(orientation).then(() => {
          HiLog.i(TAG, 'Camera setPreferredOrientation finished.');
        }).catch((err) => {
          HiLog.e(TAG, `Camera setPreferredOrientation err: ${err?.code}`);
          setSuccess = false;
        });
      } catch (err) {
        setSuccess = false;
        HiLog.e(TAG, `Camera setPreferredOrientation err1: ${err?.code}`);
      }
      if (setSuccess) {
        let windowLockDir: WindowDirection = this.orientationToWindowDirection(orientation);
        HiLog.i(TAG, 'windowLockDirection:' + windowLockDir);
        execDispatch(WindowAction.updateWindowLockDir(windowLockDir));
      }
    }, (orientation === window.Orientation.FOLLOW_DESKTOP && !AppStorage.get('isLemCollaps')) ? 300 : 0);
  }

  public getWinOrientation(): window.Orientation {
    try {
      return this.mWindow?.getPreferredOrientation();
    } catch (err) {
      HiLog.e(TAG, `getWinOrientation err: ${err}.`);
    }
  }

  public isVertical(): boolean {
    return getStates().get<number>('windowReducer', 'windowWidth') <
    getStates().get<number>('windowReducer', 'windowHeight');
  }

  /**
   * 设置主窗口是否可以点击
   * @param isTouchable
   */
  public setWindowTouchable(isTouchable: boolean): void {
    this.mWindow?.setWindowTouchable(isTouchable, (err) => {
      if (err?.code) {
        HiLog.e(TAG, 'Failed to set the window to be touchable. Cause:' + err?.code);
        return;
      }
      HiLog.i(TAG, 'Succeeded in setting the window to be touchable.');
    });
  }

  public initFloatingService(): void {
    this.initializedFloating = true;
  }

  public initAvoidArea(): void {
    try {
      this.cutoutAvoidArea = this.mWindow?.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
      HiLog.i(TAG, `windowAvoidArea Area: ${JSON.stringify(this.cutoutAvoidArea)}.`);
      this.changeTopAvoidArea();
      this.mWindow?.on('avoidAreaChange', (data: {
        type: window.AvoidAreaType,
        area: window.AvoidArea
      }) => {
        if (data.type === window.AvoidAreaType.TYPE_CUTOUT) {
          this.cutoutAvoidArea = data.area;
        } else {
          return;
        }
        HiLog.i(TAG, `avoidAreaChange, type: ${data.type}, rect: ${JSON.stringify(data.area.topRect)}.`);
        if (this.changeTopAvoidArea()) {
          execDispatch(WindowAction.refresh());
        }
      });
    } catch (err) {
      HiLog.e(TAG, `initAvoidArea err: ${err}.`);
    }
  }

  private orientationToWindowDirection(orientation: window.Orientation): WindowDirection {
    let baseLineDirection: WindowDirection = WindowDirection.TOP;
    switch (orientation) {
      case window.Orientation.PORTRAIT:
        baseLineDirection = WindowDirection.TOP;
        break;
      case window.Orientation.LANDSCAPE_INVERTED:
        baseLineDirection = WindowDirection.RIGHT;
        break;
      case window.Orientation.PORTRAIT_INVERTED:
        baseLineDirection = WindowDirection.BOTTOM;
        break;
      case window.Orientation.LANDSCAPE:
        baseLineDirection = WindowDirection.LEFT;
        break;
      default:
        break;
    }
    return baseLineDirection;
  }

  private changeTopAvoidArea(): boolean {
    const empty: window.Rect = {
      left: 0,
      top: 0,
      width: 0,
      height: 0
    };
    const cutoutTopRect: window.Rect = !!this.cutoutAvoidArea ? this.cutoutAvoidArea.topRect : empty;
    let topAvoidArea = Math.round(px2vp(cutoutTopRect.top + cutoutTopRect.height));
    if (topAvoidArea === 0) {
      topAvoidArea = 24;
    }
    if (AdaptiveLayoutService.getInstance().getTopAvoidArea() === topAvoidArea) {
      return false;
    }
    HiLog.i(TAG, `changeTopAvoidArea, topAvoidArea: ${topAvoidArea}.`);
    AdaptiveLayoutService.getInstance().setTopAvoidArea(topAvoidArea);
    execDispatch(WindowAction.changeTopAvoidArea(topAvoidArea));
    return true;
  }

  private clearTimer(): void {
    if (Number.MIN_VALUE !== this.timerId) {
      clearTimeout(this.timerId);
      this.timerId = Number.MIN_VALUE;
    }
  }

  public lockXComponentSurface(): void {
    HiLog.i(TAG, 'lock xComponent surface rotation.');
    XComponentService.getInstance().lockSurface(true);
    this.isLocked = true;
    this.clearTimer();
    this.timerId = setTimeout((): void => {
      this.timerId = Number.MIN_VALUE;
      this.setWinOrientation(window.Orientation.FOLLOW_DESKTOP);
    }, 500); //加延时是为了让预览大小变化完成之后窗口再做旋转
  }

  public unlockXComponentSurface(): void {
    HiLog.i(TAG, 'unlock xComponent surface rotation.');
    this.clearTimer();
    this.setWinOrientation(window.Orientation.FOLLOW_DESKTOP);
    XComponentService.getInstance().lockSurface(false);
    this.isLocked = false;
  }

  public xComponentIsLocked(): boolean {
    return this.isLocked;
  }

  public getWindowStatus(): window.WindowStatusType {
    if (this.windowStatus === undefined) {
      // 没有直接获得windowStatusType的接口
      this.windowStatus = window.WindowStatusType.FULL_SCREEN;
      HiLog.i(TAG, 'getWindowStatus is undefined, return FULL_SCREEN.');
    }
    return this.windowStatus;
  }

  public getWindowVisibilityStatus(): boolean {
    return this.windowVisibilityStatus;
  }

  /**
   * 设置主窗口全屏模式时导航栏显示和隐藏， 欢迎页和引导页未加载时，设置效果为常显
   * @param state  'true' | 'false' 显示|隐藏
   * @param animation 'true' | 'false' 打开动效|关闭动效
   * @param keepConstantDisplay 'true' | 'false' 是否保持常显
   * 当前规格：三键时常显，AIBar时维持原来规格。部分界面常显
   */
  public setSpecificSystemNavigationEnabled(state: boolean, animation: boolean, keepConstantDisplay: boolean): void {
    HiLog.i(TAG, `setSpecificSystemNavigationEnabled trigger. ${state}-${animation}-${keepConstantDisplay}`);
    this.aiBarStyle.state = state;
    this.aiBarStyle.animation = animation;
    this.aiBarStyle.keepConstantDisplay = keepConstantDisplay;
    if (this.navigationStyle !== NavigationStyle.AI_BAR && !GlobalContext.get().getT('isSecurityCamera')) {
      HiLog.i(TAG, 'setSpecificSystemNavigationEnabled return because is not AI bar.');
      this.setNavigationBarAlwaysShow();
      return;
    }
    if (!this.isGuidanceLoaded() && !GlobalContext.get().getIsPicker()) {
      this.mWindow?.setSpecificSystemBarEnabled('navigationIndicator', true, false).then(() => {
        HiLog.e(TAG, 'setSpecificSystemBarEnabled navigation default success.');
      }).catch((err) => {
        HiLog.e(TAG, `setSpecificSystemBarEnabled err. ${err?.code}`);
      });
      return;
    }
    // 显示且不保持常显 整改为不常显 后续跟随AiBar接口做2秒自动隐藏变更
    if (state && !keepConstantDisplay) {
      this.mWindow?.setSpecificSystemBarEnabled('navigationIndicator', false, animation).then(() => {
        HiLog.i(TAG, `setSpecificSystemBarEnabled navigation - ${false} success.  keepConstantDisplay is false`);
      }).catch((err) => {
        HiLog.e(TAG, `setSpecificSystemBarEnabled err. ${err?.code}`);
      });
      return;
    }
    // 显示且常显 保持原有逻辑
    this.mWindow?.setSpecificSystemBarEnabled('navigationIndicator', state, animation).then(() => {
      HiLog.i(TAG, `setSpecificSystemBarEnabled navigation - ${state} success1.`);
    }).catch((err) => {
      HiLog.i(TAG, `setSpecificSystemBarEnabled err1. ${err?.code}`);
    });
  }

  /**
   * 设置三键导航时常显
   */
  private setNavigationBarAlwaysShow(): void {
    this.mWindow?.setSpecificSystemBarEnabled('navigationIndicator', true, true).then(() => {
      HiLog.i(TAG, 'setNavigationBarAlwaysShow - true success.');
    }).catch((err) => {
      HiLog.i(TAG, `setNavigationBarAlwaysShow err. ${err?.code}`);
    });
  }

  /**
   * 获取导航栏类型
   */
  private initNavigationStyle(): NavigationStyle {
    let flag: NavigationStyle = NavigationStyle.AI_BAR;
    flag = SettingsValueUtil
      .getValueSync('floatingNavigation', '1', settings.domainName.USER_PROPERTY) as NavigationStyle;
    HiLog.d(TAG, `initNavigationStyle ${flag}`);
    return flag;
  }

  /**
   *  处理导航栏类型变化
   */
  private dealWithNavigationStyleChange(): void {
    HiLog.d(TAG, `dealWithNavigationStyleChange ${this.navigationStyle}`);
    const flag: string = settings.getValueSync(
      ContextManager.getInstance().getAbilityContext(), 'floatingNavigation', '1', settings.domainName.USER_PROPERTY);
    HiLog.d(TAG, `dealWithNavigationStyleChange: ${flag}`);
    if (flag === this.navigationStyle) {
      return;
    }
    this.navigationStyle = flag as NavigationStyle;
    if (this.navigationStyle === NavigationStyle.AI_BAR) {
      HiLog.d(TAG, `aibar style ${this.aiBarStyle.state},${this.aiBarStyle.animation},
        ${this.aiBarStyle.keepConstantDisplay}`);
      this.setSpecificSystemNavigationEnabled(
        this.aiBarStyle.state,
        this.aiBarStyle.animation,
        this.aiBarStyle.keepConstantDisplay);
    } else {
      this.setNavigationBarAlwaysShow();
    }
  }

  /**
   * 欢迎页和引导页是否已加载完成
   * @returns
   */
  public isGuidanceLoaded(): boolean {
    const instance = PreferencesService.getInstance();
    if (!instance.getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean) {
      return false;
    }
    if (!instance.getPublicValue(PersistType.FOREVER, PublicTag.IS_GUIDANCE_LOADED, false) as boolean) {
      return false;
    }
    return true;
  }

  /**
   * 锁定旋转时是否需要订阅 全局的direction和settingAngle
   * @returns
   */
  public isSubscriptionNeeded(): boolean {
    let windowStatus: window.WindowStatusType = WindowService.getInstance().getWindowStatus();
    const direction = getStates().get<WindowDirection>('contextReducer', 'direction');
    const isShowLandscape = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    const isShowSemiCollapsed = getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed');

    return direction !== WindowDirection.BOTTOM && (!isShowLandscape || isShowSemiCollapsed) &&
      this.accelerometerStatus === '1' && windowStatus !== window.WindowStatusType.FLOATING &&
      windowStatus !== window.WindowStatusType.SPLIT_SCREEN;
  }

  public getWindowAndXComDiffer(winSize: number, xCompSize: number): number {
    let differNum = winSize - xCompSize;
    if (differNum < DIFFER_TOLERANCE) {
      differNum = 0;
    }
    return differNum;
  }

  public async setWaterMarkFlag(): Promise<void> {
    if (this.isSetWaterMarkFlag) {
      await this.mWindow.setWaterMarkFlag(false).then(() => {
        HiLog.i(TAG, 'WaterMark is close');
      }).catch(error => {
        HiLog.i(TAG, `Failed to Set Watermark: ${error.message}`);
      });
      this.isSetWaterMarkFlag = false;
      HiLog.i(TAG, 'WaterMarkFlag : true -> false');
      return;
    }
    HiLog.i(TAG, 'WaterMarkFlag : false -> false');
    return;
  }

  private async onPhotoBrowserStatusChange(data: PhotoBrowserStatusData): Promise<void> {
    if (data.photoBrowserStatus && this.isSetWaterMarkFlag) {
      await this.mWindow.setWaterMarkFlag(false);
      this.isSetWaterMarkFlag = false;
    }
  }

  public setWindowDecorVisiblePc(isVisible: boolean): void {
    this.mWindow.setWindowDecorVisible(isVisible);
    this.mWindow.setWindowDecorHeight(WIN_DECOR_HEIGHT);
    let colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    let style: window.DecorButtonStyle = {
      colorMode: colorMode,
      buttonBackgroundSize: 28,
      spacingBetweenButtons: 12,
      closeButtonRightMargin: 20
    };
    this.mWindow.setDecorButtonStyle(style);

  }

  public setDecorButtonStyle(isNoSetColorMode: Boolean): void {
    let colorMode: ConfigurationConstant.ColorMode =
      isNoSetColorMode ? ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET :
      ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    this.mWindow.setWindowTitleButtonVisible(true, true, true);
    let style: window.DecorButtonStyle = {
      colorMode: colorMode,
      buttonBackgroundSize: 28,
      spacingBetweenButtons: 12,
      closeButtonRightMargin: 20
    };
    this.mWindow.setDecorButtonStyle(style);
  }
}