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
import camera from '@ohos.multimedia.camera';
import display from '@ohos.display';
import lazy { HiLog } from '../../utils/HiLog';
//@ts-ignore
import swingAbility from '@ohos.swingability';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { CameraAction } from '../../camera/uithread/CameraAction';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { getStates, Unsubscribe } from '../../redux';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { Action } from '../../redux/actions/Action';
import lazy { DeviceMotionManager } from './DeviceMotionManager';
import lazy { CollapsChangeService } from '../../service/collaps/CollapsChangeService';
import lazy { BackSelfMode } from '../enumbase/BackSelfMode';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { PositionType } from '../../utils/types';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { OutputOperation } from '../../function/outputswitcher/OutputOperation';
import lazy { SizeUtil } from '../../utils/SizeUtil';
import lazy { CameraProxy } from '../../camera/uithread/CameraProxy';
import lazy { UserEventReport } from '../../statistics/UserEventReport';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { CollapsTypeUtil } from '../../utils/CollapsTypeUtil';
import lazy { window } from '@kit.ArkUI';
import lazy { ConnectCapabilityManager } from '../../rpcclient/ConnectCapabilityManager';
import lazy { ContextManager } from '../../service/context/ContextManager';
import lazy { execAction } from '../../redux/ActionRegistry';
import lazy { BusinessError } from '@ohos.base';
import lazy { CollapsActionType } from '../../redux/actions/CollapsActionType';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { ModePosWarmStartUtil } from '../../mode/ModePosWarmStartUtil';
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import lazy { PropTag } from '../../service/preferences/PropTag';

interface CollapsData {
  collapsStatus: display.CollapsStatus
}

const TAG: string = 'SwingManager';
const FACE_XMI: string = 'xmi';
const FACE_XMA: string = 'xma';
const FACE_YMI: string = 'ymi';
const FACE_YMA: string = 'yma';
const FACE_GAZE_STATU: string = 'gazeStatu';
const FACE_INTERACTION_TYP: string = 'FaceInteractionTyp';
const RESULT_TO_BACK_SELFIE: number = 1;
const RESULT_EXIT_SELFIE: number = 2;
const RESULT_TIME_EXCEED: number = 3;

export enum SwingDomainId {
  SMART_BACK_SELFIE_DOMAIN_ID = 17,
}

export enum FaceResult {
  TO_BACK_SELFIE = 1, // 切到后当前
  TO_FRONT_EXPANDED = 2, // 切到前置大屏
  NO_NEED_CHANGE = 3, // 不做处理
}

class PreviewFrameStartData {
  public isPreviewFrameStart: boolean = false;
}

export class SwingManager {
  private static instance: SwingManager;
  // swing归一后固定width
  private readonly SWING_NORMALIZED_WIDTH: number = 640;
  // swing归一后固定height
  private readonly SWING_NORMALIZED_HEIGHT: number = 480;
  private readonly NO_SWING_FACE_WAIT_TIME: number = 200;
  private readonly SWING_TIME_OUT: number = 3 * 1000;
  private readonly FACE_MIN_AREA: number = 0.1;
  private readonly FACE_COMPARE_RATIO: number = 0.55;
  // camera hal上报人脸检测注视状态最大x轴角度
  private readonly PITCH_MAX_ANGLE: number = 20;
  // camera hal上报人脸检测注视状态最大Y轴角度
  private readonly YAW_MAX_ANGLE: number = 30;
  // 前置swing固定zoomRatio
  private frontSwingZoomRatio: number;
  // 后置swing固定zoomRatio
  private backSwingZoomRatio: number;
  private backVideoEisStabilizeRatio: number;
  private frontVideoEisStabilizeRatio: number;
  // 后置智感自拍开关
  private isSmartBackSelfieOpen: boolean = false;
  private currentZoomRatio: number;
  private mBase: BaseComponent = new BaseComponent();
  private mCameraProxy: CameraProxy = CameraProxy.getInstance();
  // 订阅swing后，数据回调
  private swingSubscribeCallback: swingAbility.ISubscribeCallback;
  private mCurrentMode: ModeType = ModeType.NONE;
  private mIsSwingSubscriber: boolean = false;
  private firstFrameStart: boolean = false;
  // 是否是展开到大屏的操作
  private isExpandOperation: boolean = false;
  private swingDataCount: number = 1;
  private swingNoFace: boolean = false;
  private swingNoFaceCompareFinish: boolean = false;
  private mCameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  private collapsStatus: display.CollapsStatus = display.CollapsStatus.COLLAPS_STATUS_UNKNOWN;
  private subscribeEventList: swingAbility.SwingEventType[] = [];
  private unsubscribeEventList: swingAbility.SwingEventType[] = [];
  private isBackAsFront: boolean = false;
  private swingSubscribeTimerId: number;
  private noFaceWaitTimerId: number;
  private mStoreManager: StoreManager = StoreManager.getInstance();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private lastFlipTime: number;
  private lastCameraHalFacePrintTime: number;
  private cameraHalMaxFace: camera.Rect = null;
  private cameraHalFaceStableCount: number = 1;
  private swingMaxFace: camera.Rect = null;
  private smartBackSelfieTriggerChangeDisplayMode: boolean = false;
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  // 亮屏人脸相对位置（EOD2.0）事件 -----   前置
  private facePositionLightEvent: swingAbility.SwingEventType = {
    eventType: 'FACE_RELATIVE_POSITION_LIGHT',
    params: {
      'domainId': SwingDomainId.SMART_BACK_SELFIE_DOMAIN_ID
    }
  };
  // 后置人脸 相对位置事件
  private rearFaceInteractionEvent: swingAbility.SwingEventType = {
    eventType: 'REAR_FACE_INTERACTION',
    params: {
      'domainId': SwingDomainId.SMART_BACK_SELFIE_DOMAIN_ID
    }
  };

