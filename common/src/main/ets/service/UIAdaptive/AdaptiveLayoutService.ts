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
import lazy { ModeType } from '../../mode/ModeType';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { DisplayCalculator } from '../../component/xcomponent/DisplayCalculator';
import lazy { TreasureBoxAction } from '../../component/treasurebox/reduce/TreasureBoxAction';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { SettingFuncDialogItemIndex } from '../../component/settingview/SettingFuncDialogItemIndex';
import lazy { WindowService } from '../window/WindowService';
import lazy { PickerUtils } from '../../utils/PickerUtils';
import lazy { display, window } from '@kit.ArkUI';
import lazy { DisplayService } from './DisplayService';
import lazy { execDispatch, getStates } from '../../redux';
import { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';

const TAG: string = 'AdaptiveLayoutService';

export interface ExtendBarData {
  isShowExtendBar: boolean;
  isCapture: boolean;
  isBeautyTheme?: boolean
}

export const MARGIN_MIN: number = 4;

export const TAB_BAR_HEIGHT: number = 30;

export const TRANSVERSE_16_9_TOP_MARGIN: number = 70;

export const ZOOM_VIEW_HEIGHT: number = 80;

export const VDE_ZOOM_VIEW_HEIGHT: number = 60;

export const PORTRAIT_BEAUTY_THEME: number = 98;

export const MODE_BAR_HEIGHT: number = 56;

export const FOOT_BAR_HEIGHT: number = 72;

// 额外加上三键导航栏高度
export const BOTTOM_MARGIN: number = 40 + (DeviceInfo.isUis7885() ? 24 : (DeviceInfo.isRk3568() ? 36 : 0));

export const ARROW_HEIGHT: number = 32;

export const VDE_COLLAPS_ARROW_HEIGHT: number = 40;

export const TREASURE_BOX_ELEMENT_HEIGHT: number = 72;

export const TREASURE_BOX_ELEMENT_WIDTH: number = 70;

export const TREASURE_BOX_ELEMENT_HALF_COLLAPS_LENGTH: number = 64;

export const TREASURE_BOX_ELEMENT_VDE_COLLAPS_WIDTH: number = 40;

export const TREASURE_BOX_ELEMENT_VDE_COLLAPS_HEIGHT: number = 40;

const MAX_DIFF_HEIGHT: number = 100;
const MIN_DIFF_HEIGHT: number = 42;
const ZOOM_USABLE_HEIGHT: number = 20;
const MAX_COMPO_MARGIN: number = 15;
const MIN_COMPO_MARGIN: number = 9;
const DEFAULT_RATIO: number = 837 / 388; //2.15
const FLOATING_RATIO: number = 632 / 388; // 1.62
const LANDSCAPE_DEFAULT_RATIO: number = 801 / 346; //2.31
const LANDSCAPE_SPLIT_RATIO: number = 799 / 352; //2.27
const LANDSCAPE_SPLIT_HORIZONTAL_RATIO: number = 712 / 396; //1.79
const LANDSCAPE_FLOATING_RATIO: number = 649 / 346; //1.87
const PREVIEW_POSITION_TRICOLLAPS_FLOATING_OFFSET: number = 10;

const NUM_16: number = 16;
const NUM_9: number = 9;
const NUM_6: number = 6;
const NUM_3_TO_4: number = 3 / 4;

export const NUMBER_MIN: number = 0.09;

export const NUMBER_MIN_VDE: number = 0.06;

export class AdaptiveLayoutService {
  private static instance: AdaptiveLayoutService;
  private topAvoidArea: number = 33; // UIExtension无法获取该值，给个默认值
  private bottomAvoidArea: number = 0;

  public previewPosition16to9: number = 0;
  public previewPosition4to3: number = 0;
  public previewPosition1to1: number = 0;
  public previewPosition: number = 0;
  public previewPositionDefaultConst: number = 0;
  public tabBarPosition: number = 0;
  public zoomPosition: number = 0; // 老变焦布局规则RingZoomPosition-Deprecated
  public rouletteZoomPosition: number = 0;
  public modeBarPosition: number = 0;
  public footBarPosition: number = 0;
  public arrowPosition: number = 0;

  public compoMargin: number = 0;
  public videoTimerPosition: number = 0;
  public lightPaintingTimerPosition: number = 0;
  public uncollapsBoxMargin: number = 0;
  public arrowUpDistance: number = 0;
  public preview4to3Height: number = 0;

  public static getInstance(): AdaptiveLayoutService {
    if (!AdaptiveLayoutService.instance) {
      AdaptiveLayoutService.instance = new AdaptiveLayoutService();
    }
    return AdaptiveLayoutService.instance;
  }

  private constructor() {
    this.bottomAvoidArea = BOTTOM_MARGIN;
  }

  /* *
   * 直板形态布局规则,自底向上
   * */
  public calLayoutRuleParam(width: number, height: number): void {
    HiLog.i(TAG, `calLayoutRuleParam begin, windowWidth: ${width}, windowHeight: ${height}.`);
    this.preview4to3Height = Math.ceil(width / NUM_3_TO_4);
    const preview16to9Height = this.get16to9PreviewHeight(width, height); // 考虑曲面后16:9预览高
    const defaultHeight: number = width > preview16to9Height ? Math.floor(NUM_16 / NUM_9 * width) : preview16to9Height;
    HiLog.i(TAG, `preview16to9Height: ${preview16to9Height}, preview4to3Height: ${this.preview4to3Height}.`);
    this.buttonComponentCalculation(width, height, defaultHeight - this.preview4to3Height - FOOT_BAR_HEIGHT);
    this.previewPositionCalculation(width, height, preview16to9Height, defaultHeight);

    this.videoTimerPosition = Math.max(this.previewPosition4to3, this.previewPosition16to9);
    this.lightPaintingTimerPosition = this.previewPosition4to3;
    const oldArrowUpDistance = this.arrowUpDistance;
    this.arrowUpDistance = this.arrowPosition - (this.modeBarPosition + FOOT_BAR_HEIGHT + this.compoMargin);
    HiLog.i(TAG, 'calLayoutRuleParam end.');
  }

  private buttonComponentCalculation(width: number, height: number, diffHeight: number): void {
    if (diffHeight > MAX_DIFF_HEIGHT) {
      this.compoMargin = MAX_COMPO_MARGIN;
    } else if (diffHeight < MIN_DIFF_HEIGHT) {
      this.compoMargin = MIN_COMPO_MARGIN;
    } else {
      this.compoMargin = Math.floor((diffHeight - MIN_DIFF_HEIGHT) / (MAX_DIFF_HEIGHT - MIN_DIFF_HEIGHT) *
        (MAX_COMPO_MARGIN - MIN_COMPO_MARGIN) + MIN_COMPO_MARGIN);
    }
    HiLog.i(TAG, `compoMargin: ${this.compoMargin}, diffHeight: ${diffHeight}.`);
    this.arrowPosition = height - ARROW_HEIGHT - this.bottomAvoidArea;
    this.footBarPosition = this.arrowPosition - FOOT_BAR_HEIGHT - this.compoMargin;
    this.modeBarPosition = this.footBarPosition - MODE_BAR_HEIGHT - this.compoMargin;
    this.zoomPosition = this.modeBarPosition - ZOOM_VIEW_HEIGHT - this.compoMargin;
    HiLog.i(TAG, `arrowPosition: ${this.arrowPosition}, bottomAvoidArea: ${this.bottomAvoidArea}.`);
    HiLog.i(TAG, `modeBarPosition: ${this.modeBarPosition}, zoomPosition: ${this.zoomPosition}.`);
  }

  /* instrument ignore next */
  private previewPositionCalculation(windowWidth: number, windowHeight: number, preview16to9Height: number,
    defaultHeight: number): void {
    if (windowHeight / windowWidth < FLOATING_RATIO + NUMBER_MIN) {
      // 直板机悬浮窗
      this.previewPosition16to9 = DisplayService.getInstance().isOrientationVertical() ? 0 : TRANSVERSE_16_9_TOP_MARGIN;
      this.previewPosition4to3 = this.arrowPosition + ARROW_HEIGHT - this.preview4to3Height;
      this.previewPosition1to1 = this.previewPosition4to3;
    } else if (windowHeight / windowWidth < LANDSCAPE_FLOATING_RATIO + NUMBER_MIN) {
      // 悬浮窗
      this.previewPosition1to1 = this.modeBarPosition - this.compoMargin - windowWidth;
      if (windowWidth > preview16to9Height) {
        // 当预览旋转场景
        const preview4to3Height = Math.ceil(windowWidth * NUM_3_TO_4);
        this.previewPosition4to3 = this.previewPosition1to1;
        this.previewPosition16to9 = this.previewPosition4to3 - ((preview16to9Height - preview4to3Height) >> 1);
      } else {
        this.previewPosition16to9 = windowHeight - defaultHeight;
        this.previewPosition4to3 = this.arrowPosition - this.preview4to3Height;
      }
    } else {
      // default
      if (windowWidth > preview16to9Height) {
        // 当预览旋转场景
        this.previewPosition1to1 = this.modeBarPosition - windowWidth - this.compoMargin;
        this.previewPosition4to3 = this.modeBarPosition - Math.floor(windowWidth * NUM_3_TO_4);
        this.previewPosition16to9 = this.previewPosition4to3 + ((windowWidth * NUM_3_TO_4) >> 1);
      } else {
        this.previewPosition16to9 =
          windowHeight - this.bottomAvoidArea - defaultHeight - ARROW_HEIGHT - (this.compoMargin / MARGIN_MIN);
        this.previewPosition4to3 = this.previewPosition16to9;
        this.previewPosition1to1 = Math.ceil(this.previewPosition4to3 + windowWidth / NUM_6);
      }
    }
    this.previewPositionDefaultConst = this.previewPosition16to9;
    this.previewPosition = this.previewPosition16to9;

    const topRemainingHeight: number =
      Math.max(Math.min(this.previewPosition4to3, this.previewPosition1to1) - this.topAvoidArea - TAB_BAR_HEIGHT, 0);
    this.tabBarPosition = this.topAvoidArea + (topRemainingHeight >> 1);
    if ((this.tabBarPosition + TAB_BAR_HEIGHT > this.previewPosition4to3) && PickerUtils.getIsPicker()) {
      this.tabBarPosition = this.previewPosition4to3;
    }
    const windowStatus = WindowService.getInstance().getWindowStatus();
    HiLog.i(TAG, `previewPosition16to9: ${this.previewPosition16to9}.`);
    HiLog.i(TAG, `previewPosition4to3: ${this.previewPosition4to3}.`);
    HiLog.i(TAG, `previewPosition1to1: ${this.previewPosition1to1}.`);
    HiLog.i(TAG, `tabBarPosition: ${this.tabBarPosition}.`);
    HiLog.i(TAG, `topAvoidArea: ${this.topAvoidArea}.`);
  }

  public get16to9PreviewHeight(width?: number, height?: number): number {
    return DisplayCalculator.calcSurfaceDisplaySize(NUM_16 / NUM_9, width, height).height;
  }

  public changePreviewPosition(xComponentWidth: number, xComponentHeight: number): void {
    const height = getStates().get<number>('windowReducer', 'windowHeight');
    let ratio: number = xComponentHeight / xComponentWidth;
    ratio = ratio <= 1 ? ratio : 1 / ratio;
    HiLog.i(TAG, `changePreviewPosition ratio: ${ratio}.`);
    this.rouletteZoomPosition = this.previewPosition4to3 + this.preview4to3Height - ZOOM_VIEW_HEIGHT;
    if (this.isEqual(xComponentHeight / height, 1) || this.previewNeedAlignTop()) {
      this.previewPosition = 0;
    } else if (this.isEqual(ratio, NUM_3_TO_4)) {
      this.previewPosition = this.previewPosition4to3;
    } else if (this.isEqual(ratio, NUM_9 / NUM_16)) {
      this.previewPosition = this.previewPosition16to9;
    } else if (FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue() ===
    SettingFuncDialogItemIndex.INDEX_SEC) {
      this.previewPosition = this.previewPosition1to1;
      this.rouletteZoomPosition = this.previewPosition1to1 + xComponentHeight - ZOOM_VIEW_HEIGHT;
    } else if (xComponentHeight < xComponentWidth) {
      this.previewPosition = this.previewPosition1to1 + ((xComponentWidth - xComponentHeight) >> 1);
    } else {
      this.previewPosition = this.previewPosition4to3;
    }
  }

  private previewNeedAlignTop(): boolean {
    let mode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
    let isPreTop: boolean = false;
    return isPreTop;
  }

  public previewAvoidingMotion(xComponentHeight: number, data: ExtendBarData): void {
    if (data?.isShowExtendBar === false) {
      this.previewPosition = Math.ceil(this.previewPosition4to3 + xComponentHeight / NUM_6);
    } else if (data?.isShowExtendBar === true && data?.isBeautyTheme) { // 当支持人像美颜卡片时，需要调整预览上移位置
      this.previewPosition = this.zoomPosition - xComponentHeight - (PORTRAIT_BEAUTY_THEME - ZOOM_VIEW_HEIGHT);
    } else if (data?.isShowExtendBar === true) {
      this.previewPosition = this.zoomPosition - xComponentHeight;
    }
  }

  public isEqual(num1: number, num2: number): boolean {
    return Math.abs(num1 - num2) <= NUMBER_MIN;
  }

  public getTopAvoidArea(): number {
    return this.topAvoidArea;
  }

  public setTopAvoidArea(topMargin: number): void {
    this.topAvoidArea = topMargin;
  }

  private changePickerPreviewPosition(): void {
    const windowHeight: number = getStates().get<number>('windowReducer', 'windowHeight');
    const xComponentHeight: number = getStates().get<number>('previewReducer', 'xComponentHeight');
    this.previewPosition = (windowHeight - xComponentHeight) >> 1;
    this.rouletteZoomPosition = this.previewPosition4to3 + this.preview4to3Height - ZOOM_VIEW_HEIGHT;
  }
}