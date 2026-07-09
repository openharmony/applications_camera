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
import lazy { Action } from '../../redux/actions/Action';
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { DisplayCalculator } from '../../component/xcomponent/DisplayCalculator';
import lazy { AspectRatioOperation } from './AspectRatioOperation';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { CameraAction } from '../../camera/uithread/CameraAction';
import lazy { OutputOperation } from '../outputswitcher/OutputOperation';
import lazy { OutputType } from '../outputswitcher/OutputType';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';
import lazy { RenderType } from '../core/functionproperty/RenderType';
import lazy { UiElement } from '../core/UiElement';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { OutputSwitcher } from '../outputswitcher/OutputSwitcher';
import lazy { VideoResolutionFunction } from '../videoresolution/VideoResolutionFunction';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { hasCameraProfiles } from '../../utils/FileReadUtil';
import lazy { PersistType } from '../../service/preferences/PreferencesService';
import lazy { ConflictParam } from '../core/ConflictParam';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { display } from '@kit.ArkUI';
import lazy { StringUtil } from '../../utils/StringUtil';
import lazy { PcInfo } from '../../component/deviceinfo/PcInfo';
import lazy { camera } from '@kit.CameraKit';
import lazy { getStates } from '../../redux';
import lazy { FunctionActionType } from '../../redux/actions/FunctionActionType';
import lazy { PreviewAction } from '../../redux/actions/PreviewAction';

const TAG = 'AspectRatioFunction';
const ROTATION_2: number = 2;
const RATIO_16_TO_9 = 16 / 9;
const DISPLAY_SCREEN_SIZE_PSD: number = 202;
const COLLAPS_UNCOLLAPS_WIDTH_DIFF_MIN: number = 10;

// 照片比例
export class AspectRatioFunction extends BaseFunction {
  public static readonly RATIO_NUM_3: number = 3;
  public static readonly RATIO_NUM_4: number = 4;
  public static readonly RATIO_NUM_9: number = 9;
  public static readonly RATIO_NUM_16: number = 16;
  public static readonly SPLIT_NUM: number = 2;
  public static WIN_DECOR_HEIGHT: number = 50;
  private static aspectRatio: number = -1; // 当前互斥执行后的临时比例
  private static cacheAspectRatio: number; // 互斥执行前持久化的比例
  private static isConflictParam: boolean = false;
  public static readonly ASPECT_RATIO_ARRAY: number[] = [SettingFuncDialogItemIndex.INDEX_FIR,
    SettingFuncDialogItemIndex.INDEX_SEC, SettingFuncDialogItemIndex.INDEX_THR, SettingFuncDialogItemIndex.INDEX_THR];
  private static mValueMap: Map<string, number> = new Map(); // 全量缓存数据
  private readonly RENDER_LOCATIONS: RenderLocation[] = [
    /*RenderLocation.TREASURE_BOX,*/ RenderLocation.SETTING_MENU_PHOTO
  ];
  private static ASPECT_VALUE_VDE: number[] =
    [SettingFuncDialogItemIndex.INDEX_FIR, SettingFuncDialogItemIndex.INDEX_SEC];

  constructor() {
    super();
    AspectRatioFunction.aspectRatio = this.getPersistedValueForFrameRate();
  }

  getFunctionId(): FunctionId {
    return FunctionId.ASPECT_RATIO;
  }

  /* instrument ignore next */
  getDefaultValue(): number {
    /* instrument ignore if*/
    if (DeviceInfo.isTv()) {
      return <number> SettingFuncDialogItemIndex.INDEX_THR; // fullScreen
    }
    if (DeviceInfo.isPc()) {
      // hopper临时规避，后续拍照、录像功能模块设置页选项需要重构
      if (PcInfo.isRotatablePc()) {
        return <number> SettingFuncDialogItemIndex.INDEX_FOUR; // recommend 4:3
      }
      if (!hasCameraProfiles()) {
        return <number> SettingFuncDialogItemIndex.INDEX_THR; // recommend 16:9
      }
      return <number> SettingFuncDialogItemIndex.INDEX_SEC; // recommend 16:9
    }
    return <number> SettingFuncDialogItemIndex.INDEX_FIR; // recommend 4:3
  }

  private clearAspectRatioConflictParam(): void {
  }