  private addListener(): void {
    // 状态的监听
    this.mEventBus.on(CollapsActionType.ACTION_CHANGE_COLLAPS_STATUS, this.onLandscapeChanged.bind(this), this.mBase.hashCode());
    // 退出的监听
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackGround.bind(this), this.mBase.hashCode());
    // 打开的监听
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), this.mBase.hashCode());
    // 应用销毁的监听
    this.mEventBus.on(ContextActionType.ABILITY_ON_DESTROY, this.onDestroy.bind(this), this.mBase.hashCode());
    // 预览首帧上报的监听
    this.mEventBus.on(ActionType.ACTION_ON_PREVIEW_FRAME_START, this.onPreviewFrameStart.bind(this), this.mBase.hashCode());
    // 手机翻转状态的监听
    this.mEventBus.on(ActionType.ACTION_PHONE_FLIP, this.onFlipStatusChanged.bind(this), this.mBase.hashCode());
    // 人脸数据的监听
    this.mEventBus.on(ActionType.ACTION_UPDATE_SMART_BACK_SELFIE_FACE_DATA,
      this.updateFaceData.bind(this), this.mBase.hashCode());
    // 后当前切换监听
    this.mEventBus.on(CameraActionType.RECOVER_CAMERA, this.recoverCamera.bind(this), this.mBase.hashCode());
    // 录像开始和暂停的监听
    this.mEventBus.on(RecordActionType.START, this.onRecordStart.bind(this), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.STOP, this.onRecordStop.bind(this), this.mBase.hashCode());
  }

  public static getInstance(): SwingManager {
    if (!SwingManager.instance) {
      SwingManager.instance = new SwingManager();
    }
    return SwingManager.instance;
  }

  public initAbilityParams(): void {
    this.collapsStatus = CollapsChangeService.getInstance().getCurCollapsStatus();
    this.addListener();
    this.swingCallbackInit();
  }

  // 订阅swing
  public async swingSubscriber(): Promise<void> {
    if (!CameraAppCapability.getInstance().getIsSupportedSmartBackSelfieFunction()) {
      HiLog.e(TAG, 'smart back selfie function is not support.');
      return;
    }
    this.mCurrentMode = getStates().get<ModeType>('modeReducer', 'mode');
    this.isSmartBackSelfieOpen = getStates().get('settingReducer', 'isSmartBackSelfie');
    if (!this.isSmartBackSelfieOpen || !DeviceMotionManager.getInstance().isSmartBackSelfieSupport(this.mCurrentMode)) {
      HiLog.e(TAG, `isSmartBackSelfieOpen：${this.isSmartBackSelfieOpen},curreentmode:${this.mCurrentMode}`);
      return;
    }
    if (this.mIsSwingSubscriber) {
      HiLog.w(TAG, 'swing has been subscriber.');
      return;
    }
    if (CollapsTypeUtil.isSmallIntSquareExtCollapsScreen() && CollapsChangeService.getInstance().isSmallIntSquareExtCollapsed()) {
      HiLog.w(TAG, 'current is vde collapsed status,not need subscriber swing.');
      return;
    } else {
      if (this.collapsStatus !== display.CollapsStatus.COLLAPS_STATUS_EXPANDED && !this.isBackAsFront) {
        HiLog.w(TAG, `current collapsStatus=${this.collapsStatus} error or swingSubscriber is ${this.mIsSwingSubscriber}`);
        return;
      }
    }
    HiLog.i(TAG, 'swingSubscriber');
    this.checkSubscribeEventAndClear();
    let mCameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    HiLog.i(TAG, 'swingSubscriber mCameraPosition=' + mCameraPosition + ';this.isBackAsFront=' + this.isBackAsFront);
    this.updateEventList(this.subscribeEventList, this.unsubscribeEventList);
    try {
      if (AppStorage.get<boolean>('isBackground')) {
        HiLog.w(TAG, 'The application has exited. No further operation is required.');
        return;
      }
      this.printSwingSubscribeInfo();
      UserEventReport.getInstance().swingFenceSubscribe(getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
      camera.CameraPosition.CAMERA_POSITION_FRONT, CollapsChangeService.getInstance().isShowBackAsFront());
      await swingAbility.on(this.subscribeEventList, this.swingSubscribeCallback).then((result: number) => {
        this.refreshSwingSuscribeResult(result);
      }).catch((err: BusinessError) => {
        this.updateSwingSubscribeFailed();
        HiLog.e(TAG, `Swing register exception errorCode: ${err?.code}`);
      });
    } catch (e) {
      this.updateSwingSubscribeFailed();
      HiLog.e(TAG, `swingSubscriber failed: ${e}`);
    }
  }

  private refreshSwingSuscribeResult(result: number): void {
    // result  1-成功，0--失败
    if (result === 1) {
      HiLog.i(TAG, 'Swing subscriber success.');
      this.mCameraProxy.setSwingSubscribeStatus(true);
      this.mIsSwingSubscriber = true;
      this.isExpandOperation = false;
      this.firstFrameStart = false;
      this.swingDataCount = 0;
      this.swingNoFaceCompareFinish = false;
      this.cameraHalFaceStableCount = 0;
      this.setSwingTimeout();
    } else {
      HiLog.e(TAG, `Swing subscriber failed,result: ${result}`);
    }
  }

  private checkSubscribeEventAndClear(): void {
    if (this.subscribeEventList.length !== 0 || this.unsubscribeEventList.length !== 0) {
      this.subscribeEventList.pop();
      this.unsubscribeEventList.pop();
    }
  }

  private updateSwingSubscribeFailed(): void {
    this.mCameraProxy.setSwingSubscribeStatus(false);
    this.mIsSwingSubscriber = false;
  }

  private printSwingSubscribeInfo(): void {
    this.mCameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK || this.isBackAsFront) {
      HiLog.i(TAG, 'open back camera hal, swing subscriber(FACE_RELATIVE_POSITION_LIGHT).');
    } else {
      HiLog.i(TAG, 'open front camera hal, swing subscriber(REAR_FACE_INTERACTION).');
    }
  }

  // 取消订阅swing
  public async swingUnsubscribe(): Promise<void> {
    if (this.unsubscribeEventList.length === 0 && !this.mIsSwingSubscriber) {
      HiLog.w(TAG, 'swing has Unsubscribe');
      return;
    }
    try {
      HiLog.i(TAG, 'swing Unsubscribe');
      await swingAbility.off(this.unsubscribeEventList, this.swingSubscribeCallback).then((result: number) => {
        if (result === 1) {
          this.checkSubscribeEventAndClear();
          this.mIsSwingSubscriber = false;
          this.mCameraProxy.setSwingSubscribeStatus(false);
          this.swingNoFace = false;
          this.swingMaxFace = null;
          this.cameraHalMaxFace = null;
          this.swingDataCount = 0;
          this.cancelSwingSubscribeTimer();
          this.cancelNoFaceTimer();
          this.swingNoFaceCompareFinish = false;
          this.cameraHalFaceStableCount = 0;
        }
        HiLog.i(TAG, `swing UnSubscriber.result=` + result);
      }).catch((err: BusinessError) => {
        this.mCameraProxy.setSwingSubscribeStatus(false);
        HiLog.e(TAG, `Swing unregister failed,errorMsg: ${err?.code}`);
      });
    } catch (e) {
      this.mIsSwingSubscriber = false;
      this.mCameraProxy.setSwingSubscribeStatus(false);
      HiLog.e(TAG, `swingSubscriber failed: ${e}`);
    }
  }

  // 订阅成功后，3s后自动取消订阅
  private setSwingTimeout(): void {
    this.swingSubscribeTimerId = setTimeout((): void => {
      HiLog.w(TAG, 'after 3s, swing Unsubscribe');
      UserEventReport.getInstance().smartBackSelfieCompareResult(RESULT_TIME_EXCEED);
      this.getBackAsFrontStatus();
      this.compareFaceCalculateMaxFace(this.cameraHalMaxFace, this.swingMaxFace,
        this.isBackAsFront);
      this.swingUnsubscribe();
    }, this.SWING_TIME_OUT);
  }

  private updateEventList(subscribeEventList: swingAbility.SwingEventType[],
    unsubscribeEventList: swingAbility.SwingEventType[]): void {
    if (this.isBackAsFront) {
      subscribeEventList.push(this.facePositionLightEvent); // 前置swing
      unsubscribeEventList.push(this.facePositionLightEvent); // 前置swing
      return;
    }
    this.mCameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    // 相机打开的前置镜头，订阅后置swing
    if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      subscribeEventList.push(this.rearFaceInteractionEvent); // 后置swing
      unsubscribeEventList.push(this.rearFaceInteractionEvent); // 后置swing
    }
    // 相机打开的后置镜头，订阅前置swing
    if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) {
      subscribeEventList.push(this.facePositionLightEvent); // 前置swing
      unsubscribeEventList.push(this.facePositionLightEvent); // 前置swing
    }
  }

  private onForeground(): void {
    this.collapsStatus = CollapsChangeService.getInstance().getCurCollapsStatus();
    this.getBackAsFrontStatus();
    this.updateParameters();
    if (this.collapsStatus !== display.CollapsStatus.COLLAPS_STATUS_EXPANDED) {
      return;
    }
    DeviceMotionManager.getInstance().flipSubscriber();
  }

  private updateParameters(): void {
    this.frontSwingZoomRatio = CameraAppCapability.getInstance().getFrontSwingZoomRatio();
    this.backSwingZoomRatio = CameraAppCapability.getInstance().getBackSwingZoomRatio();
    this.backVideoEisStabilizeRatio = CameraAppCapability.getInstance().getBackVideoEisStabilizeRatio();
    this.frontVideoEisStabilizeRatio = CameraAppCapability.getInstance().getFrontVideoEisStabilizeRatio();
    this.mCurrentMode = getStates().get<ModeType>('modeReducer', 'mode');
  }

  private onBackGround(): void {
    this.getBackAsFrontStatus();
    this.releaseResource();
  }

  private releaseResource(): void {
    this.cancelSwingAndMotionSubscriber();
    this.cancelNoFaceTimer();
    this.cameraHalMaxFace = null;
    this.swingMaxFace = null;
    this.firstFrameStart = false;
    this.isExpandOperation = false;
    this.smartBackSelfieTriggerChangeDisplayMode = false;
    this.swingNoFaceCompareFinish = false;
    this.cameraHalFaceStableCount = 0;
  }

  private cancelNoFaceTimer(): void {
    clearTimeout(this.noFaceWaitTimerId);
  }

  private cancelSwingSubscribeTimer(): void {
    clearTimeout(this.swingSubscribeTimerId);
  }

  // 取消swing 和 motion 订阅
  public cancelSwingAndMotionSubscriber(): void {
    this.swingUnsubscribe();
    DeviceMotionManager.getInstance().flipUnSubscriber();
  }

  private onDestroy(): void {
    this.mSubscriber.destroy();
    this.releaseResource();
  }

  private getBackAsFrontStatus(): void {
    if (CollapsChangeService.getInstance().isShowBackAsFront()) {
      this.isBackAsFront = true;
    } else if (CollapsChangeService.getInstance().isExpanded()) {
      this.isBackAsFront = false;
    } else {
      this.isBackAsFront = false;
    }
  }

  private onLandscapeChanged(data: CollapsData): void {
    this.collapsStatus = data.collapsStatus;
    HiLog.i(TAG, `onLandscapeChanged collapsStatus=${data.collapsStatus}`);
    if (CollapsTypeUtil.isSmallIntSquareExtCollapsScreen()) {
      return;
    }
    if (AppStorage.get<boolean>('isBackground')) {
      HiLog.i(TAG, 'AMS status is background.');
      return;
    }
    if (this.collapsStatus === display.CollapsStatus.COLLAPS_STATUS_HALF_COLLAPSED ||
      this.collapsStatus === display.CollapsStatus.COLLAPS_STATUS_COLLAPSED) {
      this.releaseResource();
      if (this.isBackAsFront) {
        this.exitBackSelfie(true);
        this.getBackAsFrontStatus();
      }
      HiLog.e(TAG, 'Subscription is not required in the current status.');
      return;
    }
    this.isExpandOperation = true;
    if (this.firstFrameStart && this.isExpandOperation) {
      this.swingSubscriber();
      this.isExpandOperation = false;
    }
  }

  private onPreviewFrameStart(data: PreviewFrameStartData): void {
    this.firstFrameStart = data.isPreviewFrameStart;
    if (!this.firstFrameStart) {
      this.swingUnsubscribe();
      DeviceMotionManager.getInstance().flipUnSubscriber();
      return;
    }
    this.smartBackSelfieTriggerChangeDisplayMode = false;
    this.getBackAsFrontStatus();
    this.mCurrentMode = getStates().get<ModeType>('modeReducer', 'mode');
    this.mCameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    if (!DeviceMotionManager.getInstance().isSmartBackSelfieSupport(this.mCurrentMode)) {
      return;
    }
    if (this.firstFrameStart && this.isExpandOperation) {
      this.swingSubscriber();
      this.isExpandOperation = false;
    }
    this.collapsStatus = CollapsChangeService.getInstance().getCurCollapsStatus();
    if (this.firstFrameStart && (this.isBackAsFront || this.collapsStatus === display.CollapsStatus.COLLAPS_STATUS_EXPANDED)) {
      DeviceMotionManager.getInstance().flipSubscriber();
    }
    if (this.collapsStatus === display.CollapsStatus.COLLAPS_STATUS_COLLAPSED) {
      this.firstFrameStart = false;
    }
  }

  // 翻转监听回调
  private onFlipStatusChanged(flipStatus: number): void {
    if (getStates().get<boolean>('settingViewReducer', 'isShowSettingView')) {
      HiLog.w(TAG, 'SettingView is shown,not start smart back selfie check.');
      return;
    }
    if (getStates().get<boolean>('securityCameraReducer', 'thumbnailReminderShow') ||
      getStates().get<boolean>('securityCameraReducer', 'appLockReminderShow')) {
      HiLog.w(TAG, 'thumbnail blank prompt page is shown,not start smart back selfie check.');
      return;
    }
    if ((Date.now() - this.lastFlipTime <= 500)) {
      HiLog.w(TAG, 'The rollover operation is too fast and cannot be completed. Do not repeat the operation.');
      return;
    }
    HiLog.i(TAG, `onreceived flip changed,flipStatus=${flipStatus}`);
    this.getBackAsFrontStatus();
    this.lastFlipTime = Date.now();
    this.swingMaxFace = null;
    this.cameraHalMaxFace = null;
    HiLog.i(TAG, 'swingSubscriber by flip status change.');
    this.swingSubscriber();
  }

  private recoverCamera(data: { cameraPosition: camera.CameraPosition }): void {
    if (this.smartBackSelfieTriggerChangeDisplayMode) {
      return;
    }
    HiLog.i(TAG, 'received click recoverCamera,release smart back selfie subscriber');
    this.releaseResource();
  }

  private updateFaceData(faceMetaData: camera.MetadataObject[]): void {
    // 如果已经取消订阅，后面数据对比不用在做了
    if (!this.mIsSwingSubscriber) {
      return;
    }
    if (faceMetaData.length === 0) {
      if (this.cameraHalMaxFace !== null && this.cameraHalMaxFace !== undefined) {
        HiLog.w(TAG, 'camera hal faceData change to empty.');
      }
      this.cameraHalFaceStableCount = 0;
      this.cameraHalMaxFace = null;
      return;
    }
    if (faceMetaData.length === 1) {
      let boundingBoxArr = faceMetaData[0].boundingBox;
      this.printCameraHalFace(faceMetaData[0]);
      let isGazed: boolean = this.checkFaceIsGazed(faceMetaData[0]);
      if (isGazed) {
        this.effectiveFactDataRecord(boundingBoxArr);
      } else {
        this.cameraHalFaceStableCount = 0;
      }
      return;
    }
    if (faceMetaData.length > 1) {
      let maxRect: camera.Rect = {
        topLeftX: 0,
        topLeftY: 0,
        width: 0,
        height: 0,
      };
      for (let i = 0; i < faceMetaData.length; i++) {
        this.printCameraHalFace(faceMetaData[i]);
        let boundingBoxRect = faceMetaData[i].boundingBox;
        let isGazed: boolean = this.checkFaceIsGazed(faceMetaData[i]);
        if (isGazed && (boundingBoxRect.width * boundingBoxRect.height) > (maxRect.width * maxRect.height)) {
          maxRect = boundingBoxRect;
        }
      }
      this.effectiveFactDataRecord(maxRect);
    }
  }

  private effectiveFactDataRecord(boundingBoxArr: camera.Rect): void {
    if (boundingBoxArr !== undefined && boundingBoxArr.topLeftX !== undefined) {
      this.cameraHalMaxFace = boundingBoxArr;
      if (this.swingNoFaceCompareFinish) {
        this.cameraHalFaceStableCount++;
      }
    }
    if (this.cameraHalFaceStableCount >= 3) {
      HiLog.w(TAG, 'no swing face,cameraHal face has been stable compare.');
      this.compareFaceCalculateMaxFace(this.cameraHalMaxFace, this.swingMaxFace, this.isBackAsFront);
      this.swingNoFaceCompareFinish = false;
      this.cameraHalFaceStableCount = 0;
    }
  }

  private checkFaceIsGazed(cameraMetaData: camera.MetadataObject): boolean {
    if (cameraMetaData === undefined || cameraMetaData.boundingBox === undefined ||
      cameraMetaData.boundingBox.topLeftX === undefined) {
      return false;
    }
    // @ts-ignore
    let pitchAngle: number = cameraMetaData.pitchAngle;
    // @ts-ignore
    let yawAngle: number = cameraMetaData.yawAngle;
    if (pitchAngle === undefined || yawAngle === undefined) {
      return false;
    }
    if (Math.abs(pitchAngle) > this.PITCH_MAX_ANGLE || Math.abs(yawAngle) > this.YAW_MAX_ANGLE) {
      return false;
    }
    return true;
  }

  private printCameraHalFace(cameraMetaData: camera.MetadataObject): void {
    if (cameraMetaData === undefined || cameraMetaData.boundingBox === undefined ||
      cameraMetaData.boundingBox.topLeftX === undefined) {
      HiLog.w(TAG, 'camera hal faceData is empty.');
      return;
    }
    if ((Date.now() - this.lastCameraHalFacePrintTime < 300)) {
      return;
    }
    this.lastCameraHalFacePrintTime = Date.now();
    this.mCameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    let mPosition: string;
    if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) {
      mPosition = 'back';
    } else {
      mPosition = 'front';
    }
    // @ts-ignore
    let pitchAngle: number = cameraMetaData.pitchAngle;
    // @ts-ignore
    let yawAngle: number = cameraMetaData.yawAngle;
    // @ts-ignore
    let rollAngle: number = cameraMetaData.rollAngle;
    HiLog.d(TAG, `${mPosition} camera hal faceData: rect=${JSON.stringify(cameraMetaData.boundingBox)}
    , pitchAngle=${pitchAngle}, yawAngle=${yawAngle}, rollAngle=${rollAngle}`);
  }

  /**
   * 比较camera hal 人脸和swing人脸，确认最终切换的目标
   * @param halFace camera hal上报的人脸
   * @param swingFace swing上报的人脸
   * @param isBackAsFront 是否是后当前状态
   */
  private compareFaceCalculateMaxFace(halFace: camera.Rect, swingFace: camera.Rect, isBackAsFront: boolean): void {
    if (!this.isSwingSubscriber()) {
      return;
    }
    // 没有人脸不需要比较
    if (halFace === null && swingFace === null) {
      HiLog.w(TAG, 'No face, no comparison.');
      this.changePhoneScreenByResult(FaceResult.NO_NEED_CHANGE);
      return;
    }
    if (halFace === null || swingFace === null) {
      this.singleFaceDeal(halFace, swingFace, isBackAsFront);
      return;
    }
    // camera hal识别到人脸，swing识别到人脸 ,比较大小
    if (halFace !== null && swingFace !== null) {
      HiLog.i(TAG, `compareFace,${this.getStringFacePrint(halFace, `hal`)}
      ; ${this.getStringFacePrint(swingFace, `swing`)}`);
      let swingFaceSize = this.calculateSwingFaceSize(swingFace);
      let cameraHalFaceSize = this.calculateCameraHalFaceSize(halFace);
      HiLog.i(TAG, `compareFace,swingFaceSize=${swingFaceSize} ;cameraHalFaceSize=${cameraHalFaceSize}`);

      // 前置camera hal 有人脸，后置swing有人脸,后置swing人脸面积大于0.1，并且前置camerahal人脸/后置swing脸<=0.55，切到后当前
      if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT &&
        (swingFaceSize > this.FACE_MIN_AREA && (cameraHalFaceSize / swingFaceSize <= this.FACE_COMPARE_RATIO))) {
        HiLog.w(TAG, 'back swing face Max,change to backSelf');
        this.changePhoneScreenByResult(FaceResult.TO_BACK_SELFIE);
      }
      if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) {
        // 非后当前下，后置人脸面积小于0.1 不做处理
        if (!isBackAsFront && cameraHalFaceSize < this.FACE_MIN_AREA) {
          this.changePhoneScreenByResult(FaceResult.NO_NEED_CHANGE);
          return;
        }
        // 后当前下，前置人脸面积小于0.1 不做处理
        if (isBackAsFront && swingFaceSize < this.FACE_MIN_AREA) {
          this.changePhoneScreenByResult(FaceResult.NO_NEED_CHANGE);
          return;
        }
        // 非后当前下，后置人脸面积大于0.1 并且 前置人脸/后置人脸 <= 0.55 切到后当前
        if (!isBackAsFront && (swingFaceSize / cameraHalFaceSize <= this.FACE_COMPARE_RATIO)) {
          // 后置 camera hal 大于 前置swing人脸，切到后当前
          this.changePhoneScreenByResult(FaceResult.TO_BACK_SELFIE);
          HiLog.w(TAG, 'back hal face Max,change to backSelf.');
        }
        // 后当前下，前置人脸面积大于0.1 并且 后置人脸/前置人脸 <= 0.55 退出后当前
        if (isBackAsFront && (cameraHalFaceSize / swingFaceSize <= this.FACE_COMPARE_RATIO)) {
          // 后置 camera hal 大于 前置swing人脸，切到后当前
          this.changePhoneScreenByResult(FaceResult.TO_FRONT_EXPANDED);
          HiLog.w(TAG, 'front swing face Max,exit backSelf.');
        }
      }
    }
  }

  private singleFaceDeal(halFace: camera.Rect, swingFace: camera.Rect, isBackAsFront: boolean): void {
    // camera hal识别到人脸，swing未识别到人脸
    if (halFace !== null && swingFace === null) {
      let cameraHalFaceSize = this.calculateCameraHalFaceSize(halFace);
      if (cameraHalFaceSize < this.FACE_MIN_AREA) {
        this.changePhoneScreenByResult(FaceResult.NO_NEED_CHANGE);
        HiLog.w(TAG, `camera hal face size is ${cameraHalFaceSize},no need change.`);
        return;
      }
      HiLog.i(TAG, `compareFace, ${this.getStringFacePrint(halFace, `hal`)}`);
      // 前置camera hal有人脸，后置swing没有人脸
      if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
        this.changePhoneScreenByResult(FaceResult.NO_NEED_CHANGE);
        HiLog.w(TAG, 'No face in swing. No need to switch.');
      }
      // 后置camera hal有人脸，前置swing没有人脸,预期切到副屏后当前
      if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) {
        if (!isBackAsFront) {
          // 后置camera hal有人脸，前置swing没有人脸,预期切到副屏后当前
          this.changePhoneScreenByResult(FaceResult.TO_BACK_SELFIE);
          HiLog.w(TAG, 'back camera hal has face.switch to backSelf');
        } else {
          this.changePhoneScreenByResult(FaceResult.NO_NEED_CHANGE);
          HiLog.w(TAG, 'back camera hal has face.no need switch');
        }
      }
    }
    // camera hal未识别到人脸，swing识别到人脸
    if (halFace === null && swingFace !== null) {
      HiLog.i(TAG, `compareFace, ${this.getStringFacePrint(swingFace, `swing`)}`);
      let swingFaceSize = this.calculateSwingFaceSize(swingFace);
      if (swingFaceSize < this.FACE_MIN_AREA) {
        this.changePhoneScreenByResult(FaceResult.NO_NEED_CHANGE);
        HiLog.w(TAG, `swing face size is ${swingFaceSize},no need change.`);
        return;
      }
      // 前置camera hal 没有人脸，后置swing有人脸
      if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
        // 前置camera hal 没有人脸，后置swing有人脸,预期切到副屏后当前
        this.changePhoneScreenByResult(FaceResult.TO_BACK_SELFIE);
        HiLog.w(TAG, 'back swing has face.switch to backSelf');
      }
      // 后置camera hal 没有人脸，前置swing有人脸
      // 1）后置camera hal 没有人脸，前置swing有人脸； 如果是从桌面打开的，不切换；如果是到展开态切换过来的，也不切换
      if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) {
        if (isBackAsFront) {
          // 2）后置camera hal 没有人脸，前置swing有人脸； 如果是在后当前下，则切到前置大屏
          this.changePhoneScreenByResult(FaceResult.TO_FRONT_EXPANDED);
          HiLog.w(TAG, 'front swing has face.backAsFront status change to front expanded.');
        } else {
          this.changePhoneScreenByResult(FaceResult.NO_NEED_CHANGE);
          HiLog.w(TAG, 'front swing has face.no change');
        }
      }
    }
  }

  private getStringFacePrint(faceRect: camera.Rect, type: string): string {
    if (faceRect === undefined || faceRect.topLeftX === undefined) {
      return `${type} face data error.`;
    }
    return `${type}Face.topLeftX: ${faceRect.topLeftX} , ${type}Face.topLeftY : ${faceRect.topLeftY},
    ${type}Face.width : ${faceRect.width}, ${type}Face.height : ${faceRect.height}`;
  }

  // 计算hal上报的人脸的面积（归一计算）
  private calculateCameraHalFaceSize(face: camera.Rect): number {
    if (!face) {
      return 0;
    }
    if (face === undefined || face.topLeftX === undefined) {
      HiLog.e(TAG, 'calculateCameraHalFaceSize,face data error.');
      return 0;
    }
    let width;
    let height;
    this.currentZoomRatio = getStates().get<number>('zoomReducer', 'zoomRatio');
    let zoomRatio = this.currentZoomRatio;
    if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT && zoomRatio < 1) {
      zoomRatio = 1.0;
    }
    const xComponentWidth = getStates().get<number>('previewReducer', 'xComponentWidth');
    const xComponentHeight = getStates().get<number>('previewReducer', 'xComponentHeight');
    if (OutputOperation.isPanVideoOutput(this.mCurrentMode)) {
      // 录像模式,width=人脸高/zoomRatio*录像EIS防抖裁切比例 ; height =人脸宽/zoomRatio*(4/3)/当前分辨率ratio*录像EIS防抖裁切比例
      let videoEisStabilizeRatio: number = 0;
      if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
        videoEisStabilizeRatio = this.frontVideoEisStabilizeRatio;
      } else {
        videoEisStabilizeRatio = this.backVideoEisStabilizeRatio;
      }
      width = face.height / zoomRatio * videoEisStabilizeRatio;
      height = face.width / zoomRatio * SizeUtil.RATIO_4TO3 /
      SizeUtil.getSizeRatio(xComponentWidth, xComponentHeight) * videoEisStabilizeRatio;
      HiLog.i(TAG, `calculate cameraHal face,videoEisStabilizeRatio = ${videoEisStabilizeRatio}`);
    } else {
      // 拍照模式,width=人脸高/zoomRatio*当前分辨率ratio/(4/3) ; height =人脸宽/zoomRatio
      width = face.height / zoomRatio *
      SizeUtil.getSizeRatio(xComponentWidth, xComponentHeight) / SizeUtil.RATIO_4TO3;
      height = face.width / zoomRatio;
      if (this.isBackAsFront && SizeUtil.isFullScreenSize(xComponentWidth,xComponentHeight)) {
        // 切到后当前，全屏分辨率下时，width=人脸高/zoomRatio ; height =人脸宽/zoomRatio*(4/3)/当前分辨率ratio
        width = face.height / zoomRatio;
        height = face.width / zoomRatio * SizeUtil.RATIO_4TO3 /
        SizeUtil.getSizeRatio(xComponentWidth, xComponentHeight);
      }
    }
    let faceArea = width * height;
    HiLog.i(TAG, `calculate cameraHal face,width = ${width}, height = ${height},
     faceArea = ${faceArea},currentZoomRatio = ${zoomRatio}`);
    return faceArea;
  }

  /**
   * 计算swing上报的人脸的面积
   * （归一计算公式： width = swingReportWidth / 640 / swingZoomRatio ; height = halReportHeight / 480 / swingZoomRatio）
   * @param face face rect
   * @returns face area size.
   */
  private calculateSwingFaceSize(face: camera.Rect): number {
    if (!face) {
      HiLog.e(TAG, 'calculateSwingFaceSize,face data error.');
      return 0;
    }
    if (face === undefined || face.topLeftX === undefined) {
      HiLog.e(TAG, 'calculateSwingFaceSize,face data undefined.');
      return 0;
    }
    let width: number = 0;
    let height: number = 0;
    let swingZoomRatio: number = 0;
    if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      swingZoomRatio = this.backSwingZoomRatio;
    } else {
      swingZoomRatio = this.frontSwingZoomRatio;
    }
    width = face.width / this.SWING_NORMALIZED_WIDTH / swingZoomRatio;
    height = face.height / this.SWING_NORMALIZED_HEIGHT / swingZoomRatio;
    let faceArea = width * height;
    HiLog.i(TAG, `calculate swing face,width = ${width},height = ${height},
    swingZoomRatio = ${swingZoomRatio},faceArea = ${faceArea}`);
    return faceArea;
  }

  private swingCallbackInit(): void {
    this.swingSubscribeCallback = {
      onSwingEvent(data: Record<string, object>): void {
        SwingManager.instance.dealSwintResultCallback(data);
      }
    };
  }

  private dealSwintResultCallback(data: Record<string, object>): void {
    let result = '';
    let xmi;
    let xma;
    let ymi;
    let yma;
    let gazeStatu;
    let faceInteractionTyp;

    if (typeof data === 'object') {
      // 新接口
      Object?.keys(data).forEach(key => {
        let dataKey = key.substring(0, key.length - 1);
        result += dataKey + ':' + data[key] + ';';
        if (FACE_XMI === dataKey) {
          xmi = data[key];
        } else if (FACE_XMA === dataKey) {
          xma = data[key];
        } else if (FACE_YMI === dataKey) {
          ymi = data[key];
        } else if (FACE_YMA === dataKey) {
          yma = data[key];
        } else if (FACE_GAZE_STATU === dataKey) {
          gazeStatu = data[key];
        } else if (FACE_INTERACTION_TYP === dataKey) {
          faceInteractionTyp = data[key];
        }
      });
    } else if (typeof data === 'string') {
      // 兼容老接口
      result = data;
    }
    SwingManager.instance.printSwingResult(result);
    if (xmi === 0 && ymi === 0) {
      SwingManager.instance.noSwingFaceCase();
    }
    if ((xma - xmi) > 0 && (yma - ymi) > 0 && (gazeStatu === 3 || faceInteractionTyp === 3)) {
      SwingManager.instance.cancelNoFaceTimer();
      SwingManager.instance.changeFaceRsultStatus();
    }
    SwingManager.instance.compareFaceWhenFaceStable(xmi, ymi, xma, yma);
  }

  private changeFaceRsultStatus(): void {
    if (SwingManager.instance.swingNoFace) {
      SwingManager.instance.swingNoFace = false;
      SwingManager.instance.swingDataCount = 1;
    } else {
      SwingManager.instance.swingDataCount++;
    }
    this.cameraHalFaceStableCount = 0;
    this.swingNoFaceCompareFinish = false;
  }

  private compareFaceWhenFaceStable(xmi: number, ymi: number, xma: number, yma: number): void {
    if (SwingManager.instance.swingDataCount >= 3) { // swing上报人脸后稳定三帧
      HiLog.i(TAG, 'swing face data has stable');
      SwingManager.instance.swingDataCount = 1;
      SwingManager.instance.getBackAsFrontStatus();
      SwingManager.instance.swingMaxFace = {
        topLeftX: xmi,
        topLeftY: ymi,
        width: xma - xmi,
        height: yma - ymi,
      };
      SwingManager.instance.compareFaceCalculateMaxFace(SwingManager.instance.cameraHalMaxFace,
        SwingManager.instance.swingMaxFace, SwingManager.instance.isBackAsFront);
    }
  }

  private noSwingFaceCase(): void {
    if (!SwingManager.instance.swingNoFace) {
      SwingManager.instance.swingNoFace = true;
      SwingManager.instance.swingDataCount = 1;
      SwingManager.instance.cancelNoFaceTimer();
      SwingManager.instance.addNoFaceCompareTimer();
      SwingManager.instance.swingMaxFace = null;
    } else {
      SwingManager.instance.swingDataCount++;
      SwingManager.instance.cancelNoFaceTimer();
    }
  }

  private printSwingResult(result: string): void {
    if (SwingManager.instance.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) {
      HiLog.i(TAG, `front swing, SwingResult: ${result}`);
    } else {
      HiLog.i(TAG, `back swing, SwingResult: ${result}`);
    }
  }

  private addNoFaceCompareTimer(): void {
    this.noFaceWaitTimerId = setTimeout((): void => {
      this.cancelNoFaceTimer();
      this.compareFaceCalculateMaxFace(this.cameraHalMaxFace,
        this.swingMaxFace, this.isBackAsFront);
      this.swingNoFace = false;
      this.swingDataCount = 1;
      this.swingNoFaceCompareFinish = true;
      HiLog.i(TAG, 'swing no face,time out compare.');
    }, this.NO_SWING_FACE_WAIT_TIME);
  }

  private changePhoneScreenByResult(result: FaceResult): void {
    this.isSmartBackSelfieOpen = getStates().get('settingReducer', 'isSmartBackSelfie');
    if (!this.isSmartBackSelfieOpen) {
      this.cancelSwingAndMotionSubscriber();
      return;
    }
    if (result === FaceResult.TO_BACK_SELFIE || result === FaceResult.TO_FRONT_EXPANDED) {
      this.swingUnsubscribe();
    }
    if (AppStorage.get<boolean>('isBackground')) {
      this.swingUnsubscribe();
      DeviceMotionManager.getInstance().flipUnSubscriber();
      HiLog.w(TAG, 'changePhoneScreenByResult paused,the application has exited.');
      return;
    }
    if (WindowService.getInstance().getWindowStatus() === window.WindowStatusType.FLOATING) {
      HiLog.w(TAG, 'The floating window status does not change.');
      this.swingUnsubscribe();
      DeviceMotionManager.getInstance().flipUnSubscriber();
      return;
    }
    if (result === FaceResult.TO_BACK_SELFIE) {
      this.smartBackSelfieTriggerChangeDisplayMode = true;
      HiLog.i(TAG, 'changePhoneScreenByResult to backSelf.');
      // 实际从大屏切到小屏后置（后当前） 非后当前---> 后当前
      this.enterToBackSelfie();
      this.swingNoFaceCompareFinish = false;
    } else if (result === FaceResult.TO_FRONT_EXPANDED) {
      this.smartBackSelfieTriggerChangeDisplayMode = true;
      HiLog.i(TAG, 'changePhoneScreenByResult to front expanded.');
      // 实际从小屏 后置，切到大屏前置  后当前---> 非后当前
      this.exitBackSelfie(false);
      this.swingNoFaceCompareFinish = false;
    } else {
      HiLog.d(TAG, 'changePhoneScreenByResult ignore,No operation is performed.');
    }
  }

  private exitBackSelfie(isFlodExit: boolean): void {
    HiLog.i(TAG, `exitBackSelfie isFlodExit:${isFlodExit}`);
    UserEventReport.getInstance().smartBackSelfieCompareResult(RESULT_EXIT_SELFIE);
    let currentPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    this.mStoreManager
      .postMessage(execAction('BackSelfieAction', 'switchCameraBackSelfie', BackSelfMode.CHANGE));
    this.mStoreManager
      .postMessage(CameraAction.recoverCamera(camera.CameraPosition.CAMERA_POSITION_FRONT));
    setTimeout(() => {
      if (!isFlodExit) {
        let mode: display.CollapsDisplayMode = display.CollapsDisplayMode.COLLAPS_DISPLAY_MODE_FULL;
        if (CollapsTypeUtil.isSmallIntSquareExtCollapsScreen()) {
          // @ts-ignore
          DisplayService.getInstance().setCollapsDisplayMode(mode, 'backSelfie');
        } else {
          DisplayService.getInstance().setCollapsDisplayMode(mode);
        }
      }
      this.mStoreManager.postMessage(execAction('BackSelfieAction', 'switchCameraBackSelfie', BackSelfMode.CLOSED));
      PreferencesService.getInstance().putPropValue(PersistType.FOR_AWHILE, PropTag.BACK_SELFIE, BackSelfMode.CLOSED);
      this.changeToPortraitMode(currentPosition, camera.CameraPosition.CAMERA_POSITION_FRONT);
      this.mStoreManager.postMessage(execAction('BackSelfieAction', 'processBackAsFrontModeData', true, false));
    }, 400);
  }

  private enterToBackSelfie(): void {
    HiLog.i(TAG, 'enterToBackSelfie');
    UserEventReport.getInstance().smartBackSelfieCompareResult(RESULT_TO_BACK_SELFIE);
    let currentPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    this.mStoreManager
      .postMessage(execAction('BackSelfieAction', 'switchCameraBackSelfie', BackSelfMode.CHANGE));
    this.mStoreManager
      .postMessage(CameraAction.recoverCamera(camera.CameraPosition.CAMERA_POSITION_BACK));
    CollapsChangeService.getInstance().setBackAsFrontMode(true);
    if (CollapsTypeUtil.isSmallIntSquareExtCollapsScreen()) {
      ConnectCapabilityManager.setConnectionCapability(ContextManager.getInstance().getAbilityContext(), true);
    }
    setTimeout(() => {
      let mode: display.CollapsDisplayMode = display.CollapsDisplayMode.COLLAPS_DISPLAY_MODE_MAIN;
      if (CollapsTypeUtil.isSmallIntSquareExtCollapsScreen()) {
        // @ts-ignore
        DisplayService.getInstance().setCollapsDisplayMode(mode, 'backSelfie');
      } else {
        DisplayService.getInstance().setCollapsDisplayMode(mode);
      }
      this.mStoreManager.postMessage(execAction('BackSelfieAction', 'switchCameraBackSelfie', BackSelfMode.OPEN));
      PreferencesService.getInstance().putPropValue(PersistType.FOR_AWHILE, PropTag.BACK_SELFIE, BackSelfMode.OPEN);
      this.changeToPortraitMode(currentPosition, camera.CameraPosition.CAMERA_POSITION_BACK);
      this.mStoreManager.postMessage(execAction('BackSelfieAction', 'processBackAsFrontModeData', true, true));
      if (CollapsTypeUtil.isSmallIntSquareExtCollapsScreen()) {
        WindowService.getInstance().lockXComponentSurface();
        ConnectCapabilityManager.setConnectionCapability(ContextManager.getInstance().getAbilityContext(), false);
      } else {
        // OPEN 状态
        WindowService.getInstance().unlockXComponentSurface();
      }
    }, 400);
    setTimeout(() => {
      // 后续可删除
      CollapsChangeService.getInstance().setBackAsFrontMode(false);
    }, 1400);
  }

  private changeToPortraitMode(currentPosition: camera.CameraPosition, targetPosition: camera.CameraPosition): void {
    if (getStates().get<ModeType>('modeReducer', 'mode') !== ModeType.PORTRAIT ||
      currentPosition !== targetPosition) {
      ModePosWarmStartUtil
        .startWithParams(getStates().get<ModeType>('modeReducer', 'mode'), ModeType.PORTRAIT);
    }
  }

  private onRecordStart(): void {
    this.releaseResource();
  }

  private onRecordStop(): void {
    DeviceMotionManager.getInstance().flipSubscriber();
  }

  public isSwingSubscriber(): boolean {
    return this.mIsSwingSubscriber;
  }

}