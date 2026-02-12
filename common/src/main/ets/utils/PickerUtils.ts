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

import lazy { DisplayService } from '../service/UIAdaptive/DisplayService';
import lazy { GlobalContext } from './GlobalContext';
import lazy { HiLog } from './HiLog';
import display from '@ohos.display';
import lazy { getStates, Store } from '../redux';
import lazy { WindowDirection } from './WindowDirection';
import lazy { DeviceInfo } from '../component/deviceinfo/DeviceInfo';
import lazy { PickerWindowType } from '../component/picker/PickerWindowType';
import lazy { Size, window } from '@kit.ArkUI';
import lazy { StoreManager } from '../worker/StoreManager';
import lazy { WindowAction } from '../service/window/WindowAction';
import lazy { settings } from '@kit.BasicServicesKit';
import lazy { ContextManager } from '../service/context/ContextManager';
import lazy { simpleStringify } from './SimpleStringify';
import lazy { SettingsValueUtil } from '../utils/SettingsValueUtil';

/* instrument ignore file */
const TAG: string = 'PickerUtils';

export const PICKER_ENTER_EXIT_ANIM_DURATION: number = 300;

export const PICKER_VERTICAL_LAYOUT: PickerWindowType[] = [PickerWindowType.COLLAPSED_VERTICAL_FULL,
  PickerWindowType.COLLAPSED_1_3_SPLIT_SCREEN, PickerWindowType.COLLAPSED_VERTICAL_1_2_SPLIT_SCREEN,
  PickerWindowType.COLLAPSED_2_3_SPLIT_SCREEN, PickerWindowType.EXPANDED_LEFT_RIGHT_SPLIT_SCREEN];
export const PICKER_HORIZONTAL_LAYOUT: PickerWindowType[] =
  [PickerWindowType.EXPANDED_TOP_BOTTOM_SPLIT_SCREEN, PickerWindowType.COLLAPSED_HORIZONTAL_FULL,
    PickerWindowType.COLLAPSED_HORIZONTAL_1_2_SPLIT_SCREEN];

export class PickerUtils {
  public static currentTabBarPosition: number = 0;

  public static getIsPicker(): boolean {
    return GlobalContext.get().getIsPicker();
  }

  // 原始计算方法
  public static getCollapsedPickerSize(height?: number): number {
    // 采用KNN方法计算，K=1
    const displayInfo: display.Display = DisplayService.getInstance().getDisplay();
    const displayHeight: number = Math.floor(px2vp(displayInfo.height));
    const windowHeight: number = height ?? getStates().get<number>('windowReducer', 'windowHeight');
    const oneThirdHeight: number = Math.floor(1 / 3 * displayHeight);
    const oneHalfHeight: number = Math.floor(1 / 2 * displayHeight);
    const twoThirdsHeight: number = Math.floor(2 / 3 * displayHeight);
    const pointsArr: number[] = [oneThirdHeight, oneHalfHeight, twoThirdsHeight, displayHeight];
    const distanceArr: number[] = pointsArr.map((item: number) => Math.abs(item - windowHeight));
    const closestPoint: number = distanceArr.indexOf(Math.min(...distanceArr));
    HiLog.i(TAG, `CLOSEST POINT ${closestPoint}`);
    return closestPoint;
  }

  // 原始计算方法
  public static getIsFullScreen(width: number = getStates().get<number>('windowReducer', 'windowWidth'),
    height: number = getStates().get<number>('windowReducer', 'windowHeight')): boolean {
    if (ContextManager.getInstance().getAbilityContext()) {
      return getStates().get<number>('windowReducer', 'windowStatus') === window.WindowStatusType.FULL_SCREEN;
    }
    const displayInfo = DisplayService.getInstance().getDisplay();
    HiLog.i(TAG, `get is full screen ${width} = ${Math.floor(px2vp(displayInfo.width))}, ${height} = ${Math.floor(px2vp(displayInfo.height))}`);
    return width === Math.floor(px2vp(displayInfo.width)) && height === Math.floor(px2vp(displayInfo.height)) ||
      width === Math.floor(px2vp(displayInfo.height)) && height === Math.floor(px2vp(displayInfo.width)) ?
      true : false;
  }

  // 原始计算方法
  public static getIsExpandedTopBottomSplitScreen(width: number = getStates().get<number>('windowReducer', 'windowWidth'),
    height: number = getStates().get<number>('windowReducer', 'windowHeight')): boolean {
    return false;
  }

