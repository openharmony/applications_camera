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

import lazy { ZoomAction } from './ZoomAction';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { BaseFunction } from '../core/BaseFunction';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { ValueSet } from '../core/ValueSet';
import lazy { ConflictParam } from '../core/ConflictParam';
import lazy { FlashMode } from '../../function/enumbase/FlashMode';
import lazy { CameraAction, CameraStartType } from '../../camera/uithread/CameraAction';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';
import lazy { RenderType } from '../core/functionproperty/RenderType';
import lazy { UiElement } from '../core/UiElement';
import lazy { ModeType } from '../../mode/ModeType';
import camera from '@ohos.multimedia.camera';
import lazy { ZoomOperation } from './ZoomOperation';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { TreasureBoxAction } from '../../component/treasurebox/reduce/TreasureBoxAction';
import lazy { getCloseFlashZoom, isNeedHideFlashIcon } from '../../utils/FileReadUtil';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import lazy { PropTag } from '../../service/preferences/PropTag';
import lazy { PersistType } from '../../service/preferences/PreferencesService';
import lazy { getStates } from '../../redux';
import lazy { OutputSwitcher } from '../outputswitcher/OutputSwitcher';
import lazy { execAction } from '../../redux/ActionRegistry';
import lazy { FunctionActionType } from '../../redux/actions/FunctionActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { ContextActionType } from '../../redux/actions/ContextActionType';
import lazy { ZoomParam } from './ZoomParam';

const TAG: string = 'ZoomFunction';

export type ModeData = {
  mode?: ModeType;
  cameraPosition?: camera.CameraPosition;
};

export type CameraStartedData = {
  type: CameraStartType,
  zoomRatio?: number
};

// 变焦
export class ZoomFunction extends BaseFunction {
  private static readonly ZOOM_RATIO_DEFAULT: number = 1;
  private static readonly ZOOM_RATIO_LENGTH: number = 2;
  private static readonly ZOOM_REMAIN_HOLDING_TIME: number = 5;
  private static readonly ZOOM_CONSTANT_TEN: number = 10;
  private static readonly ZOOM_RATIO_CLOSE_FLASH: number = getCloseFlashZoom();
  private static readonly isNeedHideFlashIcon: boolean = isNeedHideFlashIcon();
  private mZoomRatio: number = 1;
  private catchZoomRatio: number = 0;
  private readonly RENDER_LOCATIONS: RenderLocation[] = [RenderLocation.NONE];
  private conflictParam: ConflictParam;
  private unprepareZoomTimerId: number = Number.MAX_VALUE;

  getFunctionId(): FunctionId {
    return FunctionId.ZOOM;
  }

