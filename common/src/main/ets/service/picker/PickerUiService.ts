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

import type ability from '@ohos.ability.ability';
import type { BusinessError } from '@ohos.base';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { wantConstant } from '../../utils/LazyImportUtil';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { Action, UiStateMode } from '../../redux/actions/Action';
import lazy { CameraProxy } from '../../camera/uithread/CameraProxy';
import lazy { ModeType } from '../../mode/ModeType';
import type Want from '@ohos.app.ability.Want';
import lazy { WorkerTask } from '../../camera/WorkerTask';
import type { CollaborationFdData, PhotoInfoStruct, PickerInfo } from '../../utils/types';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import type { EventBus } from '../../worker/eventbus/EventBus';
import lazy { ContextManager } from '../context/ContextManager';
import lazy { image } from '@kit.ImageKit';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { CameraAction } from '../../camera/uithread/CameraAction';
import lazy { OutputOperation } from '../../function/outputswitcher/OutputOperation';
import lazy { privacyManager } from '../../utils/LazyImportUtil';
import lazy { uiExtensionHost } from '@kit.ArkUI';
import lazy { getStates } from '../../redux';
import lazy { CaptureActionType } from '../../redux/actions/CaptureActionType';
import lazy { ThumbnailActionType } from '../../redux/actions/ThumbnailActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { appManager } from '@kit.AbilityKit';
import type common from '@ohos.app.ability.common';
import lazy photoAccessHelper from '@ohos.file.photoAccessHelper';

/* instrument ignore file */
const TAG: string = 'PickerUiService';
const APP_STATE_EXIT_CODE: number = 5;
const ABILITY_TYPE_UI_EXTENTION: number = 5; // UIExtention 拉起

export interface PickerShowMsg {
  showPicker: boolean;
  needRestart: boolean;
}

export class PickerUiService {
  private static mInstance: PickerUiService;
  private static capturing: boolean = false;
  private noConfirm: boolean = true;
  // 落盘前的预览图
  private thumbnail: image.PixelMap;
  // 当前要落盘的uri
  private uri: string;
  private needRestart: boolean = false;
  public static isCameraActive: boolean = true;
  private pickerWindowProxy: uiExtensionHost.UIExtensionHostWindowProxy;
  private isVideoReady: boolean = false;
  private videoTimeBeforeCollapsing: number = 0;
  private appStateObserverId: number = -1; // 用于记录注册调用者生命周期

  private constructor() {
    const eventbus: EventBus = EventBusManager.getInstance().getEventBus();
    eventbus.on(ActionType.ACTION_UPDATE_COLLABORATION_PHOTO_INFO, () => this.updateCollaborationPhotoInfo(), TAG);
    eventbus.on(CaptureActionType.CAPTURE, () => this.updateCaptureState(true), TAG);
    eventbus.on([ThumbnailActionType.RECEIVED, CameraActionType.STARTED], () => this.updateCaptureState(false), TAG);
    eventbus.on(ActionType.ACTION_SHOW_PICKER, (data: PickerShowMsg) => this.handleCameraCloseOrOpen(data), TAG);
  }

  public static getInstance(): PickerUiService {
    if (!PickerUiService.mInstance) {
      PickerUiService.mInstance = new PickerUiService();
    }
    return PickerUiService.mInstance;
  }

  public handleCameraCloseOrOpen(data?: PickerShowMsg): void {
    this.needRestart = data?.needRestart ?? this.needRestart;
    HiLog.i(TAG, `handleCameraCloseOrOpen: ${PickerUiService.isCameraActive}, needRestart: ${this.needRestart}`);
    if (PickerUiService.isCameraActive) {
      this.needRestart = false;
      return;
    }
    if (this.needRestart) {
      PickerUiService.isCameraActive = true;
      this.needRestart = false;
      StoreManager.getInstance().postMessage(CameraAction.warmStart());
    }
  }

  public back(): void {
    HiLog.i(TAG, 'onCancelClicked called!.');
    StoreManager.getInstance().postMessage(Action.uiStateWithMode(true, UiStateMode.EXCLUDE_PREVIEW));
    this.collaborationResolute();
    this.terminateSelfWithResult();
  }

  private collaborationResolute(): void {
    if (!DeviceInfo.isPhone() && !DeviceInfo.isTablet()) {
      HiLog.w(TAG, 'collaborationResolute devicetype not match return');
      return;
    }
  }

