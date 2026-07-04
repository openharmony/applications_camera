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

import lazy { Dispatch } from '../../redux';
import lazy { Action, UiStateMode } from '../../redux/actions/Action';
import lazy { ZoomAction } from './ZoomAction';
import lazy { VibratorService } from '../../component/vibration/VibratorService';
import camera from '@ohos.multimedia.camera';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { RecordingState } from '../recordcontrol/RecordAction';
import lazy { CameraRunningState } from '../../camera/uithread/CameraAction';
import lazy { UIOperationType } from '../../component/uicomponent/UIOperationType';
import lazy { FunctionAction } from '../core/FunctionAction';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { TreasureBoxAction } from '../../component/treasurebox/reduce/TreasureBoxAction';
import lazy { TabBarAction } from '../../component/tabbar/TabBarAction';
import lazy { RenderLocation } from '../core/functionproperty/RenderLocation';

export class RouletteZoomState {
  public isShowDefault: boolean = true;
  public isShowSemiCollapsed: boolean = false;
  public xComponentWidth: number = 0;
  public xComponentHeight: number = 0;
  public mode: ModeType = ModeType.NONE;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public isShowPinch: boolean = false;
  public isShowZoomView: boolean = false;
  public isShowZoomText: boolean = false;
  public minZoomRatio: number = 0;
  public maxZoomRatio: number = 0;
  public zoomRatio: number = 0;
  public recordingState: RecordingState = RecordingState.READY;
  public zoomState: string = '';
  public isImmersive: boolean = false;
  public uiEnable: boolean = true;
  public cameraRunningState: CameraRunningState = CameraRunningState.UNINITIALIZED;
  public mainTrigCompo: UIOperationType = UIOperationType.NULL;
  public isShowLowAngleShotView: boolean = false;
  public tabSelector: FunctionId = FunctionId.NONE;
}

export class ZoomFuncValueStruct {
  public zoomRatio?: number = 1;
  public isPrepareZoom?: boolean = false;
  public isAutoTriggered?: boolean = false;
  public isUnprepareZoom?: boolean = false;
  public isSmoothZoom?: boolean = false;
  public unprepareDelay?: number;
}

export interface EnableData {
  superMacroEnable: boolean;
}

export class SmoothZoomDuration {
  public duration: number = 0;
}

export class ZoomViewDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch): void {
    this.mDispatch = dispatch;
  }

  // autoTriggered true-则代表是手动触发变焦了  false、默认为自动变焦场景
  public changedZoomByGesture(id: FunctionId, value: ZoomFuncValueStruct, autoTriggered?: boolean): void {
    if (id === FunctionId.ZOOM && !autoTriggered && value?.zoomRatio !== undefined) {
      this.mDispatch(ZoomAction.changedZoomByGesture());
    }
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.ZOOM_BAR));
  }

  public zoomSlide2QuickZoom(zoomValue: number): void {
    this.mDispatch(ZoomAction.zoomSlide2QuickZoom(zoomValue));
  }

  public initZoomRatio(min: number, max: number): void {
    this.mDispatch(ZoomAction.initZoomRatio(min, max));
  }

  public uiStateWithMode(enable: boolean): void {
    this.mDispatch(Action.uiStateWithMode(enable, UiStateMode.EXCLUDE_PREVIEW));
  }

  public changeZoomState(zoomState: string): void {
    this.mDispatch(ZoomAction.changeZoomState(zoomState));
  }

  public handleZoomVibrator(effectId: string, usage?: string): void {
    usage ? usage : (usage = VibratorService.VIBRATOR_USAGE_UNKNOWN);
    this.mDispatch(Action.handleZoomVibrator(effectId, usage));
  }

  public stopZoomVibrator(): void {
    this.mDispatch(Action.stopZoomVibrator());
  }

  public changeOtherComponent(): void {
    this.mDispatch(TreasureBoxAction.updateByZoomChanged());
  }

  public isProShowTreasureBox(): void {
    this.mDispatch(Action.isProShowTreasureBox());
  }

  public isProHideTreasureBox(): void {
    this.mDispatch(Action.isProHideTreasureBox());
  }

  public changeTabBarSelector(id: FunctionId, renderLocation: RenderLocation): void {
    this.mDispatch(TabBarAction.changeTabBarSelector(id, renderLocation));
  }

  public closeSecondTreasure(): void {
    this.mDispatch(TreasureBoxAction.closeSecondTreasure());
  }
}