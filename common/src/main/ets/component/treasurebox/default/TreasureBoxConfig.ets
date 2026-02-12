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

import lazy { FunctionId } from '../../../function/core/functionproperty/FunctionId';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { TransAnimationData, TREASURE_BOX_IMAGE_ELEMENT } from '../common/DataType';
import lazy { FILTER_LIST_SPACE } from './SecondLevelList';
import lazy {
  BACK_BUTTON_LEFT_MARGIN,
  BACK_BUTTON_MIN_RIGHT_MARGIN,
  BACK_BUTTON_SIDE_LENGTH,
  SECOND_LIST_PADDING_LEM_HALF
} from './TreasureBox';
import lazy {
  TREASURE_BOX_ELEMENT_HALF_COLLAPS_LENGTH,
  TREASURE_BOX_ELEMENT_VDE_COLLAPS_WIDTH,
  TREASURE_BOX_ELEMENT_WIDTH
} from '../../../service/UIAdaptive/AdaptiveLayoutService';
import lazy { IMAGE_BUTTON_SIDE_LENGTH } from './button/icon/ImageElement';
import lazy { getStates } from '../../../redux';
import lazy { RenderLocation } from '../../../function/core/functionproperty/RenderLocation';
import lazy { CameraAppCapability } from '../../../camera/CameraAppCapability';
import lazy { FeatureManager } from '../../../function/core/FeatureManager';
import lazy { ModeType } from '../../../mode/ModeType';
import lazy { PhotoFormatMode } from '../../../function/enumbase/PhotoFormatMode';
import lazy { camera } from '@kit.CameraKit';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';


/* instrument ignore file */
const TAG: string = 'TreasureBoxConfig';
const MAIN_CAMERA_ZOOM = 1;
const D_VALUE = 0.1;
const DEFAULT_LOAD_COUNT: number = 5
const HALF: number = 0.5;
const FIRST_LIST_LEFT_MARGIN: number = 13;
const FIRST_LIST_MAX_LENGTH: number = 5;
export const LIST_SIZE_MAX = 15;
export const REAL_TIME_FILTER_LEFT_MARGIN: number = 7;
export const REAL_TIME_FILTER_RIGHT_MARGIN: number = 24;
export const XMAGE_LEFT_MARGIN: number = 7;
export const XMAGE_RIGHT_MARGIN: number = 12;

export class TreasureBoxConfig {
  // 百宝箱展开动效
  private isOpening: boolean = false;
  // 滑动动效
  private isFirstToSecond: boolean = true;
  private transAnimationData: TransAnimationData | undefined;
  // 一级页面
  private firstList: FunctionId[] = [];
  private firstListOffset: number = 0;
  private firstListMargins: number[] = [];
  // 二级页面
  private secondListLength: number = 0;
  private secondListLeftMargins: number[] = [];
  private secondListRightMargins: number[] = [];
  private lastIndex: number = -1;

  public setFirstList(firstList: FunctionId[]): void {
    this.firstList = firstList;
  }

  public getFirstList(): FunctionId[] {
    return this.firstList;
  }

  public getResetListData(): FunctionId[] {
    HiLog.i(TAG, 'resetList begin.');
    let mainList: FunctionId[] = [];
    const set = getStates().get<Map<RenderLocation, Set<FunctionId>>>('functionReducer', 'functionRenderMap')
      .get(RenderLocation.TREASURE_BOX);
    if (!set) {
      return mainList;
    }
    let treasureBoxOrder = CameraAppCapability.getInstance().getTreasureBoxOrder();
    mainList = Array.from(set)
      .sort((a, b) => treasureBoxOrder.indexOf(a) - treasureBoxOrder.indexOf(b))
    if (getStates().get<boolean>('collapsReducer', 'isVdeCollapsed')) {
      if (!set.has(FunctionId.TIME_LAPSE)) {
        mainList.push(FunctionId.TIME_LAPSE);
      }
    }
    this.setFirstList(mainList);
    if (mainList.length < DEFAULT_LOAD_COUNT) {
      this.setListOffset(0);
    }
    HiLog.i(TAG, `resetList end, mainList: ${mainList.toString()}.`);
    return mainList;
  }

  public getFirstListLeftMargin(): number {
    const leftMargin: number = this.firstListMargins[this.firstList.length];
    HiLog.i(TAG, `getFirstListLeftMargin: ${leftMargin}, firstList length: ${this.firstList.length}.`);
    if (getStates().get<boolean>('collapsReducer', 'isHalfCollapsLEM') && this.firstList.length === 4) {
      return leftMargin + FIRST_LIST_LEFT_MARGIN;
    }
    return leftMargin;
  }

