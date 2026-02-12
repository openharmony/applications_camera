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

import display from '@ohos.display';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { WindowAction } from '../window/WindowAction';
import lazy { execDispatch } from '../../redux';
import lazy { Callback } from '@kit.BasicServicesKit';
import lazy { WindowService } from '../window/WindowService';
import window from '@ohos.window';
import lazy { GlobalContext } from '../../utils/GlobalContext';

const TAG: string = 'DisplayService';

export interface DisplayModeResult {
  status: 'SUCCESS' | 'ERROR';
  message?: string;
}

/*
 * 屏幕相关操作Service;
 * 仅允许在DisplayService中调用@ohos.display的涉及io耗时接口
 * 另外: 设备主动切换/监听切换相关职责聚合在CollapsChangeService中
 */
export class DisplayService {
  private static instance: DisplayService;
  private mDisplay: display.Display;
  private mRotation: number;
  private mIsCollapsable: boolean;
  private collapsStatusChangeListened: boolean = false;
  private collapsDisplayModeChangeListened: boolean = false;

  private constructor() {
    HiLog.i(TAG, "constructor");
    try {
      this.mDisplay = display.getDefaultDisplaySync();
    } catch (e) {
      HiLog.e(TAG, `DisplayService err: ${e}`)
    }
  }

  public static getInstance(): DisplayService {
    if (!DisplayService.instance) {
      DisplayService.instance = new DisplayService();
    }
    return DisplayService.instance;
  }

  public init(): void {
    HiLog.i(TAG, 'display service init.');
    try {
      this.registerChange(() => {
        this.mDisplay = display.getDefaultDisplaySync();
        HiLog.d(TAG, `display get, rotation: ${this.mDisplay.rotation}, state: ${this.mDisplay.state}.`);

        if (this.mRotation !== this.mDisplay.rotation) {
          this.mRotation = this.mDisplay.rotation;
          execDispatch(WindowAction.refresh());
          HiLog.i(TAG, `display changed, rotation: ${this.mDisplay.rotation}, state: ${this.mDisplay.state}.`);
        }
      });
    } catch (e) {
      HiLog.e(TAG, `DisplayServicee err: ${e}.`);
    }
  }

  public getIsCollapsable(): boolean {
    if (this.mIsCollapsable === undefined) {
      try {
        this.mIsCollapsable = display.isFoldable();
        HiLog.i(TAG, `getIsCollapsable : ${this.mIsCollapsable}`);
      } catch (e) {
        HiLog.e(TAG, `getIsCollapsable error: ${e}`)
        this.mIsCollapsable = false;
      }
      return this.mIsCollapsable;
    }
  }

  // 屏幕显示数据,一般不使用长宽,用窗口长宽替换
  public getDisplay(): display.Display {
    return this.mDisplay;
  }

  /* instrument ignore next */
  public async getAllDisplays(): Promise<display.Display[]> {
    try {
      return await display.getAllDisplays();
    } catch (err) {
      HiLog.e(TAG, `getAllDisplays err: ${err}`);
      return [];
    }
  }

  public isScreenOff(): boolean {
    return this.mDisplay.state === display.DisplayState.STATE_OFF;
  }

  // 获取设备是否正在横向使用
  public isHorizontal(): boolean {
    if (this.mRotation === 1 || this.mRotation === 3) {
      return true;
    }
    return false;
  }

  public isOrientationVertical(): boolean {
    return this.mDisplay?.orientation === display.Orientation.PORTRAIT ||
      this.mDisplay?.orientation === display.Orientation.PORTRAIT_INVERTED;
  }

  // 设置是否锁定屏幕状态
  public setCollapsStatusLocked(isCollapsStatusLocked: boolean): void {
    try {
      display.setFoldStatusLocked(isCollapsStatusLocked);
    } catch (err) {
      HiLog.e(TAG, `setCollapsStatusLocked error: ${err}.`);
    }
  }

  // 获取设备当前状态,注明:仅对CollapsChangeService开放调用
  public getCollapsStatus(): display.FoldStatus {
    try {
      return display.getFoldStatus();
    } catch (err) {
      HiLog.e(TAG, `getCollapsStatus error: ${err}.`);
      return display.FoldStatus.FOLD_STATUS_FOLDED;
    }
  }

  // 注册状态变更监听
  public registerCollapsStatusChange(collapsStatusChangeCallBack: Callback<display.FoldStatus>): void {
    if (this.collapsStatusChangeListened) {
      return;
    }
    try {
      display.on('foldStatusChange', collapsStatusChangeCallBack);
    } catch (err) {
      HiLog.e(TAG, `display.on collapsStatusChange error: ${err}.`);
    }
    this.collapsStatusChangeListened = true;
  }

  // 主动设置设置屏幕显示模式
  /* instrument ignore next */
  public setCollapsDisplayMode(displayMode: display.FoldDisplayMode, reason?: string): DisplayModeResult {
    try {
      if (reason) {
        display.setFoldDisplayMode(displayMode, reason);
      } else {
        display.setFoldDisplayMode(displayMode);
      }
      return { status: 'SUCCESS' };
    } catch (err) {
      HiLog.e(TAG, `setCollapsDisplayMode error: ${err}.`);
      return { status: 'ERROR', message: String(err) };
    }
  }

  // 获取设备当前屏幕显示模式
  public getCollapsDisplayMode(): display.FoldDisplayMode {
    try {
      return display.getFoldDisplayMode();
    } catch (err) {
      HiLog.e(TAG, `getCollapsDisplayMode error: ${err}.`);
      return display.FoldDisplayMode.FOLD_DISPLAY_MODE_MAIN;
    }
  }

  // 注册显示模式变更监听
  /* instrument ignore next */
  public registerCollapsDisplayModeChange(collapsDisplayModeChangeCallBack: Callback<display.FoldDisplayMode>): void {
    if (this.collapsDisplayModeChangeListened) {
      return;
    }
    try {
      display.on('foldDisplayModeChange', collapsDisplayModeChangeCallBack);
    } catch (err) {
      HiLog.e(TAG, `display.on collapsDisplayModeChange err: ${err}`);
    }
    this.collapsDisplayModeChangeListened = true;
  }

  // 注册屏幕Display参数变更监听
  public registerChange(changeCallBack: Callback<number>): void {
    display.on('change', changeCallBack);
  }

  public unregisterChange(changeCallBack: Callback<number>): void {
    try {
      display.off('change', changeCallBack);
    } catch (err) {
      HiLog.e(TAG, `display.off err: ${err}`);
    }
  }
}
