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

import lazy { reduxSubscribe, OhCombinedState } from '@ohos/common/src/main/ets/redux';
import lazy { Dispatch, Unsubscribe, getStates } from '@ohos/common/src/main/ets/redux/Store';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { PositionType } from '@ohos/common/src/main/ets/utils/types';
import lazy { FocusExposureAreaDispatcher } from
  '@ohos/common/src/main/ets/component/focusExposure/FocusExposureAreaDispatcher';
import lazy { ExposureView } from '../../commonfunc/exposure/ExposureView';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { FocusExposureService } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureService';
import lazy { LockLevel, EXPOSURE_ICON_SIZE, CANVAS_HEIGHT } from
  '@ohos/common/src/main/ets/component/focusExposure/FocusExposureHelper';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';

const TAG: 'ExposureArea' = 'ExposureArea';

@Component
export struct ExposureArea {
  @Prop previewAnimatePosition: PositionType = { x: 0, y: 0 };
  @Prop focusPosition: PositionType = { x: 0, y: 0 };
  @Prop @Watch('handlePanGestureActionChange') panGestureAction: TouchType = TouchType.Up;
  @Prop @Watch('handlePanGestureActionChange') panGestureEventOffset: number = 0;
  @Link exposurePosition: PositionType;
  @Prop @Watch('resetExposure') touchPreviewAgain: string = '';

  @State rotateAngle: number = 0;
  @State mode: ModeType = ModeType.NONE;
  @State isShowExposure: boolean = false;
  @State screenExposureY: number = 60;
  @State gestureStartY: number = 0;
  @State isShowExposureSlider: boolean = false;
  @State isShowExposureValue: boolean = false;
  @State isExposureChangedEnd: boolean = false;
  @State isShowExposureRing: boolean = false;
  @Prop isHdr: boolean = false;

  private mSubscriber: Unsubscribe = {
    destroy: () => { }
  };
  private mAction: FocusExposureAreaDispatcher = new FocusExposureAreaDispatcher();
  private eventOffset: number = 0;
  private mFocusExposureService: FocusExposureService = FocusExposureService.getInstance();
  private isImmersive: boolean = false;
  private mainTrigCompo: UIOperationType = UIOperationType.NULL;
  private oldMainTrigCompo: UIOperationType = UIOperationType.NULL;
  private isShowtimeLapse: boolean = false;

  aboutToAppear(): void {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mode = state.get<ModeType>('modeReducer', 'mode');
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.isShowExposure = state.get<boolean>('focusExposureReducer', 'isShowExposure');
      this.isShowExposureRing = state.get<boolean>('focusExposureReducer', 'isShowExposureRing');
      this.isImmersive = state.get<boolean>('uiReducer', 'isImmersive');
      this.mainTrigCompo = state.get<UIOperationType>('uiReducer', 'mainTrigCompo');
      this.isShowtimeLapse = state.get<boolean>('settingReducer', 'isShowtimeLapse');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
  }

  aboutToDisappear(): void {
    HiLog.i(TAG, 'aboutToDisappear called.');
    this.mSubscriber.destroy();
  }

  private resetExposure(): void {
    this.isShowExposureSlider = false;
    this.screenExposureY = 60;
    this.gestureStartY = 0;
  }

  private getExposureViewScale(): PositionType {
    const scale: number = FocusExposureService.getInstance().getFocusExposureVScale();
    return { x: scale, y: scale };
  }

  // 滑动开始
  private panGestureActionStart = (): void => {
    HiLog.i(TAG, 'panGestureAction panGestureActionStart');
    if (this.isShowExposure) {
      if (this.mainTrigCompo !== UIOperationType.EXPOSURE) {
        if (this.isImmersive) {
          this.oldMainTrigCompo = this.mainTrigCompo;
        }
        this.mAction.isEnterImmersive(true, UIOperationType.EXPOSURE);
      }

      this.isShowExposureSlider = true;
      this.isShowExposureValue = true;
      this.gestureStartY = this.screenExposureY;
    }
  }

  // 滑动更新
  private panGestureActionUpdate = () => {
    HiLog.i(TAG, 'panGestureAction panGestureActionUpdate');

    if (this.isShowExposure) {
      this.isExposureChangedEnd = false;
      let screenExposureY: number = (this.gestureStartY + this.panGestureEventOffset / 5);
      if (screenExposureY < EXPOSURE_ICON_SIZE / 2) {
        screenExposureY = EXPOSURE_ICON_SIZE / 2;
      } else if (screenExposureY > CANVAS_HEIGHT - EXPOSURE_ICON_SIZE / 2) {
        screenExposureY = CANVAS_HEIGHT - EXPOSURE_ICON_SIZE / 2;
      }
      this.screenExposureY = screenExposureY;
      HiLog.i(TAG, `panGestureAction screenExposureY: ${this.screenExposureY},  gestureStartY: ${this.gestureStartY},
        panGestureEventOffset: ${this.panGestureEventOffset}`);
    }
  }

