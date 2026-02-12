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
import lazy { getStates } from '../../../redux';
import lazy { HiLog } from '../../../utils/HiLog';
import lazy { PickerUtils } from '../../../utils/PickerUtils';
import lazy { DeviceInfo } from '../../deviceinfo/DeviceInfo';
import lazy { TransAnimationData, TREASURE_BOX_ELEMENT_INNER_HEIGHT } from '../common/DataType';
import lazy { LANDSCAPE_TRANSVERSE_HEIGHT_SEMI_COLLAPSED } from '../../../service/UIAdaptive/AdaptiveLandscapeLayoutService';

/* instrument ignore file */
const TAG: string = 'LandscapeTreasureBoxConfig';
const LIST_SPACE_SEMI_COLLAPSED = 28;
const LIST_SPACE = 16;
export const LIST_SIZE_MAX = 6;

export const LANDSCAPE_TRANSVERSE_HEIGHT = 328;

class LandscapeTreasureBoxConfig {
  // 通用变量
  private listMargins: number[] = [];
  // 一级页面
  private firstList: FunctionId[] = [];
  private firstListOffset: number = 0;
  // 二级页面
  private secondListLength: number = 0;
  private secondListRightMargins: number[] = [];
  // 是否需要倒置百宝箱容器
  private isReverseNeeded: boolean = false;
  // 正向显示百宝箱时所使用的属性
  private isFirstTimeInitCompleted: boolean = false;
  private offsetError: number = 0;

  // 列表、容器、单元控件高度
  private getListLength(listSize: number, isShowSemiCollapsed: boolean): number {
    const listSpace = this.getListSpace(isShowSemiCollapsed);
    return listSize * (TREASURE_BOX_ELEMENT_INNER_HEIGHT + listSpace) - listSpace;
  }

  public getComponentLength(isShowSemiCollapsed: boolean): number {
    const listLength: number = isShowSemiCollapsed ? LANDSCAPE_TRANSVERSE_HEIGHT_SEMI_COLLAPSED : LANDSCAPE_TRANSVERSE_HEIGHT;
    HiLog.i(TAG, `getComponentLength: ${listLength}, isShowSemiCollapsed: ${isShowSemiCollapsed}.`);
    return listLength;
  }

  public getListSpace(isShowSemiCollapsed: boolean): number {
    const listSpace: number = isShowSemiCollapsed ? LIST_SPACE_SEMI_COLLAPSED : LIST_SPACE;
    HiLog.i(TAG, `getListSpace: ${listSpace}, isShowSemiCollapsed: ${isShowSemiCollapsed}.`);
    return listSpace;
  }

  private getListTopMargin(listSize: number): number {
    const margin: number = this.listMargins.length < listSize ? LIST_SPACE : this.listMargins[listSize - 1];
    HiLog.i(TAG, `getListTopMargin: ${margin}, list size: ${listSize}.`);
    return margin;
  }

  // 目前一级界面最多只有五个元素，只做居中，后续增加列表滑动功能
  public initMargins(isShowSemiCollapsed: boolean, componentLength: number): void {
    this.listMargins = [];
    const listSize: number = this.getListSize();
    for (let i = 1; i < listSize; i++) {
      const length: number = this.getListLength(i, isShowSemiCollapsed);
      const margin: number = Math.max((componentLength - length) >> 1, 0);
      this.listMargins.push(margin + 1);
    }
  }

  // 一级界面数据
  public setFirstList(firstList: FunctionId[]): void {
    this.firstList = firstList;
  }

  private getListSize(): number {
    if (DeviceInfo.isTablet()) {
      if (PickerUtils.getIsTabletOneThirdSplitScreen()) {
        return 2;
      }
      return PickerUtils.getIsPickerInSplitScreen() ? 5 : LIST_SIZE_MAX;
    }
    return LIST_SIZE_MAX;
  }

  public getFirstList(): FunctionId[] {
    return this.firstList;
  }

  public isReverse(): boolean {
    // 当前所有展开态一级界面都是倒置，保留接口可扩展
    return this.isReverseNeeded && !getStates().get<boolean>('collapsReducer', 'isShowSemiCollapsed');
  }

  public getFirstListTopMargin(): number {
    const listLength: number = this.firstList.length;
    return this.getListTopMargin(listLength);
  }

  public setListOffset(listOffset: number): void {
    this.firstListOffset = listOffset;
  }

  public getListOffset(): number {
    return this.firstListOffset;
  }

  // 二级界面数据
  public setSecondListLength(length: number): void {
    this.secondListLength = length;
  }

  public getSecondListLength(): number {
    return this.secondListLength;
  }

  public getSecondListTopMargin(): number {
    const margin = this.getListTopMargin(this.secondListLength);
    HiLog.i(TAG, `getSecondListTopMargin: ${margin}, list size: ${this.secondListLength}.`);
    return margin;
  }

  // 滑动动效margin
  public getFirstListAnimateSelectorTopMargin(selector: number, space: number, height: number): number {
    let index: number = this.firstList.indexOf(selector);
    if (index === -1) {
      HiLog.e(TAG, 'getFirstListAnimate error, index: -1.');
      index = 0;
    }

    const margin: number = (TREASURE_BOX_ELEMENT_INNER_HEIGHT + space) * index + this.getFirstListTopMargin() -
    this.getListOffset();
    if (this.isReverse()) {
      return height - margin - TREASURE_BOX_ELEMENT_INNER_HEIGHT;
    } else {
      return margin;
    }
  }

  //以下4个方法只在正向显示百宝箱时，用来计算列表偏移误差。
  public getListOffsetError(): number {
    return this.offsetError;
  }

  public setListOffsetError(offsetError: number): void {
    this.offsetError = offsetError;
  }

  public getIsFirstTimeInitCompleted(): boolean {
    return this.isFirstTimeInitCompleted;
  }

  public setIsFirstTimeInitCompleted(isFirstTimeInitCompleted: boolean): void {
    this.isFirstTimeInitCompleted = isFirstTimeInitCompleted;
  }
}

const landscapeTreasureBoxConfig: LandscapeTreasureBoxConfig = new LandscapeTreasureBoxConfig();

export default landscapeTreasureBoxConfig;