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
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { Action } from '../../redux/actions/Action';
import lazy { DisplayCalculator } from '../../component/xcomponent/DisplayCalculator';
import lazy { VideoResolutionOperation } from './VideoResolutionOperation';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { CameraAction } from '../../camera/uithread/CameraAction';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';
import lazy { RenderType } from '../core/functionproperty/RenderType';
import lazy { UiElement } from '../core/UiElement';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { FunctionAction } from '../core/FunctionAction';
import lazy { BlurAnimateUtil } from '../../utils/BlurAnimateUtil';
import camera from '@ohos.multimedia.camera';
import lazy { OutputOperation } from '../outputswitcher/OutputOperation';
import lazy { ConflictParam } from '../core/ConflictParam';
import lazy { ValueSet } from '../core/ValueSet';
import lazy { CameraBasicService } from '../../camera/uithread/CameraBasicService';
import lazy { OutputType } from '../outputswitcher/OutputType';
import lazy { OutputSwitcher } from '../outputswitcher/OutputSwitcher';
import lazy { hasCameraProfiles } from '../../utils/FileReadUtil';
import lazy { PersistType } from '../../service/preferences/PreferencesService';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { GlobalContext } from '../../utils/GlobalContext';
import lazy { display } from '@kit.ArkUI';
import lazy { StringUtil } from '../../utils/StringUtil';
import lazy { StoreManager } from '../../worker/StoreManager';
import lazy { TabBarAction } from '../../component/tabbar/TabBarAction';
import lazy { PcInfo } from '../../component/deviceinfo/PcInfo';
import lazy { getStates } from '../../redux';
import lazy { ZoomActionType } from '../../redux/actions/ZoomActionType';
import lazy { FunctionActionType } from '../../redux/actions/FunctionActionType';
import lazy { PropTag } from '../../service/preferences/PropTag';
import lazy { CameraActionType } from '../../redux/actions/CameraActionType';
import lazy { PreviewAction } from '../../redux/actions/PreviewAction';

/* instrument ignore file */
const TAG = 'VideoResolutionFunction';
const DECIMAL_NOTATION_RADIX = 10;
const FRAME_RATE_60FPS: number = 60;
const FOOTER_BAR_COL: number = 8;

export const COMPONENT_WIDTH: number = 84;

const EPSILON = 0.1;
const RATIO_16_TO_9 = 16 / 9;
const WIN_DECOR_HEIGHT: number = 50;

// 视频分辨率
export class VideoResolutionFunction extends BaseFunction {
  public static readonly SPLIT_NUM: number = 2;
  public static readonly VIDEO_RESOLUTION_9: string = '9';
  public static readonly VIDEO_RESOLUTION_16: string = '16';
  public static readonly VIDEO_RESOLUTION_21: string = '21';
  public static readonly VIDEO_RESOLUTION_480: string = '480';
  public static readonly VIDEO_RESOLUTION_720: string = '720';
  public static readonly VIDEO_RESOLUTION_960: string = '960';
  public static readonly VIDEO_RESOLUTION_TIP_3_2K: string = '3.2K';
  public static readonly VIDEO_RESOLUTION_TIP_2_4K: string = '2.4K';
  public static readonly VIDEO_RESOLUTION_1: string = '1';
  public static readonly VIDEO_RESOLUTION_1080: string = '1080';
  public static readonly VIDEO_RESOLUTION_4: string = '4'; //单独传变量4的字串
  public static readonly VIDEO_RESOLUTION_3: string = '3';
  public static readonly VIDEO_RESOLUTION_TIP_4K: string = '4K'; //切换分辨率（16:9）传4K字串
  public static readonly VIDEO_RESOLUTION_2_7: string = '2.7';
  public static readonly VIDEO_RESOLUTION_TIP_2_7K: string = '2.7K'; //切换分辨率（16:9）传2.7K字串
  private static videoResolution: number = -1;
  private static mValueMap: Map<string, number> = new Map(); // 全量缓存数据
  private readonly RENDER_LOCATIONS: RenderLocation[] = [
    RenderLocation.TREASURE_BOX,
    RenderLocation.SETTING_MENU_VIDEO,
    RenderLocation.TAB_BAR_LIST
  ];

  constructor() {
    super();
    this.mEventBus.on(FunctionActionType.ACTION_SET_FUNCTION_CONFLICT_PARAM, this.onConflictParamChange.bind(this),
      this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.conflictManageFrameRate.bind(this), this.mBase.hashCode());
    this.conflictManageRealTimeFilter(false);
  }