  /*
   * 用户点击确认时去子线程往uri存buffer,然后terminateSelfWithResult
   */
  public async backAfterCapture(isPhoto: boolean, resourceUri: string, bundleName: string): Promise<void> {
    HiLog.i(TAG, `backAfterCapture uri: ${resourceUri}`);
    if (isPhoto) {
      HiLog.begin(TAG, 'backAfterCapture savePickerFile');
      const uriInfo: {
        uri: string,
        uriFromLocal: boolean,
        errorMessage: string
      } = await CameraProxy.getInstance().savePickerFile();
      HiLog.end(TAG, 'backAfterCapture savePickerFile');
      StoreManager.getInstance().postMessage(Action.updateShowPickerView(false));
      HiLog.begin(TAG, 'backAfterCapture terminateSelfWithResult');
      this.terminateSelfWithResult(0, uriInfo.uri, ModeType.PHOTO, uriInfo.errorMessage, uriInfo.uriFromLocal);
      HiLog.end(TAG, 'backAfterCapture terminateSelfWithResult');
    } else {
      StoreManager.getInstance().postMessage(Action.updateShowPickerView(false));
      const pickerInfo: PickerInfo = GlobalContext.get().getObject('pickerInfo') as PickerInfo;
      const needPermission = !pickerInfo.uri;
      const uri = pickerInfo.uri || resourceUri;
      this.terminateSelfWithResult(0, uri, ModeType.VIDEO, '', needPermission);
    }
  }

  /* instrument ignore next */
  public async grantPermissionForUri(context: common.Context, tokenId: number,
    uri: string, hideSensitiveType?: photoAccessHelper.HideSensitiveType): Promise<number | undefined> {
    let result: number | undefined = undefined;
    let helper: photoAccessHelper.PhotoAccessHelper | undefined = undefined;
    try {
      helper = photoAccessHelper.getPhotoAccessHelper(context);
      if (uri) {
        HiLog.i(TAG, `grantPermissionForUris tokenId:${tokenId}`);
        result = await helper?.grantPhotoUriPermission(
          tokenId,
          uri,
          photoAccessHelper.PhotoPermissionType.PERSISTENT_READ_IMAGEVIDEO,
          hideSensitiveType ? hideSensitiveType : photoAccessHelper.HideSensitiveType.NO_HIDE_SENSITIVE_TYPE);
      }
    } catch (error) {
      HiLog.e(TAG, `grantPermissionForUris has error: ${error}, code: ${error?.code}`);
    } finally {
      helper?.release();
      HiLog.i(TAG, `grantPermissionForUris finished tokenId:${tokenId}`);
    }
    return result;
  }


  private async getAbilityResult(resultCode: number = -1, resourceUri: string = '', mode = undefined, errorMessage = '',
    needPermission = false): Promise<ability.AbilityResult> {
    const abilityResult: ability.AbilityResult = {
      resultCode: resultCode,
      want: {
        parameters: {
          errorMessage,
        }
      }
    };
    if (!errorMessage) {
      abilityResult.want.parameters = { resourceUri: resourceUri, mode };
    }
    if (needPermission) {
      // abilityResult.want.uri = resourceUri;
      abilityResult.want.flags = wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION;

      let parameters: object = GlobalContext.get().getCameraAbilityWant().parameters as object;
      let callingTokenID: number = parameters['ohos.aafwk.param.callerToken'] as number;
      HiLog.i(TAG, `callingTokenID : ${callingTokenID}`);
      await this.grantPermissionForUri(ContextManager.getInstance().getUiContext(), callingTokenID, resourceUri);
    }
    HiLog.i(TAG, 'getAbilityResult end');
    return abilityResult;
  }

  public async terminateSelfWithResult(resultCode: number = -1, resourceUri: string = '', mode = undefined,
    errorMessage = '', needPermission = false): Promise<void> {
    HiLog.i(TAG, 'terminateSelfWithResult getAbilityResult.');
    const abilityResult: ability.AbilityResult = await this.getAbilityResult(resultCode, resourceUri, mode,
      errorMessage, needPermission);
    this.noConfirm = false;
    HiLog.i(TAG, 'terminateSelfWithResult get context.');
    const context = ContextManager.getInstance();
    HiLog.i(TAG, 'terminateSelfWithResult get session.');
    const session = context.getUiExtensionSession() || context.getUiContext();
    HiLog.i(TAG, 'terminateSelfWithResult start.');
    try {
      session.terminateSelfWithResult(abilityResult);
      HiLog.i(TAG, 'terminateSelfWithResult end.');
    } catch (error) {
      HiLog.e(TAG, `terminateSelfWithResult: ${error?.code}.`);
    }
  }

  public async resetURIContent(): Promise<void> {
    const mode = getStates().get<ModeType>('modeReducer', 'mode');
    if (this.noConfirm && mode === ModeType.VIDEO) {
      CameraProxy.getInstance().deletePickerVideoFile();
    }
  }

