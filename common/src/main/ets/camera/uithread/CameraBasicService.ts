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

import camera from '@ohos.multimedia.camera';
import lazy { Action } from '../../redux/actions/Action';
import lazy { CameraAction, CameraRunningState, CameraStartType, closeInfo } from './CameraAction';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { CameraProxy } from './CameraProxy';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { ModeType, VdeCollapsedFilterModeType } from '../../mode/ModeType';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { CameraAppCapability } from '../CameraAppCapability';
import lazy { DisplayCalculator } from '../../component/xcomponent/DisplayCalculator';
import lazy { VideoResolutionOperation } from '../../function/videoresolution/VideoResolutionOperation';
import lazy { AspectRatioOperation } from '../../function/aspectratio/AspectRatioOperation';
import lazy { FrameRateOperation } from '../../function/framerate/FrameRateOperation';
import type { EventBus } from '../../worker/eventbus/EventBus';
import type { PickerInfo, PositionType, PreviewRotationInfo, Size } from '../../utils/types';
import lazy { OutputOperation } from '../../function/outputswitcher/OutputOperation';
import lazy { OutputType } from '../../function/outputswitcher/OutputType';
import media from '@ohos.multimedia.media';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { SkinColorMode } from '../../function/enumbase/SkinColorMode';
import type image from '@ohos.multimedia.image';
import lazy { BlurAnimateUtil } from '../../utils/BlurAnimateUtil';
import lazy { RecorderConfigOperation } from '../../function/recordcontrol/RecorderConfigOperation';
import lazy {
  PreviewOutputMessage,
  PreviewRecordOutputMessage,
  TimeLapseRecordOutputMessage,
  SessionMessage,
  VideoOutputMessage,
  TagMessage,
  RestartPreviewType,
  CloseInfoToWork
} from '../DataType';
import lazy { PropTag } from '../../service/preferences/PropTag';
import lazy { XComponentService } from '../../component/xcomponent/XComponentService';
import lazy { ZoomOperation } from '../../function/zoombar/ZoomOperation';
import lazy { CameraBasicOperation, ReconfigurationFlowData } from './CameraBasicOperation';
import lazy { ContextManager } from '../../service/context/ContextManager';
import lazy { simpleStringify } from '../../utils/SimpleStringify';
import lazy { OutputSwitcher } from '../../function/outputswitcher/OutputSwitcher';
import lazy { ThumbnailService } from '../../component/thumbnail/ThumbnailService';
import lazy { JSON } from '@kit.ArkTS';
import lazy { PickerUiService } from '../../service/picker/PickerUiService';
import lazy { ZoomAction } from '../../function/zoombar/ZoomAction';
import lazy { LogStyleMode } from '../../function/enumbase/LogStyleMode';
import lazy { RecordingState } from '../../function/recordcontrol/RecordAction';
import lazy { execDispatch, getStates } from '../../redux';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { CaptureActionType } from '../../redux/actions/CaptureActionType';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { CollaborateControlActionType } from '../../redux/actions/CollaborateControlActionType';
import lazy { FocusExposureActionType } from '../../redux/actions/FocusExposureActionType';
import lazy { FocusData } from '../../component/focusExposure/FocusExposureHelper';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { CommonConstants } from '../../statistics/CommonConstants';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { WindowActionType } from '../../redux/actions/WindowActionType';
import lazy { RecordController } from '../../function/recordcontrol/RecordController';
import { PhotoFormatMode } from '../../function/enumbase/PhotoFormatMode';
import { CollaborateControlService } from '../../service/collaborateControl/CollaborateControlService';

const TAG: string = 'CameraBasicService';
const EPSILON = 0.1;
const RATE_60_FPS = 2;
const ANGLE_360: number = 360;
const MAX_RETRY_COUNT = 5;

export class CameraBasicService {
  private mBase: BaseComponent = new BaseComponent();

  protected mCameraProxy: CameraProxy = CameraProxy.getInstance();
  protected mStoreManager: StoreManager | undefined = StoreManager.getInstance();
  protected mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mCameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_FRONT;
  private mCurrentMode: ModeType = undefined //ModeType.PHOTO;
  private mPipSurfaceId: string = '';
  private static sInstanceCameraBasicService: CameraBasicService;
  private mCurrentFlowingActon: CameraAction | undefined = undefined;
  private isLeftRightNativeExchangeSurface: boolean = false;
  private mCacheHdr: boolean = false;
  private mCacheFrameRate: number = 30;
  private mCacheVideoResolution: number = SettingFuncDialogItemIndex.INDEX_NONE;
  private mCacheVideoOutputMessage: VideoOutputMessage = undefined;
  private lastSurfaceIsNull: boolean = false;
  private isForeground: boolean = true;

  private constructor() {
  }