  public getFirstListAnimateSelectorLeftMargin(selector: FunctionId): number {
    let index: number = this.firstList.indexOf(selector);
    if (this.isFirstToSecond) {
      this.lastIndex = index;
    } else {
      // 二级菜单修改，一级菜单数量发声变化，需要重新计算图标返回位置，或者动效异常
      HiLog.i(TAG, `lastIndex: ${this.lastIndex}, index: ${index}, firstListOffset: ${this.firstListOffset}`);
      if (this.firstListOffset != 0 && this.lastIndex > index) {
        index += (this.lastIndex - index);
        this.lastIndex = -1;
      }
    }
    if (index === -1) {
      HiLog.e(TAG, 'getFirstListAnimate error, index: -1.');
      index = 0;
    }
    return (TREASURE_BOX_ELEMENT_WIDTH + this.getListSpace()) * index + this.getFirstListLeftMargin() -
    this.firstListOffset;
  }

  public setSecondListLength(length: number): void {
    this.secondListLength = length;
  }

  public getSecondListLength(): number {
    return this.secondListLength;
  }

  public getSecondListAnimateSelectorLeftMargin(): number {
    if (this.secondListLength <= LIST_SIZE_MAX) {
      return this.secondListLeftMargins[this.secondListLength];
    }
    return BACK_BUTTON_MIN_RIGHT_MARGIN + BACK_BUTTON_LEFT_MARGIN + BACK_BUTTON_SIDE_LENGTH;
  }

  public initMargins(width: number): void {
    this.firstListMargins = [];
    this.secondListLeftMargins = [];
    this.secondListRightMargins = [];
    this.firstListMargins.push(0);
    this.secondListLeftMargins.push(0);
    this.secondListRightMargins.push(0);
    const space: number = this.getListSpace(width);
    for (let i = 1; i <= LIST_SIZE_MAX; i++) {
      const length: number = i * (TREASURE_BOX_ELEMENT_WIDTH + space) - space;
      const margin: number = ((width - length) >> 1) + 1;
      this.firstListMargins.push(i >= FIRST_LIST_MAX_LENGTH ? FIRST_LIST_LEFT_MARGIN : margin);

      const secondLeftMargin: number = Math.max(BACK_BUTTON_LEFT_MARGIN + BACK_BUTTON_SIDE_LENGTH +
        BACK_BUTTON_MIN_RIGHT_MARGIN, margin);
      this.secondListLeftMargins.push(secondLeftMargin);
      this.secondListRightMargins.push(Math.max(BACK_BUTTON_MIN_RIGHT_MARGIN, width - secondLeftMargin - length + 1));
    }
    HiLog.i(TAG, 'initMargins end.');
  }

  public getListSpace(width?: number): number {
    width = width ? width : getStates().get<number>('windowReducer', 'windowWidth');
    // 当一级列表长度大于五时，列表需要显示出四个半
    // 长度小于5时,列表间距和长度大于五一致
    // 支持魔镜的设备，一级列表需要显示出五个半
    const spaceCount: number = FIRST_LIST_MAX_LENGTH - 1;
    const listSpace = (width - TREASURE_BOX_ELEMENT_WIDTH * (spaceCount + HALF) - FIRST_LIST_LEFT_MARGIN) / spaceCount;
    HiLog.i(TAG, `getListSpace: ${listSpace}, width: ${width}, elementWidth: ${TREASURE_BOX_ELEMENT_WIDTH}.`);
    return listSpace;
  }

  public getTransData(): TransAnimationData | undefined {
    return this.transAnimationData;
  }

  public getIsFirstToSecond(): boolean {
    return this.isFirstToSecond;
  }

  public setIsFirstToSecond(isFirstToSecond: boolean): void {
    this.isFirstToSecond = isFirstToSecond;
  }

  public getSecondListLeftMargin(index: number, selector: FunctionId, length: number): number {
    if (index !== 0) {
      return 0;
    }
    if (length <= LIST_SIZE_MAX) {
      return this.secondListLeftMargins[length] - BACK_BUTTON_LEFT_MARGIN - BACK_BUTTON_SIDE_LENGTH;
    }
    return BACK_BUTTON_MIN_RIGHT_MARGIN;
  }

  public getSecondListRightMargin(index: number, selector: FunctionId, length: number): number {
    if (index !== length - 1) {
      return 0;
    }
    if (length <= LIST_SIZE_MAX) {
      HiLog.i(TAG, `right margin: ${this.secondListRightMargins[length]}.`);
      return this.secondListRightMargins[length];
    }
    HiLog.i(TAG, `right margin BACK_BUTTON_MIN_RIGHT_MARGIN: ${BACK_BUTTON_MIN_RIGHT_MARGIN}.`);
    return BACK_BUTTON_MIN_RIGHT_MARGIN;
  }