  // 原始计算方法
  public static getIsTabletLeftRightSplitScreen(width: number = getStates().get<number>('windowReducer', 'windowWidth'),
    height: number = getStates().get<number>('windowReducer', 'windowHeight')): boolean {
    HiLog.i(TAG, `top bottom ${height} = ${Math.floor(px2vp(DisplayService.getInstance().getDisplay()
      .width))}, ${width} = ${Math.floor(px2vp(DisplayService.getInstance().getDisplay().height))}`);
    return PickerUtils.getIsPicker() && DeviceInfo.isTablet() &&
      height === Math.floor(px2vp(DisplayService.getInstance().getDisplay().height)) &&
      width !== Math.floor(px2vp(DisplayService.getInstance().getDisplay().width));
  }

  // 原始计算方法
  public static getIsExpandedLeftRightSplitScreen(width?: number, height?: number): boolean {
    width = width ?? getStates().get<number>('windowReducer', 'windowWidth');
    height = height ?? getStates().get<number>('windowReducer', 'windowHeight');
    return false;
  }

  // 原始计算方法
  public static getIsTabletTopBottomSplitScreen(width?: number, height?: number): boolean {
    width = width ?? getStates().get<number>('windowReducer', 'windowWidth');
    height = height ?? getStates().get<number>('windowReducer', 'windowHeight');
    return PickerUtils.getIsPicker() && DeviceInfo.isTablet() &&
      height !== Math.floor(px2vp(DisplayService.getInstance().getDisplay().height)) &&
      width === Math.floor(px2vp(DisplayService.getInstance().getDisplay().width));
  }

  // 此处需使用getIsFullScreen去计算，不然CollapsChangeService中更新状态可能会出错
  public static getIsPickerInSplitScreen(): boolean {
    return this.getIsPicker() && !this.getIsFullScreen();
  }

  public static getIsPhoneInFloating(width?: number, height?: number): boolean {
    width = width ?? getStates().get<number>('windowReducer', 'windowWidth');
    height = height ?? getStates().get<number>('windowReducer', 'windowHeight');
    const displayInfo = DisplayService.getInstance().getDisplay();
    return PickerUtils.getIsPicker() && width === Math.floor(px2vp(displayInfo.width)) &&
      height !== Math.floor(px2vp(displayInfo.height)) && width < height;
  }

  /**
   * 平板是否在悬浮窗
   *
   * @param width
   * @param height
   * @returns
   */
  public static getIsTableInFloating(width?: number, height?: number): boolean {
    width = width ?? getStates().get<number>('windowReducer', 'windowWidth');
    height = height ?? getStates().get<number>('windowReducer', 'windowHeight');
    return PickerUtils.getIsPicker() && DeviceInfo.isTablet() &&
      width !== Math.floor(px2vp(DisplayService.getInstance().getDisplay().width)) &&
      height !== Math.floor(px2vp(DisplayService.getInstance().getDisplay().height)) &&
      width < height && !this.getIsInPcMode();
  }

  /**
   * 是否在自由多窗
   *
   * @param width
   * @param height
   * @returns
   */
  public static getIsInPcMode(): boolean {
    let isPcMode: string = SettingsValueUtil
      .getValueSync('window_pcmode_switch_status', '', settings.domainName.USER_PROPERTY);
    HiLog.i(TAG, `getIsInPcMode: ${isPcMode}`);
    return isPcMode === 'true';
  }

  // 原始计算方法
  public static getIsTabletInFreeWindow(width?: number, height?: number): boolean {
    width = width ?? getStates().get<number>('windowReducer', 'windowWidth');
    height = height ?? getStates().get<number>('windowReducer', 'windowHeight');
    return PickerUtils.getIsPicker() && DeviceInfo.isTablet() &&
      width !== Math.floor(px2vp(DisplayService.getInstance().getDisplay().width)) &&
      height !== Math.floor(px2vp(DisplayService.getInstance().getDisplay().height)) &&
      PickerUtils.getIsInPcMode();
  }

  public static getIsFullScreenFromReducer(): boolean {
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    return this.getIsPicker() && (pickerWindowType === PickerWindowType.COLLAPSED_VERTICAL_FULL ||
      pickerWindowType === PickerWindowType.COLLAPSED_HORIZONTAL_FULL ||
      pickerWindowType === PickerWindowType.EXPANDED_FULL_SCREEN ||
      pickerWindowType === PickerWindowType.PC_FLOAT_SCREEN ||
      pickerWindowType === PickerWindowType.TRICOLLAPS_FULL_SCREEN ||
      pickerWindowType === PickerWindowType.TABLET_FULL_SCREEN
    );
  }

