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

import lazy { ContextAction } from '../../redux/actions/ContextAction';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { CollaborateControlAction, DialogParams } from './CollaborateControlAction';
// @ts-ignore
import lazy { abilityConnectionManager, Motion } from '../../utils/LazyImportUtil';
import lazy { AbilityConstant, Context } from '@kit.AbilityKit';
import lazy { image } from '@kit.ImageKit';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { camera } from '@kit.CameraKit';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { Action, Data } from '../../redux/actions/Action';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import lazy { CameraAction, CameraRunningState, CameraStartType } from '../../camera/uithread/CameraAction';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { ThumbnailService } from '../../component/thumbnail/ThumbnailService';
import lazy { PersistType, PreferencesService } from '../preferences/PreferencesService';
import lazy { PublicTag } from '../preferences/PropTag';
import lazy { ContextManager } from '../context/ContextManager';
import lazy { ModeTransform } from '../../mode/ModeTransform';
import lazy { OutputType } from '../../function/outputswitcher/OutputType';
import lazy { OutputSwitcher } from '../../function/outputswitcher/OutputSwitcher';
import lazy { App2CameraModeMessage, CameraInputMessage } from '../../camera/DataType';
import lazy { distributedDeviceManager } from '../../utils/LazyImportUtil';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import lazy { simpleStringify } from '../../utils/SimpleStringify';
import lazy { AspectRatioOperation } from '../../function/aspectratio/AspectRatioOperation';
import lazy { OutputOperation } from '../../function/outputswitcher/OutputOperation';
import lazy { VideoResolutionOperation } from '../../function/videoresolution/VideoResolutionOperation';
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { getStates } from '../../redux';
import lazy { BusinessError, commonEventManager, power } from '@kit.BasicServicesKit';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { RecordActionType } from '../../redux/actions/RecordActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { FunctionActionType } from '../../redux/actions/FunctionActionType';
import lazy { CollaborateControlActionType } from '../../redux/actions/CollaborateControlActionType';
import lazy { colorSpaceManager } from '@kit.ArkGraphics2D';
import lazy { CaptureAction } from '../../function/capture/CaptureAction';
import lazy { MechManager, TRACK_STATE } from '../../default/function/collaboration/MechManager';
import lazy { WindowActionType } from '../../redux/actions/WindowActionType';
import lazy { DisplayService } from '../UIAdaptive/DisplayService';
import lazy { CollaborateActionType } from '../../redux/actions/CollaborateActionType';
import lazy { TreasureBoxAction } from '../../component/treasurebox/reduce/TreasureBoxAction';
import lazy { BlurAnimateUtil } from '../../utils/BlurAnimateUtil';

/* instrument ignore file */

const TAG: string = 'CollaborationControlService';
const SERVER_ID: string = 'collaborateCamera';
const EPSILON: number = 0.1;
const DEFAULT_ASPECT: number = 4 / 3;
const DEFAULT_SCALE: number = 0.75;

enum CAMERA_MODE {
  PORTRAIT = 0, // 人像
  PHOTO = 1, // 拍照
  VIDEO = 2, // 录像或录像停止
  VIDEO_START = 3, // 录像启动
  VIDEO_PAUSE = 4, // 录像暂停
  UNSUPPORT = 5, // 不支持的模式
  RECORDING = 6, // 录像中不支持
  PHOTO_BROWSER = 7 // 大图组件显示
}

enum CAMERA_POSITION {
  FRONT = 0, // 前置摄像头
  BACK = 1, // 后置摄像头
  UNSUPPORT = 2 // 不支持的摄像头
}

enum MIRROR_TYPE {
  NO_MIRROR = 0, // 后置非镜像
  MIRROR = 1 // 前置默认镜像
}

enum CAMERA_ROTATION {
  TOP = 0, // 正竖屏
  RIGHT = 90, // 右横屏
  BOTTOM = 180, // 倒竖屏
  LEFT = 270 // 左横屏
}

enum RECORD_ACTION {
  STOP = 0, // 停止录像
  START = 1 // 开始录像
}

enum ZOOM_ACTION {
  ZOOM_OUT = 0, // 缩小
  ZOOM_IN = 1, // 放大
  ZOOM_END = 2 // 结束
}

export enum AUTH_STATE {
  REJECT = 0, // 拒绝
  ACCEPT = 1, // 同意
  TIMEOUT = 2, // 授权超时
  WAIT = 3, // 等待用户授权
}

export enum CONNECT_INIT_STATE {
  UN_INIT = 0, // 未发起连接
  REMOTE = 1, // 遥控拍照发起
  STANDING = 2, // 支架态发起
  COMPLETE = 3 // 连接发起完成
}

enum STREAM_ACTION {
  STOP = 0, // 停止流
  START = 1 // 启动流
}

enum ACTION_RESULT {
  TAKE_PHOTO_ERROR = 0, // 拍照失败
  START_RECORD_ERROR = 1, // 录像开始失败
  STOP_RECORD_ERROR = 2, // 录像停止失败
  SWITCH_CAMERA_ERROR = 3, // 切换前后置摄像头失败
  REQUEST_STREAM_ERROR = 4, // 请求流失败
  CHANGE_MODE_ERROR = 5, // 切换模式失败
  OTHER_ERROR = 6, // 其它错误
  UNAUTHORIZED = 7 // 未授权（场景卡片上点击拍照或录像，但手机侧未授权）
}

enum DIALOG_RESULT {
  DIALOG_OPEN = 0, // 弹窗开启
  DIALOG_CLOSED = 1, // 弹窗开启
}

enum COLLABORATE_STATE {
  IDLE = 0,
  INIT = 1,
  STREAM_REQUEST = 2,
  STREAM_ON = 3,
  STREAM_OFF = 4
}

enum APP_SCENARIOS_ACTION {
  ENTER_REMOTE_CAPTURE = 1,
  CHECK_AUTH = 2
}

export enum CONNECT_TYPE {
  UNDEFINED = -1,
  SPORT_REMOTE = 0,
  SMART_REMOTE = 1,
  INTELLIGENT = 2
}

interface SurfaceSpecificationParam {
  format: string;
  width: string;
  height: string;
  udid: string
}

/**
 * 遥控拍照 服务类
 */
export class CollaborateControlService {
  private static sInstance: CollaborateControlService;
  private mBase: BaseComponent = new BaseComponent();
  private mContext: Context | undefined = undefined;
  private mStoreManager: StoreManager | undefined = StoreManager.getInstance();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mSessionId: number = 0;
  private mIsConnect: boolean = false;
  private mIsAuthorized: boolean = false;
  private mAuthState: AUTH_STATE = AUTH_STATE.WAIT;
  private mLastRecordAction: RECORD_ACTION = RECORD_ACTION.START;
  private mStreamId: number = 0;
  private mSurfaceId: string = null;
  private mSurfaceParam: abilityConnectionManager.SurfaceParam = null;
  private mCollaborateState: number = COLLABORATE_STATE.IDLE;
  private mIsForegroundCall: boolean = false;
  private mCameras: camera.CameraDevice[];
  private mLastStreamAction: STREAM_ACTION = STREAM_ACTION.STOP;
  private mConnectType: CONNECT_TYPE = CONNECT_TYPE.UNDEFINED; // 连接类型：遥控/智感拍照
  private mWatchDeviceName: string;
  private mWatchUuid: string;
  private hasRegisteredCameState: boolean;
  private mConnectInitState: CONNECT_INIT_STATE = CONNECT_INIT_STATE.UN_INIT; // DMS连接发起初始状态，解决对端连接冲突问题
  private mIsWaitStream: boolean; // 是否等待起流
  private mImageSize: image.Size; // 缩略图分辨率
  private mIsLastHighColorSpace: boolean = false; // 相机动态配流前是否10bit流

  public setIsLastHighColorSpace(isLastHighColorSpace: boolean): void {
    this.mIsLastHighColorSpace = isLastHighColorSpace;
  }

  public getIsLastHighColorSpace(): boolean {
    return this.mIsLastHighColorSpace;
  }

  public static getInstance(): CollaborateControlService {
    if (!CollaborateControlService.sInstance) {
      CollaborateControlService.sInstance = new CollaborateControlService();
    }
    return CollaborateControlService.sInstance;
  }