  getDefaultValue(): number {
    return ZoomFunction.ZOOM_RATIO_DEFAULT;
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

  // 加入isUnprepareZoom，与isPrepareZoom区分开，根据各自是否为true决定下发prepare还是unprepare
  // 加入isSmoothZoom决定是否走smoothZoom
  // 1、当zoomRadio为undefined时，根据isPrepareZoom和isUnprepareZoom谁为true时下发，原则上不支持此时同为true，同时为true时只生效isPrepareZoom
  // 2、当zoomRadio有值时，根据isPrepareZoom和isUnprepareZoom是否为true决定是否下发prepare和unprepare，且必定在下发zoomRadio前后下发
  setValue(inputValue: {
    zoomRatio?: number,
    isPrepareZoom?: boolean,
    isSmoothZoom?: boolean,
    isUnprepareZoom?: boolean,
    unprepareDelay?: number
  }): void {
    HiLog.d(TAG, `setValue inputValue: ${JSON.stringify(inputValue)}.`);
    if (inputValue === undefined || inputValue?.zoomRatio === undefined && inputValue?.isPrepareZoom === undefined &&
      inputValue?.isUnprepareZoom === undefined) {
      return;
    }
    if (this.unprepareZoomTimerId !== Number.MAX_VALUE) {
      clearTimeout(this.unprepareZoomTimerId);
      this.unprepareZoomTimerId = Number.MAX_VALUE;
    }
    if (inputValue?.zoomRatio === undefined) {
      if (inputValue?.isPrepareZoom) {
        this.mCameraProxy.prepareOrUnPrepareZoom(true);
      } else if (inputValue?.isUnprepareZoom) {
        this.unprepareZoom(inputValue.unprepareDelay);
      }
      return;
    }
    let oldZoomRatio = this.mZoomRatio;
    this.mZoomRatio = inputValue?.zoomRatio;
    if (inputValue?.isPrepareZoom) {
      this.mCameraProxy.prepareOrUnPrepareZoom(true);
    }

    const isForeground = getStates().get<boolean>('contextReducer', 'isForeground');
    if (isForeground) {
      if (inputValue?.isSmoothZoom) {
        this.mCameraProxy.setSmoothZoom(inputValue?.zoomRatio);
      } else {
        this.mCameraProxy.setZoomRatio(inputValue?.zoomRatio);
      }
    }
    if (inputValue?.isUnprepareZoom) {
      this.unprepareZoom(inputValue.unprepareDelay);
    }
    this.mStoreManager.postMessage(ZoomAction.updateStateZoomRatio(inputValue?.zoomRatio)); // UI数据唯一入口
    this.conflictFlashManage(oldZoomRatio, this.mZoomRatio);
    this.controlLivePhotoManage(oldZoomRatio, this.mZoomRatio);
  }

  private unprepareZoom(delay?: number): void {
    if (delay) {
      this.unprepareZoomTimerId = setTimeout(() => {
        this.mCameraProxy.prepareOrUnPrepareZoom(false);
        this.unprepareZoomTimerId = Number.MAX_VALUE;
      }, delay);
    } else {
      this.mCameraProxy.prepareOrUnPrepareZoom(false);
    }
  }

  getValue(): number {
    return this.mZoomRatio;
  }

  load(renderLocations: RenderLocation[]): void {
    super.load(renderLocations);
    this.mEventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM, this.onConflictParamChange.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.zoomOnCameraStarted.bind(this), this.mBase.hashCode());
    this.mEventBus.on([CameraActionType.CHANGE_MODE, CameraActionType.CHANGE_OUTPUT_TYPE,
      CameraActionType.SWITCH_CAMERA, CameraActionType.SWITCH_CAMERA_CHANGE_MODE],
      this.resetZoomRatio.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_BACKGROUND, this.initZoomControlLiveState.bind(this),
      this.mBase.hashCode());
    this.onLoadFunction(); // 冷启动时，CameraActionStarted事件处理完了 该Function还没加载.
    HiLog.i(TAG, 'load X.');
  }

  private onLoadFunction(): void {
    HiLog.i(TAG, 'onLoadFunction X.');
    this.mZoomRatio = ZoomOperation.getDefaultZoomRatio(getStates().get<ModeType>('modeReducer', 'mode'),
      getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition'));
    this.mStoreManager.postMessage(ZoomAction.updateStateZoomRatio(this.mZoomRatio));
  }

  unload(renderLocations: RenderLocation[]): void {
    super.unload(renderLocations);
    HiLog.i(TAG, 'unload E.');
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'unload X.');
  }

  // zoom 2x --> 闪光灯互斥
  private conflictFlashManage(oldZoomRatio: number, zoomRatio: number, type?: CameraStartType): void {
    oldZoomRatio = Math.round(oldZoomRatio * ZoomFunction.ZOOM_CONSTANT_TEN) / ZoomFunction.ZOOM_CONSTANT_TEN;
    zoomRatio = Math.round(zoomRatio * ZoomFunction.ZOOM_CONSTANT_TEN) / ZoomFunction.ZOOM_CONSTANT_TEN;
    if (((oldZoomRatio > ZoomFunction.ZOOM_RATIO_CLOSE_FLASH && zoomRatio > ZoomFunction.ZOOM_RATIO_CLOSE_FLASH) ||
      (oldZoomRatio <= ZoomFunction.ZOOM_RATIO_CLOSE_FLASH && zoomRatio <= ZoomFunction.ZOOM_RATIO_CLOSE_FLASH)) &&
      (type !== CameraStartType.CHANGE_MODE && type !== CameraStartType.SWITCH_CAMERA_CHANGE_MODE)) {
      return;
    }
    if (!ZoomFunction.isNeedHideFlashIcon) {
      // 如果不隐藏闪光灯图标, 不走下面的冲突逻辑, 超过10x自动关闭, 切回10x以下恢复
      this.handleFlashModeWhenAlwaysShowAllFlashIcon(zoomRatio);
      return;
    }
    this.conflictParam = ConflictParam.emptyParam();
    // 为了保证展示的zoomRatio 和 冲突管理判断的 zoomRatio 数据一致
    if (zoomRatio > ZoomFunction.ZOOM_RATIO_CLOSE_FLASH) {
      const off: unknown = FlashMode.OFF;
      const open: unknown = FlashMode.ALWAYS_OPEN;
      this.conflictParam =
        new ConflictParam().setLimitedValueSet(new ValueSet().setValues([<string> off, <string> open]));
    }
    this.mStoreManager.postMessage(TreasureBoxAction.updateByZoomChanged());
    HiLog.i(TAG,
      `conflictFlashManage: ${this.conflictParam?.limitedValue?.getValues().toString()}, zoom: ${zoomRatio}.`);
    this.mConflictManager.setConflictParam(FunctionId.FLASH, this.conflictParam);
  }

