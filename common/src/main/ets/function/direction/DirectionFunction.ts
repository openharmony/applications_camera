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

import lazy { HiLog } from '../../utils/HiLog';
import lazy { BaseFunction } from '../core/BaseFunction';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { Action } from '../../redux/actions/Action';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { DirectionToAngleUtil } from '../../utils/DirectionToAngleUtil';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';
import lazy { RenderType } from '../core/functionproperty/RenderType';
import lazy { UiElement } from '../core/UiElement';
import lazy {
  GravityData,
  MotionRotateCallback,
  SensorCallback,
  SensorService
} from '../../service/sensor/SensorService';
import display from '@ohos.display';
import window from '@ohos.window';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import lazy { ContextManager } from '../../service/context/ContextManager';
import lazy { getStates } from '../../redux';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { ThumbnailActionType } from '../../redux/actions/ThumbnailActionType';
import lazy { WindowActionType } from '../../redux/actions/WindowActionType';
import lazy { SettingViewActionType } from '../../redux/actions/SettingViewActionType';
import lazy { AccessibilityUtils } from '../../utils/AccessibilityUtils';
import lazy { settings } from '@kit.BasicServicesKit';
import ResGetter from '../../utils/ResGetter';
import lazy { PreferencesService, PersistType } from '../../service/preferences/PreferencesService';
import lazy { PublicTag } from '../../service/preferences/PropTag';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { SettingsValueUtil } from '../../utils/SettingsValueUtil';
import { CollaborateControlActionType } from '../../redux/actions/CollaborateControlActionType';

const TAG = 'DirectionFunction';
const OVERLOOKING_GRAVITY_OF_Z_AXIS: number = 8.487; //屏幕与水平面夹角小于30°时, 显示垂直水平仪(G * cos30°)

interface PhotoBrowserStatus {
  photoBrowserStatus: boolean
};

