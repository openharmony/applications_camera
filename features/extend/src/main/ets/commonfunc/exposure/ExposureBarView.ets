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

import lazy { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { OhCombinedState, Unsubscribe, Dispatch, getStates, reduxSubscribe } from '@ohos/common/src/main/ets/redux';
import lazy { FeatureManager } from '@ohos/common/src/main/ets/function/core/FeatureManager';
import lazy { FunctionId } from '@ohos/common/src/main/ets/function/core/functionproperty/FunctionId';
import lazy { FunctionAction } from '@ohos/common/src/main/ets/function/core/FunctionAction';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import lazy { Action, ActionData } from '@ohos/common/src/main/ets/redux/actions/Action';
import lazy { VibratorService } from '@ohos/common/src/main/ets/component/vibration/VibratorService';
import lazy { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import lazy { UIOperationType } from '@ohos/common/src/main/ets/component/uicomponent/UIOperationType';
import lazy { DirectionToAngleUtil } from '@ohos/common/src/main/ets/utils/DirectionToAngleUtil';
import camera from '@ohos.multimedia.camera';
import lazy { RenderLocation } from '@ohos/common/src/main/ets/function/core/functionproperty/RenderLocation';
import lazy { ExposureFunction } from './ExposureFunction';
import lazy { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import lazy { PositionType } from '@ohos/common/src/main/ets/utils/types';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import ResGetter from '@ohos/common/src/main/ets/utils/ResGetter';
import lazy { CommonConstants } from '@ohos/common/src/main/ets/statistics/CommonConstants';
import lazy { AccessibilityUtils } from '@ohos/common/src/main/ets/utils/AccessibilityUtils';
import lazy { getColorString } from '@ohos/common/src/main/ets/utils//ColorUtil';
import lazy { ActionType } from '@ohos/common/src/main/ets/redux/actions/ActionType';
import lazy { FocusExposureService } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureService';
import lazy { FocusExposureAction } from '@ohos/common/src/main/ets/component/focusExposure/FocusExposureAction';
import lazy { StoreManager } from '@ohos/common/src/main/ets/worker/StoreManager';
import lazy { SystemLanguageUtil } from '@ohos/common/src/main/ets/utils/SystemLanguageUtil';
import lazy { DirectionCorrectionService } from '@ohos/common/src/main/ets/service/direction/DirectionCorrectionService';

/* instrument ignore file */
const TAG: string = 'ExposureBarView';

class PositionData {
  public x: number = 0;
  public y: number = 0;
}

class FunctionValueStruct {
  public exposureMode: camera.ExposureMode = camera.ExposureMode.EXPOSURE_MODE_LOCKED;
  public exposureValue: number = 0;
}

class ExposureDispatcher {
  private mDispatch: Dispatch = (data) => data;

  private mMode: ModeType = ModeType.NONE;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public setMode(mode: ModeType) {
    this.mMode = mode;
  }

  public changeFunctionValue(id: FunctionId, value: FunctionValueStruct): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, value));
  }

  public hideExposureView(iconId: number): void {
    this.mDispatch(Action.proSonChangeState(iconId));
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.PRO_BAR));
  }

  public sliderValue(sliderVale: Number, timeLapse: string): void {
    this.mDispatch(Action.timeLapseSlider(sliderVale, timeLapse));
  }

  public uiDisabled(): void {
    this.mDispatch(Action.uiState(false));
  }

  public uiEnabled(): void {
    this.mDispatch(Action.uiState(true));
  }

  public isProShowTreasureBox(): void {
    this.mDispatch(Action.isProShowTreasureBox());
  }

  public isProHideTreasureBox(): void {
    this.mDispatch(Action.isProHideTreasureBox());
  }
}

