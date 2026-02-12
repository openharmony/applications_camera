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
import lazy { FunctionAction } from '../core/FunctionAction';
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import camera from '@ohos.multimedia.camera';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { CameraAction } from '../../camera/uithread/CameraAction';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { ConflictParam } from '../core/ConflictParam';
import lazy { postStoreManagerThrottle } from '../../utils/throtte';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { ValueSet } from '../core/ValueSet';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';
import lazy { RenderType } from '../core/functionproperty/RenderType';
import lazy { UiElement } from '../core/UiElement';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { OutputOperation } from '../outputswitcher/OutputOperation';
import lazy { OutputType } from '../outputswitcher/OutputType';
import lazy { OutputSwitcher } from '../outputswitcher/OutputSwitcher';
import lazy { hasCameraProfiles } from '../../utils/FileReadUtil';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { TabBarAction } from '../../component/tabbar/TabBarAction';
import lazy { ZoomAction } from '../zoombar/ZoomAction';
import lazy { CameraBasicService } from '../../camera/uithread/CameraBasicService';
import lazy { FrameRateOperation } from './FrameRateOperation';
import lazy { ZoomOperation } from '../zoombar/ZoomOperation';
import lazy { execAction } from '../../redux/ActionRegistry';
import lazy { getStates } from '../../redux';
import lazy { FunctionActionType } from '../../redux/actions/FunctionActionType';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { ZoomActionType } from '../../redux/actions/ZoomActionType';
import lazy { PersistType } from '../../service/preferences/PreferencesService';
import lazy { StringUtil } from '../../utils/StringUtil';

const TAG = 'FrameRateFunction';

export class FrameRateFunction extends BaseFunction {
  // 用于区分恢复默认值场景
  public static readonly RESTORE_VALUE: number = -1;
  public static readonly RATE_10_FPS: number = 10;
  public static RATE_30_FPS: number = 30;
  public static RATE_60_FPS: number = 60;
  public static readonly FRAME_RATE: number[] =
    [SettingFuncDialogItemIndex.INDEX_FIR, SettingFuncDialogItemIndex.INDEX_SEC];
  private static frameRate: number = SettingFuncDialogItemIndex.INDEX_FIR;
  private readonly RENDER_LOCATIONS: RenderLocation[] = [
    RenderLocation.TREASURE_BOX, RenderLocation.SETTING_MENU_VIDEO, RenderLocation.TAB_BAR_LIST
  ];
  private isConflictHdr: boolean = false;
  private static mValueMap: Map<string, number> = new Map(); // 全量缓存数据

  static {
    if (DeviceInfo.isRk3568() || DeviceInfo.isUis7885()) {
      FrameRateFunction.RATE_30_FPS = 5;
      FrameRateFunction.RATE_60_FPS = 10;
    }
  }