/* instrument ignore file */
export class DirectionFunction extends BaseFunction {
  private static readonly ANIM_ROTATE_180: number = 180;
  private static readonly ANIM_ROTATE_360: number = 360;
  private mDirection: number = WindowDirection.TOP;
  private mInstantDirection: number = WindowDirection.TOP;
  private mRotate: number = 0;
  private mSettingRotate: number = 0;
  private isLockRotation: boolean = true;
  private isUnRegisterMotion: boolean = false;
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.NONE];
  private mMotionData: number = -1;
  private mTimer: number = Number.MIN_VALUE;
  private mTimeOutTask: number = Number.MIN_VALUE;
  private isLevel: boolean = false;
  private isSensorCallBackTimeOut: boolean = false;
  private isSensorDataReturn: boolean = false;
  private mCallback: MotionRotateCallback = {
    onMotionRotate: (data: number) => {
      this.onMotionSensor(data);
    }
  };

  private mSensorCallback: SensorCallback = {
    onGravitySensor: (data: GravityData) => {
      this.onGSensor(data);
    }
  };

  constructor() {
    super();
  }

  getFunctionId(): FunctionId {
    return FunctionId.DIRECTION;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    return RenderType.NONE;
  }

  getUiElements(renderLocation: RenderLocation): Map<unknown, UiElement> {
    return new Map();
  }

  isAvailable(): boolean {
    return true;
  }

  load(renderLocations: RenderLocation[]): void {
    HiLog.i(TAG, 'load E.');
    this.mEventBus.on([ContextActionType.ABILITY_ON_FOREGROUND, ActionType.ACTION_INTRO_CONFIRM],
      this.onRegisterMotion.bind(this), this.mBase.hashCode());
    this.mEventBus.on([WindowActionType.ON_LOCK_ROTATION_STATUS_CHANGE, WindowActionType.REFRESH_UX],
      this.rotationStatusChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackGround.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.PHOTOBROWSER_STATUS, this.handlePhotoBrowser.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(SettingViewActionType.ACTION_SHOW_SETTING_VIEW, this.isShowSettingView.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on([WindowActionType.ON_SIZE_CHANGE, ContextActionType.ABILITY_ON_FOREGROUND],
      this.pickerOrientationChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CHECK_CURRENT_DIRECTION, this.resendDirection.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.PHOTO_BROWSER, this.onPhotoBrowser.bind(this),
      this.mBase.hashCode());
    HiLog.i(TAG, 'load x.');
  }

  unload(renderLocations: RenderLocation[]): void {
    HiLog.i(TAG, 'unload E.');
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'unload X.');
  }

  private onRegisterMotion(): void {
    const isPicker: boolean = GlobalContext.get().getIsPicker();
    let isIntroLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean;
    if (!isIntroLoaded && !isPicker && !AppStorage.get('isLemCollaps')) { //引导页没加载过,而且不是picker
      HiLog.w(TAG, 'Intro not load return');
      return;
    }
    this.registerMotionListener(); // 方向判断direction使用motion
    this.readOnceSensorData(); // 判断用户进入相机时是否平放状态-直接重置成初始状态;读取到一次值后取消注册
    this.mTimer = setTimeout(() => {
      if (!this.isSensorDataReturn) { //如果sensor没返回数据就重新去下发一次motion数据
        HiLog.i(TAG, 'setTimeout resendDirection');
        this.isSensorDataReturn = true;
        this.resendDirection();
      }
    }, 200);

    this.mTimeOutTask = setTimeout(() => {
      this.isSensorCallBackTimeOut = true;
    }, 1000);
  }

  private readOnceSensorData(): void {
    try {
      SensorService.getInstance().registerGravityListener(this.mSensorCallback, this.mBase.hashCode());
    } catch (err) {
      HiLog.e(TAG, `Sensor GRAVITY try catch err: ${err}.`);
    }
  }

  private onPhotoBrowser(data: { isShow: boolean }): void {
    HiLog.i(TAG, `onPhotoBrowser ${data.isShow}`);
    if (!data.isShow) {
      this.resendDirection();
    }
  }

  private onGSensor(data: GravityData): void {
    HiLog.i(TAG, 'DirectionFunctionGSensor: ' + JSON.stringify(data));
    this.isSensorDataReturn = true;
    clearTimeout(this.mTimer);
    clearTimeout(this.mTimeOutTask);
    SensorService.getInstance().unRegisterGravityListener(this.mBase.hashCode());
    if (this.isSensorCallBackTimeOut) {
      HiLog.w(TAG, `onGSensor timeout return`);
      return;
    }
    if (Math.abs(data.z) > OVERLOOKING_GRAVITY_OF_Z_AXIS) { //水平
      HiLog.i(TAG, 'DirectionFunctionGSensor Level');
      this.isLevel = true;
      this.reSetDefaultDirection();
    } else {
      this.isLevel = false;
      this.resendDirection();
    }
  }

  private rotationStatusChange(): void {
    HiLog.i(TAG, 'rotationStatusChange E');
    if (this.isLevel) {
      HiLog.w(TAG, 'rotationStatusChange return isLevel true');
      return;
    }
    this.isLockRotation = getStates().get<boolean>('windowReducer', 'isLockRotation');
    let photoBrowserStatus = getStates().get<boolean>('thumbnailReducer', 'photoBrowserStatus');
    let rotationStatus =
      SettingsValueUtil.getValueSync(settings.general.ACCELEROMETER_ROTATION_STATUS, '0');
    HiLog.i(TAG, 'rotationStatus:' + rotationStatus + ', MotionData:' + this.mMotionData);
    if (this.isLockRotation) {
      this.mStoreManager.postMessage(Action.lockRotationChange(this.mMotionData));
    }
    if (this.canCameraWinBeRotate() && !photoBrowserStatus) {
      this.reSetDefaultDirection();
    } else {
      this.resendDirection();
    }
    HiLog.i(TAG, 'rotationStatusChange X');
  }

  private reSetDefaultDirection(): void {
    if (AppStorage.get('isLemCollaps')) {
      HiLog.i(TAG, `reSetDefaultDirection return.`);
      return;
    }
    HiLog.i(TAG, 'reSet default direction.');
    const isShowLandscape: boolean = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    const isShowSemiCollapsed: boolean = getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed');
    if (isShowLandscape && isShowSemiCollapsed) {
      HiLog.i(TAG, 'current status is COLLAPS_STATUS_HALF_COLLAPSED need return.');
      return;
    }
    this.mDirection = DeviceInfo.isTablet() && this.isLockRotation ? WindowDirection.RIGHT : this.reSetGetDirection();
    this.calculateAngle(this.mDirection);
    this.mStoreManager.postMessage(Action.directionChange(this.mDirection, this.mRotate, this.mSettingRotate));
  }

  private reSetGetDirection(): number {
    if (!this.isLockRotation) {
      return WindowDirection.TOP;
    }
    const rotation: number = DisplayService.getInstance().getDisplay().rotation;
    const orientation: number = DisplayService.getInstance().getDisplay().orientation;
    HiLog.i(TAG, `reSetGetDirection is rotation: ${rotation}, orientation: ${orientation}`);
    switch (rotation) {
      case 0:
        return WindowDirection.TOP;
      case 1:
        return WindowDirection.LEFT;
      case 2:
        return WindowDirection.BOTTOM;
      case 3:
        return WindowDirection.RIGHT;
      default:
        return WindowDirection.TOP;
    }
  }

  private resendDirection(): void {
    HiLog.i(TAG, 'resendDirection E');
    if (this.isLevel) {
      HiLog.w(TAG, 'resendDirection return isLevel true');
      return;
    }
    this.onMotionSensor(this.mMotionData);
  }

  private canCameraWinBeRotate(): boolean { //当前窗口没有提供可以查询是否能旋转的接口 只有枚举了
    //1.屏展开态 2.平板  3.屏展开态悬浮窗或者分屏 4.直板机悬浮窗打开其它可以旋转的应用 5.picker分屏场景  6正常相机分屏场景
    //7 vde外屏旋转
    const isVdeCollapsed: boolean = getStates().get<boolean>('collapsReducer', 'isVdeCollapsed');
    const windowStatus = WindowService.getInstance().getWindowStatus();
    if (!this.isLockRotation && this.isOrientationSupportRotation() &&
      (this.isShowLandscape() || DeviceInfo.isTablet())) {
      return true;
    }
    if (!this.isLockRotation && DeviceInfo.isPhone() &&
      !(this.isShowLandscape()) &&
      windowStatus === window.WindowStatusType.FLOATING &&
      DisplayService.getInstance().getDisplay().rotation !== 0) {
      return true;
    }
    if (!this.isLockRotation && (PickerUtils.getIsPickerInSplitScreen() ||
      (!PickerUtils.getIsPickerInSplitScreen() && windowStatus === window.WindowStatusType.SPLIT_SCREEN) ||
      isVdeCollapsed)) {
      return true;
    }
    return false;
  }

  private isOrientationSupportRotation(): boolean {
    const winOrientation = WindowService.getInstance().getWinOrientation();
    return winOrientation === window.Orientation.FOLLOW_DESKTOP ||
      winOrientation === window.Orientation.AUTO_ROTATION ||
      winOrientation === window.Orientation.AUTO_ROTATION_UNSPECIFIED ||
      winOrientation === window.Orientation.AUTO_ROTATION_RESTRICTED ||
      winOrientation === window.Orientation.USER_ROTATION_LANDSCAPE ||
      winOrientation === window.Orientation.USER_ROTATION_PORTRAIT;
  }

  private isShowLandscape(): boolean {
    const isShowLandscape: boolean = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    return isShowLandscape && false;
  }

  private handlePhotoBrowser(data: PhotoBrowserStatus): void {
    let photoBrowserStatus: boolean = data.photoBrowserStatus;
  }

  private registerMotionListener(): void {
    this.isUnRegisterMotion = false;
    SensorService.getInstance().registerMotionRotateListener(this.mCallback, this.mBase.hashCode());
    HiLog.i(TAG, 'registerMotionListener X.');
  }

  private onMotionSensor(data: number): void {
    HiLog.i(TAG, 'onMotionSensor mMotionData:' + data);
    this.mMotionData = data;
    if (data !== -1 && this.isSensorDataReturn) { // 返回值data===-1表示状态未改变
      HiLog.i(TAG, 'onMotionSensor if mMotionData: ' + data);
      this.isLevel = false;
      this.mStoreManager.postMessage(Action.motionDirectionChange(data));
      let direction = this.motionMappingDirection(data);
      this.changeInstantDirection(direction);
      this.changeDirection(direction);
    }
  }

  // 从motion旋转角度转换成应用内定义的四个方向
  private motionMappingDirection(data: number): number {
    let direction = WindowDirection.TOP;
    switch (data) {
      case 0:
        direction = AppStorage.get('isLemCollaps') ? WindowDirection.BOTTOM : WindowDirection.TOP;
        break;
      case 1:
        direction = AppStorage.get('isLemCollaps') ? WindowDirection.LEFT : WindowDirection.RIGHT;
        break;
      case 2:
        direction = AppStorage.get('isLemCollaps') ? WindowDirection.TOP : WindowDirection.BOTTOM;
        break;
      case 3:
        direction = AppStorage.get('isLemCollaps') ? WindowDirection.RIGHT : WindowDirection.LEFT;
        break;
      default:
        direction = WindowDirection.TOP;
        break;

    }
    HiLog.i(TAG, 'motionMappingDirection direction is ' + direction);
    return direction;
  }

  private onBackGround(): void {
    HiLog.i(TAG, 'onBackGround.');
    this.isLevel = false;
    this.isSensorDataReturn = false;
    this.isSensorCallBackTimeOut = false;
    this.unRegisterMotionListener();
    SensorService.getInstance().unRegisterGravityListener(this.mBase.hashCode());
    clearTimeout(this.mTimer);
    clearTimeout(this.mTimeOutTask);
  }

  private unRegisterMotionListener(): void {
    this.isUnRegisterMotion = true;
    SensorService.getInstance().unRegisterMotionRotateListener(this.mBase.hashCode());
    HiLog.i(TAG, 'unRegisterMotionListener X');
  }

  private changeInstantDirection(direction: WindowDirection): void {
    return;
    if (this.isUnRegisterMotion) { //相机退出了就不再发送方向改变的消息
      return;
    }
    if ((AppStorage.Get('settingAnimationDoing')) || this.mInstantDirection === direction) {
      HiLog.w(TAG, `direction is  ${direction} not change , Don't changeInstantDirection`);
      return;
    }
    this.mStoreManager.postMessage(Action.instantDirectionChange(direction));
    this.mInstantDirection = direction;
  }

  private changeDirection(direction: WindowDirection): void {
    const isShowPhotoBrowser: boolean | undefined = AppStorage.get('showPhotoBrowserAction');
    if (this.isUnRegisterMotion || isShowPhotoBrowser) { //相机退出了就不再发送方向改变的消息
      HiLog.w(TAG, `isUnRegisterMotion or isShowPhotoBrowser is true  Don't changeDirection`);
      return;
    }
    HiLog.i(TAG,
      'this.mDirection:' + this.mDirection + ',' + direction + ',' + AppStorage.Get('settingAnimationDoing'));
    if ((AppStorage.Get('settingAnimationDoing')) || this.mDirection === direction) {
      let rotate: number = DirectionToAngleUtil.geViewRotate(direction);
      let diff: number = this.getDiffRotate(rotate);
      if (diff % 360 === 0) {
        HiLog.w(TAG, `direction is  ${direction} not change , Don't changeDirection`);
        return;
      }
    }
    const windowStatus = WindowService.getInstance().getWindowStatus();
    if (PickerUtils.getIsPickerInSplitScreen() && !this.isLockRotation) { //picker分屏模式不下发角度
      HiLog.w(TAG, `getIsPickerInSplitScreen is true , Don't changeDirection`);
      return;
    }
    if ((windowStatus === window.WindowStatusType.FLOATING || windowStatus === window.WindowStatusType.SPLIT_SCREEN) &&
      DisplayService.getInstance().getDisplay().rotation !== 0 && !this.isLockRotation) { //悬浮窗或者分屏场景 不旋转
      HiLog.w(TAG, `windowStatus is FLOATING or SPLIT_SCREEN , Don't changeDirection`);
      return;
    }
    if (this.canCameraWinBeRotate()) { //窗口可以旋转就不去发消息了
      HiLog.w(TAG, `direction is  ${direction}, mDirection is ${this.mDirection}`);
      if (this.mDirection !== direction) {
        this.mDirection = WindowDirection.TOP;
        this.calculateAngle(this.mDirection);
        this.mStoreManager.postMessage(Action.directionChange(this.mDirection, this.mRotate, this.mSettingRotate));
      }
      HiLog.w(TAG, `Window can be rotated, Don't changeDirection`);
      return;
    }
    this.mDirection = direction;
    this.calculateAngle(direction);
    if (AppStorage.get('windowDisplayName') === 'SuperLauncher') {
      this.mRotate = 0;
    }
    if (AppStorage.get('enableScreenReader')) {
      let directionStr: string = ResGetter.getStringSafe($r('app.string.device_direction_vertical')); // 已开始走提翻流程
      if (direction === WindowDirection.LEFT || direction === WindowDirection.RIGHT) {
        directionStr = ResGetter.getStringSafe($r('app.string.device_direction_horizontal'));
      }
      AccessibilityUtils.sendAnnounceAccessibilityEvent(directionStr);
    }
    // 充电口朝下top;direction
    // 不锁定旋转:上一次的值;锁定旋转:充电口朝下0;rotate
    this.mStoreManager.postMessage(Action.directionChange(direction, this.mRotate, this.mSettingRotate));
    HiLog.i(TAG, `send action directionChange currentDirection: ${direction},
       rotate: ${this.mRotate} , settingRotate: ${this.mSettingRotate}, settingDiff: ${this.mSettingRotate}.`);
  }

  // 转换motion角度为应用内定义的角度
  private calculateAngle(direction: WindowDirection): void {
    const isShowLandscape: boolean = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    const isShowSemiCollapsed: boolean = getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed');
    let rotate: number = DirectionToAngleUtil.geViewRotate(direction);
    HiLog.i(TAG, 'calculateAngle rotate:' + rotate);
    let settingRotate: number = DirectionToAngleUtil.geViewRotate(direction, true);
    let diff: number = this.getDiffRotate(rotate);
    HiLog.i(TAG, 'calculateAngle diff:' + diff);
    this.mRotate = this.mRotate + diff;
    if (this.mDirection !== WindowDirection.BOTTOM) {
      let settingDiff: number = settingRotate - this.mSettingRotate;
      while (settingDiff > DirectionFunction.ANIM_ROTATE_180) {
        settingDiff -= DirectionFunction.ANIM_ROTATE_360;
      }
      while (settingDiff < -DirectionFunction.ANIM_ROTATE_180) {
        settingDiff += DirectionFunction.ANIM_ROTATE_360;
      }
      this.mSettingRotate =
        this.mSettingRotate + (settingDiff === DirectionFunction.ANIM_ROTATE_180 ? -settingDiff : settingDiff);
    }
    if (isShowLandscape || isShowSemiCollapsed || DeviceInfo.isTablet()) {
      this.mSettingRotate = 0;
    }
  }

  private getDiffRotate(rotate: number): number {
    let diff: number = rotate - this.mRotate;
    const isUIExtensionPicker: boolean = PickerUtils.getIsPicker() &&
      !!ContextManager.getInstance().getUiExtensionContext();
    const isShowLandscape: boolean = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    const windowStatus = WindowService.getInstance().getWindowStatus();
    if (!isShowLandscape && !DeviceInfo.isTablet() && !DeviceInfo.isPc() &&
      !(windowStatus === window.WindowStatusType.FLOATING ||
        windowStatus === window.WindowStatusType.SPLIT_SCREEN)) { //直板机而且非悬浮窗分屏场景
      diff += 0;
    } else if (!this.canCameraWinBeRotate() && (!isUIExtensionPicker || DeviceInfo.isTablet())) {
      const rotation = DisplayService.getInstance().getDisplay().rotation; // 依赖屏幕的角度,锁定旋转的场景
      HiLog.i(TAG, 'calculateAngle rotation:' + rotation);
      switch (rotation) {
        case 1:
          diff += 90;
          break;
        case 2:
          diff += 180;
          break;
        case 3:
          diff += 270;
          break;
        default:
          diff += 0;
      }
    }
    while (diff > DirectionFunction.ANIM_ROTATE_180) {
      diff -= DirectionFunction.ANIM_ROTATE_360;
    }
    while (diff < -DirectionFunction.ANIM_ROTATE_180) {
      diff += DirectionFunction.ANIM_ROTATE_360;
    }
    if (PickerUtils.getIsExpandedTopBottomSplitScreen()) {
      diff += 90;
    }
    return diff;
  }

  private isShowSettingView(data: {
    isShowSettingView: boolean,
    isTriggeredByBack: boolean
  }): void {
    if (!data.isShowSettingView && !getStates().get<boolean>('collapsReducer', 'isShowLandscape')) {
      while (this.mSettingRotate > DirectionFunction.ANIM_ROTATE_180) {
        this.mSettingRotate -= DirectionFunction.ANIM_ROTATE_360;
      }
      while (this.mSettingRotate < -DirectionFunction.ANIM_ROTATE_180) {
        this.mSettingRotate += DirectionFunction.ANIM_ROTATE_360;
      }
      // 设置页退出动效做完之后，再去还原角度，防止设置页一直做旋转动效
      setTimeout((): void => {
        this.mStoreManager
          .postMessage(Action.directionChange(getStates().get<WindowDirection>('contextReducer', 'direction'),
            this.mRotate, this.mSettingRotate));
      }, 250);
    }
  }

  private pickerOrientationChange(): void {
    HiLog.i(TAG, 'pickerOrientationChange E');
    if (PickerUtils.getIsPickerInSplitScreen()) { //picker分屏
      if (!this.isLockRotation) { //可以旋转的场景
        this.setPickerExpandedSplitScreenDirection();
      }
    }
    HiLog.i(TAG, 'pickerOrientationChange X');
  }

  private setPickerExpandedSplitScreenDirection(): void {
    // 的G态orientation定义不一样，建议用rotation
    const rotation = DisplayService.getInstance().getDisplay().rotation;
    switch (rotation) {
      case display.Orientation.PORTRAIT:
        this.mDirection = WindowDirection.TOP;
        break;
      case display.Orientation.LANDSCAPE:
        this.mDirection = WindowDirection.LEFT;
        break;
      case display.Orientation.PORTRAIT_INVERTED:
        this.mDirection = WindowDirection.BOTTOM;
        break;
      case display.Orientation.LANDSCAPE_INVERTED:
        this.mDirection = WindowDirection.RIGHT;
        break;
      default:
        this.mDirection = WindowDirection.TOP;
        break;
    }
    if (PickerUtils.getIsExpandedTopBottomSplitScreen()) {
      this.mRotate = 450;
      this.mSettingRotate = 450;
    }
    if (PickerUtils.getIsExpandedLeftRightSplitScreen()) {
      this.mRotate = 0;
      this.mSettingRotate = 0;
    }
    HiLog.i(TAG, 'setPickerExpandedSplitScreenDirection direction:' + this.mDirection);
    this.mStoreManager.postMessage(Action.directionChange(this.mDirection, this.mRotate, this.mSettingRotate));
  }
}