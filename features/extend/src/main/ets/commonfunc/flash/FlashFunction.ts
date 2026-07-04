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
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { BaseFunction } from '@ohos/common/src/main/ets/function/core/BaseFunction';
import lazy { PersistType } from '@ohos/common/src/main/ets/service/preferences/PreferencesService';
import lazy {
  FLASH_MODE_AUTO,
  FLASH_MODE_OFF,
  FlashCloseScene,
  FlashMode,
  FlashModeInfo,
  isSupportFlashMode,
  MULTIPLE_OUTPUT_TYPE_MAPPING_FLASH_MODE,
  SINGLE_OUTPUT_MAPPING_FLASH_MODE
} from '@ohos/common/src/main/ets/function/enumbase/FlashMode';
import lazy { OutputType } from '@ohos/common/src/main/ets/function/outputswitcher/OutputType';
import lazy { execDispatch, getStates, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { RenderType } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderType';
import lazy { UiElement } from '@ohos/common/src/main/ets/function/core/UiElement';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { OutputOperation } from '@ohos/common/src/main/ets/function/outputswitcher/OutputOperation';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { Action } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy {
  MULTIPLE_OUTPUTS_MODES,
  OutputSwitcher
} from '@ohos/common/src/main/ets/function/outputswitcher/OutputSwitcher';
import lazy { TabBarAction } from '@ohos/common/src/main/ets/component/tabbar/TabBarAction';
import lazy { StringUtil } from '@ohos/common/src/main/ets/utils/StringUtil';
import lazy { CameraAppCapability } from '@ohos/common/src/main/ets/camera/CameraAppCapability';
import lazy { PickerShowMsg } from '@ohos/common/src/main/ets/service/picker/PickerUiService';
import lazy { PropTag } from '@ohos/common/src/main/ets/service/preferences/PropTag';
import lazy { getCloseFlashZoom, isNeedHideFlashIcon } from '@ohos/common/src/main/ets/utils/FileReadUtil';
import lazy { SettingViewActionType } from '@ohos/common/src/main/ets/redux/actions/SettingViewActionType';
import lazy { ThumbnailActionType } from '@ohos/common/src/main/ets/redux/actions/ThumbnailActionType';
import lazy { ZoomActionType } from '@ohos/common/src/main/ets/redux/actions/ZoomActionType';
import lazy { FunctionActionType } from '@ohos/common/src/main/ets/redux/actions/FunctionActionType';
import lazy { CameraActionType } from '@ohos/common/src/main/ets/redux/actions/CameraActionType';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { ContextActionType } from '@ohos/common/src/main/ets/redux/actions/ContextActionType';

const TAG = 'FlashFunction';
const MAIN_CAMERA_ZOOM = 1;
const D_VALUE = 0.1;

const PAN_PHOTO = 'PAN_PHOTO';
const PAN_VIDEO = 'PAN_VIDEO';
const PAN_NIGHT_SUB_MODE = 'PAN_NIGHT_SUB_MODE';

// 闪光灯
export class FlashFunction extends BaseFunction {
  private static readonly isNeedHideFlashIcon: boolean = isNeedHideFlashIcon();
  private static readonly ZOOM_RATIO_CLOSE_FLASH: number = getCloseFlashZoom();
  private static mValueMap: Map<string, FlashMode> = new Map();
  private readonly RENDER_LOCATIONS: RenderLocation[] = [
    RenderLocation.TREASURE_BOX, RenderLocation.TAB_BAR_LEFT, RenderLocation.TAB_BAR_RIGHT
  ];

  constructor() {
    super();
    this.init();
  }

  protected init(): void {
    let cacheModeStr: string =
      <string> this.mPreferencesService.getFunctionValue(PersistType.FOREVER, this.getFunctionId(), '');
    FlashFunction.mValueMap = StringUtil.string2Map(cacheModeStr) as Map<string, FlashMode>;
    HiLog.i(TAG, `constructor, getFunctionValue: ${cacheModeStr}, mValueMap size: ${FlashFunction.mValueMap.size}.`);
    /* 常见三种闪光灯短时展示状态变更，不改缓存，只临时getValue需要展示的值
    1、进入特殊场景如设置页等需要关闭，handleFlashCloseSceneRegister，直接触发事件下发关闭
    2、互斥如变焦互斥，需要控制闪光灯ui展示，传递互斥内容onFunctionConflictParamChange
    3、起流关闭，如专业不支持自动，复用起流直接getDefault onSessionCreated
     * */
    this.handleFlashCloseSceneRegister();
    this.mEventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM,
      this.onFunctionConflictParamChange.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.onSessionCreated.bind(this), this.mBase.hashCode());
    this.mEventBus.on(ContextActionType.ABILITY_ON_DESTROY, this.abilityOnDestroy.bind(this), this.mBase.hashCode());
  }

  getFunctionId(): FunctionId {
    return FunctionId.FLASH;
  }

  getDefaultValue(): number {
    return FlashMode.OFF;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    switch (renderLocation) {
      case RenderLocation.TREASURE_BOX:
        return RenderType.POPUP_TREASURE_BOX_ITEM;
      case RenderLocation.TAB_BAR_RIGHT:
        return RenderType.POPUP_BUTTON;
      case RenderLocation.TAB_BAR_LEFT:
        return RenderType.POPUP_BUTTON;
      default:
        return null;
    }
  }

  getUiElements(renderLocation: RenderLocation): Map<unknown, UiElement> {
    const curMode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
    switch (renderLocation) {
      case RenderLocation.TREASURE_BOX:
        return this.generateUiElements(curMode, true);
      case RenderLocation.TAB_BAR_RIGHT:
        return this.generateUiElements(curMode, false);
      case RenderLocation.TAB_BAR_LEFT:
        return this.generateUiElements(curMode, false);
      default:
        return new Map();
    }
  }

  private getFlashModeList(curMode: ModeType): FlashModeInfo[] {
    let flashModeList: FlashModeInfo[] = SINGLE_OUTPUT_MAPPING_FLASH_MODE.get(OutputType.PHOTO_OUTPUT);
    const isPanPhotoOutput: boolean =
      OutputOperation.isPanPhotoOutput(curMode, OutputSwitcher.getInstance().getOutput());
    let outputType: OutputType = isPanPhotoOutput ? OutputType.PHOTO_OUTPUT : OutputType.VIDEO_OUTPUT;
    HiLog.i(TAG, `getFlashModeList: ${outputType}`);
    if (MULTIPLE_OUTPUTS_MODES.includes(curMode)) {
      const flashKey: string = curMode + '' + outputType;
      flashModeList = MULTIPLE_OUTPUT_TYPE_MAPPING_FLASH_MODE.get(flashKey) ??
      SINGLE_OUTPUT_MAPPING_FLASH_MODE.get(outputType);
    } else {
      flashModeList = SINGLE_OUTPUT_MAPPING_FLASH_MODE.get(outputType);
    }
    return flashModeList;
  }

  private generateUiElements(curMode: ModeType, isTreasureBox: boolean): Map<unknown, UiElement> {
    const uiElements = new Map();
    if (isTreasureBox) {
      uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.treasure_box_flash_light_entry'))
        .setAccessibilityTitle($r('app.string.treasure_box_flash_light_entry')));
    }
    const flashModeList: FlashModeInfo[] = this.getFlashModeList(curMode);
    const conflicts: string[] = this.getRequiredConflicts()?.limitedValue?.getValues();
    flashModeList.forEach((item: FlashModeInfo) => {
      const flashMode = item.flashMode; // 互斥时取互斥结果，非互斥全取
      if ((conflicts && conflicts.some(conflict => Number(conflict) === flashMode)) || !conflicts) {
        const icon = isTreasureBox ? item.treasureBoxIcon : item.tabBarIcon;
        const uiElement: UiElement = new UiElement()
          .setValue(flashMode)
          .setIcon($r(icon))
          .setDesc(item.desc)
          .setAccessibilityTitle($r('app.string.treasure_box_flash_light_entry'))
          .setAccessibilityDescription(item.accessibilityDescription);
        //只有在底部时才会设置title
        if (isTreasureBox) {
          uiElement.setTitle($r(item.title));
        }
        uiElements.set(flashMode, uiElement);
      }
    });
    return uiElements;
  }

  getValue(): FlashMode {
    let value: FlashMode = this.getCacheValue();
    if (this.isDefaultValueCase(value)) {
      return this.getDefaultValue();
    }
    const conflicts: FlashMode[] =
      this.getRequiredConflicts()?.limitedValue?.getValues() as unknown as FlashMode[];
    if (conflicts && conflicts.every(conflict => Number(conflict) !== value)) {
      value = conflicts[0];
    }
    HiLog.i(TAG, `getValue: conflicts value: ${value}. conflicts: ${JSON.stringify(conflicts)}`);
    return value;
  }

  setValue(value: FlashMode, renderLocation?: RenderLocation): void {
    HiLog.i(TAG, `FlashFunction curVal: ${value}, preVal:${this.getValue()}.`);
    if (value === this.getValue()) {
      return;
    }
    if (-1 === value) {
      // -1是恢复默认值这个场景
      FlashFunction.mValueMap = new Map();
      value = this.getDefaultValue();
    }
    this.handleFlashModeUpdate(value);
    this.persistValue(value);
    execDispatch(Action.flashChanged(value, renderLocation));
    this.mPreferencesService.putPropValue(PersistType.FOREVER, PropTag.IS_AUTO_CLOSE_FLASH, false);
  }

  persistValue(value: number): void {
    const cacheKey: string = this.getCacheKey();
    FlashFunction.mValueMap.set(cacheKey, value);
    this.mPreferencesService.putFunctionValue(PersistType.FOREVER, this.getFunctionId(),
      StringUtil.map2String(FlashFunction.mValueMap));
  }

  isShow(): boolean {
    const curMode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
    if (!isSupportFlashMode(curMode)) {
      return false;
    }
    const flashMode = this.getValue();
    return true;
  }

  isAvailable(): boolean {
    const isNeedRemoveFlashFunc: boolean = CameraAppCapability.getInstance().getIsNeedRemoveFlashFunc();
    if (isNeedRemoveFlashFunc) {
      HiLog.i(TAG, 'config not support flash.');
      return false;
    }
    const isPhoneFrontCamera: boolean = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
    camera.CameraPosition.CAMERA_POSITION_FRONT;
    const isAvailable: boolean = !isPhoneFrontCamera;
    HiLog.d(TAG, `isAvailable: ${isAvailable}.`);
    return isAvailable;
  }

  private handleFlashCloseSceneRegister(): void {
    this.mEventBus.on(SettingViewActionType.ACTION_SHOW_SETTING_VIEW,
      (data) => this.handleFlashCloseScene({ isEntry: data.isShowSettingView, isQuitBack: data.isTriggeredByBack }),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_MORE_MODE_TAB_EMIT_FLASH,
      (data) => this.handleFlashCloseScene({ isEntry: data.isEmitFlashChanged }),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_THUMBNAIL_REMINDER_SHOW,
      (data) => this.handleFlashCloseScene({ isEntry: data.thumbnailReminderShow }),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_APP_LOCK_REMINDER_SHOW,
      (data) => this.handleFlashCloseScene({ isEntry: data.appLockReminderShow }),
      this.mBase.hashCode());
    this.mEventBus.on(ThumbnailActionType.PHOTOBROWSER_STATUS,
      (data) => this.handleFlashCloseScene({ isEntry: data.photoBrowserStatus, isQuitBack: data.isTriggeredByBack }),
      this.mBase.hashCode());
    this.mEventBus.on(ZoomActionType.ACTION_AUTO_CLOSE_FLASH,
      (data) => this.handleFlashCloseScene({ isEntry: data.isAutoCloseFlash }),
      this.mBase.hashCode());
  }

  // 进入某些场景需要触发关闭闪光灯（非起流无法直接复用session 获取 特性值），如：设置页、大图组件、锁屏默认、图库应用锁等
  handleFlashCloseScene(data: FlashCloseScene): void {
    if (!this.isAvailable() || data?.isQuitBack) {
      return;
    }
    let value: FlashMode = camera.FlashMode.FLASH_MODE_CLOSE as number;
    if (!data?.isEntry && this.getValue() === value) {
      HiLog.w(TAG, 'is the same value, not set');
      return;
    }
    if (data && !data?.isEntry) {
      value = this.getValue();
    }
    HiLog.i(TAG, `is entry special scene to close flash = ${!data?.isEntry},${data?.isQuitBack}, value = ${value}.`);
    this.handleFlashModeUpdate(value);
  }

  private onFunctionConflictParamChange(data: { id: number }): void {
    HiLog.i(TAG, `onFunctionConflictParamChange X, functionId: ${JSON.stringify(data.id)}`);
    const currentFunctionId = this.getFunctionId();
    if (currentFunctionId !== data.id) {
      return;
    }
    const value: FlashMode = this.getValue();
    this.handleFlashModeUpdate(value);
    HiLog.i(TAG, `onFunctionConflictParamChange ${value}`);
  }

  private onSessionCreated(): void {
    if (!this.isAvailable()) {
      return;
    }
    const flashMode = this.getValue();
    this.handleFlashModeUpdate(flashMode);
    HiLog.i(TAG, `onSessionCreated: setFlashMode: ${flashMode}.`);
  }

  private handleFlashModeUpdate(curFlashMode: FlashMode): void {
    HiLog.i(TAG, `handleFlashModeUpdate X:${curFlashMode}.`);
    this.mCameraProxy.setFlashMode(curFlashMode);
    this.mStoreManager.postMessage(TabBarAction.updatePopUpButton());
  }

  protected getCacheKey(): string {
    const state: OhCombinedState = getStates();
    const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
    const isPanPhotoOutput: boolean =
      OutputOperation.isPanPhotoOutput(state.get<ModeType>('modeReducer', 'mode'), outputType);
    const isSupportFlash: boolean = isSupportFlashMode(state.get<ModeType>('modeReducer', 'mode'));
    let headKey: string = isPanPhotoOutput ? PAN_PHOTO : PAN_VIDEO;
    let cacheKey: string = `${headKey}_${isSupportFlash}`;
    return cacheKey;
  }

  private getCacheValue(): FlashMode {
    const cacheValue = FlashFunction.mValueMap.get(this.getCacheKey());
    const value: FlashMode = cacheValue ?? this.getDefaultValue();
    return value;
  }

  private isAutoCloseFlash(): boolean {
    if (FlashFunction.isNeedHideFlashIcon) {
      return false;
    }
    const zoomValue: number = getStates().get<number>('zoomReducer', 'zoomRatio');
    const isAutoCloseFlash: boolean = this.mPreferencesService
      .getPropValue(PersistType.FOREVER, PropTag.IS_AUTO_CLOSE_FLASH, false) as boolean;
    if (zoomValue > FlashFunction.ZOOM_RATIO_CLOSE_FLASH && isAutoCloseFlash) {
      HiLog.i(TAG, `isAutoCloseFlash is true`);
      return true; // 起流时zoom10x以上且处于自动关闭闪光灯状态, 则getValue返回FlashMode.OFF
    }
    return false;
  }

  private isDefaultValueCase(value: number): boolean {
    return getStates().get<boolean>('settingViewReducer', 'isShowSettingView') ||
    AppStorage.get<boolean>('isNeedCloseFlashByMDV');
  }

  private abilityOnDestroy(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    HiLog.i(TAG, 'abilityOnDestroy');
  }
}