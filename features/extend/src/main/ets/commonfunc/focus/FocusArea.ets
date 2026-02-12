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
import lazy { reduxSubscribe, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { Dispatch, Unsubscribe, getStates } from '@ohos/common/src/main/ets/redux/Store';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { PositionType } from '@ohos/common/src/main/ets/utils/types';
import lazy { FocusExposureAreaDispatcher } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureAreaDispatcher';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { FocusExposureService } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureService';
import lazy { FOCUS_SIZE, LockLevel } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper'

const TAG: 'FocusArea' = 'FocusArea';

@Component
export struct FocusArea {
  @Link focusPosition: PositionType;
  @Prop previewAnimatePosition: PositionType = { x: 0, y: 0 };
  @Prop @Watch('changeFocusShow') touchPreviewAgain: string = '';
  @State focusBoxScale: ScaleOptions = { x: 1.0, y: 1.0 };
  @State isShowExposureRing: boolean = false;
  @State mode: ModeType = ModeType.NONE;
  @State @Watch('changeFocusShow') isShowFocus: boolean = false;
  @State focusShowWithAnimation: boolean = false;
  @State isHalfCollapsLEM: boolean = false;
  @State @Watch('handleSmartControlLocked') smartControlLocked: boolean = false;
  @Prop isHdr: boolean = false;

  private mSubscriber: Unsubscribe = {
    destroy: () => { }
  };
  private mAction: FocusExposureAreaDispatcher = new FocusExposureAreaDispatcher();
  private mFocusExposureService: FocusExposureService = new FocusExposureService();

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear called.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.isHalfCollapsLEM = state.get<boolean>('collapsReducer', 'isHalfCollapsLEM');
      this.isShowFocus = state.get<boolean>('focusExposureReducer', 'isShowFocus');
      this.isShowExposureRing = state.get<boolean>('focusExposureReducer', 'isShowExposureRing');
      this.smartControlLocked = state.get<boolean>('focusExposureReducer', 'smartControlLocked');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear called.');
    this.mSubscriber.destroy();
  }

  private handleFocusShow(initialScale = 1.3): void {
    const scale: number = FocusExposureService.getInstance().getFocusExposureVScale();
    this.focusBoxScale = { x: initialScale * scale, y: initialScale * scale };
    this.focusShowWithAnimation = this.isShowFocus;
    HiLog.i(TAG, 'handleFocusShow 1.3 - 0.95.');
    animateToImmediately({
      duration: 200,
      curve: Curve.Friction,
      onFinish: () => {
        HiLog.i(TAG, 'handleFocusShow 0.95 - 1.');
        animateToImmediately({
          duration: 200,
          curve: Curve.Friction
        }, () => {
          this.focusBoxScale = { x: 1.0 * scale, y: 1.0 * scale };
        });
      }
    }, () => {
      this.focusBoxScale = { x: 0.95 * scale, y: 0.95 * scale };
    });
  }

  private handleFocusHide(): void {
    const scale: number = FocusExposureService.getInstance().getFocusExposureVScale();
    this.focusBoxScale = { x: 1.0 * scale, y: 1.0 * scale };
    animateToImmediately({
      duration: 200,
      curve: Curve.Friction,
      onFinish: () => {
        this.focusShowWithAnimation = this.isShowFocus;
      }
    }, () => {
      this.focusBoxScale = { x: 1.3 * scale, y: 1.3 * scale };
    })
  }

  private changeFocusShow(): void {
    HiLog.i(TAG, `changeFocusShow isShowFocus: ${this.isShowFocus}.`);
    if (this.isShowFocus) {
      this.handleFocusShow();
    } else {
      this.handleFocusHide();
    }
  }

  private handleSmartControlLocked(): void {
    if (this.smartControlLocked && this.isShowFocus) {
      this.handleFocusShow(1);
    }
  }

  private getExposureViewScale(): PositionType {
    const scale: number = FocusExposureService.getInstance().getFocusExposureVScale();
    return { x: scale, y: scale };
  }

  private onTouchFocusEvent(event?: TouchEvent | undefined): void {
    HiLog.i(TAG, 'onTouchFocusEvent E');
    if (event === undefined || !this.isShowExposureRing) {
      return;
    }
    const eventType = event.type;
    HiLog.i(TAG, `onTouchFocusEvent eventType: ${eventType}`);
    if (eventType === TouchType.Down) {
      if (getStates().get<LockLevel>('focusExposureReducer', 'smartControlLocked')) {
        this.mAction.resetSmartControlLocked();
      }
      this.focusPosition = this.mFocusExposureService.getEffectiveCoordinates(event, this.previewAnimatePosition, true);
      this.mAction.uiDisabled();
      this.mAction.updateLockLevel(LockLevel.LOCK_PAUSE);
    } else if (eventType === TouchType.Move) {
      const coordinates: PositionType =
        this.mFocusExposureService.getEffectiveCoordinates(event, this.previewAnimatePosition, true);
      this.focusPosition = coordinates;
    } else if (eventType === TouchType.Up) {
      this.mAction.uiEnabled();
      this.mAction.updateLockLevel(LockLevel.FOCUS_EXPOSURE_LOCK);
      this.mFocusExposureService.setFocusValue({
        focusMode: camera.FocusMode.FOCUS_MODE_AUTO,
        focusPoint: this.focusPosition
      });
    }
  }

  build() {
    if (this.focusShowWithAnimation) {
      Image($r('app.media.focus'))
        .width(FOCUS_SIZE)
        .height(FOCUS_SIZE)
        .fillColor(Color.White)
        .draggable(false)
        .scale(this.focusBoxScale)
        .key(ComponentIdKeys.PREVIEW_FOCUSBOX_1)
        .onTouch((event?: TouchEvent) => this.onTouchFocusEvent(event))
        .hitTestBehavior(this.isShowExposureRing ? HitTestMode.Block : HitTestMode.Default)
        .responseRegion({ x: -10, y: -10, width: '125%', height: '125%' })
    }
  }
}