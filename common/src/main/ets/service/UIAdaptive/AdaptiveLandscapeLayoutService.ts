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

import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { DisplayCalculator } from '../../component/xcomponent/DisplayCalculator';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { PositionType } from '../../utils/types';
import lazy { WindowService } from '../window/WindowService';
import lazy { TREASURE_BOX_ELEMENT_INNER_WIDTH } from '../../component/treasurebox/common/DataType';

/* instrument ignore file */
const TAG: string = 'AdaptiveLandscapeLayoutService'

const NUM_16: number = 16;
const NUM_9: number = 9;
const NUM_6: number = 6;
const NUM_4: number = 4;
const NUM_3: number = 3;
const NUM_1: number = 1;
const NUMBER_4_3: number = 0.75;
const NUMBER_MIN: number = 0.07;
const NUMBER_16_9: number = 0.5625;
export const COMPONENT_WIDTH: number =DeviceInfo.isTablet() ? 88 : 84;
const WINDOWS_SCREEN_800: number = 800;
const ZOOM_PORTRAIT_DIFF: number = 11;
const ZOOM_LANDSCAPE_DIFF: number = 27;
const ZOOM_TOP_DIFF: number = 80;
const ZOOM_VIEW_TOP_MARGIN_VERTICAL: number = DeviceInfo.isTablet() ? 597 : 444;
const ZOOM_VIEW_TOP_MARGIN_VERTICAL_G: number = 613;
const ZOOM_VIEW_TOP_MARGIN: number = DeviceInfo.isTablet() ? 384 : 378;
const TREASURE_BOX_TOP_MARGIN: number = 52;
const TREASURE_BOX_TOP_MARGIN_BIG_SCREEN: number = 16;
const TREASURE_BOX_TOP_MARGIN_VERTICAL_TABLET: number = 240;
const TREASURE_BOX_TOP_MARGIN_VERTICAL_G: number = 197;
const MODE_BAR_TOP_MARGIN: number = DeviceInfo.isTablet() ? 18 : 0;
const MODE_BAR_TOP_MARGIN_G: number = 22;
const TREASURE_BOX_HEIGHT_VERTICAL: number = 360;
const QUICK_ZOOM_VIEW_HEIGHT: number = 40;
const CAMERA_START_TYPE_UNDEFINED: number = -1;
const PROFESSION_BAR_POINT_WIDTH: number = 15;
const MODE_BAR_BOTTOM_MARGIN: number = 60;
const TREASURE_BOX_OFFSET_TOP: number = 38;
const FOOTER_BAR_COL: number = 8;
const TREASURE_BOX_ELEMENT_HEIGHT: number = 48;
const MODE_BAR_OFFSET_BOTTOM: number = 84;
const PARAM_BAR_ROW: number = 92;
const EXTEND_BAR_HEIGHT: number = 398;
const PARAM_BAR_POSITION_SPACING_TRICOLLAPS: number = 88;
const PROFESSION_BAR_WIDTH_TRICOLLAPS: number = 240;
const PROFESSION_BAR_BUTTON_SPACING_TRICOLLAPS: number = 45;
const PROFESSION_BAR_POSITION_TOP_TRICOLLAPS: number = -18;
const PROFESSION_BAR_POSITION_LAND_OFFSETX: number = 190;
const PROFESSION_BAR_POSITION_LAND_OFFSETY: number = 6;
const BLACK_SIDE_SMALL: number = 5;
const BLACK_SIDE_CUSTOM: number = 12;
const MODE_INTRO_CARD_POSITION_SPACING_VERTICAL_TRICOLLAPS: number = 48;
const MODE_INTRO_CARD_POSITION_LEFT_VERTICAL_TRICOLLAPS: number = -4;
const TREASURE_BOX_LEFT_MARGIN_HORIZONTAL: number = 8;
export const PROFESSION_BAR_BUTTON_WIDTH: number = 60;
export const PROFESSION_BAR_WIDTH: number = 240;
export const FOOT_BAR_HEIGHT: number = DeviceInfo.isTablet() ? 360 : 276;
export const QUICK_ZOOM_MARGIN_BOTTOM_28: number = 28;
export const MIDDLE_COMPONENT_WIDTH: number = 72
export const MODE_BAR_HEIGHT: number = 159;
export const LANDSCAPE_TRANSVERSE_HEIGHT_SEMI_COLLAPSED = 427;
export const MODE_BAR_INNER_WIDTH_SEMI: number = 380;

