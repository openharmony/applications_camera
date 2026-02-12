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
/* instrument ignore file */
import lazy { Dispatch, OhCombinedState, reduxSubscribe, getStates } from '../../../redux';
import lazy { GlobalContext } from '../../../utils/GlobalContext';
import lazy { ZIndex } from '../../../utils/ZIndex';
import lazy { TreasureBoxAction } from '../reduce/TreasureBoxAction';
import lazy { RecordingState } from '../../../function/recordcontrol/RecordAction';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { HiLog } from '../../../utils/HiLog';

const TAG: string = 'TreasureBoxGestureGround';

@Component
export struct TreasureBoxGestureGround {
  /* instrument ignore file */
  private dispatch: Dispatch = (data) => data;
  private clickActive: boolean = true;
  private cameraPanGestureStart: number = 0;
  private readonly CAMERA_PAN_GESTURE_START_THRESHOLD: number = 18;
  private readonly CAMERA_PAN_GESTURE_DISTANCE_THRESHOLD: number = -10;
  @StorageLink('isPanGestureDoing') isPanGestureDoing: boolean = false;
  @State isHalfCollapsLEM: boolean = false;
  @State isVdeCollapsed: boolean = false;
  private isDuringSavePowerMode: boolean = false;
  private uiEnable: boolean = false;
  @StorageLink('isNightShutting') isNightShutting: boolean = false;
  @Prop isCustomFilterImmersive: boolean = false;
  @Prop isPicker: boolean = false;
  private isImmersive: boolean = true;

  aboutToAppear() {
    HiLog.i(TAG, 'aboutToAppear E.');
    reduxSubscribe((state: OhCombinedState) => {
      this.isDuringSavePowerMode = state.get<boolean>('contextReducer', 'isDuringSavePowerMode');
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isVdeCollapsed = state.get<boolean>('collapsReducer', 'isVdeCollapsed');
      this.isImmersive = state.get<boolean>('uiReducer', 'isImmersive');
    }, (dispatch: Dispatch): void => {
      this.dispatch = dispatch;
    });
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  private onPanGestureUp(event?:GestureEvent): void {
    if (AppStorage.get('disShutterEmitTreasureOpen')) { // 禁用在shutter按钮上滑拉起百宝箱
      AppStorage.setOrCreate<boolean>('disShutterEmitTreasureOpen', false);
      return;
    }
    if (this.isDuringSavePowerMode || !this.uiEnable || this.isNightShutting || this.isImmersive) {
      return;
    }
    if (!this.isHalfCollapsLEM && !this.isVdeCollapsed) {
      HiLog.i(TAG, 'isPanGestureDoing false, onPanGestureUp');
      this.isPanGestureDoing = false;
      const height: number = getStates().get<number>('windowReducer', 'windowHeight');
      // 锁屏相机锁屏应用上滑退出手势和百宝箱手势同步触发，规避只触发一个手势
      if (GlobalContext.get().getT<boolean>('isSecurityCamera') && event?.offsetY &&
        (event?.offsetY < this.CAMERA_PAN_GESTURE_DISTANCE_THRESHOLD) &&
        height - this.cameraPanGestureStart < this.CAMERA_PAN_GESTURE_START_THRESHOLD) {
        return;
      }
      if (getStates().get<RecordingState>('recordReducer', 'recordingState') !== RecordingState.READY) {
        return;
      }
      this.cameraPanGestureStart = 0;
      this.dispatch(TreasureBoxAction.setTreasureBoxStatus(true));
    }
  }

  private onPanGestureDown(): void {
    if (this.isDuringSavePowerMode || !this.uiEnable || this.isImmersive) {
      return;
    }
    if (!this.isHalfCollapsLEM && !this.isVdeCollapsed) {
      HiLog.i(TAG, 'isPanGestureDoing false, onPanGestureDown');
      this.isPanGestureDoing = false;
    }
  }

  build() {
    Row() {
    }
    .width('100%')
    .height('100%')
    .zIndex(ZIndex.BOTTOM)
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .gesture(GestureGroup(GestureMode.Exclusive,
      PanGesture({ fingers: 1, distance: 20, direction: PanDirection.Up })
        .onActionStart((event?: GestureEvent) => {
          if (this.isDuringSavePowerMode || !this.uiEnable || this.isNightShutting || this.isImmersive) {
            return;
          }
          if (this.isCustomFilterImmersive && !this.isPicker) {
            return;
          }
          if (!this.isHalfCollapsLEM && !this.isVdeCollapsed) {
            HiLog.i(TAG, 'isPanGestureDoing true, onActionStart 1');
            this.isPanGestureDoing = true;
            if (!event || !event.fingerList[0]) {
              return;
            }
            this.cameraPanGestureStart = event.fingerList[0].globalY;
          }
        })
        .onActionEnd((event?: GestureEvent) => this.onPanGestureUp(event))
        .onActionCancel((event?: GestureEvent) => this.onPanGestureUp(event)),
      PanGesture({ fingers: 1, distance: 20, direction: PanDirection.Down })
        .onActionStart((): void => {
          if (this.isDuringSavePowerMode || !this.uiEnable || (this.isCustomFilterImmersive && !this.isPicker) ||
          this.isImmersive) {
            return;
          }
          if (!this.isHalfCollapsLEM && !this.isVdeCollapsed) {
            HiLog.i(TAG, 'isPanGestureDoing true, onActionStart 2');
            this.isPanGestureDoing = true;
            this.dispatch(TreasureBoxAction.setTreasureBoxStatus(false));
          }
        })
        .onActionEnd((): void => this.onPanGestureDown())
        .onActionCancel((): void => this.onPanGestureDown()),
    ))
  }
}