  /* instrument ignore next */
  private handleFlashModeWhenAlwaysShowAllFlashIcon(zoomRatio: number): void {
    let flashStatus: number = FeatureManager.getInstance().getFunction(FunctionId.FLASH).getValue();
    HiLog.i(TAG, `handleFlashMode, ${ZoomFunction.ZOOM_RATIO_CLOSE_FLASH}, flashStatus = ${flashStatus}`);
    let isClose: boolean = false;
    const isAutoCloseFlash: boolean = this.mPreferencesService
      .getPropValue(PersistType.FOREVER, PropTag.IS_AUTO_CLOSE_FLASH, false) as boolean;
    if (zoomRatio > ZoomFunction.ZOOM_RATIO_CLOSE_FLASH) {
      if (flashStatus === FlashMode.OFF && !isAutoCloseFlash) {
        HiLog.i(TAG, `flashStatus is OFF`);
        return;
      }
      // 10x及以上自动关闭闪光灯
      isClose = true;
    } else {
      if (!isAutoCloseFlash) {
        // 用户在10x自动关闭闪光灯后又修改了闪光灯模式
        return;
      }
      isClose = false;
    }
    HiLog.i(TAG, `handleFlashMode, isClose = ${isClose}`);
    this.mPreferencesService.putPropValue(PersistType.FOREVER, PropTag.IS_AUTO_CLOSE_FLASH, isClose);
    this.mStoreManager.postMessage(ZoomAction.handleAutoCloseFlash(isClose));
    this.mStoreManager.postMessage(TreasureBoxAction.updateByZoomChanged());
  }

  // zoom 35x --> 动态照片控制
  private controlLivePhotoManage(oldZoomRatio: number, zoomRatio: number, isNeedUpdate: boolean = false): void {
    oldZoomRatio = Math.round(oldZoomRatio * ZoomFunction.ZOOM_CONSTANT_TEN) / ZoomFunction.ZOOM_CONSTANT_TEN;
    zoomRatio = Math.round(zoomRatio * ZoomFunction.ZOOM_CONSTANT_TEN) / ZoomFunction.ZOOM_CONSTANT_TEN;
    let livePhotoControlParam: boolean = false;
    const hasZoomControlLive: boolean = getStates().get<boolean>('livePhotoReducer', 'isZoomControlLive');
    HiLog.i(TAG, `zoom conflict live param: ${livePhotoControlParam},${hasZoomControlLive}.`);
    if (hasZoomControlLive === !livePhotoControlParam) {
      this.mStoreManager.postMessage(execAction('LivePhotoAction', 'handleZoomDelayControlLive',
        livePhotoControlParam));
    }
  }

  private initZoomControlLiveState(): void {
    const hasZoomControlLive: boolean = getStates().get<boolean>('livePhotoReducer', 'isZoomControlLive');
    if (hasZoomControlLive) {
      HiLog.i(TAG, 'initZoomControlLiveState');
      this.mStoreManager.postMessage(execAction('LivePhotoAction', 'handleZoomDelayControlLive', false));
    }
  }