  public dealPicker(want: Want): void {
    HiLog.i(TAG, 'dealPicker begin.');
    if (!want || want.action === 'action.system.home' ||
      !want.parameters?.callFlag ||
      want.parameters?.callFlag as string !== 'remote') {
      HiLog.e(TAG, 'CameraAbility is not picker.');
      return;
    }
    const action: string = want.action;
    HiLog.i(TAG, `cameraAbilityWant action: ${action}.`);
    HiLog.i(TAG, `dealPicker end, action: ${action}.`);
  }

  private updateCollaborationPhotoInfo(): void {
    HiLog.begin(TAG, 'updateCollaborationPhotoInfo');
    const want: Want = GlobalContext.get().getCameraAbilityWant();
    if (!want ||
      !want.parameters?.callFlag ||
      want.parameters?.callFlag as string !== 'remote') {
      HiLog.e(TAG, 'CameraAbility is not picker.');
      return;
    }
    HiLog.end(TAG, 'updateCollaborationPhotoInfo');
  }

  public setThumbnail(thumbnail: image.PixelMap): void {
    if (!thumbnail) {
      return;
    }
    if (this.thumbnail) {
      this.thumbnail?.release();
    }
    this.thumbnail = thumbnail;
  }

  public getThumbnail(): image.PixelMap {
    return this.thumbnail;
  }

  public setUri(uri: string): void {
    this.uri = uri;
  }

  public getUri(): string {
    return this.uri;
  }

  private updateCaptureState(state: boolean): void {
    HiLog.i(TAG, `updateCaptureState capturing: ${state}.`);
    PickerUiService.capturing = state;
  }

  public getCaptureState(): boolean {
    return PickerUiService.capturing;
  }

  /**
   * 拉起picker时添加一次访问记录，重拍重录等操作不额外增加
   */
  public addPickerVisitLog(): void {
    try {
      let parameters: object = GlobalContext.get().getCameraAbilityWant().parameters as object;
      if (!parameters) {
        HiLog.i(TAG, 'parameters is undefined !');
        return;
      }
      let callingTokenID: number = parameters['ohos.aafwk.param.callerToken'] as number;
      HiLog.i(TAG, `callingTokenID : ${callingTokenID}`);
      privacyManager.addPermissionUsedRecord(
        callingTokenID, 'ohos.permission.CAMERA', 1, 0, { usedType: privacyManager.PermissionUsedType.PICKER_TYPE })
        .then(() => {
          GlobalContext.get().setObject('needAddPickerVisitLog', false);
          HiLog.i(TAG, 'addPermissionUsedRecord success');
        });
    } catch (err) {
      HiLog.e(TAG, `addPermissionUsedRecord fail err: ${err?.code}`);
    }
  }

  public saveUriAndThumbnail(thumbnail: image.PixelMap): void {
    const state = getStates();
    const isPhoto = OutputOperation.isPanPhotoOutput(state.get<ModeType>('modeReducer', 'mode'));
    this.uri =
      isPhoto ? state.get<string>('captureReducer', 'resourceUri') : state.get<string>('recordReducer', 'videoUri');
    this.setThumbnail(thumbnail);
  }

  public setNoConfirm(noConfirm: boolean): void {
    this.noConfirm = noConfirm;
  }

  public setPickerWindowProxy(pickerWindowProxy: uiExtensionHost.UIExtensionHostWindowProxy): void {
    this.pickerWindowProxy = pickerWindowProxy;
  }

  public getPickerWindowProxy(): uiExtensionHost.UIExtensionHostWindowProxy {
    return this.pickerWindowProxy;
  }

  public getVideoTimeBeforeCollapsing(): number {
    return this.videoTimeBeforeCollapsing;
  }

  public setVideoTimeBeforeCollapsing(videoTimeBeforeCollapsing: number): void {
    this.videoTimeBeforeCollapsing = videoTimeBeforeCollapsing;
  }