  public init(): void {
    HiLog.i(TAG, `CameraBasicService init invoke, context name: ${ContextManager.getInstance().getModuleName()}.`);
    this.mEventBus.on(CameraActionType.INIT, this.initCamera.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.INIT_CAMERA_LIST, this.initCameraList.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.WARM_START, this.warmStartup.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.CREATE_AND_OPEN_CAMERA_INPUT, this.createAndOpenCameraInput.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.WARM_START_WITH_MODE_AND_POS, this.warmStartWithModeAPos.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.START, this.startPreview.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.RESTART, this.restartPreview.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.CHANGE_MODE, this.changeMode.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.CHANGE_OUTPUT_TYPE, this.changeOutputType.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.SWITCH_CAMERA, this.switchCamera.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.RECOVER_CAMERA, this.recoverCamera.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.SWITCH_CAMERA_CHANGE_MODE, this.changeModeAndSwitchCamera.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.RELEASE, this.release.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STOP_PREVIEW, this.stopPreviewOutPut.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.CLOSE, this.close.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_ADD_PIP_SURFACE_ID, this.addPipSurface.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.CONFIRM_CAPTURE, this.confirmCapture.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CaptureActionType.CONFIRM_BURST_CAPTURE, this.confirmCapture.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FocusExposureActionType.SET_METERING_POINT, this.setMeteringPoint.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_HANDLE_ZOOM_VIBRATOR, this.handleZoomVibrator.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_STOP_ZOOM_VIBRATOR, this.stopZoomVibrator.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_CAMERA_SHOT_KEY, this.setCameraShotKey.bind(this), this.mBase.hashCode());
    this.mEventBus.on(FocusExposureActionType.ACTION_SET_FOCUS_MODE, this.setFocusPoint.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_DIRECTION_CHANGE, this.setDirection.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_NEW_WANT, this.onNewWant.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.SWITCH_COLLABORATION, this.switchCollaborate.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.RELEASE_RESTART_AFTER_PHOTO_SAVED,
      this.connectionExecReconfigurationFlow.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_SWITCH_CAMERA_CHANGE_MODE_ONLY, this.onCameraAndModeChanged.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.START_STREAM, this.onCollaborateControlStartStream.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CollaborateControlActionType.STOP_STREAM, this.onCollaborateControlStopStream.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.KEEP_USING_STELLAR_LENSES, this.onKeepUsingStellarLenses.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(WindowActionType.WINDOW_STATUS, this.windowStatusChange.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_FOREGROUND, this.onForeground.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.onBackground.bind(this), this.mBase.hashCode());
  }

  private async createAndOpenCameraInput(data: { position: camera.CameraPosition, mode: ModeType }): Promise<void> {
    HiLog.begin(TAG, 'createAndOpenCameraInput');
    HiLog.i(TAG, 'createAndOpenCameraInput pos ' + data.position + ', mode ' + data.mode);
    this.mCameraPosition = data.position;
    this.mCurrentMode = data.mode;
    const pickerInfo: PickerInfo = GlobalContext.get().getObject('pickerInfo') as PickerInfo;
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
    const quickZoomArray: number[] =
      CameraAppCapability.getInstance().getQuickZoomArray(data.position, data.mode, outputType);
    const context = ContextManager.getInstance().getContextWithToken();
    await this.mCameraProxy.initCamera({
      cameraPosition: data.position,
      mode: data.mode,
      cameraType: this.getCameraType(outputType, quickZoomArray, getStates().get<number>('zoomReducer', 'zoomRatio')),
      zoomValue: getStates().get<number>('zoomReducer', 'zoomRatio')
    }, context, pickerInfo)
    HiLog.end(TAG, 'createAndOpenCameraInput');
  }

  public static getInstance(): CameraBasicService {
    if (!CameraBasicService.sInstanceCameraBasicService) {
      CameraBasicService.sInstanceCameraBasicService = new CameraBasicService();
    }
    return CameraBasicService.sInstanceCameraBasicService;
  }

  protected enableUi(): void {
    this.mStoreManager.postMessage(Action.uiState(true));
  }

  protected disableUi(): void {
    this.mStoreManager.postMessage(Action.uiState(false));
  }

  private async initCamera(data: {
    cameraPosition: camera.CameraPosition,
    mode: ModeType,
    isDeferred: boolean
  }): Promise<void> {
    HiLog.i(TAG, `initCamera ${JSON.stringify(data)} begin.`);
    this.lastSurfaceIsNull = false;
    this.mCameraPosition = data.cameraPosition;
    this.mCurrentMode = data.mode;
    this.mCurrentFlowingActon = CameraActionType.INIT;
    let pickerInfo: PickerInfo | null = null;
    try {
      pickerInfo = GlobalContext.get().getObject('pickerInfo') as PickerInfo;
      let parameters: object = GlobalContext.get().getCameraAbilityWant().parameters as object;
      let callingTokenID: number = parameters['ohos.aafwk.param.callerToken'] as number;
      pickerInfo.callingTokenID = callingTokenID;
      HiLog.d(TAG, `initCamera ${pickerInfo.isPicker}, ${pickerInfo.callingTokenID}`);
    } catch (err) {
      HiLog.e(TAG, `get pickerInfo fail. ${err?.code}`);
    }
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
    const quickZoomArray: number[] =
      CameraAppCapability.getInstance().getQuickZoomArray(data.cameraPosition, data.mode, outputType);
    await this.mCameraProxy.initCamera({
      cameraPosition: data.cameraPosition,
      mode: data.mode,
      cameraType: this.getCameraType(outputType, quickZoomArray, getStates().get<number>('zoomReducer', 'zoomRatio')),
      zoomValue: getStates().get<number>('zoomReducer', 'zoomRatio'),
    }, ContextManager.getInstance().getContextWithToken(), pickerInfo);
    // isDeferred: only open camera input here; first full session/commit runs in startPreview once XComponent
    // surface exists. Requires a single ACTION_INIT (see phone index skipIntro dedupe vs MainAbility).
    this.mCurrentFlowingActon = undefined;
    HiLog.i(TAG, 'initCamera end.');
  }

  private initCameraList(): void {
    this.mCameraProxy.initCameraList();
  }

  private getCameraType(outputType: OutputType, quickZoomArray: number[], zoomRatio: number): camera.CameraType {
    HiLog.i(TAG, `getCameraType outputType ${outputType} quickZoomArray ${quickZoomArray}  zoomRatio ${zoomRatio}`);
    if (DeviceInfo.isTv()) {
      return camera.CameraType.CAMERA_TYPE_WIDE_ANGLE;
    }
    zoomRatio = zoomRatio ? zoomRatio : 1;
    return camera.CameraType.CAMERA_TYPE_DEFAULT; // 逻辑镜头
  }

  /** Cold / deferred XComponent: avoid START_UP + commitSession until preview surface exists (reduces 7400201 retries). */
  private shouldDeferSessionUntilSurfaceReady(): boolean {
    if (XComponentService.getInstance().getSurface()) {
      return false;
    }
    if (!getStates().get<boolean>('cameraReducer', 'isColdStart')) {
      return false;
    }
    const runningState = getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState');
    return runningState !== CameraRunningState.STARTED;
  }

  private hasPreviewSurfaceInMessage(message: SessionMessage | undefined): boolean {
    if (!message?.previewOutputMessage) {
      return false;
    }
    const preview = message.previewOutputMessage;
    return !!(preview.previewSurfaceId ?? preview.xComponentSurfaceId);
  }

  private async warmStartup(): Promise<void> {
    // 如果停留在picker拍完照的确认界面，则需要拦截热启动
    if (getStates().get<boolean>('uiReducer', 'showPicker')) {
      return;
    }
    HiLog.i(TAG, 'warmStartup begin.');
    this.lastSurfaceIsNull = false;
    //zy-20251209-息屏进入后，调用到这里，会改变按钮的enable，让按钮不可点击
    // this.disableUi();
    const zoomRatio = ZoomOperation.getInstance().getStartupZoom(this.mCurrentMode, this.mCameraPosition);
    this.mCurrentFlowingActon = CameraActionType.WARM_START;
    if (this.shouldDeferSessionUntilSurfaceReady()) {
      HiLog.i(TAG, 'warmStartup: defer startupCamera until XComponent surface is ready.');
      this.mCurrentFlowingActon = undefined;
      this.enableUi();
      HiLog.i(TAG, 'warmStartup end (deferred).');
      return;
    }
    await this.startupCamera(zoomRatio);
    this.mCurrentFlowingActon = undefined;
    this.mStoreManager.postMessage(CameraAction.started(CameraStartType.WARM_START, zoomRatio));
    this.enableUi();
    HiLog.i(TAG, 'warmStartup end.');
  }

  private async warmStartWithModeAPos(data: {
    mode: ModeType,
    cameraPosition?: camera.CameraPosition
  }): Promise<void> {
    HiLog.i(TAG, 'warmStartWithModeAPos begin.');
    this.lastSurfaceIsNull = false;
    this.disableUi();
    this.mCurrentMode = data.mode;
    if (data.cameraPosition) {
      this.mCameraPosition = data.cameraPosition;
    }
    if (AppStorage.Get('restoreFlag')) {
      return;
    }
    // 全景模式初始化imageReceiver
    CameraAppCapability.getInstance().queryCapability(this.mCameraPosition, this.mCurrentMode);
    this.mCurrentFlowingActon = CameraActionType.WARM_START_WITH_MODE_AND_POS;
    const zoomRatio = ZoomOperation.getInstance().getStartupZoom(this.mCurrentMode, this.mCameraPosition);
    if (this.shouldDeferSessionUntilSurfaceReady()) {
      HiLog.i(TAG, 'warmStartWithModeAPos: defer startupCamera until XComponent surface is ready.');
      this.mCurrentFlowingActon = undefined;
      this.enableUi();
      HiLog.i(TAG, 'warmStartWithModeAPos end (deferred).');
      return;
    }
    await this.startupCamera(zoomRatio);
    this.mCurrentFlowingActon = undefined;
    this.mStoreManager.postMessage(CameraAction.started(CameraStartType.WARM_START_WITH_MODE_AND_POS, zoomRatio));
    this.enableUi();
    HiLog.i(TAG, 'warmStartWithModeAPos end.');
  }

  private async startupCamera(zoomRatio?: number): Promise<void> {
    HiLog.d(TAG, `startupCamera updateStateZoomRatio: ${zoomRatio}`);
    this.mStoreManager.postMessage(Action.onPreviewFrameStart(false));
    this.mCameraProxy.checkThreadSyncTaskAndRecovery();
    ThumbnailService.getInstance().clearOutputTimerAndClearData();
    // const sessionInfo = await this.mCameraProxy.startupCamera(await this.getSessionMessage({
    //   zoomRatio: zoomRatio
    // }));
    // execDispatch(ZoomAction.updateStateZoomRatio(zoomRatio));
    // if (!sessionInfo) {
    //   HiLog.i(TAG, `startupCamera failed, state reset to UNINITIALIZED.`);
    //   execDispatch(CameraAction.reset());
    // } else {
    //   HiLog.i(TAG, `startupCamera success`);
    // }
    // 增加循环重试防止黑屏；无 surface 时不退避，交由 XComponent / startPreview 路径重试
    let retryCount = 0;
    let lastSessionMessage: SessionMessage | undefined = undefined;
    while (retryCount < MAX_RETRY_COUNT) {
      try {
        lastSessionMessage = await this.getSessionMessage({ zoomRatio });
        const sessionInfo = await this.mCameraProxy.startupCamera(lastSessionMessage);
        execDispatch(ZoomAction.updateStateZoomRatio(zoomRatio));
        if (sessionInfo) {
          HiLog.i(TAG, `startupCamera succeeded at ${retryCount + 1} attempt`);
          break;
        } else {
          HiLog.i(TAG, `startupCamera failed, state reset to UNINITIALIZED.`);
          execDispatch(CameraAction.reset());
          if (!this.hasPreviewSurfaceInMessage(lastSessionMessage)) {
            HiLog.i(TAG, 'startupCamera: no preview surface; end retries (deferred surface will retry).');
            break;
          }
        }
      } catch (error) {
        HiLog.e(TAG, `startupCamera errored at attempt ${retryCount + 1}: ${error.code}`);
      }
      retryCount++;
      if (retryCount >= MAX_RETRY_COUNT) {
        break;
      }
      const backoffMs = this.hasPreviewSurfaceInMessage(lastSessionMessage) ? 100 * Math.pow(2, retryCount - 1) : 0;
      if (backoffMs > 0) {
        await new Promise(resolve => setTimeout(resolve, backoffMs));
      }
    }
  }

  private async getSurfaceId(dynamicAttachSurf?: boolean): Promise<string> {
    HiLog.i(TAG, 'getSurfaceId begin.');
    const surface: string | undefined = XComponentService.getInstance().getSurface();
    HiLog.i(TAG, `getSurfaceId end, surface: ${surface}.`);
    return surface;
  }

  private getSubSurfaceId(): string {
    return XComponentService.getInstance().getCollaborateSurface();
  }

  private async switchCollaborate(data: { collaborated: boolean }): Promise<void> {
    HiLog.i(TAG, 'switchCollaborate E.');
    let sessionMessage: PreviewOutputMessage = null;
    let tagMessage: TagMessage = null;
    if (data.collaborated) {
      sessionMessage = {
        previewSurfaceId: this.getSubSurfaceId(),
        previewProfile: this.getPreviewProfile()
      };
      tagMessage = this.getTagMessage();
      HiLog.i(TAG, `collaborate session messge: ${JSON.stringify(sessionMessage)}`);
    }
    this.mCameraProxy.switchCollaborate(sessionMessage, tagMessage);
    HiLog.i(TAG, 'switchCollaborate X.');
  }

  private onCollaborateControlStartStream(): void {
    HiLog.begin(TAG, 'onCollaborateControlStartStream');
    const isLastHighColorSpace = CollaborateControlService.getInstance().getIsLastHighColorSpace();
    HiLog.i(TAG, `isLastHighColorSpace: ${isLastHighColorSpace}`)
    if (this.mCurrentMode === ModeType.VIDEO || !isLastHighColorSpace) {
      const previewProfile = {
        format: CollaborateControlService.getInstance()?.getPreviewProfile()?.format,
        size: this.getPreviewProfile()?.size
      };
      const previewMessage: PreviewOutputMessage = {
        previewProfile: previewProfile,
        previewSurfaceId: CollaborateControlService.getInstance().getSurfaceId()
      };
      const tagMessage: TagMessage = this.getTagMessage();
      this.mCameraProxy.collaborateControlPreviewOutput(previewMessage, tagMessage);
    } else {
      this.warmStartup();
    }
    HiLog.end(TAG, 'onCollaborateControlStartStream')
  }

  private onCollaborateControlStopStream(): void {
    HiLog.i(TAG, 'onCollaborateControlStopStream');
    const tagMessage: TagMessage = this.getTagMessage();
    this.mCameraProxy.collaborateControlPreviewOutput(null, tagMessage);
  }

  private async startPreview(data: { isDeferred: boolean }): Promise<void> {
    // 如果停留在picker拍完照的确认界面，则需要拦截起流
    if (getStates().get<boolean>('uiReducer', 'showPicker')) {
      return;
    }
    // picker不设置isBackground全局变量，不做屏蔽
    if (AppStorage.get<boolean>('isBackground') &&
      (!GlobalContext.get().getIsPicker() || !getStates().get<boolean>('securityCameraReducer', 'isSecurityCamera'))) {
      HiLog.e(TAG, 'camera surface load isBackground.');
      return;
    }
    let zoomRatio: number = getStates().get<number>('zoomReducer', 'zoomRatio');
    if (this.mCurrentFlowingActon && this.mCurrentFlowingActon === CameraActionType.WARM_START) {
      zoomRatio = ZoomOperation.getInstance().getStartupZoom(this.mCurrentMode, this.mCameraPosition);
    }
    HiLog.i(TAG, `startPreview begin.zoomRatio:${zoomRatio}, ${this.mCurrentFlowingActon}`);
    this.mCurrentFlowingActon = CameraActionType.START;
    if (data.isDeferred || this.lastSurfaceIsNull) {
      let previewSurfaceId = await this.getSurfaceId();
      let minSurfaceId = undefined;
      HiLog.i(TAG, `previewSurfaceId: ${previewSurfaceId}, minSurfaceId: ${minSurfaceId}`);
      const sessionIsReady: boolean = await this.mCameraProxy.addDeferredSurface(previewSurfaceId, minSurfaceId);
      const isReadyToStartup: boolean = this.mCameraProxy.readyToStartup();
      if (!sessionIsReady && isReadyToStartup) {
        HiLog.i(TAG, 'Session is not ready.');
        ZoomOperation.getInstance().setRemainZoomRatio(true);
        if (this.mCurrentMode !== getStates().get<ModeType>('modeReducer', 'mode')) {
          this.mCurrentMode = getStates().get<ModeType>('modeReducer', 'mode');
        }
        if (this.mCameraPosition !== getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition')) {
          this.mCameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
        }
        await this.startupCamera(getStates().get<number>('zoomReducer', 'zoomRatio'));
      }
    } else {
      await this.mCameraProxy.startPreview(await this.getSessionMessage({ zoomRatio: zoomRatio }));
    }
    this.lastSurfaceIsNull = false;
    this.mCurrentFlowingActon = undefined;
    this.mStoreManager.postMessage(CameraAction.started(CameraStartType.COLD_START));
    HiLog.i(TAG, 'startPreview end.');
  }

  public async swapDeferredSurface(throughImageEffect: boolean): Promise<void> {
    HiLog.begin(TAG, `swapDeferredSurface ${throughImageEffect}`);
    let previewSurfaceId = await this.getSurfaceId(throughImageEffect);
    HiLog.i(TAG, `swapDeferredSurface Id: ${previewSurfaceId}`);
    const swapSuccess: boolean = await this.mCameraProxy.swapDeferredSurface(previewSurfaceId);
    HiLog.i(TAG, `swapDeferredSurface suc: ${swapSuccess}`);
    HiLog.end(TAG, `swapDeferredSurface ${throughImageEffect}`);
  }

  private async restartPreview(data: {
    zoomRatio: number
    collaborate?: boolean
    tricollapsStatusChange?: boolean
  }): Promise<void> {
    HiLog.i(TAG, 'restartPreview begin.');
    this.lastSurfaceIsNull = false;
    if (AppStorage.get('restoreFlag') ||
      (DeviceInfo.isPc() && !getStates().get<boolean>('cameraReducer', 'isCameraActive'))) {
      HiLog.w(TAG, 'isRestoreFlag true restartPreview cancel.');
      return;
    }
    if (!await this.getSurfaceId()) {
      HiLog.i(TAG, 'restartPreview error mSurfaceId is null.');
      this.enableUi();
      return;
    }
    if (this.mCurrentFlowingActon) {
      CameraBasicOperation.getIsNeedStoreReconfigurationFlow(this.mCurrentFlowingActon, CameraActionType.RESTART, data);
      return;
    }
    this.disableUi();
    if (ThumbnailService.getInstance().getIsNeedWaitReleasePhotoOutput()) {
      CameraBasicOperation.saveReconfigFlowData(CameraActionType.RESTART, data);
      return;
    }
    // 全景模式初始化imageReceiver
    this.mStoreManager.postMessage(Action.onPreviewFrameStart(false));
    BlurAnimateUtil.setValidFrameFlag(false);
    HiLog.d(TAG, `restartPreview updateStateZoomRatio: ${data.zoomRatio}`);
    execDispatch(ZoomAction.updateStateZoomRatio(data.zoomRatio));
    this.mCurrentFlowingActon = CameraActionType.RESTART;
    const message = await this.getSessionMessage(data);
    const tricollapsStatusChange = data.tricollapsStatusChange;
    await this.mCameraProxy.restartPreview(message, RestartPreviewType.CHANGE_ASPECT_RATIO, tricollapsStatusChange);
    this.mCurrentFlowingActon = undefined;
    let isNeedReconfigurationFlowAction = CameraBasicOperation.getNeedExecReconfigurationFlowAction();
    if (isNeedReconfigurationFlowAction) {
      HiLog.i(TAG, 'isNeedReconfigurationFlowAction.');
      await this.connectionExecReconfigurationFlow({
        flowAction: isNeedReconfigurationFlowAction,
        flowData: CameraBasicOperation.getExecReconfigurationFlowDataAndClearQueue()
      });
      return;
    } else {
      this.mStoreManager.postMessage(CameraAction.started(CameraStartType.RESTART, data.zoomRatio));
    }
    this.enableUi();
    HiLog.i(TAG, 'restartPreview end.');
  }

  private async changeOutputType(data: { zoomRatio?: number }): Promise<void> {
    HiLog.i(TAG, 'changeOutputType begin.');
    this.lastSurfaceIsNull = false;
    if (!await this.getSurfaceId()) {
      HiLog.i(TAG, 'changeOutputType error mSurfaceId is null.');
      this.enableUi();
      return;
    }
    this.disableUi();
    if (ThumbnailService.getInstance().getIsNeedWaitReleasePhotoOutput()) {
      CameraBasicOperation.saveReconfigFlowData(CameraActionType.CHANGE_OUTPUT_TYPE, data);
      HiLog.i(TAG, 'changeOutputType return.');
      return;
    }
    this.mStoreManager.postMessage(Action.onPreviewFrameStart(false));
    BlurAnimateUtil.setValidFrameFlag(false);
    this.mCurrentFlowingActon = CameraActionType.CHANGE_OUTPUT_TYPE;
    HiLog.d(TAG, `restartPreview updateStateZoomRatio: ${data.zoomRatio}`);
    if (data.zoomRatio) {
      execDispatch(ZoomAction.updateStateZoomRatio(data.zoomRatio));
    }
    await this.mCameraProxy.restartPreview(await this.getSessionMessage(data), RestartPreviewType.CHANGE_OUTPUT_TYPE);
    this.mCurrentFlowingActon = undefined;
    this.mStoreManager.postMessage(CameraAction.started(CameraStartType.CHANGE_OUTPUT_TYPE, data.zoomRatio));
    this.enableUi();
    HiLog.i(TAG, 'changeOutputType end.');
  }

  private async changeMode(data: {
    mode: ModeType,
    isToDefaultWarmStart: boolean
  }): Promise<void> {
    this.lastSurfaceIsNull = false;
    // 如果是恢复默认热启动触发的，则不走后续配流流程
    this.mCurrentMode = data.mode;
    if (data.isToDefaultWarmStart || AppStorage.Get('restoreFlag')) {
      HiLog.w(TAG, 'toDefaultWarmStart or restoreFlag');
      return;
    }
    // After ACTION_INIT only, worker still holds CameraInput with isCommit false. CHANGE_MODE uses
    // restartPreview with isCanReuseCameraInput false → release + createCameraInput again → 7400109
    // (see hilog cold start: redundant CAMERA_ACTION_CHANGE_MODE right after INIT).
    const runningStateForMode = getStates().get<CameraRunningState>('cameraReducer', 'cameraRunningState');
    if (runningStateForMode === CameraRunningState.INITIALIZED) {
      HiLog.i(TAG, 'changeMode: skip worker while INITIALIZED (wait for startPreview / START_UP).');
      CameraAppCapability.getInstance().queryCapability(this.mCameraPosition, this.mCurrentMode);
      return;
    }
    if (this.shouldDeferSessionUntilSurfaceReady()) {
      HiLog.i(TAG, 'changeMode: skip worker until preview surface (cold deferred).');
      CameraAppCapability.getInstance().queryCapability(this.mCameraPosition, this.mCurrentMode);
      return;
    }
    this.disableUi();
    if (ThumbnailService.getInstance().getIsNeedWaitReleasePhotoOutput()) {
      CameraBasicOperation.saveReconfigFlowData(CameraActionType.CHANGE_MODE, data);
      return;
    }
    HiLog.i(TAG, 'changeMode begin.');
    this.mStoreManager.postMessage(Action.onPreviewFrameStart(false));
    this.mCurrentMode = data.mode;
    CameraAppCapability.getInstance().queryCapability(this.mCameraPosition, this.mCurrentMode);
    const zoomRatio = ZoomOperation.getInstance().getStartupZoom(this.mCurrentMode, this.mCameraPosition);
    BlurAnimateUtil.setValidFrameFlag(false);
    this.mCurrentFlowingActon = CameraActionType.CHANGE_MODE;
    HiLog.d(TAG, `changeMode updateStateZoomRatio: ${zoomRatio}`);
    HiLog.begin(TAG, 'getSessionMessage');
    const sessionMessage = await this.getSessionMessage({ zoomRatio: zoomRatio });
    HiLog.end(TAG, 'getSessionMessage');
    await this.mCameraProxy.changeMode(sessionMessage, RestartPreviewType.CHANGE_MODE);
    this.mCurrentFlowingActon = undefined;
    this.mStoreManager.postMessage(CameraAction.started(CameraStartType.CHANGE_MODE, zoomRatio));

    const isRestoreFlag = AppStorage.get('restoreFlag');
    // 设置页恢复默认值触发的changeMode流程结束时，恢复初始值
    if (isRestoreFlag) {
      AppStorage.setOrCreate('restoreFlag', false);
      HiLog.i(TAG, `isRestoreFlag:${AppStorage.get('restoreFlag')}, initial setting default flag.`);
    }
    this.enableUi();
    HiLog.i(TAG, 'changeMode end.');
  }

  private async switchCamera(data: {
    cameraPosition: camera.CameraPosition, keepVideoFlowing?: boolean, isVideoRotation?: boolean
  }): Promise<void> {
    HiLog.i(TAG, `switchCamera begin. ${this.mCurrentMode} - ${data.cameraPosition}`);
    this.lastSurfaceIsNull = false;
    this.mCameraPosition = data.cameraPosition;
    if (AppStorage.Get('restoreFlag')) {
      return;
    }
    this.disableUi();
    if (ThumbnailService.getInstance().getIsNeedWaitReleasePhotoOutput()) {
      CameraBasicOperation.saveReconfigFlowData(CameraActionType.SWITCH_CAMERA, data);
      HiLog.i(TAG, 'switchCamera return.');
      return;
    }
    this.mStoreManager.postMessage(Action.onPreviewFrameStart(false));
    BlurAnimateUtil.setValidFrameFlag(false);
    let specialZoomRatio = ZoomOperation.getDefaultZoomRatio(this.mCurrentMode, data.cameraPosition);
    this.mCurrentFlowingActon = CameraActionType.SWITCH_CAMERA;
    HiLog.d(TAG, `switchCamera updateStateZoomRatio: ${specialZoomRatio}`);
    execDispatch(ZoomAction.updateStateZoomRatio(specialZoomRatio));
    await this.mCameraProxy.switchCamera(
      await this.getSessionMessage({
        zoomRatio: specialZoomRatio, keepVideoFlowing: data.keepVideoFlowing,
        isVideoRotation: data.isVideoRotation
      }),
      RestartPreviewType.SWITCH_CAMERA);
    this.mCurrentFlowingActon = undefined;
    this.mStoreManager.postMessage(CameraAction.started(CameraStartType.SWITCH_CAMERA, specialZoomRatio));
    this.enableUi();
    HiLog.i(TAG, 'switchCamera end.');
  }

  private async recoverCamera(data: { cameraPosition: camera.CameraPosition }): Promise<void> {
    HiLog.i(TAG, `recoverCamera begin. cameraPosition, ${data.cameraPosition}`);
    this.mCameraPosition = data.cameraPosition;
    HiLog.i(TAG, 'recoverCamera end.');
  }

  private async changeModeAndSwitchCamera(data: {
    cameraPosition: camera.CameraPosition,
    mode: ModeType
  }): Promise<void> {
    this.lastSurfaceIsNull = false;
    this.disableUi();
    if (ThumbnailService.getInstance().getIsNeedWaitReleasePhotoOutput()) {
      CameraBasicOperation.saveReconfigFlowData(CameraActionType.SWITCH_CAMERA_CHANGE_MODE, data);
      return;
    }
    HiLog.i(TAG, 'changeModeAndSwitchCamera begin.' + JSON.stringify(data));
    this.mStoreManager.postMessage(Action.onPreviewFrameStart(false));
    this.mCameraPosition = data.cameraPosition;
    this.mCurrentMode = data.mode;
    CameraAppCapability.getInstance().queryCapability(this.mCameraPosition, this.mCurrentMode);
    BlurAnimateUtil.setValidFrameFlag(false);
    const zoomRatio = ZoomOperation.getInstance().getStartupZoom(this.mCurrentMode, this.mCameraPosition);
    this.mCurrentFlowingActon = CameraActionType.SWITCH_CAMERA_CHANGE_MODE;
    HiLog.e(TAG, `changeModeAndSwitchCamera updateStateZoomRatio: ${zoomRatio}`);
    execDispatch(ZoomAction.updateStateZoomRatio(zoomRatio));
    await this.mCameraProxy.changeModeAndSwitchCamera(await this.getSessionMessage({ zoomRatio: zoomRatio }),
      RestartPreviewType.CHANGE_MODE_AND_SWITCH_CAMERA);
    this.mCurrentFlowingActon = undefined;
    this.mStoreManager.postMessage(CameraAction.started(CameraStartType.SWITCH_CAMERA_CHANGE_MODE, zoomRatio));
    this.enableUi();
    HiLog.i(TAG, 'changeModeAndSwitchCamera end.');
  }

  private async release(data: {
    isNeedSaveRestore: boolean
  }): Promise<void> {
    HiLog.i(TAG, `release begin.`);
    await this.close(data);
    HiLog.i(TAG, 'release end.');
  }

  private async stopPreviewOutPut(): Promise<void> {
    HiLog.i(TAG, `stopPreviewOutPut begin.`);
    await this.mCameraProxy.stopPreviewOutPut();
    HiLog.i(TAG, 'stopPreviewOutPut end.');
  }

  private getCloseInfoToWork(data: closeInfo): CloseInfoToWork {
    HiLog.i(TAG, `closeCameraInfo:${JSON.stringify(data)},closeMode:${this.mCurrentMode}`);
    let isLegalSAR: boolean = true; // 只有需要saveRestore时此状态才有用
    const specialZoomRatio = ZoomOperation.getDefaultZoomRatio(this.mCurrentMode, this.mCameraPosition);
    if (specialZoomRatio !== 1 || data.isEnterPhotoBrowser) { // 变焦默认非1，进大图save非legal，需要下发noNeed给底层
      isLegalSAR = false;
    }
    let closeInfoToWork: CloseInfoToWork = {
      mode: this.mCurrentMode,
      isNeedSaveRestore: data.isNeedSaveRestore,
      isLegalSaveRestore: isLegalSAR,
      isNeedDelayClose: data.isNeedDelayClose,
      isPcEnterSleep: data.isPcEnterSleep
    }
    return closeInfoToWork;
  }

  private async close(data: closeInfo): Promise<void> {
    if (this.isLeftRightNativeExchangeSurface) {
      const surface: string | undefined = XComponentService.getInstance().getSurface();
      this.isLeftRightNativeExchangeSurface = false;
      HiLog.i(TAG, `RealTimeRecordFilter releaseSurface when close. Surface as 0_${surface}`);
    }
    // 连续重启流场景，close丢掉之前任务，需要重置mCurrentFlowingActon状态
    this.mCurrentFlowingActon = undefined;
    ThumbnailService.getInstance().clearOutputTimerAndClearData();
    //zy-20251209-息屏进入后，调用到这里，会改变按钮的enable，让按钮不可点击
    // this.disableUi();
    const closeInfoToWork: CloseInfoToWork = this.getCloseInfoToWork(data);
    await this.mCameraProxy.closeCamera(closeInfoToWork);
    PickerUiService.isCameraActive = false;
    this.enableUi();
  }

  private addPipSurface(data: { pipSurfaceId: string }): void {
    this.mPipSurfaceId = data.pipSurfaceId;
    this.mCameraProxy.addPipSurface(data.pipSurfaceId);
  }

  // 按场景接续执行重启流流程
  public async connectionExecReconfigurationFlow(data: { flowAction: CameraAction, flowData: ReconfigurationFlowData }):
    Promise<void> {
    if (!data.flowAction) {
      return;
    }
    HiLog.i(TAG, `connectionExecReconfigurationFlow flowAction: ${data.flowAction} E.`);
    if (data.flowAction === CameraActionType.RESTART) {
      let actualParam = {
        zoomRatio: data.flowData.zoomRatio
      };
      await this.restartPreview(actualParam);
      return;
    }
    if (data.flowAction === CameraActionType.START) {
      let actualParam = { isDeferred: data.flowData.isDeferred };
      await this.startPreview(actualParam);
      return;
    }
    if (data.flowAction === CameraActionType.CHANGE_MODE) {
      let actualParam = {
        mode: data.flowData.mode,
        isToDefaultWarmStart: data.flowData.isToDefaultWarmStart
      };
      await this.changeMode(actualParam);
      return;
    }
    if (data.flowAction === CameraActionType.SWITCH_CAMERA) {
      let actualParam = { cameraPosition: data.flowData.cameraPosition };
      await this.switchCamera(actualParam);
      return;
    }
    if (data.flowAction === CameraActionType.SWITCH_CAMERA_CHANGE_MODE) {
      let actualParam = {
        cameraPosition: data.flowData.cameraPosition,
        mode: data.flowData.mode
      };
      await this.changeModeAndSwitchCamera(actualParam);
      return;
    }
    if (data.flowAction === CameraActionType.CHANGE_OUTPUT_TYPE) {
      let actualParam = {
        zoomRatio: data.flowData.zoomRatio,
        superMacroEnable: data.flowData.superMacroEnable,
        watchMoonEnable: data.flowData.watchMoonEnable
      };
      await this.changeOutputType(actualParam);
      return;
    }
    await this.warmStartup();
  }

  private onCameraAndModeChanged(): void {
    if (!getStates().get<boolean>('contextReducer', 'isForeground')) {
      return;
    }
    this.mCameraPosition = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    this.mCurrentMode = getStates().get<ModeType>('modeReducer', 'mode');
    HiLog.i(TAG, 'onCameraAndModeChanged');
  }

  private async getPreviewOutputMessage(): Promise<PreviewOutputMessage> {
    const isCollaborated: boolean = AppStorage.get('collaborate_status') as boolean;
    let isCollaborateSurfaceId: boolean = isCollaborated;
    let surface = await this.getSurfaceId();
    if (surface === undefined || surface === null) {
      this.lastSurfaceIsNull = true;
    }
    return {
      previewSurfaceId: surface,
      previewProfile: this.getPreviewProfile(),
      collaborateSurfaceId: isCollaborateSurfaceId ? this.getSubSurfaceId() : null,
      xComponentSurfaceId: XComponentService.getInstance().getSurface(),
    };
  }

  private async getCollaborateControlPreviewOutputMessage(): Promise<PreviewOutputMessage> {
    const isSupportedHighColorSpace = this.getIsSupportedHighColorSpace();
    HiLog.i(TAG, `getIsSupportedHighColorSpace: ${isSupportedHighColorSpace}.`)
    const collaborateId = CollaborateControlService.getInstance().getSurfaceId();
    const stateBackAdFront = false;
    HiLog.i(TAG, `collaborate previewOuput isStateBackAdFront: ${stateBackAdFront}.`)
    // 录像模式开启双屏协同显拦截
    let isCollaborated: boolean = AppStorage.get('collaborate_status');
    if (this.mCurrentMode === ModeType.VIDEO && isCollaborated) {
      HiLog.i(TAG, `Dual-screen simultaneous display mode does not support remote photo capture during recording.`)
      return undefined;
    }
    if (stateBackAdFront) {
      // 后当前模式不支持遥控拍照
      HiLog.i(TAG, `backSelfie mode is not support collaborate cpmtrol.`)
      return undefined;
    }
    if (collaborateId === null || collaborateId === undefined) {
      // 场景卡片，依然更新surface
      const isIntelligentConnect = CollaborateControlService.getInstance().isIntelligentConnect();
      if (!isIntelligentConnect) {
        return undefined;
      }
    }
    const profile = this.getPreviewProfile();
    CollaborateControlService.getInstance().updateSurfaceParam(profile);
    return {
      previewProfile: CollaborateControlService.getInstance().getPreviewProfile(),
      previewSurfaceId: collaborateId
    }
  }

  private getIsSupportedHighColorSpace(): boolean {
    const collaborateForbidden10Bit =
      CollaborateControlService.getInstance().isConnected() && this.mCurrentMode === ModeType.PHOTO;
    return CameraAppCapability.getInstance().getIsSupportedHighColorSpace() && !collaborateForbidden10Bit;
  }

  private async getSessionMessage(data: {
    zoomRatio?: number, keepVideoFlowing?: boolean, isVideoRotation?: boolean
  } = {}): Promise<SessionMessage> {
    HiLog.i(TAG, `getSessionMessage begin,${JSON.stringify(data)}`);
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
    const quickZoomArray: number[] =
      CameraAppCapability.getInstance().getQuickZoomArray(this.mCameraPosition, this.mCurrentMode, outputType);
    const frameRate: number = this.getVideoFrameRate();
    if (DeviceInfo.isTablet() &&
      this.mCurrentMode === ModeType.VIDEO && frameRate === FrameRateOperation.FRAME_FPS_RATE_60 &&
      this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK &&
      quickZoomArray.length > 1 && quickZoomArray[0] < 1 && data.zoomRatio < 1) {
      quickZoomArray.shift();
      data.zoomRatio = 1;
    }
    const startMessage: SessionMessage = {
      cameraInputMessage: {
        cameraPosition: this.mCameraPosition,
        mode: this.mCurrentMode,
        cameraType: this.getCameraType(outputType, quickZoomArray, data.zoomRatio),
        zoomValue: data.zoomRatio
      },
      previewOutputMessage: await this.getPreviewOutputMessage(),
      collaborateControlPreviewOutputMessage: await this.getCollaborateControlPreviewOutputMessage(),
      photoOutputMessage: {
        photoProfile: this.getPhotoProfile(this.mCameraPosition, this.mCurrentMode, data.zoomRatio ? data.zoomRatio : 1)
      },
      videoOutputMessage: this.getVideoMessage(data),
      timelapseOutputMessage: this.getTimelapseRecordMessage(),
      metadataOutputMessage: { metadataObjectTypeArr: this.getMetadataObjectTypeArr() },
      tagMessage: this.getTagMessage(quickZoomArray, false, data)
      // tagMessage必现作为最后一项,序列化context对象超长阻塞其它日志
    };
    this.checkHDRAndRemedyMessage(startMessage);
    HiLog.i(TAG, `getSessionMessage end, message: ${simpleStringify(startMessage)}}`)
    return startMessage;
  }

  public getTagMessage(quickZoomArray?: number[], isSuperSlowMo?: boolean,
    data: { zoomRatio?: number, keepVideoFlowing?: boolean, isVideoRotation?: boolean } = {}): TagMessage {
    if (quickZoomArray === undefined) {
      const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
      quickZoomArray =
        CameraAppCapability.getInstance().getQuickZoomArray(this.mCameraPosition, this.mCurrentMode, outputType);
      isSuperSlowMo = false;
      data.zoomRatio = getStates().get<number>('zoomReducer', 'zoomRatio');
    }
    return {
      mode: this.mCurrentMode,
      pickerInfo: GlobalContext.get().getObject('pickerInfo') as PickerInfo,
      outputType: OutputSwitcher.getInstance().getOutput(),
      zoomRatio: this.getZoomRatioValue(quickZoomArray, data),
      aspectRatio: this.getAspectRatio(),
      pipSurface: this.mPipSurfaceId,
      isP3Flag: this.getIsP3Flag(),
      videoResolution: this.getResolution(),
      frameRate: this.getVideoFrameRate(),
      isMirror: this.getMirror(),
      savePhotoFormat: this.getSavePhotoFormat(),
      isProRawDelivery: this.getIsProRawDelivery(),
      isCloseBFrame: FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION)?.getValue() === 1,
      previewRotationInfo: this.getPreviewRotationInfo(),
      usedAsPositionValue: this.getUsedAsPositionValue(),
      messageContext: ContextManager.getInstance().getContextWithToken(),
      isHdrVividFlag: this.getIsHdrVividFlag()
      // context必现作为最后一项,序列化对象超长阻塞其它日志
    };
  }

