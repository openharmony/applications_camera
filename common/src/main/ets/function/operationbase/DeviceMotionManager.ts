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
import display from '@ohos.display';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { getStates, Unsubscribe } from '../../redux';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { SwingManager } from './SwingManager';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { CollapsChangeService } from '../../service/collaps/CollapsChangeService';
import lazy { CollapsTypeUtil } from '../../utils/CollapsTypeUtil';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { window } from '@kit.ArkUI';
import lazy { CollapsActionType } from '../../redux/actions/CollapsActionType';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { MotionRollCallback, SensorService } from '../../service/sensor/SensorService';

interface CollapsData {
  collapsStatus: display.CollapsStatus
}

const TAG: string = 'DeviceMotionManager';

export class DeviceMotionManager {
  private static instance: DeviceMotionManager;
  // 后置智感自拍开关
  private isSmartBackSelfie: boolean = false;
  private collapsStatus: display.CollapsStatus = display.CollapsStatus.COLLAPS_STATUS_UNKNOWN;
  private hardStartFlipTimerId: number;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  private mCurrentMode: ModeType = ModeType.NONE;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  private mCallback: MotionRollCallback = {
    onMotionRoll: (data: number) => {
      this.flipCallback(data);
    }
  };

  public static getInstance(): DeviceMotionManager {
    if (!DeviceMotionManager.instance) {
      DeviceMotionManager.instance = new DeviceMotionManager();
    }
    return DeviceMotionManager.instance;
  }

  public initAbilityParams(): void {
    this.collapsStatus = CollapsChangeService.getInstance().getCurCollapsStatus();
    HiLog.i(TAG, `constructor collapsStatus=${this.collapsStatus}`);
    this.addListener();
    this.hardStartFlipTimerId = setTimeout((): void => {
      if (this.collapsStatus === display.CollapsStatus.COLLAPS_STATUS_EXPANDED || CollapsTypeUtil.isSmallIntSquareExtCollapsScreen()) {
        this.flipSubscriber();
      }
    }, 2 * 1000);
  }

  private addListener(): void {
    // 状态的监听
    this.mEventBus.on(CollapsActionType.ACTION_CHANGE_COLLAPS_STATUS, this.onLandscapeChanged.bind(this), this.mBase.hashCode());
    // 退出的监听
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackGround.bind(this), this.mBase.hashCode());
    // 打开的监听
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), this.mBase.hashCode());
    // 应用销毁的监听
    this.mEventBus.on(ContextActionType.ABILITY_ON_DESTROY, this.onDestroy.bind(this), this.mBase.hashCode());
    // 切换模式、切换镜头监听
    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.SWITCH_CAMERA, CameraActionType.SWITCH_CAMERA_CHANGE_MODE],
      this.handleModeChange.bind(this), this.mBase.hashCode());
  }

  private onForeground(): void {
    this.collapsStatus = CollapsChangeService.getInstance().getCurCollapsStatus();
    if (CollapsTypeUtil.isSmallIntSquareExtCollapsScreen()) {
      this.flipSubscriber();
    }
  }

  // 订阅翻转事件
  public async flipSubscriber(): Promise<void> {
    if (!CameraAppCapability.getInstance().getIsSupportedSmartBackSelfieFunction()) {
      HiLog.w(TAG, 'smart back selfie function is not support.');
      return;
    }
    this.isSmartBackSelfie = getStates().get('settingReducer', 'isSmartBackSelfie');
    if (!this.isSmartBackSelfie) {
      HiLog.w(TAG, 'The smartBackSelfie function is closed.');
      return;
    }
    if (!CollapsTypeUtil.isSmallIntSquareExtCollapsScreen() && this.collapsStatus !== display.CollapsStatus.COLLAPS_STATUS_EXPANDED) {
      HiLog.w(TAG, 'Is not in the expanded state and does not need to subscribered.');
      return;
    }
    this.mCurrentMode = getStates().get<ModeType>('modeReducer', 'mode');
    if (!this.isSmartBackSelfieSupport(this.mCurrentMode)) {
      HiLog.w(TAG, `This function is not supported in ${this.mCurrentMode} mode.`);
      return;
    }
    await SensorService.getInstance().registerMotionRollListener(this.mCallback, this.mBase.hashCode());
  }

  private flipCallback(motionValue: number): void {
    if (WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) {
      HiLog.w(TAG, 'The floating window status does not require subscription motion.');
      return;
    }
    HiLog.i(TAG, `on flip callback, result = ${motionValue}.`);
    this.mEventBus.emit(ActionType.ACTION_PHONE_FLIP, [motionValue]);
  }

  // 取消订阅翻转事件
  public async flipUnSubscriber(): Promise<void> {
    if (!CameraAppCapability.getInstance().getIsSupportedSmartBackSelfieFunction()) {
      return;
    }
    await SensorService.getInstance().unRegisterMotionRollListener(this.mBase.hashCode());
  }

  private onLandscapeChanged(data: CollapsData): void {
    this.collapsStatus = data.collapsStatus;
    if (this.collapsStatus === display.CollapsStatus.COLLAPS_STATUS_HALF_COLLAPSED ||
      this.collapsStatus === display.CollapsStatus.COLLAPS_STATUS_COLLAPSED) {
      if (CollapsTypeUtil.isSmallIntSquareExtCollapsScreen()) {
        return;
      }
      this.flipUnSubscriber();
    }
  }

  private handleModeChange(): void {
    this.flipUnSubscriber();
    SwingManager.getInstance().swingUnsubscribe();
  }


  private onBackGround(): void {
    clearTimeout(this.hardStartFlipTimerId);
  }

  private onDestroy(): void {
    clearTimeout(this.hardStartFlipTimerId);
    this.mSubscriber.destroy();
  }

  public isSmartBackSelfieSupport(mode: ModeType): boolean {
    switch (mode) {
      case ModeType.NIGHT:
      case ModeType.SNAPSHOT:
      case ModeType.PORTRAIT:
      case ModeType.PHOTO:
      case ModeType.VIDEO:
      case ModeType.PRO:
        return true;
      case ModeType.ROUND_PHOTO:
      case ModeType.ROUND_PORTRAIT:
      case ModeType.FLUOR:
      case ModeType.LIGHT_PAINTING:
      case ModeType.PANORAMA:
      case ModeType.STICKERS:
      case ModeType.DOCUMENTS:
      case ModeType.HIGH_RES:
      case ModeType.ROUND_VIDEO:
      case ModeType.SLOW_MO:
      case ModeType.STORY_CREATOR:
      case ModeType.TIME_LAPSE:
      case ModeType.SUPER_MACRO:
      case ModeType.APERTURE:
      case ModeType.HIGH_RES:
      default:
        return false;
    }
  }
}