/*
 * Copyright (c) Huawei Device Co., Ltd. 2025. All rights reserved.
 */
export class AdaptiveLandscapeLayoutService {
  private static instance: AdaptiveLandscapeLayoutService;
  public xComponentWidth16to9: number = 0;
  public xComponentWidth4to3: number = 0;
  public xComponentWidth1to1: number = 0;
  public aspectRatioType: number = 0;
  public previewPosition: PositionType = { x: 0, y: 0 }; //预览框动画效果定位
  public zoomBarPosition: PositionType = { x: 0, y: 0 }; //变焦条动画效果定位
  public footBarPosition: PositionType = { x: 0, y: 0 }; //缩略图,快门,前后置切换动画效果定位
  public modeBarPosition: PositionType = { x: 0, y: 0 }; //拍照模式动画效果定位
  public treasureBoxPosition: PositionType = { x: 0, y: 0 }; //百宝箱模式动画效果定位
  public paramBarPosition: PositionType = { x: 0, y: 0 }; //美颜效果动画效果定位
  public proBarPosition: PositionType = { x: 0, y: 0 }; //专业模式动画效果定位
  public modeIntroCardEntryPosition: PositionType = { x: 0, y: 0 };
  public exposurePosition: PositionType = { x: 0, y: 0 };


  public static getInstance(): AdaptiveLandscapeLayoutService {
    if (!AdaptiveLandscapeLayoutService.instance) {
      AdaptiveLandscapeLayoutService.instance = new AdaptiveLandscapeLayoutService();
    }
    return AdaptiveLandscapeLayoutService.instance;
  }

  private constructor() {
  }