  public static getIsExpandedTopBottomSplitScreenFromReducer(): boolean {//展开态上下分屏
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    return this.getIsPicker() && pickerWindowType === PickerWindowType.EXPANDED_TOP_BOTTOM_SPLIT_SCREEN;
  }

  public static getIsExpandedLeftRightSplitScreenFromReducer(): boolean {//展开态左右分屏
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    return this.getIsPicker() && pickerWindowType === PickerWindowType.EXPANDED_LEFT_RIGHT_SPLIT_SCREEN;
  }

  public static getIsPhoneInFloatingFromReducer(): boolean {
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    return this.getIsPicker() && pickerWindowType === PickerWindowType.PHONE_IN_FLOATING;
  }

  public static getIsCollapsedHorizontalFullScreenFromReducer(): boolean {
    if (DeviceInfo.isTablet()) {
      return false;
    }
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    return this.getIsPicker() && pickerWindowType === PickerWindowType.COLLAPSED_HORIZONTAL_FULL;
  }

  public static getIsExpandedSplitScreen(): boolean {
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    return this.getIsPicker() && (pickerWindowType === PickerWindowType.EXPANDED_TOP_BOTTOM_SPLIT_SCREEN ||
      pickerWindowType === PickerWindowType.EXPANDED_LEFT_RIGHT_SPLIT_SCREEN);
  }

  public static getIsExpandedVerticalPreviewSize(): boolean {
    return this.getIsPicker() &&
      ((this.getIsExpandedTopBottomSplitScreenFromReducer() && !DisplayService.getInstance().isOrientationVertical() ||
        this.getIsExpandedLeftRightSplitScreenFromReducer() && DisplayService.getInstance().isOrientationVertical()));
  }

  public static getIsExpandedHorizontalPreviewSize(): boolean {
    return this.getIsPicker() &&
      ((this.getIsExpandedTopBottomSplitScreenFromReducer() && DisplayService.getInstance().isOrientationVertical() ||
      this.getIsExpandedLeftRightSplitScreenFromReducer() && !DisplayService.getInstance().isOrientationVertical()));
  }

  public static getIsExpandedTopBottomVertical(): boolean {
    return this.getIsPicker() && this.getIsExpandedTopBottomSplitScreenFromReducer() &&
      DisplayService.getInstance().isOrientationVertical();
  }

  public static getIsExpandedLeftRightHorizontal(): boolean {
    return this.getIsPicker() && this.getIsExpandedLeftRightSplitScreenFromReducer() &&
      !DisplayService.getInstance().isOrientationVertical();
  }

  public static isGeneratedContentHorizontal(isCaptureOrientationVertical: boolean,
    isCaptureDirectionVertical: boolean): boolean {
    if (isCaptureOrientationVertical) {
      return isCaptureDirectionVertical ? false : true;
    }
    return !isCaptureDirectionVertical ? true : false;
  }

  public static getIsTabletFullScreenFromReducer(): boolean {
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    return this.getIsPicker() && pickerWindowType === PickerWindowType.TABLET_FULL_SCREEN;
  }

  public static getIsTabletVerticalFullScreenFromReducer(): boolean {
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    return this.getIsPicker() && pickerWindowType === PickerWindowType.TABLET_FULL_SCREEN &&
      DisplayService.getInstance().isOrientationVertical();
  }

  public static getIsTabletHorizontalFullScreenFromReducer(): boolean {
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    return this.getIsPicker() && pickerWindowType === PickerWindowType.TABLET_FULL_SCREEN &&
      !DisplayService.getInstance().isOrientationVertical();
  }

  public static getIsTabletTopBottomSplitScreenFromReducer(): boolean {
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    return this.getIsPicker() && (pickerWindowType === PickerWindowType.TABLET_TOP_BOTTOM_HALF_SPLIT_SCREEN ||
      pickerWindowType === PickerWindowType.TABLET_2_3_SPLIT_SCREEN ||
      pickerWindowType === PickerWindowType.TABLET_1_3_SPLIT_SCREEN);
  }

  public static getIsTabletLeftRightSplitScreenFromReducer(): boolean {
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    return this.getIsPicker() && pickerWindowType === PickerWindowType.TABLET_LEFT_RIGHT_SPLIT_SCREEN;
  }