  private registerCameraStateListener(): void {
    if (this.hasRegisteredCameState) {
      return;
    } else {
      this.hasRegisteredCameState = true;
    }
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), this.mBase.hashCode());
    // 监听相机状态变化
    this.mEventBus.on(ActionType.ACTION_DIRECTION_CHANGE, this.onDirectionChange.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.CHANGE_MODE, this.onChangeMode.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SHOW_MORE_PAGE, this.onChangeShowMorePage.bind(this), this.mBase.hashCode());
    // 监听前后置切换，由于切换时要发送镜像消息给手表，直接监听前后置切换时机较早，此时流还未停止，手表流会出现短暂翻转
    this.mEventBus.on(CameraActionType.STARTED, this.onCameraStarted.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.ERROR, this.onCameraActionError.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FunctionActionType.ACTION_CHANGE_FUNCTION_VAL, this.onChangeFunctionVal.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.STARTED, this.onRecordStart.bind(this), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.PAUSED, this.onRecordPause.bind(this), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.RESUMED, this.onRecordResume.bind(this), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.STOPPED, this.onRecordStop.bind(this), this.mBase.hashCode());
    this.mEventBus.on(RecordActionType.ERROR, this.onRecordError.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.STREAM_STARTED, this.onStreamStarted.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.STREAM_END, this.onStreamEnd.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.STREAM_ERROR, this.onStreamError.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.PHOTO_BROWSER, this.onPhotoBrowser.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CollaborateActionType.START, this.onCollaborateStart.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CollaborateActionType.STOP, this.onCollaborateEnd.bind(this), this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.ON_SIZE_CHANGE, this.onWindowSizeChange.bind(this), this.mBase.hashCode());
    HiLog.i(TAG, 'registerCameraStateListener.');
  }

  public isConnected(): boolean {
    return this.mIsConnect;
  }

  public isIntelligentConnect(): boolean {
    return this.mConnectType === CONNECT_TYPE.INTELLIGENT;
  }

  private unRegisterCameraStateListener(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'unRegisterCameraStateListener.');
  }

  public setForegroundCall(isForeground: boolean): void {
    this.mIsForegroundCall = isForeground;
    HiLog.i(TAG, `setForegroundCall ${isForeground}`);
  }

  private static getDefaultPreviewProfile(supportProfiles: camera.Profile[], aspect: number): camera.Profile {
    // 默认选择一个当前比例的最小像素
    let ratio = DEFAULT_ASPECT;
    if (aspect && aspect !== 1) {
      // 不是4:3的默认1:1
      ratio = 1;
    }
    let minIndex = 0;
    for (let i = 1; i < supportProfiles.length; i++) {
      const curRatio = supportProfiles[i].size.width / supportProfiles[i].size.height;
      if (Math.abs(ratio - curRatio) > EPSILON) {
        continue;
      }
      const minPixels = supportProfiles[minIndex].size.width * supportProfiles[minIndex].size.height;
      const curPixels = supportProfiles[i].size.width * supportProfiles[i].size.height;
      if (curPixels < minPixels) {
        minIndex = i;
      }
    }
    HiLog.i(TAG, `getDefaultPreviewProfile.height: ${supportProfiles[minIndex].size.height}.`);
    return supportProfiles[minIndex];
  }

  /**
   * 设置设备连接类型
   *
   * @param connectType 连接类型
   */
  public setRemoteConnectType(connectType: CONNECT_TYPE): void {
    this.mConnectType = connectType;
  }

  /**
   * 订阅MSDP支架态接口
   */
  private registerHolderStatus(): void {
    HiLog.i(TAG, 'subscribe hold state');
    try {
      // @ts-ignore
      Motion.on('remotePhotoStandingDetect', (data: Motion.RemotePhotoStandingStatus) => {
        let result = data === 0 ? 'enter' : 'exit';
        HiLog.i(TAG, `remotePhotoStandingDetect result: ${result}`);
        if (result === 'enter') {
          this.startConnectToDMS();
        }
      });
    } catch (err) {
      HiLog.e(TAG, `subscribeHold err: ${err}`);
    }
  }

  /**
   * 订阅智感拍照事件
   *
   * @param context
   */
  public subscribeIntelligentSensePhoto(context: Context): void {
    HiLog.i(TAG, 'subscribeIntelligentSensePhoto');
    if (this.mIsConnect) {
      return;
    }
    if (!this.checkCameraMode()) {
      HiLog.w(TAG, 'not supported camera mode');
      return;
    }
    this.mContext = context;
    this.registerHolderStatus();
  }

  /**
   * 取消订阅智感拍照
   */
  public unSubscribeHolderState(): void {
    HiLog.i(TAG, 'unSubscribeHolderState');
    MechManager.getInstance().reportUserEvent();
    try {
      // 取消订阅MSDP支架态接口
      // @ts-ignore
      Motion.off('remotePhotoStandingDetect');
    } catch (err) {
      HiLog.e(TAG, `unsubscribe hold err: ${err}`);
    }
  }

  /**
   * 向DMS发起连接请求
   *
   * @param context
   */
  private async startConnectToDMS(): Promise<void> {
    if (this.mIsConnect) {
      return;
    }
    // 设置对端协同应用信息
    const peerInfo: abilityConnectionManager.PeerInfo = {
      deviceId: this.getRemoteDeviceId(),
      bundleName: 'com.ohos.watch.distributedCamera',
      moduleName: 'entry',
      abilityName: 'MainAbility',
      // @ts-ignore
      serviceName: 'collaborateCamera'
    };
    // 设置需要发送流选项
    // @ts-ignore
    const connectOpt: abilityConnectionManager.ConnectOptions = {
      needSendData: false,
      needSendStream: true,
      needReceiveStream: false,
      // @ts-ignore
      startOptions: abilityConnectionManager.StartOptionParams.START_IN_BACKGROUND // 热启动相机参数
    };
    HiLog.i(TAG, `startConnectToDMS mConnectInitState:${this.mConnectInitState}`);
    if (this.mConnectInitState === CONNECT_INIT_STATE.REMOTE) {
      // 遥控拍照已发起，支架态停止发起连接
      HiLog.i(TAG, 'remote already start.');
      return;
    } else if (this.mConnectInitState === CONNECT_INIT_STATE.STANDING) {
      // 上次连接还未结束
      HiLog.i(TAG, 'standing is connecting.');
      return;
    } else {
      this.mConnectInitState = CONNECT_INIT_STATE.STANDING;
    }
    // 创建session会话
    let sessionId: number = -1;
    try {
      // @ts-ignore
      HiLog.i(TAG, `startConnectToDMS, options: ${connectOpt.startOptions}`);
      sessionId =
        abilityConnectionManager.createAbilityConnectionSession(SERVER_ID, this.mContext, peerInfo, connectOpt);
    } catch (error) {
      HiLog.e(TAG, error);
    }
    this.mSessionId = sessionId;
    // 注册会话监听事件
    this.registerSessionEvent(this.mSessionId);
    // 向DMS发起连接
    abilityConnectionManager.connect(this.mSessionId).then(async (connectResult) => {
      if (connectResult.isConnected) {
        HiLog.i(TAG, 'connect accepted');
        this.mConnectType = CONNECT_TYPE.INTELLIGENT; // 进入智感拍照
        this.onConnect(this.mSessionId);
        // 连接成功后向手表发送相机状态
        const cameraState = this.getCameraStateMsg();
        this.sendMessage(cameraState);
        // 授权前初始化监听&同步状态
        this.registerCameraStateListener();
      } else {
        HiLog.e(TAG, `connect rejected, reason: ${connectResult.reason}`);
      }
    }).catch((err) => {
      HiLog.e(TAG, `connect fail error: ${simpleStringify(err)}`);
    }).finally(() => {
      HiLog.i(TAG, 'startConnectToDMS done');
      this.mConnectInitState = CONNECT_INIT_STATE.COMPLETE;
    });
  }

  private getRemoteDeviceId(): string {
    let dmClass: distributedDeviceManager.DeviceManager;
    try {
      dmClass = distributedDeviceManager.createDeviceManager(CommonConstants.BUNDLE_NAME);
    } catch (err) {
      HiLog.e(TAG, `createDeviceManager err: ${err}`);
    }
    if (typeof dmClass === 'object' && dmClass !== null) {
      HiLog.i(TAG, 'getRemoteDeviceId begin');
      let list = dmClass.getAvailableDeviceListSync();
      if (typeof (list) === 'undefined' || typeof (list.length) === 'undefined') {
        HiLog.i(TAG, 'getRemoteDeviceId err: list is null');
        return '';
      }
      if (list.length === 0) {
        HiLog.i(TAG, 'getRemoteDeviceId err: list is empty');
        return '';
      }
      HiLog.i(TAG, `number of devices: ${list.length}`);
      // 弹框选择设备
      for (const deviceInfo of list) {
        if (deviceInfo.deviceType === 'WATCH') {
          HiLog.i(TAG, 'Watch devices exist on the network');
          this.mWatchDeviceName = deviceInfo.deviceName;
          return deviceInfo.networkId;
        }
      }
      return list[0].networkId;
    } else {
      HiLog.i(TAG, 'getRemoteDeviceId err: dmClass is null');
      return '';
    }
  }

  public async handlePermissionGrantResult(isGranted: boolean, isOnce?: boolean): Promise<void> {
    if (this.mConnectType !== CONNECT_TYPE.INTELLIGENT) {
      return;
    }
    HiLog.i(TAG, `handlePermissionGrantResult, isGranted: ${isGranted}, isOnce: ${isOnce}`);
    if (!isOnce && isGranted) {
      // 用户选择始终允许，需要向运动健康写入授权数据
      HiLog.i(TAG, `set permission to health wearservice. granted: ${isGranted}}`);
      if (DeviceInfo.isPc()) {
        return;
      }
      try {
        let ns = await import('../RemoteCapture/RemoteCaptureService');
        ns.RemoteCaptureService.getInstance().setPermissionUuid(this.mWatchUuid, isGranted);
      } catch (err) {
        HiLog.e(TAG, `setPermissionUuid err: ${err}`);
      }
    }
    this.handleAuthState(isGranted ? AUTH_STATE.ACCEPT : AUTH_STATE.REJECT);
    // 权限弹窗同意后，主动起流
    if (isGranted && this.mIsWaitStream) {
      this.requestStream(STREAM_ACTION.START);
    }
  }

  public static getSupportPreviewProfile(
    profile: camera.Profile,
    supportProfiles: camera.Profile[],
    mode: ModeType,
    aspect: number = 1): camera.Profile {
    // 临时方案，人像和拍照模式直接使用手机预览分辨率
    if (mode === ModeType.PHOTO) {
      return profile;
    }
    let resultProfile: camera.Profile = undefined;
    let minPixel = 0;
    let fullMinPixel = 0;
    let fullMinIndex = -1;
    const ratio = profile.size.width / profile.size.height;
    for (let i = 0; i < supportProfiles.length; i++) {
      let curRatio = supportProfiles[i].size.width / supportProfiles[i].size.height;
      let curPixels = supportProfiles[i].size.width * supportProfiles[i].size.height;
      // 先排除画中画的分辨率
      if (curPixels === 640 * 480) {
        continue;
      }
      // 记录1：1最小分辨率备用
      if (Math.abs(1 - curRatio) <= EPSILON) {
        if (fullMinPixel === 0 || curPixels < fullMinPixel) {
          fullMinPixel = curPixels;
          fullMinIndex = i;
        }
      }
      // 比例不匹配的排除
      if (Math.abs(ratio - curRatio) > EPSILON) {
        continue;
      }
      // 找出比例匹配的最小像素
      if (minPixel === 0 || curPixels < minPixel) {
        resultProfile = supportProfiles[i];
        minPixel = curPixels;
      }
    }
    if (aspect === 3 && fullMinIndex !== -1) {
      if (resultProfile && resultProfile.size.width > 1000) {
        resultProfile = supportProfiles[fullMinIndex];
      }
    }
    HiLog.i(TAG, `getSupportPreviewProfile result ${resultProfile?.size.width} ${resultProfile?.size.height}`);
    if (resultProfile) {
      return resultProfile;
    }
    // 比例全都不匹配，返回第一个可用的
    return CollaborateControlService.getDefaultPreviewProfile(supportProfiles, aspect);
  }

  private getAllSupportPreviewProfile(): camera.Profile[] {
    let cameraManager = camera.getCameraManager(ContextManager.getInstance().getUiContext());
    if (!this.mCameras) {
      this.mCameras = cameraManager.getSupportedCameras();
    }
    const mode = getStates().get<ModeType>('modeReducer', 'mode');
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
    const cameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    let device = this.getCameraWithMessage({
      cameraPosition: cameraPosition,
      mode: mode,
      cameraType: camera.CameraType.CAMERA_TYPE_DEFAULT
    });
    const cameraModeMessage: App2CameraModeMessage = { outputType: outputType };
    let sceneMode = ModeTransform.modeType2SceneMode(mode, cameraModeMessage);
    if (device === null || device === undefined || sceneMode === null) {
      HiLog.e(TAG, `params invalid, cameraPosition:${cameraPosition}, mode:${mode}, sceneMode:${sceneMode}`);
      return [];
    }
    let allProfiles = cameraManager.getSupportedOutputCapability(device, sceneMode);
    HiLog.i(TAG, `getAllSupportPreviewProfile ${JSON.stringify(allProfiles.previewProfiles)}`);
    return allProfiles.previewProfiles;
  }

  private getCameraWithMessage(message: CameraInputMessage): camera.CameraDevice | undefined {
    if (!this.mCameras || message === undefined) {
      HiLog.e(TAG, 'cameras or message is null.');
      return undefined;
    }
    HiLog.i(TAG, `getCameraWithMessage: ${message.cameraPosition}, ${this.mCameras.length}.`);
    return this.getCameraWithPosition(message.cameraPosition);
  }

  private getCameraWithType(cameraType: camera.CameraType): camera.CameraDevice | undefined {
    if (!this.mCameras || cameraType === undefined) {
      HiLog.e(TAG, 'cameras or cameraPosition is null.');
      return undefined;
    }
    let cameraPosition: number = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    HiLog.i(TAG, `getCameraWithType, cameraType: ${cameraType}. cameraPosition：${cameraPosition}`);
    // cameradevice 需要同时匹配position和connectionType  因为底层在组网成功后也会把远端的摄像头上报并且无序
    const cameraDevice: camera.CameraDevice | undefined = this.mCameras.find(item => item.cameraPosition ===
      cameraPosition && item.cameraType === cameraType && item.connectionType !==
    camera.ConnectionType.CAMERA_CONNECTION_REMOTE);
    if (cameraDevice === undefined) {
      HiLog.e(TAG, `getCameraWithType no such cameraPosition: ${cameraType}.`);
      return null;
    }
    HiLog.i(TAG, `getCameraWithType, id: ${cameraDevice.cameraId}.`);
    return cameraDevice;
  }

  private getCameraWithPosition(cameraPosition: camera.CameraPosition): camera.CameraDevice | undefined {
    if (!this.mCameras || cameraPosition === undefined) {
      HiLog.e(TAG, 'cameras or cameraPosition is null.');
      return undefined;
    }
    HiLog.i(TAG, `getCameraWithPosition, position: ${cameraPosition}.`);
    // cameradevice 需要同时匹配position和connectionType  因为底层在组网成功后也会把远端的摄像头上报并且无序
    const cameraDevice: camera.CameraDevice | undefined = this.mCameras
      .find(item => item.cameraPosition === cameraPosition &&
        item.connectionType !== camera.ConnectionType.CAMERA_CONNECTION_REMOTE);
    if (cameraDevice === undefined) {
      HiLog.e(TAG, `getCameraWithPosition no such cameraPosition: ${cameraPosition}.`);
      return undefined;
    }
    HiLog.i(TAG, `getCameraWithPosition, connectionType: ${cameraDevice.connectionType}.`);
    return cameraDevice;
  }

  // @ts-ignore
  private setPreviewParam(connectOption: abilityConnectionManager.ConnectOptions): void {
    const param = connectOption.parameters;
    if (!param) {
      HiLog.e(TAG, 'setPreviewParam param is null');
      return;
    }
    // 获取预览流参数，更新状态
    HiLog.begin(TAG, 'getPreviewParamFromWant');
    const allProfiles = this.getAllSupportPreviewProfile();
    const aspect = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue() as number;
    const requestProfile = this.getCameraPreviewProfile();
    const mode = getStates().get<ModeType>('modeReducer', 'mode');
    const profile = CollaborateControlService.getSupportPreviewProfile(requestProfile, allProfiles, mode, aspect);
    HiLog.end(TAG, `getPreviewParamFromWant ${JSON.stringify(profile)}`);
    this.mSurfaceParam = {
      width: profile.size.width,
      height: profile.size.height,
      format: parseInt(param?.format) ?? 1
    };
    // 设置初始化完成状态,此状态后省电模式不生效
    this.mCollaborateState = COLLABORATE_STATE.INIT;
  }

  // @ts-ignore
  onCollaborate(wantParam: Record<string, Object>, context: Context): AbilityConstant.OnCollaborateResult {
    HiLog.i(TAG, 'on collaborate');
    if (this.mIsConnect) {
      // @ts-ignore
      const options = wantParam?.ConnectOption as abilityConnectionManager.ConnectOptions;
      this.setPreviewParam(options);
      HiLog.i(TAG, 'onCollaborate already connect');
      return 0;
    }
    this.mContext = context;
    HiLog.i(TAG, `onCollaborate mConnectInitState:${this.mConnectInitState}`);
    // 支架态已发起连接，遥控拍照停止接受连接
    if (this.mConnectInitState === CONNECT_INIT_STATE.STANDING) {
      HiLog.i(TAG, 'standing already start.');
      return 0;
    } else {
      this.mConnectInitState = CONNECT_INIT_STATE.REMOTE;
    }
    // 创建session会话
    const sessionId = this.createSessionFromWant(wantParam);
    // 注册会话监听事件
    this.registerSessionEvent(sessionId);
    const collabToken = wantParam['ohos.dms.collabToken'] as string;
    // 接受协同请求
    abilityConnectionManager.acceptConnect(sessionId, collabToken).then(() => {
      HiLog.i(TAG, 'acceptConnect success');
    }).catch(() => {
      HiLog.e(TAG, `acceptConnect failed`);
      this.mConnectInitState = CONNECT_INIT_STATE.UN_INIT;
      abilityConnectionManager.destroyAbilityConnectionSession(sessionId);
    });
    return 0;
  }

  createSessionFromWant(collabParam: Record<string, Object>): number {
    // 获取对端协同应用信息
    const peerInfo = collabParam?.PeerInfo as abilityConnectionManager.PeerInfo;
    // 获取连接选项,预览流参数在ConnectOption的parameters中,具体格式需要跟手表协商
    // @ts-ignore
    const options = collabParam?.ConnectOption as abilityConnectionManager.ConnectOptions;
    this.setPreviewParam(options);
    // 设置需要发送流选项
    options.needSendData = false;
    options.needSendStream = true;
    options.needReceiveStream = false;
    let sessionId = -1;
    try {
      sessionId = abilityConnectionManager.createAbilityConnectionSession(SERVER_ID, this.mContext, peerInfo, options);
    } catch (error) {
      HiLog.e(TAG, error);
    }
    return sessionId;
  }

  private destroySession(): void {
    if (this.mSessionId > 0) {
      abilityConnectionManager.destroyAbilityConnectionSession(this.mSessionId);
      this.mSessionId = 0;
    }
  }

  public isInCollaborateState(): boolean {
    return this.mCollaborateState !== COLLABORATE_STATE.IDLE;
  }

  public updateDialogOpenStatus(isAnyDialogOpening: boolean): void {
    if (!this.mIsConnect) {
      return;
    }
    HiLog.i(TAG, `updateDialogOpenStatus, isAnyDialogOpening:${isAnyDialogOpening}`);
    // 弹窗变化，通知手表
    this.sendMessage(`dialog_result:${isAnyDialogOpening ? DIALOG_RESULT.DIALOG_OPEN : DIALOG_RESULT.DIALOG_CLOSED}`);
  }

  public checkIntroLoaded(): boolean {
    const isIntroLoaded =
      PreferencesService.getInstance().getPublicValue(PersistType.FOREVER, PublicTag.IS_INTRO_LOADED, false) as boolean;
    HiLog.i(TAG, `isIntroLoaded: ${isIntroLoaded}`);
    return isIntroLoaded;
  }

  private checkTakePhoto(): boolean {
    // 如果 mPictureWaitRefreshCount 或 mThumbnailWaitRefreshCount不等于0表示在拍照过程
    if (ThumbnailService.getInstance().getPictureWaitRefreshCount() > 2 ||
      ThumbnailService.getInstance().getThumbnailWaitRefreshCount() !== 0) {
      HiLog.i(TAG, 'checkTakePhoto true');
      return true;
    }
    return false;
  }

  private checkSwitching(): boolean {
    // 不等于该值表示正在切换中，不止是模式和前后置切换
    const runningState = getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState');
    HiLog.i(TAG, `checkSwitching ${runningState}`);
    if (!this.mIsForegroundCall) {
      // 后台跳过
      return false;
    }
    if (runningState === CameraRunningState.UNINITIALIZED && this.checkSavePowerMode()) {
      // 省电模式跳过
      return false;
    }
    return runningState !== CameraRunningState.STARTED && runningState !== CameraRunningState.STARTING;
  }

  private checkPhotoBrowser(): boolean {
    return AppStorage.get<boolean>('showPhotoBrowserAction');
  }

  private checkSettingShow(): boolean {
    return getStates().get<boolean>('settingViewReducer', 'isShowSettingView');
  }

  private checkSavePowerMode(): boolean {
    return getStates().get<boolean>('contextReducer', 'isDuringSavePowerMode');
  }

  private checkDialogShowOrStartError(): boolean {
    const isAnyDialogOpening = AppStorage.get<boolean>('isAnyDialogOpening');
    HiLog.i(TAG, `isAnyDialogOpening: ${isAnyDialogOpening}`);
    return isAnyDialogOpening;
  }

  private checkBeautyDialogShow(): boolean {
    const isPortraitBeautyDialogOpen = AppStorage.get<boolean>('isPortraitBeautyDialogOpen');
    HiLog.i(TAG, `isPortraitBeautyDialogOpen: ${isPortraitBeautyDialogOpen}`);
    return isPortraitBeautyDialogOpen;
  }

  public checkGuidanceLoaded(): boolean {
    const isGuidanceLoaded = PreferencesService.getInstance()
      .getPublicValue(PersistType.FOREVER, PublicTag.IS_GUIDANCE_LOADED, false) as boolean;
    HiLog.i(TAG, `isGuidanceLoaded: ${isGuidanceLoaded}`);
    return isGuidanceLoaded;
  }

  private checkIntroduceShow(): boolean {
    return AppStorage.get<boolean>('isModeIntroDialogOpen');
  }

  private checkRecording(): boolean {
    const isRecording = getStates().get<RecordingState>('recordReducer', 'recordingState') !== RecordingState.READY;
    return isRecording;
  }

  private checkCameraMode(): boolean {
    let isSupportMode: boolean = false;
    const cameraMode = getStates().get<ModeType>('modeReducer', 'mode');
    if (this.getCameraMode(cameraMode) !== CAMERA_MODE.UNSUPPORT) {
      isSupportMode = true;
    }
    if (this.isBlackAsFront()) {
      isSupportMode = false;
    }
    HiLog.i(TAG, `checkCameraMode current mode ${cameraMode}`);
    return isSupportMode;
  }

  private canDoMsg(msg: string): boolean {
    if (msg.includes('camera_specification') || msg.includes('app_scenarios')) { // 智感拍照相关等参数，忽略
      return true;
    }
    if (this.checkSwitching() || this.checkPhotoBrowser() || this.checkSettingShow()) {
      HiLog.i(TAG, 'canDoMsg unsupported status');
      return false;
    }
    if (this.checkDialogShowOrStartError()) {
      if (this.checkBeautyDialogShow() && msg.includes('request_stream')) {
        // 美颜弹窗时，仅允许给手表送预览
        return this.checkCameraMode();
      }
      return false;
    }
    return this.checkCameraMode();
  }

  private checkCameraStatus(): boolean {
    if (this.checkIntroduceShow()) {
      // 先关闭人像模式介绍页，否则会影响下面的检查
      this.mStoreManager?.postMessage(CollaborateControlAction.closeDiag());
      HiLog.i(TAG, 'closeDiag');
    }
    // 先检查不支持的模式，不支持直接返回
    if (!this.checkIntroLoaded() || this.checkRecording() || this.checkTakePhoto() || this.checkSwitching() ||
    this.checkPhotoBrowser() || this.checkSettingShow() || !this.checkGuidanceLoaded()) {
      HiLog.i(TAG, 'checkCameraStatus unsupported status');
      return false;
    }
    if (this.checkDialogShowOrStartError()) {
      if (!this.checkBeautyDialogShow()) { // 仅支持美颜弹窗
        HiLog.i(TAG, 'checkCameraStatus unsupported status, dialog is show, not beauty.');
        return false;
      }
    }
    // 检查支持的模式
    if (this.checkCameraMode()) {
      if (this.checkSavePowerMode()) {
        // 关闭省电模式
        this.mStoreManager?.postMessage(CollaborateControlAction.closeSavePowerMode());
        HiLog.i(TAG, 'closeSavePowerMode');
      }
      return true;
    }
    // 其它未知模式，返回不支持
    HiLog.i(TAG, 'checkCameraStatus unknown status');
    return false;
  }

  private getCameraMode(mode: ModeType): number {
    let modeNumber: number = CAMERA_MODE.UNSUPPORT;
    if (mode === ModeType.PHOTO) {
      modeNumber = CAMERA_MODE.PHOTO;
    } else if (mode === ModeType.VIDEO) {
      modeNumber = CAMERA_MODE.VIDEO;
    }
    return modeNumber;
  }

  private getCameraPosition(cameraPos: camera.CameraPosition): number {
    if (cameraPos === camera.CameraPosition.CAMERA_POSITION_BACK) {
      return CAMERA_POSITION.BACK;
    }
    if (cameraPos === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      return CAMERA_POSITION.FRONT;
    }
    return CAMERA_POSITION.UNSUPPORT;
  }

  private getMirrorType(cameraPos: camera.CameraPosition): number {
    if (cameraPos === camera.CameraPosition.CAMERA_POSITION_BACK) {
      return MIRROR_TYPE.MIRROR;
    }
    return MIRROR_TYPE.NO_MIRROR;
  }

  private getAspectRatio(rawAspect?: number): string {
    let aspectRatio: string = 'unknown';
    if (this.mSurfaceParam) {
      aspectRatio = `${this.mSurfaceParam.width}*${this.mSurfaceParam.height}`;
      return aspectRatio;
    }
    let aspect: number = rawAspect;
    if (rawAspect === undefined) {
      aspect = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue() as number;
    }
    if (aspect === 1) {
      aspectRatio = '4*3';
    } else {
      aspectRatio = '1*1';
    }
    return aspectRatio;
  }

  private getCameraStateMsg(mode?: number): string {
    const cameraState = getStates();
    const cameraMode = mode ?? this.getCameraMode(cameraState.get<ModeType>('modeReducer', 'mode'));
    const cameraPos = this.getCameraPosition(cameraState.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'));
    const mirror = this.getMirrorType(cameraState.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'));
    const rotation = this.getRotationFromDirection(cameraState.get<WindowDirection>('contextReducer', 'direction'));
    const aspectRatio = this.getAspectRatio();
    const stateStr = `camera_state:${cameraMode}_${cameraPos}_${mirror}_${rotation}_${aspectRatio}`;
    HiLog.i(TAG, `getCameraStateMsg ${stateStr}`);
    return stateStr;
  }

  private handleVideoMsg(data: number): void {
    const cameraMode = getStates().get<ModeType>('modeReducer', 'mode');
    if (cameraMode !== ModeType.VIDEO) {
      HiLog.i(TAG, `not VIDEO mode, current mode ${cameraMode}`);
      return;
    }
    this.mLastRecordAction = data;
    // 判断状态：1.暂停态启动，发消息给暂停按钮恢复；2.暂停态停止、录制中或未录制启动停止，发消息给shutter按钮
    const recordingState = getStates().get<RecordingState>('recordReducer', 'recordingState');
    if (recordingState === RecordingState.PAUSED && data === RECORD_ACTION.START) {
      this.resume();
      return;
    }
    if ((data === RECORD_ACTION.STOP &&
      (recordingState === RecordingState.RECORDING || recordingState === RecordingState.PAUSED)) ||
      (data === RECORD_ACTION.START && recordingState === RecordingState.READY)) {
      this.video();
    }
  }

  public getSurfaceId(): string {
    HiLog.i(TAG, `getSurfaceId ${this.mSurfaceId}`);
    return this.mSurfaceId;
  }

  public getPreviewProfile(): camera.Profile {
    HiLog.i(TAG, `getPreviewProfile ${this.mCollaborateState}`);
    // 手表请求流之前不起流
    if (this.mCollaborateState < COLLABORATE_STATE.STREAM_REQUEST || !this.checkCameraMode()) {
      return null;
    }
    // format固定为1003，其它格式DMS不支持
    return {
      format: camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP,
      size: {
        width: this.mSurfaceParam.width,
        height: this.mSurfaceParam.height
      }
    };
  }

  private getCameraPreviewProfile(): camera.Profile {
    HiLog.i(TAG, 'getCameraPreviewProfile E.');
    let previewProfile: camera.Profile = undefined;
    const mode = getStates().get<ModeType>('modeReducer', 'mode');
    const cameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    if (OutputOperation.isPanVideoOutput(mode)) {
      const videoResolution = FeatureManager.getInstance()
        .getFunction(FunctionId.VIDEO_RESOLUTION).getValue() as SettingFuncDialogItemIndex;
      const isHdrVivid = false;
      previewProfile = VideoResolutionOperation.getPreviewProfile(videoResolution, cameraPosition, mode, isHdrVivid);
    } else {
      const aspectRatio = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue();
      previewProfile = AspectRatioOperation.getPreviewProfile(aspectRatio, cameraPosition, mode);
    }
    HiLog.i(TAG, `getCameraPreviewProfile profile: ${previewProfile.size.width}-${previewProfile.size.height}.`);
    return previewProfile;
  }

  public updateSurfaceParam(profile: camera.Profile): void {
    if (!this.mIsConnect) {
      return;
    }
    const allProfile = this.getAllSupportPreviewProfile();
    const aspect = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue() as number;
    const mode = getStates().get<ModeType>('modeReducer', 'mode');
    const resultProfile = CollaborateControlService.getSupportPreviewProfile(profile, allProfile, mode, aspect);
    if (!this.mSurfaceParam) {
      this.mSurfaceParam = {
        width: resultProfile.size.width,
        height: resultProfile.size.height,
        format: 1
      };
    } else {
      const sizeChanged: boolean = this.mSurfaceParam.width !== resultProfile.size.width ||
        this.mSurfaceParam.height !== resultProfile.size.height;
      // 先更新尺寸，下面会用到
      this.mSurfaceParam.width = resultProfile.size.width;
      this.mSurfaceParam.height = resultProfile.size.height;
      if (sizeChanged) {
        // 预览流尺寸变化，底层需要销毁流重建
        this.destroyStream();
        if (this.checkCameraMode()) {
          this.sendMessage(`size:${this.getAspectRatio(aspect)}`);
        }
        HiLog.i(TAG, 'updateSurfaceParam size change');
      }
    }
    HiLog.i(TAG, `updateSurfaceParam ${this.mSurfaceParam.width} ${this.mSurfaceParam.height}`);
  }

  /**
   * 处理手表发过来的parameters参数
   *
   * @param param
   * @returns
   */
  private async handleSurfaceParam(message: string): Promise<void> {
    const param = message.split('camera_specification:')[1];
    const surfaceParam: SurfaceSpecificationParam = JSON.parse(param);
    // @ts-ignore
    const options: abilityConnectionManager.ConnectOptions = {
      needSendData: false,
      needSendStream: true,
      needReceiveStream: false,
      parameters: {
        width: surfaceParam?.width,
        height: surfaceParam?.height,
        format: surfaceParam?.format
      }
    };
    this.setPreviewParam(options);
    this.mWatchUuid = surfaceParam?.udid;
    let isGranted = false;
    if (DeviceInfo.isPc()) {
      return;
    }
    try {
      let ns = await import('../RemoteCapture/RemoteCaptureService');
      await ns.RemoteCaptureService.getInstance().init(true);
      isGranted = await ns.RemoteCaptureService.getInstance().verifyPermission(this.mWatchUuid);
    } catch (err) {
      HiLog.e(TAG, `handleSurfaceParam verifyPermission: ${err}`);
    }
    HiLog.i(TAG, `remoteCapture isGranted: ${isGranted}`);
    this.handleAuthState(isGranted ? AUTH_STATE.ACCEPT : AUTH_STATE.WAIT);
  }

  private startStreamInner(): void {
    if (this.mLastStreamAction === STREAM_ACTION.START) {
      HiLog.i(TAG, 'startStreamInner already start');
      return;
    }
    this.mCollaborateState = COLLABORATE_STATE.STREAM_REQUEST;
    this.mStoreManager?.postMessage(CollaborateControlAction.startStream());
    this.mLastStreamAction = STREAM_ACTION.START;
    // 需要启动流之后才能收到FrameStart回调
    HiLog.i(TAG, 'startStreamInner');
  }

  private stopStreamInner(): void {
    if (this.mLastStreamAction === STREAM_ACTION.STOP) {
      HiLog.i(TAG, 'stopStreamInner already stop');
      return;
    }
    // 发送通知给底层停流
    this.mCollaborateState = COLLABORATE_STATE.INIT;
    this.mStoreManager?.postMessage(CollaborateControlAction.stopStream());
    this.mLastStreamAction = STREAM_ACTION.STOP;
    // 此处不要调用协同的stopStream接口停流，否则下次起流报41212000失败
  }

  private requestStream(action: STREAM_ACTION, extra?: string): void {
    HiLog.i(TAG, `requestStream ${action}`);
    this.mIsWaitStream = false;
    if (!this.mIsConnect || !this.mIsAuthorized) {
      return;
    }
    // 检查对端请求流的size与相机当前size是否匹配,-1是无效值
    if (extra && extra !== '-1') {
      const aspect = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue() as number;
      const size = this.getAspectRatio(aspect);
      HiLog.i(TAG, `current size is ${size}`);
      if (size !== extra) {
        HiLog.i(TAG, 'size is not match.');
        return;
      }
    }
    if (action === STREAM_ACTION.START) {
      if (this.mSurfaceId && this.mStreamId > 0) {
        HiLog.i(TAG, 'stream already create');
        this.startStreamInner();
        return;
      }
      HiLog.begin(TAG, 'createStream');
      const streamParam: abilityConnectionManager.StreamParam = { name: 'cameraPreview', role: 0 };
      abilityConnectionManager.createStream(this.mSessionId, streamParam)
        .then(async (streamId) => {
          HiLog.end(TAG, `createStream ${streamId}`);
          this.mStreamId = streamId;
          this.mSurfaceId = abilityConnectionManager.getSurfaceId(streamId, this.mSurfaceParam);
          HiLog.i(TAG, `createStream getSurfaceId ${this.mSurfaceId}`);
          try {
            // 获取到预览参数，开始启动预览流
            abilityConnectionManager.startStream(this.mStreamId);
          } catch (err) {
            HiLog.e(TAG, `startStream fail, err: ${simpleStringify(err)}`);
          }
          this.startStreamInner();
        })
        .catch((err) => {
          HiLog.e(TAG, `createStream error: ${simpleStringify(err)}`);
        });
    } else {
      this.stopStreamInner();
    }
  }

  private handleTakePhoto(param: string): void {
    this.handlePhotoSize(param);
    const cameraMode = getStates().get<ModeType>('modeReducer', 'mode');
    if (cameraMode === ModeType.PHOTO) {
      this.capture();
    }
  }

  private handleChangeMode(mode: number): void {
    if (mode === CAMERA_MODE.PHOTO) {
      this.changeMode(ModeType.PHOTO);
    } else if (mode === CAMERA_MODE.VIDEO) {
      this.changeMode(ModeType.VIDEO);
    } else {
      HiLog.w(TAG, `unknow mode ${mode}`);
    }
  }

  private handleZoom(action: number): void {
    if (action === ZOOM_ACTION.ZOOM_OUT) {
      this.zoomOut();
    } else {
      this.zoomIn();
    }
  }

  /**
   * 处理场景卡片发送消息
   *
   * @param action action
   */
  private handleAppScenarios(action: number): void {
    if (!this.mIsConnect || this.mConnectType !== CONNECT_TYPE.INTELLIGENT) {
      return;
    }
    if (action === APP_SCENARIOS_ACTION.ENTER_REMOTE_CAPTURE) { // 场景卡片进入遥控拍照
      return;
    }
    if (action === APP_SCENARIOS_ACTION.CHECK_AUTH && !this.mIsAuthorized) {
      this.sendMessage(`action_result:${ACTION_RESULT.UNAUTHORIZED}`);
      this.showRemoteCaptureDialog(true);
    }
  }

  private handleMsg(message: string): void {
    if (!this.mIsConnect || !this.mIsAuthorized) {
      if (this.mConnectType !== CONNECT_TYPE.INTELLIGENT) {
        return;
      }
    }
    if (this.checkTakePhoto()) {
      HiLog.i(TAG, 'taking photo, ignore');
      return;
    }
    if (!this.canDoMsg(message)) {
      // 兜底，防止已连接后在手机上操作改变了相机状态并未与手表同步时直接返回模式不支持
      this.sendMessage(`action_result:${ACTION_RESULT.OTHER_ERROR}`);
      return;
    }
    // 收到消息，进行处理
    const params = message?.split(':');
    const command = params[0];
    const data = this.isNumberFormat(params[1]) ? parseInt(params[1]) : -1;
    const extra = params[2];
    switch (command) {
      case 'take_photo':
        if (!this.needShowRemoteCaptureDialog()) {
          this.handleTakePhoto(params[1]);
        }
        break;
      case 'record':
        if (!this.needShowRemoteCaptureDialog('record', data)) {
          this.handleVideoMsg(data);
        }
        break;
      case 'switch_mode':
        this.handleChangeMode(data);
        break;
      case 'switch_shot':
        this.switchCamera(data);
        break;
      case 'zoom':
        this.handleZoom(data);
        break;
      case 'close_camera':
        this.onDisconnect(this.mSessionId, false);
        this.terminateCamera();
        break;
      case 'request_stream':
        if (!this.needShowRemoteCaptureDialog('request_stream', data)) {
          this.requestStream(data, extra);
        }
        break;
      case 'camera_specification':
        this.handleSurfaceParam(message);
        break;
      default:
        this.handleExtendMsg(params);
        break;
    }
  }

  private handleExtendMsg(params: string[]): void {
    switch (params[0]) {
      case 'app_scenarios':
        this.handleAppScenarios(parseInt(params[1]));
        break;
      case 'rotate':
        this.rotate(params[1]);
        break
      case 'rotate_long_press':
        this.rotateLongPress(params[1]);
        break;
      case 'rotate_stop':
        this.stopRotate(parseInt(params[1]));
        break;
      case 'focus':
        this.focus(params[1]);
        break;
      case 'track_enable':
        this.setTrackEnable(params[1]);
        break;
      default:
        HiLog.i(TAG, `unknow msg ${params[0]}`);
        break;
    }
  }

  /**
   * 聚焦命令
   *
   * @param param x_y
   */
  private focus(param: string): void {
    try {
      const coord = param.split('_', 2);
      const x = parseFloat(coord[0]);
      const y = parseFloat(coord[1]);
      MechManager.getInstance().focusExposure(x, y);
    } catch (err) {
      HiLog.e(TAG, `rotate param err:${simpleStringify(err)}`);
    }
  }

  private setTrackEnable(param: string): void {
    try {
      HiLog.i(TAG, `setTrackEnable param:${param}`);
      const trackEnable: boolean = parseInt(param) === TRACK_STATE.ENABLE;
      MechManager.getInstance().setTrackingState(trackEnable);
    } catch (e) {
      HiLog.e(TAG, `setTrackEnable fail, err:${e}`);
    }
  }

  /**
   * 旋转命令
   *
   * @param param yaw_roll_pitch_duration
   */
  private rotate(param: string): void {
    try {
      HiLog.i(TAG, `rotate param:${param}`);
      const rotateParams = param.split('_');
      const yaw = parseFloat(rotateParams[0]);
      const roll = parseFloat(rotateParams[1]);
      const pitch = parseFloat(rotateParams[2]);
      const duration = parseFloat(rotateParams[3]);
      MechManager.getInstance().rotate(yaw, roll, pitch, duration);
    } catch (err) {
      HiLog.e(TAG, `rotate param err:${simpleStringify(err)}`);
    }
  }

  /**
   * 长按旋转指令
   *
   * @param param
   */
  private rotateLongPress(param: string): void {
    try {
      HiLog.i(TAG, `rotate long param:${param}`);
      const rotateParams = param.split('_');
      const yawSpeed = parseFloat(rotateParams[0]);
      const rollSpeed = parseFloat(rotateParams[1]);
      const pitchSpeed = parseFloat(rotateParams[2]);
      const duration = parseFloat(rotateParams[3]);
      MechManager.getInstance().rotateBySpeed(yawSpeed, rollSpeed, pitchSpeed, duration);
    } catch (e) {
      HiLog.e(TAG, `rotate long param err:${simpleStringify(e)}`);
    }
  }

  /**
   * 停止旋转指令
   *
   * @param params
   */
  private stopRotate(data: number): void {
    if (data === 1) {
      MechManager.getInstance().stopRotate();
    }
  }

  /**
   * 发送云台智能跟踪状态
   *
   * @param trackState
   */
  public sendMechTrackState(trackState: TRACK_STATE): void {
    HiLog.i(TAG, `sendMechTrackState: ${trackState}`);
    this.sendMessage(`track_state:${trackState}`);
  }

  /**
   * 向手表发送支架状态
   *
   * @param mechState
   */
  public sendMechState(mechState: string): void {
    HiLog.d(TAG, `sendMechState, ${JSON.stringify(mechState)}`);
    this.sendMessage(mechState);
  }

  /**
   * 向手表发送限位状态
   *
   * @param limitState
   */
  public sendLimitState(limitState: string): void {
    HiLog.d(TAG, `sendMechState, ${JSON.stringify(limitState)}`);
    this.sendMessage(limitState);
  }

  private terminateCamera(): void {
    HiLog.i(TAG, 'terminateCamera');
    ContextManager.getInstance().getUiContext().terminateSelf().then(() => {
      HiLog.i(TAG, 'terminateSelf success');
    });
  }

  private handlePhotoSize(param: string): void {
    try {
      const regex = /^\d+_(\d+)\*(\d+)$/;
      const match = param.match(regex);
      if (match) {
        this.mImageSize = {
          width: parseInt(match[1]),
          height: parseInt(match[2])
        };
        HiLog.i(TAG, `image size width:${this.mImageSize.width}, height:${this.mImageSize.height}`);
      }
    } catch (err) {
      HiLog.e(TAG, `handleData err: ${simpleStringify(err)}`);
    }
  }

  /**
   * 判断param是否为纯数字格式
   *
   * @param param
   * @returns
   */
  private isNumberFormat(param: string): boolean {
    return /^-?[0-9]+$/.test(param);
  }

  /**
   * 检查拍照权限，智感拍照时需要先授权
   *
   * @returns 是否需要展示权限弹窗
   */
  private needShowRemoteCaptureDialog(msg?: string, data?: number): boolean {
    // 停止流、录像结束不校验权限，否则会反复拉起遥控拍照APP
    if ((msg === 'request_stream' && data === STREAM_ACTION.STOP) ||
      (msg === 'record' && data === RECORD_ACTION.STOP)) {
      return false;
    }
    HiLog.i(TAG, `needShowRemoteCaptureDialog ConnectType: ${this.mConnectType}, authorized: ${this.mIsAuthorized}`);
    if (this.mConnectType === CONNECT_TYPE.INTELLIGENT && !this.mIsAuthorized) {
      // 手表请求流前校验权限，并给手表发送提醒
      this.sendMessage(`action_result:${ACTION_RESULT.UNAUTHORIZED}`);
      this.showRemoteCaptureDialog(true);
      this.mIsWaitStream = msg === 'request_stream';
      return true;
    }
    return false;
  }

  private showRemoteCaptureDialog(show: boolean): void {
    const dialogParams: DialogParams = {
      show: show,
      deviceName: this.mWatchDeviceName,
      isCustomStyle: false
    };
    this.mStoreManager?.postMessage(CollaborateControlAction.showCommonCaptureDialog(dialogParams));
  }

  public onCaptureAborted(): void {
    HiLog.i(TAG, 'onCaptureAborted');
    if (!this.mIsConnect || !this.mIsAuthorized) {
      return;
    }
    this.sendMessage(`action_result:${ACTION_RESULT.TAKE_PHOTO_ERROR}`);
  }

  private onConnect(sessionId: number): void {
    if (this.mIsConnect) {
      return;
    }
    HiLog.i(TAG, 'onConnect');
    // 连接成功
    this.mIsConnect = true;
    this.mConnectInitState = CONNECT_INIT_STATE.COMPLETE;
    this.mSessionId = sessionId;
    MechManager.getInstance().subscribe();
    if (getStates().get<boolean>('contextReducer', 'isDuringSavePowerMode')) {
      // 如果遥控拍照连接成功时，处于省电模式，通知UI退出省电模式。后续省电模式下不允许进入遥控拍照，此处同步删掉
      this.mStoreManager?.postMessage(CaptureAction.exitSavePowerModeEvent());
    }
    // 判断用户是否同意隐私协议
    if (!this.checkIntroLoaded() || !this.checkGuidanceLoaded()) {
      this.sendMessage(`authorize:${AUTH_STATE.TIMEOUT}`);
      this.onDisconnect(sessionId, false);
      return;
    }
    if (this.checkDialogShowOrStartError()) {
      this.sendMessage(`dialog_result:${DIALOG_RESULT.DIALOG_OPEN}`);
    }
    if (this.mAuthState === AUTH_STATE.WAIT) {
      HiLog.i(TAG, 'wait for user auth');
      this.sendMessage(`authorize:${AUTH_STATE.WAIT}`);
      return;
    }
    this.handleAuthInner();
  }

  private onDisconnect(sessionId: number, fromSink: boolean): void {
    this.mConnectInitState = CONNECT_INIT_STATE.COMPLETE;
    if (!this.mIsConnect) {
      this.destroySession();
      return;
    }
    HiLog.i(TAG, 'onDisconnect');
    // 此处需要判断是否授权
    if (this.mIsAuthorized) {
      // 相机主动断连，先给手表发消息
      if (fromSink) {
        this.sendMessage('close_camera:0');
      }
      // 断开连接，释放资源
      this.unRegisterCameraStateListener();
      this.unRegisterSessionEvent(sessionId);
      // 清理预览流
      if (this.mStreamId > 0) {
        this.mStoreManager?.postMessage(CollaborateControlAction.stopStream());
      }
      this.mStoreManager?.postMessage(CollaborateControlAction.sourceDisconnect());
    }
    // 重置省电模式定时器
    this.mStoreManager?.postMessage(ContextAction.resetSaveModeTimer());
    this.hasRegisteredCameState = false;
    this.mIsWaitStream = false;
    this.showRemoteCaptureDialog(false);
    this.publishCloseDialogEvent();
    MechManager.getInstance().unSubscribe();
    this.mImageSize = null;
    this.mIsConnect = false;
    this.mConnectType = CONNECT_TYPE.UNDEFINED;
    this.mStreamId = 0;
    this.mSurfaceId = null;
    this.mSurfaceParam = null;
    this.mIsAuthorized = false;
    this.mAuthState = AUTH_STATE.WAIT;
    this.mLastRecordAction = RECORD_ACTION.START;
    try {
      abilityConnectionManager.disconnect(sessionId);
      abilityConnectionManager.destroyAbilityConnectionSession(sessionId);
    } catch (err) {
      HiLog.e(TAG, `disconnect failed: ${JSON.stringify(err)}`);
    }
    this.mSessionId = 0;
    this.mCollaborateState = COLLABORATE_STATE.IDLE;
    this.mLastStreamAction = STREAM_ACTION.STOP;
  }

  private destroyStream(): void {
    if (this.mStreamId > 0) {
      HiLog.begin(TAG, `destroyStream`);
      try {
        abilityConnectionManager.stopStream(this.mStreamId);
      } catch (e) {
        HiLog.e(TAG, `stopStream err: ${simpleStringify(e)}`);
      }
      try {
        abilityConnectionManager.destroyStream(this.mStreamId);
      } catch (e) {
        HiLog.e(TAG, `destroyStream err: ${simpleStringify(e)}`);
      }
      this.mStreamId = 0;
      this.mCollaborateState = COLLABORATE_STATE.INIT;
      this.mLastStreamAction = STREAM_ACTION.STOP;
      HiLog.end(TAG, `destroyStream`);
    }
  }

  private registerSessionEvent(sessionId: number): void {
    abilityConnectionManager.on('connect', sessionId, (callbackInfo) => {
      this.onConnect(sessionId);
    });

    abilityConnectionManager.on('disconnect', sessionId, (callbackInfo) => {
      this.onDisconnect(sessionId, false);
    });

    abilityConnectionManager.on('receiveMessage', sessionId, (callbackInfo) => {
      HiLog.i(TAG, `receive message is ${callbackInfo.msg}`);
      this.handleMsg(callbackInfo.msg);
    });
  }

  private unRegisterSessionEvent(sessionId: number): void {
    abilityConnectionManager.off('connect', sessionId);
    abilityConnectionManager.off('disconnect', sessionId);
    abilityConnectionManager.off('receiveMessage', sessionId);
  }

  public async sendImage(pixelMap: image.PixelMap): Promise<void> {
    if (!this.mIsConnect || !this.mIsAuthorized) {
      HiLog.i(TAG, 'sendImage fail, not connect or unauthorized');
      return;
    }
    HiLog.i(TAG, 'sendImage start');
    const thumbnail = await this.clonePixelMap(pixelMap);
    try {
      abilityConnectionManager.sendImage(this.mSessionId, thumbnail).then(() => {
        thumbnail?.release();
        HiLog.i(TAG, 'sendImage done');
      });
    } catch (err) {
      HiLog.e(TAG, `sendImage err: ${simpleStringify(err)}`);
      thumbnail?.release();
    }
  }

  private async clonePixelMap(pixelMap: image.PixelMap): Promise<image.PixelMap> {
    const imageInfo = pixelMap.getImageInfoSync();
    const imageSize = imageInfo?.size;
    const isHdr = imageInfo?.isHdr;
    HiLog.i(TAG,
      `pixelMap width:${imageSize?.width},height:${imageSize?.height},colorspace:${pixelMap?.getColorSpace().getColorSpaceName()}`);
    const buffer = new ArrayBuffer(pixelMap.getPixelBytesNumber());
    pixelMap.readPixelsToBufferSync(buffer);
    const options: image.InitializationOptions = {
      editable: true,
      srcPixelFormat: imageInfo.pixelFormat,
      pixelFormat: imageInfo.pixelFormat,
      size: imageInfo.size
    };
    let clonePixelMap: image.PixelMap = undefined;
    try {
      if (isHdr) {
        clonePixelMap = image.createPixelMapSync(options);
        clonePixelMap?.writeBufferToPixelsSync(buffer);
        let colorSpaceName = colorSpaceManager.ColorSpace.BT2020_HLG;
        let csm: colorSpaceManager.ColorSpaceManager = colorSpaceManager.create(colorSpaceName);
        clonePixelMap?.setColorSpace(csm);
        await clonePixelMap.toSdr();
      } else {
        clonePixelMap = image.createPixelMapSync(buffer, options);
        clonePixelMap?.setColorSpace(pixelMap.getColorSpace());
      }
      clonePixelMap?.setMemoryNameSync(TAG);
    } catch (e) {
      HiLog.e(TAG, `clonePixelMap setMemoryNameSync error:${simpleStringify(e)}`);
    }
    if (clonePixelMap === undefined) {
      HiLog.w(TAG, 'clonePixelMap is undefined');
    }
    const cloneSize = clonePixelMap?.getImageInfoSync().size;
    const widthScale = this.mImageSize === null ? DEFAULT_SCALE : this.mImageSize.width / cloneSize.width;
    const heightScale = this.mImageSize === null ? DEFAULT_SCALE : this.mImageSize.height / cloneSize.height;
    clonePixelMap?.scaleSync(widthScale, heightScale);
    const cloneImageSize = clonePixelMap?.getImageInfoSync()?.size;
    HiLog.i(TAG,
      `clonePixelMap width:${cloneImageSize?.width},height:${cloneImageSize?.height},colorspace:${clonePixelMap?.getColorSpace().getColorSpaceName()}`);
    return clonePixelMap;
  }

  private sendMessage(msg: string): void {
    if (!this.mIsConnect) {
      return;
    }
    abilityConnectionManager.sendMessage(this.mSessionId, msg);
    HiLog.i(TAG, `sendMessage ${msg}`);
  }

  private handleAuthInner(): void {
    if (!this.mIsConnect) {
      return;
    }
    // 发送授权状态
    this.sendMessage(`authorize:${this.mAuthState}`);
    if (!this.mIsAuthorized) {
      return;
    }
    // 检查相机当前状态，不支持的状态直接返回
    let cameraMode = undefined;
    if (!this.checkCameraStatus()) {
      cameraMode = this.checkRecording() ? CAMERA_MODE.RECORDING : CAMERA_MODE.UNSUPPORT;
    }
    // 授权通过，初始化监听&同步状态
    this.registerCameraStateListener();
    const stateStr = this.getCameraStateMsg(cameraMode);
    this.sendMessage(stateStr);
    // 通知页面弹出提示，如果相机处于后台需延迟，等待相机进入前台后再提示
    if (!this.mIsForegroundCall) {
      setTimeout(() => {
        this.mStoreManager?.postMessage(CollaborateControlAction.sourceConnect());
      }, 1000);
    } else {
      this.mStoreManager?.postMessage(CollaborateControlAction.sourceConnect());
    }
  }

  public resetAuthState(): void {
    this.mAuthState = AUTH_STATE.WAIT;
    this.mIsAuthorized = false;
    HiLog.i(TAG, 'resetAuthState');
  }

  // 授权结果通知处理
  public handleAuthState(state: AUTH_STATE): void {
    // 先保存本次授权状态，可能授权比onconnect早
    HiLog.i(TAG, `handleAuthState ${state}`);
    if (this.mIsAuthorized) {
      return;
    }
    this.mAuthState = state;
    this.mIsAuthorized = state === AUTH_STATE.ACCEPT;
    this.handleAuthInner();
  }

  private capture(): void {
    HiLog.i(TAG, 'capture');
    if (this.mConnectType === CONNECT_TYPE.INTELLIGENT) {
    }
    this.mStoreManager?.postMessage(CollaborateControlAction.capture());
  }

  private video(): void {
    HiLog.i(TAG, 'video');
    // 更多页时手表录像，相机退出更多页
    if (getStates().get<boolean>('modeReducer', 'isShowMorePage')) {
      StoreManager.getInstance().postMessage(Action.showMoreModePage(false));
    }
    this.mStoreManager?.postMessage(CollaborateControlAction.video());
  }

  private resume(): void {
    HiLog.i(TAG, 'resume');
    this.mStoreManager?.postMessage(CollaborateControlAction.resume());
  }

  private changeMode(mode: ModeType): void {
    HiLog.i(TAG, `changeMode to ${mode}`);
    this.mStoreManager?.postMessage(Action.showMoreModePage(false));
    const oldMode = getStates().get<ModeType>('modeReducer', 'mode');
    if (oldMode === mode) {
      return;
    }
    BlurAnimateUtil.generatePixelMapFromSurface();
    this.mStoreManager?.postMessage(CameraAction.changeMode(mode));
    this.mStoreManager?.postMessage(Action.updateXComponentShot(oldMode, mode));
  }

  private switchCamera(cameraPosition: number): void {
    if (cameraPosition ===
    this.getCameraPosition(getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition'))) {
      HiLog.i(TAG, 'switchCamera no change');
      return;
    }
    HiLog.i(TAG, 'switchCamera');
    if (cameraPosition === 0) {
      const isStatusM = false;
      const isBlackAsFront = this.isBlackAsFront();
      if (isStatusM || isBlackAsFront) {
        HiLog.i(TAG, `isStatusM: ${isStatusM}, isBlackAsFront: ${isBlackAsFront}`);
        this.sendMessage(`mode:${CAMERA_MODE.UNSUPPORT}`);
        return;
      }
    }
    this.mStoreManager?.postMessage(CollaborateControlAction.switchCamera());
  }

  private isBlackAsFront(): boolean {
    return false;
  }

  private zoomIn(): void {
    HiLog.i(TAG, 'zoomIn');
    this.mStoreManager?.postMessage(CollaborateControlAction.zoomIn());
  }

  private zoomOut(): void {
    HiLog.i(TAG, 'zoomOut');
    this.mStoreManager?.postMessage(CollaborateControlAction.zoomOut());
  }

  private onForeground(): void {
    HiLog.i(TAG, 'onForeground');
  }

  private onBackground(): void {
    HiLog.i(TAG, 'onBackground');
    this.onDisconnect(this.mSessionId, true);
  }

  private getRotationFromDirection(direction: WindowDirection): number {
    let rotation: number = CAMERA_ROTATION.TOP;
    if (direction === WindowDirection.TOP) {
      rotation = CAMERA_ROTATION.TOP;
    } else if (direction === WindowDirection.BOTTOM) {
      rotation = CAMERA_ROTATION.BOTTOM;
    } else if (direction === WindowDirection.LEFT) {
      rotation = CAMERA_ROTATION.LEFT;
    } else if (direction === WindowDirection.RIGHT) {
      rotation = CAMERA_ROTATION.RIGHT;
    }
    return rotation;
  }

  private onDirectionChange(data: { direction: number }): void {
    HiLog.i(TAG, `onDirectionChange ${data.direction}`);
    if (!this.mIsConnect) {
      return;
    }
    const isLockOrientation: boolean = getStates().get<string>('windowReducer', 'rotationStatus') === '0'; //锁定方向
    const isStatusM = false;
    const isStatusG = false;
    if (!isLockOrientation && (isStatusM || isStatusG)) {
      HiLog.i(TAG, `isLockOrientation: ${isLockOrientation}, isStatusM:${isStatusM}, isStatusG:${isStatusG}`);
      return;
    }
    const rotation = this.getRotationFromDirection(data.direction);
    this.sendMessage(`rotation:${rotation}`);
  }

  private onChangeMode(data: { mode: ModeType }): void {
    HiLog.i(TAG, `onChangeMode ${data.mode}`);
    if (!this.mIsConnect) {
      return;
    }
    this.sendMessage(`mode:${this.getCameraMode(data.mode)}`);
  }

  private onChangeShowMorePage(data: { isShowMorePage: boolean }): void {
    if (!this.mIsConnect) {
      return;
    }
    this.sendMessage(`showMorePage:${data.isShowMorePage ? 1 : 0}`);
  }

  private onCameraStarted(data: { type: CameraStartType }): void {
    HiLog.i(TAG, `onCameraStarted ${data.type}`);
    if (!this.mIsConnect) {
      return;
    }
    if (data.type !== CameraStartType.SWITCH_CAMERA && data.type !== CameraStartType.SWITCH_CAMERA_CHANGE_MODE) {
      return;
    }
    const cameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    const mirror = this.getMirrorType(cameraPosition);
    if (data.type === CameraStartType.SWITCH_CAMERA) {
      this.sendMessage(`camera_shot:${this.getCameraPosition(cameraPosition)}_${mirror}`);
    }
    if (data.type === CameraStartType.SWITCH_CAMERA_CHANGE_MODE) {
      const mode = getStates().get<ModeType>('modeReducer', 'mode');
      this.sendMessage(`camera_shot:${this.getCameraPosition(cameraPosition)}_${mirror}`);
      this.sendMessage(`mode:${this.getCameraMode(mode)}`);
    }
  }

  private onSwitchCameraChangeMode(data: {
    cameraPosition: camera.CameraPosition,
    mode: ModeType
  }): void {
    HiLog.i(TAG, `onSwitchCameraChangeMode pos:${data.cameraPosition}, mode:${data.mode}`);
    if (!this.mIsConnect) {
      return;
    }
    const mirror = this.getMirrorType(data.cameraPosition);
    this.sendMessage(`camera_shot:${this.getCameraPosition(data.cameraPosition)}_${mirror}`);
    this.sendMessage(`mode:${this.getCameraMode(data.mode)}`);
  }

  private onCameraActionError(data: { code: number, msg: string }): void {
    HiLog.i(TAG, `onCameraActionError ${data.code} ${data.msg}`);
    if (!this.mIsConnect) {
      return;
    }
    // 很多错误会上报到这里,暂时无法判断是切换模式或摄像头的错误
    // 异常信息abilityConnectionManager.sendMessage(this.mSessionId, `action_result:${ACTION_RESULT.CHANGE_MODE_ERROR}`);
  }

  private onChangeFunctionVal(data: Data): void {
    if (!this.mIsConnect) {
      return;
    }
    if (data?.id === FunctionId.ASPECT_RATIO) {
      const aspectRatio = data?.value;
      HiLog.i(TAG, `onAspectRatioChange ${aspectRatio}`);
      // 不在此处发送比例变化消息，在预览尺寸实际变化时发送
    }
  }

  private onRecordStart(): void {
    HiLog.i(TAG, 'onRecordStart');
    if (!this.mIsConnect) {
      return;
    }
    this.sendMessage(`mode:${CAMERA_MODE.VIDEO_START}`);
    // 录像启动成功，预设下次动作为停止
    this.mLastRecordAction = RECORD_ACTION.STOP;
  }

  private onRecordPause(): void {
    HiLog.i(TAG, 'onRecordPause');
    if (!this.mIsConnect) {
      return;
    }
    const recordTime = AppStorage.get('recordingTime');
    if (recordTime) {
      this.sendMessage(`mode:${CAMERA_MODE.VIDEO_PAUSE}:${recordTime}`);
    } else {
      this.sendMessage(`mode:${CAMERA_MODE.VIDEO_PAUSE}`);
    }
    this.mLastRecordAction = RECORD_ACTION.START;
  }

  private onRecordResume(): void {
    HiLog.i(TAG, 'onRecordResume');
    if (!this.mIsConnect) {
      return;
    }
    this.sendMessage(`mode:${CAMERA_MODE.VIDEO_START}`);
    this.mLastRecordAction = RECORD_ACTION.STOP;
  }

  private onRecordStop(): void {
    HiLog.i(TAG, 'onRecordStop');
    if (!this.mIsConnect) {
      return;
    }
    this.sendMessage(`mode:${CAMERA_MODE.VIDEO}`);
    this.mLastRecordAction = RECORD_ACTION.START;
    // 拍照模式长按右滑录像，结束后通知手表更新模式
    const mode = getStates().get<ModeType>('modeReducer', 'mode');
    if (mode === ModeType.PHOTO) {
      this.sendMessage(`mode:${this.getCameraMode(mode)}`);
    }
  }

  private onRecordError(data: { code: number, msg: string }): void {
    HiLog.i(TAG, `onRecordError ${data.code} ${data.msg}`);
    if (!this.mIsConnect) {
      return;
    }
    let result = ACTION_RESULT.START_RECORD_ERROR;
    if (this.mLastRecordAction === RECORD_ACTION.STOP) {
      result = ACTION_RESULT.STOP_RECORD_ERROR;
    }
    this.sendMessage(`action_result:${result}`);
  }

  private onStreamStarted(): void {
    HiLog.i(TAG, 'onStreamStarted');
    if (!this.mIsConnect) {
      return;
    }
    if (!power.isActive()) {
      // 熄屏状态，唤醒屏幕
      power.wakeup('camera wakeup');
      HiLog.i(TAG, 'power wakeup');
    }
    this.mImageSize = null;
    this.sendMessage('frame_start:1');
  }

  private onStreamEnd(): void {
    HiLog.i(TAG, 'onStreamEnd');
    if (!this.mIsConnect) {
      return;
    }
    // 切模式会走到这里，并且不再有onStreamStarted回调，所以不能用该状态判断预览流状态
  }

  private onStreamError(): void {
    HiLog.i(TAG, 'onStreamError');
    if (!this.mIsConnect) {
      return;
    }
    this.sendMessage(`action_result:${ACTION_RESULT.REQUEST_STREAM_ERROR}`);
  }

  private onPhotoBrowser(data: { isShow: boolean }): void {
    HiLog.i(TAG, `onPhotoBrowser ${data.isShow}`);
    if (!this.mIsConnect) {
      return;
    }
    const mode =
      data.isShow ? CAMERA_MODE.PHOTO_BROWSER : this.getCameraMode(getStates().get<ModeType>('modeReducer', 'mode'));
    this.sendMessage(`mode:${mode}`);
    if (data.isShow) {
      this.mSurfaceParam = null;
      this.mSurfaceId = null;
    }
  }

  private onCollaborateStart(): void {
    HiLog.i(TAG, 'onCollaborateStart');
    if (!this.mIsConnect) {
      return;
    }
    this.sendMessage('collaborate_status:1');
  }

  private onCollaborateEnd(): void {
    HiLog.i(TAG, 'onCollaborateEnd');
    if (!this.mIsConnect) {
      return;
    }
    this.sendMessage('collaborate_status:0');
  }

  private async publishCloseDialogEvent(): Promise<void> {
    commonEventManager.publish('close_dialog', (err: BusinessError) => {
      if (err) {
        HiLog.e(TAG, `publish err ${err?.code}`);
      } else {
        HiLog.i(TAG, `publish succuss`);
      }
    })
  }

  private onWindowSizeChange(): void {
    HiLog.i(TAG, 'onWindowSizeChange');
    const isStatusM = false;
    const isStatusG = false;
    const isLockOrientation: boolean = getStates().get<string>('windowReducer', 'rotationStatus') === '0'; //锁定方向
    if (isLockOrientation) {
      return;
    }
    const direction: number = DisplayService.getInstance().getDisplay().rotation;
    let rotation: number = 0;
    if (isStatusM || isStatusG) {
      switch (direction) {
        case 0:
          rotation = CAMERA_ROTATION.TOP;
          break;
        case 3:
          rotation = CAMERA_ROTATION.RIGHT;
          break;
        case 2:
          rotation = CAMERA_ROTATION.BOTTOM;
          break;
        case 1:
          rotation = CAMERA_ROTATION.LEFT;
          break;
      }
    }
    HiLog.i(TAG, `direction: ${direction}, rotation:${rotation}`);
    this.sendMessage(`rotation:${rotation}`);
  }
}