  private getAspectRatio(): number {
    return FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO).getValue() as number;
  }

  private getXComponentSizeWidth(aspectRatio? : number, width? : number, height? : number): number {
    return DisplayCalculator.calcSurfaceDisplaySize(aspectRatio, width, height).width;
  }

  private isPreviewAreaMiddle(xComponentWidth : number, width: number): boolean {
    let verticalMiddleTablet: boolean = WindowService.getInstance().isVertical() && DeviceInfo.isTablet();
    let horizontalMiddle: boolean =
      (width - xComponentWidth) < COMPONENT_WIDTH || (width - xComponentWidth) / 2 >= COMPONENT_WIDTH;
    HiLog.i(TAG,
      `isPreviewAreaMiddle, verticalMiddleTablet : ${verticalMiddleTablet}, horizontalMiddle : ${horizontalMiddle}`);
    return verticalMiddleTablet || horizontalMiddle;
  }

  private getPortraitZoomDiffValue(width: number, height: number, isShowTriCollaps: boolean): number {
    // 相对模式条的位置
    if (width > WINDOWS_SCREEN_800) {
      return ((height - FOOT_BAR_HEIGHT) >> 1) + FOOT_BAR_HEIGHT / 2 - MODE_BAR_HEIGHT / 2 +
        MODE_BAR_TOP_MARGIN + ZOOM_PORTRAIT_DIFF;
    }
    let topMargin: number = DeviceInfo.isTablet() ? ZOOM_VIEW_TOP_MARGIN_VERTICAL :
      isShowTriCollaps ? ZOOM_VIEW_TOP_MARGIN_VERTICAL_G : ZOOM_VIEW_TOP_MARGIN;
    return topMargin - ZOOM_TOP_DIFF;
  }

  private getLandscapeDiffValue(width: number, height: number): number {
    // 相对模式条的位置
    if (width > WINDOWS_SCREEN_800) {
      return ((height - FOOT_BAR_HEIGHT) >> 1) + FOOT_BAR_HEIGHT / 2 - MODE_BAR_HEIGHT / 2 +
        MODE_BAR_TOP_MARGIN + ZOOM_LANDSCAPE_DIFF;
    }
    let topMargin: number = DeviceInfo.isTablet() ? ZOOM_VIEW_TOP_MARGIN : ZOOM_VIEW_TOP_MARGIN_VERTICAL;
    return topMargin - ZOOM_TOP_DIFF;
  }

  private getModeBarPositionY(height: number, isShowTricollaps: boolean): number {
    if (DeviceInfo.isTablet()) {
      return ((height - FOOT_BAR_HEIGHT) >> 1) + FOOT_BAR_HEIGHT + MODE_BAR_TOP_MARGIN;
    } else if (isShowTricollaps) {
      return ((height - FOOT_BAR_HEIGHT) >> 1) + FOOT_BAR_HEIGHT + MODE_BAR_TOP_MARGIN_G;
    } else {
      return height - MODE_BAR_HEIGHT - MODE_BAR_BOTTOM_MARGIN;
    }
  }

  // 悬停态布局
  private calButtonComponentSemiCollapsed(width: number, height: number, previewAnimatePosition?: PositionType,
    isShowLowAngleShotView?: boolean): void {
    HiLog.i(TAG, `calposition semiCollapsed, previewPosition: ${JSON.stringify(previewAnimatePosition)}.`);
    this.treasureBoxPosition = {
      x: isShowLowAngleShotView ?
        width / 2 - previewAnimatePosition.x - TREASURE_BOX_OFFSET_TOP - TREASURE_BOX_ELEMENT_HEIGHT :
        width - previewAnimatePosition.x - TREASURE_BOX_OFFSET_TOP - TREASURE_BOX_ELEMENT_HEIGHT,
      y: (height - LANDSCAPE_TRANSVERSE_HEIGHT_SEMI_COLLAPSED) / 2
    };
    this.zoomBarPosition = {
      x: 0,
      y: 0
    };
    this.footBarPosition = {
      x: (width / 2 - FOOT_BAR_HEIGHT) / 2,
      y: height - COMPONENT_WIDTH - FOOTER_BAR_COL
    };
    this.modeBarPosition = {
      x: MODE_BAR_OFFSET_BOTTOM,
      y: (height - MODE_BAR_INNER_WIDTH_SEMI) / 2
    };
    this.paramBarPosition = {
      x: PARAM_BAR_ROW,
      y: (height - EXTEND_BAR_HEIGHT) / 2
    };
    this.proBarPosition = this.paramBarPosition;
  }


  // 拍摄控件和百宝箱变焦区在预览区域内
  // 包含形态：展开态横屏、平板竖屏、G态竖屏
  private calButtonComponentInnerTool(width: number, height: number, isShowTricollaps: boolean): void {
    //展开态横屏需要基于1:1的预览比例布局
    let layoutPreviewBase: number = DeviceInfo.isTablet() ? this.xComponentWidth16to9 : this.xComponentWidth1to1;
    let blackSide16to9: number = (width - layoutPreviewBase) / 2; // 两侧黑边宽度
    blackSide16to9 = blackSide16to9 <= BLACK_SIDE_SMALL ? BLACK_SIDE_CUSTOM : blackSide16to9;
    HiLog.i(TAG, `calButtonComponentInnerTool, blackSide16to9 : ${blackSide16to9}`);
    let componentPosition : number = width - COMPONENT_WIDTH;
    this.treasureBoxPosition = {
      x : blackSide16to9 + TREASURE_BOX_LEFT_MARGIN_HORIZONTAL,
      y: DeviceInfo.isTablet() ? TREASURE_BOX_TOP_MARGIN_VERTICAL_TABLET :
        isShowTricollaps ? TREASURE_BOX_TOP_MARGIN_VERTICAL_G : TREASURE_BOX_TOP_MARGIN
    };
    this.zoomBarPosition = {
      x: blackSide16to9 - QUICK_ZOOM_MARGIN_BOTTOM_28 + TREASURE_BOX_LEFT_MARGIN_HORIZONTAL,
      y: this.getPortraitZoomDiffValue(width, height, isShowTricollaps)
    };
    this.footBarPosition = {
      x: componentPosition - blackSide16to9,
      y: (height - FOOT_BAR_HEIGHT) >> 1
    };
    this.modeBarPosition = {
      x: componentPosition - blackSide16to9,
      y: this.getModeBarPositionY(height, isShowTricollaps)
    };
    this.paramBarPosition = {
      x: componentPosition - blackSide16to9 - MIDDLE_COMPONENT_WIDTH,
      y: 0
    };
    this.proBarPosition = {
      x: componentPosition - blackSide16to9 - PROFESSION_BAR_WIDTH - PROFESSION_BAR_POINT_WIDTH,
      y: 0
    };
  }

  // 拍摄控件或者百宝箱变焦区在预览区域外的黑边中，分预览居中和预览居左两种情况
  // 包含形态：展开态竖屏、平板横屏、G态横屏
  private calButtonComponentOuterTool(width: number, height: number, isShowTricollaps: boolean): void {
    // G态横屏以1:1预览区域为基准进行布局，其他情况以4:3预览区域为基准布局
    let layoutPreviewBase: number = isShowTricollaps ? this.xComponentWidth1to1 : this.xComponentWidth4to3;
    let isPreviewAreaMiddleBase: boolean = this.isPreviewAreaMiddle(layoutPreviewBase, width);
    let bothSideBlack4to3: number = isPreviewAreaMiddleBase ? (width - layoutPreviewBase) / 2 :
        (width - layoutPreviewBase);
    let sideMargin: number = (bothSideBlack4to3 - COMPONENT_WIDTH) / 2;
    let componentPosition: number = width - COMPONENT_WIDTH;
    this.treasureBoxPosition = {
      x: isPreviewAreaMiddleBase ? (bothSideBlack4to3 - TREASURE_BOX_ELEMENT_INNER_WIDTH) / 2 : sideMargin,
      y: (DeviceInfo.isTablet() || isShowTricollaps) ?
        (height - width * NUMBER_16_9) / 2 + TREASURE_BOX_TOP_MARGIN_BIG_SCREEN : TREASURE_BOX_TOP_MARGIN
    };
    this.zoomBarPosition = {
      x: isPreviewAreaMiddleBase ? (bothSideBlack4to3 - QUICK_ZOOM_VIEW_HEIGHT) / 2 - QUICK_ZOOM_MARGIN_BOTTOM_28 :
        sideMargin - QUICK_ZOOM_MARGIN_BOTTOM_28,
      y: this.getLandscapeDiffValue(width, height)
    };
    this.footBarPosition = {
      x: componentPosition - sideMargin,
      y:(height - FOOT_BAR_HEIGHT) >> 1
    };
    this.modeBarPosition = {
      x: componentPosition - sideMargin,
      y: this.getModeBarPositionY(height, isShowTricollaps)
    };
    //考虑截断，不同情况paramBar和professionBar位置需要分开处理
    let paramBarPositionX: number = 0;
    let professionBarPositionX: number = 0;
    if (isShowTricollaps) { //G态
      paramBarPositionX = (width + this.xComponentWidth1to1) / 2 - PARAM_BAR_POSITION_SPACING_TRICOLLAPS;
      professionBarPositionX =
        (width + this.xComponentWidth1to1) / 2 - PROFESSION_BAR_WIDTH_TRICOLLAPS - PROFESSION_BAR_BUTTON_SPACING_TRICOLLAPS;
    } else if ((this.xComponentWidth4to3 > this.xComponentWidth1to1)) { //平板
      paramBarPositionX = (width + this.xComponentWidth1to1) / 2;
      if (!isPreviewAreaMiddleBase && paramBarPositionX + MIDDLE_COMPONENT_WIDTH > this.xComponentWidth4to3) {
        paramBarPositionX -= MIDDLE_COMPONENT_WIDTH; // 防止平板4:3预览下parambar截断
      }
      professionBarPositionX = (width + this.xComponentWidth1to1) / 2 -
        PROFESSION_BAR_WIDTH + PROFESSION_BAR_BUTTON_WIDTH - PROFESSION_BAR_POINT_WIDTH;
    } else { //（包括M态）
      paramBarPositionX = (width + this.xComponentWidth16to9) / 2 - MIDDLE_COMPONENT_WIDTH;
      professionBarPositionX = this.xComponentWidth4to3 - PROFESSION_BAR_WIDTH - PROFESSION_BAR_POINT_WIDTH;
    }
    this.paramBarPosition = {
      x: paramBarPositionX,
      y: 0
    };
    this.proBarPosition = {
      x: DeviceInfo.isTablet() || isShowTricollaps ? professionBarPositionX :
        this.paramBarPosition.x - PROFESSION_BAR_POSITION_LAND_OFFSETX,
      y: DeviceInfo.isTablet() ? 0 : isShowTricollaps ? PROFESSION_BAR_POSITION_TOP_TRICOLLAPS :
        this.paramBarPosition.y - PROFESSION_BAR_POSITION_LAND_OFFSETY
    };
  }

  /* *
   * 大屏形态布局规则
   * */
  public calLandscapeLayoutRuleParam(width: number, height: number, previewAnimatePosition?: PositionType,
    isShowTricollaps?: boolean, isShowSemiCollapsed?: boolean, isShowLowAngleShotView: boolean = false): void {
    HiLog.i(TAG, `calLandscapeLayoutRuleParam begin, windowWidth: ${width}, windowHeight: ${height}.`);
    this.xComponentWidth4to3 = this.getXComponentSizeWidth(NUM_4 / NUM_3, width, height);
    this.xComponentWidth16to9 = this.getXComponentSizeWidth(NUM_16 / NUM_9, width, height);
    this.xComponentWidth1to1 = this.getXComponentSizeWidth(NUM_1 / NUM_1, width, height);
    this.aspectRatioType = this.getAspectRatio();
    // 小i图标位置仅在G态下需特殊处理
    this.modeIntroCardEntryPosition = {
      x: isShowTricollaps && width < height ? MODE_INTRO_CARD_POSITION_LEFT_VERTICAL_TRICOLLAPS : 0,
      y: isShowTricollaps && width < height ? -MODE_INTRO_CARD_POSITION_SPACING_VERTICAL_TRICOLLAPS : 0
    }
    // 平板竖屏预览始终居中
    let verticalMiddleTablet: boolean = WindowService.getInstance().isVertical() && DeviceInfo.isTablet();
    let xcompMiddleWithInnerTool = (width - this.xComponentWidth4to3) < COMPONENT_WIDTH;
    HiLog.i(TAG, `xcompMiddleWithInnerTool : ${xcompMiddleWithInnerTool},
     isShowSemiCollapsed: ${isShowSemiCollapsed}, isShowLowAngleShotView: ${isShowLowAngleShotView}.`);
    if (isShowSemiCollapsed) {
      // 悬停态布局单独计算
      this.calButtonComponentSemiCollapsed(width, height, previewAnimatePosition, isShowLowAngleShotView);
    } else if (verticalMiddleTablet || xcompMiddleWithInnerTool) {
      this.calButtonComponentInnerTool(width, height, isShowTricollaps);
    } else {
      this.calButtonComponentOuterTool(width, height, isShowTricollaps);
    }
  }
}