  public static getIsTabletSplitScreen(): boolean {
    return this.getIsPicker() && DeviceInfo.isTablet() && !this.getIsTabletFullScreenFromReducer();
  }

  public static getIsTabletOneThirdSplitScreen(): boolean {
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    return this.getIsPicker() && pickerWindowType === PickerWindowType.TABLET_1_3_SPLIT_SCREEN;
  }

  public static getIsTabletInFreeWindowFromReducer(): boolean {
    const pickerWindowType: PickerWindowType = getStates().get<PickerWindowType>('windowReducer', 'pickerWindowType');
    return this.getIsPicker() && pickerWindowType === PickerWindowType.TABLET_FREE_WINDOW;
  }

  public static getIsUIExtensionPicker(): boolean {
    return GlobalContext.get().getIsPicker() && !!ContextManager.getInstance().getUiExtensionContext();
  }

  private static updateTabletWindowType(size: Size): void {
    if (PickerUtils.getCollapsedPickerSize(size.height) === 1) {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.TABLET_TOP_BOTTOM_HALF_SPLIT_SCREEN));
    } else if (PickerUtils.getIsTabletLeftRightSplitScreen(size.width, size.height)) {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.TABLET_LEFT_RIGHT_SPLIT_SCREEN));
    } else if (PickerUtils.getIsTabletInFreeWindow(size.width, size.height)) {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.TABLET_FREE_WINDOW));
    } else if (PickerUtils.getCollapsedPickerSize(size.height) === 2) {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.TABLET_2_3_SPLIT_SCREEN));
    } else if (PickerUtils.getCollapsedPickerSize(size.height) === 0) {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.TABLET_1_3_SPLIT_SCREEN));
    } else if (PickerUtils.getIsTableInFloating(size.width, size.height)) {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.TABLET_IN_FLOATING));
    } else {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.TABLET_FULL_SCREEN));
    }
    return;
  }

  private static updateLandscapeWindowType(size: Size): void {
    if (PickerUtils.getIsExpandedTopBottomSplitScreen(size.width, size.height)) {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.EXPANDED_TOP_BOTTOM_SPLIT_SCREEN));
    } else if (PickerUtils.getIsExpandedLeftRightSplitScreen(size.width, size.height)) {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.EXPANDED_LEFT_RIGHT_SPLIT_SCREEN));
    } else {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.EXPANDED_FULL_SCREEN));
    }
    return;
  }

  private static updateCollapsedWindowType(size: Size): void {
    if (DisplayService.getInstance().isOrientationVertical() || PickerUtils.getIsFullScreen(size.width, size.height)) {
      const closestPoint = PickerUtils.getCollapsedPickerSize(size.height);
      if (closestPoint === 3) {
        StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(DisplayService.getInstance()
          .isOrientationVertical() ?
        PickerWindowType.COLLAPSED_VERTICAL_FULL : PickerWindowType.COLLAPSED_HORIZONTAL_FULL));
      } else if (closestPoint === 2) {
        const displayInfo: display.Display = DisplayService.getInstance().getDisplay();
        if (size.height / Math.floor(px2vp(displayInfo.height)) > 0.7) {
          StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.PHONE_IN_FLOATING));
        } else {
          StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.COLLAPSED_2_3_SPLIT_SCREEN));
        }
      } else if (closestPoint === 1) {
        StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.COLLAPSED_VERTICAL_1_2_SPLIT_SCREEN));
      } else {
        StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.COLLAPSED_1_3_SPLIT_SCREEN));
      }
    } else {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.COLLAPSED_HORIZONTAL_1_2_SPLIT_SCREEN));
    }
  }

  private static updateExpandGRLPickerWindowType(size: Size): void {
    if (PickerUtils.getIsFullScreen(size.width, size.height)) {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.TRICOLLAPS_FULL_SCREEN));
    } else {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(
        PickerWindowType.TRICOLLAPS_1_3_SPLIT_SCREEN));
    }
  }

  public static updatePickerWindowType(size: Size): void {
    if (DeviceInfo.isTablet()) {
      this.updateTabletWindowType(size);
      return;
    }
    if (DeviceInfo.isPc()) {
      StoreManager.getInstance().postMessage(WindowAction.updatePickerWindowType(PickerWindowType.PC_FLOAT_SCREEN));
      return;
    }
    this.updateCollapsedWindowType(size);
  }
}