  private applicationStateObserver: appManager.ApplicationStateObserver = {
    onForegroundApplicationChanged(appStateData) {
      HiLog.i(TAG, `[appManager] onForegroundApplicationChanged: ${JSON.stringify(appStateData)}`);
    },
    onAbilityStateChanged(abilityStateData) {
      HiLog.i(TAG, `[appManager] onAbilityStateChanged: ${JSON.stringify(abilityStateData)}`);
      if (abilityStateData.state === APP_STATE_EXIT_CODE &&
        abilityStateData.abilityType !== ABILITY_TYPE_UI_EXTENTION) {
        HiLog.i(TAG, 'the picker client is died, exit now');
        PickerUiService.getInstance().terminateSelfWithResult();
      }
    },
    onProcessCreated(processData) {
      HiLog.i(TAG, `[appManager] onProcessCreated: ${JSON.stringify(processData)}`);
    },
    onProcessDied(processData) {
      HiLog.i(TAG, `[appManager] onProcessDied: ${JSON.stringify(processData)}`);
    },
    onProcessStateChanged(processData) {
      HiLog.i(TAG, `[appManager] onProcessStateChanged: ${JSON.stringify(processData)}`);
    },
    onAppStarted(appStateData) {
      HiLog.i(TAG, `[appManager] onAppStarted: ${JSON.stringify(appStateData)}`);
    },
    onAppStopped(appStateData) {
      HiLog.i(TAG, `[appManager] onAppStopped: ${JSON.stringify(appStateData)}`);
    }
  };

  public registerApplicationStateObserver(): void {
    HiLog.i(TAG, 'registerApplicationStateObserver begin');
    this.unRegisterApplicationStateObserver();
    let parameters: object = GlobalContext.get().getCameraAbilityWant().parameters as object;
    if (!parameters) {
      HiLog.i(TAG, 'parameters is undefined !');
      return;
    }
    let callBundleName: string = parameters['callBundleName'] as string;
    let bundleNameList = [callBundleName];

    try {
      this.appStateObserverId = appManager.on('applicationState', this.applicationStateObserver, bundleNameList);
      HiLog.i(TAG, `[appManager] observerCode: ${this.appStateObserverId}`);
    } catch (paramError) {
      let code = (paramError as BusinessError).code;
      let message = (paramError as BusinessError).message;
      HiLog.e(TAG, `[appManager] error: ${code}, ${message}`);
    }
    HiLog.i(TAG, 'registerApplicationStateObserver end');
  }

  public unRegisterApplicationStateObserver(): void {
    if (this.appStateObserverId === -1) {
      HiLog.i(TAG, 'observerId is -1 return');
    }
    HiLog.i(TAG, 'unregisterApplicationStateObserver begin');
    // 2.注销应用状态监听器
    try {
      appManager.off('applicationState', this.appStateObserverId).then((data) => {
        HiLog.i(TAG, `unregisterApplicationStateObserver success, data: ${data}`);
      }).catch((err: BusinessError) => {
        HiLog.e(TAG, `unregisterApplicationStateObserver fail, err: ${err?.code}`);
      });
      this.appStateObserverId = -1;
    } catch (paramError) {
      let code = (paramError as BusinessError).code;
      let message = (paramError as BusinessError).message;
      HiLog.e(TAG, `[appManager] error: ${code}, ${message}`);
    }
    HiLog.i(TAG, 'unregisterApplicationStateObserver end');
  }

  public getPickerInfo(want: Want): PickerInfo {
    let pickerInfo: PickerInfo = {
      isPicker: false,
      uri: '',
      callingTokenID: -1,
      callerPid: -1
    };
    let callingTokenID: number = -1;
    let callerPid: number = -1;
    try {
      callingTokenID = want?.parameters['ohos.aafwk.param.callerToken'] as number;
      callerPid = want?.parameters['ohos.aafwk.param.callerPid'] as number;
    } catch (err) {
      HiLog.e(TAG, 'get callerToken fail');
      callingTokenID = -1;
      callerPid = -1;
    }
    pickerInfo.callingTokenID = callingTokenID;
    pickerInfo.callerPid = callerPid;
    pickerInfo.uri = want?.uri;
    pickerInfo.isPicker = true;
    return pickerInfo;
  }

  /**
   * Picker进程销毁，传入调用者信息 主线程兜底（picker拍照确认后，close指令走不到子线程，线程就结束了）
   */
  public stopUsingPermission(pickerInfo: PickerInfo): void {
    if (!pickerInfo?.isPicker) {
      return;
    }
    try {
      HiLog.i(TAG, 'stopUsingPermission on destroy trigger');
      const callingTokenID: number = pickerInfo.callingTokenID; // callingTokenID as number;
      const callerPid: number = pickerInfo?.callerPid;
      HiLog.i(TAG, `stopUsingPermission callingTokenID : ${callingTokenID}`);
      if (!callingTokenID) {
        return;
      }
      privacyManager.stopUsingPermission(callingTokenID, 'ohos.permission.CAMERA', callerPid)
        .then(() => {
          HiLog.i(TAG, 'stopUsingPermission CAMERA success');
        });
    } catch (err) {
      HiLog.e(TAG, `stopUsingPermission CAMERA fail err: ${err?.code}`);
    }
  }
}