  public getIsHdrVividFlag() {
    return false;
  }

  public getIsProRawDelivery(): boolean {
    return false;
  }

  private checkHDRAndRemedyMessage(startMessage: SessionMessage): void {
    if (!startMessage?.videoOutputMessage?.videoProfile || !startMessage?.videoOutputMessage?.config) {
      return;
    }
    if (startMessage.tagMessage.isHdrVividFlag &&
      startMessage.videoOutputMessage.videoProfile.format === camera.CameraFormat.CAMERA_FORMAT_YCRCB_P010 &&
      startMessage.videoOutputMessage.config.profile.videoCodec === media.CodecMimeType.VIDEO_HEVC &&
    startMessage.videoOutputMessage.config.profile.isHdr) {
      return; // 开启hdr vivid场景校验通过
    }
    if (!startMessage.tagMessage.isHdrVividFlag &&
      startMessage.videoOutputMessage.videoProfile.format !== camera.CameraFormat.CAMERA_FORMAT_YCRCB_P010 &&
      !startMessage.videoOutputMessage.config.profile.isHdr) {
      return; // 关闭hdr vivid场景校验通过
    }
    HiLog.i(TAG, `checkHDRAndRemedyMessage, isHdrVividFlag: ${startMessage.tagMessage.isHdrVividFlag}`)
    // 重启流转台不一致，矫正与isHdrVividFlag保持一致
    if (startMessage.tagMessage.isHdrVividFlag) {
      if (startMessage.videoOutputMessage.videoProfile.format !== camera.CameraFormat.CAMERA_FORMAT_YCRCB_P010) {
        startMessage.videoOutputMessage.videoProfile = {
          ...startMessage.videoOutputMessage.videoProfile,
          format: camera.CameraFormat.CAMERA_FORMAT_YCRCB_P010
        };
      }
      startMessage.videoOutputMessage.config.profile.videoCodec = media.CodecMimeType.VIDEO_HEVC;
      startMessage.videoOutputMessage.config.profile.isHdr = true;
      if (startMessage.videoOutputMessage.videoProfile.frameRateRange.min !== 30) {
        startMessage.videoOutputMessage.videoProfile = {
          ...startMessage.videoOutputMessage.videoProfile,
          frameRateRange: { min: 30, max: 30 }
        };
      }
    }
    if (!startMessage.tagMessage.isHdrVividFlag) {
      if (startMessage.videoOutputMessage.videoProfile.format === camera.CameraFormat.CAMERA_FORMAT_YCRCB_P010 &&
        startMessage.tagMessage.isOpenLogStyle !== LogStyleMode.ON) {
        startMessage.videoOutputMessage.videoProfile = {
          ...startMessage.videoOutputMessage.videoProfile,
          format: camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP
        };
      }
      startMessage.videoOutputMessage.config.profile.isHdr = false;
    }
  }

