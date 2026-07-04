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

import lazy { FunctionAction } from '../../function/core/FunctionAction';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { FocusExposureAction } from './FocusExposureAction';
import lazy { Dispatch } from '../../redux';
import lazy { Action } from '../../redux/actions/Action';
import lazy { TabBarAction } from '../tabbar/TabBarAction';
import lazy { TipAction } from '../tip/TipAction';
import lazy { RenderLocation } from '../../function/core/functionproperty/RenderLocation';
import lazy { LockLevel } from './FocusExposureHelper';
import lazy { UIOperationType } from '../uicomponent/UIOperationType';
import lazy { CaptureAction } from '../../function/capture/CaptureAction';

export class FocusExposureAreaDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch): void {
    this.mDispatch = dispatch;
  }

  public hideFocus(): void {
    this.mDispatch(FocusExposureAction.hideFocus());
  }

  public updateShowFocus(isShowFocus: boolean): void {
    this.mDispatch(FocusExposureAction.updateShowFocus(isShowFocus));
  }

  public updateLockLevel(lockLevel: LockLevel): void {
    this.mDispatch(FocusExposureAction.updateLockLevel(lockLevel));
  }

  public updateShowExposure(isShowExposure: boolean): void {
    this.mDispatch(FocusExposureAction.updateShowExposure(isShowExposure));
  }

  public updateShowExposureRing(isShowExposureRing: boolean): void {
    this.mDispatch(FocusExposureAction.updateShowExposureRing(isShowExposureRing));
  }

  public changeFunctionValue(id: FunctionId, value: Object): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public uiDisabled(): void {
    this.mDispatch(Action.uiState(false));
  }

  public uiEnabled(): void {
    this.mDispatch(Action.uiState(true));
  }

  public previewClicked(unLock?: boolean): void {
    this.mDispatch(Action.previewClicked(unLock));
  }

  public changeTabBarSelector(id: FunctionId, renderLocation: RenderLocation): void {
    this.mDispatch(TabBarAction.changeTabBarSelector(id, renderLocation));
  }

  public hideTip(): void {
    this.mDispatch(TipAction.hideTip());
  }

  public isEnterImmersive(isEnterImmersive: boolean, mainTrigCompo: UIOperationType): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, mainTrigCompo));
  }

  public captureLemCollaps(): void {
    this.mDispatch(CaptureAction.captureLemCollaps());
  }

  public proSonChangeState(iconId: number): void {
    this.mDispatch(Action.proSonChangeState(iconId));
  }

  public resetSmartControlLocked(): void {
    this.mDispatch(FocusExposureAction.resetSmartControlLocked());
  }

  public changeTimeLapse(isShowtimeLapse: boolean): void {
    this.mDispatch(Action.changeTimeLapse(isShowtimeLapse));
  }

  public changeTimedShot(isShowTimedShot: boolean): void {
    this.mDispatch(Action.changeTimedShot(isShowTimedShot));
  }
}