@Component
export struct ExposureBarView {
  private setTimeoutForLapse: Function = () => {};
  private clearTimeoutForLapse: Function = () => {};
  private mAction: ExposureDispatcher = new ExposureDispatcher();
  private timerId: number = Number.MIN_VALUE;
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private mBase: BaseComponent = new BaseComponent();
  @State exposureFunValue: number = 0;
  @State @Watch('directionChange') mDirection: WindowDirection = WindowDirection.TOP;
  @State rotateAngle: number = 0;
  private exposureModeTimerId: number = Number.MIN_VALUE;
  private mExposureFunction: ExposureFunction = FeatureManager.getInstance()
    .getFunction(FunctionId.EXPOSURE) as ExposureFunction;
  private initValue: number = this.mExposureFunction?.getModeValue();
  private segCount: number = 4; // segment数
  private gapNumInEachSeg: number = 6; // 每段的间隙数 = 每段的分割数,general: 1 longWhiteLine + N redLine
  private valuesRange: string[] = ['-4', '-3.7', '-3.3', '-3', '-2.7', '-2.3', '-2', '-1.7', '-1.3', '-1', '-0.7', '-0.3',
    ' 0', '+0.3', '+0.7', '+1', '+1.3', '+1.7', '+2', '+2.3', '+2.7', '+3', '+3.3', '+3.7', '+4'];
  private sliderCanvasWidth: number = 316; // canvas组件宽度
  private textWidth: number = 150; // 显示文字的组件宽度
  private sliderCanvasHeight: number = 80; // 一般用于控制底部
  private longWhiteLineHeight: number = 10; // 滑动条细长白线高
  private longWhiteLineWidth: number = 1.5; // 滑动条细长白线宽
  private shortWhiteLineHeight: number = 5; // 滑动条细短白线高
  private shortWhiteLineWidth: number = 1.5; // 滑动条细短白线宽
  private redLineHeight: number = 20; // 滑动条粗红线高,直线段为20-2-2,lineTo起点终点在直线段首尾端
  private redLineWidth: number = 4; // 滑动条粗红线宽
  private bottomPadding: number = 22;
  private bothSidesPadding: number = 8; // 左侧距首点左侧、右侧距尾点右侧 padding
  private segLength: number = (this.sliderCanvasWidth - this.bothSidesPadding * 2 - this.longWhiteLineWidth) /
  this.segCount; // 前一大点中间距后一大点中间,即28.85
  private dotDistance: number = this.segLength / this.gapNumInEachSeg; // 前一点中间距后一点中间,即9.5
  private spotCount: number = this.segCount * this.gapNumInEachSeg + 1; // 总点数
  @State isSliding: boolean = false; // 用于滑动过程中,临时变量
  @State isShowExposureText: boolean = true;
  @State isCanvasClicked: boolean = false; // 用于滑动过程中,临时变量
  @State @Watch('canvasInit') screenX: number = this.bothSidesPadding + this.longWhiteLineWidth / 2 + this.initValue * this.segLength; // 粗红线中心位置
  private gestureStartX: number = 0; // 单次滑动起始位置缓存
  @State sliderValue: number = 0; // 用于显示值
  private lastFloatValue: number = 0;
  private isPanGesStartEndOrTap: boolean = false;
  private sliderSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private sliderCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.sliderSettings);
  private sliderOffCanvasCtx: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.sliderCanvasWidth, this.sliderCanvasHeight, this.sliderSettings);
  private readonly ONE_RADIAN: number = Math.PI / 180;
  private mSubscriber: Unsubscribe | null = null;
  @State isExposureAutoState: boolean = true;
  private bigTextTimer: number = setTimeout(() => {
  }); // 大字体消失延时器
  private readonly BIG_TEXT_DISAPPEAR_DURATION: number = 350;
  private tips: String[] = [];
  private showUnit: boolean = false;
  private unit: String = '';
  @State bigTextOpacity: number = 0;
  private title = '';
  private timeLapse = -1;
  @Link showEvLocked: boolean;
  private globalAutoChangeFlag: boolean = false;
  @StorageLink('enableScreenReader') enableScreenReader: boolean = false;
  @State exposureOpacity: number = 0;
  private initialLoading: boolean = true;
  @State isVdeLandscape: boolean = false;
  @State isVdeSemiCollapsed: boolean = false;
  @Prop isHdr: boolean = false;

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear invoke E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState) => {
      this.mDirection =
        DirectionCorrectionService.directionCorrection(state.get<WindowDirection>('contextReducer', 'direction'),
          state.get<boolean>('windowReducer', 'isLockRotation'));
      this.rotateAngle = state.get<number>('contextReducer', 'rotateAngle');
      this.mAction.setMode(state.get<ModeType>('modeReducer', 'mode'));
      this.isVdeLandscape = state.get<boolean>('collapsReducer', 'isVdeLandscape');
      this.isVdeSemiCollapsed = state.get<boolean>('collapsReducer', 'isVdeSemiCollapsed');
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.initialLoading = false;
    this.setExposureModeTimeout();
    this.sliderCanvasWidth = Math.min(this.sliderCanvasWidth, getStates().get<number>('windowReducer', 'windowWidth'));
    this.bothSidesPadding = Math.min(this.bothSidesPadding, (this.sliderCanvasWidth - (this.sliderCanvasWidth -
      this.bothSidesPadding * 2)) / 2);
    this.segLength = (this.sliderCanvasWidth - this.bothSidesPadding * 2 - this.longWhiteLineWidth) / this.segCount;
    this.dotDistance = this.segLength / this.gapNumInEachSeg;
    this.spotCount = this.segCount * this.gapNumInEachSeg + 1;
    this.initValue = Number(this.initValue?.toFixed(1));
    this.valuesRange = !SystemLanguageUtil.isRTL() ? [...this.valuesRange] : [...this.valuesRange].reverse();
    let initIndex = this.valuesRange.findIndex(index => {
      return Number(index) === this.initValue;
    });
    this.sliderValue = initIndex;
    this.screenX = this.bothSidesPadding + this.longWhiteLineWidth / 2 + initIndex * (this.segLength /
    this.gapNumInEachSeg); // 粗红线中心位置
    this.lastFloatValue = initIndex;
    this.mEventBus.on(ActionType.ACTION_LAPSE_AUTO, (data: ActionData) => this.changeExposureToState(data['autoType']),
      this.mBase.hashCode());
    this.mEventBus.on(ActionType.ACTION_LUMATION_CHANGE_STATE, () => this.refreshingBar(),
      this.mBase.hashCode());
    this.setTimeoutForLapse();
    this.onProHideTreasureBox(true);
    HiLog.i(TAG, 'aboutToAppear invoke X.');
  }

  aboutToDisappear() {
    HiLog.i(TAG, 'aboutToDisappear invoke E.');
    this.onProHideTreasureBox(false);
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber?.destroy();
    this.clearExposureModeTimeout();
    this.clearTimeoutForLapse();
    HiLog.i(TAG, 'aboutToDisappear invoke X.');
  }

  private onProHideTreasureBox(isHide: boolean): void {
    return
    if (isHide) {
      this.mAction.isProHideTreasureBox();
    } else {
      this.mAction.isProShowTreasureBox();
    }
  }

  private async directionChange() {
    HiLog.i(TAG, 'directionChange E');
    if (!this.isSliding && !this.initialLoading) {
      this.canvasInit();
    }
    HiLog.i(TAG, 'directionChange X');
  }

  private refreshingBar(): void {
    this.initValue = this.mExposureFunction?.getModeValue();
    this.initValue = Number(this.initValue?.toFixed(1));
    let initIndex = this.valuesRange.findIndex(index => {
      return Number(index) === this.initValue;
    });
    this.sliderValue = initIndex;
    this.lastFloatValue = initIndex;
    this.screenX = this.bothSidesPadding + this.longWhiteLineWidth / 2 + initIndex * (this.segLength /
    this.gapNumInEachSeg); // 粗红线中心位置
  }

  private changeExposureModeFunctionValue(value: number): void {
    HiLog.i(TAG, `changeExposureModeFunctionValue value --- ${value}`);
    if (this.isShowExposureText) {
      this.clearBigTextTimer();
    }
    this.showEvLocked = false;
    this.isExposureAutoState = false;
    FocusExposureService.getInstance().setExposureValue({
      exposureMode: camera.ExposureMode.EXPOSURE_MODE_AUTO,
      exposureValue: value,
      isParamSetting: true,
    });
    VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
    StoreManager.getInstance().postMessage(FocusExposureAction.smartControlLock(false));
  }

  private clearExposureModeTimeout(): void {
    HiLog.i(TAG, 'clearPortraitBeautyModeTimeout.');
    if (Number.MIN_VALUE !== this.exposureModeTimerId) {
      clearTimeout(this.exposureModeTimerId);
    }
    this.clearTimeoutForLapse();
    this.clearTimer();
  }

  private setExposureModeTimeout(): void {
    HiLog.i(TAG, 'setExposureModeTimeout.');
    this.clearExposureModeTimeout();
    this.exposureModeTimerId = setTimeout((): void => {
    }, 5000);
    this.setTimeoutForLapse();
    this.setTimeout();
  }

  private clearTimer(): void {
    if (Number.MIN_VALUE !== this.timerId) {
      clearTimeout(this.timerId);
    }
  }

  private setTimeout(): void {
    this.clearTimer();
    this.timerId = setTimeout((): void => {
      this.mAction.hideExposureView(-1);
    }, this.enableScreenReader ? 3 * 5000 : 5000); // 开启屏幕朗读延长3倍时间自动关闭
  }

  private getTitlePosition(): PositionType {
    if (this.isVdeSemiCollapsed) {
      return {
        x: (this.sliderCanvasWidth - this.textWidth) / 2,
        y: -280,
      }
    }
    return {
      x: (this.sliderCanvasWidth - this.textWidth) / 2,
      y: (this.mDirection === WindowDirection.LEFT || this.mDirection === WindowDirection.RIGHT) ? -120 : -65,
    }
  }

  private canvasInit(): void {
    HiLog.i(TAG, 'canvasInit E');
    this.sliderCanvasContext.clearRect(0, 0, this.sliderCanvasWidth, this.sliderCanvasHeight);
    this.sliderOffCanvasCtx.clearRect(0, 0, this.sliderCanvasWidth, this.sliderCanvasHeight);
    this.sliderOffCanvasCtx.strokeStyle = '#FFFFFF';
    this.sliderOffCanvasCtx.fillStyle = '#FFFFFF';
    this.sliderOffCanvasCtx.lineWidth = 1.5;
    //用来填充刻度的临界点
    let fillRectCenterX = this.getFillRectCenterX(this.screenX);
    let curFloatValue = (fillRectCenterX - this.bothSidesPadding - this.longWhiteLineWidth / 2) / (this.segCount *
    this.segLength) * (this.segCount * this.gapNumInEachSeg);
    let rightSlideThroughFlag =
      Number(curFloatValue?.toFixed(3)) >= Number(this.lastFloatValue?.toFixed(0));
    let leftSlideThroughFlag =
      Number(curFloatValue?.toFixed(3)) <= Number(this.lastFloatValue?.toFixed(0));
    let nextValue = Number(curFloatValue?.toFixed(0));
    if ((rightSlideThroughFlag || leftSlideThroughFlag ||
    this.isPanGesStartEndOrTap) && this.sliderValue !== nextValue) {
      this.sliderValue = nextValue; // 返回的是位置
      this.changeExposureModeFunctionValue(Number(this.valuesRange[this.sliderValue]));
    }
    this.lastFloatValue = curFloatValue;
    this.redrawCanvas(fillRectCenterX); // 离屏重绘制canvas
    this.sliderCanvasContext.transferFromImageBitmap(this.sliderOffCanvasCtx.transferToImageBitmap());
    HiLog.i(TAG, 'canvasInit X');
  }

  private redrawCanvas(fillRectCenterX: number): void {
    HiLog.i(TAG, 'redrawCanvas E');
    for (let i = 0; i < this.spotCount; i++) {
      // 用来处理x轴移动
      let commonLength: number = this.bothSidesPadding + this.longWhiteLineWidth / 2 +
        Math.floor(i / this.gapNumInEachSeg) * this.segLength + (i % this.gapNumInEachSeg) * this.dotDistance;
      const initIndex = this.valuesRange.findIndex((item, index) => {
        return index === this.sliderValue;
      })
      if ((i % this.gapNumInEachSeg === 0) || i === initIndex) {
        let fontText = `${this.valuesRange[i].toString()} ${this.showUnit ? this.unit : ''}`;
        let fontPosYGap = this.isSliding ? 29 : 27;
        this.sliderOffCanvasCtx.rotate(0);
        if (this.mDirection === WindowDirection.LEFT || this.mDirection === WindowDirection.RIGHT) {
          fontPosYGap = this.isSliding ? 38 : 36;
        }
        let fontTextPos = this.getTextPosition({
          x: SystemLanguageUtil.isRTL() ? commonLength + 3 : commonLength,
          y: this.sliderCanvasHeight - this.bottomPadding - fontPosYGap
        });
        this.sliderOffCanvasCtx.globalAlpha = 1;
        this.sliderOffCanvasCtx.font = `bold ${vp2px(11)}px`;
        this.sliderOffCanvasCtx.textAlign = 'center';
        this.sliderOffCanvasCtx.textBaseline = 'middle';
        this.sliderOffCanvasCtx.shadowColor = '#33000000';
        this.sliderOffCanvasCtx.shadowBlur = 3;
        if (Math.abs(initIndex - i) < 2 && i !== initIndex && !this.isSliding) {
          this.sliderOffCanvasCtx.globalAlpha = 0;
          this.sliderOffCanvasCtx.shadowColor = '#00000000';
        } else if (this.isSliding && i === initIndex && (i % this.gapNumInEachSeg !== 0)) {
          this.sliderOffCanvasCtx.globalAlpha = 0;
          this.sliderOffCanvasCtx.shadowColor = '#00000000';
        }
        this.sliderOffCanvasCtx.font = 'bold 11';
        this.sliderOffCanvasCtx.rotate(DirectionToAngleUtil.geViewRotate(this.mDirection) * this.ONE_RADIAN);
        this.sliderOffCanvasCtx.fillText(fontText, fontTextPos.x, fontTextPos.y);
        this.sliderOffCanvasCtx.rotate(-DirectionToAngleUtil.geViewRotate(this.mDirection) * this.ONE_RADIAN);
      }
      if (i % this.gapNumInEachSeg === 0) {
        this.sliderOffCanvasCtx.globalAlpha = 1;
        this.sliderOffCanvasCtx.fillStyle = '#ffffff';
        this.sliderOffCanvasCtx.shadowColor = '#4d000000';
        this.sliderOffCanvasCtx.shadowBlur = 3;
        this.sliderOffCanvasCtx.fillRect(commonLength - this.longWhiteLineWidth / 2, this.sliderCanvasHeight -
        this.bottomPadding - this.longWhiteLineHeight, this.longWhiteLineWidth, this.longWhiteLineHeight);
      } else {
        this.sliderOffCanvasCtx.globalAlpha = 0.6;
        this.sliderOffCanvasCtx.shadowColor = '#33000000';
        this.sliderOffCanvasCtx.shadowBlur = 3;
        this.sliderOffCanvasCtx.fillRect(commonLength - this.shortWhiteLineWidth / 2, this.sliderCanvasHeight -
        this.bottomPadding - this.shortWhiteLineHeight, this.shortWhiteLineWidth, this.shortWhiteLineHeight);
      }
    }
    if (this.sliderValue !== -1) {
      HiLog.i(TAG, `click4 ${this.initValue}`);
      this.sliderOffCanvasCtx.beginPath();
      this.sliderOffCanvasCtx.globalAlpha = 1;
      this.sliderOffCanvasCtx.lineWidth = this.redLineWidth;
      this.sliderOffCanvasCtx.lineCap = 'round';
      this.sliderOffCanvasCtx.strokeStyle = getColorString();
      this.sliderOffCanvasCtx.moveTo(fillRectCenterX, this.sliderCanvasHeight - (this.bottomPadding - 1) -
        this.redLineWidth / 2);
      this.sliderOffCanvasCtx.lineTo(fillRectCenterX, this.sliderCanvasHeight - (this.bottomPadding - 1) -
      this.redLineHeight + this.redLineWidth / 2);
      this.sliderOffCanvasCtx.stroke();
    }
    HiLog.i(TAG, 'redrawCanvas X');
  }

  private getFillRectCenterX(mScreenX: number): number {
    let fillRectCenterX = mScreenX;
    if (fillRectCenterX < this.bothSidesPadding + this.longWhiteLineWidth / 2) {
      fillRectCenterX = this.bothSidesPadding + this.longWhiteLineWidth / 2;
    } else if (fillRectCenterX > this.sliderCanvasWidth - this.bothSidesPadding - this.longWhiteLineWidth / 2) {
      fillRectCenterX = this.sliderCanvasWidth - this.bothSidesPadding - this.longWhiteLineWidth / 2;
    }
    return fillRectCenterX;
  }

  private getNextScreenX(mScreenX: number): number {
    let fillRectCenterX = this.getFillRectCenterX(mScreenX);
    // 将位置换成了刻度条位置
    let curFloatValue = (fillRectCenterX - this.bothSidesPadding - this.longWhiteLineWidth / 2) / (this.segCount *
    this.segLength) * (this.segCount * this.gapNumInEachSeg);
    let nextValue = Number(curFloatValue?.toFixed(0));
    // 将刻度换成了位置
    let nextScreenX = nextValue / (this.segCount * this.gapNumInEachSeg) * (this.segCount * this.segLength) +
    this.bothSidesPadding + this.longWhiteLineWidth / 2;
    return nextScreenX;
  }

  private setBigTextTimer() {
    this.clearBigTextTimer();
    this.bigTextTimer = setTimeout((): void => {
      this.bigTextOpacity = 0;
    }, this.BIG_TEXT_DISAPPEAR_DURATION);
  }

  private clearBigTextTimer() {
    if (this.bigTextTimer) {
      clearTimeout(this.bigTextTimer);
      this.bigTextOpacity = 1;
    }
  }

  private getTextPosition(textPos: PositionData): PositionData {
    switch (this.mDirection) {
      case WindowDirection.TOP:
        break;
      case WindowDirection.BOTTOM:
        textPos.x = -textPos.x;
        textPos.y = -textPos.y;
        break;
      case WindowDirection.LEFT:
        let tempX = textPos.x;
        textPos.x = -textPos.y;
        textPos.y = tempX;
        break;
      case WindowDirection.RIGHT:
        let tempY = textPos.y;
        textPos.y = -textPos.x;
        textPos.x = tempY;
        break;
      default:
        break;
    }
    return textPos;
  }

  // 获取手势事件的localX
  private getFingerListLocalX(event: GestureEvent): number | null {
    let localX: number | null = null;
    event.fingerList.forEach((eventItem: FingerInfo) => {
      if (eventItem) {
        localX = eventItem?.localX;
        return;
      }
    });
    return localX;
  }

  private tapGestureResponse(event?: GestureEvent): void {
    if (event === undefined) {
      return;
    }
    if (!this.enableScreenReader && event.fingerList[0]?.localX === undefined) {
      return;
    }
    this.clearTimer();
    this.isPanGesStartEndOrTap = true;
    this.isCanvasClicked = true;
    if (this.enableScreenReader) {
      let initIndex = (this.sliderValue + 1 > this.valuesRange.length - 1) ? 0 : this.sliderValue + 1;
      this.screenX = this.bothSidesPadding + this.longWhiteLineWidth / 2 + initIndex *
        (this.segLength / this.gapNumInEachSeg); // 粗红线中心位置
      setTimeout(() => {
        AccessibilityUtils.sendAnnounceAccessibilityEvent(
          `${ResGetter.getStringSafe($r('app.string.accessibility_exposure_compensation_tile'))} ${this.valuesRange[this.sliderValue]}`);
      }, 10);
    } else {
      this.screenX = this.getNextScreenX(event.fingerList[0]?.localX); // 双击文本的时候
      HiLog.i(TAG, `4 this.screenX ${this.screenX} `);
    }
    this.isPanGesStartEndOrTap = false;
    this.setTimeout();
    this.setTimeoutForLapse();
    this.setBigTextTimer();
  }

  private onPanGestureEnd(event?: GestureEvent): void {
    if (!event) {
      return;
    }
    this.gestureStartX = this.screenX;
    this.isSliding = false;
    this.isPanGesStartEndOrTap = true;
    let localX = this.getFingerListLocalX(event);
    if (!localX) {
      return;
    }
    this.screenX = this.getNextScreenX(localX);
    HiLog.i(TAG, `3 this.screenX ${this.screenX} `);
    this.isPanGesStartEndOrTap = false;
    this.setBigTextTimer();
    this.setTimeout();
    this.setTimeoutForLapse();
    this.mAction.isEnterImmersive(false);
    this.mAction.uiEnabled();
  }

  private onLongPressGestureEnd(event?: GestureEvent): void {
    if (!event) {
      return;
    }
    this.setTimeout();
    this.setTimeoutForLapse();
    this.setBigTextTimer();
    this.mAction.uiEnabled();
  }

  private getABText(): string {
    return `${ResGetter.getStringSafe($r('app.string.accessibility_exposure_compensation_tile'))} ${this.valuesRange[this.sliderValue]}`
  }

  build() {
    Column() {
      Row() {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.End }) {
          Column() {
            Text(`${this.valuesRange[this.sliderValue]}${this.unit}`)
              .fontSize(vp2px(px2fp(40)))
              .fontColor(Color.White)
              .fontWeight(300)
              .height(53)
              .textShadow({ radius: 3, color: '#33000000', offsetX: 0, offsetY: 0 })
              .textAlign(TextAlign.Center)
              .touchable(false)
              .margin({ bottom: 2 })
              .fontFeature('\"ss01\" on')
            if (this.tips && this.tips.length > 0) {
              Text(`${this.tips[this.sliderValue]}`)
                .fontSize(12)
                .maxFontScale(1)
                .fontColor(Color.White)
                .height(16)
                .textShadow({ radius: 3, color: '#33000000', offsetX: 0, offsetY: 0 })
                .textAlign(TextAlign.Center)
                .touchable(false)
                .fontFeature('\"ss01\" on')
            }
          }
          .width(this.textWidth)
          .position(this.getTitlePosition())
          .rotate({ angle: this.rotateAngle })
          .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
          .opacity(this.bigTextOpacity)
          .height(70)

          Column() {
            Text(`${this.title}`)
              .fontSize(11)
              .maxFontScale(1)
              .fontWeight('bold')
              .fontColor(Color.White)
              .lineHeight(16)
              .textShadow({ radius: 3, color: '#33000000', offsetX: 0, offsetY: 0 })
              .textAlign(TextAlign.Center)
              .touchable(false)
              .fontFeature('\"ss01\" on')
              .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
              .position({
                x: this.mDirection === WindowDirection.LEFT ? -45 : this.mDirection === WindowDirection.RIGHT ?
                  this.sliderCanvasWidth - 25 : this.sliderCanvasWidth / 2 - 25,
                y:
                (this.mDirection === WindowDirection.LEFT ? 42 : this.mDirection === WindowDirection.RIGHT ? 42 : 6)
              })
              .rotate({
                angle: this.rotateAngle
              }) // .textCase(this.identifierValue?.isUpperCase ? TextCase.UpperCase : TextCase.LowerCase)
              .visibility(this.isSliding ? Visibility.Hidden : Visibility.Visible)
            Row() {
              Canvas(this.sliderCanvasContext)
                .width(this.sliderCanvasWidth)
                .height(this.sliderCanvasHeight)
                .onReady((): void => {
                  this.canvasInit();
                })
                .gesture(
                  GestureGroup(
                    GestureMode.Exclusive,
                    PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Horizontal })
                      .onActionStart((event?: GestureEvent) => {
                        if (event === undefined) {
                          return;
                        }
                        this.mAction.uiDisabled();
                        this.mAction.isEnterImmersive(true);
                        this.clearTimer();
                        this.clearExposureModeTimeout();
                        let localX = this.getFingerListLocalX(event);
                        if (!localX) {
                          return;
                        }
                        this.gestureStartX = localX;
                        this.isSliding = true;
                        this.isPanGesStartEndOrTap = true;
                        this.screenX = localX;
                        HiLog.i(TAG, `1 this.screenX ${this.screenX} `);
                        this.isPanGesStartEndOrTap = false;
                        this.clearBigTextTimer();

                      })
                      .onActionUpdate((event?: GestureEvent) => {
                        if (event === undefined) {
                          return;
                        }
                        this.screenX = (this.gestureStartX + event.offsetX);
                        HiLog.i(TAG, `2 this.screenX ${this.screenX} `);
                        if (this.timeLapse !== -1) {
                          this.mAction.sliderValue(this.timeLapse, this.valuesRange[this.sliderValue]);
                        }
                        this.clearTimer();
                      })
                      .onActionEnd((event?: GestureEvent) => {
                        this.onPanGestureEnd(event);
                        if (this.enableScreenReader) {
                          AccessibilityUtils.sendAnnounceAccessibilityEvent(
                            ResGetter.getStringSafe($r('app.string.accessibility_exposure_compensation_tile')) +
                            this.valuesRange[this.sliderValue]);
                        }
                      })
                      .onActionCancel((event?: GestureEvent) => this.onPanGestureEnd(event)),
                    TapGesture({ count: 1 })
                      .onAction((event?: GestureEvent) => {
                        this.tapGestureResponse(event);
                      }),
                    LongPressGesture({ repeat: false, duration: 300 })
                      .onAction((event?: GestureEvent) => {
                        if (event === undefined) {
                          return;
                        }
                        this.mAction.uiDisabled();
                        this.clearTimer();
                        if (this.bigTextTimer) {
                          clearTimeout(this.bigTextTimer);
                        }
                      })
                      .onActionEnd((event?: GestureEvent) => {
                        this.tapGestureResponse(event);
                        this.onLongPressGestureEnd(event);
                      })
                      .onActionCancel((event?: GestureEvent) => this.onLongPressGestureEnd(event))
                  )
                )
                .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_YES)
                .id(ComponentIdKeys.EXPOSURE_BAR_VIEW)
                .accessibilityText(this.getABText())
                .accessibilityDescription(ResGetter.getStringSafe($r('app.string.accessibility_slider_description')))
            }
          }
          .height(80)
          .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
        }
      }
      .height(80)
      .justifyContent(FlexAlign.Center)
      .key(ComponentIdKeys.getInstance().getKey(TAG, FunctionId.EXPOSURE))
    }
    .accessibilityLevel(CommonConstants.ACCESSIBILITY_LEVEL_NO)
    .width('100%')
    .height(108)
    .justifyContent(FlexAlign.End)
    .opacity(this.exposureOpacity)
    .onAppear(() => {
      if (this.enableScreenReader) {
        AccessibilityUtils.sendFocusAccessibilityEvent(ComponentIdKeys.EXPOSURE_BAR_VIEW)
      }
      this.exposureOpacity = 0;
      animateToImmediately({
        delay: 100,
        duration: 200,
        curve: Curve.Sharp
      }, () => {
        this.exposureOpacity = 1;
      });
    })
    .onDisAppear(() => {
      this.exposureOpacity = 1;
      animateToImmediately({
        delay: 0,
        duration: 200,
        curve: Curve.Sharp
      }, () => {
        this.exposureOpacity = 0;
      });
    })
  }

  private changeExposureToState(newLapseAutoState: number): void {
    this.globalAutoChangeFlag = true;
    if (newLapseAutoState === 0) {
      let initIndex = this.valuesRange.findIndex(index => {
        return Number(index) === 0;
      });
      this.isShowExposureText = false;
      this.screenX = this.getScreenXByIndex(initIndex);
      this.sliderValue = initIndex;
      this.changeExposureModeFunctionValue(0);
      this.canvasInit();
      this.isShowExposureText = true;
    }
    this.setExposureModeTimeout();
    this.globalAutoChangeFlag = false;
  }

  private getScreenXByIndex(initIndex: number): number {
    return this.bothSidesPadding + this.longWhiteLineWidth / 2 + initIndex * (this.segLength / this.gapNumInEachSeg);
  }
}