  public getSavePhotoFormat(): camera.CameraFormat {
    let savePhotoFormat =
      OutputOperation.isPanPhotoOutput(this.mCurrentMode, OutputSwitcher.getInstance().getOutput(this.mCurrentMode)) ?
        PhotoFormatMode.JPG : FeatureManager.getInstance().getFunction(FunctionId.PHOTO_FORMAT)?.getValue();
    return camera.CameraFormat.CAMERA_FORMAT_JPEG;
  }

  // @ts-ignore
  private getColorStyleSetting(): camera.ColorStyleSetting {
    let colorStyleType = 0;
    let colorStyleHue = 0;
    let colorStyleSaturation = 0;
    let colorStyleTone = 0;
    HiLog.begin(TAG, 'getColorStyleSetting');
    let isCustomStyleEnabled: boolean = PreferencesService.getInstance()
      .getPropValue(PersistType.FOREVER, PropTag.CUSTOM_COLOR_STYLE_ENABLED, false) as boolean;
    if (OutputOperation.isPanVideoOutput(getStates().get<ModeType>('modeReducer', 'mode'))) {
      isCustomStyleEnabled = false;
    }
    let targetStyleIndex: number = PreferencesService.getInstance()
      .getPropValue(PersistType.FOREVER, PropTag.CUSTOM_COLOR_STYLE_SELECTED_INDEX, 0) as number;
    if (!isCustomStyleEnabled || targetStyleIndex < 0) {
      HiLog.w(TAG, `getColorStyleSetting status error or targetStyleIndex invalid.`);
      return this.getCloseColorStyleValue();
    }
    const persistDataString: string = PreferencesService.getInstance()
      .getPropValue(PersistType.FOREVER, PropTag.CUSTOM_COLOR_STYLES, '') as string;
    if (!persistDataString) {
      return this.getCloseColorStyleValue();
    }
    let persistResult: object | null = JSON.parse(persistDataString);
    HiLog.end(TAG, 'getColorStyleSetting');
    return {
      type: colorStyleType,
      hue: colorStyleHue,
      saturation: colorStyleSaturation,
      tone: colorStyleTone
    };
  }