  getRenderLocations(): RenderLocation[] {
    return this.RENDER_LOCATIONS;
  }

  getRenderType(renderLocation: RenderLocation): RenderType {
    switch (renderLocation) {
      case RenderLocation.TREASURE_BOX:
        return RenderType.POPUP_TREASURE_BOX_ITEM;
      case RenderLocation.SETTING_MENU_PHOTO:
        return RenderType.POPUP_SETTING_ITEM;
      default:
        return null;
    }
  }

  getUiElements(renderLocation: RenderLocation): Map<unknown, UiElement> {
    switch (renderLocation) {
      case RenderLocation.TREASURE_BOX:
        return this.getBoxUiElements();
      case RenderLocation.SETTING_MENU_PHOTO:
        return this.getSettingUiElements();
      default:
        return new Map();
    }
  }

  private getOutHomeUiElements(): Map<unknown, UiElement> {
    const uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setValue(-1)
      .setTitle($r('app.string.aspect_ratio'))
    );
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement().setValue(-1)
      .setTitle($r('app.string.off'))
    );
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement().setValue(SettingFuncDialogItemIndex.INDEX_FIR)
      .setTitle($r('app.string.photo_resolution_description', AspectRatioFunction.RATIO_NUM_4,
        AspectRatioFunction.RATIO_NUM_3))
    );
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement().setValue(SettingFuncDialogItemIndex.INDEX_SEC)
      .setTitle($r('app.string.photo_resolution_description', 1, 1))
    );
    return uiElements;
  }

  private getBoxUiElements(): Map<unknown, UiElement> {
    const uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.aspect_ratio'))
      .setAccessibilityTitle($r('app.string.aspect_ratio')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.photo_resolution_description',
        AspectRatioFunction.RATIO_NUM_4, AspectRatioFunction.RATIO_NUM_3))
      .setIcon($r('app.media.treasure_box_aspect_ratio_4_3'))
      .setAccessibilityTitle($r('app.string.aspect_ratio'))
      .setAccessibilityDescription($r('app.string.photo_resolution_description',
        AspectRatioFunction.RATIO_NUM_4, AspectRatioFunction.RATIO_NUM_3)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle($r('app.string.photo_resolution_description', 1, 1))
      .setIcon($r('app.media.treasure_box_aspect_ratio_1_1'))
      .setAccessibilityTitle($r('app.string.aspect_ratio'))
      .setAccessibilityDescription($r('app.string.photo_resolution_description', 1, 1)));
    /* instrument ignore if*/
    if (DeviceInfo.isTablet()) {
      uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
        .setTitle($r('app.string.photo_resolution_description',
          AspectRatioFunction.RATIO_NUM_16, AspectRatioFunction.RATIO_NUM_9))
        .setIcon($r('app.media.treasure_box_aspect_ratio_16_9'))
        .setAccessibilityTitle($r('app.string.aspect_ratio'))
        .setAccessibilityDescription($r('app.string.photo_resolution_description',
          AspectRatioFunction.RATIO_NUM_16, AspectRatioFunction.RATIO_NUM_9)));
    } else {
      uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
        .setTitle($r('app.string.box_resolution_full_screen_proportion_description'))
        .setIcon($r('app.media.aspect_ratio_full'))
        .setAccessibilityTitle($r('app.string.aspect_ratio'))
        .setAccessibilityDescription($r('app.string.box_resolution_full_screen_proportion_description')));
    }
    this.resolveConflicts(uiElements);
    return uiElements;
  }

  private resolveConflicts(uiElements: Map<SettingFuncDialogItemIndex, UiElement>): void {
    let conflicts: string[] = this.getRequiredConflicts()?.limitedValue?.getValues();
    if (conflicts) {
      HiLog.i(TAG, 'conflicts start B.');
      new Set(uiElements.keys()).forEach((key: number) => {
        if (AspectRatioFunction.ASPECT_RATIO_ARRAY.includes(Number(key)) && conflicts.indexOf(key.toString()) < 0) {
          const item = uiElements.get(key);
          item.setDisabled(true);
          uiElements.set(key, item);
        }
      });
    }
  }

  private filterItem(uiElements: Map<unknown, UiElement>): void {
    const cameraAppCapability: CameraAppCapability = CameraAppCapability.getInstance();
    const position = FeatureManager.getInstance().getFunction(FunctionId.CAMERA_SWITCHER)?.getValue();
    const mode = ModeType.PHOTO;
    uiElements.forEach((conflictParam: UiElement, key) => {
      if (key === UiElement.DEFAULT || key === SettingFuncDialogItemIndex.INDEX_NONE) {
        HiLog.i(TAG, 'getUiElements continue.');
      }
    });
  }

  /* instrument ignore next */
  private setPcSettingUiElements(uiElements: Map<unknown, UiElement>): void {
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.photo_specifications_title'))
      .setValue(this.getDefaultValue())
      .setIcon($r('app.media.ic_camera_setting_resolution_photo')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement()
      .setTitle($r('app.string.resolution_1080p_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_4,
        VideoResolutionFunction.VIDEO_RESOLUTION_3, VideoResolutionFunction.VIDEO_RESOLUTION_960)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.resolution_4K_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9, VideoResolutionFunction.VIDEO_RESOLUTION_TIP_4K))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIR));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle($r('app.string.resolution_1080p_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9, VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setValue(SettingFuncDialogItemIndex.INDEX_SEC));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9, VideoResolutionFunction.VIDEO_RESOLUTION_720))
      .setValue(SettingFuncDialogItemIndex.INDEX_THR));
    if (PcInfo.isRotatablePc()) {
      uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
        .setTitle($r('app.string.resolution_4K_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_4,
          VideoResolutionFunction.VIDEO_RESOLUTION_3, VideoResolutionFunction.VIDEO_RESOLUTION_TIP_3_2K))
        .setValue(SettingFuncDialogItemIndex.INDEX_FOUR));
      uiElements.set(SettingFuncDialogItemIndex.INDEX_FIF, new UiElement()
        .setTitle($r('app.string.resolution_4K_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_1,
          VideoResolutionFunction.VIDEO_RESOLUTION_1, VideoResolutionFunction.VIDEO_RESOLUTION_TIP_2_4K))
        .setValue(SettingFuncDialogItemIndex.INDEX_FIF));
    } else {
      uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
        .setTitle($r('app.string.resolution_1080p_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_4,
          VideoResolutionFunction.VIDEO_RESOLUTION_3, VideoResolutionFunction.VIDEO_RESOLUTION_960))
        .setValue(SettingFuncDialogItemIndex.INDEX_FOUR));
      this.filterItem(uiElements);
    }
  }

  private getPcSettingUiElements(uiElements: Map<unknown, UiElement>): void {
    if (hasCameraProfiles()) {
      this.setPcSettingUiElements(uiElements);
      return;
    }
    this.setDefaultPcSettingUiElements(uiElements);
    return;
  }

  /**
   * 照片比例展示数据组装函数
   *
   * uiElements.set(UiElement.DEFAULT...对应设置一级页面的item数据
   *  setValue(this.getDefaultValue())用于标识dialog二级弹窗页面的推荐值Index
   * uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE对应设置中dialog二级弹窗的(推荐)显示
   * uiElements.set(SettingFuncDialogItemIndex.xxx...对应设置中dialog二级弹窗的item数据
   */
  private getSettingUiElements(): Map<unknown, UiElement> {
    /* instrument ignore if*/
    const uiElements = new Map();
    if (DeviceInfo.isPc()) { //后面需要从底层读取具体支持的比例来确定UI元素
      this.getPcSettingUiElements(uiElements);
      return uiElements;
    }
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.aspect_ratio'))
      .setValue(this.getDefaultValue())
      .setIcon($r('app.media.ic_camera_setting_resolution_photo'))
      .setAccessibilityTitle($r('app.string.aspect_ratio')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement()
      .setTitle($r('app.string.photo_resolution_description_recommended', AspectRatioFunction.RATIO_NUM_4,
        AspectRatioFunction.RATIO_NUM_3))
      .setAccessibilityTitle($r('app.string.aspect_ratio'))
      .setAccessibilityDescription($r('app.string.photo_resolution_description_recommended',
        AspectRatioFunction.RATIO_NUM_4, AspectRatioFunction.RATIO_NUM_3)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.photo_resolution_description', AspectRatioFunction.RATIO_NUM_4,
        AspectRatioFunction.RATIO_NUM_3))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIR)
      .setAccessibilityTitle($r('app.string.aspect_ratio'))
      .setAccessibilityDescription($r('app.string.photo_resolution_description', AspectRatioFunction.RATIO_NUM_4,
        AspectRatioFunction.RATIO_NUM_3)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle($r('app.string.photo_resolution_description', 1, 1))
      .setValue(SettingFuncDialogItemIndex.INDEX_SEC)
      .setAccessibilityTitle($r('app.string.aspect_ratio'))
      .setAccessibilityDescription($r('app.string.photo_resolution_description', 1, 1)));
    this.getSettingUiElementsThr(uiElements);
    let conflicts: string[] = this.getRequiredConflicts()?.limitedValue?.getValues();
    if (conflicts) {
      HiLog.i(TAG, 'conflicts start B.');
      new Set(uiElements.keys()).forEach((key: number) => {
        if (AspectRatioFunction.ASPECT_RATIO_ARRAY.includes(Number(key)) && conflicts.indexOf(key.toString()) < 0) {
          const item = uiElements.get(key);
          item.setDisabled(true);
          uiElements.set(key, item);
        }
      });
    }
    return uiElements;
  }

  private getSettingUiElementsThr(uiElements: Map<unknown, UiElement>): void {
    /* instrument ignore if*/
    if (DeviceInfo.isTablet()) {
      uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
        .setTitle($r('app.string.photo_resolution_description', AspectRatioFunction.RATIO_NUM_16,
          AspectRatioFunction.RATIO_NUM_9))
        .setValue(SettingFuncDialogItemIndex.INDEX_THR)
        .setAccessibilityTitle($r('app.string.aspect_ratio'))
        .setAccessibilityDescription($r('app.string.photo_resolution_description', AspectRatioFunction.RATIO_NUM_16,
          AspectRatioFunction.RATIO_NUM_9)));
    } else {
      uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
        .setTitle($r('app.string.box_resolution_full_screen_proportion_description'))
        .setValue(SettingFuncDialogItemIndex.INDEX_THR)
        .setAccessibilityTitle($r('app.string.aspect_ratio'))
        .setAccessibilityDescription($r('app.string.box_resolution_full_screen_proportion_description')));
    }
  }

  /* instrument ignore next */
  private setDefaultPcSettingUiElements(uiElements: Map<unknown, UiElement>): Map<unknown, UiElement> {
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.aspect_ratio'))
      .setValue(this.getDefaultValue())
      .setIcon($r('app.media.ic_camera_setting_resolution_photo'))
      .setAccessibilityTitle($r('app.string.aspect_ratio')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement()
      .setTitle($r('app.string.photo_resolution_description_recommended', AspectRatioFunction.RATIO_NUM_16,
        AspectRatioFunction.RATIO_NUM_9))
      .setAccessibilityTitle($r('app.string.aspect_ratio'))
      .setAccessibilityDescription($r('app.string.photo_resolution_description_recommended',
        AspectRatioFunction.RATIO_NUM_16, AspectRatioFunction.RATIO_NUM_9)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle($r('app.string.photo_resolution_description', AspectRatioFunction.RATIO_NUM_16,
        AspectRatioFunction.RATIO_NUM_9))
      .setValue(SettingFuncDialogItemIndex.INDEX_THR)
      .setAccessibilityTitle($r('app.string.aspect_ratio'))
      .setAccessibilityDescription($r('app.string.photo_resolution_description', AspectRatioFunction.RATIO_NUM_16,
        AspectRatioFunction.RATIO_NUM_9)));
    return uiElements;
  }

  setValue(value: number): void {
    HiLog.i(TAG, `setValue value: ${value}.`);
    AspectRatioFunction.aspectRatio = value;
    this.persistValue(value);
    this.mStoreManager.postMessage(Action.updateAspectRatio(value));
    // 非OutputType.PHOTO_OUTPUT下调整图片比例,仅持久化,不更新XComponent, OutputType.NONE后期使用getStates().xxxReducer.output
    if (!OutputOperation.isPanPhotoOutput(getStates().get<ModeType>('modeReducer', 'mode'))) {
      return;
    }
    this.mStoreManager.postMessage(Action.uiState(false));
    const size = AspectRatioOperation.getPreviewProfile(value,
      getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
      getStates().get<ModeType>('modeReducer', 'mode')).size;
    const xComponentSize = DisplayCalculator.calcSurfaceDisplaySize(size.width / size.height);

    /* instrument ignore if*/
    // 竖屏相机窗口固定比例 16:9
    if (DeviceInfo.isPcAndTablet() || getStates().get<boolean>('collapsReducer', 'isShowTricollaps')) {
      if (DeviceInfo.isTablet()) {
        WindowService.getInstance().setAspectRatio(
          Number((xComponentSize.width / xComponentSize.height).toFixed(AspectRatioFunction.SPLIT_NUM)));
      } else {
        WindowService.getInstance().setAspectRatio(PcInfo.isRotatablePc() ?
        Number((RATIO_16_TO_9).toFixed(VideoResolutionFunction.SPLIT_NUM)) :
        Number((xComponentSize.width / (xComponentSize.height -
        AspectRatioFunction.WIN_DECOR_HEIGHT)).toFixed(AspectRatioFunction.SPLIT_NUM)));
      }
    }
    this.mStoreManager.postMessage(CameraAction.restart({
      zoomRatio: getStates().get<number>('zoomReducer', 'zoomRatio')
    }));
    /* instrument ignore if*/
    if (DeviceInfo.isPc()) {
      this.setPcXComponentSize(xComponentSize);
      return;
    }
    this.mStoreManager.postMessage(PreviewAction.changeXComponentAuto(xComponentSize.width, xComponentSize.height));
    if (AppStorage.get('restoreFlag')) {
      AspectRatioFunction.cacheAspectRatio = this.getDefaultValue();
    }
  }

  getValue(): number {
    AspectRatioFunction.aspectRatio = this.getPersistedValueForFrameRate();
    //高像素切换模式后会先执行restartPreview后去发互斥
    if (AspectRatioFunction.isConflictParam) {
      HiLog.i(TAG, `getValue cacheAspectRatio`);
      return AspectRatioFunction.cacheAspectRatio;
    } else {
      return AspectRatioFunction.aspectRatio;
    }
  }

  private isSupportXdRaw(): boolean {
    let resFormat = camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP;
    return resFormat === 5; // XDRAW
  }

  load(renderLocations: RenderLocation[]): void {
    HiLog.begin(TAG, 'AspectRatioFunction load');
    super.load(renderLocations);
    this.mStoreManager.postMessage(Action.updateAspectRatio(this.getValue()));
    this.mEventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM, this.onConflictParamChange.bind(this),
      this.mBase.hashCode());
    HiLog.end(TAG, 'AspectRatioFunction load');
  }

  isAvailable(): boolean {
    return true;
  }

  private onConflictParamChange(data: { id: number }): void {
    const currentFunctionId = this.getFunctionId();
    HiLog.i(TAG, `onConflictParamChange X, functionId: ${data.id}, currentFunctionId：${currentFunctionId}`);
    if (currentFunctionId !== data.id) {
      return;
    }
    const conflicts: string[] = this.getRequiredConflicts()?.limitedValue?.getValues();
    if (conflicts && conflicts?.length > 0) {
      if (AspectRatioFunction.aspectRatio === Number(conflicts[0])) {
        AspectRatioFunction.cacheAspectRatio = AspectRatioFunction.aspectRatio;
        return;
      } else {
        //缓存操作
        AspectRatioFunction.cacheAspectRatio = AspectRatioFunction.aspectRatio;
        AspectRatioFunction.aspectRatio = Number(conflicts[0]);
        AspectRatioFunction.isConflictParam = true;
      }
    } else {
      //复位操作
      AspectRatioFunction.aspectRatio = AspectRatioFunction.cacheAspectRatio ?? AspectRatioFunction.aspectRatio;
      AspectRatioFunction.isConflictParam = false;
    }
    const value: number = AspectRatioFunction.aspectRatio;
    // 非OutputType.PHOTO_OUTPUT下调整图片比例,仅持久化,不更新XComponent, OutputType.NONE后期使用getStates().xxxReducer.output
    const mode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
    HiLog.i(TAG, `onConflictParamChange X, value: ${value}, mode: ${mode}.`);
    if (!OutputOperation.isPanPhotoOutput(mode) ||
      value !== this.getValue()) {
      return;
    }
    const size = AspectRatioOperation.getPreviewProfile(value,
      getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition'), mode).size;
    const xComponentSize = DisplayCalculator.calcSurfaceDisplaySize(size.width / size.height);
    if (DeviceInfo.isPc()) {
      this.setPcXComponentSize(xComponentSize);
      return;
    }
    /* instrument ignore if*/
    this.mStoreManager.postMessage(PreviewAction.changeXComponentAuto(xComponentSize.width, xComponentSize.height));
  }

  /* instrument ignore next */
  private setPcXComponentSize(xComponentSize: { width: number, height: number }): void {
    const rotation = DisplayService.getInstance().getDisplay().rotation;
    const isRotatablePc: boolean = PcInfo.isRotatablePc();
    // 竖屏相机则需要将宽高调换
    if (isRotatablePc && (rotation === 0 || rotation === 2)) {
      const displayHeight = getStates().get<number>('windowReducer', 'windowHeight');
      if (xComponentSize.width > xComponentSize.height) {
        this.mStoreManager.postMessage(Action.changeXComponentSize(displayHeight *
          (xComponentSize.height / xComponentSize.width), displayHeight));
        return;
      } else {
        this.mStoreManager.postMessage(Action.changeXComponentSize(xComponentSize.width, xComponentSize.height));
        return;
      }
    }
    if (isRotatablePc) {
      this.mStoreManager.postMessage(Action.changeXComponentSize(xComponentSize.height, xComponentSize.width));
      return;
    }
    this.mStoreManager.postMessage(Action.changeXComponentSize(xComponentSize.width, xComponentSize.height));

    //竖屏相机竖屏状态需要对将预览界面进行收缩，使得高度与窗口高度保持一致
    if (isRotatablePc && (rotation === 0 || rotation === ROTATION_2)) {
      if (xComponentSize.width > xComponentSize.height) {
        this.mStoreManager.postMessage(Action.changeXComponentSize((xComponentSize.height * xComponentSize.height) /
        xComponentSize.width, xComponentSize.height));
        return;
      } else {
        this.mStoreManager.postMessage(Action.changeXComponentSize(xComponentSize.width, xComponentSize.height));
        return;
      }
    }

    //竖屏相机则需要将宽高调换
    if (isRotatablePc) {
      this.mStoreManager.postMessage(Action.changeXComponentSize(xComponentSize.height, xComponentSize.width));
      return;
    }

    this.mStoreManager.postMessage(Action.changeXComponentSize(xComponentSize.width, xComponentSize.height));
  }

  protected persistValue(value: number): void {
    AspectRatioFunction.mValueMap.set(this.getCacheKeyForAspectRatio(), value);
    this.mPreferencesService.putFunctionValue(PersistType.FOREVER, this.getFunctionId(),
      StringUtil.map2String(AspectRatioFunction.mValueMap));
  }

  private getPersistedValueForFrameRate(): number {
    let valueStr = this.getPersistedValue();
    if (typeof valueStr === 'number') {
      AspectRatioFunction.mValueMap.set(this.getCacheKeyForAspectRatio(), valueStr as number);
      return valueStr as number;
    }
    AspectRatioFunction.mValueMap = StringUtil.string2Map(valueStr as string) as Map<string, number>;
    HiLog.d(TAG, `getPersistedValueForFrameRate map: ${StringUtil.map2String(AspectRatioFunction.mValueMap)}`);
    if (!AspectRatioFunction.mValueMap.has(this.getCacheKeyForAspectRatio())) {
      AspectRatioFunction.mValueMap.set(this.getCacheKeyForAspectRatio(), this.getDefaultValue());
    }
    return AspectRatioFunction.mValueMap.get(this.getCacheKeyForAspectRatio());
  }

  private getCacheKeyForAspectRatio(): string {
    // VDE产品定时拍照内外屏不拉通
    return this.isUseCameraCollapsedStatus() ? 'VerdeCollaps' : 'Others';
  }

  private isUseCameraCollapsedStatus(): boolean {
    // 4：3展开态更新xcomponent过程中，突然状态改变后导致获取的分辨率是外屏分辨率全屏 1：1，如果外屏没有使用(内部window没有更新)分辨率ratio保持
    const windowWidth: number = getStates().get<number>('windowReducer', 'windowWidth');
    return windowWidth - DISPLAY_SCREEN_SIZE_PSD < COLLAPS_UNCOLLAPS_WIDTH_DIFF_MIN;

  }
}