  public getVdeSemiCollapsMargin(index: number, selector: FunctionId, length: number): Margin {
    const width: number = getStates().get<number>('windowReducer', 'windowWidth');
    const listSpace: number = this.getListSpace();
    let secondListLength: number = (listSpace + TREASURE_BOX_ELEMENT_HALF_COLLAPS_LENGTH) * length - listSpace;
    const borderMargin: number = width > secondListLength ? (width - secondListLength) / 2 : 16;
    if ((!SystemLanguageUtil.isRTL() && index === 0) ||
      (SystemLanguageUtil.isRTL() && index === length - 1)) {
      return { left: borderMargin, right: 0 };
    }
    if ((!SystemLanguageUtil.isRTL() && index === length - 1) ||
      (SystemLanguageUtil.isRTL() && index === 0)) {
      return { left: 0, right: borderMargin };
    }
    return { left: 0, right: 0 };
  }

  public getVdeCollapsedMargin(index: number, length: number): Margin {
    const width: number = getStates().get<number>('windowReducer', 'windowWidth');
    if (SystemLanguageUtil.isRTL()) {
      return {
        left: index === length - 1 ? (width - (TREASURE_BOX_ELEMENT_VDE_COLLAPS_WIDTH + 10) * length) / 2 + 5 : '5vp',
        right: index === 0 ? (width - (TREASURE_BOX_ELEMENT_VDE_COLLAPS_WIDTH + 10) * length) / 2 : '5vp',
        top: '10vp'
      }
    }
    return {
      left: index === 0 ? (width - (TREASURE_BOX_ELEMENT_VDE_COLLAPS_WIDTH + 10) * length) / 2 + 5 : '5vp',
      right: index === length - 1 ? (width - (TREASURE_BOX_ELEMENT_VDE_COLLAPS_WIDTH + 10) * length) / 2 : '5vp',
      top: '10vp'
    }
  }

  public getHalfCollapsLemMargin(index: number, selector: FunctionId, length: number): Margin {
    const width: number = getStates().get<number>('windowReducer', 'windowWidth');
    let leftMargin: number = treasureBoxConfig.getSecondListLeftMargin(index, selector, length);
    let rightMargin: number = treasureBoxConfig.getSecondListRightMargin(index, selector, length);
    if (SystemLanguageUtil.isRTL()) {
      leftMargin = treasureBoxConfig.getSecondListRightMargin(index, selector, length);
      rightMargin = treasureBoxConfig.getSecondListLeftMargin(index, selector, length);
    }
    if (index === 0) {
      leftMargin = this.getHalfCollapsMarginLEM(length, width);
    }
    if (index === length - 1) {
      rightMargin = this.getHalfCollapsMarginLEM(length, width);
    }
    return { left: leftMargin, right: rightMargin };
  }

  private getHalfCollapsMarginLEM(length: number, width: number): number {
    let secondListWidth: number = width - (BACK_BUTTON_LEFT_MARGIN + BACK_BUTTON_SIDE_LENGTH);
    let halfCollapsMarginLEM: number = (secondListWidth - TREASURE_BOX_ELEMENT_HALF_COLLAPS_LENGTH * length -
      SECOND_LIST_PADDING_LEM_HALF * (length - 1)) / 2;
    return halfCollapsMarginLEM;
  }

  public getListReleaseAnimation(treasureBoxAnimationState: number = -1): TransitionEffect {
    if (treasureBoxAnimationState >= 0) {
      return TransitionEffect.asymmetric(
        TransitionEffect
          .IDENTITY,
        TransitionEffect
          .OPACITY
          .animation({ duration: 100, curve: Curve.Friction }));
    }
    return TransitionEffect.asymmetric(
      TransitionEffect
        .OPACITY
        .animation({ duration: 100, curve: Curve.Friction, delay: 100 }),
      TransitionEffect
        .OPACITY
        .animation({ duration: 100, curve: Curve.Friction }));
  }

  /**
   *  百宝箱二级列表子项消失的时候要延迟消失，配合二级整体的淡出效果
   * @returns
   */
  public getSecondListItemDisappearAnimation(): TransitionEffect {
    return TransitionEffect.asymmetric(
      TransitionEffect
        .IDENTITY,
      TransitionEffect
        .OPACITY
        .animation({ curve: Curve.Friction, delay: 100 }));
  }

  public setListOffset(listOffset: number): void {
    this.firstListOffset = listOffset;
  }

  public getListOffset(): number {
    return this.firstListOffset;
  }

  public setIsOpening(isOpening: boolean): void {
    this.isOpening = isOpening;
  }

  public getIsOpening(): boolean {
    return this.isOpening;
  }
}

const treasureBoxConfig: TreasureBoxConfig = new TreasureBoxConfig();

export default treasureBoxConfig;