  constructor() {
    super();
    FrameRateFunction.frameRate = this.getPersistedValueJudgment();
    this.mEventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM, this.onConflictParamChange.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.conflictManage.bind(this), this.mBase.hashCode());
  }

  getFunctionId(): FunctionId {
    return FunctionId.FRAME_RATE;
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    switch (renderLocation) {
      case RenderLocation.TREASURE_BOX:
        return RenderType.POPUP_TREASURE_BOX_ITEM;
      case RenderLocation.SETTING_MENU_VIDEO:
        return RenderType.POPUP_SETTING_ITEM;
      case RenderLocation.TAB_BAR_LIST:
        return RenderType.NONE;
      default:
        return null;
    }
  }

  getUiElements(renderLocation: RenderLocation): Map<unknown, UiElement> {
    switch (renderLocation) {
      case RenderLocation.TREASURE_BOX:
        return this.getBoxUiElements();
      case RenderLocation.SETTING_MENU_VIDEO:
        return this.getSettingUiElements();
      case RenderLocation.TAB_BAR_LIST:
        return this.getTabBarUiElements();
      default:
        return new Map();
    }
  }

  private getBoxUiElements(): Map<unknown, UiElement> {
    const uiElements = new Map();
    const defaultUiElement = new UiElement()
      .setTitle($r('app.string.treasure_box_frame_rate'))
      .setAccessibilityTitle($r('app.string.treasure_box_frame_rate'));
    if (!getStates().get<boolean>('collapsReducer', 'isShowLandscape') && !DeviceInfo.isTablet()) {
      defaultUiElement.setIcon($r('app.media.treasure_box_frame_rate'));
    }
    uiElements.set(UiElement.DEFAULT, defaultUiElement);
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.frame_rate', this.getFirstRateByMode()))
      .setTextIcon(this.getFirstRateByMode().toString())
      .setTextItemSec('fps')
      .setAccessibilityTitle($r('app.string.treasure_box_frame_rate'))
      .setAccessibilityDescription($r('app.string.frame_rate', this.getFirstRateByMode())));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle($r('app.string.frame_rate', FrameRateFunction.RATE_60_FPS))
      .setTextIcon(FrameRateFunction.RATE_60_FPS.toString())
      .setTextItemSec('fps')
      .setAccessibilityTitle($r('app.string.treasure_box_frame_rate'))
      .setAccessibilityDescription($r('app.string.frame_rate', FrameRateFunction.RATE_60_FPS)));
    let conflicts: string[] = this.getRequiredConflicts()?.limitedValue?.getValues();
    /* instrument ignore if */
    if (conflicts) {
      HiLog.i(TAG, 'conflicts start B.');
      new Set(uiElements.keys()).forEach((key: number) => {
        if (FrameRateFunction.FRAME_RATE.includes(Number(key)) && conflicts.indexOf(key.toString()) < 0) {
          const item = uiElements.get(key);
          item.setDisabled(true);
          uiElements.set(key, item);
        }
      });
    }
    return uiElements;
  }

  getOutHomeUiElements(): Map<unknown, UiElement> {
    const uiElements = new Map();
    // title 视频帧率: 30 60
    uiElements.set(UiElement.DEFAULT, new UiElement().setValue(-1)
      .setTitle($r('app.string.video_frame_rate'))
    );
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement().setValue(-1)
      .setTitle($r('app.string.off'))
    );
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement().setValue(SettingFuncDialogItemIndex.INDEX_FIR)
      .setTitle($r('app.string.frame_rate', FrameRateFunction.RATE_30_FPS))
    );
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement().setValue(SettingFuncDialogItemIndex.INDEX_SEC)
      .setTitle($r('app.string.frame_rate', FrameRateFunction.RATE_60_FPS))
    );
    return uiElements;
  }

  /* instrument ignore next */
  getUiElementsLandscape(): Map<Object, UiElement> {
    const uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.treasure_box_frame_rate'))
      .setTextIcon(this.getFirstRateByMode().toString())
      .setTextItemSec('fps')
    );
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.frame_rate', this.getFirstRateByMode()))
      .setTextIcon(this.getFirstRateByMode().toString())
      .setTextItemSec('fps')
    );
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle($r('app.string.frame_rate', FrameRateFunction.RATE_60_FPS))
      .setTextIcon(FrameRateFunction.RATE_60_FPS.toString())
      .setTextItemSec('fps')
    );
    let conflicts: string[] = this.getRequiredConflicts()?.limitedValue?.getValues();
    /* instrument ignore if */
    if (conflicts) {
      new Set(uiElements.keys()).forEach((key: number) => {
        if (FrameRateFunction.FRAME_RATE.includes(Number(key)) && conflicts.indexOf(key.toString()) < 0) {
          const item = uiElements.get(key);
          item.setDisabled(true);
          uiElements.set(key, item);
        }
      });
    }

    return uiElements;
  }

  private getSettingUiElements(): Map<unknown, UiElement> {
    const uiElements = new Map();
    let defaultValue = this.getDefaultValue();
    let recommendationValue = defaultValue === SettingFuncDialogItemIndex.INDEX_FIR ?
      this.getFirstRateByMode() : FrameRateFunction.RATE_60_FPS
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.video_frame_rate'))
      .setValue(defaultValue)
      .setIcon($r('app.media.ic_camera_video_frame_rate'))
      .setAccessibilityTitle($r('app.string.video_frame_rate')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement()
      .setTitle($r('app.string.frame_rate', recommendationValue))
      .setAccessibilityTitle($r('app.string.video_frame_rate'))
      .setAccessibilityDescription($r('app.string.frame_rate', recommendationValue)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.frame_rate', this.getFirstRateByMode()))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIR)
      .setAccessibilityTitle($r('app.string.video_frame_rate'))
      .setAccessibilityDescription($r('app.string.frame_rate', this.getFirstRateByMode())));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
    //zy-20251210-这里的Description从getFirstRateByMode获取的就是30fps，这个应该对应到60fps
      .setTitle($r('app.string.frame_rate', FrameRateFunction.RATE_60_FPS))
      .setValue(SettingFuncDialogItemIndex.INDEX_SEC)
      .setAccessibilityTitle($r('app.string.video_frame_rate'))
      .setAccessibilityDescription($r('app.string.frame_rate', FrameRateFunction.RATE_60_FPS)));

    let conflicts: string[] = this.getRequiredConflicts()?.limitedValue?.getValues();
    /* instrument ignore if */
    if (conflicts) {
      new Set(uiElements.keys()).forEach((key: number) => {
        if (FrameRateFunction.FRAME_RATE.includes(key) && conflicts.indexOf(key.toString()) < 0) {
          uiElements.delete(key);
        }
      });
    }

    return uiElements;
  }

  private getTabBarUiElements(): Map<unknown, UiElement> {
    const uiElements = new Map();
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle(`${this.getFirstRateByMode()} fps`)
      .setDesc($r('app.string.frame_rate', this.getFirstRateByMode()))
      .setAccessibilityTitle($r('app.string.treasure_box_frame_rate'))
      .setAccessibilityDescription($r('app.string.frame_rate', this.getFirstRateByMode())));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle(`${FrameRateFunction.RATE_60_FPS} fps`)
      .setDesc($r('app.string.frame_rate', FrameRateFunction.RATE_60_FPS))
      .setAccessibilityTitle($r('app.string.treasure_box_frame_rate'))
      .setAccessibilityDescription($r('app.string.frame_rate', FrameRateFunction.RATE_60_FPS)));
    let conflicts: string[] = this.getRequiredConflicts()?.limitedValue?.getValues();
    /* instrument ignore if */
    if (conflicts) {
      new Set(uiElements.keys()).forEach((key: number) => {
        if (FrameRateFunction.FRAME_RATE.includes(key) && conflicts.indexOf(key.toString()) < 0) {
          uiElements.delete(key);
        }
      });
    }
    return uiElements;
  }

  getFirstRateByMode(): number {
    const mode = getStates().get<ModeType>('modeReducer', 'mode');
    return FrameRateFunction.RATE_30_FPS;
  }

  getDefaultValue(): number {
    HiLog.d(TAG, 'getDefaultValue');
    return <number> (CameraAppCapability.getInstance().getIsSupportDefault1080PAnd60Fps() ?
      SettingFuncDialogItemIndex.INDEX_SEC : SettingFuncDialogItemIndex.INDEX_FIR);
  }

  setValue(value: number): void {
    HiLog.i(TAG, `setValue value: ${value}.`);
    if (FrameRateFunction.frameRate === value) {
      HiLog.i(TAG, `value === FrameRateFunction.frameRate`);
      return;
    }
    if (value === FrameRateFunction.RESTORE_VALUE) {
      value = this.getDefaultValue();
    }
    HiLog.i(TAG, `setValue value update: ${value}. FrameRateBaseFunction.frameRate: ${FrameRateFunction.frameRate}`);
    FrameRateFunction.frameRate = value;
    const outputType = OutputSwitcher.getInstance().getOutput();
    const state = getStates();
    const mode = state.get<ModeType>('modeReducer', 'mode');
    this.persistValue(value);
    this.conflictManage();
    this.conflictEfficientVideo();
    if (!AppStorage.get('restoreFlag') && OutputOperation.isPanVideoOutput(mode, outputType)) {
      if ((CameraAppCapability.getInstance().getNotSupportedVideo60fpsWide()) &&
        (mode === ModeType.VIDEO) &&
        CameraBasicService.getInstance().getVideoFrameRate() === FrameRateOperation.FRAME_FPS_RATE_60 &&
        getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
        camera.CameraPosition.CAMERA_POSITION_BACK &&
        state.get<number>('zoomReducer', 'zoomRatio') < 1) {
        this.mStoreManager.postMessage(ZoomAction.updateStateZoomRatio(1));
      } else if (mode === ModeType.VIDEO &&
        CameraBasicService.getInstance().getVideoFrameRate() === FrameRateOperation.FRAME_FPS_RATE_60 &&
        getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') ===
        camera.CameraPosition.CAMERA_POSITION_FRONT &&
        state.get<number>('zoomReducer', 'zoomRatio') > 1) {
        let defaultZoomRatio = ZoomOperation.getDefaultZoomRatio(mode,
          getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition'));
        this.mStoreManager.postMessage(ZoomAction.updateStateZoomRatio(defaultZoomRatio));
      }
      /* instrument ignore if */
      if (!this.isConflictHdr) {
        this.mStoreManager.postMessage(CameraAction.restart(state.get<number>('zoomReducer', 'zoomRatio')));
      }
    }
    /* instrument ignore if */
    if (this.isConflictHdr) {
      this.isConflictHdr = false;
    }
    this.mEventBus.emit(ZoomActionType.ACTION_CHANGE_ZOOM_BY_FRAMERATE, []);
  }

  getValue(): number {
    let frameRate = FrameRateFunction.frameRate;
    const conflicts: string[] = this.getRequiredConflicts()?.limitedValue?.getValues();
    if (conflicts) {
      if (conflicts?.indexOf(FrameRateFunction?.frameRate?.toString()) < 0) {
        frameRate = Number(conflicts[0]);
      }
    } else {
      frameRate = this.getPersistedValueJudgment();
      HiLog.i(TAG, `getPersisteValue: ${frameRate}}`)
    }
    //zy-20251210-这里屏蔽了就能修改60fps的帧率，在默认是2的时候，会修改为1，暂时不清楚为什么
    // if (frameRate === 2) {
    //   frameRate = SettingFuncDialogItemIndex.INDEX_FIR;
    // }
    HiLog.i(TAG, `FrameRateBaseFunction.frameRate: ${frameRate}`);
    return frameRate;
  }

  isAvailable(): boolean {
    return true;
  }

  load(renderLocations: RenderLocation[]): void {
    super.load(renderLocations);
  }

  unload(renderLocations: RenderLocation[]): void {
    super.unload(renderLocations);
  }

  private onConflictParamChange(data: { id: number }): void {
    const currentFunctionId = this.getFunctionId();
    HiLog.i(TAG,
      `onConflictParamChange X, functionId: ${JSON.stringify(data.id)}, currentFunctionId：${currentFunctionId}`);
    if (currentFunctionId !== data.id) {
      return;
    }
    const value: number = this.getValue();
    HiLog.i(TAG, `onConflictParamChange FrameRateFunction.frameRate: ${FrameRateFunction.frameRate}, value：${value}`);
    if (FrameRateFunction.frameRate !== value) {
      FrameRateFunction.frameRate = value;
      let conflictParam: ConflictParam = ConflictParam.emptyParam();
      const state = getStates();

      HiLog.i(TAG, `onConflictParamChange conflictNotRestart: ${AppStorage.get('conflictNotRestart')}`);
      HiLog.i(TAG, `onConflictParamChange isKeepFlowingRecording：${getStates()
        .get<boolean>('recordReducer', 'isKeepFlowingRecording')}`);

      if (!AppStorage.get('conflictNotRestart') &&
        !getStates().get<boolean>('recordReducer', 'isKeepFlowingRecording')) {
        postStoreManagerThrottle(CameraAction.restart(state.get<number>('zoomReducer', 'zoomRatio')));
      }
    }
    /* instrument ignore if */
    if (!AppStorage.get('conflictNotRestart') &&
    OutputOperation.isPanVideoOutput(getStates().get<ModeType>('modeReducer', 'mode'))) {
      StoreManager.getInstance().postMessage(TabBarAction.updateTextList());
    }
    this.mEventBus.emit(ZoomActionType.ACTION_CHANGE_ZOOM_BY_FRAMERATE, []);
    HiLog.i(TAG, `onConflictParamChange ${value}, zoomRatio: ${getStates().get<number>('zoomReducer', 'zoomRatio')}`);
  }

  private conflictEfficientVideo(): void {
    let conflictParam: ConflictParam = ConflictParam.emptyParam();
    // 60fps默认关闭高效视频格式和hdrVivid
    /* instrument ignore if */
    if (!AppStorage.get('userChangeEfficientVideo') && this.getValue() === SettingFuncDialogItemIndex.INDEX_SEC) {
      conflictParam = new ConflictParam().setLimitedValueSet(new ValueSet().setValues(['false']));
    }
    this.mConflictManager.setConflictParam(FunctionId.EFFICIENT_VIDEO, conflictParam);
  }

  public conflictManage(): void {
    const state = getStates();
    let conflictParam: ConflictParam = ConflictParam.emptyParam();
    /* instrument ignore if */
    if (DeviceInfo.isTablet()) {
      let videoResolution: number = FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION).getValue();
      if (videoResolution === SettingFuncDialogItemIndex.INDEX_FIR) {
        conflictParam = new ConflictParam().setLimitedValueSet(new ValueSet().setValues(['false']));
        conflictParam.disabled = true;
      }
    }
  }

  private getPersistedValueJudgment(): number {
    let value = this.getPersistedValue();
    if (typeof value === 'number') {
      FrameRateFunction.mValueMap.set(this.getCacheKeyForFrameRateFunction(), value as number);
      return value as number;
    }
    FrameRateFunction.mValueMap = StringUtil.string2Map(value as string) as Map<string, number>;
    if (!FrameRateFunction.mValueMap.has(this.getCacheKeyForFrameRateFunction())) {
      FrameRateFunction.mValueMap.set(this.getCacheKeyForFrameRateFunction(), this.getDefaultValue());
    }
    return FrameRateFunction.mValueMap.get(this.getCacheKeyForFrameRateFunction());
  }


  protected persistValue(value: number): void {
    FrameRateFunction.mValueMap.set(this.getCacheKeyForFrameRateFunction(), value);
    this.mPreferencesService.putFunctionValue(PersistType.FOREVER, this.getFunctionId(),
      StringUtil.map2String(FrameRateFunction.mValueMap));
  }

  private getCacheKeyForFrameRateFunction(): string {
    return `Others`;
  }
}