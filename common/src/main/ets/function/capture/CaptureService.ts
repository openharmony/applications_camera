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
import lazy { Action, UiStateMode } from '../../redux/actions/Action';
import type { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { ActionType } from '../../redux/actions/ActionType';
import lazy { CaptureAction } from './CaptureAction';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { systemDateTime } from '../../utils/LazyImportUtil';
import lazy { UIOperationType } from '../../component/uicomponent/UIOperationType';
import lazy { CaptureActionType } from '../../redux/actions/CaptureActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { getStates } from '../../redux';
import lazy { RecordingState } from '../recordcontrol/RecordAction';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { OutputOperation } from '../outputswitcher/OutputOperation';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';

const TAG: string = 'CaptureService';
const CAPTURE_QUEUE_SIZE: number = 1;

export class CaptureService {
  private mBase: BaseComponent = new BaseComponent();
  private static sInstanceCapability: CaptureService;
  private mStoreManager: StoreManager = StoreManager.getInstance();
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mCaptureEnableCount: number = 0;
  private mLastCaptureTime: number = 0;
  private mLastCaptureReadyTime: number = 0;
  private mRichCaptureNext: number = 0; // 连拍场景拍照动作缓存队列

  public static getInstance(): CaptureService {
    if (!CaptureService.sInstanceCapability) {
      CaptureService.sInstanceCapability = new CaptureService();
    }
    return CaptureService.sInstanceCapability;
  }

  constructor() {
    this.mEventBus.on(CaptureActionType.CAPTURE, this.onCapture.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_NIGHT_CAPTURE_START, this.onNightProcessCapture.bind(this), this.mBase.hashCode());
    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.SWITCH_CAMERA, CameraActionType.SWITCH_CAMERA_CHANGE_MODE,
      CameraActionType.STARTED],
      this.resetCaptureEnableCount.bind(this), this.mBase.hashCode());
  }

  private async onCapture(): Promise<void> {
    this.mCaptureEnableCount++;
    this.mLastCaptureTime = await systemDateTime.getRealTime(false);
    HiLog.i(TAG, `SHOT2SEE onCapture captureEnableCount: ${this.mCaptureEnableCount}.`);
  }

  private async onNightProcessCapture(): Promise<void> {
    if (this.mCaptureEnableCount > 0) {
      return;
    }
    this.onCapture();
  }

  public photoSaved(uri: string): void {
    HiLog.i(TAG, `SHOT2SEE photoSaved captureEnableCount: ${this.mCaptureEnableCount}.`);
    this.mStoreManager.postMessage(CaptureAction.photoOnSave(uri));
  }

  public onCaptureAborted(): void {
    StoreManager.getInstance()
      .postMessage(Action.uiStateWithMode(true, UiStateMode.EXCLUDE_COMPONENT, UIOperationType.CAPTURE_BUTTON));
    this.mCaptureEnableCount = this.mCaptureEnableCount > 0 ? this.mCaptureEnableCount - 1 : 0;
    HiLog.i(TAG, `onCaptureAborted mCaptureEnableCount: ${this.mCaptureEnableCount}.`);
  }

  public async onCaptureReady(): Promise<void> {
    this.mCaptureEnableCount = this.mCaptureEnableCount > 0 ? this.mCaptureEnableCount - 1 : 0;
    HiLog.i(TAG, `enableCaptureCount: ${this.mCaptureEnableCount}.`);
    this.mLastCaptureReadyTime = await systemDateTime.getRealTime(false);
    let captureTime: number = this.mLastCaptureReadyTime - this.mLastCaptureTime;
    if (CameraAppCapability.getInstance().getIsSupportedIntervalPhotoCapture()) {
      const mode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
      const timeLapseValue: number =
        FeatureManager.getInstance().getFunction(FunctionId.TIME_LAPSE)?.getValue() as number;
      if (OutputOperation.isPanPhotoOutput(mode) && timeLapseValue === SettingFuncDialogItemIndex.INDEX_FIF) {
        StoreManager.getInstance().postMessage(CaptureAction.isReadyForNextAutoCapture());
      }
    }
    HiLog.i(TAG, `capture cost time: ${captureTime}`);
  }

  private resetCaptureEnableCount(): void {
    this.mRichCaptureNext = 0;
    this.mCaptureEnableCount = 0;
  }

  public isEnableCapture(report: boolean = false): boolean {
    HiLog.i(TAG, `check capture, mCaptureEnableCount: ${this.mCaptureEnableCount}.`);
    // const isEnable = this.mCaptureEnableCount < CAPTURE_QUEUE_SIZE;
    return true;
  }

  public cacheRichCaptureNext(): void {
    HiLog.d(TAG, `cache capture next, mRichCaptureNext: ${this.mRichCaptureNext}.`);
    this.mRichCaptureNext++;
  }

  public queryIsEnableRichCaptureNext(): boolean {
    return this.mRichCaptureNext > 0;
  }

  public clearRichCaptureNext(): void {
    this.mRichCaptureNext = 0;
  }

  public isCancelClickDownCapture(): boolean {
    // clickDown 不生效的场景，按下立即滑动到拍照按钮外的区域，长按进入连拍， 长按进入录像，拦截已经进入这三个场景下返回的比较慢的缩略图
    return getStates().get<boolean>('leftRightSwipeReducer', 'isCancelClickDown') ||
      getStates().get<boolean>('leftRightSwipeReducer', 'longClicked') ||
      getStates().get<RecordingState>('recordReducer', 'recordingState') !== RecordingState.READY;
  }
}