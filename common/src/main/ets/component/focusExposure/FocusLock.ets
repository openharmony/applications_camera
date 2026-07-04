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
import camera from '@ohos.multimedia.camera';
import lazy { EventBus } from '../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../worker/eventbus/EventBusManager';
import lazy { BaseComponent } from '../../worker/BaseComponent';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import lazy { reduxSubscribe, OhCombinedState } from '../../redux';
import lazy { Dispatch, Unsubscribe } from '../../redux/Store';
import lazy { ComponentIdKeys } from '../../utils/ComponentIdKeys';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { PositionType } from '../../utils/types';
import lazy { FocusExposureAreaDispatcher } from './FocusExposureAreaDispatcher';
import lazy { FocusExposureService } from './FocusExposureService';
import lazy { LockLevel } from './FocusExposureHelper';

const TAG: 'FocusLock' = 'FocusLock';

const TO_SHOW_FOCUS_LOCK: number = 750;

@Component
export struct FocusLock {
  @Link focusPosition: PositionType;
  @Prop touchPreviewAgain: string = '';
  @State isFocusLocked: boolean = false;
  @State focusLockImagePath: string = 'app.media.focus_unlock';
  @State rotateAngle: number = 0;
  @State lockLevel: LockLevel = LockLevel.UNLOCK;
  @State isLockerShow: boolean = false;
  @State focusLockerScale: ScaleOptions = { x: 1.0, y: 1.0 };
  @State @Watch('handleLockerShow') isShowFocus: boolean = false;

  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => { }
  };
  private mAction: FocusExposureAreaDispatcher = new FocusExposureAreaDispatcher();
  private focusLockTimerId: number = Number.MIN_VALUE;
  private mode: ModeType = ModeType.NONE;
  private lockedFocusPosition: PositionType = { x: 0, y: 0 };
  private isHideAnimating: boolean = false;
  @Prop isHdr: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear called.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.lockLevel = state.get<LockLevel>('focusExposureReducer', 'lockLevel');
      this.isShowFocus = state.get<boolean>('focusExposureReducer', 'isShowFocus');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear called.');
    this.clearFocusLockTimer();
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  /* instrument ignore next */
  private handleCameraStarted(): void {
    HiLog.i(TAG, `handleCameraStarted mode: ${this.mode}, isFocusLocked: ${this.isFocusLocked}.`);
  }

  /* instrument ignore next */
  private handleLockerShow(): void {
    HiLog.i(TAG, `handleLockerShow isShowFocus: ${this.isShowFocus}`);
    if (this.isShowFocus) {
    } else if (this.isLockerShow) {
      this.handleLockerHide();
      this.isFocusLocked = false;
    }
  }

  /* instrument ignore next */
  private handleLockerHide(): void {
    HiLog.i(TAG, 'handleLockerHide E');
    const scale: number = FocusExposureService.getInstance().getFocusExposureVScale();
    this.focusLockerScale = { x: 1.0 * scale, y: 1.0 * scale };
    this.isHideAnimating = true;
    animateToImmediately({
      duration: 200,
      curve: Curve.Friction,
      onFinish: () => {
        this.isLockerShow = false;
        this.focusLockerScale = { x: 1.0 * scale, y: 1.0 * scale };
        this.isHideAnimating = false;
      }
    }, () => {
      this.focusLockerScale = { x: 1.3 * scale, y: 1.3 * scale };
    })
  }

  /* instrument ignore next */
  private clearFocusLockTimer(): void {
    if (Number.MIN_VALUE === this.focusLockTimerId) {
      return;
    }
    clearTimeout(this.focusLockTimerId);
    this.focusLockTimerId = Number.MIN_VALUE;
  }

  /* instrument ignore next */
  private async changeFocusLockState(isFocusLocked: boolean): Promise<void> {
    HiLog.i(TAG, `changeFocusLockState isFocusLocked: ${isFocusLocked}`);
    let focusLockImagePath: string = 'app.media.focus_unlock';
    let focusMode: number = camera.FocusMode.FOCUS_MODE_AUTO;
    let lockLevel: LockLevel = LockLevel.TEMPORARY_LOCK;
    this.lockedFocusPosition = { x: 0, y: 0 };
    if (isFocusLocked) {
      HiLog.i(TAG, 'changeFocusLockState');
      focusLockImagePath = 'app.media.focus_lock';
      lockLevel = LockLevel.FOCUS_LOCK;
      focusMode = camera.FocusMode.FOCUS_MODE_LOCKED;
      this.lockedFocusPosition = this.focusPosition;
    }

    this.focusLockImagePath = focusLockImagePath;
    this.mAction.updateLockLevel(lockLevel);
    FocusExposureService.getInstance().setFocusValue({ focusMode, focusPoint: this.focusPosition});
  }

  /* instrument ignore next */
  build() {
    if (this.isLockerShow) {
      Image($r(this.focusLockImagePath))
        .width(24)
        .height(24)
        .fillColor(Color.White)
        .draggable(false)
        .rotate({ angle: this.rotateAngle })
        .animation({ duration: AnimSpecifications.ANIM_DURATION_300, curve: Curve.Ease })
        .key(ComponentIdKeys.PREVIEW_FOCUSLOCK_1)
        .scale(this.focusLockerScale)
        .responseRegion({ x: 0, y: 0, width: '150%', height: '150%' })
        .onClick(()=>{
          if (this.isHideAnimating) {
            HiLog.i(TAG, 'locker animating...');
            return;
          }
          this.mAction.updateLockLevel(LockLevel.LOCK_PAUSE);
          const isFocusLocked: boolean = !this.isFocusLocked;
          this.changeFocusLockState(isFocusLocked);
          this.isFocusLocked = isFocusLocked;
        })
    }
  }
}