  /**
   * 重启流后要同步当前焦距给View层
   */
  private zoomOnCameraStarted(data: CameraStartedData): void {
    HiLog.i(TAG, `zoomOnCameraStarted. Start Type ${data.type}, ${data.zoomRatio}`);
    let mode = getStates().get<ModeType>('modeReducer', 'mode');
    const ratio = getStates().get<number>('zoomReducer', 'zoomRatio');
    if ((data.type === CameraStartType.RESTART || data.type === CameraStartType.RECORD)) {
      return;
    }
    let zoomRatio: number = data.zoomRatio || ratio;
    HiLog.d(TAG, `zoomOnCameraStarted, getDefaultZoomRatio: ${zoomRatio}, ratio: ${ratio}`);
    AppStorage.delete('wantZoomRatio');
    if (ZoomOperation.getInstance().getRemainZoomRatio()) {
      zoomRatio = ratio;
      HiLog.d(TAG, `zoomOnCameraStarted.  getRemainZoomRatio:${zoomRatio}`);
    } else {
      let conflictParam = ConflictParam.emptyParam();
      this.mConflictManager.setConflictParam(FunctionId.FLASH, conflictParam);
    }
    const cameraPosition: camera.CameraPosition =
      getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    let oldZoomRatio = this.mZoomRatio;
    this.mZoomRatio = zoomRatio;
    /* instrument ignore next */
    if (this.mZoomRatio !== oldZoomRatio) {
      HiLog.e(TAG, 'Inconsistent zoomRatio before and after camera started');
      this.mStoreManager.postMessage(ZoomAction.updateStateZoomRatio(this.mZoomRatio));
      this.setValue({
        zoomRatio: this.mZoomRatio,
        isPrepareZoom: true,
        isUnprepareZoom: true,
        unprepareDelay: ZoomParam.UNPREPARE_DELAY_TIME
      });
    } else {
      const zoomRatioRange = this.mCameraProxy.getZoomRatioRange();
      this.conflictFlashManage(oldZoomRatio, this.mZoomRatio, data.type);
      this.controlLivePhotoManage(oldZoomRatio, this.mZoomRatio, true);
      if (!zoomRatioRange || zoomRatioRange.length < ZoomFunction.ZOOM_RATIO_LENGTH) {
        HiLog.e(TAG, 'zoomRatioRange undefined.');
        return;
      }
    }
    setTimeout((): void => { // Function与UI同时监听,保障UI读取remain值先执行
      ZoomOperation.getInstance().setRemainZoomRatio(false);
    }, ZoomFunction.ZOOM_REMAIN_HOLDING_TIME);
  }

  private updateZoomRatio(): void {
    let newZoomRatio = this.catchZoomRatio || this.mZoomRatio;
    const conflicts: string[] = this.getRequiredConflicts()?.limitedValue?.getValues();
    if (conflicts) {
      this.catchZoomRatio = this.mZoomRatio;
      newZoomRatio = Number(conflicts[0]);
    } else {
      this.catchZoomRatio = 0;
    }
    HiLog.i(TAG, `newZoomRatio: ${newZoomRatio}, mZoomRatio: ${this.mZoomRatio}, conflicts: ${conflicts?.toString()}.`);
    this.mZoomRatio = newZoomRatio;
  }

  private onConflictParamChange(data: { id: number }): void {
    const currentFunctionId = this.getFunctionId();
    HiLog.i(TAG, `onConflictParamChange functionId: ${data.id}, currentFunctionId：${currentFunctionId}`);
    if (currentFunctionId !== data.id) {
      return;
    }

    this.updateZoomRatio();
    this.mCameraProxy.setZoomRatio(this.mZoomRatio);
    this.mStoreManager.postMessage(ZoomAction.updateStateZoomRatio(this.mZoomRatio));
    HiLog.i(TAG, `onConflictParamChange ${this.mZoomRatio}.`);
  }

  private resetZoomRatio(data: ModeData): void {
    HiLog.i(TAG, 'handleForeground');
    // 夜景-拍照 模式相互切换时需要保持焦距
    /* instrument ignore next */
    if (ZoomOperation.getInstance().getRemainZoomRatio() && !PickerUtils.getIsPicker()) {
      return;
    }
    let mode = data.mode || getStates().get<ModeType>('modeReducer', 'mode');
    let cameraPosition =
      data.cameraPosition || getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    let zoomRatio: number = ZoomOperation.getDefaultZoomRatio(mode, cameraPosition);
    this.mZoomRatio = zoomRatio;
    this.mStoreManager.postMessage(ZoomAction.updateStateZoomRatio(zoomRatio));
    //变焦值重置后重新发互斥
    this.conflictParam = ConflictParam.emptyParam();
    this.mConflictManager.setConflictParam(FunctionId.FLASH, this.conflictParam);
    this.initZoomControlLiveState();
  }
}