  // @ts-ignore
  private getCloseColorStyleValue(): camera.ColorStyleSetting {
    const colorStypeType = 0;
    const colorStypeHue = 0;
    const colorStypeSaturation = 0;
    const colorStypeTone = 0;
    HiLog.end(TAG, 'getColorStyleSetting');
    return {
      type: colorStypeType,
      hue: colorStypeHue,
      saturation: colorStypeSaturation,
      tone: colorStypeTone
    };
  }

  private getPreviewProfile(): camera.Profile {
    let previewProfile: camera.Profile = undefined;
    if (OutputOperation.isPanVideoOutput(this.mCurrentMode)) {
      const videoResolution = this.getResolution();
      previewProfile = VideoResolutionOperation.getPreviewProfile(videoResolution, this.mCameraPosition,
        this.mCurrentMode);
    } else {
      let aspectRatio = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO)?.getValue();
      previewProfile = AspectRatioOperation.getPreviewProfile(aspectRatio, this.mCameraPosition, this.mCurrentMode);
    }
    HiLog.i(TAG, `getPreviewMessage previewProfile: $${JSON.stringify(previewProfile)}.`);
    return previewProfile;
  }

  private getPhotoProfile(position?: camera.CameraPosition, mode?: ModeType, zoomRatio?: number): camera.Profile {

    const outputType = OutputSwitcher.getInstance().getOutput();
    if (OutputOperation.isPanVideoOutput(this.mCurrentMode) &&
      (this.mCurrentMode !== ModeType.VIDEO || DeviceInfo.isPc())) {
      return undefined;
    }
    let profile: camera.Profile = { format: 2000, size: { width: 0, height: 0 } };
    if (this.mCurrentMode === ModeType.VIDEO) { // 录像抓拍
      let resolution = FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION)?.getValue();
      let snapShotProfile = AspectRatioOperation.getPhotoProfile(resolution, this.mCameraPosition,
        ModeType.VIDEO_SNAPSHOT);
      if (snapShotProfile) { // 录像抓拍配置,兼容未上VIDEO_SNAPSHOT配置场景
        return snapShotProfile;
      }
      if (resolution === SettingFuncDialogItemIndex.INDEX_FIR) {
        resolution = SettingFuncDialogItemIndex.INDEX_THR;
      }
      const frameRate: number = this.getVideoFrameRate();
      let videProfile: camera.VideoProfile =
        VideoResolutionOperation.getVideoProfile(resolution, position, mode, frameRate);
      profile.size.height = videProfile?.size.height;
      profile.size.width = videProfile?.size.width;
    } else {
      let aspectRatio: number = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO)?.getValue();
      return AspectRatioOperation.getPhotoProfile(aspectRatio, this.mCameraPosition, this.mCurrentMode, zoomRatio);
    }
    HiLog.i(TAG, `getPhotoProfile PhotoProfile: ${JSON.stringify(profile)}.`);
    return profile;
  }

  private getMetadataObjectTypeArr(): camera.MetadataObjectType[] {
    if (this.mCurrentMode === ModeType.PHOTO) {
      return undefined;
    }
    let metadataObjectTypeArr: camera.MetadataObjectType[] = [];
    if (this.mCurrentMode !== ModeType.NONE &&
      !(OutputOperation.isPanVideoOutput(this.mCurrentMode) &&
        (FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION)?.getValue() === 1 ||
          this.getVideoFrameRate() === 60))) {
      // 规格:文档矫正、4k录像、60fps录像、慢动作不支持人脸识别
      metadataObjectTypeArr.push(camera.MetadataObjectType.FACE_DETECTION);
      // @ts-ignore
      metadataObjectTypeArr.push(camera.MetadataObjectType.DOG_FACE);
      // @ts-ignore
      metadataObjectTypeArr.push(camera.MetadataObjectType.CAT_FACE);
      metadataObjectTypeArr.push(camera.MetadataObjectType.HUMAN_BODY);
      // @ts-ignore
      metadataObjectTypeArr.push(camera.MetadataObjectType.HUMAN_HEAD);
    }
    // if (this.mCurrentMode === ModeType.PHOTO &&
    //   this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK) {
    //   metadataObjectTypeArr.push(7);
    // }
    return metadataObjectTypeArr.length > 0 ? metadataObjectTypeArr : undefined;
  }

  public getVideoFrameRate(): number {
    let frameRate = FeatureManager.getInstance().getFunction(FunctionId.FRAME_RATE)?.getValue();
    HiLog.i(TAG, `getVideoFrameRate frameRateIndex: ${frameRate}, frameRate: ${FrameRateOperation.getVideoFrameRate(frameRate)}.`);
    return <number> FrameRateOperation.getVideoFrameRate(frameRate);
  }

  public getPreviewDisplaySize(givenMode?: ModeType, width?: number, height?: number,
    orientationVertical?: boolean): Size {
    let mode = givenMode ? givenMode : this.mCurrentMode;
    let previewRatio: number = null;
    if (OutputOperation.isPanVideoOutput(mode)) {
      let videoResolution = FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION)?.getValue();
      let previewSize = VideoResolutionOperation.getPreviewProfile(videoResolution, this.mCameraPosition, mode)?.size;
      if (!previewSize) {
        HiLog.w(TAG, 'getPreviewProfile undefined...');
        return { width: -1, height: -1 };
      }
      previewRatio = previewSize.width / previewSize.height;
    } else {
      let aspectRatio = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO)?.getValue();
      let previewSize = AspectRatioOperation.getPreviewProfile(aspectRatio, this.mCameraPosition, mode)?.size;
      if (!previewSize) {
        HiLog.w(TAG, 'getPreviewProfile undefined...');
        return { width: -1, height: -1 };
      }
      previewRatio = previewSize.width / previewSize.height;
    }
    let xComponentSize = DisplayCalculator.calcSurfaceDisplaySize(previewRatio, width, height, orientationVertical);
    HiLog.i(TAG,
      `getPreviewDisplaySize invoke, previewRatio: ${previewRatio}, xComponentSize: ${JSON.stringify(xComponentSize)}.`);
    return xComponentSize;
  }

  public getSemiDisplaySize(givenMode?: ModeType): Size {
    let fullSize: Size = this.getPreviewDisplaySize(givenMode);
    const displayWidth = getStates().get<number>('windowReducer', 'windowWidth');
    const semiWidth = displayWidth / 2;
    const semiHeight = semiWidth * (fullSize.height / fullSize.width);
    return { width: semiWidth, height: semiHeight };
  }

  public getSurfaceSize(currentMode: ModeType): image.Size {
    let previewProfile: camera.Profile;
    if (OutputOperation.isPanVideoOutput(currentMode)) {
      let videoResolution = FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION)?.getValue();
      previewProfile = VideoResolutionOperation.getPreviewProfile(videoResolution, this.mCameraPosition, currentMode);
    } else {
      let aspectRatio = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO)?.getValue();
      previewProfile = AspectRatioOperation.getPreviewProfile(aspectRatio, this.mCameraPosition, currentMode);
    }
    return { height: previewProfile.size.height, width: previewProfile.size.width };
  }

  public getVideoMessage(data: { zoomRatio?: number, keepVideoFlowing?: boolean, isVideoRotation?: boolean } = {
  }): VideoOutputMessage {
    let frameRate: number = this.getVideoFrameRate();
    let isHdr: boolean = this.getIsHdrVividFlag();
    const resolution = this.getResolution();
    let videoProfile =
      VideoResolutionOperation.getVideoProfile(resolution, this.mCameraPosition, this.mCurrentMode, frameRate);
    const isTempMessage: boolean = !videoProfile;
    // 当非录像模式下获取录像配置信息，得到默认配置文件
    if (isTempMessage) {
      HiLog.i(TAG, 'getVideoMessage undefined, get default profile and config.');
      videoProfile =
        VideoResolutionOperation.getVideoProfile(resolution, this.mCameraPosition, ModeType.VIDEO, frameRate);
    }
    HiLog.i(TAG, `getVideoProfile end, VideoProfile: ${JSON.stringify(videoProfile)}.`);

    const isMovie: boolean = RecordController.getInstance().isMovieFile();
    const config: media.AVRecorderConfig = isTempMessage ?
      RecorderConfigOperation.getDefaultConfig(videoProfile, frameRate) :
      RecorderConfigOperation.createVideoConfig(videoProfile, frameRate, isHdr);
    let mirrorValue: boolean = false;
    if (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      mirrorValue = FeatureManager.getInstance().getFunction(FunctionId.MIRROR)?.getValue();
    }
    const videoMessage: VideoOutputMessage = {
      videoProfile,
      config,
      mirrorValue,
      isSupportVideoEdit:
      CameraAppCapability.getInstance().getIsSupportRecordingFlowing(),
      isSupportVideoWatermark: false,
      isMovie,
      isFlowingVideo: false,
      preferencesMirror: <boolean> PreferencesService.getInstance()
        .getFunctionValue(PersistType.FOREVER, FunctionId.MIRROR, true),
      keepVideoFlowing: data?.keepVideoFlowing,
      isVideoRotation: data?.isVideoRotation,
    };
    HiLog.i(TAG, `getVideoMessage : ${JSON.stringify(videoMessage)}`);
    return videoMessage;
  }

  private handleCaching(data: { keepVideoFlowing?: boolean }, frameRate: number, isHdr: boolean,
    resolution: any): void {
    if (!data.keepVideoFlowing) {
      HiLog.i(TAG, 'Start caching frameRate and hdr');
      this.mCacheFrameRate = frameRate;
      this.mCacheHdr = isHdr;
      this.mCacheVideoResolution = resolution;
    } else {
      HiLog.i(TAG, 'Use cached frameRate and hdr');
      frameRate = this.mCacheFrameRate;
      isHdr = this.mCacheHdr;
    }
  }

  public getPreviewRecordMessage(): PreviewRecordOutputMessage {
    HiLog.i(TAG, 'getPreviewRecordMessage begin.');
    const frameRate: number = this.getVideoFrameRate();
    let aspectRatio = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO)?.getValue();
    let previewRecordProfile =
      AspectRatioOperation.getPreviewProfile(aspectRatio, this.mCameraPosition, this.mCurrentMode);
    HiLog.i(TAG, `getPreviewRecordMessage`);
    const config: media.AVRecorderConfig =
      RecorderConfigOperation.createPreviewRecordConfig(previewRecordProfile, frameRate);
    HiLog.i(TAG, `getPreviewRecordMessage end`);
    return {
      config: config,
      isAddWaterMark: false,
      isSupportFrontWaterMark: false,
    };
  }

  public getTimelapseRecordMessage(): TimeLapseRecordOutputMessage {
    return undefined;
    HiLog.i(TAG, 'getTimelapseRecordMessage begin.');
    const frameRate: number = 30;
    const resolution = this.getResolution();
    let timelapseProfile =
      VideoResolutionOperation.getVideoProfile(resolution, this.mCameraPosition, this.mCurrentMode, frameRate);
    HiLog.i(TAG, `getTimelapseRecordMessage, timelapseRecordProfile: ${timelapseProfile}.`);
    const config: media.AVRecorderConfig =
      RecorderConfigOperation.createTimelapseRecordConfig(timelapseProfile, frameRate, false);
    HiLog.i(TAG, `getTimelapseRecordMessage end, AVRecorderConfig: ${config}`);
    return {
      config: config,
    };
  }

  private getZoomRatioValue(quickZoomArray: number[], data: {
    zoomRatio?: number,
    superMacroEnable?: boolean,
    watchMoonEnable?: boolean
  } = {}): number {
    if (data.zoomRatio &&
      (this.mCameraPosition === camera.CameraPosition.CAMERA_POSITION_FRONT)) {
      HiLog.d(TAG, `zoom ratio two value: ${data.zoomRatio}`);
      return data.zoomRatio;
    } else {
      HiLog.d(TAG, `zoom ratio three value: 1`);
      return 1;
    }
  }

  private getAspectRatio(): number {
    const aspect = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO)?.getValue() as number;
    return aspect;
  }


  private getIsP3Flag(): boolean { // TagMessage带参下发到启流过程中配置ColorSpace即可
    if (OutputOperation.isPanPhotoOutput(this.mCurrentMode)) {
      return true; // 目前泛拍照模式默认支持P3广色域,后续可能支持用户选择
    }
    return undefined;
  }

  private getResolution(): SettingFuncDialogItemIndex {
    const videoResolution = FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION)?.getValue();
    return videoResolution as SettingFuncDialogItemIndex;
  }

  private confirmCapture(): void {
    this.mCameraProxy.confirmCapture();
  }

  private setMeteringPoint(data: { exposurePoint: PositionType }): void {
    this.mCameraProxy.setMeteringPoint(data.exposurePoint);
  }

  private setFocusPoint(focusData: FocusData): void {
    this.mCameraProxy.setFocus(focusData);
    if (focusData.focusPoint) {
      this.mCameraProxy.setMeteringPoint(focusData.focusPoint);
    }
  }

  private async handleZoomVibrator(data: {
    effectId: string,
    usage: string
  }): Promise<void> {
    this.mCameraProxy.handleZoomVibrator(data.effectId, data.usage);
  }

  private async stopZoomVibrator(): Promise<void> {
    this.mCameraProxy.stopZoomVibrator();
  }

  private async setCameraShotKey(data: { cameraShotKey: string }): Promise<void> {
    let recordingState = getStates().get<RecordingState>('recordReducer', 'recordingState');
    this.mCameraProxy.setCameraShotKey(data.cameraShotKey, this.mCurrentMode, recordingState);
  }

  public destroy(): void {
    HiLog.i(TAG, `CameraBasicService destroy invoke, context name: ${ContextManager.getInstance().getModuleName()}.`);
    this.mEventBus.clear(this.mBase.hashCode());
  }


  private getMirror(): boolean {
    return FeatureManager.getInstance().getFunction(FunctionId.MIRROR)?.getValue();
  }

  private getSupportAudioStage(): boolean {
    return false;
  }

  private getIsSupportOnlyShowEye(): boolean {
    return CameraAppCapability.getInstance().getIsSupportOnlyShowEye();
  }


  private async setDirection(data: {
    direction: number,
    rotate: number,
    settingAngle: number
  }): Promise<void> {
    data.rotate = data.rotate % ANGLE_360;
    this.mCameraProxy.setDirection(data);
  }

  private async onNewWant(): Promise<void> {
    const callBundleName: string = GlobalContext.get().getCameraAbilityWant().parameters?.callBundleName as string;
    const callBundleNameNew: string = GlobalContext.get()?.getCameraNewWant()?.parameters?.callBundleName as string;
    HiLog.i(TAG, `onNewWant ${callBundleName}, ${callBundleNameNew}`);
    if (callBundleNameNew != callBundleName) {
      GlobalContext.get().setCameraAbilityWant(GlobalContext.get()?.getCameraNewWant());
    }
    if (!!callBundleNameNew && callBundleName != callBundleNameNew) {
      const pickerInfo: PickerInfo = PickerUiService.getInstance()
        .getPickerInfo(GlobalContext.get()?.getCameraNewWant());
      await this.close({}); // close后再安排，是为了走上一个宿主应用的close流程，解除权限占用，后面再更新pickerInfo后进行start
      GlobalContext.get().setObject('pickerInfo', pickerInfo);
      this.mCameraProxy.refreshPickerInfo(pickerInfo);
      this.warmStartup();
    }
  }

  private onKeepUsingStellarLenses(): void {
    HiLog.i(TAG, 'onKeepUsingStellarLenses');
    this.mCameraProxy.keepUsingStellarLenses();
  }

  private async windowStatusChange(): Promise<void> {
    if (this.isForeground) {
      HiLog.i(TAG, 'windowStatusChange started');
      const zoomRatio = ZoomOperation.getInstance().getStartupZoom(this.mCurrentMode, this.mCameraPosition);
      this.mStoreManager.postMessage(CameraAction.started(CameraStartType.COLLAPS_CHANGE, zoomRatio));
      AppStorage.setOrCreate('IsNotCustomFilterLandSupport', undefined);
    }
  }

  private onForeground(): void {
    this.isForeground = true;
  }

  private onBackground(): void {
    this.isForeground = false;
  }

  public getCacheVideoFrameRate(): number {
    return this.mCacheFrameRate;
  }

  public getCacheVideoResolution(): number {
    return this.mCacheVideoResolution;
  }

  private getPreviewRotationInfo(): PreviewRotationInfo {
    if (DeviceInfo.isTv()) {
      return {
        isNeedSetPreviewRotation: true,
        previewRotation: camera.ImageRotation.ROTATION_0,
        isDisplayLocked: false
      };
    } else if (DeviceInfo.isTablet()) {
      return {
        isNeedSetPreviewRotation: true,
        previewRotation: camera.ImageRotation.ROTATION_270,
        isDisplayLocked: false
      };
    }
    return {
      isNeedSetPreviewRotation: false,
      previewRotation: camera.ImageRotation.ROTATION_0,
      isDisplayLocked: false
    }
  }

  private getUsedAsPositionValue(): camera.CameraPosition {

    return camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  }
}