  getFunctionId(): FunctionId {
    return FunctionId.VIDEO_RESOLUTION;
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
        return RenderType.POPUP_BUTTON;
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

  private getOutHomeUiElements(): Map<unknown, UiElement> {
    const uiElements = new Map();
    // title 视频分辨率: 4k 16:9    1080P 16:9    720p 16:9
    uiElements.set(UiElement.DEFAULT, new UiElement().setValue(-1)
      .setTitle($r('app.string.video_resolution'))
    );
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement().setValue(-1)
      .setTitle($r('app.string.off'))
    );
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.resolution_4K_description', VideoResolutionFunction.VIDEO_RESOLUTION_4))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIR)
    );
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle($r('app.string.resolution_1080p_description', VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setValue(SettingFuncDialogItemIndex.INDEX_THR)
    );

    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_description', VideoResolutionFunction.VIDEO_RESOLUTION_720))
      .setValue(SettingFuncDialogItemIndex.INDEX_FOUR)
    );
    return uiElements;
  }

  private handleUIElementDisabledSet(uiElements: Map<unknown, UiElement>): void {
    const conflicts: string[] = this.getRequiredConflicts()?.limitedValue?.getValues();
    if (conflicts?.length) {
      uiElements.forEach((uiElement: UiElement, index) => {
        if (!conflicts.includes((index as number).toString()) && index !== UiElement.DEFAULT
          && index !== SettingFuncDialogItemIndex.INDEX_NONE) {
          uiElement.setDisabled(true);
        }
      });
    }
    const mode = getStates().get<ModeType>('modeReducer', 'mode');
    let position = getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    let profiles: camera.VideoProfile[] = CameraAppCapability.getInstance().getVideoProfiles(position, mode);
    uiElements.forEach((conflictParam: UiElement, key) => {
      if (key !== UiElement.DEFAULT &&
        profiles[key as number - 1]?.size?.width <= 0) {
        uiElements.delete(key);
      }
    });
  }

  private setBox2_7KResolutionElement(uiElements: Map<unknown, UiElement>, textItemSec: Resource | string): void {
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIF, new UiElement()
      .setTitle($r('app.string.resolution_4K_description', VideoResolutionFunction.VIDEO_RESOLUTION_2_7))
      .setTextIcon($r('app.string.photo_resolution_description',
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_16, DECIMAL_NOTATION_RADIX),
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_9, DECIMAL_NOTATION_RADIX)))
      .setTextItemSec(textItemSec)
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_4K_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_2_7))
    );
  }

  private getBoxUiElements(): Map<unknown, UiElement> {
    if (DeviceInfo.isTablet()) {
      return this.getTabletUiElements();
    }
    const uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.treasure_box_resolution'))
      .setIcon($r('app.media.treasure_box_video_resolution'))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution')));
    this.getUiElementsCollapsFir(uiElements);
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle($r('app.string.resolution_1080p_description', VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setTextIcon($r('app.string.box_resolution_full_screen_proportion_description'))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.tabbar_resolution_full_screen_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_1080)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_description', VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setTextIcon($r('app.string.photo_resolution_description',
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_16, DECIMAL_NOTATION_RADIX),
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_9, DECIMAL_NOTATION_RADIX)))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_1080)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_description', VideoResolutionFunction.VIDEO_RESOLUTION_720))
      .setTextIcon($r('app.string.photo_resolution_description',
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_16, DECIMAL_NOTATION_RADIX),
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_9, DECIMAL_NOTATION_RADIX)))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16, VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_720)));

    const cameraAppCapability: CameraAppCapability = CameraAppCapability.getInstance();
    const position = FeatureManager.getInstance().getFunction(FunctionId.CAMERA_SWITCHER)?.getValue();
    const mode = ModeType.VIDEO;
    let videoProfiles = cameraAppCapability.getVideoProfiles(position, mode);
    uiElements.forEach((conflictParam: UiElement, key) => {
      if (key === UiElement.DEFAULT || key === SettingFuncDialogItemIndex.INDEX_NONE) {
        HiLog.i(TAG, 'getUiElements continue.');
      } else if (videoProfiles[key - 1] === undefined || videoProfiles[key - 1] === null ||
        (DeviceInfo.isTablet() && videoProfiles[key - 1]?.size?.width === 0)) {
        conflictParam.setDisabled(true);
      }
    });
    this.handleUIElementDisabledSet(uiElements);
    return uiElements;
  }

  getUiElementsLandscape(): Map<Object, UiElement> {
    const uiElements = new Map();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.treasure_box_resolution'))
      .setTextIcon($r('app.string.photo_resolution_description', parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_16,
        DECIMAL_NOTATION_RADIX), parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_9, DECIMAL_NOTATION_RADIX)))
      .setTextItemSec('1080p')
    );
    this.getUiElementsCollapsFir(uiElements);
    if (getStates().get<boolean>('collapsReducer', 'isHalfCollapsLEM')) {
      uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
        .setTitle($r('app.string.resolution_1080p_description', VideoResolutionFunction.VIDEO_RESOLUTION_1080))
        .setTextIcon($r('app.string.box_resolution_full_screen_proportion_description'))
        .setTextItemSec('1080p')
        .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
        .setAccessibilityDescription($r('app.string.resolution_1080p_description',
          VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      );
    }

    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_description', VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setTextIcon($r('app.string.photo_resolution_description',
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_16, DECIMAL_NOTATION_RADIX),
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_9, DECIMAL_NOTATION_RADIX)))
      .setTextItemSec('1080p')
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_1080))
    );
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_description', VideoResolutionFunction.VIDEO_RESOLUTION_720))
      .setTextIcon($r('app.string.photo_resolution_description',
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_16, DECIMAL_NOTATION_RADIX),
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_9, DECIMAL_NOTATION_RADIX)))
      .setTextItemSec('720p')
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_720))
    );
    this.handleUIElementDisabledSet(uiElements);
    return uiElements;
  }

  private getUiElementsCollapsFir(uiElements: Map<Object, UiElement>): void {
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.resolution_4K_description', VideoResolutionFunction.VIDEO_RESOLUTION_4))
      .setTextIcon($r('app.string.photo_resolution_description',
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_16, DECIMAL_NOTATION_RADIX),
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_9, DECIMAL_NOTATION_RADIX)))
      .setTextItemSec('4K')
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_4K_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16, VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_TIP_4K))
    );
  }

  getUiElementsCollaps(): Map<Object, UiElement> {
    const uiElements = new Map();
    const isShowLandscape = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    const isHalfCollapsLEM = getStates().get<boolean>('collapsReducer', 'isHalfCollapsLEM');
    const defaultUiElement = new UiElement().setTitle($r('app.string.treasure_box_resolution'));
    if (!isShowLandscape) {
      defaultUiElement.setIcon($r('app.media.treasure_box_video_resolution'))
        .setTextIcon($r('app.string.photo_resolution_description', parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_16,
          DECIMAL_NOTATION_RADIX), parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_9, DECIMAL_NOTATION_RADIX)))
        .setTextItemSec('1080p')
        .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
        .setAccessibilityDescription('1080p');
    }
    uiElements.set(UiElement.DEFAULT, defaultUiElement);

    this.getUiElementsCollapsFir(uiElements);

    if (isHalfCollapsLEM || !isShowLandscape) {
      uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
        .setTextItemSec('1080p')
      );
    }

    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTextItemSec('1080p')
    );

    this.handleUIElementDisabledSet(uiElements);
    return uiElements;
  }

  public getTabletUiElements(): Map<Object, UiElement> {
    const uiElements = new Map();
    const defaultUiElement = new UiElement().setTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'));
    uiElements.set(UiElement.DEFAULT, defaultUiElement);
    HiLog.i(TAG, `isTabletUiElements  cameraPosition = ${getStates()
      .get<camera.CameraPosition>('cameraReducer', 'cameraPosition')}`);
    if (getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition') !==
    camera.CameraPosition.CAMERA_POSITION_FRONT) {
      this.getUiElementsCollapsFir(uiElements);
    }
    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_description', VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setTextIcon($r('app.string.photo_resolution_description',
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_16, DECIMAL_NOTATION_RADIX),
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_9, DECIMAL_NOTATION_RADIX)))
      .setTextItemSec('1080p')
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_1080))
    );
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_description', VideoResolutionFunction.VIDEO_RESOLUTION_720))
      .setTextIcon($r('app.string.photo_resolution_description',
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_16, DECIMAL_NOTATION_RADIX),
        parseInt(VideoResolutionFunction.VIDEO_RESOLUTION_9, DECIMAL_NOTATION_RADIX)))
      .setTextItemSec('720p')
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_720))
    );
    this.handleUIElementDisabledSet(uiElements);
    return uiElements;
  }

  private setSetting2_7KResolutionElement(uiElements: Map<unknown, UiElement>): void {
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIF, new UiElement()
      .setTitle($r('app.string.resolution_4K_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9, VideoResolutionFunction.VIDEO_RESOLUTION_TIP_2_7K))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIF)
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_4K_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_TIP_2_7K)));
  }

  private getSettingUiElementsFir(uiElements: Map<unknown, UiElement>): void {
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.resolution_4K_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9, VideoResolutionFunction.VIDEO_RESOLUTION_TIP_4K))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIR)
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_4K_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16, VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_TIP_4K)));
  }

  private getSettingUiElementsSec(uiElements: Map<unknown, UiElement>): void {
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle($r('app.string.resolution_full_screen_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setValue(SettingFuncDialogItemIndex.INDEX_SEC)
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_full_screen_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_1080)));
  }

  private getSettingUiElementsThr(uiElements: Map<unknown, UiElement>): void {
    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9, VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setValue(SettingFuncDialogItemIndex.INDEX_THR)
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16, VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_1080)));
  }

  private getSettingUiElementsFour(uiElements: Map<unknown, UiElement>): void {
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9, VideoResolutionFunction.VIDEO_RESOLUTION_720))
      .setValue(SettingFuncDialogItemIndex.INDEX_FOUR)
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16, VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_720)));
  }

  /**
   * 视频分辨率展示数据组装函数
   *
   * uiElements.set(UiElement.DEFAULT...对应设置一级页面的item数据
   *  setValue(SettingFuncDialogItemIndex.INDEX_SEC)用于标识dialog二级弹窗页面的推荐值Index
   * uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE对应设置中dialog二级弹窗的(推荐)显示
   * uiElements.set(SettingFuncDialogItemIndex.xxx...对应设置中dialog二级弹窗的item数据
   */
  private getSettingUiElements(): Map<unknown, UiElement> {
    const uiElements = new Map();
    if (DeviceInfo.isPc()) {
      this.getPcCameraUiElement(uiElements);
      return uiElements;
    }
    let defaultValue: number = this.getDefaultValue();
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.video_resolution'))
      .setValue(defaultValue)
      .setIcon($r('app.media.ic_camera_setting_resolution_video'))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution')));
    this.getSettingUiElementsFir(uiElements);
    this.getSettingUiElementsSec(uiElements);
    this.getSettingUiElementsThr(uiElements);
    this.getSettingUiElementsFour(uiElements);

    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, uiElements.get(defaultValue));

    const cameraAppCapability: CameraAppCapability = CameraAppCapability.getInstance();
    const position = FeatureManager.getInstance().getFunction(FunctionId.CAMERA_SWITCHER)?.getValue();
    const mode = ModeType.VIDEO;
    let videoProfiles = cameraAppCapability.getVideoProfiles(position, mode);
    uiElements.forEach((conflictParam: UiElement, key) => {
      if (key === UiElement.DEFAULT || key === SettingFuncDialogItemIndex.INDEX_NONE) {
        HiLog.i(TAG, 'getUiElements continue.');
      } else if (videoProfiles[key - 1] === undefined || videoProfiles[key - 1] === null ||
        (DeviceInfo.isTablet() && videoProfiles[key - 1]?.size?.width === 0)) {
        uiElements.delete(key);
      }
    });
    this.handleUIElementDisabledSet(uiElements);
    return uiElements;
  }

  private setDefaultPcCameraUiElement(uiElements: Map<unknown, UiElement>): void {
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.video_resolution'))
      .setValue(this.getDefaultValue())
      .setIcon($r('app.media.ic_camera_setting_resolution_video'))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement()
      .setTitle($r('app.string.resolution_1080p_proportion_description_recommond',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_720))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description_recommond',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_720)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9, VideoResolutionFunction.VIDEO_RESOLUTION_720))
      .setValue(SettingFuncDialogItemIndex.INDEX_FOUR)
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_720)));
  }

  private filterItem(uiElements: Map<unknown, UiElement>): void {
    const cameraAppCapability: CameraAppCapability = CameraAppCapability.getInstance();
    const position = FeatureManager.getInstance().getFunction(FunctionId.CAMERA_SWITCHER)?.getValue();
    const mode = ModeType.VIDEO;
    let videoProfiles = cameraAppCapability?.getVideoProfiles(position, mode);
    uiElements.forEach((conflictParam: UiElement, key) => {
      if (key === UiElement.DEFAULT || key === SettingFuncDialogItemIndex.INDEX_NONE) {
        HiLog.i(TAG, 'getUiElements continue.');
      } else if (typeof (key) === 'number' && (videoProfiles[key - 1] === undefined ||
        videoProfiles[key - 1] === null || videoProfiles[key - 1]?.size?.width === 0)) {
        uiElements.delete(key);
      }
    });
    return;
  }

  private setDefaultPcSettingItem(uiElements: Map<unknown, UiElement>): void {
    uiElements.set(UiElement.DEFAULT, new UiElement().setTitle($r('app.string.video_resolution'))
      .setValue(this.getDefaultValue())
      .setIcon($r('app.media.ic_camera_setting_resolution_video'))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution')));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_NONE, new UiElement()
      .setTitle($r('app.string.resolution_1080p_proportion_description_recommond',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9, VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description_recommond',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_1080)));
    return;
  }

  private setFirstLevelItem(uiElements: Map<unknown, UiElement>): void {
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.resolution_4K_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9, VideoResolutionFunction.VIDEO_RESOLUTION_TIP_4K))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIR)
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_TIP_4K)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle($r('app.string.resolution_1080p_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9, VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setValue(SettingFuncDialogItemIndex.INDEX_SEC)
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_1080)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9, VideoResolutionFunction.VIDEO_RESOLUTION_720))
      .setValue(SettingFuncDialogItemIndex.INDEX_THR)
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_720)));
    return;
  }

  private setSecondLevelItem(uiElements: Map<unknown, UiElement>): void {
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIF, new UiElement()
      .setTitle($r('app.string.resolution_1080p_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_4,
        VideoResolutionFunction.VIDEO_RESOLUTION_3, VideoResolutionFunction.VIDEO_RESOLUTION_960))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIF)
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_4,
        VideoResolutionFunction.VIDEO_RESOLUTION_3,
        VideoResolutionFunction.VIDEO_RESOLUTION_960)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SIX, new UiElement()
      .setTitle($r('app.string.resolution_1080p_proportion_description', VideoResolutionFunction.VIDEO_RESOLUTION_4,
        VideoResolutionFunction.VIDEO_RESOLUTION_3, VideoResolutionFunction.VIDEO_RESOLUTION_480))
      .setValue(SettingFuncDialogItemIndex.INDEX_SIX)
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_4,
        VideoResolutionFunction.VIDEO_RESOLUTION_3,
        VideoResolutionFunction.VIDEO_RESOLUTION_480)));
    return;
  }

  private setPcCameraUiElement(uiElements: Map<unknown, UiElement>): void {
    this.setDefaultPcSettingItem(uiElements);
    this.setFirstLevelItem(uiElements);
    this.setSecondLevelItem(uiElements);
    this.setSecondLevelItem(uiElements);
    this.filterItem(uiElements);
  }

  private getPcCameraUiElement(uiElements: Map<unknown, UiElement>): void {
    if (hasCameraProfiles()) {
      this.setPcCameraUiElement(uiElements);
      return;
    }
    this.setDefaultPcCameraUiElement(uiElements);
  }

  private getTwhCameraUiElement(uiElements: Map<unknown, UiElement>): void {
    const isShowLandscape = getStates().get<boolean>('collapsReducer', 'isShowLandscape');
    this.getSettingUiElementsFir(uiElements);
    this.getSettingUiElementsSec(uiElements);
    this.getSettingUiElementsThr(uiElements);
    this.getSettingUiElementsFour(uiElements);
  }

  private setTabBar2_7KResolutionElement(uiElements: Map<unknown, UiElement>): void {
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIF, new UiElement()
      .setTitle($r('app.string.resolution_4K_description', VideoResolutionFunction.VIDEO_RESOLUTION_2_7))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIF)
      .setTextItemSec($r('app.string.resolution_4K_proportion_tabbar_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16, VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_TIP_2_7K))
      .setDesc($r('app.string.photo_resolution_description', 16, 9))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_4K_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_2_7)));
  }

  private getTabBarUiElements(): Map<unknown, UiElement> {
    const uiElements = new Map();
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.resolution_4K_description', VideoResolutionFunction.VIDEO_RESOLUTION_4))
      .setValue(SettingFuncDialogItemIndex.INDEX_FIR)
      .setTextItemSec($r('app.string.resolution_4K_proportion_tabbar_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16, VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_TIP_4K))
      .setDesc($r('app.string.photo_resolution_description', 16, 9))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_4K_proportion_tabbar_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16, VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_TIP_4K)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setValue(SettingFuncDialogItemIndex.INDEX_SEC)
      .setTextItemSec($r('app.string.tabbar_resolution_full_screen_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setTitle($r('app.string.resolution_1080p_description', VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setDesc($r('app.string.box_resolution_full_screen_proportion_description'))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.tabbar_resolution_full_screen_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_1080)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setValue(SettingFuncDialogItemIndex.INDEX_THR)
      .setTextItemSec($r('app.string.resolution_1080p_proportion_description_tabbar_recommond',
        VideoResolutionFunction.VIDEO_RESOLUTION_16, VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setTitle($r('app.string.resolution_1080p_description', VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setDesc($r('app.string.photo_resolution_description', 16, 9))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description_tabbar_recommond',
        VideoResolutionFunction.VIDEO_RESOLUTION_16, VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_1080)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
      .setValue(SettingFuncDialogItemIndex.INDEX_FOUR)
      .setTextItemSec($r('app.string.resolution_1080p_proportion_tabbar_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16, VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_720))
      .setTitle($r('app.string.resolution_1080p_description', VideoResolutionFunction.VIDEO_RESOLUTION_720))
      .setDesc($r('app.string.photo_resolution_description', 16, 9))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_tabbar_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16, VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_720)));
    const cameraAppCapability: CameraAppCapability = CameraAppCapability.getInstance();
    const position = FeatureManager.getInstance().getFunction(FunctionId.CAMERA_SWITCHER)?.getValue();
    const mode = ModeType.VIDEO;
    let videoProfiles = cameraAppCapability.getVideoProfiles(position, mode);
    uiElements.forEach((conflictParam: UiElement, key) => {
      if (key === UiElement.DEFAULT || key === SettingFuncDialogItemIndex.INDEX_NONE) {
        HiLog.i(TAG, 'getUiElements continue.');
      } else if (videoProfiles[key - 1] === undefined || videoProfiles[key - 1] === null ||
        (DeviceInfo.isTablet() && videoProfiles[key - 1]?.size?.width === 0)) {
        conflictParam.setDisabled(true);
      }
    });
    this.handleUIElementDisabledSet(uiElements);
    return uiElements;
  }

  private getTwhTabBarCameraUiElementFIR(uiElements: Map<unknown, UiElement>): void {
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FIR, new UiElement()
      .setTitle($r('app.string.resolution_4K_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_4))
      .setDesc($r('app.string.resolution_4K_proportion_tabbar_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_TIP_4K))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_4K_proportion_tabbar_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_TIP_4K)));
  }

  private getTwhTabBarCameraUiElementSec(uiElements: Map<unknown, UiElement>): void {
    uiElements.set(SettingFuncDialogItemIndex.INDEX_SEC, new UiElement()
      .setTitle($r('app.string.resolution_1080p_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setDesc($r('app.string.tabbar_resolution_full_screen_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.tabbar_resolution_full_screen_proportion_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_1080)));
  }

  private getTwhTabBarCameraUiElement(uiElements: Map<unknown, UiElement>): void {
    this.getTwhTabBarCameraUiElementFIR(uiElements);
    this.getTwhTabBarCameraUiElementSec(uiElements);
    uiElements.set(SettingFuncDialogItemIndex.INDEX_THR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setDesc($r('app.string.resolution_1080p_proportion_description_tabbar_recommond',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_1080))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_description_tabbar_recommond',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_1080)));
    uiElements.set(SettingFuncDialogItemIndex.INDEX_FOUR, new UiElement()
      .setTitle($r('app.string.resolution_1080p_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_720))
      .setDesc($r('app.string.resolution_1080p_proportion_tabbar_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_720))
      .setAccessibilityTitle($r('app.string.treasure_box_resolution'))
      .setAccessibilityDescription($r('app.string.resolution_1080p_proportion_tabbar_description',
        VideoResolutionFunction.VIDEO_RESOLUTION_16,
        VideoResolutionFunction.VIDEO_RESOLUTION_9,
        VideoResolutionFunction.VIDEO_RESOLUTION_720)));

    this.handleUIElementDisabledSet(uiElements);
  }

  getDefaultValue(): number {
    if (DeviceInfo.isTv()) {
      return <number> SettingFuncDialogItemIndex.INDEX_FIR; // tv recommend 4K
    }
    if (DeviceInfo.isPc()) {
      if (!hasCameraProfiles()) {
        return <number> SettingFuncDialogItemIndex.INDEX_FOUR; // recommend 16:9 720p
      }
      return <number> SettingFuncDialogItemIndex.INDEX_SEC; // recommend 16:9 720p
    }
    if (DeviceInfo.isTablet()) {
      let profiles: camera.VideoProfile[] = CameraAppCapability.getInstance().getVideoProfiles(
        getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        getStates().get<ModeType>('modeReducer', 'mode'));
      let itemIndex = 0;
      let availableArr = [];
      for (let item of profiles) {
        itemIndex += 1;
        if (item.size.width <= 0) {
          continue;
        }
        availableArr.push(itemIndex);
      }
      if (availableArr.indexOf(SettingFuncDialogItemIndex.INDEX_THR) >= 0) {
        return <number> SettingFuncDialogItemIndex.INDEX_THR;
      }
      return availableArr.length > 0 ? availableArr[0] : SettingFuncDialogItemIndex.INDEX_THR;
    }
    return <number> SettingFuncDialogItemIndex.INDEX_THR; // recommend 16:9 1080p
  }

  private updateXComponent(value: number): void {
    let position = FeatureManager.getInstance().getFunction(FunctionId.CAMERA_SWITCHER)?.getValue();
    let mode = getStates().get<ModeType>('modeReducer', 'mode');
    let previewSize = VideoResolutionOperation.getPreviewProfile(value, position, mode)?.size;
    if (!previewSize) {
      return;
    }
    let previewRatio = previewSize.width / previewSize.height;
    let xComponentSize = DisplayCalculator.calcSurfaceDisplaySize(previewRatio);

    // 竖屏相机窗口固定比例 16:9
    if (DeviceInfo.isPc()) {
      WindowService.getInstance().setAspectRatio(PcInfo.isRotatablePc() ?
      Number((RATIO_16_TO_9).toFixed(VideoResolutionFunction.SPLIT_NUM)) :
      Number((xComponentSize.width /
        (xComponentSize.height - WIN_DECOR_HEIGHT)).toFixed(VideoResolutionFunction.SPLIT_NUM)));
    }
    if (DeviceInfo.isTablet()) {
      WindowService.getInstance().setAspectRatio(
        Number((xComponentSize.width / xComponentSize.height).toFixed(VideoResolutionFunction.SPLIT_NUM)));
    }
    BlurAnimateUtil.setWaitForPositionFlag(true);
    if (DeviceInfo.isPc()) {
      this.setPcXComponentSize(xComponentSize);
      return;
    }
    if (DeviceInfo.isTablet()) {
      // 等平板和展开态预览二合一之后，此处删除
      this.mStoreManager.postMessage(Action.changeXComponentSize(xComponentSize.width, xComponentSize.height));
    } else {
      this.mStoreManager.postMessage(PreviewAction.changeXComponentAuto(xComponentSize.width,
        xComponentSize.height));
    }
  }

  private setPcXComponentSize(xComponentSize: { width: number, height: number }): void {
    const rotation = DisplayService.getInstance().getDisplay().rotation;
    // 竖屏相机则需要将宽高调换
    if (PcInfo.isRotatablePc() && (rotation === 0 || rotation === 2)) {
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
    if (PcInfo.isRotatablePc()) {
      this.mStoreManager.postMessage(Action.changeXComponentSize(xComponentSize.height, xComponentSize.width));
      return;
    }
    this.mStoreManager.postMessage(Action.changeXComponentSize(xComponentSize.width, xComponentSize.height));
  }

  setValue(value: number): void {
    HiLog.i(TAG, `setValue value: ${value}.`);
    VideoResolutionFunction.videoResolution = value;
    this.persistValue(value);
    this.conflictManageFrameRate();
    this.conflictManageRealTimeFilter();
    this.mStoreManager.postMessage(Action.updateVideoResolution(value));
    if (value !== SettingFuncDialogItemIndex.INDEX_FIR) {
      this.mPreferencesService.putPropValue(PersistType.FOREVER, PropTag.FILTER_CONFLICT_RESOLUTION, false);
    }

    //如果是前置,通知切换按钮,下次切换前后置无需切换分辨率
    let position = FeatureManager.getInstance().getFunction(FunctionId.CAMERA_SWITCHER)?.getValue();
    if (DeviceInfo.isTablet() && position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
      this.mStoreManager.postMessage(Action.changeResolution());
    }

    // 例如拍照模式下进入设置页调整视频分辨率,仅持久化,不更新XComponent
    const isPanVideoOutput = OutputOperation.isPanVideoOutput(getStates().get<ModeType>('modeReducer', 'mode'));
    if (!isPanVideoOutput) {
      return;
    }
    HiLog.i(TAG, 'VideoResolutionFunction value change');
    this.updateXComponent(value);
    const state = getStates();
    this.mStoreManager.postMessage(CameraAction.restart({
      zoomRatio: state.get<number>('zoomReducer', 'zoomRatio')
    }));
    this.mEventBus.emit(ZoomActionType.ACTION_CHANGE_ZOOM_BY_VIDEORESOLUTION, []);
  }

  getValue(): number {
    let videoResolutionValue = this.getVideoResolutionValue();
    if (!DeviceInfo.isPc() &&
      (getStates().get<boolean>('collapsReducer', 'isShowLandscape') ||
      getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed'))) {
      return videoResolutionValue === SettingFuncDialogItemIndex.INDEX_SEC ?
      SettingFuncDialogItemIndex.INDEX_THR : videoResolutionValue;
    }
    if (!videoResolutionValue) {
      videoResolutionValue = this.getDefaultValue();
    }
    return videoResolutionValue;
  }

  private getVideoResolutionValue(): number {
    const conflicts: string[] = this.getRequiredConflicts()?.limitedValue?.getValues();
    HiLog.d(TAG, `getValue conflicts: ${JSON.stringify(conflicts)}`);
    if (conflicts && conflicts?.length > 0) {
      return this.getValueInConflicts(conflicts);
    }
    VideoResolutionFunction.videoResolution = this.getPersistedValueForVideoResolution();
    // 暂时注释这段代码，为了解决相机设置中视频分辨率切换不成功的问题
    // 也有可能是因为设备不支持相关分辨率导致的
    // if ((VideoResolutionFunction.videoResolution !== SettingFuncDialogItemIndex.INDEX_SEC &&
    //   VideoResolutionFunction.videoResolution !== SettingFuncDialogItemIndex.INDEX_THR)) {
    //   HiLog.i(TAG, 'VdeCollapsed VideoResolution.');
    //   VideoResolutionFunction.videoResolution = SettingFuncDialogItemIndex.INDEX_SEC;
    // }
    if (VideoResolutionFunction.videoResolution === SettingFuncDialogItemIndex.INDEX_FIF && !DeviceInfo.isPc()) {
      return this.getDefaultValue();
    }
    return VideoResolutionFunction.videoResolution;
  }

  private getValueInConflicts(conflicts: string[]): number {
    VideoResolutionFunction.videoResolution = this.getPersistedValueForVideoResolution();
    if (conflicts.includes(String(VideoResolutionFunction.videoResolution))) {
      return VideoResolutionFunction.videoResolution;
    }
    if (conflicts.includes(String(SettingFuncDialogItemIndex.INDEX_THR))) {
      return SettingFuncDialogItemIndex.INDEX_THR;
    }
    return Number(conflicts[0]);
  }

  private getPersistedValueForVideoResolution(): number {
    let valueStr = this.getPersistedValue();
    if (typeof valueStr === 'number') {
      VideoResolutionFunction.mValueMap.set(this.getCacheKeyForVideoResolution(), valueStr as number);
      return valueStr as number;
    }
    VideoResolutionFunction.mValueMap = StringUtil.string2Map(valueStr as string) as Map<string, number>;
    if (!VideoResolutionFunction.mValueMap.has(this.getCacheKeyForVideoResolution())) {
      VideoResolutionFunction.mValueMap.set(this.getCacheKeyForVideoResolution(), this.getDefaultValue());
    }
    return VideoResolutionFunction.mValueMap.get(this.getCacheKeyForVideoResolution());
  }

  isAvailable(): boolean {
    return true;
  }

  private onConflictParamChange(data: { id: number }): void {
    const mode = getStates().get<ModeType>('modeReducer', 'mode');
    if (this.getFunctionId() !== data.id || (mode !== ModeType.VIDEO)) {
      return;
    }
    StoreManager.getInstance().postMessage(TabBarAction.updateTextList());
    HiLog.i(TAG, 'onConflictParamChange E');
    const val = this.getValue();
    this.updateXComponent(val);
    HiLog.i(TAG, `onConflictParamChange id: data.id, value: ${val}`);
  }

  load(renderLocations: RenderLocation[]): void {
    HiLog.i(TAG, 'VideoResolutionFunction load, X.');
    super.load(renderLocations);
    this.mStoreManager.postMessage(Action.updateVideoResolution(this.getValue()));
    HiLog.i(TAG, 'VideoResolutionFunction load, E.');
  }

  private conflictManageFrameRate(): void {
    let conflictParam: ConflictParam = ConflictParam.emptyParam();
    if (DeviceInfo.isTablet()) {
      let frameRate: number = CameraBasicService.getInstance().getVideoFrameRate();
      if (VideoResolutionFunction.videoResolution === SettingFuncDialogItemIndex.INDEX_FIR ||
        frameRate === FRAME_RATE_60FPS) {
        conflictParam = new ConflictParam().setLimitedValueSet(new ValueSet().setValues(['false']));
        conflictParam.disabled = true;
      }
      if (VideoResolutionFunction.videoResolution === SettingFuncDialogItemIndex.INDEX_FIR) {
        const index: string = SettingFuncDialogItemIndex.INDEX_FIR.toString();
        this.mConflictManager.setConflictParam(FunctionId.FRAME_RATE, new ConflictParam()
          .setLimitedValueSet(new ValueSet().setValues([index])));
      } else {
        this.mConflictManager.setConflictParam(FunctionId.FRAME_RATE, ConflictParam.emptyParam());
      }
    }
  }

  private conflictManageRealTimeFilter(isInitialized: boolean = true): void {
    if (!isInitialized) {
      return;
    }
  }

  protected persistValue(value: number): void {
    VideoResolutionFunction.mValueMap.set(this.getCacheKeyForVideoResolution(), value);
    this.mPreferencesService.putFunctionValue(PersistType.FOREVER, this.getFunctionId(),
      StringUtil.map2String(VideoResolutionFunction.mValueMap));
  }

  private getCacheKeyForVideoResolution(): string {
    // VDE产品定时拍照内外屏不拉通
    return 'Others';
  }

  private string2Map(str: string): Map<string, number> {
    let resultMap = new Map();
    if (!str || typeof str === 'number' || str === '' || str.length <= 2) {
      return resultMap;
    }
    let jsonString = JSON.parse(str);
    for (let [key, value] of jsonString) {
      resultMap.set(key, value);
    }
    return resultMap;
  }
}