  // 滑动结束
  private panGestureActionEnd = (): void => {
    HiLog.i(TAG, 'panGestureAction panGestureActionEnd');
    if (this.isShowExposure) {
      this.isExposureChangedEnd = true;
      this.gestureStartY = this.screenExposureY;
      this.isShowExposureValue = false;
      this.isShowExposureSlider = false;
      if (this.oldMainTrigCompo !== UIOperationType.NULL) {
        this.mAction.isEnterImmersive(true, this.oldMainTrigCompo);
        this.oldMainTrigCompo = UIOperationType.NULL;
      } else {
        this.mAction.isEnterImmersive(false, UIOperationType.NULL);
      }
    }
  }

  // 处理滑动手势 - 调整曝光度
  private handlePanGestureActionChange(field: string): void {
    HiLog.i(TAG, `handlePanGestureActionChange panGestureAction: ${this.panGestureAction}, field: ${field}`);
    if ((this.panGestureAction === TouchType.Down || this.panGestureAction === TouchType.Move) &&
      field === 'panGestureAction') {
      // 兼容start 和 update 通知合并场景
      this.panGestureActionStart();
    } else if (this.panGestureAction === TouchType.Move && this.eventOffset !== this.panGestureEventOffset) {
      this.eventOffset = this.panGestureEventOffset;
      this.panGestureActionUpdate();
    } else if (this.panGestureAction === TouchType.Up && field === 'panGestureAction') {
      this.panGestureActionEnd();
    }
  }

  // 测光分离
  private onTouchEvent(event?: TouchEvent): void {
    HiLog.i(TAG, 'onTouchEvent E');
    if (event === undefined || !this.isShowExposureRing || this.isShowtimeLapse ||
      this.isImmersive && this.mainTrigCompo !== UIOperationType.LR_SWIPE) {
      return;
    }

    const eventType = event.type;
    HiLog.i(TAG, `onTouchEvent eventType: ${eventType}`);
    if (eventType === TouchType.Down) {
      this.mAction.uiDisabled();
      if (getStates().get<LockLevel>('focusExposureReducer', 'smartControlLocked')) {
        this.mAction.resetSmartControlLocked();
      }
      this.mAction.updateLockLevel(LockLevel.LOCK_PAUSE);
      this.exposurePosition = this.mFocusExposureService.getEffectiveCoordinates(event,
        this.previewAnimatePosition, false);
    } else if (eventType === TouchType.Move) {
      const coordinates: PositionType =
        this.mFocusExposureService.getEffectiveCoordinates(event, this.previewAnimatePosition, false);
      this.exposurePosition = coordinates;
    } else if (eventType === TouchType.Up) {
      this.mAction.uiEnabled();
      this.mAction.updateLockLevel(LockLevel.FOCUS_EXPOSURE_LOCK);
      HiLog.i(TAG, `setMeteringPointX: ${this.exposurePosition.x} setMeteringPointY: ${this.exposurePosition.y}`);
      this.mFocusExposureService.setExposureValue({ exposurePoint: this.exposurePosition });
    }
    HiLog.i(TAG, 'onTouchEvent X');
  }

  build() {
    if (this.isShowExposure || this.isShowExposureRing) {
      ExposureView({
        focusPosition: this.focusPosition,
        screenExposureY: this.screenExposureY,
        isShowExposureSlider: this.isShowExposureSlider,
        isShowExposureValue: this.isShowExposureValue,
        isExposureChangedEnd: this.isExposureChangedEnd,
        exposurePosition: this.exposurePosition,
        isHdr: this.isHdr
      })
        .rotate(this.isShowExposureRing ? { angle: 0 } : { angle: this.rotateAngle })
        .onTouch((event?: TouchEvent) => this.onTouchEvent(event))
        .key(ComponentIdKeys.LONG_TOUCH_PREVIEW_EXPOSURE_1)
        .hitTestBehavior(this.isShowExposureRing ? HitTestMode.Block : HitTestMode.Transparent)
        .responseRegion({ x: -10, y: -10, width: '167%', height: '167%' })
        .scale(this.getExposureViewScale())
    }
  }
}